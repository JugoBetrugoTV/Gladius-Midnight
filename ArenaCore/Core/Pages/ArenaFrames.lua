-- Core/Pages/ArenaFrames.lua --
-- Arena Frames configuration page extracted from UI.lua
local AC = _G.ArenaCore
if not AC then return end

local V = AC.Vanity
local COLORS = AC.COLORS
local S = AC.Settings  -- Settings system for compatibility

-- Helper function to create a dropdown setting using the themed dropdown
local function CreateLinkedDropdown(parent, label, y, subPath, options, defaultVal, callback)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", 20, y); row:SetPoint("TOPRIGHT", -20, y); row:SetHeight(26)

  local l = AC:CreateStyledText(row, label, 11, AC.COLORS.TEXT_2, "OVERLAY", "")
  l:SetPoint("LEFT", 0, 0); l:SetWidth(120); l:SetJustifyH("LEFT")

  -- Convert options to simple string array for CreateFlatDropdown
  local optionTexts = {}
  local valueToText = {}
  local textToValue = {}
  
  for i, option in ipairs(options) do
    table.insert(optionTexts, option.text)
    valueToText[option.value] = option.text
    textToValue[option.text] = option.value
  end
  
  -- Get initial text for the selected value
  local initialText = valueToText[defaultVal] or optionTexts[1] or ""

  -- Create themed dropdown
  local dropdown = AC:CreateFlatDropdown(row, 150, 24, optionTexts, initialText, function(selectedText)
    local value = textToValue[selectedText]
    
    -- Save to database using proper path
    local keys = {}
    for k in string.gmatch(subPath, "([^%.]+)") do 
      table.insert(keys, k) 
    end
    
    local target = AC.DB.profile
    for i = 1, #keys - 1 do
      target[keys[i]] = target[keys[i]] or {}
      target = target[keys[i]]
    end
    target[keys[#keys]] = value
    
    -- Call callback if provided
    if callback then callback(value) end
  end)
  
  dropdown:SetPoint("LEFT", l, "RIGHT", 10, 0)

  return row
end

-- Reset function limited to Arena Frames settings only (must be after AC is defined)
function AC:ResetArenaFramesSettings()
    self.DB.profile = self.DB.profile or {}
    
    -- Always use your curated defaults from addon.DEFAULTS
    if self.DEFAULTS and self.DEFAULTS.arenaFrames then
        -- Deep copy to avoid reference issues
        local function DeepCopy(tbl)
            if type(tbl) ~= "table" then return tbl end
            local out = {}
            for k, v in pairs(tbl) do out[k] = DeepCopy(v) end
            return out
        end
        self.DB.profile.arenaFrames = DeepCopy(self.DEFAULTS.arenaFrames)
    end
    
    -- Reset layout system to defaults (includes your dragged position)
    if self.DEFAULTS and self.DEFAULTS.layout then
        local function DeepCopy(tbl)
            if type(tbl) ~= "table" then return tbl end
            local out = {}
            for k, v in pairs(tbl) do out[k] = DeepCopy(v) end
            return out
        end
        self.DB.profile.layout = DeepCopy(self.DEFAULTS.layout)
    end
    
    -- Apply layout using new Layout system (but skip cast bars to avoid conflict)
    if self.Layout then
        -- Only restore Arena Frame position, not cast bars
        if self.Layout.RestoreBaseAnchor and self.ArenaFrames and self.ArenaFrames[1] then
            self.Layout:RestoreBaseAnchor(self.ArenaFrames[1])
        end
        
        -- Position other elements but NOT cast bars (they have their own page)
        if self.Layout.PositionHealthResourceBars then
            self.Layout:PositionHealthResourceBars()
        end
        if self.Layout.PositionTrinkets then
            self.Layout:PositionTrinkets()
        end
        if self.Layout.PositionRacials then
            self.Layout:PositionRacials()
        end
        if self.Layout.PositionSpecIcons then
            self.Layout:PositionSpecIcons()
        end
        if self.Layout.PositionClassIcons then
            self.Layout:PositionClassIcons()
        end
        if self.Layout.PositionDiminishingReturns then
            self.Layout:PositionDiminishingReturns()
        end
    end
    
    if self.ApplyAllArenaFrameSettings then self:ApplyAllArenaFrameSettings() end
    
    -- CRITICAL FIX: Refresh cast bars with the correct defaults after reset
    if self.RefreshCastBarsLayout then
        self:RefreshCastBarsLayout()
        print("|cff22AA44Arena Core:|r Cast bars refreshed with correct defaults")
    end
    
    -- CRITICAL FIX: Refresh ALL UI sliders to show the reset values
    print("|cff22AA44Arena Core:|r Refreshing UI sliders to match reset values...")
    
    -- Force refresh the current page to update all sliders
    if self.ShowPage then 
        self:ShowPage("ArenaFrames") 
        
        -- Additional refresh after a short delay to ensure sliders update
        C_Timer.After(0.1, function()
            if self.RefreshCurrentPage then
                self:RefreshCurrentPage()
            elseif self.ShowPage then
                self:ShowPage("ArenaFrames")
            end
            print("|cff22AA44Arena Core:|r UI sliders refreshed - Default Settings complete!")
        end)
    end
end

-- Helper function to create slider settings - PROFILE MANAGER INTEGRATION
local function CreateSliderSetting(parent, label, y, path, min, max, value, pct, compactDisplay)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 20, y)
    row:SetPoint("TOPRIGHT", -20, y)
    row:SetHeight(26)

    local labelText = AC:CreateStyledText(row, label, 11, COLORS.TEXT_2, "OVERLAY", "")
    labelText:SetPoint("LEFT", row, "LEFT", 0, 0)
    labelText:SetWidth(120)
    labelText:SetJustifyH("LEFT")

    -- CRITICAL FIX: Read from THEME-SPECIFIC location (same place drag saves to)
    local currentValue = value
    
    -- For positioning sliders, read from theme-specific database
    if path:find("arenaFrames%.positioning") and AC.ArenaFrameThemes and AC.DB and AC.DB.profile then
        local currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
        if currentTheme and AC.DB.profile.themeData and AC.DB.profile.themeData[currentTheme] then
            local themeData = AC.DB.profile.themeData[currentTheme]
            if themeData.arenaFrames and themeData.arenaFrames.positioning then
                -- Extract the setting name from path (e.g., "horizontal" from "arenaFrames.positioning.horizontal")
                local settingName = path:match("%.([^%.]+)$")
                if settingName and themeData.arenaFrames.positioning[settingName] ~= nil then
                    currentValue = themeData.arenaFrames.positioning[settingName]
                end
            end
        end
    end
    
    -- Fallback to old system if theme-specific value not found
    if currentValue == value then
        if AC.ProfileManager and AC.ProfileManager.GetSetting then
            currentValue = AC.ProfileManager:GetSetting(path)
            if currentValue == nil then
                -- Fallback to FrameSystem or Settings system if ProfileManager doesn't have it
                if AC.FrameSystem and AC.FrameSystem.GetSetting then
                    currentValue = AC.FrameSystem:GetSetting(path) or value
                elseif S and S.Get then
                    currentValue = S:Get(path) or value or 0
                end
            end
        elseif AC.FrameSystem and AC.FrameSystem.GetSetting then
            currentValue = AC.FrameSystem:GetSetting(path) or value
        elseif S and S.Get then
            currentValue = S:Get(path) or value or 0
        end
    end

    -- Create DOWN arrow button for fine adjustment
    local downBtn = CreateFrame("Button", nil, row)
    downBtn:SetSize(16, 16)
    downBtn:SetPoint("LEFT", labelText, "RIGHT", 6, 0)
    
    -- Down arrow styling
    local downBg = downBtn:CreateTexture(nil, "BACKGROUND")
    downBg:SetAllPoints()
    downBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    
    local downBorder = downBtn:CreateTexture(nil, "BORDER") 
    downBorder:SetAllPoints()
    downBorder:SetColorTexture(0.4, 0.4, 0.4, 1)
    downBorder:SetPoint("TOPLEFT", 1, -1)
    downBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    
    local downText = downBtn:CreateFontString(nil, "OVERLAY")
    downText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 12, "")
    downText:SetText("-")
    downText:SetTextColor(0.8, 0.8, 0.8, 1)
    downText:SetPoint("CENTER")

    local slider = AC:CreateFlatSlider(row, 150, 20, min, max, currentValue, pct or false, compactDisplay or false, function(newValue)
        -- Update via Profile Manager for proper sync (primary)
        if AC.ProfileManager and AC.ProfileManager.SetSetting then
            AC.ProfileManager:SetSetting(path, newValue)
        end
        -- Also update Frame System and legacy system for compatibility
        if AC.FrameSystem and AC.FrameSystem.SetSetting then
            AC.FrameSystem:SetSetting(path, newValue)
        end
        if S and S.Set then
            S:Set(path, newValue)
        end
    end)
    slider:SetPoint("LEFT", downBtn, "RIGHT", 4, 0)

    -- Store slider reference for direct updates during reset
    if not AC.sliderWidgets then AC.sliderWidgets = {} end
    AC.sliderWidgets[path] = slider.slider

    -- Create UP arrow button for fine adjustment  
    local upBtn = CreateFrame("Button", nil, row)
    upBtn:SetSize(16, 16)
    upBtn:SetPoint("LEFT", slider, "RIGHT", 4, 0)
    
    -- Up arrow styling
    local upBg = upBtn:CreateTexture(nil, "BACKGROUND")
    upBg:SetAllPoints()
    upBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    
    local upBorder = upBtn:CreateTexture(nil, "BORDER")
    upBorder:SetAllPoints() 
    upBorder:SetColorTexture(0.4, 0.4, 0.4, 1)
    upBorder:SetPoint("TOPLEFT", 1, -1)
    upBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    
    local upText = upBtn:CreateFontString(nil, "OVERLAY")
    upText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 12, "")
    upText:SetText("+")
    upText:SetTextColor(0.8, 0.8, 0.8, 1)
    upText:SetPoint("CENTER")

    local maxT = AC:CreateStyledText(row, pct and (max .. "%") or tostring(max), 9, COLORS.TEXT_MUTED, "OVERLAY", "")
    maxT:SetPoint("LEFT", upBtn, "RIGHT", 6, 0)
    maxT:SetWidth(25)
    maxT:SetJustifyH("LEFT")

    local valT = AC:CreateStyledText(row, "", 11, COLORS.TEXT_2, "OVERLAY", "")
    valT:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    valT:SetPoint("LEFT", maxT, "RIGHT", 10, 0)
    valT:SetWidth(35)
    valT:SetJustifyH("CENTER")

    -- PRESERVE ORIGINAL update function
    local function upd()
        local v = slider.slider:GetValue()
        if pct then 
            valT:SetText(string.format("%.0f%%", v))
        elseif compactDisplay then
            valT:SetText(string.format("%.0f", math.floor(v / 100)))
        else 
            valT:SetText(string.format("%.0f", v)) 
        end
    end

    -- PRESERVE ORIGINAL slider event handler - DON'T MODIFY
    slider.slider:SetScript("OnValueChanged", function(_, v)
        upd()
        AC:OnArenaFramesSliderChanged(slider, path, v)
    end)
    
    -- Down arrow click handler
    downBtn:SetScript("OnClick", function()
        local currentVal = slider.slider:GetValue()
        local increment = compactDisplay and 100 or 1
        local newVal = math.max(min, currentVal - increment)
        slider.slider:SetValue(newVal)
    end)
    
    -- Up arrow click handler  
    upBtn:SetScript("OnClick", function()
        local currentVal = slider.slider:GetValue()
        local increment = compactDisplay and 100 or 1
        local newVal = math.min(max, currentVal + increment)
        slider.slider:SetValue(newVal)
    end)
    
    -- Down arrow hover effects
    downBtn:SetScript("OnEnter", function()
        downBg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
        downText:SetTextColor(1, 1, 1, 1)
    end)
    
    downBtn:SetScript("OnLeave", function()
        downBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        downText:SetTextColor(0.8, 0.8, 0.8, 1)
    end)
    
    -- Up arrow hover effects
    upBtn:SetScript("OnEnter", function()
        upBg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
        upText:SetTextColor(1, 1, 1, 1)
    end)
    
    upBtn:SetScript("OnLeave", function()
        upBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        upText:SetTextColor(0.8, 0.8, 0.8, 1)
    end)

    upd()
    return row
