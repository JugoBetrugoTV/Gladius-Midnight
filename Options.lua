--[[
    Gladius Midnight - Options
    Standalone AceGUI configuration window with minimap button
]]

local addonName, addon = ...
local GladiusMidnight = addon.Core

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

-- ============================================================================
-- Minimap Button
-- ============================================================================

local minimapButton = nil

local function CreateMinimapButton()
    if not LDB or not LDBIcon then return end

    minimapButton = LDB:NewDataObject("GladiusMidnight", {
        type = "launcher",
        text = "Gladius Midnight",
        icon = "Interface\\Icons\\Achievement_Arena_2v2_7",
        OnClick = function(_, button)
            if button == "LeftButton" then
                GladiusMidnight:ToggleOptions()
            elseif button == "RightButton" then
                GladiusMidnight:ToggleTest()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cFF00FF00Gladius Midnight|r")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cFFFFFFFFLinksklick:|r Einstellungen")
            tooltip:AddLine("|cFFFFFFFFRechtsklick:|r Test Modus")
        end,
    })

    LDBIcon:Register("GladiusMidnight", minimapButton, GladiusMidnight.db.profile.minimap)
end

-- ============================================================================
-- Options Table
-- ============================================================================

local options = {
    name = "Gladius Midnight",
    type = "group",
    args = {
        -- Header
        header = {
            order = 0,
            type = "description",
            name = "|cFF00FF00Gladius Midnight|r - Arena Frames für WoW Midnight 12.0\n\n",
            fontSize = "medium",
        },

        -- General Settings
        general = {
            order = 1,
            type = "group",
            name = "Allgemein",
            args = {
                enabled = {
                    order = 1,
                    type = "toggle",
                    name = "Aktiviert",
                    desc = "Addon aktivieren/deaktivieren",
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.enabled end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.enabled = val
                        GladiusMidnight:CheckArenaStatus()
                    end,
                },
                locked = {
                    order = 2,
                    type = "toggle",
                    name = "Frames fixiert",
                    desc = "Verhindert das Verschieben der Frames",
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.locked end,
                    set = function(_, val) GladiusMidnight.db.profile.locked = val end,
                },
                minimapIcon = {
                    order = 3,
                    type = "toggle",
                    name = "Minimap Icon",
                    desc = "Zeigt das Icon an der Minimap",
                    width = "full",
                    get = function() return not GladiusMidnight.db.profile.minimap.hide end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.minimap.hide = not val
                        if val then
                            LDBIcon:Show("GladiusMidnight")
                        else
                            LDBIcon:Hide("GladiusMidnight")
                        end
                    end,
                },
                spacer1 = { order = 4, type = "description", name = "\n" },
                testButton = {
                    order = 5,
                    type = "execute",
                    name = "Test Modus",
                    desc = "Zeigt Test-Frames an",
                    func = function() GladiusMidnight:ToggleTest() end,
                },
                resetButton = {
                    order = 6,
                    type = "execute",
                    name = "Zurücksetzen",
                    desc = "Setzt alle Einstellungen zurück",
                    confirm = true,
                    confirmText = "Alle Einstellungen zurücksetzen?",
                    func = function()
                        GladiusMidnight.db:ResetProfile()
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
            },
        },

        -- Size & Position
        size = {
            order = 2,
            type = "group",
            name = "Größe & Position",
            args = {
                scale = {
                    order = 1,
                    type = "range",
                    name = "Skalierung",
                    min = 0.5, max = 2.0, step = 0.05,
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.scale end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.scale = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                frameWidth = {
                    order = 2,
                    type = "range",
                    name = "Breite",
                    min = 100, max = 400, step = 5,
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.frameWidth end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.frameWidth = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                frameHeight = {
                    order = 3,
                    type = "range",
                    name = "Höhe",
                    min = 30, max = 100, step = 2,
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.frameHeight end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.frameHeight = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                spacing = {
                    order = 4,
                    type = "range",
                    name = "Abstand zwischen Frames",
                    min = 0, max = 30, step = 1,
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.spacing end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.spacing = val
                        GladiusMidnight:PositionFrames()
                    end,
                },
                growDirection = {
                    order = 5,
                    type = "select",
                    name = "Wachstumsrichtung",
                    values = {
                        ["DOWN"] = "Nach unten",
                        ["UP"] = "Nach oben",
                        ["LEFT"] = "Nach links",
                        ["RIGHT"] = "Nach rechts",
                    },
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.growDirection end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.growDirection = val
                        GladiusMidnight:PositionFrames()
                    end,
                },
                spacer = { order = 6, type = "description", name = "\n|cFFFFFF00Position (oder /gladius unlock zum Verschieben)|r\n" },
                posX = {
                    order = 7,
                    type = "range",
                    name = "X Position",
                    min = -1000, max = 1000, step = 5,
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.posX end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.posX = val
                        GladiusMidnight:PositionFrames()
                    end,
                },
                posY = {
                    order = 8,
                    type = "range",
                    name = "Y Position",
                    min = -800, max = 800, step = 5,
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.posY end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.posY = val
                        GladiusMidnight:PositionFrames()
                    end,
                },
            },
        },

        -- Module Toggles
        modules = {
            order = 3,
            type = "group",
            name = "Module",
            args = {
                desc = {
                    order = 0,
                    type = "description",
                    name = "Aktiviere oder deaktiviere einzelne Module.\n\n",
                },
                classIcon = {
                    order = 1,
                    type = "toggle",
                    name = "Klassen Icon",
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.modules.classIcon end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.modules.classIcon = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                health = {
                    order = 2,
                    type = "toggle",
                    name = "Lebensanzeige",
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.modules.health end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.modules.health = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                power = {
                    order = 3,
                    type = "toggle",
                    name = "Ressourcenanzeige",
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.modules.power end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.modules.power = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                trinket = {
                    order = 4,
                    type = "toggle",
                    name = "Trinket Tracker",
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.modules.trinket end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.modules.trinket = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                racial = {
                    order = 5,
                    type = "toggle",
                    name = "Racial Tracker",
                    width = "full",
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
            order = 4,
            type = "group",
            name = "Klassen Icon",
            args = {
                size = {
                    order = 1,
                    type = "range",
                    name = "Größe",
                    min = 20, max = 80, step = 2,
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.classIcon.size end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.classIcon.size = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                position = {
                    order = 2,
                    type = "select",
                    name = "Position",
                    values = { ["LEFT"] = "Links", ["RIGHT"] = "Rechts" },
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.classIcon.position end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.classIcon.position = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
            },
        },

        -- Health Settings
        healthSettings = {
            order = 5,
            type = "group",
            name = "Lebensanzeige",
            args = {
                height = {
                    order = 1,
                    type = "range",
                    name = "Höhe",
                    min = 10, max = 50, step = 2,
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.health.height end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.health.height = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                showText = {
                    order = 2,
                    type = "toggle",
                    name = "Prozent anzeigen",
                    width = "full",
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
                    width = "full",
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
            order = 6,
            type = "group",
            name = "Ressourcen",
            args = {
                height = {
                    order = 1,
                    type = "range",
                    name = "Höhe",
                    min = 4, max = 20, step = 1,
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.power.height end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.power.height = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                showText = {
                    order = 2,
                    type = "toggle",
                    name = "Prozent anzeigen",
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.power.showText end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.power.showText = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
            },
        },

        -- Trinket/Racial Settings
        cooldownSettings = {
            order = 7,
            type = "group",
            name = "Trinket & Racial",
            args = {
                trinketSize = {
                    order = 1,
                    type = "range",
                    name = "Trinket Icon Größe",
                    min = 16, max = 50, step = 2,
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.trinket.size end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.trinket.size = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                trinketPosition = {
                    order = 2,
                    type = "select",
                    name = "Trinket Position",
                    values = { ["LEFT"] = "Links", ["RIGHT"] = "Rechts" },
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.trinket.position end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.trinket.position = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                spacer = { order = 3, type = "description", name = "\n" },
                racialSize = {
                    order = 4,
                    type = "range",
                    name = "Racial Icon Größe",
                    min = 16, max = 50, step = 2,
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.racial.size end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.racial.size = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                racialPosition = {
                    order = 5,
                    type = "select",
                    name = "Racial Position",
                    values = { ["LEFT"] = "Links", ["RIGHT"] = "Rechts" },
                    width = "full",
                    get = function() return GladiusMidnight.db.profile.racial.position end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.racial.position = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
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
-- Standalone GUI Window
-- ============================================================================

local optionsFrame = nil

function GladiusMidnight:ToggleOptions()
    if optionsFrame and optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        AceConfigDialog:Open(addonName)
    end
end

-- ============================================================================
-- Setup Options
-- ============================================================================

function GladiusMidnight:SetupOptions()
    -- Add minimap settings to defaults
    if not self.db.profile.minimap then
        self.db.profile.minimap = { hide = false }
    end

    -- Add profile options
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    options.args.profiles.order = 100

    -- Register options table
    AceConfig:RegisterOptionsTable(addonName, options)

    -- Create standalone options frame
    AceConfigDialog:SetDefaultSize(addonName, 450, 550)

    -- Create minimap button
    CreateMinimapButton()
end

-- ============================================================================
-- Update Slash Command
-- ============================================================================

local origSlashCommand = GladiusMidnight.SlashCommand
function GladiusMidnight:SlashCommand(input)
    input = (input or ""):trim():lower()

    if input == "test" then
        self:ToggleTest()
    elseif input == "lock" then
        self.db.profile.locked = true
        self:Print("Frames |cFF00FF00fixiert|r")
    elseif input == "unlock" then
        self.db.profile.locked = false
        self:Print("Frames |cFFFF0000entsperrt|r - zum Verschieben ziehen")
    elseif input == "reset" then
        self.db:ResetProfile()
        self:UpdateAllFrames()
        self:Print("Einstellungen zurückgesetzt")
    elseif input == "minimap" then
        self.db.profile.minimap.hide = not self.db.profile.minimap.hide
        if self.db.profile.minimap.hide then
            LDBIcon:Hide("GladiusMidnight")
            self:Print("Minimap Icon |cFFFF0000versteckt|r")
        else
            LDBIcon:Show("GladiusMidnight")
            self:Print("Minimap Icon |cFF00FF00sichtbar|r")
        end
    elseif input == "" or input == "config" or input == "options" then
        self:ToggleOptions()
    else
        self:Print("Befehle:")
        self:Print("  |cFF00FF00/gladius|r - Einstellungen öffnen")
        self:Print("  |cFF00FF00/gladius test|r - Test-Modus")
        self:Print("  |cFF00FF00/gladius lock|r - Frames fixieren")
        self:Print("  |cFF00FF00/gladius unlock|r - Frames entsperren")
        self:Print("  |cFF00FF00/gladius minimap|r - Minimap Icon toggle")
        self:Print("  |cFF00FF00/gladius reset|r - Zurücksetzen")
    end
end

-- Hook into OnInitialize
local origOnInit = GladiusMidnight.OnInitialize
function GladiusMidnight:OnInitialize()
    origOnInit(self)
    self:SetupOptions()
end
