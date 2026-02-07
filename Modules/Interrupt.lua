--[[
    Gladius Midnight - Interrupt Module
    Tracks interrupt cooldowns on arena opponents.
]]

local addonName, addon = ...
local Interrupt = {}

-- ============================================================================
-- Module Registration
-- ============================================================================

function Interrupt:OnRegister(core)
    self.core = core
end

function Interrupt:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Interrupt Elements
-- ============================================================================

function Interrupt:CreateElements(frame)
    local container = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0, 0, 0, 0.8)
    container:SetBackdropBorderColor(0, 0, 0, 1)

    local icon = container:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexture("Interface\\Icons\\Ability_Kick")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local cooldown = CreateFrame("Cooldown", nil, container, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetDrawSwipe(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(false)

    container.icon = icon
    container.cooldown = cooldown
    container.startTime = 0
    container.duration = 0
    container.onCooldown = false

    frame.moduleFrames.interrupt = container
end

-- ============================================================================
-- Update Interrupt Display
-- ============================================================================

function Interrupt:Update(frame, testData)
    local container = frame.moduleFrames.interrupt
    if not container then return end

    local db = self.core.db.profile.interrupt

    container:SetSize(db.size, db.size)
    container:ClearAllPoints()

    if db.position == "RIGHT" then
        local trinketFrame = frame.moduleFrames.trinket
        if trinketFrame and self.core:IsModuleEnabled("trinket") then
            container:SetPoint("TOP", trinketFrame, "BOTTOM", 0, -2)
        else
            container:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
        end
    else
        container:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    end

    if testData and testData.isTarget then
        container.icon:SetTexture("Interface\\Icons\\Ability_Kick")
        container.icon:SetDesaturated(true)
        container.cooldown:SetCooldown(GetTime(), 10)
    end

    container:Show()
end

function Interrupt:OnSpellCast(frame, spellID)
    -- In Midnight 12.0, spellID may be "secret" for arena opponents
    if not spellID or type(spellID) ~= "number" then return end

    local cooldownDuration = addon.Data.InterruptSpells[spellID]
    if not cooldownDuration then return end

    local container = frame.moduleFrames.interrupt
    if not container then return end

    local iconTexture = addon.Data.GetSpellIcon(spellID)
    if iconTexture then
        container.icon:SetTexture(iconTexture)
    end

    container.startTime = GetTime()
    container.duration = cooldownDuration
    container.onCooldown = true
    container.icon:SetDesaturated(true)
    container.cooldown:SetCooldown(container.startTime, cooldownDuration)
end

function Interrupt:Reset(frame)
    local container = frame.moduleFrames.interrupt
    if container then
        container.startTime = 0
        container.duration = 0
        container.onCooldown = false
        container.icon:SetDesaturated(false)
        container.icon:SetTexture("Interface\\Icons\\Ability_Kick")
        container.cooldown:Clear()
    end
end

-- Register module
addon.Core:RegisterModule("interrupt", Interrupt)
