-- Core/Events.lua
-- Centralized event frame + helpers (no UI logic here)

if type(_G.ArenaCore) ~= "table" then _G.ArenaCore = {} end
local addon = _G.ArenaCore

-- Single event frame for the addon
addon.EventFrame = addon.EventFrame or CreateFrame("Frame")

-- Simple registry
addon.__handlers = addon.__handlers or {}
addon.RefreshRegistry = addon.RefreshRegistry or {}
-- Public API: register a handler
function addon:RegisterEvent(ev, fn)
  if type(ev) ~= "string" or type(fn) ~= "function" then return end
  if not addon.__handlers[ev] then
    addon.__handlers[ev] = {}
    addon.EventFrame:RegisterEvent(ev)
  end
  table.insert(addon.__handlers[ev], fn)
end

-- Public API: unregister all (rarely used; keep simple)
function addon:UnregisterAllEvents()
  for ev in pairs(addon.__handlers) do
    addon.EventFrame:UnregisterEvent(ev)
  end
  wipe(addon.__handlers)
end

-- Safe dispatcher
addon.EventFrame:SetScript("OnEvent", function(_, event, ...)
  local list = addon.__handlers[event]
  if not list then return end
  for i = 1, #list do
    local ok, err = pcall(list[i], event, ...)
    if not ok then
      -- Don’t hard-crash: show a readable error once per session per event+slot
      local emsg = ("|cffff5555Arena Core event error|r [%s]: %s"):format(event, tostring(err))
      geterrorhandler()(emsg)
    end
  end
end)

-- ---------------------------------------------------------------------------
-- Example baseline handlers (safe, no UI creation here)
-- ---------------------------------------------------------------------------

-- PLAYER_LOGIN: good place for late clamps or CVars if needed
addon:RegisterEvent("PLAYER_LOGIN", function()
  -- Scan for rating achievements on login (delayed to ensure API is ready)
  C_Timer.After(2.0, function()
    if addon.ScanRatingAchievements then
      addon:ScanRatingAchievements()
    end
  end)
end)

-- PLAYER_ENTERING_WORLD: map/instance checks, reset timers, etc.
addon:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isLogin, isReload)
  -- no-op default; keep lightweight to avoid taint during zoning
end)

-- ACHIEVEMENT_EARNED: Real-time achievement unlock detection
addon:RegisterEvent("ACHIEVEMENT_EARNED", function(_, achievementID, alreadyEarned)
  if addon.OnAchievementEarned then
    addon:OnAchievementEarned(achievementID, alreadyEarned)
  end
end)

-- ADDON_ACTION_FORBIDDEN / BLOCKED: surface issues without spamming
addon:RegisterEvent("ADDON_ACTION_FORBIDDEN", function(_, addonName, func)
  if addonName == addon.AddonName then
    local m = ("|cffff5555Arena Core taint:|r %s"):format(tostring(func))
    geterrorhandler()(m)
  end
end)
function addon:RefreshAllModules()
  if self.RefreshBarTextures then
    self:RefreshBarTextures()
  end
  for _, handler in ipairs(addon.RefreshRegistry) do
    local ok, err = pcall(handler)
    if not ok then
      local emsg = ("|cffff5555Arena Core refresh error|r: %s"):format(tostring(err))
      geterrorhandler()(emsg)
    end
  end
end