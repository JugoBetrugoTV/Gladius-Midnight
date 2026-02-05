-- =============================================================================
-- Core/UI.lua - v7.0 FIX
--  * FIX: Corrected "stuck hover" state on sidebar navigation buttons.
--  * REFACTOR: ArenaCore UI system
-- =============================================================================

local AddonName, _ns = ...
if type(_G.ArenaCore) ~= "table" then _G.ArenaCore = {} end
local AC = _G.ArenaCore

-- ====== CONDITIONAL LAYOUT SYSTEM ======
-- Returns layout configuration based on active theme
-- Now uses modular theme system from Core/Themes/
local function GetLayoutConfig()
    local activeTheme = AC.ThemeManager and AC.ThemeManager:GetActiveTheme() or "default"
    
    -- Get theme module
    if AC.Themes and AC.Themes[activeTheme] and AC.Themes[activeTheme].layout then
        return AC.Themes[activeTheme].layout
    end
    
    -- Fallback to default if theme not found
    if AC.Themes and AC.Themes.default and AC.Themes.default.layout then
        return AC.Themes.default.layout
    end
    
    -- Ultimate fallback (should never happen)
    print("|cffFF0000ArenaCore:|r Theme system error - using hardcoded fallback")
    return {
        UI_WIDTH = 720,
        UI_HEIGHT = 580,
        HEADER_HEIGHT = 70,
        SIDEBAR_WIDTH = 240,
        CONTENT_WIDTH = 450,
        PADDING = 8,
        SIDEBAR_TOP_OFFSET = -78,
        CONTENT_TOP_OFFSET = -78,
        VANITY_FOOTER_HEIGHT = 28,
    }
end

-- ====== CONSTANTS (Will be updated dynamically) ======
local UI_WIDTH            = 720
local UI_HEIGHT           = 580
local HEADER_HEIGHT       = 70
local SIDEBAR_WIDTH       = 240
local PADDING             = 8

local COLORS = {
  PRIMARY      = {0.545, 0.271, 1.000, 1}, -- #8B45FF purple accent
  TEXT         = {1.000, 1.000, 1.000, 1},
  TEXT_2       = {0.706, 0.706, 0.706, 1}, -- #B4B4B4
  TEXT_MUTED   = {0.502, 0.502, 0.502, 1}, -- #808080
  DANGER       = {0.863, 0.176, 0.176, 1}, -- #DC2D2D
  SUCCESS      = {0.133, 0.667, 0.267, 1}, -- #22AA44
  WARNING      = {0.800, 0.533, 0.000, 1}, -- #CC8800
  BG           = {0.200, 0.200, 0.200, 1}, -- #333333 - Content area background (LIGHTER)
  HEADER_BG    = {0.102, 0.102, 0.102, 1}, -- #1A1A1A - Dark for header (matches slider track)
  INPUT_DARK   = {0.102, 0.102, 0.102, 1}, -- #1A1A1A - Dark for input fields and boxes (matches slider track)
  GROUP_BG     = {0.102, 0.102, 0.102, 1}, -- #1A1A1A - Dark for settings groups (matches slider track)
  BORDER       = {0.196, 0.196, 0.196, 1}, -- #323232
  BORDER_LIGHT = {0.278, 0.278, 0.278, 1}, -- #474747
  ICON_BG      = {0.220, 0.220, 0.220, 1}, -- #383838
  NAV_ACTIVE_BG   = {0.20, 0.20, 0.20, 1},
  NAV_INACTIVE_BG = {0.12, 0.12, 0.12, 1},
  INSET        = {0.031, 0.031, 0.031, 1}, -- #080808
}

-- CRITICAL FIX: Expose COLORS globally for all modules to access
AC.COLORS = COLORS

-- CRITICAL FIX: Use FORWARD slashes (WoW prefers these!)
local CUSTOM_FONT = "Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf"

-- ====== ESSENTIAL UI FUNCTIONS ======
function AC:CreateFlatTexture(parent, layer, sublevel, color, alpha)
  if not parent then return nil end
  
  local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
  if sublevel then texture:SetDrawLayer(layer or "BACKGROUND", sublevel) end
  
  if color then
    if type(color) == "table" and #color >= 3 then
      texture:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
    else
      texture:SetTexture(color)
      if alpha then texture:SetAlpha(alpha) end
    end
  else
    texture:SetColorTexture(1, 1, 1, alpha or 1)
  end
  
  return texture
end

function AC:CreateStyledText(parent, text, size, color, layer, font)
  if not parent then return nil end
  
  local fontString = parent:CreateFontString(nil, layer or "OVERLAY")
  
  -- CRITICAL FIX: Always set font BEFORE setting text to avoid "Font not set" error
  local fontPath = "Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf"
  local fontSize = size or 12
  local fontFlags = ""
  
  -- Try custom font first
  local worked = pcall(function() fontString:SetFont(fontPath, fontSize, fontFlags) end)
  
  -- If that failed, use WoW default font (single backslash is correct)
  if not worked then
    pcall(function() fontString:SetFont("Fonts\\FRIZQT__.TTF", fontSize, fontFlags) end)
  end
  
  -- Now safe to set text
  fontString:SetText(text or "")
  
  if color and type(color) == "table" and #color >= 3 then
    fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
  else
    fontString:SetTextColor(1, 1, 1, 1)
  end
  
  return fontString
end

-- ====== SHADE UI STYLE FUNCTIONS ======
-- These functions create frames with Shade UI's exact visual style

function AC:CreateShadeFrame(parent, width, height, bgColor, borderColor)
  -- Creates a frame with BackdropTemplate (Shade UI style)
  if not parent then return nil end
  
  local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  if width and height then
    frame:SetSize(width, height)
  end
  
  -- Shade UI backdrop settings (exact from Shade UI code)
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 1,
    insets = { left=1, right=1, top=1, bottom=1 }
  })
  
  -- Set colors
  if bgColor and type(bgColor) == "table" then
    frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
  end
  
  if borderColor and type(borderColor) == "table" then
    frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
  end
  
  return frame
end

function AC:ApplyShadeGradient(frame, orientation, startColor, endColor)
  -- Applies a gradient overlay (Shade UI style)
  if not frame then return nil end
  
  local gradient = frame:CreateTexture(nil, "BACKGROUND")
  -- CRITICAL FIX: Use explicit anchors instead of SetAllPoints to respect frame bounds
  gradient:SetPoint("TOPLEFT", 0, 0)
  gradient:SetPoint("BOTTOMRIGHT", 0, 0)
  gradient:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
  
  local startR, startG, startB, startA = startColor[1], startColor[2], startColor[3], startColor[4] or 1
  local endR, endG, endB, endA = endColor[1], endColor[2], endColor[3], endColor[4] or 1
  
  gradient:SetGradient(
    orientation or "VERTICAL",
    CreateColor(startR, startG, startB, startA),
    CreateColor(endR, endG, endB, endA)
  )
  
  return gradient
end

function AC:CreateShadeButton(parent, width, height, text, fontSize)
  -- Creates a button with Shade UI styling (no outlines, just background changes)
  if not parent then return nil end
  
  local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  btn:SetSize(width or 160, height or 35)
  
  -- Shade UI button backdrop (simpler than frames - no border)
  btn:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    tileSize = 16
  })
  
  -- Normal state color
  btn:SetBackdropColor(0.1, 0.1, 0.1, 0.9) -- BUTTON_NORMAL
  
  -- Store colors for state changes
  btn.__shadeColors = {
    normal = {0.1, 0.1, 0.1, 0.9},
    hover = {0.15, 0.15, 0.15, 0.95},
    active = {0.2, 0.1, 0.25, 0.9}  -- Purple tint
  }
  
  return btn
end

function AC:CreateShadeCloseButton(parent)
  -- Creates a Shade UI styled close button (dark with × text)
  if not parent then return nil end
  
  local closeBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  closeBtn:SetSize(24, 24)
  closeBtn:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 1,
    insets = { left=1, right=1, top=1, bottom=1 }
  })
  closeBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.9) -- BUTTON_NORMAL
  closeBtn:SetBackdropBorderColor(0.15, 0.15, 0.15, 1) -- BORDER_DARK
  
  local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
  closeText:SetPoint("CENTER", 0, 1)
  closeText:SetTextColor(0.6, 0.6, 0.6, 1) -- TEXT_SECONDARY
  
  -- Set font BEFORE setting text
  local fontSet = pcall(function() closeText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 16, "OUTLINE") end)
  if not fontSet then
    pcall(function() closeText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE") end)
  end
  
  closeText:SetText("×")
  
  closeBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.15, 0.15, 0.15, 0.95) -- BUTTON_HOVER
    closeText:SetTextColor(1, 1, 1, 1) -- TEXT_PRIMARY
  end)
  closeBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.1, 0.1, 0.1, 0.9) -- BUTTON_NORMAL
    closeText:SetTextColor(0.6, 0.6, 0.6, 1) -- TEXT_SECONDARY
  end)
  
  return closeBtn
end

