-- Улучшения навыков Nemesis Mercenary (Starstorm Returns). Числа - в таблице T.

SPPMS = SPPMS or {}

local Util = SPPMS.Util
local api  = SPPMS.api

local T = {
    nemesisMercenaryZ = { damage = 0.10, swingSize = 0.15,
                          text = { { "swingSize", "pct" } } },
    nemesisMercenaryX = { damage = 0.10, shotRange = 0.20,
                          text = { { "shotRange", "pct" } } },
    nemesisMercenaryC = { stock_every = 2, invulnAfter = 0.2, invulnAfterMax = 1.0,
                          text = { { "invulnAfter", "sec", "invulnAfterMax" } } },
    nemesisMercenaryV = { damage = 0.10, doubleStrikeChance = 0.10,
                          text = { { "doubleStrikeChance", "pct" } } },
}

local SKILLS = {
    nemesisMercenaryZ = { "nemesisMercenaryZ" },
    nemesisMercenaryX = { "nemesisMercenaryX" },
    nemesisMercenaryC = { "nemesisMercenaryC" },
    nemesisMercenaryV = { "nemesisMercenaryV", "nemesisMercenaryVBoosted" },
}

local survivor = Survivor.find("nemesisMercenary", "ssr")
if not survivor then
    SPPMS.NemesisMercenary = "absent"
    return
end

local COMBO = {}
for _, letter in ipairs({ "A", "B", "C", "D", "E" }) do
    COMBO[#COMBO + 1] = Util.find(ActorState, "nemMercenaryAttachmentStab"..letter, "ssr")
end
local SECONDARY = Util.find(ActorState, "nemMercenaryQuickTrigger", "ssr")
local UTILITY   = Util.find(ActorState, "nemMercenaryBlindingSlide", "ssr")
local SPECIAL   = Util.find(ActorState, "nemMercenaryDevitalize", "ssr")

local NO_SPARKS = Util.constant("sNone")

local S = Util.register("ssr", T, SKILLS)

local function in_combo(actor)
    for _, state in ipairs(COMBO) do
        if Util.in_state(actor, state) then return true end
    end
    return false
end

local DEVITALIZE_COLOR = 5350773

api.on_explosion(function(actor, args)
    if actor.class ~= survivor.value or not in_combo(actor) then return end
    local rank = api.rank(actor, S.nemesisMercenaryZ)
    if rank < 1 then return end
    local scale = 1 + T.nemesisMercenaryZ.swingSize * rank
    args[8].value = args[8].value * scale
    args[9].value = args[9].value * scale
end)

api.on_bullet(function(actor, args)
    if actor.class ~= survivor.value or not Util.in_state(actor, SECONDARY) then return end
    local rank = api.rank(actor, S.nemesisMercenaryX)
    if rank < 1 then return end
    args[6].value = args[6].value * (1 + T.nemesisMercenaryX.shotRange * rank)
end)

Callback.add(UTILITY.on_exit, function(actor, data)
    local rank = api.rank(actor, S.nemesisMercenaryC)
    if rank < 1 then return end
    Util.grant_invuln(actor, math.min(T.nemesisMercenaryC.invulnAfter * rank, T.nemesisMercenaryC.invulnAfterMax))
end)

local firing_copy = false

api.after_direct(function(actor, attack, args, vanilla)
    if firing_copy or actor.class ~= survivor.value or not Util.in_state(actor, SPECIAL) then return end
    local rank = api.rank(actor, S.nemesisMercenaryV)
    if rank < 1 or math.random() >= T.nemesisMercenaryV.doubleStrikeChance * rank then return end

    firing_copy = true
    local ok, copy = pcall(GM.SO.fire_direct, actor, actor, table.unpack(vanilla, 1, vanilla.n))
    firing_copy = false
    if not ok then error(copy, 0) end
    copy.damage_color = DEVITALIZE_COLOR
end)

SPPMS.NemesisMercenary = "ready"
