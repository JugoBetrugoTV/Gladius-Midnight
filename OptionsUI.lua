--[[
    Gladius Midnight - Custom Options UI
    ArenaCore-inspired dark theme with purple accents
]]

local addonName, addon = ...
local GladiusMidnight = addon.Core

-- ============================================================================
-- Color Palette (ArenaCore-style)
-- ============================================================================

local COLORS = {
    PRIMARY      = {0.545, 0.271, 1.000, 1},  -- #8B45FF purple accent
    TEXT         = {1.000, 1.000, 1.000, 1},
    TEXT_DIM     = {0.706, 0.706, 0.706, 1},  -- #B4B4B4
    TEXT_MUTED   = {0.502, 0.502, 0.502, 1},  -- #808080
    BG_DARK      = {0.102, 0.102, 0.102, 1},  -- #1A1A1A
    BG_MEDIUM    = {0.150, 0.150, 0.150, 1},  -- #262626
    BG_LIGHT     = {0.200, 0.200, 0.200, 1},  -- #333333
    BORDER       = {0.196, 0.196, 0.196, 1},  -- #323232
    BORDER_LIGHT = {0.278, 0.278, 0.278, 1},  -- #474747
    SUCCESS      = {0.133, 0.667, 0.267, 1},  -- Green
    DANGER       = {0.863, 0.176, 0.176, 1},  -- Red
}

-- ============================================================================
-- Layout Constants
-- ============================================================================

local UI_WIDTH = 700
local UI_HEIGHT = 550
local HEADER_HEIGHT = 50
local SIDEBAR_WIDTH = 180
local PADDING = 8

-- ============================================================================
-- UI Helper Functions
-- ============================================================================

local function CreateFlatTexture(parent, layer, sublevel, color, alpha)
    if not parent then return nil end
    local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
    if sublevel then texture:SetDrawLayer(layer or "BACKGROUND", sublevel) end
    if color and type(color) == "table" then
        texture:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
    end
    return texture
end

local function CreateStyledText(parent, text, size, color, layer)
    if not parent then return nil end
    local fontString = parent:CreateFontString(nil, layer or "OVERLAY")
    fontString:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "")
    fontString:SetText(text or "")
    if color and type(color) == "table" then
        fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end
    return fontString
end

-- ============================================================================
-- Styled Checkbox
-- ============================================================================

local function CreateStyledCheckbox(parent, size, checked, onChange)
    local checkbox = CreateFrame("CheckButton", nil, parent)
    checkbox:SetSize(size or 20, size or 20)

    -- Background
    local bg = CreateFlatTexture(checkbox, "BACKGROUND", 1, COLORS.BG_DARK, 1)
    bg:SetAllPoints()

    -- Border
    local border = CreateFlatTexture(checkbox, "BORDER", 1, COLORS.BORDER_LIGHT, 1)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)

    -- Inner background
    local inner = CreateFlatTexture(checkbox, "ARTWORK", 0, COLORS.BG_MEDIUM, 1)
    inner:SetAllPoints()

    -- Checkmark (purple when checked)
    local checkmark = checkbox:CreateTexture(nil, "OVERLAY")
    checkmark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkmark:SetPoint("CENTER")
    checkmark:SetSize((size or 20) + 4, (size or 20) + 4)
    checkmark:SetVertexColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 1)
    checkbox:SetCheckedTexture(checkmark)

    if checked then checkbox:SetChecked(true) end

    -- Hover effect
    checkbox:SetScript("OnEnter", function(self)
        inner:SetColorTexture(COLORS.BG_LIGHT[1], COLORS.BG_LIGHT[2], COLORS.BG_LIGHT[3], 1)
    end)
    checkbox:SetScript("OnLeave", function(self)
        inner:SetColorTexture(COLORS.BG_MEDIUM[1], COLORS.BG_MEDIUM[2], COLORS.BG_MEDIUM[3], 1)
    end)

    if onChange then
        checkbox:SetScript("OnClick", function(self)
            onChange(self:GetChecked())
        end)
    end

    return checkbox
end

-- ============================================================================
-- Styled Slider
-- ============================================================================

local function CreateStyledSlider(parent, width, min, max, value, step, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width or 150, 20)

    -- Track background
    local track = CreateFlatTexture(container, "BACKGROUND", 1, COLORS.BG_DARK, 1)
    track:SetPoint("LEFT", 0, 0)
    track:SetPoint("RIGHT", 0, 0)
    track:SetHeight(6)

    -- Track border
    local trackBorder = CreateFlatTexture(container, "BORDER", 0, COLORS.BORDER, 1)
    trackBorder:SetPoint("TOPLEFT", track, -1, 1)
    trackBorder:SetPoint("BOTTOMRIGHT", track, 1, -1)

    -- Slider
    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetPoint("TOPLEFT", 0, 0)
    slider:SetPoint("BOTTOMRIGHT", 0, 0)
    slider:SetMinMaxValues(min or 0, max or 100)
    slider:SetValue(value or min or 0)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouseWheel(true)

    -- Thumb texture (purple)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(14, 14)
    thumb:SetColorTexture(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 1)
    slider:SetThumbTexture(thumb)

    -- Fill bar (shows progress)
    local fill = CreateFlatTexture(slider, "ARTWORK", 1, COLORS.PRIMARY, 0.5)
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)
    fill:SetHeight(6)

    local function UpdateFill()
        local minVal, maxVal = slider:GetMinMaxValues()
        local curVal = slider:GetValue()
        local pct = (curVal - minVal) / (maxVal - minVal)
        fill:SetWidth(math.max(1, track:GetWidth() * pct))
    end

    slider:SetScript("OnValueChanged", function(self, val)
        UpdateFill()
        if onChange then onChange(val) end
    end)

    slider:SetScript("OnMouseWheel", function(self, delta)
        local curVal = self:GetValue()
        local stepVal = step or 1
        self:SetValue(curVal + (delta * stepVal))
    end)

    container:SetScript("OnSizeChanged", UpdateFill)
    C_Timer.After(0.1, UpdateFill)

    container.slider = slider
    return container
