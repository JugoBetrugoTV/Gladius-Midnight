-- ============================================================================
-- File: ArenaCore/modules/KickBar/KickBar.lua
-- Purpose: Interrupt cooldown tracking bar for kicks only
-- ============================================================================

local AC = _G.ArenaCore or {}
if not AC then return end

local KickBar = {}
AC.KickBar = KickBar

-- Forward declarations
local CreateBarFrame

-- ============================================================================
-- INTERRUPT DATABASE
-- ============================================================================

local INTERRUPTS = {
    -- Death Knight
    [47528] = {duration = 15, class = "DEATHKNIGHT", name = "Mind Freeze"},
    
    -- Demon Hunter
    [183752] = {duration = 15, class = "DEMONHUNTER", name = "Disrupt"},
    
    -- Druid
    [106839] = {duration = 15, class = "DRUID", name = "Skull Bash"},
    [78675] = {duration = 60, class = "DRUID", name = "Solar Beam"},
    
    -- Evoker
    [351338] = {duration = 20, class = "EVOKER", name = "Quell"},
    
    -- Hunter
    [147362] = {duration = 24, class = "HUNTER", name = "Counter Shot"},
    [187707] = {duration = 24, class = "HUNTER", name = "Muzzle"}, -- Survival
    
    -- Mage
    [2139] = {duration = 24, class = "MAGE", name = "Counterspell"},
    
    -- Monk
    [116705] = {duration = 15, class = "MONK", name = "Spear Hand Strike"},
    
    -- Paladin
    [96231] = {duration = 15, class = "PALADIN", name = "Rebuke"},
    
    -- Priest
    [15487] = {duration = 45, class = "PRIEST", name = "Silence"}, -- Shadow only
    
    -- Rogue
    [1766] = {duration = 15, class = "ROGUE", name = "Kick"},
    
    -- Shaman
    [57994] = {duration = 12, class = "SHAMAN", name = "Wind Shear"},
    
    -- Warlock
    [19647] = {duration = 24, class = "WARLOCK", name = "Spell Lock"}, -- Felhunter
    [119910] = {duration = 24, class = "WARLOCK", name = "Spell Lock"}, -- Command Demon
    
    -- Warrior
    [6552] = {duration = 15, class = "WARRIOR", name = "Pummel"},
}

-- ============================================================================
-- LOCAL VARIABLES
-- ============================================================================
local activeInterrupts = {} -- {[unitGUID] = {[spellID] = {expirationTime, playerName, class}}}
local iconFrames = {} -- Pool of icon frames
local barFrame = nil
local eventFrame = nil

local function HasVisibleIcons()
    for _, frame in ipairs(iconFrames) do
        if frame:IsShown() then
            return true
        end
    end
    return false
end

-- ============================================================================
-- FRAME HELPERS
-- ============================================================================

local function GetSettings()
    return AC.DB and AC.DB.profile and AC.DB.profile.kickBar or {}
end

local function SaveKickBarSetting(key, value)
    if not AC.DB or not AC.DB.profile then return end
    AC.DB.profile.kickBar = AC.DB.profile.kickBar or {}
    AC.DB.profile.kickBar[key] = value
end

-- ============================================================================
-- FRAME HELPERS
-- ============================================================================

local function GetArenaFrame(index)
    if AC.MasterFrameManager and AC.MasterFrameManager.GetFrames then
        local frames = AC.MasterFrameManager:GetFrames()
        if frames and frames[index] then
            return frames[index]
        end
    end
    if AC.FrameManager and AC.FrameManager.GetFrames then
        local frames = AC.FrameManager:GetFrames()
        if frames and frames[index] then
            return frames[index]
        end
    end
    if AC.arenaFrames and AC.arenaFrames[index] then
        return AC.arenaFrames[index]
    end
    return nil
end

local function SavePosition()
    if not barFrame then return end
    local point, relativeTo, relativePoint, xOfs, yOfs = barFrame:GetPoint()
    SaveKickBarSetting("position", {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs,
    })
end

local function ApplyPosition()
    if not barFrame then return end
    local settings = GetSettings()
    barFrame:ClearAllPoints()

    local pos = settings.position
    if pos and pos.point then
        barFrame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
        return
    end

    local arena3 = GetArenaFrame(3)
    if arena3 and arena3:IsVisible() then
        barFrame:SetPoint("TOP", arena3, "BOTTOM", 0, -30)
    else
        barFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -250, 170)
    end
