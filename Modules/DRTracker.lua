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

-- DR Duration (18.5 seconds in retail PvP - ArenaCore value)
local DR_DURATION = 18.5

-- DR Levels: 100% -> 50% -> 25% -> Immune
local DR_LEVELS = { 1.0, 0.5, 0.25, 0 }

-- Spell ID to DR Category mapping (comprehensive list from ArenaCore)
local DR_SPELLS = {
    -- =============================================
    -- STUNS
    -- =============================================
    [408] = DR_CATEGORY.STUN,        -- Kidney Shot
    [1833] = DR_CATEGORY.STUN,       -- Cheap Shot
    [853] = DR_CATEGORY.STUN,        -- Hammer of Justice
    [5211] = DR_CATEGORY.STUN,       -- Mighty Bash
    [203123] = DR_CATEGORY.STUN,     -- Maim
    [163505] = DR_CATEGORY.STUN,     -- Rake (from Prowl)
    [30283] = DR_CATEGORY.STUN,      -- Shadowfury
    [46968] = DR_CATEGORY.STUN,      -- Shockwave
    [132168] = DR_CATEGORY.STUN,     -- Shockwave (Protection)
    [132169] = DR_CATEGORY.STUN,     -- Storm Bolt
    [89766] = DR_CATEGORY.STUN,      -- Axe Toss (Felguard)
    [91800] = DR_CATEGORY.STUN,      -- Gnaw (Ghoul)
    [91797] = DR_CATEGORY.STUN,      -- Monstrous Blow (Mutated Ghoul)
    [108194] = DR_CATEGORY.STUN,     -- Asphyxiate (Unholy)
    [221562] = DR_CATEGORY.STUN,     -- Asphyxiate (Blood)
    [119381] = DR_CATEGORY.STUN,     -- Leg Sweep
    [458605] = DR_CATEGORY.STUN,     -- Leg Sweep (2)
    [179057] = DR_CATEGORY.STUN,     -- Chaos Nova
    [211881] = DR_CATEGORY.STUN,     -- Fel Eruption
    [200166] = DR_CATEGORY.STUN,     -- Metamorphosis stun
    [205630] = DR_CATEGORY.STUN,     -- Illidan's Grasp
    [208618] = DR_CATEGORY.STUN,     -- Illidan's Grasp (secondary)
    [118905] = DR_CATEGORY.STUN,     -- Static Charge (Capacitor Totem)
    [118345] = DR_CATEGORY.STUN,     -- Pulverize (Earth Elemental)
    [305485] = DR_CATEGORY.STUN,     -- Lightning Lasso
    [255941] = DR_CATEGORY.STUN,     -- Wake of Ashes
    [64044] = DR_CATEGORY.STUN,      -- Psychic Horror
    [200200] = DR_CATEGORY.STUN,     -- Holy Word: Chastise (Censure)
    [117526] = DR_CATEGORY.STUN,     -- Binding Shot
    [357021] = DR_CATEGORY.STUN,     -- Consecutive Concussion
    [24394] = DR_CATEGORY.STUN,      -- Intimidation
    [389831] = DR_CATEGORY.STUN,     -- Snowdrift
    [171017] = DR_CATEGORY.STUN,     -- Meteor Strike (Infernal)
    [171018] = DR_CATEGORY.STUN,     -- Meteor Strike (Abyssal)
    [385954] = DR_CATEGORY.STUN,     -- Shield Charge
    [199085] = DR_CATEGORY.STUN,     -- Warpath
    [20549] = DR_CATEGORY.STUN,      -- War Stomp (Tauren)
    [255723] = DR_CATEGORY.STUN,     -- Bull Rush (Highmountain)
    [287254] = DR_CATEGORY.STUN,     -- Dead of Winter
    [377048] = DR_CATEGORY.STUN,     -- Absolute Zero
    [210141] = DR_CATEGORY.STUN,     -- Zombie Explosion
    [202244] = DR_CATEGORY.STUN,     -- Overrun
    [325321] = DR_CATEGORY.STUN,     -- Wild Hunt's Charge
    [372245] = DR_CATEGORY.STUN,     -- Terror of the Skies
    [408544] = DR_CATEGORY.STUN,     -- Seismic Slam
    [202346] = DR_CATEGORY.STUN,     -- Double Barrel

    -- =============================================
    -- INCAPACITATES
    -- =============================================
    [6770] = DR_CATEGORY.INCAPACITATE,    -- Sap
    [1776] = DR_CATEGORY.INCAPACITATE,    -- Gouge
    [20066] = DR_CATEGORY.INCAPACITATE,   -- Repentance
    [82691] = DR_CATEGORY.INCAPACITATE,   -- Ring of Frost
    [99] = DR_CATEGORY.INCAPACITATE,      -- Incapacitating Roar
    [2637] = DR_CATEGORY.INCAPACITATE,    -- Hibernate
    [115078] = DR_CATEGORY.INCAPACITATE,  -- Paralysis
    [357768] = DR_CATEGORY.INCAPACITATE,  -- Paralysis (2)
    -- Polymorph variants
    [118] = DR_CATEGORY.INCAPACITATE,     -- Polymorph
    [28271] = DR_CATEGORY.INCAPACITATE,   -- Polymorph (Turtle)
    [28272] = DR_CATEGORY.INCAPACITATE,   -- Polymorph (Pig)
    [61025] = DR_CATEGORY.INCAPACITATE,   -- Polymorph (Snake)
    [61305] = DR_CATEGORY.INCAPACITATE,   -- Polymorph (Black Cat)
    [61721] = DR_CATEGORY.INCAPACITATE,   -- Polymorph (Rabbit)
    [61780] = DR_CATEGORY.INCAPACITATE,   -- Polymorph (Turkey)
    [126819] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Porcupine)
    [161353] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Polar Bear)
    [161354] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Monkey)
    [161355] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Penguin)
    [161372] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Peacock)
    [277787] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Direhorn)
    [277792] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Bumblebee)
    [321395] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Mawrat)
    [391622] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Duck)
    [460396] = DR_CATEGORY.INCAPACITATE,  -- Polymorph (Mosswool)
    [383121] = DR_CATEGORY.INCAPACITATE,  -- Mass Polymorph
    -- Hex variants
    [51514] = DR_CATEGORY.INCAPACITATE,   -- Hex
    [196942] = DR_CATEGORY.INCAPACITATE,  -- Hex (Voodoo Totem)
    [210873] = DR_CATEGORY.INCAPACITATE,  -- Hex (Raptor)
    [211004] = DR_CATEGORY.INCAPACITATE,  -- Hex (Spider)
    [211010] = DR_CATEGORY.INCAPACITATE,  -- Hex (Snake)
    [211015] = DR_CATEGORY.INCAPACITATE,  -- Hex (Cockroach)
    [269352] = DR_CATEGORY.INCAPACITATE,  -- Hex (Skeletal Hatchling)
    [309328] = DR_CATEGORY.INCAPACITATE,  -- Hex (Living Honey)
    [277778] = DR_CATEGORY.INCAPACITATE,  -- Hex (Zandalari Tendonripper)
    [277784] = DR_CATEGORY.INCAPACITATE,  -- Hex (Wicker Mongrel)
    -- Other incaps
    [197214] = DR_CATEGORY.INCAPACITATE,  -- Sundering
    [200196] = DR_CATEGORY.INCAPACITATE,  -- Holy Word: Chastise
    [9484] = DR_CATEGORY.INCAPACITATE,    -- Shackle Undead
    [710] = DR_CATEGORY.INCAPACITATE,     -- Banish
    [6789] = DR_CATEGORY.INCAPACITATE,    -- Mortal Coil
    [6358] = DR_CATEGORY.INCAPACITATE,    -- Seduction
    [261589] = DR_CATEGORY.INCAPACITATE,  -- Seduction (Grimoire)
    [3355] = DR_CATEGORY.INCAPACITATE,    -- Freezing Trap
    [203337] = DR_CATEGORY.INCAPACITATE,  -- Freezing Trap (Honor)
    [213691] = DR_CATEGORY.INCAPACITATE,  -- Scatter Shot
    [360806] = DR_CATEGORY.INCAPACITATE,  -- Sleep Walk
    [217832] = DR_CATEGORY.INCAPACITATE,  -- Imprison
    [221527] = DR_CATEGORY.INCAPACITATE,  -- Imprison (Honor)
    [378441] = DR_CATEGORY.INCAPACITATE,  -- Time Stop
    [107079] = DR_CATEGORY.INCAPACITATE,  -- Quaking Palm (Pandaren)

    -- =============================================
    -- DISORIENTS
    -- =============================================
    [2094] = DR_CATEGORY.DISORIENT,   -- Blind
    [5246] = DR_CATEGORY.DISORIENT,   -- Intimidating Shout
    [316593] = DR_CATEGORY.DISORIENT, -- Intimidating Shout (Menace main)
    [316595] = DR_CATEGORY.DISORIENT, -- Intimidating Shout (Menace other)
    [8122] = DR_CATEGORY.DISORIENT,   -- Psychic Scream
    [31661] = DR_CATEGORY.DISORIENT,  -- Dragon's Breath
    [353084] = DR_CATEGORY.DISORIENT, -- Ring of Fire
    [105421] = DR_CATEGORY.DISORIENT, -- Blinding Light
    [207167] = DR_CATEGORY.DISORIENT, -- Blinding Sleet
    [207685] = DR_CATEGORY.DISORIENT, -- Sigil of Misery
    [33786] = DR_CATEGORY.DISORIENT,  -- Cyclone
    [198909] = DR_CATEGORY.DISORIENT, -- Song of Chi-ji
    [202274] = DR_CATEGORY.DISORIENT, -- Hot Trub
    [10326] = DR_CATEGORY.DISORIENT,  -- Turn Evil
    [205364] = DR_CATEGORY.DISORIENT, -- Dominate Mind
    [605] = DR_CATEGORY.DISORIENT,    -- Mind Control
    [118699] = DR_CATEGORY.DISORIENT, -- Fear
    [130616] = DR_CATEGORY.DISORIENT, -- Fear (Horrify)
    [5484] = DR_CATEGORY.DISORIENT,   -- Howl of Terror
    [1513] = DR_CATEGORY.DISORIENT,   -- Scare Beast
    [331866] = DR_CATEGORY.DISORIENT, -- Agent of Chaos

    -- =============================================
    -- SILENCES
    -- =============================================
    [15487] = DR_CATEGORY.SILENCE,    -- Silence
    [1330] = DR_CATEGORY.SILENCE,     -- Garrote
    [47476] = DR_CATEGORY.SILENCE,    -- Strangulate
    [374776] = DR_CATEGORY.SILENCE,   -- Tightening Grasp
    [204490] = DR_CATEGORY.SILENCE,   -- Sigil of Silence
    [410065] = DR_CATEGORY.SILENCE,   -- Reactive Resin
    [202933] = DR_CATEGORY.SILENCE,   -- Spider Sting
    [356727] = DR_CATEGORY.SILENCE,   -- Spider Venom
    [354831] = DR_CATEGORY.SILENCE,   -- Wailing Arrow
    [355596] = DR_CATEGORY.SILENCE,   -- Wailing Arrow (2)
    [217824] = DR_CATEGORY.SILENCE,   -- Shield of Virtue
    [196364] = DR_CATEGORY.SILENCE,   -- Unstable Affliction silence

    -- =============================================
    -- ROOTS
    -- =============================================
    [339] = DR_CATEGORY.ROOT,         -- Entangling Roots
    [235963] = DR_CATEGORY.ROOT,      -- Entangling Roots (Earthen Grasp)
    [170855] = DR_CATEGORY.ROOT,      -- Entangling Roots (Nature's Grasp)
    [102359] = DR_CATEGORY.ROOT,      -- Mass Entanglement
    [355689] = DR_CATEGORY.ROOT,      -- Landslide
    [122] = DR_CATEGORY.ROOT,         -- Frost Nova
    [33395] = DR_CATEGORY.ROOT,       -- Freeze (Water Elemental)
    [157997] = DR_CATEGORY.ROOT,      -- Ice Nova
    [228600] = DR_CATEGORY.ROOT,      -- Glacial Spike root
    [64695] = DR_CATEGORY.ROOT,       -- Earthgrab
    [116706] = DR_CATEGORY.ROOT,      -- Disable
    [162480] = DR_CATEGORY.ROOT,      -- Steel Trap
    [212638] = DR_CATEGORY.ROOT,      -- Tracker's Net
    [201158] = DR_CATEGORY.ROOT,      -- Super Sticky Tar
    [393456] = DR_CATEGORY.ROOT,      -- Entrapment (Tar Trap)
    [204085] = DR_CATEGORY.ROOT,      -- Deathchill (Chains of Ice)
    [233395] = DR_CATEGORY.ROOT,      -- Deathchill (Remorseless Winter)
    [454787] = DR_CATEGORY.ROOT,      -- Ice Prison

    -- =============================================
    -- DISARMS
    -- =============================================
    [236077] = DR_CATEGORY.DISARM,    -- Disarm

    -- =============================================
    -- KNOCKBACKS (new category from ArenaCore)
    -- =============================================
    [287712] = DR_CATEGORY.KNOCKBACK, -- Haymaker (Kul Tiran)
}

