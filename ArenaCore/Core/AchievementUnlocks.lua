-- ============================================================================
-- File: ArenaCore/Core/AchievementUnlocks.lua
-- Purpose: Rating-based achievement tracking and theme unlock system
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

-- ============================================================================
-- SEASON & ACHIEVEMENT CONFIGURATION
-- ============================================================================

-- Current active season (TWW Season 3)
local CURRENT_SEASON = 3

-- Achievement IDs for each season and rating threshold
-- IMPORTANT: Update these IDs at the start of each new season!
-- To find achievement IDs: Shift+Click achievement in Achievement panel
-- Or check Wowhead for "Duelist: The War Within Season X" achievements
local SEASON_ACHIEVEMENT_IDS = {
    -- TWW Season 1
    [1] = {
        [2100] = nil, -- Historical - not tracked
        [2400] = nil, -- Historical - not tracked
        [3000] = nil, -- Historical - not tracked
    },
    -- TWW Season 2
    [2] = {
        [2100] = nil, -- Historical - not tracked
        [2400] = nil, -- Historical - not tracked
        [3000] = nil, -- Historical - not tracked
    },
    -- TWW Season 3 (CURRENT)
    [3] = {
        [2100] = 41026, -- Duelist: The War Within Season 3
        [2400] = nil,   -- TODO: Add Gladiator achievement ID later
        [3000] = nil,   -- TODO: Add Rank 1 achievement ID later
    },
    -- Future seasons will be added here
}

-- Theme unlock mapping: rating threshold -> theme ID
local RATING_THEME_UNLOCKS = {
    [2100] = "shade_ui",        -- Shade UI theme (2100 rating)
    [2400] = "elite_2400",      -- Elite theme (2400 rating)
    [3000] = "rank1_3000",      -- Rank 1 theme (3000 rating)
}

-- Friendly names for rating thresholds (displayed to users)
local RATING_NAMES = {
    [2100] = "Shade UI",
    [2400] = "Elite",
    [3000] = "Rank 1",
}

-- ============================================================================
-- DATABASE INITIALIZATION
-- ============================================================================

-- Initialize achievement unlock database structure
function AC:InitializeAchievementUnlockDB()
    if not self.DB or not self.DB.profile then
        print("|cffFF0000ArenaCore:|r Database not initialized for achievement unlocks!")
        return
    end
    
    -- ACCOUNT-WIDE STORAGE (shared across all characters)
    -- This bypasses WoW's broken account-wide achievement API
    if not _G.ArenaCoreDB.global then
        _G.ArenaCoreDB.global = {}
    end
    
    if not _G.ArenaCoreDB.global.achievementUnlocks then
        _G.ArenaCoreDB.global.achievementUnlocks = {}
    end
    
    local globalUnlocks = _G.ArenaCoreDB.global.achievementUnlocks
    
    -- Unlocked themes (ACCOUNT-WIDE - works on all characters!)
    if not globalUnlocks.themes then
        globalUnlocks.themes = {
            ["shade_ui"] = false,       -- Shade UI (2100 rating)
            ["elite_2400"] = false,     -- Elite (2400 rating)
            ["rank1_3000"] = false,     -- Rank 1 theme (3000 rating)
        }
    end
    
    -- MIGRATION: Rename old theme IDs to new ones
    -- Step 1: Migrate gladiator_2100 → shade_ui
    if globalUnlocks.themes["gladiator_2100"] ~= nil then
        globalUnlocks.themes["shade_ui"] = globalUnlocks.themes["gladiator_2100"]
        globalUnlocks.themes["gladiator_2100"] = nil
        
        if globalUnlocks.unlockedByCharacter and globalUnlocks.unlockedByCharacter["gladiator_2100"] then
            globalUnlocks.unlockedByCharacter["shade_ui"] = globalUnlocks.unlockedByCharacter["gladiator_2100"]
            globalUnlocks.unlockedByCharacter["gladiator_2100"] = nil
        end
        
        print("|cff8B45FFArenaCore:|r Migrated gladiator_2100 theme to shade_ui")
    end
    
    -- Step 2: Migrate black_reaper → shade_ui (fixes affected users)
    if globalUnlocks.themes["black_reaper"] ~= nil then
        globalUnlocks.themes["shade_ui"] = globalUnlocks.themes["black_reaper"]
        globalUnlocks.themes["black_reaper"] = nil
        
        if globalUnlocks.unlockedByCharacter and globalUnlocks.unlockedByCharacter["black_reaper"] then
            globalUnlocks.unlockedByCharacter["shade_ui"] = globalUnlocks.unlockedByCharacter["black_reaper"]
            globalUnlocks.unlockedByCharacter["black_reaper"] = nil
        end
        
        print("|cff8B45FFArenaCore:|r Migrated black_reaper theme to shade_ui")
    end
    
    -- Track achievement history (ACCOUNT-WIDE)
    if not globalUnlocks.achievementHistory then
        globalUnlocks.achievementHistory = {}
    end
    
    -- Track which character unlocked each theme (for display purposes)
    if not globalUnlocks.unlockedByCharacter then
        globalUnlocks.unlockedByCharacter = {}
    end
    
    -- Track current season (ACCOUNT-WIDE)
    if not globalUnlocks.lastCheckedSeason then
        globalUnlocks.lastCheckedSeason = 0
    end
    
    -- PER-CHARACTER STORAGE (for notification tracking)
    if not _G.ArenaCoreCharDB then
        _G.ArenaCoreCharDB = {}
    end
    
    if not _G.ArenaCoreCharDB.achievementUnlocks then
        _G.ArenaCoreCharDB.achievementUnlocks = {}
    end
    
    local charUnlocks = _G.ArenaCoreCharDB.achievementUnlocks
    
    -- Track which popups we've shown on THIS character (prevent spam)
    if not charUnlocks.notificationsShown then
        charUnlocks.notificationsShown = {
            ["2100"] = false,
            ["2400"] = false,
            ["3000"] = false,
        }
    end
    
    -- Disabled startup message for end users
    -- print("|cff8B45FFArenaCore:|r Achievement unlock system initialized (account-wide)")
