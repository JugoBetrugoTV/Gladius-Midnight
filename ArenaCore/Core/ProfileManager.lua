-- ============================================================================
-- ARENACORE PROFILE MANAGER - Full Profile System
-- ============================================================================
-- Handles profile creation, switching, deletion, import/export
-- Self-contained system with no external dependencies

local AC = _G.ArenaCore
if not AC then return end

AC.ProfileManager = AC.ProfileManager or {}
local PM = AC.ProfileManager

-- Constants
PM.MAX_PROFILES = 8
PM.DEFAULT_PROFILE_NAME = "ArenaCore Default"
PM.PROFILE_PREFIX = "!AC"
PM.PROFILE_SUFFIX = "!AC"

-- ============================================================================
-- PROFILE EDIT MODE - Temp Buffer System
-- ============================================================================
-- PROFILE EDIT MODE SYSTEM
-- When edit mode is active, all setting changes are buffered to AC.tempProfileBuffer
-- instead of being auto-saved to the database. This allows users to experiment
-- with new layouts without corrupting their current profile.
AC.profileEditModeActive = false
AC.tempProfileBuffer = {}
AC.profileSnapshot = nil  -- Snapshot of profile state when Edit Mode starts

function PM:Initialize()
    if self.initialized then return end
    
    -- CRITICAL FIX: Ensure the global database exists (for new users)
    if not _G.ArenaCoreDB then 
        _G.ArenaCoreDB = { profile = {} }
        print("|cffFFAA00ProfileManager:|r Created new ArenaCoreDB for first-time user")
    end
    
    -- CRITICAL FIX: If profile is a string (like "Default"), convert it to a table
    if type(_G.ArenaCoreDB.profile) ~= "table" then
        print("|cffFFAA00ProfileManager:|r WARNING - profile was type: " .. type(_G.ArenaCoreDB.profile) .. ", converting to table")
        _G.ArenaCoreDB.profile = {}
    end
    
    -- CRITICAL FIX: Set up AC.DB reference if it doesn't exist or is wrong type
    if not AC.DB or type(AC.DB.profile) ~= "table" then
        AC.DB = { profile = _G.ArenaCoreDB.profile }
        print("|cffFFAA00ProfileManager:|r Created AC.DB reference")
    end
    
    if not _G.ArenaCoreDB.profile.backups then
        _G.ArenaCoreDB.profile.backups = {}
    end
    if not _G.ArenaCoreDB.profile.textures then
        _G.ArenaCoreDB.profile.textures = {
            positioning = { horizontal = 56, vertical = 15, spacing = 2 },
            sizing = { healthWidth = 128, healthHeight = 18, resourceWidth = 136, resourceHeight = 8 },
            healthBarTexture = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture1.tga",
            powerBarTexture = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture1.tga",
            castBarTexture = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture1.tga",
            useDifferentPowerBarTexture = true,
            useDifferentCastBarTexture = true
        }
        print("|cff22AA44ProfileManager:|r Created default textures structure (unified)")
    else
        -- Migrate legacy keys to unified structure if needed
        local t = _G.ArenaCoreDB.profile.textures
        if t.barPosition and not t.positioning then
            t.positioning = {
                horizontal = t.barPosition.horizontal or 56,
                vertical   = t.barPosition.vertical or 15,
                spacing    = t.barPosition.spacing or 2,
            }
        end
        if t.barSizing and not t.sizing then
            t.sizing = {
                healthWidth    = t.barSizing.healthWidth or 128,
                healthHeight   = t.barSizing.healthHeight or 18,
                resourceWidth  = t.barSizing.resourceWidth or 136,
                resourceHeight = t.barSizing.resourceHeight or 8,
            }
        end
    end
    
    -- Initialize textScale defaults if not exist
    if not _G.ArenaCoreDB.profile.textScale then
        _G.ArenaCoreDB.profile.textScale = {
            healthTextScale = 100,
            resourceTextScale = 100,
            spellTextScale = 100
        }
        print("|cff22AA44ProfileManager:|r Created default textScale structure")
    end
    self.initialized = true
    -- DEBUG: Profile Manager initialized
    -- print("|cff22AA44ArenaCore Profile Manager:|r Initialized")
end

function PM:UpdateUICheckboxStates()
    print("|cff00FF00ProfileManager:|r UpdateUICheckboxStates called")
    print("|cff00FF00ProfileManager:|r IsUIVisible = " .. tostring(AC.IsUIVisible))
    print("|cff00FF00ProfileManager:|r currentPage = " .. tostring(AC.currentPage))

    -- Check if UI is visible and on the right page
    local uiVisible = AC.configFrame and AC.configFrame:IsShown()
    local onArenaFramesPage = AC.currentPage == "ArenaFrames" or AC.__currentPage == "ArenaFrames"

    print("|cff00FF00ProfileManager:|r UI visible = " .. tostring(uiVisible))
    print("|cff00FF00ProfileManager:|r On ArenaFrames page = " .. tostring(onArenaFramesPage))

    if uiVisible and onArenaFramesPage then
        print("|cff00FF00ProfileManager:|r Refreshing UI checkboxes")
        -- Force recreation of the page to ensure checkboxes reflect database values
        C_Timer.After(0.2, function()
            if AC.__pageFrames and AC.__pageFrames["ArenaFrames"] then
                AC.__pageFrames["ArenaFrames"]:Hide()
                AC.__pageFrames["ArenaFrames"] = nil
            end
            AC.__currentPage = nil
            if AC.ShowPage then
                local result = AC:ShowPage("ArenaFrames")
                print("|cff00FF00ProfileManager:|r Checkbox refresh result: " .. tostring(result))
            end
        end)
    else
        print("|cff00FF00ProfileManager:|r Conditions not met for checkbox refresh")
    end
end

function PM:ForceCompleteUIRefresh()
    print("|cff00FF00ProfileManager:|r ForceCompleteUIRefresh called")
    
    if not AC.configFrame or not AC.configFrame:IsShown() then
        print("|cffFF0000ProfileManager:|r UI not visible, attempting to show ArenaFrames page")
        
        -- If UI is not visible, try to open it and show the page
        if AC.OpenConfigPanel then
            AC:OpenConfigPanel(false) -- Don't toggle, just open
            C_Timer.After(0.2, function()
                self:ForcePageRecreation("ArenaFrames")
            end)
        end
        return
    end

    -- UI is visible, force complete recreation
    print("|cff00FF00ProfileManager:|r UI is visible, forcing page recreation")
    self:ForcePageRecreation("ArenaFrames")
end

