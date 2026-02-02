--[[
    Gladius Midnight - Name Module
    Displays opponent name (optionally with arena index)
]]

local addonName, addon = ...
local Name = {}

-- ============================================================================
-- Module Registration
-- ============================================================================

function Name:OnRegister(core)
    self.core = core
end

function Name:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Name Elements
-- ============================================================================

function Name:CreateElements(frame)
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")

    frame.moduleFrames.name = text
end

-- ============================================================================
-- Update Name
-- ============================================================================

function Name:Update(frame, testData)
    local text = frame.moduleFrames.name
    if not text then return end

    local db = self.core.db.profile.name

    text:ClearAllPoints()
    local anchor = frame.moduleFrames.health or frame
    if anchor == frame then
        text:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
        text:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    else
        text:SetPoint("LEFT", anchor, "LEFT", 4, 0)
        text:SetPoint("RIGHT", anchor, "RIGHT", -4, 0)
    end

    text:SetFont("Fonts\\FRIZQT__.TTF", db.fontSize, "OUTLINE")

    if testData then
        local displayName = testData.name or "Gegner"
        if db.showArenaId then
            displayName = string.format("%d. %s", testData.arenaIndex or frame.index, displayName)
        end
        text:SetText(displayName)
        if db.colorByClass and testData.class then
            local color = addon.Data.GetClassColor(testData.class)
            text:SetTextColor(color.r, color.g, color.b)
        else
            text:SetTextColor(1, 1, 1)
        end
    else
        self:UpdateUnit(frame)
    end

    text:Show()
end

function Name:UpdateUnit(frame)
    local text = frame.moduleFrames.name
    if not text then return end

    local unit = frame.unit
    if not UnitExists(unit) then return end

    local db = self.core.db.profile.name
    local name = UnitName(unit) or "Gegner"

    if db.showArenaId then
        name = string.format("%d. %s", frame.index, name)
    end

    text:SetText(name)
    if db.colorByClass then
        local _, class = UnitClass(unit)
        if class then
            local color = addon.Data.GetClassColor(class)
            text:SetTextColor(color.r, color.g, color.b)
        else
            text:SetTextColor(1, 1, 1)
        end
    else
        text:SetTextColor(1, 1, 1)
    end
end

function Name:Reset(frame)
    local text = frame.moduleFrames.name
    if text then
        text:SetText("")
        text:SetTextColor(1, 1, 1)
    end
end

-- Register module
addon.Core:RegisterModule("name", Name)
