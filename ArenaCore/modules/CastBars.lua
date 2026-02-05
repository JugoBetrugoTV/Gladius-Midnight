-- ============================================================================
-- File: ArenaCore/modules/CastBars.lua
-- Purpose: Cast bar system for ArenaCore
-- ONE SOURCE OF TRUTH: Works in both test mode and arena
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

-- ============================================================================
-- DETECTION & CONSTANTS
-- ============================================================================

local isMidnight = select(4, GetBuildInfo()) >= 120000
local MAX_ARENA_ENEMIES = 3

-- Test mode cast data
local TEST_CAST_DATA = {
    [1] = { name = "Death Coil", icon = 136145, duration = 2.0, channel = false, uninterruptible = false },
    [2] = { name = "Polymorph", icon = 136071, duration = 1.7, channel = false, uninterruptible = false },
    [3] = { name = "Mass Dispel", icon = 135739, duration = 2.5, channel = false, uninterruptible = true },
}

-- ============================================================================
-- CAST BAR MODULE
-- ============================================================================

local CastBars = {}
AC.CastBars = CastBars

-- Store references to cast bars
CastBars.bars = {}

-- ============================================================================
-- GET SETTINGS FROM DATABASE
-- ============================================================================

local function GetSettings()
    local db = AC.DB and AC.DB.profile and AC.DB.profile.castBars
    -- CRITICAL: Default values MUST match Init.lua DEFAULTS.castBars exactly
    return db or {
        positioning = { horizontal = -4, vertical = -86 },
        sizing = { width = 220, height = 24 },
    }
end

-- ============================================================================
-- INITIALIZE CAST BARS
-- Called after ArenaCore frames are created
-- ============================================================================

function CastBars:Initialize()
    if not isMidnight then
        -- Non-Midnight: Would need custom cast bars (not implemented yet)
        return
    end
    
    -- Wait for Blizzard frames to be available
    C_Timer.After(0.5, function()
        self:SetupCastBars()
    end)
end

-- ============================================================================
-- SETUP CAST BARS (Midnight Mode)
-- Uses Blizzard's CastingBarFrame directly
-- ============================================================================

function CastBars:SetupCastBars()
    if not isMidnight then return end
    
    local MFM = AC.MasterFrameManager
    if not MFM or not MFM.frames then 
        -- DEBUG DISABLED: print("|cffFF0000ArenaCore:|r SetupCastBars - No MFM frames")
        return 
    end
    
    -- DEBUG DISABLED: print("|cff00FF00ArenaCore:|r Setting up cast bars...")
    
    for i = 1, MAX_ARENA_ENEMIES do
        local acFrame = MFM.frames[i]
        local blizzFrame = _G["CompactArenaFrameMember" .. i]
        
        --[[ DEBUG DISABLED: print(string.format("|cff00FF00ArenaCore:|r Frame %d - acFrame: %s, blizzFrame: %s", 
            i, tostring(acFrame), tostring(blizzFrame))) --]]
        
        if acFrame and blizzFrame and blizzFrame.CastingBarFrame then
            -- DEBUG DISABLED: print("|cff00FF00ArenaCore:|r Found cast bar 1: " .. tostring(blizzFrame.CastingBarFrame))
            local castBar = blizzFrame.CastingBarFrame
            -- DEBUG DISABLED: print(string.format("|cff00FF00ArenaCore:|r Found cast bar %d: %s", i, tostring(castBar)))
            
            -- Skip if already set up
            if self.bars[i] == castBar then
                -- DEBUG DISABLED: print("|cffFFFF00ArenaCore:|r Cast bar %d already set up, skipping", i)
                return
            end
            
            -- Store reference
            self.bars[i] = castBar
            acFrame.castBar = castBar
            
            -- CRITICAL: Reparent to ArenaCore frame (not Blizzard frame)
            -- This keeps cast bars visible even when Blizzard frames are hidden
            castBar:SetParent(acFrame)
            castBar:SetFrameStrata("HIGH")
            castBar:SetFrameLevel(10)
            
            -- CRITICAL: Ensure cast bar stays shown even if parent CompactArenaFrame is hidden
            castBar:SetIgnoreParentAlpha(true)
            
            -- Store original SetPoint function to restore Blizzard's positioning
            if not castBar._originalSetPoint then
                castBar._originalSetPoint = castBar.SetPoint
            end
            
            -- Apply blocky style (MaskTexture for sharp rectangle edges)
            self:ApplyBlockyStyle(castBar)
            
            -- Hook into cast bar OnEvent to apply uninterruptible coloring
            self:HookCastBarColors(castBar)
        else
            -- DEBUG DISABLED: print(string.format("|cffFF0000ArenaCore:|r Missing components for frame %d", i))
        end
    end
