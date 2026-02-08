--[[
    Gladius Midnight - Frames
    Per-unit frame mixin: event handling, health/power updates,
    heal prediction, absorbs, class/spec icons, widgets, status text.
]]

local isMidnight = GladiusMixin.isMidnight
local isRetail = GladiusMixin.isRetail

local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitExists = UnitExists
local UnitClass = UnitClass
local UnitRace = UnitRace
local UnitName = UnitName
local GetTime = GetTime
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local GetSpellName = GetSpellName or C_Spell.GetSpellName

-----------------------------------------------------------------------
-- OnLoad: called when each enemy frame is created from XML template
-----------------------------------------------------------------------
function GladiusFrameMixin:OnLoad()
    self.parent = self:GetParent()
    local id = self:GetID()
    self.unit = "arena" .. id

    -- Register unit-specific events
    self:RegisterUnitEvent("UNIT_HEALTH", self.unit)
    self:RegisterUnitEvent("UNIT_MAXHEALTH", self.unit)
    self:RegisterUnitEvent("UNIT_POWER_UPDATE", self.unit)
    self:RegisterUnitEvent("UNIT_MAXPOWER", self.unit)
    self:RegisterUnitEvent("UNIT_DISPLAYPOWER", self.unit)
    self:RegisterUnitEvent("UNIT_NAME_UPDATE", self.unit)

    -- Non-Midnight: register additional unit events for auras & absorbs
    if not isMidnight then
        self:RegisterUnitEvent("UNIT_AURA", self.unit)
        self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", self.unit)
        self:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", self.unit)
    end

    -- Global events
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    self:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")

    -- Click-to-target / click-to-focus
    self:SetAttribute("type1", "macro")
    self:SetAttribute("macrotext1", "/targetexact " .. self.unit)
    self:SetAttribute("type2", "macro")
    self:SetAttribute("macrotext2", "/focus " .. self.unit)

    -- CastBar creation for non-Midnight
    if not isMidnight then
        local castBar = CreateFrame("StatusBar", nil, self, "GladiusCastBarTemplate")
        castBar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        castBar:SetSize(self:GetWidth(), 16)
        castBar:SetUnit(self.unit, false, true)
        self.CastBar = castBar

        -- Hook castbar events for custom coloring
        if castBar.OnEvent then
            hooksecurefunc(castBar, "OnEvent", function(bar)
                GladiusMixin:CastbarOnEvent(bar)
            end)
        end
    end

    -- Midnight: hook Blizzard CompactArenaFrame elements
    if isMidnight then
        self:HookBlizzardArenaFrame(id)
    end

    -- Initialize health/power bars
    if self.HealthBar then
        self.HealthBar:SetMinMaxValues(0, 100)
        self.HealthBar:SetValue(100)
    end
    if self.PowerBar then
        self.PowerBar:SetMinMaxValues(0, 100)
        self.PowerBar:SetValue(100)
    end

    -- Heal prediction bar initial setup (Retail only, hidden on Midnight)
    if isMidnight then
        if self.myHealPredictionBar then self.myHealPredictionBar:Hide() end
        if self.otherHealPredictionBar then self.otherHealPredictionBar:Hide() end
        if self.totalAbsorbBar then self.totalAbsorbBar:Hide() end
        if self.healAbsorbBar then self.healAbsorbBar:Hide() end
        if self.overAbsorbGlow then self.overAbsorbGlow:Hide() end
        if self.overHealAbsorbGlow then self.overHealAbsorbGlow:Hide() end
        if self.totalAbsorbBarOverlay then self.totalAbsorbBarOverlay:Hide() end
    end

    -- Widget overlay atlas setup
    if self.WidgetOverlay then
        local wo = self.WidgetOverlay
        if wo.targetIndicator and wo.targetIndicator.atlas then
            wo.targetIndicator.Texture:SetAtlas(wo.targetIndicator.atlas)
        end
        if wo.focusIndicator and wo.focusIndicator.atlas then
            wo.focusIndicator.Texture:SetAtlas(wo.focusIndicator.atlas)
        end
        if wo.combatIndicator and wo.combatIndicator.atlas then
            wo.combatIndicator.Texture:SetAtlas(wo.combatIndicator.atlas)
        end
        if wo.partyTarget1 and wo.partyTarget1.atlas then
            wo.partyTarget1.Texture:SetAtlas(wo.partyTarget1.atlas)
            if wo.partyTarget1.desaturated then
                wo.partyTarget1.Texture:SetDesaturated(true)
            end
        end
        if wo.partyTarget2 and wo.partyTarget2.atlas then
            wo.partyTarget2.Texture:SetAtlas(wo.partyTarget2.atlas)
            if wo.partyTarget2.desaturated then
                wo.partyTarget2.Texture:SetDesaturated(true)
            end
        end
    end

    -- Create DR frames for non-Midnight
    if not isMidnight and GladiusMixin.drCategories then
        for _, cat in ipairs(GladiusMixin.drCategories) do
            local drFrame = CreateFrame("Frame", nil, self, "GladiusDRTemplate")
            drFrame:SetSize(28, 28)
            drFrame.category = cat
            self[cat] = drFrame
        end
    end
end