function PM:ForceSynchronousUIRefresh()
    -- Small delay to ensure database changes have taken effect
    C_Timer.After(0.05, function()
        -- Try to find and update existing checkboxes on the current page
        if AC.configFrame and AC.configFrame:IsShown() then
            -- Look for ArenaFrames page checkboxes and sliders and update them
            self:RefreshExistingCheckboxes()
            self:RefreshExistingSliders()
        else
            -- If config frame is not shown, try to force a page refresh
            if AC.ShowPage then
                AC:ShowPage("ArenaFrames")
                -- Try again after a delay
                C_Timer.After(0.1, function()
                    self:RefreshExistingCheckboxes()
                    self:RefreshExistingSliders()
                end)
            end
        end
    end)
end

function PM:RefreshExistingCheckboxes()
    -- Get the scroll child where checkboxes are located
    local scrollChild = AC.scrollChild
    if not scrollChild then
        return
    end
    
    -- Define the settings in the order they appear in the UI
    -- CRITICAL: Use flat boolean paths that match ArenaFrames page checkboxes
    local settingsOrder = {
        "arenaFrames.general.statusText",       -- "Status Text" checkbox
        "arenaFrames.general.usePercentage",    -- "Use Percentage" checkbox
        "arenaFrames.general.useClassColors",
        "arenaFrames.general.showNames",
        "arenaFrames.general.showArenaNumbers"
    }
    
    -- Look for checkbox elements and update them in order
    local checkboxIndex = 1
    local function findAndUpdateCheckboxes(frame)
        if not frame then return end
        
        -- Check if this frame has checkbox functionality
        if frame.checkButton and frame.checkButton.SetChecked and checkboxIndex <= #settingsOrder then
            local settingPath = settingsOrder[checkboxIndex]
            local newValue = self:GetSetting(settingPath)
            if newValue ~= nil then
                -- Delay the visual update to ensure it takes effect
                C_Timer.After(0.01, function()
                    frame:SetChecked(newValue)
                    
                    -- Update visual indicator if it exists
                    if frame.updateIndicator then
                        frame.updateIndicator()
                    end
                end)
                
                checkboxIndex = checkboxIndex + 1
            end
        end
        
        -- Recursively check child frames
        local children = {frame:GetChildren()}
        for _, child in ipairs(children) do
            findAndUpdateCheckboxes(child)
        end
    end
    
    findAndUpdateCheckboxes(scrollChild)
end

function PM:RefreshExistingSliders()
    -- Get the scroll child where sliders are located
    local scrollChild = AC.scrollChild
    if not scrollChild then
        return
    end
    
    -- Define the slider settings in the order they appear in the UI
    local sliderSettings = {
        "arenaFrames.general.playerNameX",
        "arenaFrames.general.playerNameY", 
        "arenaFrames.general.arenaNumberX",
        "arenaFrames.general.arenaNumberY",
        "arenaFrames.general.playerNameScale",
        "arenaFrames.general.arenaNumberScale",
        "arenaFrames.general.healthTextScale",
        "arenaFrames.general.resourceTextScale",
        "arenaFrames.general.spellTextScale",
        "arenaFrames.positioning.horizontal",
        "arenaFrames.positioning.vertical",
        "arenaFrames.positioning.spacing",
        "arenaFrames.sizing.scale",
        "arenaFrames.sizing.width",
        "arenaFrames.sizing.height"
    }
    
    -- Look for slider elements and update them in order
    local sliderIndex = 1
    local function findAndUpdateSliders(frame)
        if not frame then return end
        
        -- Check if this frame has slider functionality (look for slider.slider)
        if frame.slider and frame.slider.slider and frame.slider.slider.SetValue and sliderIndex <= #sliderSettings then
            local settingPath = sliderSettings[sliderIndex]
            local newValue = self:GetSetting(settingPath)
            if newValue ~= nil then
                -- Delay the visual update to ensure it takes effect
                C_Timer.After(0.01, function()
                    frame.slider.slider:SetValue(newValue)
                end)
                
                sliderIndex = sliderIndex + 1
            end
        end
        
        -- Recursively check child frames
        local children = {frame:GetChildren()}
        for _, child in ipairs(children) do
            findAndUpdateSliders(child)
        end
    end
    
    findAndUpdateSliders(scrollChild)
end

function PM:ForcePageRecreation(pageName)
    print("|cff00FF00ProfileManager:|r ForcePageRecreation called for: " .. pageName)
    
    -- Clear any cached page frame
    if AC.__pageFrames and AC.__pageFrames[pageName] then
        print("|cff00FF00ProfileManager:|r Clearing cached page frame: " .. pageName)
        AC.__pageFrames[pageName]:Hide()
        AC.__pageFrames[pageName] = nil
    end

    -- Clear current page to force recreation
    AC.__currentPage = nil
    AC.currentPage = nil

    -- Force recreation after a short delay
    C_Timer.After(0.1, function()
        -- Recreating page
        if AC.ShowPage then
            local result = AC:ShowPage(pageName)
            -- Page recreation completed
        else
            -- ShowPage function not available
        end
    end)
end

function PM:RefreshConfig()
    self:ApplyArenaFramesSettings()
    self:UpdateUICheckboxStates()
end

