-- Улучшения навыков Captain (мод Captain Returns). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    captainZ = { damage = 0.10, chargeSpeed = 0.15,
                 text = { { "chargeSpeed", "pct" } } },
    captainX = { damage = 0.10, blastSize = 0.15,
                 text = { { "blastSize", "pct" } } },
    captainC = { damage = 0.10, cooldown = 0.95, blastSize = 0.15,
                 text = { { "blastSize", "pct" } } },
    captainV = { damage = 0.10, healRate = 0.15, shockRate = 0.20, resupplyRecharge = 0.20,
                 hackSpeed = 0.20, enhanceSpeed = 0.20, punishStacks = 1,
                 text = { { "healRate", "pct" }, { "shockRate", "pct" },
                          { "resupplyRecharge", "pct" }, { "hackSpeed", "pct" },
                          { "enhanceSpeed", "pct" }, { "punishStacks", "count" } } },
}

local SKILLS = {
    captainZ = { "captainZ" },
    captainX = { "captainX" },
    captainC = { "captainC", "captainC_1" },
    captainV = { "captainV", "captainVboosted",
                 "captainBeaconHealing_1", "captainBeaconShocking_1", "captainBeaconResupply_1",
                 "captainBeaconHacking_1", "captainBeaconEnhance_1", "captainBeaconPunisher_1",
                 "captainUnavailable" },
}

local NS = "CaptainReturns"

local survivor = Survivor.find("captain", NS)
if not survivor then
    SPPMS.Captain = "absent"
    return
end

local VULCAN      = Util.find(ActorState, "vulcanShotgun", NS)
local TAZER       = Util.find(Object, "captainTazer", NS)
local PROBE       = Util.find(Object, "efCaptainProbe", NS)
local UNAVAILABLE = Util.find(Skill, "captainUnavailable", NS)

local BEACONS = {}
for i, kind in ipairs({ "Healing", "Shocking", "Resupply", "Hacking", "Enhance", "Punisher" }) do
    BEACONS[i] = Util.find(Object, "objCaptainBeacon"..kind, NS)
end

local S = Util.register(NS, T, SKILLS)

local tazer_stepping = Util.stepping(TAZER)
local probe_stepping = Util.stepping(PROBE)
local beacon_stepping = {}
for i, object in ipairs(BEACONS) do beacon_stepping[i] = Util.stepping(object) end

local function beacon_landing()
    for _, stepping in ipairs(beacon_stepping) do
        if stepping() then return true end
    end
    return false
end

local function scale_blast(args, mult)
    args[8].value = args[8].value * mult
    args[9].value = args[9].value * mult
end

Callback.add(VULCAN.on_step, Callback.Priority.AFTER, function(actor, data)
    if not Util.in_state(actor, VULCAN) then return end
    if (tonumber(data.fired) or 0) >= 1 then return end
    local timer = tonumber(data.chargetimer) or 0
    if timer <= 0 then return end
    local rank = api.rank(actor, S.captainZ)
    if rank < 1 then return end
    data.chargetimer = math.max(0, timer - actor.attack_speed * T.captainZ.chargeSpeed * rank)
end)

local SECONDARY, SPECIAL = 1, 3

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value then return end

    if tazer_stepping() then
        local rank = api.rank(actor, S.captainX)
        if rank < 1 then return end
        scale_blast(args, 1 + T.captainX.blastSize * rank)
        if actor:get_active_skill(SECONDARY).skill_id ~= S.captainX[1].value then
            args[4].value = args[4].value * (1 + T.captainX.damage * rank)
        end
    elseif probe_stepping() then
        local rank = api.rank(actor, S.captainC)
        if rank < 1 then return end
        scale_blast(args, 1 + T.captainC.blastSize * rank)
    elseif beacon_landing() then
        if actor:get_active_skill(SPECIAL).skill_id ~= UNAVAILABLE.value then return end
        local rank = api.rank(actor, S.captainV)
        if rank < 1 then return end
        args[4].value = args[4].value * (1 + T.captainV.damage * rank)
    end
end)

local BEACON_AWAKE  = 60
local BEACON_RADIUS = 135
local PUNISH_MAX    = 30

local HEALING, SHOCKING, RESUPPLY, HACKING, ENHANCE, PUNISHER = table.unpack(BEACONS)

local function beacon_rank(inst)
    return api.rank(inst.parent, S.captainV)
end

local function beacon_data(inst)
    if not Instance.exists(inst) then return nil end
    return Instance.get_data(inst, nil, NS)
end

local function faster_pulses(object, rate)
    Callback.add(object.on_step, Callback.Priority.AFTER, function(inst)
        local data = beacon_data(inst)
        if not data or data.beingcalled == 1 then return end
        local timer = tonumber(data.activetimer) or 0
        if timer <= BEACON_AWAKE then return end
        local rank = beacon_rank(inst)
        if rank < 1 then return end
        data.activetimer = timer + T.captainV[rate] * rank
    end)
end

faster_pulses(HEALING, "healRate")
faster_pulses(SHOCKING, "shockRate")

