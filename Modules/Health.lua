--[[
    Gladius Midnight - Health Module
    Displays health bar with class-colored background
]]

local addonName, addon = ...
local Health = {}

-- ============================================================================
-- Module Registration
-- ============================================================================

function Health:OnRegister(core)
    self.core = core
end

function Health:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Health Bar Elements
-- ============================================================================

function Health:CreateElements(frame)
    local db = self.core.db.profile

    -- Health bar
    local healthBar = CreateFrame("StatusBar", nil, frame)
    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    healthBar:SetStatusBarColor(0, 1, 0)
    healthBar:SetMinMaxValues(0, 100)
    healthBar:SetValue(100)

    -- Background
    healthBar.bg = healthBar:CreateTexture(nil, "BACKGROUND")
    healthBar.bg:SetAllPoints()
    healthBar.bg:SetColorTexture(0.15, 0.15, 0.15, 1)

    -- Health text
    healthBar.text = healthBar:CreateFontString(nil, "OVERLAY")
    healthBar.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    healthBar.text:SetPoint("CENTER")
    healthBar.text:SetText("100%")

    frame.moduleFrames.health = healthBar
end

-- ============================================================================
-- Update Health Bar
-- ============================================================================

function Health:Update(frame, testData)
    local healthBar = frame.moduleFrames.health
    if not healthBar then return end

    local db = self.core.db.profile.health

    -- Position health bar
    healthBar:ClearAllPoints()

    -- Calculate position based on other modules
    local leftOffset = 2
    local rightOffset = -2

    -- Account for class icon
    if self.core:IsModuleEnabled("classIcon") then
        leftOffset = self.core.db.profile.classIcon.size + 4
    end

    -- Account for trinket/racial
    if self.core:IsModuleEnabled("trinket") or self.core:IsModuleEnabled("racial") then
        rightOffset = -(self.core.db.profile.trinket.size + 4)
    end

    healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", leftOffset, -2)
    healthBar:SetPoint("RIGHT", frame, "RIGHT", rightOffset, 0)
    healthBar:SetHeight(db.height)

    -- Show/hide text
    healthBar.text:SetShown(db.showText)

    if testData then
        -- Test mode
        local color = addon.Data.GetClassColor(testData.class)
        if db.colorByClass then
            healthBar:SetStatusBarColor(color.r, color.g, color.b)
        else
            healthBar:SetStatusBarColor(0, 1, 0)
        end
        healthBar:SetMinMaxValues(0, testData.maxHealth)
        healthBar:SetValue(testData.health)
        healthBar.text:SetText(testData.health .. "%")
    else
        self:UpdateUnit(frame)
    end

    healthBar:Show()
end

function Health:UpdateUnit(frame)
    local healthBar = frame.moduleFrames.health
    if not healthBar then return end

    local unit = frame.unit
    if not UnitExists(unit) then return end

    local db = self.core.db.profile.health

    -- Get health values (12.0 API supports secret values)
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)

    -- StatusBar:SetValue() accepts secret values in 12.0
    healthBar:SetMinMaxValues(0, maxHealth)
    healthBar:SetValue(health)

    -- For text display, use percentage API (12.0 safe)
    if db.showText then
        -- Try 12.0 API first (returns actual percentage, not secret)
        if UnitHealthPercent then
            local percent = UnitHealthPercent(unit)
            if percent then
                healthBar.text:SetText(math.floor(percent) .. "%")
            end
        else
            -- Fallback: Check if values are numbers (not secret)
            if type(health) == "number" and type(maxHealth) == "number" and maxHealth > 0 then
                local percent = math.floor((health / maxHealth) * 100)
                healthBar.text:SetText(percent .. "%")
            else
                healthBar.text:SetText("")
            end
        end
    end

    -- Class color (use stored class from frame or UnitClass)
    if db.colorByClass then
        local class = frame.class
        if not class and UnitExists(unit) then
            local _, classFile = UnitClass(unit)
            class = classFile
        end
        if class then
            local color = addon.Data.GetClassColor(class)
            healthBar:SetStatusBarColor(color.r, color.g, color.b)
        end
    end
end

function Health:Reset(frame)
    local healthBar = frame.moduleFrames.health
    if healthBar then
        healthBar:SetMinMaxValues(0, 100)
        healthBar:SetValue(100)
        healthBar.text:SetText("100%")
        healthBar:SetStatusBarColor(0, 1, 0)
    end
end

-- Register module
addon.Core:RegisterModule("health", Health)
