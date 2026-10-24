-- Улучшения навыков Reclaimer (мод Reclaimer и его копия в Worlds Incursion). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    reclaimerZ  = { damage = 0.10, doubleShotChance = 0.10,
                    text = { { "doubleShotChance", "pct" } } },
    reclaimerZ2 = { damage = 0.10, pierceChance = 0.10,
                    text = { { "pierceChance", "pct" } } },
    reclaimerZ3 = { pellets = 1, shotRange = 0.20,
                    text = { { "pellets", "count" }, { "shotRange", "pct" } } },
    reclaimerX  = { stock_every = 2, burstEvery = 2, burstMax = 2,
                    text = { { "burstEvery", "every", "burstMax", "count" } } },
    reclaimerX2 = { damage = 0.10, backSlash = 0.25, backSlashMax = 1.0,
                    text = { { "backSlash", "pct", "backSlashMax" } } },
    reclaimerX3 = { markSpread = 1, markSeconds = 1,
                    text = { { "markSpread", "count" }, { "markSeconds", "sec" } } },
    reclaimerC  = { strikeCooldown = 0.08,
                    text = { { "strikeCooldown", "pct" } } },
    reclaimerPrecisionC = { blastSize = 0.15, text = { { "blastSize", "pct" } } },
    reclaimerBarrageC   = { missiles = 1, text = { { "missiles", "count" } } },
    reclaimerGatlingC   = { missiles = 2, text = { { "missiles", "count" } } },
    reclaimerGodsendC   = { blastDamage = 0.15, text = { { "blastDamage", "pct" } } },
    reclaimerSmallC     = { blastSize = 0.25, text = { { "blastSize", "pct" } } },
    reclaimerBurstC     = { missileEvery = 2, text = { { "missileEvery", "every" } } },
    reclaimerV  = { cooldown = 0.95, useHeal = 0.05,
                    text = { { "useHeal", "pct" } } },
    reclaimerV2 = { cooldown = 0.95, stimSeconds = 1,
                    text = { { "stimSeconds", "sec" } } },
}

local SKILLS = {
    reclaimerZ  = { "ReclaimerZ" },
    reclaimerZ2 = { "reclaimerZ2" },
    reclaimerZ3 = { "reclaimerZ3" },
    reclaimerX  = { "ReclaimerX" },
    reclaimerX2 = { "reclaimerX2" },
    reclaimerX3 = { "reclaimerX3" },
    reclaimerC  = { "ReclaimerC" },
    reclaimerPrecisionC = { "reclaimerPrecisionStrike", "reclaimerPrecisionOrbital" },
    reclaimerBarrageC   = { "reclaimerBarrageStrike", "reclaimerMissileOrbital" },
    reclaimerGatlingC   = { "reclaimerGatlingStrike", "reclaimerGatlingOrbital" },
    reclaimerGodsendC   = { "reclaimerGodsendStrike", "reclaimerGodsendOrbital" },
    reclaimerSmallC     = { "reclaimerSmallStrike", "reclaimerSmallOrbital" },
    reclaimerBurstC     = { "reclaimerBurstStrike", "reclaimerBurstOrbital" },
    reclaimerV  = { "ReclaimerV", "reclaimerVBoosted" },
    reclaimerV2 = { "reclaimerv2", "reclaimerVBoosted2" },
}

local STRIKE_OBJECTS = {
    reclaimerPrecisionC = "efReclaimerMissile",
    reclaimerGodsendC   = "efReclaimerMissile2",
    reclaimerBarrageC   = "efReclaimerMissile3",
    reclaimerGatlingC   = "efReclaimerMissile4",
    reclaimerSmallC     = "efReclaimerMissile5",
    reclaimerBurstC     = "efReclaimerMissile6",
}

local VOLLEYS = {
    reclaimerBarrageC = { count = 7,  near = 100, far = 400 },
    reclaimerGatlingC = { count = 18, near = 100, far = 600 },
    reclaimerBurstC   = { count = 3,  near = 100, far = 250 },
}
local VOLLEY_SPACING = 10

local VARIANTS = {
    { ns = "ReclaimerSurvivor", survivor = "Reclaimer", base = "Reclaimer", plasma = "stateSecondary2" },
    { ns = "Worlds Collide",    survivor = "reclaimer", base = "reclaimer", plasma = "stateSecondary2m" },
}

local function skills_for(variant)
    local out = {}
    for key, ids in pairs(SKILLS) do
        local list = {}
        for i, id in ipairs(ids) do
            list[i] = (id:gsub("^Reclaimer", variant.base))
        end
        out[key] = list
    end
    return out
end

