-- Core/SettingsBackup.lua --
-- Emergency settings backup and restore system for ArenaCore
-- This prevents settings loss and allows easy recovery

local AC = _G.ArenaCore
if not AC then return end

AC.SettingsBackup = {}
local SB = AC.SettingsBackup

-- ============================================================================
-- EMERGENCY BACKUP SYSTEM
-- ============================================================================

-- Create a COMPLETE backup of ALL current settings using FRAMES as source of truth
function SB:CreateBackup(backupName)
    backupName = backupName or ("Backup_" .. date("%Y%m%d_%H%M%S"))
    
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.profile then
        print("|cffFF0000ArenaCore Backup ERROR:|r No profile data found!")
        return false
    end
    
    -- Initialize backups table
    if not _G.ArenaCoreDB.backups then
        _G.ArenaCoreDB.backups = {}
    end
    
    -- FRAME-CENTRIC BACKUP: Capture current frame positions as source of truth
    if AC then
        -- Capturing Arena Frames settings from actual frames
        
        -- Arena Frames positioning from actual frame positions
        if _G.ArenaFramesAnchor then
            local point, relativeTo, relativePoint, xOfs, yOfs = _G.ArenaFramesAnchor:GetPoint()
            if xOfs and yOfs then
                AC:SetPath(AC.DB.profile, "arenaFrames.positioning.horizontal", math.floor(xOfs + 0.5))
                AC:SetPath(AC.DB.profile, "arenaFrames.positioning.vertical", math.floor(yOfs + 0.5))
                -- Arena frame position backed up
            end
        end
        
        if AC.DB and AC.DB.profile and AC.DB.profile.arenaFrames then
            local af = AC.DB.profile.arenaFrames
            
            -- General settings
            if af.general then
                -- General settings backed up successfully
            end
            
            -- Positioning settings
            if af.positioning then
                -- Positioning settings backed up successfully
            end
            
            -- Sizing settings
            if af.sizing then
                -- Sizing settings backed up successfully
            end
        end
        
        -- DISABLED: Cast bar position capture - causes issues by overwriting manual settings
        -- The backup system should preserve database values, not read from frames
        -- Cast bars positioning is handled by the main settings system
        --[[
        if AC.arenaFrames then
            for i = 1, 3 do
                if AC.arenaFrames[i] and AC.arenaFrames[i].castBar then
                    local cb = AC.arenaFrames[i].castBar
                    if cb:GetPoint() then
                        local cbPoint, cbRelativeTo, cbRelativePoint, cbX, cbY = cb:GetPoint()
                        if cbX and cbY then
                            AC:SetPath(AC.DB.profile, "castBars.positioning.horizontal", math.floor(cbX + 0.5))
                            AC:SetPath(AC.DB.profile, "castBars.positioning.vertical", math.floor(cbY + 0.5))
                            -- Debug message removed
                            break
                        end
                    end
                end
            end
        end
        --]]
        
        -- DISABLED: DR position capture - causes issues by overwriting manual settings
        -- The backup system should preserve database values, not read from frames
        -- DR positioning is handled by the main settings system
        --[[
        if AC.arenaFrames then
            for i = 1, 3 do
                if AC.arenaFrames[i] and AC.arenaFrames[i].drContainer then
                    local drContainer = AC.arenaFrames[i].drContainer
                    if drContainer:GetPoint() then
                        local drPoint, drRelativeTo, drRelativePoint, drX, drY = drContainer:GetPoint()
                        if drX and drY then
                            AC:SetPath(AC.DB.profile, "diminishingReturns.positioning.horizontal", math.floor(drX + 0.5))
                            AC:SetPath(AC.DB.profile, "diminishingReturns.positioning.vertical", math.floor(drY + 0.5))
                            -- Debug message removed
                            break
                        end
                    end
                end
            end
        end
        --]]
        
        -- Trinket/Racial positioning from actual positions
        if AC.arenaFrames then
            for i = 1, 3 do
                if AC.arenaFrames[i] and AC.arenaFrames[i].trinketContainer then
                    local trinketContainer = AC.arenaFrames[i].trinketContainer
                    if trinketContainer:GetPoint() then
                        local tPoint, tRelativeTo, tRelativePoint, tX, tY = trinketContainer:GetPoint()
                        if tX and tY then
                            AC:SetPath(AC.DB.profile, "trinketsOther.trinkets.vertical", math.floor(tY + 0.5))
                            AC:SetPath(AC.DB.profile, "trinketsOther.trinkets.horizontal", math.floor(tX + 0.5))
                            print("|cffFFAA00BACKUP:|r Captured trinket position: " .. math.floor(tX + 0.5) .. ", " .. math.floor(tY + 0.5))
                            break
                        end
                    end
                end
            end
        end
        
        -- Force SavedVariables sync
        _G.ArenaCoreDB = AC.DB
    end
    
    -- Create deep copy of COMPLETE profile (now with frame-accurate positions)
    local function DeepCopy(tbl)
        if type(tbl) ~= "table" then return tbl end
        local copy = {}
        for k, v in pairs(tbl) do
            copy[k] = DeepCopy(v)
        end
        return copy
    end
    
    _G.ArenaCoreDB.backups[backupName] = {
        profile = DeepCopy(_G.ArenaCoreDB.profile),
        timestamp = time(),
        dateString = date("%Y-%m-%d %H:%M:%S"),
        framePositions = true -- Mark this as a frame-accurate backup
    }
    
    -- Only show backup message for manual backups (not auto-saves)
    if not backupName:match("^AutoSave_") and not backupName:match("^AutoBackup_") then
        print("|cff22AA44ArenaCore:|r Settings backup created: '" .. backupName .. "'")
    end
    return true
