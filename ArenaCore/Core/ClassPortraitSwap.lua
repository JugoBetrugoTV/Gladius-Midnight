-- Core/ClassPortraitSwap.lua
-- Swaps player portraits to class icons using ArenaCore custom assets
local AC = _G.ArenaCore
if not AC then return end

local M = {}
AC.ClassPortraitSwap = M

-- Using EasyFrames proven pattern - no throttle needed

local CLASS_ICON_PATH = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\"
local CLASS_FILES = {
  DEATHKNIGHT = "Deathknight.tga",
  DEMONHUNTER = "Demonhunter.tga",
  DRUID       = "Druid.tga",
  EVOKER      = "Evoker.tga",
  HUNTER      = "Hunter.tga",
  MAGE        = "Mage.tga",
  MONK        = "Monk.tga",
  PALADIN     = "Paladin.tga",
  PRIEST      = "Priest.tga",
  ROGUE       = "Rogue.tga",
  SHAMAN      = "Shaman.tga",
  WARLOCK     = "Warlock.tga",
  WARRIOR     = "Warrior.tga",
}

-- ColdClasses theme files (WoW Default Style+Midnight Chill)
local COLDCLASSES_PATH = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\"
local COLDCLASSES_FILES = {
  DEATHKNIGHT = "deathknight.png",
  DEMONHUNTER = "demonhunter.png",
  DRUID       = "druid.png",
  EVOKER      = "evoker.png",
  HUNTER      = "hunter.png",
  MAGE        = "mage.png",
  MONK        = "monk.png",
  PALADIN     = "paladin.png",
  PRIEST      = "priest.png",
  ROGUE       = "rogue.png",
  SHAMAN      = "shaman.png",
  WARLOCK     = "warlock.png",
  WARRIOR     = "warrior.png",
}

local function IsEnabled()
  local db = AC.DB and AC.DB.profile and AC.DB.profile.classPortraitSwap
  return db and db.enabled
end

local function GetClassTexturePath(classToken)
  if not classToken then return nil end
  
  -- Get settings from database
  local db = AC.DB and AC.DB.profile
  local useCustomIcons = db and db.classPortraitSwap and db.classPortraitSwap.useCustomIcons
  
  -- When checkbox is ON: Use ArenaCore custom icons
  -- When checkbox is OFF: Use Midnight Chill (coldclasses) icons
  if useCustomIcons then
    -- Use ArenaCore Custom icons
    local file = CLASS_FILES[classToken]
    return file and (CLASS_ICON_PATH .. file) or nil
  else
    -- Use Midnight Chill (coldclasses) icons
    local file = COLDCLASSES_FILES[classToken]
    return file and (COLDCLASSES_PATH .. file) or nil
  end
end

-- Reset a portrait back to the default unit portrait
local function ResetPortrait(tex, unit)
  if not tex or not unit then return end
  if _G.SetPortraitTexture then
    pcall(SetPortraitTexture, tex, unit)
  end
end

-- Apply to a single portrait texture if it's a player unit portrait
local function ApplyToPortrait(tex, unit)
  if not tex or not unit then return end
  if not IsEnabled() then return end
  if not UnitIsPlayer(unit) then return end
  local _, classToken = UnitClass(unit)
  if not classToken then return end
  local path = GetClassTexturePath(classToken)
  if path then
    -- CRITICAL FIX: Apply class-specific texture coordinates for proper alignment
    -- Warrior needs to shift UP and RIGHT to fill gaps at top/right edges
    -- SetTexCoord format: (left, right, top, bottom)
    if classToken == "WARRIOR" then
      tex:SetTexCoord(-0.02, 0.96, 0.04, 1.02) -- Keep RIGHT fix (-0.02), minimal UP shift (0.04 top)
    else
      tex:SetTexCoord(0, 1, 0, 1) -- Standard full texture for other classes
    end
    tex:SetTexture(path)
    if tex.SetBlendMode then tex:SetBlendMode("BLEND") end
    if tex.SetVertexColor then tex:SetVertexColor(1, 1, 1, 1) end
    if tex.SetDesaturated then tex:SetDesaturated(false) end
    if tex.SetAlpha then tex:SetAlpha(1) end
  end
end

-- EasyFrames pattern: Direct application, no throttling

-- EasyFrames proven pattern: Hook UnitFramePortrait_Update
local function InstallHooks()
  if M._hooked then return end
  M._hooked = true
  
  -- EXACT EasyFrames pattern from Target.lua line 90
  -- This hook fires automatically whenever Blizzard updates ANY portrait
  -- NO TAINT - hooksecurefunc is secure
  hooksecurefunc("UnitFramePortrait_Update", function(frame)
    -- EasyFrames calls their MakeClassPortraits function here
    M:MakeClassPortraits(frame)
  end)
