-- SPP: Modded Survivors: загрузчик. Модули грузятся по порядку из списка modules
-- после инициализации модов с выжившими; каждый выживший отмечает себя ready или absent.

mods["ReturnsAPI-ReturnsAPI"].auto{
    namespace = "SPPModdedSurvivors",
    mp        = true,
}

local PATH = _ENV["!plugins_mod_folder_path"].."\\"

local modules = {
    "core/util",
    "upgrades/ssr/executioner",
    "upgrades/ssr/mule",
    "upgrades/ssr/nemesisCommando",
    "upgrades/ssr/nemesisMercenary",
    "upgrades/hunter/hunter",
    "upgrades/fishmonger/fishmonger",
    "upgrades/ReclaimerSurvivor/Reclaimer",
    "upgrades/Revenant Mod/Revenant",
    "upgrades/zerimp/zerimp",
    "upgrades/ssr/technician",
    "upgrades/CaptainReturns/captain",
    "upgrades/rex/rex",
    "upgrades/GreenAlen22/Gigachad",
    "upgrades/Gin/Gin",
    "upgrades/Ghost/Ghost",
    "upgrades/Neorit/LoseHumanity",
    "upgrades/SniperStabMod/SniperStab",
    "upgrades/aphelion/aphelion",
    "upgrades/Worlds Collide/Admiral",
    "upgrades/Worlds Collide/helper",
    "upgrades/Worlds Collide/Bitwarrior",
    "upgrades/Worlds Collide/WorldsIncursion",
    "settings/debug",
}

local function load(name)
    local file = (PATH..name..".lua"):gsub("/", "\\")

    local f = io.open(file, "r")
    if not f then
        log.warning("SPPModdedSurvivors: file not found -> "..file)
        return false
    end
    f:close()

    local ok, err = pcall(function() require(file) end)
    if not ok then
        log.warning("SPPModdedSurvivors: FAILED to load "..name.." -> "..tostring(err))
        return false
    end
    return true
end

local expected = {
    "Util", "Executioner", "Mule", "NemesisCommando", "NemesisMercenary",
    "Hunter", "Fishmonger", "Reclaimer", "Revenant",
    "Zerimp", "Technician", "Captain", "Rex", "Gigachad",
    "Gin", "Ghost", "LoseHumanity",
    "SniperStab", "Aphelion", "Admiral", "Helper", "Bitwarrior", "WorldsIncursion", "Debug",
}

Initialize.add(Callback.Priority.AFTER, function()
    SPPMS = SPPMS or {}
    SPPMS.api = mods["GreenAlen22-SkillPlusPlus"].api

    local loaded = 0
    for _, name in ipairs(modules) do
        if load(name) then loaded = loaded + 1 end
    end

    local missing = {}
    for _, key in ipairs(expected) do
        if SPPMS[key] == nil then missing[#missing + 1] = key end
    end

    SPPMS.Boot = {
        loaded   = loaded,
        total    = #modules,
        missing  = #missing > 0 and table.concat(missing, ", ") or "-",
        expected = expected,
    }

    if loaded == #modules and #missing == 0 then
        log.info("SPPModdedSurvivors: initialized ("..loaded.."/"..#modules.." modules)")
    else
        log.warning("SPPModdedSurvivors: initialized PARTIALLY ("..loaded.."/"..#modules
            .." modules; missing SPPMS: "..SPPMS.Boot.missing..")")
    end
end)
