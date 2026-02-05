-- ============================================================================
-- ARENA FRAME THEMES MODULE
-- ============================================================================
-- Theme system for arena frames - allows users to switch between
-- different visual styles and layouts in real-time without affecting core code

local AC = _G.ArenaCore
if not AC then return end

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

AC.ArenaFrameThemes = AC.ArenaFrameThemes or {}
local AFT = AC.ArenaFrameThemes

-- Theme registry
AFT.themes = {}
AFT.currentTheme = nil

-- ============================================================================
-- THEME DEFINITIONS
-- ============================================================================

-- Default "Arena Core" Theme
AFT.themes["Arena Core"] = {
    name = "Arena Core",
    description = "Default ArenaCore theme with classic styling",
    
    -- Frame dimensions
    frameWidth = 235,
    frameHeight = 68,
    
    -- Health bar settings
    healthBar = {
        texture = nil, -- Uses user's selected texture
        height = 18,
    },
    
    -- Power bar settings
    powerBar = {
        texture = nil, -- Uses user's selected texture
        height = 8,
    },
    
    -- Class icon settings
    classIcon = {
        size = 32,
        texCoord = {0.1, 0.9, 0.1, 0.9}, -- Standard crop
    },
    
    -- Spec icon settings
    specIcon = {
        size = 25,
        texCoord = {0.1, 0.9, 0.1, 0.9},
    },
    
    -- Trinket settings
    trinket = {
        size = 32,
        texCoord = {0.1, 0.9, 0.1, 0.9},
    },
    
    -- Racial settings
    racial = {
        size = 32,
        texCoord = {0.1, 0.9, 0.1, 0.9},
    },
    
    -- Name text settings (ArenaCore custom font)
    nameText = {
        font = "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf",
        fontSize = 12,
        fontFlags = "OUTLINE",
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        shadowOffset = {1, -1},
        shadowColor = {0, 0, 0, 1},
    },
    
    -- Health text settings (ArenaCore custom font)
    healthText = {
        font = "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf",
        fontSize = 10,
        fontFlags = "OUTLINE",
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        shadowOffset = {1, -1},
        shadowColor = {0, 0, 0, 1},
    },
    
    -- Background settings
    background = {
        enabled = false,
        texture = nil,
        color = {0, 0, 0, 0.8},
    },
    
    -- Border settings
    border = {
        enabled = false,
        texture = nil,
        color = {1, 1, 1, 1},
        size = 1,
    },
}

-- "The 1500 Special" Theme - Flat/Minimal Style
AFT.themes["The 1500 Special"] = {
    name = "The 1500 Special",
    description = "Clean, flat design inspired by high-rated arena gameplay",
    
    -- Frame dimensions (more compact)
    frameWidth = 200,
    frameHeight = 43,
    
    -- Health bar settings
    healthBar = {
        texture = "Interface\\AddOns\\ArenaCore\\Media\\Framethemes\\simple core\\statusbar",
        height = 25, -- Taller health bar for better visibility
    },
    
    -- Power bar settings
    powerBar = {
        texture = "Interface\\AddOns\\ArenaCore\\Media\\Framethemes\\simple core\\statusbar",
        height = 9,
    },
    
    -- Class icon settings (larger, more prominent)
    classIcon = {
        size = 43, -- Same as frame height for clean look
        texCoord = {0.07, 0.93, 0.07, 0.93}, -- Tighter crop for cleaner look
    },
    
    -- Spec icon settings
    specIcon = {
        size = 18,
        texCoord = {0.07, 0.93, 0.07, 0.93},
    },
    
    -- Trinket settings (preserve ArenaCore borders)
    trinket = {
        size = 32,
        texCoord = {0.1, 0.9, 0.1, 0.9}, -- Less aggressive cropping to preserve border compatibility
    },
    
    -- Racial settings (preserve ArenaCore borders)
    racial = {
        size = 32,
        texCoord = {0.1, 0.9, 0.1, 0.9}, -- Less aggressive cropping to preserve border compatibility
    },
    
    -- Name text settings (ArenaCore custom font)
    nameText = {
        font = "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf",
        fontSize = 12,
        fontFlags = "OUTLINE",
        justifyH = "LEFT",
        justifyV = "BOTTOM",
        shadowOffset = {0, 0}, -- No shadow for cleaner look
        shadowColor = {0, 0, 0, 0},
    },
    
    -- Health text settings (ArenaCore custom font)
    healthText = {
        font = "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf",
        fontSize = 11,
        fontFlags = "OUTLINE",
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        shadowOffset = {0, 0}, -- No shadow
        shadowColor = {0, 0, 0, 0},
    },
    
    -- Background settings (flat texture without rounded corners)
    background = {
        enabled = true,
        texture = "Interface\\Buttons\\WHITE8X8", -- Flat solid texture (no rounded corners)
        color = {0, 0, 0, 1}, -- Solid black background
        insets = {-2, 2, 2, -2}, -- Extend slightly beyond frame
    },
    
    -- Border settings
    border = {
        enabled = false,
        texture = nil,
        color = {1, 1, 1, 1},
        size = 1,
    },
    
    -- Special positioning for flat theme
    positioning = {
        mirrored = false,
        nameAboveHealthBar = true, -- Name goes above health bar
        compactLayout = true,
    },
}

-- ============================================================================
-- THEME APPLICATION FUNCTIONS
-- ============================================================================

function AFT:ApplyTheme(themeName, frameIndex)
    local theme = self.themes[themeName]
    if not theme then
        print("|cffFF0000ArenaCore Themes:|r Unknown theme: " .. tostring(themeName))
        return false
    end
    
    -- DEBUG DISABLED FOR PRODUCTION
    -- print("|cffFFFF00[Theme Debug]|r Checking frame systems...")
    
    -- Check ArenaCore Master Frame Manager (the correct way)
    local MFM = AC and AC.MasterFrameManager
    -- print("|cffFFFF00[Theme Debug]|r AC.MasterFrameManager exists: " .. tostring(MFM ~= nil))
    -- if MFM then
    --     print("|cffFFFF00[Theme Debug]|r MFM.frames exists: " .. tostring(MFM.frames ~= nil))
    --     if MFM.frames then
    --         for i = 1, 3 do
    --             print("|cffFFFF00[Theme Debug]|r MFM.frames[" .. i .. "] exists: " .. tostring(MFM.frames[i] ~= nil))
    --         end
    --     end
    -- end
    
    -- Check global MFM (legacy)
    local globalMFM = _G.MFM
    -- print("|cffFFFF00[Theme Debug]|r Global MFM exists: " .. tostring(globalMFM ~= nil))
    
    -- Check ArenaCore global frame system
    -- if _G.ArenaCore then
    --     print("|cffFFFF00[Theme Debug]|r ArenaCore.ArenaFrames exists: " .. tostring(_G.ArenaCore.ArenaFrames ~= nil))
    --     if _G.ArenaCore.ArenaFrames then
    --         for i = 1, 3 do
    --             print("|cffFFFF00[Theme Debug]|r ArenaCore.ArenaFrames[" .. i .. "] exists: " .. tostring(_G.ArenaCore.ArenaFrames[i] ~= nil))
    --         end
    --     end
    -- end
    
    -- Try multiple frame access methods (in correct order)
    local frames = nil
    if MFM and MFM.frames then
        frames = MFM.frames
        -- print("|cffFFFF00[Theme Debug]|r Using AC.MasterFrameManager.frames")
    elseif globalMFM and globalMFM.frames then
        frames = globalMFM.frames
        -- print("|cffFFFF00[Theme Debug]|r Using global MFM.frames")
    elseif _G.ArenaCore and _G.ArenaCore.ArenaFrames then
        frames = _G.ArenaCore.ArenaFrames
        -- print("|cffFFFF00[Theme Debug]|r Using ArenaCore.ArenaFrames")
    else
        print("|cffFF0000ArenaCore Themes:|r No frame system found! AC.MasterFrameManager.frames not available")
        return false
    end
    
    -- Get the frame to apply theme to
    local frame
    if frameIndex then
        -- Apply to specific frame
        frame = frames[frameIndex]
        if not frame then 
            print("|cffFF0000ArenaCore Themes:|r Frame " .. frameIndex .. " not found")
            return false 
        end
        self:ApplyThemeToFrame(theme, frame)
    else
        -- Apply to all frames
        local appliedCount = 0
        for i = 1, 3 do
            if frames[i] then
                self:ApplyThemeToFrame(theme, frames[i])
                appliedCount = appliedCount + 1
            end
        end
        
        if appliedCount == 0 then
            print("|cffFF0000ArenaCore Themes:|r No frames found to apply theme to")
            return false
        end
        
        -- print("|cffFFFF00[Theme Debug]|r Applied theme to " .. appliedCount .. " frames")
    end
    
    self.currentTheme = themeName
    -- DEBUG DISABLED FOR PRODUCTION
    -- print("|cff8B45FFArenaCore Themes:|r Applied theme: " .. themeName)
    
    -- CRITICAL FIX: Auto-normalize after theme application to ensure all frames match
    C_Timer.After(0.15, function()
        if AC and AC.NormalizeArenaFrameSizes then
            AC:NormalizeArenaFrameSizes()
        end
    end)
    
    return true
end

function AFT:ApplyThemeToFrame(theme, frame)
    if not theme or not frame then 
        -- print("|cffFF0000[Theme Debug]|r ApplyThemeToFrame: Invalid theme or frame")
        return 
    end
    
    -- print("|cffFFFF00[Theme Debug]|r Applying theme " .. theme.name .. " to frame " .. tostring(frame:GetName() or "unnamed"))
    
    -- Debug: Check what elements exist on the frame
    -- print("|cffFFFF00[Theme Debug]|r Frame elements:")
    -- print("  healthBar: " .. tostring(frame.healthBar ~= nil))
    -- print("  manaBar: " .. tostring(frame.manaBar ~= nil))
    -- print("  classIcon: " .. tostring(frame.classIcon ~= nil))
    -- print("  playerName: " .. tostring(frame.playerName ~= nil))
    -- print("  specIcon: " .. tostring(frame.specIcon ~= nil))
    -- print("  trinketIndicator: " .. tostring(frame.trinketIndicator ~= nil))
    -- print("  racialIndicator: " .. tostring(frame.racialIndicator ~= nil))
    
    -- REMOVED: Don't apply hardcoded theme dimensions!
    -- LoadThemeSettings() already loaded the user's custom width/height into the database
    -- Applying hardcoded theme.frameWidth/frameHeight here overwrites user settings
    -- The layout system and UpdateFrameSize() will apply the correct size from the database
    
    -- Apply health bar styling (ArenaCore uses frame.healthBar)
    if frame.healthBar and theme.healthBar then
        if theme.healthBar.texture then
            frame.healthBar:SetStatusBarTexture(theme.healthBar.texture)
        end
        if theme.healthBar.height then
            frame.healthBar:SetHeight(theme.healthBar.height)
            -- Also update container if it exists
            if frame.healthBarContainer then
                frame.healthBarContainer:SetHeight(theme.healthBar.height + 17)
            end
        end
        
        -- CRITICAL FIX: Ensure health bar is visible when theme is applied
        frame.healthBar:SetAlpha(1.0)
        frame.healthBar:Show()
        
        -- CRITICAL FIX: Set initial values so bar is visible
        frame.healthBar:SetMinMaxValues(0, 100)
        frame.healthBar:SetValue(100)
        
        -- CRITICAL FIX: Apply class colors if enabled and unit exists
        local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
        if general and general.useClassColors and frame.unit and UnitExists(frame.unit) then
            local _, classFile = UnitClass(frame.unit)
            if classFile and RAID_CLASS_COLORS[classFile] then
                local classColor = RAID_CLASS_COLORS[classFile]
                frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
            end
        elseif not (general and general.useClassColors) then
            -- Default green color if class colors disabled
            frame.healthBar:SetStatusBarColor(0, 1, 0)
        end
    end
    
    -- Apply power bar styling (ArenaCore uses frame.manaBar)
    if frame.manaBar and theme.powerBar then
        if theme.powerBar.texture then
            frame.manaBar:SetStatusBarTexture(theme.powerBar.texture)
        end
        if theme.powerBar.height then
            frame.manaBar:SetHeight(theme.powerBar.height)
            -- Also update container if it exists
            if frame.manaBarContainer then
                frame.manaBarContainer:SetHeight(theme.powerBar.height + 7)
            end
        end
        
        -- CRITICAL FIX: Ensure mana bar is visible when theme is applied
        frame.manaBar:SetAlpha(1.0)
        frame.manaBar:Show()
        
        -- CRITICAL FIX: Set initial values so bar is visible
        frame.manaBar:SetMinMaxValues(0, 100)
        frame.manaBar:SetValue(100)
    end
    
    -- Apply class icon styling (ArenaCore uses frame.classIcon)
    if frame.classIcon and theme.classIcon then
        if theme.classIcon.size then
            frame.classIcon:SetSize(theme.classIcon.size, theme.classIcon.size)
            
                    end
        if theme.classIcon.texCoord then
            local tc = theme.classIcon.texCoord
            -- The actual texture is frame.classIcon.classIcon or frame.classIcon.icon
            if frame.classIcon.classIcon then
                frame.classIcon.classIcon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
            elseif frame.classIcon.icon then
                frame.classIcon.icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
            end
        end
    end
    
    -- Apply spec icon styling (ArenaCore uses frame.specIcon)
    if frame.specIcon and theme.specIcon then
        if theme.specIcon.size then
            frame.specIcon:SetSize(theme.specIcon.size, theme.specIcon.size)
        end
        if theme.specIcon.texCoord then
            local tc = theme.specIcon.texCoord
            if frame.specIcon.icon then
                frame.specIcon.icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
            end
        end
        
        -- CRITICAL FIX: Update black border anchors after frame resize
        if frame.specIcon.styledBorder and frame.specIcon.icon then
            local border = frame.specIcon.styledBorder
            local icon = frame.specIcon.icon
            
            -- Reanchor all 4 border edges to icon instead of frame
            if border.top then
                border.top:ClearAllPoints()
                border.top:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
                border.top:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
            end
            if border.bottom then
                border.bottom:ClearAllPoints()
                border.bottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
                border.bottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
            end
            if border.left then
                border.left:ClearAllPoints()
                border.left:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
                border.left:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
            end
            if border.right then
                border.right:ClearAllPoints()
                border.right:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
                border.right:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
            end
        end
    end
    
    -- Apply trinket styling (ArenaCore uses frame.trinket or frame.trinketIndicator)
    local trinketFrame = frame.trinket or frame.trinketIndicator
    if trinketFrame and theme.trinket then
        if theme.trinket.size then
            trinketFrame:SetSize(theme.trinket.size, theme.trinket.size)
        end
        if theme.trinket.texCoord then
            local tc = theme.trinket.texCoord
            -- CRITICAL: Only apply texCoord to the icon, NOT the border
            if trinketFrame.icon then
                trinketFrame.icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
            elseif trinketFrame.texture then
                trinketFrame.texture:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
            end
        end
        
        -- CRITICAL: Ensure ArenaCore border is preserved and visible
        self:EnsureTrinketBorder(trinketFrame)
        
        -- CRITICAL FIX: Reanchor cooldown to icon after frame resize
        if trinketFrame.cooldown and trinketFrame.icon then
            trinketFrame.cooldown:ClearAllPoints()
            trinketFrame.cooldown:SetAllPoints(trinketFrame.icon)
        end
    end
    
    -- Apply racial styling (ArenaCore uses frame.racial or frame.racialIndicator)
    local racialFrame = frame.racial or frame.racialIndicator
    if racialFrame and theme.racial then
        if theme.racial.size then
            racialFrame:SetSize(theme.racial.size, theme.racial.size)
        end
        if theme.racial.texCoord then
            local tc = theme.racial.texCoord
            -- CRITICAL: Only apply texCoord to the icon, NOT the border
            if racialFrame.icon then
                racialFrame.icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
            elseif racialFrame.texture then
                racialFrame.texture:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
            end
        end
        
        -- CRITICAL: Ensure ArenaCore border is preserved and visible
        self:EnsureTrinketBorder(racialFrame) -- Same border system for racials
        
        -- CRITICAL FIX: Reanchor cooldown to icon after frame resize
        if racialFrame.cooldown and racialFrame.icon then
            racialFrame.cooldown:ClearAllPoints()
            racialFrame.cooldown:SetAllPoints(racialFrame.icon)
        end
    end
    
    -- Apply name text styling (ArenaCore uses frame.playerName)
    if frame.playerName and theme.nameText then
        self:ApplyTextStyling(frame.playerName, theme.nameText)
        
        -- CRITICAL: Ensure player name is always visible above all other elements
        self:EnsureTextVisibility(frame.playerName, "playerName")
    end
    
    -- Apply health text styling (ArenaCore uses frame.healthBar.text)
    if frame.healthBar and frame.healthBar.text and theme.healthText then
        self:ApplyTextStyling(frame.healthBar.text, theme.healthText)
        
        -- Ensure health text is visible above health bar
        self:EnsureTextVisibility(frame.healthBar.text, "healthText")
    end
    
    -- Apply background
    if theme.background and theme.background.enabled then
        self:ApplyBackground(frame, theme.background)
    else
        self:RemoveBackground(frame)
    end
    
    -- DISABLED: ApplySpecialPositioning was causing name position resets on reload
    -- The normal positioning system (ApplyGeneralSettings) handles text positioning correctly
    -- if theme.positioning then
    --     self:ApplySpecialPositioning(frame, theme.positioning)
    -- else
    if not theme.positioning then
        -- CRITICAL FIX: When switching back to "Arena Core" theme, restore normal positioning
        -- This ensures name is anchored to frame (not health bar) and uses slider settings
        if frame.playerName then
            local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
            if general then
                -- CRITICAL FIX: Use proper nil check - 0 is a valid value!
                local nameX = (general.playerNameX ~= nil) and general.playerNameX or 52
                local nameY = (general.playerNameY ~= nil) and general.playerNameY or 0
                frame.playerName:ClearAllPoints()
                frame.playerName:SetPoint("TOPLEFT", frame, "TOPLEFT", nameX, nameY)
            end
        end
    end
    
    -- Mark frame as themed
    frame._currentTheme = theme.name
    
    -- CRITICAL: Ensure DR visibility after theme application
    -- Theme overlays might interfere with DR edit mode functionality
    C_Timer.After(0.1, function()
        AFT:EnsureDRVisibility()
    end)
    
    -- Debug message disabled for production
    -- if AC.BLACKOUT_DEBUG then
    --     print("|cff00FFFF[Theme Debug]|r Applied " .. theme.name .. " theme to frame")
    -- end