-- DEPRECATED: Old checkbox without onChange support - use Helpers.lua version instead
function AC:CreateFlatCheckbox_OLD(parent, size, checked)
  if not parent then return nil end
  
  local checkbox = CreateFrame("CheckButton", nil, parent)
  checkbox:SetSize(size or 16, size or 16)
  
  local bg = self:CreateFlatTexture(checkbox, "BACKGROUND", 1, COLORS.INPUT_DARK, 1)
  bg:SetAllPoints()
  
  local border = self:CreateFlatTexture(checkbox, "BORDER", 1, COLORS.BORDER_LIGHT, 1)
  border:SetAllPoints()
  
  local checkTexture = checkbox:CreateTexture(nil, "ARTWORK")
  checkTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  checkTexture:SetPoint("CENTER")
  checkTexture:SetSize(size or 16, size or 16)
  checkbox:SetCheckedTexture(checkTexture)
  
  if checked then checkbox:SetChecked(true) end
  
  return checkbox
end

function AC:CreateTexturedButton(parent, width, height, text, texture)
  if not parent then return nil end
  
  -- Create button WITHOUT UIPanelButtonTemplate to avoid default WoW button styling
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(width or 100, height or 24)
  button:EnableMouse(true)
  button:RegisterForClicks("LeftButtonUp")
  
  if texture then
    -- Custom texture background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    -- Check if texture starts with "UI\" (subfolder) or "button-" (root Media folder)
    local texturePath
    if texture:match("^UI\\") or texture:match("^UI/") then
      -- Already has UI\ prefix, use as-is
      texturePath = "Interface\\AddOns\\ArenaCore\\Media\\" .. texture .. ".tga"
    elseif texture:match("^button%-") then
      -- Button textures are in root Media folder
      texturePath = "Interface\\AddOns\\ArenaCore\\Media\\" .. texture .. ".tga"
    else
      -- Default to UI subfolder (for tab-purple-matte, etc.)
      texturePath = "Interface\\AddOns\\ArenaCore\\Media\\UI\\" .. texture .. ".tga"
    end
    bg:SetTexture(texturePath)
    bg:SetAllPoints()
    button.background = bg
    
    -- Add highlight texture that shows on hover (same texture, brighter)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture(texturePath)
    highlight:SetAllPoints()
    highlight:SetBlendMode("ADD") -- Additive blending makes it glow
    highlight:SetAlpha(0.3) -- 30% brightness boost on hover
    button:SetHighlightTexture(highlight)
  end
  
  -- Add text with custom font (NO OUTLINE, pure white)
  if text and text ~= "" then
    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetPoint("CENTER")
    buttonText:SetTextColor(1, 1, 1, 1) -- Pure white
    
    -- Set font BEFORE setting text
    local fontSet = pcall(function() buttonText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 13, "") end)
    if not fontSet then
      pcall(function() buttonText:SetFont("Fonts\\FRIZQT__.TTF", 13, "") end)
    end
    
    buttonText:SetText(text)
    button:SetFontString(buttonText)
    button.text = buttonText
  end
  
  -- Add hover/click effects with smooth transitions
  button:SetScript("OnEnter", function(self)
    -- Brighten background texture on hover
    if self.background then
      self.background:SetVertexColor(1.3, 1.3, 1.3, 1)
    end
    -- Brighten text on hover
    if self.text then
      self.text:SetTextColor(1, 1, 1, 1)
    end
  end)
  
  button:SetScript("OnLeave", function(self)
    -- Reset to normal brightness
    if self.background then
      self.background:SetVertexColor(1, 1, 1, 1)
    end
    if self.text then
      self.text:SetTextColor(1, 1, 1, 1)
    end
  end)
  
  button:SetScript("OnMouseDown", function(self)
    -- Darken on click
    if self.background then
      self.background:SetVertexColor(0.7, 0.7, 0.7, 1)
    end
    if self.text then
      self.text:SetTextColor(0.9, 0.9, 0.9, 1)
    end
  end)
  
  button:SetScript("OnMouseUp", function(self)
    -- Return to hover state after click
    if self.background then
      self.background:SetVertexColor(1.3, 1.3, 1.3, 1)
    end
    if self.text then
      self.text:SetTextColor(1, 1, 1, 1)
    end
  end)
  
  return button
end

-- ====== HELPERS ======
local function AC_ClampSublevel(n)
  n = tonumber(n) or 0
  if n > 7 then return 7 end
  if n < -8 then return -8 end
  return math.floor(n)
end

local function _safe_get_text(o)
  if not o or not o.GetText then return nil end
  local ok, v = pcall(o.GetText, o)
  if ok then return v end
end

local function _walk(f, fn)
  if not f then return end
  local regions = { f:GetRegions() }
  for _, r in ipairs(regions) do fn(r, true) end
  local children = { f:GetChildren() }
  for _, c in ipairs(children) do
    fn(c, false)
    _walk(c, fn)
  end
end
-- File: Core/UI.lua
-- Purpose: Increase the group height to fully contain all four settings.

-- CreateGroup_GENERAL moved to Core/Pages/ArenaFrames.lua
-- CreateGroup_POSITIONING moved to Core/Pages/ArenaFrames.lua

function AC:AddWindowEdge(frame, thickness, gap)
  local OUT = 7
  local INN = 6
  local th  = tonumber(thickness) or 1
  local gp  = tonumber(gap) or 0
  local inset = th + gp

  local t1 = self:CreateFlatTexture(frame, "OVERLAY", OUT, COLORS.BORDER_LIGHT, 0.9)
  t1:SetPoint("TOPLEFT", 0, 0)
  t1:SetPoint("TOPRIGHT", 0, 0)
  t1:SetHeight(th)

  local l1 = self:CreateFlatTexture(frame, "OVERLAY", OUT, COLORS.BORDER_LIGHT, 0.9)
  l1:SetPoint("TOPLEFT", 0, 0)
  l1:SetPoint("BOTTOMLEFT", 0, 0)
  l1:SetWidth(th)

  local r1 = self:CreateFlatTexture(frame, "OVERLAY", OUT, COLORS.BORDER_LIGHT, 0.9)
  r1:SetPoint("TOPRIGHT", 0, 0)
  r1:SetPoint("BOTTOMRIGHT", 0, 0)
  r1:SetWidth(th)

  local b1 = self:CreateFlatTexture(frame, "OVERLAY", OUT, COLORS.BORDER_LIGHT, 0.9)
  b1:SetPoint("BOTTOMLEFT", 0, 0)
  b1:SetPoint("BOTTOMRIGHT", 0, 0)
  b1:SetHeight(th)

  local t2 = self:CreateFlatTexture(frame, "OVERLAY", INN, COLORS.BORDER, 1)
  t2:SetPoint("TOPLEFT", inset, -inset)
  t2:SetPoint("TOPRIGHT", -inset, -inset)
  t2:SetHeight(th)

  local l2 = self:CreateFlatTexture(frame, "OVERLAY", INN, COLORS.BORDER, 1)
  l2:SetPoint("TOPLEFT", inset, -inset)
  l2:SetPoint("BOTTOMLEFT", inset, inset)
  l2:SetWidth(th)

  local r2 = self:CreateFlatTexture(frame, "OVERLAY", INN, COLORS.BORDER, 1)
  r2:SetPoint("TOPRIGHT", -inset, -inset)
  r2:SetPoint("BOTTOMRIGHT", -inset, inset)
  r2:SetWidth(th)

  local b2 = self:CreateFlatTexture(frame, "OVERLAY", INN, COLORS.BORDER, 1)
  b2:SetPoint("BOTTOMLEFT", inset, inset)
  b2:SetPoint("BOTTOMRIGHT", -inset, inset)
  b2:SetHeight(th)
  
  -- CRITICAL FIX: Return all border textures so they can be hidden/shown
  -- This allows systems like DispelTracker to hide borders when showBackground is false
  return {t1, l1, r1, b1, t2, l2, r2, b2}
end

-- ====== HIDETEST KILLER ======
function AC:HideLegacyJunk(root)
  if not root then return end
  local function nuke(obj)
    if not obj then return end
    if obj.Hide then obj:Hide() end
    if obj.SetAlpha then obj:SetAlpha(0) end
    if obj.EnableMouse then obj:EnableMouse(false) end
  end
  _walk(root, function(obj, isRegion)
    if obj.GetName then
      local nm = obj:GetName()
      if type(nm) == "string" and nm:upper():find("HIDETEST", 1, true) then
        nuke(obj); return
      end
    end
    local t
    if isRegion and obj.GetObjectType and obj:GetObjectType() == "FontString" then
      t = obj:GetText()
    end
    if not t then t = _safe_get_text(obj) end
    if type(t) == "string" then
      local up = t:upper()
      if up:find("HIDETEST", 1, true) or up:find("HIDE TEST", 1, true) or up:find("HIDE-TEST", 1, true) then
        local p = (obj.GetParent and obj:GetParent()) or obj
        nuke(p)
      end
    end
  end)
end

function AC:StartHideTestNuker(container)
  if not C_Timer or not container then return end
  local elapsed = 0
  local tk
  tk = C_Timer.NewTicker(0.1, function()
    elapsed = elapsed + 0.1
    if container:IsShown() then AC:HideLegacyJunk(container) end
    if elapsed > 3 and tk and tk.Cancel then tk:Cancel() end
  end)
end

