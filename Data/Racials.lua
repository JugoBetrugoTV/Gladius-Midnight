-- Gladius Midnight - Racial Ability Data
-- Compatible with WoW Midnight 12.0

local _, GladiusMidnight = ...
GladiusMidnight.RacialData = GladiusMidnight.RacialData or {}

-- PvP-relevant racial abilities with their cooldowns and textures
-- Format: [spellID] = { cooldown = seconds, texture = "texture_path", name = "ability_name" }
GladiusMidnight.RacialData.Abilities = {
    -- Alliance
    -- Human - Will to Survive (removes stun)
    [59752] = { cooldown = 180, name = "Will to Survive" },

    -- Dwarf - Stoneform (removes poison, disease, bleed, magic)
    [20594] = { cooldown = 120, name = "Stoneform" },

    -- Night Elf - Shadowmeld
    [58984] = { cooldown = 120, name = "Shadowmeld" },

    -- Gnome - Escape Artist (removes roots/snares)
    [20589] = { cooldown = 60, name = "Escape Artist" },

    -- Draenei - Gift of the Naaru (heal)
    [28880] = { cooldown = 180, name = "Gift of the Naaru" },

    -- Worgen - Darkflight (sprint)
    [68992] = { cooldown = 120, name = "Darkflight" },

    -- Void Elf - Spatial Rift
    [256948] = { cooldown = 180, name = "Spatial Rift" },

    -- Lightforged Draenei - Light's Judgment
    [255647] = { cooldown = 150, name = "Light's Judgment" },

    -- Dark Iron Dwarf - Fireblood
    [265221] = { cooldown = 120, name = "Fireblood" },

    -- Kul Tiran - Haymaker
    [287712] = { cooldown = 150, name = "Haymaker" },

    -- Mechagnome - Emergency Failsafe
    [312924] = { cooldown = 150, name = "Emergency Failsafe" },

    -- Dracthyr (Alliance) - Tail Swipe / Wing Buffet handled by class

    -- Earthen (Alliance) - Azerite Surge
    [436344] = { cooldown = 120, name = "Azerite Surge" },

    -- Horde
    -- Orc - Blood Fury
    [33697] = { cooldown = 120, name = "Blood Fury" },
    [20572] = { cooldown = 120, name = "Blood Fury" }, -- Melee version
    [33702] = { cooldown = 120, name = "Blood Fury" }, -- Spell version

    -- Undead - Will of the Forsaken (fear/charm/sleep immunity)
    [7744] = { cooldown = 180, name = "Will of the Forsaken" },

    -- Tauren - War Stomp
    [20549] = { cooldown = 90, name = "War Stomp" },

    -- Troll - Berserking
    [26297] = { cooldown = 180, name = "Berserking" },

    -- Blood Elf - Arcane Torrent
    [28730] = { cooldown = 120, name = "Arcane Torrent" },
    [25046] = { cooldown = 120, name = "Arcane Torrent" },
    [50613] = { cooldown = 120, name = "Arcane Torrent" },
    [69179] = { cooldown = 120, name = "Arcane Torrent" },
    [80483] = { cooldown = 120, name = "Arcane Torrent" },
    [129597] = { cooldown = 120, name = "Arcane Torrent" },
    [155145] = { cooldown = 120, name = "Arcane Torrent" },
    [202719] = { cooldown = 120, name = "Arcane Torrent" },
    [232633] = { cooldown = 120, name = "Arcane Torrent" },

    -- Goblin - Rocket Jump
    [69070] = { cooldown = 90, name = "Rocket Jump" },

    -- Pandaren - Quaking Palm
    [107079] = { cooldown = 120, name = "Quaking Palm" },

    -- Nightborne - Arcane Pulse
    [260364] = { cooldown = 180, name = "Arcane Pulse" },

    -- Highmountain Tauren - Bull Rush
    [255654] = { cooldown = 120, name = "Bull Rush" },

    -- Mag'har Orc - Ancestral Call
    [274738] = { cooldown = 120, name = "Ancestral Call" },

    -- Zandalari Troll - Regeneratin'
    [291944] = { cooldown = 150, name = "Regeneratin'" },

    -- Vulpera - Bag of Tricks
    [312411] = { cooldown = 90, name = "Bag of Tricks" },

    -- Dracthyr - Tail Swipe
    [368970] = { cooldown = 90, name = "Tail Swipe" },
    -- Dracthyr - Wing Buffet
    [357214] = { cooldown = 90, name = "Wing Buffet" },
}

-- Race to primary racial mapping (for display purposes)
-- Using the main PvP-relevant racial for each race
GladiusMidnight.RacialData.RaceToRacial = {
    ["Human"] = 59752,
    ["Dwarf"] = 20594,
    ["NightElf"] = 58984,
    ["Gnome"] = 20589,
    ["Draenei"] = 28880,
    ["Worgen"] = 68992,
    ["VoidElf"] = 256948,
    ["LightforgedDraenei"] = 255647,
    ["DarkIronDwarf"] = 265221,
    ["KulTiran"] = 287712,
    ["Mechagnome"] = 312924,
    ["Earthen"] = 436344,
    ["Orc"] = 33697,
    ["Scourge"] = 7744, -- Undead
    ["Tauren"] = 20549,
    ["Troll"] = 26297,
    ["BloodElf"] = 28730,
    ["Goblin"] = 69070,
    ["Pandaren"] = 107079,
    ["Nightborne"] = 260364,
    ["HighmountainTauren"] = 255654,
    ["MagharOrc"] = 274738,
    ["ZandalariTroll"] = 291944,
    ["Vulpera"] = 312411,
    ["Dracthyr"] = 368970,
}

-- Racials that share cooldown with PvP trinket (CC-break abilities)
GladiusMidnight.RacialData.TrinketSharedCooldown = {
    [59752] = true,  -- Will to Survive (Human)
    [7744] = true,   -- Will of the Forsaken (Undead)
}

-- Racials that break specific CC types (for info display)
GladiusMidnight.RacialData.CCBreakTypes = {
    [59752] = { "stun" },
    [7744] = { "fear", "charm", "sleep" },
    [20594] = { "poison", "disease", "bleed", "magic", "curse" }, -- Stoneform
    [265221] = { "poison", "disease", "bleed", "magic", "curse" }, -- Fireblood
    [20589] = { "root", "snare" }, -- Escape Artist
}

-- Get racial info by spellID
function GladiusMidnight.RacialData:GetRacialInfo(spellID)
    -- In Midnight 12.0, spellID may be "secret" for arena opponents
    if not spellID or type(spellID) ~= "number" then return nil end
    return self.Abilities[spellID]
end

-- Check if a spellID is a tracked racial
function GladiusMidnight.RacialData:IsTrackedRacial(spellID)
    -- In Midnight 12.0, spellID may be "secret" for arena opponents
    if not spellID or type(spellID) ~= "number" then return false end
    return self.Abilities[spellID] ~= nil
end

-- Get the primary racial for a race
function GladiusMidnight.RacialData:GetRacialForRace(race)
    local spellID = self.RaceToRacial[race]
    if spellID then
        return spellID, self.Abilities[spellID]
    end
    return nil, nil
end

-- Check if racial shares CD with trinket
function GladiusMidnight.RacialData:SharesTrinketCooldown(spellID)
    -- In Midnight 12.0, spellID may be "secret" for arena opponents
    if not spellID or type(spellID) ~= "number" then return false end
    return self.TrinketSharedCooldown[spellID] == true
end
