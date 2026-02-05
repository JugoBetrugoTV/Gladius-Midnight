--[[
    Gladius Midnight - Class Icon Module
    Displays the class or spec icon for the arena opponent
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

    -- Class/Spec icon texture
    local icon = container:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    icon:SetTexCoord(0, 0.25, 0, 0.25) -- Default to Warrior

    container.icon = icon
    container.isSpecIcon = false  -- Track if currently showing spec icon
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
        -- Test mode - show spec icon if enabled
        if db.showSpec then
            -- Show a random spec icon for test
            local testSpecs = {66, 70, 71, 102, 105, 253, 262, 264, 265, 269}
            local specID = testSpecs[math.random(1, #testSpecs)]
            local _, _, _, specIcon = GetSpecializationInfoByID(specID)
            if specIcon then
                container.icon:SetTexture(specIcon)
                container.icon:SetTexCoord(0, 1, 0, 1)
                container.isSpecIcon = true
            end
        else
            container.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            local coords = addon.Data.ClassIconCoords[testData.class]
            if coords then
                container.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
            end
            container.isSpecIcon = false
        end
    else
        self:UpdateUnit(frame)
    end

    container:Show()
end

function ClassIcon:UpdateUnit(frame)
    local container = frame.moduleFrames.classIcon
    if not container then return end

    local db = self.core.db.profile.classIcon
    local unit = frame.unit
    local index = frame.index
    local class = frame.class  -- Use already stored class from prep phase
    local specID = frame.specID  -- Use stored spec from prep phase

    -- Try to get spec info (works during prep phase)
    if not specID and GetArenaOpponentSpec then
        specID = GetArenaOpponentSpec(index)
        if specID and specID > 0 then
            frame.specID = specID
            local _, specName, _, _, role, classFile = GetSpecializationInfoByID(specID)
            if classFile then
                class = classFile
                frame.class = class
            end
        end
    end

    -- Fallback to UnitClass if unit exists
    if not class and UnitExists(unit) then
        local _, classFile = UnitClass(unit)
        class = classFile
        frame.class = class
    end

    -- Show spec icon if enabled and we have spec info
    if db.showSpec and specID and specID > 0 then
        local _, _, _, specIcon = GetSpecializationInfoByID(specID)
        if specIcon then
            container.icon:SetTexture(specIcon)
            container.icon:SetTexCoord(0, 1, 0, 1)
            container.isSpecIcon = true
            return
        end
    end

    -- Fallback to class icon
    if class then
        if container.isSpecIcon then
            container.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            container.isSpecIcon = false
        end
        local coords = addon.Data.ClassIconCoords[class]
        if coords then
            container.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        end
    end
end

function ClassIcon:Reset(frame)
    local container = frame.moduleFrames.classIcon
    if container then
        container.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        container.icon:SetTexCoord(0, 0.25, 0, 0.25)
        container.isSpecIcon = false
    end
    frame.specID = nil
end

-- Register module
addon.Core:RegisterModule("classIcon", ClassIcon)