function AC:PurgeFakeHideTest(container)
  if not container then return end
  local legit = { ArenaCore_TestAction = true, ArenaCore_HideAction = true }
  local seen  = {}
  local kids = { container:GetChildren() }
  for _, child in ipairs(kids) do
    if child.GetObjectType and child:GetObjectType() == "Button" then
      local name  = child:GetName()
      local label = (child.text and child.text.GetText and child.text:GetText()) or ""
      if name and legit[name] then
        if seen[name] then
          if child.Hide then child:Hide() end
          if child.SetAlpha then child:SetAlpha(0) end
          if child.EnableMouse then child:EnableMouse(false) end
        else
          seen[name] = true
        end
      else
        local kill = false
        local upn  = name and name:upper() or ""
        local upl  = label:upper()
        if upn:find("HIDETEST", 1, true) then kill = true
        elseif upl:find("HIDETEST", 1, true) then kill = true
        elseif (upl:find("HIDE", 1, true) and upl:find("TEST", 1, true)) then kill = true end
        if kill then
          if child.Hide then child:Hide() end
          if child.SetAlpha then child:SetAlpha(0) end
          if child.EnableMouse then child:EnableMouse(false) end
        end
      end
    end
  end
end

-- ====== MAIN UI ======
function AC:CreateConfigUI()
  if self.configFrame then return end -- FIX: Don't recreate, just return
  
  -- Get layout configuration based on active theme
  local layout = GetLayoutConfig()
  
  -- Update constants from layout config
  UI_WIDTH = layout.UI_WIDTH
  UI_HEIGHT = layout.UI_HEIGHT
  HEADER_HEIGHT = layout.HEADER_HEIGHT
  SIDEBAR_WIDTH = layout.SIDEBAR_WIDTH
  PADDING = layout.PADDING
  
  -- CRITICAL: Create FontObjects BEFORE building UI
  if self.EnsureUIFontObjects then
    self:EnsureUIFontObjects()
  end

  local frame = CreateFrame("Frame", "ArenaCoreConfigFrame", UIParent)
  frame:SetSize(UI_WIDTH, UI_HEIGHT)
  frame:SetPoint("CENTER", 0, 0)
  frame:Hide()
  frame:SetMovable(true)
  frame:SetClampedToScreen(false)  -- Allow dragging off-screen for better editing visibility
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetFrameStrata("HIGH")
  frame:SetFrameLevel(100)
  
  -- CRITICAL FIX: When UI closes, handle test mode and arena state correctly
  -- This prevents test data from persisting AND prevents trinket timers from freezing
  frame:SetScript("OnHide", function()
    -- STEP 1: Only disable test mode if we're actually IN test mode
    -- CRITICAL: Don't call DisableTestMode in real arena - it cancels trinket/racial tickers!
    if AC.MasterFrameManager and AC.MasterFrameManager.isTestMode then
      if AC.MasterFrameManager.DisableTestMode then
        AC.MasterFrameManager:DisableTestMode()
      end
    end
    
    -- STEP 2: If in arena, refresh to show correct data (prep room or live arena)
    local _, instanceType = IsInInstance()
    if instanceType == "arena" then
      C_Timer.After(0.15, function()
        -- Check if in prep room
        local numOpps = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0
        if numOpps > 0 then
          -- In prep room - refresh frames to show opponent specs
          if AC.MasterFrameManager and AC.MasterFrameManager.HandlePrepRoom then
            AC.MasterFrameManager:HandlePrepRoom()
          end
        else
          -- Live arena - let ARENA_OPPONENT_UPDATE events handle frame updates
          -- Just ensure frames are visible if they should be
          if AC.MasterFrameManager and AC.MasterFrameManager.frames then
            for i = 1, 3 do
              local frame = AC.MasterFrameManager.frames[i]
              if frame and UnitExists("arena" .. i) then
                frame:Show()
              end
            end
          end
        end
      end)
    end
  end)

  local border = self:CreateFlatTexture(frame, "BACKGROUND", 1, COLORS.BORDER, 1)
  border:SetAllPoints()

  local bg = self:CreateFlatTexture(frame, "BACKGROUND", 2, COLORS.BG, 1)
  bg:SetPoint("TOPLEFT", 1, -1)
  bg:SetPoint("BOTTOMRIGHT", -1, 1)
  frame.__mainBg = bg -- Store for theme system
  
  -- Add noise overlay for premium feel (will be added by theme system if Black Reaper active)
  frame.__mainFrame = true -- Mark as main frame for theme system

  self:AddWindowEdge(frame, 1, 0)

  self.configFrame = frame
  self:CreateHeader(frame)
  self:CreateSidebar(frame)
  self:CreateContentArea(frame)
  
  -- Enable resizable UI with corner drag handles
  if AC.UIFeatures and AC.UIFeatures.EnableResizableUI then
    AC.UIFeatures:EnableResizableUI(frame)
  end
  
  -- Create bottom button bar if Shade UI theme is active
  -- DISABLED: User wants to remove this bar, keeping only vanity footer
  -- local layout = GetLayoutConfig()
  -- if layout.HAS_BOTTOM_BAR then
  --   self:CreateBottomBar(frame, layout)
  -- end

  -- Attach vanity polish (lives in Core/UI.Vanity.lua)
  if AC.Vanity and AC.Vanity.AttachAll then
    AC.Vanity:AttachAll()
  end
end

-- keep-aware cleanup for header buttons
function AC:CleanupHeaderButtons(header, keep)
  if not header then return end
  header.__keep = header.__keep or {}
  if keep then header.__keep[keep] = true end
  local children = { header:GetChildren() }
  for _, child in ipairs(children) do
    if child ~= keep and not header.__keep[child]
       and child.GetObjectType and child:GetObjectType() == "Button" then
      if child.Hide then child:Hide() end
      if child.SetAlpha then child:SetAlpha(0) end
      if child.EnableMouse then child:EnableMouse(false) end
    end
  end
end

function AC:CreateHeader(parent)
  local layout = GetLayoutConfig()
  local activeTheme = AC.ThemeManager and AC.ThemeManager:GetActiveTheme() or "default"
  local isShadeUI = (activeTheme == "shade_ui")
  
  -- Debug: Print theme detection
  -- HIDDEN: Theme detection happens silently for cleaner user experience
  -- print("CreateHeader - Active theme:", activeTheme, "isShadeUI:", isShadeUI)
  
  local header
  
  -- Create header frame (same for both themes - keep it simple)
  header = CreateFrame("Frame", nil, parent)
  header:SetPoint("TOPLEFT", layout.PADDING, -layout.PADDING)
  header:SetPoint("TOPRIGHT", -layout.PADDING, -layout.PADDING)
  header:SetHeight(layout.HEADER_HEIGHT)
  
  -- Background color (different for each theme)
  local headerBg
  if isShadeUI then
    headerBg = self:CreateFlatTexture(header, "BACKGROUND", 1, {0.05, 0.05, 0.05, 0.95}, 1)
  else
    headerBg = self:CreateFlatTexture(header, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
  end
  headerBg:SetAllPoints()
  
  -- Purple accent line (only for ArenaCore theme)
  if not isShadeUI then
    local accent = self:CreateFlatTexture(header, "OVERLAY", 3, COLORS.PRIMARY or {0.545, 0.271, 1.000, 1}, 1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(2)
    header._accent = accent
    
    -- Bottom borders
    local hbLight = self:CreateFlatTexture(header, "OVERLAY", 2, COLORS.BORDER_LIGHT or {0.278, 0.278, 0.278, 1}, 0.8)
    hbLight:SetPoint("BOTTOMLEFT", 0, 0)
    hbLight:SetPoint("BOTTOMRIGHT", 0, 0)
    hbLight:SetHeight(1)

    local hbDark = self:CreateFlatTexture(header, "OVERLAY", 1, COLORS.BORDER or {0.196, 0.196, 0.196, 1}, 1)
    hbDark:SetPoint("BOTTOMLEFT", 0, 1)
    hbDark:SetPoint("BOTTOMRIGHT", 0, 1)
    hbDark:SetHeight(1)
  end

  -- Logo/Title (different for each theme)
  local logo
  
  if isShadeUI then
    -- SHADE UI: Small centered text only (NO big logo)
    local title = self:CreateStyledText(header, "ARENA CORE", 16, COLORS.TEXT, "OVERLAY", "")
    title:SetPoint("TOP", 0, -8)
    
    local subtitle = self:CreateStyledText(header, "the ultimate PvP addon", 9, {0.6, 0.4, 0.8, 1}, "OVERLAY", "")
    subtitle:SetPoint("TOP", 0, -24)
  else
    -- DEFAULT ARENACORE: Show full logo
    logo = header:CreateTexture(nil, "OVERLAY")
    logo:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Logo\\arena_core_clean.tga")
    logo:SetSize(250, 67)
    logo:SetPoint("LEFT", 25, 8)
  end

  -- Version badge (show for both themes)
  local versionFrame = CreateFrame("Frame", nil, header)
  versionFrame:SetSize(60, 24)
  
  if isShadeUI then
    -- Shade UI: Position in empty space between sword logo and title (left-center area)
    versionFrame:SetPoint("LEFT", 140, 0)
  elseif logo then
    -- Default theme: Position next to logo
    versionFrame:SetPoint("LEFT", logo, "RIGHT", 15, 0)
  end

  local versionTexture = versionFrame:CreateTexture(nil, "BACKGROUND")
  versionTexture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\tab-purple-matte.tga")
  versionTexture:SetAllPoints()

  local version = self:CreateStyledText(versionFrame, "v" .. (AC.Version or "0.9.2.2"), 11, COLORS.TEXT, "OVERLAY", "")
  version:SetPoint("CENTER", 0, 0)

  -- Add "NEW" indicator for latest version
  local newIndicator = versionFrame:CreateFontString(nil, "OVERLAY")
  newIndicator:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 8, "OUTLINE")
  newIndicator:SetText("|cffFFD700NEW|r")
  newIndicator:SetPoint("LEFT", version, "RIGHT", 3, 0)
  -- Simple pulsing animation for the NEW indicator
  -- NOTE: FontStrings don't support SetScript - use the parent frame instead
  local pulseTime = 0
  versionFrame:SetScript("OnUpdate", function(self, elapsed)
    pulseTime = pulseTime + elapsed
    local alpha = 0.5 + math.sin(pulseTime * 2) * 0.5
    newIndicator:SetAlpha(alpha)
  end)

  -- Expose for Vanity.lua
  self.versionFrame = versionFrame
  self.versionText  = version

  -- Advanced Features button (show for both themes)
  local moreBtn = self:CreateTexturedButton(header, 140, 32, "Advanced Features", "UI\\tab-purple-matte")
  moreBtn:SetPoint("RIGHT", -110, 0)
  -- Adjust font size for better fit
  if moreBtn.text then
    local fontSet = pcall(function() moreBtn.text:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 12, "") end)
    if not fontSet then
      pcall(function() moreBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "") end)
    end
  end
  moreBtn:SetScript("OnClick", function()
    if AC.MoreFeatures and AC.MoreFeatures.ShowWindow then
      AC.MoreFeatures:ShowWindow()
    end
  end)

  -- Close button (different styles for each theme)
  local closeBtn
  if isShadeUI then
    -- Shade UI: Dark button with × text
    closeBtn = self:CreateShadeCloseButton(header)
    closeBtn:SetPoint("TOPRIGHT", -8, -8)
  else
    -- Default theme: Red textured button
    closeBtn = self:CreateTexturedButton(header, 36, 36, "", "button-close")
    closeBtn:SetPoint("RIGHT", -20, 0)
    local xText = self:CreateStyledText(closeBtn, "×", 18, COLORS.TEXT, "OVERLAY", "")
    xText:SetPoint("CENTER", 0, 0)
    closeBtn._xText = xText
  end
  
  closeBtn:SetScript("OnClick", function() 
  -- Auto-hide test frames if they're visible when closing UI
  if AC.FrameManager then
    AC.FrameManager:DisableTestMode()
  end
  
  -- Hide main UI
  if AC.configFrame then
    AC.configFrame:Hide()
  end
  
  -- Hide More Features window if open
  if AC.MoreFeatures and AC.MoreFeatures.frame and AC.MoreFeatures.frame:IsShown() then
    AC.MoreFeatures.frame:Hide()
  end
end)

  -- keep-list so CleanupHeaderButtons won’t nuke our vanity buttons
  header.__acClose = closeBtn
  header.__keep = { [closeBtn] = true }
  self.header = header
