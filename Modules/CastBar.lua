--[[
    Gladius Midnight - Cast Bar Module
    Displays cast bar for arena opponents
    Updated for Midnight 12.0 API (C_DurationUtil, issecretvalue)
]]

local addonName, addon = ...
local CastBar = {}

-- Midnight 12.0 API: Duration object for cast timers
-- StatusBar:SetTimerDuration() handles secret duration values natively
local function CreateCastDuration(startTime, endTime)
    if C_DurationUtil and C_DurationUtil.CreateDuration then
        local duration = C_DurationUtil.CreateDuration()
        if duration and duration.SetTimeSpan then
            duration:SetTimeSpan(startTime, endTime)
            return duration
        end
    end
    return nil
end

-- ============================================================================
-- Module Registration
-- ============================================================================

function CastBar:OnRegister(core)
    self.core = core
end

function CastBar:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Cast Bar Elements
-- ============================================================================

function CastBar:CreateElements(frame)
    -- Cast bar container - PARENT TO UIParent to avoid clipping issues
    -- Positioned BELOW the main arena frame
    local castBar = CreateFrame("StatusBar", "GladiusMidnightCastBar" .. frame.index, UIParent, "BackdropTemplate")
    castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    castBar:SetStatusBarColor(1, 0.7, 0)
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)
    castBar:SetFrameStrata("MEDIUM")
    castBar:SetFrameLevel(10)

    -- Store reference to parent arena frame
    castBar.arenaFrame = frame

    -- Background
    castBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    castBar:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    castBar:SetBackdropBorderColor(0, 0, 0, 1)

    -- Spell icon
    local iconFrame = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
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
    castBar.iconFrame = iconFrame

    -- Spell name text
    local spellText = castBar:CreateFontString(nil, "OVERLAY")
    spellText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    spellText:SetPoint("LEFT", 4, 0)
    spellText:SetJustifyH("LEFT")
    castBar.spellText = spellText

    -- Cast time text
    local timeText = castBar:CreateFontString(nil, "OVERLAY")
    timeText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    timeText:SetPoint("RIGHT", -4, 0)
    timeText:SetJustifyH("RIGHT")
    castBar.timeText = timeText

    -- Spark (progress indicator)
    local spark = castBar:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetSize(20, 20)
    spark:SetBlendMode("ADD")
    castBar.spark = spark

    -- Track casting state
    castBar.casting = false
    castBar.channeling = false
    castBar.startTime = 0
    castBar.endTime = 0
    castBar.spellID = nil

    castBar:Hide()
    frame.moduleFrames.castBar = castBar
end

-- ============================================================================
-- Update Cast Bar Display
-- ============================================================================

function CastBar:Update(frame, testData)
    local castBar = frame.moduleFrames.castBar
    if not castBar then return end

    local db = self.core.db.profile.castBar

    -- Size and position (below the main arena frame - castBar is parented to UIParent)
    local height = db.height or 16
    local iconSize = height

    castBar:ClearAllPoints()
    castBar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", iconSize + 2, -2)
    castBar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2)
    castBar:SetHeight(height)

    -- Icon position
    castBar.iconFrame:SetSize(iconSize, iconSize)
    castBar.iconFrame:ClearAllPoints()
    castBar.iconFrame:SetPoint("TOPRIGHT", castBar, "TOPLEFT", -2, 0)

    if testData then
        -- Test mode - show a sample cast
        castBar:SetStatusBarColor(1, 0.7, 0)
        castBar:SetMinMaxValues(0, 1)
        castBar:SetValue(0.6)
        castBar.spellText:SetText("Polymorph")
        castBar.timeText:SetText("1.2s")
        castBar.iconFrame.icon:SetTexture("Interface\\Icons\\Spell_Nature_Polymorph")
        castBar.iconFrame:Show()
        castBar:Show()

        -- Position spark (delay to ensure width is calculated)
        C_Timer.After(0.05, function()
            if castBar:IsShown() then
                local width = castBar:GetWidth()
                if width > 0 then
                    castBar.spark:ClearAllPoints()
                    castBar.spark:SetPoint("CENTER", castBar, "LEFT", width * 0.6, 0)
                    castBar.spark:Show()
                end
            end
        end)
    else
        -- Not test mode - only show if actively casting
        if not castBar.casting and not castBar.channeling then
            castBar:Hide()
        end
    end
end

