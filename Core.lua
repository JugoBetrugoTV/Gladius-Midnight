--[[=========================================================================
    Gladius Midnight - Core
    Main addon initialization, event routing, and frame management
===========================================================================]]

local ADDON_NAME, Gladius = ...

-- Create the main addon namespace table
GladiusMidnight = Gladius

-- =========================================================================
-- Default saved variable settings
-- =========================================================================
Gladius.DEFAULTS = {
    profile = {
        -- General
        locked       = true,
        enabled      = true,
        frameScale   = 1.0,
        growDirection = "DOWN",
        frameSpacing = 35,
        frameWidth   = 170,
        frameHeight  = 44,
        powerBarHeight = 12,

        -- Position
        posX = nil,
        posY = nil,

        -- Visual
        classColorBars  = true,
        classColorNames = true,
        showNames       = true,
        showHealthText  = true,
        showPowerText   = false,
        darkBackground  = true,
        bgAlpha         = 0.85,
        barTexture      = "Interface\\TargetingFrame\\UI-StatusBar",

        -- Class Icon
        classIconEnabled    = true,
        classIconSize       = 44,
        showSpecIcon        = true,
        auraPriorityOnIcon  = true,

        -- Trinket
        trinketEnabled      = true,
        trinketSize         = 28,
        trinketDesaturateCD = true,

        -- Racial
        racialEnabled       = true,
        racialSize          = 28,
        swapRacialToTrinket = false,

        -- Auras
        aurasEnabled        = true,
        auraShowStacks      = true,

        -- DR Tracker
        drEnabled           = true,
        drSize              = 24,
        drGrowDirection     = "RIGHT",
        drSpacing           = 2,
        drShowSeverity      = true,
        drColorText         = true,
        drCategories = {
            ["Stun"]         = true,
            ["Incapacitate"] = true,
            ["Disorient"]    = true,
            ["Silence"]      = true,
            ["Root"]         = true,
            ["Disarm"]       = true,
            ["Knock"]        = true,
        },

        -- Cast Bar
        castBarEnabled      = true,
        castBarHeight       = 16,
        castBarShowIcon     = true,
        castBarShowTime     = true,
        castBarInterruptColor = true,
        castBarColors = {
            normal          = { r = 1.0, g = 0.7, b = 0.0 },
            channel         = { r = 0.0, g = 1.0, b = 0.0 },
            uninterruptible = { r = 0.7, g = 0.7, b = 0.7 },
            interrupted     = { r = 1.0, g = 0.0, b = 0.0 },
        },

        -- Interrupt
        interruptEnabled        = true,
        interruptColorCastbar   = true,

        -- Indicators
        targetHighlight  = true,
        focusHighlight   = true,
    },
}

-- =========================================================================
-- Addon State
-- =========================================================================
Gladius.arenaFrames = {}
Gladius.isInArena = false
Gladius.isTestMode = false
Gladius.playerFaction = nil
Gladius.playerClass = nil
Gladius.playerInterruptOnCD = false

local MAX_ARENA_OPPONENTS = 5

-- =========================================================================
-- Main Event Frame (created in Lua to avoid XML mixin timing issues)
-- =========================================================================
local function CreateEventFrame()
    local frame = CreateFrame("Frame", "GladiusMidnightFrame", UIParent)
    frame:Hide()

    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            Gladius:Initialize()
        elseif event == "PLAYER_ENTERING_WORLD" then
            Gladius:OnEnteringWorld()
        elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
            Gladius:OnArenaPrepOpponents()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            Gladius:OnCombatLogEvent()
        elseif event == "PLAYER_TARGET_CHANGED" then
            Gladius:RefreshTargetIndicators()
        elseif event == "PLAYER_FOCUS_CHANGED" then
            Gladius:RefreshFocusIndicators()
        elseif event == "UNIT_TARGET" then
            local unit = ...
            if unit and unit:match("^party") then
                Gladius:RefreshTargetIndicators()
            end
        end
    end)

    frame:RegisterEvent("PLAYER_LOGIN")
    return frame
end

GladiusMidnightFrame = CreateEventFrame()

