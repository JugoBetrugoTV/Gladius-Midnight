--[[=========================================================================
    Gladius Midnight - Frames
    Arena unit frame mixin: handles health, power, name, unit events
===========================================================================]]

local _, Gladius = ...

GladiusArenaFrameMixin = {}

-- =========================================================================
-- Frame Lifecycle
-- =========================================================================
function GladiusArenaFrameMixin:OnLoad()
    -- Unit state
    self.unitClass = nil
    self.unitRace = nil
    self.unitSpecID = nil
    self.unitName = nil
    self.isDead = false

    -- DR state per category
    self.drState = {}
    self.drFrames = {}

    -- Aura state
    self.currentAuraSpellID = nil
    self.currentAuraPriority = 0

    -- Interrupt state
    self.isInterrupted = false
    self.interruptExpiration = 0

    -- Cast bar state
    self.castBarActive = false

    -- Create DR icon frames
    self:BuildDRFrames()
end

function GladiusArenaFrameMixin:OnEvent(event, eventUnit, ...)
    if eventUnit ~= self.unitID then return end

    if event == "ARENA_OPPONENT_UPDATE" then
        local updateReason = ...
        self:OnOpponentUpdate(updateReason)
    elseif event == "ARENA_COOLDOWNS_UPDATE" then
        self:RefreshTrinket()
    elseif event == "UNIT_HEALTH" then
        self:RefreshHealthBar()
    elseif event == "UNIT_MAXHEALTH" then
        self:RefreshHealthBar()
    elseif event == "UNIT_POWER_UPDATE" then
        self:RefreshPowerBar()
    elseif event == "UNIT_MAXPOWER" then
        self:RefreshPowerBar()
    elseif event == "UNIT_DISPLAYPOWER" then
        self:RefreshPowerType()
    elseif event == "UNIT_AURA" then
        self:RefreshAuras()
    elseif event == "UNIT_NAME_UPDATE" then
        self:RefreshName()
    elseif event == "UNIT_SPELLCAST_START" then
        self:OnCastStart(...)
    elseif event == "UNIT_SPELLCAST_STOP"
        or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_FAILED_QUIET"
        or event == "UNIT_SPELLCAST_INTERRUPTED" then
        self:OnCastEnd()
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        self:OnChannelStart(...)
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        self:OnCastEnd()
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
        self:OnCastInterruptible()
    elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        self:OnCastNotInterruptible()
    end
end

function GladiusArenaFrameMixin:OnEnter()
    if not self.unitID then return end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetUnit(self.unitID)
    GameTooltip:Show()

    -- Show health/power text on hover
    if self.HealthText then self.HealthText:Show() end
    if self.PowerText then self.PowerText:Show() end
end

function GladiusArenaFrameMixin:OnLeave()
    GameTooltip:Hide()
    local db = Gladius.db.profile
    if not db.showHealthText then
        self.HealthText:Hide()
    end
    if not db.showPowerText then
        self.PowerText:Hide()
    end
end

-- =========================================================================
-- Unit Event Registration
-- =========================================================================
function GladiusArenaFrameMixin:RegisterUnitEvents()
    self:RegisterUnitEvent("ARENA_OPPONENT_UPDATE", self.unitID)
    self:RegisterUnitEvent("ARENA_COOLDOWNS_UPDATE", self.unitID)
    self:RegisterUnitEvent("UNIT_HEALTH", self.unitID)
    self:RegisterUnitEvent("UNIT_MAXHEALTH", self.unitID)
    self:RegisterUnitEvent("UNIT_POWER_UPDATE", self.unitID)
    self:RegisterUnitEvent("UNIT_MAXPOWER", self.unitID)
    self:RegisterUnitEvent("UNIT_DISPLAYPOWER", self.unitID)
    self:RegisterUnitEvent("UNIT_AURA", self.unitID)
    self:RegisterUnitEvent("UNIT_NAME_UPDATE", self.unitID)
    self:RegisterUnitEvent("UNIT_SPELLCAST_START", self.unitID)
    self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", self.unitID)
    self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", self.unitID)
    self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET", self.unitID)
    self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", self.unitID)
    self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", self.unitID)
    self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", self.unitID)
    self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", self.unitID)
    self:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", self.unitID)
end

function GladiusArenaFrameMixin:UnregisterUnitEvents()
    self:UnregisterAllEvents()
end

