-- ============================================================================
-- BLACKOUT CUSTOMIZATION MODULE
-- ============================================================================
-- Handles texture overlays and color customization for blackout effects
-- Separate from core BlackoutEngine to keep that system stable
-- ============================================================================

local function GetAC()
    return _G.ArenaCore
end

local function Clamp01(value)
    if value < 0 then
        return 0
    elseif value > 1 then
        return 1
    end
    return value
end

local function UpdateOverlayFromHealthBar(healthBar, overlay, value)
    if not healthBar or not overlay then return end

    local minVal, maxVal = healthBar:GetMinMaxValues()
    if not minVal or not maxVal or maxVal == minVal then
        overlay:SetValue(0)
        return
    end

    local currentValue = value
    if currentValue == nil then
        currentValue = healthBar:GetValue()
    end

    local normalized = (currentValue - minVal) / (maxVal - minVal)
    overlay:SetValue(Clamp01(normalized))

    if overlay.ACAtlasCrop then
        local tex = overlay:GetStatusBarTexture()
        if tex then
            tex:SetTexCoord(overlay.ACAtlasCrop.left, overlay.ACAtlasCrop.right, overlay.ACAtlasCrop.top, overlay.ACAtlasCrop.bottom)
        end
    end
end

local function UpdateSkillbarOverlay(healthBar, overlay, value)
    if not healthBar or not overlay then return end

    local minVal, maxVal = healthBar:GetMinMaxValues()
    if not minVal or not maxVal or maxVal == minVal then
        overlay:Hide()
        return
    end

    local currentValue = value
    if currentValue == nil then
        currentValue = healthBar:GetValue()
    end

    local normalized = Clamp01((currentValue - minVal) / (maxVal - minVal))
    overlay.ACNormalized = normalized

    if normalized <= 0 then
        overlay:Hide()
        return
    end

    local orientation = (healthBar.GetOrientation and healthBar:GetOrientation()) or overlay.ACOrientation or "HORIZONTAL"
    overlay.ACOrientation = orientation

    local reverse = overlay.ACReverse
    if reverse == nil and healthBar.GetReverseFill then
        reverse = healthBar:GetReverseFill()
    end
    overlay.ACReverse = reverse

    local atlas = overlay.ACAtlas
    if atlas then
        local left = atlas.left
        local top = atlas.top
        local bottom = atlas.bottom
        local width = atlas.width or (atlas.right - atlas.left)
        local right = left + width * normalized
        overlay:SetTexCoord(left, right, top, bottom)
    end

    overlay:Show()

    if orientation == "VERTICAL" then
        local height = healthBar:GetHeight() * normalized
        overlay:ClearAllPoints()
        overlay:SetPoint("LEFT", healthBar, "LEFT")
        overlay:SetPoint("RIGHT", healthBar, "RIGHT")
        if reverse then
            overlay:SetPoint("TOP", healthBar, "TOP")
        else
            overlay:SetPoint("BOTTOM", healthBar, "BOTTOM")
        end
        overlay:SetHeight(math.max(height, 0.0001))
    else
        local width = healthBar:GetWidth() * normalized
        overlay:ClearAllPoints()
        overlay:SetPoint("TOP", healthBar, "TOP")
        overlay:SetPoint("BOTTOM", healthBar, "BOTTOM")
        if reverse then
            overlay:SetPoint("RIGHT", healthBar, "RIGHT")
        else
            overlay:SetPoint("LEFT", healthBar, "LEFT")
        end
        overlay:SetWidth(math.max(width, 0.0001))
    end
end

