-- Улучшения навыков для ванильных выживших (мод Worlds Incursion). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    wcBanditZ   = { pellets = 1, pierceChance = 0.10,
                    text = { { "pellets", "count" }, { "pierceChance", "pct" } } },
    wcBanditX   = { damage = 0.10, whipReach = 0.15, stunChance = 0.10,
                    text = { { "whipReach", "pct" }, { "stunChance", "pct" } } },
    wcEnforcerZ = { damage = 0.10, pierceChance = 0.10, stancePellets = 1,
                    text = { { "pierceChance", "pct" }, { "stancePellets", "count" } } },
    wcEnforcerV = { blastSize = 0.15, tauntSeconds = 1,
                    text = { { "blastSize", "pct" }, { "tauntSeconds", "sec" } } },
    wcEngineerZ = { pellets = 2, shotRange = 0.20,
                    text = { { "pellets", "count" }, { "shotRange", "pct" } } },
    wcEngineerC = { cooldown = 0.92, statCostCut = 0.10, statCostCutMax = 0.8,
                    text = { { "statCostCut", "pct", "statCostCutMax" } } },
    wcHandZ     = { damage = 0.10, shotRange = 0.20, burnChance = 0.10,
                    text = { { "shotRange", "pct" }, { "burnChance", "pct" } } },
    wcHandC     = { cooldown = 0.92, boostSeconds = 1, boostShield = 0.05,
                    text = { { "boostSeconds", "sec" }, { "boostShield", "pct" } } },
}

local SKILLS = {
    wcBanditZ   = { "Blast" },
    wcBanditX   = { "Lash" },
    wcEnforcerZ = { "Slug" },
    wcEnforcerV = { "Rip" },
    wcEngineerZ = { "Shotty" },
    wcEngineerC = { "Beaco" },
    wcHandZ     = { "Bang" },
    wcHandC     = { "Bolster" },
}

local NS = "Worlds Collide"

local function present(key)
    for _, id in ipairs(SKILLS[key]) do
        if not Skill.find(id, NS) then
            SKILLS[key] = nil
            return false
        end
    end
    return true
end

local has_scatter    = present("wcBanditZ")
local has_lash       = present("wcBanditX")
local has_trenchboom = present("wcEnforcerZ")
local has_ripcord    = present("wcEnforcerV")
local has_blastgun   = present("wcEngineerZ")
local has_flame      = present("wcEngineerC")
local has_assualt    = present("wcHandZ")
local has_bolster    = present("wcHandC")
if not (has_scatter or has_lash or has_trenchboom or has_ripcord
        or has_blastgun or has_flame or has_assualt or has_bolster) then
    SPPMS.WorldsIncursion = "absent"
    return
end

local SCATTER    = has_scatter    and Util.find(ActorState, "Blast", NS)
local LASH       = has_lash       and Util.find(ActorState, "Lash", NS)
local TRENCHBOOM = has_trenchboom and Util.find(ActorState, "Slug", NS)
local GRENADE    = has_ripcord    and Util.find(Object, "EnforcerTGrenade", NS)
local TAUNT      = has_ripcord    and Util.find(Buff, "enforcerTaunt", NS)
local BLASTGUN   = has_blastgun   and Util.find(ActorState, "Shotty", NS)
local FLAMY      = has_flame      and Util.find(Item, "Flamy", NS)
local ASSUALT    = has_assualt    and Util.find(ActorState, "Bang", NS)
local BOLSTER    = has_bolster    and Util.find(ActorState, "Bolster", NS)
local BOLSTERED  = has_bolster    and Util.find(Buff, "HANDBolster", NS)

local SPARKS1   = Util.constant("sSparks1")
local SPARKS2   = Util.constant("sSparks2")
local AMETHYST  = Util.constant("sEfAmethyst")
local BITE6     = Util.constant("sBite6")
local BITE7     = Util.constant("sBite7")
local BLOOD     = Util.constant("sEfBloodExplosion")
local SHADOW    = Util.find(Buff, "shadowClone", "ror")

local S = Util.register(NS, T, SKILLS)

local FPS = 60

local STUN_FRAMES = 90

local function after_fire(state, fn)
    Callback.add(state.on_enter, Callback.Priority.AFTER, function(actor, data)
        data.sppms_fired = nil
    end)
    Callback.add(state.on_step, Callback.Priority.AFTER, function(actor, data)
        if data.sppms_fired or (tonumber(data.fired) or 0) < 1 then return end
        data.sppms_fired = true
        fn(actor)
    end)
end

local cracker_shot = {}

