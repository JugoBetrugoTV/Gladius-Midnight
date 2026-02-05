-- Core/AuraTracker.lua --
-- Aura Tracking System for Arena Frames
local AC = _G.ArenaCore
if not AC then return end

-- Aura tracking module
AC.AuraTracker = {}
local AuraTracker = AC.AuraTracker

-- Storage for aura frames and data
AuraTracker.auraFrames = {}
AuraTracker.activeAuras = {}
AuraTracker.combatLogAuras = {} -- CRITICAL: Store combat log auras separately (kicks, Deep Breath, etc.)
AuraTracker.testMode = false

-- Aura categories and spells
AuraTracker.auraCategories = {
    interrupt = {
        priority = 150, -- Highest priority - interrupts are critical to track
        spells = {
            -- Death Knight
            [47528] = true,   -- Mind Freeze
            [91802] = true,   -- Shambling Rush (Unholy pet)
            [91807] = true,   -- Shambling Rush (alternate)
            
            -- Demon Hunter
            [183752] = true,  -- Disrupt
            
            -- Druid
            [93985] = true,   -- Skull Bash
            [106839] = true,  -- Skull Bash (alternate)
            
            -- Evoker
            [351338] = true,  -- Quell
            
            -- Hunter
            [147362] = true,  -- Counter Shot (Beast Mastery/Marksmanship)
            [187707] = true,  -- Muzzle (Survival)
            
            -- Mage
            [2139] = true,    -- Counterspell
            
            -- Monk
            [116705] = true,  -- Spear Hand Strike
            
            -- Paladin
            [96231] = true,   -- Rebuke
            
            -- Priest
            [15487] = true,   -- Silence (Shadow)
            [32375] = true,   -- Mass Dispel (can interrupt channeled spells)
            
            -- Rogue
            [1766] = true,    -- Kick
            
            -- Shaman
            [57994] = true,   -- Wind Shear
            
            -- Warlock
            [19647] = true,   -- Spell Lock (Felhunter)
            [115781] = true,  -- Optical Blast (Observer)
            [119911] = true,  -- Optical Blast (alternate)
            [171138] = true,  -- Shadow Lock (Doomguard)
            [132409] = true,  -- Spell Lock (Command Demon)
            
            -- Warrior
            [6552] = true,    -- Pummel
        }
    },
    crowdControl = {
        priority = 100,
        spells = {
            -- HIGH PRIORITY CC
            [118358] = true,  -- Drink (priority 12 - CRITICAL to track)
            -- NOTE: Precognition (377360) moved to defensive category with priority 140
            
            -- Stuns
            [33786] = true,   -- Cyclone
            [5211] = true,    -- Mighty Bash
            [853] = true,     -- Hammer of Justice
            [408] = true,     -- Kidney Shot
            [1833] = true,    -- Cheap Shot
            [118905] = true,  -- Static Charge (Capacitor Totem)
            [179057] = true,  -- Chaos Nova
            [132169] = true,  -- Storm Bolt
            [30283] = true,   -- Shadowfury
            [91797] = true,   -- Monstrous Blow
            [108194] = true,  -- Asphyxiate (Unholy)
            [221562] = true,  -- Asphyxiate (Blood)
            [119381] = true,  -- Leg Sweep
            [89766] = true,   -- Axe Toss
            [24394] = true,   -- Intimidation
            [117526] = true,  -- Binding Shot
            [211881] = true,  -- Fel Eruption
            [91800] = true,   -- Gnaw
            [305485] = true,  -- Lightning Lasso (ADDED - was missing)
            [46968] = true,   -- Shockwave
            [132168] = true,  -- Shockwave (Protection)
            [255941] = true,  -- Wake of Ashes
            [64044] = true,   -- Psychic Horror
            [200200] = true,  -- Holy Word: Chastise Censure
            [20549] = true,   -- War Stomp (Tauren Racial)
            [255723] = true,  -- Bull Rush (Highmountain Tauren Racial)
            [287712] = true,  -- Haymaker (Kul Tiran Racial)
            [202346] = true,  -- Double Barrel
            [385954] = true,  -- Shield Charge
            [199085] = true,  -- Warpath
            [171017] = true,  -- Meteor Strike (Infernal)
            [171018] = true,  -- Meteor Strike (Abyssal)
            [118345] = true,  -- Pulverize (Earth Elemental)
            
            -- Incapacitates
            [118] = true,     -- Polymorph
            [28271] = true,   -- Polymorph (Turtle)
            [28272] = true,   -- Polymorph (Pig)
            [61025] = true,   -- Polymorph (Snake)
            [61305] = true,   -- Polymorph (Black Cat)
            [61780] = true,   -- Polymorph (Turkey)
            [61721] = true,   -- Polymorph (Rabbit)
            [126819] = true,  -- Polymorph (Porcupine)
            [161353] = true,  -- Polymorph (Polar Bear)
            [161354] = true,  -- Polymorph (Monkey)
            [161355] = true,  -- Polymorph (Penguin)
            [161372] = true,  -- Polymorph (Peacock)
            [277787] = true,  -- Polymorph (Direhorn)
            [277792] = true,  -- Polymorph (Bumblebee)
            [321395] = true,  -- Polymorph (Mawrat)
            [391622] = true,  -- Polymorph (Duck)
            [82691] = true,   -- Ring of Frost
            [3355] = true,    -- Freezing Trap
            [203337] = true,  -- Freezing Trap (Honor Talent)
            [213691] = true,  -- Scatter Shot
            [217832] = true,  -- Imprison
            [221527] = true,  -- Imprison (Honor Talent)
            [2637] = true,    -- Hibernate
            [99] = true,      -- Incapacitating Roar
            [115078] = true,  -- Paralysis
            [20066] = true,   -- Repentance
            [9484] = true,    -- Shackle Undead
            [200196] = true,  -- Holy Word: Chastise
            [1776] = true,    -- Gouge
            [6770] = true,    -- Sap
            [51514] = true,   -- Hex
            [196942] = true,  -- Hex (Voodoo Totem)
            [210873] = true,  -- Hex (Raptor)
            [211004] = true,  -- Hex (Spider)
            [211010] = true,  -- Hex (Snake)
            [211015] = true,  -- Hex (Cockroach)
            [269352] = true,  -- Hex (Skeletal Hatchling)
            [277778] = true,  -- Hex (Zandalari)
            [277784] = true,  -- Hex (Wicker Mongrel)
            [710] = true,     -- Banish
            [6789] = true,    -- Mortal Coil
            [107079] = true,  -- Quaking Palm (Pandaren Racial)
            
            -- Disorients
            [207167] = true,  -- Blinding Sleet
            [207685] = true,  -- Sigil of Misery
            [31661] = true,   -- Dragon's Breath
            [198909] = true,  -- Song of Chi-ji
            [105421] = true,  -- Blinding Light
            [8122] = true,    -- Psychic Scream
            [2094] = true,    -- Blind
            [5484] = true,    -- Howl of Terror
            [118699] = true,  -- Fear
            [5246] = true,    -- Intimidating Shout
            [360806] = true,  -- Sleep Walk (Evoker - priority 10)
            [357210] = true,  -- Deep Breath (Evoker - 4 second stun, priority 11)
            [433874] = true,  -- Deep Breath (alternate ID)
            [371032] = true,  -- Terror of the Skies (Deep Breath DEBUFF - the actual aura applied!)
            
            -- Incapacitates (HIGH PRIORITY)
            [3355] = true,    -- Freezing Trap (priority 10)
            [217832] = true,  -- Imprison (DH - priority 10)
            [221527] = true,  -- Imprison (Honor Talent)
            [107079] = true,  -- Quaking Palm (Pandaren - priority 10)
            
            -- Stuns (HIGH PRIORITY)
            [203123] = true,  -- Maim (Druid - priority 10)
            [5211] = true,    -- Mighty Bash (Druid - priority 10) - ALREADY EXISTS but noting priority
            [163505] = true,  -- Rake (Druid stun - priority 10)
            [383121] = true,  -- Mass Polymorph (Mage - priority 10)
            
            -- Silences
            [47476] = true,   -- Strangulate (DK)
            [204490] = true,  -- Sigil of Silence (DH)
            [15487] = true,   -- Silence (Priest)
            [1330] = true,    -- Garrote (Rogue)
            [196364] = true,  -- Unstable Affliction Silence
            
            -- Roots
            [339] = true,     -- Entangling Roots
            [122] = true,     -- Frost Nova
            [33395] = true,   -- Freeze (Mage Pet)
            [116706] = true,  -- Disable (Monk)
            [64695] = true,   -- Earthgrab (Shaman Totem)
            [162480] = true,  -- Steel Trap (Hunter)
            [212638] = true,  -- Tracker's Net (Hunter)
            [355689] = true,  -- Landslide (Evoker aura - priority 5)
            [102359] = true,  -- Mass Entanglement (Druid)
            
            -- Additional CC Auras
            [81261] = true,   -- Solar Beam (Druid aura - priority 8)
            [97547] = true,   -- Solar Beam (alternate)
            [203123] = true,  -- Maim (Druid aura - priority 10)
            [61391] = true,   -- Typhoon (Druid aura)
            [127797] = true,  -- Ursol's Vortex (Druid aura)
            [209426] = true,  -- Darkness (DH aura - priority 3)
            [221527] = true,  -- Imprison (DH aura)
            [109248] = true,  -- Binding Shot (Hunter aura)
            [186387] = true,  -- Bursting Shot (Hunter aura)
            [212792] = true,  -- Cone of Cold (Mage aura - priority 1)
            [353082] = true,  -- Ring of Fire (Mage aura)
            [353084] = true,  -- Ring of Fire (Mage aura alternate)
            [124488] = true,  -- Zen Focus (Monk aura - priority 7)
            [372245] = true,  -- Terror of the Skies (Evoker aura - priority 9)
            
            -- Hunter Debuffs
            [451517] = true,  -- Catch Out (Hunter - priority 5)
            [61685] = true,   -- Charge (Hunter pet - priority 5)
            [5116] = true,    -- Concussive Shot (Hunter - priority 1)
            [260402] = true,  -- Double Tap (Hunter - priority 4)
            [393456] = true,  -- Entrapment (Hunter - priority 5)
            [54216] = true,   -- Master's Call (Hunter aura - priority 2)
            [118922] = true,  -- Posthaste (Hunter - priority 0)
            [356723] = true,  -- Scorpid Venom (Hunter - priority 1)
            [356727] = true,  -- Spider Venom (Hunter - priority 8)
            [202748] = true,  -- Survival Tactics (Hunter - priority 7)
            [407032] = true,  -- Sticky Tar Bomb (Hunter aura - priority 8)
            [248519] = true,  -- Interlope (Hunter pet - priority 3)
            
            -- Priest Mind Control
            [605] = true,     -- Mind Control (Priest - priority 10)
            
            -- Mage Additional
            [48108] = true,   -- Hot Streak! (Mage Fire - priority 2)
            [44544] = true,   -- Fingers of Frost (Mage Frost - priority 2)
            [389831] = true,  -- Snowdrift (Mage Frost aura - priority 9)
            
            -- Warlock Fear Variants
            [118699] = true,  -- Fear (Warlock)
            [130616] = true,  -- Fear (Warlock alternate)
            [6358] = true,    -- Seduction (Succubus)
            
            -- Rogue Additional
            [1833] = true,    -- Cheap Shot (already exists but confirming)
            
            -- Shaman Additional  
            [51490] = true,   -- Thunderstorm (Shaman knockback)
            
            -- Warrior Additional
            [107570] = true,  -- Storm Bolt (Warrior - priority 9)
            [5246] = true,    -- Intimidating Shout (Warrior - priority 9)
        }
    },
    highPriorityDefensive = {
        priority = 160,  -- HIGHEST PRIORITY - Precognition is critical to track (above interrupts at 150)
        spells = {
            -- CRITICAL: Precognition (immunity to CC) - MUST show above everything
            [377360] = true,  -- Precognition - PvP talent (base spell ID)
            [377362] = true,  -- Precognition - PvP talent (buff ID that appears on players)
        }
    },
    defensive = {
        priority = 50,
        spells = {
            
            -- Major Immunities
            [45438] = true,   -- Ice Block
            [642] = true,     -- Divine Shield
            [186265] = true,  -- Aspect of the Turtle
            [31224] = true,   -- Cloak of Shadows
            [47585] = true,   -- Dispersion
            [196555] = true,  -- Netherwalk (DH)
            
            -- Major Damage Reductions
            [48792] = true,   -- Icebound Fortitude
            [871] = true,     -- Shield Wall
            [118038] = true,  -- Die by the Sword
            [104773] = true,  -- Unending Resolve
            [23920] = true,   -- Spell Reflection
            [48707] = true,   -- Anti-Magic Shell
            [122783] = true,  -- Diffuse Magic (Monk)
            [122278] = true,  -- Dampen Harm (Monk)
            [125174] = true,  -- Touch of Karma (Monk)
            [22812] = true,   -- Barkskin (Druid)
            [61336] = true,   -- Survival Instincts (Druid)
            [102342] = true,  -- Ironbark (Druid)
            [1022] = true,    -- Blessing of Protection
            [6940] = true,    -- Blessing of Sacrifice
            [204018] = true,  -- Blessing of Spellwarding
            [198589] = true,  -- Blur (DH)
            [212800] = true,  -- Blur (DH aura)
            [196718] = true,  -- Darkness (DH)
            [363916] = true,  -- Obsidian Scales (Evoker)
            [374348] = true,  -- Renewing Blaze (Evoker)
            [378441] = true,  -- Time Stop (Evoker - priority 11)
            [378464] = true,  -- Nullifying Shroud (Evoker - priority 11)
            
            -- Death Knight
            [48707] = true,   -- Anti-Magic Shell (priority 11)
            [410358] = true,  -- Anti-Magic Shell (alternate)
            
            -- Demon Hunter
            [196555] = true,  -- Netherwalk (priority 11)
            [354610] = true,  -- Glimpse (priority 11)
            
            -- Druid
            [473909] = true,  -- Ancient of Lore (Resto - priority 11)
            
            -- Hunter
            [186265] = true,  -- Aspect of the Turtle (priority 11)
            [19263] = true,   -- Deterrence (Hunter - legacy)
            [5277] = true,    -- Evasion (Rogue)
            [1966] = true,    -- Feint (Rogue)
            [199754] = true,  -- Riposte (Rogue)
            [108271] = true,  -- Astral Shift (Shaman)
            [98008] = true,   -- Spirit Link Totem (Shaman)
            [33206] = true,   -- Pain Suppression (Priest)
            [47788] = true,   -- Guardian Spirit (Priest)
            [27827] = true,   -- Spirit of Redemption (Priest - priority 11)
            [213610] = true,  -- Holy Ward (Priest)
            [108968] = true,  -- Void Shift (Priest)
            [353319] = true,  -- Peaceweaver (Monk - priority 11)
            [116849] = true,  -- Life Cocoon (Monk - priority 3)
            [122470] = true,  -- Touch of Karma (Monk - priority 3)
            [115203] = true,  -- Fortifying Brew (Monk - priority 2)
            [264735] = true,  -- Survival of the Fittest (Hunter - priority 3)
            [53480] = true,   -- Roar of Sacrifice (Hunter - priority 3)
            [110959] = true,  -- Greater Invisibility (Mage - priority 3)
            [113862] = true,  -- Greater Invisibility (Mage aura - priority 4)
            [342245] = true,  -- Alter Time (Mage - priority 3)
            [342246] = true,  -- Alter Time (Mage aura - priority 3)
            [235219] = true,  -- Cold Snap (Mage Frost - priority 12)
            [115310] = true,  -- Revival (Monk Mistweaver - priority 5)
            [388615] = true,  -- Restoral (Monk Mistweaver - priority 4)
            [102342] = true,  -- Ironbark (Druid Resto - priority 3)
            [33891] = true,   -- Incarnation: Tree of Life (Druid Resto - priority 6)
            [197721] = true,  -- Flourish (Druid Resto - priority 3)
            [370960] = true,  -- Emerald Communion (Evoker Preservation - priority 3)
            [359816] = true,  -- Dream Flight (Evoker Preservation - priority 3)
            [357170] = true,  -- Time Dilation (Evoker Preservation - priority 3)
        }
    },
    utility = {
        priority = 25,
        spells = {
            [6940] = true,    -- Blessing of Sacrifice
            [114050] = true,  -- Ascendance
            [108271] = true,  -- Astral Shift
            [1966] = true,    -- Feint
            [5277] = true,    -- Evasion
            [110909] = true,  -- Alter Time
            [212295] = true,  -- Nether Ward
            [48707] = true,   -- Anti-Magic Shell
        }
    }
}