function PM:ApplyArenaFramesSettings()
    local currentDB = _G.ArenaCoreDB
    if not currentDB or not currentDB.profile.arenaFrames then 
        return 
    end
    
    local settings = currentDB.profile.arenaFrames
    local general = settings.general or {}
    
    -- CRITICAL: Apply general settings (checkboxes like server names, arena numbers, etc.)
    if AC.ApplyGeneralSettings then
        AC:ApplyGeneralSettings()
    end
    
    -- CRITICAL: If in test mode, reapply test data to show updated names
    -- Small delay ensures database is fully updated before reading settings
    if AC.testModeEnabled and AC.MasterFrameManager and AC.MasterFrameManager.ApplyTestData then
        C_Timer.After(0.05, function()
            AC.MasterFrameManager:ApplyTestData()
        end)
    end
    
    -- CONNECT TO MASTER FRAME MANAGER SYSTEM
    if AC.UpdateFramePositions then
        AC:UpdateFramePositions()
    end
    if AC.MasterFrameManager and AC.MasterFrameManager.UpdateFramePositions then
        AC.MasterFrameManager:UpdateFramePositions()
    end
    if AC.UpdateFrameScale then
        AC:UpdateFrameScale()
    end
    if AC.UpdateFrameSize then
        AC:UpdateFrameSize()
    end
    
    -- CRITICAL FIX: Refresh ALL draggable elements after Edit Mode save
    -- Without this, elements stay at dragged position visually but database has saved position
    -- This causes a jump when sliders are moved later (layout refresh reads from database)
    if AC.RefreshTrinketsOtherLayout then
        AC:RefreshTrinketsOtherLayout()
    end
    if AC.RefreshCastBarsLayout then
        AC:RefreshCastBarsLayout()
    end
    -- CRITICAL FIX: DO NOT call RefreshClassIcons here - it causes jump by reading stale database
    -- Class icons need their dragged position captured BEFORE any refresh happens
    -- CRITICAL FIX: DO NOT call RefreshDRLayout here - it causes bounce effect during save
    -- DR positioning is handled by the DR sliders themselves via Helpers.lua callbacks
    -- Calling it here causes double-refresh with stale database values
    if AC.RefreshDebuffsLayout then
        AC:RefreshDebuffsLayout()
    end
    if AC.RefreshMoreGoodiesLayout then
        AC:RefreshMoreGoodiesLayout()
    end
    if AC.TriBadges and AC.TriBadges.RefreshAll then
        AC.TriBadges:RefreshAll()
    end
    
    if AC.arenaFrames then
        for i = 1, 3 do
            if AC.arenaFrames[i] then
                local frame = AC.arenaFrames[i]
                if general then
                    if frame.healthBar and frame.healthBar.statusText then
                        -- CRITICAL FIX: statusText is a boolean, not a table
                        local enabled = general.statusText
                        if enabled == nil then enabled = true end
                        frame.healthBar.statusText:SetShown(enabled)
                        if enabled then
                            local healthPct = math.floor((frame.healthBar:GetValue() or 70) / (select(2, frame.healthBar:GetMinMaxValues()) or 100) * 100)
                            -- Use general.usePercentage for percentage display (not statusText.usePercentage)
                            local usePct = general.usePercentage
                            if usePct == nil then usePct = true end
                            frame.healthBar.statusText:SetText(usePct and (healthPct .. "%") or frame.healthBar:GetValue() or 70)
                        end
                    end

                    if frame.manaBar and frame.manaBar.statusText then
                        -- CRITICAL FIX: statusText is a boolean, not a table
                        local enabled = general.statusText
                        if enabled == nil then enabled = true end
                        frame.manaBar.statusText:SetShown(enabled)
                        if enabled then
                            local manaPct = math.floor((frame.manaBar:GetValue() or 50) / (select(2, frame.manaBar:GetMinMaxValues()) or 100) * 100)
                            -- Use general.usePercentage for percentage display (not statusText.usePercentage)
                            local usePct = general.usePercentage
                            if usePct == nil then usePct = true end
                            frame.manaBar.statusText:SetText(usePct and (manaPct .. "%") or frame.manaBar:GetValue() or 50)
                        end
                    end

                    if frame.playerName then
                        local show = general.showNames
                        if show == nil then show = true end
                        frame.playerName:SetShown(show)
                        if show then
                            -- CRITICAL FIX: Use proper nil check - 0 is a valid value!
                            local x = (general.playerNameX ~= nil) and general.playerNameX or 52
                            local y = (general.playerNameY ~= nil) and general.playerNameY or 0
                            frame.playerName:ClearAllPoints()
                            
                            -- CRITICAL: Check if theme has moved playerName to an overlay
                            local parent = frame.playerName:GetParent()
                            if parent and parent ~= frame then
                                -- PlayerName is in a theme overlay
                                frame.playerName:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
                            else
                                -- Normal case
                                frame.playerName:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
                            end
                            local scale = (general.playerNameScale or 86) / 100
                            local size = math.max(6, math.floor((11 * scale) + 0.5))
                            -- Use SafeSetFont to prevent crashes
                            -- CRITICAL FIX: Use "OUTLINE" flag to match original font styling
                            if AC.SafeSetFont then
                                AC.SafeSetFont(frame.playerName, AC.FONT_PATH, size, "OUTLINE")
                            else
                                frame.playerName:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
                            end
                            frame.playerName:SetTextColor(1, 1, 1, 1)
                        end
                    end

                    if frame.arenaNumber then
                        local show = general.showArenaNumbers
                        if show == nil then show = true end
                        frame.arenaNumber:SetShown(show)
                        if show then
                            -- CRITICAL FIX: Use proper nil check - 0 is a valid value!
                            local x = (general.arenaNumberX ~= nil) and general.arenaNumberX or 190
                            local y = (general.arenaNumberY ~= nil) and general.arenaNumberY or -3
                            frame.arenaNumber:ClearAllPoints()
                            frame.arenaNumber:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
                            local scale = (general.arenaNumberScale or 119) / 100
                            local size = math.max(6, math.floor((10 * scale) + 0.5))
                            -- Use SafeSetFont to prevent crashes
                            -- CRITICAL FIX: Use "OUTLINE" flag to match original font styling
                            if AC.SafeSetFont then
                                AC.SafeSetFont(frame.arenaNumber, AC.FONT_PATH, size, "OUTLINE")
                            else
                                frame.arenaNumber:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
                            end
                            frame.arenaNumber:SetTextColor(1, 1, 1, 1)
                        end
                    end

                    if frame.playerName and general.playerNameScale then
                        frame.playerName:SetScale(general.playerNameScale / 100)
                    end
                    if frame.arenaNumber and general.arenaNumberScale then
                        frame.arenaNumber:SetScale(general.arenaNumberScale / 100)
                    end
                    if frame.healthBar and frame.healthBar.statusText and general.healthTextScale then
                        frame.healthBar.statusText:SetScale(general.healthTextScale / 100)
                    end
                    if frame.manaBar and frame.manaBar.statusText and general.resourceTextScale then
                        frame.manaBar.statusText:SetScale(general.resourceTextScale / 100)
                    end
                    if frame.castBar and frame.castBar.Text and general.spellTextScale then
                        frame.castBar.Text:SetScale(general.spellTextScale / 100)
                    end
                end
            end
        end
    end
end

function PM:CreateBackup(name)
    local currentDB = _G.ArenaCoreDB
    if not currentDB then return false end
    name = name or ("Backup_" .. date("%Y%m%d_%H%M%S"))
    
    self:CaptureFramePositions()
    
    local function DeepCopy(t)
        if type(t) ~= "table" then return t end
        local c = {}
        for k, v in pairs(t) do c[k] = DeepCopy(v) end
        -- Copy metatable if it exists
        local mt = getmetatable(t)
        if mt then setmetatable(c, mt) end
        return c
    end
    
    -- Also initialize textScale in backup creation
    currentDB.profile.backups[name] = {
        arenaFrames = DeepCopy(currentDB.profile.arenaFrames),
        castBars = DeepCopy(currentDB.profile.castBars or {}),
        textures = DeepCopy(currentDB.profile.textures or {}),
        textScale = DeepCopy(currentDB.profile.textScale or {}),
        timestamp = time(),
        dateString = date("%Y-%m-%d %H:%M:%S")
    }
    
    -- Debug player name positioning
    if currentDB.profile.backups[name].arenaFrames.general then
        print("|cff00FF00CreateBackup:|r Player Name X/Y saved: " .. 
              tostring(currentDB.profile.backups[name].arenaFrames.general.playerNameX) .. " / " ..
              tostring(currentDB.profile.backups[name].arenaFrames.general.playerNameY))
    end
    
    print("|cff22AA44ArenaCore:|r Backup created: '" .. name .. "'")
    return true
