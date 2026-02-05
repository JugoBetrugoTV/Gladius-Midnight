-- =============================================================
-- File: Core/UI_ClassPacksEditor.lua (FINAL WITH HOW-TO SECTION)
-- =============================================================

local AC = _G.ArenaCore
if not AC then return end
-- Custom gradient textures for each class
local classGradients = {
    WARRIOR = "Interface\\AddOns\\ArenaCore\\Media\\UI\\warrior-gradient.tga",
    PALADIN = "Interface\\AddOns\\ArenaCore\\Media\\UI\\paladin-gradient.tga",
    MAGE = "Interface\\AddOns\\ArenaCore\\Media\\UI\\mage-gradient.tga",
    HUNTER = "Interface\\AddOns\\ArenaCore\\Media\\UI\\hunter-gradient.tga",
    ROGUE = "Interface\\AddOns\\ArenaCore\\Media\\UI\\rogue-gradient.tga",
    PRIEST = "Interface\\AddOns\\ArenaCore\\Media\\UI\\priest-gradient.tga",
    SHAMAN = "Interface\\AddOns\\ArenaCore\\Media\\UI\\shaman-gradient.tga",
    WARLOCK = "Interface\\AddOns\\ArenaCore\\Media\\UI\\warlock-gradient.tga",
    MONK = "Interface\\AddOns\\ArenaCore\\Media\\UI\\monk-gradient.tga",
    DRUID = "Interface\\AddOns\\ArenaCore\\Media\\UI\\druid-gradient.tga",
    DEMONHUNTER = "Interface\\AddOns\\ArenaCore\\Media\\UI\\demonhunter-gradient.tga",
    DEATHKNIGHT = "Interface\\AddOns\\ArenaCore\\Media\\UI\\deathknight-gradient.tga",
    EVOKER = "Interface\\AddOns\\ArenaCore\\Media\\UI\\evoker-gradient.tga"
}

AC.Editor = AC.Editor or {}
local Editor = AC.Editor

-- Current selected class and spec for the editor
Editor.currentClass = nil
Editor.currentSpec = 1 -- Default to first spec

-- Safe color references with fallbacks
local function GetColor(colorPath, fallback)
    if AC.COLORS then
        if colorPath == "TEXT_MUTED" then
            return AC.COLORS.TEXT_MUTED or AC.COLORS.TEXT_2 or fallback or {0.7, 0.7, 0.7, 1}
        elseif colorPath == "INPUT_DARK" then
            return AC.COLORS.INPUT_DARK or AC.COLORS.BACKGROUND or fallback or {0.067, 0.067, 0.067, 1}
        elseif colorPath == "BORDER_LIGHT" then
            return AC.COLORS.BORDER_LIGHT or AC.COLORS.BORDER or fallback or {0.278, 0.278, 0.278, 1}
        elseif colorPath == "TEXT" then
            return AC.COLORS.TEXT or fallback or {1, 1, 1, 1}
        elseif colorPath == "TEXT_2" then
            return AC.COLORS.TEXT_2 or AC.COLORS.TEXT or fallback or {0.8, 0.8, 0.8, 1}
        elseif colorPath == "PRIMARY" then
            return AC.COLORS.PRIMARY or fallback or {0.545, 0.271, 1.000, 1}
        elseif colorPath == "HEADER_BG" then
            return AC.COLORS.HEADER_BG or AC.COLORS.BACKGROUND or fallback or {0.125, 0.125, 0.125, 1}
        elseif colorPath == "PANEL_BG" then
            return AC.COLORS.PANEL_BG or AC.COLORS.BACKGROUND or fallback or {0.09, 0.09, 0.09, 1}
        end
    end
    return fallback or {0.5, 0.5, 0.5, 1}
end
-- =============================================================
-- Profile Import/Export System
-- Add this code after the GetColor function in your UI_ClassPacksEditor.lua
-- =============================================================

-- Profile management functions (SEPARATE NAMESPACE from addon ProfileManager)
AC.ClassPacksProfileManager = AC.ClassPacksProfileManager or {}
local PM = AC.ClassPacksProfileManager

-- Safe string encoding/decoding for profile data
local function EncodeProfileData(data)
    local profileData = {
        metadata = {
            version = AC.Version or "0.9.2.2",
            timestamp = time(),
            gameVersion = GetBuildInfo(),
            addonName = "ArenaCore"
        },
        classPacks = {}
    }
    
    -- Copy all class data safely (handles spec-based structure)
    for className, classData in pairs(data) do
        if type(classData) == "table" and RAID_CLASS_COLORS[className] then
            profileData.classPacks[className] = {}
            for specIndex, specData in pairs(classData) do
                if type(specData) == "table" then
                    profileData.classPacks[className][specIndex] = {}
                    for slot = 1, 3 do
                        if specData[slot] and type(specData[slot]) == "table" then
                            profileData.classPacks[className][specIndex][slot] = {}
                            for i, spellData in ipairs(specData[slot]) do
                                if type(spellData) == "table" and #spellData >= 2 then
                                    local spellID = tonumber(spellData[1])
                                    local priority = tonumber(spellData[2])
                                    if spellID and priority and spellID > 0 and priority >= 1 and priority <= 4 then
                                        table.insert(profileData.classPacks[className][specIndex][slot], {spellID, priority})
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Convert to string format
    local function tableToString(t, depth)
        depth = depth or 0
        if depth > 10 then return "nil" end
        
        local result = "{"
        for k, v in pairs(t) do
            local key = type(k) == "string" and '["' .. k .. '"]' or '[' .. tostring(k) .. ']'
            local value
            if type(v) == "table" then
                value = tableToString(v, depth + 1)
            elseif type(v) == "string" then
                value = '"' .. v:gsub('"', '\\"') .. '"'
            else
                value = tostring(v)
            end
            result = result .. key .. "=" .. value .. ","
        end
        return result .. "}"
    end
    
    return tableToString(profileData)
end

local function DecodeProfileData(encodedString)
    if not encodedString or type(encodedString) ~= "string" or encodedString == "" then
        return nil, "Invalid profile data"
    end
    
    -- Remove dangerous functions/keywords
    local dangerousPatterns = {
        "loadstring", "dofile", "loadfile", "getfenv", "setfenv", 
        "rawget", "rawset", "getmetatable", "setmetatable"
    }
    
    for _, pattern in ipairs(dangerousPatterns) do
        if encodedString:find(pattern) then
            return nil, "Profile contains unsafe code"
        end
    end
    
    -- Safely decode
    local success, result = pcall(function()
        local func = loadstring("return " .. encodedString)
        if not func then return nil end
        return func()
    end)
    
    if not success or not result then
        return nil, "Failed to decode profile data"
    end
    
    -- Validate structure
    if not result.metadata or not result.classPacks then
        return nil, "Invalid profile structure"
    end
    
    if result.metadata.addonName ~= "ArenaCore" then
        return nil, "Profile is not for ArenaCore"
    end
    
    return result, nil
end

-- Validate imported spells exist and are usable (handles spec-based structure)
local function ValidateSpellData(classPacks)
    local validatedPacks = {}
    local warnings = {}
    
    for className, classData in pairs(classPacks) do
        if RAID_CLASS_COLORS[className] then
            validatedPacks[className] = {}
            for specIndex, specData in pairs(classData) do
                if type(specData) == "table" then
                    validatedPacks[className][specIndex] = {}
                    for slot = 1, 3 do
                        if specData[slot] then
                            validatedPacks[className][specIndex][slot] = {}
                            for i, spellData in ipairs(specData[slot]) do
                                local spellID, priority = spellData[1], spellData[2]
                                local id, name, icon = AC:GetSpellData(spellID)
                                if id and name then
                                    table.insert(validatedPacks[className][specIndex][slot], {spellID, priority})
                                else
                                    local specName = AC.CLASS_SPECS[className] and AC.CLASS_SPECS[className][specIndex] and AC.CLASS_SPECS[className][specIndex].name or "Spec " .. specIndex
                                    table.insert(warnings, "Unknown spell ID " .. spellID .. " for " .. className .. " (" .. specName .. ")")
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return validatedPacks, warnings
end

-- Export current profile
function PM:ExportProfile()
    -- CRITICAL FIX: Use actual user data from database, not default ClassPacks
    local userData = AC.DB and AC.DB.profile and AC.DB.profile.classPacks
    if not userData then
        return nil, "No user class pack data found"
    end
    
    -- Convert spec-based data to exportable format
    local exportData = {}
    for className, classData in pairs(userData) do
        if type(classData) == "table" and RAID_CLASS_COLORS[className] then
            exportData[className] = {}
            for specIndex, specData in pairs(classData) do
                if type(specData) == "table" then
                    -- Export all specs for this class
                    if not exportData[className][specIndex] then
                        exportData[className][specIndex] = {}
                    end
                    for slot = 1, 3 do
                        if specData[slot] and type(specData[slot]) == "table" then
                            exportData[className][specIndex][slot] = {}
                            for _, spellData in ipairs(specData[slot]) do
                                if type(spellData) == "table" and spellData[1] and spellData[2] then
                                    table.insert(exportData[className][specIndex][slot], {spellData[1], spellData[2]})
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    local encoded = EncodeProfileData(exportData)
    return encoded, nil
end

