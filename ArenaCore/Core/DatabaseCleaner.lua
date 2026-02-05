-- ArenaCore Database Cleaner
-- Optimizes SavedVariables to prevent infinite growth

local AC = _G.ArenaCore
if not AC then return end

local Cleaner = {}
AC.DatabaseCleaner = Cleaner

-- Configuration
local MAX_BACKUPS = 5  -- Keep only last 5 backups
local MAX_CUSTOM_SPELLS_PER_CATEGORY = 20  -- Limit custom DR spells per category

-- Optimize ClassPacks by removing empty/default entries
function Cleaner:OptimizeClassPacks()
    if not AC.DB or not AC.DB.profile or not AC.DB.profile.classPacks then
        return 0
    end
    
    local removed = 0
    local classPacks = AC.DB.profile.classPacks
    
    -- Remove empty class tables
    for className, classData in pairs(classPacks) do
        if type(classData) == "table" then
            -- Remove empty spec tables
            for specIndex, specData in pairs(classData) do
                if type(specData) == "table" then
                    local isEmpty = true
                    
                    -- Check if spec has any actual data
                    for slot, spells in pairs(specData) do
                        if type(spells) == "table" and #spells > 0 then
                            isEmpty = false
                            break
                        end
                    end
                    
                    -- Remove empty spec
                    if isEmpty then
                        classData[specIndex] = nil
                        removed = removed + 1
                    end
                end
            end
            
            -- Remove empty class
            local hasSpecs = false
            for _ in pairs(classData) do
                hasSpecs = true
                break
            end
            
            if not hasSpecs then
                classPacks[className] = nil
                removed = removed + 1
            end
        end
    end
    
    return removed
end

-- Limit backups to prevent infinite growth
function Cleaner:LimitBackups()
    if not AC.DB or not AC.DB.backups then
        return 0
    end
    
    local backups = AC.DB.backups
    local backupList = {}
    
    -- Build list of backups with timestamps
    for name, backup in pairs(backups) do
        table.insert(backupList, {name = name, timestamp = backup.timestamp or 0})
    end
    
    -- Sort by timestamp (newest first)
    table.sort(backupList, function(a, b) return a.timestamp > b.timestamp end)
    
    -- Remove old backups beyond MAX_BACKUPS
    local removed = 0
    for i = MAX_BACKUPS + 1, #backupList do
        backups[backupList[i].name] = nil
        removed = removed + 1
    end
    
    return removed
end

-- Limit custom DR spells per category
function Cleaner:LimitCustomDRSpells()
    if not AC.DB or not AC.DB.profile or not AC.DB.profile.diminishingReturns then
        return 0
    end
    
    local dr = AC.DB.profile.diminishingReturns
    if not dr.customSpellsList then
        return 0
    end
    
    local removed = 0
    for category, spells in pairs(dr.customSpellsList) do
        if type(spells) == "table" and #spells > MAX_CUSTOM_SPELLS_PER_CATEGORY then
            -- Keep only the last MAX_CUSTOM_SPELLS_PER_CATEGORY spells
            local excess = #spells - MAX_CUSTOM_SPELLS_PER_CATEGORY
            for i = 1, excess do
                table.remove(spells, 1)  -- Remove oldest
                removed = removed + 1
            end
        end
    end
    
    return removed
end

-- Clean up old/stale data
function Cleaner:CleanDatabase()
    if not AC.DB or not AC.DB.profile then
        print("|cffFF0000ArenaCore:|r No database to clean!")
        return
    end
    
    print("|cff8B45FF=== ArenaCore Database Cleanup ===|r")
    
    -- Count before
    local function countEntries(tbl)
        local count = 0
        if type(tbl) == "table" then
            for k, v in pairs(tbl) do
                count = count + 1
                if type(v) == "table" then
                    count = count + countEntries(v)
                end
            end
        end
        return count
    end
    
    local beforeClassPacks = countEntries(AC.DB.profile.classPacks)
    
    -- 1. Optimize ClassPacks
    local removedClassPacks = self:OptimizeClassPacks()
    local afterClassPacks = countEntries(AC.DB.profile.classPacks)
    print(string.format("ClassPacks: %d → %d entries (removed %d empty)", beforeClassPacks, afterClassPacks, removedClassPacks))
    
    -- 2. Limit backups
    local removedBackups = self:LimitBackups()
    if removedBackups > 0 then
        print(string.format("Backups: Removed %d old backups (keeping last %d)", removedBackups, MAX_BACKUPS))
    end
    
    -- 3. Limit custom DR spells
    local removedDRSpells = self:LimitCustomDRSpells()
    if removedDRSpells > 0 then
        print(string.format("DR Custom Spells: Removed %d excess spells (limit: %d per category)", removedDRSpells, MAX_CUSTOM_SPELLS_PER_CATEGORY))
    end
    
    -- Force garbage collection
    local beforeGC = collectgarbage("count")
    collectgarbage("collect")
    local afterGC = collectgarbage("count")
    local freed = beforeGC - afterGC
    
    print(string.format("Garbage collected: %.2f KB", freed))
    print("|cff00FF00Database cleanup complete! Use /reload to see memory reduction.|r")
end

-- Slash command
SLASH_ACCLEANDB1 = "/accleandb"
SlashCmdList.ACCLEANDB = function()
    Cleaner:CleanDatabase()
end

-- Auto-cleanup on login (prevent database growth)
local cleanupFrame = CreateFrame("Frame")
cleanupFrame:RegisterEvent("PLAYER_LOGIN")
cleanupFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Silent cleanup after 5 seconds
        C_Timer.After(5, function()
            local totalRemoved = 0
            
            -- 1. Remove empty ClassPacks
            local removedCP = Cleaner:OptimizeClassPacks()
            totalRemoved = totalRemoved + removedCP
            
            -- 2. Limit backups (silent)
            local removedBackups = Cleaner:LimitBackups()
            totalRemoved = totalRemoved + removedBackups
            
            -- 3. Limit custom DR spells (silent)
            local removedDR = Cleaner:LimitCustomDRSpells()
            totalRemoved = totalRemoved + removedDR
            
            -- Only show message if something was cleaned
            -- HIDDEN: Auto-cleanup happens silently for cleaner user experience
            -- if totalRemoved > 0 then
            --     print(string.format("|cff8B45FFArenaCore:|r Auto-cleaned %d database entries (ClassPacks: %d, Backups: %d, DR: %d)", 
            --         totalRemoved, removedCP, removedBackups, removedDR))
            -- end
        end)
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- Disabled startup message for end users
-- print("|cff8B45FFArenaCore:|r Database cleaner loaded. Use |cffffff00/accleandb|r to optimize database.")
