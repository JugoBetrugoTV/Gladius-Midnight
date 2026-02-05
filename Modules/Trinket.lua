--[[
    Gladius Midnight - Trinket Module
    Tracks PvP trinket usage and cooldown
]]

local addonName, addon = ...
local Trinket = {}

-- PvP Trinket spell IDs (comprehensive list for all expansions)
local TRINKET_SPELLS = {
    -- Current (Midnight 12.0)
    [336126] = 120,   -- Gladiator's Medallion
    [336135] = 120,   -- Adaptation

    -- The War Within / Dragonflight
    [363117] = 120,   -- Gladiator's Medallion (DF)
    [370613] = 120,   -- Precognition Immunity

    -- Shadowlands
    [208683] = 120,   -- Gladiator's Medallion (SL)

    -- Legacy
    [195710] = 120,   -- Honorable Medallion
    [42292] = 120,    -- PvP Trinket (generic)

    -- Racial CC-breaks (also trigger trinket CD)
    [59752] = 120,    -- Every Man for Himself (Human) - shares CD
    [7744] = 30,      -- Will of the Forsaken (Undead) - own CD but affects trinket
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
    cooldown:SetHideCountdownNumbers(true)  -- Hide default numbers, use our own
    -- OmniCC exclusion (ArenaCore method - prevents OmniCC from overriding our display)
    cooldown.noCooldownCount = true
    cooldown.noOCC = true

    -- Custom cooldown text (more reliable than built-in)
    local cdText = container:CreateFontString(nil, "OVERLAY")
    cdText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    cdText:SetPoint("CENTER", 0, 0)
    cdText:SetTextColor(1, 1, 0)  -- Yellow for better visibility
    cdText:SetJustifyH("CENTER")
    container.cdText = cdText

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

    -- Check if it's a trinket spell (includes CC-break racials)
    local cooldownDuration = TRINKET_SPELLS[spellID]
    if cooldownDuration then
        -- Update icon to match the spell used
        local iconTexture = addon.Data.GetSpellIcon(spellID)
        if iconTexture then
            local container = frame.moduleFrames.trinket
            if container then
                container.icon:SetTexture(iconTexture)
            end
        end

        self:TriggerCooldown(frame, cooldownDuration)
        return
    end

    -- Fallback: Check Data.lua trinket-sharing racials
    if addon.Data.TrinketShareRacials[spellID] then
        self:TriggerCooldown(frame, 90)
    end
end

function Trinket:TriggerCooldown(frame, duration)
    local container = frame.moduleFrames.trinket
    if not container then return end

    -- Validate duration (trinkets are 120s max, not days)
    if duration > 300 then
        duration = 120  -- Default to 2 minutes if invalid
    end

    container.startTime = GetTime()
    container.duration = duration
    container.onCooldown = true

    container.cooldown:SetCooldown(container.startTime, duration)
    container.icon:SetDesaturated(true)

    -- Update custom text
    self:UpdateCooldownText(container)
end

function Trinket:UpdateCooldownText(container)
    if not container.onCooldown or container.startTime == 0 then
        container.cdText:SetText("")
        return
    end

    local remaining = (container.startTime + container.duration) - GetTime()

    -- Validate remaining time - trinkets max 2 minutes (120s)
    if remaining <= 0 or remaining > 180 then
        container.cdText:SetText("")
        -- If remaining is invalid/garbage, reset cooldown state
        if remaining > 180 then
            container.onCooldown = false
            container.startTime = 0
            container.duration = 0
            container.icon:SetDesaturated(false)
        end
        return
    end

    -- Format: show seconds if < 60, else show minutes
    if remaining < 60 then
        container.cdText:SetText(math.ceil(remaining))
    else
        container.cdText:SetText(math.ceil(remaining / 60) .. "m")
    end
end

function Trinket:OnUpdate(frame)
    local container = frame.moduleFrames.trinket
    if not container then return end

    local now = GetTime()

    -- Check C_PvP API for trinket cooldown (12.0)
    -- This API returns CC break ability info for arena opponents
    if C_PvP and C_PvP.GetArenaCrowdControlInfo and UnitExists(frame.unit) then
        local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(frame.unit)

        -- API returned valid cooldown data - validate all values
        if spellID and startTime and duration and duration > 0 then
            -- Validate: duration must be reasonable (max 3 min for trinkets)
            -- Validate: startTime must be reasonable (within last 3 min)
            local isValidDuration = duration <= 180
            local isValidStartTime = startTime > 0 and (now - startTime) < 300

            if isValidDuration and isValidStartTime then
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
    end

    -- Check if cooldown expired
    if container.onCooldown and container.startTime > 0 and container.duration > 0 then
        local elapsed = now - container.startTime
        if elapsed >= container.duration or elapsed < 0 then
            container.onCooldown = false
            container.icon:SetDesaturated(false)
            container.startTime = 0
            container.duration = 0
            container.cdText:SetText("")
            -- Reset to default trinket icon
            container.icon:SetTexture(addon.Data.TrinketIcon)
        else
            -- Update cooldown text
            self:UpdateCooldownText(container)
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
        container.cdText:SetText("")
    end
end

-- Register module
addon.Core:RegisterModule("trinket", Trinket)