-- =========================================================================
-- Initialization
-- =========================================================================
function Gladius:Initialize()
    -- Player info
    self.playerFaction = UnitFactionGroup("player")
    _, self.playerClass = UnitClass("player")

    -- Setup AceDB
    self.db = LibStub("AceDB-3.0"):New("GladiusMidnightDB", self.DEFAULTS, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

    -- Create arena frames
    self:CreateArenaFrames()

    -- Register slash commands
    SLASH_GLADIUSMIDNIGHT1 = "/gladius"
    SLASH_GLADIUSMIDNIGHT2 = "/gm"
    SlashCmdList["GLADIUSMIDNIGHT"] = function(msg)
        self:HandleSlashCommand(msg)
    end

    -- Register main events
    local eventFrame = GladiusMidnightFrame
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")

    -- Hide default Blizzard arena frames if they exist
    self:SuppressBlizzardFrames()

    -- Setup configuration
    self:SetupConfig()

    -- Load saved position
    self:RestorePosition()

    print("|cff00ccffGladius Midnight|r v1.0.0 loaded. Type |cff00ccff/gladius|r for options.")
end

function Gladius:OnProfileChanged()
    for i = 1, MAX_ARENA_OPPONENTS do
        local frame = self.arenaFrames[i]
        if frame then
            frame:ApplySettings()
        end
    end
    self:RestorePosition()
end

-- =========================================================================
-- Arena Frame Creation
-- =========================================================================
function Gladius:CreateArenaFrames()
    local anchor = CreateFrame("Frame", "GladiusAnchor", UIParent)
    anchor:SetSize(10, 10)
    anchor:SetPoint("RIGHT", UIParent, "RIGHT", -100, 0)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    self.anchorFrame = anchor

    -- Create drag handle
    local drag = CreateFrame("Frame", nil, anchor)
    drag:SetAllPoints()
    drag:EnableMouse(false)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function()
        if not Gladius.db.profile.locked then
            anchor:StartMoving()
        end
    end)
    drag:SetScript("OnDragStop", function()
        anchor:StopMovingOrSizing()
        Gladius:SavePosition()
    end)
    self.dragFrame = drag

    for i = 1, MAX_ARENA_OPPONENTS do
        local unitID = "arena" .. i
        local frameName = "GladiusArenaFrame" .. i

        local frame = CreateFrame("Button", frameName, UIParent, "GladiusArenaFrameTemplate")
        Mixin(frame, GladiusArenaFrameMixin)

        -- Set up script handlers after mixin is applied
        frame:SetScript("OnEvent", function(f, event, ...) f:OnEvent(event, ...) end)
        frame:SetScript("OnEnter", function(f) f:OnEnter() end)
        frame:SetScript("OnLeave", function(f) f:OnLeave() end)

        frame:OnLoad()
        frame.unitID = unitID
        frame.frameIndex = i

        -- Position relative to anchor
        local db = self.db.profile
        local spacing = db.frameSpacing
        local growDir = db.growDirection

        if i == 1 then
            frame:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0)
        else
            local prev = self.arenaFrames[i - 1]
            if growDir == "DOWN" then
                frame:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -spacing)
            else
                frame:SetPoint("BOTTOMRIGHT", prev, "TOPRIGHT", 0, spacing)
            end
        end

        -- Click bindings: left=target, right=focus
        frame:SetAttribute("type1", "target")
        frame:SetAttribute("unit", unitID)
        frame:SetAttribute("*type2", "focus")
        frame:SetAttribute("*unit2", unitID)

        frame:ApplySettings()
        frame:Hide()

        self.arenaFrames[i] = frame
    end
end

-- =========================================================================
-- Position Save/Restore
-- =========================================================================
function Gladius:SavePosition()
    local point, _, relPoint, x, y = self.anchorFrame:GetPoint(1)
    self.db.profile.posX = x
    self.db.profile.posY = y
end

function Gladius:RestorePosition()
    local x = self.db.profile.posX
    local y = self.db.profile.posY
    if x and y then
        self.anchorFrame:ClearAllPoints()
        self.anchorFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", x, y)
    end
end

-- =========================================================================
-- Arena Lifecycle Events
-- =========================================================================
function Gladius:OnEnteringWorld()
    local _, instanceType = IsInInstance()
    local wasInArena = self.isInArena
    self.isInArena = (instanceType == "arena")

    if self.isInArena and not wasInArena then
        self:EnterArena()
    elseif not self.isInArena and wasInArena then
        self:LeaveArena()
    elseif not self.isInArena and not self.isTestMode then
        self:HideAllFrames()
    end
