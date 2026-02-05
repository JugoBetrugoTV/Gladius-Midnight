--- ============================================================================
-- File: ArenaCore/modules/Absorbs/Absorbs.lua
-- Purpose: BRUTE FORCE - Just show diagonal lines (TEST MODE + LIVE ARENA)
--- ============================================================================

local AC = _G.ArenaCore or {}
_G.ArenaCore = AC

-- Create Absorbs namespace
AC.Absorbs = AC.Absorbs or {}
local Absorbs = AC.Absorbs

-- Debug flag
Absorbs.DEBUG = true

-- Track absorb states to prevent flicker
local absorbStates = {} -- [frameIndex] = hasAbsorb (true/false)

--- ============================================================================
-- BRUTE FORCE - JUST SHOW THE LINES (TEST MODE)
--- ============================================================================

function Absorbs:ForceShowLines()
    -- DEBUG DISABLED FOR PRODUCTION
    -- if Absorbs.DEBUG then
    --     print("|cff00FF00[FORCE LINES]|r === DEBUGGING FORCE SHOW ===")
    -- end
    
    -- CRITICAL FIX: Check if absorbs feature is enabled
    local absorbsEnabled = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies 
                          and AC.DB.profile.moreGoodies.absorbs 
                          and AC.DB.profile.moreGoodies.absorbs.enabled
    
    if not absorbsEnabled then
        -- Feature disabled, hide all lines
        self:HideLines()
        return
    end
    
    -- Check if AC.FrameManager exists
    if not AC then
        -- print("|cffFF0000[FORCE LINES]|r ERROR: AC doesn't exist")
        return
    end
    
    if not AC.FrameManager then
        -- print("|cffFF0000[FORCE LINES]|r ERROR: AC.FrameManager doesn't exist")
        return
    end
    
    if not AC.FrameManager.frames then
        -- print("|cffFF0000[FORCE LINES]|r ERROR: AC.FrameManager.frames doesn't exist")
        return
    end
    
    -- Try to find frames and add textures
    -- CRITICAL: Only show absorbs on frames 2 and 3 in test mode (skip frame 1)
    -- This allows users to see a clean health bar without absorbs for comparison
    for i = 2, 3 do
        local frame = AC.FrameManager.frames[i]
        if frame then
            -- print("|cffFFFF00[FORCE LINES]|r Frame " .. i .. " found, checking healthBar...")
            
            -- Check if healthBar exists
            if not frame.healthBar then
                -- print("|cffFF0000[FORCE LINES]|r ERROR: Frame " .. i .. " has no healthBar")
                -- Try to find any child frame
                -- print("|cffFFFF00[FORCE LINES]|r Frame " .. i .. " children:")
                -- for j = 1, frame:GetNumChildren() do
                --     local child = select(j, frame:GetChildren())
                --     if child then
                --         print("|cffFFFF00[FORCE LINES]|r   Child " .. j .. ": " .. (child.GetName and child:GetName() or "unnamed"))
                --     end
                -- end
            else
                -- print("|cff00FF00[FORCE LINES]|r Frame " .. i .. " healthBar found, creating texture...")
                
                -- Create full 3-layer Blizzard-style absorb system for test mode
                if not frame.forceLineTexture then
                    -- LAYER 1: Container frame
                    frame.forceLineTexture = CreateFrame("Frame", nil, frame)
                        frame.forceLineTexture:SetAllPoints(frame.healthBar)
                        frame.forceLineTexture:SetFrameStrata("MEDIUM")
                        -- CRITICAL FIX: Set frame level BELOW health bar so text stays on top
                        frame.forceLineTexture:SetFrameLevel(frame.healthBar:GetFrameLevel() + 1)
                        
                        -- LAYER 2: Fill bar (background) - Blizzard-style blue tint
                        local fillBar = frame.forceLineTexture:CreateTexture(nil, "BACKGROUND")
                        fillBar:SetAllPoints(frame.forceLineTexture)
                        fillBar:SetTexture("Interface\\RaidFrame\\Shield-Fill")
                        fillBar:SetVertexColor(0.5, 0.8, 1, 0.7) -- Blue tint, semi-transparent
                        fillBar:Show()
                        
                        -- LAYER 3: Diagonal lines overlay (middle) - Proper tiling
                        local overlay = frame.forceLineTexture:CreateTexture(nil, "BORDER")
                        overlay:SetAllPoints(frame.forceLineTexture)
                        overlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay", true, true) -- Enable tiling
                        overlay:SetVertexColor(1, 1, 1, 1) -- White
                        overlay:SetAlpha(1.0)
                        overlay.tileSize = 32 -- Standard Blizzard tile size
                        overlay:Show()
                        
                        -- LAYER 4: Overshield glow (top) - Always show in test mode for visibility
                        local glow = frame.forceLineTexture:CreateTexture(nil, "BORDER")
                        glow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
                        glow:SetBlendMode("ADD") -- Additive blending for glow effect
                        glow:SetWidth(16)
                        glow:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMRIGHT", -7, 0)
                        glow:SetPoint("TOPLEFT", frame.healthBar, "TOPRIGHT", -7, 0)
                        glow:Show() -- Always visible in test mode
                        
                        frame.forceLineTexture:Show()
                        
                        -- CRITICAL FIX: Don't reparent text - it causes text to disappear when absorbs fade
                        -- Text stays as child of healthBar and will be on top due to frame level ordering
                        
                        -- print("|cff00FF00[FORCE LINES]|r ✅ Created full 3-layer absorb system on frame " .. i)
                        
                    else
                        -- Already exists, just show it (text stays as child of healthBar)
                        frame.forceLineTexture:Show()
                        
                        -- print("|cffFFFF00[FORCE LINES]|r Already exists - showing frame " .. i)
                    end
                end
            else
                -- print("|cffFF0000[FORCE LINES]|r Frame " .. i .. " not found")
            end
        end
    -- end  ← REMOVED: Extra 'end' that was causing syntax error
    
    -- print("|cff00FF00[FORCE LINES]|r === DEBUGGING COMPLETE ===")
