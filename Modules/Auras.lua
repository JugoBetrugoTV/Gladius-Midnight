--[[
    Gladius Midnight - Auras Module
    Priority-based aura scanning for arena enemy unit frames.
    Shows highest priority aura on the ClassIcon with cooldown sweep.
    Handles interrupt lockout display and aura stack counts.
]]

local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local auraList = GladiusMixin.auraList
local interruptList = GladiusMixin.interruptList
local tooltipInfoAuras = GladiusMixin.tooltipInfoAuras
local spellLockReducer = GladiusMixin.spellLockReducer

-----------------------------------------------------------------------
-- Tooltip scanner for special aura information
-----------------------------------------------------------------------
local tooltipScanner = CreateFrame("GameTooltip", "GladiusTooltipScanner", nil, "GameTooltipTemplate")
tooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local function ScanAuraTooltipForText(unit, slotIndex, filter, searchStr)
    -- WoW 12.0+: use C_TooltipInfo API
    if C_TooltipInfo and C_TooltipInfo.GetUnitAura then
        local data = C_TooltipInfo.GetUnitAura(unit, slotIndex, filter)
        if data and data.lines then
            for _, line in ipairs(data.lines) do
                if TooltipUtil and TooltipUtil.SurfaceArgs then TooltipUtil.SurfaceArgs(line) end
                if line.leftText and line.leftText:find(searchStr, 1, true) then
                    return true
                end
            end
        end
        return false
    end
    -- Fallback: legacy SetUnitAura
    tooltipScanner:ClearLines()
    tooltipScanner:SetUnitAura(unit, slotIndex, filter)

    for i = 1, tooltipScanner:NumLines() do
        local lineObj = _G["GladiusTooltipScannerTextLeft" .. i]
        if lineObj then
            local lineText = lineObj:GetText()
            if lineText and lineText:find(searchStr, 1, true) then
                return true
            end
        end
    end
    return false
end

local function ScanAuraTooltipForPercent(unit, slotIndex, filter)
    -- WoW 12.0+: use C_TooltipInfo API
    if C_TooltipInfo and C_TooltipInfo.GetUnitAura then
        local data = C_TooltipInfo.GetUnitAura(unit, slotIndex, filter)
        if data and data.lines then
            for _, line in ipairs(data.lines) do
                if TooltipUtil and TooltipUtil.SurfaceArgs then TooltipUtil.SurfaceArgs(line) end
                if line.leftText then
                    local pctMatch = line.leftText:match("(%d+%%)")
                    if pctMatch then return pctMatch end
                end
            end
        end
        return nil
    end
    -- Fallback: legacy SetUnitAura
    tooltipScanner:ClearLines()
    tooltipScanner:SetUnitAura(unit, slotIndex, filter)

    for i = 1, tooltipScanner:NumLines() do
        local lineObj = _G["GladiusTooltipScannerTextLeft" .. i]
        if lineObj then
            local lineText = lineObj:GetText()
            if lineText then
                local pctMatch = lineText:match("(%d+%%)")
                if pctMatch then
                    return pctMatch
                end
            end
        end
    end
    return nil
end

-----------------------------------------------------------------------
-- FindInterrupt: Track spell lockout on an arena enemy
-----------------------------------------------------------------------
function GladiusFrameMixin:FindInterrupt(event, spellID, sourceName, sourceGUID)
    local lockDuration = interruptList[spellID]
    if not lockDuration then return end

    local unit = self.unit
    local castBar = self.CastBar

    -- For SPELL_CAST_SUCCESS, only trigger if target is channeling an interruptible spell
    if event == "SPELL_CAST_SUCCESS" then
        local notInterruptable = select(7, UnitChannelInfo(unit))
        if notInterruptable ~= false then
            return
        end
    end

    -- Display the interrupter's name with class color on the castbar
    if sourceName and castBar then
        local shortName = strsplit("-", sourceName)
        local colorHex = "ffFFFFFF"

        if C_PlayerInfo.GUIDIsPlayer(sourceGUID) then
            local _, engClass = GetPlayerInfoByGUID(sourceGUID)
            if engClass and RAID_CLASS_COLORS[engClass] then
                colorHex = RAID_CLASS_COLORS[engClass].colorStr
            end
        end

        local formattedName = string.format("|c%s[%s]|r", colorHex, shortName)
        castBar.interruptedBy = formattedName
        castBar.Text:SetText(formattedName)
        castBar:Show()
        C_Timer.After(1, function()
            castBar.interruptedBy = nil
        end)
    end

    -- Check for spell lock duration reducers (e.g. Concentration Aura)
    for slot = 1, 30 do
        local auraInfo = C_UnitAuras.GetAuraDataByIndex(unit, slot, "HELPFUL")
        if not auraInfo then break end
        local reducer = spellLockReducer[auraInfo.spellId]
        if reducer then
            lockDuration = lockDuration * reducer
        end
    end

    -- Store interrupt state on this frame
    local now = GetTime()
    self.currentInterruptSpellID = spellID
    self.currentInterruptDuration = lockDuration
    self.currentInterruptExpirationTime = now + lockDuration
    self.currentInterruptTexture = GetSpellTexture(spellID)

    -- Refresh aura display immediately
    self:FindAura()

    -- Schedule interrupt expiry and re-scan
    C_Timer.After(lockDuration, function()
        self.currentInterruptSpellID = nil
        self.currentInterruptDuration = 0
        self.currentInterruptExpirationTime = 0
        self.currentInterruptTexture = nil
        self:FindAura()
    end)
