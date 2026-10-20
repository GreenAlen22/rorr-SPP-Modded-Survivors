-- Улучшения навыков Warrior (мод Worlds Incursion). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    bitwarriorZ  = { damage = 0.10, swingSize = 0.15,
                     text = { { "swingSize", "pct" } } },
    bitwarriorX  = { attackDamage = 0.10, waveSize = 0.15,
                     text = { { "attackDamage", "pct" }, { "waveSize", "pct" } } },
    bitwarriorX2 = { attackDamage = 0.10, doubleShotChance = 0.10,
                     text = { { "attackDamage", "pct" }, { "doubleShotChance", "pct" } } },
    bitwarriorC  = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0,
                     text = { { "invulnAfter", "sec", "invulnAfterMax" } } },
    bitwarriorC2 = { cooldown = 0.95, boostSeconds = 1,
                     text = { { "boostSeconds", "sec" } } },
    bitwarriorV  = { attackDamage = 0.10, swingSize = 0.15,
                     text = { { "attackDamage", "pct" }, { "swingSize", "pct" } } },
    bitwarriorV2 = { blastDamage = 0.10, blastSize = 0.15,
                     text = { { "blastDamage", "pct" }, { "blastSize", "pct" } } },
}

local SKILLS = {
    bitwarriorZ  = { "BitwarriorZ" },
    bitwarriorX  = { "BitwarriorX" },
    bitwarriorX2 = { "bitwarriorX2" },
    bitwarriorC  = { "BitwarriorC" },
    bitwarriorC2 = { "bitwarriorC2" },
    bitwarriorV  = { "BitwarriorV", "bitwarriorVBoosted" },
    bitwarriorV2 = { "bitwarriorV2", "bitwarriorVBoosted2" },
}

local NS = "Worlds Collide"

local survivor = Survivor.find("Bitwarrior", NS)
if not survivor then
    SPPMS.Bitwarrior = "absent"
    return
end

local COMBO = {
    Util.find(ActorState, "bitwarriorPrimary", NS),
    Util.find(ActorState, "bitwarriorSwing2", NS),
    Util.find(ActorState, "bitwarriorSwing3", NS),
}
local SECONDARY2 = Util.find(ActorState, "bitwarriorSecondary2", NS)
local UTILITY    = Util.find(ActorState, "bitwarriorUtility", NS)
local UTILITY2   = Util.find(ActorState, "bitwarriorUtility2", NS)
local SPECIAL    = Util.find(ActorState, "bitwarriorSpecial", NS)
local SPECIAL2   = Util.find(ActorState, "bitwarriorSpecial2", NS)
local WAVE       = Util.find(Object, "warriorSlash", NS)
local DAGGER     = Util.find(Object, "warriorDagg", NS)
local BOOST      = Util.find(Buff, "BITBUFF", NS)

local S = Util.register(NS, T, SKILLS)

local wave_stepping   = Util.stepping(WAVE)
local dagger_stepping = Util.stepping(DAGGER)

local FPS = 60

local function scale_blast(args, mult)
    args[8].value = args[8].value * mult
    args[9].value = args[9].value * mult
end

local function in_combo(actor)
    for _, state in ipairs(COMBO) do
        if Util.in_state(actor, state) then return true end
    end
    return false
end

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value then return end

    if wave_stepping() then
        local rank = api.rank(actor, S.bitwarriorX)
        if rank < 1 then return end
        args[4].value = args[4].value * (1 + T.bitwarriorX.attackDamage * rank)
        scale_blast(args, 1 + T.bitwarriorX.waveSize * rank)
        return
    end

    if dagger_stepping() then
        local rank = api.rank(actor, S.bitwarriorX2)
        if rank < 1 then return end
        args[4].value = args[4].value * (1 + T.bitwarriorX2.attackDamage * rank)
        return
    end

    if in_combo(actor) then
        local rank = api.rank(actor, S.bitwarriorZ)
        if rank < 1 then return end
        scale_blast(args, 1 + T.bitwarriorZ.swingSize * rank)

    elseif Util.in_state(actor, SPECIAL) then
        local rank = api.rank(actor, S.bitwarriorV)
        if rank < 1 then return end
        args[4].value = args[4].value * (1 + T.bitwarriorV.attackDamage * rank)
        scale_blast(args, 1 + T.bitwarriorV.swingSize * rank)

    elseif Util.in_state(actor, SPECIAL2) then
        local rank = api.rank(actor, S.bitwarriorV2)
        if rank < 1 then return end
        args[4].value = args[4].value * (1 + T.bitwarriorV2.blastDamage * rank)
        scale_blast(args, 1 + T.bitwarriorV2.blastSize * rank)
    end
end)

Util.on_first_step(WAVE, function(inst)
    if not Instance.exists(inst.parent) then return end
    local rank = api.rank(inst.parent, S.bitwarriorX)
    if rank < 1 then return end
    local scale = 1 + T.bitwarriorX.waveSize * rank
    inst.image_xscale = inst.image_xscale * scale
    inst.image_yscale = inst.image_yscale * scale
end)

Callback.add(SECONDARY2.on_enter, Callback.Priority.AFTER, function(actor, data)
    data.sppms_dagger = nil
end)

Callback.add(SECONDARY2.on_step, Callback.Priority.AFTER, function(actor, data)
    if data.sppms_dagger or (tonumber(data.fired) or 0) < 1 then return end
    data.sppms_dagger = true
    if not Util.bool(actor.local_client_is_authority) then return end
    local rank = api.rank(actor, S.bitwarriorX2)
    if rank < 1 or math.random() >= T.bitwarriorX2.doubleShotChance * rank then return end
    local dagger = DAGGER:create(actor.x, actor.y)
    dagger.parent = actor
    dagger.direction = actor:skill_util_facing_direction()
    dagger.image_xscale = actor.image_xscale
end)

Callback.add(UTILITY.on_exit, function(actor, data)
    local rank = api.rank(actor, S.bitwarriorC)
    if rank < 1 then return end
    Util.grant_invuln(actor, math.min(T.bitwarriorC.invulnAfter * rank, T.bitwarriorC.invulnAfterMax))
end)

local BOOST_SECONDS = 10

Callback.add(UTILITY2.on_enter, Callback.Priority.AFTER, function(actor, data)
    data.sppms_boost = nil
end)

Callback.add(UTILITY2.on_step, Callback.Priority.AFTER, function(actor, data)
    if data.sppms_boost or (tonumber(data.fired) or 0) < 1 then return end
    data.sppms_boost = true
    if not Net.host then return end
    local rank = api.rank(actor, S.bitwarriorC2)
    local frames = (BOOST_SECONDS + T.bitwarriorC2.boostSeconds * rank) * FPS

    if not Util.bool(actor.local_client_is_authority) then
        if actor:buff_count(BOOST) == 0 then
            GM.apply_buff(actor, BOOST, frames, 1)
        else
            GM.set_buff_time(actor, BOOST, frames)
        end
    elseif rank > 0 and actor:buff_count(BOOST) > 0 then
        GM.set_buff_time(actor, BOOST, frames)
    end
end)

SPPMS.Bitwarrior = "ready"
