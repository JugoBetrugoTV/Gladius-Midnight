-- =========================================================================
-- ArenaCore LegacyBridge
-- Bridges the existing monolithic systems into the new module lifecycle so
-- we can migrate functionality gradually without breaking anything.
-- =========================================================================

local AC = _G.ArenaCore or {}
local LegacyBridge = AC:RegisterModule("LegacyBridge", {})

-- Default SavedVariables for the bridge are empty; we only mark disabled flag
-- if the user explicitly toggles this module off.
local DEFAULTS = {
    disabled = false,
}

---Ensure SavedVariables exist for the bridge before other legacy code runs.
function LegacyBridge:OnInit()
    local db = self:DB()
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then
            db[key] = value
        end
    end

    -- Signal to legacy systems that the core lifecycle is ready. Existing
    -- code can optionally hook this custom event if needed.
    AC:Fire("LegacyBridge_OnInit")
end

---Re-run any late setup tasks required by the current monolith.
function LegacyBridge:OnEnable()
    AC:Fire("LegacyBridge_OnEnable")
end

---Notify legacy systems that modules are being disabled (e.g., during /reload).
function LegacyBridge:OnDisable()
    AC:Fire("LegacyBridge_OnDisable")
end

return LegacyBridge
