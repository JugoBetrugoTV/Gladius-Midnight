-- ============================================================================
-- ARENA FRAME TOOLTIPS MODULE
-- ============================================================================
-- Shows player tooltips when hovering over arena frames
-- Pattern based on standard hover system with WoW's GameTooltip API
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

local Tooltips = {}
AC.ArenaFrameTooltips = Tooltips

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local TOOLTIP_ANCHOR = "ANCHOR_RIGHT"  -- Tooltip appears to the right of frame

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function GetSettings()
    if AC.DB and AC.DB.profile and AC.DB.profile.arenaTooltips then
        return AC.DB.profile.arenaTooltips
    end
    -- Defaults if settings don't exist yet
    return {
        enabled = true,
        showInCombat = true
    }
end

-- ============================================================================
-- TOOLTIP HANDLERS
-- ============================================================================

local function OnEnter(self)
    local settings = GetSettings()
    if not settings.enabled then return end
    
    -- Optional: Hide tooltips during combat
    if not settings.showInCombat and InCombatLockdown() then return end
    
    local unit = self.unit
    if not unit or not UnitExists(unit) then return end
    
    -- Set tooltip owner and anchor
    GameTooltip:SetOwner(self, TOOLTIP_ANCHOR)
    
    -- Use WoW's built-in unit tooltip (shows name, health, class, spec, etc.)
    GameTooltip:SetUnit(unit)
    
    -- Show the tooltip
    GameTooltip:Show()
end

local function OnLeave(self)
    -- Hide the tooltip when mouse leaves
    GameTooltip:Hide()
end

-- ============================================================================
-- FRAME SETUP
-- ============================================================================

function Tooltips:EnableTooltip(frame)
    if not frame then return end
    
    -- CRITICAL: Cannot call EnableMouse during combat lockdown (UNLESS in test mode)
    -- Test mode frames are safe to modify during combat since they're not secure
    local AC = _G.ArenaCore
    if InCombatLockdown() and not (AC and AC.testModeEnabled) then
        return
    end
    
    -- Set up mouse enter/leave scripts
    frame:SetScript("OnEnter", OnEnter)
    frame:SetScript("OnLeave", OnLeave)
    
    -- Ensure frame can receive mouse events
    frame:EnableMouse(true)
end

function Tooltips:DisableTooltip(frame)
    if not frame then return end
    
    -- Remove scripts
    frame:SetScript("OnEnter", nil)
    frame:SetScript("OnLeave", nil)
end

function Tooltips:RefreshAll()
    -- CRITICAL: If in combat, defer until combat ends (UNLESS in test mode)
    -- Test mode frames are safe to modify during combat since they're not secure
    local AC = _G.ArenaCore
    if InCombatLockdown() and not (AC and AC.testModeEnabled) then
        -- Register one-time event to refresh after combat
        local combatFrame = CreateFrame("Frame")
        combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        combatFrame:SetScript("OnEvent", function(self)
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            if Tooltips and Tooltips.RefreshAll then
                Tooltips:RefreshAll()
            end
        end)
        return
    end
    
    local settings = GetSettings()
    
    -- Get all arena frames
    local frames = {}
    if AC.MasterFrameManager and AC.MasterFrameManager.frames then
        frames = AC.MasterFrameManager.frames
    elseif AC.arenaFrames then
        frames = AC.arenaFrames
    end
    
    -- Enable or disable tooltips based on settings
    for i = 1, 3 do
        local frame = frames[i]
        if frame then
            if settings.enabled then
                self:EnableTooltip(frame)
            else
                self:DisableTooltip(frame)
            end
        end
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function Tooltips:Initialize()
    -- Wait a bit for frames to be created
    C_Timer.After(0.5, function()
        self:RefreshAll()
    end)
    
    -- Hook into frame creation to add tooltips to new frames
    if AC.MasterFrameManager and AC.MasterFrameManager.CreateArenaFrame then
        local originalCreate = AC.MasterFrameManager.CreateArenaFrame
        AC.MasterFrameManager.CreateArenaFrame = function(self, index)
            local frame = originalCreate(self, index)
            if frame then
                C_Timer.After(0.1, function()
                    Tooltips:EnableTooltip(frame)
                end)
            end
            return frame
        end
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function Tooltips:Enable()
    local settings = GetSettings()
    settings.enabled = true
    self:RefreshAll()
end

function Tooltips:Disable()
    local settings = GetSettings()
    settings.enabled = false
    self:RefreshAll()
end

function Tooltips:SetShowInCombat(enabled)
    local settings = GetSettings()
    settings.showInCombat = enabled
end

-- ============================================================================
-- AUTO-INITIALIZE
-- ============================================================================

-- Initialize when ArenaCore is ready
if AC.MasterFrameManager then
    C_Timer.After(1.0, function()
        Tooltips:Initialize()
    end)
else
    -- Wait for MasterFrameManager to be ready
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("ADDON_LOADED")
    initFrame:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "ArenaCore" and AC.MasterFrameManager then
            C_Timer.After(1.0, function()
                Tooltips:Initialize()
            end)
            self:UnregisterAllEvents()
        end
    end)
end
