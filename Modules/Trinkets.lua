--[[
    Gladius Midnight - Trinkets Module
    Tracks PvP trinket usage and cooldown for arena enemies.
    Uses C_PvP.GetArenaCrowdControlInfo for real-time trinket state.
    Handles racial/trinket swap display logic.
]]

local isMidnight = GladiusMixin.isMidnight
local isRetail = GladiusMixin.isRetail
local GetSpellTexture = GetSpellTexture or (C_Spell and C_Spell.GetSpellTexture)

local function NormalizeCooldownSeconds(startTime, duration)
    if not startTime or not duration then return nil, nil end
    if startTime > 100000 then
        startTime = startTime / 1000
    end
    if duration > 100000 then
        duration = duration / 1000
    end
    return startTime, duration
end

local function GetArenaCCInfoCompat(unit)
    if not C_PvP or not C_PvP.GetArenaCrowdControlInfo then
        return nil, 0, 0
    end

    if isRetail or isMidnight then
        local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)
        return spellID, startTime, duration
    end

    local spellID, _, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)
    return spellID, startTime, duration
end

-----------------------------------------------------------------------
-- UpdateTrinketIcon: Set trinket texture state (available/on cooldown)
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateTrinketIcon(available)
    local db = self.parent.db
    if not db then return end

    if available then
        if db.profile.colorTrinket then
            self.Trinket.Texture:SetColorTexture(0, 1, 0)
        else
            self.Trinket.Texture:SetDesaturated(false)
        end
    else
        if db.profile.colorTrinket then
            if not self.Trinket.spellID then
                self.Trinket.Texture:SetTexture(nil)
            else
                self.Trinket.Texture:SetColorTexture(1, 0, 0)
            end
        else
            local desaturate
            if self.updateRacialOnTrinketSlot then
                desaturate = false
            else
                desaturate = db.profile.desaturateTrinketCD
            end
            self.Trinket.Texture:SetDesaturated(desaturate)
        end
    end
end

-----------------------------------------------------------------------
-- UpdateTrinket: Poll C_PvP API for current trinket / CC-break state
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateTrinket()
    local spellID, startTime, duration = GetArenaCCInfoCompat(self.unit)
    if not spellID then return end

    local db = self.parent.db
    if not db then return end

    -- If the spell changed, update the trinket display
    if spellID ~= self.Trinket.spellID then
        local spellTexture, spellTextureNoOverride = GetSpellTexture(spellID)

        -- In WoW 12.0+, C_Spell.GetSpellTexture returns only one value.
        -- Detect racial overrides by spell ID instead of relying on textureNoOverride.
        if not spellTextureNoOverride and spellTexture then
            local isKnownRacial = GladiusMixin.racialSpells
                and GladiusMixin.racialSpells[spellID]
                and GladiusMixin.racialSpells[spellID] > 0
            if not isKnownRacial then
                spellTextureNoOverride = spellTexture
            end
        end

        local hadRacialOnTrinket = self.updateRacialOnTrinketSlot
        self.Trinket.spellID = spellID

        -- Determine if racial should occupy the trinket slot
        local swapEnabled = db.profile.swapRacialTrinket or db.profile.swapHumanTrinket
        local shouldPlaceRacial = swapEnabled and self.race and not spellTextureNoOverride

        -- Determine the trinket icon texture
        local trinketTex
        if spellTextureNoOverride then
            trinketTex = spellTextureNoOverride
        else
            trinketTex = GladiusMixin.noTrinketTexture
        end

        -- Handle racial/trinket slot swapping
        if spellTextureNoOverride and hadRacialOnTrinket then
            -- Real trinket detected, restore racial to its own slot
            self.updateRacialOnTrinketSlot = nil
            self.Trinket.Texture:SetTexture(trinketTex)
            self:UpdateRacial()
        elseif shouldPlaceRacial then
            -- No real trinket: put racial on the trinket slot
            self.updateRacialOnTrinketSlot = true
            self:UpdateRacial()
        else
            -- Standard case
            self.updateRacialOnTrinketSlot = nil
            self.Trinket.Texture:SetTexture(trinketTex)
            if hadRacialOnTrinket then
                self:UpdateRacial()
            end
        end

        self:UpdateTrinketIcon(true)
    end

    -- Update cooldown display based on start/duration
    local cdStart, cdDuration = NormalizeCooldownSeconds(startTime, duration)
    if cdStart and cdDuration and cdStart ~= 0 and cdDuration ~= 0 and self.Trinket.spellID then
        if self.Trinket.Texture:GetTexture() ~= GladiusMixin.noTrinketTexture then
            if self.updateRacialOnTrinketSlot then
                local racialDur = self:GetRacialDuration()
                if racialDur then
                    self.Trinket.Cooldown:SetCooldown(cdStart, racialDur)
                end
            else
                self.Trinket.Cooldown:SetCooldown(cdStart, cdDuration)
            end
        end
        self:UpdateTrinketIcon(false)
    else
        self.Trinket.Cooldown:Clear()
        self:UpdateTrinketIcon(true)
    end

    if isMidnight and self.UpdateRacial then
        -- Midnight can update trinket/racial state out-of-order after round transitions.
        -- Re-evaluate racial placement each update to keep slots consistent.
        self:UpdateRacial()
    end
end

-----------------------------------------------------------------------
-- ResetTrinket: Clear trinket state when leaving arena
-----------------------------------------------------------------------
function GladiusFrameMixin:ResetTrinket()
    -- If racial was on the trinket slot, restore it
    if self.updateRacialOnTrinketSlot then
        self.updateRacialOnTrinketSlot = nil
        self:UpdateRacial()
    end

    self.Trinket.spellID = nil
    self.Trinket.Texture:SetTexture(nil)
    self.Trinket.Cooldown:Clear()
    self.Trinket.Texture:SetDesaturated(false)
end
