-- ArenaFrameStealth.lua
-- Simple stealth detection for arena frames
-- Only handles frame alpha changes based on stealth state - nothing else

local AC = _G.ArenaCore
if not AC then return end

-- ============================================================================
-- MODULE SETUP
-- ============================================================================

local Stealth = {}
AC.ArenaFrameStealth = Stealth

-- ============================================================================
-- ALPHA VALUES
-- ============================================================================

local ALPHA = {
    VISIBLE = 1.0,      -- Enemy visible (normal state)
    STEALTH = 0.5,      -- Enemy in stealth (50% transparent)
    DESTROYED = 0.3,    -- Enemy left arena (30% transparent)
    CLEARED = 0         -- Match ended (hidden)
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

--- Get arena frames from FrameManager
local function GetArenaFrames()
    return AC.FrameManager and AC.FrameManager:GetFrames() or AC.arenaFrames
end

--- Check if we're in an active arena
local function IsInArena()
    local _, instanceType = IsInInstance()
    -- CRITICAL: Use both checks to block battlegrounds
    return instanceType == "arena" and IsActiveBattlefieldArena()
end

--- Validate unit token
local function IsValidUnit(unit)
    return unit and unit:match("^arena[1-3]$")
end

-- ============================================================================
-- CORE STEALTH HANDLER
-- ============================================================================

--- Handle ARENA_OPPONENT_UPDATE event
--- This is the ONLY event we need for stealth detection
function Stealth:OnArenaOpponentUpdate(unit, updateType)
    -- Safety checks
    if not IsInArena() then return end
    if not IsValidUnit(unit) then return end
    
    -- Extract arena index from unit token (e.g., "arena1" -> 1)
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if not arenaIndex then return end
    
    -- Get the frame for this arena unit
    local frames = GetArenaFrames()
    if not frames then return end
    
    local frame = frames[arenaIndex]
    if not frame then return end
    
    -- Simple alpha changes based on update type
    if updateType == "seen" then
        -- ALWAYS set alpha to 1.0 on "seen"
        -- This is how prep room alpha gets restored when gates open
        frame:SetAlpha(ALPHA.VISIBLE)
        
    elseif updateType == "unseen" then
        -- Enemy went into stealth
        frame:SetAlpha(ALPHA.STEALTH)
        
    elseif updateType == "destroyed" then
        -- Enemy left arena (died or left match)
        frame:SetAlpha(ALPHA.DESTROYED)
        
    elseif updateType == "cleared" then
        -- Match ended - hide frame
        frame:SetAlpha(ALPHA.CLEARED)
    end
end

-- ============================================================================
-- PREP ROOM HANDLER
-- ============================================================================

--- Handle ARENA_PREP_OPPONENT_SPECIALIZATIONS event
--- Set all frames to 0.5 alpha during prep to handle stealth at gate open
function Stealth:OnArenaPrepOpponents()
    if not IsInArena() then return end
    
    local frames = GetArenaFrames()
    if not frames then return end
    
    -- Set all frames to stealth alpha
    -- This ensures stealthed players at gate open are already at correct alpha
    for i = 1, 3 do
        if frames[i] then
            frames[i]:SetAlpha(ALPHA.STEALTH)
        end
    end
end

-- ============================================================================
-- EVENT REGISTRATION
-- ============================================================================

--- Initialize the stealth detection module
function Stealth:Initialize()
    -- Create event frame
    self.eventFrame = CreateFrame("Frame")
    
    -- Register events
    self.eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self.eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    
    -- Set up event handler
    self.eventFrame:SetScript("OnEvent", function(_, event, unit, updateType)
        if event == "ARENA_OPPONENT_UPDATE" then
            self:OnArenaOpponentUpdate(unit, updateType)
        elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
            self:OnArenaPrepOpponents()
        end
    end)
end

-- ============================================================================
-- AUTO-INITIALIZE
-- ============================================================================

-- Initialize when module loads
Stealth:Initialize()
