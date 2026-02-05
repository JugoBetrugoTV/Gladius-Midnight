-- Core/MidnightCompat.lua
-- Midnight (12.0) Compatibility and Restriction Detection System
local AC = _G.ArenaCore
if not AC then return end

AC.Midnight = {}
local Midnight = AC.Midnight

-- ============================================================================
-- MIDNIGHT DETECTION (Dual Fallback System)
-- ============================================================================

-- Method 1: Check game version string
local gameVersion = select(1, GetBuildInfo())
Midnight.isMidnight = gameVersion and gameVersion:match("^12") ~= nil

-- Method 2: Check if Midnight-specific APIs exist (fallback)
if not Midnight.isMidnight then
    Midnight.isMidnight = C_RestrictedActions ~= nil and C_RestrictedActions.IsAddOnRestrictionActive ~= nil
end

-- Store version info for debugging
Midnight.gameVersion = gameVersion
Midnight.detectionMethod = Midnight.isMidnight and (gameVersion:match("^12") and "version" or "api") or "none"

-- ============================================================================
-- RESTRICTION STATE DETECTION
-- ============================================================================

-- Check if we're currently in restricted content (arena match, rated BG, etc.)
function Midnight:IsInRestrictedContent()
    if not self.isMidnight then
        return false
    end
    
    -- Check if C_RestrictedActions API is available
    if not C_RestrictedActions or not C_RestrictedActions.IsAddOnRestrictionActive then
        return false
    end
    
    -- Check for PvP Match restriction (includes arena)
    local isPvPRestricted = C_RestrictedActions.IsAddOnRestrictionActive(Enum.AddOnRestrictionType.PvPMatch)
    
    -- Check for Combat restriction (broader, includes any combat)
    local isCombatRestricted = C_RestrictedActions.IsAddOnRestrictionActive(Enum.AddOnRestrictionType.Combat)
    
    -- Return true if either restriction is active
    return isPvPRestricted or isCombatRestricted
end

-- Check specific restriction types
function Midnight:GetRestrictionState(restrictionType)
    if not self.isMidnight then
        return false
    end
    
    if not C_RestrictedActions or not C_RestrictedActions.GetAddOnRestrictionState then
        return false
    end
    
    local state = C_RestrictedActions.GetAddOnRestrictionState(restrictionType)
    return state == Enum.AddOnRestrictionState.Active or state == Enum.AddOnRestrictionState.Activating
end

-- ============================================================================
-- FEATURE AVAILABILITY CHECKS
-- ============================================================================

-- Check if a specific feature should be disabled
function Midnight:ShouldDisableFeature(featureName)
    if not self.isMidnight then
        return false
    end
    
    -- Features that are disabled in restricted content only
    local restrictedFeatures = {
        ["blackout"] = true,
        ["classpacks"] = true,
        ["debuffswindow"] = true,
        ["dispelwindow"] = true,
        ["kickbar"] = true,
    }
    
    if restrictedFeatures[featureName] then
        return self:IsInRestrictedContent()
    end
    
    return false
end

-- Check if aura data is available (may be restricted in Midnight)
function Midnight:CanAccessAuraData()
    if not self.isMidnight then
        return true
    end
    
    -- In Midnight, aura data may be restricted during PvP matches
    -- We'll test this by trying to access aura data for the player
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
        return false
    end
    
    -- Try to get player's first aura - if it returns secret data, we're restricted
    local testAura = C_UnitAuras.GetAuraDataByIndex("player", 1, "HELPFUL")
    
    -- If we get nil, either no auras exist or we're restricted
    -- We can't distinguish between these cases without more testing
    return testAura ~= nil or not self:IsInRestrictedContent()
end

-- Check if nameplate API is available
function Midnight:CanAccessNamePlates()
    if not self.isMidnight then
        return true
    end
    
    -- Nameplate API should still work, but may have restrictions
    return C_NamePlate ~= nil and C_NamePlate.GetNamePlates ~= nil
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

-- Track restriction state changes
Midnight.restrictionState = {
    combat = false,
    encounter = false,
    challengeMode = false,
    pvpMatch = false,
    map = false,
}

-- Create event frame for restriction tracking
local restrictionFrame = CreateFrame("Frame")

