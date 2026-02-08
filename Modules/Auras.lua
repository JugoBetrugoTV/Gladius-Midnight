--[[=========================================================================
    Gladius Midnight - Aura Module
    Scans unit auras and displays the highest priority buff/debuff
    on the class icon frame using the priority list from AuraData
===========================================================================]]

local _, Gladius = ...

-- =========================================================================
-- Aura Scanning and Priority Selection
-- =========================================================================
function GladiusArenaFrameMixin:RefreshAuras()
    if not Gladius.db.profile.aurasEnabled then return end
    if not Gladius.db.profile.auraPriorityOnIcon then return end
    if Gladius.isTestMode then return end

    local unit = self.unitID
    if not UnitExists(unit) then return end

    -- If currently showing an interrupt overlay, skip aura refresh
    if self.isInterrupted and GetTime() < self.interruptExpiration then
        return
    else
        self.isInterrupted = false
    end

    local topSpellID = nil
    local topPriority = 0
    local topTexture = nil
    local topDuration = 0
    local topExpiration = 0
    local topStacks = 0

    -- Scan helpful auras (buffs)
    self:ScanAuraSlots(unit, "HELPFUL", topSpellID, topPriority, topTexture, topDuration, topExpiration, topStacks, function(spellID, priority, texture, duration, expiration, stacks)
        topSpellID = spellID
        topPriority = priority
        topTexture = texture
        topDuration = duration
        topExpiration = expiration
        topStacks = stacks
    end)

    -- Scan harmful auras (debuffs)
    self:ScanAuraSlots(unit, "HARMFUL", topSpellID, topPriority, topTexture, topDuration, topExpiration, topStacks, function(spellID, priority, texture, duration, expiration, stacks)
        topSpellID = spellID
        topPriority = priority
        topTexture = texture
        topDuration = duration
        topExpiration = expiration
        topStacks = stacks
    end)

    -- Apply the highest priority aura or restore class icon
    if topSpellID then
        self:SetAuraOverlay(topSpellID, topTexture, topDuration, topExpiration, topStacks)
    else
        self:SetAuraOverlay(nil)
    end
end

function GladiusArenaFrameMixin:ScanAuraSlots(unit, filter, currentTopID, currentTopPriority, currentTopTexture, currentTopDuration, currentTopExpiration, currentTopStacks, callback)
    local priorities = Gladius.AURA_PRIORITIES

    -- Use the Midnight/Retail aura iteration approach
    if AuraUtil and AuraUtil.ForEachAura then
        AuraUtil.ForEachAura(unit, filter, nil, function(auraData)
            if not auraData or not auraData.spellId then return false end

            local spellID = auraData.spellId
            local priority = priorities[spellID]

            if priority and priority > currentTopPriority then
                currentTopPriority = priority
                callback(
                    spellID,
                    priority,
                    auraData.icon,
                    auraData.duration,
                    auraData.expirationTime,
                    auraData.applications or 0
                )
            end

            return false  -- Continue iteration
        end, true)
    else
        -- Fallback: iterate by index
        for i = 1, 40 do
            local name, icon, count, _, duration, expirationTime, _, _, _, spellID = UnitAura(unit, i, filter)
            if not name then break end

            local priority = priorities[spellID]
            if priority and priority > currentTopPriority then
                currentTopPriority = priority
                callback(spellID, priority, icon, duration, expirationTime, count)
            end
        end
    end
end
