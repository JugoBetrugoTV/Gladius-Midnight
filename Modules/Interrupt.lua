--[[=========================================================================
    Gladius Midnight - Interrupt Module
    Tracks when enemies are interrupted and shows lockout on class icon
    Also tracks the player's own interrupt cooldown to color castbars
===========================================================================]]

local _, Gladius = ...

-- =========================================================================
-- Enemy Interrupted (from combat log SPELL_INTERRUPT)
-- =========================================================================
function GladiusArenaFrameMixin:OnInterrupted(interruptSpellID, interruptedSpellID, sourceGUID, sourceName)
    if not Gladius.db.profile.interruptEnabled then return end

    -- Get the lockout duration from our interrupt data
    local lockoutDuration = Gladius.INTERRUPT_SPELLS[interruptSpellID]
    if not lockoutDuration then return end

    -- Check for spell lock duration reducers on the interrupted target
    if self.unitID and UnitExists(self.unitID) then
        lockoutDuration = self:CheckLockoutReduction(lockoutDuration)
    end

    -- Get the source class for coloring
    local sourceClass = nil
    if sourceGUID then
        local _, classToken = GetPlayerInfoByGUID(sourceGUID)
        sourceClass = classToken
    end

    -- Show interrupt overlay on class icon
    self:SetInterruptOverlay(interruptSpellID, lockoutDuration, sourceClass)

    -- Set interrupt state
    self.isInterrupted = true
    self.interruptExpiration = GetTime() + lockoutDuration

    -- Schedule restoration of class icon after lockout ends
    C_Timer.After(lockoutDuration + 0.1, function()
        if GetTime() >= self.interruptExpiration then
            self.isInterrupted = false
            self:RefreshClassIcon()
            self:RefreshAuras()
        end
    end)
end

-- =========================================================================
-- Lockout Duration Reduction
-- Some buffs reduce the duration of interrupt lockouts
-- =========================================================================
function GladiusArenaFrameMixin:CheckLockoutReduction(baseDuration)
    local unit = self.unitID
    if not UnitExists(unit) then return baseDuration end

    local reducedDuration = baseDuration

    for reducerSpellID, multiplier in pairs(Gladius.SPELL_LOCK_REDUCERS) do
        if AuraUtil and AuraUtil.FindAuraByName then
            local name = Gladius.GetSpellInfo(reducerSpellID)
            if name and AuraUtil.FindAuraByName(name, unit, "HELPFUL") then
                reducedDuration = reducedDuration * multiplier
            end
        end
    end

    return reducedDuration
end

-- =========================================================================
-- Player's Own Interrupt Tracking
-- Monitors the player's interrupt CD to color enemy castbars accordingly
-- =========================================================================
local interruptCheckFrame = nil
local playerInterruptSpellID = nil

function Gladius:SetupInterruptTracking()
    if not self.db.profile.interruptColorCastbar then return end

    local classToken = self.playerClass
    if not classToken then return end

    playerInterruptSpellID = Gladius.CLASS_INTERRUPT_SPELLS[classToken]
    if not playerInterruptSpellID then
        -- Class has no baseline interrupt (e.g., Priest)
        self.playerInterruptOnCD = false
        return
    end

    if not interruptCheckFrame then
        interruptCheckFrame = CreateFrame("Frame")
    end

    -- Poll interrupt cooldown status periodically
    local pollInterval = 0.5
    local elapsed = 0

    interruptCheckFrame:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed < pollInterval then return end
        elapsed = 0

        if not playerInterruptSpellID then return end

        local cdInfo = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(playerInterruptSpellID)
        if cdInfo then
            local remaining = (cdInfo.startTime + cdInfo.duration) - GetTime()
            Gladius.playerInterruptOnCD = remaining > 0
        else
            -- Fallback
            local start, duration = GetSpellCooldown(playerInterruptSpellID)
            if start and duration then
                local remaining = (start + duration) - GetTime()
                Gladius.playerInterruptOnCD = remaining > 0
            end
        end
    end)
end

function Gladius:StopInterruptTracking()
    if interruptCheckFrame then
        interruptCheckFrame:SetScript("OnUpdate", nil)
    end
    self.playerInterruptOnCD = false
end

-- Hook into arena enter/leave
local originalEnterArena = Gladius.EnterArena
function Gladius:EnterArena()
    originalEnterArena(self)
    self:SetupInterruptTracking()
end

local originalLeaveArena = Gladius.LeaveArena
function Gladius:LeaveArena()
    originalLeaveArena(self)
    self:StopInterruptTracking()
end
