-- =============================================================
-- File: modules/Auras/TriBadges.lua (with Test Mode & CORRECTED NAMESPACE)
-- =============================================================

-- Get the main addon table, ensuring it exists.
local AC = _G.ArenaCore
if not AC then return end

-- MIDNIGHT COMPATIBILITY: Disable in restricted content (arena matches)
-- This feature tracks class-specific auras which may be restricted
local function IsTriBadgesRestricted()
    if not AC.IsMidnight or not AC:IsMidnight() then
        return false
    end
    return AC:IsInRestrictedContent()
end

local existing = AC.TriBadges or {}
local M

if type(AC.RegisterModule) == "function" then
    M = AC:RegisterModule("TriBadges", existing)
else
    M = existing
end

AC.TriBadges = M

-- Test mode dummy icons
local DUMMY_ICONS = {
  "Interface\\Icons\\spell_deathknight_classicon", -- Slot 1 (Burst)
  "Interface\\Icons\\ability_warrior_defensivestance",   -- Slot 2 (Defensive)
  "Interface\\Icons\\spell_mage_arcaneorb",          -- Slot 3 (Control)
}

-- FIXED: Database function that works with ArenaCore's actual database structure
local function DB() 
  -- Try multiple paths to find the TriBadges settings
  if AC.DB and AC.DB.profile then
    -- Path 1: classPacks table (your actual structure)
    if AC.DB.profile.classPacks then
      return AC.DB.profile.classPacks
    end
    
    -- Path 2: Try triBadges directly
    if AC.DB.profile.triBadges then
      return AC.DB.profile.triBadges
    end
    
    -- Path 3: Try auras.triBadges
    if AC.DB.profile.auras and AC.DB.profile.auras.triBadges then
      return AC.DB.profile.auras.triBadges
    end
    
    -- Path 4: Try moreGoodies.triBadges
    if AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.triBadges then
      return AC.DB.profile.moreGoodies.triBadges
    end
    
    -- Path 5: Create default settings if none exist - use classPacks path
    AC.DB.profile.classPacks = AC.DB.profile.classPacks or {
      enabled = true, -- Default to enabled
      size = 18,
      spacing = 2,
      anchor = "TOPLEFT",
      offsetX = -20,
      offsetY = -2
    }
    return AC.DB.profile.classPacks
  end
  
  -- Fallback: return default settings
  return {
    enabled = true,
    size = 18,
    spacing = 2,
    anchor = "TOPLEFT", 
    offsetX = -20,
    offsetY = -2
  }
end

local FONT = "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf"
if not FONT or FONT == "" then FONT = STANDARD_TEXT_FONT end

local framesByUnit = {}
local guidToUnit = {} -- GUID → unit mapping cache (like TrinketsRacials pattern)
local UpdateAll -- Forward declaration so lifecycle handlers can call it

-- CRITICAL FIX: Resolve arena unit from GUID (same pattern as TrinketsRacials)
-- This allows tracking spells via COMBAT_LOG even when unit tokens aren't immediately available
local function ResolveUnitForGUID(guid)
  if not guid then return nil end
  
  -- Check cache first
  if guidToUnit[guid] then
    return guidToUnit[guid]
  end
  
  -- Scan arena1-5 to find matching GUID
  for i = 1, 5 do
    local unit = "arena" .. i
    local unitGUID = UnitGUID(unit)
    if unitGUID then
      guidToUnit[unitGUID] = unit -- Cache for future lookups
    end
    if unitGUID == guid then
      return unit
    end
  end
  
  return nil
end

-- =====================================================================
-- Module lifecycle helpers
-- =====================================================================

function M:OnInit()
  local db = DB()
  if type(db) == "table" then
    if db.enabled == nil then db.enabled = true end
    db.size = db.size or 18
    db.spacing = db.spacing or 2
    db.anchor = db.anchor or "TOPLEFT"
    db.offsetX = db.offsetX or -20
    db.offsetY = db.offsetY or -2
  end
end

local function HideAllBadges()
  for unit, frame in pairs(framesByUnit) do
    if frame and frame.TriBadges then
      for i = 1, 3 do
        local badge = frame.TriBadges[i]
        if badge then
          if badge.timerUpdate then
            badge.timerUpdate:Cancel()
            badge.timerUpdate = nil
          end
          badge.cooldown:Clear()
          if badge.timer then badge.timer:SetText("") end
          badge:Hide()
          M:HideGlow(badge)
          M:StopTestPulse(badge)
        end
      end
    end
  end
end

local function TryAutoAttach()
  if not AC.GetFrameForUnit then
    return
  end

  local attachedCount = 0
  for i = 1, 5 do
    local unit = "arena" .. i
    local frame = AC.GetFrameForUnit(unit)
    if frame then
      M:Attach(frame, unit)
      attachedCount = attachedCount + 1
    end
  end
end

function M:_EnsureEventFrame()
  if self._eventFrame then
    return self._eventFrame
  end

  local frame = CreateFrame("Frame")
  frame:SetScript("OnEvent", function(_, event, ...)
    self:HandleEvent(event, ...)
  end)
  self._eventFrame = frame
  return frame
end

function M:_RegisterEvents()
  local frame = self:_EnsureEventFrame()
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
  frame:RegisterUnitEvent("UNIT_AURA", "arena1", "arena2", "arena3", "arena4", "arena5")
end

function M:_UnregisterEvents()
  if self._eventFrame then
    self._eventFrame:UnregisterAllEvents()
  end
end

function M:OnEnable()
  self:_RegisterEvents()

  -- Run an initial attach to cover test mode and immediate login scenarios.
  C_Timer.After(0.25, function()
    if AC.testModeEnabled then
      self:RefreshAll()
      return
    end
    TryAutoAttach()
    self:RefreshAll()
  end)
end

function M:OnDisable()
  self:_UnregisterEvents()
  HideAllBadges()
end

function M:OnProfileChanged()
  self:RefreshAll()
  self:UpdateTimerFontSize()
end

function M:HandleEvent(event, ...)
  if event == "PLAYER_ENTERING_WORLD" or event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
    -- Clear GUID cache when entering world/arena (fresh start)
    wipe(guidToUnit)
    
    C_Timer.After(0.25, function()
      if AC.testModeEnabled then
        self:RefreshAll()
        return
      end
      TryAutoAttach()
      self:RefreshAll()
    end)
  elseif event == "UNIT_AURA" then
    if AC.testModeEnabled then return end
    local unit = ...
    local frame = framesByUnit[unit] or (AC.GetFrameForUnit and AC.GetFrameForUnit(unit))
    if frame then
      framesByUnit[unit] = frame
      UpdateAll(frame, unit)
    end
  end
end

-- NEW: Animation helper for test mode pulse
function M:ApplyTestPulse(badge)
  if not badge or badge.animGroup then return end
  local ag = badge.icon:CreateAnimationGroup()
  ag:SetLooping("BOUNCE")
  local alpha = ag:CreateAnimation("Alpha")
  alpha:SetDuration(1.2)
  alpha:SetFromAlpha(0.6)
  alpha:SetToAlpha(1.0)
  alpha:SetSmoothing("IN_OUT")
  ag:Play()
  badge.animGroup = ag
end

function M:StopTestPulse(badge)
  if badge and badge.animGroup then
    badge.animGroup:Stop()
    badge.icon:SetAlpha(1.0)
    badge.animGroup = nil
  end
