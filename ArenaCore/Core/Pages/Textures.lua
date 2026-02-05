-- ============================================================================
-- File: ArenaCore/Core/Pages/Textures.lua (CLEAN REBUILD)
-- Purpose: Clean rebuild of Textures settings page matching Cast Bars pattern
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

local V = AC.Vanity

-- SINGLE SOURCE OF TRUTH: All defaults come from AC.DEFAULTS.textures
local function GetDefaults()
    return AC.DEFAULTS and AC.DEFAULTS.textures or {
        healthBarTexture = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture1.tga",
        useDifferentPowerBarTexture = true,
        powerBarTexture = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture1.tga",
        useDifferentCastBarTexture = false,
        castBarTexture = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture1.tga",
        positioning = { horizontal = 56, vertical = 6, spacing = 8 },
        sizing = {
            healthWidth = 128, healthHeight = 18,
            resourceWidth = 136, resourceHeight = 8
        }
    }
end

-- Get current database values with proper fallbacks
local function GetDB()
    if not AC.DB or not AC.DB.profile then return GetDefaults() end
    return AC.DB.profile.textures or GetDefaults()
end

-- Update textures immediately when settings change (NO INFINITE LOOP)
local function RefreshTextures()
    print("|cff00FFFF[Textures Clean]:|r Refreshing textures...")
    if AC.RefreshTexturesLayout then
        AC:RefreshTexturesLayout()
    else
        print("|cff00FFFF[Textures Clean]:|r RefreshTexturesLayout function not found")
    end
end

local TEXTURE_PATH = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\"
local TEXTURE_LIST = {}
for i = 1, 27 do
    table.insert(TEXTURE_LIST, "Texture " .. i)
end

local function GetTexturePath(textureName)
    local index = string.match(textureName or "", "%d+")
    if index then return TEXTURE_PATH .. "texture" .. index .. ".tga" end
    return TEXTURE_PATH .. "texture1.tga"
end

local function GetTextureName(texturePath)
    local index = string.match(texturePath or "", "texture(%d+).tga")
    if index then return "Texture " .. index end
    return "Texture 1"
end

