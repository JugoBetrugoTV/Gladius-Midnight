-- Gladius Midnight - Class Resource Data
-- Compatible with WoW Midnight 12.0

local _, GladiusMidnight = ...
GladiusMidnight.ClassResources = GladiusMidnight.ClassResources or {}

-- Power types per class (Enum.PowerType values)
-- Note: In 12.0, secondary resources like ComboPoints, HolyPower, etc. are NOT secrets
GladiusMidnight.ClassResources.PowerTypes = {
    ["WARRIOR"] = Enum.PowerType.Rage,
    ["PALADIN"] = Enum.PowerType.Mana, -- Holy Power is secondary
    ["HUNTER"] = Enum.PowerType.Focus,
    ["ROGUE"] = Enum.PowerType.Energy, -- Combo Points secondary
    ["PRIEST"] = Enum.PowerType.Mana, -- Insanity for Shadow
    ["DEATHKNIGHT"] = Enum.PowerType.RunicPower, -- Runes secondary
    ["SHAMAN"] = Enum.PowerType.Mana, -- Maelstrom for Elemental/Enhancement
    ["MAGE"] = Enum.PowerType.Mana, -- Arcane Charges secondary
    ["WARLOCK"] = Enum.PowerType.Mana, -- Soul Shards secondary
    ["MONK"] = Enum.PowerType.Energy, -- Chi secondary
    ["DRUID"] = Enum.PowerType.Mana, -- Varies by form
    ["DEMONHUNTER"] = Enum.PowerType.Fury,
    ["EVOKER"] = Enum.PowerType.Mana, -- Essence secondary
}

-- Power bar colors per class/power type
GladiusMidnight.ClassResources.PowerColors = {
    [Enum.PowerType.Mana] = { r = 0.0, g = 0.0, b = 1.0 },
    [Enum.PowerType.Rage] = { r = 1.0, g = 0.0, b = 0.0 },
    [Enum.PowerType.Focus] = { r = 1.0, g = 0.5, b = 0.25 },
    [Enum.PowerType.Energy] = { r = 1.0, g = 1.0, b = 0.0 },
    [Enum.PowerType.RunicPower] = { r = 0.0, g = 0.82, b = 1.0 },
    [Enum.PowerType.Fury] = { r = 0.788, g = 0.259, b = 0.992 },
    [Enum.PowerType.Insanity] = { r = 0.4, g = 0.0, b = 0.8 },
    [Enum.PowerType.Maelstrom] = { r = 0.0, g = 0.5, b = 1.0 },
    [Enum.PowerType.LunarPower] = { r = 0.3, g = 0.52, b = 0.9 },
}

-- Class colors (backup in case RAID_CLASS_COLORS is unavailable)
GladiusMidnight.ClassResources.ClassColors = {
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45 },
    ["ROGUE"] = { r = 1.0, g = 0.96, b = 0.41 },
    ["PRIEST"] = { r = 1.0, g = 1.0, b = 1.0 },
    ["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23 },
    ["SHAMAN"] = { r = 0.0, g = 0.44, b = 0.87 },
    ["MAGE"] = { r = 0.41, g = 0.8, b = 0.94 },
    ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["MONK"] = { r = 0.0, g = 1.0, b = 0.59 },
    ["DRUID"] = { r = 1.0, g = 0.49, b = 0.04 },
    ["DEMONHUNTER"] = { r = 0.64, g = 0.19, b = 0.79 },
    ["EVOKER"] = { r = 0.2, g = 0.58, b = 0.5 },
}

-- Class icon texture coordinates (from Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes)
-- Using blizzard's atlas system for class icons
GladiusMidnight.ClassResources.ClassIcons = {
    ["WARRIOR"] = "classicon-warrior",
    ["PALADIN"] = "classicon-paladin",
    ["HUNTER"] = "classicon-hunter",
    ["ROGUE"] = "classicon-rogue",
    ["PRIEST"] = "classicon-priest",
    ["DEATHKNIGHT"] = "classicon-deathknight",
    ["SHAMAN"] = "classicon-shaman",
    ["MAGE"] = "classicon-mage",
    ["WARLOCK"] = "classicon-warlock",
    ["MONK"] = "classicon-monk",
    ["DRUID"] = "classicon-druid",
    ["DEMONHUNTER"] = "classicon-demonhunter",
    ["EVOKER"] = "classicon-evoker",
}

-- Spec-specific power overrides (when spec changes primary resource)
GladiusMidnight.ClassResources.SpecPowerOverrides = {
    -- Shadow Priest uses Insanity
    [258] = Enum.PowerType.Insanity,
    -- Elemental Shaman uses Maelstrom
    [262] = Enum.PowerType.Maelstrom,
    -- Enhancement Shaman uses Maelstrom
    [263] = Enum.PowerType.Maelstrom,
    -- Balance Druid uses Astral Power (Lunar Power)
    [102] = Enum.PowerType.LunarPower,
    -- Feral Druid uses Energy
    [103] = Enum.PowerType.Energy,
    -- Guardian Druid uses Rage
    [104] = Enum.PowerType.Rage,
    -- Vengeance DH uses Pain (mapped to Fury in API)
    [581] = Enum.PowerType.Fury,
}

-- Get the power type for a given class and spec
function GladiusMidnight.ClassResources:GetPowerType(class, specID)
    if specID and self.SpecPowerOverrides[specID] then
        return self.SpecPowerOverrides[specID]
    end
    return self.PowerTypes[class] or Enum.PowerType.Mana
end

-- Get power color
function GladiusMidnight.ClassResources:GetPowerColor(powerType)
    return self.PowerColors[powerType] or { r = 0.5, g = 0.5, b = 0.5 }
end

-- Get class color
function GladiusMidnight.ClassResources:GetClassColor(class)
    -- Try to use Blizzard's class colors first
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        return RAID_CLASS_COLORS[class]
    end
    return self.ClassColors[class] or { r = 0.5, g = 0.5, b = 0.5 }
end
