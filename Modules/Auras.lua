--[[
    Gladius Midnight - Auras Module
    Displays important CC/debuffs on arena opponents
]]

local addonName, addon = ...
local Auras = {}

-- Priority auras to track (higher number = higher priority)
-- These are important PvP CC abilities that should be shown
local PRIORITY_AURAS = {
    -- Stuns (Priority 10)
    [408] = 10,      -- Kidney Shot
    [1833] = 10,     -- Cheap Shot
    [853] = 10,      -- Hammer of Justice
    [5211] = 10,     -- Mighty Bash
    [22570] = 10,    -- Maim
    [30283] = 10,    -- Shadowfury
    [46968] = 10,    -- Shockwave
    [88625] = 10,    -- Holy Word: Chastise
    [108194] = 10,   -- Asphyxiate
    [119381] = 10,   -- Leg Sweep
    [179057] = 10,   -- Chaos Nova
    [192058] = 10,   -- Capacitor Totem
    [199804] = 10,   -- Between the Eyes
    [211881] = 10,   -- Fel Eruption
    [221562] = 10,   -- Asphyxiate (Blood)
    [89766] = 10,    -- Axe Toss

    -- Incapacitates (Priority 9)
    [6770] = 9,      -- Sap
    [20066] = 9,     -- Repentance
    [82691] = 9,     -- Ring of Frost
    [99] = 9,        -- Incapacitating Roar
    [115078] = 9,    -- Paralysis
    [118] = 9,       -- Polymorph
    [28271] = 9,     -- Polymorph (Turtle)
    [28272] = 9,     -- Polymorph (Pig)
    [61025] = 9,     -- Polymorph (Serpent)
    [61305] = 9,     -- Polymorph (Black Cat)
    [61721] = 9,     -- Polymorph (Rabbit)
    [61780] = 9,     -- Polymorph (Turkey)
    [126819] = 9,    -- Polymorph (Porcupine)
    [161353] = 9,    -- Polymorph (Polar Bear)
    [161354] = 9,    -- Polymorph (Monkey)
    [161355] = 9,    -- Polymorph (Penguin)
    [161372] = 9,    -- Polymorph (Peacock)
    [277787] = 9,    -- Polymorph (Direhorn)
    [277792] = 9,    -- Polymorph (Bumblebee)
    [1776] = 9,      -- Gouge
    [187650] = 9,    -- Freezing Trap
    [213691] = 9,    -- Scatter Shot
    [710] = 9,       -- Banish
    [6358] = 9,      -- Seduction
    [9484] = 9,      -- Shackle Undead
    [360806] = 9,    -- Sleep Walk

    -- Disorients (Priority 8)
    [2094] = 8,      -- Blind
    [5246] = 8,      -- Intimidating Shout
    [8122] = 8,      -- Psychic Scream
    [31661] = 8,     -- Dragon's Breath
    [105421] = 8,    -- Blinding Light
    [207167] = 8,    -- Blinding Sleet
    [10326] = 8,     -- Turn Evil
    [331866] = 8,    -- Agent of Chaos

    -- Silences (Priority 7)
    [15487] = 7,     -- Silence
    [19647] = 7,     -- Spell Lock
    [47476] = 7,     -- Strangulate
    [78675] = 7,     -- Solar Beam
    [183752] = 7,    -- Disrupt
    [202137] = 7,    -- Sigil of Silence

    -- Roots (Priority 6)
    [339] = 6,       -- Entangling Roots
    [102359] = 6,    -- Mass Entanglement
    [122] = 6,       -- Frost Nova
    [33395] = 6,     -- Freeze
    [64695] = 6,     -- Earthgrab
    [105771] = 6,    -- Charge
    [157997] = 6,    -- Ice Nova
    [162480] = 6,    -- Steel Trap
    [190925] = 6,    -- Harpoon
    [228600] = 6,    -- Glacial Spike

    -- Important Defensive CDs (Priority 5)
    [45438] = 5,     -- Ice Block
    [642] = 5,       -- Divine Shield
    [186265] = 5,    -- Aspect of the Turtle
    [31224] = 5,     -- Cloak of Shadows
    [47585] = 5,     -- Dispersion
    [104773] = 5,    -- Unending Resolve
    [212800] = 5,    -- Blur
    [196555] = 5,    -- Netherwalk
    [1022] = 5,      -- Blessing of Protection
    [204018] = 5,    -- Blessing of Spellwarding
    [33206] = 5,     -- Pain Suppression
    [47788] = 5,     -- Guardian Spirit
    [116849] = 5,    -- Life Cocoon
    [6940] = 5,      -- Blessing of Sacrifice
    [125174] = 5,    -- Touch of Karma
    [204336] = 5,    -- Evasion
    [5277] = 5,      -- Evasion
    [118038] = 5,    -- Die by the Sword
    [23920] = 5,     -- Spell Reflection
    [184364] = 5,    -- Enraged Regeneration
    [48792] = 5,     -- Icebound Fortitude
    [48707] = 5,     -- Anti-Magic Shell

    -- Important Offensive Buffs (Priority 4)
    [31884] = 4,     -- Avenging Wrath
    [1719] = 4,      -- Recklessness
    [12472] = 4,     -- Icy Veins
    [102560] = 4,    -- Incarnation: Chosen of Elune
    [194223] = 4,    -- Celestial Alignment
    [13750] = 4,     -- Adrenaline Rush
    [121471] = 4,    -- Shadow Blades
    [114050] = 4,    -- Ascendance (Ele)
    [114051] = 4,    -- Ascendance (Enh)
    [162264] = 4,    -- Metamorphosis
    [191427] = 4,    -- Metamorphosis (Havoc)
    [137639] = 4,    -- Storm, Earth, and Fire
    [10060] = 4,     -- Power Infusion
    [319952] = 4,    -- Surrender to Madness
}

