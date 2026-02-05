-- ============================================================================
-- ARENACORE DEBUG SYSTEM - Simple & Standalone
-- ============================================================================

-- Debug message storage
local debugMessages = {}
local debugFrame = nil

-- Simple function to add debug messages
local function AddDebugMessage(msg)
    table.insert(debugMessages, "[" .. date("%H:%M:%S") .. "] " .. msg)
    -- Keep only last 100 messages
    if #debugMessages > 100 then
        table.remove(debugMessages, 1)
    end
    -- Auto-update display if window is open (with safety check)
    if debugFrame and debugFrame:IsShown() and UpdateDebugDisplay then
        UpdateDebugDisplay()
    end
end

-- GLOBAL ArenaCore Debug Function - Always captures to debug window
_G.ArenaCore_Debug = function(...)
    local msg = ""
    for i = 1, select("#", ...) do
        if i > 1 then msg = msg .. " " end
        msg = msg .. tostring(select(i, ...))
    end
    AddDebugMessage("AC_DEBUG: " .. msg)
end

-- Initialize ArenaCore Debug system early
if not _G.ArenaCore then _G.ArenaCore = {} end
if not _G.ArenaCore.Debug then 
    _G.ArenaCore.Debug = {
        Print = function(self, ...)
            local msg = ""
            for i = 1, select("#", ...) do
                if i > 1 then msg = msg .. " " end
                msg = msg .. tostring(select(i, ...))
            end
            AddDebugMessage("AURA_DEBUG: " .. msg)
        end
    }
end

-- Debug functions removed - issue resolved (was texture file artifact, not code issue)

-- Simple function to update debug display
local function UpdateDebugDisplay()
    if not debugFrame or not debugFrame.editBox then return end

    local text = ""
    for i, msg in ipairs(debugMessages) do
        text = text .. msg .. "\n"
    end

    debugFrame.editBox.isUpdating = true
    debugFrame.editBox:SetText(text)
    debugFrame.editBox.originalText = text
    debugFrame.editBox.isUpdating = false

    -- Resize scroll child based on text height
    local lineHeight = 12
    local numLines = #debugMessages
    local height = math.max(numLines * lineHeight, 100)
    debugFrame.scrollChild:SetHeight(height)
end

-- RELEASE MODE: Minimal debug output - only capture critical errors and user-facing messages
local oldPrint = print
print = function(...)
    local msg = ""
    for i = 1, select("#", ...) do
        if i > 1 then msg = msg .. " " end
        msg = msg .. tostring(select(i, ...))
    end

    -- RELEASE: Only capture important user-facing messages and errors
    -- Protect against secret values in Midnight
    local success = pcall(function()
        if msg:find("Arena Core.*loaded") or 
           msg:find("Arena Core.*Discord") or
           msg:find("ERROR") or
           msg:find("Warning") or
           msg:find("Failed") or
           (msg:find("ArenaCore") and (msg:find("Error") or msg:find("Issue") or msg:find("Problem"))) then
            AddDebugMessage(msg)
        end
    end)
    -- If pcall fails (secret value), just skip debug capture

    oldPrint(...)
end

-- Create simple debug popup
local function CreateDebugPopup()
    if debugFrame then return debugFrame end

    debugFrame = CreateFrame("Frame", "ArenaCoreDebugPopup", UIParent, "BasicFrameTemplateWithInset")
    debugFrame:SetSize(600, 400)
    debugFrame:SetPoint("CENTER", 0, 0)
    debugFrame:SetFrameStrata("HIGH")
    debugFrame:SetMovable(true)
    debugFrame:EnableMouse(true)
    debugFrame:RegisterForDrag("LeftButton")
    debugFrame:SetScript("OnDragStart", debugFrame.StartMoving)
    debugFrame:SetScript("OnDragStop", debugFrame.StopMovingOrSizing)

    debugFrame.TitleText:SetText("ArenaCore Debug Log (Copy/Paste)")

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, debugFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    -- Scroll child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(550, 1000)
    scrollFrame:SetScrollChild(scrollChild)

    -- Edit box for copy/paste
    local editBox = CreateFrame("EditBox", nil, scrollChild)
    editBox:SetPoint("TOPLEFT", 0, 0)
    editBox:SetSize(550, 1000)
    editBox:SetFontObject("GameFontNormalSmall")
    editBox:SetTextColor(1, 1, 1, 1)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnTextChanged", function(self)
        if not self.isUpdating then
            self:SetText(self.originalText or "")
        end
    end)

    debugFrame.scrollChild = scrollChild
    debugFrame.editBox = editBox

    -- Close button
    local closeBtn = CreateFrame("Button", nil, debugFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() debugFrame:Hide() end)

    -- Clear button
    local clearBtn = CreateFrame("Button", nil, debugFrame, "UIPanelButtonTemplate")
    clearBtn:SetSize(80, 22)
    clearBtn:SetPoint("BOTTOMLEFT", 10, 10)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        debugMessages = {}
        UpdateDebugDisplay()
    end)

    -- Copy hint
    local hintText = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintText:SetPoint("BOTTOMRIGHT", -10, 15)
    hintText:SetText("Ctrl+A to select all, Ctrl+C to copy")
    hintText:SetTextColor(0.7, 0.7, 0.7, 1)

    return debugFrame