-- Import profile with validation
function PM:ImportProfile(encodedData, overwriteExisting)
    local profileData, error = DecodeProfileData(encodedData)
    if not profileData then
        return false, error
    end
    
    local validatedPacks, warnings = ValidateSpellData(profileData.classPacks)
    
    if overwriteExisting then
        -- Backup current data
        if AC.DB and AC.DB.profile and AC.DB.profile.classPacks then
            AC.ClassPacksBackup = AC.DB.profile.classPacks
        end
        
        -- Apply imported data to database (spec-based structure)
        if not AC.DB then AC.DB = {} end
        if not AC.DB.profile then AC.DB.profile = {} end
        AC.DB.profile.classPacks = validatedPacks
        
        -- Also update in-memory ClassPacks for immediate use
        AC.ClassPacks = validatedPacks
        
        -- Save to persistent storage
        if AC.SaveClassPacksToDatabase then
            AC:SaveClassPacksToDatabase()
        end
        
        -- Refresh UI if editor is open
        if Editor.Frame and Editor.Frame:IsShown() and Editor.currentClass then
            Editor.PopulateClass(Editor.currentClass)
        end
        
        -- Refresh aura system
        if AC.Auras and AC.Auras.RefreshAll then
            AC.Auras:RefreshAll()
        end
    end
    
    return true, warnings
end

-- Create Profile Management UI
function AC.CreateProfileSection(parent)
    local profileSection = CreateFrame("Frame", nil, parent)
    profileSection:SetPoint("TOPLEFT", 8, -8)
    profileSection:SetPoint("TOPRIGHT", -8, -8)
    profileSection:SetHeight(500)
    
    AC:HairlineGroupBox(profileSection)
    
    local title = AC:CreateStyledText(profileSection, "Profile Import/Export", 14, GetColor("PRIMARY"), "OVERLAY", "")
    title:SetPoint("TOPLEFT", 12, -8)
    
    -- Export Section
    local exportLabel = AC:CreateStyledText(profileSection, "Export Your Profile:", 12, GetColor("TEXT"), "OVERLAY", "")
    exportLabel:SetPoint("TOPLEFT", 12, -35)
    
    local exportDesc = AC:CreateStyledText(profileSection, "Generate a shareable code containing all your class pack configurations.", 10, GetColor("TEXT_2"), "OVERLAY", "")
    exportDesc:SetPoint("TOPLEFT", 12, -50)
    exportDesc:SetPoint("TOPRIGHT", -12, -50)
    exportDesc:SetJustifyH("LEFT")
    exportDesc:SetWordWrap(true)
    
    local exportBtn = AC:CreateTexturedButton(profileSection, 100, 24, "EXPORT", "button-test")
    exportBtn:SetPoint("TOPLEFT", 12, -75)
    
    -- =============================================================
-- Fix EditBox Text Display Issue
-- Replace the export EditBox creation section in AC.CreateProfileSection
-- Find around line 180+ where exportEdit is created
-- =============================================================

-- =============================================================
-- Also fix the Import EditBox with the same approach
-- Replace the importBox creation section
-- =============================================================

-- =============================================================
-- Fix EditBox Text Display Issue
-- Replace the export EditBox creation section in AC.CreateProfileSection
-- Find around line 180+ where exportEdit is created
-- =============================================================

-- FIXED Export Box - Replace the exportBox creation section
local exportBox = CreateFrame("Frame", nil, profileSection)  -- Changed from ScrollFrame to Frame
exportBox:SetPoint("TOPLEFT", 12, -110)
exportBox:SetPoint("TOPRIGHT", -12, -110)
exportBox:SetHeight(120)

local exportBorder = AC:CreateFlatTexture(exportBox, "BACKGROUND", 1, GetColor("BORDER_LIGHT"))
exportBorder:SetAllPoints()

local exportBg = AC:CreateFlatTexture(exportBox, "BACKGROUND", 2, GetColor("INPUT_DARK"))
exportBg:SetPoint("TOPLEFT", 1, -1)
exportBg:SetPoint("BOTTOMRIGHT", -1, 1)

-- Create ScrollFrame inside the border frame
local exportScrollFrame = CreateFrame("ScrollFrame", nil, exportBox)
exportScrollFrame:SetPoint("TOPLEFT", 2, -2)
exportScrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)

-- Create the actual EditBox
local exportEdit = CreateFrame("EditBox", nil, exportScrollFrame)
exportEdit:SetWidth(exportScrollFrame:GetWidth() - 10)  -- Leave some padding
exportEdit:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
exportEdit:SetTextColor(GetColor("TEXT")[1], GetColor("TEXT")[2], GetColor("TEXT")[3], 1)
exportEdit:SetMultiLine(true)
exportEdit:SetAutoFocus(false)
exportEdit:SetMaxLetters(0)
exportEdit:SetJustifyH("LEFT")
exportEdit:SetJustifyV("TOP")


exportEdit:SetScript("OnEscapePressed", function(self) 
    self:ClearFocus() 
end)

-- Set the EditBox as scroll child
exportScrollFrame:SetScrollChild(exportEdit)
exportScrollFrame:SetScript("OnMouseDown", function() exportEdit:SetFocus() end)

-- Update the export button click handler
exportBtn:SetScript("OnClick", function()
    local profileCode, error = PM:ExportProfile()
    if profileCode then
        -- FIXED: Force text setting with proper methods
        exportEdit:SetText("")  -- Clear first
        exportEdit:Insert(profileCode)  -- Use Insert instead of SetText
        exportEdit:HighlightText(0, string.len(profileCode))  -- Highlight all text
        exportEdit:SetFocus()
        
        print("|cff8B45FFArenaCore:|r Profile exported! Code length: " .. string.len(profileCode))
    else
        print("|cff8B45FFArenaCore:|r Export failed: " .. (error or "Unknown error"))
    end
end)

-- =============================================================
-- Also fix the Import EditBox with the same approach
-- Replace the importBox creation section
-- =============================================================

-- FIXED Import Box
local importBox = CreateFrame("Frame", nil, profileSection)  -- Changed from ScrollFrame to Frame
importBox:SetPoint("TOPLEFT", 12, -290)
importBox:SetPoint("TOPRIGHT", -12, -290)
importBox:SetHeight(120)

local importBorder = AC:CreateFlatTexture(importBox, "BACKGROUND", 1, GetColor("BORDER_LIGHT"))
importBorder:SetAllPoints()

local importBg = AC:CreateFlatTexture(importBox, "BACKGROUND", 2, GetColor("INPUT_DARK"))
importBg:SetPoint("TOPLEFT", 1, -1)
importBg:SetPoint("BOTTOMRIGHT", -1, 1)

-- Create ScrollFrame inside the border frame
local importScrollFrame = CreateFrame("ScrollFrame", nil, importBox)
importScrollFrame:SetPoint("TOPLEFT", 2, -2)
importScrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)

-- Create the actual EditBox
local importEdit = CreateFrame("EditBox", nil, importScrollFrame)
importEdit:SetWidth(importScrollFrame:GetWidth() - 10)
importEdit:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
importEdit:SetTextColor(GetColor("TEXT")[1], GetColor("TEXT")[2], GetColor("TEXT")[3], 1)
importEdit:SetMultiLine(true)
importEdit:SetAutoFocus(false)
importEdit:SetMaxLetters(0)
importEdit:SetJustifyH("LEFT")
importEdit:SetJustifyV("TOP")

importEdit:SetScript("OnTextChanged", function(self)
    -- No height management needed
end)

importEdit:SetScript("OnEscapePressed", function(self) 
    self:ClearFocus() 
end)

-- Set the EditBox as scroll child
importScrollFrame:SetScrollChild(importEdit)
importScrollFrame:SetScript("OnMouseDown", function() importEdit:SetFocus() end)
    
    -- Import Section
    local importLabel = AC:CreateStyledText(profileSection, "Import Profile:", 12, GetColor("TEXT"), "OVERLAY", "")
    importLabel:SetPoint("TOPLEFT", 12, -245)
    
    local importDesc = AC:CreateStyledText(profileSection, "Paste a profile code here to import someone else's class pack configuration. This will overwrite your current settings!", 10, GetColor("TEXT_2"), "OVERLAY", "")
    importDesc:SetPoint("TOPLEFT", 12, -260)
    importDesc:SetPoint("TOPRIGHT", -12, -260)
    importDesc:SetJustifyH("LEFT")
    importDesc:SetWordWrap(true)
    
    
    local importBtn = AC:CreateTexturedButton(profileSection, 100, 24, "IMPORT", "button-test")
    importBtn:SetPoint("TOPLEFT", 12, -425)
    
    local previewBtn = AC:CreateEnhancedButton(profileSection, 100, 24, "PREVIEW", "", GetColor("TEXT_2"), GetColor("PRIMARY"))
    previewBtn:SetPoint("LEFT", importBtn, "RIGHT", 10, 0)
    
    importBtn:SetScript("OnClick", function()
        local profileCode = importEdit:GetText()
        if profileCode == "" then
            print("|cff8B45FFArenaCore:|r Please paste a profile code first.")
            return
        end
        
        -- Show confirmation dialog
        StaticPopup_Show("ARENACORE_IMPORT_CONFIRM", nil, nil, profileCode)
    end)
    
    previewBtn:SetScript("OnClick", function()
        local profileCode = importEdit:GetText()
        if profileCode == "" then
            print("|cff8B45FFArenaCore:|r Please paste a profile code first.")
            return
        end
        
        local profileData, error = DecodeProfileData(profileCode)
        if not profileData then
            print("|cff8B45FFArenaCore:|r Invalid profile: " .. error)
            return
        end
        
        -- Show preview information (handles spec-based structure)
        local spellCount = 0
        local classCount = 0
        local specCount = 0
        for className, classData in pairs(profileData.classPacks) do
            classCount = classCount + 1
            for specIndex, specData in pairs(classData) do
                if type(specData) == "table" then
                    specCount = specCount + 1
                    for slot = 1, 3 do
                        if specData[slot] then
                            spellCount = spellCount + #specData[slot]
                        end
                    end
                end
            end
        end
        
        print("|cff8B45FFArenaCore:|r Profile Preview:")
        print("  Created: " .. date("%Y-%m-%d %H:%M", profileData.metadata.timestamp))
        print("  Version: " .. (profileData.metadata.version or "Unknown"))
        print("  Classes: " .. classCount)
        print("  Specs: " .. specCount)
        print("  Total Spells: " .. spellCount)
    end)
    
    return profileSection
