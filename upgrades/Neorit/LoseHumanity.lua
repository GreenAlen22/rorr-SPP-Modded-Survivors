-- Улучшения навыков одиннадцати монстров (мод Lose Humanity). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    macrobicPredatorZ = { attackDamage = 0.10, swingSize = 0.15,
                          text = { { "attackDamage", "pct" }, { "swingSize", "pct" } } },
    macrobicPredatorX = false,
    macrobicPredatorC = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0,
                          text = { { "invulnAfter", "sec", "invulnAfterMax" } } },
    macrobicPredatorV = false,

    lemurianZ = { attackDamage = 0.10, swingSize = 0.15,
                  text = { { "attackDamage", "pct" }, { "swingSize", "pct" } } },
    lemurianX = false,
    lemurianC = false,
    lemurianV = false,

    golemZ = { attackDamage = 0.10, swingSize = 0.15,
               text = { { "attackDamage", "pct" }, { "swingSize", "pct" } } },
    golemX = false,
    golemC = false,
    golemV = false,

    parentZ = { attackDamage = 0.10, swingSize = 0.15,
                text = { { "attackDamage", "pct" }, { "swingSize", "pct" } } },
    parentX = false,
    parentC = false,
    parentV = false,

    wispZ = { shotDamage = 0.10, shotRange = 0.20,
              text = { { "shotDamage", "pct" }, { "shotRange", "pct" } } },
    wispX = false,
    wispC = false,
    wispV = false,

    greaterWispZ = { shotDamage = 0.10, shotRange = 0.20,
                     text = { { "shotDamage", "pct" }, { "shotRange", "pct" } } },
    greaterWispX = false,
    greaterWispC = false,
    greaterWispV = false,

    archaicWispZ = { shotDamage = 0.10, shotRange = 0.20,
                     text = { { "shotDamage", "pct" }, { "shotRange", "pct" } } },
    archaicWispX = false,
    archaicWispC = false,
    archaicWispV = false,

    scavengerZ = { shotDamage = 0.10, pierceChance = 0.10,
                   text = { { "shotDamage", "pct" }, { "pierceChance", "pct" } } },
    scavengerX = { attackDamage = 0.10, blastSize = 0.15,
                   text = { { "attackDamage", "pct" }, { "blastSize", "pct" } } },
    scavengerC = { cooldown = 0.92, stock_every = 2 },
    scavengerV = false,

    elderLemurianZ = { attackDamage = 0.10, swingSize = 0.15,
                       text = { { "attackDamage", "pct" }, { "swingSize", "pct" } } },
    elderLemurianX = false,
    elderLemurianC = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0,
                       text = { { "invulnAfter", "sec", "invulnAfterMax" } } },
    elderLemurianV = false,

    tardigradeZ = { attackDamage = 0.10, swingSize = 0.15,
                    text = { { "attackDamage", "pct" }, { "swingSize", "pct" } } },
    tardigradeX = false,
    tardigradeC = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0,
                    text = { { "invulnAfter", "sec", "invulnAfterMax" } } },
    tardigradeV = false,

    nautilusZ = { shotDamage = 0.10, shotRange = 0.20,
                  text = { { "shotDamage", "pct" }, { "shotRange", "pct" } } },
    nautilusX = false,
    nautilusC = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0,
                  text = { { "invulnAfter", "sec", "invulnAfterMax" } } },
    nautilusV = false,
}

local SKILLS = {
    macrobicPredatorZ = { "MacrobicPredatorZ" },
    macrobicPredatorX = { "MacrobicPredatorX" },
    macrobicPredatorC = { "MacrobicPredatorC" },
    macrobicPredatorV = { "MacrobicPredatorV" },
    lemurianZ         = { "LemurianZ" },
    lemurianX         = { "LemurianX" },
    lemurianC         = { "LemurianC" },
    lemurianV         = { "LemurianV" },
    golemZ            = { "GolemZ" },
    golemX            = { "GolemX" },
    golemC            = { "GolemC" },
    golemV            = { "GolemV" },
    parentZ           = { "ParentZ" },
    parentX           = { "ParentX" },
    parentC           = { "ParentC" },
    parentV           = { "ParentV" },
    wispZ             = { "WispZ" },
    wispX             = { "WispX" },
    wispC             = { "WispC" },
    wispV             = { "WispV" },
    greaterWispZ      = { "GreaterWispZ" },
    greaterWispX      = { "GreaterWispX" },
    greaterWispC      = { "GreaterWispC" },
    greaterWispV      = { "GreaterWispV" },
    archaicWispZ      = { "ArchaicWispZ" },
    archaicWispX      = { "ArchaicWispX" },
    archaicWispC      = { "ArchaicWispC" },
    archaicWispV      = { "ArchaicWispV" },
    scavengerZ        = { "ScavengerZ" },
    scavengerX        = { "ScavengerX" },
    scavengerC        = { "ScavengerC" },
    scavengerV        = { "ScavengerV" },
    elderLemurianZ    = { "ElderLemurianZ" },
    elderLemurianX    = { "ElderLemurianX" },
    elderLemurianC    = { "ElderLemurianC" },
    elderLemurianV    = { "ElderLemurianV" },
    tardigradeZ       = { "TardigradeZ" },
    tardigradeX       = { "TardigradeX" },
    tardigradeC       = { "TardigradeC" },
    tardigradeV       = { "TardigradeV" },
    nautilusZ         = { "NautilusZ" },
    nautilusX         = { "NautilusX" },
    nautilusC         = { "NautilusC" },
    nautilusV         = { "NautilusV" },
}

