--[[
    Gladius Midnight - Trinkets Module
    Tracks PvP trinket usage and cooldown for arena enemies.
    Uses C_PvP.GetArenaCrowdControlInfo for real-time trinket state.
    Handles racial/trinket swap display logic.
]]

local isMidnight = GladiusMixin.isMidnight
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture

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
    local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(self.unit)
    if not spellID then return end

    local db = self.parent.db
    if not db then return end

    -- If the spell changed, update the trinket display
    if spellID ~= self.Trinket.spellID then
        local _, spellTextureNoOverride = GetSpellTexture(spellID)

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
    if isMidnight then
        -- Midnight: cooldown data handled via hooks in Frames.lua
    else
        if startTime ~= 0 and duration ~= 0 and self.Trinket.spellID then
            if self.Trinket.Texture:GetTexture() ~= GladiusMixin.noTrinketTexture then
                if self.updateRacialOnTrinketSlot then
                    local racialDur = self:GetRacialDuration()
                    if racialDur then
                        self.Trinket.Cooldown:SetCooldown(startTime / 1000.0, racialDur)
                    end
                else
                    self.Trinket.Cooldown:SetCooldown(startTime / 1000.0, duration / 1000.0)
                end
            end
            if db.profile.colorTrinket then
                self.Trinket.Texture:SetColorTexture(1, 0, 0)
            else
                if not self.updateRacialOnTrinketSlot then
                    self.Trinket.Texture:SetDesaturated(db.profile.desaturateTrinketCD)
                end
            end
        else
            self.Trinket.Cooldown:Clear()
            if db.profile.colorTrinket then
                self.Trinket.Texture:SetColorTexture(0, 1, 0)
            else
                self.Trinket.Texture:SetDesaturated(false)
            end
        end
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
