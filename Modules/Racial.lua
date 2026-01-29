--[[
    Gladius Midnight - Racial Module
    Tracks racial ability usage and cooldowns
]]

local addonName, addon = ...
local Racial = {}

-- ============================================================================
-- Module Registration
-- ============================================================================

function Racial:OnRegister(core)
    self.core = core
end

function Racial:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Racial Elements
-- ============================================================================

function Racial:CreateElements(frame)
    -- Racial container
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
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
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
    container.spellID = nil
    container.startTime = 0
    container.duration = 0
    container.onCooldown = false

    frame.moduleFrames.racial = container
end

-- ============================================================================
-- Update Racial Display
-- ============================================================================

function Racial:Update(frame, testData)
    local container = frame.moduleFrames.racial
    if not container then return end

    local db = self.core.db.profile.racial
    local trinketDb = self.core.db.profile.trinket

    -- Size and position (below trinket if both enabled)
    container:SetSize(db.size, db.size)
    container:ClearAllPoints()

    local trinketFrame = frame.moduleFrames.trinket
    if trinketFrame and self.core:IsModuleEnabled("trinket") then
        container:SetPoint("TOP", trinketFrame, "BOTTOM", 0, -2)
    else
        if db.position == "RIGHT" then
            container:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
        else
            container:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        end
    end

    -- Keep current icon state
    container.icon:SetDesaturated(container.onCooldown)

    container:Show()
end

function Racial:OnSpellCast(frame, spellID)
    if not spellID then return end

    -- Check if it's a tracked racial
    local cooldown = addon.Data.RacialCooldowns[spellID]
    if not cooldown then return end

    local container = frame.moduleFrames.racial
    if not container then return end

    container.spellID = spellID
    container.startTime = GetTime()
    container.duration = cooldown
    container.onCooldown = true

    -- Update icon
    local iconTexture = addon.Data.GetSpellIcon(spellID)
    if iconTexture then
        container.icon:SetTexture(iconTexture)
    end

    container.cooldown:SetCooldown(container.startTime, cooldown)
    container.icon:SetDesaturated(true)

    -- Also trigger trinket cooldown for certain racials
    if addon.Data.TrinketShareRacials[spellID] then
        local trinketModule = self.core:GetModule("trinket")
        if trinketModule and self.core:IsModuleEnabled("trinket") then
            trinketModule:TriggerCooldown(frame, 90)
        end
    end
end

function Racial:OnUpdate(frame)
    local container = frame.moduleFrames.racial
    if not container or not container.onCooldown then return end

    -- Check if cooldown expired
    if container.startTime > 0 and container.duration > 0 then
        local elapsed = GetTime() - container.startTime
        if elapsed >= container.duration then
            container.onCooldown = false
            container.icon:SetDesaturated(false)
            container.startTime = 0
            container.duration = 0
        end
    end
end

function Racial:Reset(frame)
    local container = frame.moduleFrames.racial
    if container then
        container.spellID = nil
        container.startTime = 0
        container.duration = 0
        container.onCooldown = false
        container.cooldown:Clear()
        container.icon:SetDesaturated(false)
        container.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
end

-- Register module
addon.Core:RegisterModule("racial", Racial)