end

function AFT:ApplyTextStyling(fontString, textSettings)
    if not fontString or not textSettings then return end
    
    -- CRITICAL: Ensure text appears above health bars by setting proper strata/level
    local parentFrame = fontString:GetParent()
    if parentFrame then
        -- Check if this is a player name (needs to be above health bars)
        local isPlayerName = (fontString == parentFrame.playerName)
        
        if isPlayerName then
            -- Create or get text overlay frame for proper layering
            if not parentFrame.nameTextOverlay then
                parentFrame.nameTextOverlay = CreateFrame("Frame", nil, parentFrame)
                parentFrame.nameTextOverlay:SetAllPoints(parentFrame)
                parentFrame.nameTextOverlay:SetFrameStrata("MEDIUM")
                parentFrame.nameTextOverlay:SetFrameLevel(200) -- Very high level to appear above health bars
            end
            
            -- Move the font string to the overlay frame
            fontString:SetParent(parentFrame.nameTextOverlay)
            -- print("|cffFFFF00[Theme Debug]|r Moved player name to high strata overlay")
        end
    end
    
    -- Apply font using ArenaCore's SafeSetFont if available
    if textSettings.font and textSettings.fontSize and textSettings.fontFlags then
        if AC.SafeSetFont then
            -- Use ArenaCore's safe font setting method
            AC.SafeSetFont(fontString, textSettings.font, textSettings.fontSize, textSettings.fontFlags)
            -- print("|cffFFFF00[Theme Debug]|r Applied ArenaCore font: " .. textSettings.font .. " (" .. textSettings.fontSize .. "px)")
        else
            -- Fallback to direct font setting
            fontString:SetFont(textSettings.font, textSettings.fontSize, textSettings.fontFlags)
            -- print("|cffFFFF00[Theme Debug]|r Applied font (fallback): " .. textSettings.font .. " (" .. textSettings.fontSize .. "px)")
        end
    end
    
    -- Apply justification
    if textSettings.justifyH then
        fontString:SetJustifyH(textSettings.justifyH)
    end
    if textSettings.justifyV then
        fontString:SetJustifyV(textSettings.justifyV)
    end
    
    -- Apply shadow
    if textSettings.shadowOffset and textSettings.shadowColor then
        local offset = textSettings.shadowOffset
        local color = textSettings.shadowColor
        fontString:SetShadowOffset(offset[1], offset[2])
        fontString:SetShadowColor(color[1], color[2], color[3], color[4])
    end
end

function AFT:EnsureTextVisibility(fontString, textType)
    if not fontString then return end
    
    local parentFrame = fontString:GetParent()
    if not parentFrame then return end
    
    -- Get the main arena frame (might be nested)
    local mainFrame = parentFrame
    while mainFrame and not mainFrame.playerName do
        mainFrame = mainFrame:GetParent()
        if not mainFrame or mainFrame == UIParent then break end
    end
    
    if not mainFrame then return end
    
    -- Create high-level overlay for text elements if it doesn't exist
    if not mainFrame._themeTextOverlay then
        mainFrame._themeTextOverlay = CreateFrame("Frame", nil, mainFrame)
        mainFrame._themeTextOverlay:SetAllPoints(mainFrame)
        mainFrame._themeTextOverlay:SetFrameStrata("MEDIUM")
        mainFrame._themeTextOverlay:SetFrameLevel(250) -- Very high level above all other elements
        -- print("|cffFFFF00[Theme Debug]|r Created high-level text overlay frame")
    end
    
    -- Move text to overlay if it's not already there
    if fontString:GetParent() ~= mainFrame._themeTextOverlay then
        fontString:SetParent(mainFrame._themeTextOverlay)
        -- print("|cffFFFF00[Theme Debug]|r Moved " .. textType .. " to high-level overlay for visibility")
    end
end

function AFT:EnsureTrinketBorder(iconFrame)
    if not iconFrame then return end
    
    -- Get the actual icon texture (not the frame)
    local icon = iconFrame.icon or iconFrame.texture
    if not icon then return end
    
    -- Check if ArenaCore border exists
    if iconFrame.border then
        -- Ensure border is visible and properly configured
        iconFrame.border:Show()
        iconFrame.border:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\orangeoverlay.tga")
        iconFrame.border:SetTexCoord(0, 1, 0, 1) -- Full texture for rounded overlay
        
        -- CRITICAL FIX: Border should extend beyond icon for proper visibility
        iconFrame.border:ClearAllPoints()
        iconFrame.border:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
        iconFrame.border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
        
        -- Ensure border is on OVERLAY layer (above the icon)
        iconFrame.border:SetDrawLayer("OVERLAY", 0)
        
        -- print("|cffFFFF00[Theme Debug]|r Restored ArenaCore border for trinket/racial icon")
    else
        -- Create border if it doesn't exist (shouldn't happen, but safety check)
        local border = iconFrame:CreateTexture(nil, "OVERLAY")
        border:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
        border:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\orangeoverlay.tga")
        border:SetTexCoord(0, 1, 0, 1)
        iconFrame.border = border
        
        -- print("|cffFFFF00[Theme Debug]|r Created missing ArenaCore border for trinket/racial icon")
    end
end

function AFT:EnsureDRVisibility()
    -- Ensure DR containers maintain proper strata and aren't affected by theme overlays
    local MFM = AC and AC.MasterFrameManager
    if not MFM or not MFM.frames then return end
    
    for i = 1, 3 do
        local frame = MFM.frames[i]
        if frame and frame.drContainer then
            -- Ensure DR container has proper strata for edit mode interaction
            frame.drContainer:SetFrameStrata("MEDIUM")
            frame.drContainer:SetFrameLevel(100) -- High enough to be interactive but below text overlays
            
            -- Ensure all DR icons within the container are visible and properly layered
            if frame.drIcons then
                for category, drIcon in pairs(frame.drIcons) do
                    if drIcon then
                        drIcon:SetFrameStrata("MEDIUM")
                        drIcon:SetFrameLevel(101) -- Slightly above container
                    end
                end
            end
            
            -- print("|cffFFFF00[DR Debug]|r Ensured DR visibility for frame " .. i)
        end
    end
end

function AFT:ApplyBackground(frame, bgSettings)
    if not frame or not bgSettings then return end
    
    -- Create or get background texture
    if not frame._themeBackground then
        frame._themeBackground = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    end
    
    local bg = frame._themeBackground
    
    -- Set texture
    if bgSettings.texture then
        bg:SetTexture(bgSettings.texture)
    end
    
    -- Set color
    if bgSettings.color then
        local c = bgSettings.color
        bg:SetVertexColor(c[1], c[2], c[3], c[4])
    end
    
    -- CRITICAL FIX: Always clear points before re-anchoring to ensure dynamic sizing
    bg:ClearAllPoints()
    
    -- Set position
    if bgSettings.insets then
        local insets = bgSettings.insets
        bg:SetPoint("TOPLEFT", frame, "TOPLEFT", insets[1], insets[2])
        bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", insets[3], insets[4])
    else
        bg:SetAllPoints(frame)
    end
    
    bg:Show()
end

function AFT:RemoveBackground(frame)
    if frame and frame._themeBackground then
        frame._themeBackground:Hide()
    end
end

function AFT:ApplySpecialPositioning(frame, positioning)
    if not frame or not positioning then return end
    
    -- Handle "The 1500 Special" positioning
    if positioning.nameAboveHealthBar and frame.playerName and frame.healthBar then
        local general = AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.general
        
        -- CRITICAL FIX: ALWAYS use user's saved slider values - never override them
        -- User's slider settings take absolute priority over theme defaults
        local nameX = (general and general.playerNameX ~= nil) and general.playerNameX or 131
        local nameY = (general and general.playerNameY ~= nil) and general.playerNameY or -3
        
        frame.playerName:ClearAllPoints()
        -- CRITICAL FIX: Anchor to frame, NOT health bar, so name doesn't move when bars move
        -- Use TOPLEFT anchor (same as Arena Core theme) for independent positioning
        frame.playerName:SetPoint("TOPLEFT", frame, "TOPLEFT", nameX, nameY)
    end
    
    -- Handle compact layout for "The 1500 Special"
    if positioning.compactLayout then
        -- Adjust class icon positioning for compact layout
        if frame.classIcon then
            -- CRITICAL: Use EXACT user positioning from database (no base offset!)
            -- The old code added -2 which caused 2-pixel drift
            local pos = AC.DB and AC.DB.profile and AC.DB.profile.classIcons and AC.DB.profile.classIcons.positioning or {}
            local xOffset = (pos.horizontal or 0)  -- EXACT user position (no base offset)
            local yOffset = (pos.vertical or 0)     -- EXACT user vertical offset
            
            frame.classIcon:ClearAllPoints()
            frame.classIcon:SetPoint("RIGHT", frame, "LEFT", xOffset, yOffset)
            -- DEBUG DISABLED FOR PRODUCTION
            -- print("|cffFFFF00[Theme Debug]|r Applied compact class icon positioning with user offsets")
        end
        
        -- Adjust health bar positioning for compact layout
        if frame.healthBar and frame.classIcon then
            frame.healthBar:ClearAllPoints()
            frame.healthBar:SetPoint("LEFT", frame.classIcon, "RIGHT", 2, 0)
            -- DEBUG DISABLED FOR PRODUCTION
            -- print("|cffFFFF00[Theme Debug]|r Applied compact health bar positioning")
        end
    end
end

-- ============================================================================
-- DATABASE INTEGRATION
-- ============================================================================

function AFT:InitializeDatabase()
    -- Ensure theme setting exists in database
    if not AC.DB or not AC.DB.profile then
        C_Timer.After(0.1, function() self:InitializeDatabase() end)
        return
    end
    
    -- Initialize theme setting
    if not AC.DB.profile.arenaFrameTheme then
        AC.DB.profile.arenaFrameTheme = "Arena Core" -- Default theme
    end
    
    -- Initialize theme-specific settings storage
    if not AC.DB.profile.themeSettings then
        AC.DB.profile.themeSettings = {}
    end
    
    -- CRITICAL FIX: Load theme-specific settings for new users
    -- This ensures new users get the correct default positioning from GetArenaCoreDefaults()
    self:LoadThemeSettings(AC.DB.profile.arenaFrameTheme)
    
    -- Apply saved theme (visuals)
    self:ApplyTheme(AC.DB.profile.arenaFrameTheme)
    
    -- CRITICAL FIX: Apply general settings (names, numbers, scales) after theme loads
    -- This was missing on reload, causing names to not be positioned correctly
    if AC.ApplyGeneralSettings then
        AC:ApplyGeneralSettings()
    end
end

function AFT:SaveTheme(themeName)
    if AC.DB and AC.DB.profile then
        AC.DB.profile.arenaFrameTheme = themeName
    end
end

-- ============================================================================
-- COMPLETE THEME-SPECIFIC SETTINGS SYSTEM
-- ============================================================================
-- Every setting category is stored per-theme for complete isolation
-- Settings categories: arenaFrames, trinkets, racials, specIcons, diminishingReturns, castBars, textures, classPacks

-- Deep copy helper function
local function DeepCopy(original)
    if type(original) ~= 'table' then return original end
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