local function EnsureOverlayHooks(healthBar)
    if not healthBar or healthBar.ACBlackoutHooked then return end

    healthBar:HookScript("OnValueChanged", function(bar, value)
        local overlay = bar.ACBlackoutOverlay
        local updater = bar.ACBlackoutOverlayUpdater
        if overlay and overlay:IsShown() and updater then
            updater(bar, overlay, value)
        end
    end)

    healthBar:HookScript("OnMinMaxChanged", function(bar)
        local overlay = bar.ACBlackoutOverlay
        local updater = bar.ACBlackoutOverlayUpdater
        if overlay and overlay:IsShown() and updater then
            if bar.ACBlackoutOverlayIsStatusBar and overlay.SetMinMaxValues then
                overlay:SetMinMaxValues(0, 1)
            end
            updater(bar, overlay)
        end
    end)

    healthBar:HookScript("OnSizeChanged", function(bar)
        local overlay = bar.ACBlackoutOverlay
        local updater = bar.ACBlackoutOverlayUpdater
        if overlay and overlay:IsShown() and updater then
            updater(bar, overlay)
        end
    end)

    healthBar.ACBlackoutHooked = true
end

local BlackoutCustomization = {}

-- ============================================================================
-- TEXTURE OVERLAY SYSTEM
-- ============================================================================

--- Apply external indicator (positioned above health bar)
--- @param frame table The nameplate frame
--- @param healthBar table The health bar frame
--- @param forceShow boolean Optional - force show even without blackout (for test mode)
function BlackoutCustomization:ApplyExternalIndicator(frame, healthBar, forceShow)
    local AC = GetAC()
    if not AC then return end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    
    -- CRITICAL: ALWAYS block friendly units, even with forceShow (except in test mode)
    -- This prevents external indicator from appearing on friendly healer nameplates
    if not db.externalTestMode and not db.healthBarTestMode then
        if frame.unit and UnitIsFriend("player", frame.unit) then
            -- Hide external indicator if it exists on friendly unit
            if frame.ArenaCore and frame.ArenaCore.blackoutExternalIndicator then
                frame.ArenaCore.blackoutExternalIndicator:Hide()
            end
            return false  -- NEVER apply to friendly units
        end
    end
    
    -- CRITICAL FIX: When NOT in test mode, validate unit is a real enemy player
    -- This prevents external indicators from appearing on totems, pets, NPCs
    -- BBP PATTERN: Check GUID first, then UnitIsPlayer (most reliable order)
    if not forceShow and frame.unit then
        -- STEP 1: GUID validation FIRST (most reliable - BBP pattern)
        local unitGUID = UnitGUID(frame.unit)
        if not unitGUID or not unitGUID:match("^Player%-") then return false end
        
        -- STEP 2: Additional validation checks
        if not UnitIsPlayer(frame.unit) then return false end
        if not UnitIsEnemy("player", frame.unit) then return false end
        if UnitIsUnit(frame.unit, "player") then return false end
        if UnitIsOtherPlayersPet(frame.unit) then return false end
    end
    
    -- Check if we should show external indicator
    -- Show if: (test mode is ON and external texture selected) OR (texture is selected and not empty)
    local shouldShow = false
    local hasValidTexture = db and db.texturePath and db.texturePath ~= ""
    
    if forceShow then
        -- Force show for test mode (ignore other conditions)
        shouldShow = hasValidTexture and db.textureIsExternal
    elseif db and db.externalTestMode and db.textureIsExternal and hasValidTexture then
        -- Test mode: show on all nameplates if external indicator is selected
        shouldShow = true
    elseif db and db.useTexture and hasValidTexture then
        -- Normal mode: only show if texture is selected
        shouldShow = true
    end
    
    if not shouldShow then
        -- Hide external indicator if it exists
        if frame.ArenaCore and frame.ArenaCore.blackoutExternalIndicator then
            frame.ArenaCore.blackoutExternalIndicator:Hide()
        end
        return false
    end
    
    -- Create external indicator frame if it doesn't exist
    if not frame.ArenaCore.blackoutExternalIndicator then
        frame.ArenaCore.blackoutExternalIndicator = CreateFrame("Frame", nil, healthBar)
        frame.ArenaCore.blackoutExternalIndicator:SetFrameStrata("HIGH")
        
        -- Create texture
        frame.ArenaCore.blackoutExternalIndicator.texture = frame.ArenaCore.blackoutExternalIndicator:CreateTexture(nil, "OVERLAY")
        frame.ArenaCore.blackoutExternalIndicator.texture:SetAllPoints()
    end
    
    local indicator = frame.ArenaCore.blackoutExternalIndicator
    local texture = indicator.texture
    
    -- Position ABOVE health bar (larger size for better visibility)
    local baseSize = 64  -- Base size (100%)
    local scalePercent = AC.DB.profile.blackout.externalScale or 100  -- Scale percentage (50-200%)
    local size = math.floor(baseSize * (scalePercent / 100))  -- Apply scale
    indicator:SetSize(size, size)
    
    -- Position above health bar with user offsets
    local offsetX = AC.DB.profile.blackout.externalOffsetX or 0  -- Horizontal offset (-100 to 100)
    local offsetY = AC.DB.profile.blackout.externalOffsetY or 5  -- Vertical offset (-100 to 100)
    indicator:SetPoint("CENTER", healthBar, "TOP", offsetX, offsetY)
    
    -- Apply texture using WeakAuras pattern (auto-detect atlas vs file ID)
    local isAtlas = type(db.texturePath) == "string" and C_Texture.GetAtlasInfo(db.texturePath) ~= nil
    if isAtlas then
        texture:SetAtlas(db.texturePath)  -- Let WoW handle sizing
    else
        -- File ID - convert string to number if needed
        local fileID = tonumber(db.texturePath) or db.texturePath
        texture:SetTexture(fileID)
    end
    
    -- Reset tex coords for non-flipbook textures
    texture:SetTexCoord(0, 1, 0, 1)
    
    -- Full opacity as requested
    texture:SetAlpha(1.0)
    texture:Show()
    
    -- Ensure indicator is shown
    indicator:Show()
    
    return true
