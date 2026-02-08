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
GladiusMixin.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

GladiusMixin.layouts = {}

-- Locale fallback: returns the key itself if no translation exists
GladiusMixin.L = setmetatable({}, { __index = function(_, k) return k end })

GladiusMixin.defaultSettings = {
    profile = {
        currentLayout = "Gladiuish",
        classColors = true,
        showNames = true,
        hidePowerText = true,
        showDecimalsDR = true,
        showDecimalsClassIcon = true,
        decimalThreshold = 6,
        colorDRCooldownText = false,
        darkModeValue = 0.2,
        desaturateTrinketCD = true,
        desaturateDispelCD = true,
        darkModeDesaturate = true,
        invertClassIconCooldown = true,
        statusText = {
            alwaysShow = true,
            formatNumbers = true,
        },
        castBarColors = {
            standard = { 1.0, 0.7, 0.0, 1 },
            channel = { 0.0, 1.0, 0.0, 1 },
            uninterruptable = { 0.7, 0.7, 0.7, 1 },
            interruptNotReady = { 1.0, 0.0, 0.0, 1 },
        },
        layoutSettings = {},
    }
}
