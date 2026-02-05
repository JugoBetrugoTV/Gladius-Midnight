-- =============================================================
-- File: modules/GlobalFont.lua
-- ArenaCore Global Font System
-- Applies custom font to entire WoW UI using metatable hooking
-- Based on Fontmancer's approach for maximum compatibility
-- =============================================================

local AC = _G.ArenaCore
if not AC then return end

-- Create module
AC.GlobalFont = AC.GlobalFont or {}
local GlobalFont = AC.GlobalFont

-- Module state
GlobalFont.isEnabled = false
GlobalFont.actionBarOnly = false  -- NEW: Action bar font only mode
GlobalFont.originalFonts = {}
GlobalFont.fontPath = "Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf"
GlobalFont.fontFlags = "OUTLINE"
GlobalFont.useShadow = true
GlobalFont.isHooked = false

-- Fonts to exclude completely (quest text, parchment, etc.)
-- These fonts will NOT get ArenaCore font at all - they keep WoW's default fonts
local EXCLUDED_FONTS = {
    "^MailTextFont",                 -- Mail body text (keep default)
    "^InvoiceFont",                  -- Auction house invoice (keep default)
    -- ^QuestFont moved to NO_OUTLINE_FONTS - needs ArenaCore font WITHOUT outline
    "^GameFontBlack",                -- ADVENTURE GUIDE: Main body text (parchment background)
    "^Number14Font",                 -- PROFESSIONS: Specific number fonts (keep default)
    "^Number12Font",                 -- PROFESSIONS: Rank bar numbers (keep default)
    -- REMOVED ^GameFontNormal - Was blocking character panel, bags, tooltips
    -- REMOVED ^GameFontHighlight - Was blocking character stats, bag items
    -- REMOVED ^NumberFont - Was blocking bag item stack counts
    "NamePlate",                     -- NAMEPLATES: All nameplate fonts (keep default sizing)
    "^SystemFont_NamePlate",         -- NAMEPLATES: System nameplate fonts
    "^Tooltip_Med",                  -- NAMEPLATES: Nameplate tooltip fonts
}

-- Fonts that should ALWAYS get custom font WITHOUT outline
-- These fonts are readable with custom font but ONLY if outline is disabled
local NO_OUTLINE_FONTS = {
    "^ObjectiveTrackerFont",         -- Quest tracker (main quest text in tracker)
    "^QuestFont",                    -- Quest fonts (if not excluded, force no outline)
    "^AchievementFont",              -- Achievement text (all variants)
    "^AchievementCriteriaFont",      -- Achievement criteria
    "^AchievementDateFont",          -- Achievement dates
    "^AchievementPointsFont",        -- Achievement points
    "^GameTooltipHeader",            -- Tooltip headers (can be hard to read)
    "^QuestTitleFont",               -- Quest titles
    "^QuestDescriptionFont",         -- Quest descriptions
    "Description",                   -- Catches achievement description fonts in collapsed view
    "Criteria",                      -- Catches achievement criteria fonts
    "^SystemFont_Large",             -- SPELL BOOK: Spell names (Angelic Feather, Mass Dispel, etc.)
    "^SystemFont_Med1",              -- SPELL BOOK: Spell subtitles (Passive, Rank info)
    "^SystemFont_Med3",              -- SPELL BOOK: UI text
    "^SystemFont_Huge2",             -- SPELL BOOK: Category headers (Primal, etc.)
}

-- Action bar fonts ONLY (for action bar-only mode)
-- These are the ONLY fonts that get custom font when actionBarOnly is enabled
local ACTION_BAR_FONTS = {
    "^NumberFont",                   -- Action bar keybind numbers
    "^GameFontHighlightSmall",       -- Action bar text
    "^GameFontNormalSmall",          -- Action bar cooldown text
    "^GameFontNormal",               -- Action bar macro names
    "ActionBarFont",                 -- Generic action bar font
}

