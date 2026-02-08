--[[
    Gladius Midnight - Modern Castbar Module
    Provides a modern (retail-style) castbar with rounded corners,
    custom coloring, and the SmallCastingBarFrameTemplate.
    Supports switching between modern and classic castbar styles.
]]

-----------------------------------------------------------------------
-- Cast stop events (used to detect when a cast ends)
-----------------------------------------------------------------------
local CastStopEvents = {
    UNIT_SPELLCAST_STOP                = true,
    UNIT_SPELLCAST_FAILED              = true,
    UNIT_SPELLCAST_FAILED_QUIET        = true,
    UNIT_SPELLCAST_INTERRUPTED         = true,
    UNIT_SPELLCAST_CHANNEL_STOP        = true,
    UNIT_SPELLCAST_CHANNEL_INTERRUPTED = true,
}

-----------------------------------------------------------------------
-- GladiusCastBarExtMixin: Extension mixin for CastingBarMixin
-- Applied via XML: mixin="CastingBarMixin,GladiusCastBarExtMixin"
-----------------------------------------------------------------------
local defaultBarTexture = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"

GladiusCastBarExtMixin.typeInfo = {
    filling = defaultBarTexture,
    full    = defaultBarTexture,
    glow    = defaultBarTexture,
}

-- Default action colors for each bar type
local actionColors = {
    applyingcrafting = { 1.0, 0.7, 0.0, 1 },
    applyingtalents  = { 1.0, 0.7, 0.0, 1 },
    filling          = { 1.0, 0.7, 0.0, 1 },
    full             = { 0.0, 1.0, 0.0, 1 },
    standard         = { 1.0, 0.7, 0.0, 1 },
    empowered        = { 1.0, 0.7, 0.0, 1 },
    channel          = { 0.0, 1.0, 0.0, 1 },
    uninterruptable  = { 0.7, 0.7, 0.7, 1 },
    interrupted      = { 1.0, 0.0, 0.0, 1 },
}

-----------------------------------------------------------------------
-- GetTypeInfo: Return bar texture and apply coloring for a cast type
-----------------------------------------------------------------------
function GladiusCastBarExtMixin:GetTypeInfo(barType)
    barType = barType or "standard"

    -- Start with default colors, override from config if enabled
    local colorToUse = actionColors[barType]
    local castColors = GladiusMixin.castbarColors

    if castColors and castColors.enabled then
        if barType == "standard" or barType == "filling" or barType == "empowered" then
            colorToUse = castColors.standard or colorToUse
        elseif barType == "channel" or barType == "full" then
            colorToUse = castColors.channel or colorToUse
        elseif barType == "uninterruptable" then
            colorToUse = castColors.uninterruptable or colorToUse
        end
    end

    -- Desaturate the bar texture when using default modern textures with custom colors
    if GladiusMixin.keepDefaultModernTextures and castColors and castColors.enabled then
        local barTexture = self:GetStatusBarTexture()
        if barTexture then
            barTexture:SetDesaturated(true)
        end
    end

    self:SetStatusBarColor(unpack(colorToUse))

    local tex = GladiusMixin.castTexture or self.typeInfo.filling
    return {
        filling = tex,
        full    = tex,
        glow    = tex,
    }
end

-----------------------------------------------------------------------
-- Local helpers
-----------------------------------------------------------------------
local function CopyFrameAnchors(source, dest)
    dest:ClearAllPoints()
    for i = 1, source:GetNumPoints() do
        local pt, rel, relPt, x, y = source:GetPoint(i)
        dest:SetPoint(pt, rel, relPt, x, y)
    end
end

local function DisableCastBar(bar)
    if not bar then return end
    bar:SetUnit(nil)
    bar:Hide()
end

local function EnableCastBar(bar, unit, style, simpleCastbar)
    if not bar then return end

    bar:SetUnit(unit, true, false)
    bar.empoweredFix = true
    if bar.UpdateInterruptibleState then bar:UpdateInterruptibleState() end
    if bar.UpdateDisplayedVisuals then bar:UpdateDisplayedVisuals() end
    if bar.UpdateDisplayType then bar:UpdateDisplayType() end

    if style == "modern" then
        if simpleCastbar then
            bar.Text:ClearAllPoints()
            bar.Text:SetPoint("CENTER", bar, "CENTER", 0, 0)
            if bar.TextBorder then bar.TextBorder:Hide() end
        else
            bar.Text:ClearAllPoints()
            bar.Text:SetPoint("BOTTOM", bar, 0, -14)
            if bar.TextBorder then bar.TextBorder:Show() end
        end
        bar:SetHeight(9)
    else
        bar.Text:ClearAllPoints()
        bar.Text:SetPoint("CENTER", bar, "CENTER", 0, 0)
        bar:SetHeight(16)
    end

    bar:Show()
end