end

function Absorbs:HideLines()
    -- if Absorbs.DEBUG then
    --     print("|cffFF0000[FORCE LINES]|r Hiding all diagonal lines...")
    -- end
    
    if AC.FrameManager and AC.FrameManager.frames then
        for i = 1, 3 do
            local frame = AC.FrameManager.frames[i]
            if frame and frame.forceLineTexture then
                frame.forceLineTexture:Hide()
            end
        end
    end
end

--- ============================================================================
-- LIVE ARENA ABSORB DETECTION (NEW)
--- ============================================================================

function Absorbs:ShowAbsorbLines(frameIndex)
    -- CRITICAL FIX: Check if absorbs feature is enabled
    local absorbsEnabled = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies 
                          and AC.DB.profile.moreGoodies.absorbs 
                          and AC.DB.profile.moreGoodies.absorbs.enabled
    
    if not absorbsEnabled then
        -- Feature disabled, don't show lines
        return
    end
    
    if not AC.FrameManager or not AC.FrameManager.frames then return end
    
    local frame = AC.FrameManager.frames[frameIndex]
    if not frame or not frame.healthBar then return end
    
    -- Create full 3-layer Blizzard-style absorb system
    if not frame.liveAbsorbTexture then
        -- LAYER 1: Container frame
        frame.liveAbsorbTexture = CreateFrame("Frame", nil, frame)
        frame.liveAbsorbTexture:SetAllPoints(frame.healthBar)
        frame.liveAbsorbTexture:SetFrameStrata("MEDIUM")
        -- CRITICAL FIX: Set frame level BELOW health bar so text stays on top
        -- Don't use 100 - that's too high and covers the text
        frame.liveAbsorbTexture:SetFrameLevel(frame.healthBar:GetFrameLevel() + 1)
        
        -- LAYER 2: Fill bar (background) - Blizzard-style blue tint
        local fillBar = frame.liveAbsorbTexture:CreateTexture(nil, "BACKGROUND")
        fillBar:SetAllPoints(frame.liveAbsorbTexture)
        fillBar:SetTexture("Interface\\RaidFrame\\Shield-Fill")
        fillBar:SetVertexColor(0.5, 0.8, 1, 0.7) -- Blue tint, semi-transparent
        fillBar:Show()
        frame.liveAbsorbTexture.fillBar = fillBar
        
        -- LAYER 3: Diagonal lines overlay (middle) - Proper tiling
        local overlay = frame.liveAbsorbTexture:CreateTexture(nil, "BORDER")
        overlay:SetAllPoints(frame.liveAbsorbTexture)
        overlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay", true, true) -- Enable tiling
        overlay:SetVertexColor(1, 1, 1, 1) -- White
        overlay:SetAlpha(1.0)
        overlay.tileSize = 32 -- Standard Blizzard tile size
        overlay:Show()
        frame.liveAbsorbTexture.overlay = overlay
        
        -- LAYER 4: Overshield glow (top) - Shows when shield > max health
        local glow = frame.liveAbsorbTexture:CreateTexture(nil, "BORDER")
        glow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
        glow:SetBlendMode("ADD") -- Additive blending for glow effect
        glow:SetWidth(16)
        glow:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMRIGHT", -7, 0)
        glow:SetPoint("TOPLEFT", frame.healthBar, "TOPRIGHT", -7, 0)
        glow:Hide() -- Hidden by default, shown when overshield detected
        frame.liveAbsorbTexture.overGlow = glow
        
        -- CRITICAL FIX: Don't reparent text - it causes text to disappear when absorbs fade
        -- Text stays as child of healthBar and will be on top due to frame level ordering
        
        -- DEBUG DISABLED FOR PRODUCTION
        -- if Absorbs.DEBUG then
        --     print("|cff00FF00[LIVE ABSORB]|r ✅ Created full 3-layer absorb system on frame " .. frameIndex)
        -- end
    else
        -- Already exists, just show it (text stays as child of healthBar)
    end
    
    -- Show all layers
    frame.liveAbsorbTexture:Show()
    if frame.liveAbsorbTexture.fillBar then frame.liveAbsorbTexture.fillBar:Show() end
    if frame.liveAbsorbTexture.overlay then frame.liveAbsorbTexture.overlay:Show() end
    
    -- Check if we should show overshield glow (absorb > max health)
    local unit = "arena" .. frameIndex
    if UnitExists(unit) then
        local totalAbsorbs = UnitGetTotalAbsorbs(unit) or 0
        local maxHealth = UnitHealthMax(unit) or 1
        local currentHealth = UnitHealth(unit) or 0
        
        -- Show glow if absorbs would push health over max
        if totalAbsorbs > 0 and (currentHealth + totalAbsorbs >= maxHealth) then
            if frame.liveAbsorbTexture.overGlow then
                frame.liveAbsorbTexture.overGlow:Show()
            end
        else
            if frame.liveAbsorbTexture.overGlow then
                frame.liveAbsorbTexture.overGlow:Hide()
            end
        end
    end
    
    -- DEBUG DISABLED FOR PRODUCTION
    -- if Absorbs.DEBUG then
    --     print("|cff00FF00[LIVE ABSORB]|r Showing full absorb system on frame " .. frameIndex)
    -- end
