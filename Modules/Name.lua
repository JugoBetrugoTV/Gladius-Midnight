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
    local container = CreateFrame("Frame", nil, frame)

    local text = container:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    text:SetPoint("LEFT", container, "LEFT", 2, 0)
    text:SetJustifyH("LEFT")

    container.text = text
    frame.moduleFrames.name = container
end

-- ============================================================================
-- Update Name
-- ============================================================================

function Name:Update(frame, testData)
    local container = frame.moduleFrames.name
    if not container then return end

    local db = self.core.db.profile.name

    local leftOffset = 2
    local rightOffset = -2

    if self.core:IsModuleEnabled("classIcon") then
        leftOffset = self.core.db.profile.classIcon.size + 4
    end

    if self.core:IsModuleEnabled("trinket") or self.core:IsModuleEnabled("racial") then
        rightOffset = -(self.core.db.profile.trinket.size + 4)
    end

    container:ClearAllPoints()
    container:SetPoint("TOPLEFT", frame, "TOPLEFT", leftOffset, -2)
    container:SetPoint("RIGHT", frame, "RIGHT", rightOffset, 0)
    container:SetHeight(db.height)

    container.text:SetFont("Fonts\\FRIZQT__.TTF", db.fontSize, "OUTLINE")

    if testData then
        local displayName = testData.name or "Gegner"
        if db.showArenaId then
            displayName = string.format("%d. %s", testData.arenaIndex or frame.index, displayName)
        end
        container.text:SetText(displayName)
    else
        self:UpdateUnit(frame)
    end

    container:Show()
end

function Name:UpdateUnit(frame)
    local container = frame.moduleFrames.name
    if not container then return end

    local unit = frame.unit
    if not UnitExists(unit) then return end

    local db = self.core.db.profile.name
    local name = UnitName(unit) or "Gegner"

    if db.showArenaId then
        name = string.format("%d. %s", frame.index, name)
    end

    container.text:SetText(name)
end

function Name:Reset(frame)
    local container = frame.moduleFrames.name
    if container then
        container.text:SetText("")
    end
end

-- Register module
addon.Core:RegisterModule("name", Name)