end

-- ============================================================================
-- ACHIEVEMENT VERIFICATION
-- ============================================================================

-- Check if player has a specific achievement (account-wide)
-- Returns: completed (bool), wasEarnedByMe (bool), achievementInfo (table)
function AC:HasAchievement(achievementID)
    if not achievementID or achievementID == 0 then
        return false, false, nil
    end
    
    -- Validate achievement exists
    if not C_AchievementInfo.IsValidAchievement(achievementID) then
        return false, false, nil
    end
    
    -- Get achievement info
    local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuildAch, wasEarnedByMe = GetAchievementInfo(achievementID)
    
    if not id then
        return false, false, nil
    end
    
    local achievementInfo = {
        id = id,
        name = name,
        points = points,
        completed = completed,
        month = month,
        day = day,
        year = year,
        description = description,
        icon = icon,
        rewardText = rewardText,
        isGuildAch = isGuildAch,
        wasEarnedByMe = wasEarnedByMe,
    }
    
    return completed, wasEarnedByMe, achievementInfo
end

-- Check if player has rating achievement for current season
-- Returns: hasAchievement (bool), themeID (string), achievementInfo (table)
function AC:CheckRatingAchievement(ratingThreshold)
    local season = CURRENT_SEASON
    
    -- Get achievement ID for this season and rating
    if not SEASON_ACHIEVEMENT_IDS[season] then
        return false, nil, nil
    end
    
    local achievementID = SEASON_ACHIEVEMENT_IDS[season][ratingThreshold]
    if not achievementID then
        return false, nil, nil
    end
    
    -- Check if player has the achievement
    local completed, wasEarnedByMe, achievementInfo = self:HasAchievement(achievementID)
    
    -- Must be completed AND earned by this account (account-wide check)
    local hasAchievement = completed and wasEarnedByMe
    
    -- Get corresponding theme ID
    local themeID = RATING_THEME_UNLOCKS[ratingThreshold]
    
    return hasAchievement, themeID, achievementInfo
end

-- Verify rating via API (backup check - not primary unlock method)
-- This is a safety check to ensure achievement matches actual rating
function AC:VerifyRatingThreshold(threshold)
    local hasRating = false
    
    -- Check all rated brackets
    -- Bracket indexes: 1=2v2, 2=3v3, 3=5v5 (legacy), 4=RBG, 7=Solo Shuffle
    local brackets = {1, 2, 4, 7} -- 2v2, 3v3, RBG, Solo Shuffle
    
    for _, bracketIndex in ipairs(brackets) do
        local rating, seasonBest, weeklyBest, seasonPlayed, seasonWon = GetPersonalRatedInfo(bracketIndex)
        
        -- Check season best (highest rating this season)
        if seasonBest and seasonBest >= threshold then
            hasRating = true
            break
        end
    end
    
    return hasRating
