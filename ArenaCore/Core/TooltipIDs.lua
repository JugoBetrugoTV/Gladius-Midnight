-- Core/TooltipIDs.lua
-- Global Tooltip ID system for ArenaCore (SAFE VERSION)
-- COMPLETELY DISABLED IN MIDNIGHT due to secret value restrictions
local AC = _G.ArenaCore
if not AC then return end

-- Create stub module that does nothing
AC.TooltipIDs = { Initialize = function() end }

-- CRITICAL: Disable entirely in Midnight due to secret value restrictions
-- Check is done via C_AddOns since AC.Midnight may not be loaded yet
local isMidnight = (select(4, GetBuildInfo()) or 0) >= 110100
if isMidnight then
    return -- Exit early - do not hook any tooltip functions
end

local TooltipIDs = {}
AC.TooltipIDs = TooltipIDs

-- Check if tooltip IDs should be shown
local function ShouldShowTooltipIDs()
    -- CRITICAL: Double-check Midnight at runtime
    if AC.Midnight and AC.Midnight.isMidnight then return false end
    
    -- Always show in Blackout Editor
    if AC.BlackoutEditor and AC.BlackoutEditor.Frame and AC.BlackoutEditor.Frame:IsShown() then
        return true
    end
    
    -- Check global setting
    local db = (AC.DB and AC.DB.profile and AC.DB.profile.tooltipIDs) or {}
    return db.enabled ~= false -- Default to enabled
end

-- Add ID line to tooltip
local function AddIDLine(tooltip, id, idType)
    -- CRITICAL: Disable in Midnight - secret values cause errors
    if AC.Midnight and AC.Midnight.isMidnight then return end
    
    if not id or id == "" or not tooltip or not ShouldShowTooltipIDs() then return end
    
    -- Safe tooltip name check
    local ok, tooltipName = pcall(function() return tooltip:GetName() end)
    if not ok or not tooltipName then return end
    
    -- Check if we already added an ID to this tooltip
    local frame, text
    for i = tooltip:NumLines(), 1, -1 do
        frame = _G[tooltipName .. "TextLeft" .. i]
        if frame then 
            local success, frameText = pcall(function() return frame:GetText() end)
            if success and frameText and type(frameText) == "string" then 
                text = frameText
            end
        end
        if text and (string.find(text, "ID:") or string.find(text, "SpellID") or string.find(text, "ItemID")) then 
            return -- Already has an ID line
        end
    end
    
    -- Safely add the line
    local success = pcall(function()
        tooltip:AddDoubleLine(idType .. ":", id, nil, nil, nil, 1, 1, 1)
        tooltip:Show()
    end)
    
    if not success then return end -- Silently fail if tooltip is protected
end

-- Try modern TooltipDataProcessor API if present
local function HookTooltipDataProcessor()
    if not TooltipDataProcessor or not Enum or not Enum.TooltipDataType then return end

    local function addLineFromData(tooltip, data)
        if not tooltip or not data then return end
        -- Items
        if data.type == Enum.TooltipDataType.Item and data.id then
            AddIDLine(tooltip, data.id, "Item ID")
            return
        end
        -- Spells
        if data.type == Enum.TooltipDataType.Spell and data.id then
            AddIDLine(tooltip, data.id, "Spell ID")
            return
        end
        -- Auras
        if data.type == Enum.TooltipDataType.UnitAura and data.id then
            AddIDLine(tooltip, data.id, "Spell ID")
            return
        end
    end

    local ok = pcall(function()
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, addLineFromData)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, addLineFromData)
        if Enum.TooltipDataType.UnitAura then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, addLineFromData)
        end
    end)
    return ok
end

-- Safe hook function
local function SafeHook(object, method, callback)
    if not object or not object[method] then return false end
    local success = pcall(function()
        hooksecurefunc(object, method, callback)
    end)
    return success
end

-- Safe script hook function
local function SafeHookScript(object, script, callback)
    if not object or not object.HookScript or not object:HasScript(script) then return false end
    local success = pcall(function()
        object:HookScript(script, callback)
    end)
    return success
end

-- Hook spell tooltips
local function HookSpellTooltips()
    -- Method 1: SetSpellByID
    SafeHook(GameTooltip, "SetSpellByID", function(tooltip, spellID)
        AddIDLine(tooltip, spellID, "Spell ID")
    end)
    
    -- Method 2: OnTooltipSetSpell (only if it exists)
    SafeHookScript(GameTooltip, "OnTooltipSetSpell", function(tooltip)
        local spellID = select(2, tooltip:GetSpell())
        if spellID then
            AddIDLine(tooltip, spellID, "Spell ID")
        end
    end)
    
    -- Method 3: Unit auras (buffs/debuffs)
    if UnitBuff then
        SafeHook(GameTooltip, "SetUnitBuff", function(tooltip, ...)
            local spellID = select(10, UnitBuff(...))
            if spellID then
                AddIDLine(tooltip, spellID, "Spell ID")
            end
        end)
    end
    
    if UnitDebuff then
        SafeHook(GameTooltip, "SetUnitDebuff", function(tooltip, ...)
            local spellID = select(10, UnitDebuff(...))
            if spellID then
                AddIDLine(tooltip, spellID, "Spell ID")
            end
        end)
    end
    
    if UnitAura then
        SafeHook(GameTooltip, "SetUnitAura", function(tooltip, ...)
            local spellID = select(10, UnitAura(...))
            if spellID then
                AddIDLine(tooltip, spellID, "Spell ID")
            end
        end)
    end
end

-- Hook item tooltips
local function HookItemTooltips()
    -- Method 1: OnTooltipSetItem script hook
    SafeHookScript(GameTooltip, "OnTooltipSetItem", function(tooltip)
        local itemLink = select(2, tooltip:GetItem())
        if itemLink then
            local itemID = tonumber(itemLink:match("item:(%d+)"))
            if itemID then
                AddIDLine(tooltip, itemID, "Item ID")
            end
        end
    end)
    
    -- Method 2: ItemRefTooltip for shift-clicking
    if ItemRefTooltip then
        SafeHookScript(ItemRefTooltip, "OnTooltipSetItem", function(tooltip)
            local itemLink = select(2, tooltip:GetItem())
            if itemLink then
                local itemID = tonumber(itemLink:match("item:(%d+)"))
                if itemID then
                    AddIDLine(tooltip, itemID, "Item ID")
                end
            end
        end)
    end
end

-- Initialize the tooltip hook system
function TooltipIDs:Initialize()
    if AC.Midnight and AC.Midnight.isMidnight then
        return
    end
    -- Delay initialization to avoid conflicts with other addons
    C_Timer.After(1.5, function()
        if AC.Midnight and AC.Midnight.isMidnight then
            return
        end
        -- Use modern processor when available (Retail)
        HookTooltipDataProcessor()
        -- Also keep legacy hooks for compatibility
        HookSpellTooltips()
        HookItemTooltips()
    end)
end

-- Initialize when the addon loads
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "ArenaCore" then
        TooltipIDs:Initialize()
        frame:UnregisterEvent("ADDON_LOADED")
    end
end)