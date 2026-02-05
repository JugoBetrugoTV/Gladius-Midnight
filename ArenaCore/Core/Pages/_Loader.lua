-- ============================================================================
-- File: ArenaCore/Core/Pages/_Loader.lua - v8.0 RENAMED
-- Purpose: Robust page system; compatible CreateFlatTexture; no UI spam.
-- ============================================================================

local addonName, _ns = ...
if type(_G.ArenaCore) ~= "table" then _G.ArenaCore = {} end
local addon = _G.ArenaCore

addon.Pages         = addon.Pages         or {}
-- CRITICAL FIX: Always start with fresh page cache on reload
-- This ensures pages rebuild properly after any code changes
addon.__pageFrames  = {}
addon.__currentPage = nil

addon.COLORS = addon.COLORS or {
  PRIMARY      = {0.545, 0.271, 1.000, 1},
  TEXT         = {1,1,1,1},
  TEXT_2       = {0.706,0.706,0.706,1},
  BORDER       = {0.196,0.196,0.196,1},
  BORDER_LIGHT = {0.278,0.278,0.278,1},
  -- INPUT_DARK removed - using centralized definition from UI.lua
}


-- Shared mini‑scaffold: vanity section frame
function addon:CreateVanitySection(parent, title)
  local C = self.COLORS or {}
  local section = CreateFrame("Frame", nil, parent)

  -- Check if the motto strip from UI.Vanity.lua exists on this page
  if parent._mottoStrip and parent._mottoStrip:IsShown() then
    -- If it exists, anchor the section frame below it with padding
    section:SetPoint("TOPLEFT", parent._mottoStrip, "BOTTOMLEFT", 0, -8)
  else
    -- Fallback to the original positioning if there's no motto strip
    section:SetPoint("TOPLEFT", 8, -44)
  end
  
  section:SetPoint("BOTTOMRIGHT", -8, 8)

  local border = self:CreateFlatTexture(section, "BACKGROUND", 0, C.BORDER_LIGHT or {0.278,0.278,0.278,1}, 0.9)
  border:SetAllPoints()
  local bg = self:CreateFlatTexture(section, "BACKGROUND", 1, self.COLORS.INPUT_DARK or {0.102,0.102,0.102,1}, 1)
  bg:SetPoint("TOPLEFT", 1, -1); bg:SetPoint("BOTTOMRIGHT", -1, 1)
  local accent = self:CreateFlatTexture(section, "OVERLAY", 1, C.PRIMARY or {0.545,0.271,1.0,1}, 0.95)
  accent:SetPoint("TOPLEFT", 0, 0); accent:SetPoint("TOPRIGHT", 0, 0); accent:SetHeight(2)

  local fs = section:CreateFontString(nil, "OVERLAY")
  -- CRITICAL FIX: Use double backslashes and SafeSetFont
  local fontPath = (self.CUSTOM_FONT) or "Interface\\\\AddOns\\\\ArenaCore\\\\Media\\\\Fonts\\\\arenacore.ttf"
  if AC and AC.SafeSetFont then
    AC.SafeSetFont(fs, fontPath, 12, "")
  elseif not fs:SetFont(fontPath, 12, "") then
    fs:SetFont(STANDARD_TEXT_FONT, 12, "")
  end
  fs:SetText(title or ""); fs:SetTextColor((C.PRIMARY and C.PRIMARY[1]) or 0.545, (C.PRIMARY and C.PRIMARY[2]) or 0.271, (C.PRIMARY and C.PRIMARY[3]) or 1.0, 1)
  fs:SetPoint("TOPLEFT", 12, -10)
  section._title = fs
  return section
end

-- Registry
function addon:RegisterPage(name, builder)
  -- Registering page with builder
  if type(name) ~= "string" or type(builder) ~= "function" then 
    -- Invalid registration parameters
    return 
  end
  self.Pages[name] = builder
  -- Page registered successfully
end

-- Display
-- File: ArenaCore/Core/Pages/_Loader.lua
-- Purpose: A more defensive version of ShowPage to fix the parenting bug.

