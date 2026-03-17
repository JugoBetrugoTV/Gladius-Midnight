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
    childGroups = "tab",
    args = {
        -- General Tab
        general = {
            order = 1,
            type = "group",
            name = "Allgemein",
            args = {
                header = {
                    order = 0,
                    type = "header",
                    name = "Allgemeine Optionen",
                },
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
                spacer = {
                    order = 10,
                    type = "description",
                    name = " ",
                },
            },
        },

        -- Frames Tab
        frames = {
            order = 2,
            type = "group",
            name = "Frames",
            args = {
                size = {
                    order = 1,
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
                layout = {
                    order = 2,
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
            },
        },

        -- Module Tab
        modulesTab = {
            order = 3,
            type = "group",
            name = "Module",
            args = {
                modules = {
                    order = 1,
                    type = "group",
                    name = "Aktive Module",
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
                        specIcon = {
                            order = 7,
                            type = "toggle",
                            name = "Spezialisierung",
                            get = function() return GladiusMidnight.db.profile.modules.specIcon end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.modules.specIcon = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                        },
                        targetIndicator = {
                            order = 8,
                            type = "toggle",
                            name = "Zielmarkierung",
                            get = function() return GladiusMidnight.db.profile.modules.targetIndicator end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.modules.targetIndicator = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                        },
                        interrupt = {
                            order = 9,
                            type = "toggle",
                            name = "Interrupt",
                            get = function() return GladiusMidnight.db.profile.modules.interrupt end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.modules.interrupt = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                        },
                        drTracker = {
                            order = 10,
                            type = "toggle",
                            name = "DR Tracker",
                            get = function() return GladiusMidnight.db.profile.modules.drTracker end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.modules.drTracker = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                        },
                    },
                },
            },
        },

        -- Appearance Tab
        appearance = {
            order = 4,
            type = "group",
            name = "Aussehen",
            args = {
                classIconSettings = {
                    order = 1,
                    type = "group",
                    name = "Klassen-Icon",
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
                nameSettings = {
                    order = 2,
                    type = "group",
                    name = "Namensanzeige",
                    inline = true,
                    args = {
                        fontSize = {
                            order = 1,
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
                            order = 2,
                            type = "toggle",
                            name = "Arena-ID anzeigen",
                            get = function() return GladiusMidnight.db.profile.name.showArenaId end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.name.showArenaId = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                        },
                        colorByClass = {
                            order = 3,
                            type = "toggle",
                            name = "Klassenfarbe",
                            get = function() return GladiusMidnight.db.profile.name.colorByClass end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.name.colorByClass = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                        },
                    },
                },
                healthSettings = {
                    order = 3,
                    type = "group",
                    name = "Lebensanzeige",
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
                powerSettings = {
                    order = 4,
                    type = "group",
                    name = "Ressourcen",
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
                trinketSettings = {
                    order = 5,
                    type = "group",
                    name = "Trinket / Racial",
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
                specSettings = {
                    order = 6,
                    type = "group",
                    name = "Spezialisierung",
                    inline = true,
                    args = {
                        size = {
                            order = 1,
                            type = "range",
                            name = "Icon Größe",
                            min = 16, max = 40, step = 1,
                            get = function() return GladiusMidnight.db.profile.specIcon.size end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.specIcon.size = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                            width = "normal",
                        },
                        position = {
                            order = 2,
                            type = "select",
                            name = "Position",
                            values = { ["LEFT"] = "Links", ["RIGHT"] = "Rechts" },
                            get = function() return GladiusMidnight.db.profile.specIcon.position end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.specIcon.position = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                            width = "normal",
                        },
                    },
                },
                targetIndicatorSettings = {
                    order = 7,
                    type = "group",
                    name = "Zielmarkierung",
                    inline = true,
                    args = {
                        enabledInTest = {
                            order = 1,
                            type = "toggle",
                            name = "Im Testmodus anzeigen",
                            get = function() return GladiusMidnight.db.profile.targetIndicator.enabledInTest end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.targetIndicator.enabledInTest = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                        },
                    },
                },
                interruptSettings = {
                    order = 8,
                    type = "group",
                    name = "Interrupt",
                    inline = true,
                    args = {
                        size = {
                            order = 1,
                            type = "range",
                            name = "Icon Größe",
                            min = 16, max = 40, step = 1,
                            get = function() return GladiusMidnight.db.profile.interrupt.size end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.interrupt.size = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                            width = "normal",
                        },
                        position = {
                            order = 2,
                            type = "select",
                            name = "Position",
                            values = { ["LEFT"] = "Links", ["RIGHT"] = "Rechts" },
                            get = function() return GladiusMidnight.db.profile.interrupt.position end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.interrupt.position = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                            width = "normal",
                        },
                    },
                },
                drTrackerSettings = {
                    order = 9,
                    type = "group",
                    name = "DR Tracker",
                    inline = true,
                    args = {
                        size = {
                            order = 1,
                            type = "range",
                            name = "Icon Größe",
                            min = 12, max = 28, step = 1,
                            get = function() return GladiusMidnight.db.profile.drTracker.size end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.drTracker.size = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                            width = "normal",
                        },
                        spacing = {
                            order = 2,
                            type = "range",
                            name = "Abstand",
                            min = 0, max = 8, step = 1,
                            get = function() return GladiusMidnight.db.profile.drTracker.spacing end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.drTracker.spacing = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                            width = "normal",
                        },
                        position = {
                            order = 3,
                            type = "select",
                            name = "Position",
                            values = { ["BOTTOM"] = "Unten", ["TOP"] = "Oben" },
                            get = function() return GladiusMidnight.db.profile.drTracker.position end,
                            set = function(_, val)
                                GladiusMidnight.db.profile.drTracker.position = val
                                GladiusMidnight:UpdateAllFrames()
                            end,
                            width = "normal",
                        },
                    },
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

    AceConfigDialog:SetDefaultSize(addonName, 600, 540)
end

function GladiusMidnight:StyleConfigFrame(frame)
    if not frame or frame._gmStyled then return end

    frame._gmStyled = true
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(0.06, 0.07, 0.08, 0.98)
    frame:SetBackdropBorderColor(0.9, 0.7, 0.2, 0.9)

    if not frame.GuildWarsAccent then
        local accent = frame:CreateTexture(nil, "BORDER")
        accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
        accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
        accent:SetHeight(3)
        accent:SetColorTexture(0.9, 0.7, 0.2, 0.9)
        frame.GuildWarsAccent = accent
    end

    if frame.TitleText then
        frame.TitleText:SetTextColor(0.95, 0.82, 0.32)
    end
end

function GladiusMidnight:OpenConfig()
    AceConfigDialog:Open(addonName)
    if AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames[addonName] then
        self:StyleConfigFrame(AceConfigDialog.OpenFrames[addonName])
    end
end

-- Hook into OnInitialize
local origOnInit = GladiusMidnight.OnInitialize
function GladiusMidnight:OnInitialize()
    origOnInit(self)
    self:SetupOptions()
end
