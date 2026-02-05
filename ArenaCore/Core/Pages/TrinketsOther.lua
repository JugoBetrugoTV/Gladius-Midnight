-- File: ArenaCore/Core/Pages/TrinketsOther.lua
local addonName, _ns = ...
local addon = _G.ArenaCore
if not addon then return end

local V = addon.Vanity
local C = addon.COLORS

-- Helper function to get the database profile
local function DB()
  return (addon.DB and addon.DB.profile) or {}
end
-- File: TrinketsOther.lua
-- Purpose: Corrected reset function that includes the 'enabled' state.

-- Store slider references for direct updates
local sliderWidgets = {}

local function ResetTrinketSettings()
  local db = DB()
  if not db then return end

  -- Use ACTUAL defaults from Init.lua instead of hardcoded values
  if addon.DEFAULTS then
    -- Deep copy function to avoid reference issues
    local function DeepCopy(tbl)
      if type(tbl) ~= "table" then return tbl end
      local out = {}
      for k, v in pairs(tbl) do out[k] = DeepCopy(v) end
      return out
    end
    
    -- Reset to actual defaults (your current coordinates)
    if addon.DEFAULTS.trinkets then
      db.trinkets = DeepCopy(addon.DEFAULTS.trinkets)
      print("|cffFFAA00Debug:|r Reset trinkets to horizontal=" .. db.trinkets.positioning.horizontal .. ", vertical=" .. db.trinkets.positioning.vertical)
    end
    if addon.DEFAULTS.specIcons then
      db.specIcons = DeepCopy(addon.DEFAULTS.specIcons)
      print("|cffFFAA00Debug:|r Reset specIcons to horizontal=" .. db.specIcons.positioning.horizontal .. ", vertical=" .. db.specIcons.positioning.vertical)
    end
    if addon.DEFAULTS.racials then
      db.racials = DeepCopy(addon.DEFAULTS.racials)
      print("|cffFFAA00Debug:|r Reset racials to horizontal=" .. db.racials.positioning.horizontal .. ", vertical=" .. db.racials.positioning.vertical)
    end
  end

  -- Force a refresh of the ARENA FRAMES to update their layout
  if addon.RefreshTrinketsOtherLayout then
    addon:RefreshTrinketsOtherLayout()
  end
  
  -- Spec icons are now handled by main Arena Frames - no separate logic needed

  -- CRITICAL FIX: Directly update slider widgets using WoW API SetValue()
  print("|cff8B45FFArenaCore:|r Resetting sliders directly using SetValue()...")
  
  -- Update each slider widget directly
  for path, slider in pairs(sliderWidgets) do
    if slider and slider.SetValue then
      local value = addon.Settings:Get(path)
      if value then
        slider:SetValue(value)
        print("|cffFFAA00Debug:|r Set slider " .. path .. " to value " .. tostring(value))
      end
    end
  end
  
  print("|cff8B45FFArenaCore:|r Trinkets/Other reset complete!")
end
-- File: Core/Pages/TrinketsOther.lua
-- Purpose: Correctly define the two helper functions in the proper scope.

