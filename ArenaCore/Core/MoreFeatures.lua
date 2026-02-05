-- =============================================================
-- File: Core/MoreFeatures.lua
-- ArenaCore More Features Window
-- Smaller-scale UI for additional features
-- =============================================================

local AC = _G.ArenaCore
if not AC then return end

AC.MoreFeatures = AC.MoreFeatures or {}
local MoreFeatures = AC.MoreFeatures

-- UI Constants (smaller scale than main UI)
local WINDOW_WIDTH = 600
local WINDOW_HEIGHT = 550  -- Increased from 400 to 550 to show Profile Sharing section without scrolling
local SIDEBAR_WIDTH = 140
local HEADER_HEIGHT = 50

-- Color scheme matching main UI exactly
local _COLOR_DEFAULTS = {
PRIMARY = {0.545, 0.271, 1.000, 1},
TEXT = {1.000, 1.000, 1.000, 1},
TEXT_2 = {0.706, 0.706, 0.706, 1},
TEXT_MUTED = {0.600, 0.600, 0.600, 1},
DANGER = {0.863, 0.176, 0.176, 1},
SUCCESS = {0.133, 0.667, 0.267, 1},
WARNING = {0.800, 0.533, 0.000, 1},
BG = {0.200, 0.200, 0.200, 1},
HEADER_BG = {0.200, 0.200, 0.200, 1},
INPUT_DARK = {0.200, 0.200, 0.200, 1},
GROUP_BG = {0.200, 0.200, 0.200, 1},
BORDER = {0.196, 0.196, 0.196, 1},
BORDER_LIGHT = {0.278, 0.278, 0.278, 1},
ICON_BG = {0.220, 0.220, 0.220, 1},
NAV_ACTIVE_BG = {0.200, 0.200, 0.200, 1},
NAV_INACTIVE_BG= {0.120, 0.120, 0.120, 1},
INSET = {0.090, 0.090, 0.090, 1},
}


local COLORS = setmetatable({}, {
__index = function(_, k)
local v
if AC and AC.COLORS then v = AC.COLORS[k] end
if v ~= nil then return v end
return _COLOR_DEFAULTS[k]
end
})

local CUSTOM_FONT = "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf"

-- Feature pages data
local FEATURE_PAGES = {
    {id = "general", name = "General", icon = "Interface\\Icons\\INV_Misc_Gear_01"},
    {id = "themes", name = "Themes", icon = "Interface\\Icons\\INV_Misc_Paint_01"},
    {id = "font", name = "Font", icon = "Interface\\Icons\\INV_Inscription_Tradeskill01"},
    {id = "profiles", name = "Profiles", icon = "Interface\\Icons\\INV_Misc_Book_09"},
    {id = "feature5", name = "Coming Soon...", icon = "Interface\\Icons\\INV_Misc_QuestionMark"},
    {id = "feature6", name = "Coming Soon...", icon = "Interface\\Icons\\INV_Misc_QuestionMark"},
    {id = "feature7", name = "Coming Soon...", icon = "Interface\\Icons\\INV_Misc_QuestionMark"},
    {id = "feature8", name = "Coming Soon...", icon = "Interface\\Icons\\INV_Misc_QuestionMark"},
}

-- Create the main window frame
function MoreFeatures:CreateWindow()
    if self.window then return self.window end
    
    -- Main window frame
    local window = CreateFrame("Frame", "ArenaCoreMoreFeaturesFrame", UIParent)
    window:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    window:SetPoint("CENTER", 0, 0)
    window:SetFrameStrata("DIALOG")
    window:SetFrameLevel(50)  -- FIXED: Reduced from 100 to 50 to prevent text overlapping other UI elements
    window:EnableMouse(true)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    
    -- CRITICAL FIX: Add OnHide handler to clean up page containers
    window:SetScript("OnHide", function()
        if MoreFeatures and MoreFeatures.pageContainers then
            for _, container in pairs(MoreFeatures.pageContainers) do
                if container then
                    container:Hide()
                end
            end
        end
        
        -- CRITICAL FIX: Hide profile dropdown menu when window closes
        -- Prevents menu from persisting on screen after closing More Features
        if MoreFeatures and MoreFeatures.profileDropdown and MoreFeatures.profileDropdown.menu then
            MoreFeatures.profileDropdown.menu:Hide()
        end
    end)
    
    window:Hide()
    
    -- Window backdrop with proper border
    local border = AC:CreateFlatTexture(window, "BACKGROUND", 1, COLORS.BORDER, 1)
    border:SetAllPoints()
    
    local bg = AC:CreateFlatTexture(window, "BACKGROUND", 2, COLORS.BG, 1)
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Add window edge details like main UI
    if AC.AddWindowEdge then AC:AddWindowEdge(window, 1, 0) end

    
    self.window = window
    return window
end

