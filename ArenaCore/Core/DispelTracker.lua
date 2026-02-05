-- ============================================================================
-- File: ArenaCore/Core/DispelTracker.lua (v1.0)
-- Purpose: Dispel cooldown tracking system for arena frames
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

-- COMPREHENSIVE: All dispel/decurse spells by class and spec
-- Maps class -> spec -> spell ID (using the user's complete list)
local DISPEL_SPELLS_BY_CLASS = {
    PRIEST = {
        default = 527,      -- Purify (all specs can use)
        offensive = 528,    -- Dispel Magic (offensive)
        mass = 32375,       -- Mass Dispel
    },
    DRUID = {
        default = 2782,     -- Remove Corruption (all specs)
        Restoration = 88423, -- Nature's Cure (Resto only - removes Magic too)
    },
    PALADIN = {
        default = 213644,   -- Cleanse Toxins (all specs)
        Holy = 4987,        -- Cleanse (Holy/Prot - removes Magic too)
        Protection = 4987,  -- Cleanse (Holy/Prot - removes Magic too)
    },
    MONK = {
        default = 115450,   -- Detox (all specs - Mistweaver removes Magic too)
    },
    SHAMAN = {
        default = 51886,    -- Cleanse Spirit (all specs)
        Restoration = 77130, -- Purify Spirit (Resto only - removes Magic too)
        offensive = 370,    -- Purge (offensive dispel)
    },
    MAGE = {
        default = 475,      -- Remove Curse (all specs)
    },
    DEMONHUNTER = {
        default = 278326,   -- Consume Magic (offensive)
    },
    EVOKER = {
        default = 360823,   -- Naturalize (all specs)
        cauterize = 374251, -- Cauterizing Flame (45s CD)
    },
}

-- Build flat lookup table for combat log tracking
local DISPEL_SPELLS = {}
for class, spells in pairs(DISPEL_SPELLS_BY_CLASS) do
    for key, spellID in pairs(spells) do
        DISPEL_SPELLS[spellID] = true
    end
end

-- Store latest spell ID seen per unit (from combat log)
local lastSpellIDs = {}

-- Get the appropriate dispel spell ID for a unit based on class/spec
local function GetDispelSpellID(unit)
    local _, class = UnitClass(unit)
    if not class then return nil end
    
    local classSpells = DISPEL_SPELLS_BY_CLASS[class]
    if not classSpells then return nil end
    
    -- Try to get spec-specific spell
    local arenaIndex = tonumber(unit:match("arena(%d)"))
    if arenaIndex then
        local specID = GetArenaOpponentSpec(arenaIndex)
        if specID and specID > 0 then
            local _, specName = GetSpecializationInfoByID(specID)
            if specName and classSpells[specName] then
                return classSpells[specName]
            end
        end
    end
    
    -- Fall back to default spell for class
    return classSpells.default
end

-- Get display name for dispel spell
local function GetDisplayName(unit)
    -- Use last seen spell ID if available
    local spellID = lastSpellIDs[unit] or GetDispelSpellID(unit)
    if spellID then
        local spellName = C_Spell.GetSpellName(spellID)
        if spellName then
            return spellName
        end
    end
    return "Dispel"
end

-- Local state
local dispelContainer = nil -- Main container for all dispel frames
local dispelFrames = {}
local dispelTimers = {}
local cachedSettings = nil -- Cache settings to avoid excessive database reads

-- Default settings
local defaultSettings = {
    enabled = false,
    size = 24,
    offsetX = 0,
    offsetY = 0,
    scale = 100,
    showCooldown = true,
    cooldownDuration = 8, -- Standard dispel cooldown
    boxWidth = 260,       -- Match test frame defaults
    boxHeight = 60,
    showBackground = true, -- CRITICAL: Background frame visibility (default ON)
    textEnabled = true,    -- CRITICAL: Text visibility (default ON)
    textScale = 100,       -- Text scale percentage
    textOffsetX = 0,       -- Text horizontal offset
    textOffsetY = 0,       -- Text vertical offset
    growthDirection = "Horizontal", -- CRITICAL: Icon layout direction (Horizontal or Vertical)
}

-- Get dispel settings from database (with caching to reduce spam)
local function GetDispelSettings(forceRefresh)
    -- Return cached settings unless forced refresh
    if cachedSettings and not forceRefresh then
        return cachedSettings
    end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.dispels
    -- DEBUG REMOVED FOR RELEASE: DB path exists check
    -- if db then
    --     DEBUG: enabled/size check
    -- end
    
    if not db then
        -- Return defaults if database not initialized
        -- DEBUG REMOVED FOR RELEASE: Database not initialized warning
        cachedSettings = {
            enabled = true,
            size = 26,
            scale = 100,
            cooldownDuration = 8,
            showCooldown = true,
            textEnabled = true,
            textScale = 100,
            textOffsetX = 0,
            textOffsetY = 0,
            showBackground = true,
            growthDirection = "Horizontal",
            offsetX = 0,
            offsetY = 0,
        }
        return cachedSettings
    end
    
    -- Settings refreshed - debug removed for clean release
    
    cachedSettings = db
    return db
end

-- Get dispel icon for a unit (using spell ID to get correct texture)
-- CRITICAL FIX: Always return an icon (like trinkets) - use fallback if class not detected
local function GetDispelIcon(unit)
    -- Use last seen spell ID if available, otherwise get default for class/spec
    local spellID = lastSpellIDs[unit] or GetDispelSpellID(unit)
    
    -- CRITICAL FIX: If no spell ID detected, use fallback question mark icon (like racials)
    if not spellID then
        return 134400 -- Question mark icon - will update when class/spec detected
    end
    
    -- Get spell texture from game API (always accurate)
    local texture = C_Spell.GetSpellTexture(spellID)
    return texture or 134400 -- Fallback to question mark if texture fails
end

-- Check if unit has dispel ability
-- CRITICAL FIX: Always return true (like trinkets) - we show all dispels with fallback icons
local function UnitHasDispel(unit)
    return true -- Always show dispel icons, just like trinkets are always shown
end

-- Create the main dispel container above arena frames
local function CreateDispelContainer()
    if dispelContainer then return dispelContainer end
    
    local settings = GetDispelSettings()
    
    -- Create main container frame
    dispelContainer = CreateFrame("Frame", "ArenaCoreDispelContainer", UIParent)
    -- Compute size like test frame based on growth direction
    local numIcons, iconSpacing = 3, 5
    local growthDirection = settings.growthDirection or "Horizontal"
    local minPadding = 2
    
    local baseWidth, baseHeight
    if growthDirection == "Vertical" then
        -- Vertical: narrow width, tall height
        baseWidth = settings.size + (minPadding * 2)
        baseHeight = (numIcons * settings.size) + ((numIcons - 1) * iconSpacing) + 20
    else
        -- Horizontal: wide width, short height
        baseWidth = 10 + (numIcons * settings.size) + ((numIcons - 1) * iconSpacing) + 10
        baseHeight = 60
    end
    
    local useWidth = settings.boxWidth or baseWidth
    local useHeight = settings.boxHeight or baseHeight
    useWidth = math.max(useWidth, baseWidth)
    useHeight = math.max(useHeight, baseHeight)
    dispelContainer:SetSize(useWidth, useHeight)
    dispelContainer:SetFrameStrata("MEDIUM")
    dispelContainer:SetFrameLevel(100)

    -- Background and border to mirror test mode visuals
    -- CRITICAL: Store background and border references for toggle functionality
    if AC.CreateFlatTexture then
        dispelContainer.background = AC:CreateFlatTexture(dispelContainer, "BACKGROUND", 1, AC.COLORS and AC.COLORS.BG or {0.1,0.1,0.1,1}, 0.95)
        dispelContainer.background:SetAllPoints()
    end
    if AC.AddWindowEdge then
        dispelContainer.border = AC:AddWindowEdge(dispelContainer, 1, 0)
    end
    
    -- CRITICAL: Apply background visibility based on settings (default ON)
    local showBg = settings.showBackground ~= false
    if dispelContainer.background then
        if showBg then
            if not InCombatLockdown() then
                dispelContainer.background:Show()
            end
        else
            if not InCombatLockdown() then
                dispelContainer.background:Hide()
            end
        end
    end
    -- CRITICAL FIX: Border is now a table of textures, iterate through all of them
    if dispelContainer.border and type(dispelContainer.border) == "table" then
        for _, borderTexture in ipairs(dispelContainer.border) do
            if borderTexture then
                if showBg then
                    if not InCombatLockdown() then
                        borderTexture:Show()
                    end
                else
                    if not InCombatLockdown() then
                        borderTexture:Hide()
                    end
                end
            end
        end
    end

    -- Removed redundant title label to keep UI minimal and avoid clutter

    -- CRITICAL FIX: Apply scale like test mode
    local scale = (settings.scale or 100) / 100
    dispelContainer:SetScale(scale)
    
    -- Position using saved coordinates from DispelWindow (with offsets applied)
    local pos = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies 
        and AC.DB.profile.moreGoodies.dispels 
        and AC.DB.profile.moreGoodies.dispels.framePos
    local point = (pos and pos.point) or "BOTTOM"
    local relativePoint = (pos and (pos.relativePoint or pos.relative)) or "CENTER"
    local x = (pos and pos.x) or 0
    local y = (pos and pos.y) or 150
    dispelContainer:ClearAllPoints()
    dispelContainer:SetPoint(point, UIParent, relativePoint, x + (settings.offsetX or 0), y + (settings.offsetY or 0))
    
    -- Container positioned - debug removed for clean release
    
    -- Initially hidden
    dispelContainer:Hide()
    
    return dispelContainer
end

-- Create dispel frame for arena unit
local function CreateDispelFrame(unit)
    if dispelFrames[unit] then return dispelFrames[unit] end
    
    local settings = GetDispelSettings()
    local container = CreateDispelContainer()
    
    -- Create main frame parented to the dispel container
    local frame = CreateFrame("Frame", nil, container)
    frame:SetSize(settings.size, settings.size) -- Square icon like your custom box
    frame:SetFrameLevel(container:GetFrameLevel() + 1)
    
    -- Create icon texture and apply black square-like border styling
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetAllPoints()
    frame.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    if AC.StyleIcon then AC:StyleIcon(frame.icon, frame, true) end
    
    -- Create cooldown frame (using helper to block OmniCC)
    frame.cooldown = AC:CreateCooldown(frame, nil, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints()
    frame.cooldown:SetReverse(false)
    frame.cooldown:SetHideCountdownNumbers(true) -- Hide built-in numbers, use custom timer
    
    -- CRITICAL: Exclude from OmniCC
    if _G.ArenaCore_ExcludeFromOmniCC then
        _G.ArenaCore_ExcludeFromOmniCC(frame.cooldown, frame)
    end
    
    -- CRITICAL: Add countdown timer text (like trinkets/racials)
    frame.timerText = frame.cooldown:CreateFontString(nil, "OVERLAY")
    local fontPath = AC.FONT_PATH or "Fonts\\FRIZQT__.TTF"
    frame.timerText:SetFont(fontPath, 10, "OUTLINE")
    frame.timerText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.timerText:SetTextColor(1, 1, 1, 1)
    
    -- Store unit reference
    frame.unit = unit
    
    -- CRITICAL FIX: Optional spell name text below icon (inside the container)
    -- Only create text if explicitly enabled (not false)
    if settings.textEnabled ~= false then
        local textScale = (settings.textScale or 100) / 100
        frame.text = frame:CreateFontString(nil, "OVERLAY")
        frame.text:SetFont("Fonts\\FRIZQT__.TTF", math.max(6, math.floor(8 * textScale + 0.5)), "") -- no outline
        frame.text:SetTextColor(1, 1, 1, 1)
        frame.text:SetPoint("TOP", frame, "BOTTOM", settings.textOffsetX or 0, -2 + (settings.textOffsetY or 0))
        frame.text:SetText(GetDisplayName(unit))
        -- CRITICAL: If textEnabled is explicitly false, don't create text at all
        if settings.textEnabled == false then
            frame.text:Hide()
        end
    end
    
    -- Position based on arena number and growth direction
    local arenaNum = tonumber(unit:match("arena(%d)"))
    if arenaNum then
        local padding, iconSpacing = 10, 5
        local growthDirection = settings.growthDirection or "Horizontal"
        
        if growthDirection == "Vertical" then
            -- Vertical: Stack icons downward
            local yOffset = -padding - (arenaNum - 1) * (settings.size + iconSpacing)
            frame:SetPoint("TOP", container, "TOP", 0, yOffset)
        else
            -- Horizontal: Line up icons to the right
            local xOffset = padding + (arenaNum - 1) * (settings.size + iconSpacing)
            frame:SetPoint("LEFT", container, "LEFT", xOffset, -12)
        end
    end
    
    -- Initially hidden
    frame:Hide()
    
    dispelFrames[unit] = frame
    return frame
end

-- Update dispel container visibility and positioning
local function UpdateDispelContainer()
    local container = CreateDispelContainer()
    local settings = GetDispelSettings() -- Use cached settings
    
    -- Reduced spam: Only print on first call or when explicitly debugging
    -- print("|cff00FFFF[DispelTracker]|r UpdateDispelContainer called - textEnabled: " .. tostring(settings.textEnabled) .. ", showBackground: " .. tostring(settings.showBackground))
    
    if not settings.enabled then
        if not InCombatLockdown() then
            container:Hide()
        end
        return
    end
    
    -- CRITICAL FIX: Show container in real arena if ANY arena unit exists
    -- This matches test mode behavior where container is always visible
    local shouldShow = false
    for i = 1, 3 do
        local unit = "arena" .. i
        if UnitExists(unit) then
            shouldShow = true
            -- If unit has dispel, we'll show their icon
            -- If they don't have dispel, their slot will be empty (like test mode)
            break
        end
    end
    
    -- Show/hide container based on arena state
    -- CRITICAL: Only show in REAL ARENA, NOT prep room
    -- Check if we're in actual arena match (not prep room)
    local _, instanceType = IsInInstance()
    local inArena = instanceType == "arena"
    
    -- CRITICAL FIX: Detect prep room properly
    -- Prep room = specs exist but units don't exist
    -- Live arena = units exist
    local inPrepRoom = false
    if inArena then
        local numOpponentSpecs = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs()
        if numOpponentSpecs and numOpponentSpecs > 0 then
            -- Check if any arena units actually exist
            local anyUnitExists = false
            for i = 1, 3 do
                if UnitExists("arena" .. i) then
                    anyUnitExists = true
                    break
                end
            end
            -- Only in prep room if specs exist but NO units exist
            inPrepRoom = not anyUnitExists
        end
    end
    
    -- Show in arena but NOT in prep room
    local isRealArena = inArena and not inPrepRoom
    
    -- DEBUG REMOVED FOR RELEASE: Container visibility state
    
    if isRealArena and shouldShow then
        -- DEBUG REMOVED FOR RELEASE: Showing container in live arena
        -- Apply scale to container FIRST
        local scale = settings.scale / 100
        container:SetScale(scale)
        
        -- CRITICAL FIX: Update size to match settings/test frame respecting growth direction
        local numIcons, iconSpacing = 3, 5
        local minPadding = 2
        local growthDirection = settings.growthDirection or "Horizontal"
        
        local baseWidth, baseHeight
        if growthDirection == "Vertical" then
            -- Vertical: narrow width, tall height
            baseWidth = settings.size + (minPadding * 2)
            baseHeight = (numIcons * settings.size) + ((numIcons - 1) * iconSpacing) + 20
        else
            -- Horizontal: wide width, short height
            baseWidth = 10 + (numIcons * settings.size) + ((numIcons - 1) * iconSpacing) + 10
            baseHeight = 60
        end
        
        local useWidth = settings.boxWidth or baseWidth
        local useHeight = settings.boxHeight or baseHeight
        useWidth = math.max(useWidth, baseWidth)
        useHeight = math.max(useHeight, baseHeight)
        container:SetSize(useWidth, useHeight)

        -- CRITICAL FIX: Re-apply saved anchor and offsets
        local pos = AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies 
            and AC.DB.profile.moreGoodies.dispels 
            and AC.DB.profile.moreGoodies.dispels.framePos
        local point = (pos and pos.point) or "BOTTOM"
        local relativePoint = (pos and (pos.relativePoint or pos.relative)) or "CENTER"
        local x = (pos and pos.x) or 0
        local y = (pos and pos.y) or 150
        container:ClearAllPoints()
        container:SetPoint(point, UIParent, relativePoint, x + (settings.offsetX or 0), y + (settings.offsetY or 0))
        
        -- CRITICAL FIX: Apply background visibility based on settings
        -- Check if showBackground is explicitly false (user disabled it)
        if settings.showBackground == false then
            -- Background explicitly disabled - HIDE BOTH background and border
            if container.background then
                if not InCombatLockdown() then
                    container.background:Hide()
                end
                container.background:SetAlpha(0)
            end
            -- CRITICAL FIX: Border is a table of textures, iterate through all
            if container.border and type(container.border) == "table" then
                for _, borderTexture in ipairs(container.border) do
                    if borderTexture then
                        if not InCombatLockdown() then
                            borderTexture:Hide()
                        end
                        borderTexture:SetAlpha(0)
                    end
                end
            end
        else
            -- Background enabled (true or nil/default) - SHOW BOTH background and border
            if container.background then
                if not InCombatLockdown() then
                    container.background:Show()
                end
                container.background:SetAlpha(0.95)
            end
            -- CRITICAL FIX: Border is a table of textures, iterate through all
            if container.border and type(container.border) == "table" then
                for _, borderTexture in ipairs(container.border) do
                    if borderTexture then
                        if not InCombatLockdown() then
                            borderTexture:Show()
                        end
                        borderTexture:SetAlpha(1)
                    end
                end
            end
        end
        
        -- Show container AFTER all settings applied
        if not InCombatLockdown() then
            container:Show()
            -- DEBUG REMOVED FOR RELEASE: Container show state
        else
            -- DEBUG REMOVED FOR RELEASE: Combat lockdown warning
        end
    else
        -- DEBUG REMOVED FOR RELEASE: Hiding container state
        if not InCombatLockdown() then
            container:Hide()
        end
    end
end

-- Start dispel cooldown
local function StartDispelCooldown(unit, duration)
    local frame = dispelFrames[unit]
    if not frame then return end
    
    local settings = GetDispelSettings()
    duration = duration or settings.cooldownDuration
    
    -- Start cooldown animation
    if settings.showCooldown then
        frame.cooldown:SetCooldown(GetTime(), duration)
        
        -- CRITICAL FIX: Start countdown timer update (like trinkets/racials)
        local function UpdateDispelTimer()
            if not frame or not frame.cooldown or not frame.timerText then return end
            
            local start, dur = frame.cooldown:GetCooldownTimes()
            if start > 0 and dur > 0 then
                local remaining = (start + dur) / 1000 - GetTime()
                if remaining > 0.5 then
                    -- Format: Just show seconds for 8s cooldown (e.g., "8", "7", "6"...)
                    local timeText = string.format("%.0f", remaining)
                    frame.timerText:SetText(timeText)
                    if not InCombatLockdown() then
                        frame.timerText:Show()
                    end
                    -- Schedule next update
                    C_Timer.After(0.1, UpdateDispelTimer)
                else
                    -- Cooldown finished
                    frame.timerText:SetText("")
                end
            end
        end
        UpdateDispelTimer() -- Start the countdown
    end
    
    -- Set timer for reset
    if dispelTimers[unit] then
        dispelTimers[unit]:Cancel()
    end
    
    dispelTimers[unit] = C_Timer.NewTimer(duration, function()
        -- Reset frame state when cooldown expires
        if frame.cooldown then
            frame.cooldown:Clear()
        end
        if frame.timerText then
            frame.timerText:SetText("")
        end
        dispelTimers[unit] = nil
    end)
end

-- Update dispel frame for unit
local function UpdateDispelFrame(unit)
    local settings = GetDispelSettings()
    
    if not settings.enabled then
        if dispelFrames[unit] then
            dispelFrames[unit]:Hide()
        end
        return
    end
    
    -- Check if unit exists
    local unitExists = UnitExists(unit)
    local hasDispel = UnitHasDispel(unit)
    
    -- CRITICAL FIX: Don't hide dispels when unit doesn't exist (stealth, etc.)
    -- Like racials/trinkets, keep them visible once created
    -- Only skip creation if unit has never existed
    if not unitExists then
        -- If frame already exists, keep it visible (unit in stealth or temporarily gone)
        if dispelFrames[unit] then
        else
            -- Unit has never existed - skip creation
            return
        end
    end
    
    -- Create frame if needed
    local frame = CreateDispelFrame(unit)
    if not frame then 
        return 
    end
    
    -- Update size dynamically in case settings changed
    frame:SetSize(settings.size, settings.size)
    
    -- CRITICAL FIX: Update cooldown spiral visibility (safe in combat - custom frames)
    if frame.cooldown then
        if settings.showCooldown ~= false then
            frame.cooldown:Show()
            if frame.timerText then
                frame.timerText:Show()
            end
        else
            frame.cooldown:Hide()
            if frame.timerText then
                frame.timerText:Hide()
            end
        end
    end
    
    -- CRITICAL FIX: Update or create text to mirror test frame visuals
    -- Check textEnabled setting (false = hide text, true/nil = show text)
    if settings.textEnabled == false then
        -- Text explicitly disabled - hide it
        if frame.text then
            frame.text:Hide()
        end
    else
        -- Text enabled (true or nil/default) - show it
        local textScale = (settings.textScale or 100) / 100
        if not frame.text then
            frame.text = frame:CreateFontString(nil, "OVERLAY")
            frame.text:SetTextColor(1, 1, 1, 1)
        end
        frame.text:SetFont("Fonts\\FRIZQT__.TTF", math.max(6, math.floor(8 * textScale + 0.5)), "")
        frame.text:ClearAllPoints()
        frame.text:SetPoint("TOP", frame, "BOTTOM", settings.textOffsetX or 0, -2 + (settings.textOffsetY or 0))
        frame.text:SetText(GetDisplayName(unit))
        frame.text:Show()
    end

    -- Reposition relative to container each update based on growth direction
    do
        local container = CreateDispelContainer()
        local arenaNum = tonumber(unit:match("arena(%d)"))
        if arenaNum then
            frame:ClearAllPoints()
            local padding, iconSpacing = 10, 5
            local growthDirection = settings.growthDirection or "Horizontal"
            
            if growthDirection == "Vertical" then
                -- Vertical: Stack icons downward
                local yOffset = -padding - (arenaNum - 1) * (settings.size + iconSpacing)
                frame:SetPoint("TOP", container, "TOP", 0, yOffset)
            else
                -- Horizontal: Line up icons to the right
                local xOffset = padding + (arenaNum - 1) * (settings.size + iconSpacing)
                frame:SetPoint("LEFT", container, "LEFT", xOffset, -12)
            end
        end
    end

    -- Set icon
    local icon = GetDispelIcon(unit)
    if icon then
        frame.icon:SetTexture(icon)
        frame:Show()
    else
        frame:Hide()
    end
    
    -- CRITICAL FIX: Apply background visibility to container every time frame is updated
    -- This ensures settings persist in real arena matches
    local container = CreateDispelContainer()
    if container then
        -- Check showBackground setting (false = hide background, true/nil = show background)
        if settings.showBackground == false then
            -- Background explicitly disabled - HIDE BOTH background and border completely
            if container.background then
                container.background:Hide()
                container.background:SetAlpha(0)
            end
            -- CRITICAL FIX: Border is a table of textures, iterate through all
            if container.border and type(container.border) == "table" then
                for _, borderTexture in ipairs(container.border) do
                    if borderTexture then
                        borderTexture:Hide()
                        borderTexture:SetAlpha(0)
                    end
                end
            end
        else
            -- Background enabled (true or nil/default) - SHOW BOTH background and border
            if container.background then
                container.background:Show()
                container.background:SetAlpha(0.95)
            end
            -- CRITICAL FIX: Border is a table of textures, iterate through all
            if container.border and type(container.border) == "table" then
                for _, borderTexture in ipairs(container.border) do
                    if borderTexture then
                        borderTexture:Show()
                        borderTexture:SetAlpha(1)
                    end
                end
            end
        end
    end
end

-- Handle combat log events for dispel tracking
--- PHASE 1.1: Process combat log events (called by centralized handler)
--- @param timestamp number
--- @param combatEvent string
--- @param sourceGUID string
--- @param destGUID string
--- @param spellID number
local function ProcessCombatLogEvent(timestamp, combatEvent, sourceGUID, destGUID, spellID)
    -- We care about dispels being cast (start cooldown immediately) and successful dispels
    if combatEvent ~= "SPELL_CAST_SUCCESS" and combatEvent ~= "SPELL_DISPEL" then return end
    if not DISPEL_SPELLS[spellID] then return end
    
    -- Find which arena unit cast the dispel
    for i = 1, 3 do
        local unit = "arena" .. i
        if UnitExists(unit) and UnitGUID(unit) == sourceGUID then
            -- CRITICAL: Store the spell ID that was actually cast
            lastSpellIDs[unit] = spellID
            
            -- Update the icon immediately to match the spell that was cast
            if dispelFrames[unit] then
                local texture = C_Spell.GetSpellTexture(spellID)
                if texture and dispelFrames[unit].icon then
                    dispelFrames[unit].icon:SetTexture(texture)
                end
                
                -- Update text with actual spell name
                if dispelFrames[unit].text then
                    local spellName = C_Spell.GetSpellName(spellID)
                    if spellName then
                        dispelFrames[unit].text:SetText(spellName)
                    end
                end
            end

            StartDispelCooldown(unit, GetDispelSettings().cooldownDuration)
            break
        end
    end
end

-- Initialize dispel tracking
local function InitializeDispelTracking()
    -- Create event frame
    local eventFrame = CreateFrame("Frame")
    -- PHASE 1.1: COMBAT_LOG now handled by centralized system in ArenaCore.lua
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE") -- CRITICAL: Reset dispels between Solo Shuffle rounds
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Update dispel frames when entering arena or opponents change
            C_Timer.After(0.5, function()
                AC:UpdateDispelFrames()
            end)
        elseif event == "GROUP_ROSTER_UPDATE" then
            -- CRITICAL: Reset dispels between Solo Shuffle rounds
            AC:ClearAllDispels()
        end
    end)
end

-- Public functions
function AC:UpdateDispelFrames()
    -- Update all arena units
    for i = 1, 3 do
        local unit = "arena" .. i
        UpdateDispelFrame(unit)
    end
    
    -- Update container visibility
    UpdateDispelContainer()
end

function AC:RefreshDispelSettings()
    -- Refresh all dispel frames with new settings
    self:UpdateDispelFrames()
end

function AC:RefreshDispelFrames()
    -- CRITICAL: Clear cached settings to force fresh read from database
    cachedSettings = nil
    
    -- CRITICAL: Fully recreate dispel container with new settings
    local settings = GetDispelSettings(true) -- Force refresh
    
    -- Destroy existing container and frames to force recreation with new settings
    if dispelContainer then
        -- Clear all dispel frames
        for unit, frame in pairs(dispelFrames) do
            if frame then
                frame:Hide()
                frame:SetParent(nil)
            end
        end
        wipe(dispelFrames)
        wipe(dispelTimers)
        
        -- Destroy container
        dispelContainer:Hide()
        dispelContainer:SetParent(nil)
        dispelContainer = nil
    end
    
    -- Recreate container with new settings (will be created on next UpdateDispelFrames call)
    -- This ensures size, scale, position, growth direction, and all visual settings are applied
    self:UpdateDispelFrames()
end

--- Clear all dispel cooldowns (for Solo Shuffle round transitions)
--- This is called on GROUP_ROSTER_UPDATE to clear dispels between rounds
function AC:ClearAllDispels()
    -- Only clear if we're in arena
    local instanceType = select(2, IsInInstance())
    if instanceType ~= "arena" then
        return
    end
    
    -- CRITICAL FIX: Clear stale spell IDs from previous rounds
    -- This prevents showing wrong dispel spells on wrong classes in Solo Shuffle
    wipe(lastSpellIDs)
    
    -- Clear all arena frames (1-3 for normal arena)
    for i = 1, 3 do
        local unit = "arena" .. i
        
        -- Clear dispel frame data
        if dispelFrames[unit] then
            local frame = dispelFrames[unit]
            
            -- Hide the frame
            frame:Hide()
            
            -- Clear cooldown
            if frame.cooldown then
                frame.cooldown:Clear()
            end
            
            -- Clear timer text
            if frame.timerText then
                frame.timerText:SetText("")
            end
            
            -- Clear icon texture
            if frame.icon then
                frame.icon:SetTexture(nil)
            end
            
            -- Cancel any active timer for this dispel
            if dispelTimers[unit] then
                dispelTimers[unit]:Cancel()
                dispelTimers[unit] = nil
            end
        end
    end
    
    -- Hide the dispel container
    if dispelContainer then
        dispelContainer:Hide()
    end
end

-- This function will be overridden by DispelWindow.lua
-- Placeholder implementation
function AC:ShowDispelWindow()
end

function AC:TestDispelCooldowns()
    -- Test dispel cooldowns for demonstration
    local settings = GetDispelSettings()
    if not settings.enabled then return end
    
    -- Trigger test cooldowns for arena frames 2 and 3 (skip 1 to show variety)
    StartDispelCooldown("arena2", settings.cooldownDuration)
    C_Timer.After(2, function()
        StartDispelCooldown("arena3", settings.cooldownDuration)
    end)
end

-- PHASE 1.1: Expose ProcessCombatLogEvent for centralized handler
AC.DispelTracker = AC.DispelTracker or {}
AC.DispelTracker.ProcessCombatLogEvent = ProcessCombatLogEvent
AC.DispelTracker.Initialize = InitializeDispelTracking  -- Expose Initialize for ArenaCore

-- Initialize when addon loads
C_Timer.After(1, function()
    InitializeDispelTracking()
end)