end

function AC:CreateSidebar(parent)
  local layout = GetLayoutConfig()
  local activeTheme = AC.ThemeManager and AC.ThemeManager:GetActiveTheme() or "default"
  local isShadeUI = (activeTheme == "shade_ui")
  
  local sidebar
  
  if isShadeUI then
    -- Layout values verified - debug removed for clean release
    
    -- SHADE UI STYLE: Use BackdropTemplate with borders and gradient
    sidebar = self:CreateShadeFrame(parent, layout.SIDEBAR_WIDTH, layout.SIDEBAR_HEIGHT,
      {0.08, 0.08, 0.08, 0.9},  -- BACKGROUND_MEDIUM
      {0.15, 0.15, 0.15, 1}     -- BORDER_DARK
    )
    -- Use LEFT anchors and SetWidth to strictly constrain sidebar
    sidebar:SetPoint("TOPLEFT", layout.PADDING, layout.SIDEBAR_TOP_OFFSET)
    sidebar:SetPoint("BOTTOMLEFT", layout.PADDING, layout.PADDING + 28 + 10)
    -- CRITICAL: SetWidth to prevent sidebar from extending right into content area
    sidebar:SetWidth(layout.SIDEBAR_WIDTH)
    
    -- Remove bottom border by modifying backdrop insets
    sidebar:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 1,
      insets = { left=1, right=1, top=1, bottom=0 }  -- bottom=0 removes bottom border
    })
    sidebar:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    sidebar:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
    
    -- Sidebar dimensions verified - debug removed for clean release
    
    -- Apply horizontal gradient (Shade UI style: lighter on left, darker on right)
    self:ApplyShadeGradient(sidebar, "HORIZONTAL",
      {0.1, 0.1, 0.1, 0.9},   -- Start (lighter)
      {0.06, 0.06, 0.06, 0.9} -- End (darker)
    )
  else
    -- DEFAULT ARENACORE STYLE: Flat texture
    sidebar = CreateFrame("Frame", nil, parent)
    sidebar:SetPoint("TOPLEFT", layout.PADDING, layout.SIDEBAR_TOP_OFFSET)
    -- CRITICAL FIX: Stop sidebar above footer to prevent grey background bleed
    sidebar:SetPoint("BOTTOMLEFT", layout.PADDING, layout.PADDING + layout.VANITY_FOOTER_HEIGHT)
    sidebar:SetWidth(layout.SIDEBAR_WIDTH)
    
    local bg = self:CreateFlatTexture(sidebar, "BACKGROUND", 1, COLORS.BG, 1)
    bg:SetAllPoints()
    sidebar.__sidebarBg = bg -- Store for theme system to apply gradient
  end
  
  sidebar.__isSidebar = true -- Mark as sidebar

  -- Spacing adjusted based on theme
  local TOP_OFFSET    = layout.NAV_FIRST_OFFSET
  local TITLE_TO_LINE = 20
  local ITEM_SPACING  = layout.NAV_BUTTON_SPACING  -- Spacing between button tops
  local AFTER_SECTION = 28

  local nav = {
    {
      title = "LAYOUT",
      items = {
        { text = "Arena Frames",        key = "ArenaFrames",    active = true },
        { text = "Class Packs",          key = "classpacks" },
        { text = "Trinkets/Other",            key = "trinketsother" },
        { text = "Blackout",             key = "blackout" },
        { text = "Cast Bars",           key = "castbars" },
        { text = "Diminishing Returns", key = "dr" },
        { text = "HP Bars & Textures",  key = "textures" },
        { text = "More Goodies",        key = "moregoodies" },
        { text = "Frames/Nameplates",    key = "frames" },
      }
    }
  }

  local y = TOP_OFFSET
  
  -- MIDNIGHT button (custom purple button) - positioned at top next to LAYOUT
  local midnightBtn = CreateFrame("Button", nil, sidebar)
  midnightBtn:SetSize(100, 26) -- Compact size for top placement
  midnightBtn:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -10, y + 2) -- Right side, aligned with LAYOUT
  
  -- Background (purple gradient)
  local midnightBg = midnightBtn:CreateTexture(nil, "BACKGROUND")
  midnightBg:SetAllPoints()
  midnightBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- ArenaCore PRIMARY purple
  
  -- Border (darker for depth)
  local midnightBorder = midnightBtn:CreateTexture(nil, "BORDER")
  midnightBorder:SetPoint("TOPLEFT", 1, -1)
  midnightBorder:SetPoint("BOTTOMRIGHT", -1, 1)
  midnightBorder:SetColorTexture(0.4, 0.2, 0.7, 1)
  
  -- Alert icon (Crosshair_Important_128)
  local alertIcon = midnightBtn:CreateTexture(nil, "OVERLAY")
  alertIcon:SetAtlas("Crosshair_Important_128")
  alertIcon:SetSize(22, 22) -- As large as possible without leaving button area
  alertIcon:SetPoint("LEFT", midnightBtn, "LEFT", 6, 0)
  
  -- Text (no outline)
  local midnightText = midnightBtn:CreateFontString(nil, "OVERLAY")
  midnightText:SetFont(self.FONT_PATH, 10) -- Smaller font for compact button
  midnightText:SetText("MIDNIGHT")
  midnightText:SetTextColor(1, 1, 1, 1)
  midnightText:SetPoint("LEFT", alertIcon, "RIGHT", 4, 0) -- Positioned after icon with spacing
  
  -- Hover effect
  midnightBtn:SetScript("OnEnter", function()
    midnightBg:SetColorTexture(0.645, 0.371, 1.000, 1) -- Lighter purple
  end)
  midnightBtn:SetScript("OnLeave", function()
    midnightBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- Original purple
  end)
  
  -- Click handler
  midnightBtn:SetScript("OnClick", function()
    if AC.ShowMidnightWindow then
      AC:ShowMidnightWindow()
    end
  end)
  
  for _, section in ipairs(nav) do
    -- For Shade UI, align title and line with button left edge (10px)
    local titleInset = isShadeUI and 10 or 25
    local lineInset = isShadeUI and 10 or 25
    
    local t = self:CreateStyledText(sidebar, section.title, 12, COLORS.PRIMARY, "OVERLAY", "")
    t:SetPoint("TOPLEFT", titleInset, y)

    local line = self:CreateFlatTexture(sidebar, "OVERLAY", 1, COLORS.BORDER_LIGHT, 0.6)
    line:SetPoint("TOPLEFT", lineInset, y - TITLE_TO_LINE)
    line:SetPoint("TOPRIGHT", -lineInset, y - TITLE_TO_LINE)
    line:SetHeight(1)

    y = y - (TITLE_TO_LINE + 20)

    for _, item in ipairs(section.items) do
      local btn = self:CreateNavItem(sidebar, item)
      btn:SetPoint("TOPLEFT", 10, y)
      if item.active and not self.activeNavItem then
        self.activeNavItem = btn
      end
      y = y - ITEM_SPACING
    end

    y = y - AFTER_SECTION
  end

  -- DISCORD button (custom purple button) - positioned below More Goodies with offset from left edge
  local discordBtn = CreateFrame("Button", nil, sidebar)
  discordBtn:SetSize(90, 24) -- Slightly smaller to prevent footer clipping
  discordBtn:SetPoint("TOPLEFT", 30, y + 17) -- Moved down 3 pixels for fine-tuning
  
  -- Background (purple gradient)
  local discordBg = discordBtn:CreateTexture(nil, "BACKGROUND")
  discordBg:SetAllPoints()
  discordBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- ArenaCore PRIMARY purple
  
  -- Border (darker for depth)
  local discordBorder = discordBtn:CreateTexture(nil, "BORDER")
  discordBorder:SetPoint("TOPLEFT", 1, -1)
  discordBorder:SetPoint("BOTTOMRIGHT", -1, 1)
  discordBorder:SetColorTexture(0.4, 0.2, 0.7, 1)
  
  -- Discord icon (using chat bubble atlas)
  local discordIcon = discordBtn:CreateTexture(nil, "OVERLAY")
  discordIcon:SetAtlas("communities-icon-chat")
  discordIcon:SetSize(20, 20)
  discordIcon:SetPoint("LEFT", discordBtn, "LEFT", 6, 0)
  
  -- Text (no outline)
  local discordText = discordBtn:CreateFontString(nil, "OVERLAY")
  discordText:SetFont(self.FONT_PATH, 10) -- Same font size as Midnight
  discordText:SetText("DISCORD")
  discordText:SetTextColor(1, 1, 1, 1)
  discordText:SetPoint("LEFT", discordIcon, "RIGHT", 4, 0)
  
  -- Hover effect
  discordBtn:SetScript("OnEnter", function()
    discordBg:SetColorTexture(0.645, 0.371, 1.000, 1) -- Lighter purple
  end)
  discordBtn:SetScript("OnLeave", function()
    discordBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- Original purple
  end)
  
  -- Click handler
  discordBtn:SetScript("OnClick", function()
    if AC.Vanity and AC.Vanity.ShowDiscordLinkPopup then
      AC.Vanity:ShowDiscordLinkPopup()
    end
  end)

  local sAccent = self:CreateFlatTexture(sidebar, "OVERLAY", 2, COLORS.BORDER_LIGHT, 0.6)
  sAccent:SetPoint("TOPRIGHT", -1, 0)
  sAccent:SetPoint("BOTTOMRIGHT", -1, 0)
  sAccent:SetWidth(1)

  self.sidebar = sidebar
