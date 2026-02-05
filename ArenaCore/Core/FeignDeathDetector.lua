-- ======================================================================
--  Core/FeignDeathDetector.lua
--  Detects Hunter Feign Death to prevent users from being fooled
--  Uses UnitIsFeignDeath API + aura fallback for reliable detection
-- ======================================================================

local AC = _G.ArenaCore
if not AC then return end

-- Feign Death detection module
AC.FeignDeathDetector = {}
local FD = AC.FeignDeathDetector

-- Constants
local FEIGN_SPELL_ID = 5384
local FEIGN_SPELL_NAME = GetSpellName and GetSpellName(FEIGN_SPELL_ID) or (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(FEIGN_SPELL_ID))
local ARENA_UNITS = {"arena1", "arena2", "arena3"}
local CONFIRM_MS = 150  -- Debounce time to avoid flicker

--- Disabled startup message for end users
-- if FEIGN_SPELL_NAME then
--     print("[FeignDeathDetector] Loaded Feign Death spell name: " .. FEIGN_SPELL_NAME)
-- else
--     print("|cffFF0000[FeignDeathDetector] ERROR: Could not load Feign Death spell name!|r")
-- end

-- State tracking
local feignState = {}  -- [unit] = { isFeign=bool, tLast=timestamp, pending=bool, tPend=timestamp }

-- Get current time in milliseconds
local function Now()
    return GetTimePreciseSec() * 1000
end

-- Check if unit is feigning death
local function IsFeign(unit)
    -- CRITICAL FIX: Only check hunters
    local _, class = UnitClass(unit)
    if class ~= "HUNTER" then
        return false
    end
    
    -- PRIMARY METHOD: Use AuraUtil.FindAuraByName
    -- This is the most reliable method
    if FEIGN_SPELL_NAME and AuraUtil and AuraUtil.FindAuraByName then
        local auraData = AuraUtil.FindAuraByName(FEIGN_SPELL_NAME, unit, "HELPFUL")
        if auraData then
            return true
        end
    end
    
    -- FALLBACK 1: Use UnitIsFeignDeath API
    if UnitIsFeignDeath and UnitIsFeignDeath(unit) then
        return true 
    end
    
    -- FALLBACK 2: Check for Feign Death aura by spell ID
    if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellID then
        local aura = C_UnitAuras.GetAuraDataBySpellID(unit, FEIGN_SPELL_ID, "HELPFUL")
        if aura then
            return true
        end
    end
    
    return false
end

-- Update feign death state for a unit with debounce
local function UpdateUnit(unit, force)
    if not UnitExists(unit) then return end
    
    local t = Now()
    local was = feignState[unit] and feignState[unit].isFeign or false
    local now = IsFeign(unit)
    
    -- Initialize state record if needed
    local rec = feignState[unit] or { isFeign=false, tLast=t }
    
    -- Debounce: only commit change if it persists for CONFIRM_MS
    if now ~= was and not force then
        if rec.pending ~= now then
            rec.pending = now
            rec.tPend = t
        elseif (t - (rec.tPend or t)) >= CONFIRM_MS then
            rec.isFeign = now
            rec.pending = nil
        end
    else
        rec.isFeign = now
        rec.pending = nil
    end
    
    rec.tLast = t
    feignState[unit] = rec
    
    -- Update frame visual state
    FD:SetFrameFeignState(unit, rec.isFeign)
end

