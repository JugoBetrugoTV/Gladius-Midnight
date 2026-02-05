local AC = _G.ArenaCore or {}

local function GetAC()
    if _G.ArenaCore and AC ~= _G.ArenaCore then
        AC = _G.ArenaCore
    end
    return AC
end

local DRMidnight = {}

--[[
    Midnight DR Tracking Module
    Uses new C_SpellDiminish API while preserving ArenaCore's existing design:
    - Custom borders (orange/green/yellow/red based on severity)
    - Stage text (1/3, 2/3, 3/3) with color coding
    - Timer text (white countdown)
    - Same positioning/sizing as existing DR system
]]

local MAX_ARENA_ENEMIES = 3

-- Map Midnight DR categories to ArenaCore category names
local CATEGORY_MAP = {
    [Enum.SpellDiminishCategory.Root] = "root",
    [Enum.SpellDiminishCategory.Stun] = "stun",
    [Enum.SpellDiminishCategory.Incapacitate] = "incapacitate",
    [Enum.SpellDiminishCategory.Disorient] = "disorient",
    [Enum.SpellDiminishCategory.Silence] = "silence",
    [Enum.SpellDiminishCategory.Disarm] = "disarm",
    [Enum.SpellDiminishCategory.AoEKnockback] = "knockback",
    [Enum.SpellDiminishCategory.Taunt] = "taunt"
}

-- Reverse map for lookups
local CATEGORY_TO_ENUM = {}
for enum, name in pairs(CATEGORY_MAP) do
    CATEGORY_TO_ENUM[name] = enum
end

-- Custom icon overrides removed - using Blizzard default icons

local function CacheCategoryIcons()
    if DRMidnight.__categoryIconCache then return end
    
    DRMidnight.__categoryIconCache = {}
    
    for enumValue, categoryName in pairs(CATEGORY_MAP) do
        if categoryName ~= "disorient" then
            local catInfo
            pcall(function()
                catInfo = C_SpellDiminish.GetSpellDiminishCategoryInfo(enumValue)
            end)
            if catInfo then
                pcall(function()
                    if catInfo.icon then
                        DRMidnight.__categoryIconCache[enumValue] = catInfo.icon
                    end
                end)
            end
        end
    end
end

local function InstallBlizzardTrayHook()
    if DRMidnight.__trayHookInstalled then return end

    local function TryInstall()
        if DRMidnight.__trayHookInstalled then return true end
        if not _G.SpellDiminishStatusTrayItemMixin then return false end
        if not hooksecurefunc then return false end

        hooksecurefunc(_G.SpellDiminishStatusTrayItemMixin, "SetCategoryInfo", function(self, categoryInfo)
            if not self or not categoryInfo or not self.Icon then return end

            if not self.ArenaCoreBorder then
                local border = self:CreateTexture(nil, "OVERLAY")
                border:SetAllPoints()
                border:SetTexture("Interface/AddOns/ArenaCore/Media/Classicons/Overlays/orangeoverlay.tga")
                border:SetTexCoord(0, 1, 0, 1)
                self.ArenaCoreBorder = border
            end

            self.ArenaCoreBorder:Show()
        end)

        DRMidnight.__trayHookInstalled = true
        return true
    end

    if TryInstall() then
        return
    end

    if DRMidnight.__trayHookLoader then
        return
    end

    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(_, _, addonName)
        if addonName == "Blizzard_SpellDiminishUI" then
            if TryInstall() then
                loader:UnregisterEvent("ADDON_LOADED")
            end
        end
    end)

    DRMidnight.__trayHookLoader = loader
end

-- Track severity per unit per category
local severityTrackers = {}

local function GetSettings()
    local ac = GetAC()
    return ac.DB and ac.DB.profile and ac.DB.profile.diminishingReturns
end

local function SafeSetFont(fontString, size)
    if not fontString then return end
    local ac = GetAC()
    if ac.SafeSetFont then
        ac.SafeSetFont(fontString, ac.FONT_PATH, size, "OUTLINE")
    else
        fontString:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", size, "OUTLINE")
    end
