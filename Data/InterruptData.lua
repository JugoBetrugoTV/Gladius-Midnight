--[[=========================================================================
    Gladius Midnight - Interrupt Data
    Maps interrupt spell IDs to their lockout durations
===========================================================================]]

local _, Gladius = ...

-- Interrupt spells: spellID -> lockout duration in seconds
Gladius.INTERRUPT_SPELLS = {
    [1766]   = 3,    -- Kick (Rogue)
    [2139]   = 5,    -- Counterspell (Mage)
    [6552]   = 3,    -- Pummel (Warrior)
    [19647]  = 5,    -- Spell Lock (Warlock Felhunter)
    [47528]  = 3,    -- Mind Freeze (Death Knight)
    [57994]  = 2,    -- Wind Shear (Shaman)
    [91802]  = 2,    -- Shambling Rush (DK Pet)
    [96231]  = 3,    -- Rebuke (Paladin)
    [106839] = 3,    -- Skull Bash (Druid Feral/Guardian)
    [115781] = 5,    -- Optical Blast (Warlock Observer)
    [116705] = 3,    -- Spear Hand Strike (Monk)
    [132409] = 5,    -- Spell Lock (Warlock Command Demon)
    [147362] = 3,    -- Countershot (Hunter)
    [171138] = 5,    -- Shadow Lock (Warlock Doomguard)
    [183752] = 3,    -- Consume Magic (Demon Hunter)
    [187707] = 3,    -- Muzzle (Hunter Survival)
    [212619] = 5,    -- Call Felhunter (Warlock)
    [231665] = 3,    -- Avenger's Shield (Paladin Protection)
    [351338] = 4,    -- Quell (Evoker)
    [97547]  = 4,    -- Solar Beam (Druid Balance)
}

-- Player interrupt spell for each class
-- Used to detect when the player's own interrupt is on cooldown
Gladius.CLASS_INTERRUPT_SPELLS = {
    ["ROGUE"]       = 1766,    -- Kick
    ["MAGE"]        = 2139,    -- Counterspell
    ["WARRIOR"]     = 6552,    -- Pummel
    ["DEATHKNIGHT"] = 47528,   -- Mind Freeze
    ["SHAMAN"]      = 57994,   -- Wind Shear
    ["PALADIN"]     = 96231,   -- Rebuke
    ["DRUID"]       = 106839,  -- Skull Bash
    ["MONK"]        = 116705,  -- Spear Hand Strike
    ["HUNTER"]      = 147362,  -- Countershot
    ["DEMONHUNTER"] = 183752,  -- Consume Magic
    ["WARLOCK"]     = 19647,   -- Spell Lock
    ["EVOKER"]      = 351338,  -- Quell
    ["PRIEST"]      = nil,     -- No baseline interrupt
}
