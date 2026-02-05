-- ==========================================================================
-- ArenaCore - Trinkets & Racials module (MIDNIGHT 12.x ONLY)
-- Centralizes cooldown tracking, icon styling, and event handling for enemy
-- trinket and racial abilities. Hooks into Blizzard's CcRemoverFrame for
-- real-time cooldown synchronization.
-- ==========================================================================

local AC = _G.ArenaCore or {}

_G.ArenaCore = AC

---@class ArenaCoreTrinketsRacials
local M = AC:RegisterModule("TrinketsRacials", {})
AC.TrinketsRacials = M

-- Store the frame references we manage by their arena unit token (arena1-5).
local framesByUnit = {}

-- GUID to arena unit lookup so combat log lookups can resolve frames quickly.
local guidToUnit = {}

-- Active ticker handles for cooldown text updates so we can cancel them safely.
local activeTickers = {}

-- PvP trinket spell IDs we track. Values are boolean for quick lookup.
local TRINKET_SPELLS = {
    [208683] = true, -- Gladiator's Medallion (PvP talent effect)
    [214027] = true, -- Adaptation (auto-break)
    [196029] = true, -- Relentless (CC duration reduction)
    [336126] = true, -- Gladiator's Medallion (DPS/Healer) - legacy
    [336135] = true, -- Gladiator's Medallion (Tank) - legacy
    [42292]  = true, -- PvP Trinket (Legacy)
    [195710] = true, -- Honorable Medallion
}

-- Racial spell table storing cooldown durations and optional shared cooldowns.
local RACIAL_SPELLS = {
    -- Alliance
    [59752]  = {duration = 180, shared = 90},  -- Human - Will to Survive
    [20594]  = {duration = 120, shared = 30},  -- Dwarf - Stoneform
    [265221] = {duration = 120, shared = 30},  -- Dark Iron Dwarf - Fireblood
    [58984]  = {duration = 120},               -- Night Elf - Shadowmeld
    [20589]  = {duration =  60},               -- Gnome - Escape Artist
    [59542]  = {duration = 180},               -- Draenei - Gift of the Naaru
    [68992]  = {duration = 120},               -- Worgen - Darkflight
    [107079] = {duration = 120},               -- Pandaren - Quaking Palm
    [255647] = {duration = 150},               -- Lightforged Draenei - Light's Judgment
    [256948] = {duration = 180},               -- Void Elf - Spatial Rift
    [287712] = {duration = 160},               -- Kul Tiran - Haymaker
    [312924] = {duration = 180},               -- Mechagnome - Hyper Organic Light Originator
    [312411] = {duration =  90},               -- Vulpera - Bag of Tricks
    [436344] = {duration = 120},               -- Earthen - Azerite Surge

    -- Horde
    [33697]  = {duration = 120},               -- Orc - Blood Fury
    [20549]  = {duration =  90},               -- Tauren - War Stomp
    [26297]  = {duration = 180},               -- Troll - Berserking
    [274738] = {duration = 120},               -- Mag'har Orc - Ancestral Call
    [291944] = {duration = 160},               -- Zandalari - Regeneratin'
    [202719] = {duration =  90},               -- Blood Elf - Arcane Torrent
    [69070]  = {duration =  90},               -- Goblin - Rocket Jump
    [7744]   = {duration = 120, shared = 30},  -- Undead - Will of the Forsaken
    [260364] = {duration = 180},               -- Nightborne - Arcane Pulse

    -- Dragon Isles
    [368970] = {duration =  90},               -- Dracthyr - Tail Swipe / Wing Buffet
}

-- --------------------------------------------------------------------------
-- Helper utilities
-- --------------------------------------------------------------------------

---Check if we have reliable race data for arena units (for first round detection)
local function HasReliableRaceData()
    -- Check if any arena units have reliable race data
    for i = 1, 3 do
        local unit = "arena" .. i
        if UnitExists(unit) then
            local _, race = UnitRace(unit)
            if race and race ~= "" and race ~= "Unknown" then
                return true
            end
        end
    end
    return false
end