end

-- EasyFrames MakeClassPortraits pattern (Target.lua lines 210-220)
function M:MakeClassPortraits(frame)
  if not IsEnabled() then return end
  if InCombatLockdown() then return end
  if not frame then return end
  if not frame.portrait then return end
  if not frame.unit then return end
  
  -- EasyFrames checks unit type first
  if not UnitIsPlayer(frame.unit) then
    -- Reset to default portrait for NPCs
    ResetPortrait(frame.portrait, frame.unit)
    return
  end
  
  -- Apply class icon for players
  local _, classToken = UnitClass(frame.unit)
  if classToken then
    local path = GetClassTexturePath(classToken)
    if path then
      -- Apply class-specific texture coordinates
      if classToken == "WARRIOR" then
        frame.portrait:SetTexCoord(-0.02, 0.96, 0.04, 1.02)
      else
        frame.portrait:SetTexCoord(0, 1, 0, 1)
      end
      frame.portrait:SetTexture(path)
      if frame.portrait.SetBlendMode then frame.portrait:SetBlendMode("BLEND") end
      if frame.portrait.SetVertexColor then frame.portrait:SetVertexColor(1, 1, 1, 1) end
      if frame.portrait.SetDesaturated then frame.portrait:SetDesaturated(false) end
      if frame.portrait.SetAlpha then frame.portrait:SetAlpha(1) end
    end
  end
end

-- EasyFrames pattern: Refresh by triggering Blizzard's portrait update
function M:RefreshAll()
  if InCombatLockdown() then return end
  
  -- EasyFrames approach: Force Blizzard to update portraits, our hook will apply class icons
  local frames = {
    {frame = _G.PlayerFrame, unit = "player"},
    {frame = _G.TargetFrame, unit = "target"},
    {frame = _G.FocusFrame, unit = "focus"},
  }
  
  -- Add party frames
  for i = 1, 4 do
    table.insert(frames, {frame = _G["PartyMemberFrame"..i], unit = "party"..i})
  end
  
  -- Add boss frames
  for i = 1, 5 do
    table.insert(frames, {frame = _G["Boss"..i.."TargetFrame"], unit = "boss"..i})
  end
  
  -- Add arena frames
  for i = 1, 5 do
    table.insert(frames, {frame = _G["ArenaEnemyFrame"..i], unit = "arena"..i})
  end
  
  -- Trigger updates
  for _, data in ipairs(frames) do
    if data.frame and data.frame.portrait and UnitExists(data.unit) then
      -- Force Blizzard to update the portrait, our hook will apply class icon
      if SetPortraitTexture then
        pcall(SetPortraitTexture, data.frame.portrait, data.unit)
      end
      -- Also call our function directly as backup
      C_Timer.After(0, function()
        if not InCombatLockdown() then
          M:MakeClassPortraits(data.frame)
        end
      end)
    end
  end
end

-- EasyFrames initialization pattern
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_TARGET_CHANGED")  -- EasyFrames equivalent: catches target changes
f:RegisterEvent("PLAYER_FOCUS_CHANGED")   -- Catches focus changes
f:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Refresh after combat

f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "ArenaCore" then
    InstallHooks()
    
  elseif event == "PLAYER_LOGIN" then
    InstallHooks()
    C_Timer.After(0.5, function()
      if not InCombatLockdown() then
        M:RefreshAll()
      end
    end)
    
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Refresh when entering new zones
    C_Timer.After(1.0, function()
      if not InCombatLockdown() then
        M:RefreshAll()
      end
    end)
    
  elseif event == "PLAYER_TARGET_CHANGED" then
    -- EasyFrames pattern: Update target portrait immediately on target change
    if not InCombatLockdown() and _G.TargetFrame then
      C_Timer.After(0, function()
        if not InCombatLockdown() then
          M:MakeClassPortraits(_G.TargetFrame)
        end
      end)
    end
    
  elseif event == "PLAYER_FOCUS_CHANGED" then
    -- Update focus portrait immediately on focus change
    if not InCombatLockdown() and _G.FocusFrame then
      C_Timer.After(0, function()
        if not InCombatLockdown() then
          M:MakeClassPortraits(_G.FocusFrame)
        end
      end)
    end
    
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Refresh after combat ends
    C_Timer.After(0.1, function()
      if not InCombatLockdown() then
        M:RefreshAll()
      end
    end)
  end
end)
