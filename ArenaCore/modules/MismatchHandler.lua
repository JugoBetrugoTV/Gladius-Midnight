-- ============================================================================
-- MismatchHandler.lua
-- Handles ALL arena frame visibility for mismatched games (2v3, 1v2, etc.)
-- Uses event-driven pattern - NO bracket size calculations
-- ============================================================================

local AddonName, AC = ...

-- Create module
local MismatchHandler = {}
AC.MismatchHandler = MismatchHandler

-- Local references for performance
local GetArenaOpponentSpec = GetArenaOpponentSpec
local GetNumArenaOpponentSpecs = GetNumArenaOpponentSpecs
local GetSpecializationInfoByID = GetSpecializationInfoByID
local UnitClass = UnitClass
local UnitExists = UnitExists
local IsActiveBattlefieldArena = IsActiveBattlefieldArena
local IsInInstance = IsInInstance
local InCombatLockdown = InCombatLockdown
local MAX_ARENA_ENEMIES = 3

-- Event frame
local eventFrame = CreateFrame("Frame")

-- ============================================================================
-- UNIT VALIDATION
-- ============================================================================

local function IsValidUnit(unit)
    if not unit then
        return false
    end
    
    -- Validate it's an arena unit (arena1-arena5)
    local unitID = unit:match("arena(%d+)")
    return unitID and tonumber(unitID) <= 5
end

-- ============================================================================
-- ARENA_OPPONENT_UPDATE EVENT HANDLER
-- CRITICAL FIX: Create frames for newly seen enemies
-- ============================================================================

