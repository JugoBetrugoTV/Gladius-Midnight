-- ============================================================================
-- File: ArenaCore/Core/KickBarWindow.lua
-- Purpose: Settings window for Kick Bar feature (matches Dispel window styling)
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

local kickBarWindow = nil
local kickBarTestFrame = nil
local kickBarWasEnabled = nil

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function GetKickBarSettings()
    return AC.DB and AC.DB.profile and AC.DB.profile.kickBar or {}
end

local function SaveKickBarSetting(key, value)
    if not AC.DB or not AC.DB.profile then return end
    AC.DB.profile.kickBar = AC.DB.profile.kickBar or {}
    AC.DB.profile.kickBar[key] = value
    
    -- Refresh kick bar
    if AC.KickBar and AC.KickBar.Refresh then
        AC.KickBar:Refresh()
    end
end

-- ============================================================================
-- WINDOW CREATION
-- ============================================================================

function AC:OpenKickBarWindow()
    if kickBarWindow and kickBarWindow:IsShown() then
        kickBarWindow:Hide()
        return
    end
    
    -- FIXED: Show existing window instead of returning
    if kickBarWindow then
        kickBarWindow:Show()
        return
    end
    
    -- Create main window
    kickBarWindow = CreateFrame("Frame", "ArenaCoreKickBarWindow", UIParent)
    kickBarWindow:SetSize(450, 600)
    kickBarWindow:SetPoint("CENTER") -- Always center like Dispel window
    kickBarWindow:SetClampedToScreen(true)
    
    kickBarWindow:SetFrameStrata("DIALOG")
    kickBarWindow:SetMovable(true)
    kickBarWindow:EnableMouse(true)
    kickBarWindow:RegisterForDrag("LeftButton")
    kickBarWindow:SetScript("OnDragStart", kickBarWindow.StartMoving)
    kickBarWindow:SetScript("OnDragStop", kickBarWindow.StopMovingOrSizing)
    kickBarWindow:Hide()
    
    -- Enable resizable UI with scale drag grips
    if AC.UIFeatures and AC.UIFeatures.EnableResizableUI then
        AC.UIFeatures:EnableResizableUI(kickBarWindow, "kickBarWindowScale")
    end
    
    -- Mirror Dispel window lifecycle hooks
    kickBarWindow:HookScript("OnShow", function()
        local settings = GetKickBarSettings()
        kickBarWasEnabled = settings.enabled ~= false
        if AC.KickBar and AC.KickBar.Disable then
            AC.KickBar:Disable()
        end
    end)
    
    kickBarWindow:HookScript("OnHide", function()
        -- CRITICAL FIX: Clean up test frame when window closes
        if kickBarTestFrame then
            kickBarTestFrame:Hide()
            kickBarTestFrame:SetParent(nil)
            kickBarTestFrame = nil
        end
        
        if AC.KickBar and kickBarWasEnabled and GetKickBarSettings().enabled ~= false then
            AC.KickBar:Enable()
        end
        kickBarWasEnabled = nil
    end)
    
    -- Background using ArenaCore styling
    local bg = AC:CreateFlatTexture(kickBarWindow, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
    bg:SetAllPoints()
    
    -- Border using ArenaCore styling
    AC:AddWindowEdge(kickBarWindow, 1, 0)
    
    -- Header matching main UI style
    local header = CreateFrame("Frame", nil, kickBarWindow)
    header:SetPoint("TOPLEFT", 8, -8)
    header:SetPoint("TOPRIGHT", -8, -8)
    header:SetHeight(50)
    
    -- Header background
    local headerBg = AC:CreateFlatTexture(header, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
    headerBg:SetAllPoints()
    
    -- Purple accent line
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
    local title = AC:CreateStyledText(header, "Kick Bar Settings", 14, AC.COLORS.TEXT, "OVERLAY", "")
    title:SetPoint("LEFT", 15, 0)
    
    -- Close button
    local closeBtn = AC:CreateTexturedButton(header, 36, 36, "", "button-close")
    closeBtn:SetPoint("RIGHT", -10, 0)
    closeBtn:SetScript("OnClick", function()
        kickBarWindow:Hide()
    end)
    local xText = AC:CreateStyledText(closeBtn, "×", 18, AC.COLORS.TEXT, "OVERLAY", "")
    xText:SetPoint("CENTER", 0, 0)
    
    -- Footer (persistent): houses TEST/HIDE and description
    local footer = CreateFrame("Frame", nil, kickBarWindow)
    footer:SetPoint("BOTTOMLEFT", 0, 15)
    footer:SetPoint("BOTTOMRIGHT", -15, 15)
    footer:SetHeight(80)
    
    -- Light divider above footer
    local footerDiv = AC:CreateFlatTexture(footer, "BACKGROUND", 1, AC.COLORS.BORDER_LIGHT or {0.25,0.25,0.25,1}, 1)
    footerDiv:SetPoint("TOPLEFT", 0, 0)
    footerDiv:SetPoint("TOPRIGHT", 0, 0)
    footerDiv:SetHeight(1)
    
    -- Scrollable content area
    local scroll = CreateFrame("ScrollFrame", nil, kickBarWindow)
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 15, -6)
    scroll:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 15, 2)
    scroll:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", -15, 2)
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    content:SetPoint("TOPLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", 0, 0)
    scroll:SetScrollChild(content)
    
    content:SetWidth(scroll:GetWidth())
    scroll:SetScript("OnSizeChanged", function(self, w, h)
        content:SetWidth(w)
    end)
    
    kickBarWindow:HookScript("OnShow", function()
        content:SetWidth(scroll:GetWidth())
    end)
    
    content:EnableMouseWheel(true)
    content:SetScript("OnMouseWheel", function(_, delta)
        local current = scroll:GetVerticalScroll()
        local step = 20
        scroll:SetVerticalScroll(math.max(0, current - delta * step))
    end)
    
    if scroll.SetClipsChildren then scroll:SetClipsChildren(true) end
    
    -- Scrollbar
    local scrollbar = CreateFrame("Slider", nil, kickBarWindow)
    scrollbar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 3, 0)
    scrollbar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 3, 0)
    scrollbar:SetWidth(16)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetMinMaxValues(0, 0)
    scrollbar:SetValue(0)
    
    local trackBg = AC:CreateFlatTexture(scrollbar, "BACKGROUND", 1, (AC.COLORS and AC.COLORS.INPUT_DARK) or {0.2,0.2,0.2,1}, 1)
    trackBg:SetAllPoints()
    
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga")
    thumb:SetWidth(14)
    thumb:SetHeight(20)
    scrollbar:SetThumbTexture(thumb)
    
    local function UpdateScrollbar()
        local maxScroll = scroll:GetVerticalScrollRange()
        if maxScroll and maxScroll > 0 then
            scrollbar:Show()
            scrollbar:SetMinMaxValues(0, maxScroll)
            local currentScroll = scroll:GetVerticalScroll()
            scrollbar:SetValue(currentScroll)
        else
            scrollbar:Hide()
            scrollbar:SetMinMaxValues(0, 0)
            scrollbar:SetValue(0)
            scroll:SetVerticalScroll(0)
        end
    end
    
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scroll:SetVerticalScroll(value)
    end)
    
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollbar:GetValue()
        local step = 20
        scrollbar:SetValue(current - (delta * step))
    end)
    
    content:SetScript("OnMouseWheel", function(_, delta)
        local current = scrollbar:GetValue()
        local step = 20
        scrollbar:SetValue(current - (delta * step))
    end)
    
    scroll:SetScript("OnSizeChanged", UpdateScrollbar)
    scroll:SetScript("OnScrollRangeChanged", UpdateScrollbar)
    scroll:SetScript("OnVerticalScroll", UpdateScrollbar)
    content:SetScript("OnSizeChanged", UpdateScrollbar)
    
    kickBarWindow:HookScript("OnShow", function()
        UpdateScrollbar()
    end)
    
    -- Get current settings
    local settings = GetKickBarSettings()
    
    -- Save setting helper (mirrors Dispel window logic)
    local function SaveSetting(key, value)
        SaveKickBarSetting(key, value)

        -- Refresh test frame if it is visible (preserve position)
        if kickBarTestFrame and kickBarTestFrame:IsVisible() then
            local point, relativeTo, relativePoint, xOfs, yOfs = kickBarTestFrame:GetPoint()
            AC:TestKickBar()
            if kickBarTestFrame then
                kickBarTestFrame:ClearAllPoints()
                kickBarTestFrame:SetPoint(point or "CENTER", relativeTo or UIParent, relativePoint or "CENTER", xOfs or 0, yOfs or 0)
            end
        end

        -- Notify live Kick Bar module
        if AC.KickBar then
            if key == "enabled" then
                if value then
                    AC.KickBar:Enable()
                    -- Recreate test preview when enabling
                    if kickBarWindow and kickBarWindow:IsShown() then
                        AC:TestKickBar()
                    end
                else
                    AC.KickBar:Disable()
                    if kickBarTestFrame then
                        kickBarTestFrame:Hide()
                        kickBarTestFrame:SetParent(nil)
                        kickBarTestFrame = nil
                    end
                end
            else
                AC.KickBar:Refresh()
            end
        end
    end
    
    -- Helper function to create slider with +/- buttons (matching Dispel window)
    local function CreateSliderWithButtons(parent, label, yPos, key, min, max, currentValue, isPct, tooltipText)
        local row = CreateFrame("Frame", nil, parent)
        row:SetPoint("TOPLEFT", 20, yPos)
        row:SetPoint("TOPRIGHT", -20, yPos)
        row:SetHeight(26)
        
        local l = AC:CreateStyledText(row, label, 11, AC.COLORS.TEXT, "OVERLAY", "")
        l:SetPoint("LEFT", 0, 0)
        l:SetWidth(70)
        l:SetJustifyH("LEFT")
        
        local scaleMin, scaleMax = 1, 10
        local minT = AC:CreateStyledText(row, tostring(scaleMin), 9, AC.COLORS.TEXT, "OVERLAY", "")
        minT:SetPoint("LEFT", l, "RIGHT", 6, 0)
        minT:SetWidth(25)
        minT:SetJustifyH("RIGHT")
        
        -- DOWN button
        local downBtn = CreateFrame("Button", nil, row)
        downBtn:SetSize(16, 16)
        downBtn:SetPoint("LEFT", minT, "RIGHT", 6, 0)
        
        local downBg = downBtn:CreateTexture(nil, "BACKGROUND")
        downBg:SetAllPoints()
        downBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        local downBorder = downBtn:CreateTexture(nil, "BORDER")
        downBorder:SetAllPoints()
        downBorder:SetColorTexture(0.4, 0.4, 0.4, 1)
        downBorder:SetPoint("TOPLEFT", 1, -1)
        downBorder:SetPoint("BOTTOMRIGHT", -1, 1)
        
        local downText = downBtn:CreateFontString(nil, "OVERLAY")
        downText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        downText:SetText("-")
        downText:SetTextColor(0.8, 0.8, 0.8, 1)
        downText:SetPoint("CENTER")
        
        local currentScale = AC.ConvertPixelsToScale and AC:ConvertPixelsToScale(currentValue, min, max, scaleMin, scaleMax) or currentValue
        local valT = AC:CreateStyledText(row, string.format("%.1f", currentScale), 11, AC.COLORS.TEXT, "OVERLAY", "")
        valT:SetWidth(35)
        valT:SetJustifyH("CENTER")
        valT:Hide()
        
        local enhancedSlider = AC:CreateEnhancedSlider(row, 110, 18, scaleMin, scaleMax, currentScale, label, min, max,
            function(pixels)
                SaveSetting(key, pixels)
                local sVal = AC.ConvertPixelsToScale and AC:ConvertPixelsToScale(pixels, min, max, scaleMin, scaleMax) or pixels
                valT:SetText(string.format("%.1f", sVal))
            end,
            tooltipText
        )
        enhancedSlider:SetPoint("LEFT", downBtn, "RIGHT", 4, 0)
        
        -- UP button
        local upBtn = CreateFrame("Button", nil, row)
        upBtn:SetSize(16, 16)
        upBtn:SetPoint("LEFT", enhancedSlider, "RIGHT", 4, 0)
        
        local upBg = upBtn:CreateTexture(nil, "BACKGROUND")
        upBg:SetAllPoints()
        upBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        local upBorder = upBtn:CreateTexture(nil, "BORDER")
        upBorder:SetAllPoints()
        upBorder:SetColorTexture(0.4, 0.4, 0.4, 1)
        upBorder:SetPoint("TOPLEFT", 1, -1)
        upBorder:SetPoint("BOTTOMRIGHT", -1, 1)
        
        local upText = upBtn:CreateFontString(nil, "OVERLAY")
        upText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        upText:SetText("+")
        upText:SetTextColor(0.8, 0.8, 0.8, 1)
        upText:SetPoint("CENTER")
        
        local maxT = AC:CreateStyledText(row, tostring(scaleMax), 9, AC.COLORS.TEXT, "OVERLAY", "")
        maxT:ClearAllPoints()
        maxT:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        maxT:SetWidth(20)
        maxT:SetJustifyH("RIGHT")
        
        downBtn:SetScript("OnClick", function()
            local currentVal = enhancedSlider.slider:GetValue()
            local newVal = math.max(scaleMin, currentVal - 0.1)
            enhancedSlider.slider:SetValue(newVal)
        end)
        
        upBtn:SetScript("OnClick", function()
            local currentVal = enhancedSlider.slider:GetValue()
            local newVal = math.min(scaleMin + (scaleMax - scaleMin), currentVal + 0.1)
            enhancedSlider.slider:SetValue(newVal)
        end)
        
        downBtn:SetScript("OnEnter", function()
            downBg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
            downText:SetTextColor(1, 1, 1, 1)
        end)
        downBtn:SetScript("OnLeave", function()
            downBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
            downText:SetTextColor(0.8, 0.8, 0.8, 1)
        end)
        upBtn:SetScript("OnEnter", function()
            upBg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
            upText:SetTextColor(1, 1, 1, 1)
        end)
        upBtn:SetScript("OnLeave", function()
            upBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
            upText:SetTextColor(0.8, 0.8, 0.8, 1)
        end)
        
        return row
    end
    
    local y = -6
    
    -- Enable checkbox
    local enableLabel = AC:CreateStyledText(content, "Enable Kick Bar", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    enableLabel:SetPoint("TOPLEFT", 20, y)
    
    local enableCheckbox = AC:CreateFlatCheckbox(content, 20, settings.enabled ~= false, function(value)
        SaveSetting("enabled", value)
        if value then
            -- Re-enable tracking (don't auto-show bar)
        else
            -- Only disable tracking, don't clear test icons
            -- Test icons will naturally expire on their own
        end
    end)
    enableCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 40
    
    -- Growth Direction dropdown
    local growthLabel = AC:CreateStyledText(content, "Growth Direction", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    growthLabel:SetPoint("TOPLEFT", 20, y)
    
    local growthOptions = {"RIGHT", "LEFT", "UP", "DOWN"}
    local currentGrowth = settings.growthDirection or "RIGHT"
    local growthDropdown = AC:CreateFlatDropdown(content, 180, 24, growthOptions, currentGrowth, function(value)
        SaveSetting("growthDirection", value)
    end)
    growthDropdown:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 60
    
    -- Sliders
    local s = settings
    CreateSliderWithButtons(content, "Icon Size", y, "iconSize", 20, 80, s.iconSize or 40, false, "Controls the size of each interrupt icon in pixels.")
    y = y - 35
    
    CreateSliderWithButtons(content, "Spacing", y, "spacing", 0, 20, s.spacing or 5, false, "Space between interrupt icons.")
    y = y - 35
    
    CreateSliderWithButtons(content, "Scale", y, "scale", 50, 200, s.scale or 100, true, "Scales the entire kick bar and its contents.")
    y = y - 35
    
    -- Frame sizing controls (like Dispel window)
    CreateSliderWithButtons(content, "Bar Width", y, "barWidth", 100, 800, s.barWidth or 260, false, "Total width of the kick bar frame.")
    y = y - 35
    
    CreateSliderWithButtons(content, "Bar Height", y, "barHeight", 30, 200, s.barHeight or 60, false, "Total height of the kick bar frame.")
    y = y - 40
    
    -- Show cooldown checkbox
    local cooldownLabel = AC:CreateStyledText(content, "Show Cooldown Spiral", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    cooldownLabel:SetPoint("TOPLEFT", 20, y)
    
    local cooldownCheckbox = AC:CreateFlatCheckbox(content, 20, settings.showCooldown ~= false, function(value)
        SaveSetting("showCooldown", value)
    end)
    cooldownCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 30
    
    -- Show timer text checkbox
    local timerLabel = AC:CreateStyledText(content, "Show Timer Numbers", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    timerLabel:SetPoint("TOPLEFT", 20, y)
    
    local timerCheckbox = AC:CreateFlatCheckbox(content, 20, settings.showTimerText ~= false, function(value)
        SaveSetting("showTimerText", value)
    end)
    timerCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 30
    
    -- Show player names checkbox
    local namesLabel = AC:CreateStyledText(content, "Show Player Names", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    namesLabel:SetPoint("TOPLEFT", 20, y)
    
    local namesCheckbox = AC:CreateFlatCheckbox(content, 20, settings.showPlayerNames ~= false, function(value)
        SaveSetting("showPlayerNames", value)
    end)
    namesCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 30
    
    -- Show background checkbox
    local bgLabel = AC:CreateStyledText(content, "Show Background Frame", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    bgLabel:SetPoint("TOPLEFT", 20, y)
    
    local bgCheckbox = AC:CreateFlatCheckbox(content, 20, settings.showBackground ~= false, function(value)
        SaveSetting("showBackground", value)
    end)
    bgCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    -- Set content height
    if y and type(y) == "number" then
        content:SetHeight(math.abs(y) + 120)
    end
    
    -- Footer buttons (matching Dispel window pattern)
    local testBtn = AC:CreateTexturedButton(footer, 80, 32, "TEST", "button-test")
    testBtn:SetPoint("LEFT", 20, 0)
    testBtn:SetScript("OnClick", function()
        if AC.TestKickBar then
            AC:TestKickBar()
        end
    end)
    
    local hideBtn = AC:CreateTexturedButton(footer, 80, 32, "HIDE", "button-hide")
    hideBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
    hideBtn:SetScript("OnClick", function()
        if kickBarTestFrame then
            kickBarTestFrame:Hide()
            kickBarTestFrame:SetParent(nil)
            kickBarTestFrame = nil
        end
    end)
    
    -- Description
    local desc = AC:CreateStyledText(footer, "Tracks enemy interrupt cooldowns. Icons appear when enemies use interrupts and show cooldown timers. Use Test button to preview.", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
    desc:SetPoint("LEFT", hideBtn, "RIGHT", 20, 0)
    desc:SetPoint("RIGHT", -20, 0)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(true)
    
    kickBarWindow:Show()
end

-- Public function to hide kick bar window
function AC:HideKickBarWindow()
    if kickBarWindow then
        kickBarWindow:Hide()
    end
    -- Also hide test frame when window closes
    if kickBarTestFrame then
        kickBarTestFrame:Hide()
        kickBarTestFrame:SetParent(nil)
        kickBarTestFrame = nil
    end
    
    -- Restore live Kick Bar if enabled
    if AC.KickBar and kickBarWasEnabled and GetKickBarSettings().enabled ~= false then
        AC.KickBar:Enable()
    end
    kickBarWasEnabled = nil
end

-- Test function (matching Dispel window pattern)
function AC:TestKickBar()
    local settings = self.DB and self.DB.profile and self.DB.profile.kickBar or {}
    
    -- Hide existing test frame if it exists
    if kickBarTestFrame then
        kickBarTestFrame:Hide()
        kickBarTestFrame:SetParent(nil)
        kickBarTestFrame = nil
    end
    
    -- Create persistent test frame
    kickBarTestFrame = CreateFrame("Frame", "ArenaCoreKickBarTest", UIParent)
    kickBarTestFrame:SetSize(settings.barWidth or 260, settings.barHeight or 60)
    
    -- Position using saved coordinates (fallback to sensible default)
    local pos = settings.position
    local point = (pos and pos.point) or "BOTTOM"
    local relativePoint = (pos and pos.relativePoint) or "CENTER"
    local x = (pos and pos.x) or 0
    local y = (pos and pos.y) or 150
    kickBarTestFrame:ClearAllPoints()
    kickBarTestFrame:SetPoint(point, UIParent, relativePoint, x, y)
    kickBarTestFrame:SetFrameStrata("HIGH")
    kickBarTestFrame:SetMovable(true)
    kickBarTestFrame:EnableMouse(true)
    kickBarTestFrame:RegisterForDrag("LeftButton")
    kickBarTestFrame:SetScript("OnDragStart", kickBarTestFrame.StartMoving)
    kickBarTestFrame:SetScript("OnDragStop", function()
        kickBarTestFrame.StopMovingOrSizing(kickBarTestFrame)
        -- Capture and persist the new position
        local p, relativeTo, rp, xOfs, yOfs = kickBarTestFrame:GetPoint()
        SaveKickBarSetting("position", {
            point = p,
            relative = (relativeTo and (relativeTo.GetName and relativeTo:GetName()) or "UIParent"),
            relativePoint = rp,
            x = xOfs,
            y = yOfs,
        })
    end)
    
    -- Background
    kickBarTestFrame.background = AC:CreateFlatTexture(kickBarTestFrame, "BACKGROUND", 1, AC.COLORS.BG, 0.95)
    kickBarTestFrame.background:SetAllPoints()
    
    -- Border
    kickBarTestFrame.borderContainer = CreateFrame("Frame", nil, kickBarTestFrame)
    kickBarTestFrame.borderContainer:SetAllPoints()
    AC:AddWindowEdge(kickBarTestFrame.borderContainer, 1, 0)
    
    -- Title bar with close button
    kickBarTestFrame.titleBar = CreateFrame("Frame", nil, kickBarTestFrame)
    kickBarTestFrame.titleBar:SetPoint("TOPLEFT", 4, -4)
    kickBarTestFrame.titleBar:SetPoint("TOPRIGHT", -4, -4)
    kickBarTestFrame.titleBar:SetHeight(20)
    
    -- Close button
    local closeBtn = AC:CreateTexturedButton(kickBarTestFrame.titleBar, 16, 16, "", "button-close")
    closeBtn:SetPoint("RIGHT", -2, 0)
    AC:CreateStyledText(closeBtn, "×", 12, AC.COLORS.TEXT, "OVERLAY", ""):SetPoint("CENTER")
    closeBtn:SetScript("OnClick", function()
        if kickBarTestFrame then
            kickBarTestFrame:Hide()
            kickBarTestFrame:SetParent(nil)
            kickBarTestFrame = nil
        end
    end)
    
    -- Apply background visibility
    local showBg = settings.showBackground ~= false
    if kickBarTestFrame.background then
        kickBarTestFrame.background:SetShown(showBg)
    end
    if kickBarTestFrame.borderContainer then
        kickBarTestFrame.borderContainer:SetShown(showBg)
    end
    if kickBarTestFrame.titleBar then
        kickBarTestFrame.titleBar:SetShown(showBg)
    end
    
    -- Apply scale
    kickBarTestFrame:SetScale((settings.scale or 100) / 100)
    
    -- Create test interrupt icons
    local iconSize = settings.iconSize or 40
    local spacing = settings.spacing or 5
    local growthDirection = settings.growthDirection or "RIGHT"
    
    local testInterrupts = {
        {spellID = 2139, class = "MAGE", name = "Mage"},
        {spellID = 1766, class = "ROGUE", name = "Rogue"},
        {spellID = 47528, class = "DEATHKNIGHT", name = "DK"},
    }
    
    for i, test in ipairs(testInterrupts) do
        local icon = CreateFrame("Frame", nil, kickBarTestFrame)
        icon:SetSize(iconSize, iconSize)
        
        -- Position based on growth direction
        local offset = (i - 1) * (iconSize + spacing)
        if growthDirection == "RIGHT" then
            icon:SetPoint("LEFT", kickBarTestFrame, "LEFT", 10 + offset, 0)
        elseif growthDirection == "LEFT" then
            icon:SetPoint("RIGHT", kickBarTestFrame, "RIGHT", -10 - offset, 0)
        elseif growthDirection == "UP" then
            icon:SetPoint("BOTTOM", kickBarTestFrame, "BOTTOM", 0, 10 + offset)
        elseif growthDirection == "DOWN" then
            icon:SetPoint("TOP", kickBarTestFrame, "TOP", 0, -10 - offset)
        end
        
        -- Icon texture
        local texture = icon:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints()
        local spellTexture = C_Spell.GetSpellTexture(test.spellID)
        if spellTexture then
            texture:SetTexture(spellTexture)
        end
        texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        -- Apply black square border styling (matching Dispel/Blackout editor)
        if AC.StyleIcon then AC:StyleIcon(texture, icon, true) end
        
        -- Cooldown spiral (using helper to block OmniCC)
        if settings.showCooldown ~= false then
            local cooldown = AC:CreateCooldown(icon, nil, "CooldownFrameTemplate")
            cooldown:SetAllPoints()
            
            -- Start continuous cooldown cycle
            local duration = 15 -- Default interrupt cooldown
            local function StartCooldownCycle()
                cooldown:SetCooldown(GetTime(), duration)
                C_Timer.After(duration + 0.1, function()
                    -- FIXED: Check if frame exists AND is shown before restarting cycle
                    if kickBarTestFrame and kickBarTestFrame:IsShown() and cooldown:GetParent() then
                        StartCooldownCycle()
                    end
                end)
            end
            StartCooldownCycle()
        end
        
        -- Timer text
        if settings.showTimerText ~= false then
            local timerText = icon:CreateFontString(nil, "OVERLAY")
            timerText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
            timerText:SetPoint("CENTER")
            timerText:SetTextColor(1, 1, 1, 1)
        end
        
        -- Player name
        if settings.showPlayerNames ~= false then
            local nameText = icon:CreateFontString(nil, "OVERLAY")
            nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            nameText:SetPoint("TOP", icon, "BOTTOM", 0, -2)
            nameText:SetTextColor(1, 1, 1, 1)
            nameText:SetText(test.name)
        end
    end
    
    -- Auto-cleanup when main UI closes
    if AC.configFrame then
        AC.configFrame:HookScript("OnHide", function()
            if kickBarTestFrame then
                kickBarTestFrame:Hide()
                kickBarTestFrame:SetParent(nil)
                kickBarTestFrame = nil
            end
        end)
    end
    
    -- Check if enabled
    if settings.enabled == false then
        kickBarTestFrame:Hide()
    end
end