-- Save ALL current settings to current theme
function AFT:SaveCurrentThemeSettings()
    local currentTheme = self:GetCurrentTheme()
    if not currentTheme or not AC.DB or not AC.DB.profile then return end
    
    -- Initialize theme settings storage
    if not AC.DB.profile.themeData then
        AC.DB.profile.themeData = {}
    end
    
    -- CRITICAL FIX: ALWAYS sync global to theme-specific
    -- Even though sliders save to both locations, we need to ensure consistency
    -- This is especially important for logout/reload to persist changes
    if not AC.DB.profile.themeData[currentTheme] then
        AC.DB.profile.themeData[currentTheme] = {}
    end
    
    local themeData = AC.DB.profile.themeData[currentTheme]
    
    -- CRITICAL FIX: Only copy CLEAN positioning data, not everything
    -- This prevents corruption from being saved into theme data
    -- For arenaFrames, theme positioning (set by drag) is authoritative for horizontal/vertical
    local function SaveCleanPositioning(source, dest, elementName)
        if not source then 
            return 
        end
        
        -- Initialize destination if needed
        if not dest[elementName] then
            dest[elementName] = {}
        end
        
        -- Copy only the essential positioning values
        if source.positioning then
            if not dest[elementName].positioning then
                dest[elementName].positioning = {}
            end
            
            -- For most elements, copy horizontal/vertical from source.
            -- For arenaFrames, PRESERVE existing theme horizontal/vertical if already set
            if elementName ~= "arenaFrames" then
                if source.positioning.horizontal ~= nil then
                    dest[elementName].positioning.horizontal = source.positioning.horizontal
                end
                if source.positioning.vertical ~= nil then
                    dest[elementName].positioning.vertical = source.positioning.vertical
                end
            else
                -- arenaFrames: only initialize if completely missing; never overwrite drag-saved values
                if dest[elementName].positioning.horizontal == nil and source.positioning.horizontal ~= nil then
                    dest[elementName].positioning.horizontal = source.positioning.horizontal
                end
                if dest[elementName].positioning.vertical == nil and source.positioning.vertical ~= nil then
                    dest[elementName].positioning.vertical = source.positioning.vertical
                end
            end
            
            -- Also copy other legitimate positioning values (but NOT draggedBase or nested tables)
            if source.positioning.spacing then
                dest[elementName].positioning.spacing = source.positioning.spacing
            end
            if source.positioning.growthDirection then
                dest[elementName].positioning.growthDirection = source.positioning.growthDirection
            end
        end
        
        -- Copy sizing
        if source.sizing then
            dest[elementName].sizing = DeepCopy(source.sizing)
        end
        
        -- CRITICAL FIX: Copy general section for player name/arena number positioning
        if source.general then
            if not dest[elementName].general then
                dest[elementName].general = {}
            end
            
            -- Copy player name positioning
            if source.general.playerNameX ~= nil then
                dest[elementName].general.playerNameX = source.general.playerNameX
            end
            if source.general.playerNameY ~= nil then
                dest[elementName].general.playerNameY = source.general.playerNameY
            end
            if source.general.playerNameScale ~= nil then
                dest[elementName].general.playerNameScale = source.general.playerNameScale
            end
            
            -- Copy arena number positioning
            if source.general.arenaNumberX ~= nil then
                dest[elementName].general.arenaNumberX = source.general.arenaNumberX
            end
            if source.general.arenaNumberY ~= nil then
                dest[elementName].general.arenaNumberY = source.general.arenaNumberY
            end
            if source.general.arenaNumberScale ~= nil then
                dest[elementName].general.arenaNumberScale = source.general.arenaNumberScale
            end
            
            -- Copy other general settings (but avoid copying entire section to prevent corruption)
            for key, value in pairs(source.general) do
                if key ~= "playerNameX" and key ~= "playerNameY" and key ~= "playerNameScale" and
                   key ~= "arenaNumberX" and key ~= "arenaNumberY" and key ~= "arenaNumberScale" then
                    dest[elementName].general[key] = DeepCopy(value)
                end
            end
        end
        
        -- Copy other non-positioning data (excluding general which we handled above)
        for key, value in pairs(source) do
            if key ~= "positioning" and key ~= "sizing" and key ~= "general" then
                dest[elementName][key] = DeepCopy(value)
            end
        end
    end
    
    -- Debug removed: Too spammy during normal operation
    
    -- Save clean data for each element
    SaveCleanPositioning(AC.DB.profile.arenaFrames, themeData, "arenaFrames")
    SaveCleanPositioning(AC.DB.profile.trinkets, themeData, "trinkets")
    SaveCleanPositioning(AC.DB.profile.racials, themeData, "racials")
    SaveCleanPositioning(AC.DB.profile.specIcons, themeData, "specIcons")
    SaveCleanPositioning(AC.DB.profile.classIcons, themeData, "classIcons")
    SaveCleanPositioning(AC.DB.profile.diminishingReturns, themeData, "diminishingReturns")
    SaveCleanPositioning(AC.DB.profile.castBars, themeData, "castBars")
    
    -- Debug removed: Too spammy during normal operation
    
    -- Copy other data that doesn't have positioning issues
    if AC.DB.profile.textures then
        themeData.textures = DeepCopy(AC.DB.profile.textures)
    end
    if AC.DB.profile.classPacks then
        themeData.classPacks = DeepCopy(AC.DB.profile.classPacks)
    end
    
    -- DEBUG DISABLED FOR PRODUCTION
    -- print("|cff00FF00[Theme Settings]|r Synced all settings to theme: " .. currentTheme)
end