-- Blacklist: Spells that should NEVER be tracked (non-PvP utility, raid buffs, etc.)
AuraTracker.blacklistedSpells = {
    [6673] = true,    -- Battle Shout (1-hour raid buff, not relevant for PvP tracking)
    [1160] = true,    -- Demoralizing Shout (long duration, not a key defensive)
    [469] = true,     -- Commanding Shout (long duration raid buff)
    [974] = true,     -- Earth Shield (long duration buff, not a key PvP defensive)
    [61295] = true,   -- Riptide (short HoT, not a major defensive)
    [77130] = true,   -- Purify Spirit (utility dispel, not a defensive)
    [192077] = true,  -- Wind Rush Totem (movement buff, not defensive)
    [16191] = true,   -- Mana Tide Totem (mana regen, not defensive)
    [546] = true,     -- Water Walking (utility, not PvP relevant)
    [131] = true,     -- Water Breathing (utility, not PvP relevant)
    -- Add more non-PvP utility spells here as needed
}

-- Test auras for demonstration (Interrupts/CC/Defensive/Utility)
AuraTracker.testAuras = {
    arena1 = { -- Death Knight
        {spellId = 47528, name = "Mind Freeze", icon = 237527, duration = 4, category = "interrupt"},  -- Interrupt example
    },
    arena2 = { -- Mage
        {spellId = 2139, name = "Counterspell", icon = 135856, duration = 6, category = "interrupt"},  -- Interrupt example
    },
    arena3 = { -- Hunter  
        {spellId = 147362, name = "Counter Shot", icon = 249170, duration = 3, category = "interrupt"},  -- Interrupt example
    }
}

