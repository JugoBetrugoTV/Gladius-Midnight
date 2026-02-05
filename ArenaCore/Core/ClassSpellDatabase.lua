-- ======================================================================
--  Core/ClassSpellDatabase.lua
--  WoW Retail (The War Within) – Comprehensive Class Ability Database
--  Structure: ClassSpellDB.<CLASS>.{ CC = {...}, DEF = {...}, UTIL = {...} }
--  Date: 2025-10-02
--  
--  This database contains all core abilities for each class that should
--  be tracked in arena auras. These spells are automatically integrated
--  with the aura tracking system when auras are enabled.
-- ======================================================================

local AC = _G.ArenaCore
if not AC then return end

-- Comprehensive class spell database
AC.ClassSpellDB = {

  WARRIOR = {
    CC = {
      {id=5246,   name="Intimidating Shout"},      -- fear
      {id=107570, name="Storm Bolt"},              -- stun
      {id=132169, name="Storm Bolt"},              -- stun (alternate ID)
      {id=46968,  name="Shockwave"},               -- AoE stun (Prot/Arms talent)
      {id=132168, name="Shockwave"},               -- Shockwave (Protection)
      {id=236077, name="Disarm"},                  -- PvP talent
      {id=385954, name="Shield Charge"},           -- stun
      {id=199085, name="Warpath"},                 -- CC
      {id=202346, name="Double Barrel"},           -- stun
    },
    DEF = {
      {id=118038, name="Die by the Sword"},
      {id=871,    name="Shield Wall"},
      {id=12975,  name="Last Stand"},
      {id=184364, name="Enraged Regeneration"},
      {id=23920,  name="Spell Reflection"},
      {id=97462,  name="Rallying Cry"},
    },
    UTIL = {
      {id=6552,   name="Pummel"},                  -- interrupt
      {id=3411,   name="Intervene"},               -- external peel
      {id=213915, name="Mass Spell Reflection"},   -- PvP talent
      -- Removed: Battle Shout (6673), Demoralizing Shout (1160), Commanding Shout (469) - non-PvP raid buffs
      {id=190456, name="Ignore Pain"},             -- trackable mitigation
    },
  },

  PALADIN = {
    CC = {
      {id=853,    name="Hammer of Justice"},       -- stun
      {id=115750, name="Blinding Light"},          -- disorient
      {id=20066,  name="Repentance"},              -- incapacitate
      {id=10326,  name="Turn Evil"},               -- fear (undead/demon)
      {id=410126, name="Searing Glare"},           -- disarm (main spell)
      {id=410201, name="Searing Glare"},           -- disarm (debuff)
    },
    DEF = {
      {id=642,    name="Divine Shield"},
      {id=1022,   name="Blessing of Protection"},
      {id=204018, name="Blessing of Spellwarding"},-- Prot
      {id=6940,   name="Blessing of Sacrifice"},
      {id=31850,  name="Ardent Defender"},
      {id=86659,  name="Guardian of Ancient Kings"},
      {id=184662, name="Shield of Vengeance"},     -- Ret
      {id=498,    name="Divine Protection"},       -- Holy/Prot access varies
    },
    UTIL = {
      {id=96231,  name="Rebuke"},                  -- interrupt
      {id=1044,   name="Blessing of Freedom"},
      {id=20473,  name="Holy Shock"},              -- (if you track key heals)
      {id=317269, name="Aura Mastery"},            -- Holy
      {id=31884,  name="Avenging Wrath"},
      {id=633,    name="Lay on Hands"},
      {id=212641, name="Guardian of the Forgotten Queen"}, -- PvP talent
    },
  },

  HUNTER = {
    CC = {
      {id=3355,   name="Freezing Trap"},           -- incapacitate (trap debuff)
      {id=203337, name="Freezing Trap"},           -- Honor Talent variant
      {id=19577,  name="Intimidation"},            -- stun (pet)
      {id=213691, name="Scatter Shot"},            -- disorient
      {id=19386,  name="Wyvern Sting"},            -- sleep
      {id=109248, name="Binding Shot"},            -- root/stun
      {id=117526, name="Binding Shot"},            -- alternate ID
      {id=162480, name="Steel Trap"},              -- root
      {id=212638, name="Tracker's Net"},           -- root
    },
    DEF = {
      {id=186265, name="Aspect of the Turtle"},
      {id=264735, name="Survival of the Fittest"}, -- BM/SV talent
      {id=53480,  name="Roar of Sacrifice"},       -- external (pet)
      {id=5384,   name="Feign Death"},
      {id=19263,  name="Deterrence"},              -- legacy
    },
    UTIL = {
      {id=147362, name="Counter Shot"},            -- interrupt (MM/SV)
      {id=187707, name="Muzzle"},                  -- interrupt (SV)
      {id=19801,  name="Tranquilizing Shot"},      -- purge/enrage dispel
      {id=1543,   name="Flare"},
      {id=781,    name="Disengage"},
      {id=61648,  name="Aspect of the Chameleon"}, -- PvP
      {id=272651, name="Command Pet: Primal Rage"},-- lust (Ferocity)
    },
  },

  ROGUE = {
    CC = {
      {id=408,    name="Kidney Shot"},             -- stun
      {id=1833,   name="Cheap Shot"},              -- stun (stealth)
      {id=6770,   name="Sap"},                     -- incapacitate
      {id=2094,   name="Blind"},                   -- disorient
      {id=1776,   name="Gouge"},                   -- incapacitate
      {id=1330,   name="Garrote"},                 -- silence
    },
    DEF = {
      {id=31224,  name="Cloak of Shadows"},
      {id=5277,   name="Evasion"},
      {id=1966,   name="Feint"},                   -- DR (Elusiveness)
      {id=1856,   name="Vanish"},
      {id=45182,  name="Cheat Death"},             -- proc (buff)
      {id=199754, name="Riposte"},                 -- defensive
    },
    UTIL = {
      {id=1766,   name="Kick"},                    -- interrupt
      {id=2098,   name="Dispatch"},                -- (ignore if you only track CDs)
      {id=57934,  name="Tricks of the Trade"},
      {id=114018, name="Shroud of Concealment"},
      {id=36554,  name="Shadowstep"},
      {id=13750,  name="Adrenaline Rush"},         -- Outlaw offensive CD
    },
  },

  PRIEST = {
    CC = {
      {id=8122,   name="Psychic Scream"},          -- fear
      {id=605,    name="Mind Control"},            -- charm
      {id=15487,  name="Silence"},                 -- silence (Shadow)
      {id=64044,  name="Psychic Horror"},          -- disarm/horror (PvP/legacy variants)
      {id=323673, name="Mindgames"},               -- (CC-adjacent; optional to track)
      {id=200200, name="Holy Word: Chastise Censure"}, -- stun
      {id=200196, name="Holy Word: Chastise"},     -- incapacitate
      {id=9484,   name="Shackle Undead"},          -- incapacitate
    },
    DEF = {
      {id=33206,  name="Pain Suppression"},        -- Disc external
      {id=47788,  name="Guardian Spirit"},         -- Holy external
      {id=108968, name="Void Shift"},              -- Shadow utility/def
      {id=64843,  name="Divine Hymn"},             -- raid CD
      {id=47585,  name="Dispersion"},              -- Shadow
      {id=19236,  name="Desperate Prayer"},
      {id=408557, name="Phase Shift"},             -- PvP talent version of Fade we track
      {id=213610, name="Holy Ward"},               -- defensive
      {id=27827,  name="Spirit of Redemption"},    -- proc
    },
    UTIL = {
      {id=528,    name="Dispel Magic"},            -- offensive dispel
      {id=527,    name="Purify"},                  -- magic/ disease dispel (ally)
      {id=62618,  name="Power Word: Barrier"},     -- raid CD
      {id=200183, name="Apotheosis"},              -- Holy throughput
      {id=34433,  name="Shadowfiend"},             -- mana/CD track
    },
  },

  DEATHKNIGHT = {
    CC = {
      {id=221562, name="Asphyxiate"},              -- stun (UH/Frost)
      {id=108194, name="Asphyxiate"},              -- Blood/alt ID
      {id=207167, name="Blinding Sleet"},          -- disorient
      {id=91800,  name="Gnaw"},                    -- stun (ghoul)
      {id=91797,  name="Monstrous Blow"},          -- stun (Abomination)
      {id=204085, name="Deathchill"},              -- root (PvP)
      {id=47476,  name="Strangulate"},             -- silence (PvP)
    },
    DEF = {
      {id=48707,  name="Anti-Magic Shell"},
      {id=410358, name="Anti-Magic Shell"},        -- alternate ID
      {id=48792,  name="Icebound Fortitude"},
      {id=51052,  name="Anti-Magic Zone"},         -- external
      {id=55233,  name="Vampiric Blood"},          -- Blood
      {id=49039,  name="Lichborne"},
      {id=194679, name="Rune Tap"},                -- Blood
    },
    UTIL = {
      {id=47528,  name="Mind Freeze"},             -- interrupt
      {id=91802,  name="Shambling Rush"},          -- Unholy pet interrupt
      {id=91807,  name="Shambling Rush"},          -- alternate
      {id=49576,  name="Death Grip"},
      {id=61999,  name="Raise Ally"},              -- battle rez
      {id=212552, name="Wraith Walk"},             -- movement
      {id=221699, name="Blood Tap"},               -- resource
    },
  },

  SHAMAN = {
    CC = {
      {id=51514,  name="Hex"},                     -- incapacitate
      {id=196942, name="Hex"},                     -- Voodoo Totem
      {id=210873, name="Hex"},                     -- Raptor
      {id=211004, name="Hex"},                     -- Spider
      {id=211010, name="Hex"},                     -- Snake
      {id=211015, name="Hex"},                     -- Cockroach
      {id=269352, name="Hex"},                     -- Skeletal Hatchling
      {id=277778, name="Hex"},                     -- Zandalari
      {id=277784, name="Hex"},                     -- Wicker Mongrel
      {id=118905, name="Static Charge"},           -- Capacitor Totem stun aura
      {id=51485,  name="Earthgrab Totem"},         -- root
      {id=64695,  name="Earthgrab"},               -- root effect
      {id=305483, name="Lightning Lasso"},         -- stun (PvP talent)
      {id=305485, name="Lightning Lasso"},         -- alternate ID
      {id=51490,  name="Thunderstorm"},            -- knock (utility/CC)
      {id=118345, name="Pulverize"},               -- Earth Elemental stun
    },
    DEF = {
      {id=108271, name="Astral Shift"},
      {id=98008,  name="Spirit Link Totem"},       -- external/raid
      {id=114050, name="Ascendance"},              -- Ele/Enh (throughput)
      {id=204336, name="Grounding Totem"},         -- PvP
      -- Earth Shield (974) removed - long duration buff, not a key PvP defensive
    },
    UTIL = {
      {id=57994,  name="Wind Shear"},              -- interrupt
      {id=77130,  name="Purify Spirit"},           -- ally dispel (Curses, Magic w/ talent)
      {id=370,    name="Purge"},                   -- offensive dispel
      {id=192077, name="Wind Rush Totem"},         -- raid speed
      {id=16191,  name="Mana Tide Totem"},         -- raid mana CD
      {id=198103, name="Earth Elemental"},         -- off-tank peel
    },
  },

  MAGE = {
    CC = {
      {id=118,    name="Polymorph"},               -- sheep
      {id=28271,  name="Polymorph"},               -- Turtle
      {id=28272,  name="Polymorph"},               -- Pig
      {id=61025,  name="Polymorph"},               -- Snake
      {id=61305,  name="Polymorph"},               -- Black Cat
      {id=61780,  name="Polymorph"},               -- Turkey
      {id=61721,  name="Polymorph"},               -- Rabbit
      {id=126819, name="Polymorph"},               -- Porcupine
      {id=161353, name="Polymorph"},               -- Polar Bear
      {id=161354, name="Polymorph"},               -- Monkey
      {id=161355, name="Polymorph"},               -- Penguin
      {id=161372, name="Polymorph"},               -- Peacock
      {id=277787, name="Polymorph"},               -- Direhorn
      {id=277792, name="Polymorph"},               -- Bumblebee
      {id=321395, name="Polymorph"},               -- Mawrat
      {id=391622, name="Polymorph"},               -- Duck
      {id=31661,  name="Dragon's Breath"},         -- disorient (Fire)
      {id=122,    name="Frost Nova"},              -- root
      {id=33395,  name="Freeze"},                  -- Mage Pet root
      {id=113724, name="Ring of Frost"},           -- incapacitate
      {id=82691,  name="Ring of Frost"},           -- alternate ID
      {id=157997, name="Ice Nova"},                -- root
      {id=118253, name="Ice Nova"},                -- alternate ID
    },
    DEF = {
      {id=45438,  name="Ice Block"},
      {id=235450, name="Prismatic Barrier"},       -- Arcane
      {id=235313, name="Blazing Barrier"},         -- Fire
      {id=11426,  name="Ice Barrier"},             -- Frost
      {id=110959, name="Greater Invisibility"},    -- Arcane/Fire w/ talent
      {id=342245, name="Alter Time"},              -- (check live ID; validator below)
      {id=55342,  name="Mirror Image"},            -- 20% DR talent
    },
    UTIL = {
      {id=2139,   name="Counterspell"},            -- interrupt
      {id=30449,  name="Spellsteal"},
      {id=1953,   name="Blink"},                   -- /Shimmer (talent variant)
      {id=212653, name="Shimmer"},
      {id=157980, name="Supernova"},               -- knock
      {id=66,     name="Invisibility"},
    },
  },

  WARLOCK = {
    CC = {
      {id=5782,   name="Fear"},                    -- fear
      {id=30283,  name="Shadowfury"},              -- AoE stun
      {id=6789,   name="Mortal Coil"},             -- horror
      {id=710,    name="Banish"},                  -- banish
      {id=89766,  name="Axe Toss"},                -- pet stun (Felguard)
      {id=118699, name="Fear (Effect)"},           -- alt Fear debuff
      {id=5484,   name="Howl of Terror"},          -- AoE fear (talent/PvP)
      {id=171017, name="Meteor Strike"},           -- Infernal stun
      {id=171018, name="Meteor Strike"},           -- Abyssal stun
    },
    DEF = {
      {id=104773, name="Unending Resolve"},
      {id=108416, name="Dark Pact"},
      {id=108503, name="Grimoire of Sacrifice"},   -- DR effect in PvP
      {id=20707,  name="Soulstone"},               -- external rez utility
      {id=48020,  name="Demonic Circle: Teleport"},-- defensively used utility
    },
    UTIL = {
      {id=19647,  name="Spell Lock"},              -- pet interrupt (Felhunter)
      {id=132409, name="Spell Lock (Command Demon)"},-- talent variant
      {id=115781, name="Optical Blast"},           -- Observer
      {id=119911, name="Optical Blast"},           -- alternate
      {id=171138, name="Shadow Lock"},             -- Doomguard interrupt
      {id=212295, name="Nether Ward"},             -- reflect (PvP)
      {id=111771, name="Demonic Gateway"},
      {id=698,    name="Ritual of Summoning"},
    },
  },

  MONK = {
    CC = {
      {id=119381, name="Leg Sweep"},               -- stun
      {id=115078, name="Paralysis"},               -- incapacitate
      {id=198898, name="Song of Chi-Ji"},          -- disorient
      {id=116844, name="Ring of Peace"},           -- knock/displace (utility/CC)
    },
    DEF = {
      {id=122783, name="Diffuse Magic"},
      {id=122278, name="Dampen Harm"},
      {id=115203, name="Fortifying Brew"},         -- Brewmaster/WW base ID
      {id=243435, name="Fortifying Brew (MW)"},    -- MW variant
      {id=116849, name="Life Cocoon"},             -- external (MW)
      {id=125174, name="Touch of Karma"},          -- WW (buff aura 122470/125174)
      {id=115176, name="Zen Meditation"},          -- situational
    },
    UTIL = {
      {id=116705, name="Spear Hand Strike"},       -- interrupt
      {id=115546, name="Provoke"},                 -- taunt (utility)
      {id=115008, name="Chi Torpedo"},             -- movement
      {id=115173, name="Celerity"},                -- movement passive (optional)
      {id=115450, name="Detox"},                   -- dispel
      {id=116680, name="Thunder Focus Tea"},       -- MW throughput
    },
  },

  DRUID = {
    CC = {
      {id=33786,  name="Cyclone"},                 -- cyclone (immune CC)
      {id=5211,   name="Mighty Bash"},             -- stun
      {id=22570,  name="Maim"},                    -- stun (Feral)
      {id=203123, name="Maim"},                    -- alternate ID (priority 10)
      {id=163505, name="Rake"},                    -- Rake stun (priority 10)
      {id=339,    name="Entangling Roots"},        -- root
      {id=102359, name="Mass Entanglement"},       -- root
      {id=99,     name="Incapacitating Roar"},     -- incap (Guardian)
      {id=2637,   name="Hibernate"},               -- sleep (beasts/dragonkin)
      {id=102793, name="Ursol's Vortex"},          -- displacement (utility/CC)
      {id=132469, name="Typhoon"},                 -- knock
    },
    DEF = {
      {id=22812,  name="Barkskin"},
      {id=61336,  name="Survival Instincts"},
      {id=102342, name="Ironbark"},                -- external (Resto)
      {id=200851, name="Rage of the Sleeper"},     -- Guardian
      {id=22842,  name="Frenzied Regeneration"},   -- Guardian
      {id=108238, name="Renewal"},                 -- self-save
      {id=473909, name="Ancient of Lore"},         -- Resto (priority 11)
    },
    UTIL = {
      {id=106839, name="Skull Bash"},              -- interrupt (Feral/Guardian)
      {id=78675,  name="Solar Beam"},              -- silence/interrupt (Balance)
      {id=132302, name="Wild Charge"},
      {id=18562,  name="Swiftmend"},
      {id=29166,  name="Innervate"},               -- raid utility
      {id=20484,  name="Rebirth"},                 -- battle rez
      {id=102401, name="Wild Charge (Travel)"},    -- movement variants
    },
  },

  DEMONHUNTER = {
    CC = {
      {id=179057, name="Chaos Nova"},              -- stun
      {id=217832, name="Imprison"},                -- incapacitate
      {id=221527, name="Imprison"},                -- Honor Talent
      {id=202137, name="Sigil of Silence"},        -- silence
      {id=204490, name="Sigil of Silence"},        -- alternate ID
      {id=207684, name="Sigil of Misery"},         -- fear/disorient
      {id=207685, name="Sigil of Misery"},         -- alternate ID
    },
    DEF = {
      {id=198589, name="Blur"},
      {id=212800, name="Blur"},                    -- aura effect
      {id=196718, name="Darkness"},                -- raid/external area DR
      {id=196555, name="Netherwalk"},              -- immunity (Havoc)
      {id=354610, name="Glimpse"},                 -- defensive (priority 11)
      {id=187827, name="Metamorphosis"},           -- Vengeance major
      {id=204021, name="Fiery Brand"},             -- Vengeance DR
    },
    UTIL = {
      {id=183752, name="Disrupt"},                 -- interrupt
      {id=278326, name="Consume Magic"},           -- purge
      {id=232893, name="Felblade"},                -- mobility/charge
      {id=205604, name="Reverse Magic"},           -- PvP dispel
      {id=195072, name="Fel Rush"},                -- movement
    },
  },

  EVOKER = {
    CC = {
      {id=360806, name="Sleep Walk"},              -- sleep
      {id=358385, name="Landslide"},               -- root
      {id=372048, name="Oppressing Roar"},         -- amplifies CC (track as utility/CC)
      {id=357214, name="Wing Buffet"},             -- knock
      {id=368970, name="Tail Swipe"},              -- knock/air
      {id=357210, name="Deep Breath"},             -- PHASE 2: 4-second stun (priority 11)
      {id=433874, name="Deep Breath"},             -- PHASE 2: alternate ID
      {id=371032, name="Terror of the Skies"},     -- PHASE 2: Deep Breath DEBUFF (the actual aura applied!)
    },
    DEF = {
      {id=363916, name="Obsidian Scales"},
      {id=374348, name="Renewing Blaze"},
      {id=357170, name="Time Dilation"},           -- external (Preservation)
      {id=370960, name="Emerald Communion"},       -- big heal/channeled DR
      {id=374227, name="Zephyr"},                  -- party DR (AOE)
      {id=359077, name="Rewind"},                  -- raid CD (Pres)
      {id=378464, name="Nullifying Shroud"},       -- defensive (priority 11)
      {id=378441, name="Time Stop"},               -- defensive (priority 11)
    },
    UTIL = {
      {id=351338, name="Quell"},                   -- interrupt
      {id=369536, name="Verdant Embrace"},         -- leap to ally
      {id=368432, name="Hover"},                   -- movement
      {id=362969, name="Rescue"},                  -- ally reposition
      {id=373861, name="Mass Dispel Magic (Oppressing Roar synergy)"}, -- note
      {id=360995, name="Source of Magic"},         -- mana funnel
    },
  },

  -- ======================================================================
  --  RACIAL ABILITIES & SPECIAL SPELLS (Cross-Class)
  -- ======================================================================
  RACIAL = {
    CC = {
      {id=20549,  name="War Stomp"},               -- Tauren racial stun
      {id=255723, name="Bull Rush"},               -- Highmountain Tauren stun
      {id=287712, name="Haymaker"},                -- Kul Tiran stun
      {id=107079, name="Quaking Palm"},            -- Pandaren incapacitate
    },
    DEF = {
      {id=377360, name="Precognition"},            -- CRITICAL (priority 11) - immunity to CC
    },
    UTIL = {
      {id=118358, name="Drink"},                   -- CRITICAL (priority 12) - drinking
    },
  },

}