-- Get hardcoded default settings for "The 1500 Special" theme
function AFT:GetThe1500SpecialDefaults()
-- LIVE SETTINGS EXPORT - Your ACTUAL current settings
-- Paste this into GetThe1500SpecialDefaults() function
-- Generated: 2025-11-19 15:36:12
return {
  ["textures"] = {
    ["powerBarTexture"] = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture12.tga",
    ["sizing"] = {
      ["healthHeight"] = 27,
      ["healthWidth"] = 156,
      ["resourceWidth"] = 156,
      ["resourceHeight"] = 13,
    },
    ["barPosition"] = {
      ["horizontal"] = 1,
      ["vertical"] = -1,
      ["spacing"] = 0,
    },
    ["castBarTexture"] = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture21.tga",
    ["barSizing"] = {
      ["healthHeight"] = 18,
      ["healthWidth"] = 128,
      ["resourceWidth"] = 136,
      ["resourceHeight"] = 8,
    },
    ["positioning"] = {
      ["vertical"] = 1,
      ["spacing"] = 1,
      ["sliderOffsetY"] = 1,
      ["horizontal"] = 1,
      ["sliderOffsetX"] = 1,
    },
    ["useDifferentPowerBarTexture"] = true,
    ["healthBarTexture"] = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture27.tga",
    ["useDifferentCastBarTexture"] = true,
  },
  ["specIcons"] = {
    ["enabled"] = true,
    ["positioning"] = {
      ["vertical"] = -15,
      ["overrides"] = {
      },
      ["sliderOffsetY"] = -12,
      ["horizontal"] = 93,
      ["sliderOffsetX"] = 46,
    },
    ["sizing"] = {
      ["scale"] = 100,
    },
  },
  ["diminishingReturns"] = {
    ["enabled"] = true,
    ["customSpellsList"] = {
    },
    ["sizing"] = {
      ["borderSize"] = 0,
      ["scale"] = 100,
      ["stageFontSize"] = 11,
      ["fontSize"] = 13,
      ["size"] = 33,
    },
    ["rows"] = {
      ["dynamicPositioning"] = true,
      ["mode"] = "Straight",
    },
    ["initialized"] = true,
    ["classSpecEnabled"] = false,
    ["colorCodedBorders"] = false,
    ["positioning"] = {
      ["spacing"] = 3,
      ["timerFontY"] = 1,
      ["growthDirection"] = "Left",
      ["stageFontY"] = 2,
      ["vertical"] = 0,
      ["sliderOffsetY"] = -69,
      ["timerFontX"] = 0,
      ["sliderOffsetX"] = 23,
      ["horizontal"] = -120,
      ["stageFontX"] = -2,
    },
    ["lastSelectedCategory"] = "knockback",
    ["classSpecSelection"] = "",
    ["iconSettings"] = {
      ["incapacitate"] = "118",
      ["knockback"] = "61391",
      ["stun"] = "1833",
      ["root"] = "122",
      ["disorient"] = "8122",
      ["silence"] = "15487",
      ["disarm"] = "236077",
    },
    ["customSpells"] = {
    },
    ["categories"] = {
      ["knockback"] = true,
      ["disarm"] = true,
      ["banish"] = true,
      ["cyclone"] = true,
      ["disorient"] = true,
      ["root"] = true,
      ["incapacitate"] = true,
      ["stun"] = true,
      ["silence"] = true,
      ["mc"] = true,
      ["fear"] = true,
    },
  },
  ["classPacks"] = {
    ["HUNTER"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 19574,
            [2] = 1,
          },
          [2] = {
            [1] = 359844,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 186265,
            [2] = 1,
          },
          [2] = {
            [1] = 264735,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 3355,
            [2] = 1,
          },
          [2] = {
            [1] = 109248,
            [2] = 2,
          },
          [3] = {
            [1] = 213691,
            [2] = 3,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 288613,
            [2] = 1,
          },
          [2] = {
            [1] = 257044,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 186265,
            [2] = 1,
          },
          [2] = {
            [1] = 264735,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 3355,
            [2] = 1,
          },
          [2] = {
            [1] = 109248,
            [2] = 2,
          },
          [3] = {
            [1] = 213691,
            [2] = 3,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 360952,
            [2] = 1,
          },
          [2] = {
            [1] = 360966,
            [2] = 2,
          },
          [3] = {
            [1] = 203415,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 186265,
            [2] = 1,
          },
          [2] = {
            [1] = 264735,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 3355,
            [2] = 1,
          },
          [2] = {
            [1] = 19577,
            [2] = 2,
          },
          [3] = {
            [1] = 190925,
            [2] = 3,
          },
        },
      },
    },
    ["fontSize"] = 16,
    ["ROGUE"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 360194,
            [2] = 1,
          },
          [2] = {
            [1] = 385627,
            [2] = 2,
          },
          [3] = {
            [1] = 212182,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 31224,
            [2] = 1,
          },
          [2] = {
            [1] = 5277,
            [2] = 2,
          },
          [3] = {
            [1] = 1856,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 408,
            [2] = 1,
          },
          [2] = {
            [1] = 1833,
            [2] = 2,
          },
          [3] = {
            [1] = 6770,
            [2] = 3,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 13750,
            [2] = 1,
          },
          [2] = {
            [1] = 51690,
            [2] = 3,
          },
          [3] = {
            [1] = 13877,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 31224,
            [2] = 1,
          },
          [2] = {
            [1] = 5277,
            [2] = 2,
          },
          [3] = {
            [1] = 1856,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 1776,
            [2] = 2,
          },
          [2] = {
            [1] = 408,
            [2] = 1,
          },
          [3] = {
            [1] = 1833,
            [2] = 3,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 185313,
            [2] = 1,
          },
          [2] = {
            [1] = 212283,
            [2] = 2,
          },
          [3] = {
            [1] = 280719,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 31224,
            [2] = 1,
          },
          [2] = {
            [1] = 5277,
            [2] = 2,
          },
          [3] = {
            [1] = 1856,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 1833,
            [2] = 2,
          },
          [2] = {
            [1] = 408,
            [2] = 1,
          },
          [3] = {
            [1] = 6770,
            [2] = 3,
          },
        },
      },
    },
    ["MAGE"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 365350,
            [2] = 1,
          },
          [2] = {
            [1] = 321507,
            [2] = 2,
          },
          [3] = {
            [1] = 376103,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 45438,
            [2] = 1,
          },
          [2] = {
            [1] = 235450,
            [2] = 2,
          },
          [3] = {
            [1] = 110959,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 118,
            [2] = 1,
          },
          [2] = {
            [1] = 31661,
            [2] = 2,
          },
          [3] = {
            [1] = 82691,
            [2] = 2,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 190319,
            [2] = 1,
          },
          [2] = {
            [1] = 153561,
            [2] = 2,
          },
          [3] = {
            [1] = 257541,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 45438,
            [2] = 1,
          },
          [2] = {
            [1] = 235313,
            [2] = 2,
          },
          [3] = {
            [1] = 86949,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 118,
            [2] = 1,
          },
          [2] = {
            [1] = 82691,
            [2] = 2,
          },
          [3] = {
            [1] = 31661,
            [2] = 3,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 12472,
            [2] = 1,
          },
          [2] = {
            [1] = 153595,
            [2] = 2,
          },
          [3] = {
            [1] = 205021,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 45438,
            [2] = 1,
          },
          [2] = {
            [1] = 11426,
            [2] = 2,
          },
          [3] = {
            [1] = 235219,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 118,
            [2] = 1,
          },
          [2] = {
            [1] = 82691,
            [2] = 2,
          },
          [3] = {
            [1] = 31661,
            [2] = 3,
          },
        },
      },
    },
    ["growthDirection"] = "Horizontal",
    ["offsetX"] = 61,
    ["spacing"] = 1,
    ["anchor"] = "TOPLEFT",
    ["DRUID"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 102560,
            [2] = 1,
          },
          [2] = {
            [1] = 391528,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 22812,
            [2] = 1,
          },
          [2] = {
            [1] = 22842,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 33786,
            [2] = 1,
          },
          [2] = {
            [1] = 78675,
            [2] = 2,
          },
          [3] = {
            [1] = 102793,
            [2] = 3,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 102543,
            [2] = 1,
          },
          [2] = {
            [1] = 391528,
            [2] = 3,
          },
          [3] = {
            [1] = 106951,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 61336,
            [2] = 1,
          },
          [2] = {
            [1] = 22812,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 22570,
            [2] = 1,
          },
          [2] = {
            [1] = 5211,
            [2] = 2,
          },
          [3] = {
            [1] = 33786,
            [2] = 1,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 102558,
            [2] = 1,
          },
          [2] = {
            [1] = 391528,
            [2] = 2,
          },
          [3] = {
            [1] = 50334,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 61336,
            [2] = 1,
          },
          [2] = {
            [1] = 22812,
            [2] = 2,
          },
          [3] = {
            [1] = 22842,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 99,
            [2] = 1,
          },
          [2] = {
            [1] = 102793,
            [2] = 2,
          },
          [3] = {
            [1] = 106839,
            [2] = 3,
          },
        },
      },
    },
    ["MONK"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 132578,
            [2] = 1,
          },
          [2] = {
            [1] = 387184,
            [2] = 2,
          },
          [3] = {
            [1] = 386276,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 115203,
            [2] = 1,
          },
          [2] = {
            [1] = 115176,
            [2] = 2,
          },
          [3] = {
            [1] = 122278,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 119381,
            [2] = 1,
          },
          [2] = {
            [1] = 115078,
            [2] = 2,
          },
          [3] = {
            [1] = 116844,
            [2] = 3,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 115310,
            [2] = 1,
          },
          [2] = {
            [1] = 116680,
            [2] = 3,
          },
          [3] = {
            [1] = 116849,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 115203,
            [2] = 1,
          },
          [2] = {
            [1] = 122783,
            [2] = 2,
          },
          [3] = {
            [1] = 122278,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 119381,
            [2] = 2,
          },
          [2] = {
            [1] = 115078,
            [2] = 1,
          },
          [3] = {
            [1] = 116844,
            [2] = 3,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 137639,
            [2] = 1,
          },
          [2] = {
            [1] = 123904,
            [2] = 2,
          },
          [3] = {
            [1] = 285272,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 122783,
            [2] = 1,
          },
          [2] = {
            [1] = 122278,
            [2] = 2,
          },
          [3] = {
            [1] = 115203,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 116844,
            [2] = 3,
          },
          [2] = {
            [1] = 115078,
            [2] = 1,
          },
          [3] = {
            [1] = 119381,
            [2] = 2,
          },
        },
      },
    },
    ["size"] = 25,
    ["DEATHKNIGHT"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 47568,
            [2] = 2,
          },
          [2] = {
            [1] = 49028,
            [2] = 3,
          },
          [3] = {
            [1] = 383269,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 48792,
            [2] = 2,
          },
          [2] = {
            [1] = 48707,
            [2] = 1,
          },
          [3] = {
            [1] = 55233,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 221562,
            [2] = 1,
          },
          [2] = {
            [1] = 108199,
            [2] = 2,
          },
          [3] = {
            [1] = 49576,
            [2] = 3,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 47568,
            [2] = 3,
          },
          [2] = {
            [1] = 51271,
            [2] = 2,
          },
          [3] = {
            [1] = 196770,
            [2] = 1,
          },
        },
        [2] = {
          [1] = {
            [1] = 48707,
            [2] = 1,
          },
          [2] = {
            [1] = 48792,
            [2] = 2,
          },
          [3] = {
            [1] = 51052,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 108194,
            [2] = 2,
          },
          [2] = {
            [1] = 207167,
            [2] = 1,
          },
          [3] = {
            [1] = 49576,
            [2] = 3,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 207289,
            [2] = 1,
          },
          [2] = {
            [1] = 42650,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 48792,
            [2] = 2,
          },
          [2] = {
            [1] = 48707,
            [2] = 1,
          },
          [3] = {
            [1] = 51052,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 108194,
            [2] = 1,
          },
          [2] = {
            [1] = 49576,
            [2] = 2,
          },
        },
      },
    },
    ["PRIEST"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 10060,
            [2] = 1,
          },
          [2] = {
            [1] = 421543,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 33206,
            [2] = 1,
          },
          [2] = {
            [1] = 62618,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 8122,
            [2] = 2,
          },
          [2] = {
            [1] = 605,
            [2] = 1,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 200183,
            [2] = 1,
          },
          [2] = {
            [1] = 372616,
            [2] = 4,
          },
          [3] = {
            [1] = 64843,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 47788,
            [2] = 1,
          },
          [2] = {
            [1] = 64901,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 8122,
            [2] = 2,
          },
          [2] = {
            [1] = 88625,
            [2] = 1,
          },
          [3] = {
            [1] = 605,
            [2] = 2,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 228260,
            [2] = 1,
          },
          [2] = {
            [1] = 10060,
            [2] = 2,
          },
          [3] = {
            [1] = 391109,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 47585,
            [2] = 1,
          },
          [2] = {
            [1] = 108968,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 15487,
            [2] = 2,
          },
          [2] = {
            [1] = 64044,
            [2] = 2,
          },
          [3] = {
            [1] = 8122,
            [2] = 1,
          },
        },
      },
    },
    ["PALADIN"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 31884,
            [2] = 1,
          },
          [2] = {
            [1] = 414170,
            [2] = 2,
          },
          [3] = {
            [1] = 210294,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 642,
            [2] = 1,
          },
          [2] = {
            [1] = 1022,
            [2] = 2,
          },
          [3] = {
            [1] = 31821,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 853,
            [2] = 2,
          },
          [2] = {
            [1] = 20066,
            [2] = 1,
          },
          [3] = {
            [1] = 6940,
            [2] = 3,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 31884,
            [2] = 1,
          },
        },
        [2] = {
          [1] = {
            [1] = 31850,
            [2] = 1,
          },
          [2] = {
            [1] = 86659,
            [2] = 2,
          },
          [3] = {
            [1] = 642,
            [2] = 1,
          },
        },
        [3] = {
          [1] = {
            [1] = 853,
            [2] = 2,
          },
          [2] = {
            [1] = 115750,
            [2] = 2,
          },
          [3] = {
            [1] = 1044,
            [2] = 1,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 31884,
            [2] = 1,
          },
          [2] = {
            [1] = 231895,
            [2] = 2,
          },
          [3] = {
            [1] = 343721,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 642,
            [2] = 1,
          },
          [2] = {
            [1] = 184662,
            [2] = 2,
          },
          [3] = {
            [1] = 1022,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 115750,
            [2] = 2,
          },
          [2] = {
            [1] = 20066,
            [2] = 1,
          },
          [3] = {
            [1] = 853,
            [2] = 3,
          },
        },
      },
    },
    ["WARRIOR"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 107574,
            [2] = 1,
          },
          [2] = {
            [1] = 167105,
            [2] = 2,
          },
          [3] = {
            [1] = 198817,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 118038,
            [2] = 1,
          },
          [2] = {
            [1] = 23920,
            [2] = 2,
          },
          [3] = {
            [1] = 97462,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 107570,
            [2] = 2,
          },
          [2] = {
            [1] = 5246,
            [2] = 2,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 1719,
            [2] = 1,
          },
          [2] = {
            [1] = 107574,
            [2] = 2,
          },
          [3] = {
            [1] = 385059,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 23920,
            [2] = 2,
          },
          [2] = {
            [1] = 97462,
            [2] = 3,
          },
          [3] = {
            [1] = 184364,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 5246,
            [2] = 1,
          },
          [2] = {
            [1] = 107570,
            [2] = 2,
          },
          [3] = {
            [1] = 12323,
            [2] = 3,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 107574,
            [2] = 1,
          },
          [2] = {
            [1] = 385952,
            [2] = 2,
          },
          [3] = {
            [1] = 376079,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 23920,
            [2] = 1,
          },
          [2] = {
            [1] = 12975,
            [2] = 2,
          },
          [3] = {
            [1] = 871,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 46968,
            [2] = 2,
          },
          [2] = {
            [1] = 107570,
            [2] = 2,
          },
        },
      },
    },
    ["WARLOCK"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 386997,
            [2] = 2,
          },
          [2] = {
            [1] = 205180,
            [2] = 1,
          },
          [3] = {
            [1] = 113860,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 104773,
            [2] = 1,
          },
          [2] = {
            [1] = 48020,
            [2] = 3,
          },
          [3] = {
            [1] = 108416,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 5782,
            [2] = 1,
          },
          [2] = {
            [1] = 6789,
            [2] = 2,
          },
          [3] = {
            [1] = 30283,
            [2] = 2,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 265187,
            [2] = 1,
          },
          [2] = {
            [1] = 111898,
            [2] = 2,
          },
          [3] = {
            [1] = 267217,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 104773,
            [2] = 1,
          },
          [2] = {
            [1] = 48020,
            [2] = 3,
          },
          [3] = {
            [1] = 108416,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 5782,
            [2] = 1,
          },
          [2] = {
            [1] = 6789,
            [2] = 2,
          },
          [3] = {
            [1] = 89766,
            [2] = 2,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 1122,
            [2] = 2,
          },
          [2] = {
            [1] = 80240,
            [2] = 3,
          },
          [3] = {
            [1] = 196670,
            [2] = 1,
          },
        },
        [2] = {
          [1] = {
            [1] = 104773,
            [2] = 1,
          },
          [2] = {
            [1] = 48020,
            [2] = 3,
          },
          [3] = {
            [1] = 108416,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 5782,
            [2] = 1,
          },
          [2] = {
            [1] = 6789,
            [2] = 2,
          },
          [3] = {
            [1] = 30283,
            [2] = 2,
          },
        },
      },
    },
    ["DEMONHUNTER"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 191427,
            [2] = 1,
          },
          [2] = {
            [1] = 370965,
            [2] = 2,
          },
          [3] = {
            [1] = 258860,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 198589,
            [2] = 1,
          },
          [2] = {
            [1] = 196555,
            [2] = 2,
          },
          [3] = {
            [1] = 196718,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 217832,
            [2] = 1,
          },
          [2] = {
            [1] = 179057,
            [2] = 3,
          },
          [3] = {
            [1] = 207684,
            [2] = 2,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 187827,
            [2] = 1,
          },
          [2] = {
            [1] = 207407,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 196718,
            [2] = 1,
          },
          [2] = {
            [1] = 204021,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 202137,
            [2] = 1,
          },
          [2] = {
            [1] = 217832,
            [2] = 3,
          },
          [3] = {
            [1] = 207684,
            [2] = 2,
          },
        },
      },
    },
    ["enabled"] = true,
    ["offsetY"] = 29,
    ["EVOKER"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 375087,
            [2] = 1,
          },
          [2] = {
            [1] = 370553,
            [2] = 2,
          },
          [3] = {
            [1] = 357210,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 363916,
            [2] = 1,
          },
          [2] = {
            [1] = 374348,
            [2] = 2,
          },
          [3] = {
            [1] = 374227,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 360806,
            [2] = 1,
          },
          [2] = {
            [1] = 358385,
            [2] = 2,
          },
          [3] = {
            [1] = 372048,
            [2] = 3,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 370960,
            [2] = 1,
          },
          [2] = {
            [1] = 359816,
            [2] = 2,
          },
          [3] = {
            [1] = 370537,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 363916,
            [2] = 1,
          },
          [2] = {
            [1] = 363534,
            [2] = 2,
          },
          [3] = {
            [1] = 357170,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 360806,
            [2] = 1,
          },
          [2] = {
            [1] = 370665,
            [2] = 2,
          },
          [3] = {
            [1] = 374968,
            [2] = 3,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 403631,
            [2] = 1,
          },
          [2] = {
            [1] = 409311,
            [2] = 2,
          },
          [3] = {
            [1] = 370553,
            [2] = 3,
          },
        },
        [2] = {
          [1] = {
            [1] = 363916,
            [2] = 1,
          },
          [2] = {
            [1] = 374348,
            [2] = 2,
          },
          [3] = {
            [1] = 357170,
            [2] = 3,
          },
        },
        [3] = {
          [1] = {
            [1] = 360806,
            [2] = 1,
          },
          [2] = {
            [1] = 358385,
            [2] = 2,
          },
          [3] = {
            [1] = 395152,
            [2] = 3,
          },
        },
      },
    },
    ["SHAMAN"] = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 191634,
            [2] = 2,
          },
          [2] = {
            [1] = 375982,
            [2] = 1,
          },
          [3] = {
            [1] = 114050,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 108271,
            [2] = 1,
          },
          [2] = {
            [1] = 108270,
            [2] = 2,
          },
          [3] = {
            [1] = 198103,
            [2] = 4,
          },
        },
        [3] = {
          [1] = {
            [1] = 192058,
            [2] = 2,
          },
          [2] = {
            [1] = 51514,
            [2] = 1,
          },
          [3] = {
            [1] = 204336,
            [2] = 2,
          },
        },
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 114051,
            [2] = 1,
          },
          [2] = {
            [1] = 51533,
            [2] = 2,
          },
          [3] = {
            [1] = 384352,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 108271,
            [2] = 1,
          },
          [2] = {
            [1] = 108270,
            [2] = 2,
          },
        },
        [3] = {
          [1] = {
            [1] = 51514,
            [2] = 1,
          },
          [2] = {
            [1] = 192058,
            [2] = 2,
          },
          [3] = {
            [1] = 204336,
            [2] = 2,
          },
        },
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 114052,
            [2] = 1,
          },
          [2] = {
            [1] = 108280,
            [2] = 2,
          },
        },
        [2] = {
          [1] = {
            [1] = 108271,
            [2] = 1,
          },
          [2] = {
            [1] = 108270,
            [2] = 2,
          },
          [3] = {
            [1] = 98008,
            [2] = 1,
          },
        },
        [3] = {
          [1] = {
            [1] = 204336,
            [2] = 1,
          },
          [2] = {
            [1] = 192058,
            [2] = 2,
          },
          [3] = {
            [1] = 51514,
            [2] = 1,
          },
        },
      },
    },
  },
  ["castBars"] = {
    ["spellIcons"] = {
      ["enabled"] = true,
      ["positioning"] = {
        ["horizontal"] = -1,
        ["vertical"] = 0,
      },
      ["sizing"] = {
        ["scale"] = 106,
      },
    },
    ["spellSchoolColors"] = false,
    ["positioning"] = {
      ["vertical"] = -46,
      ["sliderOffsetY"] = 0,
      ["horizontal"] = -146,
      ["sliderOffsetX"] = 0,
    },
    ["sizing"] = {
      ["scale"] = 100,
      ["height"] = 25,
      ["width"] = 200,
    },
  },
  ["racials"] = {
    ["enabled"] = true,
    ["positioning"] = {
      ["vertical"] = 1,
      ["overrides"] = {
      },
      ["sliderOffsetY"] = 1,
      ["horizontal"] = 110,
      ["sliderOffsetX"] = 2,
    },
    ["sizing"] = {
      ["scale"] = 142,
      ["fontSize"] = 10,
    },
  },
  ["arenaFrames"] = {
    ["general"] = {
      ["showArenaLabels"] = true,
      ["resourceTextScale"] = 83,
      ["usePercentage"] = true,
      ["arenaNumberScale"] = 119,
      ["playerNameX"] = 131,
      ["arenaNumberX"] = 346,
      ["showNames"] = false,
      ["playerNameScale"] = 105,
      ["showArenaNumbers"] = false,
      ["useClassColors"] = true,
      ["spellTextScale"] = 113,
      ["playerNameY"] = -3,
      ["showArenaServerNames"] = false,
      ["statusText"] = true,
      ["arenaNumberY"] = -3,
      ["healthTextScale"] = 100,
    },
    ["testModeActive"] = true,
    ["positioning"] = {
      ["growthDirection"] = "Down",
      ["vertical"] = 681,
      ["spacing"] = 32,
      ["sliderOffsetY"] = 0,
      ["horizontal"] = 1309,
      ["sliderOffsetX"] = 0,
    },
    ["sizing"] = {
      ["scale"] = 106,
      ["height"] = 43,
      ["width"] = 200,
    },
  },
  ["classIcons"] = {
    ["enabled"] = true,
    ["positioning"] = {
      ["vertical"] = 1,
      ["overrides"] = {
      },
      ["sliderOffsetY"] = -1,
      ["horizontal"] = 202,
      ["sliderOffsetX"] = 0,
    },
    ["sizing"] = {
      ["scale"] = 100,
      ["borderThickness"] = 100,
    },
  },
  ["trinkets"] = {
    ["enabled"] = true,
    ["iconDesign"] = "alliance",
    ["positioning"] = {
      ["vertical"] = 1,
      ["overrides"] = {
      },
      ["sliderOffsetX"] = 1,
      ["horizontal"] = 67,
      ["sliderOffsetY"] = 0,
    },
    ["sizing"] = {
      ["scale"] = 182,
      ["fontSize"] = 10,
    },
  },
}
end