function addon:ShowPage(name)
  -- ShowPage called for page navigation
  -- The Fix: Explicitly reference the master contentBox from the global addon table
  -- to prevent any scope or 'self' issues.
  local contentBox = _G.ArenaCore.contentBox
  -- ShowPage function called
  if not contentBox then 
    -- Error: contentBox is nil
    return 
  end
  if addon.__currentPage == name then 
    -- Already on requested page
    return 
  end

  -- Showing requested page

  -- Hide all direct children in the content box
  local children = { contentBox:GetChildren() }
  for _, ch in ipairs(children) do if ch and ch.Hide then ch:Hide() end end

  -- Hide previous modular page
  if addon.__currentPage and addon.__pageFrames[addon.__currentPage] then
    addon.__pageFrames[addon.__currentPage]:Hide()
  end
  
  -- CRITICAL FIX: Close all open dropdown menus when switching pages
  -- Dropdowns are parented to UIParent, so they don't auto-hide with page frames
  if addon.openDropdowns then
    for _, dropdown in ipairs(addon.openDropdowns) do
      if dropdown.menu and dropdown.menu:IsShown() then
        dropdown.menu:Hide()
      end
    end
  end
  
-- RESET SCROLL POSITION: Always start each page at the top
  if _G.ArenaCore.contentArea then
    _G.ArenaCore.contentArea:SetVerticalScroll(0)
  end
  if _G.ArenaCore.scrollbar then
    _G.ArenaCore.scrollbar:SetValue(0)
  end
  -- Build page once
  local frame = addon.__pageFrames[name]
  
  -- CRITICAL FIX: Check if cached page is empty (failed to build due to previous error)
  -- If the frame has no children, it means the builder failed - force rebuild
  local needsRebuild = false
  if frame then
    local children = { frame:GetChildren() }
    if #children == 0 then
      needsRebuild = true
      frame:Hide()
      frame = nil
      addon.__pageFrames[name] = nil
    end
  end
  
  -- Checking for cached frame
  if not frame then
    -- Creating new page frame
    -- Create the new page with the guaranteed-correct parent
    frame = CreateFrame("Frame", nil, contentBox)
    frame:SetPoint("TOPLEFT", 0, 0)
    frame:SetPoint("BOTTOMRIGHT", 0, 0)
    frame:Hide()

    local builder = addon.Pages[name]
    if builder then
      -- Wrap in pcall to catch any errors during page build
      local success, err = pcall(function()
        builder(frame)
      end)
      if not success then
        print("|cffFF0000ArenaCore:|r Error building page '" .. name .. "': " .. tostring(err))
      end
    else
      local placeholder = frame:CreateFontString(nil, "OVERLAY")
      placeholder:SetFont(STANDARD_TEXT_FONT, 14, "")
      placeholder:SetText("Page '" .. name .. "' not implemented yet")
      placeholder:SetTextColor(1, 1, 1, 1)
      placeholder:SetPoint("CENTER")
    end

    addon.__pageFrames[name] = frame
  else
    -- Reusing cached frame
  end

  frame:Show()
  addon.__currentPage = name
  
  -- Refresh theme after page change (fixes light gray content area)
  if addon.ThemeManager and addon.ThemeManager.RefreshMainUI then
    -- Multiple refreshes to catch dynamically created elements
    C_Timer.After(0.05, function()
      addon.ThemeManager:RefreshMainUI()
    end)
    C_Timer.After(0.15, function()
      addon.ThemeManager:RefreshMainUI()
    end)
    C_Timer.After(0.30, function()
      addon.ThemeManager:RefreshMainUI()
    end)
    -- Final refresh to ensure gradients stick
    C_Timer.After(0.50, function()
      addon.ThemeManager:RefreshMainUI()
    end)
  end
  
  -- Add motto bar to the page (rotating text)
  if addon.Vanity and addon.Vanity.EnsureMottoStrip then
    addon.Vanity:EnsureMottoStrip(frame)
  end
  
  -- Page shown successfully
  -- Also set the global currentPage for compatibility
  addon.currentPage = name
  
  -- Update content height after showing the new page
  if _G.ArenaCore.UpdateContentHeight then
    C_Timer.After(0.1, _G.ArenaCore.UpdateContentHeight)
  end
end