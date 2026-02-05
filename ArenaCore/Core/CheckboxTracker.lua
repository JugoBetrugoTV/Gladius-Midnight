-- Core/CheckboxTracker.lua
-- Checkbox tracking system for Edit Mode
-- Tracks all checkboxes and their database paths to enable real-time visual updates when discarding changes

local AC = _G.ArenaCore
if not AC then return end

-- Create the CheckboxTracker module
local CheckboxTracker = {}
AC.CheckboxTracker = CheckboxTracker

-- Storage for tracked checkboxes
-- Format: { {checkbox = frame, path = "arenaFrames.general.showStatusText"}, ... }
local trackedCheckboxes = {}

--- Register a checkbox for tracking
--- @param checkbox table The checkbox frame (must have SetChecked method)
--- @param path string The database path (e.g. "arenaFrames.general.showStatusText")
function CheckboxTracker:Register(checkbox, path)
    if not checkbox or not path then return end
    
    -- Store the checkbox and its path
    table.insert(trackedCheckboxes, {
        checkbox = checkbox,
        path = path
    })
    
    -- DEBUG: Uncomment to see registrations
    -- print("|cff00FF00[CheckboxTracker]|r Registered checkbox for path: " .. path)
end

--- Update all tracked checkboxes to match current database values
--- Called after discarding changes to sync checkbox UI with reverted database
function CheckboxTracker:UpdateAll()
    local updateCount = 0
    
    for i, data in ipairs(trackedCheckboxes) do
        if data.checkbox and data.path then
            -- Get current value from database
            local value = AC.ProfileManager:GetSetting(data.path)
            
            if value ~= nil then
                -- Update checkbox visual state
                data.checkbox:SetChecked(value)
                updateCount = updateCount + 1
                
                -- DEBUG: Uncomment to see updates
                -- print("|cff00FF00[CheckboxTracker]|r Updated " .. data.path .. " to " .. tostring(value))
            end
        end
    end
    
    -- DEBUG: Uncomment to see summary
    -- print("|cff00FF00[CheckboxTracker]|r Updated " .. updateCount .. " checkboxes")
end

--- Clear all tracked checkboxes
--- Called when pages are rebuilt or UI is closed
function CheckboxTracker:Clear()
    trackedCheckboxes = {}
    -- DEBUG: Uncomment to see clears
    -- print("|cff00FF00[CheckboxTracker]|r Cleared all tracked checkboxes")
end

--- Get count of tracked checkboxes (for debugging)
function CheckboxTracker:GetCount()
    return #trackedCheckboxes
end

-- Module loaded (debug removed for clean user experience)
-- print("|cff8B45FFArenaCore:|r CheckboxTracker module loaded")
