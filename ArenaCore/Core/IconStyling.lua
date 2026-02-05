-- =============================================================
-- File: Core/IconStyling.lua
-- ArenaCore Global Icon Styling System
-- Implements classic WoW rounded icon design with dark borders
-- =============================================================

local AC = _G.ArenaCore
if not AC then return end

AC.IconStyling = AC.IconStyling or {}
local IconStyling = AC.IconStyling

-- Classic WoW icon textures from Blizzard Classic theme
local CLASSIC_TEXTURES = {
    backdrop = "Interface\\Buttons\\UI-Quickslot",
    normal = "Interface\\Buttons\\UI-Quickslot2", 
    border = "Interface\\Buttons\\UI-ActionButton-Border",
    highlight = "Interface\\Buttons\\CheckButtonHilight"
}

-- Icon styling configuration
local ICON_CONFIG = {
    iconTexCoords = {0, 1, 0, 1}, -- Full icon texture - no cropping
    normalTexCoords = {0, 1, 0, 1}, -- Normal frame texCoords
    backdropColor = {1, 1, 1, 0.4},
    borderColor = {0, 0, 0, 0.8}, -- Black border for rounded corners
    normalColor = {1, 1, 1, 1},
    highlightBlend = "ADD"
}

--[[
    Creates a classic WoW styled icon frame with rounded edges and dark border
    
    @param parent - Parent frame to attach the icon to
    @param size - Icon size (default: 36)
    @param showBorder - Whether to show the dark border (default: true)
    @return iconFrame - Styled icon frame with .icon, .border properties
]]
function IconStyling:CreateStyledIcon(parent, size, showBorder)
    if not parent then return nil end
    
    size = size or 36
    showBorder = showBorder ~= false -- Default to true
    
    -- Create main icon frame with backdrop template
    local iconFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    iconFrame:SetSize(size, size)
    
    -- Create the actual icon texture (full brightness, no modifications)
    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(iconFrame) -- Full size, no shrinking
    icon:SetTexCoord(0, 1, 0, 1) -- Full texture, no cropping
    
    -- CRITICAL: Override SetTexture to apply TRILINEAR filtering for smooth scaling
    -- This prevents pixelation when icons are scaled up beyond base size
    icon.SetTexture = function(self, texture, ...)
        getmetatable(self).__index.SetTexture(self, texture, true, true)
    end
    
    -- Create simple thick black border using textures
    local border = nil
    if showBorder ~= false then
        -- Get border thickness percentage from THEME-SPECIFIC settings (80-100%, default 100%)
        local AC = _G.ArenaCore
        local thicknessPercent = 100 -- Default to 100%
        
        -- CRITICAL: Read from theme-specific settings for per-theme isolation
        if AC and AC.DB and AC.DB.profile then
            local currentTheme = AC.ArenaFrameThemes and AC.ArenaFrameThemes:GetCurrentTheme()
            local themeData = currentTheme and AC.DB.profile.themeData and AC.DB.profile.themeData[currentTheme]
            
            -- Try theme-specific settings first
            if themeData and themeData.classIcons and themeData.classIcons.sizing and themeData.classIcons.sizing.borderThickness then
                thicknessPercent = themeData.classIcons.sizing.borderThickness
            -- Fallback to global settings if theme-specific don't exist
            elseif AC.DB.profile.classIcons and AC.DB.profile.classIcons.sizing and AC.DB.profile.classIcons.sizing.borderThickness then
                thicknessPercent = AC.DB.profile.classIcons.sizing.borderThickness
            end
        end
        
        -- Calculate border thickness as percentage of icon size (12% of smaller dimension)
        local iconWidth = size or 32
        local iconHeight = size or 32
        local minDimension = math.min(iconWidth, iconHeight)
        local baseBorderThickness = math.floor(minDimension * 0.12) -- 12% of size
        
        -- Apply thickness percentage (80-100%)
        local borderThickness = math.max(2, math.floor(baseBorderThickness * (thicknessPercent / 100)))
        
        local borderTop = iconFrame:CreateTexture(nil, "OVERLAY")
        borderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
        borderTop:SetVertexColor(0, 0, 0, 1)
        borderTop:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)
        borderTop:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", 0, 0)
        borderTop:SetHeight(borderThickness)
        
        local borderBottom = iconFrame:CreateTexture(nil, "OVERLAY")
        borderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
        borderBottom:SetVertexColor(0, 0, 0, 1)
        borderBottom:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 0, 0)
        borderBottom:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
        borderBottom:SetHeight(borderThickness)
        
        local borderLeft = iconFrame:CreateTexture(nil, "OVERLAY")
        borderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
        borderLeft:SetVertexColor(0, 0, 0, 1)
        borderLeft:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)
        borderLeft:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 0, 0)
        borderLeft:SetWidth(borderThickness)
        
        local borderRight = iconFrame:CreateTexture(nil, "OVERLAY")
        borderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
        borderRight:SetVertexColor(0, 0, 0, 1)
        borderRight:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", 0, 0)
        borderRight:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
        borderRight:SetWidth(borderThickness)
        
        border = {
            top = borderTop,
            bottom = borderBottom,
            left = borderLeft,
            right = borderRight,
            thickness = borderThickness
        }
    end
    
    -- Store references for easy access
    iconFrame.icon = icon
    iconFrame.border = border
    iconFrame.styledBorder = border  -- For consistency with StyleExistingIcon
    
    -- Helper method to set icon texture
    function iconFrame:SetIconTexture(texture)
        if self.icon and texture then
            self.icon:SetTexture(texture)
        end
    end
    
    -- Helper method to set border color
    function iconFrame:SetBorderColor(r, g, b, a)
        if self.border then
            self.border:SetVertexColor(r, g, b, a or 1)
        end
    end
    
    return iconFrame
