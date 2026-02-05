--[[
    Gladius Midnight - DR Tracker Module
    Tracks Diminishing Returns on arena opponents
]]

local addonName, addon = ...
local DRTracker = {}

-- DR Categories
local DR_CATEGORY = {
    STUN = "stun",
    INCAPACITATE = "incapacitate",
    DISORIENT = "disorient",
    SILENCE = "silence",
    ROOT = "root",
    DISARM = "disarm",
    HORROR = "horror",
    KNOCKBACK = "knockback",
}

-- DR Duration (18 seconds in PvP)
local DR_DURATION = 18

-- DR Levels: 100% -> 50% -> 25% -> Immune
local DR_LEVELS = { 1.0, 0.5, 0.25, 0 }

-- Spell ID to DR Category mapping (common PvP CCs)
local DR_SPELLS = {
    -- Stuns
    [408] = DR_CATEGORY.STUN,       -- Kidney Shot
    [1833] = DR_CATEGORY.STUN,      -- Cheap Shot
    [853] = DR_CATEGORY.STUN,       -- Hammer of Justice
    [5211] = DR_CATEGORY.STUN,      -- Mighty Bash
    [22570] = DR_CATEGORY.STUN,     -- Maim
    [30283] = DR_CATEGORY.STUN,     -- Shadowfury
    [46968] = DR_CATEGORY.STUN,     -- Shockwave
    [47481] = DR_CATEGORY.STUN,     -- Gnaw (Ghoul)
    [88625] = DR_CATEGORY.STUN,     -- Holy Word: Chastise
    [89766] = DR_CATEGORY.STUN,     -- Axe Toss (Felguard)
    [91800] = DR_CATEGORY.STUN,     -- Gnaw
    [108194] = DR_CATEGORY.STUN,    -- Asphyxiate
    [119381] = DR_CATEGORY.STUN,    -- Leg Sweep
    [179057] = DR_CATEGORY.STUN,    -- Chaos Nova
    [192058] = DR_CATEGORY.STUN,    -- Capacitor Totem
    [199804] = DR_CATEGORY.STUN,    -- Between the Eyes
    [204399] = DR_CATEGORY.STUN,    -- Earthfury
    [204437] = DR_CATEGORY.STUN,    -- Lightning Lasso
    [211881] = DR_CATEGORY.STUN,    -- Fel Eruption
    [221562] = DR_CATEGORY.STUN,    -- Asphyxiate (Blood)
    [255723] = DR_CATEGORY.STUN,    -- Bull Rush
    [287254] = DR_CATEGORY.STUN,    -- Dead of Winter
    [389831] = DR_CATEGORY.STUN,    -- Snowdrift

    -- Incapacitates
    [6770] = DR_CATEGORY.INCAPACITATE,   -- Sap
    [20066] = DR_CATEGORY.INCAPACITATE,  -- Repentance
    [82691] = DR_CATEGORY.INCAPACITATE,  -- Ring of Frost
    [99] = DR_CATEGORY.INCAPACITATE,     -- Incapacitating Roar
    [115078] = DR_CATEGORY.INCAPACITATE, -- Paralysis
    [118] = DR_CATEGORY.INCAPACITATE,    -- Polymorph
    [1776] = DR_CATEGORY.INCAPACITATE,   -- Gouge
    [28271] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Turtle)
    [28272] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Pig)
    [61025] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Serpent)
    [61305] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Black Cat)
    [61721] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Rabbit)
    [61780] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Turkey)
    [126819] = DR_CATEGORY.INCAPACITATE, -- Polymorph (Porcupine)
    [161353] = DR_CATEGORY.INCAPACITATE, -- Polymorph (Polar Bear)
    [161354] = DR_CATEGORY.INCAPACITATE, -- Polymorph (Monkey)
    [161355] = DR_CATEGORY.INCAPACITATE, -- Polymorph (Penguin)
    [161372] = DR_CATEGORY.INCAPACITATE, -- Polymorph (Peacock)
    [277787] = DR_CATEGORY.INCAPACITATE, -- Polymorph (Direhorn)
    [277792] = DR_CATEGORY.INCAPACITATE, -- Polymorph (Bumblebee)
    [197214] = DR_CATEGORY.INCAPACITATE, -- Sundering
    [200196] = DR_CATEGORY.INCAPACITATE, -- Holy Word: Chastise (Talent)
    [9484] = DR_CATEGORY.INCAPACITATE,   -- Shackle Undead
    [710] = DR_CATEGORY.INCAPACITATE,    -- Banish
    [6358] = DR_CATEGORY.INCAPACITATE,   -- Seduction
    [187650] = DR_CATEGORY.INCAPACITATE, -- Freezing Trap
    [213691] = DR_CATEGORY.INCAPACITATE, -- Scatter Shot
    [360806] = DR_CATEGORY.INCAPACITATE, -- Sleep Walk

    -- Disorients
    [2094] = DR_CATEGORY.DISORIENT,  -- Blind
    [5246] = DR_CATEGORY.DISORIENT,  -- Intimidating Shout
    [8122] = DR_CATEGORY.DISORIENT,  -- Psychic Scream
    [31661] = DR_CATEGORY.DISORIENT, -- Dragon's Breath
    [105421] = DR_CATEGORY.DISORIENT, -- Blinding Light
    [207167] = DR_CATEGORY.DISORIENT, -- Blinding Sleet
    [198909] = DR_CATEGORY.DISORIENT, -- Song of Chi-ji
    [202274] = DR_CATEGORY.DISORIENT, -- Incendiary Brew
    [10326] = DR_CATEGORY.DISORIENT, -- Turn Evil
    [331866] = DR_CATEGORY.DISORIENT, -- Agent of Chaos

    -- Silences
    [15487] = DR_CATEGORY.SILENCE,   -- Silence
    [19647] = DR_CATEGORY.SILENCE,   -- Spell Lock
    [47476] = DR_CATEGORY.SILENCE,   -- Strangulate
    [78675] = DR_CATEGORY.SILENCE,   -- Solar Beam
    [183752] = DR_CATEGORY.SILENCE,  -- Disrupt
    [202137] = DR_CATEGORY.SILENCE,  -- Sigil of Silence
    [351338] = DR_CATEGORY.SILENCE,  -- Quell

    -- Roots
    [339] = DR_CATEGORY.ROOT,        -- Entangling Roots
    [102359] = DR_CATEGORY.ROOT,     -- Mass Entanglement
    [122] = DR_CATEGORY.ROOT,        -- Frost Nova
    [33395] = DR_CATEGORY.ROOT,      -- Freeze (Water Elemental)
    [45334] = DR_CATEGORY.ROOT,      -- Immobilized (Wild Charge)
    [64695] = DR_CATEGORY.ROOT,      -- Earthgrab
    [105771] = DR_CATEGORY.ROOT,     -- Charge
    [116706] = DR_CATEGORY.ROOT,     -- Disable
    [157997] = DR_CATEGORY.ROOT,     -- Ice Nova
    [162480] = DR_CATEGORY.ROOT,     -- Steel Trap
    [190925] = DR_CATEGORY.ROOT,     -- Harpoon
    [198121] = DR_CATEGORY.ROOT,     -- Frostbite
    [212638] = DR_CATEGORY.ROOT,     -- Tracker's Net
    [228600] = DR_CATEGORY.ROOT,     -- Glacial Spike
    [233582] = DR_CATEGORY.ROOT,     -- Entrenched in Flame

    -- Disarms
    [236077] = DR_CATEGORY.DISARM,   -- Disarm

    -- Horrors
    [5484] = DR_CATEGORY.HORROR,     -- Howl of Terror
    [207685] = DR_CATEGORY.HORROR,   -- Sigil of Misery
    [6789] = DR_CATEGORY.HORROR,     -- Mortal Coil
    [87204] = DR_CATEGORY.HORROR,    -- Sin and Punishment
}