-----------------------------------------------------------------------
-- Hook Blizzard CompactArenaFrame (Midnight only)
-----------------------------------------------------------------------
function GladiusFrameMixin:HookBlizzardArenaFrame(id)
    -- On Midnight, Blizzard provides CompactArenaFrameMember1/2/3
    local blizzFrame = _G["CompactArenaFrameMember" .. id]
    if not blizzFrame then return end

    -- Hook the CastBar from Blizzard's frame
    if blizzFrame.CastBar then
        self.CastBar = blizzFrame.CastBar
        -- Hook castbar events for our custom coloring
        hooksecurefunc(blizzFrame.CastBar, "OnEvent", function(bar)
            GladiusMixin:CastbarOnEvent(bar)
        end)
    end

    -- Hook debuff icon for aura display on ClassIcon
    if blizzFrame.DebuffFrame and blizzFrame.DebuffFrame.Icon then
        local debuffIcon = blizzFrame.DebuffFrame.Icon
        hooksecurefunc(debuffIcon, "SetTexture", function(_, texture)
            if self.ClassIcon and texture then
                -- The Blizzard debuff frame shows the highest priority aura
                -- We use this to update our class icon overlay
                self._blizzAuraTexture = texture
            end
        end)
    end

    -- Hook trinket from CcRemoverFrame
    if blizzFrame.CcRemoverFrame then
        local ccFrame = blizzFrame.CcRemoverFrame
        if ccFrame.Cooldown then
            hooksecurefunc(ccFrame.Cooldown, "SetCooldown", function(_, start, duration)
                if self.Trinket and self.Trinket.Cooldown and start and duration then
                    self.Trinket.Cooldown:SetCooldown(start, duration)
                end
            end)
        end
    end

    -- Store reference for DR frame hooks
    self.blizzArenaFrame = blizzFrame
end

-----------------------------------------------------------------------
-- OnEvent: per-frame event routing
-----------------------------------------------------------------------
function GladiusFrameMixin:OnEvent(event, eventUnit, arg1)
    -- Unit-specific events
    if eventUnit == self.unit then
        if event == "UNIT_NAME_UPDATE" then
            self:UpdateName()

        elseif event == "ARENA_OPPONENT_UPDATE" then
            self:UpdatePlayer(arg1)

        elseif event == "ARENA_COOLDOWNS_UPDATE" then
            if self.UpdateTrinket then self:UpdateTrinket() end

        elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" then
            -- arg1 = spellID of CC break ability
            if arg1 and self.Trinket then
                local tex = GetSpellTexture(arg1)
                if tex then
                    self.Trinket.Texture:SetTexture(tex)
                end
                -- Detect if this is a racial ability on the trinket slot
                if self.UpdateRacial then
                    self:UpdateRacial()
                end
            end

        elseif event == "UNIT_AURA" then
            if self.FindAura then self:FindAura() end

        elseif event == "UNIT_HEALTH" then
            self:UpdateHealthBar()

        elseif event == "UNIT_MAXHEALTH" then
            if self.HealthBar then
                self.HealthBar:SetMinMaxValues(0, UnitHealthMax(self.unit))
                self.HealthBar:SetValue(UnitHealth(self.unit))
            end
            if not isMidnight then
                self:UpdateHealPrediction()
                self:UpdateAbsorb()
            end

        elseif event == "UNIT_POWER_UPDATE" then
            self:UpdatePowerBar()

        elseif event == "UNIT_MAXPOWER" then
            if self.PowerBar then
                self.PowerBar:SetMinMaxValues(0, UnitPowerMax(self.unit))
                self.PowerBar:SetValue(UnitPower(self.unit))
            end

        elseif event == "UNIT_DISPLAYPOWER" then
            self:UpdatePowerType()

        elseif event == "UNIT_ABSORB_AMOUNT_CHANGED"
            or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
            if not isMidnight then
                self:UpdateHealPrediction()
                self:UpdateAbsorb()
            end

        elseif event == "UNIT_FLAGS" then
            self:UpdateCombatStatus(self.unit)
        end

    -- Non-unit events
    elseif event == "PLAYER_LOGIN" then
        -- Initialize frame after parent if needed
        if not self.parent.db then return end
        self:FrameInitialize()

    elseif event == "PLAYER_ENTERING_WORLD"
        or event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        -- Reset frame state
        self.class = nil
        self.specName = nil
        self.specID = nil
        self.isHealer = false
        self.currentAuraSpellID = nil
        self.currentInterruptSpellID = nil

        if self.CastBar and not isMidnight then
            self.CastBar:Hide()
        end

        self:UpdateVisible()
        self:UpdatePlayer()

        if self.HealthBar then
            self.HealthBar:SetAlpha(1)
        end
    end
end