end

--[[
    Applies classic styling to an existing icon texture
    
    @param iconTexture - Existing icon texture to style
    @param parentFrame - Parent frame (optional, for adding border)
    @param addBorder - Whether to add dark border (default: true)
]]
function IconStyling:StyleExistingIcon(iconTexture, parentFrame, addBorder)
    if not iconTexture then return end
    
    -- CRITICAL FIX: Don't apply styling to class icons that have preventStyling flag
    if parentFrame and parentFrame.preventStyling then
        return -- Skip styling for class icons
    end
    
    -- DON'T modify the icon texture at all - keep it full brightness and original texCoords
    
    -- Add simple thick black border using 4 textures with DYNAMIC SCALING
    if addBorder ~= false and parentFrame then
        if not parentFrame.styledBorder then
            -- Get border thickness percentage from THEME-SPECIFIC settings (80-100%, default 100%)
            local AC = _G.ArenaCore
            local thicknessPercent = 100 -- Default to 100%
            
            -- CRITICAL: Read from theme-specific settings for per-theme isolation
            if AC and AC.DB and AC.DB.profile then
                local currentTheme = AC.ArenaFrameThemes and AC.ArenaFrameThemes:GetCurrentTheme()
                local themeData = currentTheme and AC.DB.profile.themeData and AC.DB.profile.themeData[currentTheme]
                
                -- Try theme-specific settings first
                if themeData and themeData.classIcons and themeData.classIcons.sizing and themeData.classIcons.sizing.borderThickness then
                    thicknessPercent = themeData.classIcons.sizing.borderThickness
                -- Fallback to global settings if theme-specific don't exist
                elseif AC.DB.profile.classIcons and AC.DB.profile.classIcons.sizing and AC.DB.profile.classIcons.sizing.borderThickness then
                    thicknessPercent = AC.DB.profile.classIcons.sizing.borderThickness
                end
            end
            
            -- Calculate border thickness as percentage of icon size (12% of smaller dimension)
            -- This ensures borders scale proportionally with icon size
            -- CRITICAL FIX: Use icon texture size, not parent frame size
            local iconWidth = iconTexture:GetWidth() or 16
            local iconHeight = iconTexture:GetHeight() or 16
            local minDimension = math.min(iconWidth, iconHeight)
            local baseBorderThickness = math.floor(minDimension * 0.12) -- 12% of size
            
            -- Apply thickness percentage (80-100%)
            local borderThickness = math.max(2, math.floor(baseBorderThickness * (thicknessPercent / 100)))
            
            -- Create 4 border textures for top, bottom, left, right with high sublevel
            -- Use sublevel 7 (max allowed) to ensure borders appear above the icon (sublevel 5)
            -- CRITICAL FIX: Anchor to ICON TEXTURE edges, not parent frame edges
            local borderTop = parentFrame:CreateTexture(nil, "OVERLAY", nil, 7)
            borderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
            borderTop:SetVertexColor(0, 0, 0, 1)
            borderTop:SetPoint("TOPLEFT", iconTexture, "TOPLEFT", 0, 0)
            borderTop:SetPoint("TOPRIGHT", iconTexture, "TOPRIGHT", 0, 0)
            borderTop:SetHeight(borderThickness)
            
            local borderBottom = parentFrame:CreateTexture(nil, "OVERLAY", nil, 7)
            borderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
            borderBottom:SetVertexColor(0, 0, 0, 1)
            borderBottom:SetPoint("BOTTOMLEFT", iconTexture, "BOTTOMLEFT", 0, 0)
            borderBottom:SetPoint("BOTTOMRIGHT", iconTexture, "BOTTOMRIGHT", 0, 0)
            borderBottom:SetHeight(borderThickness)
            
            local borderLeft = parentFrame:CreateTexture(nil, "OVERLAY", nil, 7)
            borderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
            borderLeft:SetVertexColor(0, 0, 0, 1)
            borderLeft:SetPoint("TOPLEFT", iconTexture, "TOPLEFT", 0, 0)
            borderLeft:SetPoint("BOTTOMLEFT", iconTexture, "BOTTOMLEFT", 0, 0)
            borderLeft:SetWidth(borderThickness)
            
            local borderRight = parentFrame:CreateTexture(nil, "OVERLAY", nil, 7)
            borderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
            borderRight:SetVertexColor(0, 0, 0, 1)
            borderRight:SetPoint("TOPRIGHT", iconTexture, "TOPRIGHT", 0, 0)
            borderRight:SetPoint("BOTTOMRIGHT", iconTexture, "BOTTOMRIGHT", 0, 0)
            borderRight:SetWidth(borderThickness)
            
            -- Store border data for potential updates
            parentFrame.styledBorder = {
                top = borderTop,
                bottom = borderBottom,
                left = borderLeft,
                right = borderRight,
                thickness = borderThickness,
                iconTexture = iconTexture
            }
        end
    end
