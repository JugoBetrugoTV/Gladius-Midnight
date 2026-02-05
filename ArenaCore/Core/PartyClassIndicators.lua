-- ============================================================================
-- File: ArenaCore/Core/PartyClassIndicators.lua (v2.0)
-- Purpose: Party class indicators
-- Rewritten Nov 1, 2025
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

-- Class icon paths (ArenaCore Custom theme)
local CLASS_ICON_PATHS = {
    DEATHKNIGHT = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Deathknight",
    DEMONHUNTER = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Demonhunter",
    DRUID = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Druid",
    EVOKER = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Evoker",
    HUNTER = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Hunter",
    MAGE = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Mage",
    MONK = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Monk",
    PALADIN = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Paladin",
    PRIEST = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Priest",
    ROGUE = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Rogue",
    SHAMAN = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Shaman",
    WARLOCK = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Warlock",
    WARRIOR = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Warrior",
}

-- ColdClasses theme paths (WoW Default Style+Midnight Chill)
-- CRITICAL: Must include .png extension for PNG files
local COLDCLASSES_ICON_PATHS = {
    DEATHKNIGHT = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\deathknight.png",
    DEMONHUNTER = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\demonhunter.png",
    DRUID = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\druid.png",
    EVOKER = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\evoker.png",
    HUNTER = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\hunter.png",
    MAGE = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\mage.png",
    MONK = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\monk.png",
    PALADIN = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\paladin.png",
    PRIEST = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\priest.png",
    ROGUE = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\rogue.png",
    SHAMAN = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\shaman.png",
    WARLOCK = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\warlock.png",
    WARRIOR = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\warrior.png",
}

-- Get class icon path based on useCustomIcons setting
local function GetClassIconPath(classToken)
    if not classToken then return nil end
    
    -- Get settings from database
    local db = AC.DB and AC.DB.profile
    local useCustomIcons = db and db.moreGoodies and db.moreGoodies.partyClassSpecs and db.moreGoodies.partyClassSpecs.useCustomIcons
    
    -- When checkbox is ON: Use ArenaCore custom icons
    -- When checkbox is OFF: Use Midnight Chill (coldclasses) icons
    if useCustomIcons then
        -- Use ArenaCore Custom icons
        return CLASS_ICON_PATHS[classToken]
    else
        -- Use Midnight Chill (coldclasses) icons
        return COLDCLASSES_ICON_PATHS[classToken]
    end
end

-- ============================================================================
-- INDEPENDENT FRAME STORAGE (for custom nameplate addon compatibility)
-- ============================================================================
-- Store frames independently so they work with Platynator/Plater
-- These addons reparent Blizzard frames to hidden frames, so we need our own
local independentFrames = {}

-- Expose the independentFrames table for cleanup by other modules
AC.PartyClassIndicators = AC.PartyClassIndicators or {}
AC.PartyClassIndicators.independentFrames = independentFrames

-- OnUpdate handler to continuously position frames above nameplates
local function UpdateFramePosition(self, elapsed)
    if not self.unit then return end
    
    local nameplate = C_NamePlate.GetNamePlateForUnit(self.unit)
    if nameplate and nameplate:IsShown() then
        self:ClearAllPoints()
        self:SetPoint("BOTTOM", nameplate, "TOP", self.offsetX or 0, self.offsetY or 0)
        self:Show()
    else
        self:Hide()
    end
end

-- ============================================================================
-- BBP PATTERN: Single function called from NAME_PLATE_UNIT_ADDED
-- ============================================================================

