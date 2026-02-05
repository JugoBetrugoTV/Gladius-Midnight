-- Gladius Midnight - Racial Ability Tracking Module
-- Tracks PvP-relevant racial cooldowns in arena for WoW Midnight 12.0

local _, GladiusMidnight = ...
GladiusMidnight.Racials = GladiusMidnight.Racials or {}

local Racials = GladiusMidnight.Racials
local RacialData = GladiusMidnight.RacialData

-- Track cooldown state per frame
Racials.cooldowns = {}

-- Cache for detected racials per unit
Racials.detectedRacials = {}

-- Initialize racial tracking for a frame
function Racials:Initialize(frame)
    if not frame or not frame.Racial then
        return
    end

    local racialFrame = frame.Racial
    racialFrame.spellID = nil
    racialFrame.startTime = 0
    racialFrame.duration = 0

    -- Set placeholder icon
    racialFrame.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    self.cooldowns[frame.unit] = {
        active = false,
        startTime = 0,
        duration = 0,
        spellID = nil,
    }

    self.detectedRacials[frame.unit] = nil
end

-- Detect racial based on unit's race
function Racials:DetectRacial(frame)
    if not frame then
        return nil
    end

    local unit = frame.unit
    if not UnitExists(unit) then
        return nil
    end

    -- Get unit's race
    local _, race = UnitRace(unit)
    if not race then
        return nil
    end

    -- Get the primary PvP racial for this race
    local spellID, racialInfo = RacialData:GetRacialForRace(race)

    if spellID then
        self.detectedRacials[unit] = {
            spellID = spellID,
            race = race,
            info = racialInfo,
        }

        -- Get spell icon
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo and spellInfo.iconID then
            return spellID, spellInfo.iconID, racialInfo
        end
    end

    return nil
end

-- Update racial display for a frame
function Racials:UpdateRacial(frame)
    if not frame or not frame.Racial then
        return
    end

    local unit = frame.unit
    local racialFrame = frame.Racial

    if not UnitExists(unit) then
        racialFrame:Hide()
        return
    end

    -- Detect racial if not already known
    if not self.detectedRacials[unit] then
        local spellID, icon, info = self:DetectRacial(frame)
        if spellID and icon then
            racialFrame.Icon:SetTexture(icon)
            racialFrame.spellID = spellID
        end
    else
        -- Use cached racial info
        local cached = self.detectedRacials[unit]
        if cached and cached.spellID then
            local spellInfo = C_Spell.GetSpellInfo(cached.spellID)
            if spellInfo and spellInfo.iconID then
                racialFrame.Icon:SetTexture(spellInfo.iconID)
            end
        end
    end

    -- Check cooldown state
    local cooldownData = self.cooldowns[unit]
    if cooldownData and cooldownData.active then
        local elapsed = GetTime() - cooldownData.startTime
        if elapsed >= cooldownData.duration then
            -- Cooldown expired
            cooldownData.active = false
            racialFrame.Icon:SetDesaturated(false)
            if racialFrame.Cooldown then
                racialFrame.Cooldown:Clear()
            end
        else
            -- Still on cooldown
            racialFrame.Icon:SetDesaturated(true)
        end
    end

    racialFrame:Show()
end

-- Called when a spell is cast by an arena opponent
function Racials:OnSpellCast(frame, spellID)
    if not frame or not spellID then
        return
    end

    -- Check if this is a tracked racial ability
    local racialInfo = RacialData:GetRacialInfo(spellID)
    if not racialInfo then
        return
    end

    local unit = frame.unit
    local racialFrame = frame.Racial

    if not racialFrame then
        return
    end

    -- Update cooldown tracking
    local cooldownData = self.cooldowns[unit]
    if cooldownData then
        cooldownData.spellID = spellID
        cooldownData.startTime = GetTime()
        cooldownData.duration = racialInfo.cooldown
        cooldownData.active = true

        -- Update visual
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo and spellInfo.iconID then
            racialFrame.Icon:SetTexture(spellInfo.iconID)
        end

        if racialFrame.Cooldown then
            racialFrame.Cooldown:SetCooldown(GetTime(), racialInfo.cooldown)
        end

        racialFrame.Icon:SetDesaturated(true)

        -- Check if this racial shares cooldown with trinket
        if RacialData:SharesTrinketCooldown(spellID) then
            self:ApplySharedTrinketCooldown(frame, spellID)
        end
    end
end

-- Apply shared cooldown to trinket when certain racials are used
function Racials:ApplySharedTrinketCooldown(frame, racialSpellID)
    if not GladiusMidnight.Trinkets then
        return
    end

    local unit = frame.unit

    -- Human's Will to Survive and Undead's Will of the Forsaken
    -- share a cooldown with PvP trinkets
    local sharedCooldown = 90 -- Standard shared cooldown

    -- For healers, the shared cooldown is reduced
    local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(frame.unitIndex)
    local isHealer = false

    -- Check if healer spec (simplified check)
    local healerSpecs = {
        [65] = true,   -- Holy Paladin
        [105] = true,  -- Restoration Druid
        [256] = true,  -- Discipline Priest
        [257] = true,  -- Holy Priest
        [264] = true,  -- Restoration Shaman
        [270] = true,  -- Mistweaver Monk
        [1468] = true, -- Preservation Evoker
    }

    if specID and healerSpecs[specID] then
        isHealer = true
        sharedCooldown = 60 -- Reduced for healers
    end

    -- Apply shared cooldown to trinket
    GladiusMidnight.Trinkets:OnSpellCast(frame, racialSpellID)
end

-- Reset racial tracking for a unit
function Racials:Reset(unit)
    if self.cooldowns[unit] then
        self.cooldowns[unit] = {
            active = false,
            startTime = 0,
            duration = 0,
            spellID = nil,
        }
    end

    self.detectedRacials[unit] = nil

    local frame = GladiusMidnight.frames[unit]
    if frame and frame.Racial then
        frame.Racial.Icon:SetDesaturated(false)
        frame.Racial.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        if frame.Racial.Cooldown then
            frame.Racial.Cooldown:Clear()
        end
    end
end

-- Get remaining cooldown for a unit's racial
function Racials:GetRemainingCooldown(unit)
    local cooldownData = self.cooldowns[unit]
    if cooldownData and cooldownData.active then
        local elapsed = GetTime() - cooldownData.startTime
        local remaining = cooldownData.duration - elapsed
        return math.max(0, remaining)
    end
    return 0
end

-- Check if racial is ready
function Racials:IsRacialReady(unit)
    return self:GetRemainingCooldown(unit) <= 0
end

-- Get detected racial for unit
function Racials:GetDetectedRacial(unit)
    return self.detectedRacials[unit]
end
