-- ============================================================================
-- ArenaCore - Immunity Tracker
-- ============================================================================
-- Tracks enemy immunity buffs (magic-only and total immunities) and displays
-- health bar glow effects to warn players not to waste cooldowns.
-- 
-- Integrates with the Absorbs feature (same checkbox in More Goodies).
-- Green glow = Magic immunity only
-- White glow = Total immunity (Physical + Magic)
-- ============================================================================

local _, AC = ...

-- CRITICAL: Use global ArenaCore table to ensure same namespace as ArenaCore.lua
if not _G.ArenaCore then
    _G.ArenaCore = AC
end
local AC = _G.ArenaCore

-- Create immunity tracker module
AC.ImmunityTracker = {}
local IT = AC.ImmunityTracker

-- Delayed confirmation (chat might not be ready immediately)
-- DEBUG: Disabled to reduce chat spam
-- C_Timer.After(0.5, function()
--     print("|cff00FFFF[ImmunityTracker]|r Module file loaded, AC.ImmunityTracker created on global table")
-- end)

-- ============================================================================
-- IMMUNITY SPELL DATABASES
-- ============================================================================

-- Magic-Specific Immunities (GREEN glow)
IT.MAGIC_IMMUNITIES = {
    -- Rogue - Cloak of Shadows
    [31224] = true,
    
    -- Paladin - Blessing of Spellwarding
    [204018] = true,
    
    -- Death Knight - Anti-Magic Shell
    [48707] = true,
    
    -- Warlock - Nether Ward
    [212295] = true,
    
    -- Priest - Dispersion (90% damage reduction, effectively immune)
    [47585] = true,
    
    -- Priest - Greater Fade (magic immunity talent)
    [213602] = true,
    
    -- Shaman - Grounding Totem (spell reflect, acts as immunity)
    [204336] = true,
}

-- Total Immunities - Physical + Magic (WHITE glow)
IT.TOTAL_IMMUNITIES = {
    -- Paladin - Divine Shield
    [642] = true,
    
    -- Mage - Ice Block
    [45438] = true,
    
    -- Hunter - Aspect of the Turtle
    [186265] = true,
    
    -- Demon Hunter (Havoc) - Netherwalk
    [196555] = true,
    
    -- Paladin - Blessing of Protection (physical immunity)
    [1022] = true,
    
    -- Rogue - Evasion (with Elusiveness talent - near total immunity)
    -- Note: Only shows if talented, but safe to include
    [5277] = false, -- Disabled by default (not true immunity without talent)
}

-- ============================================================================
-- GLOW EFFECT CREATION
-- ============================================================================