-- Get hardcoded default settings for "Arena Core" theme
function AFT:GetArenaCoreDefaults()
-- ARENA CORE DEFAULT SETTINGS - Your ACTUAL current settings
-- Generated: 2025-11-20 18:46:29
return {
  ["arenaFrames"] = {
    ["positioning"] = {
      ["horizontal"] = 1265.8399658203,
      ["vertical"] = 746,
      ["spacing"] = 36.790000915527,
      ["growthDirection"] = "Down",
      ["sliderOffsetX"] = 62.899963378906,
      ["sliderOffsetY"] = -47.179992675781,
    },
    ["sizing"] = {
      ["width"] = 226.19999694824,
      ["height"] = 73,
      ["scale"] = 106.19999694824,
    },
    ["general"] = {
      ["resourceTextScale"] = 83,
      ["healthTextScale"] = 100,
      ["arenaNumberScale"] = 119,
      ["playerNameY"] = -3,
      ["arenaNumberX"] = 190,
      ["showNames"] = true,
      ["playerNameScale"] = 106,
      ["showArenaNumbers"] = false,
      ["useClassColors"] = true,
      ["spellTextScale"] = 113,
      ["playerNameX"] = 50,
      ["showArenaServerNames"] = false,
      ["statusText"] = true,
      ["arenaNumberY"] = -3,
      ["usePercentage"] = true,
    },
  },
  ["textures"] = {
    ["powerBarTexture"] = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture8.tga",
    ["healthBarTexture"] = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture8.tga",
    ["castBarTexture"] = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture8.tga",
    ["useDifferentPowerBarTexture"] = true,
    ["useDifferentCastBarTexture"] = true,
    ["sizing"] = {
      ["resourceHeight"] = 11,
      ["healthWidth"] = 142.66666412354,
      ["healthHeight"] = 21,
      ["resourceWidth"] = 142.66666412354,
    },
    ["barPosition"] = {
      ["horizontal"] = 56,
      ["vertical"] = 15,
      ["spacing"] = 2,
    },
    ["barSizing"] = {
      ["resourceHeight"] = 8,
      ["healthWidth"] = 128,
      ["healthHeight"] = 18,
      ["resourceWidth"] = 136,
    },
    ["positioning"] = {
      ["horizontal"] = 46.800003051758,
      ["vertical"] = 18.799995422363,
      ["spacing"] = 0.19999998807907,
    },
  },
  ["specIcons"] = {
    ["enabled"] = true,
    ["positioning"] = {
      ["vertical"] = -5.2000122070312,
      ["horizontal"] = -90.670013427734,
    },
    ["sizing"] = {
      ["scale"] = 109.47999572754,
    },
  },
  ["trinkets"] = {
    ["enabled"] = true,
    ["iconDesign"] = "retail",
    ["positioning"] = {
      ["vertical"] = 9.7999877929688,
      ["horizontal"] = 66.579986572266,
    },
    ["sizing"] = {
      ["scale"] = 142,
      ["fontSize"] = 10,
    },
  },
  ["racials"] = {
    ["enabled"] = true,
    ["positioning"] = {
      ["vertical"] = -11.77001953125,
      ["horizontal"] = 81.199981689453,
    },
    ["sizing"] = {
      ["scale"] = 117.70999908447,
      ["fontSize"] = 10,
    },
  },
  ["castBars"] = {
    ["sizing"] = {
      ["height"] = 24,
      ["scale"] = 87,
      ["width"] = 220,
    },
    ["positioning"] = {
      ["vertical"] = -92.399993896484,
      ["horizontal"] = -4,
    },
    ["spellSchoolColors"] = true,
    ["spellIcons"] = {
      ["enabled"] = true,
      ["positioning"] = {
        ["horizontal"] = -5,
        ["vertical"] = 0.39999389648438,
      },
      ["sizing"] = {
        ["scale"] = 94,
      },
    },
  },
  ["diminishingReturns"] = {
    ["spiralAnimation"] = {
      ["opacity"] = 100,
    },
    ["sizing"] = {
      ["fontSize"] = 18,
      ["scale"] = 100,
      ["stageFontSize"] = 12,
      ["borderSize"] = 0,
      ["size"] = 35.400001525879,
    },
    ["rows"] = {
      ["dynamicPositioning"] = true,
      ["mode"] = "Straight",
    },
    ["enabled"] = true,
    ["positioning"] = {
      ["growthDirection"] = "Left",
      ["vertical"] = 0,
      ["horizontal"] = -165,
      ["spacing"] = 3,
    },
    ["initialized"] = true,
  },
  ["classIcons"] = {
    ["enabled"] = true,
    ["theme"] = "arenacore",
    ["positioning"] = {
      ["vertical"] = 9.399995803833,
      ["horizontal"] = 39.2200050354,
    },
    ["sizing"] = {
      ["scale"] = 109,
      ["borderThickness"] = 100,
    },
  },
}
end

