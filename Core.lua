--[[
    Gladius Midnight - Core
    Arena Unit Frames for WoW Midnight 12.0

    Modular architecture - each component is a separate module

    Midnight 12.0 API Notes:
    - Secret values: Use issecretvalue() to check before table index access
    - StatusBar:SetValue() accepts secret values natively
    - FontString:SetText() accepts secret strings natively
    - C_CurveUtil.CreateColorCurve() for health bar coloring with secrets
    - C_DurationUtil.CreateDuration() for timer displays with secrets
    - Cooldown:SetCooldownFromDurationObject() for cooldown frames
]]

local addonName, addon = ...

-- Create main addon object using Ace3
local GladiusMidnight = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
addon.Core = GladiusMidnight

-- ============================================================================
-- Default Settings (Gladius Classic Style)
-- ============================================================================

local defaults = {
    profile = {
        enabled = true,
        locked = true,

        -- Frame settings (balanced proportions)
        frameWidth = 220,
        frameHeight = 50,
        scale = 1.0,
        spacing = 40,  -- Space for auras/castbar between frames
        growDirection = "DOWN",

        -- Position
        posX = 500,
        posY = 0,

        -- Minimap
        minimap = {
            hide = false,
        },

        -- Module toggles
        modules = {
            classIcon = true,
            health = true,
            power = true,
            trinket = true,
            racial = true,
            drTracker = true,
            castBar = true,
            auras = true,
        },

        -- Visual settings
        targetHighlight = true,
        immunityGlow = true,
        hideBlizzardFrames = true,

        -- Module-specific settings (balanced sizes)
        classIcon = {
            size = 42,
            position = "LEFT",
            showSpec = true,
        },
        health = {
            height = 18,
            showText = true,
            showPercent = true,
            showAbsolute = true,
            showName = true,
            showSpec = true,
            colorByClass = true,
        },
        power = {
            height = 5,
            showText = false,
        },
        trinket = {
            size = 24,
            position = "RIGHT",
            showTimer = true,
        },
        racial = {
            size = 24,
            position = "RIGHT",
            showTimer = true,
        },
        drTracker = {
            iconSize = 22,
            showTimer = true,
            maxIcons = 3,
        },
        castBar = {
            height = 12,
            showIcon = true,
            insideFrame = true,
        },
        auras = {
            iconSize = 20,
            maxAuras = 4,
        },
    }
}

-- ============================================================================
-- Frame Storage
-- ============================================================================

GladiusMidnight.frames = {}
GladiusMidnight.modules = {}
GladiusMidnight.testMode = false
GladiusMidnight.arenaSize = 0
GladiusMidnight.prepPhase = false

-- ============================================================================
-- Module Registration
-- ============================================================================

function GladiusMidnight:RegisterModule(name, module)
    self.modules[name] = module
    if module.OnRegister then
        module:OnRegister(self)
    end
end

function GladiusMidnight:GetModule(name)
    return self.modules[name]
end

function GladiusMidnight:IsModuleEnabled(name)
    return self.db.profile.modules[name] == true
end

-- ============================================================================
-- Arena Frame Creation (Gladius Classic Style)
-- ============================================================================