-- Create immunity glow texture on health bar
function IT:CreateImmunityGlow(frame)
    if not frame or not frame.healthBar then 
        if IT.DEBUG_ENABLED then
            print("|cffFF0000[ImmunityTracker]|r CreateImmunityGlow: frame or healthBar is nil!")
        end
        return 
    end
    if frame.immunityGlow then 
        if IT.DEBUG_ENABLED then
            print("|cffFFAA00[ImmunityTracker]|r CreateImmunityGlow: immunityGlow already exists")
        end
        return 
    end -- Already exists
    
    if IT.DEBUG_ENABLED then
        print("|cff00FF00[ImmunityTracker]|r Creating immunity glow for frame...")
    end
    
    -- CRITICAL FIX: Create glow frame on MEDIUM strata (like absorb bar)
    -- This ensures it's visible above health bar which is on BACKGROUND strata
    
    -- Create a frame to hold the glow texture at proper strata
    frame.immunityGlowFrame = CreateFrame("Frame", nil, frame)
    frame.immunityGlowFrame:SetFrameStrata("MEDIUM")
    frame.immunityGlowFrame:SetFrameLevel(frame:GetFrameLevel() + 20) -- Above absorb bar (+15)
    frame.immunityGlowFrame:SetAllPoints(frame.healthBar)
    
    -- Create the glow texture on the MEDIUM strata frame
    frame.immunityGlow = frame.immunityGlowFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    
    -- Use a simple border texture that tiles properly
    frame.immunityGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.immunityGlow:SetBlendMode("ADD")
    
    -- DYNAMIC: Calculate glow size based on health bar dimensions
    local healthBarWidth = frame.healthBar:GetWidth() or 227
    local healthBarHeight = frame.healthBar:GetHeight() or 28
    
    -- Create a border effect by making it slightly larger than the health bar
    local borderSize = 3 -- 3 pixel border thickness
    
    frame.immunityGlow:SetPoint("TOPLEFT", frame.immunityGlowFrame, "TOPLEFT", -borderSize, borderSize)
    frame.immunityGlow:SetPoint("BOTTOMRIGHT", frame.immunityGlowFrame, "BOTTOMRIGHT", borderSize, -borderSize)
    
    -- Create inner cutout to make it a border (not a filled rectangle)
    frame.immunityGlowInner = frame.immunityGlowFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
    frame.immunityGlowInner:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.immunityGlowInner:SetVertexColor(0, 0, 0, 1)
    frame.immunityGlowInner:SetBlendMode("BLEND")
    frame.immunityGlowInner:SetAllPoints(frame.immunityGlowFrame)
    frame.immunityGlowInner:Hide()
    
    -- DEBUG: print("|cff00FF00[ImmunityTracker]|r Glow size: Width=" .. healthBarWidth .. ", Height=" .. healthBarHeight .. ", BorderSize=" .. borderSize)
    
    frame.immunityGlow:Hide()
    
    -- DEBUG: print("|cff00FF00[ImmunityTracker]|r Created immunity glow for frame")
    
    -- Animation for pulsing effect (faster and more dramatic)
    frame.immunityGlowAnim = frame.immunityGlow:CreateAnimationGroup()
    
    local fadeOut = frame.immunityGlowAnim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1.0)
    fadeOut:SetToAlpha(0.4)
    fadeOut:SetDuration(0.5)
    fadeOut:SetSmoothing("IN_OUT")
    
    local fadeIn = frame.immunityGlowAnim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.4)
    fadeIn:SetToAlpha(1.0)
    fadeIn:SetDuration(0.5)
    fadeIn:SetSmoothing("IN_OUT")
    fadeIn:SetStartDelay(0.5)
    
    frame.immunityGlowAnim:SetLooping("REPEAT")
    
    if IT.DEBUG_ENABLED then
        print("|cff00FF00[ImmunityTracker]|r ✅ Successfully created immunity glow and animation!")
    end
end

-- ============================================================================
-- IMMUNITY DETECTION
-- ============================================================================

-- Debug flag (toggle with /ac immunitydebug)
IT.DEBUG_ENABLED = false

-- Check if unit has any immunity buffs and return immunity type
-- Returns: "magic", "total", or nil
function IT:CheckImmunity(unit)
    -- Midnight compatibility: Disable immunity tracking in Midnight due to API restrictions
    if AC.Midnight and AC.Midnight.isMidnight then
        if not self.disabledWarningShown then
            print("|cffFF0000[ImmunityTracker]|r Disabled in Midnight due to API restrictions")
            self.disabledWarningShown = true
        end
        return nil
    end
    
    if not unit or not UnitExists(unit) then return nil end
    
    -- Scan all buffs on the unit
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetBuffDataByIndex(unit, i)
        if not auraData then break end
        
        local spellId = auraData.spellId
        
        -- Check for total immunity first (higher priority)
        if spellId and IT.TOTAL_IMMUNITIES[spellId] then
            if IT.DEBUG_ENABLED then
                local spellName = C_Spell.GetSpellName(spellId) or "Unknown"
                print("|cffFFFFFF[ImmunityTracker]|r TOTAL IMMUNITY detected on", unit, "- Spell:", spellName, "(", spellId, ")")
            end
            return "total"
        end
        
        -- Check for magic immunity
        if spellId and IT.MAGIC_IMMUNITIES[spellId] then
            if IT.DEBUG_ENABLED then
                local spellName = C_Spell.GetSpellName(spellId) or "Unknown"
                print("|cff00FF00[ImmunityTracker]|r MAGIC IMMUNITY detected on", unit, "- Spell:", spellName, "(", spellId, ")")
            end
            return "magic"
        end
    end
    
    return nil