end

-- Show debug popup
local function ShowDebugPopup()
    local frame = CreateDebugPopup()
    UpdateDebugDisplay()
    frame:Show()
end

-- Register slash commands globally
SLASH_ARENACOREDEBUG1 = "/acdebug"
SlashCmdList.ARENACOREDEBUG = ShowDebugPopup

SLASH_ARENACORESTATUS1 = "/acstatus"
SlashCmdList.ARENACORESTATUS = function()
    print("|cff8B45FFArenaCore Status:|r")
    print("  Debug messages captured: " .. #debugMessages)
    print("  Debug popup created: " .. tostring(debugFrame ~= nil))
end

SLASH_PLAYERNAMEDEBUG1 = "/actestnames"
SlashCmdList.PLAYERNAMEDEBUG = function()
    -- Try multiple ways to access ProfileManager
    local pm
    if _G.ArenaCore and _G.ArenaCore.ProfileManager then
        pm = _G.ArenaCore.ProfileManager
    elseif AC and AC.ProfileManager then
        pm = AC.ProfileManager
    end
    
    if pm and pm.TestPlayerNameDebug then
        pm:TestPlayerNameDebug()
    else
        print("|cffFF0000ArenaCore:|r ProfileManager not ready. Try again after addon loads.")
    end
end

-- TriBadges test command
SLASH_TRIBADGETEST1 = "/actestbadges"
SlashCmdList.TRIBADGETEST = function()
    print("|cff00FFFFArenaCore TriBadges Test:|r Testing TriBadges system...")
    
    -- Check if TriBadges system exists
    if not _G.ArenaCore or not _G.ArenaCore.TriBadges then
        print("|cffFF0000Error:|r TriBadges system not found!")
        return
    end
    
    local TB = _G.ArenaCore.TriBadges
    print("|cff00FFFF[System]:|r TriBadges system found!")
    
    -- Check database (try multiple paths for new unified system)
    local dbFound = false
    local settings = nil
    
    -- Try _G.ArenaCoreDB first (new system)
    if _G.ArenaCoreDB and _G.ArenaCoreDB.profile and _G.ArenaCoreDB.profile.classPacks then
        settings = _G.ArenaCoreDB.profile.classPacks
        dbFound = true
        print("|cff00FFFF[Database]:|r Found in _G.ArenaCoreDB")
    -- Try AC.DB (old system)
    elseif AC and AC.DB and AC.DB.profile and AC.DB.profile.classPacks then
        settings = AC.DB.profile.classPacks
        dbFound = true
        print("|cff00FFFF[Database]:|r Found in AC.DB")
    end
    
    if dbFound and settings then
        local enabled = settings.enabled
        print("|cff00FFFF[Settings]:|r enabled=" .. tostring(enabled) ..
              " size=" .. (settings.size or "nil") .. 
              " spacing=" .. (settings.spacing or "nil") .. 
              " offsetX=" .. (settings.offsetX or "nil") .. 
              " offsetY=" .. (settings.offsetY or "nil"))
    else
        print("|cffFF0000Error:|r Database not found in either location!")
    end
    
    -- Check if frames exist (try multiple locations for new unified system)
    print("|cff00FFFF[Debug]:|r Looking for frames...")
    
    local framesFound = false
    local frames = nil
    
    -- Try global frame names first (most reliable)
    if _G["ArenaCore_ArenaFrame1"] then
        frames = {_G["ArenaCore_ArenaFrame1"], _G["ArenaCore_ArenaFrame2"], _G["ArenaCore_ArenaFrame3"]}
        framesFound = true
        print("|cff00FFFF[Frames]:|r Found via global frame names")
    -- Try new unified system
    elseif _G.ArenaCore and _G.ArenaCore.FrameManager and _G.ArenaCore.FrameManager.frames then
        frames = _G.ArenaCore.FrameManager.frames
        framesFound = true
        print("|cff00FFFF[Frames]:|r Found in FrameManager.frames")
    -- Try old system
    elseif AC and AC.arenaFrames then
        frames = AC.arenaFrames
        framesFound = true
        print("|cff00FFFF[Frames]:|r Found in AC.arenaFrames")
    else
        print("|cffFF0000[Debug]:|r No frames found in any location!")
    end
    
    if framesFound and frames then
        for i = 1, 3 do
            local frame = frames[i]
            if frame then
                local hasTriBadges = frame.TriBadges ~= nil
                print("|cff00FFFF[Frame " .. i .. "]:|r exists=" .. tostring(frame ~= nil) .. 
                      " hasTriBadges=" .. tostring(hasTriBadges))
                      
                if hasTriBadges then
                    for j = 1, 3 do
                        local badge = frame.TriBadges[j]
                        if badge then
                            print("  Badge " .. j .. ": shown=" .. tostring(badge:IsShown()) .. 
                                  " alpha=" .. badge:GetAlpha())
                        end
                    end
                end
            end
        end
    else
        print("|cffFF0000Error:|r No arena frames found in any location!")
    end
    
    -- Force refresh
    if TB.RefreshAll then
        TB:RefreshAll()
        print("|cff00FF00Success:|r TriBadges refresh triggered!")
    else
        print("|cffFF0000Error:|r RefreshAll function not found!")
    end
end

-- Simple TriBadges check command
SLASH_TRIBADGECHECK1 = "/accheckbadges"
SlashCmdList.TRIBADGECHECK = function()
    print("=== SIMPLE TRIBADGES CHECK ===")
    
    -- Check if frame 1 exists
    local frame1 = _G["ArenaCore_ArenaFrame1"]
    print("Frame1 exists: " .. tostring(frame1 ~= nil))
    
    if frame1 then
        print("Frame1 has TriBadges: " .. tostring(frame1.TriBadges ~= nil))
        if frame1.TriBadges then
            for i = 1, 3 do
                local badge = frame1.TriBadges[i]
                if badge then
                    print("Badge " .. i .. " - Shown: " .. tostring(badge:IsShown()) .. " Alpha: " .. badge:GetAlpha())
                end
            end
        end
    end
    
    -- Check database
    if _G.ArenaCoreDB and _G.ArenaCoreDB.profile and _G.ArenaCoreDB.profile.classPacks then
        local cp = _G.ArenaCoreDB.profile.classPacks
        print("ClassPacks enabled: " .. tostring(cp.enabled))
    else
        print("No classPacks database found")
    end
    
    -- Check test mode
    if _G.ArenaCore then
        print("testModeEnabled: " .. tostring(_G.ArenaCore.testModeEnabled))
    end
end

-- Simple DR check command
SLASH_DRCHECK1 = "/accheckdr"
SlashCmdList.DRCHECK = function()
    print("=== SIMPLE DR CHECK ===")
    
    -- Check if frame 1 exists
    local frame1 = _G["ArenaCore_ArenaFrame1"]
    print("Frame1 exists: " .. tostring(frame1 ~= nil))
    
    if frame1 then
        print("Frame1 has drIcons: " .. tostring(frame1.drIcons ~= nil))
        if frame1.drIcons then
            local count = 0
            for category, drFrame in pairs(frame1.drIcons) do
                count = count + 1
                print("DR " .. category .. " - Shown: " .. tostring(drFrame:IsShown()) .. " Alpha: " .. drFrame:GetAlpha())
            end
            print("Total DR icons: " .. count)
        end
    end
    
    -- Check database
    if _G.ArenaCoreDB and _G.ArenaCoreDB.profile and _G.ArenaCoreDB.profile.diminishingReturns then
        local dr = _G.ArenaCoreDB.profile.diminishingReturns
        print("DR enabled: " .. tostring(dr.enabled))
    else
        print("No DR database found")
    end
    
    -- Check test mode
    if _G.ArenaCore then
        print("testModeEnabled: " .. tostring(_G.ArenaCore.testModeEnabled))
    end
end

-- Force DR refresh command
SLASH_DRFORCE1 = "/acforcedr"
SlashCmdList.DRFORCE = function()
    print("|cff00FFFFArenaCore:|r Forcing DR refresh...")
    
    -- Force enable in database
    if _G.ArenaCoreDB and _G.ArenaCoreDB.profile then
        _G.ArenaCoreDB.profile.diminishingReturns = _G.ArenaCoreDB.profile.diminishingReturns or {}
        _G.ArenaCoreDB.profile.diminishingReturns.enabled = true
        print("|cff00FF00Success:|r DR enabled set to true")
    end
    
    -- Force refresh DR
    if AC and AC.RefreshDRLayout then
        AC:RefreshDRLayout()
        print("|cff00FF00Success:|r DR layout refreshed!")
    end
end

-- Simple TriBadges force enable command
SLASH_TRIBADGEFORCE1 = "/acforcebadges"
SlashCmdList.TRIBADGEFORCE = function()
    print("|cff00FFFFArenaCore:|r Forcing TriBadges enable...")
    
    -- Force enable in database
    if _G.ArenaCoreDB and _G.ArenaCoreDB.profile then
        _G.ArenaCoreDB.profile.classPacks = _G.ArenaCoreDB.profile.classPacks or {}
        _G.ArenaCoreDB.profile.classPacks.enabled = true
        print("|cff00FF00Success:|r classPacks.enabled set to true")
    end
    
    -- Force test mode flag
    if _G.ArenaCore then
        _G.ArenaCore.testModeEnabled = true
        print("|cff00FF00Success:|r testModeEnabled set to true")
    end
    
    -- Force refresh TriBadges
    if _G.ArenaCore and _G.ArenaCore.TriBadges and _G.ArenaCore.TriBadges.RefreshAll then
        _G.ArenaCore.TriBadges:RefreshAll()
        print("|cff00FF00Success:|r TriBadges refreshed!")
    end
end

-- Settings persistence test command
SLASH_ACPERSIST1 = "/acpersist"
SlashCmdList.ACPERSIST = function()
    print("|cff00FFFFArenaCore Settings Persistence Test:|r")
    
    local AC = _G.ArenaCore
    if not AC then
        print("|cffFF0000Error:|r ArenaCore not loaded!")
        return
    end
    
    -- Check database structure
    if not AC.DB or not AC.DB.profile then
        print("|cffFF0000Error:|r No database found!")
        return
    end
    
    -- Check arenaFrames structure
    local af = AC.DB.profile.arenaFrames
    if not af then
        print("|cffFF0000Error:|r No arenaFrames settings found!")
        return
    end
    
    -- Show current positioning
    local pos = af.positioning
    if pos then
        print("|cff00FF00Positioning:|r X=" .. (pos.horizontal or "nil") .. ", Y=" .. (pos.vertical or "nil") .. ", Spacing=" .. (pos.spacing or "nil"))
    else
        print("|cffFFAA00Warning:|r No positioning data found")
    end
    
    -- Show current sizing
    local sizing = af.sizing
    if sizing then
        print("|cff00FF00Sizing:|r Scale=" .. (sizing.scale or "nil") .. ", Width=" .. (sizing.width or "nil") .. ", Height=" .. (sizing.height or "nil"))
    else
        print("|cffFFAA00Warning:|r No sizing data found")
    end
    
    -- Show theme data
    local themeName = AC.ArenaFrameThemes and AC.ArenaFrameThemes:GetCurrentTheme()
    if themeName then
        print("|cff00FF00Current Theme:|r " .. themeName)
        
        local themeData = AC.DB.profile.themeData and AC.DB.profile.themeData[themeName]
        if themeData and themeData.arenaFrames then
            local themePos = themeData.arenaFrames.positioning
            if themePos then
                print("|cff00FF00Theme Positioning:|r X=" .. (themePos.horizontal or "nil") .. ", Y=" .. (themePos.vertical or "nil"))
            end
        end
    end
    
    -- Show protection status
    if AC._recentUserChange then
        print("|cffFFFF00Protection Active:|r Recent user changes detected (5-second protection)")
    else
        print("|cff00FF00Protection Status:|r No recent user changes")
    end
    
    print("|cff00FFFFTip:|r Move a slider, then run /acpersist again to see protection activate")
end

-- Debug system loaded message disabled for release
-- print("|cff22AA44ArenaCore:|r Debug system loaded - use /acdebug to view")