end

-- NEW FEATURE: Countdown timer system (like trinkets)
function M:StartCountdownTimer(badge, expirationTime)
  if not badge or not badge.timer or not expirationTime then return end
  
  -- Cancel existing timer if any
  if badge.timerUpdate then
    badge.timerUpdate:Cancel()
    badge.timerUpdate = nil
  end
  
  -- Update timer text every 0.1 seconds
  local function UpdateTimerText()
    if not badge or not badge.timer then return end
    
    local remaining = expirationTime - GetTime()
    if remaining > 0 then
      -- Format: M:SS for times over 60s, just seconds for under 60s
      local minutes = math.floor(remaining / 60)
      local seconds = math.floor(remaining % 60)
      local timeText
      if minutes > 0 then
        timeText = string.format("%d:%02d", minutes, seconds)
      else
        timeText = string.format("%.0f", remaining)
      end
      badge.timer:SetText(timeText)
      
      -- Schedule next update
      badge.timerUpdate = C_Timer.NewTimer(0.1, UpdateTimerText)
    else
      -- Timer expired
      badge.timer:SetText("")
      badge.timerUpdate = nil
    end
  end
  
  -- Start the timer
  UpdateTimerText()
end

-- NEW FEATURE: Update font size for all timer texts
function M:UpdateTimerFontSize()
  local fontSize = (AC.DB and AC.DB.profile and AC.DB.profile.classPacks and AC.DB.profile.classPacks.fontSize) or 10
  
  for unit, frame in pairs(framesByUnit) do
    if frame.TriBadges then
      for i = 1, 3 do
        local badge = frame.TriBadges[i]
        if badge and badge.timer then
          badge.timer:SetFont(FONT, fontSize, "OUTLINE")
        end
      end
    end
  end
end


local function CreateBadge(parent)
  -- Create styled badge using new classic system
  local f = AC:CreateStyledIcon(parent, 18, true, true) -- Default size, will be updated in Layout()
  
  -- DEBUG: Check if border was created
  local hasBorder = f.border ~= nil
  local hasStyledBorder = f.styledBorder ~= nil
  local borderThickness = f.styledBorder and f.styledBorder.thickness or 0
  -- DEBUG DISABLED FOR PRODUCTION
  -- print(string.format("[CreateBadge] Created badge: hasBorder=%s, hasStyledBorder=%s, thickness=%d", 
  --   tostring(hasBorder), tostring(hasStyledBorder), borderThickness))
  
  -- Keep icon reference for compatibility
  f.icon = f.icon -- Already created by CreateStyledIcon
  
  -- Add cooldown frame (using helper to block OmniCC)
  local cd = AC:CreateCooldown(f, nil, "CooldownFrameTemplate")
  cd:SetAllPoints()
  cd:SetHideCountdownNumbers(true)
  cd:SetDrawEdge(false)
  -- CRITICAL: Make spiral very faint so icon is visible
  cd:SetSwipeColor(0, 0, 0, 0.3) -- Very faint black (30% opacity)
  
  -- CRITICAL: Exclude from OmniCC
  if _G.ArenaCore_ExcludeFromOmniCC then
    _G.ArenaCore_ExcludeFromOmniCC(cd, f)
  else
    -- Fallback if helper not loaded yet
    cd.noCooldownCount = true
    cd.noOCC = true
  end
  f.cooldown = cd
  
  -- Add stack count text (bottom-right corner)
  local count = f:CreateFontString(nil, "OVERLAY")
  count:SetFont(FONT, 10, "OUTLINE")
  count:SetPoint("BOTTOMRIGHT", -1, 1)
  count:SetJustifyH("RIGHT")
  f.count = count
  
  -- Add countdown timer text (center of icon) - NEW FEATURE
  local timer = cd:CreateFontString(nil, "OVERLAY")
  local fontSize = (AC.DB and AC.DB.profile and AC.DB.profile.classPacks and AC.DB.profile.classPacks.fontSize) or 10
  timer:SetFont(FONT, fontSize, "OUTLINE")
  timer:SetPoint("CENTER", cd, "CENTER", 0, 0)
  timer:SetTextColor(1, 1, 1, 1)
  cd.Text = timer
  f.timer = timer
  
  return f
end

local function Layout(frame)
  if not frame.TriBadges then return end
  local db = DB(); if not db then return end
  local size, spacing = db.size or 18, db.spacing or 2
  local growthDirection = db.growthDirection or "Vertical"
  
  -- DEBUG: Check frame and holder scales
  local frameName = frame:GetName() or "unknown"
  local frameScale = frame:GetScale()
  local holderScale = frame.TriBadgesHolder and frame.TriBadgesHolder:GetScale() or 1
  local effectiveScale = frameScale * holderScale
  -- DEBUG DISABLED FOR PRODUCTION
  -- print(string.format("[TriBadges Layout] %s: frameScale=%.2f, holderScale=%.2f, effective=%.2f", 
  --   frameName, frameScale, holderScale, effectiveScale))
  
  -- REMOVED: Don't force arena frame scale - respect user's scale settings
  -- The TriBadges holder has its own scale that's independent of the parent frame
  -- Forcing frame scale to 1.0 breaks the Arena Frames scale slider setting
  
  for i=1,3 do
    local b = frame.TriBadges[i]
    b:SetSize(size, size)
    b:ClearAllPoints()

    -- CRITICAL: Recalculate black border thickness after resizing
    -- This keeps the dark band behind the cyan border identical on all frames
    if AC.IconStyling and AC.IconStyling.UpdateBorderThickness then
      -- DEBUG: Log actual badge size and border thickness with ACTUAL pixel measurements
      local frameName = frame:GetName() or "unknown"
      local actualWidth = b:GetWidth() or 0
      local actualHeight = b:GetHeight() or 0
      local borderThicknessBefore = b.styledBorder and b.styledBorder.thickness or 0
      
      -- Get actual border texture heights BEFORE update
      local topHeightBefore = (b.styledBorder and b.styledBorder.top and b.styledBorder.top:GetHeight()) or 0
      
      AC.IconStyling:UpdateBorderThickness(b)
      
      -- Check after update with ACTUAL border texture measurements
      local borderThicknessAfter = b.styledBorder and b.styledBorder.thickness or 0
      local topHeightAfter = (b.styledBorder and b.styledBorder.top and b.styledBorder.top:GetHeight()) or 0
      
      -- DEBUG DISABLED FOR PRODUCTION
      -- print(string.format("[TriBadges] %s Badge %d: size=%.1fx%.1f, thickness %d->%d, actualTopHeight=%.1f", 
      --   frameName, i, actualWidth, actualHeight, borderThicknessBefore, borderThicknessAfter, topHeightAfter))
    end
  end

  -- Default to the top-left anchor
  local anchor = db.anchor or "TOPLEFT"
  
  -- CLEAN SLATE FIX: Simple, direct positioning
  -- Just use offsetX and offsetY directly - no complex calculations
  local ox = db.offsetX or -20
  local oy = db.offsetY or -2

  -- Anchor the first badge to the frame
  frame.TriBadges[1]:SetPoint(anchor, frame, anchor, ox, oy)
  
  -- Position remaining badges based on growth direction
  if growthDirection == "Horizontal" then
    -- Horizontal: Stack badges to the right
    frame.TriBadges[2]:SetPoint("LEFT", frame.TriBadges[1], "RIGHT", spacing, 0)
    frame.TriBadges[3]:SetPoint("LEFT", frame.TriBadges[2], "RIGHT", spacing, 0)
  else
    -- Vertical: Stack badges below (default)
    frame.TriBadges[2]:SetPoint("TOP", frame.TriBadges[1], "BOTTOM", 0, -spacing)
    frame.TriBadges[3]:SetPoint("TOP", frame.TriBadges[2], "BOTTOM", 0, -spacing)
  end
