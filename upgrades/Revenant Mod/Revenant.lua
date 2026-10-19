-- Улучшения навыков Revenant (мод Revenant). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    revenantZ = { damage = 0.10, swingSize = 0.15,
                  text = { { "swingSize", "pct" } } },
    revenantX = { damage = 0.10, pierceChance = 0.10,
                  text = { { "pierceChance", "pct" } } },
    revenantC = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0,
                  text = { { "invulnAfter", "sec", "invulnAfterMax" } } },
    revenantV = { orbDamage = 0.10, orbRange = 0.20,
                  text = { { "orbDamage", "pct" }, { "orbRange", "pct" } } },
}

local SKILLS = {
    revenantZ = { "RevenantZ" },
    revenantX = { "RevenantX" },
    revenantC = { "RevenantC" },
    revenantV = { "RevenantV", "RevenantVBoosted" },
}

local NS = "Revenant Mod"

local survivor = Survivor.find("Revenant", NS)
if not survivor then
    SPPMS.Revenant = "absent"
    return
end

local COMBO = {}
for i = 1, 3 do
    COMBO[i] = Util.find(ActorState, "SmashingBlade"..i, NS)
end
local SECONDARY = Util.find(ActorState, "BrokenArrow", NS)
local FLOAT     = Util.find(ActorState, "RevFloat", NS)
local CANNON    = Util.find(Object, "CorruptedCannon", NS)

local S = Util.register(NS, T, SKILLS)

local function in_combo(actor)
    for _, state in ipairs(COMBO) do
        if Util.in_state(actor, state) then return true end
    end
    return false
end

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value or not in_combo(actor) then return end
    local rank = api.rank(actor, S.revenantZ)
    if rank < 1 then return end
    local scale = 1 + T.revenantZ.swingSize * rank
    args[8].value = args[8].value * scale
    args[9].value = args[9].value * scale
end)

api.on_bullet(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, SECONDARY) then return end
    if Util.bool(args[4].value) then return end
    local rank = api.rank(actor, S.revenantX)
    if rank < 1 or math.random() >= T.revenantX.pierceChance * rank then return end
    args[4].value = true
end)

Callback.add(FLOAT.on_exit, function(actor, data)
    local rank = api.rank(actor, S.revenantC)
    if rank < 1 then return end
    Util.grant_invuln(actor, math.min(T.revenantC.invulnAfter * rank, T.revenantC.invulnAfterMax))
end)

Util.on_first_step(CANNON, function(inst)
    local rank = api.rank(inst.parent, S.revenantV)
    if rank < 1 then return end
    inst.damage = inst.damage * (1 + T.revenantV.orbDamage * rank)
    inst.lifetime = math.floor(inst.lifetime * (1 + T.revenantV.orbRange * rank))
end)

SPPMS.Revenant = "ready"
