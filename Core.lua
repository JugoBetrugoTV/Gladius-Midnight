--[[
    Gladius Midnight - Core
    Arena Unit Frames for WoW Midnight 12.0

    Modular architecture - each component is a separate module
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
        frameWidth = 200,
        frameHeight = 60,
        scale = 1.0,
        spacing = 2,
        growDirection = "DOWN",

        -- Position
        posX = 300,
        posY = 100,

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
        },

        -- Module-specific settings
        classIcon = {
            size = 50,
            position = "LEFT",
        },
        health = {
            height = 28,
            showText = true,
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

    frame.unit = unit
    frame.index = index

    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    frame:SetBackdropBorderColor(0, 0, 0, 1)

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
            -- Calculate frame center relative to UIParent center
            local centerX, centerY = f:GetCenter()
            local uiCenterX, uiCenterY = UIParent:GetCenter()
            local scale = f:GetEffectiveScale() / UIParent:GetEffectiveScale()

            if centerX and uiCenterX then
                local x = (centerX - uiCenterX) * scale
                local y = (centerY - uiCenterY) * scale
                GladiusMidnight.db.profile.posX = x
                GladiusMidnight.db.profile.posY = y
            end
        end
        -- Re-position all frames to maintain relative layout
        GladiusMidnight:PositionFrames()
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

    -- Update frame size
    frame:SetSize(db.frameWidth, db.frameHeight)
    frame:SetScale(db.scale)

    -- Update each enabled module
    for name, module in pairs(self.modules) do
        if self:IsModuleEnabled(name) and module.Update then
            module:Update(frame, testData)
        end
    end
end

function GladiusMidnight:UpdateAllFrames()
    for i = 1, 3 do
        local frame = self.frames[i]
        if frame then
            self:UpdateFrame(frame)
        end
    end
    self:PositionFrames()
end

function GladiusMidnight:PositionFrames()
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

    self:Print("Geladen - |cFF00FF00/gladius test|r zum Testen")
end

function GladiusMidnight:OnEnable()
    -- Arena events
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    -- Unit events
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_MAXHEALTH")
    self:RegisterEvent("UNIT_POWER_UPDATE")
    self:RegisterEvent("UNIT_MAXPOWER")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_AURA")

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
end

function GladiusMidnight:ZONE_CHANGED_NEW_AREA()
    self:DetectArenaType()
    self:CheckArenaStatus()
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
        frame:Show()
        self:PositionFrames()
    elseif updateType == "destroyed" then
        frame:Hide()
        self:ResetFrame(frame)
    end
end

function GladiusMidnight:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
    if not self.db.profile.enabled or self.testMode then return end

    -- Detect arena size if not already detected
    if self.arenaSize == 0 then
        self:DetectArenaType()
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
            frame:Show()
        end
    end

    -- Hide frames that shouldn't be shown
    for i = numOpponents + 1, 3 do
        local frame = self.frames[i]
        if frame then
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
    if self.testMode or not unit or not spellID then return end

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

    -- Check for DR-triggering auras using 12.0 API
    local drModule = self:GetModule("drTracker")
    if drModule and self:IsModuleEnabled("drTracker") and updateInfo then
        -- Check added auras
        if updateInfo.addedAuras then
            for _, auraInfo in ipairs(updateInfo.addedAuras) do
                if auraInfo.spellId then
                    drModule:OnAura(self.frames[index], auraInfo.spellId)
                end
            end
        end
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
                RegisterUnitWatch(frame)
                frame:Hide()
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
    end
end

-- Export
_G.GladiusMidnight = GladiusMidnight