end

-- CRITICAL: Checkbox registry for mutual exclusivity updates
local checkboxRegistry = {}

-- Helper function to create checkbox settings with proper database binding
local function CreateCheckboxSetting(parent, label, y, path, checked)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 20, y)
    row:SetPoint("TOPRIGHT", -20, y)
    row:SetHeight(26)

    local l = AC:CreateStyledText(row, label, 12, COLORS.TEXT_2, "OVERLAY", "")
    l:SetPoint("LEFT", 0, 0)
    l:SetWidth(180)

    -- Get current value from Profile Manager FIRST, then Settings system
    local currentChecked = checked
    if AC.ProfileManager and AC.ProfileManager.GetSetting then
        currentChecked = AC.ProfileManager:GetSetting(path)
        if currentChecked == nil then
            -- Fallback to Settings system if ProfileManager doesn't have it
            currentChecked = checked
        end
    end
    
    local box = AC:CreateFlatCheckbox(row, 20, currentChecked)
    box:SetPoint("RIGHT", -25, 0)
    
    -- CRITICAL: Register checkbox for mutual exclusivity updates
    checkboxRegistry[path] = box

    -- Force update the checkbox visual state (ensures it matches the database value)
    box:SetChecked(currentChecked)
    
    -- Register checkbox with CheckboxTracker for Edit Mode support
    if AC.CheckboxTracker then
        AC.CheckboxTracker:Register(box, path)
    end

    -- Add visual indicator background (dark gray color - uniform across all checkboxes)
    local indicatorBg = AC:CreateFlatTexture(row, "BACKGROUND", 1, {0.15, 0.15, 0.15, 1}, 1)
    indicatorBg:SetPoint("LEFT", 0, 0)
    indicatorBg:SetPoint("RIGHT", -30, 0)
    indicatorBg:SetHeight(20)

    -- Store reference for updates
    row.updateIndicator = function()
        -- Keep dark gray color (no longer changes based on checked state)
        -- CRITICAL: Use full opacity (1.0) for uniform appearance across all checkboxes
        indicatorBg:SetColorTexture(0.15, 0.15, 0.15, 1)
    end
    
    -- Add hover effect to lighten the background
    row:SetScript("OnEnter", function()
        indicatorBg:SetColorTexture(0.25, 0.25, 0.25, 1)
    end)
    
    row:SetScript("OnLeave", function()
        indicatorBg:SetColorTexture(0.15, 0.15, 0.15, 1)
    end)

    -- Update indicator when checkbox changes
    box:SetScript("OnClick", function(selfBtn)
        local isChecked = selfBtn:GetChecked()
        
        -- Mutual exclusivity for Show Names and Arena 1/2/3 Names
        if isChecked then
            if path == "arenaFrames.general.showNames" then
                -- User enabled Show Names -> disable Arena 1/2/3 Names
                if AC.ProfileManager and AC.ProfileManager.SetSetting then
                    AC.ProfileManager:SetSetting("arenaFrames.general.showArenaLabels", false)
                    local otherBox = checkboxRegistry["arenaFrames.general.showArenaLabels"]
                    if otherBox then
                        otherBox:SetChecked(false)
                    end
                end
            elseif path == "arenaFrames.general.showArenaLabels" then
                -- User enabled Arena 1/2/3 Names -> disable Show Names
                if AC.ProfileManager and AC.ProfileManager.SetSetting then
                    AC.ProfileManager:SetSetting("arenaFrames.general.showNames", false)
                    local otherBox = checkboxRegistry["arenaFrames.general.showNames"]
                    if otherBox then
                        otherBox:SetChecked(false)
                    end
                end
            end
        end
        
        -- SIMPLIFIED: Let ProfileManager handle everything (Edit Mode, database, refresh)
        -- ProfileManager.SetSetting() already handles:
        -- - Buffering to tempProfileBuffer if in Edit Mode
        -- - Writing to database for visual updates
        -- - Triggering appropriate refresh functions
        if AC.ProfileManager and AC.ProfileManager.SetSetting then
            AC.ProfileManager:SetSetting(path, isChecked)
        end
        
        -- Update visual indicator
        row.updateIndicator()
    end)

    -- Force synchronization of visual state with database value
    C_Timer.After(0.01, function()
        if box then
            local dbValue = AC.ProfileManager and AC.ProfileManager.GetSetting and AC.ProfileManager:GetSetting(path)
            if dbValue ~= nil then
                box:SetChecked(dbValue)
                row.updateIndicator()
            end
        end
    end)
end