end

-- ============================================================================
-- GLOW UPDATE LOGIC
-- ============================================================================

-- Update immunity glow for a specific frame
function IT:UpdateImmunityGlow(frame, unit)
    if not frame or not frame.healthBar then 
        if IT.DEBUG_ENABLED then
            print("|cffFF0000[ImmunityTracker]|r UpdateImmunityGlow: frame or healthBar is nil!")
        end
        return 
    end
    
    -- CRITICAL FIX: Always ensure glow exists before trying to use it
    -- This handles cases where Initialize() was called before frames were created
    if not frame.immunityGlow then
        if IT.DEBUG_ENABLED then
            print("|cffFFAA00[ImmunityTracker]|r Creating immunity glow for frame (was missing)")
        end
        self:CreateImmunityGlow(frame)
    end
    
    -- Double-check glow was created successfully
    if not frame.immunityGlow then
        if IT.DEBUG_ENABLED then
            print("|cffFF0000[ImmunityTracker]|r FAILED to create immunity glow!")
        end
        return
    end
    
    -- Check if absorbs feature is enabled (immunity uses same checkbox)
    local absorbsEnabled = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies 
                          and AC.DB.profile.moreGoodies.absorbs 
                          and AC.DB.profile.moreGoodies.absorbs.enabled
    
    if IT.DEBUG_ENABLED then
        print("|cffFFAA00[ImmunityTracker]|r Absorbs feature enabled:", tostring(absorbsEnabled))
    end
    
    if not absorbsEnabled then
        -- Feature disabled, hide glow
        frame.immunityGlow:Hide()
        if frame.immunityGlowAnim then
            frame.immunityGlowAnim:Stop()
        end
        if IT.DEBUG_ENABLED then
            print("|cffFF0000[ImmunityTracker]|r Absorbs feature DISABLED - immunity glow hidden")
        end
        return
    end
    
    -- Check for immunity
    local immunityType = self:CheckImmunity(unit)
    
    if IT.DEBUG_ENABLED and immunityType then
        print("|cffFFAA00[ImmunityTracker]|r Immunity type for", unit, ":", immunityType)
    end
    
    if immunityType then
        -- Set color based on immunity type using SetVertexColor for texture tinting
        -- Matches absorb system colors for consistency
        if immunityType == "magic" then
            -- MAXIMUM SATURATION BRIGHT GREEN for magic immunity (matches absorb green)
            frame.immunityGlow:SetVertexColor(0, 1, 0, 1) -- Pure bright green (0, 255, 0)
            
            -- CRITICAL FIX: Show green absorb overlay for visual consistency (safe in combat)
            if frame.totalAbsorbOverlay and frame.totalAbsorbOverlayFrame then
                -- Ensure HIGH strata for visibility
                frame.totalAbsorbOverlayFrame:SetFrameStrata("HIGH")
                frame.totalAbsorbOverlayFrame:SetFrameLevel(frame:GetFrameLevel() + 50)
                frame.totalAbsorbOverlay:SetVertexColor(0.35, 0.95, 0.35) -- Green tint
                frame.totalAbsorbOverlay:SetAlpha(1.0) -- Full opacity
                frame.totalAbsorbOverlay:Show()
                
                -- DEBUG: Track when overlay is shown for immunity
                if IT.DEBUG_ENABLED then
                    print("|cff00FF00[IMMUNITY DEBUG]|r Showing shield overlay for MAGIC immunity on " .. unit)
                end
            end
        elseif immunityType == "total" then
            -- PURE WHITE for total immunity (maximum brightness)
            frame.immunityGlow:SetVertexColor(1, 1, 1, 1) -- Pure white (255, 255, 255)
            
            -- CRITICAL FIX: Show white absorb overlay for visual consistency (safe in combat)
            if frame.totalAbsorbOverlay and frame.totalAbsorbOverlayFrame then
                -- Ensure HIGH strata for visibility
                frame.totalAbsorbOverlayFrame:SetFrameStrata("HIGH")
                frame.totalAbsorbOverlayFrame:SetFrameLevel(frame:GetFrameLevel() + 50)
                frame.totalAbsorbOverlay:SetVertexColor(1, 1, 1) -- White tint
                frame.totalAbsorbOverlay:SetAlpha(1.0) -- Full opacity
                frame.totalAbsorbOverlay:Show()
                
                -- DEBUG: Track when overlay is shown for total immunity
                if IT.DEBUG_ENABLED then
                    print("|cffFFFFFF[IMMUNITY DEBUG]|r Showing shield overlay for TOTAL immunity on " .. unit)
                end
            end
            
            -- DEBUG: print("|cffFFFFFF[ImmunityTracker]|r Applied WHITE glow + absorb overlay for total immunity")
        end
        
        -- CRITICAL FIX: Show and animate border glow (safe in combat - custom frames)
        frame.immunityGlow:Show()
        if frame.immunityGlowInner then
            frame.immunityGlowInner:Show()
        end
        if frame.immunityGlowAnim and not frame.immunityGlowAnim:IsPlaying() then
            frame.immunityGlowAnim:Play()
        end
    else
        -- No immunity, hide glow only
        frame.immunityGlow:Hide()
        if frame.immunityGlowInner then
            frame.immunityGlowInner:Hide()
        end
        if frame.immunityGlowAnim then
            frame.immunityGlowAnim:Stop()
        end
        
        -- NOTE: ImmunityTracker no longer touches absorb overlay - that's handled by Absorbs module
        -- This prevents conflicts and false positives
    end
