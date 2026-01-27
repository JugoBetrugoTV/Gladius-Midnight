--[[
    Gladius Midnight - Arena Unit Frames
    Compatible with WoW Midnight 12.0
]]

local addonName, addon = ...

-- Create addon using Ace3
local GladiusMidnight = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
addon.core = GladiusMidnight

-- Defaults for AceDB
local defaults = {
    profile = {
        enabled = true,
        locked = true,
        scale = 1.0,
        frameWidth = 180,
        frameHeight = 45,
        spacing = 2,
        posX = 300,
        posY = 200,
        growDirection = "DOWN",
        showHealthText = true,
        showPowerBar = true,
        showTrinket = true,
        showRacial = true,
        classIconSize = 40,
        trinketSize = 22,
    }
}

-- Class colors
local classColors = {
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45 },
    ["ROGUE"] = { r = 1.0, g = 0.96, b = 0.41 },
    ["PRIEST"] = { r = 1.0, g = 1.0, b = 1.0 },
    ["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23 },
    ["SHAMAN"] = { r = 0.0, g = 0.44, b = 0.87 },
    ["MAGE"] = { r = 0.41, g = 0.8, b = 0.94 },
    ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["MONK"] = { r = 0.0, g = 1.0, b = 0.59 },
    ["DRUID"] = { r = 1.0, g = 0.49, b = 0.04 },
    ["DEMONHUNTER"] = { r = 0.64, g = 0.19, b = 0.79 },
    ["EVOKER"] = { r = 0.2, g = 0.58, b = 0.5 },
}

-- Class icon texture coords
local classIconCoords = {
    ["WARRIOR"] = { 0, 0.25, 0, 0.25 },
    ["MAGE"] = { 0.25, 0.5, 0, 0.25 },
    ["ROGUE"] = { 0.5, 0.75, 0, 0.25 },
    ["DRUID"] = { 0.75, 1, 0, 0.25 },
    ["HUNTER"] = { 0, 0.25, 0.25, 0.5 },
    ["SHAMAN"] = { 0.25, 0.5, 0.25, 0.5 },
    ["PRIEST"] = { 0.5, 0.75, 0.25, 0.5 },
    ["WARLOCK"] = { 0.75, 1, 0.25, 0.5 },
    ["PALADIN"] = { 0, 0.25, 0.5, 0.75 },
    ["DEATHKNIGHT"] = { 0.25, 0.5, 0.5, 0.75 },
    ["MONK"] = { 0.5, 0.75, 0.5, 0.75 },
    ["DEMONHUNTER"] = { 0.75, 1, 0.5, 0.75 },
    ["EVOKER"] = { 0, 0.25, 0.75, 1 },
}

-- Store frames
GladiusMidnight.frames = {}
GladiusMidnight.testMode = false