-- Helper function to create collapsible section headers
local function CreateCollapsibleSection(parent, title, y, isExpanded)
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", 18, y)
    section:SetPoint("TOPRIGHT", -18, y)
    section:SetHeight(35)
    
    -- Create background using COLORS table so theme system can update it
    local bg = section:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    local bgColor = COLORS.NAV_INACTIVE_BG or {0.12, 0.12, 0.12, 1}
    bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    section.__acSectionBg = bg -- Mark for theme system
    
    -- Removed borders to avoid conflicts with hover effects
    
    -- Create clickable button for the entire header
    local button = CreateFrame("Button", nil, section)
    button:SetAllPoints()
    
    -- Expand/collapse arrow using original purple texture
    local arrow = button:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\dropdown-arrow-purple.tga")
    arrow:SetSize(16, 16)
    arrow:SetPoint("LEFT", 15, 0)
    
    -- Section title with light grey color matching "Horizontal" text
    local titleText = AC:CreateStyledText(button, title, 13, COLORS.TEXT_2, "OVERLAY", "")
    titleText:SetPoint("LEFT", arrow, "RIGHT", 8, 0)
    
    -- State management
    section.isExpanded = isExpanded or false
    section.contentFrame = nil
    section.arrow = arrow
    section.button = button
    section.bg = bg
    
    -- Update arrow display
    local function updateArrow()
        if section.isExpanded then
            arrow:SetRotation(math.rad(0)) -- Point down when expanded
        else
            arrow:SetRotation(math.rad(-90)) -- Point right when collapsed
        end
    end
    updateArrow()
    
    -- Hover effects - use COLORS table
    button:SetScript("OnEnter", function()
        local hoverColor = COLORS.NAV_ACTIVE_BG or {0.16, 0.16, 0.16, 1}
        bg:SetColorTexture(hoverColor[1], hoverColor[2], hoverColor[3], hoverColor[4] or 1)
    end)
    
    button:SetScript("OnLeave", function()
        local bgColor = COLORS.NAV_INACTIVE_BG or {0.12, 0.12, 0.12, 1}
        bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    end)
    
    -- Click handler with dynamic layout update
    button:SetScript("OnClick", function()
        section.isExpanded = not section.isExpanded
        updateArrow()
        
        if section.contentFrame then
            if section.isExpanded then
                section.contentFrame:Show()
            else
                section.contentFrame:Hide()
            end
        end
        
        -- Trigger dynamic layout refresh
        if section.onToggle then
            section.onToggle(section.isExpanded)
        end
        
        -- Update layout of all sections
        if section.parent and section.parent.updateLayout then
            section.parent:updateLayout()
            -- CRITICAL FIX: Always push other groups down when ANY section toggles
            if section.parent.pushOtherGroupsDown then
                -- Add a tiny delay to ensure the layout update completes first
                C_Timer.After(0.01, function()
                    section.parent:pushOtherGroupsDown()
                end)
            end
        end
    end)
    
    return section
end

-- Helper function to create content frame for collapsible sections with dynamic sizing and styling
local function CreateSectionContent(parent, section, initialHeight)
    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", section, "BOTTOMLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", section, "BOTTOMRIGHT", 0, 0)
    content:SetHeight(initialHeight or 100) -- Default height
    
    -- Add the beautiful styling back
    AC:HairlineGroupBox(content)
    
    -- UNIFIED SYSTEM: HairlineGroupBox now provides consistent background
    -- Removed duplicate background creation to eliminate visual conflicts
    
    section.contentFrame = content
    
    -- Function to auto-size content based on children
    function content:AutoSize()
        local totalHeight = 0
        local maxChildY = 0
        
        for i = 1, self:GetNumChildren() do
            local child = select(i, self:GetChildren())
            if child and child:IsVisible() then
                local childBottom = math.abs(select(5, child:GetPoint(1)) or 0) + child:GetHeight()
                maxChildY = math.max(maxChildY, childBottom)
            end
        end
        
        -- Add padding and set height
        totalHeight = maxChildY + 20 -- 20px bottom padding
        self:SetHeight(math.max(totalHeight, 50)) -- Minimum 50px height
        
        return totalHeight
    end
    
    -- Initially hide if section is collapsed
    if not section.isExpanded then
        content:Hide()
    end
    
    return content
end

-- Layout constants for professional spacing
local ROW_GAP = 6
local PAD_X = 10
local PAD_Y = 8
local H_GUTTER = 12
local HEADER_HEIGHT = 35

-- Measurement helper function
local function MeasureSection(section)
    if not section.body then return HEADER_HEIGHT end
    
    local sectionWidth = section:GetWidth()
    local bodyWidth = sectionWidth - PAD_X * 2
    local totalRowHeight = 0
    
    -- Measure each row in the body
    for i = 1, section.body:GetNumChildren() do
        local row = select(i, section.body:GetChildren())
        if row and row:IsVisible() then
            -- Set row width and measure
            row:SetWidth(bodyWidth)
            
            -- Get actual row height (accounting for text wrapping)
            local rowHeight = math.max(row:GetHeight(), 25) -- Minimum row height
            totalRowHeight = totalRowHeight + rowHeight + ROW_GAP
        end
    end
    
    -- Set body height
    if totalRowHeight > 0 then
        section.body:SetHeight(totalRowHeight + PAD_Y * 2)
    end
    
    -- Return total section height
    local effectiveHeight = HEADER_HEIGHT
    if section.isExpanded and section.body then
        effectiveHeight = effectiveHeight + section.body:GetHeight()
    end
    
    return effectiveHeight
end

-- Master layout function
local function Layout(scrollChild)
    if not scrollChild or not scrollChild.sections then return end
    
    local scrollWidth = scrollChild:GetParent():GetWidth()
    local contentWidth = scrollWidth - H_GUTTER * 2
    local currentY = 0
    
    -- Layout each section in order
    for i, section in ipairs(scrollChild.sections) do
        -- Set section width
        section:SetWidth(contentWidth)
        
        -- Measure section height
        local sectionHeight = MeasureSection(section)
        
        -- Position section
        section:ClearAllPoints()
        section:SetPoint("TOPLEFT", H_GUTTER, -currentY)
        section:SetHeight(sectionHeight)
        
        -- Move cursor down
        currentY = currentY + sectionHeight + ROW_GAP
    end
    
    -- Update scroll child height
    local totalHeight = currentY + PAD_Y
    scrollChild:SetHeight(math.max(totalHeight, scrollChild:GetParent():GetHeight()))
end

-- Throttled layout function to prevent excessive calls
local layoutTimer = nil
local function ThrottledLayout(scrollChild)
    if layoutTimer then return end
    layoutTimer = C_Timer.After(0, function()
        Layout(scrollChild)
        layoutTimer = nil
    end)
end

-- Create robust collapsible section with proper measurement
local function CreateRobustSection(parent, title, isExpanded)
    local section = CreateFrame("Frame", nil, parent)
    section.isExpanded = isExpanded or false
    
    -- Create header
    local header = CreateFrame("Button", nil, section)
    header:SetHeight(HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    
    -- Header background
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.109, 0.109, 0.109, 1) -- #1c1c1c
    
    local border = header:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    border:SetPoint("TOPLEFT", 1, -1)
    border:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Arrow
    local arrow = header:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\dropdown-arrow-purple.tga")
    arrow:SetSize(16, 16)
    arrow:SetPoint("LEFT", 15, 0)
    
    -- Title
    local titleText = AC:CreateStyledText(header, title, 13, {1,1,1,1}, "OVERLAY", "")
    titleText:SetPoint("LEFT", arrow, "RIGHT", 8, 0)
    titleText:SetWordWrap(true)
    
    -- Create body
    local body = CreateFrame("Frame", nil, section)
    body:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
    body:SetPoint("TOPRIGHT", 0, -HEADER_HEIGHT)
    body:SetHeight(1) -- Will be measured dynamically
    
    section.header = header
    section.body = body
    section.arrow = arrow
    section.bg = bg
    
    -- Update arrow display
    local function updateArrow()
        if section.isExpanded then
            arrow:SetRotation(math.rad(0))
        else
            arrow:SetRotation(math.rad(-90))
        end
    end
    updateArrow()
    
    -- Hover effects
    header:SetScript("OnEnter", function()
        bg:SetColorTexture(0.2, 0.2, 0.2, 1)
    end)
    
    header:SetScript("OnLeave", function()
        bg:SetColorTexture(0.109, 0.109, 0.109, 1)
    end)
    
    -- Click handler
    header:SetScript("OnClick", function()
        section.isExpanded = not section.isExpanded
        updateArrow()
        
        -- Trigger layout update
        if parent.Layout then
            ThrottledLayout(parent)
        end
    end)
    
    return section
end

