--[[
    Gladius Midnight - Racials Module
    Tracks racial ability usage and cooldowns for arena enemies.
    Handles shared cooldown between racials and PvP trinket.
    Complete racial spell database with all spell IDs and durations.
]]

local GetTime = GetTime
local isMidnight = GladiusMixin.isMidnight

local function GetSpellTextureCompat(spellID)
    if GetSpellTexture then
        local a,b = GetSpellTexture(spellID)
        return b or a
    end
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID)
    end
    return nil
end

local racialSpells
local racialData
local trinkets

-----------------------------------------------------------------------
-- Default settings for racial categories (all enabled)
-----------------------------------------------------------------------
GladiusMixin.defaultSettings.profile.racialCategories = {
    ["Human"] = true,
    ["Scourge"] = true,
    ["Dwarf"] = true,
    ["NightElf"] = true,
    ["Gnome"] = true,
    ["Draenei"] = true,
    ["Worgen"] = true,
    ["Pandaren"] = true,
    ["Orc"] = true,
    ["Tauren"] = true,
    ["Troll"] = true,
    ["BloodElf"] = true,
    ["Goblin"] = true,
    ["LightforgedDraenei"] = true,
    ["HighmountainTauren"] = true,
    ["Nightborne"] = true,
    ["MagharOrc"] = true,
    ["DarkIronDwarf"] = true,
    ["ZandalariTroll"] = true,
    ["VoidElf"] = true,
    ["KulTiran"] = true,
    ["Mechagnome"] = true,
    ["Vulpera"] = true,
    ["Dracthyr"] = true,
    ["EarthenDwarf"] = true,
    ["Harronir"] = true,
}

