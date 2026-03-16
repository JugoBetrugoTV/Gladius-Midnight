--[[
    Gladius Midnight - Interrupt Module
    Tracks the player's own interrupt spell cooldown.
    Recolors enemy castbars when the player's interrupt comes off cooldown.
    Detects interrupt spell from talents and pet abilities.
]]

-----------------------------------------------------------------------
-- Local references
-----------------------------------------------------------------------
local interruptList = GladiusMixin.interruptList

local function GetSpellCooldownCompat(spellID)
    if not spellID then return nil, nil end
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then
            return info.startTime, info.duration
        end
    end
    if GetSpellCooldown then
        local startTime, duration = GetSpellCooldown(spellID)
        return startTime, duration
    end
    return nil, nil
end

-----------------------------------------------------------------------
-- Detect the player's interrupt spell from known spells / pet spells
-----------------------------------------------------------------------
local function DetectPlayerInterrupt()
    for spellID, _ in pairs(interruptList) do
        if IsSpellKnownOrOverridesKnown(spellID)
            or (UnitExists("pet") and IsSpellKnownOrOverridesKnown(spellID, true))
        then
            return spellID
        end
    end
    return nil
end

local playerKickSpellID = DetectPlayerInterrupt()

-----------------------------------------------------------------------
-- Pet summon spells that might change the available interrupt
-----------------------------------------------------------------------
local petSummonSpells = {
    [30146]  = true, -- Summon Felguard (Demonology)
    [691]    = true, -- Summon Felhunter (for Spell Lock)
    [108503] = true, -- Grimoire of Sacrifice
}

-----------------------------------------------------------------------
-- Hidden interrupt cooldown tracker frame
-----------------------------------------------------------------------
GladiusMixin.interruptIcon = CreateFrame("Frame")
GladiusMixin.interruptIcon.cooldown = CreateFrame("Cooldown", nil, GladiusMixin.interruptIcon, "CooldownFrameTemplate")

-- When the cooldown finishes, mark interrupt as ready and refresh castbar colors
GladiusMixin.interruptIcon.cooldown:HookScript("OnCooldownDone", function()
    GladiusMixin.interruptReady = true
    GladiusMixin:UpdateCastbarInterruptStatus()
end)

-----------------------------------------------------------------------
-- UpdateCastbarInterruptStatus: Recolor all visible castbars
-- Called when the player's interrupt comes off cooldown
-----------------------------------------------------------------------
function GladiusMixin:UpdateCastbarInterruptStatus()
    for i = 1, GladiusMixin.maxArenaOpponents do
        local frame = _G["GladiusEnemyFrame" .. i]
        if frame then
            local castBar = frame.CastBar
            if castBar and castBar:IsShown() then
                GladiusMixin:CastbarOnEvent(castBar)
            end
        end
    end
end

-----------------------------------------------------------------------
-- Internal: Update the hidden cooldown frame with current kick CD
-----------------------------------------------------------------------
local function SyncInterruptCooldown(iconFrame)
    if not playerKickSpellID then
        playerKickSpellID = DetectPlayerInterrupt()
    end
    if not playerKickSpellID then return end

    local startTime, duration = GetSpellCooldownCompat(playerKickSpellID)
    if startTime and duration then
        iconFrame.cooldown:SetCooldown(startTime, duration)
    end
end

-----------------------------------------------------------------------
-- Event handler: detect when player uses interrupt or summons pet
-----------------------------------------------------------------------
local function OnInterruptEvent(_, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Player used their interrupt
        if interruptList[spellID] then
            local startTime, duration = GetSpellCooldownCompat(spellID)
            if startTime and duration then
                GladiusMixin.interruptIcon.cooldown:SetCooldown(startTime, duration)
            end
            GladiusMixin.interruptReady = false
            GladiusMixin:UpdateCastbarInterruptStatus()
            return
        end

        -- Check if this was a pet summon (might change available interrupt)
        if not petSummonSpells[spellID] then return end
    end

    -- Re-detect interrupt after talent/pet changes (slight delay for API)
    C_Timer.After(0.1, function()
        playerKickSpellID = DetectPlayerInterrupt()
        SyncInterruptCooldown(GladiusMixin.interruptIcon)
    end)
end

-----------------------------------------------------------------------
-- Cooldown update listener: keep the hidden frame in sync
-----------------------------------------------------------------------
local cdUpdateFrame = CreateFrame("Frame")
cdUpdateFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
cdUpdateFrame:SetScript("OnEvent", function(_, _, spellID)
    if spellID ~= playerKickSpellID then return end
    SyncInterruptCooldown(GladiusMixin.interruptIcon)
end)

-----------------------------------------------------------------------
-- Event routing frame for spell cast / talent updates
-----------------------------------------------------------------------
GladiusMixin.interruptSpellUpdate = CreateFrame("Frame")
GladiusMixin.interruptSpellUpdate:SetScript("OnEvent", OnInterruptEvent)

-----------------------------------------------------------------------
-- RegisterInterruptEvents: Start tracking (called when entering arena)
-----------------------------------------------------------------------
function GladiusMixin:RegisterInterruptEvents()
    self.interruptSpellUpdate:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    self.interruptSpellUpdate:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self.interruptSpellUpdate:RegisterEvent("PLAYER_TALENT_UPDATE")

    playerKickSpellID = DetectPlayerInterrupt()
    SyncInterruptCooldown(self.interruptIcon)
end

-----------------------------------------------------------------------
-- UnregisterInterruptEvents: Stop tracking (called when leaving arena)
-----------------------------------------------------------------------
function GladiusMixin:UnregisterInterruptEvents()
    self.interruptSpellUpdate:UnregisterAllEvents()
end
