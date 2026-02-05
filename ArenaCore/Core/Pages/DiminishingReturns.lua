-- COMPLETE AND CORRECTED DiminishingReturns.lua
-- ============================================================================
-- File: ArenaCore/Core/Pages/DiminishingReturns.lua (v1.1 - LUA COMMENT FIX)
-- ============================================================================
local AC = _G.ArenaCore
if not AC then return end

local V = AC.Vanity
local DB_PATH = "diminishingReturns"

-- Initialize DR categories when the page loads
local function InitializeDRDatabase()
    local db = AC.DB.profile.diminishingReturns
    db.categories = db.categories or {}
    db.iconSettings = db.iconSettings or {}
    db.customSpells = db.customSpells or {}
    db.classSpecEnabled = db.classSpecEnabled or false
    db.classSpecSelection = db.classSpecSelection or ""
end

-- Helper to link UI controls to the database
local function CreateLinkedControl(parent, y, controlType, config)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 20, y); row:SetPoint("TOPRIGHT", -20, y); row:SetHeight(26)

    local fullPath = DB_PATH .. "." .. config.path
    local keys = {}; for k in string.gmatch(fullPath, "([^%.]+)") do table.insert(keys, k) end
    
    -- CRITICAL FIX: Ensure config.val is never nil
    if config.val == nil then
        config.val = config.default or 0
        -- DEBUG DISABLED FOR PRODUCTION
        -- print("|cffFFAA00ArenaCore DR:|r Using default value for", config.path, "=", config.val)
    end

    local function OnChange(value)
        -- CRITICAL FIX: Handle nil values properly
        if value == nil then
            print("|cffFF0000ArenaCore DR Error:|r OnChange received nil value for", config.path)
            value = config.default or 0
        end
        
        local target = AC.DB.profile; for i = 1, #keys - 1 do target = target[keys[i]] end
        target[keys[#keys]] = value
        if config.valT then
            if config.isPct then 
                config.valT:SetText(string.format("%.0f%%", value))
            elseif config.compactDisplay then
                config.valT:SetText(string.format("%.0f", math.floor(value / 100)))
            else 
                config.valT:SetText(string.format("%.0f", value)) 
            end
        end
        
        -- CRITICAL FIX: Refresh DR icons to apply checkbox settings
        -- For checkboxes, we need to update the actual icon visuals or visibility
        if config.path == "enabled" then
            -- Master enable/disable - use RefreshDRLayout which handles Midnight vs regular DR
            if AC.RefreshDRLayout then
                AC:RefreshDRLayout()
            end
        elseif config.path == "showStageIndicators" or config.path == "colorCodedBorders" then
            -- Update visuals only (no repositioning). Calling UpdateDRPositions here causes a visible "jump".
            if AC.MasterFrameManager and AC.MasterFrameManager.frames then
                for i = 1, 3 do
                    local frame = AC.MasterFrameManager.frames[i]
                    if frame and frame.drIcons then
                        for category, drIcon in pairs(frame.drIcons) do
                            if drIcon and drIcon:IsShown() and drIcon.UpdateStage then
                                local stage
                                if AC.testModeEnabled then
                                    stage = math.min(math.max(i or 1, 1), 3)
                                else
                                    local diminished = drIcon.diminished or 1.0
                                    stage = 1
                                    if diminished <= 0.25 then
                                        stage = 3
                                    elseif diminished <= 0.5 then
                                        stage = 2
                                    end
                                end
                                drIcon:UpdateStage(stage)
                            end
                        end
                    end
                end
            end
        elseif config.path == "spiralAnimation.enabled" or config.path == "spiralAnimation.opacity" then
            -- Spiral Animation settings changed - refresh all DR icons
            if AC.DRSpiralAnimation and AC.DRSpiralAnimation.RefreshAllIcons then
                AC.DRSpiralAnimation:RefreshAllIcons()
            end
        else
            -- For sliders, use direct UpdatePositions for smooth real-time updates
            -- RefreshDRLayout causes a full refresh which creates a visual "jump"
            -- Direct UpdatePositions smoothly moves icons to new position
            if AC.MasterFrameManager and AC.MasterFrameManager.frames then
                for i = 1, 3 do
                    local frame = AC.MasterFrameManager.frames[i]
                    if frame and AC.UpdateDRPositions then
                        AC:UpdateDRPositions(frame)
                    end
                end
            end
        end
    end

    if controlType == "Slider" then
        local displayMin = config.min
        local displayMax = config.max
        if config.compactDisplay then
            displayMin = math.floor(config.min / 100)
            displayMax = math.floor(config.max / 100)
        end

        local l = AC:CreateStyledText(row, config.label, 11, AC.COLORS.TEXT_2, "OVERLAY", ""); l:SetPoint("LEFT", 0, 0); l:SetWidth(70); l:SetJustifyH("LEFT")
        local minT = AC:CreateStyledText(row, config.isPct and (displayMin .. "%") or tostring(displayMin), 9, AC.COLORS.TEXT_MUTED, "OVERLAY", ""); minT:SetPoint("LEFT", l, "RIGHT", 6, 0); minT:SetWidth(25); minT:SetJustifyH("RIGHT")
        
        -- Create DOWN arrow button for fine adjustment
        local downBtn = CreateFrame("Button", nil, row)
        downBtn:SetSize(16, 16)
        downBtn:SetPoint("LEFT", minT, "RIGHT", 6, 0)
        
        -- Down arrow styling
        local downBg = downBtn:CreateTexture(nil, "BACKGROUND")
        downBg:SetAllPoints()
        downBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        local downBorder = downBtn:CreateTexture(nil, "BORDER")
        downBorder:SetAllPoints()
        downBorder:SetColorTexture(0.4, 0.4, 0.4, 1)
        downBorder:SetPoint("TOPLEFT", 1, -1)
        downBorder:SetPoint("BOTTOMRIGHT", -1, 1)
        
        local downText = downBtn:CreateFontString(nil, "OVERLAY")
        downText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 12, "")
        downText:SetText("-")
        downText:SetTextColor(0.8, 0.8, 0.8, 1)
        downText:SetPoint("CENTER")

        local valT = AC:CreateStyledText(row, "", 11, AC.COLORS.TEXT_2, "OVERLAY", ""); valT:SetWidth(35); valT:SetJustifyH("CENTER")
        config.valT = valT
        local slider = AC:CreateFlatSlider(row, 120, 18, config.min, config.max, config.val, config.isPct, OnChange)
        slider:SetPoint("LEFT", downBtn, "RIGHT", 4, 0)
        
        -- CRITICAL: Wire up OnValueChanged handler (CreateFlatSlider doesn't do this)
        slider.slider:SetScript("OnValueChanged", function(self, value)
            OnChange(value)
        end)

        -- Create UP arrow button for fine adjustment  
        local upBtn = CreateFrame("Button", nil, row)
        upBtn:SetSize(16, 16)
        upBtn:SetPoint("LEFT", slider, "RIGHT", 4, 0)
        
        -- Up arrow styling
        local upBg = upBtn:CreateTexture(nil, "BACKGROUND")
        upBg:SetAllPoints()
        upBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        local upBorder = upBtn:CreateTexture(nil, "BORDER")
        upBorder:SetAllPoints()
        upBorder:SetColorTexture(0.4, 0.4, 0.4, 1)
        upBorder:SetPoint("TOPLEFT", 1, -1)
        upBorder:SetPoint("BOTTOMRIGHT", -1, 1)
        
        local upText = upBtn:CreateFontString(nil, "OVERLAY")
        upText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 12, "")
        upText:SetText("+")
        upText:SetTextColor(0.8, 0.8, 0.8, 1)
        upText:SetPoint("CENTER")

        local maxT = AC:CreateStyledText(row, config.isPct and (displayMax .. "%") or tostring(displayMax), 9, AC.COLORS.TEXT_MUTED, "OVERLAY", ""); maxT:SetPoint("LEFT", upBtn, "RIGHT", 6, 0); maxT:SetWidth(25); maxT:SetJustifyH("LEFT")
        valT:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        valT:SetPoint("LEFT", maxT, "RIGHT", 10, 0)
        
        -- Initialize the value display
        OnChange(config.val)

        -- Down arrow click handler
        downBtn:SetScript("OnClick", function()
            local currentVal = slider.slider:GetValue()
            local increment = config.compactDisplay and 100 or 1
            local newVal = math.max(config.min, currentVal - increment)
            slider.slider:SetValue(newVal)
        end)

        -- Up arrow click handler
        upBtn:SetScript("OnClick", function()
            local currentVal = slider.slider:GetValue()
            local increment = config.compactDisplay and 100 or 1
            local newVal = math.min(config.max, currentVal + increment)
            slider.slider:SetValue(newVal)
        end)
        
        -- Arrow hover effects
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
    elseif controlType == "Checkbox" then
        local l = AC:CreateStyledText(row, config.label, 11, AC.COLORS.TEXT_2, "OVERLAY", ""); l:SetPoint("LEFT", 0, 0); l:SetWidth(100); l:SetJustifyH("LEFT")
        local box = AC:CreateFlatCheckbox(row, 20, config.val, OnChange)
        box:SetPoint("RIGHT", -25, 0)
    elseif controlType == "Dropdown" then
        local l = AC:CreateStyledText(row, config.label, 11, AC.COLORS.TEXT_2, "OVERLAY", ""); l:SetPoint("LEFT", 0, 0); l:SetWidth(100); l:SetJustifyH("LEFT")
        local dropdown = AC:CreateFlatDropdown(row, 120, 24, config.options, config.val, OnChange)
        dropdown:SetPoint("LEFT", l, "RIGHT", 10, 0)
    end
    return row
end

local function CreateDiminishingReturnsPage(parent)
    local db = (AC.DB and AC.DB.profile and AC.DB.profile[DB_PATH])
    if not db then return end

    -- Initialize DR database
    InitializeDRDatabase()

    if V and V.EnsureMottoStrip then V:EnsureMottoStrip(parent) end

    -- Create the top button bar first
    local buttonBar = CreateFrame("Frame", nil, parent)
    if parent._mottoStrip then
        buttonBar:SetPoint("TOPLEFT", parent._mottoStrip, "BOTTOMLEFT", 2, -8)
        buttonBar:SetPoint("TOPRIGHT", parent._mottoStrip, "BOTTOMRIGHT", -2, -8)
    else
        buttonBar:SetPoint("TOPLEFT", 10, -52)
        buttonBar:SetPoint("TOPRIGHT", -10, -52)
    end
    buttonBar:SetHeight(40)

    local sBorder = AC:CreateFlatTexture(buttonBar, "BACKGROUND", 1, AC.COLORS.BORDER_LIGHT, 0.6)
    sBorder:SetAllPoints()
    local sFill = AC:CreateFlatTexture(buttonBar, "BACKGROUND", 2, AC.COLORS.INPUT_DARK, 1)
    sFill:SetPoint("TOPLEFT", 1, -1); sFill:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Personal Mascot button (no function)
    local mascotBtn = AC:CreateTexturedButton(buttonBar, 140, 32, "Personal Mascot", "UI\\tab-purple-matte")
    mascotBtn:SetPoint("LEFT", 6, 0)
    -- No function assigned - button disabled
    
    -- Coming Soon notice
    AC:CreateComingSoonText(buttonBar, mascotBtn)
    -- REMOVED: TEST and HIDE buttons - replaced by new unified architecture

    -- Group 1: GENERAL
    local groupGeneral = CreateFrame("Frame", nil, parent)
    groupGeneral:SetPoint("TOPLEFT", buttonBar, "BOTTOMLEFT", 18, -18)
    groupGeneral:SetPoint("TOPRIGHT", buttonBar, "BOTTOMRIGHT", -18, -18)
    groupGeneral:SetHeight(240)
    AC:HairlineGroupBox(groupGeneral)
    AC:CreateStyledText(groupGeneral, "GENERAL", 13, AC.COLORS.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)
    CreateLinkedControl(groupGeneral, -50, "Checkbox", { label = "Enable DR Tracking", path = "enabled", val = db.enabled, default = true })
    CreateLinkedControl(groupGeneral, -80, "Checkbox", { label = "Show Stage Indicators", path = "showStageIndicators", val = db.showStageIndicators, default = true })
    CreateLinkedControl(groupGeneral, -110, "Checkbox", { label = "Color Coded Borders", path = "colorCodedBorders", val = db.colorCodedBorders, default = false })
    
    -- Spiral Animation controls
    db.spiralAnimation = db.spiralAnimation or {}
    CreateLinkedControl(groupGeneral, -140, "Checkbox", { label = "Spiral Animation", path = "spiralAnimation.enabled", val = db.spiralAnimation.enabled, default = true })
    CreateLinkedControl(groupGeneral, -170, "Slider", { label = "Spiral Opacity", path = "spiralAnimation.opacity", val = db.spiralAnimation.opacity or 100, min = 1, max = 100, default = 100, isPct = true })
    
    -- Add Detailed DR Settings button (DISABLED)
    local detailedBtn = AC:CreateTexturedButton(groupGeneral, 160, 26, "Detailed DR Settings", "UI\\tab-purple-matte")
    detailedBtn:SetPoint("TOPLEFT", 20, -210)
    detailedBtn:Disable()  -- Disable the button
    detailedBtn:SetScript("OnClick", nil)  -- Remove click functionality

    -- Add arrow and "RIP" text next to disabled button
    local ripText = AC:CreateStyledText(groupGeneral, "<-------- RIP, you will be missed.", 11, {1, 0.2, 0.2, 1}, "OVERLAY", "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf")
    ripText:SetPoint("LEFT", detailedBtn, "RIGHT", 10, 0)

    -- Group 2: ROWS (dropdown selection + icon layout + dynamic positioning checkbox)
    local groupRows = CreateFrame("Frame", nil, parent)
    groupRows:SetPoint("TOP", groupGeneral, "BOTTOM", 0, -12); groupRows:SetPoint("LEFT", groupGeneral, "LEFT", 0, 0); groupRows:SetPoint("RIGHT", groupGeneral, "RIGHT", 0, 0); groupRows:SetHeight(170)
    AC:HairlineGroupBox(groupRows)
    AC:CreateStyledText(groupRows, "ROWS", 13, AC.COLORS.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)

    -- SIMPLIFIED: Single "Layout Mode" dropdown with growth directions
    db.rows = db.rows or {}
    
    local isMidnight = AC.Midnight and AC.Midnight.isMidnight
    local layoutModeValues = isMidnight and {"Left", "Right"} or {"Up", "Down", "Left", "Right"}
    local currentGrowth = db.rows.growthDirection or 4
    if isMidnight and currentGrowth ~= 3 and currentGrowth ~= 4 then
        currentGrowth = 4
    end
    local currentLayoutName = layoutModeValues[currentGrowth] or "Right"
    
    local layoutLabel = AC:CreateStyledText(groupRows, "Layout Mode", 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    layoutLabel:SetPoint("TOPLEFT", 20, -50)
    layoutLabel:SetWidth(100)
    layoutLabel:SetJustifyH("LEFT")
    
    local layoutDropdown = AC:CreateFlatDropdown(groupRows, 200, 24, layoutModeValues, currentLayoutName, function(value)
        local growthMap = isMidnight and {Left = 3, Right = 4} or {Up = 1, Down = 2, Left = 3, Right = 4}
        db.rows.growthDirection = growthMap[value] or 4
        -- Use direct UpdatePositions for smooth updates
        if AC.MasterFrameManager and AC.MasterFrameManager.frames then
            for i = 1, 3 do
                local frame = AC.MasterFrameManager.frames[i]
                if frame and AC.UpdateDRPositions then
                    AC:UpdateDRPositions(frame)
                end
            end
        end
    end)
    layoutDropdown:SetPoint("LEFT", layoutLabel, "RIGHT", 10, 0)
    
    -- ICON LAYOUT DROPDOWN (straight vs stacked)
    local iconLayoutLabel = AC:CreateStyledText(groupRows, "Icon Layout", 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    iconLayoutLabel:SetPoint("TOPLEFT", 20, -80)
    iconLayoutLabel:SetWidth(100)
    iconLayoutLabel:SetJustifyH("LEFT")
    
    local stackingModeValues = isMidnight and {"Straight"} or {"Straight", "Stacked"}
    local currentStacking = db.rows.stackingMode or "straight"
    if isMidnight then
        currentStacking = "straight"
        db.rows.stackingMode = "straight"
    end
    local currentStackingName = (currentStacking == "stacked") and "Stacked" or "Straight"
    
    local iconLayoutDropdown = AC:CreateFlatDropdown(groupRows, 200, 24, stackingModeValues, currentStackingName, function(value)
        db.rows.stackingMode = (value == "Stacked") and "stacked" or "straight"
        if isMidnight then
            db.rows.stackingMode = "straight"
        end
        if AC.RefreshDRLayout then
            AC:RefreshDRLayout()
        end
    end)
    iconLayoutDropdown:SetPoint("LEFT", iconLayoutLabel, "RIGHT", 10, 0)
    
    -- DYNAMIC POSITIONING CHECKBOX (collapse gaps when DRs expire)
    local dynamicLabel = AC:CreateStyledText(groupRows, "Dynamic Positioning", 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    dynamicLabel:SetPoint("TOPLEFT", 20, -110)
    dynamicLabel:SetWidth(150)
    dynamicLabel:SetJustifyH("LEFT")
    
    local dynamicEnabled = (db.rows.dynamicPositioning ~= false)
    if isMidnight then
        dynamicEnabled = true
        db.rows.dynamicPositioning = true
    end
    local dynamicCheckbox = AC:CreateFlatCheckbox(groupRows, 16, dynamicEnabled, function(checked)
        db.rows.dynamicPositioning = checked
        -- Use direct UpdatePositions for smooth updates
        if AC.MasterFrameManager and AC.MasterFrameManager.frames then
            for i = 1, 3 do
                local frame = AC.MasterFrameManager.frames[i]
                if frame and AC.UpdateDRPositions then
                    AC:UpdateDRPositions(frame)
                end
            end
        end
    end)
    dynamicCheckbox:SetPoint("LEFT", dynamicLabel, "RIGHT", 10, 0)
    if isMidnight and dynamicCheckbox.checkButton and dynamicCheckbox.checkButton.Disable then
        dynamicCheckbox.checkButton:Disable()
        dynamicLabel:SetTextColor(AC.COLORS.TEXT_MUTED[1], AC.COLORS.TEXT_MUTED[2], AC.COLORS.TEXT_MUTED[3], AC.COLORS.TEXT_MUTED[4] or 1)
    end
    
    -- Tooltip for dynamic positioning
    local dynamicTooltip = AC:CreateStyledText(groupRows, "Icons slide together to fill gaps when DRs expire", 9, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
    dynamicTooltip:SetPoint("TOPLEFT", dynamicLabel, "BOTTOMLEFT", 0, -4)
    dynamicTooltip:SetWidth(380)
    dynamicTooltip:SetJustifyH("LEFT")
    
    -- REMOVED: Priority Order dropdown (no longer needed with simplified pattern)

    -- Group 3: POSITIONING (test with consistent anchoring like ROWS)
    local groupPos = CreateFrame("Frame", nil, parent)
    groupPos:SetPoint("TOP", groupRows, "BOTTOM", 0, -12); groupPos:SetPoint("LEFT", groupRows, "LEFT", 0, 0); groupPos:SetPoint("RIGHT", groupRows, "RIGHT", 0, 0); groupPos:SetHeight(110)
    AC:HairlineGroupBox(groupPos)
    AC:CreateStyledText(groupPos, "POSITIONING", 13, AC.COLORS.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)
    
    -- Info text: DR icons use sliders only (not Edit Mode)
    -- Create DR positioning sliders
    AC:CreateEnhancedSliderRow(groupPos, "Horizontal", -50, "diminishingReturns.positioning.horizontal", "dr_positioning_horizontal")
    AC:CreateEnhancedSliderRow(groupPos, "Vertical", -80, "diminishingReturns.positioning.vertical", "dr_positioning_vertical")

    -- Group 4: SIZING (test with consistent anchoring like POSITIONING)
    local groupSize = CreateFrame("Frame", nil, parent)
    groupSize:SetPoint("TOP", groupPos, "BOTTOM", 0, -12); groupSize:SetPoint("LEFT", groupPos, "LEFT", 0, 0); groupSize:SetPoint("RIGHT", groupPos, "RIGHT", 0, 0); groupSize:SetHeight(140)
    AC:HairlineGroupBox(groupSize)
    AC:CreateStyledText(groupSize, "SIZING", 13, AC.COLORS.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)
    
    -- Create DR sizing sliders
    AC:CreateEnhancedSliderRow(groupSize, "Size", -50, "diminishingReturns.sizing.size", "dr_size")
    AC:CreateEnhancedSliderRow(groupSize, "Font Size", -80, "diminishingReturns.sizing.fontSize", "dr_font")
    AC:CreateEnhancedSliderRow(groupSize, "Stage Font Size", -110, "diminishingReturns.sizing.stageFontSize", "dr_stage_font")
end

AC:RegisterPage("DiminishingReturns", CreateDiminishingReturnsPage)