end

-- Add StaticPopup for import confirmation
StaticPopupDialogs["ARENACORE_IMPORT_CONFIRM"] = {
    text = "This will overwrite ALL your current class pack settings. Are you sure?",
    button1 = "Import",
    button2 = "Cancel",
    OnAccept = function(self, data)
        local success, warnings = PM:ImportProfile(data, true)
        if success then
            print("|cff8B45FFArenaCore:|r Profile imported successfully!")
            if #warnings > 0 then
                print("|cffFFAA00Warning:|r Some spells could not be imported:")
                for _, warning in ipairs(warnings) do
                    print("  " .. warning)
                end
            end
        else
            print("|cff8B45FFArenaCore:|r Import failed: " .. table.concat(warnings, ", "))
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
-- Priority options with full funny text
local PRIORITY_OPTIONS = {
    {value = 1, label = "WATCH FOR THIS I CARE THE MOST", short = "WATCH", color = {1, 0.2, 0.2, 1}},
    {value = 2, label = "Really Care", short = "CARE", color = {1, 0.6, 0, 1}},
    {value = 3, label = "Kinda Care", short = "KINDA", color = {1, 1, 0, 1}},
    {value = 4, label = "Don't Care For It But Have It Anyway", short = "MEH", color = {0.5, 0.5, 0.5, 1}}
}

local function GetPriorityData(priority)
    return PRIORITY_OPTIONS[priority] or PRIORITY_OPTIONS[4]
end

-- OPTIMALLY SIZED priority dropdown - no clipping
local function CreatePriorityDropdown(parent, currentPriority, onSelect, isInRow)
    local dropdown = CreateFrame("Frame", nil, parent)
    
    if isInRow then
        dropdown:SetSize(130, 16)
    else
        dropdown:SetSize(220, 20) -- SLIGHTLY REDUCED from 240px to prevent clipping
    end
    
    -- Border and background using ArenaCore styling
    local border = AC:CreateFlatTexture(dropdown, "BACKGROUND", 1, GetColor("BORDER_LIGHT"))
    border:SetAllPoints()
    
    local bg = AC:CreateFlatTexture(dropdown, "BACKGROUND", 2, GetColor("INPUT_DARK"))
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Current selection display
    local selectedValue = currentPriority
    local currentOption = PRIORITY_OPTIONS[selectedValue] or PRIORITY_OPTIONS[4]
    local displayText, textColor
    
    if selectedValue == 0 or selectedValue == nil then
        displayText = "Choose Priority"
        textColor = GetColor("TEXT_MUTED")
    else
        displayText = isInRow and currentOption.short or currentOption.label
        textColor = currentOption.color
    end
    
    local text = AC:CreateStyledText(dropdown, displayText, isInRow and 8 or 9, textColor, "OVERLAY", "")
    text:SetPoint("LEFT", 6, 0)
    text:SetPoint("RIGHT", -16, 0)
    text:SetJustifyH("LEFT")
    dropdown.text = text
    
    -- Dropdown arrow
-- Dropdown arrow - PROFESSIONAL TEXTURED ARROW
local arrow = dropdown:CreateTexture(nil, "OVERLAY")
arrow:SetSize(isInRow and 12 or 16, isInRow and 12 or 16)
arrow:SetPoint("RIGHT", -4, 0)
arrow:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\dropdown-arrow-purple.tga")
arrow:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Slight crop for clean edges
    
    -- Make it clickable
    local button = CreateFrame("Button", nil, dropdown)
    button:SetAllPoints()
    
    -- Smart positioned dropdown menu
    local menuWidth = isInRow and 280 or 300
    local menu = CreateFrame("Frame", nil, UIParent)
    menu:SetSize(menuWidth, #PRIORITY_OPTIONS * 22)
    menu:SetFrameStrata("TOOLTIP")
    menu:Hide()
    
    local menuBorder = AC:CreateFlatTexture(menu, "BACKGROUND", 1, GetColor("BORDER_LIGHT"))
    menuBorder:SetAllPoints()
    
    local menuBg = AC:CreateFlatTexture(menu, "BACKGROUND", 2, GetColor("INPUT_DARK"))
    menuBg:SetPoint("TOPLEFT", 1, -1)
    menuBg:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Menu options
    for i, option in ipairs(PRIORITY_OPTIONS) do
        local optionBtn = CreateFrame("Button", nil, menu)
        optionBtn:SetSize(menuWidth - 2, 20)
        optionBtn:SetPoint("TOPLEFT", 1, -(i-1) * 22 - 1)
        
        local optionBg = AC:CreateFlatTexture(optionBtn, "BACKGROUND", 1, {0, 0, 0, 0})
        optionBg:SetAllPoints()
        
        local optionText = AC:CreateStyledText(optionBtn, option.label, 10, option.color, "OVERLAY", "")
        optionText:SetPoint("LEFT", 4, 0)
        optionText:SetJustifyH("LEFT")
        
        optionBtn:SetScript("OnEnter", function()
            local primaryColor = GetColor("PRIMARY")
            optionBg:SetColorTexture(primaryColor[1]*0.3, primaryColor[2]*0.3, primaryColor[3]*0.3, 1)
        end)
        
        optionBtn:SetScript("OnLeave", function()
            optionBg:SetColorTexture(0, 0, 0, 0)
        end)
        
        optionBtn:SetScript("OnClick", function()
            selectedValue = option.value
            local newDisplayText = isInRow and option.short or option.label
            text:SetText(newDisplayText)
            text:SetTextColor(option.color[1], option.color[2], option.color[3], option.color[4])
            menu:Hide()
            
            -- CRITICAL FIX: Delayed callback to prevent focus interference
            if onSelect then
                C_Timer.After(0.05, function()
                    onSelect(option.value)
                end)
            end
        end)
    end
    
    button:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
        else
            local dropdownX, dropdownY = dropdown:GetCenter()
            local screenHeight = UIParent:GetHeight()
            
            if dropdownY > screenHeight / 2 then
                menu:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 2)
            else
                menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
            end
            
            menu:Show()
        end
    end)
    
    -- Hide menu when clicking elsewhere - IMPROVED FOR TARGETING FIX
    menu:SetScript("OnShow", function()
        local hideFrame = CreateFrame("Frame", nil, UIParent)
        hideFrame:SetAllPoints()
        hideFrame:SetFrameStrata("TOOLTIP")
        hideFrame:SetScript("OnMouseDown", function()
            menu:Hide()
            hideFrame:Hide()
            -- CRITICAL FIX: Force mouse targeting refresh after menu closes
            C_Timer.After(0.01, function()
                if UIParent then
                    UIParent:SetScript("OnUpdate", function(self)
                        self:SetScript("OnUpdate", nil)
                    end)
                end
            end)
        end)
        hideFrame:Show()
    end)
    
    dropdown.getValue = function() return selectedValue end
    dropdown.setValue = function(value)
        selectedValue = value
        if value == 0 or value == nil then
            text:SetText("Choose Priority")
            text:SetTextColor(GetColor("TEXT_MUTED")[1], GetColor("TEXT_MUTED")[2], GetColor("TEXT_MUTED")[3], 1)
        else
            local option = PRIORITY_OPTIONS[value] or PRIORITY_OPTIONS[4]
            local newDisplayText = isInRow and option.short or option.label
            text:SetText(newDisplayText)
            text:SetTextColor(option.color[1], option.color[2], option.color[3], option.color[4])
        end
    end
    
    return dropdown
end

-- Helper function for accurate text width calculation
local function GetTextWidth(str)
    -- More accurate text width calculation with special handling for long names
    local baseWidth = str:len() * 5.5 + 8
    
    -- Special case for exceptionally long spec names
    if str == "Marksmanship" then
        return baseWidth + 10 -- Extra 10px padding for Marksmanship
    end
    
    return baseWidth
end

