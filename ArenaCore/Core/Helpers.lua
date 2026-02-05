-- Core/Helpers.lua
-- Shared helper functions (UI + util) - COMPLETE & CONSOLIDATED

if type(_G.ArenaCore) ~= "table" then _G.ArenaCore = {} end
local addon = _G.ArenaCore

-- Clamp to safe sublevels
local function _clamp(n)
  n = tonumber(n) or 0
  if n > 7 then return 7 elseif n < -8 then return -8 else return math.floor(n) end
end

-- Flat texture
function addon:CreateFlatTexture(parent, layer, sublevel, color, alpha)
  if not parent then return end
  local lvl = _clamp(sublevel or 0)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, lvl)
  local c = color or {0.1, 0.1, 0.1, 1}
  local a = alpha or c[4] or 1
  t:SetColorTexture(c[1], c[2], c[3], a)
  return t
end

-- Styled text - COMPLETELY SELF-SUFFICIENT VERSION
function addon:CreateStyledText(parent, text, size, color, layer, flags)
  local fs = parent:CreateFontString(nil, layer or "OVERLAY")
  
  -- CRITICAL FIX: Use FORWARD slashes (WoW prefers these over backslashes)
  local worked = fs:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", size or 12, flags or "")
  
  -- If that failed, fallback to WoW default
  if not worked then
    fs:SetFont("Fonts\\\\FRIZQT__.TTF", size or 12, flags or "")
  end
  
  fs:SetText(text or "")
  if color then
    if type(color) == "table" then
      fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end
  else
    fs:SetTextColor(1, 1, 1, 1)
  end
  return fs
end

-- Flat button
function addon:CreateFlatButton(parent, w, h, label, c, hoverC)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  local normal = self:CreateFlatTexture(b, "BACKGROUND", 0, c or {0.2, 0.2, 0.2, 1}, 1)
  normal:SetAllPoints()
  local hover = self:CreateFlatTexture(b, "BACKGROUND", 1, hoverC or {0.3, 0.3, 0.3, 1}, 1)
  hover:SetAllPoints()
  hover:Hide()
  b:SetScript("OnEnter", function() hover:Show() end)
  b:SetScript("OnLeave", function() hover:Hide() end)
  b.text = self:CreateStyledText(b, label or "", 12, {1,1,1,1}, "OVERLAY", "")
  b.text:SetPoint("CENTER")
  return b
end

-- **SLIDER CONVERSION FUNCTIONS**
function addon:ConvertPixelsToScale(pixels, minPixel, maxPixel, scaleMin, scaleMax)
  scaleMin = scaleMin or 1
  scaleMax = scaleMax or 10
  
  -- Clamp pixels to valid range
  pixels = math.max(minPixel, math.min(maxPixel, pixels))
  
  -- Convert to 0-1 ratio, then to scale range
  local ratio = (pixels - minPixel) / (maxPixel - minPixel)
  local scale = scaleMin + (ratio * (scaleMax - scaleMin))
  
  -- CRITICAL FIX: NO ROUNDING! Return exact floating-point value
  -- Rounding causes drift: 202.4 becomes 202, losing 0.4 pixels
  return scale
end

function addon:ConvertScaleToPixels(scale, minPixel, maxPixel, scaleMin, scaleMax)
  scaleMin = scaleMin or 1
  scaleMax = scaleMax or 10
  
  -- Clamp scale to valid range
  scale = math.max(scaleMin, math.min(scaleMax, scale))
  
  -- Convert to 0-1 ratio, then to pixel range
  local ratio = (scale - scaleMin) / (scaleMax - scaleMin)
  local pixels = minPixel + (ratio * (maxPixel - minPixel))
  
  -- NO ROUNDING - return exact value
  -- WoW will handle pixel alignment internally
  return pixels
end

-- **THE NEW MASTER SLIDER FUNCTION**
function addon:CreateFlatSlider(parent, w, h, min, max, val, isPct, onChange)
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(w, h)

  -- Add enhanced track background for better visibility (use COLORS table)
  local trackColor = addon.COLORS and addon.COLORS.INPUT_DARK or {0.102, 0.102, 0.102, 1}
  local trackBg = self:CreateFlatTexture(container, "BACKGROUND", 1, trackColor, 1)
  trackBg:SetAllPoints()
  
  -- Add visible slider rail/bar for better clarity (use COLORS table)
  local railColor = addon.COLORS and addon.COLORS.BORDER or {0.196, 0.196, 0.196, 1}
  local sliderRail = self:CreateFlatTexture(container, "BACKGROUND", 2, railColor, 1)
  sliderRail:SetPoint("TOPLEFT", 2, -math.floor(h/2) + 1)
  sliderRail:SetPoint("TOPRIGHT", -2, -math.floor(h/2) + 1)
  sliderRail:SetHeight(2) -- Thin horizontal line
  
  -- Add rail border for definition (use COLORS table)
  local borderColor = addon.COLORS and addon.COLORS.BORDER_LIGHT or {0.278, 0.278, 0.278, 1}
  local railBorder = self:CreateFlatTexture(container, "BACKGROUND", 3, borderColor, 1)
  railBorder:SetPoint("TOPLEFT", sliderRail, "TOPLEFT", -1, 1)
  railBorder:SetPoint("BOTTOMRIGHT", sliderRail, "BOTTOMRIGHT", 1, -1)
  railBorder:SetHeight(4) -- Slightly taller for border effect

  local slider = CreateFrame("Slider", nil, container)
  slider:SetPoint("TOPLEFT", 2, -2)
  slider:SetPoint("BOTTOMRIGHT", -2, 2)
  slider:SetOrientation("HORIZONTAL")
  -- Ensure min <= max before setting values
  if min > max then
    local temp = min
    min = max
    max = temp
  end
  slider:SetMinMaxValues(min, max)
  -- Clamp value to valid range
  local clampedVal = val or min
  if type(clampedVal) ~= "number" then clampedVal = min end
  if clampedVal < min then clampedVal = min end
  if clampedVal > max then clampedVal = max end
  slider:SetValue(clampedVal)
  -- CRITICAL FIX: Allow decimal values for sub-pixel precision
  -- Old: SetValueStep(1) forced integer values, causing 202.4 to snap to 202
  -- New: SetValueStep(0.1) allows 0.1 precision (202.4 is preserved)
  slider:SetValueStep(isPct and 1 or 0.1)
  -- CRITICAL FIX: Disable ObeyStepOnDrag to allow free-form decimal values
  -- ObeyStepOnDrag forces snapping to step values, preventing 201.6 from being set
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(false) end

  -- Use custom compressed TGA texture for the thumb
  local thumbTexture = slider:CreateTexture(nil, "OVERLAY")
  thumbTexture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga")
  thumbTexture:SetSize(14, math.max(2, h - 2))
  slider:SetThumbTexture(thumbTexture)

  -- CRITICAL FIX: Wire up onChange callback if provided
  -- TrinketsOther.lua and other pages rely on this being connected!
  if onChange then
    slider:SetScript("OnValueChanged", function(self, value)
      onChange(value)
    end)
  end

  container.slider = slider
  return container
end

