--[[
    Gladius Midnight - Diminishing Returns Module
    Tracks DR applications on arena enemies using combat log events.
    Displays DR icons with severity coloring and cooldown sweep.
    DR reset time: 18.5s (retail), severity: 1=half, 2=quarter, 3=immune.
]]

local drCategories = GladiusMixin.drCategories
local drList = GladiusMixin.drList
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local GetTime = GetTime

-- DR reset duration (18.5s on retail with leeway)
local DR_RESET_TIME = 18.5

-- Severity colors: green -> yellow -> red
local SEVERITY_COLORS = {
    [1] = { 0, 1, 0, 1 },
    [2] = { 1, 1, 0, 1 },
    [3] = { 1, 0, 0, 1 },
}

-----------------------------------------------------------------------
-- FindDR: Process a DR combat log event for this frame
-----------------------------------------------------------------------
function GladiusFrameMixin:FindDR(combatEvent, spellID)
    local category = drList[spellID]
    if not category then return end

    -- Check if this DR category is enabled in settings
    local db = self.parent.db
    if not db then return end
    local profile = db.profile

    local isEnabled = false
    if profile.drCategoriesPerSpec then
        local specKey = GladiusMixin.playerSpecID or 0
        local perSpec = profile.drCategoriesSpec or {}
        local specCats = perSpec[specKey]
        if specCats ~= nil and specCats[category] ~= nil then
            isEnabled = specCats[category]
        else
            isEnabled = profile.drCategories and profile.drCategories[category]
        end
    elseif profile.drCategoriesPerClass then
        local classKey = GladiusMixin.playerClass
        local perClass = profile.drCategoriesClass or {}
        local classCats = perClass[classKey]
        if classCats ~= nil and classCats[category] ~= nil then
            isEnabled = classCats[category]
        else
            isEnabled = profile.drCategories and profile.drCategories[category]
        end
    else
        isEnabled = profile.drCategories and profile.drCategories[category]
    end

    if not isEnabled then return end

    local drFrame = self[category]
    if not drFrame then return end

    local now = GetTime()

    ---------------------------------------------------------------
    -- AURA REMOVED / BROKEN: Extend cooldown for the DR reset window
    ---------------------------------------------------------------
    if combatEvent == "SPELL_AURA_REMOVED" or combatEvent == "SPELL_AURA_BROKEN" then
        local cdStart, cdDuration = drFrame.Cooldown:GetCooldownTimes()
        cdStart = cdStart / 1000
        cdDuration = cdDuration / 1000

        -- Guard against division by zero
        if cdDuration == 0 then return end
        local fraction = 1 - ((now - cdStart) / cdDuration)
        if fraction == 0 then return end

        local extendedDuration = DR_RESET_TIME / fraction
        local extendedStart = DR_RESET_TIME + now - extendedDuration

        drFrame:Show()
        drFrame.Cooldown:SetCooldown(extendedStart, extendedDuration)
        return
    end

    ---------------------------------------------------------------
    -- AURA APPLIED / REFRESH: Start the DR cooldown
    ---------------------------------------------------------------
    if combatEvent == "SPELL_AURA_APPLIED" or combatEvent == "SPELL_AURA_REFRESH" then
        local unit = self.unit

        -- Find the actual debuff duration on the target
        for slot = 1, 30 do
            local auraData = C_UnitAuras.GetAuraDataByIndex(unit, slot, "HARMFUL")
            if not auraData then break end
            if auraData.spellId == spellID and auraData.duration then
                drFrame:Show()
                drFrame.Cooldown:SetCooldown(now, auraData.duration + DR_RESET_TIME)
                break
            end
        end
    end

    ---------------------------------------------------------------
    -- Determine icon texture (static icon or spell-specific)
    ---------------------------------------------------------------
    local useStatic = profile.drStaticIcons
    local textureID = nil

    if useStatic and profile.drStaticIconsPerSpec then
        local perSpec = profile.drIconsPerSpec
        local specKey = GladiusMixin.playerSpecID or 0
        if perSpec and perSpec[specKey] and perSpec[specKey][category] then
            textureID = perSpec[specKey][category]
        end
    elseif useStatic and profile.drStaticIconsPerClass then
        local perClass = profile.drIconsPerClass
        local classKey = GladiusMixin.playerClass
        if perClass and perClass[classKey] and perClass[classKey][category] then
            textureID = perClass[classKey][category]
        end
    end

    if not textureID and useStatic then
        textureID = profile.drIcons and profile.drIcons[category]
    end

    if not textureID then
        textureID = GetSpellTexture(spellID)
    end

    drFrame.Icon:SetTexture(textureID)

    ---------------------------------------------------------------
    -- Border coloring based on severity
    ---------------------------------------------------------------
    local layoutName = profile.currentLayout
    local layout = profile.layoutSettings[layoutName]
    local useBlackBorder = layout and layout.dr and layout.dr.blackDRBorder
    local useThickPixel = layout and layout.dr and layout.dr.thickPixelBorder

    local sevColor = SEVERITY_COLORS[drFrame.severity] or SEVERITY_COLORS[1]
    local borderColor = useBlackBorder and { 0, 0, 0, 1 } or sevColor

    drFrame.Border:SetVertexColor(unpack(borderColor))

    if drFrame.PixelBorder then
        if useThickPixel and useBlackBorder then
            drFrame.PixelBorder:SetVertexColor(0, 0, 0, 1)
        elseif useThickPixel then
            drFrame.PixelBorder:SetVertexColor(unpack(sevColor))
        else
            drFrame.PixelBorder:SetVertexColor(unpack(borderColor))
        end
    end

    -- Masque support
    if drFrame.__MSQ_New_Normal then
        drFrame.__MSQ_New_Normal:SetDesaturated(true)
        drFrame.__MSQ_New_Normal:SetVertexColor(unpack(sevColor))
    end

    ---------------------------------------------------------------
    -- Severity text display (half / quarter / immune)
    ---------------------------------------------------------------
    local drText = drFrame.DRTextFrame and drFrame.DRTextFrame.DRText
    if drText then
        if drFrame.severity == 1 then
            drText:SetText("\194\189")   -- ½
        elseif drFrame.severity == 2 then
            drText:SetText("\194\188")   -- ¼
        else
            drText:SetText("%")
        end
        drText:SetTextColor(unpack(sevColor))
    end

    -- Color the cooldown countdown text by severity if enabled
    if profile.colorDRCooldownText and drFrame.Cooldown.gladiusText then
        drFrame.Cooldown.gladiusText:SetTextColor(unpack(sevColor))
    end

    ---------------------------------------------------------------
    -- Advance severity for next application
    ---------------------------------------------------------------
    drFrame.severity = math.min((drFrame.severity or 1) + 1, 3)