-- Load ALL theme-specific settings when switching themes
function AFT:LoadThemeSettings(themeName)
    if not themeName or not AC.DB or not AC.DB.profile then return end
    
    -- CRITICAL FIX: Don't overwrite recent user changes
    -- If user made slider changes within last 5 seconds, preserve those changes
    if AC._recentUserChange then
        print("|cffFFFF00[THEME PROTECTION]|r Preserving recent user changes - skipping theme load")
        return
    end
    
    -- Initialize theme settings storage
    if not AC.DB.profile.themeData then
        AC.DB.profile.themeData = {}
    end
    
    -- Get saved settings for this theme
    local themeData = AC.DB.profile.themeData[themeName]
    
    -- CRITICAL FIX: Detect and fix corrupted arena frame positioning
    -- If horizontal/vertical are too small (< 100), the data is corrupted - reset to defaults
    if themeData and themeData.arenaFrames and themeData.arenaFrames.positioning then
        local pos = themeData.arenaFrames.positioning
        if pos.horizontal and pos.vertical then
            if math.abs(pos.horizontal) < 100 or math.abs(pos.vertical) < 100 then
                print("|cffFF0000[CORRUPTION FIX]|r Theme '" .. themeName .. "' has corrupted arena frames position (h=" .. tostring(pos.horizontal) .. ", v=" .. tostring(pos.vertical) .. ") - resetting to defaults!")
                themeData = nil  -- Force reload from hardcoded defaults
                AC.DB.profile.themeData[themeName] = nil
            end
        end
    end
    
    -- CRITICAL: Load hardcoded defaults for themes if no saved data exists
    if not themeData then
        if themeName == "The 1500 Special" then
            themeData = self:GetThe1500SpecialDefaults()
            if themeData then
                AC.DB.profile.themeData[themeName] = DeepCopy(themeData)
                print("|cff00FF00[THEME RESET]|r Loaded fresh defaults for The 1500 Special")
            end
        elseif themeName == "Arena Core" then
            themeData = self:GetArenaCoreDefaults()
            if themeData then
                AC.DB.profile.themeData[themeName] = DeepCopy(themeData)
                print("|cff00FF00[THEME RESET]|r Loaded fresh defaults for Arena Core")
            end
        end
    end
    
    if themeData then
        -- CRITICAL FIX: Separate global functional settings from theme-specific visual settings
        -- Global settings (statusText, showNames, etc.) persist across themes
        -- Only restore theme-specific visual settings (positions, sizes, etc.)
        
        if themeData.arenaFrames then
            -- CRITICAL FIX: showNames and showArenaLabels are now THEME-SPECIFIC
            -- Only preserve truly global functional settings (statusText, usePercentage, useClassColors)
            local globalSettings = {
                statusText = AC.DB.profile.arenaFrames.general and AC.DB.profile.arenaFrames.general.statusText,
                usePercentage = AC.DB.profile.arenaFrames.general and AC.DB.profile.arenaFrames.general.usePercentage,
                useClassColors = AC.DB.profile.arenaFrames.general and AC.DB.profile.arenaFrames.general.useClassColors,
                showArenaServerNames = AC.DB.profile.arenaFrames.general and AC.DB.profile.arenaFrames.general.showArenaServerNames,
            }
            
            -- Restore theme-specific settings (includes showNames and showArenaLabels)
            -- The theme data ALREADY has the correct slider values saved by SaveCurrentThemeSettings
            AC.DB.profile.arenaFrames = DeepCopy(themeData.arenaFrames)
            
            -- CRITICAL FIX: Sync layout settings with theme data
            -- Both FlatTheme and "simple core" use layoutSettings which is separate from arenaFrames.sizing
            -- We need to sync them so visual sizing matches theme data
            if AC.DB.profile.layoutSettings then
                -- Sync FlatTheme layout (for "The 1500 Special")
                if AC.DB.profile.layoutSettings.Flat and themeData.arenaFrames.sizing then
                    AC.DB.profile.layoutSettings.Flat.width = themeData.arenaFrames.sizing.width or 200
                    AC.DB.profile.layoutSettings.Flat.height = themeData.arenaFrames.sizing.height or 43
                end
                
                -- Sync "simple core" layout (for "Arena Core")
                if AC.DB.profile.layoutSettings["simple core"] and themeData.arenaFrames.sizing then
                    AC.DB.profile.layoutSettings["simple core"].width = themeData.arenaFrames.sizing.width or 235
                    AC.DB.profile.layoutSettings["simple core"].height = themeData.arenaFrames.sizing.height or 68
                end
            end
            
            -- CRITICAL: Restore global settings (don't let theme override these)
            if AC.DB.profile.arenaFrames.general then
                for key, value in pairs(globalSettings) do
                    if value ~= nil then
                        AC.DB.profile.arenaFrames.general[key] = value
                    end
                end
            end
        end
        
        -- CRITICAL ARCHITECTURAL FIX: Only restore VISUAL/POSITION settings from themes
        -- Functional settings (enabled, tracking modes, etc.) are GLOBAL and persist across themes
        
        -- Trinkets: Restore ALL visual settings (positioning, sizing, iconDesign)
        if themeData.trinkets then
            
            local currentEnabled = AC.DB.profile.trinkets and AC.DB.profile.trinkets.enabled
            local currentShowCooldown = AC.DB.profile.trinkets and AC.DB.profile.trinkets.showCooldownText
            
            -- Restore full trinkets object (includes positioning.horizontal/vertical, sizing)
            AC.DB.profile.trinkets = DeepCopy(themeData.trinkets)
            
            -- CRITICAL FIX: Clear old Edit Mode values after loading theme
            if AC.DB.profile.trinkets.positioning then
                AC.DB.profile.trinkets.positioning.draggedBaseX = nil
                AC.DB.profile.trinkets.positioning.draggedBaseY = nil
                AC.DB.profile.trinkets.positioning.sliderOffsetX = nil
                AC.DB.profile.trinkets.positioning.sliderOffsetY = nil
                
                -- CRITICAL: Remove nested positioning corruption
                if AC.DB.profile.trinkets.positioning.positioning then
                    AC.DB.profile.trinkets.positioning.positioning = nil
                end
            end
            
            -- Preserve functional settings
            if currentEnabled ~= nil then AC.DB.profile.trinkets.enabled = currentEnabled end
            if currentShowCooldown ~= nil then AC.DB.profile.trinkets.showCooldownText = currentShowCooldown end
        end
        
        -- Racials: Restore ALL visual settings (positioning, sizing)
        if themeData.racials then
            local currentEnabled = AC.DB.profile.racials and AC.DB.profile.racials.enabled
            
            -- Restore full racials object (includes positioning.horizontal/vertical, sizing)
            AC.DB.profile.racials = DeepCopy(themeData.racials)
            
            -- CRITICAL FIX: Clear old Edit Mode values after loading theme
            if AC.DB.profile.racials.positioning then
                AC.DB.profile.racials.positioning.draggedBaseX = nil
                AC.DB.profile.racials.positioning.draggedBaseY = nil
                AC.DB.profile.racials.positioning.sliderOffsetX = nil
                AC.DB.profile.racials.positioning.sliderOffsetY = nil
                
                -- CRITICAL: Remove nested positioning corruption
                if AC.DB.profile.racials.positioning.positioning then
                    AC.DB.profile.racials.positioning.positioning = nil
                end
            end
            
            -- Preserve functional settings
            if currentEnabled ~= nil then AC.DB.profile.racials.enabled = currentEnabled end
        end
        
        -- Class Icons: Only restore positioning and sizing (selective restore)
        if themeData.classIcons then
            local currentEnabled = AC.DB.profile.classIcons and AC.DB.profile.classIcons.enabled
            local currentIconTheme = AC.DB.profile.classIcons and AC.DB.profile.classIcons.theme
            
            if not AC.DB.profile.classIcons then AC.DB.profile.classIcons = {} end
            
            -- Restore positioning (full object to preserve horizontal/vertical)
            if themeData.classIcons.positioning then
                AC.DB.profile.classIcons.positioning = DeepCopy(themeData.classIcons.positioning)
                
                -- CRITICAL FIX: Clear old Edit Mode values after loading theme
                AC.DB.profile.classIcons.positioning.draggedBaseX = nil
                AC.DB.profile.classIcons.positioning.draggedBaseY = nil
                AC.DB.profile.classIcons.positioning.sliderOffsetX = nil
                AC.DB.profile.classIcons.positioning.sliderOffsetY = nil
                
                -- CRITICAL: Remove nested positioning corruption
                if AC.DB.profile.classIcons.positioning.positioning then
                    AC.DB.profile.classIcons.positioning.positioning = nil
                end
            end
            
            -- Restore sizing (full object to preserve scale/borderThickness)
            if themeData.classIcons.sizing then
                AC.DB.profile.classIcons.sizing = DeepCopy(themeData.classIcons.sizing)
            end
            
            -- Preserve functional settings
            if currentEnabled ~= nil then AC.DB.profile.classIcons.enabled = currentEnabled end
            if currentIconTheme then AC.DB.profile.classIcons.theme = currentIconTheme end
        end
        
        -- Spec Icons: Restore ALL visual settings (positioning, sizing)
        if themeData.specIcons then
            local currentEnabled = AC.DB.profile.specIcons and AC.DB.profile.specIcons.enabled
            
            -- Restore full specIcons object (includes positioning.horizontal/vertical, sizing)
            AC.DB.profile.specIcons = DeepCopy(themeData.specIcons)
            
            -- CRITICAL FIX: Clear old Edit Mode values after loading theme
            if AC.DB.profile.specIcons.positioning then
                AC.DB.profile.specIcons.positioning.draggedBaseX = nil
                AC.DB.profile.specIcons.positioning.draggedBaseY = nil
                AC.DB.profile.specIcons.positioning.sliderOffsetX = nil
                AC.DB.profile.specIcons.positioning.sliderOffsetY = nil
                
                -- CRITICAL: Remove nested positioning corruption
                if AC.DB.profile.specIcons.positioning.positioning then
                    AC.DB.profile.specIcons.positioning.positioning = nil
                end
            end
            
            -- Preserve functional settings
            if currentEnabled ~= nil then AC.DB.profile.specIcons.enabled = currentEnabled end
        end
        
        -- Diminishing Returns: Restore ALL visual settings (positioning, sizing, spacing)
        if themeData.diminishingReturns then
            local currentEnabled = AC.DB.profile.diminishingReturns and AC.DB.profile.diminishingReturns.enabled
            local currentCategories = AC.DB.profile.diminishingReturns and AC.DB.profile.diminishingReturns.categories
            
            -- Restore full diminishingReturns object (includes positioning.horizontal/vertical, sizing, spacing)
            AC.DB.profile.diminishingReturns = DeepCopy(themeData.diminishingReturns)
            
            -- CRITICAL FIX: Clear old Edit Mode values after loading theme
            if AC.DB.profile.diminishingReturns.positioning then
                AC.DB.profile.diminishingReturns.positioning.draggedBaseX = nil
                AC.DB.profile.diminishingReturns.positioning.draggedBaseY = nil
                AC.DB.profile.diminishingReturns.positioning.sliderOffsetX = nil
                AC.DB.profile.diminishingReturns.positioning.sliderOffsetY = nil
            end
            
            -- Preserve functional settings (enabled state and category selections)
            if currentEnabled ~= nil then AC.DB.profile.diminishingReturns.enabled = currentEnabled end
            if currentCategories then AC.DB.profile.diminishingReturns.categories = currentCategories end
        end
        
        -- Cast Bars: Restore ALL visual settings (positioning, sizing, spell icons)
        if themeData.castBars then
            local currentEnabled = AC.DB.profile.castBars and AC.DB.profile.castBars.enabled
            local currentSpellSchoolColors = AC.DB.profile.castBars and AC.DB.profile.castBars.spellSchoolColors
            
            -- Restore full cast bars object (includes positioning.horizontal/vertical, sizing, spellIcons)
            AC.DB.profile.castBars = DeepCopy(themeData.castBars)
            
            -- CRITICAL FIX: Clear old Edit Mode values after loading theme
            if AC.DB.profile.castBars.positioning then
                AC.DB.profile.castBars.positioning.draggedBaseX = nil
                AC.DB.profile.castBars.positioning.draggedBaseY = nil
                AC.DB.profile.castBars.positioning.sliderOffsetX = nil
                AC.DB.profile.castBars.positioning.sliderOffsetY = nil
            end
            
            -- Preserve functional settings
            if currentEnabled ~= nil then AC.DB.profile.castBars.enabled = currentEnabled end
            if currentSpellSchoolColors ~= nil then AC.DB.profile.castBars.spellSchoolColors = currentSpellSchoolColors end
        end
        
        -- Textures: Restore all (these are purely visual)
        if themeData.textures then
            AC.DB.profile.textures = DeepCopy(themeData.textures)
            
            -- CRITICAL FIX: Clear old Edit Mode values after loading theme
            if AC.DB.profile.textures.positioning then
                AC.DB.profile.textures.positioning.draggedBaseX = nil
                AC.DB.profile.textures.positioning.draggedBaseY = nil
                AC.DB.profile.textures.positioning.sliderOffsetX = nil
                AC.DB.profile.textures.positioning.sliderOffsetY = nil
            end
        end
        
        -- Class Packs: Restore ALL visual settings (positioning, sizing, icons per class/spec)
        if themeData.classPacks then
            local currentEnabled = AC.DB.profile.classPacks and AC.DB.profile.classPacks.enabled
            
            -- Restore full classPacks object (includes all class/spec icon configurations, positioning, sizing)
            AC.DB.profile.classPacks = DeepCopy(themeData.classPacks)
            
            -- Preserve functional settings
            if currentEnabled ~= nil then AC.DB.profile.classPacks.enabled = currentEnabled end
        end
        
        -- MORE GOODIES: Only restore visual/position settings, preserve functional settings
        if themeData.moreGoodies then
            if not AC.DB.profile.moreGoodies then AC.DB.profile.moreGoodies = {} end
            
            -- Dispels: Only restore position/size/scale
            if themeData.moreGoodies.dispels then
                local currentEnabled = AC.DB.profile.moreGoodies.dispels and AC.DB.profile.moreGoodies.dispels.enabled
                local currentShowCooldown = AC.DB.profile.moreGoodies.dispels and AC.DB.profile.moreGoodies.dispels.showCooldown
                local currentCooldownDuration = AC.DB.profile.moreGoodies.dispels and AC.DB.profile.moreGoodies.dispels.cooldownDuration
                
                if not AC.DB.profile.moreGoodies.dispels then AC.DB.profile.moreGoodies.dispels = {} end
                AC.DB.profile.moreGoodies.dispels.offsetX = themeData.moreGoodies.dispels.offsetX
                AC.DB.profile.moreGoodies.dispels.offsetY = themeData.moreGoodies.dispels.offsetY
                AC.DB.profile.moreGoodies.dispels.size = themeData.moreGoodies.dispels.size
                AC.DB.profile.moreGoodies.dispels.scale = themeData.moreGoodies.dispels.scale
                AC.DB.profile.moreGoodies.dispels.growthDirection = themeData.moreGoodies.dispels.growthDirection
                
                if currentEnabled ~= nil then AC.DB.profile.moreGoodies.dispels.enabled = currentEnabled end
                if currentShowCooldown ~= nil then AC.DB.profile.moreGoodies.dispels.showCooldown = currentShowCooldown end
                if currentCooldownDuration ~= nil then AC.DB.profile.moreGoodies.dispels.cooldownDuration = currentCooldownDuration end
            end
            
            -- Auras: Only restore position/scale (tracking categories are global)
            if themeData.moreGoodies.auras then
                local currentEnabled = AC.DB.profile.moreGoodies.auras and AC.DB.profile.moreGoodies.auras.enabled
                local currentInterrupt = AC.DB.profile.moreGoodies.auras and AC.DB.profile.moreGoodies.auras.interrupt
                local currentCC = AC.DB.profile.moreGoodies.auras and AC.DB.profile.moreGoodies.auras.crowdControl
                local currentDefensive = AC.DB.profile.moreGoodies.auras and AC.DB.profile.moreGoodies.auras.defensive
                local currentUtility = AC.DB.profile.moreGoodies.auras and AC.DB.profile.moreGoodies.auras.utility
                
                if not AC.DB.profile.moreGoodies.auras then AC.DB.profile.moreGoodies.auras = {} end
                -- Restore visual settings (if they exist in theme data)
                if themeData.moreGoodies.auras.offsetX then AC.DB.profile.moreGoodies.auras.offsetX = themeData.moreGoodies.auras.offsetX end
                if themeData.moreGoodies.auras.offsetY then AC.DB.profile.moreGoodies.auras.offsetY = themeData.moreGoodies.auras.offsetY end
                if themeData.moreGoodies.auras.scale then AC.DB.profile.moreGoodies.auras.scale = themeData.moreGoodies.auras.scale end
                
                -- Preserve functional settings
                if currentEnabled ~= nil then AC.DB.profile.moreGoodies.auras.enabled = currentEnabled end
                if currentInterrupt ~= nil then AC.DB.profile.moreGoodies.auras.interrupt = currentInterrupt end
                if currentCC ~= nil then AC.DB.profile.moreGoodies.auras.crowdControl = currentCC end
                if currentDefensive ~= nil then AC.DB.profile.moreGoodies.auras.defensive = currentDefensive end
                if currentUtility ~= nil then AC.DB.profile.moreGoodies.auras.utility = currentUtility end
            end
            
            -- Absorbs: Only restore opacity (enabled is global)
            if themeData.moreGoodies.absorbs then
                local currentEnabled = AC.DB.profile.moreGoodies.absorbs and AC.DB.profile.moreGoodies.absorbs.enabled
                
                if not AC.DB.profile.moreGoodies.absorbs then AC.DB.profile.moreGoodies.absorbs = {} end
                AC.DB.profile.moreGoodies.absorbs.opacity = themeData.moreGoodies.absorbs.opacity
                
                if currentEnabled ~= nil then AC.DB.profile.moreGoodies.absorbs.enabled = currentEnabled end
            end
            
            -- Party Class Specs: Only restore position/scale
            if themeData.moreGoodies.partyClassSpecs then
                local currentMode = AC.DB.profile.moreGoodies.partyClassSpecs and AC.DB.profile.moreGoodies.partyClassSpecs.mode
                local currentShowHealer = AC.DB.profile.moreGoodies.partyClassSpecs and AC.DB.profile.moreGoodies.partyClassSpecs.showHealerIcon
                
                if not AC.DB.profile.moreGoodies.partyClassSpecs then AC.DB.profile.moreGoodies.partyClassSpecs = {} end
                AC.DB.profile.moreGoodies.partyClassSpecs.scale = themeData.moreGoodies.partyClassSpecs.scale
                AC.DB.profile.moreGoodies.partyClassSpecs.pointerScale = themeData.moreGoodies.partyClassSpecs.pointerScale
                AC.DB.profile.moreGoodies.partyClassSpecs.pointerOffsetX = themeData.moreGoodies.partyClassSpecs.pointerOffsetX
                AC.DB.profile.moreGoodies.partyClassSpecs.pointerOffsetY = themeData.moreGoodies.partyClassSpecs.pointerOffsetY
                
                if currentMode then AC.DB.profile.moreGoodies.partyClassSpecs.mode = currentMode end
                if currentShowHealer ~= nil then AC.DB.profile.moreGoodies.partyClassSpecs.showHealerIcon = currentShowHealer end
            end
            
            -- Debuffs: Only restore position/scale
            if themeData.moreGoodies.debuffs then
                local currentShowTimer = AC.DB.profile.moreGoodies.debuffs and AC.DB.profile.moreGoodies.debuffs.showTimer
                
                if not AC.DB.profile.moreGoodies.debuffs then AC.DB.profile.moreGoodies.debuffs = {} end
                if themeData.moreGoodies.debuffs.offsetX then AC.DB.profile.moreGoodies.debuffs.offsetX = themeData.moreGoodies.debuffs.offsetX end
                if themeData.moreGoodies.debuffs.offsetY then AC.DB.profile.moreGoodies.debuffs.offsetY = themeData.moreGoodies.debuffs.offsetY end
                if themeData.moreGoodies.debuffs.scale then AC.DB.profile.moreGoodies.debuffs.scale = themeData.moreGoodies.debuffs.scale end
                
                if currentShowTimer ~= nil then AC.DB.profile.moreGoodies.debuffs.showTimer = currentShowTimer end
            end
        end
        
        -- BLACKOUT: Only restore visual settings, preserve spell list and enabled state
        if themeData.blackout then
            local currentEnabled = AC.DB.profile.blackout and AC.DB.profile.blackout.enabled
            local currentSpells = AC.DB.profile.blackout and AC.DB.profile.blackout.spells
            local currentEffectType = AC.DB.profile.blackout and AC.DB.profile.blackout.effectType
            
            if not AC.DB.profile.blackout then AC.DB.profile.blackout = {} end
            -- Restore visual settings (if they exist)
            if themeData.blackout.opacity then AC.DB.profile.blackout.opacity = themeData.blackout.opacity end
            if themeData.blackout.duration then AC.DB.profile.blackout.duration = themeData.blackout.duration end
            
            -- Preserve functional settings (spell list, enabled state, effect type)
            if currentEnabled ~= nil then AC.DB.profile.blackout.enabled = currentEnabled end
            if currentSpells then AC.DB.profile.blackout.spells = currentSpells end
            if currentEffectType then AC.DB.profile.blackout.effectType = currentEffectType end
        end
        
        -- print("|cff00FF00[Theme Settings]|r Loaded all settings from theme: " .. themeName)
    else
        -- First time using this theme - save current settings as defaults for this theme
        self:SaveCurrentThemeSettings()
        -- print("|cffFFAA00[Theme Settings]|r First time using theme '" .. themeName .. "' - saved current settings as defaults")
    end
end

function AFT:GetCurrentTheme()
    if AC.DB and AC.DB.profile and AC.DB.profile.arenaFrameTheme then
        return AC.DB.profile.arenaFrameTheme
    end
    return "Arena Core" -- Default
end

function AFT:GetAvailableThemes()
    local themeList = {}
    for themeName, _ in pairs(self.themes) do
        table.insert(themeList, themeName)
    end
    table.sort(themeList)
    return themeList
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function AFT:SwitchTheme(themeName)
    if not self.themes[themeName] then
        print("|cffFF0000ArenaCore Themes:|r Theme not found: " .. tostring(themeName))
        return false
    end
    
    local oldTheme = self:GetCurrentTheme()
    
    -- CRITICAL FIX: Show reload popup FIRST, only apply theme if user clicks OK
    -- This prevents partial theme application if user cancels
    self:ShowReloadConfirmation(themeName, oldTheme)
    
    return false  -- Return false to prevent immediate application
end

-- Internal function to actually apply the theme (called after user confirms reload)
function AFT:_ApplyThemeSwitch(themeName, oldTheme)
    
    -- CRITICAL: Save current theme's ALL settings before switching (OLD WORKING VERSION LOGIC)
    -- This ensures each theme has isolated settings
    self:SaveCurrentThemeSettings()
    
    -- CRITICAL FIX: Update theme name FIRST so GetCurrentTheme() returns correct theme
    -- This prevents LoadThemeSettings from saving to wrong theme
    self:SaveTheme(themeName)
    
    -- Load new theme's ALL settings (will use defaults if no data exists)
    self:LoadThemeSettings(themeName)
    
    -- CRITICAL: Update arena frame positions immediately after loading theme
    if AC.UpdateFramePositions then
        AC:UpdateFramePositions()
    end
    
    -- CRITICAL FIX: Refresh UI sliders to show loaded values
    -- The database has the correct values, but the slider widgets don't auto-update
    if AC.ProfileManager and AC.ProfileManager.RefreshUISliders then
        C_Timer.After(0.1, function()
            AC.ProfileManager:RefreshUISliders()
        end)
    end
    
    -- Apply theme visuals
    if self:ApplyTheme(themeName) then
        
        -- CRITICAL: Refresh ALL layout systems with new theme-specific settings
        
        -- Arena Frames general settings (names, numbers, scales)
        if AC.ApplyGeneralSettings then
            AC:ApplyGeneralSettings()
        end
        
        -- CRITICAL FIX: Reparent health text to absorb frames if in test mode with absorbs enabled
        -- This ensures text stays visible above shields after theme switching
        if AC.testModeEnabled and AC.Absorbs and AC.Absorbs.ForceShowLines then
            C_Timer.After(0.05, function()
                AC.Absorbs:ForceShowLines()
            end)
        end
        
        -- DISABLED: ApplySpecialPositioning was causing name position resets on reload
        -- ApplyGeneralSettings (called above) already handles text positioning correctly
        -- local theme = self.themes[themeName]
        -- if theme and theme.positioning then
        --     local MFM = AC and AC.MasterFrameManager
        --     if MFM and MFM.frames then
        --         for i = 1, 3 do
        --             if MFM.frames[i] then
        --                 self:ApplySpecialPositioning(MFM.frames[i], theme.positioning)
        --             end
        --         end
        --     end
        -- end
        
        -- Frame positioning and spacing
        if AC.UpdateFramePositions then
            -- AC:UpdateFramePositions()  -- TEMPORARILY DISABLED TO TEST
        end
        
        -- CRITICAL FIX: Update frame size after loading theme settings
        -- This applies the width/height from the theme data
        if AC.UpdateFrameSize then
            AC:UpdateFrameSize()
        end
        
        -- Trinkets & Racials & Spec Icons
        -- CRITICAL FIX: Delay refresh to allow UI sliders to update first
        -- Immediate refresh causes scale mismatch because sliders still have old values
        if AC.RefreshTrinketsOtherLayout then
            C_Timer.After(0.1, function()
                if AC.RefreshTrinketsOtherLayout then
                    AC:RefreshTrinketsOtherLayout()
                end
            end)
        end
        
        -- Diminishing Returns
        if AC.RefreshDRLayout and not AC._skipDRRepositionOnSave then
            AC:RefreshDRLayout()
        elseif AC.RefreshDRLayout and AC._skipDRRepositionOnSave then
            print("|cff00FF00[THEME SAVE]|r DR refresh SKIPPED - protection active")
        end
        
        -- Cast Bars
        if AC.RefreshCastBarsLayout then
            AC:RefreshCastBarsLayout()
        end
        
        -- Textures (health/mana bars)
        if AC.RefreshTexturesLayout then
            AC:RefreshTexturesLayout()
        end
        
        -- Class Packs (TriBadges)
        if AC.RefreshClassPacksLayout then
            AC:RefreshClassPacksLayout()
        end
        
        -- CRITICAL FIX: Don't reapply hardcoded theme dimensions!
        -- The theme data already has the user's custom width/height
        -- Reapplying hardcoded defaults (235x68) overwrites user settings
        -- UpdateFrameSize() already applied the correct size from theme data
        
        -- DEBUG DISABLED FOR PRODUCTION
        -- print("|cff8B45FFArenaCore Themes:|r Switched to '" .. themeName .. "' with all theme-specific settings")
        
        -- Theme applied successfully, now reload UI
        ReloadUI()
    end
    
    return false
end

-- Show reload confirmation popup BEFORE applying theme
function AFT:ShowReloadConfirmation(themeName, oldTheme)
    -- Create popup frame
    local popup = CreateFrame("Frame", "ArenaFrameThemeReloadPopup", UIParent)
    popup:SetSize(400, 180)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(9999)
    
    -- Red textured background
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-hide.tga")
    bg:SetVertexColor(1, 0.2, 0.2, 1) -- Red tint
    
    -- Dark overlay for text readability
    local overlay = popup:CreateTexture(nil, "BORDER")
    overlay:SetAllPoints()
    overlay:SetColorTexture(0, 0, 0, 0.4)
    
    -- Title
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
        -- Apply the theme switch, which will automatically reload at the end
        AFT:_ApplyThemeSwitch(themeName, oldTheme)
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
        print("|cffFFAA00Arena Core:|r Theme change cancelled")
    end)
    
    -- Close on Escape
    popup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            popup:Hide()
            print("|cffFFAA00Arena Core:|r Theme change cancelled")
        end
    end)
    popup:EnableKeyboard(true)
    
    popup:Show()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize when addon loads