-- Create spec dropdown for class selection
local function CreateSpecDropdown(parent, className, currentSpec, onSelect)
    local specs = AC.CLASS_SPECS[className]
    if not specs then return nil end
    
    local dropdown = CreateFrame("Frame", nil, parent)
    dropdown:SetSize(200, 24)
    
    -- Border and background using ArenaCore styling
    local border = AC:CreateFlatTexture(dropdown, "BACKGROUND", 1, GetColor("BORDER_LIGHT"))
    border:SetAllPoints()
    
    local bg = AC:CreateFlatTexture(dropdown, "BACKGROUND", 2, GetColor("INPUT_DARK"))
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Current selection display
    local selectedValue = currentSpec or 1
    local currentSpecData = specs[selectedValue]
    local displayText = currentSpecData and currentSpecData.name or "Select Spec"
    
    local text = AC:CreateStyledText(dropdown, displayText, 10, GetColor("TEXT"), "OVERLAY", "")
    text:SetPoint("LEFT", 6, 0)
    text:SetJustifyH("LEFT")
    dropdown.text = text
    
    -- Create styled spec icon (using proper ArenaCore styling)
    local specIconFrame = AC:CreateStyledIcon(dropdown, 16, true, true)
    local textWidth = GetTextWidth(displayText)
    specIconFrame:SetPoint("LEFT", textWidth + 8, 0) -- Text width + 8px padding
    dropdown.specIconFrame = specIconFrame
    dropdown.specIcon = specIconFrame.icon -- Keep reference for compatibility
    
    if currentSpecData then
        dropdown.specIcon:SetTexture(currentSpecData.icon)
    end
    
    -- Dropdown arrow
    local arrow = dropdown:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(12, 12)
    arrow:SetPoint("RIGHT", -4, 0)
    arrow:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\dropdown-arrow-purple.tga")
    arrow:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- Make it clickable
    local button = CreateFrame("Button", nil, dropdown)
    button:SetAllPoints()
    
    -- Smart positioned dropdown menu
    local menuWidth = 220
    local menu = CreateFrame("Frame", nil, UIParent)
    menu:SetSize(menuWidth, #specs * 26)
    menu:SetFrameStrata("TOOLTIP")
    menu:Hide()
    
    local menuBorder = AC:CreateFlatTexture(menu, "BACKGROUND", 1, GetColor("BORDER_LIGHT"))
    menuBorder:SetAllPoints()
    
    local menuBg = AC:CreateFlatTexture(menu, "BACKGROUND", 2, GetColor("INPUT_DARK"))
    menuBg:SetPoint("TOPLEFT", 1, -1)
    menuBg:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Menu options
    for specIndex, specData in ipairs(specs) do
        local optionBtn = CreateFrame("Button", nil, menu)
        optionBtn:SetSize(menuWidth - 2, 24)
        optionBtn:SetPoint("TOPLEFT", 1, -(specIndex-1) * 26 - 1)
        
        local optionBg = AC:CreateFlatTexture(optionBtn, "BACKGROUND", 1, {0, 0, 0, 0})
        optionBg:SetAllPoints()
        
        local optionText = AC:CreateStyledText(optionBtn, specData.name, 10, GetColor("TEXT"), "OVERLAY", "")
        optionText:SetPoint("LEFT", 6, 0)
        optionText:SetJustifyH("LEFT")
        
        -- Calculate proper icon positioning for this option
        local optionTextWidth = GetTextWidth(specData.name)
        
        -- Create styled spec icon in menu (using proper ArenaCore styling)
        local menuIconFrame = AC:CreateStyledIcon(optionBtn, 16, true, true)
        menuIconFrame:SetPoint("LEFT", optionTextWidth + 8, 0) -- Text width + 8px padding
        local menuIcon = menuIconFrame.icon
        menuIcon:SetTexture(specData.icon)
        
        optionBtn:SetScript("OnEnter", function()
            local primaryColor = GetColor("PRIMARY")
            optionBg:SetColorTexture(primaryColor[1]*0.3, primaryColor[2]*0.3, primaryColor[3]*0.3, 1)
        end)
        
        optionBtn:SetScript("OnLeave", function()
            optionBg:SetColorTexture(0, 0, 0, 0)
        end)
        
        optionBtn:SetScript("OnClick", function()
            selectedValue = specIndex
            text:SetText(specData.name)
            dropdown.specIcon:SetTexture(specData.icon)
            
            -- Update dynamic positioning when spec changes
            local newTextWidth = GetTextWidth(specData.name)
            dropdown.specIconFrame:ClearAllPoints()
            dropdown.specIconFrame:SetPoint("LEFT", newTextWidth + 8, 0)
            
            menu:Hide()
            if onSelect then onSelect(specIndex) end
        end)
    end
    
    button:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
        else
            local dropdownX, dropdownY = dropdown:GetCenter()
            local screenHeight = UIParent:GetHeight()
            
            if dropdownY > screenHeight / 2 then
                menu:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 2)
            else
                menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
            end
            
            menu:Show()
        end
    end)
    
    -- Hide menu when clicking elsewhere
    menu:SetScript("OnShow", function()
        local hideFrame = CreateFrame("Frame", nil, UIParent)
        hideFrame:SetAllPoints()
        hideFrame:SetFrameStrata("TOOLTIP")
        hideFrame:SetScript("OnMouseDown", function()
            menu:Hide()
            hideFrame:Hide()
        end)
        hideFrame:Show()
    end)
    
    dropdown.getValue = function() return selectedValue end
    dropdown.setValue = function(value)
        selectedValue = value
        local specData = specs[value]
        if specData then
            text:SetText(specData.name)
            specIcon:SetTexture(specData.icon)
        end
    end
    
    return dropdown
end

-- Spell row - unchanged
local function CreateSpellRow(parent, spellID, priority, className, slot, rowIndex, specIndex)
    local id, spellName, spellIcon = AC:GetSpellData(spellID)
    if not id then return nil end

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(250, 44)
    row.spellID = spellID  -- Store spellID on the row
    row.priority = priority  -- Store priority on the row
    
    local priorityData = GetPriorityData(priority)
    
    local rowBg = AC:CreateFlatTexture(row, "BACKGROUND", 1, GetColor("INPUT_DARK"))
    rowBg:SetAllPoints()
    
    local rowBorder = AC:CreateFlatTexture(row, "BACKGROUND", 2, GetColor("BORDER_LIGHT"))
    rowBorder:SetPoint("TOPLEFT", -1, 1)
    rowBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    
    local priorityBar = AC:CreateFlatTexture(row, "OVERLAY", 3, priorityData.color)
    priorityBar:SetPoint("LEFT", 0, 0)
    priorityBar:SetSize(3, 44)

    -- Create styled icon using new classic system
    local iconFrame = AC:CreateStyledIcon(row, 28, true, true)
    iconFrame:SetPoint("LEFT", 8, 0)
    local icon = iconFrame.icon -- Keep reference for compatibility
    icon:SetTexture(spellIcon)
    
    -- Add spell tooltip functionality
    iconFrame:EnableMouse(true)
    iconFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(spellID)
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    local name = AC:CreateStyledText(row, spellName, 11, GetColor("TEXT"), "OVERLAY", "")
    name:SetPoint("LEFT", icon, "RIGHT", 6, 8)
    name:SetPoint("RIGHT", -28, 8)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    
    local idText = AC:CreateStyledText(row, "(" .. id .. ")", 9, GetColor("TEXT_MUTED"), "OVERLAY", "")
    idText:SetPoint("LEFT", icon, "RIGHT", 6, -8)

    local priorityDropdown = CreatePriorityDropdown(row, priority, function(newPriority)
        if AC:UpdateSpellPriority(className, slot, spellID, newPriority, specIndex) then
            Editor.PopulateClass(className)
            if AC.Auras and AC.Auras.RefreshAll then
                AC.Auras:RefreshAll()
            end
        end
    end, true)
    priorityDropdown:SetPoint("BOTTOMRIGHT", -28, 2)

    local removeBtn = AC:CreateTexturedButton(row, 20, 20, "", "button-close")
    removeBtn:SetPoint("TOPRIGHT", -4, -4)
    
    local removeText = AC:CreateStyledText(removeBtn, "×", 12, GetColor("TEXT"), "OVERLAY", "")
    removeText:SetPoint("CENTER")
    
    removeBtn:SetScript("OnClick", function()
        if AC:RemoveSpellFromPack(className, slot, spellID, specIndex) then
            -- Refresh the UI using the Editor's current class
            if Editor and Editor.currentClass then
                -- Use a timer to ensure we're in a stable state when refreshing
                C_Timer.After(0, function()
                    if Editor and Editor.PopulateClass and Editor.currentClass then
                        Editor.PopulateClass(Editor.currentClass)
                    end
                end)
            end
            if AC.Auras and AC.Auras.RefreshAll then
                C_Timer.After(0, AC.Auras.RefreshAll, AC.Auras)
            end
        end
    end)
    
    return row
end

-- Add spell interface - unchanged
-- =============================================================
-- FIX 1: Full Clickable Input Box for Spell ID
-- Replace the CreateAddSpellInterface function in UI_ClassPacksEditor.lua
-- =============================================================