function GladiusMidnight:CreateArenaFrame(index)
    local unit = "arena" .. index
    local frameName = "GladiusMidnightFrame" .. index

    -- Main container frame
    local frame = CreateFrame("Button", frameName, UIParent, "BackdropTemplate,SecureUnitButtonTemplate")
    frame:SetSize(self.db.profile.frameWidth, self.db.profile.frameHeight)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:RegisterForClicks("AnyUp")
    frame:SetClampedToScreen(true)

    -- IMPORTANT: Allow child frames to render outside parent bounds
    frame:SetClipsChildren(false)

    frame.unit = unit
    frame.index = index
    frame.displayedUnit = unit

    -- Add optionTable for Blizzard compatibility
    frame.optionTable = {
        displayOnlyDispellableDebuffs = false,
        displayDebuffs = true,
        displayBuffs = true,
        displayNonBossDebuffs = true,
        maxDispelDebuffs = 3,
        maxDebuffs = 3,
        maxBuffs = 3,
    }

    frame.blockedAuraInstanceIDsTable = frame.blockedAuraInstanceIDsTable or {}

    -- Dark background (Gladius style)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -- Target highlight glow (Red border when targeted - Gladius style)
    local targetGlow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    targetGlow:SetPoint("TOPLEFT", -2, 2)
    targetGlow:SetPoint("BOTTOMRIGHT", 2, -2)
    targetGlow:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    targetGlow:SetBackdropBorderColor(1, 0, 0, 1)  -- Red for target
    targetGlow:SetFrameLevel(frame:GetFrameLevel() + 5)
    targetGlow:Hide()
    frame.targetGlow = targetGlow

    -- Immunity glow
    local immunityGlow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    immunityGlow:SetPoint("TOPLEFT", -3, 3)
    immunityGlow:SetPoint("BOTTOMRIGHT", 3, -3)
    immunityGlow:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 3,
    })
    immunityGlow:SetBackdropBorderColor(1, 1, 1, 1)
    immunityGlow:SetFrameLevel(frame:GetFrameLevel() - 1)
    immunityGlow:Hide()
    frame.immunityGlow = immunityGlow
    frame.hasImmunity = false
    frame.immunityType = nil

    -- Secure targeting
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "focus")
    frame:SetAttribute("unit", unit)
    RegisterUnitWatch(frame)

    -- Drag handlers
    frame:SetScript("OnDragStart", function(f)
        if not GladiusMidnight.db.profile.locked then
            f:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if f.index == 1 then
            local scale = f:GetEffectiveScale()
            local uiScale = UIParent:GetEffectiveScale()
            local centerX, centerY = f:GetCenter()
            local uiCenterX, uiCenterY = UIParent:GetCenter()

            if centerX and uiCenterX then
                local x = (centerX - uiCenterX) * (scale / uiScale)
                local y = (centerY - uiCenterY) * (scale / uiScale)
                local frameScale = GladiusMidnight.db.profile.scale or 1
                GladiusMidnight.db.profile.posX = x / frameScale
                GladiusMidnight.db.profile.posY = y / frameScale
            end
        end
        local db = GladiusMidnight.db.profile
        local prevFrame = GladiusMidnight.frames[1]
        for i = 2, 3 do
            local otherFrame = GladiusMidnight.frames[i]
            if otherFrame and prevFrame then
                otherFrame:ClearAllPoints()
                local spacing = db.spacing
                if db.growDirection == "DOWN" then
                    otherFrame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
                elseif db.growDirection == "UP" then
                    otherFrame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
                elseif db.growDirection == "LEFT" then
                    otherFrame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                else
                    otherFrame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
                end
                prevFrame = otherFrame
            end
        end
    end)

    -- Container for module elements
    frame.moduleFrames = {}

    -- Hide by default
    frame:Hide()

    return frame
end

-- ============================================================================
-- Frame Updates
-- ============================================================================

function GladiusMidnight:UpdateFrame(frame, testData)
    if not frame then return end

    local db = self.db.profile

    if not InCombatLockdown() then
        frame:SetSize(db.frameWidth, db.frameHeight)
        frame:SetScale(db.scale)
    end

    for name, module in pairs(self.modules) do
        if self:IsModuleEnabled(name) then
            if module.Update then
                module:Update(frame, testData)
            end
        else
            if frame.moduleFrames and frame.moduleFrames[name] then
                frame.moduleFrames[name]:Hide()
            end
        end
    end

    self:UpdateTargetHighlight()
end

function GladiusMidnight:UpdateAllFrames()
    local testData = self.testMode and self:GetTestData() or nil

    for i = 1, 3 do
        local frame = self.frames[i]
        if frame then
            self:UpdateFrame(frame, testData)
        end
    end
    self:PositionFrames()

    self:UpdateBlizzardDRSize()
    self:UpdateBlizzardCastBarSize()
    self:UpdateBlizzardDebuffSize()
end

function GladiusMidnight:GetTestData()
    return {
        class = "MAGE",
        name = "TestPlayer",
        health = 75,
        maxHealth = 100,
        power = 80,
        maxPower = 100,
        powerType = Enum.PowerType.Mana,
    }
end

function GladiusMidnight:PositionFrames()
    if InCombatLockdown() then
        return
    end

    local db = self.db.profile
    local prevFrame = nil
    local numFrames = self.arenaSize > 0 and self.arenaSize or 3

    for i = 1, numFrames do
        local frame = self.frames[i]
        if frame then
            frame:ClearAllPoints()

            if i == 1 then
                frame:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)
            else
                local spacing = db.spacing
                if db.growDirection == "DOWN" then
                    frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
                elseif db.growDirection == "UP" then
                    frame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
                elseif db.growDirection == "LEFT" then
                    frame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                else
                    frame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
                end
            end

            frame:SetScale(db.scale)
            prevFrame = frame
        end
    end
end

-- ============================================================================
-- Arena Detection
-- ============================================================================

function GladiusMidnight:DetectArenaType()
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then
        self.arenaSize = 0
        return
    end

    if C_PvP and C_PvP.IsSoloShuffle and C_PvP.IsSoloShuffle() then
        self.arenaSize = 3
        self:Print("Solo Shuffle erkannt")
        return
    end

    if C_PvP and C_PvP.GetActiveMatchBracket then
        local bracket = C_PvP.GetActiveMatchBracket()
        if bracket == 1 then
            self.arenaSize = 2
        else
            self.arenaSize = 3
        end
    else
        self.arenaSize = 3
    end

    self:Print(self.arenaSize .. "v" .. self.arenaSize .. " Arena erkannt")
end

-- ============================================================================
-- Test Mode
-- ============================================================================

