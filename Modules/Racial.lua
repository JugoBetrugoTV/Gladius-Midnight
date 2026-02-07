--[[
    Gladius Midnight - Racial Module
    Tracks racial ability usage and cooldowns
    Gladius style: Shows timer text below icon in "2m 54" format
    Updated for Midnight 12.0 API
]]

local addonName, addon = ...
local Racial = {}

-- Midnight 12.0 API helpers
local function IsSecretValue(value)
    return issecretvalue and issecretvalue(value)
end

local function SafeTableAccess(tbl, key)
    if not tbl or not key then return nil end
    if IsSecretValue(key) then return nil end
    return tbl[key]
end

-- Format cooldown as "2m 54" or "54" style (space instead of apostrophe for racial)
local function FormatCooldownText(seconds)
    if seconds <= 0 then return "" end
    if seconds >= 60 then
        local mins = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)
        return string.format("%dm %02d", mins, secs)
    else
        return tostring(math.floor(seconds))
    end
end

-- ============================================================================
-- Module Registration
-- ============================================================================

function Racial:OnRegister(core)
    self.core = core
end

function Racial:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Racial Elements
-- ============================================================================

function Racial:CreateElements(frame)
    -- Racial container
    local container = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0, 0, 0, 0.8)
    container:SetBackdropBorderColor(0, 0, 0, 1)

    -- Icon
    local icon = container:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown overlay
    local cooldown = CreateFrame("Cooldown", nil, container, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetDrawSwipe(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(true)
    cooldown.noCooldownCount = true
    cooldown.noOCC = true

    -- Timer text BELOW icon (Gladius style: "2m 54")
    local timerText = container:CreateFontString(nil, "OVERLAY")
    timerText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    timerText:SetPoint("TOP", container, "BOTTOM", 0, -1)
    timerText:SetTextColor(1, 0.82, 0)  -- Gold color
    timerText:SetJustifyH("CENTER")
    container.timerText = timerText

    container.icon = icon
    container.cooldown = cooldown

    -- Tracking data
    container.spellID = nil
    container.startTime = 0
    container.duration = 0
    container.onCooldown = false

    frame.moduleFrames.racial = container
end

-- ============================================================================
-- Update Racial Display
-- ============================================================================

function Racial:Update(frame, testData)
    local container = frame.moduleFrames.racial
    if not container then return end

    local db = self.core.db.profile.racial
    local trinketDb = self.core.db.profile.trinket

    -- Size and position (RIGHT side, BELOW trinket)
    container:SetSize(db.size, db.size)
    container:ClearAllPoints()

    local trinketFrame = frame.moduleFrames.trinket
    if trinketFrame and self.core:IsModuleEnabled("trinket") then
        container:SetPoint("TOPRIGHT", trinketFrame, "BOTTOMRIGHT", 0, -2)
    else
        container:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    end

    if testData then
        -- Test mode - show a random racial icon
        local races = {"Human", "Orc", "NightElf", "Tauren", "Dwarf", "Troll"}
        local testRace = races[math.random(1, #races)]
        local spellID = addon.Data.RaceToRacialSpell[testRace]
        if spellID then
            local iconTexture = addon.Data.GetSpellIcon(spellID)
            if iconTexture then
                container.icon:SetTexture(iconTexture)
            end
        end
        container.timerText:SetText("2m 54")
    else
        self:UpdateRaceIcon(frame)
    end

    container.icon:SetDesaturated(container.onCooldown)
    container:Show()
end

function Racial:UpdateRaceIcon(frame)
    local container = frame.moduleFrames.racial
    if not container then return end

    local unit = frame.unit
    local race = frame.race

    if not race and UnitExists(unit) then
        local _, raceToken = UnitRace(unit)
        if raceToken then
            race = raceToken
            frame.race = race
        end
    end

    if race then
        local spellID = addon.Data.RaceToRacialSpell[race]
        if spellID then
            if not container.onCooldown then
                local iconTexture = addon.Data.GetSpellIcon(spellID)
                if iconTexture then
                    container.icon:SetTexture(iconTexture)
                end
            end
            container.racialSpellID = spellID
        end
    end
end

function Racial:OnSpellCast(frame, spellID)
    if not spellID then return end
    if IsSecretValue(spellID) then return end

    local cooldown = SafeTableAccess(addon.Data.RacialCooldowns, spellID)
    if not cooldown then return end

    local container = frame.moduleFrames.racial
    if not container then return end

    container.spellID = spellID
    container.startTime = GetTime()
    container.duration = cooldown
    container.onCooldown = true

    local iconTexture = addon.Data.GetSpellIcon(spellID)
    if iconTexture then
        container.icon:SetTexture(iconTexture)
    end

    container.cooldown:SetCooldown(container.startTime, cooldown)
    container.icon:SetDesaturated(true)

    self:UpdateTimerText(container)

    local sharesTrinket = SafeTableAccess(addon.Data.TrinketShareRacials, spellID)
    if sharesTrinket then
        local trinketModule = self.core:GetModule("trinket")
        if trinketModule and self.core:IsModuleEnabled("trinket") then
            trinketModule:TriggerCooldown(frame, 90)
        end
    end
end

function Racial:UpdateTimerText(container)
    if not container.onCooldown or container.startTime == 0 then
        container.timerText:SetText("")
        return
    end

    local remaining = (container.startTime + container.duration) - GetTime()

    if remaining <= 0 or remaining > 200 then
        container.timerText:SetText("")
        if remaining > 200 then
            container.onCooldown = false
            container.startTime = 0
            container.duration = 0
            container.icon:SetDesaturated(false)
        end
        return
    end

    container.timerText:SetText(FormatCooldownText(remaining))
end

function Racial:OnUpdate(frame)
    local container = frame.moduleFrames.racial
    if not container then return end

    -- Try to detect race if we haven't yet
    if not frame.race and UnitExists(frame.unit) then
        self:UpdateRaceIcon(frame)
    end

    -- Check if cooldown expired
    if container.onCooldown and container.startTime > 0 and container.duration > 0 then
        local elapsed = GetTime() - container.startTime
        if elapsed >= container.duration then
            container.onCooldown = false
            container.icon:SetDesaturated(false)
            container.startTime = 0
            container.duration = 0
            container.timerText:SetText("")
        else
            self:UpdateTimerText(container)
        end
    end
end

function Racial:Reset(frame)
    local container = frame.moduleFrames.racial
    if container then
        container.spellID = nil
        container.racialSpellID = nil
        container.startTime = 0
        container.duration = 0
        container.onCooldown = false
        container.cooldown:Clear()
        container.icon:SetDesaturated(false)
        container.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        container.timerText:SetText("")
    end
    frame.race = nil
end

-- Register module
addon.Core:RegisterModule("racial", Racial)
