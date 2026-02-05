-- ============================================================================
-- File: Core/Pages/ClassPacks.lua (FIXED WITH PROPER DATABASE INTEGRATION)
-- Purpose: Class Packs settings page that actually drives the Tri‑Badges (3 icons)
-- FIX: Now uses same database pattern as TrinketsOther page for proper saving
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

-- Helper function to get the database profile (same as TrinketsOther)
local function DB()
  return (AC.DB and AC.DB.profile) or {}
end

-- Show Midnight restriction notice at the top of the page creation
local function ShowMidnightNoticeIfNeeded(parent)
  if AC.MidnightNotice and AC.MidnightNotice:ShouldShowNoticeForPage("ClassPacks") then
    AC.MidnightNotice:ShowNotice(parent, "classpacks")
  end
end

-- Store slider references for direct updates (same as TrinketsOther)
local sliderWidgets = {}

-- CLEAN SLATE: No complex slider sync needed with simple direct save approach

-- Helper function to create a standardized slider row (same as TrinketsOther)
local function CreateSliderSetting(parent, label, y, path, min, max, isPct, compactDisplay)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", 20, y); row:SetPoint("TOPRIGHT", -20, y); row:SetHeight(26)

  local displayMin = min
  local displayMax = max
  if compactDisplay then
    displayMin = math.floor(min / 100)
    displayMax = math.floor(max / 100)
  end

  local l = AC:CreateStyledText(row, label, 11, AC.COLORS.TEXT_2, "OVERLAY", ""); l:SetPoint("LEFT", 0, 0); l:SetWidth(70); l:SetJustifyH("LEFT")
  local minT = AC:CreateStyledText(row, isPct and (displayMin .. "%") or tostring(displayMin), 9, AC.COLORS.TEXT_MUTED, "OVERLAY", ""); minT:SetPoint("LEFT", l, "RIGHT", 6, 0); minT:SetWidth(25); minT:SetJustifyH("RIGHT")
  
  -- Create DOWN arrow button for fine adjustment
  local downBtn = CreateFrame("Button", nil, row)
  downBtn:SetSize(16, 16)
  downBtn:SetPoint("LEFT", minT, "RIGHT", 6, 0)
  
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

  local keys = {}; for k in string.gmatch(path, "([^%.]+)") do table.insert(keys, k) end
  
  local function GetValue()
    local target = DB(); for i=1, #keys do target = target and target[keys[i]] end
    return target
  end
  
  -- CLEAN SLATE: No sync needed - sliders read directly from offsetX/offsetY
  -- Edit Mode saves directly to offsetX/offsetY (no draggedBase/sliderOffset)
  -- NOTE: Cleanup moved to CreateClassPacksPage to run once, not per slider
  
  local val = GetValue() or (isPct and 100 or 0)
  local valT = AC:CreateStyledText(row, "", 11, AC.COLORS.TEXT_2, "OVERLAY", ""); valT:SetWidth(70); valT:SetJustifyH("CENTER")

  local function OnChange(value)
    local target = AC.DB.profile; for i=1, #keys - 1 do target[keys[i]] = target[keys[i]] or {}; target = target[keys[i]] end
    target[keys[#keys]] = value
    
    -- NOTE: Edit Mode integration is now handled by Helpers.lua CreateEnhancedSliderRow
    -- No need for duplicate logic here
    
    if isPct then 
      valT:SetText(string.format("%.0f%%", value))
    elseif compactDisplay then
      valT:SetText(string.format("%.0f", math.floor(value / 100)))
    else 
      valT:SetText(string.format("%.0f", value)) 
    end
    
    -- CRITICAL: Save to current theme to persist changes across reloads
    if AC.ArenaFrameThemes and AC.ArenaFrameThemes.SaveCurrentThemeSettings then
      AC.ArenaFrameThemes:SaveCurrentThemeSettings()
    end
    
    -- CRITICAL FIX: Call RefreshClassPacksLayout for real-time updates (like other pages)
    if AC.RefreshClassPacksLayout then
      AC:RefreshClassPacksLayout()
    end
  end

  local slider = AC:CreateFlatSlider(row, 120, 18, min, max, val, isPct, OnChange)
  slider:SetPoint("LEFT", downBtn, "RIGHT", 4, 0)
  
  -- Store slider reference for direct updates during reset
  sliderWidgets[path] = slider.slider

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

  local maxT = AC:CreateStyledText(row, isPct and (displayMax .. "%") or tostring(displayMax), 9, AC.COLORS.TEXT_MUTED, "OVERLAY", ""); maxT:SetPoint("LEFT", upBtn, "RIGHT", 6, 0); maxT:SetWidth(20); maxT:SetJustifyH("LEFT")
  valT:SetPoint("LEFT", maxT, "RIGHT", 8, 0)
  
  -- Initialize the value display
  OnChange(val)

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
  
  -- Arrow hover effects
  downBtn:SetScript("OnEnter", function()
    downBg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
    downText:SetTextColor(1, 1, 1, 1)
  end)
  downBtn:SetScript("OnLeave", function()
    downBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    downText:SetTextColor(0.8, 0.8, 0.8, 1)
  end)
  
  upBtn:SetScript("OnEnter", function()
    upBg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
    upText:SetTextColor(1, 1, 1, 1)
  end)
  upBtn:SetScript("OnLeave", function()
    upBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    upText:SetTextColor(0.8, 0.8, 0.8, 1)
  end)

  return row
end

-- Helper function to create a dropdown setting (same as TrinketsOther)
local function CreateDropdownSetting(parent, label, y, path, optionsMap, defaultValue)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", 20, y); row:SetPoint("TOPRIGHT", -20, y); row:SetHeight(26)

  local l = AC:CreateStyledText(row, label, 12, AC.COLORS.TEXT_2, "OVERLAY", ""); l:SetPoint("LEFT", 0, 0); l:SetWidth(120); l:SetJustifyH("LEFT")
  
  local keys = {}; for k in string.gmatch(path, "([^%.]+)") do table.insert(keys, k) end
  
  -- Create display options array and mapping
  local displayOptions = {}
  local displayToValue = {}
  local valueToDisplay = {}
  
  for displayText, internalValue in pairs(optionsMap) do
    table.insert(displayOptions, displayText)
    displayToValue[displayText] = internalValue
    valueToDisplay[internalValue] = displayText
  end

  local function GetValue()
    local target = DB(); for i=1, #keys do target = target and target[keys[i]] end
    local currentValue = target or defaultValue
    return valueToDisplay[currentValue] or displayOptions[1]
  end
  
  local function OnChange(displayText)
    local internalValue = displayToValue[displayText]
    
    -- Save to database
    local target = AC.DB.profile; for i=1, #keys - 1 do target[keys[i]] = target[keys[i]] or {}; target = target[keys[i]] end
    target[keys[#keys]] = internalValue
    
    -- CRITICAL: Save to current theme to persist changes across reloads
    if AC.ArenaFrameThemes and AC.ArenaFrameThemes.SaveCurrentThemeSettings then
      AC.ArenaFrameThemes:SaveCurrentThemeSettings()
    end
    
    -- Trigger refresh
    if AC.RefreshClassPacksLayout then
      AC:RefreshClassPacksLayout()
    end
  end

  local dropdown = AC:CreateFlatDropdown(row, 180, 24, displayOptions, GetValue(), OnChange)
  dropdown:SetPoint("LEFT", l, "RIGHT", 10, 0)
  
  return row
end

-- Helper function to create linked checkboxes (same as TrinketsOther)
local function CreateCheckboxSetting(parent, label, y, path)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", 20, y); row:SetPoint("TOPRIGHT", -20, y); row:SetHeight(26)

  local l = AC:CreateStyledText(row, label, 12, AC.COLORS.TEXT_2, "OVERLAY", ""); l:SetPoint("LEFT", 0, 0)
  
  local keys = {}; for k in string.gmatch(path, "([^%.]+)") do table.insert(keys, k) end

  local function GetValue()
    local target = DB(); for i=1, #keys do target = target and target[keys[i]] end
    return target
  end
  
  local isChecked = GetValue()
  if isChecked == nil then isChecked = true end -- Default to true if not set

  local function OnChange(value)
    local target = AC.DB.profile; for i=1, #keys - 1 do target[keys[i]] = target[keys[i]] or {}; target = target[keys[i]] end
    target[keys[#keys]] = value
    
    -- CRITICAL: Save to current theme to persist changes across reloads
    if AC.ArenaFrameThemes and AC.ArenaFrameThemes.SaveCurrentThemeSettings then
      AC.ArenaFrameThemes:SaveCurrentThemeSettings()
    end
    
    -- CRITICAL FIX: Call RefreshClassPacksLayout for real-time updates (like other pages)
    if AC.RefreshClassPacksLayout then
      AC:RefreshClassPacksLayout()
    end
  end

  local box = AC:CreateFlatCheckbox(row, 20, isChecked, OnChange)
  box:SetPoint("RIGHT", -25, 0)
  
  return row
end

-- ---------- Page builder ----------
local function CreateClassPacksPage(parent)
  -- Show Midnight restriction notice if applicable
  ShowMidnightNoticeIfNeeded(parent)
  
  -- CLEANUP: Remove any old draggedBase/sliderOffset keys from previous system
  -- This ensures a clean slate when opening the page
  local db = AC.DB and AC.DB.profile
  if db and db.classPacks then
    db.classPacks.draggedBaseX = nil
    db.classPacks.draggedBaseY = nil
    db.classPacks.sliderOffsetX = nil
    db.classPacks.sliderOffsetY = nil
  end
  
  if AC.Vanity and AC.Vanity.EnsureMottoStrip then
    AC.Vanity:EnsureMottoStrip(parent)
  end

  -- Create the top button bar first (like TrinketsOther)
  local buttonBar = CreateFrame("Frame", nil, parent)
  if parent._mottoStrip then
    buttonBar:SetPoint("TOPLEFT", parent._mottoStrip, "BOTTOMLEFT", 2, -8)
    buttonBar:SetPoint("TOPRIGHT", parent._mottoStrip, "BOTTOMRIGHT", -2, -8)
  else
    buttonBar:SetPoint("TOPLEFT", 10, -52)
  end
  buttonBar:SetHeight(40)
  local sBorder = AC:CreateFlatTexture(buttonBar, "BACKGROUND", 1, AC.COLORS.BORDER_LIGHT, 0.6); sBorder:SetAllPoints()
  local sFill = AC:CreateFlatTexture(buttonBar, "BACKGROUND", 2, AC.COLORS.INPUT_DARK, 1); sFill:SetPoint("TOPLEFT", 1, -1); sFill:SetPoint("BOTTOMRIGHT", -1, 1)

  -- Class Packs Editor button
  local editorBtn = AC:CreateTexturedButton(buttonBar, 140, 32, "Class Packs Editor", "UI\\tab-purple-matte")
  editorBtn:SetPoint("LEFT", 6, 0)
  editorBtn:SetScript("OnClick", function()
    if AC.OpenClassPacksEditor then
      AC.OpenClassPacksEditor()
    else
      print("|cff8B45FFArenaCore:|r Class Pack Editor not found (UI_ClassPacksEditor.lua)")
    end
  end)

  -- REMOVED: TEST and HIDE buttons - replaced by new unified architecture

  -- ================== GENERAL SETTINGS ==================
  local groupGeneral = CreateFrame("Frame", nil, parent)
  groupGeneral:SetPoint("TOPLEFT", buttonBar, "BOTTOMLEFT", 18, -18)
  groupGeneral:SetPoint("TOPRIGHT", buttonBar, "BOTTOMRIGHT", -18, -18)
  groupGeneral:SetHeight(110) -- Increased height for dropdown
  AC:HairlineGroupBox(groupGeneral)
  AC:CreateStyledText(groupGeneral, "GENERAL SETTINGS", 13, AC.COLORS.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)

  CreateCheckboxSetting(groupGeneral, "Enable Class Packs (Tri-Badges)", -50, "classPacks.enabled")
  CreateDropdownSetting(groupGeneral, "Growth Direction", -80, "classPacks.growthDirection", {
    ["Vertical"] = "Vertical",
    ["Horizontal"] = "Horizontal"
  }, "Vertical")

  -- ================== LAYOUT & POSITIONING ==================
  local groupLayout = CreateFrame("Frame", nil, parent)
  groupLayout:SetPoint("TOP", groupGeneral, "BOTTOM", 0, -12)
  groupLayout:SetPoint("LEFT", groupGeneral, "LEFT", 0, 0)
  groupLayout:SetPoint("RIGHT", groupGeneral, "RIGHT", 0, 0)
  groupLayout:SetHeight(210) -- Increased height for Font Size slider
  AC:HairlineGroupBox(groupLayout)
  AC:CreateStyledText(groupLayout, "LAYOUT & POSITIONING", 13, AC.COLORS.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)

  -- Enhanced sliders with 1-10 scale
  AC:CreateEnhancedSliderRow(groupLayout, "Icon Size", -50, "classPacks.size", "tribadges_size")
  AC:CreateEnhancedSliderRow(groupLayout, "Spacing", -80, "classPacks.spacing", "spacing")
  AC:CreateEnhancedSliderRow(groupLayout, "Offset X", -110, "classPacks.offsetX", "offset")
  AC:CreateEnhancedSliderRow(groupLayout, "Offset Y", -140, "classPacks.offsetY", "offset")
  
  -- NEW FEATURE: Font Size slider for countdown timers (like trinkets)
  AC:CreateEnhancedSliderRow(groupLayout, "Font Size", -170, "classPacks.fontSize", "cooldown_font")
end

AC:RegisterPage("classpacks", CreateClassPacksPage)