-- =========================================================================
-- State Management
-- =========================================================================
function GladiusArenaFrameMixin:ResetState()
    self.unitClass = nil
    self.unitRace = nil
    self.unitSpecID = nil
    self.unitName = nil
    self.isDead = false
    self.currentAuraSpellID = nil
    self.currentAuraPriority = 0
    self.isInterrupted = false
    self.interruptExpiration = 0
    self.castBarActive = false

    self:ResetDRState()
    self:ResetCastBar()
    self:ResetClassIcon()
    self:ResetTrinket()
    self:ResetRacial()

    self.NameText:SetText("")
    self.HealthText:SetText("")
    self.PowerText:SetText("")
    self.HealthBar:SetValue(0)
    self.PowerBar:SetValue(0)
    self.TargetHighlight:Hide()
    self.FocusHighlight:Hide()
    self.DeathOverlay:Hide()
end

-- =========================================================================
-- Apply Visual Settings
-- =========================================================================
function GladiusArenaFrameMixin:ApplySettings()
    local db = Gladius.db.profile

    -- Frame size
    self:SetSize(db.frameWidth, db.frameHeight)
    self:SetScale(db.frameScale)

    -- Background
    self.Background:SetColorTexture(0.05, 0.05, 0.05, db.bgAlpha)

    -- Health bar
    self.HealthBar:SetStatusBarTexture(db.barTexture)
    self.HealthBar:SetHeight(db.frameHeight - db.powerBarHeight - 1)

    -- Power bar
    self.PowerBar:SetStatusBarTexture(db.barTexture)
    self.PowerBar:SetHeight(db.powerBarHeight)

    -- Class icon size
    self.ClassIcon:SetSize(db.classIconSize, db.classIconSize)
    self.ClassIcon.Icon:SetSize(db.classIconSize - 4, db.classIconSize - 4)
    self.ClassIcon.Cooldown:SetSize(db.classIconSize - 4, db.classIconSize - 4)
    self.ClassIcon:SetShown(db.classIconEnabled)

    -- Trinket
    self.TrinketIcon:SetSize(db.trinketSize, db.trinketSize)
    self.TrinketIcon:SetShown(db.trinketEnabled)

    -- Racial
    self.RacialIcon:SetSize(db.racialSize, db.racialSize)
    self.RacialIcon:SetShown(db.racialEnabled)

    -- Spec icon
    self.SpecIcon:SetShown(db.showSpecIcon)

    -- Cast bar
    self.CastBar:SetHeight(db.castBarHeight)
    self.CastBar:SetShown(false)
    self.CastBar.Icon:SetShown(db.castBarShowIcon)
    self.CastBar.TimeText:SetShown(db.castBarShowTime)

    -- Health/Power text visibility
    self.HealthText:SetShown(db.showHealthText)
    self.PowerText:SetShown(db.showPowerText)
    self.NameText:SetShown(db.showNames)

    -- DR frames
    self:UpdateDRLayout()
end

-- =========================================================================
-- Opponent Update (Arena entry / visibility change)
-- =========================================================================
function GladiusArenaFrameMixin:OnOpponentUpdate(updateReason)
    if updateReason == "seen" or updateReason == "cleared" then
        if UnitExists(self.unitID) then
            self:PopulateUnitData()
            self:Show()
        else
            self:Hide()
        end
    elseif updateReason == "destroyed" then
        self:Hide()
        self:ResetState()
    end
end

function GladiusArenaFrameMixin:PopulateUnitData()
    local unit = self.unitID

    -- Class
    local _, classToken = UnitClass(unit)
    self.unitClass = classToken

    -- Race
    local _, raceToken = UnitRace(unit)
    self.unitRace = raceToken

    -- Name
    self.unitName = UnitName(unit)

    -- Spec
    local specID = GetArenaOpponentSpec(self.frameIndex)
    if specID and specID > 0 then
        self:SetSpecialization(specID)
    end

    -- Apply all visual updates
    self:RefreshName()
    self:RefreshClassIcon()
    self:RefreshHealthBar()
    self:RefreshPowerType()
    self:RefreshPowerBar()
    self:RefreshTrinket()
    self:RefreshRacial()
    self:RefreshAuras()
    self:RefreshLifeState()
end

-- =========================================================================
-- Health Bar
-- =========================================================================
function GladiusArenaFrameMixin:RefreshHealthBar()
    local unit = self.unitID
    if Gladius.isTestMode then return end
    if not UnitExists(unit) then return end

    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)

    if maxHealth > 0 then
        self.HealthBar:SetMinMaxValues(0, maxHealth)
        self.HealthBar:SetValue(health)

        local pct = math.floor((health / maxHealth) * 100)
        if Gladius.db.profile.showHealthText then
            self.HealthText:SetText(pct .. "%")
        end
    end

    -- Class-colored health bar
    if Gladius.db.profile.classColorBars and self.unitClass then
        local color = Gladius.CLASS_COLORS[self.unitClass]
        if color then
            self.HealthBar:SetStatusBarColor(color.r, color.g, color.b)
        end
    else
        self.HealthBar:SetStatusBarColor(0.2, 0.8, 0.2)
    end

    self:RefreshLifeState()
