--[[
    Gladius Midnight - Power Module
    Displays power/resource bar (mana, rage, energy, etc.)
]]

local addonName, addon = ...
local Power = {}

-- ============================================================================
-- Module Registration
-- ============================================================================

function Power:OnRegister(core)
    self.core = core
end

function Power:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Power Bar Elements
-- ============================================================================

function Power:CreateElements(frame)
    -- Power bar
    local powerBar = CreateFrame("StatusBar", nil, frame)
    powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    powerBar:SetStatusBarColor(0, 0, 1)
    powerBar:SetMinMaxValues(0, 100)
    powerBar:SetValue(100)

    -- Background
    powerBar.bg = powerBar:CreateTexture(nil, "BACKGROUND")
    powerBar.bg:SetAllPoints()
    powerBar.bg:SetColorTexture(0.1, 0.1, 0.1, 1)

    -- Power text (optional)
    powerBar.text = powerBar:CreateFontString(nil, "OVERLAY")
    powerBar.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    powerBar.text:SetPoint("CENTER")
    powerBar.text:SetText("")

    frame.moduleFrames.power = powerBar
end

-- ============================================================================
-- Update Power Bar
-- ============================================================================

function Power:Update(frame, testData)
    local powerBar = frame.moduleFrames.power
    if not powerBar then return end

    local db = self.core.db.profile.power
    local healthDb = self.core.db.profile.health

    -- Position below health bar
    powerBar:ClearAllPoints()

    local healthBar = frame.moduleFrames.health
    if healthBar then
        powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -1)
        powerBar:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, -1)
    else
        -- Fallback if no health bar
        local leftOffset = 2
        local rightOffset = -2
        local topOffset = healthDb.height + 3

        if self.core:IsModuleEnabled("classIcon") then
            leftOffset = self.core.db.profile.classIcon.size + 4
        end
        if self.core:IsModuleEnabled("trinket") or self.core:IsModuleEnabled("racial") then
            rightOffset = -(self.core.db.profile.trinket.size + 4)
        end

        powerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", leftOffset, -topOffset)
        powerBar:SetPoint("RIGHT", frame, "RIGHT", rightOffset, 0)
    end

    powerBar:SetHeight(db.height)
    powerBar.text:SetShown(db.showText)

    if testData then
        -- Test mode
        local color = addon.Data.GetPowerColor(testData.powerType)
        powerBar:SetStatusBarColor(color.r, color.g, color.b)
        powerBar:SetMinMaxValues(0, testData.maxPower)
        powerBar:SetValue(testData.power)
        if db.showText then
            powerBar.text:SetText(testData.power)
        end
    else
        self:UpdateUnit(frame)
    end

    powerBar:Show()
end

function Power:UpdateUnit(frame)
    local powerBar = frame.moduleFrames.power
    if not powerBar then return end

    local unit = frame.unit
    if not UnitExists(unit) then return end

    local db = self.core.db.profile.power

    -- Get power values (12.0 API supports secret values)
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    local powerType = UnitPowerType(unit)

    -- StatusBar:SetValue() accepts secret values in 12.0
    powerBar:SetMinMaxValues(0, maxPower)
    powerBar:SetValue(power)

    -- For text display, use percentage (12.0 safe)
    if db.showText then
        -- Try 12.0 API first
        if UnitPowerPercent then
            local percent = UnitPowerPercent(unit)
            if percent then
                powerBar.text:SetText(math.floor(percent) .. "%")
            end
        else
            -- Fallback: Check if values are numbers (not secret)
            if type(power) == "number" and type(maxPower) == "number" and maxPower > 0 then
                local percent = math.floor((power / maxPower) * 100)
                powerBar.text:SetText(percent .. "%")
            else
                powerBar.text:SetText("")
            end
        end
    end

    -- Power type color
    local color = addon.Data.GetPowerColor(powerType)
    powerBar:SetStatusBarColor(color.r, color.g, color.b)
end

function Power:Reset(frame)
    local powerBar = frame.moduleFrames.power
    if powerBar then
        powerBar:SetMinMaxValues(0, 100)
        powerBar:SetValue(100)
        powerBar.text:SetText("")
        powerBar:SetStatusBarColor(0, 0, 1)
    end
end

-- Register module
addon.Core:RegisterModule("power", Power)
