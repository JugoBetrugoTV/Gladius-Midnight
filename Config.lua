--[[
    Gladius Midnight - Config
    AceConfig-3.0 options panel for all addon settings.
    Sections: General, Class Icon, CastBar, Trinket/Racial, DR,
              Dispel, Widgets, Font, Textures, Positioning, Profiles.
]]

local LSM = LibStub("LibSharedMedia-3.0")

-----------------------------------------------------------------------
-- Helper: safe runtime accessors (closures call these at panel-open time)
-----------------------------------------------------------------------
local function getProfile()
    return GladiusMidnight and GladiusMidnight.db and GladiusMidnight.db.profile
end

local function getLS()
    local p = getProfile()
    if not p then return nil end
    local ln = p.currentLayout or "Gladiuish"
    p.layoutSettings[ln] = p.layoutSettings[ln] or {}
    return p.layoutSettings[ln]
end

local function ensureTable(parent, key)
    if not parent[key] then parent[key] = {} end
    return parent[key]
end

-----------------------------------------------------------------------
-- Helper: layout list for dropdown
-----------------------------------------------------------------------
local function getLayoutTable()
    local t = {}
    for k, v in pairs(GladiusMixin.layouts) do
        t[k] = (v.name and v.name) or k
    end
    return t
end

-----------------------------------------------------------------------
-- Helper: combat lockdown guard
-----------------------------------------------------------------------
local function validateCombat()
    if InCombatLockdown() then
        return "Must leave combat first."
    end
    return true
end

-----------------------------------------------------------------------
-- Helper: shared-media value lists
-----------------------------------------------------------------------
local function StatusbarValues()
    local t, keys = {}, {}
    for k in pairs(LSM:HashTable(LSM.MediaType.STATUSBAR)) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    for _, k in ipairs(keys) do t[k] = k end
    return t
end

-----------------------------------------------------------------------
-- Static data computed at load time (DRList.lua loaded before Config)
-----------------------------------------------------------------------
local growthValues = { "Down", "Up", "Right", "Left" }

local drCategoryDisplay = {}
for _, cat in ipairs(GladiusMixin.drCategories or {}) do
    local tex = GladiusMixin.drIcons and GladiusMixin.drIcons[cat]
    if tex then
        drCategoryDisplay[cat] = "|T" .. tostring(tex) .. ":16|t " .. cat
    else
        drCategoryDisplay[cat] = cat
    end
end

-----------------------------------------------------------------------
-- Refresh helpers called from set functions
-----------------------------------------------------------------------
local function refreshConfig()
    if GladiusMidnight and GladiusMidnight.RefreshConfig then
        GladiusMidnight:RefreshConfig()
    end
end

local function refreshTest()
    if GladiusMidnight and GladiusMidnight.Test then
        local _, instanceType = IsInInstance()
        if instanceType ~= "arena" and GladiusMidnight.arena1
           and GladiusMidnight.arena1:IsShown() then
            GladiusMidnight:Test()
        end
    end
end

local function refreshFrameColors()
    if not GladiusMidnight then return end
    for i = 1, GladiusMidnight.maxArenaOpponents do
        local f = GladiusMidnight["arena" .. i]
        if f and f.UpdateFrameColors then f:UpdateFrameColors() end
    end
end

local function refreshStatusText()
    if not GladiusMidnight then return end
    for i = 1, GladiusMidnight.maxArenaOpponents do
        local f = GladiusMidnight["arena" .. i]
        if f and f.UpdateStatusTextVisible then f:UpdateStatusTextVisible() end
    end
end

local function notifyChange()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("GladiusMidnight")
end

