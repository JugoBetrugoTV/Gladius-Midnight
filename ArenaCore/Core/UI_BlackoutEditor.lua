-- Core/UI_BlackoutEditor.lua --
-- v1.1 - FIXED state management bug preventing re-opening --
local AC = _G.ArenaCore
if not AC then return end

AC.BlackoutEditor = AC.BlackoutEditor or {}
local Editor = AC.BlackoutEditor

-- ============================================================================
-- DUPLICATE SPELL POPUP
-- ============================================================================
local function ShowDuplicatePopup(spellID, spellName)
    -- Create popup frame (reuse if exists)
    local popup = Editor.DuplicatePopup
    if not popup then
        popup = CreateFrame("Frame", "ArenaCore_BlackoutDuplicatePopup", UIParent)
        popup:SetSize(360, 140)
        popup:SetPoint("CENTER")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetFrameLevel(200)
        popup:Hide()
        
        -- Background
        AC:CreateFlatTexture(popup, "BACKGROUND", -1, {0.1, 0.1, 0.1, 1}):SetAllPoints()
        AC:AddWindowEdge(popup, 1, 0)
        
        -- Header with red accent (error color)
        local header = CreateFrame("Frame", nil, popup)
        header:SetPoint("TOPLEFT", 8, -8)
        header:SetPoint("TOPRIGHT", -8, -8)
        header:SetHeight(40)
        
        local headerBg = AC:CreateFlatTexture(header, "BACKGROUND", 1, AC.COLORS.HEADER_BG, 1)
        headerBg:SetAllPoints()
        
        -- Red accent line for error
        local accent = AC:CreateFlatTexture(header, "OVERLAY", 3, {0.86, 0.18, 0.18, 1}, 1) -- Red
        accent:SetPoint("TOPLEFT", 0, 0)
        accent:SetPoint("TOPRIGHT", 0, 0)
        accent:SetHeight(2)
        
        -- Title
        popup.title = AC:CreateStyledText(header, "Spell Already Added", 14, AC.COLORS.TEXT, "OVERLAY", "")
        popup.title:SetPoint("LEFT", 12, 0)
        
        -- Close button
        local closeBtn = AC:CreateTexturedButton(header, 28, 28, "", "button-close")
        closeBtn:SetPoint("RIGHT", -4, 0)
        AC:CreateStyledText(closeBtn, "×", 14, AC.COLORS.TEXT, "OVERLAY", ""):SetPoint("CENTER")
        closeBtn:SetScript("OnClick", function() popup:Hide() end)
        
        -- Content area
        local content = CreateFrame("Frame", nil, popup)
        content:SetPoint("TOPLEFT", 8, -48)
        content:SetPoint("BOTTOMRIGHT", -8, 42)
        AC:CreateFlatTexture(content, "BACKGROUND", 1, {0.15, 0.15, 0.15, 1}):SetAllPoints()
        
        -- Message text
        popup.message = AC:CreateStyledText(content, "", 13, AC.COLORS.TEXT_2, "OVERLAY", "")
        popup.message:SetPoint("TOPLEFT", 12, -12)
        popup.message:SetPoint("BOTTOMRIGHT", -12, 12)
        popup.message:SetJustifyH("CENTER")
        popup.message:SetJustifyV("MIDDLE")
        popup.message:SetWordWrap(true)
        
        -- OK button
        local okBtn = AC:CreateTexturedButton(popup, 100, 32, "OK", "button-test")
        okBtn:SetPoint("BOTTOM", 0, 6)
        okBtn:SetScript("OnClick", function() popup:Hide() end)
        
        Editor.DuplicatePopup = popup
    end
    
    -- Update message with spell info
    local displayName = spellName or "Unknown"
    popup.message:SetText(string.format("The spell |cffFFD700%s|r (ID: |cffFFD700%d|r)\nis already in your Blackout list.", displayName, spellID))
    
    -- Show popup
    popup:Show()
    popup:Raise()
    
    -- Auto-hide after 3 seconds
    C_Timer.After(3, function()
        if popup and popup:IsShown() then
            popup:Hide()
        end
    end)
end