-- ============================================================================
-- Arena Frame Creation
-- ============================================================================
local function CreateArenaFrame(index)
    local unit = "arena" .. index

    local frame = CreateFrame("Button", "GladiusMidnightFrame" .. index, UIParent, "BackdropTemplate")
    frame:SetSize(180, 45)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame.unit = unit
    frame.index = index

    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    -- Class Icon
    frame.classIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.classIcon:SetSize(40, 40)
    frame.classIcon:SetPoint("LEFT", frame, "LEFT", 2, 0)
    frame.classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    frame.classIcon:SetTexCoord(0, 0.25, 0, 0.25) -- Default warrior

    -- Health Bar
    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetSize(100, 22)
    frame.healthBar:SetPoint("TOPLEFT", frame.classIcon, "TOPRIGHT", 2, -1)
    frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.healthBar:SetStatusBarColor(0, 1, 0)
    frame.healthBar:SetMinMaxValues(0, 100)
    frame.healthBar:SetValue(100)

    -- Health Bar Background
    frame.healthBar.bg = frame.healthBar:CreateTexture(nil, "BACKGROUND")
    frame.healthBar.bg:SetAllPoints()
    frame.healthBar.bg:SetColorTexture(0.15, 0.15, 0.15, 1)

    -- Health Text
    frame.healthBar.text = frame.healthBar:CreateFontString(nil, "OVERLAY")
    frame.healthBar.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.healthBar.text:SetPoint("CENTER", frame.healthBar, "CENTER", 0, 0)
    frame.healthBar.text:SetText("100%")

    -- Power Bar
    frame.powerBar = CreateFrame("StatusBar", nil, frame)
    frame.powerBar:SetSize(100, 10)
    frame.powerBar:SetPoint("TOPLEFT", frame.healthBar, "BOTTOMLEFT", 0, -1)
    frame.powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.powerBar:SetStatusBarColor(0, 0, 1)
    frame.powerBar:SetMinMaxValues(0, 100)
    frame.powerBar:SetValue(100)

    -- Power Bar Background
    frame.powerBar.bg = frame.powerBar:CreateTexture(nil, "BACKGROUND")
    frame.powerBar.bg:SetAllPoints()
    frame.powerBar.bg:SetColorTexture(0.1, 0.1, 0.1, 1)

    -- Trinket Icon
    frame.trinket = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.trinket:SetSize(22, 22)
    frame.trinket:SetPoint("LEFT", frame.healthBar, "RIGHT", 4, 0)
    frame.trinket:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.trinket:SetBackdropColor(0, 0, 0, 1)
    frame.trinket:SetBackdropBorderColor(0, 0, 0, 1)

    frame.trinket.icon = frame.trinket:CreateTexture(nil, "ARTWORK")
    frame.trinket.icon:SetAllPoints()
    frame.trinket.icon:SetTexture("Interface\\Icons\\INV_Jewelry_TrinketPVP_01")
    frame.trinket.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.trinket.cooldown = CreateFrame("Cooldown", nil, frame.trinket, "CooldownFrameTemplate")
    frame.trinket.cooldown:SetAllPoints()

    -- Racial Icon
    frame.racial = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.racial:SetSize(22, 22)
    frame.racial:SetPoint("TOP", frame.trinket, "BOTTOM", 0, -2)
    frame.racial:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.racial:SetBackdropColor(0, 0, 0, 1)
    frame.racial:SetBackdropBorderColor(0, 0, 0, 1)

    frame.racial.icon = frame.racial:CreateTexture(nil, "ARTWORK")
    frame.racial.icon:SetAllPoints()
    frame.racial.icon:SetTexture("Interface\\Icons\\Ability_Rogue_Sprint")
    frame.racial.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.racial.cooldown = CreateFrame("Cooldown", nil, frame.racial, "CooldownFrameTemplate")
    frame.racial.cooldown:SetAllPoints()

    -- Drag handlers
    frame:SetScript("OnDragStart", function(self)
        if not GladiusMidnight.db.profile.locked then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        GladiusMidnight.db.profile.posX = x
        GladiusMidnight.db.profile.posY = y
    end)

    frame:Hide()
    return frame
end

-- ============================================================================
-- Update Functions
-- ============================================================================
function GladiusMidnight:UpdateFrame(frame, testData)
    if not frame then return end

    local unit = frame.unit
    local db = self.db.profile

    -- Update size
    frame:SetSize(db.frameWidth, db.frameHeight)
    frame.classIcon:SetSize(db.classIconSize, db.classIconSize)
    frame.healthBar:SetWidth(db.frameWidth - db.classIconSize - db.trinketSize - 12)
    frame.powerBar:SetWidth(db.frameWidth - db.classIconSize - db.trinketSize - 12)
    frame.trinket:SetSize(db.trinketSize, db.trinketSize)
    frame.racial:SetSize(db.trinketSize, db.trinketSize)

    if testData then
        -- Use test data
        local color = classColors[testData.class] or classColors["WARRIOR"]
        frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
        frame.healthBar:SetValue(testData.health)
        frame.healthBar.text:SetText(testData.health .. "%")
        frame.powerBar:SetValue(testData.power)

        local coords = classIconCoords[testData.class] or classIconCoords["WARRIOR"]
        frame.classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    elseif UnitExists(unit) then
        -- Use real unit data
        local _, class = UnitClass(unit)
        if class then
            local color = classColors[class] or classColors["WARRIOR"]
            frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)

            local coords = classIconCoords[class] or classIconCoords["WARRIOR"]
            frame.classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        end

        -- Health (using 12.0 API)
        local healthPercent = UnitHealth(unit) / math.max(UnitHealthMax(unit), 1) * 100
        frame.healthBar:SetValue(healthPercent)
        frame.healthBar.text:SetText(math.floor(healthPercent) .. "%")

        -- Power
        local powerPercent = UnitPower(unit) / math.max(UnitPowerMax(unit), 1) * 100
        frame.powerBar:SetValue(powerPercent)
    end

    -- Show/hide elements
    frame.trinket:SetShown(db.showTrinket)
    frame.racial:SetShown(db.showRacial)
    frame.powerBar:SetShown(db.showPowerBar)
    frame.healthBar.text:SetShown(db.showHealthText)
end

function GladiusMidnight:UpdateAllFrames()
    local db = self.db.profile

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

    for i = 1, 3 do
        local frame = self.frames[i]
        if frame then
            frame:ClearAllPoints()

            if i == 1 then
                frame:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)
            else
                if db.growDirection == "DOWN" then
                    frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -db.spacing)
                elseif db.growDirection == "UP" then
                    frame:SetPoint("BOTTOM", prevFrame, "TOP", 0, db.spacing)
                elseif db.growDirection == "LEFT" then
                    frame:SetPoint("RIGHT", prevFrame, "LEFT", -db.spacing, 0)
                else -- RIGHT
                    frame:SetPoint("LEFT", prevFrame, "RIGHT", db.spacing, 0)
                end
            end

            frame:SetScale(db.scale)
            prevFrame = frame
        end
    end
