-- Gladius Midnight - Advanced Configuration System
-- Professional settings UI with custom graphics and textures

local addonName, addon = ...
local GladiusMidnight = addon.Core

-- ============================================================================
-- Color Scheme & Constants
-- ============================================================================

local COLORS = {
    -- Main colors
    accent = { r = 0.4, g = 0.6, b = 1.0 },           -- Blue accent
    accentDark = { r = 0.2, g = 0.4, b = 0.8 },       -- Dark blue
    accentLight = { r = 0.6, g = 0.8, b = 1.0 },      -- Light blue
    gold = { r = 1.0, g = 0.82, b = 0.0 },            -- Gold

    -- Background colors
    bgDark = { r = 0.05, g = 0.05, b = 0.08 },        -- Very dark
    bgMedium = { r = 0.08, g = 0.08, b = 0.12 },      -- Medium dark
    bgLight = { r = 0.12, g = 0.12, b = 0.18 },       -- Lighter

    -- Text colors
    textWhite = { r = 1.0, g = 1.0, b = 1.0 },
    textGray = { r = 0.7, g = 0.7, b = 0.7 },
    textDark = { r = 0.5, g = 0.5, b = 0.5 },

    -- Status colors
    success = { r = 0.2, g = 0.8, b = 0.2 },
    warning = { r = 1.0, g = 0.6, b = 0.0 },
    error = { r = 0.8, g = 0.2, b = 0.2 },

    -- Class colors for preview
    classColors = {
        WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
        PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
        HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
        ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
        PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
        DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
        SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
        MAGE = { r = 0.41, g = 0.80, b = 0.94 },
        WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
        MONK = { r = 0.00, g = 1.00, b = 0.59 },
        DRUID = { r = 1.00, g = 0.49, b = 0.04 },
        DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
        EVOKER = { r = 0.20, g = 0.58, b = 0.50 },
    },
}

