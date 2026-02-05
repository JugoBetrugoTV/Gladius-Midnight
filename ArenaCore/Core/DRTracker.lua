-- Core/DRTracker.lua
-- Real-time DR tracking using combat log events

local AC = _G.ArenaCore
if not AC then return end

local function acquireTracker()
    if AC.modules and AC.modules.diminishingReturns and AC.modules.diminishingReturns.tracker then
        return AC.modules.diminishingReturns.tracker
    end

    if AC.LoadModule then
        local tracker = AC:LoadModule("modules/DiminishingReturns/Tracker.lua")
        if tracker then
            AC.modules = AC.modules or {}
            AC.modules.diminishingReturns = AC.modules.diminishingReturns or {}
            AC.modules.diminishingReturns.tracker = tracker
            return tracker
        end
    end

    return nil
end

local function requireTracker()
    local tracker = acquireTracker()
    if not tracker then
        print("|cffFF0000[ArenaCore]|r Diminishing Returns tracker module unavailable")
    end
    return tracker
end

function AC:InitializeDRTracker()
    local tracker = requireTracker()
    if tracker and tracker.Initialize then
        tracker:Initialize()
    end
end

function AC:StartRealArenaDRTimer()
    local tracker = acquireTracker()
    if tracker and tracker.StartRealArenaTicker then
        tracker:StartRealArenaTicker()
    end
end

function AC:TrackDRApplication(guid, spellID, category)
    local tracker = acquireTracker()
    if tracker and tracker.TrackApplication then
        tracker:TrackApplication(guid, spellID, category)
    end
end

function AC:UpdateDRDisplay(unitID, category, actualSpellID)
    local tracker = acquireTracker()
    if tracker and tracker.UpdateLiveDisplay then
        tracker:UpdateLiveDisplay(unitID, category, actualSpellID)
    end
end

function AC:HandleCombatLogDR()
    local tracker = acquireTracker()
    if not tracker then
        print("|cffFF0000[DR DEBUG]|r HandleCombatLogDR: Tracker is nil!")
        return
    end
    if not tracker.HandleCombatLog then
        print("|cffFF0000[DR DEBUG]|r HandleCombatLogDR: Tracker has no HandleCombatLog function!")
        return
    end
    -- print("|cff00FF00[DR DEBUG]|r HandleCombatLogDR: Calling tracker:HandleCombatLog()")
    tracker:HandleCombatLog()
end

function AC:IsDRSourceFriendly(sourceGUID, sourceFlags)
    local tracker = acquireTracker()
    if tracker and tracker.IsSourceFriendly then
        return tracker:IsSourceFriendly(sourceGUID, sourceFlags)
    end
    return false
end

function AC:GetUnitIDFromGUID(guid)
    local tracker = acquireTracker()
    if tracker and tracker.GetUnitIDFromGUID then
        return tracker:GetUnitIDFromGUID(guid)
    end
    return nil
end

function AC:GetDRIconForCategory(category, unitGUID, actualSpellID)
    local tracker = acquireTracker()
    if tracker and tracker.GetDRIconForCategory then
        return tracker:GetDRIconForCategory(category, unitGUID, actualSpellID)
    end
    return actualSpellID or 408
end

AC:RegisterEvent("ADDON_LOADED", function(eventName, addonName)
    if addonName == AC.AddonName then
        C_Timer.After(1, function()
            AC:InitializeDRTracker()
        end)
    end
end)

return