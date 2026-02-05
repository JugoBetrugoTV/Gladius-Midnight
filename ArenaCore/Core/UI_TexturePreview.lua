-- ============================================================================
-- ARENACORE TEXTURE PREVIEW WINDOW
-- ============================================================================
-- Displays visual samples of all available blackout textures
-- Clean, professional preview system for user texture selection

local AC = _G.ArenaCore
if not AC then return end

-- ============================================================================
-- TEXTURE PREVIEW WINDOW
-- ============================================================================

local previewWindow = nil

--- Create the texture preview window
local function CreateTexturePreviewWindow()
    if previewWindow then return previewWindow end
    
    -- Main window frame
    local window = CreateFrame("Frame", "ArenaCoreTexturePreview", UIParent, "BackdropTemplate")
    window:SetSize(600, 500)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:SetClampedToScreen(true)
    window:Hide()
    
    -- Backdrop
    window:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 16,
        edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    window:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    window:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Make draggable
    window:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)
    window:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
    end)
    
    -- Title bar background
    local titleBG = window:CreateTexture(nil, "BACKGROUND")
    titleBG:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    titleBG:SetPoint("TOPLEFT", 2, -2)
    titleBG:SetPoint("TOPRIGHT", -2, -2)
    titleBG:SetHeight(35)
    titleBG:SetColorTexture(0.1, 0.1, 0.1, 0.9)
    
    -- Title text (ArenaCore custom font, no outline, all caps)
    local title = window:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 14)
    title:SetText("BLACKOUT TEXTURE PREVIEW")
    title:SetTextColor(0.69, 0.4, 1, 1) -- ArenaCore purple
    title:SetPoint("TOP", 0, -12)
    
    -- Close button (matching More Features window style)
    local closeBtn = CreateFrame("Button", nil, window)
    closeBtn:SetSize(32, 32)
    closeBtn:SetPoint("TOPRIGHT", -8, -8)
    
    -- Red close button texture
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-close.tga")
    closeBg:SetAllPoints()
    closeBtn.bg = closeBg
    
    -- X text
    local xText = closeBtn:CreateFontString(nil, "OVERLAY")
    xText:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 18)
    xText:SetText("×")
    xText:SetTextColor(1, 1, 1, 1)
    xText:SetPoint("CENTER", 0, 0)
    
    -- Hover effect
    closeBtn:SetScript("OnEnter", function(self)
        self.bg:SetVertexColor(1.2, 1.2, 1.2, 1)
    end)
    
    closeBtn:SetScript("OnLeave", function(self)
        self.bg:SetVertexColor(1, 1, 1, 1)
    end)
    
    closeBtn:SetScript("OnClick", function()
        window:Hide()
    end)
    
    -- Subtitle (ArenaCore custom font)
    local subtitle = window:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 11)
    subtitle:SetText("Click a texture to select it for Blackout effects")
    subtitle:SetTextColor(0.7, 0.7, 0.7, 1)
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
    
    -- Scroll frame for texture samples (custom ArenaCore style)
    local scrollFrame = CreateFrame("ScrollFrame", nil, window)
    scrollFrame:SetPoint("TOPLEFT", 10, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    scrollFrame:EnableMouseWheel(true)
    
    -- Background for scroll area
    local scrollBg = scrollFrame:CreateTexture(nil, "BACKGROUND")
    scrollBg:SetAllPoints()
    scrollBg:SetColorTexture(0.05, 0.05, 0.05, 0.5)
    
    -- Content frame (holds all texture samples)
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(560, 800) -- Will be adjusted based on content
    scrollFrame:SetScrollChild(content)
    
    -- Custom scrollbar (matching More Features window style)
    local scrollbar = CreateFrame("Slider", nil, window)
    scrollbar:SetPoint("TOPRIGHT", -8, -62)
    scrollbar:SetPoint("BOTTOMRIGHT", -8, 12)
    scrollbar:SetWidth(14)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetMinMaxValues(0, 1)
    scrollbar:SetValue(0)
    
    -- Track background
    local trackBg = scrollbar:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    
    -- Thumb texture (same as More Features window)
    local thumbTexture = scrollbar:CreateTexture(nil, "OVERLAY")
    thumbTexture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga")
    thumbTexture:SetWidth(12)
    thumbTexture:SetHeight(20)
    scrollbar:SetThumbTexture(thumbTexture)
    
    -- Update scrollbar function
    local function UpdateScrollbar()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        if maxScroll > 0 then
            scrollbar:Show()
            scrollbar:SetMinMaxValues(0, maxScroll)
            scrollbar:SetValue(scrollFrame:GetVerticalScroll())
        else
            scrollbar:Hide()
        end
    end
    
    -- Connect scrollbar to scroll frame
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    
    scrollFrame:SetScript("OnScrollRangeChanged", function(self)
        UpdateScrollbar()
    end)
    
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        UpdateScrollbar()
    end)
    
    -- Mouse wheel scrolling
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollbar:GetValue()
        local minVal, maxVal = scrollbar:GetMinMaxValues()
        local step = 40 -- Scroll speed
        
        if delta > 0 then
            scrollbar:SetValue(math.max(minVal, current - step))
        else
            scrollbar:SetValue(math.min(maxVal, current + step))
        end
    end)
    
    -- Store reference
    window.content = content
    window.scrollFrame = scrollFrame
    
    previewWindow = window
    return window
