--[[
    Gladius Midnight - Data
    Static data for classes, racials, and trinkets
]]

local addonName, addon = ...
addon.Data = {}

-- ============================================================================
-- Class Colors (WoW Standard)
-- ============================================================================

addon.Data.ClassColors = {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    ROGUE = { r = 1.0, g = 0.96, b = 0.41 },
    PRIEST = { r = 1.0, g = 1.0, b = 1.0 },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    SHAMAN = { r = 0.0, g = 0.44, b = 0.87 },
    MAGE = { r = 0.41, g = 0.8, b = 0.94 },
    WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
    MONK = { r = 0.0, g = 1.0, b = 0.59 },
    DRUID = { r = 1.0, g = 0.49, b = 0.04 },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
    EVOKER = { r = 0.2, g = 0.58, b = 0.5 },
}

-- ============================================================================
-- Class Icon Texture Coordinates
-- ============================================================================

addon.Data.ClassIconCoords = {
    WARRIOR = { 0, 0.25, 0, 0.25 },
    MAGE = { 0.25, 0.5, 0, 0.25 },
    ROGUE = { 0.5, 0.75, 0, 0.25 },
    DRUID = { 0.75, 1, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 },
    SHAMAN = { 0.25, 0.5, 0.25, 0.5 },
    PRIEST = { 0.5, 0.75, 0.25, 0.5 },
    WARLOCK = { 0.75, 1, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
    DEATHKNIGHT = { 0.25, 0.5, 0.5, 0.75 },
    MONK = { 0.5, 0.75, 0.5, 0.75 },
    DEMONHUNTER = { 0.75, 1, 0.5, 0.75 },
    EVOKER = { 0, 0.25, 0.75, 1 },
}

-- ============================================================================
-- Power Colors
-- ============================================================================

addon.Data.PowerColors = {
    [Enum.PowerType.Mana] = { r = 0.0, g = 0.0, b = 1.0 },
    [Enum.PowerType.Rage] = { r = 1.0, g = 0.0, b = 0.0 },
    [Enum.PowerType.Focus] = { r = 1.0, g = 0.5, b = 0.25 },
    [Enum.PowerType.Energy] = { r = 1.0, g = 1.0, b = 0.0 },
    [Enum.PowerType.RunicPower] = { r = 0.0, g = 0.82, b = 1.0 },
    [Enum.PowerType.Fury] = { r = 0.788, g = 0.259, b = 0.992 },
    [Enum.PowerType.Maelstrom] = { r = 0.0, g = 0.5, b = 1.0 },
    [Enum.PowerType.Insanity] = { r = 0.4, g = 0, b = 0.8 },
}

-- ============================================================================
-- Racial Cooldowns (SpellID -> Cooldown in seconds)
-- ============================================================================

addon.Data.RacialCooldowns = {
    -- Alliance
    [59752] = 180,   -- Will to Survive (Human)
    [20594] = 120,   -- Stoneform (Dwarf)
    [58984] = 120,   -- Shadowmeld (Night Elf)
    [20589] = 60,    -- Escape Artist (Gnome)
    [28880] = 180,   -- Gift of the Naaru (Draenei)
    [68992] = 120,   -- Darkflight (Worgen)
    [256948] = 180,  -- Spatial Rift (Void Elf)
    [255647] = 150,  -- Light's Judgment (Lightforged)
    [265221] = 120,  -- Fireblood (Dark Iron)
    [287712] = 150,  -- Haymaker (Kul Tiran)
    [312924] = 150,  -- Emergency Failsafe (Mechagnome)
    [259930] = 180,  -- Hyper Organic Light Originator (Mechagnome)

    -- Horde
    [33697] = 120,   -- Blood Fury (Orc)
    [20572] = 120,   -- Blood Fury (Orc melee)
    [33702] = 120,   -- Blood Fury (Orc spell)
    [7744] = 180,    -- Will of the Forsaken (Undead)
    [20549] = 90,    -- War Stomp (Tauren)
    [26297] = 180,   -- Berserking (Troll)
    [28730] = 120,   -- Arcane Torrent (Blood Elf)
    [69070] = 90,    -- Rocket Jump (Goblin)
    [107079] = 120,  -- Quaking Palm (Pandaren)
    [260364] = 180,  -- Arcane Pulse (Nightborne)
    [255654] = 120,  -- Bull Rush (Highmountain)
    [274738] = 120,  -- Ancestral Call (Mag'har)
    [291944] = 150,  -- Regeneratin' (Zandalari)
    [312411] = 90,   -- Bag of Tricks (Vulpera)
    [368970] = 90,   -- Tail Swipe (Dracthyr)
    [357214] = 90,   -- Wing Buffet (Dracthyr)
    [358733] = 90,   -- Glide (Dracthyr)

    -- Earthen (TWW)
    [436343] = 120,  -- Azerite Surge
}

-- Racials that share CD with PvP trinket
addon.Data.TrinketShareRacials = {
    [59752] = true,  -- Will to Survive (Human)
    [7744] = true,   -- Will of the Forsaken (Undead)
}

-- Race to Primary Racial SpellID (for displaying icon)
-- Key is the race token returned by UnitRace (second return value)
addon.Data.RaceToRacialSpell = {
    -- Alliance
    ["Human"] = 59752,           -- Will to Survive
    ["Dwarf"] = 20594,           -- Stoneform
    ["NightElf"] = 58984,        -- Shadowmeld
    ["Gnome"] = 20589,           -- Escape Artist
    ["Draenei"] = 28880,         -- Gift of the Naaru
    ["Worgen"] = 68992,          -- Darkflight
    ["VoidElf"] = 256948,        -- Spatial Rift
    ["LightforgedDraenei"] = 255647, -- Light's Judgment
    ["DarkIronDwarf"] = 265221,  -- Fireblood
    ["KulTiran"] = 287712,       -- Haymaker
    ["Mechagnome"] = 312924,     -- Emergency Failsafe

    -- Horde
    ["Orc"] = 33697,             -- Blood Fury
    ["Scourge"] = 7744,          -- Will of the Forsaken (Undead)
    ["Tauren"] = 20549,          -- War Stomp
    ["Troll"] = 26297,           -- Berserking
    ["BloodElf"] = 28730,        -- Arcane Torrent
    ["Goblin"] = 69070,          -- Rocket Jump
    ["Nightborne"] = 260364,     -- Arcane Pulse
    ["HighmountainTauren"] = 255654, -- Bull Rush
    ["MagharOrc"] = 274738,      -- Ancestral Call
    ["ZandalariTroll"] = 291944, -- Regeneratin'
    ["Vulpera"] = 312411,        -- Bag of Tricks

    -- Neutral
    ["Pandaren"] = 107079,       -- Quaking Palm
    ["Dracthyr"] = 368970,       -- Tail Swipe

    -- TWW
    ["Earthen"] = 436343,        -- Azerite Surge
}

-- ============================================================================
-- PvP Trinket Data
-- ============================================================================

addon.Data.TrinketCooldown = 120  -- 2 minutes
addon.Data.TrinketSpellID = 336126  -- Gladiator's Medallion

-- Default trinket icon
addon.Data.TrinketIcon = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01"

-- ============================================================================
-- Helper Functions
-- ============================================================================

function addon.Data.GetSpellIcon(spellID)
    if not spellID then return nil end

    -- 12.0 API (primary)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.iconID then
            return info.iconID
        end
    end

    -- 12.0 alternative: C_Spell.GetSpellTexture
    if C_Spell and C_Spell.GetSpellTexture then
        local texture = C_Spell.GetSpellTexture(spellID)
        if texture then return texture end
    end

    -- Legacy fallback (pre-12.0)
    if GetSpellInfo then
        local _, _, icon = GetSpellInfo(spellID)
        if icon then return icon end
    end

    return nil
end

function addon.Data.GetClassColor(class)
    return addon.Data.ClassColors[class] or { r = 0.5, g = 0.5, b = 0.5 }
end

function addon.Data.GetPowerColor(powerType)
    return addon.Data.PowerColors[powerType] or addon.Data.PowerColors[Enum.PowerType.Mana]
end