-- Category display info (colors inspired by ArenaCore)
local DR_CATEGORY_INFO = {
    [DR_CATEGORY.STUN] = { icon = "Interface\\Icons\\Spell_Holy_SealOfMight", color = {1, 0.5, 0} },
    [DR_CATEGORY.INCAPACITATE] = { icon = "Interface\\Icons\\Spell_Nature_Polymorph", color = {0.5, 0.5, 1} },
    [DR_CATEGORY.DISORIENT] = { icon = "Interface\\Icons\\Spell_Shadow_MindSteal", color = {1, 1, 0} },
    [DR_CATEGORY.SILENCE] = { icon = "Interface\\Icons\\Spell_Shadow_Impphaseshift", color = {1, 0, 1} },
    [DR_CATEGORY.ROOT] = { icon = "Interface\\Icons\\Spell_Frost_FrostNova", color = {0, 0.7, 1} },
    [DR_CATEGORY.DISARM] = { icon = "Interface\\Icons\\Ability_Warrior_Disarm", color = {0.6, 0.6, 0.6} },
    [DR_CATEGORY.HORROR] = { icon = "Interface\\Icons\\Spell_Shadow_DeathScream", color = {0.5, 0, 0.5} },
    [DR_CATEGORY.KNOCKBACK] = { icon = "Interface\\Icons\\Ability_Druid_Typhoon", color = {0.4, 0.8, 0.4} },
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
        -- OmniCC exclusion (ArenaCore method)
        cooldown.noCooldownCount = true
        cooldown.noOCC = true
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