end

--- Apply texture overlay to a frame's health bar
--- @param frame table The nameplate frame
--- @param healthBar table The health bar frame
--- @param forceShow boolean Optional - force show texture (used by test mode)
function BlackoutCustomization:ApplyTextureOverlay(frame, healthBar, forceShow)
    local AC = GetAC()
    if not AC then return end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    
    -- CRITICAL: ALWAYS block friendly units, even with forceShow (except in test mode)
    -- This prevents edge case where textures appear on friendly healer nameplates
    if not db.healthBarTestMode and not db.externalTestMode then
        if frame.unit and UnitIsFriend("player", frame.unit) then
            return false  -- NEVER apply to friendly units
        end
    end
    
    -- CRITICAL FIX: Validate unit is a real enemy player (not totem, pet, NPC)
    -- This prevents textures from being applied to shaman totems, hunter pets, etc.
    -- BBP PATTERN: Check GUID first, then UnitIsPlayer (most reliable order)
    if not db.healthBarTestMode then  -- Skip validation in test mode
        -- CRITICAL: Must have valid unit - if nil, reject immediately
        if not frame.unit then return false end
        
        -- STEP 1: GUID validation FIRST (most reliable - BBP pattern)
        -- Player GUIDs: "Player-[server]-[ID]"
        -- Pet GUIDs: "Pet-0-[ID]" or "Creature-0-[ID]" ← MUST REJECT
        -- Totem GUIDs: "Creature-0-[ID]" ← MUST REJECT
        local unitGUID = UnitGUID(frame.unit)
        if not unitGUID or not unitGUID:match("^Player%-") then return false end
        
        -- STEP 2: Additional validation checks
        if not UnitIsPlayer(frame.unit) then return false end
        if not UnitIsEnemy("player", frame.unit) then return false end
        if UnitIsUnit(frame.unit, "player") then return false end
        if UnitIsOtherPlayersPet(frame.unit) then return false end
    end
    
    if not db or not db.useTexture or not db.texturePath or db.texturePath == "" then
        -- Hide texture if it exists
        if frame.ArenaCore and frame.ArenaCore.blackoutTexture then
            frame.ArenaCore.blackoutTexture:Hide()
        end
        if frame.ArenaCore and frame.ArenaCore.blackoutBackground then
            frame.ArenaCore.blackoutBackground:Hide()
        end
        if frame.ArenaCore and frame.ArenaCore.blackoutBackgroundExtra then
            frame.ArenaCore.blackoutBackgroundExtra:Hide()
        end
        if frame.ArenaCore and frame.ArenaCore.blackoutExternalIndicator then
            frame.ArenaCore.blackoutExternalIndicator:Hide()
        end
        if frame.ArenaCore and frame.ArenaCore.blackoutOverlayBar then
            frame.ArenaCore.blackoutOverlayBar:Hide()
        end
        return false
    end
    
    -- Check if this is an external indicator texture
    if db.textureIsExternal then
        return self:ApplyExternalIndicator(frame, healthBar)
    end
    
    -- Hide legacy blackout backgrounds so default Blizzard backing remains visible
    if frame.ArenaCore.blackoutBackground then
        frame.ArenaCore.blackoutBackground:Hide()
    end
    if frame.ArenaCore.blackoutBackgroundExtra then
        frame.ArenaCore.blackoutBackgroundExtra:Hide()
    end

    -- Determine grid structure based on texture type
    local rows, columns
    local isSkillbar = false
    
    if db.texturePath:find("Quality%-BarFill%-Flipbook") then
        -- Quality-BarFill-Flipbook textures are 15 rows x 4 columns (60 frames)
        rows, columns = 15, 4
    elseif db.texturePath:find("Priest_Void") then
        -- Void Priest texture uses 8 rows x 8 columns (64 frames)
        rows, columns = 8, 8
    elseif db.texturePath:find("DastardlyDuos%-ProgressBar%-Fill") then
        -- Dastardly Duos progress bar (simple horizontal bar, no animation)
        rows, columns = 1, 1
    elseif db.texturePath:find("Skillbar_Fill_Flipbook") then
        -- Skillbar profession textures use 30 rows x 2 columns (WeakAuras metadata)
        rows, columns = 30, 2
        isSkillbar = true
    else
        -- Default fallback for unknown textures
        rows, columns = 8, 8
    end
    
    if isSkillbar then
        -- Hide status bar overlay if it exists
        if frame.ArenaCore.blackoutOverlayBar then
            frame.ArenaCore.blackoutOverlayBar:Hide()
        end

        -- Create skillbar texture overlay (manual fill)
        if not frame.ArenaCore.blackoutSkillbarOverlay then
            local tex = healthBar:CreateTexture(nil, "OVERLAY")
            tex:SetBlendMode("BLEND")
            frame.ArenaCore.blackoutSkillbarOverlay = tex
        end

        local overlay = frame.ArenaCore.blackoutSkillbarOverlay
        overlay:SetBlendMode("BLEND")
        if overlay.SetHorizTile then overlay:SetHorizTile(false) end
        if overlay.SetVertTile then overlay:SetVertTile(false) end
        overlay:SetAlpha(1.0)
        overlay:Show()

        -- CRITICAL FIX: For Skillbar atlases, we MUST use SetAtlas but force TexCoords immediately
        -- The trick: SetAtlas loads the texture, then we override coords before any rendering
        if db.textureIsAtlas then
            -- Load atlas texture (this is required for atlas names to resolve)
            overlay:SetAtlas(db.texturePath, false)  -- false = don't use atlas size

            -- Calculate TexCoords for Skillbar flipbook (30 rows x 2 columns)
            -- Use final frame (frame 60) for clean single bar
            local frameNum = 60  -- Last frame of 60-frame flipbook
            local row = math.floor((frameNum - 1) / columns)  -- row 29
            local column = (frameNum - 1) % columns  -- column 1
            
            -- Calculate frame position in normalized 0-1 space
            local deltaX = 1.0 / columns  -- 0.5 per column
            local deltaY = 1.0 / rows     -- 0.0333... per row
            local left = deltaX * column
            local right = left + deltaX
            local top = deltaY * row
            local bottom = top + deltaY

            -- IMMEDIATELY override TexCoords to prevent tiling
            overlay:SetTexCoord(left, right, top, bottom)
            
            overlay.ACAtlas = overlay.ACAtlas or {}
            overlay.ACAtlas.left = left
            overlay.ACAtlas.right = right
            overlay.ACAtlas.top = top
            overlay.ACAtlas.bottom = bottom
            overlay.ACAtlas.width = right - left
            overlay.ACAtlas.height = bottom - top
            overlay.ACAtlas.baseRight = right
            overlay.ACAtlas.baseBottom = bottom

            local AC = GetAC()
            if AC and AC.BLACKOUT_DEBUG then
                print(string.format("|cffB266FFArenaCore:|r Skillbar %s frame %d/%d - coords: %.4f %.4f %.4f %.4f",
                    tostring(db.texturePath), frameNum, rows * columns, left, right, top, bottom))
            end
        else
            overlay:SetTexture(db.texturePath)
            overlay.ACAtlas = nil
        end

        overlay.ACOrientation = (healthBar.GetOrientation and healthBar:GetOrientation()) or "HORIZONTAL"
        if overlay.ACReverse == nil and healthBar.GetReverseFill then
            overlay.ACReverse = healthBar:GetReverseFill()
        end

        healthBar.ACBlackoutOverlay = overlay
        healthBar.ACBlackoutOverlayUpdater = UpdateSkillbarOverlay
        healthBar.ACBlackoutOverlayIsStatusBar = false

        frame.ArenaCore.blackoutTexture = overlay

        EnsureOverlayHooks(healthBar)
        UpdateSkillbarOverlay(healthBar, overlay)

        return true
    end

    -- Ensure skillbar overlay hidden when using other textures
    if frame.ArenaCore.blackoutSkillbarOverlay then
        frame.ArenaCore.blackoutSkillbarOverlay:Hide()
    end

    -- CRITICAL FIX: Use plain Texture overlay instead of StatusBar
    -- StatusBar automatically tiles/repeats textures, causing stacked bars
    -- Plain Texture gives us full control over coordinates without tiling
    if not frame.ArenaCore.blackoutTextureOverlay then
        local tex = healthBar:CreateTexture(nil, "OVERLAY")
        tex:SetBlendMode("BLEND")
        frame.ArenaCore.blackoutTextureOverlay = tex
    end

    local overlay = frame.ArenaCore.blackoutTextureOverlay
    overlay:SetBlendMode("BLEND")
    if overlay.SetHorizTile then overlay:SetHorizTile(false) end
    if overlay.SetVertTile then overlay:SetVertTile(false) end
    overlay:SetAlpha(1.0)
    overlay:Show()

    if db.textureIsAtlas then
        overlay:SetAtlas(db.texturePath, false)

        local atlasInfo = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(db.texturePath)
        local baseLeft = (atlasInfo and atlasInfo.leftTexCoord) or 0
        local baseRight = (atlasInfo and atlasInfo.rightTexCoord) or 1
        local baseTop = (atlasInfo and atlasInfo.topTexCoord) or 0
        local baseBottom = (atlasInfo and atlasInfo.bottomTexCoord) or 1

        -- Use final frame of flipbook to get clean single bar
        local frameNum = rows * columns
        if rows == 1 and columns > 1 then
            frameNum = columns
        end
        local row = math.floor((frameNum - 1) / columns)
        local column = (frameNum - 1) % columns
        local deltaX = (baseRight - baseLeft) / columns
        local deltaY = (baseBottom - baseTop) / rows
        local left = baseLeft + deltaX * column
        local right = left + deltaX
        local top = baseTop + deltaY * row
        local bottom = top + deltaY

        overlay:SetTexCoord(left, right, top, bottom)
        overlay.ACAtlas = overlay.ACAtlas or {}
        overlay.ACAtlas.left = left
        overlay.ACAtlas.right = right
        overlay.ACAtlas.top = top
        overlay.ACAtlas.bottom = bottom
        overlay.ACAtlas.width = right - left
        overlay.ACAtlas.height = bottom - top
        overlay.ACAtlas.baseRight = right
        overlay.ACAtlas.baseBottom = bottom

        local AC = GetAC()
        if AC and AC.BLACKOUT_DEBUG then
            print(string.format("|cffB266FFArenaCore:|r Atlas %s using frame %d/%d - coords: %.4f %.4f %.4f %.4f",
                tostring(db.texturePath), frameNum, rows * columns, left, right, top, bottom))
        end
    else
        overlay:SetTexture(db.texturePath)
        overlay.ACAtlas = nil
    end

    overlay.ACOrientation = (healthBar.GetOrientation and healthBar:GetOrientation()) or "HORIZONTAL"
    if overlay.ACReverse == nil and healthBar.GetReverseFill then
        overlay.ACReverse = healthBar:GetReverseFill()
    end

    healthBar.ACBlackoutOverlay = overlay
    healthBar.ACBlackoutOverlayUpdater = UpdateSkillbarOverlay  -- Use same updater as skillbar
    healthBar.ACBlackoutOverlayIsStatusBar = false

    frame.ArenaCore.blackoutTexture = overlay

    EnsureOverlayHooks(healthBar)
    UpdateSkillbarOverlay(healthBar, overlay)

    return true  -- Texture was applied
