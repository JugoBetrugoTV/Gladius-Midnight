-- ============================================================================
-- File: ArenaCore/Core/UI_DetailedDRSettings_Helpers.lua
-- Purpose: Helper functions for the detailed DR settings window
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

-- Helper function to create settings groups
function AC:CreateSettingsGroup(parent, title, yOffset)
    local group = CreateFrame("Frame", nil, parent)
    group:SetPoint("TOPLEFT", 10, yOffset)
    group:SetPoint("TOPRIGHT", -10, yOffset)
    group:SetHeight(30)
    
    AC:HairlineGroupBox(group)
    
    local titleText = AC:CreateStyledText(group, title, 13, AC.COLORS.PRIMARY, "OVERLAY", "")
    titleText:SetPoint("TOPLEFT", 10, -8)
    
    return group
end

-- Helper function to add range settings
function AC:AddRangeSetting(parent, key, setting, yOffset)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 20, yOffset)
    row:SetPoint("TOPRIGHT", -20, yOffset)
    row:SetHeight(26)
    
    local label = AC:CreateStyledText(row, setting.name, 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    label:SetPoint("LEFT", 0, 0)
    label:SetWidth(200)
    label:SetJustifyH("LEFT")
    
    local slider = AC:CreateFlatSlider(row, 200, 18, setting.min or 0, setting.max or 100, setting.default or 0, false)
    slider:SetPoint("LEFT", label, "RIGHT", 10, 0)
    
    -- Update database when slider changes
    slider.slider:SetScript("OnValueChanged", function(self, value)
        local db = AC.DB.profile.diminishingReturns
        db.drTracker = db.drTracker or {}
        db.drTracker[key] = value
    end)
    
    return yOffset - 30
end

-- Helper function to add toggle settings
function AC:AddToggleSetting(parent, key, setting, yOffset)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 20, yOffset)
    row:SetPoint("TOPRIGHT", -20, yOffset)
    row:SetHeight(26)
    
    local checkbox = AC:CreateFlatCheckbox(row, 20, setting.default or false, function(value)
        local db = AC.DB.profile.diminishingReturns
        db.drTracker = db.drTracker or {}
        db.drTracker[key] = value
    end)
    checkbox:SetPoint("LEFT", 0, 0)
    
    local label = AC:CreateStyledText(row, setting.name, 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
    
    return yOffset - 30
end

-- Helper function to add dropdown settings
function AC:AddDropdownSetting(parent, key, setting, yOffset)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 20, yOffset)
    row:SetPoint("TOPRIGHT", -20, yOffset)
    row:SetHeight(26)
    
    local label = AC:CreateStyledText(row, setting.name, 11, AC.COLORS.TEXT_2, "OVERLAY", "")
    label:SetPoint("LEFT", 0, 0)
    label:SetWidth(200)
    label:SetJustifyH("LEFT")
    
    local dropdown = AC:CreateFlatDropdown(row, 200, 24, setting.values or {}, setting.default or "", function(value)
        local db = AC.DB.profile.diminishingReturns
        db.drTracker = db.drTracker or {}
        db.drTracker[key] = value
    end)
    dropdown:SetPoint("LEFT", label, "RIGHT", 10, 0)
    
    return yOffset - 30
end

-- Build spell dropdown maps for categories
function AC:BuildSpellDropdownMaps(drCategory)
    local values = {}
    local nameToID = {}
    local idToName = {}
    
    -- Dynamic option
    values["1_dynamic"] = "|TInterface\\ICONS\\INV_Misc_QuestionMark:16:16|t Dynamic"
    nameToID["1_dynamic"] = 0
    idToName[0] = "1_dynamic"
    
    -- Custom option
    values["2_custom"] = "|TInterface\\ICONS\\INV_Misc_QuestionMark:16:16|t Custom"
    nameToID["2_custom"] = 1
    idToName[1] = "2_custom"
    
    -- Add actual spells for the category (would need full spell database)
    -- This is a simplified version - full implementation would use DRList
    local categorySpells = {
        ["disorient"] = {
            [8122] = "Psychic Scream",
            [5246] = "Intimidating Shout"
        },
        ["stun"] = {
            [408] = "Kidney Shot",
            [1833] = "Cheap Shot"
        }
        -- Add more categories as needed
    }
    
    if categorySpells[drCategory] then
        for spellID, spellName in pairs(categorySpells[drCategory]) do
            local key = spellName .. "_" .. spellID
            values[key] = "|T" .. (C_Spell.GetSpellTexture(spellID) or "Interface\\ICONS\\INV_Misc_QuestionMark") .. ":16:16|t " .. spellName
            nameToID[key] = spellID
            idToName[spellID] = key
        end
    end
    
    return values, nameToID, idToName
end
