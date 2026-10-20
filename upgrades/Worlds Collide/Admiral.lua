-- Улучшения навыков Admiral (мод Worlds Incursion). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    admiralZ  = { damage = 0.10, doubleShotChance = 0.10,
                  text = { { "doubleShotChance", "pct" } } },
    admiralZ2 = { damage = 0.10, pierceChance = 0.10,
                  text = { { "pierceChance", "pct" } } },
    admiralX  = { damage = 0.10, whipReach = 0.15, sweetSpotDamage = 0.10,
                  text = { { "whipReach", "pct" }, { "sweetSpotDamage", "pct" } } },
    admiralC  = { stock_every = 2, summonPower = 0.15,
                  text = { { "summonPower", "pct" } } },
    admiralC2 = { stock_every = 2, summonPower = 0.15,
                  text = { { "summonPower", "pct" } } },
    admiralC3 = { stock_every = 2, summonPower = 0.15,
                  text = { { "summonPower", "pct" } } },
    admiralC4 = { stock_every = 2, summonPower = 0.15,
                  text = { { "summonPower", "pct" } } },
    admiralC5 = { stock_every = 2, summonPower = 0.15,
                  text = { { "summonPower", "pct" } } },
    admiralC6 = { stock_every = 2, summonPower = 0.15,
                  text = { { "summonPower", "pct" } } },
    admiralC7 = { stock_every = 2, summonPower = 0.15,
                  text = { { "summonPower", "pct" } } },
    admiralC8 = { stock_every = 2, summonPower = 0.15,
                  text = { { "summonPower", "pct" } } },
    admiralC9 = { stock_every = 2, summonPower = 0.15,
                  text = { { "summonPower", "pct" } } },
    admiralV  = { beaconRadius = 0.15, beaconHeal = 0.01,
                  text = { { "beaconRadius", "pct" }, { "beaconHeal", "pct" } } },
}

local SKILLS = {
    admiralZ  = { "AdmiralZ" },
    admiralZ2 = { "admiralZ2" },
    admiralX  = { "AdmiralX" },
    admiralC  = { "AdmiralC" },
    admiralC2 = { "admiralC2" },
    admiralC3 = { "admiralC3" },
    admiralC4 = { "admiralC4" },
    admiralC5 = { "admiralC5" },
    admiralC6 = { "admiralC6" },
    admiralC7 = { "admiralC7" },
    admiralC8 = { "admiralC8" },
    admiralC9 = { "admiralC9" },
    admiralV  = { "AdmiralV", "admiralVBoosted" },
}

local NS = "Worlds Collide"

local survivor = Survivor.find("Admiral", NS)
if not survivor then
    SPPMS.Admiral = "absent"
    return
end

local PRIMARY   = Util.find(ActorState, "admiralPrimary", NS)
local PRIMARY2  = Util.find(ActorState, "admiralPrimary2", NS)
local SECONDARY = Util.find(ActorState, "admiralSecondary", NS)
local BEACON    = Util.find(Object, "aoethingy", NS)
local BEACON2   = Util.find(Object, "aoethingy2", NS)

local SUMMONS = {
    { key = "admiralC",  state = "admiralUtility",  object = "oLizard" },
    { key = "admiralC2", state = "admiralUtility2", object = "oImp" },
    { key = "admiralC3", state = "admiralUtility3", object = "oChild" },
    { key = "admiralC4", state = "admiralUtility4", object = "oSpider" },
    { key = "admiralC5", state = "admiralUtility5", object = "oWisp" },
    { key = "admiralC6", state = "admiralUtility6", object = "oBug" },
    { key = "admiralC7", state = "admiralUtility7", object = "oSlime2" },
    { key = "admiralC8", state = "admiralUtility8", object = "oClay" },
    { key = "admiralC9", state = "admiralUtility9", object = "oMush" },
}
for _, summon in ipairs(SUMMONS) do
    summon.state  = Util.find(ActorState, summon.state, NS)
    summon.object = Util.constant(summon.object)
end

local LASH_SPARKS = Util.constant("sSparks2")
local TIP_SPARKS  = Util.constant("sSparks3")

local OP    = gm.constants.oP
local ACTOR = Util.constant("pActor")

local S = Util.register(NS, T, SKILLS)

local PISTOL_RANGE = 1400

local firing_copy = false

