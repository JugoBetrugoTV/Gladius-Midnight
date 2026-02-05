--[[
    Gladius Midnight - Kicks Module
    Tracks enemy interrupt cooldowns
]]

local addonName, addon = ...
local Kicks = {}

-- Interrupt spell IDs and their cooldowns
local INTERRUPT_SPELLS = {
    -- Death Knight
    [47528] = 15,    -- Mind Freeze

    -- Demon Hunter
    [183752] = 15,   -- Disrupt

    -- Druid
    [106839] = 15,   -- Skull Bash
    [78675] = 60,    -- Solar Beam

    -- Evoker
    [351338] = 40,   -- Quell

    -- Hunter
    [147362] = 24,   -- Counter Shot
    [187707] = 15,   -- Muzzle

    -- Mage
    [2139] = 24,     -- Counterspell

    -- Monk
    [116705] = 15,   -- Spear Hand Strike

    -- Paladin
    [96231] = 15,    -- Rebuke

    -- Priest
    [15487] = 45,    -- Silence

    -- Rogue
    [1766] = 15,     -- Kick

    -- Shaman
    [57994] = 12,    -- Wind Shear

    -- Warlock
    [19647] = 24,    -- Spell Lock (Felhunter)
    [89766] = 30,    -- Axe Toss (Felguard)
    [119910] = 24,   -- Spell Lock (Command Demon)
    [132409] = 24,   -- Spell Lock (Grimoire)

    -- Warrior
    [6552] = 15,     -- Pummel
}

-- ============================================================================
-- Module Registration
-- ============================================================================

function Kicks:OnRegister(core)
    self.core = core
end

function Kicks:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Kick Tracker Elements
-- ============================================================================

function Kicks:CreateElements(frame)
    -- Kick bar container
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
    icon:SetTexture("Interface\\Icons\\Ability_Kick")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    container.icon = icon

    -- Cooldown overlay
    local cooldown = CreateFrame("Cooldown", nil, container, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetDrawSwipe(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(false)
    container.cooldown = cooldown

    -- Track state
    container.spellID = nil
    container.startTime = 0
    container.duration = 0
    container.onCooldown = false

    frame.moduleFrames.kicks = container
end

-- ============================================================================
-- Update Kick Display
-- ============================================================================

function Kicks:Update(frame, testData)
    local container = frame.moduleFrames.kicks
    if not container then return end

    local db = self.core.db.profile.kicks
    local size = db.size or 22

    -- Position below racial (or trinket if no racial)
    container:SetSize(size, size)
    container:ClearAllPoints()

    local racialFrame = frame.moduleFrames.racial
    local trinketFrame = frame.moduleFrames.trinket

    if racialFrame and self.core:IsModuleEnabled("racial") then
        container:SetPoint("TOP", racialFrame, "BOTTOM", 0, -2)
    elseif trinketFrame and self.core:IsModuleEnabled("trinket") then
        container:SetPoint("TOP", trinketFrame, "BOTTOM", 0, -2)
    else
        container:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    end

    if testData then
        -- Test mode - show kick on CD
        container.icon:SetTexture("Interface\\Icons\\Ability_Kick")
        container.cooldown:SetCooldown(GetTime() - 8, 15)
        container.icon:SetDesaturated(true)
    end

    container.icon:SetDesaturated(container.onCooldown)
    container:Show()
end

function Kicks:OnSpellCast(frame, spellID)
    if not spellID then return end

    local cooldown = INTERRUPT_SPELLS[spellID]
    if not cooldown then return end

    local container = frame.moduleFrames.kicks
    if not container then return end

    -- Update icon to match the interrupt used
    local iconTexture = addon.Data.GetSpellIcon(spellID)
    if iconTexture then
        container.icon:SetTexture(iconTexture)
    end

    container.spellID = spellID
    container.startTime = GetTime()
    container.duration = cooldown
    container.onCooldown = true

    container.cooldown:SetCooldown(container.startTime, cooldown)
    container.icon:SetDesaturated(true)
end

function Kicks:OnUpdate(frame)
    local container = frame.moduleFrames.kicks
    if not container or not container.onCooldown then return end

    -- Check if cooldown expired
    if container.startTime > 0 and container.duration > 0 then
        local elapsed = GetTime() - container.startTime
        if elapsed >= container.duration then
            container.onCooldown = false
            container.icon:SetDesaturated(false)
            container.startTime = 0
            container.duration = 0
            -- Reset to default kick icon
            container.icon:SetTexture("Interface\\Icons\\Ability_Kick")
        end
    end
end

function Kicks:Reset(frame)
    local container = frame.moduleFrames.kicks
    if container then
        container.spellID = nil
        container.startTime = 0
        container.duration = 0
        container.onCooldown = false
        container.cooldown:Clear()
        container.icon:SetDesaturated(false)
        container.icon:SetTexture("Interface\\Icons\\Ability_Kick")
    end
end

-- Expose interrupt spells
addon.Data.INTERRUPT_SPELLS = INTERRUPT_SPELLS

-- Register module
addon.Core:RegisterModule("kicks", Kicks)
