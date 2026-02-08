--[[=========================================================================
    Gladius Midnight - Racial Module
    Tracks racial ability usage and cooldowns on arena frames
===========================================================================]]

local _, Gladius = ...

-- =========================================================================
-- Racial Display
-- =========================================================================
function GladiusArenaFrameMixin:RefreshRacial()
    if not Gladius.db.profile.racialEnabled then
        self.RacialIcon:Hide()
        return
    end

    local race = self.unitRace
    if not race then
        self.RacialIcon.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.RacialIcon:Show()
        return
    end

    local racialData = Gladius.RACIAL_SPELLS[race]
    if racialData then
        local texture = Gladius.GetSpellTexture(racialData.spellID)
        if texture then
            self.RacialIcon.Icon:SetTexture(texture)
        else
            self.RacialIcon.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
    else
        self.RacialIcon.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    self.RacialIcon.Icon:SetDesaturated(false)
    self.RacialIcon.Cooldown:Clear()
    self.RacialIcon:Show()
end

-- =========================================================================
-- Racial Usage Detection (from combat log)
-- =========================================================================
function GladiusArenaFrameMixin:OnRacialDetected(spellID)
    if not Gladius.db.profile.racialEnabled then return end

    -- Check if this spell is a known racial
    local race = Gladius.RACIAL_SPELL_LOOKUP[spellID]
    if not race then
        -- Check aura variants
        local mainSpellID = Gladius.RACIAL_AURA_VARIANTS[spellID]
        if mainSpellID then
            race = Gladius.RACIAL_SPELL_LOOKUP[mainSpellID]
        end
    end

    if not race then return end

    local racialData = Gladius.RACIAL_SPELLS[race]
    if not racialData then return end

    -- Apply racial cooldown
    local now = GetTime()
    self.RacialIcon.Cooldown:SetCooldown(now, racialData.duration)
    self.RacialIcon.Icon:SetDesaturated(true)

    -- Hook to restore desaturation on cooldown end
    if not self.RacialIcon.Cooldown._gladiusHooked then
        self.RacialIcon.Cooldown:HookScript("OnCooldownDone", function()
            self.RacialIcon.Icon:SetDesaturated(false)
        end)
        self.RacialIcon.Cooldown._gladiusHooked = true
    end

    -- Apply shared cooldown to trinket
    self:ApplyRacialTrinketSharedCD(racialData)
end

-- =========================================================================
-- Racial -> Trinket Shared Cooldown
-- =========================================================================
function GladiusArenaFrameMixin:ApplyRacialTrinketSharedCD(racialData)
    if not racialData or racialData.sharedCD == 0 then return end
    if not Gladius.db.profile.trinketEnabled then return end

    local trinketCD = self.TrinketIcon.Cooldown
    if trinketCD then
        local start, dur = trinketCD:GetCooldownTimes()
        start = (start or 0) / 1000
        dur = (dur or 0) / 1000
        local remaining = (start + dur) - GetTime()

        if remaining < racialData.sharedCD then
            trinketCD:SetCooldown(GetTime(), racialData.sharedCD)
            self:SetTrinketAvailability(false)
        end
    end
end

function GladiusArenaFrameMixin:ResetRacial()
    if self.RacialIcon then
        self.RacialIcon.Icon:SetTexture(nil)
        self.RacialIcon.Icon:SetDesaturated(false)
        self.RacialIcon.Cooldown:Clear()
    end
end

function GladiusArenaFrameMixin:SetTestRacial()
    if not Gladius.db.profile.racialEnabled then return end

    local race = self.unitRace
    if race then
        local racialData = Gladius.RACIAL_SPELLS[race]
        if racialData then
            local texture = Gladius.GetSpellTexture(racialData.spellID)
            if texture then
                self.RacialIcon.Icon:SetTexture(texture)
            else
                self.RacialIcon.Icon:SetTexture("Interface\\Icons\\Racial_" .. race)
            end
        end
    else
        self.RacialIcon.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    self.RacialIcon.Icon:SetDesaturated(false)
    self.RacialIcon.Cooldown:Clear()
    self.RacialIcon:Show()
end
