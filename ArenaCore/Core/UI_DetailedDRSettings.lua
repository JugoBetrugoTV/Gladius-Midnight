-- ============================================================================
-- File: ArenaCore/Core/UI_DetailedDRSettings.lua
-- Purpose: Detailed Diminishing Returns Settings Window
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end
-- ============================================================================
-- Core/UI_DetailedDRSettings.lua
-- REPLACEMENT for all spell data tables
-- ============================================================================
-- This structure provides a single source of truth for DR categories.

-- The display names for our categories (core 7 categories only).
local DR_CATEGORIES = {
    ["stun"] = "Stuns",
    ["silence"] = "Silences", 
    ["root"] = "Roots",
    ["incapacitate"] = "Incapacitates",
    ["disorient"] = "Disorients",
    ["knockback"] = "Knockbacks",
    ["disarm"] = "Disarms",
}

-- A single, comprehensive list mapping Spell IDs to their DR category.
-- This prevents duplicates and makes the system easy to update.
local DR_SPELL_LIST = {
    -- Stuns
    [108194] = "stun", [91800] = "stun", [853] = "stun", [408] = "stun", [1833] = "stun", [30283] = "stun", [89766] = "stun", [46968] = "stun", [179057] = "stun", [211881] = "stun", [203123] = "stun", [5211] = "stun", [117526] = "stun", [24394] = "stun", [64044] = "stun", [118905] = "stun", [305485] = "stun", [132169] = "stun", [20549] = "stun", [287712] = "stun",
    
    -- Disorients
    [8122] = "disorient", [31661] = "disorient", [2094] = "disorient", [5246] = "disorient", [207167] = "disorient", [105421] = "disorient",
    
    -- Incapacitates
    [118] = "incapacitate", [20066] = "incapacitate", [6770] = "incapacitate", [3355] = "incapacitate", [51514] = "incapacitate", [2637] = "incapacitate", [99] = "incapacitate", [213691] = "incapacitate", [82691] = "incapacitate", [115078] = "incapacitate", [1776] = "incapacitate", [710] = "incapacitate", [6789] = "incapacitate", [107079] = "incapacitate", [217832] = "incapacitate",
    
    -- Silences
    [15487] = "silence", [1330] = "silence", [47476] = "silence", [204490] = "silence", [31935] = "silence",
    
    -- Roots
    [339] = "root", [122] = "root", [64695] = "root", [102359] = "root", [116706] = "root",
    
    -- Disarms
    [676] = "disarm", [236077] = "disarm",
    

    -- Knockbacks
    [51490] = "knockback", [61391] = "knockback", [186387] = "knockback",
}

-- A default representative spell for testing each category (core 7 categories only).
local DEFAULT_TEST_SPELLS = {
    ["stun"] = 853,          -- Hammer of Justice
    ["disorient"] = 8122,    -- Psychic Scream
    ["incapacitate"] = 118,  -- Polymorph
    ["silence"] = 15487,     -- Silence
    ["root"] = 339,          -- Entangling Roots
    ["disarm"] = 207777,     -- Dismantle (Rogue)
    ["knockback"] = 51490,   -- Thunderstorm
}-- ============================================================================
-- Core/UI_DetailedDRSettings.lua
-- NEW HELPER FUNCTION
-- ============================================================================
-- ============================================================================
-- Core/UI_DetailedDRSettings.lua
-- NEW HELPER FUNCTION TO GET THE CORRECT SETTINGS PROFILE
-- ============================================================================
function AC:GetActiveDRSettingsDB()
    -- CRITICAL FIX: Return the REAL saved variables database (AC.DB.profile)
    -- NOT a temporary table (AC.db) that gets wiped on reload
    -- This ensures dropdown selections persist and work in live arena
    AC.DB = AC.DB or {}
    AC.DB.profile = AC.DB.profile or {}
    AC.DB.profile.diminishingReturns = AC.DB.profile.diminishingReturns or {}
    AC.DB.profile.diminishingReturns.iconSettings = AC.DB.profile.diminishingReturns.iconSettings or {}
    AC.DB.profile.diminishingReturns.customSpells = AC.DB.profile.diminishingReturns.customSpells or {}
    AC.DB.profile.diminishingReturns.customSpellsList = AC.DB.profile.diminishingReturns.customSpellsList or {}
    AC.DB.profile.diminishingReturns.categories = AC.DB.profile.diminishingReturns.categories or {}
    
    return AC.DB.profile.diminishingReturns
end
-- This function builds the options for a DR dropdown.
function AC:BuildDRDropdownOptions(category)
    local optionsArray = {}
    local valueToKey = {} -- Maps the display text back to a key (like a spell ID or "dynamic")
    local customSpells = {} -- Track which options are custom (for X button display)

    -- Add default options first
    local dynamicDisplay = "|TInterface\\AddOns\\ArenaCore\\Media\\Buttons\\dynamicicon.tga:16:16|t Dynamic"
    table.insert(optionsArray, dynamicDisplay)
    valueToKey[dynamicDisplay] = "dynamic"
    customSpells[dynamicDisplay] = false -- Dynamic is never removable

    -- Find all spells for the given category from our master list
    for spellID, cat in pairs(DR_SPELL_LIST) do
        if cat == category then
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo and spellInfo.name and spellInfo.iconID then
                local display = "|T" .. spellInfo.iconID .. ":16:16|t " .. spellInfo.name
                table.insert(optionsArray, display)
                valueToKey[display] = tostring(spellID)
                customSpells[display] = false -- Default spells not removable
            end
        end
    end
    
    -- Add custom spells for this category from database
    local activeDB = AC:GetActiveDRSettingsDB()
    if activeDB.customSpellsList and activeDB.customSpellsList[category] then
        for _, spellID in ipairs(activeDB.customSpellsList[category]) do
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo and spellInfo.name and spellInfo.iconID then
                local display = "|T" .. spellInfo.iconID .. ":16:16|t " .. spellInfo.name .. " (Custom)"
                table.insert(optionsArray, display)
                valueToKey[display] = tostring(spellID)
                customSpells[display] = true -- Custom spells ARE removable
            end
        end
    end

    return optionsArray, valueToKey, customSpells
end


-- Global variables
local detailedDRFrame = nil
-- Removed currentTab variable since we no longer use tabs
local currentCategory = nil

-- Track all dropdown menus in the DR settings window for cleanup
local drDropdownMenus = {}