end

function AC:CreateNavItem(parent, item)
  -- Creates a sidebar navigation button
  local layout = GetLayoutConfig()
  local activeTheme = AC.ThemeManager and AC.ThemeManager:GetActiveTheme() or "default"
  local isShadeUI = (activeTheme == "shade_ui")
  
  local b
  
  if isShadeUI then
    -- SHADE UI STYLE: BackdropTemplate button, no outlines
    b = self:CreateShadeButton(parent, layout.NAV_BUTTON_WIDTH, layout.NAV_BUTTON_HEIGHT)
  else
    -- DEFAULT ARENACORE STYLE: Flat texture button with outlines
    b = CreateFrame("Button", nil, parent)
    b:SetSize(layout.NAV_BUTTON_WIDTH, layout.NAV_BUTTON_HEIGHT)
    
    local bg = self:CreateFlatTexture(b, "BACKGROUND", 0, COLORS.NAV_INACTIVE_BG, 1)
    bg:SetAllPoints()
    b.__navBg = bg
  end
  
  b.__isNavButton = true
  b.__useGradient = false
  
  -- Elements that differ between styles
  local indicator, hover, outlineTop, outlineBottom, outlineLeft, outlineRight
  
  if not isShadeUI then
    -- ArenaCore style: indicator bar and outlines
    indicator = self:CreateFlatTexture(b, "OVERLAY", 2, COLORS.PRIMARY, 1)
    indicator:SetPoint("LEFT", -10, 0)
    indicator:SetSize(5, 44)
    indicator:Hide()
    
    hover = self:CreateFlatTexture(b, "ARTWORK", 1, COLORS.BORDER_LIGHT, 0.15)
    hover:SetAllPoints()
    hover:Hide()
    
    -- Purple outline borders
    outlineTop = self:CreateFlatTexture(b, "OVERLAY", 3, COLORS.PRIMARY, 1)
    outlineTop:SetPoint("TOPLEFT", 0, 0)
    outlineTop:SetPoint("TOPRIGHT", 0, 0)
    outlineTop:SetHeight(2)
    outlineTop:Hide()
    
    outlineBottom = self:CreateFlatTexture(b, "OVERLAY", 3, COLORS.PRIMARY, 1)
    outlineBottom:SetPoint("BOTTOMLEFT", 0, 0)
    outlineBottom:SetPoint("BOTTOMRIGHT", 0, 0)
    outlineBottom:SetHeight(2)
    outlineBottom:Hide()
    
    outlineLeft = self:CreateFlatTexture(b, "OVERLAY", 3, COLORS.PRIMARY, 1)
    outlineLeft:SetPoint("TOPLEFT", 0, 0)
    outlineLeft:SetPoint("BOTTOMLEFT", 0, 0)
    outlineLeft:SetWidth(2)
    outlineLeft:Hide()
    
    outlineRight = self:CreateFlatTexture(b, "OVERLAY", 3, COLORS.PRIMARY, 1)
    outlineRight:SetPoint("TOPRIGHT", 0, 0)
    outlineRight:SetPoint("BOTTOMRIGHT", 0, 0)
    outlineRight:SetWidth(2)
    outlineRight:Hide()
  end
  
  -- Icon (simpler in Shade UI - no background frame)
  local icon, iconBg, iconText
  
  if isShadeUI then
    -- Shade UI: Icon texture directly on button
    icon = b:CreateTexture(nil, "OVERLAY")
    icon:SetSize(layout.NAV_ICON_SIZE, layout.NAV_ICON_SIZE)
    icon:SetPoint("LEFT", 12, 0)
    -- For now, use letter icon (can be replaced with actual icons later)
    -- icon:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Icons\\...")
  else
    -- ArenaCore: Icon in frame with background
    local iconFrame = CreateFrame("Frame", nil, b)
    iconFrame:SetSize(layout.NAV_ICON_SIZE, layout.NAV_ICON_SIZE)
    iconFrame:SetPoint("LEFT", 22, 0)
    
    iconBg = self:CreateFlatTexture(iconFrame, "BACKGROUND", 0, COLORS.ICON_BG, 1)
    iconBg:SetAllPoints()
    
    iconText = self:CreateStyledText(iconFrame, string.sub(item.text, 1, 1), 16, COLORS.TEXT_2, "OVERLAY", "")
    iconText:SetPoint("CENTER")
    icon = iconFrame
  end
  
  -- Label text
  local label = self:CreateStyledText(b, item.text, layout.NAV_FONT_SIZE, COLORS.TEXT_2, "OVERLAY", "")
  if isShadeUI then
    label:SetPoint("CENTER", 0, 0)  -- Shade UI: perfectly centered (no offset)
  else
    label:SetPoint("LEFT", icon, "RIGHT", 12, 0)  -- ArenaCore: left aligned
  end
  
  -- Shade UI: Add purple overlay for active state
  local shadeOverlay
  if isShadeUI then
    shadeOverlay = b:CreateTexture(nil, "OVERLAY")
    shadeOverlay:SetAllPoints()
    shadeOverlay:SetColorTexture(0.6, 0.2, 0.8, 0.15)  -- Purple overlay
    shadeOverlay:Hide()
  end

  b.isActive = item.active or false

  function b:SetActive(active)
    self.isActive = active
    if hover then hover:Hide() end
    
    if isShadeUI then
      -- SHADE UI STYLE: Background color + purple overlay
      if active then
        -- Active: Purple-tinted background + overlay
        self:SetBackdropColor(0.15, 0.1, 0.2, 0.95)  -- Slightly purple background
        if shadeOverlay then shadeOverlay:Show() end
        label:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
      else
        -- Inactive: Normal dark background
        self:SetBackdropColor(0.1, 0.1, 0.1, 0.9)  -- BUTTON_NORMAL
        if shadeOverlay then shadeOverlay:Hide() end
        label:SetTextColor(COLORS.TEXT_2[1], COLORS.TEXT_2[2], COLORS.TEXT_2[3], 1)
      end
    else
      -- ARENACORE STYLE: Outlines and indicator
      if active then
        local activeColor = COLORS.NAV_ACTIVE_BG
        b.__navBg:SetColorTexture(activeColor[1], activeColor[2], activeColor[3], 1)
        
        indicator:Show()
        iconBg:SetColorTexture(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.25)
        iconText:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
        label:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
        
        outlineTop:Show()
        outlineBottom:Show()
        outlineLeft:Show()
        outlineRight:Show()
      else
        local inactiveColor = COLORS.NAV_INACTIVE_BG
        b.__navBg:SetColorTexture(inactiveColor[1], inactiveColor[2], inactiveColor[3], 1)
        
        indicator:Hide()
        iconBg:SetColorTexture(COLORS.ICON_BG[1], COLORS.ICON_BG[2], COLORS.ICON_BG[3], 1)
        iconText:SetTextColor(COLORS.TEXT_2[1], COLORS.TEXT_2[2], COLORS.TEXT_2[3], 1)
        label:SetTextColor(COLORS.TEXT_2[1], COLORS.TEXT_2[2], COLORS.TEXT_2[3], 1)
        
        outlineTop:Hide()
        outlineBottom:Hide()
        outlineLeft:Hide()
        outlineRight:Hide()
      end
    end
  end
  b:SetActive(b.isActive) -- Set initial state

  b:SetScript("OnEnter", function(selfBtn)
    if not selfBtn.isActive then
      if isShadeUI then
        -- Shade UI: Lighter background on hover
        selfBtn:SetBackdropColor(0.15, 0.15, 0.15, 0.95)  -- BUTTON_HOVER
        label:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
      else
        -- ArenaCore: Show hover overlay and indicator
        hover:Show()
        indicator:SetColorTexture(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.6)
        indicator:Show()
        label:SetTextColor(COLORS.TEXT[1], COLORS.TEXT[2], COLORS.TEXT[3], 1)
        iconBg:SetColorTexture(COLORS.PRIMARY[1], COLORS.PRIMARY[2], COLORS.PRIMARY[3], 0.18)
      end
    end
  end)

  b:SetScript("OnLeave", function(selfBtn)
    if not selfBtn.isActive then
      if isShadeUI then
        -- Shade UI: Back to normal background
        selfBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)  -- BUTTON_NORMAL
        label:SetTextColor(COLORS.TEXT_2[1], COLORS.TEXT_2[2], COLORS.TEXT_2[3], 1)
      else
        -- ArenaCore: Hide hover overlay and indicator
        hover:Hide()
        indicator:Hide()
        label:SetTextColor(COLORS.TEXT_2[1], COLORS.TEXT_2[2], COLORS.TEXT_2[3], 1)
        iconBg:SetColorTexture(COLORS.ICON_BG[1], COLORS.ICON_BG[2], COLORS.ICON_BG[3], 1)
      end
    end
  end)

  b:SetScript("OnClick", function()
    AC:OnNavItemClick(b, item)
  end)

  return b
