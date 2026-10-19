-- Улучшения навыков Unload, Stealth Hunting и Spotter: BLAST (мод Aphelion). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    aphelionBanditX   = { damage = 0.10, stock_every = 2, stunChance = 0.10,
                          text = { { "stunChance", "pct" } } },
    aphelionHuntressV = { stealthSeconds = 0.5, stealthDamage = 0.05,
                          text = { { "stealthSeconds", "sec" }, { "stealthDamage", "pct" } } },
    aphelionSniperV   = { blastSize = 0.15, blastDamage = 0.10,
                          text = { { "blastSize", "pct" }, { "blastDamage", "pct" } } },
}

local SKILLS = {
    aphelionBanditX   = { "banditUnload" },
    aphelionHuntressV = { "huntressStealth", "huntressStealthBoosted" },
    aphelionSniperV   = { "sniperBlast", "sniperBlastBoosted" },
}

local NS = "aphelion"

local function present(key)
    for _, id in ipairs(SKILLS[key]) do
        if not Skill.find(id, NS) then
            SKILLS[key] = nil
            return false
        end
    end
    return true
end

local has_unload  = present("aphelionBanditX")
local has_stealth = present("aphelionHuntressV")
local has_blast   = present("aphelionSniperV")
if not (has_unload or has_stealth or has_blast) then
    SPPMS.Aphelion = "absent"
    return
end

local UNLOAD          = has_unload and Util.find(ActorState, "banditUnload", NS)
local SPARKS_UNLOAD   = has_unload and Util.constant("sSparks15")
local STEALTH         = has_stealth and Util.find(Buff, "huntressStealth", NS)
local STEALTH_BOOSTED = has_stealth and Util.find(Buff, "huntressStealthBoosted", NS)
local BLAST_SPRITE    = has_blast and Util.find(Sprite, "explosive_192", NS)
local DETONATE_SPRITE = has_blast and Util.find(Sprite, "explosive_256", NS)

local S = Util.register(NS, T, SKILLS)

local FPS = 60

if has_unload then
    local UNLOAD_RANGE = 1400
    local UNLOAD_STUN  = 0.8 / 1.5

    api.after_bullet(function(actor, attack, args, vanilla)
        if not Util.in_state(actor, UNLOAD) then return end
        if vanilla[6] ~= UNLOAD_RANGE or vanilla[7] ~= SPARKS_UNLOAD then return end
        if not Util.bool(actor.local_client_is_authority) then return end
        local rank = api.rank(actor, S.aphelionBanditX)
        if rank < 1 or math.random() >= T.aphelionBanditX.stunChance * rank then return end
        attack.stun = math.max(tonumber(attack.stun) or 0, UNLOAD_STUN)
    end)
end

if has_stealth then
    local function longer_stealth(buff)
        Callback.add(buff.on_apply, function(actor)
            if not Net.host then return end
            Instance.get_data(actor, nil, Util.NS).sppms_stealth = true
        end)
        Callback.add(buff.on_step, function(actor)
            if not Net.host then return end
            local own = Instance.get_data(actor, nil, Util.NS)
            if not own.sppms_stealth then return end
            own.sppms_stealth = nil
            local rank = api.rank(actor, S.aphelionHuntressV)
            if rank < 1 then return end
            local extra = math.floor(T.aphelionHuntressV.stealthSeconds * FPS * rank)
            actor:buff_set_time(buff, actor:buff_get_time(buff) + extra)
        end)
end

longer_stealth(STEALTH)
longer_stealth(STEALTH_BOOSTED)

RecalculateStats.add(function(actor, stats)
    if actor:buff_count(STEALTH) == 0 and actor:buff_count(STEALTH_BOOSTED) == 0 then return end
    local rank = api.rank(actor, S.aphelionHuntressV)
    if rank > 0 then stats.damage_mult(1 + T.aphelionHuntressV.stealthDamage * rank) end
end)

end

if has_blast then
    local NO_PROC_MODE = 2
    local BLAST_SPRITES = { [BLAST_SPRITE.value] = true, [DETONATE_SPRITE.value] = true }

    api.on_explosion(function(actor, args)
        if args[1].value ~= NO_PROC_MODE or not BLAST_SPRITES[args[7].value] then return end
        local rank = api.rank(actor, S.aphelionSniperV)
        if rank < 1 then return end
        local scale = 1 + T.aphelionSniperV.blastSize * rank
        args[8].value = args[8].value * scale
        args[9].value = args[9].value * scale
        args[4].value = args[4].value * (1 + T.aphelionSniperV.blastDamage * rank)
    end)
end

SPPMS.Aphelion = "ready"
