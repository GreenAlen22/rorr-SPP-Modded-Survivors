-- Улучшения навыков Executioner (Starstorm Returns). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    executionerZ  = { damage = 0.10, pierceChance = 0.10,
                      text = { { "pierceChance", "pct" } } },
    executionerX  = { stock_every = 1, killRoundChance = 0.10,
                      text = { { "killRoundChance", "pct" } } },
    executionerC  = { stock_every = 2, fearSeconds = 0.2,
                      text = { { "fearSeconds", "sec" } } },
    executionerV  = { damage = 0.10, blastSize = 0.15,
                      text = { { "blastSize", "pct" } } },
    executionerV2 = { damage = 0.10, throwRange = 0.15,
                      text = { { "throwRange", "pct" } } },
}

local SKILLS = {
    executionerZ  = { "executionerZ" },
    executionerX  = { "executionerX" },
    executionerC  = { "executionerC" },
    executionerV  = { "executionerV", "executionerVBoosted" },
    executionerV2 = { "executionerV2", "executionerV2Boosted" },
}

local survivor = Survivor.find("executioner", "ssr")
if not survivor then
    SPPMS.Executioner = "absent"
    return
end

local PRIMARY  = Util.find(ActorState, "executionerPrimary", "ssr")
local UTILITY  = Util.find(ActorState, "executionerUtility", "ssr")
local SPECIAL  = Util.find(ActorState, "executionerSpecial", "ssr")
local AXE      = Util.find(Object, "ExecutionerAxe", "ssr")
local FEAR     = Util.find(Buff, "fear", "ror")

local S = Util.register("ssr", T, SKILLS)

local OP = gm.constants.oP
local FPS = 60

local FEAR_HALF_W = 100
local FEAR_HALF_H = 48

local ARC_HIGH = 160
local ARC_LOW  = 80

api.on_bullet(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, PRIMARY) then return end
    if Util.bool(args[4].value) then return end
    local rank = api.rank(actor, S.executionerZ)
    if rank < 1 or math.random() >= T.executionerZ.pierceChance * rank then return end
    args[4].value = true
end)

Callback.add(Callback.ON_KILL_PROC, function(victim, killer)
    if not Net.host then return end
    if not Instance.exists(killer) or killer.object_index ~= OP or killer.class ~= survivor.value then return end
    local rank = api.rank(killer, S.executionerX)
    if rank < 1 or math.random() >= T.executionerX.killRoundChance * rank then return end
    GM.actor_skill_add_stock_networked(killer, Skill.Slot.SECONDARY)
end)

local feared = {}

Callback.add(UTILITY.on_enter, function(actor, data)
    feared[actor.id] = nil
end)

Callback.add(UTILITY.on_step, Callback.Priority.AFTER, function(actor, data)
    if not Net.host or not Util.in_state(actor, UTILITY) then return end
    if api.rank(actor, S.executionerC) < 1 then return end
    local list = feared[actor.id] or {}
    feared[actor.id] = list
    local x, y = actor.x, actor.y
    for _, victim in ipairs(actor:get_collisions_rectangle(gm.constants.pActor,
            x - FEAR_HALF_W, y - FEAR_HALF_H, x + FEAR_HALF_W, y + FEAR_HALF_H)) do
        if victim.team ~= actor.team and victim:buff_count(FEAR) > 0 then
            list[victim.id] = victim
        end
    end
end)

Callback.add(UTILITY.on_exit, function(actor, data)
    local list = feared[actor.id]
    feared[actor.id] = nil
    if not Net.host or not list then return end
    local rank = api.rank(actor, S.executionerC)
    if rank < 1 then return end
    local extra = math.floor(T.executionerC.fearSeconds * rank * FPS)
    for _, victim in pairs(list) do
        if Instance.exists(victim) and victim:buff_count(FEAR) > 0 then
            victim:buff_set_time(FEAR, victim:buff_get_time(FEAR) + extra)
        end
    end
end)

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, SPECIAL) then return end
    local rank = api.rank(actor, S.executionerV)
    if rank < 1 then return end
    local scale = 1 + T.executionerV.blastSize * rank
    args[8].value = args[8].value * scale
    args[9].value = args[9].value * scale
end)

Util.on_first_step(AXE, function(inst)
    local rank = api.rank(inst.parent, S.executionerV2)
    if rank < 1 then return end
    inst.tX = inst.x + (inst.tX - inst.x) * (1 + T.executionerV2.throwRange * rank)
end)

Callback.add(AXE.on_step, Callback.Priority.AFTER, function(inst)
    if not Instance.exists(inst) or not Instance.exists(inst.parent) then return end
    local t = tonumber(inst.time) or 1
    if t >= 1 then return end
    local rank = api.rank(inst.parent, S.executionerV2)
    if rank < 1 then return end
    local f = 1 / (1 + T.executionerV2.throwRange * rank)
    local lift = 3 * (1 - t) ^ 2 * t * ARC_HIGH + 3 * (1 - t) * t ^ 2 * ARC_LOW
    inst.y = inst.y + (1 - f) * lift * inst.image_yscale
end)

SPPMS.Executioner = "ready"