end

function AC:CreateContentArea(parent)
-- Connect to database
AC.db = AC.DB and AC.DB.profile or {}
  local layout = GetLayoutConfig()
  
  -- Check if Shade UI theme is active
  local activeTheme = AC.ThemeManager and AC.ThemeManager:GetActiveTheme() or "default"
  local isShadeUI = (activeTheme == "shade_ui")
  
  -- Theme detection and offset calculation - debug removed for clean release
  
  local content = CreateFrame("ScrollFrame", nil, parent)
  -- TEST: EXTREME LEFT positioning to verify code is working
  -- For Shade UI: move content to 50px from left (VERY obvious if working)
  -- For Default: keep original positioning (240 + 8 + 1 = 249px from left)
  local leftOffset = isShadeUI and 50 or (layout.SIDEBAR_WIDTH + layout.PADDING + 1)
  -- leftOffset calculated based on theme
  content:SetPoint("TOPLEFT", leftOffset, layout.CONTENT_TOP_OFFSET)
  
  -- Adjust bottom position - account for vanity footer (28px)
  local VANITY_FOOTER_HEIGHT = 28
  local bottomOffset = layout.PADDING + VANITY_FOOTER_HEIGHT
  content:SetPoint("BOTTOMRIGHT", -layout.PADDING - 20, bottomOffset) -- Leave 20px for scrollbar + gap
  
  -- Content position verified - debug removed for clean release

  -- Use darker background for Shade UI theme - but don't use SetAllPoints
  -- Instead, anchor it properly to not extend into footer
  local bgColor = isShadeUI and {0.05, 0.05, 0.05, 0.95} or COLORS.BG
  local contentBg = self:CreateFlatTexture(content, "BACKGROUND", 1, bgColor, 1)
  
  if isShadeUI then
    -- For Shade UI: Anchor background to stay within content bounds
    contentBg:SetPoint("TOPLEFT", 0, 0)
    contentBg:SetPoint("TOPRIGHT", 0, 0)
    contentBg:SetPoint("BOTTOMLEFT", 0, 0)
    contentBg:SetPoint("BOTTOMRIGHT", 0, 0)
  else
    contentBg:SetAllPoints()
  end

  -- Only show bottom border line for default theme, not Shade UI
  if not isShadeUI then
    local cBottom = self:CreateFlatTexture(parent, "OVERLAY", 2, COLORS.BORDER_LIGHT, 0.6)
    local bottomBorderY = layout.PADDING + VANITY_FOOTER_HEIGHT
    -- Use same leftOffset as content area for consistent alignment
    cBottom:SetPoint("BOTTOMLEFT", leftOffset, bottomBorderY)
    cBottom:SetPoint("BOTTOMRIGHT", -layout.PADDING, bottomBorderY)
    cBottom:SetHeight(1)
  end

  -- Create the scroll child with dynamic height
  local layout = GetLayoutConfig()
  local child = CreateFrame("Frame", nil, content)
  child:SetWidth(layout.CONTENT_WIDTH - 20) -- Fixed width based on layout
  child:SetHeight(1) -- Will be updated dynamically
  content:SetScrollChild(child)

  local activeTheme = AC.ThemeManager and AC.ThemeManager:GetActiveTheme() or "default"
  local isShadeUI = (activeTheme == "shade_ui")
  
  local contentBox
  
  if isShadeUI then
    -- SHADE UI STYLE: BackdropTemplate with much darker colors
    contentBox = self:CreateShadeFrame(child, nil, nil,
      {0.05, 0.05, 0.05, 0.95},  -- Very dark background (matches Shade UI)
      {0.15, 0.15, 0.15, 1}      -- Dark border
    )
    contentBox:SetPoint("TOPLEFT", 2, 0)
    contentBox:SetPoint("TOPRIGHT", -12, 0)
    contentBox:SetHeight(1)
    
    -- Apply vertical gradient (Shade UI style)
    self:ApplyShadeGradient(contentBox, "VERTICAL",
      {0.08, 0.08, 0.08, 0.9},   -- Top (slightly lighter)
      {0.05, 0.05, 0.05, 0.95}   -- Bottom (darker)
    )
  else
    -- DEFAULT ARENACORE STYLE: Flat texture with borders
    contentBox = CreateFrame("Frame", nil, child)
    contentBox:SetPoint("TOPLEFT", 2, 0)
    contentBox:SetPoint("TOPRIGHT", -12, 0)
    contentBox:SetHeight(1)
    
    local bgColor = COLORS.BG or {0.200, 0.200, 0.200, 1}
    local contentFill = self:CreateFlatTexture(contentBox, "BACKGROUND", 1, bgColor, 1)
    contentFill:SetAllPoints()
    contentBox.__contentFill = contentFill
    
    -- Hairline borders
    local borderCol = COLORS.BORDER_LIGHT
    local ht = self:CreateFlatTexture(contentBox, "OVERLAY", 6, borderCol, 0.9)
    ht:SetPoint("TOPLEFT", 0, 0); ht:SetPoint("TOPRIGHT", 0, 0); ht:SetHeight(1)
    local hb = self:CreateFlatTexture(contentBox, "OVERLAY", 6, borderCol, 0.9)
    hb:SetPoint("BOTTOMLEFT", 0, 0); hb:SetPoint("BOTTOMRIGHT", 0, 0); hb:SetHeight(1)
    local hl = self:CreateFlatTexture(contentBox, "OVERLAY", 6, borderCol, 0.9)
    hl:SetPoint("TOPLEFT", 0, 0); hl:SetPoint("BOTTOMLEFT", 0, 0); hl:SetWidth(1)
    local hr = self:CreateFlatTexture(contentBox, "OVERLAY", 6, borderCol, 0.9)
    hr:SetPoint("TOPRIGHT", 0, 0); hr:SetPoint("BOTTOMRIGHT", 0, 0); hr:SetWidth(1)
  end

  -- Create custom scrollbar with proper clipping
  local scrollbar = CreateFrame("Slider", nil, parent)
  
  -- CRITICAL: Set frame level higher than content so scrollbar draws on top
  -- Use parent's frame level + 50 to ensure it's above content
  scrollbar:SetFrameLevel(parent:GetFrameLevel() + 50)
  
  -- Position scrollbar to align with CONTENT area, not extend into header
  -- Use content's top/bottom for vertical alignment, parent's right edge for horizontal
  scrollbar:SetPoint("TOP", content, "TOP", 0, 0)
  scrollbar:SetPoint("BOTTOM", content, "BOTTOM", 0, 0)
  scrollbar:SetPoint("RIGHT", parent, "RIGHT", -layout.PADDING, 0)
  scrollbar:SetWidth(16)
  scrollbar:SetOrientation("VERTICAL")
  scrollbar:SetMinMaxValues(0, 1)
  scrollbar:SetValue(0)
  
  -- CRITICAL: Clip scrollbar to prevent extending into header
  scrollbar:SetClipsChildren(true)

  -- Scrollbar track (very dark background to match theme)
  local trackBg = self:CreateFlatTexture(scrollbar, "BACKGROUND", 1, {0.05, 0.05, 0.05, 0.95}, 1)
  trackBg:SetAllPoints()

  -- Scrollbar thumb - custom compressed texture
  local thumbTexture = scrollbar:CreateTexture(nil, "OVERLAY")
  thumbTexture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga")
  thumbTexture:SetWidth(14)
  thumbTexture:SetHeight(20)
  scrollbar:SetThumbTexture(thumbTexture)
  
  -- Store thumb padding constant for later use
  -- Increase padding to account for scrollbar being positioned in header area
  local THUMB_PADDING = 10
  scrollbar._thumbPadding = THUMB_PADDING

  -- Hide default Blizzard scrollbar elements
  if scrollbar.ScrollUpButton then scrollbar.ScrollUpButton:Hide() end
  if scrollbar.ScrollDownButton then scrollbar.ScrollDownButton:Hide() end

  -- Connect scrollbar to ScrollFrame
  local function UpdateScrollbar()
    local maxScroll = content:GetVerticalScrollRange()
    if maxScroll > 0 then
      scrollbar:Show()
      scrollbar:SetMinMaxValues(0, maxScroll)
      local currentScroll = content:GetVerticalScroll()
      scrollbar:SetValue(currentScroll) -- Direct mapping
    else
      scrollbar:Hide()
    end
  end

  local function UpdateContentHeight()
    local totalHeight = 0
    local children = {child:GetChildren()}
    for _, ch in ipairs(children) do
      if ch:IsShown() then
        local _, _, _, _, bottom = ch:GetPoint(1)
        if bottom then
          totalHeight = math.max(totalHeight, math.abs(bottom) + ch:GetHeight() + 20)
        end
      end
    end
    
    -- Ensure minimum height and add padding
    totalHeight = math.max(totalHeight, 600) + 50
    child:SetHeight(totalHeight)
    contentBox:SetHeight(totalHeight - 20)
    
    C_Timer.After(0.1, UpdateScrollbar) -- Update scrollbar after height change
  end

  -- Scrollbar events
  scrollbar:SetScript("OnValueChanged", function(self, value)
    local maxScroll = content:GetVerticalScrollRange()
    content:SetVerticalScroll(value) -- Direct mapping
    
    -- CRITICAL: Manually constrain thumb position with padding
    local thumb = self:GetThumbTexture()
    if thumb and self._thumbPadding then
      local scrollbarHeight = self:GetHeight()
      local minVal, maxVal = self:GetMinMaxValues()
      local range = maxVal - minVal
      
      if range > 0 and scrollbarHeight > 0 then
        -- Calculate percentage (0 to 1)
        local percent = (value - minVal) / range
        
        -- Calculate position with padding
        local padding = self._thumbPadding
        local thumbHeight = thumb:GetHeight()
        local usableHeight = scrollbarHeight - (padding * 2) - thumbHeight
        local thumbPos = padding + (percent * usableHeight)
        
        -- Manually position thumb
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", self, "TOP", 0, -thumbPos)
      end
    end
  end)

  -- Mouse wheel support
  content:EnableMouseWheel(true)
  content:SetScript("OnMouseWheel", function(self, delta)
    local current = scrollbar:GetValue()
    local step = 20
    scrollbar:SetValue(current - (delta * step)) -- Invert mouse wheel direction
  end)

  -- Update scrollbar when content changes
  content:SetScript("OnScrollRangeChanged", UpdateScrollbar)
  content:SetScript("OnVerticalScroll", UpdateScrollbar)

  self.contentArea = content
  self.scrollChild = child
  self.contentBox = contentBox
  self.scrollbar = scrollbar
  self.UpdateContentHeight = UpdateContentHeight -- Expose for other functions to use

  -- Arena Frames page is now handled by Core/Pages/ArenaFrames.lua
  -- Load the default active page (Arena Frames) on UI creation
  C_Timer.After(0.1, function()
    if AC.ShowPage then
      AC:ShowPage("ArenaFrames")
    end
  end)
  
  -- Update content height after everything is created
  C_Timer.After(0.2, UpdateContentHeight)
