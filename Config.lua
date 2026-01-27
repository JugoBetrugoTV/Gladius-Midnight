-- Gladius Midnight - Configuration System
-- Simple configuration UI for WoW Midnight 12.0

local _, GladiusMidnight = ...

-- Config frame reference
local configFrame = nil

-- Create the configuration panel
local function CreateConfigPanel()
    if configFrame then
        return configFrame
    end

    local frame = CreateFrame("Frame", "GladiusMidnightConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 450)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Title
    frame.TitleText:SetText("Gladius Midnight Configuration")

    -- Scroll frame for options
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -25, 5)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(350, 600)
    scrollFrame:SetScrollChild(content)

    local yOffset = -10
    local function AddLabel(text)
        local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        label:SetPoint("TOPLEFT", 10, yOffset)
        label:SetText(text)
        yOffset = yOffset - 25
        return label
    end

    local function AddCheckbox(label, settingKey)
        local checkbox = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 10, yOffset)
        checkbox.Text:SetText(label)

        checkbox:SetChecked(GladiusMidnight.db[settingKey])
        checkbox:SetScript("OnClick", function(self)
            GladiusMidnight.db[settingKey] = self:GetChecked()
        end)

        yOffset = yOffset - 30
        return checkbox
    end

    local function AddSlider(label, settingKey, minVal, maxVal, step)
        local sliderLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sliderLabel:SetPoint("TOPLEFT", 10, yOffset)
        sliderLabel:SetText(label)

        yOffset = yOffset - 20

        local slider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 10, yOffset)
        slider:SetWidth(300)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(GladiusMidnight.db[settingKey] or minVal)

        slider.Low:SetText(minVal)
        slider.High:SetText(maxVal)
        slider.Text:SetText(GladiusMidnight.db[settingKey] or minVal)

        slider:SetScript("OnValueChanged", function(self, value)
            GladiusMidnight.db[settingKey] = value
            self.Text:SetText(string.format("%.1f", value))
            GladiusMidnight:ApplySettings()
        end)

        yOffset = yOffset - 45
        return slider
    end

    -- General section
    AddLabel("|cFFFFD700General Settings|r")
    AddCheckbox("Enable Addon", "enabled")
    AddCheckbox("Lock Frame Positions", "locked")

    yOffset = yOffset - 10

    -- Display section
    AddLabel("|cFFFFD700Display Settings|r")
    AddCheckbox("Show Health Text", "showHealthText")
    AddCheckbox("Show Resource Text", "showResourceText")
    AddCheckbox("Show Trinket", "showTrinket")
    AddCheckbox("Show Racial", "showRacial")

    yOffset = yOffset - 10

    -- Size section
    AddLabel("|cFFFFD700Size & Scale|r")
    AddSlider("Frame Scale", "scale", 0.5, 2.0, 0.1)
    AddSlider("Frame Width", "frameWidth", 100, 400, 10)
    AddSlider("Frame Height", "frameHeight", 30, 100, 5)
    AddSlider("Frame Spacing", "spacing", 0, 20, 1)

    yOffset = yOffset - 10

    -- Button section
    local testButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    testButton:SetPoint("TOPLEFT", 10, yOffset)
    testButton:SetSize(150, 25)
    testButton:SetText("Toggle Test Mode")
    testButton:SetScript("OnClick", function()
        GladiusMidnight:ToggleTestMode()
    end)

    local resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetButton:SetPoint("LEFT", testButton, "RIGHT", 10, 0)
    resetButton:SetSize(150, 25)
    resetButton:SetText("Reset Settings")
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("GLADIUS_MIDNIGHT_RESET")
    end)

    -- Reset confirmation dialog
    StaticPopupDialogs["GLADIUS_MIDNIGHT_RESET"] = {
        text = "Are you sure you want to reset all Gladius Midnight settings?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            GladiusMidnightDB = nil
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    configFrame = frame
    return frame
end

-- Apply settings to frames
function GladiusMidnight:ApplySettings()
    local db = self.db

    -- Apply scale
    GladiusMidnightFrame:SetScale(db.scale)

    -- Apply frame dimensions
    for i = 1, 3 do
        local frame = _G["GladiusMidnightArena" .. i]
        if frame then
            frame:SetSize(db.frameWidth, db.frameHeight)

            -- Update health bar size
            if frame.HealthBar then
                frame.HealthBar:SetSize(db.frameWidth - 60, (db.frameHeight / 2) - 5)
            end

            -- Update resource bar size
            if frame.ResourceBar then
                frame.ResourceBar:SetSize(db.frameWidth - 60, (db.frameHeight / 2) - 10)
            end

            -- Lock/unlock
            frame:SetMovable(not db.locked)
            frame:EnableMouse(true)

            -- Show/hide elements
            if frame.Trinket then
                if db.showTrinket then
                    frame.Trinket:Show()
                else
                    frame.Trinket:Hide()
                end
            end

            if frame.Racial then
                if db.showRacial then
                    frame.Racial:Show()
                else
                    frame.Racial:Hide()
                end
            end

            -- Health text
            if frame.HealthBar and frame.HealthBar.Text then
                if db.showHealthText then
                    frame.HealthBar.Text:Show()
                else
                    frame.HealthBar.Text:Hide()
                end
            end

            -- Resource text
            if frame.ResourceBar and frame.ResourceBar.Text then
                if db.showResourceText then
                    frame.ResourceBar.Text:Show()
                else
                    frame.ResourceBar.Text:Hide()
                end
            end
        end
    end

    -- Update spacing between frames
    for i = 2, 3 do
        local frame = _G["GladiusMidnightArena" .. i]
        local prevFrame = _G["GladiusMidnightArena" .. (i - 1)]
        if frame and prevFrame then
            frame:ClearAllPoints()
            frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -db.spacing)
        end
    end
end

-- Open configuration panel
function GladiusMidnight:OpenConfig()
    local panel = CreateConfigPanel()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end

-- Register with Interface Options (12.0 compatible)
local function RegisterInterfaceOptions()
    local panel = CreateFrame("Frame")
    panel.name = "Gladius Midnight"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Gladius Midnight")

    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Arena unit frames for WoW Midnight.\n\nUse /gladius or /gm to open the configuration panel.")

    local openButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openButton:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    openButton:SetSize(200, 30)
    openButton:SetText("Open Configuration")
    openButton:SetScript("OnClick", function()
        GladiusMidnight:OpenConfig()
    end)

    -- Register with the new Settings API in 12.0
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        -- Fallback for older API
        if InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(panel)
        end
    end
end

-- Initialize config when addon loads
local configLoader = CreateFrame("Frame")
configLoader:RegisterEvent("ADDON_LOADED")
configLoader:SetScript("OnEvent", function(self, event, addon)
    if addon == "GladiusMidnight" then
        RegisterInterfaceOptions()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