end

-- ============================================================================
-- CLEAR ALL CAST BARS
-- Prevents stale cast data from persisting across arena state changes
-- ============================================================================

function CastBars:ClearAllCastBars()
    if not isMidnight then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local castBar = self.bars[i]
        if castBar then
            -- Hide the cast bar
            castBar:Hide()
            
            -- Clear cast bar state
            castBar.casting = nil
            castBar.channeling = nil
            castBar.empowering = nil
            
            -- Reset progress
            castBar:SetValue(0)
            
            -- Clear text
            if castBar.Text then
                castBar.Text:SetText("")
            end
            
            -- Clear icon
            if castBar.Icon then
                castBar.Icon:SetTexture(nil)
            end
            
            -- Hide shield (uninterruptible indicator)
            if castBar.BorderShield then
                castBar.BorderShield:Hide()
            end
        end
    end
end

-- ============================================================================
-- APPLY BLOCKY STYLE (MaskTexture)
-- Creates sharp rectangle edges
-- ============================================================================

function CastBars:ApplyBlockyStyle(castBar)
    if not castBar then return end
    
    -- APPROACH 1: Use custom texture from database, fallback to flat texture
    local customTexture = self:GetCastBarTexture()
    local textureToUse = customTexture or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
    castBar:SetStatusBarTexture(textureToUse)
    
    -- APPROACH 2: Apply mask for extra sharpness
    if not castBar.arenaMask then
        castBar.arenaMask = castBar:CreateMaskTexture()
        local maskPath = "Interface\\AddOns\\ArenaCore\\Media\\CastBarMask.tga"
        castBar.arenaMask:SetTexture(maskPath, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        castBar.arenaMask:SetPoint("TOPLEFT", castBar, "TOPLEFT", -1, 0)
        castBar.arenaMask:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 1, 0)
        castBar.arenaMask:Show()
    end
    
    -- Apply mask to the status bar texture
    local statusBarTexture = castBar:GetStatusBarTexture()
    if statusBarTexture then
        statusBarTexture:AddMaskTexture(castBar.arenaMask)
    end
    
    -- APPROACH 3: Aggressively hide ALL Blizzard's decorative elements
    -- Hide known named elements
    if castBar.Border then castBar.Border:Hide() end
    if castBar.Flash then castBar.Flash:Hide() end
    if castBar.Background then castBar.Background:Hide() end
    if castBar.Spark then castBar.Spark:Hide() end
    if castBar.BorderFrame then castBar.BorderFrame:Hide() end
    
    -- Hide all child textures except the status bar fill
    local statusBarTexture = castBar:GetStatusBarTexture()
    for i = 1, castBar:GetNumRegions() do
        local region = select(i, castBar:GetRegions())
        if region and region:GetObjectType() == "Texture" and region ~= statusBarTexture then
            -- Don't hide the icon or text, only background/border textures
            if region ~= castBar.Icon and region ~= castBar.Text then
                region:Hide()
            end
        end
    end
    
    -- APPROACH 4: Add semi-transparent black background
    self:AddBackground(castBar)
    
    -- APPROACH 5: Add black pixel border
    self:AddPixelBorder(castBar)
    
    -- APPROACH 6: Ensure BorderShield exists for uninterruptible casts
    self:EnsureBorderShield(castBar)
    
    -- APPROACH 7: Add black pixel border around spell icon
    self:AddSpellIconBorder(castBar)
    
    -- APPROACH 8: Center text vertically
    self:CenterText(castBar)
end

-- ============================================================================
-- ENSURE BORDER SHIELD EXISTS
-- Creates shield icon overlay for uninterruptible casts if not present
-- ============================================================================

