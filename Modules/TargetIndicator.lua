--[[
    Gladius Midnight - Target Indicator Module
    Shows a subtle highlight when the opponent is targeted.
]]

local addonName, addon = ...
local TargetIndicator = {}

-- ============================================================================
-- Module Registration
-- ============================================================================

function TargetIndicator:OnRegister(core)
    self.core = core
end

function TargetIndicator:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Target Indicator Elements
-- ============================================================================

function TargetIndicator:CreateElements(frame)
    local overlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    overlay:SetAllPoints(frame)
    overlay:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    overlay:SetBackdropBorderColor(0.9, 0.7, 0.2, 0.9)
    overlay:Hide()

    frame.moduleFrames.targetIndicator = overlay
end

-- ============================================================================
-- Update Target Indicator
-- ============================================================================

function TargetIndicator:Update(frame, testData)
    local overlay = frame.moduleFrames.targetIndicator
    if not overlay then return end

    overlay:SetAllPoints(frame)

    if testData then
        local enabled = self.core.db.profile.targetIndicator.enabledInTest
        if enabled and testData.isTarget then
            overlay:Show()
        else
            overlay:Hide()
        end
    else
        self:UpdateUnit(frame)
    end
end

function TargetIndicator:UpdateUnit(frame)
    local overlay = frame.moduleFrames.targetIndicator
    if not overlay then return end

    if UnitExists(frame.unit) and UnitIsUnit("target", frame.unit) then
        overlay:Show()
    else
        overlay:Hide()
    end
end

function TargetIndicator:Reset(frame)
    local overlay = frame.moduleFrames.targetIndicator
    if overlay then
        overlay:Hide()
    end
end

-- Register module
addon.Core:RegisterModule("targetIndicator", TargetIndicator)
