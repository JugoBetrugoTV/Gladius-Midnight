-- ============================================================================
-- File: ArenaCore/Core/UI.Features.lua
-- Purpose: UI/UX enhancement features for ArenaCore
-- Contains: Resizable UI, and future UI/UX improvements
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

-- ============================================================================
-- Resizable UI System
-- ============================================================================

local UIFeatures = {}
AC.UIFeatures = UIFeatures

-- Default and constraint values for UI scaling
local MIN_SCALE = 0.6
local MAX_SCALE = 1.4
local DEFAULT_SCALE = 1.0

-- Store original scale for reset functionality
local originalScale = DEFAULT_SCALE

-- ============================================================================
-- Resize Grip Creation
-- ============================================================================

local function CreateResizeGrip(parent, corner)
  local grip = CreateFrame("Frame", nil, parent)
  grip:SetSize(20, 20)
  grip:EnableMouse(true)
  
  -- Position based on corner
  if corner == "BOTTOMLEFT" then
    grip:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
  elseif corner == "BOTTOMRIGHT" then
    grip:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
  end
  
  -- Background (purple, matching Discord button style)
  local bg = grip:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.545, 0.271, 1.000, 1) -- ArenaCore PRIMARY purple
  
  -- Border (darker for depth, matching Discord button)
  local border = grip:CreateTexture(nil, "BORDER")
  border:SetPoint("TOPLEFT", 1, -1)
  border:SetPoint("BOTTOMRIGHT", -1, 1)
  border:SetColorTexture(0.4, 0.2, 0.7, 1)
  
  -- Create container frame for diagonal lines to keep them contained
  local lineContainer = CreateFrame("Frame", nil, grip)
  lineContainer:SetAllPoints()
  lineContainer:SetClipsChildren(true) -- CRITICAL: Keeps lines inside the box
  
  -- Add diagonal line pattern (contained within box)
  local line1 = lineContainer:CreateTexture(nil, "OVERLAY")
  line1:SetSize(14, 2)
  line1:SetColorTexture(1, 1, 1, 0.6) -- White lines for contrast
  line1:SetPoint("BOTTOMLEFT", lineContainer, "BOTTOMLEFT", 3, 4)
  line1:SetRotation(math.rad(45))
  
  local line2 = lineContainer:CreateTexture(nil, "OVERLAY")
  line2:SetSize(14, 2)
  line2:SetColorTexture(1, 1, 1, 0.6)
  line2:SetPoint("BOTTOMLEFT", lineContainer, "BOTTOMLEFT", 3, 9)
  line2:SetRotation(math.rad(45))
  
  local line3 = lineContainer:CreateTexture(nil, "OVERLAY")
  line3:SetSize(14, 2)
  line3:SetColorTexture(1, 1, 1, 0.6)
  line3:SetPoint("BOTTOMLEFT", lineContainer, "BOTTOMLEFT", 3, 14)
  line3:SetRotation(math.rad(45))
  
  -- Hover effect (matching Discord button)
  grip:SetScript("OnEnter", function()
    bg:SetColorTexture(0.645, 0.371, 1.000, 1) -- Lighter purple
    line1:SetColorTexture(1, 1, 1, 0.9)
    line2:SetColorTexture(1, 1, 1, 0.9)
    line3:SetColorTexture(1, 1, 1, 0.9)
  end)
  
  grip:SetScript("OnLeave", function()
    bg:SetColorTexture(0.545, 0.271, 1.000, 1) -- Original purple
    line1:SetColorTexture(1, 1, 1, 0.6)
    line2:SetColorTexture(1, 1, 1, 0.6)
    line3:SetColorTexture(1, 1, 1, 0.6)
  end)
  
  return grip
end

-- ============================================================================
-- Resize Logic
-- ============================================================================