-----------------------------------------------------------------------
-- Frame initialization (called after parent is ready)
-----------------------------------------------------------------------
function GladiusFrameMixin:FrameInitialize()
    if self._frameInit then return end
    local parent = self.parent

    -- Setup drag handlers
    if parent.SetupDrag then
        parent:SetupDrag(self, self, "frame", function()
            parent:SetLayout(nil, parent.db.profile.currentLayout)
        end)

        if self.CastBar then
            parent:SetupDrag(self.CastBar, self.CastBar, "castBar", function()
                parent:SetLayout(nil, parent.db.profile.currentLayout)
            end)
        end

        if self.SpecIcon then
            parent:SetupDrag(self.SpecIcon, self.SpecIcon, "specIcon", function()
                parent:SetLayout(nil, parent.db.profile.currentLayout)
            end)
        end

        if self.Trinket then
            parent:SetupDrag(self.Trinket, self.Trinket, "trinket", function()
                parent:SetLayout(nil, parent.db.profile.currentLayout)
            end)
        end

        if self.Racial then
            parent:SetupDrag(self.Racial, self.Racial, "racial", function()
                parent:SetLayout(nil, parent.db.profile.currentLayout)
            end)
        end

        if self.Dispel then
            parent:SetupDrag(self.Dispel, self.Dispel, "dispel", function()
                parent:SetLayout(nil, parent.db.profile.currentLayout)
            end)
        end

        if self.ClassIcon then
            parent:SetupDrag(self.ClassIcon, self.ClassIcon, "classIcon", function()
                parent:SetLayout(nil, parent.db.profile.currentLayout)
            end)
        end

        -- Widget drag setup
        if self.WidgetOverlay then
            local wo = self.WidgetOverlay
            local widgets = {"targetIndicator", "focusIndicator", "combatIndicator",
                            "partyTarget1", "partyTarget2"}
            for _, wName in ipairs(widgets) do
                if wo[wName] then
                    parent:SetupDrag(wo[wName], wo[wName], wName, function()
                        parent:SetLayout(nil, parent.db.profile.currentLayout)
                    end, true)
                end
            end
        end
    end

    self._frameInit = true
end

-----------------------------------------------------------------------
-- OnEnter / OnLeave (tooltip)
-----------------------------------------------------------------------
function GladiusFrameMixin:OnEnter()
    if not self.unit then return end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetUnit(self.unit)
    GameTooltip:Show()
end

function GladiusFrameMixin:OnLeave()
    GameTooltip:Hide()
end

-----------------------------------------------------------------------
-- Visibility
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateVisible()
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then
        self:Hide()
        return
    end

    local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0
    if self:GetID() <= numOpponents then
        self:Show()
    end
end

-----------------------------------------------------------------------
-- Player update (populate frame with opponent data)
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdatePlayer(unitEvent)
    if not self.parent.db then return end

    self:GetClass()

    -- Update unit data if it exists
    if UnitExists(self.unit) then
        self:SetAlpha(1)
        self:UpdateName()
        self:UpdateHealthBar()
        self:UpdatePowerType()
        self:UpdatePowerBar()
        self:SetStatusText(self.unit)
        self:SetLifeState()

        -- Trinket, racial, dispel
        if self.UpdateTrinket then self:UpdateTrinket() end
        if self.UpdateRacial then self:UpdateRacial() end
        if self.UpdateDispel then self:UpdateDispel() end

        -- Widgets
        self:UpdateTarget(self.unit)
        self:UpdateFocus(self.unit)
        self:UpdatePartyTargets(self.unit)
        self:UpdateCombatStatus(self.unit)

        -- Auras
        if self.FindAura then self:FindAura() end

        -- Heal prediction & absorbs (Retail only)
        if not isMidnight then
            self:UpdateHealPrediction()
            self:UpdateAbsorb()
        end
    else
        -- Unit not visible (stealthed or not yet spawned)
        if unitEvent == "seen" then
            self:SetAlpha(GladiusMixin.stealthAlpha)
            self:SetMysteryPlayer()
        end
    end
end

-----------------------------------------------------------------------
-- Class & spec detection
-----------------------------------------------------------------------
function GladiusFrameMixin:GetClass()
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then
        self.class = nil
        self.specName = nil
        self.specID = nil
        self.isHealer = false
        if self.SpecIcon then self.SpecIcon:Hide() end
        return
    end

    local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(self:GetID())
    if specID and specID > 0 then
        local _, specName, _, specIcon, _, classFile = GetSpecializationInfoByID(specID)
        self.class = classFile
        self.specName = specName
        self.specID = specID
        self.specTexture = specIcon
        self.isHealer = GladiusMixin.healerSpecIDs[specID] or false

        if self.SpecIcon and specIcon then
            self.SpecIcon.Texture:SetTexture(specIcon)
        end
    elseif UnitExists(self.unit) then
        local _, classFile = UnitClass(self.unit)
        self.class = classFile
    end

    self:UpdateClassIcon()
    self:UpdateSpecIcon()
end

function GladiusFrameMixin:UpdateClassIcon(forceUpdate)
    if not self.ClassIcon then return end
    local db = self.parent.db
    if not db then return end
    local ls = db.profile.layoutSettings[db.profile.currentLayout]
    if not ls then return end

    -- If there's an active aura, show it instead of class icon
    if self.currentAuraSpellID and self.currentAuraTexture then
        self.ClassIcon.Texture:SetTexture(self.currentAuraTexture)
        if self.ClassIcon.Cooldown and self.currentAuraStartTime and self.currentAuraDuration then
            if self.currentAuraDuration > 0 then
                self.ClassIcon.Cooldown:SetCooldown(self.currentAuraStartTime, self.currentAuraDuration)
            else
                self.ClassIcon.Cooldown:Clear()
            end
        end
        self.ClassIcon:Show()
        self:SetTextureCrop(self.ClassIcon.Texture, true, "aura")

        -- Aura stacks display
        if self.AuraStacks and self.currentAuraStacks then
            if self.currentAuraStacks >= 2 then
                self.AuraStacks:SetText(self.currentAuraStacks)
                self.AuraStacks:Show()
            else
                self.AuraStacks:SetText("")
                self.AuraStacks:Hide()
            end
        end
        return
    end

    -- No aura active: show class or spec icon
    if self.AuraStacks then self.AuraStacks:Hide() end

    if ls.hideClassIcon then
        self.ClassIcon:Hide()
        return
    end

    if ls.replaceClassIcon and self.specTexture then
        self.ClassIcon.Texture:SetTexture(self.specTexture)
        self:SetTextureCrop(self.ClassIcon.Texture, ls.cropIcons, "class")
    elseif self.isHealer and ls.showHealerIcon then
        self.ClassIcon.Texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        self.ClassIcon.Texture:SetTexCoord(0.3125, 0.609375, 0.015625, 0.609375)
    elseif self.class and GladiusMixin.classIcons[self.class] then
        self.ClassIcon.Texture:SetTexture(GladiusMixin.classIcons[self.class])
        self:SetTextureCrop(self.ClassIcon.Texture, ls.cropIcons, "class")
    end

    if self.ClassIcon.Cooldown then
        self.ClassIcon.Cooldown:Clear()
    end
    self.ClassIcon:Show()