function CastBar:OnCastStart(frame, unit, spellID, isChannel)
    local castBar = frame.moduleFrames.castBar
    if not castBar then return end

    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId

    if isChannel then
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(unit)
    else
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
    end

    -- Midnight 12.0: Check if we got valid data before proceeding
    if not name then return end
    if not startTimeMS or not endTimeMS then return end

    -- Midnight 12.0 API: Check for secret values using issecretvalue()
    local startTime, endTime
    if issecretvalue and (issecretvalue(startTimeMS) or issecretvalue(endTimeMS)) then
        -- Secret values - cannot perform arithmetic, but can pass to native APIs
        -- For now, store the raw values and let the duration API handle it
        startTime = startTimeMS  -- Will be handled by duration object
        endTime = endTimeMS
        castBar.usesDurationObject = true
    else
        -- Not secret - safe to perform arithmetic
        startTime = startTimeMS / 1000
        endTime = endTimeMS / 1000
        castBar.usesDurationObject = false
    end

    -- Setup cast bar
    castBar.casting = not isChannel
    castBar.channeling = isChannel
    castBar.startTime = startTime
    castBar.endTime = endTime
    castBar.spellID = spellId or spellID

    -- Midnight 12.0 API: Use C_DurationUtil for cast timer if available
    if castBar.usesDurationObject then
        local durationObj = CreateCastDuration(startTimeMS / 1000, endTimeMS / 1000)
        if durationObj and castBar.SetTimerDuration then
            -- Use native duration handling for secret values
            local direction = isChannel and Enum.StatusBarFillDirection.Reverse or Enum.StatusBarFillDirection.Standard
            castBar:SetTimerDuration(durationObj, direction)
        end
    else
        local duration = endTime - startTime
        castBar:SetMinMaxValues(0, duration)
    end

    -- Set color based on interruptibility
    if notInterruptible then
        castBar:SetStatusBarColor(0.7, 0.7, 0.7)  -- Grey for non-interruptible
    else
        if isChannel then
            castBar:SetStatusBarColor(0, 0.7, 1)  -- Blue for channel
        else
            castBar:SetStatusBarColor(1, 0.7, 0)  -- Orange for cast
        end
    end

    -- Midnight 12.0: FontString:SetText() accepts secret strings natively
    castBar.spellText:SetText(name)

    -- Set icon (texture may be secret but SetTexture accepts it)
    if texture then
        castBar.iconFrame.icon:SetTexture(texture)
    end
    castBar.iconFrame:Show()
    castBar.spark:Show()
    castBar:Show()
end

function CastBar:OnCastStop(frame)
    local castBar = frame.moduleFrames.castBar
    if not castBar then return end

    castBar.casting = false
    castBar.channeling = false
    castBar.startTime = 0
    castBar.endTime = 0
    castBar.spellID = nil
    castBar.spark:Hide()
    castBar:Hide()
end

function CastBar:OnCastInterrupted(frame)
    local castBar = frame.moduleFrames.castBar
    if not castBar then return end

    -- Flash red briefly
    castBar:SetStatusBarColor(1, 0, 0)
    castBar.spellText:SetText("Interrupted")

    -- Hide after a short delay
    C_Timer.After(0.5, function()
        self:OnCastStop(frame)
    end)
end

function CastBar:OnUpdate(frame)
    local castBar = frame.moduleFrames.castBar
    if not castBar then return end

    if not castBar.casting and not castBar.channeling then
        -- Check if unit started casting while we weren't watching
        local unit = frame.unit
        if UnitExists(unit) then
            local name = UnitCastingInfo(unit)
            if name then
                self:OnCastStart(frame, unit, nil, false)
                return
            end
            name = UnitChannelInfo(unit)
            if name then
                self:OnCastStart(frame, unit, nil, true)
                return
            end
        end
        return
    end

    local now = GetTime()

    if castBar.casting then
        local elapsed = now - castBar.startTime
        local duration = castBar.endTime - castBar.startTime

        if elapsed >= duration then
            self:OnCastStop(frame)
            return
        end

        castBar:SetValue(elapsed)
        castBar.timeText:SetText(string.format("%.1fs", duration - elapsed))

        -- Update spark position
        local width = castBar:GetWidth()
        if width > 0 then
            local progress = elapsed / duration
            castBar.spark:ClearAllPoints()
            castBar.spark:SetPoint("CENTER", castBar, "LEFT", width * progress, 0)
        end

    elseif castBar.channeling then
        local remaining = castBar.endTime - now

        if remaining <= 0 then
            self:OnCastStop(frame)
            return
        end

        local duration = castBar.endTime - castBar.startTime
        castBar:SetValue(remaining)
        castBar.timeText:SetText(string.format("%.1fs", remaining))

        -- Update spark position (reverse for channel)
        local width = castBar:GetWidth()
        if width > 0 and duration > 0 then
            local progress = remaining / duration
            castBar.spark:ClearAllPoints()
            castBar.spark:SetPoint("CENTER", castBar, "LEFT", width * progress, 0)
        end
    end
end

function CastBar:Reset(frame)
    local castBar = frame.moduleFrames.castBar
    if castBar then
        castBar.casting = false
        castBar.channeling = false
        castBar.startTime = 0
        castBar.endTime = 0
        castBar.spellID = nil
        castBar:SetValue(0)
        castBar.spellText:SetText("")
        castBar.timeText:SetText("")
        castBar.spark:Hide()
        castBar:Hide()
    end
end

-- Register module
addon.Core:RegisterModule("castBar", CastBar)
