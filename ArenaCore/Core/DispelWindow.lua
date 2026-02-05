-- ============================================================================
-- File: ArenaCore/Core/DispelWindow.lua (v1.0)
-- Purpose: Dispel configuration window with ArenaCore styling
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

local dispelWindow = nil
local dispelTestFrame = nil

-- Shared helper to save a dispel setting (persists into DB and disk if available)
function AC:SaveDispelSetting(key, value)
    self.DB = self.DB or {}
    self.DB.profile = self.DB.profile or {}
    self.DB.profile.moreGoodies = self.DB.profile.moreGoodies or {}
    self.DB.profile.moreGoodies.dispels = self.DB.profile.moreGoodies.dispels or {}
    self.DB.profile.moreGoodies.dispels[key] = value
    if self.SaveDatabase then self:SaveDatabase() end
end

-- Create the dispel configuration window
local function CreateDispelWindow()
    if dispelWindow then return dispelWindow end
    
    -- Main window frame
    local window = CreateFrame("Frame", "ArenaCoreDispelWindow", UIParent)
    window:SetSize(450, 600)  -- Extended height so buttons/description can sit lower
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
        AC.UIFeatures:EnableResizableUI(window, "dispelWindowScale")
    end
    
    -- Background using ArenaCore styling - same dark color as slider track
    local bg = AC:CreateFlatTexture(window, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
    bg:SetAllPoints()
    
    -- Border using ArenaCore styling
    AC:AddWindowEdge(window, 1, 0)
    
    -- Header matching main UI style
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
    local title = AC:CreateStyledText(header, "Dispel Configuration", 14, AC.COLORS.TEXT, "OVERLAY", "")
    title:SetPoint("LEFT", 15, 0)
    
    -- Close button (matching other pages)
    local closeBtn = AC:CreateTexturedButton(header, 36, 36, "", "button-close")
    closeBtn:SetPoint("RIGHT", -10, 0)
    closeBtn:SetScript("OnClick", function()
        window:Hide()
    end)
    local xText = AC:CreateStyledText(closeBtn, "×", 18, AC.COLORS.TEXT, "OVERLAY", "")
    xText:SetPoint("CENTER", 0, 0)
    
    -- Footer (persistent): houses TEST/HIDE and description
    local footer = CreateFrame("Frame", nil, window)
    footer:SetPoint("BOTTOMLEFT", 0, 15)
    footer:SetPoint("BOTTOMRIGHT", -15, 15)
    footer:SetHeight(80)
    -- Light divider above footer
    local footerDiv = AC:CreateFlatTexture(footer, "BACKGROUND", 1, AC.COLORS.BORDER_LIGHT or {0.25,0.25,0.25,1}, 1)
    footerDiv:SetPoint("TOPLEFT", 0, 0)
    footerDiv:SetPoint("TOPRIGHT", 0, 0)
    footerDiv:SetHeight(1)
    
    -- Scrollable content area above the footer (nudged upward, tighter margins)
    local scroll = CreateFrame("ScrollFrame", nil, window)
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 15, -6)
    scroll:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 15, 2)
    scroll:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", -15, 2)
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1) -- Will expand with children
    content:SetPoint("TOPLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", 0, 0)
    scroll:SetScrollChild(content)
    -- Initialize and maintain content width equal to the scroll viewport
    content:SetWidth(scroll:GetWidth())
    scroll:SetScript("OnSizeChanged", function(self, w, h)
        content:SetWidth(w)
    end)
    -- Ensure width is set after first show (GetWidth may be 0 at init)
    window:HookScript("OnShow", function()
        content:SetWidth(scroll:GetWidth())
    end)
    -- Allow scrolling when hovering over content too
    content:EnableMouseWheel(true)
    content:SetScript("OnMouseWheel", function(_, delta)
        local current = scroll:GetVerticalScroll()
        local step = 20
        scroll:SetVerticalScroll(math.max(0, current - delta * step))
    end)
    -- Clip children to avoid bleed/cut-off artifacts
    if scroll.SetClipsChildren then scroll:SetClipsChildren(true) end
    -- Build a slim purple scrollbar matching the main UI
    local scrollbar = CreateFrame("Slider", nil, window)
    scrollbar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 3, 0)
    scrollbar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 3, 0)
    scrollbar:SetWidth(16)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetMinMaxValues(0, 0)
    scrollbar:SetValue(0)
    -- Track (match Arena Frames content area)
    local trackBg = AC:CreateFlatTexture(scrollbar, "BACKGROUND", 1, (AC.COLORS and AC.COLORS.INPUT_DARK) or {0.2,0.2,0.2,1}, 1)
    trackBg:SetAllPoints()
    -- Thumb - custom compressed texture
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga")
    thumb:SetWidth(14)
    thumb:SetHeight(20)
    scrollbar:SetThumbTexture(thumb)

    -- Scroll wiring helpers
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
    window:HookScript("OnShow", function()
        UpdateScrollbar()
    end)
    
    -- Get current settings
    local function GetSettings()
        local moreGoodiesDB = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies
        return (moreGoodiesDB and moreGoodiesDB.dispels) or {}
    end
    
    -- Save setting helper (must be defined before helper function)
    local function SaveSetting(key, value)
        -- Persist into DB via shared helper
        AC:SaveDispelSetting(key, value)
        
        -- User-friendly messages (only for important toggles, not numeric sliders)
        local message
        if key == "enabled" then
            message = value and "Dispel tracking enabled" or "Dispel tracking disabled"
            print("|cff8B45FFArena Core:|r " .. message)
        elseif key == "textEnabled" then
            message = value and "Dispel text labels enabled" or "Dispel text labels disabled"
            print("|cff8B45FFArena Core:|r " .. message)
        elseif key == "showBackground" then
            message = value and "Dispel backgrounds enabled" or "Dispel backgrounds disabled"
            print("|cff8B45FFArena Core:|r " .. message)
        elseif key == "showCooldown" then
            message = value and "Dispel cooldown spirals enabled" or "Dispel cooldown spirals disabled"
            print("|cff8B45FFArena Core:|r " .. message)
        end
        -- Removed numeric setting spam (offsetX, offsetY, size, scale, etc.)
        
        -- Refresh test frame if it's visible (preserve position)
        if dispelTestFrame and dispelTestFrame:IsVisible() then
            local point, relativeTo, relativePoint, xOfs, yOfs = dispelTestFrame:GetPoint()
            AC:TestDispelCooldowns() -- Recreate test frame with new settings
            if dispelTestFrame then
                dispelTestFrame:ClearAllPoints()
                dispelTestFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
            end
        end
        
        -- CRITICAL: Fully refresh dispel frames (live arena container) to apply ALL settings
        -- This recreates the container with new size, scale, position, growth direction, etc.
        if AC.RefreshDispelFrames then
            AC:RefreshDispelFrames()
        end
    end
    
    -- Helper function to create slider with +/- buttons
    local function CreateSliderWithButtons(parent, label, yPos, key, min, max, currentValue, isPct, tooltipText)
        local row = CreateFrame("Frame", nil, parent)
        row:SetPoint("TOPLEFT", 20, yPos)
        row:SetPoint("TOPRIGHT", -20, yPos)
        row:SetHeight(26)
        
        local l = AC:CreateStyledText(row, label, 11, AC.COLORS.TEXT, "OVERLAY", "")
        l:SetPoint("LEFT", 0, 0)
        l:SetWidth(70)
        l:SetJustifyH("LEFT")
        
        -- Show 1–10 scale like Cast Bars UI
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
        
        -- Value display (show 1–10 scale for precision dialing)
        local currentScale = AC.ConvertPixelsToScale and AC:ConvertPixelsToScale(currentValue, min, max, scaleMin, scaleMax) or currentValue
        local valT = AC:CreateStyledText(row, string.format("%.1f", currentScale), 11, AC.COLORS.TEXT, "OVERLAY", "")
        valT:SetWidth(35)
        valT:SetJustifyH("CENTER")
        -- Hide duplicate readout; the enhanced slider's text input already shows the value
        valT:Hide()
        
        -- Enhanced slider with text input, convert pixels<->scale for smooth control
        -- Slightly reduced width to avoid clipping near right edge
        local enhancedSlider = AC:CreateEnhancedSlider(row, 110, 18, scaleMin, scaleMax, currentScale, label, min, max,
            function(pixels)
                SaveSetting(key, pixels)
                -- Update readout using 1–10 scale for consistency with Cast Bars
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
        
        -- Button click handlers
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
        
        -- Button hover effects
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
    
    -- Start content closer to the top to avoid unnecessary scrolling
    local y = -6
    
    -- Enable checkbox
    local enableLabel = AC:CreateStyledText(content, "Enable Dispel Tracking", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    enableLabel:SetPoint("TOPLEFT", 20, y)
    
    local enableCheckbox = AC:CreateFlatCheckbox(content, 20, GetSettings().enabled ~= false, function(value)
        SaveSetting("enabled", value)
        if value then
            print("|cff8B45FFArena Core:|r Dispel tracking enabled.")
            -- Show test frame if it exists
            if dispelTestFrame then
                dispelTestFrame:Show()
            end
        else
            print("|cff8B45FFArena Core:|r Dispel tracking disabled.")
            -- Hide test frame if it exists
            if dispelTestFrame then
                dispelTestFrame:Hide()
            end
        end
    end)
    enableCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 40
    
    -- Growth Direction dropdown
    local growthLabel = AC:CreateStyledText(content, "Growth Direction", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    growthLabel:SetPoint("TOPLEFT", 20, y)
    
    local growthOptions = {"Horizontal", "Vertical"}
    local currentGrowth = GetSettings().growthDirection or "Horizontal"
    local growthDropdown = AC:CreateFlatDropdown(content, 180, 24, growthOptions, currentGrowth, function(value)
        SaveSetting("growthDirection", value)
    end)
    growthDropdown:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 60
    
    -- Sliders wired directly to Dispel settings DB
    local s = GetSettings()
    CreateSliderWithButtons(content, "Icon Size", y, "size", 12, 64, s.size or 24, false, "Controls the size of each dispel icon in pixels.")
    y = y - 35
    
    CreateSliderWithButtons(content, "Scale", y, "scale", 50, 200, s.scale or 100, true, "Scales the entire dispel box and its contents.")
    y = y - 35

    -- Box sizing controls (width/height) so users can fine-tune the rectangle size
    CreateSliderWithButtons(content, "Box Width", y, "boxWidth", 20, 800, s.boxWidth or 260, false, "Total width of the dispel box. Minimum is auto-clamped to the content width.")
    y = y - 35
    CreateSliderWithButtons(content, "Box Height", y, "boxHeight", 20, 300, s.boxHeight or 60, false, "Total height of the dispel box. Minimum is auto-clamped to fit icons/text.")
    y = y - 35
    
    -- Rename to Horizontal/Vertical for consistency
    CreateSliderWithButtons(content, "Horizontal", y, "offsetX", -2000, 2000, s.offsetX or 0, false, "Horizontal offset of the box from its anchor.")
    y = y - 35
    
    CreateSliderWithButtons(content, "Vertical", y, "offsetY", -2000, 2000, s.offsetY or 0, false, "Vertical offset of the box from its anchor.")
    
    y = y - 40
    
    -- Show cooldown checkbox
    local cooldownLabel = AC:CreateStyledText(content, "Show Cooldown Spiral", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    cooldownLabel:SetPoint("TOPLEFT", 20, y)
    
    local cooldownCheckbox = AC:CreateFlatCheckbox(content, 20, GetSettings().showCooldown ~= false, function(value)
        SaveSetting("showCooldown", value)
    end)
    cooldownCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 30

    -- Text controls: enable toggle + scale + horizontal/vertical offsets
    local textLabel = AC:CreateStyledText(content, "Show Text", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    textLabel:SetPoint("TOPLEFT", 20, y)
    local textCheckbox = AC:CreateFlatCheckbox(content, 20, (GetSettings().textEnabled ~= false), function(value)
        SaveSetting("textEnabled", value)
    end)
    textCheckbox:SetPoint("TOPRIGHT", -25, y)

    y = y - 30
    
    -- CRITICAL: Background frame toggle (default ON)
    local bgLabel = AC:CreateStyledText(content, "Show Dispel Background Frame", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    bgLabel:SetPoint("TOPLEFT", 20, y)
    local bgCheckbox = AC:CreateFlatCheckbox(content, 20, (GetSettings().showBackground ~= false), function(value)
        SaveSetting("showBackground", value)
        
        -- CRITICAL: Update test frame background immediately if visible
        if dispelTestFrame and dispelTestFrame:IsVisible() then
            if dispelTestFrame.background then
                if value then
                    dispelTestFrame.background:Show()
                else
                    dispelTestFrame.background:Hide()
                end
            end
            if dispelTestFrame.borderContainer then
                if value then
                    dispelTestFrame.borderContainer:Show()
                else
                    dispelTestFrame.borderContainer:Hide()
                end
            end
            if dispelTestFrame.titleBar then
                if value then
                    dispelTestFrame.titleBar:Show()
                else
                    dispelTestFrame.titleBar:Hide()
                end
            end
        end
        
        -- Refresh live dispel frames to apply background visibility
        if AC.RefreshDispelFrames then
            AC:RefreshDispelFrames()
        end
    end)
    bgCheckbox:SetPoint("TOPRIGHT", -25, y)

    y = y - 35
    CreateSliderWithButtons(content, "Text Scale", y, "textScale", 50, 200, s.textScale or 100, true, "Scales the spell name below the icon.")
    y = y - 35
    CreateSliderWithButtons(content, "Text Horizontal", y, "textOffsetX", -40, 40, s.textOffsetX or 0, false, "Moves the spell name left/right.")
    y = y - 35
    CreateSliderWithButtons(content, "Text Vertical", y, "textOffsetY", -40, 40, s.textOffsetY or 0, false, "Moves the spell name up/down.")
    
    -- Footer content: TEST/HIDE + description
    local testBtn = AC:CreateTexturedButton(footer, 80, 32, "TEST", "button-test")
    testBtn:SetPoint("LEFT", 20, 0)
    testBtn:SetScript("OnClick", function()
        if AC.TestDispelCooldowns then
            AC:TestDispelCooldowns()
            print("|cff8B45FFArena Core:|r Testing dispel cooldowns...")
        else
            print("|cff8B45FFArena Core:|r Test dispel functionality not yet implemented.")
        end
    end)
    
    local hideBtn = AC:CreateTexturedButton(footer, 80, 32, "HIDE", "button-hide")
    hideBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
    hideBtn:SetScript("OnClick", function()
        if dispelTestFrame then
            dispelTestFrame:Hide()
            dispelTestFrame:SetParent(nil)
            dispelTestFrame = nil
            print("|cff8B45FFArena Core:|r Dispel test frame hidden.")
        end
    end)
    
    -- Description lives in the footer so it stays visible
    local desc = AC:CreateStyledText(footer, "Tracks enemy dispel cooldowns. Icons appear when enemies have dispel abilities and show cooldown when used. Use Test button to see cooldowns in action.", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
    desc:SetPoint("LEFT", hideBtn, "RIGHT", 20, 0)
    desc:SetPoint("RIGHT", -20, 0)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(true)
    
    -- Ensure scroll child is tall enough when needed, but reduce padding to avoid needless scroll
    if y and type(y) == "number" then
        content:SetHeight(math.abs(y) + 120)
    end
    
    dispelWindow = window
    return window
end

-- Public function to show dispel window
function AC:ShowDispelWindow()
    local window = CreateDispelWindow()
    if window then
        window:Show()
    end
end

-- Public function to hide dispel window
function AC:HideDispelWindow()
    if dispelWindow then
        dispelWindow:Hide()
    end
    -- Also hide test frame when dispel window closes
    if dispelTestFrame then
        dispelTestFrame:Hide()
        dispelTestFrame:SetParent(nil)
        dispelTestFrame = nil
    end
end

-- Test function to demonstrate dispel cooldown tracking
function AC:TestDispelCooldowns()
    -- CRITICAL: Get settings first
    local settings = self.DB and self.DB.profile and self.DB.profile.moreGoodies and self.DB.profile.moreGoodies.dispels or {}
    
    -- Hide existing test frame if it exists
    if dispelTestFrame then
        dispelTestFrame:Hide()
        dispelTestFrame:SetParent(nil)
        dispelTestFrame = nil
    end
    
    -- Create persistent test dispel icons (compact to fit squares properly)
    dispelTestFrame = CreateFrame("Frame", "ArenaCoreDispelTest", UIParent)
    dispelTestFrame:SetSize(260, 60) -- Will be resized dynamically below
    
    -- Position using saved coordinates (fallback to a sensible default)
    local pos = self.DB and self.DB.profile and self.DB.profile.moreGoodies 
        and self.DB.profile.moreGoodies.dispels 
        and self.DB.profile.moreGoodies.dispels.framePos
    local point = (pos and pos.point) or "BOTTOM"
    local relativePoint = (pos and pos.relativePoint) or "CENTER"
    local x = (pos and pos.x) or 0
    local y = (pos and pos.y) or 150
    dispelTestFrame:ClearAllPoints()
    dispelTestFrame:SetPoint(point, UIParent, relativePoint, x, y)
    dispelTestFrame:SetFrameStrata("HIGH")
    dispelTestFrame:SetMovable(true)
    dispelTestFrame:EnableMouse(true)
    dispelTestFrame:RegisterForDrag("LeftButton")
    dispelTestFrame:SetScript("OnDragStart", dispelTestFrame.StartMoving)
    dispelTestFrame:SetScript("OnDragStop", function()
        dispelTestFrame.StopMovingOrSizing(dispelTestFrame)
        -- Capture and persist the new position after dragging
        local p, relativeTo, rp, xOfs, yOfs = dispelTestFrame:GetPoint()
        AC:SaveDispelSetting("framePos", {
            point = p,
            relative = (relativeTo and (relativeTo.GetName and relativeTo:GetName()) or "UIParent"),
            relativePoint = rp,
            x = xOfs,
            y = yOfs,
        })
        print("|cff8B45FFArena Core:|r Dispel frame position saved: " .. p .. ", " .. ((relativeTo and (relativeTo.GetName and relativeTo:GetName())) or "UIParent") .. ", " .. rp .. ", " .. xOfs .. ", " .. yOfs)
    end)
    
    -- Background for visibility
    -- CRITICAL: Store background and border references for toggle functionality
    dispelTestFrame.background = AC:CreateFlatTexture(dispelTestFrame, "BACKGROUND", 1, AC.COLORS.BG, 0.95)
    dispelTestFrame.background:SetAllPoints()
    
    -- Border - create container frame to hold all border elements
    dispelTestFrame.borderContainer = CreateFrame("Frame", nil, dispelTestFrame)
    dispelTestFrame.borderContainer:SetAllPoints()
    AC:AddWindowEdge(dispelTestFrame.borderContainer, 1, 0)
    
    -- Title with close button
    dispelTestFrame.titleBar = CreateFrame("Frame", nil, dispelTestFrame)
    dispelTestFrame.titleBar:SetPoint("TOPLEFT", 4, -4)
    dispelTestFrame.titleBar:SetPoint("TOPRIGHT", -4, -4)
    dispelTestFrame.titleBar:SetHeight(20)
    
    -- Close button (standard white X, no outline, consistent with UI)
    local closeBtn = AC:CreateTexturedButton(dispelTestFrame.titleBar, 16, 16, "", "button-close")
    closeBtn:SetPoint("RIGHT", -2, 0)
    AC:CreateStyledText(closeBtn, "×", 12, AC.COLORS.TEXT, "OVERLAY", ""):SetPoint("CENTER")
    closeBtn:SetScript("OnClick", function()
        if dispelTestFrame then
            dispelTestFrame:Hide()
            dispelTestFrame:SetParent(nil)
            dispelTestFrame = nil
        end
    end)
    
    -- CRITICAL: Apply background visibility based on settings (default ON)
    local showBg = settings.showBackground ~= false
    if dispelTestFrame.background then
        if showBg then
            dispelTestFrame.background:Show()
        else
            dispelTestFrame.background:Hide()
        end
    end
    if dispelTestFrame.borderContainer then
        if showBg then
            dispelTestFrame.borderContainer:Show()
        else
            dispelTestFrame.borderContainer:Hide()
        end
    end
    if dispelTestFrame.titleBar then
        if showBg then
            dispelTestFrame.titleBar:Show()
        else
            dispelTestFrame.titleBar:Hide()
        end
    end
    
    -- Get current settings
    local settings = AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.dispels or {}
    local iconSize = settings.size or 24
    local scale = (settings.scale or 100) / 100
    local offsetX = settings.offsetX or 0
    local offsetY = settings.offsetY or 0
    local growthDirection = settings.growthDirection or "Horizontal"
    
    -- Apply scale to the ENTIRE test frame (icons/text will inherit)
    dispelTestFrame:SetScale(scale)
    -- Dynamically size the frame based on growth direction
    local numIcons = 3
    local iconSpacing = 5
    local minPadding = 2 -- allow tighter clamping so 1-scale can be very compact
    local textEnabled = (settings.textEnabled ~= false)
    local textScale = (settings.textScale or 100) / 100
    local approxTextH = math.max(6, math.floor(8 * textScale + 0.5))
    
    local baseWidth, baseHeight
    if growthDirection == "Vertical" then
        -- Vertical: narrow width, tall height
        baseWidth = iconSize + (minPadding * 2)
        local contentHeight = (numIcons * iconSize) + ((numIcons - 1) * iconSpacing) + (textEnabled and (approxTextH + 6) or 0)
        baseHeight = math.max(30, contentHeight + 6)
    else
        -- Horizontal: wide width, short height
        local contentWidth = (numIcons * iconSize) + ((numIcons - 1) * iconSpacing)
        baseWidth = contentWidth + (minPadding * 2)
        local contentHeight = iconSize + (textEnabled and (approxTextH + 6) or 0)
        baseHeight = math.max(30, contentHeight + 6)
    end
    
    local useWidth = (settings.boxWidth and tonumber(settings.boxWidth)) or baseWidth
    local useHeight = (settings.boxHeight and tonumber(settings.boxHeight)) or baseHeight
    -- Ensure the box is never smaller than the content footprint
    useWidth = math.max(useWidth, baseWidth)
    useHeight = math.max(useHeight, baseHeight)
    dispelTestFrame:SetSize(useWidth, useHeight)
    
    -- Create test dispel icons
    local dispelSpells = {
        { name = "Dispel Magic", icon = "Interface\\Icons\\Spell_Holy_DispelMagic", cooldown = 8 },
        { name = "Purge", icon = "Interface\\Icons\\Spell_Nature_Purge", cooldown = 6 },
        { name = "Mass Dispel", icon = "Interface\\Icons\\Spell_Arcane_MassDispel", cooldown = 45 }
    }
    
    for i, spell in ipairs(dispelSpells) do
        local icon = CreateFrame("Frame", nil, dispelTestFrame)
        icon:SetSize(iconSize, iconSize) -- Icon size independent; frame scale handles overall scaling
        
        -- Position based on growth direction
        if growthDirection == "Vertical" then
            -- Vertical: Stack icons downward
            icon:SetPoint("TOP", dispelTestFrame, "TOP", offsetX, -10 - (i-1) * (iconSize + iconSpacing) + offsetY)
        else
            -- Horizontal: Line up icons to the right
            icon:SetPoint("LEFT", dispelTestFrame, "LEFT", 10 + (i-1) * (iconSize + iconSpacing) + offsetX, -12 + offsetY)
        end
        
        -- Icon texture
        local texture = icon:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints()
        texture:SetTexture(spell.icon)
        texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        -- Apply black square-like border styling (same approach as Blackout Editor)
        if AC.StyleIcon then AC:StyleIcon(texture, icon, true) end
        
        -- Cooldown spiral if enabled (continuous like DR icons, using helper to block OmniCC)
        if settings.showCooldown ~= false then
            local cooldown = AC:CreateCooldown(icon, nil, "CooldownFrameTemplate")
            cooldown:SetAllPoints()
            
            -- Start continuous cooldown cycle
            local function StartCooldownCycle()
                cooldown:SetCooldown(GetTime(), spell.cooldown)
                C_Timer.After(spell.cooldown + 0.1, function()
                    if dispelTestFrame and cooldown:GetParent() then
                        StartCooldownCycle()
                    end
                end)
            end
            StartCooldownCycle()
        end
        
        -- Text settings
        local textEnabled = (settings.textEnabled ~= false)
        local textScale = (settings.textScale or 100) / 100
        local textOffX = settings.textOffsetX or 0
        local textOffY = settings.textOffsetY or 0

        -- Spell name (white with outline for readability), honor text toggle/scale/offsets
        if textEnabled then
            local name = icon:CreateFontString(nil, "OVERLAY")
            name:SetFont("Fonts\\FRIZQT__.TTF", math.max(6, math.floor(8 * textScale + 0.5)), "") -- Remove black outline for cleaner readability
            name:SetText(spell.name)
            name:SetTextColor(1, 1, 1, 1)
            -- Position text just below the icon but INSIDE the test frame
            name:SetPoint("TOP", icon, "BOTTOM", textOffX, -2 + textOffY)
        end
    end
    
    -- Removed redundant "Dispels" title text to reduce clutter

    -- Auto-cleanup when main UI closes
    if AC.configFrame then
        AC.configFrame:HookScript("OnHide", function()
            if dispelTestFrame then
                dispelTestFrame:Hide()
                dispelTestFrame:SetParent(nil)
                dispelTestFrame = nil
            end
        end)
    end
    
    -- Check if dispel tracking is enabled and hide frame if disabled
    if not (settings.enabled or false) then
        dispelTestFrame:Hide()
        -- HIDDEN: Dispel test frame status happens silently for cleaner user experience
        -- print("|cff8B45FFArena Core:|r Dispel test frame created but hidden (tracking disabled).")
    else
        -- HIDDEN: Dispel test frame display happens silently for cleaner user experience
        -- print("|cff8B45FFArena Core:|r Dispel test frame displayed. Settings: Size=" .. iconSize .. ", Scale=" .. (settings.scale or 100) .. "%, Offset=(" .. offsetX .. "," .. offsetY .. "), Cooldown=" .. tostring(settings.showCooldown ~= false))
    end
end
