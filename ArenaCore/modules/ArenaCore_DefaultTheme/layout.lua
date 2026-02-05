-- ============================================================================
-- ARENACORE DEFAULT THEME - ISOLATED MODULE
-- ============================================================================
-- Complete self-contained theme following the proven 1500 Special pattern
-- This eliminates tight coupling with ArenaCore.lua and provides stability
-- ============================================================================

local layoutName = "ArenaCore"
local layout = {}

-- ============================================================================
-- DEFAULT SETTINGS (Source of Truth)
-- ============================================================================
-- These are the user's expertly configured defaults from Init.lua
-- All positioning, sizing, and feature settings in one place

layout.defaultSettings = {
    -- Frame Positioning (from Init.lua defaults)
    posX = 1244,
    posY = -253,
    scale = 1.21,
    spacing = 21,
    growthDirection = 2, -- Down (1=Up, 2=Down, 3=Left, 4=Right)
    
    -- Frame Dimensions
    width = 235,
    height = 68,
    
    -- Class Icon
    classIconSize = 32,
    classIconFontSize = 14,
    
    -- Spec Icon
    specIcon = {
        posX = -20,
        posY = 0,
        scale = 1.0,
        size = 25,
    },
    
    -- Trinket
    trinket = {
        posX = 0,
        posY = -20,
        scale = 1.0,
        fontSize = 10,
        size = 32,
    },
    
    -- Racial
    racial = {
        posX = 0,
        posY = 20,
        scale = 1.0,
        fontSize = 10,
        size = 32,
    },
    
    -- Cast Bar
    castBar = {
        posX = 2,
        posY = -82,
        scale = 0.86,
        width = 227,
        height = 18,
        spellIconScale = 1.01,
        spellIconEnabled = true,
    },
    
    -- Diminishing Returns
    dr = {
        posX = 236,
        posY = 0,
        size = 33,
        borderSize = 0,
        fontSize = 15,
        spacing = 3,
        growthDirection = 3, -- Left
        mode = "Stacking",
    },
    
    -- Health Bar
    healthBarHeight = 18,
    
    -- Power Bar
    powerBarHeight = 8,
    
    -- Text Settings
    playerNameX = 52,
    playerNameY = 0,
    playerNameScale = 86,
    arenaNumberX = 190,
    arenaNumberY = -3,
    arenaNumberScale = 119,
    resourceTextScale = 83,
    spellTextScale = 113,
    
    -- Bar Positioning
    barHorizontal = 56,
    barVertical = 16,
    barSpacing = 2,
    
    -- Features
    showArenaNumbers = true,
    useClassColors = true,
    showStatusText = true,
    usePercentage = false,
    
    -- Textures (use user's selected textures)
    useCustomTextures = true,
    useDifferentPowerBarTexture = true,
    useDifferentCastBarTexture = true,
}

-- ============================================================================
-- SETTINGS MANAGEMENT
-- ============================================================================

local function getSetting(info)
    return layout.db[info[#info]]
end

local function setSetting(info, val)
    layout.db[info[#info]] = val
    
    -- Update all 3 arena frames
    for i = 1, 3 do
        local frame = info.handler["arena"..i]
        if frame then
            -- Apply the changed setting
            layout:UpdateFrame(frame)
        end
    end
end

-- ============================================================================
-- OPTIONS TABLE SETUP
-- ============================================================================

local function setupOptionsTable(self)
    layout.optionsTable = self:GetLayoutOptionsTable(layoutName)
    
    -- Add any ArenaCore-specific options here
end

-- ============================================================================
-- FRAME INITIALIZATION
-- ============================================================================

function layout:Initialize(frame)
    -- Store reference to database
    self.db = frame.parent.db.profile.layoutSettings[layoutName]
    
    -- Setup options table if not already done
    if not self.optionsTable then
        setupOptionsTable(frame.parent)
    end
    
    -- Update parent settings (only on frame 3 to avoid redundant calls)
    if frame:GetID() == 3 then
        frame.parent:UpdateCastBarSettings(self.db.castBar)
        frame.parent:UpdateDRSettings(self.db.dr)
        frame.parent:UpdateFrameSettings(self.db)
        frame.parent:UpdateSpecIconSettings(self.db.specIcon)
        frame.parent:UpdateTrinketSettings(self.db.trinket)
        frame.parent:UpdateRacialSettings(self.db.racial)
    end
    
    -- Apply frame-specific settings
    self:ApplyFrameSettings(frame)
end

-- ============================================================================
-- FRAME SETTINGS APPLICATION
-- ============================================================================

function layout:ApplyFrameSettings(frame)
    -- Set frame dimensions
    frame:SetSize(self.db.width, self.db.height)
    
    -- Set icon sizes
    frame.ClassIcon:SetSize(self.db.classIconSize, self.db.classIconSize)
    frame.ClassIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Standard crop
    
    frame.SpecIcon:SetSize(self.db.specIcon.size, self.db.specIcon.size)
    frame.SpecIcon.Texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    frame.Trinket:SetSize(self.db.trinket.size, self.db.trinket.size)
    frame.Trinket.Texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    frame.Racial:SetSize(self.db.racial.size, self.db.racial.size)
    frame.Racial.Texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- Apply textures
    self:ApplyTextures(frame)
    
    -- Apply text settings
    self:ApplyTextSettings(frame)
    
    -- Apply bar positioning
    self:ApplyBarPositioning(frame)
    
    -- Show class icon
    frame.ClassIcon:Show()
end

-- ============================================================================
-- TEXTURE APPLICATION
-- ============================================================================

function layout:ApplyTextures(frame)
    -- Get ArenaCore texture settings
    local AC = _G.ArenaCore
    if not AC or not AC.DB or not AC.DB.profile then return end
    
    local textures = AC.DB.profile.textures
    if not textures then return end
    
    -- Health bar texture
    local healthTex = textures.healthTexture or "Interface\\AddOns\\ArenaCore\\Media\\Textures\\texture1.tga"
    frame.HealthBar:SetStatusBarTexture(healthTex)
    
    -- Power bar texture
    local powerTex = textures.powerTexture or healthTex
    if self.db.useDifferentPowerBarTexture and textures.powerTexture then
        powerTex = textures.powerTexture
    end
    frame.PowerBar:SetStatusBarTexture(powerTex)
    frame.PowerBar:SetHeight(self.db.powerBarHeight)
    
    -- Cast bar texture
    local castTex = textures.castTexture or healthTex
    if self.db.useDifferentCastBarTexture and textures.castTexture then
        castTex = textures.castTexture
    end
    frame.CastBar:SetStatusBarTexture(castTex)
end

-- ============================================================================
-- TEXT SETTINGS
-- ============================================================================

function layout:ApplyTextSettings(frame)
    -- Get ArenaCore for custom font
    local AC = _G.ArenaCore
    local customFont = "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf"
    
    -- Player Name
    local nameFont = frame.Name
    if nameFont then
        nameFont:SetJustifyH("LEFT")
        nameFont:SetJustifyV("MIDDLE")
        if AC and AC.SafeSetFont then
            AC.SafeSetFont(nameFont, customFont, 12, "OUTLINE")
        else
            nameFont:SetFont(customFont, 12, "OUTLINE")
        end
        nameFont:SetShadowOffset(1, -1)
        nameFont:SetShadowColor(0, 0, 0, 1)
        
        -- Position player name
        nameFont:ClearAllPoints()
        nameFont:SetPoint("TOPLEFT", frame, "TOPLEFT", self.db.playerNameX, self.db.playerNameY)
    end
    
    -- Health Text
    if frame.HealthText then
        if AC and AC.SafeSetFont then
            AC.SafeSetFont(frame.HealthText, customFont, 10, "OUTLINE")
        else
            frame.HealthText:SetFont(customFont, 10, "OUTLINE")
        end
        frame.HealthText:SetPoint("CENTER", frame.HealthBar)
        frame.HealthText:SetShadowOffset(1, -1)
    end
    
    -- Power Text
    if frame.PowerText then
        if AC and AC.SafeSetFont then
            AC.SafeSetFont(frame.PowerText, customFont, 9, "OUTLINE")
        else
            frame.PowerText:SetFont(customFont, 9, "OUTLINE")
        end
        frame.PowerText:SetPoint("CENTER", frame.PowerBar)
        frame.PowerText:SetShadowOffset(1, -1)
    end
end

-- ============================================================================
-- BAR POSITIONING
-- ============================================================================

function layout:ApplyBarPositioning(frame)
    local healthBar = frame.HealthBar
    local powerBar = frame.PowerBar
    local classIcon = frame.ClassIcon
    
    -- Clear all points
    healthBar:ClearAllPoints()
    powerBar:ClearAllPoints()
    classIcon:ClearAllPoints()
    
    -- Standard ArenaCore layout: Class icon on left, bars on right
    classIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    
    healthBar:SetPoint("TOPLEFT", classIcon, "TOPRIGHT", self.db.barHorizontal, self.db.barVertical)
    healthBar:SetPoint("BOTTOMRIGHT", powerBar, "TOPRIGHT", 0, self.db.barSpacing)
    
    powerBar:SetPoint("BOTTOMLEFT", classIcon, "BOTTOMRIGHT", self.db.barHorizontal, 0)
    powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
end

-- ============================================================================
-- FRAME UPDATE (Called when settings change)
-- ============================================================================

function layout:UpdateFrame(frame)
    if not frame then return end
    
    -- Reapply all settings
    self:ApplyFrameSettings(frame)
    
    -- Update orientation if needed
    self:UpdateOrientation(frame)
end

-- ============================================================================
-- ORIENTATION UPDATE
-- ============================================================================

function layout:UpdateOrientation(frame)
    -- ArenaCore default theme uses standard left-to-right layout
    -- Class icon on left, bars on right
    
    self:ApplyBarPositioning(frame)
end

-- ============================================================================
-- INTEGRATION WITH ARENACORE SYSTEMS
-- ============================================================================

function layout:IntegrateWithArenaCore(frame)
    -- This function ensures the isolated theme works with ArenaCore features
    local AC = _G.ArenaCore
    if not AC then return end
    
    -- Ensure frame is registered with ArenaCore's MasterFrameManager
    if AC.MasterFrameManager and AC.MasterFrameManager.frames then
        local frameIndex = frame:GetID()
        if frameIndex and frameIndex >= 1 and frameIndex <= 3 then
            -- Frame is already managed, just ensure compatibility
            frame._arenaCore_integrated = true
        end
    end
end

-- ============================================================================
-- REGISTER LAYOUT
-- ============================================================================

if _G.sArenaMixin then
    _G.sArenaMixin.layouts[layoutName] = layout
    _G.sArenaMixin.defaultSettings.profile.layoutSettings[layoutName] = layout.defaultSettings
    
    -- Success message (only show once)
    if not _G.ArenaCore_DefaultTheme_Loaded then
        _G.ArenaCore_DefaultTheme_Loaded = true
        print("|cff8B45FFArenaCore:|r Default theme module loaded successfully!")
    end
end

-- ============================================================================
-- MIGRATION SUPPORT
-- ============================================================================

-- This function will be called by the migration system to transfer old settings
function layout:MigrateFromLegacySettings(oldSettings)
    if not oldSettings then return end
    
    local db = self.db
    if not db then return end
    
    -- Migrate positioning
    if oldSettings.positioning then
        db.posX = oldSettings.positioning.horizontal or db.posX
        db.posY = oldSettings.positioning.vertical or db.posY
        db.spacing = oldSettings.positioning.spacing or db.spacing
        db.growthDirection = oldSettings.positioning.growthDirection or db.growthDirection
    end
    
    -- Migrate sizing
    if oldSettings.sizing then
        db.width = oldSettings.sizing.width or db.width
        db.height = oldSettings.sizing.height or db.height
        db.scale = (oldSettings.sizing.scale or 100) / 100 -- Convert from percentage
    end
    
    -- Migrate general settings
    if oldSettings.general then
        db.showArenaNumbers = oldSettings.general.showArenaNumbers
        db.useClassColors = oldSettings.general.useClassColors
        db.showStatusText = oldSettings.general.showStatusText
        db.usePercentage = oldSettings.general.usePercentage
        db.playerNameX = oldSettings.general.playerNameX or db.playerNameX
        db.playerNameY = oldSettings.general.playerNameY or db.playerNameY
        db.playerNameScale = oldSettings.general.playerNameScale or db.playerNameScale
        db.arenaNumberX = oldSettings.general.arenaNumberX or db.arenaNumberX
        db.arenaNumberY = oldSettings.general.arenaNumberY or db.arenaNumberY
        db.arenaNumberScale = oldSettings.general.arenaNumberScale or db.arenaNumberScale
    end
    
    print("|cff8B45FFArenaCore:|r Legacy settings migrated to isolated theme!")
end

return layout