end

-- ============================================================================
-- Styled Dropdown
-- ============================================================================

local function CreateStyledDropdown(parent, width, options, currentValue, onChange)
    local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    dropdown:SetSize(width or 150, 26)
    dropdown:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(COLORS.BG_DARK[1], COLORS.BG_DARK[2], COLORS.BG_DARK[3], 1)
    dropdown:SetBackdropBorderColor(COLORS.BORDER_LIGHT[1], COLORS.BORDER_LIGHT[2], COLORS.BORDER_LIGHT[3], 1)

    -- Selected text
    local text = CreateStyledText(dropdown, currentValue or "Select...", 11, COLORS.TEXT, "OVERLAY")
    text:SetPoint("LEFT", 10, 0)
    text:SetPoint("RIGHT", -25, 0)
    text:SetJustifyH("LEFT")
    dropdown.text = text

    -- Arrow
    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    arrow:SetText("v")
    arrow:SetTextColor(COLORS.TEXT_DIM[1], COLORS.TEXT_DIM[2], COLORS.TEXT_DIM[3], 1)
    arrow:SetPoint("RIGHT", -8, 0)

    -- Menu frame
    local menu = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menu:SetWidth(width or 150)
    menu:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    menu:SetBackdropColor(COLORS.BG_DARK[1], COLORS.BG_DARK[2], COLORS.BG_DARK[3], 0.95)
    menu:SetBackdropBorderColor(COLORS.BORDER_LIGHT[1], COLORS.BORDER_LIGHT[2], COLORS.BORDER_LIGHT[3], 1)
    menu:SetFrameStrata("TOOLTIP")
    menu:Hide()

    -- Create menu items
    local menuHeight = 4
    for displayText, internalValue in pairs(options) do
        local item = CreateFrame("Button", nil, menu)
        item:SetHeight(22)
        item:SetPoint("TOPLEFT", 2, -menuHeight)
        item:SetPoint("TOPRIGHT", -2, -menuHeight)

        local itemText = CreateStyledText(item, displayText, 11, COLORS.TEXT_DIM, "OVERLAY")
        itemText:SetPoint("LEFT", 8, 0)

        local highlight = CreateFlatTexture(item, "HIGHLIGHT", 0, COLORS.PRIMARY, 0.3)
        highlight:SetAllPoints()

        item:SetScript("OnClick", function()
            text:SetText(displayText)
            dropdown.value = internalValue
            menu:Hide()
            if onChange then onChange(internalValue) end
        end)

        item:SetScript("OnEnter", function()
            itemText:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
        end)
        item:SetScript("OnLeave", function()
            itemText:SetTextColor(COLORS.TEXT_DIM[1], COLORS.TEXT_DIM[2], COLORS.TEXT_DIM[3], 1)
        end)

        menuHeight = menuHeight + 22
    end
    menu:SetHeight(menuHeight + 4)

    -- Toggle menu on click
    dropdown:EnableMouse(true)
    dropdown:SetScript("OnMouseDown", function()
        if menu:IsShown() then
            menu:Hide()
        else
            menu:Show()
        end
    end)

    -- Hover effect
    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        if not menu:IsShown() then
            self:SetBackdropBorderColor(COLORS.BORDER_LIGHT[1], COLORS.BORDER_LIGHT[2], COLORS.BORDER_LIGHT[3], 1)
        end
    end)

    dropdown.value = currentValue
    return dropdown
end

-- ============================================================================
-- Section Group Box
-- ============================================================================

