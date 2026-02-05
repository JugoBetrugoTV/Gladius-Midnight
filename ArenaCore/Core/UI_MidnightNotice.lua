-- Core/UI_MidnightNotice.lua
-- Midnight Restriction Notice Component
local AC = _G.ArenaCore
if not AC then return end

AC.MidnightNotice = {}
local MidnightNotice = AC.MidnightNotice

-- ============================================================================
-- NOTICE COMPONENT
-- ============================================================================

function MidnightNotice:CreateNotice(parent, featureName)
    if not AC:IsMidnight() then
        return nil
    end
    
    -- Create overlay frame
    local notice = CreateFrame("Frame", nil, parent)
    notice:SetAllPoints(parent)
    notice:SetFrameLevel(parent:GetFrameLevel() + 100)
    notice:Hide() -- Hidden by default
    
    -- Light grey backdrop (no black overlay)
    local backdrop = AC:CreateFlatTexture(notice, "BACKGROUND", 1, {0.2, 0.2, 0.2, 0.95}, 1)
    backdrop:SetAllPoints()
    
    -- Content container (final size to prevent all clipping)
    local container = CreateFrame("Frame", nil, notice)
    container:SetSize(500, 360)
    container:SetPoint("TOP", 0, -80) -- Anchor to top with 80px offset from page top
    
    -- Container background
    local containerBg = AC:CreateFlatTexture(container, "BACKGROUND", 2, AC.COLORS.BG, 1)
    containerBg:SetAllPoints()
    
    -- Container border
    local containerBorder = AC:CreateFlatTexture(container, "BACKGROUND", 1, AC.COLORS.PRIMARY, 1)
    containerBorder:SetAllPoints()
    containerBg:SetPoint("TOPLEFT", 2, -2)
    containerBg:SetPoint("BOTTOMRIGHT", -2, 2)
    
    -- Warning icon (large)
    local icon = container:CreateTexture(nil, "ARTWORK")
    icon:SetSize(64, 64)
    icon:SetPoint("TOP", 0, -30)
    icon:SetAtlas("Crosshair_Important_128")
    icon:SetVertexColor(1, 0.6, 0, 1) -- Orange warning color
    
    -- Title (no emoji - we have graphic above)
    local title = AC:CreateStyledText(container, "MIDNIGHT RESTRICTIONS", 18, {1, 0.6, 0, 1}, "OVERLAY", "Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf")
    title:SetPoint("TOP", icon, "BOTTOM", 0, -15)
    
    -- Description text
    local desc = container:CreateFontString(nil, "OVERLAY")
    desc:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 12, "")
    desc:SetTextColor(0.9, 0.9, 0.9, 1)
    desc:SetPoint("TOP", title, "BOTTOM", 0, -20)
    desc:SetWidth(440)
    desc:SetJustifyH("CENTER")
    desc:SetSpacing(4)
    
    -- Feature-specific messages
    local messages = {
        blackout = "The Blackout feature is currently disabled during Arena matches\ndue to Blizzard's new addon restrictions in patch 12.0.\n\nWe're monitoring the situation and will restore functionality\nin a limited capacity as soon as possible.",
        
        classpacks = "The Class Packs feature is currently disabled during Arena matches\ndue to Blizzard's new addon restrictions in patch 12.0.\n\nThis feature tracks class-specific auras which has restrictions.\n\nWe're continuing to monitor API changes and will restore/create a watered down version in a very limited capacity as soon as possible. Join the Discord to stay in the loop!",
        
        moregoodies = "Some More Goodies features are currently disabled during Arena matches\ndue to Blizzard's new addon restrictions in patch 12.0.\n\nDisabled features: Debuffs Window, Dispel Window, Kick Bar\n\nWe're monitoring the situation and will restore functionality\nin a limited capacity as soon as possible.",
        
        default = "This feature is currently disabled during Arena matches\ndue to Blizzard's new addon restrictions in patch 12.0.\n\nWe're monitoring the situation and will restore functionality\nin a limited capacity as soon as possible."
    }
    
    local message = messages[featureName] or messages.default
    desc:SetText(message)
    
    -- Additional info text
    local info = AC:CreateStyledText(container, "You can still configure settings here for when restrictions are lifted.", 11, AC.COLORS.TEXT_MUTED, "OVERLAY", "")
    info:SetPoint("TOP", desc, "BOTTOM", 0, -20)
    info:SetWidth(440)
    info:SetJustifyH("CENTER")
    
    -- Close button (X) - positioned far within container bounds, red like main UI
    local closeBtn = CreateFrame("Button", nil, container)
    closeBtn:SetSize(32, 32)
    closeBtn:SetPoint("TOPRIGHT", -45, -45)
    
    -- Close button background (red like main UI)
    local closeBg = AC:CreateFlatTexture(closeBtn, "BACKGROUND", 1, {0.863, 0.176, 0.176, 1}, 1)
    closeBg:SetAllPoints()
    
    -- Close button X text
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 18, "")
    closeText:SetText("×")
    closeText:SetTextColor(1, 1, 1, 1)
    closeText:SetPoint("CENTER", 0, 1)
    
    -- Close button hover effects
    closeBtn:SetScript("OnEnter", function(self)
        closeBg:SetColorTexture(1, 0.4, 0.4, 1) -- Lighter red on hover
        closeText:SetTextColor(1, 1, 1, 1)
    end)
    
    closeBtn:SetScript("OnLeave", function(self)
        closeBg:SetColorTexture(0.863, 0.176, 0.176, 1) -- Main UI red
        closeText:SetTextColor(1, 1, 1, 1)
    end)
    
    closeBtn:SetScript("OnClick", function(self)
        notice:Hide()
    end)
    
    -- Understand button - positioned below the info text
    local understandBtn = AC:CreateTexturedButton(container, 180, 32, "I Understand", "UI\\tab-purple-matte")
    understandBtn:SetPoint("TOP", info, "BOTTOM", 0, -15)
    understandBtn:SetScript("OnClick", function()
        notice:Hide()
    end)
    
    -- Store reference
    notice.container = container
    notice.featureName = featureName
    
    return notice
