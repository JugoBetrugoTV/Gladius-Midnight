--[[
    Gladius Midnight - Core
    Main addon logic: initialization, event handling, layout system,
    texture/font management, test mode, and global utilities.
]]

local isMidnight = GladiusMixin.isMidnight
local isRetail = GladiusMixin.isRetail
local L = GladiusMixin.L

-----------------------------------------------------------------------
-- Global state
-----------------------------------------------------------------------
GladiusMixin.playerClass = select(2, UnitClass("player"))
GladiusMixin.maxArenaOpponents = 3
GladiusMixin.showPixelBorder = false
GladiusMixin.interruptReady = true
GladiusMixin.beenInArena = false
GladiusMixin.shadowsightTimers = {0, 0}
GladiusMixin.shadowsightAvailable = 2
GladiusMixin.activeNonDurationAuras = {}

-----------------------------------------------------------------------
-- Libraries & media registration
-----------------------------------------------------------------------
local LSM = LibStub("LibSharedMedia-3.0")
local decimalThreshold = 6

local ADDON_PATH = [[Interface\AddOns\GladiusMidnight\Textures\]]

LSM:Register("statusbar", "Blizzard RetailBar", ADDON_PATH .. "BlizzardRetailBar")
LSM:Register("statusbar", "Gladius Default",    ADDON_PATH .. "sArenaDefault")
LSM:Register("statusbar", "Gladius Stripes",    ADDON_PATH .. "sArenaHealer")
LSM:Register("statusbar", "Gladius Stripes 2",  ADDON_PATH .. "sArenaRetailHealer")
LSM:Register("font", "Prototype",
    "Interface\\AddOns\\GladiusMidnight\\Textures\\Prototype.ttf",
    LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU)
LSM:Register("font", "PT Sans Narrow Bold",
    "Interface\\AddOns\\GladiusMidnight\\Textures\\PTSansNarrow-Bold.ttf",
    LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU)

GladiusMixin.pFont = LSM:Fetch(LSM.MediaType.FONT, "Prototype")
    or LSM:Fetch(LSM.MediaType.FONT, LSM:GetDefault(LSM.MediaType.FONT))

-----------------------------------------------------------------------
-- Cached API
-----------------------------------------------------------------------
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local GetSpellName = GetSpellName or C_Spell.GetSpellName
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID
local GetTime = GetTime
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitPowerMax = UnitPowerMax
local UnitPower = UnitPower
local UnitPowerType = UnitPowerType
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

-----------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------
local stealthAlpha = 0.4
local shadowsightStartTime = 95
local shadowsightResetTime = 122
local shadowSightID = 34709
local feignDeathID = 5384
local FEIGN_DEATH = GetSpellName(feignDeathID)

GladiusMixin.stealthAlpha = stealthAlpha
GladiusMixin.FEIGN_DEATH = FEIGN_DEATH
GladiusMixin.feignDeathID = feignDeathID

local testActive
local masqueOn
local TestTitle

-----------------------------------------------------------------------
-- Data tables
-----------------------------------------------------------------------
GladiusMixin.healerSpecNames = {
    ["Discipline"] = true,
    ["Restoration"] = true,
    ["Mistweaver"] = true,
    ["Holy"] = true,
    ["Preservation"] = true,
}

GladiusMixin.classPowerType = {
    WARRIOR = "RAGE",
    ROGUE = "ENERGY",
    DRUID = "MANA",
    PALADIN = "MANA",
    HUNTER = "FOCUS",
    DEATHKNIGHT = "RUNIC_POWER",
    SHAMAN = "MANA",
    MAGE = "MANA",
    WARLOCK = "MANA",
    PRIEST = "MANA",
    DEMONHUNTER = "FURY",
    EVOKER = "ESSENCE",
    MONK = "ENERGY",
}

GladiusMixin.classIcons = {
    ["DRUID"]        = 625999,
    ["HUNTER"]       = 135495,
    ["MAGE"]         = 135150,
    ["MONK"]         = 626002,
    ["PALADIN"]      = 626003,
    ["PRIEST"]       = 626004,
    ["ROGUE"]        = 626005,
    ["SHAMAN"]       = 626006,
    ["WARLOCK"]      = 626007,
    ["WARRIOR"]      = 135328,
    ["DEATHKNIGHT"]  = 135771,
    ["DEMONHUNTER"]  = 1260827,
    ["EVOKER"]       = 4574311,
}

GladiusMixin.healerSpecIDs = {
    [65]   = true,   -- Holy Paladin
    [105]  = true,   -- Restoration Druid
    [256]  = true,   -- Discipline Priest
    [257]  = true,   -- Holy Priest
    [264]  = true,   -- Restoration Shaman
    [270]  = true,   -- Mistweaver Monk
    [1468] = true,   -- Preservation Evoker
}

-----------------------------------------------------------------------
-- Non-duration aura mapping (spells whose aura has no built-in timer)
-----------------------------------------------------------------------
local castToAuraMap = {
    [212182] = 212183,  -- Smoke Bomb
    [359053] = 212183,  -- Smoke Bomb (variant)
    [198838] = 201633,  -- Earthen Wall Totem
    [62618]  = 81782,   -- Power Word: Barrier
    [204336] = 8178,    -- Grounding Totem
    [443028] = 456499,  -- Celestial Conduit
    [289655] = 289655,  -- Sanctified Ground
}

GladiusMixin.nonDurationAuras = {
    [212183] = { duration = 5,  helpful = false, texture = 458733 }, -- Smoke Bomb
    [201633] = { duration = 18, helpful = true,  texture = 136098 }, -- Earthen Wall Totem
    [81782]  = { duration = 10, helpful = true,  texture = 253400 }, -- PW: Barrier
    [8178]   = { duration = 3,  helpful = true,  texture = 136039 }, -- Grounding Totem
    [456499] = { duration = 4,  helpful = true,  texture = 988197 }, -- Celestial Conduit
    [289655] = { duration = 5,  helpful = true,  texture = 237544 }, -- Sanctified Ground
}

GladiusMixin.noTrinketTexture = 638661
GladiusMixin.trinketTexture = 1322720
GladiusMixin.trinketID = 336126

-----------------------------------------------------------------------
-- Utility functions
-----------------------------------------------------------------------
function GladiusMixin:Print(fmt, ...)
    local tag = "|cffffffffGladius |cff00ff00Midnight|r:"
    print(tag, string.format(fmt, ...))
end

local function IsSoloShuffle()
    return C_PvP and C_PvP.IsSoloShuffle and C_PvP.IsSoloShuffle()
end

