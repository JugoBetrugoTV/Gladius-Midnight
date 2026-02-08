--[[=========================================================================
    Gladius Midnight - Trinket Module
    Tracks PvP trinket usage and cooldown on arena frames
===========================================================================]]

local _, Gladius = ...

-- =========================================================================
-- Trinket Display
-- =========================================================================
function GladiusArenaFrameMixin:RefreshTrinket()
    if not Gladius.db.profile.trinketEnabled then
        self.TrinketIcon:Hide()
        return
    end

    local unit = self.unitID
    if Gladius.isTestMode then return end

    -- Use C_PvP API for trinket info
    if C_PvP and C_PvP.GetArenaCrowdControlInfo then
        local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)

        if spellID and spellID > 0 then
            local texture = Gladius.GetSpellTexture(spellID)
            if texture then
                self.TrinketIcon.Icon:SetTexture(texture)
            else
                self.TrinketIcon.Icon:SetTexture(self:GetFactionTrinketTexture())
            end

            -- Show cooldown if active
            if startTime and startTime > 0 and duration and duration > 0 then
                self.TrinketIcon.Cooldown:SetCooldown(startTime / 1000, duration / 1000)
                self:SetTrinketAvailability(false)
            else
                self.TrinketIcon.Cooldown:Clear()
                self:SetTrinketAvailability(true)
            end
        else
            -- No trinket equipped or not yet detected
            self.TrinketIcon.Icon:SetTexture(self:GetFactionTrinketTexture())
            self.TrinketIcon.Cooldown:Clear()
            self:SetTrinketAvailability(true)
        end
    else
        self.TrinketIcon.Icon:SetTexture(self:GetFactionTrinketTexture())
    end

    self.TrinketIcon:Show()
end

function GladiusArenaFrameMixin:OnTrinketUsed()
    if not Gladius.db.profile.trinketEnabled then return end

    local now = GetTime()
    self.TrinketIcon.Cooldown:SetCooldown(now, Gladius.TRINKET_COOLDOWN)
    self:SetTrinketAvailability(false)

    -- Apply shared cooldown to racial if applicable
    self:ApplyTrinketRacialSharedCD(Gladius.TRINKET_COOLDOWN)
end

function GladiusArenaFrameMixin:SetTrinketAvailability(available)
    if available then
        self.TrinketIcon.Icon:SetDesaturated(false)
        self.TrinketIcon.Icon:SetVertexColor(1, 1, 1)
    else
        if Gladius.db.profile.trinketDesaturateCD then
            self.TrinketIcon.Icon:SetDesaturated(true)
        end
        self.TrinketIcon.Icon:SetVertexColor(0.6, 0.6, 0.6)
    end
end

function GladiusArenaFrameMixin:GetFactionTrinketTexture()
    if Gladius.playerFaction == "Alliance" then
        return Gladius.TRINKET_ICON_HORDE
    else
        return Gladius.TRINKET_ICON_ALLIANCE
    end
end

function GladiusArenaFrameMixin:ResetTrinket()
    if self.TrinketIcon then
        self.TrinketIcon.Icon:SetTexture(nil)
        self.TrinketIcon.Icon:SetDesaturated(false)
        self.TrinketIcon.Icon:SetVertexColor(1, 1, 1)
        self.TrinketIcon.Cooldown:Clear()
    end
end

function GladiusArenaFrameMixin:SetTestTrinket()
    if not Gladius.db.profile.trinketEnabled then return end
    self.TrinketIcon.Icon:SetTexture(self:GetFactionTrinketTexture())
    self.TrinketIcon.Cooldown:Clear()
    self.TrinketIcon.Icon:SetDesaturated(false)
    self.TrinketIcon:Show()
end

-- =========================================================================
-- Trinket / Racial Shared Cooldown
-- Some racial abilities share a cooldown with PvP trinkets
-- =========================================================================
function GladiusArenaFrameMixin:ApplyTrinketRacialSharedCD(trinketCD)
    if not self.unitRace then return end
    local racialData = Gladius.RACIAL_SPELLS[self.unitRace]
    if not racialData or racialData.sharedCD == 0 then return end

    -- Check if racial cooldown is shorter than shared CD
    local racialCD = self.RacialIcon.Cooldown
    if racialCD then
        local start, dur = racialCD:GetCooldownTimes()
        start = (start or 0) / 1000
        dur = (dur or 0) / 1000
        local remaining = (start + dur) - GetTime()

        if remaining < racialData.sharedCD then
            racialCD:SetCooldown(GetTime(), racialData.sharedCD)
        end
    end
end
