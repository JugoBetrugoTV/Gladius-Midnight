-- Gladius Midnight - Configuration System
-- Comprehensive settings UI for WoW Midnight 12.0

local _, GladiusMidnight = ...

-- Config frame references
local configFrame = nil
local currentTab = 1

-- Available fonts (will be populated at runtime)
local fontList = {
    "Fonts\\FRIZQT__.TTF",
    "Fonts\\ARIALN.TTF",
    "Fonts\\MORPHEUS.TTF",
    "Fonts\\SKURRI.TTF",
}

-- Available bar textures
local textureList = {
    ["Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
    ["Smooth"] = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
    ["Flat"] = "Interface\\Buttons\\WHITE8X8",
    ["Minimalist"] = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
}

-- Grow directions
local growDirections = {
    ["DOWN"] = "Nach unten",
    ["UP"] = "Nach oben",
    ["LEFT"] = "Nach links",
    ["RIGHT"] = "Nach rechts",
}

-- ============================================================================
-- UI Helper Functions
-- ============================================================================

local function CreateSectionHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, yOffset)
    header:SetText("|cFFFFD700" .. text .. "|r")
    return header, yOffset - 25
end

local function CreateCheckbox(parent, label, settingKey, yOffset, tooltip)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 15, yOffset)
    checkbox.Text:SetText(label)
    checkbox.Text:SetFontObject("GameFontNormal")

    checkbox:SetChecked(GladiusMidnight.db[settingKey])
    checkbox:SetScript("OnClick", function(self)
        GladiusMidnight.db[settingKey] = self:GetChecked()
        GladiusMidnight:ApplySettings()
    end)

    if tooltip then
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return checkbox, yOffset - 28
end

local function CreateSlider(parent, label, settingKey, minVal, maxVal, step, yOffset, width, isPercent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width or 300, 50)
    container:SetPoint("TOPLEFT", 15, yOffset)

    local sliderLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sliderLabel:SetPoint("TOPLEFT", 0, 0)
    sliderLabel:SetText(label)

    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("TOPRIGHT", 0, 0)

    local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 0, -18)
    slider:SetWidth(width or 300)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local currentValue = GladiusMidnight.db[settingKey] or minVal
    slider:SetValue(currentValue)

    local function UpdateValueText(value)
        if isPercent then
            valueText:SetText(string.format("%.0f%%", value * 100))
        elseif step < 1 then
            valueText:SetText(string.format("%.1f", value))
        else
            valueText:SetText(string.format("%.0f", value))
        end
    end

    UpdateValueText(currentValue)

    slider.Low:SetText(minVal)
    slider.High:SetText(maxVal)
    slider.Text:SetText("")

    slider:SetScript("OnValueChanged", function(self, value)
        GladiusMidnight.db[settingKey] = value
        UpdateValueText(value)
        GladiusMidnight:ApplySettings()
    end)

    return slider, yOffset - 55
end

local function CreateDropdown(parent, label, settingKey, options, yOffset, width)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width or 300, 45)
    container:SetPoint("TOPLEFT", 15, yOffset)

    local dropLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropLabel:SetPoint("TOPLEFT", 0, 0)
    dropLabel:SetText(label)

    local dropdown = CreateFrame("Frame", nil, container, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", -15, -15)
    UIDropDownMenu_SetWidth(dropdown, (width or 300) - 30)

    local function Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for value, displayText in pairs(options) do
            info.text = displayText
            info.value = value
            info.checked = (GladiusMidnight.db[settingKey] == value)
            info.func = function(self)
                GladiusMidnight.db[settingKey] = self.value
                UIDropDownMenu_SetText(dropdown, options[self.value])
                GladiusMidnight:ApplySettings()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(dropdown, Initialize)
    UIDropDownMenu_SetText(dropdown, options[GladiusMidnight.db[settingKey]] or "Select...")

    return dropdown, yOffset - 55
end

local function CreateColorPicker(parent, label, settingKey, yOffset)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(300, 25)
    container:SetPoint("TOPLEFT", 15, yOffset)

    local colorLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorLabel:SetPoint("LEFT", 0, 0)
    colorLabel:SetText(label)

    local colorSwatch = CreateFrame("Button", nil, container)
    colorSwatch:SetSize(20, 20)
    colorSwatch:SetPoint("RIGHT", 0, 0)

    local swatchTexture = colorSwatch:CreateTexture(nil, "BACKGROUND")
    swatchTexture:SetAllPoints()

    local color = GladiusMidnight.db[settingKey] or { r = 1, g = 1, b = 1 }
    swatchTexture:SetColorTexture(color.r, color.g, color.b)

    local border = colorSwatch:CreateTexture(nil, "OVERLAY")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0.3, 0.3, 0.3)
    border:SetDrawLayer("OVERLAY", -1)

    colorSwatch:SetScript("OnClick", function()
        local r, g, b = color.r, color.g, color.b

        local function ColorCallback(restore)
            local newR, newG, newB
            if restore then
                newR, newG, newB = unpack(restore)
            else
                newR, newG, newB = ColorPickerFrame:GetColorRGB()
            end

            GladiusMidnight.db[settingKey] = { r = newR, g = newG, b = newB }
            swatchTexture:SetColorTexture(newR, newG, newB)
            GladiusMidnight:ApplySettings()
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            swatchFunc = ColorCallback,
            cancelFunc = ColorCallback,
        })
    end)

    return colorSwatch, yOffset - 30
