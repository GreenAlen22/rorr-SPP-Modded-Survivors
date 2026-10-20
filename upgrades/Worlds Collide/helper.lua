-- Улучшения навыков H.3.L.P.3.R. (мод Worlds Incursion). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    helperZ  = { pellets = 1, shotRange = 0.20,
                 text = { { "pellets", "count" }, { "shotRange", "pct" } } },
    helperZ2 = { blastDamage = 0.10, blastSize = 0.15,
                 text = { { "blastDamage", "pct" }, { "blastSize", "pct" } } },
    helperX  = { grenadeDamage = 0.10, blastSize = 0.15,
                 text = { { "grenadeDamage", "pct" }, { "blastSize", "pct" } } },
    helperC  = { stock_every = 2, blastSize = 0.15,
                 text = { { "blastSize", "pct" } } },
    helperV  = { blastDamage = 0.10, blastSize = 0.15,
                 text = { { "blastDamage", "pct" }, { "blastSize", "pct" } } },
}

local SKILLS = {
    helperZ  = { "helperZ" },
    helperZ2 = { "helperZ2" },
    helperX  = { "helperX" },
    helperC  = { "helperC" },
    helperV  = { "helperV", "helperVBoosted" },
}

local NS = "Worlds Collide"

local survivor = Survivor.find("helper", NS)
if not survivor then
    SPPMS.Helper = "absent"
    return
end

local PRIMARY = Util.find(ActorState, "helperPrimary", NS)
local SPECIAL = Util.find(ActorState, "helperSpecial", NS)
local REBAR   = Util.find(Object, "helperMissile", NS)
local GRENADE = Util.find(Object, "helperGrenade", NS)
local MORTAR  = Util.find(Object, "efHelperMissile", NS)
local SHADOW  = Util.find(Buff, "shadowClone", "ror")

local S = Util.register(NS, T, SKILLS)

local rebar_stepping   = Util.stepping(REBAR)
local grenade_stepping = Util.stepping(GRENADE)
local mortar_stepping  = Util.stepping(MORTAR)

local function scale_blast(args, mult)
    args[8].value = args[8].value * mult
    args[9].value = args[9].value * mult
end

local PELLETS       = 9
local PELLET_RANGE  = 200
local PELLET_COEFF  = 0.25
local PELLET_SPREAD = 11
local CRACKER_RANGE = 700

local cracker_shot = {}

api.after_bullet(function(actor, attack, args, vanilla)
    if actor.class ~= survivor.value or not Util.in_state(actor, PRIMARY) then return end
    if vanilla[6] == CRACKER_RANGE then cracker_shot[actor.id] = true end
end)

api.on_bullet(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, PRIMARY) then return end
    local rank = api.rank(actor, S.helperZ)
    if rank < 1 then return end
    args[6].value = args[6].value * (1 + T.helperZ.shotRange * rank)
end)

Callback.add(PRIMARY.on_enter, Callback.Priority.AFTER, function(actor, data)
    data.sppms_pellets = nil
end)

Callback.add(PRIMARY.on_step, Callback.Priority.AFTER, function(actor, data)
    if data.sppms_pellets or (tonumber(data.fired) or 0) < 1 then return end
    data.sppms_pellets = true
    local cracker = cracker_shot[actor.id]
    cracker_shot[actor.id] = nil
    if cracker or not Net.host or not Util.in_state(actor, PRIMARY) then return end
    local rank = api.rank(actor, S.helperZ)
    if rank < 1 then return end

    local extra = T.helperZ.pellets * rank
    for i = 0, actor:buff_count(SHADOW) do
        for k = 1, extra do
            local dir = actor:skill_util_facing_direction() + math.random(-PELLET_SPREAD, PELLET_SPREAD)
            local shot = actor:fire_bullet(actor.x, actor.y, PELLET_RANGE, dir, PELLET_COEFF, 1,
                gm.constants.sSparks1, Tracer.COMMANDO1)
            shot.attack_info.climb = (PELLETS + k) * 8 + i * 8
        end
    end
end)

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value then return end

    if rebar_stepping() then
        local rank = api.rank(actor, S.helperZ2)
        if rank < 1 then return end
        args[4].value = args[4].value * (1 + T.helperZ2.blastDamage * rank)
        scale_blast(args, 1 + T.helperZ2.blastSize * rank)
        return
    end

    if grenade_stepping() then
        local rank = api.rank(actor, S.helperX)
        if rank < 1 then return end
        args[4].value = args[4].value * (1 + T.helperX.grenadeDamage * rank)
        scale_blast(args, 1 + T.helperX.blastSize * rank)
        return
    end

    if mortar_stepping() then
        local rank = api.rank(actor, S.helperC)
        if rank < 1 then return end
        scale_blast(args, 1 + T.helperC.blastSize * rank)
        return
    end

    if not Util.in_state(actor, SPECIAL) then return end
    local rank = api.rank(actor, S.helperV)
    if rank < 1 then return end
    args[4].value = args[4].value * (1 + T.helperV.blastDamage * rank)
    scale_blast(args, 1 + T.helperV.blastSize * rank)
end)

SPPMS.Helper = "ready"
