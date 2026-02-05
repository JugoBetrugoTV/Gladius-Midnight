-- Core/AurasWindow.lua --
-- CC Auras Configuration Window (Midnight)
-- Simplified for Midnight - Blizzard handles CC tracking natively
local AC = _G.ArenaCore
if not AC then return end

local aurasWindow = nil

-- Create the auras configuration window
local function CreateAurasWindow()
    if aurasWindow then return aurasWindow end
    
    -- Main window frame - smaller since we have fewer options
    local window = CreateFrame("Frame", "ArenaCoreAurasWindow", UIParent)
    window:SetSize(400, 280)
    window:SetPoint("CENTER")
    window:SetClampedToScreen(true)
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()
    
    -- Enable resizable UI with scale drag grips
    if AC.UIFeatures and AC.UIFeatures.EnableResizableUI then
        AC.UIFeatures:EnableResizableUI(window, "aurasWindowScale")
    end
    
    -- Background using ArenaCore styling
    local bg = AC:CreateFlatTexture(window, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
    bg:SetAllPoints()
    
    -- Border
    AC:AddWindowEdge(window, 1, 0)
    
    -- Header
    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT", 8, -8)
    header:SetPoint("TOPRIGHT", -8, -8)
    header:SetHeight(50)
    
    -- Header background
    local headerBg = AC:CreateFlatTexture(header, "BACKGROUND", 1, {0.102, 0.102, 0.102, 1}, 1)
    headerBg:SetAllPoints()
    
    -- Purple accent line
    local accent = AC:CreateFlatTexture(header, "OVERLAY", 3, AC.COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(2)
    
    -- Header border
    local hbLight = AC:CreateFlatTexture(header, "OVERLAY", 2, AC.COLORS.BORDER_LIGHT, 0.8)
    hbLight:SetPoint("BOTTOMLEFT", 0, 0)
    hbLight:SetPoint("BOTTOMRIGHT", 0, 0)
    hbLight:SetHeight(1)
    
    -- Title
    local title = AC:CreateStyledText(header, "CC Auras Configuration", 14, AC.COLORS.TEXT, "OVERLAY", "")
    title:SetPoint("LEFT", 15, 0)
    
    -- Close button
    local closeBtn = AC:CreateTexturedButton(header, 36, 36, "", "button-close")
    closeBtn:SetPoint("RIGHT", -10, 0)
    closeBtn:SetScript("OnClick", function()
        window:Hide()
    end)
    local xText = AC:CreateStyledText(closeBtn, "×", 18, AC.COLORS.TEXT, "OVERLAY", "")
    xText:SetPoint("CENTER", 0, 0)
    
    -- Content area
    local content = CreateFrame("Frame", nil, window)
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -15)
    content:SetPoint("BOTTOMRIGHT", -15, 15)
    
    -- Get CC auras setting from classIcons
    local function GetCCAurasEnabled()
        local db = AC.DB and AC.DB.profile and AC.DB.profile.classIcons
        -- Default to true if not set
        return db and db.showAuras ~= false
    end
    
    -- Get tooltips setting
    local function GetHideTooltips()
        local db = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.auras
        return db and db.hideTooltips == true
    end
    
    local y = -20
    
    -- Enable Crowd Control Auras checkbox
    local enableLabel = AC:CreateStyledText(content, "Enable Crowd Control Auras", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    enableLabel:SetPoint("TOPLEFT", 20, y)
    
    local enableCheckbox = AC:CreateFlatCheckbox(content, 20, GetCCAurasEnabled(), function(value)
        if not AC.DB or not AC.DB.profile then return end
        if not AC.DB.profile.classIcons then
            AC.DB.profile.classIcons = {}
        end
        AC.DB.profile.classIcons.showAuras = value
        
        if value then
            print("|cff8B45FFArena Core:|r CC Auras on class icons enabled")
        else
            print("|cff8B45FFArena Core:|r CC Auras on class icons disabled")
            -- Restore class icons when disabled
            if AC.ClassIconAuras and AC.ClassIconAuras.RestoreAll then
                AC.ClassIconAuras:RestoreAll()
            end
        end
    end)
    enableCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 35
    
    -- Description for CC auras
    local ccDesc = AC:CreateStyledText(content, "Shows crowd control effects (stuns, polymorphs, etc.) on the class icon with a cooldown spiral. Blizzard handles CC tracking natively in Midnight.", 10, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
    ccDesc:SetPoint("TOPLEFT", 20, y)
    ccDesc:SetPoint("TOPRIGHT", -20, y)
    ccDesc:SetJustifyH("LEFT")
    ccDesc:SetWordWrap(true)
    
    y = y - 50
    
    -- Hide Tooltips checkbox
    local tooltipLabel = AC:CreateStyledText(content, "Hide Tooltips", 12, AC.COLORS.TEXT_2, "OVERLAY", "")
    tooltipLabel:SetPoint("TOPLEFT", 20, y)
    
    local tooltipCheckbox = AC:CreateFlatCheckbox(content, 20, GetHideTooltips(), function(value)
        if not AC.DB or not AC.DB.profile then return end
        if not AC.DB.profile.moreGoodies then
            AC.DB.profile.moreGoodies = {}
        end
        if not AC.DB.profile.moreGoodies.auras then
            AC.DB.profile.moreGoodies.auras = {}
        end
        AC.DB.profile.moreGoodies.auras.hideTooltips = value
        
        if value then
            print("|cff8B45FFArena Core:|r Aura tooltips hidden")
        else
            print("|cff8B45FFArena Core:|r Aura tooltips enabled")
        end
    end)
    tooltipCheckbox:SetPoint("TOPRIGHT", -25, y)
    
    y = y - 40
    
    -- Test and Hide buttons
    local testBtn = AC:CreateTexturedButton(content, 80, 32, "TEST", "button-test")
    testBtn:SetPoint("TOPLEFT", 20, y)
    testBtn:SetScript("OnClick", function()
        -- Enable test mode on MasterFrameManager
        if AC.MasterFrameManager and AC.MasterFrameManager.EnableTestMode then
            AC.MasterFrameManager:EnableTestMode()
            print("|cff8B45FFArena Core:|r Test mode enabled - showing sample arena frames")
        end
    end)
    
    local hideBtn = AC:CreateTexturedButton(content, 80, 32, "HIDE", "button-hide")
    hideBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
    hideBtn:SetScript("OnClick", function()
        -- Disable test mode
        if AC.MasterFrameManager and AC.MasterFrameManager.DisableTestMode then
            AC.MasterFrameManager:DisableTestMode()
            print("|cff8B45FFArena Core:|r Test mode disabled")
        end
    end)
    
    aurasWindow = window
    return window
end

-- Show the auras window
function AC:ShowAurasWindow()
    local window = CreateAurasWindow()
    if window then
        window:Show()
    end
end

-- Legacy functions for compatibility (no-op in Midnight)
function AC:TestAuraTracking()
    if AC.MasterFrameManager and AC.MasterFrameManager.EnableTestMode then
        AC.MasterFrameManager:EnableTestMode()
    end
end

function AC:HideAuraTracking()
    if AC.MasterFrameManager and AC.MasterFrameManager.DisableTestMode then
        AC.MasterFrameManager:DisableTestMode()
    end
end
