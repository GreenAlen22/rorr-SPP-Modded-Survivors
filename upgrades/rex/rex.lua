-- Улучшения навыков REX (мод Risk of Rex Returns). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    rexZ = { syringeEvery = 2, syringeDamage = 0.10, breakSeconds = 1,
             text = { { "syringeEvery", "every" }, { "syringeDamage", "pct" },
                      { "breakSeconds", "sec" } } },
    rexX = { mortarDamage = 0.10, blastSize = 0.15,
             text = { { "mortarDamage", "pct" }, { "blastSize", "pct" } } },
    rexC = { stock_every = 2, lifesteal = 0.10,
             text = { { "lifesteal", "pct" } } },
    rexV = { pulseDamage = 0.10, pulseRadius = 0.15,
             text = { { "pulseDamage", "pct" }, { "pulseRadius", "pct" } } },
}

local SKILLS = {
    rexZ = { "rexZ" },
    rexX = { "rexX" },
    rexC = { "rexC" },
    rexV = { "rexV", "rexVUpgrade" },
}

local NS = "rex"

local survivor = Survivor.find("rex", NS)
if not survivor then
    SPPMS.Rex = "absent"
    return
end

local PRIMARY  = Util.find(ActorState, "rexPrimary", NS)
local SYRINGE  = Util.find(Object, "rexSyringe", NS)
local SYRINGE3 = Util.find(Object, "rexSyringeBreak", NS)
local MORTAR   = Util.find(Object, "rexMortar", NS)
local FLOWER   = Util.find(Object, "rexTanglingGrowth", NS)
local PULL     = Util.find(Object, "rexFlowerPull", NS)
local BREAK    = Util.find(Buff, "rexBreak", NS)
local SHOOT    = Util.find(Sound, "rexShoot1_Shoot", NS)
local MIRROR   = Util.find(Buff, "shadowClone", "ror")

local S = Util.register(NS, T, SKILLS)

local syringe_stepping  = Util.stepping(SYRINGE)
local syringe3_stepping = Util.stepping(SYRINGE3)
local mortar_stepping   = Util.stepping(MORTAR)
local flower_stepping   = Util.stepping(FLOWER)

local FPS = 60

api.on_direct(function(actor, args)
    if actor.class ~= survivor.value then return end
    local rank, gain
    if syringe_stepping() or syringe3_stepping() then
        rank, gain = api.rank(actor, S.rexZ), T.rexZ.syringeDamage
    elseif flower_stepping() then
        rank, gain = api.rank(actor, S.rexV), T.rexV.pulseDamage
    else
        return
    end
    if rank < 1 then return end
    args[5].value = args[5].value * (1 + gain * rank)
end)

api.on_bullet(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, PRIMARY) then return end
    local rank = api.rank(actor, S.rexZ)
    if rank < 1 then return end
    args[5].value = args[5].value * (1 + T.rexZ.syringeDamage * rank)
end)

local EXTRA_FIRST = 1
local EXTRA_GAP   = 2
local EXTRA_LAST  = 7

Callback.add(PRIMARY.on_enter, Callback.Priority.AFTER, function(actor, data)
    data.sppms_extra = 0
end)

Callback.add(PRIMARY.on_step, Callback.Priority.AFTER, function(actor, data)
    if not Util.in_state(actor, PRIMARY) then return end
    local extra = math.floor(api.rank(actor, S.rexZ) / T.rexZ.syringeEvery)
    local fired = tonumber(data.sppms_extra) or 0
    while fired < extra
      and actor.image_index2 >= math.min(EXTRA_FIRST + fired * EXTRA_GAP, EXTRA_LAST) do
        local dir = actor:skill_util_facing_direction()
        for i = 0, actor:buff_count(MIRROR) do
            local syringe = SYRINGE:create(actor.x + (i * 20) + 7 * actor.image_xscale, actor.y - 7)
            syringe:actor_skin_skinnable_set_skin(actor)
            syringe.direction = dir
            syringe.image_xscale = actor.image_xscale
            syringe.parent = actor
        end
        actor:sound_play(SHOOT, 0.7, 0.8 + math.random() * 0.2)
        fired = fired + 1
    end
    data.sppms_extra = fired
end)

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value or not mortar_stepping() then return end
    local rank = api.rank(actor, S.rexX)
    if rank < 1 then return end
    args[4].value = args[4].value * (1 + T.rexX.mortarDamage * rank)
    local scale = 1 + T.rexX.blastSize * rank
    args[8].value = args[8].value * scale
    args[9].value = args[9].value * scale
