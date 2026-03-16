--[[
    Gladius Midnight - Init
    Declares global mixins and default profile settings.
    Loaded before all other Lua files.
]]

GladiusMixin = {}
GladiusFrameMixin = {}
GladiusCastBarExtMixin = {}

local buildVersion = select(1, GetBuildInfo())
GladiusMixin.isMidnight = buildVersion:match("^12")
GladiusMixin.isMoP = buildVersion:match("^5%.")
GladiusMixin.isTBC = buildVersion:match("^2%.")
GladiusMixin.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

GladiusMixin.layouts = {}

-- Locale fallback: returns the key itself if no translation exists
GladiusMixin.L = setmetatable({}, { __index = function(_, k) return k end })

GladiusMixin.defaultSettings = {
    profile = {
        currentLayout = "Gladiuish",

        -- Health Bars
        classColors = true,
        classColorFrameTexture = false,
        classColorFrameTextureOnlyClassIcon = false,
        classColorFrameTextureHealerGreen = false,
        reverseBarsFill = false,

        -- Names
        showNames = true,
        classColorNames = false,
        showArenaNumber = false,

        -- Dark Mode
        darkMode = false,
        darkModeValue = 0.2,
        darkModeDesaturate = true,

        -- Status Text
        hidePowerText = true,
        statusText = {
            alwaysShow = true,
            formatNumbers = true,
            usePercentage = false,
        },

        -- Class Icon
        showDecimalsClassIcon = true,
        decimalThreshold = 6,
        invertClassIconCooldown = true,
        disableAurasOnClassIcon = false,

        -- Trinket / Racial
        desaturateTrinketCD = true,
        colorTrinket = false,
        removeUnequippedTrinketTexture = false,
        forceShowTrinketOnHuman = false,
        replaceHumanRacialWithTrinket = false,
        swapRacialTrinket = false,

        -- Dispel
        desaturateDispelCD = true,

        -- DR
        showDecimalsDR = true,
        colorDRCooldownText = false,
        blackDRBorder = false,
        drStaticIcons = false,
        drResetTime = 18.5,
        drCategoriesPerClass = false,
        drCategoriesPerSpec = false,
        dynamicIconsPerClass = false,
        dynamicIconsPerSpec = false,

        -- Swipe Animations
        disableSwipeEdge = false,
        disableClassIconSwipe = false,
        disableDRSwipe = false,
        disableTrinketRacialSwipe = false,

        -- Masque
        enableMasque = false,
        disableOvershields = false,

        -- Stealth
        stealthAlpha = 0.4,
        colorMysteryGray = true,

        -- Misc
        shadowSightTimer = false,
        testUnits = 3,

        -- CastBar Colors
        castBarColors = {
            standard = { 1.0, 0.7, 0.0, 1 },
            channel = { 0.0, 1.0, 0.0, 1 },
            uninterruptable = { 0.7, 0.7, 0.7, 1 },
            interruptNotReady = { 1.0, 0.0, 0.0, 1 },
        },

        layoutSettings = {},
    }
}