local function CreateAddSpellInterface(parent, className, slot, specIndex)
    specIndex = specIndex or 1 -- Default to first spec
    
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(300, 130)
    
    AC:HairlineGroupBox(container)
    
    local title = AC:CreateStyledText(container, "Add New Spell", 11, GetColor("PRIMARY"), "OVERLAY", "")
    title:SetPoint("TOPLEFT", 12, -8)
    
    local spellLabel = AC:CreateStyledText(container, "Spell ID:", 10, GetColor("TEXT_2"), "OVERLAY", "")
    spellLabel:SetPoint("TOPLEFT", 12, -28)
    
    -- Add "Press Enter" hint text for manual typing
    local enterHint = AC:CreateStyledText(container, "(Press Enter)", 8, GetColor("TEXT_MUTED"), "OVERLAY", "")
    enterHint:SetPoint("LEFT", spellLabel, "RIGHT", 155, 0)
    
    -- FIXED: Create a proper full-width clickable input
    local inputContainer = CreateFrame("Frame", nil, container)
    inputContainer:SetSize(140, 18)
    inputContainer:SetPoint("LEFT", spellLabel, "RIGHT", 8, 0)
    
    -- Input background and border
    local inputBorder = AC:CreateFlatTexture(inputContainer, "BACKGROUND", 1, GetColor("BORDER_LIGHT"))
    inputBorder:SetAllPoints()
    
    local inputBg = AC:CreateFlatTexture(inputContainer, "BACKGROUND", 2, GetColor("INPUT_DARK"))
    inputBg:SetPoint("TOPLEFT", 1, -1)
    inputBg:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Create the actual EditBox that fills the entire container
    local spellInput = CreateFrame("EditBox", "ArenaCore_SpellInput_" .. className .. "_" .. slot, inputContainer)
    spellInput:SetPoint("TOPLEFT", 3, -2)
    spellInput:SetPoint("BOTTOMRIGHT", -3, 2)
    spellInput:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    spellInput:SetTextColor(GetColor("TEXT")[1], GetColor("TEXT")[2], GetColor("TEXT")[3], 1)
    spellInput:SetAutoFocus(false)
    spellInput:SetMaxLetters(10)
    spellInput:SetNumeric(true)
    
    
    -- Placeholder text
    local placeholder = AC:CreateStyledText(inputContainer, "e.g., 107574", 9, GetColor("TEXT_MUTED"), "OVERLAY", "")
    placeholder:SetPoint("LEFT", 3, 0)
    placeholder:SetJustifyH("LEFT")
    
    -- Show/hide placeholder based on text content
    local function UpdatePlaceholder()
        local text = spellInput:GetText()
        if text == "" then
            placeholder:Show()
        else
            placeholder:Hide()
        end
    end
    
    -- Declare variables first before setting up handlers
    local UpdateValidation
    
    -- Track input order for UX flow
    local inputOrder = {
        spellFirst = false,
        priorityFirst = false,
        lastInput = nil
    }
    
    -- Copy/paste detection variables
    local inputTracking = {
        lastText = "",
        lastTextLength = 0,
        lastChangeTime = 0,
        wasPasteOperation = false
    }
    
    spellInput:SetScript("OnTextChanged", function(self)
        local currentText = self:GetText() or ""
        local currentTime = GetTime()
        local currentLength = string.len(currentText)
        
        
        -- COPY/PASTE DETECTION LOGIC
        local lengthDifference = math.abs(currentLength - inputTracking.lastTextLength)
        local timeDifference = currentTime - inputTracking.lastChangeTime
        
        -- Detect paste operation:
        -- 1. Large text change (3+ characters at once)
        -- 2. OR complete text replacement
        -- 3. OR very rapid input (< 0.1 seconds with 2+ chars)
        inputTracking.wasPasteOperation = false
        
        if lengthDifference >= 3 then
            -- Large text change indicates paste
            inputTracking.wasPasteOperation = true
        elseif inputTracking.lastText ~= "" and currentText ~= "" and not string.find(currentText, inputTracking.lastText, 1, true) then
            -- Text replacement (old text not found in new text) indicates paste
            inputTracking.wasPasteOperation = true
        elseif timeDifference < 0.1 and lengthDifference >= 2 then
            -- Rapid multi-character input indicates paste
            inputTracking.wasPasteOperation = true
        else
        end
        
        -- Update tracking variables
        inputTracking.lastText = currentText
        inputTracking.lastTextLength = currentLength
        inputTracking.lastChangeTime = currentTime
        
        -- Track input order for UX flow
        if currentText ~= "" then
            inputOrder.lastInput = "spell"
        end
        
        -- FOCUS FIX: Prevent focus stealing during validation
        local hadFocus = self:HasFocus()
        UpdateValidation()
        
        -- Restore focus if it was lost during validation
        if hadFocus and not self:HasFocus() then
            C_Timer.After(0.001, function()
                if self and self:IsVisible() then
                    self:SetFocus()
                end
            end)
        end
    end)
    
    -- Run initial validation to set proper button state
    C_Timer.After(0.1, function()
        if UpdateValidation then
            UpdateValidation()
        end
    end)
    
    
    spellInput:SetScript("OnEditFocusGained", function(self)
        placeholder:Hide()
        inputBorder:SetColorTexture(GetColor("PRIMARY")[1], GetColor("PRIMARY")[2], GetColor("PRIMARY")[3], 0.8)
    end)
    
    spellInput:SetScript("OnEditFocusLost", function(self)
        UpdatePlaceholder()
        inputBorder:SetColorTexture(GetColor("BORDER_LIGHT")[1], GetColor("BORDER_LIGHT")[2], GetColor("BORDER_LIGHT")[3], 1)
    end)
    
    -- Make the entire container clickable to focus the input
    local clickArea = CreateFrame("Button", nil, inputContainer)
    clickArea:SetAllPoints()
    clickArea:SetScript("OnClick", function()
        spellInput:SetFocus()
        spellInput:HighlightText() -- Ensure text is ready for input
    end)
    
    UpdatePlaceholder()
    
    local priorityLabel = AC:CreateStyledText(container, "Priority:", 10, GetColor("TEXT_2"), "OVERLAY", "")
    priorityLabel:SetPoint("TOPLEFT", 12, -56)
    
    local priorityDropdown = CreatePriorityDropdown(container, 0, function(value)
        -- Trigger validation when priority changes
        
        -- Track input order for UX flow
        if value and value > 0 then
            inputOrder.lastInput = "priority"
        end
        
        if UpdateValidation then
            UpdateValidation()
        end
        
        -- FIXED: DO NOT refocus the spell input after dropdown selection
    end, false)
    priorityDropdown:SetPoint("LEFT", priorityLabel, "RIGHT", 8, 0)
    
    -- FULLY AUTOMATED UX: No buttons, no checkboxes - pure automation!
    
    -- Create styled preview icon using new classic system
    local previewIconFrame = AC:CreateStyledIcon(container, 14, true, true)
    previewIconFrame:SetPoint("TOPLEFT", 12, -85)
    local previewIcon = previewIconFrame.icon -- Keep reference for compatibility
    previewIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    previewIcon:Hide()
    
    local previewText = AC:CreateStyledText(container, "", 9, GetColor("TEXT_MUTED"), "OVERLAY", "")
    previewText:SetPoint("LEFT", previewIcon, "RIGHT", 4, 0)
    previewText:SetPoint("RIGHT", container, "RIGHT", -12, 0)
    previewText:SetJustifyH("LEFT")
    
    -- AUTO-ADD FUNCTION: Handles the actual spell addition
    local function AutoAddSpell()
        local inputText = spellInput:GetText()
        local spellID = tonumber(inputText)
        local priority = priorityDropdown.getValue()
        
        
        if spellID and priority and priority > 0 then
            local success, message = AC:AddSpellToPack(className, slot, spellID, priority, specIndex)
            if success then
                -- Clear inputs
                spellInput:SetText("")
                priorityDropdown.setValue(0)
                
                -- Reset input tracking
                inputOrder.spellFirst = false
                inputOrder.priorityFirst = false
                inputOrder.lastInput = nil
                
                -- Reset copy/paste tracking
                inputTracking.lastText = ""
                inputTracking.lastTextLength = 0
                inputTracking.lastChangeTime = 0
                inputTracking.wasPasteOperation = false
                
                
                -- Refresh UI
                C_Timer.After(0.1, function()
                    if Editor and Editor.PopulateClass then
                        Editor.PopulateClass(className)
                    end
                    if AC.Auras and AC.Auras.RefreshAll then
                        AC.Auras:RefreshAll()
                    end
                end)
                return true
            else
                return false
            end
        end
        return false
    end
    
    -- MODERN UX VALIDATION: Handles auto-add logic based on input order
    UpdateValidation = function()
        local inputText = spellInput:GetText()
        local spellID = tonumber(inputText)
        local priority = priorityDropdown and priorityDropdown.getValue() or 0
        
        
        -- Update preview regardless of completion
        if spellID then
            local id, name, icon = AC:GetSpellData(spellID)
            if id and name and name ~= "Unknown Spell" then
                previewIcon:SetTexture(icon)
                previewIcon:Show()
                previewText:SetText(name)
                previewText:SetTextColor(0.4, 1, 0.4, 1)
            else
                previewIcon:Hide()
                previewText:SetText("Unknown spell ID")
                previewText:SetTextColor(1, 0.4, 0.4, 1)
                return false
            end
        else
            previewIcon:Hide()
            previewText:SetText("Enter spell ID")
            previewText:SetTextColor(GetColor("TEXT_MUTED")[1], GetColor("TEXT_MUTED")[2], GetColor("TEXT_MUTED")[3], 1)
        end
        
        -- CONDITIONAL AUTO-ADD: Only auto-add if paste was detected
        if spellID and priority and priority > 0 then
            if inputTracking.wasPasteOperation then
                AutoAddSpell()
                return true
            else
                -- Show visual feedback that Enter is needed
                previewText:SetText(previewText:GetText() .. " - Press Enter to add")
                previewText:SetTextColor(1, 1, 0.4, 1) -- Yellow color to indicate action needed
                return false
            end
        end
        
        return false
    end
    
    -- Handle Enter key for spell input (auto-add if ready)
    spellInput:SetScript("OnEnterPressed", function()
        local inputText = spellInput:GetText()
        local spellID = tonumber(inputText)
        local priority = priorityDropdown.getValue()
        
        if spellID and priority and priority > 0 then
            AutoAddSpell()
        end
    end)
    
    -- No checkbox needed - fully automated!
    
    -- Run initial validation to set proper state
    C_Timer.After(0.1, function()
        if UpdateValidation then
            UpdateValidation()
        end
    end)
    
    -- Store reference to the input for external access
    container.input = spellInput
    
    return container
