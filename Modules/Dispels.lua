--[[
    Gladius Midnight - Dispels Module
    Tracks enemy dispel ability usage and cooldowns.
    Supports multi-charge detection for Purify (527).
    Complete dispel spell database with spec-to-dispel mapping.
]]

local GetTime = GetTime
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local L = GladiusMixin.L

-----------------------------------------------------------------------
-- Helper: get localized spell name with fallbacks
-----------------------------------------------------------------------
local function SafeGetSpellName(spellID, fallback)
    if C_Spell and C_Spell.GetSpellName then
        local name = C_Spell.GetSpellName(spellID)
        if name then return name end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then return info.name end
    end
    if GetSpellInfo then
        local name = GetSpellInfo(spellID)
        if name then return name end
    end
    return fallback or "Unknown"
end

-----------------------------------------------------------------------
-- Dispel spell database: spellID -> info table
-----------------------------------------------------------------------
GladiusMixin.dispelData = {
    [527]    = { texture = GetSpellTexture(527),    name = "Purify",            classes = L["DispelClass_DiscHolyPriest"],      cooldown = 8, healer = true },
    [213634] = { texture = GetSpellTexture(213634), name = "Purify Disease",    classes = L["DispelClass_ShadowPriest"],        cooldown = 8, showAfterUse = true },
    [4987]   = { texture = GetSpellTexture(4987),   name = "Cleanse",           classes = L["DispelClass_HolyPaladin"],         cooldown = 8, healer = true },
    [213644] = { texture = GetSpellTexture(213644), name = "Cleanse Toxins",    classes = L["DispelClass_ProtRetPaladin"],      cooldown = 8, showAfterUse = true },
    [77130]  = { texture = GetSpellTexture(77130),  name = "Purify Spirit",     classes = L["DispelClass_RestoShaman"],         cooldown = 8, healer = true },
    [51886]  = { texture = GetSpellTexture(51886),  name = "Cleanse Spirit",    classes = L["DispelClass_EnhEleShaman"],        cooldown = 8, showAfterUse = true },
    [88423]  = { texture = GetSpellTexture(88423),  name = "Nature's Cure",     classes = L["DispelClass_RestoDruid"],          cooldown = 8, healer = true },
    [2782]   = { texture = GetSpellTexture(2782),   name = "Remove Corruption", classes = L["DispelClass_BalFeralGuardianDruid"], cooldown = 8, showAfterUse = true },
    [475]    = { texture = GetSpellTexture(475),    name = "Remove Curse",      classes = L["DispelClass_Mage"],                cooldown = 8, showAfterUse = true },
    [218164] = { texture = GetSpellTexture(218164), name = "Detox",             classes = L["DispelClass_Monk"],                cooldown = 8, showAfterUse = true },
    [115450] = { texture = GetSpellTexture(115450), name = "Detox",             classes = L["DispelClass_MistweaverMonk"],      cooldown = 8, healer = true },
    [360823] = { texture = GetSpellTexture(360823), name = "Naturalize",        classes = L["DispelClass_Evoker"],              cooldown = 8, healer = true },
    [374251] = { texture = GetSpellTexture(374251), name = "Cauterizing Flame", classes = L["DispelClass_DevEvoker"],           cooldown = 60, showAfterUse = true },
    [119905] = { texture = GetSpellTexture(119905), name = "Singe Magic",       classes = L["DispelClass_WarlockPet"],          cooldown = 15, showAfterUse = true },
    [132411] = { texture = GetSpellTexture(132411), name = "Singe Magic",       classes = L["DispelClass_WarlockGrimoire"],     cooldown = 15, showAfterUse = true },
    [212640] = { texture = GetSpellTexture(212640), name = "Mending Bandage",   classes = L["DispelClass_SurvivalHunter"],      cooldown = 25, showAfterUse = true },
}