local MONSTERS = {
    { "MacrobicPredator", "Neorit",        blast  = { "macrobicPredatorZ", "sSparks14" },
                                           dash   = "macrobicPredatorC" },
    { "Lemurian",         "SmoothSpatula", blast  = { "lemurianZ", "sBite4" } },
    { "Golem",            "SmoothSpatula", blast  = { "golemZ", "sBite1" } },
    { "Parent",           "SmoothSpatula", blast  = { "parentZ", "sBite1" } },
    { "Wisp",             "SmoothSpatula", bullet = { "wispZ", "sWispSpark", 168 } },
    { "GreaterWisp",      "SmoothSpatula", bullet = { "greaterWispZ", "sWispGSpark", 400 } },
    { "ArchaicWisp",      "SmoothSpatula", bullet = { "archaicWispZ", "sWispG2Spark", 400 } },
    { "Scavenger",        "Neorit",        bullet = { "scavengerZ", "sSparks2", 1400 },
                                           blast  = { "scavengerX", "sWispSpark" } },
    { "ElderLemurian",    "Neorit",        blast  = { "elderLemurianZ", "sBite1" },
                                           dash   = "elderLemurianC" },
    { "Tardigrade",       "Neorit",        blast  = { "tardigradeZ", "sBite5" },
                                           dash   = "tardigradeC" },
    { "Nautilus",         "Neorit",        bullet = { "nautilusZ", -1, 180 },
                                           dash   = "nautilusC" },
}

local SLOTS = { "Z", "X", "C", "V" }

local function sprite(name)
    if type(name) == "string" then return Util.constant(name) end
    return name
end

Util.late("LoseHumanity", function()
    local own = false
    for _, monster in ipairs(MONSTERS) do
        if monster[2] == "Neorit" and Survivor.find(monster[1], "Neorit") then own = true end
    end
    if not own then return false end

    local by_namespace = {}
    local found = {}
    for _, monster in ipairs(MONSTERS) do
        local identifier, namespace = monster[1], monster[2]
        local survivor = Survivor.find(identifier, namespace)
        if survivor then
            local prefix = identifier:sub(1, 1):lower()..identifier:sub(2)
            local skills = by_namespace[namespace] or {}
            by_namespace[namespace] = skills
            for _, slot in ipairs(SLOTS) do
                skills[prefix..slot] = SKILLS[prefix..slot]
            end
            found[#found + 1] = { survivor, monster }
        end
    end
    if #found == 0 then return false end

    local MERC_DASH = Util.find(ActorState, "mercenaryC", "ror")

    local blasts, bullets, dashes = {}, {}, {}
    for _, entry in ipairs(found) do
        local class, monster = entry[1].value, entry[2]
        if monster.blast then
            blasts[class] = { key = monster.blast[1], sparks = sprite(monster.blast[2]) }
        end
        if monster.bullet then
            bullets[class] = { key = monster.bullet[1], sparks = sprite(monster.bullet[2]),
                               range = monster.bullet[3] }
        end
        if monster.dash then dashes[class] = monster.dash end
    end

    for namespace, skills in pairs(by_namespace) do
        for _, ids in pairs(skills) do
            for _, id in ipairs(ids) do Util.find(Skill, id, namespace) end
        end
    end

    local S = {}
    for namespace, skills in pairs(by_namespace) do
        for key, list in pairs(Util.register(namespace, T, skills)) do S[key] = list end
    end

    local NO_SPRITE = -1

    local function blast_of(actor, args)
        local blast = blasts[actor.class]
        if blast and args[5].value == blast.sparks and args[7].value == NO_SPRITE then return blast end
        return nil
    end

    api.on_explosion(function(actor, args)
        local blast = blast_of(actor, args)
        if not blast then return end
        local rank = api.rank(actor, S[blast.key])
        if rank < 1 then return end
        local def = T[blast.key]
        local scale = 1 + (def.swingSize or def.blastSize) * rank
        args[8].value = args[8].value * scale
        args[9].value = args[9].value * scale
    end)

    api.after_explosion(function(actor, attack, args, vanilla)
        local blast = blast_of(actor, args)
        if not blast then return end
        local rank = api.rank(actor, S[blast.key])
        if rank < 1 then return end
        attack.damage = attack.damage * (1 + T[blast.key].attackDamage * rank)
    end)

    api.on_bullet(function(actor, args)
        local bullet = bullets[actor.class]
        if not bullet or args[7].value ~= bullet.sparks or args[6].value ~= bullet.range then return end
        local rank = api.rank(actor, S[bullet.key])
        if rank < 1 then return end
        local def = T[bullet.key]
        args[5].value = args[5].value * (1 + def.shotDamage * rank)
        if def.shotRange then
            args[6].value = args[6].value * (1 + def.shotRange * rank)
        end
        if def.pierceChance and not Util.bool(args[4].value)
            and math.random() < def.pierceChance * rank then
            args[4].value = true
        end
    end)

    Callback.add(MERC_DASH.on_exit, function(actor, data)
        local key = dashes[actor.class]
        if not key then return end
        local rank = api.rank(actor, S[key])
        if rank < 1 then return end
        Util.grant_invuln(actor, math.min(T[key].invulnAfter * rank, T[key].invulnAfterMax))
    end)

    return true
end)