-- **SLIDER CONFIGURATION PRESETS**
-- NOTE: scaleMax increased to 800/600/500/400 for 1-pixel precision (each step = 1 pixel)
local SLIDER_CONFIGS = {
  positioning_horizontal = { scaleMin = 0, scaleMax = 3840, pixelMin = 0, pixelMax = 3840, tooltip = "Horizontal position - pixels from left edge (0 to 3840)" },
  positioning_vertical = { scaleMin = 0, scaleMax = 2160, pixelMin = 0, pixelMax = 2160, tooltip = "Vertical position - pixels from bottom edge (0 to 2160)" },
  -- Fine-tuned positioning for precise adjustments (increased range for cast bars and other elements)
  positioning_horizontal_fine = { scaleMin = -500, scaleMax = 500, pixelMin = -500, pixelMax = 500, tooltip = "Horizontal positioning with 1-pixel precision (-500px to +500px)" },
  positioning_vertical_fine = { scaleMin = -400, scaleMax = 400, pixelMin = -400, pixelMax = 400, tooltip = "Vertical positioning with 1-pixel precision (-400px to +400px)" },
  -- Ultra-fine precision for trinkets/racials/spec icons (1-pixel precision)
  positioning_horizontal_ultra = { scaleMin = -400, scaleMax = 400, pixelMin = -400, pixelMax = 400, tooltip = "Horizontal positioning with 1-pixel precision (-400px to +400px)" },
  positioning_vertical_ultra = { scaleMin = -400, scaleMax = 400, pixelMin = -400, pixelMax = 400, tooltip = "Vertical positioning with 1-pixel precision (-400px to +400px)" },
  -- Ultra-fine precision for text positioning (names, arena numbers)
  text_positioning_horizontal = { scaleMin = -200, scaleMax = 200, pixelMin = -200, pixelMax = 200, tooltip = "Text horizontal positioning with 1-pixel precision (-200px to +200px)" },
  text_positioning_vertical = { scaleMin = -100, scaleMax = 100, pixelMin = -100, pixelMax = 100, tooltip = "Text vertical positioning with 1-pixel precision (-100px to +100px)" },
  -- Ultra-fine precision for arena numbers (1-pixel precision)
  arena_number_horizontal = { scaleMin = -400, scaleMax = 400, pixelMin = -400, pixelMax = 400, tooltip = "Arena number horizontal positioning with 1-pixel precision (-400px to +400px)" },
  arena_number_vertical = { scaleMin = -200, scaleMax = 200, pixelMin = -200, pixelMax = 200, tooltip = "Arena number vertical positioning with 1-pixel precision (-200px to +200px)" },
  -- Ultra-fine precision for text scaling (1% increments)
  text_scaling_ultra = { scaleMin = 60, scaleMax = 140, pixelMin = 60, pixelMax = 140, tooltip = "Text scaling with 1% precision (60% to 140%)", isPercent = true },
  -- Ultra-fine precision for texture/bar positioning (1-pixel precision)
  texture_positioning_horizontal = { scaleMin = -100, scaleMax = 100, pixelMin = -100, pixelMax = 100, tooltip = "Bar horizontal positioning with 1-pixel precision (-100px to +100px)" },
  texture_positioning_vertical = { scaleMin = -50, scaleMax = 50, pixelMin = -50, pixelMax = 50, tooltip = "Bar vertical positioning with 1-pixel precision (-50px to +50px)" },
  texture_spacing_ultra = { scaleMin = 0, scaleMax = 20, pixelMin = 0, pixelMax = 20, tooltip = "Bar spacing with 1-pixel precision (0px to 20px)" },
  -- Ultra-fine precision for DR positioning (5-pixel steps for smooth dragging) - MAXIMUM RANGE
  dr_positioning_horizontal = { scaleMin = -1500, scaleMax = 1500, pixelMin = -1500, pixelMax = 1500, valueStep = 5, tooltip = "DR horizontal positioning with smooth 5-pixel steps (-1500px to +1500px) - Position anywhere on screen!" },
  dr_positioning_vertical = { scaleMin = -1000, scaleMax = 1000, pixelMin = -1000, pixelMax = 1000, valueStep = 5, tooltip = "DR vertical positioning with smooth 5-pixel steps (-1000px to +1000px) - Position anywhere on screen!" },
  sizing_scale = { scaleMin = 50, scaleMax = 300, pixelMin = 50, pixelMax = 300, tooltip = "Scale with 1% precision (50% to 300%)", isPercent = true },
  sizing_width = { scaleMin = 40, scaleMax = 400, pixelMin = 40, pixelMax = 400, tooltip = "Width with 1-pixel precision (40px to 400px)" },
  sizing_height = { scaleMin = 20, scaleMax = 100, pixelMin = 20, pixelMax = 100, tooltip = "Height with 1-pixel precision (20px to 100px)" },
  spacing = { scaleMin = 0, scaleMax = 50, pixelMin = 0, pixelMax = 50, tooltip = "Spacing with 1-pixel precision (0px to 50px)" },
  offset = { scaleMin = -200, scaleMax = 200, pixelMin = -200, pixelMax = 200, tooltip = "Offset with 1-pixel precision (-200px to +200px)" },
  tribadges_size = { scaleMin = 15, scaleMax = 38, pixelMin = 15, pixelMax = 38, tooltip = "TriBadges size with 1-pixel precision (15px to 38px)" },
  -- DR-specific configs with 1-pixel/1-point precision
  dr_size = { scaleMin = 22, scaleMax = 48, pixelMin = 22, pixelMax = 48, tooltip = "DR icon size with 1-pixel precision (22px to 48px)" },
  dr_font = { scaleMin = 8, scaleMax = 18, pixelMin = 8, pixelMax = 18, tooltip = "DR font size with 1-point precision (8pt to 18pt)" },
  -- Trinket/Racial font size with 1-point precision
  cooldown_font = { scaleMin = 6, scaleMax = 16, pixelMin = 6, pixelMax = 16, tooltip = "Cooldown font size with 1-point precision (6pt to 16pt)" },
  racial_font = { scaleMin = 4, scaleMax = 16, pixelMin = 4, pixelMax = 16, tooltip = "Racial font size with extra-small minimum (4pt to 16pt)" },
  dr_stage_font = { scaleMin = 7, scaleMax = 16, pixelMin = 7, pixelMax = 16, tooltip = "DR stage font size with 1-point precision (7pt to 16pt)" },
  -- Class icon border thickness (80% to 100% - physically shrinks overlay inward)
  border_thickness = { scaleMin = 80, scaleMax = 100, pixelMin = 80, pixelMax = 100, tooltip = "Border thickness: 100% = full border (default), 80% = thinner border", isPercent = true },
  -- Direct pixel offset (no scale conversion) - shows actual pixel values, 0 = center
  -- Uses integer steps to prevent floating point rounding drift on +/- buttons
  direct_pixel_offset = { scaleMin = -100, scaleMax = 100, pixelMin = -100, pixelMax = 100, valueStep = 1, tooltip = "Offset in pixels. 0 = centered/default position." }
}

