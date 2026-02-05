-- ============================================================================
-- DRSpiralAnimation.lua - Isolated DR Spiral Animation Control Module
-- ============================================================================
-- Purpose: Controls the spiral/swipe animation and dark overlay opacity on DR icons
-- This module is completely isolated to prevent any conflicts with core DR functionality
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

local DRSpiral = {}
AC.DRSpiralAnimation = DRSpiral

-- ============================================================================
-- SPIRAL ANIMATION SETTINGS
-- ============================================================================

-- Apply spiral animation settings to a DR cooldown frame
function DRSpiral:ApplySettings(cooldownFrame)
    if not cooldownFrame then return end
    
    -- Get settings from database with safe fallbacks
    local db = AC.DB and AC.DB.profile and AC.DB.profile.diminishingReturns
    
    -- Default values if database isn't ready
    local enabled = true
    local opacity = 100
    
    -- Get actual values from database if available
    if db and db.spiralAnimation then
        local spiralSettings = db.spiralAnimation
        enabled = spiralSettings.enabled ~= false -- Default: true (enabled)
        opacity = spiralSettings.opacity or 100 -- Default: 100%
    end
    
    -- Apply spiral visibility
    if enabled then
        -- Spiral is enabled - show it with the specified opacity
        local alpha = opacity / 100 -- Convert percentage to alpha (0.01 to 1.0)
        cooldownFrame:SetSwipeColor(0, 0, 0, alpha)
        cooldownFrame:SetDrawSwipe(true)
    else
        -- Spiral is disabled - hide it completely
        cooldownFrame:SetDrawSwipe(false)
    end
end

-- ============================================================================
-- REFRESH ALL DR ICONS
-- ============================================================================

-- Refresh spiral animation settings on all visible DR icons
function DRSpiral:RefreshAllIcons()
    -- Get all arena frames
    local frames = AC.MasterFrameManager and AC.MasterFrameManager.frames
    if not frames then return end
    
    -- Loop through all frames and update their DR icons
    for i = 1, 3 do
        local frame = frames[i]
        if frame and frame.drIcons then
            for category, drIcon in pairs(frame.drIcons) do
                if drIcon and drIcon.cooldown and drIcon:IsShown() then
                    self:ApplySettings(drIcon.cooldown)
                end
            end
        end
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize the module (called when addon loads)
function DRSpiral:Initialize()
    -- Module initialized successfully
    -- Settings will be applied when DR icons are created
end

return DRSpiral