end

-- Restore from a backup
function SB:RestoreBackup(backupName)
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.backups then
        print("|cffFF0000ArenaCore Restore ERROR:|r No backups found!")
        return false
    end
    
    local backup = _G.ArenaCoreDB.backups[backupName]
    if not backup then
        print("|cffFF0000ArenaCore Restore ERROR:|r Backup '" .. backupName .. "' not found!")
        self:ListBackups()
        return false
    end
    
    -- Deep copy backup data back to profile
    local function DeepCopy(tbl)
        if type(tbl) ~= "table" then return tbl end
        local copy = {}
        for k, v in pairs(tbl) do
            copy[k] = DeepCopy(v)
        end
        return copy
    end
    
    _G.ArenaCoreDB.profile = DeepCopy(backup.profile)
    
    -- Update AC.DB reference to point to restored data
    if AC and AC.DB and AC.DB.profile then
        AC.DB.profile = _G.ArenaCoreDB.profile
    end
    
    print("|cff22AA44ArenaCore:|r Settings restored from '" .. backupName .. "' (" .. backup.dateString .. ")")
    
    -- Apply COMPLETE settings restore with REAL-TIME VISUAL SYNC
    C_Timer.After(0.1, function()
        if AC and AC.DB and AC.DB.profile then
            -- STEP 1: Restore frame positions
            if AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.positioning then
                local positioning = AC.DB.profile.arenaFrames.positioning
                local savedX = positioning.horizontal
                local savedY = positioning.vertical
                
                if savedX and savedY then
                    local anchor = _G.ArenaFramesAnchor or (AC and AC.ArenaFramesAnchor)
                    if anchor then
                        anchor:ClearAllPoints()
                        anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", savedX, savedY)
                        anchor:Show()
                        
                        if AC and AC.config then
                            AC.config.position = AC.config.position or {}
                            AC.config.position.x = savedX
                            AC.config.position.y = savedY
                        end
                    end
                end
            end
            
            -- OLD FRAME POSITIONING COMPLETELY DISABLED - New unified system handles this
            -- Old frame positioning disabled - using new unified system
            --[[
            -- Force individual arena frames to follow the moved anchor
            if AC and AC.arenaFrames then
                for i = 1, 3 do
                    if AC.arenaFrames[i] then
                        AC.arenaFrames[i]:ClearAllPoints()
                        local growthDir = (AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.positioning and AC.DB.profile.arenaFrames.positioning.growthDirection) or "Down"
                        local spacing = (AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.positioning and AC.DB.profile.arenaFrames.positioning.spacing) or 12
                        local frameHeight = (AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.sizing and AC.DB.profile.arenaFrames.sizing.height) or 68
                        local frameWidth = (AC.DB.profile.arenaFrames and AC.DB.profile.arenaFrames.sizing and AC.DB.profile.arenaFrames.sizing.width) or 235
                        
                        local yOffset = 0
                        local xOffset = 0
                        
                        if i > 1 then
                            if growthDir == "Up" then 
                                yOffset = (i - 1) * (frameHeight + spacing)
                            elseif growthDir == "Right" then 
                                xOffset = (i - 1) * (frameWidth + spacing)
                            elseif growthDir == "Left" then 
                                xOffset = -(i - 1) * (frameWidth + spacing)
                            else -- "Down" 
                                yOffset = -(i - 1) * (frameHeight + spacing)
                            end
                        end
                        
                        -- OLD POSITIONING SYSTEM DISABLED - New unified system handles frame positioning
                        -- Old positioning system disabled - using new unified system
                        -- local anchor = _G.ArenaFramesAnchor or (AC and AC.ArenaFramesAnchor)
                        -- if anchor then
                        --     AC.arenaFrames[i]:SetPoint("TOPLEFT", anchor, "TOPLEFT", xOffset, yOffset)
                        --     AC.arenaFrames[i]:Show()
                        --     AC.arenaFrames[i]:SetAlpha(1.0)
                        -- end
                    end
                end
            end
            --]]
            
            -- STEP 2: Apply ALL visual changes based on restored settings
            SB:ApplyVisualChanges()
        end
        
        -- STEP 3: Force UI controls to update to match restored settings
        C_Timer.After(0.2, function()
            SB:RefreshAllUIControls()
            print("|cff22AA44ArenaCore:|r COMPLETE settings restored! All frames, visuals, and UI controls updated.")
        end)
    end)
    
    return true