end

local function ApplyBackground()
    if not barFrame then return end
    local settings = GetSettings()
    local showBg = settings.showBackground == nil and false or settings.showBackground

    if showBg then
        -- Background with ArenaCore styling
        if not barFrame.background then
            barFrame.background = AC:CreateFlatTexture(barFrame, "BACKGROUND", 1, AC.COLORS.BG, 0.95)
            barFrame.background:SetAllPoints()
        end
        barFrame.background:Show()
        
        -- Border container
        if not barFrame.borderContainer then
            barFrame.borderContainer = CreateFrame("Frame", nil, barFrame)
            barFrame.borderContainer:SetAllPoints()
            AC:AddWindowEdge(barFrame.borderContainer, 1, 0)
        end
        barFrame.borderContainer:Show()
        
        -- Title bar with close button (test mode only)
        if not barFrame.titleBar then
            barFrame.titleBar = CreateFrame("Frame", nil, barFrame)
            barFrame.titleBar:SetPoint("TOPLEFT", 4, -4)
            barFrame.titleBar:SetPoint("TOPRIGHT", -4, -4)
            barFrame.titleBar:SetHeight(20)
            
            -- Close button (red X)
            local closeBtn = AC:CreateTexturedButton(barFrame.titleBar, 16, 16, "", "button-close")
            closeBtn:SetPoint("RIGHT", -2, 0)
            AC:CreateStyledText(closeBtn, "×", 12, AC.COLORS.TEXT, "OVERLAY", ""):SetPoint("CENTER")
            closeBtn:SetScript("OnClick", function()
                if AC.KickBar and AC.KickBar.Clear then
                    AC.KickBar:Clear()
                end
                if barFrame then
                    barFrame:Hide()
                end
            end)
            barFrame.closeBtn = closeBtn
        end
        
        -- Show/hide close button based on arena state
        if barFrame.titleBar then
            local inArena = IsActiveBattlefieldArena()
            if inArena then
                barFrame.titleBar:Hide() -- Hide in live arena to prevent accidental clicks
            else
                barFrame.titleBar:Show() -- Show in test mode
            end
        end
    else
        -- Hide all background elements
        if barFrame.background then barFrame.background:Hide() end
        if barFrame.borderContainer then barFrame.borderContainer:Hide() end
        if barFrame.titleBar then barFrame.titleBar:Hide() end
    end
end

-- ============================================================================
-- ICON FRAME CREATION
-- ============================================================================

local function CreateIconFrame()
    local settings = GetSettings()
    local iconSize = settings.iconSize or 40
    
    local frame = CreateFrame("Frame", nil, barFrame)
    frame:SetSize(iconSize, iconSize)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(50)
    
    -- Icon texture
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize(iconSize - 4, iconSize - 4)
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    if AC.StyleIcon then AC:StyleIcon(icon, frame, true) end
    frame.icon = icon
    
    -- CRITICAL FIX: Setup IconGlow system for flash animation on interrupt detection
    -- IconGlow expects a FRAME, not a texture, so pass the frame itself
    if AC.IconGlow and AC.IconGlow.SetupIconGlow then
        AC.IconGlow:SetupIconGlow(frame, "PURPLE")
    end
    
    -- Cooldown spiral (using helper to block OmniCC)
    local cooldown = AC:CreateCooldown(frame, nil, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetDrawEdge(true)
    cooldown:SetSwipeColor(0, 0, 0, 0.8)
    cooldown:SetHideCountdownNumbers(true) -- FIXED: Disable Blizzard's default timer to prevent duplicate timers
    cooldown:SetDrawSwipe(true)
    -- CRITICAL FIX: Set cooldown to lower draw level so text appears above it
    if cooldown.SetSwipeTexture then
        cooldown:SetSwipeTexture("Interface\\AddOns\\ArenaCore\\Media\\Textures\\white", 0, 0, 0, 0.8)
    end
    frame.cooldown = cooldown
    
    -- Timer text container (separate frame to ensure it's above cooldown)
    local textFrame = CreateFrame("Frame", nil, frame)
    textFrame:SetAllPoints(frame)
    textFrame:SetFrameLevel(frame:GetFrameLevel() + 10) -- Much higher than cooldown
    
    -- Timer text (using custom ArenaCore font)
    -- CRITICAL FIX: Create text as child of textFrame (not main frame) with OVERLAY layer
    local timerText = textFrame:CreateFontString(nil, "OVERLAY", nil, 7)
    timerText:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 14, "OUTLINE")
    timerText:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
    timerText:SetTextColor(1, 1, 1, 1)
    frame.timerText = timerText
    
    -- Player name text (using custom ArenaCore font)
    local nameText = frame:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 10, "OUTLINE")
    nameText:SetPoint("TOP", frame, "BOTTOM", 0, -2)
    nameText:SetTextColor(1, 1, 1, 1)
    frame.nameText = nameText
    
    frame:Hide()
    return frame
