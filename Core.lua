-- Gladius Midnight - Core Addon Logic
-- Arena Unit Frames for WoW Midnight 12.0
-- Uses Secret Values API (Curves) for health/power display

local addonName, GladiusMidnight = ...
GladiusMidnight.frames = {}
GladiusMidnight.arenaUnits = { "arena1", "arena2", "arena3" }

-- Default settings
GladiusMidnight.defaults = {
    enabled = true,
    locked = false,
    scale = 1.0,
    showHealthText = true,
    showResourceText = true,
    showTrinket = true,
    showRacial = true,
    growDirection = "DOWN",
    spacing = 5,
    frameWidth = 200,
    frameHeight = 50,
    posX = -100,
    posY = 0,
}

-- Initialize addon
local function InitializeAddon()
    -- Load saved settings or use defaults
    if not GladiusMidnightDB then
        GladiusMidnightDB = {}
    end

    for key, value in pairs(GladiusMidnight.defaults) do
        if GladiusMidnightDB[key] == nil then
            GladiusMidnightDB[key] = value
        end
    end

    GladiusMidnight.db = GladiusMidnightDB
end

-- Create health color curve for 12.0 secret values
-- Curves allow us to display secret values without accessing them directly
local function CreateHealthColorCurve()
    -- Health curve: Green (100%) -> Yellow (50%) -> Red (0%)
    local curve = C_CurveUtil.CreateColorCurve()
    if curve then
        curve:AddPoint(0.0, CreateColor(1.0, 0.0, 0.0, 1.0)) -- Red at 0%
        curve:AddPoint(0.5, CreateColor(1.0, 1.0, 0.0, 1.0)) -- Yellow at 50%
        curve:AddPoint(1.0, CreateColor(0.0, 1.0, 0.0, 1.0)) -- Green at 100%
        return curve
    end
    return nil
end

-- Create a value curve for health percentage
local function CreateHealthValueCurve()
    local curve = C_CurveUtil.CreateCurve()
    if curve then
        curve:AddPoint(0.0, 0)
        curve:AddPoint(1.0, 100)
        return curve
    end
    return nil
end

GladiusMidnight.healthColorCurve = nil
GladiusMidnight.healthValueCurve = nil

-- Initialize frame for a specific arena unit
local function InitializeArenaFrame(frame, unitIndex)
    local unit = "arena" .. unitIndex
    frame.unit = unit
    frame.unitIndex = unitIndex

    -- Store reference
    GladiusMidnight.frames[unit] = frame

    -- Initialize sub-elements
    frame.HealthBar:SetMinMaxValues(0, 100)
    frame.ResourceBar:SetMinMaxValues(0, 100)

    -- Set up class icon with mask
    frame.ClassIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Initialize trinket/racial frames
    if frame.Trinket then
        frame.Trinket.unit = unit
        frame.Trinket.Icon:SetTexture("Interface\\Icons\\INV_Jewelry_TrinketPVP_01")
    end

    if frame.Racial then
        frame.Racial.unit = unit
        frame.Racial.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- Register unit-specific events
    frame:RegisterUnitEvent("UNIT_HEALTH", unit)
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    frame:RegisterUnitEvent("UNIT_POWER_UPDATE", unit)
    frame:RegisterUnitEvent("UNIT_MAXPOWER", unit)
    frame:RegisterUnitEvent("UNIT_AURA", unit)

    -- Set up frame scripts
    frame:SetScript("OnEvent", GladiusMidnight.OnFrameEvent)

    -- Make frame draggable when unlocked
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not GladiusMidnight.db.locked then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        GladiusMidnight.db["frame" .. unitIndex .. "Point"] = point
        GladiusMidnight.db["frame" .. unitIndex .. "RelPoint"] = relativePoint
        GladiusMidnight.db["frame" .. unitIndex .. "X"] = xOfs
        GladiusMidnight.db["frame" .. unitIndex .. "Y"] = yOfs
    end)

    frame:Hide()
end

-- Update health bar using 12.0 secret values API
function GladiusMidnight:UpdateHealth(frame)
    local unit = frame.unit
    if not UnitExists(unit) then
        return
    end

    local healthBar = frame.HealthBar

    -- In 12.0, UnitHealth returns secret values when called from tainted code
    -- We use UnitHealthPercent which returns a secret that can be passed to StatusBar:SetValue
    local healthPercent = UnitHealthPercent(unit)

    -- SetValue accepts secret values in 12.0
    if healthPercent then
        healthBar:SetValue(healthPercent)
    end

    -- Update health text if enabled
    -- Note: In 12.0, we can use string.format with secrets
    if self.db.showHealthText and healthBar.Text then
        -- UnitHealthPercent returns 0-100 range as secret
        -- We can format it directly since string.format accepts secrets
        local textValue = string.format("%.0f%%", healthPercent or 0)
        healthBar.Text:SetText(textValue)
    end

    -- Update health bar color based on class
    local _, class = UnitClass(unit)
    if class then
        local color = self.ClassResources:GetClassColor(class)
        healthBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end