function MismatchHandler:ARENA_OPPONENT_UPDATE(event, unit, updateType)
    -- Validate we're in arena
    if not IsActiveBattlefieldArena() then
        return
    end
    
    -- Validate unit
    if not IsValidUnit(unit) then
        return
    end
    
    -- CRITICAL FIX: Create frame if it doesn't exist
    -- This handles the case where a stealth player becomes visible
    local frame = self:GetFrame(unit)
    if not frame then
        -- Try to get frame from FrameManager first
        if AC.FrameManager then
            local frames = AC.FrameManager:GetFrames()
            if frames then
                local arenaIndex = tonumber(unit:match("arena(%d)"))
                if arenaIndex and not frames[arenaIndex] then
                    -- Frame doesn't exist, create it
                    if AC.FrameManager.CreateFrame then
                        AC.FrameManager:CreateFrame(arenaIndex)
                        frame = self:GetFrame(unit)
                    end
                end
            end
        end
        
        -- If still no frame, we can't proceed (silently fail)
        if not frame then
            return
        end
    end
    
    -- Extract arena index
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if not arenaIndex then
        return
    end
    
    -- Update spec/class data
    local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(arenaIndex)
    
    if specID and specID > 0 then
        -- We have spec data - use it
        local id, name, description, icon, role, class = GetSpecializationInfoByID(specID)
        
        if class then
            -- Store for later use
            frame.class = class
            frame.specID = id
            frame.specIcon = icon
            
            -- Update visual spec icon
            if frame.specIcon and frame.specIcon.icon and icon then
                local AC = _G.ArenaCore
                local db = AC and AC.DB and AC.DB.profile
                local specEnabled = db and db.specIcons and db.specIcons.enabled
                if specEnabled ~= false then
                    frame.specIcon.icon:SetTexture(icon)
                    frame.specIcon:Show()
                else
                    frame.specIcon:Hide()
                end
            end
            
            -- Update visual class icon
            if frame.classIcon and class then
                local AC = _G.ArenaCore
                local db = AC and AC.DB and AC.DB.profile
                local classEnabled = db and db.classIcons and db.classIcons.enabled
                if classEnabled ~= false then
                    if frame.classIcon.UpdateClassIcon then
                        frame.classIcon.UpdateClassIcon(class)
                    else
                        local iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\" .. class .. ".tga"
                        frame.classIcon.icon:SetTexture(iconPath)
                        if frame.classIcon.overlay then
                            local overlayPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\" .. class:lower() .. "overlay.tga"
                            frame.classIcon.overlay:SetTexture(overlayPath, true, true)
                        end
                    end
                    
                    -- CRITICAL FIX: Apply user's saved position and scale
                    local classIconDB = db and db.classIcons
                    if classIconDB then
                        local pos = classIconDB.positioning or {}
                        local size = classIconDB.sizing or {}
                        
                        -- Check for theme-specific positioning
                        local useCompactLayout = false
                        if AC.ArenaFrameThemes then
                            local currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
                            local theme = AC.ArenaFrameThemes.themes and AC.ArenaFrameThemes.themes[currentTheme]
                            if theme and theme.positioning and theme.positioning.compactLayout then
                                useCompactLayout = true
                            end
                        end
                        
                        frame.classIcon:ClearAllPoints()
                        if useCompactLayout then
                            -- The 1500 Special: Position to RIGHT of frame (outside left edge)
                            local xOffset = -2 + (pos.horizontal or 0)
                            local yOffset = 0 + (pos.vertical or 0)
                            frame.classIcon:SetPoint("RIGHT", frame, "LEFT", xOffset, yOffset)
                        else
                            -- Arena Core: Position to LEFT of frame (inside left edge)
                            local xOffset = 8 + (pos.horizontal or 0)
                            local yOffset = 0 + (pos.vertical or 0)
                            frame.classIcon:SetPoint("LEFT", frame, "LEFT", xOffset, yOffset)
                        end
                        
                        local scale = (size.scale or 100) / 100
                        frame.classIcon:SetScale(scale)
                    end
                    
                    frame.classIcon:Show()
                end
            end
        end
    else
        -- No spec data - fallback to UnitClass
        local _, classFile = UnitClass(unit)
        if classFile then
            frame.class = classFile
            
            -- Hide spec icon
            if frame.specIcon then
                frame.specIcon:Hide()
            end
            
            -- Update class icon with fallback
            if frame.classIcon then
                local AC = _G.ArenaCore
                local db = AC and AC.DB and AC.DB.profile
                local classEnabled = db and db.classIcons and db.classIcons.enabled
                if classEnabled ~= false then
                    if frame.classIcon.UpdateClassIcon then
                        frame.classIcon.UpdateClassIcon(classFile)
                    else
                        local iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\" .. classFile .. ".tga"
                        frame.classIcon.icon:SetTexture(iconPath)
                        if frame.classIcon.overlay then
                            local overlayPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\" .. classFile:lower() .. "overlay.tga"
                            frame.classIcon.overlay:SetTexture(overlayPath, true, true)
                        end
                    end
                    
                    -- CRITICAL FIX: Apply user's saved position and scale
                    local classIconDB = db and db.classIcons
                    if classIconDB then
                        local pos = classIconDB.positioning or {}
                        local size = classIconDB.sizing or {}
                        
                        -- Check for theme-specific positioning
                        local useCompactLayout = false
                        if AC.ArenaFrameThemes then
                            local currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
                            local theme = AC.ArenaFrameThemes.themes and AC.ArenaFrameThemes.themes[currentTheme]
                            if theme and theme.positioning and theme.positioning.compactLayout then
                                useCompactLayout = true
                            end
                        end
                        
                        frame.classIcon:ClearAllPoints()
                        if useCompactLayout then
                            -- The 1500 Special: Position to RIGHT of frame (outside left edge)
                            local xOffset = -2 + (pos.horizontal or 0)
                            local yOffset = 0 + (pos.vertical or 0)
                            frame.classIcon:SetPoint("RIGHT", frame, "LEFT", xOffset, yOffset)
                        else
                            -- Arena Core: Position to LEFT of frame (inside left edge)
                            local xOffset = 8 + (pos.horizontal or 0)
                            local yOffset = 0 + (pos.vertical or 0)
                            frame.classIcon:SetPoint("LEFT", frame, "LEFT", xOffset, yOffset)
                        end
                        
                        local scale = (size.scale or 100) / 100
                        frame.classIcon:SetScale(scale)
                    end
                    
                    frame.classIcon:Show()
                end
            end
        end
    end
    
    -- Update frame elements (moved from old handler)
    local AC = _G.ArenaCore
    if AC then
        -- Update dispels
        if AC.UpdateDispelFrames then
            C_Timer.After(0.05, function()
                AC:UpdateDispelFrames()
            end)
        end
        
        -- Update trinkets and racials
        if AC.TrinketsRacials and AC.TrinketsRacials.RefreshFrame then
            AC.TrinketsRacials:RefreshFrame(frame, unit)
        end
        
        -- Update MFM elements if available
        local MFM = AC.MasterFrameManager
        if MFM then
            -- Update name (clear test mode names)
            if not AC.testModeEnabled and MFM.UpdateName then
                MFM:UpdateName(frame)
            end
            
            -- Update health and power
            if MFM.UpdateHealth then MFM.UpdateHealth(frame) end
            if MFM.UpdatePower then MFM.UpdatePower(frame) end
        end
    end
    
    -- CRITICAL: Show frame for all update types
    -- ArenaFrameStealth.lua handles alpha, but we MUST show the frame
    self:ShowFrame(unit)
end

-- ============================================================================
-- ARENA_PREP_OPPONENT_SPECIALIZATIONS EVENT HANDLER
-- ============================================================================