end

-----------------------------------------------------------------------
-- UpdateDRPositions: Arrange visible DR icons along a growth direction
-- Growth directions: 1=Up, 2=Down, 3=Left, 4=Right
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateDRPositions()
    if GladiusMixin.isMidnight then return end
    if not drCategories then return end

    local db = self.parent.db
    if not db then return end
    local layoutDB = db.profile.layoutSettings[db.profile.currentLayout]
    if not layoutDB or not layoutDB.dr then return end

    local spacing = layoutDB.dr.spacing or 6
    local growDir = layoutDB.dr.growthDirection or 4
    local posX = layoutDB.dr.posX or 0
    local posY = layoutDB.dr.posY or 0

    local visibleCount = 0
    local prevFrame

    for i = 1, #drCategories do
        local drFrame = self[drCategories[i]]

        if drFrame and drFrame:IsShown() then
            drFrame:ClearAllPoints()

            if visibleCount == 0 then
                -- First visible frame: position relative to parent center
                local halfSize = (GladiusMixin.drBaseSize or 28) / 2
                if growDir == 4 then
                    drFrame:SetPoint("RIGHT", self, "CENTER", posX + halfSize, posY)
                elseif growDir == 3 then
                    drFrame:SetPoint("LEFT", self, "CENTER", posX - halfSize, posY)
                elseif growDir == 1 then
                    drFrame:SetPoint("TOP", self, "CENTER", posX, posY + halfSize)
                elseif growDir == 2 then
                    drFrame:SetPoint("BOTTOM", self, "CENTER", posX, posY - halfSize)
                end
            else
                -- Subsequent frames: anchor to previous
                if growDir == 4 then
                    drFrame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                elseif growDir == 3 then
                    drFrame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
                elseif growDir == 1 then
                    drFrame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
                elseif growDir == 2 then
                    drFrame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
                end
            end

            visibleCount = visibleCount + 1
            prevFrame = drFrame
        end
    end
end

-----------------------------------------------------------------------
-- ResetDR: Clear all DR state when leaving arena
-----------------------------------------------------------------------
function GladiusFrameMixin:ResetDR()
    if not drCategories then return end
    for i = 1, #drCategories do
        local drFrame = self[drCategories[i]]
        if drFrame and drFrame.Cooldown then
            drFrame.Cooldown:Clear()
        end
    end
end