-- Initialize aura tracking
function AuraTracker:Initialize()
    self:CreateEventFrame()
    -- Debug removed: Aura Tracker initialized
end

-- Create event frame for aura tracking
function AuraTracker:CreateEventFrame()
    if self.eventFrame then return end
    
    self.eventFrame = CreateFrame("Frame")
    -- CRITICAL FIX: Use RegisterUnitEvent to filter for arena units only
    -- This prevents unnecessary event spam from player/party/raid auras
    self.eventFrame:RegisterUnitEvent("UNIT_AURA", "arena1", "arena2", "arena3")
    self.eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    self.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE") -- CRITICAL: Clear auras between Solo Shuffle rounds
    -- PHASE 1.1: COMBAT_LOG now handled by centralized system in ArenaCore.lua
    
    self.eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "UNIT_AURA" then
            local unitTarget = ...
            -- Reduced spam: Only log if invalid
            if unitTarget and string.match(unitTarget, "^arena[1-3]$") then
                self:UpdateAuras(unitTarget)
            end
        elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
            -- CRITICAL FIX: Clear auras in prep room (Solo Shuffle fix)
            -- Prep room should have NO auras - they populate when gates open via UNIT_AURA
            -- Matches standard addon behavior (they don't refresh auras in prep room)
            self:ClearAllAuras()
        elseif event == "GROUP_ROSTER_UPDATE" then
            -- CRITICAL: Clear all auras between Solo Shuffle rounds (like trinkets/racials)
            self:ClearAllAuras()
        end
        -- PHASE 1.1: COMBAT_LOG handling moved to ProcessCombatLogEvent (called by centralized handler)
    end)
end

-- Update auras for a specific unit
function AuraTracker:UpdateAuras(unit)
    -- Midnight compatibility: Disable aura tracking in Midnight due to API restrictions
    -- ClassIconAuras module handles CC display in Midnight instead
    if AC.Midnight and AC.Midnight.isMidnight then
        return
    end
    
    if not self:IsEnabled() then 
        return 
    end
    if not unit or not string.match(unit, "^arena[1-3]$") then 
        return 
    end
    
    -- print("|cff00FFFF[AuraTracker]|r UpdateAuras called for " .. unit .. " (testMode: " .. tostring(self.testMode) .. ")")
    
    -- Clear existing auras for this unit
    self.activeAuras[unit] = {}
    
    if self.testMode then
        self:UpdateTestAuras(unit)
        return
    end
    
    -- Get enabled categories
    local settings = self:GetSettings()
    
    -- Scan for debuffs (HARMFUL) - TWW API
    local debuffCount = 0
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetDebuffDataByIndex(unit, i)
        if not auraData then break end
        
        debuffCount = debuffCount + 1
        local name, icon, count, dispelType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellId = auraData.name, auraData.icon, auraData.applications, 
              auraData.dispelName, auraData.duration, auraData.expirationTime, auraData.sourceUnit, 
              auraData.isStealable, auraData.nameplateShowPersonal, auraData.spellId
        
        -- Skip blacklisted spells (non-PvP utility, raid buffs, etc.)
        if not self.blacklistedSpells[spellId] then
            local category, priority = self:GetSpellCategoryAndPriority(spellId)
            
            -- PHASE 2 DEBUG: Log Deep Breath detection
            if spellId == 357210 or spellId == 433874 or spellId == 371032 then
                print("|cff00FF00[AuraTracker]|r PHASE 2: Deep Breath DEBUFF found on " .. unit .. "! SpellID: " .. spellId .. ", Name: " .. name .. ", Category: " .. tostring(category) .. ", Priority: " .. tostring(priority))
            end
            
            if category and settings[category] ~= false then
                -- print("|cff00FF00[AuraTracker]|r Found DEBUFF: " .. name .. " (" .. spellId .. ") - Category: " .. category .. ", Priority: " .. priority)
                table.insert(self.activeAuras[unit], {
                    spellId = spellId,
                    name = name,
                    icon = icon,
                    count = count,
                    duration = duration,
                    expirationTime = expirationTime,
                    priority = priority,
                    category = category,
                    isDebuff = true
                })
            else
                if category then
                    -- print("|cffFFAA00[AuraTracker]|r Skipping debuff " .. name .. " - Category " .. category .. " is disabled")
                end
            end
        end
    end
    -- print("|cff00FFFF[AuraTracker]|r Scanned " .. debuffCount .. " debuffs on " .. unit)
    
    -- Scan for buffs (HELPFUL) - TWW API
    local buffCount = 0
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetBuffDataByIndex(unit, i)
        if not auraData then break end
        
        buffCount = buffCount + 1
        local name, icon, count, dispelType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellId = auraData.name, auraData.icon, auraData.applications, 
              auraData.dispelName, auraData.duration, auraData.expirationTime, auraData.sourceUnit, 
              auraData.isStealable, auraData.nameplateShowPersonal, auraData.spellId
        
        -- Skip blacklisted spells (non-PvP utility, raid buffs, etc.)
        if not self.blacklistedSpells[spellId] then
            local category, priority = self:GetSpellCategoryAndPriority(spellId)
            
            -- DEBUG: Log Precognition detection
            if spellId == 377360 then
                print("|cffFF00FF[AuraTracker PRECOGNITION]|r DETECTED on " .. unit .. "!")
                print("  Category: " .. tostring(category))
                print("  Priority: " .. tostring(priority))
                print("  Setting enabled: " .. tostring(settings[category] ~= false))
                print("  Name: " .. tostring(name))
                print("  Icon: " .. tostring(icon))
                print("  Duration: " .. tostring(duration))
                print("  Will be tracked: " .. tostring(settings[category] ~= false))
            end
            
            if category and settings[category] ~= false then
                -- print("|cff00FF00[AuraTracker]|r Found BUFF: " .. name .. " (" .. spellId .. ") - Category: " .. category .. ", Priority: " .. priority)
                table.insert(self.activeAuras[unit], {
                    spellId = spellId,
                    name = name,
                    icon = icon,
                    count = count,
                    duration = duration,
                    expirationTime = expirationTime,
                    priority = priority,
                    category = category,
                    isDebuff = false
                })
            else
                if category then
                    -- print("|cffFFAA00[AuraTracker]|r Skipping buff " .. name .. " - Category " .. category .. " is disabled")
                end
            end
        end
    end
    -- print("|cff00FFFF[AuraTracker]|r Scanned " .. buffCount .. " buffs on " .. unit)
    
    -- Sort by priority (highest first) BEFORE checking combat log auras
    table.sort(self.activeAuras[unit], function(a, b)
        return a.priority > b.priority
    end)
    
    -- CRITICAL FIX: Check combat log aura AFTER scanning regular auras
    -- If combat log aura has higher priority OR no regular aura exists, use combat log aura
    local combatLogAura = self.combatLogAuras[unit]
    local topAura = self.activeAuras[unit][1] -- Highest priority regular aura (or nil)
    
    if combatLogAura and combatLogAura.expirationTime and combatLogAura.expirationTime > GetTime() then
        -- Combat log aura is still valid
        if (topAura and topAura.priority < combatLogAura.priority) or (not topAura) then
            -- Combat log aura wins! Either higher priority or no regular aura exists
            -- Replace entire list with just combat log aura
            self.activeAuras[unit] = {combatLogAura}
        end
    end
    
    -- Update display
    self:UpdateAuraDisplay(unit)
