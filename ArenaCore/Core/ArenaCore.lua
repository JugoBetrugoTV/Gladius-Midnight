-- ============================================================================
-- ARENACORE MASTER FILE - CHUNK 1: INITIALIZATION & CONSTANTS
-- Sections 1-2: Initialization & Database System
-- ============================================================================

-- ============================================================================
-- 1. INITIALIZATION & CONSTANTS
-- ============================================================================

local AC = _G.ArenaCore or {}
_G.ArenaCore = AC

-- CRITICAL FIX: Use FORWARD slashes (WoW prefers these over backslashes!)
AC.FONT_PATH = "Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf"
AC.CUSTOM_FONT = "Fonts\\\\FRIZQT__.TTF"

-- ============================================================================
-- PHASE 1.2: CENTRAL TICKER MANAGEMENT SYSTEM
-- Prevents memory leaks from orphaned tickers
-- ============================================================================

AC.activeTickers = AC.activeTickers or {}

-- Register a ticker for automatic cleanup
function AC:RegisterTicker(ticker, name)
    if not ticker then return end
    if not name then
        name = "ticker_" .. tostring(ticker)
    end
    
    self.activeTickers[name] = ticker
    return ticker
end

-- Cancel a specific ticker by name
function AC:CancelTicker(name)
    local ticker = self.activeTickers[name]
    if ticker and ticker.Cancel then
        ticker:Cancel()
    end
    self.activeTickers[name] = nil
end

-- Cancel all registered tickers
function AC:CancelAllTickers()
    local count = 0
    for name, ticker in pairs(self.activeTickers) do
        if ticker and ticker.Cancel then
            ticker:Cancel()
            count = count + 1
        end
    end
    wipe(self.activeTickers)
    -- DEBUG DISABLED FOR PRODUCTION
    -- if count > 0 then
    --     print("|cffFF0000[TickerRegistry]|r Cancelled " .. count .. " active tickers")
    -- end
end

-- Wrapper function for easy ticker creation with auto-registration
function AC:CreateTicker(interval, callback, name)
    local ticker = C_Timer.NewTicker(interval, callback)
    self:RegisterTicker(ticker, name)
    return ticker
end

-- Enhanced TickerChecker integration
function AC:CheckActiveTickers()
    local count = 0
    for name, ticker in pairs(self.activeTickers) do
        if ticker then
            count = count + 1
            -- print("|cff00FFFF[TickerCheck]|r Active: " .. name)
        end
    end
    
    -- DEBUG DISABLED FOR PRODUCTION
    -- if count == 0 then
    --     print("|cffFFAA00[TickerCheck]|r No active tickers found.")
    --     print("|cffFFAA00[TickerCheck]|r Tickers are created when:")
    --     print("  - Test mode is enabled (/ac test)")
    --     print("  - You enter an arena match")
    --     print("  - Certain features are active")
    -- else
    --     print("|cff00FF00[TickerCheck]|r Total active tickers: " .. count)
    -- end
    
    return count
end

-- ============================================================================
-- PHASE 2.3: EVENT FRAME CLEANUP SYSTEM
-- Ensures proper cleanup when features disabled or on logout
-- ============================================================================

AC.eventFrames = AC.eventFrames or {}

-- Register an event frame for automatic cleanup
function AC:RegisterEventFrame(frame, name)
    if not frame then return end
    if not name then
        name = "eventframe_" .. tostring(frame)
    end
    
    self.eventFrames[name] = frame
    return frame
end

-- Unregister a specific event frame by name
function AC:UnregisterEventFrame(name)
    local frame = self.eventFrames[name]
    if frame and frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end
    self.eventFrames[name] = nil
end

-- Unregister all tracked event frames
function AC:UnregisterAllEvents()
    local count = 0
    for name, frame in pairs(self.eventFrames) do
        if frame and frame.UnregisterAllEvents then
            frame:UnregisterAllEvents()
            count = count + 1
        end
    end
    wipe(self.eventFrames)
    if count > 0 then
        print("|cffFF0000[EventCleanup]|r Unregistered " .. count .. " event frames")
    end
end

-- Check active event frames (debug command)
function AC:CheckActiveEventFrames()
    local count = 0
    for name, frame in pairs(self.eventFrames) do
        if frame then
            count = count + 1
            print("|cff00FFFF[EventCheck]|r Active: " .. name)
        end
    end
    
    if count == 0 then
        print("|cffFFAA00[EventCheck]|r No active event frames found.")
    else
        print("|cff00FF00[EventCheck]|r Total active event frames: " .. count)
    end
    
    return count
end

-- Comprehensive cleanup on logout or disable
function AC:Cleanup()
    print("|cffFFAA00[ArenaCore]|r Performing cleanup...")
    
    -- Cancel all tickers
    self:CancelAllTickers()
    
    -- Unregister all events
    self:UnregisterAllEvents()
    
    print("|cff00FF00[ArenaCore]|r Cleanup complete!")
end

-- ============================================================================
-- PHASE 3.2: DATABASE SETTINGS CACHE
-- Eliminates repeated table lookups for 2-5 FPS gain
-- ============================================================================

AC.cachedSettings = AC.cachedSettings or {}

-- Refresh settings cache from database
function AC:RefreshSettingsCache()
    if not self.DB or not self.DB.profile then
        self:EnsureDB()
    end
    
    local db = self.DB.profile
    
    -- Cache frequently accessed settings
    self.cachedSettings = {
        -- Arena Frames
        arenaFrames = {
            width = db.arenaFrames and db.arenaFrames.sizing and db.arenaFrames.sizing.width or 200,
            height = db.arenaFrames and db.arenaFrames.sizing and db.arenaFrames.sizing.height or 50,
            spacing = db.arenaFrames and db.arenaFrames.positioning and db.arenaFrames.positioning.spacing or 21,
            horizontal = db.arenaFrames and db.arenaFrames.positioning and db.arenaFrames.positioning.horizontal or 0,
            vertical = db.arenaFrames and db.arenaFrames.positioning and db.arenaFrames.positioning.vertical or 0,
            growthDirection = db.arenaFrames and db.arenaFrames.positioning and db.arenaFrames.positioning.growthDirection or "Down",
            useClassColors = db.arenaFrames and db.arenaFrames.general and db.arenaFrames.general.useClassColors ~= false,
            usePercentage = db.arenaFrames and db.arenaFrames.general and db.arenaFrames.general.usePercentage or false,
            showArenaServerNames = db.arenaFrames and db.arenaFrames.general and db.arenaFrames.general.showArenaServerNames or false,
            playerNameX = db.arenaFrames and db.arenaFrames.general and db.arenaFrames.general.playerNameX or 52,
            playerNameY = db.arenaFrames and db.arenaFrames.general and db.arenaFrames.general.playerNameY or 0,
        },
        
        -- Trinkets
        trinkets = {
            fontSize = db.trinkets and db.trinkets.sizing and db.trinkets.sizing.fontSize or 12,
            iconDesign = db.trinkets and db.trinkets.iconDesign or "retail",
        },
        
        -- Racials
        racials = {
            fontSize = db.racials and db.racials.sizing and db.racials.sizing.fontSize or 12,
        },
        
        -- Debuffs
        debuffs = {
            enabled = db.moreGoodies and db.moreGoodies.debuffs and db.moreGoodies.debuffs.enabled ~= false,
            horizontal = db.moreGoodies and db.moreGoodies.debuffs and db.moreGoodies.debuffs.positioning and db.moreGoodies.debuffs.positioning.horizontal or 8,
            vertical = db.moreGoodies and db.moreGoodies.debuffs and db.moreGoodies.debuffs.positioning and db.moreGoodies.debuffs.positioning.vertical or 6,
        },
        
        -- Absorbs
        absorbs = {
            enabled = db.moreGoodies and db.moreGoodies.absorbs and db.moreGoodies.absorbs.enabled or false,
        },
        
        -- Cast Bars (CRITICAL: Defaults MUST match Init.lua DEFAULTS.castBars)
        castBars = {
            horizontal = db.castBars and db.castBars.positioning and db.castBars.positioning.horizontal or -4,
            vertical = db.castBars and db.castBars.positioning and db.castBars.positioning.vertical or -86,
            width = db.castBars and db.castBars.sizing and db.castBars.sizing.width or 220,
            height = db.castBars and db.castBars.sizing and db.castBars.sizing.height or 24,
        },
        
        -- Textures
        textures = {
            healthWidth = db.textures and db.textures.sizing and db.textures.sizing.healthWidth or 128,
            healthHeight = db.textures and db.textures.sizing and db.textures.sizing.healthHeight or 18,
        },
        
        -- DR
        diminishingReturns = {
            enabled = db.diminishingReturns and db.diminishingReturns.enabled ~= false,
        },
    }
    
    -- Debug output
    -- print("|cff00FF00[SettingsCache]|r Cache refreshed with " .. self:CountCachedSettings() .. " settings")
end

-- Count cached settings (for debug)
function AC:CountCachedSettings()
    local count = 0
    for category, settings in pairs(self.cachedSettings) do
        for _ in pairs(settings) do
            count = count + 1
        end
    end
    return count
end

-- Get cached setting with fallback to database
function AC:GetCachedSetting(category, key, default)
    -- Try cache first
    if self.cachedSettings[category] and self.cachedSettings[category][key] ~= nil then
        return self.cachedSettings[category][key]
    end
    
    -- Fallback to database
    self:RefreshSettingsCache()
    return self.cachedSettings[category] and self.cachedSettings[category][key] or default
end

-- Safe font setter - never crashes even if font path is invalid
function AC.SafeSetFont(fontString, desiredFont, height, flags)
    if not fontString or not fontString.SetFont then return nil end
    
    -- Resolve font path
    local fontToUse = AC.CUSTOM_FONT -- Safe fallback
    if type(desiredFont) == "string" and desiredFont ~= "" then
        fontToUse = desiredFont
    elseif type(AC.FONT_PATH) == "string" and AC.FONT_PATH ~= "" then
        fontToUse = AC.FONT_PATH
    end
    
    -- Normalize parameters
    height = tonumber(height) or 12
    flags = (flags and flags ~= "") and flags or nil
    
    -- Safe call with pcall
    local success = pcall(function()
        fontString:SetFont(fontToUse, height, flags)
    end)
    
    if not success then
        -- Ultimate fallback to WoW default (also wrapped in pcall for safety)
        pcall(function()
            fontString:SetFont("Fonts\\FRIZQT__.TTF", height, flags)
        end)
    end
    
    -- CRITICAL ARENA FIX: Mark font as set to prevent "Font not set" errors
    fontString._fontIsSet = true
    
    return fontToUse
end

-- CRITICAL ARENA FIX: Wrap SetText to auto-set font if missing (ArenaCore frames only)
local function SafeSetText(fontString, text)
    if fontString and not fontString._fontIsSet then
        -- Font was never set - apply emergency font
        AC.SafeSetFont(fontString, AC.FONT_PATH, 12, "OUTLINE")
    end
    if fontString and fontString.SetText then
        fontString:SetText(text or "")
    end
end

-- REMOVED: Global hook was affecting all WoW UI fonts
-- Instead, we'll ensure all ArenaCore FontStrings use SafeSetFont

-- Create reusable FontObjects for UI (prevents "Font not set" errors)
function AC.EnsureUIFontObjects()
    if AC.UIFont then return end -- Already created
    
    local function makeFontObject(name, size, flags)
        local font = CreateFont(name)
        local path = AC.FONT_PATH or "Fonts\\\\FRIZQT__.TTF"
        font:SetFont(path, size, flags or "")
        return font
    end
    
    AC.UIFont = makeFontObject("ArenaCoreUIFont", 12, nil)
    AC.UIFontSmall = makeFontObject("ArenaCoreUIFontSmall", 11, nil)
    AC.UIFontMedium = makeFontObject("ArenaCoreUIFontMedium", 13, nil)
    AC.UIFontLarge = makeFontObject("ArenaCoreUIFontLarge", 16, "OUTLINE")
    AC.UIFontHeader = makeFontObject("ArenaCoreUIFontHeader", 20, "OUTLINE")
    
    -- DEBUG: UI FontObjects created
    -- print("|cff00FF00[ArenaCore]|r UI FontObjects created successfully")
end

-- REMOVED: Global CreateFontString hook (caused 500MB+ memory leak)
-- ArenaCore frames now set fonts explicitly using SafeSetFont()

-- Recursively fix any FontStrings that don't have fonts set
function AC.FixUIFontsRecursively(frame)
    if not frame then return end
    
    -- Fix all FontString regions in this frame
    for _, region in ipairs({frame:GetRegions()}) do
        if region.GetObjectType and region:GetObjectType() == "FontString" then
            local path = region:GetFont()
            if not path then
                -- FontString has no font - set it to our default
                AC.EnsureUIFontObjects()
                region:SetFontObject(AC.UIFont)
            end
        end
    end
    
    -- Recursively fix all child frames
    for _, child in ipairs({frame:GetChildren()}) do
        AC.FixUIFontsRecursively(child)
    end
end

-- Master Frame Manager - The one system to rule them all
AC.MasterFrameManager = AC.MasterFrameManager or {}
local MFM = AC.MasterFrameManager

-- FrameManager alias for compatibility with consolidated functions
AC.FrameManager = AC.MasterFrameManager
local FrameManager = AC.FrameManager

--[[ OLD CAST BAR SYSTEM - DISABLED
local function GetCastBarModule()
    if AC.MasterFrameManager and AC.MasterFrameManager.CastBars then
        return AC.MasterFrameManager.CastBars
    end
    if AC.FrameManager and AC.FrameManager.CastBars then
        return AC.FrameManager.CastBars
    end
    return nil
end
--]]

-- State tracking
MFM.frames = {}  -- Our unified frames array
MFM.isInArena = false
MFM.isTestMode = false
MFM.instanceType = nil
MFM.eventFrame = nil

-- ============================================================================
-- HELPER METHODS for FrameManager
-- ============================================================================

-- Get frames array (used by debuff system and other components)
function FrameManager:GetFrames()
    return self.frames or {}
end

-- Check if frames exist and are available
function FrameManager:FramesExist()
    return self.frames and #self.frames > 0
end

-- Delegate trinket icon lookup to the TrinketsRacials module for consistency.
local function GetTrinketIcon()
    if AC.TrinketsRacials and AC.TrinketsRacials.GetUserTrinketIcon then
        return AC.TrinketsRacials:GetUserTrinketIcon()
    end
    return 1322720 -- Retail Gladiator Medallion fallback
end

local function GetDebuffModule()
    if AC.MasterFrameManager and AC.MasterFrameManager.Debuffs then
        return AC.MasterFrameManager.Debuffs
    end
    if AC.FrameManager and AC.FrameManager.Debuffs then
        return AC.FrameManager.Debuffs
    end
    return nil
end

local function GetDispelModule()
    if AC.MasterFrameManager and AC.MasterFrameManager.Dispels then
        return AC.MasterFrameManager.Dispels
    end
    if AC.FrameManager and AC.FrameManager.Dispels then
        return AC.FrameManager.Dispels
    end
    return nil
end

local function GetDRModule()
    -- Use Midnight DR module if in Midnight
    if AC.Midnight and AC.Midnight.isMidnight and AC.DRMidnight then
        return AC.DRMidnight
    end
    
    -- Otherwise use regular DR module
    if AC.MasterFrameManager and AC.MasterFrameManager.DR then
        return AC.MasterFrameManager.DR
    end
    if AC.FrameManager and AC.FrameManager.DR then
        return AC.FrameManager.DR
    end
    return nil
end

-- Constants
local MAX_ARENA_ENEMIES = 3
local FRAME_PREFIX = "ArenaCoreFrame"
local FRAME_WIDTH, FRAME_HEIGHT = 350, 72
local FRAME_SPACING = 12
local HEALTH_W, HEALTH_H = 245, 18
local MANA_W, MANA_H = 245, 8
local HEALTH_X, HEALTH_Y = 56, 6
local MANA_X, MANA_Y = 56, -14
local SELECTION_TINT = {0.97, 0.27, 0.30, 1}
local DR_TIME = 18.5

-- ArenaTracking now uses frames created by FrameLayout via _G.ArenaCore.arenaFrames
local updateTicker
local DR_SEVERITY_COLORS = {
    [1] = { 0, 1, 0, 1}, -- Green
    [2] = { 1, 1, 0, 1}, -- Yellow
    [3] = { 1, 0, 0, 1}, -- Red
}

local config = {
  position = { x = 200, y = -200 },
  scale = 1.0,
  growthDirection = "Down",
}

AC.testModeEnabled = false
AC.framesLocked = true

-- Define DR categories for frame creation (must match UI_DetailedDRSettings.lua)
AC.DR_CATEGORIES = {
    "stun", "silence", "root", "incapacitate", "disorient", "fear", "mc", "cyclone", "banish", "knockback", "disarm"
}

-- Class colors
local CLASS = {
  DEATHKNIGHT = {0.77, 0.12, 0.23}, DEMONHUNTER = {0.64, 0.19, 0.79},
  DRUID = {1.00, 0.49, 0.04}, EVOKER = {0.20, 0.58, 0.50},
  HUNTER = {0.67, 0.83, 0.45}, MAGE = {0.25, 0.78, 0.92},
  MONK = {0.00, 1.00, 0.60}, PALADIN = {0.96, 0.55, 0.73},
  PRIEST = {1.00, 1.00, 1.00}, ROGUE = {1.00, 0.96, 0.41},
  SHAMAN = {0.00, 0.44, 0.87}, WARLOCK = {0.53, 0.53, 0.93},
  WARRIOR = {0.78, 0.61, 0.43},
}

-- Texture paths
local A = "Interface\\AddOns\\ArenaCore\\Media\\Textures\\"
local TEX = {
  frame_bg = A.."frame_background.tga", frame_border = A.."frame_border.tga",
  frame_hover = A.."frame_hover.tga", class_icon_bg = A.."class_icon_bg.tga",
  spec_icon_bg = A.."spec_icon_bg.tga", spec_icon_border = A.."spec_icon_border.tga",
  health_bg = A.."health_bg.tga", health_border = A.."health_border.tga",
  health_fill = A.."health_fill.tga", mana_bg = A.."mana_bg.tga",
  mana_border = A.."mana_border.tga", mana_fill = A.."mana_fill.tga",
  cast_bg = A.."cast_bg.tga", cast_fill = A.."cast_fill.tga",
  target_arrow = A.."target_arrow.tga", trinket_bg = A.."trinket_bg.tga",
  trinket_border = A.."trinket_border.tga", debuff_bg = A.."debuff_bg.tga",
  debuff_border = A.."debuff_border.tga",
}

-- Racial data
local racialData = {
    ["Human"] = { texture = 59752, sharedCD = 90 },
    ["Scourge"] = { texture = 7744, sharedCD = 30 },
    ["Dwarf"] = { texture = 20594, sharedCD = 30 },
    ["NightElf"] = { texture = 58984, sharedCD = 0 },
    ["Gnome"] = { texture = 20589, sharedCD = 0 },
    ["Draenei"] = { texture = 59542, sharedCD = 0 },
    ["Worgen"] = { texture = 68992, sharedCD = 0 },
    ["Pandaren"] = { texture = 107079, sharedCD = 0 },
    ["Orc"] = { texture = 33697, sharedCD = 0 },
    ["Tauren"] = { texture = 20549, sharedCD = 0 },
    ["Troll"] = { texture = 26297, sharedCD = 0 },
    ["BloodElf"] = { texture = 202719, sharedCD = 0 },
    ["Goblin"] = { texture = 69070, sharedCD = 0 },
    ["LightforgedDraenei"] = { texture = 255647, sharedCD = 0 },
    ["HighmountainTauren"] = { texture = 255654, sharedCD = 0 },
    ["Nightborne"] = { texture = 260364, sharedCD = 0 },
    ["MagharOrc"] = { texture = 274738, sharedCD = 0 },
    ["DarkIronDwarf"] = { texture = 265221, sharedCD = 30 },
    ["ZandalariTroll"] = { texture = 291944, sharedCD = 0 },
    ["VoidElf"] = { texture = 256948, sharedCD = 0 },
    ["KulTiran"] = { texture = 287712, sharedCD = 0 },
    ["Mechagnome"] = { texture = 312924, sharedCD = 0 },
    ["Vulpera"] = { texture = 312411, sharedCD = 0 },
    ["Dracthyr"] = { texture = 368970, sharedCD = 0 },
    ["EarthenDwarf"] = { texture = 436344, sharedCD = 0 }
}

-- Frame positioning anchor - CRITICAL: Must be movable for dragging to work
-- IMPORTANT: Uses TOPLEFT positioning like old system for smooth StartMoving()
AC.ArenaFramesAnchor = AC.ArenaFramesAnchor or CreateFrame("Frame", "ArenaCoreFramesAnchor", UIParent)
AC.ArenaFramesAnchor:SetSize(1, 1)
AC.ArenaFramesAnchor:SetMovable(true) -- Required for drag system
AC.ArenaFramesAnchor:SetUserPlaced(false) -- Don't save Blizzard position
AC.ArenaFramesAnchor:SetClampedToScreen(true) -- Keep on screen
AC.ArenaFramesAnchor:SetFrameStrata("MEDIUM")
AC.ArenaFramesAnchor:SetFrameLevel(1)
AC.ArenaFramesAnchor:EnableMouse(false) -- Anchor itself doesn't need mouse
-- Initial position will be set by UpdateFramePositions or from saved settings

-- ============================================================================
-- 2. DATABASE & SETTINGS SYSTEM  
-- ============================================================================

function AC:EnsureDB()
    _G.ArenaCoreDB = _G.ArenaCoreDB or { profile = {} }
    self.DB = _G.ArenaCoreDB
    self.DB.profile = self.DB.profile or {}
    
    -- CRITICAL FIX: Only ensure structure exists, NEVER overwrite existing settings!
    if not self.DB.profile.arenaFrames then
        self.DB.profile.arenaFrames = {}
    end
    if not self.DB.profile.arenaFrames.positioning then
        self.DB.profile.arenaFrames.positioning = {}
    end
    if not self.DB.profile.arenaFrames.sizing then
        self.DB.profile.arenaFrames.sizing = {}
    end
    if not self.DB.profile.arenaFrames.general then
        self.DB.profile.arenaFrames.general = {}
    end
    
    -- Only set defaults if the specific values don't exist
    -- This preserves user's carefully configured settings!
    -- Note: Defaults are properly set in Init.lua
    local pos = self.DB.profile.arenaFrames.positioning
    local siz = self.DB.profile.arenaFrames.sizing
    local gen = self.DB.profile.arenaFrames.general
    
    -- Set default target border thickness if not set
    if siz.targetBorderThickness == nil then
        siz.targetBorderThickness = 3
    end
end

-- Utility to set a dot-path inside a table (e.g., "arenaFrames.positioning.horizontal")
function AC:SetPath(root, path, value)
    if not root or not path then return end
    local t = root
    local parts = { strsplit('.', path) }
    for i = 1, #parts - 1 do
        local k = parts[i]
        t[k] = t[k] or {}
        t = t[k]
    end
    t[parts[#parts]] = value
end

-- Create main tracking container
local ArenaTracking = CreateFrame("Frame", "ArenaCore_ArenaTrackingContainer", UIParent)
AC.ArenaTracking = ArenaTracking

-- ============================================================================
AC.drTimerSystem = AC.drTimerSystem or {}

-- ============================================================================
-- ARENACORE MASTER FILE - CHUNK 3: ICON STYLING SYSTEM
-- Section 4: Complete Icon Styling & Border System
-- ============================================================================

-- ============================================================================
-- 4. ICON STYLING SYSTEM
-- ============================================================================

AC.IconStyling = AC.IconStyling or {}
local IconStyling = AC.IconStyling

-- Classic WoW icon textures from Blizzard Classic theme
local CLASSIC_TEXTURES = {
    backdrop = "Interface\\Buttons\\UI-Quickslot",
    normal = "Interface\\Buttons\\UI-Quickslot2", 
    border = "Interface\\Buttons\\UI-ActionButton-Border",
    highlight = "Interface\\Buttons\\CheckButtonHilight"
}

-- Icon styling configuration
local ICON_CONFIG = {
    iconTexCoords = {0, 1, 0, 1}, -- Full icon texture - no cropping
    normalTexCoords = {0, 1, 0, 1}, -- Normal frame texCoords
    backdropColor = {1, 1, 1, 0.4},
    borderColor = {0, 0, 0, 0.8}, -- Black border for rounded corners
    normalColor = {1, 1, 1, 1},
    highlightBlend = "ADD"
}

-- REMOVED DUPLICATE: IconStyling:CreateStyledIcon is defined in Core/IconStyling.lua
-- This duplicate was overwriting the correct version and missing the styledBorder assignment

--[[
    Applies classic styling to an existing icon texture
    
    @param iconTexture - Existing icon texture to style
    @param parentFrame - Parent frame (optional, for adding border)
    @param addBorder - Whether to add dark border (default: true)
]]
function IconStyling:StyleExistingIcon(iconTexture, parentFrame, addBorder)
    if not iconTexture then return end
    
    -- CRITICAL FIX: Don't apply styling to class icons that have preventStyling flag
    if parentFrame and parentFrame.preventStyling then
        return -- Skip styling for class icons
    end
    
    -- DON'T modify the icon texture at all - keep it full brightness and original texCoords
    
    -- Add simple thick black border using 4 textures with DYNAMIC SCALING
    if addBorder ~= false and parentFrame then
        if not parentFrame.styledBorder then
            -- Calculate border thickness as percentage of icon size (12% of smaller dimension)
            -- This ensures borders scale proportionally with icon size
            -- CRITICAL: Use parent frame size, not texture size (texture size may not be set yet)
            local iconWidth = parentFrame:GetWidth() or 32
            local iconHeight = parentFrame:GetHeight() or 32
            local minDimension = math.min(iconWidth, iconHeight)
            local borderThickness = math.max(2, math.floor(minDimension * 0.12)) -- 12% of size, minimum 2px
            
            -- Create 4 border textures for top, bottom, left, right with high sublevel
            -- Use sublevel 7 (max allowed) to ensure borders appear above the icon (sublevel 5)
            -- CRITICAL: Anchor to PARENT FRAME edges, not icon texture edges (for consistent borders)
            local borderTop = parentFrame:CreateTexture(nil, "OVERLAY", nil, 7)
            borderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
            borderTop:SetVertexColor(0, 0, 0, 1)
            borderTop:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
            borderTop:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 0, 0)
            borderTop:SetHeight(borderThickness)
            
            local borderBottom = parentFrame:CreateTexture(nil, "OVERLAY", nil, 7)
            borderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
            borderBottom:SetVertexColor(0, 0, 0, 1)
            borderBottom:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 0, 0)
            borderBottom:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0, 0)
            borderBottom:SetHeight(borderThickness)
            
            local borderLeft = parentFrame:CreateTexture(nil, "OVERLAY", nil, 7)
            borderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
            borderLeft:SetVertexColor(0, 0, 0, 1)
            borderLeft:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
            borderLeft:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 0, 0)
            borderLeft:SetWidth(borderThickness)
            
            local borderRight = parentFrame:CreateTexture(nil, "OVERLAY", nil, 7)
            borderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
            borderRight:SetVertexColor(0, 0, 0, 1)
            borderRight:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 0, 0)
            borderRight:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0, 0)
            borderRight:SetWidth(borderThickness)
            
            -- Store border data for potential updates
            parentFrame.styledBorder = {
                top = borderTop,
                bottom = borderBottom,
                left = borderLeft,
                right = borderRight,
                thickness = borderThickness,
                iconTexture = iconTexture
            }
        end
    end
end

-- REMOVED DUPLICATE: IconStyling:UpdateBorderThickness is defined in Core/IconStyling.lua

--[[
    Batch applies styling to multiple icons
    
    @param icons - Table of {texture = iconTexture, parent = parentFrame} entries
]]
function IconStyling:StyleMultipleIcons(icons)
    if not icons then return end
    
    for _, iconData in pairs(icons) do
        if iconData.texture then
            self:StyleExistingIcon(iconData.texture, iconData.parent, iconData.addBorder)
        end
    end
end

-- Global helper function for easy access
function AC:CreateStyledIcon(parent, size, showBorder, showBackdrop)
    return IconStyling:CreateStyledIcon(parent, size, showBorder, showBackdrop)
end

function AC:StyleIcon(iconTexture, parentFrame, addBorder)
    return IconStyling:StyleExistingIcon(iconTexture, parentFrame, addBorder)
end

function AC:UpdateIconBorder(parentFrame)
    return IconStyling:UpdateBorderThickness(parentFrame)
end

-- Create flat colored texture helper
function AC:CreateFlatTexture(parent, layer, sublevel, color, alpha)
    if not parent or not color then return nil end
    
    local texture = parent:CreateTexture(nil, layer, nil, sublevel)
    texture:SetTexture("Interface\\Buttons\\WHITE8X8")
    texture:SetVertexColor(color[1], color[2], color[3], alpha or color[4] or 1)
    
    return texture
end

-- Enhanced icon creation system for complex styling
function AC:CreateAdvancedIcon(parent, config)
    if not parent or not config then return nil end
    
    local size = config.size or 32
    local iconFrame = CreateFrame("Frame", nil, parent)
    iconFrame:SetSize(size, size)
    
    if config.point then
        iconFrame:SetPoint(config.point, config.x or 0, config.y or 0)
    end
    
    -- Background layer
    if config.background then
        local bg = iconFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        if config.background.texture then
            bg:SetTexture(config.background.texture)
            bg:SetTexCoord(unpack(config.background.texCoords or {0, 1, 0, 1}))
        else
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        end
        if config.background.color then
            bg:SetVertexColor(unpack(config.background.color))
        end
        iconFrame.background = bg
    end
    
    -- Main icon
    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    if config.iconInset then
        icon:SetSize(size - config.iconInset, size - config.iconInset)
        icon:SetPoint("CENTER")
    else
        icon:SetAllPoints()
    end
    icon:SetTexCoord(unpack(config.texCoords or {0.1, 0.9, 0.1, 0.9}))
    
    -- Border/overlay
    if config.border then
        local border = iconFrame:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints()
        border:SetTexture(config.border.texture)
        border:SetTexCoord(unpack(config.border.texCoords or {0, 1, 0, 1}))
        if config.border.color then
            border:SetVertexColor(unpack(config.border.color))
        end
        iconFrame.border = border
    end
    
    -- Store references
    iconFrame.icon = icon
    iconFrame.size = size
    
    -- Helper methods
    function iconFrame:SetIconTexture(texture)
        if self.icon then
            self.icon:SetTexture(texture)
        end
    end
    
    function iconFrame:SetBorderColor(r, g, b, a)
        if self.border then
            self.border:SetVertexColor(r, g, b, a or 1)
        end
    end
    
    return iconFrame
end

-- Spell school colors for cast bars
local SPELL_SCHOOL_COLORS = {
  [1] = {1.0, 1.0, 1.0},    -- Physical (White)
  [2] = {1.0, 1.0, 0.0},    -- Holy (Yellow)
  [4] = {1.0, 0.5, 0.0},    -- Fire (Orange)
  [8] = {0.3, 0.8, 1.0},    -- Nature (Light Blue)
  [16] = {0.5, 1.0, 1.0},   -- Frost (Cyan)
  [32] = {0.5, 0.0, 1.0},   -- Shadow (Purple)
  [64] = {1.0, 0.1, 1.0},   -- Arcane (Magenta)
}

-- ============================================================================
-- ARENACORE MASTER FILE - CHUNK 4: HELPER FUNCTIONS & UTILITIES
-- Section 5: Complete Helper Functions & Utility System
-- ============================================================================

-- ============================================================================
-- 5. HELPER FUNCTIONS & UTILITIES
-- ============================================================================

-- Bridge variable for compatibility
local arenaFrames = MFM.frames
local isTestMode = false

local function tContains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

-- Helper functions to bridge old and new systems
local function GetFrameSettings()
    if not AC.DB or not AC.DB.profile then AC:EnsureDB() end
    return AC.DB.profile.arenaFrames
end

local function GetArenaFrames()
    return MFM.frames
end

-- REMOVED: Duplicate GetTrinketIcon() function (line 696)
-- This was a duplicate of the function at line 194
-- The main GetTrinketIcon() at line 194 is used throughout the codebase

-- Helper function to check if a unit is a healer with null safety
local function IsHealer(unit)
    if not unit then return false end
    
    local id = string.match(unit, "arena(%d)")
    if not id then return false end
    
    local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(tonumber(id))
    if specID and specID > 0 then
        local _, _, _, _, role = GetSpecializationInfoByID(specID)
        return role == "HEALER"
    end
    return false
end

-- Helper function to get remaining cooldown time with safety checks
local function GetRemainingCD(cooldownFrame)
    if not cooldownFrame or not cooldownFrame.GetCooldownTimes then return 0 end
    
    local startTime, duration = cooldownFrame:GetCooldownTimes()
    if not startTime or startTime == 0 or not duration or duration == 0 then return 0 end
    
    local currTime = GetTime()
    local remaining = (startTime + duration) / 1000 - currTime
    return math.max(0, remaining) -- Never return negative values
end

-- Function to update cooldown timer text with test mode awareness
local function UpdateCooldownText(indicator)
    if not indicator or not indicator.cooldown or not indicator.cooldown.Text then return end
    
    -- In test mode, let FrameLayout handle cooldown displays
    if AC.testModeEnabled then return end
    
    local start, duration = indicator.cooldown:GetCooldownTimes()
    if start == 0 or duration == 0 then
        indicator.cooldown.Text:SetText("")
        indicator.cooldown.Text:Hide()
        return
    end
    
    local remaining = (start + duration) / 1000 - GetTime()
    if remaining > 0.5 then
        indicator.cooldown.Text:SetText(math.ceil(remaining))
        indicator.cooldown.Text:Show()
    else
        indicator.cooldown.Text:SetText("")
        indicator.cooldown.Text:Hide()
    end
end

-- Helper function to get class colors setting consistently
-- REMOVED DUPLICATE: This function is defined at line 9927 (authoritative version)
-- Using simpler logic: general.useClassColors ~= false (defaults to true)

-- REMOVED: Duplicate GetRemainingCooldown() function (lines 755-760)
-- This was a duplicate of GetRemainingCD() at line 715
-- GetRemainingCD() has better null safety checks

-- ENHANCED: Consolidated font string creation with consistent patterns
local function CreateFontString(parent, fontSize, outline, point, x, y, width, height)
    -- CRITICAL FIX: Use double backslashes and SafeSetFont
    local fontPath = "Interface\\\\AddOns\\\\ArenaCore\\\\Media\\\\Fonts\\\\arenacore.ttf"
    local fs = parent:CreateFontString(nil, "OVERLAY")
    
    -- Set font with optional outline using SafeSetFont
    local fontFlags = outline and "OUTLINE" or ""
    if AC and AC.SafeSetFont then
        AC.SafeSetFont(fs, fontPath, fontSize or 12, fontFlags)
    else
        fs:SetFont(fontPath, fontSize or 12, fontFlags)
    end
    
    -- Set position and size
    if point then
        fs:SetPoint(point, x or 0, y or 0)
    end
    if width and height then
        fs:SetSize(width, height)
        fs:SetJustifyH("LEFT")
    end
    
    fs:SetTextColor(1, 1, 1, 1)
    return fs
end

-- OPTIMIZED: Specific font string creators using consolidated function
local function CreateName(parent)
    return CreateFontString(parent, 13, false, "TOPLEFT", 56, -6, 270, 18)
end

local function CreateStatusText(parent)
    local fs = CreateFontString(parent, 10, true, "CENTER", 0, 0)
    fs:Hide()
    return fs
end

local function FormatHealth(n)
    if not n or n < 1000 then return tostring(n or 0) end
    if n >= 1000000 then return string.format("%.1fm", n / 1000000) end
    if n >= 1000 then return string.format("%.0fk", n / 1000) end
end

local function Trim(texture)
    if texture and texture.SetTexCoord then
        texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end
end

local function StopTicker()
    if updateTicker then
        updateTicker:Cancel()
        updateTicker = nil
    end
end

local function StartTicker()
    StopTicker()
    -- PHASE 3: Reduced from 0.5s to 1.0s (50% reduction, events handle real-time updates)
    updateTicker = AC:CreateTicker(1.0, UpdateAllFrames, "main_update_ticker")
end

local FadeIn = _G.UIFrameFadeIn or function(f, t, from, to) if f then f:SetAlpha(to or 1) end end
local FadeOut = _G.UIFrameFadeOut or function(f, t, from, to) if f then f:SetAlpha(to or 0) end end

-- Enhanced TriBadges attachment with comprehensive test mode support
local function AttachTriBadgesAll()
    -- CRITICAL: Don't interfere with FrameLayout test mode but ensure opacity
    if AC.testModeEnabled then 
        -- In test mode, ensure TriBadges have proper opacity
        local arenaFrames = _G.ArenaCore and _G.ArenaCore.arenaFrames
        if arenaFrames and _G.ArenaCore.TriBadges then
            for i = 1, MAX_ARENA_ENEMIES do
                if arenaFrames[i] and arenaFrames[i].TriBadges then
                    arenaFrames[i].TriBadges:SetAlpha(1.0)
                    if arenaFrames[i].TriBadges:IsShown() then
                        -- Ensure test mode TriBadges are fully visible
                        arenaFrames[i].TriBadges:Show()
                    end
                end
            end
        end
        return 
    end
    
    -- Normal attachment for live arena
    if _G.ArenaCore and _G.ArenaCore.TriBadges and _G.ArenaCore.TriBadges.Attach then
        local arenaFrames = _G.ArenaCore and _G.ArenaCore.arenaFrames
        if not arenaFrames then return end
        
        for i = 1, MAX_ARENA_ENEMIES do
            if arenaFrames[i] then
                _G.ArenaCore.TriBadges:Attach(arenaFrames[i], "arena"..i)
                if _G.ArenaCore.TriBadges.RefreshAll then
                    _G.ArenaCore.TriBadges:RefreshAll()
                end
            end
        end
    end
end

-- REMOVED: First duplicate UpdateFramePosition function (legacy system)
-- Kept the one at line ~5267 which works with MasterFrameManager

function AC:UpdateFrameSpacing()
    local settings = GetFrameSettings()
    if not settings then return end
    
    local positioning = settings.positioning or {}
    -- Update spacing using MasterFrameManager
    if MFM and MFM.UpdateFramePositions then
        MFM:UpdateFramePositions() -- This applies spacing changes
    end
end

-- REMOVED: First duplicate UpdateFrameScale function (legacy system)
-- Kept the one at line ~5359 which works with MasterFrameManager

-- REMOVED: First duplicate UpdateFrameSize function (legacy system)
-- Kept the one at line ~5377 which works with MasterFrameManager

function AC:SetGrowthDirection(direction)
    if not direction or not tContains({"Down", "Up", "Right", "Left"}, direction) then return end
    
    -- Store in database (avoid undefined config global)
    local settings = GetFrameSettings()
    if settings then
        settings.positioning = settings.positioning or {}
        settings.positioning.growthDirection = direction
        
        -- Notify MasterFrameManager system of growth direction change
        if MFM and MFM.UpdateFramePositions then
            MFM:UpdateFramePositions() -- This applies growth direction changes
        end
    end
end

-- REMOVED: Duplicate ResetToDefaultSettings function with dangerous legacy globals
-- This one had undefined globals: config, FRAME_SPACING, FRAME_WIDTH, FRAME_HEIGHT
-- Kept the clean one at line ~5363 which works with MasterFrameManager

-- Component-specific clear helpers for better maintainability
local function ClearHealthBars(frame)
    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, 100)
        frame.healthBar:SetValue(100)
        -- CRITICAL FIX: Respect statusText setting when clearing
        if frame.healthBar.text then
            local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
            local statusTextEnabled = general and general.statusText ~= false
            if statusTextEnabled then
                frame.healthBar.text:SetText("100%")
                frame.healthBar.text:Show()
            else
                frame.healthBar.text:Hide()
            end
        end
    end
    
    if frame.manaBar then
        frame.manaBar:SetMinMaxValues(0, 100)
        frame.manaBar:SetValue(100)
        -- CRITICAL FIX: Respect statusText setting when clearing
        if frame.manaBar.text then
            local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
            local statusTextEnabled = general and general.statusText ~= false
            if statusTextEnabled then
                frame.manaBar.text:SetText("100%")
                frame.manaBar.text:Show()
            else
                frame.manaBar.text:Hide()
            end
        end
    end
end

local function ClearIconsAndIndicators(frame)
    -- Clear class icon and spec chips
    if frame.classIcon then
        if frame.classIcon.icon then frame.classIcon.icon:SetTexture(nil) end
        if frame.classIcon.overlay then frame.classIcon.overlay:SetTexture(nil) end
        if frame.classIcon.background then frame.classIcon.background:SetVertexColor(1, 1, 1, 1) end
        if frame.classIcon.specChip then
            frame.classIcon.specChip:Hide()
            if frame.classIcon.specChip.icon then frame.classIcon.specChip.icon:SetTexture(nil) end
        end
    end
    
    -- Clear trinket and racial indicators
    if frame.trinketIndicator then
        if frame.trinketIndicator.texture then frame.trinketIndicator.texture:SetTexture(nil) end
        if frame.trinketIndicator.cooldown then frame.trinketIndicator.cooldown:Clear() end
        frame.trinketIndicator:Hide()
    end
    
    if frame.racialIndicator then
        if frame.racialIndicator.texture then frame.racialIndicator.texture:SetTexture(nil) end
        if frame.racialIndicator.cooldown then frame.racialIndicator.cooldown:Clear() end
        frame.racialIndicator:Hide()
    end
    
    -- CRITICAL FIX: Clear death icon to prevent leaks
    if frame.deathIconFrame then
        frame.deathIconFrame:Hide()
    end
end

local function ClearDebuffsAndDR(frame)
    -- Clear all debuffs/auras
    if frame.debuffContainer and frame.debuffContainer.debuffs then
        for _, debuff in pairs(frame.debuffContainer.debuffs) do
            if debuff then
                debuff:Hide()
                if debuff.icon then debuff.icon:SetTexture(nil) end
                if debuff.cooldown then debuff.cooldown:Clear() end
            end
        end
        wipe(frame.debuffContainer.debuffs)
    end
    
    -- Clear all DR (Diminishing Returns) icons
    if frame.drIcons then
        for category, dr in pairs(frame.drIcons) do
            if dr then
                dr:Hide()
                if dr.icon then dr.icon:SetTexture(nil) end
                if dr.cooldown then 
                    dr.cooldown.duration = 0
                    dr.cooldown.startTime = 0
                end
                if dr.timerText then dr.timerText:Hide() end
                dr.severity = 1
            end
        end
    end
end

local function ClearMiscElements(frame)
    --[[ OLD CAST BAR SYSTEM - DISABLED
    -- Clear cast bars
    if frame.castBar then
        if frame.castBar.Icon then frame.castBar.Icon:SetTexture(nil) end
        if frame.castBar.Text then frame.castBar.Text:SetText("") end
        frame.castBar:SetValue(0)
        frame.castBar:Hide()
    end
    --]]
    
    -- Clear target indicator
    if frame.targetIndicator then
        frame.targetIndicator:SetAlpha(0)
    end
    
    -- Clear player name and stored race data
    if frame.playerName then frame.playerName:SetText("") end
    frame.race = nil
end

-- OPTIMIZED: Clean, modular ClearArenaData function
function AC:ClearArenaData()
    -- CRITICAL: Complete test mode protection with frame restoration
    if AC.testModeEnabled then
        if not AC._clearDataWarningShown then
            print("|cffFF0000[CRITICAL]|r ClearArenaData blocked during TEST MODE - Restoring frame opacity")
            AC._clearDataWarningShown = true
        end
        
        local arenaFrames = _G.ArenaCore and _G.ArenaCore.arenaFrames
        if arenaFrames then
            for i = 1, MAX_ARENA_ENEMIES do
                if arenaFrames[i] then
                    local f = arenaFrames[i]
                    f:SetAlpha(1.0)
                    if f.playerName and (not f.playerName:GetText() or f.playerName:GetText() == "") then
                        -- ARCHITECTURAL FIX: Use unified text control system
                        AC:SetArenaFrameText(f, i, "test_mode")
                        -- CRITICAL FIX: Only show if enabled in settings
                        local db = AC.DB and AC.DB.profile
                        local general = db and db.arenaFrames and db.arenaFrames.general or {}
                        if general.showNames ~= false and not InCombatLockdown() then
                            f.playerName:Show()
                        end
                    end
                end
            end
        end
        return
    end
    AC._clearDataWarningShown = false
    
    -- STAGE 2: REMOVED _stealthTimers clearing
    
    -- Use FrameLayout frames with proper null safety
    local arenaFrames = _G.ArenaCore and _G.ArenaCore.arenaFrames
    if not arenaFrames then return end
    
    -- Use modular helper functions for clean, maintainable clearing
    for i = 1, MAX_ARENA_ENEMIES do
        if arenaFrames[i] then
            local f = arenaFrames[i]
            ClearHealthBars(f)
            ClearIconsAndIndicators(f)
            ClearDebuffsAndDR(f)
            ClearMiscElements(f)
        end
    end
end

-- Function to refresh all trinket icons when iconDesign setting changes
function AC:RefreshTrinketIcons()
  -- Use the correct frame array that has trinket indicators
  local frames = AC.arenaFrames or arenaFrames
  
  -- Also handle new FrameManager frames
  if AC.FrameManager and AC.FrameManager.GetFrames then
    local fmFrames = AC.FrameManager:GetFrames()
    if fmFrames and #fmFrames > 0 then
      frames = fmFrames
    end
  end
  
  for i = 1, MAX_ARENA_ENEMIES do
    if frames[i] and frames[i].trinketIndicator then
      -- Get the custom trinket icon based on current setting
      local trinketIcon = GetTrinketIcon()
      local trinketTexture
      
      -- Handle both texture paths (strings) and spell IDs (numbers)
      if type(trinketIcon) == "string" then
        trinketTexture = trinketIcon -- Direct texture path
      else
        trinketTexture = C_Spell.GetSpellTexture(trinketIcon) -- Spell ID lookup
      end
      
      if trinketTexture then
        -- Use .icon property based on CreateTrinket function (FrameManager structure)
        if frames[i].trinketIndicator.icon then
          frames[i].trinketIndicator.icon:SetTexture(trinketTexture)
        elseif frames[i].trinketIndicator.texture then
          frames[i].trinketIndicator.texture:SetTexture(trinketTexture)
        end
      end
    end
  end
end

-- ============================================================================
-- ARENACORE MASTER FILE - CHUNK 5: FRAME CREATION SYSTEM
-- Section 6: Complete Frame Creation & Master Frame Manager
-- ============================================================================

-- ============================================================================
-- 6. FRAME CREATION SYSTEM
-- ============================================================================

function MFM:CreateArenaFrame(index)
    local frameName = FRAME_PREFIX .. index
    local unit = "arena" .. index
    
    -- Check if frame already exists
    if self.frames[index] then
        return self.frames[index]
    end
    
    -- DEBUG: Creating unified frame
    -- print("|cffFFAA00ArenaCore Master:|r Creating unified frame " .. index)
    
    -- Create frame using SecureUnitButtonTemplate (PROVEN TO WORK!)
    local frame = CreateFrame("Button", frameName, AC.ArenaFramesAnchor, "SecureUnitButtonTemplate")
    
    -- Basic setup
    frame:SetSize(200, 60)  -- Default size, will be updated by UpdateFramePositions()
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(2)
    frame:SetMovable(false) -- Frame itself doesn't move - anchor moves instead
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    -- CRITICAL FIX: Initialize frame alpha to 1.0
    -- This prevents faded frames after reload mid-arena
    -- Alpha should only be 0.5 in prep room for stealth detection
    frame:SetAlpha(1.0)
    
    -- Set unit attributes for secure clicking
    frame:SetAttribute("*type1", "target")          -- Left-click to target
    frame:SetAttribute("*type2", "focus")           -- Right-click to focus (direct, no menu)
    frame:SetAttribute("unit", unit)
    frame.unit = unit
    frame.id = index
    
    -- Register for clicks
    frame:RegisterForClicks("AnyUp")
    
    -- DEBUG: Frame created
    -- print("|cff00FF00[Frame Created]|r " .. frameName .. " - Left-click=target, Right-click=focus")
    
    -- DRAG HANDLERS: Ctrl+Alt+LeftClick to drag (only when unlocked)
    frame:SetScript("OnDragStart", function(self)
        -- CRITICAL: Set flag immediately when drag starts
        AC.justFinishedDragging = true
        
        -- Combat check
        if InCombatLockdown() then
            -- Silently prevent frame movement in combat (no chat spam for end users)
            return
        end
        
        -- Require frames to be unlocked
        if AC.framesLocked then
            print("|cffFF4444ArenaCore:|r Frames are locked! Use Unlock button first.")
            return
        end
        
        -- Require Ctrl+Alt+Left Click
        if not (IsControlKeyDown() and IsAltKeyDown()) then
            -- DEBUG DISABLED FOR PRODUCTION
            -- print("|cffFFAA00ArenaCore:|r Hold Ctrl+Alt while dragging to move frames.")
            return
        end
        
        -- Start moving the anchor (which moves all frames together)
        if AC.ArenaFramesAnchor then
            AC.ArenaFramesAnchor:Show()
            AC.ArenaFramesAnchor:StartMoving()
            AC.isDragging = true
            
            -- Store last position to minimize unnecessary updates
            local lastX, lastY = AC.ArenaFramesAnchor:GetCenter()
            
            -- Get settings once at drag start
            local db = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.positioning
            local spacing = (db and db.spacing)
            if not spacing or spacing == 0 then spacing = 21 end
            local growthDirection = (db and db.growthDirection) or "Down"
            
            -- Minimal OnUpdate - only reposition if anchor actually moved
            AC.ArenaFramesAnchor:SetScript("OnUpdate", function()
                local currentX, currentY = AC.ArenaFramesAnchor:GetCenter()
                if currentX ~= lastX or currentY ~= lastY then
                    lastX, lastY = currentX, currentY
                    
                    for i = 1, 3 do
                        local childFrame = _G["ArenaCoreFrame" .. i]
                        if childFrame and childFrame:IsShown() then
                            local offsetX, offsetY = 0, 0
                            if growthDirection == "Down" then
                                offsetY = -((i-1) * (childFrame:GetHeight() + spacing))
                            elseif growthDirection == "Up" then
                                offsetY = ((i-1) * (childFrame:GetHeight() + spacing))
                            elseif growthDirection == "Right" then
                                offsetX = ((i-1) * (childFrame:GetWidth() + spacing))
                            elseif growthDirection == "Left" then
                                offsetX = -((i-1) * (childFrame:GetWidth() + spacing))
                            end
                            
                            childFrame:ClearAllPoints()
                            childFrame:SetPoint("TOPLEFT", AC.ArenaFramesAnchor, "TOPLEFT", offsetX, offsetY)
                        end
                    end
                end
            end)
            
            -- DEBUG: Dragging frames
            -- print("|cff8B45FFArenaCore:|r Dragging arena frames...")
        end
    end)
    
    frame:SetScript("OnDragStop", function(self)
        if AC.isDragging and AC.ArenaFramesAnchor then
            -- CRITICAL: Set flag FIRST to prevent slider callbacks from overwriting drag position
            AC.justFinishedDragging = true
            
            -- Stop OnUpdate before stopping movement
            AC.ArenaFramesAnchor:SetScript("OnUpdate", nil)
            
            AC.ArenaFramesAnchor:StopMovingOrSizing()
            AC.isDragging = false
            
            -- CRITICAL FIX: Calculate position in BOTTOMLEFT coordinate system
            -- This must match exactly how UpdateFramePositions reads/writes positions
            local point, relativeTo, relativePoint, xOfs, yOfs = AC.ArenaFramesAnchor:GetPoint()
            
            if xOfs and yOfs then
                -- GetPoint returns the exact coordinates we need (unscaled, BOTTOMLEFT-relative)
                local newX = math.floor(xOfs + 0.5)
                local newY = math.floor(yOfs + 0.5)
                
                -- CRITICAL FIX: Save to THEME-SPECIFIC location (same place sliders read from)
                -- This fixes the drag + slider conflict
                if AC.ArenaFrameThemes and AC.DB and AC.DB.profile then
                    local currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
                    if currentTheme then
                        -- Initialize theme data if needed
                        if not AC.DB.profile.themeData then
                            AC.DB.profile.themeData = {}
                        end
                        if not AC.DB.profile.themeData[currentTheme] then
                            AC.DB.profile.themeData[currentTheme] = {}
                        end
                        if not AC.DB.profile.themeData[currentTheme].arenaFrames then
                            AC.DB.profile.themeData[currentTheme].arenaFrames = {}
                        end
                        if not AC.DB.profile.themeData[currentTheme].arenaFrames.positioning then
                            AC.DB.profile.themeData[currentTheme].arenaFrames.positioning = {}
                        end
                        
                        -- Save to theme-specific location (same place UpdateFramePositions reads from)
                        AC.DB.profile.themeData[currentTheme].arenaFrames.positioning.horizontal = newX
                        AC.DB.profile.themeData[currentTheme].arenaFrames.positioning.vertical = newY
                        
                        -- CRITICAL FIX: Update the UI sliders to match the new dragged position
                        -- This prevents the slider from using its old cached value
                        C_Timer.After(0.1, function()
                            if AC.sliderWidgets then
                                local hSlider = AC.sliderWidgets["arenaFrames.positioning.horizontal"]
                                local vSlider = AC.sliderWidgets["arenaFrames.positioning.vertical"]
                                
                                if hSlider then
                                    -- Temporarily disable OnValueChanged to prevent triggering save
                                    local oldScript = hSlider:GetScript("OnValueChanged")
                                    hSlider:SetScript("OnValueChanged", nil)
                                    hSlider:SetValue(newX)
                                    hSlider:SetScript("OnValueChanged", oldScript)
                                end
                                if vSlider then
                                    -- Temporarily disable OnValueChanged to prevent triggering save
                                    local oldScript = vSlider:GetScript("OnValueChanged")
                                    vSlider:SetScript("OnValueChanged", nil)
                                    vSlider:SetValue(newY)
                                    vSlider:SetScript("OnValueChanged", oldScript)
                                end
                            end
                            
                            -- Clear the flag after slider update completes
                            C_Timer.After(0.2, function()
                                AC.justFinishedDragging = false
                            end)
                        end)
                    end
                end
                
                -- ALSO save to global location for compatibility
                if AC.ProfileManager and AC.ProfileManager.SetSetting then
                    AC.ProfileManager:SetSetting("arenaFrames.positioning.horizontal", newX)
                    AC.ProfileManager:SetSetting("arenaFrames.positioning.vertical", newY)
                    
                    -- DEBUG DISABLED FOR PRODUCTION
                    -- print("|cff8B45FFArenaCore:|r Dragged to X:" .. newX .. ", Y:" .. newY)
                    -- print("|cffFFAA00Tip:|r Sliders now adjust from this position (range: ±800px)")
                    
                    -- CRITICAL: Reposition child elements after dragging
                    if AC.Layout then
                        C_Timer.After(0.1, function()
                            if AC.Layout.PositionChildFrames then
                                AC.Layout:PositionChildFrames(self)
                            end
                            if AC.Layout.PositionTrinkets then
                                AC.Layout:PositionTrinkets()
                            end
                            if AC.Layout.PositionRacials then
                                AC.Layout:PositionRacials()
                            end
                            --[[ OLD CAST BAR SYSTEM - DISABLED
                            if AC.Layout.PositionCastBars then
                                AC.Layout:PositionCastBars()
                            end
                            --]]
                            if AC.Layout.PositionDebuffs then
                                AC.Layout:PositionDebuffs()
                            end
                            if AC.Layout.PositionDispelContainers then
                                AC.Layout:PositionDispelContainers(self)
                            end
                            if AC.Layout.PositionDiminishingReturns then
                                AC.Layout:PositionDiminishingReturns()
                            end
                            -- DEBUG: Child elements repositioned
                            -- print("|cff8B45FFArenaCore:|r Child elements repositioned to respect frame parent.")
                        end)
                    end
                else
                    print("|cffFF4444ArenaCore:|r Error: Could not save position!")
                end
            end
        end
    end)
    
    -- Create all visual elements
    self:CreateFrameElements(frame, index)
    
    -- Register events for this frame
    self:RegisterFrameEvents(frame, unit)
    
    -- Store frame in our unified array
    self.frames[index] = frame
    
    -- CRITICAL FIX: Set global AC.arenaFrames reference for backward compatibility
    -- This ensures modules (KickBar, DispelTracker, TrinketsRacials) can find frames
    if not AC.arenaFrames then
        AC.arenaFrames = self.frames
    end
    
    -- Hide initially
    frame:Hide()
    
    return frame
end

function MFM:CreateFrameElements(frame, index)
    -- ========================================================================  
    -- ENHANCED WITH BEAUTIFUL ARENACORE TEXTURES
    -- ========================================================================
    
    -- DEBUG: CreateFrameElements called
    -- print("|cffFF0000[DEBUG]|r CreateFrameElements called for frame " .. index .. " - YOU SHOULD SEE THIS!")
    
    -- ArenaCore texture paths (same as your existing system)
    local A = "Interface\\AddOns\\ArenaCore\\Media\\Textures\\"
    local TEX = {
        frame_bg = A.."frame_background.tga", 
        frame_border = A.."frame_border.tga",
        frame_hover = A.."frame_hover.tga", 
        health_bg = A.."health_bg.tga", 
        health_border = A.."health_border.tga",
        health_fill = A.."health_fill.tga", 
        mana_bg = A.."mana_bg.tga",
        mana_border = A.."mana_border.tga", 
        mana_fill = A.."mana_fill.tga",
        cast_bg = A.."cast_bg.tga", 
        cast_fill = A.."cast_fill.tga"
    }
    
    -- NOTE: AC.FONT_PATH is now set at the top of the file (line 15) for early access
    
    -- Frame Background (BEAUTIFUL TEXTURE instead of solid color)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetTexture(TEX.frame_bg)
    frame.bg:SetTexCoord(0, 1, 0, 1) -- Full texture for proper edges
    
    -- Frame Border (BEAUTIFUL TEXTURE)
    frame.border = frame:CreateTexture(nil, "BORDER")
    frame.border:SetAllPoints()
    frame.border:SetTexture(TEX.frame_border)
    frame.border:SetTexCoord(0, 1, 0, 1) -- Full texture for proper edges
    
    -- Get bar sizes from database to avoid resize issues
    local texDb = AC.DB and AC.DB.profile and AC.DB.profile.textures
    local healthWidth = (texDb and texDb.sizing and texDb.sizing.healthWidth) or 128
    local healthHeight = (texDb and texDb.sizing and texDb.sizing.healthHeight) or 18
    -- DEBUG: Initial healthWidth
    -- print("|cffFF00FF[BAR SIZE DEBUG]|r Frame " .. index .. " - Initial healthWidth: " .. healthWidth .. " (from DB: " .. tostring(texDb and texDb.sizing and texDb.sizing.healthWidth) .. ")")
    
    -- Health Bar Container
    frame.healthBarContainer = CreateFrame("Frame", nil, frame)
    frame.healthBarContainer:SetSize(healthWidth, healthHeight + 17) -- Extra height for padding
    frame.healthBarContainer:SetPoint("TOP", frame, "TOP", 0, -5)
    
    -- Health Bar (BEAUTIFUL STYLING)
    frame.healthBar = CreateFrame("StatusBar", nil, frame.healthBarContainer)
    frame.healthBar:SetSize(healthWidth, healthHeight) -- Use database size, not SetAllPoints
    frame.healthBar:SetPoint("CENTER", frame.healthBarContainer, "CENTER", 0, 0) -- Center in container
    -- Use custom ArenaCore health texture (straight edges, not rounded)
    local healthTexturePath = TEX.health_fill
    -- DEBUG: Health texture path
    -- print("|cffFF0000[TEXTURE DEBUG]|r Health texture path: " .. tostring(healthTexturePath))
    
    -- Try multiple methods to ensure texture loads
    frame.healthBar:SetStatusBarTexture(healthTexturePath)
    
    -- Alternative method if first doesn't work
    local healthBarTexture = frame.healthBar:GetStatusBarTexture()
    if healthBarTexture then
        healthBarTexture:SetTexture(healthTexturePath)
        healthBarTexture:SetTexCoord(0, 1, 0, 1)
        healthBarTexture:SetHorizTile(false)
        healthBarTexture:SetVertTile(false)
        -- DEBUG: Health bar texture applied
        -- print("|cffFF0000[TEXTURE DEBUG]|r Health bar texture applied directly")
        
        -- Test if texture actually loaded by trying fallback
        C_Timer.After(0.1, function()
            local textureFileID = healthBarTexture:GetTexture()
            if not textureFileID or textureFileID == 0 then
                -- DEBUG: Texture failed, using fallback
                -- print("|cffFF0000[TEXTURE ERROR]|r Health texture failed to load, trying fallback")
                healthBarTexture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
            else
                -- DEBUG: Texture loaded successfully
                -- print("|cffFF0000[TEXTURE SUCCESS]|r Health texture loaded with ID: " .. tostring(textureFileID))
            end
        end)
    end
    
    frame.healthBar:SetMinMaxValues(0, 100)
    frame.healthBar:SetValue(100)
    frame.healthBar:SetStatusBarColor(0, 1, 0)  -- Green color to make texture visible
    
    -- Health Bar Background (BEAUTIFUL TEXTURE - confirmed to exist)
    local healthBg = frame.healthBar:CreateTexture(nil, "BACKGROUND")
    healthBg:SetAllPoints()
    healthBg:SetTexture(TEX.health_bg)
    healthBg:SetTexCoord(0, 1, 0, 1)
    -- CRITICAL FIX: Set background to dark color (missing health color)
    -- Default WoW uses dark gray/black for missing health, never white
    healthBg:SetVertexColor(0.3, 0.3, 0.3, 1) -- Dark gray background
    frame.healthBar.bg = healthBg -- Store reference for potential updates
    
    -- Health Bar Border (BEAUTIFUL TEXTURE - confirmed to exist)
    local healthBorder = frame.healthBar:CreateTexture(nil, "BORDER")
    healthBorder:SetAllPoints()
    healthBorder:SetTexture(TEX.health_border)
    healthBorder:SetTexCoord(0, 1, 0, 1)
    
    -- Health Bar Text (BEAUTIFUL FONT)
    frame.healthBar.text = frame.healthBar:CreateFontString(nil, "OVERLAY")
    if AC.SafeSetFont then
        AC.SafeSetFont(frame.healthBar.text, AC.FONT_PATH, 12, "OUTLINE")
    else
        frame.healthBar.text:SetFont("Fonts\\\\FRIZQT__.TTF", 12, "OUTLINE")
    end
    frame.healthBar.text:SetPoint("CENTER", frame.healthBar, "CENTER", 0, 0)
    frame.healthBar.text:SetTextColor(1, 1, 1)
    frame.healthBar.text:SetText("100%")
    
    -- CRITICAL FIX: Create alias for compatibility with test mode code
    frame.healthBar.statusText = frame.healthBar.text
    
    -- Get mana bar sizes from database
    local resourceWidth = (texDb and texDb.sizing and texDb.sizing.resourceWidth) or 136
    local resourceHeight = (texDb and texDb.sizing and texDb.sizing.resourceHeight) or 8
    
    -- Mana Bar Container
    frame.manaBarContainer = CreateFrame("Frame", nil, frame)
    frame.manaBarContainer:SetSize(resourceWidth, resourceHeight + 7) -- Extra height for padding
    frame.manaBarContainer:SetPoint("TOP", frame.healthBarContainer, "BOTTOM", 0, -2)
    
    -- Mana Bar (BEAUTIFUL STYLING)
    frame.manaBar = CreateFrame("StatusBar", nil, frame.manaBarContainer)
    frame.manaBar:SetSize(resourceWidth, resourceHeight) -- Use database size, not SetAllPoints
    frame.manaBar:SetPoint("CENTER", frame.manaBarContainer, "CENTER", 0, 0) -- Center in container
    -- Use custom ArenaCore mana texture (straight edges, not rounded)
    local manaTexturePath = TEX.mana_fill
    -- DEBUG: Mana texture path
    -- print("|cffFF0000[TEXTURE DEBUG]|r Mana texture path: " .. tostring(manaTexturePath))
    
    -- Try multiple methods to ensure texture loads
    frame.manaBar:SetStatusBarTexture(manaTexturePath)
    
    -- Alternative method if first doesn't work
    local manaBarTexture = frame.manaBar:GetStatusBarTexture()
    if manaBarTexture then
        manaBarTexture:SetTexture(manaTexturePath)
        manaBarTexture:SetTexCoord(0, 1, 0, 1)
        manaBarTexture:SetHorizTile(false)
        manaBarTexture:SetVertTile(false)
        -- DEBUG: Mana bar texture applied
        -- print("|cffFF0000[TEXTURE DEBUG]|r Mana bar texture applied directly")
    end
    
    -- CRITICAL FIX: Don't hardcode blue - color will be set by power type system
    -- frame.manaBar:SetStatusBarColor(0, 0.5, 1)  -- REMOVED: This was overriding class colors
    frame.manaBar:SetMinMaxValues(0, 100)
    frame.manaBar:SetValue(100)
    
    -- Mana Bar Background (BEAUTIFUL TEXTURE - confirmed to exist)
    local manaBg = frame.manaBar:CreateTexture(nil, "BACKGROUND")
    manaBg:SetAllPoints()
    manaBg:SetTexture(TEX.mana_bg)
    manaBg:SetTexCoord(0, 1, 0, 1)
    
    -- Mana Bar Border (BEAUTIFUL TEXTURE - confirmed to exist)
    local manaBorder = frame.manaBar:CreateTexture(nil, "BORDER")
    manaBorder:SetAllPoints()
    manaBorder:SetTexture(TEX.mana_border)
    manaBorder:SetTexCoord(0, 1, 0, 1)
    
    -- Mana Bar Text (BEAUTIFUL FONT)
    frame.manaBar.text = frame.manaBar:CreateFontString(nil, "OVERLAY")
    if AC.SafeSetFont then
        AC.SafeSetFont(frame.manaBar.text, AC.FONT_PATH, 10, "OUTLINE")
    else
        frame.manaBar.text:SetFont("Fonts\\\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    frame.manaBar.text:SetPoint("CENTER", frame.manaBar, "CENTER", 0, 0)
    frame.manaBar.text:SetTextColor(1, 1, 1)
    frame.manaBar.text:SetText("100%")
    
    -- CRITICAL FIX: Create alias for compatibility with test mode code
    frame.manaBar.statusText = frame.manaBar.text
    
    -- ========================================================================
    -- ABSORB BAR CREATION (Delegated to Absorbs module)
    -- ========================================================================
    if AC.Absorbs and AC.Absorbs.CreateAbsorbElements then
        AC.Absorbs:CreateAbsorbElements(frame)
    end
    
    -- ========================================================================
    -- FIXED: Create invisible overlay frame to hold text (above absorb shields)
    frame.textOverlayFrame = CreateFrame("Frame", nil, frame)
    frame.textOverlayFrame:SetAllPoints(frame)
    frame.textOverlayFrame:SetFrameStrata("MEDIUM") -- CRITICAL: Use MEDIUM to stay below bags/tooltips
    frame.textOverlayFrame:SetFrameLevel(150) -- High within MEDIUM, above absorb shields (which use 100)
    
    -- Move .text (ArenaCore.lua uses .text, not .statusText) to the high-strata overlay frame
    if frame.healthBar.text then
        frame.healthBar.text:SetParent(frame.textOverlayFrame)
        frame.healthBar.text:SetDrawLayer("OVERLAY", 7)
        -- CRITICAL: Re-anchor after changing parent to ensure proper positioning
        frame.healthBar.text:ClearAllPoints()
        frame.healthBar.text:SetPoint("CENTER", frame.healthBar, "CENTER", 0, 0)
        frame.healthBar.text:SetAlpha(1.0) -- Ensure full opacity
    end
    if frame.manaBar and frame.manaBar.text then
        frame.manaBar.text:SetParent(frame.textOverlayFrame)
        frame.manaBar.text:SetDrawLayer("OVERLAY", 7)
        -- CRITICAL: Re-anchor after changing parent to ensure proper positioning
        frame.manaBar.text:ClearAllPoints()
        frame.manaBar.text:SetPoint("CENTER", frame.manaBar, "CENTER", 0, 0)
        frame.manaBar.text:SetAlpha(1.0) -- Ensure full opacity
    end
    
    -- Absorb bar created
    -- ========================================================================
    
    -- Player Name (BEAUTIFUL FONT) - Anchor to frame (not health bar) for independent positioning
    frame.playerName = frame:CreateFontString(nil, "OVERLAY")
    if AC.SafeSetFont then
        AC.SafeSetFont(frame.playerName, AC.FONT_PATH, 12, "OUTLINE")
    else
        frame.playerName:SetFont("Fonts\\\\FRIZQT__.TTF", 12, "OUTLINE")
    end
    -- NOTE: Position will be set at end of CreateArenaFrame after healthBar exists
    frame.playerName:SetTextColor(1, 1, 1)
    -- ARCHITECTURAL FIX: Use unified text control system
    AC:SetArenaFrameText(frame, index, "live_arena")
    
    -- Arena Number (BEAUTIFUL FONT)
    -- CRITICAL FIX: Create separate frame with HIGH strata so number shows above all UI elements
    frame.arenaNumberFrame = CreateFrame("Frame", nil, frame)
    frame.arenaNumberFrame:SetFrameStrata("HIGH")  -- Higher than MEDIUM (main frame)
    frame.arenaNumberFrame:SetFrameLevel(100)  -- Very high level to ensure visibility
    frame.arenaNumberFrame:SetSize(50, 50)  -- Size for the container frame
    
    -- Initialize position tracking
    frame.arenaNumberFrame._lastX = nil
    frame.arenaNumberFrame._lastY = nil
    frame.arenaNumberFrame._lastScale = 1.0
    
    frame.arenaNumber = frame.arenaNumberFrame:CreateFontString(nil, "OVERLAY")
    if AC.SafeSetFont then
        AC.SafeSetFont(frame.arenaNumber, AC.FONT_PATH, 16, "OUTLINE")
    else
        frame.arenaNumber:SetFont("Fonts\\\\FRIZQT__.TTF", 16, "OUTLINE")
    end
    frame.arenaNumber:SetPoint("CENTER", frame.arenaNumberFrame, "CENTER", 0, 0)
    frame.arenaNumber:SetText(index)
    frame.arenaNumber:SetTextColor(1, 0.82, 0)  -- Gold color
    
    -- Class Icon (same structure, no texture changes needed)
    frame.classIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.classIcon:SetSize(32, 32)
    frame.classIcon:SetPoint("LEFT", frame, "RIGHT", 5, 0)
    -- CRITICAL: Set texture filtering to prevent distortion when scaled
    -- Using TRILINEAR filtering (true, true) for smooth scaling without blur
    frame.classIcon.SetTexture = function(self, texture, ...)
        getmetatable(self).__index.SetTexture(self, texture, true, true)
    end
    frame.classIcon:Hide()  -- Hidden until we have class data
    
    -- Cast bars handled by modules/CastBars.lua
    -- Uses Blizzard's CastingBarFrame directly in Midnight
    
    -- MISSING CRITICAL COMPONENTS: Add proper class icon creation
    local testClasses = {"Deathknight", "Mage", "Hunter"} -- Match your test setup
    local testClass = testClasses[index]
    frame.classIcon = self:CreateClassIcon(frame, testClass)
    
    -- MISSING CRITICAL COMPONENTS: Add trinket and racial with proper styling
    frame.trinketIndicator = self:CreateTrinket(frame)
    
    -- PHASE 3: Use TrinketsRacials module for racial creation (centralized logic)
    if AC.TrinketsRacials and AC.TrinketsRacials.CreateRacialIndicator then
        frame.racialIndicator = AC.TrinketsRacials:CreateRacialIndicator(frame, index)
    end
    -- No fallback - module must be loaded for racials to work
    
    -- MISSING CRITICAL COMPONENTS: Add spec icon (bottom-left small icon)
    frame.specIcon = self:CreateSpecIcon(frame, testClass)
    
    -- ARCHITECTURAL FIX: Use unified text control system
    AC:SetArenaFrameText(frame, index, "test_mode")
    
    -- CRITICAL: Create DR (Diminishing Returns) icons for frame via module
    local drModule = GetDRModule()
    if drModule and drModule.EnsureFrame then
        drModule:EnsureFrame(frame)
    end
    
    -- DEBUFF SYSTEM INTEGRATION: Create debuff container for enemy aura tracking
    local debuffModule = GetDebuffModule()
    if debuffModule and debuffModule.EnsureContainer then
        frame.debuffContainer = debuffModule:EnsureContainer(frame)
    else
        frame.debuffContainer = self:CreateDebuffContainer(frame)
    end

    -- DISPEL SYSTEM INTEGRATION
    local dispelModule = GetDispelModule()
    if dispelModule and dispelModule.EnsureFrame then
        dispelModule:EnsureFrame(frame)
    end
    
    -- CRITICAL FIX: TRINKETS & RACIALS MODULE ATTACHMENT
    -- This is what makes trinkets and racials actually track cooldowns!
    if AC.TrinketsRacials and AC.TrinketsRacials.Attach then
        AC.TrinketsRacials:Attach(frame, unit)
    end
    
    -- CRITICAL FIX: TRIBADGES (CLASS PACKS) ATTACHMENT - Attach TriBadges to frame
    -- This is what makes the "Enable Class Packs" checkbox actually work!
    if _G.ArenaCore and _G.ArenaCore.TriBadges and _G.ArenaCore.TriBadges.Attach then
        C_Timer.After(0.1, function()
            -- Use frame.unit since 'unit' local variable is out of scope in this closure
            _G.ArenaCore.TriBadges:Attach(frame, frame.unit)
            -- DEBUG: TriBadges attached
            -- print("|cff00FF00[TRIBADGES]|r Attached to frame " .. index .. " (" .. frame.unit .. ")")
        end)
    end
    
    -- TARGET HIGHLIGHT SYSTEM: Create target outline texture
    if AC.TargetHighlight and AC.TargetHighlight.CreateOutline then
        AC.TargetHighlight:CreateOutline(frame)
    end
    
    -- DEATH ICON SYSTEM: Create death skull overlay (shows when enemy dies)
    -- CRITICAL: Use HIGH strata to appear above arena frames but BELOW scoreboard
    -- TOOLTIP strata was causing death icon to leak over end-of-match scoreboard
    -- Strata hierarchy: MEDIUM (arena frames) < HIGH (death icon) < FULLSCREEN_DIALOG (scoreboard)
    frame.deathIconFrame = CreateFrame("Frame", nil, frame)
    frame.deathIconFrame:SetFrameStrata("HIGH")  -- High enough for arena frames, below scoreboard
    frame.deathIconFrame:SetFrameLevel(1000)  -- Maximum frame level within HIGH strata
    frame.deathIconFrame:SetSize(70, 70)
    -- Position slightly lower for better visibility (8px down from center)
    frame.deathIconFrame:SetPoint("CENTER", frame.healthBar, "CENTER", 0, -8)
    
    -- Create texture on the high-strata frame
    frame.deathIcon = frame.deathIconFrame:CreateTexture(nil, "ARTWORK")
    frame.deathIcon:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Textures\\ArenaCoreDead.png")
    frame.deathIcon:SetAllPoints(frame.deathIconFrame)
    
    frame.deathIconFrame:Hide() -- Hidden by default, shown when enemy dies
    
    -- CRITICAL FIX: Anchor player name to FRAME (not healthBar) for independent positioning
    if frame.playerName then
        local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
        if general then
            -- CRITICAL FIX: Use proper nil check - 0 is a valid value!
            local nameX = (general.playerNameX ~= nil) and general.playerNameX or 52
            local nameY = (general.playerNameY ~= nil) and general.playerNameY or 0
            frame.playerName:ClearAllPoints()
            
            -- CRITICAL: Check if theme has moved playerName to an overlay
            local parent = frame.playerName:GetParent()
            if parent and parent ~= frame then
                -- PlayerName is in a theme overlay
                frame.playerName:SetPoint("TOPLEFT", parent, "TOPLEFT", nameX, nameY)
            else
                -- Normal case - anchor to frame, not healthBar, so it doesn't move when bars move
                frame.playerName:SetPoint("TOPLEFT", frame, "TOPLEFT", nameX, nameY)
            end
        end
    end
    
    -- DEBUG: Frame created with styling
    -- print("|cffFFAA00ArenaCore Master:|r Frame " .. index .. " created with BEAUTIFUL STYLING! 🎨")
end

-- ============================================================================
-- MISSING CRITICAL VISUAL COMPONENT CREATORS
-- ============================================================================

function MFM:CreateClassIcon(parent, class)
    -- Create class icon frame with HIGH strata to show above health/mana bars
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(36, 36)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetFrameStrata("MEDIUM") -- CRITICAL: Use MEDIUM to stay below bags
    icon:SetFrameLevel(50) -- High level within MEDIUM strata to appear above health/mana bars
    
    -- CRITICAL: Prevent any automatic styling systems
    icon.preventStyling = true
    
    -- Create class icon texture - will show above bars due to HIGH strata
    local classIcon = icon:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(28, 28)
    classIcon:SetPoint("CENTER")
    
    -- Create overlay for your custom borders - HIGHEST priority
    local overlay = icon:CreateTexture(nil, "OVERLAY")
    overlay:SetAllPoints(icon) -- Use full frame size for detailed borders
    overlay:SetTexCoord(0, 1, 0, 1) -- NO CROPPING - preserve full overlay detail
    
    -- Function to update overlay size/insets based on borderThickness setting
    -- This physically shrinks the overlay inward to make borders thinner
    local function UpdateOverlayThickness()
        -- Get border thickness percentage from THEME-SPECIFIC settings (80-100%, default 100%)
        -- 100% = full border thickness (default appearance)
        -- 80% = thinner borders (overlay scaled inward)
        local thicknessPercent = 100
        
        -- CRITICAL: Read from theme-specific settings for per-theme isolation
        if AC and AC.DB and AC.DB.profile then
            local currentTheme = AC.ArenaFrameThemes and AC.ArenaFrameThemes:GetCurrentTheme()
            local themeData = currentTheme and AC.DB.profile.themeData and AC.DB.profile.themeData[currentTheme]
            
            -- Try theme-specific settings first
            if themeData and themeData.classIcons and themeData.classIcons.sizing and themeData.classIcons.sizing.borderThickness then
                thicknessPercent = themeData.classIcons.sizing.borderThickness
            -- Fallback to global settings if theme-specific don't exist
            elseif AC.DB.profile.classIcons and AC.DB.profile.classIcons.sizing and AC.DB.profile.classIcons.sizing.borderThickness then
                thicknessPercent = AC.DB.profile.classIcons.sizing.borderThickness
            end
        end
        
        -- CRITICAL: Calculate inset based on CURRENT icon size (accounts for scaling)
        -- This ensures the inset scales proportionally with the icon
        local iconWidth, iconHeight = icon:GetSize()
        local currentScale = icon:GetScale()
        local effectiveSize = math.min(iconWidth, iconHeight) * currentScale
        
        -- Calculate inset amount based on percentage AND current size
        -- 100% = 0 inset (full size overlay)
        -- 80% = maximum inset (overlay shrunk inward, making borders thinner)
        -- Use a smaller percentage for better scaling at high sizes
        local insetPercent = ((100 - thicknessPercent) / 20) * 0.05 -- 0% to 5%
        local inset = effectiveSize * insetPercent
        
        -- CRITICAL: Cap maximum inset to prevent breaking at very high scales
        -- Maximum 4 pixels regardless of scale to maintain overlay integrity
        inset = math.min(inset, 4)
        
        -- Apply insets to shrink overlay inward
        -- Positive insets move the edges inward, making the overlay smaller
        overlay:ClearAllPoints()
        overlay:SetPoint("TOPLEFT", icon, "TOPLEFT", inset, -inset)
        overlay:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -inset, inset)
    end
    
    -- Apply initial overlay thickness
    UpdateOverlayThickness()
    
    -- Dynamic class detection for arena/open world
    local function UpdateClassIcon(overrideClass)
        local detectedClass = overrideClass or class
        
        -- If no class provided, try to detect from unit
        if not detectedClass or detectedClass == "" then
            if parent.unit then
                local unitClass = UnitClass(parent.unit)
                if unitClass then
                    detectedClass = unitClass:upper()
                end
            end
        end
        
        -- CRITICAL FIX: Ensure detectedClass is uppercase for consistency
        if detectedClass then
            detectedClass = detectedClass:upper()
        end
        
        -- Set textures based on detected class
        if detectedClass and detectedClass ~= "" then
            -- Get theme setting from database
            local db = AC.DB and AC.DB.profile
            local theme = db and db.classIcons and db.classIcons.theme or "arenacore"
            
            local iconPath
            if theme == "coldclasses" then
                -- Use WoW Default Style+Midnight Chill texture (ColdClasses folder)
                iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\" .. detectedClass:lower() .. ".png"
            else
                -- Use ArenaCore Custom (default)
                iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\" .. detectedClass .. ".tga"
            end
            classIcon:SetTexture(iconPath, true, true) -- TRILINEAR filtering for smooth scaling
            
            local overlayPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\" .. detectedClass:lower() .. "overlay.tga"
            overlay:SetTexture(overlayPath, true, true) -- TRILINEAR filtering for smooth scaling
            
            -- CRITICAL FIX: Apply class-specific texture coordinate adjustments AFTER setting texture
            -- This ensures coordinates are applied every time the class icon is updated
            if detectedClass == "DEATHKNIGHT" then
                classIcon:SetTexCoord(0.02, 0.98, 0.02, 0.98) -- Much tighter crop for Death Knight
            elseif detectedClass == "WARRIOR" then
                classIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Standard crop (same as other classes)
            else
                classIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Standard crop for other classes
            end
        else
            -- Fallback for test mode or unknown class
            classIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            classIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Standard crop for fallback
            overlay:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\orangeoverlay.tga")
        end
    end
    
    -- Initial update
    UpdateClassIcon()
    
    -- DEBUG DISABLED FOR PRODUCTION
    
    -- Function to update border thickness when settings change
    local function UpdateBorderThickness()
        -- Call UpdateOverlayThickness to physically shrink/expand the overlay
        UpdateOverlayThickness()
    end
    
    -- Store references (maintain compatibility with both old and new systems)
    icon.classIcon = classIcon -- New system reference
    icon.icon = classIcon -- Old system reference for compatibility
    icon.overlay = overlay
    icon.UpdateClassIcon = UpdateClassIcon -- Allow external updates
    icon.UpdateBorderThickness = UpdateBorderThickness -- Allow border thickness updates
    
    return icon
end

function MFM:CreateTrinket(parent)
    -- MIDNIGHT-ONLY: Create visual indicator only
    -- Blizzard frame hooking is handled by TrinketsRacials module when arena starts
    -- (Blizzard frames don't exist at addon load time)
    
    local t = CreateFrame("Frame", nil, parent)
    t:SetSize(20, 20)
    t:SetPoint("TOPRIGHT", -6, -6)
    t:SetFrameStrata("MEDIUM")
    t:SetFrameLevel(50)
    
    -- Trinket icon texture
    local icon = t:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- Orange overlay border
    local br = t:CreateTexture(nil, "OVERLAY")
    br:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
    br:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    br:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\orangeoverlay.tga")
    br:SetTexCoord(0, 1, 0, 1)
    
    -- Set initial trinket icon
    local trinketTexture = GetTrinketIcon()
    icon:SetTexture(trinketTexture)
    
    -- Create cooldown frame
    local cd = AC:CreateCooldown(t, nil, "CooldownFrameTemplate")
    cd:SetAllPoints(icon)
    cd:SetDrawBling(false)
    cd:SetHideCountdownNumbers(true)
    
    -- Create cooldown text
    local txt = cd:CreateFontString(nil, "OVERLAY")
    local trinketSettings = AC.DB and AC.DB.profile and AC.DB.profile.trinkets
    local fontSize = trinketSettings and trinketSettings.sizing and trinketSettings.sizing.fontSize or 12
    txt:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", fontSize, "OUTLINE")
    txt:SetPoint("CENTER", t, "CENTER", 0, 0)
    txt:SetTextColor(1, 1, 1, 1)
    txt:SetJustifyH("CENTER")
    txt:SetJustifyV("MIDDLE")
    txt:Show()
    cd.Text = txt
    
    -- Store references (consistent naming for TrinketsRacials module)
    t.icon = icon
    t.texture = icon
    t.border = br
    t.cooldown = cd
    t.txt = txt
    t.text = txt
    
    return t
end

-- PHASE 3: REMOVED - Racial creation now handled by TrinketsRacials module
-- Use AC.TrinketsRacials:CreateRacialIndicator() instead

function MFM:CreateSpecIcon(parent, class)
    -- Create spec icon frame (small icon in bottom-left)
    local specIcon = CreateFrame("Frame", nil, parent)
    specIcon:SetSize(20, 20)
    specIcon:SetPoint("BOTTOMLEFT", 5, 5) -- Bottom-left corner positioning
    specIcon:SetFrameStrata("MEDIUM") -- CRITICAL: Use MEDIUM to stay below bags
    specIcon:SetFrameLevel(60) -- High level within MEDIUM strata
    
    -- Spec icon texture
    local icon = specIcon:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- CRITICAL: Override SetTexture to apply TRILINEAR filtering for smooth scaling
    -- This prevents pixelation when spec icons are scaled up beyond base size
    icon.SetTexture = function(self, texture, ...)
        getmetatable(self).__index.SetTexture(self, texture, true, true)
    end
    
    -- Class-specific spec icons for test mode
    local classSpecs = {
        ["Deathknight"] = {
            name = "Unholy",
            icon = "Interface\\Icons\\Spell_Deathknight_UnholyPresence"
        },
        ["Mage"] = {
            name = "Fire",
            icon = "Interface\\Icons\\Spell_Fire_FlameBolt"
        },
        ["Hunter"] = {
            name = "Marksmanship",
            icon = "Interface\\Icons\\Ability_Hunter_FocusedAim"
        }
    }
    
    -- Set spec icon based on class
    local specInfo = classSpecs[class] or classSpecs["Deathknight"]
    icon:SetTexture(specInfo.icon)
    
    -- Apply ArenaCore's proper black border styling
    if AC and AC.StyleIcon then
        AC:StyleIcon(icon, specIcon, true)
    end
    
    -- Store references
    specIcon.icon = icon
    specIcon.specName = specInfo.name
    
    return specIcon
end

function MFM:CreateDebuffContainer(parent)
    -- Create debuff container matching ArenaTracking.lua system
    local c = CreateFrame("Frame", nil, parent)
    c:SetSize(220, 24)
    
    -- Apply user positioning settings
    local debuffSettings = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.debuffs
    local horizontal = debuffSettings and debuffSettings.positioning and debuffSettings.positioning.horizontal or 8
    local vertical = debuffSettings and debuffSettings.positioning and debuffSettings.positioning.vertical or 6
    
    c:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", horizontal, vertical)
    c:SetFrameStrata("MEDIUM") -- CRITICAL: Use MEDIUM to stay below bags
    c:SetFrameLevel(40) -- Above health bars, below trinkets/racials within MEDIUM strata
    c.debuffs = {}
    c:Hide() -- Hidden by default, shown when debuffs detected
    return c
end



function MFM:RegisterFrameEvents(frame, unit)
    -- Set up individual frame event handling
    frame:SetScript("OnEvent", function(self, event, eventUnit, ...)
        -- Only process events for our unit
        if eventUnit and eventUnit ~= unit then return end
        
        MFM:HandleFrameEvent(self, event, eventUnit, ...)
    end)
    
    -- Register unit-specific events (PROVEN TO WORK!)
    frame:RegisterUnitEvent("UNIT_HEALTH", unit)
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    frame:RegisterUnitEvent("UNIT_POWER_UPDATE", unit)
    frame:RegisterUnitEvent("UNIT_MAXPOWER", unit)
    frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
    
    -- REMOVED: Cast bar events now handled by ArenaTracking (lines 9320-9325)
    -- Duplicate registration was causing events to fire twice per spell cast
    -- frame:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
    -- frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
    -- frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
    -- frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
    -- frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
    -- frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
    -- frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", unit)
    -- frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", unit)
    
    -- CRITICAL FIX: Absorb and Aura events for real-time tracking
    frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)
    frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unit)
    frame:RegisterUnitEvent("UNIT_AURA", unit)
    
    -- REMOVED: MFM event frame handles this globally (line 2660)
    -- Duplicate registration was causing prep room event to fire 4 times
    -- frame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    
    -- DEBUG: Events registered
    -- print("|cffFFAA00ArenaCore Master:|r Events registered for frame " .. frame.id)
end

function MFM:HandleFrameEvent(frame, event, eventUnit, ...)
    -- Handle events based on current state
    if self.isTestMode then
        -- Test mode - ignore real events
        return
    end
    
    local unit = frame.unit
    
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        self:UpdateHealth(frame)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        self:UpdatePower(frame)
    elseif event == "UNIT_NAME_UPDATE" then
        self:UpdateName(frame)
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        self:HandlePrepRoom(frame)
    --[[ OLD CAST BAR SYSTEM - DISABLED
    elseif event:match("^UNIT_SPELLCAST") then
        -- Cast bar events need unit parameter
        self:UpdateCastBar(frame, frame.unit, event)
    --]]
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
        -- CRITICAL FIX: Update absorb bars when shields change
        if AC.Absorbs and AC.Absorbs.UpdateAbsorbBar then
            AC.Absorbs:UpdateAbsorbBar(frame)
        end
    elseif event == "UNIT_AURA" then
        -- CRITICAL FIX: Update absorbs and immunities on aura changes
        if AC.Absorbs and AC.Absorbs.UpdateAbsorbBar then
            AC.Absorbs:UpdateAbsorbBar(frame)
        end
        if AC.ImmunityTracker and AC.ImmunityTracker.UpdateImmunityGlow then
            AC.ImmunityTracker:UpdateImmunityGlow(frame, unit)
        end
    end
end

-- Update health bar
function MFM:UpdateHealth(frame)
    if not frame or not frame.healthBar then return end
    
    local unit = frame.unit
    if not unit or not UnitExists(unit) then return end
    
    -- CRITICAL: StatusBar:SetValue() and SetMinMaxValues() accept secret values (protected operations)
    -- We only need percentage conversion for TEXT display, not bar values
    local health, maxHealth, healthPercent
    if AC.Midnight and AC.Midnight.isMidnight then
        -- Midnight: Both SetMinMaxValues and SetValue accept secret values
        frame.healthBar:SetMinMaxValues(0, UnitHealthMax(unit))
        frame.healthBar:SetValue(UnitHealth(unit))
        -- For text display later, we'll use UnitHealthPercent with CurveConstants.ScaleTo100
    else
        -- Non-Midnight: Use standard health APIs
        health = UnitHealth(unit)
        maxHealth = UnitHealthMax(unit)
        frame.healthBar:SetMinMaxValues(0, maxHealth)
        frame.healthBar:SetValue(health)
    end
    
    -- CRITICAL FIX: Check if unit is feigning death - preserve dimmed alpha
    local isFeigning = frame.__isFeign
    
    -- CRITICAL FIX: Only update health bar color if NOT feigning
    -- This prevents overriding feign death visual states
    if not isFeigning then
        -- CRITICAL: Update health bar color based on class (fix for green bar bug)
        local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
        local useClassColors = general and general.useClassColors ~= false
        
        if useClassColors then
            local _, classFile = UnitClass(unit)
            if classFile and RAID_CLASS_COLORS[classFile] then
                local classColor = RAID_CLASS_COLORS[classFile]
                frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
            else
                -- Fallback to green if class not detected
                frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
            end
        else
            -- Use default green when class colors are disabled
            frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
        end
    end
    
    -- Update health text if it exists
    if frame.healthBar.text then
        local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
        local statusTextEnabled = general and general.statusText ~= false
        
        if statusTextEnabled then
            -- Midnight compatibility: Use percentage directly if available
            if AC.Midnight and AC.Midnight.isMidnight then
                if healthPercent and type(healthPercent) == "number" and healthPercent >= 0 and healthPercent <= 100 then
                    frame.healthBar.text:SetText(math.floor(healthPercent) .. "%")
                    frame.healthBar.text:Show()
                end
            else
                -- Non-Midnight: Calculate percentage
                local percent = (maxHealth and maxHealth > 0) and math.floor((health / maxHealth) * 100) or 0
                frame.healthBar.text:SetText(percent .. "%")
                frame.healthBar.text:Show()
            end
        else
            frame.healthBar.text:Hide()
        end
    end
    
    -- CRITICAL FIX: Restore feign death alpha if unit is feigning
    -- This ensures health updates don't override the dimmed state
    if isFeigning and frame.healthBar then
        frame.healthBar:SetAlpha(0.4)
    end
    
    -- Update absorb bars
    if AC.Absorbs and AC.Absorbs.UpdateAbsorbBar then
        AC.Absorbs:UpdateAbsorbBar(frame)
    end
    
    -- Update immunity glow
    if AC.ImmunityTracker and AC.ImmunityTracker.UpdateImmunityGlow then
        AC.ImmunityTracker:UpdateImmunityGlow(frame, frame.unit)
    end
end

-- Update power/mana bar
function MFM:UpdatePower(frame)
    if not frame or not frame.manaBar then return end
    
    local unit = frame.unit
    if not unit or not UnitExists(unit) then return end
    
    -- Midnight compatibility: Use protected power API calls
    if AC.Midnight and AC.Midnight.isMidnight then
        -- CRITICAL: StatusBar:SetValue() and SetMinMaxValues() accept secret values
        frame.manaBar:SetMinMaxValues(0, UnitPowerMax(unit))
        frame.manaBar:SetValue(UnitPower(unit))
    else
        -- Traditional power calculation for non-Midnight
        local power = UnitPower(unit)
        local maxPower = UnitPowerMax(unit)
        
        frame.manaBar:SetMinMaxValues(0, maxPower)
        frame.manaBar:SetValue(power)
    end
    
    -- Update power text if it exists
    if frame.manaBar.text then
        local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
        local statusTextEnabled = general and general.statusText ~= false
        
        if AC.Midnight and AC.Midnight.isMidnight then
            -- CRITICAL: Disable mana text in Midnight due to UnitPowerPercent API bug
            frame.manaBar.text:Hide()
        else
            -- CRITICAL FIX: Hide text in prep room when unit doesn't exist yet
            if not UnitExists(unit) then
                frame.manaBar.text:Hide()
            elseif statusTextEnabled then
                local power = UnitPower(unit)
                local maxPower = UnitPowerMax(unit)
                if maxPower and maxPower > 0 and power and power >= 0 then
                    local powerPercent = math.floor((power / maxPower) * 100)
                    frame.manaBar.text:SetText(powerPercent .. "%")
                else
                    frame.manaBar.text:SetText("")
                end
                frame.manaBar.text:Show()
            else
                frame.manaBar.text:Hide()
            end
        end
    end
    
    -- CRITICAL FIX: Restore feign death alpha if unit is feigning
    -- This ensures power updates don't override the dimmed state
    local isFeigning = frame.__isFeign
    if isFeigning and frame.manaBar then
        frame.manaBar:SetAlpha(0.4)
    end
end

-- Update player name
function MFM:UpdateName(frame)
    if not frame or not frame.playerName then return end
    
    -- CRITICAL FIX: Don't override test mode names
    if AC.testModeEnabled then return end
    
    local unit = frame.unit
    if not unit or not UnitExists(unit) then return end
    
    -- CRITICAL FIX: Use SetArenaFrameText for consistent name handling
    -- This ensures showArenaLabels setting is respected
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if arenaIndex and AC.SetArenaFrameText then
        AC:SetArenaFrameText(frame, arenaIndex, "live_arena", unit)
    else
        -- Fallback: Direct name update
        local name = UnitName(unit)
        if name then
            local currentText = frame.playerName:GetText() or ""
            if currentText ~= name then
                frame.playerName:SetText(name)
            end
        end
    end
end

-- Update all frame data
function MFM:UpdateFrameData(frame)
    if not frame then return end
    
    self:UpdateHealth(frame)
    self:UpdatePower(frame)
    self:UpdateName(frame)
end

-- Handle prep room (arena gates)
function MFM:HandlePrepRoom(frame)
    if not frame then return end
    
    -- In prep room, update spec icons and class info
    local unit = frame.unit
    if not unit or not UnitExists(unit) then return end
    
    -- Get spec info
    local specID = GetArenaOpponentSpec(frame.id)
    if specID and specID > 0 then
        local _, specName, _, icon, _, class = GetSpecializationInfoByID(specID)
        
        -- Update class icon if available - USE CUSTOM ARENACORE ICONS
        if frame.classIcon and class then
            local classFile = class
            -- FIXED: Check if class icons are enabled before showing
            local db = AC.DB and AC.DB.profile
            local classEnabled = db and db.classIcons and db.classIcons.enabled
            if classEnabled ~= false then
                -- CRITICAL FIX: Use custom ArenaCore class icons instead of default WoW icons
                -- This fixes the bug where fresh installs show default icons until reload
                if frame.classIcon.UpdateClassIcon then
                    -- New system with custom icons
                    frame.classIcon.UpdateClassIcon(classFile)
                    frame.classIcon:Show()
                elseif frame.classIcon.icon then
                    -- Fallback: set class icon texture directly respecting theme setting
                    local theme = db and db.classIcons and db.classIcons.theme or "arenacore"
                    local iconPath
                    if theme == "coldclasses" then
                        iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\" .. classFile:lower() .. ".png"
                    else
                        iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\" .. classFile .. ".tga"
                    end
                    frame.classIcon.icon:SetTexture(iconPath, true, true)
                    frame.classIcon:Show()
                else
                    -- Legacy fallback respecting theme setting
                    local theme = db and db.classIcons and db.classIcons.theme or "arenacore"
                    local iconPath
                    if theme == "coldclasses" then
                        iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\" .. classFile:lower() .. ".png"
                    else
                        iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\" .. classFile .. ".tga"
                    end
                    frame.classIcon:SetTexture(iconPath, true, true)
                    frame.classIcon:Show()
                end
            else
                frame.classIcon:Hide()
            end
        end
        
        -- Update spec icon if available
        if frame.specIcon and icon then
            -- FIXED: Check if spec icons are enabled before showing
            local db = AC.DB and AC.DB.profile
            local specEnabled = db and db.specIcons and db.specIcons.enabled
            if specEnabled ~= false then
                -- CRITICAL FIX: Use .icon not .texture (consistent with frame structure)
                if frame.specIcon.icon then
                    frame.specIcon.icon:SetTexture(icon)
                end
                frame.specIcon:Show()
            else
                frame.specIcon:Hide()
            end
        end
        
        -- PHASE 3: Racial visibility now handled by TrinketsRacials module
        -- Module's RefreshFrame handles prep room hiding automatically
    end
    
    -- Update basic info
    self:UpdateFrameData(frame)
end

-- OLD MFM HANDLERS - NO LONGER USED (using FrameManager UNIT_SPELLCAST_SUCCEEDED instead)
-- These are kept for reference but not called anywhere
--[[
function MFM:HandleCombatLog()
    -- DEPRECATED: Now using FrameManager:HandleTrinketRacialSpell with UNIT_SPELLCAST_SUCCEEDED
end

function MFM:HandleTrinketSpell(frame, spellID)
    -- DEPRECATED: Now using FrameManager:UpdateTrinket
end

function MFM:HandleRacialSpell(frame, spellID)
    -- DEPRECATED: Now using FrameManager:UpdateRacial
end
--]]

-- ============================================================================
-- FRAME CREATION HELPERS
-- ============================================================================

local function CreateFrameBackground(frame)
  local bg = frame:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetTexture(TEX.frame_bg); Trim(bg);
  local border = frame:CreateTexture(nil, "BORDER"); border:SetAllPoints(); border:SetTexture(TEX.frame_border); Trim(border);
  local hover = frame:CreateTexture(nil, "OVERLAY", nil, 1); hover:SetAllPoints(); hover:SetTexture(TEX.frame_hover); Trim(hover); hover:SetAlpha(0);
  local sel = frame:CreateTexture(nil, "OVERLAY", nil, 2); sel:SetAllPoints(); sel:SetTexture(TEX.frame_hover); Trim(sel); sel:SetBlendMode("ADD"); sel:SetVertexColor(unpack(SELECTION_TINT)); sel:SetAlpha(0);
  frame.background, frame.border, frame.hoverGlow, frame.selectionGlow = bg, border, hover, sel
end

local function CreateBar(parent, w, h, bgTex, borderTex, fillTex, x, y)
  -- Create actual StatusBar widget
  local statusBar = CreateFrame("StatusBar", nil, parent)
  statusBar:SetSize(w, h)
  -- Don't set initial position here - let UpdateBarPositions handle it
  statusBar:SetMinMaxValues(0, 100)
  statusBar:SetValue(100)
  statusBar:SetStatusBarTexture(fillTex)
  
  -- Background texture
  local bg = statusBar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetTexture(bgTex)
  Trim(bg)
  
  -- Border texture  
  local border = statusBar:CreateTexture(nil, "BORDER")
  border:SetAllPoints()
  border:SetTexture(borderTex)
  Trim(border)
  
  -- Store references for compatibility
  statusBar.background = bg
  statusBar.border = border
  statusBar.fill = statusBar:GetStatusBarTexture() -- This is the StatusBar's built-in fill
  
  return statusBar
end

-- PHASE 1.3: Duplicate CreateTrinket removed (kept MFM:CreateTrinket at line ~1843)

-- PHASE 1.3: Duplicate CreateRacial removed (kept MFM:CreateRacial at line ~1899)

-- PHASE 1.3: Duplicate CreateSpecIcon removed (kept MFM:CreateSpecIcon at line ~1972)

-- PHASE 1.3: Duplicate CreateDebuffContainer removed (kept MFM:CreateDebuffContainer at line ~2020)

-- ============================================================================
-- MASTER FRAME MANAGER INITIALIZATION
-- ============================================================================

function MFM:CreateFrames()
    -- Create all arena frames if they don't exist
    if not self.frames[1] then
        -- DEBUG: Creating arena frames
        -- print("|cffFFAA00ArenaCore Master:|r Creating arena frames...")
        
        for i = 1, MAX_ARENA_ENEMIES do
            self:CreateArenaFrame(i)
        end
        
        -- DEBUG: Arena frames created
        -- print("|cffFFAA00ArenaCore Master:|r " .. MAX_ARENA_ENEMIES .. " arena frames created")
    else
        -- DEBUG: Arena frames already exist
        -- print("|cffFFAA00ArenaCore Master:|r Arena frames already exist")
    end
end

function MFM:Initialize()
    -- Prevent duplicate initialization
    if self.frames[1] then
        -- DEBUG: Already initialized
        -- print("|cffFFAA00ArenaCore Master:|r Already initialized")
        return
    end
    
    -- DEBUG: Initializing Master Frame System
    -- print("|cffFFAA00ArenaCore Master:|r Initializing Master Frame System")
    
    -- Create frames ONCE at initialization
    for i = 1, MAX_ARENA_ENEMIES do
        self:CreateArenaFrame(i)
    end
    
    -- CRITICAL FIX: Set global AC.arenaFrames reference for module compatibility
    AC.arenaFrames = self.frames
    
    -- Set up global event handling
    self:SetupGlobalEvents()
    
    -- CRITICAL: Register cast bar, trinket, and racial events
    AC.FrameManager:RegisterDebuffEvents()
    
    -- LONG-TERM FIX: Apply sizes then positions on initialization
    -- ApplyFrameSizes() reads from profile and sets frame sizes
    -- UpdateFramePositions() is called automatically by ApplyFrameSizes()
    -- CRITICAL: Delay to ensure profile is fully loaded (especially after profile switches)
    C_Timer.After(0.3, function()
        if MFM and MFM.ApplyFrameSizes then
            MFM:ApplyFrameSizes()
        end
    end)
    
    -- Hide all frames initially
    self:HideAllFrames()

    -- Register FrameSort events
    local fs = FrameSortApi and FrameSortApi.v3

    if fs then
        AC.Debug:Print("|cffFF0000[FRAMESORT DEBUG]|r FrameSort integrated enabled.")

        if fs.Sorting.RegisterFrameProvider then
            -- New method for FrameSort integration with addons
            -- Available in FrameSort 7.6+
            local provider = {
                Name = function() return "Arena Core" end,
                Enabled = function() return true end,
                -- FrameSort wants to know if frames are visible for health check reasons.
                IsVisible = function() return self.frames[1] and self.frames[1]:IsVisible() end,
                -- We manage our own frames, don't want FrameSort to sort them.
                IsSelfManaged = true,
                -- This method runs when FrameSort requests us to sort our frames.
                Sort = function() return AC:FrameSortRequestingSort() end
            }

            fs.Sorting:RegisterFrameProvider(provider)
        else
            -- Legacy FrameSort integration, for 7.5 and below
            -- fires when the user changes a FrameSort configuration setting
            fs.Options:RegisterConfigurationChangedCallback(function() AC:OnFrameSortConfigChanged() end)

            -- fires when FrameSort performs a sort, e.g. when an arena unit spec becomes discovered
            fs.Sorting:RegisterPostSortCallback(function() AC:OnFrameSortPerformedSort() end)
        end
    end
    
    -- DEBUG: Master System initialized
    -- print("|cffFFAA00ArenaCore Master:|r Master System initialized - 3 unified frames created")
end

function MFM:SetupGlobalEvents()
    -- Create global event frame
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
    end
    
    -- CONSOLIDATION: Register ALL arena events in ONE place (no more dual systems!)
    -- Basic zone/login events
    self.eventFrame:RegisterEvent("PLAYER_LOGIN")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    -- Arena-specific events
    self.eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS") -- Prep room
    self.eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE") -- CRITICAL: Stealth handling
    self.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE") -- Solo Shuffle round transitions
    self.eventFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE") -- Trinket cooldown updates (sArena method)
    
    -- Unit update events (for arena units only - registered per-frame)
    self.eventFrame:RegisterEvent("UNIT_HEALTH")
    self.eventFrame:RegisterEvent("UNIT_MAXHEALTH")
    self.eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    self.eventFrame:RegisterEvent("UNIT_MAXPOWER")
    self.eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
    
    -- Match state events
    self.eventFrame:RegisterEvent("PVP_MATCH_STATE_CHANGED")
    self.eventFrame:RegisterEvent("UNIT_TARGETABLE_CHANGED")
    
    -- Set up event handler
    self.eventFrame:SetScript("OnEvent", function(self, event, ...)
        MFM:HandleGlobalEvent(event, ...)
    end)
    
    -- Debug removed for clean release
    -- print("|cff00FF00[ArenaCore]|r MasterFrameManager: ALL events consolidated into ONE system ✅")
end

function MFM:HandleGlobalEvent(event, ...)
    -- Skip all arena updates if in test mode (except LOGIN)
    if event ~= "PLAYER_LOGIN" and self.isTestMode then return end
    
    if event == "PLAYER_LOGIN" then
        -- Initialize on login if not already done
        if not self.frames[1] then
            self:Initialize()
        end
        
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        -- Check arena state (PROVEN PATTERN!)
        self:CheckArenaState()
        
        -- CRITICAL FIX: Update dispel frames when entering world/changing zones (like other modules)
        if AC.UpdateDispelFrames then
            C_Timer.After(0.5, function()
                AC:UpdateDispelFrames()
            end)
        end
        
        -- Forward to TrinketsRacials for Blizzard hook installation
        if AC.TrinketsRacials and AC.TrinketsRacials.HandleEvent then
            AC.TrinketsRacials:HandleEvent("PLAYER_ENTERING_WORLD")
        end
        
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        -- CRITICAL FIX: Call HandlePrepRoom to show real prep room data
        self:HandlePrepRoom()
        
        -- Forward to TrinketsRacials for Blizzard hook installation
        if AC.TrinketsRacials and AC.TrinketsRacials.HandleEvent then
            AC.TrinketsRacials:HandleEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
        end
        
    elseif event == "ARENA_OPPONENT_UPDATE" then
        -- CRITICAL: Re-enabled for racial/trinket/dispel updates
        -- ArenaFrameStealth.lua handles alpha, MismatchHandler handles spec/class
        -- This handler updates racials, trinkets, dispels, health, power, names
        local unit, updateType = ...
        self:HandleArenaOpponentUpdate(unit, updateType)
        
        -- Forward to TrinketsRacials for Blizzard hook installation
        if AC.TrinketsRacials and AC.TrinketsRacials.HandleEvent then
            AC.TrinketsRacials:HandleEvent("ARENA_OPPONENT_UPDATE", unit, updateType)
        end
        
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Solo Shuffle round transitions
        self:HandleSoloShuffleTransition()
        
        -- Forward to TrinketsRacials for cooldown reset
        if AC.TrinketsRacials and AC.TrinketsRacials.HandleEvent then
            AC.TrinketsRacials:HandleEvent("GROUP_ROSTER_UPDATE")
        end
        
    elseif event == "ARENA_COOLDOWNS_UPDATE" then
        -- CRITICAL: Trinket cooldown changed - forward to TrinketsRacials
        if AC.TrinketsRacials and AC.TrinketsRacials.HandleEvent then
            AC.TrinketsRacials:HandleEvent("ARENA_COOLDOWNS_UPDATE")
        end
        
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        -- Health updates for arena units
        local unit = ...
        if unit and unit:match("^arena[1-3]$") then
            self:UpdateUnitHealth(unit)
        end
        
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        -- Power updates for arena units
        local unit = ...
        if unit and unit:match("^arena[1-3]$") then
            self:UpdateUnitPower(unit)
        end
        
    elseif event == "UNIT_NAME_UPDATE" then
        -- Name updates for arena units
        local unit = ...
        if unit and unit:match("^arena[1-3]$") then
            self:UpdateUnitName(unit)
        end
        
    elseif event == "PVP_MATCH_STATE_CHANGED" then
        -- Match state changed (start/end)
        self:HandleMatchStateChange()
        
    elseif event == "UNIT_TARGETABLE_CHANGED" then
        -- Targeting changed
        local unit = ...
        if unit and unit:match("^arena[1-3]$") then
            self:UpdateUnitTargetable(unit)
        end
    end
end

-- Show test mode target border preview on Arena 3
function AC:ShowTestModeBorder()
    local frame = self.MasterFrameManager and self.MasterFrameManager.frames and self.MasterFrameManager.frames[3]
    if not frame then return end
    
    local thickness = self.DB and self.DB.profile and self.DB.profile.arenaFrames and 
                     self.DB.profile.arenaFrames.sizing and self.DB.profile.arenaFrames.sizing.targetBorderThickness or 3
    local color = {1, 0.4, 0}  -- Vibrant orange color
    
    -- Create test border container if it doesn't exist
    if not frame.testModeBorder then
        frame.testModeBorder = CreateFrame("Frame", nil, frame)
        frame.testModeBorder:SetFrameLevel(frame:GetFrameLevel() + 10)
        frame.testModeBorder:SetAllPoints(frame)
        
        -- Create 4 border textures
        frame.testModeBorder.top = frame.testModeBorder:CreateTexture(nil, "OVERLAY", nil, 7)
        frame.testModeBorder.bottom = frame.testModeBorder:CreateTexture(nil, "OVERLAY", nil, 7)
        frame.testModeBorder.left = frame.testModeBorder:CreateTexture(nil, "OVERLAY", nil, 7)
        frame.testModeBorder.right = frame.testModeBorder:CreateTexture(nil, "OVERLAY", nil, 7)
    end
    
    local border = frame.testModeBorder
    
    -- Update top
    border.top:SetColorTexture(color[1], color[2], color[3], 1)
    border.top:ClearAllPoints()
    border.top:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    border.top:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
    border.top:SetHeight(thickness)
    border.top:Show()
    
    -- Update bottom
    border.bottom:SetColorTexture(color[1], color[2], color[3], 1)
    border.bottom:ClearAllPoints()
    border.bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
    border.bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    border.bottom:SetHeight(thickness)
    border.bottom:Show()
    
    -- Update left
    border.left:SetColorTexture(color[1], color[2], color[3], 1)
    border.left:ClearAllPoints()
    border.left:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    border.left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
    border.left:SetWidth(thickness)
    border.left:Show()
    
    -- Update right
    border.right:SetColorTexture(color[1], color[2], color[3], 1)
    border.right:ClearAllPoints()
    border.right:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
    border.right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    border.right:SetWidth(thickness)
    border.right:Show()
    
    border:Show()
end

-- Hide test mode border (called when leaving test mode)
function AC:HideTestModeBorder()
    local frame = self.MasterFrameManager and self.MasterFrameManager.frames and self.MasterFrameManager.frames[3]
    if frame and frame.testModeBorder then
        frame.testModeBorder:Hide()
    end
end

-- Update target border thickness - called by slider
function AC:UpdateAllTargetBorders()
    local thickness = self.DB and self.DB.profile and self.DB.profile.arenaFrames and 
                     self.DB.profile.arenaFrames.sizing and self.DB.profile.arenaFrames.sizing.targetBorderThickness or 3
    
    -- Update test mode border if in test mode
    if self.MasterFrameManager and self.MasterFrameManager.isTestMode then
        self:ShowTestModeBorder()  -- This recreates with new thickness
    end
    
    -- Update TargetHighlight borders for real arena (if outlines exist)
    if self.MasterFrameManager and self.MasterFrameManager.frames then
        for i = 1, MAX_ARENA_ENEMIES do
            local frame = self.MasterFrameManager.frames[i]
            if frame and frame.targetOutline then
                local outline = frame.targetOutline
                if outline.top then outline.top:SetHeight(thickness) end
                if outline.bottom then outline.bottom:SetHeight(thickness) end
                if outline.left then outline.left:SetWidth(thickness) end
                if outline.right then outline.right:SetWidth(thickness) end
            end
        end
    end
end

function MFM:CheckArenaState()
    local _, instanceType = IsInInstance()
    
    -- Check if we entered or left arena
    if instanceType == "arena" and not self.isInArena then
        self:EnteredArena()
    elseif instanceType ~= "arena" and self.isInArena then
        self:LeftArena()
    end
    
    -- ADDITIONAL SAFEGUARD: If we're not in arena and not in test mode, ensure frames are hidden
    if instanceType ~= "arena" and not self.isTestMode then
        -- Force hide frames if they're somehow visible outside arena
        for i = 1, MAX_ARENA_ENEMIES do
            if self.frames[i] and self.frames[i]:IsShown() then
                print("|cffFF0000[CRITICAL]|r Frame " .. i .. " was visible outside arena - force hiding!")
                self.frames[i]:Hide()
                self.frames[i]:SetAlpha(1)
            end
        end
    end
    
    self.instanceType = instanceType
end

function MFM:EnteredArena()
    -- User notification: Entered arena
    print("|cffFFAA00ArenaCore:|r Entered Arena")
    self.isInArena = true
    self.isTestMode = false
    AC.testModeEnabled = false  -- CRITICAL: Also disable global test mode flag
    
    -- FRAMESORT WARNING: Check if integration enabled but FrameSort not detected
    local enableFrameSortIntegration = AC.DB and AC.DB.profile 
        and AC.DB.profile.arenaFrames 
        and AC.DB.profile.arenaFrames.general 
        and AC.DB.profile.arenaFrames.general.enableFrameSortIntegration
    
    if enableFrameSortIntegration and not (FrameSortApi and FrameSortApi.v3) then
        print("|cffFF0000[ArenaCore]|r FrameSort integration is enabled but FrameSort addon is not detected!")
        print("|cffFF0000[ArenaCore]|r Please install FrameSort or disable integration in ArenaCore settings.")
    end
    
    -- REMOVED: DR reset call - using auto-expiration now!
    -- DRs automatically expire after 18 seconds, no manual reset needed
    -- This prevents bugs from missed arena enter events
    
    -- CRITICAL: Hide Blizzard's default arena trinket/racial frames (multiple attempts)
    C_Timer.After(0.1, function()
        for i = 1, 3 do
            -- Try different frame names
            local frames = {
                _G["CompactArenaFramePlayer" .. i],
                _G["ArenaEnemyFrame" .. i],
                _G["CompactArenaFrame" .. i]
            }
            
            for _, blizzFrame in ipairs(frames) do
                if blizzFrame then
                    -- Hide all possible trinket/racial elements
                    if blizzFrame.trinket then 
                        blizzFrame.trinket:Hide()
                        blizzFrame.trinket:SetAlpha(0)
                        -- DEBUG: Hidden Blizzard trinket
                        -- print("|cffFFAA00[HIDE BLIZZ]|r Hidden trinket for " .. blizzFrame:GetName())
                    end
                    if blizzFrame.Trinket then 
                        blizzFrame.Trinket:Hide()
                        blizzFrame.Trinket:SetAlpha(0)
                    end
                    if blizzFrame.trinketButton then 
                        blizzFrame.trinketButton:Hide()
                        blizzFrame.trinketButton:SetAlpha(0)
                    end
                    if blizzFrame.racial then
                        blizzFrame.racial:Hide()
                        blizzFrame.racial:SetAlpha(0)
                    end
                    if blizzFrame.Racial then
                        blizzFrame.Racial:Hide()
                        blizzFrame.Racial:SetAlpha(0)
                    end
                end
            end
        end
    end)
    
    -- CRITICAL: Clear ALL test mode elements when entering arena
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = self.frames[i]
        if frame then
            -- CRITICAL FIX: Reset frame alpha to 1.0 when entering arena
            -- This fixes faded frames after reload mid-arena
            -- Alpha should only be 0.5 in prep room for stealth detection
            frame:SetAlpha(1.0)
            
            -- CRITICAL FIX: Switch to Blizzard CastingBarFrame in Midnight when entering arena
            -- ALSO set up DR tray if in arena (handles reload mid-arena)
            local _, instanceType = IsInInstance()
            if AC.Midnight and AC.Midnight.isMidnight and instanceType == "arena" then
                local blizzArenaFrame = _G["CompactArenaFrameMember" .. i]
                
                -- Set up cast bar if not already done
                if frame.castBar and not frame.castBar._isMidnightBlizzardFrame and blizzArenaFrame and blizzArenaFrame.CastingBarFrame then
                    -- print("|cff00FF00[EnteredArena]|r Switching Arena" .. i .. " to Blizzard CastingBarFrame")
                    
                    -- Hide and clear old custom cast bar
                    frame.castBar:Hide()
                    frame.castBar:SetValue(0)
                    
                    -- Switch to Blizzard's CastingBarFrame
                    frame.castBar = blizzArenaFrame.CastingBarFrame
                    frame.castBar:SetParent(frame)
                    frame.castBar:ClearAllPoints()
                    
                    -- Get positioning from settings
                    -- CRITICAL: Default values MUST match Init.lua DEFAULTS.castBars exactly
                    local castBarDB = AC.DB and AC.DB.profile and AC.DB.profile.castBars
                    local castBarPos = castBarDB and castBarDB.positioning or {}
                    local castBarSize = castBarDB and castBarDB.sizing or {}
                    local cbHorizontal = castBarPos.horizontal or -4
                    local cbVertical = castBarPos.vertical or -86
                    local cbWidth = castBarSize.width or 220
                    local cbHeight = castBarSize.height or 24
                    
                    -- CRITICAL: Protect position from Blizzard's repositioning attempts
                    -- Store original SetPoint before overriding
                    if not frame.castBar._originalSetPoint then
                        frame.castBar._originalSetPoint = frame.castBar.SetPoint
                    end
                    
                    -- Override SetPoint to prevent Blizzard from repositioning
                    frame.castBar.SetPoint = function(self, point, relativeTo, relativePoint, x, y)
                        -- Only allow ArenaCore's positioning (TOP-TOP anchor)
                        if point == "TOP" and relativePoint == "TOP" and relativeTo == frame then
                            frame.castBar._originalSetPoint(self, point, relativeTo, relativePoint, x, y)
                        end
                        -- Block all other SetPoint attempts (like Blizzard's TOPRIGHT-LEFT)
                    end
                    
                    -- Set ArenaCore's custom position
                    frame.castBar._originalSetPoint(frame.castBar, "TOP", frame, "TOP", cbHorizontal, cbVertical)
                    frame.castBar:SetSize(cbWidth, cbHeight)
                    frame.castBar:SetFrameStrata("HIGH")
                    
                    -- CRITICAL: Set unit token for cast tracking to work
                    frame.castBar.empoweredFix = true
                    frame.castBar:SetUnit("arena" .. i, false, true)
                    
                    -- Set default orange color for cast bar (prevents white color)
                    frame.castBar:SetStatusBarColor(1, 0.7, 0, 1)
                    
                    -- Apply ArenaCore visual theme to Blizzard's CastingBarFrame
                    -- Get cast bar texture from settings
                    local texturesDB = AC.DB and AC.DB.profile and AC.DB.profile.textures
                    local castTex = nil
                    if texturesDB then
                        local healthTex = texturesDB.healthBarTexture or "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture1.tga"
                        local powerTex = texturesDB.useDifferentPowerBarTexture and texturesDB.powerBarTexture or healthTex
                        castTex = texturesDB.useDifferentCastBarTexture and texturesDB.castBarTexture or powerTex
                    end
                    
                    -- Apply status bar texture (the filling bar itself)
                    if castTex then
                        frame.castBar:SetStatusBarTexture(castTex)
                    end
                    
                    -- Background texture
                    if not frame.castBar.bg then
                        frame.castBar.bg = frame.castBar:CreateTexture(nil, "BACKGROUND")
                        frame.castBar.bg:SetAllPoints(frame.castBar)
                    end
                    local bgStyle = castBarDB and castBarDB.backgroundStyle or "Arena Core"
                    if bgStyle == "Arena Core" then
                        frame.castBar.bg:SetTexture(TEX.cast_bg, true, true)
                        frame.castBar.bg:SetTexCoord(0, 1, 0, 1)
                    else
                        frame.castBar.bg:SetTexture(nil)
                        frame.castBar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)
                    end
                    frame.castBar.bg:Show()
                    
                    -- Border frame
                    if not frame.castBar.borderFrame then
                        frame.castBar.borderFrame = CreateFrame("Frame", nil, frame.castBar)
                        frame.castBar.borderFrame:SetAllPoints()
                        frame.castBar.borderFrame:SetFrameStrata("HIGH")
                        frame.castBar.borderFrame:SetFrameLevel(frame.castBar:GetFrameLevel() + 10)
                        
                        -- Create border textures
                        frame.castBar.borderFrame.top = frame.castBar.borderFrame:CreateTexture(nil, "OVERLAY")
                        frame.castBar.borderFrame.top:SetTexture(TEX.border)
                        frame.castBar.borderFrame.top:SetPoint("TOPLEFT", frame.castBar, "TOPLEFT", -2, 2)
                        frame.castBar.borderFrame.top:SetPoint("TOPRIGHT", frame.castBar, "TOPRIGHT", 2, 2)
                        frame.castBar.borderFrame.top:SetHeight(2)
                        
                        frame.castBar.borderFrame.bottom = frame.castBar.borderFrame:CreateTexture(nil, "OVERLAY")
                        frame.castBar.borderFrame.bottom:SetTexture(TEX.border)
                        frame.castBar.borderFrame.bottom:SetPoint("BOTTOMLEFT", frame.castBar, "BOTTOMLEFT", -2, -2)
                        frame.castBar.borderFrame.bottom:SetPoint("BOTTOMRIGHT", frame.castBar, "BOTTOMRIGHT", 2, -2)
                        frame.castBar.borderFrame.bottom:SetHeight(2)
                        
                        frame.castBar.borderFrame.left = frame.castBar.borderFrame:CreateTexture(nil, "OVERLAY")
                        frame.castBar.borderFrame.left:SetTexture(TEX.border)
                        frame.castBar.borderFrame.left:SetPoint("TOPLEFT", frame.castBar, "TOPLEFT", -2, 2)
                        frame.castBar.borderFrame.left:SetPoint("BOTTOMLEFT", frame.castBar, "BOTTOMLEFT", -2, -2)
                        frame.castBar.borderFrame.left:SetWidth(2)
                        
                        frame.castBar.borderFrame.right = frame.castBar.borderFrame:CreateTexture(nil, "OVERLAY")
                        frame.castBar.borderFrame.right:SetTexture(TEX.border)
                        frame.castBar.borderFrame.right:SetPoint("TOPRIGHT", frame.castBar, "TOPRIGHT", 2, 2)
                        frame.castBar.borderFrame.right:SetPoint("BOTTOMRIGHT", frame.castBar, "BOTTOMRIGHT", 2, -2)
                        frame.castBar.borderFrame.right:SetWidth(2)
                    end
                    frame.castBar.borderFrame:Show()
                    
                    -- Style Blizzard's Text with ArenaCore font
                    if frame.castBar.Text then
                        if AC.SafeSetFont then
                            AC.SafeSetFont(frame.castBar.Text, AC.FONT_PATH, 10, "OUTLINE")
                        else
                            frame.castBar.Text:SetFont("Fonts\\\\FRIZQT__.TTF", 10, "OUTLINE")
                        end
                        frame.castBar.Text:SetTextColor(1, 1, 1)
                        frame.castBar.Text:Show()
                    end
                    
                    -- Show/hide Blizzard elements
                    if frame.castBar.Icon then frame.castBar.Icon:Show() end
                    if frame.castBar.Border then frame.castBar.Border:Hide() end
                    if frame.castBar.Spark then frame.castBar.Spark:Show() end
                    
                    -- Hook cast bar colors for Midnight
                    if AC.CastBars and AC.CastBars.HookCastBarColors then
                        AC.CastBars:HookCastBarColors(frame.castBar)
                    end
                    
                    -- CRITICAL: Create spellIcon alias to Icon for consistency
                    -- This ensures that frame.castBar.spellIcon references the same frame as frame.castBar.Icon
                    if frame.castBar.Icon and not frame.castBar.spellIcon then
                        frame.castBar.spellIcon = frame.castBar.Icon
                    end
                    
                    -- Mark as Midnight frame
                    frame.castBar._isMidnightBlizzardFrame = true
                end
                
                -- CRITICAL FIX: Set up Blizzard's SpellDiminishStatusTray for DR tracking
                -- This runs independently of cast bar setup to handle reloads mid-arena
                if blizzArenaFrame and blizzArenaFrame.SpellDiminishStatusTray and not frame.drTray then
                    -- print("|cff00FF00[DR SETUP]|r Arena" .. i .. " - Setting up DR tray")
                    
                    -- CRITICAL: Enable the CVar that controls DR tray visibility
                    C_CVar.SetCVar("spellDiminishPVPEnemiesEnabled", "1")
                    -- print("|cff00FF00[DR SETUP]|r CVar set to: " .. tostring(C_CVar.GetCVar("spellDiminishPVPEnemiesEnabled")))
                    
                    local drTray = blizzArenaFrame.SpellDiminishStatusTray
                    frame.drTray = drTray
                    
                    -- Store references
                    drTray._acArenaFrame = frame
                    drTray._acBlizzFrame = blizzArenaFrame
                    drTray._acOriginalOnHide = drTray:GetScript("OnHide")
                    
                    -- Override OnHide to prevent forbidden table errors when leaving arena
                    -- But ALLOW the tray to hide normally (just skip RemoveAllTrayItems cleanup)
                    drTray:SetScript("OnHide", function(self)
                        local _, instanceType = IsInInstance()
                        if instanceType == "arena" then
                            -- Still in arena - skip cleanup to avoid forbidden table errors
                            -- But let Blizzard handle event unregistration normally
                            return
                        end
                        -- Actually leaving arena - run original OnHide safely
                        if self._acOriginalOnHide then
                            pcall(self._acOriginalOnHide, self)
                        end
                    end)
                    
                    -- Reparent to ArenaCore frame
                    drTray:SetParent(frame)
                    drTray:SetFrameStrata("HIGH")
                    drTray:SetUnit("arena" .. i)
                    drTray:EnableMouse(false)
                    drTray:SetMouseClickEnabled(false)
                    
                    -- CRITICAL: Force show the tray and register events
                    drTray:Show()
                    pcall(function()
                        drTray:RegisterEvent("UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED")
                    end)

                    if AC.UpdateDRPositions then
                        AC:UpdateDRPositions(frame)
                    end

                    if not AC._midnightDRTrayItemHooksInitialized then
                        AC._midnightDRTrayItemHooksInitialized = true

                        local function GetDRDB()
                            return AC.DB and AC.DB.profile and AC.DB.profile.diminishingReturns
                        end

                        local function SafeXCall(tag, fn)
                            local ok, err = xpcall(fn, function(e)
                                local msg = tostring(e)
                                if msg:find("forbidden table", 1, true) then
                                    print("|cffFF0000[ArenaCore]|r " .. tag .. ": " .. msg)
                                    print(debugstack(2, 40, 40))
                                end
                                return e
                            end)
                            return ok, err
                        end

                        -- Setup dual text elements: one for 1/2 (green), one for 2/2 (red)
                        -- The 2/2 text is parented to ImmunityIndicator so it auto-shows when immune
                        local function SetupDualStageText(item)
                            if item._acDualTextSetup then return end
                            item._acDualTextSetup = true
                            
                            local db = GetDRDB() or {}
                            local stageSize = (db.sizing and db.sizing.stageFontSize) or 8
                            
                            -- Create green "1/2" text (shows when NOT immune)
                            item.ACStageText1 = item:CreateFontString(nil, "OVERLAY")
                            item.ACStageText1:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -2, 2)
                            if AC.SafeSetFont then
                                AC.SafeSetFont(item.ACStageText1, AC.FONT_PATH, stageSize, "OUTLINE")
                            else
                                item.ACStageText1:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", stageSize, "OUTLINE")
                            end
                            item.ACStageText1:SetText("1/2")
                            item.ACStageText1:SetTextColor(0, 1, 0, 1)  -- Green
                            
                            -- Create red "2/2" text - PARENTED TO ImmunityIndicator so it auto-shows when immune
                            item.ACStageText2 = item.ImmunityIndicator:CreateFontString(nil, "OVERLAY")
                            item.ACStageText2:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -2, 2)
                            if AC.SafeSetFont then
                                AC.SafeSetFont(item.ACStageText2, AC.FONT_PATH, stageSize, "OUTLINE")
                            else
                                item.ACStageText2:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", stageSize, "OUTLINE")
                            end
                            item.ACStageText2:SetText("2/2")
                            item.ACStageText2:SetTextColor(1, 0, 0, 1)  -- Red
                            item.ACStageText2:SetIgnoreParentAlpha(true)
                            
                            -- Hook ImmunityIndicator:SetShown to toggle green text and border color
                            -- Use SetAlphaFromBoolean to handle secret values
                            hooksecurefunc(item.ImmunityIndicator, "SetShown", function(immunityIndicator, isShown)
                                -- Use SetAlphaFromBoolean to handle secret value (can't use 'not isShown')
                                -- When immune: green text alpha=0, when not immune: green text alpha=1
                                if item.ACStageText1 and item.ACStageText1.SetAlphaFromBoolean then
                                    item.ACStageText1:SetAlphaFromBoolean(isShown, 0, 1)
                                end
                                
                                -- Update border color using SetAlphaFromBoolean on dual borders
                                -- CRITICAL: We can't evaluate isShown (secret value), so we use two borders
                                -- and show/hide them using SetAlphaFromBoolean
                                local dbInner = GetDRDB() or {}
                                if dbInner.colorCodedBorders then
                                    if item.ACBorderGreen and item.ACBorderGreen.SetAlphaFromBoolean then
                                        -- Green border: show when NOT immune (isShown=false)
                                        item.ACBorderGreen:SetAlphaFromBoolean(isShown, 0, 1)
                                    end
                                    if item.ACBorderRed and item.ACBorderRed.SetAlphaFromBoolean then
                                        -- Red border: show when immune (isShown=true)
                                        item.ACBorderRed:SetAlphaFromBoolean(isShown, 1, 0)
                                    end
                                end
                            end)
                        end
                        
                        local function ApplyItemVisuals(item)
                            pcall(function()
                                local db = GetDRDB() or {}
                                local showStage = db.showStageIndicators
                                if showStage == nil then showStage = true end
                                local colorBorders = db.colorCodedBorders
                                
                                -- Setup dual text if not done
                                if item.ImmunityIndicator and not item._acDualTextSetup then
                                    SetupDualStageText(item)
                                end
                                
                                -- Show/hide stage text based on setting
                                if item.ACStageText1 then
                                    item.ACStageText1:SetShown(showStage)
                                end
                                if item.ACStageText2 then
                                    item.ACStageText2:SetShown(showStage)
                                end
                                
                                -- Setup dual borders for color-coded mode (green/red)
                                -- CRITICAL: We use TWO borders and toggle alpha because we can't evaluate secret booleans
                                if not item.ACBorderGreen then
                                    -- Green border (stage 1 - not immune)
                                    item.ACBorderGreen = item:CreateTexture(nil, "OVERLAY", nil, 6)
                                    item.ACBorderGreen:SetTexture("Interface/AddOns/ArenaCore/Media/Classicons/Overlays/orangeoverlay.tga")
                                    item.ACBorderGreen:SetAllPoints(item)
                                    item.ACBorderGreen:SetVertexColor(0, 1, 0, 1)  -- Green
                                end
                                
                                if not item.ACBorderRed then
                                    -- Red border (stage 2 - immune)
                                    item.ACBorderRed = item:CreateTexture(nil, "OVERLAY", nil, 7)
                                    item.ACBorderRed:SetTexture("Interface/AddOns/ArenaCore/Media/Classicons/Overlays/orangeoverlay.tga")
                                    item.ACBorderRed:SetAllPoints(item)
                                    item.ACBorderRed:SetVertexColor(1, 0, 0, 1)  -- Red
                                end
                                
                                if not item.ACBorderOrange then
                                    -- Orange border (default when colorCodedBorders is OFF)
                                    item.ACBorderOrange = item:CreateTexture(nil, "OVERLAY", nil, 6)
                                    item.ACBorderOrange:SetTexture("Interface/AddOns/ArenaCore/Media/Classicons/Overlays/orangeoverlay.tga")
                                    item.ACBorderOrange:SetAllPoints(item)
                                    item.ACBorderOrange:SetVertexColor(1, 0.4, 0, 1)  -- Orange
                                end
                                
                                -- Show/hide borders based on colorCodedBorders setting
                                if colorBorders then
                                    -- Color-coded mode: show green/red borders, hide orange
                                    item.ACBorderOrange:Hide()
                                    item.ACBorderGreen:Show()
                                    item.ACBorderRed:Show()
                                    
                                    -- Set initial alpha based on current immune state
                                    if item.ImmunityIndicator then
                                        local isShown
                                        pcall(function() isShown = item.ImmunityIndicator:IsShown() end)
                                        if item.ACBorderGreen.SetAlphaFromBoolean then
                                            item.ACBorderGreen:SetAlphaFromBoolean(isShown, 0, 1)
                                        end
                                        if item.ACBorderRed.SetAlphaFromBoolean then
                                            item.ACBorderRed:SetAlphaFromBoolean(isShown, 1, 0)
                                        end
                                    end
                                else
                                    -- Default mode: show orange border, hide green/red
                                    item.ACBorderOrange:Show()
                                    item.ACBorderGreen:Hide()
                                    item.ACBorderRed:Hide()
                                end
                            end)
                        end

                        if _G.SpellDiminishStatusTrayItemMixin then
                            hooksecurefunc(_G.SpellDiminishStatusTrayItemMixin, "SetCategoryInfo", function(item)
                                SafeXCall("DR:SetCategoryInfo", function()
                                    local db = GetDRDB() or {}
                                    local iconSize = (db.sizing and db.sizing.size) or 22

                                    item:SetSize(iconSize, iconSize)
                                    local immunity = item.ImmunityIndicator
                                    if immunity and immunity.SetSize then
                                        immunity:SetSize(iconSize, iconSize)
                                    end

                                    ApplyItemVisuals(item)
                                end)
                            end)

                            hooksecurefunc(_G.SpellDiminishStatusTrayItemMixin, "UpdateState", function(item, spellDiminishCategoryState)
                                SafeXCall("DR:UpdateState", function()
                                    local db = GetDRDB() or {}
                                    local iconSize = (db.sizing and db.sizing.size) or 22
                                    item:SetSize(iconSize, iconSize)

                                    local immunity = item.ImmunityIndicator
                                    if immunity and immunity.SetSize then
                                        immunity:SetSize(iconSize, iconSize)
                                    end

                                    ApplyItemVisuals(item)
                                end)
                            end)

                            hooksecurefunc(_G.SpellDiminishStatusTrayItemMixin, "Reset", function(item)
                                pcall(function()
                                    -- Reset handled by dual-text system (green text shows, red hides with ImmunityIndicator)
                                    if item.ACStageText1 then
                                        item.ACStageText1:Show()
                                    end
                                end)
                            end)
                        end
                    end

                    if frame.drTray.SetMouseClickEnabled then
                        frame.drTray:SetMouseClickEnabled(false)
                    end

                    if AC.UpdateDRPositions then
                        AC:UpdateDRPositions(frame)
                    end
                    -- DEBUG DISABLED: print("|cff00FF00[DR SETUP]|r Arena" .. i .. " - DR tray configured")
                end
                
                -- CRITICAL FIX: Disable mouse on Blizzard's aura frames to prevent tooltip SetAttribute errors
                -- Blizzard's CompactUnitFrame aura tooltips call SetAttribute internally, causing 9000+ errors in arena
                if blizzArenaFrame then
                    -- Disable mouse on buff frames
                    local buffFrames
                    pcall(function() buffFrames = blizzArenaFrame.buffFrames end)
                    if type(buffFrames) == "table" then
                        for _, buffFrame in pairs(buffFrames) do
                            if buffFrame and buffFrame.EnableMouse then
                                buffFrame:EnableMouse(false)
                            end
                        end
                    end
                    -- Disable mouse on debuff frames
                    local debuffFrames
                    pcall(function() debuffFrames = blizzArenaFrame.debuffFrames end)
                    if type(debuffFrames) == "table" then
                        for _, debuffFrame in pairs(debuffFrames) do
                            if debuffFrame and debuffFrame.EnableMouse then
                                debuffFrame:EnableMouse(false)
                            end
                        end
                    end
                    -- Disable mouse on dispel debuff frames
                    local dispelDebuffFrames
                    pcall(function() dispelDebuffFrames = blizzArenaFrame.dispelDebuffFrames end)
                    if type(dispelDebuffFrames) == "table" then
                        for _, dispelFrame in pairs(dispelDebuffFrames) do
                            if dispelFrame and dispelFrame.EnableMouse then
                                dispelFrame:EnableMouse(false)
                            end
                        end
                    end
                end
                
                -- CRITICAL FIX: Close Edit Mode after all DR trays set up
                if i == MAX_ARENA_ENEMIES and EditModeManagerFrame and EditModeManagerFrame.AccountSettings then
                    HideUIPanel(EditModeManagerFrame)
                    -- DEBUG DISABLED: print("|cff00FF00[DR FIX]|r Closed Edit Mode - DR trays unlocked")
                end
            end  -- AC.Midnight if block
            
            -- REMOVED: Layout override code - accessing trayItemPool causes forbidden table errors
            -- DR icons will use Blizzard's default spacing and sizing for now
        end  -- frame if block
    end  -- for loop
    
    -- MismatchHandler now controls frame visibility via events
    -- No manual ShowArenaFrames needed - ARENA_OPPONENT_UPDATE and ARENA_PREP_OPPONENT_SPECIALIZATIONS handle it
    
    -- Check for prep room
    local numOpps = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0
    if numOpps > 0 then
        -- Prep room detected - MismatchHandler will handle frame visibility
        self:HandlePrepRoom()
    end
end

function MFM:LeftArena()
    -- User notification: Left arena
    print("|cffFFAA00ArenaCore:|r Left Arena")
    self.isInArena = false
    
    -- CRITICAL FIX: If test mode is active, completely reset it
    -- This ensures test mode works like a fresh reload after arena
    local wasTestMode = self.isTestMode or AC.testModeEnabled
    if wasTestMode then
        print("|cffFFAA00ArenaCore:|r Resetting test mode (like fresh reload)...")
        
        -- Disable test mode
        self:DisableTestMode()
        
        -- Wait a moment, then re-enable it fresh
        C_Timer.After(0.1, function()
            if not self.isInArena then
                self:EnableTestMode()
                print("|cff00FF00ArenaCore:|r Test mode reset complete!")
            end
        end)
    end
    
    -- CRITICAL FIX: BULLETPROOF frame hiding when leaving arena
    -- Multiple attempts with delays to catch any race conditions
    self:HideAllFrames()
    
    -- ADDITIONAL SAFEGUARD: Hide frames again after short delay
    -- This catches cases where other systems might show frames after LeftArena()
    C_Timer.After(0.1, function()
        if not self.isInArena and not self.isTestMode then
            self:HideAllFrames()
        end
    end)
    
    -- ADDITIONAL SAFEGUARD: Hide frames again after longer delay
    -- This catches cases where zone change events might trigger frame showing
    C_Timer.After(0.5, function()
        if not self.isInArena and not self.isTestMode then
            self:HideAllFrames()
        end
    end)
    
    -- Reset frame data
    for i = 1, MAX_ARENA_ENEMIES do
        self:ResetFrame(self.frames[i])
        
        -- CRITICAL FIX: Explicitly hide death icon when leaving arena
        -- Death icon has TOOLTIP strata and can leak into scoreboard
        local frame = self.frames[i]
        if frame and frame.deathIconFrame then
            frame.deathIconFrame:Hide()
        end
    end
    
    -- CRITICAL FIX: Clear all DR icons when leaving arena
    -- This ensures clean slate for next test mode or arena
    local drModule = GetDRModule()
    if drModule and drModule.ClearAllDRs then
        drModule:ClearAllDRs()
    end
    
    -- CRITICAL: Clear any arena-related flags that might cause frames to show
    self.hasArenaData = false
    self.arenaFramesInitialized = false
    
    -- CRITICAL FIX: Reset texture application flag for next match
    self._texturesAppliedThisMatch = false
    
    -- Clear stealth timers to prevent memory leaks
    if AC._stealthTimers then
        wipe(AC._stealthTimers)
    end
end

-- ============================================================================
-- Visibility and Data Updates
-- ============================================================================

-- Update frame visibility based on arena state
-- This determines show/hide WITHOUT resizing or repositioning
function MFM:UpdateVisible()
    if InCombatLockdown() then
        -- Defer until combat ends
        if not self._deferredVisibilityUpdate then
            self._deferredVisibilityUpdate = true
            local combatFrame = CreateFrame("Frame")
            combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            combatFrame:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                MFM._deferredVisibilityUpdate = nil
                MFM:UpdateVisible()
            end)
        end
        return
    end
    
    local _, instanceType = IsInInstance()
    local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0
    local numArenaOpponents = GetNumArenaOpponents and GetNumArenaOpponents() or 0
    
    -- Show frames if in arena and have opponents (prep room or live)
    if instanceType == "arena" and (numOpponents > 0 or numArenaOpponents > 0) then
        local maxFrames = math.max(numOpponents, numArenaOpponents)
        for i = 1, MAX_ARENA_ENEMIES do
            if self.frames[i] then
                if i <= maxFrames then
                    self.frames[i]:Show()
                else
                    self.frames[i]:Hide()
                end
            end
        end
    else
        -- Not in arena or no opponents - hide all
        self:HideAllFrames()
    end
end

-- Update arena unit data WITHOUT resizing
-- This refreshes health, power, names, etc. but preserves visual properties
function MFM:UpdateArenaData()
    -- CRITICAL: Block during combat to prevent taint
    if InCombatLockdown() then
        return
    end
    
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then
        return
    end
    
    -- Update each arena unit's data
    for i = 1, MAX_ARENA_ENEMIES do
        local unit = "arena" .. i
        local frame = self.frames[i]
        
        if frame and UnitExists(unit) then
            -- Update unit data (health, power, name) WITHOUT resizing
            self:UpdateUnitHealth(unit)
            self:UpdateUnitPower(unit)
            self:UpdateUnitName(unit)
            
            -- Update class/spec icons if available
            if self.UpdateClassIcon then
                self:UpdateClassIcon(unit)
            end
            
            -- Update trinket/racial states (not sizes)
            if AC.TrinketTracker and AC.TrinketTracker.UpdateTrinketForUnit then
                AC.TrinketTracker:UpdateTrinketForUnit(unit)
            end
        end
    end
end

-- ============================================================================
-- LONG-TERM FIX: Size Application (Separated from Positioning)
-- ============================================================================

-- Apply frame sizes from database settings
-- This is ONLY called when user changes settings, switches profiles, or on initial load
-- NEVER called on reloads or arena events - that's the key to preventing unwanted resizing
function MFM:ApplyFrameSizes()
    -- CRITICAL: Block during combat to prevent taint
    if InCombatLockdown() then
        -- Queue for after combat
        C_Timer.After(0.1, function()
            if not InCombatLockdown() and MFM and MFM.ApplyFrameSizes then
                MFM:ApplyFrameSizes()
            end
        end)
        return
    end
    
    -- Read sizes from PROFILE (not themeData!)
    -- Profiles store their settings in AC.DB.profile.arenaFrames
    local width = 235  -- Fallback defaults
    local height = 68
    local scale = 1.0
    
    if AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.sizing then
        local sizing = AC.DB.profile.arenaFrames.sizing
        
        -- CRITICAL FIX: Detect and fix corrupted decimal values
        -- If width/height are not clean integers, they're corrupted - round them
        local rawWidth = sizing.width or 235
        local rawHeight = sizing.height or 68
        
        -- Check if values are corrupted (have decimal places when they shouldn't)
        if rawWidth ~= math.floor(rawWidth) or rawHeight ~= math.floor(rawHeight) then
            -- Corruption detected - rounding and fixing
            -- Round to nearest integer
            width = math.floor(rawWidth + 0.5)
            height = math.floor(rawHeight + 0.5)
            
            -- Fix the database
            sizing.width = width
            sizing.height = height
        else
            width = rawWidth
            height = rawHeight
        end
        
        -- ADDITIONAL CHECK: If values are suspiciously wrong (too small/large), reset to defaults
        -- This catches cases where corruption happened but values are still integers
        if width < 100 or width > 500 or height < 30 or height > 200 then
            -- Suspicious values detected - resetting to safe defaults
            width = 235
            height = 68
            sizing.width = 235
            sizing.height = 68
        end
        
        -- CRITICAL FIX: Check if scale is already a decimal (< 10) or a percentage (>= 10)
        -- Some old profiles stored scale as decimal (1.0), newer ones as percentage (100)
        local rawScale = sizing.scale or 100
        
        -- Also fix corrupted scale values
        if rawScale ~= math.floor(rawScale) and rawScale >= 10 then
            -- Scale corruption detected - rounding to percentage
            rawScale = math.floor(rawScale + 0.5)
            sizing.scale = rawScale
        end
        
        if rawScale < 10 then
            -- Already a decimal (e.g., 1.05)
            scale = rawScale
            -- Scale is already decimal
        else
            -- Percentage (e.g., 100 = 1.0)
            scale = rawScale / 100
            -- Scale converted from percentage
        end
    end
    
    -- Apply final values
    
    -- Apply sizes to all frames
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = self.frames[i]
        if frame then
            frame:SetSize(width, height)
            frame:SetScale(scale)
        end
    end
    
    -- CRITICAL: After resizing, update positions to account for new sizes
    -- This ensures spacing is correct with the new frame dimensions
    if self.UpdateFramePositions then
        self:UpdateFramePositions()
    end
    
    -- CRITICAL FIX: Also refresh module layouts (trinkets, racials, class icons, etc.)
    -- This ensures child elements are positioned correctly relative to the resized frames
    -- Refresh module layouts
    if AC.RefreshTrinketsOtherLayout then
        AC:RefreshTrinketsOtherLayout()
    end
    --[[ OLD CAST BAR SYSTEM - DISABLED
    if AC.RefreshCastBarsLayout then
        AC:RefreshCastBarsLayout()
    end
    --]]
    if AC.RefreshDRLayout then
        AC:RefreshDRLayout()
    end
end

-- ============================================================================
-- CONSOLIDATION: NEW EVENT HANDLERS (ArenaCore patterns)
-- ============================================================================

-- STEALTH HANDLING REMOVED: ArenaFrameStealth.lua now handles ALL stealth/alpha changes
-- This function kept for spec/class icon updates and other non-stealth functionality
function MFM:HandleArenaOpponentUpdate(unit, updateType)
    -- CRITICAL FIX: Block during slider drag to prevent flickering
    if AC._sliderDragActive then
        return
    end
    
    -- CRITICAL: Block battleground events
    if not IsActiveBattlefieldArena() then
        return
    end
    
    if not unit or not updateType then return end
    
    -- CRITICAL: Validate unit exists before processing
    if not UnitExists(unit) then return end
    
    -- Extract arena index (arena1 → 1, arena2 → 2, etc.)
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if not arenaIndex or arenaIndex < 1 or arenaIndex > 3 then return end
    
    local frame = self.frames[arenaIndex]
    if not frame then return end
    
    -- CRITICAL FIX: Apply user's saved texture settings when match starts
    -- This ensures real arena uses the same bar settings as test mode and prep room
    -- Only call once per match (use a flag to prevent repeated calls)
    if not self._texturesAppliedThisMatch then
        if AC.RefreshTexturesLayout then
            AC:RefreshTexturesLayout()
        end
        self._texturesAppliedThisMatch = true
    end
    
    -- Show frame (alpha handled by ArenaFrameStealth.lua)
    if not InCombatLockdown() then
        frame:Show()
    end
    
    -- Update class and spec data
    local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(arenaIndex)
    
    if specID and specID > 0 then
        -- We have spec data - use it for both class and spec icons
        local _, specName, _, specIcon, _, classFile = GetSpecializationInfoByID(specID)
        
        -- Update spec icon
        if frame.specIcon and frame.specIcon.icon and specIcon then
            local db = AC.DB and AC.DB.profile
            local specEnabled = db and db.specIcons and db.specIcons.enabled
            if specEnabled ~= false then
                frame.specIcon.icon:SetTexture(specIcon)
                frame.specIcon:Show()
            else
                frame.specIcon:Hide()
            end
        end
        
        -- Update class icon with real class data
        if frame.classIcon and classFile then
            local db = AC.DB and AC.DB.profile
            local classEnabled = db and db.classIcons and db.classIcons.enabled
            if classEnabled ~= false then
                if frame.classIcon.UpdateClassIcon then
                    frame.classIcon.UpdateClassIcon(classFile)
                    frame.classIcon:Show()
                else
                    -- Fallback for old system compatibility
                    local classIconTexture = frame.classIcon.classIcon or frame.classIcon.icon
                    if classIconTexture then
                        local iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\" .. classFile .. ".tga"
                        classIconTexture:SetTexture(iconPath)
                        
                        if frame.classIcon.overlay then
                            local overlayPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\" .. classFile:lower() .. "overlay.tga"
                            frame.classIcon.overlay:SetTexture(overlayPath, true, true)
                        end
                        frame.classIcon:Show()
                    end
                end
            else
                frame.classIcon:Hide()
            end
        end
    else
        -- No spec data - fallback to UnitClass
        local _, classFile = UnitClass(unit)
        
        -- Hide spec icon if no spec data available
        if frame.specIcon then
            frame.specIcon:Hide()
        end
        
        -- Update class icon with fallback class data
        if frame.classIcon and classFile then
            local db = AC.DB and AC.DB.profile
            local classEnabled = db and db.classIcons and db.classIcons.enabled
            if classEnabled ~= false then
                if frame.classIcon.UpdateClassIcon then
                    frame.classIcon.UpdateClassIcon(classFile)
                    frame.classIcon:Show()
                else
                    -- Fallback for old system compatibility
                    local classIconTexture = frame.classIcon.classIcon or frame.classIcon.icon
                    if classIconTexture then
                        local iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\" .. classFile .. ".tga"
                        classIconTexture:SetTexture(iconPath)
                        
                        if frame.classIcon.overlay then
                            local overlayPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\" .. classFile:lower() .. "overlay.tga"
                            frame.classIcon.overlay:SetTexture(overlayPath, true, true)
                        end
                        frame.classIcon:Show()
                    end
                end
            else
                frame.classIcon:Hide()
            end
        end
    end
    
    -- CRITICAL FIX: Ensure health and mana bars are visible in real arena
    if frame.healthBar then
        frame.healthBar:Show()
        frame.healthBar:SetAlpha(1.0)
    end
    if frame.manaBar then
        frame.manaBar:Show()
        frame.manaBar:SetAlpha(1.0)
    end
    
    -- CRITICAL FIX: Show trinket in real arena (always visible)
    local trinket = frame.trinketIndicator or frame.trinket
    if trinket then
        if trinket.icon then
            local trinketIcon = self:GetUserTrinketIcon()
            trinket.icon:SetTexture(trinketIcon)
            trinket.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        end
        trinket:Show()
    end
    
    -- Update dispels for this unit
    if AC.UpdateDispelFrames then
        C_Timer.After(0.05, function()
            AC:UpdateDispelFrames()
        end)
    end
    
    -- Update trinkets and racials for this unit
    if AC.TrinketsRacials and AC.TrinketsRacials.RefreshFrame then
        AC.TrinketsRacials:RefreshFrame(frame, unit)
    end
    
    -- Update frame data on "seen" event
    if updateType == "seen" then
        if not AC.testModeEnabled then
            self:UpdateName(frame)
        end
        self:UpdateHealth(frame)
        self:UpdatePower(frame)
        
        -- CRITICAL FIX: Re-apply general settings after player data becomes available
        -- This ensures arena labels are properly shown when player names load
        C_Timer.After(0.1, function()
            if AC.ApplyGeneralSettings then
                AC:ApplyGeneralSettings()
            end
        end)
    
    -- CRITICAL FIX: Handle "destroyed" event (player left arena after dying)
    elseif updateType == "destroyed" then
        -- Clear DR icons for this frame (same as death cleanup)
        if frame.drIcons then
            for _, drIcon in pairs(frame.drIcons) do
                if drIcon.Hide then
                    drIcon:Hide()
                end
                if drIcon.cooldown and drIcon.cooldown.Clear then
                    drIcon.cooldown:Clear()
                end
                drIcon.active = false
                drIcon.severity = 0
                drIcon.diminished = nil
                drIcon.reset = 0
                if drIcon.timerText then
                    drIcon.timerText:SetText("")
                end
                if drIcon.stageText then
                    drIcon.stageText:SetText("")
                end
            end
        end
    end
    
    -- CRITICAL FIX: Apply class icon positioning (same as test mode and prep room)
    -- This ensures class icons respect saved positioning and theme settings when gates open
    if AC.RefreshTrinketsOtherLayout then
        AC:RefreshTrinketsOtherLayout()
    end
end

-- Solo Shuffle round transitions (GROUP_ROSTER_UPDATE)
-- STEALTH STATE CLEARING REMOVED: ArenaFrameStealth.lua handles all stealth state
function MFM:HandleSoloShuffleTransition()
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then return end
    
    -- CRITICAL FIX: Only clear DR icons on actual round transitions, not initial arena entry
    -- GROUP_ROSTER_UPDATE fires when entering arena AND between rounds
    -- We only want to clear DRs between rounds, not on initial entry
    if self.isInArena and self._lastRosterCheck then
        -- We're already in arena and this is a roster change = round transition
        -- Clear DR icons for new opponents
        for i = 1, 3 do
            local frame = self.frames[i]
            if frame and frame.drTray then
                -- Do not call RemoveAllTrayItems() in Midnight.
                -- Blizzard's tray manages its own internal state; clearing it here can trigger forbidden table access.
            end
        end
    end
    
    -- Track that we've seen a roster update while in arena
    self._lastRosterCheck = GetTime()
    
    -- CRITICAL FIX: Delay status text reset to run AFTER other cleanup systems
    -- This ensures text isn't cleared by race conditions with other GROUP_ROSTER_UPDATE handlers
    C_Timer.After(0.05, function()
        -- CRITICAL FIX: Reset status text on round transitions
        -- This ensures health/mana text respects the statusText setting for new opponents
        for i = 1, 3 do
            local frame = self.frames[i]
            if frame then
                local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
                local statusTextEnabled = general and general.statusText ~= false
                
                -- Reset health text visibility based on settings
                if frame.healthBar and frame.healthBar.text then
                    if statusTextEnabled then
                        -- CRITICAL: Show and set to 100% for new round (will update when unit exists)
                        frame.healthBar.text:SetText("100%")
                        frame.healthBar.text:Show()
                    else
                        frame.healthBar.text:Hide()
                    end
                end
                
                -- Reset mana text visibility based on settings
                if frame.manaBar and frame.manaBar.text then
                    if statusTextEnabled then
                        -- CRITICAL: Show and set to 100% for new round (will update when unit exists)
                        frame.manaBar.text:SetText("100%")
                        frame.manaBar.text:Show()
                    else
                        frame.manaBar.text:Hide()
                    end
                end
            end
        end
    end)
    
    -- MismatchHandler controls frame visibility via events
    -- ARENA_OPPONENT_UPDATE will fire for new round and handle frame visibility automatically
end

-- Prep room handling (ARENA_PREP_OPPONENT_SPECIALIZATIONS)
function MFM:HandlePrepRoom()
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then 
        return 
    end
    
    -- CRITICAL: Block battleground events
    local isActive = IsActiveBattlefieldArena()
    if not isActive then
        return
    end
    
    -- CRITICAL FIX: Reset trinket/racial tickers and cooldowns for ALL frames (Midnight and non-Midnight)
    -- This ensures solo shuffle rounds properly reset cooldowns
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = self.frames[i]
        if frame then
            -- Reset trinket ticker and cooldown (both Midnight and non-Midnight)
            if frame.trinketIndicator then
                if frame.trinketIndicator.ticker then
                    frame.trinketIndicator.ticker:Cancel()
                    frame.trinketIndicator.ticker = nil
                end
                if frame.trinketIndicator.cooldown then
                    frame.trinketIndicator.cooldown:Clear()
                end
                if frame.trinketIndicator.txt then
                    frame.trinketIndicator.txt:SetText("")
                end
                if frame.trinketIndicator.icon then
                    frame.trinketIndicator.icon:SetDesaturated(false)
                end
            end
            -- Reset racial ticker and cooldown
            if frame.racialIndicator then
                if frame.racialIndicator.ticker then
                    frame.racialIndicator.ticker:Cancel()
                    frame.racialIndicator.ticker = nil
                end
                if frame.racialIndicator.cooldown then
                    frame.racialIndicator.cooldown:Clear()
                end
                if frame.racialIndicator.text then
                    frame.racialIndicator.text:SetText("")
                end
                if frame.racialIndicator.icon then
                    frame.racialIndicator.icon:SetDesaturated(false)
                end
            end
        end
    end
    
    -- CRITICAL FIX: Disable test mode when entering prep room
    -- This prevents test mode data from bleeding into real arena
    if AC.testModeEnabled then
        AC.testModeEnabled = false
        self.isTestMode = false
        print("|cffFFAA00ArenaCore:|r Test mode disabled - entering prep room")
        
        -- CRITICAL PREP ROOM FIX: Clear ALL test mode data immediately
        -- This prevents test mode trinkets, racials, debuffs, and spec icons from appearing in prep room
        for i = 1, MAX_ARENA_ENEMIES do
            local frame = self.frames[i]
            if frame then
                -- Clear trinket test data
                if frame.trinketIndicator then
                    frame.trinketIndicator:Hide()
                    -- CRITICAL FIX: Explicitly hide orange border texture to prevent stale test mode overlay
                    if frame.trinketIndicator.border then
                        frame.trinketIndicator.border:Hide()
                    end
                    if frame.trinketIndicator.cooldown then
                        frame.trinketIndicator.cooldown:Clear()
                    end
                    if frame.trinketIndicator.text then
                        frame.trinketIndicator.text:SetText("")
                    end
                end
                
                -- Clear racial test data
                if frame.racialIndicator then
                    frame.racialIndicator:Hide()
                    -- CRITICAL FIX: Explicitly hide orange border texture to prevent stale test mode overlay
                    if frame.racialIndicator.border then
                        frame.racialIndicator.border:Hide()
                    end
                    if frame.racialIndicator.cooldown then
                        frame.racialIndicator.cooldown:Clear()
                    end
                    if frame.racialIndicator.text then
                        frame.racialIndicator.text:SetText("")
                    end
                    if frame.racialIndicator.ticker then
                        frame.racialIndicator.ticker:Cancel()
                        frame.racialIndicator.ticker = nil
                    end
                end
                
                -- CRITICAL FIX: Clear spec icon test data
                -- This prevents test mode spec icons (e.g., DK) from appearing in prep room
                if frame.specIcon then
                    frame.specIcon:Hide()
                    if frame.specIcon.icon then
                        frame.specIcon.icon:SetTexture(nil)
                    end
                end
                
                -- Clear debuff test data
                if frame.debuffContainer then
                    if frame.debuffContainer.debuffs then
                        for j = 1, #frame.debuffContainer.debuffs do
                            local debuffFrame = frame.debuffContainer.debuffs[j]
                            if debuffFrame then
                                debuffFrame:Hide()
                                debuffFrame:SetAlpha(0)
                                if debuffFrame.cooldown then
                                    debuffFrame.cooldown:Clear()
                                end
                                if debuffFrame.timer then
                                    debuffFrame.timer:SetText("")
                                end
                                if debuffFrame.timerUpdate then
                                    debuffFrame.timerUpdate:Cancel()
                                    debuffFrame.timerUpdate = nil
                                end
                            end
                        end
                    end
                    frame.debuffContainer.testDebuffsActive = false
                    frame.debuffContainer:Hide()
                end
            end
        end
    end
    
    -- CRITICAL FIX: Event-driven prep room
    -- Only show frames for opponents that actually have specs
    -- This handles mismatched teams in prep room (e.g., 2v3 before match starts)
    
    -- CRITICAL FIX: Apply user's saved texture settings ONCE for all frames
    -- This ensures prep room uses the same bar settings as test mode and real arena
    if AC.RefreshTexturesLayout then
        AC:RefreshTexturesLayout()
    end
    
    -- CRITICAL FIX: Single-loop pattern (backup working version)
    -- Check each frame individually for spec data - handles mismatched teams
    for i = 1, 3 do
        local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(i)
        local frame = self.frames[i]
        
        if frame then
            if not specID or specID == 0 then
                -- No opponent in this slot - hide frame
                frame:SetAlpha(0)
                if not InCombatLockdown() then
                    frame:Hide()
                end
            else
                -- Opponent exists in this slot - show frame with spec info
                -- ARCHITECTURAL FIX: Use unified text control system
                if frame.playerName and not AC.testModeEnabled then
                    -- FRAMESORT FIX: Pass frame.unit so FrameSort API can determine visual position
                    AC:SetArenaFrameText(frame, i, "prep_room", frame.unit)
                end
                
                -- Update spec icon
                local _, specName, _, specIcon, _, classFile = GetSpecializationInfoByID(specID)
                if frame.specIcon and specIcon then
                    frame.specIcon.icon:SetTexture(specIcon)
                    frame.specIcon:Show()
                end
                
                -- Update class icon
                if frame.classIcon and classFile then
                    -- CRITICAL FIX: Respect theme setting in prep room (all arena types)
                    local db = AC.DB and AC.DB.profile
                    local theme = db and db.classIcons and db.classIcons.theme or "arenacore"
                    
                    local iconPath
                    if theme == "coldclasses" then
                        -- Midnight Chill theme
                        iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\" .. classFile:lower() .. ".png"
                    else
                        -- ArenaCore Custom theme (default)
                        iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\" .. classFile .. ".tga"
                    end
                    frame.classIcon.icon:SetTexture(iconPath)
                    
                    -- CRITICAL FIX: Update overlay to match detected class (prep room fix)
                    if frame.classIcon.overlay then
                        local overlayPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\" .. classFile:lower() .. "overlay.tga"
                        frame.classIcon.overlay:SetTexture(overlayPath, true, true)
                    end
                    
                    -- CRITICAL FIX: Apply user's saved position and scale in prep room
                    local classIconDB = db and db.classIcons
                    if classIconDB then
                        local pos = classIconDB.positioning or {}
                        local size = classIconDB.sizing or {}
                        
                        -- CRITICAL: Check for theme-specific positioning (The 1500 Special uses RIGHT anchor)
                        local useCompactLayout = false
                        if self.ArenaFrameThemes then
                            local currentTheme = self.ArenaFrameThemes:GetCurrentTheme()
                            local theme = self.ArenaFrameThemes.themes and self.ArenaFrameThemes.themes[currentTheme]
                            if theme and theme.positioning and theme.positioning.compactLayout then
                                useCompactLayout = true
                            end
                        end
                        
                        -- Apply scale FIRST (Bartender4 pattern)
                        local scale = (size.scale or 100) / 100
                        frame.classIcon:SetScale(scale)
                        
                        frame.classIcon:ClearAllPoints()
                        -- CRITICAL FIX: Always use RIGHT to LEFT anchor (consistent with RefreshTrinketsOtherLayout)
                        -- The old code used LEFT to LEFT which caused position drift
                        local xOffset = (pos.horizontal or 0)
                        local yOffset = (pos.vertical or 0)
                        
                        -- NO SCALE COMPENSATION - frame-relative anchoring doesn't need it
                        
                        frame.classIcon:SetPoint("RIGHT", frame, "LEFT", xOffset, yOffset)
                        
                        -- Mark that theme positioning has been applied
                        local currentTheme = self.ArenaFrameThemes and self.ArenaFrameThemes:GetCurrentTheme()
                        frame.classIcon._themePositioned = currentTheme
                    end
                    
                    frame.classIcon:Show()
                end
                
                -- Apply class-based health bar color (ArenaCore exclusive!)
                -- Note: RefreshTexturesLayout is called once at the start of HandlePrepRoom
                if frame.healthBar and classFile and RAID_CLASS_COLORS[classFile] then
                    local classColor = RAID_CLASS_COLORS[classFile]
                    frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
                    -- CRITICAL FIX: Set health to 100% in prep room (units don't exist yet)
                    frame.healthBar:SetMinMaxValues(0, 100)
                    frame.healthBar:SetValue(100)
                    
                    -- CRITICAL FIX: Set health text in prep room
                    if frame.healthBar.text then
                        local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
                        local statusTextEnabled = general and general.statusText ~= false
                        if statusTextEnabled then
                            frame.healthBar.text:SetText("100%")
                            frame.healthBar.text:Show()
                        else
                            frame.healthBar.text:Hide()
                        end
                    end
                end
                
                -- CRITICAL FIX: Set mana bar to 100% in prep room
                if frame.manaBar then
                    frame.manaBar:SetMinMaxValues(0, 100)
                    frame.manaBar:SetValue(100)
                    
                    -- CRITICAL FIX: Apply SPEC-based resource colors (not hardcoded blue!)
                    if classFile and AC.FrameManager and AC.FrameManager.ApplySpecBasedResourceColors then
                        AC.FrameManager:ApplySpecBasedResourceColors(frame, classFile, specID)
                    end
                    
                    -- CRITICAL FIX: Hide mana text in prep room (prevents leaking into arena)
                    if frame.manaBar.text then
                        frame.manaBar.text:SetText("")
                        frame.manaBar.text:Hide()
                    end
                end
                
                -- CRITICAL FIX: Apply class-based border color (matches health bar)
                if frame.border and classFile and RAID_CLASS_COLORS[classFile] then
                    local classColor = RAID_CLASS_COLORS[classFile]
                    frame.border:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
                end
                
                -- CRITICAL FIX: Hide immunity glows in prep room (test mode artifacts)
                if frame.immunityGlow then
                    frame.immunityGlow:Hide()
                    if frame.immunityGlowAnim then
                        frame.immunityGlowAnim:Stop()
                    end
                end
                
                -- CRITICAL FIX: Hide absorbs in prep room (units don't exist yet)
                if frame.totalAbsorb then frame.totalAbsorb:Hide() end
                if frame.totalAbsorbOverlay then frame.totalAbsorbOverlay:Hide() end
                if frame.overAbsorbGlow then frame.overAbsorbGlow:Hide() end
                
                -- CRITICAL FIX: Hide auras/debuffs in prep room (units don't exist yet)
                if frame.auras then
                    for _, auraFrame in pairs(frame.auras) do
                        if auraFrame and auraFrame.Hide then
                            auraFrame:Hide()
                        end
                    end
                end
                
                -- CRITICAL FIX: Show trinket in prep room (always visible)
                local trinket = frame.trinketIndicator or frame.trinket
                if trinket then
                    if trinket.icon then
                        local trinketIcon = self:GetUserTrinketIcon()
                        trinket.icon:SetTexture(trinketIcon)
                        trinket.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                    end
                    trinket:Show()
                end
                
                -- CRITICAL FIX: Ensure health and mana bars are visible
                if frame.healthBar then
                    frame.healthBar:Show()
                    frame.healthBar:SetAlpha(1.0)
                end
                if frame.manaBar then
                    frame.manaBar:Show()
                    frame.manaBar:SetAlpha(1.0)
                end
                
                -- CRITICAL FIX: Set 0.5 opacity in prep room for stealth detection
                frame:SetAlpha(0.5)
                
                -- Show frame
                if not InCombatLockdown() then
                    frame:Show()
                end
            end
        end
    end
    
    -- CRITICAL FIX: Apply class icon positioning (same as test mode)
    -- This ensures class icons respect saved positioning and theme settings
    if AC.RefreshTrinketsOtherLayout then
        AC:RefreshTrinketsOtherLayout()
    end
    
    -- CRITICAL FIX: Apply general settings to show status text "100%" placeholder in prep room
    -- This matches the old working version's behavior
    if AC.ApplyGeneralSettings then
        AC:ApplyGeneralSettings()
    end
    
    -- FRAMESORT INTEGRATION: Trigger reordering after specs are detected
    -- This ensures first prep room respects FrameSort settings (e.g., healer on top)
    local enableFrameSortIntegration = AC.DB and AC.DB.profile 
        and AC.DB.profile.arenaFrames 
        and AC.DB.profile.arenaFrames.general 
        and AC.DB.profile.arenaFrames.general.enableFrameSortIntegration
    
    if enableFrameSortIntegration then
        -- Delay slightly to let FrameSort process the specs
        C_Timer.After(0.1, function()
            -- Trigger FrameSort reordering
            if MFM and MFM.UpdateFramePositions then
                MFM:UpdateFramePositions()
            end
            
            -- Refresh arena numbers
            if AC.RefreshArenaNumbers then
                AC:RefreshArenaNumbers()
            end
            
            -- Refresh "Arena 1/2/3" labels
            if AC.RefreshArenaLabels then
                AC:RefreshArenaLabels()
            end
        end)
    end
end

-- Unit health updates
function MFM:UpdateUnitHealth(unit)
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if not arenaIndex then return end
    
    local frame = self.frames[arenaIndex]
    if not frame or not frame.healthBar then return end
    
    -- Declare health/maxHealth variables for use in text updates below
    local health, maxHealth
    
    -- CRITICAL: StatusBar:SetValue() and SetMinMaxValues() accept secret values (protected operations)
    if AC.Midnight and AC.Midnight.isMidnight then
        -- Midnight: Both SetMinMaxValues and SetValue accept secret values
        frame.healthBar:SetMinMaxValues(0, UnitHealthMax(unit))
        frame.healthBar:SetValue(UnitHealth(unit))
        -- Leave health/maxHealth nil for text display logic below
        health = nil
        maxHealth = nil
    else
        health = UnitHealth(unit) or 0
        maxHealth = UnitHealthMax(unit) or 1
        frame.healthBar:SetMinMaxValues(0, maxHealth)
        frame.healthBar:SetValue(health)
    end
    
    -- CRITICAL FIX: Update health text
    if frame.healthBar.text then
        local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
        local statusTextEnabled = general and general.statusText ~= false  -- Default ON
        local usePercentage = general and general.usePercentage ~= false
        
        if statusTextEnabled then
            if usePercentage then
                -- Midnight compatibility: Use new percentage APIs in Midnight
                if AC.Midnight and AC.Midnight.isMidnight then
                    -- Use CurveConstants.ScaleTo100 to get non-secret percentage value
                    local percent = UnitHealthPercent(unit, nil, CurveConstants.ScaleTo100)
                    frame.healthBar.text:SetFormattedText("%0.f%%", percent)
                else
                    -- Use traditional health calculation for non-Midnight
                    if maxHealth and maxHealth > 0 and health and health >= 0 then
                        local percent = math.ceil((health / maxHealth) * 100)
                        frame.healthBar.text:SetText(percent .. "%")
                    else
                        frame.healthBar.text:SetText("")
                    end
                end
            else
                -- Use AbbreviateLargeNumbers for shorter display
                local safeHealth = health and health >= 0 and health or 0
                frame.healthBar.text:SetText(AbbreviateLargeNumbers(safeHealth))
            end
            frame.healthBar.text:Show()
        else
            frame.healthBar.text:Hide()
        end
    end
    
    -- DEATH ICON SYSTEM: Update death state
    self:UpdateDeathIcon(frame, unit)
end

-- Unit power updates
function MFM:UpdateUnitPower(unit)
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if not arenaIndex then return end
    
    local frame = self.frames[arenaIndex]
    if not frame or not frame.manaBar then return end
    
    -- CRITICAL: StatusBar:SetValue() and SetMinMaxValues() accept secret values
    if AC.Midnight and AC.Midnight.isMidnight then
        -- Midnight: Both SetMinMaxValues and SetValue accept secret values
        frame.manaBar:SetMinMaxValues(0, UnitPowerMax(unit))
        frame.manaBar:SetValue(UnitPower(unit))
        
        if frame.manaBar.text then
            -- CRITICAL: Disable mana text in Midnight due to UnitPowerPercent API bug
            frame.manaBar.text:Hide()
        end
    else
        -- Non-Midnight: Use standard power APIs
        local power = UnitPower(unit) or 0
        local maxPower = UnitPowerMax(unit) or 1
        frame.manaBar:SetMinMaxValues(0, maxPower)
        frame.manaBar:SetValue(power)
        
        -- CRITICAL FIX: Update mana/power text
        if frame.manaBar.text then
            local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
            local statusTextEnabled = general and general.statusText ~= false  -- Default ON
            local usePercentage = general and general.usePercentage ~= false
            
            -- CRITICAL FIX: Hide text in prep room when unit doesn't exist yet
            if not UnitExists(unit) then
                frame.manaBar.text:Hide()
            elseif statusTextEnabled then
                if usePercentage then
                    local percent = maxPower > 0 and math.ceil((power / maxPower) * 100) or 0
                    frame.manaBar.text:SetText(percent .. "%")
                else
                    -- Use AbbreviateLargeNumbers for shorter display
                    frame.manaBar.text:SetText(AbbreviateLargeNumbers(power))
                end
                frame.manaBar.text:Show()
            else
                frame.manaBar.text:Hide()
            end
        end
    end
end

-- DEATH ICON SYSTEM: Update death icon visibility based on unit life state
function MFM:UpdateDeathIcon(frame, unit)
    if not frame or not frame.deathIconFrame then return end
    
    -- Check if unit is dead or ghost (but NOT feign death)
    local isDead = UnitIsDeadOrGhost(unit)
    
    -- CRITICAL: Exclude Feign Death from showing death icon
    if isDead then
        -- Use ArenaCore's Feign Death detector if available
        if AC.FeignDeathDetector and AC.FeignDeathDetector.IsFeigning then
            if AC.FeignDeathDetector:IsFeigning(unit) then
                isDead = false -- Don't show death icon for Feign Death
            end
        else
            -- Fallback: Check for Feign Death aura manually
            -- CRITICAL: AuraUtil.FindAuraByName is PROTECTED in Midnight - cannot be called
            -- Skip this check in Midnight to avoid ADDON_ACTION_BLOCKED errors
            if not (AC.Midnight and AC.Midnight.isMidnight) then
                local feignSpellName = GetSpellName and GetSpellName(5384) or (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(5384))
                if feignSpellName and AuraUtil and AuraUtil.FindAuraByName then
                    local auraData = AuraUtil.FindAuraByName(feignSpellName, unit, "HELPFUL")
                    if auraData then
                        isDead = false -- Don't show death icon for Feign Death
                    end
                end
            end
        end
    end
    
    -- Show/hide death icon based on death state
    frame.deathIconFrame:SetShown(isDead)
    
    -- CLEANUP: Reset DR icons when enemy dies
    if isDead then
        -- Clear all DR cooldowns for this frame
        local drModule = GetDRModule()
        if drModule and drModule.ResetFrame then
            drModule:ResetFrame(frame)
        elseif frame.drIcons then
            -- Fallback: Manually clear DR cooldowns AND hide icons
            for _, drIcon in pairs(frame.drIcons) do
                -- CRITICAL FIX: Hide the DR icon frame (not just clear cooldown)
                -- Hide the DR icon frame
                if drIcon.Hide then
                    drIcon:Hide()
                end
                
                -- Clear cooldown spiral
                if drIcon.cooldown and drIcon.cooldown.Clear then
                    drIcon.cooldown:Clear()
                end
                
                -- Reset state
                drIcon.active = false
                drIcon.severity = 0
                drIcon.diminished = nil
                drIcon.reset = 0
                
                -- Clear text displays
                if drIcon.timerText then
                    drIcon.timerText:SetText("")
                end
                if drIcon.stageText then
                    drIcon.stageText:SetText("")
                end
            end
        end
    end
end

-- Unit name updates
function MFM:UpdateUnitName(unit)
    -- CRITICAL FIX: Block during slider drag to prevent flickering
    if AC._sliderDragActive then
        return
    end
    
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if not arenaIndex then return end
    
    local frame = self.frames[arenaIndex]
    if not frame or not frame.playerName then return end
    
    -- CRITICAL FIX: Properly detect prep room vs live arena
    -- Prep room: GetNumArenaOpponentSpecs() > 0 BUT units don't exist yet
    -- Live arena: GetNumArenaOpponentSpecs() > 0 AND units exist
    local _, instanceType = IsInInstance()
    local mode = "live_arena"
    
    if instanceType == "arena" then
        local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs()
        -- Only treat as prep room if we have specs but unit doesn't exist
        if numOpponents and numOpponents > 0 and not UnitExists(unit) then
            mode = "prep_room"
        end
    end
    
    AC:SetArenaFrameText(frame, arenaIndex, mode, unit)
end

-- ============================================================================
-- UNIFIED TEXT CONTROL SYSTEM - ARCHITECTURAL FIX
-- ============================================================================

-- Single source of truth for all arena frame text - eliminates competing text systems
function AC:SetArenaFrameText(frame, arenaIndex, mode, unit)
    if not frame or not frame.playerName or not arenaIndex then return end
    
    -- CRITICAL FIX: Ensure proper database access to prevent nil 'general' error
    local db = AC.DB and AC.DB.profile
    local general = db and db.arenaFrames and db.arenaFrames.general or {}
    local showArenaLabels = general.showArenaLabels == true
    local enableFrameSortIntegration = general.enableFrameSortIntegration == true
    
    -- FRAMESORT INTEGRATION: Get visual position if enabled
    local displayIndex = arenaIndex  -- Default to creation index
    
    if enableFrameSortIntegration and unit then
        local fs = FrameSortApi and FrameSortApi.v3
        
        if fs then
            -- Check if FrameSort arena sorting is enabled (inline check)
            local arenaEnabled = fs.Options and fs.Options:GetEnabled("EnemyArena")
            
            if arenaEnabled then
                -- Get visual frame number from FrameSort API
                local frameNumber = fs.Frame:FrameNumberForUnit(unit)
                
                if frameNumber then
                    displayIndex = frameNumber  -- Use FrameSort visual position
                end
            end
        end
    end
    
    local finalText
    
    if mode == "prep_room" then
        -- ALWAYS show "Arena X" in prep room regardless of user setting
        -- Use FrameSort visual position if integration enabled
        finalText = "Arena " .. displayIndex
    elseif mode == "live_arena" then
        if showArenaLabels then
            -- User has Arena 1/2/3 Names enabled
            -- Use FrameSort visual position if integration enabled
            finalText = "Arena " .. displayIndex
        else
            -- User has Show Names enabled - use real player names
            local playerName = unit and UnitName(unit)
            
            -- Both Midnight and non-Midnight: UnitName returns actual names (sArena pattern)
            -- Wrap comparisons in pcall to handle potential secret values
            local isValidName = false
            if playerName then
                local success = pcall(function()
                    isValidName = type(playerName) == "string" and playerName ~= "" and playerName ~= "Unknown"
                end)
                if not success then isValidName = false end
            end
            
            if isValidName then
                -- Valid player name - handle server name display setting
                local showArenaServerNames = general.showArenaServerNames
                
                if not showArenaServerNames then
                    -- Remove server name if setting is OFF (default)
                    local dashPos = playerName:find("-")
                    if dashPos then
                        playerName = playerName:sub(1, dashPos - 1)
                    end
                end
                
                finalText = playerName
            else
                -- Stealthed or unknown - fallback to "Arena X"
                finalText = "Arena " .. displayIndex
            end
        end
    elseif mode == "test_mode" then
        if showArenaLabels then
            -- User has Arena 1/2/3 Names enabled
            finalText = "Arena " .. displayIndex
        else
            -- User has Show Names enabled - use test names with server name support
            local testNames = {"Survivable", "Patymorph", "Easymodex"}
            local playerName = testNames[arenaIndex] or ("TestPlayer" .. arenaIndex)
            
            -- Apply server name if enabled (preserve existing functionality)
            local showServerNames = general.showArenaServerNames
            if showServerNames then
                local serverName = "TestServer"
                finalText = playerName .. "-" .. serverName
            else
                finalText = playerName
            end
        end
    else
        -- Default fallback
        finalText = "Arena " .. displayIndex
    end
    
    -- CRITICAL: Only set text if it's different (prevents flicker)
    local currentText = frame.playerName:GetText() or ""
    if currentText ~= finalText then
        frame.playerName:SetText(finalText)
    end
end

-- Match state changes
function MFM:HandleMatchStateChange()
    -- MismatchHandler now controls frame visibility via events
    -- ARENA_OPPONENT_UPDATE and ARENA_PREP_OPPONENT_SPECIALIZATIONS handle everything
    -- No manual frame showing needed
end

-- Unit targetable changes
function MFM:UpdateUnitTargetable(unit)
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if not arenaIndex then return end
    
    local frame = self.frames[arenaIndex]
    if not frame then return end
    
    -- Update frame visibility based on targetable state
    if UnitExists(unit) and not InCombatLockdown() then
        frame:Show()
    end
end

function MFM:UpdateArenaState()
    -- Update arena detection and frame visibility
    self:CheckArenaState()
    
    -- MismatchHandler now controls frame visibility via events
    -- ARENA_OPPONENT_UPDATE and ARENA_PREP_OPPONENT_SPECIALIZATIONS handle everything
    -- No manual frame showing needed
    if not self.isInArena and not self.isTestMode then
        self:HideAllFrames()
    end
end

-- ============================================================================
-- 6. VISUAL COMPONENT CREATORS  
-- ============================================================================
-- PHASE 1.3: FrameManager duplicate functions removed (kept MFM versions at lines ~1770-2037)
-- Removed: CreateDebuffContainer, CreateClassIcon, CreateTrinket, CreateRacial, CreateSpecIcon
-- These are exact duplicates of the MFM (MasterFrameManager) versions
-- ============================================================================

-- Kept: CreateTargetIndicator and CreateDRIcon (not duplicated in MFM)
-- Note: Duplicate FrameManager functions removed below (lines 2701-2929)

-- PHASE 1.3: FrameManager duplicate functions removed (220 lines) ✅ COMPLETE
-- Removed: CreateDebuffContainer, CreateClassIcon, CreateTrinket, CreateRacial, CreateSpecIcon
-- These were exact duplicates of MFM versions at lines 1770-2037
-- Kept only: CreateTargetIndicator and CreateDRIcon (unique to FrameManager)

function FrameManager:CreateTargetIndicator(parent)
    local ind = CreateFrame("Frame", nil, parent)
    ind:SetSize(8, 16)
    ind:SetPoint("RIGHT", parent, "LEFT", 4, 0)
    ind:SetAlpha(0) -- Hidden by default
    
    local t = ind:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints()
    t:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Textures\\target_arrow.tga")
    t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    ind.texture = t
    return ind
end

function FrameManager:CreateDRIcon(parent, category)
    -- Create DR icon using round styling like trinkets/racials
    -- CRITICAL FIX: Ensure drContainer exists, or parent directly to frame
    local parentFrame = parent.drContainer or parent
    local dr = CreateFrame("Frame", nil, parentFrame)
    dr:SetSize(22, 22)
    dr.category = category
    dr.severity = 0  -- CRITICAL: Start at 0, TrackDRApplication will increment to 1
    dr.active = false
    dr:Hide() -- Hidden by default
    
    -- SOLID ORANGE BACKGROUND: Create multiple layers of the same rounded texture for opacity
    -- Layer 1: Base orange layer
    local solidBackground1 = dr:CreateTexture(nil, "BACKGROUND")
    solidBackground1:SetAllPoints() -- Same size as frame (22x22)
    solidBackground1:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\orangeoverlay.tga")
    solidBackground1:SetTexCoord(0, 1, 0, 1)
    solidBackground1:SetVertexColor(1, 0.4, 0, 1) -- Bright orange
    
    -- Layer 2: Second orange layer for more opacity
    local solidBackground2 = dr:CreateTexture(nil, "BACKGROUND", nil, 1)
    solidBackground2:SetAllPoints()
    solidBackground2:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\orangeoverlay.tga")
    solidBackground2:SetTexCoord(0, 1, 0, 1)
    solidBackground2:SetVertexColor(1, 0.3, 0, 0.8) -- Slightly different orange for layering
    
end
-- ENHANCED: Update DR icon positions with comprehensive test mode safeguards
function AC:UpdateDRPositions(frame)
    -- print("|cffFF00FF[DR POSITION]|r UpdateDRPositions called")
    
    -- Position DR icons in both test mode and live arena
    if not frame then 
        -- print("|cffFF0000[DR POSITION]|r No frame provided!")
        return 
    end
    
    local db = (AC.DB and AC.DB.profile and AC.DB.profile.diminishingReturns)
    if not db then 
        -- print("|cffFF0000[DR POSITION]|r No DR database!")
        return 
    end
    
    -- Check if DR is enabled (nil or true = enabled, false = disabled)
    local enabled = (db.enabled ~= false)
    if not enabled then
        -- print("|cffFFAA00[DR POSITION]|r DR tracking disabled in settings")
        if frame.drTray then
            pcall(function()
                frame.drTray:Hide()
            end)
        end
        return
    end

    if (AC.Midnight and AC.Midnight.isMidnight) and frame.drTray then
        -- print("|cff00FF00[DR POSITION]|r Midnight detected, positioning DR tray for frame " .. tostring(frame.id or "?"))
        local pos = db.positioning or {}
        local sizeCfg = db.sizing or {}
        local rowsCfg = db.rows or {}

        local drHorizontal = pos.horizontal or 0
        local drVertical = pos.vertical
        if drVertical == nil then drVertical = 0 end

        local iconSize = tonumber(sizeCfg.size) or 22
        local stageSize = tonumber(sizeCfg.stageFontSize) or 8

        local growthEnum = rowsCfg.growthDirection
        if growthEnum == nil then growthEnum = 4 end

        -- CRITICAL FIX: Use sArena's positioning approach
        -- Position the TRAY with proper anchor point, let Blizzard's Layout() handle icon spacing
        local anchorPoint
        if growthEnum == 4 then
            anchorPoint = "RIGHT"  -- Left growth (icons grow left from anchor)
        elseif growthEnum == 3 then
            anchorPoint = "LEFT"   -- Right growth (icons grow right from anchor)
        elseif growthEnum == 1 then
            anchorPoint = "RIGHT"  -- Up growth (use RIGHT anchor)
        elseif growthEnum == 2 then
            anchorPoint = "RIGHT"  -- Down growth (use RIGHT anchor)
        else
            anchorPoint = "RIGHT"
        end
        
        -- Calculate offset like sArena: half icon size to center the first icon
        local offset = (iconSize / 2)
        local trayX = drHorizontal + offset
        local trayY = drVertical

        pcall(function()
            frame.drTray:ClearAllPoints()
            frame.drTray:SetPoint(anchorPoint, frame, "CENTER", trayX, trayY)
            -- print("|cff00FF00[DR POSITION]|r Tray positioned at " .. anchorPoint .. " with offset (" .. trayX .. ", " .. trayY .. ")")
            
            if frame.drTray.SetIsInEditMode then
                frame.drTray:SetIsInEditMode(AC.testModeEnabled == true)
                -- print("|cff00FF00[DR POSITION]|r Edit mode set to: " .. tostring(AC.testModeEnabled))
            end
            
            if frame.drTray.UpdateShownState then
                frame.drTray:UpdateShownState()
                -- print("|cff00FF00[DR POSITION]|r Called UpdateShownState()")
            else
                frame.drTray:Show()
                -- print("|cff00FF00[DR POSITION]|r Called Show()")
            end
            
            -- print("|cff00FF00[DR POSITION]|r Tray visibility: " .. tostring(frame.drTray:IsShown()))
        end)

        local children
        pcall(function()
            children = { frame.drTray:GetChildren() }
        end)

        if children then
            for _, item in ipairs(children) do
                pcall(function()
                    item:SetSize(iconSize, iconSize)

                    local immunity = item.ImmunityIndicator
                    if immunity and immunity.SetSize then
                        immunity:SetSize(iconSize, iconSize)
                    end

                    if item.ACBorder == nil then
                        item.ACBorder = item:CreateTexture(nil, "OVERLAY", nil, 6)
                        item.ACBorder:SetTexture("Interface/AddOns/ArenaCore/Media/Classicons/Overlays/orangeoverlay.tga")
                        item.ACBorder:SetAllPoints(item)
                    else
                        item.ACBorder:SetAllPoints(item)
                    end

                    if item.ACCStageText == nil then
                        item.ACCStageText = item:CreateFontString(nil, "OVERLAY")
                        item.ACCStageText:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -2, 2)
                    end

                    if AC.SafeSetFont then
                        AC.SafeSetFont(item.ACCStageText, AC.FONT_PATH, stageSize, "OUTLINE")
                    else
                        item.ACCStageText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", stageSize, "OUTLINE")
                    end

                    local showStage = db.showStageIndicators
                    if showStage == nil then showStage = true end

                    local severity = item._acSeverity or 1
                    if item._acIsImmune then
                        severity = 3
                    end

                    if showStage then
                        local capped = math.min(severity, 3)
                        item.ACCStageText:SetText(capped .. "/3")
                        if capped == 1 then
                            item.ACCStageText:SetTextColor(0, 1, 0, 1)
                        elseif capped == 2 then
                            item.ACCStageText:SetTextColor(1, 1, 0, 1)
                        else
                            item.ACCStageText:SetTextColor(1, 0, 0, 1)
                        end
                        item.ACCStageText:Show()
                    else
                        item.ACCStageText:Hide()
                    end

                    if db.colorCodedBorders then
                        if severity == 1 then
                            item.ACBorder:SetVertexColor(0, 1, 0, 1)
                        elseif severity == 2 then
                            item.ACBorder:SetVertexColor(1, 1, 0, 1)
                        else
                            item.ACBorder:SetVertexColor(1, 0, 0, 1)
                        end
                    else
                        item.ACBorder:SetVertexColor(1, 0.4, 0, 1)
                    end
                end)
            end

            pcall(function()
                if frame.drTray.Layout then
                    frame.drTray:Layout()
                end
            end)
        end
        return
    end
    
    -- DEBUG: Positioning DR icons
    -- print("|cff00FF00[DR POSITION]|r Positioning DR icons...")

    local pos = db.positioning or {}
    local sizeCfg = db.sizing or {}
    local rowsCfg = (db.rows or {})
    local mode = (rowsCfg.stackingMode == "stacked") and "Stacked" or "Straight"
    local spacing = tonumber(pos.spacing) or 5
    local iconSize = tonumber(sizeCfg.size) or 22

    -- Collect a stable-ordered list of DR icon frames to position
    local drTable = frame.drIcons or {}
    -- If in test mode and we created test icons, also consider them
    local isTest = AC.testModeEnabled and frame.testDRIcons
    if isTest then drTable = frame.testDRIcons end

    -- Prefer ROWS growthDirection (numeric: 1=Up, 2=Down, 3=Left, 4=Right)
    local growthEnum = rowsCfg.growthDirection
    local growth = pos.growthDirection
    if growthEnum == 1 then
      growth = "Up"
    elseif growthEnum == 2 then
      growth = "Down"
    elseif growthEnum == 3 then
      growth = "Left"
    elseif growthEnum == 4 then
      growth = "Right"
    end
    if not growth then
      growth = "Right"
    end

  -- DYNAMIC POSITIONING: Check if enabled (default true)
  local dynamicPositioning = (rowsCfg.dynamicPositioning ~= false)
  
  local ordered = {}
  for key, f in pairs(drTable) do
    -- CRITICAL FIX: Always include all DR icons for positioning
    -- Dynamic positioning affects ANIMATION, not which icons get positioned
    -- This fixes the bug where icons in real arena don't get positioned at all
    if f then 
      table.insert(ordered, {key=key, frame=f})
    end
  end
  
  -- PRIORITY ORDER: stun, disorient, silence, incap, root, disarm, knockback
  local priorityOrder = {
    stun = 1,
    disorient = 2,
    silence = 3,
    incapacitate = 4,
    root = 5,
    disarm = 6,
    knockback = 7
  }
  
  -- Sort by priority order (stun first, then disorient, etc.)
  table.sort(ordered, function(a,b) 
    local aPriority = priorityOrder[tostring(a.key)] or 999
    local bPriority = priorityOrder[tostring(b.key)] or 999
    if aPriority ~= bPriority then
      return aPriority < bPriority
    end
    return tostring(a.key) < tostring(b.key) -- Alphabetical fallback
  end)

  if dynamicPositioning then
    local visible = {}
    for _, item in ipairs(ordered) do
      local iconFrame = item.frame
      if iconFrame and iconFrame.IsShown and iconFrame:IsShown() then
        table.insert(visible, item)
      end
    end
    ordered = visible
  end

  if #ordered == 0 then return end

  -- Base anchor position with user offsets
  local baseX = (pos.horizontal or 0)
  local baseY = (pos.vertical or 0)

  if mode == "Straight" then
    -- Straight line mode - simple positioning based on growth direction
    for idx, item in ipairs(ordered) do
      local iconFrame = item.frame
      
      local offset = (idx - 1) * (iconSize + spacing)
      local point, relativePoint, x, y

      if growth == "Right" then
        -- Icons extend to the left from the right edge
        point, relativePoint, x, y = "TOPRIGHT", "TOPRIGHT", baseX - offset, baseY
      elseif growth == "Left" then
        -- Icons extend to the right from the left edge
        point, relativePoint, x, y = "TOPLEFT", "TOPLEFT", baseX + offset, baseY
      elseif growth == "Up" then
        -- Icons extend downward from the top
        point, relativePoint, x, y = "TOPRIGHT", "TOPRIGHT", baseX, baseY - offset
      elseif growth == "Down" then
        -- Icons extend upward from the bottom
        point, relativePoint, x, y = "BOTTOMRIGHT", "BOTTOMRIGHT", baseX, baseY + offset
      end
      
      -- CRITICAL FIX: Disable broken animation system that causes drift
      -- The Translation animation is ADDITIVE and was causing icons to move towards center
      -- Always use instant positioning for reliability
      iconFrame:ClearAllPoints()
      iconFrame:SetPoint(point, frame, relativePoint, x, y)
      
      -- FUTURE: If animation is desired, use Alpha fade instead of Translation
      -- Translation animations are buggy with relative positioning
    end
    return
  end

  -- Stacking Rows mode: 4 on top, 3 on bottom
  local topCount = math.min(4, #ordered)
  local bottomCount = math.max(0, math.min(3, #ordered - topCount))

  -- Calculate row widths
  local function rowWidth(n)
    if n <= 0 then return 0 end
    return (n * iconSize) + ((n - 1) * spacing)
  end

  local topRowWidth = rowWidth(topCount)
  local bottomRowWidth = rowWidth(bottomCount)

  -- Position top row (first 4 icons)
  for i = 1, topCount do
    local item = ordered[i]
    local iconFrame = item.frame
    iconFrame:ClearAllPoints()

    -- Position within the top row
    local posInRow = (i - 1) * (iconSize + spacing)

    if growth == "Right" then
      -- Top row extends left from right edge
      iconFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", baseX - posInRow, baseY)
    elseif growth == "Left" then
      -- Top row extends right from left edge
      iconFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", baseX + posInRow, baseY)
    elseif growth == "Up" then
      -- Top row extends down from top
      iconFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", baseX - posInRow, baseY)
    elseif growth == "Down" then
      -- Top row extends up from bottom
      iconFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", baseX - posInRow, baseY)
    end
  end

  -- Position bottom row (next 3 icons) - aligned under the start of top row
  for j = 1, bottomCount do
    local item = ordered[topCount + j]
    local iconFrame = item.frame
    iconFrame:ClearAllPoints()

    -- Position within the bottom row
    local posInRow = (j - 1) * (iconSize + spacing)
    local rowOffset = iconSize + spacing -- Distance between rows

    if growth == "Right" then
      -- Bottom row starts under the rightmost icon of top row
      iconFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", baseX - posInRow, baseY - rowOffset)
    elseif growth == "Left" then
      -- Bottom row starts under the leftmost icon of top row
      iconFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", baseX + posInRow, baseY - rowOffset)
    elseif growth == "Up" then
      -- Bottom row is to the right of top row
      iconFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", baseX - posInRow - topRowWidth - spacing, baseY)
    elseif growth == "Down" then
      -- Bottom row is to the right of top row
      iconFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", baseX - posInRow - topRowWidth - spacing, baseY)
    end
  end
end


-- ENHANCED: RefreshMoreGoodiesLayout with test mode awareness
function AC:RefreshMoreGoodiesLayout()
    -- Allow refresh in test mode for real-time preview
    
    -- Get frames from unified system
    local frames = GetArenaFrames()
    if not frames and AC.FrameManager and AC.FrameManager.GetFrames then
        frames = AC.FrameManager:GetFrames()
    end

  -- Check if absorbs feature is enabled (matches Absorbs module logic)
  local moreGoodiesDB = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies
  local absorbsEnabled = true -- Default to true if setting doesn't exist
  if moreGoodiesDB and moreGoodiesDB.absorbs then
    absorbsEnabled = moreGoodiesDB.absorbs.enabled ~= false
  end
  
  -- MoreGoodies refresh
  if AC.Absorbs and AC.Absorbs.RefreshAll then
    AC.Absorbs:RefreshAll()
  end
  
  -- CRITICAL FIX: Refresh immunity glows when absorbs checkbox changes
  if AC.ImmunityTracker then
    if absorbsEnabled then
      -- Absorbs enabled - refresh all immunity glows
      if AC.ImmunityTracker.RefreshAll then
        AC.ImmunityTracker:RefreshAll()
      end
    else
      -- Absorbs disabled - hide all immunity glows
      if AC.ImmunityTracker.HideAll then
        AC.ImmunityTracker:HideAll()
      end
    end
  end
  
  -- CRITICAL FIX: Hide/show shield textures when absorbs checkbox changes
  if AC.Absorbs then
    if absorbsEnabled then
      -- Absorbs enabled - show lines if in test mode
      if AC.testModeEnabled and AC.Absorbs.ForceShowLines then
        AC.Absorbs:ForceShowLines()
      end
    else
      -- Absorbs disabled - hide all shield textures
      if AC.Absorbs.HideLines then
        AC.Absorbs:HideLines()
      end
      -- Also hide live absorb textures
      for i = 1, 3 do
        if AC.Absorbs.HideAbsorbLines then
          AC.Absorbs:HideAbsorbLines(i)
        end
      end
    end
  end
  
  -- CRITICAL FIX: Re-apply test mode data after refresh if in test mode
  -- The refresh above calls UpdateAbsorbBar which hides test absorbs/glows
  -- We need to re-apply the test data to show them again
  if AC.testModeEnabled and absorbsEnabled then
    local MFM = _G.ArenaCore and _G.ArenaCore.MasterFrameManager
    if MFM and MFM.ApplyTestData then
      MFM:ApplyTestData()
    end
  end

  -- 2) Party class indicators
  if AC.UpdatePartyClassIndicators then
    AC:UpdatePartyClassIndicators()
  end
end

-- ENHANCED: Component-specific clear helpers for better maintainability
local function ClearHealthBars(frame)
    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, 100)
        frame.healthBar:SetValue(100)
        -- CRITICAL FIX: Respect statusText setting when clearing
        if frame.healthBar.text then
            local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
            local statusTextEnabled = general and general.statusText ~= false
            if statusTextEnabled then
                frame.healthBar.text:SetText("100%")
                frame.healthBar.text:Show()
            else
                frame.healthBar.text:Hide()
            end
        end
    end
    
    if frame.manaBar then
        frame.manaBar:SetMinMaxValues(0, 100)
        frame.manaBar:SetValue(100)
        -- CRITICAL FIX: Respect statusText setting when clearing
        if frame.manaBar.text then
            local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
            local statusTextEnabled = general and general.statusText ~= false
            if statusTextEnabled then
                frame.manaBar.text:SetText("100%")
                frame.manaBar.text:Show()
            else
                frame.manaBar.text:Hide()
            end
        end
    end
end

local function ClearIconsAndIndicators(frame)
    -- Clear class icon and spec chips
    if frame.classIcon then
        if frame.classIcon.icon then frame.classIcon.icon:SetTexture(nil) end
        if frame.classIcon.overlay then frame.classIcon.overlay:SetTexture(nil) end
        if frame.classIcon.background then frame.classIcon.background:SetVertexColor(1, 1, 1, 1) end
        if frame.classIcon.specChip then
            frame.classIcon.specChip:Hide()
            if frame.classIcon.specChip.icon then frame.classIcon.specChip.icon:SetTexture(nil) end
        end
    end
    
    -- Clear trinket and racial indicators
    if frame.trinketIndicator then
        if frame.trinketIndicator.texture then frame.trinketIndicator.texture:SetTexture(nil) end
        if frame.trinketIndicator.cooldown then frame.trinketIndicator.cooldown:Clear() end
        frame.trinketIndicator:Hide()
    end
    
    if frame.racialIndicator then
        if frame.racialIndicator.texture then frame.racialIndicator.texture:SetTexture(nil) end
        if frame.racialIndicator.cooldown then frame.racialIndicator.cooldown:Clear() end
        frame.racialIndicator:Hide()
    end
    
    -- CRITICAL FIX: Clear death icon to prevent leaks
    if frame.deathIconFrame then
        frame.deathIconFrame:Hide()
    end
end

local function ClearDebuffsAndDR(frame)
    -- Clear all debuffs/auras
    if frame.debuffContainer and frame.debuffContainer.debuffs then
        for _, debuff in pairs(frame.debuffContainer.debuffs) do
            if debuff then
                debuff:Hide()
                if debuff.icon then debuff.icon:SetTexture(nil) end
                if debuff.cooldown then debuff.cooldown:Clear() end
            end
        end
        wipe(frame.debuffContainer.debuffs)
    end
    
    -- Clear all DR (Diminishing Returns) icons
    if frame.drIcons then
        for category, dr in pairs(frame.drIcons) do
            if dr then
                dr:Hide()
                if dr.icon then dr.icon:SetTexture(nil) end
                if dr.cooldown then 
                    dr.cooldown.duration = 0
                    dr.cooldown.startTime = 0
                end
                if dr.timerText then dr.timerText:Hide() end
                dr.severity = 1
            end
        end
    end
end

-- REMOVED: Duplicate GetRemainingCD() function (lines 3241-3250)
-- This was an exact duplicate of GetRemainingCD() at line 715
-- Using the original function defined earlier in the file

-- ENHANCED: Function to update cooldown timer text (works in test mode and real arena)
local function UpdateCooldownText(indicator)
    if not indicator then 
        -- DEBUG: Indicator is nil
        -- print("|cffFF0000[UpdateCooldownText]|r Indicator is nil")
        return 
    end
    if not indicator.cooldown then 
        -- DEBUG: No cooldown frame
        -- print("|cffFF0000[UpdateCooldownText]|r No cooldown frame")
        return 
    end
    if not indicator.cooldown.Text then 
        -- DEBUG: No Text object on cooldown
        -- print("|cffFF0000[UpdateCooldownText]|r No Text object on cooldown")
        return 
    end
    
    local start, duration = indicator.cooldown:GetCooldownTimes()
    if start == 0 or duration == 0 then
        indicator.cooldown.Text:SetText("")
        indicator.cooldown.Text:Hide()
        return
    end
    
    local remaining = (start + duration) / 1000 - GetTime()
    if remaining > 0.5 then
        -- Format as M:SS (e.g., "1:59", "0:45")
        local minutes = math.floor(remaining / 60)
        local seconds = math.floor(remaining % 60)
        local timeText = string.format("%d:%02d", minutes, seconds)
        indicator.cooldown.Text:SetText(timeText)
        indicator.cooldown.Text:Show()
    else
        indicator.cooldown.Text:SetText("")
        indicator.cooldown.Text:Hide()
    end
end


-- Hide debuff test - called from DebuffsWindow HIDE button
function FrameManager:HideDebuffTest()
    if not self:FramesExist() then return end
    
    local frames = self:GetFrames()
    for i = 1, #frames do
        if frames[i] and frames[i].debuffContainer then
            frames[i].debuffContainer:Hide()
            -- CRITICAL FIX: Clear the active flag so TEST button works again
            frames[i].debuffContainer.testDebuffsActive = false
        end
    end
end

-- Refresh debuff settings - called when settings change in DebuffsWindow
function FrameManager:RefreshDebuffSettings()
    local debuffModule = GetDebuffModule()
    if debuffModule and debuffModule.RefreshSettings then
        debuffModule:RefreshSettings()
        return
    end

    if not self:FramesExist() then return end
    
    local frames = self:GetFrames()
    local debuffSettings = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.debuffs
    
    -- Update positioning for all debuff containers
    for i = 1, #frames do
        if frames[i] and frames[i].debuffContainer then
            local c = frames[i].debuffContainer
            
            -- Clear existing positioning and apply new positioning
            c:ClearAllPoints()
            local horizontal = debuffSettings and debuffSettings.positioning and debuffSettings.positioning.horizontal or 8
            local vertical = debuffSettings and debuffSettings.positioning and debuffSettings.positioning.vertical or 6
            c:SetPoint("BOTTOMLEFT", frames[i], "BOTTOMLEFT", horizontal, vertical)
            
            -- Hide all existing debuff frames
            for j = 1, #c.debuffs do 
                if c.debuffs[j] then
                    c.debuffs[j]:SetAlpha(0)
                    c.debuffs[j]:Hide()
                end
            end
            
            -- Clear the debuffs array to force recreation with new scale
            c.debuffs = {}
            
            -- CRITICAL FIX: Clear the active flag to allow re-setup with new settings
            c.testDebuffsActive = false
            
            -- Hide container if debuffs are disabled
            if not debuffSettings or not debuffSettings.enabled then
                c:Hide()
            end
        end
    end
    
    -- Check if any frame is shown (test mode active)
    local inTestMode = false
    for i = 1, #frames do
        if frames[i] and frames[i]:IsShown() then
            inTestMode = true
            break
        end
    end
    
    -- If in test mode and debuffs are enabled, refresh with new settings
    if inTestMode and debuffSettings and debuffSettings.enabled then
        self:TestDebuffMode()
    end
end

-- Spec-based resource colors for prep room and arena
function FrameManager:ApplySpecBasedResourceColors(frame, classFile, specID)
    if not frame.manaBar or not classFile then return end
    
    -- Use MFM's spec-based resource color system
    local color = MFM:GetSpecResourceColor(classFile, specID)
    frame.manaBar:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)
end

-- Legacy function for backward compatibility
function FrameManager:ApplyClassBasedResourceColors(frame, classFile)
    self:ApplySpecBasedResourceColors(frame, classFile, nil)
end

-- ============================================================================
-- ABSORBS SYSTEM MOVED TO MODULE
-- See: modules/Absorbs/Absorbs.lua
-- Backward compatibility maintained via global UpdateAbsorbBar in module
-- ============================================================================

-- ============================================================================
-- 7. EVENT SYSTEM & COMBAT LOG
-- ============================================================================
-- Event handling, combat log processing, cast bars, trinket/racial tracking

-- Get user's chosen trinket icon from settings (returns texture path/ID ready for SetTexture)
function FrameManager:GetUserTrinketIcon()
    if AC.TrinketsRacials and AC.TrinketsRacials.GetUserTrinketIcon then
        return AC.TrinketsRacials:GetUserTrinketIcon()
    end
    return 1322720
end

-- PHASE 3: REMOVED - Racial icon logic now in TrinketsRacials module
-- Use AC.TrinketsRacials:RefreshFrame() instead

function FrameManager:RegisterDebuffEvents()
    -- Create event frame if it doesn't exist
    if not self.debuffEventFrame then
        self.debuffEventFrame = CreateFrame("Frame")
        self.debuffEventFrame:SetScript("OnEvent", function(_, event, ...)
            -- Only show critical events (trinkets/racials/cast bars), not UNIT_AURA spam
            if event == "UNIT_SPELLCAST_SUCCEEDED" then
                local arg1 = select(1, ...)
                local spellID = select(3, ...)
                -- DEBUG: Event fired
                -- print("|cffFFFF00[EVENT]|r " .. event .. " - " .. tostring(arg1) .. " spell " .. tostring(spellID))
            end
            self:OnDebuffEvent(event, ...)
        end)
    end
    
    -- Register for aura update events
    -- CRITICAL FIX: Use RegisterUnitEvent to filter for arena units only
    -- This prevents unnecessary event spam from player/party/raid auras
    self.debuffEventFrame:RegisterUnitEvent("UNIT_AURA", "arena1", "arena2", "arena3")
    
    --[[ OLD CAST BAR SYSTEM - DISABLED
    local castModule = GetCastBarModule()
    if castModule and castModule.RegisterEvents then
        castModule:RegisterEvents(self.debuffEventFrame)
    end
    --]]
    
    -- Trinket/Racial updates are handled by TrinketsRacials module via ArenaTracking events
    self.debuffEventFrame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
    
    -- REMOVED: COMBAT_LOG_EVENT_UNFILTERED - DR tracking should handle this separately
    
    -- DEBUG: Events registered
    -- print("|cff00FF00[FrameManager]|r ✓ Registered ALL events (cast bars, trinkets, racials)")
    -- print("|cff00FF00[FrameManager]|r ✓ UNIT_SPELLCAST_SUCCEEDED registered for arena1, arena2, arena3")
    -- print("|cff00FF00[FrameManager]|r ✓ UNIT_SPELLCAST_START registered for arena1, arena2, arena3")
end

function FrameManager:OnDebuffEvent(event, ...)
    if not self:FramesExist() then 
        return 
    end
    
    -- Handle COMBAT_LOG_EVENT_UNFILTERED for DR tracking and dispels
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:HandleCombatLogEvent()
        return
    end
    
    -- PHASE 2: Removed duplicate UNIT_SPELLCAST_SUCCEEDED handler
    -- ArenaTracking already handles this event and forwards to TrinketsRacials module
    if event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" then
        local unit, spellID = ...
        if AC.TrinketsRacials and AC.TrinketsRacials.OnCrowdControlSpell then
            AC.TrinketsRacials:OnCrowdControlSpell(unit, spellID)
        end
        return
    end
    
    local unit = ...
    if not unit or not unit:match("^arena%d$") then 
        return 
    end
    
    -- Get arena index from unit
    local arenaIndex = tonumber(unit:match("^arena(%d)$"))
    if not arenaIndex or arenaIndex < 1 or arenaIndex > 3 then 
        return 
    end
    
    -- Get the frame for this arena unit
    local frames = self:GetFrames()
    local frame = frames[arenaIndex]
    if not frame then 
        return 
    end
    
    -- Handle debuff events
    if event == "UNIT_AURA" then
        local debuffModule = GetDebuffModule()
        if debuffModule and debuffModule.Update then
            debuffModule:Update(frame, unit)
        end
        -- Also update dispel tracking
        local dispelModule = GetDispelModule()
        if dispelModule and dispelModule.Update then
            dispelModule:Update(frame, unit)
        else
            self:UpdateDispels(frame, unit)
        end
    --[[ OLD CAST BAR SYSTEM - DISABLED
    -- Handle cast bar events
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
        local castModule = GetCastBarModule()
        if castModule and castModule.Update then
            castModule:Update(frame, unit, event)
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        local castModule = GetCastBarModule()
        if castModule and castModule.Hide then
            castModule:Hide(frame)
        end
    --]]
    end
end

--[[ OLD CAST BAR SYSTEM - DISABLED
function FrameManager:UpdateCastBar(frame, unit, event)
    local castModule = GetCastBarModule()
    if castModule and castModule.Update then
        castModule:Update(frame, unit, event)
    end
end

function FrameManager:HideCastBar(frame)
    local castModule = GetCastBarModule()
    if castModule and castModule.Hide then
        castModule:Hide(frame)
    end
end
--]]


-- Handle COMBAT_LOG_EVENT_UNFILTERED for all tracking systems
function FrameManager:HandleCombatLogEvent()
    local _, combatEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    
    if combatEvent == "SPELL_AURA_APPLIED" or combatEvent == "SPELL_AURA_REFRESH" then
        -- DR TRACKING NOW HANDLED BY DRTracker module (direct COMBAT_LOG registration)
        -- Old complex routing system disabled
        
        -- ====================================================================
        -- TRIBADGES (CLASS PACKS) COMBAT_LOG TRACKING - FALLBACK METHOD
        -- ====================================================================
        -- NOTE: TriBadges now uses AuraUtil.ForEachAura as PRIMARY method (BBP pattern)
        -- This COMBAT_LOG tracking is kept as FALLBACK for reliability
        -- Also needed for: Trinkets, Racials, DR, Dispels, etc.
        -- 
        -- This handles spells like Unholy Assault that apply buffs AFTER hitting a target
        -- destGUID is the unit receiving the buff (the arena enemy)
        if _G.ArenaCore and _G.ArenaCore.TriBadges and _G.ArenaCore.TriBadges.OnSpellCastByGUID then
            _G.ArenaCore.TriBadges:OnSpellCastByGUID(destGUID, spellID, combatEvent)
        end
    elseif combatEvent == "SPELL_CAST_SUCCESS" then
        -- Track dispel casts
        local dispelSpells = {
            [527] = 8,     -- Purify (Priest)
            [4987] = 8,    -- Cleanse (Paladin)
            [77130] = 8,   -- Purify Spirit (Shaman)
            [88423] = 8,   -- Nature's Cure (Druid)
            [115450] = 8,  -- Detox (Monk)
            [2782] = 8,    -- Remove Corruption (Druid)
            [51886] = 8,   -- Cleanse Spirit (Shaman)
            [475] = 8,     -- Remove Curse (Mage)
            [360823] = 8,  -- Naturalize (Evoker)
        }
        
        if dispelSpells[spellID] then
            -- Find which arena unit cast this
            for i = 1, 3 do
                local unitGUID = UnitGUID("arena" .. i)
                if unitGUID == sourceGUID then
                    local frames = self:GetFrames()
                    local frame = frames[i]
                    if frame then
                        self:TrackDispelCooldown(frame, spellID, dispelSpells[spellID], "arena" .. i)
                    end
                    break
                end
            end
        else
            for i = 1, 3 do
                local unitGUID = UnitGUID("arena" .. i)
                if unitGUID == sourceGUID then
                    local unit = "arena" .. i
                    local frame = self:GetFrames()[i]
                    -- Racial tracking via combat log (trinkets use API events)
                    if AC.TrinketsRacials and AC.TrinketsRacials.HandleSpell then
                        AC.TrinketsRacials:HandleSpell(frame, unit, spellID)
                    end
                    -- TriBadges COMBAT_LOG tracking (FALLBACK - primary method is AuraUtil.ForEachAura)
                    if _G.ArenaCore and _G.ArenaCore.TriBadges and _G.ArenaCore.TriBadges.OnSpellCast then
                        _G.ArenaCore.TriBadges:OnSpellCast(unit, spellID, combatEvent)
                    end
                    break
                end
            end
        end
    end
end


-- Update dispel tracking
function FrameManager:UpdateDispels(frame, unit)
    local dispelModule = GetDispelModule()
    if dispelModule and dispelModule.Update then
        dispelModule:Update(frame, unit)
        return
    end
end

-- Track dispel cooldown
function FrameManager:TrackDispelCooldown(frame, spellID, duration, unit)
    local dispelModule = GetDispelModule()
    if dispelModule and dispelModule.TrackCooldown then
        dispelModule:TrackCooldown(frame, spellID, duration)
        return
    end
end

-- Local implementation of UpdateDebuffs (adapted from ArenaTracking.lua)
function FrameManager:UpdateDebuffs(frame, unit)
    local debuffModule = GetDebuffModule()
    if debuffModule and debuffModule.Update then
        return debuffModule:Update(frame, unit)
    end

    if not frame.debuffContainer then return end
    
    -- Check if debuffs are enabled
    local debuffSettings = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.debuffs
    if not debuffSettings or not debuffSettings.enabled then
        frame.debuffContainer:Hide()
        return
    end
    
    -- Get max count and scaling from settings (default 6, 100%)
    local maxCount = debuffSettings.maxCount or 6
    local scale = (debuffSettings.sizing and debuffSettings.sizing.scale or 100) / 100
    
    local function Trim(texture)
        if texture and texture.SetTexCoord then 
            texture:SetTexCoord(0.002, 0.998, 0.002, 0.998) 
        end 
    end
    
    local c = frame.debuffContainer
    
    -- Hide existing debuffs
    for i = 1, #c.debuffs do 
        if c.debuffs[i] then
            c.debuffs[i]:SetAlpha(0) 
        end
    end
    
    local idx = 1
    local hasDebuffs = false
    
    -- CRITICAL FIX: Consolidate debuffs by spell ID to combine stacks from multiple sources
    local debuffMap = {}
    
    -- Scan for debuffs (up to 40 slots)
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetDebuffDataByIndex(unit, i)
        if not auraData then break end
        
        local spellID = auraData.spellId
        
        -- FILTER OUT DAMPENING (spell ID 110310)
        if spellID ~= 110310 and auraData.name then
            if not debuffMap[spellID] then
                -- First instance of this spell
                debuffMap[spellID] = {
                    name = auraData.name,
                    icon = auraData.icon,
                    count = 1, -- Count instances, not applications
                    duration = auraData.duration,
                    expirationTime = auraData.expirationTime
                }
            else
                -- Same spell from another source - increment count
                debuffMap[spellID].count = debuffMap[spellID].count + 1
            end
        end
    end
    
    -- Convert map to sorted array and display up to maxCount
    local debuffArray = {}
    for spellID, data in pairs(debuffMap) do
        table.insert(debuffArray, data)
    end
    
    -- Display consolidated debuffs
    for _, debuffData in ipairs(debuffArray) do
        if idx > maxCount then break end
        
        hasDebuffs = true
        local name = debuffData.name
        local texture = debuffData.icon
        local count = debuffData.count
        
        -- Create debuff frame if it doesn't exist
        if not c.debuffs[idx] then 
            local frameSize = 20 * scale
            local iconSize = 16 * scale
            local spacing = 23 * scale
            
            local d = CreateFrame("Frame", nil, c)
            d:SetSize(frameSize, frameSize)
            d:SetPoint("LEFT", (idx-1) * spacing, 0)
            d:SetFrameStrata("MEDIUM") -- CRITICAL: Use MEDIUM to stay below bags
            d:SetFrameLevel(30) -- Lower level within MEDIUM strata, below trinkets/racials
            
            -- Black square background (like Blackout Aura editor)
            local bg = d:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(1, 1, 1, 1) -- White background first
            bg:SetVertexColor(0.1, 0.1, 0.1, 0.8) -- Dark background
            
            -- Black square border
            local border = AC:CreateFlatTexture(d, "BORDER", 1, {0, 0, 0, 1}, 1)
            border:SetAllPoints()
            
            -- Inner border for clean square look
            local innerBg = AC:CreateFlatTexture(d, "BACKGROUND", 2, {0.15, 0.15, 0.15, 1}, 1)
            innerBg:SetPoint("TOPLEFT", 1, -1)
            innerBg:SetPoint("BOTTOMRIGHT", -1, 1)
            
            -- Icon
            local icon = d:CreateTexture(nil, "ARTWORK")
            icon:SetSize(iconSize, iconSize)
            icon:SetPoint("CENTER")
            Trim(icon)
            
            -- Stack count text (scaled)
            local stack = d:CreateFontString(nil, "OVERLAY")
            local fontSize = math.max(6, 7 * scale)
            stack:SetFont("Interface\\\\AddOns\\\\ArenaCore\\\\Media\\\\Fonts\\\\arenacore.ttf", fontSize, "OUTLINE")
            stack:SetPoint("BOTTOMRIGHT", 2, -2)
            stack:SetTextColor(1, 1, 1, 1) -- White text
            
            -- NEW FEATURE: Cooldown frame for countdown spiral (using helper to block OmniCC)
            local cd = AC:CreateCooldown(d, nil, "CooldownFrameTemplate")
            cd:SetAllPoints(d)
            cd:SetHideCountdownNumbers(true)
            cd:SetDrawEdge(false)
            cd.noCooldownCount = true
            -- CRITICAL: Make spiral very faint so icon is visible
            cd:SetSwipeColor(0, 0, 0, 0.3) -- Very faint black (30% opacity)
            
            -- NEW FEATURE: Countdown timer text (center of icon)
            local timerFontSize = (debuffSettings.timerFontSize) or 10
            local timer = cd:CreateFontString(nil, "OVERLAY")
            timer:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", timerFontSize, "OUTLINE")
            timer:SetPoint("CENTER", cd, "CENTER", 0, 0)
            timer:SetTextColor(1, 1, 1, 1)
            cd.Text = timer
            
            d.icon = icon
            d.stack = stack
            d.cooldown = cd
            d.timer = timer
            c.debuffs[idx] = d
        end
        
        -- Update debuff display
        local d = c.debuffs[idx]
        d:SetAlpha(1)
        d.icon:SetTexture(texture)
        
        -- Show/hide stack count
        if count and count > 1 then 
            d.stack:SetText(count)
            d.stack:Show()
        else 
            d.stack:Hide()
        end
        
        -- NEW FEATURE: Countdown timer system (like TriBadges)
        local showTimer = debuffSettings.showTimer
        if showTimer == nil then showTimer = true end -- Default enabled
        
        if showTimer and debuffData.duration and debuffData.duration > 0 and debuffData.expirationTime then
            -- Start cooldown spiral
            local startTime = debuffData.expirationTime - debuffData.duration
            d.cooldown:SetCooldown(startTime, debuffData.duration)
            
            -- Start countdown timer text
            if d.timer then
                -- Cancel existing timer if any
                if d.timerUpdate then
                    d.timerUpdate:Cancel()
                    d.timerUpdate = nil
                end
                
                -- Update timer text every 0.1 seconds
                local expirationTime = debuffData.expirationTime
                local function UpdateTimerText()
                    if not d or not d.timer then return end
                    
                    local remaining = expirationTime - GetTime()
                    if remaining > 0 then
                        -- Format: M:SS for times over 60s, just seconds for under 60s
                        local minutes = math.floor(remaining / 60)
                        local seconds = math.floor(remaining % 60)
                        local timeText
                        if minutes > 0 then
                            timeText = string.format("%d:%02d", minutes, seconds)
                        else
                            timeText = string.format("%.0f", remaining)
                        end
                        d.timer:SetText(timeText)
                        
                        -- Schedule next update
                        d.timerUpdate = C_Timer.NewTimer(0.1, UpdateTimerText)
                    else
                        -- Timer expired
                        d.timer:SetText("")
                        d.timerUpdate = nil
                    end
                end
                
                -- Start the timer
                UpdateTimerText()
            end
        else
            -- Clear cooldown and timer if disabled or no duration
            if d.cooldown then
                d.cooldown:Clear()
            end
            if d.timer then
                d.timer:SetText("")
            end
            if d.timerUpdate then
                d.timerUpdate:Cancel()
                d.timerUpdate = nil
            end
        end
        
        idx = idx + 1
    end
    
    -- Show/hide container based on whether we have debuffs
    if hasDebuffs then
        c:Show()
    else
        c:Hide()
    end
end

-- ============================================================================
-- 8. ARENA STATE MANAGEMENT
-- ============================================================================
-- Arena detection, prep room handling, unit updates, arena entry/exit logic

-- ENHANCED: Helper functions to break down massive UpdateFrameData function
local function UpdateFrameVisibility(frame, unit, arenaIndex)
    local unitExists = UnitExists(unit)
    local _, instanceType = IsInInstance()
    local isArena = instanceType == "arena"
    
    -- If in arena, always show frame
    local shouldShow = isArena
    
    return shouldShow, unitExists
end
local function UpdateFrameIndicators(frame, unit)
    -- PHASE 1: Delegate to TrinketsRacials module for centralized control
    -- Module handles ALL trinket/racial visibility logic
    if AC.TrinketsRacials and AC.TrinketsRacials.RefreshFrame then
        AC.TrinketsRacials:RefreshFrame(frame, unit)
    else
        -- Fallback: Basic visibility control if module not loaded
        local db = AC.DB and AC.DB.profile
        
        if frame.trinketIndicator then
            local trinketEnabled = db and db.trinkets and db.trinkets.enabled
            if trinketEnabled ~= false then
                frame.trinketIndicator:Show()
            else
                frame.trinketIndicator:Hide()
            end
        end
        
        if frame.racialIndicator then
            local racialEnabled = db and db.racials and db.racials.enabled
            if racialEnabled ~= false then
                frame.racialIndicator:Show()
            else
                frame.racialIndicator:Hide()
            end
        end
    end
end

local function UpdateFrameBars(frame, unit)
    -- Update health bar
    if frame.healthBar then
        if AC.Midnight and AC.Midnight.isMidnight then
            -- Midnight: Both SetMinMaxValues and SetValue accept secret values
            frame.healthBar:SetMinMaxValues(0, UnitHealthMax(unit))
            frame.healthBar:SetValue(UnitHealth(unit))
        else
            -- Non-Midnight: Use raw values
            local health = UnitHealth(unit)
            local maxHealth = UnitHealthMax(unit)
            if maxHealth > 0 then
                frame.healthBar:SetMinMaxValues(0, maxHealth)
                frame.healthBar:SetValue(health)
            end
        end
        
        -- Apply class colors if enabled (works for both Midnight and non-Midnight)
        local _, class = UnitClass(unit)
        if AC:GetClassColorsEnabled() and class then
            local classColor = RAID_CLASS_COLORS[class]
            if classColor then
                frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
            else
                frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
            end
        else
            frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
        end
    end
    
    -- Update mana bar
    if frame.manaBar then
        -- CRITICAL FIX: Clear resource bar when unit is dead
        if UnitIsDead(unit) or UnitIsGhost(unit) then
            frame.manaBar:SetMinMaxValues(0, 100)
            frame.manaBar:SetValue(0)
            -- Update text to show 0%
            if frame.manaBar.text then
                frame.manaBar.text:SetText("0%")
            end
        else
            if AC.Midnight and AC.Midnight.isMidnight then
                -- Midnight: Both SetMinMaxValues and SetValue accept secret values
                frame.manaBar:SetMinMaxValues(0, UnitPowerMax(unit))
                frame.manaBar:SetValue(UnitPower(unit))
                
                -- CRITICAL: Disable mana text in Midnight due to UnitPowerPercent API bug
                if frame.manaBar.text then
                    frame.manaBar.text:Hide()
                end
            else
                -- Non-Midnight: Use raw values
                local power = UnitPower(unit)
                local maxPower = UnitPowerMax(unit)
                local powerType = UnitPowerType(unit)
                
                if maxPower > 0 then
                    frame.manaBar:SetMinMaxValues(0, maxPower)
                    frame.manaBar:SetValue(power)
                    
                    -- CRITICAL FIX: Cache power type to prevent flickering (Shadow Priest issue)
                    -- Initialize cache if it doesn't exist
                    if not frame.manaBar.cachedPowerType then
                        frame.manaBar.cachedPowerType = -1
                    end
                    
                    -- Only update color if power type changed (prevents flickering)
                    if frame.manaBar.cachedPowerType ~= powerType then
                        frame.manaBar.cachedPowerType = powerType
                        
                        -- CRITICAL FIX: Use WoW's PowerBarColor table (Gladius method)
                        -- This automatically handles all power types correctly
                        local powerColor = PowerBarColor[powerType]
                        if powerColor then
                            frame.manaBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b, 1)
                        else
                            frame.manaBar:SetStatusBarColor(0, 0, 1, 1) -- Fallback to mana blue
                        end
                    end
                end
            end
        end
    end
end

-- OPTIMIZED: UpdateFrameData function broken into manageable pieces
UpdateFrameData = function(frame, unit)
    if not frame or not unit then return end
    
    -- Extract arena index (1, 2, or 3)
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if not arenaIndex then return end
    
    -- CRITICAL: Complete test mode protection
    if AC.testModeEnabled then
        return
    end

    -- Use helper functions for cleaner, maintainable code
    local shouldShow, unitExists = UpdateFrameVisibility(frame, unit, arenaIndex)
    
    if shouldShow then
        -- CRITICAL FIX: Only update indicators if unit actually exists (not in prep room)
        -- In prep room, units don't exist yet, so skip indicator updates
        -- ARENA_OPPONENT_UPDATE will handle indicator updates when gates open
        if unitExists then
            -- Update indicators (trinkets, racials)
            UpdateFrameIndicators(frame, unit)
            
            -- Update health and mana bars
            UpdateFrameBars(frame, unit)
        end
    end
end

-- ENHANCED: Clean UpdateAllFrames function with comprehensive test mode protection
UpdateAllFrames = function()
    -- CRITICAL: Complete test mode protection - ArenaTracking should not interfere
    if AC.testModeEnabled then 
        StopTicker() -- Stop ArenaTracking ticker in test mode
        return 
    end
    
    -- CRITICAL FIX: Skip all updates during slider drag to prevent resetting timers/icons
    if AC._sliderDragActive then
        print("|cffFFFF00[UPDATE DEBUG]|r UpdateAllFrames SKIPPED - slider drag active")
        return
    end
    
    -- FIXED: Get frames from proper location
    local frames = AC.FrameManager and AC.FrameManager:GetFrames()
    if not frames then
        frames = _G.ArenaCore and _G.ArenaCore.arenaFrames
    end
    if not frames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        if frames[i] then
            UpdateFrameData(frames[i], "arena"..i)
            
            -- Update cooldown timer text for trinket and racial indicators
            if frames[i].trinketIndicator then
                UpdateCooldownText(frames[i].trinketIndicator)
            end
            if frames[i].racialIndicator then
                UpdateCooldownText(frames[i].racialIndicator)
            end
            
            -- Update DR icons for each frame (only in live arena)
            UpdateDRIcons("arena" .. i)
            
            -- Update DR cooldown text for all DR icons
            if frames[i].drFrames then
                for category, drFrame in pairs(frames[i].drFrames) do
                    if drFrame.cooldown and drFrame.cooldown.Text then
                        UpdateCooldownText(drFrame)
                    end
                end
            end
        end
    end
end

local function UpdatePrepRoomUnit(arenaIndex, frame)
    if not frame or not arenaIndex then return end
    
    -- CRITICAL: Always ensure frame is visible in prep room
    if not InCombatLockdown() then
        frame:Show()
    end
    
    -- ARCHITECTURAL FIX: Use unified text control system
    if frame.playerName and not AC.testModeEnabled then
        AC:SetArenaFrameText(frame, arenaIndex, "prep_room")
    end
    
    -- Get spec information using proper API calls
    local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(arenaIndex)
    if specID and specID > 0 then
        local _, specName, _, specIcon, _, classFile = GetSpecializationInfoByID(specID)
        
        -- Update spec icon
        if frame.specIcon and specIcon and frame.specIcon.icon then
            -- FIXED: Check if spec icons are enabled before showing
            local db = AC.DB and AC.DB.profile
            local specEnabled = db and db.specIcons and db.specIcons.enabled
            if specEnabled ~= false then
                frame.specIcon.icon:SetTexture(specIcon)
                frame.specIcon:Show()
            else
                frame.specIcon:Hide()
            end
        end
        
        -- Update class icon based on spec
        if frame.classIcon and classFile then
            -- FIXED: Check if class icons are enabled before showing
            local db = AC.DB and AC.DB.profile
            local classEnabled = db and db.classIcons and db.classIcons.enabled
            if classEnabled ~= false then
                if frame.classIcon.UpdateClassIcon then
                    frame.classIcon.UpdateClassIcon(classFile)
                    frame.classIcon:Show()
                elseif frame.classIcon.icon then
                    -- CRITICAL FIX: Fallback must also update overlay, not just icon
                    local iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\" .. classFile .. ".tga"
                    frame.classIcon.icon:SetTexture(iconPath)
                    
                    -- Update overlay to match the detected class (prep room fix)
                    if frame.classIcon.overlay and classFile then
                        local overlayPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\" .. classFile:lower() .. "overlay.tga"
                        frame.classIcon.overlay:SetTexture(overlayPath, true, true)
                    end
                    
                    frame.classIcon:Show()
                end
            else
                frame.classIcon:Hide()
            end
        end
        
        -- Apply class-based health bar colors in prep room (unique ArenaCore feature!)
        if frame.healthBar and classFile and RAID_CLASS_COLORS[classFile] then
            local classColor = RAID_CLASS_COLORS[classFile]
            frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
        end
        
        -- REVOLUTIONARY: Apply SPEC-based resource colors in prep room (no other addon does this!)
        if frame.manaBar and classFile and AC.FrameManager and AC.FrameManager.ApplySpecBasedResourceColors then
            AC.FrameManager:ApplySpecBasedResourceColors(frame, classFile, specID)
        end
    else
        -- No spec data available YET - hide spec and class icons but KEEP FRAME VISIBLE
        if frame.specIcon then
            frame.specIcon:Hide()
        end
        if frame.classIcon then
            frame.classIcon:Hide()
        end
        
        -- DEFENSIVE: Even without spec data, keep the frame visible in prep room
        -- Spec data might load later via subsequent events
        if not InCombatLockdown() then
            frame:Show()
        end
    end
    
    -- CRITICAL FIX: Hide cast bar AND all child elements in prep room
    -- This prevents empty spell icon borders from showing after /reload
    -- MIDNIGHT: Don't hide Blizzard's CastingBarFrame - it manages itself
    if frame.castBar and not frame.castBar._isMidnightBlizzardFrame then
        frame.castBar:Hide()
        
        -- Hide spell icon (prevents empty border from showing)
        if frame.castBar.spellIcon then
            frame.castBar.spellIcon:Hide()
            -- Clear icon texture
            if frame.castBar.spellIcon.texture then
                frame.castBar.spellIcon.texture:SetTexture(nil)
            end
            -- CRITICAL FIX: Hide the border textures (top, bottom, left, right)
            -- These stay visible even when spellIcon is hidden, causing empty black borders
            -- Check BOTH border and styledBorder (IconStyling uses styledBorder)
            if frame.castBar.spellIcon.border then
                if frame.castBar.spellIcon.border.top then frame.castBar.spellIcon.border.top:Hide() end
                if frame.castBar.spellIcon.border.bottom then frame.castBar.spellIcon.border.bottom:Hide() end
                if frame.castBar.spellIcon.border.left then frame.castBar.spellIcon.border.left:Hide() end
                if frame.castBar.spellIcon.border.right then frame.castBar.spellIcon.border.right:Hide() end
            end
            if frame.castBar.spellIcon.styledBorder then
                if frame.castBar.spellIcon.styledBorder.top then frame.castBar.spellIcon.styledBorder.top:Hide() end
                if frame.castBar.spellIcon.styledBorder.bottom then frame.castBar.spellIcon.styledBorder.bottom:Hide() end
                if frame.castBar.spellIcon.styledBorder.left then frame.castBar.spellIcon.styledBorder.left:Hide() end
                if frame.castBar.spellIcon.styledBorder.right then frame.castBar.spellIcon.styledBorder.right:Hide() end
            end
        end
        
        -- Hide all borders
        if frame.castBar.borders then
            for _, border in pairs(frame.castBar.borders) do
                border:Hide()
            end
        end
        
        -- Clear and hide text
        if frame.castBar.text then
            frame.castBar.text:SetText("")
            frame.castBar.text:Hide()
        end
        
        -- Reset cast bar value
        frame.castBar:SetValue(0)
    end
    
    -- Keep health/mana at 100% (as requested)
    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, 100)
        frame.healthBar:SetValue(100)
        if frame.healthBar.statusText then
            frame.healthBar.statusText:SetText("100%")
        end
    end
    
    if frame.manaBar then
        frame.manaBar:SetMinMaxValues(0, 100)
        frame.manaBar:SetValue(100)
        if frame.manaBar.statusText then
            frame.manaBar.statusText:SetText("")
            frame.manaBar.statusText:Hide()
        end
    end
    
    -- PHASE 3: Racial visibility now handled by TrinketsRacials module
    -- Module's RefreshFrame handles prep room hiding automatically
    
    -- Show trinkets (as requested - they can stay)
    if frame.trinketIndicator then
        frame.trinketIndicator:Show()
    end
    
    -- CRITICAL: Hide DR icons in prep room (they should only show in live arena)
    if frame.drIcons then
        for category, drFrame in pairs(frame.drIcons) do
            if drFrame then
                drFrame:Hide()
            end
        end
    end
    
    -- CRITICAL: Hide dispel container in prep room (should only show in live arena)
    if frame.dispelContainer then
        frame.dispelContainer:Hide()
    end
    
    -- REMOVED: Don't force alpha to 1.0 - let stealth system control it
    -- frame:SetAlpha(1.0)  -- This was overriding prep room 0.5 alpha from ArenaFrameStealth
    
    -- CRITICAL: Always show the frame at the end, regardless of spec data availability
    -- This is the final safety net to prevent disappearing frames
    if not InCombatLockdown() then
        frame:Show()
    end
end

-- Arena state update handler - works with FrameLayout frames
function AC:UpdateArenaFrames(inPrepRoom)
    -- CRITICAL: Don't interfere with FrameLayout test mode
    if AC.testModeEnabled then
        -- DEBUG: Skipping UpdateArenaFrames in test mode
        -- print("ArenaCore: Skipping UpdateArenaFrames - test mode active")
        return
    end
    
    -- FIXED: Get frames from proper location
    local frames = AC.FrameManager and AC.FrameManager:GetFrames()
    if not frames then
        frames = _G.ArenaCore and _G.ArenaCore.arenaFrames
    end
    if not frames then 
        print("ArenaCore: No frames available from FrameLayout!")
        return 
    end
    
    -- OLD MISMATCH CODE REMOVED - Bracket size logic deleted
    -- MismatchHandler now handles all frame visibility
    -- This function only updates frame data, not visibility
    
    -- Update frame data based on context
    for i = 1, 3 do
        local frame = frames[i]
        if frame then
            if inPrepRoom then
                -- Prep room: Update if valid spec data exists
                local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(i)
                if specID and specID > 0 then
                    UpdatePrepRoomUnit(i, frame)
                end
            else
                -- Real arena: Update if unit exists
                local unit = "arena" .. i
                if UnitExists(unit) then
                    UpdateArenaUnit(unit, frame)
                end
            end
        end
    end
end

-- Arena unit updates for real matches (global so it can be called from anywhere)
function UpdateArenaUnit(unit, frame)
    if not frame or not unit or not UnitExists(unit) then return end
    
    -- Update unit association
    frame.unit = unit
    
    -- CRITICAL FIX: Use unified text system to respect showArenaLabels setting
    -- This prevents "Arena 3" from showing when user has "Show Names" enabled
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if arenaIndex and AC.SetArenaFrameText then
        AC:SetArenaFrameText(frame, arenaIndex, "live_arena", unit)
    end
    
    -- Update health/mana
    if frame.healthBar then
        if AC.Midnight and AC.Midnight.isMidnight then
            -- Midnight: Both SetMinMaxValues and SetValue accept secret values
            frame.healthBar:SetMinMaxValues(0, UnitHealthMax(unit))
            frame.healthBar:SetValue(UnitHealth(unit))
        else
            -- Non-Midnight: Use raw values
            local maxHealth = UnitHealthMax(unit) or 100
            local currentHealth = UnitHealth(unit) or 0
            frame.healthBar:SetMinMaxValues(0, maxHealth)
            frame.healthBar:SetValue(currentHealth)
        end
        
        -- Dynamic class color for health bar (check useClassColors setting)
        local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
        local useClassColors = general and general.useClassColors ~= false
        
        local _, classFile = UnitClass(unit)
        
        -- CRITICAL FIX: Always set a color, don't leave it undefined
        if useClassColors and classFile then
            -- Use WoW's built-in class colors for consistency
            if RAID_CLASS_COLORS[classFile] then
                local classColor = RAID_CLASS_COLORS[classFile]
                frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
            else
                -- Fallback to green if class color not found
                frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
            end
        else
            -- Use default green when class colors are disabled OR class not detected
            frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
        end
        
        if frame.healthBar.text then
            -- Check usePercentage setting
            local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
            local usePercentage = general and general.usePercentage ~= false
            
            if usePercentage then
                if AC.Midnight and AC.Midnight.isMidnight then
                    -- Midnight: Use CurveConstants.ScaleTo100 to get non-secret percentage
                    local percent = UnitHealthPercent(unit, nil, CurveConstants.ScaleTo100)
                    frame.healthBar.text:SetFormattedText("%0.f%%", percent)
                else
                    -- Non-Midnight: Calculate from raw values
                    local maxHealth = UnitHealthMax(unit) or 100
                    local currentHealth = UnitHealth(unit) or 0
                    local percent = maxHealth > 0 and math.ceil((currentHealth / maxHealth) * 100) or 0
                    frame.healthBar.text:SetText(percent .. "%")
                end
            else
                if AC.Midnight and AC.Midnight.isMidnight then
                    -- Midnight: Can't show raw health values (they're secret)
                    frame.healthBar.text:SetText("")
                else
                    -- Non-Midnight: Use AbbreviateLargeNumbers for shorter display
                    local currentHealth = UnitHealth(unit) or 0
                    frame.healthBar.text:SetText(AbbreviateLargeNumbers(currentHealth))
                end
            end
        end
    end
    
    if frame.manaBar then
        if AC.Midnight and AC.Midnight.isMidnight then
            -- Midnight: Both SetMinMaxValues and SetValue accept secret values
            frame.manaBar:SetMinMaxValues(0, UnitPowerMax(unit))
            frame.manaBar:SetValue(UnitPower(unit))
        else
            -- Non-Midnight: Use raw values
            local power = UnitPower(unit) or 0
            local maxPower = UnitPowerMax(unit) or 1
            frame.manaBar:SetMinMaxValues(0, maxPower)
            frame.manaBar:SetValue(power)
        end
        
        -- CRITICAL FIX: Cache power type to prevent flickering (Shadow Priest issue)
        -- Only update color when power type actually changes, not on every power update
        local powerType = UnitPowerType(unit)
        
        -- Initialize cache if it doesn't exist
        if not frame.manaBar.cachedPowerType then
            frame.manaBar.cachedPowerType = -1
        end
        
        -- Only update color if power type changed (prevents flickering)
        if frame.manaBar.cachedPowerType ~= powerType then
            frame.manaBar.cachedPowerType = powerType
            
            local powerColors = {
                [0] = {0.00, 0.00, 1.00}, -- Mana (Blue)
                [1] = {1.00, 0.00, 0.00}, -- Rage (Red)
                [2] = {1.00, 0.50, 0.25}, -- Focus (Orange)
                [3] = {1.00, 1.00, 0.00}, -- Energy (Yellow)
                [4] = {0.00, 1.00, 1.00}, -- Combo Points (Cyan)
                [5] = {0.50, 0.50, 1.00}, -- Runes (Light Blue)
                [6] = {0.00, 1.00, 0.00}, -- Runic Power (Green)
                [7] = {0.50, 0.00, 1.00}, -- Soul Shards (Purple)
                [8] = {0.40, 0.80, 1.00}, -- Lunar Power (Light Blue)
                [9] = {0.80, 0.40, 0.80}, -- Holy Power (Pink)
                [11] = {0.50, 1.00, 1.00}, -- Maelstrom (Cyan)
                [12] = {0.00, 0.80, 0.60}, -- Chi (Green-Blue)
                [13] = {0.60, 0.20, 0.80}, -- Insanity (Purple)
                [17] = {1.00, 0.30, 0.30}, -- Fury (Red)
                [18] = {0.80, 0.60, 0.00}, -- Pain (Yellow-Brown)
                [19] = {0.00, 0.60, 1.00}  -- Essence (Blue)
            }
            
            local color = powerColors[powerType] or {0.00, 0.00, 1.00} -- Default to mana blue
            frame.manaBar:SetStatusBarColor(color[1], color[2], color[3], 1)
        end
        
        if frame.manaBar.text then
            if AC.Midnight and AC.Midnight.isMidnight then
                -- CRITICAL: Disable mana text in Midnight due to UnitPowerPercent API bug
                frame.manaBar.text:Hide()
            else
                -- Non-Midnight: Show text normally
                local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
                local usePercentage = general and general.usePercentage ~= false
                
                if usePercentage then
                    local currentPower = UnitPower(unit) or 0
                    local maxPower = UnitPowerMax(unit) or 1
                    local percent = maxPower > 0 and math.ceil((currentPower / maxPower) * 100) or 0
                    frame.manaBar.text:SetText(percent .. "%")
                else
                    local currentPower = UnitPower(unit) or 0
                    frame.manaBar.text:SetText(AbbreviateLargeNumbers(currentPower))
                end
                frame.manaBar.text:Show()
            end
        end
    end
    
    -- Update class icon
    if frame.classIcon then
        local _, classFile = UnitClass(unit)
        if classFile then
            -- FIXED: Check if class icons are enabled before showing
            local db = AC.DB and AC.DB.profile
            local classEnabled = db and db.classIcons and db.classIcons.enabled
            if classEnabled ~= false then
                if frame.classIcon.UpdateClassIcon then
                    frame.classIcon.UpdateClassIcon(classFile)
                elseif frame.classIcon.icon then
                    local iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\" .. classFile .. ".tga"
                    frame.classIcon.icon:SetTexture(iconPath)
                    
                    -- CRITICAL FIX: Update overlay to match detected class
                    if frame.classIcon.overlay then
                        local overlayPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\" .. classFile:lower() .. "overlay.tga"
                        frame.classIcon.overlay:SetTexture(overlayPath, true, true)
                    end
                end
                frame.classIcon:Show()
            else
                frame.classIcon:Hide()
            end
        end
    end
    
    -- Update spec icon
    if frame.specIcon then
        local arenaIndex = tonumber(unit:match("arena(%d)"))
        if arenaIndex then
            local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(arenaIndex)
            if specID and specID > 0 then
                local _, specName, _, specIcon = GetSpecializationInfoByID(specID)
                if specIcon and frame.specIcon.icon then
                    -- FIXED: Check if spec icons are enabled before showing
                    local db = AC.DB and AC.DB.profile
                    local specEnabled = db and db.specIcons and db.specIcons.enabled
                    if specEnabled ~= false then
                        frame.specIcon.icon:SetTexture(specIcon)
                        -- CRITICAL FIX: Safe Show() call - check if method exists
                        if frame.specIcon.Show then
                            frame.specIcon:Show()
                        end
                        -- CRITICAL FIX: Ensure border is visible when icon shows
                        if frame.specIcon.border and frame.specIcon.border.Show then
                            frame.specIcon.border:Show()
                        end
                    else
                        frame.specIcon:Hide()
                    end
                else
                    -- CRITICAL FIX: No spec icon available - hide icon but keep border structure intact
                    -- This prevents "broken borders" when spec data isn't ready yet
                    if frame.specIcon.icon then
                        frame.specIcon.icon:SetTexture(nil)
                    end
                    frame.specIcon:Hide()
                end
            else
                -- CRITICAL FIX: No spec ID yet (player didn't join or data not ready)
                -- Clear texture but don't break the frame structure
                if frame.specIcon.icon then
                    frame.specIcon.icon:SetTexture(nil)
                end
                frame.specIcon:Hide()
            end
        end
    end
    
    -- Show cast bar (will be updated by cast events)
    if frame.castBar then
        frame.castBar:Show()
    end
    
    -- CRITICAL FIX: Respect user settings for trinkets and racials
    local db = AC.DB and AC.DB.profile
    
    -- Update trinket (show only if enabled)
    if frame.trinketIndicator then
        local trinketEnabled = db and db.trinkets and db.trinkets.enabled
        if trinketEnabled ~= false then
            frame.trinketIndicator:Show()
        else
            frame.trinketIndicator:Hide()
        end
    end
    
    -- CRITICAL FIX: Show racial indicator like trinkets - always visible with border/icon
    if frame.racialIndicator then
        local racialEnabled = db and db.racials and db.racials.enabled
        
        -- CRITICAL FIX: Check if in prep room (same logic as absorbs)
        local _, instanceType = IsInInstance()
        local inPrepRoom = false
        if instanceType == "arena" then
            local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs()
            if numOpponents and numOpponents > 0 then
                inPrepRoom = true
            end
        end
        
        -- Show racial indicator if enabled and not in prep room (like trinkets)
        if racialEnabled ~= false and not inPrepRoom then
            frame.racialIndicator:Show()
            -- Icon texture is handled by TrinketsRacials module
        else
            frame.racialIndicator:Hide()
        end
    end
    
    -- REMOVED: Don't force alpha to 1.0 - let stealth system control it
    -- frame:SetAlpha(1.0)  -- This was overriding stealth alpha from ArenaFrameStealth
    -- The "seen" event in ARENA_OPPONENT_UPDATE will set alpha to 1.0 when appropriate
    
    -- Show the frame (use secure method to avoid combat restrictions)
    if not InCombatLockdown() then
        frame:Show()
    end
end

-- ENHANCED: Component-specific clear helpers for better maintainability
local function ClearHealthBars(frame)
    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, 100)
        frame.healthBar:SetValue(100)
        -- CRITICAL FIX: Respect statusText setting when clearing
        if frame.healthBar.text then
            local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
            local statusTextEnabled = general and general.statusText ~= false
            if statusTextEnabled then
                frame.healthBar.text:SetText("100%")
                frame.healthBar.text:Show()
            else
                frame.healthBar.text:Hide()
            end
        end
    end
    
    if frame.manaBar then
        frame.manaBar:SetMinMaxValues(0, 100)
        frame.manaBar:SetValue(100)
        -- CRITICAL FIX: Respect statusText setting when clearing
        if frame.manaBar.text then
            local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
            local statusTextEnabled = general and general.statusText ~= false
            if statusTextEnabled then
                frame.manaBar.text:SetText("100%")
                frame.manaBar.text:Show()
            else
                frame.manaBar.text:Hide()
            end
        end
    end
end

local function ClearIconsAndIndicators(frame)
    -- Clear class icon and spec chips
    if frame.classIcon then
        if frame.classIcon.icon then frame.classIcon.icon:SetTexture(nil) end
        if frame.classIcon.overlay then frame.classIcon.overlay:SetTexture(nil) end
        if frame.classIcon.background then frame.classIcon.background:SetVertexColor(1, 1, 1, 1) end
        if frame.classIcon.specChip then
            frame.classIcon.specChip:Hide()
            if frame.classIcon.specChip.icon then frame.classIcon.specChip.icon:SetTexture(nil) end
        end
    end
    
    -- Clear trinket and racial indicators
    if frame.trinketIndicator then
        if frame.trinketIndicator.texture then frame.trinketIndicator.texture:SetTexture(nil) end
        if frame.trinketIndicator.cooldown then frame.trinketIndicator.cooldown:Clear() end
        frame.trinketIndicator:Hide()
    end
    
    if frame.racialIndicator then
        if frame.racialIndicator.texture then frame.racialIndicator.texture:SetTexture(nil) end
        if frame.racialIndicator.cooldown then frame.racialIndicator.cooldown:Clear() end
        frame.racialIndicator:Hide()
    end
    
    -- CRITICAL FIX: Clear death icon to prevent leaks
    if frame.deathIconFrame then
        frame.deathIconFrame:Hide()
    end
end

local function ClearDebuffsAndDR(frame)
    -- Clear all debuffs/auras
    if frame.debuffContainer and frame.debuffContainer.debuffs then
        for _, debuff in pairs(frame.debuffContainer.debuffs) do
            if debuff then
                debuff:Hide()
                if debuff.icon then debuff.icon:SetTexture(nil) end
                if debuff.cooldown then debuff.cooldown:Clear() end
            end
        end
        wipe(frame.debuffContainer.debuffs)
    end
    
    -- Clear all DR (Diminishing Returns) icons
    if frame.drIcons then
        for category, dr in pairs(frame.drIcons) do
            if dr then
                dr:Hide()
                if dr.icon then dr.icon:SetTexture(nil) end
                if dr.cooldown then 
                    dr.cooldown.duration = 0
                    dr.cooldown.startTime = 0
                end
                if dr.timerText then dr.timerText:Hide() end
                dr.severity = 1
            end
        end
    end
end

local function ClearMiscElements(frame)
    --[[ OLD CAST BAR SYSTEM - DISABLED
    -- Clear cast bars
    if frame.castBar then
        if frame.castBar.Icon then frame.castBar.Icon:SetTexture(nil) end
        if frame.castBar.Text then frame.castBar.Text:SetText("") end
        frame.castBar:SetValue(0)
        frame.castBar:Hide()
    end
    --]]
    
    -- Clear target indicator
    if frame.targetIndicator then
        frame.targetIndicator:SetAlpha(0)
    end
    
    -- Clear player name and stored race data
    if frame.playerName then frame.playerName:SetText("") end
    frame.race = nil
end

-- REMOVED DUPLICATE: AC:ClearArenaData() already defined at line 993
-- ============================================================================
-- CONSOLIDATION: OLD SYSTEM REMOVED (Lines 5131-5309)
-- ============================================================================
-- This OLD arenaEventFrame system has been DELETED and consolidated into
-- MasterFrameManager (MFM) at lines 2644-3078.
--
-- ALL events now handled by MFM.eventFrame:
-- - ARENA_OPPONENT_UPDATE (stealth) → MFM:HandleArenaOpponentUpdate()
-- - GROUP_ROSTER_UPDATE (Solo Shuffle) → MFM:HandleSoloShuffleTransition()
-- - ARENA_PREP_OPPONENT_SPECIALIZATIONS → MFM:HandlePrepRoom()
-- - UNIT_HEALTH, UNIT_POWER, etc. → MFM:UpdateUnitHealth/Power/Name()
--
-- This eliminates the dual system problem that caused recurring bugs.
-- ============================================================================

-- REMOVED: Old arenaEventFrame code (178 lines deleted)
-- If you need to restore, check git history or backup

-- Placeholder to maintain line structure (will be cleaned up later)
local function OLD_SYSTEM_REMOVED_PLACEHOLDER()
    -- This function does nothing - placeholder for deleted OLD arenaEventFrame
    -- The NEW consolidated system is in MFM (MasterFrameManager)
end

-- OLD event handler body completely removed (lines 5153-5315 deleted)
-- All functionality moved to MFM:HandleGlobalEvent() at line 2680

-- ============================================================================
-- PHASE 1.3: Duplicate StartTicker/StopTicker removed (kept only first instance at line ~825)

-- Enhanced UpdateDebuffs function with comprehensive test mode protection
UpdateDebuffs = function(frame, unit)
    -- CRITICAL: Complete test mode protection
    if AC.testModeEnabled then return end
    if not frame or not frame.debuffContainer then return end
  
    local c = frame.debuffContainer
    for i=1,#c.debuffs do c.debuffs[i]:SetAlpha(0) end
    
    -- Get player debuffs only setting
    local db = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.debuffs
    -- CRITICAL FIX: Check if playerDebuffsOnly is explicitly false, otherwise respect the actual value
    local playerDebuffsOnly = (db and db.playerDebuffsOnly ~= nil) and db.playerDebuffsOnly or false
    local maxCount = db and db.maxCount or 6
    
    local idx = 1
    for i=1,40 do
        -- Use the modern API approach
        local auraData = C_UnitAuras.GetDebuffDataByIndex(unit, i)
        if not auraData then break end

        local name = auraData.name
        local texture = auraData.icon  
        local count = auraData.applications
        local spellID = auraData.spellId
        local sourceUnit = auraData.sourceUnit
        
        -- FILTER OUT DAMPENING (spell ID 110310)
        if spellID == 110310 then
            -- Skip Dampening debuff entirely
        -- FILTER: Player debuffs only mode
        elseif playerDebuffsOnly and sourceUnit ~= "player" then
            -- Skip debuffs not created by the player
        elseif not name or idx > maxCount then 
            break
        else
            if not c.debuffs[idx] then 
                local d = CreateFrame("Frame", nil, c)
                d:SetSize(20,20)
                d:SetPoint("LEFT", (idx-1)*23, 0)
                
                -- Set aura icons to lower frame level so spec icons appear on top
                d:SetFrameStrata("MEDIUM") -- CRITICAL: Use MEDIUM to stay below bags
                d:SetFrameLevel(30) -- Lower level within MEDIUM strata, below spec icons
                local bg = d:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetTexture(TEX.debuff_bg)
                Trim(bg)
                
                local icon = d:CreateTexture(nil, "ARTWORK")
                icon:SetSize(16,16)
                icon:SetPoint("CENTER")
                Trim(icon)
                
                local br = d:CreateTexture(nil, "BORDER")
                br:SetAllPoints()
                br:SetTexture(TEX.debuff_border)
                Trim(br)
                
                local stack = d:CreateFontString(nil, "OVERLAY")
                if AC.SafeSetFont then
                    AC.SafeSetFont(stack, AC.FONT_PATH, 7, "OUTLINE")
                else
                    stack:SetFont("Fonts\\\\FRIZQT__.TTF", 7, "OUTLINE")
                end
                stack:SetPoint("BOTTOMRIGHT", 2, -2)
                
                d.icon, d.stack = icon, stack
                c.debuffs[idx] = d
            end
            
            local d = c.debuffs[idx]
            d:SetAlpha(1)
            d.icon:SetTexture(texture)
            
            if count and count > 1 then 
                d.stack:SetText(count)
                d.stack:Show() 
            else 
                d.stack:Hide() 
            end
            
            idx = idx + 1
        end
    end
end

-- Public API with proper FrameLayout integration
function AC.GetFrameForUnit(unit)
    local idx = unit and unit:match("^arena(%d)$")
    local arenaFrames = GetArenaFrames() -- Use Wave 3 helper function
    return idx and arenaFrames and arenaFrames[tonumber(idx)]
end

-- REMOVED: Duplicate AC:UpdateDispelFrames function that was overriding DispelTracker.lua
-- The working implementation is in Core/DispelTracker.lua (line 443)
-- This duplicate was preventing dispels from showing in real arena

-- ============================================================================
-- CHUNK 9: BRIDGE FUNCTIONS & UI INTEGRATION
-- Functions that connect UI settings pages to frame updates
-- ============================================================================

-- ============================================================================
-- REFRESH LAYOUT FUNCTIONS - Connect UI pages to frame updates
-- ============================================================================

function AC:RefreshTexturesLayout(skipTextureUpdate)
    -- IMPORTANT: Single function handles all texture updates (like RefreshCastBarsLayout)
    -- WARNING: This function ONLY affects health/resource bars - DO NOT touch player names!
    -- Player names have their own independent positioning system in Arena Frames page
    local db = (self.DB and self.DB.profile and self.DB.profile.textures)
    if not db then return end
    
    -- Apply positioning settings
    local pos = db.positioning or {}
    local hPos = pos.horizontal or 56
    local vPos = pos.vertical or 6
    local spacing = pos.spacing or 8

    -- Apply sizing settings
    local sizing = db.sizing or {}
    local healthWidth = sizing.healthWidth or 128
    local healthHeight = sizing.healthHeight or 18
    local resourceWidth = sizing.resourceWidth or 136
    local resourceHeight = sizing.resourceHeight or 8
    -- Debug print removed to prevent console spam

    -- Get frames from unified system (MFM.frames)
    local frames = GetArenaFrames()
    if not frames then
        print("|cffFF0000[REFRESH TEXTURES ERROR]|r No frames found!")
        return
    end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local f = frames[i]
        
        if f and f.healthBar and f.manaBar then
            -- ALWAYS update positioning to ensure spacing changes apply
            -- Position health bar at absolute coordinates
            f.healthBar:ClearAllPoints()
            f.healthBar:SetPoint("TOPLEFT", f, "TOPLEFT", hPos, -vPos)

            -- Position mana bar below health bar with spacing
            f.manaBar:ClearAllPoints()
            f.manaBar:SetPoint("TOPLEFT", f.healthBar, "BOTTOMLEFT", 0, -spacing)
            
            -- CRITICAL: DO NOT re-anchor player name here!
            -- Player names have their own independent positioning system
            -- They should NEVER be affected by health/resource bar positioning

            -- Apply sizing (SetSize doesn't cause flicker)
            f.healthBar:SetSize(healthWidth, healthHeight)
            f.manaBar:SetSize(resourceWidth, resourceHeight)
        end
    end

    -- ONLY update textures if this is a texture change, not positioning/sizing change
    -- This prevents the flash when just moving/resizing bars
    if not skipTextureUpdate then
        -- Apply texture settings ONLY to health and mana bars
        -- Cast bars have their own refresh function and shouldn't be touched here
        local healthTex = db.healthBarTexture or "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture1.tga"
        local powerTex = db.useDifferentPowerBarTexture and db.powerBarTexture or healthTex

        for i = 1, MAX_ARENA_ENEMIES do
            -- Use same frame source as above (unified system)
            local f = frames[i]
            
            if f and f.healthBar then
                f.healthBar:SetStatusBarTexture(healthTex)
                
                -- CRITICAL FIX: Reapply background vertex color after texture refresh
                -- SetStatusBarTexture may reset the background layer, causing white background bug
                -- This ensures the dark gray background (0.3, 0.3, 0.3) is always maintained
                if f.healthBar.bg then
                    f.healthBar.bg:SetVertexColor(0.3, 0.3, 0.3, 1)
                end
            end
            if f and f.manaBar then
                f.manaBar:SetStatusBarTexture(powerTex)
                
                -- CRITICAL FIX: Reapply mana bar background vertex color after texture refresh
                -- Same issue as health bar - prevent white background on mana bar
                if f.manaBar.bg then
                    f.manaBar.bg:SetVertexColor(0.3, 0.3, 0.3, 1)
                end
            end
        end
    end
end

function AC:RefreshBarTextures()
    local db = (self.DB and self.DB.profile and self.DB.profile.textures)
    if not db then return end
    local healthTex = db.healthBarTexture
    local powerTex = db.useDifferentPowerBarTexture and db.powerBarTexture or healthTex
    local castTex = db.useDifferentCastBarTexture and db.castBarTexture or powerTex
    
    -- Helper to try both backslash and forward slash paths
    local function SetTextureSafe(textureObj, path)
        if not path then return false end
        local success = textureObj:SetTexture(path)
        if not success then
            -- Fallback: try with forward slashes
            local altPath = path:gsub("\\", "/")
            success = textureObj:SetTexture(altPath)
        end
        return success
    end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local f = GetArenaFrames()[i]
        if f then
            if f.healthBar and f.healthBar.fill then 
                SetTextureSafe(f.healthBar.fill, healthTex)
                -- CRITICAL FIX: Reapply background vertex color after texture changes
                if f.healthBar.bg then
                    f.healthBar.bg:SetVertexColor(0.3, 0.3, 0.3, 1)
                end
            end
            if f.manaBar and f.manaBar.fill then 
                SetTextureSafe(f.manaBar.fill, powerTex)
                -- CRITICAL FIX: Reapply mana bar background vertex color
                if f.manaBar.bg then
                    f.manaBar.bg:SetVertexColor(0.3, 0.3, 0.3, 1)
                end
            end
            -- Cast bar texture update (uses StatusBar texture)
            if f.castBar then
                if castTex then
                    -- Midnight compatibility: Update stored texture and use original method
                    if AC.Midnight and AC.Midnight.isMidnight then
                        f.castBar._arenaCoreTexture = castTex
                        -- Use metatable to bypass our hook
                        local mt = getmetatable(f.castBar).__index
                        if mt and mt.SetStatusBarTexture then
                            mt.SetStatusBarTexture(f.castBar, castTex)
                        end
                    else
                        f.castBar:SetStatusBarTexture(castTex)
                    end
                    -- Update the fill reference
                    f.castBar.fill = f.castBar:GetStatusBarTexture()
                end
            end
        end
    end
end

-- Refresh function used by sliders and Edit Mode for Class Packs (TriBadges)
function AC:RefreshClassPacksLayout()
    if self.TriBadges and self.TriBadges.RefreshAll then
        self.TriBadges:RefreshAll()
    end
end

-- ================= Z-ORDER (STRATA/LEVEL) POLICY =================
-- Prevents overlays (DR icons, TriBadges) from bleeding through UI panels
local Z = {}
AC.ZPolicy = Z

-- Tuned so: Game panels (DIALOG) > our overlays (HIGH) > base frame art (MEDIUM)
Z.STRATA_BASE   = "MEDIUM"
Z.STRATA_OVER   = "HIGH"     -- overlays (DR, TriBadges, etc.)
Z.STRATA_PANEL  = "DIALOG"   -- config/edit UI

-- Apply to one arena frame
function Z:ApplyToFrame(f)
    if not f then return end
    local baseLevel = (f:GetFrameLevel() or 10)

    -- DR holder
    if f.DRHolder then
        f.DRHolder:SetToplevel(false)
        f.DRHolder:SetFrameStrata(self.STRATA_OVER)
        f.DRHolder:SetFrameLevel(baseLevel + 30)
    end

    -- TriBadges holder
    if f.TriBadgesHolder then
        f.TriBadgesHolder:SetToplevel(false)
        f.TriBadgesHolder:SetFrameStrata(self.STRATA_OVER)
        f.TriBadgesHolder:SetFrameLevel(baseLevel + 30)
    end
end

-- Apply to ALL frames
function Z:ApplyAll()
    local arenaFrames = AC.FrameManager and AC.FrameManager:GetFrames()
    if not arenaFrames then return end
    for i = 1, #arenaFrames do
        self:ApplyToFrame(arenaFrames[i])
    end
end

-- When config/edit UI opens
function Z:OnPanelShow()
    self:ApplyAll()
end

-- When panel closes
function Z:OnPanelHide()
    self:ApplyAll()
end

function AC:RefreshCastBarsLayout()
    -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r RefreshCastBarsLayout() entered")
    -- IMPORTANT: This function targets the ONE main cast bar (f.castBar) for each arena frame
    -- There are no old/duplicate cast bars - only the main one created in CreateArenaFrame
    
    -- CRITICAL FIX: Read directly from saved variables, not from DB reference which may have defaults
    local db = _G.ArenaCoreDB and _G.ArenaCoreDB.profile and _G.ArenaCoreDB.profile.castBars
    if not db then 
        -- DEBUG DISABLED: print("|cffFF0000[SPELL ICON ERROR]|r No castBars database found!")
        return 
    end
    -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r Database found, spellIcons.enabled = " .. tostring(db.spellIcons and db.spellIcons.enabled))
    -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r Reading from _G.ArenaCoreDB.profile.castBars.spellIcons.enabled = " .. tostring(_G.ArenaCoreDB.profile.castBars.spellIcons and _G.ArenaCoreDB.profile.castBars.spellIcons.enabled))
    local pos = db.positioning or {}
    local size = db.sizing or {}
    
    -- Get cast bar texture from textures settings
    local texturesDB = self.DB and self.DB.profile and self.DB.profile.textures
    local castTex = nil
    if texturesDB then
        local healthTex = texturesDB.healthBarTexture or "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture1.tga"
        local powerTex = texturesDB.useDifferentPowerBarTexture and texturesDB.powerBarTexture or healthTex
        castTex = texturesDB.useDifferentCastBarTexture and texturesDB.castBarTexture or powerTex
    end
    
    --[[ OLD CAST BAR SYSTEM - DISABLED
    local castModule = GetCastBarModule()
    --]]

    for i = 1, MAX_ARENA_ENEMIES do
        local f = GetArenaFrames()[i]
        if f and f.castBar then
            local cb = f.castBar -- This is the ONE main cast bar
            
            -- Apply positioning settings (works in both test mode and arena mode)
            -- CRITICAL: Default values MUST match Init.lua DEFAULTS.castBars exactly
            cb:ClearAllPoints()
            cb:SetPoint("TOP", f, "TOP", pos.horizontal or -4, pos.vertical or -86)
            cb:SetWidth(size.width or 220)
            cb:SetHeight(size.height or 24)
            cb:SetScale((size.scale or 87) / 100)
            
            -- Apply cast bar texture if available
            if castTex then
                cb:SetStatusBarTexture(castTex)
            end
            
            
            -- Ensure visibility in test mode
            if AC.testModeEnabled then
                cb:SetAlpha(1)
                cb:Show()
                if castModule and castModule.RefreshTestLayout then
                    castModule:RefreshTestLayout(f, db)
                end
            end

            -- Apply Spell Icon settings (affects cb.spellIcon)
            -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r Frame " .. i .. " - Checking spell icon existence")
            -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   cb.spellIcon exists: " .. tostring(cb.spellIcon ~= nil))
            -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   db.spellIcons exists: " .. tostring(db.spellIcons ~= nil))
            if cb.spellIcon and db.spellIcons then
                local idb = db.spellIcons
                
                -- CRITICAL FIX: Use rawget to bypass metatable __index that applies defaults
                -- The metatable returns default (true) instead of saved value (false)
                local enabled = rawget(idb, "enabled")
                if enabled == nil then
                    enabled = true  -- Only use default if value was never set
                end
                
                -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r Frame " .. i .. " - Applying spell icon settings")
                -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   rawget enabled = " .. tostring(enabled))
                -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   scale = " .. tostring(idb.sizing and idb.sizing.scale))
                -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   horizontal = " .. tostring(idb.positioning and idb.positioning.horizontal))
                -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   vertical = " .. tostring(idb.positioning and idb.positioning.vertical))
                
                -- CRITICAL FIX: Use both Hide() and SetAlpha() for Blizzard's Icon
                -- The CastBars module calls Show() which overrides SetAlpha(0)
                if enabled then
                    cb.spellIcon:SetAlpha(1)
                    cb.spellIcon:Show()
                else
                    cb.spellIcon:SetAlpha(0)
                    cb.spellIcon:Hide()
                end
                -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   " .. (enabled and "Show()" or "Hide()") .. " called")

                -- CRITICAL FIX: Hide/show spell icon borders too
                -- Custom spell icons (ArenaCore) may store 4 border textures on the icon frame.
                -- Blizzard/Midnight icon uses a separate _borderFrame.
                -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   Checking borders...")
                -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   cb.spellIcon exists: " .. tostring(cb.spellIcon ~= nil))
                -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   cb.spellIcon._borderFrame exists: " .. tostring(cb.spellIcon and cb.spellIcon._borderFrame ~= nil))
                -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   cb.Icon exists: " .. tostring(cb.Icon ~= nil))
                -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   cb.Icon._borderFrame exists: " .. tostring(cb.Icon and cb.Icon._borderFrame ~= nil))
                
                if cb.spellIcon.border then
                    if cb.spellIcon.border.top then cb.spellIcon.border.top:SetShown(enabled) end
                    if cb.spellIcon.border.bottom then cb.spellIcon.border.bottom:SetShown(enabled) end
                    if cb.spellIcon.border.left then cb.spellIcon.border.left:SetShown(enabled) end
                    if cb.spellIcon.border.right then cb.spellIcon.border.right:SetShown(enabled) end
                    -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   Set border visibility (old style)")
                end
                if cb.spellIcon.styledBorder then
                    if cb.spellIcon.styledBorder.top then cb.spellIcon.styledBorder.top:SetShown(enabled) end
                    if cb.spellIcon.styledBorder.bottom then cb.spellIcon.styledBorder.bottom:SetShown(enabled) end
                    if cb.spellIcon.styledBorder.left then cb.spellIcon.styledBorder.left:SetShown(enabled) end
                    if cb.spellIcon.styledBorder.right then cb.spellIcon.styledBorder.right:SetShown(enabled) end
                    -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   Set styledBorder visibility")
                end
                if cb.spellIcon._borderFrame then
                    cb.spellIcon._borderFrame:SetShown(enabled)
                    -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   Set _borderFrame visibility on spellIcon: " .. tostring(enabled))
                end
                -- CRITICAL FIX: Also check the original Blizzard icon for borders
                -- AddSpellIconBorder creates borders on castBar.Icon, not cb.spellIcon
                if cb.Icon and cb.Icon._borderFrame then
                    cb.Icon._borderFrame:SetShown(enabled)
                    -- DEBUG DISABLED: print("|cffFF00FF[SPELL ICON DEBUG]|r   Set _borderFrame visibility on Icon: " .. tostring(enabled))
                end

                -- CRITICAL FIX: Ensure proper table structure (don't reset, just ensure it exists)
                if not idb.sizing or type(idb.sizing) ~= "table" then
                    idb.sizing = {}
                end
                if not idb.sizing.scale then
                    idb.sizing.scale = 100
                end
                
                if not idb.positioning or type(idb.positioning) ~= "table" then
                    idb.positioning = {}
                end
                if not idb.positioning.horizontal then
                    idb.positioning.horizontal = -4
                end
                if not idb.positioning.vertical then
                    idb.positioning.vertical = 0
                end
                
                -- CRITICAL FIX: Ensure enabled has a default value if nil (but don't override false!)
                if idb.enabled == nil then
                    idb.enabled = true
                end

                -- CRITICAL FIX: Use SetScale() instead of SetSize() (like sArena does)
                -- The spell icon is created at 16x16 base size, we scale it from there
                local scalePct = (idb.sizing and idb.sizing.scale or 100) / 100
                cb.spellIcon:SetScale(scalePct)

                -- Position relative to the bar
                local ix = (idb.positioning and idb.positioning.horizontal) or -4
                local iy = (idb.positioning and idb.positioning.vertical) or 0
                cb.spellIcon:ClearAllPoints()
                cb.spellIcon:SetPoint("RIGHT", cb, "LEFT", ix, iy)
            end
            
            -- CRITICAL FIX: Update cast bar color when spell school colors setting changes
            -- Only update color in test mode (live mode updates happen during actual casts)
            if AC.testModeEnabled and cb:IsShown() then
                if castModule and castModule.RefreshTestLayout then
                    castModule:RefreshTestLayout(f, db)
                end
            end
            
            -- Update cast bar background style
            if cb.bg then
                local bgStyle = db.backgroundStyle or "Arena Core"
                if bgStyle == "Arena Core" then
                    -- Arena Core style: Original textured background (cast_bg.tga)
                    cb.bg:SetTexture(TEX.cast_bg, true, true)
                    cb.bg:SetTexCoord(0, 1, 0, 1)
                else
                    -- Midnight style: Simple dark/transparent fill
                    cb.bg:SetTexture(nil)
                    cb.bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)
                end
                -- CRITICAL FIX: Show background (EnteredArena hides it, but never shows it again)
                cb.bg:Show()
            end
        end
    end
end

function AC:RefreshDRLayout()
    local drModule = GetDRModule()
    if drModule and drModule.RefreshLayout then
        drModule:RefreshLayout()
    end
end

-- ============================================================================
-- ELEMENT UPDATE HELPER - Used by trinkets/other layout refreshers
-- ============================================================================

local function UpdateElement(frame, dbPath, fontPath, skipReposition)
    if not frame then return end
    
    -- OPTION 1 FIX: Always read from GLOBAL database to get fresh data
    -- AC.DB.profile might be stale, but _G.ArenaCoreDB.profile is always current
    local globalDB = _G.ArenaCoreDB and _G.ArenaCoreDB.profile
    local db = (globalDB and globalDB[dbPath]) or {}
    
    
    -- Handle enabled state (nil or true = enabled, false = disabled)
    local enabled = db.enabled
    if enabled == nil then enabled = true end -- Default to enabled if not set
    
    if not enabled then
        frame:Hide()
        return
    else
        -- COMBAT PROTECTED: Only show frame outside combat
        if not InCombatLockdown() then
            frame:Show()
        end
        
        -- CRITICAL FIX: Preserve Edit Mode glow when showing frame
        -- The glow must persist after refresh to maintain visual feedback
        -- MOVED OUTSIDE Show() call so it runs even if frame is already visible
        if AC.EditMode and AC.EditMode.isActive then
            if frame.editModeGlow then frame.editModeGlow:Show() end
            if frame.editModeGlowFrame then frame.editModeGlowFrame:Show() end
            if frame.editModeGlowBorders then
                for _, border in ipairs(frame.editModeGlowBorders) do
                    border:Show()
                end
            end
        end
    end

    local pos = db.positioning or {}
    local size = db.sizing or {}
    
    -- CRITICAL FIX: Skip repositioning if requested (prevents jump after Edit Mode save)
    -- When skipReposition is true, we only update scale/visibility/fonts, not position
    if not skipReposition then
        -- CRITICAL FIX: EDIT MODE + SLIDER INTEGRATION
        -- Final position = Edit Mode base + Slider offset
        -- This allows both systems to work together without jumping
        
        -- Try to get Edit Mode base position first
        local editModeBaseX = pos.draggedBaseX or 0
        local editModeBaseY = pos.draggedBaseY or 0
        
        -- Try to get slider offset
        local sliderOffsetX = pos.sliderOffsetX or 0
        local sliderOffsetY = pos.sliderOffsetY or 0
        
        -- CRITICAL FIX: Check if horizontal/vertical values have changed from slider
        -- If they have, we should use them directly instead of Edit Mode base + offset
        -- This allows sliders to work even after Edit Mode was used
        local hasEditModeBase = (pos.draggedBaseX ~= nil or pos.draggedBaseY ~= nil)
        local hasSliderValues = (pos.horizontal ~= nil or pos.vertical ~= nil)
        
        local finalX, finalY
        -- ALWAYS use horizontal/vertical directly - these are the source of truth
        -- Sliders save to these values, so we should always respect them
        finalX = pos.horizontal or 0
        finalY = pos.vertical or 0
        
        -- CRITICAL FIX: Set scale BEFORE position!
        -- Setting scale after position causes the position to be wrong
        -- because scaling changes the frame's effective position
        local targetScale = (size.scale or 100) / 100
        
        
        frame:SetScale(targetScale)
        
        frame:ClearAllPoints()
        
        
        frame:SetPoint("CENTER", frame:GetParent(), "CENTER", finalX, finalY)
    end

    if fontPath and size.fontSize then
        local textObject = frame[fontPath]
        
        -- CRITICAL FIX: Create text object if it doesn't exist (for old frames)
        if not textObject and frame.cooldown then
            textObject = frame.cooldown:CreateFontString(nil, "OVERLAY")
            textObject:SetFont("Interface\\\\AddOns\\\\ArenaCore\\\\Media\\\\Fonts\\\\arenacore.ttf", size.fontSize, "OUTLINE")
            textObject:SetPoint("CENTER", frame.cooldown, "CENTER", 0, 0) -- Anchor to center of cooldown
            textObject:SetTextColor(1, 1, 1, 1)
            frame.cooldown.Text = textObject
            frame[fontPath] = textObject
            -- Font created
        elseif textObject and textObject.SetFont then
            -- CRITICAL FIX: GetFont() can return nil, use SafeSetFont instead
            if AC.SafeSetFont then
                AC.SafeSetFont(textObject, AC.FONT_PATH, size.fontSize, "OUTLINE")
            else
                local font, _, flags = textObject:GetFont()
                -- If GetFont returns nil, use fallback
                if not font or font == "" then
                    font = "Fonts\\\\FRIZQT__.TTF"
                    flags = "OUTLINE"
                end
                textObject:SetFont(font, size.fontSize, flags)
            end
            -- Font updated
        end
    end
end

function AC:RefreshTrinketsOtherLayout()
    -- CRITICAL FIX: Prevent rapid successive calls that cause position jumping
    -- When theme swaps happen, multiple systems call this function in quick succession
    -- Each call reads potentially stale scale values, causing positions to jump
    local now = GetTime()
    if self._lastRefreshTrinketsTime and (now - self._lastRefreshTrinketsTime) < 0.1 then
        return
    end
    self._lastRefreshTrinketsTime = now
    
    -- Update spec icons using the main Layout system (once for all frames)
    
    -- CRITICAL: Refresh trinket icons when settings change
    self:RefreshTrinketIcons()
    
    local frames = GetArenaFrames()
    -- Refreshing trinkets/other
    
    -- CRITICAL FIX: Check if we should skip repositioning (post-save refresh)
    local skipReposition = self._skipRepositionOnRefresh or false
    
    for i = 1, MAX_ARENA_ENEMIES do
        local f = frames and frames[i]
        -- Processing frame
        if f then
            -- Update trinket, racial, and specIcon - call UpdateElement directly
            -- Pass skipReposition flag to prevent jump after Edit Mode save
            UpdateElement(f.trinketIndicator, "trinkets", "text", skipReposition)
            UpdateElement(f.racialIndicator, "racials", "text", skipReposition)
            UpdateElement(f.specIcon, "specIcons", nil, skipReposition)
            
            -- Apply Class Icons settings WITHOUT hiding the frame so the spec chip remains independent
            if f.classIcon and self.DB and self.DB.profile and self.DB.profile.classIcons then
                local db = self.DB.profile.classIcons
                local pos = db.positioning or {}
                local size = db.sizing or {}
                local enabled = (db.enabled ~= false)
                
                -- Always keep the classIcon frame shown so specChip can display even if main icon is disabled
                f.classIcon:Show()
                
                -- CRITICAL FIX: Preserve Edit Mode glow when showing class icon frame
                -- This ensures the glow persists after refresh (same as UpdateElement)
                if AC.EditMode and AC.EditMode.isActive then
                    if f.classIcon.editModeGlow then f.classIcon.editModeGlow:Show() end
                    if f.classIcon.editModeGlowFrame then f.classIcon.editModeGlowFrame:Show() end
                    if f.classIcon.editModeGlowBorders then
                        for _, border in ipairs(f.classIcon.editModeGlowBorders) do
                            border:Show()
                        end
                    end
                end
                
                -- CRITICAL FIX: Skip repositioning if requested (prevents jump after Edit Mode save)
                -- ALSO skip if a different element's slider is being changed (prevents cross-element jumping)
                -- ALSO skip if player name sliders are being moved (prevents jump when adjusting text)
                local isClassIconChange = self._currentSettingPath and self._currentSettingPath:match("classIcons%.")
                local shouldSkipReposition = skipReposition or 
                                             (self._currentSettingPath and not isClassIconChange) or
                                             self._skipClassIconReposition
                
                if not shouldSkipReposition then
                    -- CRITICAL FIX: Only reposition if position actually changed
                    -- Multiple SetPoint() calls cause floating-point drift!
                    local currentX = pos.horizontal or 0
                    local currentY = pos.vertical or 0
                    local lastX = f.classIcon._lastSetX
                    local lastY = f.classIcon._lastSetY
                    
                    -- Skip if position hasn't changed (prevents drift from redundant SetPoint calls)
                    if lastX == currentX and lastY == currentY then
                        -- Still update scale even if position unchanged
                        local scale = (size.scale or 100) / 100
                        f.classIcon:SetScale(scale)
                    else
                        -- Position changed - apply it
                        
                        -- CRITICAL: Check for theme-specific positioning (The 1500 Special uses RIGHT anchor)
                        local useCompactLayout = false
                        local currentTheme = nil
                        if self.ArenaFrameThemes then
                            currentTheme = self.ArenaFrameThemes:GetCurrentTheme()
                            local theme = self.ArenaFrameThemes.themes and self.ArenaFrameThemes.themes[currentTheme]
                            if theme and theme.positioning and theme.positioning.compactLayout then
                                useCompactLayout = true
                            end
                        end
                        
                        -- Apply scale FIRST (Bartender4 pattern)
                        local scale = (size.scale or 100) / 100
                        f.classIcon:SetScale(scale)
                    
                    -- Apply positioning AFTER scale - use theme-appropriate anchor
                    f.classIcon:ClearAllPoints()
                    
                    -- REVERTED: Back to frame-relative anchoring (original system)
                    -- UIParent anchoring broke the positioning system
                    local xOffset = (pos.horizontal or 0)
                    local yOffset = (pos.vertical or 0)
                    
                    -- NO SCALE COMPENSATION - positions are frame-relative, not UIParent-relative
                    -- Bartender4 needs scale compensation because it anchors to UIParent
                    -- We anchor to the arena frame, so scale is already accounted for
                    
                    if useCompactLayout then
                        -- The 1500 Special: Position to left of frame
                        f.classIcon:SetPoint("RIGHT", f, "LEFT", xOffset, yOffset)
                    else
                        -- Arena Core: Position to left of frame (original system)
                        f.classIcon:SetPoint("RIGHT", f, "LEFT", xOffset, yOffset)
                    end
                    
                        -- CRITICAL FIX: Save the ACTUAL position WoW set (not the database value!)
                        -- This prevents drift because we compare against what WoW actually rendered
                        local _, _, _, actualX, actualY = f.classIcon:GetPoint()
                        if actualX and actualY then
                            f.classIcon._lastSetX = actualX
                            f.classIcon._lastSetY = actualY
                            
                            -- Also update the database to match reality
                            if self.DB and self.DB.profile and self.DB.profile.classIcons and self.DB.profile.classIcons.positioning then
                                self.DB.profile.classIcons.positioning.horizontal = actualX
                                self.DB.profile.classIcons.positioning.vertical = actualY
                            end
                        end
                        
                        -- Mark that theme positioning has been applied
                        f.classIcon._themePositioned = currentTheme
                    end
                end
                
                -- Toggle only the main class icon visuals; do not affect spec chip
                local alpha = enabled and 1 or 0
                if f.classIcon.background then f.classIcon.background:SetAlpha(alpha) end
                if f.classIcon.icon then f.classIcon.icon:SetAlpha(alpha) end
                if f.classIcon.overlay then f.classIcon.overlay:SetAlpha(alpha) end
                
                -- CRITICAL: Update border thickness AFTER scale is applied
                -- Use C_Timer to ensure scale has been processed
                if f.classIcon.UpdateBorderThickness then
                    C_Timer.After(0, function()
                        if f.classIcon and f.classIcon.UpdateBorderThickness then
                            f.classIcon:UpdateBorderThickness()
                        end
                    end)
                end
            end
        end
    end
    
    -- CRITICAL: Refresh aura insets after border thickness changes
    -- This ensures auras sit inside the orange border at all thickness settings
    if self.AuraTracker and self.AuraTracker.RefreshAllAuraScaling then
        C_Timer.After(0.05, function()
            if self.AuraTracker and self.AuraTracker.RefreshAllAuraScaling then
                self.AuraTracker:RefreshAllAuraScaling()
            end
        end)
    end
    
end

function AC:RefreshMoreGoodiesLayout()
    -- Allow refresh in test mode for real-time preview
    
    -- Get frames from unified system
    local frames = GetArenaFrames()
    if not frames and self.FrameManager and self.FrameManager.GetFrames then
        frames = self.FrameManager:GetFrames()
    end

    -- Check if absorbs feature is enabled (matches Absorbs module logic)
    local moreGoodiesDB = self.DB and self.DB.profile and self.DB.profile.moreGoodies
    local absorbsEnabled = true -- Default to true if setting doesn't exist
    if moreGoodiesDB and moreGoodiesDB.absorbs then
        absorbsEnabled = moreGoodiesDB.absorbs.enabled ~= false
    end
    
    -- MoreGoodies refresh
    if UpdateAbsorbBar and frames then
        for i = 1, #frames do
            local f = frames[i]
            if f then pcall(UpdateAbsorbBar, f) end
        end
    end
    
    -- CRITICAL FIX: Refresh immunity glows when absorbs checkbox changes
    if self.ImmunityTracker then
        if absorbsEnabled then
            -- Absorbs enabled - refresh all immunity glows
            if self.ImmunityTracker.RefreshAll then
                self.ImmunityTracker:RefreshAll()
            end
        else
            -- Absorbs disabled - hide all immunity glows
            if self.ImmunityTracker.HideAll then
                self.ImmunityTracker:HideAll()
            end
        end
    end
    
    -- CRITICAL FIX: Hide/show shield textures when absorbs checkbox changes
    if self.Absorbs then
        if absorbsEnabled then
            -- Absorbs enabled - show lines if in test mode
            if self.testModeEnabled and self.Absorbs.ForceShowLines then
                self.Absorbs:ForceShowLines()
            end
        else
            -- Absorbs disabled - hide all shield textures
            if self.Absorbs.HideLines then
                self.Absorbs:HideLines()
            end
            -- Also hide live absorb textures
            for i = 1, 3 do
                if self.Absorbs.HideAbsorbLines then
                    self.Absorbs:HideAbsorbLines(i)
                end
            end
        end
    end
    
    -- CRITICAL FIX: Re-apply test mode data after refresh if in test mode
    -- The refresh above calls UpdateAbsorbBar which hides test absorbs/glows
    -- We need to re-apply the test data to show them again
    if self.testModeEnabled and absorbsEnabled then
        local MFM = _G.ArenaCore and _G.ArenaCore.MasterFrameManager
        if MFM and MFM.ApplyTestData then
            MFM:ApplyTestData()
        end
    end

    -- 2) Party class indicators
    if self.UpdatePartyClassIndicators then
        self:UpdatePartyClassIndicators()
    end
end

function AC:RefreshClassPacksLayout()
    -- Real-time refresh for Class Packs (TriBadges) settings
    -- Called when sliders or checkbox change on Class Packs page
    -- CRITICAL: Only update TriBadges, don't touch main arena frames!
    
    if AC.TriBadges and AC.TriBadges.RefreshAll then
        AC.TriBadges:RefreshAll()
    end
    
    -- NEW FEATURE: Update timer font sizes when font size slider changes
    if AC.TriBadges and AC.TriBadges.UpdateTimerFontSize then
        AC.TriBadges:UpdateTimerFontSize()
    end
end

-- ============================================================================
-- FRAME PROPERTY UPDATERS - Connect frame properties to settings
-- ============================================================================

function AC:UpdateFramePosition()
    local settings = GetFrameSettings()
    if not settings then return end
    
    local positioning = settings.positioning or {}
    local x = tonumber(positioning.horizontal) or 200
    local y = tonumber(positioning.vertical) or -200
    
    -- Enforce WoW TOPLEFT semantics and screen bounds
    if y > 0 then y = -math.abs(y) end
    local w = UIParent:GetWidth() or 1920
    local h = UIParent:GetHeight() or 1080
    if x > w or x < -w then x = 200 end
    if y > h or y < -h then y = -200 end
    
    -- Store in database (avoid undefined config global)
    self:EnsureDB()
    self:SetPath(self.DB.profile, "arenaFrames.positioning.horizontal", x)
    self:SetPath(self.DB.profile, "arenaFrames.positioning.vertical", y)
end

function AC:UpdateFrameSpacing()
    local settings = GetFrameSettings()
    if not settings then return end
    
    local positioning = settings.positioning or {}
    -- Update spacing (avoid undefined FRAME_SPACING global)
    if self.FrameManager and self.FrameManager.UpdateSpacing then
        local spacing = positioning.spacing
        if not spacing or spacing == 0 then spacing = 21 end
        self.FrameManager:UpdateSpacing(spacing)
    end
end

function AC:UpdateFrameScale()
    -- CRITICAL: Cannot call SetScale during combat lockdown (UNLESS in test mode)
    -- Test mode frames are safe to modify during combat since they're not secure
    if InCombatLockdown() and not self.testModeEnabled then
        return
    end
    
    local settings = GetFrameSettings()
    if not settings then return end
    
    local sizing = settings.sizing or {}
    local scale = (sizing.scale or 100) / 100
    
    -- Apply to FrameLayout frames with null safety
    local arenaFrames = GetArenaFrames()
    if arenaFrames then
        for i = 1, MAX_ARENA_ENEMIES do
            if arenaFrames[i] then
                arenaFrames[i]:SetScale(scale)
            end
        end
    end
end

function AC:UpdateFrameSize()
    -- CRITICAL: Cannot call SetSize during combat lockdown (UNLESS in test mode)
    -- Test mode frames are safe to modify during combat since they're not secure
    if InCombatLockdown() and not self.testModeEnabled then
        return
    end
    
    local settings = GetFrameSettings()
    if not settings then return end
    
    local sizing = settings.sizing or {}
    local frameWidth = sizing.width or 350
    local frameHeight = sizing.height or 72
    
    -- CRITICAL FIX: Get bar sizes from textures database, NOT calculated from frame width
    -- This respects user's bar size settings from Textures page
    local texDb = self.DB and self.DB.profile and self.DB.profile.textures
    local healthWidth = (texDb and texDb.sizing and texDb.sizing.healthWidth) or 128
    local healthHeight = (texDb and texDb.sizing and texDb.sizing.healthHeight) or 18
    local resourceWidth = (texDb and texDb.sizing and texDb.sizing.resourceWidth) or 136
    local resourceHeight = (texDb and texDb.sizing and texDb.sizing.resourceHeight) or 8
    
    -- DEBUG: Using bar sizes
    -- print("|cffFFFF00[UPDATE FRAME SIZE]|r Using bar sizes - healthWidth: " .. healthWidth .. ", resourceWidth: " .. resourceWidth)
    
    -- Apply to FrameLayout frames with null safety
    local arenaFrames = GetArenaFrames()
    if not arenaFrames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        if arenaFrames[i] then
            local f = arenaFrames[i]
            
            -- Update frame dimensions
            f:SetSize(frameWidth, frameHeight)
            
            -- Update health and mana bars using TEXTURES database sizes (NOT calculated from frame width)
            if f.healthBar then
                f.healthBar:SetSize(healthWidth, healthHeight)
            end
            
            if f.manaBar then
                f.manaBar:SetSize(resourceWidth, resourceHeight)
            end
            
            -- Update cast bar sizing - handled by RefreshCastBarsLayout
            -- No need to update here as cast bars have their own refresh function
        end
    end
end

function AC:SetGrowthDirection(direction)
    if not direction or not tContains({"Down", "Up", "Right", "Left"}, direction) then return end
    
    -- Store in database (avoid undefined config global)
    local settings = GetFrameSettings()
    if settings then
        settings.positioning = settings.positioning or {}
        settings.positioning.growthDirection = direction
        
        -- Notify FrameLayout system of growth direction change
        if self.FrameManager and self.FrameManager.UpdateGrowthDirection then
            self.FrameManager:UpdateGrowthDirection(direction)
        end
    end
end

function AC:ResetToDefaultSettings()
    if not self.DB or not self.DB.profile then return end
    local defaults = {
        positioning = { horizontal = 200, vertical = -200, spacing = 12, growthDirection = "Down" },
        sizing = { scale = 100, width = 350, height = 72 }
    }
    self.DB.profile.arenaFrames = self.DB.profile.arenaFrames or {}
    self.DB.profile.arenaFrames.positioning = defaults.positioning
    self.DB.profile.arenaFrames.sizing = defaults.sizing
    config.position.x = defaults.positioning.horizontal
    config.position.y = defaults.positioning.vertical
    config.growthDirection = defaults.positioning.growthDirection
    config.scale = defaults.sizing.scale / 100
    FRAME_SPACING = defaults.positioning.spacing
    FRAME_WIDTH = defaults.sizing.width
    FRAME_HEIGHT = defaults.sizing.height
    self:UpdateFramePosition()
    self:UpdateFrameSpacing()
    self:UpdateFrameScale()
    self:UpdateFrameSize()
    if self.configFrame and self.configFrame:IsShown() and self.RefreshConfigUI then
        self:RefreshConfigUI()
    end
end

-- ============================================================================
-- TRINKET ICON REFRESH SYSTEM - Handle trinket design changes
-- ============================================================================

function AC:RefreshTrinketIcons()
    -- Use the correct frame array that has trinket indicators
    local frames = self.arenaFrames or GetArenaFrames()
    
    -- Also handle new FrameManager frames
    if self.FrameManager and self.FrameManager.GetFrames then
        local fmFrames = self.FrameManager:GetFrames()
        if fmFrames and #fmFrames > 0 then
            frames = fmFrames
        end
    end
    
    -- DEBUG: Refreshing trinket icons
    -- print("|cff00FFFF[RefreshTrinketIcons]|r Refreshing trinket icons for " .. (#frames or 0) .. " frames")
    
    for i = 1, MAX_ARENA_ENEMIES do
        if frames[i] and frames[i].trinketIndicator then
            -- Get the custom trinket icon - this now returns a texture ID ready for SetTexture()
            local trinketTexture = GetTrinketIcon()
            
            -- DEBUG: Trinket texture
            -- print("|cff00FFFF[RefreshTrinketIcons]|r Frame " .. i .. " trinket texture: " .. tostring(trinketTexture))
            
            if trinketTexture then
                -- Use .icon property based on CreateTrinket function (FrameManager structure)
                if frames[i].trinketIndicator.icon then
                    frames[i].trinketIndicator.icon:SetTexture(trinketTexture)
                    frames[i].trinketIndicator.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                    -- DEBUG: Icon set
                    -- print("|cff00FF00[RefreshTrinketIcons SUCCESS]|r Set icon for frame " .. i)
                elseif frames[i].trinketIndicator.texture then
                    frames[i].trinketIndicator.texture:SetTexture(trinketTexture)
                    frames[i].trinketIndicator.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                    -- DEBUG: Texture set
                    -- print("|cff00FF00[RefreshTrinketIcons SUCCESS]|r Set texture for frame " .. i)
                end
            end
        end
    end
end

-- ============================================================================
-- CLASS ICON REFRESH SYSTEM - Handle class icon theme changes
-- ============================================================================

function AC:RefreshClassIcons()
    -- Use the correct frame array that has class icons
    local frames = self.arenaFrames or GetArenaFrames()
    
    -- Also handle new FrameManager frames
    if self.FrameManager and self.FrameManager.GetFrames then
        local fmFrames = self.FrameManager:GetFrames()
        if fmFrames and #fmFrames > 0 then
            frames = fmFrames
        end
    end
    
    for i = 1, MAX_ARENA_ENEMIES do
        if frames[i] and frames[i].classIcon then
            -- Call UpdateClassIcon if it exists (it should update based on current theme)
            if frames[i].classIcon.UpdateClassIcon then
                frames[i].classIcon.UpdateClassIcon()
            end
        end
    end
end

-- ============================================================================
-- CLASS COLORS HELPER - Consistent class color settings access
-- ============================================================================
-- REMOVED DUPLICATE: This function is already defined at line 1208 and line 9927
-- Keeping the simpler version at line 9927 as the authoritative one

-- ============================================================================
-- CHUNK 10: TEST MODE SYSTEM
-- Complete test mode functionality with frame protection and realistic data
-- ============================================================================

-- ============================================================================
-- TEST MODE STATE MANAGEMENT
-- ============================================================================

AC.testModeEnabled = false
AC.framesLocked = true

-- Test mode configuration
local testModeConfig = {
    playerNames = {
        [1] = "Survivable",
        [2] = "Patymorph", 
        [3] = "Easymodex"
    },
    testClasses = {"DEATHKNIGHT", "MAGE", "HUNTER"},
    testSpecs = {
        [1] = 250, -- Death Knight Unholy
        [2] = 62,  -- Mage Arcane  
        [3] = 253  -- Hunter Beast Mastery
    }
}

-- ============================================================================
-- MAIN TEST MODE FUNCTIONS
-- ============================================================================

-- Setup test debuffs for demonstration in test mode
function FrameManager:SetupTestDebuffs(frame, testClass)
    local debuffModule = GetDebuffModule()
    if debuffModule and debuffModule.ApplyTestDebuffs then
        return debuffModule:ApplyTestDebuffs(frame, testClass)
    end

    if not frame.debuffContainer then return end
    
    -- CRITICAL FIX: Prevent re-running if already set up to avoid flickering
    if frame.debuffContainer.testDebuffsActive then return end
    
    -- Check if debuffs are enabled
    local debuffSettings = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.debuffs
    if not debuffSettings or not debuffSettings.enabled then
        frame.debuffContainer:Hide()
        frame.debuffContainer.testDebuffsActive = false
        return
    end
    
    -- Get max count and scaling from settings (default 6, 100%)
    local maxCount = debuffSettings.maxCount or 6
    local scale = (debuffSettings.sizing and debuffSettings.sizing.scale or 100) / 100
    
    -- UNIVERSAL TEST DEBUFFS: 8 proper spells that work regardless of user's maxCount setting
    -- These are real debuff spells with proper icons (not class-specific, works for all frames)
    -- NEW FEATURE: Added duration field for countdown timer testing
    local testDebuffs = {
        {spellID = 589, icon = "Interface\\Icons\\spell_shadow_shadowwordpain", count = 1, duration = 18},      -- Shadow Word: Pain (18s)
        {spellID = 30108, icon = "Interface\\Icons\\spell_shadow_unstableaffliction_3", count = 1, duration = 12}, -- Unstable Affliction (12s)
        {spellID = 191587, icon = "Interface\\Icons\\spell_shadow_plaguecloud", count = 1, duration = 8},      -- Virulent Plague (8s)
        {spellID = 703, icon = "Interface\\Icons\\ability_rogue_garrote", count = 1, duration = 15},            -- Garrote (15s)
        {spellID = 164812, icon = "Interface\\Icons\\spell_nature_starfall", count = 2, duration = 10},         -- Moonfire (10s, 2 stacks)
        {spellID = 20271, icon = "Interface\\Icons\\spell_holy_righteousfury", count = 1, duration = 6},       -- Judgment (6s)
        {spellID = 772, icon = "Interface\\Icons\\ability_gouge", count = 1, duration = 12},                    -- Rend (12s)
        {spellID = 1715, icon = "Interface\\Icons\\ability_shockwave", count = 1, duration = 8}                -- Hamstring (8s)
    }
    
    -- No need for class-specific debuffs - these 8 universal debuffs work for all frames
    local debuffs = testDebuffs
    if not debuffs then return end
    
    local function Trim(texture)
        if texture and texture.SetTexCoord then 
            texture:SetTexCoord(0.002, 0.998, 0.002, 0.998) 
        end 
    end
    
    local c = frame.debuffContainer
    c:Show() -- Show container for test mode
    
    -- First, hide ALL existing debuff frames
    for i = 1, #c.debuffs do 
        if c.debuffs[i] then
            c.debuffs[i]:SetAlpha(0)
            c.debuffs[i]:Hide()
        end
    end
    
    -- Limit debuffs to user's max count setting
    local actualDebuffs = {}
    for i = 1, math.min(#debuffs, maxCount) do
        table.insert(actualDebuffs, debuffs[i])
    end
    
    -- Create test debuff icons with new styling and scaling
    for i, debuffData in ipairs(actualDebuffs) do
        if not c.debuffs[i] then 
            local frameSize = 20 * scale
            local iconSize = 16 * scale
            local spacing = 23 * scale
            
            local d = CreateFrame("Frame", nil, c)
            d:SetSize(frameSize, frameSize)
            d:SetPoint("LEFT", (i-1) * spacing, 0)
            d:SetFrameStrata("MEDIUM") -- CRITICAL: Use MEDIUM to stay below bags
            d:SetFrameLevel(30) -- Lower level within MEDIUM strata
            
            -- Black square background (like Blackout Aura editor)
            local bg = d:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(1, 1, 1, 1) -- White background first
            bg:SetVertexColor(0.1, 0.1, 0.1, 0.8) -- Dark background
            
            -- Black square border
            local border = AC:CreateFlatTexture(d, "BORDER", 1, {0, 0, 0, 1}, 1)
            border:SetAllPoints()
            
            -- Inner border for clean square look
            local innerBg = AC:CreateFlatTexture(d, "BACKGROUND", 2, {0.15, 0.15, 0.15, 1}, 1)
            innerBg:SetPoint("TOPLEFT", 1, -1)
            innerBg:SetPoint("BOTTOMRIGHT", -1, 1)
            
            -- Icon
            local icon = d:CreateTexture(nil, "ARTWORK")
            icon:SetSize(iconSize, iconSize)
            icon:SetPoint("CENTER")
            Trim(icon)
            
            -- Stack count text (scaled)
            local stack = d:CreateFontString(nil, "OVERLAY")
            local fontSize = math.max(6, 7 * scale)
            stack:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", fontSize, "OUTLINE")
            stack:SetPoint("BOTTOMRIGHT", 2, -2)
            stack:SetTextColor(1, 1, 1, 1) -- White text
            
            -- NEW FEATURE: Cooldown frame for test mode countdown (using helper to block OmniCC)
            local cd = AC:CreateCooldown(d, nil, "CooldownFrameTemplate")
            cd:SetAllPoints(d)
            cd:SetHideCountdownNumbers(true)
            cd:SetDrawEdge(false)
            cd.noCooldownCount = true
            
            -- NEW FEATURE: Countdown timer text for test mode
            local timerFontSize = (debuffSettings.timerFontSize) or 10
            local timer = cd:CreateFontString(nil, "OVERLAY")
            timer:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", timerFontSize, "OUTLINE")
            timer:SetPoint("CENTER", cd, "CENTER", 0, 0)
            timer:SetTextColor(1, 1, 1, 1)
            cd.Text = timer
            
            d.icon = icon
            d.stack = stack
            d.cooldown = cd
            d.timer = timer
            c.debuffs[i] = d
        end
        
        -- Update test debuff display
        local d = c.debuffs[i]
        d:SetAlpha(1)
        d:Show() -- Ensure frame is visible
        d.icon:SetTexture(debuffData.icon)
        
        -- Show stack count
        if debuffData.count and debuffData.count > 1 then 
            d.stack:SetText(debuffData.count)
            d.stack:Show()
        else 
            d.stack:Hide()
        end
        
        -- NEW FEATURE: Test mode countdown timers
        local showTimer = debuffSettings.showTimer
        if showTimer == nil then showTimer = true end
        
        if showTimer and d.cooldown and d.timer and debuffData.duration then
            local duration = debuffData.duration
            
            local function StartTestCountdown()
                if not AC.testModeEnabled then return end
                if not d or not d.cooldown then return end
                
                local startTime = GetTime()
                local expirationTime = startTime + duration
                d.cooldown:SetCooldown(startTime, duration)
                
                local function UpdateTimerText()
                    if not d or not d.timer or not AC.testModeEnabled then return end
                    local remaining = expirationTime - GetTime()
                    if remaining > 0 then
                        local minutes = math.floor(remaining / 60)
                        local seconds = math.floor(remaining % 60)
                        local timeText = minutes > 0 and string.format("%d:%02d", minutes, seconds) or string.format("%.0f", remaining)
                        d.timer:SetText(timeText)
                        d.timerUpdate = C_Timer.NewTimer(0.1, UpdateTimerText)
                    else
                        d.timer:SetText("")
                        if d.timerUpdate then d.timerUpdate:Cancel() d.timerUpdate = nil end
                        C_Timer.After(0.5, function()
                            if AC.testModeEnabled and d and d:IsVisible() then StartTestCountdown() end
                        end)
                    end
                end
                UpdateTimerText()
            end
            StartTestCountdown()
        else
            if d.cooldown then d.cooldown:Clear() end
            if d.timer then d.timer:SetText("") end
            if d.timerUpdate then d.timerUpdate:Cancel() d.timerUpdate = nil end
        end
    end
    
    -- CRITICAL FIX: Mark as active to prevent re-running
    frame.debuffContainer.testDebuffsActive = true
end

-- Test debuff mode - called from DebuffsWindow TEST button
function FrameManager:TestDebuffMode()
    local debuffModule = GetDebuffModule()
    if debuffModule and debuffModule.TestMode then
        debuffModule:TestMode()
        return
    end

    if not self:FramesExist() then
        print("|cffFF6B6BArena Core:|r No frames available for testing")
        return
    end
    
    local frames = self:GetFrames()
    local testClasses = {"Deathknight", "Mage", "Hunter"}
    
    for i = 1, #frames do
        if frames[i] and frames[i].debuffContainer then
            frames[i].debuffContainer.testDebuffsActive = false
            local testClass = testClasses[i] or "Mage"
            self:SetupTestDebuffs(frames[i], testClass)
        end
    end
end

-- Refresh debuff settings - called when settings change in DebuffsWindow
function FrameManager:RefreshDebuffSettings()
    if not self:FramesExist() then return end
    
    local frames = self:GetFrames()
    local debuffSettings = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.debuffs
    
    -- Update positioning for all debuff containers
    for i = 1, #frames do
        if frames[i] and frames[i].debuffContainer then
            local c = frames[i].debuffContainer
            
            -- Clear existing positioning and apply new positioning
            c:ClearAllPoints()
            local horizontal = debuffSettings and debuffSettings.positioning and debuffSettings.positioning.horizontal or 8
            local vertical = debuffSettings and debuffSettings.positioning and debuffSettings.positioning.vertical or 6
            c:SetPoint("BOTTOMLEFT", frames[i], "BOTTOMLEFT", horizontal, vertical)
            
            -- Hide all existing debuff frames
            for j = 1, #c.debuffs do 
                if c.debuffs[j] then
                    c.debuffs[j]:SetAlpha(0)
                    c.debuffs[j]:Hide()
                end
            end
            
            -- Clear the debuffs array to force recreation with new scale
            c.debuffs = {}
            
            -- CRITICAL FIX: Clear the active flag to allow re-setup with new settings
            c.testDebuffsActive = false
            
            -- Hide container if debuffs are disabled
            if not debuffSettings or not debuffSettings.enabled then
                c:Hide()
            end
        end
    end
    
    -- Check if any frame is shown (test mode active)
    local inTestMode = false
    for i = 1, #frames do
        if frames[i] and frames[i]:IsShown() then
            inTestMode = true
            break
        end
    end
    
    -- If in test mode and debuffs are enabled, refresh with new settings
    if inTestMode and debuffSettings and debuffSettings.enabled then
        self:TestDebuffMode()
    end
end
-- ============================================================================
-- MASTER FRAME MANAGER TEST MODE FUNCTIONS
-- ============================================================================

function MFM:CreateDragInfoBox()
    -- Only create once
    if self.dragInfoBox then
        self.dragInfoBox:Show()
        -- Restart pulse animation
        if self.dragInfoBox.pulseAnim then
            self.dragInfoBox.pulseAnim:Play()
        end
        return
    end
    
    -- Create small, non-intrusive info box
    local infoBox = CreateFrame("Frame", "ArenaCoreDragInfoBox", UIParent)
    infoBox:SetSize(150, 22)  -- Even more compact!
    infoBox:SetFrameStrata("MEDIUM")  -- Below DIALOG strata (where UI windows are)
    infoBox:SetFrameLevel(50)  -- Lower level so UI windows appear on top
    
    -- Position UPPER LEFT of Arena 1, high and to the left - visible but non-intrusive
    if arenaFrames and arenaFrames[1] then
        infoBox:SetPoint("BOTTOMRIGHT", arenaFrames[1], "TOPLEFT", -15, 40)  -- Higher up for more clearance
    else
        infoBox:SetPoint("CENTER", UIParent, "CENTER", -200, 100)
    end
    
    -- Use frame texture for rounded corners (matches arena frames)
    local bg = infoBox:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(TEX.frame_bg or "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture1.tga")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.9)  -- Dark tint
    
    -- Thin purple accent line at top
    if AC and AC.CreateFlatTexture then
        local topAccent = AC:CreateFlatTexture(infoBox, "OVERLAY", 3, AC.COLORS.PRIMARY or {0.66, 0.33, 0.94, 1}, 1)
        topAccent:SetPoint("TOPLEFT", 0, 0)
        topAccent:SetPoint("TOPRIGHT", 0, 0)
        topAccent:SetHeight(1)  -- Thinner line
    end
    
    -- Compact info text
    local text = infoBox:CreateFontString(nil, "OVERLAY")
    text:SetFont(AC.FONT_PATH or "Fonts\\FRIZQT__.TTF", 10, "OUTLINE")  -- Smaller font
    text:SetPoint("CENTER", 0, 0)
    text:SetText("|cffFFDD00Ctrl+Alt+Click|r to drag")  -- Shorter, gold color
    text:SetJustifyH("CENTER")
    text:SetShadowOffset(1, -1)
    text:SetShadowColor(0, 0, 0, 1)
    
    -- COOL PULSING ANIMATION like class icons!
    -- OPTIMIZED: Faster, smoother animation for professional appearance
    local animGroup = infoBox:CreateAnimationGroup()
    animGroup:SetLooping("REPEAT")
    
    -- Pulse out (scale up + fade out) - FASTER & SMOOTHER
    local scaleOut = animGroup:CreateAnimation("Scale")
    scaleOut:SetDuration(0.8)  -- Faster: 1.5s → 0.8s
    scaleOut:SetScale(1.12, 1.12)  -- Slightly less dramatic for smoothness
    scaleOut:SetSmoothing("IN_OUT")
    
    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetDuration(0.8)  -- Faster: 1.5s → 0.8s
    fadeOut:SetFromAlpha(1.0)
    fadeOut:SetToAlpha(0.7)  -- Less fade for smoother appearance
    fadeOut:SetSmoothing("IN_OUT")
    
    -- Pulse back (scale down + fade in) - FASTER & SMOOTHER
    local scaleIn = animGroup:CreateAnimation("Scale")
    scaleIn:SetDuration(0.8)  -- Faster: 1.5s → 0.8s
    scaleIn:SetScale(0.893, 0.893)  -- Back to original (1.12 * 0.893 ≈ 1.0)
    scaleIn:SetSmoothing("IN_OUT")
    scaleIn:SetOrder(2)
    
    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetDuration(0.8)  -- Faster: 1.5s → 0.8s
    fadeIn:SetFromAlpha(0.7)  -- Match fadeOut target
    fadeIn:SetToAlpha(1.0)
    fadeIn:SetSmoothing("IN_OUT")
    fadeIn:SetOrder(2)
    
    animGroup:Play()
    infoBox.pulseAnim = animGroup
    
    infoBox:Show()
    self.dragInfoBox = infoBox
    
    -- HIDDEN: Drag info box creation happens silently for cleaner user experience
    -- print("|cff8B45FFArena Core:|r Drag info box created with pulse animation!")
end

function MFM:EnableTestMode()
    if isTestMode then return end
    
    -- CRITICAL FIX: Initialize MFM if not already done (for new users clicking TEST early)
    if not self.frames[1] then
        self:Initialize()
    end
    
    -- CRITICAL FIX: AGGRESSIVELY CLEAR ALL ARENA DATA BEFORE ENABLING TEST MODE
    -- This ensures NO arena data leaks into test mode (auras, debuffs, cast bars, etc.)
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = self.frames[i]
        if frame then
            -- Clear unit token
            frame.unit = nil
            
            -- Clear TriBadges auras (the "Frozen" icon you saw)
            if frame.TriBadges then
                for j = 1, 3 do
                    local badge = frame.TriBadges[j]
                    if badge then
                        badge:Hide()
                        badge:SetAlpha(0)
                        if badge.icon then
                            badge.icon:SetTexture(nil)
                        end
                        if badge.cooldown then
                            badge.cooldown:Clear()
                        end
                        if badge.timer then
                            badge.timer:SetText("")
                        end
                    end
                end
            end
            
            -- Clear debuffs
            if frame.debuffContainer then
                if frame.debuffContainer.debuffs then
                    for _, debuff in pairs(frame.debuffContainer.debuffs) do
                        if debuff then
                            debuff:Hide()
                            if debuff.icon then debuff.icon:SetTexture(nil) end
                            if debuff.cooldown then debuff.cooldown:Clear() end
                        end
                    end
                    wipe(frame.debuffContainer.debuffs)
                end
                frame.debuffContainer:Hide()
                frame.debuffContainer.testDebuffsActive = false
            end
            
            -- Clear cast bar (don't touch Midnight Blizzard cast bars)
            if frame.castBar and not frame.castBar._isMidnightBlizzardFrame then
                frame.castBar:Hide()
                if frame.castBar.shieldOverlay then
                    frame.castBar.shieldOverlay:Hide()
                end
                if frame.castBar.borders then
                    for _, border in pairs(frame.castBar.borders) do
                        border:Hide()
                    end
                end
            end
            
            -- Clear trinket/racial cooldowns
            if frame.trinketIndicator and frame.trinketIndicator.cooldown then
                frame.trinketIndicator.cooldown:Clear()
            end
            if frame.racialIndicator and frame.racialIndicator.cooldown then
                frame.racialIndicator.cooldown:Clear()
            end
        end
    end
    
    -- SIMPLE FIX: Just sort frames by ID to restore original order
    if self.frames and #self.frames > 0 then
        table.sort(self.frames, function(a, b)
            return (a.id or 0) < (b.id or 0)
        end)
    end
    
    isTestMode = true
    self.isTestMode = true
    
    -- CRITICAL: Set the global test mode flag for TriBadges system
    if _G.ArenaCore then
        _G.ArenaCore.testModeEnabled = true
    end
    
    if AC and AC.Debug then 
        AC.Debug:Print("[FrameLayout] ===== ENABLE TEST MODE START =====")
        -- Debug what coordinates we have BEFORE creating frames
        local db = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.positioning
        if db then
            AC.Debug:Print("[FrameLayout] BEFORE CreateFrames - DB coords: (" .. tostring(db.horizontal) .. ", " .. tostring(db.vertical) .. ")")
        else
            AC.Debug:Print("[FrameLayout] BEFORE CreateFrames - NO DB COORDS FOUND")
        end
        
        -- Check if anchor already exists and where it is
        if AC.ArenaFramesAnchor then
            local anchorX, anchorY = AC.ArenaFramesAnchor:GetCenter()
            AC.Debug:Print("[FrameLayout] BEFORE CreateFrames - Existing anchor at: (" .. tostring(anchorX) .. ", " .. tostring(anchorY) .. ")")
        else
            AC.Debug:Print("[FrameLayout] BEFORE CreateFrames - NO ANCHOR EXISTS")
        end
    end
    
    self:CreateFrames()
    
    if AC and AC.Debug then 
        -- Check where anchor ended up AFTER CreateFrames
        if AC.ArenaFramesAnchor then
            local anchorX, anchorY = AC.ArenaFramesAnchor:GetCenter()
            AC.Debug:Print("[FrameLayout] AFTER CreateFrames - Anchor at: (" .. tostring(anchorX) .. ", " .. tostring(anchorY) .. ")")
        end
    end
    
    -- Update arena state (will create frames if needed)
    self:UpdateArenaState()
    
    if AC and AC.Debug then 
        -- Check where anchor is AFTER UpdateArenaState
        if AC.ArenaFramesAnchor then
            local anchorX, anchorY = AC.ArenaFramesAnchor:GetCenter()
            AC.Debug:Print("[FrameLayout] AFTER UpdateArenaState - Anchor at: (" .. tostring(anchorX) .. ", " .. tostring(anchorY) .. ")")
        end
    end
    
    -- CRITICAL FIX: Set skip reposition flag during test mode initialization
    -- This prevents class icons from jumping when test mode loads
    AC._skipRepositionOnRefresh = true
    
    -- Apply test data to frames
    self:ApplyTestData()
    
    -- CRITICAL FIX: Force UpdateFramePositions() to position frames correctly
    -- This ensures frames are positioned by their ID in test mode
    self:UpdateFramePositions()
    
    -- CRITICAL FIX: Apply Edit Mode saved positions after test data
    -- This ensures trinkets/racials/spec icons respect Edit Mode positioning
    -- Small delay ensures test data is fully applied first
    C_Timer.After(0.05, function()
        if AC.RefreshTrinketsOtherLayout then
            AC:RefreshTrinketsOtherLayout()
        end
    end)
    
    -- Create drag info box (test mode only)
    self:CreateDragInfoBox()
    
    -- Clear skip flag after initialization
    C_Timer.After(0.2, function()
        AC._skipRepositionOnRefresh = false
    end)
    
    -- REMOVED: Alpha protection was blocking stealth system from working
    -- ArenaCore doesn't have alpha protection - it lets stealth system control it
    
    -- CRITICAL: Capture MFM reference for use in deferred callbacks
    local mfm = self
    
    -- Helper function to apply full test mode visibility (used both immediately and after combat)
    local function ApplyTestModeVisibility()
        if not (isTestMode and mfm:FramesExist()) then return end
        
        -- CRITICAL: Double-check we're out of combat before showing secure frames
        if InCombatLockdown() then
            -- print("|cffFF4444ArenaCore DEBUG:|r Still in combat lockdown, deferring 0.5s...")
            C_Timer.After(0.5, ApplyTestModeVisibility)
            return
        end
        
        -- print("|cff8B45FFArenaCore DEBUG:|r Out of combat, showing frames now...")
        
        for i = 1, #arenaFrames do
            local frame = arenaFrames[i]
            if frame then
                -- Don't force alpha - let stealth system control it
                -- frame:SetAlpha(1.0)  -- REMOVED: Blocks prep room 0.5 alpha
                -- CRITICAL: Frames use SecureUnitButtonTemplate - can only show outside combat
                frame:Show()
                -- print("|cff8B45FFArenaCore DEBUG:|r Showed frame " .. i)
                    -- CRITICAL FIX: Respect user settings even in test mode
                    local db = AC.DB and AC.DB.profile
                    local general = db and db.arenaFrames and db.arenaFrames.general or {}
                    
                    -- Always show health and mana bars
                    if frame.healthBar then frame.healthBar:SetAlpha(1.0); frame.healthBar:Show() end
                    if frame.manaBar then frame.manaBar:SetAlpha(1.0); frame.manaBar:Show() end
                    
                    -- Show player name only if enabled
                    if frame.playerName then
                        frame.playerName:SetAlpha(1.0)
                        local showArenaLabels = general.showArenaLabels == true
                        local currentText = frame.playerName:GetText() or ""
                        if general.showNames ~= false or showArenaLabels then
                            frame.playerName:Show()
                        else
                            frame.playerName:Hide()
                        end
                    end
                    
                    -- Show class icon only if enabled
                    if frame.classIcon then
                        frame.classIcon:SetAlpha(1.0)
                        local classEnabled = db and db.classIcons and db.classIcons.enabled
                        if classEnabled ~= false then
                            frame.classIcon:Show()
                        else
                            frame.classIcon:Hide()
                        end
                    end
                    
                    -- Show trinket only if enabled
                    if frame.trinketIndicator then
                        frame.trinketIndicator:SetAlpha(1.0)
                        local trinketEnabled = db and db.trinkets and db.trinkets.enabled
                        if trinketEnabled ~= false then
                            frame.trinketIndicator:Show()
                        else
                            frame.trinketIndicator:Hide()
                        end
                    end
                    
                    -- Show racial only if enabled
                    if frame.racialIndicator then
                        frame.racialIndicator:SetAlpha(1.0)
                        local racialEnabled = db and db.racials and db.racials.enabled
                        if racialEnabled ~= false then
                            frame.racialIndicator:Show()
                        else
                            frame.racialIndicator:Hide()
                        end
                    end
                    
                    if frame.castBar then frame.castBar:SetAlpha(1.0) end
                end
        end
        
        -- CRITICAL FIX: Don't re-apply test data when resuming from combat
        -- Only apply test data during initial test mode activation
        -- DR icons and dispel cooldowns are already set from EnableTestMode()
    end
    
    -- Apply final visibility restoration
    C_Timer.After(0.1, function()
        if isTestMode and self:FramesExist() then
            -- CRITICAL FIX: Frames use SecureUnitButtonTemplate (line 1354), making them SECURE
            -- Cannot show secure frames during combat - must defer until after combat
            if InCombatLockdown() then
                print("|cffFFAA00ArenaCore:|r Test mode will activate after combat ends...")
                -- Register one-time event to show frames after combat
                local combatFrame = CreateFrame("Frame")
                combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                combatFrame:SetScript("OnEvent", function(frame)
                    frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
                    print("|cffFFAA00ArenaCore DEBUG:|r Combat ended, attempting to show frames...")
                    print("|cffFFAA00ArenaCore DEBUG:|r isTestMode = " .. tostring(isTestMode))
                    print("|cffFFAA00ArenaCore DEBUG:|r mfm:FramesExist() = " .. tostring(mfm:FramesExist()))
                    -- CRITICAL FIX: Call helper function which has access to outer scope
                    ApplyTestModeVisibility()
                    print("|cff8B45FFArenaCore:|r Test mode activated!")
                end)
                return
            end
            
            -- Out of combat - apply visibility immediately
            ApplyTestModeVisibility()
        end
    end)
    
    -- CRITICAL: Show absorb lines when test mode is enabled
    C_Timer.After(0.2, function()
        if AC and AC.Absorbs and AC.Absorbs.ForceShowLines then
            AC.Absorbs:ForceShowLines()
            -- DEBUG DISABLED FOR PRODUCTION
            -- print("|cff8B45FFArenaCore:|r Absorb lines activated for test mode!")
        end
    end)
    
    -- CRITICAL: Show DR test icons when test mode is enabled
    -- This ensures DR icons appear after leaving arena and re-enabling test mode
    C_Timer.After(0.3, function()
        if isTestMode and self:FramesExist() then
            -- Call DR module to show test icons
            if AC.DR and AC.DR.ShowTestIcons then
                AC.DR:ShowTestIcons(self)
            end
            
            -- Show cast bars in test mode (sArena-style)
            if AC.CastBars and AC.CastBars.SetupCastBars then
                AC.CastBars:SetupCastBars()
                AC.CastBars:ShowTestCastBars()
            end
            
            -- Show test mode target border preview on Arena 3
            AC:ShowTestModeBorder()
        end
    end)
    
    if AC and AC.Debug then 
        AC.Debug:Print("[FrameLayout] ===== ENABLE TEST MODE END =====")
    end
end

-- Show test DR icons in test mode (based on old FrameLayout.lua system)
function MFM:ShowTestDRIcons()
    -- DEBUG: ShowTestDRIcons called
    -- print("|cffFFAA00[TEST DR]|r ShowTestDRIcons called, isTestMode: " .. tostring(isTestMode))
    
    if not isTestMode then 
        -- DEBUG: Not in test mode
        -- print("|cffFF0000[TEST DR]|r Not in test mode, exiting")
        return 
    end
    
    -- CRITICAL: Use Midnight DR module if in Midnight
    if AC.Midnight and AC.Midnight.isMidnight and AC.DRMidnight then
        AC.DRMidnight:ShowTestIcons()
        return
    end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.diminishingReturns
    if not db then 
        -- DEBUG: No DR database found
        -- print("|cffFF0000[TEST DR]|r No DR database found")
        return 
    end
    
    -- CRITICAL: Check if DR is enabled (nil or true = enabled, false = disabled)
    local enabled = (db.enabled ~= false)
    -- DEBUG: DR enabled check
    -- print("|cffFFAA00[TEST DR]|r DR enabled: " .. tostring(enabled))
    
    if not enabled then
        -- Hide all DR icons when disabled
        -- DEBUG: DR disabled
        -- print("|cffFFAA00[TEST DR]|r DR disabled, hiding icons")
        self:HideTestDRIcons()
        return
    end
    
    -- Get active DR settings (respects Detailed DR Settings window)
    local activeDB = (AC.GetActiveDRSettingsDB and AC:GetActiveDRSettingsDB()) or db
    activeDB.categories = activeDB.categories or {}
    
    -- Show test DR icons on each frame
    -- DEBUG: Looping through frames
    -- print("|cffFFAA00[TEST DR]|r Looping through " .. MAX_ARENA_ENEMIES .. " frames")
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = arenaFrames[i]
        -- DEBUG: Frame check
        -- print("|cffFFAA00[TEST DR]|r Frame " .. i .. ": " .. tostring(frame ~= nil) .. ", drIcons: " .. tostring(frame and frame.drIcons ~= nil))
        
        if frame and frame.drIcons then
            -- Show 7 core PvP DR categories with proper spell icons
            local testCategories = {
                {category = "stun", defaultSpellID = 408},
                {category = "silence", defaultSpellID = 15487},
                {category = "root", defaultSpellID = 339},
                {category = "incapacitate", defaultSpellID = 118},
                {category = "disorient", defaultSpellID = 5782},
                {category = "disarm", defaultSpellID = 207777}, -- Dismantle (Rogue)
                {category = "knockback", defaultSpellID = 51490}
            }
            
            for j, data in ipairs(testCategories) do
                local drFrame = frame.drIcons[data.category]
                -- DEBUG: Category check
                -- print("|cffFFAA00[TEST DR]|r   Category: " .. data.category .. ", drFrame exists: " .. tostring(drFrame ~= nil))
                
                if drFrame then
                    -- CRITICAL FIX: Check if this category is enabled in Detailed DR Settings
                    local categoryEnabled = (activeDB.categories[data.category] ~= false)
                    -- DEBUG: Category enabled check
                    -- print("|cffFFAA00[TEST DR]|r   Category " .. data.category .. " enabled: " .. tostring(categoryEnabled))
                    
                    if categoryEnabled then
                        -- CRITICAL FIX: Use ResolveDRIconSpellID for dynamic/custom icon logic
                        local spellIDToShow = data.defaultSpellID
                        if AC.ResolveDRIconSpellID then
                            -- Pass nil for unitGUID in test mode, use default spell as fallback
                            spellIDToShow = AC:ResolveDRIconSpellID(data.category, nil, data.defaultSpellID)
                        end
                        
                        -- RETAIL-ACCURATE: Set different DR stages per frame (1-3 only, no stage 4)
                        -- Stage 1 = 100%, Stage 2 = 50%, Stage 3 = 25%, Stage 4 = immune (hidden)
                        local stage = ((i - 1) % 3) + 1 -- Cycles through 1, 2, 3
                        if drFrame.UpdateStage then
                            drFrame:UpdateStage(stage)
                        else
                            drFrame.severity = stage
                            if drFrame.stageText then
                                drFrame.stageText:SetText(tostring(stage))
                            end
                        end
                        
                        -- Set spell icon texture using resolved spell ID (same method as dropdown)
                        if drFrame.icon then
                            local spellInfo = C_Spell.GetSpellInfo(spellIDToShow)
                            if spellInfo and spellInfo.iconID then
                                drFrame.icon:SetTexture(spellInfo.iconID)
                            else
                                -- Fallback: Try default spell for this category
                                local fallbackInfo = C_Spell.GetSpellInfo(data.defaultSpellID)
                                if fallbackInfo and fallbackInfo.iconID then
                                    drFrame.icon:SetTexture(fallbackInfo.iconID)
                                end
                            end
                        end
                        
                        drFrame:Show()
                        -- DEBUG: Showing DR icon
                        -- print("|cff00FF00[TEST DR]|r   Showing " .. data.category .. " icon at stage " .. stage)
                        
                        -- Set test cooldown with auto-refresh
                        if drFrame.cooldown then
                            local cooldownTime = 18.5 - (j * 2)
                            drFrame.cooldown:SetCooldown(GetTime(), cooldownTime)
                            drFrame.testCooldownDuration = cooldownTime
                            drFrame.testCooldownCategory = data.category
                        end
                    else
                        -- Category disabled - hide this DR icon
                        drFrame:Hide()
                    end
                end
            end
            
            -- Position the DR icons
            -- DEBUG: Calling UpdateDRPositions
            -- print("|cffFFAA00[TEST DR]|r Calling AC:UpdateDRPositions for frame " .. i)
            if AC and AC.UpdateDRPositions then
                AC:UpdateDRPositions(frame)
                -- DEBUG: UpdateDRPositions called
                -- print("|cff00FF00[TEST DR]|r AC:UpdateDRPositions called successfully")
            else
                -- DEBUG: UpdateDRPositions not found
                -- print("|cffFF0000[TEST DR]|r AC:UpdateDRPositions function NOT FOUND!")
            end
        end
    end
    
    -- Start auto-refresh timer if not already running
    if not self.drTestRefreshTimer then
        self:StartDRTestRefreshTimer()
    end
end

-- Auto-refresh DR test cooldowns when they expire
function MFM:StartDRTestRefreshTimer()
    -- Cancel existing timer if any
    if self.drTestRefreshTimer then
        self.drTestRefreshTimer:Cancel()
    end
    
    -- Create repeating timer to refresh cooldowns
    -- PHASE 3: Reduced from 1s to 2s (50% reduction, test mode only)
    self.drTestRefreshTimer = C_Timer.NewTicker(2, function()
        if not isTestMode then
            -- Stop timer when test mode ends
            if self.drTestRefreshTimer then
                self.drTestRefreshTimer:Cancel()
                self.drTestRefreshTimer = nil
            end
            return
        end
        
        -- Check each frame's DR icons
        for i = 1, MAX_ARENA_ENEMIES do
            local frame = arenaFrames[i]
            if frame and frame.drIcons then
                for category, drFrame in pairs(frame.drIcons) do
                    if drFrame and drFrame:IsShown() and drFrame.cooldown and drFrame.testCooldownDuration then
                        -- Check if cooldown expired
                        local start, duration = drFrame.cooldown:GetCooldownTimes()
                        local currentTime = GetTime() * 1000
                        
                        if start == 0 or currentTime >= (start + duration) then
                            -- Restart cooldown
                            drFrame.cooldown:SetCooldown(GetTime(), drFrame.testCooldownDuration)
                        end
                        
                        -- CRITICAL: Update timer text with remaining time
                        if drFrame.timerText and start > 0 then
                            local remaining = math.ceil((start + duration - currentTime) / 1000)
                            if remaining > 0 then
                                drFrame.timerText:SetText(tostring(remaining))
                                drFrame.timerText:Show()
                            else
                                drFrame.timerText:SetText("")
                            end
                        end
                    end
                end
            end
        end
    end)
end

function MFM:DisableTestMode()
    if not isTestMode then return end
    
    isTestMode = false
    self.isTestMode = false  -- CRITICAL: Clear MFM property too
    
    -- CRITICAL FIX: Reset frames array to original order when disabling test mode
    -- This ensures frames are in correct order [1, 2, 3] for next test mode enable
    if self.frames and #self.frames > 0 then
        table.sort(self.frames, function(a, b)
            return (a.id or 0) < (b.id or 0)
        end)
    end
    
    -- Stop frame monitoring
    if frameMonitorTimer then
        frameMonitorTimer:Cancel()
        frameMonitorTimer = nil
    end
    
    -- Stop DR test refresh timer
    if self.drTestRefreshTimer then
        self.drTestRefreshTimer:Cancel()
        self.drTestRefreshTimer = nil
    end
    
    -- CRITICAL: Detect if we're in prep room
    local _, instanceType = IsInInstance()
    local inPrepRoom = false
    if instanceType == "arena" then
        local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs()
        if numOpponents and numOpponents > 0 then
            -- Check if any arena units actually exist
            local anyUnitExists = false
            for i = 1, 3 do
                if UnitExists("arena" .. i) then
                    anyUnitExists = true
                    break
                end
            end
            -- Only in prep room if specs exist but NO units exist
            inPrepRoom = not anyUnitExists
        end
    end
    
    -- MEMORY LEAK FIX: Cancel trinket and racial tickers
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = arenaFrames[i]
        if frame then
            -- Cancel trinket ticker
            if frame.trinketIndicator and frame.trinketIndicator.ticker then
                frame.trinketIndicator.ticker:Cancel()
                frame.trinketIndicator.ticker = nil
            end
            -- Cancel racial ticker
            if frame.racialIndicator and frame.racialIndicator.ticker then
                frame.racialIndicator.ticker:Cancel()
                frame.racialIndicator.ticker = nil
            end
            
            -- CRITICAL FIX: Clean up any duplicate child frames
            if frame.trinketIndicator then
                local children = {frame.trinketIndicator:GetChildren()}
                for j = 2, #children do
                    if children[j] and children[j].Hide then
                        children[j]:Hide()
                    end
                end
            end
            if frame.racialIndicator then
                local children = {frame.racialIndicator:GetChildren()}
                for j = 2, #children do
                    if children[j] and children[j].Hide then
                        children[j]:Hide()
                    end
                end
            end
            
            -- CRITICAL PREP ROOM FIX: Clear test mode trinket/racial/spec icons
            -- This prevents test mode icons from bleeding into prep room
            if inPrepRoom then
                if frame.trinketIndicator then
                    frame.trinketIndicator:Hide()
                    -- CRITICAL FIX: Explicitly hide orange border texture to prevent stale test mode overlay
                    if frame.trinketIndicator.border then
                        frame.trinketIndicator.border:Hide()
                    end
                    if frame.trinketIndicator.cooldown then
                        frame.trinketIndicator.cooldown:Clear()
                    end
                    if frame.trinketIndicator.text then
                        frame.trinketIndicator.text:SetText("")
                    end
                end
                if frame.racialIndicator then
                    frame.racialIndicator:Hide()
                    -- CRITICAL FIX: Explicitly hide orange border texture to prevent stale test mode overlay
                    if frame.racialIndicator.border then
                        frame.racialIndicator.border:Hide()
                    end
                    if frame.racialIndicator.cooldown then
                        frame.racialIndicator.cooldown:Clear()
                    end
                    if frame.racialIndicator.text then
                        frame.racialIndicator.text:SetText("")
                    end
                end
                -- CRITICAL FIX: Clear spec icon test data
                if frame.specIcon then
                    frame.specIcon:Hide()
                    if frame.specIcon.icon then
                        frame.specIcon.icon:SetTexture(nil)
                    end
                end
            end
        end
    end
    
    -- CRITICAL: Set the global test mode flag
    if _G.ArenaCore then
        _G.ArenaCore.testModeEnabled = false
    end
    
    -- CRITICAL: Clear TriBadges test mode auras
    -- This prevents test mode auras from persisting into live arena
    if AC.TriBadges and AC.TriBadges.RefreshAll then
        AC.TriBadges:RefreshAll()
    end
    
    -- Hide test DR icons
    self:HideTestDRIcons()
    
    -- Hide cast bars (sArena-style module)
    if AC.CastBars and AC.CastBars.HideTestCastBars then
        AC.CastBars:HideTestCastBars()
    end
    
    -- CRITICAL PREP ROOM FIX: Clear test mode debuffs
    -- This prevents test mode debuffs from bleeding into prep room and live arena
    if AC.MasterFrameManager and AC.MasterFrameManager.Debuffs then
        local debuffsModule = AC.MasterFrameManager.Debuffs
        for i = 1, MAX_ARENA_ENEMIES do
            local frame = arenaFrames[i]
            if frame and frame.debuffContainer then
                -- Clear all debuff frames
                if frame.debuffContainer.debuffs then
                    for j = 1, #frame.debuffContainer.debuffs do
                        local debuffFrame = frame.debuffContainer.debuffs[j]
                        if debuffFrame then
                            debuffFrame:Hide()
                            debuffFrame:SetAlpha(0)
                            if debuffFrame.cooldown then
                                debuffFrame.cooldown:Clear()
                            end
                            if debuffFrame.timer then
                                debuffFrame.timer:SetText("")
                            end
                            if debuffFrame.timerUpdate then
                                debuffFrame.timerUpdate:Cancel()
                                debuffFrame.timerUpdate = nil
                            end
                        end
                    end
                end
                -- Reset test mode flag and hide container
                frame.debuffContainer.testDebuffsActive = false
                if inPrepRoom then
                    frame.debuffContainer:Hide()
                end
            end
        end
    end
    
    -- Hide drag info box
    if self.dragInfoBox then
        self.dragInfoBox:Hide()
    end
    
    -- Hide frames unless we're in arena
    if not self.isInArena then
        self:HideAllFrames()
    elseif inPrepRoom then
        -- CRITICAL PREP ROOM FIX: If in prep room, refresh to show real prep room data
        -- This ensures test mode data is replaced with actual enemy specs
        print("|cffFFAA00ArenaCore:|r Test mode disabled in prep room - refreshing with real data")
        C_Timer.After(0.1, function()
            if self.HandlePrepRoom then
                self:HandlePrepRoom()
            end
        end)
    end
    
    -- CRITICAL: Hide absorb lines when test mode is disabled
    if AC and AC.Absorbs and AC.Absorbs.HideLines then
        AC.Absorbs:HideLines()
        -- DEBUG DISABLED FOR PRODUCTION
        -- print("|cffFF0000ArenaCore:|r Absorb lines hidden - test mode disabled!")
    end
    
    -- DEBUG: Test Mode Disabled
    -- print("|cffFFAA00ArenaCore Master:|r Test Mode Disabled")
end

-- Hide test DR icons when exiting test mode
function MFM:HideTestDRIcons()
    -- CRITICAL FIX: Use DR module's HideTestIcons() to properly cancel the ticker
    local drModule = GetDRModule()
    if drModule and drModule.HideTestIcons then
        drModule:HideTestIcons(self)
    else
        -- Fallback: Manually hide icons if module not available
        for i = 1, MAX_ARENA_ENEMIES do
            local frame = arenaFrames[i]
            if frame and frame.drIcons then
                for category, drFrame in pairs(frame.drIcons) do
                    if drFrame then
                        drFrame:Hide()
                        if drFrame.cooldown then
                            drFrame.cooldown:Clear()
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- NOTE: OmniCC exclusion now handled globally in Init.lua via metatable hook
-- This section removed - no longer needed
-- ============================================================================

-- ============================================================================
-- TRINKET AND RACIAL INDICATOR CREATION
-- ============================================================================

function MFM:FramesExist()
    -- Check if arena frames exist and are valid
    return self.frames and self.frames[1] and self.frames[2] and self.frames[3]
end

-- CRITICAL FIX: Add GetFrames() function for module compatibility
function MFM:GetFrames()
    return self.frames or {}
end

function MFM:ApplyTestData()
    if not self:FramesExist() then return end
    
    -- Apply realistic test data to all frames
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = self.frames[i]
        if frame then
            -- CRITICAL FIX: Apply test data by frame ID, not array index
            -- This ensures DK data goes to frame 1, Mage to frame 2, Hunter to frame 3
            local dataIndex = frame.id or i
            self:ApplyTestDataToFrame(frame, dataIndex)
        end
    end
    
    -- Force refresh all layout systems with test data
    self:RefreshAllTestLayouts()
    
    -- DEBUG: Test data applied
    -- print("|cffAAFFAA[SUCCESS]|r Test data applied to all frames")
end

function MFM:ApplyTestDataToFrame(frame, index)
    if not frame then return end
    
    -- CRITICAL TEST MODE FIX: Clear stale unit values from previous arena matches
    -- This prevents FrameSort from using old unit tokens to incorrectly reorder test frames
    frame.unit = nil
    
    -- Local test configuration
    local config = {
        playerNames = {
            [1] = "Survivable",
            [2] = "Patymorph", 
            [3] = "Easymodex"
        },
        serverNames = {
            [1] = "Stormrage",
            [2] = "Sargeras",
            [3] = "Moonguard"
        },
        testClasses = {"DEATHKNIGHT", "MAGE", "HUNTER"},
        testSpecs = {
            [1] = 250, -- Death Knight Unholy
            [2] = 62,  -- Mage Arcane  
            [3] = 253  -- Hunter Beast Mastery
        }
    }
    
    local testClass = config.testClasses[index] or "MAGE"
    
    -- Store test class on frame for color updates
    frame.testClass = testClass
    
    if frame.playerName then
        -- ARCHITECTURAL FIX: Use unified text control system
        AC:SetArenaFrameText(frame, index, "test_mode")
        
        -- Show/hide based on Show Names OR Arena Labels setting
        -- CRITICAL FIX: Ensure proper database access to prevent nil 'general' error
        local db = AC.DB and AC.DB.profile
        local general = db and db.arenaFrames and db.arenaFrames.general or {}
        local showArenaLabels = general.showArenaLabels == true
        
        if general.showNames ~= false or showArenaLabels then
            frame.playerName:SetAlpha(1.0)
            frame.playerName:Show()
        else
            frame.playerName:Hide()
        end
    end
    -- Set health and mana to realistic values
    -- NEW FEATURE: Realistic health values for combat preview (unique to ArenaCore!)
    -- Arena 1: 100% (full health), Arena 2: 73% (damaged), Arena 3: 43% (low health)
    local healthValues = {100, 73, 43}
    local healthValue = healthValues[index] or 100
    
    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, 100)
        frame.healthBar:SetValue(healthValue)
        
        -- Apply class colors if enabled
        if AC and AC:GetClassColorsEnabled() and RAID_CLASS_COLORS[testClass] then
            local classColor = RAID_CLASS_COLORS[testClass]
            frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
            
            -- CRITICAL FIX: Apply class-based border color (matches health bar)
            if frame.border then
                frame.border:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
            end
        else
            frame.healthBar:SetStatusBarColor(0, 1, 0, 1) -- Default green
            
            -- Default border color when class colors disabled
            if frame.border then
                frame.border:SetVertexColor(1, 1, 1, 1) -- White
            end
        end
        
        -- Respect Status Text and Use Percentage settings in test mode
        local db = AC.DB and AC.DB.profile
        local general = db and db.arenaFrames and db.arenaFrames.general or {}
        local statusTextEnabled = general.statusText ~= false
        local usePercentage = general.usePercentage ~= false
        
        if frame.healthBar.statusText then
            if statusTextEnabled then
                if usePercentage then
                    frame.healthBar.statusText:SetText(healthValue .. "%")
                else
                    frame.healthBar.statusText:SetText(tostring(healthValue))
                end
                frame.healthBar.statusText:Show()
            else
                frame.healthBar.statusText:SetText("")
                frame.healthBar.statusText:Hide()
            end
            -- DEBUG: Health text set
            -- print("|cff00FF00[TEST MODE HEALTH]|r Arena " .. index .. " health text set to: " .. healthValue .. "%")
        else
            -- DEBUG: Health text missing
            -- print("|cffFF0000[TEST MODE ERROR]|r Arena " .. index .. " healthBar.statusText does NOT exist!")
        end
    end
    
    -- Get test spec for this frame
    local testSpecID = config.testSpecs and config.testSpecs[index]
    
    -- NEW FEATURE: Realistic resource values for combat preview (unique to ArenaCore!)
    -- Arena 1: 100% (full), Arena 2: 82% (mana), Arena 3: 24% (focus)
    local resourceValues = {100, 82, 24}
    local resourceValue = resourceValues[index] or 100
    
    if frame.manaBar then
        frame.manaBar:SetMinMaxValues(0, 100)
        frame.manaBar:SetValue(resourceValue)
        
        -- REVOLUTIONARY: Set SPEC-appropriate resource color (no other addon does this!)
        local resourceColor = self:GetSpecResourceColor(testClass, testSpecID)
        frame.manaBar:SetStatusBarColor(resourceColor[1], resourceColor[2], resourceColor[3], resourceColor[4] or 1)
        
        -- Respect Status Text and Use Percentage settings in test mode
        local db = AC.DB and AC.DB.profile
        local general = db and db.arenaFrames and db.arenaFrames.general or {}
        local statusTextEnabled = general.statusText ~= false
        local usePercentage = general.usePercentage ~= false
        
        if frame.manaBar.statusText then
            if statusTextEnabled then
                if usePercentage then
                    frame.manaBar.statusText:SetText(resourceValue .. "%")
                else
                    frame.manaBar.statusText:SetText(tostring(resourceValue))
                end
                frame.manaBar.statusText:Show()
            else
                frame.manaBar.statusText:SetText("")
                frame.manaBar.statusText:Hide()
            end
            -- DEBUG: Resource text set
            -- print("|cff00FF00[TEST MODE RESOURCE]|r Arena " .. index .. " resource text set to: " .. resourceValue .. "%")
        else
            -- DEBUG: Resource text missing
            -- print("|cffFF0000[TEST MODE ERROR]|r Arena " .. index .. " manaBar.statusText does NOT exist!")
        end
    end
    
    -- Set class icon
    if frame.classIcon and frame.classIcon.UpdateClassIcon then
        -- FIXED: Check if class icons are enabled in test mode
        local db = AC.DB and AC.DB.profile
        local classEnabled = db and db.classIcons and db.classIcons.enabled
        if classEnabled ~= false then
            frame.classIcon.UpdateClassIcon(testClass)
            frame.classIcon:Show()
        else
            frame.classIcon:Hide()
        end
    end
    
    -- Set spec icon
    if frame.specIcon and frame.specIcon.icon then
        local _, _, _, specIcon = GetSpecializationInfoByID(testSpecID)
        if specIcon and frame.specIcon.icon then
            -- FIXED: Check if spec icons are enabled in test mode
            local db = AC.DB and AC.DB.profile
            local specEnabled = db and db.specIcons and db.specIcons.enabled
            if specEnabled ~= false then
                frame.specIcon.icon:SetTexture(specIcon)
                frame.specIcon:Show()
            else
                frame.specIcon:Hide()
            end
        end
    end
    
    -- CRITICAL FIX: Set frame.unit BEFORE calling RefreshFrame so racial icons work
    frame.unit = "arena" .. index
    
    -- CRITICAL FIX: Clean up any duplicate indicators before refreshing
    -- This prevents multiple borders from appearing
    if frame.trinketIndicator then
        -- Hide any child frames that might be duplicates
        local children = {frame.trinketIndicator:GetChildren()}
        for i = 2, #children do  -- Keep first child, hide rest
            if children[i] and children[i].Hide then
                children[i]:Hide()
            end
        end
    end
    if frame.racialIndicator then
        -- Hide any child frames that might be duplicates
        local children = {frame.racialIndicator:GetChildren()}
        for i = 2, #children do  -- Keep first child, hide rest
            if children[i] and children[i].Hide then
                children[i]:Hide()
            end
        end
    end
    
    -- Show trinket and racial icons with test data
    if AC.TrinketsRacials and AC.TrinketsRacials.RefreshFrame then
        AC.TrinketsRacials:RefreshFrame(frame, frame.unit)
    end
    
    -- REVERTED: Back to original individual timer system (Arena 3 only)
    -- The centralized approach caused issues with borders and settings
    if index == 3 then
        -- Trinket looping cooldown (original working code)
        if frame.trinketIndicator and frame.trinketIndicator.cooldown then
            local function UpdateTrinketTimer()
                if not isTestMode or not frame.trinketIndicator then return end
                
                local start, duration = frame.trinketIndicator.cooldown:GetCooldownTimes()
                if start > 0 and duration > 0 and frame.trinketIndicator.txt then
                    local remaining = (start + duration - GetTime() * 1000) / 1000
                    if remaining > 0 then
                        local minutes = math.floor(remaining / 60)
                        local seconds = math.floor(remaining % 60)
                        local text = string.format("%d:%02d", minutes, seconds)
                        frame.trinketIndicator.txt:SetText(text)
                        frame.trinketIndicator.txt:Show()
                    else
                        frame.trinketIndicator.txt:SetText("")
                    end
                end
            end
            
            local function StartTrinketLoop()
                if not isTestMode then return end
                frame.trinketIndicator.cooldown:SetCooldown(GetTime(), 120)
                
                -- Update timer text every 0.5 seconds
                local ticker = C_Timer.NewTicker(0.5, UpdateTrinketTimer)
                frame.trinketIndicator.ticker = ticker
                
                -- Restart loop after 120 seconds
                C_Timer.After(120, function()
                    if frame.trinketIndicator.ticker then
                        frame.trinketIndicator.ticker:Cancel()
                    end
                    StartTrinketLoop()
                end)
            end
            StartTrinketLoop()
        end
        
        -- Racial looping cooldown (original working code)
        if frame.racialIndicator and frame.racialIndicator.cooldown then
            local function UpdateRacialTimer()
                if not isTestMode or not frame.racialIndicator then return end
                
                local start, duration = frame.racialIndicator.cooldown:GetCooldownTimes()
                if start > 0 and duration > 0 and frame.racialIndicator.txt then
                    local remaining = (start + duration - GetTime() * 1000) / 1000
                    if remaining > 0 then
                        local text = string.format("%.0f", remaining)
                        frame.racialIndicator.txt:SetText(text)
                        frame.racialIndicator.txt:Show()
                    else
                        frame.racialIndicator.txt:SetText("")
                    end
                end
            end
            
            local function StartRacialLoop()
                if not isTestMode then return end
                frame.racialIndicator.cooldown:SetCooldown(GetTime(), 30)
                
                -- Update timer text every 0.5 seconds
                local ticker = C_Timer.NewTicker(0.5, UpdateRacialTimer)
                frame.racialIndicator.ticker = ticker
                
                -- Restart loop after 30 seconds
                C_Timer.After(30, function()
                    if frame.racialIndicator.ticker then
                        frame.racialIndicator.ticker:Cancel()
                    end
                    StartRacialLoop()
                end)
            end
            StartRacialLoop()
        end
    end

    -- Cast bars handled by modules/CastBars.lua (sArena-style approach)
    
    -- Apply test debuffs if enabled
    if AC.FrameManager and AC.FrameManager.SetupTestDebuffs then
        AC.FrameManager:SetupTestDebuffs(frame, testClass)
    end
    
    -- Apply test absorb bars if enabled
    -- CRITICAL FIX: Don't show absorbs in prep room (check instance type)
    local _, instanceType = IsInInstance()
    if AC.Absorbs and AC.Absorbs.UpdateAbsorbBar and instanceType ~= "arena" then
        -- frame.unit already set above for racial icons
        -- Only show test absorbs outside arena (not in prep room)
        AC.Absorbs:UpdateAbsorbBar(frame)
    end
    
    -- Apply test immunity glow (show on frame 2 for demonstration) - ONLY IN TEST MODE
    -- CRITICAL FIX: Check if absorbs feature is enabled (immunity uses same checkbox)
    local moreGoodiesDB = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies
    local absorbsEnabled = true -- Default to true if setting doesn't exist
    if moreGoodiesDB and moreGoodiesDB.absorbs then
        absorbsEnabled = moreGoodiesDB.absorbs.enabled ~= false
    end
    
    if index == 2 and AC.testModeEnabled and absorbsEnabled then
        if AC.ImmunityTracker then
            AC.ImmunityTracker:CreateImmunityGlow(frame)
            -- Show magic immunity glow on frame 2 in test mode
            if frame.immunityGlow then
                frame.immunityGlow:SetVertexColor(0, 1, 0, 1) -- BRIGHT GREEN for magic immunity
                frame.immunityGlow:Show()
                if frame.immunityGlowAnim and not frame.immunityGlowAnim:IsPlaying() then
                    frame.immunityGlowAnim:Play()
                end
            end
        end
    end
    
    -- Also show white immunity glow on frame 3 for demonstration - ONLY IN TEST MODE
    if index == 3 and AC.testModeEnabled and absorbsEnabled then
        if AC.ImmunityTracker then
            AC.ImmunityTracker:CreateImmunityGlow(frame)
            -- Show total immunity glow on frame 3 in test mode
            if frame.immunityGlow then
                frame.immunityGlow:SetVertexColor(1, 1, 1, 1) -- PURE WHITE for total immunity
                frame.immunityGlow:Show()
                if frame.immunityGlowAnim and not frame.immunityGlowAnim:IsPlaying() then
                    frame.immunityGlowAnim:Play()
                end
            end
        end
    end
end

-- ============================================================================
-- TEST DATA HELPER FUNCTIONS
-- ============================================================================

-- REVOLUTIONARY: Spec-based resource colors (no other addon does this!)
-- Returns resource color based on SPEC, not just class
function MFM:GetSpecResourceColor(className, specID)
    -- Spec-based resource colors for specs with different resources than base class
    local specResourceColors = {
        -- DRUID: Different resources per spec
        [102] = {0.30, 0.52, 0.90, 1}, -- Balance: Astral Power (Royal Blue #4D85E6)
        [103] = {1.00, 1.00, 0.00, 1}, -- Feral: Energy (Yellow #FFFF00)
        [104] = {1.00, 0.00, 0.00, 1}, -- Guardian: Rage (Red #FF0000)
        [105] = {0.00, 0.00, 1.00, 1}, -- Restoration: Mana (Blue #0000FF)
        
        -- MONK: Different resources per spec
        [268] = {1.00, 1.00, 0.00, 1}, -- Brewmaster: Energy (Yellow #FFFF00)
        [270] = {0.00, 0.00, 1.00, 1}, -- Mistweaver: Mana (Blue #0000FF) - FIXED: Was cyan, now proper mana blue
        [269] = {1.00, 1.00, 0.00, 1}, -- Windwalker: Energy (Yellow #FFFF00)
        
        -- PRIEST: Shadow uses Insanity instead of Mana
        [256] = {0.00, 0.00, 1.00, 1}, -- Discipline: Mana (Blue #0000FF)
        [257] = {0.00, 0.00, 1.00, 1}, -- Holy: Mana (Blue #0000FF)
        [258] = {0.40, 0.00, 0.80, 1}, -- Shadow: Insanity (Purple #6600CC)
        
        -- SHAMAN: Elemental uses Maelstrom, others use Mana
        [262] = {0.00, 0.50, 1.00, 1}, -- Elemental: Maelstrom (Azure #0080FF)
        [263] = {0.00, 0.00, 1.00, 1}, -- Enhancement: Mana (Blue #0000FF)
        [264] = {0.00, 0.00, 1.00, 1}, -- Restoration: Mana (Blue #0000FF)
    }
    
    -- If spec has custom color, use it
    if specID and specResourceColors[specID] then
        return specResourceColors[specID]
    end
    
    -- Otherwise use class default resource color
    local classResourceColors = {
        ["DEATHKNIGHT"] = {0.00, 0.82, 1.00, 1}, -- Runic Power (Cyan #00D1FF)
        ["DEMONHUNTER"] = {0.788, 0.259, 0.992, 1}, -- Fury (Heliotrope #C942FD)
        ["DRUID"] = {0.00, 0.00, 1.00, 1},       -- Mana (Blue #0000FF) - default, overridden by spec
        ["EVOKER"] = {0.00, 0.00, 1.00, 1},      -- Mana (Blue #0000FF)
        ["HUNTER"] = {1.00, 0.50, 0.25, 1},      -- Focus (Light Orange #FF8040)
        ["MAGE"] = {0.00, 0.00, 1.00, 1},        -- Mana (Blue #0000FF)
        ["MONK"] = {1.00, 1.00, 0.00, 1},        -- Energy (Yellow #FFFF00) - default, overridden by spec
        ["PALADIN"] = {0.00, 0.00, 1.00, 1},     -- Mana (Blue #0000FF)
        ["PRIEST"] = {0.00, 0.00, 1.00, 1},      -- Mana (Blue #0000FF) - default, overridden by spec
        ["ROGUE"] = {1.00, 1.00, 0.00, 1},       -- Energy (Yellow #FFFF00)
        ["SHAMAN"] = {0.00, 0.00, 1.00, 1},      -- Mana (Blue #0000FF) - default, overridden by spec
        ["WARLOCK"] = {0.00, 0.00, 1.00, 1},     -- Mana (Blue #0000FF)
        ["WARRIOR"] = {1.00, 0.00, 0.00, 1}      -- Rage (Red #FF0000)
    }
    
    return classResourceColors[className] or {0.00, 0.00, 1.00, 1} -- Default to mana blue
end

-- Legacy function for backward compatibility
function MFM:GetClassResourceColor(className)
    return self:GetSpecResourceColor(className, nil)
end

function MFM:GetTestSpellData(className)
    -- Spell school constants: PHYSICAL=1, HOLY=2, FIRE=4, NATURE=8, FROST=16, SHADOW=32, ARCANE=64
    local spellData = {
        ["DEATHKNIGHT"] = {
            name = "Death Coil",
            icon = "Interface\\Icons\\Spell_Shadow_DeathCoil",
            spellSchool = 32 -- Shadow
        },
        ["MAGE"] = {
            name = "Fireball",
            icon = "Interface\\Icons\\Spell_Fire_FlameBolt",
            spellSchool = 4 -- Fire
        },
        ["HUNTER"] = {
            name = "Aimed Shot",
            icon = "Interface\\Icons\\INV_Spear_07",
            spellSchool = 1 -- Physical (non-interruptible in test mode)
        },
        ["WARRIOR"] = {
            name = "Mortal Strike",
            icon = "Interface\\Icons\\Ability_Warrior_SavageBlow",
            spellSchool = 1 -- Physical
        },
        ["PRIEST"] = {
            name = "Greater Heal",
            icon = "Interface\\Icons\\Spell_Holy_GreaterHeal",
            spellSchool = 2 -- Holy
        },
        ["PALADIN"] = {
            name = "Holy Light",
            icon = "Interface\\Icons\\Spell_Holy_HolyBolt",
            spellSchool = 2 -- Holy
        },
        ["ROGUE"] = {
            name = "Shadowstrike",
            icon = "Interface\\Icons\\Ability_Rogue_Shadowstrike",
            spellSchool = 1 -- Physical
        },
        ["WARLOCK"] = {
            name = "Shadow Bolt",
            icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt",
            spellSchool = 32 -- Shadow
        },
        ["SHAMAN"] = {
            name = "Lightning Bolt",
            icon = "Interface\\Icons\\Spell_Nature_Lightning",
            spellSchool = 8 -- Nature
        },
        ["DRUID"] = {
            name = "Wrath",
            icon = "Interface\\Icons\\Spell_Nature_AbolishMagic",
            spellSchool = 8 -- Nature
        },
        ["MONK"] = {
            name = "Vivify",
            icon = "Interface\\Icons\\Ability_Monk_Vivify",
            spellSchool = 8 -- Nature
        },
        ["DEMONHUNTER"] = {
            name = "Chaos Strike",
            icon = "Interface\\Icons\\Ability_DemonHunter_ChaosStrike",
            spellSchool = 1 -- Physical
        },
        ["EVOKER"] = {
            name = "Living Flame",
            icon = "Interface\\Icons\\Ability_Evoker_LivingFlame",
            spellSchool = 4 -- Fire
        }
    }
    
    return spellData[className] or spellData["MAGE"] -- Default to Mage
end

-- ============================================================================
-- TEST MODE LAYOUT REFRESH SYSTEM
-- ============================================================================

function MFM:RefreshAllTestLayouts()
    if not AC then return end
    
    -- Refresh all layout systems to apply test mode settings
    if AC.RefreshTexturesLayout then
        AC:RefreshTexturesLayout()
    end
    
    if AC.RefreshCastBarsLayout then
        AC:RefreshCastBarsLayout()
    end
    
    -- CRITICAL FIX: Delay DR refresh to allow Edit Mode save to complete (0.15s delay)
    -- This prevents DR icons from jumping when TEST/HIDE is clicked after dragging
    if AC.RefreshDRLayout then
        C_Timer.After(0.15, function()
            if AC.RefreshDRLayout then
                AC:RefreshDRLayout()
            end
        end)
    end
    
    if AC.RefreshTrinketsOtherLayout then
        AC:RefreshTrinketsOtherLayout()
    end
    
    -- CRITICAL FIX: Don't refresh absorbs during initial test setup
    -- The absorbs and immunity glows are already set up by ApplyTestDataToFrame
    -- Refreshing them here causes UpdateAbsorbBar to run again and hide them
    -- Only refresh other More Goodies features (party indicators, etc.)
    -- if AC.RefreshMoreGoodiesLayout then
    --     AC:RefreshMoreGoodiesLayout()
    -- end
    
    -- CRITICAL FIX: Refresh TriBadges (Class Packs) in test mode
    if AC.TriBadges and AC.TriBadges.RefreshAll then
        AC.TriBadges:RefreshAll()
        -- DEBUG: TriBadges refreshed
        -- print("|cff00FF00[TRIBADGES]|r Refreshed for test mode")
    end
    
    -- Force update frame positions with current settings
    if AC.FrameManager and AC.FrameManager.ApplyAllSettings then
        AC.FrameManager:ApplyAllSettings()
    end
end

-- ============================================================================
-- TEST MODE PROTECTION SYSTEM
-- ============================================================================

function AC:ProtectTestModeFrames()
    if not self.testModeEnabled then return end
    
    local frames = GetArenaFrames()
    if not frames then return end
    
    -- Protect frames from being hidden or having alpha reduced
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            -- Force full visibility
            frame:SetAlpha(1.0)
            -- COMBAT PROTECTED: Only show frame outside combat
            if not InCombatLockdown() then
                frame:Show()
            end
            
            -- Protect critical child elements
            local elements = {
                frame.healthBar,
                frame.manaBar,
                frame.playerName,
                frame.classIcon,
                frame.trinketIndicator,
                frame.racialIndicator,
                frame.castBar
            }
            
            for _, element in pairs(elements) do
                if element then
                    element:SetAlpha(1.0)
                    if element.Show then
                        element:Show()
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- TEST MODE CLEAR DATA PROTECTION
-- ============================================================================

-- REMOVED DUPLICATE: AC:ClearArenaData() already defined at line 993
-- The first definition is the authoritative version with memory leak cleanup

function AC:ClearFrameData(frame)
    if not frame then return end
    
    -- Clear health and mana bars
    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, 100)
        frame.healthBar:SetValue(100)
        -- CRITICAL: Don't reset to green - preserve class colors or apply them if unit exists
        if frame.unit and UnitExists(frame.unit) then
            local _, classFile = UnitClass(frame.unit)
            if classFile and RAID_CLASS_COLORS[classFile] then
                local classColor = RAID_CLASS_COLORS[classFile]
                frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
            else
                frame.healthBar:SetStatusBarColor(0, 1, 0, 1) -- Fallback to green only if no class
            end
        else
            frame.healthBar:SetStatusBarColor(0, 1, 0, 1) -- Fallback to green if no unit
        end
        -- CRITICAL FIX: Respect statusText setting when clearing
        if frame.healthBar.text then
            local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
            local statusTextEnabled = general and general.statusText ~= false
            if statusTextEnabled then
                frame.healthBar.text:SetText("100%")
                frame.healthBar.text:Show()
            else
                frame.healthBar.text:Hide()
            end
        end
    end
    
    if frame.manaBar then
        -- CRITICAL FIX: Clear cached power type to force color refresh on next update
        frame.manaBar.cachedPowerType = nil
        
        frame.manaBar:SetMinMaxValues(0, 100)
        frame.manaBar:SetValue(100)
        -- CRITICAL FIX: Use proper power type color, not hardcoded blue
        if frame.unit and UnitExists(frame.unit) then
            local powerType = UnitPowerType(frame.unit)
            local powerColor = PowerBarColor[powerType]
            if powerColor then
                frame.manaBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b, 1)
            else
                frame.manaBar:SetStatusBarColor(0, 0, 1, 1) -- Fallback to mana blue
            end
        else
            frame.manaBar:SetStatusBarColor(0, 0, 1, 1) -- Fallback to mana blue if no unit
        end
        -- CRITICAL FIX: Respect statusText setting when clearing
        if frame.manaBar.text then
            local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
            local statusTextEnabled = general and general.statusText ~= false
            if statusTextEnabled then
                frame.manaBar.text:SetText("100%")
                frame.manaBar.text:Show()
            else
                frame.manaBar.text:Hide()
            end
        end
    end
    
    -- Clear icons and indicators
    if frame.classIcon then
        if frame.classIcon.icon then frame.classIcon.icon:SetTexture(nil) end
        frame.classIcon:Hide()
    end
    
    if frame.specIcon then
        if frame.specIcon.icon then frame.specIcon.icon:SetTexture(nil) end
        frame.specIcon:Hide()
    end
    
    if frame.trinketIndicator then
        if frame.trinketIndicator.cooldown then frame.trinketIndicator.cooldown:Clear() end
        frame.trinketIndicator:Hide()
    end
    
    if frame.racialIndicator then
        if frame.racialIndicator.cooldown then frame.racialIndicator.cooldown:Clear() end
        frame.racialIndicator:Hide()
    end
    
    -- Clear cast bar (but preserve test mode data, don't touch Midnight Blizzard cast bars)
    if frame.castBar and not AC.testModeEnabled and not frame.castBar._isMidnightBlizzardFrame then
        frame.castBar:SetValue(0)
        if frame.castBar.Text then frame.castBar.Text:SetText("") end
        if frame.castBar.spellIcon then frame.castBar.spellIcon:Hide() end
        frame.castBar:Hide()
    end
    
    -- Clear player name
    if frame.playerName then
        local currentText = frame.playerName:GetText() or ""
        if currentText ~= "" then
            frame.playerName:SetText("")
        end
    end
    
    -- Clear debuffs
    if frame.debuffContainer then
        frame.debuffContainer:Hide()
    end
    
    -- Clear DR icons
    if frame.drIcons then
        for _, drIcon in pairs(frame.drIcons) do
            if drIcon then
                drIcon:Hide()
                if drIcon.cooldown then drIcon.cooldown:Clear() end
            end
        end
    end
end

-- ============================================================================
-- TEST MODE INTEGRATION WITH EXISTING SYSTEMS
-- ============================================================================

-- Override UpdateFrameData to protect test mode
local originalUpdateFrameData = UpdateFrameData
UpdateFrameData = function(frame, unit)
    -- CRITICAL: Complete test mode protection
    if AC.testModeEnabled then
        return
    end
    
    -- Call original function for live arena
    if originalUpdateFrameData then
        originalUpdateFrameData(frame, unit)
    end
end

-- Override UpdateAllFrames to protect test mode
local originalUpdateAllFrames = UpdateAllFrames
UpdateAllFrames = function()
    -- CRITICAL: Complete test mode protection - ArenaTracking should not interfere
    if AC.testModeEnabled then 
        if StopTicker then StopTicker() end -- Stop ArenaTracking ticker in test mode
        return
    end
    
    -- CRITICAL FIX: Skip all updates during slider drag to prevent resetting timers/icons
    if AC._sliderDragActive then
        print("|cffFFFF00[UPDATE DEBUG]|r UpdateAllFrames (override) SKIPPED - slider drag active")
        return
    end
    
    -- Call original function for live arena
    if originalUpdateAllFrames then
        originalUpdateAllFrames()
    end
end

-- Override UpdateDebuffs to protect test mode
local originalUpdateDebuffs = UpdateDebuffs
UpdateDebuffs = function(frame, unit)
    -- CRITICAL: Complete test mode protection
    if AC.testModeEnabled then return end
    
    -- Call original function for live arena
    if originalUpdateDebuffs then
        originalUpdateDebuffs(frame, unit)
    end
end

-- ============================================================================
-- CHUNK 11: UTILITY FUNCTIONS
-- Frame visibility management, positioning utilities, and reset functions
-- ============================================================================

-- ============================================================================
-- FRAME VISIBILITY MANAGEMENT
-- ============================================================================
-- OLD MISMATCH CODE REMOVED - Now handled by MismatchHandler module

function MFM:HideAllFrames()
    if not self.frames then
        return
    end
    
    for i = 1, MAX_ARENA_ENEMIES do
        if self.frames[i] then
            -- CRITICAL: Use both SetAlpha AND Hide when leaving arena
            -- SetAlpha(0) alone leaves frames visible in open world
            -- Only use SetAlpha during combat to avoid taint
            if InCombatLockdown() then
                -- In combat: Only use SetAlpha to avoid taint
                self.frames[i]:SetAlpha(0)
            else
                -- Out of combat: Properly hide frames
                self.frames[i]:Hide()
                self.frames[i]:SetAlpha(1) -- Reset alpha for next arena
                
                -- ADDITIONAL SAFEGUARD: Clear frame visibility flags
                self.frames[i].isVisible = false
                self.frames[i].hasEverHadData = false
                
                -- ADDITIONAL SAFEGUARD: Hide all child elements
                if self.frames[i].healthBar then
                    self.frames[i].healthBar:Hide()
                end
                if self.frames[i].powerBar then
                    self.frames[i].powerBar:Hide()
                end
                if self.frames[i].castBar then
                    self.frames[i].castBar:Hide()
                end
                if self.frames[i].classIcon then
                    self.frames[i].classIcon:Hide()
                end
                if self.frames[i].specIcon then
                    self.frames[i].specIcon:Hide()
                end
                if self.frames[i].trinketIndicator then
                    self.frames[i].trinketIndicator:Hide()
                end
                if self.frames[i].racialIndicator then
                    self.frames[i].racialIndicator:Hide()
                end
                
                -- CRITICAL FIX: Hide death icon when hiding frames
                -- Death icon has TOOLTIP strata and can leak into scoreboard
                if self.frames[i].deathIconFrame then
                    self.frames[i].deathIconFrame:Hide()
                end
            end
        end
    end
    
    -- DEBUG DISABLED FOR PRODUCTION
    -- if not InCombatLockdown() then
    --     print("|cffFF6B6B[FRAME CLEANUP]|r All arena frames hidden and reset")
    -- end
end

-- OLD MISMATCH CODE REMOVED - Now handled by MismatchHandler module
function AC:ShowArenaFrames()
    -- Deprecated - MismatchHandler now controls frame visibility
    -- Kept for backward compatibility but does nothing
end

-- OLD MISMATCH CODE REMOVED - Now handled by MismatchHandler module
function AC:HideArenaFrames()
    -- Deprecated - MismatchHandler now controls frame visibility
    -- Kept for backward compatibility
    if MFM and MFM.HideAllFrames then
        MFM:HideAllFrames()
    end
end

-- ============================================================================
-- FRAME POSITIONING UTILITIES
-- ============================================================================

local function FrameSortArenaEnabled()
    local fs = FrameSortApi and FrameSortApi.v3

    return fs and fs.Options:GetEnabled("EnemyArena")
end

-- Refresh arena numbers based on FrameSort integration setting
function AC:RefreshArenaNumbers()
    if not MFM or not MFM.frames then return end
    
    -- Check if FrameSort integration is enabled
    local enableFrameSortIntegration = self.DB and self.DB.profile 
        and self.DB.profile.arenaFrames 
        and self.DB.profile.arenaFrames.general 
        and self.DB.profile.arenaFrames.general.enableFrameSortIntegration
    
    local fs = FrameSortApi and FrameSortApi.v3
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = MFM.frames[i]
        if frame and frame.arenaNumber and frame.unit then
            local displayNumber
            
            -- Use FrameSort visual position if integration enabled
            if enableFrameSortIntegration and fs and FrameSortArenaEnabled() then
                displayNumber = fs.Frame:FrameNumberForUnit(frame.unit)
                
                if displayNumber then
                    AC.Debug:Print(string.format("|cffFF0000[FRAMESORT DEBUG]|r Frame %d (%s) → Display Number: %d", 
                        i, frame.unit, displayNumber))
                end
            end
            
            -- Fallback to unit arena number
            if not displayNumber then
                displayNumber = tonumber(frame.unit:match("arena(%d)"))
            end
            
            -- Update arena number display
            if displayNumber then
                frame.arenaNumber:SetText(displayNumber)
            end
        end
    end
end

-- Refresh "Arena 1/2/3" text labels when FrameSort reorders
function AC:RefreshArenaLabels()
    if not MFM or not MFM.frames then return end
    
    -- Determine current mode
    local _, instanceType = IsInInstance()
    local mode
    if instanceType == "arena" then
        local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs()
        if numOpponents and numOpponents > 0 then
            mode = "prep_room"
        else
            mode = "live_arena"
        end
    else
        mode = "live_arena"  -- Default
    end
    
    -- Update text for each frame
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = MFM.frames[i]
        if frame and frame.unit then
            local arenaIndex = tonumber(frame.unit:match("arena(%d)"))
            if arenaIndex and self.SetArenaFrameText then
                self:SetArenaFrameText(frame, arenaIndex, mode, frame.unit)
            end
        end
    end
end

function AC:FrameSortRequestingSort()
    -- CRITICAL TEST MODE FIX: Ignore FrameSort events in test mode
    -- Test mode frames should never be reordered by FrameSort
    if self.testModeEnabled or (MFM and MFM.isTestMode) then
        return false
    end
    
    -- Check if FrameSort integration is enabled
    local enableFrameSortIntegration = self.DB and self.DB.profile 
        and self.DB.profile.arenaFrames 
        and self.DB.profile.arenaFrames.general 
        and self.DB.profile.arenaFrames.general.enableFrameSortIntegration
    
    if not enableFrameSortIntegration then
        return false -- Integration disabled, ignore FrameSort events
    end
    
    if not FrameSortArenaEnabled() then
        return false
    end

    AC.Debug:Print("|cffFF0000[FRAMESORT DEBUG]|r FrameSort requested sort.")
    
    -- Update frame positions (reordering)
    if MFM and MFM.UpdateFramePositions then
        MFM:UpdateFramePositions()
    end
    
    -- Update arena numbers to match new visual positions
    AC:RefreshArenaNumbers()
    
    -- Update "Arena 1/2/3" text labels to match new visual positions
    AC:RefreshArenaLabels()

    -- Return true to indicate frames were updated
    return true
end

function AC:OnFrameSortPerformedSort()
    -- Legacy function for FrameSort 7.5 and below
    -- Calls the new consolidated function
    AC:FrameSortRequestingSort()
end

function AC:OnFrameSortConfigChanged()
    -- Legacy function for FrameSort 7.5 and below
    -- Calls the new consolidated function
    AC:FrameSortRequestingSort()
end

function MFM:UpdateFramePositions()
    -- CRITICAL: Don't reposition frames while user is dragging them!
    if AC.isDragging then
        return
    end
    
    -- CRITICAL: Don't reposition frames immediately after drag completes
    if AC.justFinishedDragging then
        return
    end
    
    -- CRITICAL TAINT FIX: Don't manipulate frames during combat or protected states
    -- This prevents ADDON_ACTION_BLOCKED errors when importing/switching profiles
    if InCombatLockdown() then
        -- Queue for after combat ends
        C_Timer.After(0.1, function()
            if not InCombatLockdown() and MFM and MFM.UpdateFramePositions then
                MFM:UpdateFramePositions()
            end
        end)
        return
    end
    
    -- LONG-TERM FIX: Read POSITIONS from profile (not themeData!)
    -- Read SPACING and GROWTH from profile
    -- But use frames' CURRENT sizes (don't read sizes from database)
    local horizontal, vertical = 0, 0
    local spacing = 21
    local growthDirection = "Down"
    
    if AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.positioning then
        local positioning = AC.DB.profile.arenaFrames.positioning
        horizontal = positioning.horizontal or 0
        vertical = positioning.vertical or 0
        spacing = positioning.spacing or 21
        growthDirection = positioning.growthDirection or "Down"
    end
    
    -- CRITICAL: Get base frame size from FIRST FRAME'S CURRENT SIZE
    -- This preserves whatever size the frames currently have (from ApplyFrameSizes or user customization)
    local baseFrameHeight = 68  -- Fallback
    local baseFrameWidth = 235  -- Fallback
    
    if self.frames[1] then
        baseFrameHeight = self.frames[1]:GetHeight() or 68
        baseFrameWidth = self.frames[1]:GetWidth() or 235
    end
    
    -- SIMPLE SYSTEM: Use coordinates directly like spacing does (no scale math)
    -- horizontal = pixels from left edge, vertical = pixels from bottom edge
    if AC.ArenaFramesAnchor then
        AC.ArenaFramesAnchor:ClearAllPoints()
        
        -- SetPoint using BOTTOMLEFT so vertical is positive upward from bottom
        AC.ArenaFramesAnchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", horizontal, vertical)
    end

    -- Check if FrameSort integration is enabled
    local enableFrameSortIntegration = AC.DB and AC.DB.profile 
        and AC.DB.profile.arenaFrames 
        and AC.DB.profile.arenaFrames.general 
        and AC.DB.profile.arenaFrames.general.enableFrameSortIntegration

    -- if FrameSort is enabled, retrieve their order
    local fs = FrameSortApi and FrameSortApi.v3

    -- make a copy of our frames array that we can sort
    local frames = {}

    for _, f in ipairs(self.frames) do
        frames[#frames + 1] = f
    end

    -- CRITICAL TEST MODE FIX: Never use FrameSort in test mode
    -- Test mode frames don't have real unit tokens, and stale unit values from previous arena
    -- can cause FrameSort to incorrectly reorder test frames
    local inTestMode = isTestMode or self.isTestMode or (AC and AC.testModeEnabled)
    
    -- CRITICAL TEST MODE FIX: In test mode, ALWAYS sort frames by ID to ensure correct order
    -- This prevents any stale ordering from previous arena sessions
    if inTestMode then
        table.sort(frames, function(a, b)
            return (a.id or 0) < (b.id or 0)
        end)
    end
    
    -- CRITICAL: Only use FrameSort if toggle is enabled AND not in test mode
    -- ALSO: Don't use FrameSort if we're outside arena (prevents stale sorting after leaving arena)
    local _, instanceType = IsInInstance()
    local inArena = (instanceType == "arena")
    
    if fs and FrameSortArenaEnabled() and enableFrameSortIntegration and not inTestMode and inArena then
        -- retrieve a sorted array of unit tokens
        local ordered = fs.Sorting:GetEnemyUnits()
        -- key = unit, value = sorted index
        local unitsToIndex = {}

        AC.Debug:Print(string.format("|cffFF0000[FRAMESORT DEBUG]|r Retrieved %d ordered arena units from FrameSort.", #ordered))

        for i, unit in ipairs(ordered) do
            unitsToIndex[unit] = i
        end

        -- sort our frames array
        table.sort(frames, function(left, right)
            local leftIndex = unitsToIndex[left.unit]
            local rightIndex = unitsToIndex[right.unit]

            if leftIndex and rightIndex then
                return leftIndex < rightIndex
            end

            return leftIndex and true or false
        end)
    else
        -- FrameSort disabled or not available - use default order (no sorting)
        -- frames array already in default order (arena1, arena2, arena3)
    end

    -- Position frames relative to anchor
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            frame:ClearAllPoints()
            
            -- CRITICAL TEST MODE FIX: In test mode, position by frame ID, not array position
            -- This ensures frame 1 is always top, frame 2 middle, frame 3 bottom
            local positionIndex = i
            if inTestMode and frame.id then
                positionIndex = frame.id
            end
            
            -- LONG-TERM FIX: Use base dimensions from CURRENT frame size
            -- This preserves user's custom sizes and prevents unwanted resizing
            local offsetX, offsetY = 0, 0
            if growthDirection == "Down" then
                offsetY = -((positionIndex-1) * (baseFrameHeight + spacing))
            elseif growthDirection == "Up" then
                offsetY = ((positionIndex-1) * (baseFrameHeight + spacing))
            elseif growthDirection == "Right" then
                offsetX = ((positionIndex-1) * (baseFrameWidth + spacing))
            elseif growthDirection == "Left" then
                offsetX = -((positionIndex-1) * (baseFrameWidth + spacing))
            end
            
            if AC.ArenaFramesAnchor then
                frame:SetPoint("TOPLEFT", AC.ArenaFramesAnchor, "TOPLEFT", offsetX, offsetY)
            end
        end
    end
end

function AC:UpdateFramePositions()
    -- Use Master Frame Manager if available
    if MFM and MFM.UpdateFramePositions then
        MFM:UpdateFramePositions()
        return
    end
    
    -- Fallback implementation with DRAG + SLIDER system
    local frames = GetArenaFrames()
    if not frames then return end
    
    local settings = GetFrameSettings()
    if not settings or not settings.positioning then return end
    
    local pos = settings.positioning
    
    -- DRAG + SLIDER SYSTEM: Calculate final position
    -- CRITICAL FIX: Use horizontal/vertical directly (source of truth)
    -- No longer use draggedBase + sliderOffset (Edit Mode is disabled)
    local horizontal = pos.horizontal or 0
    local vertical = pos.vertical or 0
    
    -- Use proper default from Init.lua: 21
    local spacing = pos.spacing
    if not spacing or spacing == 0 then spacing = 21 end
    local growthDirection = pos.growthDirection or "Down"
    
    -- CRITICAL FIX: Get base frame dimensions from database, not from frame:GetHeight()/GetWidth()
    -- This prevents spacing from changing when frame scale changes
    local sizing = settings.sizing or {}
    local baseFrameHeight = sizing.height or 68
    local baseFrameWidth = sizing.width or 235
    
    -- Position anchor using TOPLEFT to UIParent BOTTOMLEFT with scale-adjusted coordinates
    if AC.ArenaFramesAnchor then
        print("|cffFF0000[ANCHOR DEBUG]|r FALLBACK: About to reposition ArenaFramesAnchor to:", horizontal, vertical)
        AC.ArenaFramesAnchor:ClearAllPoints()
        local scale = AC.ArenaFramesAnchor:GetEffectiveScale()
        -- Formula: SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.x / scale, db.y / scale)
        AC.ArenaFramesAnchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", horizontal / scale, vertical / scale)
        print("|cffFF0000[ANCHOR DEBUG]|r FALLBACK: ArenaFramesAnchor repositioned")
    end
    
    -- Position individual frames
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            frame:ClearAllPoints()
            
            -- CRITICAL FIX: Use base dimensions from database, not frame:GetHeight()/GetWidth()
            local offsetX, offsetY = 0, 0
            if growthDirection == "Down" then
                offsetY = -((i-1) * (baseFrameHeight + spacing))
            elseif growthDirection == "Up" then
                offsetY = ((i-1) * (baseFrameHeight + spacing))
            elseif growthDirection == "Right" then
                offsetX = ((i-1) * (baseFrameWidth + spacing))
            elseif growthDirection == "Left" then
                offsetX = -((i-1) * (baseFrameWidth + spacing))
            end
            
            if AC.ArenaFramesAnchor then
                frame:SetPoint("TOPLEFT", AC.ArenaFramesAnchor, "TOPLEFT", offsetX, offsetY)
            else
                frame:SetPoint("CENTER", UIParent, "CENTER", horizontal + offsetX, vertical + offsetY)
            end
        end
    end
end

function MFM:CaptureFramePositions()
    print("|cffFF00FF[CAPTURE DEBUG]|r CaptureFramePositions called!")
    if not self:FramesExist() then
        print("|cffFF00FF[CAPTURE DEBUG]|r Frames don't exist, returning false")
        return false
    end
    print("|cffFF00FF[CAPTURE DEBUG]|r Frames exist, continuing...")
    
    -- Get the position of the first frame as the base position
    local frame1 = self.frames[1]
    if frame1 then
        -- Use GetPoint() to match our positioning system
        local point, relativeTo, relativePoint, xOfs, yOfs = frame1:GetPoint()
        if xOfs and yOfs then
            -- Use the relative coordinates directly
            local horizontal = math.floor(xOfs * 10 + 0.5) / 10
            local vertical = math.floor(yOfs * 10 + 0.5) / 10
            
            -- Save to database with proper structure
            if AC.DB and AC.DB.profile then
                -- Ensure arenaFrames structure exists
                AC.DB.profile.arenaFrames = AC.DB.profile.arenaFrames or {}
                AC.DB.profile.arenaFrames.positioning = AC.DB.profile.arenaFrames.positioning or {}
                
                -- Save the position
                AC.DB.profile.arenaFrames.positioning.horizontal = horizontal
                AC.DB.profile.arenaFrames.positioning.vertical = vertical
                
                -- CRITICAL DEBUG: Track what database values are being changed
                print("|cffFF0000[DB DEBUG]|r Arena frames DB set to:", horizontal, vertical)
                
                -- Check if DR positioning reads from same database values
                local drDB = AC.DB and AC.DB.profile and AC.DB.profile.diminishingReturns
                if drDB and drDB.positioning then
                    -- print("|cffFFAA00[DB DEBUG]|r DR positioning DB currently:", drDB.positioning.horizontal, drDB.positioning.vertical)
                end
                
                -- CRITICAL: Check for database callbacks/listeners
                print("|cffFFFF00[CALLBACK DEBUG]|r Checking for database callbacks...")
                if AC.DB and AC.DB.RegisterCallback then
                    print("|cffFFFF00[CALLBACK DEBUG]|r AC.DB has RegisterCallback!")
                else
                    print("|cffFFFF00[CALLBACK DEBUG]|r No RegisterCallback on AC.DB")
                end
                
                -- Check for any AceDB callbacks (protected call to avoid errors)
                local success, err = pcall(function()
                    if AC.DB and AC.DB.callbacks then
                        print("|cffFFFF00[CALLBACK DEBUG]|r AC.DB has callbacks table!")
                        if AC.DB.callbacks.events then
                            for k, v in pairs(AC.DB.callbacks.events) do
                                print("|cffFFFF00[CALLBACK DEBUG]|r Callback event:", k)
                            end
                        else
                            print("|cffFFFF00[CALLBACK DEBUG]|r No events in callbacks")
                        end
                    else
                        print("|cffFFFF00[CALLBACK DEBUG]|r No callbacks table on AC.DB")
                    end
                end)
                if not success then
                    print("|cffFF0000[CALLBACK DEBUG ERROR]|r", err)
                end
                
                -- CRITICAL: Save to current theme but protect DR from jumping
                print("|cffFF00FF[THEME CHECK]|r AC.ArenaFrameThemes exists:", AC.ArenaFrameThemes ~= nil)
                if AC.ArenaFrameThemes then
                    print("|cffFF00FF[THEME CHECK]|r SaveCurrentThemeSettings exists:", AC.ArenaFrameThemes.SaveCurrentThemeSettings ~= nil)
                end
                
                if AC.ArenaFrameThemes and AC.ArenaFrameThemes.SaveCurrentThemeSettings then
                    print("|cffFF00FF[THEME CHECK]|r ENTERING theme save block!")
                    -- Set temporary protection flag to prevent DR jumping during this theme save
                    AC._skipDRRepositionOnSave = true
                    AC._saveOperationTime = GetTime()
                    
                    -- CRITICAL: Check for phantom/stale references
                    print("|cffFFFF00[PHANTOM DEBUG]|r Checking global arena frame references...")
                    for i = 1, MAX_ARENA_ENEMIES do
                        local globalFrame = _G["ArenaCoreFrame" .. i]
                        if globalFrame then
                            print("|cffFFFF00[PHANTOM DEBUG]|r Global frame", i, "exists, IsShown:", globalFrame:IsShown())
                            if globalFrame.drIcons then
                                print("|cffFFFF00[PHANTOM DEBUG]|r Global frame", i, "HAS drIcons table!")
                                for k, v in pairs(globalFrame.drIcons) do
                                    print("|cffFFFF00[PHANTOM DEBUG]|r Global frame", i, "drIcons.", k, "exists")
                                end
                            end
                            if globalFrame.testDRIcons then
                                print("|cffFFFF00[PHANTOM DEBUG]|r Global frame", i, "HAS testDRIcons table!")
                                for k, v in pairs(globalFrame.testDRIcons) do
                                    print("|cffFFFF00[PHANTOM DEBUG]|r Global frame", i, "testDRIcons.", k, "exists")
                                end
                            end
                        else
                            print("|cffFFFF00[PHANTOM DEBUG]|r Global frame", i, "does NOT exist")
                        end
                    end
                    
                    -- CRITICAL: Check for stale timers/callbacks
                    print("|cffFFFF00[TIMER DEBUG]|r Checking for active DR timers...")
                    if AC.drTestRefreshTimer then
                        print("|cffFFFF00[TIMER DEBUG]|r drTestRefreshTimer exists!")
                    else
                        print("|cffFFFF00[TIMER DEBUG]|r No drTestRefreshTimer")
                    end
                    
                    -- Check for any OnUpdate handlers that might be running
                    print("|cffFFFF00[EVENT DEBUG]|r Checking for event handlers...")
                    for i = 1, MAX_ARENA_ENEMIES do
                        local arenaFrame = _G["ArenaCoreFrame" .. i]
                        if arenaFrame then
                            if arenaFrame:GetScript("OnUpdate") then
                                print("|cffFFFF00[EVENT DEBUG]|r Frame", i, "has OnUpdate script!")
                            end
                            if arenaFrame:GetScript("OnShow") then
                                print("|cffFFFF00[EVENT DEBUG]|r Frame", i, "has OnShow script!")
                            end
                            if arenaFrame:GetScript("OnHide") then
                                print("|cffFFFF00[EVENT DEBUG]|r Frame", i, "has OnHide script!")
                            end
                        end
                    end
                    for i = 1, MAX_ARENA_ENEMIES do
                        local arenaFrame = _G["ArenaCoreFrame" .. i]
                        if arenaFrame and arenaFrame.drContainer then
                            print("|cffFF0000[DR PARENT DEBUG]|r Unparenting DR container from arena frame", i)
                            
                            -- CRITICAL DEBUG: Track DR icon positions BEFORE save
                            if arenaFrame.drIcons then
                                print("|cffFFAA00[DR TRACK DEBUG]|r Checking frame", i, "drIcons table...")
                                for category, icon in pairs(arenaFrame.drIcons) do
                                    if icon and icon.GetPoint then
                                        local point, relativeTo, relativePoint, xOfs, yOfs = icon:GetPoint()
                                        print("|cffFFAA00[DR COORD DEBUG]|r BEFORE SAVE: Frame", i, "DR", category, "at:", xOfs, yOfs)
                                    else
                                        print("|cffFF0000[DR TRACK DEBUG]|r Frame", i, "DR", category, "icon invalid or no GetPoint")
                                    end
                                end
                            else
                                print("|cffFF0000[DR TRACK DEBUG]|r Frame", i, "has no drIcons table")
                            end
                            
                            -- CRITICAL: Check for TEST MODE DR icons!
                            if AC.testModeEnabled and arenaFrame.testDRIcons then
                                print("|cffFF00FF[TEST DR DEBUG]|r Frame", i, "has TEST MODE DR icons!")
                                for category, icon in pairs(arenaFrame.testDRIcons) do
                                    if icon and icon.GetPoint then
                                        local point, relativeTo, relativePoint, xOfs, yOfs = icon:GetPoint()
                                        print("|cffFF00FF[TEST DR COORD]|r BEFORE SAVE: Frame", i, "TEST DR", category, "at:", xOfs, yOfs)
                                    end
                                end
                            else
                                print("|cffFF00FF[TEST DR DEBUG]|r Frame", i, "test mode:", AC.testModeEnabled, "testDRIcons:", arenaFrame.testDRIcons and "yes" or "no")
                            end
                            
                            -- Also check DRHolder and drContainer directly
                            if arenaFrame.DRHolder then
                                local point, relativeTo, relativePoint, xOfs, yOfs = arenaFrame.DRHolder:GetPoint()
                                print("|cffFFAA00[DR HOLDER DEBUG]|r BEFORE SAVE: Frame", i, "DRHolder at:", xOfs, yOfs)
                            end
                            
                            if arenaFrame.drContainer then
                                local point, relativeTo, relativePoint, xOfs, yOfs = arenaFrame.drContainer:GetPoint()
                                print("|cffFFAA00[DR CONTAINER DEBUG]|r BEFORE SAVE: Frame", i, "drContainer at:", xOfs, yOfs)
                            end
                            
                            arenaFrame.drContainer:SetParent(UIParent)
                            arenaFrame.drContainer._originalParent = arenaFrame.DRHolder
                        end
                    end
                    
                    AC.ArenaFrameThemes:SaveCurrentThemeSettings()
                    
                    -- Restore DR container parenting after save completes
                    C_Timer.After(1.0, function()
                        if AC then
                            print("|cffFFFF00[PHANTOM DEBUG]|r AFTER SAVE: Checking for phantom behavior...")
                            
                            -- Check if any DR icons appeared after save
                            for i = 1, MAX_ARENA_ENEMIES do
                                local arenaFrame = _G["ArenaCoreFrame" .. i]
                                if arenaFrame then
                                    if arenaFrame.drIcons then
                                        print("|cffFFFF00[PHANTOM DEBUG]|r AFTER SAVE: Frame", i, "NOW HAS drIcons table!")
                                        for k, v in pairs(arenaFrame.drIcons) do
                                            if v and v.GetPoint then
                                                local point, relativeTo, relativePoint, xOfs, yOfs = v:GetPoint()
                                                print("|cffFFFF00[PHANTOM DEBUG]|r AFTER SAVE: Frame", i, "drIcons.", k, "at:", xOfs, yOfs)
                                            end
                                        end
                                    end
                                    if arenaFrame.testDRIcons then
                                        print("|cffFFFF00[PHANTOM DEBUG]|r AFTER SAVE: Frame", i, "NOW HAS testDRIcons table!")
                                        for k, v in pairs(arenaFrame.testDRIcons) do
                                            if v and v.GetPoint then
                                                local point, relativeTo, relativePoint, xOfs, yOfs = v:GetPoint()
                                                print("|cffFFFF00[PHANTOM DEBUG]|r AFTER SAVE: Frame", i, "testDRIcons.", k, "at:", xOfs, yOfs)
                                            end
                                        end
                                    end
                                end
                            end
                            
                            for i = 1, MAX_ARENA_ENEMIES do
                                local arenaFrame = _G["ArenaCoreFrame" .. i]
                                if arenaFrame and arenaFrame.drContainer and arenaFrame.drContainer._originalParent then
                                    print("|cff00FF00[DR PARENT DEBUG]|r Restoring DR container parent to arena frame", i)
                                    
                                    -- CRITICAL DEBUG: Track DR icon positions AFTER save
                                    if arenaFrame.drIcons then
                                        print("|cffFF6600[DR TRACK DEBUG]|r Checking frame", i, "drIcons table AFTER...")
                                        for category, icon in pairs(arenaFrame.drIcons) do
                                            if icon and icon.GetPoint then
                                                local point, relativeTo, relativePoint, xOfs, yOfs = icon:GetPoint()
                                                print("|cffFF6600[DR COORD DEBUG]|r AFTER SAVE: Frame", i, "DR", category, "at:", xOfs, yOfs)
                                            else
                                                print("|cffFF0000[DR TRACK DEBUG]|r Frame", i, "DR", category, "icon invalid AFTER")
                                            end
                                        end
                                    else
                                        print("|cffFF0000[DR TRACK DEBUG]|r Frame", i, "has no drIcons table AFTER")
                                    end
                                    
                                    -- CRITICAL: Check for TEST MODE DR icons AFTER save!
                                    if AC.testModeEnabled and arenaFrame.testDRIcons then
                                        print("|cffFF00FF[TEST DR DEBUG]|r Frame", i, "has TEST MODE DR icons AFTER!")
                                        for category, icon in pairs(arenaFrame.testDRIcons) do
                                            if icon and icon.GetPoint then
                                                local point, relativeTo, relativePoint, xOfs, yOfs = icon:GetPoint()
                                                print("|cffFF00FF[TEST DR COORD]|r AFTER SAVE: Frame", i, "TEST DR", category, "at:", xOfs, yOfs)
                                            end
                                        end
                                    else
                                        print("|cffFF00FF[TEST DR DEBUG]|r Frame", i, "test mode AFTER:", AC.testModeEnabled, "testDRIcons:", arenaFrame.testDRIcons and "yes" or "no")
                                    end
                                    
                                    -- Also check DRHolder and drContainer directly AFTER
                                    if arenaFrame.DRHolder then
                                        local point, relativeTo, relativePoint, xOfs, yOfs = arenaFrame.DRHolder:GetPoint()
                                        print("|cffFF6600[DR HOLDER DEBUG]|r AFTER SAVE: Frame", i, "DRHolder at:", xOfs, yOfs)
                                    end
                                    
                                    if arenaFrame.drContainer then
                                        local point, relativeTo, relativePoint, xOfs, yOfs = arenaFrame.drContainer:GetPoint()
                                        print("|cffFF6600[DR CONTAINER DEBUG]|r AFTER SAVE: Frame", i, "drContainer at:", xOfs, yOfs)
                                    end
                                    
                                    arenaFrame.drContainer:SetParent(arenaFrame.drContainer._originalParent)
                                    arenaFrame.drContainer._originalParent = nil
                                end
                            end
                            
                            AC._skipDRRepositionOnSave = nil
                            AC._saveOperationTime = nil
                        end
                    end)
                end
                
                -- Force database save
                _G.ArenaCoreDB = AC.DB
                
                print("ArenaCore: Frame positions saved!")
                return true
            end
        end
    end
    
    return false
end

function AC:CaptureFramePositions()
    -- Use Master Frame Manager if available
    if MFM and MFM.CaptureFramePositions then
        return MFM:CaptureFramePositions()
    end
    
    -- Fallback implementation
    local frames = GetArenaFrames()
    if not frames or not frames[1] then return false end
    
    local frame1 = frames[1]
    local point, relativeTo, relativePoint, xOfs, yOfs = frame1:GetPoint()
    if xOfs and yOfs then
        -- Save position to database
        self:EnsureDB()
        self:SetPath(self.DB.profile, "arenaFrames.positioning.horizontal", xOfs)
        self:SetPath(self.DB.profile, "arenaFrames.positioning.vertical", yOfs)
        
        print("ArenaCore: Frame positions captured and saved!")
        return true
    end
    
    return false
end

-- ============================================================================
-- FRAME RESET UTILITIES
-- ============================================================================

function MFM:ResetFrame(frame)
    if not frame then return end
    
    -- CRITICAL FIX: Ensure proper database access to prevent nil 'general' error
    local db = AC.DB and AC.DB.profile
    local general = db and db.arenaFrames and db.arenaFrames.general or {}
    local showArenaLabels = general.showArenaLabels == true
    
    if showArenaLabels then
        local newName = "Arena " .. frame.id
        local currentText = frame.playerName:GetText() or ""
        if currentText ~= newName then
            frame.playerName:SetText(newName)
        end
    else
        local currentText = frame.playerName:GetText() or ""
        if currentText ~= "" then
            frame.playerName:SetText("")
        end
    end
    frame.healthBar:SetValue(100)
    frame.manaBar:SetValue(100)
    frame.healthBar.text:SetText("100%")
    frame.manaBar.text:SetText("100%")
    frame.healthBar:SetStatusBarColor(0, 1, 0)  -- Reset to green
    frame.classIcon:Hide()
    if frame.castBar and not frame.castBar._isMidnightBlizzardFrame then
        frame.castBar:Hide()
    end
    frame:SetAlpha(1)
    
    -- DEATH ICON SYSTEM: Hide death icon when resetting frame
    if frame.deathIconFrame then
        frame.deathIconFrame:Hide()
    end
end

function AC:ResetFrame(frame)
    if not frame then return end
    
    -- Reset basic frame properties
    frame:SetAlpha(1.0)
    
    -- Reset player name
    if frame.playerName then
        local arenaIndex = frame.arenaIndex or frame.id or 1
        -- CRITICAL FIX: Ensure proper database access to prevent nil 'general' error
        local db = AC.DB and AC.DB.profile
        local general = db and db.arenaFrames and db.arenaFrames.general or {}
        local showArenaLabels = general.showArenaLabels == true
        
        if showArenaLabels then
            local newName = "Arena " .. arenaIndex
            local currentText = frame.playerName:GetText() or ""
            if currentText ~= newName then
                frame.playerName:SetText(newName)
            end
        else
            local currentText = frame.playerName:GetText() or ""
            if currentText ~= "" then
                frame.playerName:SetText("")
            end
        end
        -- CRITICAL FIX: Only show if enabled in settings
        local db = AC.DB and AC.DB.profile
        local general = db and db.arenaFrames and db.arenaFrames.general or {}
        if general.showNames ~= false then
            frame.playerName:Show()
        else
            frame.playerName:Hide()
        end
    end
    
    -- DEATH ICON SYSTEM: Hide death icon when resetting frame
    if frame.deathIconFrame then
        frame.deathIconFrame:Hide()
    end
    
    -- Reset health bar (with realistic test mode values)
    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, 100)
        
        -- NEW FEATURE: Use realistic values in test mode
        local arenaIndex = frame.arenaIndex or frame.id or 1
        local healthValues = {100, 73, 43}
        local healthValue = (AC.testModeEnabled and healthValues[arenaIndex]) or 100
        
        frame.healthBar:SetValue(healthValue)
        -- CRITICAL: Don't reset to green - preserve class colors or apply them if unit exists
        if frame.unit and UnitExists(frame.unit) then
            local _, classFile = UnitClass(frame.unit)
            if classFile and RAID_CLASS_COLORS[classFile] then
                local classColor = RAID_CLASS_COLORS[classFile]
                frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
            else
                frame.healthBar:SetStatusBarColor(0, 1, 0, 1) -- Fallback to green only if no class
            end
        else
            frame.healthBar:SetStatusBarColor(0, 1, 0, 1) -- Fallback to green if no unit
        end
        if frame.healthBar.statusText then
            frame.healthBar.statusText:SetText(healthValue .. "%")
            if not InCombatLockdown() then
                frame.healthBar.statusText:Show()
            end
        end
    end
    
    -- Reset mana bar (with realistic test mode values)
    if frame.manaBar then
        -- CRITICAL FIX: Clear cached power type to force color refresh on next update
        frame.manaBar.cachedPowerType = nil
        
        frame.manaBar:SetMinMaxValues(0, 100)
        
        -- NEW FEATURE: Use realistic values in test mode
        local arenaIndex = frame.arenaIndex or frame.id or 1
        local resourceValues = {100, 82, 24}
        local resourceValue = (AC.testModeEnabled and resourceValues[arenaIndex]) or 100
        
        frame.manaBar:SetValue(resourceValue)
        -- CRITICAL FIX: Use proper power type color, not hardcoded blue
        if frame.unit and UnitExists(frame.unit) then
            local powerType = UnitPowerType(frame.unit)
            local powerColor = PowerBarColor[powerType]
            if powerColor then
                frame.manaBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b, 1)
            else
                frame.manaBar:SetStatusBarColor(0, 0, 1, 1) -- Fallback to mana blue
            end
        else
            frame.manaBar:SetStatusBarColor(0, 0, 1, 1) -- Fallback to mana blue if no unit
        end
        if frame.manaBar.statusText then
            frame.manaBar.statusText:SetText(resourceValue .. "%")
            if not InCombatLockdown() then
                frame.manaBar.statusText:Show()
            end
        end
    end
    
    -- Reset icons and indicators
    if frame.classIcon then
        frame.classIcon:Hide()
    end
    
    if frame.specIcon then
        frame.specIcon:Hide()
    end
    
    if frame.trinketIndicator then
        if frame.trinketIndicator.cooldown then
            frame.trinketIndicator.cooldown:Clear()
        end
        frame.trinketIndicator:Hide()
    end
    
    if frame.racialIndicator then
        if frame.racialIndicator.cooldown then
            frame.racialIndicator.cooldown:Clear()
        end
        frame.racialIndicator:Hide()
    end
    
    -- Reset cast bar (don't touch Midnight Blizzard cast bars)
    if frame.castBar and not frame.castBar._isMidnightBlizzardFrame then
        frame.castBar:SetValue(0)
        if frame.castBar.Text then
            frame.castBar.Text:SetText("")
        end
        frame.castBar:Hide()
    end
    
    -- Reset debuffs
    if frame.debuffContainer then
        frame.debuffContainer:Hide()
    end
    
    -- Reset DR icons
    if frame.drIcons then
        for _, drIcon in pairs(frame.drIcons) do
            if drIcon then
                drIcon:Hide()
                if drIcon.cooldown then
                    drIcon.cooldown:Clear()
                end
            end
        end
    end
end

function AC:ResetAllFrames()
    local frames = GetArenaFrames()
    if not frames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        if frames[i] then
            self:ResetFrame(frames[i])
        end
    end
    
    print("ArenaCore: All frames reset to default state")
end

-- ============================================================================
-- BETA PRESET & DEFAULTS SYSTEM
-- ============================================================================
-- Apply your personal beta preset settings to current profile
-- This overwrites ALL settings with your COMPLETE configuration from Init.lua
function AC:ApplyBetaPreset()
    if not self.GetBetaDefaults then
        return
    end
    
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.profile then
        return
    end
    
    -- Deep copy function (local to avoid conflicts)
    local function DeepCopy(tbl)
        if type(tbl) ~= "table" then return tbl end
        local out = {}
        for k, v in pairs(tbl) do out[k] = DeepCopy(v) end
        return out
    end
    
    -- Get COMPLETE beta defaults (includes Blackout, debuffs, everything)
    local betaDefaults = self:GetBetaDefaults()
    if not betaDefaults then
        print("|cffFF0000ArenaCore:|r Failed to get beta defaults!")
        return
    end
    
    -- CRITICAL: Deep copy the defaults FIRST to avoid corrupting the source
    local defaultsCopy = DeepCopy(betaDefaults)
    
    -- Apply ALL defaults to current profile (using the copy, not the original)
    for key, value in pairs(defaultsCopy) do
        _G.ArenaCoreDB.profile[key] = DeepCopy(value)
    end
    
    -- CRITICAL: Force overwrite texture settings (dropdown values don't update otherwise)
    if defaultsCopy.textures then
        _G.ArenaCoreDB.profile.textures = DeepCopy(defaultsCopy.textures)
        -- print("|cffFFAA00[DEBUG]|r Forced texture settings update")
        
        -- DEBUG: Show what textures were applied
        -- local tex = _G.ArenaCoreDB.profile.textures
        -- if tex then
        --     print("|cffFFAA00[DEBUG]|r Health texture: " .. tostring(tex.healthBarTexture))
        --     print("|cffFFAA00[DEBUG]|r Power texture: " .. tostring(tex.powerBarTexture))
        --     print("|cffFFAA00[DEBUG]|r Cast texture: " .. tostring(tex.castBarTexture))
        -- end
    end
    
    -- DEBUG: Show what positioning values were applied
    -- if betaDefaults.arenaFrames and betaDefaults.arenaFrames.positioning then
    --     local pos = betaDefaults.arenaFrames.positioning
    --     print("|cffFFAA00[DEBUG]|r Applied positioning: horizontal=" .. tostring(pos.horizontal) .. ", vertical=" .. tostring(pos.vertical))
    -- end
    
    -- DEBUG: Verify what's actually in the database now
    -- if _G.ArenaCoreDB.profile.arenaFrames and _G.ArenaCoreDB.profile.arenaFrames.positioning then
    --     local dbPos = _G.ArenaCoreDB.profile.arenaFrames.positioning
    --     print("|cffFFAA00[DEBUG]|r Database now has: horizontal=" .. tostring(dbPos.horizontal) .. ", vertical=" .. tostring(dbPos.vertical))
    -- end
    
    -- CRITICAL FIX: Actually apply the settings to move frames immediately
    if self.UpdateFramePositions then
        self:UpdateFramePositions()
        -- print("|cffFFAA00[DEBUG]|r Called UpdateFramePositions()")
    end
    
    -- Also refresh trinkets, racials, class packs, etc.
    if self.RefreshTrinketsOtherLayout then
        self:RefreshTrinketsOtherLayout()
        -- print("|cffFFAA00[DEBUG]|r Called RefreshTrinketsOtherLayout()")
    end
    
    if self.TriBadges and self.TriBadges.RefreshAll then
        self.TriBadges:RefreshAll()
        -- print("|cffFFAA00[DEBUG]|r Called TriBadges:RefreshAll()")
    end
    
    -- CRITICAL: Refresh textures to apply new bar textures
    -- print("|cffFFAA00[DEBUG]|r Test mode enabled: " .. tostring(self.testModeEnabled))
    if self.RefreshTexturesLayout then
        self:RefreshTexturesLayout()
        -- print("|cffFFAA00[DEBUG]|r Called RefreshTexturesLayout()")
    end
    
    -- CRITICAL: Refresh cast bars to apply new cast bar texture and colors
    if self.RefreshCastBarsLayout then
        self:RefreshCastBarsLayout()
        -- print("|cffFFAA00[DEBUG]|r Called RefreshCastBarsLayout()")
    end
    
    -- If not in test mode, warn user to enable it
    if not self.testModeEnabled then
        print("|cffFFCC00[WARNING]|r Textures updated in database but not visible. Type |cffffff00/arena test|r to see changes!")
    end
    
    print("|cff8B45FFArena Core:|r Beta preset applied! Complete configuration restored.")
    print("|cffFFAA00Includes:|r Blackout spells, debuffs, all settings, and features!")
    print("|cffFFAA00Note:|r Frames should move immediately. If not, type |cffffff00/reload|r")
end

-- NEW: Simulate fresh install - EXACT same process as Init.lua for first-time users
function AC:SimulateFreshInstall()
    print("|cffFFAA00[Fresh Install Simulator]|r Resetting to EXACT first-time user experience...")
    
    if not self.GetBetaDefaults then
        print("|cffFF0000[Fresh Install]|r GetBetaDefaults function not found in Init.lua!")
        return
    end
    
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.profile then
        print("|cffFF0000[Fresh Install]|r Database not initialized!")
        return
    end
    
    -- Deep copy function (same as Init.lua uses)
    local function DeepCopyLocal(tbl)
        if type(tbl) ~= "table" then return tbl end
        local out = {}
        for k, v in pairs(tbl) do out[k] = DeepCopyLocal(v) end
        return out
    end
    
    -- Get beta defaults (SAME function Init.lua calls)
    local betaDefaults = self:GetBetaDefaults()
    if not betaDefaults then
        print("|cffFF0000[Fresh Install]|r Failed to get beta defaults!")
        return
    end
    
    -- CRITICAL: Wipe current profile completely (fresh slate)
    _G.ArenaCoreDB.profile = {}
    
    -- Apply ALL beta defaults (EXACT same code as Init.lua lines 2711-2713)
    for key, value in pairs(betaDefaults) do
        _G.ArenaCoreDB.profile[key] = DeepCopyLocal(value)
    end
    
    -- Mark as fresh install
    _G.ArenaCoreDB.__firstInstall = true
    
    -- Apply settings immediately
    if self.UpdateFramePositions then
        self:UpdateFramePositions()
    end
    
    if self.RefreshTrinketsOtherLayout then
        self:RefreshTrinketsOtherLayout()
    end
    
    if self.TriBadges and self.TriBadges.RefreshAll then
        self.TriBadges:RefreshAll()
    end
    
    if self.RefreshTexturesLayout then
        self:RefreshTexturesLayout()
    end
    
    if self.RefreshCastBarsLayout then
        self:RefreshCastBarsLayout()
    end
    
    if self.RefreshDRLayout then
        self:RefreshDRLayout()
    end
    
    -- Success message (SAME as Init.lua)
    print("|cff8B45FFArena Core:|r First-time setup complete! Beta preset applied.")
    print("|cffFFAA00Note:|r All settings, Blackout spells, debuffs, and features configured!")
    print("|cff00FF00[Fresh Install]|r This is EXACTLY what new users see!")
    print("|cffFFAA00Tip:|r Type /reload to ensure everything loads perfectly")
end

-- NEW: Reset ONLY visual positioning/sizing (Arena Core theme defaults)
function AC:ResetVisualsOnly()
    print("|cffFFAA00[Visual Reset]|r Resetting ONLY positioning and sizing to Arena Core defaults...")
    
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.profile then
        print("|cffFF0000[Visual Reset]|r Database not initialized!")
        return
    end
    
    local profile = _G.ArenaCoreDB.profile
    
    -- Reset trinkets positioning and sizing
    if not profile.trinkets then profile.trinkets = {} end
    if not profile.trinkets.positioning then profile.trinkets.positioning = {} end
    profile.trinkets.positioning.horizontal = -25
    profile.trinkets.positioning.vertical = -5
    profile.trinkets.positioning.draggedBaseX = nil
    profile.trinkets.positioning.draggedBaseY = nil
    profile.trinkets.positioning.sliderOffsetX = nil
    profile.trinkets.positioning.sliderOffsetY = nil
    if not profile.trinkets.sizing then profile.trinkets.sizing = {} end
    profile.trinkets.sizing.scale = 142
    
    -- Reset racials positioning and sizing
    if not profile.racials then profile.racials = {} end
    if not profile.racials.positioning then profile.racials.positioning = {} end
    profile.racials.positioning.horizontal = -50
    profile.racials.positioning.vertical = -5
    profile.racials.positioning.draggedBaseX = nil
    profile.racials.positioning.draggedBaseY = nil
    profile.racials.positioning.sliderOffsetX = nil
    profile.racials.positioning.sliderOffsetY = nil
    if not profile.racials.sizing then profile.racials.sizing = {} end
    profile.racials.sizing.scale = 105
    
    -- Reset class icons positioning and sizing
    if not profile.classIcons then profile.classIcons = {} end
    if not profile.classIcons.positioning then profile.classIcons.positioning = {} end
    profile.classIcons.positioning.horizontal = -2
    profile.classIcons.positioning.vertical = 7
    profile.classIcons.positioning.draggedBaseX = nil
    profile.classIcons.positioning.draggedBaseY = nil
    profile.classIcons.positioning.sliderOffsetX = nil
    profile.classIcons.positioning.sliderOffsetY = nil
    if not profile.classIcons.sizing then profile.classIcons.sizing = {} end
    profile.classIcons.sizing.scale = 109
    
    -- Reset spec icons positioning and sizing
    if not profile.specIcons then profile.specIcons = {} end
    if not profile.specIcons.positioning then profile.specIcons.positioning = {} end
    profile.specIcons.positioning.horizontal = -37
    profile.specIcons.positioning.vertical = -37
    profile.specIcons.positioning.draggedBaseX = nil
    profile.specIcons.positioning.draggedBaseY = nil
    profile.specIcons.positioning.sliderOffsetX = nil
    profile.specIcons.positioning.sliderOffsetY = nil
    if not profile.specIcons.sizing then profile.specIcons.sizing = {} end
    profile.specIcons.sizing.scale = 94
    
    -- Reset cast bars positioning and sizing (CRITICAL: Match Init.lua DEFAULTS.castBars)
    if not profile.castBars then profile.castBars = {} end
    if not profile.castBars.positioning then profile.castBars.positioning = {} end
    profile.castBars.positioning.horizontal = -4
    profile.castBars.positioning.vertical = -86
    profile.castBars.positioning.draggedBaseX = nil
    profile.castBars.positioning.draggedBaseY = nil
    profile.castBars.positioning.sliderOffsetX = nil
    profile.castBars.positioning.sliderOffsetY = nil
    if not profile.castBars.sizing then profile.castBars.sizing = {} end
    profile.castBars.sizing.scale = 87
    profile.castBars.sizing.width = 220
    profile.castBars.sizing.height = 24
    
    -- Reset diminishing returns positioning and sizing
    if not profile.diminishingReturns then profile.diminishingReturns = {} end
    if not profile.diminishingReturns.positioning then profile.diminishingReturns.positioning = {} end
    profile.diminishingReturns.positioning.horizontal = 0
    profile.diminishingReturns.positioning.vertical = 0
    profile.diminishingReturns.positioning.draggedBaseX = nil
    profile.diminishingReturns.positioning.draggedBaseY = nil
    profile.diminishingReturns.positioning.sliderOffsetX = nil
    profile.diminishingReturns.positioning.sliderOffsetY = nil
    profile.diminishingReturns.positioning.spacing = 3
    if not profile.diminishingReturns.sizing then profile.diminishingReturns.sizing = {} end
    profile.diminishingReturns.sizing.size = 33
    if not profile.diminishingReturns.rows then profile.diminishingReturns.rows = {} end
    profile.diminishingReturns.rows.growthDirection = 4  -- Right
    
    -- Reset arena frames positioning and sizing
    if not profile.arenaFrames then profile.arenaFrames = {} end
    if not profile.arenaFrames.positioning then profile.arenaFrames.positioning = {} end
    profile.arenaFrames.positioning.horizontal = 1264
    profile.arenaFrames.positioning.vertical = -297
    profile.arenaFrames.positioning.draggedBaseX = 1264
    profile.arenaFrames.positioning.draggedBaseY = -297
    profile.arenaFrames.positioning.sliderOffsetX = 0
    profile.arenaFrames.positioning.sliderOffsetY = 0
    profile.arenaFrames.positioning.spacing = 25
    profile.arenaFrames.positioning.growthDirection = "Down"
    if not profile.arenaFrames.sizing then profile.arenaFrames.sizing = {} end
    profile.arenaFrames.sizing.scale = 121
    profile.arenaFrames.sizing.width = 235
    profile.arenaFrames.sizing.height = 68
    
    -- Apply changes immediately
    if self.UpdateFramePositions then
        self:UpdateFramePositions()
    end
    
    if self.RefreshTrinketsOtherLayout then
        self:RefreshTrinketsOtherLayout()
    end
    
    if self.RefreshCastBarsLayout then
        self:RefreshCastBarsLayout()
    end
    
    if self.RefreshDRLayout then
        self:RefreshDRLayout()
    end
    
    -- Force MFM to reposition everything
    local MFM = self.MasterFrameManager
    if MFM and MFM.RefreshAllFrames then
        MFM:RefreshAllFrames()
    end
    
    print("|cff00FF00[Visual Reset]|r ✅ Visual positioning and sizing reset to Arena Core defaults!")
    print("|cff00FFFF[Visual Reset]|r Trinkets: -25, -5 (scale 142)")
    print("|cff00FFFF[Visual Reset]|r Racials: -50, -5 (scale 105)")
    print("|cff00FFFF[Visual Reset]|r Class Icons: -2, 7 (scale 109)")
    print("|cff00FFFF[Visual Reset]|r Spec Icons: -37, -37 (scale 94)")
    print("|cff00FFFF[Visual Reset]|r Cast Bars: 2, -81 (scale 86)")
    print("|cff00FFFF[Visual Reset]|r DR Icons: 0, 0 (size 33)")
    print("|cffFFAA00[Visual Reset]|r All other settings (Blackout, debuffs, etc.) preserved!")
end

-- Hard reset to defaults (wipes everything and reapplies COMPLETE beta defaults)
function AC:ResetToDefaults()
    if not self.GetBetaDefaults then
        print("|cffFF0000ArenaCore:|r GetBetaDefaults function not found in Init.lua!")
        return
    end
    
    if not _G.ArenaCoreDB then
        print("|cffFF0000ArenaCore:|r Database not initialized!")
        return
    end
    
    -- Deep copy function (local to avoid conflicts)
    local function DeepCopy(tbl)
        if type(tbl) ~= "table" then return tbl end
        local out = {}
        for k, v in pairs(tbl) do out[k] = DeepCopy(v) end
        return out
    end
    
    -- Get COMPLETE beta defaults
    local betaDefaults = self:GetBetaDefaults()
    if not betaDefaults then
        print("|cffFF0000ArenaCore:|r Failed to get beta defaults!")
        return
    end
    
    -- CRITICAL: Deep copy the defaults FIRST to avoid corrupting the source
    local defaultsCopy = DeepCopy(betaDefaults)
    
    -- Wipe profile and reapply COMPLETE defaults (using the copy, not the original)
    _G.ArenaCoreDB.profile = {}
    for key, value in pairs(defaultsCopy) do
        _G.ArenaCoreDB.profile[key] = DeepCopy(value)
    end
    
    -- Reset version tracking
    _G.ArenaCoreDB.__version = self.DEFAULTS_VERSION
    _G.ArenaCoreDB.__firstInstall = false
    
    print("|cff8B45FFArena Core:|r Hard reset complete! Complete configuration restored.")
    print("|cffFFAA00Includes:|r Blackout spells, debuffs, all settings, and features!")
    print("|cffFFAA00Note:|r Type |cffffff00/reload|r to see all changes take effect.")
end

-- ============================================================================
-- FRAME DRAGGING UTILITIES
-- ============================================================================

function AC:EnableFrameDragging()
    if not AC.ArenaFramesAnchor then return end
    
    self.isDragging = false
    self.framesLocked = false
    
    -- CRITICAL FIX: Make the ANCHOR draggable, not the individual frames
    -- This ensures all frames move together and positioning is captured correctly
    AC.ArenaFramesAnchor:SetMovable(true)
    AC.ArenaFramesAnchor:EnableMouse(true)
    AC.ArenaFramesAnchor:RegisterForDrag("LeftButton")
    AC.ArenaFramesAnchor:SetClampedToScreen(true)
    
    AC.ArenaFramesAnchor:SetScript("OnDragStart", function(self)
        self:StartMoving()
        AC.isDragging = true
    end)
    
    AC.ArenaFramesAnchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        AC.isDragging = false
        
        -- Capture the anchor's new position IMMEDIATELY (no timer)
        if AC.ArenaFramesAnchor and AC.DB and AC.DB.profile then
            -- Get current position after drag
            local point, relativeTo, relativePoint, xOfs, yOfs = AC.ArenaFramesAnchor:GetPoint()
            
            if xOfs and yOfs then
                -- SIMPLE SYSTEM: Store actual screen coordinates like spacing does
                -- GetLeft/GetBottom return positive pixel positions on screen
                local x = AC.ArenaFramesAnchor:GetLeft()
                local y = AC.ArenaFramesAnchor:GetBottom()
                
                -- 1) Mirror into GLOBAL arenaFrames.positioning (for sliders / legacy code)
                AC.DB.profile.arenaFrames = AC.DB.profile.arenaFrames or {}
                AC.DB.profile.arenaFrames.positioning = AC.DB.profile.arenaFrames.positioning or {}
                AC.DB.profile.arenaFrames.positioning.horizontal = x
                AC.DB.profile.arenaFrames.positioning.vertical = y

                -- 2) Save into THEME-SPECIFIC location (single source of truth for themes)
                if AC.ArenaFrameThemes then
                    local currentTheme = AC.ArenaFrameThemes:GetCurrentTheme()
                    if currentTheme then
                        AC.DB.profile.themeData = AC.DB.profile.themeData or {}
                        AC.DB.profile.themeData[currentTheme] = AC.DB.profile.themeData[currentTheme] or {}
                        AC.DB.profile.themeData[currentTheme].arenaFrames = AC.DB.profile.themeData[currentTheme].arenaFrames or {}
                        AC.DB.profile.themeData[currentTheme].arenaFrames.positioning = AC.DB.profile.themeData[currentTheme].arenaFrames.positioning or {}
                        AC.DB.profile.themeData[currentTheme].arenaFrames.positioning.horizontal = x
                        AC.DB.profile.themeData[currentTheme].arenaFrames.positioning.vertical = y
                        
                        -- CRITICAL FIX: Update the UI sliders to match the new dragged position
                        C_Timer.After(0.1, function()
                            if AC.sliderWidgets then
                                local hSlider = AC.sliderWidgets["arenaFrames.positioning.horizontal"]
                                local vSlider = AC.sliderWidgets["arenaFrames.positioning.vertical"]
                                
                                if hSlider then
                                    -- Temporarily disable OnValueChanged to prevent triggering save
                                    local oldScript = hSlider:GetScript("OnValueChanged")
                                    hSlider:SetScript("OnValueChanged", nil)
                                    hSlider:SetValue(x)
                                    hSlider:SetScript("OnValueChanged", oldScript)
                                end
                                if vSlider then
                                    -- Temporarily disable OnValueChanged to prevent triggering save
                                    local oldScript = vSlider:GetScript("OnValueChanged")
                                    vSlider:SetScript("OnValueChanged", nil)
                                    vSlider:SetValue(y)
                                    vSlider:SetScript("OnValueChanged", oldScript)
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)
    
    -- CRITICAL: Make individual frames forward drag events to the anchor
    local frames = GetArenaFrames()
    if frames then
        for i = 1, 3 do
            local frame = frames[i]
            if frame then
                frame:EnableMouse(true)
                frame:RegisterForDrag("LeftButton")
                
                frame:SetScript("OnDragStart", function(self)
                    -- CRITICAL: Set flag IMMEDIATELY to block slider callbacks
                    AC.justFinishedDragging = true
                    if AC.ArenaFramesAnchor then
                        AC.ArenaFramesAnchor:StartMoving()
                        AC.isDragging = true
                    end
                end)
                
                frame:SetScript("OnDragStop", function(self)
                    if AC.ArenaFramesAnchor then
                        -- Trigger the anchor's OnDragStop
                        local anchorScript = AC.ArenaFramesAnchor:GetScript("OnDragStop")
                        if anchorScript then
                            anchorScript(AC.ArenaFramesAnchor)
                        end
                        
                        -- CRITICAL: Clear the flag after drag completes and positions are saved
                        C_Timer.After(0.5, function()
                            AC.justFinishedDragging = false
                        end)
                    end
                end)
            else
                print("|cffFF0000[DRAG SETUP ERROR]|r Frame " .. i .. " is nil!")
            end
        end
    else
        print("|cffFF0000[DRAG SETUP ERROR]|r GetArenaFrames() returned nil!")
    end
    
    print("ArenaCore: Frame dragging enabled - drag any arena frame to move all frames")
end

function AC:DisableFrameDragging()
    if not AC.ArenaFramesAnchor then return end
    
    self.isDragging = false
    self.framesLocked = true
    
    -- CRITICAL FIX: Disable dragging on the ANCHOR
    AC.ArenaFramesAnchor:SetMovable(false)
    AC.ArenaFramesAnchor:EnableMouse(false)
    AC.ArenaFramesAnchor:RegisterForDrag() -- Clear drag registration
    
    AC.ArenaFramesAnchor:SetScript("OnDragStart", nil)
    AC.ArenaFramesAnchor:SetScript("OnDragStop", nil)
    
    -- Also clear drag scripts from individual frames
    local frames = GetArenaFrames()
    if frames then
        for i = 1, 3 do
            local frame = frames[i]
            if frame then
                frame:RegisterForDrag() -- Clear drag registration
                frame:SetScript("OnDragStart", nil)
                frame:SetScript("OnDragStop", nil)
            end
        end
    end
    
    print("ArenaCore: Frame dragging disabled - frames are now locked")
end

function AC:ToggleFrameDragging()
    if self.framesLocked then
        self:EnableFrameDragging()
    else
        self:DisableFrameDragging()
    end
end

-- ============================================================================
-- ADD DEFAULT BLACKOUT SPELLS - Simple command to add creator's spell list
-- ============================================================================

function AC:AddDefaultBlackoutSpells()
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.profile then
        print("|cffFF0000ArenaCore:|r Database not initialized!")
        return
    end
    
    -- Ensure blackout table exists
    if not _G.ArenaCoreDB.profile.blackout then
        _G.ArenaCoreDB.profile.blackout = { enabled = true, spells = {} }
    end
    
    if not _G.ArenaCoreDB.profile.blackout.spells then
        _G.ArenaCoreDB.profile.blackout.spells = {}
    end
    
    -- Default blackout spells from Init.lua (43 spells)
    local defaultSpells = {
        107574, 31884, 190319, 22812, 19574, 114050, 114051, 359844,
        167105, 231895, 384352, 343721, 12472, 102543, 102560, 123904,
        191427, 51271, 10060, 375982, 196770, 121471, 185313, 137639,
        207289, 1719, 391109, 228260, 357715, 266779, 378957, 203415,
        205180, 205179, 265187, 111898, 267217, 1122, 446285, 288613,
        205320, 365350, 257044
    }
    
    local currentSpells = _G.ArenaCoreDB.profile.blackout.spells
    local addedCount = 0
    local skippedCount = 0
    
    -- Add spells that don't already exist
    for _, spellID in ipairs(defaultSpells) do
        local exists = false
        for _, existingID in ipairs(currentSpells) do
            if existingID == spellID then
                exists = true
                break
            end
        end
        
        if not exists then
            table.insert(currentSpells, spellID)
            addedCount = addedCount + 1
        else
            skippedCount = skippedCount + 1
        end
    end
    
    -- Report results
    print("|cff22AA44ArenaCore:|r Blackout Spells Update Complete!")
    print("|cffFFAA00→|r Added: " .. addedCount .. " new spells")
    print("|cffFFAA00→|r Skipped: " .. skippedCount .. " (already in your list)")
    print("|cffFFAA00→|r Total: " .. #currentSpells .. " spells in your Blackout list")
    
    if addedCount > 0 then
        print("|cff00FF00Tip:|r Open Blackout Editor to see the updated spell list!")
    end
end

-- ============================================================================
-- EXPORT BLACKOUT SPELLS TO DEFAULTS - Update GetBetaDefaults with current list
-- ============================================================================

function AC:ExportBlackoutToDefaults()
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.profile or not _G.ArenaCoreDB.profile.blackout then
        print("|cffFF0000ArenaCore:|r Blackout database not found!")
        return
    end
    
    local spells = _G.ArenaCoreDB.profile.blackout.spells
    if not spells or #spells == 0 then
        print("|cffFF0000ArenaCore:|r No Blackout spells to export!")
        return
    end
    
    -- Generate the code to paste into Init.lua
    local code = "    spells = {\n"
    
    for i, spellID in ipairs(spells) do
        code = code .. "      [" .. i .. "] = " .. spellID .. ",\n"
    end
    
    code = code .. "    }"
    
    -- Use the existing export window from Init.lua
    if AC.ShowExportWindow then
        AC:ShowExportWindow(code)
    else
        print("|cffFF0000ArenaCore:|r Export window not available!")
        print("|cffFFAA00Code to paste:|r")
        print(code)
        return
    end
    
    print("|cff8B45FFArenaCore:|r Blackout spells exported! (" .. #spells .. " spells)")
    print("|cffFFAA00Instructions:|r")
    print("1. Press Ctrl+A, then Ctrl+C to copy from the window")
    print("2. Open Core/Init.lua and find the GetBetaDefaults() function (line 58)")
    print("3. Replace lines 69-96 (the blackout.spells table) with the copied text")
    print("4. Save Init.lua")
    print("|cffFFAA00Result:|r New users will get your " .. #spells .. " Blackout spells as defaults!")
end

-- ============================================================================
-- FRAME STATE UTILITIES
-- ============================================================================

function AC:GetFrameVisibilityState()
    local frames = GetArenaFrames()
    if not frames then return "no_frames" end
    
    local visibleCount = 0
    local totalCount = 0
    
    for i = 1, MAX_ARENA_ENEMIES do
        if frames[i] then
            totalCount = totalCount + 1
            if frames[i]:IsShown() then
                visibleCount = visibleCount + 1
            end
        end
    end
    
    if visibleCount == 0 then
        return "all_hidden"
    elseif visibleCount == totalCount then
        return "all_visible"
    else
        return "partial_visible"
    end
end

function AC:GetFrameCount()
    local frames = GetArenaFrames()
    if not frames then return 0 end
    
    local count = 0
    for i = 1, MAX_ARENA_ENEMIES do
        if frames[i] then
            count = count + 1
        end
    end
    
    return count
end

function AC:AreFramesInTestMode()
    return self.testModeEnabled or false
end

function AC:AreFramesLocked()
    return self.framesLocked or true
end

-- ============================================================================
-- FRAME SCALING UTILITIES
-- ============================================================================

function AC:ScaleAllFrames(scaleFactor)
    if not scaleFactor or scaleFactor <= 0 then
        scaleFactor = 1.0
    end
    
    -- Clamp scale to reasonable values
    scaleFactor = math.max(0.5, math.min(2.0, scaleFactor))
    
    local frames = GetArenaFrames()
    if not frames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        if frames[i] then
            frames[i]:SetScale(scaleFactor)
        end
    end
    
    -- Save scale to database
    self:EnsureDB()
    self:SetPath(self.DB.profile, "arenaFrames.sizing.scale", scaleFactor * 100)
    
    print("ArenaCore: All frames scaled to " .. (scaleFactor * 100) .. "%")
end

function AC:ResetFrameScale()
    self:ScaleAllFrames(1.0)
end

-- ============================================================================
-- FRAME ALPHA UTILITIES
-- ============================================================================

function AC:SetFrameAlpha(alpha)
    if not alpha then alpha = 1.0 end
    
    -- Clamp alpha to valid range
    alpha = math.max(0.0, math.min(1.0, alpha))
    
    local frames = GetArenaFrames()
    if not frames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        if frames[i] then
            frames[i]:SetAlpha(alpha)
        end
    end
    
    print("ArenaCore: Frame alpha set to " .. (alpha * 100) .. "%")
end

function AC:FadeFramesIn(duration)
    duration = duration or 0.5
    
    local frames = GetArenaFrames()
    if not frames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        if frames[i] then
            frames[i]:SetAlpha(0)
            frames[i]:Show()
            
            -- Use WoW's fade in function if available
            if UIFrameFadeIn then
                UIFrameFadeIn(frames[i], duration, 0, 1)
            else
                -- Fallback manual fade
                local startTime = GetTime()
                -- PHASE 3: Reduced from 0.02s to 0.05s (60% reduction, still smooth at 20 FPS)
                local ticker = C_Timer.NewTicker(0.05, function()
                    local elapsed = GetTime() - startTime
                    local progress = math.min(1, elapsed / duration)
                    frames[i]:SetAlpha(progress)
                    
                    if progress >= 1 then
                        ticker:Cancel()
                    end
                end)
            end
        end
    end
end

function AC:FadeFramesOut(duration)
    duration = duration or 0.5
    
    local frames = GetArenaFrames()
    if not frames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        if frames[i] then
            -- Use WoW's fade out function if available
            if UIFrameFadeOut then
                UIFrameFadeOut(frames[i], duration, 1, 0)
            else
                -- Fallback manual fade
                local startTime = GetTime()
                local startAlpha = frames[i]:GetAlpha()
                -- PHASE 3: Reduced from 0.02s to 0.05s (60% reduction, still smooth at 20 FPS)
                local ticker = C_Timer.NewTicker(0.05, function()
                    local elapsed = GetTime() - startTime
                    local progress = math.min(1, elapsed / duration)
                    local currentAlpha = startAlpha * (1 - progress)
                    frames[i]:SetAlpha(currentAlpha)
                    
                    if progress >= 1 then
                        frames[i]:Hide()
                        ticker:Cancel()
                    end
                end)
            end
        end
    end
end

-- ============================================================================
-- FRAME SIZE UTILITIES
-- ============================================================================

function AC:ResizeAllFrames(width, height)
    if not width or not height then return end
    
    -- Clamp sizes to reasonable values
    width = math.max(100, math.min(800, width))
    height = math.max(50, math.min(200, height))
    
    local frames = GetArenaFrames()
    if not frames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        if frames[i] then
            frames[i]:SetSize(width, height)
        end
    end
    
    -- Save size to database
    self:EnsureDB()
    self:SetPath(self.DB.profile, "arenaFrames.sizing.width", width)
    self:SetPath(self.DB.profile, "arenaFrames.sizing.height", height)
    
    print("ArenaCore: All frames resized to " .. width .. "x" .. height)
end

function AC:ResetFrameSize()
    self:ResizeAllFrames(350, 72) -- Default ArenaCore frame size
end

-- ============================================================================
-- FRAME VALIDATION UTILITIES
-- ============================================================================

function AC:ValidateFrames()
    local frames = GetArenaFrames()
    if not frames then
        print("ArenaCore: No frames found - frames may not be initialized")
        return false
    end
    
    local issues = {}
    local validFrames = 0
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            validFrames = validFrames + 1
            
            -- Check essential components
            if not frame.healthBar then
                table.insert(issues, "Frame " .. i .. " missing health bar")
            end
            
            if not frame.manaBar then
                table.insert(issues, "Frame " .. i .. " missing mana bar")
            end
            
            if not frame.playerName then
                table.insert(issues, "Frame " .. i .. " missing player name")
            end
            
            if not frame.classIcon then
                table.insert(issues, "Frame " .. i .. " missing class icon")
            end
            
            if not frame.trinketIndicator then
                table.insert(issues, "Frame " .. i .. " missing trinket indicator")
            end
        else
            table.insert(issues, "Frame " .. i .. " is nil")
        end
    end
    
    print("ArenaCore: Frame validation complete")
    print("Valid frames: " .. validFrames .. "/" .. MAX_ARENA_ENEMIES)
    
    if #issues > 0 then
        print("Issues found:")
        for _, issue in ipairs(issues) do
            print("  - " .. issue)
        end
        return false
    else
        print("All frames validated successfully!")
        return true
    end
end

-- ============================================================================
-- FRAME REFRESH UTILITIES
-- ============================================================================

-- CRITICAL: This function applies DATABASE settings to frames (resizes, repositions, etc.)
-- ONLY call this when:
--   1. User changes settings in options panel
--   2. User switches themes
--   3. User manually requests a refresh via /ac refresh command
--
-- DO NOT call this on:
--   - PLAYER_ENTERING_WORLD (reloads)
--   - ARENA_PREP_OPPONENT_SPECIALIZATIONS (prep room)
--   - ARENA_OPPONENT_UPDATE (live arena)
--
-- For reloads/arena events, use MFM:UpdateVisible() and MFM:UpdateArenaData() instead.
-- This follows the pattern of separating "apply settings" from "update data".
function AC:RefreshAllFrames()
    -- Refresh all frame layouts and settings
    if self.RefreshTexturesLayout then
        self:RefreshTexturesLayout()
    end
    
    if self.RefreshCastBarsLayout then
        self:RefreshCastBarsLayout()
    end
    
    -- Diminishing Returns
    if self.RefreshDRLayout then
        self:RefreshDRLayout()
    end
    
    if self.RefreshTrinketsOtherLayout then
        self:RefreshTrinketsOtherLayout()
    end
    
    if self.RefreshMoreGoodiesLayout then
        self:RefreshMoreGoodiesLayout()
    end
    
    -- LONG-TERM FIX: Apply frame sizes from profile settings
    -- This also calls UpdateFramePositions() automatically to reposition with new sizes
    if MFM and MFM.ApplyFrameSizes then
        MFM:ApplyFrameSizes()
    end
    
    -- Apply general settings (NEW!)
    if self.ApplyGeneralSettings then
        self:ApplyGeneralSettings()
    end
    
    -- CRITICAL: If a theme with special positioning is active, reapply theme positioning
    -- This ensures slider changes take effect for themes like "The 1500 Special"
    if self.ArenaFrameThemes then
        local currentTheme = self.ArenaFrameThemes:GetCurrentTheme()
        local theme = currentTheme and self.ArenaFrameThemes.themes and self.ArenaFrameThemes.themes[currentTheme]
        if theme and theme.positioning and theme.positioning.nameAboveHealthBar then
            local frames = GetArenaFrames()
            if frames then
                for i = 1, MAX_ARENA_ENEMIES do
                    if frames[i] then
                        self.ArenaFrameThemes:ApplySpecialPositioning(frames[i], theme.positioning)
                    end
                end
            end
        end
    end
    
    -- CRITICAL: Force health bar color updates (for class colors toggle)
    self:ForceHealthBarColorUpdate()
    
    -- Apply settings via ProfileManager
    if self.ProfileManager and self.ProfileManager.ApplyArenaFramesSettings then
        self.ProfileManager:ApplyArenaFramesSettings()
    end
    
    -- CRITICAL: Refresh test mode player names if in test mode
    if self.testModeEnabled and MFM and MFM.frames then
        for i = 1, MAX_ARENA_ENEMIES do
            if MFM.frames[i] then
                MFM:ApplyTestDataToFrame(MFM.frames[i], i)
            end
        end
    end
    
    -- DEBUG: All frames refreshed
    -- print("ArenaCore: All frames refreshed with current settings")
end

-- Force update health bar colors based on current class colors setting
function AC:ForceHealthBarColorUpdate()
    local frames = GetArenaFrames()
    if not frames then 
        -- DEBUG: No frames found
        -- print("|cffFF0000[FORCE COLOR UPDATE]|r No frames found!")
        return 
    end
    
    local general = self.DB and self.DB.profile and self.DB.profile.arenaFrames and self.DB.profile.arenaFrames.general
    local useClassColors = general and general.useClassColors ~= false
    
    -- DEBUG: useClassColors
    -- print("|cffFFFF00[FORCE COLOR UPDATE]|r useClassColors: " .. tostring(useClassColors))
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame and frame.healthBar then
            if useClassColors then
                -- Get class and apply class color
                local unit = frame.unit or ("arena" .. i)
                local _, classFile = UnitClass(unit)
                
                -- In test mode, use stored test class if unit doesn't exist
                if not classFile and self.testModeEnabled and frame.testClass then
                    classFile = frame.testClass
                    -- DEBUG: Using test class
                    -- print("|cffFFFF00[FORCE COLOR UPDATE]|r Frame " .. i .. " - Using test class: " .. tostring(classFile))
                end
                
                -- DEBUG: Frame unit and class
                -- print("|cffFFFF00[FORCE COLOR UPDATE]|r Frame " .. i .. " - unit: " .. tostring(unit) .. ", class: " .. tostring(classFile))
                if classFile then
                    local classColors = {
                        ["DEATHKNIGHT"] = {0.77, 0.12, 0.23},
                        ["DEMONHUNTER"] = {0.64, 0.19, 0.79},
                        ["DRUID"] = {1.00, 0.49, 0.04},
                        ["EVOKER"] = {0.20, 0.58, 0.50},
                        ["HUNTER"] = {0.67, 0.83, 0.45},
                        ["MAGE"] = {0.25, 0.78, 0.92},
                        ["MONK"] = {0.00, 1.00, 0.59},
                        ["PALADIN"] = {0.96, 0.55, 0.73},
                        ["PRIEST"] = {1.00, 1.00, 1.00},
                        ["ROGUE"] = {1.00, 0.96, 0.41},
                        ["SHAMAN"] = {0.00, 0.44, 0.87},
                        ["WARLOCK"] = {0.53, 0.53, 0.93},
                        ["WARRIOR"] = {0.78, 0.61, 0.43}
                    }
                    local color = classColors[classFile]
                    if color then
                        frame.healthBar:SetStatusBarColor(color[1], color[2], color[3], 1)
                        -- DEBUG: Applied class color
                        -- print("|cff00FF00[FORCE COLOR UPDATE]|r Applied class color for " .. classFile)
                    else
                        -- DEBUG: No color found
                        -- print("|cffFF0000[FORCE COLOR UPDATE]|r No color found for class: " .. tostring(classFile))
                    end
                else
                    -- DEBUG: No class found
                    -- print("|cffFF0000[FORCE COLOR UPDATE]|r No class found for unit: " .. tostring(unit))
                end
            else
                -- Use default green when class colors are disabled
                frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
                -- DEBUG: Set to green
                -- print("|cffFFFF00[FORCE COLOR UPDATE]|r Set to green (class colors disabled)")
            end
        end
    end
end

-- ============================================================================
-- GENERAL SETTINGS APPLICATION - Connect Arena Frames UI to Master Frame System
-- ============================================================================

function AC:ApplyGeneralSettings()
    -- CRITICAL FIX: Skip this heavy function during slider drag
    if AC._sliderDragActive then
        return
    end
    
    local frames = GetArenaFrames()
    
    if not frames then 
        -- Try alternative frame sources
        if MFM and MFM.frames then
            frames = MFM.frames
        elseif AC.arenaFrames then
            frames = AC.arenaFrames
        end
        
        if not frames then
            print("|cffFF0000[ERROR]|r No frames available for general settings!")
            return
        end
    end
    
    -- Get general settings from database
    local general = self.DB and self.DB.profile and self.DB.profile.arenaFrames and self.DB.profile.arenaFrames.general
    if not general then 
        print("|cffFF0000[ERROR]|r No general settings found in database")
        return 
    end
    
    -- DEBUG: Applying general settings
    -- print("|cff8B45FFArenaCore:|r Applying general settings to frames...")
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            self:ApplyFrameGeneralSettings(frame, general)
        end
    end
    
    -- CRITICAL: Force health bar color update after applying settings
    -- This ensures class colors toggle works immediately
    self:ForceHealthBarColorUpdate()
end

function AC:ApplyFrameGeneralSettings(frame, general)
    if not frame or not general then return end
    
    -- ==========================================
    -- TEXT DISPLAY SETTINGS (Checkboxes)
    -- ==========================================
    
    -- Status Text (Health and Resource percentages)
    local statusTextEnabled = general.statusText ~= false
    local usePercentage = general.usePercentage ~= false
    
    if frame.healthBar and frame.healthBar.text then
        if statusTextEnabled then
            if not InCombatLockdown() then
                frame.healthBar.text:Show()
            end
            -- CRITICAL FIX: Only set placeholder text if unit doesn't exist (prep room)
            -- In live arena, UpdateHealth will set the real value
            local unit = frame.unit
            if not unit or not UnitExists(unit) then
                -- Prep room or no unit - set placeholder
                if usePercentage then
                    frame.healthBar.text:SetText("100%")
                else
                    frame.healthBar.text:SetText("100")
                end
            end
            -- If unit exists, UpdateHealth will handle the text via UNIT_HEALTH events
        else
            frame.healthBar.text:Hide()
        end
    end
    
    if frame.manaBar and frame.manaBar.text then
        if statusTextEnabled then
            -- CRITICAL FIX: Only show/set text if unit exists (not in prep room)
            local unit = frame.unit
            if not unit or not UnitExists(unit) then
                -- Prep room - hide mana text (user request)
                frame.manaBar.text:SetText("")
                frame.manaBar.text:Hide()
            else
                -- Unit exists - show text and let UpdatePower handle the value
                if not InCombatLockdown() then
                    frame.manaBar.text:Show()
                end
            end
        else
            frame.manaBar.text:Hide()
        end
    end
    
    -- Use Class Colors (for health bars)
    local useClassColors = general.useClassColors ~= false
    if frame.healthBar and not useClassColors then
        -- Reset to default green if class colors disabled
        frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
    end
    -- Class colors will be applied in UpdateArenaUnit when enabled
    
    -- ==========================================
    -- PLAYER NAME DISPLAY (Show Names vs Arena Labels)
    -- ==========================================
    
    -- CRITICAL FIX: Handle showNames and showArenaLabels settings
    if frame.playerName then
        local showNames = general.showNames ~= false
        local showArenaLabels = general.showArenaLabels == true
        
        if showNames or showArenaLabels then
            if not InCombatLockdown() then
                frame.playerName:Show()
                
                -- CRITICAL FIX: Don't set text here - let SetArenaFrameText handle it
                -- This prevents conflicts between ApplyGeneralSettings and UpdateName
                -- Just trigger an update to refresh the text with current settings
                if frame.unit and UnitExists(frame.unit) then
                    -- Live arena - trigger UpdateName to refresh text
                    if AC.MasterFrameManager and AC.MasterFrameManager.UpdateName then
                        AC.MasterFrameManager:UpdateName(frame)
                    end
                elseif AC.testModeEnabled then
                    -- Test mode - force refresh test data to get correct names
                    if AC.MasterFrameManager and AC.MasterFrameManager.ApplyTestDataToFrame then
                        C_Timer.After(0.05, function()
                            AC.MasterFrameManager:ApplyTestDataToFrame(frame, frame.id)
                        end)
                    end
                end
            end
        else
            frame.playerName:Hide()
        end
    end
    
    -- ==========================================
    -- ARENA NUMBER DISPLAY (Mutual Exclusivity Fix)
    -- ==========================================
    
    -- CRITICAL FIX: Arena numbers should NEVER show when Show Names is enabled
    -- This prevents the clash where frame 2 shows "Arena 2" while frames 1/3 show player names
    if frame.arenaNumber then
        local showNames = general.showNames ~= false
        local showArenaLabels = general.showArenaLabels == true
        local showArenaNumbers = general.showArenaNumbers ~= false
        
        -- MUTUAL EXCLUSIVITY: Arena numbers only show if:
        -- 1. showArenaNumbers is enabled AND
        -- 2. showNames is disabled (user wants "Arena 1/2/3" not player names)
        if showArenaNumbers and not showNames and not showArenaLabels then
            if not InCombatLockdown() then
                frame.arenaNumber:Show()
            end
        else
            -- Hide arena numbers when showing player names or arena labels
            if not InCombatLockdown() then
                frame.arenaNumber:Hide()
            end
        end
    end
    
    -- ==========================================
    -- PLAYER NAME POSITIONING (Sliders) - LIGHTWEIGHT VERSION
    -- ==========================================
    
    -- DEBUG: Show what we're working with
    if AC.DEBUG_NAME_POSITIONING then
        print(string.format("|cffFFFF00[NAME POS DEBUG]|r playerNameX/Y: %s/%s (type: %s/%s)", 
            tostring(general.playerNameX), tostring(general.playerNameY),
            type(general.playerNameX), type(general.playerNameY)))
    end
    
    -- CRITICAL FIX: Don't require both X and Y to exist - use defaults if missing
    if frame.playerName then
        -- CRITICAL FIX: Use proper nil check - 0 is a valid value!
        local nameX = (general.playerNameX ~= nil) and general.playerNameX or 52
        local nameY = (general.playerNameY ~= nil) and general.playerNameY or 0
        
        frame.playerName:ClearAllPoints()
        
        -- CRITICAL FIX: Check if theme has moved playerName to an overlay
        -- If so, position relative to the overlay's parent (which is the main frame)
        local parent = frame.playerName:GetParent()
        if parent and parent ~= frame then
            -- PlayerName is in a theme overlay - position the overlay relative to frame
            -- The overlay is already SetAllPoints to frame, so we position playerName within it
            frame.playerName:SetPoint("TOPLEFT", parent, "TOPLEFT", nameX, nameY)
        else
            -- Normal case - position directly on frame
            frame.playerName:SetPoint("TOPLEFT", frame, "TOPLEFT", nameX, nameY)
        end
    end
    
    -- ==========================================
    -- ARENA NUMBER POSITIONING (Sliders) - Now handled in UpdateFrameTextPositioningOnly
    -- ==========================================
    
    -- ==========================================
    -- TEXT SCALING (Sliders)
    -- ==========================================
    
    -- Player Name Scale
    if frame.playerName and general.playerNameScale then
        local scale = (general.playerNameScale or 100) / 100
        frame.playerName:SetScale(scale)
    end
    
    -- Arena Number Scale
    if frame.arenaNumberText and general.arenaNumberScale then
        local scale = (general.arenaNumberScale or 100) / 100
        frame.arenaNumberText:SetScale(scale)
    end
    
    -- Health Text Scale
    if frame.healthBar and frame.healthBar.statusText and general.healthTextScale then
        local scale = (general.healthTextScale or 100) / 100
        frame.healthBar.statusText:SetScale(scale)
    end
    
    -- Resource Text Scale
    if frame.manaBar and frame.manaBar.statusText and general.resourceTextScale then
        local scale = (general.resourceTextScale or 100) / 100
        frame.manaBar.statusText:SetScale(scale)
    end
    
    -- Spell Text Scale
    if frame.castBar and frame.castBar.Text and general.spellTextScale then
        local scale = (general.spellTextScale or 100) / 100
        frame.castBar.Text:SetScale(scale)
    end
end

-- ============================================================================
-- LIGHTWEIGHT TEXT POSITIONING UPDATE - Prevents visual glitches during slider drags
-- ============================================================================

function AC:UpdateTextPositioningOnly()
    -- Only update text elements (player names, arena numbers) without touching other frame components
    local frames = GetArenaFrames()
    
    if not frames then 
        -- Try alternative frame sources
        if MFM and MFM.frames then
            frames = MFM.frames
        elseif AC.arenaFrames then
            frames = AC.arenaFrames
        end
        
        if not frames then
            return
        end
    end
    
    -- Get general settings from database
    local general = self.DB and self.DB.profile and self.DB.profile.arenaFrames and self.DB.profile.arenaFrames.general
    if not general then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            -- ONLY update player name and arena number positioning - skip everything else
            self:UpdateFrameTextPositioningOnly(frame, general)
        end
    end
end

function AC:UpdateFrameTextPositioningOnly(frame, general)
    if not frame or not general then return end
    
    -- ==========================================
    -- PLAYER NAME POSITIONING ONLY
    -- ==========================================
    
    if frame.playerName then
        local nameX = (general.playerNameX ~= nil) and general.playerNameX or 52
        local nameY = (general.playerNameY ~= nil) and general.playerNameY or 0
        
        -- CRITICAL FIX: Only reposition if values actually changed (prevents flicker from redundant SetPoint calls)
        -- Round to integers to prevent sub-pixel changes that cause flicker
        -- But allow small changes during drag for real-time feedback
        nameX = math.floor(nameX + 0.5)
        nameY = math.floor(nameY + 0.5)
        
        -- During slider drag, allow more frequent updates for real-time movement
        local lastX = frame.playerName._lastX or 0
        local lastY = frame.playerName._lastY or 0
        
        if AC._sliderDragActive then
            -- During drag: Allow small position changes for smooth real-time movement
            if math.abs(nameX - lastX) >= 1 or math.abs(nameY - lastY) >= 1 then
                frame.playerName._lastX = nameX
                frame.playerName._lastY = nameY
                -- Apply positioning - CRITICAL: Only clear points when actually changing position
                frame.playerName:ClearAllPoints()
                local parent = frame.playerName:GetParent()
                if parent and parent ~= frame then
                    frame.playerName:SetPoint("TOPLEFT", parent, "TOPLEFT", nameX, nameY)
                else
                    frame.playerName:SetPoint("TOPLEFT", frame, "TOPLEFT", nameX, nameY)
                end
            end
            -- CRITICAL FIX: If position hasn't changed, don't do anything (prevents flicker)
        else
            -- Not dragging: Use strict change detection to prevent flicker
            if frame.playerName._lastX ~= nameX or frame.playerName._lastY ~= nameY then
                frame.playerName._lastX = nameX
                frame.playerName._lastY = nameY
                -- Apply positioning
                frame.playerName:ClearAllPoints()
                local parent = frame.playerName:GetParent()
                if parent and parent ~= frame then
                    frame.playerName:SetPoint("TOPLEFT", parent, "TOPLEFT", nameX, nameY)
                else
                    frame.playerName:SetPoint("TOPLEFT", frame, "TOPLEFT", nameX, nameY)
                end
            end
        end
    end
    
    -- ==========================================
    -- ARENA NUMBER POSITIONING ONLY
    -- ==========================================
    
    if frame.arenaNumberFrame then
        local numberX = (general.arenaNumberX ~= nil) and general.arenaNumberX or 190
        local numberY = (general.arenaNumberY ~= nil) and general.arenaNumberY or -3
        
        -- Round to integers to prevent sub-pixel positioning
        numberX = math.floor(numberX + 0.5)
        numberY = math.floor(numberY + 0.5)
        
        -- Only update if position changed
        if frame.arenaNumberFrame._lastX ~= numberX or frame.arenaNumberFrame._lastY ~= numberY then
            frame.arenaNumberFrame._lastX = numberX
            frame.arenaNumberFrame._lastY = numberY
            
            -- Apply positioning
            frame.arenaNumberFrame:ClearAllPoints()
            frame.arenaNumberFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", numberX, numberY)
        end
    end
end

-- Helper function to check if class colors are enabled
function AC:GetClassColorsEnabled()
    local general = self.DB and self.DB.profile and self.DB.profile.arenaFrames and self.DB.profile.arenaFrames.general
    return general and general.useClassColors ~= false
end

-- ============================================================================
-- PHASE 1: LIGHTWEIGHT PER-SETTING UPDATE FUNCTIONS
-- Replaces heavy ApplyGeneralSettings/RefreshFrames with targeted updates
-- ============================================================================

function AC:UpdateArenaGeneralSetting(path)
    -- Extract the setting name from the path (e.g., "arenaFrames.general.healthTextScale" -> "healthTextScale")
    local settingName = path:match("%.([^%.]+)$")
    if not settingName then return end
    
    local frames = GetArenaFrames()
    if not frames then
        if MFM and MFM.frames then
            frames = MFM.frames
        elseif AC.arenaFrames then
            frames = AC.arenaFrames
        end
        if not frames then return end
    end
    
    local general = self.DB and self.DB.profile and self.DB.profile.arenaFrames and self.DB.profile.arenaFrames.general
    if not general then return end
    
    -- Route to specific lightweight update based on setting name
    if settingName == "healthTextScale" or settingName == "resourceTextScale" or settingName == "spellTextScale" then
        -- Text scale settings - update only text scales
        self:UpdateArenaTextScalesOnly()
        
    elseif settingName == "playerNameScale" or settingName == "arenaNumberScale" then
        -- Name/number scale settings - update only name/number scales
        self:UpdateArenaNameNumberScalesOnly()
        
    elseif settingName == "useClassColors" then
        -- Class colors toggle - update only bar colors
        self:UpdateArenaHealthBarColorsOnly()
        
    elseif settingName == "showStatusText" or settingName == "usePercentage" then
        -- Status text toggles - update only text visibility/format
        self:UpdateArenaStatusTextOnly()
        
    else
        -- Unknown setting - fallback to lightweight text positioning
        -- (safer than calling full ApplyGeneralSettings)
        self:UpdateTextPositioningOnly()
    end
end

function AC:UpdateArenaTextScalesOnly()
    local frames = GetArenaFrames()
    if not frames then
        if MFM and MFM.frames then frames = MFM.frames
        elseif AC.arenaFrames then frames = AC.arenaFrames end
        if not frames then return end
    end
    
    local general = self.DB and self.DB.profile and self.DB.profile.arenaFrames and self.DB.profile.arenaFrames.general
    if not general then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            -- Health text scale - only update if changed
            if frame.healthBar and frame.healthBar.statusText and general.healthTextScale then
                local scale = (general.healthTextScale or 100) / 100
                if frame.healthBar.statusText._lastScale ~= scale then
                    frame.healthBar.statusText._lastScale = scale
                    frame.healthBar.statusText:SetScale(scale)
                end
            end
            
            -- Resource text scale - only update if changed
            if frame.manaBar and frame.manaBar.statusText and general.resourceTextScale then
                local scale = (general.resourceTextScale or 100) / 100
                if frame.manaBar.statusText._lastScale ~= scale then
                    frame.manaBar.statusText._lastScale = scale
                    frame.manaBar.statusText:SetScale(scale)
                end
            end
            
            -- Spell text scale (cast bar) - only update if changed
            if frame.castBar and frame.castBar.Text and general.spellTextScale then
                local scale = (general.spellTextScale or 100) / 100
                if frame.castBar.Text._lastScale ~= scale then
                    frame.castBar.Text._lastScale = scale
                    frame.castBar.Text:SetScale(scale)
                end
            end
        end
    end
end

function AC:UpdateArenaNameNumberScalesOnly()
    local frames = GetArenaFrames()
    if not frames then
        if MFM and MFM.frames then frames = MFM.frames
        elseif AC.arenaFrames then frames = AC.arenaFrames end
        if not frames then return end
    end
    
    local general = self.DB and self.DB.profile and self.DB.profile.arenaFrames and self.DB.profile.arenaFrames.general
    if not general then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            -- Player name scale - only update if changed
            if frame.playerName and general.playerNameScale then
                local scale = (general.playerNameScale or 100) / 100
                if frame.playerName._lastScale ~= scale then
                    frame.playerName._lastScale = scale
                    frame.playerName:SetScale(scale)
                end
            end
            
            -- Arena number scale - only update if changed
            if frame.arenaNumberFrame and general.arenaNumberScale then
                local scale = (general.arenaNumberScale or 100) / 100
                if frame.arenaNumberFrame._lastScale ~= scale then
                    frame.arenaNumberFrame._lastScale = scale
                    frame.arenaNumberFrame:SetScale(scale)
                end
            end
        end
    end
end

function AC:UpdateArenaHealthBarColorsOnly()
    local frames = GetArenaFrames()
    if not frames then
        if MFM and MFM.frames then frames = MFM.frames
        elseif AC.arenaFrames then frames = AC.arenaFrames end
        if not frames then return end
    end
    
    local general = self.DB and self.DB.profile and self.DB.profile.arenaFrames and self.DB.profile.arenaFrames.general
    if not general then return end
    
    local useClassColors = general.useClassColors ~= false
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame and frame.healthBar then
            if useClassColors and frame.classFile and RAID_CLASS_COLORS[frame.classFile] then
                -- Apply class color
                local classColor = RAID_CLASS_COLORS[frame.classFile]
                frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
            else
                -- Apply default green color
                frame.healthBar:SetStatusBarColor(0, 1, 0)
            end
        end
    end
end

function AC:UpdateArenaStatusTextOnly()
    -- CRITICAL FIX: Update BOTH frame systems
    local general = self.DB and self.DB.profile and self.DB.profile.arenaFrames and self.DB.profile.arenaFrames.general
    if not general then return end
    
    -- CRITICAL: Use correct database path (statusText, not showStatusText)
    local showStatusText = general.statusText ~= false
    local usePercentage = general.usePercentage ~= false
    
    -- Update MasterFrameManager.frames (new unified system - live arena/prep room)
    if MFM and MFM.frames then
        for i = 1, MAX_ARENA_ENEMIES do
            local frame = MFM.frames[i]
            if frame then
                -- Update health bar text
                if frame.healthBar and frame.healthBar.text then
                    if showStatusText then
                        frame.healthBar.text:Show()
                        local health = frame.healthBar:GetValue() or 0
                        local maxHealth = select(2, frame.healthBar:GetMinMaxValues()) or 1
                        if maxHealth > 0 then
                            if usePercentage then
                                local pct = math.floor((health / maxHealth) * 100)
                                frame.healthBar.text:SetText(pct .. "%")
                            else
                                frame.healthBar.text:SetText(AbbreviateLargeNumbers(health))
                            end
                        end
                    else
                        frame.healthBar.text:Hide()
                    end
                end
                
                -- Update mana bar text
                if frame.manaBar and frame.manaBar.text then
                    if showStatusText then
                        frame.manaBar.text:Show()
                        local power = frame.manaBar:GetValue() or 0
                        local maxPower = select(2, frame.manaBar:GetMinMaxValues()) or 1
                        if maxPower > 0 then
                            if usePercentage then
                                local pct = math.floor((power / maxPower) * 100)
                                frame.manaBar.text:SetText(pct .. "%")
                            else
                                frame.manaBar.text:SetText(AbbreviateLargeNumbers(power))
                            end
                        end
                    else
                        frame.manaBar.text:Hide()
                    end
                end
            end
        end
    end
    
    -- Update AC.arenaFrames (old system - test mode)
    if AC.arenaFrames then
        for i = 1, MAX_ARENA_ENEMIES do
            local frame = AC.arenaFrames[i]
            if frame then
                -- Update health bar text (old system uses statusText alias)
                if frame.healthBar and frame.healthBar.statusText then
                    if showStatusText then
                        frame.healthBar.statusText:Show()
                        local health = frame.healthBar:GetValue() or 0
                        local maxHealth = select(2, frame.healthBar:GetMinMaxValues()) or 1
                        if maxHealth > 0 then
                            if usePercentage then
                                local pct = math.floor((health / maxHealth) * 100)
                                frame.healthBar.statusText:SetText(pct .. "%")
                            else
                                frame.healthBar.statusText:SetText(AbbreviateLargeNumbers(health))
                            end
                        end
                    else
                        frame.healthBar.statusText:Hide()
                    end
                end
                
                -- Update mana bar text (old system uses statusText alias)
                if frame.manaBar and frame.manaBar.statusText then
                    if showStatusText then
                        frame.manaBar.statusText:Show()
                        local power = frame.manaBar:GetValue() or 0
                        local maxPower = select(2, frame.manaBar:GetMinMaxValues()) or 1
                        if maxPower > 0 then
                            if usePercentage then
                                local pct = math.floor((power / maxPower) * 100)
                                frame.manaBar.statusText:SetText(pct .. "%")
                            else
                                frame.manaBar.statusText:SetText(AbbreviateLargeNumbers(power))
                            end
                        end
                    else
                        frame.manaBar.statusText:Hide()
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- FRAME DEBUGGING UTILITIES
-- ============================================================================

-- ============================================================================
-- FRAME DEBUGGING UTILITIES
-- ============================================================================

function AC:PrintFrameDebugInfo()
    local frames = MFM and MFM.frames or {}
    if not frames or not next(frames) then
        print("ArenaCore Debug: No frames available")
        return
    end
    
    print("=== ArenaCore Frame Debug Info ===")
    print("Test Mode: " .. tostring(self.testModeEnabled))
    print("Frames Locked: " .. tostring(self.framesLocked))
    print("Is Dragging: " .. tostring(self.isDragging))
    
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            local x, y = frame:GetCenter()
            local width, height = frame:GetSize()
            local scale = frame:GetScale()
            local alpha = frame:GetAlpha()
            local visible = frame:IsShown()
            
            print("Frame " .. i .. ":")
            print("  Position: (" .. (x or "nil") .. ", " .. (y or "nil") .. ")")
            print("  Size: " .. width .. "x" .. height)
            print("  Scale: " .. scale)
            print("  Alpha: " .. alpha)
            print("  Visible: " .. tostring(visible))
            
            if frame.unit then
                print("  Unit: " .. frame.unit)
            end
            
            if frame.playerName and frame.playerName:GetText() then
                print("  Player: " .. frame.playerName:GetText())
            end
        else
            print("Frame " .. i .. ": nil")
        end
    end
    print("=== End Debug Info ===")
end

-- ============================================================================
-- CHUNK 12: INITIALIZATION & EVENT REGISTRATION
-- Final initialization, slash commands, startup code, and event handlers
-- ============================================================================

-- ============================================================================
-- SLASH COMMANDS AND INTEGRATION
-- ============================================================================

-- Master system slash commands
SLASH_ARENAMASTERCORE1 = "/acmaster"
SLASH_ARENAMASTERCORE2 = "/acm"
SlashCmdList["ARENAMASTERCORE"] = function(msg)
    msg = msg:lower()
    
    if msg == "test" then
        if MFM.isTestMode then
            MFM:DisableTestMode()
        else
            MFM:EnableTestMode()
        end
    elseif msg == "show" then
        MFM:ShowArenaFrames()
    elseif msg == "hide" then
        MFM:HideAllFrames()
    elseif msg == "reset" then
        MFM:UpdateFramePositions()
        print("|cffFFAA00ArenaCore Master:|r Frames reset to saved positions")
    elseif msg == "status" then
        print("|cffFFAA00ArenaCore Master Status:|r")
        print("  isInArena: " .. tostring(MFM.isInArena))
        print("  isTestMode: " .. tostring(MFM.isTestMode))
        print("  instanceType: " .. tostring(MFM.instanceType))
        print("  Frames created: " .. (#MFM.frames))
    elseif msg == "init" then
        MFM:Initialize()
    elseif msg == "validate" then
        AC:ValidateFrames()
    elseif msg == "debug" then
        AC:PrintFrameDebugInfo()
    elseif msg == "drag" then
        AC:ToggleFrameDragging()
    elseif msg == "refresh" then
        AC:RefreshAllFrames()
    elseif msg == "scale reset" then
        AC:ResetFrameScale()
    elseif msg == "size reset" then
        AC:ResetFrameSize()
    elseif msg == "settings" then
        -- Test the general settings application
        if AC.ApplyGeneralSettings then
            AC:ApplyGeneralSettings()
        else
            print("|cffFF0000ArenaCore:|r ApplyGeneralSettings function not found!")
        end
    elseif msg == "create" then
        -- Force create frames
        if MFM and MFM.Initialize then
            MFM:Initialize()
        else
            print("|cffFF0000ArenaCore:|r Master Frame Manager not available!")
        end
    else
        print("|cffFFAA00ArenaCore Master Commands:|r")
        print("  /acmaster test - Toggle test mode")
        print("  /acmaster show - Show frames")
        print("  /acmaster hide - Hide frames")
        print("  /acmaster reset - Reset positions")
        print("  /acmaster status - Show system status")
        print("  /acmaster init - Reinitialize system")
        print("  /acmaster validate - Validate frame integrity")
        print("  /acmaster debug - Print debug information")
        print("  /acmaster drag - Toggle frame dragging")
        print("  /acmaster refresh - Refresh all frame layouts")
        print("  /acmaster scale reset - Reset frame scale")
        print("  /acmaster size reset - Reset frame size")
        print("  /acmaster settings - Test apply general settings")
        print("  /acmaster create - Force create frames")
    end
end

-- Debug slash commands (separate to avoid UI conflict)
SLASH_ARENACOREDEBUG1 = "/acdebug"
SLASH_ARENACOREDEBUG2 = "/acdbg"
SlashCmdList["ARENACOREDEBUG"] = function(msg)
    local AC = _G.ArenaCore
    if not AC then
        print("|cffFF0000ArenaCore:|r Addon not loaded!")
        return
    end
    
    msg = msg:lower()
    
    if msg == "absorb" or msg == "absorbs" then
        -- Toggle absorb system debug mode
        if not AC.ABSORB_DEBUG then
            AC.ABSORB_DEBUG = true
            print("|cffFFAA00ArenaCore:|r Absorb debug ENABLED")
            print("|cff00FF00[AbsorbDebug]|r Will show detailed absorb detection and display info")
        else
            AC.ABSORB_DEBUG = false
            print("|cffFFAA00ArenaCore:|r Absorb debug DISABLED")
        end
    elseif msg == "immunity" or msg == "immunities" then
        -- Toggle immunity tracker debug mode
        if AC.ImmunityTracker then
            AC.ImmunityTracker.DEBUG_ENABLED = not AC.ImmunityTracker.DEBUG_ENABLED
            print("|cffFFAA00ArenaCore:|r Immunity debug " .. (AC.ImmunityTracker.DEBUG_ENABLED and "ENABLED" or "DISABLED"))
        else
            print("|cffFF0000ArenaCore:|r ImmunityTracker not available")
        end
    elseif msg == "blackout" then
        -- Toggle blackout system debug mode
        if not AC.BLACKOUT_DEBUG then
            AC.BLACKOUT_DEBUG = true
            print("|cffFFAA00ArenaCore:|r Blackout debug ENABLED")
            print("|cff00FF00[Blackout]|r Will show spell list loading and aura detection")
        else
            AC.BLACKOUT_DEBUG = false
            print("|cffFFAA00ArenaCore:|r Blackout debug DISABLED")
        end
    elseif msg == "tribadges" or msg == "classpacks" or msg == "priority" then
        -- Toggle TriBadges (Class Packs) debug mode
        if not AC.TRIBADGES_DEBUG then
            AC.TRIBADGES_DEBUG = true
            print("|cffFFAA00ArenaCore:|r TriBadges debug ENABLED")
            print("|cff00FF00[TriBadges]|r Will show:")
            print("  - ALL buffs detected on arena units")
            print("  - Priority comparison logic (why each spell wins/loses)")
            print("  - Special Unholy Assault (207289) detection")
            print("  - BBP vs OLD scanning method tracking")
        else
            AC.TRIBADGES_DEBUG = false
            print("|cffFFAA00ArenaCore:|r TriBadges debug DISABLED")
        end
    elseif msg == "all" then
        -- Enable all debug modes
        AC.ABSORB_DEBUG = true
        AC.BLACKOUT_DEBUG = true
        AC.TRIBADGES_DEBUG = true
        if AC.ImmunityTracker then AC.ImmunityTracker.DEBUG_ENABLED = true end
        print("|cffFFAA00ArenaCore:|r ALL debug modes ENABLED")
    elseif msg == "off" or msg == "disable" then
        -- Disable all debug modes
        AC.ABSORB_DEBUG = false
        AC.BLACKOUT_DEBUG = false
        AC.TRIBADGES_DEBUG = false
        if AC.ImmunityTracker then AC.ImmunityTracker.DEBUG_ENABLED = false end
        print("|cffFFAA00ArenaCore:|r ALL debug modes DISABLED")
    elseif msg == "unlock" then
        -- Unlock frames for dragging
        if AC.EnableFrameDragging then
            AC:EnableFrameDragging()
        else
            print("|cffFF0000ArenaCore:|r EnableFrameDragging function not available")
        end
    elseif msg == "lock" then
        -- Lock frames
        if AC.DisableFrameDragging then
            AC:DisableFrameDragging()
        else
            print("|cffFF0000ArenaCore:|r DisableFrameDragging function not available")
        end
    else
        print("|cffFFAA00ArenaCore Debug Commands:|r")
        print("  /acdebug absorb - Toggle absorb debug")
        print("  /acdebug immunity - Toggle immunity debug")
        print("  /acdebug blackout - Toggle blackout debug")
        print("  /acdebug tribadges - Toggle Class Pack priority debug")
        print("  /acdebug all - Enable all debug modes")
        print("  /acdebug off - Disable all debug modes")
        print("  /acdebug unlock - Unlock frames for dragging")
        print("  /acdebug lock - Lock frames")
    end
end

-- Dedicated command to reset ENTIRE theme to new user defaults
SLASH_RESETTHEME1 = "/resettheme"
SLASH_RESETTHEME2 = "/resetarenaframes"
SlashCmdList["RESETTHEME"] = function()
    local AC = _G.ArenaCore
    if not AC then
        print("|cffFF0000ArenaCore:|r Addon not loaded!")
        return
    end
    
    if not AC.DB or not AC.DB.profile then
        print("|cffFF0000ArenaCore:|r Database not available!")
        return
    end
    
    print("|cffFFAA00ArenaCore:|r Resetting ALL arena frame visuals to new user defaults...")
    
    -- Reset Arena Frames positioning
    AC.DB.profile.arenaFrames.positioning.horizontal = 1244
    AC.DB.profile.arenaFrames.positioning.vertical = -253
    AC.DB.profile.arenaFrames.positioning.spacing = 21
    AC.DB.profile.arenaFrames.positioning.growthDirection = "Down"
    
    -- Reset Arena Frames sizing
    AC.DB.profile.arenaFrames.sizing.scale = 121
    AC.DB.profile.arenaFrames.sizing.width = 235
    AC.DB.profile.arenaFrames.sizing.height = 68
    
    -- Reset Arena Frames general settings
    AC.DB.profile.arenaFrames.general.showArenaNumbers = true
    AC.DB.profile.arenaFrames.general.playerNameScale = 86
    AC.DB.profile.arenaFrames.general.arenaNumberScale = 119
    AC.DB.profile.arenaFrames.general.resourceTextScale = 83
    AC.DB.profile.arenaFrames.general.spellTextScale = 113
    AC.DB.profile.arenaFrames.general.playerNameX = 52
    AC.DB.profile.arenaFrames.general.playerNameY = 0
    AC.DB.profile.arenaFrames.general.arenaNumberX = 190
    AC.DB.profile.arenaFrames.general.arenaNumberY = -3
    
    -- Reset Cast Bars
    AC.DB.profile.castBars.positioning.horizontal = 2
    AC.DB.profile.castBars.positioning.vertical = -82
    AC.DB.profile.castBars.sizing.scale = 86
    AC.DB.profile.castBars.sizing.width = 227
    AC.DB.profile.castBars.sizing.height = 18
    AC.DB.profile.castBars.spellIcons.scale = 101
    AC.DB.profile.castBars.spellIcons.enabled = true
    
    -- Reset Trinkets
    AC.DB.profile.trinkets.positioning.vertical = -20
    AC.DB.profile.trinkets.positioning.horizontal = 0
    AC.DB.profile.trinkets.sizing.scale = 100
    AC.DB.profile.trinkets.sizing.fontSize = 10
    
    -- Reset Racials
    AC.DB.profile.racials.positioning.vertical = 20
    AC.DB.profile.racials.positioning.horizontal = 0
    AC.DB.profile.racials.sizing.scale = 100
    AC.DB.profile.racials.sizing.fontSize = 10
    
    -- Reset Spec Icons
    AC.DB.profile.specIcons.positioning.vertical = 0
    AC.DB.profile.specIcons.positioning.horizontal = -20
    AC.DB.profile.specIcons.sizing.scale = 100
    
    -- Reset Class Icons
    AC.DB.profile.classIcons.positioning.vertical = 7
    AC.DB.profile.classIcons.positioning.horizontal = -2
    AC.DB.profile.classIcons.sizing.scale = 109
    
    -- Reset Textures
    AC.DB.profile.textures.positioning.horizontal = 56
    AC.DB.profile.textures.positioning.vertical = 16
    AC.DB.profile.textures.positioning.spacing = 2
    
    -- Reset DR positioning
    AC.DB.profile.diminishingReturns.positioning.horizontal = 236
    AC.DB.profile.diminishingReturns.positioning.vertical = 0
    AC.DB.profile.diminishingReturns.positioning.spacing = 3
    AC.DB.profile.diminishingReturns.sizing.size = 33
    
    -- Force refresh everything
    if AC.RefreshArenaFramesLayout then AC:RefreshArenaFramesLayout() end
    if AC.RefreshCastBarsLayout then AC:RefreshCastBarsLayout() end
    if AC.RefreshTrinketsOtherLayout then AC:RefreshTrinketsOtherLayout() end
    if AC.RefreshDRLayout then AC:RefreshDRLayout() end
    if AC.RefreshTexturesLayout then AC:RefreshTexturesLayout() end
    if AC.UpdateFramePositions then AC:UpdateFramePositions() end
    
    print("|cff00FF00ArenaCore:|r ALL arena frame visuals reset to new user defaults!")
    print("|cff00FF00Success!|r Use Test Mode to verify - everything should look like a fresh install")
end

-- Slash commands for ArenaCore
SLASH_ARENACORE1 = "/arena"
SLASH_ARENACORE2 = "/arenacore"
SLASH_ARENACORE3 = "/ac"
SlashCmdList["ARENACORE"] = function(msg)
    local AC = _G.ArenaCore  -- Get global ArenaCore reference
    if not AC then
        print("|cffFF0000ArenaCore:|r Addon not loaded!")
        return
    end
    
    -- Trim spaces manually (WoW Lua doesn't have :trim())
    msg = msg:match("^%s*(.-)%s*$"):lower()
    
    -- DEBUG: Show what command was received
    print("|cffFFAA00[DEBUG]|r Received command: '" .. msg .. "' (length: " .. #msg .. ")")
    
    if msg == "test" then
        if AC.testModeEnabled then
            AC:HideTestFrames()
        else
            AC:ShowTestFrames()
        end
    elseif msg == "show" then
        AC:ShowArenaFrames()
    elseif msg == "hide" then
        AC:HideArenaFrames()
    elseif msg == "config" then
        if AC.OpenConfigFrame then
            AC:OpenConfigFrame()
        else
            print("ArenaCore: Config frame not available")
        end
    elseif msg == "reset" then
        AC:ResetAllFrames()
    elseif msg == "betapreset" or msg == "preset" then
        print("|cffFFAA00[DEBUG]|r Slash command 'betapreset' detected, calling AC:ApplyBetaPreset()")
        AC:ApplyBetaPreset()
    elseif msg == "resetdefaults" or msg == "resetall" then
        AC:ResetToDefaults()
    elseif msg == "addblackoutspells" or msg == "blackoutspells" then
        AC:AddDefaultBlackoutSpells()
    elseif msg == "exportblackout" or msg == "blackoutexport" then
        AC:ExportBlackoutToDefaults()
    elseif msg == "tickers" or msg == "checktickers" then
        -- PHASE 1.2: Check active tickers
        AC:CheckActiveTickers()
    elseif msg == "events" or msg == "checkevents" then
        -- PHASE 2.3: Check active event frames
        AC:CheckActiveEventFrames()
    elseif msg == "cleanup" then
        -- PHASE 2.3: Manual cleanup
        AC:Cleanup()
    elseif msg == "cache" or msg == "refreshcache" then
        -- PHASE 3.2: Refresh settings cache
        AC:RefreshSettingsCache()
        local count = AC:CountCachedSettings()
        print("|cff00FF00[ArenaCore]|r Settings cache refreshed! (" .. count .. " settings cached)")
    -- REMOVED: blackoutdebug command - backend removed, will be rebuilt
    elseif msg == "immunitydebug" or msg == "debugimmunity" then
        -- Toggle immunity tracker debug mode
        if AC.ImmunityTracker then
            AC.ImmunityTracker.DEBUG_ENABLED = not AC.ImmunityTracker.DEBUG_ENABLED
            print("|cffFFAA00ArenaCore:|r Immunity debug " .. (AC.ImmunityTracker.DEBUG_ENABLED and "ENABLED" or "DISABLED"))
        else
            print("|cffFF0000ArenaCore:|r ImmunityTracker not available")
        end
    elseif msg == "absorbdebug" or msg == "debugabsorb" then
        -- Toggle absorb system debug mode
        if not AC.ABSORB_DEBUG then
            AC.ABSORB_DEBUG = true
            print("|cffFFAA00ArenaCore:|r Absorb debug ENABLED")
            print("|cff00FF00[AbsorbDebug]|r Will show detailed absorb detection and display info")
        else
            AC.ABSORB_DEBUG = false
            print("|cffFFAA00ArenaCore:|r Absorb debug DISABLED")
        end
    elseif msg == "checknames" or msg == "namepos" then
        -- Check current player name position values in database
        local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
        if general then
            print("|cffFFAA00[NAME POS CHECK]|r Current database values:")
            print(string.format("  playerNameX = %s (type: %s)", tostring(general.playerNameX), type(general.playerNameX)))
            print(string.format("  playerNameY = %s (type: %s)", tostring(general.playerNameY), type(general.playerNameY)))
            print(string.format("  arenaNumberX = %s (type: %s)", tostring(general.arenaNumberX), type(general.arenaNumberX)))
            print(string.format("  arenaNumberY = %s (type: %s)", tostring(general.arenaNumberY), type(general.arenaNumberY)))
        else
            print("|cffFF0000[NAME POS CHECK]|r No general settings found!")
        end
    elseif msg == "blackoutdebug" or msg == "debugblackout" then
        -- Toggle blackout system debug mode
        if not AC.BLACKOUT_DEBUG then
            AC.BLACKOUT_DEBUG = true
            print("|cffFFAA00ArenaCore:|r Blackout debug ENABLED")
            print("|cff00FF00[Blackout]|r Will show spell list loading and aura detection")
        else
            AC.BLACKOUT_DEBUG = false
            print("|cffFFAA00ArenaCore:|r Blackout debug DISABLED")
        end
    elseif msg == "reset1500" or msg == "reset1500special" then
        -- Reset The 1500 Special theme class icon positioning to defaults
        if AC.DB and AC.DB.profile and AC.DB.profile.classIcons then
            AC.DB.profile.classIcons.positioning.horizontal = -2
            AC.DB.profile.classIcons.positioning.vertical = 7
            
            -- Also refresh the layout
            if AC.RefreshTrinketsOtherLayout then
                AC:RefreshTrinketsOtherLayout()
            end
            
            print("|cff8B45FFArenaCore:|r Reset class icon positioning to defaults:")
            print("  Horizontal: -2")
            print("  Vertical: 7")
            print("|cff00FF00Tip:|r Use Test Mode to verify positioning")
        else
            print("|cffFF0000ArenaCore:|r Database not available!")
        end
    elseif msg == "tribadgesdebug" or msg == "debugtribadges" or msg == "classpacksdebug" then
        -- Toggle TriBadges (Class Packs) debug mode
        if not AC.TRIBADGES_DEBUG then
            AC.TRIBADGES_DEBUG = true
            print("|cffFFAA00ArenaCore:|r TriBadges debug ENABLED")
            print("|cff00FF00[TriBadges]|r Will show which method (BBP/OLD) detects each spell")
        else
            AC.TRIBADGES_DEBUG = false
            print("|cffFFAA00ArenaCore:|r TriBadges debug DISABLED")
        end
    elseif msg == "help" then
        print("|cffFFAA00ArenaCore Commands:|r")
        print("  /arena - Open ArenaCore configuration")
        print("  /ac test - Toggle test mode")
        print("  /ac show - Show arena frames")
        print("  /ac hide - Hide arena frames")
        print("  /ac config - Open configuration")
        print("  /ac reset - Reset all frames")
        print("  /ac tickers - Check active tickers (Phase 1.2)")
        print("  /ac events - Check active event frames (Phase 2.3)")
        print("  /ac cleanup - Manual cleanup (tickers + events)")
        print("  /ac cache - Refresh settings cache (Phase 3.2)")
        print("  ")
        print("|cff8B45FFTheme Commands:|r")
        print("  /actheme - List available themes")
        print("  /actheme [name] - Switch to theme")
        print("  /actheme_export - Export current theme settings")
        print("  /actheme_reset - Reset current theme to defaults")
        print("  ")
        print("|cffFFAA00Debug Commands:|r (Use /acdebug to avoid UI conflict)")
        print("  /acdebug absorb - Toggle absorb debug")
        print("  /acdebug immunity - Toggle immunity debug")
        print("  /acdebug blackout - Toggle blackout debug")
        print("  /acdebug all - Enable all debug modes")
        print("  ")
        print("  /ac betapreset - Apply beta tester preset (your defaults)")
        print("  /ac addblackoutspells - Add default Blackout spells to your list")
        print("  /ac exportblackout - Export your Blackout spells to become defaults")
        print("  /ac resetdefaults - Hard reset to defaults")
        print("  /ac help - Show this help")
    else
        -- Temporarily disabled config panel due to UI consolidation
        print("|cffFFAA00ArenaCore:|r Available commands:")
        print("  /ac test - Toggle test mode")
        print("  /ac show - Show arena frames") 
        print("  /ac hide - Hide arena frames")
        print("  /ac help - Show all commands")
        print("|cffFFCC00Note:|r Config UI being updated for consolidated files")
    end
end

-- ============================================================================
-- GLOBAL EVENT FRAME SETUP
-- ============================================================================

-- Create global event frame for system initialization
local ArenaCore_InitFrame = CreateFrame("Frame", "ArenaCore_InitializationFrame", UIParent)
ArenaCore_InitFrame:RegisterEvent("ADDON_LOADED")
ArenaCore_InitFrame:RegisterEvent("PLAYER_LOGIN")
ArenaCore_InitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Main initialization event handler
ArenaCore_InitFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "ArenaCore" then
            -- DEBUG: Addon loaded
            -- print("|cffFFAA00ArenaCore:|r Addon loaded, initializing database...")
            
            -- Initialize database first
            AC:EnsureDB()
            
            -- PHASE 3.2: Initialize settings cache
            AC:RefreshSettingsCache()
            
            -- Initialize icon styling system
            if AC.IconStyling then
                -- DEBUG: Icon styling system initialized
                -- print("|cffFFAA00ArenaCore:|r Icon styling system initialized")
            end
            
            -- Initialize DR system
            if InitializeDRSystem and InitializeDRSystem() then
                -- DEBUG: DR system initialized
                -- print("|cffFFAA00ArenaCore:|r DR system initialized")
            end
            
            -- NOTE: Module initialization happens in Core.lua via AC:_EnableModules() on PLAYER_LOGIN
            -- Don't duplicate it here - let the proper system handle it
            
            -- Mark addon as loaded
            AC.addonLoaded = true
        end
        
    elseif event == "PLAYER_LOGIN" then
        -- DEBUG: Player logged in
        -- print("|cffFFAA00ArenaCore:|r Player logged in, initializing frame systems...")
        
        -- CRITICAL: Register slash commands on PLAYER_LOGIN to override any conflicts
        C_Timer.After(0.5, function()
            SLASH_ARENACORE1 = "/arena"
            SLASH_ARENACORE2 = "/arenacore"
            SLASH_ARENACORE3 = "/ac"
            -- Force re-register the handler
            SlashCmdList["ARENACORE"] = SlashCmdList["ARENACORE"]
            -- HIDDEN: Slash commands register silently for cleaner user experience
            -- print("|cffFFAA00[DEBUG]|r ArenaCore slash commands registered!")
        end)
        
        -- Initialize Master Frame Manager if not already done
        if MFM and not MFM.frames[1] then
            MFM:Initialize()
        end
        
        -- Initialize FrameManager if available
        if AC.FrameManager and AC.FrameManager.Initialize then
            AC.FrameManager:Initialize()
        end
        
        -- Initialize TriBadges system if available
        if AC.TriBadges and AC.TriBadges.Initialize then
            AC.TriBadges:Initialize()
        end
        
        -- Register for trinket icon refreshes
        if AC.RefreshTrinketIcons then
            -- Refresh trinket icons with current settings
            C_Timer.After(1, function()
                AC:RefreshTrinketIcons()
            end)
        end
        
        -- CRITICAL: Apply /gg surrender command if enabled
        if AC.MoreFeatures and AC.MoreFeatures.ApplySurrenderSetting then
            AC.MoreFeatures:ApplySurrenderSetting()
        end
        
        -- DEBUG: Systems initialized
        -- print("|cffFFAA00ArenaCore:|r Systems initialized successfully")
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        
        if isInitialLogin or isReloadingUi then
            -- Simple arena state check
            -- No special reload handling, no caching, no complex flags
            local _, instanceType = IsInInstance()
            
            if instanceType == "arena" then
                -- IN ARENA (prep room or live): Update visibility and data only
                print("|cffFFAA00ArenaCore:|r Reload in arena detected - updating data without resizing")
                
                -- Update visibility (show/hide frames based on opponent count)
                if MFM and MFM.UpdateVisible then
                    MFM:UpdateVisible()
                end
                
                -- Update unit data without resizing
                C_Timer.After(0.5, function()
                    if MFM and MFM.UpdateArenaData then
                        MFM:UpdateArenaData()
                    end
                end)
                
                -- Reset component states (trinkets, racials, DRs)
                C_Timer.After(0.7, function()
                    for i = 1, MAX_ARENA_ENEMIES do
                        local unit = "arena" .. i
                        if UnitExists(unit) then
                            -- Reset trinket cooldown display
                            if AC.TrinketTracker and AC.TrinketTracker.ResetTrinket then
                                AC.TrinketTracker:ResetTrinket(unit)
                            end
                            
                            -- Reset DR icons
                            local drModule = GetDRModule()
                            if drModule and drModule.ResetFrame and MFM.frames[i] then
                                drModule:ResetFrame(MFM.frames[i])
                            end
                        end
                    end
                end)
            else
                -- NOT IN ARENA: Normal initialization
                C_Timer.After(1, function()
                    if MFM and MFM.CheckArenaState then
                        MFM:CheckArenaState()
                    end
                end)
            end
        end
    end
end)

-- ============================================================================
-- CONSOLIDATION: SECOND OLD SYSTEM REMOVED (Lines 9295-9410)
-- ============================================================================
-- This was the SECOND duplicate arenaEventFrame - also deleted!
-- ALL arena event handling is now in ONE place: MFM (MasterFrameManager)
-- See lines 2644-3078 for the consolidated system.
-- ============================================================================

-- ============================================================================
-- ARENA TRACKING CONTAINER SETUP
-- ============================================================================

-- Initialize ArenaTracking container
local ArenaTracking = CreateFrame("Frame", "ArenaCore_ArenaTrackingContainer", UIParent)
AC.ArenaTracking = ArenaTracking

-- PHASE 2.3: Register main event frame for cleanup
AC:RegisterEventFrame(ArenaTracking, "ArenaTracking_Main")

-- ============================================================================
-- PHASE 1.1: CENTRALIZED COMBAT_LOG HANDLER
-- Consolidates 4 separate COMBAT_LOG registrations into one efficient system
-- Performance gain: 60-75% reduction in COMBAT_LOG processing overhead
-- ============================================================================

local function ProcessCentralizedCombatLog()
    local timestamp, combatEvent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Early exit for irrelevant events
    if not combatEvent then return end
    
    -- ========================================================================
    -- DELEGATION TO SUBSYSTEMS (each processes only what it needs)
    -- ========================================================================
    
    -- 1. AuraTracker: Interrupts (SPELL_INTERRUPT, SPELL_CAST_SUCCESS)
    if (combatEvent == "SPELL_INTERRUPT" or combatEvent == "SPELL_CAST_SUCCESS") then
        if AC.AuraTracker and AC.AuraTracker.ProcessCombatLogEvent then
            AC.AuraTracker:ProcessCombatLogEvent(timestamp, combatEvent, sourceGUID, destGUID, spellID)
        end
    end
    
    -- 2. DispelTracker: Dispels (SPELL_CAST_SUCCESS, SPELL_DISPEL)
    if (combatEvent == "SPELL_CAST_SUCCESS" or combatEvent == "SPELL_DISPEL") then
        if AC.DispelTracker and AC.DispelTracker.ProcessCombatLogEvent then
            AC.DispelTracker.ProcessCombatLogEvent(timestamp, combatEvent, sourceGUID, destGUID, spellID)
        end
    end
    
    -- 3. FeignDeathDetector: Death events (UNIT_DIED, UNIT_DESTROYED)
    if (combatEvent == "UNIT_DIED" or combatEvent == "UNIT_DESTROYED") then
        if AC.FeignDeathDetector and AC.FeignDeathDetector.ProcessCombatLogEvent then
            AC.FeignDeathDetector:ProcessCombatLogEvent(timestamp, combatEvent, sourceGUID, destGUID, spellID)
        end
    end
    
    -- 4. KickBar: Interrupt cooldown tracking (SPELL_CAST_SUCCESS)
    if combatEvent == "SPELL_CAST_SUCCESS" then
        if AC.KickBar and AC.KickBar.ProcessCombatLogEvent then
            AC.KickBar:ProcessCombatLogEvent(timestamp, combatEvent, sourceGUID, sourceName, sourceFlags, destGUID, spellID)
        end
    end
    
    -- 5. TrinketsRacials: Racial cooldown tracking via combat log (SPELL_CAST_SUCCESS)
    -- Trinkets are handled via ARENA_COOLDOWNS_UPDATE API events
    if combatEvent == "SPELL_CAST_SUCCESS" then
        if AC.TrinketsRacials and AC.TrinketsRacials.OnCombatLogSpell then
            AC.TrinketsRacials:OnCombatLogSpell(sourceGUID, spellID)
        end
    end
    
    -- 6. Main System: FrameManager for DR tracking and other systems
    if AC.FrameManager and AC.FrameManager.HandleCombatLogEvent then
        AC.FrameManager:HandleCombatLogEvent()
    end
end

-- Delay event registration to avoid taint warnings in Midnight
C_Timer.After(0.1, function()
    local AC = _G.ArenaCore
    
    -- MIDNIGHT: Skip non-essential event registration to minimize taint warnings
    if AC and AC.Midnight and AC.Midnight.isMidnight then
        -- Only register absolutely essential events in Midnight
        ArenaTracking:RegisterEvent("ADDON_LOADED")
        ArenaTracking:RegisterEvent("PLAYER_LOGOUT")
        return
    end
    
    -- Register events for ArenaTracking (non-Midnight)
    ArenaTracking:RegisterEvent("ADDON_LOADED")
    ArenaTracking:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- PHASE 1.1: Now centralized
    ArenaTracking:RegisterEvent("PLAYER_LOGOUT")
    -- Power events for mana/energy/rage percentage
    ArenaTracking:RegisterUnitEvent("UNIT_POWER_FREQUENT", "arena1", "arena2", "arena3")
    ArenaTracking:RegisterUnitEvent("UNIT_DISPLAYPOWER", "arena1", "arena2", "arena3")
    -- Spell cast events for trinkets and racials
    ArenaTracking:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "arena1", "arena2", "arena3")
    -- Cast bar events for all arena units
    ArenaTracking:RegisterUnitEvent("UNIT_SPELLCAST_START", "arena1", "arena2", "arena3")
    ArenaTracking:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "arena1", "arena2", "arena3")
    ArenaTracking:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "arena1", "arena2", "arena3")
    ArenaTracking:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "arena1", "arena2", "arena3")
    ArenaTracking:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "arena1", "arena2", "arena3")
    ArenaTracking:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "arena1", "arena2", "arena3")
end)
-- CRITICAL: Evoker empowered spells (Spirit Bloom, Fire Breath, etc.)
--- REMOVED: UNIT_AURA, UNIT_ABSORB events now handled by MFM individual frames (lines 2308-2310)
--- This prevents duplicate event handling and ensures proper frame-specific updates
-- ArenaTracking:RegisterUnitEvent("UNIT_AURA", "arena1", "arena2", "arena3")
-- ArenaTracking:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "arena1", "arena2", "arena3")
-- ArenaTracking:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "arena1", "arena2", "arena3")

--- ArenaTracking event handler
ArenaTracking:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local addonName = ...
        if addonName == "ArenaCore" then
            AC:EnsureDB()
        end
        
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        -- PHASE 1.1: Use centralized COMBAT_LOG handler
        ProcessCentralizedCombatLog()
        
    elseif event == "UNIT_POWER_FREQUENT" or event == "UNIT_DISPLAYPOWER" then
        local unit = ...
        if unit and string.match(unit, "^arena%d$") and not AC.testModeEnabled then
            local arenaIndex = tonumber(string.match(unit, "^arena(%d)$"))
            local arenaFrames = GetArenaFrames()
            if arenaIndex and arenaFrames and arenaFrames[arenaIndex] then
                -- Update power bars
                if UpdateFrameBars then
                    UpdateFrameBars(arenaFrames[arenaIndex], unit)
                end
            end
        end
        
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Racial tracking via unit spellcast (trinkets use API events)
        if AC.TrinketsRacials and AC.TrinketsRacials.OnUnitSpellCast then
            local unit, _, spellID = ...
            AC.TrinketsRacials:OnUnitSpellCast(unit, spellID)
        end
        
    elseif event:match("^UNIT_SPELLCAST") then
        local unit = ...
        -- Cast bar event
        if unit and string.match(unit, "^arena%d$") and not AC.testModeEnabled then
            local arenaIndex = tonumber(string.match(unit, "^arena(%d)$"))
            local arenaFrames = GetArenaFrames()
            -- Arena index check
            if arenaIndex and arenaFrames and arenaFrames[arenaIndex] then
                -- Handle cast bar updates through FrameManager
                if AC.FrameManager then
                    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
                        -- Update cast bar
                        if AC.FrameManager.UpdateCastBar then
                            AC.FrameManager:UpdateCastBar(arenaFrames[arenaIndex], unit, event)
                        end
                    else
                        -- Hide cast bar
                        if AC.FrameManager.HideCastBar then
                            AC.FrameManager:HideCastBar(arenaFrames[arenaIndex])
                        end
                    end
                end
            end
        end
        
    -- REMOVED: UNIT_AURA and UNIT_ABSORB handlers - now handled by MFM individual frames (lines 2344-2351)
    -- This prevents duplicate event handling and ensures proper frame-specific updates
    -- Debuffs, AuraTracker, Absorbs, and Immunities are all updated via MFM:HandleFrameEvent
    
    elseif event == "UNIT_AURA" then
        -- LEGACY: Keep debuff and aura tracker calls for compatibility
        local unit = ...
        local _, instanceType = IsInInstance()
        
        if instanceType == "arena" and unit and unit:match("^arena%d$") and not AC.testModeEnabled then
            -- CRITICAL: Call debuff module directly (still needed for compatibility)
            local arenaIndex = tonumber(unit:match("^arena(%d)$"))
            local arenaFrames = GetArenaFrames()
            
            if arenaIndex and arenaFrames and arenaFrames[arenaIndex] then
                local frame = arenaFrames[arenaIndex]
                
                local debuffModule = GetDebuffModule()
                if debuffModule and debuffModule.Update then
                    debuffModule:Update(frame, unit)
                end
                
                -- Update auras via AuraTracker system if available
                if AC.AuraTracker and AC.AuraTracker.UpdateAuras then
                    AC.AuraTracker:UpdateAuras(unit)
                end
                
                -- NOTE: Absorbs and Immunities now handled by MFM (lines 2346-2351)
            end
        end
        
    elseif event == "PLAYER_LOGOUT" then
        -- PHASE 2.3: Comprehensive cleanup on logout
        AC:Cleanup()
    end
end)
-- ============================================================================
-- INTEGRATION WITH EXISTING SYSTEMS
-- ============================================================================

-- REMOVED: Duplicate/conflicting test mode functions
-- ============================================================================
-- AUTO-INITIALIZATION AND STARTUP
-- ============================================================================

-- Auto-initialize on file load
-- DEBUG: Master System loaded
-- print("|cffFFAA00ArenaCore Master System:|r Loaded - use /acmaster test")
-- print("|cffFFAA00ArenaCore Master System:|r Will auto-initialize on PLAYER_LOGIN")

-- For immediate testing, initialize right away if possible
if IsLoggedIn() then
    -- DEBUG: Player already logged in
    -- print("|cffFFAA00ArenaCore Master System:|r Player already logged in - initializing immediately")
    C_Timer.After(1, function()
        AC.InitMasterSystem()
    end)
end
function AC.InitMasterSystem()
    if not MFM.frames[1] then
        MFM:Initialize()
        return true
    end
    return false
end

-- ============================================================================
-- MODULE INITIALIZATION CALLS
-- ============================================================================

-- Initialize all available modules
local function InitializeAllModules()
    -- Initialize Master Frame Manager
    if MFM and not MFM.initialized then
        MFM:Initialize()
        MFM.initialized = true
    end
    
    -- Initialize FrameManager if available
    if AC.FrameManager and not AC.FrameManager.initialized then
        if AC.FrameManager.Initialize then
            AC.FrameManager:Initialize()
        end
        AC.FrameManager.initialized = true
    end
    
    -- Initialize TriBadges if available
    if AC.TriBadges and not AC.TriBadges.initialized then
        if AC.TriBadges.Initialize then
            AC.TriBadges:Initialize()
        end
        AC.TriBadges.initialized = true
    end
    
    -- Initialize AuraTracker if available
    if AC.AuraTracker and not AC.AuraTracker.initialized then
        if AC.AuraTracker.Initialize then
            AC.AuraTracker:Initialize()
        end
        AC.AuraTracker.initialized = true
    end
    
    -- Initialize DispelTracker if available
    if AC.DispelTracker and not AC.DispelTracker.initialized then
        if AC.DispelTracker.Initialize then
            AC.DispelTracker:Initialize()
        end
        AC.DispelTracker.initialized = true
    end
    
    -- CRITICAL FIX: Initialize KickBar if available
    if AC.KickBar and not AC.KickBar.initialized then
        if AC.KickBar.Initialize then
            AC.KickBar:Initialize()
        end
        AC.KickBar.initialized = true
    end
    
    -- DEBUG: Modules initialized
    -- print("|cffAAFFAA[SUCCESS]|r All ArenaCore modules initialized")
end

-- Schedule module initialization
C_Timer.After(3, InitializeAllModules)

-- ============================================================================
-- FINAL SYSTEM VALIDATION
-- ============================================================================

-- Final validation function to ensure everything is working
local function PerformSystemValidation()
    local issues = {}
    
    -- Check Master Frame Manager
    if not MFM or not MFM.frames then
        table.insert(issues, "Master Frame Manager not available")
    elseif not MFM.frames[1] then
        table.insert(issues, "Master Frame Manager frames not created")
    end
    
    -- Check database
    if not AC.DB or not AC.DB.profile then
        table.insert(issues, "Database not initialized")
    end
    
    -- Check slash commands
    if not SlashCmdList["ARENAMASTERCORE"] then
        table.insert(issues, "Master slash commands not registered")
    end
    
    -- Check event frames
    if not ArenaCore_InitFrame then
        table.insert(issues, "Initialization event frame not created")
    end
    
    if not ArenaTracking then
        table.insert(issues, "ArenaTracking event frame not created")
    end
    
    -- Report validation results
    if #issues > 0 then
        print("|cffFF6B6BArenaCore System Validation:|r Issues found:")
        for _, issue in ipairs(issues) do
            print("  - " .. issue)
        end
    else
        -- DEBUG: System validation passed
        -- print("|cffAAFFAA[SUCCESS]|r ArenaCore system validation passed!")
        -- print("|cffAAFFAA[SUCCESS]|r All systems operational and ready!")
    end
end

-- Schedule final validation
C_Timer.After(5, PerformSystemValidation)

-- ============================================================================
-- FRAME PERSISTENCE PREVENTION SYSTEM
-- ============================================================================
-- Periodic check to ensure frames don't persist outside arena
-- This is a failsafe against the random frame persistence bug

local function PreventFramePersistence()
    if not MFM or not MFM.frames then return end
    
    local _, instanceType = IsInInstance()
    
    -- Only check when NOT in arena and NOT in test mode
    if instanceType ~= "arena" and not (MFM.isTestMode or false) then
        local foundVisibleFrame = false
        
        for i = 1, MAX_ARENA_ENEMIES do
            if MFM.frames[i] and MFM.frames[i]:IsShown() then
                foundVisibleFrame = true
                -- DEBUG DISABLED FOR PRODUCTION
                -- print("|cffFF0000[PERSISTENCE BUG]|r Frame " .. i .. " persisting outside arena - auto-fixing!")
                
                -- Force hide the frame (use pcall to catch forbidden table errors)
                pcall(function()
                    MFM.frames[i]:Hide()
                end)
                MFM.frames[i]:SetAlpha(1)
                
                -- Clear all visibility flags
                MFM.frames[i].isVisible = false
                MFM.frames[i].hasEverHadData = false
            end
        end
        
        -- DEBUG DISABLED FOR PRODUCTION
        -- if foundVisibleFrame then
        --     print("|cffFF6B6B[AUTO-FIX]|r Frame persistence bug detected and fixed automatically")
        -- end
    end
end

-- Run the check every 3 seconds (low overhead, catches persistence bugs)
C_Timer.NewTicker(3, PreventFramePersistence)

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

-- ============================================================================
-- UI SYSTEM INTEGRATION - Connect Core/UI.lua to Master System
-- ============================================================================

-- Note: AC:OpenConfigPanel() is defined in Core/UI.lua, not here.
-- This ensures Core/UI.lua slash commands work properly.

-- ============================================================================
-- MASTER SYSTEM UI BRIDGE FUNCTIONS
-- ============================================================================

-- Bridge function for UI pages to control Master Frame Manager
function AC:ShowTestFrames()
    if MFM and MFM.EnableTestMode then
        -- CRITICAL FIX: Clear stale aura data BEFORE enabling test mode frames
        -- This prevents real arena auras from persisting into test mode
        if AC.AuraTracker and AC.AuraTracker.EnableTestMode then
            AC.AuraTracker:EnableTestMode()
        end
        
        -- Now enable test mode frames (which will apply test data)
        MFM:EnableTestMode()
        
        return true
    end
    print("|cffFF6B6BArenaCore:|r Master Frame Manager not available!")
    return false
end

function AC:HideTestFrames()
    if MFM and MFM.DisableTestMode then
        MFM:DisableTestMode()
        
        -- CRITICAL: Disable aura tracking test mode
        if AC.AuraTracker and AC.AuraTracker.DisableTestMode then
            AC.AuraTracker:DisableTestMode()
        end
        
        -- CRITICAL: Hide immunity glows when exiting test mode
        if AC.ImmunityTracker and AC.ImmunityTracker.HideAll then
            AC.ImmunityTracker:HideAll()
        end
        
        -- CRITICAL: Hide test mode target border to prevent leaking into prep room
        AC:HideTestModeBorder()
        
        return true
    end
    print("|cffFF6B6BArenaCore:|r Master Frame Manager not available!")
    return false
end

-- Bridge function to get test mode status
function AC:IsTestModeEnabled()
    return MFM and MFM.isTestMode or false
end

-- Bridge function for UI sliders to update frame positioning
function AC:UpdateFramePositioning()
    if MFM and MFM.UpdateFramePositions then
        MFM:UpdateFramePositions()
    elseif self.UpdateFramePositions then
        self:UpdateFramePositions()
    end
end


-- DEBUG: Master System fully loaded
-- print("|cffAAFFAA=== ArenaCore Master System Fully Loaded ===|r")
-- print("|cffAAFFAAAll 12 chunks successfully integrated!|r")
-- print("|cffAAFFAAUI Bridge functions added for /arena command|r")
-- print("|cffAAFFAAUse /arena to open config or /acmaster for commands|r")
-- DEBUG: Separator line
-- print("|cffAAFFAA=======================================|r")
