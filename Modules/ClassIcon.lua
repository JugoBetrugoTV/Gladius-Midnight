--[[=========================================================================
    Gladius Midnight - Class Icon Module
    Displays class portrait on arena frames, with aura overlay support
===========================================================================]]

local _, Gladius = ...

local CLASS_ICON_ATLAS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"

-- =========================================================================
-- Class Icon Display
-- =========================================================================
function GladiusArenaFrameMixin:RefreshClassIcon()
    if not Gladius.db.profile.classIconEnabled then
        self.ClassIcon:Hide()
        return
    end

    local classToken = self.unitClass
    if not classToken then
        self.ClassIcon.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.ClassIcon:Show()
        return
    end

    local coords = Gladius.CLASS_ICON_COORDS[classToken]
    if coords then
        self.ClassIcon.Icon:SetTexture(CLASS_ICON_ATLAS)
        self.ClassIcon.Icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        self.ClassIcon.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.ClassIcon.Icon:SetTexCoord(0, 1, 0, 1)
    end

    -- Reset cooldown display
    self.ClassIcon.Cooldown:Clear()
    self.ClassIcon.StackText:SetText("")
    self.ClassIcon.Icon:SetDesaturated(false)

    self.ClassIcon:Show()
end

function GladiusArenaFrameMixin:ResetClassIcon()
    if self.ClassIcon then
        self.ClassIcon.Icon:SetTexture(nil)
        self.ClassIcon.Icon:SetTexCoord(0, 1, 0, 1)
        self.ClassIcon.Cooldown:Clear()
        self.ClassIcon.StackText:SetText("")
        self.ClassIcon.Icon:SetDesaturated(false)
    end
end

-- =========================================================================
-- Aura Overlay on Class Icon
-- When an important aura is active, we overlay its icon on the class icon
-- =========================================================================
function GladiusArenaFrameMixin:SetAuraOverlay(spellID, texture, duration, expirationTime, stacks)
    if not Gladius.db.profile.auraPriorityOnIcon then return end
    if not self.ClassIcon then return end

    local icon = self.ClassIcon.Icon
    local cooldown = self.ClassIcon.Cooldown

    if spellID then
        -- Show aura texture on class icon
        icon:SetTexture(texture)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Show duration cooldown
        if duration and duration > 0 and expirationTime then
            cooldown:SetCooldown(expirationTime - duration, duration)
        else
            cooldown:Clear()
        end

        -- Show stacks
        if stacks and stacks > 1 and Gladius.db.profile.auraShowStacks then
            self.ClassIcon.StackText:SetText(stacks)
        else
            self.ClassIcon.StackText:SetText("")
        end

        self.currentAuraSpellID = spellID
    else
        -- Restore class icon
        self:RefreshClassIcon()
        self.currentAuraSpellID = nil
        self.currentAuraPriority = 0
    end
end

-- =========================================================================
-- Interrupt Overlay on Class Icon
-- When an enemy is interrupted, show the interrupt lockout on class icon
-- =========================================================================
function GladiusArenaFrameMixin:SetInterruptOverlay(spellID, lockoutDuration, sourceClass)
    if not self.ClassIcon then return end

    local texture = Gladius.GetSpellTexture(spellID)
    if not texture then return end

    local icon = self.ClassIcon.Icon
    local cooldown = self.ClassIcon.Cooldown

    icon:SetTexture(texture)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local now = GetTime()
    cooldown:SetCooldown(now, lockoutDuration)

    self.isInterrupted = true
    self.interruptExpiration = now + lockoutDuration

    -- Tint based on source class
    if sourceClass then
        local color = Gladius.CLASS_COLORS[sourceClass]
        if color then
            self.ClassIcon.StackText:SetText("")
            self.ClassIcon.StackText:SetTextColor(color.r, color.g, color.b)
        end
    end
end