api.after_bullet(function(actor, attack, args, vanilla)
    if firing_copy or actor.class ~= survivor.value or not Util.in_state(actor, PRIMARY) then return end
    if vanilla[6] ~= PISTOL_RANGE then return end
    local rank = api.rank(actor, S.admiralZ)
    if rank < 1 or math.random() >= T.admiralZ.doubleShotChance * rank then return end

    firing_copy = true
    local ok, copy = pcall(GM.SO.fire_bullet, actor, actor, table.unpack(vanilla, 1, vanilla.n))
    firing_copy = false
    if not ok then error(copy, 0) end
    copy.climb = 8 * 1.35
    copy.tracer_kind = Tracer.BANDIT1
    copy.damage_color = Color.WHITE_ALMOST
end)

api.on_bullet(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, PRIMARY2) then return end
    if args[6].value ~= PISTOL_RANGE or Util.bool(args[4].value) then return end
    local rank = api.rank(actor, S.admiralZ2)
    if rank < 1 or math.random() >= T.admiralZ2.pierceChance * rank then return end
    args[4].value = true
end)

local LASH_OFFSET = 50
local LASH_WIDTH  = 165
local TIP_OFFSET  = 140

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, SECONDARY) then return end
    local sparks = args[5].value
    if sparks ~= LASH_SPARKS and sparks ~= TIP_SPARKS then return end
    local rank = api.rank(actor, S.admiralX)
    if rank < 1 then return end
    local reach = 1 + T.admiralX.whipReach * rank
    local facing = actor.image_xscale

    if sparks == LASH_SPARKS then
        local back  = LASH_OFFSET - LASH_WIDTH / 2
        local front = (LASH_OFFSET + LASH_WIDTH / 2) * reach
        args[8].value = args[8].value * (front - back) / LASH_WIDTH
        args[2].value = actor.x + (front + back) / 2 * facing
    else
        args[2].value = actor.x + TIP_OFFSET * reach * facing
        args[4].value = args[4].value * (1 + T.admiralX.sweetSpotDamage * rank)
    end
end)

local summon_power = {}

for _, summon in ipairs(SUMMONS) do
    local key, state, object = summon.key, summon.state, summon.object

    Callback.add(state.on_enter, Callback.Priority.AFTER, function(actor, data)
        data.sppms_summon = nil
    end)

    Callback.add(state.on_step, Callback.Priority.AFTER, function(actor, data)
        if data.sppms_summon or (tonumber(data.fired) or 0) < 1 then return end
        data.sppms_summon = true
        local rank = api.rank(actor, S[key])
        if rank < 1 then return end

        local newest = nil
        for _, inst in ipairs(Instance.find_all(object)) do
            if inst.team == actor.team and (not newest or inst.id > newest.id) then newest = inst end
        end
        if not newest then return end
        summon_power[newest.id] = T[key].summonPower * rank
        newest:queue_recalculate_stats()
    end)
end

RecalculateStats.add(function(actor, stats)
    local power = summon_power[actor.id]
    if not power then return end
    stats.maxhp_mult(1 + power)
    stats.damage_mult(1 + power)
end)

Callback.add(Callback.ON_GAME_START, function()
    summon_power = {}
end)

local BEACON_PULSE = 60

local function beacon_owner(inst)
    local synced = not Net.host and (tonumber(inst.m_id) or -1) >= 0
    local best, best_d = nil, nil
    for _, player in ipairs(Instance.find_all(OP)) do
        if player.class == survivor.value then
            local is_local = Util.bool(player.local_client_is_authority)
            if not synced then
                if is_local then return player end
            elseif not is_local then
                local d = (player.x - inst.x) ^ 2 + (player.y - inst.y) ^ 2
                if not best_d or d < best_d then best, best_d = player, d end
            end
        end
    end
    return best
end

for _, beacon in ipairs({ BEACON, BEACON2 }) do
    Util.on_first_step(beacon, function(inst)
        local owner = beacon_owner(inst)
        if not owner then return end
        local rank = api.rank(owner, S.admiralV)
        if rank < 1 then return end
        local data = Instance.get_data(inst, nil, NS)
        data.range = data.range * (1 + T.admiralV.beaconRadius * rank)
        Instance.get_data(inst, nil, Util.NS).sppms_rank = rank
    end)

    Callback.add(beacon.on_step, Callback.Priority.AFTER, function(inst)
        if not Net.host or not Instance.exists(inst) then return end
        local rank = Instance.get_data(inst, nil, Util.NS).sppms_rank
        if not rank then return end
        local data = Instance.get_data(inst, nil, NS)
        if data.timer ~= BEACON_PULSE then return end
        for _, ally in ipairs(Instance.find_all(ACTOR)) do
            if ally.team == inst.team and ally:distance_to_object(inst) < data.range then
                ally:heal(math.ceil(ally.maxhp * T.admiralV.beaconHeal * rank))
            end
        end
    end)
end

SPPMS.Admiral = "ready"