-- Set visual state on arena frame for feign death
function FD:SetFrameFeignState(unit, isFeign)
    -- Get the arena frame
    local frameNumber = string.match(unit, "%d")
    if not frameNumber then return end
    
    -- CRITICAL: Only process arena1-3 (valid arena frames)
    local frameNum = tonumber(frameNumber)
    if not frameNum or frameNum < 1 or frameNum > 3 then
        -- Silently ignore invalid frame numbers (arena4, arena5, etc.)
        return
    end
    
    -- CRITICAL FIX: Check both frame systems (FrameManager and legacy arenaFrames)
    local arenaFrames = nil
    if AC.FrameManager and AC.FrameManager.frames then
        arenaFrames = AC.FrameManager.frames
    elseif AC.arenaFrames then
        arenaFrames = AC.arenaFrames
    end
    
    if not arenaFrames then 
        -- Silently return - frames not initialized yet
        return 
    end
    
    local frame = arenaFrames[frameNum]
    if not frame then 
        -- Silently return - frame doesn't exist (valid for 2v2 when checking frame 3)
        return 
    end
    
    -- Only update if state actually changed
    local wasFeigning = frame.__isFeign
    frame.__isFeign = isFeign
    
    -- Only log and apply visuals if state CHANGED
    if isFeign and not wasFeigning then
        -- Check if chat messages are enabled
        local db = AC.DB and AC.DB.profile
        local chatMessagesEnabled = db and db.moreFeatures and db.moreFeatures.chatMessagesEnabled
        if chatMessagesEnabled == nil then chatMessagesEnabled = true end
        
        if chatMessagesEnabled then
            print("|cffFF6600Arena Core: |r " .. unit .. " is FEIGNING DEATH - applying visual indicators")
        end
        
        -- Visual indicators for feign death
        
        -- 1. Desaturate class icon
        if frame.classIcon and frame.classIcon.classIcon then
            frame.classIcon.classIcon:SetDesaturated(true)
        end
        
        -- 2. Dim health and mana bars (CRITICAL: Set alpha multiple times to ensure it sticks)
        if frame.healthBar then 
            frame.healthBar:SetAlpha(0.4)
            -- Force update after a tiny delay to override any competing updates
            C_Timer.After(0.05, function()
                if frame.__isFeign and frame.healthBar then
                    frame.healthBar:SetAlpha(0.4)
                end
            end)
        end
        if frame.manaBar then 
            frame.manaBar:SetAlpha(0.4)
            C_Timer.After(0.05, function()
                if frame.__isFeign and frame.manaBar then
                    frame.manaBar:SetAlpha(0.4)
                end
            end)
        end
        
        -- 3. Create/show FEIGN DEATH text overlay (using custom ArenaCore font)
        if not frame.feignTag then
            -- Create a separate high-strata frame for the text to ensure it's always on top
            local textFrame = CreateFrame("Frame", nil, frame)
            textFrame:SetAllPoints(frame)
            textFrame:SetFrameStrata("HIGH")  -- CRITICAL: High strata so text is never clipped
            
            frame.feignTag = textFrame:CreateFontString(nil, "OVERLAY")
            frame.feignTag:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 14, "OUTLINE")
            frame.feignTag:SetPoint("CENTER", frame, "CENTER", 0, 0)
            frame.feignTag:SetText("|cffFF6600FEIGN DEATH|r")
            frame.feignTag:SetShadowOffset(2, -2)
            frame.feignTag:SetShadowColor(0, 0, 0, 1)
            frame.feignTag:SetDrawLayer("OVERLAY", 7)
            
            -- Pulsing animation for attention
            local animGroup = frame.feignTag:CreateAnimationGroup()
            animGroup:SetLooping("BOUNCE")
            
            local fadeOut = animGroup:CreateAnimation("Alpha")
            fadeOut:SetDuration(0.8)
            fadeOut:SetFromAlpha(1.0)
            fadeOut:SetToAlpha(0.5)
            fadeOut:SetSmoothing("IN_OUT")
            
            animGroup:Play()
            frame.feignTag.pulseAnim = animGroup
            frame.feignTagFrame = textFrame
        end
        -- COMBAT PROTECTED: Only show text outside combat
        if not InCombatLockdown() then
            frame.feignTag:Show()
        end
        
        -- 4. Add orange tint overlay to frame (more visible than just background)
        if not frame.feignOverlay then
            frame.feignOverlay = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
            frame.feignOverlay:SetAllPoints(frame)
            frame.feignOverlay:SetColorTexture(1.0, 0.4, 0.0, 0.3)  -- Orange overlay with transparency
        end
        -- COMBAT PROTECTED: Only show overlay outside combat
        if not InCombatLockdown() then
            frame.feignOverlay:Show()
        end
        
        -- Also tint the background texture
        if frame.background then
            frame.background:SetVertexColor(1.0, 0.5, 0.0, 1)  -- Orange tint
        end
        
        -- 5. Add orange glow around frame border (native WoW glow effect - dynamic sizing)
        if not frame.feignGlowFrame then
            -- CRITICAL: Create a separate frame for the glow (like TriBadges does)
            -- This ensures the glow dynamically scales with the parent frame
            frame.feignGlowFrame = CreateFrame("Frame", nil, frame)
            frame.feignGlowFrame:SetFrameLevel(frame:GetFrameLevel() - 1)  -- Behind frame but visible
            
            -- CRITICAL: Use SetPoint with offsets for dynamic sizing
            -- This makes the glow automatically adjust when frame size changes
            frame.feignGlowFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -8, 8)
            frame.feignGlowFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 8, -8)
            
            -- Create glow texture on the frame
            frame.feignGlow = frame.feignGlowFrame:CreateTexture(nil, "OVERLAY")
            frame.feignGlow:SetAllPoints(frame.feignGlowFrame)
            frame.feignGlow:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
            frame.feignGlow:SetBlendMode("ADD")
            frame.feignGlow:SetVertexColor(1.0, 0.4, 0.0, 0.8)  -- Orange glow
            
            -- Pulsing glow animation
            local glowAnimGroup = frame.feignGlow:CreateAnimationGroup()
            glowAnimGroup:SetLooping("BOUNCE")
            
            local glowFade = glowAnimGroup:CreateAnimation("Alpha")
            glowFade:SetDuration(1.0)
            glowFade:SetFromAlpha(0.8)
            glowFade:SetToAlpha(0.3)
            glowFade:SetSmoothing("IN_OUT")
            
            frame.feignGlow.pulseAnim = glowAnimGroup
        end
        -- COMBAT PROTECTED: Only show glow outside combat
        if not InCombatLockdown() then
            frame.feignGlowFrame:Show()
        end
        if frame.feignGlow.pulseAnim then
            frame.feignGlow.pulseAnim:Play()
        end
        
    elseif not isFeign and wasFeigning then
        -- Check if chat messages are enabled
        local db = AC.DB and AC.DB.profile
        local chatMessagesEnabled = db and db.moreFeatures and db.moreFeatures.chatMessagesEnabled
        if chatMessagesEnabled == nil then chatMessagesEnabled = true end
        
        if chatMessagesEnabled then
            print("|cff00FF00Arena Core: |r " .. unit .. " stopped FEIGNING DEATH - restoring normal state")
        end
        
        -- Restore normal state
        
        -- 1. Restore class icon saturation
        if frame.classIcon and frame.classIcon.classIcon then
            frame.classIcon.classIcon:SetDesaturated(false)
        end
        
        -- 2. Restore bar alpha
        if frame.healthBar then 
            frame.healthBar:SetAlpha(1.0)
        end
        if frame.manaBar then 
            frame.manaBar:SetAlpha(1.0)
        end
        
        -- 3. Hide feign death text
        if frame.feignTag then
            frame.feignTag:Hide()
            if frame.feignTag.pulseAnim then
                frame.feignTag.pulseAnim:Stop()
            end
        end
        
        -- 4. Hide orange overlay
        if frame.feignOverlay then
            frame.feignOverlay:Hide()
        end
        
        -- 5. Restore frame background color
        if frame.background then
            frame.background:SetVertexColor(1, 1, 1, 1)  -- Normal
        end
        
        -- 6. Hide orange glow
        if frame.feignGlowFrame then
            frame.feignGlowFrame:Hide()
        end
        if frame.feignGlow and frame.feignGlow.pulseAnim then
            frame.feignGlow.pulseAnim:Stop()
        end
    end