end

-- ============================================================================
-- SHOW/HIDE FUNCTIONS
-- ============================================================================

function MidnightNotice:ShowNotice(parent, featureName)
    if not AC:IsMidnight() then
        return
    end
    
    -- Check if notice already exists
    if parent._midnightNotice then
        parent._midnightNotice:Show()
        return
    end
    
    -- Create new notice
    local notice = self:CreateNotice(parent, featureName)
    if notice then
        parent._midnightNotice = notice
        notice:Show()
    end
end

function MidnightNotice:HideNotice(parent)
    if parent._midnightNotice then
        parent._midnightNotice:Hide()
    end
end

-- ============================================================================
-- PAGE WRAPPER FUNCTION
-- ============================================================================

-- Wrap a page creation function to show notice if feature is restricted
function MidnightNotice:WrapPageCreation(createPageFunc, featureName)
    return function(parent)
        -- Call original page creation function
        local result = createPageFunc(parent)
        
        -- Show notice overlay if we're in Midnight and feature is restricted
        if AC:IsMidnight() and AC:ShouldDisableFeature(featureName) then
            self:ShowNotice(parent, featureName)
        end
        
        return result
    end
end

-- ============================================================================
-- HELPER: Check if we should show notice on page load
-- ============================================================================

function MidnightNotice:ShouldShowNoticeForPage(pageName)
    if not AC:IsMidnight() then
        return false
    end
    
    -- Map page names to feature names
    local pageToFeature = {
        ["Blackout"] = "blackout",
        ["ClassPacks"] = "classpacks",
        ["MoreGoodies"] = "moregoodies",
    }
    
    local featureName = pageToFeature[pageName]
    if not featureName then
        return false
    end
    
    -- Always show notice for these pages in Midnight (even if not currently restricted)
    -- This informs users that the feature may be disabled during arena matches
    return true
end