end

function Gladius:EnterArena()
    local eventFrame = GladiusMidnightFrame
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    eventFrame:RegisterEvent("UNIT_TARGET")

    -- Enable mouse on frames
    for i = 1, MAX_ARENA_OPPONENTS do
        local frame = self.arenaFrames[i]
        if frame then
            frame:EnableMouse(true)
            frame:RegisterUnitEvents()
            frame:Show()
            frame:ResetState()
        end
    end
end

function Gladius:LeaveArena()
    local eventFrame = GladiusMidnightFrame
    eventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:UnregisterEvent("PLAYER_FOCUS_CHANGED")
    eventFrame:UnregisterEvent("UNIT_TARGET")

    self.isTestMode = false
    self:HideAllFrames()
end

function Gladius:OnArenaPrepOpponents()
    for i = 1, MAX_ARENA_OPPONENTS do
        local frame = self.arenaFrames[i]
        if frame then
            frame:ResetDRState()
            local specID = GetArenaOpponentSpec(i)
            if specID and specID > 0 then
                frame:SetSpecialization(specID)
                frame:Show()
            end
        end
    end
end

function Gladius:HideAllFrames()
    for i = 1, MAX_ARENA_OPPONENTS do
        local frame = self.arenaFrames[i]
        if frame then
            frame:UnregisterUnitEvents()
            frame:Hide()
            frame:ResetState()
        end
    end
end

-- =========================================================================
-- Combat Log Event Router
-- =========================================================================
function Gladius:OnCombatLogEvent()
    local timestamp, combatEvent, hideCaster, sourceGUID, sourceName,
          sourceFlags, sourceRaidFlags, destGUID, destName, destFlags,
          destRaidFlags = CombatLogGetCurrentEventInfo()

    if not combatEvent then return end

    -- Route relevant combat events to arena frames
    local spellID, spellName
    if combatEvent == "SPELL_CAST_SUCCESS"
        or combatEvent == "SPELL_AURA_APPLIED"
        or combatEvent == "SPELL_AURA_REMOVED"
        or combatEvent == "SPELL_AURA_REFRESH"
        or combatEvent == "SPELL_INTERRUPT"
        or combatEvent == "SPELL_AURA_BROKEN_SPELL"
    then
        spellID = select(12, CombatLogGetCurrentEventInfo())
        spellName = select(13, CombatLogGetCurrentEventInfo())
    else
        return
    end

    if not spellID then return end

    -- Find the arena frame by GUID
    local destFrame = self:GetFrameByGUID(destGUID)
    local sourceFrame = self:GetFrameByGUID(sourceGUID)

    -- DR tracking: detect CC applied/removed on enemies
    if destFrame and self.db.profile.drEnabled then
        if combatEvent == "SPELL_AURA_APPLIED" or combatEvent == "SPELL_AURA_REFRESH" then
            destFrame:OnDRAuraApplied(spellID)
        elseif combatEvent == "SPELL_AURA_REMOVED" or combatEvent == "SPELL_AURA_BROKEN_SPELL" then
            destFrame:OnDRAuraRemoved(spellID)
        end
    end

    -- Racial detection: enemy used a racial ability
    if sourceFrame and combatEvent == "SPELL_CAST_SUCCESS" then
        sourceFrame:OnRacialDetected(spellID)
    end

    -- Interrupt detection: someone interrupted an enemy
    if destFrame and combatEvent == "SPELL_INTERRUPT" then
        local extraSpellID = select(15, CombatLogGetCurrentEventInfo())
        destFrame:OnInterrupted(spellID, extraSpellID, sourceGUID, sourceName)
    end

    -- Trinket detection from combat log (backup for ARENA_COOLDOWNS_UPDATE)
    if sourceFrame and combatEvent == "SPELL_CAST_SUCCESS" then
        if spellID == Gladius.TRINKET_SPELL_ID then
            sourceFrame:OnTrinketUsed()
        end
    end
end

function Gladius:GetFrameByGUID(guid)
    if not guid then return nil end
    for i = 1, MAX_ARENA_OPPONENTS do
        local frame = self.arenaFrames[i]
        if frame and frame:IsShown() and UnitGUID(frame.unitID) == guid then
            return frame
        end
    end
    return nil
