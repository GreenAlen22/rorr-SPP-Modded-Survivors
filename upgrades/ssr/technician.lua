-- Улучшения навыков Technician (мод Starstorm Returns). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    technicianZ  = { damage = 0.10, swingSize = 0.15,
                     text = { { "swingSize", "pct" } } },
    technicianZ2 = { wrenchDamage = 0.10, wrenchHits = 1,
                     text = { { "wrenchDamage", "pct" }, { "wrenchHits", "count" } } },
    technicianX  = { damage = 0.10, blastSize = 0.15,
                     text = { { "blastSize", "pct" } } },
    technicianC  = { stock_every = 2, stimSeconds = 1, drinkPotency = 0.10,
                     text = { { "stimSeconds", "sec" }, { "drinkPotency", "pct" } } },
    technicianV  = { stock_every = 2, turretFireRate = 0.15,
                     text = { { "turretFireRate", "pct" } } },
}

local SKILLS = {
    technicianZ  = { "technicianZ" },
    technicianZ2 = { "technicianZ2" },
    technicianX  = { "technicianX", "technicianXD" },
    technicianC  = { "technicianC" },
    technicianV  = { "technicianV", "technicianVBoosted" },
}

local survivor = Survivor.find("technician", "ssr")
if not survivor then
    SPPMS.Technician = "absent"
    return
end

local PRIMARY   = Util.find(ActorState, "technicianPrimary", "ssr")
local WRENCH    = Util.find(Object, "wrench", "ssr")
local MINE      = Util.find(Object, "TechnicianMine", "ssr")
local VENDING   = Util.find(Object, "TechnicianVendingMachine", "ssr")
local TURRET    = Util.find(Object, "TechnicianTurret", "ssr")
local HYDRATED  = Util.find(Buff, "hydrated", "ssr")
local HYDRATED2 = Util.find(Buff, "really_hydrated", "ssr")

local S = Util.register("ssr", T, SKILLS)

local FPS = 60

local BITE_WIDTH   = gm.sprite_get_width(Util.constant("sBite1Mask"))
local SWING_XSCALE = 2.2 * 32 / BITE_WIDTH
local MINE_XSCALE  = 6 * 32 / BITE_WIDTH

local function is_width(args, xscale)
    return math.abs(args[8].value - xscale) < 1e-6
end

local DRINK_FRAMES = 5 * FPS

local DRINK_SPEED         = 0.56
local DRINK_ATTACK_SPEED  = 0.2
local DRINK_ATTACK_SPEED2 = 0.4
local DRINK_CRIT          = 20

local function scale_blast(args, mult)
    args[8].value = args[8].value * mult
    args[9].value = args[9].value * mult
end

local mine_exploding = false
Callback.add(MINE.on_destroy, Callback.Priority.BEFORE, function(inst) mine_exploding = true end)
Callback.add(MINE.on_destroy, Callback.Priority.AFTER, function(inst) mine_exploding = false end)

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value then return end

    if mine_exploding then
        if not is_width(args, MINE_XSCALE) then return end
        local rank = api.rank(actor, S.technicianX)
        if rank < 1 then return end
        scale_blast(args, 1 + T.technicianX.blastSize * rank)
        return
    end

    if not Util.in_state(actor, PRIMARY) or not is_width(args, SWING_XSCALE) then return end
    local rank = api.rank(actor, S.technicianZ)
    if rank < 1 then return end
    scale_blast(args, 1 + T.technicianZ.swingSize * rank)
end)

Util.on_first_step(WRENCH, function(inst)
    local rank = api.rank(inst.parent, S.technicianZ2)
    if rank < 1 then return end
    local data = Instance.get_data(inst, nil, "ssr")
    data.damage = data.damage * (1 + T.technicianZ2.wrenchDamage * rank)
    data.hits = data.hits + T.technicianZ2.wrenchHits * rank
end)

local at_machine = {}
local machine_rank = 0

Callback.add(VENDING.on_step, Callback.Priority.BEFORE, function(inst)
    at_machine = {}
    machine_rank = 0
    if not Net.host or not Instance.exists(inst.parent) then return end
    machine_rank = api.rank(inst.parent, S.technicianC)
    if machine_rank < 1 then return end
    for _, player in ipairs(Instance.find_all(gm.constants.oP)) do
        if player.team == inst.team then
            at_machine[#at_machine + 1] = { player, player:buff_count(HYDRATED), player:buff_count(HYDRATED2) }
        end
    end
end)

Callback.add(VENDING.on_step, Callback.Priority.AFTER, function(inst)
    if #at_machine == 0 or not Instance.exists(inst) then return end
    local upgraded = Util.bool(inst.upgraded)
    local buff = upgraded and HYDRATED2 or HYDRATED
    local frames = DRINK_FRAMES + T.technicianC.stimSeconds * FPS * machine_rank
    for _, entry in ipairs(at_machine) do
        local player = entry[1]
        local before = upgraded and entry[3] or entry[2]
        if before == 0 and Instance.exists(player) and player:buff_count(buff) > 0 then
            GM.set_buff_time(player, buff, frames)
        end
    end
    at_machine = {}
end)

local function nearest_machine_rank(actor)
    local nearest, nearest_dist = nil, math.huge
    for _, machine in ipairs(Instance.find_all(VENDING)) do
        if machine.team == actor.team then
            local dx, dy = machine.x - actor.x, machine.y - actor.y
            local dist = dx * dx + dy * dy
            if dist < nearest_dist then nearest, nearest_dist = machine, dist end
        end
    end
    if not nearest or not Instance.exists(nearest.parent) then return 0 end
    return api.rank(nearest.parent, S.technicianC)
end

Callback.add(HYDRATED.on_apply, function(actor)
    Instance.get_data(actor, nil, Util.NS).sppms_drink_rank = nearest_machine_rank(actor)
end)

Callback.add(HYDRATED2.on_apply, function(actor)
    Instance.get_data(actor, nil, Util.NS).sppms_drink_rank2 = nearest_machine_rank(actor)
end)

RecalculateStats.add(function(actor, stats)
    local has1 = actor:buff_count(HYDRATED) > 0
    local has2 = actor:buff_count(HYDRATED2) > 0
    if not has1 and not has2 then return end
    local own = Instance.get_data(actor, nil, Util.NS)
    if has1 then
        local mult = T.technicianC.drinkPotency * (own.sppms_drink_rank or 0)
        stats.attack_speed_add(DRINK_ATTACK_SPEED * mult)
        stats.pHmax_add(DRINK_SPEED * mult)
    end
    if has2 then
        local mult = T.technicianC.drinkPotency * (own.sppms_drink_rank2 or 0)
        stats.attack_speed_add(DRINK_ATTACK_SPEED2 * mult)
        stats.pHmax_add(DRINK_SPEED * mult)
        stats.critical_chance_add(DRINK_CRIT * mult)
    end
end)

Callback.add(TURRET.on_step, Callback.Priority.AFTER, function(inst)
    if not Instance.exists(inst) then return end
    local own = Instance.get_data(inst, nil, Util.NS)
    local cooldown = tonumber(inst.cooldown) or 0
    local last = own.sppms_cooldown
    own.sppms_cooldown = cooldown
    if not last or cooldown <= last then return end
    local rank = api.rank(inst.parent, S.technicianV)
    if rank < 1 then return end
    inst.cooldown = cooldown / (1 + T.technicianV.turretFireRate * rank)
    own.sppms_cooldown = inst.cooldown
end)

SPPMS.Technician = "ready"
