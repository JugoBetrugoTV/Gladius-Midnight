-- =============================================================================
-- Core/Pages/Frames.lua - Frames Configuration Page
-- =============================================================================
-- Party and Unit frame modifications configuration

local AddonName, _ns = ...
if type(_G.ArenaCore) ~= "table" then _G.ArenaCore = {} end
local AC = _G.ArenaCore



-- =============================================================================
-- PAGE CREATION FUNCTION
-- =============================================================================

function AC:CreateFramesPage(parent)
  -- Ensure database exists
  if not AC.DB or not AC.DB.profile then
    AC:EnsureDB()
  end
  
  -- Ensure arenaNameplates section exists (for databases created before this feature)
  if AC.DB.profile and not AC.DB.profile.arenaNameplates then
    AC.DB.profile.arenaNameplates = {
      enabled = true,
      mode = "both",
      useShortNames = false,
      useClassColors = false
    }
  end
  -- Ensure useClassColors exists for older databases
  if AC.DB.profile.arenaNameplates and AC.DB.profile.arenaNameplates.useClassColors == nil then
    AC.DB.profile.arenaNameplates.useClassColors = false
  end
  
  -- Ensure motto strip
  if AC.Vanity and AC.Vanity.EnsureMottoStrip then 
    AC.Vanity:EnsureMottoStrip(parent) 
  end
  
  -- Alert frame with icon and message (directly below motto bar)
  local alertFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  alertFrame:SetHeight(70)
  if parent._mottoStrip then
    alertFrame:SetPoint("TOPLEFT", parent._mottoStrip, "BOTTOMLEFT", 10, -10)
    alertFrame:SetPoint("TOPRIGHT", parent._mottoStrip, "BOTTOMRIGHT", -10, -10)
  else
    alertFrame:SetPoint("TOPLEFT", 10, -10)
    alertFrame:SetPoint("TOPRIGHT", -10, -10)
  end
  alertFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true, tileSize = 16, edgeSize = 1,
  })
  alertFrame:SetBackdropColor(0.3, 0.1, 0.1, 0.8)
  alertFrame:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)

  -- Alert icon (blue alert icon like Shade UI)
  local alertIcon = alertFrame:CreateTexture(nil, "OVERLAY")
  alertIcon:SetSize(40, 40)
  alertIcon:SetPoint("LEFT", 15, 0)
  alertIcon:SetAtlas("Crosshair_Important_128")
  alertIcon:SetVertexColor(0.4, 0.6, 1, 1)

  -- Alert text
  local alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  alertText:SetPoint("LEFT", alertIcon, "RIGHT", 12, 0)
  alertText:SetPoint("RIGHT", -15, 0)
  alertText:SetJustifyH("LEFT")
  alertText:SetWordWrap(true)
  alertText:SetText("More Features coming soon, working on experimenting things we can still do and ensure it is done properly.")
  alertText:SetTextColor(1, 1, 1, 1)
  alertText:SetFont(alertText:GetFont(), 13, "OUTLINE")

  -- Arena Nameplate Customization Section
  local nameplateGroup = CreateFrame("Frame", nil, parent)
  nameplateGroup:SetPoint("TOPLEFT", alertFrame, "BOTTOMLEFT", -10, -20)
  nameplateGroup:SetPoint("TOPRIGHT", alertFrame, "BOTTOMRIGHT", 10, -20)
  nameplateGroup:SetHeight(170)
  AC:HairlineGroupBox(nameplateGroup)

  local nameplateTitle = AC:CreateStyledText(nameplateGroup, "ARENA NAMEPLATE NAMES", 13, AC.COLORS.PRIMARY, "OVERLAY", "")
  nameplateTitle:SetPoint("TOPLEFT", 20, -18)

  -- Helper function to create dropdown (inline version from TrinketsOther.lua)
  local function CreateNameplateDropdown(parent, label, y, path, optionsMap, defaultValue)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 20, y)
    row:SetPoint("TOPRIGHT", -20, y)
    row:SetHeight(26)

    local l = AC:CreateStyledText(row, label, 11, AC.COLORS.TEXT, "OVERLAY", "")
    l:SetPoint("LEFT", 0, 0)
    l:SetWidth(120)
    l:SetJustifyH("LEFT")
    
    local keys = {}
    for k in string.gmatch(path, "([^%.]+)") do
      table.insert(keys, k)
    end
    
    local displayOptions = {}
    local displayToValue = {}
    local valueToDisplay = {}
    
    for displayText, internalValue in pairs(optionsMap) do
      table.insert(displayOptions, displayText)
      displayToValue[displayText] = internalValue
      valueToDisplay[internalValue] = displayText
    end

    local function GetValue()
      local target = AC.DB.profile
      for i = 1, #keys do
        target = target and target[keys[i]]
      end
      local currentValue = target or defaultValue
      return valueToDisplay[currentValue] or displayOptions[1]
    end
    
    local function OnChange(displayText)
      local internalValue = displayToValue[displayText]
      local target = AC.DB.profile
      for i = 1, #keys - 1 do
        target[keys[i]] = target[keys[i]] or {}
        target = target[keys[i]]
      end
      target[keys[#keys]] = internalValue
      
      if AC.RefreshArenaNameplates then
        AC:RefreshArenaNameplates()
      end
    end

    local dropdown = AC:CreateFlatDropdown(row, 200, 26, displayOptions, GetValue(), OnChange)
    dropdown:SetPoint("LEFT", l, "RIGHT", 10, 0)
    
    return dropdown
  end

  -- Display Mode Dropdown
  CreateNameplateDropdown(nameplateGroup, "Display Mode:", -50, "arenaNameplates.mode", {
    ["Player Name (Default)"] = "default",
    ["Arena Number (1/2/3)"] = "arena",
    ["Spec Name"] = "spec",
    ["Spec + Arena Number"] = "both"
  }, "both")

  -- Helper function to create clean checkbox (matches Textures page)
  local function CreateCleanCheckbox(parent, label, y, dbPath, onToggle)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 20, y)
    row:SetPoint("TOPRIGHT", -20, y)
    row:SetHeight(26)

    -- Get current value from database
    local keys = {}
    for k in string.gmatch(dbPath, "([^%.]+)") do
      table.insert(keys, k)
    end

    local currentValue = AC.DB.profile
    for _, key in ipairs(keys) do
      currentValue = currentValue and currentValue[key]
    end
    currentValue = currentValue or false

    local function OnChange(value)
      -- Save to database
      local target = AC.DB.profile
      for i = 1, #keys - 1 do
        target[keys[i]] = target[keys[i]] or {}
        target = target[keys[i]]
      end
      target[keys[#keys]] = value
      
      -- Call custom toggle function
      if onToggle then pcall(onToggle, value) end
    end

    local checkbox = AC:CreateFlatCheckbox(row, 20, currentValue, OnChange)
    checkbox:SetPoint("LEFT", 0, 0)

    local labelText = AC:CreateStyledText(row, label, 11, AC.COLORS.TEXT, "OVERLAY", "")
    labelText:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)

    return row
  end

  -- Enable/Disable Checkbox
  CreateCleanCheckbox(nameplateGroup, "Enable Arena Nameplate Customization", -80, "arenaNameplates.enabled", function(enabled)
    if AC.RefreshArenaNameplates then
      AC:RefreshArenaNameplates()
    end
  end)

  -- Short Names Checkbox
  CreateCleanCheckbox(nameplateGroup, "Use Short Spec Names (Aff, Ret, Sub)", -110, "arenaNameplates.useShortNames", function(enabled)
    if AC.RefreshArenaNameplates then
      AC:RefreshArenaNameplates()
    end
  end)

  -- Class Colors Checkbox
  CreateCleanCheckbox(nameplateGroup, "Use Class Colors", -140, "arenaNameplates.useClassColors", function(enabled)
    if AC.RefreshArenaNameplates then
      AC:RefreshArenaNameplates()
    end
  end)

  return parent
end

-- Register the page with the AC system
AC:RegisterPage("frames", function(parent)
  return AC:CreateFramesPage(parent)
end)