-- Immunity spells (for glow effect)
local IMMUNITY_SPELLS = {
    [45438] = true,  -- Ice Block
    [642] = true,    -- Divine Shield
    [186265] = true, -- Aspect of the Turtle
    [196555] = true, -- Netherwalk
    [1022] = true,   -- Blessing of Protection
    [204018] = true, -- Blessing of Spellwarding
    [710] = true,    -- Banish (self-immunity if used on self)
    [31224] = true,  -- Cloak of Shadows (magic immunity)
    [212182] = true, -- Smoke Bomb (untargetable)
}

-- ============================================================================
-- Module Registration
-- ============================================================================

function Auras:OnRegister(core)
    self.core = core
end

function Auras:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Aura Elements
-- ============================================================================

function Auras:CreateElements(frame)
    -- Container for aura icons - PARENT TO UIParent to avoid clipping/overlap issues
    local container = CreateFrame("Frame", "GladiusMidnightAuras" .. frame.index, UIParent)
    container:SetSize(150, 32)
    container:SetFrameStrata("MEDIUM")
    container:SetFrameLevel(10)

    -- Store reference to parent arena frame
    container.arenaFrame = frame

    -- Create aura icon frames
    container.icons = {}
    for i = 1, 4 do
        local iconFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
        iconFrame:SetSize(28, 28)
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

        -- Duration text
        local duration = iconFrame:CreateFontString(nil, "OVERLAY")
        duration:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        duration:SetPoint("CENTER", 0, 0)
        duration:SetTextColor(1, 1, 1)
        iconFrame.duration = duration

        -- Cooldown overlay
        local cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
        cooldown:SetAllPoints(icon)
        cooldown:SetDrawSwipe(true)
        cooldown:SetDrawEdge(false)
        cooldown:SetHideCountdownNumbers(true)
        -- OmniCC exclusion (ArenaCore method)
        cooldown.noCooldownCount = true
        cooldown.noOCC = true
        iconFrame.cooldown = cooldown

        -- Stack count
        local stacks = iconFrame:CreateFontString(nil, "OVERLAY")
        stacks:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        stacks:SetPoint("BOTTOMRIGHT", -1, 1)
        stacks:SetTextColor(1, 1, 1)
        iconFrame.stacks = stacks

        iconFrame:Hide()
        container.icons[i] = iconFrame
    end

    -- Store active auras
    container.activeAuras = {}

    frame.moduleFrames.auras = container
end

-- ============================================================================
-- Update Auras Display
-- ============================================================================

