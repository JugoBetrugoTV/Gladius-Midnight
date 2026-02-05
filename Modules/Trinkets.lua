-- Gladius Midnight - Trinket Tracking Module
-- Tracks PvP trinket usage in arena for WoW Midnight 12.0

local _, GladiusMidnight = ...
GladiusMidnight.Trinkets = GladiusMidnight.Trinkets or {}

local Trinkets = GladiusMidnight.Trinkets

-- PvP Trinket spell IDs (CC-break trinkets)
Trinkets.TrinketSpells = {
    -- Gladiator's Medallion (removes all CC)
    [336126] = { cooldown = 120, icon = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01" },
    -- Older trinket variants
    [42292] = { cooldown = 120, icon = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01" },
    -- Adaptation (passive, but triggers on CC)
    [336135] = { cooldown = 60, icon = "Interface\\Icons\\Spell_Shadow_Teleport" },
    -- Relentless (passive DR)
    [336128] = { cooldown = 0, icon = "Interface\\Icons\\Ability_PVP_Hardiness" },
}

-- Faction-specific trinket icons
Trinkets.FactionIcons = {
    ["Alliance"] = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01",
    ["Horde"] = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02",
}

-- Surrender to Madness flag icon (when no trinket equipped)
Trinkets.NoTrinketIcon = "Interface\\Icons\\INV_BannerPVP_02"

-- Track cooldown state per frame
Trinkets.cooldowns = {}

-- Initialize trinket tracking for a frame
function Trinkets:Initialize(frame)
    if not frame or not frame.Trinket then
        return
    end

    local trinketFrame = frame.Trinket
    trinketFrame.spellID = nil
    trinketFrame.startTime = 0
    trinketFrame.duration = 0

    -- Set default icon
    local faction = UnitFactionGroup(frame.unit)
    local icon = self.FactionIcons[faction] or self.FactionIcons["Alliance"]
    trinketFrame.Icon:SetTexture(icon)

    self.cooldowns[frame.unit] = {
        active = false,
        startTime = 0,
        duration = 0,
        spellID = nil,
    }
end

-- Update trinket display for a frame
function Trinkets:UpdateTrinket(frame)
    if not frame or not frame.Trinket then
        return
    end

    local unit = frame.unit
    local trinketFrame = frame.Trinket

    if not UnitExists(unit) then
        trinketFrame:Hide()
        return
    end

    -- Check for trinket info using C_PvP API (12.0 compatible)
    local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)

    if spellID and spellID ~= 0 then
        -- Trinket has been used, show cooldown
        local cooldownData = self.cooldowns[unit]

        -- Check if this is a new trinket usage
        if spellID ~= cooldownData.spellID or startTime ~= cooldownData.startTime then
            cooldownData.spellID = spellID
            cooldownData.startTime = startTime
            cooldownData.duration = duration
            cooldownData.active = true

            -- Get icon for this spell
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo and spellInfo.iconID then
                trinketFrame.Icon:SetTexture(spellInfo.iconID)
            end

            -- Start cooldown display
            if trinketFrame.Cooldown then
                trinketFrame.Cooldown:SetCooldown(startTime, duration)
            end

            -- Desaturate icon while on cooldown
            trinketFrame.Icon:SetDesaturated(true)
        end
    else
        -- No cooldown active, check if previous cooldown expired
        local cooldownData = self.cooldowns[unit]
        if cooldownData and cooldownData.active then
            local elapsed = GetTime() - cooldownData.startTime
            if elapsed >= cooldownData.duration then
                cooldownData.active = false
                trinketFrame.Icon:SetDesaturated(false)

                -- Reset to faction icon
                local faction = UnitFactionGroup(unit)
                local icon = self.FactionIcons[faction] or self.FactionIcons["Alliance"]
                trinketFrame.Icon:SetTexture(icon)
            end
        end
    end

    trinketFrame:Show()
end

-- Called when a spell is cast by an arena opponent
function Trinkets:OnSpellCast(frame, spellID)
    if not frame or not spellID then
        return
    end

    local trinketInfo = self.TrinketSpells[spellID]
    if trinketInfo then
        -- This is a trinket spell
        local unit = frame.unit
        local trinketFrame = frame.Trinket

        if not trinketFrame then
            return
        end

        -- Update cooldown tracking
        local cooldownData = self.cooldowns[unit]
        if cooldownData then
            cooldownData.spellID = spellID
            cooldownData.startTime = GetTime()
            cooldownData.duration = trinketInfo.cooldown
            cooldownData.active = true

            -- Update visual
            if trinketInfo.icon then
                trinketFrame.Icon:SetTexture(trinketInfo.icon)
            end

            if trinketFrame.Cooldown then
                trinketFrame.Cooldown:SetCooldown(GetTime(), trinketInfo.cooldown)
            end

            trinketFrame.Icon:SetDesaturated(true)
        end
    end
end

-- Reset trinket tracking for a unit
function Trinkets:Reset(unit)
    if self.cooldowns[unit] then
        self.cooldowns[unit] = {
            active = false,
            startTime = 0,
            duration = 0,
            spellID = nil,
        }
    end

    local frame = GladiusMidnight.frames[unit]
    if frame and frame.Trinket then
        frame.Trinket.Icon:SetDesaturated(false)
        if frame.Trinket.Cooldown then
            frame.Trinket.Cooldown:Clear()
        end
    end
end

-- Get remaining cooldown for a unit's trinket
function Trinkets:GetRemainingCooldown(unit)
    local cooldownData = self.cooldowns[unit]
    if cooldownData and cooldownData.active then
        local elapsed = GetTime() - cooldownData.startTime
        local remaining = cooldownData.duration - elapsed
        return math.max(0, remaining)
    end
    return 0
end

-- Check if trinket is ready
function Trinkets:IsTrinketReady(unit)
    return self:GetRemainingCooldown(unit) <= 0
end