-- Helper function to create a standardized slider row for this page
local function CreateSliderSetting(parent, label, y, path, min, max, isPct, compactDisplay)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", 20, y); row:SetPoint("TOPRIGHT", -20, y); row:SetHeight(26)

  local displayMin = min
  local displayMax = max
  if compactDisplay then
    displayMin = math.floor(min / 100)
    displayMax = math.floor(max / 100)
  end

  local l = addon:CreateStyledText(row, label, 11, C.TEXT_2, "OVERLAY", ""); l:SetPoint("LEFT", 0, 0); l:SetWidth(70); l:SetJustifyH("LEFT")
  local minT = addon:CreateStyledText(row, isPct and (displayMin .. "%") or tostring(displayMin), 9, C.TEXT_MUTED, "OVERLAY", ""); minT:SetPoint("LEFT", l, "RIGHT", 6, 0); minT:SetWidth(25); minT:SetJustifyH("RIGHT")
  
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
  
  local val = GetValue() or (isPct and 100 or 0)
  local valT = addon:CreateStyledText(row, "", 11, C.TEXT_2, "OVERLAY", ""); valT:SetWidth(70); valT:SetJustifyH("CENTER")

  local function OnChange(value)
    -- DEBUG: Show what's being changed
    print("|cff00FFFF[SLIDER CHANGE]|r path=" .. path .. ", newValue=" .. tostring(value))
    
    -- Save to global database
    local target = addon.DB.profile; for i=1, #keys - 1 do target[keys[i]] = target[keys[i]] or {}; target = target[keys[i]] end
    local oldValue = target[keys[#keys]]
    target[keys[#keys]] = value
    
    print("|cff00FFFF[SLIDER CHANGE]|r   Global DB: " .. tostring(oldValue) .. " → " .. tostring(value))
    
    -- CRITICAL FIX: Also save to theme-specific location for theme switching
    local currentTheme = addon.ArenaFrameThemes and addon.ArenaFrameThemes:GetCurrentTheme()
    if currentTheme and addon.DB.profile.themeData and addon.DB.profile.themeData[currentTheme] then
      local themeTarget = addon.DB.profile.themeData[currentTheme]
      for i=1, #keys - 1 do 
        themeTarget[keys[i]] = themeTarget[keys[i]] or {}
        themeTarget = themeTarget[keys[i]]
      end
      local oldThemeValue = themeTarget[keys[#keys]]
      themeTarget[keys[#keys]] = value
      print("|cff00FFFF[SLIDER CHANGE]|r   Theme DB: " .. tostring(oldThemeValue) .. " → " .. tostring(value))
    end
    
    if isPct then 
      valT:SetText(string.format("%.1f%%", value))  -- Show 1 decimal for percentages
    elseif compactDisplay then
      valT:SetText(string.format("%.0f", math.floor(value / 100)))
    else 
      valT:SetText(string.format("%.1f", value))  -- CRITICAL FIX: Show 1 decimal to display exact position (202.4 instead of 202)
    end
    
    if addon.RefreshTrinketsOtherLayout then
      addon:RefreshTrinketsOtherLayout()
    end
  end

  local slider = addon:CreateFlatSlider(row, 120, 18, min, max, val, isPct, OnChange)
  slider:SetPoint("LEFT", downBtn, "RIGHT", 4, 0)
  
  -- CRITICAL FIX: Store slider reference for direct updates during reset
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

  local maxT = addon:CreateStyledText(row, isPct and (displayMax .. "%") or tostring(displayMax), 9, C.TEXT_MUTED, "OVERLAY", ""); maxT:SetPoint("LEFT", upBtn, "RIGHT", 6, 0); maxT:SetWidth(20); maxT:SetJustifyH("LEFT")
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

-- Helper function to create a dropdown setting
local function CreateDropdownSetting(parent, label, y, path, optionsMap, defaultValue, dropdownWidth, menuWidth)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", 20, y); row:SetPoint("TOPRIGHT", -20, y); row:SetHeight(26)

  -- Use custom width or default to 180 for button
  dropdownWidth = dropdownWidth or 180
  -- Menu width can be different (wider) than button width
  menuWidth = menuWidth or dropdownWidth

  local l = addon:CreateStyledText(row, label, 12, C.TEXT_2, "OVERLAY", ""); l:SetPoint("LEFT", 0, 0); l:SetWidth(120); l:SetJustifyH("LEFT")
  
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
    
    -- Detect what setting is being changed for appropriate messaging and refresh
    local isClassIconTheme = path:find("classIcons%.theme")
    local isTrinketDesign = path:find("trinkets%.iconDesign")
    
    -- User-friendly confirmation message with display text
    if isClassIconTheme then
      print("|cff8B45FF[CLASS ICON THEME]|r Class Icon Theme changed to: " .. displayText)
    elseif isTrinketDesign then
      print("|cff8B45FF[TRINKET CHANGE]|r Trinket Design changed to: " .. displayText)
    end
    
    -- Use the same saving mechanism as sliders
    if addon.ProfileManager and addon.ProfileManager.SetSetting then
      addon.ProfileManager:SetSetting(path, internalValue)
    end
    if addon.FrameSystem and addon.FrameSystem.SetSetting then
      addon.FrameSystem:SetSetting(path, internalValue)
    end
    if addon.Settings and addon.Settings.Set then
      addon.Settings:Set(path, internalValue)
    end
    
    -- Fallback direct setting (same as before)
    local target = addon.DB.profile; for i=1, #keys - 1 do target[keys[i]] = target[keys[i]] or {}; target = target[keys[i]] end
    target[keys[#keys]] = internalValue
    
    -- Refresh appropriate system based on what changed
    if isClassIconTheme then
      -- Refresh class icons for all arena frames
      if addon.RefreshClassIcons then
        addon:RefreshClassIcons()
      elseif addon.RefreshTrinketsOtherLayout then
        addon:RefreshTrinketsOtherLayout()
      end
      
      -- CRITICAL: Also refresh Class Portrait Swap system to respect new theme
      if addon.ClassPortraitSwap and addon.ClassPortraitSwap.RefreshAll then
        C_Timer.After(0.1, function()
          addon.ClassPortraitSwap:RefreshAll()
        end)
      end
    elseif isTrinketDesign then
      -- CRITICAL FIX: Only refresh trinket icons, don't call full layout refresh
      -- Full refresh can trigger checkbox re-creation which toggles enabled state
      if addon.RefreshTrinketIcons then
        addon:RefreshTrinketIcons()
      elseif addon.RefreshTrinketsOtherLayout then
        addon:RefreshTrinketsOtherLayout()
      end
    end
  end

  -- Create dropdown with custom menu width support
  local dropdown = addon:CreateFlatDropdown(row, dropdownWidth, 24, displayOptions, GetValue(), OnChange)
  dropdown:SetPoint("LEFT", l, "RIGHT", 10, 0)
  
  -- CUSTOM: If menuWidth is different from dropdownWidth, adjust the menu
  if menuWidth ~= dropdownWidth and dropdown.menu then
    dropdown.menu:SetWidth(menuWidth)
    if dropdown.menu.scrollChild then
      dropdown.menu.scrollChild:SetWidth(menuWidth - 4)
    end
  end
  
  return row
end

-- A new helper function to create linked checkboxes.
local function CreateCheckboxSetting(parent, label, y, path)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", 20, y); row:SetPoint("TOPRIGHT", -20, y); row:SetHeight(26)

  local l = addon:CreateStyledText(row, label, 12, C.TEXT_2, "OVERLAY", ""); l:SetPoint("LEFT", 0, 0)
  
  local keys = {}; for k in string.gmatch(path, "([^%.]+)") do table.insert(keys, k) end

  local function GetValue()
    local target = DB(); for i=1, #keys do target = target and target[keys[i]] end
    return target
  end
  
  local isChecked = GetValue()
  if isChecked == nil then isChecked = true end -- Default to true if not set

  local function OnChange(value)
    local target = addon.DB.profile; for i=1, #keys - 1 do target[keys[i]] = target[keys[i]] or {}; target = target[keys[i]] end
    target[keys[#keys]] = value
    
    print("|cffFFAA00[CHECKBOX DEBUG]|r " .. path .. " changed to: " .. tostring(value))
    
    if addon.RefreshTrinketsOtherLayout then
      addon:RefreshTrinketsOtherLayout()
      print("|cffFFAA00[CHECKBOX DEBUG]|r Called RefreshTrinketsOtherLayout()")
    else
      print("|cffFF0000[CHECKBOX ERROR]|r RefreshTrinketsOtherLayout not found!")
    end
  end

  local box = addon:CreateFlatCheckbox(row, 20, isChecked, OnChange)
  box:SetPoint("RIGHT", -25, 0)
  
  return row
end

-- Main page creation
-- File: Core/Pages/TrinketsOther.lua
-- Purpose: Final, stable version using the same self-contained logic as the working Arena Frames page.

-- File: Core/Pages/TrinketsOther.lua
-- Purpose: Final version rebuilt with the correct, stable architecture from CastBars.lua.

-- File: Core/Pages/TrinketsOther.lua
-- Purpose: Final version with a simplified structure to fix the "double box" visual bug.

-- File: Core/Pages/TrinketsOther.lua
-- Purpose: Final, stable version using the proven architecture from other working pages.

addon:RegisterPage("trinketsother", function(root)
  if V and V.EnsureMottoStrip then V:EnsureMottoStrip(root) end
  
  -- Create the top button bar first
  local buttonBar = CreateFrame("Frame", nil, root)
  if root._mottoStrip then
    buttonBar:SetPoint("TOPLEFT", root._mottoStrip, "BOTTOMLEFT", 2, -8)
    buttonBar:SetPoint("TOPRIGHT", root._mottoStrip, "BOTTOMRIGHT", -2, -8)
  else
    buttonBar:SetPoint("TOPLEFT", 10, -52)
  end
  buttonBar:SetHeight(40)
  local sBorder = addon:CreateFlatTexture(buttonBar, "BACKGROUND", 1, C.BORDER_LIGHT, 0.6); sBorder:SetAllPoints()
  local sFill = addon:CreateFlatTexture(buttonBar, "BACKGROUND", 2, C.INPUT_DARK, 1); sFill:SetPoint("TOPLEFT", 1, -1); sFill:SetPoint("BOTTOMRIGHT", -1, 1)
  local mascotBtn = addon:CreateTexturedButton(buttonBar, 140, 32, "Personal Mascot", "UI\\tab-purple-matte")
  mascotBtn:SetPoint("LEFT", 6, 0)
  -- No function assigned - button disabled
  
  -- Coming Soon notice
  addon:CreateComingSoonText(buttonBar, mascotBtn)
  -- REMOVED: TEST and HIDE buttons - replaced by new unified architecture
  -- ================== TRINKETS & OTHER ==================
  local groupTrinkets = CreateFrame("Frame", nil, root)
  groupTrinkets:SetPoint("TOPLEFT", buttonBar, "BOTTOMLEFT", 18, -18)
  groupTrinkets:SetPoint("TOPRIGHT", buttonBar, "BOTTOMRIGHT", -18, -18)
  groupTrinkets:SetHeight(250)
  addon:HairlineGroupBox(groupTrinkets)
  addon:CreateStyledText(groupTrinkets, "TRINKETS", 13, C.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)
  -- Enhanced sliders with ultra-fine precision for pixel-perfect positioning
  CreateDropdownSetting(groupTrinkets, "Trinket Icon Design", -50, "trinkets.iconDesign", {
    ["Retail Medallion"] = "retail",
    ["Horde Vanilla"] = "horde", 
    ["Alliance Vanilla"] = "alliance"
  }, "retail")
  addon:CreateEnhancedSliderRow(groupTrinkets, "Horizontal", -80, "trinkets.positioning.horizontal", "positioning_horizontal_ultra")
  addon:CreateEnhancedSliderRow(groupTrinkets, "Vertical", -110, "trinkets.positioning.vertical", "positioning_vertical_ultra")
  addon:CreateEnhancedSliderRow(groupTrinkets, "Scale", -140, "trinkets.sizing.scale", "sizing_scale")
  addon:CreateEnhancedSliderRow(groupTrinkets, "Font Size", -170, "trinkets.sizing.fontSize", "cooldown_font")
  CreateCheckboxSetting(groupTrinkets, "Enable", -200, "trinkets.enabled")

  -- ================== SPEC ICONS ==================
  local groupSpecIcons = CreateFrame("Frame", nil, root)
  groupSpecIcons:SetPoint("TOP", groupTrinkets, "BOTTOM", 0, -12)
  groupSpecIcons:SetPoint("LEFT", groupTrinkets, "LEFT", 0, 0); groupSpecIcons:SetPoint("RIGHT", groupTrinkets, "RIGHT", 0, 0);
  groupSpecIcons:SetHeight(190)
  addon:HairlineGroupBox(groupSpecIcons)
  addon:CreateStyledText(groupSpecIcons, "SPEC ICONS", 13, C.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)
  -- Enhanced sliders with ultra-fine precision for pixel-perfect positioning
  addon:CreateEnhancedSliderRow(groupSpecIcons, "Horizontal", -50, "specIcons.positioning.horizontal", "positioning_horizontal_ultra")
  addon:CreateEnhancedSliderRow(groupSpecIcons, "Vertical", -80, "specIcons.positioning.vertical", "positioning_vertical_ultra")
  addon:CreateEnhancedSliderRow(groupSpecIcons, "Scale", -110, "specIcons.sizing.scale", "sizing_scale")
  CreateCheckboxSetting(groupSpecIcons, "Enable", -140, "specIcons.enabled")

  -- ================== RACIALS ==================
  local groupRacials = CreateFrame("Frame", nil, root)
  groupRacials:SetPoint("TOP", groupSpecIcons, "BOTTOM", 0, -12)
  groupRacials:SetPoint("LEFT", groupTrinkets, "LEFT", 0, 0); groupRacials:SetPoint("RIGHT", groupTrinkets, "RIGHT", 0, 0);
  groupRacials:SetHeight(220)
  addon:HairlineGroupBox(groupRacials)
  addon:CreateStyledText(groupRacials, "RACIALS", 13, C.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)
  -- Enhanced sliders with ultra-fine precision for pixel-perfect positioning
  addon:CreateEnhancedSliderRow(groupRacials, "Horizontal", -50, "racials.positioning.horizontal", "positioning_horizontal_ultra")
  addon:CreateEnhancedSliderRow(groupRacials, "Vertical", -80, "racials.positioning.vertical", "positioning_vertical_ultra")
  addon:CreateEnhancedSliderRow(groupRacials, "Scale", -110, "racials.sizing.scale", "sizing_scale")
  addon:CreateEnhancedSliderRow(groupRacials, "Font Size", -140, "racials.sizing.fontSize", "racial_font")
  CreateCheckboxSetting(groupRacials, "Enable", -170, "racials.enabled")

  -- ================== CLASS ICONS ==================
  local groupClassIcons = CreateFrame("Frame", nil, root)
  groupClassIcons:SetPoint("TOP", groupRacials, "BOTTOM", 0, -12)
  groupClassIcons:SetPoint("LEFT", groupTrinkets, "LEFT", 0, 0); groupClassIcons:SetPoint("RIGHT", groupTrinkets, "RIGHT", 0, 0);
  groupClassIcons:SetHeight(250)  -- Dropdown + sliders + border thickness
  addon:HairlineGroupBox(groupClassIcons)
  addon:CreateStyledText(groupClassIcons, "CLASS ICONS", 13, C.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)
  CreateCheckboxSetting(groupClassIcons, "Enable", -50, "classIcons.enabled")
  CreateDropdownSetting(groupClassIcons, "Class Icon Theme", -80, "classIcons.theme", {
    ["ArenaCore Custom"] = "arenacore",
    ["Midnight Chill"] = "coldclasses"
  }, "arenacore", 200, 300)  -- Button: 200px, Menu: 300px (wider menu shows full text)
  -- Enhanced sliders with ultra-fine precision for pixel-perfect positioning
  addon:CreateEnhancedSliderRow(groupClassIcons, "Horizontal", -110, "classIcons.positioning.horizontal", "positioning_horizontal_ultra")
  addon:CreateEnhancedSliderRow(groupClassIcons, "Vertical", -140, "classIcons.positioning.vertical", "positioning_vertical_ultra")
  addon:CreateEnhancedSliderRow(groupClassIcons, "Scale", -170, "classIcons.sizing.scale", "sizing_scale")
  addon:CreateEnhancedSliderRow(groupClassIcons, "Border Thickness", -200, "classIcons.sizing.borderThickness", "border_thickness")
end)