-----------------------------------------------------------------------
-- Racial spell database: spellID -> cooldown duration
-----------------------------------------------------------------------
racialSpells = {
    [59752]   = 180,  -- Will to Survive (Human)
    [7744]    = 120,  -- Will of the Forsaken (Undead)
    [20594]   = 120,  -- Stoneform (Dwarf)
    [65116]   = 120,  -- Stoneform Aura (Dwarf)
    [58984]   = 120,  -- Shadowmeld (Night Elf)
    [20589]   = 60,   -- Escape Artist (Gnome)
    [59542]   = 120,  -- Gift of the Naaru (Draenei)
    [68992]   = 120,  -- Darkflight (Worgen)
    [107079]  = 120,  -- Quaking Palm (Pandaren)
    [33697]   = 120,  -- Blood Fury (Orc)
    [20549]   = 90,   -- War Stomp (Tauren)
    [26297]   = 180,  -- Berserking (Troll)
    [202719]  = 90,   -- Arcane Torrent (Blood Elf)
    [69070]   = 90,   -- Rocket Jump (Goblin)
    [255647]  = 150,  -- Light's Judgment (Lightforged Draenei)
    [255654]  = 120,  -- Bull Rush (Highmountain Tauren)
    [260364]  = 180,  -- Arcane Pulse (Nightborne)
    [274738]  = 120,  -- Ancestral Call (Mag'har Orc)
    [265221]  = 120,  -- Fireblood (Dark Iron Dwarf)
    [273104]  = 120,  -- Fireblood Aura (Dark Iron Dwarf)
    [291944]  = 160,  -- Regeneratin' (Zandalari Troll)
    [256948]  = 180,  -- Spatial Rift (Void Elf)
    [287712]  = 160,  -- Haymaker (Kul Tiran)
    [312924]  = 180,  -- Hyper Organic Light Originator (Mechagnome)
    [312411]  = 90,   -- Bag of Tricks (Vulpera)
    [368970]  = 90,   -- Tail Swipe (Dracthyr)
    [357214]  = 90,   -- Wing Buffet (Dracthyr)
    [436344]  = 120,  -- Azerite Surge (Earthen Dwarf)
    [1237885] = 180,  -- Thorn Bloom (Harronir)

    -- PvP Trinket spells (not actual racials, duration = 0)
    [336126]  = 0,    -- PvP Trinket cast
    [336139]  = 0,    -- Adapted Aura applied
}

-- Spells that represent trinket usage (not racial abilities)
trinkets = {
    [336126] = true,  -- Trinket Spell Cast
    [336139] = true,  -- Adaptation Aura Applied
}

-----------------------------------------------------------------------
-- Racial data per race: texture, shared CD with trinket, primary spell
-----------------------------------------------------------------------
racialData = {
    ["Human"]              = { texture = GetSpellTextureCompat(59752),   sharedCD = 90,  spellID = 59752 },
    ["Scourge"]            = { texture = GetSpellTextureCompat(7744),    sharedCD = 30,  spellID = 7744 },
    ["Dwarf"]              = { texture = GetSpellTextureCompat(20594),   sharedCD = 30,  spellID = 20594 },
    ["NightElf"]           = { texture = GetSpellTextureCompat(58984),   sharedCD = 0,   spellID = 58984 },
    ["Gnome"]              = { texture = GetSpellTextureCompat(20589),   sharedCD = 0,   spellID = 20589 },
    ["Draenei"]            = { texture = GetSpellTextureCompat(59542),   sharedCD = 0,   spellID = 59542 },
    ["Worgen"]             = { texture = GetSpellTextureCompat(68992),   sharedCD = 0,   spellID = 68992 },
    ["Pandaren"]           = { texture = GetSpellTextureCompat(107079),  sharedCD = 0,   spellID = 107079 },
    ["Orc"]                = { texture = GetSpellTextureCompat(33697),   sharedCD = 0,   spellID = 33697 },
    ["Tauren"]             = { texture = GetSpellTextureCompat(20549),   sharedCD = 0,   spellID = 20549 },
    ["Troll"]              = { texture = GetSpellTextureCompat(26297),   sharedCD = 0,   spellID = 26297 },
    ["BloodElf"]           = { texture = GetSpellTextureCompat(202719),  sharedCD = 0,   spellID = 202719 },
    ["Goblin"]             = { texture = GetSpellTextureCompat(69070),   sharedCD = 0,   spellID = 69070 },
    ["LightforgedDraenei"] = { texture = GetSpellTextureCompat(255647),  sharedCD = 0,   spellID = 255647 },
    ["HighmountainTauren"] = { texture = GetSpellTextureCompat(255654),  sharedCD = 0,   spellID = 255654 },
    ["Nightborne"]         = { texture = GetSpellTextureCompat(260364),  sharedCD = 0,   spellID = 260364 },
    ["MagharOrc"]          = { texture = GetSpellTextureCompat(274738),  sharedCD = 0,   spellID = 274738 },
    ["DarkIronDwarf"]      = { texture = GetSpellTextureCompat(265221),  sharedCD = 30,  spellID = 265221 },
    ["ZandalariTroll"]     = { texture = GetSpellTextureCompat(291944),  sharedCD = 0,   spellID = 291944 },
    ["VoidElf"]            = { texture = GetSpellTextureCompat(256948),  sharedCD = 0,   spellID = 256948 },
    ["KulTiran"]           = { texture = GetSpellTextureCompat(287712),  sharedCD = 0,   spellID = 287712 },
    ["Mechagnome"]         = { texture = GetSpellTextureCompat(312924),  sharedCD = 0,   spellID = 312924 },
    ["Vulpera"]            = { texture = GetSpellTextureCompat(312411),  sharedCD = 0,   spellID = 312411 },
    ["Dracthyr"]           = { texture = GetSpellTextureCompat(368970),  sharedCD = 0,   spellID = 368970 },
    ["EarthenDwarf"]       = { texture = GetSpellTextureCompat(436344),  sharedCD = 0,   spellID = 436344 },
    ["Harronir"]           = { texture = GetSpellTextureCompat(1237885), sharedCD = 0,   spellID = 1237885 },
}

-- Store references on the main mixin for other modules
GladiusMixin.racialSpells = racialSpells
GladiusMixin.racialData = racialData

-----------------------------------------------------------------------
-- Helper: Get remaining cooldown time on a cooldown frame
-----------------------------------------------------------------------
local function GetCooldownRemaining(cooldownFrame)
    local startMs, durationMs = cooldownFrame:GetCooldownTimes()
    if startMs == 0 then return 0 end
    return (startMs + durationMs) / 1000 - GetTime()
end

-----------------------------------------------------------------------
-- GetRacialDuration: Get the cooldown duration for this frame's race
-----------------------------------------------------------------------
function GladiusFrameMixin:GetRacialDuration()
    if not self.race or not racialData[self.race] then return nil end
    local sid = racialData[self.race].spellID
    if not sid then return nil end
    return racialSpells[sid]
end

-----------------------------------------------------------------------
-- GetSharedCD: Get the shared CD between racial and trinket
-- Human healers have reduced shared CD (60s instead of 90s)
-----------------------------------------------------------------------
function GladiusFrameMixin:GetSharedCD()
    if self.race == "Human" and self.isHealer and self.Trinket.spellID == GladiusMixin.trinketID then
        return 60
    end
    return racialData[self.race] and racialData[self.race].sharedCD
end

-----------------------------------------------------------------------
-- FindRacial: Called from combat log when a racial or trinket is used
-----------------------------------------------------------------------
function GladiusFrameMixin:FindRacial(spellID)
    local duration = racialSpells[spellID]
    if not duration then return end

    local now = GetTime()

    -- Actual racial ability used (not a trinket spell)
    if not trinkets[spellID] then
        if self.updateRacialOnTrinketSlot then
            -- Racial is displayed on the trinket slot
            if self.Trinket.spellID and self.Trinket.Texture:GetTexture() ~= GladiusMixin.noTrinketTexture then
                self.Trinket.Cooldown:SetCooldown(now, duration)
            end
            self:UpdateTrinketIcon(false)
        else
            -- Normal: apply cooldown to the racial slot
            if self.Racial.Texture:GetTexture() then
                self.Racial.Cooldown:SetCooldown(now, duration)
            end
        end

        -- Handle shared CD: racial used -> trinket gets shared CD
        if not self.updateRacialOnTrinketSlot and self.Trinket.spellID == GladiusMixin.trinketID then
            local remainingCD = GetCooldownRemaining(self.Trinket.Cooldown)
            local sharedCD = self:GetSharedCD()

            if sharedCD and remainingCD < sharedCD then
                if self.Trinket.spellID and self.Trinket.Texture:GetTexture() ~= GladiusMixin.noTrinketTexture then
                    self.Trinket.Cooldown:SetCooldown(now, sharedCD)
                end
                local db = self.parent.db
                if db then
                    if db.profile.colorTrinket then
                        self.Trinket.Texture:SetColorTexture(1, 0, 0)
                    else
                        self.Trinket.Texture:SetDesaturated(db.profile.desaturateTrinketCD)
                    end
                end
            end
        end

    -- Trinket spell used: handle shared CD in reverse (trinket -> racial)
    elseif self.Racial.Texture:GetTexture() then
        local remainingCD = GetCooldownRemaining(self.Racial.Cooldown)
        local sharedCD = self:GetSharedCD()

        if sharedCD and remainingCD < sharedCD then
            self.Racial.Cooldown:SetCooldown(now, sharedCD)
        end
    end
end

-----------------------------------------------------------------------
-- UpdateRacial: Set the racial icon texture based on detected race
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateRacial()
    self.race = select(2, UnitRace(self.unit))
    self.Racial.Texture:SetTexture(nil)

    if not self.race then return end

    local db = self.parent.db
    if not db then return end
    local profile = db.profile

    -- Check if this race is enabled or if swap is active for Human
    local raceEnabled = profile.racialCategories and profile.racialCategories[self.race]
    local swapEnabled = profile.swapRacialTrinket or profile.swapHumanTrinket

    if not raceEnabled and not (swapEnabled and self.race == "Human") then
        return
    end

    local rData = racialData[self.race]
    if not rData then return end

    -- Handle swap display logic
    if swapEnabled then
        local trinketTex = self.Trinket.Texture:GetTexture()

        if not self.updateRacialOnTrinketSlot then
            -- Racial stays in its own slot
            self.Racial.Texture:SetTexture(rData.texture)
        else
            -- Racial should be on the trinket slot
            if not trinketTex
                or trinketTex == GladiusMixin.noTrinketTexture
                or trinketTex == rData.texture
            then
                -- Place racial icon on trinket slot
                self.Racial.Texture:SetTexture(nil)

                if profile.colorTrinket then
                    local cdStart, cdDuration = self.Racial.Cooldown:GetCooldownTimes()
                    if cdDuration and cdDuration > 0 and cdStart > 0 then
                        self.Trinket.Texture:SetColorTexture(1, 0, 0)
                    else
                        self.Trinket.Texture:SetColorTexture(0, 1, 0)
                    end
                else
                    self.Trinket.Texture:SetTexture(rData.texture)
                    self.Racial.Texture:SetTexture(nil)
                end

                -- Transfer any active cooldown to the trinket slot
                local cdStart, cdDuration = self.Racial.Cooldown:GetCooldownTimes()
                if cdDuration and cdDuration > 0 and cdStart > 0 then
                    if self.Trinket.spellID and self.Trinket.Texture:GetTexture() ~= GladiusMixin.noTrinketTexture then
                        self.Trinket.Cooldown:SetCooldown(cdStart / 1000.0, cdDuration / 1000.0)
                    end
                end
                self.Racial.Cooldown:Clear()
            else
                -- Real trinket already present, racial stays in racial slot
                self.Racial.Texture:SetTexture(rData.texture)
            end
        end
    else
        -- No swap: racial always in racial slot
        self.Racial.Texture:SetTexture(rData.texture)
    end
end

-----------------------------------------------------------------------
-- ResetRacial: Clear racial state when leaving arena
-----------------------------------------------------------------------
function GladiusFrameMixin:ResetRacial()
    self.race = nil
    self.Racial.Texture:SetTexture(nil)
    self.Racial.Cooldown:Clear()
    self.updateRacialOnTrinketSlot = nil
    self:UpdateRacial()
end
