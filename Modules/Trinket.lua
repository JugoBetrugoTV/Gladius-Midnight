--[[
    Gladius Midnight - Trinket Module
    Tracks PvP trinket usage and cooldown
]]

local addonName, addon = ...
local Trinket = {}

-- PvP Trinket spell IDs (Patch 12.0 Midnight - 90 second cooldown)
local TRINKET_SPELLS = {
    -- Current (Midnight 12.0) - 90 second cooldown
    [336126] = 90,    -- Gladiator's Medallion
    [336135] = 90,    -- Adaptation
    [363117] = 90,    -- Gladiator's Medallion (DF/TWW)
    [370613] = 90,    -- Precognition Immunity
    [208683] = 90,    -- Gladiator's Medallion (SL)
    [195710] = 90,    -- Honorable Medallion
    [42292] = 90,     -- PvP Trinket (generic)

    -- Racial CC-breaks (also trigger trinket CD)
    [59752] = 90,     -- Every Man for Himself (Human) - shares CD
    [7744] = 30,      -- Will of the Forsaken (Undead) - own CD
}

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
    cooldown:SetHideCountdownNumbers(true)  -- Hide default numbers, use our own
    -- OmniCC exclusion (ArenaCore method - prevents OmniCC from overriding our display)
    cooldown.noCooldownCount = true
    cooldown.noOCC = true

    -- Custom cooldown text (more reliable than built-in)
    local cdText = container:CreateFontString(nil, "OVERLAY")
    cdText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    cdText:SetPoint("CENTER", 0, 0)
    cdText:SetTextColor(1, 1, 0)  -- Yellow for better visibility
    cdText:SetJustifyH("CENTER")
    container.cdText = cdText

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
    local classIconDb = self.core.db.profile.classIcon

    -- Size and position
    container:SetSize(db.size, db.size)
    container:ClearAllPoints()

    if db.position == "RIGHT" then
        -- Check if class icon is also on RIGHT
        if classIconDb.position == "RIGHT" and self.core:IsModuleEnabled("classIcon") then
            container:SetPoint("RIGHT", frame.moduleFrames.classIcon, "LEFT", -2, 0)
        else
            container:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
        end
    else
        -- Check if class icon is also on LEFT
        if classIconDb.position == "LEFT" and self.core:IsModuleEnabled("classIcon") then
            container:SetPoint("LEFT", frame.moduleFrames.classIcon, "RIGHT", 2, 0)
        else
            container:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        end
    end

    -- Reset icon
    container.icon:SetTexture(addon.Data.TrinketIcon)
    container.icon:SetDesaturated(container.onCooldown)

    container:Show()
end

function Trinket:OnSpellCast(frame, spellID)
    -- In Midnight 12.0, spellID may be "secret" for arena opponents
    if not spellID then return end

    -- Use pcall for table access to handle secret values
    local success, cooldownDuration = pcall(function()
        return TRINKET_SPELLS[spellID]
    end)
    if success and cooldownDuration then
        -- Update icon to match the spell used
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

    -- Fallback: Check Data.lua trinket-sharing racials
    local fallbackSuccess, isTrinketRacial = pcall(function()
        return addon.Data.TrinketShareRacials[spellID]
    end)
    if fallbackSuccess and isTrinketRacial then
        self:TriggerCooldown(frame, 90)
    end
end

function Trinket:TriggerCooldown(frame, duration)
    local container = frame.moduleFrames.trinket
    if not container then return end

    -- Validate duration (trinkets are 90s in Patch 12.0)
    if duration > 180 or duration <= 0 then
        duration = 90  -- Default to 90 seconds (Patch 12.0)
    end

    container.startTime = GetTime()
    container.duration = duration
    container.onCooldown = true

    container.cooldown:SetCooldown(container.startTime, duration)
    container.icon:SetDesaturated(true)

    -- Update custom text
    self:UpdateCooldownText(container)
end

function Trinket:UpdateCooldownText(container)
    if not container.onCooldown or container.startTime == 0 then
        container.cdText:SetText("")
        return
    end

    local remaining = (container.startTime + container.duration) - GetTime()

    -- Validate remaining time - trinkets max 2 minutes (120s)
    if remaining <= 0 or remaining > 180 then
        container.cdText:SetText("")
        -- If remaining is invalid/garbage, reset cooldown state
        if remaining > 180 then
            container.onCooldown = false
            container.startTime = 0
            container.duration = 0
            container.icon:SetDesaturated(false)
        end
        return
    end

    -- Format: show seconds if < 60, else show minutes
    if remaining < 60 then
        container.cdText:SetText(math.ceil(remaining))
    else
        container.cdText:SetText(math.ceil(remaining / 60) .. "m")
    end
end

function Trinket:OnUpdate(frame)
    local container = frame.moduleFrames.trinket
    if not container then return end

    local now = GetTime()

    -- Check C_PvP API for trinket cooldown (12.0)
    -- This API returns CC break ability info for arena opponents
    if C_PvP and C_PvP.GetArenaCrowdControlInfo and UnitExists(frame.unit) then
        local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(frame.unit)

        -- In Midnight 12.0, values may be "secret" - use pcall for comparisons
        if spellID and startTime and duration then
            local validateSuccess, isValid = pcall(function()
                return duration > 0 and duration <= 180 and startTime > 0 and (now - startTime) < 300
            end)

            if validateSuccess and isValid then
                -- Check if this is new cooldown data
                local checkSuccess, isNewData = pcall(function()
                    return startTime ~= container.startTime or duration ~= container.duration
                end)
                if checkSuccess and isNewData then
                    container.startTime = startTime
                    container.duration = duration
                    container.onCooldown = true
                    container.cooldown:SetCooldown(startTime, duration)
                    container.icon:SetDesaturated(true)

                    -- Update icon to match the spell used
                    local iconTexture = addon.Data.GetSpellIcon(spellID)
                    if iconTexture then
                        container.icon:SetTexture(iconTexture)
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
            container.cdText:SetText("")
            -- Reset to default trinket icon
            container.icon:SetTexture(addon.Data.TrinketIcon)
        else
            -- Update cooldown text
            self:UpdateCooldownText(container)
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
        container.cdText:SetText("")
    end
end

-- ============================================================================
-- Blizzard CcRemoverFrame Hook (Midnight 12.0)
-- This is called when Blizzard updates trinket cooldown for arena opponents
-- ============================================================================

function Trinket:OnBlizzardTrinketCooldown(frame, start, duration)
    if self.core.testMode then return end

    local container = frame.moduleFrames.trinket
    if not container then return end

    -- In Midnight 12.0, start/duration may be "secret" values
    -- Use pcall for comparisons to handle secret values safely
    if not start or not duration then return end

    local validateSuccess, isValid = pcall(function()
        return start > 0 and duration > 0 and duration <= 180
    end)
    if not validateSuccess or not isValid then return end

    -- Only update if this is new data
    local checkSuccess, isNewData = pcall(function()
        return start ~= container.startTime or duration ~= container.duration
    end)
    if checkSuccess and isNewData then
        container.startTime = start
        container.duration = duration
        container.onCooldown = true
        container.cooldown:SetCooldown(start, duration)
        container.icon:SetDesaturated(true)
        self:UpdateCooldownText(container)
    end
end

-- Register module
addon.Core:RegisterModule("trinket", Trinket)
