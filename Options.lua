--[[
    Gladius Midnight - Options Panel
    Uses AceConfig-3.0 for WoW Midnight 12.0
]]

local addonName, addon = ...
local GladiusMidnight = LibStub("AceAddon-3.0"):GetAddon(addonName)

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Options table
local options = {
    name = "Gladius Midnight",
    type = "group",
    args = {
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
                },
                locked = {
                    order = 2,
                    type = "toggle",
                    name = "Frames fixiert",
                    desc = "Verhindert das Verschieben der Frames",
                    get = function() return GladiusMidnight.db.profile.locked end,
                    set = function(_, val) GladiusMidnight.db.profile.locked = val end,
                },
                test = {
                    order = 3,
                    type = "execute",
                    name = "Test Modus",
                    desc = "Zeigt Test-Frames an",
                    func = function() GladiusMidnight:ToggleTest() end,
                },
            },
        },
        display = {
            order = 2,
            type = "group",
            name = "Anzeige",
            inline = true,
            args = {
                showHealthText = {
                    order = 1,
                    type = "toggle",
                    name = "HP Text anzeigen",
                    get = function() return GladiusMidnight.db.profile.showHealthText end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.showHealthText = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                showPowerBar = {
                    order = 2,
                    type = "toggle",
                    name = "Ressourcen-Leiste",
                    get = function() return GladiusMidnight.db.profile.showPowerBar end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.showPowerBar = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                showTrinket = {
                    order = 3,
                    type = "toggle",
                    name = "Trinket anzeigen",
                    get = function() return GladiusMidnight.db.profile.showTrinket end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.showTrinket = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                showRacial = {
                    order = 4,
                    type = "toggle",
                    name = "Racial anzeigen",
                    get = function() return GladiusMidnight.db.profile.showRacial end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.showRacial = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
            },
        },
        size = {
            order = 3,
            type = "group",
            name = "Größe",
            inline = true,
            args = {
                scale = {
                    order = 1,
                    type = "range",
                    name = "Skalierung",
                    min = 0.5,
                    max = 2.0,
                    step = 0.05,
                    get = function() return GladiusMidnight.db.profile.scale end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.scale = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                frameWidth = {
                    order = 2,
                    type = "range",
                    name = "Frame Breite",
                    min = 100,
                    max = 300,
                    step = 5,
                    get = function() return GladiusMidnight.db.profile.frameWidth end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.frameWidth = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                frameHeight = {
                    order = 3,
                    type = "range",
                    name = "Frame Höhe",
                    min = 30,
                    max = 80,
                    step = 1,
                    get = function() return GladiusMidnight.db.profile.frameHeight end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.frameHeight = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                classIconSize = {
                    order = 4,
                    type = "range",
                    name = "Klassen-Icon Größe",
                    min = 20,
                    max = 60,
                    step = 2,
                    get = function() return GladiusMidnight.db.profile.classIconSize end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.classIconSize = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
                trinketSize = {
                    order = 5,
                    type = "range",
                    name = "Trinket/Racial Größe",
                    min = 16,
                    max = 40,
                    step = 2,
                    get = function() return GladiusMidnight.db.profile.trinketSize end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.trinketSize = val
                        GladiusMidnight:UpdateAllFrames()
                    end,
                },
            },
        },
        layout = {
            order = 4,
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
                },
                spacing = {
                    order = 2,
                    type = "range",
                    name = "Abstand",
                    min = 0,
                    max = 20,
                    step = 1,
                    get = function() return GladiusMidnight.db.profile.spacing end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.spacing = val
                        GladiusMidnight:PositionFrames()
                    end,
                },
                posX = {
                    order = 3,
                    type = "range",
                    name = "X Position",
                    min = -800,
                    max = 800,
                    step = 5,
                    get = function() return GladiusMidnight.db.profile.posX end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.posX = val
                        GladiusMidnight:PositionFrames()
                    end,
                },
                posY = {
                    order = 4,
                    type = "range",
                    name = "Y Position",
                    min = -600,
                    max = 600,
                    step = 5,
                    get = function() return GladiusMidnight.db.profile.posY end,
                    set = function(_, val)
                        GladiusMidnight.db.profile.posY = val
                        GladiusMidnight:PositionFrames()
                    end,
                },
            },
        },
        profiles = {
            order = 100,
            type = "group",
            name = "Profile",
            childGroups = "tab",
            args = {},
        },
    },
}

function GladiusMidnight:SetupOptions()
    -- Add profile options
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    options.args.profiles.order = 100

    -- Register options
    AceConfig:RegisterOptionsTable(addonName, options)

    -- Add to Blizzard options
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(addonName, "Gladius Midnight")

    -- Update slash command to open options properly
    self.SlashCommand = function(self, input)
        input = input:trim():lower()

        if input == "test" then
            self:ToggleTest()
        elseif input == "lock" then
            self.db.profile.locked = true
            self:Print("Frames |cFF00FF00locked|r")
        elseif input == "unlock" then
            self.db.profile.locked = false
            self:Print("Frames |cFFFF0000unlocked|r - drag to move")
        elseif input == "reset" then
            self.db:ResetProfile()
            self:UpdateAllFrames()
            self:Print("Settings reset to defaults")
        else
            -- Open options using AceConfigDialog
            AceConfigDialog:Open(addonName)
        end
    end
end

-- Hook into OnInitialize
local origOnInit = GladiusMidnight.OnInitialize
function GladiusMidnight:OnInitialize()
    origOnInit(self)
    self:SetupOptions()
end