end

-- ============================================================================
-- THEME UNLOCK LOGIC
-- ============================================================================

-- Unlock a theme based on rating achievement
-- Returns: success (bool), alreadyUnlocked (bool)
function AC:UnlockTheme(ratingThreshold, skipNotification)
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.global or not _G.ArenaCoreDB.global.achievementUnlocks then
        return false, false
    end
    
    -- Check if player has the achievement
    local hasAchievement, themeID, achievementInfo = self:CheckRatingAchievement(ratingThreshold)
    
    if not hasAchievement then
        return false, false
    end
    
    -- Check if already unlocked (ACCOUNT-WIDE)
    local globalUnlocks = _G.ArenaCoreDB.global.achievementUnlocks
    local alreadyUnlocked = globalUnlocks.themes[themeID] == true
    
    if alreadyUnlocked then
        return true, true
    end
    
    -- UNLOCK THE THEME (ACCOUNT-WIDE)!
    globalUnlocks.themes[themeID] = true
    
    -- Record which character unlocked it
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local characterKey = playerName .. "-" .. realmName
    
    if not globalUnlocks.unlockedByCharacter[themeID] then
        globalUnlocks.unlockedByCharacter[themeID] = characterKey
    end
    
    -- Record achievement history (ACCOUNT-WIDE)
    table.insert(globalUnlocks.achievementHistory, {
        themeID = themeID,
        rating = ratingThreshold,
        achievementID = achievementInfo.id,
        achievementName = achievementInfo.name,
        unlockedAt = time(),
        season = CURRENT_SEASON,
        unlockedBy = characterKey,
    })
    
    -- Show notification popup (unless skipped)
    if not skipNotification then
        self:ShowThemeUnlockNotification(ratingThreshold, themeID, achievementInfo)
    end
    
    print(string.format("|cff8B45FFArenaCore:|r Theme unlocked ACCOUNT-WIDE: %s (%d rating)", themeID, ratingThreshold))
    
    return true, false
end

-- Check if a theme is unlocked (ACCOUNT-WIDE)
function AC:IsThemeUnlocked(themeID)
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.global or not _G.ArenaCoreDB.global.achievementUnlocks then
        return false
    end
    
    return _G.ArenaCoreDB.global.achievementUnlocks.themes[themeID] == true
end

-- ============================================================================
-- ACHIEVEMENT SCANNING
-- ============================================================================