-----------------------------------------------------------------------
-- Ensure classic castbar reference is stored
-----------------------------------------------------------------------
local function EnsureClassicBar(frame)
    if frame.classicCastBar and frame.classicCastBar ~= frame.CastBar then
        return frame.classicCastBar
    end
    frame.classicCastBar = frame.CastBar
    return frame.classicCastBar
end

-----------------------------------------------------------------------
-- Create or return the modern castbar for a frame
-----------------------------------------------------------------------
local function EnsureModernBar(frame, unit)
    if frame.modernCastBar and frame.modernCastBar:IsObjectType("StatusBar") then
        return frame.modernCastBar
    end

    local oldBar = EnsureClassicBar(frame)
    local parent = oldBar:GetParent() or frame

    local newBar = CreateFrame("StatusBar", nil, parent, "SmallCastingBarFrameTemplate")
    newBar:SetMovable(true)

    if newBar.OnLoad then
        newBar:OnLoad(nil, true, false)
    end

    if not newBar.customTextureFix then
        newBar.isClassicStyle = true
        newBar.customTextureFix = true
    end

    -- Set up status bar texture
    newBar:SetStatusBarTexture(GladiusMixin.castTexture or defaultBarTexture)

    -- Create rounded-corner mask
    if not newBar.MaskTexture then
        newBar.MaskTexture = newBar:CreateMaskTexture()
    end
    local castTex = newBar:GetStatusBarTexture()
    newBar.MaskTexture:SetTexture(
        "Interface\\AddOns\\GladiusMidnight\\Textures\\RetailCastMask.tga",
        "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    newBar.MaskTexture:SetPoint("TOPLEFT", newBar, "TOPLEFT", -1, 0)
    newBar.MaskTexture:SetPoint("BOTTOMRIGHT", newBar, "BOTTOMRIGHT", 1, 0)
    newBar.MaskTexture:Show()
    castTex:AddMaskTexture(newBar.MaskTexture)

    -- Hook events to handle cast stop and custom coloring
    newBar:HookScript("OnEvent", function(castBar, event, eventUnit)
        if CastStopEvents[event] and eventUnit == unit then
            if castBar.interruptedBy then
                castBar:Show()
            else
                local activeCast = UnitCastingInfo(unit) or UnitChannelInfo(unit)
                if not activeCast then
                    castBar:Hide()
                    return
                end
            end
        end
        GladiusMixin:CastbarOnEvent(newBar)
    end)

    -- Restore custom texture after finish animation
    hooksecurefunc(newBar, "PlayFinishAnim", function(self)
        if GladiusMixin.keepDefaultModernTextures then return end
        self:SetStatusBarTexture(GladiusMixin.castTexture)
    end)

    newBar.__modernHooked = true

    -- Apply dark mode if active
    if GladiusMixin:DarkMode() then
        local dmColor = GladiusMixin:DarkModeColor()
        if newBar.TextBorder then
            newBar.TextBorder:SetDesaturated(true)
            newBar.TextBorder:SetVertexColor(dmColor, dmColor, dmColor)
        end
        if newBar.Border then
            newBar.Border:SetDesaturated(true)
            newBar.Border:SetVertexColor(dmColor, dmColor, dmColor)
        end
    end

    -- Match size, position, and strata of the old bar
    newBar:SetSize(oldBar:GetWidth(), oldBar:GetHeight())
    CopyFrameAnchors(oldBar, newBar)
    newBar:SetFrameStrata(oldBar:GetFrameStrata())
    newBar:SetFrameLevel(oldBar:GetFrameLevel())
    newBar:Hide()

    -- Fine-tune spark and border sizing
    newBar.Spark:SetSize(3, 16)
    if newBar.Border then
        newBar.Border:SetPoint("TOPLEFT", newBar, "TOPLEFT", -1.4, 1.6)
        newBar.Border:SetPoint("BOTTOMRIGHT", newBar, "BOTTOMRIGHT", 1.4, -1.6)
    end

    frame.modernCastBar = newBar
    return newBar
end

-----------------------------------------------------------------------
-- ApplyCastbarStyle: Switch between modern and classic for a frame
-----------------------------------------------------------------------
function GladiusMixin:ApplyCastbarStyle(frame, unit, modern, simpleCastbar)
    if InCombatLockdown and InCombatLockdown() then
        frame.__pendingCastbarStyle = modern and "modern" or "classic"
        frame.__pendingSimpleCastbar = simpleCastbar
        return
    end

    local classicBar = EnsureClassicBar(frame)
    local modernBar = EnsureModernBar(frame, unit)

    if modern then
        DisableCastBar(classicBar)
        EnableCastBar(modernBar, unit or classicBar.unit, "modern", simpleCastbar)
        frame.CastBar = modernBar
    else
        DisableCastBar(modernBar)
        EnableCastBar(classicBar, unit or modernBar.unit or classicBar.unit, "classic", simpleCastbar)
        frame.CastBar = classicBar
    end

    frame.__pendingCastbarStyle = nil
    frame.__pendingSimpleCastbar = nil
end