---Return the shared profile table for trinket settings.
local function GetTrinketProfile()
    if not AC.DB or not AC.DB.profile then
        return nil
    end
    AC.DB.profile.trinkets = AC.DB.profile.trinkets or {
        enabled = true,
        iconDesign = "retail",
    }
    return AC.DB.profile.trinkets
end

---Return the shared profile table for racial settings.
local function GetRacialProfile()
    if not AC.DB or not AC.DB.profile then
        return nil
    end
    AC.DB.profile.racials = AC.DB.profile.racials or {
        enabled = true,
    }
    return AC.DB.profile.racials
end

---Simple healer check copied from the core for self-contained logic.
local function IsHealer(unit)
    if not unit then
        return false
    end
    local index = unit:match("arena(%d)")
    if not index then
        return false
    end
    local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(tonumber(index))
    if specID and specID > 0 then
        local _, _, _, _, role = GetSpecializationInfoByID(specID)
        return role == "HEALER"
    end
    return false
end

---Stop and clear the ticker tied to a cooldown indicator (if any).
local function StopTicker(indicator)
    if not indicator then
        return
    end
    if indicator._trTicker then
        indicator._trTicker:Cancel()
        indicator._trTicker = nil
    end
    if indicator.cooldown and indicator.cooldown.Text then
        indicator.cooldown.Text:SetText("")
        indicator.cooldown.Text:Hide()
    end
end

---Start a ticker to update cooldown text every 0.1s for a given indicator.
local function StartTicker(indicator)
    if not indicator or not indicator.cooldown or not indicator.cooldown.Text then
        return
    end
    
    -- CRITICAL FIX: Use database font size settings, don't hardcode
    -- The font may have been set during creation, but we need to ensure it's correct
    local txt = indicator.cooldown.Text
    if txt then
        -- Always re-apply the correct font size from database settings
        -- This ensures consistency even if font was cleared or reset elsewhere
        local fontSize = 10 -- Default fallback
        
        if AC.DB and AC.DB.profile then
            -- Check if this is a racial indicator (has _isRacial flag set during creation)
            if indicator._isRacial and AC.DB.profile.racials and AC.DB.profile.racials.sizing then
                fontSize = AC.DB.profile.racials.sizing.fontSize or 10
            elseif not indicator._isRacial and AC.DB.profile.trinkets and AC.DB.profile.trinkets.sizing then
                fontSize = AC.DB.profile.trinkets.sizing.fontSize or 10
            end
        end
        
        -- CRITICAL FIX: Always use custom ArenaCore font for consistency
        txt:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", fontSize, "OUTLINE")
    end
    
    StopTicker(indicator)
    indicator._trTicker = C_Timer.NewTicker(0.1, function()
        local startTime, duration = indicator.cooldown:GetCooldownTimes()
        if not startTime or startTime == 0 or not duration or duration == 0 then
            StopTicker(indicator)
            return
        end
        -- CRITICAL FIX: Divide each value by 1000 individually (milliseconds to seconds)
        -- GetCooldownTimes() returns milliseconds in Midnight
        startTime, duration = startTime / 1000, duration / 1000
        local remaining = (startTime + duration) - GetTime()
        if remaining <= 0.5 then
            StopTicker(indicator)
            return
        end
        local minutes = math.floor(remaining / 60)
        local seconds = math.floor(remaining % 60)
        indicator.cooldown.Text:SetFormattedText("%d:%02d", minutes, seconds)
        indicator.cooldown.Text:Show()
    end)
end

---Refresh the visible icon for the trinket indicator based on current profile.
local function ApplyTrinketIcon(indicator)
    if not indicator then
        return
    end
    local profile = GetTrinketProfile()
    if profile and profile.enabled == false then
        indicator:Hide()
        return
    end
    if indicator.icon then
        local icon = AC.TrinketsRacials and AC.TrinketsRacials:GetUserTrinketIcon()
        if type(icon) == "string" then
            indicator.icon:SetTexture(icon)
        elseif type(icon) == "number" then
            local texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(icon)
            indicator.icon:SetTexture(texture or icon)
        else
            indicator.icon:SetTexture(nil)
        end
        indicator.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    elseif indicator.texture then
        local icon = AC.TrinketsRacials and AC.TrinketsRacials:GetUserTrinketIcon()
        if type(icon) == "string" then
            indicator.texture:SetTexture(icon)
        elseif type(icon) == "number" then
            local texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(icon)
            indicator.texture:SetTexture(texture or icon)
        else
            indicator.texture:SetTexture(nil)
        end
        indicator.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end