-- Tab definitions with icons
local TAB_DATA = {
    { id = "general", name = "Allgemein", icon = "Interface\\Icons\\INV_Misc_Gear_01" },
    { id = "frames", name = "Frames", icon = "Interface\\Icons\\Spell_ChargePositive" },
    { id = "health", name = "Leben", icon = "Interface\\Icons\\Spell_Holy_FlashHeal" },
    { id = "power", name = "Ressource", icon = "Interface\\Icons\\Spell_Frost_Stun" },
    { id = "classicon", name = "Klasse", icon = "Interface\\Icons\\ClassIcon_Warrior" },
    { id = "trinket", name = "Trinket", icon = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01" },
    { id = "racial", name = "Racial", icon = "Interface\\Icons\\Achievement_Character_Orc_Male" },
    { id = "dr", name = "DR Tracker", icon = "Interface\\Icons\\Spell_Magic_LesserInvisibilty" },
    { id = "castbar", name = "CastBar", icon = "Interface\\Icons\\Spell_Holy_MindVision" },
    { id = "auras", name = "Auras", icon = "Interface\\Icons\\Spell_Shadow_Possession" },
    { id = "profiles", name = "Profile", icon = "Interface\\Icons\\INV_Misc_Book_09" },
}

-- Config frame references
local configFrame = nil
local currentTab = "general"
local previewFrames = {}

-- ============================================================================
-- Utility Functions
-- ============================================================================

local function RGB(r, g, b, a)
    return r, g, b, a or 1
end

local function ColorRGB(color, alpha)
    return color.r, color.g, color.b, alpha or 1
end

local function CreateGradientTexture(frame, orientation, r1, g1, b1, a1, r2, g2, b2, a2)
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetColorTexture(1, 1, 1)

    if orientation == "HORIZONTAL" then
        texture:SetGradient("HORIZONTAL", CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
    else
        texture:SetGradient("VERTICAL", CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
    end

    return texture
end

-- ============================================================================
-- Custom UI Components
-- ============================================================================

-- Fancy Section Header with gradient line
local function CreateFancyHeader(parent, text, yOffset)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(parent:GetWidth() - 20, 30)
    container:SetPoint("TOPLEFT", 10, yOffset)

    -- Left gradient line
    local leftLine = container:CreateTexture(nil, "ARTWORK")
    leftLine:SetSize(80, 2)
    leftLine:SetPoint("LEFT", 0, 0)
    leftLine:SetColorTexture(1, 1, 1)
    leftLine:SetGradient("HORIZONTAL",
        CreateColor(0, 0, 0, 0),
        CreateColor(COLORS.accent.r, COLORS.accent.g, COLORS.accent.b, 1))

    -- Header text
    local headerText = container:CreateFontString(nil, "OVERLAY")
    headerText:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
    headerText:SetPoint("LEFT", leftLine, "RIGHT", 10, 0)
    headerText:SetTextColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b)
    headerText:SetText(text)
    headerText:SetShadowOffset(1, -1)
    headerText:SetShadowColor(0, 0, 0, 1)

    -- Right gradient line
    local rightLine = container:CreateTexture(nil, "ARTWORK")
    rightLine:SetSize(200, 2)
    rightLine:SetPoint("LEFT", headerText, "RIGHT", 10, 0)
    rightLine:SetColorTexture(1, 1, 1)
    rightLine:SetGradient("HORIZONTAL",
        CreateColor(COLORS.accent.r, COLORS.accent.g, COLORS.accent.b, 1),
        CreateColor(0, 0, 0, 0))

    return container, yOffset - 35
end

-- Styled Checkbox with custom graphics
local function CreateStyledCheckbox(parent, label, settingPath, yOffset, tooltip)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(parent:GetWidth() - 30, 26)
    container:SetPoint("TOPLEFT", 15, yOffset)

    -- Custom checkbox button
    local checkbox = CreateFrame("CheckButton", nil, container)
    checkbox:SetSize(20, 20)
    checkbox:SetPoint("LEFT", 0, 0)

    -- Checkbox background
    local bg = checkbox:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(ColorRGB(COLORS.bgLight, 0.8))

    -- Checkbox border
    local border = checkbox:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(ColorRGB(COLORS.accent, 0.5))

    -- Checkmark
    local check = checkbox:CreateTexture(nil, "OVERLAY")
    check:SetSize(16, 16)
    check:SetPoint("CENTER")
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetDesaturated(false)
    check:SetVertexColor(COLORS.accent.r, COLORS.accent.g, COLORS.accent.b)
    check:Hide()
    checkbox.check = check

    -- Hover glow
    local glow = checkbox:CreateTexture(nil, "OVERLAY", nil, 1)
    glow:SetPoint("TOPLEFT", -4, 4)
    glow:SetPoint("BOTTOMRIGHT", 4, -4)
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(COLORS.accentLight.r, COLORS.accentLight.g, COLORS.accentLight.b, 0.5)
    glow:Hide()
    checkbox.glow = glow

    -- Get current value from profile
    local function GetValue()
        local keys = {strsplit(".", settingPath)}
        local value = GladiusMidnight.db.profile
        for _, key in ipairs(keys) do
            if value and value[key] ~= nil then
                value = value[key]
            else
                return false
            end
        end
        return value
    end

    -- Set value in profile
    local function SetValue(val)
        local keys = {strsplit(".", settingPath)}
        local target = GladiusMidnight.db.profile
        for i = 1, #keys - 1 do
            if not target[keys[i]] then
                target[keys[i]] = {}
            end
            target = target[keys[i]]
        end
        target[keys[#keys]] = val
        GladiusMidnight:UpdateAllFrames()
    end

    local isChecked = GetValue()
    if isChecked then
        check:Show()
    end

    checkbox:SetScript("OnClick", function(self)
        local newValue = not GetValue()
        SetValue(newValue)
        if newValue then
            self.check:Show()
            -- Animate check appearing
            self.check:SetAlpha(0)
            self.check:SetScale(0.5)
            self.check:Show()
            local ag = self.check:CreateAnimationGroup()
            local anim = ag:CreateAnimation("Scale")
            anim:SetScale(2, 2)
            anim:SetDuration(0.1)
            anim:SetOrder(1)
            local fade = ag:CreateAnimation("Alpha")
            fade:SetFromAlpha(0)
            fade:SetToAlpha(1)
            fade:SetDuration(0.1)
            fade:SetOrder(1)
            ag:Play()
        else
            self.check:Hide()
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)

    checkbox:SetScript("OnEnter", function(self)
        self.glow:Show()
        border:SetColorTexture(ColorRGB(COLORS.accentLight, 1))
    end)

    checkbox:SetScript("OnLeave", function(self)
        self.glow:Hide()
        border:SetColorTexture(ColorRGB(COLORS.accent, 0.5))
    end)

    -- Label
    local labelText = container:CreateFontString(nil, "OVERLAY")
    labelText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    labelText:SetPoint("LEFT", checkbox, "RIGHT", 10, 0)
    labelText:SetTextColor(ColorRGB(COLORS.textWhite))
    labelText:SetText(label)

    -- Tooltip
    if tooltip then
        container:EnableMouse(true)
        container:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(label, COLORS.gold.r, COLORS.gold.g, COLORS.gold.b)
            GameTooltip:AddLine(tooltip, COLORS.textGray.r, COLORS.textGray.g, COLORS.textGray.b, true)
            GameTooltip:Show()
        end)
        container:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return container, yOffset - 30
end

-- Styled Slider with visual track
local function CreateStyledSlider(parent, label, settingPath, minVal, maxVal, step, yOffset, isPercent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(parent:GetWidth() - 30, 50)
    container:SetPoint("TOPLEFT", 15, yOffset)

    -- Label
    local labelText = container:CreateFontString(nil, "OVERLAY")
    labelText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    labelText:SetPoint("TOPLEFT", 0, 0)
    labelText:SetTextColor(ColorRGB(COLORS.textWhite))
    labelText:SetText(label)

    -- Value display
    local valueText = container:CreateFontString(nil, "OVERLAY")
    valueText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    valueText:SetPoint("TOPRIGHT", 0, 0)
    valueText:SetTextColor(ColorRGB(COLORS.accent))

    -- Slider track background
    local trackBg = container:CreateTexture(nil, "BACKGROUND")
    trackBg:SetHeight(6)
    trackBg:SetPoint("TOPLEFT", 0, -22)
    trackBg:SetPoint("TOPRIGHT", 0, -22)
    trackBg:SetColorTexture(ColorRGB(COLORS.bgDark, 1))

    -- Slider track border
    local trackBorder = CreateFrame("Frame", nil, container, "BackdropTemplate")
    trackBorder:SetHeight(8)
    trackBorder:SetPoint("TOPLEFT", 0, -21)
    trackBorder:SetPoint("TOPRIGHT", 0, -21)
    trackBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    trackBorder:SetBackdropBorderColor(ColorRGB(COLORS.accent, 0.3))

    -- Actual slider
    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetHeight(6)
    slider:SetPoint("TOPLEFT", 0, -22)
    slider:SetPoint("TOPRIGHT", 0, -22)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    -- Custom thumb
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(14, 14)
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumb:SetVertexColor(COLORS.accent.r, COLORS.accent.g, COLORS.accent.b)
    slider:SetThumbTexture(thumb)

    -- Fill bar (shows progress)
    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(4)
    fill:SetPoint("LEFT", trackBg, "LEFT", 1, 0)
    fill:SetColorTexture(1, 1, 1)
    fill:SetGradient("HORIZONTAL",
        CreateColor(COLORS.accentDark.r, COLORS.accentDark.g, COLORS.accentDark.b, 1),
        CreateColor(COLORS.accent.r, COLORS.accent.g, COLORS.accent.b, 1))
    slider.fill = fill

    -- Get current value
    local function GetValue()
        local keys = {strsplit(".", settingPath)}
        local value = GladiusMidnight.db.profile
        for _, key in ipairs(keys) do
            if value and value[key] ~= nil then
                value = value[key]
            else
                return minVal
            end
        end
        return value or minVal
    end

    -- Set value
    local function SetValue(val)
        local keys = {strsplit(".", settingPath)}
        local target = GladiusMidnight.db.profile
        for i = 1, #keys - 1 do
            if not target[keys[i]] then
                target[keys[i]] = {}
            end
            target = target[keys[i]]
        end
        target[keys[#keys]] = val
        GladiusMidnight:UpdateAllFrames()
    end

    local function UpdateValueText(value)
        if isPercent then
            valueText:SetText(string.format("%.0f%%", value * 100))
        elseif step < 1 then
            valueText:SetText(string.format("%.2f", value))
        else
            valueText:SetText(string.format("%.0f", value))
        end

        -- Update fill bar width
        local percent = (value - minVal) / (maxVal - minVal)
        local trackWidth = trackBg:GetWidth()
        if trackWidth and trackWidth > 0 then
            fill:SetWidth(math.max(1, trackWidth * percent))
        end
    end

    local currentValue = GetValue()
    slider:SetValue(currentValue)
    UpdateValueText(currentValue)

    slider:SetScript("OnValueChanged", function(self, value)
        SetValue(value)
        UpdateValueText(value)
    end)

    -- Min/Max labels
    local minLabel = container:CreateFontString(nil, "OVERLAY")
    minLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    minLabel:SetPoint("TOPLEFT", 0, -32)
    minLabel:SetTextColor(ColorRGB(COLORS.textDark))
    minLabel:SetText(minVal)

    local maxLabel = container:CreateFontString(nil, "OVERLAY")
    maxLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    maxLabel:SetPoint("TOPRIGHT", 0, -32)
    maxLabel:SetTextColor(ColorRGB(COLORS.textDark))
    maxLabel:SetText(maxVal)

    return container, yOffset - 55
end

-- Styled Dropdown
local function CreateStyledDropdown(parent, label, settingPath, options, yOffset)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(parent:GetWidth() - 30, 50)
    container:SetPoint("TOPLEFT", 15, yOffset)

    -- Label
    local labelText = container:CreateFontString(nil, "OVERLAY")
    labelText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    labelText:SetPoint("TOPLEFT", 0, 0)
    labelText:SetTextColor(ColorRGB(COLORS.textWhite))
    labelText:SetText(label)

    -- Dropdown button
    local dropdown = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdown:SetSize(200, 24)
    dropdown:SetPoint("TOPLEFT", 0, -18)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(ColorRGB(COLORS.bgLight, 0.9))
    dropdown:SetBackdropBorderColor(ColorRGB(COLORS.accent, 0.5))

    -- Selected text
    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    selectedText:SetPoint("LEFT", 8, 0)
    selectedText:SetTextColor(ColorRGB(COLORS.textWhite))
    dropdown.selectedText = selectedText

    -- Arrow
    local arrow = dropdown:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(12, 12)
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    arrow:SetTexCoord(0.2, 0.8, 0.25, 0.75)

    -- Get/Set functions
    local function GetValue()
        local keys = {strsplit(".", settingPath)}
        local value = GladiusMidnight.db.profile
        for _, key in ipairs(keys) do
            if value and value[key] ~= nil then
                value = value[key]
            else
                return nil
            end
        end
        return value
    end

    local function SetValue(val)
        local keys = {strsplit(".", settingPath)}
        local target = GladiusMidnight.db.profile
        for i = 1, #keys - 1 do
            if not target[keys[i]] then
                target[keys[i]] = {}
            end
            target = target[keys[i]]
        end
        target[keys[#keys]] = val
        GladiusMidnight:UpdateAllFrames()
    end

    -- Set initial text
    local currentValue = GetValue()
    selectedText:SetText(options[currentValue] or "Select...")

    -- Dropdown menu frame
    local menuFrame = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    menuFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menuFrame:SetWidth(200)
    menuFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    menuFrame:SetBackdropColor(ColorRGB(COLORS.bgMedium, 0.95))
    menuFrame:SetBackdropBorderColor(ColorRGB(COLORS.accent, 0.7))
    menuFrame:SetFrameStrata("TOOLTIP")
    menuFrame:Hide()
    dropdown.menuFrame = menuFrame

    -- Create menu items
    local itemHeight = 22
    local numItems = 0
    for _ in pairs(options) do numItems = numItems + 1 end
    menuFrame:SetHeight(numItems * itemHeight + 4)

    local index = 0
    for value, displayText in pairs(options) do
        local item = CreateFrame("Button", nil, menuFrame)
        item:SetSize(196, itemHeight)
        item:SetPoint("TOPLEFT", 2, -2 - (index * itemHeight))

        local itemBg = item:CreateTexture(nil, "BACKGROUND")
        itemBg:SetAllPoints()
        itemBg:SetColorTexture(0, 0, 0, 0)
        item.bg = itemBg

        local itemText = item:CreateFontString(nil, "OVERLAY")
        itemText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        itemText:SetPoint("LEFT", 8, 0)
        itemText:SetTextColor(ColorRGB(COLORS.textWhite))
        itemText:SetText(displayText)

        item:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(COLORS.accent.r, COLORS.accent.g, COLORS.accent.b, 0.3)
        end)

        item:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0, 0, 0, 0)
        end)

        item:SetScript("OnClick", function()
            SetValue(value)
            selectedText:SetText(displayText)
            menuFrame:Hide()
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end)

        index = index + 1
    end

    -- Toggle menu on click
    dropdown:SetScript("OnClick", function()
        if menuFrame:IsShown() then
            menuFrame:Hide()
        else
            menuFrame:Show()
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)

    -- Hover effects
    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ColorRGB(COLORS.accentLight, 1))
    end)

    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(ColorRGB(COLORS.accent, 0.5))
    end)

    return container, yOffset - 55
end

-- Styled Color Picker
local function CreateStyledColorPicker(parent, label, settingPath, yOffset)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(parent:GetWidth() - 30, 30)
    container:SetPoint("TOPLEFT", 15, yOffset)

    -- Label
    local labelText = container:CreateFontString(nil, "OVERLAY")
    labelText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    labelText:SetPoint("LEFT", 0, 0)
    labelText:SetTextColor(ColorRGB(COLORS.textWhite))
    labelText:SetText(label)

    -- Color swatch button
    local colorButton = CreateFrame("Button", nil, container, "BackdropTemplate")
    colorButton:SetSize(60, 20)
    colorButton:SetPoint("RIGHT", 0, 0)
    colorButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    colorButton:SetBackdropBorderColor(ColorRGB(COLORS.accent, 0.8))

    -- Get/Set functions
    local function GetColor()
        local keys = {strsplit(".", settingPath)}
        local value = GladiusMidnight.db.profile
        for _, key in ipairs(keys) do
            if value and value[key] ~= nil then
                value = value[key]
            else
                return { r = 1, g = 1, b = 1 }
            end
        end
        return value or { r = 1, g = 1, b = 1 }
    end

    local function SetColor(r, g, b)
        local keys = {strsplit(".", settingPath)}
        local target = GladiusMidnight.db.profile
        for i = 1, #keys - 1 do
            if not target[keys[i]] then
                target[keys[i]] = {}
            end
            target = target[keys[i]]
        end
        target[keys[#keys]] = { r = r, g = g, b = b }
        colorButton:SetBackdropColor(r, g, b, 1)
        GladiusMidnight:UpdateAllFrames()
    end

    -- Set initial color
    local color = GetColor()
    colorButton:SetBackdropColor(color.r, color.g, color.b, 1)

    -- Hex display
    local hexText = container:CreateFontString(nil, "OVERLAY")
    hexText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    hexText:SetPoint("RIGHT", colorButton, "LEFT", -8, 0)
    hexText:SetTextColor(ColorRGB(COLORS.textGray))
    hexText:SetText(string.format("#%02X%02X%02X", color.r * 255, color.g * 255, color.b * 255))
    colorButton.hexText = hexText

    colorButton:SetScript("OnClick", function()
        local currentColor = GetColor()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = currentColor.r,
            g = currentColor.g,
            b = currentColor.b,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                SetColor(r, g, b)
                hexText:SetText(string.format("#%02X%02X%02X", r * 255, g * 255, b * 255))
            end,
            cancelFunc = function(prev)
                SetColor(prev.r, prev.g, prev.b)
                hexText:SetText(string.format("#%02X%02X%02X", prev.r * 255, prev.g * 255, prev.b * 255))
            end,
        })
    end)

    return container, yOffset - 35
end

-- Styled Button
local function CreateStyledButton(parent, text, yOffset, width, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 200, 28)
    button:SetPoint("TOPLEFT", 15, yOffset)

    -- Background with gradient
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    button:SetBackdropColor(COLORS.accent.r * 0.6, COLORS.accent.g * 0.6, COLORS.accent.b * 0.6, 0.9)
    button:SetBackdropBorderColor(ColorRGB(COLORS.accent, 1))

    -- Button text
    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    buttonText:SetPoint("CENTER")
    buttonText:SetTextColor(1, 1, 1)
    buttonText:SetText(text)

    -- Hover effect
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(COLORS.accentLight.r * 0.8, COLORS.accentLight.g * 0.8, COLORS.accentLight.b * 0.8, 1)
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(COLORS.accent.r * 0.6, COLORS.accent.g * 0.6, COLORS.accent.b * 0.6, 0.9)
    end)

    -- Click effect
    button:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(COLORS.accentDark.r, COLORS.accentDark.g, COLORS.accentDark.b, 1)
    end)

    button:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(COLORS.accent.r * 0.6, COLORS.accent.g * 0.6, COLORS.accent.b * 0.6, 0.9)
    end)

    if onClick then
        button:SetScript("OnClick", function()
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            onClick()
        end)
    end

    return button, yOffset - 35
