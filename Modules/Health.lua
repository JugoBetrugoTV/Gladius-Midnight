--[[
    Gladius Midnight - Health Module
    Displays health bar with Gladius Classic style layout:
    - Line 1: Name (arena1) + Health % (100.0%)
    - Line 2: Spec name (Frost Mage) + Health values (300.0k/300.0k)
    - Green health bar fills the area
    Updated for Midnight 12.0 API (secret values)
]]

local addonName, addon = ...
local Health = {}

-- Format large numbers (300000 -> 300.0k)
local function FormatNumber(num)
    if not num or num == 0 then return "0" end
    if num >= 1000000 then
        return string.format("%.1fm", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fk", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

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
-- Create Health Bar Elements (Gladius Classic Layout)
-- ============================================================================

function Health:CreateElements(frame)
    local db = self.core.db.profile

    -- Health bar container
    local healthBar = CreateFrame("StatusBar", nil, frame)
    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    healthBar:SetStatusBarColor(0, 1, 0)
    healthBar:SetMinMaxValues(0, 100)
    healthBar:SetValue(100)

    -- Background (darker)
    healthBar.bg = healthBar:CreateTexture(nil, "BACKGROUND")
    healthBar.bg:SetAllPoints()
    healthBar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    -- Line 1: Name text (left) - "arena1"
    healthBar.nameText = healthBar:CreateFontString(nil, "OVERLAY")
    healthBar.nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    healthBar.nameText:SetPoint("TOPLEFT", 4, -2)
    healthBar.nameText:SetJustifyH("LEFT")
    healthBar.nameText:SetTextColor(1, 1, 1)
    healthBar.nameText:SetText("")

    -- Line 1: Health percentage (right) - "100.0%"
    healthBar.percentText = healthBar:CreateFontString(nil, "OVERLAY")
    healthBar.percentText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    healthBar.percentText:SetPoint("TOPRIGHT", -4, -2)
    healthBar.percentText:SetJustifyH("RIGHT")
    healthBar.percentText:SetTextColor(1, 1, 1)
    healthBar.percentText:SetText("100.0%")

    -- Line 2: Spec name (left) - "Frost Mage"
    healthBar.specText = healthBar:CreateFontString(nil, "OVERLAY")
    healthBar.specText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    healthBar.specText:SetPoint("BOTTOMLEFT", 4, 2)
    healthBar.specText:SetJustifyH("LEFT")
    healthBar.specText:SetTextColor(0.8, 0.8, 0.8)
    healthBar.specText:SetText("")

    -- Line 2: Health values (right) - "300.0k/300.0k"
    healthBar.healthText = healthBar:CreateFontString(nil, "OVERLAY")
    healthBar.healthText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    healthBar.healthText:SetPoint("BOTTOMRIGHT", -4, 2)
    healthBar.healthText:SetJustifyH("RIGHT")
    healthBar.healthText:SetTextColor(0.8, 0.8, 0.8)
    healthBar.healthText:SetText("")

    frame.moduleFrames.health = healthBar
end

-- ============================================================================
-- Update Health Bar
-- ============================================================================

function Health:Update(frame, testData)
    local healthBar = frame.moduleFrames.health
    if not healthBar then return end

    local db = self.core.db.profile.health
    local mirrored = self.core.db.profile.mirrored

    -- Position health bar (accounts for class icon and trinket/racial positioning)
    healthBar:ClearAllPoints()

    local classIconOffset = 0
    local trinketOffset = 0

    -- Calculate offsets for class icon
    if self.core:IsModuleEnabled("classIcon") then
        classIconOffset = self.core.db.profile.classIcon.size + 4
    end

    -- Calculate offset for trinket + racial
    local rightIcons = 0
    if self.core:IsModuleEnabled("trinket") then
        rightIcons = rightIcons + 1
    end
    if self.core:IsModuleEnabled("racial") then
        rightIcons = rightIcons + 1
    end
    if rightIcons > 0 then
        trinketOffset = self.core.db.profile.trinket.size * rightIcons + (rightIcons * 2) + 4
    end

    if mirrored then
        -- Mirrored layout: Class icon LEFT, Trinket/Racial RIGHT
        healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", classIconOffset, -2)
        healthBar:SetPoint("RIGHT", frame, "RIGHT", -trinketOffset, 0)
    else
        -- Normal layout: Trinket/Racial LEFT, Class icon RIGHT
        healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", trinketOffset, -2)
        healthBar:SetPoint("RIGHT", frame, "RIGHT", -classIconOffset, 0)
    end

    healthBar:SetHeight(db.height)

    -- Show/hide elements based on settings
    healthBar.nameText:SetShown(db.showName)
    healthBar.percentText:SetShown(db.showPercent ~= false)
    healthBar.specText:SetShown(db.showSpec ~= false)
    healthBar.healthText:SetShown(db.showAbsolute ~= false)

    if testData then
        -- Test mode
        local testNames = {"Easymodex", "Gladiator", "Shadowstep"}
        local testSpecs = {"Frost Mage", "Survival Hunter", "Combat Rogue"}

        local color = addon.Data.GetClassColor(testData.class)
        if db.colorByClass then
            healthBar:SetStatusBarColor(color.r, color.g, color.b)
        else
            healthBar:SetStatusBarColor(0, 1, 0)
        end

        healthBar:SetMinMaxValues(0, testData.maxHealth)
        healthBar:SetValue(testData.health)

        healthBar.nameText:SetText("arena" .. frame.index)
        healthBar.percentText:SetText(string.format("%.1f%%", testData.health))
        healthBar.specText:SetText(testSpecs[frame.index] or "Unknown")
        healthBar.healthText:SetText(FormatNumber(testData.health * 3000) .. "/" .. FormatNumber(testData.maxHealth * 3000))
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

    -- During prep phase, unit doesn't exist yet
    if not UnitExists(unit) then
        healthBar:SetMinMaxValues(0, 100)
        healthBar:SetValue(100)
        healthBar.percentText:SetText("100.0%")
        healthBar.healthText:SetText("")

        -- Show "arena1", "arena2", etc as name
        healthBar.nameText:SetText("arena" .. frame.index)

        -- Show spec name if we have specID from prep phase
        if frame.specID then
            local _, specName = GetSpecializationInfoByID(frame.specID)
            if specName then
                healthBar.specText:SetText(specName)
            end
        else
            healthBar.specText:SetText("")
        end

        -- Apply class color
        if db.colorByClass and frame.class then
            local color = addon.Data.GetClassColor(frame.class)
            healthBar:SetStatusBarColor(color.r, color.g, color.b)
        else
            healthBar:SetStatusBarColor(0, 1, 0)
        end
        return
    end

    -- Unit exists - update all info

    -- Name (use arena1, arena2, etc. like in screenshot)
    if db.showName then
        healthBar.nameText:SetText("arena" .. frame.index)
    end

    -- Spec name
    if frame.specID then
        local _, specName = GetSpecializationInfoByID(frame.specID)
        if specName then
            healthBar.specText:SetText(specName)
        end
    elseif frame.class then
        -- Fallback to class name if no spec
        local className = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[frame.class]
        healthBar.specText:SetText(className or frame.class)
    end

    -- Get health values (may be secret in 12.0)
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)

    -- StatusBar accepts secret values
    healthBar:SetMinMaxValues(0, maxHealth)
    healthBar:SetValue(health)

    -- Health percentage display
    if UnitHealthPercent then
        local percent = UnitHealthPercent(unit)
        if percent then
            if issecretvalue and issecretvalue(percent) then
                healthBar.percentText:SetText("")
            else
                healthBar.percentText:SetText(string.format("%.1f%%", percent))
            end
        else
            healthBar.percentText:SetText("100.0%")
        end
    else
        -- Fallback calculation
        if health and maxHealth then
            if issecretvalue and (issecretvalue(health) or issecretvalue(maxHealth)) then
                healthBar.percentText:SetText("")
            elseif maxHealth > 0 then
                local percent = (health / maxHealth) * 100
                healthBar.percentText:SetText(string.format("%.1f%%", percent))
            else
                healthBar.percentText:SetText("100.0%")
            end
        else
            healthBar.percentText:SetText("")
        end
    end

    -- Health values display (300.0k/300.0k)
    if health and maxHealth then
        if issecretvalue and (issecretvalue(health) or issecretvalue(maxHealth)) then
            healthBar.healthText:SetText("")
        else
            healthBar.healthText:SetText(FormatNumber(health) .. "/" .. FormatNumber(maxHealth))
        end
    else
        healthBar.healthText:SetText("")
    end

    -- Class color
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
        healthBar.nameText:SetText("")
        healthBar.percentText:SetText("100.0%")
        healthBar.specText:SetText("")
        healthBar.healthText:SetText("")
        healthBar:SetStatusBarColor(0, 1, 0)
    end
end

-- Register module
addon.Core:RegisterModule("health", Health)