-- Wipes all child frames (like spell rows) from a parent frame
local function WipeChildren(frame)
    if not frame then return end
    for _, child in ipairs({ frame:GetChildren() }) do
        child:Hide()
        child:SetParent(UIParent) -- Reparent to avoid memory leaks
    end
end

-- Creates a single row in the spell list
-- Creates a single row in the spell list with tooltips
local function CreateSpellRow(parent, spellID)
    local id, spellName, spellIcon = AC:GetSpellData(spellID)
    if not id then return nil end

    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("LEFT", 12, 0); row:SetPoint("RIGHT", -12, 0); row:SetHeight(28)

    -- Create styled icon using new classic system
    local iconFrame = AC:CreateStyledIcon(row, 24, true, true)
    iconFrame:SetPoint("LEFT", 0, 0)
    local icon = iconFrame.icon -- Keep reference for compatibility
    icon:SetTexture(spellIcon)

    local name = AC:CreateStyledText(row, spellName .. " (" .. id .. ")", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)

    local removeBtn = AC:CreateTexturedButton(row, 24, 24, "", "button-close")
    removeBtn:SetPoint("RIGHT", 0, 0)
    AC:CreateStyledText(removeBtn, "×", 14, AC.COLORS.TEXT, "OVERLAY", ""):SetPoint("CENTER")
    removeBtn:SetScript("OnClick", function()
        -- FIX: Get a fresh DB reference right when the button is clicked
        local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
        if not db then return end

        for i, sID in ipairs(db.spells) do
            if sID == spellID then
                table.remove(db.spells, i)
                
                -- FIXED: Force save to SavedVariables immediately
                if _G.ArenaCoreDB and _G.ArenaCoreDB.profile then
                    _G.ArenaCoreDB.profile.blackout = _G.ArenaCoreDB.profile.blackout or {}
                    _G.ArenaCoreDB.profile.blackout.spells = db.spells
                end
                
                Editor:PopulateList() -- Refresh the list
                print("|cff22AA44Arena Core:|r Removed spell " .. spellID .. " from Blackout list (SAVED).")
                return
            end
        end
    end)

    -- ADD TOOLTIP FUNCTIONALITY
    -- Create invisible button covering the entire row for tooltip detection
    local tooltipButton = CreateFrame("Button", nil, row)
    tooltipButton:SetPoint("LEFT", 0, 0)
    tooltipButton:SetPoint("RIGHT", removeBtn, "LEFT", -4, 0) -- Stop before remove button
    tooltipButton:SetHeight(28)
    tooltipButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(spellID)
        GameTooltip:Show()
        
        -- Add subtle hover effect
        row:SetAlpha(0.8)
    end)
    tooltipButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        row:SetAlpha(1.0)
    end)

    return row
end

-- Populates the list with spells from the database
function Editor:PopulateList()
    -- FIX: Get a fresh DB reference every time the list is populated
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    if not db or not Editor.Frame or not Editor.Frame.ScrollChild then return end

    -- CRITICAL: Ensure spells table exists
    if not db.spells then
        db.spells = {}
    end

    WipeChildren(Editor.Frame.ScrollChild)

    local yOffset = -4
    for _, spellID in ipairs(db.spells) do
        local row = CreateSpellRow(Editor.Frame.ScrollChild, spellID)
        if row then
            row:SetPoint("TOP", 0, yOffset)
            yOffset = yOffset - 30
        end
    end
    Editor.Frame.ScrollChild:SetHeight(math.abs(yOffset) + 10)
    if Editor.Frame.UpdateScrollbar then
        C_Timer.After(0.1, Editor.Frame.UpdateScrollbar)
    end
end