end

--- PHASE 1.1: Process combat log events (called by centralized handler)
--- @param timestamp number
--- @param combatEvent string
--- @param sourceGUID string
--- @param destGUID string
--- @param spellID number
function AuraTracker:ProcessCombatLogEvent(timestamp, combatEvent, sourceGUID, destGUID, spellID)
    if not self:IsEnabled() then return end
    if self.testMode then return end -- Don't process combat log in test mode
    
    -- PHASE 2: Deep Breath removed from combat log tracking
    -- Deep Breath (357210, 433874, 371032) is now tracked via UNIT_AURA scanning
    -- The debuff appears on victims and will be found by ScanAuras function
    
    -- Track SPELL_INTERRUPT (successful interrupts) only
    -- PHASE 1 FIX: Handle interrupt tracking
    -- - SPELL_INTERRUPT: For interrupts on casts
    -- - SPELL_CAST_SUCCESS: For interrupts on channels (with channel check)
    if combatEvent ~= "SPELL_INTERRUPT" and combatEvent ~= "SPELL_CAST_SUCCESS" then return end
    
    -- Check if this spell is tracked by AuraTracker FIRST
    local category, priority = self:GetSpellCategoryAndPriority(spellID)
    if not category then 
        return 
    end
    
    -- PHASE 1 FIX: Handle interrupt tracking
    -- Accept BOTH SPELL_INTERRUPT (for casts) and SPELL_CAST_SUCCESS (for channels)
    if category == "interrupt" then
        if combatEvent == "SPELL_INTERRUPT" then
            -- Always accept SPELL_INTERRUPT (successful interrupt on cast)
        elseif combatEvent == "SPELL_CAST_SUCCESS" then
            -- For SPELL_CAST_SUCCESS, check if victim is channeling
            -- We need to find the unit first to check if they're channeling
            local targetUnit = nil
            for i = 1, 3 do
                local arenaUnit = "arena" .. i
                if UnitGUID(arenaUnit) == destGUID then
                    targetUnit = arenaUnit
                    break
                end
            end
            
            if targetUnit then
                local _, _, _, _, _, _, notInterruptibleChannel = UnitChannelInfo(targetUnit)
                if notInterruptibleChannel == false then
                    -- Victim is channeling an interruptible spell - accept this interrupt
                else
                    -- Victim is not channeling or channel is not interruptible - reject
                    return
                end
            else
                -- Could not find target unit - reject
                return
            end
        else
            -- Not SPELL_INTERRUPT or SPELL_CAST_SUCCESS - reject
            return
        end
    end
    
    -- PHASE 1 FIX: Simplified tracking logic
    -- 
    -- INTERRUPTS: Track via combat log (VICTIM = destGUID)
    --   - Shows on enemy frame when YOU/TEAMMATES kick them
    --   - Example: You kick arena1 → icon shows on arena1's frame
    --
    -- EVERYTHING ELSE (CC, defensives, etc.): Track via UNIT_AURA scanning
    --   - If it's not an interrupt, we shouldn't be in combat log tracking
    --
    local unit = nil
    
    -- For interrupts, ALWAYS track the VICTIM (destGUID)
    if category == "interrupt" then
        for i = 1, 3 do
            local arenaUnit = "arena" .. i
            if UnitGUID(arenaUnit) == destGUID then
                unit = arenaUnit
                break
            end
        end
    else
        -- Non-interrupt spells should NOT be tracked via combat log
        -- They will be handled by UNIT_AURA scanning instead
        return
    end
    
    if not unit then 
        return
    end
    
    -- Check if category is enabled
    local settings = self:GetSettings()
    if settings[category] == false then return end
    
    -- Get spell info
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo then return end
    
    -- CRITICAL: Get actual spell duration from game data
    -- This ensures interrupt/CC durations match reality (Counterspell 6s, Kick 5s, etc.)
    local displayDuration = 3 -- Default fallback
    
    -- Interrupt durations (lockout time) - CRITICAL for PvP awareness
    local interruptDurations = {
        -- Standard interrupts (4-5 seconds)
        [1766] = 5,      -- Kick (Rogue)
        [2139] = 6,      -- Counterspell (Mage) - LONGEST
        [57994] = 3,     -- Wind Shear (Shaman) - SHORTEST
        [6552] = 4,      -- Pummel (Warrior)
        [116705] = 4,    -- Spear Hand Strike (Monk)
        [96231] = 4,     -- Rebuke (Paladin)
        [47528] = 4,     -- Mind Freeze (DK)
        [187707] = 4,    -- Muzzle (Hunter)
        [106839] = 4,    -- Skull Bash (Druid)
        [183752] = 3,    -- Disrupt (DH)
        [19647] = 6,     -- Spell Lock (Felhunter) - LONG
        [119910] = 6,    -- Spell Lock (Command Demon: Felhunter)
        [132409] = 6,    -- Spell Lock (Command Demon)
        [115781] = 6,    -- Optical Blast (Observer)
        [132409] = 6,    -- Spell Lock (Command Demon)
        [147362] = 3,    -- Counter Shot (Hunter)
        [351338] = 4,    -- Quell (Evoker)
        [31935] = 3,     -- Avenger's Shield (Paladin)
        
        -- Silences (longer duration)
        [15487] = 4,     -- Silence (Priest)
        [1330] = 3,      -- Garrote - Silence (Rogue)
        [47476] = 5,     -- Strangulate (DK)
        [204490] = 6,    -- Sigil of Silence (DH)
        
        -- Special CC durations
        [357210] = 4,    -- Deep Breath (Evoker) - 4 second stun
        [433874] = 4,    -- Deep Breath (alternate ID)
        [371032] = 4,    -- Terror of the Skies (Deep Breath DEBUFF - the actual aura!)
    }
    
    -- Check if this is an interrupt/CC with known duration
    if interruptDurations[spellID] then
        displayDuration = interruptDurations[spellID]
    else
        -- Try to get duration from C_Spell API (works for some spells)
        local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)
        if spellCooldownInfo and spellCooldownInfo.duration and spellCooldownInfo.duration > 0 and spellCooldownInfo.duration < 30 then
            -- If spell has a short duration (< 30s), use it as display duration
            displayDuration = spellCooldownInfo.duration
        end
    end
    
    local expirationTime = GetTime() + displayDuration
    
    -- CRITICAL FIX: Store combat log aura separately
    -- This prevents it from being overwritten by UNIT_AURA scans
    self.combatLogAuras[unit] = {
        spellId = spellID,
        name = spellInfo.name,
        icon = spellInfo.iconID,
        count = 0,
        duration = displayDuration,
        expirationTime = expirationTime,
        priority = priority,
        category = category,
        isDebuff = false,
        isCastEvent = true -- Mark as cast event for potential special handling
    }
    
    -- Trigger aura update to check if combat log aura should display
    self:UpdateAuras(unit)
    
    -- CRITICAL FIX: Send chat announcement for interrupts
    if category == "interrupt" then
        self:AnnounceInterrupt(unit, spellInfo.name, displayDuration)
    end
    
    -- CRITICAL: Schedule cleanup of combat log aura after expiration
    -- Check if interrupt aura is still valid by comparing GetTime()
    C_Timer.After(displayDuration + 0.1, function()
        -- Clear combat log aura if it's expired
        if self.combatLogAuras[unit] and self.combatLogAuras[unit].expirationTime <= GetTime() then
            -- DEBUG: print("|cffFFAA00[AuraTracker]|r Combat log aura expired for " .. unit)
            self.combatLogAuras[unit] = nil
            -- Trigger update to show next priority aura
            self:UpdateAuras(unit)
        end
    end)