-- Scan all rating achievements for current season (called on login)
function AC:ScanRatingAchievements()
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.global or not _G.ArenaCoreDB.global.achievementUnlocks then
        print("|cffFF0000ArenaCore:|r Achievement unlock database not initialized!")
        return
    end
    
    local globalUnlocks = _G.ArenaCoreDB.global.achievementUnlocks
    local charUnlocks = _G.ArenaCoreCharDB and _G.ArenaCoreCharDB.achievementUnlocks
    local currentSeason = C_PvP.GetUIDisplaySeason() or CURRENT_SEASON
    
    -- Check if we've already scanned this season
    local isNewSeason = globalUnlocks.lastCheckedSeason ~= currentSeason
    globalUnlocks.lastCheckedSeason = currentSeason
    
    print(string.format("|cff8B45FFArena Core: |r Scanning rating achievements for Season %d...", currentSeason))
    
    local unlockedCount = 0
    local newUnlocks = {}
    
    -- Check each rating threshold
    for rating, themeID in pairs(RATING_THEME_UNLOCKS) do
        local hasAchievement, themeIDResult, achievementInfo = self:CheckRatingAchievement(rating)
        
        if hasAchievement then
            local alreadyUnlocked = globalUnlocks.themes[themeID] == true
            
            if not alreadyUnlocked then
                -- NEW UNLOCK!
                local success, wasAlreadyUnlocked = self:UnlockTheme(rating, false)
                
                if success and not wasAlreadyUnlocked then
                    table.insert(newUnlocks, {
                        rating = rating,
                        themeID = themeID,
                        name = RATING_NAMES[rating] or tostring(rating),
                    })
                    unlockedCount = unlockedCount + 1
                end
            else
                -- Already unlocked account-wide
                -- Check if THIS character has seen the notification
                local hasSeenNotification = charUnlocks and charUnlocks.notificationsShown[tostring(rating)] == true
                
                if not hasSeenNotification then
                    -- Show "already unlocked" message for this character
                    local unlockedBy = globalUnlocks.unlockedByCharacter[themeID] or "another character"
                    print(string.format("  |A:VAS-icon-checkmark-glw:16:16|a %s (%d) - Already unlocked by %s", RATING_NAMES[rating], rating, unlockedBy))
                    
                    -- Mark as shown for this character
                    if charUnlocks then
                        charUnlocks.notificationsShown[tostring(rating)] = true
                    end
                else
                    print(string.format("  |A:VAS-icon-checkmark-glw:16:16|a %s (%d) - Already unlocked", RATING_NAMES[rating], rating))
                end
            end
        end
    end
    
    -- Summary
    if unlockedCount > 0 then
        print(string.format("|cff00FF00Arena Core: |r %d new theme(s) unlocked ACCOUNT-WIDE!", unlockedCount))
    else
        print("|cff8B45FFArena Core: |r No new themes unlocked")
    end
    
    return newUnlocks
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Handle ACHIEVEMENT_EARNED event (real-time unlock)
function AC:OnAchievementEarned(achievementID, alreadyEarned)
    if not achievementID then return end
    
    -- Check if this is a rating achievement we care about
    local season = CURRENT_SEASON
    
    if not SEASON_ACHIEVEMENT_IDS[season] then return end
    
    for rating, achID in pairs(SEASON_ACHIEVEMENT_IDS[season]) do
        if achID == achievementID then
            -- This is a rating achievement we track!
            print(string.format("|cff8B45FFArenaCore:|r Rating achievement earned: %d!", rating))
            
            -- Unlock the theme
            local success, wasAlreadyUnlocked = self:UnlockTheme(rating, false)
            
            if success and not wasAlreadyUnlocked then
                print(string.format("|cffFFD700ArenaCore:|r NEW THEME UNLOCKED: %s!", RATING_NAMES[rating]))
            end
            
            break
        end
    end
end

-- ============================================================================
-- NOTIFICATION SYSTEM - Custom Popup UI
-- ============================================================================

-- Create the unlock popup frame (only once)
local unlockPopup = nil

