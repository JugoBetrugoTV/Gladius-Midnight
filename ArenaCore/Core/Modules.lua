-- =========================================================================
-- ArenaCore - Module registry, event bus, and helper utilities
-- Provides a lightweight contract for separating features into modules.
-- =========================================================================

local AC = _G.ArenaCore or {}
_G.ArenaCore = AC

-- Listener registry for custom events fired between modules.
AC._eventListeners = AC._eventListeners or {}

---Subscribe to a custom ArenaCore event.
---@param event string
---@param fn function
---@return function|nil  -- Returns an unsubscribe closure.
function AC:On(event, fn)
    if type(event) ~= "string" or event == "" then
        return nil
    end
    if type(fn) ~= "function" then
        return nil
    end

    local listeners = self._eventListeners
    listeners[event] = listeners[event] or {}
    table.insert(listeners[event], fn)

    return function()
        local list = listeners[event]
        if not list then
            return
        end
        for index, handler in ipairs(list) do
            if handler == fn then
                table.remove(list, index)
                break
            end
        end
    end
end

---Fire a custom ArenaCore event, invoking every subscribed handler safely.
---@param event string
function AC:Fire(event, ...)
    if type(event) ~= "string" or event == "" then
        return
    end

    local listeners = self._eventListeners[event]
    if not listeners then
        return
    end

    for _, handler in ipairs(listeners) do
        local ok, err = pcall(handler, ...)
        if not ok then
            -- Preserve developer visibility without hard crashing the addon.
            -- Use DEFAULT_CHAT_FRAME if available; otherwise print.
            if _G.DEFAULT_CHAT_FRAME then
                _G.DEFAULT_CHAT_FRAME:AddMessage("|cffff5555ArenaCore Module Error:|r " .. tostring(err))
            else
                print("ArenaCore Module Error:", err)
            end
        end
    end
end

-- -------------------------------------------------------------------------
-- Timer helpers (safe wrappers around C_Timer)
-- -------------------------------------------------------------------------

---Execute a function after a number of seconds (no error propagation).
function AC:After(seconds, fn)
    if type(seconds) ~= "number" or seconds < 0 then
        return
    end
    if type(fn) ~= "function" then
        return
    end

    _G.C_Timer.After(seconds, function()
        pcall(fn)
    end)
end

---Execute a function every N seconds until the cancel closure is called.
---@return function|nil cancel  -- Call to stop the ticker.
function AC:Every(seconds, fn)
    if type(seconds) ~= "number" or seconds <= 0 then
        return nil
    end
    if type(fn) ~= "function" then
        return nil
    end

    local alive = true
    local ticker

    local function tick()
        if not alive then
            return
        end
        pcall(fn)
        ticker = _G.C_Timer.After(seconds, tick)
    end

    ticker = _G.C_Timer.After(seconds, tick)

    return function()
        alive = false
        ticker = nil
    end
end

-- -------------------------------------------------------------------------
-- Module registration & iteration helpers
-- -------------------------------------------------------------------------

---Register a module so it participates in lifecycle events.
---@param name string
---@param mod table
---@return table module  -- Always returns the module table for chaining.
function AC:RegisterModule(name, mod)
    assert(type(name) == "string" and name ~= "", "RegisterModule: invalid name")
    assert(type(mod) == "table", "RegisterModule: module must be a table")

    if self.modules[name] then
        return self.modules[name]
    end

    self.modules[name] = mod
    table.insert(self.moduleOrder, name)

    -- Inject common helpers so modules do not need to touch globals.
    mod.name = name
    mod.enabled = false
    mod.Core = self
    mod.API = self.API

    ---Return the module's SavedVariables table (profile-scoped).
    function mod:DB()
        if type(self.Core.GetModuleDB) == "function" then
            return self.Core:GetModuleDB(name)
        end
        return nil
    end

    return mod
end

---Call a method on every registered module in registration order.
function AC:ForEachModule(method, ...)
    if type(method) ~= "string" or method == "" then
        return
    end

    for _, name in ipairs(self.moduleOrder) do
        local mod = self.modules[name]
        if mod then
            local fn = mod[method]
            if type(fn) == "function" then
                local ok, err = pcall(fn, mod, ...)
                if not ok then
                    if _G.DEFAULT_CHAT_FRAME then
                        _G.DEFAULT_CHAT_FRAME:AddMessage("|cffff5555ArenaCore Module Error:|r " .. tostring(err))
                    else
                        print("ArenaCore Module Error:", err)
                    end
                end
            end
        end
    end
end

-- -------------------------------------------------------------------------
-- Database helpers
-- -------------------------------------------------------------------------

---Return the active profile table, creating base structures on demand.
---@return table profile
function AC:GetActiveProfile()
    if type(self.DB) ~= "table" then
        return {}
    end

    -- CRITICAL FIX: ArenaCore doesn't use named profiles system
    -- profile should be a table, not a profile name string
    -- Just return the profile table directly
    if type(self.DB.profile) == "table" then
        return self.DB.profile
    end
    
    -- If profile doesn't exist, create it
    self.DB.profile = {}
    return self.DB.profile
end

---Return (and create if needed) the SavedVariables table for a module.
---@param name string
---@return table
function AC:GetModuleDB(name)
    local profile = self:GetActiveProfile()
    profile.modules = profile.modules or {}
    profile.modules[name] = profile.modules[name] or {}
    return profile.modules[name]
end
