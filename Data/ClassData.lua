--[[=========================================================================
    Gladius Midnight - Class Data
    Static data for class colors, icon coordinates, and power type colors
===========================================================================]]

local _, Gladius = ...

-- Class color definitions (r, g, b)
Gladius.CLASS_COLORS = {
    ["WARRIOR"]     = { r = 0.78, g = 0.61, b = 0.43 },
    ["PALADIN"]     = { r = 0.96, g = 0.55, b = 0.73 },
    ["HUNTER"]      = { r = 0.67, g = 0.83, b = 0.45 },
    ["ROGUE"]       = { r = 1.00, g = 0.96, b = 0.41 },
    ["PRIEST"]      = { r = 1.00, g = 1.00, b = 1.00 },
    ["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23 },
    ["SHAMAN"]      = { r = 0.00, g = 0.44, b = 0.87 },
    ["MAGE"]        = { r = 0.25, g = 0.78, b = 0.92 },
    ["WARLOCK"]     = { r = 0.53, g = 0.53, b = 0.93 },
    ["MONK"]        = { r = 0.00, g = 1.00, b = 0.60 },
    ["DRUID"]       = { r = 1.00, g = 0.49, b = 0.04 },
    ["DEMONHUNTER"] = { r = 0.64, g = 0.19, b = 0.79 },
    ["EVOKER"]      = { r = 0.20, g = 0.58, b = 0.50 },
}

-- Class icon texture coordinates in the default class icon atlas
-- Format: {left, right, top, bottom}
Gladius.CLASS_ICON_COORDS = {
    ["WARRIOR"]     = { 0.00, 0.25, 0.00, 0.25 },
    ["MAGE"]        = { 0.25, 0.50, 0.00, 0.25 },
    ["ROGUE"]       = { 0.50, 0.75, 0.00, 0.25 },
    ["DRUID"]       = { 0.75, 1.00, 0.00, 0.25 },
    ["HUNTER"]      = { 0.00, 0.25, 0.25, 0.50 },
    ["SHAMAN"]      = { 0.25, 0.50, 0.25, 0.50 },
    ["PRIEST"]      = { 0.50, 0.75, 0.25, 0.50 },
    ["WARLOCK"]     = { 0.75, 1.00, 0.25, 0.50 },
    ["PALADIN"]     = { 0.00, 0.25, 0.50, 0.75 },
    ["DEATHKNIGHT"] = { 0.25, 0.50, 0.50, 0.75 },
    ["MONK"]        = { 0.50, 0.75, 0.50, 0.75 },
    ["DEMONHUNTER"] = { 0.75, 1.00, 0.50, 0.75 },
    ["EVOKER"]      = { 0.00, 0.25, 0.75, 1.00 },
}

-- Power type color definitions
Gladius.POWER_COLORS = {
    [Enum.PowerType.Mana]        = { r = 0.00, g = 0.50, b = 1.00 },
    [Enum.PowerType.Rage]        = { r = 1.00, g = 0.00, b = 0.00 },
    [Enum.PowerType.Focus]       = { r = 1.00, g = 0.50, b = 0.25 },
    [Enum.PowerType.Energy]      = { r = 1.00, g = 1.00, b = 0.00 },
    [Enum.PowerType.RunicPower]  = { r = 0.00, g = 0.82, b = 1.00 },
    [Enum.PowerType.Insanity]    = { r = 0.40, g = 0.00, b = 0.80 },
    [Enum.PowerType.Fury]        = { r = 0.79, g = 0.26, b = 0.99 },
    [Enum.PowerType.Maelstrom]   = { r = 0.00, g = 0.50, b = 1.00 },
    [Enum.PowerType.LunarPower]  = { r = 0.30, g = 0.52, b = 0.90 },
    [Enum.PowerType.Essence]     = { r = 0.49, g = 0.64, b = 0.36 },
}

-- Trinket constants
Gladius.TRINKET_SPELL_ID = 336126
Gladius.TRINKET_ADAPTATION_ID = 336139
Gladius.TRINKET_COOLDOWN = 120

-- Faction-specific trinket icon textures
Gladius.TRINKET_ICON_ALLIANCE = 133452
Gladius.TRINKET_ICON_HORDE = 133453

-- Magic-only immunities (not affected by physical damage)
Gladius.MAGIC_IMMUNITIES = {
    [1022]   = true,   -- Blessing of Protection
    [204018] = true,   -- Blessing of Spellwarding
    [31224]  = true,   -- Cloak of Shadows
    [48707]  = true,   -- Anti-Magic Shell
    [410358] = true,   -- Anti-Magic Shell (variant)
    [212295] = true,   -- Nether Ward
    [23920]  = true,   -- Spell Reflection
}

-- Total immunities (immune to everything)
Gladius.TOTAL_IMMUNITIES = {
    [642]    = true,   -- Divine Shield
    [186265] = true,   -- Aspect of the Turtle
    [45438]  = true,   -- Ice Block
    [196555] = true,   -- Netherwalk
    [378441] = true,   -- Time Stop
}

-- Helper to get spell info safely for Midnight
function Gladius.GetSpellInfo(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
        end
    end
    return nil
end

function Gladius.GetSpellTexture(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID)
    end
    return nil
end