end

-- CRITICAL FIX: Announce interrupts in chat
function AuraTracker:AnnounceInterrupt(unit, spellName, duration)
    -- Check if chat messages are enabled in More Features
    local db = AC.DB and AC.DB.profile
    local chatMessagesEnabled = db and db.moreFeatures and db.moreFeatures.chatMessagesEnabled
    
    -- Default to true if setting doesn't exist yet
    if chatMessagesEnabled == nil then
        chatMessagesEnabled = true
    end
    
    -- CRITICAL FIX: Exit early if chat messages are disabled
    if not chatMessagesEnabled then return end
    
    -- Get unit info
    local unitName = UnitName(unit) or unit
    local _, className = UnitClass(unit)
    local classColor = className and RAID_CLASS_COLORS[className] or {r = 1, g = 1, b = 1}
    
    -- Format message with class color
    local colorCode = string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
    local msg = string.format("INTERRUPTED: %s%s|r (%s) - %ds lockout", colorCode, unitName, spellName, duration)
    
    -- Determine destination (instance chat for skirmish/unrated, party for rated)
    local dest = "INSTANCE_CHAT"
    local isArena, isRegistered = IsActiveBattlefieldArena()
    if isRegistered then
        -- Rated arena - use party chat
        dest = "PARTY"
    end
    
    -- Send to chat
    if GetNumGroupMembers() > 0 then
        SendChatMessage(msg, dest)
    else
        -- Solo testing - print to chat frame
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ArenaCore|r: " .. msg)
    end
    
    -- Also print to local chat for visibility
    print("|cff33ff99ArenaCore|r: " .. msg)
end

-- Update test auras
function AuraTracker:UpdateTestAuras(unit)
    if not self.testAuras[unit] then 
        -- DEBUG: No test auras defined
        -- print("|cffFF0000[AuraTracker]|r No test auras defined for " .. unit)
        return 
    end
    
    -- DEBUG: UpdateTestAuras
    -- print("|cff00FFFF[AuraTracker]|r UpdateTestAuras for " .. unit)
    
    local settings = self:GetSettings()
    -- DEBUG: Settings check
    -- print("|cffFFFF00[AuraTracker]|r Settings: enabled=" .. tostring(settings.enabled) .. ", defensive=" .. tostring(settings.defensive) .. ", crowdControl=" .. tostring(settings.crowdControl))
    
    self.activeAuras[unit] = {}
    
    local auraCount = 0
    for _, aura in ipairs(self.testAuras[unit]) do
        -- DEBUG: Checking aura
        -- print("|cffFFFF00[AuraTracker]|r Checking aura: " .. aura.name .. " (category: " .. aura.category .. ") - Enabled: " .. tostring(settings[aura.category] ~= false))
        -- CRITICAL: In test mode, show ALL auras regardless of settings (for preview)
        -- In live mode, respect category settings
        local shouldShow = self.testMode or (settings[aura.category] ~= false)
        if shouldShow then
            auraCount = auraCount + 1
            local priority = self.auraCategories[aura.category].priority
            table.insert(self.activeAuras[unit], {
                spellId = aura.spellId,
                name = aura.name,
                icon = aura.icon,
                count = 1,
                duration = aura.duration,
                expirationTime = GetTime() + aura.duration,
                priority = priority,
                category = aura.category,
                isDebuff = false,
                isTest = true
            })
            -- DEBUG: Added test aura
            -- print("|cff00FF00[AuraTracker]|r Added test aura: " .. aura.name .. " (icon: " .. aura.icon .. ")")
        end
    end
    
    -- DEBUG: Total auras added
    -- print("|cff00FFFF[AuraTracker]|r Total auras added for " .. unit .. ": " .. auraCount)
    
    -- Sort by priority
    table.sort(self.activeAuras[unit], function(a, b)
        return a.priority > b.priority
    end)
    
    self:UpdateAuraDisplay(unit)
end

