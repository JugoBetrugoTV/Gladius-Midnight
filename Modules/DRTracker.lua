--[[
    Gladius Midnight - DR Tracker Module
    Tracks Diminishing Returns on arena opponents

    For Midnight 12.0: Uses Blizzard's SpellDiminishStatusTray by reparenting it
    (same approach as sArena_Reloaded - secret values are handled by Blizzard's frames)
]]

local addonName, addon = ...
local DRTracker = {}

-- DR Categories (for test mode and fallback)
local DR_CATEGORY = {
    STUN = "stun",
    INCAPACITATE = "incapacitate",
    DISORIENT = "disorient",
    SILENCE = "silence",
    ROOT = "root",
    DISARM = "disarm",
}

-- DR Duration (18 seconds in retail PvP)
local DR_DURATION = 18

-- Spell ID to DR Category mapping (used for fallback/test mode)
local DR_SPELLS = {
    -- STUNS
    [408] = DR_CATEGORY.STUN,        -- Kidney Shot
    [1833] = DR_CATEGORY.STUN,       -- Cheap Shot
    [853] = DR_CATEGORY.STUN,        -- Hammer of Justice
    [5211] = DR_CATEGORY.STUN,       -- Mighty Bash
    [119381] = DR_CATEGORY.STUN,     -- Leg Sweep
    [179057] = DR_CATEGORY.STUN,     -- Chaos Nova
    [46968] = DR_CATEGORY.STUN,      -- Shockwave
    [255941] = DR_CATEGORY.STUN,     -- Wake of Ashes
    [20549] = DR_CATEGORY.STUN,      -- War Stomp

    -- INCAPACITATES
    [6770] = DR_CATEGORY.INCAPACITATE,    -- Sap
    [118] = DR_CATEGORY.INCAPACITATE,     -- Polymorph
    [51514] = DR_CATEGORY.INCAPACITATE,   -- Hex
    [20066] = DR_CATEGORY.INCAPACITATE,   -- Repentance
    [3355] = DR_CATEGORY.INCAPACITATE,    -- Freezing Trap
    [115078] = DR_CATEGORY.INCAPACITATE,  -- Paralysis
    [217832] = DR_CATEGORY.INCAPACITATE,  -- Imprison

    -- DISORIENTS
    [2094] = DR_CATEGORY.DISORIENT,   -- Blind
    [5246] = DR_CATEGORY.DISORIENT,   -- Intimidating Shout
    [8122] = DR_CATEGORY.DISORIENT,   -- Psychic Scream
    [33786] = DR_CATEGORY.DISORIENT,  -- Cyclone
    [118699] = DR_CATEGORY.DISORIENT, -- Fear
    [207685] = DR_CATEGORY.DISORIENT, -- Sigil of Misery

    -- SILENCES
    [15487] = DR_CATEGORY.SILENCE,    -- Silence
    [1330] = DR_CATEGORY.SILENCE,     -- Garrote
    [47476] = DR_CATEGORY.SILENCE,    -- Strangulate
    [204490] = DR_CATEGORY.SILENCE,   -- Sigil of Silence

    -- ROOTS
    [339] = DR_CATEGORY.ROOT,         -- Entangling Roots
    [122] = DR_CATEGORY.ROOT,         -- Frost Nova
    [102359] = DR_CATEGORY.ROOT,      -- Mass Entanglement
    [116706] = DR_CATEGORY.ROOT,      -- Disable
}

-- Category display info (for test mode)
local DR_CATEGORY_INFO = {
    [DR_CATEGORY.STUN] = { icon = "Interface\\Icons\\Ability_Rogue_KidneyShot", color = {1, 0.5, 0} },
    [DR_CATEGORY.INCAPACITATE] = { icon = "Interface\\Icons\\Spell_Nature_Polymorph", color = {0.5, 0.5, 1} },
    [DR_CATEGORY.DISORIENT] = { icon = "Interface\\Icons\\Spell_Shadow_MindSteal", color = {1, 1, 0} },
    [DR_CATEGORY.SILENCE] = { icon = "Interface\\Icons\\Ability_Priest_Silence", color = {1, 0, 1} },
    [DR_CATEGORY.ROOT] = { icon = "Interface\\Icons\\Spell_Frost_FrostNova", color = {0, 0.7, 1} },
    [DR_CATEGORY.DISARM] = { icon = "Interface\\Icons\\Ability_Warrior_Disarm", color = {0.6, 0.6, 0.6} },
}

-- ============================================================================
-- Module Registration
-- ============================================================================

function DRTracker:OnRegister(core)
    self.core = core
end

function DRTracker:OnInitialize(core)
    self.core = core
end

function DRTracker:OnEnable(core)
    self.core = core
end

function DRTracker:OnDisable(core)
end

-- ============================================================================
-- Create DR Tracker Elements
-- ============================================================================

function DRTracker:CreateElements(frame)
    -- Container for DR display (positioned to left of arena frame)
    local container = CreateFrame("Frame", "GladiusMidnightDR" .. frame.index, UIParent, "BackdropTemplate")
    container:SetSize(90, 30)
    container:SetFrameStrata("MEDIUM")
    container:SetFrameLevel(10)

    container.arenaFrame = frame
    container.blizzardDRInitialized = false
    container.drData = {}  -- For fallback tracking

    -- We'll create our own icon frames for test mode and fallback
    container.icons = {}
    for i = 1, 4 do
        local iconFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
        iconFrame:SetSize(28, 28)
        iconFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        iconFrame:SetBackdropColor(0, 0, 0, 0.8)
        iconFrame:SetBackdropBorderColor(0, 0, 0, 1)

        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", -2, 2)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        iconFrame.icon = icon

        -- DR level text (centered)
        local drLevelText = iconFrame:CreateFontString(nil, "OVERLAY")
        drLevelText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        drLevelText:SetPoint("CENTER", 0, 0)
        drLevelText:SetTextColor(1, 1, 1)
        iconFrame.drLevelText = drLevelText

        -- Cooldown spiral
        local cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
        cooldown:SetAllPoints(icon)
        cooldown:SetDrawSwipe(true)
        cooldown:SetDrawEdge(false)
        cooldown:SetHideCountdownNumbers(true)
        cooldown.noCooldownCount = true
        cooldown.noOCC = true
        iconFrame.cooldown = cooldown

        iconFrame:Hide()
        container.icons[i] = iconFrame
    end

    container:Hide()
    frame.moduleFrames.drTracker = container
end

-- ============================================================================
-- Initialize Blizzard DR Frames (Midnight 12.0 approach from sArena)
-- ============================================================================

function DRTracker:InitializeBlizzardDR(frame, blizzArenaFrame)
    local container = frame.moduleFrames.drTracker
    if not container or container.blizzardDRInitialized then return end

    local drTray = blizzArenaFrame and blizzArenaFrame.SpellDiminishStatusTray
    if not drTray then return end

    local db = self.core.db.profile.drTracker
    local iconSize = db.iconSize or 28

    -- Reparent Blizzard's DR tray to our container
    drTray:SetParent(container)
    drTray:SetFrameStrata("MEDIUM")
    drTray:SetFrameLevel(11)
    drTray:EnableMouse(false)
    if drTray.SetMouseClickEnabled then
        drTray:SetMouseClickEnabled(false)
    end
    drTray:SetAlpha(1)
    drTray:ClearAllPoints()
    drTray:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    drTray:Show()

    container.blizzDRTray = drTray

    -- Get the DR frames from the tray
    local drFrames = {drTray:GetChildren()}
    container.blizzDRFrames = drFrames

    -- Style each DR frame
    for drIndex, drFrame in ipairs(drFrames) do
        if drFrame and drFrame.Icon then
            drFrame:SetFrameStrata("MEDIUM")
            drFrame:SetFrameLevel(12)
            drFrame:SetAlpha(1)
            drFrame:EnableMouse(false)
            if drFrame.SetMouseClickEnabled then
                drFrame:SetMouseClickEnabled(false)
            end

            -- Make icon visible
            drFrame.Icon:Show()
            drFrame.Icon:SetAlpha(1)

            -- Create our custom border overlay (sArena style)
            if not drFrame.gladiusBorder then
                drFrame.gladiusBorder = drFrame:CreateTexture(nil, "OVERLAY", nil, 6)
                drFrame.gladiusBorder:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                drFrame.gladiusBorder:SetAllPoints(drFrame)
                drFrame.gladiusBorder:SetVertexColor(0, 1, 0, 1)
            end

            -- Create DR level text overlay
            if not drFrame.gladiusDRText then
                local textFrame = CreateFrame("Frame", nil, drFrame)
                textFrame:SetAllPoints(drFrame)
                textFrame:SetFrameStrata("MEDIUM")
                textFrame:SetFrameLevel(26)

                local drText = textFrame:CreateFontString(nil, "OVERLAY")
                drText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
                drText:SetPoint("BOTTOMRIGHT", 2, -2)
                drText:SetTextColor(0, 1, 0)
                drText:SetText("")

                drFrame.gladiusDRText = drText
                drFrame.gladiusDRTextFrame = textFrame
            end

            -- Create immune indicator text
            if not drFrame.gladiusImmuneText and drFrame.ImmunityIndicator then
                local immuneText = drFrame.ImmunityIndicator:CreateFontString(nil, "OVERLAY")
                immuneText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
                immuneText:SetPoint("CENTER", 0, 0)
                immuneText:SetTextColor(1, 0, 0)
                immuneText:SetText("X")
                immuneText:SetIgnoreParentAlpha(true)
                drFrame.gladiusImmuneText = immuneText

                -- Hook ImmunityIndicator to update our display
                if drFrame.ImmunityIndicator.SetShown then
                    hooksecurefunc(drFrame.ImmunityIndicator, "SetShown", function(_, shown)
                        if shown then
                            drFrame.gladiusBorder:SetVertexColor(1, 0, 0, 1)
                            if drFrame.gladiusDRText then
                                drFrame.gladiusDRText:SetText("")
                            end
                        end
                    end)
                end
            end

            -- Hook to track DR severity and update border color
            if drFrame.Cooldown and not drFrame.gladiusCooldownHooked then
                drFrame.gladiusCooldownHooked = true
                drFrame.gladiusSeverity = 0

                hooksecurefunc(drFrame.Cooldown, "SetCooldown", function(_, start, duration)
                    if start and start > 0 and duration and duration > 0 then
                        -- DR applied - increment severity
                        drFrame.gladiusSeverity = (drFrame.gladiusSeverity or 0) + 1
                        if drFrame.gladiusSeverity > 3 then
                            drFrame.gladiusSeverity = 3
                        end

                        -- Update border color and text based on severity
                        if drFrame.gladiusSeverity == 1 then
                            drFrame.gladiusBorder:SetVertexColor(0, 1, 0, 1)
                            if drFrame.gladiusDRText then
                                drFrame.gladiusDRText:SetText("½")
                                drFrame.gladiusDRText:SetTextColor(0, 1, 0)
                            end
                        elseif drFrame.gladiusSeverity == 2 then
                            drFrame.gladiusBorder:SetVertexColor(1, 0.5, 0, 1)
                            if drFrame.gladiusDRText then
                                drFrame.gladiusDRText:SetText("¼")
                                drFrame.gladiusDRText:SetTextColor(1, 0.5, 0)
                            end
                        else
                            drFrame.gladiusBorder:SetVertexColor(1, 0, 0, 1)
                            if drFrame.gladiusDRText then
                                drFrame.gladiusDRText:SetText("X")
                                drFrame.gladiusDRText:SetTextColor(1, 0, 0)
                            end
                        end
                    end
                end)

                -- Hook Clear to reset severity
                if drFrame.Cooldown.Clear then
                    hooksecurefunc(drFrame.Cooldown, "Clear", function()
                        drFrame.gladiusSeverity = 0
                        drFrame.gladiusBorder:SetVertexColor(0, 1, 0, 1)
                        if drFrame.gladiusDRText then
                            drFrame.gladiusDRText:SetText("")
                        end
                    end)
                end
            end
        end
    end

    container.blizzardDRInitialized = true
    container:Show()
end

-- ============================================================================
-- Update DR Tracker Display
-- ============================================================================

function DRTracker:Update(frame, testData)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    local db = self.core.db.profile.drTracker
    local iconSize = db.iconSize or 28

    -- Position to the LEFT of the arena frame (horizontal row, growing left)
    container:ClearAllPoints()
    container:SetPoint("RIGHT", frame, "LEFT", -4, 0)
    container:SetSize(iconSize * 4 + 12, iconSize)

    -- Update Blizzard DR tray positioning if initialized
    if container.blizzDRTray then
        container.blizzDRTray:ClearAllPoints()
        container.blizzDRTray:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    end

    -- Update individual Blizzard DR frames
    if container.blizzDRFrames then
        local spacing = 4
        for i, drFrame in ipairs(container.blizzDRFrames) do
            if drFrame then
                drFrame:SetSize(iconSize, iconSize)
                drFrame:ClearAllPoints()
                drFrame:SetPoint("RIGHT", container, "RIGHT", -(i - 1) * (iconSize + spacing), 0)

                if drFrame.Icon then
                    drFrame.Icon:SetSize(iconSize - 4, iconSize - 4)
                end

                -- Update border size
                if drFrame.gladiusBorder then
                    drFrame.gladiusBorder:SetAllPoints(drFrame)
                end
            end
        end
    end

    -- Update our fallback icon sizes
    for i, iconFrame in ipairs(container.icons) do
        iconFrame:SetSize(iconSize, iconSize)
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint("RIGHT", container, "RIGHT", -(i - 1) * (iconSize + 4), 0)
    end

    if testData then
        self:ShowTestDR(frame)
        container:Show()
        return
    end

    -- In live mode, Blizzard DR tray handles display if initialized
    if container.blizzardDRInitialized then
        container:Show()
    else
        self:RefreshDisplay(frame)
    end
end

function DRTracker:ShowTestDR(frame)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    -- Hide Blizzard frames for test mode
    if container.blizzDRTray then
        container.blizzDRTray:Hide()
    end

    -- Show our test DR icons
    for _, iconFrame in ipairs(container.icons) do
        iconFrame:Hide()
    end

    local testCategories = { DR_CATEGORY.STUN, DR_CATEGORY.INCAPACITATE, DR_CATEGORY.ROOT }
    local testLevels = { 1, 2, 3 }

    for i, category in ipairs(testCategories) do
        local iconFrame = container.icons[i]
        if iconFrame then
            local info = DR_CATEGORY_INFO[category]
            if info then
                iconFrame.icon:SetTexture(info.icon)

                local level = testLevels[i]
                if level == 1 then
                    iconFrame:SetBackdropBorderColor(0, 1, 0, 1)
                    iconFrame.drLevelText:SetText("½")
                    iconFrame.drLevelText:SetTextColor(0, 1, 0)
                    iconFrame.icon:SetDesaturated(false)
                elseif level == 2 then
                    iconFrame:SetBackdropBorderColor(1, 0.5, 0, 1)
                    iconFrame.drLevelText:SetText("¼")
                    iconFrame.drLevelText:SetTextColor(1, 0.5, 0)
                    iconFrame.icon:SetDesaturated(false)
                else
                    iconFrame:SetBackdropBorderColor(1, 0, 0, 1)
                    iconFrame.drLevelText:SetText("X")
                    iconFrame.drLevelText:SetTextColor(1, 0, 0)
                    iconFrame.icon:SetDesaturated(true)
                end

                iconFrame.cooldown:SetCooldown(GetTime() - math.random(5, 15), DR_DURATION)
                iconFrame:Show()
            end
        end
    end

    container:Show()
end

-- ============================================================================
-- Fallback DR Tracking (Combat Log based)
-- ============================================================================

function DRTracker:OnCombatLogEvent()
    if self.core.testMode then return end

    local _, subEvent, _, _, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()

    if subEvent ~= "SPELL_AURA_APPLIED" and subEvent ~= "SPELL_AURA_REFRESH" then
        return
    end

    local category = DR_SPELLS[spellID]
    if not category then return end

    -- Find which arena unit this GUID belongs to
    for i = 1, 3 do
        local unit = "arena" .. i
        if UnitExists(unit) and UnitGUID(unit) == destGUID then
            local frame = self.core.frames[i]
            if frame then
                self:ApplyDR(frame, category, spellID)
            end
            break
        end
    end
end

function DRTracker:ApplyDR(frame, category, spellID)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    -- Skip if Blizzard DR is handling it
    if container.blizzardDRInitialized then return end

    local drData = container.drData
    local now = GetTime()

    local spellIcon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
    if not spellIcon then
        spellIcon = GetSpellTexture and GetSpellTexture(spellID)
    end
    if not spellIcon then
        local info = DR_CATEGORY_INFO[category]
        spellIcon = info and info.icon
    end

    if drData[category] and drData[category].expireTime > now then
        drData[category].level = math.min(drData[category].level + 1, 3)
        drData[category].expireTime = now + DR_DURATION
        drData[category].spellIcon = spellIcon or drData[category].spellIcon
    else
        drData[category] = {
            level = 1,
            expireTime = now + DR_DURATION,
            spellIcon = spellIcon,
        }
    end

    self:RefreshDisplay(frame)
end

function DRTracker:RefreshDisplay(frame)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    -- Skip if Blizzard DR is handling it
    if container.blizzardDRInitialized then return end

    for _, iconFrame in ipairs(container.icons) do
        iconFrame:Hide()
        iconFrame.icon:SetDesaturated(false)
    end

    local now = GetTime()
    local drData = container.drData
    local index = 1
    local hasActiveDR = false

    for category, data in pairs(drData) do
        if data.expireTime > now and index <= 4 then
            hasActiveDR = true
            local iconFrame = container.icons[index]
            local info = DR_CATEGORY_INFO[category]

            if iconFrame and info then
                iconFrame.icon:SetTexture(data.spellIcon or info.icon)

                local remaining = data.expireTime - now

                if data.level == 1 then
                    iconFrame:SetBackdropBorderColor(0, 1, 0, 1)
                    iconFrame.drLevelText:SetText("½")
                    iconFrame.drLevelText:SetTextColor(0, 1, 0)
                    iconFrame.icon:SetDesaturated(false)
                elseif data.level == 2 then
                    iconFrame:SetBackdropBorderColor(1, 0.5, 0, 1)
                    iconFrame.drLevelText:SetText("¼")
                    iconFrame.drLevelText:SetTextColor(1, 0.5, 0)
                    iconFrame.icon:SetDesaturated(false)
                else
                    iconFrame:SetBackdropBorderColor(1, 0, 0, 1)
                    iconFrame.drLevelText:SetText("X")
                    iconFrame.drLevelText:SetTextColor(1, 0, 0)
                    iconFrame.icon:SetDesaturated(true)
                end

                iconFrame.cooldown:SetCooldown(now - (DR_DURATION - remaining), DR_DURATION)
                iconFrame:Show()

                index = index + 1
            end
        end
    end

    if hasActiveDR then
        container:Show()
    else
        container:Hide()
    end
end

function DRTracker:OnUpdate(frame)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    -- Skip cleanup if Blizzard DR is handling it
    if container.blizzardDRInitialized then return end

    local now = GetTime()
    local drData = container.drData
    local needsRefresh = false

    for category, data in pairs(drData) do
        if data.expireTime <= now then
            drData[category] = nil
            needsRefresh = true
        end
    end

    if needsRefresh then
        self:RefreshDisplay(frame)
    end
end

-- ============================================================================
-- External Callbacks
-- ============================================================================

function DRTracker:OnBlizzardDR(frame, spellID)
    if not spellID or type(spellID) ~= "number" then return end

    local category = DR_SPELLS[spellID]
    if category then
        self:ApplyDR(frame, category, spellID)
    end
end

function DRTracker:OnAura(frame, spellID)
    if not spellID or type(spellID) ~= "number" then return end

    local category = DR_SPELLS[spellID]
    if category then
        self:ApplyDR(frame, category, spellID)
    end
end

-- ============================================================================
-- Reset
-- ============================================================================

function DRTracker:Reset(frame)
    local container = frame.moduleFrames.drTracker
    if container then
        container.drData = {}

        for _, iconFrame in ipairs(container.icons) do
            iconFrame:Hide()
            iconFrame.icon:SetDesaturated(false)
            iconFrame.drLevelText:SetText("")
        end

        -- Reset Blizzard DR frames severity
        if container.blizzDRFrames then
            for _, drFrame in ipairs(container.blizzDRFrames) do
                if drFrame then
                    drFrame.gladiusSeverity = 0
                    if drFrame.gladiusBorder then
                        drFrame.gladiusBorder:SetVertexColor(0, 1, 0, 1)
                    end
                    if drFrame.gladiusDRText then
                        drFrame.gladiusDRText:SetText("")
                    end
                end
            end
        end

        container:Hide()
    end
end

-- For external use
addon.Data = addon.Data or {}
addon.Data.DR_SPELLS = DR_SPELLS

-- Register module
addon.Core:RegisterModule("drTracker", DRTracker)