end

function Absorbs:HideAbsorbLines(frameIndex)
    if not AC.FrameManager or not AC.FrameManager.frames then return end
    
    local frame = AC.FrameManager.frames[frameIndex]
    if frame and frame.liveAbsorbTexture then
        frame.liveAbsorbTexture:Hide()
        
        -- DEBUG DISABLED FOR PRODUCTION
        -- if Absorbs.DEBUG then
        --     print("|cffFF0000[LIVE ABSORB]|r Hiding absorb lines on frame " .. frameIndex)
        -- end
    end
end

function Absorbs:CheckAbsorbsOnFrame(frameIndex)
    -- Midnight compatibility: Use Midnight absorbs module if in Midnight
    if AC.Midnight and AC.Midnight.isMidnight then
        if AC.AbsorbsMidnight and AC.AbsorbsMidnight.CheckAbsorbsOnFrame then
            AC.AbsorbsMidnight:CheckAbsorbsOnFrame(frameIndex)
        end
        return
    end
    
    -- CRITICAL FIX: Check if absorbs feature is enabled
    local absorbsEnabled = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies 
                          and AC.DB.profile.moreGoodies.absorbs 
                          and AC.DB.profile.moreGoodies.absorbs.enabled
    
    if not absorbsEnabled then
        -- Feature disabled, hide lines if they exist
        self:HideAbsorbLines(frameIndex)
        return
    end
    
    if not AC.FrameManager or not AC.FrameManager.frames then return end
    
    local frame = AC.FrameManager.frames[frameIndex]
    if not frame then return end
    
    -- Get the unit for this frame (arena1, arena2, arena3)
    local unit = "arena" .. frameIndex
    
    -- Check if unit exists and has absorbs OR immunities
    if UnitExists(unit) then
        local totalAbsorbs = UnitGetTotalAbsorbs(unit) or 0
        local hasAbsorb = totalAbsorbs > 0
        
        -- CRITICAL: Also check for immunity buffs (Ice Block, Divine Shield, etc.)
        local hasImmunity = false
        if AC.ImmunityTracker and AC.ImmunityTracker.CheckImmunity then
            local immunityType = AC.ImmunityTracker:CheckImmunity(unit)
            hasImmunity = (immunityType ~= nil)
        end
        
        -- Show lines if unit has EITHER absorbs OR immunity
        local shouldShowLines = hasAbsorb or hasImmunity
        
        -- Only update if state changed (prevent flicker)
        if absorbStates[frameIndex] ~= shouldShowLines then
            absorbStates[frameIndex] = shouldShowLines
            
            if shouldShowLines then
                -- DEBUG DISABLED FOR PRODUCTION
                -- if Absorbs.DEBUG then
                --     if hasAbsorb then
                --         print("|cff00FF00[LIVE ABSORB]|r " .. unit .. " has absorb: " .. totalAbsorbs)
                --     end
                --     if hasImmunity then
                --         print("|cff00FFFF[LIVE ABSORB]|r " .. unit .. " has immunity - showing shield lines")
                --     end
                -- end
                self:ShowAbsorbLines(frameIndex)
            else
                -- DEBUG DISABLED FOR PRODUCTION
                -- if Absorbs.DEBUG then
                --     print("|cffFF0000[LIVE ABSORB]|r " .. unit .. " no absorb or immunity")
                -- end
                self:HideAbsorbLines(frameIndex)
            end
        end
    else
        -- Unit doesn't exist, hide lines
        if absorbStates[frameIndex] ~= false then
            absorbStates[frameIndex] = false
            self:HideAbsorbLines(frameIndex)
        end
    end