-- Texture dropdown with live preview using CreateFlatDropdownWithPreview
local function CreateTextureDropdown(parent, label, y, dbKey, options)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 20, y)
    row:SetPoint("TOPRIGHT", -20, y)
    row:SetHeight(26)

    local labelText = AC:CreateStyledText(row, label, 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    labelText:SetPoint("LEFT", 0, 0)
    labelText:SetWidth(120)
    labelText:SetJustifyH("LEFT")

    -- Get current value from database
    local db = GetDB()
    local currentValue = db[dbKey]
    
    -- Convert stored path back to display name for texture dropdowns
    local displayValue = "Texture 1" -- default
    if currentValue and type(currentValue) == "string" and currentValue:match("texture%d+%.tga") then
        displayValue = GetTextureName(currentValue)
    end

    local function OnSelect(selectedText)
        local path = "textures." .. dbKey
        local texturePath = GetTexturePath(selectedText)
        if AC.ProfileManager and AC.ProfileManager.SetSetting then
            AC.ProfileManager:SetSetting(path, texturePath)
        else
            AC.DB.profile = AC.DB.profile or {}
            AC.DB.profile.textures = AC.DB.profile.textures or {}
            AC.DB.profile.textures[dbKey] = texturePath
        end
        if AC.RefreshBarTextures then AC:RefreshBarTextures() end
    end

    -- Dropdown with preview swatch
    local dropdown = AC:CreateFlatDropdownWithPreview(row, 200, 24, options, displayValue, OnSelect, GetTexturePath)
    dropdown:SetPoint("LEFT", labelText, "RIGHT", 10, 0)

    -- Overlay blocker to disable interactions when needed
    local blocker = CreateFrame("Frame", nil, row)
    blocker:SetAllPoints(dropdown)
    blocker:EnableMouse(true)
    blocker:Hide()

    -- Provide a simple enable/disable API on the row
    row.dropdown = dropdown
    row.blocker = blocker
    function row:SetEnabled(enabled)
        if enabled then
            self.blocker:Hide()
            self.dropdown:SetAlpha(1)
        else
            self.blocker:Show()
            self.dropdown:SetAlpha(0.4)
        end
    end

    return row
end

-- EXACT COPY of Cast Bars slider pattern for perfect compatibility
local function CreateCleanSlider(parent, label, y, dbPath, min, max, isPct)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 20, y)
    row:SetPoint("TOPRIGHT", -20, y)
    row:SetHeight(26)

    -- Label
    local labelText = AC:CreateStyledText(row, label, 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    labelText:SetPoint("LEFT", 0, 0)
    labelText:SetWidth(70)
    labelText:SetJustifyH("LEFT")

    -- Create DOWN arrow button for fine adjustment
    local downBtn = CreateFrame("Button", nil, row)
    downBtn:SetSize(16, 16)
    downBtn:SetPoint("LEFT", labelText, "RIGHT", 6, 0)
    
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

    -- Min/Max labels
    local minText = AC:CreateStyledText(row, isPct and (min .. "%") or tostring(min), 9, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
    minText:SetPoint("LEFT", downBtn, "RIGHT", 6, 0)
    minText:SetWidth(25)
    minText:SetJustifyH("RIGHT")

    -- Value display
    local valueText = AC:CreateStyledText(row, "", 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    valueText:SetWidth(70)
    valueText:SetJustifyH("CENTER")

    -- Get current value from database
    local db = GetDB()
    local keys = {}
    for k in string.gmatch(dbPath, "([^%.]+)") do
        table.insert(keys, k)
    end
    
    local currentValue = db
    for _, key in ipairs(keys) do
        currentValue = currentValue and currentValue[key]
    end
    
    -- Use default if no value exists
    local defaults = GetDefaults()
    local defaultValue = defaults
    for _, key in ipairs(keys) do
        defaultValue = defaultValue and defaultValue[key]
    end
    currentValue = currentValue or defaultValue or (isPct and 100 or 0)

    -- OnChange function - ONLY called by user interaction
    local function OnChange(value)
        -- Ensure database structure exists
        AC.DB.profile = AC.DB.profile or {}
        AC.DB.profile.textures = AC.DB.profile.textures or {}
        
        local target = AC.DB.profile.textures
        for i = 1, #keys - 1 do
            target[keys[i]] = target[keys[i]] or {}
            target = target[keys[i]]
        end
        target[keys[#keys]] = value

        -- Update display
        if isPct then
            valueText:SetText(string.format("%.0f%%", value))
        else
            valueText:SetText(string.format("%.0f", value))
        end

        -- Refresh textures
        RefreshTextures()
    end

    -- Create slider
    local slider = AC:CreateFlatSlider(row, 120, 18, min, max, currentValue, isPct, OnChange)
    slider:SetPoint("LEFT", minText, "RIGHT", 10, 0)

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

    -- Max label
    local maxText = AC:CreateStyledText(row, isPct and (max .. "%") or tostring(max), 9, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
    maxText:SetPoint("LEFT", upBtn, "RIGHT", 6, 0)
    maxText:SetWidth(20)
    maxText:SetJustifyH("LEFT")

    -- Position value text
    valueText:SetPoint("LEFT", maxText, "RIGHT", 8, 0)

    -- Initialize display WITHOUT calling OnChange
    if isPct then
        valueText:SetText(string.format("%.0f%%", currentValue))
    else
        valueText:SetText(string.format("%.0f", currentValue))
    end

    -- Button handlers
    downBtn:SetScript("OnClick", function()
        local current = slider.slider:GetValue()
        local newValue = math.max(min, current - 1)
        slider.slider:SetValue(newValue)
    end)
    
    upBtn:SetScript("OnClick", function()
        local current = slider.slider:GetValue()
        local newValue = math.min(max, current + 1)
        slider.slider:SetValue(newValue)
    end)

    return row
end

-- Clean checkbox creation
local function CreateCleanCheckbox(parent, label, y, dbPath, onToggle)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 20, y)
    row:SetPoint("TOPRIGHT", -20, y)
    row:SetHeight(26)

    local db = GetDB()
    local keys = {}
    for k in string.gmatch(dbPath, "([^%.]+)") do
        table.insert(keys, k)
    end

    local currentValue = db
    for _, key in ipairs(keys) do
        currentValue = currentValue and currentValue[key]
    end
    currentValue = currentValue or false

    local function OnChange(value)
        local path = "textures." .. dbPath
        if AC.ProfileManager and AC.ProfileManager.SetSetting then
            AC.ProfileManager:SetSetting(path, value)
        else
            AC.DB.profile = AC.DB.profile or {}
            AC.DB.profile.textures = AC.DB.profile.textures or {}
            if dbPath == "useDifferentPowerBarTexture" then
                AC.DB.profile.textures.useDifferentPowerBarTexture = value
            elseif dbPath == "useDifferentCastBarTexture" then
                AC.DB.profile.textures.useDifferentCastBarTexture = value
            end
        end
        if onToggle then pcall(onToggle, value) end
        if AC.RefreshBarTextures then AC:RefreshBarTextures() end
    end

    local checkbox = AC:CreateFlatCheckbox(row, 20, currentValue, OnChange)
    checkbox:SetPoint("LEFT", 0, 0)

    local labelText = AC:CreateStyledText(row, label, 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    labelText:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)

    return row
end

-- Main page creation function
local function CreateCleanTexturesPage(parent)
    local db = GetDB()

    if V and V.EnsureMottoStrip then V:EnsureMottoStrip(parent) end

    -- Create the top button bar
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
    
    -- Coming Soon notice
    AC:CreateComingSoonText(buttonBar, mascotBtn)
    
    -- Default Settings button removed by request

    -- Group 1: BAR TEXTURES
    local groupTextures = CreateFrame("Frame", nil, parent)
    groupTextures:SetPoint("TOPLEFT", buttonBar, "BOTTOMLEFT", 18, -18)
    groupTextures:SetPoint("TOPRIGHT", buttonBar, "BOTTOMRIGHT", -18, -18)
    groupTextures:SetHeight(220)
    AC:HairlineGroupBox(groupTextures)
    local titleTextures = AC:CreateStyledText(groupTextures, "BAR TEXTURES", 13, AC.COLORS.PRIMARY, "OVERLAY", "")
    titleTextures:SetPoint("TOPLEFT", 20, -18)

    local healthRow = CreateTextureDropdown(groupTextures, "Health Bar", -50, "healthBarTexture", TEXTURE_LIST)
    local powerRow  = CreateTextureDropdown(groupTextures, "Power Bar", -115, "powerBarTexture", TEXTURE_LIST)
    local castRow   = CreateTextureDropdown(groupTextures, "Cast Bar", -180, "castBarTexture", TEXTURE_LIST)

    -- Checkboxes that control the dependent dropdowns
    CreateCleanCheckbox(groupTextures, "Use different Power Bar texture", -85, "useDifferentPowerBarTexture", function(enabled)
        if powerRow and powerRow.SetEnabled then powerRow:SetEnabled(enabled) end
    end)
    
    -- Cast Bar texture checkbox (DISABLED - will be re-enabled in future update)
    local castBarCheckbox = CreateCleanCheckbox(groupTextures, "Use different Cast Bar texture", -150, "useDifferentCastBarTexture", function(enabled)
        if castRow and castRow.SetEnabled then castRow:SetEnabled(enabled) end
    end)
    -- Disable the checkbox and its checkButton
    if castBarCheckbox and castBarCheckbox.checkButton then
        castBarCheckbox.checkButton:Disable()
        castBarCheckbox.checkButton:SetChecked(false) -- Force unchecked
        castBarCheckbox.checkButton:SetScript("OnClick", nil) -- Remove click functionality
    end
    -- Force the database value to false
    if AC.DB and AC.DB.profile then
        AC.DB.profile.textures = AC.DB.profile.textures or {}
        AC.DB.profile.textures.useDifferentCastBarTexture = false
    end

    -- Initialize enabled state based on current DB
    if powerRow and powerRow.SetEnabled then powerRow:SetEnabled(db.useDifferentPowerBarTexture ~= false) end
    if castRow and castRow.SetEnabled then castRow:SetEnabled(false) end -- Always disabled for now

    -- Group 2: POSITIONING
    local groupPos = CreateFrame("Frame", nil, parent)
    groupPos:SetPoint("TOP", groupTextures, "BOTTOM", 0, -12)
    groupPos:SetPoint("LEFT", groupTextures, "LEFT", 0, 0)
    groupPos:SetPoint("RIGHT", groupTextures, "RIGHT", 0, 0)
    groupPos:SetHeight(140)
    AC:HairlineGroupBox(groupPos)
    local titlePos = AC:CreateStyledText(groupPos, "POSITIONING", 13, AC.COLORS.PRIMARY, "OVERLAY", "")
    titlePos:SetPoint("TOPLEFT", 20, -18)

    -- Enhanced sliders with ultra-fine precision for bar positioning
    AC:CreateEnhancedSliderRow(groupPos, "Horizontal", -50, "textures.positioning.horizontal", "texture_positioning_horizontal")
    AC:CreateEnhancedSliderRow(groupPos, "Vertical", -80, "textures.positioning.vertical", "texture_positioning_vertical")
    AC:CreateEnhancedSliderRow(groupPos, "Spacing", -110, "textures.positioning.spacing", "texture_spacing_ultra")

    -- Group 3: SIZING
    local groupSize = CreateFrame("Frame", nil, parent)
    groupSize:SetPoint("TOP", groupPos, "BOTTOM", 0, -12)
    groupSize:SetPoint("LEFT", groupPos, "LEFT", 0, 0)
    groupSize:SetPoint("RIGHT", groupPos, "RIGHT", 0, 0)
    groupSize:SetHeight(200)
    AC:HairlineGroupBox(groupSize)
    local titleSize = AC:CreateStyledText(groupSize, "SIZING", 13, AC.COLORS.PRIMARY, "OVERLAY", "")
    titleSize:SetPoint("TOPLEFT", 20, -18)

    -- Enhanced sliders with custom ranges
    AC:CreateEnhancedSliderRow(groupSize, "Health Width", -50, "textures.sizing.healthWidth", nil, { scaleMin = 1, scaleMax = 10, pixelMin = 80, pixelMax = 200, tooltip = "Health bar width" })
    AC:CreateEnhancedSliderRow(groupSize, "Health Height", -80, "textures.sizing.healthHeight", nil, { scaleMin = 1, scaleMax = 10, pixelMin = 10, pixelMax = 40, tooltip = "Health bar height" })
    AC:CreateEnhancedSliderRow(groupSize, "Resource Width", -110, "textures.sizing.resourceWidth", nil, { scaleMin = 1, scaleMax = 10, pixelMin = 80, pixelMax = 200, tooltip = "Resource bar width" })
    AC:CreateEnhancedSliderRow(groupSize, "Resource Height", -140, "textures.sizing.resourceHeight", nil, { scaleMin = 1, scaleMax = 10, pixelMin = 6, pixelMax = 20, tooltip = "Resource bar height" })
end

-- Register the clean page
AC:RegisterPage("Textures", CreateCleanTexturesPage)