local function CreateSectionBox(parent, title, height)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section:SetHeight(height or 100)
    section:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    section:SetBackdropColor(COLORS.BG_DARK[1], COLORS.BG_DARK[2], COLORS.BG_DARK[3], 0.8)
    section:SetBackdropBorderColor(COLORS.BORDER[1], COLORS.BORDER[2], COLORS.BORDER[3], 1)

    -- Purple accent line at top
    local accent = CreateFlatTexture(section, "OVERLAY", 2, COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(2)

    -- Title
    if title then
        local titleText = CreateStyledText(section, title, 12, COLORS.PRIMARY, "OVERLAY")
        titleText:SetPoint("TOPLEFT", 12, -10)
    end

    return section
end

-- ============================================================================
-- Navigation Button
-- ============================================================================

local function CreateNavButton(parent, text, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(SIDEBAR_WIDTH - 20, 32)

    -- Background
    local bg = CreateFlatTexture(btn, "BACKGROUND", 0, COLORS.BG_DARK, 1)
    bg:SetAllPoints()
    btn.bg = bg

    -- Purple indicator (left bar when active)
    local indicator = CreateFlatTexture(btn, "OVERLAY", 2, COLORS.PRIMARY, 1)
    indicator:SetPoint("LEFT", 0, 0)
    indicator:SetSize(3, 32)
    indicator:Hide()
    btn.indicator = indicator

    -- Label
    local label = CreateStyledText(btn, text, 12, COLORS.TEXT_DIM, "OVERLAY")
    label:SetPoint("LEFT", 15, 0)
    btn.label = label

    btn.isActive = false

    function btn:SetActive(active)
        self.isActive = active
        if active then
            self.bg:SetColorTexture(COLORS.BG_LIGHT[1], COLORS.BG_LIGHT[2], COLORS.BG_LIGHT[3], 1)
            self.indicator:Show()
            self.label:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
        else
            self.bg:SetColorTexture(COLORS.BG_DARK[1], COLORS.BG_DARK[2], COLORS.BG_DARK[3], 1)
            self.indicator:Hide()
            self.label:SetTextColor(COLORS.TEXT_DIM[1], COLORS.TEXT_DIM[2], COLORS.TEXT_DIM[3], 1)
        end
    end

    btn:SetScript("OnEnter", function(self)
        if not self.isActive then
            self.bg:SetColorTexture(COLORS.BG_MEDIUM[1], COLORS.BG_MEDIUM[2], COLORS.BG_MEDIUM[3], 1)
            self.label:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
        end
    end)

    btn:SetScript("OnLeave", function(self)
        if not self.isActive then
            self.bg:SetColorTexture(COLORS.BG_DARK[1], COLORS.BG_DARK[2], COLORS.BG_DARK[3], 1)
            self.label:SetTextColor(COLORS.TEXT_DIM[1], COLORS.TEXT_DIM[2], COLORS.TEXT_DIM[3], 1)
        end
    end)

    btn:SetScript("OnClick", onClick)

    return btn
end

-- ============================================================================
-- Main Options Frame
-- ============================================================================

local OptionsUI = {}
addon.OptionsUI = OptionsUI

function OptionsUI:CreateMainFrame()
    if self.frame then return self.frame end

    -- Main frame
    local frame = CreateFrame("Frame", "GladiusMidnightOptionsUI", UIParent, "BackdropTemplate")
    frame:SetSize(UI_WIDTH, UI_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    frame:Hide()

    -- Background
    local bg = CreateFlatTexture(frame, "BACKGROUND", 0, COLORS.BG_MEDIUM, 1)
    bg:SetAllPoints()

    -- Border
    frame:SetBackdrop({
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    frame:SetBackdropBorderColor(COLORS.BORDER[1], COLORS.BORDER[2], COLORS.BORDER[3], 1)

    self.frame = frame
    self:CreateHeader(frame)
    self:CreateSidebar(frame)
    self:CreateContentArea(frame)

    return frame
end

function OptionsUI:CreateHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT", PADDING, -PADDING)
    header:SetPoint("TOPRIGHT", -PADDING, -PADDING)
    header:SetHeight(HEADER_HEIGHT)

    -- Header background
    local bg = CreateFlatTexture(header, "BACKGROUND", 0, COLORS.BG_DARK, 1)
    bg:SetAllPoints()

    -- Purple accent line
    local accent = CreateFlatTexture(header, "OVERLAY", 2, COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(2)

    -- Title
    local title = CreateStyledText(header, "GLADIUS MIDNIGHT", 18, COLORS.TEXT, "OVERLAY")
    title:SetPoint("LEFT", 20, 0)

    -- Subtitle
    local subtitle = CreateStyledText(header, "Arena Frames for Midnight 12.0", 10, COLORS.TEXT_DIM, "OVERLAY")
    subtitle:SetPoint("LEFT", title, "RIGHT", 15, 0)

    -- Version badge
    local version = CreateStyledText(header, "v1.0", 10, COLORS.PRIMARY, "OVERLAY")
    version:SetPoint("LEFT", subtitle, "RIGHT", 10, 0)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("RIGHT", -10, 0)

    local closeBg = CreateFlatTexture(closeBtn, "BACKGROUND", 0, COLORS.BG_MEDIUM, 1)
    closeBg:SetAllPoints()

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    closeText:SetText("x")
    closeText:SetTextColor(COLORS.TEXT_DIM[1], COLORS.TEXT_DIM[2], COLORS.TEXT_DIM[3], 1)
    closeText:SetPoint("CENTER", 0, 1)

    closeBtn:SetScript("OnEnter", function()
        closeBg:SetColorTexture(COLORS.DANGER[1], COLORS.DANGER[2], COLORS.DANGER[3], 0.8)
        closeText:SetTextColor(1, 1, 1, 1)
    end)
    closeBtn:SetScript("OnLeave", function()
        closeBg:SetColorTexture(COLORS.BG_MEDIUM[1], COLORS.BG_MEDIUM[2], COLORS.BG_MEDIUM[3], 1)
        closeText:SetTextColor(COLORS.TEXT_DIM[1], COLORS.TEXT_DIM[2], COLORS.TEXT_DIM[3], 1)
    end)
    closeBtn:SetScript("OnClick", function()
        parent:Hide()
    end)

    -- Test button
    local testBtn = CreateFrame("Button", nil, header, "BackdropTemplate")
    testBtn:SetSize(80, 28)
    testBtn:SetPoint("RIGHT", closeBtn, "LEFT", -15, 0)
    testBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    testBtn:SetBackdropColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.8)
    testBtn:SetBackdropBorderColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 1)

    local testText = CreateStyledText(testBtn, "Test", 11, COLORS.TEXT, "OVERLAY")
    testText:SetPoint("CENTER")

    testBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(COLORS.PRIMARY[1] * 1.2, COLORS.PRIMARY[2] * 1.2, COLORS.PRIMARY[3] * 1.2, 1)
    end)
    testBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.8)
    end)
    testBtn:SetScript("OnClick", function()
        GladiusMidnight:ToggleTest()
    end)

    self.header = header
end

function OptionsUI:CreateSidebar(parent)
    local sidebar = CreateFrame("Frame", nil, parent)
    sidebar:SetPoint("TOPLEFT", PADDING, -(PADDING + HEADER_HEIGHT + 8))
    sidebar:SetPoint("BOTTOMLEFT", PADDING, PADDING)
    sidebar:SetWidth(SIDEBAR_WIDTH)

    -- Background
    local bg = CreateFlatTexture(sidebar, "BACKGROUND", 0, COLORS.BG_DARK, 1)
    bg:SetAllPoints()

    -- Section title
    local sectionTitle = CreateStyledText(sidebar, "EINSTELLUNGEN", 10, COLORS.PRIMARY, "OVERLAY")
    sectionTitle:SetPoint("TOPLEFT", 10, -10)

    -- Divider line
    local divider = CreateFlatTexture(sidebar, "OVERLAY", 1, COLORS.BORDER_LIGHT, 0.5)
    divider:SetPoint("TOPLEFT", 10, -28)
    divider:SetPoint("TOPRIGHT", -10, -28)
    divider:SetHeight(1)

    -- Navigation buttons
    local navItems = {
        { text = "Allgemein", page = "general" },
        { text = "Grosse & Position", page = "size" },
        { text = "Module", page = "modules" },
        { text = "Visuelle Effekte", page = "visual" },
        { text = "Klassen Icon", page = "classIcon" },
        { text = "Lebensanzeige", page = "health" },
        { text = "Ressourcen", page = "power" },
        { text = "Trinket & Racial", page = "cooldowns" },
        { text = "DR Tracker", page = "drTracker" },
        { text = "Cast Bar", page = "castBar" },
        { text = "Auras / CC", page = "auras" },
        { text = "Kick Tracker", page = "kicks" },
    }

    self.navButtons = {}
    local y = -40

    for _, item in ipairs(navItems) do
        local btn = CreateNavButton(sidebar, item.text, function()
            self:ShowPage(item.page)
        end)
        btn:SetPoint("TOPLEFT", 10, y)
        btn.page = item.page
        table.insert(self.navButtons, btn)
        y = y - 34
    end

    -- Right border
    local rightBorder = CreateFlatTexture(sidebar, "OVERLAY", 1, COLORS.BORDER_LIGHT, 0.5)
    rightBorder:SetPoint("TOPRIGHT", 0, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", 0, 0)
    rightBorder:SetWidth(1)

    self.sidebar = sidebar
end

function OptionsUI:CreateContentArea(parent)
    local content = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    content:SetPoint("TOPLEFT", SIDEBAR_WIDTH + PADDING + 10, -(PADDING + HEADER_HEIGHT + 8))
    content:SetPoint("BOTTOMRIGHT", -PADDING - 25, PADDING)

    -- Hide default scrollbar styling
    local scrollBar = content.ScrollBar
    if scrollBar then
        scrollBar:SetWidth(12)
        -- Restyle the scrollbar thumb
        local thumb = scrollBar:GetThumbTexture()
        if thumb then
            thumb:SetColorTexture(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.8)
            thumb:SetWidth(10)
        end
    end

    -- Scroll child
    local scrollChild = CreateFrame("Frame", nil, content)
    scrollChild:SetWidth(content:GetWidth() - 20)
    scrollChild:SetHeight(1) -- Will be set dynamically
    content:SetScrollChild(scrollChild)

    self.content = content
    self.scrollChild = scrollChild
    self.pages = {}

    -- Create all pages
    self:CreateGeneralPage()
    self:CreateSizePage()
    self:CreateModulesPage()
    self:CreateVisualPage()
    self:CreateClassIconPage()
    self:CreateHealthPage()
    self:CreatePowerPage()
    self:CreateCooldownsPage()
    self:CreateDRTrackerPage()
    self:CreateCastBarPage()
    self:CreateAurasPage()
    self:CreateKicksPage()

    -- Show default page
    self:ShowPage("general")
end

-- ============================================================================
-- Page Creation Functions
-- ============================================================================

function OptionsUI:CreateGeneralPage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(300)
    page:Hide()

    local section = CreateSectionBox(page, "ALLGEMEINE EINSTELLUNGEN", 280)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local y = -40

    -- Enabled checkbox
    local enabledLabel = CreateStyledText(section, "Addon aktiviert", 12, COLORS.TEXT, "OVERLAY")
    enabledLabel:SetPoint("TOPLEFT", 15, y)
    local enabledCheck = CreateStyledCheckbox(section, 20, GladiusMidnight.db.profile.enabled, function(val)
        GladiusMidnight.db.profile.enabled = val
        GladiusMidnight:CheckArenaStatus()
    end)
    enabledCheck:SetPoint("TOPRIGHT", -15, y + 2)
    y = y - 35

    -- Locked checkbox
    local lockedLabel = CreateStyledText(section, "Frames fixiert", 12, COLORS.TEXT, "OVERLAY")
    lockedLabel:SetPoint("TOPLEFT", 15, y)
    local lockedCheck = CreateStyledCheckbox(section, 20, GladiusMidnight.db.profile.locked, function(val)
        GladiusMidnight.db.profile.locked = val
    end)
    lockedCheck:SetPoint("TOPRIGHT", -15, y + 2)
    y = y - 35

    -- Minimap icon checkbox
    local minimapLabel = CreateStyledText(section, "Minimap Icon", 12, COLORS.TEXT, "OVERLAY")
    minimapLabel:SetPoint("TOPLEFT", 15, y)
    local minimapCheck = CreateStyledCheckbox(section, 20, not GladiusMidnight.db.profile.minimap.hide, function(val)
        GladiusMidnight.db.profile.minimap.hide = not val
        local LDBIcon = LibStub("LibDBIcon-1.0", true)
        if LDBIcon then
            if val then LDBIcon:Show("GladiusMidnight") else LDBIcon:Hide("GladiusMidnight") end
        end
    end)
    minimapCheck:SetPoint("TOPRIGHT", -15, y + 2)
    y = y - 50

    -- Buttons row
    local testBtn = CreateFrame("Button", nil, section, "BackdropTemplate")
    testBtn:SetSize(120, 32)
    testBtn:SetPoint("TOPLEFT", 15, y)
    testBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    testBtn:SetBackdropColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.8)
    testBtn:SetBackdropBorderColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 1)
    local testText = CreateStyledText(testBtn, "Test Modus", 11, COLORS.TEXT, "OVERLAY")
    testText:SetPoint("CENTER")
    testBtn:SetScript("OnClick", function() GladiusMidnight:ToggleTest() end)

    local resetBtn = CreateFrame("Button", nil, section, "BackdropTemplate")
    resetBtn:SetSize(120, 32)
    resetBtn:SetPoint("LEFT", testBtn, "RIGHT", 15, 0)
    resetBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    resetBtn:SetBackdropColor(COLORS.DANGER[1], COLORS.DANGER[2], COLORS.DANGER[3], 0.6)
    resetBtn:SetBackdropBorderColor(COLORS.DANGER[1], COLORS.DANGER[2], COLORS.DANGER[3], 1)
    local resetText = CreateStyledText(resetBtn, "Zurucksetzen", 11, COLORS.TEXT, "OVERLAY")
    resetText:SetPoint("CENTER")
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("GLADIUS_MIDNIGHT_RESET")
    end)

    self.pages["general"] = page