if has_scatter or has_blastgun then
    api.after_bullet(function(actor, attack, args, vanilla)
        if vanilla[7] ~= SPARKS1 then return end
        if (has_scatter and Util.in_state(actor, SCATTER))
                or (has_blastgun and Util.in_state(actor, BLASTGUN)) then
            cracker_shot[actor.id] = true
        end
    end)
end

local function host_pellets(state, key, fire)
    after_fire(state, function(actor)
        local cracker = cracker_shot[actor.id]
        cracker_shot[actor.id] = nil
        if cracker or not Net.host then return end
        local rank = api.rank(actor, S[key])
        if rank < 1 then return end
        for i = 0, actor:buff_count(SHADOW) do
            for k = 1, T[key].pellets * rank do fire(actor, i, k) end
        end
    end)
end

if has_scatter then
    local PELLETS = 6
    local RANGE   = 500
    local COEFF   = 0.45
    local SPREAD  = 8

    host_pellets(SCATTER, "wcBanditZ", function(actor, i, k)
        local dir = actor:skill_util_facing_direction() + math.random(-SPREAD, SPREAD)
        local shot = actor:fire_bullet(actor.x, actor.y, RANGE, dir, COEFF, nil, AMETHYST, Tracer.BANDIT1)
        shot.attack_info.climb = (PELLETS + k) * 8 + i * 8
    end)

    api.on_bullet(function(actor, args)
        if not Util.in_state(actor, SCATTER) or args[7].value ~= AMETHYST then return end
        if Util.bool(args[4].value) then return end
        local rank = api.rank(actor, S.wcBanditZ)
        if rank < 1 or math.random() >= T.wcBanditZ.pierceChance * rank then return end
        args[4].value = true
    end)
end

if has_lash then
    local LASH_STUN = 1 * FPS / STUN_FRAMES

    api.on_explosion(function(actor, args)
        if not Util.in_state(actor, LASH) or args[5].value ~= SPARKS2 then return end
        local rank = api.rank(actor, S.wcBanditX)
        if rank < 1 then return end
        local mult = 1 + T.wcBanditX.whipReach * rank
        args[2].value = actor.x + (args[2].value - actor.x) * mult
        args[8].value = args[8].value * mult
    end)

    api.after_explosion(function(actor, attack, args, vanilla)
        if not Util.in_state(actor, LASH) or vanilla[5] ~= SPARKS2 then return end
        local rank = api.rank(actor, S.wcBanditX)
        if rank < 1 or math.random() >= T.wcBanditX.stunChance * rank then return end
        attack.stun = math.max(tonumber(attack.stun) or 0, LASH_STUN)
    end)
end

if has_trenchboom then
    local SLUG_RANGE    = 1400
    local PELLETS       = 9
    local PELLET_RANGE  = 175
    local PELLET_COEFF  = 0.35
    local PELLET_SPREAD = 8

    api.on_bullet(function(actor, args)
        if not Util.in_state(actor, TRENCHBOOM) or args[7].value ~= BITE7 then return end
        if args[6].value ~= SLUG_RANGE or Util.bool(args[4].value) then return end
        local rank = api.rank(actor, S.wcEnforcerZ)
        if rank < 1 or math.random() >= T.wcEnforcerZ.pierceChance * rank then return end
        args[4].value = true
    end)

    after_fire(TRENCHBOOM, function(actor)
        if not Util.bool(actor.local_client_is_authority) or not Util.bool(actor.bunker) then return end
        local rank = api.rank(actor, S.wcEnforcerZ)
        if rank < 1 then return end
        for i = 0, actor:buff_count(SHADOW) do
            for k = 1, T.wcEnforcerZ.stancePellets * rank do
                local dir = actor:skill_util_facing_direction() + math.random(-PELLET_SPREAD, PELLET_SPREAD)
                local shot = actor:fire_bullet(actor.x, actor.y - 10, PELLET_RANGE, dir, PELLET_COEFF, 1,
                    AMETHYST, Tracer.BANDIT1)
                shot.attack_info.climb = (PELLETS + k) * 8 + i * 8
            end
        end
    end)
end

if has_ripcord then
    local TAUNT_SECONDS = 5
    local TAUNT_TAG     = 1

    local grenade_stepping = Util.stepping(GRENADE)

    api.on_explosion(function(actor, args)
        if not grenade_stepping() or args[7].value ~= BLOOD then return end
        local rank = api.rank(actor, S.wcEnforcerV)
        if rank < 1 then return end
        local scale = 1 + T.wcEnforcerV.blastSize * rank
        args[8].value = args[8].value * scale
        args[9].value = args[9].value * scale
    end)

    Callback.add(Callback.ON_ATTACK_HIT, Callback.Priority.AFTER, function(hit_info)
        if not Net.host then return end
        local attack = hit_info.attack_info
        if attack.enforcerTaunt ~= TAUNT_TAG then return end
        local enforcer = attack.parent
        if not Instance.exists(enforcer) then return end
        local rank = api.rank(enforcer, S.wcEnforcerV)
        if rank < 1 then return end
        local victim = hit_info.target
        if not Instance.exists(victim) or victim:buff_count(TAUNT) == 0 then return end
        GM.set_buff_time(victim, TAUNT, (TAUNT_SECONDS + T.wcEnforcerV.tauntSeconds * rank) * FPS)
    end)