end

function GladiusArenaFrameMixin:RefreshLifeState()
    local unit = self.unitID
    if not UnitExists(unit) then return end

    local isDead = UnitIsDeadOrGhost(unit)
    local isFeign = UnitIsFeignDeath(unit)

    self.isDead = isDead and not isFeign
    self.DeathOverlay:SetShown(self.isDead)

    if isFeign then
        self.HealthBar:SetAlpha(0.4)
    elseif self.isDead then
        self.HealthBar:SetAlpha(0.3)
    else
        self.HealthBar:SetAlpha(1.0)
    end
end

-- =========================================================================
-- Power Bar
-- =========================================================================
function GladiusArenaFrameMixin:RefreshPowerBar()
    local unit = self.unitID
    if Gladius.isTestMode then return end
    if not UnitExists(unit) then return end

    local powerType = UnitPowerType(unit)
    local power = UnitPower(unit, powerType)
    local maxPower = UnitPowerMax(unit, powerType)

    if maxPower > 0 then
        self.PowerBar:SetMinMaxValues(0, maxPower)
        self.PowerBar:SetValue(power)

        if Gladius.db.profile.showPowerText then
            local pct = math.floor((power / maxPower) * 100)
            self.PowerText:SetText(pct .. "%")
        end
    end
end

function GladiusArenaFrameMixin:RefreshPowerType()
    local unit = self.unitID
    if not UnitExists(unit) and not Gladius.isTestMode then return end

    local powerType
    if Gladius.isTestMode then
        powerType = Enum.PowerType.Mana
    else
        powerType = UnitPowerType(unit)
    end

    local color = Gladius.POWER_COLORS[powerType]
    if color then
        self.PowerBar:SetStatusBarColor(color.r, color.g, color.b)
    else
        self.PowerBar:SetStatusBarColor(0.0, 0.5, 1.0)
    end
end

-- =========================================================================
-- Name Display
-- =========================================================================
function GladiusArenaFrameMixin:RefreshName()
    local unit = self.unitID
    local name

    if Gladius.isTestMode then
        name = self.unitName
    else
        name = UnitName(unit)
        self.unitName = name
    end

    if name and Gladius.db.profile.showNames then
        self.NameText:SetText(name)

        -- Class-colored name
        if Gladius.db.profile.classColorNames and self.unitClass then
            local color = Gladius.CLASS_COLORS[self.unitClass]
            if color then
                self.NameText:SetTextColor(color.r, color.g, color.b)
                return
            end
        end
        self.NameText:SetTextColor(1, 1, 1)
    end
end

-- =========================================================================
-- Specialization
-- =========================================================================
function GladiusArenaFrameMixin:SetSpecialization(specID)
    self.unitSpecID = specID

    if not Gladius.db.profile.showSpecIcon then return end
    if not specID or specID == 0 then
        self.SpecIcon.Icon:SetTexture(nil)
        return
    end

    local _, _, _, icon = GetSpecializationInfoByID(specID)
    if icon then
        self.SpecIcon.Icon:SetTexture(icon)
        self.SpecIcon:Show()
    end
end

-- =========================================================================
-- Test Mode Data
-- =========================================================================
function GladiusArenaFrameMixin:SetTestData(name, class, race, healthPct, powerPct)
    self.unitName = name
    self.unitClass = class
    self.unitRace = race
    self.isDead = false

    -- Name
    self:RefreshName()

    -- Class icon
    self:RefreshClassIcon()

    -- Health bar
    local db = Gladius.db.profile
    self.HealthBar:SetMinMaxValues(0, 100)
    self.HealthBar:SetValue(healthPct)
    if db.showHealthText then
        self.HealthText:SetText(healthPct .. "%")
    end
    if db.classColorBars and class then
        local color = Gladius.CLASS_COLORS[class]
        if color then
            self.HealthBar:SetStatusBarColor(color.r, color.g, color.b)
        end
    end

    -- Power bar
    self.PowerBar:SetMinMaxValues(0, 100)
    self.PowerBar:SetValue(powerPct)
    self:RefreshPowerType()

    -- Trinket
    self:SetTestTrinket()

    -- Racial
    self:SetTestRacial()

    -- Show spec icon placeholder
    self.SpecIcon.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    -- Indicators off
    self.TargetHighlight:Hide()
    self.FocusHighlight:Hide()
    self.DeathOverlay:Hide()
end
