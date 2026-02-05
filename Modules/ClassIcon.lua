--[[
    Gladius Midnight - Class Icon Module
    Displays the class icon for the arena opponent
]]

local addonName, addon = ...
local ClassIcon = {}

-- ============================================================================
-- Module Registration
-- ============================================================================

function ClassIcon:OnRegister(core)
    self.core = core
end

function ClassIcon:OnInitialize(core)
    self.core = core
end

-- ============================================================================
-- Create Class Icon Elements
-- ============================================================================

function ClassIcon:CreateElements(frame)
    -- Icon container
    local container = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0, 0, 0, 0.8)
    container:SetBackdropBorderColor(0, 0, 0, 1)

    -- Class icon texture
    local icon = container:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    icon:SetTexCoord(0, 0.25, 0, 0.25) -- Default to Warrior

    container.icon = icon
    frame.moduleFrames.classIcon = container
end

-- ============================================================================
-- Update Class Icon
-- ============================================================================

function ClassIcon:Update(frame, testData)
    local container = frame.moduleFrames.classIcon
    if not container then return end

    local db = self.core.db.profile.classIcon

    -- Size and position
    container:SetSize(db.size, db.size)
    container:ClearAllPoints()

    if db.position == "LEFT" then
        container:SetPoint("LEFT", frame, "LEFT", 2, 0)
    else
        container:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
    end

    if testData then
        -- Test mode
        local coords = addon.Data.ClassIconCoords[testData.class]
        if coords then
            container.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        end
    else
        self:UpdateUnit(frame)
    end

    container:Show()
end

function ClassIcon:UpdateUnit(frame)
    local container = frame.moduleFrames.classIcon
    if not container then return end

    local unit = frame.unit
    local index = frame.index
    local class = frame.class  -- Use already stored class from prep phase

    -- Method 1: If no stored class, try GetArenaOpponentSpec (works during prep phase)
    if not class and GetArenaOpponentSpec then
        local specID = GetArenaOpponentSpec(index)
        if specID and specID > 0 then
            local _, specName, _, _, role, classFile = GetSpecializationInfoByID(specID)
            if classFile then
                class = classFile
            end
        end
    end

    -- Method 2: Fallback to UnitClass if unit exists
    if not class and UnitExists(unit) then
        local _, classFile = UnitClass(unit)
        class = classFile
    end

    -- Update icon if we found a class
    if class then
        local coords = addon.Data.ClassIconCoords[class]
        if coords then
            container.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        end
        -- Store class for other modules
        frame.class = class
    end
end

function ClassIcon:Reset(frame)
    local container = frame.moduleFrames.classIcon
    if container then
        container.icon:SetTexCoord(0, 0.25, 0, 0.25)
    end
end

-- Register module
addon.Core:RegisterModule("classIcon", ClassIcon)