-- Update aura display on arena frames
function AuraTracker:UpdateAuraDisplay(unit)
    -- print("|cff00FFFF[AuraTracker]|r UpdateAuraDisplay called for " .. unit)
    
    local auraFrame = self.auraFrames[unit]
    if not auraFrame then
        -- CRITICAL: Do NOT create frames during combat - this causes taint!
        -- Frames must be pre-created before combat starts
        if InCombatLockdown() then
            -- Silently skip - frame will be created when combat ends
            return
        end
        
        -- DEBUG: print("|cffFFAA00[AuraTracker]|r No aura frame exists for " .. unit .. ", creating one...")
        self:CreateAuraFrame(unit)
        auraFrame = self.auraFrames[unit]
    end
    
    if not auraFrame then 
        -- Only print error if not in combat (to avoid spam)
        if not InCombatLockdown() then
            print("|cffFF0000[AuraTracker]|r FAILED to create aura frame for " .. unit .. " - Arena frames may not be initialized yet")
        end
        return 
    end
    
    -- print("|cff00FF00[AuraTracker]|r Aura frame found for " .. unit)
    
    local auras = self.activeAuras[unit] or {}
    
    -- DEBUG: UpdateAuraDisplay
    -- print("|cff00FFFF[AuraTracker]|r UpdateAuraDisplay for " .. unit .. " - Auras count: " .. #auras)
    
    -- Show only the highest priority aura (single icon system)
    if #auras > 0 then
        local aura = auras[1] -- Highest priority aura
        -- Already printed in UpdateAuras, no need to spam here
        -- print("|cff00FF00[AuraTracker]|r Displaying aura: " .. aura.name .. " (Priority: " .. aura.priority .. ") on " .. unit)
        local icon = auraFrame.icon
        
        -- DEBUG: Displaying aura
        -- print("|cff00FF00[AuraTracker]|r Displaying aura: " .. (aura.name or "Unknown") .. " on " .. unit)
        
        if icon and aura then
            -- Set the aura texture
            icon.texture:SetTexture(aura.icon)
            -- DEBUG: Set texture
            -- print("|cff00FF00[AuraTracker]|r Set texture to icon: " .. aura.icon)
            
            -- Set up cooldown with continuous animation for test mode
            if aura.isTest then
                -- Show icon first, then start cooldown
                icon:Show()
                icon.cooldown:Show()
                
                -- Store test aura data for cooldown text updates
                icon.auraData = aura
                icon.auraData.expirationTime = GetTime() + aura.duration
                
                -- Start cooldown immediately
                icon.cooldown:SetCooldown(GetTime(), aura.duration)
                
                -- Show cooldown text for test mode
                if icon.cooldownText then
                    icon.cooldownText:Show()
                end
                
                -- Set up continuous cycle for test mode (spiral + text)
                local function StartContinuousCooldown()
                    if icon and self.testMode then
                        local startTime = GetTime()
                        icon.cooldown:SetCooldown(startTime, aura.duration)
                        
                        -- Update aura data for cooldown text
                        icon.auraData.expirationTime = startTime + aura.duration
                        
                        -- Schedule next cycle
                        C_Timer.After(aura.duration + 0.1, function()
                            if icon and self.testMode then
                                StartContinuousCooldown()
                            end
                        end)
                    end
                end
                
                -- Start the continuous cycle after first cooldown
                C_Timer.After(aura.duration + 0.1, function()
                    if icon and self.testMode then
                        StartContinuousCooldown()
                    end
                end)
            elseif aura.duration and aura.duration > 0 and aura.expirationTime then
                -- Live arena mode - use actual aura timing (no auto-reset)
                icon.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
                icon.cooldown:Show()
                
                -- Show cooldown text for live arena
                if icon.cooldownText then
                    icon.cooldownText:Show()
                end
            else
                icon.cooldown:Hide()
                if icon.cooldownText then
                    icon.cooldownText:Hide()
                end
            end
            
            -- Set up count
            if aura.count and aura.count > 1 then
                icon.count:SetText(aura.count)
                icon.count:Show()
            else
                icon.count:Hide()
            end
            
            -- Store aura data for tooltip
            icon.auraData = aura
            
            icon:Show()
        end
    else
        -- Hide icon when no auras (no need to spam this)
        -- print("|cffFFAA00[AuraTracker]|r No auras to display for " .. unit .. ", hiding icon")
        auraFrame.icon:Hide()
    end
end

-- Create aura frame for a unit
function AuraTracker:CreateAuraFrame(unit)
    if self.auraFrames[unit] then 
        -- print("|cffFFFF00[AuraTracker]|r Aura frame already exists for " .. unit .. ", skipping creation")
        return 
    end
    
    -- Find the ArenaCore arena frame for this unit
    local frameNumber = string.match(unit, "%d")
    local arenaFrame = nil
    
    -- NEW SYSTEM: Try to get frame from FrameManager first
    if AC.FrameManager and AC.FrameManager.GetFrames then
        local frames = AC.FrameManager:GetFrames()
        if frames and frames[tonumber(frameNumber)] then
            arenaFrame = frames[tonumber(frameNumber)]
        end
    end
    
    -- NEW SYSTEM: Try global ArenaCore.arenaFrames array
    if not arenaFrame and _G.ArenaCore and _G.ArenaCore.arenaFrames then
        arenaFrame = _G.ArenaCore.arenaFrames[tonumber(frameNumber)]
    end
    
    -- OLD SYSTEM: Try global frame names (backward compatibility)
    if not arenaFrame then
        arenaFrame = _G["ArenaCore_ArenaFrame" .. frameNumber]
    end
    
    -- FALLBACK: Standard Blizzard frames
    if not arenaFrame then 
        arenaFrame = _G["ArenaEnemyFrame" .. frameNumber]
    end
    
    if not arenaFrame then 
        print("|cffFF0000[AuraTracker]|r CRITICAL: Could not find arena frame for " .. unit)
        print("|cffFF0000[AuraTracker]|r Checked: FrameManager.GetFrames(), ArenaCore.arenaFrames, global frame names")
        return 
    end
    
    -- DEBUG: Disabled to reduce chat spam
    -- print("|cff00FF00[AuraTracker]|r Found arena frame for " .. unit)
    
    -- Find the class icon to overlay
    local classIcon = arenaFrame.classIcon
    if not classIcon then 
        print("|cffFF0000[AuraTracker]|r CRITICAL: No classIcon found on frame for " .. unit)
        return 
    end
    
    -- DEBUG: Disabled to reduce chat spam
    -- print("|cff00FF00[AuraTracker]|r Found classIcon for " .. unit .. ", creating aura overlay")
    
    if AC and AC.Debug then 
        -- Found arena frame and class icon
    end
    
    -- Create aura icon that replaces only the class icon texture area (keeps ArenaCore overlay border)
    local icon = CreateFrame("Frame", "ArenaCoreAura_" .. unit, classIcon)
    
    -- Match the class icon's texture region exactly and draw UNDER the overlay border
    local classIconTexture = classIcon.classIcon or classIcon.icon
    
    -- CRITICAL: Function to calculate aura inset based on border thickness setting
    -- This matches the class icon overlay inset calculation exactly
    local function CalculateAuraInset()
        -- Get border thickness percentage from THEME-SPECIFIC settings (80-100%)
        local thicknessPercent = 100
        
        -- Read from theme-specific settings first, fallback to global
        if AC and AC.DB and AC.DB.profile then
            local currentTheme = AC.ArenaFrameThemes and AC.ArenaFrameThemes:GetCurrentTheme()
            local themeData = currentTheme and AC.DB.profile.themeData and AC.DB.profile.themeData[currentTheme]
            
            if themeData and themeData.classIcons and themeData.classIcons.sizing and themeData.classIcons.sizing.borderThickness then
                thicknessPercent = themeData.classIcons.sizing.borderThickness
            elseif AC.DB.profile.classIcons and AC.DB.profile.classIcons.sizing and AC.DB.profile.classIcons.sizing.borderThickness then
                thicknessPercent = AC.DB.profile.classIcons.sizing.borderThickness
            end
        end
        
        -- CRITICAL: Simple inset calculation like The 1500 Special
        -- The aura is anchored to classIconTexture (28x28)
        -- Natural border space from frame-texture difference handles most spacing
        if not classIconTexture then
            return 0 -- Fallback if texture doesn't exist
        end
        
        -- SIMPLIFIED: Use fixed inset values that work for both themes
        -- At 100% thickness: 2px inset (ensures border visibility)
        -- At 80% thickness: 4px inset (shrinks aura further)
        
        -- Calculate inset based on thickness percentage
        -- 100% = 2px, 80% = 4px (linear interpolation)
        local minInset = 2  -- At 100% thickness
        local maxInset = 4  -- At 80% thickness
        
        -- Linear interpolation: as thickness decreases from 100 to 80, inset increases from 2 to 4
        local thicknessRange = 20  -- 100 - 80
        local insetRange = maxInset - minInset  -- 4 - 2 = 2
        local thicknessDelta = 100 - thicknessPercent  -- How far from 100%
        local inset = minInset + (thicknessDelta / thicknessRange) * insetRange
        
        return inset
    end
    
    if classIconTexture then
        -- CRITICAL: Anchor to classIconTexture (28x28), NOT classIcon (36x36)
        -- This is how it worked in the old version before border thickness
        icon:ClearAllPoints()
        icon:SetAllPoints(classIconTexture)
        
        -- CRITICAL FIX (Nov 20, 2025): Set aura frame to SAME level as classIcon (not higher)
        -- This ensures the layer hierarchy is respected: ARTWORK < OVERLAY
        -- If aura frame level is higher than classIcon, it renders above the OVERLAY border
        -- By keeping it at the same level, the OVERLAY layer on classIcon renders on top
        icon:SetFrameLevel(classIcon:GetFrameLevel())
    else
        -- Fallback: Center with fixed size to stay inside border
        icon:SetPoint("CENTER", classIcon, "CENTER", 0, 0)
        icon:SetSize(28, 28) -- Match typical icon size
        icon:SetFrameLevel(classIcon:GetFrameLevel())
    end
    
    -- Store the inset calculation function for later updates
    icon.CalculateAuraInset = CalculateAuraInset
    
    -- Main aura texture (cropped like the class icon); no extra backgrounds/borders
    -- CRITICAL RENDERING ORDER FIX (Nov 20, 2025):
    -- At Frame Level 50 (classIcon level):
    --   ARTWORK sublevel 0: Class icon texture (base)
    --   ARTWORK sublevel 1: Aura texture (on top of class icon) ✅
    --   Cooldown spiral: Default layers (below OVERLAY) ✅
    --   OVERLAY layer: Class icon border (always on top) ✅
    -- At Frame Level 60 (text level):
    --   Timer text: Way above everything for visibility ✅
    icon.texture = icon:CreateTexture(nil, "ARTWORK", nil, 1)  -- Sublevel 1: on top of class icon (sublevel 0)
    
    -- CRITICAL FIX: Aura should fill the FULL class icon texture area (28x28)
    -- The orange overlay border (OVERLAY layer) sits on top and provides the border
    -- NO INSET needed - auras fill completely like the class icon does
    icon.texture:SetAllPoints(icon)
    icon.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- Cooldown frame with spiral animation (using helper to block OmniCC)
    icon.cooldown = AC:CreateCooldown(icon, nil, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon)
    icon.cooldown:SetReverse(false) -- Standard direction for buffs/debuffs
    
    -- CRITICAL FIX (Nov 20, 2025): Cooldown spiral needs to be ABOVE the aura texture
    -- but still BELOW the classIcon's OVERLAY layer (the custom border)
    -- Frame level +1 puts it above the aura's ARTWORK sublevel 1, but parent's OVERLAY still renders on top
    icon.cooldown:SetFrameLevel(icon:GetFrameLevel() + 1)
    
    icon.cooldown:SetHideCountdownNumbers(true) -- Hide default numbers, we'll use custom
    icon.cooldown:SetDrawEdge(true) -- Show the spiral edge
    icon.cooldown:SetSwipeColor(0, 0, 0, 0.8) -- Dark swipe overlay
    
    -- Custom cooldown text with decimal precision at 4 seconds or below
    -- CRITICAL: Create text frame ABOVE cooldown spiral
    local textFrame = CreateFrame("Frame", nil, icon)
    textFrame:SetAllPoints(icon)
    textFrame:SetFrameLevel(icon:GetFrameLevel() + 10) -- WAY above cooldown spiral
    
    icon.cooldownText = textFrame:CreateFontString(nil, "OVERLAY")
    icon.cooldownText:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 14, "OUTLINE") -- Custom ArenaCore font
    icon.cooldownText:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
    icon.cooldownText:SetTextColor(1, 1, 1)
    icon.cooldownText:SetDrawLayer("OVERLAY", 7)  -- Highest overlay layer
    icon.cooldownText:SetShadowOffset(1, -1)
    icon.cooldownText:SetShadowColor(0, 0, 0, 1)
    icon.cooldownText:Hide()
    
    -- Update function for precise cooldown display
    icon.UpdateCooldownText = function(self)
        if not self.auraData or not self.auraData.expirationTime or not self.auraData.duration then
            self.cooldownText:Hide()
            return
        end
        
        local remaining = self.auraData.expirationTime - GetTime()
        if remaining <= 0 then
            self.cooldownText:Hide()
            return
        end
        
        -- Show decimals when at or below 4 seconds for precision
        if remaining <= 4 then
            self.cooldownText:SetText(string.format("%.1f", remaining))
        else
            self.cooldownText:SetText(string.format("%d", math.ceil(remaining)))
        end
        self.cooldownText:Show()
    end
    
    -- OnUpdate for continuous cooldown text updates (works for both test and live)
    icon:SetScript("OnUpdate", function(self, elapsed)
        if self.auraData and self.auraData.expirationTime then
            self:UpdateCooldownText()
        end
    end)
    
    -- Count text (using custom ArenaCore font)
    icon.count = icon:CreateFontString(nil, "OVERLAY")
    icon.count:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 10, "OUTLINE")
    icon.count:SetPoint("BOTTOMRIGHT", -1, 1)
    icon.count:SetTextColor(1, 1, 1)
    icon.count:SetDrawLayer("OVERLAY", 3)
    
    -- Tooltip (respects hideTooltips setting)
    icon:EnableMouse(true)
    icon:SetScript("OnEnter", function(self)
        -- Check if tooltips are disabled
        local hideTooltips = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.auras and AC.DB.profile.moreGoodies.auras.hideTooltips
        if hideTooltips then
            return -- Don't show tooltip if disabled
        end
        
        if self.auraData then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.auraData.isTest then
                GameTooltip:SetSpellByID(self.auraData.spellId)
            else
                GameTooltip:SetSpellByID(self.auraData.spellId)
            end
            GameTooltip:Show()
        end
    end)
    
    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Store references for dynamic scaling updates
    icon.classIcon = classIcon
    icon.classIconTexture = classIconTexture
    icon.unit = unit
    
    icon:Hide()
    
    -- Store single icon reference
    local auraFrame = { 
        icon = icon,
        classIcon = classIcon,
        unit = unit
    }
    self.auraFrames[unit] = auraFrame
    
    if AC and AC.Debug then 
        -- Aura frame created
    end
