-- ============================================================================
-- File: ArenaCore/Core/Pages/MoreGoodies.lua (v1.0)
-- Purpose: Settings page for More Goodies features including Absorbs.
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

local V = AC.Vanity
local DB_PATH = "moreGoodies" -- The key we'll create in Init.lua

-- Reset function limited to More Goodies settings only
function AC:ResetMoreGoodiesSettings()
  self.DB.profile = self.DB.profile or {}
  self.DB.profile[DB_PATH] = {
    absorbs = { enabled = false },
    partyClassSpecs = { mode = "off", scale = 100 },
  }
  if self.RefreshMoreGoodiesLayout then self:RefreshMoreGoodiesLayout() end
  if self.ShowPage then self:ShowPage("MoreGoodies") end
end

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
    
    -- Save to database
    local fullPath = DB_PATH .. "." .. subPath
    local keys = {}; for k in string.gmatch(fullPath, "([^%.]+)") do table.insert(keys, k) end
    local target = AC.DB.profile
    for i = 1, #keys - 1 do
      target[keys[i]] = target[keys[i]] or {}
      target = target[keys[i]]
    end
    target[keys[#keys]] = value
    
    -- Call callback if provided
    if callback then callback(value) end
    
    -- Tell the system to update
    if AC.RefreshMoreGoodiesLayout then
      AC:RefreshMoreGoodiesLayout()
    end
  end)
  
  dropdown:SetPoint("LEFT", l, "RIGHT", 10, 0)

  return row
end

-- Helper function to create a slider setting
local function CreateLinkedSlider(parent, label, y, subPath, min, max, val, isPct, compactDisplay)
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
  
  local fullPath = DB_PATH .. "." .. subPath
  local keys = {}; for k in string.gmatch(fullPath, "([^%.]+)") do table.insert(keys, k) end
  local valT = AC:CreateStyledText(row, "", 11, AC.COLORS.TEXT_2, "OVERLAY", ""); valT:SetWidth(35); valT:SetJustifyH("CENTER")

  local function OnChange(value)
    local target = AC.DB.profile
    for i = 1, #keys - 1 do
      target[keys[i]] = target[keys[i]] or {}
      target = target[keys[i]]
    end
    target[keys[#keys]] = value
    if isPct then 
      valT:SetText(string.format("%.0f%%", value))
    elseif compactDisplay then
      valT:SetText(string.format("%.0f", math.floor(value / 100)))
    else 
      valT:SetText(string.format("%.0f", value)) 
    end
    
    -- Tell the system to update
    if AC.RefreshMoreGoodiesLayout then
      AC:RefreshMoreGoodiesLayout()
    end
  end

  local slider = AC:CreateFlatSlider(row, 120, 18, min, max, val, isPct, OnChange)
  slider:SetPoint("LEFT", minT, "RIGHT", 10, 0)

  local maxT = AC:CreateStyledText(row, isPct and (displayMax .. "%") or tostring(displayMax), 9, AC.COLORS.TEXT_MUTED, "OVERLAY", ""); maxT:SetPoint("LEFT", slider, "RIGHT", 6, 0); maxT:SetWidth(25); maxT:SetJustifyH("LEFT")
  valT:SetPoint("RIGHT", row, "RIGHT", -10, 0)
  valT:SetPoint("LEFT", maxT, "RIGHT", 10, 0)
  
  -- Initialize the value display
  OnChange(val)

  return row
end

-- Helper function to create a checkbox setting
local function CreateLinkedCheckbox(parent, label, y, subPath, defaultVal, callback)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", 20, y); row:SetPoint("TOPRIGHT", -20, y); row:SetHeight(26)

  local l = AC:CreateStyledText(row, label, 12, AC.COLORS.TEXT_2, "OVERLAY", "")
  l:SetPoint("LEFT", 0, 0)
  l:SetWidth(200)
  l:SetJustifyH("LEFT")

  local fullPath = DB_PATH .. "." .. subPath
  local keys = {}
  for k in string.gmatch(fullPath, "([^%.]+)") do 
    table.insert(keys, k) 
  end

  local function OnChange(value)
    local target = AC.DB.profile
    for i = 1, #keys - 1 do
      target[keys[i]] = target[keys[i]] or {}
      target = target[keys[i]]
    end
    target[keys[#keys]] = value
    
    -- Call the callback if provided
    if callback then callback(value) end
    
    -- Tell the system to update
    if AC.RefreshMoreGoodiesLayout then
      AC:RefreshMoreGoodiesLayout()
    end
  end

  local checkbox = AC:CreateFlatCheckbox(row, 20, defaultVal, OnChange)
  checkbox:SetPoint("RIGHT", -25, 0)

  return row
end

-- Main page builder function
local function CreateMoreGoodiesPage(parent)
  -- Show Midnight restriction notice if applicable
  if AC.MidnightNotice and AC.MidnightNotice:ShouldShowNoticeForPage("MoreGoodies") then
    AC.MidnightNotice:ShowNotice(parent, "moregoodies")
  end
  
  -- CRITICAL: Ensure moreGoodies database exists for new users
  if not AC.DB then AC.DB = {} end
  if not AC.DB.profile then AC.DB.profile = {} end
  if not AC.DB.profile[DB_PATH] then
    -- Initialize with minimal defaults for new users
    AC.DB.profile[DB_PATH] = {
      absorbs = { enabled = true },
      partyClassSpecs = { mode = "all", scale = 178, showHealerIcon = true, hideHealthBars = false, showPointers = true },
      dispels = { enabled = true, size = 26, scale = 136, showCooldown = true, cooldownDuration = 8, showBackground = true },
      auras = { enabled = true, crowdControl = true, defensive = true, utility = true, hideTooltips = false },
      debuffs = { enabled = true, showTimer = true, timerFontSize = 10 }
    }
  end
  
  local db = AC.DB.profile[DB_PATH]
  if not db then
    local warn = AC:CreateStyledText(parent, "More Goodies database initialization failed.", 12, AC.COLORS.TEXT, "OVERLAY", "")
    warn:SetPoint("CENTER")
    return
  end

  if V and V.EnsureMottoStrip then V:EnsureMottoStrip(parent) end
  
  -- Create the top button bar first
  local buttonBar = CreateFrame("Frame", nil, parent)
  -- This anchors the new bar below the orange motto strip
  if parent._mottoStrip then
    buttonBar:SetPoint("TOPLEFT", parent._mottoStrip, "BOTTOMLEFT", 2, -8)
    buttonBar:SetPoint("TOPRIGHT", parent._mottoStrip, "BOTTOMRIGHT", -2, -8)
  else
    -- Fallback positioning if motto strip is missing
    buttonBar:SetPoint("TOPLEFT", 10, -52)
    buttonBar:SetPoint("TOPRIGHT", -10, -52)
  end
  buttonBar:SetHeight(40)

  local sBorder = AC:CreateFlatTexture(buttonBar, "BACKGROUND", 1, AC.COLORS.BORDER_LIGHT, 0.6)
  sBorder:SetAllPoints()
  local sFill = AC:CreateFlatTexture(buttonBar, "BACKGROUND", 2, AC.COLORS.INPUT_DARK, 1)
  sFill:SetPoint("TOPLEFT", 1, -1); sFill:SetPoint("BOTTOMRIGHT", -1, 1)

  -- Personal Mascot button (no function)
  local mascotBtn = AC:CreateTexturedButton(buttonBar, 140, 32, "Personal Mascot", "UI\\tab-purple-matte")
  mascotBtn:SetPoint("LEFT", 6, 0)
  -- No function assigned - button disabled
  
  -- Coming Soon notice
  AC:CreateComingSoonText(buttonBar, mascotBtn)

  -- REMOVED: TEST and HIDE buttons - replaced by new unified architecture

  -- Group 1: EXTRA BANGER FEATURES
  local groupFeatures = CreateFrame("Frame", nil, parent)
  groupFeatures:SetPoint("TOPLEFT", buttonBar, "BOTTOMLEFT", 18, -18)
  groupFeatures:SetPoint("TOPRIGHT", buttonBar, "BOTTOMRIGHT", -18, -18)
  groupFeatures:SetHeight(780)
  AC:HairlineGroupBox(groupFeatures)
  local titleFeatures = AC:CreateStyledText(groupFeatures, "EXTRA BANGER FEATURES", 13, AC.COLORS.PRIMARY, "OVERLAY", "")
  titleFeatures:SetPoint("TOPLEFT", 20, -18)

  -- CORE FEATURE BUTTONS (moved to top for visibility)
  local dispelsBtn = AC:CreateTexturedButton(groupFeatures, 80, 32, "Dispels", "UI\\tab-purple-matte")
  dispelsBtn:SetPoint("TOPLEFT", 20, -50)
  dispelsBtn:SetScript("OnClick", function()
    if AC.ShowDispelWindow then
      AC:ShowDispelWindow()
    end
  end)

  local aurasBtn = AC:CreateTexturedButton(groupFeatures, 80, 32, "Auras", "UI\\tab-purple-matte")
  aurasBtn:SetPoint("LEFT", dispelsBtn, "RIGHT", 10, 0)
  aurasBtn:SetScript("OnClick", function()
    if AC.ShowAurasWindow then
      AC:ShowAurasWindow()
    end
  end)

  local debuffsBtn = AC:CreateTexturedButton(groupFeatures, 80, 32, "Debuffs", "UI\\tab-purple-matte")
  debuffsBtn:SetPoint("LEFT", aurasBtn, "RIGHT", 10, 0)
  debuffsBtn:SetScript("OnClick", function()
    if AC.ShowDebuffsWindow then
      AC:ShowDebuffsWindow()
    end
  end)
  
  local kickBarBtn = AC:CreateTexturedButton(groupFeatures, 80, 32, "Kick Bar", "UI\\tab-purple-matte")
  kickBarBtn:SetPoint("LEFT", debuffsBtn, "RIGHT", 10, 0)
  kickBarBtn:SetScript("OnClick", function()
    if AC.OpenKickBarWindow then
      AC:OpenKickBarWindow()
    end
  end)

  -- Absorbs checkbox
  if not db.absorbs then db.absorbs = {} end
  local absorbsDb = db.absorbs or { enabled = false }
  CreateLinkedCheckbox(groupFeatures, "Absorbs", -95, "absorbs.enabled", absorbsDb.enabled, function(value)
    -- This callback will be called when the checkbox changes
    -- Absorb checkbox toggled
    -- Refresh absorbs immediately
    if AC.RefreshMoreGoodiesLayout then
      AC:RefreshMoreGoodiesLayout()
    end
  end)

  -- Add description text for absorbs
  local descText = AC:CreateStyledText(groupFeatures, "Shows absorb shields on enemy health bars (green for magic, white for physical). Absorbs will also pulse/glow when target has an immunity on (I.E. Cloak of Shadows, Blessing of Protection etc.)", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
  descText:SetPoint("TOPLEFT", 20, -123)
  descText:SetPoint("TOPRIGHT", -20, -78)
  descText:SetJustifyH("LEFT")
  descText:SetWordWrap(true)


  -- Party Class Specs dropdown
  local partyClassDb = db.partyClassSpecs or { mode = "off", scale = 100, useCustomIcons = true }
  local dropdownOptions = {
    { text = "Off", value = "off" },
    { text = "Party Members", value = "party" },
    { text = "All Players", value = "all" }
  }
  
  CreateLinkedDropdown(groupFeatures, "Party Class Icons", -165, "partyClassSpecs.mode", dropdownOptions, partyClassDb.mode or "off", function(value)
    if value == "off" then
      print("|cff8B45FFArena Core:|r Party class indicators disabled.")
    elseif value == "party" then
      print("|cff8B45FFArena Core:|r Party class indicators enabled for party members.")
    elseif value == "all" then
      print("|cff8B45FFArena Core:|r Party class indicators enabled for all players.")
    end
    
    -- FIXED: Multiple refreshes to ensure all nameplates update properly
    C_Timer.After(0.1, function()
      if AC.RefreshPartyClassIcons then
        AC:RefreshPartyClassIcons()
      end
    end)
    -- Additional delayed refresh to catch late-loading nameplates
    C_Timer.After(0.5, function()
      if AC.RefreshPartyClassIcons then
        AC:RefreshPartyClassIcons()
      end
    end)
  end)

  -- Add description text for party class specs
  local partyDescText = AC:CreateStyledText(groupFeatures, "Shows class icons above players' heads using custom class icons", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
  partyDescText:SetPoint("TOPLEFT", 20, -193)
  partyDescText:SetPoint("TOPRIGHT", -20, -148)
  partyDescText:SetJustifyH("LEFT")
  partyDescText:SetWordWrap(true)

  -- Use Custom Icons checkbox (under Party Class Icons)
  local useCustomLabel = AC:CreateStyledText(groupFeatures, "Use Arena Core Custom Icons", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
  useCustomLabel:SetPoint("TOPLEFT", 20, -218)
  
  local useCustomCheckbox = AC:CreateFlatCheckbox(groupFeatures, 20, partyClassDb.useCustomIcons == true, function(value)
    -- Save to database
    if not AC.DB.profile.moreGoodies then
      AC.DB.profile.moreGoodies = {}
    end
    if not AC.DB.profile.moreGoodies.partyClassSpecs then
      AC.DB.profile.moreGoodies.partyClassSpecs = {}
    end
    AC.DB.profile.moreGoodies.partyClassSpecs.useCustomIcons = value
    
    if AC.RefreshPartyClassIcons then
      AC:RefreshPartyClassIcons()
    end
    if value then
      print("|cff8B45FFArena Core:|r Party class icons now using ArenaCore custom icons")
    else
      print("|cff8B45FFArena Core:|r Party class icons now using theme icons (Midnight Chill/etc)")
    end
  end)
  useCustomCheckbox:SetPoint("TOPRIGHT", -25, -218)
  
  -- Description for use custom icons
  local useCustomDesc = AC:CreateStyledText(groupFeatures, "When checked, uses original ArenaCore custom icons. When unchecked, uses alternate theme icons (Midnight Chill, etc).", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
  useCustomDesc:SetPoint("TOPLEFT", 20, -243)
  useCustomDesc:SetPoint("TOPRIGHT", -20, -198)
  useCustomDesc:SetJustifyH("LEFT")
  useCustomDesc:SetWordWrap(true)

  -- Where's My Healer checkbox (moved below Party Class Icons)
  local healerLabel = AC:CreateStyledText(groupFeatures, "Where's My Healer?", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
  healerLabel:SetPoint("TOPLEFT", 20, -280)
  
  local healerCheckbox = AC:CreateFlatCheckbox(groupFeatures, 20, partyClassDb.showHealerIcon ~= false, function(value)
    -- Save to database directly
    if not AC.DB.profile.moreGoodies then
      AC.DB.profile.moreGoodies = {}
    end
    if not AC.DB.profile.moreGoodies.partyClassSpecs then
      AC.DB.profile.moreGoodies.partyClassSpecs = {}
    end
    AC.DB.profile.moreGoodies.partyClassSpecs.showHealerIcon = value
    
    if AC.RefreshPartyClassIcons then
      AC:RefreshPartyClassIcons()
    end
    if value then
      print("|cff8B45FFArena Core:|r Where's My Healer enabled - friendly team healers will show special icons!")
    else
      print("|cff8B45FFArena Core:|r Where's My Healer disabled - showing normal class icons")
    end
  end)
  healerCheckbox:SetPoint("TOPRIGHT", -25, -280)
  
  -- Add description text for healer option
  local healerDescText = AC:CreateStyledText(groupFeatures, "Shows a custom Arena Core healer icon ONLY for your team's healers (not enemies). If you ARE the healer, this feature does nothing to avoid confusion.", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
  healerDescText:SetPoint("TOPLEFT", 20, -305)
  healerDescText:SetPoint("TOPRIGHT", -20, -260)
  healerDescText:SetJustifyH("LEFT")
  healerDescText:SetWordWrap(true)

  -- Hide Friendly Health Bars checkbox (added spacing for clarity)
  local hideHealthLabel = AC:CreateStyledText(groupFeatures, "Hide Friendly Health Bars", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
  hideHealthLabel:SetPoint("TOPLEFT", 20, -350)
  
  local hideHealthCheckbox = AC:CreateFlatCheckbox(groupFeatures, 20, partyClassDb.hideHealthBars == true, function(value)
    -- Save to database
    if not AC.DB.profile.moreGoodies then
      AC.DB.profile.moreGoodies = {}
    end
    if not AC.DB.profile.moreGoodies.partyClassSpecs then
      AC.DB.profile.moreGoodies.partyClassSpecs = {}
    end
    AC.DB.profile.moreGoodies.partyClassSpecs.hideHealthBars = value
    
    if AC.RefreshPartyClassIcons then
      AC:RefreshPartyClassIcons()
    end
    if value then
      print("|cff8B45FFArena Core:|r Friendly health bars hidden - only class icons visible!")
    else
      print("|cff8B45FFArena Core:|r Friendly health bars restored")
    end
  end)
  hideHealthCheckbox:SetPoint("TOPRIGHT", -25, -350)
  
  -- Description for hide health bars
  local hideHealthDesc = AC:CreateStyledText(groupFeatures, "Hides friendly nameplate health bars while keeping class icons visible. Friendly nameplates must be enabled in WoW settings.", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
  hideHealthDesc:SetPoint("TOPLEFT", 20, -375)
  hideHealthDesc:SetPoint("TOPRIGHT", -20, -375)
  hideHealthDesc:SetJustifyH("LEFT")
  hideHealthDesc:SetWordWrap(true)

  -- Show Pointers checkbox (moved down to prevent overlap)
  local showPointersLabel = AC:CreateStyledText(groupFeatures, "Show Pointers", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
  showPointersLabel:SetPoint("TOPLEFT", 20, -420)
  
  local showPointersCheckbox = AC:CreateFlatCheckbox(groupFeatures, 20, partyClassDb.showPointers ~= false, function(value)
    -- Save to database
    if not AC.DB.profile.moreGoodies then
      AC.DB.profile.moreGoodies = {}
    end
    if not AC.DB.profile.moreGoodies.partyClassSpecs then
      AC.DB.profile.moreGoodies.partyClassSpecs = {}
    end
    AC.DB.profile.moreGoodies.partyClassSpecs.showPointers = value
    
    if AC.RefreshPartyClassIcons then
      AC:RefreshPartyClassIcons()
    end
    if value then
      print("|cff8B45FFArena Core:|r Pointers enabled - triangle arrows will show above players!")
    else
      print("|cff8B45FFArena Core:|r Pointers disabled")
    end
  end)
  showPointersCheckbox:SetPoint("TOPRIGHT", -25, -420)
  
  -- Description for show pointers
  local showPointersDesc = AC:CreateStyledText(groupFeatures, "Shows class color party pointers above players' heads using custom icons", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
  showPointersDesc:SetPoint("TOPLEFT", 20, -445)
  showPointersDesc:SetPoint("TOPRIGHT", -20, -445)
  showPointersDesc:SetJustifyH("LEFT")
  showPointersDesc:SetWordWrap(true)

  -- CLASS ICON SETTINGS HEADER (purple for visibility) - moved down
  local classIconTitle = AC:CreateStyledText(groupFeatures, "Class Icon Settings", 12, AC.COLORS.PRIMARY, "OVERLAY", "")
  classIconTitle:SetPoint("TOPLEFT", 20, -480)
  
  -- Enhanced slider with 1-10 scale (friendlier tooltip just for this page)
  AC:CreateEnhancedSliderRow(
    groupFeatures,
    "Scale",
    -505,
    "moreGoodies.partyClassSpecs.scale",
    "sizing_scale",
    { scaleMin = 1, scaleMax = 12, pixelMin = 50, pixelMax = 360, isPercent = true,
      tooltip = "Scales the party class icons and their visuals. 1 = smallest, 12 = extra large." }
  )

  -- Horizontal and Vertical fine-tune controls for class icons (direct pixel values, 0 = center)
  AC:CreateEnhancedSliderRow(
    groupFeatures,
    "Horizontal",
    -530,
    "moreGoodies.partyClassSpecs.offsetX",
    "direct_pixel_offset",
    { scaleMin = -100, scaleMax = 100, pixelMin = -100, pixelMax = 100, valueStep = 1,
      tooltip = "Horizontal offset in pixels. 0 = centered above player." }
  )
  AC:CreateEnhancedSliderRow(
    groupFeatures,
    "Vertical",
    -555,
    "moreGoodies.partyClassSpecs.offsetY",
    "direct_pixel_offset",
    { scaleMin = -100, scaleMax = 100, pixelMin = -100, pixelMax = 100, valueStep = 1,
      tooltip = "Vertical offset in pixels. 0 = default height above player." }
  )

  -- POINTER POSITIONING CONTROLS (triangle arrows for all players)
  local pointerTitle = AC:CreateStyledText(groupFeatures, "Pointer Settings", 12, AC.COLORS.PRIMARY, "OVERLAY", "")
  pointerTitle:SetPoint("TOPLEFT", 20, -590)
  
  -- Link Horizontal checkbox - when enabled, pointer horizontal follows class icon horizontal
  local linkHorizLabel = AC:CreateStyledText(groupFeatures, "Link Horizontal", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
  linkHorizLabel:SetPoint("TOPLEFT", 20, -612)
  
  -- Store reference for enabling/disabling pointer horizontal slider
  local pointerHorizSlider = nil
  
  local linkHorizCheckbox = AC:CreateFlatCheckbox(groupFeatures, 20, partyClassDb.linkHorizontal == true, function(value)
    if not AC.DB.profile.moreGoodies then AC.DB.profile.moreGoodies = {} end
    if not AC.DB.profile.moreGoodies.partyClassSpecs then AC.DB.profile.moreGoodies.partyClassSpecs = {} end
    AC.DB.profile.moreGoodies.partyClassSpecs.linkHorizontal = value
    
    -- Enable/disable pointer horizontal slider based on link state
    C_Timer.After(0.05, function()
      local ptrSlider = AC.sliderWidgets and AC.sliderWidgets["moreGoodies.partyClassSpecs.pointerOffsetX"]
      if ptrSlider then
        if value then
          -- Linked: Sync pointer value to class icon value and disable slider
          local classOffsetX = AC.DB.profile.moreGoodies.partyClassSpecs.offsetX or 0
          AC.DB.profile.moreGoodies.partyClassSpecs.pointerOffsetX = classOffsetX
          ptrSlider:SetValue(classOffsetX)
          ptrSlider:SetAlpha(0.4)
          ptrSlider:EnableMouse(false)
          -- Also disable +/- buttons and editbox if they exist
          if ptrSlider.minusBtn then ptrSlider.minusBtn:EnableMouse(false) end
          if ptrSlider.plusBtn then ptrSlider.plusBtn:EnableMouse(false) end
          if ptrSlider.editBox then ptrSlider.editBox:EnableMouse(false) end
        else
          -- Unlinked: Re-enable slider
          ptrSlider:SetAlpha(1.0)
          ptrSlider:EnableMouse(true)
          if ptrSlider.minusBtn then ptrSlider.minusBtn:EnableMouse(true) end
          if ptrSlider.plusBtn then ptrSlider.plusBtn:EnableMouse(true) end
          if ptrSlider.editBox then ptrSlider.editBox:EnableMouse(true) end
        end
      end
    end)
    
    -- Refresh pointers to apply new positioning
    if AC.RefreshPointersOnly then AC:RefreshPointersOnly() end
  end)
  linkHorizCheckbox:SetPoint("TOPRIGHT", -25, -612)
  
  local linkHorizDesc = AC:CreateStyledText(groupFeatures, "When ON, Class Icon Horizontal controls both. Pointer slider is disabled.", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
  linkHorizDesc:SetPoint("TOPLEFT", 20, -632)
  linkHorizDesc:SetPoint("TOPRIGHT", -20, -632)
  linkHorizDesc:SetJustifyH("LEFT")
  linkHorizDesc:SetWordWrap(true)
  
  AC:CreateEnhancedSliderRow(
    groupFeatures,
    "Pointer Scale",
    -665,
    "moreGoodies.partyClassSpecs.pointerScale",
    "sizing_scale",
    { scaleMin = 1, scaleMax = 12, pixelMin = 50, pixelMax = 360, isPercent = true,
      tooltip = "Scales the triangle pointer arrows. 1 = smallest, 12 = extra large." }
  )
  
  AC:CreateEnhancedSliderRow(
    groupFeatures,
    "Pointer Horizontal",
    -690,
    "moreGoodies.partyClassSpecs.pointerOffsetX",
    "direct_pixel_offset",
    { scaleMin = -100, scaleMax = 100, pixelMin = -100, pixelMax = 100, valueStep = 1,
      tooltip = "Horizontal offset in pixels. 0 = centered. (Ignored when Link Horizontal is on)" }
  )
  
  AC:CreateEnhancedSliderRow(
    groupFeatures,
    "Pointer Vertical",
    -715,
    "moreGoodies.partyClassSpecs.pointerOffsetY",
    "direct_pixel_offset",
    { scaleMin = -100, scaleMax = 100, pixelMin = -100, pixelMax = 100, valueStep = 1,
      tooltip = "Vertical offset in pixels. 0 = default height above class icon." }
  )

  -- Live update hooks so changes reflect immediately on nameplates
  -- CRITICAL: Use independent refresh functions to prevent cross-contamination/flickering
  C_Timer.After(0.1, function()
    if AC.sliderWidgets then
      -- Class icon scale/vertical sliders → only refresh class icons
      local hookClassIconOnly = function(sl)
        if sl and sl.HookScript then
          sl:HookScript("OnValueChanged", function()
            if AC.RefreshClassIconsOnly then AC:RefreshClassIconsOnly() end
          end)
        end
      end
      
      -- Class icon HORIZONTAL slider → refresh class icons AND sync pointer when linked
      local hookClassIconHorizontal = function(sl)
        if sl and sl.HookScript then
          sl:HookScript("OnValueChanged", function(self, value)
            if AC.RefreshClassIconsOnly then AC:RefreshClassIconsOnly() end
            
            -- If Link Horizontal is ON, sync pointer slider and refresh pointers
            local db = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.partyClassSpecs
            if db and db.linkHorizontal then
              -- Sync pointer offset value to class icon value
              db.pointerOffsetX = value
              -- Update pointer slider visual (if visible)
              local ptrSlider = AC.sliderWidgets["moreGoodies.partyClassSpecs.pointerOffsetX"]
              if ptrSlider and ptrSlider.SetValue then
                ptrSlider:SetValue(value)
              end
              -- Refresh pointers with new position
              if AC.RefreshPointersOnly then AC:RefreshPointersOnly() end
            end
          end)
        end
      end
      
      -- Pointer sliders → only refresh pointers
      local hookPointer = function(sl)
        if sl and sl.HookScript then
          sl:HookScript("OnValueChanged", function()
            if AC.RefreshPointersOnly then AC:RefreshPointersOnly() end
          end)
        end
      end
      
      -- Hook class icon sliders
      hookClassIconOnly(AC.sliderWidgets["moreGoodies.partyClassSpecs.scale"])    
      hookClassIconHorizontal(AC.sliderWidgets["moreGoodies.partyClassSpecs.offsetX"]) 
      hookClassIconOnly(AC.sliderWidgets["moreGoodies.partyClassSpecs.offsetY"])
      
      -- Hook pointer sliders to pointer-only refresh
      hookPointer(AC.sliderWidgets["moreGoodies.partyClassSpecs.pointerScale"])
      hookPointer(AC.sliderWidgets["moreGoodies.partyClassSpecs.pointerOffsetX"])
      hookPointer(AC.sliderWidgets["moreGoodies.partyClassSpecs.pointerOffsetY"])
      
      -- Apply initial link state (disable pointer horizontal if already linked)
      local db = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.partyClassSpecs
      if db and db.linkHorizontal then
        local ptrSlider = AC.sliderWidgets["moreGoodies.partyClassSpecs.pointerOffsetX"]
        if ptrSlider then
          ptrSlider:SetAlpha(0.4)
          ptrSlider:EnableMouse(false)
          if ptrSlider.minusBtn then ptrSlider.minusBtn:EnableMouse(false) end
          if ptrSlider.plusBtn then ptrSlider.plusBtn:EnableMouse(false) end
          if ptrSlider.editBox then ptrSlider.editBox:EnableMouse(false) end
        end
      end
    end
  end)
end

AC:RegisterPage("MoreGoodies", CreateMoreGoodiesPage)
