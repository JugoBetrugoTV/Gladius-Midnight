--[[
    Gladius Midnight - Trinket Module
    Tracks PvP trinket usage and cooldown
]]

local addonName, addon = ...
local Trinket = {}

-- PvP Trinket spell IDs
local TRINKET_SPELLS = {
    [336126] = true,  -- Gladiator's Medallion
    [336135] = true,  -- Adaptation
    [208683] = true,  -- Gladiator's Medallion (old)
    [195710] = true,  -- Honorable Medallion
    [42292] = true,   -- PvP Trinket (generic)
}

-- ============================================================================
-- Module Registration
-- ============================================================================

function Trinket:OnRegister(core)
    self.core = core
end

function Trinket:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Trinket Elements
-- ============================================================================

function Trinket:CreateElements(frame)
    -- Trinket container
    local container = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0, 0, 0, 0.8)
    container:SetBackdropBorderColor(0, 0, 0, 1)

    -- Icon
    local icon = container:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexture(addon.Data.TrinketIcon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown overlay
    local cooldown = CreateFrame("Cooldown", nil, container, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetDrawSwipe(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(false)

    container.icon = icon
    container.cooldown = cooldown

    -- Tracking data
    container.startTime = 0
    container.duration = 0
    container.onCooldown = false

    frame.moduleFrames.trinket = container
end

-- ============================================================================
-- Update Trinket Display
-- ============================================================================

function Trinket:Update(frame, testData)
    local container = frame.moduleFrames.trinket
    if not container then return end

    local db = self.core.db.profile.trinket

    -- Size and position
    container:SetSize(db.size, db.size)
    container:ClearAllPoints()

    if db.position == "RIGHT" then
        container:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    else
        container:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    end

    -- Reset icon
    container.icon:SetTexture(addon.Data.TrinketIcon)
    container.icon:SetDesaturated(container.onCooldown)

    container:Show()
end

function Trinket:OnSpellCast(frame, spellID)
    if not spellID then return end

    -- Check if it's a trinket spell
    if TRINKET_SPELLS[spellID] then
        self:TriggerCooldown(frame, addon.Data.TrinketCooldown)
        return
    end

    -- Check if it's a trinket-sharing racial (Human, Undead)
    if addon.Data.TrinketShareRacials[spellID] then
        self:TriggerCooldown(frame, 90) -- Shared 90 sec cooldown
    end
end

function Trinket:TriggerCooldown(frame, duration)
    local container = frame.moduleFrames.trinket
    if not container then return end

    container.startTime = GetTime()
    container.duration = duration
    container.onCooldown = true

    container.cooldown:SetCooldown(container.startTime, duration)
    container.icon:SetDesaturated(true)
end

function Trinket:OnUpdate(frame)
    local container = frame.moduleFrames.trinket
    if not container then return end

    -- Check C_PvP API for trinket cooldown (12.0)
    -- This API returns CC break ability info for arena opponents
    if C_PvP and C_PvP.GetArenaCrowdControlInfo and UnitExists(frame.unit) then
        local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(frame.unit)

        -- API returned valid cooldown data
        if spellID and startTime and duration and duration > 0 then
            -- New cooldown detected or updated
            if startTime ~= container.startTime or duration ~= container.duration then
                container.startTime = startTime
                container.duration = duration
                container.onCooldown = true
                container.cooldown:SetCooldown(startTime, duration)
                container.icon:SetDesaturated(true)

                -- Update icon to match the spell used
                local iconTexture = addon.Data.GetSpellIcon(spellID)
                if iconTexture then
                    container.icon:SetTexture(iconTexture)
                end
            end
        end
    end

    -- Check if cooldown expired
    if container.onCooldown and container.startTime > 0 and container.duration > 0 then
        local elapsed = GetTime() - container.startTime
        if elapsed >= container.duration then
            container.onCooldown = false
            container.icon:SetDesaturated(false)
            container.startTime = 0
            container.duration = 0
            -- Reset to default trinket icon
            container.icon:SetTexture(addon.Data.TrinketIcon)
        end
    end
end

function Trinket:Reset(frame)
    local container = frame.moduleFrames.trinket
    if container then
        container.startTime = 0
        container.duration = 0
        container.onCooldown = false
        container.cooldown:Clear()
        container.icon:SetDesaturated(false)
        container.icon:SetTexture(addon.Data.TrinketIcon)
    end
end

-- Register module
addon.Core:RegisterModule("trinket", Trinket)