local function CreateUnlockPopup()
    if unlockPopup then return unlockPopup end
    
    -- Main container frame (transparent, just for grouping)
    local frame = CreateFrame("Frame", "ArenaCoreUnlockPopup", UIParent)
    frame:SetSize(800, 450) -- Width matches your graphic (800px)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:Hide()
    
    -- Make it draggable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Custom graphic (Black Reaper unlock PNG - EXACT dimensions, no stretching!)
    frame.graphic = frame:CreateTexture(nil, "ARTWORK", nil, 7)
    frame.graphic:SetSize(800, 280) -- EXACT original size - 800x280!
    frame.graphic:SetPoint("TOP", frame, "TOP", 0, 0)
    frame.graphic:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Achievements\\black_reaper_unlock.png")
    
    -- Close button (custom ArenaCore red X button) - REPOSITIONED closer to popup
    frame.closeButton = CreateFrame("Button", nil, frame)
    frame.closeButton:SetSize(36, 36)
    frame.closeButton:SetPoint("TOPRIGHT", frame.graphic, "TOPRIGHT", -15, -15) -- Moved inside graphic bounds for visibility
    frame.closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    frame.closeButton:EnableMouse(true)
    frame.closeButton:RegisterForClicks("LeftButtonUp")
    
    -- Close button background (red texture)
    local closeBg = frame.closeButton:CreateTexture(nil, "BACKGROUND")
    closeBg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-close.tga")
    closeBg:SetAllPoints()
    
    -- Close button highlight (glow on hover)
    local closeHighlight = frame.closeButton:CreateTexture(nil, "HIGHLIGHT")
    closeHighlight:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\button-close.tga")
    closeHighlight:SetAllPoints()
    closeHighlight:SetBlendMode("ADD")
    closeHighlight:SetAlpha(0.3)
    frame.closeButton:SetHighlightTexture(closeHighlight)
    
    -- Close button X text (white)
    local closeText = frame.closeButton:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 18, "")
    closeText:SetPoint("CENTER", 0, 0)
    closeText:SetText("×")
    closeText:SetTextColor(1, 1, 1, 1)
    
    frame.closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Info box below graphic (ArenaCore dark style - NARROWER)
    -- HIDDEN: User requested to only show custom graphic, not the info box
    frame.infoBox = CreateFrame("Frame", nil, frame)
    frame.infoBox:SetSize(500, 120) -- Much narrower for cleaner look
    frame.infoBox:SetPoint("TOP", frame.graphic, "BOTTOM", 0, -10)
    frame.infoBox:Hide()  -- Hide the info box - only show custom graphic
    
    -- Info box background (dark ArenaCore style)
    frame.infoBox.bg = frame.infoBox:CreateTexture(nil, "BACKGROUND")
    frame.infoBox.bg:SetAllPoints()
    frame.infoBox.bg:SetColorTexture(0.102, 0.102, 0.102, 0.95) -- ArenaCore dark bg
    
    -- Outer purple accent border (signature ArenaCore style!)
    frame.infoBox.purpleBorder = frame.infoBox:CreateTexture(nil, "BORDER")
    frame.infoBox.purpleBorder:SetAllPoints()
    frame.infoBox.purpleBorder:SetColorTexture(0.545, 0.271, 1.000, 1) -- ArenaCore purple #8B45FF
    frame.infoBox.purpleBorder:SetDrawLayer("BORDER", 0)
    
    -- Inner dark border (creates the outline effect)
    frame.infoBox.innerBorder = frame.infoBox:CreateTexture(nil, "BORDER")
    frame.infoBox.innerBorder:SetPoint("TOPLEFT", 2, -2)
    frame.infoBox.innerBorder:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.infoBox.innerBorder:SetColorTexture(0.102, 0.102, 0.102, 0.95)
    frame.infoBox.innerBorder:SetDrawLayer("BORDER", 1)
    
    -- Subtle inner glow (makes it pop!)
    frame.infoBox.glow = frame.infoBox:CreateTexture(nil, "ARTWORK")
    frame.infoBox.glow:SetPoint("TOPLEFT", 2, -2)
    frame.infoBox.glow:SetPoint("TOPRIGHT", -2, -2)
    frame.infoBox.glow:SetHeight(30)
    frame.infoBox.glow:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\gradient-vertical.tga")
    frame.infoBox.glow:SetVertexColor(0.545, 0.271, 1.000, 0.15) -- Subtle purple glow
    frame.infoBox.glow:SetDrawLayer("ARTWORK", 0)
    
    -- Rating text (white, centered)
    frame.ratingText = frame.infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.ratingText:SetPoint("TOP", frame.infoBox, "TOP", 0, -15)
    frame.ratingText:SetTextColor(1, 1, 1, 1)
    
    -- Theme name text (purple ArenaCore accent)
    frame.themeText = frame.infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    frame.themeText:SetPoint("TOP", frame.ratingText, "BOTTOM", 0, -8)
    frame.themeText:SetTextColor(0.545, 0.271, 1.000, 1) -- ArenaCore purple
    
    -- Description text (muted)
    frame.descText = frame.infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.descText:SetPoint("TOP", frame.themeText, "BOTTOM", 0, -8)
    frame.descText:SetText("This exclusive theme is now available!")
    frame.descText:SetTextColor(0.706, 0.706, 0.706, 1) -- ArenaCore muted text
    
    -- Activate Theme button (custom ArenaCore purple button)
    frame.activateButton = CreateFrame("Button", nil, frame.infoBox)
    frame.activateButton:SetSize(180, 32)
    frame.activateButton:SetPoint("BOTTOM", frame.infoBox, "BOTTOM", 0, 10)
    frame.activateButton:EnableMouse(true)
    frame.activateButton:RegisterForClicks("LeftButtonUp")
    
    -- Purple button background texture
    local btnBg = frame.activateButton:CreateTexture(nil, "BACKGROUND")
    btnBg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\tab-purple-matte.tga")
    btnBg:SetAllPoints()
    
    -- Purple button highlight (glow on hover)
    local btnHighlight = frame.activateButton:CreateTexture(nil, "HIGHLIGHT")
    btnHighlight:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\tab-purple-matte.tga")
    btnHighlight:SetAllPoints()
    btnHighlight:SetBlendMode("ADD")
    btnHighlight:SetAlpha(0.3)
    frame.activateButton:SetHighlightTexture(btnHighlight)
    
    -- Button text (white, ArenaCore font)
    local btnText = frame.activateButton:CreateFontString(nil, "OVERLAY")
    btnText:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", 13, "")
    btnText:SetPoint("CENTER", 0, 0)
    btnText:SetText("Activate Theme")
    btnText:SetTextColor(1, 1, 1, 1) -- Pure white
    
    frame.activateButton:SetScript("OnClick", function()
        -- TODO: Open theme settings page when theme system is built
        print("|cff8B45FFArenaCore:|r Theme activation coming soon! Check /arena settings.")
        frame:Hide()
    end)
    
    -- Glow animation (subtle, around graphic only)
    frame.glow = frame:CreateTexture(nil, "BACKGROUND")
    frame.glow:SetSize(820, 300) -- Slightly larger than graphic (800x280)
    frame.glow:SetPoint("CENTER", frame.graphic, "CENTER")
    frame.glow:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Glow")
    frame.glow:SetBlendMode("ADD")
    frame.glow:SetAlpha(0)
    
    -- Pulse animation
    frame.animGroup = frame:CreateAnimationGroup()
    local fadeIn = frame.animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.3)
    fadeIn:SetOrder(1)
    
    local glowPulse = frame.animGroup:CreateAnimation("Alpha")
    glowPulse:SetTarget(frame.glow)
    glowPulse:SetFromAlpha(0)
    glowPulse:SetToAlpha(0.3)
    glowPulse:SetDuration(0.5)
    glowPulse:SetOrder(1)
    
    local glowFade = frame.animGroup:CreateAnimation("Alpha")
    glowFade:SetTarget(frame.glow)
    glowFade:SetFromAlpha(0.3)
    glowFade:SetToAlpha(0)
    glowFade:SetDuration(1.0)
    glowFade:SetOrder(2)
    
    unlockPopup = frame
    return frame