function AC.UpdatePartyClassIndicator(frame)
    if not frame or not frame.unit then return end
    
    -- Don't check IsForbidden/IsProtected - we're using a dummy table now, not a real frame
    
    -- Get ArenaCore config
    local db = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.partyClassSpecs
    if not db or not db.mode or db.mode == "off" then
        -- Feature disabled - restore any hidden elements
        if frame.__acClassIndicatorActive then
            if frame.HealthBarsContainer then
                frame.HealthBarsContainer:SetAlpha(1)
            end
            if frame.name then
                frame.name:SetAlpha(1)
            end
            frame.__acClassIndicatorActive = nil
        end
        if frame.ArenaCore_ClassIndicator then
            frame.ArenaCore_ClassIndicator:Hide()
        end
        if frame.ArenaCore_Pointer then
            frame.ArenaCore_Pointer:Hide()
        end
        -- Restore raid target markers when feature is off
        if frame.RaidTargetFrame and frame.RaidTargetFrame.RaidTargetIcon then
            frame.RaidTargetFrame.RaidTargetIcon:SetAlpha(1)
        end
        return
    end
    
    -- Get unit info first
    local unitForData = frame.displayedUnit or frame.unit
    if not unitForData or not UnitExists(unitForData) then return end
    
    -- Only handle nameplates
    -- CRITICAL: For custom nameplate addons, frame.unit may not contain "nameplate"
    -- Check if the unit itself is a nameplate unit
    if not unitForData:find("nameplate") then return end
    
    -- CRITICAL: Only work on FRIENDLY PLAYERS, not NPCs (BBP pattern)
    if not UnitIsPlayer(unitForData) or not UnitIsFriend("player", unitForData) then
        -- NPC or enemy - don't touch anything
        if frame.__acClassIndicatorActive then
            if frame.HealthBarsContainer then
                frame.HealthBarsContainer:SetAlpha(1)
            end
            frame.__acClassIndicatorActive = nil
        end
        if frame.ArenaCore_ClassIndicator then
            frame.ArenaCore_ClassIndicator:Hide()
        end
        if frame.ArenaCore_Pointer then
            frame.ArenaCore_Pointer:Hide()
        end
        -- Restore raid target markers for NPCs/enemies
        if frame.RaidTargetFrame and frame.RaidTargetFrame.RaidTargetIcon then
            frame.RaidTargetFrame.RaidTargetIcon:SetAlpha(1)
        end
        return
    end
    
    -- Check mode setting (party vs all)
    local showOnThisUnit = false
    if db.mode == "all" then
        showOnThisUnit = true
    elseif db.mode == "party" then
        showOnThisUnit = UnitInParty(unitForData)
    end
    
    -- If mode doesn't match, hide and return
    if not showOnThisUnit then
        -- Mode doesn't match - hide everything
        if frame.__acClassIndicatorActive then
            if frame.HealthBarsContainer then
                frame.HealthBarsContainer:SetAlpha(1)
            end
            frame.__acClassIndicatorActive = nil
        end
        if frame.ArenaCore_ClassIndicator then
            frame.ArenaCore_ClassIndicator:Hide()
        end
        if frame.ArenaCore_Pointer then
            frame.ArenaCore_Pointer:Hide()
        end
        -- Restore raid target markers for enemies/neutrals
        if frame.RaidTargetFrame and frame.RaidTargetFrame.RaidTargetIcon then
            frame.RaidTargetFrame.RaidTargetIcon:SetAlpha(1)
        end
        return
    end
    
    -- Don't show on self
    if UnitIsUnit(unitForData, "player") then
        if frame.ArenaCore_ClassIndicator then
            frame.ArenaCore_ClassIndicator:Hide()
        end
        if frame.ArenaCore_Pointer then
            frame.ArenaCore_Pointer:Hide()
        end
        -- Restore raid target markers for self
        if frame.RaidTargetFrame and frame.RaidTargetFrame.RaidTargetIcon then
            frame.RaidTargetFrame.RaidTargetIcon:SetAlpha(1)
        end
        return
    end
    
    -- Get class info
    local _, class = UnitClass(unitForData)
    if not class then return end
    
    -- ========================================================================
    -- CLASS INDICATOR (Icon above nameplate)
    -- ========================================================================
    
    -- Always show class icons when feature is enabled (mode != "off")
    if true then
        -- Get or create independent frame (not a child of nameplate)
        local classFrame = independentFrames[unitForData]
        if not classFrame then
            -- Create frame attached to UIParent (independent of nameplate)
            classFrame = CreateFrame("Frame", "ArenaCore_ClassIndicator_" .. unitForData, UIParent)
            classFrame:SetSize(32, 32)
            -- ENHANCED: Use TOOLTIP strata with high frame level to ensure visibility above talent trees
            -- Following tooltip pattern: use high frame level within TOOLTIP strata
            classFrame:SetFrameStrata("TOOLTIP")
            classFrame:SetFrameLevel(100)
            independentFrames[unitForData] = classFrame
            
            -- Store unit for OnUpdate positioning
            classFrame.unit = unitForData
            
            -- Set up continuous positioning
            classFrame:SetScript("OnUpdate", UpdateFramePosition)
            
            -- Store reference on frame for compatibility
            frame.ArenaCore_ClassIndicator = classFrame
            
            -- Create the class icon texture
            classFrame.icon = classFrame:CreateTexture(nil, "ARTWORK")
            classFrame.icon:SetPoint("CENTER", classFrame)
            classFrame.icon:SetSize(28, 28)
            
            -- Create circular mask
            classFrame.mask = classFrame:CreateMaskTexture()
            classFrame.mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            classFrame.mask:SetSize(28, 28)
            classFrame.mask:SetPoint("CENTER", classFrame.icon)
            classFrame.icon:AddMaskTexture(classFrame.mask)
            
            -- Create border using BlackOutline.tga
            classFrame.border = classFrame:CreateTexture(nil, "OVERLAY")
            classFrame.border:SetAllPoints(classFrame)
            classFrame.border:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Classicons\\BlackOutline.tga")
        end
        
        -- Position frame above nameplate using world coordinates
        local nameplateFrame = C_NamePlate.GetNamePlateForUnit(unitForData)
        if nameplateFrame then
            classFrame:SetPoint("BOTTOM", nameplateFrame, "TOP", 0, 8)
        end
        
        -- Apply scale from settings
        local finalScale
        do
            local pm = AC.ProfileManager
            local scalePixels = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.scale")
            if type(scalePixels) == "number" then
                local currentScale = AC.ConvertPixelsToScale and AC:ConvertPixelsToScale(scalePixels, 50, 360, 1, 12) or 6.5
                finalScale = 0.5 + (currentScale - 1) * (2.5 / 11)
            else
                local rawScale = (db.scale) or 100
                if rawScale <= 12 then
                    finalScale = 0.5 + (rawScale - 1) * (2.5 / 11)
                else
                    finalScale = rawScale / 100
                end
            end
            finalScale = math.max(0.5, math.min(finalScale or 1.0, 3.0))
            classFrame:SetScale(finalScale)
        end
        
        -- Apply horizontal/vertical offsets
        local offX, offY = 0, 0
        do
            local pm = AC.ProfileManager
            local px = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.offsetX")
            local py = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.offsetY")
            if type(px) ~= "number" then
                px = db.offsetX or 0
            end
            if type(py) ~= "number" then
                py = db.offsetY or 0
            end
            offX, offY = tonumber(px) or 0, tonumber(py) or 0
        end
        
        local baseY = 8
        -- Store offsets for OnUpdate handler
        classFrame.offsetX = offX
        classFrame.offsetY = baseY + offY
        
        -- Set class icon texture (use custom ArenaCore icons)
        -- CRITICAL FIX: Check if this is a healer and showHealerIcon is enabled
        local useHealerIcon = false
        if db.showHealerIcon then
            -- Check if this unit is a healer using role assignment
            local role = UnitGroupRolesAssigned(unitForData)
            if role == "HEALER" then
                useHealerIcon = true
            end
        end
        
        if useHealerIcon then
            -- Use custom ArenaCore healer icon
            classFrame.icon:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Classicons\\HealerPointer.tga")
            classFrame.icon:SetTexCoord(0, 1, 0, 1) -- Full texture for healer icon
        else
            -- Use normal class icon (respects theme setting)
            local iconPath = GetClassIconPath(class)
            if iconPath then
                classFrame.icon:SetTexture(iconPath)
                classFrame.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
            end
        end
        
        -- Hide raid target markers (skull, cross, moon, etc.) when showing class icons
        if frame.RaidTargetFrame and frame.RaidTargetFrame.RaidTargetIcon then
            frame.RaidTargetFrame.RaidTargetIcon:SetAlpha(0)
        end
        
        classFrame:Show()
    else
        local classFrame = independentFrames[unitForData]
        if classFrame then
            classFrame:Hide()
        end
    end
    
    -- ========================================================================
    -- PARTY POINTER (Arrow above nameplate)
    -- ========================================================================
    
    -- Update pointer (triangle arrow) with separate positioning
    if db.showPointers then
        -- Get or create independent pointer frame
        local pointerFrame = independentFrames[unitForData .. "_pointer"]
        if not pointerFrame then
            -- Create frame attached to UIParent (independent of nameplate)
            pointerFrame = CreateFrame("Frame", "ArenaCore_Pointer_" .. unitForData, UIParent)
            pointerFrame:SetSize(34, 48)
            -- ENHANCED: Use TOOLTIP strata with high frame level to ensure visibility above talent trees
            -- Slightly higher level than class icons so pointers appear above them
            pointerFrame:SetFrameStrata("TOOLTIP")
            pointerFrame:SetFrameLevel(101)
            independentFrames[unitForData .. "_pointer"] = pointerFrame
            
            -- Store unit for OnUpdate positioning
            pointerFrame.unit = unitForData
            
            -- Set up continuous positioning
            pointerFrame:SetScript("OnUpdate", UpdateFramePosition)
            
            -- Store reference on frame for compatibility
            frame.ArenaCore_Pointer = pointerFrame
            
            pointerFrame.icon = pointerFrame:CreateTexture(nil, "ARTWORK")
            pointerFrame.icon:SetAtlas("UI-QuestPoiImportant-QuestNumber-SuperTracked")
            pointerFrame.icon:SetSize(34, 48)
            pointerFrame.icon:SetPoint("BOTTOM", pointerFrame, "BOTTOM", 0, 5)
            pointerFrame.icon:SetDesaturated(true)
            pointerFrame.icon:SetTexelSnappingBias(0.0)
            pointerFrame.icon:SetSnapToPixelGrid(false)
        end
        
        -- Apply pointer scale
        local pointerScale
        do
            local pm = AC.ProfileManager
            local scalePixels = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.pointerScale")
            if type(scalePixels) == "number" then
                local currentScale = AC.ConvertPixelsToScale and AC:ConvertPixelsToScale(scalePixels, 50, 360, 1, 12) or 6.5
                pointerScale = 0.5 + (currentScale - 1) * (2.5 / 11)
            else
                local rawScale = db.pointerScale or 100
                if rawScale <= 12 then
                    pointerScale = 0.5 + (rawScale - 1) * (2.5 / 11)
                else
                    pointerScale = rawScale / 100
                end
            end
            pointerScale = math.max(0.5, math.min(pointerScale or 1.0, 3.0))
            pointerFrame:SetScale(pointerScale)
        end
        
        -- Apply pointer offsets
        local ptrOffX, ptrOffY = 0, 0
        do
            local pm = AC.ProfileManager
            
            -- Check if Link Horizontal is enabled - if so, use scale-compensated offset
            local linkHorizontal = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.linkHorizontal")
            if linkHorizontal == nil then linkHorizontal = db.linkHorizontal end
            
            local px, py
            if linkHorizontal then
                -- LINKED MODE: Calculate scale-compensated offset so icons stay visually aligned
                local classOffX = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.offsetX")
                if type(classOffX) ~= "number" then classOffX = db.offsetX or 0 end
                
                -- Get class icon scale for compensation
                local classScalePixels = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.scale")
                local classScale = 1.0
                if type(classScalePixels) == "number" then
                    local currentScale = AC.ConvertPixelsToScale and AC:ConvertPixelsToScale(classScalePixels, 50, 360, 1, 12) or 6.5
                    classScale = 0.5 + (currentScale - 1) * (2.5 / 11)
                else
                    local rawScale = db.scale or 100
                    if rawScale <= 12 then
                        classScale = 0.5 + (rawScale - 1) * (2.5 / 11)
                    else
                        classScale = rawScale / 100
                    end
                end
                classScale = math.max(0.5, math.min(classScale or 1.0, 3.0))
                
                -- Scale-compensated offset: ptrOffX = (classOffX * classScale) / pointerScale
                if pointerScale > 0 then
                    px = (classOffX * classScale) / pointerScale
                else
                    px = classOffX
                end
            else
                -- UNLINKED MODE: Use pointer's own horizontal offset
                px = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.pointerOffsetX")
                if type(px) ~= "number" then px = db.pointerOffsetX or 0 end
            end
            
            py = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.pointerOffsetY")
            if type(py) ~= "number" then py = db.pointerOffsetY or 0 end
            
            ptrOffX, ptrOffY = tonumber(px) or 0, tonumber(py) or 0
        end
        
        -- Position pointer above class icon (both share same horizontal center when offset=0)
        local basePointerY = 40
        -- Store offsets for OnUpdate handler
        pointerFrame.offsetX = ptrOffX
        pointerFrame.offsetY = basePointerY + ptrOffY
        
        -- Color pointer based on class
        if class and RAID_CLASS_COLORS[class] then
            local classColor = RAID_CLASS_COLORS[class]
            pointerFrame.icon:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
        end
        
        pointerFrame:Show()
    else
        local pointerFrame = independentFrames[unitForData .. "_pointer"]
        if pointerFrame then
            pointerFrame:Hide()
        end
    end
    
    -- ========================================================================
    -- HIDE HEALTH BARS (Enhanced for Midnight compatibility and reliability)
    -- ========================================================================
    
    if db.hideHealthBars then
        -- BBP PATTERN: Use flag to track state
        if not frame.__acClassIndicatorActive then
            -- ENHANCED: Multiple methods for better reliability
            -- Method 1: Hide HealthBarsContainer (standard approach)
            if frame.HealthBarsContainer then
                -- In Midnight, check if we can manipulate alpha
                local canUseAlpha = true
                if AC.IsMidnight and AC:IsMidnight() then
                    -- In Midnight, check if we're in restricted content
                    canUseAlpha = not AC:IsInRestrictedContent()
                end
                
                if canUseAlpha then
                    frame.HealthBarsContainer:SetAlpha(0)
                else
                    -- Fallback for Midnight restricted content: hide individual bars
                    if frame.HealthBarsContainer.HealthBar then
                        frame.HealthBarsContainer.HealthBar:Hide()
                    end
                    if frame.HealthBarsContainer.AbsorbBar then
                        frame.HealthBarsContainer.AbsorbBar:Hide()
                    end
                    if frame.HealthBarsContainer.HealPrediction then
                        frame.HealthBarsContainer.HealPrediction:Hide()
                    end
                    if frame.HealthBarsContainer.TempMaxHealthLoss then
                        frame.HealthBarsContainer.TempMaxHealthLoss:Hide()
                    end
                end
            end
            
            -- Method 2: Hide selection highlight (more reliable)
            if frame.selectionHighlight then
                frame.selectionHighlight:SetAlpha(0)
            end
            
            -- Method 3: Try to hide individual health bar components (fallback)
            if frame.healthBar then
                frame.healthBar:Hide()
            end
            
            -- Method 4: Use CVar approach for additional reliability (if available)
            -- This affects all nameplates globally but provides consistent behavior
            if not frame.__acHealthBarCVarSet and not AC.IsMidnight then
                -- Store original value before changing
                frame.__acOriginalNameplateShowFriends = GetCVar("nameplateShowFriends")
                SetCVar("nameplateShowFriends", "1") -- Ensure friendly nameplates are shown
                frame.__acHealthBarCVarSet = true
            end
            
            frame.__acClassIndicatorActive = true  -- Set flag
        end
    else
        -- Restore if previously hidden
        if frame.__acClassIndicatorActive then
            -- Restore HealthBarsContainer
            if frame.HealthBarsContainer then
                local canUseAlpha = true
                if AC.IsMidnight and AC:IsMidnight() then
                    canUseAlpha = not AC:IsInRestrictedContent()
                end
                
                if canUseAlpha then
                    frame.HealthBarsContainer:SetAlpha(1)
                else
                    -- Restore individual bars for Midnight restricted content
                    if frame.HealthBarsContainer.HealthBar then
                        frame.HealthBarsContainer.HealthBar:Show()
                    end
                    if frame.HealthBarsContainer.AbsorbBar then
                        frame.HealthBarsContainer.AbsorbBar:Show()
                    end
                    if frame.HealthBarsContainer.HealPrediction then
                        frame.HealthBarsContainer.HealPrediction:Show()
                    end
                    if frame.HealthBarsContainer.TempMaxHealthLoss then
                        frame.HealthBarsContainer.TempMaxHealthLoss:Show()
                    end
                end
            end
            
            -- Restore selection highlight
            if frame.selectionHighlight then
                frame.selectionHighlight:SetAlpha(0.22)
            end
            
            -- Restore individual health bar
            if frame.healthBar then
                frame.healthBar:Show()
            end
            
            -- Restore CVar if we changed it
            if frame.__acHealthBarCVarSet and frame.__acOriginalNameplateShowFriends then
                SetCVar("nameplateShowFriends", frame.__acOriginalNameplateShowFriends)
                frame.__acHealthBarCVarSet = nil
                frame.__acOriginalNameplateShowFriends = nil
            end
            
            frame.__acClassIndicatorActive = nil  -- Clear flag
        end
    end
    
    -- ========================================================================
    -- HIDE NAMES (BBP Pattern)
    -- ========================================================================
    
    -- Only hide names when class icons are actually showing (not when feature is off/hidden)
    if frame.ArenaCore_ClassIndicator and frame.ArenaCore_ClassIndicator:IsShown() then
        -- Hide name when class icon is showing (BBP pattern)
        -- BBP uses classIndicatorHideName flag which is checked in ConsolidatedUpdateName
        frame.classIndicatorHideName = true
        if frame.name then
            frame.name:SetText("")
        end
    else
        -- Restore name when class icon is hidden
        frame.classIndicatorHideName = false
    end
