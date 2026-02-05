-- ============================================================================
-- TARGET HIGHLIGHT MODULE
-- ============================================================================
-- Shows frametargetoutline.tga texture around arena frames when targeted
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

local TargetHighlight = {}
AC.TargetHighlight = TargetHighlight

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local FADE_DURATION = 0.15  -- Fade in/out duration in seconds
local UPDATE_INTERVAL = 0.05  -- Animation update interval

-- ============================================================================
-- LOCAL VARIABLES
-- ============================================================================

local eventFrame = nil
local activeTarget = nil  -- Currently targeted arena unit
local animationTimers = {}  -- [unit] = {startTime, startAlpha, targetAlpha, duration}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function GetFrameForUnit(unit)
    -- Try MasterFrameManager first (primary system)
    if AC.MasterFrameManager and AC.MasterFrameManager.frames then
        for i = 1, 3 do
            local frame = AC.MasterFrameManager.frames[i]
            if frame and frame.unit == unit then
                return frame
            end
        end
    end
    
    -- Fallback to global arenaFrames array
    if AC.arenaFrames then
        for i = 1, 3 do
            local frame = AC.arenaFrames[i]
            if frame and frame.unit == unit then
                return frame
            end
        end
    end
    
    return nil
end

local function GetSettings()
    if AC.DB and AC.DB.profile and AC.DB.profile.targetHighlight then
        return AC.DB.profile.targetHighlight
    end
    -- Defaults if settings don't exist yet
    return {
        enabled = true,
        color = {r = 1, g = 0.7, b = 0, a = 1},  -- Gold/orange default
        fadeEnabled = true,
        fadeDuration = 0.15
    }
end

-- ============================================================================
-- ANIMATION SYSTEM (Smooth Fade In/Out)
-- ============================================================================

local function StartFadeAnimation(unit, targetAlpha)
    local frame = GetFrameForUnit(unit)
    if not frame or not frame.targetOutline then return end
    
    local settings = GetSettings()
    local duration = settings.fadeEnabled and (settings.fadeDuration or FADE_DURATION) or 0
    
    -- Instant change if fade disabled or duration is 0
    if duration <= 0 then
        frame.targetOutline:SetAlpha(targetAlpha)
        animationTimers[unit] = nil
        return
    end
    
    -- Start animation
    local currentAlpha = frame.targetOutline:GetAlpha()
    animationTimers[unit] = {
        startTime = GetTime(),
        startAlpha = currentAlpha,
        targetAlpha = targetAlpha,
        duration = duration
    }
end

local function UpdateAnimations()
    local currentTime = GetTime()
    
    for unit, anim in pairs(animationTimers) do
        local frame = GetFrameForUnit(unit)
        if frame and frame.targetOutline then
            local elapsed = currentTime - anim.startTime
            local progress = math.min(elapsed / anim.duration, 1.0)
            
            -- Smooth easing (ease-out)
            progress = 1 - math.pow(1 - progress, 3)
            
            local newAlpha = anim.startAlpha + (anim.targetAlpha - anim.startAlpha) * progress
            frame.targetOutline:SetAlpha(newAlpha)
            
            -- Animation complete
            if progress >= 1.0 then
                animationTimers[unit] = nil
            end
        else
            -- Frame doesn't exist, cancel animation
            animationTimers[unit] = nil
        end
    end
end

-- ============================================================================
-- TARGET TRACKING
-- ============================================================================

