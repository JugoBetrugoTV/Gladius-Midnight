--[[=========================================================================
    Gladius Midnight - Diminishing Returns Tracker
    Monitors CC applied to arena opponents and tracks DR severity
    DR Categories: Stun, Incapacitate, Disorient, Silence, Root, Disarm, Knock
    Severity levels: Full -> Half -> Quarter -> Immune (resets after 18.5s)
===========================================================================]]

local _, Gladius = ...

local DR_RESET_TIME = Gladius.DR_RESET_TIME
local MAX_DR_SEVERITY = 3

-- =========================================================================
-- DR Frame Construction
-- =========================================================================
function GladiusArenaFrameMixin:BuildDRFrames()
    self.drFrames = {}
    self.drState = {}

    for _, category in ipairs(Gladius.DR_CATEGORIES) do
        local drFrame = CreateFrame("Frame", nil, self, "GladiusDRIconTemplate")
        drFrame:Hide()
        drFrame.category = category
        drFrame.severity = 0
        drFrame.resetTimer = nil

        -- Set default icon
        local iconID = Gladius.DR_CATEGORY_ICONS[category]
        if iconID then
            drFrame.Icon:SetTexture(iconID)
        end

        self.drFrames[category] = drFrame

        -- Initialize DR tracking state
        self.drState[category] = {
            severity = 0,
            lastApplication = 0,
        }
    end
end

-- =========================================================================
-- DR Layout Positioning
-- =========================================================================
function GladiusArenaFrameMixin:UpdateDRLayout()
    local db = Gladius.db.profile
    if not db.drEnabled then
        for _, drFrame in pairs(self.drFrames) do
            drFrame:Hide()
        end
        return
    end

    local size = db.drSize
    local spacing = db.drSpacing
    local growDir = db.drGrowDirection

    local visibleIndex = 0
    for _, category in ipairs(Gladius.DR_CATEGORIES) do
        local drFrame = self.drFrames[category]
        if drFrame and db.drCategories[category] then
            drFrame:SetSize(size, size)
            drFrame.Icon:SetSize(size - 2, size - 2)
            drFrame.Cooldown:SetSize(size - 2, size - 2)

            drFrame:ClearAllPoints()
            local offset = visibleIndex * (size + spacing)

            if growDir == "RIGHT" then
                drFrame:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", 1 + offset, 0)
            elseif growDir == "LEFT" then
                drFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", -(1 + offset), 0)
            elseif growDir == "DOWN" then
                drFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", offset, -1)
            elseif growDir == "UP" then
                drFrame:SetPoint("BOTTOMLEFT", self, "TOPLEFT", offset, 1)
            end

            visibleIndex = visibleIndex + 1
        else
            if drFrame then drFrame:Hide() end
        end
    end
end

-- =========================================================================
-- DR Event Handlers
-- =========================================================================
function GladiusArenaFrameMixin:OnDRAuraApplied(spellID)
    local category = Gladius.DR_SPELLS[spellID]
    if not category then return end
    if not Gladius.db.profile.drCategories[category] then return end

    local state = self.drState[category]
    if not state then return end

    local now = GetTime()

    -- Check if DR has reset (18.5s since last application)
    if (now - state.lastApplication) > DR_RESET_TIME then
        state.severity = 0
    end

    -- Increment severity
    state.severity = math.min(state.severity + 1, MAX_DR_SEVERITY)
    state.lastApplication = now

    -- Update the visual DR frame
    local drFrame = self.drFrames[category]
    if drFrame then
        -- Set the aura icon
        local texture = Gladius.GetSpellTexture(spellID)
        if texture then
            drFrame.Icon:SetTexture(texture)
            drFrame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        -- Start cooldown for DR reset timer
        drFrame.Cooldown:SetCooldown(now, DR_RESET_TIME)

        -- Show severity text
        self:UpdateDRSeverityDisplay(drFrame, state.severity)

        drFrame:Show()

        -- Setup reset timer
        if drFrame.resetTimer then
            drFrame.resetTimer:Cancel()
        end
        drFrame.resetTimer = C_Timer.NewTimer(DR_RESET_TIME, function()
            self:OnDRReset(category)
        end)
    end
end

function GladiusArenaFrameMixin:OnDRAuraRemoved(spellID)
    local category = Gladius.DR_SPELLS[spellID]
    if not category then return end

    -- DR frame stays visible with its current severity until the 18.5s timer expires
    -- The cooldown spin already shows the remaining reset time
end

function GladiusArenaFrameMixin:OnDRReset(category)
    local state = self.drState[category]
    if state then
        state.severity = 0
        state.lastApplication = 0
    end

    local drFrame = self.drFrames[category]
    if drFrame then
        drFrame:Hide()
        drFrame.severity = 0
        drFrame.SeverityText:SetText("")

        -- Restore default category icon
        local iconID = Gladius.DR_CATEGORY_ICONS[category]
        if iconID then
            drFrame.Icon:SetTexture(iconID)
        end
    end
end

-- =========================================================================
-- DR Severity Display
-- =========================================================================
function GladiusArenaFrameMixin:UpdateDRSeverityDisplay(drFrame, severity)
    if not Gladius.db.profile.drShowSeverity then
        drFrame.SeverityText:SetText("")
        return
    end

    local text = Gladius.DR_SEVERITY_TEXT[severity] or ""
    drFrame.SeverityText:SetText(text)

    -- Color the text based on severity
    if Gladius.db.profile.drColorText then
        local color = Gladius.DR_SEVERITY_COLORS[severity]
        if color then
            drFrame.SeverityText:SetTextColor(color.r, color.g, color.b)
        else
            drFrame.SeverityText:SetTextColor(1, 1, 1)
        end
    else
        drFrame.SeverityText:SetTextColor(1, 1, 1)
    end
end

-- =========================================================================
-- DR State Reset
-- =========================================================================
function GladiusArenaFrameMixin:ResetDRState()
    for _, category in ipairs(Gladius.DR_CATEGORIES) do
        self.drState[category] = {
            severity = 0,
            lastApplication = 0,
        }

        local drFrame = self.drFrames[category]
        if drFrame then
            drFrame:Hide()
            drFrame.severity = 0
            drFrame.SeverityText:SetText("")
            drFrame.Cooldown:Clear()

            if drFrame.resetTimer then
                drFrame.resetTimer:Cancel()
                drFrame.resetTimer = nil
            end

            -- Restore default icon
            local iconID = Gladius.DR_CATEGORY_ICONS[category]
            if iconID then
                drFrame.Icon:SetTexture(iconID)
            end
        end
    end
end