end

-----------------------------------------------------------------------
-- FindAura: Scan all buffs/debuffs to find the highest priority aura
-----------------------------------------------------------------------
function GladiusFrameMixin:FindAura()
    if self.parent and self.parent.db and self.parent.db.profile.disableAurasOnClassIcon then
        self:UpdateClassIcon()
        return
    end

    local unit = self.unit
    local bestSpellID, bestDuration, bestExpiration, bestTexture, bestStacks
    local bestPriority, bestRemaining = 0, 0

    -- If there's an active interrupt lockout, seed it as the baseline
    if self.currentInterruptSpellID then
        bestSpellID = self.currentInterruptSpellID
        bestDuration = self.currentInterruptDuration
        bestExpiration = self.currentInterruptExpirationTime
        bestTexture = self.currentInterruptTexture
        bestPriority = 5.9  -- Below Silence priority
        bestRemaining = bestExpiration - GetTime()
        bestStacks = nil
    end

    -- Iterate HELPFUL then HARMFUL filters
    local filters = { "HELPFUL", "HARMFUL" }
    for _, filter in ipairs(filters) do
        for slot = 1, 30 do
            local auraData = C_UnitAuras.GetAuraDataByIndex(unit, slot, filter)
            if not auraData then break end

            local sid = auraData.spellId
            local priority = auraList[sid]

            if priority then
                local dur = auraData.duration or 0
                local expTime = auraData.expirationTime or 0
                local icon = auraData.icon
                local stacks = auraData.applications or 0

                -- Check for manually tracked non-duration auras
                local activeND = GladiusMixin.activeNonDurationAuras[unit .. sid]
                if activeND then
                    dur = activeND.duration
                    expTime = activeND.startTime + dur
                    icon = activeND.texture or icon
                end

                local remaining = expTime - GetTime()

                -- Higher priority wins; equal priority: longer remaining wins
                if priority > bestPriority
                    or (priority == bestPriority and remaining > bestRemaining)
                then
                    bestSpellID = sid
                    bestDuration = dur
                    bestExpiration = expTime
                    bestTexture = icon
                    bestPriority = priority
                    bestRemaining = remaining
                    bestStacks = stacks
                end
            end
        end
    end

    -- Apply the best aura or clear
    if bestSpellID then
        self.currentAuraSpellID = bestSpellID
        self.currentAuraStartTime = bestExpiration - bestDuration
        self.currentAuraDuration = bestDuration
        self.currentAuraTexture = bestTexture
        self.currentAuraApplications = bestStacks
    else
        self.currentAuraSpellID = nil
        self.currentAuraStartTime = 0
        self.currentAuraDuration = 0
        self.currentAuraTexture = nil
        self.currentAuraApplications = nil
    end

    self:UpdateAuraStacks()
    self:UpdateClassIcon()
end

-----------------------------------------------------------------------
-- UpdateAuraStacks: Show stack count text on the ClassIcon
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateAuraStacks()
    if not self.AuraStacks then return end

    if not self.currentAuraApplications then
        self.AuraStacks:SetText("")
        return
    end

    -- Percentage auras get special treatment
    if tooltipInfoAuras[self.currentAuraSpellID] then
        self.AuraStacks:SetText(self.currentAuraApplications)
        self.AuraStacks:SetScale(0.9)
    elseif self.currentAuraApplications >= 2 then
        self.AuraStacks:SetText(self.currentAuraApplications)
        self.AuraStacks:SetScale(1)
    else
        self.AuraStacks:SetText("")
    end
end
