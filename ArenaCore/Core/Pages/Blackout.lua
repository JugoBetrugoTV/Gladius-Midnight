-- Core/Pages/Blackout.lua --
-- BUILDS the main page with the editor button --
local AC = _G.ArenaCore
if not AC then return end

local V = AC.Vanity

local function CreateBlackoutPage(parent)
    if V and V.EnsureMottoStrip then V:EnsureMottoStrip(parent) end

    -- Show Midnight restriction notice if applicable
    if AC.MidnightNotice and AC.MidnightNotice:ShouldShowNoticeForPage("Blackout") then
        AC.MidnightNotice:ShowNotice(parent, "blackout")
    end

    -- Create a single group box
    local group = CreateFrame("Frame", nil, parent)
    -- Position below motto strip if it exists
    if parent._mottoStrip then
        group:SetPoint("TOPLEFT", parent._mottoStrip, "BOTTOMLEFT", 10, -18)
        group:SetPoint("TOPRIGHT", parent._mottoStrip, "BOTTOMRIGHT", -10, -18)
    else
        group:SetPoint("TOPLEFT", 10, -60)
        group:SetPoint("TOPRIGHT", -10, -60)
    end
    group:SetHeight(140)
    AC:HairlineGroupBox(group)
    AC:CreateStyledText(group, "GENERAL", 13, AC.COLORS.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)

    -- Button to open the spell editor
    local editorBtn = AC:CreateTexturedButton(group, 200, 32, "Configure Blackout Auras", "UI\\tab-purple-matte")
    editorBtn:SetPoint("TOP", -50, -50)
    editorBtn:SetScript("OnClick", function()
        if AC.OpenBlackoutEditor then
            AC:OpenBlackoutEditor()
        end
    end)

    -- Enable checkbox
    local function OnBlackoutToggle(checked)
        -- Update database
        if AC.DB and AC.DB.profile and AC.DB.profile.blackout then
            AC.DB.profile.blackout.enabled = checked
        end
        
        if checked then
            print("|cff8B45FFArena Core:|r Blackout feature enabled")
        else
            print("|cff8B45FFArena Core:|r Blackout feature disabled")
        end
    end

    local db = (AC.DB and AC.DB.profile and AC.DB.profile.blackout) or {}
    local enableCheckbox = AC:CreateFlatCheckbox(group, 20, db.enabled ~= false, OnBlackoutToggle)
    enableCheckbox:SetPoint("TOPLEFT", 20, -90)
    
    local enableLabel = AC:CreateStyledText(group, "Enable Blackout Feature", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    enableLabel:SetPoint("LEFT", enableCheckbox, "RIGHT", 8, 0)

    -- Scroll hint in gray space between boxes
    local hintContainer = CreateFrame("Frame", nil, parent)
    hintContainer:SetPoint("TOPLEFT", group, "BOTTOMLEFT", 0, -8)
    hintContainer:SetPoint("TOPRIGHT", group, "BOTTOMRIGHT", 0, -8)
    hintContainer:SetHeight(40)
    
    -- Important icon (purple exclamation triangle) - WoW built-in atlas
    local hintIcon = hintContainer:CreateTexture(nil, "ARTWORK")
    hintIcon:SetSize(32, 32)
    hintIcon:SetPoint("LEFT", hintContainer, "LEFT", 20, 0)
    hintIcon:SetAtlas("Crosshair_Important_128")
    
    -- Scroll hint text
    local scrollHint = AC:CreateStyledText(hintContainer, "Scroll down to learn how Blackout works", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    scrollHint:SetPoint("LEFT", hintIcon, "RIGHT", 10, 0)

    -- Effect Customization Group (moved down to make room)
    local effectGroup = CreateFrame("Frame", nil, parent)
    effectGroup:SetPoint("TOPLEFT", hintContainer, "BOTTOMLEFT", 0, -8)
    effectGroup:SetPoint("TOPRIGHT", hintContainer, "BOTTOMRIGHT", 0, -8)
    effectGroup:SetHeight(320)
    AC:HairlineGroupBox(effectGroup)
    
    local effectTitle = AC:CreateStyledText(effectGroup, "EFFECT CUSTOMIZATION", 13, AC.COLORS.PRIMARY, "OVERLAY", "")
    effectTitle:SetPoint("TOPLEFT", 20, -18)
    
    -- Effect Type Dropdown
    local dropdownLabel = AC:CreateStyledText(effectGroup, "Effect Style:", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    dropdownLabel:SetPoint("TOPLEFT", 20, -50)
    
    local effectTypes = {
        {value = "default", label = "Default (Black)", color = {r=0, g=0, b=0}},
        {value = "fire", label = "Fire (Orange)", color = {r=1, g=0.3, b=0}},
        {value = "ice", label = "Frost (Blue)", color = {r=0, g=0.5, b=1}},
        {value = "poison", label = "Poison (Green)", color = {r=0, g=0.8, b=0}},
        {value = "shadow", label = "Shadow (Purple)", color = {r=0.5, g=0, b=0.8}}
    }
    
    -- Create display options array
    local displayOptions = {}
    local valueToDisplay = {}
    for _, effectType in ipairs(effectTypes) do
        table.insert(displayOptions, effectType.label)
        valueToDisplay[effectType.value] = effectType.label
    end
    
    -- Get current display text
    local currentEffect = db.effectType or "default"
    local currentDisplay = valueToDisplay[currentEffect] or "Default (Black)"
    
    -- Create styled dropdown (matching Class Packs style)
    local dropdown = AC:CreateFlatDropdown(effectGroup, 200, 24, displayOptions, currentDisplay, function(selectedLabel)
        -- Find the value for the selected label
        for _, effectType in ipairs(effectTypes) do
            if effectType.label == selectedLabel then
                db.effectType = effectType.value
                
                -- Update color for preset
                if effectType.color then
                    db.customColor = {r = effectType.color.r, g = effectType.color.g, b = effectType.color.b}
                end
                
                print("|cff8B45FFArena Core:|r Blackout effect changed to: " .. selectedLabel)
                break
            end
        end
    end)
    dropdown:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", 0, -8)
    
    -- Texture Overlay Section
    local textureLabel = AC:CreateStyledText(effectGroup, "Texture Overlay (Optional):", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    textureLabel:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -20)
    
    -- Preview button (next to label) - WITH NATIVE WOW GLOW (SQUARE)
    local previewBtn = CreateFrame("Button", "ArenaCoreBlackoutPreviewButton", effectGroup, "BackdropTemplate")
    previewBtn:SetSize(32, 32)
    previewBtn:SetPoint("LEFT", textureLabel, "RIGHT", 10, 0)
    previewBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 16,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    previewBtn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    previewBtn:SetBackdropBorderColor(1, 0.84, 0, 1)  -- Gold border for visibility
    
    -- Add icon to square button (eye icon for preview)
    local previewIcon = previewBtn:CreateTexture(nil, "ARTWORK")
    previewIcon:SetSize(24, 24)
    previewIcon:SetPoint("CENTER")
    previewIcon:SetAtlas("transmog-icon-hidden")  -- Eye icon
    previewIcon:SetVertexColor(1, 0.84, 0, 1)  -- Gold color
    
    -- Tooltip for square button
    previewBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Preview Textures", 1, 1, 1)
        GameTooltip:AddLine("Click to view all available texture overlays", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
        
        self:SetBackdropColor(0.25, 0.25, 0.25, 1)
        self:SetBackdropBorderColor(1, 1, 1, 1)  -- White border on hover
        previewIcon:SetVertexColor(1, 1, 1, 1)
    end)
    
    previewBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        self:SetBackdropBorderColor(1, 0.84, 0, 1)  -- Back to gold
        previewIcon:SetVertexColor(1, 0.84, 0, 1)
    end)
    
    -- Create CUSTOM controlled glow using WoW's proc glow assets (we control everything)
    local glowFrame = CreateFrame("Frame", nil, previewBtn)
    glowFrame:SetAllPoints(previewBtn)
    glowFrame:SetFrameLevel(previewBtn:GetFrameLevel() + 10)

    -- Create the main glow texture (spinning flipbook effect)
    local glowTexture = glowFrame:CreateTexture(nil, "OVERLAY")
    glowTexture:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook", true)
    glowTexture:SetSize(50, 50)
    glowTexture:SetPoint("CENTER", previewBtn, "CENTER", 0, 0)
    glowTexture:SetBlendMode("ADD")
    glowTexture:SetVertexColor(1, 0.84, 0, 1)  -- Gold color

    -- Create secondary glow texture (alt glow effect)
    local glowBorder = glowFrame:CreateTexture(nil, "OVERLAY")
    glowBorder:SetAtlas("UI-HUD-RotationHelper-ProcAltGlow", true)
    glowBorder:SetSize(50, 50)
    glowBorder:SetPoint("CENTER", previewBtn, "CENTER", 0, 0)
    glowBorder:SetBlendMode("ADD")
    glowBorder:SetVertexColor(1, 0.84, 0, 1)  -- Gold color

    -- Flipbook animation for the spinning particle effect (matches WoW's ActionButtonSpellAlerts)
    local flipAnim = glowTexture:CreateAnimationGroup()
    flipAnim:SetLooping("REPEAT")

    local flipBook = flipAnim:CreateAnimation("FlipBook")
    flipBook:SetFlipBookRows(6)
    flipBook:SetFlipBookColumns(5)
    flipBook:SetFlipBookFrames(30)
    flipBook:SetDuration(1.0)  -- 1 second for full rotation cycle

    flipAnim:Play()

    -- Pulsing scale animation for intensity
    local pulseAnim = glowFrame:CreateAnimationGroup()
    pulseAnim:SetLooping("BOUNCE")

    local scaleIn = pulseAnim:CreateAnimation("Scale")
    scaleIn:SetScale(1.1, 1.1)
    scaleIn:SetDuration(0.8)
    scaleIn:SetSmoothing("IN_OUT")
    scaleIn:SetOrder(1)

    local scaleOut = pulseAnim:CreateAnimation("Scale")
    scaleOut:SetScale(0.95, 0.95)
    scaleOut:SetDuration(0.8)
    scaleOut:SetSmoothing("IN_OUT")
    scaleOut:SetOrder(2)

    pulseAnim:Play()

    -- Store reference globally for page switch persistence
    _G.ArenaCoreBlackoutPreviewBtn = previewBtn
    
    -- Add attention text next to button
    local attentionText = AC:CreateStyledText(effectGroup, "<----- CLICK THIS FIRST", 12, {r=1, g=0.84, b=0, a=1}, "OVERLAY", "OUTLINE")
    attentionText:SetPoint("LEFT", previewBtn, "RIGHT", 8, 0)
    attentionText:SetFont(AC.CUSTOM_FONT, 12, "OUTLINE, THICKOUTLINE")
    attentionText:SetTextColor(1, 0.84, 0, 1)  -- Gold color
    
    -- Pulsing animation for attention text
    local textAnim = attentionText:CreateAnimationGroup()
    textAnim:SetLooping("BOUNCE")
    
    local textFade = textAnim:CreateAnimation("Alpha")
    textFade:SetFromAlpha(1.0)
    textFade:SetToAlpha(0.4)
    textFade:SetDuration(1.0)
    textFade:SetSmoothing("IN_OUT")
    
    textAnim:Play()
    
    local textureCheckbox = AC:CreateFlatCheckbox(effectGroup, 20, db.useTexture == true, function(checked)
        db.useTexture = checked
        
        -- Enable/disable effect dropdown based on checkbox AND texture selection
        local currentTexturePath = db.texturePath or ""
        if checked and currentTexturePath ~= "" then
            -- Checkbox ON + texture selected = disable effect dropdown
            dropdown:SetAlpha(0.5)
            if dropdown.button then
                dropdown.button:Disable()
            end
            print("|cff8B45FFArena Core:|r Texture overlay enabled (Effect Style disabled)")
        else
            -- Checkbox OFF or no texture = enable effect dropdown
            dropdown:SetAlpha(1.0)
            if dropdown.button then
                dropdown.button:Enable()
            end
            if checked then
                print("|cff8B45FFArena Core:|r Texture overlay enabled")
            else
                print("|cff8B45FFArena Core:|r Texture overlay disabled (Effect Style re-enabled)")
            end
        end
    end)
    textureCheckbox:SetPoint("TOPLEFT", textureLabel, "BOTTOMLEFT", 0, -8)
    
    local textureCheckLabel = AC:CreateStyledText(effectGroup, "Enable Texture Overlay", 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    textureCheckLabel:SetPoint("LEFT", textureCheckbox, "RIGHT", 8, 0)
    
    -- Texture Style Dropdown
    local textureStyleLabel = AC:CreateStyledText(effectGroup, "Texture Style:", 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    textureStyleLabel:SetPoint("TOPLEFT", textureCheckbox, "BOTTOMLEFT", 0, -12)
    
    -- Warning message about texture overriding effect style
    local textureWarning = AC:CreateStyledText(effectGroup, "(Overrides Effect Style color)", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
    textureWarning:SetPoint("LEFT", textureStyleLabel, "RIGHT", 8, 0)
    
    -- Define available textures (Quality BarFill Flipbook textures + Experience Bar Flares)
    local textureOptions = {
        {
            name = "None",
            path = "",
            displayName = "None",
            isAtlas = false
        },
        -- Quality BarFill Flipbook Textures (Tier 5 to Tier 1)
        {
            name = "Gold Spender",
            path = "Quality-BarFill-Flipbook-T5-x2",
            displayName = "Gold Spender",
            isAtlas = true
        },
        {
            name = "Cringe Queue Comp",
            path = "Quality-BarFill-Flipbook-T4-x2",
            displayName = "Cringe Queue Comp",
            isAtlas = true
        },
        {
            name = "MMR Below Sea Level",
            path = "Quality-BarFill-Flipbook-T3-x2",
            displayName = "MMR Below Sea Level",
            isAtlas = true
        },
        {
            name = "MMR Millionaire",
            path = "Quality-BarFill-Flipbook-T2-x2",
            displayName = "MMR Millionaire",
            isAtlas = true
        },
        {
            name = "Low MMR Enjoyer",
            path = "Quality-BarFill-Flipbook-T1-x2",
            displayName = "Low MMR Enjoyer",
            isAtlas = true
        },
        -- Void Priest Texture
        {
            name = "Don't Get Mind Control DC'd",
            path = "Unit_Priest_Void_Fill_Flipbook",
            displayName = "Don't Get Mind Control DC'd",
            isAtlas = true
        },
        -- UI Frame Textures
        {
            name = "Bloodlust Bar",
            path = "UI-Frame-DastardlyDuos-ProgressBar-Fill-Red",
            displayName = "Bloodlust Bar",
            isAtlas = true
        },
        -- External Indicator Textures (positioned above health bar)
        {
            name = "Bigdam™ Certified",
            path = "1028137",
            displayName = "Bigdam™ Certified",
            isAtlas = false,
            isExternal = true
        },
        {
            name = "CR Protection Plan™",
            path = "charactercreate-icon-requiredarrow",
            displayName = "CR Protection Plan™",
            isAtlas = true,
            isExternal = true
        },
        -- Skillbar Textures (1x4 horizontal strip flipbooks)
        {
            name = "MMR Tinkering Kit",
            path = "Skillbar_Fill_Flipbook_Blacksmithing",
            displayName = "MMR Tinkering Kit",
            isAtlas = true
        },
        {
            name = "Copium Elixir +15%",
            path = "Skillbar_Fill_Flipbook_Alchemy",
            displayName = "Copium Elixir +15%",
            isAtlas = true
        },
        {
            name = "Catch of the Day: 0 CR Gain",
            path = "Skillbar_Fill_Flipbook_Fishing",
            displayName = "Catch of the Day: 0 CR Gain",
            isAtlas = true
        }
    }
    
    -- Create display options and mapping
    local textureDisplayOptions = {}
    local textureNameToPath = {}
    local texturePathToName = {}
    local textureNameToIsAtlas = {}  -- Track which textures are atlas vs file paths
    local textureNameToIsExternal = {}  -- Track which textures are external indicators
    
    for _, texture in ipairs(textureOptions) do
        table.insert(textureDisplayOptions, texture.displayName)
        textureNameToPath[texture.displayName] = texture.path
        texturePathToName[texture.path] = texture.displayName
        textureNameToIsAtlas[texture.displayName] = texture.isAtlas
        textureNameToIsExternal[texture.displayName] = texture.isExternal or false  -- Store external flag
    end
    
    -- Get current texture name
    local currentTexturePath = db.texturePath or ""
    local currentTextureName = texturePathToName[currentTexturePath] or "None"
    
    -- ========================================================================
    -- EXTERNAL INDICATOR OFFSET SLIDERS (CR Protection Plan & Bigdam Certified)
    -- Create these BEFORE the dropdown so the callback can reference them
    -- ========================================================================
    
    -- Create anchor frame for positioning (where the dropdown will be)
    local dropdownAnchor = CreateFrame("Frame", nil, effectGroup)
    dropdownAnchor:SetPoint("TOPLEFT", textureStyleLabel, "BOTTOMLEFT", 0, -8)
    dropdownAnchor:SetSize(200, 24)
    
    -- Helper function to create slider with +/- buttons (copied from Arena Frames page)
    local function CreateOffsetSlider(parent, label, anchorFrame, yOffset, dbKey, currentValue)
        local row = CreateFrame("Frame", nil, parent)
        row:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, yOffset)
        row:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT", 0, yOffset)
        row:SetHeight(26)
        
        local labelText = AC:CreateStyledText(row, label, 11, AC.COLORS.TEXT_2, "OVERLAY", "")
        labelText:SetPoint("LEFT", row, "LEFT", 0, 0)
        labelText:SetWidth(120)
        labelText:SetJustifyH("LEFT")
        
        -- Create DOWN button (-)
        local downBtn = CreateFrame("Button", nil, row)
        downBtn:SetSize(16, 16)
        downBtn:SetPoint("LEFT", labelText, "RIGHT", 6, 0)
        
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
        
        -- Create slider (CreateFlatSlider doesn't set onChange callback, we must do it manually)
        local sliderContainer = AC:CreateFlatSlider(row, 150, 20, -100, 100, currentValue, false)
        sliderContainer:SetPoint("LEFT", downBtn, "RIGHT", 4, 0)
        
        -- CRITICAL FIX: Manually set OnValueChanged since CreateFlatSlider doesn't do it
        local slider = sliderContainer.slider
        slider:SetScript("OnValueChanged", function(self, value)
            -- Round to integer
            value = math.floor(value + 0.5)
            
            -- Save to database
            AC.DB.profile.blackout[dbKey] = value
            
            -- If test mode is active, refresh all nameplates to show new position
            if AC.DB.profile.blackout.externalTestMode and AC.BlackoutCustomization and AC.BlackoutCustomization.RefreshAllNameplatesForTest then
                AC.BlackoutCustomization:RefreshAllNameplatesForTest()
            end
        end)
        
        -- Create UP button (+)
        local upBtn = CreateFrame("Button", nil, row)
        upBtn:SetSize(16, 16)
        upBtn:SetPoint("LEFT", sliderContainer, "RIGHT", 4, 0)
        
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
        
        -- Wire up buttons
        downBtn:SetScript("OnClick", function()
            local current = slider:GetValue()
            slider:SetValue(math.max(-100, current - 1))
        end)
        
        upBtn:SetScript("OnClick", function()
            local current = slider:GetValue()
            slider:SetValue(math.min(100, current + 1))
        end)
        
        return row
    end
    
    -- Helper function to create scale slider with +/- buttons (for Bigdam/CR Protection scale)
    local function CreateScaleSlider(parent, label, anchorFrame, yOffset, dbKey, currentValue)
        local row = CreateFrame("Frame", nil, parent)
        row:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, yOffset)
        row:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT", 0, yOffset)
        row:SetHeight(26)
        
        local labelText = AC:CreateStyledText(row, label, 11, AC.COLORS.TEXT_2, "OVERLAY", "")
        labelText:SetPoint("LEFT", row, "LEFT", 0, 0)
        labelText:SetWidth(120)
        labelText:SetJustifyH("LEFT")
        
        -- Create DOWN button (-)
        local downBtn = CreateFrame("Button", nil, row)
        downBtn:SetSize(16, 16)
        downBtn:SetPoint("LEFT", labelText, "RIGHT", 6, 0)
        
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
        
        -- Create slider (CreateFlatSlider doesn't set onChange callback, we must do it manually)
        local sliderContainer = AC:CreateFlatSlider(row, 150, 20, 50, 200, currentValue, false)
        sliderContainer:SetPoint("LEFT", downBtn, "RIGHT", 4, 0)
        
        -- CRITICAL FIX: Manually set OnValueChanged since CreateFlatSlider doesn't do it
        local slider = sliderContainer.slider
        slider:SetScript("OnValueChanged", function(self, value)
            -- Round to integer
            value = math.floor(value + 0.5)
            
            -- Save to database
            AC.DB.profile.blackout[dbKey] = value
            
            -- If test mode is active, refresh all nameplates to show new scale
            if AC.DB.profile.blackout.externalTestMode and AC.BlackoutCustomization and AC.BlackoutCustomization.RefreshAllNameplatesForTest then
                AC.BlackoutCustomization:RefreshAllNameplatesForTest()
            end
        end)
        
        -- Create UP button (+)
        local upBtn = CreateFrame("Button", nil, row)
        upBtn:SetSize(16, 16)
        upBtn:SetPoint("LEFT", sliderContainer, "RIGHT", 4, 0)
        
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
        
        -- Wire up buttons
        downBtn:SetScript("OnClick", function()
            local current = slider:GetValue()
            slider:SetValue(math.max(50, current - 5))  -- 5% increments
        end)
        
        upBtn:SetScript("OnClick", function()
            local current = slider:GetValue()
            slider:SetValue(math.min(200, current + 5))  -- 5% increments
        end)
        
        return row
    end
    
    -- Create horizontal offset slider (8px below dropdown)
    local horizontalSlider = CreateOffsetSlider(
        effectGroup,
        "Horizontal Offset",
        dropdownAnchor,
        -8,
        "externalOffsetX",
        db.externalOffsetX or 0
    )
    
    -- Create vertical offset slider (8px below horizontal slider = 38px below dropdown)
    local verticalSlider = CreateOffsetSlider(
        effectGroup,
        "Vertical Offset",
        dropdownAnchor,
        -38,
        "externalOffsetY",
        db.externalOffsetY or 5
    )
    
    -- Create scale slider (8px below vertical slider = 68px below dropdown)
    local scaleSlider = CreateScaleSlider(
        effectGroup,
        "Scale/Size",
        dropdownAnchor,
        -68,
        "externalScale",
        db.externalScale or 100
    )
    
    -- Function to show/hide sliders based on selected texture
    local function UpdateSliderVisibility()
        local isExternal = db.textureIsExternal or false
        local selectedTexture = db.texturePath or ""
        
        if isExternal then
            horizontalSlider:Show()
            verticalSlider:Show()
            
            -- Show scale slider only for Bigdam Certified and CR Protection Plan
            if selectedTexture == "1028137" or selectedTexture == "charactercreate-icon-requiredarrow" then
                scaleSlider:Show()
            else
                scaleSlider:Hide()
            end
        else
            horizontalSlider:Hide()
            verticalSlider:Hide()
            scaleSlider:Hide()
        end
    end
    
    -- Initial visibility
    UpdateSliderVisibility()
    
    -- ========================================================================
    -- TEST MODE BUTTONS (for ALL textures - external AND health bar)
    -- ========================================================================
    
    -- Create TEST TEXTURES button (green, like Edit Mode)
    local testButton = CreateFrame("Button", nil, effectGroup)
    testButton:SetSize(110, 24)
    testButton:SetPoint("LEFT", dropdownAnchor, "RIGHT", 8, 0)
    
    -- Green background (darker, more vibrant for better contrast)
    local testBg = testButton:CreateTexture(nil, "BACKGROUND")
    testBg:SetAllPoints()
    testBg:SetColorTexture(0.1, 0.5, 0.1, 1)  -- Darker, more saturated green
    
    -- Border
    local testBorder = testButton:CreateTexture(nil, "BORDER")
    testBorder:SetPoint("TOPLEFT", 1, -1)
    testBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    testBorder:SetColorTexture(0.2, 0.7, 0.2, 1)  -- Darker green border
    
    -- Text
    local testText = testButton:CreateFontString(nil, "OVERLAY")
    testText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 11, "")
    testText:SetText("TEST TEXTURE")
    testText:SetTextColor(1, 1, 1, 1)
    testText:SetPoint("CENTER")
    
    -- Hover effect
    testButton:SetScript("OnEnter", function()
        testBg:SetColorTexture(0.15, 0.6, 0.15, 1)  -- Brighter on hover
        testBorder:SetColorTexture(0.3, 0.8, 0.3, 1)
    end)
    testButton:SetScript("OnLeave", function()
        testBg:SetColorTexture(0.1, 0.5, 0.1, 1)  -- Back to normal
        testBorder:SetColorTexture(0.2, 0.7, 0.2, 1)
    end)
    
    -- Click handler - handles BOTH external and health bar textures
    testButton:SetScript("OnClick", function()
        local isExternal = db.textureIsExternal or false
        
        if isExternal then
            -- External indicator test mode (Bigdam/CR Protection)
            db.externalTestMode = true
            db.healthBarTestMode = false  -- Mutually exclusive
            print("|cff8B45FF[ArenaCore]|r |TInterface\\RaidFrame\\ReadyCheck-Ready:16:16|t External Indicator Test Mode |cff00FF00ON|r - Preview active on all nameplates")
        else
            -- Health bar texture test mode (all other textures)
            db.healthBarTestMode = true
            db.externalTestMode = false  -- Mutually exclusive
            print("|cff8B45FF[ArenaCore]|r |TInterface\\RaidFrame\\ReadyCheck-Ready:16:16|t Health Bar Texture Test Mode |cff00FF00ON|r - Preview active on all nameplates")
        end
        
        -- Refresh all nameplates to show test textures
        if AC.BlackoutCustomization and AC.BlackoutCustomization.RefreshAllNameplatesForTest then
            AC.BlackoutCustomization:RefreshAllNameplatesForTest()
        end
    end)
    
    -- Create OFF button (red)
    local offButton = CreateFrame("Button", nil, effectGroup)
    offButton:SetSize(50, 24)
    offButton:SetPoint("LEFT", testButton, "RIGHT", 4, 0)
    
    -- Red background
    local offBg = offButton:CreateTexture(nil, "BACKGROUND")
    offBg:SetAllPoints()
    offBg:SetColorTexture(0.6, 0.2, 0.2, 0.8)  -- Red
    
    -- Border
    local offBorder = offButton:CreateTexture(nil, "BORDER")
    offBorder:SetPoint("TOPLEFT", 1, -1)
    offBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    offBorder:SetColorTexture(0.8, 0.3, 0.3, 1)  -- Lighter red border
    
    -- Text
    local offText = offButton:CreateFontString(nil, "OVERLAY")
    offText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 11, "")
    offText:SetText("OFF")
    offText:SetTextColor(1, 1, 1, 1)
    offText:SetPoint("CENTER")
    
    -- Hover effect
    offButton:SetScript("OnEnter", function()
        offBg:SetColorTexture(0.7, 0.25, 0.25, 1)  -- Brighter red on hover
        offBorder:SetColorTexture(1, 0.4, 0.4, 1)
    end)
    offButton:SetScript("OnLeave", function()
        offBg:SetColorTexture(0.6, 0.2, 0.2, 0.8)  -- Back to normal
        offBorder:SetColorTexture(0.8, 0.3, 0.3, 1)
    end)
    
    -- Click handler - disables BOTH test modes
    offButton:SetScript("OnClick", function()
        db.externalTestMode = false
        db.healthBarTestMode = false
        print("|cff8B45FF[ArenaCore]|r |TInterface\\RaidFrame\\ReadyCheck-NotReady:16:16|t Texture Test Mode |cffFF0000OFF|r - Preview disabled")
        -- Refresh all nameplates to hide test textures
        if AC.BlackoutCustomization and AC.BlackoutCustomization.RefreshAllNameplatesForTest then
            AC.BlackoutCustomization:RefreshAllNameplatesForTest()
        end
    end)
    
    -- Function to show/hide test buttons based on selected texture
    local function UpdateTestButtonVisibility()
        local selectedTexture = db.texturePath or ""
        -- Show test buttons for ALL textures (not just external)
        if selectedTexture ~= "" then
            testButton:Show()
            offButton:Show()
        else
            testButton:Hide()
            offButton:Hide()
        end
    end
    
    -- Initial visibility
    UpdateTestButtonVisibility()
    
    -- Update the slider visibility function to also update test buttons
    local originalUpdateSliderVisibility = UpdateSliderVisibility
    UpdateSliderVisibility = function()
        originalUpdateSliderVisibility()
        UpdateTestButtonVisibility()
    end
    
    -- ========================================================================
    -- NOW CREATE THE DROPDOWN (after sliders exist)
    -- ========================================================================
    
    -- Create texture dropdown with preview icons
    local textureDropdown = AC:CreateFlatDropdownWithPreview(
        effectGroup, 
        200, 
        24, 
        textureDisplayOptions, 
        currentTextureName, 
        function(selectedName)
            local selectedPath = textureNameToPath[selectedName]
            local isAtlas = textureNameToIsAtlas[selectedName]
            local isExternal = textureNameToIsExternal[selectedName]
            
            db.texturePath = selectedPath
            db.textureIsAtlas = isAtlas  -- Store whether this is an atlas texture
            db.textureIsExternal = isExternal  -- Store whether this is an external indicator
            
            -- Update slider visibility based on whether this is an external indicator
            UpdateSliderVisibility()
            
            -- CRITICAL UX FIX: If test mode is active, automatically refresh to show new texture
            -- This allows users to switch between textures seamlessly without hitting OFF first
            if db.externalTestMode or db.healthBarTestMode then
                -- User is in test mode - update the test mode type based on new texture
                if isExternal then
                    -- Switching to external texture - ensure correct test mode
                    db.externalTestMode = true
                    db.healthBarTestMode = false
                else
                    -- Switching to health bar texture - ensure correct test mode
                    db.healthBarTestMode = true
                    db.externalTestMode = false
                end
                
                -- Refresh all nameplates to show the new texture immediately
                if AC.BlackoutCustomization and AC.BlackoutCustomization.RefreshAllNameplatesForTest then
                    AC.BlackoutCustomization:RefreshAllNameplatesForTest()
                end
            end
            
            -- Disable effect dropdown if texture is selected AND checkbox is enabled
            if selectedPath ~= "" and db.useTexture == true then
                -- Texture selected + checkbox ON = disable effect dropdown
                dropdown:SetAlpha(0.5)
                if dropdown.button then
                    dropdown.button:Disable()
                end
                print("|cff8B45FFArena Core:|r Texture style changed to: " .. selectedName .. " (Effect Style disabled)")
            else
                -- "None" selected OR checkbox OFF = re-enable effect dropdown
                dropdown:SetAlpha(1.0)
                if dropdown.button then
                    dropdown.button:Enable()
                end
                print("|cff8B45FFArena Core:|r Texture style changed to: " .. selectedName)
            end
        end,
        function(optionName)
            -- Return texture path for preview icon
            return textureNameToPath[optionName]
        end
    )
    textureDropdown:SetPoint("TOPLEFT", dropdownAnchor, "TOPLEFT", 0, 0)
    
    -- Wire up preview button to show texture preview window
    previewBtn:SetScript("OnClick", function()
        if AC.ShowTexturePreviewWindow then
            AC:ShowTexturePreviewWindow(textureOptions, function(selectedName, selectedPath, isAtlas, isExternal)
                -- Callback when texture is selected from preview window
                db.texturePath = selectedPath
                db.textureIsAtlas = isAtlas
                db.textureIsExternal = isExternal
                
                -- Update dropdown to show selected texture
                if textureDropdown.SetValue then
                    textureDropdown:SetValue(selectedName)
                end
                
                -- Update slider visibility based on whether this is an external indicator
                UpdateSliderVisibility()
                
                -- CRITICAL UX FIX: If test mode is active, automatically refresh to show new texture
                -- This allows users to switch between textures seamlessly from preview window
                if db.externalTestMode or db.healthBarTestMode then
                    -- User is in test mode - update the test mode type based on new texture
                    if isExternal then
                        -- Switching to external texture - ensure correct test mode
                        db.externalTestMode = true
                        db.healthBarTestMode = false
                    else
                        -- Switching to health bar texture - ensure correct test mode
                        db.healthBarTestMode = true
                        db.externalTestMode = false
                    end
                    
                    -- Refresh all nameplates to show the new texture immediately
                    if AC.BlackoutCustomization and AC.BlackoutCustomization.RefreshAllNameplatesForTest then
                        AC.BlackoutCustomization:RefreshAllNameplatesForTest()
                    end
                end
                
                -- Enable texture checkbox if not already enabled
                if not db.useTexture then
                    db.useTexture = true
                    textureCheckbox:SetChecked(true)
                end
                
                -- Disable effect dropdown if texture is selected
                if selectedPath ~= "" then
                    dropdown:SetAlpha(0.5)
                    if dropdown.button then
                        dropdown.button:Disable()
                    end
                end
            end)
        end
    end)
    
    -- Disable effect dropdown on load if texture is selected AND checkbox is enabled
    if currentTexturePath ~= "" and db.useTexture == true then
        dropdown:SetAlpha(0.5)
        if dropdown.button then
            dropdown.button:Disable()
        end
    end

    -- How Blackout Works info block
    local infoGroup = CreateFrame("Frame", nil, parent)
    infoGroup:SetPoint("TOPLEFT", effectGroup, "BOTTOMLEFT", 0, -20)
    infoGroup:SetPoint("TOPRIGHT", effectGroup, "BOTTOMRIGHT", 0, -20)
    infoGroup:SetHeight(380)
    AC:HairlineGroupBox(infoGroup)
    
    local infoTitle = AC:CreateStyledText(infoGroup, "HOW BLACKOUT WORKS", 13, AC.COLORS.PRIMARY, "OVERLAY", "")
    infoTitle:SetPoint("TOPLEFT", 20, -18)

    -- Main description
    local mainDesc = AC:CreateStyledText(infoGroup, 
        "Blackout is an awareness system that transforms how you react to enemy cooldowns in PvP. Instead of cluttering your screen with 357 WeakAuras tracking individual abilities, Blackout provides instant visual feedback through a simple, elegant solution.",
        12, AC.COLORS.TEXT_2, "OVERLAY", "")
    mainDesc:SetPoint("TOPLEFT", 20, -50)
    mainDesc:SetPoint("TOPRIGHT", -20, -50)
    mainDesc:SetJustifyH("LEFT")
    mainDesc:SetWordWrap(true)

    -- How it works section
    local howTitle = AC:CreateStyledText(infoGroup, "The System:", 13, AC.COLORS.TEXT, "OVERLAY", "")
    howTitle:SetPoint("TOPLEFT", 20, -110)

    local howDesc = AC:CreateStyledText(infoGroup,
        "ArenaCore monitors enemy spell casts and automatically applies visual effects when specific abilities are detected. " ..
        "The system tracks high-priority spells that typically require immediate attention or defensive responses.",
        11, AC.COLORS.TEXT_2, "OVERLAY", "")
    howDesc:SetPoint("TOPLEFT", 20, -135)
    howDesc:SetPoint("TOPRIGHT", -20, -135)
    howDesc:SetWordWrap(true)

    -- Benefits section
    local benefitsTitle = AC:CreateStyledText(infoGroup, "The Benefits:", 13, AC.COLORS.TEXT, "OVERLAY", "")
    benefitsTitle:SetPoint("TOPLEFT", 20, -210)

    local benefitsDesc = AC:CreateStyledText(infoGroup,
        "• Instant Reaction Time: See threats immediately without scanning multiple WeakAuras\n" ..
        "• Clean UI: No screen clutter - just essential information when you need it\n" ..
        "• Macro Awareness: Focus on big picture gameplay instead of micro managing cooldown details\n" ..
        "• Better Teamplay: Quickly communicate threats (\"Warrior is black = Trade cooldowns!\") and coordinate responses\n" ..
        "• Improved Performance: React faster to wall, peel, or assist your healer when enemies go offensive",
        11, AC.COLORS.TEXT_2, "OVERLAY", "")
    benefitsDesc:SetPoint("TOPLEFT", 20, -230)
    benefitsDesc:SetPoint("TOPRIGHT", -20, -230)
    benefitsDesc:SetJustifyH("LEFT")
    benefitsDesc:SetWordWrap(true)
end

AC:RegisterPage("Blackout", CreateBlackoutPage)
