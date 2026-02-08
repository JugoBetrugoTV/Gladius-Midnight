--[[=========================================================================
    Gladius Midnight - Racial Ability Data
    Maps races to their PvP-relevant racial abilities with cooldowns
===========================================================================]]

local _, Gladius = ...

-- Racial ability definitions
-- Format: { spellID, cooldownSeconds, sharedCooldownWithTrinket }
Gladius.RACIAL_SPELLS = {
    ["Human"]              = { spellID = 59752,   duration = 180, sharedCD = 90  },  -- Will to Survive
    ["Scourge"]            = { spellID = 7744,    duration = 120, sharedCD = 30  },  -- Will of the Forsaken
    ["Dwarf"]              = { spellID = 20594,   duration = 120, sharedCD = 30  },  -- Stoneform
    ["NightElf"]           = { spellID = 58984,   duration = 120, sharedCD = 0   },  -- Shadowmeld
    ["Gnome"]              = { spellID = 20589,   duration = 60,  sharedCD = 0   },  -- Escape Artist
    ["Draenei"]            = { spellID = 59542,   duration = 120, sharedCD = 0   },  -- Gift of the Naaru
    ["Worgen"]             = { spellID = 68992,   duration = 120, sharedCD = 0   },  -- Darkflight
    ["Pandaren"]           = { spellID = 107079,  duration = 120, sharedCD = 0   },  -- Quaking Palm
    ["Orc"]                = { spellID = 33697,   duration = 120, sharedCD = 0   },  -- Blood Fury
    ["Tauren"]             = { spellID = 20549,   duration = 90,  sharedCD = 0   },  -- War Stomp
    ["Troll"]              = { spellID = 26297,   duration = 180, sharedCD = 0   },  -- Berserking
    ["BloodElf"]           = { spellID = 202719,  duration = 90,  sharedCD = 0   },  -- Arcane Torrent
    ["Goblin"]             = { spellID = 69070,   duration = 90,  sharedCD = 0   },  -- Rocket Jump
    ["LightforgedDraenei"] = { spellID = 255647,  duration = 150, sharedCD = 0   },  -- Light's Judgment
    ["HighmountainTauren"] = { spellID = 255654,  duration = 120, sharedCD = 0   },  -- Bull Rush
    ["Nightborne"]         = { spellID = 260364,  duration = 180, sharedCD = 0   },  -- Arcane Pulse
    ["MagharOrc"]          = { spellID = 274738,  duration = 120, sharedCD = 0   },  -- Ancestral Call
    ["DarkIronDwarf"]      = { spellID = 265221,  duration = 120, sharedCD = 30  },  -- Fireblood
    ["ZandalariTroll"]     = { spellID = 291944,  duration = 160, sharedCD = 0   },  -- Regeneratin'
    ["VoidElf"]            = { spellID = 256948,  duration = 180, sharedCD = 0   },  -- Spatial Rift
    ["KulTiran"]           = { spellID = 287712,  duration = 160, sharedCD = 0   },  -- Haymaker
    ["Mechagnome"]         = { spellID = 312924,  duration = 180, sharedCD = 0   },  -- Hyper Organic Light Originator
    ["Vulpera"]            = { spellID = 312411,  duration = 90,  sharedCD = 0   },  -- Bag of Tricks
    ["Dracthyr"]           = { spellID = 368970,  duration = 90,  sharedCD = 0   },  -- Tail Swipe
    ["EarthenDwarf"]       = { spellID = 436344,  duration = 120, sharedCD = 0   },  -- Azerite Surge
}

-- Reverse lookup: spell ID -> race name (for combat log detection)
Gladius.RACIAL_SPELL_LOOKUP = {}
for race, data in pairs(Gladius.RACIAL_SPELLS) do
    Gladius.RACIAL_SPELL_LOOKUP[data.spellID] = race
end

-- Additional racial spell IDs that are aura-based variants
Gladius.RACIAL_AURA_VARIANTS = {
    [65116]  = 20594,   -- Stoneform Aura -> Stoneform
    [273104] = 265221,  -- Fireblood Aura -> Fireblood
}

-- Wing Buffet is also Dracthyr but a different spell
Gladius.RACIAL_SPELL_LOOKUP[357214] = "Dracthyr"