end)

local BREAK_SECONDS = 4
local TAG_SYRINGE   = 1
local TAG_SYRINGE3  = 2
local TAG_BOOM      = 3

Callback.add(Callback.ON_ATTACK_HIT, Callback.Priority.AFTER, function(hit_info)
    local attack = hit_info.attack_info
    local tag = attack.__rex_info
    if tag ~= TAG_SYRINGE and tag ~= TAG_SYRINGE3 then return end
    local rex = attack.parent
    if not Instance.exists(rex) then return end
    local rank = api.rank(rex, S.rexZ)
    if rank < 1 then return end
    local victim = hit_info.target
    if not Instance.exists(victim) or victim:buff_count(BREAK) == 0 then return end
    GM.set_buff_time(victim, BREAK, (BREAK_SECONDS + T.rexZ.breakSeconds * rank) * FPS)
end)

Callback.add(Callback.ON_ATTACK_HIT, Callback.Priority.AFTER, function(hit_info)
    if not Net.host then return end
    local attack = hit_info.attack_info
    if attack.__rex_info ~= TAG_BOOM then return end
    local rex = attack.parent
    if not Instance.exists(rex) then return end
    local rank = api.rank(rex, S.rexC)
    if rank < 1 then return end
    rex:heal(hit_info.damage * T.rexC.lifesteal * rank)
end)

local TICK_TIME      = 90
local RADIUS         = 180
local RADIUS_S       = 250
local PULSE_DAMAGE   = 1
local PULSE_DAMAGE_S = 1.35
local PULL_LIFETIME  = 12
local TAG_GROWTH     = 4
local TAG_GROWTH_S   = 5

local function outer_ring(inst, radius, scale)
    local inner = {}
    for _, target in ipairs(inst:get_collisions_circle(gm.constants.pActor, radius, inst.x, inst.y)) do
        inner[target.id] = true
    end
    local ring = {}
    for _, target in ipairs(inst:get_collisions_circle(gm.constants.pActor, radius * scale, inst.x, inst.y)) do
        if not inner[target.id] then ring[#ring + 1] = target end
    end
    return ring
end

Callback.add(FLOWER.on_step, Callback.Priority.BEFORE - 1, function(inst)
    if not Instance.exists(inst) then return end
    local parent = inst.parent
    if not Instance.exists(parent) then return end
    local data = Instance.get_data(inst, nil, NS)
    if not data.active or data.timer + 1 < TICK_TIME then return end
    local rank = api.rank(parent, S.rexV)
    if rank < 1 then return end
    local boosted = inst.scepter > 0
    local radius = boosted and RADIUS_S or RADIUS
    local damage = boosted and PULSE_DAMAGE_S or PULSE_DAMAGE
    local tag    = boosted and TAG_GROWTH_S or TAG_GROWTH
    for _, target in ipairs(outer_ring(inst, radius, 1 + T.rexV.pulseRadius * rank)) do
        if parent:attack_collision_canhit(target) then
            local dir = Math.direction(inst.x, inst.y, target.x, target.y)
            for i = 0, parent:buff_count(MIRROR) do
                local hit = parent:fire_direct(target, damage, dir, inst.x, inst.y, nil).attack_info
                hit.climb = i * 8 * 1.35
                hit.__rex_info = tag
            end
        end
    end
end)

Callback.add(PULL.on_step, Callback.Priority.AFTER, function(inst)
    if not Instance.exists(inst) then return end
    local parent = inst.parent
    if not Instance.exists(parent) then return end
    local rank = api.rank(parent, S.rexV)
    if rank < 1 then return end
    for _, target in ipairs(outer_ring(inst, RADIUS, 1 + T.rexV.pulseRadius * rank)) do
        if parent:attack_collision_canhit(target) and not target:is_climbing() and not target.intangible then
            local t = 1 - (inst.lifetime + 1) / PULL_LIFETIME
            local falloff = (1 - t)^2
            local strength = math.max(0.1, 12 * falloff)

            if GM.actor_is_classic(target) then
                target:move_contact_solid(180 + Math.direction(inst.x, target.y, target.x, target.y), strength)
            elseif not GM.actor_is_boss(target) then
                target.x = target.x - math.cos(math.rad(Math.direction(inst.x, inst.y, target.x, target.y))) * strength
                target.y = target.y + math.sin(math.rad(Math.direction(inst.x, inst.y, target.x, target.y))) * strength
            end
        end
    end
end)

SPPMS.Rex = "ready"
