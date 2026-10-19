-- Улучшения навыков Ghost (мод Ghost Survivor). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    ghostZ = false,
    ghostX = false,
    ghostC = false,
    ghostV = { fearSeconds = 1,
               text = { { "fearSeconds", "sec" } } },
}

local SKILLS = {
    ghostZ = { "GhostZ" },
    ghostX = { "GhostX" },
    ghostC = { "GhostC" },
    ghostV = { "GhostV" },
}

local NS = "Ghost"

local survivor = Survivor.find("Ghost", NS)
if not survivor then
    SPPMS.Ghost = "absent"
    return
end

local SPECIAL = Util.find(ActorState, "GhostV", NS)
local FEAR    = Util.find(Buff, "fear", "ror")
local SCEPTER = Util.find(Item, "ancientScepter", "ror")

local S = Util.register(NS, T, SKILLS)

local FPS = 60

local HALF_WIDTH  = 100 + 344
local HALF_HEIGHT = 366
local FEAR_SECONDS         = 6
local FEAR_SCEPTER_SECONDS = 14

Callback.add(SPECIAL.on_enter, Callback.Priority.AFTER, function(actor, data)
    data.sppms_fear = nil
end)

Callback.add(SPECIAL.on_step, Callback.Priority.AFTER, function(actor, data)
    if not Net.host or data.sppms_fear or not Util.in_state(actor, SPECIAL) then return end
    if (tonumber(data.fired) or 0) < 1 then return end
    data.sppms_fear = true
    local rank = api.rank(actor, S.ghostV)
    if rank < 1 then return end

    local base = actor:item_count(SCEPTER) > 0 and FEAR_SCEPTER_SECONDS or FEAR_SECONDS
    local frames = (base + T.ghostV.fearSeconds * rank) * FPS
    local victims = actor:get_collisions_rectangle(gm.constants.pActor,
        actor.x - HALF_WIDTH, actor.y - HALF_HEIGHT, actor.x + HALF_WIDTH, actor.y + HALF_HEIGHT)
    for _, victim in ipairs(victims) do
        if victim.team ~= actor.team then GM.apply_buff(victim, FEAR, frames) end
    end
end)

SPPMS.Ghost = "ready"