-- Create GENERAL settings group with collapsible sections and dynamic layout
local function CreateGroup_GENERAL(parent, y)
    local mainContainer = CreateFrame("Frame", nil, parent)
    mainContainer:SetPoint("TOPLEFT", 0, y)
    mainContainer:SetPoint("TOPRIGHT", 0, y)
    mainContainer:SetHeight(800) -- Increased to accommodate all sections when expanded
    
    -- Store all sections for dynamic layout
    mainContainer.sections = {}
    mainContainer.sectionOrder = {}
    
    -- Simple dynamic layout function - prevents overlap and pushes content down
    function mainContainer:updateLayout()
        local currentY = 0
        
        -- Position each section sequentially to prevent overlap
        for i, section in ipairs(self.sectionOrder) do
            -- Clear existing points and reposition
            section:ClearAllPoints()
            section:SetPoint("TOPLEFT", 18, currentY)
            section:SetPoint("TOPRIGHT", -18, currentY)
            
            -- Move down by header height (35px)
            currentY = currentY - 35
            
            -- If section is expanded, auto-size content and push everything below down
            if section.isExpanded and section.contentFrame then
                section.contentFrame:AutoSize()
                currentY = currentY - section.contentFrame:GetHeight()
            end
            
            -- Add spacing between sections to keep layout clean
            currentY = currentY - 15
        end
        
        -- Update container height and push other groups down
        local totalHeight = math.abs(currentY) + 20
        self:SetHeight(totalHeight)
        self:pushOtherGroupsDown()
    end
    
    -- SIMPLIFIED: Store direct references to the groups we need to move
    mainContainer.positioningGroup = nil -- Will be set after groups are created
    mainContainer.sizingGroup = nil -- Will be set after groups are created
    
    -- Simple function to push POSITIONING and SIZING groups down when sections expand
    function mainContainer:pushOtherGroupsDown()
        -- Calculate the actual height based on expanded sections
        local totalHeight = 0
        for i, section in ipairs(self.sectionOrder) do
            totalHeight = totalHeight + 35 -- Header height
            if section.isExpanded and section.contentFrame then
                totalHeight = totalHeight + section.contentFrame:GetHeight()
            end
            totalHeight = totalHeight + 15 -- Gap between sections
        end
        
        local positioningY = -totalHeight - 20 -- Gap after collapsible sections
        local sizingY = positioningY - 170 - 15 -- POSITIONING height + gap
        
            -- Use direct references to the groups (much simpler!)
        if self.positioningGroup then
            self.positioningGroup:ClearAllPoints()
            self.positioningGroup:SetPoint("TOPLEFT", 18, positioningY)
            self.positioningGroup:SetPoint("TOPRIGHT", -18, positioningY)
        end
        
        if self.sizingGroup then
            self.sizingGroup:ClearAllPoints()
            self.sizingGroup:SetPoint("TOPLEFT", 18, sizingY)
            self.sizingGroup:SetPoint("TOPRIGHT", -18, sizingY)
        end
    end
    
    -- ▼ Text Display Settings (first 5 checkboxes)
    local textDisplaySection = CreateCollapsibleSection(mainContainer, "Text Display Settings", 0, false)
    textDisplaySection.parent = mainContainer
    local textDisplayContent = CreateSectionContent(mainContainer, textDisplaySection, 180)
    
    CreateCheckboxSetting(textDisplayContent, "Status Text", -25, "arenaFrames.general.statusText")
    CreateCheckboxSetting(textDisplayContent, "Use Percentage", -50, "arenaFrames.general.usePercentage")
    CreateCheckboxSetting(textDisplayContent, "Use Class Colors", -75, "arenaFrames.general.useClassColors")
    CreateCheckboxSetting(textDisplayContent, "Show Names", -100, "arenaFrames.general.showNames")
    CreateCheckboxSetting(textDisplayContent, "Server Names", -125, "arenaFrames.general.showArenaServerNames")
    CreateCheckboxSetting(textDisplayContent, "Arena Numbers Only", -150, "arenaFrames.general.showArenaNumbers")
    CreateCheckboxSetting(textDisplayContent, "  Arena 1/2/3 Names", -175, "arenaFrames.general.showArenaLabels")
    
    -- FrameSort Integration Toggle
    local frameSortRow = CreateFrame("Frame", nil, textDisplayContent)
    frameSortRow:SetPoint("TOPLEFT", 20, -200)
    frameSortRow:SetPoint("TOPRIGHT", -20, -200)
    frameSortRow:SetHeight(26)
    
    local frameSortLabel = AC:CreateStyledText(frameSortRow, "FrameSort Integration", 12, COLORS.TEXT_2, "OVERLAY", "")
    frameSortLabel:SetPoint("LEFT", 0, 0)
    frameSortLabel:SetWidth(180)
    
    -- Get current value
    local frameSortEnabled = AC.DB and AC.DB.profile 
        and AC.DB.profile.arenaFrames 
        and AC.DB.profile.arenaFrames.general 
        and AC.DB.profile.arenaFrames.general.enableFrameSortIntegration or false
    
    local frameSortBox = AC:CreateFlatCheckbox(frameSortRow, 20, frameSortEnabled)
    frameSortBox:SetPoint("RIGHT", -25, 0)
    
    -- Add visual indicator background
    local frameSortBg = AC:CreateFlatTexture(frameSortRow, "BACKGROUND", 1, {0.15, 0.15, 0.15, 1}, 1)
    frameSortBg:SetPoint("LEFT", 0, 0)
    frameSortBg:SetPoint("RIGHT", -30, 0)
    frameSortBg:SetHeight(20)
    
    -- Add hover effect
    frameSortRow:SetScript("OnEnter", function()
        frameSortBg:SetColorTexture(0.25, 0.25, 0.25, 1)
    end)
    frameSortRow:SetScript("OnLeave", function()
        frameSortBg:SetColorTexture(0.15, 0.15, 0.15, 1)
    end)
    
    -- Status icon (shows alert or checkmark)
    local frameSortStatusIcon = textDisplayContent:CreateTexture(nil, "OVERLAY")
    frameSortStatusIcon:SetSize(20, 20)  -- Slightly larger for better visibility
    frameSortStatusIcon:SetPoint("TOPLEFT", frameSortRow, "BOTTOMLEFT", 0, -4)
    frameSortStatusIcon:Hide()  -- Hidden by default
    
    -- Status/Warning Text
    local frameSortStatusText = textDisplayContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frameSortStatusText:SetPoint("LEFT", frameSortStatusIcon, "RIGHT", 4, 0)  -- Position after icon
    frameSortStatusText:SetJustifyH("LEFT")
    frameSortStatusText:SetWidth(380)
    
    -- Update status text function
    local function UpdateFrameSortStatus()
        local isEnabled = AC.DB and AC.DB.profile 
            and AC.DB.profile.arenaFrames 
            and AC.DB.profile.arenaFrames.general 
            and AC.DB.profile.arenaFrames.general.enableFrameSortIntegration or false
        local isDetected = FrameSortApi and FrameSortApi.v3
        
        if isEnabled and not isDetected then
            -- WARNING: Enabled but not detected - show alert icon
            frameSortStatusIcon:SetAtlas("Crosshair_Important_128")
            frameSortStatusIcon:SetVertexColor(1, 1, 1, 1)  -- Reset to white
            frameSortStatusIcon:Show()
            frameSortStatusText:SetText("|cffFF0000Warning:|r FrameSort addon not detected. Install FrameSort or disable integration.")
            frameSortStatusText:SetTextColor(1, 0.2, 0.2)
        elseif isEnabled and isDetected then
            -- SUCCESS: Enabled and detected - show green checkmark icon (same as unlock message)
            frameSortStatusIcon:SetAtlas("VAS-icon-checkmark-glw")
            frameSortStatusIcon:SetVertexColor(1, 1, 1, 1)  -- Reset to white (atlas has green built-in)
            frameSortStatusIcon:Show()
            frameSortStatusText:SetText("FrameSort detected and active")
            frameSortStatusText:SetTextColor(0.2, 1, 0.2)
        else
            -- DISABLED: No status needed - hide icon
            frameSortStatusIcon:Hide()
            frameSortStatusText:SetText("")
        end
    end
    
    -- Checkbox click handler
    frameSortBox:SetScript("OnClick", function(selfBtn)
        local isChecked = selfBtn:GetChecked()
        
        -- Save to database
        if AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general then
            AC.DB.profile.arenaFrames.general.enableFrameSortIntegration = isChecked
        end
        
        -- Update status text
        UpdateFrameSortStatus()
        
        -- Refresh frames immediately
        if AC.MasterFrameManager and AC.MasterFrameManager.UpdateFramePositions then
            AC.MasterFrameManager:UpdateFramePositions()
        end
        
        -- Refresh arena numbers
        if AC.RefreshArenaNumbers then
            AC:RefreshArenaNumbers()
        end
        
        -- Show warning if enabled but FrameSort not detected
        if isChecked and not (FrameSortApi and FrameSortApi.v3) then
            print("|cffFF0000[ArenaCore]|r FrameSort addon not detected! Please install FrameSort or disable integration.")
        end
    end)
    
    -- Initial status update
    UpdateFrameSortStatus()
    
    -- Auto-size after content is created
    C_Timer.After(0.05, function() textDisplayContent:AutoSize() end)
    
    -- ▼ Name Positioning (X/Y sliders for names/player names)
    local namePositionSection = CreateCollapsibleSection(mainContainer, "Name Positioning", 0, false)
    namePositionSection.parent = mainContainer
    local namePositionContent = CreateSectionContent(mainContainer, namePositionSection, 85)
    
    -- Enhanced sliders with ultra-fine precision for text positioning
    AC:CreateEnhancedSliderRow(namePositionContent, "Player Names X", -25, "arenaFrames.general.playerNameX", "text_positioning_horizontal")
    AC:CreateEnhancedSliderRow(namePositionContent, "Player Names Y", -55, "arenaFrames.general.playerNameY", "text_positioning_vertical")
    -- Auto-size after content is created
    C_Timer.After(0.05, function() namePositionContent:AutoSize() end)
    
    -- ▼ Arena Number Positioning (Arena numbers positioning)
    local numberPositionSection = CreateCollapsibleSection(mainContainer, "Arena Number Positioning", 0, false)
    numberPositionSection.parent = mainContainer
    local numberPositionContent = CreateSectionContent(mainContainer, numberPositionSection, 85)
    
    -- Enhanced sliders with ultra-fine precision for arena number positioning
    AC:CreateEnhancedSliderRow(numberPositionContent, "Arena Numbers X", -25, "arenaFrames.general.arenaNumberX", "arena_number_horizontal")
    AC:CreateEnhancedSliderRow(numberPositionContent, "Arena Numbers Y", -55, "arenaFrames.general.arenaNumberY", "arena_number_vertical")
    -- Auto-size after content is created
    C_Timer.After(0.05, function() numberPositionContent:AutoSize() end)
    
    -- ▼ Text Scaling & Fonts (all the percentage sliders)
    local textScalingSection = CreateCollapsibleSection(mainContainer, "Text Scaling & Fonts", 0, false)
    textScalingSection.parent = mainContainer
    local textScalingContent = CreateSectionContent(mainContainer, textScalingSection, 175)
    
    -- Enhanced sliders with ultra-fine precision for text scaling
    AC:CreateEnhancedSliderRow(textScalingContent, "Player Name Scale", -25, "arenaFrames.general.playerNameScale", "text_scaling_ultra")
    AC:CreateEnhancedSliderRow(textScalingContent, "Arena Number Scale", -55, "arenaFrames.general.arenaNumberScale", "text_scaling_ultra")
    AC:CreateEnhancedSliderRow(textScalingContent, "Health Text Scale", -85, "arenaFrames.general.healthTextScale", "text_scaling_ultra")
    AC:CreateEnhancedSliderRow(textScalingContent, "Resource Text Scale", -115, "arenaFrames.general.resourceTextScale", "text_scaling_ultra")
    AC:CreateEnhancedSliderRow(textScalingContent, "Spell Text Scale", -145, "arenaFrames.general.spellTextScale", "text_scaling_ultra")
    -- Auto-size after content is created
    C_Timer.After(0.05, function() textScalingContent:AutoSize() end)
    
    -- ▼ Arena Frame Themes (NEW FEATURE)
    local frameThemesSection = CreateCollapsibleSection(mainContainer, "Arena Frame Themes", 0, false)
    frameThemesSection.parent = mainContainer
    local frameThemesContent = CreateSectionContent(mainContainer, frameThemesSection, 80)
    
    -- Theme selection dropdown
    local themeLabel = AC:CreateStyledText(frameThemesContent, "Frame Theme", 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    themeLabel:SetPoint("TOPLEFT", 20, -25)
    themeLabel:SetWidth(120)
    themeLabel:SetJustifyH("LEFT")
    
    -- Get current theme and available themes
    local currentTheme = "Arena Core" -- Default
    if AC.ArenaFrameThemes then
        currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
    end
    
    local themeOptions = {"Arena Core", "The 1500 Special"}
    
    local themeDropdown = AC:CreateFlatDropdown(frameThemesContent, 150, 24, themeOptions, currentTheme, function(selectedTheme)
        -- Apply theme in real-time
        -- SwitchTheme now shows a reload popup and returns false immediately
        -- The popup handles user feedback, so no need for success/fail messages here
        if AC.ArenaFrameThemes then
            AC.ArenaFrameThemes:SwitchTheme(selectedTheme)
        else
            print("|cffFF6B6B ArenaCore:|r Theme system not loaded yet")
        end
        
        -- CRITICAL: Update Width/Height slider visibility based on theme
        if AC.ArenaFramesPage_UpdateSizingSliders then
            AC:ArenaFramesPage_UpdateSizingSliders(selectedTheme)
        end
    end)
    themeDropdown:SetPoint("LEFT", themeLabel, "RIGHT", 10, 0)
    
    -- Theme description text
    local themeDesc = AC:CreateStyledText(frameThemesContent, "Choose your preferred arena frame visual style", 10, AC.COLORS.TEXT_3, "OVERLAY", "")
    themeDesc:SetPoint("TOPLEFT", 20, -50)
    themeDesc:SetPoint("TOPRIGHT", -20, -50)
    themeDesc:SetJustifyH("LEFT")
    themeDesc:SetWordWrap(true)
    
    -- Auto-size after content is created
    C_Timer.After(0.05, function() frameThemesContent:AutoSize() end)
    
    -- Store sections in order for layout management
    mainContainer.sections = {
        textDisplay = textDisplaySection,
        namePosition = namePositionSection,
        numberPosition = numberPositionSection,
        textScaling = textScalingSection,
        frameThemes = frameThemesSection
    }
    
    mainContainer.sectionOrder = {
        textDisplaySection,
        namePositionSection,
        numberPositionSection,
        textScalingSection,
        frameThemesSection
    }
    
    -- Set up toggle callbacks for dynamic layout with throttling
    for _, section in ipairs(mainContainer.sectionOrder) do
        section.onToggle = function()
            C_Timer.After(0, function() 
                mainContainer:updateLayout()
                -- CRITICAL: Also push other groups down when ANY dropdown expands/collapses
                if mainContainer.pushOtherGroupsDown then
                    mainContainer:pushOtherGroupsDown()
                end
            end)
        end
    end
    
    -- Initial layout with scroll bar setup
    C_Timer.After(0.1, function() 
        mainContainer:updateLayout()
        if mainContainer.pushOtherGroupsDown then
            mainContainer:pushOtherGroupsDown()
        end
        -- ENHANCED: Initialize scroll bar range after layout is complete
        C_Timer.After(0.05, function()
            if mainContainer.pushOtherGroupsDown then
                mainContainer:pushOtherGroupsDown() -- This will set proper scroll range
            end
        end)
    end)
    
    return mainContainer
end

-- Create POSITIONING settings group
local function CreateGroup_POSITIONING(parent, y)
    local g = CreateFrame("Frame", nil, parent)
    g:SetPoint("TOPLEFT", 18, y)
    g:SetPoint("TOPRIGHT", -18, y)
    g:SetHeight(170)

    AC:HairlineGroupBox(g)

    local title = AC:CreateStyledText(g, "ARENA FRAME POSITIONING", 13, COLORS.PRIMARY, "OVERLAY", "")
    title:SetPoint("TOPLEFT", 20, -18)

    -- POSITIONING SLIDERS: Save directly to horizontal/vertical (source of truth)
    -- These control the absolute position of the arena frames anchor
    AC:CreateEnhancedSliderRow(g, "Horizontal", -50, "arenaFrames.positioning.horizontal", "positioning_horizontal")
    AC:CreateEnhancedSliderRow(g, "Vertical", -80, "arenaFrames.positioning.vertical", "positioning_vertical")
    AC:CreateEnhancedSliderRow(g, "Spacing", -110, "arenaFrames.positioning.spacing", "spacing")
    
    -- Add Growth Direction dropdown
    local growthLabel = AC:CreateStyledText(g, "Growth Direction", 11, COLORS.TEXT_2, "OVERLAY", "")
    growthLabel:SetPoint("TOPLEFT", 20, -140)
    growthLabel:SetWidth(100)
    growthLabel:SetJustifyH("LEFT")
    
        local growthDir = S:Get("arenaFrames.positioning.growthDirection", "Down")
    local growthDropdown = AC:CreateFlatDropdown(g, 120, 24, {"Down", "Up", "Right", "Left"}, growthDir, function(value)
        AC:OnArenaFramesGrowthDirectionChanged(value)
    end)
    growthDropdown:SetPoint("LEFT", growthLabel, "RIGHT", 10, 0)
    
    AC.growthDirectionDropdown = growthDropdown
    
    return g
end

-- Create SIZING settings group
local function CreateGroup_SIZING(parent, y)
    local g = CreateFrame("Frame", nil, parent)
    g:SetPoint("TOPLEFT", 18, y)
    g:SetPoint("TOPRIGHT", -18, y)
    g:SetHeight(170)  -- Increased from 140 to accommodate 4th slider

    AC:HairlineGroupBox(g)

    local title = AC:CreateStyledText(g, "ARENA FRAME SIZING", 13, COLORS.PRIMARY, "OVERLAY", "")
    title:SetPoint("TOPLEFT", 20, -18)

    -- Enhanced sliders with 1-10 scale
    AC:CreateSliderSetting(g, "Scale", -50, "arenaFrames.sizing.scale", 50, 150, 100, true, false)
    local widthRow = AC:CreateSliderSetting(g, "Width", -80, "arenaFrames.sizing.width", 150, 300, 220, false, false)
    local heightRow = AC:CreateSliderSetting(g, "Height", -110, "arenaFrames.sizing.height", 50, 100, 72, false, false)
    
    -- STYLED TARGET BORDER THICKNESS SLIDER (matching existing UI)
    local thicknessRow = CreateFrame("Frame", nil, g)
    thicknessRow:SetPoint("TOPLEFT", 20, -140)
    thicknessRow:SetPoint("TOPRIGHT", -20, -140)
    thicknessRow:SetHeight(26)

    local thicknessLabel = AC:CreateStyledText(thicknessRow, "Target Border Thickness", 11, COLORS.TEXT_2, "OVERLAY", "")
    thicknessLabel:SetPoint("LEFT", 0, 0)
    thicknessLabel:SetWidth(100)
    thicknessLabel:SetJustifyH("LEFT")

    local minText = AC:CreateStyledText(thicknessRow, "1", 10, COLORS.TEXT_MUTED, "OVERLAY", "")
    minText:SetPoint("LEFT", thicknessLabel, "RIGHT", 10, 0)

    local thicknessSlider = AC:CreateFlatSlider(thicknessRow, 120, 18, 1, 5, 3, false)
    thicknessSlider:SetPoint("LEFT", minText, "RIGHT", 8, 0)

    local maxText = AC:CreateStyledText(thicknessRow, "5", 10, COLORS.TEXT_MUTED, "OVERLAY", "")
    maxText:SetPoint("LEFT", thicknessSlider, "RIGHT", 8, 0)

    local valueText = AC:CreateStyledText(thicknessRow, "", 11, COLORS.TEXT_2, "OVERLAY", "")
    valueText:SetPoint("LEFT", maxText, "RIGHT", 8, 0)
    valueText:SetWidth(35)
    valueText:SetJustifyH("CENTER")

    -- Get current value from database
    local currentThickness = 3
    if AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.sizing then
        currentThickness = AC.DB.profile.arenaFrames.sizing.targetBorderThickness or 3
    end
    thicknessSlider.slider:SetValue(currentThickness)

    local function updateValue()
        local value = thicknessSlider.slider:GetValue()
        valueText:SetText(string.format("%.0f", value))
    end

    -- Custom slider script (bypassing broken callback system)
    thicknessSlider.slider:SetScript("OnValueChanged", function(_, value)
        updateValue()
        
        -- Save to database
        if AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames then
            AC.DB.profile.arenaFrames.sizing = AC.DB.profile.arenaFrames.sizing or {}
            AC.DB.profile.arenaFrames.sizing.targetBorderThickness = value
        end
        
        -- Update border in real-time
        AC:UpdateAllTargetBorders()
        
        print("|cff8B45FFArena Core:|r Target border thickness set to " .. value)
    end)

    updateValue()
    
    -- CRITICAL: Store references to Width/Height sliders for theme-based visibility control
    g.widthSlider = widthRow
    g.heightSlider = heightRow
    
    return g
end

-- Create the tab row with action buttons
local function CreateTabRow(parent)
    local prev = { parent:GetChildren() }
    for _, ch in ipairs(prev) do ch:Hide(); ch:SetParent(nil) end

    local row = CreateFrame("Frame", nil, parent)
    row:SetAllPoints()

    local saveBtn = AC:CreateTexturedButton(row, 100, 32, "Save Settings", "UI\\tab-purple-matte")
    saveBtn:SetPoint("LEFT", 12, 0)
    saveBtn:SetScript("OnClick", function()
        -- CRITICAL FIX: Save ALL settings to disk, not just position!
        -- The button is called "Save Settings" so it should save EVERYTHING
        
        if not AC or not AC.DB then
            print("|cffFF0000ArenaCore:|r Database not available!")
            return
        end
        
        -- Force WoW to write the saved variables to disk
        -- This ensures all current settings (including scale, width, height, etc.) are persisted
        if AC.DB.profile then
            -- Mark the database as changed so WoW will save it
            AC.DB.profile.lastSaved = time()
            
            print("|cff8B45FFArena Core:|r All settings saved to disk!")
            print("|cff8B45FFArena Core:|r Scale: " .. tostring(AC.DB.profile.arenaFrames.sizing.scale) .. "%, Width: " .. tostring(AC.DB.profile.arenaFrames.sizing.width) .. "px, Height: " .. tostring(AC.DB.profile.arenaFrames.sizing.height) .. "px")
            
            -- Play custom ArenaCore save sound for feedback
            PlaySoundFile("Interface/AddOns/ArenaCore/Media/Sounds/InfoSaved.mp3", "Master")
        else
            print("|cffFF0000ArenaCore:|r Could not access database profile!")
        end
    end)
    
    -- Profiles button - shortcut to More Features > Profiles page
    local profilesBtn = AC:CreateTexturedButton(row, 100, 32, "Profiles", "UI\\tab-purple-matte")
    profilesBtn:SetPoint("LEFT", saveBtn, "RIGHT", 8, 0)
    profilesBtn:SetScript("OnClick", function()
        -- Open More Features window and navigate to Profiles page
        if AC.MoreFeatures and AC.MoreFeatures.ShowProfilesTab then
            -- Use the built-in ShowProfilesTab method which handles everything
            AC.MoreFeatures:ShowProfilesTab()
        elseif AC.MoreFeatures and AC.MoreFeatures.ShowWindow then
            -- Fallback: manually open and navigate
            AC.MoreFeatures:ShowWindow()
            if AC.MoreFeatures.SelectPage then
                C_Timer.After(0.15, function()
                    AC.MoreFeatures:SelectPage("profiles")
                end)
            end
        else
            print("|cffFF0000ArenaCore:|r More Features module not available!")
        end
    end)

    -- ============================================================================
    -- EDIT MODE BUTTON - DISABLED
    -- ============================================================================
    -- Edit Mode removed to eliminate positioning drift
    -- 
    -- WHY REMOVED:
    -- - GetPoint() capture accumulated floating-point errors
    -- - Result: 1-3 pixel drift after multiple theme switches
    --
    -- SOLUTION:
    -- - Use sliders for positioning (single source of truth)
    -- - No position capture = no feedback loop = ZERO DRIFT
    --
    -- LEGACY CODE:
    -- - Edit Mode files moved to legacy/ folder
    -- - Can be restored if needed in future
    -- - See POSITIONING_RESEARCH.md for details
    -- ============================================================================
    
    -- Edit Mode button code INTENTIONALLY REMOVED
    -- Users now use sliders on Trinkets/Other page for positioning
    -- Sliders provide precise 1-pixel control without drift

    -- NEW UNIFIED ARCHITECTURE TEST BUTTON
    local testBtn = AC:CreateTexturedButton(row, 80, 32, "TEST", "button-test")
    testBtn:SetPoint("RIGHT", -90, 0)
    testBtn:SetScript("OnClick", function()
        if AC.FrameManager then
            -- Always enable test mode (don't toggle)
            AC.FrameManager:EnableTestMode()
        else
            print("|cffFF0000ArenaCore:|r New frame system not loaded!")
        end
    end)

    local hideBtn = AC:CreateTexturedButton(row, 80, 32, "HIDE", "button-hide")
    hideBtn:SetPoint("RIGHT", -6, 0)
    hideBtn:SetScript("OnClick", function()
        if AC.FrameManager then
            AC.FrameManager:DisableTestMode()
        else
            print("|cffFF0000ArenaCore:|r New frame system not loaded!")
        end
    end)

    -- Create a second row for lock/unlock buttons below the first row
    local lockRow = CreateFrame("Frame", nil, parent)
    lockRow:SetSize(parent:GetWidth() - 24, 32)
    lockRow:SetPoint("TOP", row, "BOTTOM", 0, -4)
    
    -- Create flat matte dark buttons
    local unlockBtn = CreateFrame("Button", nil, lockRow)
    unlockBtn:SetSize(100, 28)
    unlockBtn:SetPoint("LEFT", 12, 0)
    
    -- Create flat dark background (even darker for Shade UI)
    local unlockBg = unlockBtn:CreateTexture(nil, "BACKGROUND")
    unlockBg:SetAllPoints()
    unlockBg:SetColorTexture(0.05, 0.05, 0.05, 1) -- Even darker
    
    local unlockBorder = unlockBtn:CreateTexture(nil, "BORDER")
    unlockBorder:SetAllPoints()
    unlockBorder:SetColorTexture(0.10, 0.10, 0.10, 1) -- Even darker border
    unlockBorder:SetPoint("TOPLEFT", 1, -1)
    unlockBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Purple outline glow for hover (edge only, hidden by default)
    local unlockGlowTop = unlockBtn:CreateTexture(nil, "OVERLAY")
    unlockGlowTop:SetColorTexture(0.545, 0.271, 1.000, 1)
    unlockGlowTop:SetPoint("TOPLEFT", -1, 1)
    unlockGlowTop:SetPoint("TOPRIGHT", 1, 1)
    unlockGlowTop:SetHeight(2)
    unlockGlowTop:Hide()
    
    local unlockGlowBottom = unlockBtn:CreateTexture(nil, "OVERLAY")
    unlockGlowBottom:SetColorTexture(0.545, 0.271, 1.000, 1)
    unlockGlowBottom:SetPoint("BOTTOMLEFT", -1, -1)
    unlockGlowBottom:SetPoint("BOTTOMRIGHT", 1, -1)
    unlockGlowBottom:SetHeight(2)
    unlockGlowBottom:Hide()
    
    local unlockGlowLeft = unlockBtn:CreateTexture(nil, "OVERLAY")
    unlockGlowLeft:SetColorTexture(0.545, 0.271, 1.000, 1)
    unlockGlowLeft:SetPoint("TOPLEFT", -1, 1)
    unlockGlowLeft:SetPoint("BOTTOMLEFT", -1, -1)
    unlockGlowLeft:SetWidth(2)
    unlockGlowLeft:Hide()
    
    local unlockGlowRight = unlockBtn:CreateTexture(nil, "OVERLAY")
    unlockGlowRight:SetColorTexture(0.545, 0.271, 1.000, 1)
    unlockGlowRight:SetPoint("TOPRIGHT", 1, 1)
    unlockGlowRight:SetPoint("BOTTOMRIGHT", 1, -1)
    unlockGlowRight:SetWidth(2)
    unlockGlowRight:Hide()
    
    local unlockText = unlockBtn:CreateFontString(nil, "OVERLAY")
    unlockText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 11)
    unlockText:SetText("Unlock")
    unlockText:SetTextColor(0.9, 0.9, 0.9, 1)
    unlockText:SetPoint("CENTER")
    
    unlockBtn:SetScript("OnClick", function()
        -- CRITICAL FIX: Call EnableFrameDragging() to properly set up drag system
        if AC.EnableFrameDragging then
            AC:EnableFrameDragging()
        else
            AC.framesLocked = false
            print("|cffFF0000ArenaCore:|r EnableFrameDragging function not available!")
        end
        if AC.IsUIVisible and AC.currentPage == "ArenaFrames" and AC.ShowPage then
            AC:ShowPage("ArenaFrames")
        end
    end)
    
    unlockBtn:SetScript("OnEnter", function()
        unlockBg:SetColorTexture(0.08, 0.08, 0.08, 1)  -- Even darker hover
        unlockGlowTop:Show()
        unlockGlowBottom:Show()
        unlockGlowLeft:Show()
        unlockGlowRight:Show()
    end)
    
    unlockBtn:SetScript("OnLeave", function()
        unlockBg:SetColorTexture(0.05, 0.05, 0.05, 1)  -- Even darker
        unlockGlowTop:Hide()
        unlockGlowBottom:Hide()
        unlockGlowLeft:Hide()
        unlockGlowRight:Hide()
    end)
    
    local lockBtn = CreateFrame("Button", nil, lockRow)
    lockBtn:SetSize(100, 28)
    lockBtn:SetPoint("LEFT", unlockBtn, "RIGHT", 8, 0)
    
    -- Create flat dark background (even darker for Shade UI)
    local lockBg = lockBtn:CreateTexture(nil, "BACKGROUND")
    lockBg:SetAllPoints()
    lockBg:SetColorTexture(0.05, 0.05, 0.05, 1) -- Even darker
    
    local lockBorder = lockBtn:CreateTexture(nil, "BORDER")
    lockBorder:SetAllPoints()
    lockBorder:SetColorTexture(0.10, 0.10, 0.10, 1) -- Even darker border
    lockBorder:SetPoint("TOPLEFT", 1, -1)
    lockBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Purple outline glow for hover (edge only, hidden by default)
    local lockGlowTop = lockBtn:CreateTexture(nil, "OVERLAY")
    lockGlowTop:SetColorTexture(0.545, 0.271, 1.000, 1)
    lockGlowTop:SetPoint("TOPLEFT", -1, 1)
    lockGlowTop:SetPoint("TOPRIGHT", 1, 1)
    lockGlowTop:SetHeight(2)
    lockGlowTop:Hide()
    
    local lockGlowBottom = lockBtn:CreateTexture(nil, "OVERLAY")
    lockGlowBottom:SetColorTexture(0.545, 0.271, 1.000, 1)
    lockGlowBottom:SetPoint("BOTTOMLEFT", -1, -1)
    lockGlowBottom:SetPoint("BOTTOMRIGHT", 1, -1)
    lockGlowBottom:SetHeight(2)
    lockGlowBottom:Hide()
    
    local lockGlowLeft = lockBtn:CreateTexture(nil, "OVERLAY")
    lockGlowLeft:SetColorTexture(0.545, 0.271, 1.000, 1)
    lockGlowLeft:SetPoint("TOPLEFT", -1, 1)
    lockGlowLeft:SetPoint("BOTTOMLEFT", -1, -1)
    lockGlowLeft:SetWidth(2)
    lockGlowLeft:Hide()
    
    local lockGlowRight = lockBtn:CreateTexture(nil, "OVERLAY")
    lockGlowRight:SetColorTexture(0.545, 0.271, 1.000, 1)
    lockGlowRight:SetPoint("TOPRIGHT", 1, 1)
    lockGlowRight:SetPoint("BOTTOMRIGHT", 1, -1)
    lockGlowRight:SetWidth(2)
    lockGlowRight:Hide()
    
    local lockText = lockBtn:CreateFontString(nil, "OVERLAY")
    lockText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 11)
    lockText:SetText("Lock")
    lockText:SetTextColor(0.9, 0.9, 0.9, 1)
    lockText:SetPoint("CENTER")
    
    lockBtn:SetScript("OnClick", function()
        -- CRITICAL FIX: Call DisableFrameDragging() to properly disable drag system
        if AC.DisableFrameDragging then
            AC:DisableFrameDragging()
        else
            AC.framesLocked = true
            print("|cffFF0000ArenaCore:|r DisableFrameDragging function not available!")
        end
        if AC.IsUIVisible and AC.currentPage == "ArenaFrames" and AC.ShowPage then
            AC:ShowPage("ArenaFrames")
        end
    end)
    
    lockBtn:SetScript("OnEnter", function()
        lockBg:SetColorTexture(0.08, 0.08, 0.08, 1)  -- Even darker hover
        lockGlowTop:Show()
        lockGlowBottom:Show()
        lockGlowLeft:Show()
        lockGlowRight:Show()
    end)
    
    lockBtn:SetScript("OnLeave", function()
        lockBg:SetColorTexture(0.05, 0.05, 0.05, 1)  -- Even darker
        lockGlowTop:Hide()
        lockGlowBottom:Hide()
        lockGlowLeft:Hide()
        lockGlowRight:Hide()
    end)

    -- Add drag instruction alert message across from the buttons (two lines)
    local dragAlert1 = AC:CreateStyledText(lockRow, "Ctrl+Alt+Left Click", 10, COLORS.TEXT_2, "OVERLAY", "")
    dragAlert1:SetPoint("RIGHT", -12, 6)
    dragAlert1:SetJustifyH("RIGHT")
    dragAlert1:SetTextColor(0.8, 0.9, 1.0, 0.9) -- Light blue tint
    
    local dragAlert2 = AC:CreateStyledText(lockRow, "to drag frames!", 10, COLORS.TEXT_2, "OVERLAY", "")
    dragAlert2:SetPoint("RIGHT", -12, -6)
    dragAlert2:SetJustifyH("RIGHT")
    dragAlert2:SetTextColor(0.8, 0.9, 1.0, 0.9) -- Light blue tint

    AC:PurgeFakeHideTest(row)
    row:SetScript("OnShow", function() AC:PurgeFakeHideTest(row) end)

    AC.tabContainer = parent