local function UpdateTargetHighlight()
    local settings = GetSettings()
    if not settings.enabled then return end
    
    -- REAL ARENA ONLY: Normal targeting logic
    local targetUnit
    if AC.Midnight and AC.Midnight.isMidnight then
        targetUnit = "target"
    else
        targetUnit = UnitGUID("target")
    end
    
    local newTarget = nil
    
    -- DEBUG: Show current target for debugging (DISABLED)
    --[[ 
    if targetUnit then
        if AC.Midnight and AC.Midnight.isMidnight then
            print("|cffFFA500[TargetHighlight]|r Current target unit:", targetUnit)
        else
            print("|cffFFA500[TargetHighlight]|r Current target GUID:", targetUnit)
        end
    else
        print("|cffFFA500[TargetHighlight]|r No target detected")
    end
    --]]
    
    -- Find which arena unit is targeted
    for i = 1, 3 do
        local arenaUnit = "arena" .. i
        if UnitExists(arenaUnit) then
            local isMatch
            if AC.Midnight and AC.Midnight.isMidnight then
                isMatch = UnitIsUnit(arenaUnit, targetUnit)
            else
                isMatch = UnitGUID(arenaUnit) == targetUnit
            end
            
            if isMatch then
                newTarget = arenaUnit
                -- DEBUG: print("|cffFFA500[TargetHighlight]|r MATCH FOUND:", newTarget)
                break
            end
        end
    end
    
    -- Target changed
    if newTarget ~= activeTarget then
        -- DEBUG: print("|cffFFA500[TargetHighlight]|r Target changed from", activeTarget or "nil", "to", newTarget or "nil")
        
        -- Fade out old target
        if activeTarget then
            -- DEBUG: print("|cffFFA500[TargetHighlight]|r Fading out old target:", activeTarget)
            StartFadeAnimation(activeTarget, 0)
        end
        
        -- Fade in new target
        if newTarget then
            local frame = GetFrameForUnit(newTarget)
            if frame and frame.targetOutline then
                -- Update color for all 4 edges
                local c = settings.color
                if frame.targetOutline.top then
                    frame.targetOutline.top:SetVertexColor(c.r, c.g, c.b, c.a)
                    frame.targetOutline.bottom:SetVertexColor(c.r, c.g, c.b, c.a)
                    frame.targetOutline.left:SetVertexColor(c.r, c.g, c.b, c.a)
                    frame.targetOutline.right:SetVertexColor(c.r, c.g, c.b, c.a)
                end
                
                -- Fade in
                -- DEBUG: print("|cffFFA500[TargetHighlight]|r Fading in new target:", newTarget)
                StartFadeAnimation(newTarget, 1.0)
            else
                -- DEBUG: print("|cffFFA500[TargetHighlight]|r Frame or outline missing!")
            end
        end
        
        activeTarget = newTarget
    else
        -- DEBUG: Show why no change occurred (DISABLED)
        --[[
        if activeTarget then
            print("|cffFFA500[TargetHighlight]|r No change - still targeting:", activeTarget)
        else
            print("|cffFFA500[TargetHighlight]|r No change - no active target")
        end
        --]]
    end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local function OnEvent(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        UpdateTargetHighlight()
        
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat - continue tracking
        UpdateTargetHighlight()
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat - continue tracking
        UpdateTargetHighlight()
        
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        -- Prep room - reset highlights
        activeTarget = nil
        for i = 1, 3 do
            StartFadeAnimation("arena" .. i, 0)
        end
        
    elseif event == "ARENA_OPPONENT_UPDATE" then
        -- Arena state changed - refresh
        C_Timer.After(0.1, UpdateTargetHighlight)
    end
end

-- ============================================================================
-- FRAME CREATION
-- ============================================================================

function TargetHighlight:CreateOutline(frame)
    if frame.targetOutline then
        return frame.targetOutline
    end
    
    -- Create container for border textures
    local container = CreateFrame("Frame", nil, frame)
    container:SetFrameLevel(frame:GetFrameLevel() + 10)  -- Above everything
    
    -- CRITICAL: Check if current theme has background insets (like The 1500 Special)
    -- If so, extend outline to sit on outer edge of background
    local outlineOffset = 0
    if AC.ArenaFrameThemes then
        local currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
        local theme = AC.ArenaFrameThemes.themes and AC.ArenaFrameThemes.themes[currentTheme]
        if theme and theme.background and theme.background.enabled and theme.background.insets then
            -- The 1500 Special has insets = {-2, 2, 2, -2} (extends 2px left/right)
            -- Extend outline by 4px to make it thicker and more visible
            outlineOffset = 4
        end
    end
    
    -- Position container to cover entire frame
    container:SetAllPoints(frame)
    
    -- CRITICAL FIX: Use 4 separate solid color textures for THICK, BRIGHT border (old working version)
    -- This creates a much more prominent target indicator than the thin frametargetoutline.tga
    -- Get thickness from database settings
    local borderThickness = 3  -- Default thickness
    if AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.sizing then
        borderThickness = AC.DB.profile.arenaFrames.sizing.targetBorderThickness or 3
    end
    local color = {1, 0.4, 0}  -- Vibrant orange color
    
    -- Create 4 border edges (top, bottom, left, right)
    local top = container:CreateTexture(nil, "OVERLAY", nil, 7)
    top:SetColorTexture(color[1], color[2], color[3], 1)
    top:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    top:SetHeight(borderThickness)
    
    local bottom = container:CreateTexture(nil, "OVERLAY", nil, 7)
    bottom:SetColorTexture(color[1], color[2], color[3], 1)
    bottom:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(borderThickness)
    
    local left = container:CreateTexture(nil, "OVERLAY", nil, 7)
    left:SetColorTexture(color[1], color[2], color[3], 1)
    left:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    left:SetWidth(borderThickness)
    
    local right = container:CreateTexture(nil, "OVERLAY", nil, 7)
    right:SetColorTexture(color[1], color[2], color[3], 1)
    right:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(borderThickness)
    
    -- Store references
    container.top = top
    container.bottom = bottom
    container.left = left
    container.right = right
    container:SetAlpha(0)  -- Hidden by default
    
    frame.targetOutline = container
    
    return container
end

function TargetHighlight:UpdateOutlineSize(frame)
    if not frame or not frame.targetOutline then return end
    
    -- Get current frame size
    local width = frame:GetWidth()
    local height = frame:GetHeight()
    
    -- Position outline to cover entire frame (outer edge)
    -- The texture itself should have transparent center with border on edges
    frame.targetOutline:ClearAllPoints()
    frame.targetOutline:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.targetOutline:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
end

function TargetHighlight:RefreshAll()
    -- Refresh all outlines (called when settings change)
    for i = 1, 3 do
        local frame = GetFrameForUnit("arena" .. i)
        if frame then
            self:UpdateOutlineSize(frame)
        end
    end
    
    -- Update current target (real arena only)
    UpdateTargetHighlight()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function TargetHighlight:Initialize()
    -- Create event frame
    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:SetScript("OnEvent", OnEvent)
        
        -- Register events
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
        eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    end
    
    -- Start animation ticker
    if not self.animationTicker then
        self.animationTicker = C_Timer.NewTicker(UPDATE_INTERVAL, UpdateAnimations)
    end
    
    -- CRITICAL: Create outlines for existing frames (retroactive creation)
    for i = 1, 3 do
        local frame = GetFrameForUnit("arena" .. i)
        if frame and not frame.targetOutline then
            self:CreateOutline(frame)
        end
    end
    
    -- Trigger initial update (will show border on arena3 in test mode)
    C_Timer.After(0.1, function()
        UpdateTargetHighlight()
    end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function TargetHighlight:Enable()
    local settings = GetSettings()
    settings.enabled = true
    self:RefreshAll()
end

function TargetHighlight:Disable()
    local settings = GetSettings()
    settings.enabled = false
    
    -- Hide all outlines
    for i = 1, 3 do
        StartFadeAnimation("arena" .. i, 0)
    end
    activeTarget = nil
end

function TargetHighlight:SetColor(r, g, b, a)
    local settings = GetSettings()
    settings.color = {r = r, g = g, b = b, a = a or 1}
    
    -- Update active target immediately
    if activeTarget then
        local frame = GetFrameForUnit(activeTarget)
        if frame and frame.targetOutline and frame.targetOutline.top then
            frame.targetOutline.top:SetVertexColor(r, g, b, a or 1)
            frame.targetOutline.bottom:SetVertexColor(r, g, b, a or 1)
            frame.targetOutline.left:SetVertexColor(r, g, b, a or 1)
            frame.targetOutline.right:SetVertexColor(r, g, b, a or 1)
        end
    end
end

function TargetHighlight:SetFadeDuration(duration)
    local settings = GetSettings()
    settings.fadeDuration = duration
end

function TargetHighlight:SetFadeEnabled(enabled)
    local settings = GetSettings()
    settings.fadeEnabled = enabled
end

-- ============================================================================
-- AUTO-INITIALIZE
-- ============================================================================

-- Auto-initialize when ArenaCore is ready
if AC.MasterFrameManager then
    C_Timer.After(0.5, function()
        TargetHighlight:Initialize()
    end)
else
    -- Wait for MasterFrameManager to be ready
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("ADDON_LOADED")
    initFrame:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "ArenaCore" and AC.MasterFrameManager then
            C_Timer.After(0.5, function()
                TargetHighlight:Initialize()
            end)
            self:UnregisterAllEvents()
        end
    end)
end

-- Debug command removed for production