end

function OptionsUI:CreateSizePage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(400)
    page:Hide()

    local section = CreateSectionBox(page, "GROSSE & POSITION", 380)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local y = -40

    -- Scale slider
    local scaleLabel = CreateStyledText(section, "Skalierung", 12, COLORS.TEXT, "OVERLAY")
    scaleLabel:SetPoint("TOPLEFT", 15, y)
    local scaleValue = CreateStyledText(section, string.format("%.2f", GladiusMidnight.db.profile.scale), 11, COLORS.TEXT_DIM, "OVERLAY")
    scaleValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local scaleSlider = CreateStyledSlider(section, 300, 0.5, 2.0, GladiusMidnight.db.profile.scale, 0.05, function(val)
        GladiusMidnight.db.profile.scale = val
        scaleValue:SetText(string.format("%.2f", val))
        GladiusMidnight:UpdateAllFrames()
    end)
    scaleSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Frame width slider
    local widthLabel = CreateStyledText(section, "Breite", 12, COLORS.TEXT, "OVERLAY")
    widthLabel:SetPoint("TOPLEFT", 15, y)
    local widthValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.frameWidth), 11, COLORS.TEXT_DIM, "OVERLAY")
    widthValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local widthSlider = CreateStyledSlider(section, 300, 100, 400, GladiusMidnight.db.profile.frameWidth, 5, function(val)
        GladiusMidnight.db.profile.frameWidth = val
        widthValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    widthSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Frame height slider
    local heightLabel = CreateStyledText(section, "Hohe", 12, COLORS.TEXT, "OVERLAY")
    heightLabel:SetPoint("TOPLEFT", 15, y)
    local heightValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.frameHeight), 11, COLORS.TEXT_DIM, "OVERLAY")
    heightValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local heightSlider = CreateStyledSlider(section, 300, 30, 100, GladiusMidnight.db.profile.frameHeight, 2, function(val)
        GladiusMidnight.db.profile.frameHeight = val
        heightValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    heightSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Spacing slider
    local spacingLabel = CreateStyledText(section, "Abstand", 12, COLORS.TEXT, "OVERLAY")
    spacingLabel:SetPoint("TOPLEFT", 15, y)
    local spacingValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.spacing), 11, COLORS.TEXT_DIM, "OVERLAY")
    spacingValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local spacingSlider = CreateStyledSlider(section, 300, 0, 30, GladiusMidnight.db.profile.spacing, 1, function(val)
        GladiusMidnight.db.profile.spacing = val
        spacingValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:PositionFrames()
    end)
    spacingSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Growth direction dropdown
    local growLabel = CreateStyledText(section, "Wachstumsrichtung", 12, COLORS.TEXT, "OVERLAY")
    growLabel:SetPoint("TOPLEFT", 15, y)
    y = y - 25
    local growOptions = {
        ["Nach unten"] = "DOWN",
        ["Nach oben"] = "UP",
        ["Nach links"] = "LEFT",
        ["Nach rechts"] = "RIGHT",
    }
    local currentGrowText = "Nach unten"
    for text, val in pairs(growOptions) do
        if val == GladiusMidnight.db.profile.growDirection then currentGrowText = text end
    end
    local growDropdown = CreateStyledDropdown(section, 200, growOptions, currentGrowText, function(val)
        GladiusMidnight.db.profile.growDirection = val
        GladiusMidnight:PositionFrames()
    end)
    growDropdown:SetPoint("TOPLEFT", 15, y)

    self.pages["size"] = page