end

local function EnsureWidgets(frame)
  if frame.TriBadges then return end
  
  -- Create TriBadgesHolder first (for Z-order policy)
  if not frame.TriBadgesHolder then
    frame.TriBadgesHolder = CreateFrame("Frame", nil, frame)
    
    -- CRITICAL FIX: Inset TriBadgesHolder by border thickness so auras sit INSIDE the border
    -- Get border thickness from the class icon's styled border
    local borderThickness = frame.styledBorder and frame.styledBorder.thickness or 0
    
    if borderThickness > 0 then
      -- Inset by border thickness on all sides
      frame.TriBadgesHolder:SetPoint("TOPLEFT", frame, "TOPLEFT", borderThickness, -borderThickness)
      frame.TriBadgesHolder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderThickness, borderThickness)
    else
      -- No border, use full frame
      frame.TriBadgesHolder:SetAllPoints(frame)
    end
    
    frame.TriBadgesHolder:SetFrameStrata("HIGH")
    frame.TriBadgesHolder:SetFrameLevel((frame:GetFrameLevel() or 10) + 30)
    frame.TriBadgesHolder:SetToplevel(false)
  end
  
  -- Parent badges to holder instead of frame
  frame.TriBadges = { 
    CreateBadge(frame.TriBadgesHolder), 
    CreateBadge(frame.TriBadgesHolder), 
    CreateBadge(frame.TriBadgesHolder) 
  }
  
  -- Set strata/level for each badge
  for i = 1, 3 do
    local b = frame.TriBadges[i]
    b:SetFrameStrata(frame.TriBadgesHolder:GetFrameStrata())
    b:SetFrameLevel(frame.TriBadgesHolder:GetFrameLevel() + 1)
  end
  
  Layout(frame)
  
  -- Hide all badges initially
  for i=1,3 do frame.TriBadges[i]:Hide() end
end

---Update all TriBadge icons for a specific arena frame.
---@param frame Frame
---@param unit string
UpdateAll = function(frame, unit)
  if not frame or not unit then return end
  EnsureWidgets(frame)

  -- Avoid re-running layout unless settings changed; RefreshAll handles layout updates.
  local db = DB()
  local isEnabled = false

  if AC.DB and AC.DB.profile then
    if AC.DB.profile.classPacks and AC.DB.profile.classPacks.enabled ~= false then
      isEnabled = true
    elseif not AC.DB.profile.classPacks then
      isEnabled = true
    end
  else
    isEnabled = true
  end

  if not isEnabled then
    if frame.TriBadges then
      for i = 1, 3 do
        frame.TriBadges[i]:Hide()
        M:StopTestPulse(frame.TriBadges[i])
        M:HideGlow(frame.TriBadges[i])
      end
    end
    return
  end

  local _, instanceType = IsInInstance()
  local isInArena = instanceType == "arena"
  local isInPrepRoom = isInArena and (GetNumArenaOpponentSpecs() > 0 and not UnitExists(unit))

  if isInPrepRoom then
    if frame.TriBadges then
      for i = 1, 3 do
        frame.TriBadges[i]:Hide()
        M:StopTestPulse(frame.TriBadges[i])
        M:HideGlow(frame.TriBadges[i])
      end
    end
    return
  end

  if AC.testModeEnabled then
    local arenaIndex = tonumber(unit:match("arena(%d)")) or 1
    local testSetups = {
      [1] = {class = "DEATHKNIGHT", spec = 3},
      [2] = {class = "MAGE", spec = 2},
      [3] = {class = "HUNTER", spec = 2}
    }
    local testSetup = testSetups[arenaIndex] or testSetups[1]

    local classData = nil
    if AC.DB and AC.DB.profile and AC.DB.profile.classPacks then
      classData = AC.DB.profile.classPacks[testSetup.class]
    end
    if not classData and AC.ClassPacks then
      classData = AC.ClassPacks[testSetup.class]
    end

    local specData = classData and classData[testSetup.spec]

    if specData then
      for i = 1, 3 do
        local b = frame.TriBadges[i]
        if b then
          local categoryData = specData[i]
          if categoryData and #categoryData > 0 then
            local spellEntry = categoryData[1]
            local spellID = type(spellEntry) == "table" and spellEntry[1] or spellEntry
            if spellID then
              local spellInfo = C_Spell.GetSpellInfo(spellID)
              if spellInfo and spellInfo.iconID then
                b.icon:SetTexture(spellInfo.iconID)
                b.count:SetText("")
                b:SetAlpha(1)
                b:Show()
                M:ApplyTestPulse(b)

                if arenaIndex == 3 and i == 2 and spellID == 186265 then
                  local function StartTestCountdown()
                    if not AC.testModeEnabled or not b or not b.cooldown then return end
                    local duration = 8
                    local startTime = GetTime()
                    local expirationTime = startTime + duration
                    b.cooldown:SetCooldown(startTime, duration)
                    M:StartCountdownTimer(b, expirationTime)
                    C_Timer.After(duration + 0.5, function()
                      if AC.testModeEnabled and b and b:IsVisible() then
                        StartTestCountdown()
                      end
                    end)
                  end
                  StartTestCountdown()
                else
                  if b.cooldown then b.cooldown:Clear() end
                  if b.timer then b.timer:SetText("") end
                end
              else
                b.icon:SetTexture(136071)
                b.count:SetText("")
                b:SetAlpha(1)
                b:Show()
                M:ApplyTestPulse(b)
              end
            else
              b:Hide()
            end
          else
            b:Hide()
          end
        end
      end
    else
      for i = 1, 3 do
        local b = frame.TriBadges[i]
        if b then
          b.icon:SetTexture(136071)
          b.count:SetText("")
          b:SetAlpha(1)
          b:Show()
          M:ApplyTestPulse(b)
        end
      end
    end
    return
  end

  for i = 1, 3 do
    M:StopTestPulse(frame.TriBadges[i])
    M:HideGlow(frame.TriBadges[i])
  end

  M:UpdateLiveArenaIcons(frame, unit)
end