function CastBars:EnsureBorderShield(castBar)
    if not castBar then return end
    if castBar.BorderShield then return end -- Already exists
    
    -- Create shield texture
    castBar.BorderShield = castBar:CreateTexture(nil, "OVERLAY", nil, 6)
    castBar.BorderShield:SetAtlas("UI-CastingBar-Shield")
    castBar.BorderShield:SetSize(30, 34)
    
    -- Position centered on the icon
    if castBar.Icon then
        castBar.BorderShield:SetPoint("CENTER", castBar.Icon, "CENTER", 0, -3)
    else
        castBar.BorderShield:SetPoint("LEFT", castBar, "LEFT", -15, 0)
    end
    
    castBar.BorderShield:Hide() -- Hidden by default
end

-- ============================================================================
-- HOOK CAST BAR STYLE
-- Intercepts ALL SetStatusBarTexture calls and replaces with custom texture
-- Also applies custom coloring based on Blizzard's barType
-- ============================================================================

-- Get user's selected cast bar texture from database
function CastBars:GetCastBarTexture()
    local db = AC.DB and AC.DB.profile and AC.DB.profile.textures
    if not db then return nil end
    
    -- Check if user has a specific cast bar texture set
    if db.useDifferentCastBarTexture and db.castBarTexture then
        return db.castBarTexture
    end
    
    -- Fall back to power bar texture if set
    if db.useDifferentPowerBarTexture and db.powerBarTexture then
        return db.powerBarTexture
    end
    
    -- Fall back to health bar texture
    return db.healthBarTexture
end

function CastBars:HookCastBarColors(castBar)
    if not castBar then return end
    if castBar._arenaColorHooked then return end -- Already hooked
    
    -- Hook SetStatusBarTexture to apply our texture AFTER Blizzard sets theirs
    -- Using hooksecurefunc is safe and won't cause taint/secret value issues
    hooksecurefunc(castBar, "SetStatusBarTexture", function(self)
        local customTexture = CastBars:GetCastBarTexture()
        if customTexture and not self._settingCustomTexture then
            self._settingCustomTexture = true
            -- Use raw StatusBar method to avoid recursion
            getmetatable(self).__index.SetStatusBarTexture(self, customTexture)
            self._settingCustomTexture = nil
        end
    end)
    
    -- Use HookScript for OnEvent for Midnight
    -- This is more reliable than hooksecurefunc for frame scripts
    castBar:HookScript("OnEvent", function(self, event, eventUnit)
        CastBars:ApplyCastBarColor(self)
    end)
    
    -- Hook UpdateInterruptibleState for mid-cast interruptibility changes
    -- This fires when UNIT_SPELLCAST_INTERRUPTIBLE/NOT_INTERRUPTIBLE events occur
    if castBar.UpdateInterruptibleState then
        hooksecurefunc(castBar, "UpdateInterruptibleState", function(self)
            CastBars:ApplyCastBarColor(self)
        end)
    end
    
    castBar._arenaColorHooked = true
end

function CastBars:ApplyCastBarColor(castBar)
    if not castBar then return end
    
    local barType = castBar.barType
    
    -- DEBUG: Log barType to understand what's happening
    --[[ DEBUG DISABLED:
    if barType then
        local spellName = castBar.Text and castBar.Text:GetText() or "Unknown"
        print(string.format("[CastBar Color] Spell: %s | barType: %s", spellName, tostring(barType)))
    end
    --]]
    
    if barType == "uninterruptable" then
        castBar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
        if castBar.BorderShield then
            castBar.BorderShield:Show()
        end
    elseif barType == "channel" then
        castBar:SetStatusBarColor(0, 1, 0, 1)
        if castBar.BorderShield then
            castBar.BorderShield:Hide()
        end
    elseif barType == "interrupted" then
        castBar:SetStatusBarColor(1, 0, 0, 1)
        if castBar.BorderShield then
            castBar.BorderShield:Hide()
        end
    else
        castBar:SetStatusBarColor(1, 0.7, 0, 1)
        if castBar.BorderShield then
            castBar.BorderShield:Hide()
        end
    end
end

-- ============================================================================
-- ADD BACKGROUND (Semi-transparent black rectangle)
-- Creates clean background behind cast bar
-- ============================================================================

