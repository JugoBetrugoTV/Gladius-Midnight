--[[
    Gladius Midnight - DR Tracker Module
    Tracks diminishing returns categories for arena opponents.
]]

local addonName, addon = ...
local DRTracker = {}

local DR_RESET_TIME = 18
local DR_STEPS = { 1.0, 0.5, 0.25 }

-- ============================================================================
-- Module Registration
-- ============================================================================

function DRTracker:OnRegister(core)
    self.core = core
end

function DRTracker:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create DR Elements
-- ============================================================================

function DRTracker:CreateElements(frame)
    local container = CreateFrame("Frame", nil, frame)
    container.icons = {}
    container.data = {}

    frame.moduleFrames.drTracker = container
end

local function EnsureIcon(container, index, size)
    if container.icons[index] then
        container.icons[index]:SetSize(size, size)
        return container.icons[index]
    end

    local button = CreateFrame("Frame", nil, container, "BackdropTemplate")
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    button:SetBackdropColor(0, 0, 0, 0.8)
    button:SetBackdropBorderColor(0, 0, 0, 1)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    text:SetPoint("CENTER")
    button.text = text

    button:SetSize(size, size)
    container.icons[index] = button
    return button
end

-- ============================================================================
-- Update DR Display
-- ============================================================================

function DRTracker:Update(frame, testData)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    local db = self.core.db.profile.drTracker

    container:ClearAllPoints()
    if db.position == "BOTTOM" then
        container:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 2)
    else
        container:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -2)
    end

    container:SetSize(1, 1)

    if testData then
        container.data = {
            stun = { level = 2, expires = GetTime() + 12, icon = addon.Data.DRIcons.stun },
            fear = { level = 3, expires = GetTime() + 8, icon = addon.Data.DRIcons.fear },
        }
        self:Layout(container, db)
    else
        self:Layout(container, db)
    end
end

function DRTracker:Layout(container, db)
    local index = 0
    for category, entry in pairs(container.data) do
        if entry.expires > GetTime() then
            index = index + 1
            local iconFrame = EnsureIcon(container, index, db.size)
            iconFrame.icon:SetTexture(entry.icon)
            iconFrame.text:SetText(entry.level or "")
            iconFrame:ClearAllPoints()
            if index == 1 then
                iconFrame:SetPoint("LEFT", container, "LEFT", 0, 0)
            else
                iconFrame:SetPoint("LEFT", container.icons[index - 1], "RIGHT", db.spacing, 0)
            end
            iconFrame:Show()
        end
    end

    for i = index + 1, #container.icons do
        container.icons[i]:Hide()
    end
end

function DRTracker:OnSpellCast(frame, spellID)
    if not spellID then return end

    local category = addon.Data.DRCategories[spellID]
    if not category then return end

    local container = frame.moduleFrames.drTracker
    if not container then return end

    local entry = container.data[category]
    if not entry then
        entry = { level = 1 }
        container.data[category] = entry
    else
        entry.level = math.min((entry.level or 1) + 1, #DR_STEPS)
    end

    entry.expires = GetTime() + DR_RESET_TIME
    entry.icon = addon.Data.DRIcons[category] or addon.Data.TrinketIcon

    self:Layout(container, self.core.db.profile.drTracker)
end

function DRTracker:OnUpdate(frame)
    local container = frame.moduleFrames.drTracker
    if not container then return end

    local now = GetTime()
    local changed = false
    for category, entry in pairs(container.data) do
        if entry.expires <= now then
            container.data[category] = nil
            changed = true
        end
    end

    if changed then
        self:Layout(container, self.core.db.profile.drTracker)
    end
end

function DRTracker:Reset(frame)
    local container = frame.moduleFrames.drTracker
    if container then
        container.data = {}
        for _, icon in ipairs(container.icons) do
            icon:Hide()
        end
    end
end

-- Register module
addon.Core:RegisterModule("drTracker", DRTracker)
