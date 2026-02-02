--[[
    Gladius Midnight - Options
    AceConfig-3.0 settings panel
]]

local addonName, addon = ...
local GladiusMidnight = addon.Core

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- ============================================================================
-- Options Table
-- ============================================================================

local options = {
    name = "Gladius Midnight",
    type = "group",
    args = {
        -- General Settings
        general = {
            order = 1,
            type = "group",
            name = "Allgemein",
            inline = true,
            args = {
                enabled = {
                    order = 1,
                    type = "toggle",
                    name = "Addon aktiviert",
                    desc = "Aktiviert oder deaktiviert das Addon",
                    get = function() return GladiusMidnight.db.profile.enabled end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.enabled = val
                        GladiusMidnight:CheckArenaStatus()
                    end,
                    width = "normal",
                },
                locked = {
                    order = 2,
                    type = "toggle",
                    name = "Frames fixiert",
                    desc = "Verhindert das Verschieben der Frames",
                    get = function() return GladiusMidnight.db.profile.locked end,
                    set = function(_, val) GladiusMidnight.db.profile.locked = val end,
                    width = "normal",
                },
                test = {
                    order = 3,
                    type = "execute",
                    name = "Test Modus",
                    desc = "Zeigt Test-Frames an",
                    func = function() GladiusMidnight:ToggleTest() end,
                    width = "normal",
                },
            },
        },

        -- Frame Size Settings
        size = {
            order = 2,
            type = "group",
            name = "Frame-Größe",
            inline = true,
            args = {
                scale = {
                    order = 1,
                    type = "range",
                    name = "Skalierung",
                    min = 0.5, max = 2.0, step = 0.05,
                    get = function() return GladiusMidnight.db.profile.scale end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.scale = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                    width = "full",
                },
                frameWidth = {
                    order = 2,
                    type = "range",
                    name = "Breite",
                    min = 100, max = 400, step = 5,
                    get = function() return GladiusMidnight.db.profile.frameWidth end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.frameWidth = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                    width = "normal",
                },
                frameHeight = {
                    order = 3,
                    type = "range",
                    name = "Höhe",
                    min = 30, max = 100, step = 2,
                    get = function() return GladiusMidnight.db.profile.frameHeight end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.frameHeight = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                    width = "normal",
                },
            },
        },

        -- Layout Settings
        layout = {
            order = 3,
            type = "group",
            name = "Layout",
            inline = true,
            args = {
                growDirection = {
                    order = 1,
                    type = "select",
                    name = "Wachstumsrichtung",
                    values = {
                        ["DOWN"] = "Nach unten",
                        ["UP"] = "Nach oben",
                        ["LEFT"] = "Nach links",
                        ["RIGHT"] = "Nach rechts",
                    },
                    get = function() return GladiusMidnight.db.profile.growDirection end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.growDirection = val
                        GladiusMidnight:PositionFrames()
                    end,
                    width = "normal",
                },
                spacing = {
                    order = 2,
                    type = "range",
                    name = "Abstand",
                    min = 0, max = 30, step = 1,
                    get = function() return GladiusMidnight.db.profile.spacing end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.spacing = val
                        GladiusMidnight:PositionFrames()
                    end,
                    width = "normal",
                },
                posX = {
                    order = 3,
                    type = "range",
                    name = "X Position",
                    min = -1000, max = 1000, step = 5,
                    get = function() return GladiusMidnight.db.profile.posX end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.posX = val
                        GladiusMidnight:PositionFrames()
                    end,
                    width = "normal",
                },
                posY = {
                    order = 4,
                    type = "range",
                    name = "Y Position",
                    min = -800, max = 800, step = 5,
                    get = function() return GladiusMidnight.db.profile.posY end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.posY = val
                        GladiusMidnight:PositionFrames()
                    end,
                    width = "normal",
                },
            },
        },

        -- Module Toggles
        modules = {
            order = 4,
            type = "group",
            name = "Module",
            inline = true,
            args = {
                classIcon = {
                    order = 1,
                    type = "toggle",
                    name = "Klassen-Icon",
                    get = function() return GladiusMidnight.db.profile.modules.classIcon end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.modules.classIcon = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                name = {
                    order = 2,
                    type = "toggle",
                    name = "Namen",
                    get = function() return GladiusMidnight.db.profile.modules.name end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.modules.name = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                health = {
                    order = 3,
                    type = "toggle",
                    name = "Lebensanzeige",
                    get = function() return GladiusMidnight.db.profile.modules.health end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.modules.health = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                power = {
                    order = 4,
                    type = "toggle",
                    name = "Ressourcen",
                    get = function() return GladiusMidnight.db.profile.modules.power end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.modules.power = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                trinket = {
                    order = 5,
                    type = "toggle",
                    name = "Trinket Tracker",
                    get = function() return GladiusMidnight.db.profile.modules.trinket end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.modules.trinket = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                racial = {
                    order = 6,
                    type = "toggle",
                    name = "Racial Tracker",
                    get = function() return GladiusMidnight.db.profile.modules.racial end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.modules.racial = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
            },
        },

        -- Class Icon Settings
        classIconSettings = {
            order = 5,
            type = "group",
            name = "Klassen-Icon Einstellungen",
            inline = true,
            args = {
                size = {
                    order = 1,
                    type = "range",
                    name = "Größe",
                    min = 20, max = 80, step = 2,
                    get = function() return GladiusMidnight.db.profile.classIcon.size end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.classIcon.size = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                    width = "normal",
                },
                position = {
                    order = 2,
                    type = "select",
                    name = "Position",
                    values = { ["LEFT"] = "Links", ["RIGHT"] = "Rechts" },
                    get = function() return GladiusMidnight.db.profile.classIcon.position end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.classIcon.position = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                    width = "normal",
                },
            },
        },

        -- Name Settings
        nameSettings = {
            order = 6,
            type = "group",
            name = "Namensanzeige Einstellungen",
            inline = true,
            args = {
                height = {
                    order = 1,
                    type = "range",
                    name = "Höhe",
                    min = 8, max = 24, step = 1,
                    get = function() return GladiusMidnight.db.profile.name.height end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.name.height = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                    width = "normal",
                },
                fontSize = {
                    order = 2,
                    type = "range",
                    name = "Schriftgröße",
                    min = 8, max = 18, step = 1,
                    get = function() return GladiusMidnight.db.profile.name.fontSize end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.name.fontSize = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                    width = "normal",
                },
                showArenaId = {
                    order = 3,
                    type = "toggle",
                    name = "Arena-ID anzeigen",
                    get = function() return GladiusMidnight.db.profile.name.showArenaId end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.name.showArenaId = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
            },
        },

        -- Health Settings
        healthSettings = {
            order = 7,
            type = "group",
            name = "Lebensanzeige Einstellungen",
            inline = true,
            args = {
                height = {
                    order = 1,
                    type = "range",
                    name = "Höhe",
                    min = 10, max = 50, step = 2,
                    get = function() return GladiusMidnight.db.profile.health.height end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.health.height = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                    width = "normal",
                },
                showText = {
                    order = 2,
                    type = "toggle",
                    name = "Text anzeigen",
                    get = function() return GladiusMidnight.db.profile.health.showText end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.health.showText = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                colorByClass = {
                    order = 3,
                    type = "toggle",
                    name = "Klassenfarbe",
                    get = function() return GladiusMidnight.db.profile.health.colorByClass end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.health.colorByClass = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
            },
        },

        -- Power Settings
        powerSettings = {
            order = 8,
            type = "group",
            name = "Ressourcen Einstellungen",
            inline = true,
            args = {
                height = {
                    order = 1,
                    type = "range",
                    name = "Höhe",
                    min = 4, max = 20, step = 1,
                    get = function() return GladiusMidnight.db.profile.power.height end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.power.height = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                    width = "normal",
                },
                showText = {
                    order = 2,
                    type = "toggle",
                    name = "Text anzeigen",
                    get = function() return GladiusMidnight.db.profile.power.showText end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.power.showText = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
            },
        },

        -- Trinket/Racial Settings
        trinketSettings = {
            order = 9,
            type = "group",
            name = "Trinket/Racial Einstellungen",
            inline = true,
            args = {
                trinketSize = {
                    order = 1,
                    type = "range",
                    name = "Trinket Größe",
                    min = 16, max = 50, step = 2,
                    get = function() return GladiusMidnight.db.profile.trinket.size end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.trinket.size = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                    width = "normal",
                },
                racialSize = {
                    order = 2,
                    type = "range",
                    name = "Racial Größe",
                    min = 16, max = 50, step = 2,
                    get = function() return GladiusMidnight.db.profile.racial.size end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.racial.size = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                    width = "normal",
                },
            },
        },

        -- Profiles
        profiles = {
            order = 100,
            type = "group",
            name = "Profile",
            childGroups = "tab",
            args = {},
        },
    },
}

-- ============================================================================
-- Setup Options
-- ============================================================================

function GladiusMidnight:SetupOptions()
    -- Add profile options
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    options.args.profiles.order = 100

    -- Register options table
    AceConfig:RegisterOptionsTable(addonName, options)

    -- Add to Blizzard options panel
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(addonName, "Gladius Midnight")
end

-- Hook into OnInitialize
local origOnInit = GladiusMidnight.OnInitialize
function GladiusMidnight:OnInitialize()
    origOnInit(self)
    self:SetupOptions()
end