end

local function GetIconFrame()
    for _, frame in ipairs(iconFrames) do
        if not frame:IsShown() then
            return frame
        end
    end
    
    -- Create new frame if none available
    local frame = CreateIconFrame()
    table.insert(iconFrames, frame)
    return frame
end

-- ============================================================================
-- BAR POSITIONING
-- ============================================================================

local function UpdateIconPositions()
    local settings = GetSettings()
    local iconSize = settings.iconSize or 40
    local spacing = settings.spacing or 5
    local growthDirection = settings.growthDirection or "RIGHT"
    
    -- Collect all visible icons
    local visibleIcons = {}
    for _, frame in ipairs(iconFrames) do
        if frame:IsShown() then
            table.insert(visibleIcons, frame)
        end
    end
    
    -- Sort by expiration time (soonest first)
    table.sort(visibleIcons, function(a, b)
        return (a.expirationTime or 0) < (b.expirationTime or 0)
    end)
    
    -- Position icons
    for i, frame in ipairs(visibleIcons) do
        frame:ClearAllPoints()
        local offset = (i - 1) * (iconSize + spacing)
        
        if growthDirection == "RIGHT" then
            frame:SetPoint("LEFT", barFrame, "LEFT", offset, 0)
        elseif growthDirection == "LEFT" then
            frame:SetPoint("RIGHT", barFrame, "RIGHT", -offset, 0)
        elseif growthDirection == "UP" then
            frame:SetPoint("BOTTOM", barFrame, "BOTTOM", 0, offset)
        elseif growthDirection == "DOWN" then
            frame:SetPoint("TOP", barFrame, "TOP", 0, -offset)
        end
    end
end

-- ============================================================================
-- INTERRUPT TRACKING
-- ============================================================================

local function AddInterrupt(unitGUID, playerName, spellID, class)
    local settings = GetSettings()
    -- Allow test mode interrupts even if disabled (test GUIDs start with "test")
    local isTestMode = unitGUID and unitGUID:match("^test")
    
    if settings.enabled == false and not isTestMode then 
        return 
    end
    
    local interruptData = INTERRUPTS[spellID]
    if not interruptData then return end
    
    -- Initialize storage
    activeInterrupts[unitGUID] = activeInterrupts[unitGUID] or {}
    
    local now = GetTime()
    local duration = interruptData.duration
    local expirationTime = now + duration
    
    -- CRITICAL: Prevent duplicates
    -- If this GUID+spellID combo is already on cooldown, don't add it again
    if activeInterrupts[unitGUID][spellID] then
        local existing = activeInterrupts[unitGUID][spellID]
        -- Only skip if the cooldown is still active
        if existing.expirationTime and existing.expirationTime > now then
            return -- Already tracking this interrupt
        end
    end
    
    -- Store interrupt data
    activeInterrupts[unitGUID][spellID] = {
        expirationTime = expirationTime,
        playerName = playerName,
        class = class or interruptData.class,
        spellID = spellID,
    }
    
    -- Ensure bar exists
    if not barFrame then
        CreateBarFrame()
    end

    -- Get icon frame
    local frame = GetIconFrame()
    frame.unitGUID = unitGUID
    frame.spellID = spellID
    frame.expirationTime = expirationTime
    
    -- Set icon texture
    local texture = C_Spell.GetSpellTexture(spellID)
    if texture then
        frame.icon:SetTexture(texture)
    end
    
    -- Set class color border
    local classColor = RAID_CLASS_COLORS[class or interruptData.class]
    if classColor and frame.styledBorder and frame.styledBorder.overlay then
        frame.styledBorder.overlay:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
    end
    
    -- Set player name
    if settings.showPlayerNames then
        frame.nameText:SetText(playerName or "Unknown")
        frame.nameText:Show()
    else
        frame.nameText:Hide()
    end
    
    -- Start cooldown
    if settings.showCooldown ~= false then
        frame.cooldown:SetCooldown(now, duration)
        frame.cooldown:Show()
    else
        frame.cooldown:Hide()
    end
    
    -- Show frame (these are NOT protected frames - can show in combat!)
    frame:Show()
    
    -- CRITICAL FIX: Play glow animation when interrupt first appears
    -- IconGlow expects a FRAME, not a texture, so pass the frame itself
    if AC.IconGlow and AC.IconGlow.PlayGlow then
        AC.IconGlow:PlayGlow(frame)
    end
    
    -- Update positions
    UpdateIconPositions()
    
    -- Show bar when first icon appears
    if barFrame then
        barFrame:Show()
        ApplyBackground() -- Update background visibility
    end
    
    -- Set up expiration
    C_Timer.After(duration, function()
        if activeInterrupts[unitGUID] and activeInterrupts[unitGUID][spellID] then
            activeInterrupts[unitGUID][spellID] = nil
        end
        frame:Hide()
        UpdateIconPositions()
        
        -- Hide bar if no more icons visible
        if not HasVisibleIcons() and barFrame then
            barFrame:Hide()
        end
    end)