function GladiusMixin:FontValues()
    local result, keys = {}, {}
    for name in pairs(LSM:HashTable(LSM.MediaType.FONT)) do
        keys[#keys + 1] = name
    end
    table.sort(keys)
    for _, name in ipairs(keys) do result[name] = name end
    return result
end

function GladiusMixin:FontOutlineValues()
    return {
        [""]             = "None",
        ["OUTLINE"]      = "Normal",
        ["THICKOUTLINE"] = "Thick",
    }
end

function GladiusMixin:CheckClassStacking()
    local classCounts = {}
    local hasHealer = false
    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if f and f:IsShown() and f.class then
            classCounts[f.class] = (classCounts[f.class] or 0) + 1
            if f.isHealer then hasHealer = true end
        end
    end
    if not hasHealer then return false end
    for _, count in pairs(classCounts) do
        if count >= 2 then return true end
    end
    return false
end

local function GetFactionTrinketIconByRace(race)
    local alliance = {
        Human = true, Dwarf = true, NightElf = true, Gnome = true,
        Draenei = true, Worgen = true, Pandaren = true,
        LightforgedDraenei = true, VoidElf = true, DarkIronDwarf = true,
        KulTiran = true, Mechagnome = true, EarthenDwarf = true,
    }
    return alliance[race] and 133452 or 133453
end
GladiusMixin.GetFactionTrinketIconByRace = GetFactionTrinketIconByRace

local function FormatLargeNumber(value)
    if value >= 1000000 then
        return string.format("%.1f M", value / 1000000)
    elseif value >= 1000 then
        return string.format("%d K", value / 1000)
    end
    return tostring(value)
end
GladiusMixin.FormatLargeNumber = FormatLargeNumber

-----------------------------------------------------------------------
-- Database / settings helpers
-----------------------------------------------------------------------
function GladiusMixin:DatabaseCleanup(db)
    if not db or not db.profile then return end
    local p = db.profile
    -- Migrate old setting names
    if p.swapHumanTrinket ~= nil then
        p.swapRacialTrinket = p.swapHumanTrinket
        p.swapHumanTrinket = nil
    end
    if p.drSwipeOff ~= nil then
        p.disableDRSwipe = p.drSwipeOff
        p.drSwipeOff = nil
    end
end

function GladiusMixin:UpdateDecimalThreshold()
    decimalThreshold = self.db.profile.decimalThreshold or 6
    GladiusMixin.decimalThreshold = decimalThreshold
end

function GladiusMixin:UpdateNoTrinketTexture()
    if self.db.profile.removeUnequippedTrinketTexture then
        self.noTrinketTexture = nil
    else
        self.noTrinketTexture = 638661
    end
end

function GladiusMixin:UpdatePlayerSpec()
    local specIndex
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        specIndex = C_SpecializationInfo.GetSpecialization()
    elseif GetSpecialization then
        specIndex = GetSpecialization()
    end
    if specIndex then
        local specID, specName = GetSpecializationInfo(specIndex)
        self.playerSpecID = specID
        self.playerSpecName = specName
    end
    LibStub("AceConfigRegistry-3.0"):NotifyChange("GladiusMidnight")
end

-----------------------------------------------------------------------
-- Font management
-----------------------------------------------------------------------
local ogFonts = {}

local function captureFont(fs)
    if not fs then return nil end
    local path, size, flags = fs:GetFont()
    return { path, size, flags }
end

local function applyFont(fs, fontTbl)
    if fs and fontTbl then
        fs:SetFont(fontTbl[1], fontTbl[2], fontTbl[3])
    end
end

function GladiusMixin:UpdateFonts()
    local layoutName = self.db.profile.currentLayout
    local ls = self.db.profile.layoutSettings[layoutName]
    if not ls then return end

    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if f then
            if not ls.changeFont then
                -- Restore original fonts
                if f.ogFonts then
                    applyFont(f.Name, f.ogFonts.name)
                    applyFont(f.HealthText, f.ogFonts.health)
                    applyFont(f.SpecNameText, f.ogFonts.spec)
                    applyFont(f.PowerText, f.ogFonts.power)
                    if f.CastBar and f.CastBar.Text then
                        applyFont(f.CastBar.Text, f.ogFonts.castbar)
                    end
                    f.ogFonts = nil
                end
                self:ApplyPrototypeFont(f)
            else
                -- Save originals before first change
                if not f.ogFonts then
                    f.ogFonts = {
                        name    = captureFont(f.Name),
                        health  = captureFont(f.HealthText),
                        spec    = captureFont(f.SpecNameText),
                        power   = captureFont(f.PowerText),
                        castbar = f.CastBar and captureFont(f.CastBar.Text),
                    }
                end

                local fontPath = LSM:Fetch(LSM.MediaType.FONT, ls.fontName or "Prototype")
                local outline = ls.fontOutline or "OUTLINE"
                local size = ls.fontSize or 10

                local elements = { f.Name, f.HealthText, f.SpecNameText, f.PowerText }
                for _, el in ipairs(elements) do
                    if el then
                        el:SetFont(fontPath, size, outline)
                        if outline ~= "" then
                            el:SetShadowOffset(0, 0)
                        else
                            el:SetShadowOffset(1, -1)
                        end
                    end
                end
                if f.CastBar and f.CastBar.Text then
                    f.CastBar.Text:SetFont(fontPath, size, "OUTLINE")
                    f.CastBar.Text:SetShadowOffset(0, 0)
                end
            end
        end
    end
end

function GladiusMixin:ApplyPrototypeFont(frame)
    local layoutName = self.db.profile.currentLayout
    if layoutName ~= "Gladiuish" and layoutName ~= "Pixelated" then
        -- Restore if we changed it before
        if frame.changedFonts then
            for fs, saved in pairs(frame.changedFonts) do
                applyFont(fs, saved)
            end
            frame.changedFonts = nil
        end
        return
    end

    local pFont = self.pFont
    if not pFont then return end

    frame.changedFonts = frame.changedFonts or {}
    local targets = {
        { fs = frame.Name,         size = 11 },
        { fs = frame.SpecNameText, size = 9  },
        { fs = frame.HealthText,   size = 10 },
        { fs = frame.PowerText,    size = 10 },
    }
    for _, t in ipairs(targets) do
        if t.fs then
            if not frame.changedFonts[t.fs] then
                frame.changedFonts[t.fs] = captureFont(t.fs)
            end
            t.fs:SetFont(pFont, t.size, "OUTLINE")
            t.fs:SetShadowOffset(0, 0)
        end
    end
    if frame.CastBar and frame.CastBar.Text then
        local cb = frame.CastBar.Text
        if not frame.changedFonts[cb] then
            frame.changedFonts[cb] = captureFont(cb)
        end
        cb:SetFont(pFont, 10, "OUTLINE")
        cb:SetShadowOffset(0, 0)
    end
end

-----------------------------------------------------------------------
-- Texture management
-----------------------------------------------------------------------
function GladiusMixin:UpdateTextures()
    local layoutName = self.db.profile.currentLayout
    local ls = self.db.profile.layoutSettings[layoutName]
    if not ls or not ls.textures then return end

    local generalTex = LSM:Fetch(LSM.MediaType.STATUSBAR,
        ls.textures.generalStatusBarTexture or "Blizzard RetailBar")
    local healerTex = LSM:Fetch(LSM.MediaType.STATUSBAR,
        ls.textures.healStatusBarTexture or generalTex)
    local castTex = LSM:Fetch(LSM.MediaType.STATUSBAR,
        ls.textures.castbarStatusBarTexture or generalTex)

    local isClassStacking = self:CheckClassStacking()

    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if f then
            local usedTex = generalTex
            -- Use healer texture if applicable
            if f.isHealer then
                if ls.retextureHealerClassStackOnly then
                    if isClassStacking then usedTex = healerTex end
                else
                    usedTex = healerTex
                end
            end

            if f.HealthBar then
                f.HealthBar:SetStatusBarTexture(usedTex)
            end
            if f.PowerBar then
                f.PowerBar:SetStatusBarTexture(usedTex)
            end

            -- CastBar texture
            if f.CastBar and not ls.keepDefaultModernTextures then
                f.CastBar:SetStatusBarTexture(castTex)
            end

            -- Background
            if ls.textures.bgTexture then
                local bgTex = LSM:Fetch(LSM.MediaType.STATUSBAR, ls.textures.bgTexture)
                if f.HealthBar and f.HealthBar.hpUnderlay then
                    f.HealthBar.hpUnderlay:SetTexture(bgTex)
                    local c = ls.textures.bgColor or {0, 0, 0, 0.6}
                    f.HealthBar.hpUnderlay:SetVertexColor(c[1], c[2], c[3], c[4])
                end
            end

            -- Reverse fill
            if ls.reverseBarsFill then
                if f.HealthBar then f.HealthBar:SetReverseFill(true) end
                if f.PowerBar then f.PowerBar:SetReverseFill(true) end
            else
                if f.HealthBar then f.HealthBar:SetReverseFill(false) end
                if f.PowerBar then f.PowerBar:SetReverseFill(false) end
            end
        end
    end
end

-----------------------------------------------------------------------
-- Layout system
-----------------------------------------------------------------------
function GladiusMixin:SetLayout(_, layoutName)
    layoutName = layoutName or self.db.profile.currentLayout
    if not self.layouts[layoutName] then
        layoutName = "Gladiuish"
    end
    self.db.profile.currentLayout = layoutName

    -- Determine pixel border visibility
    self.showPixelBorder = (layoutName == "BlizzRaid" or layoutName == "Pixelated")

    -- Apply layout to each frame
    local layout = self.layouts[layoutName]
    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if f then
            f:ResetLayout()

            if layout and layout.Initialize then
                layout:Initialize(f)
            end

            -- Refresh frame state
            if f.class then
                f:UpdatePlayer()
            end

            f:UpdateFrameColors()
            self:ApplyPrototypeFont(f)
            f:UpdateClassIconCooldownReverse()
            f:UpdateTrinketRacialCooldownReverse()
            f:UpdateClassIconSwipeSettings()
            f:UpdateTrinketRacialSwipeSettings()
        end
    end

    self:UpdateTextures()
    self:UpdateFonts()
    self:ModernOrClassicCastbar()
    self:SetupCustomCD()

    -- Update config panel
    LibStub("AceConfigRegistry-3.0"):NotifyChange("GladiusMidnight")

    -- Re-run test mode if active outside arena
    if testActive then
        self:Test()
    end
end

-----------------------------------------------------------------------
-- Custom cooldown text with decimals
-----------------------------------------------------------------------
function GladiusMixin:CreateCustomCooldown(cooldown, showDecimals, isDR)
    if not cooldown then return end

    -- Create custom text overlay
    if not cooldown.gladiusText then
        local fs = cooldown:CreateFontString(nil, "OVERLAY")
        fs:SetPoint("CENTER", 0, 0)
        if cooldown.Text then
            local path, size, flags = cooldown.Text:GetFont()
            fs:SetFont(path, size, flags)
        else
            fs:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        end
        cooldown.gladiusText = fs
    end

    if isMidnight then
        -- On Midnight, always hide Blizzard countdown numbers
        cooldown:SetHideCountdownNumbers(true)
        if cooldown.Text then cooldown.Text:SetAlpha(0) end
    end

    if showDecimals then
        cooldown:SetScript("OnUpdate", function(self, elapsed)
            self._elapsed = (self._elapsed or 0) + elapsed
            if self._elapsed < 0.1 then return end
            self._elapsed = 0

            local remaining = self:GetCooldownTimes()
            if not remaining then
                self.gladiusText:SetText("")
                return
            end

            local startTime, duration = self:GetCooldownTimes()
            if not startTime or startTime == 0 then
                self.gladiusText:SetText("")
                return
            end

            local now = GetTime()
            local timeLeft = (startTime + duration) / 1000 - now
            if duration > 0 then
                timeLeft = startTime / 1000 + duration / 1000 - now
                -- GetCooldownTimes returns ms on Midnight
                if startTime > 1000000 then
                    timeLeft = (startTime + duration) / 1000 - now
                else
                    timeLeft = startTime + duration - now
                end
            end

            if timeLeft <= 0 then
                self.gladiusText:SetText("")
                return
            end

            if timeLeft < decimalThreshold then
                self.gladiusText:SetText(string.format("%.1f", timeLeft))
            elseif timeLeft < 60 then
                self.gladiusText:SetText(string.format("%d", timeLeft))
            elseif timeLeft < 3600 then
                self.gladiusText:SetText(string.format("%d:%02d", timeLeft / 60, timeLeft % 60))
            else
                self.gladiusText:SetText(string.format("%dh", timeLeft / 3600))
            end
        end)
    elseif isDR and isMidnight then
        -- Mirror Blizzard text but use our own display
        cooldown:SetScript("OnUpdate", function(self, elapsed)
            self._elapsed = (self._elapsed or 0) + elapsed
            if self._elapsed < 0.1 then return end
            self._elapsed = 0

            if self.Text and self.Text:GetText() then
                self.gladiusText:SetText(self.Text:GetText())
                self.Text:SetAlpha(0)
            else
                self.gladiusText:SetText("")
            end
        end)
    end
end

function GladiusMixin:SetupCustomCD()
    -- Skip if OmniCC is handling cooldown text
    if C_AddOns and C_AddOns.IsAddOnLoaded("OmniCC") then return end

    local db = self.db.profile
    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if f then
            -- ClassIcon cooldown
            if f.ClassIcon and f.ClassIcon.Cooldown then
                self:CreateCustomCooldown(f.ClassIcon.Cooldown, db.showDecimalsClassIcon)
            end

            -- DR frames (Midnight uses Blizzard tray, non-Midnight uses our frames)
            if isMidnight then
                if f.drFrames then
                    for _, drFrame in ipairs(f.drFrames) do
                        if drFrame.Cooldown then
                            self:CreateCustomCooldown(drFrame.Cooldown, db.showDecimalsDR, true)
                        end
                    end
                end
            else
                if f.drCategories then
                    for _, cat in ipairs(GladiusMixin.drCategories or {}) do
                        local drFrame = f[cat]
                        if drFrame and drFrame.Cooldown then
                            self:CreateCustomCooldown(drFrame.Cooldown, db.showDecimalsDR, true)
                        end
                    end
                end
            end
        end
    end
end

-----------------------------------------------------------------------
-- Dark mode helpers
-----------------------------------------------------------------------
function GladiusMixin:DarkMode()
    return self.db and self.db.profile.darkMode
end

function GladiusMixin:DarkModeColor()
    return self.db and self.db.profile.darkModeValue or 0.2
end

-----------------------------------------------------------------------
-- Widget event management
-----------------------------------------------------------------------
function GladiusMixin:RegisterWidgetEvents()
    local ls = self.db.profile.layoutSettings[self.db.profile.currentLayout]
    if not ls or not ls.widgets then return end

    local w = ls.widgets
    if w.targetIndicator and w.targetIndicator.enabled then
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
    if w.focusIndicator and w.focusIndicator.enabled then
        self:RegisterEvent("PLAYER_FOCUS_CHANGED")
    end
    if w.partyTargetIndicators and w.partyTargetIndicators.enabled then
        self:RegisterEvent("UNIT_TARGET")
    end
    if w.combatIndicator and w.combatIndicator.enabled then
        for i = 1, self.maxArenaOpponents do
            self:RegisterUnitEvent("UNIT_FLAGS", "arena" .. i)
        end
    end
end

function GladiusMixin:UnregisterWidgetEvents()
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
    self:UnregisterEvent("UNIT_TARGET")
    for i = 1, self.maxArenaOpponents do
        self:UnregisterEvent("UNIT_FLAGS")
    end
end

-----------------------------------------------------------------------
-- Drag positioning system (Shift+Ctrl+Drag)
-----------------------------------------------------------------------
function GladiusMixin:SetupDrag(clickFrame, moveFrame, settingsKey, updateFunc, isWidget)
    if not clickFrame then return end

    clickFrame:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and IsShiftKeyDown() and IsControlKeyDown() then
            if not moveFrame._isMoving then
                moveFrame._isMoving = true
                moveFrame:StartMoving()
            end
        end
    end)

    clickFrame:SetScript("OnMouseUp", function(_, button)
        if moveFrame._isMoving then
            moveFrame._isMoving = false
            moveFrame:StopMovingOrSizing()

            -- Calculate offset from parent
            local parent = moveFrame:GetParent()
            local pScale = parent:GetEffectiveScale()
            local mScale = moveFrame:GetEffectiveScale()
            local px, py = parent:GetCenter()
            local mx, my = moveFrame:GetCenter()

            local posX = math.floor(((mx * mScale - px * pScale) / pScale) * 10 + 0.5) / 10
            local posY = math.floor(((my * mScale - py * pScale) / pScale) * 10 + 0.5) / 10

            -- Store position
            local layoutName = self.db.profile.currentLayout
            if isWidget then
                local ws = self.db.profile.layoutSettings[layoutName].widgets
                if ws and ws[settingsKey] then
                    ws[settingsKey].posX = posX
                    ws[settingsKey].posY = posY
                end
            else
                local ls = self.db.profile.layoutSettings[layoutName]
                if ls[settingsKey] then
                    ls[settingsKey].posX = posX
                    ls[settingsKey].posY = posY
                elseif settingsKey == "frame" then
                    ls.posX = posX
                    ls.posY = posY
                end
            end

            -- Refresh
            if updateFunc then
                updateFunc()
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("GladiusMidnight")
        end
    end)