-- Create the main detailed DR settings window
function AC:ShowDetailedDRSettings()
    if detailedDRFrame and detailedDRFrame:IsShown() then
        detailedDRFrame:Hide()
        return
    end
    
    -- Clear dropdown tracking table when creating new window
    drDropdownMenus = {}
    
    -- Initialize database structure if it doesn't exist
    AC.DB = AC.DB or {}
    AC.DB.profile = AC.DB.profile or {}
    AC.DB.profile.diminishingReturns = AC.DB.profile.diminishingReturns or {}
    
    -- Initialize DR categories if needed
    if not AC.DB.profile.diminishingReturns.initialized then
        AC:InitializeDRCategories()
        AC.DB.profile.diminishingReturns.initialized = true
    end
    -- Create main settings frame with ArenaCore styling
    detailedDRFrame = CreateFrame("Frame", "ArenaCoreDRSettings", UIParent)
    detailedDRFrame:SetSize(700, 500)
    detailedDRFrame:SetPoint("CENTER")
    detailedDRFrame:SetFrameStrata("DIALOG")
    detailedDRFrame:SetToplevel(true)
    detailedDRFrame:EnableMouse(true)
    detailedDRFrame:SetMovable(true)
    detailedDRFrame:SetClampedToScreen(true)
    detailedDRFrame:RegisterForDrag("LeftButton")
    detailedDRFrame:SetScript("OnDragStart", detailedDRFrame.StartMoving)
    detailedDRFrame:SetScript("OnDragStop", detailedDRFrame.StopMovingOrSizing)
    
    -- Enable resizable UI with scale drag grips
    if AC.UIFeatures and AC.UIFeatures.EnableResizableUI then
        AC.UIFeatures:EnableResizableUI(detailedDRFrame, "drSettingsScale")
    end
    
    -- Background
    local bg = AC:CreateFlatTexture(detailedDRFrame, "BACKGROUND", 0, AC.COLORS.BACKGROUND)
    bg:SetAllPoints()
    
    -- Border
    local border = AC:CreateFlatTexture(detailedDRFrame, "BORDER", 0, AC.COLORS.BORDER)
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    
-- Header with hairline styling matching MoreFeatures
    local header = CreateFrame("Frame", nil, detailedDRFrame)
    header:SetPoint("TOPLEFT", 2, -2)
    header:SetPoint("TOPRIGHT", -2, -2)
    header:SetHeight(50)
    
    local headerBg = AC:CreateFlatTexture(header, "BACKGROUND", 1, AC.COLORS.HEADER_BG, 1)
    headerBg:SetAllPoints()
    
    -- Purple accent line like MoreFeatures
    local accent = AC:CreateFlatTexture(header, "OVERLAY", 3, AC.COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(3)
    
    -- Hairline borders matching MoreFeatures exactly
    local hbLight = AC:CreateFlatTexture(header, "OVERLAY", 2, AC.COLORS.BORDER_LIGHT, 0.8)
    hbLight:SetPoint("BOTTOMLEFT", 0, 0)
    hbLight:SetPoint("BOTTOMRIGHT", 0, 0)
    hbLight:SetHeight(1)
    
    local hbDark = AC:CreateFlatTexture(header, "OVERLAY", 1, AC.COLORS.BORDER, 1)
    hbDark:SetPoint("BOTTOMLEFT", 0, 1)
    hbDark:SetPoint("BOTTOMRIGHT", 0, 1)
    hbDark:SetHeight(1)
    
    -- Title
    local title = AC:CreateStyledText(header, "Detailed DR Settings", 16, AC.COLORS.TEXT, "OVERLAY", "")
    title:SetPoint("LEFT", header, "LEFT", 15, 0)
-- Close button using ArenaCore textured button system
local closeButton = AC:CreateTexturedButton(header, 24, 24, "X", "button-hide")
    closeButton:SetPoint("RIGHT", header, "RIGHT", -3, 0)
    closeButton:SetScript("OnClick", function()
        -- Close all dropdowns before hiding the window
        AC:CloseAllDRDropdowns()
        detailedDRFrame:Hide()
    end)
    
    -- Content area
    local contentArea = CreateFrame("Frame", nil, detailedDRFrame)
    contentArea:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 10, -10)
    contentArea:SetPoint("BOTTOMRIGHT", -10, 10)
    detailedDRFrame.contentArea = contentArea
    
-- Create categories content directly (no tabs needed)
    AC:CreateCategoriesTab(detailedDRFrame)
    
    -- Default category on open: last selected if valid, otherwise Incapacitates
    local defaultCategory = "incapacitate"
    if AC.DB and AC.DB.profile and AC.DB.profile.diminishingReturns then
        local savedCat = AC.DB.profile.diminishingReturns.lastSelectedCategory
        if savedCat and DR_CATEGORIES[savedCat] then
            defaultCategory = savedCat
        end
    end
    currentCategory = defaultCategory
    if detailedDRFrame.categoriesContent and detailedDRFrame.categoriesContent.categoryScrollChild then
        AC:UpdateCategorySelection(detailedDRFrame.categoriesContent.categoryScrollChild)
    end
    AC:RefreshCategorySettings()
    
    -- Show the frame
    detailedDRFrame:Show()
end


-- Create Categories tab content
function AC:CreateCategoriesTab(parent)
    local categoriesContent = CreateFrame("Frame", nil, parent.contentArea)
    categoriesContent:SetPoint("TOPLEFT", parent.contentArea, "TOPLEFT", 0, 0)
    categoriesContent:SetPoint("BOTTOMRIGHT", parent.contentArea, "BOTTOMRIGHT", 0, 0)
    
    -- Class/Spec controls at the top
    self:CreateClassSpecControls(categoriesContent)
    
    -- Category list on the left
    self:CreateCategoryList(categoriesContent)
    
    -- Category settings on the right
    self:CreateCategorySettings(categoriesContent)
    
    parent.categoriesContent = categoriesContent
    categoriesContent:Show() -- Show by default since Categories is the default tab
end

-- Create class/spec controls for categories tab
function AC:CreateClassSpecControls(parent)
    local classSpecFrame = CreateFrame("Frame", nil, parent)
    classSpecFrame:SetPoint("TOPLEFT", 0, 0)
    classSpecFrame:SetPoint("TOPRIGHT", 0, 0)
    classSpecFrame:SetHeight(60)
    
    AC:HairlineGroupBox(classSpecFrame)
    