end

function AC:OnArenaFramesSliderChanged(slider, path, value)
    -- CRITICAL: Don't save if drag just finished (prevents overwriting drag position)
    if AC.justFinishedDragging then
        return
    end
    
    -- Use both settings systems to ensure consistency
    if S and S.Set then
        S:Set(path, value)
    end

    -- ALSO save to the DB directly for immediate access
    if AC and AC.EnsureDB and AC.SetPath then
        AC:EnsureDB()
        -- Only accept paths under arenaFrames.*
        if type(path) == "string" and path:match("^arenaFrames%.") then
            AC:SetPath(AC.DB.profile, path, value)
            _G.ArenaCoreDB = AC.DB
            
            -- CRITICAL: ALSO save to theme-specific settings for theme isolation
            if AC.ArenaFrameThemes then
                local currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
                if currentTheme then
                    -- Initialize theme data structure if needed
                    if not AC.DB.profile.themeData then
                        AC.DB.profile.themeData = {}
                    end
                    if not AC.DB.profile.themeData[currentTheme] then
                        AC.DB.profile.themeData[currentTheme] = {}
                    end
                    
                    -- Save to theme-specific location
                    AC:SetPath(AC.DB.profile.themeData[currentTheme], path, value)
                end
            end
        end
    end

    -- Apply changes to Master Frame Manager system immediately
    if path:find("arenaFrames.positioning") then
        -- Handle positioning changes (horizontal, vertical, spacing)
        -- CRITICAL FIX: Only call UpdateFramePositions ONCE (not twice)
        -- MasterFrameManager.UpdateFramePositions is the authoritative function
        if AC.MasterFrameManager and AC.MasterFrameManager.UpdateFramePositions then
            AC.MasterFrameManager:UpdateFramePositions()
        elseif AC.UpdateFramePositions then
            AC:UpdateFramePositions()
        end
    elseif path:find("arenaFrames.sizing.scale") then
        -- Handle scale changes
        if AC.UpdateFrameScale then
            AC:UpdateFrameScale()
        end
        print("|cff8B45FFArena Core:|r Scale updated!")
    elseif path:find("arenaFrames.sizing") then
        -- Handle size changes (width, height)
        if AC.UpdateFrameSize then
            AC:UpdateFrameSize()
        end
        
        print("|cff8B45FFArena Core:|r Size updated!")
    elseif path:find("arenaFrames.general") then
        -- Handle general settings
        if AC.RefreshAllFrames then
            AC:RefreshAllFrames()
        end
        print("|cff8B45FFArena Core:|r Settings updated!")
    end