function CastBars:AddBackground(castBar)
    if not castBar then return end
    if castBar.arenaBackground then return end -- Already has background
    
    -- Create background frame
    castBar.arenaBackground = CreateFrame("Frame", nil, castBar)
    castBar.arenaBackground:SetAllPoints()
    castBar.arenaBackground:SetFrameLevel(castBar:GetFrameLevel() - 1)
    
    -- Create semi-transparent black texture
    castBar.arenaBackground.texture = castBar.arenaBackground:CreateTexture(nil, "BACKGROUND")
    castBar.arenaBackground.texture:SetAllPoints()
    castBar.arenaBackground.texture:SetColorTexture(0, 0, 0, 0.5) -- Semi-transparent black
    castBar.arenaBackground:Show()
end

-- ============================================================================
-- CENTER TEXT VERTICALLY
-- Moves spell name text to center of cast bar instead of bottom
-- ============================================================================

function CastBars:CenterText(castBar)
    if not castBar then return end
    if not castBar.Text then return end
    
    -- Use ArenaCore's custom font for consistency
    local AC = _G.ArenaCore
    local fontPath = AC and AC.FONT_PATH or "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf"
    local fontSize = 12 -- Standard cast bar text size
    
    -- Set custom font with outline
    castBar.Text:SetFont(fontPath, fontSize, "OUTLINE")
    
    -- Clear current text anchor and reposition to center
    castBar.Text:ClearAllPoints()
    castBar.Text:SetPoint("CENTER", castBar, "CENTER", 0, 0)
end

-- ============================================================================
-- ADD PIXEL BORDER (Black outline around cast bar)
-- ============================================================================

function CastBars:AddPixelBorder(castBar)
    if not castBar then return end
    if castBar.pixelBorder then return end -- Already has border
    
    local borderSize = 2 -- 2 pixel border (thicker outline)
    
    -- Create holder frame for borders
    castBar.pixelBorder = CreateFrame("Frame", nil, castBar)
    castBar.pixelBorder:SetAllPoints()
    castBar.pixelBorder:SetFrameLevel(castBar:GetFrameLevel() + 1)
    
    local holder = castBar.pixelBorder
    
    -- Create 4 edge textures (top, bottom, left, right)
    holder.edges = {}
    for i = 1, 4 do
        local tex = holder:CreateTexture(nil, "OVERLAY", nil, 7)
        tex:SetColorTexture(0, 0, 0, 1) -- Solid black
        holder.edges[i] = tex
    end
    
    local top, bottom, left, right = holder.edges[1], holder.edges[2], holder.edges[3], holder.edges[4]
    
    -- Top edge
    top:SetPoint("TOPLEFT", castBar, "TOPLEFT", -borderSize, borderSize)
    top:SetPoint("TOPRIGHT", castBar, "TOPRIGHT", borderSize, borderSize)
    top:SetHeight(borderSize)
    
    -- Bottom edge
    bottom:SetPoint("BOTTOMLEFT", castBar, "BOTTOMLEFT", -borderSize, -borderSize)
    bottom:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", borderSize, -borderSize)
    bottom:SetHeight(borderSize)
    
    -- Left edge
    left:SetPoint("TOPLEFT", castBar, "TOPLEFT", -borderSize, borderSize)
    left:SetPoint("BOTTOMLEFT", castBar, "BOTTOMLEFT", -borderSize, -borderSize)
    left:SetWidth(borderSize)
    
    -- Right edge
    right:SetPoint("TOPRIGHT", castBar, "TOPRIGHT", borderSize, borderSize)
    right:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", borderSize, -borderSize)
    right:SetWidth(borderSize)
    
    holder:Show()
end

-- ============================================================================
-- ADD SPELL ICON BORDER (Black outline around spell icon)
-- Creates black pixel border around the spell icon to match cast bar styling
-- ============================================================================