-----------------------------------------------------------------------
-- Spec ID -> Dispel spell ID mapping
-----------------------------------------------------------------------
GladiusMixin.specToDispel = {
    -- Druid
    [102] = 2782,    -- Balance -> Remove Corruption
    [103] = 2782,    -- Feral -> Remove Corruption
    [104] = 2782,    -- Guardian -> Remove Corruption
    [105] = 88423,   -- Restoration -> Nature's Cure

    -- Evoker
    [1467] = 374251, -- Devastation -> Cauterizing Flame
    [1468] = 360823, -- Preservation -> Naturalize

    -- Hunter
    [255] = 212640,  -- Survival -> Mending Bandage

    -- Mage
    [62] = 475,      -- Arcane -> Remove Curse
    [63] = 475,      -- Fire -> Remove Curse
    [64] = 475,      -- Frost -> Remove Curse

    -- Monk
    [268] = 218164,  -- Brewmaster -> Detox
    [269] = 218164,  -- Windwalker -> Detox
    [270] = 115450,  -- Mistweaver -> Detox (magic dispel)

    -- Paladin
    [65] = 4987,     -- Holy -> Cleanse
    [66] = 213644,   -- Protection -> Cleanse Toxins
    [70] = 213644,   -- Retribution -> Cleanse Toxins

    -- Priest
    [256] = 527,     -- Discipline -> Purify
    [257] = 527,     -- Holy -> Purify
    [258] = 213634,  -- Shadow -> Purify Disease

    -- Shaman
    [262] = 51886,   -- Elemental -> Cleanse Spirit
    [263] = 51886,   -- Enhancement -> Cleanse Spirit
    [264] = 77130,   -- Restoration -> Purify Spirit

    -- Warlock (pet and grimoire variants)
    [265] = { 119905, 132411 }, -- Affliction
    [266] = { 119905, 132411 }, -- Demonology
    [267] = { 119905, 132411 }, -- Destruction
}

-----------------------------------------------------------------------
-- Default dispel categories (healer dispels enabled by default)
-----------------------------------------------------------------------
GladiusMixin.defaultSettings.profile.dispelCategories = {
    [527]    = true,  -- Purify (Disc/Holy Priest)
    [4987]   = true,  -- Cleanse (Holy Paladin)
    [77130]  = true,  -- Purify Spirit (Resto Shaman)
    [88423]  = true,  -- Nature's Cure (Resto Druid)
    [115450] = true,  -- Detox (Mistweaver Monk)
    [360823] = true,  -- Naturalize (Preservation Evoker)
}

-----------------------------------------------------------------------
-- Module-local tracking state
-----------------------------------------------------------------------
local detectedDispels = {}   -- [unit][spellID] = true when seen in combat log
local dispelCharges = {}     -- [unit] = charge tracking table (for Purify 527)
local lastDispelCast = {}    -- [unit_spellID] = timestamp of last cast

local RECHARGE_DURATION = 8
local THROTTLE_WINDOW = 0.2

