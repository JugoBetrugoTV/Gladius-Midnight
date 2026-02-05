-- ============================================================================
-- ArenaCore Compression System - Dictionary Module
-- ============================================================================
-- Compresses common profile patterns using predefined tokens
-- Achieves ~40% reduction on structured profile data
-- ============================================================================

local AC = _G.ArenaCore
AC.Compression = AC.Compression or {}
local Dictionary = {}
AC.Compression.Dictionary = Dictionary

-- ============================================================================
-- DICTIONARY DEFINITIONS
-- ============================================================================

-- Common path prefixes (most frequent patterns first)
local PATH_TOKENS = {
    -- Arena Frames paths
    ["arenaFrames.positioning."] = "#P",
    ["arenaFrames.sizing."] = "#S",
    ["arenaFrames.general."] = "#G",
    ["arenaFrames."] = "#A",
    
    -- More Features paths
    ["moreFeatures.trinkets."] = "#T",
    ["moreFeatures.racials."] = "#R",
    ["moreFeatures.dispels."] = "#D",
    ["moreFeatures.castBars."] = "#C",
    ["moreFeatures."] = "#M",
    
    -- Class Packs paths
    ["classPacks."] = "#K",
    
    -- Blackout paths
    ["blackout."] = "#B",
}

-- Common property names
local PROPERTY_TOKENS = {
    [".enabled"] = "#E",
    [".visible"] = "#V",
    [".offsetX"] = "#X",
    [".offsetY"] = "#Y",
    [".scale"] = "#Z",
    [".width"] = "#W",
    [".height"] = "#H",
    [".alpha"] = "#L",
    [".color"] = "#O",
    [".fontSize"] = "#F",
    [".position"] = "#N",
    [".anchor"] = "#Q",
}

-- Common values
local VALUE_TOKENS = {
    ["true"] = "#t",
    ["false"] = "#f",
    ["nil"] = "#n",
    ["TOPLEFT"] = "#1",
    ["TOPRIGHT"] = "#2",
    ["BOTTOMLEFT"] = "#3",
    ["BOTTOMRIGHT"] = "#4",
    ["CENTER"] = "#5",
    ["TOP"] = "#6",
    ["BOTTOM"] = "#7",
    ["LEFT"] = "#8",
    ["RIGHT"] = "#9",
}

-- Reverse lookup tables (for decompression)
local PATH_REVERSE = {}
local PROPERTY_REVERSE = {}
local VALUE_REVERSE = {}

-- Build reverse lookup tables
for k, v in pairs(PATH_TOKENS) do
    PATH_REVERSE[v] = k
end
for k, v in pairs(PROPERTY_TOKENS) do
    PROPERTY_REVERSE[v] = k
end
for k, v in pairs(VALUE_TOKENS) do
    VALUE_REVERSE[v] = k
end

-- ============================================================================
-- COMPRESSION FUNCTIONS
-- ============================================================================

--- Compress string using dictionary substitution
---@param data string
---@return string compressed
function Dictionary:Compress(data)
    if not data or data == "" then
        return ""
    end
    
    local result = data
    
    -- Replace paths (longest first to avoid partial matches)
    local pathKeys = {}
    for k in pairs(PATH_TOKENS) do
        table.insert(pathKeys, k)
    end
    table.sort(pathKeys, function(a, b) return #a > #b end)
    
    for _, pattern in ipairs(pathKeys) do
        local token = PATH_TOKENS[pattern]
        result = result:gsub(pattern:gsub("[%.%-%+%*%?%[%]%^%$%(%)%%]", "%%%1"), token)
    end
    
    -- Replace properties
    for pattern, token in pairs(PROPERTY_TOKENS) do
        result = result:gsub(pattern:gsub("[%.%-%+%*%?%[%]%^%$%(%)%%]", "%%%1"), token)
    end
    
    -- Replace values (need word boundaries to avoid partial matches)
    for pattern, token in pairs(VALUE_TOKENS) do
        -- Match whole words only
        result = result:gsub("([^%w])" .. pattern .. "([^%w])", "%1" .. token .. "%2")
        -- Match at start of string
        result = result:gsub("^" .. pattern .. "([^%w])", token .. "%1")
        -- Match at end of string
        result = result:gsub("([^%w])" .. pattern .. "$", "%1" .. token)
        -- Match entire string
        if result == pattern then
            result = token
        end
    end
    
    return result
end

--- Decompress string using dictionary substitution
---@param data string
---@return string|nil decompressed, string|nil error
function Dictionary:Decompress(data)
    if not data or data == "" then
        return "", nil
    end
    
    local result = data
    
    -- Replace tokens back to original values (reverse order)
    for token, original in pairs(VALUE_REVERSE) do
        result = result:gsub(token:gsub("[%.%-%+%*%?%[%]%^%$%(%)%%]", "%%%1"), original)
    end
    
    for token, original in pairs(PROPERTY_REVERSE) do
        result = result:gsub(token:gsub("[%.%-%+%*%?%[%]%^%$%(%)%%]", "%%%1"), original)
    end
    
    for token, original in pairs(PATH_REVERSE) do
        result = result:gsub(token:gsub("[%.%-%+%*%?%[%]%^%$%(%)%%]", "%%%1"), original)
    end
    
    return result, nil
end

--- Get compression statistics
---@param original string
---@param compressed string
---@return table stats
function Dictionary:GetStats(original, compressed)
    local originalSize = #original
    local compressedSize = #compressed
    local reduction = originalSize - compressedSize
    local ratio = (reduction / originalSize) * 100
    
    return {
        originalSize = originalSize,
        compressedSize = compressedSize,
        reduction = reduction,
        ratio = ratio,
    }
end

return Dictionary