function Auras:Update(frame, testData)
    local container = frame.moduleFrames.auras
    if not container then return end

    local db = self.core.db.profile.auras
    local iconSize = db.iconSize or 22  -- Smaller icons like ArenaCore

    -- Position BELOW the health/power bars (ArenaCore style)
    container:ClearAllPoints()

    -- Calculate position - below power bar if enabled, otherwise below health
    local healthHeight = self.core.db.profile.health.height or 28
    local powerHeight = self.core:IsModuleEnabled("power") and (self.core.db.profile.power.height or 10) or 0
    local yOffset = -(healthHeight + powerHeight + 6)

    -- Position starting from left side, below the bars
    local leftOffset = self.core.db.profile.classIcon.size + 4
    container:SetPoint("TOPLEFT", frame, "TOPLEFT", leftOffset, yOffset)
    container:SetSize(iconSize * 5 + 8, iconSize)

    -- Update icon sizes
    for i, iconFrame in ipairs(container.icons) do
        iconFrame:SetSize(iconSize, iconSize)
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint("LEFT", container, "LEFT", (i - 1) * (iconSize + 2), 0)
    end

    if testData then
        -- Test mode - show sample auras
        self:ShowTestAuras(frame)
        container:Show()
    else
        -- Live mode - RefreshAuras will show/hide based on content
        self:RefreshAuras(frame)
    end
end

function Auras:ShowTestAuras(frame)
    local container = frame.moduleFrames.auras
    if not container then return end

    -- Hide all first
    for i, iconFrame in ipairs(container.icons) do
        iconFrame:Hide()
    end

    -- Show test auras
    local testAuras = {
        { icon = "Interface\\Icons\\Spell_Nature_Polymorph", duration = 4.5 },
        { icon = "Interface\\Icons\\Spell_Holy_SealOfMight", duration = 2.1 },
    }

    for i, aura in ipairs(testAuras) do
        local iconFrame = container.icons[i]
        if iconFrame then
            iconFrame.icon:SetTexture(aura.icon)
            iconFrame.duration:SetText(string.format("%.1f", aura.duration))
            iconFrame.stacks:SetText("")
            iconFrame:SetBackdropBorderColor(1, 0, 0, 1)  -- Red border for CC
            iconFrame:Show()
        end
    end
end