end

-- Restore the most recent backup
function SB:RestoreLatest()
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.backups then
        print("|cffFF0000ArenaCore Restore ERROR:|r No backups found!")
        return false
    end
    
    -- Find most recent backup
    local latestName = nil
    local latestTime = 0
    
    for name, backup in pairs(_G.ArenaCoreDB.backups) do
        if backup.timestamp and backup.timestamp > latestTime then
            latestTime = backup.timestamp
            latestName = name
        end
    end
    
    if not latestName then
        print("|cffFF0000ArenaCore Restore ERROR:|r No valid backups found!")
        return false
    end
    
    print("|cff22AA44ArenaCore:|r Restoring most recent backup: " .. latestName)
    return self:RestoreBackup(latestName)
end

-- List all available backups
function SB:ListBackups()
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.backups then
        print("|cffFFAA00ArenaCore:|r No backups found.")
        return
    end
    
    print("|cff8B45FFArenaCore Available Backups:|r")
    local count = 0
    for name, backup in pairs(_G.ArenaCoreDB.backups) do
        count = count + 1
        print(string.format("  %d. %s (%s)", count, name, backup.dateString))
    end
    
    if count == 0 then
        print("|cffFFAA00ArenaCore:|r No backups found.")
    else
        print("|cffFFFFFFUse:|r /ac_restore <backup_name>")
    end
end

-- Auto-backup on significant changes
function SB:AutoBackup()
    -- Only create auto-backup if we have meaningful settings
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.profile then
        return
    end
    
    -- Check if we have arena frames settings (indicates user has configured)
    local profile = _G.ArenaCoreDB.profile
    if profile.arenaFrames and profile.arenaFrames.positioning then
        local autoBackupName = "AutoBackup_" .. date("%Y%m%d_%H%M")
        
        -- Only create if we don't already have a recent auto-backup
        if not _G.ArenaCoreDB.backups or not _G.ArenaCoreDB.backups[autoBackupName] then
            self:CreateBackup(autoBackupName)
        end
    end
end

