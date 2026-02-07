--[[
    Gladius Midnight - Trinket Module
    Tracks PvP trinket usage and cooldown
    Gladius style: Shows timer text below icon in "2m'54" format
    Updated for Midnight 12.0 API
]]

local addonName, addon = ...
local Trinket = {}

-- PvP Trinket spell IDs (Patch 12.0 - 90 second cooldown)
local TRINKET_SPELLS = {
    [336126] = 90,    -- Gladiator's Medallion
    [336135] = 90,    -- Adaptation
    [363117] = 90,    -- Gladiator's Medallion (DF/TWW)
    [370613] = 90,    -- Precognition Immunity
    [208683] = 90,    -- Gladiator's Medallion (SL)
    [195710] = 90,    -- Honorable Medallion
    [42292] = 90,     -- PvP Trinket (generic)
    [59752] = 90,     -- Every Man for Himself (Human)
    [7744] = 30,      -- Will of the Forsaken (Undead)
}

-- Format cooldown as "2m'54" or "54" style
local function FormatCooldownText(seconds)
    if seconds <= 0 then return "" end
    if seconds >= 60 then
        local mins = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)
        return string.format("%dm'%02d", mins, secs)
    else
        return tostring(math.floor(seconds))
    end
end

-- ============================================================================
-- Module Registration
-- ============================================================================

function Trinket:OnRegister(core)
    self.core = core
end

function Trinket:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Trinket Elements
-- ============================================================================

function Trinket:CreateElements(frame)
    -- Trinket container
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
    icon:SetTexture(addon.Data.TrinketIcon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown overlay
    local cooldown = CreateFrame("Cooldown", nil, container, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetDrawSwipe(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(true)
    cooldown.noCooldownCount = true
    cooldown.noOCC = true

    -- Timer text BELOW icon (Gladius style: "2m'54")
    local timerText = container:CreateFontString(nil, "OVERLAY")
    timerText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    timerText:SetPoint("TOP", container, "BOTTOM", 0, -1)
    timerText:SetTextColor(1, 0.82, 0)  -- Gold color
    timerText:SetJustifyH("CENTER")
    container.timerText = timerText

    container.icon = icon
    container.cooldown = cooldown

    -- Tracking data
    container.startTime = 0
    container.duration = 0
    container.onCooldown = false

    frame.moduleFrames.trinket = container
end

-- ============================================================================
-- Update Trinket Display
-- ============================================================================

function Trinket:Update(frame, testData)
    local container = frame.moduleFrames.trinket
    if not container then return end

    local db = self.core.db.profile.trinket

    -- Size and position (RIGHT side of frame, stacked vertically)
    container:SetSize(db.size, db.size)
    container:ClearAllPoints()
    container:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)

    -- Reset icon
    container.icon:SetTexture(addon.Data.TrinketIcon)
    container.icon:SetDesaturated(container.onCooldown)

    -- Test mode timer
    if testData then
        container.timerText:SetText("2m'54")
    end

    container:Show()
end

function Trinket:OnSpellCast(frame, spellID)
    if not spellID then return end
    if issecretvalue and issecretvalue(spellID) then return end

    local cooldownDuration = TRINKET_SPELLS[spellID]
    if cooldownDuration then
        local iconTexture = addon.Data.GetSpellIcon(spellID)
        if iconTexture then
            local container = frame.moduleFrames.trinket
            if container then
                container.icon:SetTexture(iconTexture)
            end
        end
        self:TriggerCooldown(frame, cooldownDuration)
        return
    end

    if addon.Data.TrinketShareRacials then
        local isTrinketRacial = addon.Data.TrinketShareRacials[spellID]
        if isTrinketRacial then
            self:TriggerCooldown(frame, 90)
        end
    end
end

function Trinket:TriggerCooldown(frame, duration)
    local container = frame.moduleFrames.trinket
    if not container then return end

    if duration > 180 or duration <= 0 then
        duration = 90
    end

    container.startTime = GetTime()
    container.duration = duration
    container.onCooldown = true

    container.cooldown:SetCooldown(container.startTime, duration)
    container.icon:SetDesaturated(true)

    self:UpdateTimerText(container)
end

function Trinket:UpdateTimerText(container)
    if not container.onCooldown or container.startTime == 0 then
        container.timerText:SetText("")
        return
    end

    local remaining = (container.startTime + container.duration) - GetTime()

    if remaining <= 0 or remaining > 180 then
        container.timerText:SetText("")
        if remaining > 180 then
            container.onCooldown = false
            container.startTime = 0
            container.duration = 0
            container.icon:SetDesaturated(false)
        end
        return
    end

    container.timerText:SetText(FormatCooldownText(remaining))
end

function Trinket:OnUpdate(frame)
    local container = frame.moduleFrames.trinket
    if not container then return end

    local now = GetTime()

    -- Check Blizzard API for trinket cooldown
    if C_PvP and C_PvP.GetArenaCrowdControlInfo and UnitExists(frame.unit) then
        local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(frame.unit)

        if spellID and startTime and duration then
            local isSecret = issecretvalue and (issecretvalue(startTime) or issecretvalue(duration))

            if not isSecret then
                local isValid = duration > 0 and duration <= 180 and startTime > 0 and (now - startTime) < 300
                if isValid then
                    local isNewData = startTime ~= container.startTime or duration ~= container.duration
                    if isNewData then
                        container.startTime = startTime
                        container.duration = duration
                        container.onCooldown = true
                        container.cooldown:SetCooldown(startTime, duration)
                        container.icon:SetDesaturated(true)

                        if not (issecretvalue and issecretvalue(spellID)) then
                            local iconTexture = addon.Data.GetSpellIcon(spellID)
                            if iconTexture then
                                container.icon:SetTexture(iconTexture)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Check if cooldown expired
    if container.onCooldown and container.startTime > 0 and container.duration > 0 then
        local elapsed = now - container.startTime
        if elapsed >= container.duration or elapsed < 0 then
            container.onCooldown = false
            container.icon:SetDesaturated(false)
            container.startTime = 0
            container.duration = 0
            container.timerText:SetText("")
            container.icon:SetTexture(addon.Data.TrinketIcon)
        else
            self:UpdateTimerText(container)
        end
    end
end

function Trinket:Reset(frame)
    local container = frame.moduleFrames.trinket
    if container then
        container.startTime = 0
        container.duration = 0
        container.onCooldown = false
        container.cooldown:Clear()
        container.icon:SetDesaturated(false)
        container.icon:SetTexture(addon.Data.TrinketIcon)
        container.timerText:SetText("")
    end
end

function Trinket:OnBlizzardTrinketCooldown(frame, start, duration)
    if self.core.testMode then return end

    local container = frame.moduleFrames.trinket
    if not container then return end

    if not start or not duration then return end

    local isSecret = issecretvalue and (issecretvalue(start) or issecretvalue(duration))

    if isSecret then
        container.cooldown:SetCooldown(start, duration)
        container.onCooldown = true
        container.icon:SetDesaturated(true)
    else
        local isValid = start > 0 and duration > 0 and duration <= 180
        if not isValid then return end

        local isNewData = start ~= container.startTime or duration ~= container.duration
        if isNewData then
            container.startTime = start
            container.duration = duration
            container.onCooldown = true
            container.cooldown:SetCooldown(start, duration)
            container.icon:SetDesaturated(true)
            self:UpdateTimerText(container)
        end
    end
end

-- Register module
addon.Core:RegisterModule("trinket", Trinket)