end

-- ============================================================================
-- Tab Content Creation
-- ============================================================================

local function CreateGeneralContent(scrollContent)
    local yOffset = -10

    _, yOffset = CreateFancyHeader(scrollContent, "Allgemeine Einstellungen", yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Addon aktivieren", "enabled", yOffset, "Aktiviert oder deaktiviert das gesamte Addon")
    _, yOffset = CreateStyledCheckbox(scrollContent, "Frames fixieren", "locked", yOffset, "Verhindert das Verschieben der Frames")
    _, yOffset = CreateStyledCheckbox(scrollContent, "Blizzard Frames verstecken", "hideBlizzardFrames", yOffset, "Versteckt die Standard-Arena-Frames")
    _, yOffset = CreateStyledCheckbox(scrollContent, "Target Highlight", "targetHighlight", yOffset, "Zeigt einen Rahmen um das aktuelle Ziel")
    _, yOffset = CreateStyledCheckbox(scrollContent, "Immunity Glow", "immunityGlow", yOffset, "Leuchten bei Immunitäten (Bubble, Block, etc.)")

    yOffset = yOffset - 15
    _, yOffset = CreateFancyHeader(scrollContent, "Position & Layout", yOffset)

    local directions = {
        ["DOWN"] = "Nach unten",
        ["UP"] = "Nach oben",
        ["LEFT"] = "Nach links",
        ["RIGHT"] = "Nach rechts",
    }
    _, yOffset = CreateStyledDropdown(scrollContent, "Wachstumsrichtung", "growDirection", directions, yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Abstand zwischen Frames", "spacing", 0, 100, 1, yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Horizontale Position", "posX", -1000, 1000, 5, yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Vertikale Position", "posY", -800, 800, 5, yOffset)

    yOffset = yOffset - 15
    _, yOffset = CreateFancyHeader(scrollContent, "Test Modus", yOffset)

    _, yOffset = CreateStyledButton(scrollContent, "Test Modus umschalten", yOffset, 200, function()
        GladiusMidnight:ToggleTest()
    end)

    _, yOffset = CreateStyledButton(scrollContent, "Frames entsperren", yOffset, 200, function()
        GladiusMidnight.db.profile.locked = not GladiusMidnight.db.profile.locked
        local status = GladiusMidnight.db.profile.locked and "|cFFFF0000fixiert|r" or "|cFF00FF00entsperrt|r"
        GladiusMidnight:Print("Frames " .. status)
    end)
end

local function CreateFramesContent(scrollContent)
    local yOffset = -10

    _, yOffset = CreateFancyHeader(scrollContent, "Frame Größe", yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Skalierung", "scale", 0.5, 2.0, 0.05, yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Frame Breite", "frameWidth", 150, 400, 5, yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Frame Höhe", "frameHeight", 40, 150, 2, yOffset)
end

local function CreateHealthContent(scrollContent)
    local yOffset = -10

    _, yOffset = CreateFancyHeader(scrollContent, "Lebensleiste Einstellungen", yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Höhe", "health.height", 10, 60, 1, yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Text anzeigen", "health.showText", yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Name anzeigen", "health.showName", yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Klassenfarbe verwenden", "health.colorByClass", yOffset)
end

local function CreatePowerContent(scrollContent)
    local yOffset = -10

    _, yOffset = CreateFancyHeader(scrollContent, "Ressourcenleiste Einstellungen", yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Ressourcenleiste aktivieren", "modules.power", yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Höhe", "power.height", 4, 30, 1, yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Text anzeigen", "power.showText", yOffset)
end

local function CreateClassIconContent(scrollContent)
    local yOffset = -10

    _, yOffset = CreateFancyHeader(scrollContent, "Klassensymbol Einstellungen", yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Klassensymbol aktivieren", "modules.classIcon", yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Größe", "classIcon.size", 20, 80, 2, yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Spezialisierung anzeigen", "classIcon.showSpec", yOffset, "Zeigt das Spec-Icon statt Klassen-Icon")

    local positions = {
        ["LEFT"] = "Links",
        ["RIGHT"] = "Rechts",
    }
    _, yOffset = CreateStyledDropdown(scrollContent, "Position", "classIcon.position", positions, yOffset)
end

local function CreateTrinketContent(scrollContent)
    local yOffset = -10

    _, yOffset = CreateFancyHeader(scrollContent, "Trinket Einstellungen", yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Trinket aktivieren", "modules.trinket", yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Größe", "trinket.size", 16, 48, 2, yOffset)

    local positions = {
        ["RIGHT"] = "Rechts",
        ["LEFT"] = "Links",
    }
    _, yOffset = CreateStyledDropdown(scrollContent, "Position", "trinket.position", positions, yOffset)
end

local function CreateRacialContent(scrollContent)
    local yOffset = -10

    _, yOffset = CreateFancyHeader(scrollContent, "Racial Einstellungen", yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Racial aktivieren", "modules.racial", yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Größe", "racial.size", 16, 48, 2, yOffset)

    local positions = {
        ["RIGHT"] = "Rechts",
        ["LEFT"] = "Links",
    }
    _, yOffset = CreateStyledDropdown(scrollContent, "Position", "racial.position", positions, yOffset)
end

local function CreateDRContent(scrollContent)
    local yOffset = -10

    _, yOffset = CreateFancyHeader(scrollContent, "DR Tracker Einstellungen", yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "DR Tracker aktivieren", "modules.drTracker", yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Icon Größe", "drTracker.iconSize", 14, 36, 2, yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Timer anzeigen", "drTracker.showTimer", yOffset)

    yOffset = yOffset - 15
    _, yOffset = CreateFancyHeader(scrollContent, "Midnight 12.0 Info", yOffset)

    local infoText = scrollContent:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    infoText:SetPoint("TOPLEFT", 15, yOffset)
    infoText:SetWidth(scrollContent:GetWidth() - 30)
    infoText:SetJustifyH("LEFT")
    infoText:SetTextColor(COLORS.textGray.r, COLORS.textGray.g, COLORS.textGray.b)
    infoText:SetText("|cFFFFD700Hinweis:|r In Midnight 12.0 wird Blizzards eingebautes DR-System verwendet. Die DR-Icons werden von Blizzards CompactArenaFrameMember reparented.")
end

local function CreateCastBarContent(scrollContent)
    local yOffset = -10

    _, yOffset = CreateFancyHeader(scrollContent, "CastBar Einstellungen", yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "CastBar aktivieren", "modules.castBar", yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Höhe", "castBar.height", 8, 30, 1, yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Icon anzeigen", "castBar.showIcon", yOffset)

    yOffset = yOffset - 15
    _, yOffset = CreateFancyHeader(scrollContent, "Midnight 12.0 Info", yOffset)

    local infoText = scrollContent:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    infoText:SetPoint("TOPLEFT", 15, yOffset)
    infoText:SetWidth(scrollContent:GetWidth() - 30)
    infoText:SetJustifyH("LEFT")
    infoText:SetTextColor(COLORS.textGray.r, COLORS.textGray.g, COLORS.textGray.b)
    infoText:SetText("|cFFFFD700Hinweis:|r In Midnight 12.0 wird Blizzards eingebaute CastBar verwendet. Cast-Daten sind 'secret' und können nicht direkt gelesen werden.")
end

local function CreateAurasContent(scrollContent)
    local yOffset = -10

    _, yOffset = CreateFancyHeader(scrollContent, "Auras Einstellungen", yOffset)
    _, yOffset = CreateStyledCheckbox(scrollContent, "Auras aktivieren", "modules.auras", yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Icon Größe", "auras.iconSize", 16, 48, 2, yOffset)
    _, yOffset = CreateStyledSlider(scrollContent, "Max Auras", "auras.maxAuras", 1, 8, 1, yOffset)

    yOffset = yOffset - 15
    _, yOffset = CreateFancyHeader(scrollContent, "Midnight 12.0 Info", yOffset)

    local infoText = scrollContent:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    infoText:SetPoint("TOPLEFT", 15, yOffset)
    infoText:SetWidth(scrollContent:GetWidth() - 30)
    infoText:SetJustifyH("LEFT")
    infoText:SetTextColor(COLORS.textGray.r, COLORS.textGray.g, COLORS.textGray.b)
    infoText:SetText("|cFFFFD700Hinweis:|r In Midnight 12.0 sind Aura-Daten 'secret'. Das Addon hookt in Blizzards DebuffFrame um den wichtigsten CC anzuzeigen.")
end

local function CreateProfilesContent(scrollContent)
    local yOffset = -10

    _, yOffset = CreateFancyHeader(scrollContent, "Profil Verwaltung", yOffset)

    -- Current profile
    local profileLabel = scrollContent:CreateFontString(nil, "OVERLAY")
    profileLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    profileLabel:SetPoint("TOPLEFT", 15, yOffset)
    profileLabel:SetTextColor(COLORS.textWhite.r, COLORS.textWhite.g, COLORS.textWhite.b)
    profileLabel:SetText("Aktuelles Profil: |cFF00FF00Default|r")
    yOffset = yOffset - 30

    _, yOffset = CreateStyledButton(scrollContent, "Alle Einstellungen zurücksetzen", yOffset, 250, function()
        StaticPopup_Show("GLADIUS_MIDNIGHT_RESET")
    end)

    yOffset = yOffset - 15
    _, yOffset = CreateFancyHeader(scrollContent, "Export / Import", yOffset)

    local exportBtn
    exportBtn, yOffset = CreateStyledButton(scrollContent, "Einstellungen exportieren", yOffset, 200, function()
        GladiusMidnight:Print("Export Funktion - Coming Soon")
    end)

    _, yOffset = CreateStyledButton(scrollContent, "Einstellungen importieren", yOffset, 200, function()
        GladiusMidnight:Print("Import Funktion - Coming Soon")
    end)

    -- Reset dialog
    StaticPopupDialogs["GLADIUS_MIDNIGHT_RESET"] = {
        text = "Bist du sicher, dass du alle Gladius Midnight Einstellungen zurücksetzen möchtest?",
        button1 = "Ja",
        button2 = "Nein",
        OnAccept = function()
            GladiusMidnight.db:ResetProfile()
            GladiusMidnight:UpdateAllFrames()
            GladiusMidnight:Print("Einstellungen zurückgesetzt!")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end

-- Tab content creators mapping
local TAB_CONTENT_CREATORS = {
    general = CreateGeneralContent,
    frames = CreateFramesContent,
    health = CreateHealthContent,
    power = CreatePowerContent,
    classicon = CreateClassIconContent,
    trinket = CreateTrinketContent,
    racial = CreateRacialContent,
    dr = CreateDRContent,
    castbar = CreateCastBarContent,
    auras = CreateAurasContent,
    profiles = CreateProfilesContent,
}

-- ============================================================================
-- Main Config Panel Creation
-- ============================================================================

local function CreateConfigPanel()
    if configFrame then
        return configFrame
    end

    -- Main frame
    local frame = CreateFrame("Frame", "GladiusMidnightConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(700, 550)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)

    -- Main backdrop with dark theme
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        tileSize = 32,
        edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    frame:SetBackdropColor(ColorRGB(COLORS.bgDark, 0.98))

    -- =========================================================================
    -- Header Section
    -- =========================================================================

    local headerFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    headerFrame:SetHeight(60)
    headerFrame:SetPoint("TOPLEFT", 8, -8)
    headerFrame:SetPoint("TOPRIGHT", -8, -8)
    headerFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })

    -- Header gradient
    local headerGradient = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerGradient:SetAllPoints()
    headerGradient:SetColorTexture(1, 1, 1)
    headerGradient:SetGradient("VERTICAL",
        CreateColor(COLORS.accentDark.r * 0.3, COLORS.accentDark.g * 0.3, COLORS.accentDark.b * 0.3, 1),
        CreateColor(COLORS.bgDark.r, COLORS.bgDark.g, COLORS.bgDark.b, 1))

    -- Logo/Title area
    local logoIcon = headerFrame:CreateTexture(nil, "ARTWORK")
    logoIcon:SetSize(48, 48)
    logoIcon:SetPoint("LEFT", 15, 0)
    logoIcon:SetTexture("Interface\\Icons\\Achievement_Arena_5v5_1")
    logoIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Logo border
    local logoBorder = CreateFrame("Frame", nil, headerFrame, "BackdropTemplate")
    logoBorder:SetPoint("TOPLEFT", logoIcon, "TOPLEFT", -2, 2)
    logoBorder:SetPoint("BOTTOMRIGHT", logoIcon, "BOTTOMRIGHT", 2, -2)
    logoBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    logoBorder:SetBackdropBorderColor(ColorRGB(COLORS.gold, 1))

    -- Title text with shadow
    local titleShadow = headerFrame:CreateFontString(nil, "ARTWORK")
    titleShadow:SetFont("Fonts\\MORPHEUS.TTF", 28, "")
    titleShadow:SetPoint("LEFT", logoIcon, "RIGHT", 17, -1)
    titleShadow:SetTextColor(0, 0, 0, 0.7)
    titleShadow:SetText("Gladius Midnight")

    local titleText = headerFrame:CreateFontString(nil, "OVERLAY")
    titleText:SetFont("Fonts\\MORPHEUS.TTF", 28, "")
    titleText:SetPoint("LEFT", logoIcon, "RIGHT", 15, 0)
    titleText:SetTextColor(ColorRGB(COLORS.gold))
    titleText:SetText("Gladius Midnight")

    -- Subtitle
    local subtitleText = headerFrame:CreateFontString(nil, "OVERLAY")
    subtitleText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    subtitleText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 2, -2)
    subtitleText:SetTextColor(ColorRGB(COLORS.textGray))
    subtitleText:SetText("Arena Unit Frames - Midnight 12.0")

    -- Version badge
    local versionBadge = CreateFrame("Frame", nil, headerFrame, "BackdropTemplate")
    versionBadge:SetSize(60, 20)
    versionBadge:SetPoint("RIGHT", -15, 0)
    versionBadge:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    versionBadge:SetBackdropColor(COLORS.success.r * 0.3, COLORS.success.g * 0.3, COLORS.success.b * 0.3, 0.9)
    versionBadge:SetBackdropBorderColor(ColorRGB(COLORS.success, 0.8))

    local versionText = versionBadge:CreateFontString(nil, "OVERLAY")
    versionText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    versionText:SetPoint("CENTER")
    versionText:SetTextColor(ColorRGB(COLORS.success))
    versionText:SetText("v1.0")

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame)
    closeButton:SetSize(28, 28)
    closeButton:SetPoint("TOPRIGHT", -12, -12)
    closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    -- =========================================================================
    -- Tab Bar
    -- =========================================================================

    local tabBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    tabBar:SetHeight(36)
    tabBar:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -4)
    tabBar:SetPoint("TOPRIGHT", headerFrame, "BOTTOMRIGHT", 0, -4)
    tabBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    tabBar:SetBackdropColor(ColorRGB(COLORS.bgMedium, 0.95))

    -- Tab bottom line
    local tabLine = tabBar:CreateTexture(nil, "BORDER")
    tabLine:SetHeight(2)
    tabLine:SetPoint("BOTTOMLEFT", 0, 0)
    tabLine:SetPoint("BOTTOMRIGHT", 0, 0)
    tabLine:SetColorTexture(ColorRGB(COLORS.accent, 0.5))

    frame.tabButtons = {}
    frame.tabContents = {}

    -- Create scroll frame for content
    local contentFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -4)
    contentFrame:SetPoint("BOTTOMRIGHT", -8, 8)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    contentFrame:SetBackdropColor(ColorRGB(COLORS.bgMedium, 0.9))

    local scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(scrollFrame:GetWidth() - 20)
    scrollContent:SetHeight(1000)
    scrollFrame:SetScrollChild(scrollContent)

    frame.scrollContent = scrollContent
    frame.scrollFrame = scrollFrame

    -- Tab selection function
    local function SelectTab(tabId)
        currentTab = tabId

        -- Update tab button appearances
        for id, button in pairs(frame.tabButtons) do
            if id == tabId then
                button.bg:SetColorTexture(COLORS.accent.r * 0.5, COLORS.accent.g * 0.5, COLORS.accent.b * 0.5, 0.8)
                button.text:SetTextColor(ColorRGB(COLORS.textWhite))
                button.indicator:Show()
            else
                button.bg:SetColorTexture(0, 0, 0, 0)
                button.text:SetTextColor(ColorRGB(COLORS.textGray))
                button.indicator:Hide()
            end
        end

        -- Clear scroll content and create new content
        for _, child in ipairs({scrollContent:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end

        -- Create content for selected tab
        local creator = TAB_CONTENT_CREATORS[tabId]
        if creator then
            creator(scrollContent)
        end

        -- Reset scroll position
        scrollFrame:SetVerticalScroll(0)
    end

    -- Create tab buttons
    local tabWidth = 60
    local tabSpacing = 2
    local totalWidth = #TAB_DATA * (tabWidth + tabSpacing)
    local startX = (tabBar:GetWidth() - totalWidth) / 2

    for i, tabData in ipairs(TAB_DATA) do
        local button = CreateFrame("Button", nil, tabBar)
        button:SetSize(tabWidth, 32)
        button:SetPoint("BOTTOMLEFT", 6 + (i - 1) * (tabWidth + tabSpacing), 2)

        -- Button background
        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        button.bg = bg

        -- Icon
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("TOP", 0, -4)
        icon:SetTexture(tabData.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon = icon

        -- Text
        local text = button:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
        text:SetPoint("BOTTOM", 0, 3)
        text:SetTextColor(ColorRGB(COLORS.textGray))
        text:SetText(tabData.name)
        button.text = text

        -- Active indicator
        local indicator = button:CreateTexture(nil, "OVERLAY")
        indicator:SetHeight(2)
        indicator:SetPoint("BOTTOMLEFT", 4, 0)
        indicator:SetPoint("BOTTOMRIGHT", -4, 0)
        indicator:SetColorTexture(ColorRGB(COLORS.accent, 1))
        indicator:Hide()
        button.indicator = indicator

        -- Hover effect
        button:SetScript("OnEnter", function(self)
            if currentTab ~= tabData.id then
                self.bg:SetColorTexture(COLORS.accent.r * 0.2, COLORS.accent.g * 0.2, COLORS.accent.b * 0.2, 0.5)
            end
        end)

        button:SetScript("OnLeave", function(self)
            if currentTab ~= tabData.id then
                self.bg:SetColorTexture(0, 0, 0, 0)
            end
        end)

        button:SetScript("OnClick", function()
            SelectTab(tabData.id)
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end)

        frame.tabButtons[tabData.id] = button
    end

    -- Select first tab
    SelectTab("general")

    -- Close on escape
    tinsert(UISpecialFrames, "GladiusMidnightConfigFrame")

    frame:Hide()
    configFrame = frame
    return frame
end

-- ============================================================================
-- Public API
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

    -- Create visual panel for interface options
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(ColorRGB(COLORS.bgDark, 1))

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetTextColor(ColorRGB(COLORS.gold))
    title:SetText("Gladius Midnight")

    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetTextColor(ColorRGB(COLORS.textGray))
    desc:SetText("Arena Unit Frames für WoW Midnight 12.0\n\nVerwende |cFFFFD700/gladius|r oder |cFFFFD700/gm|r um die Konfiguration zu öffnen.")

    local openButton = CreateFrame("Button", nil, panel, "BackdropTemplate")
    openButton:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    openButton:SetSize(200, 30)
    openButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    openButton:SetBackdropColor(COLORS.accent.r * 0.6, COLORS.accent.g * 0.6, COLORS.accent.b * 0.6, 0.9)
    openButton:SetBackdropBorderColor(ColorRGB(COLORS.accent, 1))

    local buttonText = openButton:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    buttonText:SetPoint("CENTER")
    buttonText:SetTextColor(1, 1, 1)
    buttonText:SetText("Konfiguration öffnen")

    openButton:SetScript("OnClick", function()
        GladiusMidnight:OpenConfig()
    end)

    openButton:SetScript("OnEnter", function(self)
        self:SetBackdropColor(COLORS.accentLight.r * 0.8, COLORS.accentLight.g * 0.8, COLORS.accentLight.b * 0.8, 1)
    end)

    openButton:SetScript("OnLeave", function(self)
        self:SetBackdropColor(COLORS.accent.r * 0.6, COLORS.accent.g * 0.6, COLORS.accent.b * 0.6, 0.9)
    end)

    -- Register with Settings API
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

-- Initialize on addon load
local configLoader = CreateFrame("Frame")
configLoader:RegisterEvent("ADDON_LOADED")
configLoader:SetScript("OnEvent", function(self, event, addon)
    if addon == "GladiusMidnight" then
        C_Timer.After(0.5, function()
            RegisterInterfaceOptions()
        end)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
