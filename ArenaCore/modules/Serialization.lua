---@class ArenaCoreSerializationModule
--- Custom serialization system for ArenaCore profile sharing
--- Self-contained, no external dependencies
--- Handles table serialization, compression, and Base64-style encoding

local AC = _G.ArenaCore
if not AC then return end

AC.Serialization = AC.Serialization or {}
local Serialization = AC.Serialization

-- ============================================================================
-- BASE64 ENCODING/DECODING
-- ============================================================================

local base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local base64Lookup = {}

-- Build lookup table for decoding
for i = 1, #base64Chars do
    base64Lookup[base64Chars:sub(i, i)] = i - 1
end

--- Encode string to Base64
---@param data string
---@return string
function Serialization:EncodeBase64(data)
    local result = {}
    local padding = ""
    
    -- Process 3 bytes at a time
    for i = 1, #data, 3 do
        local b1, b2, b3 = data:byte(i, i + 2)
        
        -- First 6 bits of b1
        result[#result + 1] = base64Chars:sub(bit.rshift(b1, 2) + 1, bit.rshift(b1, 2) + 1)
        
        if b2 then
            -- Last 2 bits of b1 + first 4 bits of b2
            result[#result + 1] = base64Chars:sub(bit.lshift(bit.band(b1, 0x03), 4) + bit.rshift(b2, 4) + 1, 
                                                    bit.lshift(bit.band(b1, 0x03), 4) + bit.rshift(b2, 4) + 1)
            
            if b3 then
                -- Last 4 bits of b2 + first 2 bits of b3
                result[#result + 1] = base64Chars:sub(bit.lshift(bit.band(b2, 0x0F), 2) + bit.rshift(b3, 6) + 1,
                                                        bit.lshift(bit.band(b2, 0x0F), 2) + bit.rshift(b3, 6) + 1)
                -- Last 6 bits of b3
                result[#result + 1] = base64Chars:sub(bit.band(b3, 0x3F) + 1, bit.band(b3, 0x3F) + 1)
            else
                -- Last 4 bits of b2, padded
                result[#result + 1] = base64Chars:sub(bit.lshift(bit.band(b2, 0x0F), 2) + 1, 
                                                        bit.lshift(bit.band(b2, 0x0F), 2) + 1)
                padding = "="
            end
        else
            -- Last 2 bits of b1, padded
            result[#result + 1] = base64Chars:sub(bit.lshift(bit.band(b1, 0x03), 4) + 1,
                                                    bit.lshift(bit.band(b1, 0x03), 4) + 1)
            padding = "=="
        end
    end
    
    return table.concat(result) .. padding
end

--- Decode Base64 string
---@param data string
---@return string|nil, string|nil error
function Serialization:DecodeBase64(data)
    -- Remove padding
    data = data:gsub("=+$", "")
    
    local result = {}
    
    -- Process 4 characters at a time
    for i = 1, #data, 4 do
        local c1 = base64Lookup[data:sub(i, i)]
        local c2 = base64Lookup[data:sub(i + 1, i + 1)]
        local c3 = base64Lookup[data:sub(i + 2, i + 2)]
        local c4 = base64Lookup[data:sub(i + 3, i + 3)]
        
        if not c1 or not c2 then
            return nil, "Invalid Base64 character"
        end
        
        -- First byte: 6 bits from c1 + 2 bits from c2
        result[#result + 1] = string.char(bit.lshift(c1, 2) + bit.rshift(c2, 4))
        
        if c3 then
            -- Second byte: 4 bits from c2 + 4 bits from c3
            result[#result + 1] = string.char(bit.lshift(bit.band(c2, 0x0F), 4) + bit.rshift(c3, 2))
            
            if c4 then
                -- Third byte: 2 bits from c3 + 6 bits from c4
                result[#result + 1] = string.char(bit.lshift(bit.band(c3, 0x03), 6) + c4)
            end
        end
    end
    
    return table.concat(result)
end

-- ============================================================================
-- TABLE SERIALIZATION
-- ============================================================================

--- Serialize a value to string
---@param value any
---@param depth number
---@return string
local function SerializeValue(value, depth)
    depth = depth or 0
    
    if depth > 50 then
        return "nil" -- Prevent infinite recursion
    end
    
    local valueType = type(value)
    
    if valueType == "nil" then
        return "nil"
    elseif valueType == "boolean" then
        return value and "true" or "false"
    elseif valueType == "number" then
        return tostring(value)
    elseif valueType == "string" then
        -- Escape special characters safely using %q
        -- %q already handles newlines, quotes, and special chars properly
        return string.format("%q", value)
    elseif valueType == "table" then
        local parts = {"{"}
        
        -- Serialize array part
        for i, v in ipairs(value) do
            parts[#parts + 1] = SerializeValue(v, depth + 1)
            parts[#parts + 1] = ","
        end
        
        -- Serialize hash part
        for k, v in pairs(value) do
            if type(k) ~= "number" or k > #value or k < 1 then
                parts[#parts + 1] = "["
                parts[#parts + 1] = SerializeValue(k, depth + 1)
                parts[#parts + 1] = "]="
                parts[#parts + 1] = SerializeValue(v, depth + 1)
                parts[#parts + 1] = ","
            end
        end
        
        parts[#parts + 1] = "}"
        return table.concat(parts)
    else
        -- Unsupported type (function, userdata, thread)
        return "nil"
    end
end

--- Serialize table to string
---@param tbl table
---@return string
function Serialization:SerializeTable(tbl)
    if type(tbl) ~= "table" then
        return "nil"
    end
    
    return SerializeValue(tbl, 0)
end

--- Deserialize string to table
---@param str string
---@return table|nil, string|nil error
function Serialization:DeserializeTable(str)
    if not str or str == "" then
        return nil, "Empty string"
    end
    
    -- Create safe environment for loading
    local func, err = loadstring("return " .. str)
    if not func then
        return nil, "Failed to parse: " .. tostring(err)
    end
    
    -- Set empty environment to prevent access to globals
    setfenv(func, {})
    
    local success, result = pcall(func)
    if not success then
        return nil, "Failed to execute: " .. tostring(result)
    end
    
    if type(result) ~= "table" then
        return nil, "Result is not a table"
    end
    
    return result
end

-- ============================================================================
-- SIMPLE COMPRESSION (RLE for repeated patterns)
-- ============================================================================

--- Compress string using simple run-length encoding
---@param data string
---@return string
function Serialization:Compress(data)
    -- Simple RLE: Replace repeated characters with count
    -- Format: ~<count><char> for runs of 4+ identical characters
    local result = {}
    local i = 1
    
    while i <= #data do
        local char = data:sub(i, i)
        local count = 1
        
        -- Count consecutive identical characters
        while i + count <= #data and data:sub(i + count, i + count) == char do
            count = count + 1
        end
        
        if count >= 4 then
            -- Use RLE for runs of 4+
            result[#result + 1] = "~" .. count .. char
            i = i + count
        else
            -- Keep as-is for short runs
            for j = 1, count do
                result[#result + 1] = char
            end
            i = i + count
        end
    end
    
    return table.concat(result)
end

--- Decompress RLE string
---@param data string
---@return string|nil, string|nil error
function Serialization:Decompress(data)
    local result = {}
    local i = 1
    
    while i <= #data do
        if data:sub(i, i) == "~" then
            -- RLE sequence
            local numStart = i + 1
            local numEnd = numStart
            
            -- Find end of number
            while numEnd <= #data and data:sub(numEnd, numEnd):match("%d") do
                numEnd = numEnd + 1
            end
            
            if numEnd > #data then
                return nil, "Invalid RLE sequence"
            end
            
            local count = tonumber(data:sub(numStart, numEnd - 1))
            local char = data:sub(numEnd, numEnd)
            
            if not count then
                return nil, "Invalid RLE count"
            end
            
            -- Expand run
            for j = 1, count do
                result[#result + 1] = char
            end
            
            i = numEnd + 1
        else
            -- Regular character
            result[#result + 1] = data:sub(i, i)
            i = i + 1
        end
    end
    
    return table.concat(result)
end

-- ============================================================================
-- HIGH-LEVEL EXPORT/IMPORT FUNCTIONS
-- ============================================================================

--- Export profile table to shareable string (V1 - Legacy)
---@param profileData table
---@return string|nil, string|nil error
function Serialization:ExportProfile(profileData)
    -- Step 1: Serialize table to string
    local serialized = self:SerializeTable(profileData)
    if not serialized then
        return nil, "Failed to serialize profile"
    end
    
    -- Step 2: Compress
    local compressed = self:Compress(serialized)
    
    -- Step 3: Base64 encode
    local encoded = self:EncodeBase64(compressed)
    
    -- Step 4: Add prefix/suffix
    return "!AC" .. encoded .. "!AC"
end

--- Export profile table using new compression system (V2)
---@param profileData table
---@return string|nil, string|nil error
function Serialization:ExportProfileV2(profileData)
    -- Use WoW's built-in serialization (available in all WoW versions)
    -- This is the same approach as LibSerialize but using native WoW functions
    
    -- Step 1: Use WoW's native serialization (CBOR format - binary, not Lua code)
    local serialized = C_EncodingUtil.SerializeCBOR(profileData)
    if not serialized then
        return nil, "Failed to serialize profile data"
    end
    
    -- Step 2: Compress using WoW's native compression
    local compressed = C_EncodingUtil.CompressString(serialized)
    if not compressed then
        return nil, "Failed to compress profile data"
    end
    
    -- Step 3: Encode to Base64 for safe text transmission
    local encoded = C_EncodingUtil.EncodeBase64(compressed)
    if not encoded then
        return nil, "Failed to encode profile data"
    end
    
    -- Step 4: Add prefix/suffix with version marker
    return "!AC2" .. encoded .. "!AC2"
end

--- LEGACY: Export using custom compression (kept for backwards compatibility)
---@param profileData table
---@return string|nil, string|nil error
function Serialization:ExportProfileV2Legacy(profileData)
    local Dictionary = AC.Compression and AC.Compression.Dictionary
    local LZ77 = AC.Compression and AC.Compression.LZ77
    local BitPacker = AC.Compression and AC.Compression.BitPacker
    local Base85 = AC.Compression and AC.Compression.Base85
    local DeltaCompression = AC.Compression and AC.Compression.DeltaCompression
    
    if not (Dictionary and LZ77 and BitPacker and Base85 and DeltaCompression) then
        return nil, "Compression modules not loaded"
    end
    
    -- Step 1: Create delta (only changed values)
    local defaults = DeltaCompression:GetDefaults()
    if not defaults then
        return nil, "Failed to get defaults"
    end
    
    local delta = DeltaCompression:CreateDelta(profileData, defaults)
    if not delta then
        return nil, "Failed to create delta"
    end
    
    -- Step 2: Serialize table to string
    local serialized = self:SerializeTable(delta)
    if not serialized then
        return nil, "Failed to serialize profile"
    end
    
    -- CRITICAL: Validate serialized Lua before compressing
    local testFunc, testErr = loadstring("return " .. serialized)
    if not testFunc then
        return nil, "Serialization created invalid Lua: " .. tostring(testErr)
    end
    
    -- Step 3: Dictionary compression
    local dictCompressed = Dictionary:Compress(serialized)
    
    -- Step 4: LZ77 compression (DISABLED - too slow, causes game freeze)
    -- LZ77 has O(n²) complexity which freezes WoW on large profiles
    -- Dictionary + BitPacker + Base85 still gives ~60% reduction
    local lz77Compressed = dictCompressed  -- Skip LZ77, pass through
    
    -- Step 5: Bit packing
    local bitPacked = BitPacker:Compress(lz77Compressed)
    
    -- Step 6: Base85 encode
    local encoded = Base85:Encode(bitPacked)
    
    -- Step 7: Add prefix/suffix with version marker
    return "!AC2" .. encoded .. "!AC2"
end

--- Import profile from shareable string (V1 - Legacy)
---@param shareCode string
---@return table|nil, string|nil error
function Serialization:ImportProfile(shareCode)
    -- Step 1: Validate format
    if not shareCode or shareCode:sub(1, 3) ~= "!AC" or shareCode:sub(-3) ~= "!AC" then
        return nil, "Invalid profile code format"
    end
    
    -- Step 2: Remove prefix/suffix
    local encoded = shareCode:sub(4, -4)
    
    -- Step 3: Base64 decode
    local compressed, err = self:DecodeBase64(encoded)
    if not compressed then
        return nil, "Failed to decode: " .. tostring(err)
    end
    
    -- Step 4: Decompress
    local serialized, err2 = self:Decompress(compressed)
    if not serialized then
        return nil, "Failed to decompress: " .. tostring(err2)
    end
    
    -- Step 5: Deserialize to table
    local profileData, err3 = self:DeserializeTable(serialized)
    if not profileData then
        return nil, "Failed to deserialize: " .. tostring(err3)
    end
    
    return profileData
end

--- Import profile using new compression system (V2)
---@param shareCode string
---@return table|nil, string|nil error
function Serialization:ImportProfileV2(shareCode)
    -- Use WoW's built-in deserialization (matching ExportProfileV2)
    
    -- Step 1: Validate format
    if not shareCode or shareCode:sub(1, 4) ~= "!AC2" or shareCode:sub(-4) ~= "!AC2" then
        return nil, "Invalid profile code format (V2)"
    end
    
    -- Step 2: Remove prefix/suffix
    local encoded = shareCode:sub(5, -5)
    
    -- Step 3: Decode from Base64
    local compressed = C_EncodingUtil.DecodeBase64(encoded)
    if not compressed then
        return nil, "Failed to decode Base64"
    end
    
    -- Step 4: Decompress using WoW's native decompression
    local serialized = C_EncodingUtil.DecompressString(compressed)
    if not serialized then
        return nil, "Failed to decompress data"
    end
    
    -- Step 5: Deserialize from CBOR format
    local profileData = C_EncodingUtil.DeserializeCBOR(serialized)
    if not profileData then
        return nil, "Failed to deserialize CBOR data"
    end
    
    return profileData
end

--- LEGACY: Import using custom compression (kept for backwards compatibility)
---@param shareCode string
---@return table|nil, string|nil error
function Serialization:ImportProfileV2Legacy(shareCode)
    local Dictionary = AC.Compression.Dictionary
    local LZ77 = AC.Compression.LZ77
    local BitPacker = AC.Compression.BitPacker
    local Base85 = AC.Compression.Base85
    local DeltaCompression = AC.Compression.DeltaCompression
    
    if not (Dictionary and LZ77 and BitPacker and Base85 and DeltaCompression) then
        return nil, "Compression modules not loaded"
    end
    
    -- Step 1: Validate format
    if not shareCode or shareCode:sub(1, 4) ~= "!AC2" or shareCode:sub(-4) ~= "!AC2" then
        return nil, "Invalid profile code format (V2)"
    end
    
    -- Step 2: Remove prefix/suffix
    local encoded = shareCode:sub(5, -5)
    
    -- Step 3: Base85 decode
    local bitPacked, err = Base85:Decode(encoded)
    if not bitPacked then
        return nil, "Failed to decode: " .. tostring(err)
    end
    
    -- Step 4: Bit unpacking
    local lz77Compressed, err2 = BitPacker:Decompress(bitPacked)
    if not lz77Compressed then
        return nil, "Failed to unpack: " .. tostring(err2)
    end
    
    -- Step 5: LZ77 decompression (DISABLED - matching export)
    local dictCompressed = lz77Compressed  -- Skip LZ77, pass through
    
    -- Step 6: Dictionary decompression
    local serialized, err4 = Dictionary:Decompress(dictCompressed)
    if not serialized then
        return nil, "Failed to decompress dictionary: " .. tostring(err4)
    end
    
    -- Step 7: Deserialize to table (this is the delta)
    local delta, err5 = self:DeserializeTable(serialized)
    if not delta then
        return nil, "Failed to deserialize: " .. tostring(err5)
    end
    
    -- Step 8: Restore full profile from delta
    local defaults = DeltaCompression:GetDefaults()
    local profileData = DeltaCompression:RestoreFromDelta(delta, defaults)
    
    return profileData
end

--- Smart import that detects version and uses appropriate method
---@param shareCode string
---@return table|nil, string|nil error
function Serialization:ImportProfileAuto(shareCode)
    if not shareCode then
        return nil, "No share code provided"
    end
    
    -- Detect version
    if shareCode:sub(1, 4) == "!AC2" then
        -- V2 format (new compression)
        return self:ImportProfileV2(shareCode)
    elseif shareCode:sub(1, 3) == "!AC" then
        -- V1 format (legacy)
        return self:ImportProfile(shareCode)
    else
        return nil, "Unknown profile code format"
    end
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

--- Deep copy a table
---@param orig table
---@param copies table|nil
---@return table
function Serialization:DeepCopy(orig, copies)
    copies = copies or {}
    local copy
    
    if type(orig) == "table" then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for k, v in next, orig, nil do
                copy[self:DeepCopy(k, copies)] = self:DeepCopy(v, copies)
            end
            setmetatable(copy, self:DeepCopy(getmetatable(orig), copies))
        end
    else
        copy = orig
    end
    
    return copy
end

--- Validate profile data structure
---@param profileData table
---@return boolean, string|nil error
function Serialization:ValidateProfile(profileData)
    if type(profileData) ~= "table" then
        return false, "Profile data is not a table"
    end
    
    -- Check for essential sections (basic validation)
    local requiredSections = {"arenaFrames", "moreFeatures"}
    for _, section in ipairs(requiredSections) do
        if not profileData[section] then
            return false, "Missing required section: " .. section
        end
    end
    
    return true
end
