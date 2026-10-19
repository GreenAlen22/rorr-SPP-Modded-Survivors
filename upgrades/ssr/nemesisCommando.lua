-- Улучшения навыков Nemesis Commando (Starstorm Returns). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    nemesisCommandoZ  = { swingSize = 0.15, woundedDamage = 0.10,
                          text = { { "swingSize", "pct" }, { "woundedDamage", "pct" } } },
    nemesisCommandoX  = { damage = 0.10, pierceChance = 0.10,
                          text = { { "pierceChance", "pct" } } },
    nemesisCommandoX2 = { slashHeight = 0.20, slashDamage = 0.10,
                          text = { { "slashHeight", "pct" }, { "slashDamage", "pct" } } },
    nemesisCommandoC  = { invulnAfter = 0.2, invulnAfterMax = 1.0, bladeDamage = 0.10,
                          text = { { "invulnAfter", "sec", "invulnAfterMax" }, { "bladeDamage", "pct" } } },
    nemesisCommandoV  = { blastSize = 0.15, grenadeDamage = 0.10,
                          text = { { "blastSize", "pct" }, { "grenadeDamage", "pct" } } },
    nemesisCommandoV2 = { stock_every = 2, blastSize = 0.15,
                          text = { { "blastSize", "pct" } } },
}

local SKILLS = {
    nemesisCommandoZ  = { "nemesisCommandoZ" },
    nemesisCommandoX  = { "nemesisCommandoX" },
    nemesisCommandoX2 = { "nemesisCommandoX2" },
    nemesisCommandoC  = { "nemesisCommandoC" },
    nemesisCommandoV  = { "nemesisCommandoV", "nemesisCommandoVBoosted" },
    nemesisCommandoV2 = { "nemesisCommandoV2", "nemesisCommandoV2Boosted" },
}

local survivor = Survivor.find("nemesisCommando", "ssr")
if not survivor then
    SPPMS.NemesisCommando = "absent"
    return
end

local PRIMARY   = Util.find(ActorState, "nemCommandoPrimary", "ssr")
local SECONDARY = Util.find(ActorState, "nemCommandoSecondary", "ssr")
local UTILITY   = Util.find(ActorState, "nemCommandoUtility", "ssr")
local SLASH     = Util.find(Object, "NemmandoSlash", "ssr")
local WOUND     = Util.find(Buff, "commandoWound", "ror")

local SLASH_COEFF   = 0.9
local GRENADE_COEFF = 7
local CLUSTER_COEFF = 1.5
local ROCKET_BLAST  = 0.5

local APPLY_WOUND = 1

local SWING_SPARKS = Util.constant("sSparks9r")
local DRILL_SPARKS = Util.constant("sSparks1")
local SLASH_SPARKS = Util.constant("sBite3")
local SLASH_HIT_SOUND = Util.constant("wMercenaryShoot1_3")

local WOUND_STRIKE = 1 << AttackFlag.COMMANDO_WOUND_DAMAGE

local OP = gm.constants.oP

local S = Util.register("ssr", T, SKILLS)

local function scale_blast(args, mult)
    args[8].value = args[8].value * mult
    args[9].value = args[9].value * mult
end

local function blade_mult(actor)
    return 1 + T.nemesisCommandoC.bladeDamage * api.rank(actor, S.nemesisCommandoC)
end

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, PRIMARY) then return end
    if args[5].value ~= SWING_SPARKS then return end
    local rank = api.rank(actor, S.nemesisCommandoZ)
    if rank > 0 then scale_blast(args, 1 + T.nemesisCommandoZ.swingSize * rank) end
    args[4].value = args[4].value * blade_mult(actor)
end)

api.on_bullet(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, PRIMARY) then return end
    if args[7].value ~= DRILL_SPARKS then return end
    args[5].value = args[5].value * blade_mult(actor)
end)

DamageCalculate.add(function(calc)
    if math.floor(tonumber(calc.attack_flags) or 0) & WOUND_STRIKE ~= 0 then return end
    local parent = calc.parent
    if not Instance.exists(parent) or parent.object_index ~= OP or parent.class ~= survivor.value then return end
    local rank = api.rank(parent, S.nemesisCommandoZ)
    if rank < 1 then return end
    local hit = calc.hit
    if not Instance.exists(hit) or hit:buff_count(WOUND) < 1 then return end
    calc.damage_mult(1 + T.nemesisCommandoZ.woundedDamage * rank)
end)

api.on_bullet(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, SECONDARY) then return end
    if Util.bool(args[4].value) then return end
    local rank = api.rank(actor, S.nemesisCommandoX)
    if rank < 1 or math.random() >= T.nemesisCommandoX.pierceChance * rank then return end
    args[4].value = true
end)

Callback.add(SLASH.on_step, Callback.Priority.AFTER, function(inst)
    if not Instance.exists(inst) then return end
    local parent = inst.parent
    if not Instance.exists(parent) then return end
    local rank = api.rank(parent, S.nemesisCommandoX2)
    if rank < 1 then return end

    inst.image_yscale = inst.image_yscale * (1 + T.nemesisCommandoX2.slashHeight * rank)

    local hit_list = Instance.get_data(inst, nil, "ssr").hit_list
    for _, victim in ipairs(inst:get_collisions(gm.constants.pActorCollisionBase)) do
        if inst:attack_collision_canhit(victim) and not hit_list[victim.id] then
            if Net.host then
                local attack = parent:fire_direct(victim, SLASH_COEFF, inst.direction, inst.x, inst.y, SLASH_SPARKS).attack_info
                attack.__ssr_nemmando_wound = APPLY_WOUND
            end
            inst:sound_play(SLASH_HIT_SOUND, 0.5, 0.9)
            hit_list[victim.id] = true
        end
    end
end)

api.on_direct(function(actor, args)
    if actor.class ~= survivor.value or args[5].value ~= SLASH_COEFF then return end
    if args[6].value ~= SLASH_SPARKS then return end
    local rank = api.rank(actor, S.nemesisCommandoX2)
    if rank < 1 then return end
    args[5].value = args[5].value * (1 + T.nemesisCommandoX2.slashDamage * rank)
end)

Callback.add(UTILITY.on_exit, function(actor, data)
    local rank = api.rank(actor, S.nemesisCommandoC)
    if rank < 1 then return end
    Util.grant_invuln(actor, math.min(T.nemesisCommandoC.invulnAfter * rank, T.nemesisCommandoC.invulnAfterMax))
end)

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value then return end
    local coeff = args[4].value

    if coeff == GRENADE_COEFF or coeff == CLUSTER_COEFF then
        local rank = api.rank(actor, S.nemesisCommandoV)
        if rank < 1 then return end
        scale_blast(args, 1 + T.nemesisCommandoV.blastSize * rank)
        args[4].value = coeff * (1 + T.nemesisCommandoV.grenadeDamage * rank)
    elseif coeff == ROCKET_BLAST then
        local rank = api.rank(actor, S.nemesisCommandoV2)
        if rank < 1 then return end
        scale_blast(args, 1 + T.nemesisCommandoV2.blastSize * rank)
    end
end)

SPPMS.NemesisCommando = "ready"