function CastBars:AddSpellIconBorder(castBar)
    if not castBar then return end
    if not castBar.Icon then return end -- No icon to border
    if castBar.Icon._borderFrame then return end -- Already has border
    
    -- Get icon's parent frame (legacy approach)
    local iconParent = castBar.Icon:GetParent()
    
    -- Create border frame for spell icon (parented to icon's parent, not castBar)
    local iconBorderFrame = CreateFrame("Frame", nil, iconParent)
    iconBorderFrame:SetAllPoints(castBar.Icon)
    iconBorderFrame:SetFrameLevel(castBar:GetFrameLevel() + 11)  -- Above cast bar borders
    
    -- Top border (2px, no offset)
    local top = iconBorderFrame:CreateTexture(nil, "OVERLAY")
    top:SetColorTexture(0, 0, 0, 1)
    top:SetPoint("TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", 0, 0)
    top:SetHeight(2)
    
    -- Bottom border
    local bottom = iconBorderFrame:CreateTexture(nil, "OVERLAY")
    bottom:SetColorTexture(0, 0, 0, 1)
    bottom:SetPoint("BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(2)
    
    -- Left border
    local left = iconBorderFrame:CreateTexture(nil, "OVERLAY")
    left:SetColorTexture(0, 0, 0, 1)
    left:SetPoint("TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", 0, 0)
    left:SetWidth(2)
    
    -- Right border
    local right = iconBorderFrame:CreateTexture(nil, "OVERLAY")
    right:SetColorTexture(0, 0, 0, 1)
    right:SetPoint("TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", 0, 0)
    right:SetWidth(2)
    
    castBar.Icon._borderFrame = iconBorderFrame
end

-- ============================================================================
-- POSITION CAST BAR
-- ============================================================================

function CastBars:PositionCastBar(index)
    local castBar = self.bars[index]
    if not castBar then return end
    
    local MFM = AC.MasterFrameManager
    local acFrame = MFM and MFM.frames and MFM.frames[index]
    if not acFrame then return end
    
    -- Read from GLOBAL SavedVariables directly for consistency
    -- CRITICAL: Default values MUST match Init.lua DEFAULTS.castBars exactly
    local db = _G.ArenaCoreDB and _G.ArenaCoreDB.profile and _G.ArenaCoreDB.profile.castBars
    local settings = db or {
        positioning = { horizontal = -4, vertical = -86 },
        sizing = { width = 220, height = 24 },
    }
    
    local pos = settings.positioning or {}
    local sizing = settings.sizing or {}
    
    -- Use Init.lua canonical defaults: horizontal=-4, vertical=-86, width=220, height=24
    local horizontal = pos.horizontal or -4
    local vertical = pos.vertical or -86
    local width = sizing.width or 220
    local height = sizing.height or 24
    
    -- CRITICAL FIX: Use same anchor point as ArenaCore.lua (TOP-TOP, not TOP-BOTTOM)
    -- ArenaCore.lua line 3063 uses: SetPoint("TOP", frame, "TOP", cbHorizontal, cbVertical)
    -- This ensures consistent positioning between test mode and arena
    castBar:ClearAllPoints()
    
    -- RELOAD FIX: Use _originalSetPoint to bypass the SetPoint override in EnteredArena()
    -- This ensures repositioning works even after reload in arena
    if castBar._originalSetPoint then
        castBar._originalSetPoint(castBar, "TOP", acFrame, "TOP", horizontal, vertical)
    else
        castBar:SetPoint("TOP", acFrame, "TOP", horizontal, vertical)
    end
    
    castBar:SetSize(width, height)
end

-- ============================================================================
-- REFRESH ALL CAST BAR POSITIONS
-- Called when settings change
-- ============================================================================

function CastBars:RefreshLayout()
    for i = 1, MAX_ARENA_ENEMIES do
        self:PositionCastBar(i)
        -- Reapply blocky style after positioning to prevent texture reset
        local castBar = self.bars[i]
        if castBar then
            self:ApplyBlockyStyle(castBar)
            -- Apply spell icon settings from UI
            self:ApplySpellIconSettings(castBar)
        end
    end
    
    -- If in test mode, ensure cast bars are visible
    if AC.testModeEnabled then
        self:ShowTestCastBars()
    end
end

-- ============================================================================
-- APPLY SPELL ICON SETTINGS
-- Applies positioning and scale from UI settings to cast bar Icon
-- ============================================================================

function CastBars:ApplySpellIconSettings(castBar)
    if not castBar then return end
    if not castBar.Icon then return end
    
    -- Read spell icon settings from database
    local db = _G.ArenaCoreDB and _G.ArenaCoreDB.profile and _G.ArenaCoreDB.profile.castBars
    local iconSettings = db and db.spellIcons
    
    if not iconSettings then return end
    
    -- Check if enabled
    local enabled = iconSettings.enabled
    if enabled == nil then enabled = true end
    
    if enabled then
        castBar.Icon:SetAlpha(1)
        castBar.Icon:Show()
        if castBar.BorderShield then
            castBar.BorderShield:SetAlpha(1)
        end
        -- Show the border frame when icon is enabled
        if castBar.Icon._borderFrame then
            castBar.Icon._borderFrame:Show()
        end
    else
        castBar.Icon:SetAlpha(0)
        castBar.Icon:Hide()
        if castBar.BorderShield then
            castBar.BorderShield:SetAlpha(0)
        end
        -- CRITICAL FIX: Hide the border frame when icon is disabled
        if castBar.Icon._borderFrame then
            castBar.Icon._borderFrame:Hide()
        end
        return -- Don't apply positioning if disabled
    end
    
    -- Apply positioning
    local pos = iconSettings.positioning or {}
    local horizontal = pos.horizontal or -4
    local vertical = pos.vertical or 0
    
    -- Apply scale
    local sizing = iconSettings.sizing or {}
    local scale = (sizing.scale or 100) / 100
    
    -- Reposition icon relative to cast bar
    castBar.Icon:ClearAllPoints()
    castBar.Icon:SetPoint("RIGHT", castBar, "LEFT", horizontal, vertical)
    castBar.Icon:SetScale(scale)
    
    -- Also scale and reposition BorderShield to follow the icon
    if castBar.BorderShield then
        castBar.BorderShield:ClearAllPoints()
        castBar.BorderShield:SetPoint("CENTER", castBar.Icon, "CENTER", 0, -3)
        castBar.BorderShield:SetScale(scale)
    end
    
    -- Also scale and reposition the icon border to match the icon
    if castBar.Icon._borderFrame then
        castBar.Icon._borderFrame:ClearAllPoints()
        castBar.Icon._borderFrame:SetAllPoints(castBar.Icon)
    end
end

-- ============================================================================
-- TEST MODE: Show Cast Bars with Fake Data
-- ============================================================================

function CastBars:ShowTestCastBars()
    if not isMidnight then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local castBar = self.bars[i]
        local testData = TEST_CAST_DATA[i]
        
        if castBar and testData then
            -- Show cast bar
            castBar:Show()
            castBar:SetAlpha(1)
            
            -- Set icon
            if castBar.Icon then
                castBar.Icon:SetTexture(testData.icon)
                castBar.Icon:Show()
                -- DEBUG DISABLED: print("|cff00FF00[CastBars]|r Frame " .. i .. " Icon exists, shown: " .. tostring(castBar.Icon:IsShown()))
            else
                -- DEBUG DISABLED: print("|cffFF0000[CastBars]|r Frame " .. i .. " Icon is nil!")
            end
            
            -- Set text
            if castBar.Text then
                castBar.Text:SetText(testData.name)
            end
            
            -- Reapply blocky style FIRST to ensure BorderShield is created
            self:ApplyBlockyStyle(castBar)
            
            -- Set colors based on cast type
            if testData.uninterruptible then
                castBar:SetStatusBarColor(0.7, 0.7, 0.7, 1) -- Gray for uninterruptible
                -- Show shield icon (Blizzard's BorderShield)
                if castBar.BorderShield then
                    castBar.BorderShield:Show()
                    -- DEBUG DISABLED: print("|cff00FF00[CastBars]|r Frame " .. i .. " BorderShield:Show() called")
                else
                    -- DEBUG DISABLED: print("|cffFF0000[CastBars]|r Frame " .. i .. " BorderShield is nil!")
                end
            elseif testData.channel then
                castBar:SetStatusBarColor(0, 1, 0, 1) -- Green for channel
                if castBar.BorderShield then
                    castBar.BorderShield:Hide()
                end
            else
                castBar:SetStatusBarColor(1, 0.7, 0, 1) -- Orange for regular cast
                if castBar.BorderShield then
                    castBar.BorderShield:Hide()
                end
            end
            
            -- Animate the cast bar
            self:AnimateTestCastBar(castBar, testData.duration, i)
        end
    end
end

-- ============================================================================
-- ANIMATE TEST CAST BAR
-- Creates realistic cast bar animation in test mode
-- ============================================================================

function CastBars:AnimateTestCastBar(castBar, duration, index)
    if not castBar then return end
    
    -- Cancel any existing animation
    if castBar._testTicker then
        castBar._testTicker:Cancel()
        castBar._testTicker = nil
    end
    
    local startTime = GetTime()
    local endTime = startTime + duration
    
    -- Set initial value
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)
    
    -- Create animation ticker
    castBar._testTicker = C_Timer.NewTicker(0.02, function()
        if not AC.testModeEnabled then
            castBar._testTicker:Cancel()
            castBar._testTicker = nil
            castBar:Hide()
            return
        end
        
        local now = GetTime()
        local elapsed = now - startTime
        local progress = elapsed / duration
        
        if progress >= 1 then
            -- Reset and loop
            startTime = GetTime()
            endTime = startTime + duration
            castBar:SetValue(0)
        else
            castBar:SetValue(progress)
        end
    end)
    
    -- Register ticker for cleanup
    if AC.RegisterTicker then
        AC:RegisterTicker(castBar._testTicker, "castbar_test_" .. index)
    end
end

-- ============================================================================
-- HIDE TEST CAST BARS
-- Called when exiting test mode
-- ============================================================================

function CastBars:HideTestCastBars()
    for i = 1, MAX_ARENA_ENEMIES do
        local castBar = self.bars[i]
        if castBar then
            -- Cancel animation
            if castBar._testTicker then
                castBar._testTicker:Cancel()
                castBar._testTicker = nil
            end
            
            -- Hide cast bar
            castBar:Hide()
            castBar:SetAlpha(0)
        end
    end
end

-- ============================================================================
-- HOOK INTO ARENACORE SYSTEMS
-- ============================================================================

-- Hook into test mode enable
local function OnTestModeEnabled()
    C_Timer.After(0.5, function()
        CastBars:SetupCastBars()
        CastBars:RefreshLayout()
    end)
end

-- Hook into test mode disable
local function OnTestModeDisabled()
    CastBars:HideTestCastBars()
end

-- Hook into arena entry
local function OnArenaEnter()
    C_Timer.After(0.3, function()
        CastBars:SetupCastBars()
        CastBars:RefreshLayout()
    end)
end

-- ============================================================================
-- EXPOSED API FOR SETTINGS PAGE
-- ============================================================================

function AC:RefreshCastBarsLayout()
    if CastBars.RefreshLayout then
        CastBars:RefreshLayout()
    end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local _, instanceType = IsInInstance()
        if instanceType == "arena" then
            OnArenaEnter()
        end
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" or event == "ARENA_OPPONENT_UPDATE" then
        -- CRITICAL FIX: Clear all cast bars to prevent stale cast data
        -- This fixes the bug where spells from prep room persist on wrong frames
        CastBars:ClearAllCastBars()
        
        C_Timer.After(0.2, function()
            CastBars:SetupCastBars()
            CastBars:RefreshLayout()
        end)
    end
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize after a short delay to ensure frames exist
C_Timer.After(1, function()
    CastBars:Initialize()
end)

-- Hook into MFM test mode (with delay to ensure MFM exists)
C_Timer.After(2, function()
    if not AC.MasterFrameManager then return end
    
    local oldEnableTestMode = AC.MasterFrameManager.EnableTestMode
    if oldEnableTestMode then
        AC.MasterFrameManager.EnableTestMode = function(self, ...)
            local result = oldEnableTestMode(self, ...)
            OnTestModeEnabled()
            return result
        end
    end
    
    local oldDisableTestMode = AC.MasterFrameManager.DisableTestMode
    if oldDisableTestMode then
        AC.MasterFrameManager.DisableTestMode = function(self, ...)
            OnTestModeDisabled()
            return oldDisableTestMode(self, ...)
        end
    end
end)

-- DEBUG DISABLED: print("|cff00FF00ArenaCore:|r Cast Bars module loaded (sArena-style)")