local function Initialize()
    AFT:InitializeDatabase()
    
    -- Hook into UpdateFramePositions to preserve theme dimensions
    local MFM = AC and AC.MasterFrameManager
    if MFM and MFM.UpdateFramePositions then
        local originalUpdateFramePositions = MFM.UpdateFramePositions
        MFM.UpdateFramePositions = function(self, ...)
            -- Call original function
            originalUpdateFramePositions(self, ...)
            
            -- Reapply theme dimensions if a theme is active
            local currentTheme = AFT:GetCurrentTheme()
            if currentTheme and currentTheme ~= "Arena Core" then
                local theme = AFT.themes[currentTheme]
                if theme and theme.frameWidth and theme.frameHeight then
                    C_Timer.After(0.05, function()
                        -- CRITICAL FIX: Don't resize frames during combat (causes ADDON_ACTION_BLOCKED)
                        -- FrameSort integration can trigger UpdateFramePositions during arena matches
                        -- SetSize() is a protected function and cannot be called in combat
                        if InCombatLockdown() then
                            return
                        end

                        if MFM.frames and AC.ArenaFramesAnchor then
                            -- Get theme-specific spacing for repositioning
                            local themeData = AC.DB and AC.DB.profile and AC.DB.profile.themeData and AC.DB.profile.themeData[currentTheme]
                            local spacing = 21
                            local growthDirection = "Down"
                            if themeData and themeData.arenaFrames and themeData.arenaFrames.positioning then
                                spacing = themeData.arenaFrames.positioning.spacing or 21
                                growthDirection = themeData.arenaFrames.positioning.growthDirection or "Down"
                            end

                            for i = 1, 3 do
                                local f = MFM.frames[i]
                                if f then
                                    f:SetSize(theme.frameWidth, theme.frameHeight)

                                    -- CRITICAL FIX: Re-anchor backgrounds/borders after SetSize
                                    -- This ensures all 3 frames stay identical after theme hook runs
                                    if f.bg then
                                        f.bg:ClearAllPoints()
                                        f.bg:SetAllPoints(f)
                                    end
                                    if f.border then
                                        f.border:ClearAllPoints()
                                        f.border:SetAllPoints(f)
                                    end
                                    if f._themeBackground then
                                        f._themeBackground:ClearAllPoints()
                                        f._themeBackground:SetAllPoints(f)
                                    end
                                    
                                    -- CRITICAL FIX: Reposition frame after SetSize to prevent drift
                                    -- SetSize can cause slight position shifts, so we recalculate and reapply position
                                    -- FRAMESORT FIX: DON'T reposition frames here - let main UpdateFramePositions handle it
                                    -- The main system already positioned frames correctly using FrameSort order
                                    -- This theme hook was overriding that positioning, breaking FrameSort
                                    -- SOLUTION: Only resize frames, don't reposition them
                                    -- REMOVED: f:ClearAllPoints() and f:SetPoint() - let main UpdateFramePositions handle positioning
                                end
                            end
                            
                            -- Extra safety: hard-normalize sizes after theme sizing
                            if AC.NormalizeArenaFrameSizes then
                                AC:NormalizeArenaFrameSizes()
                            end
                            
                            -- DEBUG DISABLED FOR PRODUCTION
                            -- print("|cffFFFF00[Theme Debug]|r Preserved theme dimensions after UpdateFramePositions")
                        end
                    end)
                end
            end
        end
        -- DEBUG DISABLED FOR PRODUCTION
        -- print("|cff8B45FFArenaCore Themes:|r Hooked UpdateFramePositions to preserve theme dimensions")
    end
    
    -- CRITICAL FIX: Create missing RefreshDRLayout function for real-time DR positioning
    if not AC.RefreshDRLayout then
        AC.RefreshDRLayout = function()
            -- Update DR positions for all arena frames in real-time
            local MFM = AC and AC.MasterFrameManager
            if MFM and MFM.frames then
                for i = 1, 3 do
                    local frame = MFM.frames[i]
                    if frame and AC.UpdateDRPositions then
                        AC:UpdateDRPositions(frame)
                    end
                    
                    -- DR container positioning now handled exclusively by DR.lua UpdatePositions/UpdatePositionsWithOffset
                end
                print("|cffFFFF00[DR Debug]|r RefreshDRLayout: Updated DR positions for all frames")
            end
            
            -- ADDITIONAL FIX: Ensure DR containers maintain proper strata after theme changes
            AFT:EnsureDRVisibility()
        end
        -- DEBUG DISABLED FOR PRODUCTION
        -- print("|cff8B45FFArenaCore Themes:|r Created missing RefreshDRLayout function for real-time DR updates")
    end
    
    -- Wait for frame system to be ready
    local attempts = 0
    local function CheckFrameSystem()
        attempts = attempts + 1
        
        local MFM = AC and AC.MasterFrameManager
        if (MFM and MFM.frames) or (_G.ArenaCore and _G.ArenaCore.ArenaFrames) then
            -- DEBUG DISABLED FOR PRODUCTION
            -- print("|cff8B45FFArenaCore Themes:|r Frame system detected, themes ready!")
            -- Apply saved theme if any
            local savedTheme = AFT:GetCurrentTheme()
            if savedTheme then
                C_Timer.After(0.1, function()
                    -- CRITICAL FIX: Don't load theme settings on initialization!
                    -- Settings are already in AC.DB.profile from last session
                    -- Loading theme settings here causes race condition where it overwrites
                    -- current settings while frames are initializing (arena2/arena3 affected most)
                    -- Only load theme settings when user explicitly switches themes
                    
                    -- Just apply visual theme settings (frame sizes, colors, etc.)
                    AFT:ApplyTheme(savedTheme)
                    
                    -- CRITICAL: Refresh textures after theme application
                    -- This ensures health/mana bar textures are applied when reloading in arena
                    C_Timer.After(0.2, function()
                        if AC.RefreshTexturesLayout then
                            AC:RefreshTexturesLayout()
                        end
                    end)
                end)
            end
        elseif attempts < 20 then -- Try for 10 seconds
            C_Timer.After(0.5, CheckFrameSystem)
        else
            print("|cffFF6B6B ArenaCore Themes:|r Warning: Frame system not detected after 10 seconds")
        end
    end
    
    CheckFrameSystem()
end

-- Hook into addon initialization
if AC and AC.DB then
    Initialize()
else
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "ArenaCore" then
            -- CRITICAL FIX: Only initialize once, not on every instance transition
            -- This prevents LoadThemeSettings from overwriting current settings when entering arena
            C_Timer.After(1, function()
                if not AFT._initialized then
                    AFT._initialized = true
                    Initialize()
                end
            end)
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

-- ============================================================================
-- THEME SETTINGS EXPORT/IMPORT
-- ============================================================================

-- Helper function to serialize table to Lua code
local function SerializeValue(val, indent)
    indent = indent or ""
    local t = type(val)
    
    if t == "string" then
        return string.format("%q", val)
    elseif t == "number" or t == "boolean" then
        return tostring(val)
    elseif t == "table" then
        local lines = {"{"}
        for k, v in pairs(val) do
            local key
            if type(k) == "string" then
                key = string.format("[%q]", k)
            else
                key = "[" .. k .. "]"
            end
            table.insert(lines, indent .. "  " .. key .. " = " .. SerializeValue(v, indent .. "  ") .. ",")
        end
        table.insert(lines, indent .. "}")
        return table.concat(lines, "\n")
    else
        return "nil"
    end
end

-- Create export popup window with copy/paste functionality
local function CreateExportWindow(title, content)
    -- Create main frame
    local frame = CreateFrame("Frame", "ACThemeExportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(700, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    
    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetSize(700, 30)
    titleBar:SetPoint("TOP", 0, 12)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    
    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    titleText:SetText(title)
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleText:SetTextColor(1, 0.82, 0, 1)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    
    -- Scroll frame for text
    local scrollFrame = CreateFrame("ScrollFrame", "ACThemeExportScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -40, 50)
    
    -- Edit box for text content
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth() - 20)
    editBox:SetText(content)
    editBox:SetCursorPosition(0)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    
    scrollFrame:SetScrollChild(editBox)
    
    -- Select All button
    local selectAllBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    selectAllBtn:SetSize(100, 25)
    selectAllBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 15)
    selectAllBtn:SetText("Select All")
    selectAllBtn:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)
    
    -- Copy instruction text
    local instructionText = frame:CreateFontString(nil, "OVERLAY")
    instructionText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    instructionText:SetText("Press Ctrl+C to copy, then paste into GetThe1500SpecialDefaults() function")
    instructionText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    instructionText:SetTextColor(0.8, 0.8, 0.8, 1)
    
    -- Auto-select all text when window opens
    C_Timer.After(0.1, function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)
    
    frame:Show()
    return frame
end

-- Export current theme settings to popup window for baking into defaults
SLASH_ACTHEME_EXPORT1 = "/actheme_export"
SlashCmdList["ACTHEME_EXPORT"] = function()
    local currentTheme = AFT:GetCurrentTheme()
    if not currentTheme then
        print("|cffFF0000[Theme Export]|r No active theme")
        return
    end
    
    if currentTheme ~= "The 1500 Special" then
        print("|cffFF0000[Theme Export]|r Please switch to 'The 1500 Special' theme first!")
        print("|cffFFAA00[Theme Export]|r Use: /actheme The 1500 Special")
        return
    end
    
    -- Save current settings first
    AFT:SaveCurrentThemeSettings()
    
    -- Get the saved data
    local themeData = AC.DB.profile.themeData and AC.DB.profile.themeData[currentTheme]
    if not themeData then
        print("|cffFF0000[Theme Export]|r No saved data for this theme")
        return
    end
    
    -- Generate Lua code
    local luaCode = "-- Paste this into GetThe1500SpecialDefaults() function\n"
    luaCode = luaCode .. "-- Generated: " .. date("%Y-%m-%d %H:%M:%S") .. "\n"
    luaCode = luaCode .. "return " .. SerializeValue(themeData, "")
    
    -- Create popup window with the code
    CreateExportWindow("The 1500 Special - Theme Settings Export", luaCode)
    
    print("|cff00FF00[Theme Export]|r Export window opened! Select all (Ctrl+A) and copy (Ctrl+C)")
end