end

-- ============================================================================
-- COMBAT LOG TRACKING
-- ============================================================================

-- FIXED: Accept parameters from centralized combat log handler (matches AuraTracker/DispelTracker pattern)
-- @param timestamp number
-- @param combatEvent string
-- @param sourceGUID string
-- @param sourceName string
-- @param sourceFlags number
-- @param destGUID string
-- @param spellID number
function KickBar:ProcessCombatLogEvent(timestamp, combatEvent, sourceGUID, sourceName, sourceFlags, destGUID, spellID)
    -- Only track SPELL_CAST_SUCCESS for interrupts
    if combatEvent ~= "SPELL_CAST_SUCCESS" then return end
    if not INTERRUPTS[spellID] then return end
    
    -- Check if source is an enemy player
    local isPlayer = bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
    local isHostile = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
    
    if not isPlayer or not isHostile then return end
    
    -- Get player info
    local _, class = GetPlayerInfoByGUID(sourceGUID)
    local playerName = sourceName
    
    -- Strip server name
    if playerName and playerName:find("-") then
        playerName = playerName:match("([^-]+)")
    end
    
    -- Add interrupt to tracking
    AddInterrupt(sourceGUID, playerName, spellID, class)
end

-- ============================================================================
-- TIMER UPDATES
-- ============================================================================

local function UpdateTimers()
    local settings = GetSettings()
    -- Default to true if not set - always show timer text
    if settings.showTimerText == false then return end
    
    local now = GetTime()
    for _, frame in ipairs(iconFrames) do
        if frame:IsShown() and frame.expirationTime then
            local remaining = frame.expirationTime - now
            if remaining > 0 then
                if remaining < 10 then
                    frame.timerText:SetText(string.format("%.1f", remaining))
                else
                    frame.timerText:SetText(string.format("%d", math.ceil(remaining)))
                end
            else
                frame.timerText:SetText("")
            end
        end
    end
end

-- ============================================================================
-- BAR FRAME CREATION
-- ============================================================================