end

--[[
    Update border thickness when icon size changes
    Call this after changing icon size to maintain proportional borders
    
    @param parentFrame - Frame containing the styledBorder
]]
function IconStyling:UpdateBorderThickness(parentFrame)
    if not parentFrame then 
        -- DEBUG DISABLED FOR PRODUCTION
        -- print("[IconStyling] UpdateBorderThickness: parentFrame is nil")
        return 
    end
    
    if not parentFrame.styledBorder then 
        -- DEBUG DISABLED FOR PRODUCTION
        -- print("[IconStyling] UpdateBorderThickness: parentFrame.styledBorder is nil")
        return 
    end
    
    local border = parentFrame.styledBorder
    
    -- Get border thickness percentage from THEME-SPECIFIC settings (80-100%, default 100%)
    local AC = _G.ArenaCore
    local thicknessPercent = 100 -- Default to 100%
    
    -- CRITICAL: Read from theme-specific settings for per-theme isolation
    if AC and AC.DB and AC.DB.profile then
        local currentTheme = AC.ArenaFrameThemes and AC.ArenaFrameThemes:GetCurrentTheme()
        local themeData = currentTheme and AC.DB.profile.themeData and AC.DB.profile.themeData[currentTheme]
        
        -- Try theme-specific settings first
        if themeData and themeData.classIcons and themeData.classIcons.sizing and themeData.classIcons.sizing.borderThickness then
            thicknessPercent = themeData.classIcons.sizing.borderThickness
        -- Fallback to global settings if theme-specific don't exist
        elseif AC.DB.profile.classIcons and AC.DB.profile.classIcons.sizing and AC.DB.profile.classIcons.sizing.borderThickness then
            thicknessPercent = AC.DB.profile.classIcons.sizing.borderThickness
        end
    end
    
    -- Recalculate border thickness based on new parent frame size
    -- CRITICAL: Use parent frame size for consistency
    local iconWidth = parentFrame:GetWidth() or 32
    local iconHeight = parentFrame:GetHeight() or 32
    local minDimension = math.min(iconWidth, iconHeight)
    local baseBorderThickness = math.floor(minDimension * 0.12) -- 12% of size
    
    -- Apply thickness percentage (80-100%)
    local borderThickness = math.max(2, math.floor(baseBorderThickness * (thicknessPercent / 100)))
    
    -- DEBUG DISABLED FOR PRODUCTION
    -- print(string.format("[IconStyling] UpdateBorderThickness: size=%.1fx%.1f, base=%d, percent=%d%%, final=%d", 
    --     iconWidth, iconHeight, baseBorderThickness, thicknessPercent, borderThickness))
    
    -- Update border sizes
    if border.top then border.top:SetHeight(borderThickness) end
    if border.bottom then border.bottom:SetHeight(borderThickness) end
    if border.left then border.left:SetWidth(borderThickness) end
    if border.right then border.right:SetWidth(borderThickness) end
    
    -- Store new thickness
    border.thickness = borderThickness
end

--[[
    Batch applies styling to multiple icons
    
    @param icons - Table of {texture = iconTexture, parent = parentFrame} entries
]]
function IconStyling:StyleMultipleIcons(icons)
    if not icons then return end
    
    for _, iconData in pairs(icons) do
        if iconData.texture then
            self:StyleExistingIcon(iconData.texture, iconData.parent, iconData.addBorder)
        end
    end
end

-- Global helper function for easy access
function AC:CreateStyledIcon(parent, size, showBorder, showBackdrop)
    return IconStyling:CreateStyledIcon(parent, size, showBorder, showBackdrop)
end

function AC:StyleIcon(iconTexture, parentFrame, addBorder)
    return IconStyling:StyleExistingIcon(iconTexture, parentFrame, addBorder)
end