end

-- Force refresh all arena units
function FD:ForceRefreshAll()
    for _, unit in ipairs(ARENA_UNITS) do
        UpdateUnit(unit, true)
    end
end

-- Initialize the detector
function FD:Initialize()
    -- MIDNIGHT: Skip event registration to avoid taint warnings
    if AC and AC.Midnight and AC.Midnight.isMidnight then
        return
    end
    
    -- Create event frame
    self.eventFrame = CreateFrame("Frame")
    
    -- Register events
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("UNIT_FLAGS")
    -- CRITICAL FIX: Use RegisterUnitEvent to filter for arena units only
    self.eventFrame:RegisterUnitEvent("UNIT_AURA", "arena1", "arena2", "arena3")
    
    -- Register UNIT_HEALTH for all arena units
    for _, unit in ipairs(ARENA_UNITS) do
        self.eventFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
    end
    
    -- Register COMBAT_LOG for death events
    self.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    -- Event handler
    self.eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Clear state on zone change
            wipe(feignState)
            FD:ForceRefreshAll()
            
        elseif event == "UNIT_FLAGS" or event == "UNIT_AURA" then
            -- Update on any flag/aura change
            if arg1 and string.match(arg1, "^arena[1-3]$") then
                UpdateUnit(arg1)
            end
            
        elseif event == "UNIT_HEALTH" then
            -- CRITICAL: Check for feign death when health changes
            if arg1 and string.match(arg1, "^arena[1-3]$") then
                local health = UnitHealth(arg1)
                
                -- When health becomes 0, check if feigning or actually dead
                if health == 0 then
                    -- DEBUG: Removed spam - print("|cffFFAA00[FeignDeathDetector]|r " .. arg1 .. " health is 0 - checking feign death status...")
                    UpdateUnit(arg1, true)  -- Force immediate update, no debounce
                else
                    -- Normal health update
                    UpdateUnit(arg1)
                end
            end
            
        end
        -- PHASE 1.1: COMBAT_LOG handling moved to ProcessCombatLogEvent (called by centralized handler)
    end)
    
    -- DEBUG: Feign Death Detector initialized
    -- print("|cff8B45FFArena Core:|r Feign Death Detector initialized")