end

-- Update aura frame scaling to match class icon
function AuraTracker:UpdateAuraFrameScaling(unit)
    local auraFrame = self.auraFrames[unit]
    if not auraFrame or not auraFrame.icon then return end
    
    local icon = auraFrame.icon
    local classIcon = auraFrame.classIcon
    
    if classIcon and icon.texture then
        -- CRITICAL FIX: Aura texture should fill the full icon frame (no inset)
        -- The orange overlay border sits on top and provides the border
        icon.texture:ClearAllPoints()
        icon.texture:SetAllPoints(icon)
    end
end

-- Refresh all aura scaling
function AuraTracker:RefreshAllAuraScaling()
    for i = 1, 3 do
        local unit = "arena" .. i
        self:UpdateAuraFrameScaling(unit)
    end
end

-- Refresh all auras
function AuraTracker:RefreshAllAuras()
    -- DEBUG: print("|cff00FFFF[AuraTracker]|r RefreshAllAuras called")
    
    -- CRITICAL: Proactively create aura frames when arena starts
    for i = 1, 3 do
        local unit = "arena" .. i
        if UnitExists(unit) then
            -- Ensure aura frame exists BEFORE trying to update auras
            if not self.auraFrames[unit] then
                -- DEBUG: Disabled to reduce chat spam
                -- print("|cffFFAA00[AuraTracker]|r Proactively creating aura frame for " .. unit)
                self:CreateAuraFrame(unit)
            end
            
            self:UpdateAuras(unit)
        end
    end
