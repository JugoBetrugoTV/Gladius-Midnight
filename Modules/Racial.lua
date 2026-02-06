--[[
    Gladius Midnight - Racial Module
    Tracks racial ability usage and cooldowns
    Updated for Midnight 12.0 API (issecretvalue)
]]

local addonName, addon = ...
local Racial = {}

-- Midnight 12.0 API helper: Check if a value is secret
local function IsSecretValue(value)
    return issecretvalue and issecretvalue(value)
end

-- Midnight 12.0 API helper: Safe table access for potentially secret keys
local function SafeTableAccess(tbl, key)
    if not tbl or not key then return nil end
    if IsSecretValue(key) then return nil end
    return tbl[key]
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
    cooldown:SetHideCountdownNumbers(true)  -- Use our own text
    -- OmniCC exclusion (ArenaCore method)
    cooldown.noCooldownCount = true
    cooldown.noOCC = true

    -- Custom cooldown text
    local cdText = container:CreateFontString(nil, "OVERLAY")
    cdText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    cdText:SetPoint("CENTER", 0, 0)
    cdText:SetTextColor(1, 1, 0)
    cdText:SetJustifyH("CENTER")
    container.cdText = cdText

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
    local classIconDb = self.core.db.profile.classIcon

    -- Size and position (below trinket if both enabled)
    container:SetSize(db.size, db.size)
    container:ClearAllPoints()

    local trinketFrame = frame.moduleFrames.trinket
    if trinketFrame and self.core:IsModuleEnabled("trinket") then
        -- Position below trinket
        container:SetPoint("TOP", trinketFrame, "BOTTOM", 0, -2)
    else
        -- Position independently - account for class icon
        if db.position == "RIGHT" then
            if classIconDb.position == "RIGHT" and self.core:IsModuleEnabled("classIcon") then
                container:SetPoint("RIGHT", frame.moduleFrames.classIcon, "LEFT", -2, 0)
            else
                container:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
            end
        else
            if classIconDb.position == "LEFT" and self.core:IsModuleEnabled("classIcon") then
                container:SetPoint("LEFT", frame.moduleFrames.classIcon, "RIGHT", 2, 0)
            else
                container:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
            end
        end
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
    else
        -- Update icon based on opponent's race
        self:UpdateRaceIcon(frame)
    end

    -- Keep current cooldown state
    container.icon:SetDesaturated(container.onCooldown)

    container:Show()
end

function Racial:UpdateRaceIcon(frame)
    local container = frame.moduleFrames.racial
    if not container then return end

    local unit = frame.unit
    local race = frame.race  -- Check if we already stored the race

    -- Try to get race from unit if it exists
    if not race and UnitExists(unit) then
        local _, raceToken = UnitRace(unit)
        if raceToken then
            race = raceToken
            frame.race = race  -- Store for later
        end
    end

    -- If we have a race, look up and display the racial icon
    if race then
        local spellID = addon.Data.RaceToRacialSpell[race]
        if spellID then
            -- Only update icon if not on cooldown (cooldown keeps the used spell icon)
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
    -- Midnight 12.0: spellID may be "secret" for arena opponents
    if not spellID then return end

    -- Midnight 12.0 API: Check for secret values using issecretvalue()
    local cooldown = SafeTableAccess(addon.Data.RacialCooldowns, spellID)
    if not cooldown then return end

    local container = frame.moduleFrames.racial
    if not container then return end

    container.spellID = spellID
    container.startTime = GetTime()
    container.duration = cooldown
    container.onCooldown = true

    -- Update icon (only if spellID is not secret)
    if not IsSecretValue(spellID) then
        local iconTexture = addon.Data.GetSpellIcon(spellID)
        if iconTexture then
            container.icon:SetTexture(iconTexture)
        end
    end

    container.cooldown:SetCooldown(container.startTime, cooldown)
    container.icon:SetDesaturated(true)

    -- Update cooldown text
    self:UpdateCooldownText(container)

    -- Also trigger trinket cooldown for certain racials
    local sharesTrinket = SafeTableAccess(addon.Data.TrinketShareRacials, spellID)
    if sharesTrinket then
        local trinketModule = self.core:GetModule("trinket")
        if trinketModule and self.core:IsModuleEnabled("trinket") then
            trinketModule:TriggerCooldown(frame, 90)
        end
    end
end

function Racial:UpdateCooldownText(container)
    if not container.onCooldown or container.startTime == 0 then
        if container.cdText then
            container.cdText:SetText("")
        end
        return
    end

    local remaining = (container.startTime + container.duration) - GetTime()

    -- Validate remaining time - racials max 3 minutes (180s)
    if remaining <= 0 or remaining > 200 then
        if container.cdText then
            container.cdText:SetText("")
        end
        -- If remaining is garbage, reset cooldown state
        if remaining > 200 then
            container.onCooldown = false
            container.startTime = 0
            container.duration = 0
            container.icon:SetDesaturated(false)
        end
        return
    end

    -- Format: show seconds if < 60, else show minutes
    if container.cdText then
        if remaining < 60 then
            container.cdText:SetText(math.ceil(remaining))
        else
            container.cdText:SetText(math.ceil(remaining / 60) .. "m")
        end
    end
end

function Racial:OnUpdate(frame)
    local container = frame.moduleFrames.racial
    if not container then return end

    -- Try to detect race if we haven't yet (after gates open)
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
            if container.cdText then
                container.cdText:SetText("")
            end
        else
            -- Update cooldown text
            self:UpdateCooldownText(container)
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
        if container.cdText then
            container.cdText:SetText("")
        end
    end
    -- Clear stored race
    frame.race = nil
end

-- Register module
addon.Core:RegisterModule("racial", Racial)
