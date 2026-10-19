-- Улучшения навыков Gin (мод GinMod). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    ginZ = { damage = 0.10, swingSize = 0.15,
             text = { { "swingSize", "pct" } } },
    ginX = { damage = 0.10, cooldown = 0.92 },
    ginC = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0,
             text = { { "invulnAfter", "sec", "invulnAfterMax" } } },
    ginV = { fearSeconds = 1, fearSize = 0.15,
             text = { { "fearSeconds", "sec" }, { "fearSize", "pct" } } },
}

local SKILLS = {
    ginZ = { "GinZ" },
    ginX = { "GinX" },
    ginC = { "GinC" },
    ginV = { "GinV" },
}

local NS = "Gin"

local survivor = Survivor.find("Gin", NS)
if not survivor then
    SPPMS.Gin = "absent"
    return
end

local PRIMARY = Util.find(ActorState, "GinZ", NS)
local UTILITY = Util.find(ActorState, "GinC", NS)
local SPECIAL = Util.find(ActorState, "GinV", NS)
local FEAR    = Util.find(Buff, "fear", "ror")
local SCEPTER = Util.find(Item, "ancientScepter", "ror")

local S = Util.register(NS, T, SKILLS)

local FPS = 60

local SLAP_SPARKS = Util.constant("sSparks7")

local CRY_HALF_WIDTH  = 100 + 72
local CRY_HALF_HEIGHT = 88
local CRY_SECONDS         = 8
local CRY_SCEPTER_SECONDS = 16

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, PRIMARY) then return end
    if args[5].value ~= SLAP_SPARKS then return end
    local rank = api.rank(actor, S.ginZ)
    if rank < 1 then return end
    local scale = 1 + T.ginZ.swingSize * rank
    args[8].value = args[8].value * scale
    args[9].value = args[9].value * scale
end)

Callback.add(UTILITY.on_exit, function(actor, data)
    local rank = api.rank(actor, S.ginC)
    if rank < 1 then return end
    Util.grant_invuln(actor, math.min(T.ginC.invulnAfter * rank, T.ginC.invulnAfterMax))
end)

Callback.add(SPECIAL.on_enter, Callback.Priority.AFTER, function(actor, data)
    data.sppms_cry = nil
end)

Callback.add(SPECIAL.on_step, Callback.Priority.AFTER, function(actor, data)
    if not Net.host or data.sppms_cry or not Util.in_state(actor, SPECIAL) then return end
    if (tonumber(data.fired) or 0) < 1 then return end
    data.sppms_cry = true
    local rank = api.rank(actor, S.ginV)
    if rank < 1 then return end

    local scale = 1 + T.ginV.fearSize * rank
    local half_w, half_h = CRY_HALF_WIDTH * scale, CRY_HALF_HEIGHT * scale
    local base = actor:item_count(SCEPTER) > 0 and CRY_SCEPTER_SECONDS or CRY_SECONDS
    local frames = (base + T.ginV.fearSeconds * rank) * FPS
    local victims = actor:get_collisions_rectangle(gm.constants.pActor,
        actor.x - half_w, actor.y - half_h, actor.x + half_w, actor.y + half_h)
    for _, victim in ipairs(victims) do
        if victim.team ~= actor.team then GM.apply_buff(victim, FEAR, frames) end
    end
end)

SPPMS.Gin = "ready"