end

-- ============================================================================
-- COLOR CUSTOMIZATION SYSTEM
-- ============================================================================

--- Get the customized blackout color based on effect type
--- @param effectType string The effect type (default, fire, ice, poison, shadow, custom)
--- @param customColor table Optional custom RGB color
--- @return table RGB color table {r, g, b}
function BlackoutCustomization:GetBlackoutColor(effectType, customColor)
    local color = {r = 0, g = 0, b = 0}  -- Default black
    
    if effectType == "fire" then
        color = {r = 1, g = 0.3, b = 0}
    elseif effectType == "ice" then
        color = {r = 0, g = 0.5, b = 1}
    elseif effectType == "poison" then
        color = {r = 0, g = 0.8, b = 0}
    elseif effectType == "shadow" then
        color = {r = 0.5, g = 0, b = 0.8}
    elseif effectType == "custom" and customColor then
        color = {r = customColor.r, g = customColor.g, b = customColor.b}
    end
    
    return color
end

--- Apply customized color to health bar
--- @param healthBar table The health bar frame
--- @param blackoutColor table The RGB color to apply
function BlackoutCustomization:ApplyColorOverride(healthBar, blackoutColor)
    if not healthBar or not blackoutColor then return end
    
    -- CRITICAL: Always apply the color (don't check if it changed)
    -- This ensures we override Blizzard colors that were just applied
    healthBar:SetStatusBarColor(blackoutColor.r, blackoutColor.g, blackoutColor.b)
    
    local AC = GetAC()
    if AC and AC.BLACKOUT_DEBUG then
        print(string.format("|cffB266FFArenaCore:|r Applied custom color (%.2f, %.2f, %.2f)", 
            blackoutColor.r, blackoutColor.g, blackoutColor.b))
    end
    
    return true
end

-- ============================================================================
-- MAIN CUSTOMIZATION HANDLER
-- ============================================================================

--- Apply blackout customization (texture OR color)
--- @param frame table The nameplate frame
--- @param config table The frame's ArenaCore config
function BlackoutCustomization:ApplyCustomization(frame, config)
    if not frame or not frame.healthBar or not config then return end
    if not config.blackoutColor then return end  -- No blackout active
    
    local AC = GetAC()
    if not AC then return end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    if not db then return end
    
    -- CRITICAL FIX: Validate unit is a real enemy player (not totem, pet, NPC)
    -- This prevents blackout from being applied to shaman totems, hunter pets, etc.
    -- BBP PATTERN: Check GUID first, then UnitIsPlayer (most reliable order)
    -- CRITICAL: Must have valid unit - if nil, reject immediately
    if not frame.unit then return end
    
    -- STEP 1: GUID validation FIRST (most reliable - BBP pattern)
    -- Player GUIDs: "Player-[server]-[ID]"
    -- Pet GUIDs: "Pet-0-[ID]" or "Creature-0-[ID]" ← MUST REJECT
    -- Totem GUIDs: "Creature-0-[ID]" ← MUST REJECT
    local unitGUID = UnitGUID(frame.unit)
    if not unitGUID or not unitGUID:match("^Player%-") then return end
    
    -- STEP 2: Additional validation checks
    if not UnitIsPlayer(frame.unit) then return end
    if not UnitIsEnemy("player", frame.unit) then return end
    if UnitIsUnit(frame.unit, "player") then return end
    if UnitIsOtherPlayersPet(frame.unit) then return end
    
    -- ========================================================================
    -- CRITICAL FIX: Check for textureMode marker first
    -- ========================================================================
    -- When textureMode is true, we ONLY apply texture overlay, never color
    if config.blackoutColor.textureMode then
        if AC.BLACKOUT_DEBUG then
            print("|cffB266FFArenaCore:|r TEXTURE MODE DETECTED - Applying texture only")
        end
        
        -- Only apply texture if texture settings are valid
        if db.useTexture and db.texturePath and db.texturePath ~= "" then
            self:ApplyTextureOverlay(frame, frame.healthBar)
        else
            -- Fallback: Clear everything if texture settings are invalid
            self:ClearCustomization(frame)
        end
        return
    end
    
    -- ========================================================================
    -- LEGACY MODE: Color-based blackout (when textureMode is false)
    -- ========================================================================
    
    -- CRITICAL SAFEGUARD: If texture mode is enabled in DB, NEVER apply color
    -- This catches cases where textureMode marker might be missing from config
    if db.useTexture then
        if AC.BLACKOUT_DEBUG then
            print("|cffB266FFArenaCore:|r SAFEGUARD: Texture mode enabled in DB - applying texture only, NO COLOR")
        end
        
        if db.texturePath and db.texturePath ~= "" then
            self:ApplyTextureOverlay(frame, frame.healthBar)
        else
            -- No valid texture path - clear everything
            self:ClearCustomization(frame)
        end
        return  -- CRITICAL: Exit here, never apply color when texture mode is on
    end
    
    -- If we reach here, texture mode is OFF - apply color customization
    if db.useTexture and db.texturePath and db.texturePath ~= "" then
        -- This should never happen (caught by safeguard above)
        if AC.BLACKOUT_DEBUG then
            print("|cffFF0000[BlackoutCustomization]|r ERROR: Reached unreachable code! Texture mode check failed!")
        end
        self:ApplyTextureOverlay(frame, frame.healthBar)
    else
        -- COLOR MODE: Apply color customization
        local effectType = db.effectType or "default"
        
        -- CRITICAL FIX: Don't apply "default" (black) effect when texture is selected
        -- This prevents random black health bars when texture overlay should be used instead
        if effectType == "default" and db.useTexture then
            if AC.BLACKOUT_DEBUG then
                print("|cffB266FFArenaCore:|r Skipping default black color (texture mode active)")
            end
            return
        end
        
        local customizedColor = self:GetBlackoutColor(effectType, db.customColor)
        
        if AC.BLACKOUT_DEBUG then
            print(string.format("|cffB266FFArenaCore:|r COLOR MODE - Effect: %s, Color: (%.2f, %.2f, %.2f)", 
                effectType, customizedColor.r, customizedColor.g, customizedColor.b))
        end
        
        -- Update config with customized color
        config.blackoutColor = customizedColor
        
        -- CRITICAL FIX: Apply blackout color directly to health bar (no overlay)
        -- This allows the health bar to show real-time health changes with blackout color
        self:ApplyColorOverride(frame.healthBar, customizedColor)
        
        -- Hide any existing color overlay (legacy cleanup)
        if frame.ArenaCore.blackoutColorOverlay then
            frame.ArenaCore.blackoutColorOverlay:Hide()
        end
        
        -- Hide texture if it exists
        if frame.ArenaCore and frame.ArenaCore.blackoutTexture then
            frame.ArenaCore.blackoutTexture:Hide()
        end
        if frame.ArenaCore and frame.ArenaCore.blackoutBackground then
            frame.ArenaCore.blackoutBackground:Hide()
        end
        if frame.ArenaCore and frame.ArenaCore.blackoutBackgroundExtra then
            frame.ArenaCore.blackoutBackgroundExtra:Hide()
        end
    end
end

--- Refresh all active nameplate blackouts (called when settings change)
--- NOTE: This is a placeholder function for future use. The blackout system
--- already works correctly - changes take effect on next blackout trigger.
function BlackoutCustomization:RefreshAllNameplates()
    -- Placeholder - blackout system already handles updates correctly
    -- This function exists for potential future enhancements
end

--- Refresh all nameplates for test mode (both external indicators AND health bar textures)
-- Storage for independent external indicator frames (Platynator compatibility)
local externalIndicatorFrames = {}

--- Shows textures on ALL nameplates when test mode is active
function BlackoutCustomization:RefreshAllNameplatesForTest()
    local AC = GetAC()
    if not AC then return end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    if not db then return end
    
    -- NOTE: Blackout external indicators only work with Blizzard nameplates
    -- Custom nameplate addons (Plater, Platynator) are not supported due to
    -- forbidden frame restrictions and lack of compatible APIs
    local nameplates = C_NamePlate.GetNamePlates()
    
    for _, nameplate in pairs(nameplates) do
        if nameplate then
            local unit = nameplate.namePlateUnitToken
            
            if not unit then
                local frame = nameplate.UnitFrame
                if frame and not frame:IsForbidden() then
                    unit = frame.unit or frame.displayedUnit
                end
            end
            
            if unit then
                if db.externalTestMode and db.textureIsExternal then
                    local indicator = externalIndicatorFrames[unit]
                    if not indicator then
                        indicator = CreateFrame("Frame", "ArenaCore_ExternalIndicator_" .. unit, nameplate)
                        indicator:SetSize(256, 64)
                        indicator:SetFrameStrata("HIGH")
                        indicator:SetFrameLevel(999)
                        indicator:SetPoint("CENTER", nameplate, "CENTER", 0, 0)
                        
                        externalIndicatorFrames[unit] = indicator
                        
                        indicator.texture = indicator:CreateTexture(nil, "OVERLAY")
                        indicator.texture:SetAllPoints()
                    end
                    
                    local texturePath = db.selectedTexture or "Interface\\AddOns\\ArenaCore\\Media\\Blackout\\CRProtectionPlan.tga"
                    indicator.texture:SetTexture(texturePath)
                    indicator:Show()
                else
                    local indicator = externalIndicatorFrames[unit]
                    if indicator then
                        indicator:Hide()
                    end
                end
                
                -- NOTE: Health bar texture test mode (color changes) cannot work with
                -- custom nameplate addons like Platynator because they use forbidden frames.
                -- Only external indicators (overlays) are supported with custom addons.
            end
        end
    end
end

--- Clear all customization from a frame
--- @param frame table The nameplate frame
function BlackoutCustomization:ClearCustomization(frame)
    if not frame or not frame.ArenaCore then return end
    
    -- Hide texture overlay
    if frame.ArenaCore.blackoutTexture then
        frame.ArenaCore.blackoutTexture:Hide()
    end

    -- Hide texture overlay
    if frame.ArenaCore.blackoutTextureOverlay then
        frame.ArenaCore.blackoutTextureOverlay:Hide()
    end
    
    -- Hide black backgrounds (both layers)
    if frame.ArenaCore.blackoutBackground then
        frame.ArenaCore.blackoutBackground:Hide()
    end
    
    if frame.ArenaCore.blackoutBackgroundExtra then
        frame.ArenaCore.blackoutBackgroundExtra:Hide()
    end
    
    -- Hide color overlay
    if frame.ArenaCore.blackoutColorOverlay then
        frame.ArenaCore.blackoutColorOverlay:Hide()
    end
    
    -- Hide external indicator
    if frame.ArenaCore.blackoutExternalIndicator then
        frame.ArenaCore.blackoutExternalIndicator:Hide()
    end
end

-- ============================================================================
-- EXPORT
-- ============================================================================

local AC = GetAC()
if AC then
    AC.BlackoutCustomization = BlackoutCustomization
end

-- Module loaded (debug removed for clean user experience)
-- print("|cffB266FFArenaCore:|r BlackoutCustomization module loaded")