end

local function GetFrameByUnit(unitToken)
    local ac = GetAC()
    local manager = ac.MasterFrameManager or ac.FrameManager
    if not manager or not manager.GetFrames then return nil end
    
    local frames = manager:GetFrames()
    if not frames then return nil end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame and frame.unit == unitToken then
            return frame
        end
    end
    
    return nil
end

--[[
    Creates DR icon frame with ArenaCore's existing design
    Matches the design from DR.lua but adapted for Midnight categories
]]
function DRMidnight:CreateIcon(frame, category)
    local parent = frame.drContainer or frame
    local dr = CreateFrame("Frame", nil, parent)
    
    -- Get size from database
    local db = GetSettings()
    local iconSize = (db and db.sizing and db.sizing.size) or 22
    
    dr:SetSize(iconSize, iconSize)
    dr.category = category
    dr.severity = 0
    dr:Hide()

    -- Background layers (orange borders - will change based on severity)
    local bg1 = dr:CreateTexture(nil, "BACKGROUND")
    bg1:SetAllPoints()
    bg1:SetTexture("Interface/AddOns/ArenaCore/Media/Classicons/Overlays/orangeoverlay.tga")
    bg1:SetTexCoord(0, 1, 0, 1)
    bg1:SetVertexColor(1, 0.4, 0, 1)

    local bg2 = dr:CreateTexture(nil, "BACKGROUND", nil, 1)
    bg2:SetAllPoints()
    bg2:SetTexture("Interface/AddOns/ArenaCore/Media/Classicons/Overlays/orangeoverlay.tga")
    bg2:SetTexCoord(0, 1, 0, 1)
    bg2:SetVertexColor(1, 0.3, 0, 0.8)

    -- Icon texture - size based on database settings
    local icon = dr:CreateTexture(nil, "ARTWORK")
    local inset = math.max(2, iconSize * 0.15)
    icon:SetSize(iconSize - inset, iconSize - inset)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0, 1, 0, 1)

    -- Overlay
    local overlay = dr:CreateTexture(nil, "OVERLAY")
    overlay:SetAllPoints()
    overlay:SetTexture("Interface/AddOns/ArenaCore/Media/Classicons/Overlays/orangeoverlay.tga")
    overlay:SetTexCoord(0, 1, 0, 1)

    -- Cooldown frame - size based on database settings
    local ac = GetAC()
    local cooldown = ac:CreateCooldown(dr, nil, "CooldownFrameTemplate")
    local cooldownSize = iconSize - (iconSize * 0.1)
    cooldown:SetSize(cooldownSize, cooldownSize)
    cooldown:SetPoint("CENTER")
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetDrawEdge(true)
    cooldown:SetSwipeColor(0, 0, 0, 0.8)
    cooldown.noCooldownCount = true
    cooldown.noOCC = true
    
    -- Apply spiral animation settings
    if AC.DRSpiralAnimation and AC.DRSpiralAnimation.ApplySettings then
        AC.DRSpiralAnimation:ApplySettings(cooldown)
    end

    -- White timer text - font size from database
    local fontSize = (db and db.sizing and db.sizing.fontSize) or 10
    local timerText = cooldown:CreateFontString(nil, "OVERLAY")
    timerText:SetPoint("CENTER", dr, "CENTER", 0, 1)
    SafeSetFont(timerText, fontSize)
    timerText:SetTextColor(1, 1, 1, 1)

    -- Colored stage text (1/3, 2/3, 3/3) - font size from database
    local stageSize = (db and db.sizing and db.sizing.stageFontSize) or 8
    local stageText = cooldown:CreateFontString(nil, "OVERLAY")
    stageText:SetPoint("BOTTOMRIGHT", dr, "BOTTOMRIGHT", -2, 2)
    SafeSetFont(stageText, stageSize)
    stageText:SetTextColor(1, 1, 0, 1)

    -- Update stage and severity colors
    -- MIDNIGHT: Only 2 stages now (1=half duration, 2=immune)
    function dr:UpdateStage(stage)
        if not stageText then return end
        
        local db = GetSettings()
        local showStage = db and db.showStageIndicators
        if showStage == nil then showStage = true end
        
        -- Midnight: Only 2 stages - stage 1 = green "½", stage 2+ = red "%"
        local isImmune = (stage or 1) >= 2
        
        if showStage then
            if isImmune then
                stageText:SetText("2/2")
                stageText:SetTextColor(1, 0, 0, 1)  -- Red
            else
                stageText:SetText("1/2")
                stageText:SetTextColor(0, 1, 0, 1)  -- Green
            end
            stageText:Show()
        else
            stageText:Hide()
        end
        
        -- Update border colors if color-coded borders enabled
        local colorBorders = db and db.colorCodedBorders
        if colorBorders and self.overlay and self.background and self.background2 then
            if isImmune then
                -- Red borders for immune
                self.overlay:SetVertexColor(1, 0, 0, 1)
                self.background:SetVertexColor(0.8, 0, 0, 1)
                self.background2:SetVertexColor(0.6, 0, 0, 0.8)
            else
                -- Green borders for active
                self.overlay:SetVertexColor(0, 1, 0, 1)
                self.background:SetVertexColor(0, 0.8, 0, 1)
                self.background2:SetVertexColor(0, 0.6, 0, 0.8)
            end
        else
            -- Default orange borders
            if self.overlay then
                self.overlay:SetVertexColor(1, 1, 1, 1)
            end
            if self.background then
                self.background:SetVertexColor(1, 0.4, 0, 1)
            end
            if self.background2 then
                self.background2:SetVertexColor(1, 0.3, 0, 0.8)
            end
        end
    end

    dr.icon = icon
    dr.cooldown = cooldown
    dr.timerText = timerText
    dr.stageText = stageText
    dr.overlay = overlay
    dr.background = bg1
    dr.background2 = bg2

    return dr