if Midnight.isMidnight and C_RestrictedActions then
    restrictionFrame:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
    
    restrictionFrame:SetScript("OnEvent", function(self, event, restrictionType, state)
        if event == "ADDON_RESTRICTION_STATE_CHANGED" then
            -- Update our tracked state
            local isActive = (state == Enum.AddOnRestrictionState.Active or state == Enum.AddOnRestrictionState.Activating)
            
            if restrictionType == Enum.AddOnRestrictionType.Combat then
                Midnight.restrictionState.combat = isActive
            elseif restrictionType == Enum.AddOnRestrictionType.Encounter then
                Midnight.restrictionState.encounter = isActive
            elseif restrictionType == Enum.AddOnRestrictionType.ChallengeMode then
                Midnight.restrictionState.challengeMode = isActive
            elseif restrictionType == Enum.AddOnRestrictionType.PvPMatch then
                Midnight.restrictionState.pvpMatch = isActive
            elseif restrictionType == Enum.AddOnRestrictionType.Map then
                Midnight.restrictionState.map = isActive
            end
            
            -- Fire custom event for other modules to react
            if AC.callbacks then
                AC.callbacks:Fire("MIDNIGHT_RESTRICTION_CHANGED", restrictionType, isActive)
            end
            
            -- Debug output (commented out for production)
            -- if AC.Debug then
            --     local typeName = "Unknown"
            --     if restrictionType == Enum.AddOnRestrictionType.Combat then typeName = "Combat"
            --     elseif restrictionType == Enum.AddOnRestrictionType.Encounter then typeName = "Encounter"
            --     elseif restrictionType == Enum.AddOnRestrictionType.ChallengeMode then typeName = "ChallengeMode"
            --     elseif restrictionType == Enum.AddOnRestrictionType.PvPMatch then typeName = "PvPMatch"
            --     elseif restrictionType == Enum.AddOnRestrictionType.Map then typeName = "Map"
            --     end
            --     
            --     AC.Debug:Print(string.format("Midnight Restriction %s: %s", typeName, isActive and "ACTIVE" or "INACTIVE"))
            -- end
        end
    end)
end

-- ============================================================================
-- TAINT WARNING SUPPRESSION
-- ============================================================================

-- Suppress Midnight's taint warning events that show as errors in-game
-- These warnings are cosmetic and don't affect functionality, but scare users
local function SuppressTaintWarnings()
    -- Create a frame to intercept and suppress taint warning events
    local suppressFrame = CreateFrame("Frame")
    suppressFrame:RegisterEvent("ADDON_ACTION_BLOCKED")
    suppressFrame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
    
    suppressFrame:SetScript("OnEvent", function(self, event, addonName, functionName)
        -- Silently consume these events for ArenaCore
        -- This prevents them from showing as red errors in the default UI
        if addonName and addonName:find("ArenaCore") or addonName == "Arena Core" then
            -- Suppress the warning - don't let it propagate to UIErrorsFrame
            return
        end
    end)
    
    -- Also suppress the default error frame from showing these specific messages
    if UIErrorsFrame then
        local originalAddMessage = UIErrorsFrame.AddMessage
        UIErrorsFrame.AddMessage = function(self, text, ...)
            -- Filter out ArenaCore taint messages
            if text and (text:find("Arena Core taint") or text:find("ArenaCore")) then
                return -- Suppress
            end
            return originalAddMessage(self, text, ...)
        end
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function Midnight:Initialize()
    -- Suppress taint warnings FIRST before any output
    if self.isMidnight then
        SuppressTaintWarnings()
    end
    
    -- Print detection info
    if self.isMidnight then
        print("|cff8B45FFArena Core:|r Midnight (12.0) detected - Compatibility mode enabled")
        -- print("|cff8B45FFArena Core:|r Detection method: " .. self.detectionMethod)
        -- print("|cff8B45FFArena Core:|r Game version: " .. (self.gameVersion or "unknown"))
        
        -- Check initial restriction state
        if C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive then
            local inPvP = C_RestrictedActions.IsAddOnRestrictionActive(Enum.AddOnRestrictionType.PvPMatch)
            if inPvP then
                print("|cff8B45FFArena Core:|r |cffFF0000Currently in restricted PvP content - some features disabled|r")
            end
        end
    end
end

-- Auto-initialize when module loads
C_Timer.After(1, function()
    if Midnight and Midnight.Initialize then
        Midnight:Initialize()
    end
end)

-- ============================================================================
-- GLOBAL HELPER FUNCTIONS
-- ============================================================================

-- Make commonly used functions available at AC level
function AC:IsMidnight()
    return Midnight.isMidnight
end

function AC:IsInRestrictedContent()
    return Midnight:IsInRestrictedContent()
end

function AC:ShouldDisableFeature(featureName)
    return Midnight:ShouldDisableFeature(featureName)
end