end

-----------------------------------------------------------------------
-- Mouse state (enable/disable interactivity)
-----------------------------------------------------------------------
function GladiusMixin:SetMouseState(enabled)
    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if f then
            if enabled then
                -- Outside arena: enable mouse on all elements
                f:EnableMouse(true)
                if f.ClassIcon then f.ClassIcon:EnableMouse(true) end
                if f.SpecIcon then f.SpecIcon:EnableMouse(true) end
                if f.Trinket then f.Trinket:EnableMouse(true) end
                if f.Racial then f.Racial:EnableMouse(true) end
                if f.Dispel then f.Dispel:EnableMouse(true) end
            else
                -- In arena: disable mouse on sub-frames
                if f.CastBar then f.CastBar:EnableMouse(false) end
            end
        end
    end
end

-----------------------------------------------------------------------
-- Hide Blizzard arena frames
-----------------------------------------------------------------------
local function HideBlizzArenaFrames(instanceType)
    if not isMidnight and not isRetail then return end
    if not CompactArenaFrame then return end

    -- Create a hidden parent to dump Blizzard frames into
    if not GladiusMixin.blizzHider then
        local hider = CreateFrame("Frame")
        hider:Hide()
        GladiusMixin.blizzHider = hider
    end

    if instanceType == "arena" then
        -- Hook CompactArenaFrame to stay hidden
        if CompactArenaFrame and not GladiusMixin._blizzHooked then
            hooksecurefunc(CompactArenaFrame, "OnShow", function(self)
                if GladiusMixin._inArena then
                    self:Hide()
                end
            end)
            GladiusMixin._blizzHooked = true
        end
    end