local SCEPTER = Util.find(Item, "ancientScepter", "ror")
local SHADOW  = Util.find(Buff, "shadowClone", "ror")
local ACTOR   = Util.constant("pActor")

local FPS = 60

local function scale_blast(args, mult)
    args[8].value = args[8].value * mult
    args[9].value = args[9].value * mult
end

local RIFLE_RANGE = 1400

local HAMMER_DEGRADE = 1 - 0.15

local PELLETS       = 9
local PELLET_RANGE  = 300
local PELLET_COEFF  = 0.55
local PELLET_SPREAD = 8
local CRACKER_RANGE = 700

local PISTOL_RANGE = 1400

local SLASH_KNOCKBACK = 6
local SLASH_STUN      = 1

local MARK_SECONDS  = 6
local DEATHMARK_TAG = 1
local SPREAD_REACH  = 300

local G3_SECONDS  = 10
local T60_SECONDS = 7

local firing_copy = false

local function prepare(v)
    local NS = v.ns
    local survivor = Survivor.find(v.survivor, NS)
    if not survivor then return nil end

    local PRIMARY    = Util.find(ActorState, "ReclaimerPrimary", NS)
    local PRIMARY2   = Util.find(ActorState, "ReclaimerPrimary2", NS)
    local PRIMARY3   = Util.find(ActorState, "ReclaimerPrimary3", NS)
    local SECONDARY  = Util.find(ActorState, "ReclaimerSecondary", NS)
    local SECONDARY2 = Util.find(ActorState, v.plasma, NS)
    local SPECIAL    = Util.find(ActorState, "reclaimerSpecial", NS)
    local SPECIAL2   = Util.find(ActorState, "reclaimerSpecial2", NS)
    local DEATHMARK  = Util.find(Buff, "reclaimerDeathmark", NS)
    local G3         = Util.find(Buff, "g3Stimulant", NS)
    local T60        = Util.find(Buff, "T60 Stimulant", NS)

    local PISTOL_SPARKS = Util.find(Sprite, "ReclaimerPistolSparks", NS).value
    local BLADE_SPARKS  = Util.find(Sprite, "ReclaimerBladeSparks", NS).value

    local MISSILES = {}
    for key, identifier in pairs(STRIKE_OBJECTS) do
        MISSILES[key] = Util.find(Object, identifier, NS)
    end

    local skills = skills_for(v)
    for _, ids in pairs(skills) do
        for _, id in ipairs(ids) do
            if not Skill.find(id, NS) then error("skill "..NS.."-"..id.." not found") end
        end
    end

    return function()
        local S = Util.register(NS, T, skills)

        local ORBITALS = {}
        for key in pairs(STRIKE_OBJECTS) do ORBITALS[#ORBITALS + 1] = S[key][2] end

        local strike_stepping = {}
        for key, object in pairs(MISSILES) do strike_stepping[key] = Util.stepping(object) end

        local function strike_exploding()
            for key, stepping in pairs(strike_stepping) do
                if stepping() then return key end
            end
            return nil
        end

        local cracker_shot = {}

        api.after_bullet(function(actor, attack, args, vanilla)
            if firing_copy or actor.class ~= survivor.value then return end

            if Util.in_state(actor, PRIMARY3) then
                if vanilla[6] == CRACKER_RANGE then cracker_shot[actor.id] = true end
                return
            end

            if not Util.in_state(actor, PRIMARY) or vanilla[6] ~= RIFLE_RANGE then return end
            local rank = api.rank(actor, S.reclaimerZ)
            if rank < 1 or math.random() >= T.reclaimerZ.doubleShotChance * rank then return end

            firing_copy = true
            local ok, copy = pcall(GM.SO.fire_bullet, actor, actor, table.unpack(vanilla, 1, vanilla.n))
            firing_copy = false
            if not ok then error(copy, 0) end
            copy.climb = 8 * 1.35
            copy.damage_degrade = HAMMER_DEGRADE
            copy.tracer_kind = Tracer.SNIPER2
            copy.damage_color = Color.WHITE_ALMOST
        end)

        api.on_bullet(function(actor, args)
            if actor.class ~= survivor.value then return end

            if Util.in_state(actor, PRIMARY2) then
                if args[6].value ~= RIFLE_RANGE or Util.bool(args[4].value) then return end
                local rank = api.rank(actor, S.reclaimerZ2)
                if rank < 1 or math.random() >= T.reclaimerZ2.pierceChance * rank then return end
                args[4].value = true

            elseif Util.in_state(actor, PRIMARY3) then
                local rank = api.rank(actor, S.reclaimerZ3)
                if rank < 1 then return end
                args[6].value = args[6].value * (1 + T.reclaimerZ3.shotRange * rank)
            end
        end)

        Callback.add(PRIMARY3.on_enter, Callback.Priority.AFTER, function(actor, data)
            data.sppms_pellets = nil
        end)

        Callback.add(PRIMARY3.on_step, Callback.Priority.AFTER, function(actor, data)
            if data.sppms_pellets or (tonumber(data.fired) or 0) < 1 then return end
            data.sppms_pellets = true
            local cracker = cracker_shot[actor.id]
            cracker_shot[actor.id] = nil
            if cracker or not Net.host or not Util.in_state(actor, PRIMARY3) then return end
            local rank = api.rank(actor, S.reclaimerZ3)
            if rank < 1 then return end

            local extra = T.reclaimerZ3.pellets * rank
            for i = 0, actor:buff_count(SHADOW) do
                for k = 1, extra do
                    local dir = actor:skill_util_facing_direction() + math.random(-PELLET_SPREAD, PELLET_SPREAD)
                    local shot = actor:fire_bullet(actor.x, actor.y - 10, PELLET_RANGE, dir, PELLET_COEFF, 1,
                        gm.constants.sSparks1, Tracer.SNIPER1)
                    shot.attack_info.climb = (PELLETS + k) * 8 + i * 8
                end
            end
        end)

        Callback.add(SECONDARY.on_enter, Callback.Priority.AFTER, function(actor, data)
            data.sppms_burst = 0
        end)

        Callback.add(SECONDARY.on_step, Callback.Priority.AFTER, function(actor, data)
            if not Util.in_state(actor, SECONDARY) then return end
            local rank = api.rank(actor, S.reclaimerX)
            local extra = math.min(math.floor(rank / T.reclaimerX.burstEvery), T.reclaimerX.burstMax)
            local fired = data.sppms_burst or 0
            if fired >= extra or actor.image_index2 < 1 + fired * 2 then return end
            data.sppms_burst = fired + 1

            for i = 0, actor:buff_count(SHADOW) do
                local shot = actor:fire_bullet(actor.x, actor.y, PISTOL_RANGE, actor:skill_util_facing_direction(),
                    S.reclaimerX[1].damage, nil, PISTOL_SPARKS, Tracer.BANDIT1)
                shot.attack_info.climb = 8 * 1.35
            end
            actor:sound_play(gm.constants.wBullet3, 1, 0.65 + math.random() * 0.15)
        end)

        api.after_explosion(function(actor, attack, args, vanilla)
            if firing_copy or actor.class ~= survivor.value or not Util.in_state(actor, SECONDARY2) then return end
            if vanilla[5] ~= BLADE_SPARKS then return end
            local rank = api.rank(actor, S.reclaimerX2)
            if rank < 1 then return end

            local back = table.pack(table.unpack(vanilla, 1, vanilla.n))
            back[2] = 2 * actor.x - vanilla[2]
            back[4] = vanilla[4] * math.min(T.reclaimerX2.backSlash * rank, T.reclaimerX2.backSlashMax)

            firing_copy = true
            local ok, copy = pcall(GM.SO.fire_explosion, actor, actor, table.unpack(back, 1, back.n))
            firing_copy = false
            if not ok then error(copy, 0) end
            copy.climb = 8 * 1.35
            copy.knockback = copy.knockback + SLASH_KNOCKBACK
            copy.knockback_direction = -actor.image_xscale
            copy.stun = SLASH_STUN
            copy.damage_color = Color.WHITE_ALMOST
        end)

        api.on_explosion(function(actor, args)
            if actor.class ~= survivor.value then return end
            local key = strike_exploding()
            if not key then return end
            local rank = api.rank(actor, S.reclaimerC)
            if rank < 1 then return end
            local def = T[key]
            if def.blastSize then scale_blast(args, 1 + def.blastSize * rank) end
            if def.blastDamage then args[4].value = args[4].value * (1 + def.blastDamage * rank) end
        end)

        for key, volley in pairs(VOLLEYS) do
            local def, missile = T[key], MISSILES[key]
            Callback.add(S[key][2].on_activate, Callback.Priority.AFTER, function(actor)
                local rank = api.rank(actor, S.reclaimerC)
                local extra = def.missiles and def.missiles * rank or math.floor(rank / def.missileEvery)
                for k = 1, extra do
                    Alarm.add((volley.count + k) * VOLLEY_SPACING, function()
                        if not Util.bool(Global.__run_exists) or not Instance.exists(actor) then return end
                        local inst = missile:create(actor.x + math.random(volley.near, volley.far) * actor.image_xscale,
                            actor.y)
                        inst.parent = actor
                    end)
                end
            end)
        end

        local function shorter_strike(actor, skill, slot)
            local rank = api.rank(actor, S.reclaimerC)
            if rank < 1 then return end
            local own = ActorSkill.wrap(actor:get_active_skill(slot))
            local stopwatch = own.cooldown_stopwatch.value
            if not gm.stopwatch_is_active(stopwatch) then return end
            local left = gm.stopwatch_get_duration_remaining(stopwatch)
            own:override_cooldown(math.floor(left * (1 - T.reclaimerC.strikeCooldown) ^ rank))
        end

        for _, strike in ipairs(ORBITALS) do
            Callback.add(strike.on_activate, Callback.Priority.AFTER, shorter_strike)
        end

        local marker_key = "sppms_marker_"..NS

        local function mark_frames(rank)
            return (MARK_SECONDS + T.reclaimerX3.markSeconds * rank) * FPS
        end

        Callback.add(Callback.ON_ATTACK_HIT, Callback.Priority.AFTER, function(hit_info)
            if not Net.host then return end
            local attack = hit_info.attack_info
            if attack.reclaimerDeathmark ~= DEATHMARK_TAG then return end
            local reclaimer = attack.parent
            if not Instance.exists(reclaimer) or reclaimer.class ~= survivor.value then return end
            local victim = hit_info.target
            if not Instance.exists(victim) or victim:buff_count(DEATHMARK) == 0 then return end
            Instance.get_data(victim, nil, Util.NS)[marker_key] = reclaimer
            local rank = api.rank(reclaimer, S.reclaimerX3)
            if rank > 0 then GM.set_buff_time(victim, DEATHMARK, mark_frames(rank)) end
        end)

        Callback.add(Callback.ON_KILL_PROC, function(victim, killer)
            if not Net.host or victim:buff_count(DEATHMARK) == 0 then return end
            local marker = Instance.get_data(victim, nil, Util.NS)[marker_key]
            if not marker or not Instance.exists(marker) then return end
            local rank = api.rank(marker, S.reclaimerX3)
            if rank < 1 then return end

            local near = {}
            for _, enemy in ipairs(Instance.find_all(ACTOR)) do
                if Instance.exists(enemy) and enemy.id ~= victim.id and enemy:buff_count(DEATHMARK) == 0
                        and Util.bool(GM.actor_canhit(marker, enemy)) then
                    local dx, dy = enemy.x - victim.x, enemy.y - victim.y
                    local d = dx * dx + dy * dy
                    if d <= SPREAD_REACH * SPREAD_REACH then near[#near + 1] = { enemy = enemy, d = d } end
                end
            end
            table.sort(near, function(a, b) return a.d < b.d end)

            for i = 1, math.min(T.reclaimerX3.markSpread * rank, #near) do
                local enemy = near[i].enemy
                GM.apply_buff(enemy, DEATHMARK, mark_frames(rank), 1)
                Instance.get_data(enemy, nil, Util.NS)[marker_key] = marker
            end
        end)

        local function on_use(state, fn)
            Callback.add(state.on_enter, Callback.Priority.AFTER, function(actor, data)
                data.sppms_stim = nil
            end)
            Callback.add(state.on_step, Callback.Priority.AFTER, function(actor, data)
                if data.sppms_stim or not Util.in_state(actor, state) then return end
                if (tonumber(data.fired) or 0) < 1 then return end
                data.sppms_stim = true
                if not Net.host then return end
                fn(actor, actor:item_count(SCEPTER) > 0)
            end)
        end

        on_use(SPECIAL, function(actor, scepter)
            local rank = api.rank(actor, S.reclaimerV)
            if rank < 1 then return end
            GM.actor_heal_networked(actor, actor.maxhp * T.reclaimerV.useHeal * rank, false)
        end)

        on_use(SPECIAL2, function(actor, scepter)
            local buff, seconds = G3, G3_SECONDS
            if scepter then buff, seconds = T60, T60_SECONDS end
            local rank = api.rank(actor, S.reclaimerV2)
            local frames = (seconds + T.reclaimerV2.stimSeconds * rank) * FPS

            if not Util.bool(actor.local_client_is_authority) then
                if actor:buff_count(buff) == 0 then
                    GM.apply_buff(actor, buff, frames, 1)
                else
                    GM.set_buff_time(actor, buff, frames)
                end
            elseif rank > 0 and actor:buff_count(buff) > 0 then
                GM.set_buff_time(actor, buff, frames)
            end
        end)
    end
end

local installs = {}
for _, variant in ipairs(VARIANTS) do
    local install = prepare(variant)
    if install then installs[#installs + 1] = install end
end
for _, install in ipairs(installs) do install() end

SPPMS.Reclaimer = #installs > 0 and "ready" or "absent"
