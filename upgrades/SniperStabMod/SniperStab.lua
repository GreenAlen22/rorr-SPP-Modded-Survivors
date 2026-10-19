-- Улучшения навыков Stab (мод Sniper Stab Legacy). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    sniperStabZ = { damage = 0.10, shotRange = 0.20, bleedChance = 0.10,
                    text = { { "shotRange", "pct" }, { "bleedChance", "pct" } } },
}

local SKILLS = {
    sniperStabZ = { "sniperStabSS1" },
}

local NS = "SniperStabMod"

if not Skill.find("sniperStabSS1", NS) then
    SPPMS.SniperStab = "absent"
    return
end

local STAB = Util.find(ActorState, "sniperStabSS1", NS)

local S = Util.register(NS, T, SKILLS)

local STAB_RANGE = 25

api.on_bullet(function(actor, args)
    if not Util.in_state(actor, STAB) or args[6].value ~= STAB_RANGE then return end
    local rank = api.rank(actor, S.sniperStabZ)
    if rank < 1 then return end
    args[6].value = args[6].value * (1 + T.sniperStabZ.shotRange * rank)
end)

local BLEED_SHARE, BLEED_TICKS, BLEED_RATE = 0.35, 4, 30
local STAB_TAG = 1

Callback.add(Callback.ON_ATTACK_HIT, function(hit_info)
    if not Net.host or hit_info.attack_info.stabHitSS1 ~= STAB_TAG then return end
    local actor = hit_info.inflictor
    if not Instance.exists(actor) then return end
    local rank = api.rank(actor, S.sniperStabZ)
    if rank < 1 or math.random() >= T.sniperStabZ.bleedChance * rank then return end
    local victim = hit_info.target
    if not Instance.exists(victim) then return end
    victim:apply_dot(BLEED_SHARE, BLEED_TICKS, BLEED_RATE, hit_info, Color.RED, false)
end)

SPPMS.SniperStab = "ready"