-- Class/Spec Enable checkbox with proper database handling and initial value
local enableCheckbox = AC:CreateFlatCheckbox(classSpecFrame, 20, false, function(value)
    -- Ensure database structure exists
    AC.DB = AC.DB or {}
    AC.DB.profile = AC.DB.profile or {}
    AC.DB.profile.diminishingReturns = AC.DB.profile.diminishingReturns or {}
    AC.DB.profile.diminishingReturns.classSpecEnabled = value
    
    -- Force save to disk immediately
    if AC.SaveDatabase then
        AC:SaveDatabase()
    end
    
    AC:RefreshDetailedDRWindow()
end)
enableCheckbox:SetPoint("TOPLEFT", 10, -10)

-- Set initial value from saved data
local savedValue = AC.DB.profile.diminishingReturns.classSpecEnabled or false
enableCheckbox:SetChecked(savedValue)
    enableCheckbox:SetPoint("TOPLEFT", 10, -10)
    
    local enableLabel = AC:CreateStyledText(classSpecFrame, "Enable Class/Spec", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    enableLabel:SetPoint("LEFT", enableCheckbox, "RIGHT", 8, 0)
    
    -- COMING SOON indicator
    local comingSoonLabel = AC:CreateStyledText(classSpecFrame, "<-------- THIS FEATURE IS COMING SOON™", 12, {1, 0.8, 0, 1}, "OVERLAY", "")
    comingSoonLabel:SetPoint("LEFT", enableLabel, "RIGHT", 10, 0)
    
   -- Class/Spec dropdown with proper alphabetical grouping
    local classSpecOptions = {}
    local classSpecArray = {}
    
    -- Get all classes and sort them alphabetically
    local classes = {}
    for i = 1, GetNumClasses() do
        local className = GetClassInfo(i)
        if className then
            table.insert(classes, {id = i, name = className})
        end
    end
    
    -- Sort classes alphabetically
    table.sort(classes, function(a, b) return a.name < b.name end)
    
    -- Build the dropdown options in proper order
    for _, classData in ipairs(classes) do
        local className = classData.name
        local classID = classData.id
        
        -- Get all specs for this class
        local specs = {}
        for j = 1, GetNumSpecializationsForClassID(classID) do
            local _, specName, _, icon = GetSpecializationInfoForClassID(classID, j)
            if specName then
                table.insert(specs, {name = specName, icon = icon})
            end
        end
        
        -- Sort specs alphabetically within each class
        table.sort(specs, function(a, b) return a.name < b.name end)
        
        -- Add each spec to the arrays
        for _, specData in ipairs(specs) do
            local key = className .. "-" .. specData.name
            local displayText = "|T" .. specData.icon .. ":16:16|t " .. className .. " - " .. specData.name
            classSpecOptions[key] = displayText
            table.insert(classSpecArray, displayText)
        end
    end
    
    
    local classSpecDropdown = AC:CreateFlatDropdown(classSpecFrame, 300, 24, classSpecArray, classSpecArray[1] or "", function(value)
        -- Find the key that corresponds to the selected display text
        local selectedKey = nil
        for key, displayText in pairs(classSpecOptions) do
            if displayText == value then
                selectedKey = key
                break
            end
        end
        
        if selectedKey then
            AC.DB.profile.diminishingReturns.classSpecSelection = selectedKey
            AC:RefreshDetailedDRWindow()
        else
        end
    end)
    classSpecDropdown:SetPoint("TOPLEFT", 10, -35)
-- Fix z-order for class/spec dropdown to appear above other dropdowns
classSpecDropdown:SetFrameStrata("FULLSCREEN_DIALOG")
classSpecDropdown:SetFrameLevel(2000)
    
    -- Register this dropdown for cleanup when switching categories
    table.insert(drDropdownMenus, classSpecDropdown)
    
    parent.classSpecFrame = classSpecFrame
    parent.enableCheckbox = enableCheckbox
    parent.classSpecDropdown = classSpecDropdown
end

function AC:CreateCategoryList(parent)
    local categoryFrame = CreateFrame("Frame", nil, parent)
    categoryFrame:SetPoint("TOPLEFT", parent.classSpecFrame, "BOTTOMLEFT", 0, -10)
    categoryFrame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    categoryFrame:SetWidth(200)
    
    AC:HairlineGroupBox(categoryFrame)
    AC:CreateStyledText(categoryFrame, "Categories", 13, AC.COLORS.PRIMARY, "OVERLAY", ""):SetPoint("TOPLEFT", 20, -18)
    
    -- Direct category list (no scroll needed for 7 categories)
    local categoryContainer = CreateFrame("Frame", nil, categoryFrame)
    categoryContainer:SetPoint("TOPLEFT", 10, -40)
    categoryContainer:SetPoint("BOTTOMRIGHT", -10, 10)
    
    local yOffset = 0
    for key, name in pairs(DR_CATEGORIES) do
        local button = CreateFrame("Button", nil, categoryContainer)
        button:SetSize(160, 25)
        button:SetPoint("TOPLEFT", 0, yOffset)
        
        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        
        local text = button:CreateFontString(nil, "OVERLAY")
        text:SetFontObject("GameFontNormal")
        text:SetPoint("LEFT", 5, 0)
        text:SetText(name)
        text:SetTextColor(0.8, 0.8, 0.8, 1)
        
        button:SetScript("OnClick", function()
            -- CRITICAL FIX: Close any open dropdowns before switching categories
            AC:CloseAllDRDropdowns()
            
            currentCategory = key
            -- Persist last selected category
            AC.DB = AC.DB or {}
            AC.DB.profile = AC.DB.profile or {}
            AC.DB.profile.diminishingReturns = AC.DB.profile.diminishingReturns or {}
            AC.DB.profile.diminishingReturns.lastSelectedCategory = key
            if AC.SaveDatabase then AC:SaveDatabase() end
            AC:RefreshCategorySettings()
            AC:UpdateCategorySelection(categoryContainer)
        end)
        
        button:SetScript("OnEnter", function()
            bg:SetColorTexture(0.2, 0.2, 0.2, 0.9)
            text:SetTextColor(1, 1, 1, 1)
        end)
        
        button:SetScript("OnLeave", function()
            if currentCategory ~= key then
                bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
                text:SetTextColor(0.8, 0.8, 0.8, 1)
            end
        end)
        
        button.bg = bg
        button.text = text
        button.categoryKey = key
        
        yOffset = yOffset - 30
    end
    
    parent.categoryFrame = categoryFrame
    parent.categoryScrollChild = categoryContainer
end

-- ============================================================================
-- Core/UI_DetailedDRSettings.lua
-- REPLACEMENT for CreateCategorySettings
-- ============================================================================
-- ============================================================================
-- Core/UI_DetailedDRSettings.lua
-- REPLACEMENT for CreateCategorySettings
-- ============================================================================
function AC:CreateCategorySettings(parent)
    local settingsFrame = CreateFrame("Frame", nil, parent)
    settingsFrame:SetPoint("TOPLEFT", parent.categoryFrame, "TOPRIGHT", 10, 0)
    settingsFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    
    AC:HairlineGroupBox(settingsFrame)
    
    settingsFrame.title = AC:CreateStyledText(settingsFrame, "Select a Category", 13, AC.COLORS.PRIMARY, "OVERLAY", "")
    settingsFrame.title:SetPoint("TOPLEFT", 20, -18)
    
    local enableCheckbox = AC:CreateFlatCheckbox(settingsFrame, 20, true, function(value)
        if not currentCategory then return end
        
        local activeDB = AC:GetActiveDRSettingsDB()
        activeDB.categories = activeDB.categories or {}
        activeDB.categories[currentCategory] = value
        
        -- Refresh test mode DR icons immediately when checkbox changes
        if AC.testModeEnabled and AC.MasterFrameManager and AC.MasterFrameManager.ShowTestDRIcons then
            AC.MasterFrameManager:ShowTestDRIcons()
        end
    end)
    enableCheckbox:SetPoint("TOPLEFT", 10, -45)
    
    local enableLabel = AC:CreateStyledText(settingsFrame, "Enable Category", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    enableLabel:SetPoint("LEFT", enableCheckbox, "RIGHT", 8, 0)
    
    settingsFrame.iconLabel = AC:CreateStyledText(settingsFrame, "Default Icon", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    settingsFrame.iconLabel:SetPoint("TOPLEFT", 10, -70)
    
    local iconDropdown = AC:CreateFlatDropdown(settingsFrame, 300, 24, {}, "")
    iconDropdown:SetPoint("TOPLEFT", settingsFrame.iconLabel, "BOTTOMLEFT", 0, -10)
    
    local customLabel = AC:CreateStyledText(settingsFrame, "Add Custom Spell ID", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    customLabel:SetPoint("TOPLEFT", 10, -130)
    
    local customInput = AC:CreateEnhancedInput(settingsFrame, 200, 28, "Enter Spell ID...")
    customInput:SetPoint("TOPLEFT", 10, -155)
    
    local addBtn = AC:CreateTexturedButton(settingsFrame, 100, 28, "Add Spell", "button-test")
    addBtn:SetPoint("LEFT", customInput, "RIGHT", 8, 0)
    addBtn:SetScript("OnClick", function()
        if not currentCategory then
            print("|cffDC2D2DArena Core:|r No category selected!")
            return
        end
        
        local text = customInput.input:GetText()
        if not text or text == "" then
            print("|cffDC2D2DArena Core:|r Please enter a Spell ID.")
            return
        end
        
        local spellID = tonumber(text)
        if not spellID then
            print("|cffDC2D2DArena Core:|r Input must be a numeric Spell ID.")
            return
        end
        
        -- Validate spell exists
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if not spellInfo or not spellInfo.name then
            print("|cffDC2D2DArena Core:|r Invalid Spell ID: " .. text .. " - Spell not found in game data.")
            return
        end
        
        local activeDB = AC:GetActiveDRSettingsDB()
        activeDB.customSpellsList = activeDB.customSpellsList or {}
        activeDB.customSpellsList[currentCategory] = activeDB.customSpellsList[currentCategory] or {}
        
        -- Check for duplicates
        for _, existingID in ipairs(activeDB.customSpellsList[currentCategory]) do
            if existingID == spellID then
                print("|cffFFAA00Arena Core:|r Spell '" .. spellInfo.name .. "' (ID: " .. spellID .. ") is already in the list for " .. (DR_CATEGORIES[currentCategory] or "this category") .. "!")
                customInput.input:SetText("")
                return
            end
        end
        
        -- Check if spell already exists in default list
        if DR_SPELL_LIST[spellID] == currentCategory then
            print("|cffFFAA00Arena Core:|r Spell '" .. spellInfo.name .. "' (ID: " .. spellID .. ") is already in the default list for " .. (DR_CATEGORIES[currentCategory] or "this category") .. "!")
            customInput.input:SetText("")
            return
        end
        
        -- Add the spell
        table.insert(activeDB.customSpellsList[currentCategory], spellID)
        
        -- Save to SavedVariables immediately
        if _G.ArenaCoreDB and _G.ArenaCoreDB.profile then
            _G.ArenaCoreDB.profile.diminishingReturns = _G.ArenaCoreDB.profile.diminishingReturns or {}
            _G.ArenaCoreDB.profile.diminishingReturns.customSpellsList = activeDB.customSpellsList
        end
        
        print("|cff8B45FFArena Core:|r Added '" .. spellInfo.name .. "' (ID: " .. spellID .. ") to " .. (DR_CATEGORIES[currentCategory] or "category") .. " DR icons! (SAVED)")
        
        -- Play custom ArenaCore save sound for feedback
        PlaySoundFile("Interface/AddOns/ArenaCore/Media/Sounds/InfoSaved.mp3", "Master")
        
        -- Clear input
        customInput.input:SetText("")
        
        -- Refresh the dropdown to show the new spell
        AC:RefreshCategorySettings()
    end)
    
    local testButton = AC:CreateTexturedButton(settingsFrame, 80, 32, "TEST", "button-test")
    testButton:SetPoint("TOPLEFT", 10, -190)
    testButton:SetScript("OnClick", function()
        if not currentCategory then return end
        if AC.FrameManager then AC.FrameManager:EnableTestMode() end

        local activeDB = AC:GetActiveDRSettingsDB()
        activeDB.iconSettings = activeDB.iconSettings or {}
        activeDB.customSpells = activeDB.customSpells or {}

        local setting = activeDB.iconSettings[currentCategory] or "dynamic"
        local spellToTest

        if setting == "dynamic" then
            spellToTest = DEFAULT_TEST_SPELLS[currentCategory]
        elseif setting == "custom" then
            spellToTest = activeDB.customSpells[currentCategory] or DEFAULT_TEST_SPELLS[currentCategory]
        else
            spellToTest = tonumber(setting) or DEFAULT_TEST_SPELLS[currentCategory]
        end

        AC:ApplyTestDRIcons(currentCategory, spellToTest)
    end)
    
    -- THE FIX: We must attach all the created elements to the settingsFrame
    -- so they can be found and updated later by the RefreshCategorySettings function.
    parent.settingsFrame = settingsFrame
    settingsFrame.enableCheckbox = enableCheckbox
    settingsFrame.iconDropdown = iconDropdown
    settingsFrame.customInput = customInput
    settingsFrame.customLabel = customLabel
    settingsFrame.addBtn = addBtn
end

function AC:RefreshDetailedDRWindow()
    if not detailedDRFrame then return end
    
    -- Ensure database structure exists and get saved values
    AC.DB = AC.DB or {}
    AC.DB.profile = AC.DB.profile or {}
    AC.DB.profile.diminishingReturns = AC.DB.profile.diminishingReturns or {}
    local db = AC.DB.profile.diminishingReturns
    
    -- Initialize defaults if needed
    if not db.initialized then
        AC:InitializeDRCategories()
        db.initialized = true
    end
    
    -- Update class/spec controls in categories content
    if detailedDRFrame.categoriesContent and detailedDRFrame.categoriesContent.enableCheckbox then
        local savedValue = db.classSpecEnabled or false
        detailedDRFrame.categoriesContent.enableCheckbox:SetChecked(savedValue)
        
        -- Also update the dropdown value if class/spec is enabled
        if savedValue and db.classSpecSelection and detailedDRFrame.categoriesContent.classSpecDropdown then
            -- Find the display text for the saved selection
            local classSpecOptions = {}
            
            -- Rebuild the same options as in creation
            local classes = {}
            for i = 1, GetNumClasses() do
                local className = GetClassInfo(i)
                if className then
                    table.insert(classes, {id = i, name = className})
                end
            end
            
            table.sort(classes, function(a, b) return a.name < b.name end)
            
            for _, classData in ipairs(classes) do
                local className = classData.name
                local classID = classData.id
                
                local specs = {}
                for j = 1, GetNumSpecializationsForClassID(classID) do
                    local _, specName, _, icon = GetSpecializationInfoForClassID(classID, j)
                    if specName then
                        table.insert(specs, {name = specName, icon = icon})
                    end
                end
                
                table.sort(specs, function(a, b) return a.name < b.name end)
                
                for _, specData in ipairs(specs) do
                    local key = className .. "-" .. specData.name
                    local displayText = "|T" .. specData.icon .. ":16:16|t " .. className .. " - " .. specData.name
                    classSpecOptions[key] = displayText
                end
            end
            
            -- Set the dropdown to the saved value
            if classSpecOptions[db.classSpecSelection] then
                detailedDRFrame.categoriesContent.classSpecDropdown:SetValue(classSpecOptions[db.classSpecSelection])
            end
        end
        
        -- Update category selection
        if detailedDRFrame.categoriesContent.categoryScrollChild then
            self:UpdateCategorySelection(detailedDRFrame.categoriesContent.categoryScrollChild)
        end
        
        -- Refresh category settings
        self:RefreshCategorySettings()
    end
end

function AC:UpdateCategorySelection(scrollChild)
    for _, child in pairs({scrollChild:GetChildren()}) do
        if child.categoryKey then
            if child.categoryKey == currentCategory then
                child.bg:SetColorTexture(0.3, 0.2, 0.5, 0.9)
                child.text:SetTextColor(1, 1, 1, 1)
            else
                child.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
                child.text:SetTextColor(0.8, 0.8, 0.8, 1)
            end
        end
    end
end

-- ============================================================================
-- Create specialized dropdown with X buttons for removing custom spells
-- ============================================================================
function AC:CreateDRDropdownWithRemove(parent, width, height, options, selectedValue, customSpells, valueToKey, category, onSelect)
    -- Use base CreateFlatDropdown but modify to add X buttons
    local dropdown = CreateFrame("Frame", nil, parent)
    dropdown:SetSize(width, height)
    
    local border = AC:CreateFlatTexture(dropdown, "BACKGROUND", 1, {0.196, 0.196, 0.196, 1})
    border:SetAllPoints()
    local bg = AC:CreateFlatTexture(dropdown, "BACKGROUND", 2, {0.102, 0.102, 0.102, 1})
    bg:SetPoint("TOPLEFT", 1, -1); bg:SetPoint("BOTTOMRIGHT", -1, 1)
    
    local button = CreateFrame("Button", nil, dropdown)
    button:SetAllPoints()
    
    local selectedIcon = AC:CreateStyledIcon(button, height - 8, true)
    selectedIcon:SetPoint("LEFT", 4, 0)
    selectedIcon:Hide()
    
    local text = AC:CreateStyledText(button, "", 11, {0.706, 0.706, 0.706, 1}, "OVERLAY", "")
    text:SetPoint("LEFT", 8, 0); text:SetPoint("RIGHT", -20, 0); text:SetJustifyH("LEFT")
    
    local arrow = button:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(12, 12)
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\dropdown-arrow-purple.tga")
    
    local function ParseOption(optionStr)
        local texture, remainingText = string.match(optionStr, "|T(.-):.-|t(.*)")
        return texture, remainingText or optionStr
    end

    local function UpdateSelectedDisplay(value)
        local texturePath, textOnly = ParseOption(value)
        if texturePath and AC.IconStyling then
            selectedIcon:SetIconTexture(texturePath)
            selectedIcon:Show()
            text:SetPoint("LEFT", selectedIcon, "RIGHT", 5, 0)
            text:SetText(textOnly)
        else
            selectedIcon:Hide()
            text:SetPoint("LEFT", 8, 0)
            text:SetText(value)
        end
    end

    local maxVisibleOptions = 8
    local optionHeight = 24
    local menu = CreateFrame("Frame", nil, UIParent)
    menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -1)
    menu:SetWidth(width)
    menu:SetHeight(math.min(#options, maxVisibleOptions) * optionHeight + 4)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetFrameLevel(1000)
    menu:Hide()
    menu.__isArenaCore = true
    
    local menuBorder = AC:CreateFlatTexture(menu, "BACKGROUND", 1, {0.196, 0.196, 0.196, 1})
    menuBorder:SetAllPoints()
    local menuBg = AC:CreateFlatTexture(menu, "BACKGROUND", 2, {0.102, 0.102, 0.102, 1})
    menuBg:SetPoint("TOPLEFT", 1, -1); menuBg:SetPoint("BOTTOMRIGHT", -1, 1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, menu)
    scrollFrame:SetPoint("TOPLEFT", 2, -2); scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(width - 4)
    scrollChild:SetHeight(#options * optionHeight)
    scrollFrame:SetScrollChild(scrollChild)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = math.max(0, scrollChild:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(maxScroll, current - (delta * optionHeight))))
    end)

    for i, option in ipairs(options) do
        local optBtn = CreateFrame("Button", nil, scrollChild)
        optBtn:SetPoint("TOPLEFT", 0, -(i-1) * optionHeight); optBtn:SetPoint("TOPRIGHT", 0, -(i-1) * optionHeight)
        optBtn:SetHeight(optionHeight - 2)
        
        local optHover = AC:CreateFlatTexture(optBtn, "BACKGROUND", 1, {0.278, 0.278, 0.278, 1}, 0.3)
        optHover:SetAllPoints(); optHover:Hide()
        
        local texturePath, textOnly = ParseOption(option)
        if texturePath and AC.IconStyling then
            local icon = AC:CreateStyledIcon(optBtn, optionHeight - 8, true)
            icon:SetIconTexture(texturePath)
            icon:SetPoint("LEFT", 4, 0)
            local optText = AC:CreateStyledText(optBtn, textOnly, 11, {0.706, 0.706, 0.706, 1}, "OVERLAY", "")
            optText:SetPoint("LEFT", icon, "RIGHT", 5, 0); optText:SetJustifyH("LEFT")
        else
            local optText = AC:CreateStyledText(optBtn, option, 11, {0.706, 0.706, 0.706, 1}, "OVERLAY", "")
            optText:SetPoint("LEFT", 6, 0); optText:SetJustifyH("LEFT")
        end
        
        -- Add X button for custom spells
        if customSpells[option] then
            local xBtn = AC:CreateTexturedButton(optBtn, 16, 16, "X", "button-hide")
            xBtn:SetPoint("RIGHT", -4, 0)
            xBtn:SetScript("OnClick", function()
                AC:RemoveCustomDRSpell(category, option, valueToKey[option])
                menu:Hide()
            end)
        end
        
        optBtn:SetScript("OnEnter", function() optHover:Show() end)
        optBtn:SetScript("OnLeave", function() optHover:Hide() end)
        optBtn:SetScript("OnClick", function()
            UpdateSelectedDisplay(option)
            menu:Hide()
            if onSelect then onSelect(option) end
            dropdown.selectedValue = option
        end)
    end
    
    button:SetScript("OnClick", function() 
        if menu:IsShown() then 
            menu:Hide() 
        else 
            menu:Show() 
        end 
    end)
    menu:SetScript("OnShow", function() arrow:SetRotation(math.rad(180)) end)
    menu:SetScript("OnHide", function() arrow:SetRotation(math.rad(0)) end)

    dropdown.SetValue = function(self, value)
        for _, option in ipairs(options) do
            if option == value then
                UpdateSelectedDisplay(value)
                self.selectedValue = value
                break
            end
        end
    end
    dropdown:SetValue(selectedValue or options[1])
    dropdown.menu = menu
    
    return dropdown
end

-- ============================================================================
-- Remove custom DR spell with confirmation
-- ============================================================================
function AC:RemoveCustomDRSpell(category, displayText, spellIDKey)
    if not category or not spellIDKey then return end
    
    local spellID = tonumber(spellIDKey)
    if not spellID then return end
    
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo then return end
    
    -- Create custom styled confirmation popup (matching ArenaCore UI)
    if not AC.DRRemovePopup then
        local popup = CreateFrame("Frame", "ArenaCoreRemoveDRPopup", UIParent)
        popup:SetSize(420, 220)
        popup:SetPoint("CENTER")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")  -- Higher than DIALOG (DR settings window)
        popup:SetFrameLevel(1000)
        popup:SetToplevel(true)  -- Ensures it stays on top
        popup:Hide()
        
        -- Background
        local bg = AC:CreateFlatTexture(popup, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
        bg:SetAllPoints()
        
        -- Border
        AC:AddWindowEdge(popup, 1, 0)
        
        -- Header
        local header = CreateFrame("Frame", nil, popup)
        header:SetPoint("TOPLEFT", 8, -8)
        header:SetPoint("TOPRIGHT", -8, -8)
        header:SetHeight(40)
        
        local headerBg = AC:CreateFlatTexture(header, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
        headerBg:SetAllPoints()
        
        -- Purple accent line (matching other ArenaCore windows)
        local accent = AC:CreateFlatTexture(header, "OVERLAY", 3, AC.COLORS.PRIMARY, 1)
        accent:SetPoint("TOPLEFT", 0, 0)
        accent:SetPoint("TOPRIGHT", 0, 0)
        accent:SetHeight(2)
        
        -- Title
        popup.title = AC:CreateStyledText(header, "Remove Custom Spell", 14, AC.COLORS.TEXT, "OVERLAY", "")
        popup.title:SetPoint("LEFT", 12, 0)
        
        -- Close button
        local closeBtn = AC:CreateTexturedButton(header, 28, 28, "", "button-close")
        closeBtn:SetPoint("RIGHT", -4, 0)
        AC:CreateStyledText(closeBtn, "×", 14, AC.COLORS.TEXT, "OVERLAY", ""):SetPoint("CENTER")
        closeBtn:SetScript("OnClick", function() popup:Hide() end)
        
        -- Content area
        local content = CreateFrame("Frame", nil, popup)
        content:SetPoint("TOPLEFT", 8, -48)
        content:SetPoint("BOTTOMRIGHT", -8, 50)
        AC:CreateFlatTexture(content, "BACKGROUND", 1, {0.15, 0.15, 0.15, 1}):SetAllPoints()
        
        -- Message text
        popup.message = AC:CreateStyledText(content, "", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
        popup.message:SetPoint("TOPLEFT", 12, -12)
        popup.message:SetPoint("BOTTOMRIGHT", -12, 12)
        popup.message:SetJustifyH("CENTER")
        popup.message:SetJustifyV("MIDDLE")
        popup.message:SetWordWrap(true)
        
        -- Remove button (green - button-test texture)
        local removeBtn = AC:CreateTexturedButton(popup, 100, 32, "Remove", "button-test")
        removeBtn:SetPoint("BOTTOM", -55, 10)
        popup.removeBtn = removeBtn
        
        -- Cancel button (red - button-hide texture)
        local cancelBtn = AC:CreateTexturedButton(popup, 100, 32, "Cancel", "button-hide")
        cancelBtn:SetPoint("BOTTOM", 55, 10)
        cancelBtn:SetScript("OnClick", function() popup:Hide() end)
        
        AC.DRRemovePopup = popup
    end
    
    local popup = AC.DRRemovePopup
    
    -- Update message with spell and category info
    local categoryName = DR_CATEGORIES[category] or "this category"
    popup.message:SetText(string.format("Remove |cffFFAA00%s|r from %s DR icons?\n\nThis will permanently remove it from the list.\nYou can re-add it later if needed.", spellInfo.name, categoryName))
    
    -- Set up Remove button click handler with current spell data
    popup.removeBtn:SetScript("OnClick", function()
        local activeDB = AC:GetActiveDRSettingsDB()
        if not activeDB or not activeDB.customSpellsList or not activeDB.customSpellsList[category] then 
            popup:Hide()
            return 
        end
        
        -- Find and remove the spell from customSpellsList
        for i, id in ipairs(activeDB.customSpellsList[category]) do
            if id == spellID then
                table.remove(activeDB.customSpellsList[category], i)
                break
            end
        end
        
        -- Save to SavedVariables immediately
        if _G.ArenaCoreDB and _G.ArenaCoreDB.profile then
            _G.ArenaCoreDB.profile.diminishingReturns = _G.ArenaCoreDB.profile.diminishingReturns or {}
            _G.ArenaCoreDB.profile.diminishingReturns.customSpellsList = activeDB.customSpellsList
        end
        
        -- Check if the removed spell was currently selected
        local currentSettingKey = activeDB.iconSettings[category]
        if currentSettingKey == spellIDKey then
            -- Auto-switch to Dynamic (user deleted the selected icon)
            activeDB.iconSettings[category] = "dynamic"
            print("|cff8B45FFArena Core:|r Removed '" .. spellInfo.name .. "' and switched to Dynamic (it was selected)")
        else
            -- Just removed, keep current selection
            print("|cff8B45FFArena Core:|r Removed '" .. spellInfo.name .. "' from " .. categoryName .. " DR icons")
        end
        
        -- Refresh the dropdown to update the list
        AC:RefreshCategorySettings()
        
        -- Update test mode icons if active
        if AC.testModeEnabled then
            AC:UpdateDRIconTexturesOnly(category)
        end
        
        popup:Hide()
    end)
    
    -- Show popup
    popup:Show()
end

-- ============================================================================
-- Core/UI_DetailedDRSettings.lua
-- REPLACEMENT for RefreshCategorySettings
-- ============================================================================
function AC:RefreshCategorySettings()
    if not detailedDRFrame or not currentCategory then return end
    
    local settingsFrame = detailedDRFrame.categoriesContent.settingsFrame
    -- Use our new "brain" to get the correct settings table (default or class/spec)
    local activeDB = AC:GetActiveDRSettingsDB()
    activeDB.categories = activeDB.categories or {}
    activeDB.iconSettings = activeDB.iconSettings or {}
    activeDB.customSpells = activeDB.customSpells or {}
    
    settingsFrame.title:SetText("Settings: " .. (DR_CATEGORIES[currentCategory] or "Unknown"))
    settingsFrame.enableCheckbox:SetChecked(activeDB.categories[currentCategory] ~= false)
    
    local optionsArray, valueToKey, customSpells = AC:BuildDRDropdownOptions(currentCategory)
    
    local currentSettingKey = activeDB.iconSettings[currentCategory] or "dynamic"
    local selectedDisplayValue = optionsArray[1]

    for display, key in pairs(valueToKey) do
        if key == currentSettingKey then
            selectedDisplayValue = display
            break
        end
    end

    if settingsFrame.iconDropdown then settingsFrame.iconDropdown:Hide() end
    
    -- Create dropdown with X buttons for custom spells
    settingsFrame.iconDropdown = AC:CreateDRDropdownWithRemove(settingsFrame, 300, 24, optionsArray, selectedDisplayValue, customSpells, valueToKey, currentCategory, function(selectedValue)
        local selectedKey = valueToKey[selectedValue]
        if selectedKey then
            -- CRITICAL FIX: Save to saved variables database
            -- GetActiveDRSettingsDB now returns AC.DB.profile.diminishingReturns (the real saved database)
            -- This ensures settings persist across reloads and work in live arena
            local dbToSave = AC:GetActiveDRSettingsDB()
            dbToSave.iconSettings = dbToSave.iconSettings or {}
            dbToSave.iconSettings[currentCategory] = selectedKey
            
            -- SURGICAL FIX: Only update icon textures for this category, don't reposition
            if AC.testModeEnabled then
                AC:UpdateDRIconTexturesOnly(currentCategory)
            end
        end
    end)
    settingsFrame.iconDropdown:SetPoint("TOPLEFT", settingsFrame.iconLabel, "BOTTOMLEFT", 0, -10)
    
    -- Register this dropdown for cleanup when switching categories
    table.insert(drDropdownMenus, settingsFrame.iconDropdown)
end

-- SURGICAL FIX: Update only icon textures for a specific category without repositioning
function AC:UpdateDRIconTexturesOnly(category)
    if not category or not AC.testModeEnabled then return end
    
    -- Get the spell ID to use for this category based on user's dropdown selection
    local activeDB = AC:GetActiveDRSettingsDB()
    if not activeDB or not activeDB.iconSettings then return end
    
    local spellIDToShow
    if AC.ResolveDRIconSpellID then
        -- Use the same resolution logic as ShowTestDRIcons
        local defaultSpellID = DEFAULT_TEST_SPELLS[category]
        spellIDToShow = AC:ResolveDRIconSpellID(category, nil, defaultSpellID)
    else
        spellIDToShow = DEFAULT_TEST_SPELLS[category]
    end
    
    if not spellIDToShow then return end
    
    -- Update icon texture on all 3 arena frames for this category only
    local arenaFrames = AC.arenaFrames or (AC.MasterFrameManager and AC.MasterFrameManager.frames)
    if not arenaFrames then return end
    
    for i = 1, 3 do
        local frame = arenaFrames[i]
        if frame and frame.drIcons and frame.drIcons[category] then
            local drFrame = frame.drIcons[category]
            if drFrame.icon then
                local spellInfo = C_Spell.GetSpellInfo(spellIDToShow)
                if spellInfo and spellInfo.iconID then
                    drFrame.icon:SetTexture(spellInfo.iconID)
                end
            end
        end
    end
end

-- Close all open dropdown menus in the DR settings window
function AC:CloseAllDRDropdowns()
    for _, dropdown in ipairs(drDropdownMenus) do
        if dropdown and dropdown.menu and dropdown.menu:IsShown() then
            dropdown.menu:Hide()
        end
    end
end

-- Initialize DR categories in database
function AC:InitializeDRCategories()
    local db = AC.DB.profile.diminishingReturns
    db.categories = db.categories or {}
    db.iconSettings = db.iconSettings or {}
    db.customSpells = db.customSpells or {}
    db.customSpellsList = db.customSpellsList or {}
    
    -- Set default enabled state for all categories
    for key in pairs(DR_CATEGORIES) do
        if db.categories[key] == nil then
            db.categories[key] = true
        end
    end
end

-- Duplicate ShowTestFrames function removed - using main one in ArenaTracking.lua

-- Apply test DR icons to arena frames
-- ============================================================================
-- Core/UI_DetailedDRSettings.lua
-- REPLACEMENT for GetDRIconForCategory
-- ============================================================================
function AC:GetDRIconForCategory(category, unitGUID, actualSpellID)
    -- Delegate to centralized resolver to avoid drift with DRTracker
    if AC.ResolveDRIconSpellID then
        return AC:ResolveDRIconSpellID(category, unitGUID, actualSpellID)
    end
    -- UI test fallback: use provided test spell or a sensible default per category
    return actualSpellID or DEFAULT_TEST_SPELLS[category]
end

-- RENAMED: This was conflicting with the real TrackDRApplication in DRTracker.lua!
-- This is only for UI tracking of recent spells, not actual DR tracking
function AC:TrackRecentDRSpell(unitGUID, spellID, category)
    AC.recentDRSpells = AC.recentDRSpells or {}
    AC.recentDRSpells[unitGUID] = AC.recentDRSpells[unitGUID] or {}
    AC.recentDRSpells[unitGUID][category] = {
        spellID = spellID,
        timestamp = GetTime()
    }
    
end

-- Add this helper function to get spells for a category
function AC:GetSpellsForCategory(category)
    -- Return the comprehensive spell list from your RefreshCategorySettings
    local categorySpells = {
        ["stun"] = {
            [108194] = "Asphyxiate", [91800] = "Gnaw", [91797] = "Monstrous Blow", [377048] = "Absolute Zero", [287254] = "Dead of Winter",
            [179057] = "Chaos Nova", [205630] = "Illidan's Grasp", [208618] = "Illidan's Grasp (Secondary)", [211881] = "Fel Eruption", [200166] = "Metamorphosis",
            [203123] = "Maim", [163505] = "Rake (Prowl)", [5211] = "Mighty Bash", [202244] = "Overrun", [325321] = "Wild Hunt's Charge", [372245] = "Terror of the Skies",
            [408544] = "Seismic Slam", [117526] = "Binding Shot", [357021] = "Consecutive Concussion", [24394] = "Intimidation", [389831] = "Snowdrift",
            [119381] = "Leg Sweep", [458605] = "Leg Sweep 2", [202346] = "Double Barrel",
            [853] = "Hammer of Justice", [255941] = "Wake of Ashes",
            [64044] = "Psychic Horror", [200200] = "Holy Word: Chastise Censure",
            [1833] = "Cheap Shot", [408] = "Kidney Shot",
            [118905] = "Static Charge", [118345] = "Pulverize", [305485] = "Lightning Lasso",
            [89766] = "Axe Toss", [171017] = "Meteor Strike (Infernal)", [171018] = "Meteor Strike (Abyssal)", [30283] = "Shadowfury",
            [385954] = "Shield Charge", [46968] = "Shockwave", [132168] = "Shockwave (Protection)", [145047] = "Shockwave (Proving Grounds)", [132169] = "Storm Bolt", [199085] = "Warpath",
            [20549] = "War Stomp", [255723] = "Bull Rush", [287712] = "Haymaker",
            [332423] = "Sparkling Driftglobe Core", [210141] = "Zombie Explosion"
        },
        ["disorient"] = {
            [207167] = "Blinding Sleet", [207685] = "Sigil of Misery", [33786] = "Cyclone", [360806] = "Sleep Walk", [1513] = "Scare Beast",
            [31661] = "Dragon's Breath", [353084] = "Ring of Fire", [198909] = "Song of Chi-ji", [202274] = "Hot Trub",
            [105421] = "Blinding Light", [10326] = "Turn Evil", [205364] = "Dominate Mind", [605] = "Mind Control", [8122] = "Psychic Scream",
            [2094] = "Blind", [118699] = "Fear", [130616] = "Fear (Horrify)", [5484] = "Howl of Terror", [261589] = "Seduction (Grimoire of Sacrifice)", [6358] = "Seduction (Succubus)",
            [5246] = "Intimidating Shout", [316593] = "Intimidating Shout (Menace Main)", [316595] = "Intimidating Shout (Menace Other)",
            [331866] = "Agent of Chaos", [324263] = "Sulfuric Emission"
        },
        -- Add all other categories from your comprehensive list...
        ["incapacitate"] = {[217832] = "Imprison", [221527] = "Imprison (Honor talent)", [2637] = "Hibernate", [99] = "Incapacitating Roar"},
        ["silence"] = {[47476] = "Strangulate", [374776] = "Tightening Grasp", [204490] = "Sigil of Silence", [410065] = "Reactive Resin"},
        ["root"] = {[204085] = "Deathchill (Chains of Ice)", [233395] = "Deathchill (Remorseless Winter)", [454787] = "Ice Prison", [339] = "Entangling Roots"},
        ["disarm"] = {[209749] = "Faerie Swarm", [407032] = "Sticky Tar Bomb 1", [407031] = "Sticky Tar Bomb 2", [207777] = "Dismantle"},
        -- Add the rest of your categories here...
    }
    
    return categorySpells[category]
end

-- ============================================================================
-- Core/UI_DetailedDRSettings.lua
-- REPLACEMENT for ApplyTestDRIcons
-- ============================================================================
-- ============================================================================
-- Core/UI_DetailedDRSettings.lua
-- REPLACEMENT for ApplyTestDRIcons
-- ============================================================================
function AC:ApplyTestDRIcons(category, spellID)
    -- Simple self-contained test DR system - no external dependencies
    if not self.testModeEnabled or not self.arenaFrames then
        return
    end

    -- Apply DR icons to all active arena frames using the simple system
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = self.arenaFrames[i]
        if frame and frame:IsShown() and frame.drFrames and frame.drFrames[category] then
            -- Get spell info
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo and spellInfo.iconID then
                -- Update the DR frame directly
                local drFrame = frame.drFrames[category]
                drFrame.icon:SetTexture(spellInfo.iconID)
                drFrame:Show()

                -- Update positions
                if AC.UpdateDRPositions then
                    AC:UpdateDRPositions(frame)
                end
            end
        end
    end
end
