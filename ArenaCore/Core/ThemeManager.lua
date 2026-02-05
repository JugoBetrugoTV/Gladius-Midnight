-- =============================================================================
-- Core/ThemeManager.lua
-- ArenaCore Theme System - Dynamic theme switching without reload
-- =============================================================================

local AddonName, _ns = ...
if type(_G.ArenaCore) ~= "table" then _G.ArenaCore = {} end
local AC = _G.ArenaCore

AC.ThemeManager = AC.ThemeManager or {}
local TM = AC.ThemeManager

-- =============================================================================
-- PREMIUM VISUAL HELPERS
-- =============================================================================

-- Apply gradient to a texture
function TM:ApplyGradient(texture, gradientDef)
    if not texture or not gradientDef then return end
    
    texture:SetGradient(
        gradientDef.orientation,
        CreateColor(gradientDef.start[1], gradientDef.start[2], gradientDef.start[3], gradientDef.start[4]),
        CreateColor(gradientDef.finish[1], gradientDef.finish[2], gradientDef.finish[3], gradientDef.finish[4])
    )
end

-- Add noise overlay to a frame (Shade UI style)
function TM:AddNoiseOverlay(frame, noisePath, alpha)
    if not frame or not noisePath then return end
    
    alpha = alpha or 0.08 -- Subtle by default
    
    local noise = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    noise:SetAllPoints()
    noise:SetTexture(noisePath)
    noise:SetAlpha(alpha)
    noise:SetBlendMode("ADD")
    
    frame.__noiseOverlay = noise
    return noise
end

-- Add shadow under an element
function TM:AddShadow(frame, shadowPath, offset)
    if not frame or not shadowPath then return end
    
    offset = offset or 4
    
    local shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    shadow:SetTexture(shadowPath)
    shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset, offset)
    shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset, -offset)
    shadow:SetAlpha(0.5)
    
    frame.__shadow = shadow
    return shadow
end

-- Add gloss layer to a button
function TM:AddGloss(button, glossPath, alpha)
    if not button or not glossPath then return end
    
    alpha = alpha or 0.3
    
    local gloss = button:CreateTexture(nil, "OVERLAY", nil, 2)
    gloss:SetTexture(glossPath)
    gloss:SetAllPoints()
    gloss:SetAlpha(alpha)
    gloss:SetBlendMode("ADD")
    
    button.__gloss = gloss
    return gloss
end

-- =============================================================================
-- THEME DEFINITIONS
-- =============================================================================

-- Default ArenaCore theme (current colors)
local DEFAULT_THEME = {
    id = "default",
    name = "ArenaCore Default",
    colors = {
        PRIMARY      = {0.545, 0.271, 1.000, 1}, -- #8B45FF purple accent
        TEXT         = {1.000, 1.000, 1.000, 1},
        TEXT_2       = {0.706, 0.706, 0.706, 1}, -- #B4B4B4
        TEXT_MUTED   = {0.502, 0.502, 0.502, 1}, -- #808080
        DANGER       = {0.863, 0.176, 0.176, 1}, -- #DC2D2D
        SUCCESS      = {0.133, 0.667, 0.267, 1}, -- #22AA44
        WARNING      = {0.800, 0.533, 0.000, 1}, -- #CC8800
        BG           = {0.200, 0.200, 0.200, 1}, -- #333333
        HEADER_BG    = {0.102, 0.102, 0.102, 1}, -- #1A1A1A
        INPUT_DARK   = {0.102, 0.102, 0.102, 1}, -- #1A1A1A
        GROUP_BG     = {0.102, 0.102, 0.102, 1}, -- #1A1A1A
        BORDER       = {0.196, 0.196, 0.196, 1}, -- #323232
        BORDER_LIGHT = {0.278, 0.278, 0.278, 1}, -- #474747
        ICON_BG      = {0.220, 0.220, 0.220, 1}, -- #383838
        NAV_ACTIVE_BG   = {0.20, 0.20, 0.20, 1},
        NAV_INACTIVE_BG = {0.12, 0.12, 0.12, 1},
        INSET        = {0.031, 0.031, 0.031, 1}, -- #080808
    },
    textures = {
        -- Using default ArenaCore textures
        panel_bg = nil, -- Use color textures
        button = "Interface\\AddOns\\ArenaCore\\Media\\UI\\tab-purple-matte.tga",
        slider_thumb = "Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga",
    }
}