-- Create the header section
function MoreFeatures:CreateHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT", 2, -2)
    header:SetPoint("TOPRIGHT", -2, -2)
    header:SetHeight(HEADER_HEIGHT)
    
    
    
    
    local headerBg = AC:CreateFlatTexture(header, "BACKGROUND", 1, COLORS.HEADER_BG, 1)
    headerBg:SetAllPoints()
    
    -- Purple accent line like main UI
    local accent = AC:CreateFlatTexture(header, "OVERLAY", 3, COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(3)
    
    -- Hairline borders
    local hbLight = AC:CreateFlatTexture(header, "OVERLAY", 2, COLORS.BORDER_LIGHT, 0.8)
    hbLight:SetPoint("BOTTOMLEFT", 0, 0)
    hbLight:SetPoint("BOTTOMRIGHT", 0, 0)
    hbLight:SetHeight(1)
    
    local hbDark = AC:CreateFlatTexture(header, "OVERLAY", 1, COLORS.BORDER, 1)
    hbDark:SetPoint("BOTTOMLEFT", 0, 1)
    hbDark:SetPoint("BOTTOMRIGHT", 0, 1)
    hbDark:SetHeight(1)
    
    -- Title text with custom font
    local title = AC:CreateStyledText(header, "Arena Core - More Features", 16, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
    title:SetPoint("LEFT", 15, 0)
    
    -- Close button with red X texture like main UI
    local closeBtn = AC:CreateTexturedButton(header, 36, 36, "", "button-close")
    closeBtn:SetPoint("RIGHT", -10, 0)
    local xText = AC:CreateStyledText(closeBtn, "×", 18, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
    xText:SetPoint("CENTER", 0, 0)
    closeBtn._xText = xText
    closeBtn:SetScript("OnClick", function() 
        parent:Hide()
        -- CRITICAL FIX: Clear all page content when window closes to prevent text leaking to other frames
        if MoreFeatures and MoreFeatures.pageContainers then
            for pageId, container in pairs(MoreFeatures.pageContainers) do
                if container then
                    container:Hide()
                end
            end
        end
    end)
    
    return header
end

-- Create the sidebar navigation
function MoreFeatures:CreateSidebar(parent)
    local sidebar = CreateFrame("Frame", nil, parent)
    sidebar:SetPoint("TOPLEFT", 2, -HEADER_HEIGHT - 2)
    sidebar:SetPoint("BOTTOMLEFT", 2, 2)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    
    local sidebarBg = AC:CreateFlatTexture(sidebar, "BACKGROUND", 1, COLORS.BG, 1)
    sidebarBg:SetAllPoints()
    
    -- Purple hairline accent on right edge like main UI
    local sAccent = AC:CreateFlatTexture(sidebar, "OVERLAY", 2, COLORS.BORDER_LIGHT, 0.6)
    sAccent:SetPoint("TOPRIGHT", -1, 0)
    sAccent:SetPoint("BOTTOMRIGHT", -1, 0)
    sAccent:SetWidth(1)
    
    -- Create navigation buttons
    self.navButtons = {}
    local buttonHeight = 35
    local buttonSpacing = 5
    
    for i, page in ipairs(FEATURE_PAGES) do
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetSize(SIDEBAR_WIDTH - 10, buttonHeight)
        btn:SetPoint("TOP", 0, -10 - (i - 1) * (buttonHeight + buttonSpacing))
        
        local bg = AC:CreateFlatTexture(btn, "BACKGROUND", 0, COLORS.NAV_INACTIVE_BG, 1)
        bg:SetAllPoints()
        
        -- Purple outline (like main UI)
        local outline = CreateFrame("Frame", nil, btn)
        outline:SetAllPoints()
        outline:Hide()
        
        local outlineTop = AC:CreateFlatTexture(outline, "OVERLAY", 3, COLORS.PRIMARY, 1)
        outlineTop:SetPoint("TOPLEFT", 0, 0)
        outlineTop:SetPoint("TOPRIGHT", 0, 0)
        outlineTop:SetHeight(2)
        
        local outlineBottom = AC:CreateFlatTexture(outline, "OVERLAY", 3, COLORS.PRIMARY, 1)
        outlineBottom:SetPoint("BOTTOMLEFT", 0, 0)
        outlineBottom:SetPoint("BOTTOMRIGHT", 0, 0)
        outlineBottom:SetHeight(2)
        
        local outlineLeft = AC:CreateFlatTexture(outline, "OVERLAY", 3, COLORS.PRIMARY, 1)
        outlineLeft:SetPoint("TOPLEFT", 0, 0)
        outlineLeft:SetPoint("BOTTOMLEFT", 0, 0)
        outlineLeft:SetWidth(2)
        
        local outlineRight = AC:CreateFlatTexture(outline, "OVERLAY", 3, COLORS.PRIMARY, 1)
        outlineRight:SetPoint("TOPRIGHT", 0, 0)
        outlineRight:SetPoint("BOTTOMRIGHT", 0, 0)
        outlineRight:SetWidth(2)
        
        local indicator = AC:CreateFlatTexture(btn, "OVERLAY", 2, COLORS.PRIMARY, 1)
        indicator:SetPoint("LEFT", -10, 0)
        indicator:SetSize(5, buttonHeight)
        indicator:Hide()
        
        local hover = AC:CreateFlatTexture(btn, "ARTWORK", 1, COLORS.BORDER_LIGHT, 0.15)
        hover:SetAllPoints()
        hover:Hide()
        
        btn.bg = bg
        btn.outline = outline
        btn.indicator = indicator
        btn.hover = hover
        
        -- Button text with custom font
        local text = AC:CreateStyledText(btn, page.name, 14, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
        text:SetPoint("CENTER", 0, 0)
        
        -- Button hover effects like main UI
        btn:SetScript("OnEnter", function(self)
            if not self.isSelected then
                self.hover:Show()
                self.indicator:SetColorTexture(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.6)
                self.indicator:Show()
                self.text:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if not self.isSelected then
                self.hover:Hide()
                self.indicator:Hide()
                self.text:SetTextColor(COLORS.TEXT_2[1], COLORS.TEXT_2[2], COLORS.TEXT_2[3], 1)
            end
        end)
        
        -- Button click handler
        btn:SetScript("OnClick", function(self)
            MoreFeatures:SelectPage(page.id)
        end)
        
        btn.pageId = page.id
        btn.text = text
        self.navButtons[page.id] = btn
    end
    
    -- Store reference but don't select yet (will be done in ShowWindow)
    self.defaultPage = "general"
    
    return sidebar
end

-- Create the content area
function MoreFeatures:CreateContentArea(parent)
    local content = CreateFrame("ScrollFrame", nil, parent)
    content:SetPoint("TOPLEFT", SIDEBAR_WIDTH + 5, -HEADER_HEIGHT - 2)
    content:SetPoint("BOTTOMRIGHT", -5, 5)
    content:EnableMouseWheel(true)
-- (intentionally blank) -- removed redundant contentBg to eliminate the background rectangle
    -- Scroll child with dynamic height
    local child = CreateFrame("Frame", nil, content)
    child:SetWidth(450)
    child:SetHeight(1)
    content:SetScrollChild(child)

    -- Content box styled like Core/UI.lua
    local contentBox = CreateFrame("Frame", nil, child)
    contentBox:SetPoint("TOPLEFT", 2, 0)
    contentBox:SetPoint("TOPRIGHT", -12, 0) -- room for scrollbar
    contentBox:SetHeight(1)

    -- Use the correct dark background fill to match the main UI
    local fill = AC:CreateFlatTexture(contentBox, "BACKGROUND", 1, COLORS.INPUT_DARK, 1)
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)

    local borderCol = COLORS.BORDER_LIGHT
    local ht = AC:CreateFlatTexture(contentBox, "OVERLAY", 6, borderCol, 0.9)
    ht:SetPoint("TOPLEFT", 0, 0); ht:SetPoint("TOPRIGHT", 0, 0); ht:SetHeight(1)
    local hb = AC:CreateFlatTexture(contentBox, "OVERLAY", 6, borderCol, 0.9)
    hb:SetPoint("BOTTOMLEFT", 0, 0); hb:SetPoint("BOTTOMRIGHT", 0, 0); hb:SetHeight(1)
    local hl = AC:CreateFlatTexture(contentBox, "OVERLAY", 6, borderCol, 0.9)
    hl:SetPoint("TOPLEFT", 0, 0); hl:SetPoint("BOTTOMLEFT", 0, 0); hl:SetWidth(1)
    local hr = AC:CreateFlatTexture(contentBox, "OVERLAY", 6, borderCol, 0.9)
    hr:SetPoint("TOPRIGHT", 0, 0); hr:SetPoint("BOTTOMRIGHT", 0, 0); hr:SetWidth(1)

    -- Custom scrollbar matching Core/UI.lua assets
    local scrollbar = CreateFrame("Slider", nil, parent)
    scrollbar:SetPoint("TOPRIGHT", -6, -HEADER_HEIGHT - 6)
    scrollbar:SetPoint("BOTTOMRIGHT", -6, 6)
    scrollbar:SetWidth(14)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetMinMaxValues(0, 1)
    scrollbar:SetValue(0)

    local trackBg = AC:CreateFlatTexture(scrollbar, "BACKGROUND", 1, COLORS.INPUT_DARK, 1)
    trackBg:SetAllPoints()
    local thumbTexture = scrollbar:CreateTexture(nil, "OVERLAY")
    thumbTexture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga")
    thumbTexture:SetWidth(12)
    thumbTexture:SetHeight(20)
    scrollbar:SetThumbTexture(thumbTexture)

    -- Hide default buttons if present
    if scrollbar.ScrollUpButton then scrollbar.ScrollUpButton:Hide() end
    if scrollbar.ScrollDownButton then scrollbar.ScrollDownButton:Hide() end

    local function UpdateScrollbar()
        local maxScroll = content:GetVerticalScrollRange()
        if maxScroll > 0 then
            scrollbar:Show()
            scrollbar:SetMinMaxValues(0, maxScroll)
            scrollbar:SetValue(content:GetVerticalScroll())
        else
            scrollbar:Hide()
        end
    end

    local function UpdateContentHeight()
        local total = 0
        for _, ch in ipairs({child:GetChildren()}) do
            if ch:IsShown() then
                local _, _, _, _, bottom = ch:GetPoint(1)
                if bottom then total = math.max(total, math.abs(bottom) + ch:GetHeight() + 16) end
            end
        end
        total = math.max(total, 600) + 40
        child:SetHeight(total)
        contentBox:SetHeight(total - 12)
        C_Timer.After(0.05, UpdateScrollbar)
    end

    scrollbar:SetScript("OnValueChanged", function(_, value)
        content:SetVerticalScroll(value)
    end)

    content:SetScript("OnScrollRangeChanged", UpdateScrollbar)
    content:SetScript("OnVerticalScroll", UpdateScrollbar)
    content:EnableMouseWheel(true)
    content:SetScript("OnMouseWheel", function(_, delta)
        local current = scrollbar:GetValue()
        local step = 20
        scrollbar:SetValue(current - (delta * step))
    end)

    -- Create padded page container anchored inside contentBox
    self.pageContainers = {}
    for _, page in ipairs(FEATURE_PAGES) do
        local pageFrame = CreateFrame("Frame", nil, contentBox)
        pageFrame:SetPoint("TOPLEFT", 10, -10)
        pageFrame:SetPoint("TOPRIGHT", -10, -10)
        pageFrame:SetHeight(1)
        pageFrame:Hide()
        self.pageContainers[page.id] = pageFrame
    end

    self.contentArea = content
    self.scrollChild = child
    self.contentBox = contentBox
    self.scrollbar = scrollbar
    self.UpdateContentHeight = UpdateContentHeight
    return content
end

-- Select a page in the navigation
function MoreFeatures:SelectPage(pageId)
    -- Update button states like main UI
    for id, btn in pairs(self.navButtons) do
        btn.hover:Hide() -- Always hide hover on state change
        
        if id == pageId then
            -- ACTIVE STATE
            local activeColor = COLORS.NAV_ACTIVE_BG
            btn.bg:SetColorTexture(activeColor[1], activeColor[2], activeColor[3], 1)
            btn.indicator:Show()
            btn.outline:Show() -- Show purple outline
            btn.text:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
            btn.isSelected = true
        else
            -- INACTIVE STATE
            local inactiveColor = COLORS.NAV_INACTIVE_BG
            btn.bg:SetColorTexture(inactiveColor[1], inactiveColor[2], inactiveColor[3], 1)
            btn.indicator:Hide()
            btn.outline:Hide() -- Hide purple outline
            btn.text:SetTextColor(COLORS.TEXT_2[1], COLORS.TEXT_2[2], COLORS.TEXT_2[3], 1)
            btn.isSelected = false
        end
    end
    
    -- Hide all page containers
    if self.pageContainers then
        for id, container in pairs(self.pageContainers) do
            container:Hide()
        end
    end
    
    -- Show the selected page container and load content if needed
    if self.pageContainers and self.pageContainers[pageId] then
        local container = self.pageContainers[pageId]
        container:Show()
        -- Reset scroll to top on page change
        if self.contentArea then
            self.contentArea:SetVerticalScroll(0)
        end
        
        -- Only load content if container is empty
        if container:GetNumChildren() == 0 then
            self:LoadPageContent(pageId, container)
        end
    end
    
    self.currentPage = pageId
end

-- Clear content from a specific page container
function MoreFeatures:ClearPageContent(pageId)
    if not self.pageContainers or not self.pageContainers[pageId] then return end
    
    local container = self.pageContainers[pageId]
    local children = {container:GetChildren()}
    for _, child in ipairs(children) do
        if child then
            child:Hide()
            child:ClearAllPoints()
            child:SetParent(nil)
        end
    end
end

-- Load content for a specific page
function MoreFeatures:LoadPageContent(pageId, container)
    if not container then return end
    
    if pageId == "general" then
        self:LoadGeneralContent(container)
    elseif pageId == "themes" then
        self:LoadThemesContent(container)
    elseif pageId == "font" then
        self:LoadFontContent(container)
    elseif pageId == "profiles" then
        self:LoadProfilesContent(container)
    else
        self:LoadComingSoonContent(pageId, container)
    end
end

-- Load General page content
function MoreFeatures:LoadGeneralContent(container)
    -- Exact copy of Blackout.lua pattern
   
    
    -- Settings group box inside the section
    local settingsGroup = CreateFrame("Frame", nil, container)
    settingsGroup:SetPoint("TOPLEFT", 10, -10)
    settingsGroup:SetPoint("TOPRIGHT", -10, -10)
    settingsGroup:SetHeight(680) -- Increased to accommodate custom icons checkbox
    AC:HairlineGroupBox(settingsGroup)

    -- Tooltips section title with message
    local tooltipTitle = AC:CreateStyledText(settingsGroup, "TOOLTIPS", 13, COLORS.PRIMARY, "OVERLAY", CUSTOM_FONT)
    tooltipTitle:SetPoint("TOPLEFT", 15, -18)

    -- Add disabled message next to title
    local disabledMessage = AC:CreateStyledText(settingsGroup, "Will come back when Blizzard fixes their Tooltips errors", 9, {1, 0.4, 0.4, 1}, "OVERLAY", CUSTOM_FONT)
    disabledMessage:SetPoint("LEFT", tooltipTitle, "RIGHT", 10, 0)
    disabledMessage:SetPoint("RIGHT", settingsGroup, "RIGHT", -20, 0)
    disabledMessage:SetJustifyH("LEFT")
    if disabledMessage.SetWordWrap then disabledMessage:SetWordWrap(true) end

    -- Tooltip IDs checkbox row (DISABLED)
    local checkboxRow2 = CreateFrame("Frame", nil, settingsGroup)
    checkboxRow2:SetPoint("TOPLEFT", tooltipTitle, "BOTTOMLEFT", 0, -14)
    checkboxRow2:SetPoint("RIGHT", settingsGroup, "RIGHT", -20, 0)
    checkboxRow2:SetHeight(26)

    local checkboxLabel2 = AC:CreateStyledText(checkboxRow2, "Show Spell/Item IDs in Tooltips", 12, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    checkboxLabel2:SetPoint("LEFT", 0, 0)
    checkboxLabel2:SetPoint("RIGHT", -46, 0)
    if checkboxLabel2.SetWordWrap then checkboxLabel2:SetWordWrap(true) end
    checkboxLabel2:SetJustifyH("LEFT")

    local db = (AC.DB and AC.DB.profile and AC.DB.profile.tooltipIDs) or {}
    local checkbox2 = AC:CreateFlatCheckbox(checkboxRow2, 20, db.enabled ~= false)
    checkbox2:SetPoint("RIGHT", -10, 0)
    checkbox2.checkButton:Disable()  -- DISABLE the checkbox's checkButton
    checkbox2.checkButton:SetScript("OnClick", nil)  -- Remove click functionality

    -- Tooltip section description
    local description2 = AC:CreateStyledText(settingsGroup, "Shows spell and item IDs in tooltips throughout the game.\nAlways enabled in ArenaCore editors for spell management.", 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    description2:SetPoint("TOPLEFT", checkboxRow2, "BOTTOMLEFT", 0, -10)
    description2:SetPoint("TOPRIGHT", checkboxRow2, "BOTTOMRIGHT", 0, -10)
    description2:SetJustifyH("LEFT"); description2:SetJustifyV("TOP")
    if description2.SetWordWrap then description2:SetWordWrap(true) end
    description2:SetWidth(settingsGroup:GetWidth() - 40)

    -- Class Portrait Swap section
    local portraitsTitle = AC:CreateStyledText(settingsGroup, "CLASS PORTRAITS", 13, COLORS.PRIMARY, "OVERLAY", CUSTOM_FONT)
    portraitsTitle:SetPoint("TOPLEFT", description2, "BOTTOMLEFT", 0, -22)

    local checkboxRow3 = CreateFrame("Frame", nil, settingsGroup)
    checkboxRow3:SetPoint("TOPLEFT", portraitsTitle, "BOTTOMLEFT", 0, -14)
    checkboxRow3:SetPoint("RIGHT", settingsGroup, "RIGHT", -20, 0)
    checkboxRow3:SetHeight(26)

    local checkboxLabel3 = AC:CreateStyledText(checkboxRow3, "Class Portrait Swap", 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    checkboxLabel3:SetPoint("LEFT", 0, 0)
    checkboxLabel3:SetPoint("RIGHT", -46, 0)
    if checkboxLabel3.SetWordWrap then checkboxLabel3:SetWordWrap(true) end
    checkboxLabel3:SetJustifyH("LEFT")

    local dbPortrait = (AC.DB and AC.DB.profile and AC.DB.profile.classPortraitSwap) or {}
    local checkbox3 = AC:CreateFlatCheckbox(checkboxRow3, 20, dbPortrait.enabled == true)
    checkbox3:SetPoint("RIGHT", -10, 0)
    checkbox3:SetScript("OnClick", function(selfBtn)
        local desired = selfBtn:GetChecked()
        AC.DB = AC.DB or {}; AC.DB.profile = AC.DB.profile or {}; AC.DB.profile.classPortraitSwap = AC.DB.profile.classPortraitSwap or {}
        AC.DB.profile.classPortraitSwap.enabled = desired
        if AC.ClassPortraitSwap and AC.ClassPortraitSwap.RefreshAll then
            C_Timer.After(0.05, function() AC.ClassPortraitSwap:RefreshAll() end)
        end
    end)

    local description3 = AC:CreateStyledText(settingsGroup, "Swap all player portraits to class icons.", 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    description3:SetPoint("TOPLEFT", checkboxRow3, "BOTTOMLEFT", 0, -10)
    description3:SetPoint("TOPRIGHT", checkboxRow3, "BOTTOMRIGHT", 0, -10)
    description3:SetJustifyH("LEFT"); description3:SetJustifyV("TOP")
    if description3.SetWordWrap then description3:SetWordWrap(true) end
    description3:SetWidth(settingsGroup:GetWidth() - 40)

    -- Use Custom Icons checkbox (under Class Portrait Swap)
    local checkboxRow3b = CreateFrame("Frame", nil, settingsGroup)
    checkboxRow3b:SetPoint("TOPLEFT", description3, "BOTTOMLEFT", 0, -10)
    checkboxRow3b:SetPoint("RIGHT", settingsGroup, "RIGHT", -20, 0)
    checkboxRow3b:SetHeight(26)

    local checkboxLabel3b = AC:CreateStyledText(checkboxRow3b, "Use Arena Core Custom Icons", 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    checkboxLabel3b:SetPoint("LEFT", 15, 0)
    checkboxLabel3b:SetPoint("RIGHT", -46, 0)
    if checkboxLabel3b.SetWordWrap then checkboxLabel3b:SetWordWrap(true) end
    checkboxLabel3b:SetJustifyH("LEFT")

    local dbPortraitCustom = (AC.DB and AC.DB.profile and AC.DB.profile.classPortraitSwap) or { useCustomIcons = true }
    local checkbox3b = AC:CreateFlatCheckbox(checkboxRow3b, 20, dbPortraitCustom.useCustomIcons == true)
    checkbox3b:SetPoint("RIGHT", -10, 0)
    checkbox3b:SetScript("OnClick", function(selfBtn)
        local desired = selfBtn:GetChecked()
        AC.DB = AC.DB or {}; AC.DB.profile = AC.DB.profile or {}; AC.DB.profile.classPortraitSwap = AC.DB.profile.classPortraitSwap or {}
        AC.DB.profile.classPortraitSwap.useCustomIcons = desired
        if AC.ClassPortraitSwap and AC.ClassPortraitSwap.RefreshAll then
            C_Timer.After(0.05, function() AC.ClassPortraitSwap:RefreshAll() end)
        end
        if desired then
            print("|cff8B45FFArena Core:|r Class portraits now using ArenaCore custom icons")
        else
            print("|cff8B45FFArena Core:|r Class portraits now using theme icons (Midnight Chill/etc)")
        end
    end)

    local description3b = AC:CreateStyledText(settingsGroup, "When checked, uses original ArenaCore custom icons. When unchecked, uses alternate theme icons (Midnight Chill, etc).", 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    description3b:SetPoint("TOPLEFT", checkboxRow3b, "BOTTOMLEFT", 0, -10)
    description3b:SetPoint("TOPRIGHT", checkboxRow3b, "BOTTOMRIGHT", 0, -10)
    description3b:SetJustifyH("LEFT"); description3b:SetJustifyV("TOP")
    if description3b.SetWordWrap then description3b:SetWordWrap(true) end
    description3b:SetWidth(settingsGroup:GetWidth() - 40)

    -- SURRENDER section title
    local surrenderTitle = AC:CreateStyledText(settingsGroup, "SURRENDER", 13, COLORS.PRIMARY, "OVERLAY", CUSTOM_FONT)
    surrenderTitle:SetPoint("TOPLEFT", description3b, "BOTTOMLEFT", 0, -22)

    -- Surrender /gg checkbox row (under Class Portraits)
    local checkboxRow4 = CreateFrame("Frame", nil, settingsGroup)
    checkboxRow4:SetPoint("TOPLEFT", surrenderTitle, "BOTTOMLEFT", 0, -14)
    checkboxRow4:SetPoint("RIGHT", settingsGroup, "RIGHT", -20, 0)
    checkboxRow4:SetHeight(26)

    local checkboxLabel4 = AC:CreateStyledText(checkboxRow4, "Surrender /gg", 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    checkboxLabel4:SetPoint("LEFT", 0, 0)
    checkboxLabel4:SetPoint("RIGHT", -46, 0)
    if checkboxLabel4.SetWordWrap then checkboxLabel4:SetWordWrap(true) end
    checkboxLabel4:SetJustifyH("LEFT")

    local dbSurr = (AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures) or {}
    local checkbox4 = AC:CreateFlatCheckbox(checkboxRow4, 20, (dbSurr.surrenderGGEnabled ~= false)) -- default ON
    checkbox4:SetPoint("RIGHT", -10, 0)
    checkbox4:SetScript("OnClick", function(selfBtn)
        local enabled = selfBtn:GetChecked()
        AC.DB = AC.DB or {}; AC.DB.profile = AC.DB.profile or {}; AC.DB.profile.moreFeatures = AC.DB.profile.moreFeatures or {}
        AC.DB.profile.moreFeatures.surrenderGGEnabled = enabled
        if MoreFeatures and MoreFeatures.ApplySurrenderSetting then
            MoreFeatures:ApplySurrenderSetting()
        end
    end)

    -- Description under Surrender
    local description4 = AC:CreateStyledText(settingsGroup, "Enable /gg feature inside of arena to easily surrender.", 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    description4:SetPoint("TOPLEFT", checkboxRow4, "BOTTOMLEFT", 0, -10)
    description4:SetPoint("TOPRIGHT", checkboxRow4, "BOTTOMRIGHT", 0, -10)
    description4:SetJustifyH("LEFT"); description4:SetJustifyV("TOP")
    if description4.SetWordWrap then description4:SetWordWrap(true) end
    description4:SetWidth(settingsGroup:GetWidth() - 40)

    -- CHAT MESSAGES section title
    local chatMessagesTitle = AC:CreateStyledText(settingsGroup, "CHAT MESSAGES", 13, COLORS.PRIMARY, "OVERLAY", CUSTOM_FONT)
    chatMessagesTitle:SetPoint("TOPLEFT", description4, "BOTTOMLEFT", 0, -22)

    -- Chat Messages checkbox row
    local checkboxRow5 = CreateFrame("Frame", nil, settingsGroup)
    checkboxRow5:SetPoint("TOPLEFT", chatMessagesTitle, "BOTTOMLEFT", 0, -14)
    checkboxRow5:SetPoint("RIGHT", settingsGroup, "RIGHT", -20, 0)
    checkboxRow5:SetHeight(26)

    local checkboxLabel5 = AC:CreateStyledText(checkboxRow5, "Arena Chat Announcements", 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    checkboxLabel5:SetPoint("LEFT", 0, 0)
    checkboxLabel5:SetPoint("RIGHT", -46, 0)
    if checkboxLabel5.SetWordWrap then checkboxLabel5:SetWordWrap(true) end
    checkboxLabel5:SetJustifyH("LEFT")

    local dbChat = (AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures) or {}
    local checkbox5 = AC:CreateFlatCheckbox(checkboxRow5, 20, (dbChat.chatMessagesEnabled ~= false)) -- default ON
    checkbox5:SetPoint("RIGHT", -10, 0)
    checkbox5:SetScript("OnClick", function(selfBtn)
        local enabled = selfBtn:GetChecked()
        AC.DB = AC.DB or {}; AC.DB.profile = AC.DB.profile or {}; AC.DB.profile.moreFeatures = AC.DB.profile.moreFeatures or {}
        AC.DB.profile.moreFeatures.chatMessagesEnabled = enabled
        
        -- User feedback
        if enabled then
            print("|cff8B45FFArena Core:|r Chat messages |cff00FF00ENABLED|r - You will see interrupt and feign death announcements")
        else
            print("|cff8B45FFArena Core:|r Chat messages |cffFF0000DISABLED|r - Interrupt and feign death announcements are now hidden")
        end
    end)

    -- Description under Chat Messages
    local description5 = AC:CreateStyledText(settingsGroup, "Enable chat announcements for interrupts and feign death detection during arena matches.", 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    description5:SetPoint("TOPLEFT", checkboxRow5, "BOTTOMLEFT", 0, -10)
    description5:SetPoint("TOPRIGHT", checkboxRow5, "BOTTOMRIGHT", 0, -10)
    description5:SetJustifyH("LEFT"); description5:SetJustifyV("TOP")
    if description5.SetWordWrap then description5:SetWordWrap(true) end
    description5:SetWidth(settingsGroup:GetWidth() - 40)
end

-- Load Themes page content
function MoreFeatures:LoadThemesContent(container)
    -- Theme data (matches AchievementUnlocks.lua)
    local themes = {
        {
            id = "default",
            name = "Arena Core Default",
            description = "The classic Arena Core theme",
            rating = nil, -- Always unlocked
            icon = "Interface\\Icons\\INV_Misc_Gear_01",
        },
        {
            id = "shade_ui",
            name = "Shade UI",
            description = "Premium dark theme inspired by Shade UI addon",
            rating = 2100,
            icon = "Interface\\Icons\\Spell_Shadow_Twilight",
        },
        {
            id = "elite_2400",
            name = "Elite",
            description = "Exclusive theme unlocked at 2400 rating",
            rating = 2400,
            icon = "Interface\\Icons\\Achievement_Arena_2v2_7",
        },
        {
            id = "rank1_3000",
            name = "Rank 1",
            description = "Exclusive theme unlocked at 3000 rating",
            rating = 3000,
            icon = "Interface\\Icons\\Achievement_Arena_3v3_7",
        },
    }
    
    -- Settings group box
    local settingsGroup = CreateFrame("Frame", nil, container)
    settingsGroup:SetPoint("TOPLEFT", 10, -10)
    settingsGroup:SetPoint("TOPRIGHT", -10, -10)
    settingsGroup:SetHeight(580) -- Increased to accommodate production notice
    AC:HairlineGroupBox(settingsGroup)
    
    -- Group title
    local groupTitle = AC:CreateStyledText(settingsGroup, "UNLOCKABLE THEMES", 13, COLORS.PRIMARY, "OVERLAY", CUSTOM_FONT)
    groupTitle:SetPoint("TOPLEFT", 15, -18)
    
    -- Production notice (add this new text)
    local productionNotice = AC:CreateStyledText(settingsGroup, "This feature is still under production and will evolve as time goes on.", 10, COLORS.WARNING, "OVERLAY", CUSTOM_FONT)
    productionNotice:SetPoint("TOPLEFT", groupTitle, "BOTTOMLEFT", 0, -6)
    productionNotice:SetJustifyH("LEFT")

    -- Description
    local desc = AC:CreateStyledText(settingsGroup, "Unlock exclusive UI themes by reaching rating milestones in PvP.", 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    desc:SetPoint("TOPLEFT", productionNotice, "BOTTOMLEFT", 0, -6)
    desc:SetJustifyH("LEFT")
    
    local yOffset = -75  -- Adjusted for new production notice text
    
    -- Create theme cards
    for i, theme in ipairs(themes) do
        local card = CreateFrame("Frame", nil, settingsGroup)
        card:SetPoint("TOPLEFT", 15, yOffset)
        card:SetPoint("TOPRIGHT", -15, yOffset)
        card:SetHeight(100)
        
        -- Check if theme is unlocked (default theme is always unlocked)
        local isUnlocked = (theme.id == "default") or (AC.IsThemeUnlocked and AC:IsThemeUnlocked(theme.id)) or false
        
        -- Card background
        local cardBg = AC:CreateFlatTexture(card, "BACKGROUND", 1, COLORS.INPUT_DARK, 1)
        cardBg:SetAllPoints()
        
        -- Purple border if unlocked, gray if locked
        local borderColor = isUnlocked and COLORS.PRIMARY or COLORS.BORDER
        local cardBorder = AC:CreateFlatTexture(card, "BORDER", 0, borderColor, 1)
        cardBorder:SetAllPoints()
        
        local cardInner = AC:CreateFlatTexture(card, "BORDER", 1, COLORS.INPUT_DARK, 1)
        cardInner:SetPoint("TOPLEFT", 2, -2)
        cardInner:SetPoint("BOTTOMRIGHT", -2, 2)
        
        -- Theme icon
        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(64, 64)
        icon:SetPoint("LEFT", 15, 0)
        icon:SetTexture(theme.icon)
        
        -- Desaturate if locked
        if not isUnlocked then
            icon:SetDesaturated(true)
            icon:SetAlpha(0.5)
        end
        
        -- Theme name
        local nameColor = isUnlocked and COLORS.PRIMARY or COLORS.TEXT_MUTED
        local themeName = AC:CreateStyledText(card, theme.name, 14, nameColor, "OVERLAY", CUSTOM_FONT)
        themeName:SetPoint("TOPLEFT", icon, "TOPRIGHT", 15, -5)
        
        -- Rating requirement (or "Always Available" for default)
        local ratingLabel = theme.rating and string.format("Requires %d Rating", theme.rating) or "Always Available"
        local ratingText = AC:CreateStyledText(card, ratingLabel, 11, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
        ratingText:SetPoint("TOPLEFT", themeName, "BOTTOMLEFT", 0, -4)
        
        -- Description
        local themeDesc = AC:CreateStyledText(card, theme.description, 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
        themeDesc:SetPoint("TOPLEFT", ratingText, "BOTTOMLEFT", 0, -6)
        themeDesc:SetPoint("TOPRIGHT", card, "TOPRIGHT", -120, 0)
        themeDesc:SetJustifyH("LEFT")
        if themeDesc.SetWordWrap then themeDesc:SetWordWrap(true) end
        
        -- Status/Action button
        local btn = AC:CreateTexturedButton(card, 100, 32, "", "UI\\tab-purple-matte")
        btn:SetPoint("RIGHT", -15, 0)
        
        if isUnlocked then
            -- Check if this theme is currently active
            local isActive = AC.ThemeManager and AC.ThemeManager:IsThemeActive(theme.id) or false
            
            if isActive then
                -- Show "ACTIVE" status
                local btnText = AC:CreateStyledText(btn, "ACTIVE", 12, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
                btnText:SetPoint("CENTER", 0, 0)
                btnText:SetTextColor(0.133, 0.667, 0.267, 1) -- Green
                btn:SetAlpha(1.0)
                btn:Disable()
            else
                -- Show "ACTIVATE" button
                local btnText = AC:CreateStyledText(btn, "ACTIVATE", 12, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
                btnText:SetPoint("CENTER", 0, 0)
                btnText:SetTextColor(1, 1, 1, 1) -- White
                btn:SetAlpha(1.0)
                btn:Enable()
                btn:SetScript("OnClick", function()
                    -- Activate this theme
                    if AC.ThemeManager then
                        AC.ThemeManager:ApplyTheme(theme.id)
                        -- Refresh the themes page to update button states
                        if MoreFeatures and MoreFeatures.pageContainers and MoreFeatures.pageContainers["themes"] then
                            MoreFeatures:ClearPageContent("themes")
                            MoreFeatures:LoadThemesContent(MoreFeatures.pageContainers["themes"])
                        end
                    end
                end)
            end
        else
            -- Show locked status with custom padlock icon (larger)
            local lockIcon = btn:CreateTexture(nil, "OVERLAY")
            lockIcon:SetSize(20, 20) -- Increased from 16x16
            lockIcon:SetPoint("CENTER", -24, 0)
            lockIcon:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Achievements\\padlock_icon.png")
            
            local btnText = AC:CreateStyledText(btn, "LOCKED", 12, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
            btnText:SetPoint("CENTER", 10, 0) -- Offset right to make room for larger icon
            btnText:SetTextColor(0.863, 0.176, 0.176, 1) -- Red
            btn:SetAlpha(0.5)
            btn:Disable()
        end
        
        yOffset = yOffset - 105
    end
    
    -- Info text at bottom (properly positioned inside the box)
    local infoText = AC:CreateStyledText(settingsGroup, "Themes are unlocked account-wide when you earn the achievement on any character.", 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    infoText:SetPoint("BOTTOMLEFT", settingsGroup, "BOTTOMLEFT", 15, 12)
    infoText:SetPoint("BOTTOMRIGHT", settingsGroup, "BOTTOMRIGHT", -15, 12)
    infoText:SetJustifyH("CENTER")
    infoText:SetJustifyV("BOTTOM")
    if infoText.SetWordWrap then infoText:SetWordWrap(true) end
end

-- Load Font page content
function MoreFeatures:LoadFontContent(container)
    -- Settings group box
    local settingsGroup = CreateFrame("Frame", nil, container)
    settingsGroup:SetPoint("TOPLEFT", 10, -10)
    settingsGroup:SetPoint("TOPRIGHT", -10, -10)
    settingsGroup:SetHeight(380)
    AC:HairlineGroupBox(settingsGroup)

    -- Group title
    local groupTitle = AC:CreateStyledText(settingsGroup, "GLOBAL ARENACORE FONT", 13, COLORS.PRIMARY, "OVERLAY", CUSTOM_FONT)
    groupTitle:SetPoint("TOPLEFT", 15, -18)

    -- Global Font checkbox row
    local checkboxRow1 = CreateFrame("Frame", nil, settingsGroup)
    checkboxRow1:SetPoint("TOPLEFT", groupTitle, "BOTTOMLEFT", 0, -14)
    checkboxRow1:SetPoint("RIGHT", settingsGroup, "RIGHT", -20, 0)
    checkboxRow1:SetHeight(26)

    local checkboxLabel1 = AC:CreateStyledText(checkboxRow1, "Apply ArenaCore Font Globally", 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    checkboxLabel1:SetPoint("LEFT", 0, 0)
    checkboxLabel1:SetPoint("RIGHT", -46, 0)
    if checkboxLabel1.SetWordWrap then checkboxLabel1:SetWordWrap(true) end
    checkboxLabel1:SetJustifyH("LEFT")

    local dbGlobalFont = (AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures) or {}
    local checkbox1 = AC:CreateFlatCheckbox(checkboxRow1, 20, (dbGlobalFont.globalFontEnabled == true))
    checkbox1:SetPoint("RIGHT", -10, 0)
    
    -- Store reference for mutual exclusivity (will be set up after checkbox4 is created)
    local globalFontCheckbox = checkbox1

    -- Description under Global Font
    local description1 = AC:CreateStyledText(settingsGroup, "Applies ArenaCore font to your entire game UI including chat, tooltips, action bars, and combat text.", 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    description1:SetPoint("TOPLEFT", checkboxRow1, "BOTTOMLEFT", 0, -10)
    description1:SetPoint("TOPRIGHT", checkboxRow1, "BOTTOMRIGHT", 0, -10)
    description1:SetJustifyH("LEFT"); description1:SetJustifyV("TOP")
    if description1.SetWordWrap then description1:SetWordWrap(true) end
    description1:SetWidth(settingsGroup:GetWidth() - 40)
    
    -- Action Bar Font Only checkbox row (NEW FEATURE)
    local checkboxRow4 = CreateFrame("Frame", nil, settingsGroup)
    checkboxRow4:SetPoint("TOPLEFT", description1, "BOTTOMLEFT", 0, -18)
    checkboxRow4:SetPoint("RIGHT", settingsGroup, "RIGHT", -20, 0)
    checkboxRow4:SetHeight(26)

    local checkboxLabel4 = AC:CreateStyledText(checkboxRow4, "Action Bar Font Only", 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    checkboxLabel4:SetPoint("LEFT", 0, 0)
    checkboxLabel4:SetPoint("RIGHT", -46, 0)
    if checkboxLabel4.SetWordWrap then checkboxLabel4:SetWordWrap(true) end
    checkboxLabel4:SetJustifyH("LEFT")

    local dbActionBarFont = (AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures) or {}
    local checkbox4 = AC:CreateFlatCheckbox(checkboxRow4, 20, (dbActionBarFont.actionBarFontOnly == true))
    checkbox4:SetPoint("RIGHT", -10, 0)
    
    -- Store reference for mutual exclusivity
    local actionBarFontCheckbox = checkbox4
    
    -- Description under Action Bar Font Only
    local description4 = AC:CreateStyledText(settingsGroup, "Applies ArenaCore custom font to action bars ONLY and nothing else. This option is mutually exclusive with 'Apply ArenaCore Font Globally'.", 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    description4:SetPoint("TOPLEFT", checkboxRow4, "BOTTOMLEFT", 0, -10)
    description4:SetPoint("TOPRIGHT", checkboxRow4, "BOTTOMRIGHT", 0, -10)
    description4:SetJustifyH("LEFT"); description4:SetJustifyV("TOP")
    if description4.SetWordWrap then description4:SetWordWrap(true) end
    description4:SetWidth(settingsGroup:GetWidth() - 40)
    
    -- Set up OnClick handlers with mutual exclusivity AFTER both checkboxes exist
    checkbox1:SetScript("OnClick", function(selfBtn)
        local enabled = selfBtn:GetChecked()
        AC.DB = AC.DB or {}; AC.DB.profile = AC.DB.profile or {}; AC.DB.profile.moreFeatures = AC.DB.profile.moreFeatures or {}
        AC.DB.profile.moreFeatures.globalFontEnabled = enabled
        
        -- MUTUAL EXCLUSIVITY: If enabling global font, disable action bar font only
        if enabled and actionBarFontCheckbox then
            actionBarFontCheckbox:SetChecked(false)
            AC.DB.profile.moreFeatures.actionBarFontOnly = false
            -- Disable action bar-only mode
            if AC.GlobalFont and AC.GlobalFont.isEnabled then
                AC.GlobalFont:Disable()
            end
        end
        
        if MoreFeatures and MoreFeatures.ApplyGlobalFont then
            MoreFeatures:ApplyGlobalFont(enabled)
        end
    end)
    
    checkbox4:SetScript("OnClick", function(selfBtn)
        local enabled = selfBtn:GetChecked()
        AC.DB = AC.DB or {}; AC.DB.profile = AC.DB.profile or {}; AC.DB.profile.moreFeatures = AC.DB.profile.moreFeatures or {}
        AC.DB.profile.moreFeatures.actionBarFontOnly = enabled
        
        -- MUTUAL EXCLUSIVITY: If enabling action bar font only, disable global font
        if enabled and globalFontCheckbox then
            globalFontCheckbox:SetChecked(false)
            AC.DB.profile.moreFeatures.globalFontEnabled = false
            -- Disable global font mode
            if AC.GlobalFont and AC.GlobalFont.isEnabled then
                AC.GlobalFont:Disable()
            end
        end
        
        if MoreFeatures and MoreFeatures.ApplyActionBarFont then
            MoreFeatures:ApplyActionBarFont(enabled)
        end
    end)
    
    -- Font Outline checkbox
    local checkboxRow2 = CreateFrame("Frame", nil, settingsGroup)
    checkboxRow2:SetPoint("TOPLEFT", description4, "BOTTOMLEFT", 0, -18)
    checkboxRow2:SetPoint("RIGHT", settingsGroup, "RIGHT", -20, 0)
    checkboxRow2:SetHeight(26)

    local checkboxLabel2 = AC:CreateStyledText(checkboxRow2, "Font Outline", 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    checkboxLabel2:SetPoint("LEFT", 0, 0)
    checkboxLabel2:SetPoint("RIGHT", -46, 0)
    if checkboxLabel2.SetWordWrap then checkboxLabel2:SetWordWrap(true) end
    checkboxLabel2:SetJustifyH("LEFT")

    local dbFontOutline = (AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures) or {}
    local checkbox2 = AC:CreateFlatCheckbox(checkboxRow2, 20, (dbFontOutline.globalFontOutline ~= false)) -- default ON
    checkbox2:SetPoint("RIGHT", -10, 0)
    checkbox2:SetScript("OnClick", function(selfBtn)
        local enabled = selfBtn:GetChecked()
        AC.DB = AC.DB or {}; AC.DB.profile = AC.DB.profile or {}; AC.DB.profile.moreFeatures = AC.DB.profile.moreFeatures or {}
        AC.DB.profile.moreFeatures.globalFontOutline = enabled
        print("|cff8B45FFArena Core:|r Font outline " .. (enabled and "enabled" or "disabled") .. ". /reload to apply.")
    end)
    
    -- Description under Font Outline
    local description2 = AC:CreateStyledText(settingsGroup, "Adds a black outline around text for better visibility against varied backgrounds. Recommended for numbers and icons.", 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    description2:SetPoint("TOPLEFT", checkboxRow2, "BOTTOMLEFT", 0, -10)
    description2:SetPoint("TOPRIGHT", checkboxRow2, "BOTTOMRIGHT", 0, -10)
    description2:SetJustifyH("LEFT"); description2:SetJustifyV("TOP")
    if description2.SetWordWrap then description2:SetWordWrap(true) end
    description2:SetWidth(settingsGroup:GetWidth() - 40)
    
    -- Font Shadow checkbox
    local checkboxRow3 = CreateFrame("Frame", nil, settingsGroup)
    checkboxRow3:SetPoint("TOPLEFT", description2, "BOTTOMLEFT", 0, -18)
    checkboxRow3:SetPoint("RIGHT", settingsGroup, "RIGHT", -20, 0)
    checkboxRow3:SetHeight(26)

    local checkboxLabel3 = AC:CreateStyledText(checkboxRow3, "Font Shadow", 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    checkboxLabel3:SetPoint("LEFT", 0, 0)
    checkboxLabel3:SetPoint("RIGHT", -46, 0)
    if checkboxLabel3.SetWordWrap then checkboxLabel3:SetWordWrap(true) end
    checkboxLabel3:SetJustifyH("LEFT")

    local dbFontShadow = (AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures) or {}
    local checkbox3 = AC:CreateFlatCheckbox(checkboxRow3, 20, (dbFontShadow.globalFontShadow ~= false)) -- default ON
    checkbox3:SetPoint("RIGHT", -10, 0)
    checkbox3:SetScript("OnClick", function(selfBtn)
        local enabled = selfBtn:GetChecked()
        AC.DB = AC.DB or {}; AC.DB.profile = AC.DB.profile or {}; AC.DB.profile.moreFeatures = AC.DB.profile.moreFeatures or {}
        AC.DB.profile.moreFeatures.globalFontShadow = enabled
        print("|cff8B45FFArena Core:|r Font shadow " .. (enabled and "enabled" or "disabled") .. ". /reload to apply.")
    end)
    
    -- Description under Font Shadow
    local description3 = AC:CreateStyledText(settingsGroup, "Adds a subtle drop shadow to text for improved depth and readability. Enabled by default for optimal visual clarity.", 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    description3:SetPoint("TOPLEFT", checkboxRow3, "BOTTOMLEFT", 0, -10)
    description3:SetPoint("TOPRIGHT", checkboxRow3, "BOTTOMRIGHT", 0, -10)
    description3:SetJustifyH("LEFT"); description3:SetJustifyV("TOP")
    if description3.SetWordWrap then description3:SetWordWrap(true) end
    description3:SetWidth(settingsGroup:GetWidth() - 40)
    
    -- ACTION BAR FONT SETTINGS section title
    local actionBarTitle = AC:CreateStyledText(settingsGroup, "ACTIONBAR FONT SETTINGS", 13, COLORS.PRIMARY, "OVERLAY", CUSTOM_FONT)
    actionBarTitle:SetPoint("TOPLEFT", description3, "BOTTOMLEFT", 0, -22)
    
    -- Helper function to create sliders with +/- buttons and text input
    local function CreateActionBarSlider(parent, label, anchorTo, yOffset, dbKey, minVal, maxVal, defaultVal)
        local row = CreateFrame("Frame", nil, parent)
        row:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, yOffset)
        row:SetPoint("RIGHT", parent, "RIGHT", -20, 0)
        row:SetHeight(40)
        
        local labelText = AC:CreateStyledText(row, label, 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
        labelText:SetPoint("TOPLEFT", 0, -5)
        
        -- Get current value from database (same as working sliders)
        local db = AC.DB and AC.DB.profile and AC.DB.profile.actionBarFont or {}
        local currentValue = db[dbKey] or defaultVal
        
        -- Minus button
        local minusBtn = AC:CreateTexturedButton(row, 20, 20, "-", "button-minus")
        minusBtn:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -8)
        local minusText = AC:CreateStyledText(minusBtn, "-", 16, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
        minusText:SetPoint("CENTER", 0, 0)
        
        -- Text input box
        local inputBox = CreateFrame("EditBox", nil, row)
        inputBox:SetPoint("LEFT", minusBtn, "RIGHT", 5, 0)
        inputBox:SetSize(50, 20)
        inputBox:SetAutoFocus(false)
        inputBox:SetFontObject(GameFontNormal)
        inputBox:SetMaxLetters(5)
        inputBox:SetNumeric(false)
        
        local inputBg = AC:CreateFlatTexture(inputBox, "BACKGROUND", 1, COLORS.INPUT_DARK, 1)
        inputBg:SetAllPoints()
        
        local inputBorder = AC:CreateFlatTexture(inputBox, "BORDER", 1, COLORS.BORDER, 1)
        inputBorder:SetAllPoints()
        
        inputBox:SetText(tostring(currentValue))
        inputBox:SetCursorPosition(0)
        
        -- Plus button
        local plusBtn = AC:CreateTexturedButton(row, 20, 20, "+", "button-plus")
        plusBtn:SetPoint("LEFT", inputBox, "RIGHT", 5, 0)
        local plusText = AC:CreateStyledText(plusBtn, "+", 16, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
        plusText:SetPoint("CENTER", 0, 0)
        
        -- Slider
        local slider = CreateFrame("Slider", nil, row)
        slider:SetPoint("LEFT", plusBtn, "RIGHT", 10, 0)
        slider:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        slider:SetHeight(16)
        slider:SetOrientation("HORIZONTAL")
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValue(currentValue)
        slider:SetValueStep(1)
        
        local sliderBg = AC:CreateFlatTexture(slider, "BACKGROUND", 1, COLORS.INSET, 1)
        sliderBg:SetAllPoints()
        
        local sliderThumb = slider:CreateTexture(nil, "OVERLAY")
        sliderThumb:SetSize(12, 16)
        sliderThumb:SetColorTexture(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 1)
        slider:SetThumbTexture(sliderThumb)
        
        -- Update function
        local function UpdateValue(value)
            value = math.floor(value + 0.5)
            value = math.max(minVal, math.min(maxVal, value))
            
            slider:SetValue(value)
            inputBox:SetText(tostring(value))
            
            -- Save to AC.DB.profile (EXACT pattern from working sliders in Helpers.lua)
            if AC.DB and AC.DB.profile then
                AC.DB.profile.actionBarFont = AC.DB.profile.actionBarFont or {}
                AC.DB.profile.actionBarFont[dbKey] = value
            end
            
            -- CRITICAL: Only apply changes if global font is enabled
            if AC.MoreFeatures and AC.MoreFeatures.ApplyActionBarFonts then
                local enabled = AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures and AC.DB.profile.moreFeatures.globalFontEnabled
                if enabled then
                    AC.MoreFeatures:ApplyActionBarFonts()
                end
            end
        end
        
        minusBtn:SetScript("OnClick", function() UpdateValue(slider:GetValue() - 1) end)
        plusBtn:SetScript("OnClick", function() UpdateValue(slider:GetValue() + 1) end)
        slider:SetScript("OnValueChanged", function(self, value) UpdateValue(value) end)
        
        inputBox:SetScript("OnEnterPressed", function(self)
            local value = tonumber(self:GetText())
            if value then UpdateValue(value) end
            self:ClearFocus()
        end)
        
        inputBox:SetScript("OnEscapePressed", function(self)
            self:SetText(tostring(slider:GetValue()))
            self:ClearFocus()
        end)
        
        return row
    end
    
    -- Scale slider
    local scaleRow = CreateActionBarSlider(settingsGroup, "Scale", actionBarTitle, -14, "scale", 50, 200, 100)
    
    -- Horizontal position slider
    local horizRow = CreateActionBarSlider(settingsGroup, "Horizontal", scaleRow, -8, "horizontal", -500, 500, 0)
    
    -- Vertical position slider
    local vertRow = CreateActionBarSlider(settingsGroup, "Vertical", horizRow, -8, "vertical", -500, 500, 0)
    
    -- Update settingsGroup height to accommodate new sliders
    settingsGroup:SetHeight(620)
end

--- Load Profiles page content
function MoreFeatures:LoadProfilesContent(container)
    if not container then return end
    
    -- Settings group box
    local settingsGroup = CreateFrame("Frame", nil, container)
    settingsGroup:SetPoint("TOPLEFT", 10, -10)
    settingsGroup:SetPoint("TOPRIGHT", -10, -10)
    settingsGroup:SetHeight(520)
    AC:HairlineGroupBox(settingsGroup)
    
    -- Group title
    local groupTitle = AC:CreateStyledText(settingsGroup, "PROFILE MANAGEMENT", 13, COLORS.PRIMARY, "OVERLAY", CUSTOM_FONT)
    groupTitle:SetPoint("TOPLEFT", 15, -18)
    
    local yOffset = -55
    
    -- Current Profile Dropdown
    local dropdownLabel = AC:CreateStyledText(settingsGroup, "Current Profile:", 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    dropdownLabel:SetPoint("TOPLEFT", 20, yOffset)
    
    -- FIXED: Use CreateProfileDropdown with delete buttons
    -- Store the dropdown Y position as a constant so it doesn't move when RefreshDropdown is called
    local dropdownYPosition = yOffset - 25
    local dropdown
    local nameInput  -- Declare early so RefreshDropdown can access it
    
    local function RefreshDropdown()
        if not AC.ProfileManager then return end
        
        local profiles = AC.ProfileManager:GetProfileList()
        local currentProfile = AC.ProfileManager:GetCurrentProfile()
        local defaultProfile = AC.ProfileManager.DEFAULT_PROFILE_NAME or "ArenaCore Default"
        
        local function OnProfileChange(selectedProfile)
            -- Switch profile
            local success, err = AC.ProfileManager:SwitchProfile(selectedProfile)
            if not success then
                print("|cffFF0000ArenaCore:|r " .. (err or "Failed to switch profile"))
                return
            end
            
            -- Show reload confirmation popup
            MoreFeatures:ShowReloadConfirmation(selectedProfile)
        end
        
        local function OnProfileDelete(profileToDelete)
            -- Play sound
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
            
            -- Check if trying to delete active profile
            if profileToDelete == currentProfile then
                MoreFeatures:ShowActiveProfileError()
                print("|cffFF0000ArenaCore:|r Cannot delete active profile. Please switch to another profile first.")
                return
            end
            
            -- Show delete confirmation
            MoreFeatures:ShowDeleteConfirmation(profileToDelete, function()
                local success, err = AC.ProfileManager:DeleteProfile(profileToDelete)
                if success then
                    RefreshDropdown()
                    nameInput:SetText(AC.ProfileManager:GetCurrentProfile())
                else
                    print("|cffFF0000ArenaCore:|r " .. (err or "Failed to delete profile"))
                end
            end)
        end
        
        -- Create or recreate dropdown with current profile list
        if dropdown then
            -- Hide and cleanup the old dropdown's menu
            if dropdown.menu then
                dropdown.menu:Hide()
                dropdown.menu:SetParent(nil)
            end
            dropdown:Hide()
            dropdown:SetParent(nil)
            dropdown = nil
        end
        
        dropdown = AC:CreateProfileDropdown(settingsGroup, 300, 30, profiles, currentProfile, OnProfileChange, OnProfileDelete, defaultProfile, currentProfile)
        dropdown:SetPoint("TOPLEFT", 20, dropdownYPosition)  -- Use fixed position, not changing yOffset
        
        -- CRITICAL FIX: Store dropdown reference for cleanup when window closes
        MoreFeatures.profileDropdown = dropdown
    end
    
    RefreshDropdown()
    
    yOffset = yOffset - 70
    
    -- Profile Name Input
    local nameLabel = AC:CreateStyledText(settingsGroup, "Profile Name:", 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    nameLabel:SetPoint("TOPLEFT", 20, yOffset)
    
    -- FIXED: Create EditBox directly (no AC:CreateTextInput method exists)
    nameInput = CreateFrame("EditBox", nil, settingsGroup)  -- Assignment, not declaration (declared above)
    nameInput:SetPoint("TOPLEFT", 20, yOffset - 25)
    nameInput:SetSize(300, 30)
    nameInput:SetAutoFocus(false)
    nameInput:SetFontObject(GameFontNormal)
    nameInput:SetMaxLetters(50)
    
    -- Add background and border styling
    local inputBg = AC:CreateFlatTexture(nameInput, "BACKGROUND", 1, COLORS.INPUT_DARK, 1)
    inputBg:SetAllPoints()
    
    local inputBorder = AC:CreateFlatTexture(nameInput, "BORDER", 1, COLORS.BORDER, 1)
    inputBorder:SetAllPoints()
    
    nameInput:SetText(AC.ProfileManager and AC.ProfileManager:GetCurrentProfile() or "")
    nameInput:SetCursorPosition(0)
    
    yOffset = yOffset - 70
    
    -- Helper function to create styled profile buttons (Edit Mode popup gradient style)
    local function CreateProfileButton(parent, width, height, text, colorType)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(width, height)
        
        -- Color schemes matching Edit Mode popup gradient style
        local colors = {
            primary = {
                bg = {0.545, 0.271, 1.000, 1},      -- Purple
                border = {0.4, 0.2, 0.7, 1},         -- Darker purple
                hover = {0.645, 0.371, 1.000, 1}     -- Lighter purple
            },
            success = {
                bg = {0.133, 0.667, 0.267, 1},       -- Green
                border = {0.1, 0.5, 0.2, 1},         -- Darker green
                hover = {0.233, 0.767, 0.367, 1}     -- Lighter green
            },
            danger = {
                bg = {0.863, 0.176, 0.176, 1},       -- Red
                border = {0.6, 0.1, 0.1, 1},         -- Darker red
                hover = {0.963, 0.276, 0.276, 1}     -- Lighter red
            }
        }
        
        local color = colors[colorType] or colors.primary
        
        -- Background layer (main color)
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(color.bg[1], color.bg[2], color.bg[3], color.bg[4])
        btn.bg = bg
        
        -- Border layer (darker for depth) - Edit Mode popup style
        local border = btn:CreateTexture(nil, "BORDER")
        border:SetAllPoints()
        border:SetColorTexture(color.border[1], color.border[2], color.border[3], color.border[4])
        border:SetPoint("TOPLEFT", 1, -1)
        border:SetPoint("BOTTOMRIGHT", -1, 1)
        
        -- Button text (white, no outline) - Edit Mode popup style
        local btnText = btn:CreateFontString(nil, "OVERLAY")
        btnText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 11)
        btnText:SetText(text)
        btnText:SetTextColor(1, 1, 1, 1)  -- Pure white
        btnText:SetPoint("CENTER", 0, 0)
        btn.text = btnText
        
        -- Hover effect (lighter shade) - Edit Mode popup style
        btn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(color.hover[1], color.hover[2], color.hover[3], color.hover[4])
        end)
        
        btn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(color.bg[1], color.bg[2], color.bg[3], color.bg[4])
        end)
        
        return btn
    end
    
    -- Buttons Row 1: Rename, Create New
    local renameBtn = CreateProfileButton(settingsGroup, 145, 32, "Rename Profile", "primary")
    renameBtn:SetPoint("TOPLEFT", 20, yOffset)
    renameBtn:SetScript("OnClick", function()
        local newName = nameInput:GetText()
        local currentProfile = AC.ProfileManager:GetCurrentProfile()
        
        if not newName or newName == "" then
            print("|cffFF0000ArenaCore:|r Profile name cannot be empty")
            return
        end
        
        local success, err = AC.ProfileManager:RenameProfile(currentProfile, newName)
        if success then
            nameInput:SetText(newName)
            RefreshDropdown()
        else
            print("|cffFF0000ArenaCore:|r " .. (err or "Failed to rename profile"))
        end
    end)
    
    local createBtn = CreateProfileButton(settingsGroup, 145, 32, "Create New Profile", "primary")
    createBtn:SetPoint("TOPLEFT", 175, yOffset)
    createBtn:SetScript("OnClick", function()
        local newName = nameInput:GetText()
        
        if not newName or newName == "" then
            print("|cffFF0000ArenaCore:|r Please enter a profile name")
            return
        end
        
        local success, err = AC.ProfileManager:CreateProfile(newName)
        if success then
            RefreshDropdown()
            nameInput:SetText(newName)
            
            -- Update profile count in real-time
            if container.UpdateProfileCount then
                container.UpdateProfileCount()
            end
        else
            print("|cffFF0000ArenaCore:|r " .. tostring(err))
        end
    end)
    
    yOffset = yOffset - 45
    
    -- Buttons Row 2: Save (Delete moved to dropdown X buttons)
    local saveBtn = CreateProfileButton(settingsGroup, 300, 32, "Save to Current Profile", "success")
    saveBtn:SetPoint("TOPLEFT", 20, yOffset)
    saveBtn:SetScript("OnClick", function()
        local currentProfile = AC.ProfileManager:GetCurrentProfile()
        local success, err = AC.ProfileManager:SaveCurrentToProfile(currentProfile)
        if success then
            print("|cff8B45FFArenaCore:|r Profile saved successfully!")
        else
            print("|cffFF0000ArenaCore:|r " .. (err or "Failed to save profile"))
        end
    end)
    
    yOffset = yOffset - 60
    
    -- Separator line
    local separator = AC:CreateFlatTexture(settingsGroup, "OVERLAY", 1, COLORS.BORDER_LIGHT, 0.5)
    separator:SetPoint("TOPLEFT", 20, yOffset)
    separator:SetPoint("TOPRIGHT", -20, yOffset)
    separator:SetHeight(1)
    
    yOffset = yOffset - 25
    
    -- Profile Sharing Section
    local sharingTitle = AC:CreateStyledText(settingsGroup, "PROFILE SHARING", 13, COLORS.PRIMARY, "OVERLAY", CUSTOM_FONT)
    sharingTitle:SetPoint("TOPLEFT", 15, yOffset)
    
    yOffset = yOffset - 40
    
    -- Share and Import buttons
    local shareBtn = CreateProfileButton(settingsGroup, 145, 32, "Share Profile", "primary")
    shareBtn:SetPoint("TOPLEFT", 20, yOffset)
    shareBtn:SetScript("OnClick", function()
        local currentProfile = AC.ProfileManager:GetCurrentProfile()
        MoreFeatures:ShowExportWindow(currentProfile)
    end)
    
    local importBtn = CreateProfileButton(settingsGroup, 145, 32, "Import Profile", "primary")
    importBtn:SetPoint("TOPLEFT", 175, yOffset)
    importBtn:SetScript("OnClick", function()
        MoreFeatures:ShowImportWindow()
    end)
    
    yOffset = yOffset - 50
    
    -- Profile count display
    local function GetProfileCount()
        if not AC.ProfileManager then return "0/8" end
        local profiles = AC.ProfileManager:GetProfileList()
        return #profiles .. "/" .. (AC.ProfileManager.MAX_PROFILES or 8)
    end
    
    local profileCount = AC:CreateStyledText(settingsGroup, "Profiles: " .. GetProfileCount(), 11, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    profileCount:SetPoint("TOPLEFT", 20, yOffset)
    
    -- Store reference for updates
    settingsGroup.profileCount = profileCount
    settingsGroup.RefreshDropdown = RefreshDropdown
    
    -- CRITICAL: Store RefreshDropdown on container so import window can access it
    container.RefreshDropdown = RefreshDropdown
    container.UpdateProfileCount = function()
        profileCount:SetText("Profiles: " .. GetProfileCount())
    end
end

--- Show Export Profile Window
function MoreFeatures:ShowExportWindow(profileName)
    -- Generate export code
    local shareCode, err = AC.ProfileManager:ExportProfile(profileName)
    
    if not shareCode then
        print("|cffFF0000ArenaCore:|r Failed to export profile: " .. tostring(err))
        return
    end
    
    -- Create popup window
    local window = CreateFrame("Frame", "ArenaCoreExportWindow", UIParent, "BackdropTemplate")
    window:SetSize(500, 350)
    window:SetPoint("CENTER", 0, 0)
    window:SetFrameStrata("FULLSCREEN_DIALOG")
    window:SetFrameLevel(1000)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    
    -- Background
    local bg = AC:CreateFlatTexture(window, "BACKGROUND", 0, COLORS.BG, 1)
    bg:SetAllPoints()
    
    -- Border
    local border = AC:CreateFlatTexture(window, "BORDER", 0, COLORS.BORDER, 1)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    
    -- Purple accent line
    local accent = AC:CreateFlatTexture(window, "OVERLAY", 3, COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(3)
    
    -- Title
    local title = AC:CreateStyledText(window, "Share Profile: " .. profileName, 14, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
    title:SetPoint("TOP", 0, -15)
    
    -- Instructions
    local instructions = AC:CreateStyledText(window, "Copy the code below to share your profile:", 11, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    instructions:SetPoint("TOP", title, "BOTTOM", 0, -10)
    
    -- Scrollable text box with custom ArenaCore scrollbar (matching More Features window)
    local scrollFrame = CreateFrame("ScrollFrame", nil, window)
    scrollFrame:SetPoint("TOPLEFT", 20, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 50)
    scrollFrame:EnableMouseWheel(true)
    
    -- Background for scroll area
    local editBg = AC:CreateFlatTexture(scrollFrame, "BACKGROUND", 0, COLORS.INPUT_DARK, 1)
    editBg:SetAllPoints()
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth() - 20) -- Room for scrollbar
    editBox:SetAutoFocus(false)
    
    scrollFrame:SetScrollChild(editBox)
    
    -- Clean share code: remove any trailing/leading whitespace and newlines
    if shareCode then
        shareCode = shareCode:gsub("^%s+", ""):gsub("%s+$", "")  -- Trim whitespace
        shareCode = shareCode:gsub("\n", ""):gsub("\r", "")  -- Remove all newlines
    end
    
    -- Set text AFTER setting scroll child
    editBox:SetText(shareCode or "")
    editBox:SetCursorPosition(0)
    editBox:HighlightText()
    
    -- Select all on click
    editBox:SetScript("OnMouseDown", function(self)
        self:HighlightText()
    end)
    
    -- Custom scrollbar (EXACT pattern from More Features window)
    local scrollbar = CreateFrame("Slider", nil, window)
    scrollbar:SetPoint("TOPRIGHT", -22, -72)
    scrollbar:SetPoint("BOTTOMRIGHT", -22, 52)
    scrollbar:SetWidth(14)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetMinMaxValues(0, 1)
    scrollbar:SetValue(0)
    
    -- Track background
    local trackBg = AC:CreateFlatTexture(scrollbar, "BACKGROUND", 1, COLORS.INPUT_DARK, 1)
    trackBg:SetAllPoints()
    
    -- Thumb texture (same as More Features window)
    local thumbTexture = scrollbar:CreateTexture(nil, "OVERLAY")
    thumbTexture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga")
    thumbTexture:SetWidth(12)
    thumbTexture:SetHeight(20)
    scrollbar:SetThumbTexture(thumbTexture)
    
    -- Update scrollbar function
    local function UpdateScrollbar()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        if maxScroll > 0 then
            scrollbar:Show()
            scrollbar:SetMinMaxValues(0, maxScroll)
            scrollbar:SetValue(scrollFrame:GetVerticalScroll())
        else
            scrollbar:Hide()
        end
    end
    
    -- Connect scrollbar to scroll frame
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    
    scrollFrame:SetScript("OnScrollRangeChanged", function(self)
        UpdateScrollbar()
    end)
    
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        scrollbar:SetValue(offset)
    end)
    
    -- Mouse wheel support
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollbar:GetValue()
        local min, max = scrollbar:GetMinMaxValues()
        local step = 20
        if delta > 0 then
            scrollbar:SetValue(math.max(min, current - step))
        else
            scrollbar:SetValue(math.min(max, current + step))
        end
    end)
    
    -- Initial update
    C_Timer.After(0.1, function()
        -- Calculate proper height for editBox based on text
        local text = editBox:GetText()
        local lineCount = 1
        for _ in text:gmatch("\n") do
            lineCount = lineCount + 1
        end
        editBox:SetHeight(math.max(scrollFrame:GetHeight(), lineCount * 14))
        UpdateScrollbar()
    end)
    
    -- Helper function to create styled button with texture and depth
    local function CreateStyledButton(parent, width, height, text, isPrimary)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(width, height)
        
        if isPrimary then
            -- Primary button: Use purple textured button (like OK button in error popup)
            local texturePath = "Interface\\AddOns\\ArenaCore\\Media\\UI\\tab-purple-matte.tga"
            
            -- Background texture
            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetTexture(texturePath)
            bg:SetAllPoints()
            btn.bg = bg
            
            -- Highlight texture (glow on hover)
            local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetTexture(texturePath)
            highlight:SetAllPoints()
            highlight:SetBlendMode("ADD")
            highlight:SetAlpha(0.3)
            btn:SetHighlightTexture(highlight)
            
            -- Shadow for depth (bottom-right)
            local shadow = AC:CreateFlatTexture(btn, "BACKGROUND", -1, {0, 0, 0, 0.5}, 1)
            shadow:SetPoint("TOPLEFT", 2, -2)
            shadow:SetPoint("BOTTOMRIGHT", 2, -2)
            
        else
            -- Secondary button: Dark with border and depth
            -- Outer shadow for depth
            local shadow = AC:CreateFlatTexture(btn, "BACKGROUND", 0, {0, 0, 0, 0.6}, 1)
            shadow:SetPoint("TOPLEFT", 2, -2)
            shadow:SetPoint("BOTTOMRIGHT", 2, -2)
            
            -- Border
            local border = AC:CreateFlatTexture(btn, "BACKGROUND", 1, COLORS.BORDER_LIGHT, 1)
            border:SetPoint("TOPLEFT", -1, 1)
            border:SetPoint("BOTTOMRIGHT", 1, -1)
            
            -- Background
            local bg = AC:CreateFlatTexture(btn, "BACKGROUND", 2, COLORS.BG_DARK, 1)
            bg:SetAllPoints()
            btn.bg = bg
            
            -- Inner highlight for inset effect
            local innerHighlight = AC:CreateFlatTexture(btn, "BORDER", 0, COLORS.BORDER_LIGHT, 0.3)
            innerHighlight:SetPoint("TOPLEFT", 1, -1)
            innerHighlight:SetPoint("TOPRIGHT", -1, -1)
            innerHighlight:SetHeight(1)
            
            -- Hover glow
            local glow = AC:CreateFlatTexture(btn, "OVERLAY", 0, COLORS.PRIMARY, 0)
            glow:SetAllPoints(bg)
            btn.glow = glow
        end
        
        -- Text
        local label = AC:CreateStyledText(btn, text, 13, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
        label:SetPoint("CENTER", 0, 0)
        btn.label = label
        
        -- Hover effects (text stays visible, only texture changes)
        btn:SetScript("OnEnter", function(self)
            if isPrimary then
                -- Brighten texture on hover
                if self.bg then
                    self.bg:SetVertexColor(1.3, 1.3, 1.3, 1)
                end
            else
                -- Show purple glow on hover
                if self.glow then
                    self.glow:SetAlpha(0.2)
                end
            end
            -- Text stays white (no color change to keep it visible)
        end)
        
        btn:SetScript("OnLeave", function(self)
            if isPrimary then
                -- Reset texture brightness
                if self.bg then
                    self.bg:SetVertexColor(1, 1, 1, 1)
                end
            else
                -- Hide glow
                if self.glow then
                    self.glow:SetAlpha(0)
                end
            end
            -- Text stays white (always visible)
        end)
        
        -- Click effect
        btn:SetScript("OnMouseDown", function(self)
            if self.bg then
                self.bg:SetVertexColor(0.7, 0.7, 0.7, 1)
            end
        end)
        
        btn:SetScript("OnMouseUp", function(self)
            if self.bg then
                self.bg:SetVertexColor(isPrimary and 1.3 or 1, isPrimary and 1.3 or 1, isPrimary and 1.3 or 1, 1)
            end
        end)
        
        return btn
    end
    
    -- Select All button
    local copyBtn = CreateStyledButton(window, 140, 36, "Select All", true)
    copyBtn:SetPoint("BOTTOMLEFT", 20, 10)
    copyBtn:SetScript("OnClick", function()
        editBox:HighlightText()
        editBox:SetFocus()
    end)
    
    -- Close button (red button texture with "Close" text)
    local closeBtn = CreateFrame("Button", nil, window)
    closeBtn:SetSize(140, 36)
    closeBtn:SetPoint("BOTTOMRIGHT", -20, 10)
    
    -- Use red button texture
    local texturePath = "Interface\\AddOns\\ArenaCore\\Media\\button-hide.tga"
    local bg = closeBtn:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(texturePath)
    bg:SetAllPoints()
    closeBtn.bg = bg
    
    -- Highlight texture (glow on hover)
    local highlight = closeBtn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture(texturePath)
    highlight:SetAllPoints()
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.3)
    closeBtn:SetHighlightTexture(highlight)
    
    -- Shadow for depth
    local shadow = AC:CreateFlatTexture(closeBtn, "BACKGROUND", -1, {0, 0, 0, 0.5}, 1)
    shadow:SetPoint("TOPLEFT", 2, -2)
    shadow:SetPoint("BOTTOMRIGHT", 2, -2)
    
    -- "Close" text (always visible, no color change on hover)
    local closeText = AC:CreateStyledText(closeBtn, "Close", 13, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
    closeText:SetPoint("CENTER", 0, 0)
    closeBtn.closeText = closeText
    
    -- Hover effects (only brighten texture, text stays same)
    closeBtn:SetScript("OnEnter", function(self)
        self.bg:SetVertexColor(1.3, 1.3, 1.3, 1)
    end)
    
    closeBtn:SetScript("OnLeave", function(self)
        self.bg:SetVertexColor(1, 1, 1, 1)
    end)
    
    closeBtn:SetScript("OnMouseDown", function(self)
        self.bg:SetVertexColor(0.7, 0.7, 0.7, 1)
    end)
    
    closeBtn:SetScript("OnMouseUp", function(self)
        self.bg:SetVertexColor(1.3, 1.3, 1.3, 1)
    end)
    
    closeBtn:SetScript("OnClick", function()
        window:Hide()
    end)
    
    -- Close on escape
    window:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            window:Hide()
        end
    end)
    
    window:Show()
    
    -- Auto-select text
    C_Timer.After(0.1, function()
        editBox:HighlightText()
        editBox:SetFocus()
    end)
end

--- Show Import Profile Window
function MoreFeatures:ShowImportWindow()
    -- Create popup window
    local window = CreateFrame("Frame", "ArenaCoreImportWindow", UIParent, "BackdropTemplate")
    window:SetSize(500, 400)
    window:SetPoint("CENTER", 0, 0)
    window:SetFrameStrata("FULLSCREEN_DIALOG") -- FIXED: Higher strata so it shows above More Features
    window:SetFrameLevel(1000)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    
    -- Background
    local bg = AC:CreateFlatTexture(window, "BACKGROUND", 0, COLORS.BG, 1)
    bg:SetAllPoints()
    
    -- Border
    local border = AC:CreateFlatTexture(window, "BORDER", 0, COLORS.BORDER, 1)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    
    -- Purple accent line
    local accent = AC:CreateFlatTexture(window, "OVERLAY", 3, COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(3)
    
    -- Title
    local title = AC:CreateStyledText(window, "Import Profile", 14, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
    title:SetPoint("TOP", 0, -15)
    
    -- Close button (red X button in top-right corner)
    local closeBtn = CreateFrame("Button", nil, window)
    closeBtn:SetSize(32, 32)
    closeBtn:SetPoint("TOPRIGHT", -8, -8)
    
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-close.tga")
    closeBg:SetAllPoints()
    closeBtn.bg = closeBg
    
    local closeX = AC:CreateStyledText(closeBtn, "×", 20, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
    closeX:SetPoint("CENTER", 0, 0)
    closeBtn.xText = closeX
    
    closeBtn:SetScript("OnEnter", function(self)
        self.bg:SetVertexColor(1.3, 1.3, 1.3, 1)
        self.xText:SetTextColor(1, 0.3, 0.3, 1)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self.bg:SetVertexColor(1, 1, 1, 1)
        self.xText:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
    end)
    closeBtn:SetScript("OnClick", function()
        window:Hide()
    end)
    
    -- Instructions
    local instructions = AC:CreateStyledText(window, "Paste profile code below:", 11, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    instructions:SetPoint("TOP", title, "BOTTOM", 0, -10)
    
    -- Scrollable text box with custom ArenaCore scrollbar (matching Share Profile window)
    local scrollFrame = CreateFrame("ScrollFrame", nil, window)
    scrollFrame:SetPoint("TOPLEFT", 20, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 165)
    scrollFrame:EnableMouseWheel(true)
    
    -- Background for scroll area
    local editBg = AC:CreateFlatTexture(scrollFrame, "BACKGROUND", 0, COLORS.INPUT_DARK, 1)
    editBg:SetAllPoints()
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth() - 20) -- Room for scrollbar
    editBox:SetAutoFocus(true)
    
    -- CRITICAL: Clean text when it changes (removes newlines added by paste)
    editBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text and (text:find("\n") or text:find("\r")) then
            -- Remove all newlines silently
            local cleaned = text:gsub("\n", ""):gsub("\r", "")
            self:SetText(cleaned)
            self:SetCursorPosition(#cleaned)
        end
    end)
    
    scrollFrame:SetScrollChild(editBox)
    
    -- Custom scrollbar (same as Share Profile window)
    local scrollbar = CreateFrame("Slider", nil, window)
    scrollbar:SetPoint("TOPRIGHT", -22, -72)
    scrollbar:SetPoint("BOTTOMRIGHT", -22, 167)
    scrollbar:SetWidth(14)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetMinMaxValues(0, 1)
    scrollbar:SetValue(0)
    
    -- Track background
    local trackBg = AC:CreateFlatTexture(scrollbar, "BACKGROUND", 1, COLORS.INPUT_DARK, 1)
    trackBg:SetAllPoints()
    
    -- Thumb texture
    local thumbTexture = scrollbar:CreateTexture(nil, "OVERLAY")
    thumbTexture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga")
    thumbTexture:SetWidth(12)
    thumbTexture:SetHeight(20)
    scrollbar:SetThumbTexture(thumbTexture)
    
    -- Update scrollbar function
    local function UpdateScrollbar()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        if maxScroll > 0 then
            scrollbar:Show()
            scrollbar:SetMinMaxValues(0, maxScroll)
            scrollbar:SetValue(scrollFrame:GetVerticalScroll())
        else
            scrollbar:Hide()
        end
    end
    
    -- Connect scrollbar to scroll frame
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    
    scrollFrame:SetScript("OnScrollRangeChanged", function(self)
        UpdateScrollbar()
    end)
    
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        scrollbar:SetValue(offset)
    end)
    
    -- Mouse wheel support
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollbar:GetValue()
        local min, max = scrollbar:GetMinMaxValues()
        local step = 20
        if delta > 0 then
            scrollbar:SetValue(math.max(min, current - step))
        else
            scrollbar:SetValue(math.min(max, current + step))
        end
    end)
    
    -- Initial update
    C_Timer.After(0.1, function()
        UpdateScrollbar()
    end)
    
    -- Status text (positioned at top of bottom section, well above everything)
    local statusText = window:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(CUSTOM_FONT, 11, "")
    statusText:SetPoint("BOTTOMLEFT", 20, 120)
    statusText:SetPoint("BOTTOMRIGHT", -20, 120)
    statusText:SetJustifyH("LEFT")
    statusText:SetWordWrap(true)
    statusText:SetTextColor(COLORS.TEXT_MUTED[1], COLORS.TEXT_MUTED[2], COLORS.TEXT_MUTED[3], 1)
    statusText:SetText("")
    
    -- Instruction text above profile name
    local instructionText = AC:CreateStyledText(window, "Enter a name for the imported profile:", 10, COLORS.TEXT_MUTED, "OVERLAY", CUSTOM_FONT)
    instructionText:SetPoint("BOTTOMLEFT", 20, 100)
    
    -- Profile name label
    local nameLabel = AC:CreateStyledText(window, "Profile Name:", 11, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    nameLabel:SetPoint("BOTTOMLEFT", 20, 85)
    
    -- Profile name input with visible text box
    local nameInputContainer = CreateFrame("Frame", nil, window)
    nameInputContainer:SetPoint("BOTTOMLEFT", 20, 45)
    nameInputContainer:SetSize(300, 32)
    
    -- Visible background for text input (darker, more prominent)
    local inputBg = AC:CreateFlatTexture(nameInputContainer, "BACKGROUND", 0, COLORS.INPUT_DARK, 1)
    inputBg:SetAllPoints()
    
    -- Border for text input
    local inputBorder = AC:CreateFlatTexture(nameInputContainer, "BORDER", 0, COLORS.BORDER, 1)
    inputBorder:SetPoint("TOPLEFT", -1, 1)
    inputBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    
    -- Inner shadow for depth
    local inputShadow = AC:CreateFlatTexture(nameInputContainer, "ARTWORK", 0, {0, 0, 0, 0.3}, 1)
    inputShadow:SetPoint("TOPLEFT", 1, -1)
    inputShadow:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- EditBox inside the container
    local nameInput = CreateFrame("EditBox", nil, nameInputContainer)
    nameInput:SetPoint("LEFT", 8, 0)
    nameInput:SetPoint("RIGHT", -8, 0)
    nameInput:SetHeight(32)
    nameInput:SetAutoFocus(false)
    nameInput:SetFontObject(GameFontNormal)
    nameInput:SetMaxLetters(50)
    nameInput:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
    nameInput:SetText("")
    nameInput:SetCursorPosition(0)
    
    -- Placeholder text
    local placeholderText = nameInput:CreateFontString(nil, "OVERLAY")
    placeholderText:SetFont(CUSTOM_FONT, 11, "")
    placeholderText:SetPoint("LEFT", 8, 0)
    placeholderText:SetTextColor(COLORS.TEXT_MUTED[1], COLORS.TEXT_MUTED[2], COLORS.TEXT_MUTED[3], 0.5)
    placeholderText:SetText("Enter profile name...")
    
    -- Show/hide placeholder based on text
    nameInput:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text and text ~= "" then
            placeholderText:Hide()
        else
            placeholderText:Show()
        end
    end)
    
    -- Focus effects
    nameInput:SetScript("OnEditFocusGained", function(self)
        inputBorder:SetVertexColor(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 1)
    end)
    
    nameInput:SetScript("OnEditFocusLost", function(self)
        inputBorder:SetVertexColor(COLORS.BORDER[1], COLORS.BORDER[2], COLORS.BORDER[3], 1)
    end)
    
    -- Import button (purple textured button)
    local importBtn = CreateFrame("Button", nil, window)
    importBtn:SetSize(140, 36)
    importBtn:SetPoint("BOTTOMLEFT", 20, 10)
    
    local importBg = importBtn:CreateTexture(nil, "BACKGROUND")
    importBg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\tab-purple-matte.tga")
    importBg:SetAllPoints()
    importBtn.bg = importBg
    
    local importHighlight = importBtn:CreateTexture(nil, "HIGHLIGHT")
    importHighlight:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\tab-purple-matte.tga")
    importHighlight:SetAllPoints()
    importHighlight:SetBlendMode("ADD")
    importHighlight:SetAlpha(0.3)
    importBtn:SetHighlightTexture(importHighlight)
    
    local importShadow = AC:CreateFlatTexture(importBtn, "BACKGROUND", -1, {0, 0, 0, 0.5}, 1)
    importShadow:SetPoint("TOPLEFT", 2, -2)
    importShadow:SetPoint("BOTTOMRIGHT", 2, -2)
    
    local importText = AC:CreateStyledText(importBtn, "Import", 13, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
    importText:SetPoint("CENTER", 0, 0)
    importBtn.importText = importText
    
    importBtn:SetScript("OnEnter", function(self)
        self.bg:SetVertexColor(1.3, 1.3, 1.3, 1)
    end)
    importBtn:SetScript("OnLeave", function(self)
        self.bg:SetVertexColor(1, 1, 1, 1)
    end)
    importBtn:SetScript("OnMouseDown", function(self)
        self.bg:SetVertexColor(0.7, 0.7, 0.7, 1)
    end)
    importBtn:SetScript("OnMouseUp", function(self)
        self.bg:SetVertexColor(1.3, 1.3, 1.3, 1)
    end)
    importBtn:SetScript("OnClick", function()
        local shareCode = editBox:GetText()
        local profileName = nameInput:GetText()
        
        -- Clear previous status
        statusText:SetText("")
        
        -- Validation
        if not shareCode or shareCode == "" then
            statusText:SetText("|cffFF0000Error: Please paste a profile code|r")
            print("|cffFF0000ArenaCore:|r Please paste a profile code")
            return
        end
        
        if not profileName or profileName == "" then
            statusText:SetText("|cffFF0000Error: Please enter a profile name|r")
            print("|cffFF0000ArenaCore:|r Please enter a profile name")
            return
        end
        
        -- Check if ProfileManager exists
        if not AC.ProfileManager then
            statusText:SetText("|cffFF0000Error: ProfileManager not found|r")
            print("|cffFF0000ArenaCore:|r ProfileManager not found")
            return
        end
        
        -- Show importing message
        statusText:SetText("|cffFFFF00Importing profile...|r")
        
        -- Clean whitespace from code
        local cleanCode = shareCode:gsub("%s", ""):gsub("\n", ""):gsub("\r", ""):gsub("\t", "")
        if #cleanCode ~= #shareCode then
            shareCode = cleanCode
        end
        
        -- Import profile (now auto-activates)
        local success, err = AC.ProfileManager:ImportProfile(shareCode, profileName)
        if success then
            statusText:SetText("|cff00FF00Profile imported and activated!|r")
            print("|cff8B45FFArenaCore:|r Profile '" .. profileName .. "' imported and activated!")
            
            -- Refresh profiles page if it's open
            if MoreFeatures.pageContainers and MoreFeatures.pageContainers["profiles"] then
                local container = MoreFeatures.pageContainers["profiles"]
                if container.RefreshDropdown then
                    -- Refresh immediately (no delay needed)
                    container.RefreshDropdown()
                end
                if container.UpdateProfileCount then
                    container.UpdateProfileCount()
                end
            end
            
            -- Close window after success
            C_Timer.After(1.5, function()
                window:Hide()
            end)
        else
            local errorMsg = err or "Import failed - unknown error"
            
            -- Make error message more helpful
            if errorMsg:find("Base85") or errorMsg:find("decode") then
                errorMsg = "Invalid or corrupted profile code. Make sure you copied the entire code."
            elseif errorMsg:find("decompress") then
                errorMsg = "Profile code is corrupted or incomplete. Try copying it again."
            elseif errorMsg:find("deserialize") or errorMsg:find("parse") then
                errorMsg = "Profile code format error. The profile may have been exported incorrectly. Try exporting it again from the source."
            end
            
            statusText:SetText("|cffFF0000Error: " .. errorMsg .. "|r")
            print("|cffFF0000ArenaCore:|r Import failed - " .. errorMsg)
        end
    end)
    
    -- Cancel button (red textured button)
    local cancelBtn = CreateFrame("Button", nil, window)
    cancelBtn:SetSize(140, 36)
    cancelBtn:SetPoint("BOTTOMRIGHT", -20, 10)
    
    local cancelBg = cancelBtn:CreateTexture(nil, "BACKGROUND")
    cancelBg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-hide.tga")
    cancelBg:SetAllPoints()
    cancelBtn.bg = cancelBg
    
    local cancelHighlight = cancelBtn:CreateTexture(nil, "HIGHLIGHT")
    cancelHighlight:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-hide.tga")
    cancelHighlight:SetAllPoints()
    cancelHighlight:SetBlendMode("ADD")
    cancelHighlight:SetAlpha(0.3)
    cancelBtn:SetHighlightTexture(cancelHighlight)
    
    local cancelShadow = AC:CreateFlatTexture(cancelBtn, "BACKGROUND", -1, {0, 0, 0, 0.5}, 1)
    cancelShadow:SetPoint("TOPLEFT", 2, -2)
    cancelShadow:SetPoint("BOTTOMRIGHT", 2, -2)
    
    local cancelText = AC:CreateStyledText(cancelBtn, "Cancel", 13, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
    cancelText:SetPoint("CENTER", 0, 0)
    cancelBtn.cancelText = cancelText
    
    cancelBtn:SetScript("OnEnter", function(self)
        self.bg:SetVertexColor(1.3, 1.3, 1.3, 1)
    end)
    cancelBtn:SetScript("OnLeave", function(self)
        self.bg:SetVertexColor(1, 1, 1, 1)
    end)
    cancelBtn:SetScript("OnMouseDown", function(self)
        self.bg:SetVertexColor(0.7, 0.7, 0.7, 1)
    end)
    cancelBtn:SetScript("OnMouseUp", function(self)
        self.bg:SetVertexColor(1.3, 1.3, 1.3, 1)
    end)
    cancelBtn:SetScript("OnClick", function()
        window:Hide()
    end)
    
    -- Close on escape
    window:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            window:Hide()
        end
    end)
    
    window:Show()
    editBox:SetFocus()
end

--- Show Reload Confirmation Popup (matches theme reload style)
function MoreFeatures:ShowReloadConfirmation(profileName)
    -- Create popup frame
    local popup = CreateFrame("Frame", "ArenaCoreProfileReloadPopup", UIParent)
    popup:SetSize(400, 150)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(9999)
    
    -- Red textured background using button-hide.tga
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-hide.tga")
    bg:SetVertexColor(1, 0.2, 0.2, 1) -- Red tint
    
    -- Dark overlay for text readability
    local overlay = popup:CreateTexture(nil, "BORDER")
    overlay:SetAllPoints()
    overlay:SetColorTexture(0, 0, 0, 0.4) -- 40% black overlay
    
    -- Title (clean white, no outline)
    local title = popup:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    title:SetPoint("TOP", 0, -15)
    title:SetTextColor(1, 1, 1, 1)
    title:SetText("RELOAD RECOMMENDED")
    
    -- Message
    local message = popup:CreateFontString(nil, "OVERLAY")
    message:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    message:SetPoint("TOP", title, "BOTTOM", 0, -15)
    message:SetWidth(360)
    message:SetJustifyH("CENTER")
    message:SetText("Profile switched to |cff8B45FF" .. profileName .. "|r\n\nA reload is recommended to apply all settings.\nClick OK to reload now, or Cancel to reload later.")
    
    -- OK Button
    local okBtn = CreateFrame("Button", nil, popup)
    okBtn:SetSize(120, 35)
    okBtn:SetPoint("BOTTOM", -65, 15)
    
    local okBg = okBtn:CreateTexture(nil, "BACKGROUND")
    okBg:SetAllPoints()
    okBg:SetColorTexture(0.2, 0.6, 0.2, 1)
    
    local okText = okBtn:CreateFontString(nil, "OVERLAY")
    okText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    okText:SetPoint("CENTER")
    okText:SetText("OK (Reload)")
    
    okBtn:SetScript("OnEnter", function(self)
        okBg:SetColorTexture(0.3, 0.8, 0.3, 1)
    end)
    okBtn:SetScript("OnLeave", function(self)
        okBg:SetColorTexture(0.2, 0.6, 0.2, 1)
    end)
    okBtn:SetScript("OnClick", function()
        popup:Hide()
        ReloadUI()
    end)
    
    -- Cancel Button
    local cancelBtn = CreateFrame("Button", nil, popup)
    cancelBtn:SetSize(120, 35)
    cancelBtn:SetPoint("BOTTOM", 65, 15)
    
    local cancelBg = cancelBtn:CreateTexture(nil, "BACKGROUND")
    cancelBg:SetAllPoints()
    cancelBg:SetColorTexture(0.3, 0.3, 0.3, 1)
    
    local cancelText = cancelBtn:CreateFontString(nil, "OVERLAY")
    cancelText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    cancelText:SetPoint("CENTER")
    cancelText:SetText("Cancel")
    
    cancelBtn:SetScript("OnEnter", function(self)
        cancelBg:SetColorTexture(0.4, 0.4, 0.4, 1)
    end)
    cancelBtn:SetScript("OnLeave", function(self)
        cancelBg:SetColorTexture(0.3, 0.3, 0.3, 1)
    end)
    cancelBtn:SetScript("OnClick", function()
        popup:Hide()
        print("|cffFFAA00ArenaCore:|r Profile will fully apply after next /reload")
    end)
    
    -- Close on Escape
    popup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            popup:Hide()
            print("|cffFFAA00ArenaCore:|r Profile will fully apply after next /reload")
        end
    end)
    popup:EnableKeyboard(true)
    
    popup:Show()
end

--- Show Delete Confirmation Popup (styled to match ArenaCore)
function MoreFeatures:ShowDeleteConfirmation(profileName, onConfirm)
    -- Create popup frame
    local popup = CreateFrame("Frame", "ArenaCoreDeleteProfilePopup", UIParent)
    popup:SetSize(420, 180)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(9999)
    
    -- Red textured background using button-hide.tga
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-hide.tga")
    bg:SetVertexColor(0.8, 0.15, 0.15, 1) -- Dark red tint
    
    -- Dark overlay for text readability
    local overlay = popup:CreateTexture(nil, "BORDER")
    overlay:SetAllPoints()
    overlay:SetColorTexture(0, 0, 0, 0.5) -- 50% black overlay
    
    -- Purple accent line at top (ArenaCore branding)
    local accent = popup:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(3)
    accent:SetColorTexture(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 1)
    
    -- Title (moved up, no icon)
    local title = popup:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    title:SetPoint("TOP", 0, -25)
    title:SetTextColor(1, 1, 1, 1)
    title:SetText("DELETE PROFILE")
    
    -- Message (moved up closer to title)
    local message = popup:CreateFontString(nil, "OVERLAY")
    message:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    message:SetPoint("TOP", title, "BOTTOM", 0, -20)
    message:SetWidth(380)
    message:SetJustifyH("CENTER")
    message:SetTextColor(1, 1, 1, 1)
    message:SetText("Are you sure you want to delete\n|cff8B45FF" .. profileName .. "|r?\n\n|cffFF4444This action cannot be undone!|r")
    
    -- Delete Button (danger style)
    local deleteBtn = CreateFrame("Button", nil, popup)
    deleteBtn:SetSize(140, 38)
    deleteBtn:SetPoint("BOTTOM", -75, 15)
    
    local deleteBg = deleteBtn:CreateTexture(nil, "BACKGROUND")
    deleteBg:SetAllPoints()
    deleteBg:SetColorTexture(0.8, 0.2, 0.2, 1)
    
    local deleteBorder = deleteBtn:CreateTexture(nil, "BORDER")
    deleteBorder:SetAllPoints()
    deleteBorder:SetColorTexture(0.6, 0.1, 0.1, 1)
    deleteBg:SetPoint("TOPLEFT", 1, -1)
    deleteBg:SetPoint("BOTTOMRIGHT", -1, 1)
    
    local deleteText = deleteBtn:CreateFontString(nil, "OVERLAY")
    deleteText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    deleteText:SetPoint("CENTER")
    deleteText:SetTextColor(1, 1, 1, 1)
    deleteText:SetText("Delete")
    
    deleteBtn:SetScript("OnEnter", function(self)
        deleteBg:SetColorTexture(0.9, 0.3, 0.3, 1)
    end)
    deleteBtn:SetScript("OnLeave", function(self)
        deleteBg:SetColorTexture(0.8, 0.2, 0.2, 1)
    end)
    deleteBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        popup:Hide()
        if onConfirm then
            onConfirm()
        end
    end)
    
    -- Cancel Button
    local cancelBtn = CreateFrame("Button", nil, popup)
    cancelBtn:SetSize(140, 38)
    cancelBtn:SetPoint("BOTTOM", 75, 15)
    
    local cancelBg = cancelBtn:CreateTexture(nil, "BACKGROUND")
    cancelBg:SetAllPoints()
    cancelBg:SetColorTexture(0.3, 0.3, 0.3, 1)
    
    local cancelBorder = cancelBtn:CreateTexture(nil, "BORDER")
    cancelBorder:SetAllPoints()
    cancelBorder:SetColorTexture(0.2, 0.2, 0.2, 1)
    cancelBg:SetPoint("TOPLEFT", 1, -1)
    cancelBg:SetPoint("BOTTOMRIGHT", -1, 1)
    
    local cancelText = cancelBtn:CreateFontString(nil, "OVERLAY")
    cancelText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    cancelText:SetPoint("CENTER")
    cancelText:SetTextColor(1, 1, 1, 1)
    cancelText:SetText("Cancel")
    
    cancelBtn:SetScript("OnEnter", function(self)
        cancelBg:SetColorTexture(0.4, 0.4, 0.4, 1)
    end)
    cancelBtn:SetScript("OnLeave", function(self)
        cancelBg:SetColorTexture(0.3, 0.3, 0.3, 1)
    end)
    cancelBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        popup:Hide()
    end)
    
    -- Close on Escape
    popup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
            popup:Hide()
        end
    end)
    popup:EnableKeyboard(true)
    
    popup:Show()
end

--- Show Active Profile Error Popup
function MoreFeatures:ShowActiveProfileError()
    -- Create small error popup
    local popup = CreateFrame("Frame", "ArenaCoreActiveProfileError", UIParent)
    popup:SetSize(350, 120)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(9999)
    
    -- Red textured background
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-hide.tga")
    bg:SetVertexColor(0.8, 0.2, 0.2, 1)
    
    -- Dark overlay
    local overlay = popup:CreateTexture(nil, "BORDER")
    overlay:SetAllPoints()
    overlay:SetColorTexture(0, 0, 0, 0.5)
    
    -- Purple accent line
    local accent = popup:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(3)
    accent:SetColorTexture(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 1)
    
    -- Title
    local title = popup:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    title:SetPoint("TOP", 0, -20)
    title:SetTextColor(1, 1, 1, 1)
    title:SetText("CANNOT DELETE ACTIVE PROFILE")
    
    -- Message
    local message = popup:CreateFontString(nil, "OVERLAY")
    message:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    message:SetPoint("TOP", title, "BOTTOM", 0, -12)
    message:SetWidth(320)
    message:SetJustifyH("CENTER")
    message:SetTextColor(1, 1, 1, 1)
    message:SetText("Please switch to another profile first.")
    
    -- OK Button (using same purple textured button as Save Settings)
    local okBtn = AC:CreateTexturedButton(popup, 100, 32, "OK", "UI\\tab-purple-matte")
    okBtn:SetPoint("BOTTOM", 0, 12)
    okBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        popup:Hide()
    end)
    
    -- Close on Escape
    popup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
            popup:Hide()
        end
    end)
    popup:EnableKeyboard(true)
    
    popup:Show()
end

-- Load Coming Soon content (simple placeholder page)
function MoreFeatures:LoadComingSoonContent(pageId, container)
    if not container then return end
    local title = AC:CreateStyledText(container, "Coming Soon...", 16, COLORS.TEXT, "OVERLAY", CUSTOM_FONT)
    title:SetPoint("TOP", 0, -20)

    local description = AC:CreateStyledText(container, "This feature is planned for a future update.\nStay tuned for more exciting additions!", 12, COLORS.TEXT_2, "OVERLAY", CUSTOM_FONT)
    description:SetPoint("TOP", title, "BOTTOM", 0, -15)
    description:SetJustifyH("CENTER")
end

-- Blizzard frame hiding is now always enabled automatically via BlizzFrameHider.lua
-- No toggle needed - removed OnBlizzFrameToggle function

-- Apply or remove the /gg slash command based on setting
function MoreFeatures:ApplySurrenderSetting()
    local enabled = AC and AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures and AC.DB.profile.moreFeatures.surrenderGGEnabled
    
    -- Remove existing bindings first
    SlashCmdList.ACGG = nil
    _G.SLASH_ACGG1 = nil
    
    -- Debug: Check what we're seeing (DISABLED)
    -- local surrenderExists = SurrenderArena ~= nil
    -- print("|cff8B45FFArenaCore Surrender:|r Enabled=" .. tostring(enabled) .. ", SurrenderArena exists=" .. tostring(surrenderExists))
    
    if enabled and SurrenderArena then
        -- Direct binding - SurrenderArena handles arena context internally
        _G.SLASH_ACGG1 = "/gg"
        SlashCmdList.ACGG = function(msg)
            print("|cff8B45FFArenaCore:|r /gg command called - attempting surrender...")
            SurrenderArena()
        end
        -- print("|cff8B45FFArenaCore:|r /gg surrender command registered")
    elseif enabled and not SurrenderArena then
        print("|cffFF0000ArenaCore:|r Surrender enabled but SurrenderArena function not found")
    end
end

-- Show reload confirmation popup for font changes
function MoreFeatures:ShowFontReloadPopup(fontType)
    -- Create popup frame (INCREASED HEIGHT from 150 to 180 for better text fitting)
    local popup = CreateFrame("Frame", "ArenaCoreFontReloadPopup", UIParent)
    popup:SetSize(400, 180)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(9999)
    
    -- Red textured background using button-hide.tga
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-hide.tga")
    bg:SetVertexColor(1, 0.2, 0.2, 1) -- Red tint
    
    -- Dark overlay for text readability
    local overlay = popup:CreateTexture(nil, "BORDER")
    overlay:SetAllPoints()
    overlay:SetColorTexture(0, 0, 0, 0.4) -- 40% black overlay
    
    -- Title (clean white, no outline)
    local title = popup:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    title:SetPoint("TOP", 0, -15)
    title:SetTextColor(1, 1, 1, 1)
    title:SetText("RELOAD REQUIRED")
    
    -- Message (increased spacing for better readability)
    local message = popup:CreateFontString(nil, "OVERLAY")
    message:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    message:SetPoint("TOP", title, "BOTTOM", 0, -20)
    message:SetWidth(360)
    message:SetJustifyH("CENTER")
    
    local messageText = ""
    if fontType == "global" then
        messageText = "Global font setting changed.\n\nYou must reload your UI for the font changes to fully take effect.\n\nClick OK to reload now, or Cancel to reload later."
    elseif fontType == "actionbar" then
        messageText = "Action bar font setting changed.\n\nYou must reload your UI for the font changes to fully take effect.\n\nClick OK to reload now, or Cancel to reload later."
    end
    message:SetText(messageText)
    
    -- OK Button (GREEN TEXTURED - matching profiles page style)
    local okBtn = AC:CreateTexturedButton(popup, 120, 35, "OK (Reload)", "button-save")
    okBtn:SetPoint("BOTTOM", -65, 15)
    okBtn:SetScript("OnClick", function()
        popup:Hide()
        ReloadUI()
    end)
    
    -- Cancel Button (GRAY TEXTURED - matching profiles page style)
    local cancelBtn = AC:CreateTexturedButton(popup, 120, 35, "Cancel", "button-cancel")
    cancelBtn:SetPoint("BOTTOM", 65, 15)
    cancelBtn:SetScript("OnClick", function()
        popup:Hide()
    end)
    
    popup:Show()
end

-- Apply or remove global ArenaCore font
function MoreFeatures:ApplyGlobalFont(enabled, skipPopup)
    if enabled then
        -- Enable GlobalFont module (NOT action bar-only mode)
        if AC.GlobalFont then
            local fontPath = "Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf"
            local useOutline = AC.DB.profile.moreFeatures.globalFontOutline ~= false
            local useShadow = AC.DB.profile.moreFeatures.globalFontShadow ~= false
            local fontFlags = useOutline and "OUTLINE" or ""
            
            AC.GlobalFont:UpdateSettings(fontPath, fontFlags, useShadow)
            AC.GlobalFont:Enable(false)  -- false = NOT action bar-only mode
        end
        
        -- CRITICAL: Apply action bar fonts when global font is enabled
        if self.ApplyActionBarFonts then
            self:ApplyActionBarFonts()
        end
        
        -- Show reload popup ONLY if not skipped (user manually toggled)
        if not skipPopup then
            self:ShowFontReloadPopup("global")
        end
    else
        -- Disable GlobalFont module and revert fonts
        if AC.GlobalFont then
            AC.GlobalFont:Disable()
        end
        
        -- CRITICAL: Revert action bar fonts when global font is disabled
        if self.RevertActionBarFonts then
            self:RevertActionBarFonts()
        end
        
        -- Show reload popup ONLY if not skipped (user manually toggled)
        if not skipPopup then
            self:ShowFontReloadPopup("global")
        end
    end
end

-- Apply or remove action bar-only ArenaCore font (NEW FEATURE)
function MoreFeatures:ApplyActionBarFont(enabled, skipPopup)
    if enabled then
        -- Enable GlobalFont module in ACTION BAR-ONLY mode
        if AC.GlobalFont then
            local fontPath = "Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf"
            local useOutline = AC.DB.profile.moreFeatures.globalFontOutline ~= false
            local useShadow = AC.DB.profile.moreFeatures.globalFontShadow ~= false
            local fontFlags = useOutline and "OUTLINE" or ""
            
            AC.GlobalFont:UpdateSettings(fontPath, fontFlags, useShadow)
            AC.GlobalFont:Enable(true)  -- true = ACTION BAR-ONLY mode
        end
        
        -- Show reload popup ONLY if not skipped (user manually toggled)
        if not skipPopup then
            self:ShowFontReloadPopup("actionbar")
        end
    else
        -- Disable GlobalFont module and revert fonts
        if AC.GlobalFont then
            AC.GlobalFont:Disable()
        end
        
        -- Show reload popup ONLY if not skipped (user manually toggled)
        if not skipPopup then
            self:ShowFontReloadPopup("actionbar")
        end
    end
end

-- Removed old debug function - now using ApplyToSingleButton directly

-- Setup event-driven action bar font system (MattActionBarFont pattern - ZERO TAINT!)
function MoreFeatures:SetupActionBarHook()
    if self.actionBarHookSetup then return end
    self.actionBarHookSetup = true
    
    -- Create event frame for action bar font updates
    local eventFrame = _G._AC_ABFont or CreateFrame("Frame")
    _G._AC_ABFont = eventFrame
    
    -- Register events (MattActionBarFont pattern)
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("UPDATE_BINDINGS")
    
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_LOGIN" then
            -- CRITICAL: Only apply fonts if global font is enabled
            if AC.MoreFeatures then
                local enabled = AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures and AC.DB.profile.moreFeatures.globalFontEnabled
                if enabled then
                    AC.MoreFeatures:ApplyActionBarFonts()
                end
            end
        elseif event == "UPDATE_BINDINGS" then
            -- CRITICAL: Only apply fonts if global font is enabled
            C_Timer.After(0.2, function()
                if AC.MoreFeatures then
                    local enabled = AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures and AC.DB.profile.moreFeatures.globalFontEnabled
                    if enabled then
                        AC.MoreFeatures:ApplyActionBarFonts()
                    end
                end
            end)
        end
    end)
    
    -- Hook QuickKeybindFrame to reapply after keybind mode closes
    if QuickKeybindFrame then
        QuickKeybindFrame:HookScript("OnHide", function()
            -- CRITICAL: Only apply fonts if global font is enabled
            if AC.MoreFeatures then
                local enabled = AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures and AC.DB.profile.moreFeatures.globalFontEnabled
                if enabled then
                    AC.MoreFeatures:ApplyActionBarFonts()
                end
            end
        end)
    end
    
    -- CRITICAL: Only apply fonts immediately if global font is enabled
    local enabled = AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures and AC.DB.profile.moreFeatures.globalFontEnabled
    if enabled then
        self:ApplyActionBarFonts()
    end
end

-- Revert action bar fonts to Blizzard default
function MoreFeatures:RevertActionBarFonts()
    -- List of action bar button prefixes
    local bars = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", 
        "MultiBar6Button", "MultiBar7Button", "StanceButton"
    }
    
    -- Revert all buttons to default Blizzard font
    for _, bar in pairs(bars) do
        for i = 1, 12 do
            local button = _G[bar .. i]
            if button and button.HotKey then
                local hk = button.HotKey
                -- Reset to Blizzard's default font (NumberFontNormal)
                local defaultFont = NumberFontNormal or GameFontNormalSmall
                if defaultFont then
                    local font, size, flags = defaultFont:GetFont()
                    hk:SetFont(font, size, flags)
                end
                -- Reset position to default
                hk:ClearAllPoints()
                hk:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
            end
        end
    end
end

-- Apply action bar fonts to all buttons (MattActionBarFont pattern)
function MoreFeatures:ApplyActionBarFonts()
    -- Get database settings (same as working sliders)
    local db = AC.DB and AC.DB.profile and AC.DB.profile.actionBarFont
    if not db then return end
    
    local scale = (db.scale or 100) / 100
    local offsetX = db.horizontal or 0
    local offsetY = db.vertical or 0
    
    -- List of action bar button prefixes (including StanceButton - MattActionBarFont does this!)
    local bars = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", 
        "MultiBar6Button", "MultiBar7Button", "StanceButton"
    }
    
    -- Apply to all buttons
    for _, bar in pairs(bars) do
        for i = 1, 12 do
            local button = _G[bar .. i]
            if button then
                self:ApplyToSingleButton(button, scale, offsetX, offsetY)
            end
        end
    end
end

-- Apply font settings to a single button (MattActionBarFont pattern - NO PROTECTION CHECKS!)
function MoreFeatures:ApplyToSingleButton(btn, scale, offsetX, offsetY)
    if not btn then return end
    
    -- Get HotKey element (MattActionBarFont pattern)
    local hk = btn.HotKey
    if not hk then return end
    
    -- Apply ArenaCore font with custom size
    local arenaCoreFontPath = "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf"
    local baseSize = 10
    local newSize = math.max(1, math.floor(baseSize * scale))
    hk:SetFont(arenaCoreFontPath, newSize, "OUTLINE")
    
    -- Apply position
    hk:ClearAllPoints()
    hk:SetPoint("TOPRIGHT", btn, "TOPRIGHT", offsetX, offsetY)
    
    -- Hook SetText to reapply settings when Blizzard updates the text (THE SECRET!)
    -- MattActionBarFont uses this pattern to persist fonts without taint
    if not hk._AC_ABF_Hooked then
        local originalSetText = hk.SetText
        hk.SetText = function(self, text)
            -- Call original SetText
            originalSetText(self, text)
            
            -- CRITICAL: Only apply ArenaCore font if global font is enabled
            local globalEnabled = _G.ArenaCoreDB and _G.ArenaCoreDB.profile and _G.ArenaCoreDB.profile.moreFeatures and _G.ArenaCoreDB.profile.moreFeatures.globalFontEnabled
            if not globalEnabled then return end
            
            -- Get current settings
            local db = _G.ArenaCoreDB and _G.ArenaCoreDB.profile and _G.ArenaCoreDB.profile.actionBarFont
            if not db then return end
            
            local currentScale = (db.scale or 100) / 100
            local currentOffsetX = db.horizontal or 0
            local currentOffsetY = db.vertical or 0
            
            -- Reapply ArenaCore font
            local arenaCoreFontPath = "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf"
            local baseSize = 10
            local newSize = math.max(1, math.floor(baseSize * currentScale))
            self:SetFont(arenaCoreFontPath, newSize, "OUTLINE")
            
            -- Reapply position
            self:ClearAllPoints()
            self:SetPoint("TOPRIGHT", btn, "TOPRIGHT", currentOffsetX, currentOffsetY)
        end
        hk._AC_ABF_Hooked = true
    end
end

-- Test slash command for action bar font
SLASH_ACTESTABFONT1 = "/actestabfont"
SlashCmdList["ACTESTABFONT"] = function()
    if AC.MoreFeatures and AC.MoreFeatures.ApplyActionBarFonts then
        AC.MoreFeatures:ApplyActionBarFonts()
    end
end

-- Initialize the More Features window
function MoreFeatures:Initialize()
    local window = self:CreateWindow()
    local header = self:CreateHeader(window)
    local sidebar = self:CreateSidebar(window)
    local content = self:CreateContentArea(window)
    
    -- Setup action bar font hook (if not already done)
    if not self.actionBarHookSetup then
        self:SetupActionBarHook()
    end
    
    -- Load saved settings
    self:LoadSettings()
    -- Apply settings that need runtime hooks
    if self.ApplySurrenderSetting then self:ApplySurrenderSetting() end
    if self.ApplyGlobalFont then 
        local enabled = AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures and AC.DB.profile.moreFeatures.globalFontEnabled
        if enabled then
            self:ApplyGlobalFont(true, true)  -- true, true = enabled, skipPopup
        end
    end
    
    -- Apply action bar-only font if enabled (during initialization, skip popup)
    if self.ApplyActionBarFont then
        local enabled = AC.DB and AC.DB.profile and AC.DB.profile.moreFeatures and AC.DB.profile.moreFeatures.actionBarFontOnly
        if enabled then
            self:ApplyActionBarFont(true, true)  -- true, true = enabled, skipPopup
        end
    end
    
    -- Set General as default and select it
    self:SelectPage("general")
    
    self.initialized = true
end

-- Load saved settings from database
function MoreFeatures:LoadSettings()
    AC.DB = AC.DB or {}
    AC.DB.profile = AC.DB.profile or {}
    AC.DB.profile.moreFeatures = AC.DB.profile.moreFeatures or {}
    
    -- Blizzard frame hiding is now always enabled automatically via BlizzFrameHider.lua

    -- Default enable Surrender /gg if not set
    if AC.DB.profile.moreFeatures.surrenderGGEnabled == nil then
        AC.DB.profile.moreFeatures.surrenderGGEnabled = true
    end
    
    -- Default enable Chat Messages if not set
    if AC.DB.profile.moreFeatures.chatMessagesEnabled == nil then
        AC.DB.profile.moreFeatures.chatMessagesEnabled = true
    end
end

-- Show the More Features window
function MoreFeatures:ShowWindow()
    if not self.initialized then
        self:Initialize()
    end
    
    if self.window then
        self.window:Show()
        -- Always ensure General tab is selected when opening
        C_Timer.After(0.1, function()
            if self.SelectPage then
                self:SelectPage("general")
            end
        end)
    end
end

-- Hide the More Features window
function MoreFeatures:HideWindow()
    if self.window then
        -- Restore normal strata if it was raised from Edit Mode
        if self.window.__raisedFromEditMode then
            self.window:SetFrameStrata("DIALOG")
            self.window:SetFrameLevel(50)
            self.window.__raisedFromEditMode = nil
        end
        self.window:Hide()
    end
end

-- Toggle the More Features window
function MoreFeatures:ToggleWindow()
    if not self.initialized then
        self:Initialize()
    end
    
    if self.window and self.window:IsShown() then
        self:HideWindow()
    else
        self:ShowWindow()
    end
end

-- Show More Features window and navigate to Profiles tab
-- Used by Profile Edit Mode to allow creating new profiles
function MoreFeatures:ShowProfilesTab()
    if not self.initialized then
        self:Initialize()
    end
    
    -- CRITICAL FIX: Raise window strata when opened from Edit Mode
    -- This ensures More Features appears ABOVE the Edit Mode popup (DIALOG level 1000)
    -- so users can immediately see and interact with it without manual dragging
    if self.window then
        self.window:SetFrameStrata("FULLSCREEN_DIALOG")
        self.window:SetFrameLevel(2000)
        self.window:Show()
        
        -- Mark that we raised the strata from Edit Mode context
        self.window.__raisedFromEditMode = true
    end
    
    -- Small delay to ensure window is fully shown before switching tabs
    C_Timer.After(0.1, function()
        if self.SelectPage then
            self:SelectPage("profiles")
            
            -- Auto-populate profile name with "New Profile X"
            C_Timer.After(0.2, function()
                if self.pageContainers and self.pageContainers["profiles"] then
                    local container = self.pageContainers["profiles"]
                    
                    -- Find the profile name input box
                    local children = {container:GetChildren()}
                    for _, child in ipairs(children) do
                        if child.GetObjectType and child:GetObjectType() == "EditBox" then
                            -- Generate unique profile name
                            local profileNum = 1
                            local profileName = "New Profile " .. profileNum
                            
                            -- Check if name exists, increment until unique
                            if AC.ProfileManager then
                                local profiles = AC.ProfileManager:GetProfileList()
                                while true do
                                    local exists = false
                                    for _, name in ipairs(profiles) do
                                        if name == profileName then
                                            exists = true
                                            break
                                        end
                                    end
                                    if not exists then break end
                                    profileNum = profileNum + 1
                                    profileName = "New Profile " .. profileNum
                                end
                            end
                            
                            -- Set the auto-generated name
                            child:SetText(profileName)
                            child:HighlightText()
                            child:SetFocus()
                            break
                        end
                    end
                end
            end)
        end
    end)
end

-- Auto-initialize action bar fonts on login (CRITICAL FIX!)
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    -- Initialize action bar font system on login (before window is opened)
    if AC.MoreFeatures and not AC.MoreFeatures.actionBarHookSetup then
        AC.MoreFeatures:SetupActionBarHook()
    end
end)