-- ============================================================================
-- ARENA NAMEPLATES - Name Customization System
-- ============================================================================
-- Allows users to replace enemy nameplate names in arena with:
-- - Arena numbers (1/2/3)
-- - Spec names (Affliction, Retribution, etc.)
-- - Both (Affliction 1, Retribution 2, etc.)
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

-- ============================================================================
-- PLATYNATOR API INTEGRATION
-- ============================================================================
-- When Platynator nameplate addon is enabled, use their API to set name overrides
-- This allows both addons to work together seamlessly

local function IsPlatynatorAPIAvailable()
    return Platynator and Platynator.API and Platynator.API.SetUnitTextOverride
end

-- ============================================================================
-- SPEC ID TO NAME MAPPINGS
-- ============================================================================

local SPEC_NAMES_FULL = {
    -- Death Knight
    [250] = "Blood", [251] = "Frost", [252] = "Unholy",
    -- Demon Hunter
    [577] = "Havoc", [581] = "Vengeance",
    -- Druid
    [102] = "Balance", [103] = "Feral", [104] = "Guardian", [105] = "Restoration",
    -- Evoker
    [1467] = "Devastation", [1468] = "Preservation", [1473] = "Augmentation",
    -- Hunter
    [253] = "Beast Mastery", [254] = "Marksmanship", [255] = "Survival",
    -- Mage
    [62] = "Arcane", [63] = "Fire", [64] = "Frost",
    -- Monk
    [268] = "Brewmaster", [270] = "Mistweaver", [269] = "Windwalker",
    -- Paladin
    [65] = "Holy", [66] = "Protection", [70] = "Retribution",
    -- Priest
    [256] = "Discipline", [257] = "Holy", [258] = "Shadow",
    -- Rogue
    [259] = "Assassination", [260] = "Outlaw", [261] = "Subtlety",
    -- Shaman
    [262] = "Elemental", [263] = "Enhancement", [264] = "Restoration",
    -- Warlock
    [265] = "Affliction", [266] = "Demonology", [267] = "Destruction",
    -- Warrior
    [71] = "Arms", [72] = "Fury", [73] = "Protection",
}

local SPEC_NAMES_SHORT = {
    -- Death Knight
    [250] = "Blood", [251] = "Frost", [252] = "Unholy",
    -- Demon Hunter
    [577] = "Havoc", [581] = "Veng",
    -- Druid
    [102] = "Balance", [103] = "Feral", [104] = "Guardian", [105] = "Resto",
    -- Evoker
    [1467] = "Dev", [1468] = "Pres", [1473] = "Aug",
    -- Hunter
    [253] = "BM", [254] = "MM", [255] = "Survival",
    -- Mage
    [62] = "Arcane", [63] = "Fire", [64] = "Frost",
    -- Monk
    [268] = "Brew", [270] = "MW", [269] = "WW",
    -- Paladin
    [65] = "Holy", [66] = "Prot", [70] = "Ret",
    -- Priest
    [256] = "Disc", [257] = "Holy", [258] = "Shadow",
    -- Rogue
    [259] = "Assa", [260] = "Outlaw", [261] = "Sub",
    -- Shaman
    [262] = "Ele", [263] = "Enh", [264] = "Resto",
    -- Warlock
    [265] = "Aff", [266] = "Demo", [267] = "Destro",
    -- Warrior
    [71] = "Arms", [72] = "Fury", [73] = "Prot",
}

-- ============================================================================
-- ARENA NAMEPLATE TRACKING (BetterBlizzPlates approach)
-- ============================================================================

-- Cache arena nameplates by index
local arenaPlates = {} -- [1..3] = nameplate frame or nil

local function RefreshArenaPlates()
    wipe(arenaPlates)
    for i = 1, 3 do
        arenaPlates[i] = C_NamePlate.GetNamePlateForUnit("arena" .. i)
    end
end

-- Get arena index by comparing nameplate objects (avoids secret value issue)
local function GetArenaIndexByNameplate(nameplate)
    if not nameplate then return nil end
    for i = 1, 3 do
        if arenaPlates[i] and arenaPlates[i] == nameplate then
            return i
        end
    end
    return nil
end

-- ============================================================================
-- NAME TRANSFORMATION LOGIC
-- ============================================================================

local function GetSpecName(arenaIndex, useShortNames)
    local specID = GetArenaOpponentSpec(arenaIndex)
    local specTable = useShortNames and SPEC_NAMES_SHORT or SPEC_NAMES_FULL
    
    -- Try to get spec name from specID (BBP pattern: check both specID exists AND is in table)
    local specName = specID and specTable[specID]
    
    -- Fallback to class name if spec not available or not found in table
    if not specName then
        local className = UnitClass("arena" .. arenaIndex)
        return className or "Unknown"
    end
    
    return specName
end

-- ============================================================================
-- GET TRANSFORMED NAME TEXT (for Platynator integration)
-- ============================================================================
-- Returns the text ArenaCore would display based on current settings
-- Used by both native UI and Platynator API