function MismatchHandler:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
    -- Loop through all opponent specs (handles mismatched brackets automatically)
    -- This is the KEY to handling 2v3, 1v2, etc. - we loop based on ACTUAL opponent count
    local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0
    
    -- print("|cff00FF00[PREP_ROOM]|r ARENA_PREP_OPPONENT_SPECIALIZATIONS fired - numOpponents:", numOpponents)
    
    for i = 1, numOpponents do
        local unit = "arena" .. i
        local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(i)
        
        if specID and specID > 0 then
            -- Get frame
            local frame = self:GetFrame(unit)
            if frame then
                -- Update spec/class data
                local id, name, description, icon, role, class = GetSpecializationInfoByID(specID)
                if class then
                    frame.class = class
                    frame.specID = id
                    frame.specIcon = icon
                end
                
                -- Show frame (alpha handled by ArenaFrameStealth.lua)
                self:ShowFrame(unit)
                
                -- print("[PREP_ROOM] Updated spec/class for", unit, "- Frame shown:", frame:IsShown())
            end
        end
    end
    
    -- Do NOT explicitly hide extra frames
    -- Only show frames with data and ignore the rest
    -- This prevents any potential race conditions with WoW's events
end

-- ============================================================================
-- FRAME MANAGEMENT
-- ============================================================================

function MismatchHandler:GetFrame(unit)
    -- Get frame from FrameManager
    if not AC.FrameManager then
        return nil
    end
    
    local frames = AC.FrameManager:GetFrames()
    if not frames then
        return nil
    end
    
    -- Extract arena index
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if not arenaIndex then
        return nil
    end
    
    local frame = frames[arenaIndex]
    return frame
end

function MismatchHandler:ShowFrame(unit)
    local frame = self:GetFrame(unit)
    if not frame then
        return
    end
    
    -- Don't interfere with combat lockdown
    if InCombatLockdown() then
        return
    end
    
    -- Show the frame
    frame:Show()
end

function MismatchHandler:HideFrame(unit)
    local frame = self:GetFrame(unit)
    if not frame then
        return
    end
    
    -- Don't interfere with combat lockdown
    if InCombatLockdown() then
        return
    end
    
    -- Hide the frame
    frame:Hide()
    frame:SetAlpha(0)
end

function MismatchHandler:UpdateAlpha(unit, alpha)
    local frame = self:GetFrame(unit)
    if not frame then
        return
    end
    
    -- Set alpha (alpha controls visibility state)
    frame:SetAlpha(alpha)
end

-- ============================================================================
-- EVENT REGISTRATION
-- ============================================================================

function MismatchHandler:RegisterEvents()
    -- Register arena events
    eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    eventFrame:RegisterEvent("UNIT_NAME_UPDATE")  -- CRITICAL: Ensures frames show even if ARENA_OPPONENT_UPDATE is delayed
    
    -- Set event handler
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ARENA_OPPONENT_UPDATE" then
            MismatchHandler:ARENA_OPPONENT_UPDATE(event, ...)
        elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
            MismatchHandler:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
        elseif event == "UNIT_NAME_UPDATE" then
            MismatchHandler:UNIT_NAME_UPDATE(event, ...)
        end
    end)
end

function MismatchHandler:UnregisterEvents()
    eventFrame:UnregisterEvent("ARENA_OPPONENT_UPDATE")
    eventFrame:UnregisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    eventFrame:UnregisterEvent("UNIT_NAME_UPDATE")
end

-- ============================================================================
-- UNIT_NAME_UPDATE EVENT HANDLER
-- CRITICAL: This ensures frames show even if ARENA_OPPONENT_UPDATE is delayed
-- ============================================================================

function MismatchHandler:UNIT_NAME_UPDATE(event, unit)
    -- Validate we're in arena
    if not IsActiveBattlefieldArena() then
        return
    end
    
    -- Validate unit
    if not IsValidUnit(unit) then
        return
    end
    
    -- Show the frame
    self:ShowFrame(unit)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MismatchHandler:Initialize()
    -- Register events when entering arena
    self:RegisterEvents()
end

-- Auto-initialize on load
C_Timer.After(0.1, function()
    if AC.MismatchHandler then
        AC.MismatchHandler:Initialize()
    end
end)

-- ============================================================================
-- DEBUG COMMANDS
-- ============================================================================

SLASH_ACMISMATCH1 = "/acmismatch"
SlashCmdList["ACMISMATCH"] = function(msg)
    if msg == "debug" then
        print("ArenaCore MismatchHandler Debug:")
        print("- Events registered: ARENA_OPPONENT_UPDATE, ARENA_PREP_OPPONENT_SPECIALIZATIONS")
        print("- Frame count: " .. (AC.FrameManager and #AC.FrameManager:GetFrames() or 0))
        print("- In arena: " .. tostring(IsActiveBattlefieldArena()))
        
        local numOpps = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0
        print("- Opponent count: " .. numOpps)
        
        for i = 1, MAX_ARENA_ENEMIES do
            local unit = "arena" .. i
            local frame = MismatchHandler:GetFrame(unit)
            if frame then
                print(string.format("  - %s: visible=%s, alpha=%.1f", unit, tostring(frame:IsVisible()), frame:GetAlpha()))
            end
        end
    else
        print("ArenaCore MismatchHandler")
        print("Usage: /acmismatch debug")
    end
end