end

-- Show theme unlock notification popup
function AC:ShowThemeUnlockNotification(ratingThreshold, themeID, achievementInfo)
    local themeName = RATING_NAMES[ratingThreshold] or tostring(ratingThreshold)
    
    -- Create popup if it doesn't exist
    local popup = CreateUnlockPopup()
    
    -- Set custom text based on rating
    popup.ratingText:SetText(string.format("Congratulations on reaching %d rating!", ratingThreshold))
    popup.themeText:SetText(string.format("%s Theme Unlocked!", themeName))
    
    -- Show and animate
    popup:Show()
    popup.animGroup:Play()
    
    -- Play achievement sound
    PlaySound(SOUNDKIT.ACHIEVEMENT_MENU_OPEN)
    
    -- Also print to chat for visibility
    print(" ")
    print("|cffFFD700========================================|r")
    print("|cffFFD700    🏆 ACHIEVEMENT UNLOCKED! 🏆    |r")
    print("|cffFFD700========================================|r")
    print(string.format("|cffFFFFFFCongratulations on reaching |cffFFD700%d rating|r|cffFFFFFF!|r", ratingThreshold))
    print(string.format("|cffFFFFFFYou've unlocked the |cff000000%s|r |cffFFFFFFTheme!|r", themeName))
    print("|cff8B45FFCheck the popup or Theme settings to activate it!|r")
    print("|cffFFD700========================================|r")
    print(" ")
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get list of all unlocked themes (ACCOUNT-WIDE)
function AC:GetUnlockedThemes()
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.global or not _G.ArenaCoreDB.global.achievementUnlocks then
        return {}
    end
    
    local unlocked = {}
    for themeID, isUnlocked in pairs(_G.ArenaCoreDB.global.achievementUnlocks.themes) do
        if isUnlocked then
            table.insert(unlocked, themeID)
        end
    end
    
    return unlocked
end

-- Get achievement history (ACCOUNT-WIDE)
function AC:GetAchievementHistory()
    if not _G.ArenaCoreDB or not _G.ArenaCoreDB.global or not _G.ArenaCoreDB.global.achievementUnlocks then
        return {}
    end
    
    return _G.ArenaCoreDB.global.achievementUnlocks.achievementHistory or {}
