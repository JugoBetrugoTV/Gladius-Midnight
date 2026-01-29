--[[
    Gladius Midnight - Arena Unit Frames
    Compatible with WoW Midnight 12.0

    Uses 12.0 API:
    - StatusBar:SetValue() accepts secret values
    - C_PvP.GetArenaCrowdControlInfo() for trinket tracking
    - UnitHealthPercent/UnitPowerPercent for percentage values
]]

local addonName, addon = ...

-- Create addon using Ace3
local GladiusMidnight = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
addon.core = GladiusMidnight

-- ============================================================================
-- Constants & Data
-- ============================================================================

local TRINKET_COOLDOWN = 120 -- 2 minute cooldown
local RACIAL_COOLDOWNS = {
    -- Alliance
    [59752] = 180,   -- Will to Survive (Human)
    [20594] = 120,   -- Stoneform (Dwarf)
    [58984] = 120,   -- Shadowmeld (Night Elf)
    [20589] = 60,    -- Escape Artist (Gnome)
    [28880] = 180,   -- Gift of the Naaru (Draenei)
    [68992] = 120,   -- Darkflight (Worgen)
    [256948] = 180,  -- Spatial Rift (Void Elf)
    [255647] = 150,  -- Light's Judgment (Lightforged)
    [265221] = 120,  -- Fireblood (Dark Iron)
    [287712] = 150,  -- Haymaker (Kul Tiran)
    [312924] = 150,  -- Emergency Failsafe (Mechagnome)

    -- Horde
    [33697] = 120,   -- Blood Fury (Orc)
    [20572] = 120,   -- Blood Fury (Orc melee)
    [33702] = 120,   -- Blood Fury (Orc spell)
    [7744] = 180,    -- Will of the Forsaken (Undead)
    [20549] = 90,    -- War Stomp (Tauren)
    [26297] = 180,   -- Berserking (Troll)
    [28730] = 120,   -- Arcane Torrent (Blood Elf)
    [69070] = 90,    -- Rocket Jump (Goblin)
    [107079] = 120,  -- Quaking Palm (Pandaren)
    [260364] = 180,  -- Arcane Pulse (Nightborne)
    [255654] = 120,  -- Bull Rush (Highmountain)
    [274738] = 120,  -- Ancestral Call (Mag'har)
    [291944] = 150,  -- Regeneratin' (Zandalari)
    [312411] = 90,   -- Bag of Tricks (Vulpera)
    [368970] = 90,   -- Tail Swipe (Dracthyr)
    [357214] = 90,   -- Wing Buffet (Dracthyr)
}

-- Racials that share CD with trinket
local TRINKET_SHARE_RACIALS = {
    [59752] = true,  -- Will to Survive
    [7744] = true,   -- Will of the Forsaken
}

-- Class colors
local CLASS_COLORS = {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    ROGUE = { r = 1.0, g = 0.96, b = 0.41 },
    PRIEST = { r = 1.0, g = 1.0, b = 1.0 },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    SHAMAN = { r = 0.0, g = 0.44, b = 0.87 },
    MAGE = { r = 0.41, g = 0.8, b = 0.94 },
    WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
    MONK = { r = 0.0, g = 1.0, b = 0.59 },
    DRUID = { r = 1.0, g = 0.49, b = 0.04 },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
    EVOKER = { r = 0.2, g = 0.58, b = 0.5 },
}

-- Class icon coords in UI-CharacterCreate-Classes texture
local CLASS_ICON_COORDS = {
    WARRIOR = { 0, 0.25, 0, 0.25 },
    MAGE = { 0.25, 0.5, 0, 0.25 },
    ROGUE = { 0.5, 0.75, 0, 0.25 },
    DRUID = { 0.75, 1, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 },
    SHAMAN = { 0.25, 0.5, 0.25, 0.5 },
    PRIEST = { 0.5, 0.75, 0.25, 0.5 },
    WARLOCK = { 0.75, 1, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
    DEATHKNIGHT = { 0.25, 0.5, 0.5, 0.75 },
    MONK = { 0.5, 0.75, 0.5, 0.75 },
    DEMONHUNTER = { 0.75, 1, 0.5, 0.75 },
    EVOKER = { 0, 0.25, 0.75, 1 },
}

-- Power colors
local POWER_COLORS = {
    [Enum.PowerType.Mana] = { r = 0.0, g = 0.0, b = 1.0 },
    [Enum.PowerType.Rage] = { r = 1.0, g = 0.0, b = 0.0 },
    [Enum.PowerType.Focus] = { r = 1.0, g = 0.5, b = 0.25 },
    [Enum.PowerType.Energy] = { r = 1.0, g = 1.0, b = 0.0 },
    [Enum.PowerType.RunicPower] = { r = 0.0, g = 0.82, b = 1.0 },
    [Enum.PowerType.Fury] = { r = 0.788, g = 0.259, b = 0.992 },
}

-- ============================================================================
-- Default Settings
-- ============================================================================

local defaults = {
    profile = {
        enabled = true,
        locked = true,
        scale = 1.0,
        frameWidth = 180,
        frameHeight = 50,
        spacing = 2,
        posX = 300,
        posY = 150,
        growDirection = "DOWN",

        -- Display
        showHealthText = true,
        showPowerBar = true,
        showTrinket = true,
        showRacial = true,
        showClassIcon = true,

        -- Sizes
        classIconSize = 45,
        trinketSize = 24,
        healthBarHeight = 26,
        powerBarHeight = 8,
    }
}

-- ============================================================================
-- Frame Storage
-- ============================================================================

GladiusMidnight.frames = {}
GladiusMidnight.testMode = false
GladiusMidnight.arenaSize = 0  -- 0 = not in arena, 2 = 2v2, 3 = 3v3, etc.

-- ============================================================================
-- Arena Frame Creation
-- ============================================================================

local function CreateArenaFrame(index)
    local unit = "arena" .. index

    -- Main frame
    local frame = CreateFrame("Button", "GladiusMidnightFrame" .. index, UIParent, "BackdropTemplate")
    frame:SetSize(180, 50)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
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

    -- Class Icon (left side)
    frame.classIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.classIcon:SetSize(45, 45)
    frame.classIcon:SetPoint("LEFT", 2, 0)
    frame.classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    frame.classIcon:SetTexCoord(0, 0.25, 0, 0.25)

    -- Class icon border (behind the icon)
    frame.classIconBorder = frame:CreateTexture(nil, "BORDER")
    frame.classIconBorder:SetPoint("TOPLEFT", frame.classIcon, -1, 1)
    frame.classIconBorder:SetPoint("BOTTOMRIGHT", frame.classIcon, 1, -1)
    frame.classIconBorder:SetColorTexture(0, 0, 0, 1)

    -- Health Bar
    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetPoint("TOPLEFT", frame.classIcon, "TOPRIGHT", 2, 0)
    frame.healthBar:SetPoint("RIGHT", frame, "RIGHT", -30, 0)
    frame.healthBar:SetHeight(26)
    frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.healthBar:SetStatusBarColor(0, 1, 0)
    frame.healthBar:SetMinMaxValues(0, 100)
    frame.healthBar:SetValue(100)

    -- Health bar background
    frame.healthBar.bg = frame.healthBar:CreateTexture(nil, "BACKGROUND")
    frame.healthBar.bg:SetAllPoints()
    frame.healthBar.bg:SetColorTexture(0.15, 0.15, 0.15, 1)

    -- Health text
    frame.healthBar.text = frame.healthBar:CreateFontString(nil, "OVERLAY")
    frame.healthBar.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    frame.healthBar.text:SetPoint("CENTER")
    frame.healthBar.text:SetText("100%")

    -- Power Bar
    frame.powerBar = CreateFrame("StatusBar", nil, frame)
    frame.powerBar:SetPoint("TOPLEFT", frame.healthBar, "BOTTOMLEFT", 0, -1)
    frame.powerBar:SetPoint("TOPRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, -1)
    frame.powerBar:SetHeight(8)
    frame.powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.powerBar:SetStatusBarColor(0, 0, 1)
    frame.powerBar:SetMinMaxValues(0, 100)
    frame.powerBar:SetValue(100)

    -- Power bar background
    frame.powerBar.bg = frame.powerBar:CreateTexture(nil, "BACKGROUND")
    frame.powerBar.bg:SetAllPoints()
    frame.powerBar.bg:SetColorTexture(0.1, 0.1, 0.1, 1)

    -- Trinket (right side, top)
    frame.trinket = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.trinket:SetSize(24, 24)
    frame.trinket:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    frame.trinket:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.trinket:SetBackdropColor(0, 0, 0, 0.8)
    frame.trinket:SetBackdropBorderColor(0, 0, 0, 1)

    frame.trinket.icon = frame.trinket:CreateTexture(nil, "ARTWORK")
    frame.trinket.icon:SetAllPoints()
    frame.trinket.icon:SetTexture("Interface\\Icons\\INV_Jewelry_TrinketPVP_01")
    frame.trinket.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.trinket.cooldown = CreateFrame("Cooldown", nil, frame.trinket, "CooldownFrameTemplate")
    frame.trinket.cooldown:SetAllPoints(frame.trinket.icon)
    frame.trinket.cooldown:SetDrawSwipe(true)
    frame.trinket.cooldown:SetDrawEdge(false)

    -- Trinket tracking data
    frame.trinket.spellID = nil
    frame.trinket.startTime = 0
    frame.trinket.duration = 0

    -- Racial (right side, bottom)
    frame.racial = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.racial:SetSize(24, 24)
    frame.racial:SetPoint("TOP", frame.trinket, "BOTTOM", 0, -1)
    frame.racial:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.racial:SetBackdropColor(0, 0, 0, 0.8)
    frame.racial:SetBackdropBorderColor(0, 0, 0, 1)

    frame.racial.icon = frame.racial:CreateTexture(nil, "ARTWORK")
    frame.racial.icon:SetAllPoints()
    frame.racial.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.racial.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.racial.cooldown = CreateFrame("Cooldown", nil, frame.racial, "CooldownFrameTemplate")
    frame.racial.cooldown:SetAllPoints(frame.racial.icon)
    frame.racial.cooldown:SetDrawSwipe(true)
    frame.racial.cooldown:SetDrawEdge(false)

    -- Racial tracking data
    frame.racial.spellID = nil
    frame.racial.startTime = 0
    frame.racial.duration = 0

    -- Drag handlers
    frame:SetScript("OnDragStart", function(self)
        if not GladiusMidnight.db.profile.locked then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        GladiusMidnight.db.profile.posX = x
        GladiusMidnight.db.profile.posY = y
    end)

    -- Target on click
    frame:SetAttribute("type", "target")
    frame:SetAttribute("unit", unit)
    RegisterUnitWatch(frame)

    frame:Hide()
    return frame
end

-- ============================================================================
-- Update Functions
-- ============================================================================

-- Update health bar using 12.0 API
function GladiusMidnight:UpdateHealth(frame)
    local unit = frame.unit
    if not UnitExists(unit) then return end

    -- In 12.0, we can pass secret values directly to StatusBar:SetValue()
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)

    if maxHealth > 0 then
        -- Calculate percentage for display
        local percent = (health / maxHealth) * 100
        frame.healthBar:SetMinMaxValues(0, maxHealth)
        frame.healthBar:SetValue(health)

        if self.db.profile.showHealthText then
            frame.healthBar.text:SetText(math.floor(percent) .. "%")
        end
    end

    -- Update color based on class
    local _, class = UnitClass(unit)
    if class and CLASS_COLORS[class] then
        local c = CLASS_COLORS[class]
        frame.healthBar:SetStatusBarColor(c.r, c.g, c.b)
    end
end

-- Update power bar
function GladiusMidnight:UpdatePower(frame)
    local unit = frame.unit
    if not UnitExists(unit) then return end

    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    local powerType = UnitPowerType(unit)

    if maxPower > 0 then
        frame.powerBar:SetMinMaxValues(0, maxPower)
        frame.powerBar:SetValue(power)
    end

    -- Update power color
    local color = POWER_COLORS[powerType] or POWER_COLORS[Enum.PowerType.Mana]
    frame.powerBar:SetStatusBarColor(color.r, color.g, color.b)
end

-- Update class icon
function GladiusMidnight:UpdateClassIcon(frame)
    local unit = frame.unit
    if not UnitExists(unit) then return end

    local _, class = UnitClass(unit)
    if class and CLASS_ICON_COORDS[class] then
        local coords = CLASS_ICON_COORDS[class]
        frame.classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    end
end

-- Update trinket using C_PvP.GetArenaCrowdControlInfo (12.0 API)
function GladiusMidnight:UpdateTrinket(frame)
    local unit = frame.unit
    if not UnitExists(unit) then return end

    -- C_PvP.GetArenaCrowdControlInfo returns info about CC break abilities
    -- In 12.0, this API may not exist or have different signature
    if C_PvP and C_PvP.GetArenaCrowdControlInfo then
        local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)

        if spellID and spellID ~= frame.trinket.spellID then
            -- New trinket usage detected
            frame.trinket.spellID = spellID
            frame.trinket.startTime = startTime or GetTime()
            frame.trinket.duration = duration or TRINKET_COOLDOWN

            -- Update icon using 12.0 C_Spell API
            if C_Spell and C_Spell.GetSpellInfo then
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                if spellInfo and spellInfo.iconID then
                    frame.trinket.icon:SetTexture(spellInfo.iconID)
                end
            else
                -- Fallback for older API
                local _, _, icon = GetSpellInfo(spellID)
                if icon then
                    frame.trinket.icon:SetTexture(icon)
                end
            end

            -- Set cooldown
            if frame.trinket.startTime and frame.trinket.duration then
                frame.trinket.cooldown:SetCooldown(frame.trinket.startTime, frame.trinket.duration)
            end

            -- Desaturate when on cooldown
            frame.trinket.icon:SetDesaturated(true)

            -- Check if this affects racial (shared CD)
            if TRINKET_SHARE_RACIALS[spellID] then
                self:ApplySharedRacialCooldown(frame, 90) -- 90 second shared CD
            end
        elseif not spellID and frame.trinket.spellID then
            -- Check if cooldown expired
            local elapsed = GetTime() - (frame.trinket.startTime or 0)
            if elapsed >= (frame.trinket.duration or TRINKET_COOLDOWN) then
                frame.trinket.icon:SetDesaturated(false)
            end
        end
    end

    -- Also check cooldown expiry
    if frame.trinket.startTime and frame.trinket.startTime > 0 and frame.trinket.duration and frame.trinket.duration > 0 then
        local elapsed = GetTime() - frame.trinket.startTime
        if elapsed >= frame.trinket.duration then
            frame.trinket.icon:SetDesaturated(false)
            frame.trinket.startTime = 0
            frame.trinket.duration = 0
        end
    end
end

-- Apply shared cooldown to racial
function GladiusMidnight:ApplySharedRacialCooldown(frame, duration)
    frame.racial.startTime = GetTime()
    frame.racial.duration = duration
    frame.racial.cooldown:SetCooldown(GetTime(), duration)
    frame.racial.icon:SetDesaturated(true)
end

-- Handle spell cast for racial tracking
function GladiusMidnight:OnSpellCast(frame, spellID)
    if not spellID then return end

    -- Check if it's a tracked racial
    local cooldown = RACIAL_COOLDOWNS[spellID]
    if cooldown then
        frame.racial.spellID = spellID
        frame.racial.startTime = GetTime()
        frame.racial.duration = cooldown

        -- Update icon using 12.0 C_Spell API with fallback
        if C_Spell and C_Spell.GetSpellInfo then
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo and spellInfo.iconID then
                frame.racial.icon:SetTexture(spellInfo.iconID)
            end
        else
            -- Fallback for older API
            local _, _, icon = GetSpellInfo(spellID)
            if icon then
                frame.racial.icon:SetTexture(icon)
            end
        end

        -- Set cooldown
        frame.racial.cooldown:SetCooldown(GetTime(), cooldown)
        frame.racial.icon:SetDesaturated(true)

        -- Check if it also triggers trinket CD
        if TRINKET_SHARE_RACIALS[spellID] then
            frame.trinket.startTime = GetTime()
            frame.trinket.duration = 90
            frame.trinket.cooldown:SetCooldown(GetTime(), 90)
            frame.trinket.icon:SetDesaturated(true)
        end
    end
end

-- Update all frames
function GladiusMidnight:UpdateAllFrames()
    for i = 1, 3 do
        local frame = self.frames[i]
        if frame then
            self:UpdateFrame(frame)
            if self.testMode or frame:IsShown() then
                self:PositionFrames()
            end
        end
    end
end

-- Full frame update
function GladiusMidnight:UpdateFrame(frame, testData)
    if not frame then return end

    local db = self.db.profile

    -- Update sizes
    frame:SetSize(db.frameWidth, db.frameHeight)
    frame.classIcon:SetSize(db.classIconSize, db.classIconSize)
    frame.trinket:SetSize(db.trinketSize, db.trinketSize)
    frame.racial:SetSize(db.trinketSize, db.trinketSize)

    local barWidth = db.frameWidth - db.classIconSize - db.trinketSize - 10
    frame.healthBar:SetHeight(db.healthBarHeight)
    frame.powerBar:SetHeight(db.powerBarHeight)

    -- Show/hide elements
    frame.classIcon:SetShown(db.showClassIcon)
    frame.classIconBorder:SetShown(db.showClassIcon)
    frame.trinket:SetShown(db.showTrinket)
    frame.racial:SetShown(db.showRacial)
    frame.powerBar:SetShown(db.showPowerBar)
    frame.healthBar.text:SetShown(db.showHealthText)

    -- Adjust health bar position based on class icon visibility
    frame.healthBar:ClearAllPoints()
    if db.showClassIcon then
        frame.healthBar:SetPoint("TOPLEFT", frame.classIcon, "TOPRIGHT", 2, 0)
    else
        frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    end
    frame.healthBar:SetPoint("RIGHT", frame, "RIGHT", db.showTrinket and -db.trinketSize - 4 or -2, 0)

    if testData then
        -- Test mode data
        local c = CLASS_COLORS[testData.class] or CLASS_COLORS.WARRIOR
        frame.healthBar:SetStatusBarColor(c.r, c.g, c.b)
        frame.healthBar:SetMinMaxValues(0, 100)
        frame.healthBar:SetValue(testData.health)
        frame.healthBar.text:SetText(testData.health .. "%")

        frame.powerBar:SetMinMaxValues(0, 100)
        frame.powerBar:SetValue(testData.power)

        local coords = CLASS_ICON_COORDS[testData.class] or CLASS_ICON_COORDS.WARRIOR
        frame.classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        -- Real data
        self:UpdateHealth(frame)
        self:UpdatePower(frame)
        self:UpdateClassIcon(frame)
        self:UpdateTrinket(frame)
    end
end

-- Position all frames
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

    -- Check for Solo Shuffle
    if C_PvP.IsSoloShuffle and C_PvP.IsSoloShuffle() then
        self.arenaSize = 3
        self:Print("Detected: Solo Shuffle")
        return
    end

    -- Check arena size via GetMaxBattlefieldID or MaxArenaSize
    local maxSize = GetMaxBattlefieldID and GetMaxBattlefieldID() or 3

    -- Try to detect from bracket
    if C_PvP.GetActiveMatchBracket then
        local bracket = C_PvP.GetActiveMatchBracket()
        if bracket == 1 then
            self.arenaSize = 2
        elseif bracket == 2 then
            self.arenaSize = 3
        else
            self.arenaSize = 3
        end
    else
        self.arenaSize = 3
    end

    self:Print("Detected: " .. self.arenaSize .. "v" .. self.arenaSize .. " Arena")
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
    self.db = LibStub("AceDB-3.0"):New("GladiusMidnightDB", defaults, true)

    -- Create frames
    for i = 1, 3 do
        self.frames[i] = CreateArenaFrame(i)
    end

    -- Register slash commands
    self:RegisterChatCommand("gladius", "SlashCommand")
    self:RegisterChatCommand("gm", "SlashCommand")

    self:Print("Loaded - Type |cFF00FF00/gladius test|r to test")
end

function GladiusMidnight:OnEnable()
    -- Arena events
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    -- Unit events for updates
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_MAXHEALTH")
    self:RegisterEvent("UNIT_POWER_UPDATE")
    self:RegisterEvent("UNIT_MAXPOWER")

    -- Spell cast for racial tracking
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    -- Cooldown update timer (12.0: polling is safer than combat log)
    self.updateTimer = C_Timer.NewTicker(0.1, function()
        if self.testMode then return end

        for i = 1, 3 do
            local frame = self.frames[i]
            if frame and frame:IsShown() then
                self:UpdateTrinket(frame)
                self:UpdateRacialCooldown(frame)
            end
        end
    end)
end

-- Check racial cooldown expiry
function GladiusMidnight:UpdateRacialCooldown(frame)
    if frame.racial.startTime and frame.racial.startTime > 0 and frame.racial.duration and frame.racial.duration > 0 then
        local elapsed = GetTime() - frame.racial.startTime
        if elapsed >= frame.racial.duration then
            frame.racial.icon:SetDesaturated(false)
            frame.racial.startTime = 0
            frame.racial.duration = 0
        end
    end
end

function GladiusMidnight:OnDisable()
    if self.updateTimer then
        self.updateTimer:Cancel()
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
    if not self.db.profile.enabled then return end
    if self.testMode then return end

    local index = tonumber(unit:match("arena(%d)"))
    if not index or not self.frames[index] then return end

    local frame = self.frames[index]

    if updateType == "seen" or updateType == "cleared" then
        self:UpdateFrame(frame)
        frame:Show()
        self:PositionFrames()
    elseif updateType == "destroyed" then
        frame:Hide()
    end
end

function GladiusMidnight:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
    if not self.db.profile.enabled then return end
    if self.testMode then return end

    for i = 1, self.arenaSize do
        local frame = self.frames[i]
        local unit = "arena" .. i

        if frame and UnitExists(unit) then
            self:UpdateFrame(frame)
            frame:Show()
        end
    end

    self:PositionFrames()
end

function GladiusMidnight:UNIT_HEALTH(_, unit)
    if self.testMode then return end

    local index = tonumber(unit:match("arena(%d)"))
    if index and self.frames[index] and self.frames[index]:IsShown() then
        self:UpdateHealth(self.frames[index])
    end
end

function GladiusMidnight:UNIT_MAXHEALTH(_, unit)
    self:UNIT_HEALTH(_, unit)
end

function GladiusMidnight:UNIT_POWER_UPDATE(_, unit)
    if self.testMode then return end

    local index = tonumber(unit:match("arena(%d)"))
    if index and self.frames[index] and self.frames[index]:IsShown() then
        self:UpdatePower(self.frames[index])
    end
end

function GladiusMidnight:UNIT_MAXPOWER(_, unit)
    self:UNIT_POWER_UPDATE(_, unit)
end

function GladiusMidnight:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
    if self.testMode then return end
    if not unit or not spellID then return end

    local index = tonumber(unit:match("arena(%d)"))
    if index and self.frames[index] then
        self:OnSpellCast(self.frames[index], spellID)
    end
end

function GladiusMidnight:CheckArenaStatus()
    if self.testMode then return end

    local _, instanceType = IsInInstance()

    if instanceType ~= "arena" or not self.db.profile.enabled then
        for i = 1, 3 do
            if self.frames[i] then
                self.frames[i]:Hide()
                self:ResetFrameCooldowns(self.frames[i])
            end
        end
    end
end

-- Reset cooldown tracking data for a frame
function GladiusMidnight:ResetFrameCooldowns(frame)
    -- Reset trinket
    frame.trinket.spellID = nil
    frame.trinket.startTime = 0
    frame.trinket.duration = 0
    frame.trinket.cooldown:Clear()
    frame.trinket.icon:SetDesaturated(false)
    frame.trinket.icon:SetTexture("Interface\\Icons\\INV_Jewelry_TrinketPVP_01")

    -- Reset racial
    frame.racial.spellID = nil
    frame.racial.startTime = 0
    frame.racial.duration = 0
    frame.racial.cooldown:Clear()
    frame.racial.icon:SetDesaturated(false)
    frame.racial.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
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
        self:Print("Frames |cFF00FF00locked|r")
    elseif input == "unlock" then
        self.db.profile.locked = false
        self:Print("Frames |cFFFF0000unlocked|r - drag to move")
    elseif input == "reset" then
        self.db:ResetProfile()
        self:PositionFrames()
        self:Print("Settings reset")
    elseif input == "config" or input == "" then
        LibStub("AceConfigDialog-3.0"):Open(addonName)
    else
        self:Print("Commands:")
        self:Print("  |cFF00FF00/gladius|r - Open config")
        self:Print("  |cFF00FF00/gladius test|r - Toggle test")
        self:Print("  |cFF00FF00/gladius lock|r - Lock frames")
        self:Print("  |cFF00FF00/gladius unlock|r - Unlock frames")
        self:Print("  |cFF00FF00/gladius reset|r - Reset settings")
    end
end

-- Export
_G.GladiusMidnight = GladiusMidnight
