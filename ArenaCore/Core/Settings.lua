-- Core/Settings.lua --
-- Delegation wrapper for modular settings management

local AC = _G.ArenaCore
if not AC then return end

-- ============================================================================
-- MODULE ACQUISITION
-- ============================================================================

local function acquireManager()
    -- Try cached module first
    if AC.modules and AC.modules.settings and AC.modules.settings.manager then
        return AC.modules.settings.manager
    end

    -- Try loading via LoadModule if available
    if AC.LoadModule then
        local manager = AC:LoadModule("modules/Settings/Manager.lua")
        if manager then
            AC.modules = AC.modules or {}
            AC.modules.settings = AC.modules.settings or {}
            AC.modules.settings.manager = manager
            return manager
        end
    end

    return nil
end

local function requireManager()
    local manager = acquireManager()
    -- REMOVED: Debug spam - this is expected behavior when modular manager isn't loaded
    -- The Settings system works fine without it
    return manager
end

-- ============================================================================
-- DELEGATION API
-- ============================================================================

AC.Settings = {}
local Settings = AC.Settings

--- Initialize settings manager
function Settings:Initialize()
    local manager = requireManager()
    if manager and manager.Initialize then
        manager:Initialize()
    end
end

--- Get a setting value
--- @param path string Dot-separated path (e.g., "arenaFrames.sizing.width")
--- @param defaultValue any Value to return if path doesn't exist
--- @return any The value at the path, or defaultValue if not found
function Settings:Get(path, defaultValue)
    local manager = acquireManager()
    if manager and manager.Get then
        return manager:Get(path, defaultValue)
    end
    return defaultValue
end

--- Set a setting value
--- @param path string Dot-separated path (e.g., "arenaFrames.sizing.width")
--- @param value any Value to set
function Settings:Set(path, value)
    local manager = acquireManager()
    if manager and manager.Set then
        manager:Set(path, value)
    end
end

--- Ensure a default value is set if path doesn't exist
--- @param path string Dot-separated path (e.g., "arenaFrames.sizing.width")
--- @param defaultValue any Default value to set if path is nil
function Settings:EnsureDefault(path, defaultValue)
    local manager = acquireManager()
    if manager and manager.EnsureDefault then
        manager:EnsureDefault(path, defaultValue)
    end
end
