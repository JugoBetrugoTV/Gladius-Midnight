-- =========================================================================
-- ArenaCore - Core bootstrap and lifecycle coordination
-- This file sets up the global addon table, public API surface, and
-- lifecycle entry points that other systems can rely on.
-- =========================================================================

local addonName = ...
local AC = _G.ArenaCore or {}
_G.ArenaCore = AC

-- Tiny, stable public API surface that feature modules can extend safely.
AC.API = AC.API or {}

-- Internal state holders used by the module framework (populated later).
AC.modules = AC.modules or {}
AC.moduleOrder = AC.moduleOrder or {}

-- SavedVariables root reference (assigned during ADDON_LOADED).
AC.DB = AC.DB or nil

-- -------------------------------------------------------------------------
-- Lifecycle helpers
-- Each helper guards against double execution so legacy systems remain safe.
-- -------------------------------------------------------------------------

---Initialize all registered modules once the SavedVariables are ready.
function AC:_InitModules()
    if self._modulesInitialized then
        return
    end
    self._modulesInitialized = true

    if type(self.ForEachModule) == "function" then
        self:ForEachModule("OnInit")
    end
end

---Enable every module that is not explicitly disabled in the profile.
function AC:_EnableModules()
    if type(self.modules) ~= "table" then
        print("|cffFF0000[MODULE ERROR]|r AC.modules is not a table!")
        return
    end

    if type(self.moduleOrder) ~= "table" then
        print("|cffFF0000[MODULE ERROR]|r AC.moduleOrder is not a table!")
        return
    end

    -- DEBUG REMOVED FOR RELEASE: Module initialization messages
    for _, name in ipairs(self.moduleOrder) do
        local mod = self.modules[name]
        if mod and not mod.enabled then
            local shouldEnable = true
            if type(self.IsModuleDisabled) == "function" then
                shouldEnable = not self:IsModuleDisabled(name)
            end

            if shouldEnable then
                mod.enabled = true
                local onEnable = mod.OnEnable
                if type(onEnable) == "function" then
                    local success, err = pcall(onEnable, mod)
                    if success then
                        -- DEBUG REMOVED FOR RELEASE: Module enabled message
                    else
                        -- Keep error messages for troubleshooting
                        print(string.format("|cffFF0000[MODULE ERROR]|r ✗ %s failed: %s", name, tostring(err)))
                    end
                else
                    -- DEBUG REMOVED FOR RELEASE: No OnEnable message
                end
            else
                -- DEBUG REMOVED FOR RELEASE: Disabled in profile message
            end
        elseif mod and mod.enabled then
            -- DEBUG REMOVED FOR RELEASE: Already enabled message
        else
            -- Keep error messages for troubleshooting
            print(string.format("|cffFF0000[MODULE ERROR]|r ✗ %s not found!", name))
        end
    end
    -- DEBUG REMOVED FOR RELEASE: Module initialization complete
end

---Disable every currently enabled module (used during reloads or shutdown).
function AC:_DisableModules()
    if type(self.modules) ~= "table" then
        return
    end

    for _, mod in pairs(self.modules) do
        if mod.enabled then
            mod.enabled = false
            local onDisable = mod.OnDisable
            if type(onDisable) == "function" then
                pcall(onDisable, mod)
            end
        end
    end
end

---Notify modules that profile data changed (e.g., new profile, reset, or import).
---@param kind string|nil  -- Optional hint describing the profile change source.
function AC:_ProfileChanged(kind)
    if type(self.ForEachModule) == "function" then
        self:ForEachModule("OnProfileChanged", kind)
    end
end

-- -------------------------------------------------------------------------
-- Bootstrap event handling
-- Register early so we can prepare SavedVariables before legacy code runs.
-- -------------------------------------------------------------------------

-- Delay event frame creation to avoid Midnight taint warnings
local eventFrame
C_Timer.After(0, function()
    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")

    eventFrame:SetScript("OnEvent", function(_, event, arg1)
        if event == "ADDON_LOADED" and arg1 == addonName then
            if not ArenaCoreDB then
                ArenaCoreDB = {}
            end

            AC.DB = ArenaCoreDB

            if type(AC.LoadDefaultsAndMigrate) == "function" then
                pcall(AC.LoadDefaultsAndMigrate, AC)
            end

            AC:_InitModules()

        elseif event == "PLAYER_LOGIN" then
            AC:_EnableModules()
        end
    end)
end)

-- Provide manual toggles for Console/Slash usage without disturbing legacy hooks.
---Enable a specific module immediately when requested by name.
---@param name string
function AC:EnableModule(name)
    if type(name) ~= "string" or name == "" then
        return
    end

    if type(self.IsModuleDisabled) == "function" and self:IsModuleDisabled(name) then
        local profile = self:GetModuleDB(name)
        profile.disabled = false
    end

    local mod = self.modules[name]
    if mod and not mod.enabled then
        mod.enabled = true
        if type(mod.OnEnable) == "function" then
            pcall(mod.OnEnable, mod)
        end
    end
end

---Disable a specific module immediately and mark it as disabled in the profile.
---@param name string
function AC:DisableModule(name)
    if type(name) ~= "string" or name == "" then
        return
    end

    local profile = nil
    if type(self.GetModuleDB) == "function" then
        profile = self:GetModuleDB(name)
    end

    if type(profile) == "table" then
        profile.disabled = true
    elseif type(self.DB) == "table" then
        self.DB.modules = self.DB.modules or {}
        self.DB.modules[name] = self.DB.modules[name] or {}
        self.DB.modules[name].disabled = true
    end

    local mod = self.modules[name]
    if mod and mod.enabled then
        mod.enabled = false
        if type(mod.OnDisable) == "function" then
            pcall(mod.OnDisable, mod)
        end
    end
end

---Return whether a module is disabled in the current profile.
---@param name string
---@return boolean
function AC:IsModuleDisabled(name)
    if type(name) ~= "string" or name == "" then
        return false
    end

    local profile = nil
    if type(self.GetModuleDB) == "function" then
        profile = self:GetModuleDB(name)
    elseif type(self.DB) == "table" then
        local active = self.DB.profiles and self.DB.profile and self.DB.profiles[self.DB.profile]
        if active then
            profile = active.modules and active.modules[name]
        end
    end

    if type(profile) == "table" and profile.disabled == true then
        return true
    end

    return false
end

-- Manual profile change helper for legacy systems to call once migration begins.
---External entry point to notify modules about profile changes.
---@param kind string|nil
function AC:NotifyProfileChanged(kind)
    self:_ProfileChanged(kind)
end