-- Update resource/power bar
function GladiusMidnight:UpdatePower(frame)
    local unit = frame.unit
    if not UnitExists(unit) then
        return
    end

    local resourceBar = frame.ResourceBar
    local _, class = UnitClass(unit)

    -- Get spec-specific power type if available
    local specID = nil
    if GetArenaOpponentSpec then
        specID = GetArenaOpponentSpec(frame.unitIndex)
    end

    local powerType = self.ClassResources:GetPowerType(class, specID)

    -- In 12.0, secondary resources (combo points, holy power, etc.) are NOT secrets
    -- Primary resources may be secrets, so we use UnitPowerPercent
    local powerPercent = UnitPowerPercent(unit, powerType)

    if powerPercent then
        resourceBar:SetValue(powerPercent)
    end

    -- Update power bar color
    local color = self.ClassResources:GetPowerColor(powerType)
    resourceBar:SetStatusBarColor(color.r, color.g, color.b)

    -- Update text
    if self.db.showResourceText and resourceBar.Text then
        local textValue = string.format("%.0f%%", powerPercent or 0)
        resourceBar.Text:SetText(textValue)
    end
end

-- Update class icon
function GladiusMidnight:UpdateClassIcon(frame)
    local unit = frame.unit
    if not UnitExists(unit) then
        return
    end

    local _, class = UnitClass(unit)
    if class then
        -- Use atlas for class icons (modern approach)
        local atlasName = self.ClassResources.ClassIcons[class]
        if atlasName then
            frame.ClassIcon:SetAtlas(atlasName)
        else
            -- Fallback to texture file
            local coords = CLASS_ICON_TCOORDS[class]
            if coords then
                frame.ClassIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                frame.ClassIcon:SetTexCoord(unpack(coords))
            end
        end
    end
end

-- Update entire frame for a unit
function GladiusMidnight:UpdateFrame(frame)
    if not frame or not frame.unit then
        return
    end

    local unit = frame.unit
    if not UnitExists(unit) then
        frame:Hide()
        return
    end

    self:UpdateHealth(frame)
    self:UpdatePower(frame)
    self:UpdateClassIcon(frame)

    -- Update trinket module
    if self.Trinkets and self.db.showTrinket then
        self.Trinkets:UpdateTrinket(frame)
    end

    -- Update racial module
    if self.Racials and self.db.showRacial then
        self.Racials:UpdateRacial(frame)
    end

    frame:Show()
end

-- Frame event handler
function GladiusMidnight.OnFrameEvent(frame, event, ...)
    local unit = ...

    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        GladiusMidnight:UpdateHealth(frame)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        GladiusMidnight:UpdatePower(frame)
    elseif event == "UNIT_AURA" then
        -- Aura updates can affect trinket/racial tracking
        if GladiusMidnight.Trinkets then
            GladiusMidnight.Trinkets:UpdateTrinket(frame)
        end
    end
end

-- Main event handler
local mainFrame = CreateFrame("Frame")
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mainFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
mainFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
mainFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
mainFrame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
mainFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

mainFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            InitializeAddon()

            -- Initialize curves for 12.0 secret values
            GladiusMidnight.healthColorCurve = CreateHealthColorCurve()
            GladiusMidnight.healthValueCurve = CreateHealthValueCurve()

            -- Initialize arena frames
            for i = 1, 3 do
                local frame = _G["GladiusMidnightArena" .. i]
                if frame then
                    InitializeArenaFrame(frame, i)
                end
            end

            print("|cFF00FF00Gladius Midnight|r loaded. Type /gladius for options.")
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        GladiusMidnight:CheckArenaStatus()

    elseif event == "ARENA_OPPONENT_UPDATE" then
        local unit, updateType = ...
        local frame = GladiusMidnight.frames[unit]
        if frame then
            if updateType == "seen" or updateType == "cleared" then
                GladiusMidnight:UpdateFrame(frame)
            elseif updateType == "destroyed" then
                frame:Hide()
            end
        end

    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        -- Update all frames when spec info becomes available
        for _, unit in ipairs(GladiusMidnight.arenaUnits) do
            local frame = GladiusMidnight.frames[unit]
            if frame then
                GladiusMidnight:UpdateFrame(frame)
            end
        end

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        GladiusMidnight:ProcessCombatLog()

    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_BATTLEGROUND" then
        GladiusMidnight:CheckArenaStatus()
    end