end

-- Create how-to section with professional orange matte texture
local function CreateHowToSection(parent)
    local howToSection = CreateFrame("Frame", nil, parent)
    howToSection:SetPoint("TOPLEFT", 8, -378)
    howToSection:SetPoint("TOPRIGHT", -8, -378)
    howToSection:SetHeight(150) -- INCREASED height for more content
    
    -- Professional orange matte texture background
    local orangeBg = howToSection:CreateTexture(nil, "BACKGROUND", nil, 1)
    orangeBg:SetAllPoints()
    orangeBg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\bar-orange-matte.tga")
    orangeBg:SetTexCoord(0.002, 0.998, 0.002, 0.998)
    
    -- Subtle border for definition
    local border = AC:CreateFlatTexture(howToSection, "OVERLAY", 1, {1, 0.7, 0.2, 0.3})
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    
    -- Title
    local title = AC:CreateStyledText(howToSection, "How to Use Class Pack Editor", 13, {0, 0, 0, 1}, "OVERLAY", "")
    title:SetPoint("TOPLEFT", 16, -8)
    
    -- Multi-line text area
    local textContainer = CreateFrame("Frame", nil, howToSection)
    textContainer:SetPoint("TOPLEFT", 16, -28)
    textContainer:SetPoint("BOTTOMRIGHT", -16, 8)
    
    local instructionText = AC:CreateStyledText(textContainer, "", 11, {0, 0, 0, 1}, "OVERLAY", "")
    instructionText:SetPoint("TOPLEFT", 0, 0)
    instructionText:SetPoint("BOTTOMRIGHT", 0, 0)
    instructionText:SetJustifyH("LEFT")
    instructionText:SetJustifyV("TOP")
    instructionText:SetWordWrap(true)
    
    -- Default text
    local defaultText = "Welcome to the Class Pack Editor! This powerful tool lets you customize which spells ArenaCore tracks for each class.\n\nClick any priority dropdown to set spell importance: WATCH FOR THIS (highest priority), Really Care, Kinda Care, or Don't Care (lowest priority). Spells are scanned in priority order during arena matches.\n\nAdd new spells by entering their Spell ID and selecting a priority level. You can find Spell IDs on Wowhead OR use the built in tooltip addon Arena Core offers in the Extension Pack window from the main header button..\n\nTip: Each class can have up to 3 spells per category, and the system automatically detects enemy class during arena prep!"
    
    instructionText:SetText(defaultText)
    
    howToSection.textElement = instructionText
    howToSection.setText = function(text) instructionText:SetText(text) end
    howToSection.getText = function() return instructionText:GetText() end
    
    return howToSection
end

local function WipeChildren(frame)
    if not frame then return end
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(UIParent)
        child:ClearAllPoints()
    end
end

-- =============================================================
-- Modified PopulateClass function to handle profile view
-- Replace your existing PopulateClass function
-- =============================================================

-- Function to save all spells for the current class
local function SaveAllSpells(className)
    if not className then 
        print("|cff8B45FFArenaCore:|r Error: No class selected for saving")
        return 
    end
    
    -- Get current spec
    local currentSpec = Editor.currentSpec or 1
    
    
    -- Use the new centralized save function
    if AC.SaveClassPacksToDatabase then
        AC:SaveClassPacksToDatabase()
        
        local specName = AC.CLASS_SPECS[className] and AC.CLASS_SPECS[className][currentSpec] and AC.CLASS_SPECS[className][currentSpec].name or "Spec " .. currentSpec
        print("|cff8B45FFArenaCore:|r All spells saved successfully for " .. className .. " (" .. specName .. ")!")
        
        -- Play custom ArenaCore save sound for feedback
        PlaySoundFile("Interface/AddOns/ArenaCore/Media/Sounds/InfoSaved.mp3", "Master")
        
        -- Refresh any active auras
        if AC.Auras and AC.Auras.RefreshAll then
            AC.Auras:RefreshAll()
        end
    else
        print("|cff8B45FFArenaCore:|r Error: Save function not available")
    end
end

-- Make PopulateClass available through the Editor table
function Editor.PopulateClass(className)
    
    if not Editor.Frame then 
        return 
    end
    
    -- Ensure AC.ClassPacks exists and initialize class data if needed (now spec-aware)
    if not AC.ClassPacks then
        AC.ClassPacks = {}
    end
    if not AC.ClassPacks[className] then
        AC.ClassPacks[className] = {}
    end
    
    -- Ensure current spec exists
    local currentSpec = Editor.currentSpec or 1
    if not AC.ClassPacks[className][currentSpec] then
        AC.ClassPacks[className][currentSpec] = {[1] = {}, [2] = {}, [3] = {}}
    end
    
    Editor.currentClass = className
    
    -- Create or update spec dropdown
    if Editor.Frame.specDropdown then
        Editor.Frame.specDropdown:Hide()
        Editor.Frame.specDropdown:SetParent(nil)
    end
    
    Editor.Frame.specDropdown = CreateSpecDropdown(Editor.Frame.specHeader, className, Editor.currentSpec, function(newSpec)
        Editor.currentSpec = newSpec
        Editor.PopulateClass(className) -- Refresh with new spec
    end)
    
    if Editor.Frame.specDropdown then
        Editor.Frame.specDropdown:SetPoint("LEFT", Editor.Frame.specHeader, "LEFT", 120, 0)
        Editor.Frame.specDropdown:Show()
    end
    
    -- Update title to include spec information
    local specName = AC.CLASS_SPECS[className] and AC.CLASS_SPECS[className][currentSpec] and AC.CLASS_SPECS[className][currentSpec].name or "Spec " .. currentSpec
    Editor.Frame.Title:SetText("Class Pack Editor - " .. className .. " (" .. specName .. ")")
    
    -- CRITICAL FIX: Apply subtle class-specific header color theming
    if Editor.Frame.HeaderBg and RAID_CLASS_COLORS[className] then
        local classColor = RAID_CLASS_COLORS[className]
        -- Mix class color with dark background for subtle theming
        local r = (classColor.r * 0.3) + (GetColor("HEADER_BG")[1] * 0.7)
        local g = (classColor.g * 0.3) + (GetColor("HEADER_BG")[2] * 0.7)
        local b = (classColor.b * 0.3) + (GetColor("HEADER_BG")[3] * 0.7)
        Editor.Frame.HeaderBg:SetTexture(nil) -- Clear any texture
        Editor.Frame.HeaderBg:SetColorTexture(r, g, b, 1.0)
        Editor.Frame.HeaderBg:SetAlpha(1.0)
    end
    
    -- Show normal class interface (hide profile section if visible)
    if Editor.Frame.ProfileSection then
        Editor.Frame.ProfileSection:Hide()
    end
    
    -- CRITICAL FIX: Show spec header when switching back to class view
    if Editor.Frame.specHeader then
        Editor.Frame.specHeader:Show()
    end
    
    -- Ensure Editor is created
    if not Editor.Frame.Groups then
        print("|cff8B45FFArenaCore:|r Editor groups not found, recreating...")
        Editor:Create()
    end
    
    -- Show normal spell groups
    for slot = 1, 3 do
        local group = Editor.Frame.Groups[slot]
        if group then
            group:Show()
        end
    end
    
    -- Always show how-to section
    if not Editor.Frame.HowToSection then
        -- Create the how-to section if it doesn't exist
        Editor.Frame.HowToSection = CreateHowToSection(Editor.Frame.mainContent)
    end
    Editor.Frame.HowToSection:Show()
    
    -- Continue with normal class population
    local classData = AC.ClassPacks[className]

    for slot = 1, 3 do
        local group = Editor.Frame.Groups[slot]
        if not group then
            print("|cff8B45FFArenaCore:|r Group " .. slot .. " not found for " .. className)
            return
        end
        WipeChildren(group.content)
        
        local sortedSpells = AC:GetSortedSpellsForSlot(className, slot, currentSpec)
        local yOffset = -8
        
        for i, spellData in ipairs(sortedSpells) do
            local row = CreateSpellRow(group.content, spellData.spellID, spellData.priority, className, slot, i, currentSpec)
            if row then
                row:SetPoint("TOPLEFT", 4, yOffset)
                yOffset = yOffset - 48
            end
        end
        
        if #sortedSpells > 0 then
            local separator = AC:CreateFlatTexture(group.content, "OVERLAY", 1, GetColor("BORDER_LIGHT"))
            separator:SetPoint("LEFT", 4, 0)
            separator:SetPoint("RIGHT", -4, 0)
            separator:SetPoint("TOP", 0, yOffset - 4)
            separator:SetHeight(1)
            yOffset = yOffset - 12
        end
        
        if #sortedSpells < 3 then
            local addInterface = CreateAddSpellInterface(group.content, className, slot, currentSpec)
            addInterface:SetPoint("TOPLEFT", 4, yOffset)
            -- Debug: Ensure interface is created and visible
            if addInterface then
                addInterface:Show()
            else
            end
        else
        end
        
        local spellCount = #sortedSpells
        local countText = group.countLabel or AC:CreateStyledText(group, "", 10, GetColor("TEXT_MUTED"), "OVERLAY", "")
        countText:SetText("(" .. spellCount .. "/3)")
        countText:SetPoint("TOPRIGHT", -8, -6)
        group.countLabel = countText
    end
    