end

function Absorbs:UpdateAllAbsorbs()
    -- Check all 3 arena frames
    for i = 1, 3 do
        self:CheckAbsorbsOnFrame(i)
    end
end

--- ============================================================================
-- EVENT SYSTEM FOR LIVE ARENA
--- ============================================================================

function Absorbs:RegisterEvents()
    if self.eventFrame then return end -- Already registered
    
    self.eventFrame = CreateFrame("Frame")
    
    -- Register events that indicate absorb changes
    self.eventFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
    self.eventFrame:RegisterEvent("UNIT_HEALTH")
    self.eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    self.eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_ABSORB_AMOUNT_CHANGED" then
            local unit = ...
            if unit and unit:match("^arena%d$") then
                local frameIndex = tonumber(unit:match("arena(%d)"))
                if frameIndex then
                    Absorbs:CheckAbsorbsOnFrame(frameIndex)
                end
            end
        elseif event == "UNIT_HEALTH" then
            local unit = ...
            if unit and unit:match("^arena%d$") then
                local frameIndex = tonumber(unit:match("arena(%d)"))
                if frameIndex then
                    Absorbs:CheckAbsorbsOnFrame(frameIndex)
                end
            end
        elseif event == "ARENA_OPPONENT_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
            -- Update all frames when arena state changes
            C_Timer.After(0.5, function()
                Absorbs:UpdateAllAbsorbs()
            end)
        end
    end)
    
    -- if Absorbs.DEBUG then
    --     print("|cff00FF00[LIVE ABSORB]|r Event system registered")
    -- end
end

function Absorbs:Initialize()
    if self.initialized then return end
    
    -- if Absorbs.DEBUG then
    --     print("|cff00FF00[FORCE LINES]|r Initializing BRUTE FORCE line system...")
    -- end
    
    -- Register events for live arena absorb detection
    self:RegisterEvents()
    
    -- Start monitoring absorbs in arena
    C_Timer.NewTicker(0.5, function()
        local _, instanceType = IsInInstance()
        if instanceType == "arena" then
            self:UpdateAllAbsorbs()
        end
    end)
    
    self.initialized = true
    
    -- if Absorbs.DEBUG then
    --     print("|cff00FF00[FORCE LINES]|r ✅ Brute force system initialized - TEST MODE + LIVE ARENA!")
    -- end
end

-- Auto-initialize
C_Timer.After(1, function()
    Absorbs:Initialize()
end)

-- Global functions for testing
_G.ForceShowLines = function() 
    Absorbs:ForceShowLines()
    -- print("|cffFFFF00[FORCE LINES]|r Manual force show triggered")
end

_G.ForceHideLines = function() 
    Absorbs:HideLines()
    -- print("|cffFFFF00[FORCE LINES]|r Manual force hide triggered")
end

-- Global function for live absorb testing
_G.CheckAbsorbs = function()
    -- print("|cffFFFF00[LIVE ABSORB]|r === CHECKING ALL ABSORBS ===")
    Absorbs:UpdateAllAbsorbs()
    -- print("|cffFFFF00[LIVE ABSORB]|r === CHECK COMPLETE ===")
end