end)

-- Check if we're in an arena and show/hide frames accordingly
function GladiusMidnight:CheckArenaStatus()
    local _, instanceType = IsInInstance()
    local inArena = (instanceType == "arena")

    if inArena and self.db.enabled then
        GladiusMidnightFrame:Show()
        -- Update all arena frames
        for _, unit in ipairs(self.arenaUnits) do
            local frame = self.frames[unit]
            if frame and UnitExists(unit) then
                self:UpdateFrame(frame)
            end
        end
    else
        GladiusMidnightFrame:Hide()
        for _, unit in ipairs(self.arenaUnits) do
            local frame = self.frames[unit]
            if frame then
                frame:Hide()
            end
        end
    end
end

-- Process combat log for trinket/racial usage
function GladiusMidnight:ProcessCombatLog()
    local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()

    if subEvent == "SPELL_CAST_SUCCESS" then
        -- Check if this is from an arena opponent
        for _, unit in ipairs(self.arenaUnits) do
            if UnitGUID(unit) == sourceGUID then
                local frame = self.frames[unit]
                if frame then
                    -- Let modules handle specific abilities
                    if self.Trinkets then
                        self.Trinkets:OnSpellCast(frame, spellID)
                    end
                    if self.Racials then
                        self.Racials:OnSpellCast(frame, spellID)
                    end
                end
                break
            end
        end
    end
end

-- Slash command handler
SLASH_GLADIUSMIDNIGHT1 = "/gladius"
SLASH_GLADIUSMIDNIGHT2 = "/gm"
SlashCmdList["GLADIUSMIDNIGHT"] = function(msg)
    msg = msg:lower():trim()

    if msg == "" or msg == "options" or msg == "config" then
        if GladiusMidnight.OpenConfig then
            GladiusMidnight:OpenConfig()
        else
            print("|cFF00FF00Gladius Midnight|r: Configuration UI not yet loaded.")
        end
    elseif msg == "test" then
        -- Toggle test mode
        GladiusMidnight:ToggleTestMode()
    elseif msg == "lock" then
        GladiusMidnight.db.locked = true
        print("|cFF00FF00Gladius Midnight|r: Frames locked.")
    elseif msg == "unlock" then
        GladiusMidnight.db.locked = false
        print("|cFF00FF00Gladius Midnight|r: Frames unlocked. Drag to reposition.")
    elseif msg == "reset" then
        GladiusMidnightDB = nil
        ReloadUI()
    else
        print("|cFF00FF00Gladius Midnight|r commands:")
        print("  /gladius - Open configuration")
        print("  /gladius test - Toggle test mode")
        print("  /gladius lock - Lock frame positions")
        print("  /gladius unlock - Unlock frame positions")
        print("  /gladius reset - Reset all settings")
    end
end

-- Test mode for development/positioning
function GladiusMidnight:ToggleTestMode()
    self.testMode = not self.testMode

    if self.testMode then
        print("|cFF00FF00Gladius Midnight|r: Test mode enabled.")
        GladiusMidnightFrame:Show()

        -- Show test frames with mock data
        for i, unit in ipairs(self.arenaUnits) do
            local frame = self.frames[unit]
            if frame then
                -- Set mock data
                frame.HealthBar:SetValue(math.random(20, 100))
                frame.ResourceBar:SetValue(math.random(0, 100))

                -- Random class icon
                local classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
                                  "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
                                  "DRUID", "DEMONHUNTER", "EVOKER" }
                local testClass = classes[math.random(1, #classes)]
                local color = self.ClassResources:GetClassColor(testClass)
                frame.HealthBar:SetStatusBarColor(color.r, color.g, color.b)

                local atlasName = self.ClassResources.ClassIcons[testClass]
                if atlasName then
                    frame.ClassIcon:SetAtlas(atlasName)
                end

                frame.HealthBar.Text:SetText(math.random(20, 100) .. "%")
                frame.ResourceBar.Text:SetText(math.random(0, 100) .. "%")

                frame:Show()
            end
        end
    else
        print("|cFF00FF00Gladius Midnight|r: Test mode disabled.")
        self:CheckArenaStatus()
    end
end

-- Export addon table for modules
_G.GladiusMidnight = GladiusMidnight
