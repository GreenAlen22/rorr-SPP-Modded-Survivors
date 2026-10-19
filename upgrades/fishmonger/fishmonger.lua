-- Улучшения навыков Fishmonger (мод Fishmonger). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    fishmongerZ = { damage = 0.10, swingSize = 0.15,
                    text = { { "swingSize", "pct" } } },
    fishmongerX = { netSize = 0.15, netSeconds = 1,
                    text = { { "netSize", "pct" }, { "netSeconds", "sec" } } },
    fishmongerC = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0,
                    text = { { "invulnAfter", "sec", "invulnAfterMax" } } },
    fishmongerV = { biteDamage = 0.10, baitLife = 0.15,
                    text = { { "biteDamage", "pct" }, { "baitLife", "pct" } } },
}

local SKILLS = {
    fishmongerZ = { "fishmongerZ" },
    fishmongerX = { "fishmongerX" },
    fishmongerC = { "fishmongerC" },
    fishmongerV = { "fishmongerV", "fishmongerVBoosted" },
}

local survivor = Survivor.find("fishmonger", "fishmonger")
if not survivor then
    SPPMS.Fishmonger = "absent"
    return
end

local PUSH    = Util.find(ActorState, "fishmongerZA", "fishmonger")
local PULL    = Util.find(ActorState, "fishmongerZB", "fishmonger")
local UTILITY = Util.find(ActorState, "fishmongerC", "fishmonger")
local NET     = Util.find(Object, "fishmongerNet", "fishmonger")
local BAIT    = Util.find(Object, "fishmongerLiveBait", "fishmonger")
local SHARK   = Util.find(Object, "fishmongerLiveBaitBoosted", "fishmonger")

local S = Util.register("fishmonger", T, SKILLS)

local bait_stepping  = Util.stepping(BAIT)
local shark_stepping = Util.stepping(SHARK)

local FPS = 60

local function scale_blast(args, mult)
    args[8].value = args[8].value * mult
    args[9].value = args[9].value * mult
end

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value then return end

    if bait_stepping() or shark_stepping() then
        local rank = api.rank(actor, S.fishmongerV)
        if rank < 1 then return end
        args[4].value = args[4].value * (1 + T.fishmongerV.biteDamage * rank)
        return
    end

    local push = Util.in_state(actor, PUSH)
    if not push and not Util.in_state(actor, PULL) then return end
    local rank = api.rank(actor, S.fishmongerZ)
    if rank < 1 then return end
    scale_blast(args, 1 + T.fishmongerZ.swingSize * rank)
    if push then
        args[4].value = args[4].value * (1 + T.fishmongerZ.damage * rank)
    end
end)

Util.on_first_step(NET, function(inst)
    local data = Instance.get_data(inst, nil, "fishmonger")
    local rank = api.rank(data.parent, S.fishmongerX)
    if rank < 1 then return end
    local scale = 1 + T.fishmongerX.netSize * rank
    inst.image_xscale = inst.image_xscale * scale
    inst.image_yscale = inst.image_yscale * scale
    Instance.get_data(inst, nil, Util.NS).sppms_left = T.fishmongerX.netSeconds * FPS * rank
end)

Callback.add(NET.on_step, Callback.Priority.AFTER, function(inst)
    if not Instance.exists(inst) then return end
    local own = Instance.get_data(inst, nil, Util.NS)
    local left = own.sppms_left
    if not left or left < 1 then return end
    local data = Instance.get_data(inst, nil, "fishmonger")
    if (tonumber(data.stopped) or 0) <= 1 then return end
    data.stopped = data.stopped - 1
    own.sppms_left = left - 1
end)

Callback.add(UTILITY.on_exit, function(actor, data)
    local rank = api.rank(actor, S.fishmongerC)
    if rank < 1 then return end
    Util.grant_invuln(actor, math.min(T.fishmongerC.invulnAfter * rank, T.fishmongerC.invulnAfterMax))
end)

local function longer_life(inst)
    local data = Instance.get_data(inst, nil, "fishmonger")
    local rank = api.rank(data.parent, S.fishmongerV)
    if rank < 1 then return end
    data.duration = math.floor(data.duration * (1 + T.fishmongerV.baitLife * rank))
end

Util.on_first_step(BAIT, longer_life)
Util.on_first_step(SHARK, longer_life)

SPPMS.Fishmonger = "ready"