end

function GladiusFrameMixin:UpdateSpecIcon()
    if not self.SpecIcon then return end
    local db = self.parent.db
    if not db then return end
    local ls = db.profile.layoutSettings[db.profile.currentLayout]
    if not ls then return end

    if ls.replaceClassIcon or ls.hideSpecIcon then
        self.SpecIcon:Hide()
    elseif self.specTexture then
        self.SpecIcon.Texture:SetTexture(self.specTexture)
        self.SpecIcon:Show()
    else
        self.SpecIcon:Hide()
    end
end

-----------------------------------------------------------------------
-- Name
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateName()
    if not self.Name then return end
    local db = self.parent.db
    if not db then return end

    local displayName
    if db.profile.showNames then
        displayName = UnitName(self.unit) or self.unit
    else
        displayName = "arena" .. self:GetID()
    end
    self.Name:SetText(displayName)

    if db.profile.classColors and self.class then
        local cc = RAID_CLASS_COLORS[self.class]
        if cc then
            self.Name:SetTextColor(cc.r, cc.g, cc.b)
            return
        end
    end
    self.Name:SetTextColor(1, 1, 1)
end

-----------------------------------------------------------------------
-- Health bar
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateHealthBar()
    if not self.HealthBar then return end
    local unit = self.unit

    local maxHP = UnitHealthMax(unit)
    local curHP = UnitHealth(unit)
    self.HealthBar:SetMinMaxValues(0, maxHP)
    self.HealthBar:SetValue(curHP)

    -- Class color
    local db = self.parent.db
    if db and db.profile.classColors and self.class then
        local cc = RAID_CLASS_COLORS[self.class]
        if cc then
            self.HealthBar:SetStatusBarColor(cc.r, cc.g, cc.b)
        end
    end

    self:SetStatusText(unit)
    self:SetLifeState()

    -- Update absorbs and heal prediction on health change
    if not isMidnight then
        self:UpdateHealPrediction()
        self:UpdateAbsorb()
    end
end

-----------------------------------------------------------------------
-- Power bar
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdatePowerBar()
    if not self.PowerBar then return end
    local unit = self.unit
    self.PowerBar:SetValue(UnitPower(unit))
    self:SetStatusText(unit)
end

function GladiusFrameMixin:UpdatePowerType()
    if not self.PowerBar then return end
    local unit = self.unit
    local powerType, powerToken = UnitPowerType(unit)
    local color = PowerBarColor[powerToken] or PowerBarColor[powerType] or {r = 0, g = 0, b = 1}
    self.PowerBar:SetStatusBarColor(color.r, color.g, color.b)
    self.PowerBar:SetMinMaxValues(0, UnitPowerMax(unit))
    self.PowerBar:SetValue(UnitPower(unit))
end

-----------------------------------------------------------------------
-- Status text (health/power values)
-----------------------------------------------------------------------
function GladiusFrameMixin:SetStatusText(unit)
    unit = unit or self.unit
    local db = self.parent.db
    if not db then return end
    local ls = db.profile.layoutSettings[db.profile.currentLayout]

    -- Health text
    if self.HealthText then
        if ls and ls.statusText and ls.hideStatusText then
            self.HealthText:SetText("")
        elseif ls and ls.statusText and ls.statusText.usePercentage then
            -- Percentage display
            if isMidnight and UnitHealthPercent then
                self.HealthText:SetText(string.format("%d%%", UnitHealthPercent(unit) or 0))
            else
                local max = UnitHealthMax(unit)
                if max > 0 then
                    self.HealthText:SetText(string.format("%d%%", math.ceil((UnitHealth(unit) / max) * 100)))
                end
            end
        else
            -- Absolute value
            local hp = UnitHealth(unit)
            if db.profile.statusText and db.profile.statusText.formatNumbers then
                if AbbreviateLargeNumbers then
                    self.HealthText:SetText(AbbreviateLargeNumbers(hp))
                else
                    self.HealthText:SetText(GladiusMixin.FormatLargeNumber(hp))
                end
            else
                self.HealthText:SetText(hp)
            end
        end
    end

    -- Power text
    if self.PowerText then
        if ls and ls.statusText and ls.hideStatusText then
            self.PowerText:SetText("")
        elseif ls and ls.statusText and ls.statusText.usePercentage then
            if isMidnight and UnitPowerPercent then
                self.PowerText:SetText(string.format("%d%%", UnitPowerPercent(unit) or 0))
            else
                local max = UnitPowerMax(unit)
                if max > 0 then
                    self.PowerText:SetText(string.format("%d%%", math.ceil((UnitPower(unit) / max) * 100)))
                end
            end
        else
            local pwr = UnitPower(unit)
            if db.profile.statusText and db.profile.statusText.formatNumbers then
                if AbbreviateLargeNumbers then
                    self.PowerText:SetText(AbbreviateLargeNumbers(pwr))
                else
                    self.PowerText:SetText(GladiusMixin.FormatLargeNumber(pwr))
                end
            else
                self.PowerText:SetText(pwr)
            end
        end
    end
