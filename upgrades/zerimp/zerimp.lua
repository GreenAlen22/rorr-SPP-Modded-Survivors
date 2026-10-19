-- Улучшения навыков Zerimp (мод Zerimp Returns). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    zerimpZ = { bubbleDamage = 0.10, bubbleEvery = 2, bubbleShare = 0.6,
                text = { { "bubbleDamage", "pct" }, { "bubbleEvery", "every", "bubbleShare", "share" } } },
    zerimpX = { shotDamage = 0.10, stunSeconds = 0.5, stunSecondsMax = 2,
                text = { { "shotDamage", "pct" }, { "stunSeconds", "sec", "stunSecondsMax" } } },
    zerimpC = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0, flipBubbles = 1, flipBubblesMax = 4,
                text = { { "invulnAfter", "sec", "invulnAfterMax" }, { "flipBubbles", "count", "flipBubblesMax" } } },
    zerimpV = { boostSeconds = 0.5, boostRadius = 0.25,
                text = { { "boostSeconds", "sec" }, { "boostRadius", "pct" } } },
}

local SKILLS = {
    zerimpZ = { "zerimpZ" },
    zerimpX = { "zerimpX" },
    zerimpC = { "zerimpC" },
    zerimpV = { "zerimpV", "zerimpVBoosted" },
}

local survivor = Survivor.find("zerimp", "zerimp")
if not survivor then
    SPPMS.Zerimp = "absent"
    return
end

local SECONDARY = Util.find(ActorState, "zerimpX", "zerimp")
local UTILITY   = Util.find(ActorState, "zerimpC", "zerimp")
local SPECIAL   = Util.find(ActorState, "zerimpV", "zerimp")
local BUBBLE    = Util.find(Object, "ZerimpBullet", "zerimp")
local CAMBRIAN  = Util.find(Buff, "cambrianBoost", "zerimp")
local DILUVIAN  = Util.find(Buff, "diluvianBoost", "zerimp")
local SCEPTER   = Util.find(Item, "ancientScepter", "ror")

local S = Util.register("zerimp", T, SKILLS)

local bubble_stepping = Util.stepping(BUBBLE)

local FPS = 60

local BUBBLE_COEFF    = 1.1
local BUBBLE_OFFSET   = 6
local CRUSH_RANGE     = 85.5
local CRUSH_STUN      = 2
local CRUSH_KNOCKBACK = 5
local BOOST_FRAMES    = 300
local BOOST_RADIUS    = 100

local STUN_FRAMES = 90

local FAN_DEGREES = 8

local function fan(i)
    local step = math.ceil((i - 1) / 2)
    return (i % 2 == 0 and 1 or -1) * step * FAN_DEGREES
end

local function spawn_bubble(parent, x, y, direction, damage)
    local bubble = BUBBLE:create(x, y)
    local data = Instance.get_data(bubble, nil, "zerimp")
    data.parent = parent
    data.damage = damage
    bubble.direction = direction
    Instance.get_data(bubble, nil, Util.NS).sppms_extra = true
end

Util.on_first_step(BUBBLE, function(inst)
    if Instance.get_data(inst, nil, Util.NS).sppms_extra then return end
    local data = Instance.get_data(inst, nil, "zerimp")
    local parent = data.parent
    if not Instance.exists(parent) or parent.class ~= survivor.value then return end
    local extra = math.floor(api.rank(parent, S.zerimpZ) / T.zerimpZ.bubbleEvery)
    for i = 2, extra + 1 do
        spawn_bubble(parent, inst.x, inst.y, inst.direction + fan(i), data.damage * T.zerimpZ.bubbleShare)
    end
end)

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value or not bubble_stepping() then return end
    local rank = api.rank(actor, S.zerimpZ)
    if rank < 1 then return end
    args[4].value = args[4].value * (1 + T.zerimpZ.bubbleDamage * rank)
end)

api.on_bullet(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, SECONDARY) then return end
    if args[6].value ~= CRUSH_RANGE then return end
    local rank = api.rank(actor, S.zerimpX)
    if rank < 1 then return end
    args[5].value = args[5].value * (1 + T.zerimpX.shotDamage * rank)
end)

Callback.add(Callback.ON_ATTACK_HANDLE_START, function(attack)
    if not Net.host then return end
    if tonumber(attack.stun) ~= CRUSH_STUN or tonumber(attack.knockback) ~= CRUSH_KNOCKBACK then return end
    local parent = attack.parent
    if not Instance.exists(parent) or parent.class ~= survivor.value then return end
    local rank = api.rank(parent, S.zerimpX)
    if rank < 1 then return end
    local seconds = math.min(T.zerimpX.stunSeconds * rank, T.zerimpX.stunSecondsMax)
    attack.stun = attack.stun + seconds * FPS / STUN_FRAMES
end)

Callback.add(UTILITY.on_enter, Callback.Priority.AFTER, function(actor, data)
    local rank = api.rank(actor, S.zerimpC)
    if rank < 1 then return end
    local count = math.min(T.zerimpC.flipBubbles * rank, T.zerimpC.flipBubblesMax)
    local x = actor.x + BUBBLE_OFFSET * actor.image_xscale
    local direction = actor:skill_util_facing_direction()
    for i = 1, count do
        spawn_bubble(actor, x, actor.y, direction + fan(i), BUBBLE_COEFF)
    end
end)

Callback.add(UTILITY.on_exit, function(actor, data)
    local rank = api.rank(actor, S.zerimpC)
    if rank < 1 then return end
    Util.grant_invuln(actor, math.min(T.zerimpC.invulnAfter * rank, T.zerimpC.invulnAfterMax))
end)

Callback.add(SPECIAL.on_enter, Callback.Priority.AFTER, function(actor, data)
    data.sppms_boost = nil
end)

Callback.add(SPECIAL.on_step, Callback.Priority.AFTER, function(actor, data)
    if not Net.host or data.sppms_boost or not Util.in_state(actor, SPECIAL) then return end
    if (tonumber(Instance.get_data(actor, nil, "zerimp").fired) or 0) < 1 then return end
    data.sppms_boost = true
    local rank = api.rank(actor, S.zerimpV)
    if rank < 1 then return end

    local buff = actor:item_count(SCEPTER) > 0 and DILUVIAN or CAMBRIAN
    local frames = BOOST_FRAMES + T.zerimpV.boostSeconds * FPS * rank
    local radius = BOOST_RADIUS * (1 + T.zerimpV.boostRadius * rank)
    for _, other in ipairs(actor:get_collisions_circle(gm.constants.pActorCollisionBase, radius, actor.x, actor.y)) do
        local ally = actor:attack_collision_resolve(other)
        if ally ~= -4 and ally.team == actor.team then
            if ally:buff_count(buff) > 0 then
                GM.set_buff_time(ally, buff, frames)
            else
                GM.apply_buff(ally, buff, frames, 1)
            end
        end
    end
    if actor:buff_count(buff) > 0 then
        GM.set_buff_time(actor, buff, frames)
    end
end)

SPPMS.Zerimp = "ready"