-- Check if a font should be excluded completely
local function IsExcludedFont(fontName)
    if not fontName then return false end
    for _, pattern in ipairs(EXCLUDED_FONTS) do
        if fontName:find(pattern) then
            return true
        end
    end
    return false
end

-- Check if a font should NOT get outline flag
local function ShouldSkipOutline(fontName)
    if not fontName then return false end
    for _, pattern in ipairs(NO_OUTLINE_FONTS) do
        if fontName:find(pattern) then
            return true
        end
    end
    return false
end

-- Check if a font is an action bar font
local function IsActionBarFont(fontName)
    if not fontName then return false end
    for _, pattern in ipairs(ACTION_BAR_FONTS) do
        if fontName:find(pattern) then
            return true
        end
    end
    return false
end

-- Store original font values for potential revert
function GlobalFont:StoreOriginal(fontName, fontObject)
    if not self.originalFonts[fontName] then
        local font, height, flags = fontObject:GetFont()
        self.originalFonts[fontName] = {
            font = font,
            height = height,
            flags = flags or "",
        }
    end
end

-- Apply custom font to a font object
function GlobalFont:ApplyFont(fontName, fontObject, isFontmancerCall)
    if not self.isEnabled then return end
    
    -- CRITICAL: Action bar-only mode filtering
    if self.actionBarOnly then
        -- In action bar-only mode, ONLY apply to action bar fonts
        if not IsActionBarFont(fontName) then
            return  -- Skip non-action bar fonts
        end
    end
    
    -- DEBUG: Check if font is excluded
    if IsExcludedFont(fontName) then
        if AC.BLACKOUT_DEBUG then
            print("|cffFF00FF[GlobalFont]|r EXCLUDED:", fontName)
        end
        return
    end
    
    -- Store original if we haven't already
    self:StoreOriginal(fontName, fontObject)
    
    -- Get original size and flags
    local originalHeight = self.originalFonts[fontName] and self.originalFonts[fontName].height or 12
    local originalFlags = self.originalFonts[fontName] and self.originalFonts[fontName].flags or ""
    
    -- CRITICAL FIX: FORCE empty flags for quest/achievement fonts
    -- Fontmancer pattern: Override flags, don't preserve them
    -- Problem: Quest fonts already have OUTLINE from previous application
    -- Solution: Force "" to remove outline, don't preserve existing flags
    local fontFlags = self.fontFlags
    
    if ShouldSkipOutline(fontName) then
        -- For quest/achievement fonts, FORCE empty flags (no outline)
        -- Don't preserve original flags - they may already have OUTLINE!
        fontFlags = ""
        
        -- DEBUG: Log when we skip outline for a font
        if AC.BLACKOUT_DEBUG then
            print("|cffFFAA00[GlobalFont]|r FORCING no outline for:", fontName, "| Was:", originalFlags or "none", "| Now: (empty)")
        end
    end
    
    -- Apply custom font with original size and appropriate flags
    -- The 5th parameter (true) tells our hook this is an internal call
    pcall(function()
        fontObject:SetFont(self.fontPath, originalHeight, fontFlags, isFontmancerCall)
    end)
end

-- Hook the Font metatable to intercept ALL SetFont calls
function GlobalFont:HookFontMetatable()
    if self.isHooked then return end
    
    -- Create a temporary font to get the metatable
    local tempFont = CreateFont("ArenaCoreFontHookTemp")
    local fontMeta = getmetatable(tempFont).__index
    
    -- Hook SetFont at the metatable level
    hooksecurefunc(fontMeta, "SetFont", function(fontInstance, fontFile, height, flags, isInternalCall)
        -- Skip if this is our own internal call (prevents infinite loop)
        if isInternalCall then return end
        
        local fontName = fontInstance:GetName()
        if not fontName then return end
        
        -- DEBUG: Log SetFont calls for quest fonts
        if AC.BLACKOUT_DEBUG and ShouldSkipOutline(fontName) then
            print("|cffFF00FF[GlobalFont HOOK]|r SetFont called on:", fontName, "| flags:", flags or "none")
        end
        
        -- Store the new original values
        if not GlobalFont.originalFonts[fontName] then
            GlobalFont.originalFonts[fontName] = {}
        end
        GlobalFont.originalFonts[fontName].height = height
        GlobalFont.originalFonts[fontName].flags = flags or ""
        
        -- Apply our custom font
        GlobalFont:ApplyFont(fontName, fontInstance, true)
    end)
    
    self.isHooked = true
    -- Silently installed (no chat spam for users)