end

-- PopulateClass is now accessed via Editor.PopulateClass

function Editor:Create()
    -- HIDDEN: Editor creation happens silently for cleaner user experience
    -- print("[EDITOR DEBUG] Create called")
    
    -- FORCE RECREATE: Destroy old frame to apply new styling
    if Editor.Frame then
        -- HIDDEN: Frame destruction happens silently
        -- print("[EDITOR DEBUG] Destroying old frame")
        Editor.Frame:Hide()
        Editor.Frame = nil
    end
    
    -- HIDDEN: Frame creation happens silently
    -- print("[EDITOR DEBUG] Creating new frame")
    local f = CreateFrame("Frame", "ArenaCore_ClassPackEditor", UIParent)
    f:SetSize(1150, 770) -- INCREASED height to accommodate taller how-to section
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")  -- CRITICAL: Use DIALOG strata to prevent bleed-through from lower UI elements
    
    -- CRITICAL: Mark as addon frame for theme system
    f.__isArenaCore = true
    
    -- Enable resizable UI with scale drag grips
    if AC.UIFeatures and AC.UIFeatures.EnableResizableUI then
        AC.UIFeatures:EnableResizableUI(f, "classPackEditorScale")
    end
    
    AC:AddWindowEdge(f, 1, 0)
    AC:CreateFlatTexture(f, "BACKGROUND", -1, GetColor("BACKGROUND", {0.1, 0.1, 0.1, 1})):SetAllPoints()
    
    -- Header
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(40)
    
    -- CRITICAL FIX: Store header background reference for later modification
    f.HeaderBg = AC:CreateFlatTexture(header, "BACKGROUND", 1, GetColor("HEADER_BG"))
    f.Header = header -- Also store header reference
    
    -- Purple accent line (matching Dispel Configuration window)
    local accent = AC:CreateFlatTexture(header, "OVERLAY", 3, AC.COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(2)
    
    f.Title = AC:CreateStyledText(header, "Class Pack Editor", 14, GetColor("TEXT"), "OVERLAY", "")
    f.Title:SetPoint("LEFT", 12, 0)
    
    local closeBtn = AC:CreateTexturedButton(header, 32, 32, "", "button-close")
    closeBtn:SetPoint("RIGHT", -6, 0)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    AC:CreateStyledText(closeBtn, "×", 16, GetColor("TEXT"), "OVERLAY", ""):SetPoint("CENTER")

    -- Sidebar
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetPoint("TOPLEFT", 1, -41)
    sidebar:SetPoint("BOTTOMLEFT", 1, 1)
    sidebar:SetWidth(180)
    AC:CreateFlatTexture(sidebar, "BACKGROUND", 1, GetColor("PANEL_BG"))
    
    local sidebarBorder = AC:CreateFlatTexture(sidebar, "OVERLAY", 1, GetColor("BORDER_LIGHT"))
sidebarBorder:SetPoint("TOPRIGHT", 0, 0)
sidebarBorder:SetPoint("BOTTOMRIGHT", 0, 0)
sidebarBorder:SetWidth(1)

-- Class buttons
-- =============================================================
-- FIX 2: Class Button Hover States
-- Replace the class button creation section in Editor:Create() function
-- Find the section around line 600+ where class buttons are created
-- =============================================================

-- Class buttons with FIXED hover states
-- =============================================================
-- CORRECTED CLASS BUTTON HOVER STATES - PROPER READABILITY
-- Replace the class button creation section in your file
-- =============================================================

-- Class buttons with PROFILE button added after Evoker (ALPHABETICAL ORDER)
local classList = {"DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER", "HUNTER", "MAGE", "MONK", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR"}
local y = -8
Editor.ClassButtons = {}

for i, className in ipairs(classList) do
    local color = RAID_CLASS_COLORS[className]
    local displayName = className:sub(1,1):upper() .. className:sub(2):lower()
    local btn = AC:CreateEnhancedButton(sidebar, 164, 28, displayName, "", {0, 0, 0, 0}, {0, 0, 0, 0})
    btn:SetPoint("TOP", 0, y)

    -- VIBRANT CLASS-SPECIFIC GRADIENT BACKGROUND
    local gradientBg = btn:CreateTexture(nil, "ARTWORK")
    gradientBg:SetAllPoints()
    gradientBg:SetTexture(classGradients[className])
    gradientBg:SetTexCoord(0, 1, 0, 1)
    gradientBg:SetAlpha(0.8) -- Start at good readable level

    btn.text:SetTextColor(1, 1, 1) -- White text for readability
    btn.gradientBg = gradientBg
    btn.className = className
    btn.isActive = false

    Editor.ClassButtons[className] = btn

    -- CORRECTED: Proper hover states for readability
    btn:SetScript("OnEnter", function(self)
        if not self.isActive then
            self.gradientBg:SetAlpha(0.9)
        end
    end)

    btn:SetScript("OnLeave", function(self)
        if not self.isActive then
            self.gradientBg:SetAlpha(0.8)
        else
            self.gradientBg:SetAlpha(1.0)
        end
    end)

    btn:SetScript("OnClick", function(self)
        -- Update all button states
        for cName, cBtn in pairs(Editor.ClassButtons) do
            if cName == className then
                cBtn.gradientBg:SetAlpha(1.0)
                cBtn.isActive = true
            else
                cBtn.gradientBg:SetAlpha(0.6)
                cBtn.isActive = false
            end
        end
        
        -- Deactivate profile button when clicking class
        if Editor.ProfileButton then
            Editor.ProfileButton.isActive = false
            Editor.ProfileButton:SetAlpha(0.6)
        end
        
        Editor.PopulateClass(className)
    end)

    y = y - 32
end

-- ADD PROFILE BUTTON after Evoker (with spacing)
y = y - 8 -- Extra spacing

local profileBtn = AC:CreateEnhancedButton(sidebar, 164, 28, "Profiles", "", {0, 0, 0, 0}, {0, 0, 0, 0})
profileBtn:SetPoint("TOP", 0, y)

-- Profile button styling (different from class buttons)
local profileBg = AC:CreateFlatTexture(profileBtn, "ARTWORK", 1, GetColor("PRIMARY"))
profileBg:SetAllPoints()
profileBg:SetAlpha(0.8)

profileBtn.text:SetTextColor(1, 1, 1)
profileBtn.isActive = false
profileBtn:SetAlpha(0.8)

Editor.ProfileButton = profileBtn

-- Profile button hover states
profileBtn:SetScript("OnEnter", function(self)
    if not self.isActive then
        self:SetAlpha(0.9)
    end
end)

profileBtn:SetScript("OnLeave", function(self)
    if not self.isActive then
        self:SetAlpha(0.8)
    else
        self:SetAlpha(1.0)
    end
end)

profileBtn:SetScript("OnClick", function(self)
    -- Deactivate all class buttons
    for cName, cBtn in pairs(Editor.ClassButtons) do
        cBtn.gradientBg:SetAlpha(0.6)
        cBtn.isActive = false
    end
    
    -- Activate profile button
    self:SetAlpha(1.0)
    self.isActive = true
    
    -- Show profile interface instead of class data
    ShowProfileInterface()
end)

-- Function to show profile interface
function ShowProfileInterface()
    Editor.currentClass = nil
    Editor.currentSpec = nil
    
    -- CRITICAL FIX: Force title update and clear any class-specific styling
    if Editor.Frame and Editor.Frame.Title then
        Editor.Frame.Title:SetText("Class Pack Editor - Profile Manager")
        -- Clear any class gradient background that might be lingering
        if Editor.Frame.HeaderBg then
            Editor.Frame.HeaderBg:SetTexture(nil) -- Clear texture first
            local headerColor = GetColor("HEADER_BG")
            Editor.Frame.HeaderBg:SetColorTexture(headerColor[1], headerColor[2], headerColor[3], headerColor[4])
            Editor.Frame.HeaderBg:SetAlpha(1.0) -- Reset alpha
            Editor.Frame.HeaderBg:SetTexCoord(0, 1, 0, 1) -- Reset texture coordinates
        end
    end
    
    -- CRITICAL FIX: Hide spec dropdown that's bleeding from previous class
    if Editor.Frame.specDropdown then
        Editor.Frame.specDropdown:Hide()
        Editor.Frame.specDropdown:SetParent(nil)
    end
    
    -- CRITICAL FIX: Hide spec header section completely
    if Editor.Frame.specHeader then
        Editor.Frame.specHeader:Hide()
    end
    
    -- Hide normal spell groups
    for slot = 1, 3 do
        local group = Editor.Frame.Groups[slot]
        group:Hide()
    end
    
    -- Hide how-to section
    if Editor.Frame.HowToSection then
        Editor.Frame.HowToSection:Hide()
    end
    
    -- Show profile management interface
    if not Editor.Frame.ProfileSection then
        Editor.Frame.ProfileSection = AC.CreateProfileSection(Editor.Frame.mainContent)
    end
    Editor.Frame.ProfileSection:Show()
end

-- Main content area

    -- Main content area
    local mainContent = CreateFrame("Frame", nil, f)
    f.mainContent = mainContent  -- Store reference for profile section
    mainContent:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
    mainContent:SetPoint("BOTTOMRIGHT", -10, 10)
    mainContent:SetFrameLevel(f:GetFrameLevel() + 1)  -- Ensure proper layering
    
    AC:CreateFlatTexture(mainContent, "BACKGROUND", 1, GetColor("INPUT_DARK")):SetAllPoints()

    -- Create spec selection header
    local specHeader = CreateFrame("Frame", nil, mainContent)
    specHeader:SetPoint("TOPLEFT", 8, -8)
    specHeader:SetPoint("TOPRIGHT", -8, -8)
    specHeader:SetHeight(32)
    
    local specLabel = AC:CreateStyledText(specHeader, "Specialization:", 12, GetColor("TEXT"), "OVERLAY", "")
    specLabel:SetPoint("LEFT", 4, 0)
    
    -- Spec dropdown will be created when a class is selected
    f.specDropdown = nil
    f.specHeader = specHeader

    f.Groups = {}
    local slotNames = {"[1] Burst Cooldowns", "[2] Defensives & Immunities", "[3] Control & Utility"}
    
    local columnWidth = 310
    local columnSpacing = 10
    
    for i = 1, 3 do
        local group = CreateFrame("Frame", nil, mainContent)
        group:SetPoint("TOPLEFT", (i-1) * (columnWidth + columnSpacing) + 8, -48) -- Moved down to account for spec header
        group:SetSize(columnWidth, 320) -- Reduced height to fit spec header
        AC:HairlineGroupBox(group)
        
        -- HIDDEN: Content box creation happens silently
        -- print("[EDITOR DEBUG] Creating content box " .. i .. " with MUCH lighter background")
        
        -- MUCH lighter background for content boxes (very noticeable difference)
        local contentBg = AC:CreateFlatTexture(group, "BACKGROUND", 0, {0.35, 0.35, 0.35, 1})
        contentBg:SetAllPoints()
        
        -- HIDDEN: Background application happens silently
        -- print("[EDITOR DEBUG] Content box " .. i .. " background applied - RGB(0.35, 0.35, 0.35)")
        
        local groupTitle = AC:CreateStyledText(group, slotNames[i], 12, GetColor("PRIMARY"), "OVERLAY", "")
        groupTitle:SetPoint("TOPLEFT", 8, -8)
        
        local content = CreateFrame("Frame", nil, group)
        content:SetPoint("TOPLEFT", 0, -26)
        content:SetPoint("BOTTOMRIGHT", 0, i == 1 and -30 or 0) -- Add space at bottom for Save button in first column
        group.content = content
        
        -- Add Save button to first column (Burst Cooldowns)
        if i == 1 then
            local saveBtn = AC:CreateEnhancedButton(group, 100, 22, "Save All", "", {0, 0, 0, 0}, {0, 0, 0, 0})
            saveBtn:SetPoint("BOTTOMLEFT", 4, 4)
            saveBtn:SetPoint("BOTTOMRIGHT", -4, 4)
            
            local saveBg = AC:CreateFlatTexture(saveBtn, "BACKGROUND", 1, GetColor("PRIMARY"))
            saveBg:SetAllPoints()
            saveBg:SetAlpha(0.8)
            
            saveBtn.text:SetTextColor(1, 1, 1)
            saveBtn:SetScript("OnClick", function()
                if Editor.currentClass then
                    SaveAllSpells(Editor.currentClass)
                end
            end)
            
            saveBtn:SetScript("OnEnter", function(self)
                saveBg:SetAlpha(1.0)
            end)
            
            saveBtn:SetScript("OnLeave", function(self)
                saveBg:SetAlpha(0.8)
            end)
            
            group.saveButton = saveBtn
        end
        
        f.Groups[i] = group
    end
    
    -- Create the how-to section
    f.HowToSection = CreateHowToSection(mainContent)
    
    
    Editor.Frame = f
end

-- Function to remove a spell from a class pack
function AC:RemoveSpellFromPack(className, slot, spellID)
    if not self.ClassPacks or not self.ClassPacks[className] or not self.ClassPacks[className][slot] then
        return false
    end
    
    local spellList = self.ClassPacks[className][slot]
    for i, spellData in ipairs(spellList) do
        if spellData[1] == spellID then
            table.remove(spellList, i)
            print("|cff8B45FFArenaCore:|r Removed spell " .. spellID .. " from " .. className .. " slot " .. slot)
            return true
        end
    end
    
    return false
end

-- Update the priority of a spell in a class pack
function AC:UpdateSpellPriority(className, slot, spellID, newPriority)
    if not self.ClassPacks or not self.ClassPacks[className] or not self.ClassPacks[className][slot] then
        return false
    end
    
    local spellList = self.ClassPacks[className][slot]
    for i, spellData in ipairs(spellList) do
        if spellData[1] == spellID then
            spellData[2] = newPriority
            print("|cff8B45FFArenaCore:|r Updated priority for spell " .. spellID .. " to " .. (AC.PRIORITY_LABELS[newPriority] or "Unknown"))
            return true
        end
    end
    
    return false
end

function AC:OpenClassPacksEditor()
    -- Load saved data from persistent storage
    if AC.DB and AC.DB.profile and AC.DB.profile.classPacks then
        AC.ClassPacks = AC.ClassPacks or {}
        for className, classData in pairs(AC.DB.profile.classPacks) do
            -- FIXED: Only process actual class names, skip other data like "enabled"
            if type(classData) == "table" and RAID_CLASS_COLORS[className] then
                AC.ClassPacks[className] = AC.ClassPacks[className] or {}
                for slot = 1, 3 do
                    if classData[slot] then
                        AC.ClassPacks[className][slot] = CopyTable(classData[slot])
                    end
                end
            end
        end
    end
    
    if not Editor.Frame then Editor:Create() end
    
    if AC.configFrame then
        Editor.Frame:SetFrameLevel(AC.configFrame:GetFrameLevel() + 5)
    end
    
    Editor.Frame:Show()
    Editor.Frame:Raise()
    
    if Editor.firstLoad == nil then
        if Editor.ClassButtons and Editor.ClassButtons["DEATHKNIGHT"] then
            Editor.ClassButtons["DEATHKNIGHT"]:GetScript("OnClick")()
        end
        Editor.firstLoad = false
    end
end

-- ENHANCED Save function that properly persists to SavedVariables
local function SaveAllSpells(className)
    if not className or not AC.ClassPacks then return end
    
    -- Initialize class data if it doesn't exist
    AC.ClassPacks[className] = AC.ClassPacks[className] or {}
    
    -- Create a temporary table to store ONLY the spells currently in the UI
    local newSpells = {}
    
    -- Save spells for each slot (1 = Burst, 2 = Defensives, 3 = Control & Utility)
    for slot = 1, 3 do
        newSpells[slot] = {}
        local group = Editor.Frame and Editor.Frame.Groups and Editor.Frame.Groups[slot]
        if group and group.content then
            -- Get all children of the content frame
            local children = {group.content:GetChildren()}
            
            for _, child in ipairs(children) do
                -- Check if this is a spell row (has spellID and priority)
                if child.spellID and child.priority then
                    table.insert(newSpells[slot], {child.spellID, child.priority})
                end
            end
        end
        
        -- Debug output
        print(string.format("|cff8B45FFArenaCore:|r Saving %d spells in slot %d", #newSpells[slot], slot))
    end
    
    -- Update the actual data with ONLY what's currently in the UI
    for slot = 1, 3 do
        AC.ClassPacks[className][slot] = CopyTable(newSpells[slot])
    end
    
    -- CRITICAL: Save to persistent database AND SavedVariables
    AC:EnsureDB() -- Use the same DB system as arena frames
    AC.DB.profile.classPacks = AC.DB.profile.classPacks or {}
    AC.DB.profile.classPacks[className] = AC.DB.profile.classPacks[className] or {}
    
    -- Copy the data to the persistent storage
    for slot = 1, 3 do
        AC.DB.profile.classPacks[className][slot] = CopyTable(newSpells[slot])
    end
    
    -- FORCE SavedVariables update (direct database save)
    _G.ArenaCoreDB = AC.DB
    
    -- Show feedback
    print("|cff8B45FFArenaCore:|r Spells saved successfully for " .. className .. " (Total: " .. 
          (#newSpells[1] + #newSpells[2] + #newSpells[3]) .. " spells)")
    
    -- Refresh any active auras
    if AC.Auras and AC.Auras.RefreshAll then
        AC.Auras:RefreshAll()
    end
    
    -- Refresh the UI to show updated state
    if Editor and Editor.PopulateClass then
        Editor.PopulateClass(className)
    end
    
    -- Play custom ArenaCore save sound for feedback
    PlaySoundFile("Interface/AddOns/ArenaCore/Media/Sounds/InfoSaved.mp3", "Master")
end