-----------------------------------------------------------------------
-- OPTIONS TABLE
-----------------------------------------------------------------------
GladiusMixin.optionsTable = {
    type = "group",
    name = "Gladius Midnight",
    childGroups = "tab",
    validate = validateCombat,
    args = {

        ---------------------------------------------------------------
        -- Top-level controls (outside tabs)
        ---------------------------------------------------------------
        setLayout = {
            order = 0.1,
            name = "Layout",
            desc = "Select which arena frame layout to use.",
            type = "select",
            style = "dropdown",
            get = function()
                local p = getProfile()
                return p and p.currentLayout or "Gladiuish"
            end,
            set = function(_, val)
                if GladiusMidnight and GladiusMidnight.SetLayout then
                    GladiusMidnight:SetLayout(nil, val)
                end
            end,
            values = getLayoutTable,
            width = 1.2,
        },
        test = {
            order = 0.2,
            name = "Test",
            desc = "Show test frames.",
            type = "execute",
            func = function()
                if GladiusMidnight and GladiusMidnight.Test then
                    GladiusMidnight:Test()
                end
            end,
            width = "half",
        },
        hide = {
            order = 0.3,
            name = "Hide",
            desc = "Hide test frames.",
            type = "execute",
            func = function()
                if not GladiusMidnight then return end
                for i = 1, GladiusMidnight.maxArenaOpponents do
                    local f = GladiusMidnight["arena" .. i]
                    if f then f:Hide() end
                end
            end,
            width = "half",
        },
        dragHint = {
            order = 0.4,
            name = "|cffff3300Shift+Ctrl+Drag to reposition elements in test mode.|r",
            type = "description",
            fontSize = "medium",
            width = "full",
        },

        ---------------------------------------------------------------
        -- 1. GENERAL
        ---------------------------------------------------------------
        general = {
            order = 1,
            name = "General",
            type = "group",
            args = {
                classColors = {
                    order = 1,
                    name = "Class Colored Health Bars",
                    desc = "Color health bars by class color instead of green.",
                    type = "toggle",
                    width = "full",
                    get = function() local p = getProfile(); return p and p.classColors end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.classColors = val
                        refreshConfig()
                        refreshTest()
                    end,
                },
                showNames = {
                    order = 2,
                    name = "Show Player Names",
                    desc = "Display opponent names on frames. When disabled, shows arena1/arena2/arena3.",
                    type = "toggle",
                    width = "full",
                    get = function() local p = getProfile(); return p and p.showNames end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.showNames = val
                        refreshTest()
                    end,
                },
                darkModeHeader = {
                    order = 3,
                    name = "Dark Mode",
                    type = "header",
                },
                darkMode = {
                    order = 3.1,
                    name = "Enable Dark Mode",
                    desc = "Darken frame borders and textures.",
                    type = "toggle",
                    width = 0.9,
                    get = function() local p = getProfile(); return p and p.darkMode end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.darkMode = val
                        refreshFrameColors()
                        refreshTest()
                    end,
                },
                darkModeValue = {
                    order = 3.2,
                    name = "Darkness",
                    desc = "How dark the frame borders should be (0 = black, 1 = white).",
                    type = "range",
                    min = 0,
                    max = 1,
                    step = 0.01,
                    width = 0.8,
                    disabled = function() local p = getProfile(); return not (p and p.darkMode) end,
                    get = function() local p = getProfile(); return p and p.darkModeValue or 0.2 end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.darkModeValue = val
                        refreshFrameColors()
                    end,
                },
                darkModeDesaturate = {
                    order = 3.3,
                    name = "Desaturate",
                    desc = "Desaturate frame textures in dark mode.",
                    type = "toggle",
                    width = 0.7,
                    disabled = function() local p = getProfile(); return not (p and p.darkMode) end,
                    get = function() local p = getProfile(); return p and p.darkModeDesaturate end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.darkModeDesaturate = val
                        refreshFrameColors()
                    end,
                },
                statusTextHeader = {
                    order = 4,
                    name = "Status Text",
                    type = "header",
                },
                alwaysShowText = {
                    order = 4.1,
                    name = "Always Show",
                    desc = "Always show health/power text instead of on mouseover only.",
                    type = "toggle",
                    get = function()
                        local p = getProfile()
                        return p and p.statusText and p.statusText.alwaysShow
                    end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        ensureTable(p, "statusText")
                        p.statusText.alwaysShow = val
                        refreshStatusText()
                    end,
                },
                formatNumbers = {
                    order = 4.2,
                    name = "Format Numbers",
                    desc = "Abbreviate large health values (e.g. 500K instead of 500000).",
                    type = "toggle",
                    get = function()
                        local p = getProfile()
                        return p and p.statusText and p.statusText.formatNumbers
                    end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        ensureTable(p, "statusText")
                        p.statusText.formatNumbers = val
                        if val then p.statusText.usePercentage = false end
                        refreshTest()
                    end,
                },
                usePercentage = {
                    order = 4.3,
                    name = "Use Percentage",
                    desc = "Show health and power as percentage values.",
                    type = "toggle",
                    get = function()
                        local p = getProfile()
                        return p and p.statusText and p.statusText.usePercentage
                    end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        ensureTable(p, "statusText")
                        p.statusText.usePercentage = val
                        if val then p.statusText.formatNumbers = false end
                        refreshTest()
                    end,
                },
                hideStatusText = {
                    order = 4.4,
                    name = "Hide Status Text",
                    desc = "Completely hide all health/power text.",
                    type = "toggle",
                    get = function()
                        local ls = getLS()
                        return ls and ls.hideStatusText
                    end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.hideStatusText = val
                        refreshTest()
                    end,
                },
                hidePowerText = {
                    order = 4.5,
                    name = "Hide Power Text",
                    desc = "Hide power bar text (mana/energy/rage numbers).",
                    type = "toggle",
                    get = function() local p = getProfile(); return p and p.hidePowerText end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.hidePowerText = val
                        refreshStatusText()
                    end,
                },
                miscHeader = {
                    order = 5,
                    name = "Miscellaneous",
                    type = "header",
                },
                stealthAlpha = {
                    order = 5.1,
                    name = "Stealth Alpha",
                    desc = "Transparency of frames for stealthed opponents (0 = invisible, 1 = fully visible).",
                    type = "range",
                    min = 0,
                    max = 1,
                    step = 0.05,
                    width = 1.2,
                    get = function()
                        return GladiusMixin.stealthAlpha or 0.4
                    end,
                    set = function(_, val)
                        GladiusMixin.stealthAlpha = val
                        if GladiusMidnight then
                            GladiusMidnight.stealthAlpha = val
                        end
                    end,
                },
                shadowSightTimer = {
                    order = 5.2,
                    name = "Shadowsight Timer",
                    desc = "Show a timer for Shadowsight orb spawns in arena.",
                    type = "toggle",
                    get = function() local p = getProfile(); return p and p.shadowSightTimer end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.shadowSightTimer = val
                    end,
                },
                testHeader = {
                    order = 6,
                    name = "Test Mode",
                    type = "header",
                },
                testUnits = {
                    order = 6.1,
                    name = "Number of Test Units",
                    desc = "How many arena frames to show in test mode (1-3).",
                    type = "range",
                    min = 1,
                    max = 3,
                    step = 1,
                    width = 1.2,
                    get = function()
                        local p = getProfile()
                        return p and p.testUnits or 3
                    end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.testUnits = val
                    end,
                },
                testButton = {
                    order = 6.2,
                    name = "Toggle Test Mode",
                    desc = "Show or hide the test frames with sample data.",
                    type = "execute",
                    func = function()
                        if GladiusMidnight and GladiusMidnight.Test then
                            GladiusMidnight:Test()
                        end
                    end,
                    width = 1.0,
                },
            },
        },

        ---------------------------------------------------------------
        -- 2. CLASS ICON
        ---------------------------------------------------------------
        classIcon = {
            order = 2,
            name = "Class Icon",
            type = "group",
            args = {
                hideClassIcon = {
                    order = 1,
                    name = "Hide Class Icon",
                    desc = "Hide the class icon completely. Aura overlays will still appear when active.",
                    type = "toggle",
                    width = "full",
                    get = function() local ls = getLS(); return ls and ls.hideClassIcon end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.hideClassIcon = val
                        refreshConfig()
                        refreshTest()
                    end,
                },
                replaceClassIcon = {
                    order = 2,
                    name = "Replace with Spec Icon",
                    desc = "Show the specialization icon instead of the class icon.",
                    type = "toggle",
                    width = "full",
                    disabled = function() local ls = getLS(); return ls and ls.hideClassIcon end,
                    get = function() local ls = getLS(); return ls and ls.replaceClassIcon end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.replaceClassIcon = val
                        refreshConfig()
                        refreshTest()
                    end,
                },
                showHealerIcon = {
                    order = 3,
                    name = "Show Healer Icon",
                    desc = "Display a healer role icon for healer specializations instead of the class icon.",
                    type = "toggle",
                    width = "full",
                    disabled = function()
                        local ls = getLS()
                        return ls and (ls.hideClassIcon or ls.replaceClassIcon)
                    end,
                    get = function() local ls = getLS(); return ls and ls.showHealerIcon end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.showHealerIcon = val
                        refreshConfig()
                        refreshTest()
                    end,
                },
                cropIcons = {
                    order = 4,
                    name = "Crop Icons",
                    desc = "Slightly crop class/spec icons to remove border artifacts.",
                    type = "toggle",
                    width = "full",
                    get = function() local ls = getLS(); return ls and ls.cropIcons end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.cropIcons = val
                        refreshConfig()
                        refreshTest()
                    end,
                },
                cooldownHeader = {
                    order = 5,
                    name = "Cooldown Display",
                    type = "header",
                },
                invertClassIconCooldown = {
                    order = 5.1,
                    name = "Invert Cooldown Swipe",
                    desc = "Reverse the direction of the cooldown swipe animation on the class icon.",
                    type = "toggle",
                    width = "full",
                    get = function() local p = getProfile(); return p and p.invertClassIconCooldown end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p or not GladiusMidnight then return end
                        p.invertClassIconCooldown = val
                        for i = 1, GladiusMidnight.maxArenaOpponents do
                            local f = GladiusMidnight["arena" .. i]
                            if f and f.UpdateClassIconCooldownReverse then
                                f:UpdateClassIconCooldownReverse()
                            end
                        end
                    end,
                },
                showDecimalsClassIcon = {
                    order = 5.2,
                    name = "Show Decimal Countdown",
                    desc = "Display cooldown time with decimal precision on the class icon.",
                    type = "toggle",
                    width = 1.4,
                    get = function() local p = getProfile(); return p and p.showDecimalsClassIcon end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.showDecimalsClassIcon = val
                        if GladiusMidnight and GladiusMidnight.SetupCustomCD then
                            GladiusMidnight:SetupCustomCD()
                        end
                    end,
                },
                decimalThreshold = {
                    order = 5.3,
                    name = "Decimal Threshold",
                    desc = "Show decimals only when remaining time is below this threshold (seconds).",
                    type = "range",
                    min = 1,
                    max = 10,
                    step = 0.1,
                    width = 0.8,
                    disabled = function() local p = getProfile(); return not (p and p.showDecimalsClassIcon) end,
                    get = function() local p = getProfile(); return p and p.decimalThreshold or 6 end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.decimalThreshold = val
                        if GladiusMidnight then
                            GladiusMidnight:UpdateDecimalThreshold()
                            GladiusMidnight:SetupCustomCD()
                        end
                    end,
                },
            },
        },

        ---------------------------------------------------------------
        -- 3. CASTBAR
        ---------------------------------------------------------------
        castBar = {
            order = 3,
            name = "CastBar",
            type = "group",
            args = {
                styleHeader = {
                    order = 1,
                    name = "CastBar Style",
                    type = "header",
                },
                modernCastbar = {
                    order = 1.1,
                    name = "Modern CastBar",
                    desc = "Use the modern Blizzard-style castbar appearance.",
                    type = "toggle",
                    width = "full",
                    get = function() local ls = getLS(); return ls and ls.modernCastbar end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.modernCastbar = val
                        if GladiusMidnight then
                            GladiusMidnight:ModernOrClassicCastbar()
                        end
                        refreshTest()
                    end,
                },
                simpleCastbar = {
                    order = 1.2,
                    name = "Simple CastBar",
                    desc = "Simplified castbar with fewer visual elements.",
                    type = "toggle",
                    width = "full",
                    disabled = function() local ls = getLS(); return not (ls and ls.modernCastbar) end,
                    get = function() local ls = getLS(); return ls and ls.simpleCastbar end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.simpleCastbar = val
                        if GladiusMidnight then
                            GladiusMidnight:ModernOrClassicCastbar()
                        end
                        refreshTest()
                    end,
                },
                keepDefaultModernTextures = {
                    order = 1.3,
                    name = "Keep Default Modern Textures",
                    desc = "When using modern castbars, keep Blizzard's default textures instead of applying custom statusbar textures.",
                    type = "toggle",
                    width = "full",
                    disabled = function() local ls = getLS(); return not (ls and ls.modernCastbar) end,
                    get = function() local ls = getLS(); return ls and ls.keepDefaultModernTextures end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.keepDefaultModernTextures = val
                        if GladiusMidnight then
                            GladiusMidnight:UpdateTextures()
                        end
                        refreshTest()
                    end,
                },
                colorsHeader = {
                    order = 2,
                    name = "CastBar Colors",
                    type = "header",
                },
                colorsDesc = {
                    order = 2.05,
                    name = "Customize the colors for different cast bar states.",
                    type = "description",
                    fontSize = "medium",
                },
                standard = {
                    order = 2.1,
                    name = "Standard Cast",
                    desc = "Color for interruptible casts.",
                    type = "color",
                    hasAlpha = true,
                    get = function()
                        local p = getProfile()
                        local c = p and p.castBarColors and p.castBarColors.standard
                        if c then return c[1], c[2], c[3], c[4] end
                        return 1.0, 0.7, 0.0, 1
                    end,
                    set = function(_, r, g, b, a)
                        local p = getProfile()
                        if not p then return end
                        ensureTable(p, "castBarColors")
                        p.castBarColors.standard = { r, g, b, a }
                        if GladiusMidnight then
                            GladiusMidnight.castbarColors = p.castBarColors
                        end
                        refreshTest()
                    end,
                },
                channel = {
                    order = 2.2,
                    name = "Channeled Cast",
                    desc = "Color for channeled spells.",
                    type = "color",
                    hasAlpha = true,
                    get = function()
                        local p = getProfile()
                        local c = p and p.castBarColors and p.castBarColors.channel
                        if c then return c[1], c[2], c[3], c[4] end
                        return 0.0, 1.0, 0.0, 1
                    end,
                    set = function(_, r, g, b, a)
                        local p = getProfile()
                        if not p then return end
                        ensureTable(p, "castBarColors")
                        p.castBarColors.channel = { r, g, b, a }
                        if GladiusMidnight then
                            GladiusMidnight.castbarColors = p.castBarColors
                        end
                        refreshTest()
                    end,
                },
                uninterruptable = {
                    order = 2.3,
                    name = "Uninterruptible",
                    desc = "Color for casts that cannot be interrupted.",
                    type = "color",
                    hasAlpha = true,
                    get = function()
                        local p = getProfile()
                        local c = p and p.castBarColors and p.castBarColors.uninterruptable
                        if c then return c[1], c[2], c[3], c[4] end
                        return 0.7, 0.7, 0.7, 1
                    end,
                    set = function(_, r, g, b, a)
                        local p = getProfile()
                        if not p then return end
                        ensureTable(p, "castBarColors")
                        p.castBarColors.uninterruptable = { r, g, b, a }
                        if GladiusMidnight then
                            GladiusMidnight.castbarColors = p.castBarColors
                        end
                        refreshTest()
                    end,
                },
                interruptNotReady = {
                    order = 2.4,
                    name = "Interrupt Not Ready",
                    desc = "Color shown when your interrupt ability is on cooldown.",
                    type = "color",
                    hasAlpha = true,
                    get = function()
                        local p = getProfile()
                        local c = p and p.castBarColors and p.castBarColors.interruptNotReady
                        if c then return c[1], c[2], c[3], c[4] end
                        return 1.0, 0.0, 0.0, 1
                    end,
                    set = function(_, r, g, b, a)
                        local p = getProfile()
                        if not p then return end
                        ensureTable(p, "castBarColors")
                        p.castBarColors.interruptNotReady = { r, g, b, a }
                        if GladiusMidnight then
                            GladiusMidnight.castbarColors = p.castBarColors
                        end
                        refreshTest()
                    end,
                },
            },
        },

        ---------------------------------------------------------------
        -- 4. TRINKET / RACIAL
        ---------------------------------------------------------------
        trinketRacial = {
            order = 4,
            name = "Trinket / Racial",
            type = "group",
            args = {
                showRacial = {
                    order = 1,
                    name = "Show Racial Ability",
                    desc = "Display the racial ability icon next to the trinket.",
                    type = "toggle",
                    width = "full",
                    get = function()
                        local ls = getLS()
                        if ls and ls.showRacial ~= nil then return ls.showRacial end
                        return true
                    end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.showRacial = val
                        refreshConfig()
                        refreshTest()
                    end,
                },
                swapRacialTrinket = {
                    order = 2,
                    name = "Swap Racial / Trinket Position",
                    desc = "Swap the positions of the racial ability icon and the PvP trinket icon.",
                    type = "toggle",
                    width = "full",
                    get = function() local p = getProfile(); return p and p.swapRacialTrinket end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.swapRacialTrinket = val
                        refreshConfig()
                        refreshTest()
                    end,
                },
                desaturateTrinketCD = {
                    order = 3,
                    name = "Desaturate Trinket on Cooldown",
                    desc = "Gray out the trinket icon while it is on cooldown.",
                    type = "toggle",
                    width = "full",
                    get = function() local p = getProfile(); return p and p.desaturateTrinketCD end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.desaturateTrinketCD = val
                    end,
                },
                invertTrinketCooldown = {
                    order = 4,
                    name = "Invert Trinket/Racial Cooldown Swipe",
                    desc = "Reverse the direction of the cooldown swipe animation on trinket and racial icons.",
                    type = "toggle",
                    width = "full",
                    get = function() local ls = getLS(); return ls and ls.invertTrinketCooldown end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls or not GladiusMidnight then return end
                        ls.invertTrinketCooldown = val
                        for i = 1, GladiusMidnight.maxArenaOpponents do
                            local f = GladiusMidnight["arena" .. i]
                            if f and f.UpdateTrinketRacialCooldownReverse then
                                f:UpdateTrinketRacialCooldownReverse()
                            end
                        end
                    end,
                },
            },
        },

        ---------------------------------------------------------------
        -- 5. DIMINISHING RETURNS
        ---------------------------------------------------------------
        dr = {
            order = 5,
            name = "Diminishing Returns",
            type = "group",
            args = {
                optionsGroup = {
                    order = 1,
                    name = "DR Options",
                    type = "group",
                    inline = true,
                    args = {
                        showDecimalsDR = {
                            order = 1,
                            name = "Show Decimal Countdown",
                            desc = "Display DR cooldown time with decimal precision.",
                            type = "toggle",
                            width = 1.2,
                            get = function() local p = getProfile(); return p and p.showDecimalsDR end,
                            set = function(_, val)
                                local p = getProfile()
                                if not p then return end
                                p.showDecimalsDR = val
                                if GladiusMidnight and GladiusMidnight.SetupCustomCD then
                                    GladiusMidnight:SetupCustomCD()
                                end
                            end,
                        },
                        colorDRCooldownText = {
                            order = 2,
                            name = "Color DR Cooldown Text",
                            desc = "Color the DR cooldown countdown text based on the DR severity level.",
                            type = "toggle",
                            width = "full",
                            get = function() local p = getProfile(); return p and p.colorDRCooldownText end,
                            set = function(_, val)
                                local p = getProfile()
                                if not p then return end
                                p.colorDRCooldownText = val
                                if GladiusMidnight and GladiusMidnight.SetupCustomCD then
                                    GladiusMidnight:SetupCustomCD()
                                end
                                refreshTest()
                            end,
                        },
                        blackDRBorder = {
                            order = 3,
                            name = "Black DR Border",
                            desc = "Force DR icon borders to be black instead of colored by severity.",
                            type = "toggle",
                            width = "full",
                            get = function() local p = getProfile(); return p and p.blackDRBorder end,
                            set = function(_, val)
                                local p = getProfile()
                                if not p then return end
                                p.blackDRBorder = val
                                refreshTest()
                            end,
                        },
                    },
                },
                layoutGroup = {
                    order = 2,
                    name = "DR Layout (Per-Layout)",
                    type = "group",
                    inline = true,
                    args = {
                        growthDirection = {
                            order = 1,
                            name = "Growth Direction",
                            desc = "Direction in which new DR icons appear.",
                            type = "select",
                            style = "dropdown",
                            values = growthValues,
                            get = function()
                                local ls = getLS()
                                local dr = ls and ls.dr
                                return dr and dr.growthDirection or 4
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "dr")
                                ls.dr.growthDirection = val
                                refreshConfig()
                                refreshTest()
                            end,
                        },
                        size = {
                            order = 2,
                            name = "Icon Size",
                            desc = "Size of each DR icon in pixels.",
                            type = "range",
                            min = 12,
                            max = 64,
                            step = 1,
                            get = function()
                                local ls = getLS()
                                local dr = ls and ls.dr
                                return dr and dr.size or 28
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "dr")
                                ls.dr.size = val
                                refreshConfig()
                                refreshTest()
                            end,
                        },
                        spacing = {
                            order = 3,
                            name = "Icon Spacing",
                            desc = "Space between DR icons in pixels.",
                            type = "range",
                            min = 0,
                            max = 20,
                            step = 1,
                            get = function()
                                local ls = getLS()
                                local dr = ls and ls.dr
                                return dr and dr.spacing or 6
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "dr")
                                ls.dr.spacing = val
                                refreshConfig()
                                refreshTest()
                            end,
                        },
                        borderSize = {
                            order = 4,
                            name = "Border Size",
                            desc = "Thickness of the DR icon border.",
                            type = "range",
                            min = 0,
                            max = 4,
                            step = 0.5,
                            get = function()
                                local ls = getLS()
                                local dr = ls and ls.dr
                                return dr and dr.borderSize or 1
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "dr")
                                ls.dr.borderSize = val
                                refreshConfig()
                                refreshTest()
                            end,
                        },
                    },
                },
                categoriesGroup = {
                    order = 3,
                    name = "DR Categories",
                    type = "group",
                    inline = true,
                    args = {
                        categoriesDesc = {
                            order = 0,
                            name = "Enable or disable tracking for each DR category.",
                            type = "description",
                        },
                        categories = {
                            order = 1,
                            name = "",
                            type = "multiselect",
                            get = function(_, key)
                                local p = getProfile()
                                if not p or not p.drCategories then return true end
                                if p.drCategories[key] == nil then return true end
                                return p.drCategories[key]
                            end,
                            set = function(_, key, val)
                                local p = getProfile()
                                if not p then return end
                                p.drCategories = p.drCategories or {}
                                p.drCategories[key] = val
                            end,
                            values = drCategoryDisplay,
                        },
                    },
                },
            },
        },

        ---------------------------------------------------------------
        -- 6. DISPEL
        ---------------------------------------------------------------
        dispel = {
            order = 6,
            name = "Dispel",
            type = "group",
            args = {
                showDispels = {
                    order = 1,
                    name = "Show Dispel Icon",
                    desc = "Display the enemy's dispel ability icon on their frame.",
                    type = "toggle",
                    width = "full",
                    get = function()
                        local ls = getLS()
                        if ls and ls.showDispels ~= nil then return ls.showDispels end
                        return true
                    end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.showDispels = val
                        refreshConfig()
                        refreshTest()
                    end,
                },
                desaturateDispelCD = {
                    order = 2,
                    name = "Desaturate on Cooldown",
                    desc = "Gray out the dispel icon when the ability is on cooldown.",
                    type = "toggle",
                    width = "full",
                    get = function() local p = getProfile(); return p and p.desaturateDispelCD end,
                    set = function(_, val)
                        local p = getProfile()
                        if not p then return end
                        p.desaturateDispelCD = val
                    end,
                },
            },
        },

        ---------------------------------------------------------------
        -- 7. WIDGETS
        ---------------------------------------------------------------
        widgets = {
            order = 7,
            name = "Widgets",
            type = "group",
            args = {
                widgetsDesc = {
                    order = 0,
                    name = "Overlay indicators shown on arena frames. Position values are offsets from the frame center.",
                    type = "description",
                    fontSize = "medium",
                },
                targetGroup = {
                    order = 1,
                    name = "Target Indicator",
                    type = "group",
                    inline = true,
                    args = {
                        enabled = {
                            order = 1,
                            name = "Enable",
                            desc = "Show a crosshair indicator on your current target.",
                            type = "toggle",
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.targetIndicator
                                return w and w.enabled
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "targetIndicator")
                                ls.widgets.targetIndicator.enabled = val
                                if GladiusMidnight then
                                    GladiusMidnight:RegisterWidgetEvents()
                                end
                                refreshTest()
                            end,
                        },
                        posX = {
                            order = 2,
                            name = "X Offset",
                            type = "range",
                            min = -200,
                            max = 200,
                            step = 1,
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.targetIndicator
                                return w and w.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "targetIndicator")
                                ls.widgets.targetIndicator.posX = val
                                refreshConfig()
                            end,
                        },
                        posY = {
                            order = 3,
                            name = "Y Offset",
                            type = "range",
                            min = -200,
                            max = 200,
                            step = 1,
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.targetIndicator
                                return w and w.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "targetIndicator")
                                ls.widgets.targetIndicator.posY = val
                                refreshConfig()
                            end,
                        },
                    },
                },
                focusGroup = {
                    order = 2,
                    name = "Focus Indicator",
                    type = "group",
                    inline = true,
                    args = {
                        enabled = {
                            order = 1,
                            name = "Enable",
                            desc = "Show a pin indicator on your focus target.",
                            type = "toggle",
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.focusIndicator
                                return w and w.enabled
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "focusIndicator")
                                ls.widgets.focusIndicator.enabled = val
                                if GladiusMidnight then
                                    GladiusMidnight:RegisterWidgetEvents()
                                end
                                refreshTest()
                            end,
                        },
                        posX = {
                            order = 2,
                            name = "X Offset",
                            type = "range",
                            min = -200,
                            max = 200,
                            step = 1,
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.focusIndicator
                                return w and w.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "focusIndicator")
                                ls.widgets.focusIndicator.posX = val
                                refreshConfig()
                            end,
                        },
                        posY = {
                            order = 3,
                            name = "Y Offset",
                            type = "range",
                            min = -200,
                            max = 200,
                            step = 1,
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.focusIndicator
                                return w and w.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "focusIndicator")
                                ls.widgets.focusIndicator.posY = val
                                refreshConfig()
                            end,
                        },
                    },
                },
                combatGroup = {
                    order = 3,
                    name = "Combat Indicator",
                    type = "group",
                    inline = true,
                    args = {
                        enabled = {
                            order = 1,
                            name = "Enable",
                            desc = "Show a food/drink icon when an enemy is out of combat.",
                            type = "toggle",
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.combatIndicator
                                return w and w.enabled
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "combatIndicator")
                                ls.widgets.combatIndicator.enabled = val
                                if GladiusMidnight then
                                    GladiusMidnight:RegisterWidgetEvents()
                                end
                                refreshTest()
                            end,
                        },
                        posX = {
                            order = 2,
                            name = "X Offset",
                            type = "range",
                            min = -200,
                            max = 200,
                            step = 1,
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.combatIndicator
                                return w and w.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "combatIndicator")
                                ls.widgets.combatIndicator.posX = val
                                refreshConfig()
                            end,
                        },
                        posY = {
                            order = 3,
                            name = "Y Offset",
                            type = "range",
                            min = -200,
                            max = 200,
                            step = 1,
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.combatIndicator
                                return w and w.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "combatIndicator")
                                ls.widgets.combatIndicator.posY = val
                                refreshConfig()
                            end,
                        },
                    },
                },
                partyTargetGroup = {
                    order = 4,
                    name = "Party Target Indicators",
                    type = "group",
                    inline = true,
                    args = {
                        enabled = {
                            order = 1,
                            name = "Enable",
                            desc = "Show colored dots when party members are targeting an arena enemy.",
                            type = "toggle",
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.partyTargetIndicators
                                return w and w.enabled
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "partyTargetIndicators")
                                ls.widgets.partyTargetIndicators.enabled = val
                                if GladiusMidnight then
                                    GladiusMidnight:RegisterWidgetEvents()
                                end
                                refreshTest()
                            end,
                        },
                        posX = {
                            order = 2,
                            name = "X Offset",
                            type = "range",
                            min = -200,
                            max = 200,
                            step = 1,
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.partyTargetIndicators
                                return w and w.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "partyTargetIndicators")
                                ls.widgets.partyTargetIndicators.posX = val
                                refreshConfig()
                            end,
                        },
                        posY = {
                            order = 3,
                            name = "Y Offset",
                            type = "range",
                            min = -200,
                            max = 200,
                            step = 1,
                            get = function()
                                local ls = getLS()
                                local w = ls and ls.widgets and ls.widgets.partyTargetIndicators
                                return w and w.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "widgets")
                                ensureTable(ls.widgets, "partyTargetIndicators")
                                ls.widgets.partyTargetIndicators.posY = val
                                refreshConfig()
                            end,
                        },
                    },
                },
            },
        },

        ---------------------------------------------------------------
        -- 8. FONT
        ---------------------------------------------------------------
        font = {
            order = 8,
            name = "Font",
            type = "group",
            args = {
                changeFont = {
                    order = 1,
                    name = "Use Custom Font",
                    desc = "Override the default layout font with a custom font selection.",
                    type = "toggle",
                    width = "full",
                    get = function() local ls = getLS(); return ls and ls.changeFont end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.changeFont = val
                        if GladiusMidnight and GladiusMidnight.UpdateFonts then
                            GladiusMidnight:UpdateFonts()
                        end
                    end,
                },
                fontName = {
                    order = 2,
                    name = "Font",
                    desc = "Select a font from LibSharedMedia.",
                    type = "select",
                    style = "dropdown",
                    dialogControl = "LSM30_Font",
                    values = function()
                        if GladiusMidnight and GladiusMidnight.FontValues then
                            return GladiusMidnight:FontValues()
                        end
                        return {}
                    end,
                    disabled = function() local ls = getLS(); return not (ls and ls.changeFont) end,
                    get = function()
                        local ls = getLS()
                        return ls and ls.fontName or "Prototype"
                    end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.fontName = val
                        if GladiusMidnight and GladiusMidnight.UpdateFonts then
                            GladiusMidnight:UpdateFonts()
                        end
                    end,
                },
                fontSize = {
                    order = 3,
                    name = "Font Size",
                    desc = "Size of the font in points.",
                    type = "range",
                    min = 4,
                    max = 32,
                    step = 1,
                    disabled = function() local ls = getLS(); return not (ls and ls.changeFont) end,
                    get = function()
                        local ls = getLS()
                        return ls and ls.fontSize or 10
                    end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.fontSize = val
                        if GladiusMidnight and GladiusMidnight.UpdateFonts then
                            GladiusMidnight:UpdateFonts()
                        end
                    end,
                },
                fontOutline = {
                    order = 4,
                    name = "Font Outline",
                    desc = "Outline style applied to font text.",
                    type = "select",
                    style = "dropdown",
                    values = function()
                        if GladiusMidnight and GladiusMidnight.FontOutlineValues then
                            return GladiusMidnight:FontOutlineValues()
                        end
                        return { [""] = "None", ["OUTLINE"] = "Normal", ["THICKOUTLINE"] = "Thick" }
                    end,
                    disabled = function() local ls = getLS(); return not (ls and ls.changeFont) end,
                    get = function()
                        local ls = getLS()
                        return ls and ls.fontOutline or "OUTLINE"
                    end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.fontOutline = val
                        if GladiusMidnight and GladiusMidnight.UpdateFonts then
                            GladiusMidnight:UpdateFonts()
                        end
                    end,
                },
            },
        },

        ---------------------------------------------------------------
        -- 9. TEXTURES
        ---------------------------------------------------------------
        textures = {
            order = 9,
            name = "Textures",
            type = "group",
            args = {
                texturesDesc = {
                    order = 0,
                    name = "Texture settings are per-layout. Changing layout will show that layout's texture configuration.",
                    type = "description",
                    fontSize = "medium",
                },
                generalTexture = {
                    order = 1,
                    name = "General StatusBar Texture",
                    desc = "Texture used for health and power bars.",
                    type = "select",
                    style = "dropdown",
                    dialogControl = "LSM30_Statusbar",
                    values = StatusbarValues,
                    width = 1.5,
                    get = function()
                        local ls = getLS()
                        local t = ls and ls.textures
                        return (t and t.generalStatusBarTexture) or "Gladius Default"
                    end,
                    set = function(_, key)
                        local ls = getLS()
                        if not ls then return end
                        ensureTable(ls, "textures")
                        ls.textures.generalStatusBarTexture = key
                        if GladiusMidnight then GladiusMidnight:UpdateTextures() end
                    end,
                },
                healerTexture = {
                    order = 2,
                    name = "Healer StatusBar Texture",
                    desc = "Alternate texture for healer specialization bars.",
                    type = "select",
                    style = "dropdown",
                    dialogControl = "LSM30_Statusbar",
                    values = StatusbarValues,
                    width = 1.5,
                    get = function()
                        local ls = getLS()
                        local t = ls and ls.textures
                        return (t and t.healStatusBarTexture) or "Gladius Default"
                    end,
                    set = function(_, key)
                        local ls = getLS()
                        if not ls then return end
                        ensureTable(ls, "textures")
                        ls.textures.healStatusBarTexture = key
                        if GladiusMidnight then GladiusMidnight:UpdateTextures() end
                    end,
                },
                healerClassStackOnly = {
                    order = 2.5,
                    name = "Healer Texture Only on Class Stacking",
                    desc = "Only use the healer texture when there are duplicate classes in the arena (class stacking).",
                    type = "toggle",
                    width = "full",
                    get = function()
                        local ls = getLS()
                        return ls and ls.retextureHealerClassStackOnly
                    end,
                    set = function(_, val)
                        local ls = getLS()
                        if not ls then return end
                        ls.retextureHealerClassStackOnly = val
                        if GladiusMidnight then GladiusMidnight:UpdateTextures() end
                    end,
                },
                castbarTexture = {
                    order = 3,
                    name = "CastBar Texture",
                    desc = "Texture used for cast bars.",
                    type = "select",
                    style = "dropdown",
                    dialogControl = "LSM30_Statusbar",
                    values = StatusbarValues,
                    width = 1.5,
                    get = function()
                        local ls = getLS()
                        local t = ls and ls.textures
                        return (t and t.castbarStatusBarTexture) or "Gladius Default"
                    end,
                    set = function(_, key)
                        local ls = getLS()
                        if not ls then return end
                        ensureTable(ls, "textures")
                        ls.textures.castbarStatusBarTexture = key
                        if GladiusMidnight then GladiusMidnight:UpdateTextures() end
                    end,
                },
                bgHeader = {
                    order = 4,
                    name = "Background",
                    type = "header",
                },
                bgTexture = {
                    order = 4.1,
                    name = "Background Texture",
                    desc = "Texture used behind health bars.",
                    type = "select",
                    style = "dropdown",
                    dialogControl = "LSM30_Statusbar",
                    values = StatusbarValues,
                    width = 1.5,
                    get = function()
                        local ls = getLS()
                        local t = ls and ls.textures
                        return (t and t.bgTexture) or "Solid"
                    end,
                    set = function(_, key)
                        local ls = getLS()
                        if not ls then return end
                        ensureTable(ls, "textures")
                        ls.textures.bgTexture = key
                        if GladiusMidnight then GladiusMidnight:UpdateTextures() end
                    end,
                },
                bgColor = {
                    order = 4.2,
                    name = "Background Color",
                    desc = "Color and transparency of the background texture.",
                    type = "color",
                    hasAlpha = true,
                    width = 1.5,
                    get = function()
                        local ls = getLS()
                        local t = ls and ls.textures
                        local c = t and t.bgColor or { 0, 0, 0, 0.6 }
                        return c[1], c[2], c[3], c[4]
                    end,
                    set = function(_, r, g, b, a)
                        local ls = getLS()
                        if not ls then return end
                        ensureTable(ls, "textures")
                        ls.textures.bgColor = { r, g, b, a }
                        if GladiusMidnight then GladiusMidnight:UpdateTextures() end
                    end,
                },
            },
        },

        ---------------------------------------------------------------
        -- 10. POSITIONING
        ---------------------------------------------------------------
        positioning = {
            order = 10,
            name = "Positioning",
            type = "group",
            args = {
                positioningDesc = {
                    order = 0,
                    name = "Position settings are per-layout. Use Shift+Ctrl+Drag in test mode for quick positioning.",
                    type = "description",
                    fontSize = "medium",
                },
                frameGroup = {
                    order = 1,
                    name = "Frame Position",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "Horizontal (X)",
                            type = "range",
                            min = -1000,
                            max = 1000,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                return ls and ls.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ls.posX = val
                                refreshConfig()
                            end,
                        },
                        posY = {
                            order = 2,
                            name = "Vertical (Y)",
                            type = "range",
                            min = -1000,
                            max = 1000,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                return ls and ls.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ls.posY = val
                                refreshConfig()
                            end,
                        },
                        scale = {
                            order = 3,
                            name = "Scale",
                            desc = "Overall scale of all arena frames.",
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.1,
                            isPercent = true,
                            get = function()
                                local ls = getLS()
                                return ls and ls.scale or 1.0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ls.scale = val
                                refreshConfig()
                            end,
                        },
                        spacing = {
                            order = 4,
                            name = "Spacing",
                            desc = "Vertical spacing between arena frames.",
                            type = "range",
                            min = 0,
                            max = 100,
                            step = 1,
                            get = function()
                                local ls = getLS()
                                return ls and ls.spacing or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ls.spacing = val
                                refreshConfig()
                            end,
                        },
                        growthDirection = {
                            order = 5,
                            name = "Growth Direction",
                            desc = "Direction in which additional arena frames are placed.",
                            type = "select",
                            style = "dropdown",
                            values = { "Down", "Up" },
                            get = function()
                                local ls = getLS()
                                return ls and ls.growthDirection or 1
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ls.growthDirection = val
                                refreshConfig()
                            end,
                        },
                        mirrored = {
                            order = 6,
                            name = "Mirrored",
                            desc = "Mirror frame layout horizontally (useful for left-side placement).",
                            type = "toggle",
                            get = function()
                                local ls = getLS()
                                return ls and ls.mirrored
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ls.mirrored = val
                                refreshConfig()
                            end,
                        },
                    },
                },
                castBarGroup = {
                    order = 2,
                    name = "CastBar Position",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "X Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local cb = ls and ls.castBar
                                return cb and cb.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "castBar")
                                ls.castBar.posX = val
                                refreshConfig()
                            end,
                        },
                        posY = {
                            order = 2,
                            name = "Y Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local cb = ls and ls.castBar
                                return cb and cb.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "castBar")
                                ls.castBar.posY = val
                                refreshConfig()
                            end,
                        },
                    },
                },
                specIconGroup = {
                    order = 3,
                    name = "Spec Icon Position",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "X Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local si = ls and ls.specIcon
                                return si and si.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "specIcon")
                                ls.specIcon.posX = val
                                refreshConfig()
                            end,
                        },
                        posY = {
                            order = 2,
                            name = "Y Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local si = ls and ls.specIcon
                                return si and si.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "specIcon")
                                ls.specIcon.posY = val
                                refreshConfig()
                            end,
                        },
                    },
                },
                trinketGroup = {
                    order = 4,
                    name = "Trinket Position",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "X Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local tr = ls and ls.trinket
                                return tr and tr.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "trinket")
                                ls.trinket.posX = val
                                refreshConfig()
                            end,
                        },
                        posY = {
                            order = 2,
                            name = "Y Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local tr = ls and ls.trinket
                                return tr and tr.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "trinket")
                                ls.trinket.posY = val
                                refreshConfig()
                            end,
                        },
                    },
                },
                racialGroup = {
                    order = 5,
                    name = "Racial Position",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "X Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local rc = ls and ls.racial
                                return rc and rc.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "racial")
                                ls.racial.posX = val
                                refreshConfig()
                            end,
                        },
                        posY = {
                            order = 2,
                            name = "Y Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local rc = ls and ls.racial
                                return rc and rc.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "racial")
                                ls.racial.posY = val
                                refreshConfig()
                            end,
                        },
                    },
                },
                dispelGroup = {
                    order = 6,
                    name = "Dispel Position",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "X Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local dp = ls and ls.dispel
                                return dp and dp.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "dispel")
                                ls.dispel.posX = val
                                refreshConfig()
                            end,
                        },
                        posY = {
                            order = 2,
                            name = "Y Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local dp = ls and ls.dispel
                                return dp and dp.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "dispel")
                                ls.dispel.posY = val
                                refreshConfig()
                            end,
                        },
                    },
                },
                classIconGroup = {
                    order = 7,
                    name = "Class Icon Position",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "X Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local ci = ls and ls.classIcon
                                return ci and ci.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "classIcon")
                                ls.classIcon.posX = val
                                refreshConfig()
                            end,
                        },
                        posY = {
                            order = 2,
                            name = "Y Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local ci = ls and ls.classIcon
                                return ci and ci.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "classIcon")
                                ls.classIcon.posY = val
                                refreshConfig()
                            end,
                        },
                    },
                },
                drGroup = {
                    order = 8,
                    name = "DR Icons Position",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "X Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local dr = ls and ls.dr
                                return dr and dr.posX or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "dr")
                                ls.dr.posX = val
                                refreshConfig()
                                refreshTest()
                            end,
                        },
                        posY = {
                            order = 2,
                            name = "Y Offset",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                            get = function()
                                local ls = getLS()
                                local dr = ls and ls.dr
                                return dr and dr.posY or 0
                            end,
                            set = function(_, val)
                                local ls = getLS()
                                if not ls then return end
                                ensureTable(ls, "dr")
                                ls.dr.posY = val
                                refreshConfig()
                                refreshTest()
                            end,
                        },
                    },
                },
            },
        },

        ---------------------------------------------------------------
        -- 11. PROFILES (placeholder, populated after DB creation)
        ---------------------------------------------------------------
        profiles = {
            order = 11,
            name = "Profiles",
            type = "group",
            args = {
                placeholder = {
                    order = 1,
                    name = "Profile management will be available after the addon is fully loaded.",
                    type = "description",
                    fontSize = "medium",
                },
            },
        },
    },
}