end

if has_blastgun then
    local PELLETS = 15
    local RANGE   = 200
    local COEFF   = 0.15
    local SPREAD  = 12

    host_pellets(BLASTGUN, "wcEngineerZ", function(actor, i, k)
        local dir = actor:skill_util_facing_direction() + math.random(-SPREAD, SPREAD)
        local shot = actor:fire_bullet(actor.x, actor.y, RANGE, dir, COEFF, 1, SPARKS2, Tracer.BANDIT1)
        shot.attack_info.climb = (PELLETS + k) * 8 + i * 8
    end)

    api.on_bullet(function(actor, args)
        if not Util.in_state(actor, BLASTGUN) or args[7].value ~= SPARKS2 or args[6].value ~= RANGE then return end
        local rank = api.rank(actor, S.wcEngineerZ)
        if rank < 1 then return end
        args[6].value = args[6].value * (1 + T.wcEngineerZ.shotRange * rank)
    end)
end

if has_flame then
    local SPEED  = 0.15
    local ARMOR  = 0.25
    local HEALTH = 35
    local DAMAGE = 0.03

    RecalculateStats.add(function(actor, stats)
        local stack = actor:item_count(FLAMY)
        if stack <= 0 then return end
        local rank = api.rank(actor, S.wcEngineerC)
        if rank < 1 then return end
        local back = stack * math.min(T.wcEngineerC.statCostCut * rank, T.wcEngineerC.statCostCutMax)
        stats.pHmax_add(SPEED * back)
        stats.armor_add(ARMOR * back)
        stats.maxhp_add(HEALTH * back)
        stats.damage_add(DAMAGE * back)
    end)
end

if has_assualt then
    local RANGE    = 325
    local LAST_DY  = -15

    local BURN_TWICE = AttackFlag.new("sppmsBangBurn")

    api.on_bullet(function(actor, args)
        if not Util.in_state(actor, ASSUALT) or args[7].value ~= BITE6 or args[6].value ~= RANGE then return end
        local rank = api.rank(actor, S.wcHandZ)
        if rank < 1 then return end
        args[6].value = args[6].value * (1 + T.wcHandZ.shotRange * rank)
    end)

    api.after_bullet(function(actor, attack, args, vanilla)
        if not Util.in_state(actor, ASSUALT) or vanilla[7] ~= BITE6 or vanilla[6] ~= RANGE then return end
        if vanilla[3] ~= actor.y + LAST_DY or api.rank(actor, S.wcHandZ) < 1 then return end
        AttackInfo.wrap(attack):set_flag(BURN_TWICE, true)
    end)

    Callback.add(Callback.ON_ATTACK_HIT, function(hit_info)
        if not Net.host or not hit_info.attack_info:get_flag(BURN_TWICE) then return end
        local actor = hit_info.inflictor
        if not Instance.exists(actor) then return end
        local rank = api.rank(actor, S.wcHandZ)
        if rank < 1 or math.random() >= T.wcHandZ.burnChance * rank then return end
        local victim = hit_info.target
        if not Instance.exists(victim) then return end
        victim:apply_dot(0.3, 5, 30, hit_info, Color.ORANGE, false)
    end)
end

if has_bolster then
    local BOLSTER_SECONDS = 10

    after_fire(BOLSTER, function(actor)
        if not Net.host then return end
        local rank = api.rank(actor, S.wcHandC)
        local frames = (BOLSTER_SECONDS + T.wcHandC.boostSeconds * rank) * FPS
        if not Util.bool(actor.local_client_is_authority) then
            if actor:buff_count(BOLSTERED) == 0 then
                GM.apply_buff(actor, BOLSTERED, frames, 1)
            else
                GM.set_buff_time(actor, BOLSTERED, frames)
            end
        elseif rank > 0 and actor:buff_count(BOLSTERED) > 0 then
            GM.set_buff_time(actor, BOLSTERED, frames)
        end
    end)

    RecalculateStats.add(function(actor, stats)
        if actor:buff_count(BOLSTERED) == 0 then return end
        local rank = api.rank(actor, S.wcHandC)
        if rank > 0 then stats.maxshield_add_from_maxhp(T.wcHandC.boostShield * rank) end
    end)
end

SPPMS.WorldsIncursion = "ready"
