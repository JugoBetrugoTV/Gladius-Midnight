-- ============================================================================
-- ArenaCore Compression System - Base85 Encoding Module
-- ============================================================================
-- More efficient encoding than Base64 (4 bytes → 5 chars vs 3 → 4)
-- Results in ~20% smaller encoded output
-- Uses ASCII85 variant safe for WoW text transmission
-- ============================================================================

local AC = _G.ArenaCore
AC.Compression = AC.Compression or {}
local Base85 = {}
AC.Compression.Base85 = Base85

-- ============================================================================
-- BASE85 ALPHABET
-- ============================================================================

-- ASCII85 alphabet (printable ASCII characters, avoiding problematic ones)
-- Excludes: quotes, backslash, control characters
local ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+-;<=>?@^_`{|}~"

-- Build lookup tables
local ENCODE_TABLE = {}
local DECODE_TABLE = {}

for i = 1, #ALPHABET do
    local char = ALPHABET:sub(i, i)
    ENCODE_TABLE[i - 1] = char
    DECODE_TABLE[char] = i - 1
end

-- ============================================================================
-- ENCODING FUNCTIONS
-- ============================================================================

--- Encode 4 bytes into 5 base85 characters
---@param b1 number Byte 1 (0-255)
---@param b2 number Byte 2 (0-255)
---@param b3 number Byte 3 (0-255)
---@param b4 number Byte 4 (0-255)
---@return string encoded 5 characters
local function EncodeGroup(b1, b2, b3, b4)
    -- Combine 4 bytes into 32-bit number
    local value = b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
    
    -- Convert to base85 (5 digits)
    local c1 = math.floor(value / 52200625) % 85
    local c2 = math.floor(value / 614125) % 85
    local c3 = math.floor(value / 7225) % 85
    local c4 = math.floor(value / 85) % 85
    local c5 = value % 85
    
    return ENCODE_TABLE[c1] .. ENCODE_TABLE[c2] .. ENCODE_TABLE[c3] .. ENCODE_TABLE[c4] .. ENCODE_TABLE[c5]
end

--- Encode string to Base85
---@param data string
---@return string encoded
function Base85:Encode(data)
    if not data or data == "" then
        return ""
    end
    
    local result = {}
    local len = #data
    local pos = 1
    
    -- Process 4-byte groups
    while pos + 3 <= len do
        local b1 = data:byte(pos)
        local b2 = data:byte(pos + 1)
        local b3 = data:byte(pos + 2)
        local b4 = data:byte(pos + 3)
        
        table.insert(result, EncodeGroup(b1, b2, b3, b4))
        pos = pos + 4
    end
    
    -- Handle remaining bytes (1-3 bytes)
    if pos <= len then
        local remaining = len - pos + 1
        local b1 = data:byte(pos) or 0
        local b2 = data:byte(pos + 1) or 0
        local b3 = data:byte(pos + 2) or 0
        local b4 = 0
        
        local encoded = EncodeGroup(b1, b2, b3, b4)
        
        -- Only include necessary characters based on remaining bytes
        -- 1 byte → 2 chars, 2 bytes → 3 chars, 3 bytes → 4 chars
        local charsNeeded = remaining + 1
        table.insert(result, encoded:sub(1, charsNeeded))
    end
    
    return table.concat(result)
end

-- ============================================================================
-- DECODING FUNCTIONS
-- ============================================================================

--- Decode 5 base85 characters into 4 bytes
---@param c1 string Character 1
---@param c2 string Character 2
---@param c3 string Character 3
---@param c4 string Character 4
---@param c5 string Character 5
---@return number, number, number, number bytes
local function DecodeGroup(c1, c2, c3, c4, c5)
    local v1 = DECODE_TABLE[c1] or 0
    local v2 = DECODE_TABLE[c2] or 0
    local v3 = DECODE_TABLE[c3] or 0
    local v4 = DECODE_TABLE[c4] or 0
    local v5 = DECODE_TABLE[c5] or 0
    
    -- Convert from base85 to 32-bit number
    local value = v1 * 52200625 + v2 * 614125 + v3 * 7225 + v4 * 85 + v5
    
    -- Extract 4 bytes
    local b1 = math.floor(value / 16777216) % 256
    local b2 = math.floor(value / 65536) % 256
    local b3 = math.floor(value / 256) % 256
    local b4 = value % 256
    
    return b1, b2, b3, b4
end

--- Decode Base85 string
---@param data string
---@return string|nil decoded, string|nil error
function Base85:Decode(data)
    if not data or data == "" then
        return "", nil
    end
    
    local result = {}
    local len = #data
    local pos = 1
    
    -- Process 5-character groups
    while pos + 4 <= len do
        local c1 = data:sub(pos, pos)
        local c2 = data:sub(pos + 1, pos + 1)
        local c3 = data:sub(pos + 2, pos + 2)
        local c4 = data:sub(pos + 3, pos + 3)
        local c5 = data:sub(pos + 4, pos + 4)
        
        if not (DECODE_TABLE[c1] and DECODE_TABLE[c2] and DECODE_TABLE[c3] and DECODE_TABLE[c4] and DECODE_TABLE[c5]) then
            return nil, "Invalid Base85 character"
        end
        
        local b1, b2, b3, b4 = DecodeGroup(c1, c2, c3, c4, c5)
        table.insert(result, string.char(b1, b2, b3, b4))
        pos = pos + 5
    end
    
    -- Handle remaining characters (2-4 chars)
    if pos <= len then
        local remaining = len - pos + 1
        
        -- Pad with zeros to make 5 characters
        local c1 = data:sub(pos, pos)
        local c2 = data:sub(pos + 1, pos + 1)
        local c3 = remaining >= 3 and data:sub(pos + 2, pos + 2) or ENCODE_TABLE[0]
        local c4 = remaining >= 4 and data:sub(pos + 3, pos + 3) or ENCODE_TABLE[0]
        local c5 = ENCODE_TABLE[0]
        
        if not (DECODE_TABLE[c1] and DECODE_TABLE[c2]) then
            return nil, "Invalid Base85 character in padding"
        end
        
        local b1, b2, b3, b4 = DecodeGroup(c1, c2, c3, c4, c5)
        
        -- Only include bytes based on remaining characters
        -- 2 chars → 1 byte, 3 chars → 2 bytes, 4 chars → 3 bytes
        local bytesNeeded = remaining - 1
        if bytesNeeded >= 1 then table.insert(result, string.char(b1)) end
        if bytesNeeded >= 2 then table.insert(result, string.char(b2)) end
        if bytesNeeded >= 3 then table.insert(result, string.char(b3)) end
    end
    
    return table.concat(result), nil
end

--- Get encoding statistics
---@param original string
---@param encoded string
---@return table stats
function Base85:GetStats(original, encoded)
    local originalSize = #original
    local encodedSize = #encoded
    local overhead = encodedSize - originalSize
    local ratio = originalSize > 0 and (overhead / originalSize) * 100 or 0
    
    return {
        originalSize = originalSize,
        encodedSize = encodedSize,
        overhead = overhead,
        ratio = ratio,
    }
end

return Base85