end

-----------------------------------------------------------------------
-- Shadowsight timer
-----------------------------------------------------------------------
function GladiusMixin:ResetShadowsightTimer()
    if self._shadowTicker then
        self._shadowTicker:Cancel()
        self._shadowTicker = nil
    end
    self.ShadowsightTimer.Text:SetText("")
    self.ShadowsightTimer:Hide()
    self.shadowsightTimers = {0, 0}
    self.shadowsightAvailable = 2
end

function GladiusMixin:StartShadowsightTimer(spawnTime)
    self.shadowsightTimers[1] = spawnTime
    self.shadowsightTimers[2] = spawnTime + 35
    self.shadowsightAvailable = 0

    -- Position below the top-center widget area
    self.ShadowsightTimer:ClearAllPoints()
    if UIWidgetTopCenterContainerFrame then
        self.ShadowsightTimer:SetPoint("TOP", UIWidgetTopCenterContainerFrame, "BOTTOM", 0, -5)
    else
        self.ShadowsightTimer:SetPoint("TOP", UIParent, "TOP", 0, -30)
    end
    self.ShadowsightTimer:Show()

    self._shadowTicker = C_Timer.NewTicker(0.1, function()
        self:UpdateShadowsightDisplay()
    end)
end

function GladiusMixin:OnShadowsightTaken()
    local now = GetTime()
    local resetTime = now + shadowsightResetTime

    if self.shadowsightTimers[1] <= 1 and self.shadowsightTimers[2] <= 1 then
        self.shadowsightTimers[1] = resetTime
        self.shadowsightTimers[2] = resetTime
    else
        self.shadowsightAvailable = math.max(0, self.shadowsightAvailable - 1)
        -- Reset whichever timer was used
        if self.shadowsightTimers[1] <= now then
            self.shadowsightTimers[1] = resetTime
        else
            self.shadowsightTimers[2] = resetTime
        end
    end

    if not self._shadowTicker then
        self:StartShadowsightTimer(resetTime)
    end