end

-- Clear all auras (for Solo Shuffle round transitions)
-- This is called on GROUP_ROSTER_UPDATE to clear auras between rounds
function AuraTracker:ClearAllAuras()
    -- Only clear if we're in arena
    local instanceType = select(2, IsInInstance())
    if instanceType ~= "arena" then
        return
    end
    
    -- Clear all active auras AND combat log auras
    for i = 1, 3 do
        local unit = "arena" .. i
        self.activeAuras[unit] = {}
        self.combatLogAuras[unit] = nil -- CRITICAL: Also clear combat log auras
        
        -- Hide aura display
        local auraFrame = self.auraFrames[unit]
        if auraFrame and auraFrame.icon then
            auraFrame.icon:Hide()
            if auraFrame.icon.cooldown then
                auraFrame.icon.cooldown:Clear()
            end
        end
    end
end

-- Get spell category and priority (uses comprehensive ClassSpellDB)
function AuraTracker:GetSpellCategoryAndPriority(spellId)
    -- CRITICAL FIX: Check AuraTracker's interrupt list FIRST
    -- This prevents ClassSpellDB from miscategorizing interrupts as UTIL
    -- (e.g., Quell 351338 is in ClassSpellDB as UTIL but should be interrupt)
    for categoryName, categoryData in pairs(self.auraCategories) do
        if categoryData.spells[spellId] then
            return categoryName, categoryData.priority
        end
    end
    
    -- Then use the comprehensive ClassSpellDB lookup if available
    if AC and AC.AuraLookup and AC.AuraLookup.AllSpells then
        local spellData = AC.AuraLookup.AllSpells[spellId]
        if spellData then
            -- Map category names to priorities
            local priorityMap = {
                interrupt = 150,  -- CRITICAL FIX: Interrupts HIGHEST priority (must show over everything)
                CC = 100,         -- Crowd Control high priority
                DEF = 50,         -- Defensive cooldowns medium priority
                UTIL = 25         -- Utility lowest priority
            }
            return spellData.category, priorityMap[spellData.category] or 0
        end
    end
    
    return nil, 0
end

-- Get aura settings
function AuraTracker:GetSettings()
    local db = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.auras
    if not db then 
        -- Only warn once
        if not self.dbWarningShown then
            print("|cffFF0000[AuraTracker]|r WARNING: No database found! Using defaults (all enabled)")
            self.dbWarningShown = true
        end
        return {
            enabled = true,  -- DEFAULT TO ENABLED if no database
            interrupt = true,
            crowdControl = true,
            defensive = true,
            utility = true,
            CC = true,
            DEF = true,
            UTIL = true
        }
    end
    
    -- CRITICAL MIGRATION FIX: If interrupt is nil, set it to true and save
    if db.interrupt == nil then
        print("|cffFFAA00[AuraTracker]|r MIGRATION: interrupt was nil, setting to TRUE")
        db.interrupt = true
    end
    if db.crowdControl == nil then
        db.crowdControl = true
    end
    if db.defensive == nil then
        db.defensive = true
    end
    if db.utility == nil then
        db.utility = true
    end
    
    -- Settings tracking (debug removed for clean chat output)
    if not self.lastSettings or 
       self.lastSettings.enabled ~= db.enabled or 
       self.lastSettings.interrupt ~= db.interrupt then
        self.lastSettings = {enabled = db.enabled, interrupt = db.interrupt}
    end
    
    return {
        enabled = db.enabled ~= false,
        interrupt = db.interrupt ~= false,  -- CRITICAL FIX: Track interrupts (kicks/silences)
        crowdControl = db.crowdControl ~= false,
        defensive = db.defensive ~= false,
        highPriorityDefensive = db.defensive ~= false,  -- Use same setting as defensive
        utility = db.utility ~= false,
        -- Map ClassSpellDB categories to UI settings
        CC = db.crowdControl ~= false,
        DEF = db.defensive ~= false,
        -- CRITICAL FIX: Map UTIL to interrupt checkbox (ClassSpellDB puts kicks in UTIL category!)
        UTIL = db.interrupt ~= false  -- Changed from db.utility to db.interrupt
    }
end

-- Check if aura tracking is enabled
function AuraTracker:IsEnabled()
    local settings = self:GetSettings()
    return settings.enabled
end

-- Enable test mode
function AuraTracker:EnableTestMode()
    self.testMode = true
    
    if AC and AC.Debug then 
        AC.Debug:Print("[AuraTracker] Enabling test mode...")
    end
    
    -- CRITICAL: Clear all stale arena aura data before entering test mode
    -- This prevents real arena auras from showing in test mode
    for i = 1, 3 do
        local unit = "arena" .. i
        self.activeAuras[unit] = {}
        self.combatLogAuras[unit] = nil
    end
    
    -- NOTE: FrameManager:EnableTestMode() is called by AC:ShowTestFrames()
    -- We don't call it here to avoid duplicate calls
    if AC and AC.Debug then 
        AC.Debug:Print("[AuraTracker] Cleared stale aura data for test mode")
    end
    
    -- Wait a moment for frames to be created, then add auras
    C_Timer.After(0.5, function()
        if AC and AC.Debug then 
            AC.Debug:Print("[AuraTracker] Creating aura frames...")
        end
        
        local successCount = 0
        for i = 1, 3 do
            local unit = "arena" .. i
            self:CreateAuraFrame(unit)
            if self.auraFrames[unit] then
                successCount = successCount + 1
                self:UpdateTestAuras(unit)
            end
        end
        
        if AC and AC.Debug then 
            AC.Debug:Print("[AuraTracker] Successfully created " .. successCount .. "/3 aura frames")
        end
    end)
end

-- Disable test mode
function AuraTracker:DisableTestMode()
    self.testMode = false
    
    if AC and AC.Debug then 
        AC.Debug:Print("[AuraTracker] Disabling test mode...")
    end
    
    -- Clear all auras and hide aura icons only
    local clearedCount = 0
    for unit, _ in pairs(self.activeAuras) do
        self.activeAuras[unit] = {}
        self:UpdateAuraDisplay(unit)
        clearedCount = clearedCount + 1
    end
    
    -- DEBUG DISABLED FOR PRODUCTION
    -- if AC and AC.Debug then 
    --     AC.Debug:Print("[AuraTracker] Test mode disabled, cleared " .. clearedCount .. " aura displays")
    -- end
    
    -- Don't hide the entire frames - just the aura overlays are hidden by UpdateAuraDisplay
end

-- Hook into ArenaCore's class icon updates for dynamic scaling
local function HookClassIconUpdates()
    -- Hook into the class icon update function if it exists
    if AC and AC.RefreshClassIconsLayout then
        local originalRefresh = AC.RefreshClassIconsLayout
        AC.RefreshClassIconsLayout = function(...)
            originalRefresh(...)
            -- Update aura scaling after class icon changes
            C_Timer.After(0.1, function()
                if AuraTracker.RefreshAllAuraScaling then
                    AuraTracker:RefreshAllAuraScaling()
                end
            end)
        end
    end
end

-- Initialize when addon loads
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, event, addonName)
    if addonName == "ArenaCore" then
        AuraTracker:Initialize()
        -- Hook class icon updates after a delay to ensure AC is fully loaded
        C_Timer.After(1, HookClassIconUpdates)
        initFrame:UnregisterEvent("ADDON_LOADED")
    end
end)