end

--- Create a texture sample display
--- @param parent Frame - Parent frame
--- @param textureName string - Display name
--- @param texturePath string - Atlas name or file path
--- @param isAtlas boolean - Whether it's an atlas texture
--- @param isExternal boolean - Whether it's an external indicator
--- @param xOffset number - X position
--- @param yOffset number - Y position
--- @param onClickCallback function - Called when sample is clicked
local function CreateTextureSample(parent, textureName, texturePath, isAtlas, isExternal, xOffset, yOffset, onClickCallback)
    -- Container frame
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(170, 140)
    container:SetPoint("TOPLEFT", xOffset, yOffset)
    
    -- Backdrop
    container:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 16,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    container:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    container:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Handle external indicators differently (no health bar, just icon)
    if isExternal and texturePath and texturePath ~= "" then
        -- Create external indicator frame (larger, centered, no health bar)
        local indicatorFrame = CreateFrame("Frame", nil, container)
        indicatorFrame:SetSize(80, 80)  -- Larger size for better preview
        indicatorFrame:SetPoint("CENTER", container, "CENTER", 0, 5)  -- Moved up for better centering
        
        local indicatorTexture = indicatorFrame:CreateTexture(nil, "OVERLAY")
        indicatorTexture:SetAllPoints()
        
        -- Use WeakAuras pattern to auto-detect atlas
        local textureIsAtlas = type(texturePath) == "string" and C_Texture.GetAtlasInfo(texturePath) ~= nil
        if textureIsAtlas then
            indicatorTexture:SetAtlas(texturePath)
        else
            local fileID = tonumber(texturePath) or texturePath
            indicatorTexture:SetTexture(fileID)
        end
        
        indicatorTexture:SetTexCoord(0, 1, 0, 1)  -- Reset tex coords
        indicatorTexture:SetAlpha(1.0)
        
        -- No health bar for external indicators
    else
        -- Regular overlay textures need health bar
        -- Sample display area (simulates health bar) - THIN horizontal bar like WeakAuras
        local sampleFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
        sampleFrame:SetSize(150, 30)  -- Changed from 80 to 30 height for thin bar
        sampleFrame:SetPoint("TOP", 0, -30)  -- Adjusted position
        
        -- Health bar background
        sampleFrame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            tileSize = 16,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        sampleFrame:SetBackdropColor(0, 0.5, 0, 0.5) -- Green health bar
        sampleFrame:SetBackdropBorderColor(0, 0, 0, 1)
        
        -- Black background layer (matches actual blackout implementation)
        local blackBackground = sampleFrame:CreateTexture(nil, "ARTWORK")
        blackBackground:SetAllPoints(sampleFrame)
        blackBackground:SetColorTexture(0, 0, 0, 1)  -- Solid black to hide health bar
        
        -- Texture overlay (the actual glow effect)
        if texturePath and texturePath ~= "" then
            local textureOverlay = sampleFrame:CreateTexture(nil, "OVERLAY")
            -- CRITICAL: Don't stretch - maintain aspect ratio by centering horizontally
            textureOverlay:SetPoint("LEFT", sampleFrame, "LEFT", 0, 0)
            textureOverlay:SetPoint("RIGHT", sampleFrame, "RIGHT", 0, 0)
            textureOverlay:SetHeight(30)  -- Fixed height to match thin bar
            textureOverlay:SetBlendMode("BLEND")  -- Normal blending for full opacity
            
            -- Use WeakAuras pattern to auto-detect atlas
            local textureIsAtlas = type(texturePath) == "string" and C_Texture.GetAtlasInfo(texturePath) ~= nil
            if textureIsAtlas then
                textureOverlay:SetAtlas(texturePath, false)  -- false = don't use atlas size, stretch to fit
            
            -- Determine grid structure based on texture type
            local rows, columns
            
            if texturePath:find("Quality%-BarFill%-Flipbook") then
                -- Quality-BarFill-Flipbook textures are 15 rows x 4 columns (60 frames)
                rows, columns = 15, 4
            elseif texturePath:find("Priest_Void") then
                -- Void Priest texture uses 8 rows x 8 columns (64 frames)
                rows, columns = 8, 8
            elseif texturePath:find("DastardlyDuos%-ProgressBar%-Fill") then
                -- Dastardly Duos progress bar (simple horizontal bar, no animation)
                rows, columns = 1, 1
            elseif texturePath:find("Skillbar_Fill_Flipbook") then
                -- Skillbar textures use 1 row x 4 columns (horizontal strip, 4 frames)
                rows, columns = 1, 4
            else
                -- Default fallback for unknown textures
                rows, columns = 8, 8
            end
            
            -- Show only ONE frame using SetTexCoord (WeakAuras pattern)
            local frame = 1
            
            local row = math.floor((frame - 1) / columns)
            local column = (frame - 1) % columns
            local deltaX = 1.0 / columns
                local deltaY = 1.0 / rows
                local left = deltaX * column
                local right = left + deltaX
                local top = deltaY * row
                local bottom = top + deltaY
                textureOverlay:SetTexCoord(left, right, top, bottom)
            else
                -- Non-atlas texture (file ID)
                local fileID = tonumber(texturePath) or texturePath
                textureOverlay:SetTexture(fileID)
            end
            
            textureOverlay:SetAlpha(1.0)  -- Full opacity to match actual blackout effect
        end
    end
    
    -- Texture name label (ArenaCore custom font, no outline, larger size)
    local nameLabel = container:CreateFontString(nil, "OVERLAY")
    
    -- CRITICAL FIX: Reduce font size for long texture names to fit in box
    local fontSize = 12
    if textureName == "Don't Get Mind Control DC'd" or textureName == "Catch of the Day: 0 CR Gain" then
        fontSize = 10  -- Slightly smaller for long names
    end
    
    nameLabel:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", fontSize)
    nameLabel:SetText(textureName)
    nameLabel:SetTextColor(1, 1, 1, 1)
    nameLabel:SetPoint("BOTTOM", 0, 8)
    
    -- Make clickable
    local clickButton = CreateFrame("Button", nil, container)
    clickButton:SetAllPoints(container)
    clickButton:SetScript("OnEnter", function()
        container:SetBackdropBorderColor(0.69, 0.4, 1, 1) -- ArenaCore purple highlight
        nameLabel:SetTextColor(0.69, 0.4, 1, 1)
    end)
    clickButton:SetScript("OnLeave", function()
        container:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        nameLabel:SetTextColor(1, 1, 1, 1)
    end)
    clickButton:SetScript("OnClick", function()
        if onClickCallback then
            onClickCallback(textureName, texturePath, isAtlas, isExternal)
        end
    end)
    
    -- Tooltip
    clickButton:SetScript("OnEnter", function(self)
        container:SetBackdropBorderColor(0.69, 0.4, 1, 1)
        nameLabel:SetTextColor(0.69, 0.4, 1, 1)
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(textureName, 1, 1, 1)
        GameTooltip:AddLine("Click to select this texture", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    clickButton:SetScript("OnLeave", function()
        container:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        nameLabel:SetTextColor(1, 1, 1, 1)
        GameTooltip:Hide()
    end)
    
    return container
end

--- Populate the preview window with texture samples
--- @param textureOptions table - Array of texture definitions
--- @param onSelectCallback function - Called when texture is selected
local function PopulatePreviewWindow(textureOptions, onSelectCallback)
    local window = CreateTexturePreviewWindow()
    local content = window.content
    
    -- Clear existing samples
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Layout configuration
    local samplesPerRow = 3
    local sampleWidth = 170
    local sampleHeight = 140
    local spacing = 10
    local startX = 10
    local startY = -10
    
    local row = 0
    local col = 0
    
    -- Create samples for each texture
    for i, texture in ipairs(textureOptions) do
        -- Skip "None" option
        if texture.path ~= "" then
            local xOffset = startX + (col * (sampleWidth + spacing))
            local yOffset = startY - (row * (sampleHeight + spacing))
            
            CreateTextureSample(
                content,
                texture.displayName,
                texture.path,
                texture.isAtlas,
                texture.isExternal or false,
                xOffset,
                yOffset,
                function(name, path, isAtlas, isExternal)
                    if onSelectCallback then
                        onSelectCallback(name, path, isAtlas, isExternal)
                    end
                    window:Hide()
                    print("|cff8B45FFArena Core:|r Selected texture: " .. name)
                end
            )
            
            col = col + 1
            if col >= samplesPerRow then
                col = 0
                row = row + 1
            end
        end
    end
    
    -- Adjust content height based on number of rows
    local totalRows = math.ceil((#textureOptions - 1) / samplesPerRow) -- -1 for "None"
    local contentHeight = (totalRows * (sampleHeight + spacing)) + 20
    content:SetHeight(contentHeight)
end

--- Show the texture preview window
--- @param textureOptions table - Array of texture definitions
--- @param onSelectCallback function - Called when texture is selected
function AC:ShowTexturePreviewWindow(textureOptions, onSelectCallback)
    PopulatePreviewWindow(textureOptions, onSelectCallback)
    local window = CreateTexturePreviewWindow()
    window:Show()
end

--- Hide the texture preview window
function AC:HideTexturePreviewWindow()
    if previewWindow then
        previewWindow:Hide()
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Module loaded (debug removed for clean user experience)
-- print("|cffB266FFArenaCore:|r Texture Preview window loaded")
