-- Улучшения навыков Gigachad (мод Gigachad). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    gigachadZ  = { damage = 0.10, doubleStrikeChance = 0.10,
                   text = { { "doubleStrikeChance", "pct" } } },
    gigachadX  = { damage = 0.10, spikeReach = 0.15,
                   text = { { "spikeReach", "pct" } } },
    gigachadC  = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0,
                   text = { { "invulnAfter", "sec", "invulnAfterMax" } } },
    gigachadV  = { damage = 0.10, swingSize = 0.15,
                   text = { { "swingSize", "pct" } } },
    gigachadZ2 = { damage = 0.10, kickSize = 0.15,
                   text = { { "kickSize", "pct" } } },
    gigachadX2 = { trollDamage = 0.10, trollRange = 0.15,
                   text = { { "trollDamage", "pct" }, { "trollRange", "pct" } } },
    gigachadC2 = { cooldown = 0.95, musicAttackSpeed = 0.05,
                   text = { { "musicAttackSpeed", "pct" } } },
    gigachadV2 = { blastSize = 0.10, helplessCut = 0.08, helplessCutMax = 0.4,
                   text = { { "blastSize", "pct" }, { "helplessCut", "pct", "helplessCutMax" } } },
}

local SKILLS = {
    gigachadZ  = { "GigachadZ" },
    gigachadX  = { "GigachadX" },
    gigachadC  = { "GigachadC" },
    gigachadV  = { "GigachadV", "GigachadVBoosted" },
    gigachadZ2 = { "GigachadZ2" },
    gigachadX2 = { "GigachadX2" },
    gigachadC2 = { "GigachadC2" },
    gigachadV2 = { "GigachadV2", "GigachadV2Boosted" },
}

local NS = "GreenAlen22"

local survivor = Survivor.find("Gigachad", NS)
if not survivor then
    SPPMS.Gigachad = "absent"
    return
end

local PRIMARY    = Util.find(ActorState, "GigachadZ", NS)
local SECONDARY  = Util.find(ActorState, "GigachadX", NS)
local UTILITY    = Util.find(ActorState, "GigachadC", NS)
local SPECIAL    = Util.find(ActorState, "GigachadV", NS)
local SPECIAL_B  = Util.find(ActorState, "GigachadVBoosted", NS)
local PRIMARY2   = Util.find(ActorState, "GigachadZ2", NS)
local BLAST      = Util.find(ActorState, "GigachadV2", NS)
local BLAST_B    = Util.find(ActorState, "GigachadV2Boosted", NS)
local TROLL      = Util.find(Object, "gigachadTroll", NS)
local SPIKE      = Util.find(Sprite, "gigachad_spike", NS)
local TROLL_HIT  = Util.find(Sprite, "gigachad_small_trollface", NS)
local GIGAMUSIC  = Util.find(Buff, "gigamusic", NS)

local S = Util.register(NS, T, SKILLS)

local stepping = {
    stab      = Util.stepping(PRIMARY),
    seismic   = Util.stepping(SECONDARY),
    fury      = Util.stepping(SPECIAL),
    fury_b    = Util.stepping(SPECIAL_B),
    sparta    = Util.stepping(PRIMARY2),
    blast     = Util.stepping(BLAST),
    blast_b   = Util.stepping(BLAST_B),
}

local function in_step(which, actor)
    local current = stepping[which]()
    return current ~= nil and current.id == actor.id
end

local function scale_box(args, mult)
    args[8].value = args[8].value * mult
    args[9].value = args[9].value * mult
end

local SPIKE_REACH = 95
local SPIKE_HALF  = 220 / 2

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value then return end

    if in_step("seismic", actor) then
        local rank = api.rank(actor, S.gigachadX)
        if rank < 1 then return end
        local grow = T.gigachadX.spikeReach * rank
        local dir = (args[2].value >= actor.x) and 1 or -1
        args[8].value = args[8].value * (1 + grow)
        args[2].value = args[2].value + SPIKE_HALF * grow * dir
    elseif in_step("fury", actor) or in_step("fury_b", actor) then
        local rank = api.rank(actor, S.gigachadV)
        if rank < 1 then return end
        scale_box(args, 1 + T.gigachadV.swingSize * rank)
    elseif in_step("sparta", actor) then
        local rank = api.rank(actor, S.gigachadZ2)
        if rank < 1 then return end
        scale_box(args, 1 + T.gigachadZ2.kickSize * rank)
    elseif in_step("blast", actor) or in_step("blast_b", actor) then
        local rank = api.rank(actor, S.gigachadV2)
        if rank < 1 then return end
        scale_box(args, 1 + T.gigachadV2.blastSize * rank)
    end