end

-- ====== BOTTOM BUTTON BAR (Shade UI Only) ======
function AC:CreateBottomBar(parent, layout)
  -- SHADE UI STYLE: BackdropTemplate with dark colors
  local bottomBar = self:CreateShadeFrame(parent, layout.UI_WIDTH - (layout.PADDING * 2), layout.BOTTOM_BAR_HEIGHT,
    {0.05, 0.05, 0.05, 0.95},  -- Very dark background
    {0.15, 0.15, 0.15, 1}      -- Dark border
  )
  bottomBar:SetPoint("BOTTOM", 0, layout.PADDING)
  
  -- "Apply Changes" button (left side)
  local applyBtn = self:CreateTexturedButton(bottomBar, 120, 30, "Apply Changes", "UI\\tab-purple-matte")
  applyBtn:SetPoint("LEFT", 20, 0)
  applyBtn:SetScript("OnClick", function()
    print("|cff8B45FFArenaCore:|r Settings applied!")
    -- Trigger any apply logic here if needed
  end)
  
  -- "Save Settings" button (next to Apply)
  local saveBtn = self:CreateTexturedButton(bottomBar, 120, 30, "Save Settings", "UI\\tab-purple-matte")
  saveBtn:SetPoint("LEFT", applyBtn, "RIGHT", 15, 0)
  saveBtn:SetScript("OnClick", function()
    print("|cff8B45FFArenaCore:|r Settings saved!")
    -- Trigger any save logic here if needed
  end)
  
  self.bottomBar = bottomBar
end

-- OnGrowthDirectionChanged moved to Core/Pages/ArenaFrames.lua
function AC:CreateSliderSetting(parent, label, y, path, min, max, value, pct)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", 20, y)
  row:SetPoint("TOPRIGHT", -20, y)
  row:SetHeight(26)

  local l = self:CreateStyledText(row, label, 11, COLORS.TEXT_2, "OVERLAY", "")
  l:SetPoint("LEFT", 0, 0)
  l:SetWidth(100)
  l:SetJustifyH("LEFT")

  local minT = self:CreateStyledText(row, pct and (min .. "%") or tostring(min), 10, COLORS.TEXT_MUTED, "OVERLAY", "")
  minT:SetPoint("LEFT", l, "RIGHT", 10, 0)

  local slider = self:CreateFlatSlider(row, 120, 18, min, max, value, pct)
  slider:SetPoint("LEFT", minT, "RIGHT", 8, 0)

  local maxT = self:CreateStyledText(row, pct and (max .. "%") or tostring(max), 10, COLORS.TEXT_MUTED, "OVERLAY", "")
  maxT:SetPoint("LEFT", slider, "RIGHT", 8, 0)

  local valT = self:CreateStyledText(row, "", 11, COLORS.TEXT_2, "OVERLAY", "")
  valT:SetPoint("LEFT", maxT, "RIGHT", 8, 0)
  valT:SetWidth(35)
  valT:SetJustifyH("CENTER")

  local function upd()
    local v = slider.slider:GetValue()
    if pct then valT:SetText(string.format("%.0f%%", v))
    else valT:SetText(string.format("%.0f", v)) end
  end

  slider.slider:SetScript("OnValueChanged", function(_, v)
    upd()
    AC:OnSliderValueChanged(slider, path, v)
  end)

  upd()
  return row
end

-- CreateGroup_SIZING moved to Core/Pages/ArenaFrames.lua

-- File: Core/UI.lua
-- Purpose: Constrain the label width to prevent overflow.

function AC:CreateCheckboxSetting(parent, label, y, path, checked)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", 20, y)
  row:SetPoint("TOPRIGHT", -20, y)
  row:SetHeight(26)

  local l = self:CreateStyledText(row, label, 12, COLORS.TEXT_2, "OVERLAY", "")
  l:SetPoint("LEFT", 0, 0)
  l:SetWidth(120) -- This new line fixes the overflow

  local box = self:CreateFlatCheckbox(row, 20, checked)
  box:SetPoint("RIGHT", -25, 0)

  box:SetScript("OnClick", function(selfBtn)
    AC:OnCheckboxToggle(box, path, selfBtn:GetChecked())
  end)

  return row
end

-- CreateTabRow moved to Core/Pages/ArenaFrames.lua

-- ====== EVENTS / HANDLERS ======

