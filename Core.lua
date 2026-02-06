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
-- Default Settings
-- ============================================================================

local defaults = {
    profile = {
        enabled = true,
        locked = true,

        -- Frame settings
        frameWidth = 275,
        frameHeight = 74,
        scale = 1.0,
        spacing = 30,
        growDirection = "DOWN",

        -- Position
        posX = 606.87,
        posY = -50.97,

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
        hideBlizzardFrames = false,

        -- Module-specific settings
        classIcon = {
            size = 50,
            position = "LEFT",
            showSpec = true,  -- Show spec icon instead of class
        },
        health = {
            height = 28,
            showText = true,
            showName = true,
            colorByClass = true,
        },
        power = {
            height = 10,
            showText = false,
        },
        trinket = {
            size = 26,
            position = "RIGHT",
        },
        racial = {
            size = 26,
            position = "RIGHT",
        },
        drTracker = {
            iconSize = 20,
            showTimer = true,
        },
        castBar = {
            height = 16,
            showIcon = true,
        },
        auras = {
            iconSize = 28,
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
-- Arena Frame Creation
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
    -- This is needed for DR Tracker (left of frame) and Cast Bar (below frame)
    frame:SetClipsChildren(false)

    frame.unit = unit
    frame.index = index
    frame.displayedUnit = unit  -- Required by Blizzard's aura code

    -- Add optionTable to prevent Blizzard CompactUnitFrame errors
    -- Blizzard's code expects this field when updating auras on reparented frames
    frame.optionTable = {
        displayOnlyDispellableDebuffs = false,
        displayDebuffs = true,
        displayBuffs = true,
        displayNonBossDebuffs = true,
        maxDispelDebuffs = 3,  -- Prevent "compare nil with number" error
        maxDebuffs = 3,
        maxBuffs = 3,
    }

    -- Table for blocked aura instance IDs (used by Blizzard's aura code)
    frame.blockedAuraInstanceIDsTable = frame.blockedAuraInstanceIDsTable or {}

    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    -- Target highlight glow
    local targetGlow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    targetGlow:SetPoint("TOPLEFT", -3, 3)
    targetGlow:SetPoint("BOTTOMRIGHT", 3, -3)
    targetGlow:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    targetGlow:SetBackdropBorderColor(1, 1, 1, 1)
    targetGlow:SetFrameLevel(frame:GetFrameLevel() - 1)
    targetGlow:Hide()
    frame.targetGlow = targetGlow

    -- Immunity glow - WHITE for total immunity, GREEN for magic-only (ArenaCore style)
    local immunityGlow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    immunityGlow:SetPoint("TOPLEFT", -4, 4)
    immunityGlow:SetPoint("BOTTOMRIGHT", 4, -4)
    immunityGlow:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 3,
    })
    immunityGlow:SetBackdropBorderColor(1, 1, 1, 1)  -- White = total immunity
    immunityGlow:SetFrameLevel(frame:GetFrameLevel() - 1)
    immunityGlow:Hide()
    frame.immunityGlow = immunityGlow
    frame.hasImmunity = false
    frame.immunityType = nil  -- "total" or "magic"

    -- Arena number indicator (right side)
    local arenaNumber = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    arenaNumber:SetSize(28, 28)
    arenaNumber:SetPoint("LEFT", frame, "RIGHT", 4, 0)
    arenaNumber:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    arenaNumber:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    arenaNumber:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local numberText = arenaNumber:CreateFontString(nil, "OVERLAY")
    numberText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    numberText:SetPoint("CENTER")
    numberText:SetText(index)
    numberText:SetTextColor(1, 1, 1)
    arenaNumber.text = numberText
    frame.arenaNumber = arenaNumber

    -- Secure targeting (left-click = target, right-click = focus)
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
        -- Only save position from frame 1 (other frames are positioned relative to it)
        if f.index == 1 then
            -- Get the frame's current position relative to UIParent center
            local scale = f:GetEffectiveScale()
            local uiScale = UIParent:GetEffectiveScale()
            local centerX, centerY = f:GetCenter()
            local uiCenterX, uiCenterY = UIParent:GetCenter()

            if centerX and uiCenterX then
                -- Convert to UIParent-relative coordinates (accounting for frame's scale)
                local x = (centerX - uiCenterX) * (scale / uiScale)
                local y = (centerY - uiCenterY) * (scale / uiScale)

                -- Account for the frame's own scale setting
                local frameScale = GladiusMidnight.db.profile.scale or 1
                GladiusMidnight.db.profile.posX = x / frameScale
                GladiusMidnight.db.profile.posY = y / frameScale
            end
        end
        -- Re-position other frames relative to frame 1 (but don't reposition frame 1 itself)
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

    -- Update frame size (only outside of combat to avoid taint)
    if not InCombatLockdown() then
        frame:SetSize(db.frameWidth, db.frameHeight)
        frame:SetScale(db.scale)
    end

    -- Update each module (show enabled, hide disabled)
    for name, module in pairs(self.modules) do
        if self:IsModuleEnabled(name) then
            if module.Update then
                module:Update(frame, testData)
            end
        else
            -- Hide disabled module's frame
            if frame.moduleFrames and frame.moduleFrames[name] then
                frame.moduleFrames[name]:Hide()
            end
        end
    end

    -- Update target highlight
    self:UpdateTargetHighlight()
end

function GladiusMidnight:UpdateAllFrames()
    -- Pass testData if in test mode
    local testData = self.testMode and self:GetTestData() or nil

    for i = 1, 3 do
        local frame = self.frames[i]
        if frame then
            self:UpdateFrame(frame, testData)
        end
    end
    self:PositionFrames()

    -- Update Blizzard frame sizes (for live arena)
    self:UpdateBlizzardDRSize()
    self:UpdateBlizzardCastBarSize()
    self:UpdateBlizzardDebuffSize()
end

-- Get test data for test mode
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
    -- Cannot modify frame positions during combat (protected functions)
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

    -- Solo Shuffle
    if C_PvP and C_PvP.IsSoloShuffle and C_PvP.IsSoloShuffle() then
        self.arenaSize = 3
        self:Print("Solo Shuffle erkannt")
        return
    end

    -- Bracket detection
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

        for i = 1, 3 do
            local frame = self.frames[i]
            if frame then
                -- Unregister unit watch so we can show the frame manually
                UnregisterUnitWatch(frame)

                -- Store test class on frame
                local testClass = classes[math.random(1, #classes)]
                frame.class = testClass

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
                -- Re-register unit watch for normal arena operation
                RegisterUnitWatch(frame)

                -- Hide UIParent-parented module frames (DR Tracker, Cast Bar, Auras)
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
    -- Initialize database
    self.db = LibStub("AceDB-3.0"):New("GladiusMidnightDB", defaults, true)

    -- Create arena frames
    for i = 1, 3 do
        self.frames[i] = self:CreateArenaFrame(i)
    end

    -- Initialize modules
    for name, module in pairs(self.modules) do
        if module.OnInitialize then
            module:OnInitialize(self)
        end
    end

    -- Create module elements on frames
    for i = 1, 3 do
        local frame = self.frames[i]
        for name, module in pairs(self.modules) do
            if module.CreateElements then
                module:CreateElements(frame)
            end
        end
    end

    -- Register slash commands
    self:RegisterChatCommand("gladius", "SlashCommand")
    self:RegisterChatCommand("gm", "SlashCommand")
    self:RegisterChatCommand("gg", "SurrenderArena")

    self:Print("Geladen - |cFF00FF00/gladius test|r zum Testen, |cFFFF6600/gg|r zum Aufgeben")
end

function GladiusMidnight:OnEnable()
    -- Arena events
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    -- Target events
    self:RegisterEvent("PLAYER_TARGET_CHANGED")

    -- Unit events
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_MAXHEALTH")
    self:RegisterEvent("UNIT_POWER_UPDATE")
    self:RegisterEvent("UNIT_MAXPOWER")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_AURA")

    -- Cast bar events
    self:RegisterEvent("UNIT_SPELLCAST_START")
    self:RegisterEvent("UNIT_SPELLCAST_STOP")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")

    -- Note: COMBAT_LOG_EVENT_UNFILTERED is BLOCKED in Midnight 12.0 during PvP
    -- DR tracking uses full aura scan via UNIT_AURA instead

    -- Enable modules
    for name, module in pairs(self.modules) do
        if module.OnEnable then
            module:OnEnable(self)
        end
    end

    -- Update timer for cooldowns
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

    -- After reload in arena, scan for existing opponents
    local _, instanceType = IsInInstance()
    if instanceType == "arena" and self.db.profile.enabled then
        -- Initialize Blizzard frames (DR + CastBar reparenting)
        C_Timer.After(0.3, function()
            self:InitializeBlizzardFrames()
        end)

        C_Timer.After(0.5, function()
            self:ScanExistingOpponents()
        end)
    end
end

-- ============================================================================
-- Blizzard DR Frame Reparenting (Midnight 12.0)
-- In Midnight 12.0, Blizzard provides built-in DR tracking via SpellDiminishStatusTray
-- We reparent these frames to our arena frames (like sArena does)
-- ============================================================================

function GladiusMidnight:InitializeBlizzardFrames()
    if self.blizzFramesInitialized then return end

    for i = 1, 3 do
        local blizzArenaFrame = _G["CompactArenaFrameMember" .. i]
        local ourFrame = self.frames[i]

        if not blizzArenaFrame or not ourFrame then
            -- Blizzard frames not created yet, try again later
            C_Timer.After(1, function()
                self:InitializeBlizzardFrames()
            end)
            return
        end

        -- =====================================================================
        -- DR Tracking - Hide Blizzard's DR tray and use our custom DRTracker
        -- Our DRTracker shows category icons (Kidney Shot, Polymorph, etc.)
        -- We hook into Blizzard's DR detection to trigger our custom display
        -- =====================================================================
        if self:IsModuleEnabled("drTracker") then
            local drTray = blizzArenaFrame.SpellDiminishStatusTray
            if drTray then
                -- Store reference but HIDE Blizzard's DR tray
                ourFrame.blizzDRTray = drTray
                drTray:SetAlpha(0)  -- Hide it
                drTray:EnableMouse(false)

                -- Get individual DR frames for hooking
                local drFrames = {drTray:GetChildren()}
                ourFrame.blizzDRFrames = drFrames

                -- Hook each DR frame to detect when Blizzard shows a DR
                for drIndex, drFrame in ipairs(drFrames) do
                    if drFrame and not drFrame.gladiusHooked then
                        drFrame.gladiusHooked = true

                        -- Hook the Show function to detect DR
                        hooksecurefunc(drFrame, "Show", function(self)
                            -- When Blizzard shows a DR, trigger our DRTracker
                            local drModule = GladiusMidnight:GetModule("drTracker")
                            if drModule and self.auraData then
                                local spellID = self.auraData.spellID
                                if spellID then
                                    drModule:OnBlizzardDR(ourFrame, spellID)
                                end
                            end
                        end)
                    end
                end

                -- Show our custom DR tracker (with category icons)
                if ourFrame.moduleFrames and ourFrame.moduleFrames.drTracker then
                    ourFrame.moduleFrames.drTracker:Show()
                end
            end
        end

        -- =====================================================================
        -- CastBar Reparenting (CastingBarFrame)
        -- In Midnight 12.0, cast data for arena opponents is "secret"
        -- We reparent Blizzard's built-in cast bar instead
        -- =====================================================================
        if self:IsModuleEnabled("castBar") then
            local blizzCastBar = blizzArenaFrame.CastingBarFrame
            if blizzCastBar then
                -- Reparent Blizzard's cast bar to our frame
                blizzCastBar:SetParent(ourFrame)
                ourFrame.blizzCastBar = blizzCastBar

                -- Configure the cast bar
                blizzCastBar:SetFrameStrata("HIGH")
                blizzCastBar:SetFrameLevel(20)
                blizzCastBar:EnableMouse(false)
                if blizzCastBar.SetMouseClickEnabled then
                    blizzCastBar:SetMouseClickEnabled(false)
                end

                -- Position BELOW our frame
                local db = self.db.profile.castBar
                local height = db and db.height or 16
                blizzCastBar:ClearAllPoints()
                blizzCastBar:SetPoint("TOPLEFT", ourFrame, "BOTTOMLEFT", 0, -2)
                blizzCastBar:SetPoint("TOPRIGHT", ourFrame, "BOTTOMRIGHT", 0, -2)
                blizzCastBar:SetHeight(height)

                -- Hide our custom cast bar (we're using Blizzard's now)
                if ourFrame.moduleFrames and ourFrame.moduleFrames.castBar then
                    ourFrame.moduleFrames.castBar:Hide()
                end
            end
        end

        -- =====================================================================
        -- DebuffFrame Reparenting (Current CC Display)
        -- In Midnight 12.0, this shows the most important CC on the target
        -- We reparent it to overlay on our ClassIcon (like sArena)
        -- =====================================================================
        local debuffFrame = blizzArenaFrame.DebuffFrame
        if debuffFrame then
            ourFrame.blizzDebuffFrame = debuffFrame

            -- Reparent to our frame
            debuffFrame:SetParent(ourFrame)
            debuffFrame:SetFrameStrata("HIGH")
            debuffFrame:SetFrameLevel(25)

            -- Position on top of ClassIcon (overlay style like sArena)
            debuffFrame:ClearAllPoints()
            local classIconSize = self.db.profile.classIcon.size or 50
            debuffFrame:SetSize(classIconSize, classIconSize)
            debuffFrame:SetPoint("TOPLEFT", ourFrame, "TOPLEFT", 2, -2)

            -- Make sure it's visible
            debuffFrame:SetAlpha(1)
            debuffFrame:Show()

            -- Store reference for hooks
            local frameIndex = i

            -- Hook SetTexture to also update our ClassIcon module
            if not debuffFrame.gladiusHooked then
                hooksecurefunc(debuffFrame.Icon, "SetTexture", function(_, tex)
                    local frame = self.frames[frameIndex]
                    if frame then
                        -- Update ClassIcon overlay when in CC
                        local classIconModule = self:GetModule("classIcon")
                        if classIconModule and classIconModule.OnDebuffUpdate then
                            classIconModule:OnDebuffUpdate(frame, tex)
                        end
                    end
                end)

                if debuffFrame.Cooldown then
                    hooksecurefunc(debuffFrame.Cooldown, "SetCooldown", function(_, start, duration)
                        local frame = self.frames[frameIndex]
                        if frame then
                            local classIconModule = self:GetModule("classIcon")
                            if classIconModule and classIconModule.OnDebuffCooldown then
                                classIconModule:OnDebuffCooldown(frame, start, duration)
                            end
                        end
                    end)
                end

                debuffFrame.gladiusHooked = true
            end
        end

        -- =====================================================================
        -- CcRemoverFrame Hooking (Trinket Cooldown)
        -- Blizzard's built-in trinket tracking for arena opponents
        -- =====================================================================
        if self:IsModuleEnabled("trinket") then
            local trinketFrame = blizzArenaFrame.CcRemoverFrame
            if trinketFrame then
                ourFrame.blizzTrinketFrame = trinketFrame

                -- Hide Blizzard's frame but keep it functional for hooks
                trinketFrame:SetParent(ourFrame)
                trinketFrame:SetAlpha(0)

                local frameIndex = i

                if not trinketFrame.gladiusHooked then
                    -- Hook trinket cooldown
                    if trinketFrame.Cooldown then
                        hooksecurefunc(trinketFrame.Cooldown, "SetCooldown", function(_, start, duration)
                            local frame = self.frames[frameIndex]
                            if frame then
                                local trinketModule = self:GetModule("trinket")
                                if trinketModule and trinketModule.OnBlizzardTrinketCooldown then
                                    trinketModule:OnBlizzardTrinketCooldown(frame, start, duration)
                                end
                            end
                        end)
                    end

                    trinketFrame.gladiusHooked = true
                end
            end
        end
    end

    self.blizzFramesInitialized = true
    self:Print("Blizzard Frames initialisiert (DR + CastBar + CC + Trinket)")
end

-- Legacy alias for backwards compatibility
function GladiusMidnight:InitializeBlizzardDRFrames()
    self:InitializeBlizzardFrames()
end

-- Reset Blizzard frames when leaving arena
function GladiusMidnight:ResetBlizzardFrames()
    self.blizzFramesInitialized = false

    for i = 1, 3 do
        local ourFrame = self.frames[i]
        local blizzArenaFrame = _G["CompactArenaFrameMember" .. i]

        -- Reset DR tray (restore visibility and reparent back to Blizzard)
        if ourFrame and ourFrame.blizzDRTray then
            if blizzArenaFrame then
                ourFrame.blizzDRTray:SetParent(blizzArenaFrame)
                ourFrame.blizzDRTray:SetScale(1)
                ourFrame.blizzDRTray:ClearAllPoints()
            end
            ourFrame.blizzDRTray:SetAlpha(1)  -- Restore visibility
            ourFrame.blizzDRTray = nil
            ourFrame.blizzDRFrames = nil
        end

        -- Reset Cast bar
        if ourFrame and ourFrame.blizzCastBar then
            if blizzArenaFrame then
                ourFrame.blizzCastBar:SetParent(blizzArenaFrame)
            end
            ourFrame.blizzCastBar = nil
        end

        -- Reset DebuffFrame (CC display)
        if ourFrame and ourFrame.blizzDebuffFrame then
            if blizzArenaFrame then
                ourFrame.blizzDebuffFrame:SetParent(blizzArenaFrame)
            end
            ourFrame.blizzDebuffFrame = nil
        end

        -- Reset TrinketFrame
        if ourFrame and ourFrame.blizzTrinketFrame then
            if blizzArenaFrame then
                ourFrame.blizzTrinketFrame:SetParent(blizzArenaFrame)
                ourFrame.blizzTrinketFrame:SetAlpha(1)
            end
            ourFrame.blizzTrinketFrame = nil
        end
    end
end

-- Legacy alias for backwards compatibility
function GladiusMidnight:ResetBlizzardDRFrames()
    self:ResetBlizzardFrames()
end

-- Update DR frame sizes when settings change
-- We use our custom DRTracker, so just update that module
function GladiusMidnight:UpdateBlizzardDRSize()
    if not self.blizzFramesInitialized then return end

    -- Update our custom DRTracker module for all frames
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

-- Update Blizzard CastBar size when settings change
function GladiusMidnight:UpdateBlizzardCastBarSize()
    if not self.blizzFramesInitialized then return end

    local db = self.db.profile.castBar
    local height = db and db.height or 16

    for i = 1, 3 do
        local ourFrame = self.frames[i]
        if ourFrame and ourFrame.blizzCastBar then
            ourFrame.blizzCastBar:SetHeight(height)
        end
    end
end

-- Update Blizzard DebuffFrame (CC) size when settings change
function GladiusMidnight:UpdateBlizzardDebuffSize()
    if not self.blizzFramesInitialized then return end

    local db = self.db.profile.classIcon
    local size = db and db.size or 50

    for i = 1, 3 do
        local ourFrame = self.frames[i]
        if ourFrame and ourFrame.blizzDebuffFrame then
            ourFrame.blizzDebuffFrame:SetSize(size, size)
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

            -- Get class info
            local _, classFile = UnitClass(unit)
            if classFile then
                frame.class = classFile
            end

            -- Get spec info
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

            -- Get race info
            if UnitRace then
                local _, raceToken = UnitRace(unit)
                if raceToken then
                    frame.race = raceToken
                end
            end

            -- Update and show frame
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
        -- Also hide immunity glow if disabled
        if frame and frame.immunityGlow and not self.db.profile.immunityGlow then
            frame.immunityGlow:Hide()
            frame.hasImmunity = false
        end
    end
end

function GladiusMidnight:HideBlizzardFrames()
    if not self.db.profile.hideBlizzardFrames then return end

    -- Hide default arena frames
    for i = 1, 5 do
        local frameName = "ArenaEnemyFrame" .. i
        local frame = _G[frameName]
        if frame then
            frame:UnregisterAllEvents()
            frame:Hide()
            frame:SetScript("OnShow", function(self) self:Hide() end)
        end

        -- Also hide the newer compact arena frames
        local compactFrame = _G["CompactArenaFrame" .. i]
        if compactFrame then
            compactFrame:UnregisterAllEvents()
            compactFrame:Hide()
        end
    end

    -- Hide arena prep frames
    if ArenaEnemyPrepFramesContainer then
        ArenaEnemyPrepFramesContainer:Hide()
    end
end

function GladiusMidnight:ZONE_CHANGED_NEW_AREA()
    local _, instanceType = IsInInstance()

    -- Reset Blizzard frames when leaving arena
    if instanceType ~= "arena" and self.blizzFramesInitialized then
        self:ResetBlizzardFrames()
    end

    self:DetectArenaType()
    self:CheckArenaStatus()

    -- Initialize Blizzard frames when entering arena (DR + CastBar)
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
        -- Gates have opened - exit prep phase and re-register unit watch
        if self.prepPhase then
            self.prepPhase = false
            self:Print("Arena gestartet!")
            for i = 1, 3 do
                local f = self.frames[i]
                if f then
                    RegisterUnitWatch(f)
                end
            end
        end

        -- Update class from actual unit now that they exist
        if UnitExists(unit) then
            local _, classFile = UnitClass(unit)
            if classFile then
                frame.class = classFile
            end
        end

        self:UpdateFrame(frame)
        -- Only call Show outside combat to avoid taint
        if not InCombatLockdown() then
            frame:Show()
        end

        -- Explicitly show UIParent-parented module containers now that frame is visible
        if frame.moduleFrames then
            if frame.moduleFrames.drTracker then
                frame.moduleFrames.drTracker:ClearAllPoints()
                frame.moduleFrames.drTracker:SetPoint("RIGHT", frame, "LEFT", -4, 0)
            end
            if frame.moduleFrames.castBar then
                frame.moduleFrames.castBar:ClearAllPoints()
                local height = self.db.profile.castBar.height or 16
                frame.moduleFrames.castBar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", height + 2, -2)
                frame.moduleFrames.castBar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2)
            end
            if frame.moduleFrames.auras then
                local healthHeight = self.db.profile.health.height or 28
                local powerHeight = self:IsModuleEnabled("power") and (self.db.profile.power.height or 10) or 0
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
        -- Hide UIParent-parented module containers
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

    -- Detect arena size if not already detected
    if self.arenaSize == 0 then
        self:DetectArenaType()
    end

    -- Reset all frames for new round (fixes trinket/DR not resetting)
    for i = 1, 3 do
        local frame = self.frames[i]
        if frame then
            self:ResetFrame(frame)
        end
    end

    -- Enter prep phase - unregister unit watch so we can show frames manually
    self.prepPhase = true
    for i = 1, 3 do
        local frame = self.frames[i]
        if frame then
            UnregisterUnitWatch(frame)
        end
    end

    local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or self.arenaSize
    if numOpponents == 0 then numOpponents = self.arenaSize end
    if numOpponents == 0 then numOpponents = 3 end -- Fallback

    self:Print("Prep Phase - " .. numOpponents .. " Gegner erkannt")

    for i = 1, numOpponents do
        local frame = self.frames[i]
        if frame then
            -- Get spec info before gates open
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

    -- Hide frames that shouldn't be shown
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
    -- In Midnight 12.0, spellID may be "secret" for arena opponents
    if self.testMode or not unit or not spellID or type(spellID) ~= "number" then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index or not self.frames[index] then return end

    -- Notify modules
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

    -- DR Tracking: In Midnight 12.0, aura data is "secret" for arena opponents
    -- Most of this will not work - we rely on Blizzard's built-in DR display
    local drModule = self:GetModule("drTracker")
    if drModule and self:IsModuleEnabled("drTracker") then
        -- Try new API first - but spellId is likely secret
        if updateInfo and updateInfo.addedAuras then
            for _, auraInfo in ipairs(updateInfo.addedAuras) do
                if auraInfo and auraInfo.spellId and type(auraInfo.spellId) == "number" then
                    drModule:OnAura(frame, auraInfo.spellId)
                end
            end
        else
            -- Fallback: Full debuff scan - also likely returns secret data
            self:ScanDebuffsForDR(frame, unit)
        end
    end

    -- Notify Auras module - also affected by secret data
    local aurasModule = self:GetModule("auras")
    if aurasModule and self:IsModuleEnabled("auras") then
        aurasModule:OnAuraChange(frame)
    end
end

-- Scan all debuffs for DR spells (Midnight 12.0 fallback)
-- Midnight 12.0: most aura data is "secret" for arena opponents
-- This function relies on issecretvalue() to check before table access
function GladiusMidnight:ScanDebuffsForDR(frame, unit)
    local drModule = self:GetModule("drTracker")
    if not drModule then return end

    -- Track which spells we've already processed this scan
    frame.lastDRScan = frame.lastDRScan or {}
    local currentDebuffs = {}

    -- Scan all debuffs - Midnight 12.0 API with secret value handling
    if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
        for i = 1, 40 do
            local auraData = C_UnitAuras.GetDebuffDataByIndex(unit, i)
            if not auraData then break end

            -- Midnight 12.0 API: Check for secret values using issecretvalue()
            local spellId = auraData.spellId
            if spellId and not (issecretvalue and issecretvalue(spellId)) then
                -- Not secret - safe to use as table key
                currentDebuffs[spellId] = true

                -- Only process if this is a NEW debuff (not seen in last scan)
                if not frame.lastDRScan[spellId] then
                    drModule:OnAura(frame, spellId)
                end
            end
        end
    end

    -- Update last scan
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

function GladiusMidnight:CheckArenaStatus()
    if self.testMode then return end

    local _, instanceType = IsInInstance()

    if instanceType ~= "arena" or not self.db.profile.enabled then
        -- Left arena - reset state
        self.prepPhase = false
        self.arenaSize = 0

        for i = 1, 3 do
            local frame = self.frames[i]
            if frame then
                -- Re-register unit watch for normal operation
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
            -- Try to leave arena
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
