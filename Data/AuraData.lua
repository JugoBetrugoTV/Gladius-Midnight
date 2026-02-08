--[[=========================================================================
    Gladius Midnight - Aura Priority Data
    Priority-ranked spell list for arena aura display
    Higher number = more important / shown first

    Priority Tiers:
      9.0+  = Hard CC (Stuns, Polys, Fears, etc.)
      8.0   = Full Immunities (Divine Shield, Ice Block, etc.)
      7.0   = Partial Immunities (Evasion, AMS, Spell Reflect)
      6.0   = Interrupts and Silences
      5.0   = Disarms and Smoke Bomb
      4.0-4.9 = Roots and offensive debuffs
      3.0-3.5 = Offensive buffs and refreshments
      2.5   = Defensive buffs
      2.0-2.4 = Miscellaneous important buffs
      1.0   = Form changes
===========================================================================]]

local _, Gladius = ...

-- Spell lock duration reducers (talent effects)
Gladius.SPELL_LOCK_REDUCERS = {
    [317920] = 0.7,  -- Concentration Aura
    [234084] = 0.5,  -- Moon and Stars
    [383020] = 0.5,  -- Tranquil Air
}

Gladius.AURA_PRIORITIES = {
    -- =======================================
    -- HARD CC - Priority 9
    -- =======================================

    -- Stuns
    [378441] = 9.1,      -- Time Stop
    [5211]   = 9,         -- Mighty Bash
    [108194] = 9,         -- Asphyxiate (Unholy)
    [221562] = 9,         -- Asphyxiate (Blood)
    [377048] = 9,         -- Absolute Zero
    [91797]  = 9,         -- Monstrous Blow
    [287254] = 9,         -- Dead of Winter
    [210141] = 9,         -- Zombie Explosion
    [118905] = 9,         -- Static Charge
    [1833]   = 9,         -- Cheap Shot
    [853]    = 9,         -- Hammer of Justice
    [179057] = 9,         -- Chaos Nova
    [132169] = 9,         -- Storm Bolt
    [408]    = 9,         -- Kidney Shot
    [163505] = 9,         -- Rake (Prowl)
    [119381] = 9,         -- Leg Sweep
    [89766]  = 9,         -- Axe Toss
    [30283]  = 9,         -- Shadowfury
    [24394]  = 9,         -- Intimidation
    [117526] = 9,         -- Binding Shot
    [357021] = 9,         -- Consecutive Concussion
    [211881] = 9,         -- Fel Eruption
    [91800]  = 9,         -- Gnaw
    [205630] = 9,         -- Illidan's Grasp
    [208618] = 9,         -- Illidan's Grasp (Secondary)
    [203123] = 9,         -- Maim
    [202244] = 9,         -- Overrun
    [200200] = 9,         -- Holy Word: Chastise (Censure)
    [22703]  = 9,         -- Infernal Awakening
    [132168] = 9,         -- Shockwave
    [20549]  = 9,         -- War Stomp
    [199085] = 9,         -- Warpath
    [305485] = 9,         -- Lightning Lasso
    [64044]  = 9,         -- Psychic Horror
    [255723] = 9,         -- Bull Rush
    [202346] = 9,         -- Double Barrel
    [213688] = 9,         -- Fel Cleave
    [204399] = 9,         -- Earthfury
    [118345] = 9,         -- Pulverize
    [171017] = 9,         -- Meteor Strike (Infernal)
    [171018] = 9,         -- Meteor Strike (Abyssal)
    [46968]  = 9,         -- Shockwave
    [287712] = 9,         -- Haymaker
    [372245] = 9,         -- Terror of the Skies
    [389831] = 9,         -- Snowdrift

    -- Disorients
    [5246]   = 9,         -- Intimidating Shout
    [316593] = 9,         -- Intimidating Shout (Menace Main)
    [316595] = 9,         -- Intimidating Shout (Menace Others)
    [8122]   = 9,         -- Psychic Scream
    [2094]   = 9,         -- Blind
    [605]    = 9,         -- Mind Control
    [105421] = 9,         -- Blinding Light
    [207167] = 9,         -- Blinding Sleet
    [31661]  = 9,         -- Dragon's Breath
    [207685] = 9,         -- Sigil of Misery
    [198909] = 9,         -- Song of Chi-ji
    [202274] = 9,         -- Incendiary Brew
    [130616] = 9,         -- Fear (Horrify)
    [118699] = 9,         -- Fear
    [1513]   = 9,         -- Scare Beast
    [10326]  = 9,         -- Turn Evil
    [6358]   = 9,         -- Seduction
    [261589] = 9,         -- Seduction (Grimoire)
    [5484]   = 9,         -- Howl of Terror
    [115268] = 9,         -- Mesmerize
    [87204]  = 9,         -- Sin and Punishment
    [2637]   = 9,         -- Hibernate
    [226943] = 9,         -- Mind Bomb
    [236748] = 9,         -- Intimidating Roar
    [331866] = 9,         -- Agent of Chaos
    [324263] = 9,         -- Sulfuric Emission
    [360806] = 9,         -- Sleep Walk
    [358861] = 9,         -- Void Volley
    [33786]  = 9,         -- Cyclone

    -- Incapacitates
    [51514]  = 9,         -- Hex
    [211004] = 9,         -- Hex: Spider
    [210873] = 9,         -- Hex: Raptor
    [211015] = 9,         -- Hex: Cockroach
    [211010] = 9,         -- Hex: Snake
    [196942] = 9,         -- Hex: Voodoo Totem
    [277784] = 9,         -- Hex: Wicker Mongrel
    [277778] = 9,         -- Hex: Zandalari Tendonripper
    [269352] = 9,         -- Hex: Skeletal Hatchling
    [309328] = 9,         -- Hex: Living Honey
    [118]    = 9,         -- Polymorph
    [61305]  = 9,         -- Polymorph: Black Cat
    [28272]  = 9,         -- Polymorph: Pig
    [61721]  = 9,         -- Polymorph: Rabbit
    [61780]  = 9,         -- Polymorph: Turkey
    [28271]  = 9,         -- Polymorph: Turtle
    [161353] = 9,         -- Polymorph: Polar Bear Cub
    [126819] = 9,         -- Polymorph: Porcupine
    [161354] = 9,         -- Polymorph: Monkey
    [161355] = 9,         -- Polymorph: Penguin
    [161372] = 9,         -- Polymorph: Peacock
    [277792] = 9,         -- Polymorph: Bumblebee
    [277787] = 9,         -- Polymorph: Baby Direhorn
    [391622] = 9,         -- Polymorph: Duck
    [383121] = 9,         -- Mass Polymorph
    [3355]   = 9,         -- Freezing Trap
    [203337] = 9,         -- Freezing Trap (Diamond Ice)
    [115078] = 9,         -- Paralysis
    [213691] = 9,         -- Scatter Shot
    [6770]   = 9,         -- Sap
    [20066]  = 9,         -- Repentance
    [200196] = 9,         -- Holy Word: Chastise
    [221527] = 9,         -- Imprison (Detainment)
    [217832] = 9,         -- Imprison
    [99]     = 9,         -- Incapacitating Roar
    [82691]  = 9,         -- Ring of Frost
    [1776]   = 9,         -- Gouge
    [107079] = 9,         -- Quaking Palm
    [236025] = 9,         -- Enraged Maim
    [197214] = 9,         -- Sundering
    [9484]   = 9,         -- Shackle Undead
    [710]    = 9,         -- Banish
    [6789]   = 9,         -- Mortal Coil

    -- =======================================
    -- IMMUNITIES - Priority 8
    -- =======================================
    [213610] = 8.1,       -- Holy Ward
    [377362] = 8.1,       -- Precog
    [456499] = 8,         -- Absolute Serenity
    [642]    = 8,         -- Divine Shield
    [186265] = 8,         -- Aspect of the Turtle
    [45438]  = 8,         -- Ice Block
    [196555] = 8,         -- Netherwalk
    [47585]  = 8,         -- Dispersion
    [1022]   = 8,         -- Blessing of Protection
    [204018] = 8,         -- Blessing of Spellwarding
    [31224]  = 8,         -- Cloak of Shadows
    [8178]   = 8,         -- Grounding Totem
    [199448] = 8,         -- Blessing of Sacrifice
    [227847] = 8,         -- Bladestorm (Arms)
    [446035] = 8,         -- Bladestorm (Fury)
    [118038] = 8,         -- Die by the Sword
    [357210] = 8,         -- Deep Breath
    [116849] = 8,         -- Life Cocoon
    [212800] = 8,         -- Blur
    [48792]  = 8,         -- Icebound Fortitude
    [409293] = 8,         -- Burrow

    -- =======================================
    -- PARTIAL IMMUNITIES - Priority 7
    -- =======================================
    [5277]   = 7,         -- Evasion
    [23920]  = 7,         -- Spell Reflection
    [212295] = 7,         -- Nether Ward
    [48707]  = 7,         -- Anti-Magic Shell
    [410358] = 7,         -- Anti-Magic Shell (variant)
    [5384]   = 7,         -- Feign Death
    [353319] = 7,         -- Peaceweaver
    [378464] = 7,         -- Nullifying Shroud
    [31821]  = 7,         -- Aura Mastery
    [206803] = 7,         -- Rain from Above

    -- =======================================
    -- INTERRUPTS / SILENCES - Priority 6
    -- =======================================
    [1766]   = 6,         -- Kick
    [2139]   = 6,         -- Counterspell
    [6552]   = 6,         -- Pummel
    [19647]  = 6,         -- Spell Lock
    [47528]  = 6,         -- Mind Freeze
    [57994]  = 6,         -- Wind Shear
    [106839] = 6,         -- Skull Bash
    [116705] = 6,         -- Spear Hand Strike
    [147362] = 6,         -- Countershot
    [183752] = 6,         -- Consume Magic
    [187707] = 6,         -- Muzzle
    [351338] = 6,         -- Quell
    [97547]  = 6,         -- Solar Beam

    [202933] = 6,         -- Spider Sting
    [356727] = 6,         -- Spider Venom
    [1330]   = 6,         -- Garrote
    [15487]  = 6,         -- Silence
    [199683] = 6,         -- Last Word
    [47476]  = 6,         -- Strangulate
    [204490] = 6,         -- Sigil of Silence
    [217824] = 6,         -- Shield of Virtue
    [375901] = 6,         -- Mindgames
    [81261]  = 5.5,       -- Solar Beam (area)

    -- =======================================
    -- DISARMS / SMOKE - Priority 5
    -- =======================================
    [236077] = 5,         -- Disarm
    [236236] = 5,         -- Disarm (Protection)
    [209749] = 5,         -- Faerie Swarm
    [233759] = 5,         -- Grapple Weapon
    [207777] = 5,         -- Dismantle
    [212182] = 4.9,       -- Smoke Bomb
    [212183] = 4.9,       -- Smoke Bomb (variant)

    -- =======================================
    -- OFFENSIVE DEBUFFS - Priority 4.5
    -- =======================================
    [383005] = 4.5,       -- Chrono Loop
    [372048] = 4.5,       -- Oppressing Roar
    [356723] = 4.5,       -- Scorpid Venom

    -- =======================================
    -- ROOTS - Priority 4
    -- =======================================
    [376080] = 4,         -- Spear
    [105771] = 4,         -- Charge
    [324382] = 4,         -- Clash
    [114404] = 4,         -- Void Tendrils
    [339]    = 4,         -- Entangling Roots
    [170855] = 4,         -- Entangling Roots (Nature's Grasp)
    [235963] = 4,         -- Entangling Roots (Feral)
    [122]    = 4,         -- Frost Nova
    [386770] = 4,         -- Freezing Cold
    [102359] = 4,         -- Mass Entanglement
    [64695]  = 4,         -- Earthgrab
    [200108] = 4,         -- Ranger's Net
    [212638] = 4,         -- Tracker's Net
    [162480] = 4,         -- Steel Trap
    [204085] = 4,         -- Deathchill
    [233395] = 4,         -- Frozen Center
    [33395]  = 4,         -- Freeze
    [228600] = 4,         -- Glacial Spike
    [116706] = 4,         -- Disable
    [190927] = 4,         -- Harpoon
    [157997] = 4,         -- Ice Nova
    [378760] = 4,         -- Frostbite
    [355689] = 4,         -- Landslide
    [393456] = 4,         -- Entrapment

    -- =======================================
    -- REFRESHMENTS (Drinking) - Priority 3.5
    -- =======================================
    [167152] = 3.5,       -- Mage Food
    [274914] = 3.5,       -- Rockskip Mineral Water
    [396920] = 3.5,       -- Dragon Spittle
    [369162] = 3.5,       -- Drink
    [452382] = 3.5,       -- Drink (variant)
    [461063] = 3.5,       -- Quiet Contemplation (Earthen)

    -- =======================================
    -- OFFENSIVE BUFFS - Priority 3
    -- =======================================
    [51271]  = 3,         -- Pillar of Frost
    [207289] = 3,         -- Unholy Assault
    [162264] = 3,         -- Metamorphosis
    [194223] = 3,         -- Celestial Alignment
    [383410] = 3,         -- Celestial Alignment (Orbital)
    [102560] = 3,         -- Incarnation: Chosen of Elune
    [5217]   = 3,         -- Tiger's Fury
    [102543] = 3,         -- Incarnation: King of the Jungle
    [19574]  = 3,         -- Bestial Wrath
    [266779] = 3,         -- Coordinated Assault
    [288613] = 3,         -- Trueshot
    [365362] = 3,         -- Arcane Surge
    [190319] = 3,         -- Combustion
    [205025] = 3,         -- Presence of Mind
    [12472]  = 3,         -- Icy Veins
    [152173] = 3,         -- Serenity
    [137639] = 3,         -- Storm, Earth, and Fire
    [31884]  = 3,         -- Avenging Wrath (Ret)
    [231895] = 3,         -- Crusade
    [185313] = 3,         -- Shadow Dance
    [185422] = 3,         -- Shadow Dance (variant)
    [194249] = 3,         -- Voidform
    [384631] = 3,         -- Flagellation
    [13750]  = 3,         -- Adrenaline Rush
    [121471] = 3,         -- Shadow Blades
    [114050] = 3,         -- Ascendance (Elemental)
    [114051] = 3,         -- Ascendance (Enhancement)
    [191634] = 3,         -- Stormkeeper
    [113858] = 3,         -- Dark Soul: Instability
    [113860] = 3,         -- Dark Soul: Misery
    [107574] = 3,         -- Avatar
    [1719]   = 3,         -- Recklessness
    [375087] = 3,         -- Dragonrage
    [370553] = 3,         -- Tip the Scales
    [10060]  = 3,         -- Power Infusion
    [360952] = 3,         -- Coordinated Assault (variant)

    -- =======================================
    -- DEFENSIVE BUFFS - Priority 2.5
    -- =======================================
    [199450] = 2.6,       -- Ultimate Sacrifice
    [232707] = 2.5,       -- Ray of Hope
    [49039]  = 2.5,       -- Lichborne
    [145629] = 2.5,       -- Anti-Magic Zone
    [81256]  = 2.5,       -- Dancing Rune Weapon
    [55233]  = 2.5,       -- Vampiric Blood
    [188499] = 2.5,       -- Blade Dance
    [209426] = 2.5,       -- Darkness
    [132158] = 2.5,       -- Nature's Swiftness (Druid)
    [22842]  = 2.5,       -- Frenzied Regeneration
    [102342] = 2.5,       -- Ironbark
    [22812]  = 2.5,       -- Barkskin
    [61336]  = 2.5,       -- Survival Instincts
    [117679] = 2.5,       -- Incarnation: Tree of Life
    [236696] = 2.5,       -- Thorns
    [29166]  = 2.5,       -- Innervate
    [53480]  = 2.5,       -- Roar of Sacrifice
    [113862] = 2.5,       -- Greater Invisibility
    [198111] = 2.5,       -- Temporal Shield
    [125174] = 2.5,       -- Touch of Karma
    [120954] = 2.5,       -- Fortifying Brew
    [122783] = 2.5,       -- Diffuse Magic
    [122278] = 2.5,       -- Dampen Harm
    [86659]  = 2.5,       -- Guardian of Ancient Kings
    [6940]   = 2.5,       -- Blessing of Sacrifice
    [184662] = 2.5,       -- Shield of Vengeance
    [31850]  = 2.5,       -- Ardent Defender
    [498]    = 2.5,       -- Divine Protection
    [47788]  = 2.5,       -- Guardian Spirit
    [33206]  = 2.5,       -- Pain Suppression
    [81782]  = 2.5,       -- Power Word: Barrier
    [15286]  = 2.5,       -- Vampiric Embrace
    [47536]  = 2.5,       -- Rapture
    [207736] = 2.5,       -- Shadowy Duel
    [378081] = 2.5,       -- Nature's Swiftness (Shaman)
    [108271] = 2.5,       -- Astral Shift
    [114052] = 2.5,       -- Ascendance (Restoration)
    [104773] = 2.5,       -- Unending Resolve
    [108416] = 2.5,       -- Dark Pact
    [12975]  = 2.5,       -- Last Stand
    [871]    = 2.5,       -- Shield Wall
    [184364] = 2.5,       -- Enraged Regeneration
    [197690] = 2.5,       -- Defensive Stance
    [370960] = 2.5,       -- Emerald Communion
    [363916] = 2.5,       -- Obsidian Scales
    [374348] = 2.5,       -- Renewing Blaze
    [357170] = 2.5,       -- Time Dilation

    -- =======================================
    -- MISCELLANEOUS - Priority 2
    -- =======================================
    [1044]   = 2.4,       -- Blessing of Freedom
    [54216]  = 2.4,       -- Master's Call
    [41425]  = 2.4,       -- Hypothermia
    [384100] = 2.3,       -- Berserker Shout
    [2983]   = 2.3,       -- Sprint
    [358267] = 2.3,       -- Hover
    [190784] = 2.3,       -- Divine Steed
    [319454] = 2.3,       -- Heart of the Wild
    [77606]  = 2,         -- Dark Simulacrum
    [25771]  = 2,         -- Forbearance
    [391528] = 2,         -- Convoke

    -- =======================================
    -- FORM CHANGES - Priority 1
    -- =======================================
    [768]    = 1,         -- Cat Form
    [783]    = 1,         -- Travel Form
    [5487]   = 1,         -- Bear Form
    [197625] = 1,         -- Moonkin Form
}