end

-- ============================================================================
-- REFRESH FUNCTION: Called when settings change
-- ============================================================================

function AC:RefreshPartyClassIcons()
    -- Refresh all visible nameplates
    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        -- Universal nameplate addon compatibility
        -- Plater/Platynator use nameplate.unitFrame (lowercase 'u')
        -- Blizzard uses nameplate.UnitFrame (uppercase 'U')
        local frame = nameplate.unitFrame or nameplate.UnitFrame
        if frame and not frame:IsForbidden() and not frame:IsProtected() then
            AC.UpdatePartyClassIndicator(frame)
        end
    end
    
    -- ENHANCED: Start persistent health bar hiding refresh if enabled
    AC:EnsureHealthBarHidingPersistence()
end

-- ============================================================================
-- INDEPENDENT REFRESH FUNCTIONS: Update only specific elements without flickering
-- ============================================================================

-- Refresh ONLY class icon positioning/scale (doesn't touch pointers)
function AC:RefreshClassIconsOnly()
    local db = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.partyClassSpecs
    if not db then return end
    
    -- Get current class icon settings
    local pm = AC.ProfileManager
    local offX = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.offsetX")
    local offY = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.offsetY")
    local scalePixels = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.scale")
    
    if type(offX) ~= "number" then offX = db.offsetX or 0 end
    if type(offY) ~= "number" then offY = db.offsetY or 0 end
    
    local baseY = 8
    
    -- Calculate scale
    local finalScale = 1.0
    if type(scalePixels) == "number" then
        local currentScale = AC.ConvertPixelsToScale and AC:ConvertPixelsToScale(scalePixels, 50, 360, 1, 12) or 6.5
        finalScale = 0.5 + (currentScale - 1) * (2.5 / 11)
    else
        local rawScale = db.scale or 100
        if rawScale <= 12 then
            finalScale = 0.5 + (rawScale - 1) * (2.5 / 11)
        else
            finalScale = rawScale / 100
        end
    end
    finalScale = math.max(0.5, math.min(finalScale or 1.0, 3.0))
    
    -- Update all existing class icon frames directly (no recreation)
    for key, classFrame in pairs(independentFrames) do
        if not key:find("_pointer") and classFrame.offsetX ~= nil then
            classFrame.offsetX = offX
            classFrame.offsetY = baseY + offY
            classFrame:SetScale(finalScale)
        end
    end
end

-- Refresh ONLY pointer positioning/scale (doesn't touch class icons)
function AC:RefreshPointersOnly()
    local db = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.partyClassSpecs
    if not db then return end
    
    local pm = AC.ProfileManager
    
    -- Check if Link Horizontal is enabled
    local linkHorizontal = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.linkHorizontal")
    if linkHorizontal == nil then linkHorizontal = db.linkHorizontal end
    
    -- Get pointer scale first (needed for scale compensation)
    local ptrScalePixels = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.pointerScale")
    local pointerScale = 1.0
    if type(ptrScalePixels) == "number" then
        local currentScale = AC.ConvertPixelsToScale and AC:ConvertPixelsToScale(ptrScalePixels, 50, 360, 1, 12) or 6.5
        pointerScale = 0.5 + (currentScale - 1) * (2.5 / 11)
    else
        local rawScale = db.pointerScale or 100
        if rawScale <= 12 then
            pointerScale = 0.5 + (rawScale - 1) * (2.5 / 11)
        else
            pointerScale = rawScale / 100
        end
    end
    pointerScale = math.max(0.5, math.min(pointerScale or 1.0, 3.0))
    
    -- Get pointer offsets
    local ptrOffX, ptrOffY
    if linkHorizontal then
        -- LINKED MODE: Calculate scale-compensated offset so icons stay visually aligned
        -- Get class icon's horizontal offset and scale
        local classOffX = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.offsetX")
        if type(classOffX) ~= "number" then classOffX = db.offsetX or 0 end
        
        local classScalePixels = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.scale")
        local classScale = 1.0
        if type(classScalePixels) == "number" then
            local currentScale = AC.ConvertPixelsToScale and AC:ConvertPixelsToScale(classScalePixels, 50, 360, 1, 12) or 6.5
            classScale = 0.5 + (currentScale - 1) * (2.5 / 11)
        else
            local rawScale = db.scale or 100
            if rawScale <= 12 then
                classScale = 0.5 + (rawScale - 1) * (2.5 / 11)
            else
                classScale = rawScale / 100
            end
        end
        classScale = math.max(0.5, math.min(classScale or 1.0, 3.0))
        
        -- Scale-compensated offset: ensures both icons visually align at same horizontal position
        -- Formula: pointerVisualX = classVisualX → ptrOffX * ptrScale = classOffX * classScale
        -- So: ptrOffX = (classOffX * classScale) / ptrScale
        if pointerScale > 0 then
            ptrOffX = (classOffX * classScale) / pointerScale
        else
            ptrOffX = classOffX
        end
    else
        -- UNLINKED MODE: Use pointer's own horizontal offset
        ptrOffX = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.pointerOffsetX")
        if type(ptrOffX) ~= "number" then ptrOffX = db.pointerOffsetX or 0 end
    end
    
    ptrOffY = pm and pm.GetSetting and pm:GetSetting("moreGoodies.partyClassSpecs.pointerOffsetY")
    if type(ptrOffY) ~= "number" then ptrOffY = db.pointerOffsetY or 0 end
    
    local basePointerY = 40
    
    -- Update all existing pointer frames directly (no recreation)
    for key, pointerFrame in pairs(independentFrames) do
        if key:find("_pointer") and pointerFrame.offsetX ~= nil then
            pointerFrame.offsetX = ptrOffX
            pointerFrame.offsetY = basePointerY + ptrOffY
            pointerFrame:SetScale(pointerScale)
        end
    end
end

-- ============================================================================
-- PERSISTENT HEALTH BAR HIDING (Enhanced reliability)
-- ============================================================================

-- Timer reference for persistent refresh
local healthBarRefreshTimer = nil

function AC:EnsureHealthBarHidingPersistence()
    local db = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.partyClassSpecs
    
    if db and db.hideHealthBars then
        -- Start periodic refresh if health bar hiding is enabled
        if not healthBarRefreshTimer then
            healthBarRefreshTimer = C_Timer.NewTicker(0.5, function()
                AC:RefreshPartyClassIcons()
            end)
        end
    else
        -- Stop refresh if health bar hiding is disabled
        if healthBarRefreshTimer then
            healthBarRefreshTimer:Cancel()
            healthBarRefreshTimer = nil
        end
    end
end

-- Enhanced refresh with additional health bar checks
local originalUpdatePartyClassIndicator = AC.UpdatePartyClassIndicator
AC.UpdatePartyClassIndicator = function(frame)
    -- Call original function first
    if originalUpdatePartyClassIndicator then
        originalUpdatePartyClassIndicator(frame)
    end
    
    -- ENHANCED: Additional health bar hiding enforcement
    local db = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.partyClassSpecs
    
    if db and db.hideHealthBars and frame.__acClassIndicatorActive then
        -- Re-apply health bar hiding to combat overrides from other addons
        if frame.HealthBarsContainer then
            local canUseAlpha = true
            if AC.IsMidnight and AC:IsMidnight() then
                canUseAlpha = not AC:IsInRestrictedContent()
            end
            
            if canUseAlpha and frame.HealthBarsContainer:GetAlpha() > 0 then
                -- Something overrode our alpha setting, re-apply it
                frame.HealthBarsContainer:SetAlpha(0)
            end
        end
        
        -- Check individual health bar visibility
        if frame.healthBar and frame.healthBar:IsShown() then
            frame.healthBar:Hide()
        end
    end
end

-- ============================================================================
-- HOOK: Prevent Blizzard from showing names when hideNameOverride is set
-- ============================================================================

-- Hook CompactUnitFrame_UpdateName to enforce classIndicatorHideName
local function OnNameUpdate(frame)
    if not frame or not frame.unit or not frame.unit:find("nameplate") then return end
    if frame:IsForbidden() or frame:IsProtected() then return end
    
    -- If we set classIndicatorHideName, enforce it (BBP pattern)
    -- Only use SetText - let BBP handle alpha via its own system
    if frame.classIndicatorHideName and frame.name then
        frame.name:SetText("")
    end
end

-- Register the hook after a short delay to ensure CompactUnitFrame_UpdateName exists
C_Timer.After(0.1, function()
    if CompactUnitFrame_UpdateName then
        hooksecurefunc("CompactUnitFrame_UpdateName", OnNameUpdate)
    end
end)

-- ============================================================================
-- INTEGRATION: This will be called from BlackoutEngine's NAME_PLATE_UNIT_ADDED
-- ============================================================================

-- Module loaded (debug message removed for cleaner startup)

-- ============================================================================
-- CLEANUP: Ensure timer is stopped on addon shutdown
-- ============================================================================

-- Hook into addon shutdown to clean up timer
local function OnAddonShutdown()
    if healthBarRefreshTimer then
        healthBarRefreshTimer:Cancel()
        healthBarRefreshTimer = nil
    end
end

-- Register cleanup on addon reload or logout
local cleanupFrame = CreateFrame("Frame")
cleanupFrame:RegisterEvent("PLAYER_LOGOUT") -- Triggered on logout and reload
cleanupFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGOUT" then
        OnAddonShutdown()
    end
end)