end

function AC:OnArenaFramesCheckboxToggle(checkbox, path, checked)
    S:Set(path, checked)

    -- Apply changes to Master Frame Manager system immediately
    if path:find("arenaFrames.general") then
        if AC.RefreshAllFrames then
            AC:RefreshAllFrames()
        end
        print("|cff8B45FFArena Core:|r " .. (path:gsub(".*%.", "")) .. " " .. (checked and "enabled" or "disabled") .. "!")
    end
end

function AC:OnArenaFramesGrowthDirectionChanged(direction)
    -- Set flag to indicate this is a UI control change (for smart positioning refresh)
    AC._isSliderChange = true
    
    S:Set("arenaFrames.positioning.growthDirection", direction)
    
    -- Apply changes to Master Frame Manager system immediately
    if AC.UpdateFramePositions then
        AC:UpdateFramePositions()
    end
    if AC.MasterFrameManager and AC.MasterFrameManager.UpdateFramePositions then
        AC.MasterFrameManager:UpdateFramePositions()
    end
    print("|cff8B45FFArena Core:|r Growth direction: " .. direction)
    
    -- Clear the flag after processing
    AC._isSliderChange = false
end

-- ============================================================================
-- DUPLICATE CreateTabRow REMOVED - Using the proper textured version above (line 856)
-- ============================================================================

