-- Улучшения навыков Hunter (мод Hunter). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    hunterZ        = { damage = 0.10, chargeSpeed = 0.15,
                       text = { { "chargeSpeed", "pct" } } },
    hunterX        = { damage = 0.10, blastSize = 0.15,
                       text = { { "blastSize", "pct" } } },
    hunterC        = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0,
                       text = { { "invulnAfter", "sec", "invulnAfterMax" } } },
    hunterV        = { damage = 0.10, blastSize = 0.15,
                       text = { { "blastSize", "pct" } } },
    hunterVBoosted = { damage = 0.10 },
}

local SKILLS = {
    hunterZ        = { "hunterZ" },
    hunterX        = { "hunterX" },
    hunterC        = { "hunterC" },
    hunterV        = { "hunterV" },
    hunterVBoosted = { "hunterVBoosted" },
}

local survivor = Survivor.find("hunter", "hunter")
if not survivor then
    SPPMS.Hunter = "absent"
    return
end

local PRIMARY = Util.find(ActorState, "hunterZ", "hunter")
local UTILITY = Util.find(ActorState, "hunterC", "hunter")
local MISSILE = Util.find(Object, "hunter_missile", "hunter")
local BOMB    = Util.find(Object, "hunter_bomb", "hunter")

local S = Util.register("hunter", T, SKILLS)

local missile_stepping = Util.stepping(MISSILE)
local bomb_stepping    = Util.stepping(BOMB)

local CHARGE_FULL  = 50
local CHARGE_DELAY = 10

Callback.add(PRIMARY.on_step, Callback.Priority.AFTER, function(actor, data)
    if not Util.in_state(actor, PRIMARY) then return end
    if (tonumber(data.released) or 0) ~= 0 then return end
    if (tonumber(data.wannacharge) or 0) < CHARGE_DELAY then return end
    local charge = tonumber(data.charge) or 0
    if charge >= CHARGE_FULL then return end
    if (tonumber(Instance.get_data(actor, nil, "hunter").beamcharged) or 0) ~= 0 then return end
    local rank = api.rank(actor, S.hunterZ)
    if rank < 1 then return end
    local rate = 1 + (actor.attack_speed - 1) * 2.5
    data.charge = charge + rate * T.hunterZ.chargeSpeed * rank
end)

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value then return end
    local rank, size
    if missile_stepping() then
        rank, size = api.rank(actor, S.hunterX), T.hunterX.blastSize
    elseif bomb_stepping() then
        rank, size = api.rank(actor, S.hunterV), T.hunterV.blastSize
    else
        return
    end
    if rank < 1 then return end
    local scale = 1 + size * rank
    args[8].value = args[8].value * scale
    args[9].value = args[9].value * scale
end)

Callback.add(UTILITY.on_exit, function(actor, data)
    local rank = api.rank(actor, S.hunterC)
    if rank < 1 then return end
    Util.grant_invuln(actor, math.min(T.hunterC.invulnAfter * rank, T.hunterC.invulnAfterMax))
end)

SPPMS.Hunter = "ready"