-- Shade UI theme (FULL VISUAL CLONE of Shade UI addon - 2100 rating unlock)
local SHADE_UI_THEME = {
    id = "shade_ui",
    name = "Shade UI",
    colors = {
        PRIMARY      = {0.6, 0.2, 0.8, 1},        -- Purple accent (Shade style)
        TEXT         = {0.9, 0.9, 0.9, 1},        -- Light gray text
        TEXT_2       = {0.7, 0.7, 0.7, 1},        -- Muted text
        TEXT_MUTED   = {0.5, 0.5, 0.5, 1},        -- Very muted
        DANGER       = {0.863, 0.176, 0.176, 1},  -- Red
        SUCCESS      = {0.133, 0.667, 0.267, 1},  -- Green
        WARNING      = {0.800, 0.533, 0.000, 1},  -- Orange
        BG           = {0.05, 0.05, 0.05, 0.95},  -- Main background (Shade dark)
        HEADER_BG    = {0.08, 0.08, 0.08, 0.9},   -- Header background
        INPUT_DARK   = {0.15, 0.15, 0.15, 0.9},   -- Input backgrounds
        GROUP_BG     = {0.08, 0.08, 0.08, 0.9},   -- Group backgrounds
        BORDER       = {0.15, 0.15, 0.15, 1},     -- Dark borders
        BORDER_LIGHT = {0.25, 0.25, 0.25, 1},     -- Light borders
        ICON_BG      = {0.12, 0.12, 0.12, 0.85},  -- Icon backgrounds
        NAV_ACTIVE_BG   = {0.2, 0.1, 0.25, 0.9},  -- Active nav (purple tint)
        NAV_INACTIVE_BG = {0.1, 0.1, 0.1, 0.9},   -- Inactive nav
        INSET        = {0.03, 0.03, 0.03, 1},     -- Very dark inset
    },
    -- Gradient definitions (EXACT Shade UI style)
    gradients = {
        main_bg = {
            orientation = "VERTICAL",
            start = {0.08, 0.08, 0.08, 0.8},   -- Shade main gradient
            finish = {0.03, 0.03, 0.03, 0.9}   -- Darker at bottom
        },
        sidebar = {
            orientation = "HORIZONTAL",
            start = {0.1, 0.1, 0.1, 0.9},      -- LEFT: Lighter (Shade style)
            finish = {0.06, 0.06, 0.06, 0.9}   -- RIGHT: Darker
        },
        content = {
            orientation = "VERTICAL",
            start = {0.12, 0.12, 0.12, 0.85},  -- Content gradient
            finish = {0.08, 0.08, 0.08, 0.85}  -- Subtle depth
        }
    },
    -- Texture paths (Shade UI assets - NEW LOCATION)
    textures = {
        noise = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\themes\\shade\\media\\noise.tga",
        shadow = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\themes\\shade\\media\\soft_shadow_64.tga",
        button_fill = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\themes\\shade\\media\\button_fill_64x32.tga",
        button_gloss = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\themes\\shade\\media\\button_gloss_64x16.tga",
        slider_thumb = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\themes\\shade\\media\\slider_thumb_10x18.tga",
        scroll_thumb = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\themes\\shade\\media\\scroll_thumb_8x24.tga",
        input_bg = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\themes\\shade\\media\\input_bg_64.tga",
        border = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\themes\\shade\\media\\border.tga",
        vignette = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\themes\\shade\\media\\panel_vignette_512.tga",
        panel_gloss = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\themes\\shade\\media\\panel_gloss_256x64.tga",
        font_oxanium = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\themes\\shade\\media\\fonts\\Oxanium.ttf",
    },
    -- Shade UI spacing (more generous than default)
    spacing = {
        padding = 15,           -- Shade uses 15px padding (vs ArenaCore's 8px)
        titleBarHeight = 40,    -- Shade uses 40px title bar
        sidebarWidth = 180,     -- Shade uses 180px sidebar (vs ArenaCore's 240px)
    }
}

-- Black Reaper theme (PREMIUM Shade UI style with gradients and textures)
-- KEPT FOR FUTURE USE - Not currently shown in UI
local BLACK_REAPER_THEME = {
    id = "black_reaper",
    name = "Black Reaper",
    colors = {
        PRIMARY      = {0.6, 0.2, 0.8, 1},        -- Purple accent
        TEXT         = {0.9, 0.9, 0.9, 1},        -- Light gray text
        TEXT_2       = {0.7, 0.7, 0.7, 1},        -- Muted text
        TEXT_MUTED   = {0.5, 0.5, 0.5, 1},        -- Very muted
        DANGER       = {0.863, 0.176, 0.176, 1},  -- Red
        SUCCESS      = {0.133, 0.667, 0.267, 1},  -- Green
        WARNING      = {0.800, 0.533, 0.000, 1},  -- Orange
        BG           = {0.05, 0.05, 0.05, 0.95},  -- Main background (for gradients)
        HEADER_BG    = {0.08, 0.08, 0.08, 0.9},   -- Header background
        INPUT_DARK   = {0.15, 0.15, 0.15, 0.9},   -- Input backgrounds (balanced for sliders)
        GROUP_BG     = {0.08, 0.08, 0.08, 0.9},   -- Group backgrounds
        BORDER       = {0.15, 0.15, 0.15, 1},     -- Dark borders
        BORDER_LIGHT = {0.25, 0.25, 0.25, 1},     -- Light borders
        ICON_BG      = {0.12, 0.12, 0.12, 0.85},  -- Icon backgrounds
        NAV_ACTIVE_BG   = {0.2, 0.1, 0.25, 0.9},  -- Active nav (purple tint)
        NAV_INACTIVE_BG = {0.1, 0.1, 0.1, 0.9},   -- Inactive nav
        INSET        = {0.03, 0.03, 0.03, 1},     -- Very dark inset
    },
    -- Gradient definitions (EXACT Shade UI style)
    gradients = {
        main_bg = {
            orientation = "VERTICAL",
            start = {0.05, 0.05, 0.05, 0.95},  -- Darker to match Shade
            finish = {0.02, 0.02, 0.02, 0.95}  -- Almost black
        },
        sidebar = {
            orientation = "HORIZONTAL",
            start = {0.03, 0.03, 0.03, 0.95},  -- LEFT: Almost black (REVERSED!)
            finish = {0.07, 0.07, 0.07, 0.95}  -- RIGHT: Slightly lighter
        },
        content = {
            orientation = "VERTICAL",
            start = {0.08, 0.08, 0.08, 0.9},   -- Darker
            finish = {0.05, 0.05, 0.05, 0.9}   -- Almost black
        }
    },
    -- Texture paths (Shade UI assets)
    textures = {
        noise = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\shade\\media\\noise.tga",
        shadow = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\shade\\media\\soft_shadow_64.tga",
        button_fill = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\shade\\media\\button_fill_64x32.tga",
        button_gloss = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\shade\\media\\button_gloss_64x16.tga",
        slider_thumb = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\shade\\media\\slider_thumb_10x18.tga",
        scroll_thumb = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\shade\\media\\scroll_thumb_8x24.tga",
        input_bg = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\shade\\media\\input_bg_64.tga",
        border = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\shade\\media\\border.tga",
        vignette = "Interface\\AddOns\\ArenaCore\\Media\\Achievements\\shade\\media\\panel_vignette_512.tga",
    }
}

-- Theme registry
TM.themes = {
    ["default"] = DEFAULT_THEME,
    ["shade_ui"] = SHADE_UI_THEME,
    ["black_reaper"] = BLACK_REAPER_THEME,  -- Kept for future use
}

-- =============================================================================
-- THEME MANAGEMENT
-- =============================================================================

-- Initialize theme system
function TM:Initialize()
    -- Load saved theme from database
    if not AC.DB or not AC.DB.profile then
        -- DEBUG: print("|cffFF0000ArenaCore ThemeManager:|r Database not ready!")
        return
    end
    
    if not AC.DB.profile.theme then
        AC.DB.profile.theme = {
            active = "default",
        }
    end
    
    -- Apply saved theme
    local savedTheme = AC.DB.profile.theme.active or "default"
    self:ApplyTheme(savedTheme, true) -- true = silent on init
    
    -- Debug disabled: Theme initialization
    -- local themeName = self.themes[savedTheme] and self.themes[savedTheme].name or "Default"
    -- print("|cff8B45FFArenaCore:|r Theme system initialized")
    -- print("|cff8B45FFArenaCore:|r Active theme: " .. themeName .. " (ID: " .. savedTheme .. ")")
    
    -- Debug disabled: Color values
    -- if AC.COLORS then
    --     print("|cff8B45FFArenaCore:|r NAV_INACTIVE_BG: " .. string.format("%.2f, %.2f, %.2f", AC.COLORS.NAV_INACTIVE_BG[1], AC.COLORS.NAV_INACTIVE_BG[2], AC.COLORS.NAV_INACTIVE_BG[3]))
    -- end
end

-- Get current active theme
function TM:GetActiveTheme()
    if not AC.DB or not AC.DB.profile or not AC.DB.profile.theme then
        return "default"
    end
    return AC.DB.profile.theme.active or "default"
end

-- Check if a theme is active
function TM:IsThemeActive(themeId)
    return self:GetActiveTheme() == themeId
end

-- Apply a theme
function TM:ApplyTheme(themeId, silent)
    if not self.themes[themeId] then
        print("|cffFF0000Arena Core: |r Theme '" .. themeId .. "' not found!")
        return
    end
    
    local oldTheme = AC.DB.profile.theme.active
    local theme = self.themes[themeId]
    
    -- If theme is already active, do nothing
    if oldTheme == themeId then
        if not silent then
            print("|cff8B45FFArena Core: |r Theme '" .. theme.name .. "' is already active!")
        end
        return
    end
    
    -- CRITICAL FIX: Show reload popup FIRST, only apply theme if user clicks OK
    -- This prevents partial theme application if user cancels
    if not silent then
        self:ShowReloadConfirmation(theme.name, themeId, oldTheme)
        return  -- Don't apply yet, wait for user confirmation
    else
        -- Silent mode (on init) - just apply without popup
        self:_ApplyThemeInternal(themeId)
        print("|cff8B45FFArena Core: |r Theme set to: " .. theme.name)
    end
end

-- Internal function to actually apply the theme (called after user confirms reload)
function TM:_ApplyThemeInternal(themeId)
    local theme = self.themes[themeId]
    if not theme then return end
    
    -- Save to database
    AC.DB.profile.theme.active = themeId
    
    -- Update global COLORS table
    if theme.colors then
        for key, value in pairs(theme.colors) do
            AC.COLORS[key] = value
        end
    end
    
    -- Reload UI to apply theme
    ReloadUI()
end

-- Show reload confirmation popup BEFORE applying theme
function TM:ShowReloadConfirmation(themeName, themeId, oldTheme)
    -- Create popup frame
    local popup = CreateFrame("Frame", "ArenaCoreThemeReloadPopup", UIParent)
    popup:SetSize(400, 180)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(9999)
    
    -- Red textured background using button-hide.tga
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-hide.tga")
    bg:SetVertexColor(1, 0.2, 0.2, 1) -- Red tint
    
    -- Dark overlay for text readability
    local overlay = popup:CreateTexture(nil, "BORDER")
    overlay:SetAllPoints()
    overlay:SetColorTexture(0, 0, 0, 0.4) -- 40% black overlay
    
    -- Title (clean white, no outline)
    local title = popup:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    title:SetPoint("TOP", 0, -15)
    title:SetTextColor(1, 1, 1, 1)
    title:SetText("RELOAD REQUIRED")
    
    -- Message
    local message = popup:CreateFontString(nil, "OVERLAY")
    message:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    message:SetPoint("TOP", title, "BOTTOM", 0, -15)
    message:SetWidth(360)
    message:SetJustifyH("CENTER")
    message:SetText("Switch to |cff8B45FF" .. themeName .. "|r theme?\n\nThis requires a UI reload to apply.\nClick OK to switch and reload now, or Cancel to stay on your current theme.")
    
    -- OK Button
    local okBtn = CreateFrame("Button", nil, popup)
    okBtn:SetSize(120, 35)
    okBtn:SetPoint("BOTTOM", -65, 15)
    
    local okBg = okBtn:CreateTexture(nil, "BACKGROUND")
    okBg:SetAllPoints()
    okBg:SetColorTexture(0.2, 0.6, 0.2, 1)
    
    local okText = okBtn:CreateFontString(nil, "OVERLAY")
    okText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    okText:SetPoint("CENTER")
    okText:SetText("OK (Reload)")
    
    okBtn:SetScript("OnEnter", function(self)
        okBg:SetColorTexture(0.3, 0.8, 0.3, 1)
    end)
    okBtn:SetScript("OnLeave", function(self)
        okBg:SetColorTexture(0.2, 0.6, 0.2, 1)
    end)
    okBtn:SetScript("OnClick", function()
        popup:Hide()
        -- Apply the theme, which will automatically reload at the end
        TM:_ApplyThemeInternal(themeId)
    end)
    
    -- Cancel Button
    local cancelBtn = CreateFrame("Button", nil, popup)
    cancelBtn:SetSize(120, 35)
    cancelBtn:SetPoint("BOTTOM", 65, 15)
    
    local cancelBg = cancelBtn:CreateTexture(nil, "BACKGROUND")
    cancelBg:SetAllPoints()
    cancelBg:SetColorTexture(0.3, 0.3, 0.3, 1)
    
    local cancelText = cancelBtn:CreateFontString(nil, "OVERLAY")
    cancelText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    cancelText:SetPoint("CENTER")
    cancelText:SetText("Cancel")
    
    cancelBtn:SetScript("OnEnter", function(self)
        cancelBg:SetColorTexture(0.4, 0.4, 0.4, 1)
    end)
    cancelBtn:SetScript("OnLeave", function(self)
        cancelBg:SetColorTexture(0.3, 0.3, 0.3, 1)
    end)
    cancelBtn:SetScript("OnClick", function()
        popup:Hide()
        print("|cffFFAA00Arena Core: |r Theme change cancelled")
    end)
    
    -- Close on Escape
    popup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            popup:Hide()
            print("|cffFFAA00Arena Core: |r Theme change cancelled")
        end
    end)
    popup:EnableKeyboard(true)
    
    popup:Show()
end

-- Refresh all UI elements with new theme
function TM:RefreshAllUI()
    -- Refresh main UI window
    local mainFrame = _G["ArenaCoreConfigFrame"]
    if mainFrame and mainFrame:IsShown() then
        self:RefreshMainUI()
    end
    
    -- Refresh Extension Packs window
    if AC.MoreFeatures and AC.MoreFeatures.window and AC.MoreFeatures.window:IsShown() then
        self:RefreshMoreFeaturesUI()
    end
    
    -- Refresh ALL ArenaCore windows (Debuffs, Auras, Kick Bar, DR, etc.)
    self:RefreshAllWindows()
    
    -- Refresh enemy frames (if visible)
    if AC.RefreshEnemyFrames then
        AC:RefreshEnemyFrames()
    end
    
    -- Refresh trinket tracker (if visible)
    if AC.TrinketTracker and AC.TrinketTracker.Refresh then
        AC.TrinketTracker:Refresh()
    end
end

-- Refresh all ArenaCore windows (popup editors, etc.)
function TM:RefreshAllWindows()
    local colors = AC.COLORS
    
    -- List of known ArenaCore window names
    local windowNames = {
        "ArenaCoreDebuffsWindow",
        "ArenaCoreAurasWindow",
        "ArenaCoreKickBarWindow",
        "ArenaCoreDRWindow",
        "ArenaCoreDispelWindow",
    }
    
    for _, windowName in ipairs(windowNames) do
        local window = _G[windowName]
        if window and window:IsShown() then
            self:RefreshWindow(window)
        end
    end
end

-- Refresh a single window
function TM:RefreshWindow(window)
    if not window then return end
    
    local colors = AC.COLORS
    
    local function UpdateTextures(frame, depth)
        if not frame then return end
        depth = depth or 0
        
        local regions = {frame:GetRegions()}
        for _, region in ipairs(regions) do
            if region and region.GetObjectType then
                local objType = region:GetObjectType()
                
                if objType == "Texture" and region.SetColorTexture then
                    local r, g, b, a = region:GetVertexColor()
                    
                    if r and g and b then
                        -- Main content backgrounds (0.20 range)
                        if r >= 0.19 and r <= 0.21 and g >= 0.19 and g <= 0.21 then
                            region:SetColorTexture(colors.BG[1], colors.BG[2], colors.BG[3], colors.BG[4] or 1)
                        -- Header/sidebar backgrounds (0.10-0.12 range)
                        elseif r >= 0.09 and r <= 0.13 and g >= 0.09 and g <= 0.13 then
                            region:SetColorTexture(colors.HEADER_BG[1], colors.HEADER_BG[2], colors.HEADER_BG[3], colors.HEADER_BG[4] or 1)
                        -- Very dark/inset backgrounds
                        elseif r < 0.05 and g < 0.05 then
                            region:SetColorTexture(colors.INSET[1], colors.INSET[2], colors.INSET[3], colors.INSET[4] or 1)
                        -- Medium gray backgrounds
                        elseif r >= 0.14 and r <= 0.19 and g >= 0.14 and g <= 0.19 then
                            region:SetColorTexture(colors.ICON_BG[1], colors.ICON_BG[2], colors.ICON_BG[3], colors.ICON_BG[4] or 1)
                        -- Borders
                        elseif r >= 0.24 and r <= 0.30 and g >= 0.24 and g <= 0.30 then
                            region:SetColorTexture(colors.BORDER_LIGHT[1], colors.BORDER_LIGHT[2], colors.BORDER_LIGHT[3], colors.BORDER_LIGHT[4] or 1)
                        end
                    end
                end
            end
        end
        
        local children = {frame:GetChildren()}
        for _, child in ipairs(children) do
            UpdateTextures(child, depth + 1)
        end
    end
    
    UpdateTextures(window)
end

-- Helper function to refresh all sliders
function TM:RefreshAllSliders(frame)
    if not frame then return end
    
    -- Check if this is a slider container
    if frame.slider and frame:GetObjectType() == "Frame" then
        local children = {frame:GetChildren()}
        for _, child in ipairs(children) do
            -- Update slider track background
            local regions = {child:GetRegions()}
            for _, region in ipairs(regions) do
                if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                    local r, g, b = region:GetVertexColor()
                    -- Update slider track (darkish gray)
                    if r and r >= 0.10 and r <= 0.20 and g >= 0.10 and g <= 0.20 and b >= 0.10 and b <= 0.20 then
                        local trackColor = AC.COLORS.INPUT_DARK
                        region:SetColorTexture(trackColor[1], trackColor[2], trackColor[3], trackColor[4] or 1)
                    end
                end
            end
        end
    end
    
    -- Recursively check children
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        self:RefreshAllSliders(child)
    end
end

-- Refresh main UI window
function TM:RefreshMainUI()
    -- Find the main ArenaCore config frame
    local mainFrame = _G["ArenaCoreConfigFrame"]
    if not mainFrame then 
        -- DEBUG: print("|cffFF0000ArenaCore ThemeManager:|r Main UI frame not found!")
        return 
    end
    
    local colors = AC.COLORS
    local activeTheme = self.themes[self:GetActiveTheme()]
    local activeThemeId = self:GetActiveTheme()
    local isShadeUI = activeThemeId == "shade_ui"
    local isBlackReaper = activeThemeId == "black_reaper"
    local isPremiumTheme = isShadeUI or isBlackReaper
    
    -- Refresh all sliders to use new theme colors
    self:RefreshAllSliders(mainFrame)
    
    -- CRITICAL: Reposition content area for Shade UI theme
    if isShadeUI then
        -- Find the content ScrollFrame and reposition it
        local children = {mainFrame:GetChildren()}
        for _, child in ipairs(children) do
            if child:GetObjectType() == "ScrollFrame" then
                -- This is likely the content area
                child:ClearAllPoints()
                -- Left: 180 (sidebar) + 15 (padding) + 5 (small gap) = 200px
                -- Right: -15 (padding) - 0 (no extra gap, scrollbar fills the space)
                child:SetPoint("TOPLEFT", 200, -55)
                child:SetPoint("BOTTOMRIGHT", -15, 15 + 28)
                -- Debug removed for clean release
                break
            end
        end
    end
    
    -- Apply premium features for Shade UI and Black Reaper themes
    if isPremiumTheme and activeTheme then
        -- Apply gradient to main background
        if mainFrame.__mainBg and activeTheme.gradients and activeTheme.gradients.main_bg then
            self:ApplyGradient(mainFrame.__mainBg, activeTheme.gradients.main_bg)
        end
        
        -- Add noise overlay to main frame
        if mainFrame.__mainFrame and activeTheme.textures and activeTheme.textures.noise then
            if not mainFrame.__noiseOverlay then
                self:AddNoiseOverlay(mainFrame, activeTheme.textures.noise, 0.08)
            end
        end
        
        -- Apply gradient to sidebar
        if AC.sidebar and AC.sidebar.__sidebarBg and activeTheme.gradients and activeTheme.gradients.sidebar then
            self:ApplyGradient(AC.sidebar.__sidebarBg, activeTheme.gradients.sidebar)
        end
        
        -- Add noise to sidebar
        if AC.sidebar and AC.sidebar.__isSidebar and activeTheme.textures and activeTheme.textures.noise then
            if not AC.sidebar.__noiseOverlay then
                self:AddNoiseOverlay(AC.sidebar, activeTheme.textures.noise, 0.05)
            end
        end
    end
    
    -- Update the main content area background (the light gray area behind everything)
    if AC.contentBox and AC.contentBox.__contentFill then
        AC.contentBox.__contentFill:SetColorTexture(colors.BG[1], colors.BG[2], colors.BG[3], colors.BG[4] or 1)
    end
    
    -- Also search for it in the main frame tree
    local function FindContentBox(frame)
        if not frame then return end
        
        -- Check if this frame has the contentBox characteristics
        local regions = {frame:GetRegions()}
        for _, region in ipairs(regions) do
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local r, g, b = region:GetVertexColor()
                -- Main content fill (0.20 gray) - this is what we're looking for!
                if r and r >= 0.195 and r <= 0.205 and g >= 0.195 and g <= 0.205 and b >= 0.195 and b <= 0.205 then
                    region:SetColorTexture(colors.BG[1], colors.BG[2], colors.BG[3], colors.BG[4] or 1)
                end
            end
        end
        
        -- Recursively search children
        local children = {frame:GetChildren()}
        for _, child in ipairs(children) do
            FindContentBox(child)
        end
    end
    
    FindContentBox(mainFrame)
    
    -- Update all background textures in the main frame
    local function UpdateTextures(frame, depth)
        if not frame then return end
        depth = depth or 0
        
        -- CRITICAL FIX: Only process ArenaCore frames to prevent styling global UI elements
        -- Check if this frame or any of its parents belong to this addon
        local function IsArenaCoreFrame(f)
            if not f then return false end
            
            -- Check if frame has addon marker
            if f.__isArenaCore then return true end
            
            -- Check frame name
            local name = f:GetName()
            if name and name:match("^ArenaCore") then return true end
            
            -- Check if it's the main config frame or its children
            if f == _G["ArenaCoreConfigFrame"] then return true end
            
            -- Check parent recursively (max 10 levels to prevent infinite loops)
            local parent = f:GetParent()
            local depth = 0
            while parent and depth < 10 do
                if parent == _G["ArenaCoreConfigFrame"] then return true end
                if parent.__isArenaCore then return true end
                local parentName = parent:GetName()
                if parentName and parentName:match("^ArenaCore") then return true end
                parent = parent:GetParent()
                depth = depth + 1
            end
            
            return false
        end
        
        -- Skip frames that don't belong to this addon
        if not IsArenaCoreFrame(frame) then
            return
        end
        
        -- Check if this frame has a HairlineGroupBox fill
        if frame.__acFill and frame.__acFillIsGroupBox then
            frame.__acFill:SetColorTexture(colors.HEADER_BG[1], colors.HEADER_BG[2], colors.HEADER_BG[3], colors.HEADER_BG[4] or 1)
        end
        
        -- Also check for __acFill without the flag (old boxes)
        if frame.__acFill and not frame.__acFillIsGroupBox then
            frame.__acFill:SetColorTexture(colors.HEADER_BG[1], colors.HEADER_BG[2], colors.HEADER_BG[3], colors.HEADER_BG[4] or 1)
        end
        
        -- Check for collapsible section backgrounds
        if frame.__acSectionBg then
            frame.__acSectionBg:SetColorTexture(colors.NAV_INACTIVE_BG[1], colors.NAV_INACTIVE_BG[2], colors.NAV_INACTIVE_BG[3], colors.NAV_INACTIVE_BG[4] or 1)
        end
        
        -- Apply premium treatment to nav buttons (Shade UI and Black Reaper)
        if isPremiumTheme and frame.__isNavButton and activeTheme and activeTheme.textures then
            -- Set gradient flag so SetActive will apply gradient
            frame.__useGradient = true
            
            -- Add subtle shadow under nav buttons
            if not frame.__shadow and activeTheme.textures.shadow then
                self:AddShadow(frame, activeTheme.textures.shadow, 2)
            end
            
            -- Force refresh of button state to apply gradient
            if frame.SetActive then
                local wasActive = frame.isActive
                frame:SetActive(wasActive) -- Re-apply current state with gradient
            end
        else
            -- Not premium theme - ensure gradient flag is false and refresh
            if frame.__isNavButton then
                frame.__useGradient = false
                if frame.SetActive then
                    local wasActive = frame.isActive
                    frame:SetActive(wasActive) -- Re-apply current state without gradient
                end
            end
        end
        
        -- Get all regions (textures and font strings)
        local regions = {frame:GetRegions()}
        for _, region in ipairs(regions) do
            if region and region.GetObjectType then
                local objType = region:GetObjectType()
                
                -- Update color textures
                if objType == "Texture" and region.SetColorTexture then
                    -- Try to identify what this texture is for based on current color
                    local r, g, b, a = region:GetVertexColor()
                    
                    if r and g and b then
                        -- ANY gray shade (0.10 to 0.30) - replace with appropriate dark color
                        if r >= 0.10 and r <= 0.30 and g >= 0.10 and g <= 0.30 and b >= 0.10 and b <= 0.30 then
                            -- Determine which dark shade to use based on original brightness
                            if r >= 0.18 then
                                -- Light gray (0.18-0.30) → Main background (darkest)
                                region:SetColorTexture(colors.BG[1], colors.BG[2], colors.BG[3], colors.BG[4] or 1)
                            else
                                -- Medium/dark gray (0.10-0.18) → Header background
                                region:SetColorTexture(colors.HEADER_BG[1], colors.HEADER_BG[2], colors.HEADER_BG[3], colors.HEADER_BG[4] or 1)
                            end
                        -- Very dark/inset backgrounds (< 0.05 - almost black)
                        elseif r < 0.05 and g < 0.05 then
                            region:SetColorTexture(colors.INSET[1], colors.INSET[2], colors.INSET[3], colors.INSET[4] or 1)
                        end
                    end
                end
            end
        end
        
        -- Recursively update child frames
        local children = {frame:GetChildren()}
        for _, child in ipairs(children) do
            UpdateTextures(child, depth + 1)
        end
    end
    
    -- Update the entire frame tree
    UpdateTextures(mainFrame)
    
    -- CRITICAL: Force refresh ALL navigation buttons in sidebar
    if AC.sidebar then
        local function ForceRefreshNavButtons(frame, depth)
            if not frame then return end
            depth = depth or 0
            
            -- Check if this is a nav button
            if frame.__isNavButton and frame.SetActive then
                local wasActive = frame.isActive
                
                -- Update gradient flag based on theme
                frame.__useGradient = isPremiumTheme
                
                -- Force re-apply state with new colors
                frame:SetActive(wasActive)
            end
            
            -- Recursively check children
            local children = {frame:GetChildren()}
            for _, child in ipairs(children) do
                ForceRefreshNavButtons(child, depth + 1)
            end
        end
        
        ForceRefreshNavButtons(AC.sidebar)
    end
    
    -- Debug disabled: Main UI refresh
    -- print("|cff8B45FFArenaCore ThemeManager:|r Main UI refreshed with " .. (activeTheme and activeTheme.name or "DEFAULT") .. " theme")
end

-- Refresh Extension Packs window
function TM:RefreshMoreFeaturesUI()
    if not AC.MoreFeatures or not AC.MoreFeatures.window then return end
    
    local colors = AC.COLORS
    local window = AC.MoreFeatures.window
    
    -- Update all background textures in the Extension Packs window
    local function UpdateTextures(frame, depth)
        if not frame then return end
        depth = depth or 0
        
        -- Get all regions (textures and font strings)
        local regions = {frame:GetRegions()}
        for _, region in ipairs(regions) do
            if region and region.GetObjectType then
                local objType = region:GetObjectType()
                
                -- Update color textures
                if objType == "Texture" and region.SetColorTexture then
                    -- Try to identify what this texture is for based on current color
                    local r, g, b, a = region:GetVertexColor()
                    
                    if r and g and b then
                        -- ANY gray shade (0.10 to 0.30) - replace with appropriate dark color
                        if r >= 0.10 and r <= 0.30 and g >= 0.10 and g <= 0.30 and b >= 0.10 and b <= 0.30 then
                            -- Determine which dark shade to use based on original brightness
                            if r >= 0.18 then
                                -- Light gray (0.18-0.30) → Main background (darkest)
                                region:SetColorTexture(colors.BG[1], colors.BG[2], colors.BG[3], colors.BG[4] or 1)
                            else
                                -- Medium/dark gray (0.10-0.18) → Header background
                                region:SetColorTexture(colors.HEADER_BG[1], colors.HEADER_BG[2], colors.HEADER_BG[3], colors.HEADER_BG[4] or 1)
                            end
                        -- Very dark/inset backgrounds (< 0.05 - almost black)
                        elseif r < 0.05 and g < 0.05 then
                            region:SetColorTexture(colors.INSET[1], colors.INSET[2], colors.INSET[3], colors.INSET[4] or 1)
                        end
                    end
                end
            end
        end
        
        -- Recursively update child frames
        local children = {frame:GetChildren()}
        for _, child in ipairs(children) do
            UpdateTextures(child, depth + 1)
        end
    end
    
    -- Update the entire frame tree
    UpdateTextures(window)
    
    -- DEBUG: print("|cff8B45FFArenaCore ThemeManager:|r Extension Packs UI refreshed")
end

-- Rebuild main UI completely (for theme switching)
function TM:RebuildMainUI()
    -- CRITICAL: Verify CreateUI exists BEFORE destroying anything
    if not AC or not AC.CreateUI then
        print("|cffFF0000Arena Core: |r CreateUI function not found! Cannot rebuild UI.")
        return
    end
    
    local mainFrame = _G["ArenaCoreConfigFrame"]
    if not mainFrame then 
        -- No frame exists, just create it
        AC:CreateUI()
        return 
    end
    
    -- Remember state before destroying
    local wasShown = mainFrame:IsShown()
    local currentPage = AC.currentPage
    
    -- Properly destroy the old frame
    if mainFrame.UnregisterAllEvents then
        mainFrame:UnregisterAllEvents()
    end
    mainFrame:Hide()
    
    -- Clear all children
    local children = {mainFrame:GetChildren()}
    for _, child in ipairs(children) do
        if child.Hide then child:Hide() end
        if child.SetParent then child:SetParent(nil) end
    end
    
    -- Remove the frame
    mainFrame:SetParent(nil)
    _G["ArenaCoreConfigFrame"] = nil
    
    -- Clear all references
    AC.configFrame = nil
    AC.header = nil
    AC.sidebar = nil
    AC.content = nil
    AC.currentPage = nil
    
    -- Force garbage collection
    collectgarbage("collect")
    
    -- Wait a frame then rebuild
    C_Timer.After(0, function()
        -- Rebuild from scratch (we already verified CreateUI exists)
        local success, err = pcall(function()
            AC:CreateUI()
        end)
        
        if not success then
            print("|cffFF0000Arena Core: |r Error rebuilding UI: " .. tostring(err))
            return
        end
        
        -- Verify UI was created
        if not AC.configFrame then
            print("|cffFF0000Arena Core: |r UI rebuild failed - configFrame not created!")
            return
        end
        
        -- Restore state
        if wasShown then
            AC.configFrame:Show()
            
            -- Restore the current page
            if currentPage and AC.ShowPage then
                C_Timer.After(0.1, function()
                    AC:ShowPage(currentPage)
                end)
            end
        end
    end)
end

-- Rebuild Extension Packs window (for theme switching)
function TM:RebuildMoreFeaturesUI()
    if not AC.MoreFeatures then return end
    if not AC.MoreFeatures.window then 
        -- No window exists, just create it if needed
        return
    end
    
    local window = AC.MoreFeatures.window
    local wasShown = window:IsShown()
    local currentPage = AC.MoreFeatures.currentPage
    
    -- Properly destroy the old window
    if window.UnregisterAllEvents then
        window:UnregisterAllEvents()
    end
    window:Hide()
    
    -- Clear all children
    local children = {window:GetChildren()}
    for _, child in ipairs(children) do
        if child.Hide then child:Hide() end
        if child.SetParent then child:SetParent(nil) end
    end
    
    -- Remove the window
    window:SetParent(nil)
    AC.MoreFeatures.window = nil
    
    -- Clear references
    AC.MoreFeatures.sidebar = nil
    AC.MoreFeatures.content = nil
    AC.MoreFeatures.pageContainers = {}
    
    -- Force garbage collection
    collectgarbage("collect")
    
    -- Wait a frame then rebuild
    C_Timer.After(0, function()
        -- Rebuild from scratch
        if AC.MoreFeatures.CreateWindow then
            AC.MoreFeatures:CreateWindow()
        end
        
        -- Restore state
        if wasShown and AC.MoreFeatures.window then
            AC.MoreFeatures.window:Show()
            
            -- Restore the current page
            if currentPage and AC.MoreFeatures.ShowPage then
                C_Timer.After(0.1, function()
                    AC.MoreFeatures:ShowPage(currentPage)
                end)
            end
        end
    end)
end

-- =============================================================================
-- SLASH COMMANDS
-- =============================================================================

SLASH_ACTHEME1 = "/actheme"
SlashCmdList["ACTHEME"] = function(msg)
    local cmd = string.lower(string.trim(msg or ""))
    
    if cmd == "default" then
        TM:ApplyTheme("default")
    elseif cmd == "shade" or cmd == "shade_ui" or cmd == "shadeui" then
        -- Check if unlocked
        if AC.IsThemeUnlocked and not AC:IsThemeUnlocked("shade_ui") then
            print("|cffFF0000Arena Core: |r Shade UI theme is locked! Reach 2100 rating to unlock.")
            print("|cffFFFF00Arena Core: |r Use '/actheme force shade_ui' to test it anyway (debug mode)")
            return
        end
        TM:ApplyTheme("shade_ui")
    elseif cmd == "force shade_ui" or cmd == "force shadeui" then
        -- Force apply Shade UI for testing (bypass unlock check)
        print("|cffFFD700Arena Core: |r FORCING Shade UI theme (debug mode - bypassing unlock)")
        TM:ApplyTheme("shade_ui")
    elseif cmd == "black_reaper" or cmd == "blackreaper" or cmd == "reaper" then
        -- Check if unlocked
        if AC.IsThemeUnlocked and not AC:IsThemeUnlocked("black_reaper") then
            print("|cffFF0000Arena Core: |r Black Reaper theme is locked! Future theme.")
            return
        end
        TM:ApplyTheme("black_reaper")
    elseif cmd == "debug" or cmd == "status" then
        -- Debug info
        print("|cff8B45FFArenaCore Theme Debug:|r")
        print("  Active Theme: " .. TM:GetActiveTheme())
        print("  Shade UI Unlocked: " .. tostring(AC:IsThemeUnlocked("shade_ui")))
        if AC.COLORS then
            print("  NAV_INACTIVE_BG: " .. string.format("%.2f, %.2f, %.2f", AC.COLORS.NAV_INACTIVE_BG[1], AC.COLORS.NAV_INACTIVE_BG[2], AC.COLORS.NAV_INACTIVE_BG[3]))
            print("  BG: " .. string.format("%.2f, %.2f, %.2f", AC.COLORS.BG[1], AC.COLORS.BG[2], AC.COLORS.BG[3]))
        end
    elseif cmd == "list" then
        print("|cff8B45FFArenaCore Themes:|r")
        for id, theme in pairs(TM.themes) do
            local isActive = TM:IsThemeActive(id)
            local isUnlocked = AC.IsThemeUnlocked and AC:IsThemeUnlocked(id) or (id == "default")
            local status = isActive and "|cff22AA44[ACTIVE]|r" or ""
            local lockStatus = isUnlocked and "|cff00FF00[UNLOCKED]|r" or "|cffFF0000[LOCKED]|r"
            print(string.format("  - %s %s %s (ID: %s)", theme.name, status, lockStatus, id))
        end
    else
        print("|cff8B45FFArenaCore Theme Commands:|r")
        print("  /actheme default - Switch to default theme")
        print("  /actheme shade_ui - Switch to Shade UI theme (2100 unlock)")
        print("  /actheme force shade_ui - Force Shade UI (debug/testing)")
        print("  /actheme debug - Show theme debug info")
        print("  /actheme list - List all themes")
    end
end

-- DEBUG: print("|cff8B45FFArenaCore:|r ThemeManager.lua loaded")