end

function PM:RestoreBackup(name)
    local currentDB = _G.ArenaCoreDB
    if not currentDB or not currentDB.profile.backups then return false end
    
    local backup = currentDB.profile.backups[name]
    if not backup then
        print("|cffFF0000ArenaCore:|r Backup not found: '" .. name .. "'")
        return false
    end
    
    if backup.arenaFrames then
        -- Use DeepCopy to create a proper copy, not share references
        local function DeepCopy(t)
            if type(t) ~= "table" then return t end
            local c = {}
            for k, v in pairs(t) do c[k] = DeepCopy(v) end
            -- Copy metatable if it exists
            local mt = getmetatable(t)
            if mt then setmetatable(c, mt) end
            return c
        end
        
        _G.ArenaCoreDB = _G.ArenaCoreDB or {}
        _G.ArenaCoreDB.profile = _G.ArenaCoreDB.profile or {}
        _G.ArenaCoreDB.profile.arenaFrames = DeepCopy(backup.arenaFrames)
        _G.ArenaCoreDB.profile.castBars = DeepCopy(backup.castBars or {})
        _G.ArenaCoreDB.profile.textures = DeepCopy(backup.textures or {})
        _G.ArenaCoreDB.profile.textScale = DeepCopy(backup.textScale or {})
        
        -- Debug player name positioning restore
        if _G.ArenaCoreDB.profile.arenaFrames.general then
            print("|cff00FF00RestoreBackup:|r Player Name X/Y restored to: " .. 
                  tostring(_G.ArenaCoreDB.profile.arenaFrames.general.playerNameX) .. " / " ..
                  tostring(_G.ArenaCoreDB.profile.arenaFrames.general.playerNameY))
        end
        
        print("|cff22AA44ArenaCore:|r Restored from '" .. name .. "'")
        
        -- Apply settings and force UI refresh
        self:ApplyArenaFramesSettings()
        self:ForceSynchronousUIRefresh()
        
        -- Also refresh cast bars since they were restored
        if AC.RefreshCastBarsLayout then
            AC:RefreshCastBarsLayout()
            print("|cff22AA44ArenaCore:|r Cast bars restored and refreshed")
        end
        
        -- Use original UpdateBarPositions function for bar positions
        if AC.UpdateBarPositions then
            AC:UpdateBarPositions()
            print("|cff22AA44ArenaCore:|r Bar positions restored and refreshed")
        end
        
        -- Also refresh text scaling - DISABLED TO TEST
        -- if UpdateAllFrames then
        --     UpdateAllFrames()
        --     print("|cff22AA44ArenaCore:|r Text scaling restored and refreshed")
        -- end
        
        return true
    end
    return false
end

function PM:RestoreLatest()
    -- DEBUG: Add stack trace to see what's calling this
    -- RestoreLatest called
    
    local currentDB = _G.ArenaCoreDB
    if not currentDB or not currentDB.profile.backups then return false end
    
    print("|cff00FF00RestoreLatest:|r Available backups:")
    for name, backup in pairs(currentDB.profile.backups) do
        print("|cff00FF00RestoreLatest:|r   " .. name .. " (timestamp: " .. tostring(backup.timestamp) .. ")")
        if backup.arenaFrames and backup.arenaFrames.general then
            print("|cff00FF00RestoreLatest:|r     statusText.enabled = " .. tostring(backup.arenaFrames.general.statusText.enabled))
        end
    end
    
    local latest, latestTime = nil, 0
    for name, backup in pairs(currentDB.profile.backups) do
        if backup.timestamp and backup.timestamp > latestTime then
            latestTime = backup.timestamp
            latest = name
        end
    end
    
    if latest then
        print("|cff00FF00RestoreLatest:|r Selected latest backup: " .. latest .. " (time: " .. latestTime .. ")")
        print("|cff22AA44ArenaCore:|r Restoring latest: " .. latest)
        return self:RestoreBackup(latest)
    else
        print("|cffFF0000RestoreLatest:|r No backups found")
        return false
    end
end