-- Creates the main editor window frame (no changes here)
function Editor:Create()
    if Editor.Frame then return end

    local f = CreateFrame("Frame", "ArenaCore_BlackoutEditor", UIParent)
    f:SetSize(480, 550); f:SetPoint("CENTER"); f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true);
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing);
    f:SetFrameStrata("DIALOG")

    AC:AddWindowEdge(f, 1, 0)
    AC:CreateFlatTexture(f, "BACKGROUND", -1, {0.1, 0.1, 0.1, 1}):SetAllPoints()

    -- Header matching Dispel Configuration style
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 8, -8)
    header:SetPoint("TOPRIGHT", -8, -8)
    header:SetHeight(50)
    
    -- Header background (dark like main UI)
    local headerBg = AC:CreateFlatTexture(header, "BACKGROUND", 1, AC.COLORS.HEADER_BG, 1)
    headerBg:SetAllPoints()
    
    -- Purple accent line (hairline like main UI)
    local accent = AC:CreateFlatTexture(header, "OVERLAY", 3, AC.COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(2)
    
    -- Header border
    local hbLight = AC:CreateFlatTexture(header, "OVERLAY", 2, AC.COLORS.BORDER_LIGHT, 0.8)
    hbLight:SetPoint("BOTTOMLEFT", 0, 0)
    hbLight:SetPoint("BOTTOMRIGHT", 0, 0)
    hbLight:SetHeight(1)
    
    f.Title = AC:CreateStyledText(header, "Blackout Aura Editor", 14, AC.COLORS.TEXT, "OVERLAY", "")
    f.Title:SetPoint("LEFT", 12, 0)

    local closeBtn = AC:CreateTexturedButton(header, 32, 32, "", "button-close")
    closeBtn:SetPoint("RIGHT", -6, 0); closeBtn:SetScript("OnClick", function() f:Hide() end)
    AC:CreateStyledText(closeBtn, "×", 16, AC.COLORS.TEXT, "OVERLAY", ""):SetPoint("CENTER")

    -- Add "How To" text box
    local howToFrame = CreateFrame("Frame", nil, f)
    howToFrame:SetPoint("TOPLEFT", 1, -58); howToFrame:SetPoint("TOPRIGHT", -1, -58); howToFrame:SetHeight(100)
    AC:CreateFlatTexture(howToFrame, "BACKGROUND", 1, {0.12, 0.12, 0.12, 1})

    local howToText = AC:CreateStyledText(howToFrame,
        "By default, the below are listed spells to track from all classes. These have been suggested tracking by Rank 1's, Multi Gladiators and AWC competitors and are only here by default, keep this exact list or edit to your liking as needed. We recommend keeping this exact list, but feel free to add or remove what YOU want to track.",
        13, AC.COLORS.TEXT_2, "OVERLAY", "")
    howToText:SetPoint("TOPLEFT", 12, -8)
    howToText:SetPoint("BOTTOMRIGHT", -12, 8)
    howToText:SetJustifyH("LEFT")
    howToText:SetJustifyV("TOP")
    howToText:SetWordWrap(true)
    howToText:SetSpacing(3)

    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", 1, -158); content:SetPoint("BOTTOMRIGHT", -1, 41)
    AC:CreateFlatTexture(content, "BACKGROUND", 1, {0.15, 0.15, 0.15, 1})

    local scroll = CreateFrame("ScrollFrame", nil, content)
scroll:SetPoint("TOPLEFT", 10, -10); scroll:SetPoint("BOTTOMRIGHT", -26, 10) -- Make room for scrollbar
local scrollChild = CreateFrame("Frame", nil, scroll)
scrollChild:SetWidth(424); scrollChild:SetHeight(1) -- Adjust width for scrollbar
scroll:SetScrollChild(scrollChild)

-- Create custom scrollbar
local scrollbar = CreateFrame("Slider", nil, content)
scrollbar:SetPoint("TOPRIGHT", -6, -10)
scrollbar:SetPoint("BOTTOMRIGHT", -6, 10)
scrollbar:SetWidth(16)
scrollbar:SetOrientation("VERTICAL")
scrollbar:SetMinMaxValues(0, 1)
scrollbar:SetValue(0)

-- Scrollbar track
local trackBg = AC:CreateFlatTexture(scrollbar, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1})
trackBg:SetAllPoints()

-- Scrollbar thumb - custom compressed texture
local thumbTexture = scrollbar:CreateTexture(nil, "OVERLAY")
thumbTexture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\slider-thumb-square.tga")
thumbTexture:SetWidth(14)
thumbTexture:SetHeight(20)
scrollbar:SetThumbTexture(thumbTexture)

-- Connect scrollbar to ScrollFrame
local function UpdateScrollbar()
    local maxScroll = scroll:GetVerticalScrollRange()
    if maxScroll > 0 then
        scrollbar:Show()
        scrollbar:SetMinMaxValues(0, maxScroll)
        local currentScroll = scroll:GetVerticalScroll()
        scrollbar:SetValue(currentScroll)
    else
        scrollbar:Hide()
    end
