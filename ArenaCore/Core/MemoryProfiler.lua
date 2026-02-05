-- ArenaCore Memory Profiler
-- Use /acmemory to see what's using memory

local AC = _G.ArenaCore
if not AC then return end

local function FormatBytes(bytes)
    if bytes > 1024*1024 then
        return string.format("%.2f MB", bytes / (1024*1024))
    elseif bytes > 1024 then
        return string.format("%.2f KB", bytes / 1024)
    else
        return string.format("%d bytes", bytes)
    end
end

local function CountTableSize(tbl, name, depth)
    depth = depth or 0
    if depth > 3 then return 0 end -- Prevent infinite recursion
    if type(tbl) ~= "table" then return 0 end
    
    local count = 0
    for k, v in pairs(tbl) do
        count = count + 1
        if type(v) == "table" and depth < 3 then
            count = count + CountTableSize(v, name, depth + 1)
        end
    end
    return count
end

local function ProfileMemory()
    UpdateAddOnMemoryUsage()
    local total = GetAddOnMemoryUsage("ArenaCore")
    
    print("|cff8B45FF=== ArenaCore Memory Profile ===|r")
    print(string.format("Total: %s", FormatBytes(total * 1024)))
    print("")
    
    -- Profile major AC tables
    local profiles = {
        {"AC.DB", AC.DB},
        {"AC.ClassSpellDB", AC.ClassSpellDB},
        {"AC.AuraTracker", AC.AuraTracker},
        {"AC.MasterFrameManager", AC.MasterFrameManager},
        {"AC.FrameManager", AC.FrameManager},
        {"AC.arenaFrames", AC.arenaFrames},
        {"AC.Themes", AC.Themes},
        {"AC.MoreFeatures", AC.MoreFeatures},
        {"AC.ProfileManager", AC.ProfileManager},
        {"AC.SettingsBackup", AC.SettingsBackup},
        {"AC.Editor", AC.Editor},
        {"AC.BlackoutEditor", AC.BlackoutEditor},
        {"AC.EditMode", AC.EditMode},
        {"AC.ImmunityTracker", AC.ImmunityTracker},
        {"AC.FeignDeathDetector", AC.FeignDeathDetector},
        {"AC.ThemeManager", AC.ThemeManager},
        {"AC.IconStyling", AC.IconStyling},
        {"AC.TooltipIDs", AC.TooltipIDs},
        {"AC.ClassPortraitSwap", AC.ClassPortraitSwap},
        {"AC.BlizzFrameHider", AC.BlizzFrameHider},
        {"AC.PartyClassIndicators", AC.EmergencyCleanupClassIcons and "loaded" or nil},
        -- STAGE 2: REMOVED AC._stealthTimers
        {"AC._eventListeners", AC._eventListeners},
    }
    
    print("|cffFFAA00Module Sizes:|r")
    for _, profile in ipairs(profiles) do
        local name, tbl = profile[1], profile[2]
        if tbl then
            local size = CountTableSize(tbl, name)
            if size > 0 then
                print(string.format("  %s: %d entries", name, size))
            end
        end
    end
    
    -- DEEP DIVE: Show what's in AC.DB
    if AC.DB and AC.DB.profile then
        print("")
        print("|cffFF6B6B=== AC.DB.profile Breakdown ===|r")
        for key, value in pairs(AC.DB.profile) do
            local size = CountTableSize(value, key)
            if size > 10 then -- Only show tables with more than 10 entries
                print(string.format("  AC.DB.profile.%s: %d entries", key, size))
            end
        end
    end
    
    -- CRITICAL TEST: Check if ClassPacks is actually in memory or just on disk
    print("")
    print("|cffFFFF00=== Memory vs Disk Test ===|r")
    if AC.ClassPacks then
        local classPacksSize = CountTableSize(AC.ClassPacks, "AC.ClassPacks")
        print(string.format("  AC.ClassPacks (in-memory): %d entries", classPacksSize))
    else
        print("  AC.ClassPacks: NOT loaded in memory")
    end
    
    if _G.ArenaCoreDB and _G.ArenaCoreDB.profile and _G.ArenaCoreDB.profile.classPacks then
        local dbSize = CountTableSize(_G.ArenaCoreDB.profile.classPacks, "SavedVariables")
        print(string.format("  SavedVariables classPacks: %d entries", dbSize))
    end
    
    print("")
    print("|cffFFAA00Garbage Collection:|r")
    local before = collectgarbage("count")
    collectgarbage("collect")
    local after = collectgarbage("count")
    local freed = before - after
    print(string.format("  Before GC: %.2f KB", before))
    print(string.format("  After GC: %.2f KB", after))
    print(string.format("  Freed: %.2f KB", freed))
    
    print("")
    print("|cff00FF00Use '/acmemory clear' to force garbage collection|r")
end

-- Slash command
SLASH_ACMEMORY1 = "/acmemory"
SlashCmdList.ACMEMORY = function(msg)
    if msg == "clear" or msg == "gc" then
        local before = collectgarbage("count")
        collectgarbage("collect")
        local after = collectgarbage("count")
        local freed = before - after
        print(string.format("|cff8B45FFArenaCore:|r Garbage collected %.2f KB", freed))
        UpdateAddOnMemoryUsage()
        local total = GetAddOnMemoryUsage("ArenaCore")
        print(string.format("|cff8B45FFArenaCore:|r Current memory: %s", FormatBytes(total * 1024)))
    elseif msg == "auto" then
        -- Enable aggressive garbage collection
        print("|cff8B45FFArenaCore:|r Enabling aggressive garbage collection...")
        collectgarbage("setpause", 100)  -- Run GC more frequently
        collectgarbage("setstepmul", 200) -- Run GC more aggressively
        collectgarbage("collect")
        UpdateAddOnMemoryUsage()
        local total = GetAddOnMemoryUsage("ArenaCore")
        print(string.format("|cff8B45FFArenaCore:|r Memory after aggressive GC: %s", FormatBytes(total * 1024)))
    else
        ProfileMemory()
    end
end

-- Disabled startup message for end users
-- print("|cff8B45FFArenaCore:|r Memory profiler loaded. Use |cffffff00/acmemory|r to profile memory usage.")