-- Map sidebar button label -> page key registered by Core/Pages/_Loader.lua
local NAV_TO_PAGE = {
  ["Arena Frames"]        = "ArenaFrames",
  ["Class Packs"]          = "classpacks",
  ["Trinkets/Other"]      = "trinketsother",
  ["Blackout"]             = "Blackout",
  ["Cast Bars"]           = "CastBars",
  ["Diminishing Returns"] = "DiminishingReturns",
  ["HP Bars & Textures"]  = "Textures",
  ["More Goodies"]        = "MoreGoodies",
  ["Frames/Nameplates"]    = "frames",
}

-- Visually toggle active nav state, then route to the right page
function AC:OnNavItemClick(btn, itemData)
  if self.sidebar then
    local function reset(f)
      for _, ch in ipairs({ f:GetChildren() }) do if ch.SetActive then ch:SetActive(false) end; reset(ch) end
    end
    reset(self.sidebar)
  end
  btn:SetActive(true); self.activeNavItem = btn
  
  local key = NAV_TO_PAGE[itemData.text]
  if key and AC.ShowPage then AC:ShowPage(key) end

  -- BRUTE-FORCE FIX for the stubborn purple background bug
  C_Timer.After(0.01, function()
    if btn and btn.isActive and btn.bg and btn.bg.SetColorTexture and COLORS and COLORS.NAV_ACTIVE_BG then
        local activeColor = COLORS.NAV_ACTIVE_BG
        btn.bg:SetColorTexture(activeColor[1], activeColor[2], activeColor[3], 1)
    end
  end)
end

function AC:OnTabClick(_, label)
  self.db = self.db or {}
  self.db.ui = self.db.ui or {}
  self.db.ui.selectedTab = label
  print("|cff8B45FFArenaCore:|r Switched to " .. label .. " tab")
end

-- Update these functions around line 1200 in UI.lua:

function AC:OnSliderValueChanged(slider, path, value)
  -- PROFILE EDIT MODE: Skip direct database writes if in edit mode
  if not AC.profileEditModeActive then
    self.db = self.db or {}
    local keys, cur = {}, self.db
    for k in string.gmatch(path, "([^%.]+)") do table.insert(keys, k) end
    for i = 1, #keys - 1 do cur[keys[i]] = cur[keys[i]] or {}; cur = cur[keys[i]] end
    cur[keys[#keys]] = value
  else
    -- In edit mode: buffer the change instead
    if AC.tempProfileBuffer then
      AC.tempProfileBuffer[path] = value
    end
  end
  
  -- Arena Frames slider changes now handled by Core/Pages/ArenaFrames.lua
end

-- File: Core/UI.lua
-- Purpose: Update the checkbox handler to refresh general settings.

-- File: Core/UI.lua
-- Purpose: Add diagnostic messages to track checkbox clicks and data saving.

-- File: Core/UI.lua
-- Purpose: Corrected to save directly to the master database table.

function AC:OnCheckboxToggle(checkbox, path, checked)
  if not AC.DB or not AC.DB.profile then return end

  -- PROFILE EDIT MODE: Skip direct database writes if in edit mode
  if not AC.profileEditModeActive then
    -- This is the fix: we now use AC.DB.profile as the starting point
    local keys, cur = {}, AC.DB.profile
    for k in string.gmatch(path, "([^%.]+)") do table.insert(keys, k) end
    for i = 1, #keys - 1 do cur[keys[i]] = cur[keys[i]] or {}; cur = cur[keys[i]] end
    cur[keys[#keys]] = checked
  else
    -- In edit mode: buffer the change instead
    if AC.tempProfileBuffer then
      AC.tempProfileBuffer[path] = checked
    end
  end

  -- Arena Frames checkbox changes now handled by Core/Pages/ArenaFrames.lua
end
-- Refresh the config UI to show updated values
function AC:RefreshConfigUI()
  -- Close and reopen the config panel to refresh all values
  if self.configFrame then
    local wasShown = self.configFrame:IsShown()
    self.configFrame:Hide()
    if wasShown then
      C_Timer.After(0.1, function()
        self.configFrame:Show()
      end)
    end
  end
end

function AC:OpenConfigPanel(toggle)
  -- Create the UI only if it doesn't exist yet.
  if not self.configFrame then
    self:CreateConfigUI()
    
    -- CRITICAL FIX: Ensure all FontStrings have fonts after UI creation
    if self.EnsureUIFontObjects then
      self:EnsureUIFontObjects()
    end
    if self.FixUIFontsRecursively and self.configFrame then
      C_Timer.After(0.2, function()
        -- Pass the actual UI frame, not the AC table
        AC.FixUIFontsRecursively(AC.configFrame)
      end)
    end
  end
  if toggle then
    local shouldShow = not self.configFrame:IsShown()
    self.configFrame:SetShown(shouldShow)
    
    -- CRITICAL FIX: Auto-hide test frames when closing UI via /arena command
    -- This matches the X button behavior for consistent UX
    if not shouldShow then
      -- UI is being closed
      if AC.FrameManager then
        AC.FrameManager:DisableTestMode()
        print("|cff8B45FFArena Core:|r Test frames auto-hidden on UI close.")
      end
    end
    
    -- Set UI visibility state
    self.IsUIVisible = shouldShow
    if shouldShow then
      self.currentPage = self.__currentPage or "ArenaFrames"
    end
  else
    self.configFrame:Show()
    -- Set UI visibility state
    self.IsUIVisible = true
    self.currentPage = self.__currentPage or "ArenaFrames"
    
    -- Apply Z-order policy when panel shows
    if self.ZPolicy then
      self.ZPolicy:OnPanelShow()
    end
  end
end

--- ====== DEDICATED SLASH COMMANDS (NO UI CONFLICT) ======

-- Reset visuals only (positioning/sizing)
SLASH_ACRESETVISUALS1 = "/acresetvisuals"
SLASH_ACRESETVISUALS2 = "/acvisualreset"
SlashCmdList.ACRESETVISUALS = function()
  if _G.ArenaCore and _G.ArenaCore.ResetVisualsOnly then
    _G.ArenaCore:ResetVisualsOnly()
  end
end

-- Simulate fresh install
SLASH_ACFRESHINSTALL1 = "/acfreshinstall"
SLASH_ACFRESHINSTALL2 = "/acfresh"
SlashCmdList.ACFRESHINSTALL = function()
  if _G.ArenaCore and _G.ArenaCore.SimulateFreshInstall then
    _G.ArenaCore:SimulateFreshInstall()
  end
end

--- ====== MAIN SLASH COMMANDS ======
SLASH_ARENACORE1 = "/arena"
SLASH_ARENACORE2 = "/arenacore"
SLASH_ARENACORE3 = "/acf"
SlashCmdList.ARENACORE = function(msg)
  -- Check for special commands first
  if msg and msg ~= "" then
    msg = msg:lower():match("^%s*(.-)%s*$")
    
    -- Beta preset command
    if msg == "betapreset" or msg == "preset" then
      if _G.ArenaCore and _G.ArenaCore.ApplyBetaPreset then
        _G.ArenaCore:ApplyBetaPreset()
        return
      end
    end
    
    -- Export Blackout spells command
    if msg == "exportblackout" or msg == "blackoutexport" then
      if _G.ArenaCore and _G.ArenaCore.ExportBlackoutToDefaults then
        _G.ArenaCore:ExportBlackoutToDefaults()
        return
      end
    end
    
    -- Add Blackout spells command
    if msg == "addblackoutspells" or msg == "blackoutspells" then
      if _G.ArenaCore and _G.ArenaCore.AddDefaultBlackoutSpells then
        _G.ArenaCore:AddDefaultBlackoutSpells()
        return
      end
    end
    
    -- PHASE 1.2: Check active tickers command
    if msg == "tickers" or msg == "checktickers" then
      if _G.ArenaCore and _G.ArenaCore.CheckActiveTickers then
        _G.ArenaCore:CheckActiveTickers()
        return
      end
    end
    
    -- PHASE 2.3: Check active event frames command
    if msg == "events" or msg == "checkevents" then
      if _G.ArenaCore and _G.ArenaCore.CheckActiveEventFrames then
        _G.ArenaCore:CheckActiveEventFrames()
        return
      end
    end
    
    -- PHASE 2.3: Manual cleanup command
    if msg == "cleanup" then
      if _G.ArenaCore and _G.ArenaCore.Cleanup then
        _G.ArenaCore:Cleanup()
        return
      end
    end
    
    -- NEW: Simulate fresh install - EXACT same process as first-time users
    if msg == "freshinstall" or msg == "fresh" or msg == "newuser" then
      if _G.ArenaCore and _G.ArenaCore.SimulateFreshInstall then
        _G.ArenaCore:SimulateFreshInstall()
        return
      end
    end
    
    -- NEW: Reset ONLY visual positioning/sizing (Arena Core theme defaults)
    if msg == "resetvisuals" or msg == "visualreset" or msg == "resetpositions" then
      if _G.ArenaCore and _G.ArenaCore.ResetVisualsOnly then
        _G.ArenaCore:ResetVisualsOnly()
        return
      end
    end
    
    -- Other special commands can go here
  end
  
  -- Default: Open UI
  local toggle = true
  if type(msg) == "string" and msg:lower():find("show") then
      toggle = false
  end
  AC:OpenConfigPanel(toggle)
end