end

-- ==========================================================================
-- ARENACORE TRINKET TRACKING (MIDNIGHT 12.x)
-- Uses sArena's method: ARENA_COOLDOWNS_UPDATE event + C_PvP.GetArenaCrowdControlInfo API
-- ==========================================================================

---Query Blizzard API and apply trinket cooldown for a unit.
---@param unitToken string Arena unit token (arena1-5)
local function UpdateTrinketCooldown(unitToken)
    if not unitToken or not C_PvP or not C_PvP.GetArenaCrowdControlInfo then
        return
    end
    
    -- API returns milliseconds - convert to seconds (same as Blizzard's CompactArenaFrame.lua line 392-394)
    local spellID, startTimeMs, durationMs = C_PvP.GetArenaCrowdControlInfo(unitToken)
    local startTime = startTimeMs and (startTimeMs / 1000) or 0
    local duration = durationMs and (durationMs / 1000) or 0
    
    local frame = framesByUnit[unitToken] or (AC.GetFrameForUnit and AC.GetFrameForUnit(unitToken))
    if not frame or not frame.trinketIndicator then
        return
    end
    
    local indicator = frame.trinketIndicator
    
    -- Update spell ID and icon if changed
    if spellID and spellID ~= 0 then
        if spellID ~= indicator.spellID then
            indicator.spellID = spellID
            ApplyTrinketIcon(indicator)
        end
        
        -- Apply cooldown if we have valid timing data
        if startTime > 0 and duration > 0 then
            if indicator.cooldown then
                indicator.cooldown:SetCooldown(startTime, duration)
                indicator:Show()
                StartTicker(indicator)
            end
        end
    end
end

---Update all arena trinket cooldowns.
local function UpdateAllTrinketCooldowns()
    for i = 1, 5 do
        local unit = "arena" .. i
        if UnitExists(unit) then
            UpdateTrinketCooldown(unit)
        end
    end
end

---Update trinket icon when spell ID changes (from ARENA_CROWD_CONTROL_SPELL_UPDATE).
---@param unitToken string Arena unit token
---@param spellID number The trinket spell ID
local function UpdateTrinketIcon(unitToken, spellID)
    if not unitToken then
        return
    end
    
    local frame = framesByUnit[unitToken] or (AC.GetFrameForUnit and AC.GetFrameForUnit(unitToken))
    if not frame or not frame.trinketIndicator then
        return
    end
    
    local indicator = frame.trinketIndicator
    if spellID and spellID ~= 0 then
        indicator.spellID = spellID
        ApplyTrinketIcon(indicator)
    end
end


---Start racial cooldown for a frame.
---@param frame Frame The arena frame
---@param spellID number The racial spell ID
local function StartRacialCooldown(frame, spellID)
    if not frame or not frame.racialIndicator then
        return
    end
    local profile = GetRacialProfile()
    if profile and profile.enabled == false then
        return
    end
    local data = RACIAL_SPELLS[spellID]
    if not data then
        return
    end
    local indicator = frame.racialIndicator
    if indicator.cooldown then
        indicator.cooldown:SetCooldown(GetTime(), data.duration or 120)
    end
    indicator.spellID = spellID
    indicator:Show()
    if indicator.icon then
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
        if info and info.iconID then
            indicator.icon:SetTexture(info.iconID)
        end
    end
    StartTicker(indicator)
end

---Handle shared cooldown logic between racials and trinkets.
---@param frame Frame The arena frame
local function ApplySharedCooldown(frame)
    local racialIndicator = frame and frame.racialIndicator
    local trinketIndicator = frame and frame.trinketIndicator
    if not racialIndicator or not racialIndicator.spellID then
        return
    end
    local data = RACIAL_SPELLS[racialIndicator.spellID]
    if not data or not data.shared or not trinketIndicator or not trinketIndicator.cooldown then
        return
    end
    local startTime, duration = trinketIndicator.cooldown:GetCooldownTimes()
    if not startTime or startTime == 0 or not duration then
        return
    end
    -- Convert from milliseconds to seconds
    startTime, duration = startTime * MS_TO_SEC, duration * MS_TO_SEC
    local remaining = (startTime + duration) - GetTime()
    if remaining > 0 and remaining <= data.shared then
        racialIndicator.cooldown:SetCooldown(GetTime(), data.shared)
        StartTicker(racialIndicator)
    end
end

---Fetch (and remember) the arena unit for a GUID by scanning arena opponents.
local function ResolveUnitForGUID(guid)
    if guidToUnit[guid] then
        return guidToUnit[guid]
    end
    for i = 1, 5 do
        local unit = "arena" .. i
        local unitGUID = UnitGUID(unit)
        if unitGUID then
            guidToUnit[unitGUID] = unit
        end
        if unitGUID == guid then
            return unit
        end
    end
end

---Create a racial indicator frame (centralized creation logic).
---This replaces the CreateRacial function that was in ArenaCore.lua.
---@param parent Frame The parent arena frame
---@param frameIndex number The arena frame index (1-3)
---@return Frame The created racial indicator frame
function M:CreateRacialIndicator(parent, frameIndex)
    if not parent then
        return nil
    end
    
    -- EXACT COPY OF TRINKET CREATION - ONLY DIFFERENCES: position and variable names
    local r = CreateFrame("Frame", nil, parent)
    r:SetSize(20, 20)
    r:SetPoint("TOPRIGHT", -50, -6) -- Position to avoid trinket overlap (only difference from trinkets)
    -- Set MEDIUM strata to stay below bags while rendering above health/mana bars
    r:SetFrameStrata("MEDIUM") -- CRITICAL: Use MEDIUM to stay below bags
    r:SetFrameLevel(50) -- High level within MEDIUM strata
    
    -- Racial icon texture (full texture for rounded edges)
    local icon = r:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Cropped for racial icons
    
    -- Orange overlay border only (ArenaCore styling - no background texture)
    -- CRITICAL FIX: Border should extend slightly beyond icon for proper visibility
    local br = r:CreateTexture(nil, "OVERLAY")
    br:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
    br:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    br:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\orangeoverlay.tga")
    br:SetTexCoord(0, 1, 0, 1) -- Full texture for rounded overlay
    
    -- CRITICAL: Override SetTexture to apply TRILINEAR filtering for smooth scaling
    -- This prevents pixelation when racial icons are scaled up beyond base size
    icon.SetTexture = function(self, texture, ...)
        getmetatable(self).__index.SetTexture(self, texture, true, true)
    end
    
    -- Create cooldown frame (using helper to block OmniCC)
    local cd = AC:CreateCooldown(r, nil, "CooldownFrameTemplate")
    cd:SetAllPoints(icon) -- CRITICAL FIX: Match icon size, not frame size
    cd:SetDrawBling(false) -- Disable bling animation
    cd:SetHideCountdownNumbers(true) -- CRITICAL: Hide Blizzard's numbers so our custom text shows
    
    -- Create cooldown text with user-configurable font size
    local txt = cd:CreateFontString(nil, "OVERLAY")
    local racialProfile = GetRacialProfile()
    local fontSize = racialProfile and racialProfile.sizing and racialProfile.sizing.fontSize or 10
    txt:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", fontSize, "OUTLINE")
    txt:SetPoint("CENTER", r, "CENTER", 0, 0)
    txt:SetTextColor(1, 1, 1, 1)
    txt:SetJustifyH("CENTER")
    txt:SetJustifyV("MIDDLE")
    txt:Show()
    cd.Text = txt
    
    -- Store references (EXACT same order as trinkets)
    r.texture = icon
    r.icon = icon  -- Also store as .icon for consistency
    r.cooldown = cd
    r.border = br
    r.text = txt  -- Make text accessible for UpdateElement
    r.txt = txt   -- Also store as .txt for looping cooldown code
    r._isRacial = true -- Flag for font size detection in StartTicker
    
    -- Apply initial icon (test mode or fallback)
    local unit = parent.unit or ("arena" .. frameIndex)
    self:ApplyRacialIcon(r, unit)
    
    return r
end

---Attach a newly created frame so the module can manage its indicators.
function M:Attach(frame, unit)
    if not frame or not unit then
        return
    end
    framesByUnit[unit] = frame
    local guid = UnitGUID(unit)
    if guid then
        guidToUnit[guid] = unit
    end
    ApplyTrinketIcon(frame.trinketIndicator)
    self:RefreshFrame(frame, unit)
end

---Apply racial icon based on test mode or detected race.
---CRITICAL FIX: Always show indicator (like trinkets), just update icon when race detected
---PHASE 3 FIX: Changed from local to module function so CreateRacialIndicator can call it
function M:ApplyRacialIcon(indicator, unit)
    if not indicator then
        return
    end
    
    -- Default fallback icon (question mark) if race not detected yet
    local fallbackIcon = 134400 -- Question mark icon
    local racialSpellID = nil
    
    -- In test mode, use test racial icons
    if AC.testModeEnabled then
        -- Test mode racial icons: DK=Human, Mage=BloodElf, Hunter=Orc
        local testRacials = {
            [1] = 59752,  -- Human - Will to Survive
            [2] = 202719, -- Blood Elf - Arcane Torrent
            [3] = 33697,  -- Orc - Blood Fury
        }
        
        local frameIndex = unit and tonumber(unit:match("arena(%d)")) or 1
        racialSpellID = testRacials[frameIndex] or testRacials[1]
    elseif unit and UnitExists(unit) then
        -- Real arena mode - use detected race
        local _, race = UnitRace(unit)
        -- print("|cffFFFF00[RACIAL_DEBUG]|r", unit, "- UnitExists:", UnitExists(unit), "UnitRace returned:", race or "NIL")
        
        if race and race ~= "" and race ~= "Unknown" then
            local normalizedRace = race:gsub("[%s']", "")
            racialSpellID = M:GetRacialSpellID(normalizedRace) or M:GetRacialSpellID(race)
            
            if racialSpellID then
                -- print("|cff00FF00[RACIAL_SUCCESS]|r", unit, "- Race:", race, "SpellID:", racialSpellID)
            else
                -- print("|cffFF0000[RACIAL_ERROR]|r", unit, "- Race detected:", race, "but NO racial spell found!")
            end
        else
            -- Race data not available yet - show memelol placeholder icon
            -- This acts as placeholder in prep room / first round until real race detected
            if indicator.icon then
                indicator.icon:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\racialicon\\memelol.tga")
                indicator.icon:SetTexCoord(0, 1, 0, 1)
            elseif indicator.texture then
                indicator.texture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\racialicon\\memelol.tga")
            end
            indicator:Show()
            return
        end
    else
        -- Unit doesn't exist yet - show memelol placeholder icon
        if indicator.icon then
            indicator.icon:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\racialicon\\memelol.tga")
            indicator.icon:SetTexCoord(0, 1, 0, 1)
        elseif indicator.texture then
            indicator.texture:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\racialicon\\memelol.tga")
        end
        indicator:Show()
        return
    end
    
    -- Set icon texture (use racial icon if found, otherwise fallback)
    if indicator.icon then
        if racialSpellID then
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(racialSpellID)
            if info and info.iconID then
                indicator.icon:SetTexture(info.iconID)
            else
                indicator.icon:SetTexture(fallbackIcon)
            end
        else
            indicator.icon:SetTexture(fallbackIcon)
        end
        indicator.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    elseif indicator.texture then
        if racialSpellID then
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(racialSpellID)
            if info and info.iconID then
                indicator.texture:SetTexture(info.iconID)
            else
                indicator.texture:SetTexture(fallbackIcon)
            end
        else
            indicator.texture:SetTexture(fallbackIcon)
        end
        indicator.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end
    
    -- NOTE: Don't call indicator:Show() here - that's handled in RefreshFrame() like trinkets
end

---Refresh a single frame (icon visibility, fonts, etc.).
function M:RefreshFrame(frame, unit)
    if not frame then
        return
    end
    
    -- CRITICAL FIX: Detect prep room state and first round detection
    -- Prep room = specs exist but units don't
    -- Live arena = units exist
    local _, instanceType = IsInInstance()
    local inPrepRoom = false
    local isFirstArenaOrRound = false
    
    if instanceType == "arena" then
        local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs()
        if numOpponents and numOpponents > 0 then
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
            
            -- CRITICAL FIX: Detect if this is first arena/round by checking race data availability
            -- First arena/round = either no units exist OR units exist but no reliable race data yet
            isFirstArenaOrRound = not anyUnitExists or not HasReliableRaceData()
        end
    end
    
    local trinketProfile = GetTrinketProfile()
    if frame.trinketIndicator then
        if trinketProfile and trinketProfile.enabled == false then
            frame.trinketIndicator:Hide()
        else
            ApplyTrinketIcon(frame.trinketIndicator)
        end
    end
    
    local racialProfile = GetRacialProfile()
    if frame.racialIndicator then
        if racialProfile and racialProfile.enabled == false then
            frame.racialIndicator:Hide()
        else
            -- ApplyRacialIcon handles placeholder (memelol) when race data not available
            -- and auto-swaps to real racial icon once race is detected
            self:ApplyRacialIcon(frame.racialIndicator, unit)
        end
    end
    if unit then
        self:UpdateCrowdControlSpell(unit)
    end
end

---Refresh every tracked frame (used on profile changes and enabling).
function M:RefreshAll()
    for unit, frame in pairs(framesByUnit) do
        self:RefreshFrame(frame, unit)
    end
end

---Get the configured trinket icon (public so UI/layout can call it).
function M:GetUserTrinketIcon()
    local profile = GetTrinketProfile()
    local design = profile and profile.iconDesign or "retail"
    if design == "horde" then
        return "Interface\\Icons\\INV_Jewelry_TrinketPVP_02"
    elseif design == "alliance" then
        return "Interface\\Icons\\INV_Jewelry_TrinketPVP_01"
    else
        return 1322720 -- Retail Gladiator's Medallion
    end
end

---Handle spell cast for trinket/racial detection.
---Called from combat log or unit spellcast events.
---FALLBACK: Also handles trinket spells when API fails (mismatched games)
---@param frame Frame The arena frame (optional, will be looked up if nil)
---@param unit string The unit token
---@param spellID number The spell ID cast
function M:HandleSpell(frame, unit, spellID)
    if not spellID then
        return
    end
    
    -- Resolve unit if not provided
    if not unit and frame and frame.unit then
        unit = frame.unit
    end
    
    -- Resolve frame if not provided
    if unit and not frame then
        frame = framesByUnit[unit] or (AC.GetFrameForUnit and AC.GetFrameForUnit(unit))
    end
    
    if not frame then
        return
    end
    
    -- Cache references
    if frame and unit then
        framesByUnit[unit] = frame
    end
    if unit then
        local guid = UnitGUID(unit)
        if guid then
            guidToUnit[guid] = unit
        end
    end
    
    -- Handle racial spells only (trinkets use Blizzard hook method)
    if RACIAL_SPELLS[spellID] then
        StartRacialCooldown(frame, spellID)
        ApplySharedCooldown(frame)
    end
end

---Expose racial spell ID lookup for compatibility with existing calls.
function M:GetRacialSpellID(race)
    if not race then
        return nil
    end
    local lookup = {
        Human = 59752,
        Dwarf = 20594,
        NightElf = 58984,
        Gnome = 20589,
        Draenei = 59542,
        Worgen = 68992,
        Pandaren = 107079,
        Orc = 33697,
        Scourge = 7744,
        Tauren = 20549,
        Troll = 26297,
        BloodElf = 202719,
        Goblin = 69070,
        LightforgedDraenei = 255647,
        HighmountainTauren = 255654,
        Nightborne = 260364,
        Vulpera = 312411,
        VoidElf = 256948,
        ZandalariTroll = 291944,
        MagharOrc = 274738,
        DarkIronDwarf = 265221,
        KulTiran = 287712,
        Mechagnome = 312924,
        Dracthyr = 368970,
        EarthenDwarf = 436344,
    }
    return lookup[race]
end

---Handle ARENA_CROWD_CONTROL_SPELL_UPDATE event.
---@param unit string Arena unit token
---@param spellID number The trinket spell ID
function M:OnCrowdControlSpell(unit, spellID)
    UpdateTrinketIcon(unit, spellID)
end

---Rescan the Blizzard reported trinket spell after a refresh.
function M:UpdateCrowdControlSpell(unit)
    if not unit then
        return
    end
    local frame = framesByUnit[unit]
    if not frame then
        return
    end
    -- If Blizzard already told us the spell, ensure icon matches current design.
    if frame.trinketIndicator then
        ApplyTrinketIcon(frame.trinketIndicator)
    end
end

---Handle UNIT_SPELLCAST_SUCCEEDED for racial detection.
---Trinkets are handled via ARENA_COOLDOWNS_UPDATE API.
---@param unit string Unit token
---@param spellID number Spell ID cast
function M:OnUnitSpellCast(unit, spellID)
    if not unit or not spellID then
        return
    end
    -- Only handle racials via spellcast (trinkets use API)
    if RACIAL_SPELLS[spellID] then
        local frame = framesByUnit[unit] or (AC.GetFrameForUnit and AC.GetFrameForUnit(unit))
        if frame then
            self:HandleSpell(frame, unit, spellID)
        end
    end
end

---Handle combat log SPELL_CAST_SUCCESS for racial detection.
---Trinkets use Blizzard hook method (same as sArena).
---@param sourceGUID string Source GUID
---@param spellID number Spell ID cast
function M:OnCombatLogSpell(sourceGUID, spellID)
    if not sourceGUID or not spellID then
        return
    end
    -- Only handle racials via combat log (trinkets use Blizzard hook)
    if RACIAL_SPELLS[spellID] then
        local unit = ResolveUnitForGUID(sourceGUID)
        if unit then
            local frame = framesByUnit[unit] or (AC.GetFrameForUnit and AC.GetFrameForUnit(unit))
            if frame then
                self:HandleSpell(frame, unit, spellID)
            end
        end
    end
end

---Cleanup all indicators when the module is disabled.
local function HideAllIndicators()
    for unit, frame in pairs(framesByUnit) do
        if frame.trinketIndicator then
            StopTicker(frame.trinketIndicator)
            frame.trinketIndicator:Hide()
        end
        if frame.racialIndicator then
            StopTicker(frame.racialIndicator)
            frame.racialIndicator:Hide()
        end
    end
end

-- --------------------------------------------------------------------------
-- Module lifecycle
-- --------------------------------------------------------------------------

---Ensure base settings exist when SavedVariables are ready.
function M:OnInit()
    GetTrinketProfile()
    GetRacialProfile()
end

---Create (or reuse) the hidden frame used to listen for game events.
function M:_EnsureEventFrame()
    if self._eventFrame then
        return self._eventFrame
    end
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(_, event, ...)
        self:HandleEvent(event, ...)
    end)
    self._eventFrame = frame
    return frame
