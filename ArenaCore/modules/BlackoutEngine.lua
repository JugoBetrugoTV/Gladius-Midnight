-- ============================================================================
-- BLACKOUT ENGINE (PLATYNATOR-STYLE SIMPLIFICATION)
-- ============================================================================
-- CLEAN IMPLEMENTATION (Mimics Platynator's approach):
-- - Uses hooksecurefunc (taint-free)
-- - ONLY changes foreground color to black
-- - NEVER touches background (lets Blizzard handle it naturally)
-- - No conflicts with other addons (BBP, Plater, etc.)
-- - Simple, maintainable, reliable
-- ============================================================================

-- CRITICAL FIX: Don't check AC at load time - it may not exist yet
-- Instead, get AC reference when functions are called
local function GetAC()
    return _G.ArenaCore
end

-- MIDNIGHT COMPATIBILITY: Disable in restricted content (arena matches)
-- This feature uses nameplate API which may be restricted during PvP
local function IsBlackoutRestricted()
    local AC = GetAC()
    if not AC or not AC.IsMidnight or not AC:IsMidnight() then
        return false
    end
    return AC:IsInRestrictedContent()
end

-- ============================================================================
-- BLACKOUT SPELL LOOKUP
-- ============================================================================

local blackoutSpells = {}

local function RebuildBlackoutSpells()
    wipe(blackoutSpells)
    
    local AC = GetAC()
    if not AC then return end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    if not db or not db.spells then
        if AC.BLACKOUT_DEBUG then
            print("|cffFF0000[Blackout]|r Database not ready - spell list empty")
        end
        return
    end
    
    local count = 0
    for _, spellID in ipairs(db.spells) do
        blackoutSpells[spellID] = true
        count = count + 1
    end
    
    if AC.BLACKOUT_DEBUG then
        print("|cff00FF00[Blackout]|r Loaded", count, "blackout spells")
    end
end

-- ============================================================================
-- BLACKOUT TRACKING TABLES
-- ============================================================================
-- Track active blackout spells by unit GUID (since we can't see enemy buffs)
local activeBlackouts = {} -- [unitGUID] = {spellID = X, expiresAt = time}

-- ANTI-FLICKER: Track blackout state per unit
-- Only update color when state CHANGES (on→off or off→on), not on every buff tick
-- Fixes MM Hunter Trueshot flicker (rapid UNIT_AURA events from focus regen/procs)
local lastBlackoutState = {} -- [unit] = true/false

-- ============================================================================
-- CENTRALIZED UNIT VALIDATION (CRITICAL FIX)
-- ============================================================================
-- Single source of truth for "is this unit valid for blackout?"
-- Prevents duplicate checks and ensures consistent filtering

local function IsValidBlackoutTarget(unit, unitGUID)
    -- Midnight compatibility: Completely disable in Midnight
    local AC = GetAC()
    if AC and AC.Midnight and AC.Midnight.isMidnight then
        return false
    end
    
    -- CRITICAL: Must have valid unit
    if not unit or not UnitExists(unit) then return false end
    
    -- CRITICAL: ONLY work on ENEMY PLAYERS (not NPCs, not friendlies, not pets, not totems)
    if not UnitIsPlayer(unit) then return false end  -- Must be a player
    if not UnitIsEnemy("player", unit) then return false end  -- Must be hostile to you
    if UnitIsUnit(unit, "player") then return false end  -- Never yourself
    
    -- CRITICAL FIX: Exclude pets (hunter pets, warlock pets, etc.)
    -- Pets can sometimes pass UnitIsPlayer check but should NEVER get blackout
    if UnitIsOtherPlayersPet(unit) then return false end
    
    -- CRITICAL FIX: GUID validation to prevent totems, NPCs, creatures
    -- Player GUIDs: "Player-[server]-[ID]"
    -- Totem GUIDs: "Creature-0-[ID]" ← MUST REJECT
    -- Pet GUIDs: "Pet-0-[ID]" ← MUST REJECT
    -- NPC GUIDs: "Creature-0-[ID]" ← MUST REJECT
    local guid = unitGUID or UnitGUID(unit)
    -- Midnight compatibility: Handle secret GUID values
    if type(guid) ~= "string" then return false end
    if not guid:match("^Player%-") then return false end
    
    return true
end

-- ============================================================================
-- CHECK IF UNIT HAS BLACKOUT (Aura Scan PRIMARY, Combat Log FALLBACK)
-- ============================================================================

local function HasBlackoutAura(unit)
    local unitGUID = UnitGUID(unit)
    
    -- CRITICAL FIX: Use centralized validation (eliminates duplicate checks)
    if not IsValidBlackoutTarget(unit, unitGUID) then return false end
    
    -- ========================================================================
    -- COMBAT LOG ONLY METHOD (OLD VERSION - RELIABLE, NO FALSE POSITIVES)
    -- ========================================================================
    -- REMOVED: AuraUtil.ForEachAura scanning that was causing CC spell false positives
    -- The old version only used combat log tracking and never had CC issues
    -- Combat log is more reliable because it only fires for spells in our whitelist
    
    -- Check if unit has active blackout in our tracking table
    local blackoutData = activeBlackouts[unitGUID]
    if blackoutData and blackoutData.expiresAt > GetTime() then
        local AC = GetAC()
        if AC and AC.BLACKOUT_DEBUG then
            local spellName = C_Spell.GetSpellName(blackoutData.spellID) or "Unknown"
            print(string.format("|cff00FFFF[Blackout]|r %s has %s (%d) via combat log tracking", unit, spellName, blackoutData.spellID))
        end
        return true, blackoutData.spellID
    end
    
    -- Cleanup expired entry
    if blackoutData then
        activeBlackouts[unitGUID] = nil
    end
    
    return false, nil
end

-- ============================================================================
-- FRAME CONFIG INITIALIZATION
-- ============================================================================

local function InitializeFrameConfig(frame)
    if not frame.ArenaCore then
        frame.ArenaCore = {}
    end
    if not frame.ArenaCore.config then
        frame.ArenaCore.config = {}
    end
    return frame.ArenaCore.config
end

-- ============================================================================
-- BLACKOUT COLOR SCANNER
-- ============================================================================
-- Scans for blackout auras and stores the result in frame config

local function ScanBlackoutAura(frame)
    if IsBlackoutRestricted() then return end -- MIDNIGHT: Disable in arena
    if not frame or not frame.unit then return end
    if frame:IsForbidden() or frame:IsProtected() then return end -- TAINT PREVENTION
    
    -- CRITICAL FIX: Use centralized validation (eliminates duplicate checks)
    local unitGUID = UnitGUID(frame.unit)
    if not IsValidBlackoutTarget(frame.unit, unitGUID) then
        -- CRITICAL: Clear blackout state for non-player units (pets, totems, NPCs)
        -- This prevents recycled nameplate frames from showing old blackout textures
        local config = frame.ArenaCore and frame.ArenaCore.config
        if config then
            config.blackoutColor = nil
            config.blackoutSpellID = nil
        end
        return
    end
    
    local AC = GetAC()
    if not AC then return end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    if not db or db.enabled == false then
        -- Clear any existing blackout state
        local config = frame.ArenaCore and frame.ArenaCore.config
        if config then
            config.blackoutColor = nil
        end
        return
    end
    
    -- Initialize config if needed
    local config = InitializeFrameConfig(frame)
    
    -- Check for blackout aura
    local hasBlackout, spellID = HasBlackoutAura(frame.unit)
    
    if hasBlackout then
        -- Check if this spell should actually be in blackout list
        local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
        if db and db.spells then
            local found = false
            for i, listSpellID in ipairs(db.spells) do
                if listSpellID == spellID then
                    found = true
                    break
                end
            end
            if not found then
                -- CRITICAL FIX: If spell is NOT in blackout list, don't apply blackout
                return
            end
        end
        
        -- CRITICAL FIX: When using texture mode, DO NOT set any color at all
        -- Only set a marker that blackout is active for texture application
        local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
        if db and db.useTexture then
            -- Texture mode: ONLY set marker, NO color values
            config.blackoutColor = {textureMode = true}  -- Pure marker, no RGB values
        else
            -- Color mode: Set black color
            config.blackoutColor = {r = 0, g = 0, b = 0}  -- Default black only for color mode
        end
        config.blackoutSpellID = spellID
        
        if AC.BLACKOUT_DEBUG then
            print("|cff00FFFF[Blackout]|r Stored blackout for", frame.unit, (db and db.useTexture) and "(texture mode)" or "(color mode)")
        end
    else
        -- Clear blackout color
        config.blackoutColor = nil
        config.blackoutSpellID = nil
    end
end

-- ============================================================================
-- ARENACORE'S OWN HEALTH COLOR UPDATE FUNCTION
-- ============================================================================
-- Copy of Blizzard's CompactUnitFrame_UpdateHealthColor with blackout applied at end
-- This allows us to bypass Blizzard's function entirely and prevent ping-pong

function AC_CompactUnitFrame_UpdateHealthColor(frame, exitLoop)
    if not frame or not frame.unit then return end
    if frame:IsForbidden() or frame:IsProtected() then return end
    
    -- CRITICAL FIX: ONLY handle nameplates (not arena frames, not party frames)
    if not frame.unit:find("nameplate") then return end
    
    local config = frame.ArenaCore and frame.ArenaCore.config or InitializeFrameConfig(frame)
    
    -- ========================================================================
    -- BLIZZARD'S ORIGINAL HEALTH COLOR LOGIC (Exact Copy)
    -- ========================================================================
    local r, g, b;
    local unitIsConnected = UnitIsConnected(frame.unit);
    local unitIsDead = unitIsConnected and UnitIsDead(frame.unit);
    local unitIsPlayer = UnitIsPlayer(frame.unit) or UnitIsPlayer(frame.displayedUnit);

    if ( not unitIsConnected or (unitIsDead and not unitIsPlayer) ) then
        --Color it gray
        r, g, b = 0.5, 0.5, 0.5;
    else
        if ( frame.optionTable.healthBarColorOverride ) then
            local healthBarColorOverride = frame.optionTable.healthBarColorOverride;
            r, g, b = healthBarColorOverride.r, healthBarColorOverride.g, healthBarColorOverride.b;
        else
            --Try to color it by class.
            local localizedClass, englishClass = UnitClass(frame.unit);
            local classColor = RAID_CLASS_COLORS[englishClass];
            local useClassColors = CompactUnitFrame_GetOptionUseClassColors(frame, frame.optionTable);
            if ( (frame.optionTable.allowClassColorsForNPCs or UnitIsPlayer(frame.unit) or UnitTreatAsPlayerForDisplay(frame.unit)) and classColor and useClassColors ) then
                -- Use class colors for players if class color option is turned on
                r, g, b = classColor.r, classColor.g, classColor.b;
            elseif ( CompactUnitFrame_IsTapDenied(frame) ) then
                -- Use grey if not a player and can't get tap on unit
                r, g, b = 0.9, 0.9, 0.9;
            elseif ( frame.optionTable.colorHealthBySelection ) then
                -- Use color based on the type of unit (neutral, etc.)
                if ( frame.optionTable.considerSelectionInCombatAsHostile and CompactUnitFrame_IsOnThreatListWithPlayer(frame.displayedUnit) and not UnitIsFriend("player", frame.unit) ) then
                    r, g, b = 1.0, 0.0, 0.0;
                elseif ( UnitIsPlayer(frame.displayedUnit) and UnitIsFriend("player", frame.displayedUnit) ) then
                    -- We don't want to use the selection color for friendly player nameplates because
                    -- it doesn't show player health clearly enough.
                    r, g, b = 0.667, 0.667, 1.0;
                else
                    r, g, b = UnitSelectionColor(frame.unit, frame.optionTable.colorHealthWithExtendedColors);
                end
            elseif ( UnitIsFriend("player", frame.unit) ) then
                r, g, b = 0.0, 1.0, 0.0;
            else
                r, g, b = 1.0, 0.0, 0.0;
            end
        end
    end

    -- ========================================================================
    -- ANTI-FLICKER: Only set color if it actually changed
    -- ========================================================================
    local oldR, oldG, oldB = frame.healthBar:GetStatusBarColor();
    if ( r ~= oldR or g ~= oldG or b ~= oldB ) then
        frame.healthBar:SetStatusBarColor(r, g, b);

        if (frame.optionTable.colorHealthWithExtendedColors) then
            frame.selectionHighlight:SetVertexColor(r, g, b);
        else
            frame.selectionHighlight:SetVertexColor(1, 1, 1);
        end
    end
    
    -- ========================================================================
    -- ARENACORE BLACKOUT COLOR APPLICATION (Platynator-style)
    -- ========================================================================
    -- ONLY change foreground color, let Blizzard handle background
    
    local AC = GetAC()
    if not AC then return end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    if not db or db.enabled == false then return end
    
    -- CRITICAL FIX: Use centralized validation (eliminates duplicate checks)
    local unitGUID = UnitGUID(frame.unit)
    if not IsValidBlackoutTarget(frame.unit, unitGUID) then 
        -- CRITICAL FIX: Ensure artifacts are cleaned up from recycled frames (e.g. enemy -> friendly)
        if AC.BlackoutCustomization then
            AC.BlackoutCustomization:ClearCustomization(frame)
        end
        return 
    end
    
    -- Apply blackout customization if stored in config
    if config and config.blackoutColor then
        -- ====================================================================
        -- USE BLACKOUT CUSTOMIZATION MODULE
        -- ====================================================================
        -- Handles texture overlays and color customization
        if AC.BLACKOUT_DEBUG then
            print("|cff00FFFF[BlackoutEngine]|r About to call BlackoutCustomization for", frame.unit)
        end
        
        if AC.BlackoutCustomization then
            AC.BlackoutCustomization:ApplyCustomization(frame, config)
        else
            if AC.BLACKOUT_DEBUG then
                print("|cffFF0000[BlackoutEngine]|r ERROR: BlackoutCustomization module not loaded!")
            end
        end
    else
        -- Clear customization when blackout ends
        if AC.BlackoutCustomization then
            AC.BlackoutCustomization:ClearCustomization(frame)
        end
    end
end

-- ============================================================================
-- HEALTH COLOR UPDATE HOOK
-- ============================================================================
-- CRITICAL: This hook only handles when OTHER addons or Blizzard call the function
-- Our own code uses AC_CompactUnitFrame_UpdateHealthColor() to bypass this entirely

hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
    -- Midnight compatibility: Completely disable blackout engine in Midnight
    local AC = GetAC()
    if AC and AC.Midnight and AC.Midnight.isMidnight then
        return
    end
    
    if not frame or not frame.unit then return end
    if frame:IsForbidden() or frame:IsProtected() then return end
    
    -- CRITICAL FIX: ONLY handle nameplates (not arena frames, not party frames)
    if not frame.unit:find("nameplate") then return end
    
    -- ========================================================================
    -- BLACKOUT SYSTEM (Enemy Players Only) - Platynator-style
    -- ========================================================================
    -- ONLY change foreground color, NEVER touch background
    -- CRITICAL FIX: Use centralized validation (eliminates duplicate checks)
    local unitGUID = UnitGUID(frame.unit)
    if not IsValidBlackoutTarget(frame.unit, unitGUID) then 
        -- CRITICAL FIX: Ensure artifacts are cleaned up from recycled frames (e.g. enemy -> friendly)
        local AC = GetAC()
        if AC and AC.BlackoutCustomization then
            AC.BlackoutCustomization:ClearCustomization(frame)
        end
        return 
    end
    
    local AC = GetAC()
    if not AC then return end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    if not db or db.enabled == false then return end
    
    -- CRITICAL FIX: Re-scan for blackout aura to ensure we have current state
    -- This prevents untargeting from clearing blackout
    ScanBlackoutAura(frame)
    
    -- Check if frame has blackout color stored in config
    local config = frame.ArenaCore and frame.ArenaCore.config
    if config and config.blackoutColor then
        -- Use BlackoutCustomization module for texture/color handling
        if AC.BLACKOUT_DEBUG then
            print("|cff00FFFF[BlackoutEngine HOOK]|r About to call BlackoutCustomization for", frame.unit)
        end
        
        if AC.BlackoutCustomization then
            AC.BlackoutCustomization:ApplyCustomization(frame, config)
        else
            if AC.BLACKOUT_DEBUG then
                print("|cffFF0000[BlackoutEngine HOOK]|r ERROR: BlackoutCustomization module not loaded!")
            end
        end
    else
        -- Clear customization when blackout ends
        if AC.BlackoutCustomization then
            AC.BlackoutCustomization:ClearCustomization(frame)
        end
    end
end)

-- ============================================================================
-- EXTERNAL INTEGRATION
-- ============================================================================
-- REMOVED: No longer needed since we don't touch backgrounds
-- BBP handles its own background colors, we only change foreground for blackout

-- ============================================================================
-- COMBAT_LOG_EVENT_UNFILTERED HANDLER
-- ============================================================================
-- Detect when blackout spells are cast/applied/removed

local combatLogFrame
local function InitializeCombatLogFrame()
    if combatLogFrame then return end
    
    combatLogFrame = CreateFrame("Frame")
    combatLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    combatLogFrame:RegisterEvent("GROUP_ROSTER_UPDATE") -- Solo Shuffle cleanup
    
    combatLogFrame:SetScript("OnEvent", function(self, event)
    local AC = GetAC()
    if not AC then return end
    
    if event == "GROUP_ROSTER_UPDATE" then
        -- Solo Shuffle round transition - clean up blackout states
        local _, instanceType = IsInInstance()
        if instanceType == "arena" then
            -- Clear all blackout tracking
            wipe(activeBlackouts)
            
            -- ANTI-FLICKER: Clear state tracking table (prevents stale states)
            wipe(lastBlackoutState)
            
            -- CRITICAL FIX: Clear test mode flags (prevent test textures from persisting)
            local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
            if db then
                db.externalTestMode = false
                db.healthBarTestMode = false
            end
            
            -- Trigger health color update for all nameplates to restore colors
            C_Timer.After(0.3, function()
                for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
                    local frame = nameplate.unitFrame or nameplate.UnitFrame
                    if frame and frame.unit and not frame:IsForbidden() and not frame:IsProtected() then
                        ScanBlackoutAura(frame)
                        AC_CompactUnitFrame_UpdateHealthColor(frame)  -- Use OUR function, not Blizzard's
                    end
                end
            end)
            
            if AC.BLACKOUT_DEBUG then
                print("|cff00FFFF[Blackout]|r Solo Shuffle cleanup complete (state tracking + test modes cleared)")
            end
        end
        return
    end
    
    -- COMBAT_LOG_EVENT_UNFILTERED handling
    local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    
    -- DEBUG: Log ALL spell aura events (not just blackout ones)
    local AC = GetAC()
    if AC and AC.BLACKOUT_DEBUG and spellID then
        local spellName = C_Spell.GetSpellName(spellID) or "Unknown"
        if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" or subEvent == "SPELL_AURA_REMOVED" then
            print(string.format("|cffFFFF00[Combat Log]|r %s: %s (%d) on %s", subEvent, spellName, spellID, destGUID or "unknown"))
        end
    end
    
    if not spellID or not blackoutSpells[spellID] then 
        -- DEBUG: Log why we rejected this spell
        if AC and AC.BLACKOUT_DEBUG and spellID then
            local spellName = C_Spell.GetSpellName(spellID) or "Unknown"
            if not blackoutSpells[spellID] then
                print(string.format("|cffFF0000[Combat Log]|r REJECTED: %s (%d) - Not in blackout list", spellName, spellID))
            end
        end
        return 
    end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    if not db or db.enabled == false then return end
    
    -- SPELL_AURA_APPLIED: Blackout spell applied
    if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" then
        -- CRITICAL: ONLY track if destination is an ENEMY PLAYER
        -- GUID format check: Player GUIDs start with "Player-"
        if not destGUID or not destGUID:match("^Player%-") then return end
        
        -- CRITICAL FIX: Ensure destGUID is NOT the player's own GUID
        -- This prevents CC debuffs cast ON YOU from triggering blackout
        local playerGUID = UnitGUID("player")
        if destGUID == playerGUID then
            if AC.BLACKOUT_DEBUG then
                local spellName = C_Spell.GetSpellName(spellID) or "Unknown"
                print(string.format("|cffFF0000[Blackout BLOCKED]|r %s (%d) applied to YOU - ignoring (not an enemy buff)", spellName, spellID))
            end
            return
        end
        
        -- Additional check: Ensure it's not a friendly player (arena teammates, etc.)
        -- We can't directly check UnitIsEnemy from GUID, but Player- prefix ensures it's a player
        -- The nameplate filtering will handle the enemy check
        
        -- Track the blackout with conservative 20-second duration
        activeBlackouts[destGUID] = {
            spellID = spellID,
            expiresAt = GetTime() + 20
        }
        
        if AC.BLACKOUT_DEBUG then
            local spellName = C_Spell.GetSpellName(spellID)
            print("|cff00FFFF[Blackout]|r Applied:", spellName, "(", spellID, ")")
        end
        
        -- Trigger health color update for all nameplates IMMEDIATELY
        -- NO DELAY: Apply aura colors immediately to prevent flashing
        for _, namePlateFrameBase in pairs(C_NamePlate.GetNamePlates()) do
            local frame = namePlateFrameBase.UnitFrame
            if frame and frame.unit and not frame:IsForbidden() and not frame:IsProtected() then
                local guid = UnitGUID(frame.unit)
                if guid == destGUID then
                    ScanBlackoutAura(frame)
                    AC_CompactUnitFrame_UpdateHealthColor(frame)  -- Use OUR function, not Blizzard's
                end
            end
        end
        
    -- SPELL_AURA_REMOVED: Blackout spell removed
    elseif subEvent == "SPELL_AURA_REMOVED" then
        -- CRITICAL FIX: Clear blackout immediately without re-scanning
        activeBlackouts[destGUID] = nil
        
        if AC.BLACKOUT_DEBUG then
            local spellName = C_Spell.GetSpellName(spellID)
            print("|cff00FFFF[Blackout]|r Removed:", spellName, "(", spellID, ")")
        end
        
        -- CRITICAL FIX: Force-clear blackout state without re-scanning
        -- Re-scanning can cause race condition if aura hasn't fully cleared yet
        for _, namePlateFrameBase in pairs(C_NamePlate.GetNamePlates()) do
            local frame = namePlateFrameBase.UnitFrame
            if frame and frame.unit and not frame:IsForbidden() and not frame:IsProtected() then
                local guid = UnitGUID(frame.unit)
                if guid == destGUID then
                    -- Force-clear blackout config (don't re-scan)
                    local config = frame.ArenaCore and frame.ArenaCore.config
                    if config then
                        config.blackoutColor = nil
                        config.blackoutSpellID = nil
                    end
                    
                    -- Clear state tracking
                    lastBlackoutState[frame.unit] = false
                    
                    -- Trigger color update to restore original colors
                    AC_CompactUnitFrame_UpdateHealthColor(frame)
                    
                    if AC.BLACKOUT_DEBUG then
                        print(string.format("|cff00FF00[Blackout]|r FORCE-CLEARED blackout for %s (GUID: %s)", frame.unit, guid))
                    end
                end
            end
        end
    end
    end)
end

-- ============================================================================
-- NAME_PLATE_UNIT_ADDED HANDLER
-- ============================================================================
-- Scan new nameplates immediately when they appear

local nameplateFrame
local function InitializeNameplateFrame()
    if nameplateFrame then return end
    
    nameplateFrame = CreateFrame("Frame")
    nameplateFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")

nameplateFrame:SetScript("OnEvent", function(self, event, unit)
    -- Midnight compatibility: Completely disable blackout engine in Midnight
    local AC = GetAC()
    if AC and AC.Midnight and AC.Midnight.isMidnight then
        return
    end
    
    if IsBlackoutRestricted() then return end -- MIDNIGHT: Disable in arena
    
    local AC = GetAC()
    if not AC then return end
    
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end
    
    -- ================================================================
    -- UNIVERSAL NAMEPLATE ADDON COMPATIBILITY
    -- ================================================================
    -- Detect the correct frame for any nameplate addon:
    -- - Blizzard default: nameplate.UnitFrame (uppercase 'U')
    -- - Plater: nameplate.unitFrame (lowercase 'u')
    -- - Platynator: nameplate.unitFrame (lowercase 'u')
    -- - Other addons: Try both, prefer custom frame if it exists
    local frame = nameplate.unitFrame or nameplate.UnitFrame
    
    if frame and not frame:IsForbidden() and not frame:IsProtected() then
            -- ================================================================
            -- BBP PATTERN: Touch HealthBarsContainer to trigger visibility
            -- ================================================================
            -- CRITICAL: This MUST happen for ALL nameplates FIRST!
            -- BBP initializes by touching the container, not calling Show()
            -- This activates Blizzard's visibility system for ALL units
            if frame.HealthBarsContainer and frame.HealthBarsContainer.background then
                -- Access the background to trigger Blizzard's visibility (BBP pattern)
                local r, g, b, a = frame.HealthBarsContainer.background:GetVertexColor()
                -- This simple access is enough to activate the frame
            end
            
            -- ================================================================
            -- BLACKOUT SYSTEM: Scan for blackout auras (BBP Pattern)
            -- ================================================================
            -- BBP PATTERN: Let Blizzard set colors naturally, hook will override
            -- ONLY scan for blackout, don't manually trigger color updates
            local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
            if db and db.enabled then
                -- Scan for blackout aura immediately
                -- Blizzard will call CompactUnitFrame_UpdateHealthColor naturally
                -- Our hook will apply blackout color if aura is present
                ScanBlackoutAura(frame)
            end
    end
    end)
end

-- ============================================================================
-- UNIT_AURA HANDLER (For friendly/neutral units we can scan)
-- ============================================================================

local auraFrame
local function InitializeAuraFrame()
    if auraFrame then return end
    
    auraFrame = CreateFrame("Frame")
    auraFrame:RegisterEvent("UNIT_AURA")

auraFrame:SetScript("OnEvent", function(self, event, unit)
    -- CRITICAL FIX: ONLY handle nameplates (not arena frames, not party frames)
    if not unit or not unit:find("nameplate") then return end
    
    if IsBlackoutRestricted() then return end
    
    local AC = GetAC()
    if not AC then return end
    
    -- Get nameplate frame
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end
    local frame = nameplate.unitFrame or nameplate.UnitFrame
    if not frame then return end
    
    if frame and not frame:IsForbidden() and not frame:IsProtected() then
        -- ================================================================
        -- BLACKOUT SYSTEM: Track aura changes (Platynator-style)
        -- ================================================================
        -- ONLY track blackout state, NEVER touch backgrounds
        local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
        if db and db.enabled then
            -- DEBUG: Log every UNIT_AURA event
            if AC.BLACKOUT_DEBUG then
                print(string.format("|cffFFFF00[UNIT_AURA]|r Event triggered for %s (nameplate only)", unit))
            end
            
            -- Check current blackout state
            local hasBlackout = HasBlackoutAura(unit)
            
            -- ANTI-FLICKER: Only update if state changed
            -- Prevents rapid color updates from MM Hunter Trueshot, focus regen, procs, etc.
            if lastBlackoutState[unit] ~= hasBlackout then
                lastBlackoutState[unit] = hasBlackout
                
                if AC.BLACKOUT_DEBUG then
                    print(string.format("|cff00FFFF[Blackout]|r %s state changed: %s (NAMEPLATE)", unit, hasBlackout and "ACTIVE" or "CLEARED"))
                    if hasBlackout then
                        print(string.format("|cff00FFFF[Blackout]|r %s HAS BLACKOUT AURA - This should only happen for spells in the blackout list!", unit))
                    end
                end
                
                ScanBlackoutAura(frame)
                
                if frame.healthBar then
                    AC_CompactUnitFrame_UpdateHealthColor(frame)  -- Use OUR function, not Blizzard's
                end
            elseif AC.BLACKOUT_DEBUG then
                -- DEBUG: Log when state didn't change (for debugging flicker issues)
                print(string.format("|cffFFFF00[Blackout]|r %s state unchanged: %s", unit, hasBlackout and "ACTIVE" or "CLEARED"))
            end
        end
    end
    end)
end

-- ============================================================================
-- SLASH COMMAND FOR DEBUG
-- ============================================================================

-- ============================================================================
-- CONTINUOUS MONITOR (REMOVED)
-- ============================================================================
-- No longer needed - we don't touch backgrounds anymore

SLASH_BLACKOUTDEBUG1 = "/blackoutdebug"
SLASH_BLACKOUTDEBUG2 = "/bodebug"
SlashCmdList["BLACKOUTDEBUG"] = function(msg)
    local AC = GetAC()
    if not AC then
        print("|cffFF0000[Blackout]|r ArenaCore not loaded yet!")
        return
    end
    
    -- Toggle debug mode
    AC.BLACKOUT_DEBUG = not AC.BLACKOUT_DEBUG
    if AC.BLACKOUT_DEBUG then
        print("|cff00FFFF[Blackout]|r Debug mode |cff00FF00ENABLED|r")
        print("|cff00FFFF[Blackout]|r You will now see debug messages for blackout aura detection")
        print("|cff00FFFF[Blackout]|r Use /testblackout to check current target")
    else
        print("|cff00FFFF[Blackout]|r Debug mode |cffFF0000DISABLED|r")
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Public API function - needs to be added to AC when it exists
local function RefreshBlackout()
    RebuildBlackoutSpells()
    
    -- Rescan all visible nameplates
    local nameplates = C_NamePlate.GetNamePlates()
    for _, nameplate in ipairs(nameplates) do
        local frame = nameplate.unitFrame or nameplate.UnitFrame
        if frame and frame.unit then
            if not frame:IsForbidden() and not frame:IsProtected() then
                ScanBlackoutAura(frame)
                if frame.healthBar then
                    AC_CompactUnitFrame_UpdateHealthColor(frame)  -- Use OUR function, not Blizzard's
                end
            end
        end
    end
end

-- Register the public API when AC is ready
C_Timer.After(0.1, function()
    local AC = GetAC()
    if AC then
        AC.RefreshBlackout = RefreshBlackout
    end
end)

-- ============================================================================
-- RELOAD SAFETY NET
-- ============================================================================

local reloadFrame = CreateFrame("Frame")
reloadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
reloadFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")  -- Solo Shuffle round start
reloadFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")  -- Arena opponent changes

reloadFrame:SetScript("OnEvent", function(self, event)
    C_Timer.After(0.5, function()
        -- Rebuild spell list
        RebuildBlackoutSpells()
        
        local AC = GetAC()
        if not AC then return end
        
        local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
        
        -- CRITICAL FIX: Clear test mode flags on zone change/reload
        -- Prevents test textures from persisting outside of active testing
        if event == "PLAYER_ENTERING_WORLD" then
            local _, instanceType = IsInInstance()
            -- Clear test modes when NOT in arena (prevents target dummy issue)
            if instanceType ~= "arena" then
                if db then
                    db.externalTestMode = false
                    db.healthBarTestMode = false
                end
                
                -- Clear all blackout states when leaving arena
                wipe(activeBlackouts)
                wipe(lastBlackoutState)
                
                if AC.BLACKOUT_DEBUG then
                    print("|cff00FFFF[Blackout]|r Left arena - test modes cleared, blackout states reset")
                end
            end
        end
        
        if not db or db.enabled == false then return end
        
        -- Scan all visible nameplates
        local nameplates = C_NamePlate.GetNamePlates()
        for _, nameplate in ipairs(nameplates) do
            local frame = nameplate.unitFrame or nameplate.UnitFrame
            if frame and frame.unit then
                if not frame:IsForbidden() and not frame:IsProtected() then
                    ScanBlackoutAura(frame)
                    if frame.healthBar then
                        AC_CompactUnitFrame_UpdateHealthColor(frame)  -- Use OUR function, not Blizzard's
                    end
                    
                    -- CRITICAL: Refresh party class indicators on round changes
                    if AC.UpdatePartyClassIndicator then
                        AC.UpdatePartyClassIndicator(frame)
                    end
                end
            end
        end
        
        if AC.BLACKOUT_DEBUG then
            print("|cff00FFFF[Blackout]|r System initialized (event: " .. event .. ")")
        end
    end)
end)

-- ============================================================================
-- DEBUG COMMAND
-- ============================================================================

local function TestBlackout()
    print("|cff00FFFF[Blackout Debug]|r ==================")
    
    local AC = GetAC()
    if not AC then
        print("|cffFF0000[Blackout]|r ArenaCore not loaded yet!")
        return
    end
    
    -- Check if enabled
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    if not db then
        print("|cffFF0000[Blackout]|r Database not found!")
        return
    end
    
    print("|cff00FF00[Blackout]|r Enabled:", tostring(db.enabled))
    
    -- Count spells
    local count = 0
    for _ in pairs(blackoutSpells) do count = count + 1 end
    print("|cff00FF00[Blackout]|r Spells loaded:", count)
    
    -- Check target
    if UnitExists("target") then
        print("|cff00FF00[Blackout]|r Target:", UnitName("target"))
        
        -- Check blackout detection
        local hasBlackout, spellID = HasBlackoutAura("target")
        print("|cff00FF00[Blackout]|r Has blackout aura:", tostring(hasBlackout))
        if spellID then
            local spellName = C_Spell.GetSpellName(spellID)
            print("|cff00FF00[Blackout]|r Detected spell:", spellName, "(", spellID, ")")
        end
        
        -- Check active blackouts
        print("|cffFFAA00[Blackout]|r Active blackouts:")
        local activeCount = 0
        for guid, data in pairs(activeBlackouts) do
            activeCount = activeCount + 1
            local spellName = C_Spell.GetSpellName(data.spellID)
            local timeLeft = data.expiresAt - GetTime()
            print("  ", guid, ":", spellName, "(", data.spellID, ") -", string.format("%.1f", timeLeft), "sec left")
        end
        if activeCount == 0 then
            print("  |cffFFAA00No active blackouts|r")
        end
    else
        print("|cffFFAA00[Blackout]|r No target selected")
    end
    
    print("|cff00FFFF[Blackout Debug]|r ==================")
end

-- Register dedicated slash command
SLASH_BLACKOUTTEST1 = "/testblackout"
SLASH_BLACKOUTTEST2 = "/blackouttest"
SlashCmdList["BLACKOUTTEST"] = TestBlackout
SLASH_BLACKOUTLIST1 = "/blackoutlist"
SLASH_BLACKOUTLIST2 = "/bolist"
SlashCmdList["BLACKOUTLIST"] = function(msg)
    local AC = GetAC()
    if not AC then
        print("|cffFF0000[Blackout]|r ArenaCore not loaded yet!")
        return
    end
    
    print("|cff00FFFF[Blackout]|r ========== CURRENT BLACKOUT SPELLS ==========")
    
    local count = 0
    for spellID, _ in pairs(blackoutSpells) do
        count = count + 1
        local spellName = C_Spell.GetSpellName(spellID) or "Unknown"
        print(string.format("  %d: %s (%d)", count, spellName, spellID))
    end
    
    print(string.format("|cff00FFFF[Blackout]|r Total: %d spells loaded", count))
    print("|cff00FFFF[Blackout]|r ============================================")
    
    -- Check if Polymorph and Fear are in the list
    if blackoutSpells[118] then
        print("|cff00FF00[Blackout]|r ✓ Polymorph (118) IS in blackout list")
    else
        print("|cffFF0000[Blackout]|r ✗ Polymorph (118) NOT in blackout list")
    end
    
    if blackoutSpells[5782] then
        print("|cff00FF00[Blackout]|r ✓ Fear (5782) IS in blackout list")
    else
        print("|cffFF0000[Blackout]|r ✗ Fear (5782) NOT in blackout list")
    end
end

-- ============================================================================
-- NAMEPLATE CLEANUP (Prevent Frame Recycling Issues)
-- ============================================================================
-- CRITICAL: Blizzard recycles nameplate frames for performance
-- When a nameplate is removed, we MUST clear all blackout state
-- Otherwise, a pet nameplate might inherit blackout textures from a previous enemy player

local function HandleNamePlateRemoved(unit)
    local AC = GetAC()
    if not AC then return end
    
    -- Get the nameplate frame for this unit
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end
    
    local frame = nameplate.unitFrame or nameplate.UnitFrame
    if not frame then return end
    
    -- Clear blackout config to prevent recycled frames from inheriting old state
    if frame.ArenaCore and frame.ArenaCore.config then
        frame.ArenaCore.config.blackoutColor = nil
        frame.ArenaCore.config.blackoutSpellID = nil
    end
    
    -- Clear all blackout textures and indicators
    if AC.BlackoutCustomization then
        AC.BlackoutCustomization:ClearCustomization(frame)
    end
end

-- Register NAME_PLATE_UNIT_REMOVED event
local nameplateRemovedFrame = CreateFrame("Frame")
nameplateRemovedFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
nameplateRemovedFrame:SetScript("OnEvent", function(self, event, unit)
    -- Midnight compatibility: Completely disable blackout engine in Midnight
    local AC = GetAC()
    if AC and AC.Midnight and AC.Midnight.isMidnight then
        return
    end
    
    HandleNamePlateRemoved(unit)
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
-- Load blackout spells and initialize event frames when addon loads

C_Timer.After(0.5, function()
    local AC = GetAC()
    
    -- MIDNIGHT: Completely disable Blackout to avoid taint warnings
    if AC and AC.Midnight and AC.Midnight.isMidnight then
        if AC.BLACKOUT_DEBUG then
            print("|cffFF0000[Blackout]|r Disabled in Midnight to prevent taint warnings")
        end
        return
    end
    
    RebuildBlackoutSpells()
    
    -- Initialize all event frames AFTER addon loads to avoid taint warnings
    InitializeCombatLogFrame()
    InitializeNameplateFrame()
    InitializeAuraFrame()
    
    if AC and AC.BLACKOUT_DEBUG then
        local count = 0
        for _ in pairs(blackoutSpells) do count = count + 1 end
        print("|cff00FFFF[Blackout]|r Spells loaded:", count)
        print("|cff00FFFF[Blackout]|r Use /testblackout to debug")
    end
end)