end

-- ============================================================================
-- INTEGRATION WITH ARENACORE
-- ============================================================================

-- Initialize immunity tracking for all arena frames
function IT:Initialize()
    -- Create glows for all existing frames
    if AC.FrameManager and AC.FrameManager.frames then
        for i = 1, 3 do
            local frame = AC.FrameManager.frames[i]
            if frame then
                self:CreateImmunityGlow(frame)
            end
        end
    end
end

-- Refresh all immunity glows (called when settings change)
function IT:RefreshAll()
    if not AC.FrameManager or not AC.FrameManager.frames then return end
    
    for i = 1, 3 do
        local frame = AC.FrameManager.frames[i]
        if frame then
            local unit = "arena" .. i
            self:UpdateImmunityGlow(frame, unit)
        end
    end
end

-- Hide all immunity glows (called when feature is disabled)
function IT:HideAll()
    if not AC.FrameManager or not AC.FrameManager.frames then return end
    
    for i = 1, 3 do
        local frame = AC.FrameManager.frames[i]
        if frame and frame.immunityGlow then
            frame.immunityGlow:Hide()
            if frame.immunityGlowAnim then
                frame.immunityGlowAnim:Stop()
            end
        end
    end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

-- Register for aura events to detect immunity changes
function IT:RegisterEvents()
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:SetScript("OnEvent", function(_, event, ...)
            self:OnEvent(event, ...)
        end)
    end
    
    -- Register for unit aura updates
    self.eventFrame:RegisterUnitEvent("UNIT_AURA", "arena1", "arena2", "arena3")
end

-- Handle events
function IT:OnEvent(event, unit)
    if event == "UNIT_AURA" then
        -- Find the frame for this unit
        local arenaIndex = tonumber(unit:match("arena(%d)"))
        if arenaIndex and AC.FrameManager and AC.FrameManager.frames then
            local frame = AC.FrameManager.frames[arenaIndex]
            if frame then
                self:UpdateImmunityGlow(frame, unit)
            end
        end
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Auto-initialize when ArenaCore loads
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, function()
            IT:Initialize()
            IT:RegisterEvents()
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

-- Also initialize immediately on file load for test mode
-- DEBUG: Disabled to reduce chat spam
-- C_Timer.After(0.1, function()
--     if AC.ImmunityTracker then
--         print("|cffA855F7ArenaCore:|r Immunity Tracker loaded and ready!")
--     end
-- end)