end

function GladiusFrameMixin:UpdateStatusTextVisible()
    local db = self.parent.db
    if not db then return end

    if self.HealthText then
        self.HealthText:SetShown(db.profile.statusText and db.profile.statusText.alwaysShow)
    end
    if self.PowerText then
        local shown = db.profile.statusText and db.profile.statusText.alwaysShow
        self.PowerText:SetShown(shown)
        if shown then
            self.PowerText:SetAlpha(db.profile.hidePowerText and 0 or 1)
        end
    end
end

-----------------------------------------------------------------------
-- Life state (death / feign death)
-----------------------------------------------------------------------
function GladiusFrameMixin:SetLifeState()
    local unit = self.unit
    if not UnitExists(unit) then return end

    local feignDeath = false
    -- Check for feign death on hunters
    if self.class == "HUNTER" and GladiusMixin.FEIGN_DEATH then
        for i = 1, 40 do
            local name = UnitBuff(unit, i)
            if not name then break end
            if name == GladiusMixin.FEIGN_DEATH then
                feignDeath = true
                break
            end
        end
    end

    local isDead = UnitIsDeadOrGhost(unit) and not feignDeath
    self.feignDeath = feignDeath

    if self.DeathIcon then
        self.DeathIcon:SetShown(isDead)
    end

    if isDead then
        if self.SpecNameText then self.SpecNameText:Hide() end
        -- Hide widgets on death
        if self.WidgetOverlay then
            for _, w in pairs({"targetIndicator", "focusIndicator", "combatIndicator",
                              "partyTarget1", "partyTarget2"}) do
                if self.WidgetOverlay[w] then
                    self.WidgetOverlay[w]:Hide()
                end
            end
        end
    end

    -- Feign death: dim the health bar
    if self.HealthBar then
        self.HealthBar:SetAlpha(feignDeath and 0.55 or 1)
    end
end

-----------------------------------------------------------------------
-- Mystery player (opponent not yet visible)
-----------------------------------------------------------------------
function GladiusFrameMixin:SetMysteryPlayer()
    local db = self.parent.db
    if not db then return end

    if self.HealthBar then
        self.HealthBar:SetMinMaxValues(0, 100)
        self.HealthBar:SetValue(100)
        if db.profile.colorMysteryGray then
            self.HealthBar:SetStatusBarColor(0.5, 0.5, 0.5)
        elseif self.class then
            local cc = RAID_CLASS_COLORS[self.class]
            if cc then
                self.HealthBar:SetStatusBarColor(cc.r, cc.g, cc.b)
            end
        end
    end

    if self.PowerBar then
        self.PowerBar:SetMinMaxValues(0, 100)
        self.PowerBar:SetValue(100)
        -- Set power type color from class
        local pType = GladiusMixin.classPowerType[self.class or ""] or "MANA"
        -- Special monk/druid spec handling
        if self.class == "DRUID" then
            if self.specName == "Feral" or self.specName == "Guardian" then
                pType = "ENERGY"
            end
        elseif self.class == "MONK" then
            if self.specName == "Mistweaver" then
                pType = "MANA"
            end
        end
        local pColor = PowerBarColor[pType] or {r = 0, g = 0, b = 1}
        self.PowerBar:SetStatusBarColor(pColor.r, pColor.g, pColor.b)
    end

    -- Hide status text and widgets while mystery
    if self.HealthText then self.HealthText:SetText("") end
    if self.PowerText then self.PowerText:SetText("") end
    if self.SpecNameText then self.SpecNameText:SetText("") end
end