-- Category display info
local DR_CATEGORY_INFO = {
    [DR_CATEGORY.STUN] = { icon = "Interface\\Icons\\Spell_Holy_SealOfMight", color = {1, 0.5, 0} },
    [DR_CATEGORY.INCAPACITATE] = { icon = "Interface\\Icons\\Spell_Nature_Polymorph", color = {0.5, 0.5, 1} },
    [DR_CATEGORY.DISORIENT] = { icon = "Interface\\Icons\\Spell_Shadow_MindSteal", color = {1, 1, 0} },
    [DR_CATEGORY.SILENCE] = { icon = "Interface\\Icons\\Spell_Shadow_Impphaseshift", color = {1, 0, 1} },
    [DR_CATEGORY.ROOT] = { icon = "Interface\\Icons\\Spell_Frost_FrostNova", color = {0, 0.5, 1} },
    [DR_CATEGORY.DISARM] = { icon = "Interface\\Icons\\Ability_Warrior_Disarm", color = {0.5, 0.5, 0.5} },
    [DR_CATEGORY.HORROR] = { icon = "Interface\\Icons\\Spell_Shadow_DeathScream", color = {0.5, 0, 0.5} },
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

-- ============================================================================
-- Create DR Tracker Elements
-- ============================================================================

function DRTracker:CreateElements(frame)
    -- Container for DR icons
    local container = CreateFrame("Frame", nil, frame)
    container:SetSize(100, 20)

    -- Store DR tracking data
    container.drData = {}  -- [category] = { level = 1-4, expireTime = time }

    -- Create icon frames for each DR category (max 5 shown)
    container.icons = {}
    for i = 1, 5 do
        local iconFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
        iconFrame:SetSize(20, 20)
        iconFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        iconFrame:SetBackdropColor(0, 0, 0, 0.8)
        iconFrame:SetBackdropBorderColor(0, 0, 0, 1)

        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        iconFrame.icon = icon

        -- Duration text (center, large and readable)
        local text = iconFrame:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        text:SetPoint("CENTER", 0, 0)
        text:SetTextColor(1, 1, 1)
        iconFrame.text = text

        -- DR level text (bottom - shows 1/3, 2/3, 3/3)
        local drLevelText = iconFrame:CreateFontString(nil, "OVERLAY")
        drLevelText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        drLevelText:SetPoint("BOTTOM", 0, 1)
        drLevelText:SetTextColor(1, 0.8, 0)
        iconFrame.drLevelText = drLevelText

        -- Cooldown spiral (optional)
        local cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
        cooldown:SetAllPoints(icon)
        cooldown:SetDrawSwipe(true)
        cooldown:SetDrawEdge(false)
        cooldown:SetHideCountdownNumbers(true)
        iconFrame.cooldown = cooldown

        iconFrame:Hide()
        container.icons[i] = iconFrame
    end

    frame.moduleFrames.drTracker = container
end

-- ============================================================================
-- Update DR Tracker Display
-- ============================================================================

function DRTracker:Update(frame, testData)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    local db = self.core.db.profile.drTracker
    local iconSize = db.iconSize or 24

    -- Position to the LEFT of the frame (ArenaCore style)
    container:ClearAllPoints()
    container:SetPoint("RIGHT", frame, "LEFT", -4, 0)
    container:SetSize(iconSize * 6 + 12, iconSize)

    -- Update icon sizes
    for i, iconFrame in ipairs(container.icons) do
        iconFrame:SetSize(iconSize, iconSize)
    end

    if testData then
        -- Test mode - show some sample DRs
        self:ShowTestDR(frame)
        container:Show()
    else
        -- Only show container if there are active DRs
        local hasActiveDR = false
        local now = GetTime()
        for _, data in pairs(container.drData) do
            if data.expireTime > now then
                hasActiveDR = true
                break
            end
        end

        if hasActiveDR then
            self:RefreshDisplay(frame)
            container:Show()
        else
            -- Hide all icons and container when no active DRs
            for i, iconFrame in ipairs(container.icons) do
                iconFrame:Hide()
            end
            container:Hide()
        end
    end
end

function DRTracker:ShowTestDR(frame)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    local db = self.core.db.profile.drTracker
    local iconSize = db.iconSize or 24

    -- Clear existing
    for i, iconFrame in ipairs(container.icons) do
        iconFrame:Hide()
    end

    -- Show test DRs (ArenaCore style: 1/3, 2/3, 3/3)
    local testCategories = { DR_CATEGORY.STUN, DR_CATEGORY.INCAPACITATE, DR_CATEGORY.ROOT, DR_CATEGORY.SILENCE, DR_CATEGORY.DISORIENT }
    local testLevels = { 2, 3, 4, 2, 3 }
    local testDurations = { 5, 9, 17, 5, 17 }

    for i, category in ipairs(testCategories) do
        local iconFrame = container.icons[i]
        if iconFrame then
            local info = DR_CATEGORY_INFO[category]
            if info then
                iconFrame.icon:SetTexture(info.icon)
                iconFrame:SetBackdropBorderColor(info.color[1], info.color[2], info.color[3], 1)

                -- ArenaCore style: show remaining time on top, DR level below
                local level = testLevels[i]
                iconFrame.text:SetText(testDurations[i])

                if level == 2 then
                    iconFrame.drLevelText:SetText("1/3")
                elseif level == 3 then
                    iconFrame.drLevelText:SetText("2/3")
                elseif level >= 4 then
                    iconFrame.drLevelText:SetText("3/3")
                else
                    iconFrame.drLevelText:SetText("")
                end

                -- Position from RIGHT to LEFT (so icons appear left of frame)
                iconFrame:ClearAllPoints()
                iconFrame:SetPoint("RIGHT", container, "RIGHT", -(i - 1) * (iconSize + 2), 0)
                iconFrame:Show()
            end
        end
    end
end

function DRTracker:ApplyDR(frame, spellID)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    local category = DR_SPELLS[spellID]
    if not category then return end

    local drData = container.drData
    local now = GetTime()

    -- Check existing DR for this category
    if drData[category] and drData[category].expireTime > now then
        -- Increment DR level
        drData[category].level = math.min(drData[category].level + 1, 4)
        drData[category].expireTime = now + DR_DURATION
    else
        -- New DR
        drData[category] = {
            level = 2,  -- First application = 50% next time
            expireTime = now + DR_DURATION,
        }
    end

    self:RefreshDisplay(frame)
end

function DRTracker:RefreshDisplay(frame)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    local db = self.core.db.profile.drTracker
    local iconSize = db.iconSize or 24

    -- Hide all icons first
    for i, iconFrame in ipairs(container.icons) do
        iconFrame:Hide()
        iconFrame.icon:SetDesaturated(false)
    end

    local now = GetTime()
    local drData = container.drData
    local index = 1

    -- Show active DRs
    for category, data in pairs(drData) do
        if data.expireTime > now and index <= 5 then
            local iconFrame = container.icons[index]
            local info = DR_CATEGORY_INFO[category]

            if iconFrame and info then
                iconFrame.icon:SetTexture(info.icon)
                iconFrame:SetBackdropBorderColor(info.color[1], info.color[2], info.color[3], 1)

                -- Show remaining time as main text (ArenaCore style)
                local remaining = data.expireTime - now
                iconFrame.text:SetText(math.ceil(remaining))

                -- Show DR level (1/3, 2/3, 3/3 style)
                if data.level == 2 then
                    iconFrame.drLevelText:SetText("1/3")
                elseif data.level == 3 then
                    iconFrame.drLevelText:SetText("2/3")
                elseif data.level >= 4 then
                    iconFrame.drLevelText:SetText("3/3")
                    iconFrame.icon:SetDesaturated(true)
                else
                    iconFrame.drLevelText:SetText("")
                end

                -- Show cooldown timer
                iconFrame.cooldown:SetCooldown(now - (DR_DURATION - remaining), DR_DURATION)

                -- Position from RIGHT to LEFT
                iconFrame:ClearAllPoints()
                iconFrame:SetPoint("RIGHT", container, "RIGHT", -(index - 1) * (iconSize + 2), 0)
                iconFrame:Show()

                index = index + 1
            end
        end
    end
end

function DRTracker:OnUpdate(frame)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    local now = GetTime()
    local drData = container.drData
    local needsRefresh = false
    local hasActiveDR = false

    -- Check for expired DRs and update timers
    for category, data in pairs(drData) do
        if data.expireTime <= now then
            drData[category] = nil
            needsRefresh = true
        else
            hasActiveDR = true
        end
    end

    if needsRefresh or hasActiveDR then
        self:RefreshDisplay(frame)
    end

    -- Hide container if no active DRs
    if not hasActiveDR then
        for i, iconFrame in ipairs(container.icons) do
            iconFrame:Hide()
        end
        container:Hide()
    end
end

-- Called when UNIT_AURA fires for arena units
function DRTracker:OnAura(frame, spellID)
    if not spellID then return end

    -- Check if this is a DR spell
    if DR_SPELLS[spellID] then
        self:ApplyDR(frame, spellID)
    end
end

function DRTracker:Reset(frame)
    local container = frame.moduleFrames.drTracker
    if container then
        container.drData = {}
        for i, iconFrame in ipairs(container.icons) do
            iconFrame:Hide()
            iconFrame.icon:SetDesaturated(false)
            iconFrame.text:SetText("")
            iconFrame.drLevelText:SetText("")
        end
    end
end

-- Expose DR_SPELLS for external use
addon.Data.DR_SPELLS = DR_SPELLS

-- Register module
addon.Core:RegisterModule("drTracker", DRTracker)
