-- Улучшения навыков MULE (Starstorm Returns). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    muleZ = { chargeSpeed = 0.10, slamSize = 0.15,
              text = { { "chargeSpeed", "pct" }, { "slamSize", "pct" } } },
    muleX = { damage = 0.10, snareCount = 1,
              text = { { "snareCount", "count" } } },
    muleC = { stock_every = 2, spinInvuln = 0.15, spinInvulnMax = 1.0,
              text = { { "spinInvuln", "sec", "spinInvulnMax" } } },
    muleV = { healShare = 0.01, droneSeconds = 1,
              text = { { "healShare", "pct" }, { "droneSeconds", "sec" } } },
}

local SKILLS = {
    muleZ = { "muleZ" },
    muleX = { "muleX" },
    muleC = { "muleC" },
    muleV = { "muleV", "muleVBoosted" },
}

local survivor = Survivor.find("mule", "ssr")
if not survivor then
    SPPMS.Mule = "absent"
    return
end

local CHARGE  = Util.find(ActorState, "mulePrimaryCharge", "ssr")
local SLAM    = Util.find(ActorState, "mulePrimarySlam", "ssr")
local UTILITY = Util.find(ActorState, "muleUtility", "ssr")
local SNARE   = Util.find(Buff, "muleSnare", "ssr")
local DRONE   = Util.find(Object, "muleDrone", "ssr")

local S = Util.register("ssr", T, SKILLS)

local OP = gm.constants.oP
local FPS = 60

local CHARGE_RATE = 0.06

Callback.add(CHARGE.on_step, Callback.Priority.AFTER, function(actor, data)
    if not Util.in_state(actor, CHARGE) then return end
    if (tonumber(data.fired) or 0) >= 1 then return end
    local rank = api.rank(actor, S.muleZ)
    if rank < 1 then return end
    local rate = CHARGE_RATE * actor.attack_speed
    local faster = math.min(rate * (1 + T.muleZ.chargeSpeed * rank), 1)
    if Util.bool(actor.state_strafe_half) then
        actor.image_index2 = actor.image_index2 + faster - math.min(rate, 1)
    else
        actor.image_speed = faster
    end
end)

local SLAM_COEFF = 10

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, SLAM) then return end
    if args[4].value ~= SLAM_COEFF then return end
    local rank = api.rank(actor, S.muleZ)
    if rank < 1 then return end
    local scale = 1 + T.muleZ.slamSize * rank
    args[8].value = args[8].value * scale
    args[9].value = args[9].value * scale
end)

local SNARE_FRAMES = 3 * FPS
local ELLIPSE_W, ELLIPSE_H = 280, 200

Callback.add(Callback.ON_ATTACK_HIT, Callback.Priority.AFTER, function(hit_info)
    local attack = hit_info.attack_info
    if attack.mule_immobilize ~= 1 or (tonumber(attack.climb) or 0) > 0 then return end
    local mule = attack.parent
    if not Instance.exists(mule) or mule.object_index ~= OP then return end
    local rank = api.rank(mule, S.muleX)
    if rank < 1 then return end

    local target = hit_info.target
    if not Instance.exists(target) then return end
    local extra = T.muleX.snareCount * rank
    local victims = List.new()
    target:collision_ellipse_list(target.x - ELLIPSE_W, target.y - ELLIPSE_H,
        target.x + ELLIPSE_W, target.y + ELLIPSE_H, gm.constants.pActor, false, false, victims, true)
    for _, victim in ipairs(victims) do
        if extra < 1 then break end
        if victim.team == target.team and victim:buff_count(SNARE) == 0 then
            GM.apply_buff(victim, SNARE, SNARE_FRAMES, 1)
            extra = extra - 1
        end
    end
    victims:destroy()
end)

local SPIN_FRAME = 4

Callback.add(UTILITY.on_enter, Callback.Priority.AFTER, function(actor, data)
    data.sppms_spin = nil
end)

Callback.add(UTILITY.on_step, Callback.Priority.AFTER, function(actor, data)
    if not Util.in_state(actor, UTILITY) or data.sppms_spin or actor.image_index < SPIN_FRAME then return end
    data.sppms_spin = true
    local rank = api.rank(actor, S.muleC)
    if rank < 1 then return end
    Util.grant_invuln(actor, math.min(T.muleC.spinInvuln * rank, T.muleC.spinInvulnMax))
end)

Util.on_first_step(DRONE, function(inst)
    local data = Instance.get_data(inst, nil, "ssr")
    local parent = data.parent
    if not Instance.exists(parent) then return end
    local rank = api.rank(parent, S.muleV)
    if rank < 1 then return end
    data.regen = data.regen + parent.maxhp * T.muleV.healShare * rank
    data.life = data.life + T.muleV.droneSeconds * FPS * rank
end)

SPPMS.Mule = "ready"