end

---Register the events we need while the module is enabled.
function M:_RegisterEvents()
    local frame = self:_EnsureEventFrame()
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE") -- CRITICAL: Reset trinkets/racials between Solo Shuffle rounds
    
    -- MIDNIGHT: Primary events for trinket tracking
    frame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")     -- Server pushes cooldown state
    frame:RegisterEvent("ARENA_OPPONENT_UPDATE")      -- Guarantees Blizzard frames exist
    frame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS") -- Early prep room detection
end

---Unregister all events when the module is disabled or reloading.
function M:_UnregisterEvents()
    if self._eventFrame then
        self._eventFrame:UnregisterAllEvents()
    end
end

---Called when the module is enabled (after ADDON_LOADED).
function M:OnEnable()
    self:_RegisterEvents()
    wipe(guidToUnit)
    
    -- Delayed refresh to ensure frames are ready after login
    C_Timer.After(0.25, function()
        self:RefreshAll()
    end)
end

---Called when the module is disabled (addon shutdown, reload, etc.).
function M:OnDisable()
    self:_UnregisterEvents()
    HideAllIndicators()
end

---React to profile changes from the core profile manager.
function M:OnProfileChanged()
    self:RefreshAll()
end

---Central event dispatcher for trinket/racial tracking.
---Hooks Blizzard's CcRemoverFrame to mirror cooldowns (same method as sArena).
function M:HandleEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        wipe(guidToUnit)
        self:RefreshAll()
        
    elseif event == "ARENA_COOLDOWNS_UPDATE" then
        -- CRITICAL: This is when Blizzard tells us a trinket cooldown changed
        -- Query API for all arena units to get updated cooldown data
        UpdateAllTrinketCooldowns()
        
    elseif event == "ARENA_OPPONENT_UPDATE" then
        -- Opponent detected - query their trinket cooldown
        local unit, updateReason = ...
        if unit and updateReason == "seen" then
            UpdateTrinketCooldown(unit)
        end
        
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        -- Prep room - nothing to do yet (no cooldowns in prep)
        
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Solo Shuffle round transition - reset cooldowns
        self:ResetAllCooldowns()
        
    elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" then
        -- Spell ID changed - update icon and query cooldown
        local unit, spellID = ...
        UpdateTrinketIcon(unit, spellID)
        -- Also query cooldown in case it's available now
        if unit then
            UpdateTrinketCooldown(unit)
        end
    end