-----------------------------------------------------------------------
-- Heal prediction (Retail only, skip on Midnight)
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateHealPrediction()
    if isMidnight then return end
    if not self.HealthBar or not self.myHealPredictionBar then return end

    local unit = self.unit
    local maxHP = UnitHealthMax(unit)
    local curHP = UnitHealth(unit)
    if maxHP <= 0 then return end

    local myIncomingHeal = UnitGetIncomingHeals(unit, "player") or 0
    local allIncomingHeal = UnitGetIncomingHeals(unit) or 0
    local totalAbsorb = UnitGetTotalAbsorbs(unit) or 0
    local healAbsorb = UnitGetTotalHealAbsorbs(unit) or 0

    -- Clamp heal absorb to current health
    if curHP < healAbsorb then
        healAbsorb = curHP
        if self.overHealAbsorbGlow then self.overHealAbsorbGlow:Show() end
    else
        if self.overHealAbsorbGlow then self.overHealAbsorbGlow:Hide() end
    end

    -- Clamp incoming heals to prevent overflow beyond 100%
    local maxOverflow = maxHP * 1.0
    if curHP - healAbsorb + allIncomingHeal > maxOverflow then
        allIncomingHeal = maxOverflow - curHP + healAbsorb
        if allIncomingHeal < 0 then allIncomingHeal = 0 end
    end

    -- Split heals
    local otherIncomingHeal
    if allIncomingHeal >= myIncomingHeal then
        otherIncomingHeal = allIncomingHeal - myIncomingHeal
    else
        myIncomingHeal = allIncomingHeal
        otherIncomingHeal = 0
    end

    -- Calculate bar widths
    local barWidth = self.HealthBar:GetWidth()
    local healthWidth = (curHP / maxHP) * barWidth
    local healAbsorbWidth = (healAbsorb / maxHP) * barWidth
    local myHealWidth = (myIncomingHeal / maxHP) * barWidth
    local otherHealWidth = (otherIncomingHeal / maxHP) * barWidth
    local absorbWidth = (totalAbsorb / maxHP) * barWidth

    -- Position my heal prediction bar
    local startPos = healthWidth - healAbsorbWidth
    self.myHealPredictionBar:ClearAllPoints()
    self.myHealPredictionBar:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT", startPos, 0)
    self.myHealPredictionBar:SetWidth(math.max(1, myHealWidth))
    self.myHealPredictionBar:SetShown(myHealWidth > 0)

    -- Position other heal prediction bar
    self.otherHealPredictionBar:ClearAllPoints()
    self.otherHealPredictionBar:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT", startPos + myHealWidth, 0)
    self.otherHealPredictionBar:SetWidth(math.max(1, otherHealWidth))
    self.otherHealPredictionBar:SetShown(otherHealWidth > 0)

    -- Position absorb bar
    self.totalAbsorbBar:ClearAllPoints()
    self.totalAbsorbBar:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT",
        startPos + myHealWidth + otherHealWidth, 0)
    self.totalAbsorbBar:SetWidth(math.max(1, absorbWidth))
    self.totalAbsorbBar:SetShown(absorbWidth > 0)

    -- Heal absorb bar
    self.healAbsorbBar:ClearAllPoints()
    self.healAbsorbBar:SetPoint("TOPRIGHT", self.HealthBar, "TOPLEFT", healthWidth, 0)
    self.healAbsorbBar:SetWidth(math.max(1, healAbsorbWidth))
    self.healAbsorbBar:SetShown(healAbsorbWidth > 0)

    -- Over-absorb glow
    if self.overAbsorbGlow then
        local showGlow = (curHP + allIncomingHeal + totalAbsorb) >= maxHP
        self.overAbsorbGlow:SetShown(showGlow)
    end
end

-----------------------------------------------------------------------
-- Absorb display
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateAbsorb()
    if isMidnight then return end
    if not self.HealthBar or not self.totalAbsorbBar then return end

    local unit = self.unit
    local totalAbsorb = UnitGetTotalAbsorbs(unit) or 0
    local maxHP = UnitHealthMax(unit)
    if maxHP <= 0 then return end

    local barWidth = self.HealthBar:GetWidth()
    local absorbWidth = (totalAbsorb / maxHP) * barWidth
    local curHP = UnitHealth(unit)
    local missingHP = maxHP - curHP
    local missingWidth = (missingHP / maxHP) * barWidth

    -- Clamp to missing health (no overshield display beyond bar)
    local displayWidth = math.min(absorbWidth, missingWidth)
    self.totalAbsorbBar:SetWidth(math.max(1, displayWidth))
    self.totalAbsorbBar:SetShown(displayWidth > 0)

    -- Overlay
    if self.totalAbsorbBarOverlay then
        self.totalAbsorbBarOverlay:SetShown(displayWidth > 0)
    end

    -- Over-absorb glow
    if self.overAbsorbGlow then
        self.overAbsorbGlow:SetShown(totalAbsorb > missingHP)
        if totalAbsorb > missingHP then
            self.overAbsorbGlow:ClearAllPoints()
            self.overAbsorbGlow:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT",
                (curHP / maxHP) * barWidth, 0)
        end
    end
end

-----------------------------------------------------------------------
-- Frame color management
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateFrameColors()
    local db = self.parent.db
    if not db then return end

    if db.profile.classColorFrameTexture then
        self:ClassColorFrameTexture()
    elseif db.profile.darkMode then
        self:DarkModeFrame()
    else
        -- Default white
        self:ResetFrameColor(1, 1, 1)
    end
end

function GladiusFrameMixin:DarkModeFrame()
    local db = self.parent.db
    if not db then return end
    local darkVal = db.profile.darkModeValue or 0.2
    local lightVal = darkVal + 0.1

    self:ResetFrameColor(darkVal, darkVal, darkVal)

    -- Slightly lighter for trinket/racial/dispel borders
    if self.Trinket and self.Trinket.Border then
        self.Trinket.Border:SetVertexColor(lightVal, lightVal, lightVal)
    end
    if self.Racial and self.Racial.Border then
        self.Racial.Border:SetVertexColor(lightVal, lightVal, lightVal)
    end
    if self.Dispel and self.Dispel.Border then
        self.Dispel.Border:SetVertexColor(lightVal, lightVal, lightVal)
    end

    -- Desaturate if enabled
    if db.profile.darkModeDesaturate then
        if self.frameTexture then self.frameTexture:SetDesaturated(true) end
    end