end

function OptionsUI:CreateModulesPage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(450)
    page:Hide()

    local section = CreateSectionBox(page, "MODULE", 430)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local modules = {
        { key = "classIcon", label = "Klassen Icon" },
        { key = "health", label = "Lebensanzeige" },
        { key = "power", label = "Ressourcenanzeige" },
        { key = "trinket", label = "Trinket Tracker" },
        { key = "racial", label = "Racial Tracker" },
        { key = "drTracker", label = "DR Tracker" },
        { key = "castBar", label = "Cast Bar" },
        { key = "auras", label = "Auras / CC Anzeige" },
        { key = "kicks", label = "Kick Tracker" },
    }

    local y = -40
    for _, mod in ipairs(modules) do
        local label = CreateStyledText(section, mod.label, 12, COLORS.TEXT, "OVERLAY")
        label:SetPoint("TOPLEFT", 15, y)
        local check = CreateStyledCheckbox(section, 20, GladiusMidnight.db.profile.modules[mod.key], function(val)
            GladiusMidnight.db.profile.modules[mod.key] = val
            GladiusMidnight:UpdateAllFrames()
        end)
        check:SetPoint("TOPRIGHT", -15, y + 2)
        y = y - 35
    end

    self.pages["modules"] = page
end

function OptionsUI:CreateVisualPage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(200)
    page:Hide()

    local section = CreateSectionBox(page, "VISUELLE EFFEKTE", 180)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local visuals = {
        { key = "targetHighlight", label = "Target Highlight" },
        { key = "immunityGlow", label = "Immunity Glow" },
        { key = "hideBlizzardFrames", label = "Blizzard Frames verstecken" },
    }

    local y = -40
    for _, vis in ipairs(visuals) do
        local label = CreateStyledText(section, vis.label, 12, COLORS.TEXT, "OVERLAY")
        label:SetPoint("TOPLEFT", 15, y)
        local check = CreateStyledCheckbox(section, 20, GladiusMidnight.db.profile[vis.key], function(val)
            GladiusMidnight.db.profile[vis.key] = val
            if vis.key == "hideBlizzardFrames" then
                GladiusMidnight:HideBlizzardFrames()
            elseif vis.key == "targetHighlight" then
                GladiusMidnight:UpdateTargetHighlight()
            end
        end)
        check:SetPoint("TOPRIGHT", -15, y + 2)
        y = y - 35
    end

    self.pages["visual"] = page