end)

Callback.add(SECONDARY.on_enter, Callback.Priority.AFTER, function(actor, data)
    data.sppms_spike = nil
end)

Callback.add(SECONDARY.on_step, Callback.Priority.AFTER, function(actor, data)
    if data.sppms_spike or (tonumber(data.hits) or 0) < 1 then return end
    data.sppms_spike = true
    local rank = api.rank(actor, S.gigachadX)
    if rank < 1 then return end
    local grow = T.gigachadX.spikeReach * rank

    for _, spike in ipairs(Instance.find_all(gm.constants.oEfSparks)) do
        if spike.sprite_index == SPIKE.value and math.abs(spike.image_xscale) == 1
        and math.abs(spike.y - actor.y) < 1
        and math.abs(math.abs(spike.x - actor.x) - SPIKE_REACH) < 1 then
            local dir = spike.image_xscale
            spike.image_xscale = dir * (1 + grow)
            spike.x = spike.x + SPIKE_HALF * grow * dir
            return
        end
    end
end)

local firing_copy = false

api.after_explosion(function(actor, attack, args, vanilla)
    if firing_copy or actor.class ~= survivor.value or not in_step("stab", actor) then return end
    local rank = api.rank(actor, S.gigachadZ)
    if rank < 1 or math.random() >= T.gigachadZ.doubleStrikeChance * rank then return end

    firing_copy = true
    local ok, copy = pcall(GM.SO.fire_explosion, actor, actor, table.unpack(vanilla, 1, vanilla.n))
    firing_copy = false
    if not ok then error(copy, 0) end
    copy.climb = 8 * 1.35
    copy.damage_color = Color.WHITE_ALMOST
end)

Callback.add(UTILITY.on_exit, function(actor, data)
    local rank = api.rank(actor, S.gigachadC)
    if rank < 1 then return end
    Util.grant_invuln(actor, math.min(T.gigachadC.invulnAfter * rank, T.gigachadC.invulnAfterMax))
end)

api.on_direct(function(actor, args)
    if actor.class ~= survivor.value or args[6].value ~= TROLL_HIT.value then return end
    local rank = api.rank(actor, S.gigachadX2)
    if rank < 1 then return end
    args[5].value = args[5].value * (1 + T.gigachadX2.trollDamage * rank)
end)

local FACE_SPEED = 2.0

Callback.add(TROLL.on_step, function(inst)
    if not Instance.exists(inst) then return end
    local owner = inst.parent
    if not Instance.exists(owner) then return end
    local rank = api.rank(owner, S.gigachadX2)
    if rank < 1 then return end
    local dir = (inst.image_xscale < 0) and -1 or 1
    inst.x = inst.x + dir * FACE_SPEED * T.gigachadX2.trollRange * rank
end)

RecalculateStats.add(function(actor, stats)
    if actor.class ~= survivor.value then return end
    if actor:buff_count(GIGAMUSIC) < 1 then return end
    local rank = api.rank(actor, S.gigachadC2)
    if rank < 1 then return end
    stats.attack_speed_add(T.gigachadC2.musicAttackSpeed * rank)
end)

local CAST = 159
local RISE, STAND = 12, 6
local RISING_FRAME, STANDING_FRAME = 5, 6

local function shorter_spent(state, spent)
    Callback.add(state.on_step, Callback.Priority.AFTER, function(actor, data)
        if not Util.in_state(actor, state) then return end
        local rank = api.rank(actor, S.gigachadV2)
        if rank < 1 then return end

        local share = math.min(T.gigachadV2.helplessCut * rank, T.gigachadV2.helplessCutMax)
        local finish = spent - math.floor(spent * share)
        local since = (tonumber(data.t) or 0) - CAST
        if since < finish - RISE then return end

        if since >= finish then
            actor:skill_util_reset_activity_state()
        else
            actor.image_index = (since >= finish - STAND) and STANDING_FRAME or RISING_FRAME
        end
    end)
end

shorter_spent(BLAST, 150)
shorter_spent(BLAST_B, 60)

SPPMS.Gigachad = "ready"