end

function GladiusMixin:UpdateShadowsightDisplay()
    local now = GetTime()
    local t1, t2 = self.shadowsightTimers[1], self.shadowsightTimers[2]
    local eyeIcon = "|TInterface\\Minimap\\TRACKING\\StealthDetect:14|t"

    -- Count available orbs
    local available = 0
    if t1 > 0 and t1 <= now then available = available + 1 end
    if t2 > 0 and t2 <= now then available = available + 1 end

    if available == 2 then
        self.ShadowsightTimer.Text:SetText(eyeIcon .. " Shadowsight Ready " .. eyeIcon)
    elseif available == 1 then
        local nextSpawn = math.max(t1, t2)
        if nextSpawn <= now then
            self.ShadowsightTimer.Text:SetText(eyeIcon .. " Shadowsight Ready " .. eyeIcon)
        else
            local remaining = math.ceil(nextSpawn - now)
            self.ShadowsightTimer.Text:SetText(
                eyeIcon .. " Shadowsight " .. eyeIcon .. "  |cffcccccc" .. remaining .. "s|r")
        end
    else
        local nextSpawn = math.min(t1, t2)
        if nextSpawn <= 1 then
            self:ResetShadowsightTimer()
            return
        end
        local remaining = math.ceil(nextSpawn - now)
        if remaining <= 0 then
            self.ShadowsightTimer.Text:SetText(eyeIcon .. " Shadowsight Ready " .. eyeIcon)
        else
            self.ShadowsightTimer.Text:SetText("Shadowsight spawns in |cffffff00" .. remaining .. "s|r")
        end
    end
end

-----------------------------------------------------------------------
-- CastBar management
-----------------------------------------------------------------------
function GladiusMixin:CastbarOnEvent(castBar)
    if not castBar or not self.db then return end
    local colors = self.db.profile.castBarColors
    if not colors then return end

    local isChanneling = castBar.channeling
    local isUninterruptible = castBar.notInterruptible

    if isUninterruptible then
        local c = colors.uninterruptable
        castBar:SetStatusBarColor(c[1], c[2], c[3], c[4])
    elseif isChanneling then
        local c = colors.channel
        castBar:SetStatusBarColor(c[1], c[2], c[3], c[4])
    else
        -- Check interrupt readiness for color
        if not GladiusMixin.interruptReady and colors.interruptNotReady then
            local c = colors.interruptNotReady
            castBar:SetStatusBarColor(c[1], c[2], c[3], c[4])
        else
            local c = colors.standard
            castBar:SetStatusBarColor(c[1], c[2], c[3], c[4])
        end
    end
end

function GladiusMixin:ModernOrClassicCastbar()
    if not self.db then return end
    local layoutName = self.db.profile.currentLayout
    local ls = self.db.profile.layoutSettings[layoutName]
    if not ls then return end

    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if f and f.CastBar then
            if isMidnight then
                local modern = ls.modernCastbar
                local simple = ls.simpleCastbar
                if self.ApplyCastbarStyle then
                    self:ApplyCastbarStyle(f, f.unit, modern, simple)
                end
            else
                if self.ApplyCastbarStyle then
                    self:ApplyCastbarStyle(f, f.unit, ls.modernCastbar, ls.simpleCastbar)
                end
            end
        end
    end
end

-----------------------------------------------------------------------
-- Masque (skinning library) support
-----------------------------------------------------------------------
function GladiusMixin:AddMasqueSupport()
    local Masque = LibStub("Masque", true)
    if not Masque then return end

    local group = Masque:Group("GladiusMidnight", "Arena Frames")
    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if f then
            if f.Trinket then
                group:AddButton(f.Trinket, {
                    Icon = f.Trinket.Texture,
                    Cooldown = f.Trinket.Cooldown,
                })
            end
            if f.Racial then
                group:AddButton(f.Racial, {
                    Icon = f.Racial.Texture,
                    Cooldown = f.Racial.Cooldown,
                })
            end
            if f.Dispel then
                group:AddButton(f.Dispel, {
                    Icon = f.Dispel.Texture,
                    Cooldown = f.Dispel.Cooldown,
                })
            end
        end
    end
    masqueOn = true
end

function GladiusMixin:SetupGrayTrinket()
    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if f then
            -- Desaturate trinket when on cooldown
            if f.Trinket and f.Trinket.Cooldown then
                f.Trinket.Cooldown:SetScript("OnCooldownDone", function()
                    if f.Trinket.Texture and self.db.profile.desaturateTrinketCD then
                        f.Trinket.Texture:SetDesaturated(false)
                    end
                end)
            end
            -- Desaturate dispel when on cooldown
            if f.Dispel and f.Dispel.Cooldown then
                f.Dispel.Cooldown:SetScript("OnCooldownDone", function()
                    if f.Dispel.Texture and self.db.profile.desaturateDispelCD then
                        f.Dispel.Texture:SetDesaturated(false)
                    end
                end)
            end
        end
    end
end

-----------------------------------------------------------------------
-- Initialize
-----------------------------------------------------------------------
function GladiusMixin:Initialize()
    if self._initialized then return end

    -- Create AceDB
    self.db = LibStub("AceDB-3.0"):New("GladiusMidnightDB", self.defaultSettings, true)

    -- Register DB callbacks
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    -- Store castbar colors for easy access
    self.castbarColors = self.db.profile.castBarColors

    -- Register config
    if self.optionsTable then
        LibStub("AceConfig-3.0"):RegisterOptionsTable("GladiusMidnight", self.optionsTable)
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("GladiusMidnight", "Gladius Midnight")
    end

    -- Slash commands
    if AceConsole then
        -- Use AceConsole mixin if available
    end
    SLASH_GLADIUSMIDNIGHT1 = "/gladius"
    SLASH_GLADIUSMIDNIGHT2 = "/gm"
    SlashCmdList["GLADIUSMIDNIGHT"] = function(msg)
        msg = strtrim(msg):lower()
        if msg == "test" or msg == "t" then
            self:Test()
        elseif msg == "hide" or msg == "h" then
            testActive = false
            for i = 1, self.maxArenaOpponents do
                local f = self["arena" .. i]
                if f then f:Hide() end
            end
            if TestTitle then TestTitle:Hide() end
        elseif msg == "" or msg == "config" or msg == "options" then
            Settings.OpenToCategory("Gladius Midnight")
        else
            self:Print("Commands: /gladius test | hide | config")
        end
    end

    -- Database cleanup & initial settings
    self:DatabaseCleanup(self.db)
    self:UpdateDecimalThreshold()
    self:UpdateNoTrinketTexture()

    -- Apply layout
    self:SetLayout(nil, self.db.profile.currentLayout)

    self._initialized = true
