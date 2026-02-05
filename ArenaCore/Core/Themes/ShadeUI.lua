-- =============================================================================
-- Core/Themes/ShadeUI.lua - Shade UI Theme Module
-- =============================================================================

local AddonName, _ns = ...
if type(_G.ArenaCore) ~= "table" then _G.ArenaCore = {} end
local AC = _G.ArenaCore

-- Initialize theme registry if it doesn't exist
AC.Themes = AC.Themes or {}

-- ====== SHADE UI THEME DEFINITION ======
AC.Themes.shade_ui = {
    name = "Shade UI",
    
    -- Layout configuration
    layout = {
        UI_WIDTH = 700,
        UI_HEIGHT = 550,
        HEADER_HEIGHT = 40,
        SIDEBAR_WIDTH = 180,  -- Increased to give buttons breathing room
        SIDEBAR_HEIGHT = 410,
        CONTENT_WIDTH = 485,  -- Adjusted: 700 - 180 - 15 - 20 = 485
        CONTENT_HEIGHT = 410,
        PADDING = 15,
        NAV_BUTTON_WIDTH = 150,  -- Keep at 150px so buttons have 15px margin on each side in 180px sidebar
        NAV_BUTTON_HEIGHT = 40,
        NAV_BUTTON_SPACING = 40,  -- Reduced from 42 to fit new Frames button
        NAV_FIRST_OFFSET = -35,
        BOTTOM_BAR_HEIGHT = 45,
        TITLE_FONT_SIZE = 18,
        SUBTITLE_FONT_SIZE = 10,
        NAV_FONT_SIZE = 12,
        NAV_ICON_SIZE = 24,
        HAS_BOTTOM_BAR = false,  -- Disabled per user request
        SIDEBAR_TOP_OFFSET = -55,
        CONTENT_TOP_OFFSET = -55,
        VANITY_FOOTER_HEIGHT = 28,
    },
    
    -- Color palette
    colors = {
        BACKGROUND_DARK = {0.05, 0.05, 0.05, 0.95},
        BACKGROUND_MEDIUM = {0.08, 0.08, 0.08, 0.9},
        BACKGROUND_LIGHT = {0.1, 0.1, 0.1, 0.9},
        BORDER_DARK = {0.15, 0.15, 0.15, 1},
        BUTTON_NORMAL = {0.1, 0.1, 0.1, 0.9},
        BUTTON_HOVER = {0.15, 0.15, 0.15, 0.95},
        BUTTON_ACTIVE = {0.2, 0.1, 0.25, 0.9},  -- Purple tint
        TEXT_PRIMARY = {1, 1, 1, 1},
        TEXT_SECONDARY = {0.6, 0.6, 0.6, 1},
        ACCENT_PURPLE = {0.6, 0.4, 0.8, 1},
    },
    
    -- Header customization
    CreateHeader = function(self, parent, layout)
        local header = CreateFrame("Frame", nil, parent)
        header:SetPoint("TOPLEFT", layout.PADDING, -layout.PADDING)
        header:SetPoint("TOPRIGHT", -layout.PADDING, -layout.PADDING)
        header:SetHeight(layout.HEADER_HEIGHT)
        
        -- Dark background
        local headerBg = AC:CreateFlatTexture(header, "BACKGROUND", 1, {0.05, 0.05, 0.05, 0.95}, 1)
        headerBg:SetAllPoints()
        
        -- Title text (centered)
        local title = AC:CreateStyledText(header, "ARENA CORE", 16, AC.COLORS.TEXT, "OVERLAY", "")
        title:SetPoint("TOP", 0, -8)
        
        -- Subtitle text
        local subtitle = AC:CreateStyledText(header, "the ultimate PvP addon", 9, self.colors.ACCENT_PURPLE, "OVERLAY", "")
        subtitle:SetPoint("TOP", 0, -24)
        
        return header
    end,
    
    -- Sidebar customization
    CreateSidebar = function(self, parent, layout)
        local sidebar = AC:CreateShadeFrame(parent, layout.SIDEBAR_WIDTH, layout.SIDEBAR_HEIGHT,
            self.colors.BACKGROUND_MEDIUM,
            self.colors.BORDER_DARK
        )
        sidebar:SetPoint("TOPLEFT", layout.PADDING, layout.SIDEBAR_TOP_OFFSET)
        
        -- Apply horizontal gradient
        AC:ApplyShadeGradient(sidebar, "HORIZONTAL",
            {0.1, 0.1, 0.1, 0.9},   -- Lighter on left
            {0.06, 0.06, 0.06, 0.9} -- Darker on right
        )
        
        return sidebar
    end,
    
    -- Content area customization
    CreateContentArea = function(self, parent, layout)
        local content = CreateFrame("ScrollFrame", nil, parent)
        -- Move content LEFT - close gap with sidebar (just 2px gap instead of 25+px)
        content:SetPoint("TOPLEFT", layout.SIDEBAR_WIDTH + 2, layout.CONTENT_TOP_OFFSET)
        
        local bottomOffset = layout.PADDING + layout.VANITY_FOOTER_HEIGHT
        -- Keep right side the same to maintain width
        content:SetPoint("BOTTOMRIGHT", -layout.PADDING - 5, bottomOffset)
        
        return content
    end,
    
    -- Close button customization
    CreateCloseButton = function(self, parent)
        local closeBtn = AC:CreateShadeCloseButton(parent)
        closeBtn:SetPoint("TOPRIGHT", -8, -8)
        return closeBtn
    end,
}

-- Disabled startup message for end users
-- print("|cff8B45FFArenaCore:|r Shade UI theme module loaded")