end

--[[
    Ensures frame has Midnight DR setup
]]
function DRMidnight:EnsureFrame(frame)
    if not frame.drContainer then
        frame.drContainer = CreateFrame("Frame", nil, frame)
        frame.drContainer:SetAllPoints(frame)
        frame.drContainer:SetFrameStrata("HIGH")
        frame.drContainer:SetFrameLevel((frame:GetFrameLevel() or 10) + 30)
    end
    
    frame.drIcons = frame.drIcons or {}
    frame.drIconsByEnum = frame.drIconsByEnum or {}
end

--[[
    Handles UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED event
]]
function DRMidnight:OnDRUpdate(unitToken, trackerInfo)
    if not unitToken or not trackerInfo then return end
    
    -- Check if system is supported
    if not C_SpellDiminish or not C_SpellDiminish.IsSystemSupported() then
        return
    end
    
    local frame = GetFrameByUnit(unitToken)
    if not frame then return end
    
    local db = GetSettings()
    if not db or db.enabled == false then return end
    
    -- CRITICAL FIX: Safely extract ALL trackerInfo properties (may be forbidden)
    local category, startTime, duration, showCountdown
    local success = pcall(function()
        category = trackerInfo.category
        startTime = trackerInfo.startTime
        duration = trackerInfo.duration
        showCountdown = trackerInfo.showCountdown
    end)
    if not success or not category then return end
    
    -- Get category info using safe category value
    local categoryInfo
    success = pcall(function()
        categoryInfo = C_SpellDiminish.GetSpellDiminishCategoryInfo(category)
    end)
    if not success or not categoryInfo then return end
    
    -- Safely extract categoryInfo properties
    local categoryIcon
    success = pcall(function()
        categoryIcon = categoryInfo.icon
    end)
    if not success then return end
    
    -- Map to ArenaCore category name
    local categoryName = CATEGORY_MAP[category]
    if not categoryName then return end
    
    -- Check if this category is enabled
    local activeDB = (AC.GetActiveDRSettingsDB and AC:GetActiveDRSettingsDB()) or db
    activeDB.categories = activeDB.categories or {}
    if activeDB.categories[categoryName] == false then
        return
    end
    
    self:EnsureFrame(frame)
    
    -- Get or create DR icon for this category using SAFE category value
    local drIcon = frame.drIconsByEnum[category]
    if not drIcon then
        drIcon = self:CreateIcon(frame, categoryName)
        frame.drIconsByEnum[category] = drIcon
        frame.drIcons[categoryName] = drIcon
    end
    
    -- Set icon texture from Blizzard using SAFE categoryIcon value
    if drIcon.icon then
        if categoryIcon then
            drIcon.icon:SetTexture(categoryIcon)
        end
    end
    
    -- Track severity - only increment on NEW DR applications (when startTime changes)
    local unitGUID = UnitGUID(unitToken)
    if not severityTrackers[unitGUID] then
        severityTrackers[unitGUID] = {}
    end
    if not severityTrackers[unitGUID][category] then
        -- First time seeing this category for this unit
        severityTrackers[unitGUID][category] = {
            severity = 1,
            lastStartTime = startTime,
            lastUpdate = GetTime()
        }
    else
        local tracker = severityTrackers[unitGUID][category]
        -- If more than 18 seconds since last update, reset to 1
        if GetTime() - tracker.lastUpdate > 18 then
            tracker.severity = 1
            tracker.lastStartTime = startTime
        elseif startTime ~= tracker.lastStartTime then
            -- NEW DR application (startTime changed) - increment severity
            tracker.severity = math.min(tracker.severity + 1, 2) -- Midnight only has 2 stages
            tracker.lastStartTime = startTime
        end
        -- Always update lastUpdate time
        tracker.lastUpdate = GetTime()
    end
    
    local severity = severityTrackers[unitGUID][category].severity
    
    -- Update stage display
    if drIcon.UpdateStage then
        drIcon:UpdateStage(severity)
    end
    
    -- Set cooldown using SAFE timing values
    if drIcon.cooldown and startTime and duration then
        CooldownFrame_Set(drIcon.cooldown, startTime, duration, showCountdown)
        
        -- Hide built-in numbers
        drIcon.cooldown:SetHideCountdownNumbers(true)
        
        -- Reapply spiral animation
        if AC.DRSpiralAnimation and AC.DRSpiralAnimation.ApplySettings then
            AC.DRSpiralAnimation:ApplySettings(drIcon.cooldown)
        end
    end
    
    -- Show the icon
    drIcon:Show()
    
    -- Update positions
    if AC.FrameManager and AC.FrameManager.DR and AC.FrameManager.DR.UpdatePositions then
        AC.FrameManager.DR:UpdatePositions(frame)
    end