end

-- Debug: Print current unlock status
function AC:PrintUnlockStatus()
    print("|cff8B45FFArenaCore Achievement Unlock Status (Account-Wide):|r")
    print(string.format("  Current Season: %d", CURRENT_SEASON))
    
    local globalUnlocks = _G.ArenaCoreDB and _G.ArenaCoreDB.global and _G.ArenaCoreDB.global.achievementUnlocks
    
    for rating, themeID in pairs(RATING_THEME_UNLOCKS) do
        local hasAchievement, _, achievementInfo = self:CheckRatingAchievement(rating)
        local isUnlocked = self:IsThemeUnlocked(themeID)
        
        local status = isUnlocked and "|cff00FF00UNLOCKED|r" or "|cffFF0000LOCKED|r"
        local achStatus = hasAchievement and "|A:VAS-icon-checkmark-glw:16:16|a" or "✗"
        
        -- Show which character unlocked it
        local unlockedBy = ""
        if isUnlocked and globalUnlocks and globalUnlocks.unlockedByCharacter then
            local characterKey = globalUnlocks.unlockedByCharacter[themeID]
            if characterKey then
                unlockedBy = string.format(" (by %s)", characterKey)
            end
        end
        
        print(string.format("  %s (%d): %s [Achievement: %s]%s", RATING_NAMES[rating], rating, status, achStatus, unlockedBy))
    end
end

-- ============================================================================
-- SLASH COMMANDS (Debug)
-- ============================================================================

SLASH_ACUNLOCK1 = "/acunlock"
SlashCmdList["ACUNLOCK"] = function(msg)
    local cmd = msg:lower():trim()
    
    if cmd == "status" or cmd == "" then
        AC:PrintUnlockStatus()
    elseif cmd == "scan" then
        AC:ScanRatingAchievements()
    elseif cmd == "history" then
        local history = AC:GetAchievementHistory()
        print("|cff8B45FFArenaCore Achievement History (Account-Wide):|r")
        if #history == 0 then
            print("  No achievements unlocked yet")
        else
            for i, entry in ipairs(history) do
                local unlockedBy = entry.unlockedBy or "Unknown"
                print(string.format("  %d. %s (Season %d) - Unlocked by %s on %s", 
                    i, 
                    entry.achievementName or "Unknown", 
                    entry.season or 0, 
                    unlockedBy,
                    date("%Y-%m-%d %H:%M:%S", entry.unlockedAt or 0)))
            end
        end
    elseif cmd == "test" then
        -- Test the 2100 achievement directly
        print("|cff8B45FFArenaCore Achievement Test:|r")
        local achievementID = 41026
        local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuildAch, wasEarnedByMe = GetAchievementInfo(achievementID)
        
        if id then
            print(string.format("  Achievement ID: %d", id))
            print(string.format("  Name: %s", name or "Unknown"))
            print(string.format("  Completed: %s", tostring(completed)))
            print(string.format("  Earned By Me: %s", tostring(wasEarnedByMe)))
            print(string.format("  Points: %d", points or 0))
            
            if completed and wasEarnedByMe then
                print("|cff00FF00  |A:VAS-icon-checkmark-glw:16:16|a YOU HAVE THIS ACHIEVEMENT! Theme should unlock!|r")
            else
                print("|cffFF0000  ✗ Achievement not earned yet|r")
            end
        else
            print("|cffFF0000  ERROR: Achievement ID 41026 not found!|r")
        end
    elseif cmd == "popup" then
        -- Test the unlock popup
        print("|cff8B45FFArenaCore:|r Showing test popup...")
        AC:ShowThemeUnlockNotification(2100, "shade_ui", {
            id = 41026,
            name = "Duelist: The War Within Season 3",
            icon = 134400,
        })
    else
        print("|cff8B45FFArenaCore Achievement Unlock Commands:|r")
        print("  /acunlock status - Show unlock status")
        print("  /acunlock scan - Scan for achievements")
        print("  /acunlock history - Show unlock history")
        print("  /acunlock test - Test achievement 41026 directly")
        print("  /acunlock popup - Show unlock popup (preview)")
    end
end

-- Disabled startup message for end users
-- print("|cff8B45FFArenaCore:|r AchievementUnlocks.lua loaded")