local function GetTransformedNameText(arenaIndex, mode, useShortNames)
    if not arenaIndex or arenaIndex < 1 or arenaIndex > 3 then return nil end
    
    if mode == "arena" then
        return tostring(arenaIndex)
    elseif mode == "spec" then
        return GetSpecName(arenaIndex, useShortNames)
    elseif mode == "both" then
        local specName = GetSpecName(arenaIndex, useShortNames)
        return specName .. " " .. arenaIndex
    end
    
    return nil -- "default" mode returns nil (use original name)
end

-- ============================================================================
-- PLATYNATOR OVERRIDE HELPERS
-- ============================================================================
-- Update Platynator text overrides for all active arena nameplates

local function UpdatePlatynatorOverrides()
    if not IsPlatynatorAPIAvailable() then return end
    
    local db = AC.DB and AC.DB.profile and AC.DB.profile.arenaNameplates
    if not db or not db.enabled then return end
    
    RefreshArenaPlates()
    
    for i = 1, 3 do
        local nameplate = arenaPlates[i]
        if nameplate then
            -- Get the nameplate unit token (nameplate1, nameplate2, etc.)
            local unit = nameplate.namePlateUnitToken
            if unit and UnitIsPlayer(unit) and not UnitIsFriend("player", unit) then
                local transformedName = GetTransformedNameText(i, db.mode, db.useShortNames)
                if transformedName then
                    Platynator.API.SetUnitTextOverride(unit, transformedName, nil)
                end
            end
        end
    end
end

local function CreateCustomTextElements(unitFrame)
    -- Create custom text elements if they don't exist
    if not unitFrame.arenaNameText then
        unitFrame.arenaNameText = unitFrame:CreateFontString(nil, "OVERLAY")
        unitFrame.arenaNameText:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 12, "OUTLINE")
        unitFrame.arenaNameText:SetIgnoreParentScale(true)
    end
end

local function TransformNameplateText(nameplate, unitFrame, arenaIndex, mode, useShortNames, useClassColors)
    if not unitFrame or not arenaIndex then return end
    
    -- Get the name text element for class color
    local nameText = unitFrame.name
    if not nameText then return end
    
    -- Get health bar for positioning
    local healthBar = unitFrame.healthBar
    if not healthBar then return end
    
    -- Create custom text elements
    CreateCustomTextElements(unitFrame)
    
    -- Determine new text based on mode
    local newText
    if mode == "arena" then
        -- Arena number only
        newText = tostring(arenaIndex)
    elseif mode == "spec" then
        -- Spec name only
        newText = GetSpecName(arenaIndex, useShortNames)
    elseif mode == "both" then
        -- Spec name + arena number (format: "Affliction 1")
        local specName = GetSpecName(arenaIndex, useShortNames)
        newText = specName .. " " .. arenaIndex
    else
        -- Default mode - restore original name and hide custom text
        unitFrame.arenaNameText:Hide()
        nameText:Show()
        return
    end
    
    -- Determine text color: class color if enabled, white if disabled
    local r, g, b
    if useClassColors then
        -- Get actual class color from WoW's class color table
        local _, class = UnitClass("arena" .. arenaIndex)
        if class and RAID_CLASS_COLORS[class] then
            local classColor = RAID_CLASS_COLORS[class]
            r, g, b = classColor.r, classColor.g, classColor.b
        else
            r, g, b = 1, 1, 1  -- Fallback to white if class not found
        end
    else
        r, g, b = 1, 1, 1  -- White
    end
    
    -- Hide original name and show custom text
    nameText:SetText("")  -- Hide original name
    unitFrame.arenaNameText:SetText(newText)
    unitFrame.arenaNameText:SetTextColor(r, g, b, 1)
    
    -- Position custom text where the original name was (centered above health bar)
    unitFrame.arenaNameText:SetPoint("CENTER", healthBar, "TOP", 0, 8)
    unitFrame.arenaNameText:Show()
end

-- ============================================================================
-- UNIT VALIDATION (BBP Pattern)
-- ============================================================================

-- Check if unit is a player (not pet/NPC) - BBP uses UnitIsPlayer
local function IsValidArenaPlayer(unit)
    if not unit then return false end
    
    -- Must be a player (filters out pets, NPCs, totems, etc.)
    if not UnitIsPlayer(unit) then return false end
    
    -- Must be an enemy (filters out friendly players/party members)
    if UnitIsFriend("player", unit) then return false end
    
    -- Additional safety: Check reaction (BBP pattern)
    local reaction = UnitReaction(unit, "player")
    if reaction and reaction >= 5 then return false end -- Friendly reaction
    
    return true
end

-- ============================================================================
-- NAMEPLATE UPDATE HANDLER
-- ============================================================================

