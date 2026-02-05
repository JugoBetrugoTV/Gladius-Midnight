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

    -- Player name text (left side)
    healthBar.nameText = healthBar:CreateFontString(nil, "OVERLAY")
    healthBar.nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    healthBar.nameText:SetPoint("LEFT", 4, 0)
    healthBar.nameText:SetJustifyH("LEFT")
    healthBar.nameText:SetText("")

    -- Health percentage text (right side)
    healthBar.text = healthBar:CreateFontString(nil, "OVERLAY")
    healthBar.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    healthBar.text:SetPoint("RIGHT", -4, 0)
    healthBar.text:SetJustifyH("RIGHT")
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

    -- Show/hide name
    healthBar.nameText:SetShown(db.showName)

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
        -- Test names
        local testNames = {"Survivable", "Patymorph", "Easymodex", "Gladiator", "Shadowstep"}
        healthBar.nameText:SetText(testNames[frame.index] or "Player")
    else
        self:UpdateUnit(frame)
    end

    healthBar:Show()
end

function Health:UpdateUnit(frame)
    local healthBar = frame.moduleFrames.health
    if not healthBar then return end

    local unit = frame.unit
    local db = self.core.db.profile.health

    -- During prep phase, unit doesn't exist yet - show full health with class color
    if not UnitExists(unit) then
        healthBar:SetMinMaxValues(0, 100)
        healthBar:SetValue(100)
        if db.showText then
            healthBar.text:SetText("100%")
        end
        -- Clear name during prep (we don't know it yet)
        healthBar.nameText:SetText("")

        -- Apply class color if we have it from prep phase
        if db.colorByClass and frame.class then
            local color = addon.Data.GetClassColor(frame.class)
            healthBar:SetStatusBarColor(color.r, color.g, color.b)
        else
            healthBar:SetStatusBarColor(0, 1, 0)
        end
        return
    end

    -- Update player name
    if db.showName then
        local name = UnitName(unit)
        if name then
            healthBar.nameText:SetText(name)
        end
    end

    -- Get health values (12.0 API supports secret values)
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)

    -- StatusBar:SetValue() accepts secret values in 12.0
    healthBar:SetMinMaxValues(0, maxHealth)
    healthBar:SetValue(health)

    -- For text display, use percentage API (12.0 safe)
    if db.showText then
        -- WoW 12.0 API: UnitHealthPercent with CurveConstants.ScaleTo100 for proper display
        if UnitHealthPercent then
            -- Use CurveConstants.ScaleTo100 for proper percentage scaling (ArenaCore method)
            local success, percent = pcall(function()
                if CurveConstants and CurveConstants.ScaleTo100 then
                    return UnitHealthPercent(unit, nil, CurveConstants.ScaleTo100)
                else
                    return UnitHealthPercent(unit)
                end
            end)

            if success and percent and type(percent) == "number" then
                healthBar.text:SetFormattedText("%d%%", math.floor(percent))
            else
                -- Fallback if API call failed
                healthBar.text:SetText("100%")
            end
        else
            -- Pre-12.0 fallback: Check if values are numbers (not secret)
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
        if not class then
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
        healthBar.nameText:SetText("")
        healthBar:SetStatusBarColor(0, 1, 0)
    end
end

-- Register module
addon.Core:RegisterModule("health", Health)