-- ======================================================================
--  Build flat spell lookup tables for fast checking
-- ======================================================================
function AC:BuildAuraLookupTables()
    -- Create fast lookup tables for each category
    self.AuraLookup = {
        CC = {},
        DEF = {},
        UTIL = {},
        AllSpells = {}  -- Combined lookup for any tracked spell
    }
    
    -- Build lookup tables from ClassSpellDB
    for className, categories in pairs(self.ClassSpellDB) do
        for categoryName, spells in pairs(categories) do
            local lookupTable = self.AuraLookup[categoryName]
            if lookupTable then
                for _, spell in ipairs(spells) do
                    lookupTable[spell.id] = {
                        name = spell.name,
                        class = className,
                        category = categoryName
                    }
                    -- Also add to combined lookup
                    self.AuraLookup.AllSpells[spell.id] = {
                        name = spell.name,
                        class = className,
                        category = categoryName
                    }
                end
            end
        end
    end
    
    -- DEBUG: Aura lookup tables built
    -- print("|cff8B45FFArena Core:|r Aura lookup tables built - " ..
    --       "CC: " .. self:CountTable(self.AuraLookup.CC) ..
    --       ", DEF: " .. self:CountTable(self.AuraLookup.DEF) ..
    --       ", UTIL: " .. self:CountTable(self.AuraLookup.UTIL))
end

-- Helper to count table entries
function AC:CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- Check if a spell should be tracked based on enabled categories
function AC:ShouldTrackAura(spellID)
    if not self.AuraLookup or not self.AuraLookup.AllSpells then
        return false
    end
    
    local spellData = self.AuraLookup.AllSpells[spellID]
    if not spellData then
        return false
    end
    
    -- Check if the category is enabled in settings
    local db = self.DB and self.DB.profile and self.DB.profile.moreGoodies and self.DB.profile.moreGoodies.auras
    if not db or not db.enabled then
        return false
    end
    
    -- Check category-specific settings
    if spellData.category == "CC" and db.crowdControl then
        return true
    elseif spellData.category == "DEF" and db.defensive then
        return true
    elseif spellData.category == "UTIL" and db.utility then
        return true
    end
    
    return false
end

-- Initialize lookup tables when addon loads
C_Timer.After(0.5, function()
    if AC and AC.BuildAuraLookupTables then
        AC:BuildAuraLookupTables()
    end
end)

-- DEBUG: Class Spell Database loaded
-- print("|cff8B45FFArena Core:|r Class Spell Database loaded")