CreateBarFrame = function()
    if barFrame then return barFrame end
    
    local settings = GetSettings()
    
    barFrame = CreateFrame("Frame", "ArenaCoreKickBar", UIParent)
    
    -- Apply sizing from settings (default to compact like Dispel frame)
    local width = settings.barWidth or 260
    local height = settings.barHeight or 60
    barFrame:SetSize(width, height)
    
    barFrame:SetFrameStrata("MEDIUM")
    barFrame:SetFrameLevel(40)
    barFrame:SetMovable(true)
    barFrame:EnableMouse(true)
    barFrame:RegisterForDrag("LeftButton")
    barFrame:SetScript("OnDragStart", function(f)
        f:StartMoving()
    end)
    barFrame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        -- Anchor to UIParent to avoid taint from protected frames
        local point, _, relativePoint, xOfs, yOfs = f:GetPoint()
        f:ClearAllPoints()
        f:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
        SavePosition()
    end)
    
    -- Position
    ApplyPosition()

    -- Scale
    barFrame:SetScale((settings.scale or 100) / 100)
    
    ApplyBackground()

    -- CRITICAL: Bar should be hidden by default, only shown when needed
    barFrame:Hide()
    
    return barFrame
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function KickBar:Initialize()
    if self.initialized then return end
    
    -- Create bar frame
    CreateBarFrame()
    
    -- Create event frame
    eventFrame = CreateFrame("Frame")
    -- REMOVED: COMBAT_LOG_EVENT_UNFILTERED (now handled by centralized ArenaCore combat log system)
    -- eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- FIXED: Clear kick bar when leaving arena
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- FIXED: Clear kick bar when changing zones
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE") -- CRITICAL: Clear kick bar between Solo Shuffle rounds
    eventFrame:SetScript("OnEvent", function(_, event)
        -- COMBAT_LOG now delegated through AC.KickBar:ProcessCombatLogEvent()
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            -- FIXED: Clear kick bar when leaving arena
            local _, instanceType = IsInInstance()
            if instanceType ~= "arena" then
                -- Not in arena anymore - clear all kick icons
                if AC.KickBar and AC.KickBar.Clear then
                    AC.KickBar:Clear()
                end
            end
        elseif event == "GROUP_ROSTER_UPDATE" then
            -- CRITICAL: Clear kick bar between Solo Shuffle rounds
            local _, instanceType = IsInInstance()
            if instanceType == "arena" then
                -- In arena - clear stale interrupt cooldowns from previous round
                if AC.KickBar and AC.KickBar.Clear then
                    AC.KickBar:Clear()
                end
            end
        end
    end)
    
    -- Timer ticker
    C_Timer.NewTicker(0.1, UpdateTimers)
    
    self.initialized = true
end

function KickBar:Enable()
    local settings = GetSettings()
    if settings.enabled == false then return end
    
    CreateBarFrame()
    ApplyPosition()
    ApplyBackground()
    
    if barFrame then
        barFrame:SetShown(HasVisibleIcons())
    end
end

function KickBar:Disable()
    if barFrame then
        barFrame:Hide()
    end
    
    -- Hide all icons
    for _, frame in ipairs(iconFrames) do
        frame:Hide()
    end
    
    -- Clear active interrupts
    wipe(activeInterrupts)
end

function KickBar:Refresh()
    -- Update all icon sizes and positions
    local settings = GetSettings()
    local iconSize = settings.iconSize or 40
    
    for _, frame in ipairs(iconFrames) do
        frame:SetSize(iconSize, iconSize)
        if frame.icon then
            frame.icon:SetSize(iconSize - 4, iconSize - 4)
        end
    end
    
    if barFrame then
        -- Apply sizing
        local width = settings.barWidth or 260
        local height = settings.barHeight or 60
        barFrame:SetSize(width, height)
        
        -- Apply scale
        barFrame:SetScale((settings.scale or 100) / 100)
    end
    
    ApplyBackground()
    ApplyPosition()
    UpdateIconPositions()

    if barFrame then
        barFrame:SetShown(HasVisibleIcons())
    end
end

function KickBar:Clear()
    for _, frame in ipairs(iconFrames) do
        frame:Hide()
        frame.unitGUID = nil
        frame.spellID = nil
        frame.expirationTime = nil
    end
    wipe(activeInterrupts)

    if barFrame then
        barFrame:Hide()
    end
end

-- ============================================================================
-- TEST MODE
-- ============================================================================

function KickBar:Test()
    self:Enable()
    self:Clear()
    
    -- Ensure bar is created and visible for test mode
    if not barFrame then
        CreateBarFrame()
    end
    if barFrame then
        barFrame:Show()
        ApplyBackground() -- Show background in test mode
    end
    
    -- Show test interrupts
    local testInterrupts = {
        {spellID = 2139, class = "MAGE", name = "Mage"},
        {spellID = 1766, class = "ROGUE", name = "Rogue"},
        {spellID = 47528, class = "DEATHKNIGHT", name = "DK"},
    }
    
    for i, test in ipairs(testInterrupts) do
        C_Timer.After((i - 1) * 0.5, function()
            AddInterrupt("test" .. i, test.name, test.spellID, test.class)
        end)
    end
end

-- Auto-initialize when module loads
C_Timer.After(1, function()
    if AC.KickBar then
        AC.KickBar:Initialize()
    end
end)