local function UpdateArenaNameplate(nameplate, unitFrame, arenaIndex)
    if not unitFrame or not arenaIndex then return end
    
    -- Get the nameplate's ACTUAL unit (not just the arena token)
    local nameplateUnit = unitFrame.unit
    if not nameplateUnit then return end
    
    -- CRITICAL: Validate the nameplate's actual unit is a player (filters pets)
    if not UnitIsPlayer(nameplateUnit) then return end
    
    -- Also validate the arena token itself
    local arenaUnit = "arena" .. arenaIndex
    if not IsValidArenaPlayer(arenaUnit) then return end
    
    -- Get settings
    local db = AC.DB and AC.DB.profile and AC.DB.profile.arenaNameplates
    if not db or not db.enabled then return end
    
    -- Transform the nameplate text
    TransformNameplateText(nameplate, unitFrame, arenaIndex, db.mode, db.useShortNames, db.useClassColors)
end

local function RestoreOriginalName(unitFrame)
    if not unitFrame then return end
    
    local nameText = unitFrame.name
    if not nameText then return end
    
    -- Restore original name
    nameText:SetText("")  -- Clear any custom text
    nameText:Show()
    
    -- Hide custom text
    if unitFrame.arenaNameText then
        unitFrame.arenaNameText:Hide()
    end
end

local function RestoreAllOriginalNames()
    -- Only restore nameplates that have our custom text element
    -- This prevents touching nameplates we never modified
    for _, namePlate in pairs(C_NamePlate.GetNamePlates()) do
        local unitFrame = namePlate.UnitFrame
        if unitFrame and unitFrame.arenaNameText then
            RestoreOriginalName(unitFrame)
        end
    end
end

local function UpdateAllArenaNameplates()
    -- Refresh the arena plates cache first
    RefreshArenaPlates()
    
    -- Iterate through cached arena nameplates (like BetterBlizzPlates)
    for i = 1, 3 do
        local nameplate = arenaPlates[i]
        if nameplate then
            local unitFrame = nameplate.UnitFrame
            if unitFrame then
                UpdateArenaNameplate(nameplate, unitFrame, i)
            end
        end
    end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS") -- CRITICAL: When spec data becomes available
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local db = AC.DB and AC.DB.profile and AC.DB.profile.arenaNameplates
    
    -- Handle leaving arena or feature disabled
    if not IsActiveBattlefieldArena() or not db or not db.enabled then
        -- CRITICAL: Always restore nameplates when leaving arena or on world enter
        RestoreAllOriginalNames()
        
        -- Clear the arena plates cache to prevent stale data
        wipe(arenaPlates)
        return
    end
    
    if event == "PLAYER_ENTERING_WORLD" or event == "ARENA_OPPONENT_UPDATE" or event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        RefreshArenaPlates()
        C_Timer.After(0.1, UpdateAllArenaNameplates)
        -- Update Platynator overrides when spec info becomes available
        C_Timer.After(0.15, UpdatePlatynatorOverrides)
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...
        
        -- ================================================================
        -- PLATYNATOR INTEGRATION: Set text override via their API
        -- ================================================================
        if IsPlatynatorAPIAvailable() and unit:match("^nameplate") then
            -- Check if this nameplate belongs to an arena enemy
            RefreshArenaPlates()
            local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
            
            for i = 1, 3 do
                if arenaPlates[i] == nameplate then
                    -- Verify it's actually a player and enemy
                    if UnitIsPlayer(unit) and not UnitIsFriend("player", unit) then
                        local transformedName = GetTransformedNameText(i, db.mode, db.useShortNames)
                        if transformedName then
                            -- Call Platynator API to override the name text
                            Platynator.API.SetUnitTextOverride(unit, transformedName, nil)
                        end
                    end
                    break
                end
            end
        end
        
        -- CRITICAL FIX: Nameplates are RECYCLED by WoW. When a nameplate appears,
        -- it might have our custom text from when it was an arena plate.
        -- We must clean it up if this unit is NOT a valid arena enemy player.
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        if nameplate and nameplate.UnitFrame then
            local unitFrame = nameplate.UnitFrame
            
            -- Check if this nameplate has our custom text element
            if unitFrame.arenaNameText then
                -- Determine if this is a valid arena enemy player
                local isValidArena = false
                
                -- Check if it's one of the arena enemy plates
                RefreshArenaPlates()
                for i = 1, 3 do
                    if arenaPlates[i] == nameplate then
                        -- Verify it's actually a player and enemy
                        if UnitIsPlayer(unit) and not UnitIsFriend("player", unit) then
                            isValidArena = true
                        end
                        break
                    end
                end
                
                -- If NOT a valid arena enemy, hide our custom text
                if not isValidArena then
                    unitFrame.arenaNameText:Hide()
                    unitFrame.arenaNameText:SetText("")
                    if unitFrame.name then
                        unitFrame.name:SetAlpha(1)
                        unitFrame.name:Show()
                    end
                end
            end
        end
        
        RefreshArenaPlates()
        C_Timer.After(0.05, UpdateAllArenaNameplates)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        RefreshArenaPlates()
    end
end)

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function AC:RefreshArenaNameplates()
    UpdateAllArenaNameplates()
end

-- Initialize on load
C_Timer.After(1, function()
    if IsActiveBattlefieldArena() then
        UpdateAllArenaNameplates()
    end
end)