-----------------------------------------------------------------------
-- Hook Initialize: set handler, add AceDBOptions profiles, add import/export
-----------------------------------------------------------------------
do
    local origInitialize = GladiusMixin.Initialize
    function GladiusMixin:Initialize()
        -- Run original initialization (creates db, registers options, etc.)
        origInitialize(self)

        -- Set handler so AceConfig can resolve info.handler references
        if self.optionsTable then
            self.optionsTable.handler = self
        end

        -- Replace profile placeholder with AceDBOptions profile management
        if self.db and self.optionsTable then
            local AceDBOptions = LibStub("AceDBOptions-3.0", true)
            if AceDBOptions then
                local profileOpts = AceDBOptions:GetOptionsTable(self.db)
                profileOpts.order = 1

                local profileArgs = {
                    aceProfiles = profileOpts,
                }

                -- Add Import/Export buttons if the module is loaded
                if self.ExportProfile then
                    profileArgs.exportHeader = {
                        order = 2,
                        name = "Import / Export",
                        type = "header",
                    }
                    profileArgs.exportButton = {
                        order = 2.1,
                        name = "Export Profile",
                        desc = "Export your current profile as a shareable string.",
                        type = "execute",
                        func = function()
                            if GladiusMidnight and GladiusMidnight.ExportProfile then
                                GladiusMidnight:ExportProfile()
                            end
                        end,
                        width = 1.0,
                    }
                end
                if self.ImportProfile then
                    profileArgs.importInput = {
                        order = 2.2,
                        name = "Import Profile String",
                        desc = "Paste a profile string to import settings.",
                        type = "input",
                        multiline = 4,
                        width = "full",
                        get = function() return "" end,
                        set = function(_, val)
                            if GladiusMidnight and GladiusMidnight.ImportProfile then
                                GladiusMidnight:ImportProfile(val)
                            end
                        end,
                    }
                end

                self.optionsTable.args.profiles = {
                    order = 11,
                    name = "Profiles",
                    type = "group",
                    childGroups = "tab",
                    args = profileArgs,
                }

                LibStub("AceConfigRegistry-3.0"):NotifyChange("GladiusMidnight")
            end
        end
    end
end

-----------------------------------------------------------------------
-- End of Config.lua
-----------------------------------------------------------------------