end

-- ============================================================================
-- Test Mode
-- ============================================================================
function GladiusMidnight:ToggleTest()
    self.testMode = not self.testMode

    if self.testMode then
        self:Print("Test mode |cFF00FF00enabled|r")

        local classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
                          "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
                          "DRUID", "DEMONHUNTER", "EVOKER" }

        for i = 1, 3 do
            local frame = self.frames[i]
            if frame then
                local testData = {
                    class = classes[math.random(1, #classes)],
                    health = math.random(20, 100),
                    power = math.random(0, 100),
                }
                self:UpdateFrame(frame, testData)
                frame:Show()
            end
        end

        self:PositionFrames()
    else
        self:Print("Test mode |cFFFF0000disabled|r")
        for i = 1, 3 do
            local frame = self.frames[i]
            if frame then
                frame:Hide()
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

    -- Create frames
    for i = 1, 3 do
        self.frames[i] = CreateArenaFrame(i)
    end

    -- Register chat commands
    self:RegisterChatCommand("gladius", "SlashCommand")
    self:RegisterChatCommand("gm", "SlashCommand")

    self:Print("Loaded. Type |cFF00FF00/gladius|r for options or |cFF00FF00/gladius test|r to test.")
end

function GladiusMidnight:OnEnable()
    -- Register events
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_POWER_UPDATE")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    self:UpdateAllFrames()
end

-- ============================================================================
-- Event Handlers
-- ============================================================================
function GladiusMidnight:PLAYER_ENTERING_WORLD()
    self:CheckArenaStatus()
end

function GladiusMidnight:ZONE_CHANGED_NEW_AREA()
    self:CheckArenaStatus()
end

function GladiusMidnight:ARENA_OPPONENT_UPDATE(_, unit, updateType)
    if not self.db.profile.enabled then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index then return end

    local frame = self.frames[index]
    if not frame then return end

    if updateType == "seen" or updateType == "cleared" then
        self:UpdateFrame(frame)
        frame:Show()
    elseif updateType == "destroyed" then
        frame:Hide()
    end
end

function GladiusMidnight:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
    if not self.db.profile.enabled then return end

    for i = 1, 3 do
        local frame = self.frames[i]
        if frame and UnitExists("arena" .. i) then
            self:UpdateFrame(frame)
            frame:Show()
        end
    end
end

function GladiusMidnight:UNIT_HEALTH(_, unit)
    local index = tonumber(unit:match("arena(%d)"))
    if not index then return end

    local frame = self.frames[index]
    if frame and frame:IsShown() then
        self:UpdateFrame(frame)
    end
end

function GladiusMidnight:UNIT_POWER_UPDATE(_, unit)
    local index = tonumber(unit:match("arena(%d)"))
    if not index then return end

    local frame = self.frames[index]
    if frame and frame:IsShown() then
        self:UpdateFrame(frame)
    end
end

function GladiusMidnight:CheckArenaStatus()
    if self.testMode then return end

    local _, instanceType = IsInInstance()
    local inArena = (instanceType == "arena")

    if not inArena or not self.db.profile.enabled then
        for i = 1, 3 do
            local frame = self.frames[i]
            if frame then
                frame:Hide()
            end
        end
    end
end

-- ============================================================================
-- Slash Commands
-- ============================================================================
function GladiusMidnight:SlashCommand(input)
    input = input:trim():lower()

    if input == "test" then
        self:ToggleTest()
    elseif input == "lock" then
        self.db.profile.locked = true
        self:Print("Frames |cFF00FF00locked|r")
    elseif input == "unlock" then
        self.db.profile.locked = false
        self:Print("Frames |cFFFF0000unlocked|r - drag to move")
    elseif input == "reset" then
        self.db:ResetProfile()
        self:UpdateAllFrames()
        self:Print("Settings reset to defaults")
    elseif input == "" or input == "config" or input == "options" then
        -- Open options
        Settings.OpenToCategory("Gladius Midnight")
    else
        self:Print("Commands:")
        self:Print("  |cFF00FF00/gladius|r - Open options")
        self:Print("  |cFF00FF00/gladius test|r - Toggle test mode")
        self:Print("  |cFF00FF00/gladius lock|r - Lock frames")
        self:Print("  |cFF00FF00/gladius unlock|r - Unlock frames")
        self:Print("  |cFF00FF00/gladius reset|r - Reset settings")
    end
end

-- Export for other modules
_G.GladiusMidnight = GladiusMidnight
