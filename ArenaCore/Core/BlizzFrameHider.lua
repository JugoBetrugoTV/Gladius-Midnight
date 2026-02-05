-- =============================================================
-- File: Core/BlizzFrameHider.lua
-- ArenaCore Blizzard Frame Hider
-- Automatically hides default Blizzard arena frames (CompactArenaFrame)
-- Always enabled - no toggle needed
-- =============================================================

local AC = _G.ArenaCore
if not AC then return end

AC.BlizzFrameHider = AC.BlizzFrameHider or {}
local BlizzFrameHider = AC.BlizzFrameHider

-- State tracking
BlizzFrameHider.isInitialized = false

-- Hidden frame to parent Blizzard frames to (created once, never shown)
local hiddenFrame = CreateFrame("Frame")
hiddenFrame:Hide()

-- Event list for monitoring arena state
local events = {
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
    "ARENA_OPPONENT_UPDATE",
    "ARENA_PREP_OPPONENT_SPECIALIZATIONS",
    "PVP_MATCH_STATE_CHANGED"
}

-- Main function to hide Blizzard arena frames by reparenting to hidden frame
local function HideBlizzardFrames()
    if InCombatLockdown() then return end
    
    local instanceType = select(2, IsInInstance())
    if instanceType == "arena" then
        -- Reparent CompactArenaFrame and title to hidden frame
        if CompactArenaFrame then
            CompactArenaFrame:SetParent(hiddenFrame)
        end
        if CompactArenaFrameTitle then
            CompactArenaFrameTitle:SetParent(hiddenFrame)
        end
    end
end

-- Event handler
local function OnEvent(self, event, ...)
    HideBlizzardFrames()
    -- Also try one frame later to catch any delayed frame creation
    C_Timer.After(0, HideBlizzardFrames)
end

-- Initialize the frame hider (called automatically on addon load)
function BlizzFrameHider:Initialize()
    if self.isInitialized then return end
    
    -- Create event frame
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:SetScript("OnEvent", OnEvent)
    
    -- Register events
    for _, event in ipairs(events) do
        self.eventFrame:RegisterEvent(event)
    end
    
    -- Hook frame show events to catch them immediately
    if CompactArenaFrame then
        CompactArenaFrame:HookScript("OnLoad", HideBlizzardFrames)
        CompactArenaFrame:HookScript("OnShow", HideBlizzardFrames)
    end
    if CompactArenaFrameTitle then
        CompactArenaFrameTitle:HookScript("OnLoad", HideBlizzardFrames)
        CompactArenaFrameTitle:HookScript("OnShow", HideBlizzardFrames)
    end
    
    -- Initial hide attempt
    HideBlizzardFrames()
    
    self.isInitialized = true
end

-- Initialize on addon load
C_Timer.After(0.1, function()
    BlizzFrameHider:Initialize()
end)