-- CRITICAL FIX: Export CURRENT LIVE settings, not cached theme data
SLASH_ACTHEME_EXPORT_LIVE1 = "/actheme_export_live"
SlashCmdList["ACTHEME_EXPORT_LIVE"] = function()
    local currentTheme = AFT:GetCurrentTheme()
    if not currentTheme then
        print("|cffFF0000[Theme Export]|r No active theme")
        return
    end
    
    if currentTheme ~= "The 1500 Special" then
        print("|cffFF0000[Theme Export]|r Please switch to 'The 1500 Special' theme first!")
        print("|cffFFAA00[Theme Export]|r Use: /actheme The 1500 Special")
        return
    end
    
    -- CRITICAL: Read DIRECTLY from current profile, not from themeData cache
    local liveData = {
        arenaFrames = AC.DB.profile.arenaFrames and DeepCopy(AC.DB.profile.arenaFrames) or nil,
        trinkets = AC.DB.profile.trinkets and DeepCopy(AC.DB.profile.trinkets) or nil,
        racials = AC.DB.profile.racials and DeepCopy(AC.DB.profile.racials) or nil,
        specIcons = AC.DB.profile.specIcons and DeepCopy(AC.DB.profile.specIcons) or nil,
        diminishingReturns = AC.DB.profile.diminishingReturns and DeepCopy(AC.DB.profile.diminishingReturns) or nil,
        castBars = AC.DB.profile.castBars and DeepCopy(AC.DB.profile.castBars) or nil,
        textures = AC.DB.profile.textures and DeepCopy(AC.DB.profile.textures) or nil,
        classPacks = AC.DB.profile.classPacks and DeepCopy(AC.DB.profile.classPacks) or nil,
        classIcons = AC.DB.profile.classIcons and DeepCopy(AC.DB.profile.classIcons) or nil,
    }
    
    -- Generate Lua code
    local luaCode = "-- LIVE SETTINGS EXPORT - Your ACTUAL current settings\n"
    luaCode = luaCode .. "-- Paste this into GetThe1500SpecialDefaults() function\n"
    luaCode = luaCode .. "-- Generated: " .. date("%Y-%m-%d %H:%M:%S") .. "\n"
    luaCode = luaCode .. "return " .. SerializeValue(liveData, "")
    
    -- Create popup window with the code
    CreateExportWindow("The 1500 Special - LIVE Settings Export", luaCode)
    
    print("|cff00FF00[Theme Export LIVE]|r Export window opened with your CURRENT settings!")
    print("|cffFFAA00[Theme Export LIVE]|r This exports what you see RIGHT NOW, not cached data")
end

-- ============================================================================
-- DEBUG COMMANDS
-- ============================================================================

-- Slash command to export Arena Core defaults (LIVE settings)
SLASH_ACEXPORTDEFAULTS1 = "/acexportdefaults"
SlashCmdList["ACEXPORTDEFAULTS"] = function()
    local currentTheme = AFT:GetCurrentTheme()
    
    if currentTheme ~= "Arena Core" then
        print("|cffFF0000[Export]|r Please switch to Arena Core theme first!")
        print("|cffFFAA00[Export]|r Current theme: " .. tostring(currentTheme))
        return
    end
    
    -- CRITICAL: Read DIRECTLY from current profile, not from themeData cache
    local liveData = {
        arenaFrames = AC.DB.profile.arenaFrames and DeepCopy(AC.DB.profile.arenaFrames) or nil,
        trinkets = AC.DB.profile.trinkets and DeepCopy(AC.DB.profile.trinkets) or nil,
        racials = AC.DB.profile.racials and DeepCopy(AC.DB.profile.racials) or nil,
        specIcons = AC.DB.profile.specIcons and DeepCopy(AC.DB.profile.specIcons) or nil,
        diminishingReturns = AC.DB.profile.diminishingReturns and DeepCopy(AC.DB.profile.diminishingReturns) or nil,
        castBars = AC.DB.profile.castBars and DeepCopy(AC.DB.profile.castBars) or nil,
        textures = AC.DB.profile.textures and DeepCopy(AC.DB.profile.textures) or nil,
        classPacks = AC.DB.profile.classPacks and DeepCopy(AC.DB.profile.classPacks) or nil,
        classIcons = AC.DB.profile.classIcons and DeepCopy(AC.DB.profile.classIcons) or nil,
    }
    
    -- Generate Lua code
    local luaCode = "-- ARENA CORE DEFAULT SETTINGS - Your ACTUAL current settings\n"
    luaCode = luaCode .. "-- Paste this into GetArenaCoreDefaults() function\n"
    luaCode = luaCode .. "-- Replace the 'return nil' and commented block with this:\n"
    luaCode = luaCode .. "-- Generated: " .. date("%Y-%m-%d %H:%M:%S") .. "\n"
    luaCode = luaCode .. "return " .. SerializeValue(liveData, "")
    
    -- Create popup window with the code
    CreateExportWindow("Arena Core - LIVE Settings Export", luaCode)
    
    print("|cff00FF00[Arena Core Export]|r Export window opened!")
    print("|cffFFAA00[Arena Core Export]|r This exports your CURRENT settings as defaults")
    print("|cffFFAA00[Arena Core Export]|r Copy the code and send it to rebuild GetArenaCoreDefaults()")
end

-- Slash command to reset theme to clean defaults
SLASH_ACTHEME_RESET1 = "/actheme_reset"
SlashCmdList["ACTHEME_RESET"] = function()
    local currentTheme = AFT:GetCurrentTheme()
    
    if currentTheme == "The 1500 Special" then
        -- Force load clean defaults
        print("|cffFFAA00[Theme Reset]|r Resetting 'The 1500 Special' to clean defaults...")
        
        -- Delete saved data
        if AC.DB and AC.DB.profile and AC.DB.profile.themeData then
            AC.DB.profile.themeData["The 1500 Special"] = nil
        end
        
        -- Load defaults
        local defaults = AFT:GetThe1500SpecialDefaults()
        if defaults then
            AC.DB.profile.themeData["The 1500 Special"] = DeepCopy(defaults)
            
            -- CRITICAL: Reload theme settings to update database
            AFT:LoadThemeSettings("The 1500 Special")
            
            -- CRITICAL: Reapply theme visuals to actually move the frames
            AFT:ApplyTheme("The 1500 Special")
            
            -- CRITICAL: Refresh ALL layout systems with new positions
            if AC.ApplyGeneralSettings then
                AC:ApplyGeneralSettings()
            end
            
            if AC.RefreshTrinketsOtherLayout then
                AC:RefreshTrinketsOtherLayout()
            end
            
            if AC.RefreshRacials then
                AC:RefreshRacials()
            end
            
            if AC.RefreshClassIcons then
                AC:RefreshClassIcons()
            end
            
            if AC.CastBars and AC.CastBars.RefreshLayout then
                AC.CastBars:RefreshLayout()
            end
            
            -- Force MFM to reposition everything
            local MFM = AC and AC.MasterFrameManager
            if MFM and MFM.RefreshAllFrames then
                MFM:RefreshAllFrames()
            end
            
            print("|cff00FF00[Theme Reset]|r ✅ Clean defaults loaded! All positions reset to 0.")
            print("|cff00FFFF[Theme Reset]|r Trinkets, Racials, Class Icons, Cast Bars are now at default positions.")
            print("|cffFFAA00[Theme Reset]|r If positions still look wrong, try /reload")
        else
            print("|cffFF0000[Theme Reset]|r Failed to load defaults!")
        end
    else
        print("|cffFF0000[Theme Reset]|r This command only works for 'The 1500 Special' theme.")
        print("|cffFFAA00[Theme Reset]|r Current theme: " .. tostring(currentTheme))
        print("|cffFFAA00[Theme Reset]|r Switch to 'The 1500 Special' first: /actheme The 1500 Special")
    end
end

-- Auto-save theme settings on logout/reload
local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:RegisterEvent("PLAYER_LEAVING_WORLD")  -- Fires on /reload
logoutFrame:SetScript("OnEvent", function(self, event)
    if AFT and AFT.SaveCurrentThemeSettings then
        -- DEBUG DISABLED FOR PRODUCTION
        -- print("|cffFF00FF[AUTO-SAVE]|r Saving theme settings on " .. event)
        AFT:SaveCurrentThemeSettings()
    end
end)

-- Export current Arena Core theme settings for Init.lua defaults
SLASH_ARENACORE_EXPORT1 = "/acexport"
SlashCmdList["ARENACORE_EXPORT"] = function(msg)
    local currentTheme = AFT:GetCurrentTheme()
    
    if currentTheme ~= "Arena Core" then
        print("|cffFF0000[Export]|r Please switch to Arena Core theme first!")
        print("|cffFFAA00[Export]|r Current theme: " .. tostring(currentTheme))
        return
    end
    
    -- Get current settings from database
    local db = AC.DB and AC.DB.profile
    if not db then
        print("|cffFF0000[Export]|r Database not available!")
        return
    end
    
    -- Build export text
    local exportText = "-- Arena Core Theme Defaults Export\n"
    exportText = exportText .. "-- Copy these lines and replace in Core/Init.lua (lines 2427-2478)\n\n"
    
    -- Export Arena Frames positioning
    if db.arenaFrames and db.arenaFrames.positioning then
        local p = db.arenaFrames.positioning
        exportText = exportText .. string.format('        S:EnsureDefault("arenaFrames.positioning.horizontal", %d)\n', p.horizontal or 0)
        exportText = exportText .. string.format('        S:EnsureDefault("arenaFrames.positioning.vertical", %d)\n', p.vertical or 0)
        exportText = exportText .. string.format('        S:EnsureDefault("arenaFrames.positioning.spacing", %d)\n', p.spacing or 21)
        exportText = exportText .. string.format('        S:EnsureDefault("arenaFrames.positioning.growthDirection", "%s")\n\n', p.growthDirection or "Down")
    end
    
    -- Export Arena Frames sizing
    if db.arenaFrames and db.arenaFrames.sizing then
        local s = db.arenaFrames.sizing
        exportText = exportText .. string.format('        S:EnsureDefault("arenaFrames.sizing.scale", %d)\n', s.scale or 121)
        exportText = exportText .. string.format('        S:EnsureDefault("arenaFrames.sizing.width", %d)\n', s.width or 235)
        exportText = exportText .. string.format('        S:EnsureDefault("arenaFrames.sizing.height", %d)\n\n', s.height or 68)
    end
    
    -- Export Trinkets
    if db.trinkets then
        if db.trinkets.positioning then
            local p = db.trinkets.positioning
            exportText = exportText .. string.format('        S:EnsureDefault("trinkets.positioning.horizontal", %.10f)\n', p.horizontal or 0)
            exportText = exportText .. string.format('        S:EnsureDefault("trinkets.positioning.vertical", %.10f)\n', p.vertical or 0)
        end
        if db.trinkets.sizing then
            local s = db.trinkets.sizing
            exportText = exportText .. string.format('        S:EnsureDefault("trinkets.sizing.scale", %d)\n\n', s.scale or 100)
        end
    end
    
    -- Export Racials
    if db.racials then
        if db.racials.positioning then
            local p = db.racials.positioning
            exportText = exportText .. string.format('        S:EnsureDefault("racials.positioning.horizontal", %.10f)\n', p.horizontal or 0)
            exportText = exportText .. string.format('        S:EnsureDefault("racials.positioning.vertical", %.10f)\n', p.vertical or 0)
        end
        if db.racials.sizing then
            local s = db.racials.sizing
            exportText = exportText .. string.format('        S:EnsureDefault("racials.sizing.scale", %d)\n\n', s.scale or 100)
        end
    end
    
    -- Export Class Icons
    if db.classIcons then
        if db.classIcons.positioning then
            local p = db.classIcons.positioning
            exportText = exportText .. string.format('        S:EnsureDefault("classIcons.positioning.vertical", %.10f)\n', p.vertical or 0)
            exportText = exportText .. string.format('        S:EnsureDefault("classIcons.positioning.horizontal", %.10f)\n', p.horizontal or -2)
        end
        if db.classIcons.sizing then
            local s = db.classIcons.sizing
            exportText = exportText .. string.format('        S:EnsureDefault("classIcons.sizing.scale", %d)\n', s.scale or 100)
        end
    end
    
    -- Create popup window
    local popup = CreateFrame("Frame", "ArenaCoreExportWindow", UIParent)
    popup:SetSize(600, 500)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(2000)
    
    -- Background
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.95)
    
    -- Border
    local border = popup:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetColorTexture(0.5, 0.3, 0.7, 1)
    
    -- Title
    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Arena Core Theme Export")
    title:SetTextColor(0.7, 0.5, 1, 1)
    
    -- Instructions
    local instructions = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOP", title, "BOTTOM", 0, -10)
    instructions:SetText("Ctrl+A to select all, then Ctrl+C to copy")
    instructions:SetTextColor(1, 1, 0.5, 1)
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    -- Edit box
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetAutoFocus(false)
    editBox:SetText(exportText)
    editBox:SetCursorPosition(0)
    editBox:HighlightText()
    
    -- Edit box background
    local editBg = editBox:CreateTexture(nil, "BACKGROUND")
    editBg:SetAllPoints()
    editBg:SetColorTexture(0.05, 0.05, 0.05, 1)
    
    scrollFrame:SetScrollChild(editBox)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, popup)
    closeBtn:SetSize(100, 32)
    closeBtn:SetPoint("BOTTOM", 0, 12)
    
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.5, 0.3, 0.7, 0.8)
    
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER")
    closeText:SetText("Close")
    closeText:SetTextColor(1, 1, 1, 1)
    
    closeBtn:SetScript("OnClick", function()
        popup:Hide()
    end)
    
    closeBtn:SetScript("OnEnter", function()
        closeBg:SetColorTexture(0.6, 0.4, 0.8, 1)
    end)
    
    closeBtn:SetScript("OnLeave", function()
        closeBg:SetColorTexture(0.5, 0.3, 0.7, 0.8)
    end)
    
    -- Make draggable
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
    
    -- Auto-select text when shown
    popup:SetScript("OnShow", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)
    
    popup:Show()
    
    print("|cff00FF00[Export]|r Export window opened! Ctrl+A to select all, Ctrl+C to copy")
end

-- Slash command for testing themes
SLASH_ARENACORE_THEME1 = "/actheme"
SlashCmdList["ARENACORE_THEME"] = function(msg)
    local themeName = msg:trim()
    
    if themeName == "" then
        print("|cff00FFFF[ArenaCore Themes]|r Available themes:")
        for name, theme in pairs(AFT.themes) do
            local current = (name == AFT:GetCurrentTheme()) and " |cff00FF00(CURRENT)|r" or ""
            print("  - " .. name .. current)
        end
        print("|cff00FFFF[ArenaCore Themes]|r Usage: /actheme <theme name>")
        print("|cff00FFFF[ArenaCore Themes]|r Debug: /actheme debug")
        return
    end
    
    if themeName:lower() == "debug" then
        print("|cff00FFFF[ArenaCore Themes Debug]|r System Status:")
        print("  ArenaCore: " .. tostring(_G.ArenaCore ~= nil))
        local MFM = AC and AC.MasterFrameManager
        print("  AC.MasterFrameManager: " .. tostring(MFM ~= nil))
        print("  Global MFM: " .. tostring(_G.MFM ~= nil))
        print("  AFT: " .. tostring(AFT ~= nil))
        if MFM and MFM.frames then
            local frameCount = 0
            for i = 1, 3 do
                if MFM.frames[i] then frameCount = frameCount + 1 end
            end
            print("  MFM frames: " .. frameCount .. "/3")
        end
        if _G.ArenaCore and _G.ArenaCore.ArenaFrames then
            print("  AC frames: " .. tostring(#_G.ArenaCore.ArenaFrames or 0))
        end
        return
    end
    
    if AFT:SwitchTheme(themeName) then
        print("|cff00FF00[ArenaCore Themes]|r Switched to: " .. themeName)
    else
        print("|cffFF0000[ArenaCore Themes]|r Failed to switch to: " .. themeName)
    end
end