local function SetupResizing(frame, dbKey)
  if not frame then return end
  
  -- Use custom database key or default to "uiScale"
  local scaleKey = dbKey or "uiScale"
  
  -- Create resize grips
  local gripBL = CreateResizeGrip(frame, "BOTTOMLEFT")
  local gripBR = CreateResizeGrip(frame, "BOTTOMRIGHT")
  
  -- Store grips for later access
  frame._resizeGripBL = gripBL
  frame._resizeGripBR = gripBR
  
  -- Resize state tracking
  local isResizing = false
  local startScale
  local startX, startY
  
  -- Helper function to update scale based on mouse movement
  local function UpdateScale()
    if not isResizing then return end
    
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    
    -- Calculate distance moved (use horizontal movement for scale)
    local deltaX = (cursorX - startX) / uiScale
    
    -- Convert distance to scale change (100 pixels = 0.1 scale change)
    local scaleChange = deltaX / 1000
    local newScale = startScale + scaleChange
    
    -- Clamp to min/max
    if newScale < MIN_SCALE then newScale = MIN_SCALE end
    if newScale > MAX_SCALE then newScale = MAX_SCALE end
    
    -- Apply scale
    frame:SetScale(newScale)
  end
  
  -- Bottom-left corner resize
  gripBL:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      isResizing = true
      startScale = frame:GetScale()
      startX, startY = GetCursorPosition()
      self:SetScript("OnUpdate", UpdateScale)
    end
  end)
  
  gripBL:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and isResizing then
      isResizing = false
      self:SetScript("OnUpdate", nil)
      
      -- Save new scale to database using custom key
      if AC.DB and AC.DB.profile then
        AC.DB.profile[scaleKey] = frame:GetScale()
      end
    end
  end)
  
  -- Bottom-right corner resize
  gripBR:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      isResizing = true
      startScale = frame:GetScale()
      startX, startY = GetCursorPosition()
      self:SetScript("OnUpdate", UpdateScale)
    end
  end)
  
  gripBR:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and isResizing then
      isResizing = false
      self:SetScript("OnUpdate", nil)
      
      -- Save new scale to database using custom key
      if AC.DB and AC.DB.profile then
        AC.DB.profile[scaleKey] = frame:GetScale()
      end
    end
  end)
end

-- ============================================================================
-- Initialize Resizable UI
-- ============================================================================

function UIFeatures:EnableResizableUI(frame, dbKey)
  if not frame then
    print("|cffFF0000ArenaCore UI.Features:|r No frame provided for resizing")
    return
  end
  
  -- Use custom database key or default to "uiScale"
  local scaleKey = dbKey or "uiScale"
  
  -- Load saved scale from database
  if AC.DB and AC.DB.profile then
    local savedScale = AC.DB.profile[scaleKey] or DEFAULT_SCALE
    frame:SetScale(savedScale)
  else
    frame:SetScale(DEFAULT_SCALE)
  end
  
  -- Setup resizing functionality with custom database key
  SetupResizing(frame, scaleKey)
  
  print("|cff8B45FFArenaCore:|r Resizable UI enabled - drag bottom corners to scale")
end

-- ============================================================================
-- Reset UI Size
-- ============================================================================

function UIFeatures:ResetUISize(frame)
  if not frame then return end
  
  frame:SetScale(DEFAULT_SCALE)
  
  -- Save to database
  if AC.DB and AC.DB.profile then
    AC.DB.profile.uiScale = DEFAULT_SCALE
  end
  
  print("|cff8B45FFArenaCore:|r UI scale reset to default")
end

-- ============================================================================
-- Get Current UI Size
-- ============================================================================

function UIFeatures:GetUIScale()
  if AC.DB and AC.DB.profile then
    return AC.DB.profile.uiScale or DEFAULT_SCALE
  end
  return DEFAULT_SCALE
end

-- ============================================================================
-- Future UI/UX Features Can Be Added Below
-- ============================================================================

-- Example: Snap-to-grid positioning
-- Example: UI presets (compact, normal, large)
-- Example: Custom UI themes/skins
-- Example: Dockable panels
-- Example: Collapsible sections

-- Module loaded silently