function Auras:RefreshAuras(frame)
    local container = frame.moduleFrames.auras
    if not container then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        -- Hide all icons
        for i, iconFrame in ipairs(container.icons) do
            iconFrame:Hide()
        end
        container.blizzDebuffShown = false
        return
    end

    -- In Midnight 12.0 live arena, we rely on Blizzard hooks for the main debuff
    -- The native aura scanning below may not work due to "secret" data
    -- Keep the first slot reserved for Blizzard's hooked debuff if active
    local startIndex = container.blizzDebuffShown and 2 or 1

    -- Collect auras with priority
    local auras = {}

    -- Scan debuffs on the unit
    -- NOTE: In Midnight 12.0, most aura data is "secret" for arena opponents
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetDebuffDataByIndex(unit, i)
        if not auraData then break end

        -- In Midnight 12.0, spellId and other fields may be secret/nil
        local spellId = auraData.spellId
        if spellId and type(spellId) == "number" then
            local priority = PRIORITY_AURAS[spellId]

            if priority then
                table.insert(auras, {
                    spellId = spellId,
                    name = auraData.name,
                    icon = auraData.icon,
                    duration = (type(auraData.duration) == "number") and auraData.duration or 0,
                    expirationTime = (type(auraData.expirationTime) == "number") and auraData.expirationTime or 0,
                    stacks = (type(auraData.applications) == "number") and auraData.applications or 0,
                    priority = priority,
                    isDebuff = true,
                })
            end
        end
    end

    -- Also scan important buffs (defensive CDs) and check for immunities
    -- NOTE: In Midnight 12.0, most aura data is "secret" for arena opponents
    local immunityType = nil  -- "total" or "magic" or nil
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetBuffDataByIndex(unit, i)
        if not auraData then break end

        -- In Midnight 12.0, spellId and other fields may be secret/nil
        local spellId = auraData.spellId
        if spellId and type(spellId) == "number" then
            local priority = PRIORITY_AURAS[spellId]

            -- Check for immunity type (ArenaCore style - magic vs total)
            local spellImmunityType = addon.Data.GetImmunityType(spellId)
            if spellImmunityType then
                -- Total immunity takes priority over magic immunity
                if spellImmunityType == "total" then
                    immunityType = "total"
                elseif not immunityType then
                    immunityType = "magic"
                end
            end
            -- Fallback: Check old IMMUNITY_SPELLS table
            if not immunityType and IMMUNITY_SPELLS[spellId] then
                immunityType = "total"
            end

            if priority then
                table.insert(auras, {
                    spellId = spellId,
                    name = auraData.name,
                    icon = auraData.icon,
                    duration = (type(auraData.duration) == "number") and auraData.duration or 0,
                    expirationTime = (type(auraData.expirationTime) == "number") and auraData.expirationTime or 0,
                    stacks = (type(auraData.applications) == "number") and auraData.applications or 0,
                    priority = priority,
                    isDebuff = false,
                })
            end
        end
    end

    -- Update immunity glow on frame (ArenaCore style - white/green)
    self:UpdateImmunityGlow(frame, immunityType)

    -- Sort by priority (highest first)
    table.sort(auras, function(a, b)
        return a.priority > b.priority
    end)

    -- Update icons (starting from startIndex to preserve Blizzard's hooked debuff)
    local auraIndex = 1
    for i = startIndex, #container.icons do
        local iconFrame = container.icons[i]
        local aura = auras[auraIndex]
        if aura then
            iconFrame.icon:SetTexture(aura.icon)

            -- Set border color based on type
            if aura.priority >= 8 then
                iconFrame:SetBackdropBorderColor(1, 0, 0, 1)  -- Red for hard CC
            elseif aura.priority >= 6 then
                iconFrame:SetBackdropBorderColor(1, 0.5, 0, 1)  -- Orange for soft CC
            elseif aura.isDebuff then
                iconFrame:SetBackdropBorderColor(0.8, 0, 0.8, 1)  -- Purple for other debuffs
            else
                iconFrame:SetBackdropBorderColor(0, 1, 0, 1)  -- Green for buffs
            end

            -- Stack count
            if aura.stacks > 1 then
                iconFrame.stacks:SetText(aura.stacks)
            else
                iconFrame.stacks:SetText("")
            end

            -- Duration tracking
            if aura.duration > 0 and aura.expirationTime > 0 then
                iconFrame.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
                iconFrame.expirationTime = aura.expirationTime
            else
                iconFrame.cooldown:Clear()
                iconFrame.expirationTime = nil
            end

            iconFrame:Show()
            auraIndex = auraIndex + 1
        else
            iconFrame:Hide()
        end
    end

    container.activeAuras = auras

    -- Show container if there are auras to display or Blizzard debuff is shown
    if #auras > 0 or container.blizzDebuffShown then
        container:Show()
    else
        container:Hide()
    end
end

function Auras:OnUpdate(frame)
    local container = frame.moduleFrames.auras
    if not container or not container:IsShown() then return end

    local now = GetTime()

    -- Update duration text for visible icons only
    for i, iconFrame in ipairs(container.icons) do
        if iconFrame:IsShown() and iconFrame.expirationTime then
            local remaining = iconFrame.expirationTime - now
            if remaining > 0 then
                if remaining > 60 then
                    iconFrame.duration:SetText(math.floor(remaining / 60) .. "m")
                elseif remaining > 10 then
                    iconFrame.duration:SetText(math.floor(remaining))
                else
                    iconFrame.duration:SetText(string.format("%.1f", remaining))
                end
            else
                -- Aura expired - trigger refresh
                iconFrame.duration:SetText("")
                if not self.core.testMode then
                    self:RefreshAuras(frame)
                end
                break
            end
        end
    end
end

function Auras:OnAuraChange(frame)
    if not self.core.testMode then
        self:RefreshAuras(frame)
    end
end

-- ============================================================================
-- Blizzard DebuffFrame Hooks (Midnight 12.0)
-- Since we can't read aura data directly, we hook into Blizzard's debuff display
-- ============================================================================

function Auras:OnBlizzardDebuffUpdate(frame, texture)
    if self.core.testMode then return end

    local container = frame.moduleFrames.auras
    if not container then return end

    -- Ignore placeholder textures
    if not texture or texture == "" or
       texture == "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK.BLP" or
       texture:find("INV_MISC_QUESTIONMARK") then
        -- No valid debuff - hide first icon if it was showing Blizzard debuff
        if container.blizzDebuffShown and container.icons[1] then
            container.icons[1]:Hide()
            container.blizzDebuffShown = false
        end
        return
    end

    -- Show the first aura icon with Blizzard's debuff texture
    local iconFrame = container.icons[1]
    if iconFrame then
        iconFrame.icon:SetTexture(texture)
        iconFrame:SetBackdropBorderColor(1, 0, 0, 1)  -- Red for CC
        iconFrame.stacks:SetText("")
        iconFrame.duration:SetText("")
        iconFrame:Show()
        container.blizzDebuffShown = true
        container:Show()
    end
end

function Auras:OnBlizzardDebuffCooldown(frame, start, duration)
    if self.core.testMode then return end

    local container = frame.moduleFrames.auras
    if not container then return end

    local iconFrame = container.icons[1]
    if iconFrame and container.blizzDebuffShown then
        if start and duration and start > 0 and duration > 0 then
            iconFrame.cooldown:SetCooldown(start, duration)
            iconFrame.expirationTime = start + duration
        else
            iconFrame.cooldown:Clear()
            iconFrame.expirationTime = nil
        end
    end
end

function Auras:UpdateImmunityGlow(frame, immunityType)
    if not self.core.db.profile.immunityGlow then return end

    if frame.immunityGlow then
        if immunityType and not frame.hasImmunity then
            -- Set color based on immunity type (ArenaCore style)
            -- WHITE = Total immunity (Bubble, Ice Block, Turtle)
            -- GREEN = Magic-only immunity (Cloak, AMS, Spellwarding)
            if immunityType == "total" then
                frame.immunityGlow:SetBackdropBorderColor(1, 1, 1, 1)  -- White
            else
                frame.immunityGlow:SetBackdropBorderColor(0, 1, 0, 1)  -- Green
            end

            -- Start immunity glow
            frame.immunityGlow:Show()
            frame.hasImmunity = true
            frame.immunityType = immunityType

            -- Start pulse animation
            if not frame.immunityGlow.pulseAnim then
                local ag = frame.immunityGlow:CreateAnimationGroup()
                ag:SetLooping("REPEAT")

                local fadeOut = ag:CreateAnimation("Alpha")
                fadeOut:SetFromAlpha(1)
                fadeOut:SetToAlpha(0.3)
                fadeOut:SetDuration(0.4)  -- Faster pulse like ArenaCore
                fadeOut:SetOrder(1)

                local fadeIn = ag:CreateAnimation("Alpha")
                fadeIn:SetFromAlpha(0.3)
                fadeIn:SetToAlpha(1)
                fadeIn:SetDuration(0.4)
                fadeIn:SetOrder(2)

                frame.immunityGlow.pulseAnim = ag
            end
            frame.immunityGlow.pulseAnim:Play()

        elseif immunityType and frame.hasImmunity and immunityType ~= frame.immunityType then
            -- Immunity type changed - update color
            if immunityType == "total" then
                frame.immunityGlow:SetBackdropBorderColor(1, 1, 1, 1)
            else
                frame.immunityGlow:SetBackdropBorderColor(0, 1, 0, 1)
            end
            frame.immunityType = immunityType

        elseif not immunityType and frame.hasImmunity then
            -- Stop immunity glow
            if frame.immunityGlow.pulseAnim then
                frame.immunityGlow.pulseAnim:Stop()
            end
            frame.immunityGlow:Hide()
            frame.hasImmunity = false
            frame.immunityType = nil
        end
    end
end

function Auras:Reset(frame)
    local container = frame.moduleFrames.auras
    if container then
        container.activeAuras = {}
        container.lastRefresh = nil
        container.blizzDebuffShown = false
        for i, iconFrame in ipairs(container.icons) do
            iconFrame:Hide()
            iconFrame.cooldown:Clear()
            iconFrame.expirationTime = nil
        end
    end

    -- Reset immunity glow
    if frame.immunityGlow then
        if frame.immunityGlow.pulseAnim then
            frame.immunityGlow.pulseAnim:Stop()
        end
        frame.immunityGlow:Hide()
        frame.hasImmunity = false
        frame.immunityType = nil
    end
end

-- Register module
addon.Core:RegisterModule("auras", Auras)
