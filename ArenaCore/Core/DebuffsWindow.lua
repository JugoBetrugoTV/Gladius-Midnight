-- Core/DebuffsWindow.lua --
-- Debuffs Window: Displays debuffs on enemy arena targets
local AC = _G.ArenaCore
if not AC then return end

-- MIDNIGHT COMPATIBILITY: Disable in restricted content (arena matches)
local function IsDebuffsWindowRestricted()
    if not AC.IsMidnight or not AC:IsMidnight() then
        return false
    end
    return AC:IsInRestrictedContent()
end

local debuffsWindow = nil

-- Create the debuffs configuration window
local function CreateDebuffsWindow()
    if debuffsWindow then return debuffsWindow end
    
    -- Main window frame
    local window = CreateFrame("Frame", "ArenaCoreDebuffsWindow", UIParent)
    window:SetSize(450, 650)  -- Increased height for timer controls
    window:SetPoint("CENTER")
    window:SetClampedToScreen(true)
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()
    
    -- Enable resizable UI with scale drag grips
    if AC.UIFeatures and AC.UIFeatures.EnableResizableUI then
        AC.UIFeatures:EnableResizableUI(window, "debuffsWindowScale")
    end
    
    -- Background using ArenaCore styling - same dark color as slider track
    local bg = AC:CreateFlatTexture(window, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
    bg:SetAllPoints()
    
    -- Border
    AC:AddWindowEdge(window, 1, 0)
    
    -- Header matching Dispel Configuration style
    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT", 8, -8)
    header:SetPoint("TOPRIGHT", -8, -8)
    header:SetHeight(50)
    
    -- Header background (dark like main UI) - same dark color as slider track
    local headerBg = AC:CreateFlatTexture(header, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
    headerBg:SetAllPoints()
    
    -- Purple accent line (hairline like main UI)
    local accent = AC:CreateFlatTexture(header, "OVERLAY", 3, AC.COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(2)
    
    -- Header border
    local hbLight = AC:CreateFlatTexture(header, "OVERLAY", 2, AC.COLORS.BORDER_LIGHT, 0.8)
    hbLight:SetPoint("BOTTOMLEFT", 0, 0)
    hbLight:SetPoint("BOTTOMRIGHT", 0, 0)
    hbLight:SetHeight(1)
    
    -- Title
    local title = AC:CreateStyledText(header, "Debuffs Configuration", 14, AC.COLORS.TEXT, "OVERLAY", "")
    title:SetPoint("LEFT", 15, 0)
    
    -- Close button (matching other pages)
    local closeBtn = AC:CreateTexturedButton(header, 36, 36, "", "button-close")
    closeBtn:SetPoint("RIGHT", -10, 0)
    closeBtn:SetScript("OnClick", function()
        window:Hide()
    end)
    local xText = AC:CreateStyledText(closeBtn, "×", 18, AC.COLORS.TEXT, "OVERLAY", "")
    xText:SetPoint("CENTER", 0, 0)
    
    -- Content area
    local content = CreateFrame("Frame", nil, window)
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -15)
    content:SetPoint("BOTTOMRIGHT", -15, 15)
    
    -- Get current settings
    local function GetSettings()
        local moreGoodiesDB = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies
        return (moreGoodiesDB and moreGoodiesDB.debuffs) or {}
    end
    
    -- Simple save function for checkbox (enhanced sliders handle their own saving)
    local function SaveSetting(key, value)
        if not AC.DB or not AC.DB.profile then return end
        if not AC.DB.profile.moreGoodies then
            AC.DB.profile.moreGoodies = {}
        end
        if not AC.DB.profile.moreGoodies.debuffs then
            AC.DB.profile.moreGoodies.debuffs = {}
        end
        AC.DB.profile.moreGoodies.debuffs[key] = value
        
        -- Refresh debuffs when settings change
        if AC.FrameManager and AC.FrameManager.RefreshDebuffSettings then
            AC.FrameManager:RefreshDebuffSettings()
        end
    end
    
    local y = -20
    
    -- Enable checkbox
    local enableLabel = AC:CreateStyledText(content, "Enable Enemy Debuff Tracking", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    enableLabel:SetPoint("TOPLEFT", 20, y)
    
    local enableCheckbox = AC:CreateFlatCheckbox(content, 20, GetSettings().enabled ~= false, function(value)
        SaveSetting("enabled", value)
        if value then
            print("|cff8B45FFArena Core:|r Enemy debuff tracking enabled")
        else
            print("|cff8B45FFArena Core:|r Enemy debuff tracking disabled")
        end
    end)
    enableCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 40
    
    -- Description for enable
    local enableDesc = AC:CreateStyledText(content, "Shows enemy debuffs on arena frames. Never shows in prep room - only in test mode and live arena matches.", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
    enableDesc:SetPoint("TOPLEFT", 20, y)
    enableDesc:SetPoint("TOPRIGHT", -20, y)
    enableDesc:SetJustifyH("LEFT")
    enableDesc:SetWordWrap(true)
    
    y = y - 40
    
    -- Player Debuffs Only checkbox
    local playerOnlyLabel = AC:CreateStyledText(content, "Player Debuffs Only", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    playerOnlyLabel:SetPoint("TOPLEFT", 20, y)
    
    local playerOnlyCheckbox = AC:CreateFlatCheckbox(content, 20, GetSettings().playerDebuffsOnly == true, function(value)
        SaveSetting("playerDebuffsOnly", value)
        if value then
            print("|cff8B45FFArena Core:|r Player debuffs only mode enabled - showing only your debuffs")
        else
            print("|cff8B45FFArena Core:|r Player debuffs only mode disabled - showing all debuffs")
        end
    end)
    playerOnlyCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 40
    
    -- Description for player debuffs only
    local playerOnlyDesc = AC:CreateStyledText(content, "When enabled, only shows debuffs that YOU create on enemies. When disabled, shows all debuffs including those from party members.", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
    playerOnlyDesc:SetPoint("TOPLEFT", 20, y)
    playerOnlyDesc:SetPoint("TOPRIGHT", -20, y)
    playerOnlyDesc:SetJustifyH("LEFT")
    playerOnlyDesc:SetWordWrap(true)
    
    y = y - 40
    
    -- Max Count enhanced slider
    AC:CreateEnhancedSliderRow(
        content,
        "Max Debuffs",
        y,
        "moreGoodies.debuffs.maxCount",
        nil,
        { scaleMin = 1, scaleMax = 8, pixelMin = 1, pixelMax = 8, isPercent = false, tooltip = "Maximum number of debuffs to display on each enemy frame. Lower values focus on the most important debuffs." }
    )
    
    y = y - 30
    
    -- Positioning header
    local positioningLabel = AC:CreateStyledText(content, "Positioning", 13, AC.COLORS.PRIMARY, "OVERLAY", "")
    positioningLabel:SetPoint("TOPLEFT", 20, y)
    
    y = y - 20
    
    -- Enhanced positioning sliders with ultra-fine precision
    AC:CreateEnhancedSliderRow(
        content,
        "Horizontal",
        y,
        "moreGoodies.debuffs.positioning.horizontal",
        "positioning_horizontal_ultra"
    )
    
    y = y - 30
    
    AC:CreateEnhancedSliderRow(
        content,
        "Vertical",
        y,
        "moreGoodies.debuffs.positioning.vertical",
        "positioning_vertical_ultra"
    )
    
    y = y - 40
    
    -- Sizing header
    local sizingLabel = AC:CreateStyledText(content, "Sizing", 13, AC.COLORS.PRIMARY, "OVERLAY", "")
    sizingLabel:SetPoint("TOPLEFT", 20, y)
    
    y = y - 20
    
    -- Enhanced scale slider
    AC:CreateEnhancedSliderRow(
        content,
        "Scale",
        y,
        "moreGoodies.debuffs.sizing.scale",
        "sizing_scale"
    )
    
    y = y - 40
    
    -- NEW FEATURE: Show Timer checkbox
    local showTimerLabel = AC:CreateStyledText(content, "Show Countdown Timers", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    showTimerLabel:SetPoint("TOPLEFT", 20, y)
    
    local showTimerCheckbox = AC:CreateFlatCheckbox(content, 20, GetSettings().showTimer ~= false, function(value)
        SaveSetting("showTimer", value)
        if value then
            print("|cff8B45FFArena Core:|r Debuff countdown timers enabled")
        else
            print("|cff8B45FFArena Core:|r Debuff countdown timers disabled")
        end
    end)
    showTimerCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 30
    
    -- NEW FEATURE: Timer Font Size slider
    AC:CreateEnhancedSliderRow(
        content,
        "Timer Font Size",
        y,
        "moreGoodies.debuffs.timerFontSize",
        "cooldown_font"
    )
    
    y = y - 50
    
    -- Test and Hide buttons (matching other pages)
    local testBtn = AC:CreateTexturedButton(content, 80, 32, "TEST", "button-test")
    testBtn:SetPoint("TOPLEFT", 20, y)
    testBtn:SetScript("OnClick", function()
        if AC.FrameManager and AC.FrameManager.TestDebuffMode then
            AC.FrameManager:TestDebuffMode()
            print("|cff8B45FFArena Core:|r Testing debuff tracking...")
        else
            print("|cff8B45FFArena Core:|r Test debuff functionality not available.")
        end
    end)
    
    local hideBtn = AC:CreateTexturedButton(content, 80, 32, "HIDE", "button-hide")
    hideBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
    hideBtn:SetScript("OnClick", function()
        if AC.FrameManager and AC.FrameManager.HideDebuffTest then
            AC.FrameManager:HideDebuffTest()
            print("|cff8B45FFArena Core:|r Debuff test hidden")
        end
    end)
    
    y = y - 40
    
    -- Final description text
    local desc = AC:CreateStyledText(content, "Enemy debuffs appear at the bottom-left of arena frames. Automatically filters out Dampening and prioritizes important crowd control and damage over time effects. Use TEST button to preview debuffs with your current settings.", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
    desc:SetPoint("TOPLEFT", 20, y)
    desc:SetPoint("TOPRIGHT", -20, y)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(true)
    
    -- Hook enhanced sliders to refresh debuffs when they change
    C_Timer.After(0.1, function()
        if AC.sliderWidgets then
            local function hookSlider(path)
                local slider = AC.sliderWidgets[path]
                if slider and slider.HookScript then
                    slider:HookScript("OnValueChanged", function()
                        if AC.FrameManager and AC.FrameManager.RefreshDebuffSettings then
                            AC.FrameManager:RefreshDebuffSettings()
                        end
                    end)
                end
            end
            
            hookSlider("moreGoodies.debuffs.maxCount")
            hookSlider("moreGoodies.debuffs.positioning.horizontal")
            hookSlider("moreGoodies.debuffs.positioning.vertical") 
            hookSlider("moreGoodies.debuffs.sizing.scale")
            hookSlider("moreGoodies.debuffs.timerFontSize") -- NEW: Timer font size
        end
    end)
    
    debuffsWindow = window
    return window
end

-- Show the debuffs window
function AC:ShowDebuffsWindow()
    local window = CreateDebuffsWindow()
    if window then
        window:Show()
    end
end