end

function OptionsUI:CreateClassIconPage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(220)
    page:Hide()

    local section = CreateSectionBox(page, "KLASSEN ICON", 200)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local y = -40

    -- Size slider
    local sizeLabel = CreateStyledText(section, "Grosse", 12, COLORS.TEXT, "OVERLAY")
    sizeLabel:SetPoint("TOPLEFT", 15, y)
    local sizeValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.classIcon.size), 11, COLORS.TEXT_DIM, "OVERLAY")
    sizeValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local sizeSlider = CreateStyledSlider(section, 300, 20, 80, GladiusMidnight.db.profile.classIcon.size, 2, function(val)
        GladiusMidnight.db.profile.classIcon.size = val
        sizeValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    sizeSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Show spec checkbox
    local specLabel = CreateStyledText(section, "Spec Icon anzeigen", 12, COLORS.TEXT, "OVERLAY")
    specLabel:SetPoint("TOPLEFT", 15, y)
    local specCheck = CreateStyledCheckbox(section, 20, GladiusMidnight.db.profile.classIcon.showSpec, function(val)
        GladiusMidnight.db.profile.classIcon.showSpec = val
        GladiusMidnight:UpdateAllFrames()
    end)
    specCheck:SetPoint("TOPRIGHT", -15, y + 2)
    y = y - 40

    -- Position dropdown
    local posLabel = CreateStyledText(section, "Position", 12, COLORS.TEXT, "OVERLAY")
    posLabel:SetPoint("TOPLEFT", 15, y)
    y = y - 25
    local posOptions = { ["Links"] = "LEFT", ["Rechts"] = "RIGHT" }
    local currentPosText = GladiusMidnight.db.profile.classIcon.position == "RIGHT" and "Rechts" or "Links"
    local posDropdown = CreateStyledDropdown(section, 150, posOptions, currentPosText, function(val)
        GladiusMidnight.db.profile.classIcon.position = val
        GladiusMidnight:UpdateAllFrames()
    end)
    posDropdown:SetPoint("TOPLEFT", 15, y)

    self.pages["classIcon"] = page
end

function OptionsUI:CreateHealthPage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(250)
    page:Hide()

    local section = CreateSectionBox(page, "LEBENSANZEIGE", 230)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local y = -40

    -- Height slider
    local heightLabel = CreateStyledText(section, "Hohe", 12, COLORS.TEXT, "OVERLAY")
    heightLabel:SetPoint("TOPLEFT", 15, y)
    local heightValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.health.height), 11, COLORS.TEXT_DIM, "OVERLAY")
    heightValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local heightSlider = CreateStyledSlider(section, 300, 10, 50, GladiusMidnight.db.profile.health.height, 2, function(val)
        GladiusMidnight.db.profile.health.height = val
        heightValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    heightSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Checkboxes
    local healthOptions = {
        { key = "showText", label = "Prozent anzeigen" },
        { key = "showName", label = "Spielername anzeigen" },
        { key = "colorByClass", label = "Klassenfarbe" },
    }

    for _, opt in ipairs(healthOptions) do
        local label = CreateStyledText(section, opt.label, 12, COLORS.TEXT, "OVERLAY")
        label:SetPoint("TOPLEFT", 15, y)
        local check = CreateStyledCheckbox(section, 20, GladiusMidnight.db.profile.health[opt.key], function(val)
            GladiusMidnight.db.profile.health[opt.key] = val
            GladiusMidnight:UpdateAllFrames()
        end)
        check:SetPoint("TOPRIGHT", -15, y + 2)
        y = y - 35
    end

    self.pages["health"] = page
end

function OptionsUI:CreatePowerPage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(180)
    page:Hide()

    local section = CreateSectionBox(page, "RESSOURCEN", 160)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local y = -40

    -- Height slider
    local heightLabel = CreateStyledText(section, "Hohe", 12, COLORS.TEXT, "OVERLAY")
    heightLabel:SetPoint("TOPLEFT", 15, y)
    local heightValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.power.height), 11, COLORS.TEXT_DIM, "OVERLAY")
    heightValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local heightSlider = CreateStyledSlider(section, 300, 4, 20, GladiusMidnight.db.profile.power.height, 1, function(val)
        GladiusMidnight.db.profile.power.height = val
        heightValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    heightSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Show text checkbox
    local textLabel = CreateStyledText(section, "Prozent anzeigen", 12, COLORS.TEXT, "OVERLAY")
    textLabel:SetPoint("TOPLEFT", 15, y)
    local textCheck = CreateStyledCheckbox(section, 20, GladiusMidnight.db.profile.power.showText, function(val)
        GladiusMidnight.db.profile.power.showText = val
        GladiusMidnight:UpdateAllFrames()
    end)
    textCheck:SetPoint("TOPRIGHT", -15, y + 2)

    self.pages["power"] = page
end

function OptionsUI:CreateCooldownsPage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(300)
    page:Hide()

    local section = CreateSectionBox(page, "TRINKET & RACIAL", 280)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local y = -40

    -- Trinket size
    local trinketSizeLabel = CreateStyledText(section, "Trinket Icon Grosse", 12, COLORS.TEXT, "OVERLAY")
    trinketSizeLabel:SetPoint("TOPLEFT", 15, y)
    local trinketSizeValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.trinket.size), 11, COLORS.TEXT_DIM, "OVERLAY")
    trinketSizeValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local trinketSizeSlider = CreateStyledSlider(section, 300, 16, 50, GladiusMidnight.db.profile.trinket.size, 2, function(val)
        GladiusMidnight.db.profile.trinket.size = val
        trinketSizeValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    trinketSizeSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Trinket position
    local trinketPosLabel = CreateStyledText(section, "Trinket Position", 12, COLORS.TEXT, "OVERLAY")
    trinketPosLabel:SetPoint("TOPLEFT", 15, y)
    y = y - 25
    local trinketPosOptions = { ["Links"] = "LEFT", ["Rechts"] = "RIGHT" }
    local currentTrinketPos = GladiusMidnight.db.profile.trinket.position == "RIGHT" and "Rechts" or "Links"
    local trinketPosDropdown = CreateStyledDropdown(section, 150, trinketPosOptions, currentTrinketPos, function(val)
        GladiusMidnight.db.profile.trinket.position = val
        GladiusMidnight:UpdateAllFrames()
    end)
    trinketPosDropdown:SetPoint("TOPLEFT", 15, y)
    y = y - 50

    -- Racial size
    local racialSizeLabel = CreateStyledText(section, "Racial Icon Grosse", 12, COLORS.TEXT, "OVERLAY")
    racialSizeLabel:SetPoint("TOPLEFT", 15, y)
    local racialSizeValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.racial.size), 11, COLORS.TEXT_DIM, "OVERLAY")
    racialSizeValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local racialSizeSlider = CreateStyledSlider(section, 300, 16, 50, GladiusMidnight.db.profile.racial.size, 2, function(val)
        GladiusMidnight.db.profile.racial.size = val
        racialSizeValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    racialSizeSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Racial position
    local racialPosLabel = CreateStyledText(section, "Racial Position", 12, COLORS.TEXT, "OVERLAY")
    racialPosLabel:SetPoint("TOPLEFT", 15, y)
    y = y - 25
    local racialPosOptions = { ["Links"] = "LEFT", ["Rechts"] = "RIGHT" }
    local currentRacialPos = GladiusMidnight.db.profile.racial.position == "RIGHT" and "Rechts" or "Links"
    local racialPosDropdown = CreateStyledDropdown(section, 150, racialPosOptions, currentRacialPos, function(val)
        GladiusMidnight.db.profile.racial.position = val
        GladiusMidnight:UpdateAllFrames()
    end)
    racialPosDropdown:SetPoint("TOPLEFT", 15, y)

    self.pages["cooldowns"] = page
end

function OptionsUI:CreateDRTrackerPage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(180)
    page:Hide()

    local section = CreateSectionBox(page, "DR TRACKER", 160)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local y = -40

    -- Icon size
    local sizeLabel = CreateStyledText(section, "Icon Grosse", 12, COLORS.TEXT, "OVERLAY")
    sizeLabel:SetPoint("TOPLEFT", 15, y)
    local sizeValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.drTracker.iconSize), 11, COLORS.TEXT_DIM, "OVERLAY")
    sizeValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local sizeSlider = CreateStyledSlider(section, 300, 16, 40, GladiusMidnight.db.profile.drTracker.iconSize, 2, function(val)
        GladiusMidnight.db.profile.drTracker.iconSize = val
        sizeValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    sizeSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Show timer checkbox
    local timerLabel = CreateStyledText(section, "Timer anzeigen", 12, COLORS.TEXT, "OVERLAY")
    timerLabel:SetPoint("TOPLEFT", 15, y)
    local timerCheck = CreateStyledCheckbox(section, 20, GladiusMidnight.db.profile.drTracker.showTimer, function(val)
        GladiusMidnight.db.profile.drTracker.showTimer = val
        GladiusMidnight:UpdateAllFrames()
    end)
    timerCheck:SetPoint("TOPRIGHT", -15, y + 2)

    self.pages["drTracker"] = page
end

function OptionsUI:CreateCastBarPage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(180)
    page:Hide()

    local section = CreateSectionBox(page, "CAST BAR", 160)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local y = -40

    -- Height
    local heightLabel = CreateStyledText(section, "Hohe", 12, COLORS.TEXT, "OVERLAY")
    heightLabel:SetPoint("TOPLEFT", 15, y)
    local heightValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.castBar.height), 11, COLORS.TEXT_DIM, "OVERLAY")
    heightValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local heightSlider = CreateStyledSlider(section, 300, 10, 30, GladiusMidnight.db.profile.castBar.height, 2, function(val)
        GladiusMidnight.db.profile.castBar.height = val
        heightValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    heightSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Show icon checkbox
    local iconLabel = CreateStyledText(section, "Spell Icon anzeigen", 12, COLORS.TEXT, "OVERLAY")
    iconLabel:SetPoint("TOPLEFT", 15, y)
    local iconCheck = CreateStyledCheckbox(section, 20, GladiusMidnight.db.profile.castBar.showIcon, function(val)
        GladiusMidnight.db.profile.castBar.showIcon = val
        GladiusMidnight:UpdateAllFrames()
    end)
    iconCheck:SetPoint("TOPRIGHT", -15, y + 2)

    self.pages["castBar"] = page
end

function OptionsUI:CreateAurasPage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(180)
    page:Hide()

    local section = CreateSectionBox(page, "AURAS / CC", 160)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local y = -40

    -- Icon size
    local sizeLabel = CreateStyledText(section, "Icon Grosse", 12, COLORS.TEXT, "OVERLAY")
    sizeLabel:SetPoint("TOPLEFT", 15, y)
    local sizeValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.auras.iconSize), 11, COLORS.TEXT_DIM, "OVERLAY")
    sizeValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local sizeSlider = CreateStyledSlider(section, 300, 16, 50, GladiusMidnight.db.profile.auras.iconSize, 2, function(val)
        GladiusMidnight.db.profile.auras.iconSize = val
        sizeValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    sizeSlider:SetPoint("TOPLEFT", 15, y)
    y = y - 40

    -- Max auras
    local maxLabel = CreateStyledText(section, "Max. Auras", 12, COLORS.TEXT, "OVERLAY")
    maxLabel:SetPoint("TOPLEFT", 15, y)
    local maxValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.auras.maxAuras), 11, COLORS.TEXT_DIM, "OVERLAY")
    maxValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local maxSlider = CreateStyledSlider(section, 300, 1, 8, GladiusMidnight.db.profile.auras.maxAuras, 1, function(val)
        GladiusMidnight.db.profile.auras.maxAuras = val
        maxValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    maxSlider:SetPoint("TOPLEFT", 15, y)

    self.pages["auras"] = page
end

function OptionsUI:CreateKicksPage()
    local page = CreateFrame("Frame", nil, self.scrollChild)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetHeight(130)
    page:Hide()

    local section = CreateSectionBox(page, "KICK TRACKER", 110)
    section:SetPoint("TOPLEFT", 0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)

    local y = -40

    -- Icon size
    local sizeLabel = CreateStyledText(section, "Icon Grosse", 12, COLORS.TEXT, "OVERLAY")
    sizeLabel:SetPoint("TOPLEFT", 15, y)
    local sizeValue = CreateStyledText(section, tostring(GladiusMidnight.db.profile.kicks.size), 11, COLORS.TEXT_DIM, "OVERLAY")
    sizeValue:SetPoint("TOPRIGHT", -15, y)
    y = y - 25
    local sizeSlider = CreateStyledSlider(section, 300, 16, 40, GladiusMidnight.db.profile.kicks.size, 2, function(val)
        GladiusMidnight.db.profile.kicks.size = val
        sizeValue:SetText(tostring(math.floor(val)))
        GladiusMidnight:UpdateAllFrames()
    end)
    sizeSlider:SetPoint("TOPLEFT", 15, y)

    self.pages["kicks"] = page
end

-- ============================================================================
-- Page Navigation
-- ============================================================================

function OptionsUI:ShowPage(pageKey)
    -- Hide all pages
    for key, page in pairs(self.pages) do
        page:Hide()
    end

    -- Update nav buttons
    for _, btn in ipairs(self.navButtons) do
        btn:SetActive(btn.page == pageKey)
    end

    -- Show selected page
    if self.pages[pageKey] then
        self.pages[pageKey]:Show()
        self.scrollChild:SetHeight(self.pages[pageKey]:GetHeight())
    end

    self.currentPage = pageKey
end

-- ============================================================================
-- Toggle Function
-- ============================================================================

function OptionsUI:Toggle()
    if not self.frame then
        self:CreateMainFrame()
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

-- ============================================================================
-- Static Popup for Reset
-- ============================================================================

StaticPopupDialogs["GLADIUS_MIDNIGHT_RESET"] = {
    text = "Alle Einstellungen zurucksetzen?",
    button1 = "Ja",
    button2 = "Nein",
    OnAccept = function()
        GladiusMidnight.db:ResetProfile()
        GladiusMidnight:UpdateAllFrames()
        -- Refresh UI
        if addon.OptionsUI and addon.OptionsUI.frame then
            addon.OptionsUI.frame:Hide()
            addon.OptionsUI.frame = nil
            addon.OptionsUI.pages = {}
            addon.OptionsUI:Toggle()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- ============================================================================
-- Hook into ToggleOptions
-- ============================================================================

local origToggleOptions = GladiusMidnight.ToggleOptions
function GladiusMidnight:ToggleOptions()
    addon.OptionsUI:Toggle()
end