end

function GladiusFrameMixin:ClassColorFrameTexture()
    if not self.class then return end
    local cc = RAID_CLASS_COLORS[self.class]
    if not cc then return end

    local db = self.parent.db
    if not db then return end

    local r, g, b = cc.r, cc.g, cc.b

    -- Healer override: green
    if self.isHealer and db.profile.classColorFrameTextureHealerGreen then
        r, g, b = 0, 1, 0
    end

    self:ResetFrameColor(r, g, b)

    -- Lighter tint for accessory borders
    local lr, lg, lb = math.min(r + 0.2, 1), math.min(g + 0.2, 1), math.min(b + 0.2, 1)
    if self.Trinket and self.Trinket.Border then
        self.Trinket.Border:SetVertexColor(lr, lg, lb)
    end
    if self.Racial and self.Racial.Border then
        self.Racial.Border:SetVertexColor(lr, lg, lb)
    end
    if self.Dispel and self.Dispel.Border then
        self.Dispel.Border:SetVertexColor(lr, lg, lb)
    end

    -- Pixel borders
    if GladiusMixin.showPixelBorder and self.UpdatePixelBorderColor then
        self:UpdatePixelBorderColor(r, g, b)
    end
end

function GladiusFrameMixin:ResetFrameColor(r, g, b)
    if self.frameTexture then
        self.frameTexture:SetVertexColor(r, g, b)
    end
    if self.ClassIcon and self.ClassIcon.Border then
        self.ClassIcon.Border:SetVertexColor(r, g, b)
    end
    if self.SpecIcon and self.SpecIcon.Border then
        self.SpecIcon.Border:SetVertexColor(r, g, b)
    end
end

function GladiusFrameMixin:ResetPixelBorders()
    if self.pixelBorders then
        for _, border in ipairs(self.pixelBorders) do
            border:SetColorTexture(0, 0, 0, 1)
        end
    end
end

-----------------------------------------------------------------------
-- Texture coord helper
-----------------------------------------------------------------------
function GladiusFrameMixin:SetTextureCrop(texture, crop, texType)
    if not texture then return end
    if texType == "aura" then
        texture:SetTexCoord(0.03, 0.97, 0.03, 0.93)
    elseif texType == "healer" then
        texture:SetTexCoord(0.205, 0.765, 0.22, 0.745)
    elseif texType == "class" then
        if crop then
            texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            texture:SetTexCoord(0, 1, 0, 1)
        end
    else
        if crop then
            texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            texture:SetTexCoord(0, 1, 0, 1)
        end
    end
end

-----------------------------------------------------------------------
-- Widget indicator updates
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateTarget(unit)
    if not self.WidgetOverlay or not self.WidgetOverlay.targetIndicator then return end
    self.WidgetOverlay.targetIndicator:SetShown(UnitExists("target") and UnitIsUnit("target", unit))
end

function GladiusFrameMixin:UpdateFocus(unit)
    if not self.WidgetOverlay or not self.WidgetOverlay.focusIndicator then return end
    self.WidgetOverlay.focusIndicator:SetShown(UnitExists("focus") and UnitIsUnit("focus", unit))
end

function GladiusFrameMixin:UpdatePartyTargets(unit)
    if not self.WidgetOverlay then return end

    local pt1 = self.WidgetOverlay.partyTarget1
    local pt2 = self.WidgetOverlay.partyTarget2

    local show1, show2 = false, false

    -- Check party1target
    if UnitExists("party1target") and UnitIsUnit("party1target", unit) then
        show1 = true
        if pt1 then
            local _, class = UnitClass("party1")
            local cc = class and RAID_CLASS_COLORS[class]
            if cc then
                pt1.Texture:SetVertexColor(cc.r, cc.g, cc.b)
            end
        end
    end

    -- Check party2target
    if UnitExists("party2target") and UnitIsUnit("party2target", unit) then
        show2 = true
        if pt2 then
            local _, class = UnitClass("party2")
            local cc = class and RAID_CLASS_COLORS[class]
            if cc then
                pt2.Texture:SetVertexColor(cc.r, cc.g, cc.b)
            end
        end
    end

    if pt1 then pt1:SetShown(show1) end
    if pt2 then pt2:SetShown(show2) end
end

function GladiusFrameMixin:UpdateCombatStatus(unit)
    if not self.WidgetOverlay or not self.WidgetOverlay.combatIndicator then return end
    -- Show food/drink icon when NOT in combat and alive
    local inCombat = UnitExists(unit) and UnitAffectingCombat(unit)
    local isDead = self.DeathIcon and self.DeathIcon:IsShown()
    self.WidgetOverlay.combatIndicator:SetShown(unit and not inCombat and not isDead)
end

-----------------------------------------------------------------------
-- Cooldown settings
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateClassIconCooldownReverse()
    if not self.ClassIcon or not self.ClassIcon.Cooldown then return end
    local db = self.parent.db
    if db and db.profile.invertClassIconCooldown then
        self.ClassIcon.Cooldown:SetReverse(true)
    else
        self.ClassIcon.Cooldown:SetReverse(false)
    end
end

