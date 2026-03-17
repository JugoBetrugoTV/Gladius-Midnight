--[[
    Gladius Midnight - Spec Icon Module
    Displays specialization icon for arena opponents.
]]

local addonName, addon = ...
local SpecIcon = {}

-- ============================================================================
-- Module Registration
-- ============================================================================

function SpecIcon:OnRegister(core)
    self.core = core
end

function SpecIcon:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Spec Icon Elements
-- ============================================================================

function SpecIcon:CreateElements(frame)
    local container = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0, 0, 0, 0.85)
    container:SetBackdropBorderColor(0, 0, 0, 1)

    local icon = container:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    container.icon = icon
    frame.moduleFrames.specIcon = container
end

-- ============================================================================
-- Update Spec Icon
-- ============================================================================

function SpecIcon:Update(frame, testData)
    local container = frame.moduleFrames.specIcon
    if not container then return end

    local db = self.core.db.profile.specIcon

    container:SetSize(db.size, db.size)
    container:ClearAllPoints()

    if db.position == "RIGHT" then
        local trinketFrame = frame.moduleFrames.trinket
        if trinketFrame and self.core:IsModuleEnabled("trinket") then
            container:SetPoint("TOPRIGHT", trinketFrame, "TOPLEFT", -2, 0)
        else
            container:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
        end
    else
        local classIconFrame = frame.moduleFrames.classIcon
        if classIconFrame and self.core:IsModuleEnabled("classIcon") then
            container:SetPoint("TOPLEFT", classIconFrame, "TOPRIGHT", 2, 0)
        else
            container:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        end
    end

    if testData then
        local coords = addon.Data.ClassIconCoords[testData.class]
        if coords then
            container.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            container.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        end
    else
        self:UpdateUnit(frame)
    end

    container:Show()
end

function SpecIcon:UpdateUnit(frame)
    local container = frame.moduleFrames.specIcon
    if not container then return end

    local specID
    if C_PvP and C_PvP.GetArenaOpponentSpec then
        specID = C_PvP.GetArenaOpponentSpec(frame.index)
    elseif GetArenaOpponentSpec then
        specID = GetArenaOpponentSpec(frame.index)
    end

    if specID and specID > 0 and GetSpecializationInfoByID then
        local _, _, _, icon = GetSpecializationInfoByID(specID)
        if icon then
            container.icon:SetTexture(icon)
            container.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            return
        end
    end

    container.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    container.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

function SpecIcon:Reset(frame)
    local container = frame.moduleFrames.specIcon
    if container then
        container.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        container.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

-- Register module
addon.Core:RegisterModule("specIcon", SpecIcon)
