-- =============================================================================
-- Core/Themes/Default.lua - Default ArenaCore Theme Module
-- =============================================================================

local AddonName, _ns = ...
if type(_G.ArenaCore) ~= "table" then _G.ArenaCore = {} end
local AC = _G.ArenaCore

-- Initialize theme registry if it doesn't exist
AC.Themes = AC.Themes or {}

-- ====== DEFAULT ARENACORE THEME DEFINITION ======
AC.Themes.default = {
    name = "ArenaCore Default",
    
    -- Layout configuration
    layout = {
        UI_WIDTH = 720,
        UI_HEIGHT = 580,
        HEADER_HEIGHT = 70,
        SIDEBAR_WIDTH = 240,
        SIDEBAR_HEIGHT = 480,
        CONTENT_WIDTH = 485,  -- Increased from 450 to match Shade UI (prevents button clipping)
        CONTENT_HEIGHT = 480,
        PADDING = 8,
        NAV_BUTTON_WIDTH = 220,
        NAV_BUTTON_HEIGHT = 44,
        NAV_BUTTON_SPACING = 48,  -- Reduced from 50 to fit new Frames button
        NAV_FIRST_OFFSET = -18,
        BOTTOM_BAR_HEIGHT = 0,
        TITLE_FONT_SIZE = 16,
        SUBTITLE_FONT_SIZE = 12,
        NAV_FONT_SIZE = 14,
        NAV_ICON_SIZE = 32,
        HAS_BOTTOM_BAR = false,
        SIDEBAR_TOP_OFFSET = -(70 + 8),
        CONTENT_TOP_OFFSET = -(70 + 8),
        VANITY_FOOTER_HEIGHT = 28,
    },
    
    -- Uses global AC.COLORS
    colors = nil,  -- Will use AC.COLORS
    
    -- Header customization
    CreateHeader = function(self, parent, layout)
        local header = CreateFrame("Frame", nil, parent)
        header:SetPoint("TOPLEFT", layout.PADDING, -layout.PADDING)
        header:SetPoint("TOPRIGHT", -layout.PADDING, -layout.PADDING)
        header:SetHeight(layout.HEADER_HEIGHT)
        
        -- Background
        local headerBg = AC:CreateFlatTexture(header, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
        headerBg:SetAllPoints()
        
        -- Purple accent line
        local accent = AC:CreateFlatTexture(header, "OVERLAY", 3, AC.COLORS.PRIMARY, 1)
        accent:SetPoint("TOPLEFT", 0, 0)
        accent:SetPoint("TOPRIGHT", 0, 0)
        accent:SetHeight(2)
        
        -- Bottom borders
        local hbLight = AC:CreateFlatTexture(header, "OVERLAY", 2, AC.COLORS.BORDER_LIGHT, 0.8)
        hbLight:SetPoint("BOTTOMLEFT", 0, 0)
        hbLight:SetPoint("BOTTOMRIGHT", 0, 0)
        hbLight:SetHeight(1)

        local hbDark = AC:CreateFlatTexture(header, "OVERLAY", 1, AC.COLORS.BORDER, 1)
        hbDark:SetPoint("BOTTOMLEFT", 0, 1)
        hbDark:SetPoint("BOTTOMRIGHT", 0, 1)
        hbDark:SetHeight(1)
        
        -- Logo
        local logo = header:CreateTexture(nil, "OVERLAY")
        logo:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Logo\\arena_core_clean.tga")
        logo:SetSize(250, 67)
        logo:SetPoint("LEFT", 25, 8)
        
        return header
    end,
    
    -- Sidebar customization
    CreateSidebar = function(self, parent, layout)
        local sidebar = CreateFrame("Frame", nil, parent)
        sidebar:SetPoint("TOPLEFT", layout.PADDING, layout.SIDEBAR_TOP_OFFSET)
        sidebar:SetPoint("BOTTOMLEFT", layout.PADDING, layout.PADDING)
        sidebar:SetWidth(layout.SIDEBAR_WIDTH)
        
        local bg = AC:CreateFlatTexture(sidebar, "BACKGROUND", 1, AC.COLORS.BG, 1)
        bg:SetAllPoints()
        
        return sidebar
    end,
    
    -- Content area customization
    CreateContentArea = function(self, parent, layout)
        local content = CreateFrame("ScrollFrame", nil, parent)
        content:SetPoint("TOPLEFT", layout.SIDEBAR_WIDTH + layout.PADDING + 1, layout.CONTENT_TOP_OFFSET)
        
        local bottomOffset = layout.PADDING + layout.VANITY_FOOTER_HEIGHT
        content:SetPoint("BOTTOMRIGHT", -layout.PADDING - 16, bottomOffset)
        
        return content
    end,
    
    -- Close button customization
    CreateCloseButton = function(self, parent)
        local closeBtn = AC:CreateTexturedButton(parent, 36, 36, "", "button-close")
        closeBtn:SetPoint("RIGHT", -20, 0)
        
        local xText = AC:CreateStyledText(closeBtn, "×", 18, AC.COLORS.TEXT, "OVERLAY", "")
        xText:SetPoint("CENTER", 0, 0)
        closeBtn._xText = xText
        
        return closeBtn
    end,
}

-- Disabled startup message for end users
-- print("|cff8B45FFArenaCore:|r Default theme module loaded")