function GladiusFrameMixin:UpdateTrinketRacialCooldownReverse()
    local db = self.parent.db
    if not db then return end
    local ls = db.profile.layoutSettings[db.profile.currentLayout]
    local reversed = ls and ls.invertTrinketCooldown

    if self.Trinket and self.Trinket.Cooldown then
        self.Trinket.Cooldown:SetReverse(reversed or false)
    end
    if self.Racial and self.Racial.Cooldown then
        self.Racial.Cooldown:SetReverse(reversed or false)
    end
end

function GladiusFrameMixin:UpdateClassIconSwipeSettings()
    if not self.ClassIcon or not self.ClassIcon.Cooldown then return end
    -- The XML already configures initial swipe settings
end

function GladiusFrameMixin:UpdateTrinketRacialSwipeSettings()
    -- Trinket/Racial swipe settings configured by layout
end

-----------------------------------------------------------------------
-- DR position update
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateDRPositions()
    if isMidnight then return end -- Midnight uses Blizzard's tray
    if not GladiusMixin.drCategories then return end

    local db = self.parent.db
    if not db then return end
    local ls = db.profile.layoutSettings[db.profile.currentLayout]
    if not ls or not ls.dr then return end

    local drSize = ls.dr.size or 28
    local spacing = ls.dr.spacing or 6
    local growDir = ls.dr.growthDirection or 4
    local baseX = ls.dr.posX or 0
    local baseY = ls.dr.posY or 0

    local visibleIdx = 0
    for _, cat in ipairs(GladiusMixin.drCategories) do
        local drFrame = self[cat]
        if drFrame and drFrame:IsShown() then
            drFrame:ClearAllPoints()
            drFrame:SetSize(drSize, drSize)

            local xOff, yOff = 0, 0
            if growDir == 4 then      -- RIGHT
                xOff = visibleIdx * (drSize + spacing)
            elseif growDir == 3 then   -- LEFT
                xOff = -(visibleIdx * (drSize + spacing))
            elseif growDir == 1 then   -- UP
                yOff = visibleIdx * (drSize + spacing)
            elseif growDir == 2 then   -- DOWN
                yOff = -(visibleIdx * (drSize + spacing))
            end

            drFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", baseX + xOff, baseY + yOff)
            visibleIdx = visibleIdx + 1
        end
    end
end

-----------------------------------------------------------------------
-- Reset layout (restore defaults before applying a new layout)
-----------------------------------------------------------------------
function GladiusFrameMixin:ResetLayout()
    -- Reset sizes
    self:SetSize(168, 44)

    -- Reset health/power bars
    if self.HealthBar then
        self.HealthBar:ClearAllPoints()
        self.HealthBar:SetReverseFill(false)
    end
    if self.PowerBar then
        self.PowerBar:ClearAllPoints()
        self.PowerBar:SetReverseFill(false)
    end

    -- Reset class icon
    if self.ClassIcon then
        self.ClassIcon:ClearAllPoints()
        self.ClassIcon.Texture:SetTexCoord(0, 1, 0, 1)
        if self.ClassIcon.Mask then
            self.ClassIcon.Mask:Show()
        end
    end

    -- Reset spec icon
    if self.SpecIcon then
        self.SpecIcon:ClearAllPoints()
        self.SpecIcon.Texture:SetTexCoord(0, 1, 0, 1)
    end

    -- Reset trinket/racial/dispel
    if self.Trinket then self.Trinket:ClearAllPoints() end
    if self.Racial then self.Racial:ClearAllPoints() end
    if self.Dispel then self.Dispel:ClearAllPoints() end

    -- Reset castbar
    if self.CastBar then
        self.CastBar:ClearAllPoints()
    end

    -- Reset text positions
    if self.Name then self.Name:ClearAllPoints() end
    if self.HealthText then self.HealthText:ClearAllPoints() end
    if self.PowerText then self.PowerText:ClearAllPoints() end
    if self.SpecNameText then self.SpecNameText:ClearAllPoints() end

    -- Reset frame texture
    if self.frameTexture then
        self.frameTexture:ClearAllPoints()
        self.frameTexture:Hide()
    end

    -- Reset death icon
    if self.DeathIcon then
        self.DeathIcon:ClearAllPoints()
    end

    -- Reset pixel borders
    self:ResetPixelBorders()

    -- Reset font changes
    if self.changedFonts then
        for fs, saved in pairs(self.changedFonts) do
            if saved then
                local path, size, flags = unpack(saved)
                fs:SetFont(path, size, flags)
            end
        end
        self.changedFonts = nil
    end

    -- Reset frame color
    self:ResetFrameColor(1, 1, 1)
end

-----------------------------------------------------------------------
-- Stub functions (implemented by modules)
-----------------------------------------------------------------------
function GladiusFrameMixin:ResetTrinket() end
function GladiusFrameMixin:ResetRacial() end
function GladiusFrameMixin:ResetDispel() end
function GladiusFrameMixin:ResetDR() end
function GladiusFrameMixin:UpdateTrinket() end
function GladiusFrameMixin:UpdateRacial() end
function GladiusFrameMixin:UpdateDispel() end
function GladiusFrameMixin:FindAura() end
function GladiusFrameMixin:FindDR() end
function GladiusFrameMixin:FindRacial() end
function GladiusFrameMixin:FindDispel() end
function GladiusFrameMixin:FindInterrupt() end
function GladiusFrameMixin:GetTestModeDispelData() return nil end
function GladiusFrameMixin:UpdatePixelBorderColor() end

-----------------------------------------------------------------------
-- End of Frames.lua
-----------------------------------------------------------------------