local function UpdateOne(frame, unit, slot)
  if IsTriBadgesRestricted() then return end -- MIDNIGHT: Disable in arena
  -- Check if AC.PickTriBadge exists, if not create a simple implementation
  if not AC.PickTriBadge then
    AC.PickTriBadge = function(unit, slot)
      -- Simple implementation: return test data or basic spell info
      if AC.testModeEnabled then
        local testSpells = {
          [1] = {icon = "Interface\\Icons\\spell_deathknight_classicon", duration = 0, expirationTime = 0, applications = 1}, -- Burst
          [2] = {icon = "Interface\\Icons\\ability_warrior_defensivestance", duration = 0, expirationTime = 0, applications = 1}, -- Defensive  
          [3] = {icon = "Interface\\Icons\\spell_mage_arcaneorb", duration = 0, expirationTime = 0, applications = 1}  -- Control
        }
        return testSpells[slot]
      end
      
      -- For live mode, try to get class pack data
      local class = UnitClass(unit)
      if class and AC.ClassPacks and AC.ClassPacks[class] then
        -- Find the spec
        local specID = GetArenaOpponentSpec(tonumber(unit:match("arena(%d+)")) or 1)
        if specID then
          local _, _, _, _, _, specClass = GetSpecializationInfoByID(specID)
          if specClass == class then
            -- Look for spec-specific data
            for specKey, specData in pairs(AC.ClassPacks[class]) do
              if type(specData) == "table" and specData[slot] then
                local spellData = specData[slot]
                if type(spellData) == "table" and spellData[1] then
                  local spellID = spellData[1]
                  local spellInfo = C_Spell.GetSpellInfo(spellID)
                  if spellInfo then
                    return {
                      icon = spellInfo.iconID,
                      duration = 0,
                      expirationTime = 0,
                      applications = spellData[2] or 1
                    }
                  end
                end
              end
            end
          end
        end
      end
      
      return nil -- No aura found
    end
  end
  
  local aura = AC.PickTriBadge(unit, slot)
  local b = frame.TriBadges[slot]
  if aura then
    b.icon:SetTexture(aura.icon)
    local start = (aura.expirationTime or 0) - (aura.duration or 0)
    if (aura.duration or 0) > 0 then 
      b.cooldown:SetCooldown(start, aura.duration)
      -- Start countdown timer update (shows duration in center)
      M:StartCountdownTimer(b, aura.expirationTime)
    else 
      b.cooldown:Clear()
      if b.timer then b.timer:SetText("") end
    end
    -- FIXED: Don't show stack counts - countdown timers are the primary display
    -- Stack counts would overlap/interfere with countdown timers
    b.count:SetText("")
    b:Show()
  else
    b:Hide()
    if b.timer then b.timer:SetText("") end
  end
end

