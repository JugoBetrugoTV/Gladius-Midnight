-- ============================================================================
-- ARENACORE ICON GLOW SYSTEM
-- ============================================================================
-- Standalone module for adding glow effects to icons
-- Uses WoW's built-in bag glow textures for professional appearance
-- 
-- Features:
-- - Dual animation system (flash + pulsing glow)
-- - Configurable colors (blue, purple, white, etc.)
-- - Clean API for easy integration
-- - Zero dependencies on other modules

local AC = _G.ArenaCore
if not AC then return end

AC.IconGlow = AC.IconGlow or {}
local IG = AC.IconGlow

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

-- Available glow colors (WoW atlas textures)
IG.GLOW_COLORS = {
    BLUE = "bags-glow-blue",      -- Default blue glow
    PURPLE = "bags-glow-purple",  -- ArenaCore theme
    WHITE = "bags-glow-white",    -- Clean/bright
    GREEN = "bags-glow-green",    -- Success/positive
    ORANGE = "bags-glow-orange",  -- Warning/attention
}

-- Flash texture (always white for maximum visibility)
IG.FLASH_ATLAS = "bags-glow-flash"

-- Animation timings (seconds)
IG.FLASH_DURATION = 1.0
IG.PULSE_DURATION = 1.0  -- Per pulse (3 pulses total = 3 seconds)

-- ============================================================================
-- CORE FUNCTIONS
-- ============================================================================

--- Setup glow textures and animations on an icon frame
--- Call this once when creating the icon
--- @param icon Frame - The icon frame to add glow to
--- @param glowColor string - Optional color key from GLOW_COLORS (default: PURPLE)
function IG:SetupIconGlow(icon, glowColor)
    if not icon then return end
    
    -- Default to ArenaCore purple theme
    glowColor = glowColor or "PURPLE"
    local glowAtlas = self.GLOW_COLORS[glowColor] or self.GLOW_COLORS.PURPLE
    
    -- Create flash texture (white quick fade)
    icon.glowFlash = icon:CreateTexture(nil, "OVERLAY", nil, 1)
    icon.glowFlash:SetAtlas(self.FLASH_ATLAS)
    icon.glowFlash:SetAllPoints(icon)
    icon.glowFlash:SetBlendMode("ADD")
    icon.glowFlash:SetAlpha(0)
    
    -- Create glow texture (colored pulsing)
    icon.glowTexture = icon:CreateTexture(nil, "OVERLAY", nil, 1)
    icon.glowTexture:SetAtlas(glowAtlas)
    icon.glowTexture:SetAllPoints(icon)
    icon.glowTexture:SetBlendMode("ADD")
    icon.glowTexture:SetAlpha(0)
    
    -- Create flash animation (1 second fade out)
    icon.glowFlashAnim = icon:CreateAnimationGroup()
    icon.glowFlashAnim:SetToFinalAlpha(true)
    
    local flashAlpha = icon.glowFlashAnim:CreateAnimation("Alpha")
    flashAlpha:SetTarget(icon.glowFlash)
    flashAlpha:SetDuration(self.FLASH_DURATION)
    flashAlpha:SetFromAlpha(1)
    flashAlpha:SetToAlpha(0)
    flashAlpha:SetSmoothing("OUT")
    
    -- Create glow animation (3 pulses: bright->dim->bright->fade)
    icon.glowPulseAnim = icon:CreateAnimationGroup()
    icon.glowPulseAnim:SetToFinalAlpha(true)
    
    -- Pulse 1: Bright to dim
    local pulse1 = icon.glowPulseAnim:CreateAnimation("Alpha")
    pulse1:SetTarget(icon.glowTexture)
    pulse1:SetDuration(self.PULSE_DURATION)
    pulse1:SetOrder(1)
    pulse1:SetFromAlpha(1)
    pulse1:SetToAlpha(0.4)
    pulse1:SetSmoothing("NONE")
    
    -- Pulse 2: Dim to bright
    local pulse2 = icon.glowPulseAnim:CreateAnimation("Alpha")
    pulse2:SetTarget(icon.glowTexture)
    pulse2:SetDuration(self.PULSE_DURATION)
    pulse2:SetOrder(2)
    pulse2:SetFromAlpha(0.4)
    pulse2:SetToAlpha(1)
    pulse2:SetSmoothing("NONE")
    
    -- Pulse 3: Bright to fade out
    local pulse3 = icon.glowPulseAnim:CreateAnimation("Alpha")
    pulse3:SetTarget(icon.glowTexture)
    pulse3:SetDuration(self.PULSE_DURATION)
    pulse3:SetOrder(3)
    pulse3:SetFromAlpha(1)
    pulse3:SetToAlpha(0)
    pulse3:SetSmoothing("NONE")
    
    -- Mark icon as glow-enabled
    icon._hasIconGlow = true
end

--- Play the glow animation on an icon
--- Call this when you want the icon to glow (e.g., when interrupt appears)
--- @param icon Frame - The icon frame with glow setup
--- @param force boolean - Optional: play even if already playing
function IG:PlayGlow(icon, force)
    if not icon or not icon._hasIconGlow then return end
    
    -- Check if animations are already playing (unless forced)
    if not force then
        if icon.glowFlashAnim and icon.glowFlashAnim:IsPlaying() then return end
        if icon.glowPulseAnim and icon.glowPulseAnim:IsPlaying() then return end
    end
    
    -- Stop any existing animations
    self:StopGlow(icon)
    
    -- Play both animations simultaneously
    if icon.glowFlashAnim then
        icon.glowFlashAnim:Play()
    end
    
    if icon.glowPulseAnim then
        icon.glowPulseAnim:Play()
    end