-- RESTRUCTURED: Work exactly like other pages using the main content area
local function CreateArenaFramesPage(root)
    if V and V.EnsureMottoStrip then V:EnsureMottoStrip(root) end
    
    -- Create the button strip (increased height for two rows of buttons)
    local strip = CreateFrame("Frame", nil, root)
    strip:SetHeight(58) -- Compact height for two rows
    
    if root._mottoStrip then
        strip:SetPoint("TOPLEFT", root._mottoStrip, "BOTTOMLEFT", 0, -8)
        strip:SetPoint("TOPRIGHT", root._mottoStrip, "BOTTOMRIGHT", 0, -8)
    else
        strip:SetPoint("TOPLEFT", 6, -52)
        strip:SetPoint("TOPRIGHT", -6, -52)
    end

    local sBorder = AC:CreateFlatTexture(strip, "BACKGROUND", 1, COLORS.BORDER_LIGHT, 0.6)
    sBorder:SetAllPoints()

    local sFill = AC:CreateFlatTexture(strip, "BACKGROUND", 2, COLORS.INPUT_DARK, 1)
    sFill:SetPoint("TOPLEFT", 1, -1)
    sFill:SetPoint("BOTTOMRIGHT", -1, 1)

    CreateTabRow(strip)
    AC:HideLegacyJunk(strip)

    -- Create content directly in root like other pages (no custom scroll frame)
    local currentY = -150 -- Start further below to avoid button overlap
    
    -- Create GENERAL group with collapsible sections
    local generalGroup = CreateGroup_GENERAL(root, currentY)
    currentY = currentY - 250 -- Space for general group
    
    -- Create POSITIONING group 
    local positioningGroup = CreateGroup_POSITIONING(root, currentY)
    currentY = currentY - 180
    
    -- Create SIZING group
    local sizingGroup = CreateGroup_SIZING(root, currentY)
    currentY = currentY - 150
    
    -- Store references for dynamic positioning
    local mainContainer = generalGroup
    mainContainer.positioningGroup = positioningGroup
    mainContainer.sizingGroup = sizingGroup
    
    -- CRITICAL: Function to update Width/Height slider visibility based on theme
    function AC:ArenaFramesPage_UpdateSizingSliders(themeName)
        if not sizingGroup or not sizingGroup.widthSlider or not sizingGroup.heightSlider then
            return
        end
        
        -- Hide Width/Height sliders for "The 1500 Special" theme
        -- Show them for "Arena Core" theme
        local shouldHide = (themeName == "The 1500 Special")
        
        if shouldHide then
            sizingGroup.widthSlider:Hide()
            sizingGroup.heightSlider:Hide()
        else
            sizingGroup.widthSlider:Show()
            sizingGroup.heightSlider:Show()
        end
    end
    
    -- CRITICAL: Initialize slider visibility based on current theme
    C_Timer.After(0.1, function()
        if AC.ArenaFrameThemes then
            local currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
            AC:ArenaFramesPage_UpdateSizingSliders(currentTheme)
        end
    end)
    
    -- Enhanced pushOtherGroupsDown that works with the global scroll system
    function mainContainer:pushOtherGroupsDown()
        local totalHeight = 0
        for i, section in ipairs(self.sectionOrder) do
            totalHeight = totalHeight + 35 -- Header height
            if section.isExpanded and section.contentFrame then
                totalHeight = totalHeight + section.contentFrame:GetHeight()
            end
            totalHeight = totalHeight + 15 -- Gap between sections
        end
        
        local positioningY = -150 - totalHeight - 20 -- Start below strip + sections + gap
        local sizingY = positioningY - 170 - 10 -- POSITIONING height + gap
        
        -- Move groups with absolute positioning
        if positioningGroup then
            positioningGroup:ClearAllPoints()
            positioningGroup:SetPoint("TOPLEFT", 18, positioningY)
            positioningGroup:SetPoint("TOPRIGHT", -18, positioningY)
            positioningGroup:Show()
        end
        
        if sizingGroup then
            sizingGroup:ClearAllPoints()
            sizingGroup:SetPoint("TOPLEFT", 18, sizingY)
            sizingGroup:SetPoint("TOPRIGHT", -18, sizingY)
            sizingGroup:Show()
        end
        
        -- Update global content height like other pages
        local totalContentHeight = math.abs(sizingY) + 200
        if AC.UpdateContentHeight then
            C_Timer.After(0.1, function()
                AC:UpdateContentHeight()
            end)
        end
    end
end

-- CreateArenaFramesPage function defined

-- ============================================================================
-- Apply All Settings
-- ============================================================================
-- New function to apply all saved settings to the frames at once.
-- This is called after the addon loads to synchronize the visual state.
function AC:ApplyAllArenaFrameSettings()
    -- OLD ApplyAllArenaFrameSettings disabled - using new unified system
    return -- Exit early, new system handles everything
    
    -- OLD CODE DISABLED:
    -- Commented out old refresh logic - now handled by other systems
    -- if AC.UpdateFramePosition then AC:UpdateFramePosition() end
    -- if AC.UpdateFrameSpacing then AC:UpdateFrameSpacing() end
    -- if AC.UpdateFrameScale then AC:UpdateFrameScale() end
    -- if AC.UpdateFrameSize then AC:UpdateFrameSize() end
    -- if AC.RefreshGeneralSettings then AC:RefreshGeneralSettings() end
end

-- ============================================================================
-- Event Handling
-- ============================================================================
-- Use an event handler to apply settings after the addon and frames are fully loaded.
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0.5, function() -- Short delay to ensure frames are created
            AC:ApplyAllArenaFrameSettings()
        end)
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- Register the page with the AC system
AC:RegisterPage("ArenaFrames", CreateArenaFramesPage)