end

---Reset all trinket and racial cooldowns (for Solo Shuffle round transitions).
function M:ResetAllCooldowns()
    local instanceType = select(2, IsInInstance())
    if instanceType ~= "arena" then
        return
    end
    
    for i = 1, 5 do
        local unit = "arena" .. i
        local frame = AC.GetFrameForUnit and AC.GetFrameForUnit(unit)
        
        if frame then
            -- Reset trinket indicator
            if frame.trinketIndicator then
                if frame.trinketIndicator.cooldown then
                    frame.trinketIndicator.cooldown:Clear()
                end
                StopTicker(frame.trinketIndicator)
            end
            
            -- Reset racial indicator
            if frame.racialIndicator then
                if frame.racialIndicator.cooldown then
                    frame.racialIndicator.cooldown:Clear()
                end
                StopTicker(frame.racialIndicator)
            end
        end
    end
end

-- --------------------------------------------------------------------------
-- Public helpers for legacy/core compatibility
-- --------------------------------------------------------------------------

---Legacy compatibility wrapper: refresh icon layout when options change.
function M:RefreshLayout()
    self:RefreshAll()
end

-- ==========================================================================
-- ARENACORE AUTHORITATIVE SYNC - PUBLIC METHODS
-- These methods query Blizzard's API for server-authoritative cooldown timing
-- ==========================================================================

---Request trinket spell data from server for a unit.
---Mirrors what Blizzard does in CompactArenaFrame when setting unit.
---@param unitToken string Arena unit token (arena1-arena5)
function M:RequestTrinketSpellData(unitToken)
    if not unitToken or not C_PvP or not C_PvP.RequestCrowdControlSpell then
        return
    end
    if UnitExists(unitToken) then
        C_PvP.RequestCrowdControlSpell(unitToken)
    end
end

---Resync trinket cooldown for a specific arena unit using server data.
---@param unitToken string Arena unit token
function M:ResyncTrinketForUnit(unitToken)
    UpdateTrinketForUnit(unitToken)
end

---Resync ALL arena trinket cooldowns using server data.
function M:ResyncAllTrinketCooldowns()
    UpdateAllTrinkets()
end

return M