-- Export settings as text for manual backup
function SB:ExportSettings()
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.profile then
        print("|cffFF0000ArenaCore Export ERROR:|r No profile data found!")
        return
    end
    
    -- Serialize table to string
    local function TableToString(tbl, indent)
        indent = indent or 0
        local spaces = string.rep("  ", indent)
        local result = "{\n"
        
        for k, v in pairs(tbl) do
            local key = type(k) == "string" and k or "[" .. tostring(k) .. "]"
            result = result .. spaces .. "  " .. key .. " = "
            
            if type(v) == "table" then
                result = result .. TableToString(v, indent + 1)
            elseif type(v) == "string" then
                result = result .. '"' .. v .. '"'
            else
                result = result .. tostring(v)
            end
            result = result .. ",\n"
        end
        
        result = result .. spaces .. "}"
        return result
    end
    
    local exportString = "-- ArenaCore Settings Export --\n"
    exportString = exportString .. "-- Generated: " .. date("%Y-%m-%d %H:%M:%S") .. "\n\n"
    exportString = exportString .. "local settings = " .. TableToString(_G.ArenaCoreDB.profile) .. "\n\n"
    exportString = exportString .. "-- To restore: copy this to a .lua file and load it"
    
    -- Show export window
    if AC.ShowExportWindow then
        AC:ShowExportWindow(exportString)
    else
        print("|cff22AA44ArenaCore:|r Settings exported to chat (scroll up)")
        print(exportString)
    end
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

-- /ac_backup [name] - Create backup
SLASH_AC_BACKUP1 = "/ac_backup"
SlashCmdList.AC_BACKUP = function(msg)
    local backupName = msg and msg:trim() ~= "" and msg:trim() or nil
    SB:CreateBackup(backupName)
end

-- /ac_restore <name> - Restore backup
SLASH_AC_RESTORE1 = "/ac_restore"
SlashCmdList.AC_RESTORE = function(msg)
    local backupName = msg and msg:trim()
    if not backupName or backupName == "" then
        print("|cffFFAA00ArenaCore:|r Usage: /ac_restore <backup_name>")
        SB:ListBackups()
        return
    end
    SB:RestoreBackup(backupName)
end

-- /ac_backups - List all backups
SLASH_AC_BACKUPS1 = "/ac_backups"
SlashCmdList.AC_BACKUPS = function()
    SB:ListBackups()
end

-- /ac_export - Export settings as text
SLASH_AC_EXPORT1 = "/ac_export"
SlashCmdList.AC_EXPORT = function()
    SB:ExportSettings()
end

-- /ac_test - Test settings persistence
SLASH_AC_TEST1 = "/ac_test"
SlashCmdList.AC_TEST = function()
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.profile then
        print("|cffFF0000ArenaCore Test:|r No database found!")
        return
    end
    
    print("|cff8B45FFArenaCore Settings Test:|r")
    print("Change Counter:", _G.ArenaCoreDB.changeCounter or "none")
    print("Last Change:", _G.ArenaCoreDB.lastChange and date("%H:%M:%S", _G.ArenaCoreDB.lastChange) or "none")
    print("Last Changed Path:", _G.ArenaCoreDB.lastChangedPath or "none")
    
    -- Test arena frames settings
    local af = _G.ArenaCoreDB.profile.arenaFrames
    if af then
        print("|cff22AA44Arena Frames Settings:|r")
        if af.positioning then
            print("  Position: x=" .. (af.positioning.horizontal or "nil") .. ", y=" .. (af.positioning.vertical or "nil"))
        end
        if af.sizing then
            print("  Size: scale=" .. (af.sizing.scale or "nil") .. ", w=" .. (af.sizing.width or "nil") .. ", h=" .. (af.sizing.height or "nil"))
        end
    else
        print("|cffFF0000Arena Frames:|r No settings found!")
    end
end

-- ============================================================================
-- AUTO-INITIALIZATION
-- ============================================================================

-- Auto-backup when addon loads (if user has settings)
local backupFrame = CreateFrame("Frame")
backupFrame:RegisterEvent("PLAYER_LOGIN")
backupFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(3, function()  -- Wait for everything to load
            SB:AutoBackup()
        end)
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- ============================================================================
-- VISUAL SYNC SYSTEM
-- ============================================================================