end

function GladiusMixin:RefreshConfig()
    self.castbarColors = self.db.profile.castBarColors
    self:SetLayout(nil, self.db.profile.currentLayout)
end

-----------------------------------------------------------------------
-- OnLoad (called by XML when main frame is created)
-----------------------------------------------------------------------
function GladiusMixin:OnLoad()
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end

-----------------------------------------------------------------------
-- Main OnEvent handler
-----------------------------------------------------------------------
function GladiusMixin:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:Initialize()

        -- Enable DR tracking on Midnight
        if isMidnight and C_CVar then
            C_CVar.SetCVar("spellDiminishPVPEnemiesEnabled", "1")
        end

        self:UpdatePlayerSpec()
        self:SetupGrayTrinket()
        self:AddMasqueSupport()

        -- Mark that we've been in the game
        C_Timer.After(3, function()
            self.beenInArena = true
        end)

        self:UnregisterEvent("PLAYER_LOGIN")

    elseif event == "PLAYER_ENTERING_WORLD" then
        local _, instanceType = IsInInstance()
        HideBlizzArenaFrames(instanceType)

        if instanceType == "arena" then
            self._inArena = true
            self:SetMouseState(false)

            -- Register arena events
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
            self:RegisterWidgetEvents()
            if self.RegisterInterruptEvents then
                self:RegisterInterruptEvents()
            end

            -- Hide test title
            if TestTitle then TestTitle:Hide() end
            testActive = false

            -- Reset frame data
            for i = 1, self.maxArenaOpponents do
                local f = self["arena" .. i]
                if f then
                    f:ResetTrinket()
                    f:ResetRacial()
                    f:ResetDispel()
                    f:ResetDR()
                    f.currentAuraSpellID = nil
                    f.currentInterruptSpellID = nil
                end
            end
        else
            self._inArena = false
            self:SetMouseState(true)

            -- Unregister arena events
            pcall(function() self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED") end)
            pcall(function() self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL") end)
            self:UnregisterWidgetEvents()
            if self.UnregisterInterruptEvents then
                self:UnregisterInterruptEvents()
            end

            self:ResetShadowsightTimer()
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:UpdatePlayerSpec()

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:HandleCombatLog()

    elseif event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        local msg = ...
        -- Detect arena start (localized patterns)
        local startPatterns = {
            "The Arena battle has begun",
            "Der Arenakampf hat begonnen",
            "Le combat d'ar\195\168ne a commenc\195\169",
            "La batalla en arena ha comenzado",
        }
        for _, pattern in ipairs(startPatterns) do
            if msg and msg:find(pattern) then
                C_Timer.After(0.5, function()
                    self:HandleArenaStart()
                end)
                -- Start shadowsight timer
                if self.db.profile.shadowSightTimer then
                    self:StartShadowsightTimer(GetTime() + shadowsightStartTime)
                end
                break
            end
        end

    elseif event == "PLAYER_TARGET_CHANGED" then
        for i = 1, self.maxArenaOpponents do
            local f = self["arena" .. i]
            if f and f:IsShown() then f:UpdateTarget(f.unit) end
        end

    elseif event == "PLAYER_FOCUS_CHANGED" then
        for i = 1, self.maxArenaOpponents do
            local f = self["arena" .. i]
            if f and f:IsShown() then f:UpdateFocus(f.unit) end
        end

    elseif event == "UNIT_TARGET" then
        for i = 1, self.maxArenaOpponents do
            local f = self["arena" .. i]
            if f and f:IsShown() then f:UpdatePartyTargets(f.unit) end
        end

    elseif event == "UNIT_FLAGS" then
        local unit = ...
        for i = 1, self.maxArenaOpponents do
            local f = self["arena" .. i]
            if f and f.unit == unit and f:IsShown() then
                f:UpdateCombatStatus(unit)
            end
        end
    end
end

-----------------------------------------------------------------------
-- Combat log routing
-----------------------------------------------------------------------
function GladiusMixin:HandleCombatLog()
    local _, combatEvent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _,
        spellID, spellName = CombatLogGetCurrentEventInfo()

    -- Match destination to arena unit
    local destFrame
    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if f and UnitGUID(f.unit) == destGUID then
            destFrame = f
            break
        end
    end

    -- Non-duration aura tracking (cast triggers a timerless aura)
    if combatEvent == "SPELL_CAST_SUCCESS" then
        local auraID = castToAuraMap[spellID]
        if auraID then
            local auraInfo = self.nonDurationAuras[auraID]
            if auraInfo then
                local now = GetTime()
                -- Apply to all matching arena frames
                for i = 1, self.maxArenaOpponents do
                    local f = self["arena" .. i]
                    if f then
                        self.activeNonDurationAuras[f.unit .. auraID] = {
                            startTime = now,
                            duration = auraInfo.duration,
                            texture = auraInfo.texture,
                            helpful = auraInfo.helpful,
                            spellID = auraID,
                        }
                        -- Schedule cleanup
                        C_Timer.After(auraInfo.duration, function()
                            self.activeNonDurationAuras[f.unit .. auraID] = nil
                            if f.FindAura then f:FindAura() end
                        end)
                    end
                end
            end
        end

        -- Shadowsight tracking
        if spellID == shadowSightID and self.db.profile.shadowSightTimer
           and not IsSoloShuffle() then
            self:OnShadowsightTaken()
        end
    end

    -- Route racial detection
    if combatEvent == "SPELL_CAST_SUCCESS" or combatEvent == "SPELL_AURA_APPLIED" then
        if destFrame and destFrame.FindRacial then
            destFrame:FindRacial(spellID)
        end
    end

    -- Route dispel detection (source is the caster)
    if combatEvent == "SPELL_CAST_SUCCESS" then
        local sourceFrame
        for i = 1, self.maxArenaOpponents do
            local f = self["arena" .. i]
            if f and UnitGUID(f.unit) == sourceGUID then
                sourceFrame = f
                break
            end
        end
        if sourceFrame and sourceFrame.FindDispel then
            sourceFrame:FindDispel(spellID)
        end
    end

    -- Route DR tracking
    if combatEvent == "SPELL_AURA_APPLIED" or combatEvent == "SPELL_AURA_REFRESH"
       or combatEvent == "SPELL_AURA_REMOVED" or combatEvent == "SPELL_AURA_BROKEN" then
        if destFrame and destFrame.FindDR then
            destFrame:FindDR(combatEvent, spellID)
        end
    end

    -- Route interrupt tracking (source is the interrupter)
    if combatEvent == "SPELL_INTERRUPT" then
        -- The interrupted target gets the lockout
        if destFrame and destFrame.FindInterrupt then
            local _, _, _, _, _, _, _, _, _, _, _, _, _, extraSpellID = CombatLogGetCurrentEventInfo()
            destFrame:FindInterrupt(combatEvent, spellID, sourceName, sourceGUID)
        end
    end
end

-----------------------------------------------------------------------
-- Arena start handling
-----------------------------------------------------------------------
function GladiusMixin:HandleArenaStart()
    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if f then
            f:UpdateVisible()
            if f:IsShown() then
                f:UpdatePlayer("seen")
            end
            -- Set stealth alpha for non-visible units
            if not UnitExists(f.unit) then
                f:SetAlpha(stealthAlpha)
            end
        end
    end
end

-----------------------------------------------------------------------
-- Test mode
-----------------------------------------------------------------------
local testPlayers = {
    { name = "Shadowblade",  specName = "Subtlety",     class = "ROGUE",       specIcon = 132320, specID = 261  },
    { name = "Ironwall",     specName = "Arms",         class = "WARRIOR",     specIcon = 132355, specID = 71   },
    { name = "Lightbringer", specName = "Holy",         class = "PALADIN",     specIcon = 135920, specID = 65   },
    { name = "Frostweaver",  specName = "Frost",        class = "MAGE",        specIcon = 135846, specID = 64   },
    { name = "Wildshot",     specName = "Marksmanship",  class = "HUNTER",      specIcon = 236179, specID = 254  },
}

-- DR test data for Midnight fake frames
local testDRData = {
    { category = "Incapacitate", icon = 136071, severity = 3 },
    { category = "Stun",         icon = 132298, severity = 1 },
    { category = "Root",         icon = 136100, severity = 2 },
    { category = "Disorient",    icon = 136183, severity = 1 },
}

-- Test castbar spells
local testCasts = {
    { name = "Polymorph",    icon = 136071, duration = 1.7, interruptible = true,  channel = false },
    { name = "Greater Heal", icon = 135915, duration = 2.5, interruptible = true,  channel = false },
    { name = "Cyclone",      icon = 136022, duration = 1.5, interruptible = false, channel = false },
}

-- Severity display text and color
local severityDisplay = {
    [1] = { text = "\194\189",  color = {0, 1, 0, 1} },     -- ½ green
    [2] = { text = "\194\188",  color = {1, 1, 0, 1} },     -- ¼ yellow
    [3] = { text = "%%",        color = {1, 0, 0, 1} },     -- % red (immune)
}

function GladiusMixin:Test()
    if InCombatLockdown() then
        self:Print("Cannot toggle test mode while in combat.")
        return
    end
    if self._inArena then
        self:Print("Cannot use test mode while in arena.")
        return
    end

    testActive = true

    -- Create title overlay
    if not TestTitle then
        TestTitle = CreateFrame("Frame", nil, self)
        TestTitle:SetSize(200, 20)
        TestTitle.text = TestTitle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        TestTitle.text:SetPoint("CENTER")
        TestTitle.text:SetText("|cff00ff00Gladius Midnight|r - Test Mode")
    end

    -- Shuffle test players
    local shuffled = {}
    for i, p in ipairs(testPlayers) do shuffled[i] = p end
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    local testUnits = self.db.profile.testUnits or self.maxArenaOpponents
    local healthPcts = { 1.0, 0.75, 0.45 }
    local db = self.db.profile
    local layoutName = db.currentLayout
    local ls = db.layoutSettings[layoutName] or {}

    for i = 1, self.maxArenaOpponents do
        local f = self["arena" .. i]
        if not f then break end

        if i <= testUnits and i <= #shuffled then
            local tp = shuffled[i]
            f:Show()
            f.class = tp.class
            f.specName = tp.specName
            f.isHealer = GladiusMixin.healerSpecNames[tp.specName] or false
            f.specID = tp.specID

            -- Name
            local displayName = db.showNames and tp.name or ("arena" .. i)
            if f.Name then
                f.Name:SetText(displayName)
                if db.classColors then
                    local cc = RAID_CLASS_COLORS[tp.class]
                    if cc then f.Name:SetTextColor(cc.r, cc.g, cc.b) end
                else
                    f.Name:SetTextColor(1, 1, 1)
                end
            end

            -- SpecNameText
            if f.SpecNameText then
                f.SpecNameText:SetText(tp.specName)
            end

            -- Health bar
            local hpPct = healthPcts[i] or 1.0
            if f.HealthBar then
                f.HealthBar:SetMinMaxValues(0, 100)
                f.HealthBar:SetValue(hpPct * 100)
                if db.classColors then
                    local cc = RAID_CLASS_COLORS[tp.class]
                    if cc then f.HealthBar:SetStatusBarColor(cc.r, cc.g, cc.b) end
                else
                    f.HealthBar:SetStatusBarColor(0, 1, 0)
                end
            end

            -- Power bar
            if f.PowerBar then
                local pwrType = GladiusMixin.classPowerType[tp.class] or "MANA"
                local pwrColor = PowerBarColor[pwrType] or {r = 0, g = 0, b = 1}
                f.PowerBar:SetMinMaxValues(0, 100)
                f.PowerBar:SetValue(100)
                f.PowerBar:SetStatusBarColor(pwrColor.r, pwrColor.g, pwrColor.b)
            end

            -- Health / Power text
            if f.HealthText then
                if ls.statusText and ls.statusText.usePercentage then
                    f.HealthText:SetText(string.format("%d%%", hpPct * 100))
                else
                    f.HealthText:SetText(FormatLargeNumber(hpPct * 500000))
                end
                f.HealthText:Show()
            end
            if f.PowerText then
                if ls.statusText and ls.statusText.usePercentage then
                    f.PowerText:SetText("100%")
                else
                    f.PowerText:SetText(FormatLargeNumber(50000))
                end
                f.PowerText:Show()
                f.PowerText:SetAlpha(db.hidePowerText and 0 or 1)
            end

            -- Class icon
            if f.ClassIcon then
                local classTexture = GladiusMixin.classIcons[tp.class]
                if not ls.hideClassIcon then
                    f.ClassIcon:Show()
                    if ls.replaceClassIcon and tp.specIcon then
                        f.ClassIcon.Texture:SetTexture(tp.specIcon)
                    elseif f.isHealer and ls.showHealerIcon then
                        f.ClassIcon.Texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                        f.ClassIcon.Texture:SetTexCoord(0.3125, 0.609375, 0.015625, 0.609375)
                    else
                        f.ClassIcon.Texture:SetTexture(classTexture)
                        f:SetTextureCrop(f.ClassIcon.Texture, ls.cropIcons, "class")
                    end

                    -- Test cooldown on class icon
                    if f.ClassIcon.Cooldown then
                        local dur = math.random(5, 35)
                        f.ClassIcon.Cooldown:SetCooldown(GetTime(), dur)
                    end
                else
                    f.ClassIcon:Hide()
                end
            end

            -- Spec icon
            if f.SpecIcon then
                if ls.replaceClassIcon or ls.hideSpecIcon then
                    f.SpecIcon:Hide()
                else
                    f.SpecIcon:Show()
                    f.SpecIcon.Texture:SetTexture(tp.specIcon)
                end
            end

            -- Trinket
            if f.Trinket then
                local trinketTex = GetFactionTrinketIconByRace("Human")
                f.Trinket.Texture:SetTexture(trinketTex)
                f.Trinket:Show()
                if f.Trinket.Cooldown then
                    if i == 2 then
                        f.Trinket.Cooldown:SetCooldown(GetTime(), math.random(15, 35))
                        if db.desaturateTrinketCD then
                            f.Trinket.Texture:SetDesaturated(true)
                        end
                    else
                        f.Trinket.Cooldown:Clear()
                        f.Trinket.Texture:SetDesaturated(false)
                    end
                end
            end

            -- Racial
            if f.Racial then
                if ls.showRacial ~= false then
                    f.Racial:Show()
                    f.Racial.Texture:SetTexture(GetSpellTexture(59752) or 136020)
                    if f.Racial.Cooldown and i == 1 then
                        f.Racial.Cooldown:SetCooldown(GetTime(), math.random(10, 30))
                    end
                else
                    f.Racial:Hide()
                end
            end

            -- Dispel
            if f.Dispel then
                if ls.showDispels ~= false and f.GetTestModeDispelData then
                    local dispelData = f:GetTestModeDispelData()
                    if dispelData then
                        f.Dispel:Show()
                        f.Dispel.Texture:SetTexture(dispelData.texture)
                        if f.Dispel.Cooldown and i == 3 then
                            f.Dispel.Cooldown:SetCooldown(GetTime(), math.random(5, 15))
                        end
                    else
                        f.Dispel:Hide()
                    end
                else
                    f.Dispel:Hide()
                end
            end

            -- DR frames (test mode)
            if isMidnight then
                -- Create fake DR frames for visual testing
                if not f.fakeDRFrames then
                    f.fakeDRFrames = {}
                end

                -- Clean old fake frames
                for _, fdr in ipairs(f.fakeDRFrames) do
                    fdr:Hide()
                end

                local drCount = math.min(#testDRData, 4)
                for d = 1, drCount do
                    local drData = testDRData[d]
                    local fdr = f.fakeDRFrames[d]
                    if not fdr then
                        fdr = CreateFrame("Frame", nil, f, "GladiusDRTemplate")
                        f.fakeDRFrames[d] = fdr
                    end

                    local drSize = (ls.dr and ls.dr.size) or 28
                    fdr:SetSize(drSize, drSize)
                    fdr.Icon:SetTexture(drData.icon)

                    -- Position relative to frame
                    fdr:ClearAllPoints()
                    local drPosX = (ls.dr and ls.dr.posX) or 0
                    local drPosY = (ls.dr and ls.dr.posY) or 0
                    local spacing = (ls.dr and ls.dr.spacing) or 6
                    local growDir = (ls.dr and ls.dr.growthDirection) or 4 -- RIGHT

                    local xOff, yOff = 0, 0
                    if growDir == 4 then      -- RIGHT
                        xOff = (d - 1) * (drSize + spacing)
                    elseif growDir == 3 then   -- LEFT
                        xOff = -(d - 1) * (drSize + spacing)
                    elseif growDir == 1 then   -- UP
                        yOff = (d - 1) * (drSize + spacing)
                    elseif growDir == 2 then   -- DOWN
                        yOff = -(d - 1) * (drSize + spacing)
                    end

                    fdr:SetPoint("TOPLEFT", f, "BOTTOMLEFT", drPosX + xOff, drPosY + yOff)
                    fdr:Show()

                    -- Set cooldown
                    if fdr.Cooldown then
                        fdr.Cooldown:SetCooldown(GetTime(), math.random(12, 25))
                    end

                    -- Severity display
                    local sev = drData.severity
                    if fdr.DRTextFrame and fdr.DRTextFrame.DRText then
                        local sevInfo = severityDisplay[sev]
                        if sevInfo then
                            fdr.DRTextFrame.DRText:SetText(sevInfo.text)
                            fdr.DRTextFrame.DRText:SetTextColor(unpack(sevInfo.color))
                        end
                    end

                    -- Border color from severity
                    if fdr.Border then
                        local sevInfo = severityDisplay[sev]
                        if sevInfo and not db.blackDRBorder then
                            fdr.Border:SetVertexColor(unpack(sevInfo.color))
                        end
                    end
                end
            else
                -- Non-Midnight: show built-in DR frames
                if f.drCategories and GladiusMixin.drCategories then
                    local cats = {"Incapacitate", "Stun", "Root", "Silence"}
                    for d, cat in ipairs(cats) do
                        local drFrame = f[cat]
                        if drFrame then
                            drFrame:Show()
                            drFrame.Icon:SetTexture(testDRData[d] and testDRData[d].icon or 136071)
                            if drFrame.Cooldown then
                                drFrame.Cooldown:SetCooldown(GetTime(), math.random(12, 25))
                            end
                        end
                    end
                end
            end

            -- CastBar test
            if f.CastBar and i <= #testCasts then
                local tc = testCasts[((i - 1) % #testCasts) + 1]
                f.CastBar:Show()
                if f.CastBar.Text then
                    f.CastBar.Text:SetText(tc.name)
                end
                if f.CastBar.Icon then
                    f.CastBar.Icon:SetTexture(tc.icon)
                end
                f.CastBar:SetMinMaxValues(0, 1)
                f.CastBar:SetValue(0.5)

                -- Apply castbar color
                self:CastbarOnEvent(f.CastBar)
            end

            -- Death icon hidden in test mode
            if f.DeathIcon then f.DeathIcon:Hide() end

            -- Frame colors
            f:UpdateFrameColors()

            -- Widget indicators (test: show target on frame 1, focus on frame 2)
            if f.WidgetOverlay then
                local wo = f.WidgetOverlay
                if wo.targetIndicator then
                    wo.targetIndicator:SetShown(i == 1)
                end
                if wo.focusIndicator then
                    wo.focusIndicator:SetShown(i == 2)
                end
                if wo.combatIndicator then
                    wo.combatIndicator:SetShown(i == 3)
                end
                if wo.partyTarget1 then wo.partyTarget1:Hide() end
                if wo.partyTarget2 then wo.partyTarget2:Hide() end
            end
        else
            f:Hide()
        end
    end

    -- Position test title
    if TestTitle then
        TestTitle:ClearAllPoints()
        local firstFrame = self["arena1"]
        if firstFrame then
            TestTitle:SetPoint("BOTTOM", firstFrame, "TOP", 0, 10)
        end
        TestTitle:Show()
    end

    -- Update textures after test setup (for healer detection)
    self:UpdateTextures()
end

-----------------------------------------------------------------------
-- End of Core.lua
-----------------------------------------------------------------------