end

-- Apply font to all existing fonts using GetFonts() API
function GlobalFont:ApplyToAllFonts()
    if not self.isEnabled then return end
    
    -- GetFonts() returns all Font objects in the game
    local fonts = GetFonts()
    local count = 0
    
    for _, fontName in ipairs(fonts) do
        local fontObject = _G[fontName]
        if fontObject and not IsExcludedFont(fontName) then
            self:ApplyFont(fontName, fontObject, true)
            count = count + 1
        end
    end
    
    -- Silently applied to fonts (no chat spam for users)
end

-- Set global font constants (for fonts created before hooks)
function GlobalFont:SetGlobalConstants()
    STANDARD_TEXT_FONT = self.fontPath
    UNIT_NAME_FONT = self.fontPath
    DAMAGE_TEXT_FONT = self.fontPath
    -- REMOVED: NAMEPLATE_FONT and NAMEPLATE_SPELLCAST_FONT
    -- These must remain as font object names (e.g. "GameFontWhite"), not file paths
    -- Setting them to a file path causes WoW to use incorrect sizing (massive text)
end

-- Enable the global font system
function GlobalFont:Enable(actionBarOnly)
    if self.isEnabled then return end
    
    -- Silently enable (no chat spam for users)
    self.isEnabled = true
    self.actionBarOnly = actionBarOnly or false  -- Set action bar-only mode
    
    -- Set global constants first (only if NOT action bar-only)
    if not self.actionBarOnly then
        self:SetGlobalConstants()
    end
    
    -- Install metatable hooks (catches future font changes)
    self:HookFontMetatable()
    
    -- Apply to all existing fonts IMMEDIATELY (don't wait)
    self:ApplyToAllFonts()
    
    -- CRITICAL: Force re-apply after 1 second to catch fonts that load late
    C_Timer.After(1.0, function()
        self:ApplyToAllFonts()
    end)
    
    -- CRITICAL: Force re-apply after 3 seconds for quest/UI fonts
    C_Timer.After(3.0, function()
        self:ApplyToAllFonts()
    end)
    
    -- Silently enabled (no chat spam for users)
end

-- Revert all fonts to their original values
function GlobalFont:RevertAllFonts()
    local fonts = GetFonts()
    local count = 0
    
    for _, fontName in ipairs(fonts) do
        local fontObject = _G[fontName]
        if fontObject and self.originalFonts[fontName] then
            local original = self.originalFonts[fontName]
            -- Restore original font
            pcall(function()
                fontObject:SetFont(original.font, original.height, original.flags)
            end)
            count = count + 1
        end
    end
    
    -- Clear the cache
    self.originalFonts = {}
    
    return count
end

-- Disable the global font system and revert fonts
function GlobalFont:Disable()
    self.isEnabled = false
    self.actionBarOnly = false  -- Reset action bar-only mode
    -- Revert all fonts to original
    self:RevertAllFonts()
    -- Silently disabled (no chat spam for users)
end

-- Update settings
function GlobalFont:UpdateSettings(fontPath, fontFlags, useShadow)
    self.fontPath = fontPath or self.fontPath
    self.fontFlags = fontFlags or self.fontFlags
    self.useShadow = useShadow ~= nil and useShadow or self.useShadow
    
    if self.isEnabled then
        -- Reapply to all fonts with new settings
        self:ApplyToAllFonts()
    end
end

-- Debug: Print all hooked fonts
function GlobalFont:PrintHookedFonts()
    print("|cff00FFFF[ArenaCore GlobalFont]|r Hooked fonts:")
    local count = 0
    local questCount = 0
    for fontName, data in pairs(self.originalFonts) do
        local isQuest = ShouldSkipOutline(fontName)
        if isQuest then questCount = questCount + 1 end
        print("  " .. fontName .. " (size: " .. tostring(data.height) .. ", flags: " .. tostring(data.flags) .. ")" .. (isQuest and " [QUEST/ACHIEVEMENT]" or ""))
        count = count + 1
    end
    print("|cff00FFFF[ArenaCore GlobalFont]|r Total: " .. count .. " fonts (" .. questCount .. " quest/achievement fonts)")
end

-- Slash command to debug fonts
SLASH_ACFONTDEBUG1 = "/acfontdebug"
SlashCmdList["ACFONTDEBUG"] = function()
    if _G.ArenaCore and _G.ArenaCore.GlobalFont then
        _G.ArenaCore.GlobalFont:PrintHookedFonts()
    end
end

-- Slash command to force refresh fonts (for quest text issues)
SLASH_ACFONTFIX1 = "/acfontfix"
SlashCmdList["ACFONTFIX"] = function()
    if _G.ArenaCore and _G.ArenaCore.GlobalFont then
        print("|cff00FFFF[ArenaCore GlobalFont]|r Force-refreshing all fonts...")
        _G.ArenaCore.GlobalFont:ApplyToAllFonts()
        print("|cff00FFFF[ArenaCore GlobalFont]|r Done! Quest text should now be readable.")
    end
end

-- Slash command to reset fonts (revert to original and re-apply with new exclusions)
SLASH_ACFONTRESET1 = "/acfontreset"
SlashCmdList["ACFONTRESET"] = function()
    if _G.ArenaCore and _G.ArenaCore.GlobalFont then
        print("|cff00FFFF[ArenaCore GlobalFont]|r Resetting all fonts...")
        local count = _G.ArenaCore.GlobalFont:RevertAllFonts()
        print("|cff00FFFF[ArenaCore GlobalFont]|r Reverted " .. count .. " fonts to original.")
        
        if _G.ArenaCore.GlobalFont.isEnabled then
            C_Timer.After(0.5, function()
                print("|cff00FFFF[ArenaCore GlobalFont]|r Re-applying fonts with new exclusions...")
                _G.ArenaCore.GlobalFont:ApplyToAllFonts()
                print("|cff00FFFF[ArenaCore GlobalFont]|r Done! Fonts reset successfully.")
            end)
        else
            print("|cff00FFFF[ArenaCore GlobalFont]|r Global font is disabled. Enable it to apply fonts.")
        end
    end
end

-- Slash command to list all fonts with Quest/Game in the name
SLASH_ACFONTLIST1 = "/acfontlist"
SlashCmdList["ACFONTLIST"] = function(msg)
    if _G.ArenaCore and _G.ArenaCore.GlobalFont then
        local fonts = GetFonts()
        local filter = msg and msg:lower() or ""
        local count = 0
        
        print("|cff00FFFF[ArenaCore GlobalFont]|r Listing fonts" .. (filter ~= "" and " matching '" .. filter .. "'" or "") .. ":")
        
        for _, fontName in ipairs(fonts) do
            if filter == "" or fontName:lower():find(filter) then
                local fontObject = _G[fontName]
                if fontObject then
                    local font, height, flags = fontObject:GetFont()
                    local isExcluded = IsExcludedFont(fontName)
                    local skipOutline = ShouldSkipOutline(fontName)
                    local status = isExcluded and "|cffFF0000[EXCLUDED]|r" or (skipOutline and "|cffFFAA00[NO OUTLINE]|r" or "|cff00FF00[APPLIED]|r")
                    print("  " .. status .. " " .. fontName .. " (size: " .. tostring(height) .. ", flags: " .. tostring(flags or "none") .. ")")
                    count = count + 1
                end
            end
        end
        
        print("|cff00FFFF[ArenaCore GlobalFont]|r Found " .. count .. " fonts.")
    end
end

-- Initialize on addon load (silently)
