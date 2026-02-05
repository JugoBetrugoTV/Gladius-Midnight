-- ============================================================================
-- ArenaCore Compression System - Delta Compression Module
-- ============================================================================
-- Only stores values that differ from default profile settings
-- Achieves ~30-40% data reduction by eliminating unchanged values
-- ============================================================================

local AC = _G.ArenaCore
AC.Compression = AC.Compression or {}
local DeltaCompression = {}
AC.Compression.DeltaCompression = DeltaCompression

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

--- Deep compare two values
---@param v1 any
---@param v2 any
---@return boolean equal
local function DeepEquals(v1, v2)
    if type(v1) ~= type(v2) then
        return false
    end
    
    if type(v1) ~= "table" then
        return v1 == v2
    end
    
    -- Compare tables recursively
    for k, v in pairs(v1) do
        if not DeepEquals(v, v2[k]) then
            return false
        end
    end
    
    for k, v in pairs(v2) do
        if v1[k] == nil then
            return false
        end
    end
    
    return true
end

--- Get value from nested table using dot notation path
---@param tbl table
---@param path string
---@return any value
local function GetNestedValue(tbl, path)
    local keys = {}
    for key in path:gmatch("[^%.]+") do
        table.insert(keys, key)
    end
    
    local current = tbl
    for _, key in ipairs(keys) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[key]
    end
    
    return current
end

--- Set value in nested table using dot notation path
---@param tbl table
---@param path string
---@param value any
local function SetNestedValue(tbl, path, value)
    local keys = {}
    for key in path:gmatch("[^%.]+") do
        table.insert(keys, key)
    end
    
    local current = tbl
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    current[keys[#keys]] = value
end

--- Recursively build path-value pairs
---@param tbl table
---@param prefix string
---@param result table
local function BuildPathValuePairs(tbl, prefix, result)
    for k, v in pairs(tbl) do
        local path = prefix == "" and k or (prefix .. "." .. k)
        
        if type(v) == "table" then
            BuildPathValuePairs(v, path, result)
        else
            result[path] = v
        end
    end
end

-- ============================================================================
-- COMPRESSION FUNCTIONS
-- ============================================================================

--- Create delta by comparing profile with defaults
---@param profileData table
---@param defaultData table
---@return table delta Only changed values
function DeltaCompression:CreateDelta(profileData, defaultData)
    if not profileData or not defaultData then
        return profileData
    end
    
    local delta = {}
    
    -- Build flat path-value maps
    local profilePairs = {}
    local defaultPairs = {}
    
    BuildPathValuePairs(profileData, "", profilePairs)
    BuildPathValuePairs(defaultData, "", defaultPairs)
    
    -- Only include values that differ from defaults
    for path, value in pairs(profilePairs) do
        local defaultValue = defaultPairs[path]
        
        if not DeepEquals(value, defaultValue) then
            -- Value differs from default - include it
            SetNestedValue(delta, path, value)
        end
    end
    
    return delta
end

--- Restore full profile from delta and defaults
---@param delta table
---@param defaultData table
---@return table profile Full profile with defaults applied
function DeltaCompression:RestoreFromDelta(delta, defaultData)
    if not defaultData then
        return delta
    end
    
    -- Start with a deep copy of defaults
    local profile = AC.Serialization:DeepCopy(defaultData)
    
    if not delta then
        return profile
    end
    
    -- Build flat path-value map from delta
    local deltaPairs = {}
    BuildPathValuePairs(delta, "", deltaPairs)
    
    -- Apply delta values over defaults
    for path, value in pairs(deltaPairs) do
        SetNestedValue(profile, path, value)
    end
    
    return profile
end

--- Get default profile structure
---@return table defaults
function DeltaCompression:GetDefaults()
    -- Return a copy of the default profile from Init.lua
    if AC.DB and AC.DB.defaults and AC.DB.defaults.profile then
        return AC.Serialization:DeepCopy(AC.DB.defaults.profile)
    end
    
    -- Fallback: return minimal defaults
    return {
        arenaFrames = {
            positioning = {
                horizontal = 400,
                vertical = 120,
                spacing = 50,
                growthDirection = "DOWN",
            },
            sizing = {
                width = 180,
                height = 40,
                scale = 1.0,
            },
            general = {
                statusText = {
                    enabled = true,
                },
            },
        },
        moreFeatures = {
            trinkets = {
                enabled = true,
            },
            racials = {
                enabled = true,
            },
        },
    }
end

--- Get compression statistics
---@param original table
---@param delta table
---@return table stats
function DeltaCompression:GetStats(original, delta)
    local originalPairs = {}
    local deltaPairs = {}
    
    BuildPathValuePairs(original, "", originalPairs)
    BuildPathValuePairs(delta, "", deltaPairs)
    
    local originalCount = 0
    local deltaCount = 0
    
    for _ in pairs(originalPairs) do originalCount = originalCount + 1 end
    for _ in pairs(deltaPairs) do deltaCount = deltaCount + 1 end
    
    local reduction = originalCount - deltaCount
    local ratio = originalCount > 0 and (reduction / originalCount) * 100 or 0
    
    return {
        originalFields = originalCount,
        deltaFields = deltaCount,
        reduction = reduction,
        ratio = ratio,
    }
end

return DeltaCompression