end

-- =========================================================================
-- Target / Focus Indicators
-- =========================================================================
function Gladius:RefreshTargetIndicators()
    if not self.db.profile.targetHighlight then return end
    for i = 1, MAX_ARENA_OPPONENTS do
        local frame = self.arenaFrames[i]
        if frame and frame:IsShown() then
            local isTarget = UnitIsUnit(frame.unitID, "target")
            frame.TargetHighlight:SetShown(isTarget)
        end
    end
end

function Gladius:RefreshFocusIndicators()
    if not self.db.profile.focusHighlight then return end
    for i = 1, MAX_ARENA_OPPONENTS do
        local frame = self.arenaFrames[i]
        if frame and frame:IsShown() then
            local isFocus = UnitIsUnit(frame.unitID, "focus")
            frame.FocusHighlight:SetShown(isFocus)
        end
    end
end

-- =========================================================================
-- Suppress Blizzard Arena Frames
-- =========================================================================
function Gladius:SuppressBlizzardFrames()
    -- Attempt to hide Blizzard's compact arena frames in Midnight
    if CompactArenaFrame then
        CompactArenaFrame:UnregisterAllEvents()
        CompactArenaFrame:Hide()
        hooksecurefunc(CompactArenaFrame, "Show", function(self)
            self:Hide()
        end)
    end
end

-- =========================================================================
-- Slash Command Handler
-- =========================================================================
function Gladius:HandleSlashCommand(msg)
    msg = msg and msg:trim():lower() or ""

    if msg == "" or msg == "config" or msg == "options" then
        self:OpenConfig()
    elseif msg == "lock" then
        self.db.profile.locked = true
        self.dragFrame:EnableMouse(false)
        print("|cff00ccffGladius Midnight|r: Frames locked.")
    elseif msg == "unlock" then
        self.db.profile.locked = false
        self.dragFrame:EnableMouse(true)
        print("|cff00ccffGladius Midnight|r: Frames unlocked. Drag to reposition.")
    elseif msg:match("^test") then
        local count = tonumber(msg:match("test%s*(%d)")) or 3
        self:ActivateTestMode(count)
    elseif msg == "hide" then
        self.isTestMode = false
        self:HideAllFrames()
        print("|cff00ccffGladius Midnight|r: Test mode disabled.")
    elseif msg == "version" or msg == "ver" then
        print("|cff00ccffGladius Midnight|r v1.0.0")
    else
        print("|cff00ccffGladius Midnight|r commands:")
        print("  /gladius - Open configuration")
        print("  /gladius test [1-5] - Show test frames")
        print("  /gladius hide - Hide test frames")
        print("  /gladius lock - Lock frame position")
        print("  /gladius unlock - Unlock frame position")
    end
end

-- =========================================================================
-- Test Mode
-- =========================================================================
local TEST_CLASSES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
    "DRUID", "DEMONHUNTER", "EVOKER",
}

local TEST_RACES = {
    "Human", "Orc", "Dwarf", "NightElf", "Scourge",
    "Tauren", "Gnome", "Troll", "BloodElf", "Draenei",
    "Worgen", "Goblin", "Pandaren", "Dracthyr",
}

local TEST_NAMES = {
    "Shadowstrike", "Frostweaver", "Lightbringer",
    "Doomcaller", "Stormrider",
}

function Gladius:ActivateTestMode(count)
    count = math.min(count or 3, MAX_ARENA_OPPONENTS)
    self.isTestMode = true

    for i = 1, MAX_ARENA_OPPONENTS do
        local frame = self.arenaFrames[i]
        if frame then
            if i <= count then
                local classIndex = math.random(1, #TEST_CLASSES)
                local raceIndex = math.random(1, #TEST_RACES)
                local testClass = TEST_CLASSES[classIndex]
                local testRace = TEST_RACES[raceIndex]
                local testName = TEST_NAMES[i] or ("Opponent" .. i)
                local testHealth = math.random(40, 100)
                local testPower = math.random(20, 100)

                frame:SetTestData(testName, testClass, testRace, testHealth, testPower)
                frame:Show()
            else
                frame:Hide()
            end
        end
    end

    print("|cff00ccffGladius Midnight|r: Test mode with " .. count .. " opponents.")
end