function PM:CaptureFramePositions()
    local currentDB = _G.ArenaCoreDB
    if not currentDB then 
        return 
    end
    
    -- Capture main frame position (optional - only exists in live arena)
    if _G.ArenaFramesAnchor then
        -- CRITICAL FIX: Don't overwrite recent user slider changes with drag position
        -- User slider changes take priority over drag position capture
        if not AC._recentUserChange then
            local _, _, _, x, y = _G.ArenaFramesAnchor:GetPoint()
            if x and y then
                currentDB.profile.arenaFrames.positioning.horizontal = math.floor(x + 0.5)
                currentDB.profile.arenaFrames.positioning.vertical = math.floor(y + 0.5)
            end
        else
            print("|cffFFFF00[DRAG PROTECTION]|r Preserving recent user slider changes - skipping drag position capture")
        end
    else
        -- ArenaFramesAnchor not found (test mode) - skipping main frame position
    end
    
    -- CRITICAL FIX: Capture ALL draggable element positions from actual frames
    -- Use FrameManager system (same as Edit Mode) instead of old arenaFrames
    local AC = _G.ArenaCore
    if not AC then
        return
    end
    if not AC.FrameManager then
        return
    end
    
    local arenaFrames = AC.FrameManager:GetFrames()
    if not arenaFrames then
        return
    end
    if not arenaFrames[1] then
        return
    end
    
    local frame = arenaFrames[1]
    
    -- Capture health bar position
    if frame.healthBar then
        local _, _, _, hx, hy = frame.healthBar:GetPoint()
        if hx and hy then
            currentDB.profile.textures = currentDB.profile.textures or {}
            currentDB.profile.textures.barPosition = currentDB.profile.textures.barPosition or {}
            currentDB.profile.textures.barPosition.horizontal = math.floor(hx + 0.5)
            currentDB.profile.textures.barPosition.vertical = math.floor(hy + 0.5)
            
            if frame.manaBar then
                local _, _, _, mx, my = frame.manaBar:GetPoint()
                if mx and my then
                    local spacing = math.abs(hy - my)
                    currentDB.profile.textures.barPosition.spacing = math.floor(spacing + 0.5)
                end
            end
        end
    end
    
    -- ============================================================================
    -- ZERO DRIFT IMPLEMENTATION
    -- ============================================================================
    -- Position capture REMOVED to eliminate feedback loop
    -- 
    -- WHY THIS FIXES DRIFT:
    -- - Never capture positions via GetPoint()
    -- - Database only updated by sliders (single source of truth)
    -- - No feedback loop = no floating-point error accumulation
    -- - Result: ZERO DRIFT (mathematically impossible to drift)
    --
    -- TRADE-OFF:
    -- - Edit Mode drag-to-position removed
    -- - Users must use sliders for positioning
    -- - Sliders provide precise 1-pixel control
    --
    -- RESEARCH: See POSITIONING_RESEARCH.md - Option 1 (⭐⭐⭐⭐⭐ BEST)
    -- ============================================================================
    
    -- Position capture code INTENTIONALLY REMOVED
    -- Class icons, trinkets, racials, cast bars NO LONGER auto-captured
    -- This eliminates the feedback loop that caused 1-3 pixel drift
    -- 
    -- Positions now ONLY updated by:
    -- 1. Sliders on Trinkets/Other page
    -- 2. Profile import
    -- 3. Theme switching (restores saved values, doesn't capture new ones)
    --
    -- NO MORE DRIFT! ✅
end

function PM:GetSetting(path)
    -- CRITICAL FIX: Auto-initialize if not done yet (for early calls)
    if not self.initialized then
        self:Initialize()
    end
    
    -- Always use the current global database to avoid stale references
    local currentDB = _G.ArenaCoreDB
    if not currentDB then return nil end
    
    -- CRITICAL FIX: Ensure profile is a table, not a string
    if type(currentDB.profile) ~= "table" then
        print("|cffFF0000ProfileManager:|r ERROR in GetSetting - profile is type: " .. type(currentDB.profile) .. ", returning nil")
        return nil
    end
    
    local keys = {strsplit(".", path)}
    local value = currentDB.profile
    for _, key in ipairs(keys) do
        if not (value and value[key] ~= nil) then
            return nil
        end
        value = value[key]
    end
    return value
end

function PM:SetSetting(path, value, skipApply)
    -- CRITICAL FIX: Auto-initialize if not done yet (for early calls)
    if not self.initialized then
        self:Initialize()
    end
    
    -- PROFILE EDIT MODE: If edit mode is active, save to temp buffer AND apply visual changes
    if AC.profileEditModeActive then
        AC.tempProfileBuffer[path] = value
        -- Continue below to apply visual changes in real-time
        -- (changes are buffered and can be discarded, but user sees them immediately)
    end
    
    -- Always use the current global database to avoid stale references
    local currentDB = _G.ArenaCoreDB
    if not currentDB then return end
    
    -- CRITICAL FIX: Ensure profile is a table, not a string
    if type(currentDB.profile) ~= "table" then
        print("|cffFF0000ProfileManager:|r ERROR - profile is type: " .. type(currentDB.profile) .. ", recreating as table")
        currentDB.profile = {}
        if AC.DB then
            AC.DB.profile = currentDB.profile
        end
    end
    
    -- DEBUG: Track all SetSetting calls for arenaFrames (DISABLED - uncomment for debugging)
    -- if path and path:match("^arenaFrames%.") then
    --     print("|cffFF00FF[PM DEBUG]|r SetSetting: path=" .. path .. ", skipApply=" .. tostring(skipApply))
    -- end
    
    local keys = {strsplit(".", path)}
    local current = currentDB.profile
    for i = 1, #keys - 1 do
        local key = keys[i]
        -- Ensure we have a table at each level
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    -- DEBUG: Track scale changes (DISABLED - was spamming chat)
    -- if path == "arenaFrames.sizing.scale" then
    --     print("|cffFFFF00[PM SCALE DEBUG]|r Setting scale to: " .. tostring(value) .. ", skipApply: " .. tostring(skipApply))
    --     print("|cffFFFF00[PM SCALE DEBUG]|r Call stack: " .. debugstack(2, 2, 2))
    -- end
    
    current[keys[#keys]] = value
    
    -- Only apply when explicitly requested (skipApply = false or nil)
    local rootKey = keys[1]
    if rootKey == "arenaFrames" and not skipApply then
        -- CRITICAL FIX: Save ALL arenaFrames changes to theme data so they persist across reloads/arena entry
        -- Without this, LoadThemeSettings() overwrites user changes with stale theme data
        if AC.ArenaFrameThemes and AC.ArenaFrameThemes.SaveCurrentThemeSettings then
            AC.ArenaFrameThemes:SaveCurrentThemeSettings()
        end
        
        -- CRITICAL FIX: Mark recent user change to protect against arena entry overwrites
        AC._recentUserChange = true
        C_Timer.After(5.0, function() AC._recentUserChange = nil end)
        
        -- CRITICAL FIX: statusText changes call dedicated update function
        -- This ensures all 3 frames update immediately in test mode, prep room, AND live arena
        if path == "arenaFrames.general.statusText" or path == "arenaFrames.general.usePercentage" then
            if AC.UpdateArenaStatusTextOnly then
                AC:UpdateArenaStatusTextOnly()
            end
            
            return -- Skip ApplyArenaFramesSettings to avoid unnecessary full refresh
        end
        
        -- CRITICAL FIX: Skip during slider drag to prevent flickering
        -- CRITICAL FIX: Skip when sizing changes are being handled specifically (scale, width, height)
        if not AC._sliderDragActive and not AC._skipArenaFramesApply then
            -- DEBUG: Track when ApplyArenaFramesSettings is triggered (DISABLED - uncomment for debugging)
            -- print("|cffFFAA00[PM DEBUG]|r ApplyArenaFramesSettings TRIGGERED by path: " .. path)
            self:ApplyArenaFramesSettings()
        end
    elseif rootKey == "textures" then
        if AC.RefreshTexturesLayout then AC:RefreshTexturesLayout() end
    elseif rootKey == "classPacks" or rootKey == "trinkets" or rootKey == "specIcons" or 
           rootKey == "racials" or rootKey == "classIcons" or rootKey == "castBars" or 
           rootKey == "diminishingReturns" or rootKey == "moreGoodies" then
        -- CRITICAL FIX: These settings have their own refresh systems in Helpers.lua
        -- Don't call ApplyArenaFramesSettings here - it causes main frames to resize/reposition
        -- Each system has its own RefreshXXXLayout function called from Helpers.lua callback
        -- Do nothing here to prevent double-refresh and frame jumping
    else
        -- Unknown setting - apply arena frames settings as fallback
        self:ApplyArenaFramesSettings()
    end
end

-- DEBUG: Profile Manager loaded
-- print("|cff8B45FFArenaCore Profile Manager:|r Loaded")

-- ============================================================================
-- FULL PROFILE SYSTEM FUNCTIONS
-- ============================================================================

--- Get list of all profile names
---@return table
function PM:GetProfileList()
    local db = AC.DB or _G.ArenaCoreDB
    if not db or not db.profiles then
        return {self.DEFAULT_PROFILE_NAME}
    end
    
    local list = {}
    for name, _ in pairs(db.profiles) do
        table.insert(list, name)
    end
    
    -- Sort alphabetically, but keep default first
    table.sort(list, function(a, b)
        if a == self.DEFAULT_PROFILE_NAME then return true end
        if b == self.DEFAULT_PROFILE_NAME then return false end
        return a < b
    end)
    
    return list
end

--- Get current profile name
---@return string
function PM:GetCurrentProfile()
    local db = AC.DB or _G.ArenaCoreDB
    if not db or not db.profileSettings then
        return self.DEFAULT_PROFILE_NAME
    end
    return db.profileSettings.currentProfile or self.DEFAULT_PROFILE_NAME
end

--- Create new profile
---@param name string
---@return boolean success, string|nil error
function PM:CreateProfile(name)
    if not name or name == "" then
        return false, "Profile name cannot be empty"
    end
    
    local db = AC.DB or _G.ArenaCoreDB
    if not db then
        return false, "Database not initialized"
    end
    
    -- Check if profile already exists
    if db.profiles and db.profiles[name] then
        return false, "Profile '" .. name .. "' already exists"
    end
    
    -- Check max profiles limit
    local profileCount = 0
    if db.profiles then
        for _ in pairs(db.profiles) do
            profileCount = profileCount + 1
        end
    end
    
    if profileCount >= self.MAX_PROFILES then
        return false, "Maximum " .. self.MAX_PROFILES .. " profiles reached"
    end
    
    -- Initialize profiles table if needed
    db.profiles = db.profiles or {}
    
    -- Create deep copy of current profile
    if not AC.Serialization then
        return false, "Serialization module not loaded"
    end
    
    db.profiles[name] = AC.Serialization:DeepCopy(db.profile)
    
    print("|cff00FFFFArenaCore:|r Created profile: " .. name)
    return true
end

--- Delete profile
---@param name string
---@return boolean success, string|nil error
function PM:DeleteProfile(name)
    if name == self.DEFAULT_PROFILE_NAME then
        return false, "Cannot delete default profile"
    end
    
    local db = AC.DB or _G.ArenaCoreDB
    if not db or not db.profiles or not db.profiles[name] then
        return false, "Profile not found: " .. name
    end
    
    -- Can't delete currently active profile
    if self:GetCurrentProfile() == name then
        return false, "Cannot delete active profile. Switch to another profile first."
    end
    
    db.profiles[name] = nil
    print("|cff00FFFFArenaCore:|r Deleted profile: " .. name)
    return true
end

--- Rename profile
---@param oldName string
---@param newName string
---@return boolean success, string|nil error
function PM:RenameProfile(oldName, newName)
    if oldName == self.DEFAULT_PROFILE_NAME then
        return false, "Cannot rename default profile"
    end
    
    if not newName or newName == "" then
        return false, "New name cannot be empty"
    end
    
    local db = AC.DB or _G.ArenaCoreDB
    if not db or not db.profiles or not db.profiles[oldName] then
        return false, "Profile not found: " .. oldName
    end
    
    if db.profiles[newName] then
        return false, "Profile '" .. newName .. "' already exists"
    end
    
    -- Rename profile
    db.profiles[newName] = db.profiles[oldName]
    db.profiles[oldName] = nil
    
    -- Update current profile name if this was the active one
    if db.profileSettings and db.profileSettings.currentProfile == oldName then
        db.profileSettings.currentProfile = newName
    end
    
    -- Purple arrow pointing right (using custom asset, 16x16 for better visibility)
    local arrowPath = "Interface\\AddOns\\ArenaCore\\Media\\Textures\\purple-arrow-right.tga"
    local arrow = ("|T%s:16:16:0:-2|t"):format(arrowPath)
    print("|cff00FFFFArenaCore:|r Renamed profile:  " .. arrow .. "  " .. newName)
    return true
end

--- Save current settings to profile
---@param profileName string
---@return boolean success, string|nil error
function PM:SaveCurrentToProfile(profileName)
    local db = AC.DB or _G.ArenaCoreDB
    if not db then
        return false, "Database not initialized"
    end
    
    if not db.profiles or not db.profiles[profileName] then
        return false, "Profile not found: " .. profileName
    end
    
    -- Capture current frame positions before saving
    self:CaptureFramePositions()
    
    -- Deep copy current profile to saved profile
    if not AC.Serialization then
        return false, "Serialization module not loaded"
    end
    
    db.profiles[profileName] = AC.Serialization:DeepCopy(db.profile)
    
    print("|cff00FFFFArenaCore:|r Saved current setup to profile: " .. profileName)
    return true
end

--- Switch to different profile
---@param profileName string
---@return boolean success, string|nil error
function PM:SwitchProfile(profileName)
    local db = AC.DB or _G.ArenaCoreDB
    if not db then
        return false, "Database not initialized"
    end
    
    if not db.profiles or not db.profiles[profileName] then
        return false, "Profile not found: " .. profileName
    end
    
    -- Don't switch if already on this profile
    if self:GetCurrentProfile() == profileName then
        return true
    end
    
    -- Deep copy profile data to current profile
    if not AC.Serialization then
        return false, "Serialization module not loaded"
    end
    
    -- CRITICAL FIX: Auto-save current profile before switching to prevent data loss
    -- This ensures any changes made to the current profile are preserved
    local currentProfileName = self:GetCurrentProfile()
    if currentProfileName and db.profiles and db.profiles[currentProfileName] then
        -- Capture current frame positions before saving
        self:CaptureFramePositions()
        
        -- Save current db.profile to the stored profile
        db.profiles[currentProfileName] = AC.Serialization:DeepCopy(db.profile)
        -- DEBUG DISABLED FOR PRODUCTION
        -- print("|cffFFAA00ArenaCore:|r Auto-saved '" .. currentProfileName .. "' before switching")
    end
    
    db.profile = AC.Serialization:DeepCopy(db.profiles[profileName])
    
    -- Update current profile setting
    db.profileSettings = db.profileSettings or {}
    db.profileSettings.currentProfile = profileName
    
    -- Apply settings
    self:ApplyArenaFramesSettings()
    
    -- Refresh all systems
    if AC.MasterFrameManager and AC.MasterFrameManager.RefreshAllSettings then
        AC.MasterFrameManager:RefreshAllSettings()
    end
    
    if AC.AuraTracker and AC.AuraTracker.RefreshSettings then
        AC.AuraTracker:RefreshSettings()
    end
    
    -- Apply theme from the profile (if it has one, otherwise use default)
    if AC.ThemeManager and AC.ThemeManager.ApplyTheme then
        local themeId = AC.ThemeManager:GetActiveTheme() or "default"
        AC.ThemeManager:ApplyTheme(themeId, true)  -- silent = true to avoid spam
    end
    
    print("|cff00FFFFArenaCore:|r Switched to profile: " .. profileName)
    return true
end

--- Export profile to shareable string
---@param profileName string
---@return string|nil shareCode, string|nil error
function PM:ExportProfile(profileName)
    local db = AC.DB or _G.ArenaCoreDB
    if not db or not db.profiles or not db.profiles[profileName] then
        return nil, "Profile not found: " .. profileName
    end
    
    if not AC.Serialization then
        return nil, "Serialization module not loaded"
    end
    
    -- CRITICAL FIX: Auto-save current settings to profile before exporting
    -- This ensures we export the user's CURRENT settings, not an old snapshot
    self:CaptureFramePositions()
    
    -- DUAL-THEME SYSTEM: Save current theme settings before exporting
    if AC.ArenaFrameThemes and AC.ArenaFrameThemes.SaveCurrentThemeSettings then
        AC.ArenaFrameThemes:SaveCurrentThemeSettings()
    end
    
    db.profiles[profileName] = AC.Serialization:DeepCopy(db.profile)
    
    local profileData = db.profiles[profileName]
    
    -- DUAL-THEME SYSTEM: Include BOTH themes in export
    -- This ensures recipients get the full setup (both ArenaCore Default and The 1500 Special)
    if db.profile.theme then
        profileData.theme = AC.Serialization:DeepCopy(db.profile.theme)
    end
    
    if db.profile.themeData then
        profileData.themeData = AC.Serialization:DeepCopy(db.profile.themeData)
    end
    
    -- Check if compression modules are loaded
    if not AC.Compression then
        -- Fallback to V1 if compression modules not available
        local shareCode, err = AC.Serialization:ExportProfile(profileData)
        return shareCode, err
    end
    
    -- Try new V2 compression first (much smaller codes)
    local shareCode, err = AC.Serialization:ExportProfileV2(profileData)
    
    if not shareCode then
        -- Fallback to V1 if V2 fails
        shareCode, err = AC.Serialization:ExportProfile(profileData)
    end
    
    if not shareCode then
        return nil, err
    end
    
    return shareCode
end

--- Import profile from shareable string
---@param shareCode string
---@param profileName string
---@return boolean success, string|nil error
function PM:ImportProfile(shareCode, profileName)
    if not profileName or profileName == "" then
        return false, "Profile name cannot be empty"
    end
    
    if not AC.Serialization then
        return false, "Serialization module not loaded"
    end
    
    -- Decode profile data (auto-detect V1 or V2)
    local profileData, err = AC.Serialization:ImportProfileAuto(shareCode)
    if not profileData then
        return false, err or "Failed to import profile"
    end
    
    -- Validate profile data
    local valid, validErr = AC.Serialization:ValidateProfile(profileData)
    if not valid then
        return false, validErr or "Invalid profile data"
    end
    
    local db = AC.DB or _G.ArenaCoreDB
    if not db then
        return false, "Database not initialized"
    end
    
    -- Check if profile name already exists
    if db.profiles and db.profiles[profileName] then
        return false, "Profile '" .. profileName .. "' already exists. Please choose a different name."
    end
    
    -- Check max profiles limit
    local profileCount = 0
    if db.profiles then
        for _ in pairs(db.profiles) do
            profileCount = profileCount + 1
        end
    end
    
    if profileCount >= self.MAX_PROFILES then
        return false, "Maximum " .. self.MAX_PROFILES .. " profiles reached"
    end
    
    -- Save imported profile
    db.profiles = db.profiles or {}
    db.profiles[profileName] = profileData
    
    print("|cff00FFFFArenaCore:|r Imported profile: " .. profileName)
    
    -- DUAL-THEME SYSTEM: Show notification about included themes
    local themeCount = 0
    local themeNames = {}
    if profileData.themeData then
        for themeName, _ in pairs(profileData.themeData) do
            themeCount = themeCount + 1
            table.insert(themeNames, themeName)
        end
    end
    
    if themeCount > 0 then
        table.sort(themeNames) -- Alphabetical order
        local themeList = table.concat(themeNames, ", ")
        print("|cff8B45FFArenaCore:|r Profile includes settings for " .. themeCount .. " theme(s): " .. themeList)
    else
        -- Old profile format (pre-theme system) - will only apply to active theme
        print("|cffFFAA00ArenaCore:|r This is an older profile (pre-theme system). Settings will apply to current theme only.")
    end
    
    -- CRITICAL TAINT FIX: Delay profile switch to avoid protected state errors
    -- Importing during addon loading can trigger ADDON_ACTION_BLOCKED
    -- Small delay ensures we're out of protected state before manipulating frames
    C_Timer.After(0.5, function()
        if not InCombatLockdown() then
            -- CRITICAL FIX: Automatically switch to the imported profile
            -- Without this, the imported profile just sits in storage unused and frames break
            local switchSuccess, switchErr = self:SwitchProfile(profileName)
            if not switchSuccess then
                print("|cffFFAA00ArenaCore:|r WARNING: Profile imported but failed to activate: " .. (switchErr or "unknown error"))
                print("|cffFFAA00ArenaCore:|r You can manually switch to it in More Features > Profiles")
            else
                print("|cff8B45FFArenaCore:|r Profile '" .. profileName .. "' imported and activated successfully!")
                
                -- DUAL-THEME SYSTEM: Show active theme after import
                if profileData.theme and profileData.theme.active then
                    print("|cff8B45FFArenaCore:|r Active theme set to: " .. profileData.theme.active)
                end
            end
        else
            print("|cffFFAA00ArenaCore:|r Profile imported but cannot activate during combat. Switch manually in More Features > Profiles")
        end
    end)
    
    return true
end

-- Debug test function
function PM:TestPlayerNameDebug()
    -- Test current database values
    local currentDB = _G.ArenaCoreDB
    if currentDB and currentDB.profile and currentDB.profile.arenaFrames and currentDB.profile.arenaFrames.general then
        print("|cff00FF00Player Name Debug:|r Current DB X/Y: " .. 
              tostring(currentDB.profile.arenaFrames.general.playerNameX) .. " / " ..
              tostring(currentDB.profile.arenaFrames.general.playerNameY))
    else
        print("|cffFF0000Player Name Debug:|r No current DB values found!")
    end
end

-- Make it globally accessible for testing
_G.TestPlayerNameDebug = function() AC.ProfileManager:TestPlayerNameDebug() end

-- ============================================================================
-- PROFILE EDIT MODE - Buffer Management Functions
-- ============================================================================

--- Commit all buffered changes to the current profile
function PM:CommitTempBuffer()
    if not AC.tempProfileBuffer or next(AC.tempProfileBuffer) == nil then
        print("|cffFFAA00ArenaCore:|r No changes to save")
        return
    end
    
    local changeCount = 0
    for _ in pairs(AC.tempProfileBuffer) do
        changeCount = changeCount + 1
    end
    
    -- DEBUG DISABLED FOR PRODUCTION
    -- print("|cff22AA44ArenaCore:|r Saving " .. changeCount .. " buffered changes to current profile...")
    
    -- Apply all buffered changes to database
    for path, value in pairs(AC.tempProfileBuffer) do
        -- Call SetSetting with skipApply=true to avoid multiple refreshes
        -- Temporarily disable edit mode flag so SetSetting writes to database
        local wasEditMode = AC.profileEditModeActive
        AC.profileEditModeActive = false
        self:SetSetting(path, value, true)
        AC.profileEditModeActive = wasEditMode
    end
    
    -- CRITICAL FIX: Capture dragged frame positions from Edit Mode BEFORE clearing buffer
    -- This saves the visual positions that the user dragged to
    self:CaptureFramePositions()
    
    -- CRITICAL FIX: Save captured positions to current theme data
    -- Without this, positions are saved to profile but NOT to theme
    -- When you /reload or Hide/Test, LoadThemeSettings() loads old theme data and overwrites the new positions
    if AC.ArenaFrameThemes and AC.ArenaFrameThemes.SaveCurrentThemeSettings then
        AC.ArenaFrameThemes:SaveCurrentThemeSettings()
        print("|cff00FF00[PROFILE MANAGER]|r Saved positions to current theme")
    end
    
    -- Clear temp buffer and snapshot
    AC.tempProfileBuffer = {}
    AC.profileSnapshot = nil
    
    -- NOTE: Slider sync handled by page refresh below (lines 1169-1175)
    -- Manual sync was causing "unsaved changes" detection issues
    
    -- CRITICAL FIX: Set flag BEFORE timer to prevent any repositioning during save
    -- Frames are already visually positioned correctly from Edit Mode drag
    -- Repositioning them causes a jump due to timing/rounding differences
    AC._skipRepositionOnRefresh = true
    print("|cff00FF00[PROFILE MANAGER]|r Skip flag SET to TRUE - repositioning disabled")
    
    -- CRITICAL FIX: Add small delay before refresh to ensure all database writes complete
    -- This prevents race condition where some elements refresh before all positions are saved
    -- Without this delay, trinkets/racials can jump to wrong positions when multiple elements are dragged
    C_Timer.After(0.05, function()
        -- Single comprehensive refresh after all changes applied
        self:ApplyArenaFramesSettings()
        
        -- CRITICAL FIX: Restore Edit Mode glow overlays after refresh
        -- ApplyArenaFramesSettings can cause glow to disappear on some frames
        -- This ensures all draggable elements maintain their blue overlay
        -- INCREASED DELAY: 0.1s to ensure this runs AFTER all other refresh operations
        if AC.EditMode and AC.EditMode.isActive then
            C_Timer.After(0.1, function()
                -- Restore glow for all registered draggable frames
                if AC.EditMode.registeredFrames then
                    for groupName, frames in pairs(AC.EditMode.registeredFrames) do
                        for idx, frame in ipairs(frames) do
                            if frame.editModeGlow then frame.editModeGlow:Show() end
                            if frame.editModeGlowFrame then frame.editModeGlowFrame:Show() end
                            if frame.editModeGlowBorders then
                                for _, border in ipairs(frame.editModeGlowBorders) do
                                    border:Show()
                                end
                            end
                        end
                    end
                end
            end)
        end
        
        -- CRITICAL FIX: Refresh the current page to update slider UI values
        -- Without this, sliders show old values and jump on first interaction
        if AC.currentPage and AC.ShowPage then
            C_Timer.After(0.1, function()
                AC:ShowPage(AC.currentPage)
            end)
        end
        
        -- CRITICAL: Do NOT clear the skip flag here!
        -- The flag will be cleared when Edit Mode is disabled (EditMode.lua line 1422)
        -- This ensures the flag stays set for the ENTIRE duration of the save operation
        print("|cffFFAA00[PROFILE MANAGER]|r Skip flag will remain TRUE until Edit Mode is disabled")
        
        -- DEBUG DISABLED FOR PRODUCTION
        -- print("|cff22AA44ArenaCore:|r Changes saved to current profile successfully!")
    end)
end

--- Discard all buffered changes without saving
function PM:DiscardTempBuffer()
    if not AC.tempProfileBuffer or next(AC.tempProfileBuffer) == nil then
        return
    end
    
    local changeCount = 0
    for _ in pairs(AC.tempProfileBuffer) do
        changeCount = changeCount + 1
    end
    
    -- CRITICAL: Restore original values from snapshot to revert ALL visual changes
    -- This makes sliders, checkboxes, frames, and all visual elements snap back to saved state
    local currentDB = _G.ArenaCoreDB
    if currentDB and AC.profileSnapshot then
        for path, _ in pairs(AC.tempProfileBuffer) do
            -- Get the original value from the snapshot (taken when Edit Mode started)
            local keys = {strsplit(".", path)}
            local originalValue = AC.profileSnapshot
            
            for _, key in ipairs(keys) do
                if originalValue and originalValue[key] ~= nil then
                    originalValue = originalValue[key]
                else
                    originalValue = nil
                    break
                end
            end
            
            -- Restore the original value to the current profile
            -- This reverts the visual change that was applied in real-time
            if originalValue ~= nil then
                local current = currentDB.profile
                for i = 1, #keys - 1 do
                    if not current[keys[i]] then
                        current[keys[i]] = {}
                    end
                    current = current[keys[i]]
                end
                current[keys[#keys]] = originalValue
            end
        end
    end
    
    -- Clear temp buffer and snapshot
    AC.tempProfileBuffer = {}
    AC.profileSnapshot = nil
    
    -- CRITICAL: Force complete refresh to show reverted values
    -- This updates all visual elements (frames, sliders, checkboxes, etc.)
    self:ApplyArenaFramesSettings()
    
    print("|cffFFAA00ArenaCore:|r Discarded " .. changeCount .. " unsaved changes")
end

--- Refresh UI checkboxes after Edit Mode is disabled
--- Called from EditMode:Disable() after profileEditModeActive is set to false
function PM:RefreshMoreFeaturesCheckboxes()
    -- Use CheckboxTracker to update all tracked checkboxes
    -- This updates the visual state without rebuilding pages
    if AC.CheckboxTracker then
        AC.CheckboxTracker:UpdateAll()
    end
end

--- Check if there are unsaved changes in the temp buffer
---@return boolean
function PM:HasUnsavedChanges()
    return AC.tempProfileBuffer and next(AC.tempProfileBuffer) ~= nil
end

--- Get count of unsaved changes
---@return number
function PM:GetUnsavedChangeCount()
    if not AC.tempProfileBuffer then return 0 end
    local count = 0
    for _ in pairs(AC.tempProfileBuffer) do
        count = count + 1
    end
    return count
end
