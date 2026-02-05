--[[
    Gladius Midnight - Cast Bar Module
    Displays cast bar for arena opponents
]]

local addonName, addon = ...
local CastBar = {}

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

    -- In Midnight 12.0, cast data for arena opponents is "secret"
    -- Check if we got valid data before proceeding
    if not name then return end
    if not startTimeMS or not endTimeMS then return end
    if type(startTimeMS) ~= "number" or type(endTimeMS) ~= "number" then return end

    -- Setup cast bar
    castBar.casting = not isChannel
    castBar.channeling = isChannel
    castBar.startTime = startTimeMS / 1000
    castBar.endTime = endTimeMS / 1000
    castBar.spellID = spellId or spellID

    local duration = castBar.endTime - castBar.startTime

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

    castBar:SetMinMaxValues(0, duration)
    castBar.spellText:SetText(name)

    -- Set icon
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