end

--- Stop the glow animation on an icon
--- @param icon Frame - The icon frame with glow setup
function IG:StopGlow(icon)
    if not icon or not icon._hasIconGlow then return end
    
    -- Stop animations
    if icon.glowFlashAnim and icon.glowFlashAnim:IsPlaying() then
        icon.glowFlashAnim:Stop()
    end
    
    if icon.glowPulseAnim and icon.glowPulseAnim:IsPlaying() then
        icon.glowPulseAnim:Stop()
    end
    
    -- Reset alpha to 0
    if icon.glowFlash then
        icon.glowFlash:SetAlpha(0)
    end
    
    if icon.glowTexture then
        icon.glowTexture:SetAlpha(0)
    end
end

--- Change the glow color on an existing icon
--- @param icon Frame - The icon frame with glow setup
--- @param glowColor string - Color key from GLOW_COLORS
function IG:SetGlowColor(icon, glowColor)
    if not icon or not icon._hasIconGlow or not icon.glowTexture then return end
    
    local glowAtlas = self.GLOW_COLORS[glowColor] or self.GLOW_COLORS.PURPLE
    icon.glowTexture:SetAtlas(glowAtlas)
end

--- Check if an icon has glow enabled
--- @param icon Frame - The icon frame to check
--- @return boolean
function IG:HasGlow(icon)
    return icon and icon._hasIconGlow == true
end

--- Check if glow is currently playing on an icon
--- @param icon Frame - The icon frame to check
--- @return boolean
function IG:IsGlowing(icon)
    if not icon or not icon._hasIconGlow then return false end
    
    local flashPlaying = icon.glowFlashAnim and icon.glowFlashAnim:IsPlaying()
    local pulsePlaying = icon.glowPulseAnim and icon.glowPulseAnim:IsPlaying()
    
    return flashPlaying or pulsePlaying
end

-- ============================================================================
-- CONVENIENCE FUNCTIONS
-- ============================================================================

--- Setup and immediately play glow on an icon (one-shot)
--- @param icon Frame - The icon frame
--- @param glowColor string - Optional color key
function IG:SetupAndPlay(icon, glowColor)
    self:SetupIconGlow(icon, glowColor)
    self:PlayGlow(icon)
end

--- Batch setup glow on multiple icons
--- @param icons table - Array of icon frames
--- @param glowColor string - Optional color key
function IG:SetupBatch(icons, glowColor)
    if not icons then return end
    
    for _, icon in ipairs(icons) do
        self:SetupIconGlow(icon, glowColor)
    end
end

--- Batch play glow on multiple icons
--- @param icons table - Array of icon frames
function IG:PlayBatch(icons)
    if not icons then return end
    
    for _, icon in ipairs(icons) do
        self:PlayGlow(icon)
    end
end

--- Batch stop glow on multiple icons
--- @param icons table - Array of icon frames
function IG:StopBatch(icons)
    if not icons then return end
    
    for _, icon in ipairs(icons) do
        self:StopGlow(icon)
    end
end

-- ============================================================================
-- DEBUG HELPERS
-- ============================================================================

--- Print glow system status
function IG:DebugStatus()
    print("|cffB266FFArenaCore IconGlow:|r System Status")
    print("  Available Colors:", table.concat(tInvert(self.GLOW_COLORS), ", "))
    print("  Flash Duration:", self.FLASH_DURATION .. "s")
    print("  Pulse Duration:", self.PULSE_DURATION .. "s (x3 = " .. (self.PULSE_DURATION * 3) .. "s total)")
end

--- Test glow on a frame (for development)
--- @param testFrame Frame - Optional frame to test on (creates one if nil)
function IG:Test(testFrame)
    if not testFrame then
        -- Create test button
        testFrame = CreateFrame("Button", "ACGlowTest", UIParent)
        testFrame:SetSize(64, 64)
        testFrame:SetPoint("CENTER")
        
        -- Add icon texture
        local icon = testFrame:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints()
        icon:SetTexture(136235) -- Kick spell icon
        
        -- Add border
        local border = testFrame:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints()
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        
        print("|cffB266FFArenaCore IconGlow:|r Test frame created at screen center")
    end
    
    -- Setup and play glow
    self:SetupIconGlow(testFrame, "PURPLE")
    self:PlayGlow(testFrame)
    
    print("|cffB266FFArenaCore IconGlow:|r Playing test glow (3 seconds)")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Module loaded (debug removed for clean user experience)
-- print("|cffB266FFArenaCore:|r IconGlow module loaded")

-- Slash command for testing
SLASH_ACGLOW1 = "/acglow"
SlashCmdList["ACGLOW"] = function(msg)
    if msg == "test" then
        AC.IconGlow:Test()
    elseif msg == "status" then
        AC.IconGlow:DebugStatus()
    else
        print("|cffB266FFArenaCore IconGlow:|r Commands:")
        print("  /acglow test - Create test icon with glow")
        print("  /acglow status - Show system status")
    end
end