-- Apply ARENA FRAMES visual changes based on current database settings
function SB:ApplyVisualChanges()
    if not AC or not AC.DB or not AC.DB.profile then return end
    
    local profile = AC.DB.profile
    
    -- ARENA FRAMES COMPLETE VISUAL SYNC
    if profile.arenaFrames then
        local general = profile.arenaFrames.general or {}
        
        print("|cffFFAA00VISUAL SYNC:|r Applying Arena Frames visual changes...")
        
        -- Update arena frames based on restored settings
        if AC.arenaFrames then
            for i = 1, 3 do
                if AC.arenaFrames[i] then
                    local frame = AC.arenaFrames[i]
                    
                    -- Show/Hide Names
                    if frame.playerName then
                        if general.showNames then
                            frame.playerName:Show()
                            print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Names shown")
                        else
                            frame.playerName:Hide()
                            print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Names hidden")
                        end
                    end
                    
                    -- Show/Hide Arena Numbers
                    if frame.arenaNumber then
                        if general.showArenaNumbers then
                            frame.arenaNumber:Show()
                            print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Arena numbers shown")
                        else
                            frame.arenaNumber:Hide()
                            print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Arena numbers hidden")
                        end
                    end
                    
                    -- Status Text Updates
                    if frame.healthText and general.statusText then
                        if general.statusText.enabled then
                            frame.healthText:Show()
                            print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Status text enabled")
                            
                            -- Update percentage vs absolute values
                            if general.statusText.usePercentage then
                                print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Using percentage display")
                                -- Force percentage display in test mode
                                if AC.testModeEnabled then
                                    frame.healthText:SetText("85%")
                                end
                            else
                                print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Using absolute values")
                                if AC.testModeEnabled then
                                    frame.healthText:SetText("34250")
                                end
                            end
                        else
                            frame.healthText:Hide()
                            print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Status text disabled")
                        end
                    end
                    
                    -- Update text scaling
                    if frame.playerName and general.playerNameScale then
                        local scale = general.playerNameScale / 100
                        frame.playerName:SetScale(scale)
                        print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Player name scale: " .. scale)
                    end
                    
                    if frame.arenaNumber and general.arenaNumberScale then
                        local scale = general.arenaNumberScale / 100
                        frame.arenaNumber:SetScale(scale)
                        print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Arena number scale: " .. scale)
                    end
                    
                    if frame.healthText and general.healthTextScale then
                        local scale = general.healthTextScale / 100
                        frame.healthText:SetScale(scale)
                        print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Health text scale: " .. scale)
                    end
                    
                    if frame.resourceText and general.resourceTextScale then
                        local scale = general.resourceTextScale / 100
                        frame.resourceText:SetScale(scale)
                        print("|cffFFAA00VISUAL SYNC:|r Frame " .. i .. " - Resource text scale: " .. scale)
                    end
                end
            end
        end
        
        -- Update frame positioning and sizing
        if profile.arenaFrames.positioning then
            local pos = profile.arenaFrames.positioning
            -- DEBUG: Positioning sync
            -- print("|cffFFAA00VISUAL SYNC:|r Positioning - X: " .. (pos.horizontal or "nil") .. ", Y: " .. (pos.vertical or "nil") .. ", Spacing: " .. (pos.spacing or "nil"))
        end
    end
    
    -- DEBUG: Visual elements updated
    -- print("|cffFFAA00ArenaCore:|r Arena Frames visual elements updated!")
end

-- Refresh Arena Frames UI controls to match current database settings
function SB:RefreshAllUIControls()
    if not AC or not AC.ShowPage or not AC.IsUIVisible then return end
    
    print("|cffFFAA00UI REFRESH:|r Refreshing Arena Frames UI controls...")
    
    -- Force complete UI refresh by re-showing Arena Frames page
    if AC.currentPage == "ArenaFrames" then
        -- Small delay to ensure database is fully synced
        C_Timer.After(0.1, function()
            print("|cffFFAA00UI REFRESH:|r Re-showing Arena Frames page to sync controls...")
            AC:ShowPage("ArenaFrames")
            print("|cffFFAA00ArenaCore:|r Arena Frames UI controls refreshed!")
        end)
    else
        print("|cffFFAA00UI REFRESH:|r Not on Arena Frames page, skipping UI refresh")
    end
end

-- DEBUG: Backup system loaded (obsolete - auto-save enabled)
-- print("|cff8B45FFArenaCore Backup System:|r Loaded. Use /ac_backup, /ac_restore, /ac_backups, /ac_export")
