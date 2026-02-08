--[[=========================================================================
    Gladius Midnight - Cast Bar Module
    Displays enemy cast bars with spell name, icon, and timer
    Colors bar based on interruptibility and player interrupt availability
===========================================================================]]

local _, Gladius = ...

-- =========================================================================
-- Cast Bar Event Handlers
-- =========================================================================
function GladiusArenaFrameMixin:OnCastStart(spellName, spellID)
    if not Gladius.db.profile.castBarEnabled then return end

    local unit = self.unitID
    if not UnitExists(unit) then return end

    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId
    if C_Spell and C_Spell.GetSpellInfo then
        name = spellName
        local info = UnitCastingInfo and UnitCastingInfo(unit)
        if type(info) == "table" then
            name = info.name or spellName
            texture = info.iconID
            startTimeMS = info.startTime
            endTimeMS = info.endTime
            notInterruptible = info.notInterruptible
        else
            -- Fallback to positional returns
            name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
        end
    else
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
    end

    if not name then return end

    local castBar = self.CastBar
    local startTime = (startTimeMS or 0) / 1000
    local endTime = (endTimeMS or 0) / 1000
    local duration = endTime - startTime

    castBar:SetMinMaxValues(0, duration)
    castBar:SetValue(0)

    castBar.SpellText:SetText(name)
    if texture then
        castBar.Icon:SetTexture(texture)
    end

    -- Color based on interruptibility
    self:ApplyCastBarColor(notInterruptible, false)

    castBar.startTime = startTime
    castBar.endTime = endTime
    castBar.isChanneling = false
    castBar.castBarActive = true

    castBar:SetScript("OnUpdate", function(bar, elapsed)
        self:CastBarOnUpdate(bar)
    end)

    castBar:Show()
    castBar.Spark:Show()
    castBar.BorderShield:SetShown(notInterruptible)
end

function GladiusArenaFrameMixin:OnChannelStart(spellName, spellID)
    if not Gladius.db.profile.castBarEnabled then return end

    local unit = self.unitID
    if not UnitExists(unit) then return end

    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId
    if UnitChannelInfo then
        local info = UnitChannelInfo(unit)
        if type(info) == "table" then
            name = info.name or spellName
            texture = info.iconID
            startTimeMS = info.startTime
            endTimeMS = info.endTime
            notInterruptible = info.notInterruptible
        else
            name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(unit)
        end
    end

    if not name then return end

    local castBar = self.CastBar
    local startTime = (startTimeMS or 0) / 1000
    local endTime = (endTimeMS or 0) / 1000
    local duration = endTime - startTime

    castBar:SetMinMaxValues(0, duration)
    castBar:SetValue(duration)

    castBar.SpellText:SetText(name)
    if texture then
        castBar.Icon:SetTexture(texture)
    end

    -- Channel color
    self:ApplyCastBarColor(notInterruptible, true)

    castBar.startTime = startTime
    castBar.endTime = endTime
    castBar.isChanneling = true
    castBar.castBarActive = true

    castBar:SetScript("OnUpdate", function(bar, elapsed)
        self:CastBarOnUpdate(bar)
    end)

    castBar:Show()
    castBar.Spark:Show()
    castBar.BorderShield:SetShown(notInterruptible)
end

function GladiusArenaFrameMixin:OnCastEnd()
    self:ResetCastBar()
end

function GladiusArenaFrameMixin:OnCastInterruptible()
    local castBar = self.CastBar
    if castBar.castBarActive then
        self:ApplyCastBarColor(false, castBar.isChanneling)
        castBar.BorderShield:Hide()
    end
end

function GladiusArenaFrameMixin:OnCastNotInterruptible()
    local castBar = self.CastBar
    if castBar.castBarActive then
        self:ApplyCastBarColor(true, castBar.isChanneling)
        castBar.BorderShield:Show()
    end
end

-- =========================================================================
-- Cast Bar Update Loop
-- =========================================================================
function GladiusArenaFrameMixin:CastBarOnUpdate(castBar)
    local now = GetTime()

    if now > castBar.endTime then
        self:ResetCastBar()
        return
    end

    local elapsed = now - castBar.startTime
    local duration = castBar.endTime - castBar.startTime

    if castBar.isChanneling then
        castBar:SetValue(castBar.endTime - now)
    else
        castBar:SetValue(elapsed)
    end

    -- Position spark
    local sparkPos = elapsed / duration
    if castBar.isChanneling then
        sparkPos = 1.0 - sparkPos
    end
    local barWidth = castBar:GetWidth()
    castBar.Spark:SetPoint("CENTER", castBar, "LEFT", barWidth * sparkPos, 0)

    -- Update time text
    if Gladius.db.profile.castBarShowTime then
        local remaining = castBar.endTime - now
        castBar.TimeText:SetFormattedText("%.1f", remaining)
    end
end

-- =========================================================================
-- Cast Bar Colors
-- =========================================================================
function GladiusArenaFrameMixin:ApplyCastBarColor(notInterruptible, isChannel)
    local colors = Gladius.db.profile.castBarColors
    local castBar = self.CastBar

    if notInterruptible then
        local c = colors.uninterruptible
        castBar:SetStatusBarColor(c.r, c.g, c.b)
    elseif isChannel then
        local c = colors.channel
        castBar:SetStatusBarColor(c.r, c.g, c.b)
    else
        -- Check if player's interrupt is on cooldown
        if Gladius.db.profile.interruptColorCastbar and Gladius.playerInterruptOnCD then
            local c = colors.interrupted
            castBar:SetStatusBarColor(c.r, c.g, c.b)
        else
            local c = colors.normal
            castBar:SetStatusBarColor(c.r, c.g, c.b)
        end
    end
end

-- =========================================================================
-- Reset
-- =========================================================================
function GladiusArenaFrameMixin:ResetCastBar()
    local castBar = self.CastBar
    castBar:Hide()
    castBar:SetScript("OnUpdate", nil)
    castBar.SpellText:SetText("")
    castBar.TimeText:SetText("")
    castBar.Icon:SetTexture(nil)
    castBar.Spark:Hide()
    castBar.BorderShield:Hide()
    castBar.castBarActive = false
    castBar.isChanneling = false
end