end

-- PHASE 1.1: Process combat log events (called by centralized handler)
--- @param timestamp number
--- @param combatEvent string
--- @param sourceGUID string
--- @param destGUID string
--- @param spellID number
function FD:ProcessCombatLogEvent(timestamp, combatEvent, sourceGUID, destGUID, spellID)
    -- Handle death events - override if feigning
    if combatEvent == "UNIT_DIED" or combatEvent == "UNIT_DESTROYED" then
        -- Map destGUID to arena unit
        for _, u in ipairs(ARENA_UNITS) do
            if UnitGUID(u) == destGUID then
                -- If currently feigning, DO NOT mark as real death
                if feignState[u] and feignState[u].isFeign then
                    self:SetFrameFeignState(u, true)
                    
                    -- Check if chat messages are enabled
                    local db = AC.DB and AC.DB.profile
                    local chatMessagesEnabled = db and db.moreFeatures and db.moreFeatures.chatMessagesEnabled
                    if chatMessagesEnabled == nil then chatMessagesEnabled = true end
                    
                    if chatMessagesEnabled then
                        print("|cffFF6600Arena Core: |r Hunter " .. u .. " used Feign Death - NOT actually dead!")
                    end
                    return
                end
            end
        end
    end
end

-- Hook into death detection to prevent false deaths
function FD:HookDeathDetection()
    -- This will be called when integrating with main frame system
    -- Prevents frames from showing "DEAD" when hunter is feigning
end

-- Initialize when addon loads
C_Timer.After(1, function()
    if AC and AC.FeignDeathDetector then
        AC.FeignDeathDetector:Initialize()
    end
end)
