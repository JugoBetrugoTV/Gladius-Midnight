-- ============================================================================
-- File: ArenaCore/modules/PartyClassIndicatorEngine.lua (v1.0)
-- Purpose: Independent party class indicator event handling
-- Separated from BlackoutEngine to work in Midnight where Blackout is disabled
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

-- CRITICAL FIX: Don't check AC at load time - it may not exist yet
-- Instead, get AC reference when functions are called
local function GetAC()
    return _G.ArenaCore
end

-- ============================================================================
-- NAME_PLATE_UNIT_ADDED HANDLER
-- ============================================================================
-- Handle party class indicators when nameplates appear

local nameplateFrame
local function InitializeNameplateFrame()
    if nameplateFrame then return end
    
    nameplateFrame = CreateFrame("Frame")
    nameplateFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")

nameplateFrame:SetScript("OnEvent", function(self, event, unit)
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
            -- CRITICAL FIX: NAMEPLATE RECYCLING CLEANUP
            -- ================================================================
            -- Nameplates are RECYCLED by WoW. When a nameplate appears, it might
            -- have class icons/pointers from when it was a friendly player.
            -- We must clean them up if this unit is NOT a friendly player.
            
            -- Check if this nameplate has our custom elements
            if AC.PartyClassIndicators and AC.PartyClassIndicators.independentFrames then
                local independentFrames = AC.PartyClassIndicators.independentFrames
                
                -- Check if this is a friendly player
                local isFriendlyPlayer = UnitIsPlayer(unit) and UnitIsFriend("player", unit)
                
                -- If NOT a friendly player, hide any existing class icons/pointers
                if not isFriendlyPlayer then
                    local classFrame = independentFrames[unit]
                    if classFrame then
                        classFrame:Hide()
                    end
                    
                    local pointerFrame = independentFrames[unit .. "_pointer"]
                    if pointerFrame then
                        pointerFrame:Hide()
                    end
                end
            end
            
            -- ================================================================
            -- PARTY CLASS INDICATORS
            -- ================================================================
            -- Called when nameplates appear
            -- COMPATIBLE WITH: Blizzard nameplates only
            -- NOTE: Custom nameplate addons (Plater, Platynator) have protected/forbidden
            -- frames that prevent this code from running
            if AC.UpdatePartyClassIndicator then
                -- CRITICAL: Don't pass the nameplate frame - it's forbidden with custom addons!
                -- Just create a simple table with the unit ID
                local dummyFrame = { unit = unit }
                AC.UpdatePartyClassIndicator(dummyFrame)
            end
    end
    end)
end

-- ============================================================================
-- NAME_PLATE_UNIT_REMOVED HANDLER
-- ============================================================================
-- Clean up party class indicators when nameplates disappear

local function HandleNamePlateRemoved(unit)
    local AC = GetAC()
    if not AC then return end
    
    -- CRITICAL FIX: Clean up party class indicator independent frames
    -- This prevents stale frames from remaining when you leave and return to an area
    if AC.PartyClassIndicators then
        -- Clean up the independent frames table for this unit
        local independentFrames = AC.PartyClassIndicators.independentFrames
        if independentFrames then
            -- Hide and clean up class icon frame
            local classFrame = independentFrames[unit]
            if classFrame then
                classFrame:Hide()
                classFrame:SetScript("OnUpdate", nil)
                classFrame.unit = nil
                independentFrames[unit] = nil
            end
            
            -- Hide and clean up pointer frame
            local pointerFrame = independentFrames[unit .. "_pointer"]
            if pointerFrame then
                pointerFrame:Hide()
                pointerFrame:SetScript("OnUpdate", nil)
                pointerFrame.unit = nil
                independentFrames[unit .. "_pointer"] = nil
            end
        end
    end
end

-- Register NAME_PLATE_UNIT_REMOVED event
local nameplateRemovedFrame = CreateFrame("Frame")
nameplateRemovedFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
nameplateRemovedFrame:SetScript("OnEvent", function(self, event, unit)
    HandleNamePlateRemoved(unit)
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
-- Initialize event frames when addon loads (works in both regular WoW and Midnight)

C_Timer.After(0.5, function()
    local AC = GetAC()
    if not AC then return end
    
    -- Initialize party class indicator event handling
    -- This works in both regular WoW and Midnight (no blackout restrictions)
    InitializeNameplateFrame()
    
    if AC and AC.PARTY_CLASS_DEBUG then
        print("|cff8B45FF[Party Class Indicators]|r Event handler initialized")
    end
end)

-- CRITICAL FIX: Ensure health bar hiding persists on fresh game load
-- This must run after database is fully initialized
C_Timer.After(2, function()
    local AC = GetAC()
    if not AC then return end
    
    -- Start the persistence ticker if hideHealthBars is enabled
    -- This ensures the setting works on fresh login without needing to toggle it
    if AC.EnsureHealthBarHidingPersistence then
        AC:EnsureHealthBarHidingPersistence()
    end
end)

-- BACKUP: Also trigger on PLAYER_ENTERING_WORLD for zone changes and reloads
local playerEnterFrame = CreateFrame("Frame")
playerEnterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
playerEnterFrame:SetScript("OnEvent", function(self, event)
    -- Delay to ensure database is ready
    C_Timer.After(0.5, function()
        local AC = GetAC()
        if not AC then return end
        
        if AC.EnsureHealthBarHidingPersistence then
            AC:EnsureHealthBarHidingPersistence()
        end
    end)
end)

-- Module loaded
if AC and AC.PARTY_CLASS_DEBUG then
    print("|cff8B45FF[Party Class Indicators]|r Engine module loaded")
end