end

-- Scrollbar events
scrollbar:SetScript("OnValueChanged", function(self, value)
    scroll:SetVerticalScroll(value)
end)

-- Mouse wheel support
scroll:EnableMouseWheel(true)
scroll:SetScript("OnMouseWheel", function(self, delta)
    local current = scrollbar:GetValue()
    local step = 30 -- Scroll by 30 pixels per wheel step
    scrollbar:SetValue(current - (delta * step))
end)

-- Update scrollbar when content changes
scroll:SetScript("OnScrollRangeChanged", UpdateScrollbar)
scroll:SetScript("OnVerticalScroll", UpdateScrollbar)

f.ScrollChild = scrollChild
f.UpdateScrollbar = UpdateScrollbar -- Expose for PopulateList to call

    local footer = CreateFrame("Frame", nil, f)
    footer:SetPoint("BOTTOMLEFT", 1, 1); footer:SetPoint("BOTTOMRIGHT", -1, 1); footer:SetHeight(40)
    AC:CreateFlatTexture(footer, "BACKGROUND", 1, AC.COLORS.HEADER_BG)

    local input = AC:CreateEnhancedInput(footer, 200, 28, "Enter Spell ID...")
    input:SetPoint("LEFT", 10, 0)

    -- Core/UI_BlackoutEditor.lua --
-- FIX: Corrected and enhanced "Add Spell" logic --
local addBtn = AC:CreateTexturedButton(footer, 100, 28, "Add Spell", "button-test")
addBtn:SetPoint("LEFT", input, "RIGHT", 8, 0)
addBtn:SetScript("OnClick", function()
    local db = AC.DB and AC.DB.profile and AC.DB.profile.blackout
    if not db then 
        print("|cffDC2D2DArena Core:|r ERROR: Blackout database not found!")
        return 
    end
    
    -- CRITICAL: Ensure spells table exists
    if not db.spells then
        db.spells = {}
        print("|cffFFAA00Arena Core:|r Initialized empty spells table")
    end

    local text = input.input:GetText()
    if not text or text == "" then
        print("|cffDC2D2DArena Core:|r Please enter a Spell ID.")
        return
    end
    
    local spellID = tonumber(text)

    if not spellID then
        print("|cffDC2D2DArena Core:|r Input must be a numeric Spell ID.")
        return
    end

    -- Validate that the spell ID is real first (before duplicate check)
    local id, spellName = AC:GetSpellData(spellID)
    if not id or not spellName or spellName == "Unknown Spell" then
        print("|cffDC2D2DArena Core:|r Invalid Spell ID: " .. text .. " - Spell not found in game data.")
        return
    end
    
    -- Check for duplicates AFTER validation (so we have spell name for popup)
    for _, existingID in ipairs(db.spells) do
        if existingID == spellID then
            -- Show popup instead of chat message
            ShowDuplicatePopup(spellID, spellName)
            input.input:SetText("") -- Clear input field
            return
        end
    end
    
    -- Add the spell (validation already passed)
    table.insert(db.spells, id)
    
    -- FIXED: Force save to SavedVariables immediately
    if _G.ArenaCoreDB and _G.ArenaCoreDB.profile then
        _G.ArenaCoreDB.profile.blackout = _G.ArenaCoreDB.profile.blackout or {}
        _G.ArenaCoreDB.profile.blackout.spells = db.spells
    end
    
    input.input:SetText("")
    Editor:PopulateList() -- Refresh the UI to show the new spell
    print("|cff22AA44Arena Core:|r Added '" .. spellName .. "' (ID: " .. id .. ") to the Blackout list (SAVED).")
end)

    Editor.Frame = f
end

-- Global function to open the editor
function AC:OpenBlackoutEditor()
    if not Editor.Frame then Editor:Create() end
    -- FIX: Removed the problematic file-scoped db variable assignment

    if AC.configFrame then
        Editor.Frame:SetFrameLevel(AC.configFrame:GetFrameLevel() + 5)
    end

    Editor:PopulateList()
    Editor.Frame:Show()
    Editor.Frame:Raise()
end