-- **STREAMLINED ENHANCED SLIDER CREATOR**
function addon:CreateEnhancedSliderRow(parent, label, y, path, configType, customConfig)
  -- Use preset config or custom config
  local config = customConfig or SLIDER_CONFIGS[configType]
  if not config then
    print("|cffFF0000ERROR:|r Unknown slider config type: " .. tostring(configType))
    return nil
  end
  
  -- Get current value and convert to scale
  local AC = _G.ArenaCore
  local currentPixels = 0
  
  -- SPECIAL CASE: For arenaFrames.positioning.horizontal/vertical, read from THEME data (single source of truth)
  if path == "arenaFrames.positioning.horizontal" or path == "arenaFrames.positioning.vertical" then
    if AC.ArenaFrameThemes and AC.DB and AC.DB.profile then
      local currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
      if currentTheme and AC.DB.profile.themeData and AC.DB.profile.themeData[currentTheme] then
        local themeData = AC.DB.profile.themeData[currentTheme]
        if themeData.arenaFrames and themeData.arenaFrames.positioning then
          if path == "arenaFrames.positioning.horizontal" then
            currentPixels = themeData.arenaFrames.positioning.horizontal or 0
          else
            currentPixels = themeData.arenaFrames.positioning.vertical or 0
          end
        end
      end
    end
  else
    -- For all other sliders, use ProfileManager
    currentPixels = (AC.ProfileManager and AC.ProfileManager.GetSetting and AC.ProfileManager:GetSetting(path)) or 0
  end
  
  local currentScale = self:ConvertPixelsToScale(currentPixels, config.pixelMin, config.pixelMax, config.scaleMin, config.scaleMax)
  
  -- Create row
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", 20, y)
  row:SetPoint("TOPRIGHT", -20, y)
  row:SetHeight(26)
  row:EnableMouse(false) -- CRITICAL: Row should NOT block mouse input to child buttons
  row:SetFrameLevel(parent:GetFrameLevel() + 1)
  
  -- Create all elements with tighter positioning to fit in content boxes
  local COLORS = AC.COLORS or {}
  local labelText = self:CreateStyledText(row, label, 11, COLORS.TEXT_2 or {1, 1, 1, 1}, "OVERLAY", "")
  labelText:SetPoint("LEFT", 0, 0)
  labelText:SetWidth(85) -- Reduced from 100 to save space
  labelText:SetJustifyH("LEFT")
  
  local minText = self:CreateStyledText(row, tostring(config.scaleMin), 10, COLORS.TEXT_MUTED, "OVERLAY", "")
  minText:SetPoint("LEFT", labelText, "RIGHT", 6, 0) -- Reduced spacing from 10 to 6
  
  -- Down button
  local downBtn = self:CreateCompactButton(row, 16, "-")
  downBtn:SetPoint("LEFT", minText, "RIGHT", 4, 0) -- Reduced spacing from 8 to 4
  downBtn:SetFrameLevel(row:GetFrameLevel() + 10) -- CRITICAL: Ensure button is way above everything
  
  -- Enhanced slider (reduced width to fit better)
  local enhancedSlider = self:CreateEnhancedSlider(
    row, 100, 18, -- Reduced width from 120 to 100
    config.scaleMin, config.scaleMax, currentScale, label,
    config.pixelMin, config.pixelMax,
    function(pixels)
      -- Set flag to indicate this is a slider change (for smart positioning refresh)
      AC._isSliderChange = true
      
      -- CRITICAL FIX: Prevent class icon repositioning when moving player name sliders
      -- Set this flag BEFORE any refresh functions are called
      if path:match("playerNameX") or path:match("playerNameY") or 
         path:match("arenaNumberX") or path:match("arenaNumberY") or
         path:match("playerNameScale") or path:match("arenaNumberScale") then
        AC._skipClassIconReposition = true
      end
      
      -- SIMPLIFIED: Just save the position directly, no Edit Mode offsets
      -- The old Edit Mode base + offset system was causing drift
      local PM = AC.ProfileManager
      
      -- Just save the position directly
      if PM and PM.SetSetting and path then
        PM:SetSetting(path, pixels)
      end
      
      -- Check if this is a positioning path (horizontal/vertical) OR text positioning
      local isPositioning = path and (path:match("%.horizontal$") or path:match("%.vertical$"))
      local isTextPositioning = path and (path:match("playerNameX") or path:match("playerNameY") or 
                                          path:match("arenaNumberX") or path:match("arenaNumberY"))
      
      if (isPositioning or isTextPositioning) and path then
        -- ALSO save directly to database (bypass ProfileManager for immediate effect)
        
        -- Update database directly
        local pathParts = {}
        for part in string.gmatch(path, "[^%.]+") do
          table.insert(pathParts, part)
        end
        
        if #pathParts >= 1 then
          local current = AC.DB.profile
          for i = 1, #pathParts - 1 do
            if not current[pathParts[i]] then
              current[pathParts[i]] = {}
            end
            current = current[pathParts[i]]
          end
          current[pathParts[#pathParts]] = pixels
        end
        
        -- CRITICAL: ALSO write to theme data for theme-specific settings
        -- This ensures settings persist across reloads and aren't overwritten by theme defaults
        if path == "arenaFrames.positioning.horizontal" or path == "arenaFrames.positioning.vertical" or
           path == "arenaFrames.general.playerNameX" or path == "arenaFrames.general.playerNameY" or
           path == "arenaFrames.general.arenaNumberX" or path == "arenaFrames.general.arenaNumberY" then
          if AC.ArenaFrameThemes then
            local currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
            if currentTheme then
              AC.DB.profile.themeData = AC.DB.profile.themeData or {}
              AC.DB.profile.themeData[currentTheme] = AC.DB.profile.themeData[currentTheme] or {}
              local themeRoot = AC.DB.profile.themeData[currentTheme]
              themeRoot.arenaFrames = themeRoot.arenaFrames or {}
              
              if path == "arenaFrames.positioning.horizontal" then
                themeRoot.arenaFrames.positioning = themeRoot.arenaFrames.positioning or {}
                themeRoot.arenaFrames.positioning.horizontal = pixels
              elseif path == "arenaFrames.positioning.vertical" then
                themeRoot.arenaFrames.positioning = themeRoot.arenaFrames.positioning or {}
                themeRoot.arenaFrames.positioning.vertical = pixels
              else
                -- Text positioning (playerNameX/Y, arenaNumberX/Y)
                themeRoot.arenaFrames.general = themeRoot.arenaFrames.general or {}
                if path == "arenaFrames.general.playerNameX" then
                  themeRoot.arenaFrames.general.playerNameX = pixels
                elseif path == "arenaFrames.general.playerNameY" then
                  themeRoot.arenaFrames.general.playerNameY = pixels
                elseif path == "arenaFrames.general.arenaNumberX" then
                  themeRoot.arenaFrames.general.arenaNumberX = pixels
                elseif path == "arenaFrames.general.arenaNumberY" then
                  themeRoot.arenaFrames.general.arenaNumberY = pixels
                end
              end
            end
          end
        end
      end
      
      -- Non-positioning paths or fallback
      if not isPositioning then
        -- Non-positioning paths: use original logic
        -- CRITICAL FIX: Set flag to prevent ApplyArenaFramesSettings from being called
        -- for sizing changes (scale, width, height) - we handle those specifically below
        local isSizingPath = path:match("arenaFrames%.sizing%.")
        if isSizingPath then
          AC._skipArenaFramesApply = true
        end
        
        if PM and PM.SetSetting then
          PM:SetSetting(path, pixels)
        end
        
        if isSizingPath then
          AC._skipArenaFramesApply = false
        end
        if AC.FrameSystem and AC.FrameSystem.SetSetting then
          AC.FrameSystem:SetSetting(path, pixels)
        end
        
        local pathParts = {}
        for part in string.gmatch(path, "[^%.]+") do
          table.insert(pathParts, part)
        end
        
        if #pathParts >= 1 then
          local current = AC.DB.profile
          for i = 1, #pathParts - 1 do
            if not current[pathParts[i]] then
              current[pathParts[i]] = {}
            end
            current = current[pathParts[i]]
          end
          current[pathParts[#pathParts]] = pixels
          
          -- CRITICAL FIX: Clear old Edit Mode base positions when slider is used
          -- This prevents jumps caused by stale draggedBaseX/draggedBaseY values
          -- NOTE: Only remove draggedBaseX/Y - sliderOffsetX/Y are legitimate values!
          if path:match("%.positioning%.horizontal") or path:match("%.positioning%.vertical") then
            local positioningTable = AC.DB.profile
            for i = 1, #pathParts - 2 do
              positioningTable = positioningTable[pathParts[i]]
            end
            if positioningTable.positioning then
              positioningTable.positioning.draggedBaseX = nil
              positioningTable.positioning.draggedBaseY = nil
            end
          end
        end
        
        -- CRITICAL: ALSO save to theme-specific settings for theme isolation
        if AC.ArenaFrameThemes then
          local currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
          if currentTheme then
            -- Initialize theme data structure if needed
            AC.DB.profile.themeData = AC.DB.profile.themeData or {}
            AC.DB.profile.themeData[currentTheme] = AC.DB.profile.themeData[currentTheme] or {}
            local themeRoot = AC.DB.profile.themeData[currentTheme]

            -- SPECIAL CASE: arenaFrames.positioning.horizontal/vertical must always
            -- hit themeData[currentTheme].arenaFrames.positioning so MFM reads them.
            if path == "arenaFrames.positioning.horizontal" or path == "arenaFrames.positioning.vertical" then
              themeRoot.arenaFrames = themeRoot.arenaFrames or {}
              themeRoot.arenaFrames.positioning = themeRoot.arenaFrames.positioning or {}
              if path == "arenaFrames.positioning.horizontal" then
                themeRoot.arenaFrames.positioning.horizontal = pixels
                print("|cffFF00FF[SLIDER WRITE]|r Wrote horizontal=" .. tostring(pixels) .. " to theme: " .. tostring(currentTheme))
              else
                themeRoot.arenaFrames.positioning.vertical = pixels
                print("|cffFF00FF[SLIDER WRITE]|r Wrote vertical=" .. tostring(pixels) .. " to theme: " .. tostring(currentTheme))
              end
            else
              -- Generic path-based theme write for all other settings
              local themePathParts = {}
              for part in string.gmatch(path, "[^%.]+") do
                table.insert(themePathParts, part)
              end
              
              if #themePathParts >= 1 then
                local themeCurrent = themeRoot
                for i = 1, #themePathParts - 1 do
                  if not themeCurrent[themePathParts[i]] then
                    themeCurrent[themePathParts[i]] = {}
                  end
                  themeCurrent = themeCurrent[themePathParts[i]]
                end
                themeCurrent[themePathParts[#themePathParts]] = pixels
              end
            end

            -- CRITICAL FIX: Also clear Edit Mode values from theme-specific data
            -- NOTE: Only remove draggedBaseX/Y - sliderOffsetX/Y are legitimate values!
            if path:match("%.positioning%.horizontal") or path:match("%.positioning%.vertical") then
              local themePositioningTable = themeRoot
              local themePathParts = {}
              for part in string.gmatch(path, "[^%.]+") do
                table.insert(themePathParts, part)
              end
              for i = 1, #themePathParts - 2 do
                themePositioningTable = themePositioningTable[themePathParts[i]] or themePositioningTable
              end
              if themePositioningTable.positioning then
                themePositioningTable.positioning.draggedBaseX = nil
                themePositioningTable.positioning.draggedBaseY = nil
              end
            end
          end
        end
      end
      -- Trigger visual update based on path
      if path:match("arenaFrames%.") then
        -- SMART POSITIONING REFRESH - Allow slider changes but prevent manual save jumping
        if path:match("arenaFrames%.positioning%.") then
          -- Check if this is from a slider change (has _sliderChange flag) vs manual save
          if AC._isSliderChange then
            -- Allow refresh for slider changes (real-time preview)
            if AC.FrameManager and AC.FrameManager.ApplyPositioning then
              local db = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames
              if db and db.positioning then
                AC.FrameManager:ApplyPositioning(db.positioning)
                if AC.Debug then AC.Debug:Print("[HELPERS DEBUG] Applied positioning from slider change") end
              end
            end

            -- NEW: also run the unified master layout so sliders behave like drag
            if AC.UpdateFramePositioning then
              AC:UpdateFramePositioning()
            end
          else
            -- Skip refresh for manual saves to prevent jumping
            if AC.Debug then AC.Debug:Print("[HELPERS DEBUG] Skipping positioning refresh for manual save") end
          end
        elseif path:match("arenaFrames%.general%.") then
          -- CRITICAL FIX: Use lightweight text-only update for player name/arena number positioning
          -- Full ApplyGeneralSettings is too heavy and causes laggy sliders + class icon glitching
          if path:match("playerNameX") or path:match("playerNameY") or 
             path:match("arenaNumberX") or path:match("arenaNumberY") or
             path:match("playerNameScale") or path:match("arenaNumberScale") then
            -- CRITICAL: Set flag to prevent class icon repositioning during text updates
            -- This prevents class icons from jumping when moving player name sliders
            AC._skipClassIconReposition = true
            
            -- Text positioning/scaling only - lightweight, no side effects on other elements
            if AC.UpdateTextPositioningOnly then
              AC:UpdateTextPositioningOnly()
            end
            
            -- ALSO update scales for playerNameScale/arenaNumberScale
            if path:match("playerNameScale") or path:match("arenaNumberScale") then
              if AC.UpdateArenaNameNumberScalesOnly then
                AC:UpdateArenaNameNumberScalesOnly()
              end
            end
            
            -- Clear flag after a delay to catch any deferred refreshes
            C_Timer.After(0.1, function()
              AC._skipClassIconReposition = false
            end)
          elseif path:match("healthTextScale") or path:match("resourceTextScale") or path:match("spellTextScale") then
            -- Health/Resource/Spell text scale - use lightweight scale-only update
            if AC.UpdateArenaTextScalesOnly then
              AC:UpdateArenaTextScalesOnly()
            end
          else
            -- Other general settings (checkboxes, etc.) - use full refresh
            if AC.ApplyGeneralSettings then
              AC:ApplyGeneralSettings()
            end
          end
      elseif path:match("arenaFrames%.sizing%.") then
          -- CRITICAL FIX: Arena Frames SIZING settings (scale, width, height)
          -- DO NOT call RefreshDRLayout - it causes DR icons to jump/break
          -- Only update frame scale/size, not child element positioning
          
          -- CRITICAL FIX: Skip if we're in a save operation (Save Settings button)
          if AC._skipArenaFramesApply then
            if AC.Debug then AC.Debug:Print("[HELPERS DEBUG] Skipping sizing update during save operation") end
            return
          end
          
          if path:match("arenaFrames%.sizing%.scale") then
            if AC.UpdateFrameScale then
              AC:UpdateFrameScale()
            end
          elseif path:match("arenaFrames%.sizing%.width") or path:match("arenaFrames%.sizing%.height") then
            if AC.UpdateFrameSize then
              AC:UpdateFrameSize()
            end
          end
        else
          -- Other Arena Frames settings - use comprehensive refresh for non-positioning changes
          if AC.FrameManager and AC.FrameManager.RefreshFrames then
            AC.FrameManager:RefreshFrames()
          end
        end
      elseif path:match("classPacks%.") then
        -- CLASS PACKS REFRESH - Always allow for real-time TriBadges updates
        if AC._isSliderChange then
          -- CRITICAL FIX: Refresh in BOTH test mode and live arena (like other pages)
          if AC.RefreshClassPacksLayout then
            AC:RefreshClassPacksLayout()
          end
        end
      elseif path:match("trinkets%.") or path:match("specIcons%.") or path:match("racials%.") or path:match("classIcons%.") then
        -- TRINKETS/OTHER REFRESH - Always allow for real-time updates
        if AC._isSliderChange then
          -- CRITICAL FIX: Track which element is being changed to prevent cross-element jumping
          -- When trinket slider changes, don't reposition class icons (and vice versa)
          AC._currentSettingPath = path
          
          -- Refresh Trinkets/Other elements for slider changes
          if AC.RefreshTrinketsOtherLayout then
            AC:RefreshTrinketsOtherLayout()
            if AC.Debug then AC.Debug:Print("[HELPERS DEBUG] Applied Trinkets/Other refresh from slider change") end
          end
          
          -- Clear the flag after refresh
          AC._currentSettingPath = nil
        end
      elseif path:match("castBars%.") then
        -- CAST BARS REFRESH - Always allow for real-time updates
        -- Refresh Cast Bars for any changes (slider, checkbox, etc.)
        
        -- CRITICAL: Call CastBars module RefreshLayout for Midnight cast bars
        if AC.CastBars and AC.CastBars.RefreshLayout then
          AC.CastBars:RefreshLayout()
        end
        
        -- Also call legacy RefreshCastBarsLayout for compatibility
        if AC.RefreshCastBarsLayout then
          AC:RefreshCastBarsLayout()
        end
      elseif path:match("diminishingReturns%.") then
        -- DIMINISHING RETURNS REFRESH - Always allow for real-time updates
        -- Refresh DR for any changes (slider, checkbox, etc.)
        if AC.RefreshDRLayout then
          AC:RefreshDRLayout()
        end
      elseif path:match("textures%.") then
        -- TEXTURES REFRESH - Handle all textures page changes with immediate refresh
        if AC.RefreshTexturesLayout then
          -- Skip texture updates for positioning and sizing to prevent bar flash
          local skipTextureUpdate = path:match("textures%.positioning%.") or path:match("textures%.sizing%.")
          AC:RefreshTexturesLayout(skipTextureUpdate)
          if AC.Debug then AC.Debug:Print("[HELPERS DEBUG] Applied Textures refresh for path: " .. path) end
        end
      elseif path:match("positioning") or path:match("sizing") then
        -- ARENA FRAMES POSITIONING/SIZING REFRESH
        if AC.FrameManager and AC.FrameManager.ApplyPositioning then
          local db = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames
          if db and db.positioning then
            AC.FrameManager:ApplyPositioning(db.positioning)
          end
        end
      end
      
      -- NOTE: Theme save removed - it's handled when drag ends (line ~712)
      -- Saving on every slider change causes spam and performance issues
      
      -- Clear the slider change flag after processing
      AC._isSliderChange = false
    end,
    config.tooltip,
    config.valueStep -- Pass valueStep for smooth DR positioning
  )
  enhancedSlider:SetPoint("LEFT", downBtn, "RIGHT", 4, 0)
  
  -- Up button
  local upBtn = self:CreateCompactButton(row, 16, "+")
  upBtn:SetPoint("LEFT", enhancedSlider, "RIGHT", 4, 0)
  upBtn:SetFrameLevel(row:GetFrameLevel() + 10) -- CRITICAL: Ensure button is way above everything
  
  -- Max text (reduced spacing)
  local maxText = self:CreateStyledText(row, tostring(config.scaleMax), 10, COLORS.TEXT_MUTED, "OVERLAY", "")
  maxText:SetPoint("LEFT", upBtn, "RIGHT", 4, 0) -- Reduced spacing from 6 to 4
  
  -- Button handlers (SMART STEP SIZE: Adjusts based on pixel range for optimal control)
  -- Use config.valueStep if provided (for DR positioning), otherwise calculate dynamically
  local stepSize
  if config.valueStep then
    -- Use the same step size as the slider for consistency (DR positioning)
    stepSize = config.valueStep
  else
    -- Calculate appropriate step size based on total pixel range
    local totalPixels = math.abs(config.pixelMax - config.pixelMin)
    local scaleRange = config.scaleMax - config.scaleMin
    local pixelsPerScaleUnit = totalPixels / scaleRange
    
    -- Target 6 pixels per click - middle ground between visible and precise
    local targetPixelsPerClick = 6
    stepSize = targetPixelsPerClick / pixelsPerScaleUnit
    
    -- Clamp step size between 0.04 (very fine) and 0.4 (moderate)
    stepSize = math.max(0.04, math.min(0.4, stepSize))
  end
  
  -- Store direct slider reference for button handlers
  local sliderWidget = enhancedSlider.slider
  
  downBtn:SetScript("OnClick", function()
    if not sliderWidget then return end
    local currentVal = sliderWidget:GetValue()
    local newVal = math.max(config.scaleMin, currentVal - stepSize)
    sliderWidget:SetValue(newVal)
  end)
  
  upBtn:SetScript("OnClick", function()
    if not sliderWidget then return end
    local currentVal = sliderWidget:GetValue()
    local newVal = math.min(config.scaleMax, currentVal + stepSize)
    sliderWidget:SetValue(newVal)
  end)
  
  -- Store reference
  if not AC.sliderWidgets then AC.sliderWidgets = {} end
  AC.sliderWidgets[path] = enhancedSlider.slider
  
  return row
end

-- **COMPACT BUTTON HELPER**
function addon:CreateCompactButton(parent, size, text)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetSize(size, size)
  btn:EnableMouse(true) -- CRITICAL: Enable mouse interaction
  btn:SetFrameLevel(parent:GetFrameLevel() + 2) -- Ensure button is above other elements
  
  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
  
  local border = btn:CreateTexture(nil, "BORDER")
  border:SetAllPoints()
  border:SetColorTexture(0.4, 0.4, 0.4, 1)
  border:SetPoint("TOPLEFT", 1, -1)
  border:SetPoint("BOTTOMRIGHT", -1, 1)
  
  local textObj = btn:CreateFontString(nil, "OVERLAY")
  textObj:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  textObj:SetText(text)
  textObj:SetTextColor(0.8, 0.8, 0.8, 1)
  textObj:SetPoint("CENTER")
  
  -- Add hover effects
  btn:SetScript("OnEnter", function()
    bg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
    textObj:SetTextColor(1, 1, 1, 1)
  end)
  btn:SetScript("OnLeave", function()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    textObj:SetTextColor(0.8, 0.8, 0.8, 1)
  end)
  
  return btn
end

-- **ENHANCED SLIDER WITH TEXT INPUT AND SCALE CONVERSION**
function addon:CreateEnhancedSlider(parent, w, h, scaleMin, scaleMax, currentScale, label, pixelMin, pixelMax, onChange, tooltip, valueStep)
  -- CRITICAL FIX: Capture AC at function creation time to avoid nil reference
  local AC = _G.ArenaCore
  
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(w + 60, h) -- Extra width for text input
  
  -- Enhanced track background
  local trackBg = self:CreateFlatTexture(container, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
  trackBg:SetPoint("TOPLEFT", 0, 0)
  trackBg:SetPoint("BOTTOMRIGHT", -60, 0) -- Leave space for text input
  
  -- Visible slider rail
  local sliderRail = self:CreateFlatTexture(container, "BACKGROUND", 2, {0.196, 0.196, 0.196, 1}, 1)
  sliderRail:SetPoint("TOPLEFT", 2, -math.floor(h/2) + 1)
  sliderRail:SetPoint("TOPRIGHT", -62, -math.floor(h/2) + 1)
  sliderRail:SetHeight(2)
  
  -- Rail border
  local railBorder = self:CreateFlatTexture(container, "BACKGROUND", 3, {0.278, 0.278, 0.278, 1}, 1)
  railBorder:SetPoint("TOPLEFT", sliderRail, "TOPLEFT", -1, 1)
  railBorder:SetPoint("BOTTOMRIGHT", sliderRail, "BOTTOMRIGHT", 1, -1)
  railBorder:SetHeight(4)
  
  -- Main slider
  local slider = CreateFrame("Slider", nil, container)
  slider:SetPoint("TOPLEFT", 2, -2)
  slider:SetPoint("BOTTOMRIGHT", -62, 2)
  slider:SetOrientation("HORIZONTAL")
  slider:SetMinMaxValues(scaleMin, scaleMax)
  slider:SetValue(currentScale)
  -- Use custom valueStep if provided (for smooth DR positioning), otherwise use 0.01 for precision
  slider:SetValueStep(valueStep or 0.01)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  
  -- Use custom compressed TGA texture for the thumb
  local thumbTexture = slider:CreateTexture(nil, "OVERLAY")
  thumbTexture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga")
  thumbTexture:SetSize(14, math.max(2, h - 2))
  slider:SetThumbTexture(thumbTexture)
  
  -- Text input box (small, 2-3 digits)
  local textInput = CreateFrame("EditBox", nil, container)
  textInput:SetSize(50, h - 4)
  textInput:SetPoint("RIGHT", -5, 0)
  textInput:SetAutoFocus(false)
  textInput:SetNumeric(false) -- Allow decimals
  textInput:SetMaxLetters(5) -- Max 5 characters (like "10.52" for 2 decimal precision)
  
  -- Text input background
  local inputBg = self:CreateFlatTexture(textInput, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
  inputBg:SetAllPoints()
  
  -- Text input border
  local inputBorder = self:CreateFlatTexture(textInput, "BORDER", 1, {0.278, 0.278, 0.278, 1}, 1)
  inputBorder:SetPoint("TOPLEFT", -1, 1)
  inputBorder:SetPoint("BOTTOMRIGHT", 1, -1)
  
  -- Text input font
  textInput:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 11, "")
  textInput:SetTextColor(1, 1, 1, 1)
  textInput:SetJustifyH("CENTER")
  
  -- Update functions
  local function UpdateDisplays(scaleValue)
    textInput:SetText(string.format("%.2f", scaleValue))  -- 2 decimal places for pixel-perfect control
    slider:SetValue(scaleValue)
  end
  
  -- Track last value to prevent redundant updates
  local lastValue = nil
  local updateThrottle = nil
  
  local function OnScaleChange(newScale)
    if onChange and pixelMin and pixelMax then
      local pixels = addon:ConvertScaleToPixels(newScale, pixelMin, pixelMax, scaleMin, scaleMax)
      
      -- CRITICAL FIX: Only update if value actually changed (prevents flicker from redundant SetPoint calls)
      if lastValue == pixels then
        return
      end
      lastValue = pixels
      
      -- CRITICAL FIX: Throttle updates during drag to reduce flicker (max 30 updates/sec)
      if isDragging then
        if updateThrottle then
          return  -- Skip this update, we have one pending
        end
        updateThrottle = C_Timer.After(0.033, function()
          updateThrottle = nil
          onChange(pixels)
        end)
      else
        -- Not dragging: Apply immediately
        onChange(pixels)
      end
    end
  end
  
  -- Slider events with debouncing to prevent visual glitches  -- Slider state tracking
  local isDragging = false
  
  -- CRITICAL: Track drag state globally to defer heavy refresh operations
  local function MarkSliderDrag(active)
    if not AC then 
      return 
    end
    -- CRITICAL: Don't allow slider drag during Edit Mode
    if AC.EditMode and AC.EditMode.isActive then
      return
    end
    
    AC._sliderDragActive = active and true or false
    
    if not active then
      -- When drag ends, defer theme save to AFTER pending update
      AC._pendingThemeSave = true
    end
  end
  
  local function ApplyPendingUpdate()
    -- CRITICAL FIX: Apply deferred text positioning update when drag ends
    if AC._pendingTextUpdate then
      if AC and AC.UpdateTextPositioningOnly then
        AC:UpdateTextPositioningOnly()
      end
      AC._pendingTextUpdate = nil
    end
    
    -- Apply deferred theme save when drag ends
    if AC._pendingThemeSave then
      if AC.ArenaFrameThemes and AC.ArenaFrameThemes.SaveCurrentThemeSettings then
        AC.ArenaFrameThemes:SaveCurrentThemeSettings()
      end
      AC._pendingThemeSave = nil
    end
  end
  
  slider:SetScript("OnValueChanged", function(self, value)
    UpdateDisplays(value)
    
    -- CRITICAL FIX: Always call onChange - it has internal logic to allow lightweight updates during drag
    -- The onChange callback will skip heavy refreshes during drag but allow smooth text positioning
    OnScaleChange(value)
  end)
  
  slider:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      isDragging = true
      MarkSliderDrag(true)  -- Signal drag start
    end
  end)
  
  slider:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      isDragging = false
      MarkSliderDrag(false)  -- Signal drag end
      
      -- Cancel any pending throttle and apply final value immediately
      if updateThrottle then
        updateThrottle:Cancel()
        updateThrottle = nil
      end
      
      -- Apply final value immediately on release
      OnScaleChange(slider:GetValue())
      
      -- Apply deferred theme save
      ApplyPendingUpdate()
    end
  end)
  
  -- Text input events
  textInput:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value and value >= scaleMin and value <= scaleMax then
      UpdateDisplays(value)
      OnScaleChange(value)
    else
      -- Reset to current slider value if invalid
      UpdateDisplays(slider:GetValue())
    end
    self:ClearFocus()
  end)
  
  textInput:SetScript("OnEscapePressed", function(self)
    UpdateDisplays(slider:GetValue()) -- Reset to slider value
    self:ClearFocus()
  end)
  
  -- Enhanced tooltip support - show on hover over any part of the slider
  if tooltip then
    local function ShowTooltip()
      GameTooltip:SetOwner(container, "ANCHOR_RIGHT")
      GameTooltip:SetText(label, 1, 1, 1)
      GameTooltip:AddLine(tooltip, 0.7, 0.7, 0.7, true)
      GameTooltip:Show()
    end
    
    local function HideTooltip()
      GameTooltip:Hide()
    end
    
    -- Attach tooltip to all interactive elements
    container:SetScript("OnEnter", ShowTooltip)
    container:SetScript("OnLeave", HideTooltip)
    
    slider:SetScript("OnEnter", ShowTooltip)
    slider:SetScript("OnLeave", HideTooltip)
    
    textInput:SetScript("OnEnter", ShowTooltip)
    textInput:SetScript("OnLeave", HideTooltip)
  end
  
  -- Initialize display
  UpdateDisplays(currentScale)
  
  -- Store references
  container.slider = slider
  container.textInput = textInput
  container.UpdateDisplays = UpdateDisplays
  
  return container
end


-- Flat checkbox
function addon:CreateFlatCheckbox(parent, size, checked, onChange)
  -- DEBUG: CreateFlatCheckbox called
  -- print("|cffFF00FF[CREATE CHECKBOX]|r Called with onChange: " .. tostring(onChange ~= nil))
  
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(size, size)

  local btn = CreateFrame("CheckButton", nil, container)
  btn:SetAllPoints()

  local uncheckedTex = btn:CreateTexture(nil, "ARTWORK")
  uncheckedTex:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\checkbox-unchecked.tga")
  uncheckedTex:SetAllPoints()
  btn:SetNormalTexture(uncheckedTex)

  local checkedTex = btn:CreateTexture(nil, "ARTWORK")
  checkedTex:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\checkbox-checked.tga")
  checkedTex:SetAllPoints()
  btn:SetCheckedTexture(checkedTex)

  local highlightTex = btn:CreateTexture(nil, "HIGHLIGHT")
  highlightTex:SetAllPoints()
  highlightTex:SetColorTexture(1, 1, 1, 0.15)
  btn:SetHighlightTexture(highlightTex)

  btn:SetChecked(checked or false)
  
  if onChange then
    -- DEBUG: Setting up OnClick handler
    -- DEBUG DISABLED: print("|cffFF00FF[CREATE CHECKBOX]|r Setting up OnClick handler")
    btn:SetScript("OnClick", function(self) 
      -- DEBUG: Checkbox clicked
      local checkedState = self:GetChecked()
      -- DEBUG DISABLED: print("|cffFF00FF[CHECKBOX CLICK]|r Checkbox clicked! GetChecked() returned: " .. tostring(checkedState) .. " (type: " .. type(checkedState) .. ")")
      -- DEBUG DISABLED: print("|cffFF00FF[CHECKBOX CLICK]|r Calling onChange with value: " .. tostring(checkedState))
      onChange(checkedState) 
    end)
  else
    -- DEBUG: No onChange callback
    -- print("|cffFF0000[CREATE CHECKBOX ERROR]|r No onChange callback provided!")
  end
  
  container.checkButton = btn
  
  -- Method forwarding for convenience (allows both container:SetScript() and container.checkButton:SetScript())
  container.SetScript = function(self, ...) return btn:SetScript(...) end
  container.SetChecked = function(self, ...) return btn:SetChecked(...) end  
  container.GetChecked = function(self, ...) return btn:GetChecked(...) end
  
  return container
end
-- ============================================================================
-- Core/Helpers.lua
-- REPLACEMENT for CreateFlatDropdown
-- ============================================================================
function addon:CreateFlatDropdown(parent, width, height, options, selectedValue, onSelect)
  local dropdown = CreateFrame("Frame", nil, parent)
  dropdown:SetSize(width, height)
  
  local border = addon:CreateFlatTexture(dropdown, "BACKGROUND", 1, {0.196, 0.196, 0.196, 1})
  border:SetAllPoints()
  local bg = addon:CreateFlatTexture(dropdown, "BACKGROUND", 2, {0.102, 0.102, 0.102, 1})
  bg:SetPoint("TOPLEFT", 1, -1); bg:SetPoint("BOTTOMRIGHT", -1, 1)
  
  local button = CreateFrame("Button", nil, dropdown)
  button:SetAllPoints()
  
  -- Container for the selected item's icon and text
  local selectedIcon = addon:CreateStyledIcon(button, height - 8, true)
  selectedIcon:SetPoint("LEFT", 4, 0)
  selectedIcon:Hide()
  
  local text = addon:CreateStyledText(button, "", 11, {0.706, 0.706, 0.706, 1}, "OVERLAY", "")
  text:SetPoint("LEFT", 8, 0); text:SetPoint("RIGHT", -20, 0); text:SetJustifyH("LEFT")
  
  local arrow = button:CreateTexture(nil, "OVERLAY")
  arrow:SetSize(12, 12)
  arrow:SetPoint("RIGHT", -8, 0)
  arrow:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\dropdown-arrow-purple.tga")
  
  -- Helper to parse texture and text from an option string
  local function ParseOption(optionStr)
    local texture, remainingText = string.match(optionStr, "|T(.-):.-|t(.*)")
    return texture, remainingText or optionStr
  end

  local function UpdateSelectedDisplay(value)
      local texturePath, textOnly = ParseOption(value)
      if texturePath and addon.IconStyling then
          selectedIcon:SetIconTexture(texturePath)
          selectedIcon:Show()
          text:SetPoint("LEFT", selectedIcon, "RIGHT", 5, 0)
          text:SetText(textOnly)
      else
          selectedIcon:Hide()
          text:SetPoint("LEFT", 8, 0)
          text:SetText(value)
      end
  end

  local maxVisibleOptions = 8
  local optionHeight = 24
  local menu = CreateFrame("Frame", nil, UIParent)
  menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -1)
  menu:SetWidth(width)
  menu:SetHeight(math.min(#options, maxVisibleOptions) * optionHeight + 4)
  menu:SetFrameStrata("FULLSCREEN_DIALOG")
  menu:SetFrameLevel(1000)
  menu:Hide()
  
  -- CRITICAL: Mark as ArenaCore frame for theme system
  menu.__isArenaCore = true
  
  local menuBorder = addon:CreateFlatTexture(menu, "BACKGROUND", 1, {0.196, 0.196, 0.196, 1})
  menuBorder:SetAllPoints()
  local menuBg = addon:CreateFlatTexture(menu, "BACKGROUND", 2, {0.102, 0.102, 0.102, 1})
  menuBg:SetPoint("TOPLEFT", 1, -1); menuBg:SetPoint("BOTTOMRIGHT", -1, 1)

  local scrollFrame = CreateFrame("ScrollFrame", nil, menu)
  scrollFrame:SetPoint("TOPLEFT", 2, -2); scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(width - 4)
  scrollChild:SetHeight(#options * optionHeight)
  scrollFrame:SetScrollChild(scrollChild)
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
      local current = self:GetVerticalScroll()
      local maxScroll = math.max(0, scrollChild:GetHeight() - self:GetHeight())
      self:SetVerticalScroll(math.max(0, math.min(maxScroll, current - (delta * optionHeight))))
  end)

  for i, option in ipairs(options) do
    local optBtn = CreateFrame("Button", nil, scrollChild)
    optBtn:SetPoint("TOPLEFT", 0, -(i-1) * optionHeight); optBtn:SetPoint("TOPRIGHT", 0, -(i-1) * optionHeight)
    optBtn:SetHeight(optionHeight - 2)
    
    local optHover = addon:CreateFlatTexture(optBtn, "BACKGROUND", 1, {0.278, 0.278, 0.278, 1}, 0.3)
    optHover:SetAllPoints(); optHover:Hide()
    
    local texturePath, textOnly = ParseOption(option)
    if texturePath and addon.IconStyling then
        local icon = addon:CreateStyledIcon(optBtn, optionHeight - 8, true)
        icon:SetIconTexture(texturePath)
        icon:SetPoint("LEFT", 4, 0)
        local optText = addon:CreateStyledText(optBtn, textOnly, 11, {0.706, 0.706, 0.706, 1}, "OVERLAY", "")
        optText:SetPoint("LEFT", icon, "RIGHT", 5, 0); optText:SetJustifyH("LEFT")
    else
        local optText = addon:CreateStyledText(optBtn, option, 11, {0.706, 0.706, 0.706, 1}, "OVERLAY", "")
        optText:SetPoint("LEFT", 6, 0); optText:SetJustifyH("LEFT")
    end
    
    optBtn:SetScript("OnEnter", function() optHover:Show() end)
    optBtn:SetScript("OnLeave", function() optHover:Hide() end)
    optBtn:SetScript("OnClick", function()
      UpdateSelectedDisplay(option)
      menu:Hide()
      if onSelect then onSelect(option) end
      dropdown.selectedValue = option
    end)
  end
  
  button:SetScript("OnClick", function() 
    if menu:IsShown() then 
      menu:Hide() 
    else 
      menu:Show() 
    end 
  end)
  menu:SetScript("OnShow", function() arrow:SetRotation(math.rad(180)) end)
  menu:SetScript("OnHide", function() arrow:SetRotation(math.rad(0)) end)

  dropdown.SetValue = function(self, value)
    for _, option in ipairs(options) do
      if option == value then
        UpdateSelectedDisplay(value)
        self.selectedValue = value
        break
      end
    end
  end
  dropdown:SetValue(selectedValue or options[1])
  
  -- CRITICAL FIX: Expose menu reference for external cleanup
  dropdown.menu = menu
  dropdown.menu.scrollChild = scrollChild  -- Expose scrollChild for width adjustments
  
  -- CRITICAL FIX: Register dropdown for global cleanup when switching pages
  if not addon.openDropdowns then
    addon.openDropdowns = {}
  end
  table.insert(addon.openDropdowns, dropdown)
  
  return dropdown
end
-- Global dropdown management to prevent overlapping
if not addon.openDropdowns then
  addon.openDropdowns = {}
end

local function CloseAllDropdowns()
  for _, dropdown in ipairs(addon.openDropdowns) do
    if dropdown.menu and dropdown.menu:IsShown() then
      dropdown.menu:Hide()
    end
  end
end

-- Enhanced dropdown with texture previews
function addon:CreateFlatDropdownWithPreview(parent, width, height, options, selectedValue, onSelect, texturePathFunc)
  local dropdown = CreateFrame("Frame", nil, parent)
  dropdown:SetSize(width, height)
  
  local border = addon:CreateFlatTexture(dropdown, "BACKGROUND", 1, {0.196, 0.196, 0.196, 1})
  border:SetAllPoints()
  local bg = addon:CreateFlatTexture(dropdown, "BACKGROUND", 2, {0.102, 0.102, 0.102, 1})
  bg:SetPoint("TOPLEFT", 1, -1); bg:SetPoint("BOTTOMRIGHT", -1, 1)
  
  local button = CreateFrame("Button", nil, dropdown)
  button:SetAllPoints()
  
  -- Preview texture for selected item
  local previewTexture = nil
  if texturePathFunc then
    previewTexture = button:CreateTexture(nil, "OVERLAY")
    previewTexture:SetSize(18, 18)
    previewTexture:SetPoint("LEFT", 6, 0)
  end
  
  local text = addon:CreateStyledText(button, "", 11, {0.706, 0.706, 0.706, 1}, "OVERLAY", "")
  if previewTexture then
    text:SetPoint("LEFT", previewTexture, "RIGHT", 6, 0)
  else
    text:SetPoint("LEFT", 8, 0)
  end
  text:SetPoint("RIGHT", -20, 0)
  text:SetJustifyH("LEFT")
  
  local arrow = button:CreateTexture(nil, "OVERLAY")
  arrow:SetSize(12, 12)
  arrow:SetPoint("RIGHT", -8, 0)
  arrow:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\dropdown-arrow-purple.tga")
  arrow:SetVertexColor(0.502, 0.502, 0.502, 1)
  
  -- Calculate menu height
  local optionHeight = 26
  local maxVisibleOptions = 8
  local visibleOptions = math.min(#options, maxVisibleOptions)
  local menuHeight = visibleOptions * optionHeight + 4
  
  local menu = CreateFrame("ScrollFrame", nil, dropdown)
  menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -1)
  menu:SetWidth(width)
  menu:SetHeight(menuHeight)
  menu:SetFrameStrata("DIALOG")
  menu:Hide()
  
  -- CRITICAL: Mark as ArenaCore frame for theme system
  menu.__isArenaCore = true
  
  local menuBorder = addon:CreateFlatTexture(menu, "BACKGROUND", 1, {0.196, 0.196, 0.196, 1})
  menuBorder:SetAllPoints()
  local menuBg = addon:CreateFlatTexture(menu, "BACKGROUND", 2, {0.102, 0.102, 0.102, 1})
  menuBg:SetPoint("TOPLEFT", 1, -1); menuBg:SetPoint("BOTTOMRIGHT", -1, 1)
  
  -- Scroll child for options
  local scrollChild = CreateFrame("Frame", nil, menu)
  scrollChild:SetWidth(width - 2)
  scrollChild:SetHeight(#options * optionHeight)
  menu:SetScrollChild(scrollChild)
  
  for i, option in ipairs(options) do
    local optBtn = CreateFrame("Button", nil, scrollChild)
    optBtn:SetPoint("TOPLEFT", 2, -(i-1) * optionHeight - 2)
    optBtn:SetPoint("TOPRIGHT", -2, -(i-1) * optionHeight - 2)
    optBtn:SetHeight(optionHeight - 2)
    
    local optHover = addon:CreateFlatTexture(optBtn, "BACKGROUND", 1, {0.278, 0.278, 0.278, 1}, 0.3)
    optHover:SetAllPoints()
    optHover:Hide()
    
    -- Option texture preview
    local optTexture = nil
    if texturePathFunc then
      optTexture = optBtn:CreateTexture(nil, "OVERLAY")
      optTexture:SetSize(18, 18)
      optTexture:SetPoint("LEFT", 6, 0)
      local texPath = texturePathFunc(option)
      if texPath and texPath ~= "" then
        -- Use WeakAuras pattern to auto-detect atlas vs file ID
        local isAtlas = type(texPath) == "string" and C_Texture.GetAtlasInfo(texPath) ~= nil
        if isAtlas then
          optTexture:SetAtlas(texPath)
        else
          local fileID = tonumber(texPath) or texPath
          local success = optTexture:SetTexture(fileID)
          if not success then
            -- Fallback: try without backslashes (forward slashes)
            local altPath = texPath:gsub("\\", "/")
            optTexture:SetTexture(altPath)
          end
        end
        
        -- CRITICAL FIX: Apply texture coordinates to show only first frame of flipbook textures
        -- This makes all previews show a single bar instead of stacked bars
        if type(texPath) == "string" then
          if texPath:find("Quality%-BarFill%-Flipbook") then
            -- Quality BarFill: 15 rows x 4 columns = show top-left cell only
            optTexture:SetTexCoord(0, 0.25, 0, 0.0667)
          elseif texPath:find("Priest_Void") then
            -- Void Priest: 8 rows x 8 columns = show top-left cell only
            optTexture:SetTexCoord(0, 0.125, 0, 0.125)
          elseif texPath:find("Skillbar_Fill_Flipbook") then
            -- Skillbar: 1 row x 4 columns = show ONLY first frame (leftmost 25%)
            -- Crop both horizontally (0 to 0.25) AND vertically to maintain aspect ratio
            optTexture:SetTexCoord(0, 0.25, 0.375, 0.625)
          else
            -- Default: show full texture (Dastardly Duos, external indicators, etc.)
            optTexture:SetTexCoord(0, 1, 0, 1)
          end
        else
          -- File IDs: show full texture
          optTexture:SetTexCoord(0, 1, 0, 1)
        end
        
        -- Apply bright, clean color to all texture previews (purple tint for Arena Core branding)
        optTexture:SetVertexColor(0.8, 0.6, 1.0, 1.0)
      end
    end
    
    local optText = addon:CreateStyledText(optBtn, option, 11, {0.706, 0.706, 0.706, 1}, "OVERLAY", "")
    if optTexture then
      optText:SetPoint("LEFT", optTexture, "RIGHT", 6, 0)
    else
      optText:SetPoint("LEFT", 6, 0)
    end
    optText:SetJustifyH("LEFT")
    
    optBtn:SetScript("OnEnter", function() optHover:Show() end)
    optBtn:SetScript("OnLeave", function() optHover:Hide() end)
    optBtn:SetScript("OnClick", function()
      text:SetText(option)
      if previewTexture and texturePathFunc then
        local texPath = texturePathFunc(option)
        if texPath and texPath ~= "" then
          -- Use WeakAuras pattern to auto-detect atlas vs file ID
          local isAtlas = type(texPath) == "string" and C_Texture.GetAtlasInfo(texPath) ~= nil
          if isAtlas then
            previewTexture:SetAtlas(texPath)
          else
            local fileID = tonumber(texPath) or texPath
            local success = previewTexture:SetTexture(fileID)
            if not success then
              -- Fallback: try without backslashes (forward slashes)
              local altPath = texPath:gsub("\\", "/")
              previewTexture:SetTexture(altPath)
            end
          end
          
          -- CRITICAL FIX: Apply texture coordinates to show only first frame of flipbook textures
          if type(texPath) == "string" then
            if texPath:find("Quality%-BarFill%-Flipbook") then
              previewTexture:SetTexCoord(0, 0.25, 0, 0.0667)
            elseif texPath:find("Priest_Void") then
              previewTexture:SetTexCoord(0, 0.125, 0, 0.125)
            elseif texPath:find("Skillbar_Fill_Flipbook") then
              previewTexture:SetTexCoord(0, 0.25, 0.375, 0.625)
            else
              previewTexture:SetTexCoord(0, 1, 0, 1)
            end
          else
            previewTexture:SetTexCoord(0, 1, 0, 1)
          end
          
          -- Apply bright, clean color to selected preview texture
          previewTexture:SetVertexColor(0.8, 0.6, 1.0, 1.0)
          previewTexture:Show()
        else
          -- CRITICAL FIX: Hide preview icon when "None" is selected (empty path)
          previewTexture:Hide()
        end
      end
      menu:Hide()
      if onSelect then onSelect(option) end
      dropdown.selectedValue = option
    end)
  end
  
  -- Scrollbar for long lists
  if #options > maxVisibleOptions then
    local scrollbar = CreateFrame("Slider", nil, menu)
    scrollbar:SetPoint("TOPRIGHT", -2, -2)
    scrollbar:SetPoint("BOTTOMRIGHT", -2, 2)
    scrollbar:SetWidth(12)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetMinMaxValues(0, (#options - maxVisibleOptions) * optionHeight)
    scrollbar:SetValue(0)
    
    -- Use custom compressed TGA texture for scrollbar
    local scrollThumb = scrollbar:CreateTexture(nil, "OVERLAY")
    scrollThumb:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga")
    scrollThumb:SetWidth(10)
    scrollThumb:SetHeight(20)
    scrollbar:SetThumbTexture(scrollThumb)
    
    scrollbar:SetScript("OnValueChanged", function(self, value)
      menu:SetVerticalScroll(value)
    end)
    
    menu:EnableMouseWheel(true)
    menu:SetScript("OnMouseWheel", function(self, delta)
      local current = scrollbar:GetValue()
      local step = optionHeight
      scrollbar:SetValue(current - (delta * step))
    end)
  end
  
  button:SetScript("OnClick", function()
    if menu:IsShown() then 
      menu:Hide() 
    else 
      CloseAllDropdowns()  -- Close all other dropdowns first
      menu:Show() 
    end
  end)
  
  menu:SetScript("OnShow", function() arrow:SetRotation(math.rad(180)) end)
  menu:SetScript("OnHide", function() arrow:SetRotation(math.rad(0)) end)

  dropdown.SetValue = function(self, value)
    for _, option in ipairs(options) do
      if option == value then
        text:SetText(value)
        if previewTexture and texturePathFunc then
          local texPath = texturePathFunc(value)
          if texPath and texPath ~= "" then
            -- Use WeakAuras pattern to auto-detect atlas vs file ID
            local isAtlas = type(texPath) == "string" and C_Texture.GetAtlasInfo(texPath) ~= nil
            if isAtlas then
              previewTexture:SetAtlas(texPath)
            else
              local fileID = tonumber(texPath) or texPath
              previewTexture:SetTexture(fileID)
            end
            
            -- CRITICAL FIX: Apply texture coordinates to show only first frame of flipbook textures
            if type(texPath) == "string" then
              if texPath:find("Quality%-BarFill%-Flipbook") then
                previewTexture:SetTexCoord(0, 0.25, 0, 0.0667)
              elseif texPath:find("Priest_Void") then
                previewTexture:SetTexCoord(0, 0.125, 0, 0.125)
              elseif texPath:find("Skillbar_Fill_Flipbook") then
                previewTexture:SetTexCoord(0, 0.25, 0.375, 0.625)
              else
                previewTexture:SetTexCoord(0, 1, 0, 1)
              end
            else
              previewTexture:SetTexCoord(0, 1, 0, 1)
            end
            previewTexture:Show()
          else
            -- CRITICAL FIX: Hide preview icon when "None" is selected (empty path)
            previewTexture:Hide()
          end
        end
        self.selectedValue = value
        break
      end
    end
  end
  
  dropdown:SetValue(selectedValue or options[1])
  
  -- Register this dropdown in the global list and store menu reference
  dropdown.menu = menu
  table.insert(addon.openDropdowns, dropdown)
  
  return dropdown
end
-- Enhanced input field
function addon:CreateEnhancedInput(parent, w, h, placeholder)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(w, h)
  local border = self:CreateFlatTexture(f, "BACKGROUND", 1, {0.196, 0.196, 0.196, 1}, 1)
  border:SetAllPoints()
  local fill = self:CreateFlatTexture(f, "BACKGROUND", 2, {0.102, 0.102, 0.102, 1}, 1)
  fill:SetPoint("TOPLEFT", 1, -1)
  fill:SetPoint("BOTTOMRIGHT", -1, 1)
  local input = CreateFrame("EditBox", nil, f)
  input:SetPoint("TOPLEFT", 8, -8)
  input:SetPoint("BOTTOMRIGHT", -8, 8)
  input:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  input:SetTextColor(1, 1, 1, 1)
  input:SetAutoFocus(false)
  input:SetMaxLetters(50)
  local ph = self:CreateStyledText(f, placeholder or "", 12, {0.502, 0.502, 0.502, 1}, "OVERLAY", "")
  ph:SetPoint("LEFT", 12, 0)
  input:SetScript("OnEditFocusGained", function() ph:Hide() end)
  input:SetScript("OnEditFocusLost", function() if input:GetText() == "" then ph:Show() end end)
  input:SetScript("OnTextChanged", function()
    if input:GetText() ~= "" then ph:Hide() else ph:Show() end
  end)
  f.input = input
  return f
end

-- Enhanced button with textures
function addon:CreateEnhancedButton(parent, w, h, label, flags, normalColor, hoverColor)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  local border = self:CreateFlatTexture(b, "BACKGROUND", 1, {0.278, 0.278, 0.278, 1}, 1)
  border:SetAllPoints()
  local bg = self:CreateFlatTexture(b, "BACKGROUND", 2, normalColor or {0.545, 0.271, 1.000, 1}, 1)
  bg:SetPoint("TOPLEFT", 1, -1)
  bg:SetPoint("BOTTOMRIGHT", -1, 1)
  local t
  if label then
    t = self:CreateStyledText(b, label, 12, {1,1,1,1}, "OVERLAY", flags)
    t:SetPoint("CENTER", 0, 0)
    b.text = t
  end
  b:SetScript("OnEnter", function() if hoverColor then bg:SetColorTexture(hoverColor[1], hoverColor[2], hoverColor[3], 1) end end)
  b:SetScript("OnLeave", function()
    local c = normalColor or {0.545, 0.271, 1.000, 1}
    bg:SetColorTexture(c[1], c[2], c[3], 1)
  end)
  b.bg = bg
  return b
end

-- Textured button
function addon:CreateTexturedButton(parent, w, h, label, texBase, name)
  local b = CreateFrame("Button", name or nil, parent)
  b:SetSize(w, h)
  local path = "Interface\\AddOns\\ArenaCore\\Media\\" .. texBase .. ".tga"
  local n = b:CreateTexture(nil, "BACKGROUND", nil, 0)
  n:SetAllPoints()
  n:SetTexture(path)
  n:SetTexCoord(0.002, 0.998, 0.002, 0.998)
  b:SetNormalTexture(n)
  local hlt = b:CreateTexture(nil, "HIGHLIGHT", nil, 1)
  hlt:SetAllPoints()
  hlt:SetTexture(path)
  hlt:SetTexCoord(0.002, 0.998, 0.002, 0.998)
  hlt:SetVertexColor(1, 1, 1, 0.85)
  b:SetHighlightTexture(hlt)
  local p = b:CreateTexture(nil, "ARTWORK", nil, 0)
  p:SetAllPoints()
  p:SetTexture(path)
  p:SetTexCoord(0.002, 0.998, 0.002, 0.998)
  p:SetVertexColor(0.92, 0.92, 0.92, 1)
  b:SetPushedTexture(p)
  if label and label ~= "" then
    local t = self:CreateStyledText(b, label, 12, {1,1,1,1}, "OVERLAY", "")
    t:SetPoint("CENTER", 0, 0)
    b.text = t
  end
  return b
end

-- Get spell data (CLEAN VERSION - NO DEBUG SPAM)
function addon:GetSpellData(spellID)
  if not spellID then 
    return nil, "Unknown Spell", "Interface\\Icons\\INV_Misc_QuestionMark"
  end
  
  local id = tonumber(spellID)
  if not id then
    return nil, "Invalid Spell ID", "Interface\\Icons\\INV_Misc_QuestionMark"
  end
  
  
  if C_Spell and C_Spell.GetSpellInfo then
    local spellInfo = C_Spell.GetSpellInfo(id)
    if spellInfo and spellInfo.name then
      return id, spellInfo.name, spellInfo.iconID or spellInfo.icon
    else
    end
  end
  
  if GetSpellName and GetSpellTexture then
    local name = GetSpellName(id)
    local icon = GetSpellTexture(id)
    if name and icon then
      return id, name, icon
    end
  end
  
  return id, "Unknown Spell", "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Shared DR icon resolver to avoid drift across files
function addon:ResolveDRIconSpellID(category, unitGUID, actualSpellID)
  -- Acquire active DR settings (supports both new helper and direct DB path)
  local activeDB
  if self.GetActiveDRSettingsDB then
    activeDB = self:GetActiveDRSettingsDB()
  else
    activeDB = self.DB and self.DB.profile and self.DB.profile.diminishingReturns
  end

  -- Default to dynamic if not configured
  local iconSetting = (activeDB and activeDB.iconSettings and activeDB.iconSettings[category]) or "dynamic"

  if iconSetting == "dynamic" then
    -- DYNAMIC MODE: Show the actual spell that triggered the DR
    -- This means if Kidney Shot was cast, show Kidney Shot icon
    -- If Mighty Bash was cast, show Mighty Bash icon
    return actualSpellID or 408 -- fallback to Kidney Shot icon if nothing else
  elseif iconSetting == "custom" then
    -- CUSTOM MODE: Use user-provided custom spell ID for this category
    return (activeDB and activeDB.customSpells and activeDB.customSpells[category]) or actualSpellID or 408
  else
    -- SPECIFIC SPELL MODE: A specific spell ID was chosen for this category
    -- Always show that spell icon, no matter what spell actually triggered the DR
    -- Example: If set to Kidney Shot, always show Kidney Shot even if Mighty Bash was cast
    return tonumber(iconSetting) or actualSpellID or 408
  end
end

function addon:HairlineGroupBox(group)
-- DEBUG: Track which groups are being processed with detailed info
if _G.ArenaCore_Debug then
    local frameInfo = "unnamed frame"
    if group then
        local name = group:GetName() or "no name"
        local parent = group:GetParent()
        local parentName = parent and parent:GetName() or "no parent"
        local width = group:GetWidth() or 0
        local height = group:GetHeight() or 0
        frameInfo = string.format("name=%s, parent=%s, size=%dx%d", name, parentName, width, height)
    end
    -- Debug disabled for release: _G.ArenaCore_Debug("HairlineGroupBox called for:", frameInfo)
end

-- Clean solid color background (replaced problematic texture file)
local fill = group:CreateTexture(nil, "BACKGROUND", nil, 2)
-- Use COLORS table so theme system can update it
local bgColor = addon.COLORS and addon.COLORS.HEADER_BG or {0.102, 0.102, 0.102, 1}
fill:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
fill:SetPoint("TOPLEFT", 1, -1)
fill:SetPoint("BOTTOMRIGHT", -1, 1)
group.__acFill = fill
group.__acFillIsGroupBox = true -- Mark this so theme system knows to update it

-- REBUILT SYSTEM: Simple, clean purple-top border with no z-fighting
-- Use a single border frame with purple top, avoiding multiple overlapping textures

local borderFrame = CreateFrame("Frame", nil, group)
borderFrame:SetAllPoints(group)
-- ENHANCED: Ensure unique frame levels for nested scenarios
local uniqueLevel = group:GetFrameLevel() + 1
-- Add small offset based on group's position to prevent conflicts
if group:GetParent() then
    uniqueLevel = uniqueLevel + (group:GetFrameLevel() % 3)
end
borderFrame:SetFrameLevel(uniqueLevel)

-- Single purple top line - no complex layering
local purpleTop = borderFrame:CreateTexture(nil, "BORDER", nil, 1)
purpleTop:SetColorTexture(0.545, 0.271, 1.000, 1) -- Purple color
purpleTop:SetPoint("TOPLEFT", group, "TOPLEFT", 0, 0)
purpleTop:SetPoint("TOPRIGHT", group, "TOPRIGHT", 0, 0)
purpleTop:SetHeight(1)

-- Debug disabled for release
-- if _G.ArenaCore_Debug then
--     _G.ArenaCore_Debug("Purple accent line created for frame:", frameInfo or "unknown")
-- end

-- Simple gray borders - single texture each, no overlap
local grayTop = borderFrame:CreateTexture(nil, "BORDER", nil, 0)
grayTop:SetColorTexture(0.278, 0.278, 0.278, 0.9)
grayTop:SetPoint("TOPLEFT", group, "TOPLEFT", 0, -1)
grayTop:SetPoint("TOPRIGHT", group, "TOPRIGHT", 0, -1)
grayTop:SetHeight(1)

local grayBottom = borderFrame:CreateTexture(nil, "BORDER", nil, 0)
grayBottom:SetColorTexture(0.278, 0.278, 0.278, 0.9)
grayBottom:SetPoint("BOTTOMLEFT", group, "BOTTOMLEFT", 0, 0)
grayBottom:SetPoint("BOTTOMRIGHT", group, "BOTTOMRIGHT", 0, 0)
grayBottom:SetHeight(1)

local grayLeft = borderFrame:CreateTexture(nil, "BORDER", nil, 0)
grayLeft:SetColorTexture(0.278, 0.278, 0.278, 0.9)
grayLeft:SetPoint("TOPLEFT", group, "TOPLEFT", 0, 0)
grayLeft:SetPoint("BOTTOMLEFT", group, "BOTTOMLEFT", 0, 0)
grayLeft:SetWidth(1)

local grayRight = borderFrame:CreateTexture(nil, "BORDER", nil, 0)
grayRight:SetColorTexture(0.278, 0.278, 0.278, 0.9)
grayRight:SetPoint("TOPRIGHT", group, "TOPRIGHT", 0, 0)
grayRight:SetPoint("BOTTOMRIGHT", group, "BOTTOMRIGHT", 0, 0)
grayRight:SetWidth(1)

-- Store reference for cleanup if needed
group.__acBorderFrame = borderFrame
end

-- =========================================================================
-- Coming Soon Text Helper
-- Creates professional "Coming Soon™" notice with purple accent underline
-- =========================================================================
function addon:CreateComingSoonText(parent, anchorFrame)
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(250, 20)
  container:SetPoint("LEFT", anchorFrame, "RIGHT", 10, 0)
  
  -- Main text with ArenaCore custom font
  local text = self:CreateStyledText(container, "<----------- This feature is Coming Soon™", 11, {1, 1, 1, 1}, "OVERLAY", "")
  text:SetPoint("LEFT", container, "LEFT", 0, 0)
  text:SetJustifyH("LEFT")
  
  -- Purple accent underline (matching ArenaCore theme)
  local underline = container:CreateTexture(nil, "OVERLAY")
  underline:SetColorTexture(0.698, 0.4, 1, 0.8) -- Purple accent (#B266FF with 80% alpha)
  underline:SetPoint("BOTTOMLEFT", text, "BOTTOMLEFT", 0, -2)
  underline:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", 0, -2)
  underline:SetHeight(1)
  
  return container
end

--- Profile Dropdown with Delete Buttons
--- Special dropdown for profile management with red X delete buttons
function addon:CreateProfileDropdown(parent, width, height, options, selectedValue, onSelect, onDelete, defaultProfile, currentProfile)
  local dropdown = CreateFrame("Frame", nil, parent)
  dropdown:SetSize(width, height)
  
  local border = addon:CreateFlatTexture(dropdown, "BACKGROUND", 1, {0.196, 0.196, 0.196, 1})
  border:SetAllPoints()
  local bg = addon:CreateFlatTexture(dropdown, "BACKGROUND", 2, {0.102, 0.102, 0.102, 1})
  bg:SetPoint("TOPLEFT", 1, -1); bg:SetPoint("BOTTOMRIGHT", -1, 1)
  
  local button = CreateFrame("Button", nil, dropdown)
  button:SetAllPoints()
  
  local text = addon:CreateStyledText(button, "", 11, {0.706, 0.706, 0.706, 1}, "OVERLAY", "")
  text:SetPoint("LEFT", 8, 0); text:SetPoint("RIGHT", -20, 0); text:SetJustifyH("LEFT")
  
  local arrow = button:CreateTexture(nil, "OVERLAY")
  arrow:SetSize(12, 12)
  arrow:SetPoint("RIGHT", -8, 0)
  arrow:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\dropdown-arrow-purple.tga")
  
  local function UpdateSelectedDisplay(value)
    text:SetText(value)
  end

  local maxVisibleOptions = 8
  local optionHeight = 26
  local menu = CreateFrame("Frame", nil, UIParent)
  menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -1)
  menu:SetWidth(width)
  menu:SetHeight(math.min(#options, maxVisibleOptions) * optionHeight + 4)
  menu:SetFrameStrata("FULLSCREEN_DIALOG")
  menu:SetFrameLevel(3000)  -- Higher than More Features window (2000) when raised from Edit Mode
  menu:Hide()
  
  menu.__isArenaCore = true
  
  local menuBorder = addon:CreateFlatTexture(menu, "BACKGROUND", 1, {0.196, 0.196, 0.196, 1})
  menuBorder:SetAllPoints()
  local menuBg = addon:CreateFlatTexture(menu, "BACKGROUND", 2, {0.102, 0.102, 0.102, 1})
  menuBg:SetPoint("TOPLEFT", 1, -1); menuBg:SetPoint("BOTTOMRIGHT", -1, 1)

  local scrollFrame = CreateFrame("ScrollFrame", nil, menu)
  scrollFrame:SetPoint("TOPLEFT", 2, -2); scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(width - 4)
  scrollChild:SetHeight(#options * optionHeight)
  scrollFrame:SetScrollChild(scrollChild)
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = math.max(0, scrollChild:GetHeight() - self:GetHeight())
    self:SetVerticalScroll(math.max(0, math.min(maxScroll, current - (delta * optionHeight))))
  end)

  for i, option in ipairs(options) do
    local optBtn = CreateFrame("Button", nil, scrollChild)
    optBtn:SetPoint("TOPLEFT", 0, -(i-1) * optionHeight); optBtn:SetPoint("TOPRIGHT", 0, -(i-1) * optionHeight)
    optBtn:SetHeight(optionHeight - 2)
    
    local optHover = addon:CreateFlatTexture(optBtn, "BACKGROUND", 1, {0.278, 0.278, 0.278, 1}, 0.3)
    optHover:SetAllPoints(); optHover:Hide()
    
    local optText = addon:CreateStyledText(optBtn, option, 11, {0.706, 0.706, 0.706, 1}, "OVERLAY", "")
    optText:SetPoint("LEFT", 6, 0); optText:SetJustifyH("LEFT")
    
    -- Add delete button (red X) for non-default profiles
    if option ~= defaultProfile then
      local deleteBtn = CreateFrame("Button", nil, optBtn)
      deleteBtn:SetSize(18, 18)
      deleteBtn:SetPoint("RIGHT", -4, 0)
      
      -- Red background texture (same as main UI close button)
      local deleteBg = deleteBtn:CreateTexture(nil, "BACKGROUND")
      deleteBg:SetAllPoints()
      deleteBg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-close.tga")
      deleteBg:SetTexCoord(0.002, 0.998, 0.002, 0.998)
      
      -- White X text (same as main UI close button)
      local xText = addon:CreateStyledText(deleteBtn, "×", 14, {0.9, 0.9, 0.9, 1}, "OVERLAY", "")
      xText:SetPoint("CENTER", 0, 0)
      deleteBtn.xText = xText
      
      -- Hover effect for delete button
      deleteBtn:SetScript("OnEnter", function(self)
        deleteBg:SetVertexColor(1.2, 1.2, 1.2, 1) -- Brighten on hover
        self.xText:SetTextColor(1, 1, 1, 1) -- Brighter white
      end)
      
      deleteBtn:SetScript("OnLeave", function(self)
        deleteBg:SetVertexColor(1, 1, 1, 1) -- Normal
        self.xText:SetTextColor(0.9, 0.9, 0.9, 1) -- Normal white
      end)
      
      deleteBtn:SetScript("OnClick", function(self)
        -- Prevent event from bubbling to parent button
        self:GetParent():GetScript("OnClick")(self:GetParent(), "RightButton")
        if onDelete then
          onDelete(option)
        end
      end)
      
      -- Adjust text to not overlap with delete button
      optText:SetPoint("RIGHT", deleteBtn, "LEFT", -4, 0)
    end
    
    optBtn:SetScript("OnEnter", function() optHover:Show() end)
    optBtn:SetScript("OnLeave", function() optHover:Hide() end)
    optBtn:SetScript("OnClick", function(self, mouseButton)
      if mouseButton == "RightButton" then
        -- Right click or delete button click - do nothing, handled by delete button
        return
      end
      UpdateSelectedDisplay(option)
      menu:Hide()
      if onSelect then onSelect(option) end
      dropdown.selectedValue = option
    end)
  end
  
  button:SetScript("OnClick", function() 
    if menu:IsShown() then 
      menu:Hide() 
    else 
      menu:Show() 
    end 
  end)
  menu:SetScript("OnShow", function() arrow:SetRotation(math.rad(180)) end)
  menu:SetScript("OnHide", function() arrow:SetRotation(math.rad(0)) end)

  dropdown.SetValue = function(self, value)
    for _, option in ipairs(options) do
      if option == value then
        UpdateSelectedDisplay(value)
        self.selectedValue = value
        break
      end
    end
  end
  dropdown:SetValue(selectedValue or options[1])
  
  dropdown.menu = menu
  dropdown:Show()  -- Ensure dropdown is visible when created
  
  -- CRITICAL FIX: Auto-hide menu when dropdown is hidden
  -- Prevents menu from persisting when parent dropdown is cleaned up
  dropdown:SetScript("OnHide", function()
    if menu and menu:IsShown() then
      menu:Hide()
    end
  end)
  
  return dropdown
end