-----------------------------------------------------------------------
-- Internal: Refresh charge display and cooldown for a single frame
-----------------------------------------------------------------------
local function RefreshChargeDisplay(frame)
    local unit = frame.unit
    local chargeData = dispelCharges[unit]

    if not chargeData then
        if frame.DispelStacks then
            frame.DispelStacks:SetText("")
        end
        return
    end

    local now = GetTime()

    -- Process completed recharges
    if #chargeData.rechargeTimes > 0 then
        local pending = {}
        for _, rechargeAt in ipairs(chargeData.rechargeTimes) do
            if rechargeAt > now then
                pending[#pending + 1] = rechargeAt
            else
                chargeData.charges = math.min(chargeData.maxCharges, chargeData.charges + 1)
            end
        end
        chargeData.rechargeTimes = pending
    end

    -- Update stack count text
    if frame.DispelStacks then
        if chargeData.isMultiCharge then
            frame.DispelStacks:SetText(tostring(chargeData.charges))
        else
            frame.DispelStacks:SetText("")
        end
    end

    -- Desaturation when out of charges
    local db = frame.parent and frame.parent.db
    local shouldDesaturate = db and db.profile and db.profile.desaturateDispelCD
    frame.Dispel.Texture:SetDesaturated(shouldDesaturate and chargeData.charges == 0)

    -- Show cooldown for the soonest recharging charge
    if #chargeData.rechargeTimes > 0 then
        local soonest = math.huge
        for _, rechargeAt in ipairs(chargeData.rechargeTimes) do
            if rechargeAt < soonest then
                soonest = rechargeAt
            end
        end

        local timeLeft = soonest - now
        if timeLeft > 0 then
            frame.Dispel.Cooldown:SetCooldown(soonest - RECHARGE_DURATION, RECHARGE_DURATION)
            C_Timer.After(timeLeft + 0.01, function()
                RefreshChargeDisplay(frame)
            end)
        else
            frame.Dispel.Cooldown:Clear()
        end
    else
        frame.Dispel.Cooldown:Clear()
    end
end

-----------------------------------------------------------------------
-- FindDispel: Called from combat log when an enemy casts a dispel
-----------------------------------------------------------------------
function GladiusFrameMixin:FindDispel(spellID)
    local dispelInfo = GladiusMixin.dispelData[spellID]
    if not dispelInfo then return end

    -- Mark this dispel as detected for this unit
    if not detectedDispels[self.unit] then
        detectedDispels[self.unit] = {}
    end
    detectedDispels[self.unit][spellID] = true

    local cooldown = dispelInfo.cooldown or 8
    local now = GetTime()

    -- Throttle rapid duplicate events
    local throttleKey = self.unit .. "_" .. spellID
    if lastDispelCast[throttleKey] and (now - lastDispelCast[throttleKey]) < THROTTLE_WINDOW then
        return
    end

    -- Multi-charge tracking only for Purify (527)
    if spellID == 527 then
        if not dispelCharges[self.unit] then
            dispelCharges[self.unit] = {
                charges = 1,
                maxCharges = 1,
                isMultiCharge = false,
                rechargeTimes = {},
            }
        end

        local data = dispelCharges[self.unit]

        -- Detect 2-charge talent: if used again within the CD window, must have talent
        local sinceLastCast = lastDispelCast[throttleKey] and (now - lastDispelCast[throttleKey]) or math.huge
        if sinceLastCast < (RECHARGE_DURATION - 0.5) and not data.isMultiCharge then
            data.isMultiCharge = true
            data.maxCharges = 2
        end
    end

    lastDispelCast[throttleKey] = now

    -- Purify charge consumption
    if spellID == 527 then
        local data = dispelCharges[self.unit]

        if data.charges > 0 then
            data.charges = data.charges - 1
        end

        -- Calculate recharge end time (queue after any pending recharges)
        local rechargeEnd
        if #data.rechargeTimes > 0 then
            rechargeEnd = data.rechargeTimes[#data.rechargeTimes] + RECHARGE_DURATION
        else
            rechargeEnd = now + RECHARGE_DURATION
        end
        data.rechargeTimes[#data.rechargeTimes + 1] = rechargeEnd

        RefreshChargeDisplay(self)
    end

    self.Dispel.Cooldown:SetCooldown(now, cooldown)
    self:UpdateDispel()
end

-----------------------------------------------------------------------
-- GetDispelData: Determine which dispel this enemy has based on spec
-----------------------------------------------------------------------
function GladiusFrameMixin:GetDispelData()
    local specID = self.specID
    if not specID then return nil end

    local spellMapping = GladiusMixin.specToDispel[specID]
    if not spellMapping then return nil end

    -- Normalize to a list (Warlock has multiple options)
    local spellIDs = type(spellMapping) == "table" and spellMapping or { spellMapping }

    for _, sid in ipairs(spellIDs) do
        local info = GladiusMixin.dispelData[sid]
        if info then
            local valid = true

            -- showAfterUse spells require detection first
            if info.showAfterUse then
                if not detectedDispels[self.unit] or not detectedDispels[self.unit][sid] then
                    valid = false
                end
            end

            -- Check if enabled in settings
            if valid then
                local db = self.parent and self.parent.db
                if db and db.profile and db.profile.dispelCategories then
                    if not db.profile.dispelCategories[sid] then
                        valid = false
                    end
                end
            end

            if valid then
                return {
                    spellID = sid,
                    texture = info.texture,
                    name = SafeGetSpellName(sid, info.name),
                }
            end
        end
    end

    return nil
end

-----------------------------------------------------------------------
-- GetTestModeDispelData: Provide fake dispel data for test mode
-----------------------------------------------------------------------
function GladiusFrameMixin:GetTestModeDispelData()
    local class = self.tempClass or self.class
    if not class then return nil end

    local classToSpellID = {
        ["DRUID"]   = 88423,   -- Nature's Cure (Resto)
        ["EVOKER"]  = 360823,  -- Naturalize (Preservation)
        ["MAGE"]    = 475,     -- Remove Curse
        ["MONK"]    = 115450,  -- Detox (Mistweaver)
        ["PALADIN"] = 4987,    -- Cleanse (Holy)
        ["PRIEST"]  = 527,     -- Purify
        ["SHAMAN"]  = 77130,   -- Purify Spirit (Resto)
    }

    local sid = classToSpellID[class]
    if not sid then return nil end

    local info = GladiusMixin.dispelData[sid]
    if not info then return nil end

    -- Check if enabled in settings
    local db = self.parent and self.parent.db
    if db and db.profile and db.profile.dispelCategories and db.profile.dispelCategories[sid] then
        return {
            spellID = sid,
            texture = info.texture,
            name = SafeGetSpellName(sid, info.name),
        }
    end

    return nil
end

-----------------------------------------------------------------------
-- UpdateDispel: Refresh the dispel icon display
-----------------------------------------------------------------------
function GladiusFrameMixin:UpdateDispel()
    local dispelFrame = self.Dispel
    if not dispelFrame then return end

    local db = self.parent.db
    if not db then return end

    local ls = db.profile.layoutSettings[db.profile.currentLayout]
    local showDispels = not ls or ls.showDispels ~= false
    local dispelInfo = self:GetDispelData()

    local shouldShow = showDispels and dispelInfo ~= nil
    dispelFrame:SetShown(shouldShow)

    if not dispelInfo then
        dispelFrame.Texture:SetTexture(nil)
        return
    end

    dispelFrame.spellID = dispelInfo.spellID
    dispelFrame.Texture:SetTexture(dispelInfo.texture)

    -- Purify uses charge tracking; others use simple cooldown desaturation
    if dispelInfo.spellID == 527 then
        RefreshChargeDisplay(self)
    else
        local onCD = db.profile.desaturateDispelCD and dispelFrame.Cooldown:GetCooldownDuration() > 0
        dispelFrame.Texture:SetDesaturated(onCD)
    end
end

-----------------------------------------------------------------------
-- ResetDetectedDispels: Clear all tracking state (called on arena leave)
-----------------------------------------------------------------------
function GladiusMixin:ResetDetectedDispels()
    wipe(detectedDispels)
    wipe(dispelCharges)
    wipe(lastDispelCast)
end

-----------------------------------------------------------------------
-- ResetDispel: Clear dispel state for this frame
-----------------------------------------------------------------------
function GladiusFrameMixin:ResetDispel()
    local dispelFrame = self.Dispel
    if not dispelFrame then return end

    dispelFrame.spellID = nil
    dispelFrame.Texture:SetTexture(nil)
    dispelFrame.Cooldown:Clear()
    dispelFrame.Texture:SetDesaturated(false)

    detectedDispels[self.unit] = nil
    dispelCharges[self.unit] = nil

    -- Clear throttle entries for this unit
    for key in pairs(lastDispelCast) do
        if key:match("^" .. self.unit .. "_") then
            lastDispelCast[key] = nil
        end
    end

    if self.DispelStacks then
        self.DispelStacks:SetText("")
    end
end