-- FIXED: UpdateAll function with proper database handling
local function UpdateAll(frame, unit)
  if IsTriBadgesRestricted() then return end -- MIDNIGHT: Disable in arena
  if not frame or not unit then return end
  -- UpdateAll called for " .. unit
  EnsureWidgets(frame)
  -- CRITICAL FIX: Don't call Layout() on every update - only call it when settings change
  -- Layout(frame) is now only called from RefreshAll() when user changes settings

  -- FIXED: Check enabled state from multiple possible database paths
  local db = DB()
  local isEnabled = false
  
  -- Check multiple possible database paths for enabled state
  if AC.DB and AC.DB.profile then
    -- Path 1: Direct classPacks.enabled
    if AC.DB.profile.classPacks and AC.DB.profile.classPacks.enabled ~= false then
      isEnabled = true
    -- Path 2: Default enabled if no setting exists
    elseif not AC.DB.profile.classPacks then
      isEnabled = true -- Default to enabled
    end
  else
    -- No database yet, default to enabled
    isEnabled = true
  end
  
  -- Enabled state: " .. tostring(isEnabled)
  
  if not isEnabled then
    -- TriBadges disabled, hiding badges
    if frame.TriBadges then 
      for i=1,3 do 
        frame.TriBadges[i]:Hide()
        M:StopTestPulse(frame.TriBadges[i])
        M:HideGlow(frame.TriBadges[i])
      end 
    end
    return
  end

  -- CRITICAL: Check arena state - hide in prep room, show only in test mode or when spells are active in live arena
  local _, instanceType = IsInInstance()
  local isInArena = instanceType == "arena"
  local isInPrepRoom = isInArena and (GetNumArenaOpponentSpecs() > 0 and not UnitExists(unit))
  
  -- PREP ROOM: Hide completely (user requirement)
  if isInPrepRoom then
    if frame.TriBadges then
      for i=1,3 do
        frame.TriBadges[i]:Hide()
        M:StopTestPulse(frame.TriBadges[i])
        M:HideGlow(frame.TriBadges[i])
      end
    end
    return
  end
  
  -- TEST MODE: Show static icons for preview (user requirement - keep as-is)
  -- CRITICAL: Only show test mode data if NOT in a live arena match
  -- This prevents test mode auras from persisting when gates open
  if AC.testModeEnabled and not (isInArena and UnitExists(unit)) then
    -- Layout is handled by RefreshAll() when settings change, not on every update
    
    -- Test mode - showing real Class Pack spell icons matching class portraits
    local arenaIndex = tonumber(unit:match("arena(%d)")) or 1
    local testSetups = {
        [1] = {class = "DEATHKNIGHT", spec = 3}, -- Unholy Death Knight
        [2] = {class = "MAGE", spec = 2},        -- Fire Mage  
        [3] = {class = "HUNTER", spec = 2}       -- Marksmanship Hunter
    }
    local testSetup = testSetups[arenaIndex] or testSetups[1]

    -- Get class pack data from the real Class Packs system
    local classData = nil
    
    -- Try database first (user's customized data)
    if AC.DB and AC.DB.profile and AC.DB.profile.classPacks then
        classData = AC.DB.profile.classPacks[testSetup.class]
    end
    
    -- Fallback to default Class Packs data
    if not classData and AC.ClassPacks then
        classData = AC.ClassPacks[testSetup.class]
    end
    
    -- Get spec data
    local specData = classData and classData[testSetup.spec]
    
    if specData then
        -- Test mode using class and spec for frame
        
        for i=1,3 do
            local b = frame.TriBadges[i]
            if b then
                local categoryData = specData[i] -- i = slot (1=Burst, 2=Defensive, 3=Control)
                if categoryData and #categoryData > 0 then
                    -- Show the first (highest priority) spell in each category
                    local spellEntry = categoryData[1]
                    local spellID = type(spellEntry) == "table" and spellEntry[1] or spellEntry
                    local priority = type(spellEntry) == "table" and spellEntry[2] or 1
                    
                    if spellID then
                        local spellInfo = C_Spell.GetSpellInfo(spellID)
                        if spellInfo and spellInfo.iconID then
                            b.icon:SetTexture(spellInfo.iconID)
                            -- FIXED: Don't show priority numbers - timers will show duration instead
                            b.count:SetText("")
                            b:SetAlpha(1)
                            b:Show()
                            M:ApplyTestPulse(b)
                            
                            -- NEW FEATURE: Test mode countdown for Arena 3, slot 2 (Aspect of the Turtle)
                            -- This allows users to preview timer font size and see countdown in action
                            if arenaIndex == 3 and i == 2 and spellID == 186265 then
                                -- Aspect of the Turtle: 8 second duration with looping countdown
                                local function StartTestCountdown()
                                    if not AC.testModeEnabled then return end
                                    if not b or not b.cooldown then return end
                                    
                                    local duration = 8
                                    local startTime = GetTime()
                                    local expirationTime = startTime + duration
                                    
                                    -- Start cooldown spiral
                                    b.cooldown:SetCooldown(startTime, duration)
                                    
                                    -- Start countdown timer
                                    M:StartCountdownTimer(b, expirationTime)
                                    
                                    -- Loop the countdown after it expires (for continuous preview)
                                    C_Timer.After(duration + 0.5, function()
                                        if AC.testModeEnabled and b and b:IsVisible() then
                                            StartTestCountdown()
                                        end
                                    end)
                                end
                                
                                -- Start the looping countdown
                                StartTestCountdown()
                            else
                                -- Clear any existing cooldowns for other badges
                                if b.cooldown then
                                    b.cooldown:Clear()
                                end
                                if b.timer then
                                    b.timer:SetText("")
                                end
                            end
                            -- Spell icon set successfully
                        else
                            -- Fallback to sheep icon if spell not found
                            b.icon:SetTexture(136071)
                            b.count:SetText("")
                            b:SetAlpha(1)
                            b:Show()
                            M:ApplyTestPulse(b)
                            -- Using fallback icon
                        end
                    else
                        b:Hide()
                    end
                else
                    b:Hide()
                end
            end
        end
    else
        -- Fallback to old dummy icons if no class data found
        -- No spec data found, using fallback icons
        for i=1,3 do
            local b = frame.TriBadges[i]
            if b then
                b.icon:SetTexture(136071) -- Polymorph icon for testing
                b.count:SetText("")
                b:SetAlpha(1)
                b:Show()
                M:ApplyTestPulse(b)
            end
        end
    end
    return
  end

  -- Stop any leftover animations from test mode
  for i=1,3 do 
    M:StopTestPulse(frame.TriBadges[i])
    M:HideGlow(frame.TriBadges[i])
  end
  
  -- LIVE ARENA MODE: Only show icons when spells are ACTIVELY USED (user requirement)
  -- Icons start hidden and only appear when enemy uses the spell
  -- This is handled by OnSpellCast() which tracks active spells
  M:UpdateLiveArenaIcons(frame, unit)
end

-- ============================================================================
-- LIVE ARENA REAL-TIME SPELL TRACKING SYSTEM
-- ============================================================================

-- Track active spells per unit per category with priority system
-- Structure: activeSpells[unit][category] = {spellID = expirationTime}
local activeSpells = {}

-- Native WoW-style glow effect functions (manual implementation)
function M:ShowGlow(badge, color)
  if not badge then return end
  
  -- Create glow frame if it doesn't exist
  if not badge.glow then
    badge.glow = CreateFrame("Frame", nil, badge)
    -- CRITICAL: Position glow OUTSIDE the icon border for better visibility
    -- Extend 6 pixels beyond the badge on all sides
    badge.glow:SetPoint("TOPLEFT", badge, "TOPLEFT", -6, 6)
    badge.glow:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", 6, -6)
    badge.glow:SetFrameLevel(badge:GetFrameLevel() + 1)
    
    -- Create glow texture (golden glow effect)
    badge.glow.texture = badge.glow:CreateTexture(nil, "OVERLAY")
    badge.glow.texture:SetAllPoints()
    badge.glow.texture:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    badge.glow.texture:SetBlendMode("ADD")
    badge.glow.texture:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    
    -- Create animation group for pulsing glow
    badge.glow.animGroup = badge.glow.texture:CreateAnimationGroup()
    badge.glow.animGroup:SetLooping("REPEAT")
    
    -- Scale animation (pulse effect) - more subtle to keep icon visible
    local scale1 = badge.glow.animGroup:CreateAnimation("Scale")
    scale1:SetDuration(0.6)
    scale1:SetScale(1.2, 1.2) -- Reduced from 1.5 to 1.2 for subtler effect
    scale1:SetSmoothing("IN_OUT")
    
    local scale2 = badge.glow.animGroup:CreateAnimation("Scale")
    scale2:SetDuration(0.6)
    scale2:SetScale(0.833, 0.833) -- Back to 1.0 (1.2 * 0.833 = 1.0)
    scale2:SetSmoothing("IN_OUT")
    scale2:SetStartDelay(0.6)
    
    -- Alpha animation (fade in/out) - brighter for better visibility
    local alpha1 = badge.glow.animGroup:CreateAnimation("Alpha")
    alpha1:SetDuration(0.6)
    alpha1:SetFromAlpha(0.7) -- Increased from 0.5 for brighter glow
    alpha1:SetToAlpha(1.0)
    alpha1:SetSmoothing("IN_OUT")
    
    local alpha2 = badge.glow.animGroup:CreateAnimation("Alpha")
    alpha2:SetDuration(0.6)
    alpha2:SetFromAlpha(1.0)
    alpha2:SetToAlpha(0.7) -- Increased from 0.5 for brighter glow
    alpha2:SetSmoothing("IN_OUT")
    alpha2:SetStartDelay(0.6)
    
    badge.glow:Hide()
  end
  
  -- CRITICAL: Set glow color (blue for casts, default golden for instant)
  if color and type(color) == "table" and #color >= 3 then
    badge.glow.texture:SetVertexColor(color[1], color[2], color[3], color[4] or 1.0)
  else
    badge.glow.texture:SetVertexColor(1.0, 0.85, 0.0, 1.0) -- Default golden glow
  end
  
  -- Show and start animation
  badge.glow:Show()
  if badge.glow.animGroup then
    badge.glow.animGroup:Play()
  end
end

function M:HideGlow(badge)
  if badge and badge.glow then
    if badge.glow.animGroup then
      badge.glow.animGroup:Stop()
    end
    badge.glow:Hide()
  end
end

-- Update live arena icons based on actively used spells
function M:UpdateLiveArenaIcons(frame, unit)
  if IsTriBadgesRestricted() then return end -- MIDNIGHT: Disable in arena
  if not frame or not frame.TriBadges then return end
  
  -- CRITICAL FIX: Extract arena index from unit (e.g., "arena1" -> 1)
  local arenaIndex = tonumber(unit:match("arena(%d+)"))
  if not arenaIndex then return end
  
  -- CRITICAL FIX: Check if unit is dead - clear all active spells if dead
  if UnitIsDead(unit) then
    -- Clear all active spells for this unit
    if activeSpells[unit] then
      activeSpells[unit] = {}
    end
    
    -- Hide all badges and glows
    for i=1,3 do
      frame.TriBadges[i]:Hide()
      M:HideGlow(frame.TriBadges[i])
      M:StopTestPulse(frame.TriBadges[i])
    end
    return
  end
  
  -- Get spec ID for this unit
  local specID = GetArenaOpponentSpec(arenaIndex)
  
  if not specID or specID == 0 then
    -- No spec detected yet, hide all badges
    for i=1,3 do
      frame.TriBadges[i]:Hide()
      M:HideGlow(frame.TriBadges[i])
    end
    return
  end
  
  -- Get class from spec
  local _, _, _, _, _, classFile = GetSpecializationInfoByID(specID)
  if not classFile then return end
  
  -- Get class pack data for this class/spec
  local classData = nil
  if AC.DB and AC.DB.profile and AC.DB.profile.classPacks then
    classData = AC.DB.profile.classPacks[classFile]
  end
  
  if not classData and AC.ClassPacks then
    classData = AC.ClassPacks[classFile]
  end
  
  if not classData then
    -- No class pack data, hide all badges
    for i=1,3 do
      frame.TriBadges[i]:Hide()
      M:HideGlow(frame.TriBadges[i])
    end
    return
  end
  
  -- CRITICAL FIX: Detect actual arena opponent spec (not just first spec)
  local specIndex = nil
  local arenaIndex = unit:match("arena(%d)")
  
  if arenaIndex then
    arenaIndex = tonumber(arenaIndex)
    local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(arenaIndex)
    
    if specID and specID > 0 then
      -- Map specID to spec index using WoW API
      -- GetSpecializationInfoByID returns: id, name, description, icon, role, classFile
      local _, specName, _, _, _, specClassFile = GetSpecializationInfoByID(specID)
      
      -- Verify class matches
      if specClassFile == classFile then
        -- Map specID to spec index (1, 2, 3, or 4 for Druid)
        -- Death Knight: Blood=250, Frost=251, Unholy=252
        -- We need to find which position this spec is in its class
        local specIDMap = {
          -- Death Knight
          [250] = 1, -- Blood
          [251] = 2, -- Frost
          [252] = 3, -- Unholy
          -- Warrior
          [71] = 1,  -- Arms
          [72] = 2,  -- Fury
          [73] = 3,  -- Protection
          -- Paladin
          [65] = 1,  -- Holy
          [66] = 2,  -- Protection
          [70] = 3,  -- Retribution
          -- Hunter
          [253] = 1, -- Beast Mastery
          [254] = 2, -- Marksmanship
          [255] = 3, -- Survival
          -- Rogue
          [259] = 1, -- Assassination
          [260] = 2, -- Outlaw
          [261] = 3, -- Subtlety
          -- Priest
          [256] = 1, -- Discipline
          [257] = 2, -- Holy
          [258] = 3, -- Shadow
          -- Shaman
          [262] = 1, -- Elemental
          [263] = 2, -- Enhancement
          [264] = 3, -- Restoration
          -- Mage
          [62] = 1,  -- Arcane
          [63] = 2,  -- Fire
          [64] = 3,  -- Frost
          -- Warlock
          [265] = 1, -- Affliction
          [266] = 2, -- Demonology
          [267] = 3, -- Destruction
          -- Monk
          [268] = 1, -- Brewmaster
          [270] = 2, -- Mistweaver
          [269] = 3, -- Windwalker
          -- Druid
          [102] = 1, -- Balance
          [103] = 2, -- Feral
          [104] = 3, -- Guardian
          [105] = 4, -- Restoration
          -- Demon Hunter
          [577] = 1, -- Havoc
          [581] = 2, -- Vengeance
          -- Evoker
          [1467] = 1, -- Devastation
          [1468] = 2, -- Preservation
          [1473] = 3, -- Augmentation
        }
        
        specIndex = specIDMap[specID]
        
        -- ENHANCED DEBUG: Show spec detection
        if AC.TRIBADGES_DEBUG then
          if specIndex then
            print(string.format("|cff00FFFF[TriBadges]|r Detected spec: %s (specID %d → index %d) for %s", specName or "Unknown", specID, specIndex, unit))
          else
            print(string.format("|cffFF0000[TriBadges]|r Unknown specID %d (%s) for %s - using fallback", specID, specName or "Unknown", unit))
          end
        end
      else
        -- ENHANCED DEBUG: Class mismatch
        if AC.TRIBADGES_DEBUG then
          print(string.format("|cffFF0000[TriBadges]|r Class mismatch: specID %d is %s but unit is %s", specID, specClassFile or "Unknown", classFile))
        end
      end
    else
      -- ENHANCED DEBUG: No specID
      if AC.TRIBADGES_DEBUG then
        print(string.format("|cffFF0000[TriBadges]|r No specID available for %s", unit))
      end
    end
  end
  
  -- Fallback: If spec detection failed, use first available spec
  if not specIndex then
    if AC.TRIBADGES_DEBUG then
      print(string.format("|cffFFAA00[TriBadges]|r Using fallback (first spec) for %s", unit))
    end
    for idx, data in pairs(classData) do
      if type(idx) == "number" and type(data) == "table" then
        specIndex = idx
        break
      end
    end
  end
  
  if not specIndex then
    for i=1,3 do
      frame.TriBadges[i]:Hide()
      M:HideGlow(frame.TriBadges[i])
    end
    return
  end
  
  local specData = classData[specIndex]
  if not specData then
    for i=1,3 do
      frame.TriBadges[i]:Hide()
      M:HideGlow(frame.TriBadges[i])
    end
    return
  end
  
  -- Initialize active spells table for this unit if needed
  if not activeSpells[unit] then
    activeSpells[unit] = {}
  end
  
  local currentTime = GetTime()
  
  -- ============================================================================
  -- PRIMARY METHOD: Scan buffs using AuraUtil.ForEachAura
  -- ============================================================================
  -- More reliable than index scanning
  local verifiedBuffs = {}
  local bbpMethodWorked = false
  local buffCount = 0
  
  -- ENHANCED DEBUG: Show scanning start
  if AC.TRIBADGES_DEBUG then
    print(string.format("|cff00FFFF[TriBadges]|r ========== SCANNING BUFFS ON %s ==========", unit))
  end
  
  if AuraUtil and AuraUtil.ForEachAura then
    AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId)
      if spellId and expirationTime and expirationTime > 0 then
        verifiedBuffs[spellId] = {
          expirationTime = expirationTime,
          duration = duration,
          method = "BBP" -- Debug: track which method found this
        }
        bbpMethodWorked = true
        buffCount = buffCount + 1
        
        -- ENHANCED DEBUG: Show ALL buffs found (not just Class Pack spells)
        if AC.TRIBADGES_DEBUG then
          local buffName = name or C_Spell.GetSpellName(spellId) or "Unknown"
          local timeLeft = expirationTime - GetTime()
          print(string.format("|cff00FFFF[TriBadges]|r   [BBP] Found buff: %s (%d) expires in %.1fs", buffName, spellId, timeLeft))
          
          -- SPECIAL: Highlight Unholy Assault if found
          if spellId == 207289 then
            print(string.format("|cffFF00FF[TriBadges]|r   ★★★ UNHOLY ASSAULT DETECTED ★★★"))
          end
        end
      end
      return false -- Continue scanning
    end)
    
    -- ENHANCED DEBUG: Show BBP method result
    if AC.TRIBADGES_DEBUG then
      if bbpMethodWorked then
        print(string.format("|cff00FF00[TriBadges]|r BBP method SUCCESS: Found %d buffs", buffCount))
      else
        print(string.format("|cffFF0000[TriBadges]|r BBP method FAILED: No buffs found"))
      end
    end
  else
    -- ENHANCED DEBUG: Show if AuraUtil not available
    if AC.TRIBADGES_DEBUG then
      print(string.format("|cffFF0000[TriBadges]|r BBP method UNAVAILABLE: AuraUtil.ForEachAura not found"))
    end
  end
  
  -- ============================================================================
  -- OLD METHOD (FALLBACK): Scan buffs using C_UnitAuras.GetBuffDataByIndex
  -- ============================================================================
  -- Keep this as fallback in case AuraUtil fails or isn't available
  if not bbpMethodWorked then
    if AC.TRIBADGES_DEBUG then
      print(string.format("|cffFFAA00[TriBadges]|r Falling back to OLD scanning method..."))
    end
    
    for i = 1, 40 do -- Scan up to 40 buffs
      local auraData = C_UnitAuras.GetBuffDataByIndex(unit, i)
      if not auraData then break end
      
      local spellID = auraData.spellId
      local expirationTime = auraData.expirationTime
      local duration = auraData.duration
      
      if spellID and expirationTime and expirationTime > 0 then
        verifiedBuffs[spellID] = {
          expirationTime = expirationTime,
          duration = duration,
          method = "OLD" -- Debug: track which method found this
        }
        buffCount = buffCount + 1
        
        -- ENHANCED DEBUG: Show ALL buffs found
        if AC.TRIBADGES_DEBUG then
          local buffName = C_Spell.GetSpellName(spellID) or "Unknown"
          local timeLeft = expirationTime - GetTime()
          print(string.format("|cffFFAA00[TriBadges]|r   [OLD] Found buff: %s (%d) expires in %.1fs", buffName, spellID, timeLeft))
          
          -- SPECIAL: Highlight Unholy Assault if found
          if spellID == 207289 then
            print(string.format("|cffFF00FF[TriBadges]|r   ★★★ UNHOLY ASSAULT DETECTED ★★★"))
          end
        end
      end
    end
    
    -- ENHANCED DEBUG: Show OLD method result
    if AC.TRIBADGES_DEBUG then
      print(string.format("|cff00FF00[TriBadges]|r OLD method: Found %d buffs", buffCount))
    end
  end
  
  -- ENHANCED DEBUG: Show total buffs found
  if AC.TRIBADGES_DEBUG then
    print(string.format("|cff00FFFF[TriBadges]|r ========== TOTAL: %d BUFFS FOUND ON %s ==========", buffCount, unit))
  end
  
  -- For each category (1=Burst, 2=Defensive, 3=Control)
  for category = 1, 3 do
    local badge = frame.TriBadges[category]
    local categoryData = specData[category]
    
    if not categoryData or #categoryData == 0 then
      badge:Hide()
      M:HideGlow(badge)
    else
      -- Find highest priority ACTIVE spell in this category
      local highestPrioritySpell = nil
      local highestPriority = math.huge -- CRITICAL FIX: Use math.huge instead of 999
      local expirationTime = 0
      local duration = 0
      
      -- ENHANCED DEBUG: Show all active buffs in this category
      if AC.TRIBADGES_DEBUG then
        local categoryNames = {[1] = "BURST", [2] = "DEFENSIVE", [3] = "CONTROL"}
        print(string.format("|cffFFAA00[TriBadges]|r === %s Category %s - Checking %d spells ===", unit, categoryNames[category], #categoryData))
      end
      
      -- Check all spells in this category
      for spellIndex, spellEntry in ipairs(categoryData) do
        local spellID = type(spellEntry) == "table" and spellEntry[1] or spellEntry
        local priority = type(spellEntry) == "table" and spellEntry[2] or 1
        local spellName = C_Spell.GetSpellName(spellID) or "Unknown"
        
        -- ENHANCED DEBUG: Show what we're checking
        if AC.TRIBADGES_DEBUG then
          print(string.format("|cff00FF00[TriBadges]|r   [%d] Checking %s (%d) priority=%d", spellIndex, spellName, spellID, priority))
        end
        
        -- CRITICAL FIX: Only show if buff is ACTUALLY on the unit (verified by UnitAura)
        if verifiedBuffs[spellID] then
          local buffData = verifiedBuffs[spellID]
          
          -- ENHANCED DEBUG: Show detection method and expiration
          if AC.TRIBADGES_DEBUG then
            local timeLeft = buffData.expirationTime - currentTime
            print(string.format("|cff00FF00[TriBadges]|r     ✓ ACTIVE via %s method, expires in %.1fs", buffData.method, timeLeft))
          end
          
          -- Only consider if not expired
          if buffData.expirationTime > currentTime then
            -- CRITICAL FIX: Higher priority = lower number (1 is highest)
            -- Compare: if this spell's priority is LOWER (better) than current best
            if priority < highestPriority then
              -- ENHANCED DEBUG: Show priority comparison
              if AC.TRIBADGES_DEBUG then
                if highestPrioritySpell then
                  local oldSpellName = C_Spell.GetSpellName(highestPrioritySpell) or "Unknown"
                  print(string.format("|cffFFAA00[TriBadges]|r     → NEW WINNER: %s (priority %d) beats %s (priority %d)", spellName, priority, oldSpellName, highestPriority))
                else
                  print(string.format("|cffFFAA00[TriBadges]|r     → FIRST WINNER: %s (priority %d)", spellName, priority))
                end
              end
              
              highestPriority = priority
              highestPrioritySpell = spellID
              expirationTime = buffData.expirationTime
              duration = buffData.duration or (buffData.expirationTime - currentTime)
            else
              -- ENHANCED DEBUG: Show why this spell lost
              if AC.TRIBADGES_DEBUG then
                local currentWinner = C_Spell.GetSpellName(highestPrioritySpell) or "Unknown"
                print(string.format("|cff888888[TriBadges]|r     ✗ LOSES: priority %d >= current best %d (%s)", priority, highestPriority, currentWinner))
              end
            end
          else
            -- ENHANCED DEBUG: Show expired spell
            if AC.TRIBADGES_DEBUG then
              print(string.format("|cff888888[TriBadges]|r     ✗ EXPIRED: buff ended"))
            end
          end
        else
          -- ENHANCED DEBUG: Show spell not active
          if AC.TRIBADGES_DEBUG then
            print(string.format("|cff888888[TriBadges]|r     ✗ NOT ACTIVE on unit"))
          end
        end
      end
      
      -- ENHANCED DEBUG: Show final winner
      if AC.TRIBADGES_DEBUG then
        if highestPrioritySpell then
          local winnerName = C_Spell.GetSpellName(highestPrioritySpell) or "Unknown"
          print(string.format("|cff00FF00[TriBadges]|r === FINAL WINNER: %s (%d) priority=%d ===", winnerName, highestPrioritySpell, highestPriority))
        else
          print(string.format("|cff888888[TriBadges]|r === NO ACTIVE SPELLS IN THIS CATEGORY ==="))
        end
      end
      
      -- Show the highest priority active spell, or hide if none active
      if highestPrioritySpell then
        local spellInfo = C_Spell.GetSpellInfo(highestPrioritySpell)
        if spellInfo and spellInfo.iconID then
          -- CRITICAL FIX: Only update if spell changed to prevent flickering
          local currentSpell = badge.currentSpellID
          if currentSpell ~= highestPrioritySpell then
            badge.icon:SetTexture(spellInfo.iconID)
            badge.currentSpellID = highestPrioritySpell
          end
          
          -- CRITICAL FIX: Don't show priority numbers - show countdown timers instead
          badge.count:SetText("")
          
          -- CRITICAL FIX: Start countdown timer (like trinkets/racials)
          if expirationTime and expirationTime > currentTime then
            local duration = expirationTime - currentTime
            badge.cooldown:SetCooldown(currentTime, duration)
            -- Start countdown timer update
            M:StartCountdownTimer(badge, expirationTime)
          else
            badge.cooldown:Clear()
            if badge.timer then badge.timer:SetText("") end
          end
          
          -- CRITICAL: Determine if spell is a cast or instant for glow color
          local isCastSpell = false
          local spellCastTime = C_Spell.GetSpellInfo(highestPrioritySpell)
          if spellCastTime and spellCastTime.castTime and spellCastTime.castTime > 0 then
            isCastSpell = true
          end
          
          badge:SetAlpha(1)
          -- CRITICAL FIX: Only call Show() if not already shown to prevent flickering
          if not badge:IsShown() then
            badge:Show()
          end
          
          -- Show glow border: BLUE for cast spells, DEFAULT for instant spells
          if isCastSpell then
            M:ShowGlow(badge, {0.3, 0.5, 1.0, 1.0}) -- Blue glow for cast spells
          else
            M:ShowGlow(badge) -- Default glow for instant spells
          end
          M:ApplyTestPulse(badge) -- Keep the pulse animation
        else
          -- CRITICAL FIX: Only call Hide() if currently shown to prevent flickering
          if badge:IsShown() then
            badge:Hide()
            M:HideGlow(badge)
          end
        end
      else
        -- No active spells in this category
        -- CRITICAL FIX: Only call Hide() if currently shown to prevent flickering
        if badge:IsShown() then
          badge:Hide()
          M:HideGlow(badge)
          M:StopTestPulse(badge)
        end
      end
    end
  end
end

-- Called from COMBAT_LOG when enemy uses a spell
function M:OnSpellCast(unit, spellID, eventType)
  if not unit or not spellID then return end
  if not activeSpells[unit] then
    activeSpells[unit] = {}
  end
  
  -- Get class and spec for this unit
  local arenaIndex = tonumber(unit:match("arena(%d)")) or 0
  if arenaIndex == 0 then return end
  
  local specID = GetArenaOpponentSpec(arenaIndex)
  if not specID or specID == 0 then return end
  
  local _, _, _, _, _, classFile = GetSpecializationInfoByID(specID)
  if not classFile then return end
  
  -- Get class pack data
  local classData = nil
  if AC.DB and AC.DB.profile and AC.DB.profile.classPacks then
    classData = AC.DB.profile.classPacks[classFile]
  end
  
  if not classData and AC.ClassPacks then
    classData = AC.ClassPacks[classFile]
  end
  
  if not classData then return end
  
  -- Find which category this spell belongs to
  for specIndex, specData in pairs(classData) do
    if type(specIndex) == "number" and type(specData) == "table" then
      for category = 1, 3 do
        local categoryData = specData[category]
        if categoryData then
          for _, spellEntry in ipairs(categoryData) do
            local trackedSpellID = type(spellEntry) == "table" and spellEntry[1] or spellEntry
            
            if trackedSpellID == spellID then
              -- Found it! Mark as active
              if not activeSpells[unit][category] then
                activeSpells[unit][category] = {}
              end
              
              -- CRITICAL: Category 3 (Control) spells like Polymorph should NOT have cooldown timers
              -- They only show while casting, handled by cast events
              -- Categories 1 (Burst) and 2 (Defensive) get cooldown timers
              
              local duration = 0
              if category ~= 3 then
                -- Burst and Defensive spells get cooldown tracking
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                duration = 10 -- Default 10 seconds if we can't get duration
              end
              
              -- Set expiration time
              activeSpells[unit][category][spellID] = GetTime() + duration
              
              -- CRITICAL FIX: Only update the specific badge that changed (prevents flickering)
              local frame = framesByUnit[unit]
              if frame and frame.TriBadges and frame.TriBadges[category] then
                local badge = frame.TriBadges[category]
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                
                if spellInfo and spellInfo.iconID then
                  -- Only update if icon actually changed (prevents unnecessary redraws)
                  local currentTexture = badge.icon:GetTexture()
                  if currentTexture ~= spellInfo.iconID then
                    badge.icon:SetTexture(spellInfo.iconID)
                  end
                  
                  badge.count:SetText("")
                  
                  -- Update cooldown (only for Burst/Defensive, not Control)
                  if duration > 0 then
                    badge.cooldown:SetCooldown(GetTime(), duration)
                    M:StartCountdownTimer(badge, GetTime() + duration)
                  else
                    -- Control spells: no cooldown, just show icon
                    badge.cooldown:Clear()
                    if badge.timer then badge.timer:SetText("") end
                  end
                  
                  badge:Show()
                end
              end
              
              return
            end
          end
        end
      end
    end
  end
end

-- CRITICAL FIX: Handle COMBAT_LOG events by GUID (like TrinketsRacials pattern)
-- This is called for SPELL_AURA_APPLIED events where we only have GUID, not unit token
function M:OnSpellCastByGUID(guid, spellID, eventType)
  if not guid or not spellID then return end
  
  -- Resolve GUID to arena unit (arena1/2/3/4/5)
  local unit = ResolveUnitForGUID(guid)
  if not unit then return end
  
  -- Now call the regular OnSpellCast with the resolved unit
  self:OnSpellCast(unit, spellID, eventType)
end


function M:Attach(frame, unit)
  if not frame or not unit then return end
  EnsureWidgets(frame)
  framesByUnit[unit] = frame
  UpdateAll(frame, unit)
end

function M:RefreshAll()
  -- CRITICAL FIX: RefreshAll must work in BOTH test mode and live arena
  -- UpdateAll() handles test mode vs live mode internally (line 249)
  for unit, frame in pairs(framesByUnit) do 
    -- CRITICAL FIX: Update TriBadgesHolder positioning when border thickness changes
    if frame.TriBadgesHolder then
      local borderThickness = frame.styledBorder and frame.styledBorder.thickness or 0
      frame.TriBadgesHolder:ClearAllPoints()
      
      if borderThickness > 0 then
        -- Inset by border thickness on all sides
        frame.TriBadgesHolder:SetPoint("TOPLEFT", frame, "TOPLEFT", borderThickness, -borderThickness)
        frame.TriBadgesHolder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderThickness, borderThickness)
      else
        -- No border, use full frame
        frame.TriBadgesHolder:SetAllPoints(frame)
      end
    end
    
    -- CRITICAL: Call Layout() here when settings change (not on every UNIT_AURA)
    Layout(frame)
    UpdateAll(frame, unit)
    
    -- CRITICAL: Also update live arena icons to handle dead units
    if not AC.testModeEnabled then
      M:UpdateLiveArenaIcons(frame, unit)
    end
  end
end

SLASH_ARENA_CORE_TRI1 = "/actri"
SlashCmdList["ARENA_CORE_TRI"] = function(msg)
  msg=(msg or ""):lower()
  local db=DB()
  if not db then 
    print("|cffFF4444TriBadges:|r No database found!")
    return 
  end
  local a,b=msg:match("(%S+)%s+(.*)")
  a=a or msg
  if a=="auto" then
    db.autoByEnemyClass=(b=="on")
    M:RefreshAll()
  elseif a=="size" then
    local n=tonumber(b)
    if n then db.size=math.max(12,min(28,math.floor(n))); M:RefreshAll() end
  elseif a=="enable" then
    db.enabled=(b=="on")
    print("|cff00FFFFTriBadges:|r Enabled = " .. tostring(db.enabled))
    M:RefreshAll()
  elseif a=="status" then
    print("|cff00FFFFTriBadges:|r Status - Enabled: " .. tostring(db.enabled) .. ", Size: " .. (db.size or "nil"))
  elseif a=="class" then
    local k=(b or ""):upper()
    if k~="" then AC.ApplyClassPack(k,{}); M:RefreshAll() end
  elseif a=="manual" then
    local k=(b or ""):upper()
    if k~="" then AC.ApplyClassPack(k,{setAsManual=true}); M:RefreshAll() end
  else
    print("|cff00FFFFTriBadges:|r Commands: enable on/off, status, size <number>")
  end
end