end

--[[
    Initialize Midnight DR tracking
]]
function DRMidnight:Initialize()
    -- Check if Midnight DR system is available
    if not C_SpellDiminish or not C_SpellDiminish.IsSystemSupported() then
        return false
    end

    InstallBlizzardTrayHook()
    
    -- NUCLEAR FIX: DO NOT register for UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED
    -- This event passes forbidden trackerInfo objects that cause "attempted to index a forbidden table" errors
    -- even when wrapped in pcall (error still logs, just doesn't crash)
    -- 
    -- SOLUTION: Let Blizzard's DR tray handle everything internally via CVar
    -- ArenaCore only positions the tray - Blizzard handles tracking/icons/cooldowns
    -- 
    -- Custom DR features (borders, stage indicators) are disabled until Blizzard provides
    -- a safe API for accessing DR state
    
    -- DEBUG DISABLED: print("|cff8B45FFArena|r|cffB266FFCore|r |cffFFAA00DR_Midnight: Using pure Blizzard DR tray (no custom tracking)|r")
    
    return true
end

--[[
    Update timer text for all active DR icons
]]
function DRMidnight:UpdateTimerText()
    local ac = GetAC()
    local manager = ac.MasterFrameManager or ac.FrameManager
    if not manager or not manager.GetFrames then return end
    
    local frames = manager:GetFrames()
    if not frames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame and frame.drIcons then
            for _, drIcon in pairs(frame.drIcons) do
                if drIcon and drIcon:IsShown() and drIcon.cooldown and drIcon.timerText then
                    local start, duration = drIcon.cooldown:GetCooldownTimes()
                    if start > 0 then
                        local now = GetTime() * 1000
                        local remaining = math.ceil((start + duration - now) / 1000)
                        if remaining > 0 then
                            drIcon.timerText:SetText(tostring(remaining))
                        else
                            drIcon.timerText:SetText("")
                            drIcon:Hide()
                        end
                    end
                end
            end
        end
    end
end

--[[
    Show test icons using Blizzard's category icons
]]
function DRMidnight:ShowTestIcons()
    local ac = GetAC()
    if not ac.testModeEnabled then 
        return 
    end
    
    local db = GetSettings()
    if not db or db.enabled == false then
        self:HideTestIcons()
        return
    end
    
    -- CRITICAL: Manually build category list since Blizzard's GetAllSpellDiminishCategories
    -- doesn't return all categories (missing Silence, Disarm, etc.)
    -- We'll use all 8 enum values and get their info individually
    local allEnumCategories = {
        Enum.SpellDiminishCategory.Root,
        Enum.SpellDiminishCategory.Taunt,
        Enum.SpellDiminishCategory.Stun,
        Enum.SpellDiminishCategory.AoEKnockback,
        Enum.SpellDiminishCategory.Incapacitate,
        Enum.SpellDiminishCategory.Disorient,
        Enum.SpellDiminishCategory.Silence,
        Enum.SpellDiminishCategory.Disarm
    }
    
    local categories = {}
    for _, enumValue in ipairs(allEnumCategories) do
        local catInfo = C_SpellDiminish.GetSpellDiminishCategoryInfo(enumValue)
        -- CRITICAL: Only include categories that have valid icons
        -- Blizzard only provides icons for actively tracked DRs
        -- Safely check for icon property (may be forbidden during round transitions)
        if catInfo then
            local hasIcon = false
            pcall(function()
                hasIcon = catInfo.icon ~= nil
            end)
            if hasIcon then
                table.insert(categories, catInfo)
            end
        end
    end
    
    if #categories == 0 then 
        return 
    end
    
    local manager = ac.MasterFrameManager or ac.FrameManager
    if not manager or not manager.GetFrames then return end
    
    local frames = manager:GetFrames()
    if not frames then return end
    
    local activeDB = (ac.GetActiveDRSettingsDB and ac:GetActiveDRSettingsDB()) or db
    activeDB.categories = activeDB.categories or {}
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            self:EnsureFrame(frame)
            
            local frameID = frame.id or i
            local categoryIndex = 0
            
            -- Show icons for each enabled category
            for _, categoryInfo in ipairs(categories) do
                -- Safely extract categoryInfo properties
                local category, categoryIcon
                local success = pcall(function()
                    category = categoryInfo.category
                    categoryIcon = categoryInfo.icon
                end)
                
                if success and category then
                    local categoryName = CATEGORY_MAP[category]
                    if categoryName then
                        local categoryEnabled = (activeDB.categories[categoryName] ~= false)
                        
                        if categoryEnabled then
                            categoryIndex = categoryIndex + 1
                            
                            -- Get or create icon using SAFE category value
                            local drIcon = frame.drIconsByEnum[category]
                            if not drIcon then
                                drIcon = self:CreateIcon(frame, categoryName)
                                frame.drIconsByEnum[category] = drIcon
                                frame.drIcons[categoryName] = drIcon
                            end
                            
                            -- Set Blizzard's category icon using SAFE categoryIcon value
                            if drIcon.icon then
                                if categoryIcon then
                                    drIcon.icon:SetTexture(categoryIcon)
                                end
                                drIcon.icon:Show()
                                drIcon.icon:SetAlpha(1)
                            end
                            
                            -- MIDNIGHT: Only 2 stages now
                            -- Arena 1 = stage 1 (green ½)
                            -- Arena 2/3 = stage 2 (red %)
                            local stage = (i == 1) and 1 or 2
                            if drIcon.UpdateStage then
                                drIcon:UpdateStage(stage)
                            end
                            
                            -- Set test cooldown
                            if drIcon.cooldown then
                                local cooldownTime = 18.5 - (categoryIndex * 2)
                                drIcon.cooldown:SetCooldown(GetTime(), cooldownTime)
                                drIcon.testCooldownDuration = cooldownTime
                                drIcon.cooldown:SetHideCountdownNumbers(true)
                                
                                -- Apply spiral animation
                                if ac.DRSpiralAnimation and ac.DRSpiralAnimation.ApplySettings then
                                    ac.DRSpiralAnimation:ApplySettings(drIcon.cooldown)
                                end
                            end
                            
                            drIcon:Show()
                            drIcon:SetAlpha(1)
                        end
                    end
                end
            end
            
            -- Update positions
            if ac.FrameManager and ac.FrameManager.DR and ac.FrameManager.DR.UpdatePositions then
                ac.FrameManager.DR:UpdatePositions(frame)
            end
        end
    end
    
    -- Start test ticker if not already running
    if not self.testTicker then
        self.testTicker = C_Timer.NewTicker(1, function()
            local acInner = GetAC()
            if not acInner or not acInner.testModeEnabled then
                if self.testTicker then
                    self.testTicker:Cancel()
                    self.testTicker = nil
                end
                return
            end
            
            self:UpdateTimerText()
            
            -- Refresh cooldowns for test mode
            local mgrInner = acInner.MasterFrameManager or acInner.FrameManager
            if not mgrInner or not mgrInner.GetFrames then return end
            
            local framesInner = mgrInner:GetFrames()
            if not framesInner then return end
            
            for i = 1, MAX_ARENA_ENEMIES do
                local frame = framesInner[i]
                if frame and frame.drIcons then
                    for _, drIcon in pairs(frame.drIcons) do
                        if drIcon and drIcon:IsShown() and drIcon.cooldown and drIcon.testCooldownDuration then
                            local start, duration = drIcon.cooldown:GetCooldownTimes()
                            local now = GetTime() * 1000
                            if start == 0 or now >= (start + duration) then
                                drIcon.cooldown:SetCooldown(GetTime(), drIcon.testCooldownDuration)
                                drIcon.cooldown:SetHideCountdownNumbers(true)
                                
                                if acInner.DRSpiralAnimation and acInner.DRSpiralAnimation.ApplySettings then
                                    acInner.DRSpiralAnimation:ApplySettings(drIcon.cooldown)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end

--[[
    Hide test icons
]]
function DRMidnight:HideTestIcons()
    if self.testTicker then
        self.testTicker:Cancel()
        self.testTicker = nil
    end
    
    local ac = GetAC()
    local manager = ac.MasterFrameManager or ac.FrameManager
    if not manager or not manager.GetFrames then return end
    
    local frames = manager:GetFrames()
    if not frames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame and frame.drIcons then
            for _, icon in pairs(frame.drIcons) do
                if icon then
                    icon:Hide()
                    if icon.cooldown then
                        icon.cooldown:Clear()
                    end
                    if icon.timerText then
                        icon.timerText:SetText("")
                    end
                    icon.testCooldownDuration = nil
                end
            end
        end
    end
end

--[[
    Refresh layout - applies sizing and font settings
    This integrates with the existing DR settings system
]]
function DRMidnight:RefreshLayout()
    local db = GetSettings()
    if not db then return end
    
    local ac = GetAC()
    local manager = ac.MasterFrameManager or ac.FrameManager
    if not manager or not manager.GetFrames then return end
    
    local frames = manager:GetFrames() or {}
    
    -- CRITICAL: If DR tracking is disabled, hide all custom DR icons and return
    if db.enabled == false then
        for i = 1, MAX_ARENA_ENEMIES do
            local frame = frames[i]
            if frame and frame.drIcons then
                for _, drIcon in pairs(frame.drIcons) do
                    if drIcon then
                        drIcon:Hide()
                        if drIcon.cooldown then
                            drIcon.cooldown:Clear()
                        end
                    end
                end
            end
            -- Also hide Blizzard DR tray if in arena
            if frame and frame.drTray then
                frame.drTray:Hide()
            end
        end
        self:HideTestIcons()
        return
    end
    
    -- CRITICAL: In live arena, don't show custom DR icons - Blizzard tray handles it
    local _, instanceType = IsInInstance()
    local isInArena = (instanceType == "arena")
    
    if isInArena then
        -- Hide custom DR icons in live arena
        for i = 1, MAX_ARENA_ENEMIES do
            local frame = frames[i]
            if frame and frame.drIcons then
                for _, drIcon in pairs(frame.drIcons) do
                    if drIcon then
                        drIcon:Hide()
                    end
                end
            end
            -- Ensure Blizzard DR tray is visible
            if frame and frame.drTray then
                if frame.drTray.UpdateShownState then
                    frame.drTray:UpdateShownState()
                else
                    frame.drTray:Show()
                end
            end
        end
        return
    end

    -- Only apply sizing/positioning to custom DR icons in test mode
    local iconSize = (db.sizing and db.sizing.size) or 22
    local fontSize = (db.sizing and db.sizing.fontSize) or 10
    local stageSize = (db.sizing and db.sizing.stageFontSize) or 8

    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            self:EnsureFrame(frame)
            for _, drFrame in pairs(frame.drIcons or {}) do
                if drFrame then
                    drFrame:SetSize(iconSize, iconSize)
                    if drFrame.icon then
                        local inset = math.max(2, iconSize * 0.15)
                        drFrame.icon:SetSize(iconSize - inset, iconSize - inset)
                    end
                    if drFrame.cooldown then
                        local cooldownSize = iconSize - (iconSize * 0.1)
                        drFrame.cooldown:SetSize(cooldownSize, cooldownSize)
                    end
                    if drFrame.timerText then
                        SafeSetFont(drFrame.timerText, fontSize)
                    end
                    if drFrame.stageText then
                        SafeSetFont(drFrame.stageText, stageSize)
                    end
                end
            end
            
            -- Use existing DR positioning system
            if ac.FrameManager and ac.FrameManager.DR and ac.FrameManager.DR.UpdatePositions then
                ac.FrameManager.DR:UpdatePositions(frame)
            end
        end
    end
    
    -- Show test icons if in test mode
    if ac.testModeEnabled then
        self:ShowTestIcons()
    end
end

--[[
    Clear all DR trackers (on arena end, etc.)
]]
function DRMidnight:ClearAll()
    severityTrackers = {}
    
    local ac = GetAC()
    local manager = ac.MasterFrameManager or ac.FrameManager
    if not manager or not manager.GetFrames then return end
    
    local frames = manager:GetFrames()
    if not frames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame and frame.drIcons then
            for _, icon in pairs(frame.drIcons) do
                if icon then
                    icon:Hide()
                    if icon.cooldown then
                        icon.cooldown:Clear()
                    end
                    if icon.timerText then
                        icon.timerText:SetText("")
                    end
                end
            end
        end
    end
end

-- Expose module
AC.DRMidnight = DRMidnight

-- Auto-initialize if in Midnight
local function TryInitialize()
    local ac = GetAC()
    
    -- Check if we're in Midnight
    if not ac.Midnight or not ac.Midnight.isMidnight then
        return
    end
    
    -- Initialize Midnight DR tracking
    if DRMidnight:Initialize() then
        -- DEBUG DISABLED: print("|cff8B45FFArena|r|cffB266FFCore|r |cff00FF00Midnight DR tracking enabled|r")
    else
        print("|cff8B45FFArena|r|cffB266FFCore|r |cffFF0000Midnight DR tracking failed to initialize|r")
    end
end

-- Try to initialize after a short delay to ensure AC.Midnight is loaded
C_Timer.After(0.5, TryInitialize)

-- Also try immediate initialization in case Midnight is already loaded
if AC.Midnight and AC.Midnight.isMidnight then
    TryInitialize()
end

return DRMidnight
