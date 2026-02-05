--PASTE INTO NEW FILE: modules/Auras/DRData.lua
local AC = _G.ArenaCore
if not AC then return end

AC.DR_CATEGORIES = {
    "Stun",
    "Incapacitate",
    "Disorient",
    "Incapacitate",
    "Silence",
    "Root",
    "Knock",
    "Disarm",
}

-- This list maps Spell IDs to their respective DR categories.
-- CRITICAL FIX: All categories use lowercase to match frame.drIcons keys (stun, disorient, etc.)
AC.DR_SPELL_LIST = {
    [207167] = "disorient", -- Blinding Sleet
    [207685] = "disorient", -- Sigil of Misery
    [33786] = "disorient", -- Cyclone
    [209753] = "disorient", -- Cyclone (Honor talent)
    [31661] = "disorient", -- Dragon's Breath
    [198909] = "disorient", -- Song of Chi-ji
    [105421] = "disorient", -- Blinding Light
    [605] = "disorient", -- Mind Control
    [8122] = "disorient", -- Psychic Scream
    [226943] = "disorient", -- Mind Bomb
    [2094] = "disorient", -- Blind
    [118699] = "disorient", -- Fear
    [130616] = "disorient", -- Fear (Warlock Horrify talent)
    [5484] = "disorient", -- Howl of Terror
    [6358] = "disorient", -- Seduction (Succubus)
    [115268] = "disorient", -- Mesmerize (Shivarra)
    [5246] = "disorient", -- Intimidating Shout
    [316593] = "disorient", -- Intimidating Shout (Menace Main Target)
    [316595] = "disorient", -- Intimidating Shout (Menace Other Targets)
    [1513] = "disorient", -- Scare Beast
    [10326] = "disorient", -- Turn Evil
    [331866] = "disorient", -- Agent of Chaos
    [324263] = "disorient", -- Sulfuric Emission
    [360806] = "disorient", -- Sleep Walk

    [217832] = "incapacitate", -- Imprison
    [221527] = "incapacitate", -- Imprison (Honor talent)
    [99] = "incapacitate", -- Incapacitating Roar
    [3355] = "incapacitate", -- Freezing Trap
    [203337] = "incapacitate", -- Freezing Trap (Honor talent)
    [213691] = "incapacitate", -- Scatter Shot
    [118] = "incapacitate", -- Polymorph
    [28271] = "incapacitate", -- Polymorph (Turtle)
    [28272] = "incapacitate", -- Polymorph (Pig)
    [61025] = "incapacitate", -- Polymorph (Snake)
    [61305] = "incapacitate", -- Polymorph (Black Cat)
    [61780] = "incapacitate", -- Polymorph (Turkey)
    [61721] = "incapacitate", -- Polymorph (Rabbit)
    [126819] = "incapacitate", -- Polymorph (Porcupine)
    [161353] = "incapacitate", -- Polymorph (Polar Bear Cub)
    [161354] = "incapacitate", -- Polymorph (Monkey)
    [161355] = "incapacitate", -- Polymorph (Penguin)
    [161372] = "incapacitate", -- Polymorph (Peacock)
    [277787] = "incapacitate", -- Polymorph (Baby Direhorn)
    [277792] = "incapacitate", -- Polymorph (Bumblebee)
    [391622] = "incapacitate", -- Polymorph (Duck)
    [383121] = "incapacitate", -- Mass Polymorph
    [82691] = "incapacitate", -- Ring of Frost
    [115078] = "incapacitate", -- Paralysis
    [20066] = "incapacitate", -- Repentance
    [9484] = "incapacitate", -- Shackle Undead
    [200196] = "incapacitate", -- Holy Word: Chastise
    [1776] = "incapacitate", -- Gouge
    [6770] = "incapacitate", -- Sap
    [51514] = "incapacitate", -- Hex
    [196942] = "incapacitate", -- Hex (Voodoo Totem)
    [197214] = "incapacitate", -- Sundering
    [710] = "incapacitate", -- Banish
    [6789] = "incapacitate", -- Mortal Coil
    [107079] = "incapacitate", -- Quaking Palm (Pandaren)
    [2637] = "incapacitate", -- Hibernate

    [47476] = "silence", -- Strangulate
    [204490] = "silence", -- Sigil of Silence
    [202933] = "silence", -- Spider Sting
    [15487] = "silence", -- Silence
    [1330] = "silence", -- Garrote

    [108194] = "stun", -- Asphyxiate (Unholy)
    [221562] = "stun", -- Asphyxiate (Blood)
    [377048] = "stun", -- Absolute Zero (Frost)
    [91800] = "stun", -- Gnaw (Ghoul)
    [91797] = "stun", -- Monstrous Blow (Mutated Ghoul)
    [287254] = "stun", -- Dead of Winter
    [179057] = "stun", -- Chaos Nova
    [205630] = "stun", -- Illidan's Grasp (Primary effect)
    [208618] = "stun", -- Illidan's Grasp (Secondary effect)
    [211881] = "stun", -- Fel Eruption
    [203123] = "stun", -- Maim
    [163505] = "stun", -- Rake (Prowl)
    [5211] = "stun", -- Mighty Bash
    [24394] = "stun", -- Intimidation
    [117526] = "stun", -- Binding Shot
    [119381] = "stun", -- Leg Sweep
    [202346] = "stun", -- Double Barrel
    [853] = "stun", -- Hammer of Justice
    [64044] = "stun", -- Psychic Horror
    [200200] = "stun", -- Holy Word: Chastise Censure
    [1833] = "stun", -- Cheap Shot
    [408] = "stun", -- Kidney Shot
    [118905] = "stun", -- Static Charge (Capacitor Totem)
    [305485] = "stun", -- Lightning Lasso
    [30283] = "stun", -- Shadowfury
    [46968] = "stun", -- Shockwave
    [132168] = "stun", -- Shockwave (Protection)
    [132169] = "stun", -- Storm Bolt
    [20549] = "stun", -- War Stomp (Tauren)
    [287712] = "stun", -- Haymaker (Kul Tiran)
    [389831] = "stun", -- Snowdrift
    [256148] = "stun", -- Iron Wire (Monk - ADDED FOR USER)

    [204085] = "root", -- Deathchill (Chains of Ice)
    [233395] = "root", -- Deathchill (Remorseless Winter)
    [339] = "root", -- Entangling Roots
    [102359] = "root", -- Mass Entanglement
    [162480] = "root", -- Steel Trap
    [212638] = "root", -- Tracker's Net
    [122] = "root", -- Frost Nova
    [33395] = "root", -- Freeze
    [378760] = "root", -- Frostbite
    [116706] = "root", -- Disable
    [64695] = "root", -- Earthgrab (Totem effect)

    [207777] = "disarm", -- Dismantle
    [233759] = "disarm", -- Grapple Weapon
    [236077] = "disarm", -- Disarm
    [209749] = "disarm", -- Faerie Swarm (Balance)

    [51490] = "knock", -- Thunderstorm
    [132469] = "knock", -- Typhoon
    [357214] = "knock", -- Evoker Racial (Wing Buffet)
    [236776] = "knock", -- High explosive trap
}