end

local function CreateEditBox(parent, label, settingKey, yOffset, width, isNumeric)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width or 300, 45)
    container:SetPoint("TOPLEFT", 15, yOffset)

    local editLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    editLabel:SetPoint("TOPLEFT", 0, 0)
    editLabel:SetText(label)

    local editBox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    editBox:SetSize((width or 300) - 10, 20)
    editBox:SetPoint("TOPLEFT", 5, -18)
    editBox:SetAutoFocus(false)

    if isNumeric then
        editBox:SetNumeric(true)
    end

    editBox:SetText(tostring(GladiusMidnight.db[settingKey] or ""))

    editBox:SetScript("OnEnterPressed", function(self)
        local value = self:GetText()
        if isNumeric then
            value = tonumber(value) or 0
        end
        GladiusMidnight.db[settingKey] = value
        self:ClearFocus()
        GladiusMidnight:ApplySettings()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(GladiusMidnight.db[settingKey] or ""))
        self:ClearFocus()
    end)

    return editBox, yOffset - 50
end

-- ============================================================================
-- Tab Content Creation
-- ============================================================================

local function CreateGeneralTab(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints()

    local yOffset = -10
    local _, newY

    -- General Settings
    _, yOffset = CreateSectionHeader(content, "Allgemeine Einstellungen", yOffset)
    _, yOffset = CreateCheckbox(content, "Addon aktivieren", "enabled", yOffset, "Aktiviert oder deaktiviert das gesamte Addon")
    _, yOffset = CreateCheckbox(content, "Frames fixieren", "locked", yOffset, "Verhindert das Verschieben der Frames")
    _, yOffset = CreateCheckbox(content, "Im Hintergrund zeigen", "showOutOfArena", yOffset, "Zeigt Frames auch außerhalb der Arena (zum Testen)")

    yOffset = yOffset - 15

    -- Frame Position
    _, yOffset = CreateSectionHeader(content, "Position & Layout", yOffset)
    _, yOffset = CreateDropdown(content, "Wachstumsrichtung", "growDirection", growDirections, yOffset)
    _, yOffset = CreateSlider(content, "Abstand zwischen Frames", "spacing", 0, 50, 1, yOffset)
    _, yOffset = CreateSlider(content, "Horizontale Position", "posX", -800, 800, 5, yOffset)
    _, yOffset = CreateSlider(content, "Vertikale Position", "posY", -600, 600, 5, yOffset)

    yOffset = yOffset - 15

    -- Test Mode Section
    _, yOffset = CreateSectionHeader(content, "Test Modus", yOffset)

    local testButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    testButton:SetPoint("TOPLEFT", 15, yOffset)
    testButton:SetSize(200, 28)
    testButton:SetText("Test Modus umschalten")
    testButton:SetScript("OnClick", function()
        GladiusMidnight:ToggleTestMode()
    end)

    return content
end

local function CreateFrameTab(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints()

    local yOffset = -10

    -- Frame Size
    _, yOffset = CreateSectionHeader(content, "Frame Größe", yOffset)
    _, yOffset = CreateSlider(content, "Skalierung", "scale", 0.5, 2.0, 0.05, yOffset)
    _, yOffset = CreateSlider(content, "Frame Breite", "frameWidth", 100, 400, 5, yOffset)
    _, yOffset = CreateSlider(content, "Frame Höhe", "frameHeight", 30, 120, 2, yOffset)

    yOffset = yOffset - 15

    -- Background
    _, yOffset = CreateSectionHeader(content, "Hintergrund", yOffset)
    _, yOffset = CreateCheckbox(content, "Hintergrund anzeigen", "showBackground", yOffset)
    _, yOffset = CreateSlider(content, "Hintergrund Transparenz", "backgroundAlpha", 0, 1, 0.05, yOffset, nil, true)
    _, yOffset = CreateColorPicker(content, "Hintergrund Farbe", "backgroundColor", yOffset)

    yOffset = yOffset - 15

    -- Border
    _, yOffset = CreateSectionHeader(content, "Rahmen", yOffset)
    _, yOffset = CreateCheckbox(content, "Rahmen anzeigen", "showBorder", yOffset)
    _, yOffset = CreateSlider(content, "Rahmen Dicke", "borderSize", 1, 5, 1, yOffset)
    _, yOffset = CreateColorPicker(content, "Rahmen Farbe", "borderColor", yOffset)

    return content
end

local function CreateHealthBarTab(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints()

    local yOffset = -10

    -- Health Bar Display
    _, yOffset = CreateSectionHeader(content, "Lebensleiste Anzeige", yOffset)
    _, yOffset = CreateCheckbox(content, "Lebensleiste anzeigen", "showHealthBar", yOffset)
    _, yOffset = CreateCheckbox(content, "Lebenstext anzeigen", "showHealthText", yOffset)
    _, yOffset = CreateCheckbox(content, "Prozent anzeigen", "healthShowPercent", yOffset)
    _, yOffset = CreateCheckbox(content, "Aktuell/Max anzeigen", "healthShowCurrentMax", yOffset)

    yOffset = yOffset - 15

    -- Health Bar Size
    _, yOffset = CreateSectionHeader(content, "Lebensleiste Größe", yOffset)
    _, yOffset = CreateSlider(content, "Höhe", "healthBarHeight", 10, 50, 1, yOffset)
    _, yOffset = CreateSlider(content, "Horizontaler Offset", "healthBarOffsetX", -50, 50, 1, yOffset)
    _, yOffset = CreateSlider(content, "Vertikaler Offset", "healthBarOffsetY", -50, 50, 1, yOffset)

    yOffset = yOffset - 15

    -- Health Bar Appearance
    _, yOffset = CreateSectionHeader(content, "Lebensleiste Aussehen", yOffset)
    _, yOffset = CreateDropdown(content, "Textur", "healthBarTexture", textureList, yOffset)
    _, yOffset = CreateCheckbox(content, "Klassenfarbe verwenden", "healthUseClassColor", yOffset)
    _, yOffset = CreateCheckbox(content, "Farbverlauf nach HP", "healthColorByPercent", yOffset, "Grün bei voll, Rot bei niedrig")
    _, yOffset = CreateColorPicker(content, "Benutzerdefinierte Farbe", "healthBarColor", yOffset)

    yOffset = yOffset - 15

    -- Health Text
    _, yOffset = CreateSectionHeader(content, "Lebenstext Einstellungen", yOffset)
    _, yOffset = CreateSlider(content, "Textgröße", "healthTextSize", 8, 24, 1, yOffset)
    _, yOffset = CreateColorPicker(content, "Textfarbe", "healthTextColor", yOffset)
    _, yOffset = CreateCheckbox(content, "Text Schatten", "healthTextShadow", yOffset)

    return content
end

local function CreateResourceBarTab(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints()

    local yOffset = -10

    -- Resource Bar Display
    _, yOffset = CreateSectionHeader(content, "Ressourcenleiste Anzeige", yOffset)
    _, yOffset = CreateCheckbox(content, "Ressourcenleiste anzeigen", "showResourceBar", yOffset)
    _, yOffset = CreateCheckbox(content, "Ressourcentext anzeigen", "showResourceText", yOffset)
    _, yOffset = CreateCheckbox(content, "Prozent anzeigen", "resourceShowPercent", yOffset)

    yOffset = yOffset - 15

    -- Resource Bar Size
    _, yOffset = CreateSectionHeader(content, "Ressourcenleiste Größe", yOffset)
    _, yOffset = CreateSlider(content, "Höhe", "resourceBarHeight", 5, 30, 1, yOffset)
    _, yOffset = CreateSlider(content, "Horizontaler Offset", "resourceBarOffsetX", -50, 50, 1, yOffset)
    _, yOffset = CreateSlider(content, "Vertikaler Offset", "resourceBarOffsetY", -50, 50, 1, yOffset)

    yOffset = yOffset - 15

    -- Resource Bar Appearance
    _, yOffset = CreateSectionHeader(content, "Ressourcenleiste Aussehen", yOffset)
    _, yOffset = CreateDropdown(content, "Textur", "resourceBarTexture", textureList, yOffset)
    _, yOffset = CreateCheckbox(content, "Ressourcenfarbe verwenden", "resourceUseDefaultColor", yOffset, "Verwendet die Standard-Farbe des Ressourcentyps")
    _, yOffset = CreateColorPicker(content, "Benutzerdefinierte Farbe", "resourceBarColor", yOffset)

    yOffset = yOffset - 15

    -- Resource Text
    _, yOffset = CreateSectionHeader(content, "Ressourcentext Einstellungen", yOffset)
    _, yOffset = CreateSlider(content, "Textgröße", "resourceTextSize", 6, 18, 1, yOffset)
    _, yOffset = CreateColorPicker(content, "Textfarbe", "resourceTextColor", yOffset)

    return content
end

local function CreateClassIconTab(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints()

    local yOffset = -10

    -- Class Icon Display
    _, yOffset = CreateSectionHeader(content, "Klassensymbol Anzeige", yOffset)
    _, yOffset = CreateCheckbox(content, "Klassensymbol anzeigen", "showClassIcon", yOffset)
    _, yOffset = CreateCheckbox(content, "Spezialisierungssymbol verwenden", "useSpecIcon", yOffset, "Zeigt das Spezialisierungssymbol statt Klassensymbol")

    yOffset = yOffset - 15

    -- Class Icon Size & Position
    _, yOffset = CreateSectionHeader(content, "Größe & Position", yOffset)
    _, yOffset = CreateSlider(content, "Größe", "classIconSize", 16, 64, 2, yOffset)
    _, yOffset = CreateSlider(content, "Horizontaler Offset", "classIconOffsetX", -50, 50, 1, yOffset)
    _, yOffset = CreateSlider(content, "Vertikaler Offset", "classIconOffsetY", -50, 50, 1, yOffset)

    yOffset = yOffset - 15

    -- Class Icon Appearance
    _, yOffset = CreateSectionHeader(content, "Aussehen", yOffset)
    _, yOffset = CreateCheckbox(content, "Runder Rahmen", "classIconRound", yOffset)
    _, yOffset = CreateCheckbox(content, "Rahmen anzeigen", "classIconBorder", yOffset)
    _, yOffset = CreateSlider(content, "Rahmendicke", "classIconBorderSize", 1, 4, 1, yOffset)
    _, yOffset = CreateColorPicker(content, "Rahmenfarbe", "classIconBorderColor", yOffset)

    return content
end

local function CreateTrinketTab(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints()

    local yOffset = -10

    -- Trinket Display
    _, yOffset = CreateSectionHeader(content, "Trinket Anzeige", yOffset)
    _, yOffset = CreateCheckbox(content, "Trinket anzeigen", "showTrinket", yOffset)
    _, yOffset = CreateCheckbox(content, "Cooldown Spirale anzeigen", "trinketShowCooldown", yOffset)
    _, yOffset = CreateCheckbox(content, "Cooldown Text anzeigen", "trinketShowCooldownText", yOffset)

    yOffset = yOffset - 15

    -- Trinket Size & Position
    _, yOffset = CreateSectionHeader(content, "Größe & Position", yOffset)
    _, yOffset = CreateSlider(content, "Größe", "trinketSize", 16, 48, 2, yOffset)
    _, yOffset = CreateSlider(content, "Horizontaler Offset", "trinketOffsetX", -100, 100, 1, yOffset)
    _, yOffset = CreateSlider(content, "Vertikaler Offset", "trinketOffsetY", -100, 100, 1, yOffset)

    yOffset = yOffset - 15

    -- Trinket Appearance
    _, yOffset = CreateSectionHeader(content, "Aussehen", yOffset)
    _, yOffset = CreateCheckbox(content, "Entsättigen wenn auf CD", "trinketDesaturateOnCD", yOffset)
    _, yOffset = CreateCheckbox(content, "Farbcodierung", "trinketColorCode", yOffset, "Grün = Bereit, Rot = Cooldown")
    _, yOffset = CreateColorPicker(content, "Bereit Farbe", "trinketReadyColor", yOffset)
    _, yOffset = CreateColorPicker(content, "Cooldown Farbe", "trinketCDColor", yOffset)

    yOffset = yOffset - 15

    -- Trinket Alerts
    _, yOffset = CreateSectionHeader(content, "Benachrichtigungen", yOffset)
    _, yOffset = CreateCheckbox(content, "Sound bei Trinket Benutzung", "trinketPlaySound", yOffset)
    _, yOffset = CreateCheckbox(content, "Glow bei Bereitschaft", "trinketGlowOnReady", yOffset)

    return content
end

local function CreateRacialTab(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints()

    local yOffset = -10

    -- Racial Display
    _, yOffset = CreateSectionHeader(content, "Racial Anzeige", yOffset)
    _, yOffset = CreateCheckbox(content, "Racial anzeigen", "showRacial", yOffset)
    _, yOffset = CreateCheckbox(content, "Cooldown Spirale anzeigen", "racialShowCooldown", yOffset)
    _, yOffset = CreateCheckbox(content, "Cooldown Text anzeigen", "racialShowCooldownText", yOffset)

    yOffset = yOffset - 15

    -- Racial Size & Position
    _, yOffset = CreateSectionHeader(content, "Größe & Position", yOffset)
    _, yOffset = CreateSlider(content, "Größe", "racialSize", 16, 48, 2, yOffset)
    _, yOffset = CreateSlider(content, "Horizontaler Offset", "racialOffsetX", -100, 100, 1, yOffset)
    _, yOffset = CreateSlider(content, "Vertikaler Offset", "racialOffsetY", -100, 100, 1, yOffset)

    yOffset = yOffset - 15

    -- Racial Appearance
    _, yOffset = CreateSectionHeader(content, "Aussehen", yOffset)
    _, yOffset = CreateCheckbox(content, "Entsättigen wenn auf CD", "racialDesaturateOnCD", yOffset)
    _, yOffset = CreateCheckbox(content, "Farbcodierung", "racialColorCode", yOffset)
    _, yOffset = CreateColorPicker(content, "Bereit Farbe", "racialReadyColor", yOffset)
    _, yOffset = CreateColorPicker(content, "Cooldown Farbe", "racialCDColor", yOffset)

    return content
end

local function CreateProfilesTab(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints()

    local yOffset = -10

    -- Profile Management
    _, yOffset = CreateSectionHeader(content, "Profil Verwaltung", yOffset)

    -- Current profile display
    local profileLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileLabel:SetPoint("TOPLEFT", 15, yOffset)
    profileLabel:SetText("Aktuelles Profil: |cFFFFFFFF" .. (GladiusMidnight.db.currentProfile or "Default") .. "|r")
    yOffset = yOffset - 30

    -- Reset button
    local resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", 15, yOffset)
    resetButton:SetSize(200, 28)
    resetButton:SetText("Alle Einstellungen zurücksetzen")
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("GLADIUS_MIDNIGHT_RESET")
    end)
    yOffset = yOffset - 40

    -- Export/Import Section
    _, yOffset = CreateSectionHeader(content, "Export / Import", yOffset)

    local exportButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    exportButton:SetPoint("TOPLEFT", 15, yOffset)
    exportButton:SetSize(140, 28)
    exportButton:SetText("Einstellungen exportieren")
    exportButton:SetScript("OnClick", function()
        GladiusMidnight:ExportSettings()
    end)

    local importButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    importButton:SetPoint("LEFT", exportButton, "RIGHT", 10, 0)
    importButton:SetSize(140, 28)
    importButton:SetText("Einstellungen importieren")
    importButton:SetScript("OnClick", function()
        GladiusMidnight:ImportSettings()
    end)

    -- Reset confirmation dialog
    StaticPopupDialogs["GLADIUS_MIDNIGHT_RESET"] = {
        text = "Bist du sicher, dass du alle Gladius Midnight Einstellungen zurücksetzen möchtest?",
        button1 = "Ja",
        button2 = "Nein",
        OnAccept = function()
            GladiusMidnightDB = nil
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    return content
end

-- ============================================================================
-- Main Config Panel
-- ============================================================================

local tabs = {
    { name = "Allgemein", create = CreateGeneralTab },
    { name = "Frame", create = CreateFrameTab },
    { name = "Leben", create = CreateHealthBarTab },
    { name = "Ressource", create = CreateResourceBarTab },
    { name = "Klasse", create = CreateClassIconTab },
    { name = "Trinket", create = CreateTrinketTab },
    { name = "Racial", create = CreateRacialTab },
    { name = "Profile", create = CreateProfilesTab },
}

local function CreateConfigPanel()
    if configFrame then
        return configFrame
    end

    -- Main frame - use BasicFrameTemplateWithInset for 12.0 compatibility
    local frame = CreateFrame("Frame", "GladiusMidnightConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(550, 600)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    -- Set title
    frame.TitleText:SetText("Gladius Midnight - Einstellungen")

    -- Add icon next to title
    local titleIcon = frame:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(24, 24)
    titleIcon:SetPoint("RIGHT", frame.TitleText, "LEFT", -5, 0)
    titleIcon:SetTexture("Interface\\Icons\\Achievement_Arena_2v2_7")

    -- Tab container
    local tabContainer = CreateFrame("Frame", nil, frame)
    tabContainer:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 5, -5)
    tabContainer:SetPoint("BOTTOMLEFT", frame.Inset, "BOTTOMLEFT", 5, 5)
    tabContainer:SetWidth(120)

    -- Tab background
    local tabBg = tabContainer:CreateTexture(nil, "BACKGROUND")
    tabBg:SetAllPoints()
    tabBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    -- Content container
    local contentContainer = CreateFrame("Frame", nil, frame)
    contentContainer:SetPoint("TOPLEFT", tabContainer, "TOPRIGHT", 5, 0)
    contentContainer:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -5, 5)

    -- Content background
    local contentBg = contentContainer:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetColorTexture(0.05, 0.05, 0.05, 0.9)

    -- Scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, contentContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(380, 800)
    scrollFrame:SetScrollChild(scrollContent)

    frame.scrollContent = scrollContent
    frame.tabContents = {}
    frame.tabButtons = {}

    -- Create tab buttons
    local function SelectTab(index)
        currentTab = index

        -- Update button appearance
        for i, button in ipairs(frame.tabButtons) do
            if i == index then
                button:SetNormalFontObject("GameFontHighlight")
                button.bg:SetColorTexture(0.2, 0.4, 0.6, 1)
            else
                button:SetNormalFontObject("GameFontNormal")
                button.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
            end
        end

        -- Show/hide content
        for i, content in ipairs(frame.tabContents) do
            if i == index then
                content:Show()
            else
                content:Hide()
            end
        end

        -- Reset scroll position
        scrollFrame:SetVerticalScroll(0)
    end

    for i, tab in ipairs(tabs) do
        local button = CreateFrame("Button", nil, tabContainer)
        button:SetSize(110, 28)
        button:SetPoint("TOPLEFT", 5, -5 - ((i - 1) * 30))

        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.15, 0.15, 0.15, 1)
        button.bg = bg

        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.3, 0.5, 0.7, 0.3)

        button:SetNormalFontObject("GameFontNormal")
        button:SetText(tab.name)
        button:GetFontString():SetPoint("LEFT", 10, 0)

        button:SetScript("OnClick", function()
            SelectTab(i)
        end)

        frame.tabButtons[i] = button

        -- Create tab content
        local content = tab.create(scrollContent)
        content:Hide()
        frame.tabContents[i] = content
    end

    -- Select first tab
    SelectTab(1)

    -- Close on escape
    tinsert(UISpecialFrames, "GladiusMidnightConfigFrame")

    configFrame = frame
    return frame
end

-- ============================================================================
-- Apply Settings Function
-- ============================================================================

function GladiusMidnight:ApplySettings()
    local db = self.db
    if not db then return end

    -- Apply main frame position
    if GladiusMidnightFrame then
        GladiusMidnightFrame:ClearAllPoints()
        GladiusMidnightFrame:SetPoint("CENTER", UIParent, "CENTER", db.posX or 0, db.posY or 0)
        GladiusMidnightFrame:SetScale(db.scale or 1.0)
    end

    -- Apply to each arena frame
    for i = 1, 3 do
        local frame = _G["GladiusMidnightArena" .. i]
        if frame then
            -- Frame size
            frame:SetSize(db.frameWidth or 200, db.frameHeight or 50)

            -- Background
            if frame.Background then
                if db.showBackground then
                    local bgColor = db.backgroundColor or { r = 0.1, g = 0.1, b = 0.1 }
                    frame.Background:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, db.backgroundAlpha or 0.8)
                    frame.Background:Show()
                else
                    frame.Background:Hide()
                end
            end

            -- Health bar
            if frame.HealthBar then
                local healthHeight = db.healthBarHeight or 22
                frame.HealthBar:SetHeight(healthHeight)
                frame.HealthBar:SetWidth((db.frameWidth or 200) - 60)

                if db.healthBarTexture and textureList[db.healthBarTexture] then
                    frame.HealthBar:SetStatusBarTexture(textureList[db.healthBarTexture])
                end

                if frame.HealthBar.Text then
                    if db.showHealthText then
                        frame.HealthBar.Text:Show()
                        local textSize = db.healthTextSize or 12
                        frame.HealthBar.Text:SetFont("Fonts\\FRIZQT__.TTF", textSize, "OUTLINE")
                        if db.healthTextColor then
                            frame.HealthBar.Text:SetTextColor(db.healthTextColor.r, db.healthTextColor.g, db.healthTextColor.b)
                        end
                    else
                        frame.HealthBar.Text:Hide()
                    end
                end
            end

            -- Resource bar
            if frame.ResourceBar then
                local resourceHeight = db.resourceBarHeight or 12
                frame.ResourceBar:SetHeight(resourceHeight)
                frame.ResourceBar:SetWidth((db.frameWidth or 200) - 60)

                if db.resourceBarTexture and textureList[db.resourceBarTexture] then
                    frame.ResourceBar:SetStatusBarTexture(textureList[db.resourceBarTexture])
                end

                if db.showResourceBar == false then
                    frame.ResourceBar:Hide()
                else
                    frame.ResourceBar:Show()
                end

                if frame.ResourceBar.Text then
                    if db.showResourceText then
                        frame.ResourceBar.Text:Show()
                        local textSize = db.resourceTextSize or 10
                        frame.ResourceBar.Text:SetFont("Fonts\\FRIZQT__.TTF", textSize, "OUTLINE")
                    else
                        frame.ResourceBar.Text:Hide()
                    end
                end
            end

            -- Class icon
            if frame.ClassIcon then
                if db.showClassIcon == false then
                    frame.ClassIcon:Hide()
                else
                    frame.ClassIcon:Show()
                    local iconSize = db.classIconSize or 44
                    frame.ClassIcon:SetSize(iconSize, iconSize)
                end
            end

            -- Trinket
            if frame.Trinket then
                if db.showTrinket == false then
                    frame.Trinket:Hide()
                else
                    frame.Trinket:Show()
                    local trinketSize = db.trinketSize or 24
                    frame.Trinket:SetSize(trinketSize, trinketSize)

                    local offsetX = db.trinketOffsetX or 4
                    local offsetY = db.trinketOffsetY or 8
                    frame.Trinket:ClearAllPoints()
                    frame.Trinket:SetPoint("LEFT", frame, "RIGHT", offsetX, offsetY)
                end
            end

            -- Racial
            if frame.Racial then
                if db.showRacial == false then
                    frame.Racial:Hide()
                else
                    frame.Racial:Show()
                    local racialSize = db.racialSize or 24
                    frame.Racial:SetSize(racialSize, racialSize)

                    local offsetX = db.racialOffsetX or 0
                    local offsetY = db.racialOffsetY or -2
                    frame.Racial:ClearAllPoints()
                    if frame.Trinket then
                        frame.Racial:SetPoint("TOP", frame.Trinket, "BOTTOM", offsetX, offsetY)
                    else
                        frame.Racial:SetPoint("LEFT", frame, "RIGHT", offsetX + 4, offsetY)
                    end
                end
            end

            -- Lock/unlock
            frame:SetMovable(not db.locked)
        end
    end

    -- Update spacing between frames
    local growDir = db.growDirection or "DOWN"
    for i = 2, 3 do
        local frame = _G["GladiusMidnightArena" .. i]
        local prevFrame = _G["GladiusMidnightArena" .. (i - 1)]
        if frame and prevFrame then
            frame:ClearAllPoints()
            local spacing = db.spacing or 5

            if growDir == "DOWN" then
                frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
            elseif growDir == "UP" then
                frame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
            elseif growDir == "LEFT" then
                frame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
            elseif growDir == "RIGHT" then
                frame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
            end
        end
    end
end

-- ============================================================================
-- Export/Import Functions
-- ============================================================================

function GladiusMidnight:ExportSettings()
    -- Create export frame
    local exportFrame = CreateFrame("Frame", "GladiusMidnightExportFrame", UIParent, "BasicFrameTemplateWithInset")
    exportFrame:SetSize(400, 300)
    exportFrame:SetPoint("CENTER")
    exportFrame:SetFrameStrata("DIALOG")

    exportFrame.TitleText:SetText("Einstellungen exportieren")

    local editBox = CreateFrame("EditBox", nil, exportFrame, "InputBoxTemplate")
    editBox:SetMultiLine(true)
    editBox:SetSize(360, 220)
    editBox:SetPoint("TOP", 0, -40)
    editBox:SetAutoFocus(true)
    editBox:EnableMouse(true)
    editBox:SetMaxLetters(99999)

    -- Serialize settings
    local serialized = ""
    for key, value in pairs(self.db) do
        if type(value) == "table" then
            serialized = serialized .. key .. "=" .. "TABLE" .. ";"
        else
            serialized = serialized .. key .. "=" .. tostring(value) .. ";"
        end
    end

    editBox:SetText(serialized)
    editBox:HighlightText()

    tinsert(UISpecialFrames, "GladiusMidnightExportFrame")
end

function GladiusMidnight:ImportSettings()
    -- Create import frame
    local importFrame = CreateFrame("Frame", "GladiusMidnightImportFrame", UIParent, "BasicFrameTemplateWithInset")
    importFrame:SetSize(400, 300)
    importFrame:SetPoint("CENTER")
    importFrame:SetFrameStrata("DIALOG")

    importFrame.TitleText:SetText("Einstellungen importieren")

    local editBox = CreateFrame("EditBox", nil, importFrame, "InputBoxTemplate")
    editBox:SetMultiLine(true)
    editBox:SetSize(360, 180)
    editBox:SetPoint("TOP", 0, -40)
    editBox:SetAutoFocus(true)
    editBox:EnableMouse(true)
    editBox:SetMaxLetters(99999)

    local importButton = CreateFrame("Button", nil, importFrame, "UIPanelButtonTemplate")
    importButton:SetSize(100, 25)
    importButton:SetPoint("BOTTOM", 0, 15)
    importButton:SetText("Importieren")
    importButton:SetScript("OnClick", function()
        local text = editBox:GetText()
        -- Parse and apply settings
        for pair in string.gmatch(text, "([^;]+)") do
            local key, value = string.match(pair, "(.+)=(.+)")
            if key and value and value ~= "TABLE" then
                if value == "true" then
                    GladiusMidnight.db[key] = true
                elseif value == "false" then
                    GladiusMidnight.db[key] = false
                elseif tonumber(value) then
                    GladiusMidnight.db[key] = tonumber(value)
                else
                    GladiusMidnight.db[key] = value
                end
            end
        end
        GladiusMidnight:ApplySettings()
        importFrame:Hide()
        print("|cFF00FF00Gladius Midnight|r: Einstellungen importiert!")
    end)

    tinsert(UISpecialFrames, "GladiusMidnightImportFrame")
end

-- ============================================================================
-- Open Config Function
-- ============================================================================

function GladiusMidnight:OpenConfig()
    local panel = CreateConfigPanel()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end

-- ============================================================================
-- Interface Options Registration
-- ============================================================================

local function RegisterInterfaceOptions()
    local panel = CreateFrame("Frame")
    panel.name = "Gladius Midnight"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Gladius Midnight")

    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Arena Unit Frames für WoW Midnight.\n\nVerwende /gladius oder /gm um die Konfiguration zu öffnen.")

    local openButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openButton:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    openButton:SetSize(200, 30)
    openButton:SetText("Konfiguration öffnen")
    openButton:SetScript("OnClick", function()
        GladiusMidnight:OpenConfig()
    end)

    -- Register with the new Settings API in 12.0
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
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
