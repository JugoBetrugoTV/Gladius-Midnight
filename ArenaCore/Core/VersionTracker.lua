-- Core/VersionTracker.lua
-- Tracks addon version changes and auto-shows "What's New" window on updates

local AC = _G.ArenaCore
if not AC then return end

local VersionTracker = {}
AC.VersionTracker = VersionTracker

-- Initialize version tracking on ADDON_LOADED
local function OnAddonLoaded()
    -- Ensure we have a place to store version info in SavedVariables
    if not ArenaCoreDB then
        ArenaCoreDB = {}
    end
    
    if not ArenaCoreDB.versionTracking then
        ArenaCoreDB.versionTracking = {
            lastSeenVersion = nil,
            firstInstall = true
        }
    end
    
    local tracking = ArenaCoreDB.versionTracking
    local currentVersion = AC.Version or "0.9.2.3"
    
    -- Check if this is a new version
    local isNewVersion = false
    
    if tracking.firstInstall then
        -- First time install - don't show popup, just record version
        tracking.lastSeenVersion = currentVersion
        tracking.firstInstall = false
        -- No message - let existing login messages show
    elseif tracking.lastSeenVersion ~= currentVersion then
        -- Version changed - mark for auto-show
        isNewVersion = true
        print("|cff8B45FFArena Core:|r Updated to v" .. currentVersion .. "! Opening What's New...")
    end
    
    -- Store the flag for PLAYER_LOGIN to use
    AC._showWhatsNewOnLogin = isNewVersion
end

-- Show "What's New" window after UI is fully loaded
local function OnPlayerLogin()
    -- Wait a bit for UI to settle, then show if needed
    C_Timer.After(1.5, function()
        if AC._showWhatsNewOnLogin and AC.Vanity and AC.Vanity.ShowPatchNotes then
            -- Auto-show the What's New window
            AC.Vanity:ShowPatchNotes()
            
            -- Update last seen version
            if ArenaCoreDB and ArenaCoreDB.versionTracking then
                ArenaCoreDB.versionTracking.lastSeenVersion = AC.Version or "0.9.2.3"
            end
            
            -- Clear the flag
            AC._showWhatsNewOnLogin = false
        end
    end)
end

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ArenaCore" then
        OnAddonLoaded()
    elseif event == "PLAYER_LOGIN" then
        OnPlayerLogin()
    end
end)

-- Manual function to force show (for testing)
function VersionTracker:ForceShowWhatsNew()
    if AC.Vanity and AC.Vanity.ShowPatchNotes then
        AC.Vanity:ShowPatchNotes()
    end
end

-- Reset version tracking (for testing)
function VersionTracker:ResetVersionTracking()
    if ArenaCoreDB and ArenaCoreDB.versionTracking then
        ArenaCoreDB.versionTracking.lastSeenVersion = nil
        ArenaCoreDB.versionTracking.firstInstall = true
        print("|cff8B45FFArena Core:|r Version tracking reset. /reload to test.")
    end
end