function GladiusMidnight:ToggleTest()
    self.testMode = not self.testMode

    if self.testMode then
        self:Print("Test Modus |cFF00FF00aktiviert|r")

        local classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
                          "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
                          "DRUID", "DEMONHUNTER", "EVOKER" }

        local specs = {
            MAGE = {62, 63, 64},       -- Arcane, Fire, Frost
            WARRIOR = {71, 72, 73},    -- Arms, Fury, Prot
            ROGUE = {259, 260, 261},   -- Assassination, Outlaw, Sub
            HUNTER = {253, 254, 255},  -- BM, MM, Survival
        }

        for i = 1, 3 do
            local frame = self.frames[i]
            if frame then
                UnregisterUnitWatch(frame)

                local testClass = classes[math.random(1, #classes)]
                frame.class = testClass

                -- Assign a spec if available
                if specs[testClass] then
                    frame.specID = specs[testClass][math.random(1, #specs[testClass])]
                end

                local testData = {
                    class = testClass,
                    health = math.random(20, 100),
                    maxHealth = 100,
                    power = math.random(0, 100),
                    maxPower = 100,
                    powerType = Enum.PowerType.Mana,
                }

                self:UpdateFrame(frame, testData)
                frame:Show()
            end
        end

        self:PositionFrames()
    else
        self:Print("Test Modus |cFFFF0000deaktiviert|r")

        for i = 1, 3 do
            local frame = self.frames[i]
            if frame then
                frame:Hide()
                frame.class = nil
                frame.specID = nil
                RegisterUnitWatch(frame)

                if frame.moduleFrames then
                    if frame.moduleFrames.drTracker then
                        frame.moduleFrames.drTracker:Hide()
                    end
                    if frame.moduleFrames.castBar then
                        frame.moduleFrames.castBar:Hide()
                    end
                    if frame.moduleFrames.auras then
                        frame.moduleFrames.auras:Hide()
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- Initialization
-- ============================================================================

function GladiusMidnight:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("GladiusMidnightDB", defaults, true)

    for i = 1, 3 do
        self.frames[i] = self:CreateArenaFrame(i)
    end

    for name, module in pairs(self.modules) do
        if module.OnInitialize then
            module:OnInitialize(self)
        end
    end

    for i = 1, 3 do
        local frame = self.frames[i]
        for name, module in pairs(self.modules) do
            if module.CreateElements then
                module:CreateElements(frame)
            end
        end
    end

    self:RegisterChatCommand("gladius", "SlashCommand")
    self:RegisterChatCommand("gm", "SlashCommand")
    self:RegisterChatCommand("gg", "SurrenderArena")

    self:Print("Geladen - |cFF00FF00/gladius test|r zum Testen, |cFFFF6600/gg|r zum Aufgeben")
end

-- Helper function to check if we should hide Blizzard frames (defined early for use in timer)
local function ShouldHideBlizzardFrames()
    local _, instanceType = IsInInstance()
    return instanceType == "arena" and GladiusMidnight.db and GladiusMidnight.db.profile and GladiusMidnight.db.profile.enabled
end

function GladiusMidnight:OnEnable()
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_MAXHEALTH")
    self:RegisterEvent("UNIT_POWER_UPDATE")
    self:RegisterEvent("UNIT_MAXPOWER")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("UNIT_SPELLCAST_START")
    self:RegisterEvent("UNIT_SPELLCAST_STOP")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- Register combat log event only if not in combat (Midnight 12.0 protection)
    if not InCombatLockdown() then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self.combatLogRegistered = true
    else
        self.combatLogRegistered = false
    end

    for name, module in pairs(self.modules) do
        if module.OnEnable then
            module:OnEnable(self)
        end
    end

    self.updateTimer = C_Timer.NewTicker(0.1, function()
        if self.testMode then return end

        for i = 1, 3 do
            local frame = self.frames[i]
            if frame and frame:IsShown() then
                for name, module in pairs(self.modules) do
                    if self:IsModuleEnabled(name) and module.OnUpdate then
                        module:OnUpdate(frame)
                    end
                end
            end

            -- Ensure Blizzard frames stay hidden
            if ShouldHideBlizzardFrames() then
                local blizzFrame = _G["CompactArenaFrameMember" .. i]
                if blizzFrame and blizzFrame:GetAlpha() > 0 then
                    blizzFrame:SetAlpha(0)
                end
            end
        end
    end)
end

function GladiusMidnight:OnDisable()
    if self.updateTimer then
        self.updateTimer:Cancel()
    end

    for name, module in pairs(self.modules) do
        if module.OnDisable then
            module:OnDisable(self)
        end
    end
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

function GladiusMidnight:PLAYER_ENTERING_WORLD()
    self:DetectArenaType()
    self:CheckArenaStatus()
    self:UpdateTargetHighlight()
    self:HideBlizzardFrames()

    local _, instanceType = IsInInstance()
    if instanceType == "arena" and self.db.profile.enabled then
        C_Timer.After(0.3, function()
            self:InitializeBlizzardFrames()
        end)

        C_Timer.After(0.5, function()
            self:ScanExistingOpponents()
        end)
    end
end

-- ============================================================================
-- Blizzard Arena Frame Handling (Midnight 12.0)
-- ============================================================================

-- Helper function to permanently hide a frame
local function PermanentlyHideFrame(frame)
    if not frame then return end

    -- Set alpha to 0
    frame:SetAlpha(0)

    -- Hook SetAlpha to prevent Blizzard from making it visible again
    if not frame.gladiusAlphaHooked then
        frame.gladiusAlphaHooked = true
        hooksecurefunc(frame, "SetAlpha", function(self, alpha)
            if ShouldHideBlizzardFrames() and alpha > 0 then
                self:SetAlpha(0)
            end
        end)
    end

    -- Also hook Show to reset alpha when shown
    if not frame.gladiusShowHooked then
        frame.gladiusShowHooked = true
        hooksecurefunc(frame, "Show", function(self)
            if ShouldHideBlizzardFrames() then
                self:SetAlpha(0)
            end
        end)
    end
end

function GladiusMidnight:InitializeBlizzardFrames()
    if self.blizzFramesInitialized then return end

    for i = 1, 3 do
        local blizzArenaFrame = _G["CompactArenaFrameMember" .. i]
        local ourFrame = self.frames[i]

        if not blizzArenaFrame or not ourFrame then
            C_Timer.After(1, function()
                self:InitializeBlizzardFrames()
            end)
            return
        end

        -- Permanently hide Blizzard's arena frame with hooks to prevent re-showing
        PermanentlyHideFrame(blizzArenaFrame)
        PermanentlyHideFrame(blizzArenaFrame.CastingBarFrame)
        PermanentlyHideFrame(blizzArenaFrame.DebuffFrame)
        PermanentlyHideFrame(blizzArenaFrame.CcRemoverFrame)
        PermanentlyHideFrame(blizzArenaFrame.SpellDiminishStatusTray)

        -- Also hide the health bar and other visual components
        if blizzArenaFrame.healthBar then
            PermanentlyHideFrame(blizzArenaFrame.healthBar)
        end
        if blizzArenaFrame.HealthBar then
            PermanentlyHideFrame(blizzArenaFrame.HealthBar)
        end
        if blizzArenaFrame.manaBar then
            PermanentlyHideFrame(blizzArenaFrame.manaBar)
        end
        if blizzArenaFrame.PowerBar then
            PermanentlyHideFrame(blizzArenaFrame.PowerBar)
        end

        ourFrame.blizzArenaFrame = blizzArenaFrame

        -- DR Tracking hooks - hook multiple methods to ensure we catch DR events
        if self:IsModuleEnabled("drTracker") then
            local drTray = blizzArenaFrame.SpellDiminishStatusTray
            if drTray then
                local drFrames = {drTray:GetChildren()}

                for drIndex, drFrame in ipairs(drFrames) do
                    if drFrame and not drFrame.gladiusHooked then
                        drFrame.gladiusHooked = true
                        local frameIndex = i

                        -- Hook Show function
                        hooksecurefunc(drFrame, "Show", function(self)
                            local drModule = GladiusMidnight:GetModule("drTracker")
                            local frame = GladiusMidnight.frames[frameIndex]
                            if drModule and frame then
                                -- Try to get spellID from auraData
                                local spellID = self.auraData and self.auraData.spellID
                                if spellID and not (issecretvalue and issecretvalue(spellID)) then
                                    drModule:OnBlizzardDR(frame, spellID)
                                end
                            end
                        end)

                        -- Also hook SetCooldown on the cooldown frame (backup method)
                        if drFrame.Cooldown then
                            hooksecurefunc(drFrame.Cooldown, "SetCooldown", function(_, start, duration)
                                local drModule = GladiusMidnight:GetModule("drTracker")
                                local frame = GladiusMidnight.frames[frameIndex]
                                if drModule and frame and start and start > 0 and duration and duration > 0 then
                                    -- DR was triggered - try to get category from parent's auraData
                                    local parent = drFrame
                                    local spellID = parent.auraData and parent.auraData.spellID
                                    if spellID and not (issecretvalue and issecretvalue(spellID)) then
                                        drModule:OnBlizzardDR(frame, spellID)
                                    end
                                end
                            end)
                        end
                    end
                end

                if ourFrame.moduleFrames and ourFrame.moduleFrames.drTracker then
                    ourFrame.moduleFrames.drTracker:Show()
                end
            end
        end

        -- DebuffFrame hooks
        local debuffFrame = blizzArenaFrame.DebuffFrame
        if debuffFrame then
            local frameIndex = i

            if debuffFrame.Icon and not debuffFrame.gladiusHooked then
                hooksecurefunc(debuffFrame.Icon, "SetTexture", function(_, tex)
                    local frame = GladiusMidnight.frames[frameIndex]
                    if frame then
                        local classIconModule = GladiusMidnight:GetModule("classIcon")
                        if classIconModule and classIconModule.OnDebuffUpdate then
                            classIconModule:OnDebuffUpdate(frame, tex)
                        end
                    end
                end)

                if debuffFrame.Cooldown then
                    hooksecurefunc(debuffFrame.Cooldown, "SetCooldown", function(_, start, duration)
                        local frame = GladiusMidnight.frames[frameIndex]
                        if frame then
                            local classIconModule = GladiusMidnight:GetModule("classIcon")
                            if classIconModule and classIconModule.OnDebuffCooldown then
                                classIconModule:OnDebuffCooldown(frame, start, duration)
                            end
                        end
                    end)
                end

                debuffFrame.gladiusHooked = true
            end
        end

        -- Trinket hooks
        if self:IsModuleEnabled("trinket") then
            local trinketFrame = blizzArenaFrame.CcRemoverFrame
            if trinketFrame and trinketFrame.Cooldown and not trinketFrame.gladiusHooked then
                local frameIndex = i

                hooksecurefunc(trinketFrame.Cooldown, "SetCooldown", function(_, start, duration)
                    local frame = GladiusMidnight.frames[frameIndex]
                    if frame then
                        local trinketModule = GladiusMidnight:GetModule("trinket")
                        if trinketModule and trinketModule.OnBlizzardTrinketCooldown then
                            trinketModule:OnBlizzardTrinketCooldown(frame, start, duration)
                        end
                    end
                end)

                trinketFrame.gladiusHooked = true
            end
        end
    end

    self.blizzFramesInitialized = true
    self:Print("Blizzard Frames versteckt - eigene Module aktiv")
end

function GladiusMidnight:InitializeBlizzardDRFrames()
    self:InitializeBlizzardFrames()
end

function GladiusMidnight:ResetBlizzardFrames()
    self.blizzFramesInitialized = false

    for i = 1, 3 do
        local ourFrame = self.frames[i]
        local blizzArenaFrame = _G["CompactArenaFrameMember" .. i]

        if blizzArenaFrame then
            -- Restore visibility when leaving arena
            blizzArenaFrame:SetAlpha(1)

            if blizzArenaFrame.CastingBarFrame then
                blizzArenaFrame.CastingBarFrame:SetAlpha(1)
            end
            if blizzArenaFrame.DebuffFrame then
                blizzArenaFrame.DebuffFrame:SetAlpha(1)
            end
            if blizzArenaFrame.CcRemoverFrame then
                blizzArenaFrame.CcRemoverFrame:SetAlpha(1)
            end
            if blizzArenaFrame.SpellDiminishStatusTray then
                blizzArenaFrame.SpellDiminishStatusTray:SetAlpha(1)
            end
        end

        if ourFrame then
            ourFrame.blizzArenaFrame = nil
        end
    end
end

function GladiusMidnight:ResetBlizzardDRFrames()
    self:ResetBlizzardFrames()
end

function GladiusMidnight:UpdateBlizzardDRSize()
    if not self.blizzFramesInitialized then return end

    local drModule = self:GetModule("drTracker")
    if drModule then
        for i = 1, 3 do
            local ourFrame = self.frames[i]
            if ourFrame then
                drModule:Update(ourFrame, self.testMode and self:GetTestData(i) or nil)
            end
        end
    end
end

function GladiusMidnight:UpdateBlizzardCastBarSize()
    local castBarModule = self:GetModule("castBar")
    if castBarModule then
        for i = 1, 3 do
            local ourFrame = self.frames[i]
            if ourFrame then
                castBarModule:Update(ourFrame, self.testMode and self:GetTestData(i) or nil)
            end
        end
    end
end

function GladiusMidnight:UpdateBlizzardDebuffSize()
    local classIconModule = self:GetModule("classIcon")
    if classIconModule then
        for i = 1, 3 do
            local ourFrame = self.frames[i]
            if ourFrame then
                classIconModule:Update(ourFrame, self.testMode and self:GetTestData(i) or nil)
            end
        end
    end
end

function GladiusMidnight:ScanExistingOpponents()
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" or self.testMode then return end

    self:Print("Scanne Arena-Gegner...")

    local foundOpponents = 0
    for i = 1, 3 do
        local unit = "arena" .. i
        local frame = self.frames[i]

        if frame and UnitExists(unit) then
            foundOpponents = foundOpponents + 1

            local _, classFile = UnitClass(unit)
            if classFile then
                frame.class = classFile
            end

            if GetArenaOpponentSpec then
                local specID = GetArenaOpponentSpec(i)
                if specID and specID > 0 then
                    frame.specID = specID
                    local _, _, _, _, _, specClassFile = GetSpecializationInfoByID(specID)
                    if specClassFile then
                        frame.class = specClassFile
                    end
                end
            end

            if UnitRace then
                local _, raceToken = UnitRace(unit)
                if raceToken then
                    frame.race = raceToken
                end
            end

            self:UpdateFrame(frame)
            if not InCombatLockdown() then
                frame:Show()
            end
        end
    end

    if foundOpponents > 0 then
        self:Print(foundOpponents .. " Gegner gefunden nach Reload")
        self:PositionFrames()
    end
end

function GladiusMidnight:PLAYER_TARGET_CHANGED()
    self:UpdateTargetHighlight()
end

function GladiusMidnight:UpdateTargetHighlight()
    for i = 1, 3 do
        local frame = self.frames[i]
        if frame and frame.targetGlow then
            if self.db.profile.targetHighlight and UnitIsUnit("target", frame.unit) then
                frame.targetGlow:Show()
            else
                frame.targetGlow:Hide()
            end
        end
        if frame and frame.immunityGlow and not self.db.profile.immunityGlow then
            frame.immunityGlow:Hide()
            frame.hasImmunity = false
        end
    end
end

function GladiusMidnight:HideBlizzardFrames()
    -- Always hide Blizzard arena frames when our addon is enabled
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then return end

    for i = 1, 5 do
        -- Old arena frames
        local frameName = "ArenaEnemyFrame" .. i
        local frame = _G[frameName]
        if frame then
            frame:UnregisterAllEvents()
            frame:Hide()
            frame:SetScript("OnShow", function(self) self:Hide() end)
        end

        -- Compact arena frame container
        local compactFrame = _G["CompactArenaFrame" .. i]
        if compactFrame then
            compactFrame:UnregisterAllEvents()
            compactFrame:Hide()
        end

        -- Compact arena frame members (the actual visible frames)
        local memberFrame = _G["CompactArenaFrameMember" .. i]
        if memberFrame then
            PermanentlyHideFrame(memberFrame)
            -- Hide all children recursively
            for _, child in pairs({memberFrame:GetChildren()}) do
                if child.SetAlpha then
                    child:SetAlpha(0)
                end
            end
        end
    end

    -- Hide containers
    if ArenaEnemyPrepFramesContainer then
        ArenaEnemyPrepFramesContainer:Hide()
    end

    if CompactArenaFrame then
        CompactArenaFrame:SetAlpha(0)
        if not CompactArenaFrame.gladiusAlphaHooked then
            CompactArenaFrame.gladiusAlphaHooked = true
            hooksecurefunc(CompactArenaFrame, "SetAlpha", function(self, alpha)
                if ShouldHideBlizzardFrames() and alpha > 0 then
                    self:SetAlpha(0)
                end
            end)
        end
    end

    -- Also check for EditModeArenaFrame or other variants
    if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then
        -- Don't disable edit mode, just hide the actual frames
    end
end

function GladiusMidnight:ZONE_CHANGED_NEW_AREA()
    local _, instanceType = IsInInstance()

    if instanceType ~= "arena" and self.blizzFramesInitialized then
        self:ResetBlizzardFrames()
    end

    self:DetectArenaType()
    self:CheckArenaStatus()

    if instanceType == "arena" and self.db.profile.enabled then
        C_Timer.After(0.5, function()
            self:InitializeBlizzardFrames()
        end)
    end
end

function GladiusMidnight:ARENA_OPPONENT_UPDATE(_, unit, updateType)
    if not self.db.profile.enabled or self.testMode then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index or not self.frames[index] then return end

    local frame = self.frames[index]

    if updateType == "seen" or updateType == "cleared" then
        if self.prepPhase then
            self.prepPhase = false
            self:Print("Arena gestartet!")
            if not InCombatLockdown() then
                for i = 1, 3 do
                    local f = self.frames[i]
                    if f then
                        RegisterUnitWatch(f)
                    end
                end
            end
        end

        if UnitExists(unit) then
            local _, classFile = UnitClass(unit)
            if classFile then
                frame.class = classFile
            end
        end

        self:UpdateFrame(frame)
        if not InCombatLockdown() then
            frame:Show()
        end

        if frame.moduleFrames then
            if frame.moduleFrames.drTracker then
                frame.moduleFrames.drTracker:ClearAllPoints()
                frame.moduleFrames.drTracker:SetPoint("RIGHT", frame, "LEFT", -4, 0)
            end
            if frame.moduleFrames.castBar then
                frame.moduleFrames.castBar:ClearAllPoints()
                local height = self.db.profile.castBar.height or 14
                frame.moduleFrames.castBar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", height + 2, -2)
                frame.moduleFrames.castBar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2)
            end
            if frame.moduleFrames.auras then
                local healthHeight = self.db.profile.health.height or 20
                local powerHeight = self:IsModuleEnabled("power") and (self.db.profile.power.height or 6) or 0
                local yOffset = -(healthHeight + powerHeight + 6)
                local leftOffset = self.db.profile.classIcon.size + 4
                frame.moduleFrames.auras:ClearAllPoints()
                frame.moduleFrames.auras:SetPoint("TOPLEFT", frame, "TOPLEFT", leftOffset, yOffset)
            end
        end

        self:PositionFrames()
    elseif updateType == "destroyed" then
        if not InCombatLockdown() then
            frame:Hide()
        end
        if frame.moduleFrames then
            if frame.moduleFrames.drTracker then
                frame.moduleFrames.drTracker:Hide()
            end
            if frame.moduleFrames.castBar then
                frame.moduleFrames.castBar:Hide()
            end
            if frame.moduleFrames.auras then
                frame.moduleFrames.auras:Hide()
            end
        end
        self:ResetFrame(frame)
    end
end

function GladiusMidnight:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
    if not self.db.profile.enabled or self.testMode then return end

    if self.arenaSize == 0 then
        self:DetectArenaType()
    end

    for i = 1, 3 do
        local frame = self.frames[i]
        if frame then
            self:ResetFrame(frame)
        end
    end

    self.prepPhase = true
    if not InCombatLockdown() then
        for i = 1, 3 do
            local frame = self.frames[i]
            if frame then
                UnregisterUnitWatch(frame)
            end
        end
    end

    local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or self.arenaSize
    if numOpponents == 0 then numOpponents = self.arenaSize end
    if numOpponents == 0 then numOpponents = 3 end

    self:Print("Prep Phase - " .. numOpponents .. " Gegner erkannt")

    for i = 1, numOpponents do
        local frame = self.frames[i]
        if frame then
            local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(i)
            if specID and specID > 0 then
                local _, specName, _, _, role, classFile = GetSpecializationInfoByID(specID)
                if classFile then
                    frame.class = classFile
                    frame.specID = specID
                    self:Print("Arena" .. i .. ": " .. classFile .. " (SpecID: " .. specID .. ")")
                end
            else
                self:Print("Arena" .. i .. ": Spec nicht verfügbar")
            end

            self:UpdateFrame(frame)
            if not InCombatLockdown() then
                frame:Show()
            end
        end
    end

    for i = numOpponents + 1, 3 do
        local frame = self.frames[i]
        if frame and not InCombatLockdown() then
            frame:Hide()
        end
    end

    self:PositionFrames()
end

function GladiusMidnight:UNIT_HEALTH(_, unit)
    if self.testMode then return end

    local index = tonumber(unit:match("arena(%d)"))
    if index and self.frames[index] and self.frames[index]:IsShown() then
        local module = self:GetModule("health")
        if module and self:IsModuleEnabled("health") then
            module:UpdateUnit(self.frames[index])
        end
    end
end

function GladiusMidnight:UNIT_MAXHEALTH(_, unit)
    self:UNIT_HEALTH(_, unit)
end

function GladiusMidnight:UNIT_POWER_UPDATE(_, unit)
    if self.testMode then return end

    local index = tonumber(unit:match("arena(%d)"))
    if index and self.frames[index] and self.frames[index]:IsShown() then
        local module = self:GetModule("power")
        if module and self:IsModuleEnabled("power") then
            module:UpdateUnit(self.frames[index])
        end
    end
end

function GladiusMidnight:UNIT_MAXPOWER(_, unit)
    self:UNIT_POWER_UPDATE(_, unit)
end

function GladiusMidnight:UNIT_SPELLCAST_SUCCEEDED(_, unit, castGUID, spellID)
    if self.testMode or not unit or not spellID or type(spellID) ~= "number" then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index or not self.frames[index] then return end

    local trinketModule = self:GetModule("trinket")
    if trinketModule and self:IsModuleEnabled("trinket") then
        trinketModule:OnSpellCast(self.frames[index], spellID)
    end

    local racialModule = self:GetModule("racial")
    if racialModule and self:IsModuleEnabled("racial") then
        racialModule:OnSpellCast(self.frames[index], spellID)
    end
end

function GladiusMidnight:UNIT_AURA(_, unit, updateInfo)
    if self.testMode or not unit then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index or not self.frames[index] then return end

    local frame = self.frames[index]

    local drModule = self:GetModule("drTracker")
    if drModule and self:IsModuleEnabled("drTracker") then
        if updateInfo and updateInfo.addedAuras then
            for _, auraInfo in ipairs(updateInfo.addedAuras) do
                if auraInfo and auraInfo.spellId and type(auraInfo.spellId) == "number" then
                    drModule:OnAura(frame, auraInfo.spellId)
                end
            end
        else
            self:ScanDebuffsForDR(frame, unit)
        end
    end

    local aurasModule = self:GetModule("auras")
    if aurasModule and self:IsModuleEnabled("auras") then
        aurasModule:OnAuraChange(frame)
    end
end

function GladiusMidnight:ScanDebuffsForDR(frame, unit)
    local drModule = self:GetModule("drTracker")
    if not drModule then return end

    frame.lastDRScan = frame.lastDRScan or {}
    local currentDebuffs = {}

    if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
        for i = 1, 40 do
            local auraData = C_UnitAuras.GetDebuffDataByIndex(unit, i)
            if not auraData then break end

            local spellId = auraData.spellId
            if spellId and not (issecretvalue and issecretvalue(spellId)) then
                currentDebuffs[spellId] = true

                if not frame.lastDRScan[spellId] then
                    drModule:OnAura(frame, spellId)
                end
            end
        end
    end

    frame.lastDRScan = currentDebuffs
end

-- Cast Bar Events
function GladiusMidnight:UNIT_SPELLCAST_START(_, unit, castGUID, spellID)
    if self.testMode or not unit then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index or not self.frames[index] then return end

    local castBarModule = self:GetModule("castBar")
    if castBarModule and self:IsModuleEnabled("castBar") then
        castBarModule:OnCastStart(self.frames[index], unit, spellID, false)
    end
end

function GladiusMidnight:UNIT_SPELLCAST_STOP(_, unit)
    if self.testMode or not unit then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index or not self.frames[index] then return end

    local castBarModule = self:GetModule("castBar")
    if castBarModule and self:IsModuleEnabled("castBar") then
        castBarModule:OnCastStop(self.frames[index])
    end
end

function GladiusMidnight:UNIT_SPELLCAST_FAILED(_, unit)
    if self.testMode or not unit then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index or not self.frames[index] then return end

    local castBarModule = self:GetModule("castBar")
    if castBarModule and self:IsModuleEnabled("castBar") then
        castBarModule:OnCastStop(self.frames[index])
    end
end

function GladiusMidnight:UNIT_SPELLCAST_INTERRUPTED(_, unit)
    if self.testMode or not unit then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index or not self.frames[index] then return end

    local castBarModule = self:GetModule("castBar")
    if castBarModule and self:IsModuleEnabled("castBar") then
        castBarModule:OnCastInterrupted(self.frames[index])
    end
end

function GladiusMidnight:UNIT_SPELLCAST_CHANNEL_START(_, unit, castGUID, spellID)
    if self.testMode or not unit then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index or not self.frames[index] then return end

    local castBarModule = self:GetModule("castBar")
    if castBarModule and self:IsModuleEnabled("castBar") then
        castBarModule:OnCastStart(self.frames[index], unit, spellID, true)
    end
end

function GladiusMidnight:UNIT_SPELLCAST_CHANNEL_STOP(_, unit)
    if self.testMode or not unit then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index or not self.frames[index] then return end

    local castBarModule = self:GetModule("castBar")
    if castBarModule and self:IsModuleEnabled("castBar") then
        castBarModule:OnCastStop(self.frames[index])
    end
end

function GladiusMidnight:COMBAT_LOG_EVENT_UNFILTERED()
    if self.testMode then return end

    local drModule = self:GetModule("drTracker")
    if drModule and self:IsModuleEnabled("drTracker") then
        drModule:OnCombatLogEvent()
    end
end

function GladiusMidnight:PLAYER_REGEN_ENABLED()
    -- Register combat log event after combat ends (if we couldn't during OnEnable)
    if not self.combatLogRegistered then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self.combatLogRegistered = true
    end
end

function GladiusMidnight:CheckArenaStatus()
    if self.testMode then return end

    local _, instanceType = IsInInstance()

    if instanceType ~= "arena" or not self.db.profile.enabled then
        self.prepPhase = false
        self.arenaSize = 0

        for i = 1, 3 do
            local frame = self.frames[i]
            if frame then
                if not InCombatLockdown() then
                    RegisterUnitWatch(frame)
                    frame:Hide()
                end
                self:ResetFrame(frame)
            end
        end
    end
end

function GladiusMidnight:ResetFrame(frame)
    for name, module in pairs(self.modules) do
        if module.Reset then
            module:Reset(frame)
        end
    end
end

-- ============================================================================
-- Slash Commands
-- ============================================================================

function GladiusMidnight:SlashCommand(input)
    input = (input or ""):trim():lower()

    if input == "test" then
        self:ToggleTest()
    elseif input == "lock" then
        self.db.profile.locked = true
        self:Print("Frames |cFF00FF00fixiert|r")
    elseif input == "unlock" then
        self.db.profile.locked = false
        self:Print("Frames |cFFFF0000entsperrt|r - zum Verschieben ziehen")
    elseif input == "reset" then
        self.db:ResetProfile()
        self:UpdateAllFrames()
        self:Print("Einstellungen zurückgesetzt")
    elseif input == "config" or input == "" then
        LibStub("AceConfigDialog-3.0"):Open(addonName)
    else
        self:Print("Befehle:")
        self:Print("  |cFF00FF00/gladius|r - Einstellungen öffnen")
        self:Print("  |cFF00FF00/gladius test|r - Test-Modus")
        self:Print("  |cFF00FF00/gladius lock|r - Frames fixieren")
        self:Print("  |cFF00FF00/gladius unlock|r - Frames entsperren")
        self:Print("  |cFF00FF00/gladius reset|r - Zurücksetzen")
        self:Print("  |cFF00FF00/gg|r - Arena aufgeben")
    end
end

function GladiusMidnight:SurrenderArena()
    local _, instanceType = IsInInstance()
    if instanceType == "arena" then
        if C_PvP and C_PvP.RequestCrowdControlSpell then
            LeaveBattlefield()
            self:Print("|cFFFF0000Arena aufgegeben|r")
        else
            LeaveBattlefield()
            self:Print("|cFFFF0000Arena aufgegeben|r")
        end
    else
        self:Print("Du bist nicht in einer Arena!")
    end
end

-- Export
_G.GladiusMidnight = GladiusMidnight