Callback.add(RESUPPLY.on_step, Callback.Priority.AFTER, function(inst)
    local data = beacon_data(inst)
    if not data then return end
    local left = tonumber(data.recharge) or -1
    if left <= 1 then return end
    local rank = beacon_rank(inst)
    if rank < 1 then return end
    local own = Instance.get_data(inst, nil, Util.NS)
    local due = (own.sppms_recharge or 0) + T.captainV.resupplyRecharge * rank
    data.recharge = left - math.min(math.floor(due), left - 1)
    own.sppms_recharge = due - math.floor(due)
end)

local function chests_near(inst)
    local list = List.new()
    inst:collision_ellipse_list(inst.x - BEACON_RADIUS, inst.y - BEACON_RADIUS,
        inst.x + BEACON_RADIUS, inst.y + BEACON_RADIUS, gm.constants.pInteractable, false, true, list, true)
    local chests = {}
    for _, chest in ipairs(list) do chests[#chests + 1] = chest end
    list:destroy()
    return chests
end

local function save_timers(object, field)
    Callback.add(object.on_step, Callback.Priority.BEFORE, function(inst)
        local data = beacon_data(inst)
        if not data or data.beingcalled == 1 or beacon_rank(inst) < 1 then return end
        local before = {}
        for _, chest in ipairs(chests_near(inst)) do
            before[chest.id] = tonumber(chest[field])
        end
        Instance.get_data(inst, nil, Util.NS).sppms_before = before
    end)
end

local function at_work_on(inst, takes)
    local own = Instance.get_data(inst, nil, Util.NS)
    local before = own.sppms_before or {}
    own.sppms_before = nil
    for _, chest in ipairs(chests_near(inst)) do
        if takes(chest, before) then return chest end
    end
    return nil
end

local HIDDEN_HAND = gm.constants.oHiddenHand
local ROBO_BUDDY  = gm.constants.oRoboBuddyBroken
local DOOR        = gm.constants.oDoor

local function hacking(chest, before)
    if chest.captainhacktimer == nil then return false end
    local kind = chest.object_index
    local takes, target
    if kind == HIDDEN_HAND then
        takes, target = chest.captainhacked == nil and chest.active >= 1, 15 * 60
    elseif kind == ROBO_BUDDY then
        takes, target = chest.captainhacked == nil, 22 * 60
    elseif kind == DOOR then
        takes, target = chest.active < 1, 15 * 60
    else
        takes = chest.cost ~= nil and chest.cost > 0 and chest.cost_type == 0 and chest.active < 1
        target = takes and chest.cost * 9
    end
    return takes and (before[chest.id] or 0) < target
end

save_timers(HACKING, "captainhacktimer")

Callback.add(HACKING.on_step, Callback.Priority.AFTER, function(inst)
    local data = beacon_data(inst)
    if not data or data.beingcalled == 1 or (tonumber(data.activetimer) or 0) < BEACON_AWAKE then return end
    local rank = beacon_rank(inst)
    if rank < 1 then return end
    local chest = at_work_on(inst, hacking)
    if not chest then return end
    local kind = chest.object_index
    local fill = 1
    if kind ~= HIDDEN_HAND and kind ~= ROBO_BUDDY and kind ~= DOOR then
        fill = GM._mod_game_getDirector().stage_chest_cost_scale
    end
    chest.captainhacktimer = chest.captainhacktimer + fill * T.captainV.hackSpeed * rank
end)

save_timers(ENHANCE, "captainUpTimer")

Callback.add(ENHANCE.on_step, Callback.Priority.AFTER, function(inst)
    local data = beacon_data(inst)
    if not data or data.beingcalled == 1 or (tonumber(data.activetimer) or 0) < BEACON_AWAKE then return end
    local rank = beacon_rank(inst)
    if rank < 1 then return end
    local chest = at_work_on(inst, function(chest, before)
        if chest.captainUpTimer == nil or data.no:contains(chest.object_index) then return false end
        local target
        if data.needsTwo:contains(chest.object_index) then
            if (tonumber(chest.enhanceCount) or 0) < 2 then return false end
            target = chest.cost * 90
        else
            if not (chest.cost ~= nil and chest.cost_type == 0 and chest.active < 1
                    and chest.captainUpgraded == nil) then return false end
            target = chest.cost * 60
        end
        return (before[chest.id] or 0) < target
    end)
    if not chest then return end
    local beacons = tonumber(chest.enhanceCount) or 0
    if beacons < 1 then return end
    local fill = GM._mod_game_getDirector().stage_chest_cost_scale / beacons
    chest.captainUpTimer = chest.captainUpTimer + fill * T.captainV.enhanceSpeed * rank
end)

Callback.add(PUNISHER.on_step, Callback.Priority.AFTER, function(inst)
    local data = beacon_data(inst)
    if not data or data.beingcalled ~= 0 or data.punished == nil then return end
    local own = Instance.get_data(inst, nil, Util.NS)
    if own.sppms_punish then return end
    own.sppms_punish = true
    local rank = beacon_rank(inst)
    if rank < 1 then return end
    local stacks = math.min(PUNISH_MAX, data.punished + T.captainV.punishStacks * rank)
    data.punished = math.max(data.punished, stacks)
end)

SPPMS.Captain = "ready"
