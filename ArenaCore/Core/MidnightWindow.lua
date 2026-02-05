-- ============================================================================
-- File: ArenaCore/Core/MidnightWindow.lua
-- Purpose: MIDNIGHT expansion information window
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

-- Create the MIDNIGHT information window
function AC:ShowMidnightWindow()
    -- Close existing window if open
    if self.midnightWindow then
        self.midnightWindow:Hide()
        self.midnightWindow = nil
    end
    
    -- Create main window frame
    local window = CreateFrame("Frame", "ArenaCoreM idnightWindow", UIParent)
    window:SetSize(550, 520)
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetClampedToScreen(true)
    
    -- Outer border
    local outerBorder = window:CreateTexture(nil, "BACKGROUND")
    outerBorder:SetAllPoints()
    outerBorder:SetColorTexture(0.2, 0.2, 0.2, 1)
    
    -- Inner background (dark)
    local bg = window:CreateTexture(nil, "BORDER")
    bg:SetPoint("TOPLEFT", 2, -2)
    bg:SetPoint("BOTTOMRIGHT", -2, 2)
    bg:SetColorTexture(0.08, 0.08, 0.08, 0.98)
    
    -- Accent line at top (purple)
    local accent = window:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 2, -2)
    accent:SetPoint("TOPRIGHT", -2, -2)
    accent:SetHeight(2)
    accent:SetColorTexture(0.55, 0.35, 0.65, 1)
    
    -- Title
    local title = window:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 16, "OUTLINE")
    title:SetText("MIDNIGHT EXPANSION")
    title:SetTextColor(0.8, 0.6, 1.0, 1) -- Light purple
    title:SetPoint("TOP", window, "TOP", 0, -20)
    
    -- Alert icon (Crosshair_Important_128)
    local alertIcon = window:CreateTexture(nil, "OVERLAY")
    alertIcon:SetAtlas("Crosshair_Important_128")
    alertIcon:SetSize(40, 40)
    alertIcon:SetPoint("RIGHT", title, "LEFT", -10, 0)
    
    -- Divider line under title
    local divider1 = window:CreateTexture(nil, "ARTWORK")
    divider1:SetPoint("TOPLEFT", window, "TOPLEFT", 20, -55)
    divider1:SetPoint("TOPRIGHT", window, "TOPRIGHT", -20, -55)
    divider1:SetHeight(1)
    divider1:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    
    -- Message text (formatted like hotfix/alert text) - no scroll frame needed
    local messageText = window:CreateFontString(nil, "OVERLAY")
    messageText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 11)
    messageText:SetJustifyH("LEFT")
    messageText:SetJustifyV("TOP")
    messageText:SetWidth(500)
    messageText:SetPoint("TOPLEFT", window, "TOPLEFT", 25, -65)
    
    -- Format text with color coding (orange/yellow for emphasis like hotfixes)
    local messageContent = [[|cffFFAA00Arena Core|r, along with my other addons |cffFFAA00WILL be ported to Midnight expansion!|r I am actively working on it and in talks with certain people that are helping me forge the way for PvP in the next expansion.

|cffFFDD44I want people to know that Blizzard is giving developers active information before the public|r, including but not limited to API changes as well as their goals for the future beta releases etc.

|cffFF6644I can confirm we are NOT anywhere near the end stages of the changes|r, and there will continue to be massive changes coming in terms of what addons can do. |cffFFAA00THIS is also why I am not focusing on a beta release version of my addon|r, the truth is... |cffFF4444beta right now has broken API info|r, and anything I would create would not hold true to the Arena Core name and perfection that I put out.

|cffFFDD44I will not feed my users with half put together data.|r Most addons will break or give you false info in arena currently, so my main focus is keeping up with Retail, along with adapting each week behind the scenes to Midnight expansion.

|cff44FF44You WILL receive an insane version of Arena Core in Midnight|r, please be patient and join us all in |cff8855FFDiscord|r (it's been fun!) to learn more in detail about updates in real time, my thoughts, ideas and others voicing their suggestions as well!

|cffCCCCCC- Arena Core Development Team|r]]
    
    messageText:SetText(messageContent)
    
    -- Static image below Development Team text
    local imageFrame = CreateFrame("Frame", nil, window)
    imageFrame:SetSize(160, 120)
    imageFrame:SetPoint("BOTTOM", window, "BOTTOM", 0, 70)
    
    local imageTexture = imageFrame:CreateTexture(nil, "ARTWORK")
    imageTexture:SetAllPoints()
    imageTexture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\gif\\frame_2_delay-0.16s_result.png")
    imageTexture:SetTexCoord(0, 1, 0, 1)
    
    -- Divider line above buttons
    local divider2 = window:CreateTexture(nil, "ARTWORK")
    divider2:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 20, 50)
    divider2:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -20, 50)
    divider2:SetHeight(1)
    divider2:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    
    -- Discord button (purple styled) - left side
    local discordBtn = CreateFrame("Button", nil, window)
    discordBtn:SetSize(120, 32)
    discordBtn:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 80, 15)
    
    -- Background (purple)
    local discordBg = discordBtn:CreateTexture(nil, "BACKGROUND")
    discordBg:SetAllPoints()
    discordBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- ArenaCore PRIMARY purple
    
    -- Border (darker for depth)
    local discordBorder = discordBtn:CreateTexture(nil, "BORDER")
    discordBorder:SetPoint("TOPLEFT", 1, -1)
    discordBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    discordBorder:SetColorTexture(0.4, 0.2, 0.7, 1)
    
    -- Text
    local discordText = discordBtn:CreateFontString(nil, "OVERLAY")
    discordText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 11)
    discordText:SetText("Discord")
    discordText:SetTextColor(1, 1, 1, 1)
    discordText:SetPoint("CENTER")
    
    -- Hover effect
    discordBtn:SetScript("OnEnter", function()
        discordBg:SetColorTexture(0.645, 0.371, 1.000, 1) -- Lighter purple
    end)
    discordBtn:SetScript("OnLeave", function()
        discordBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- Original purple
    end)
    
    -- Click handler - print Discord link to chat with Arena Core prefix
    discordBtn:SetScript("OnClick", function()
        print("|cff8B45FFArena Core:|r https://AcDiscord.com (Discord Link)")
    end)
    
    -- Close button (purple styled) - right side
    local closeBtn = CreateFrame("Button", nil, window)
    closeBtn:SetSize(120, 32)
    closeBtn:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -80, 15)
    
    -- Background (purple)
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- ArenaCore PRIMARY purple
    
    -- Border (darker for depth)
    local closeBorder = closeBtn:CreateTexture(nil, "BORDER")
    closeBorder:SetPoint("TOPLEFT", 1, -1)
    closeBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    closeBorder:SetColorTexture(0.4, 0.2, 0.7, 1)
    
    -- Text
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 11)
    closeText:SetText("Close")
    closeText:SetTextColor(1, 1, 1, 1)
    closeText:SetPoint("CENTER")
    
    -- Hover effect
    closeBtn:SetScript("OnEnter", function()
        closeBg:SetColorTexture(0.645, 0.371, 1.000, 1) -- Lighter purple
    end)
    closeBtn:SetScript("OnLeave", function()
        closeBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- Original purple
    end)
    
    -- Close handler
    closeBtn:SetScript("OnClick", function()
        window:Hide()
        AC.midnightWindow = nil
    end)
    
    -- ESC key to close
    window:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            window:Hide()
            AC.midnightWindow = nil
        end
    end)
    
    -- Store reference
    self.midnightWindow = window
    window:Show()
end
