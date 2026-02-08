--[[=========================================================================
    Gladius Midnight - Configuration Panel
    AceConfig-based options UI with all addon settings
===========================================================================]]

local _, Gladius = ...

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

-- =========================================================================
-- Options Table Builder
-- =========================================================================
local function BuildOptionsTable()
    return {
        type = "group",
        name = "Gladius Midnight",
        childGroups = "tab",
        args = {
            -- ==================================
            -- General Settings Tab
            -- ==================================
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = {
                    headerGeneral = {
                        type = "header",
                        name = "General Settings",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable Addon",
                        desc = "Enable or disable Gladius Midnight",
                        order = 2,
                        get = function() return Gladius.db.profile.enabled end,
                        set = function(_, val) Gladius.db.profile.enabled = val end,
                    },
                    locked = {
                        type = "toggle",
                        name = "Lock Frames",
                        desc = "Lock frame positions to prevent accidental dragging",
                        order = 3,
                        get = function() return Gladius.db.profile.locked end,
                        set = function(_, val)
                            Gladius.db.profile.locked = val
                            Gladius.dragFrame:EnableMouse(not val)
                        end,
                    },
                    testSpacer = {
                        type = "description",
                        name = "",
                        order = 4,
                    },
                    testMode = {
                        type = "execute",
                        name = "Test Mode (3 Opponents)",
                        desc = "Show test arena frames for configuration",
                        order = 5,
                        func = function() Gladius:ActivateTestMode(3) end,
                    },
                    testMode5 = {
                        type = "execute",
                        name = "Test Mode (5 Opponents)",
                        order = 6,
                        func = function() Gladius:ActivateTestMode(5) end,
                    },
                    hideTest = {
                        type = "execute",
                        name = "Hide Test Frames",
                        order = 7,
                        func = function()
                            Gladius.isTestMode = false
                            Gladius:HideAllFrames()
                        end,
                    },
                },
            },

            -- ==================================
            -- Frame Settings Tab
            -- ==================================
            frames = {
                type = "group",
                name = "Frames",
                order = 2,
                args = {
                    headerSize = {
                        type = "header",
                        name = "Size & Position",
                        order = 1,
                    },
                    frameScale = {
                        type = "range",
                        name = "Frame Scale",
                        min = 0.5, max = 2.0, step = 0.05,
                        order = 2,
                        get = function() return Gladius.db.profile.frameScale end,
                        set = function(_, val)
                            Gladius.db.profile.frameScale = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    frameWidth = {
                        type = "range",
                        name = "Frame Width",
                        min = 100, max = 300, step = 1,
                        order = 3,
                        get = function() return Gladius.db.profile.frameWidth end,
                        set = function(_, val)
                            Gladius.db.profile.frameWidth = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    frameHeight = {
                        type = "range",
                        name = "Frame Height",
                        min = 20, max = 80, step = 1,
                        order = 4,
                        get = function() return Gladius.db.profile.frameHeight end,
                        set = function(_, val)
                            Gladius.db.profile.frameHeight = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    powerBarHeight = {
                        type = "range",
                        name = "Power Bar Height",
                        min = 4, max = 20, step = 1,
                        order = 5,
                        get = function() return Gladius.db.profile.powerBarHeight end,
                        set = function(_, val)
                            Gladius.db.profile.powerBarHeight = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    frameSpacing = {
                        type = "range",
                        name = "Frame Spacing",
                        min = 0, max = 100, step = 1,
                        order = 6,
                        get = function() return Gladius.db.profile.frameSpacing end,
                        set = function(_, val)
                            Gladius.db.profile.frameSpacing = val
                            Gladius:RepositionFrames()
                        end,
                    },
                    growDirection = {
                        type = "select",
                        name = "Growth Direction",
                        values = { DOWN = "Down", UP = "Up" },
                        order = 7,
                        get = function() return Gladius.db.profile.growDirection end,
                        set = function(_, val)
                            Gladius.db.profile.growDirection = val
                            Gladius:RepositionFrames()
                        end,
                    },
                    headerVisual = {
                        type = "header",
                        name = "Visual",
                        order = 10,
                    },
                    classColorBars = {
                        type = "toggle",
                        name = "Class Color Health Bars",
                        order = 11,
                        get = function() return Gladius.db.profile.classColorBars end,
                        set = function(_, val)
                            Gladius.db.profile.classColorBars = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    classColorNames = {
                        type = "toggle",
                        name = "Class Color Names",
                        order = 12,
                        get = function() return Gladius.db.profile.classColorNames end,
                        set = function(_, val)
                            Gladius.db.profile.classColorNames = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    showNames = {
                        type = "toggle",
                        name = "Show Names",
                        order = 13,
                        get = function() return Gladius.db.profile.showNames end,
                        set = function(_, val)
                            Gladius.db.profile.showNames = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    showHealthText = {
                        type = "toggle",
                        name = "Show Health Percentage",
                        order = 14,
                        get = function() return Gladius.db.profile.showHealthText end,
                        set = function(_, val)
                            Gladius.db.profile.showHealthText = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    showPowerText = {
                        type = "toggle",
                        name = "Show Power Percentage",
                        order = 15,
                        get = function() return Gladius.db.profile.showPowerText end,
                        set = function(_, val)
                            Gladius.db.profile.showPowerText = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    bgAlpha = {
                        type = "range",
                        name = "Background Opacity",
                        min = 0, max = 1, step = 0.05,
                        order = 16,
                        get = function() return Gladius.db.profile.bgAlpha end,
                        set = function(_, val)
                            Gladius.db.profile.bgAlpha = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    headerIndicators = {
                        type = "header",
                        name = "Indicators",
                        order = 20,
                    },
                    targetHighlight = {
                        type = "toggle",
                        name = "Show Target Highlight",
                        order = 21,
                        get = function() return Gladius.db.profile.targetHighlight end,
                        set = function(_, val) Gladius.db.profile.targetHighlight = val end,
                    },
                    focusHighlight = {
                        type = "toggle",
                        name = "Show Focus Highlight",
                        order = 22,
                        get = function() return Gladius.db.profile.focusHighlight end,
                        set = function(_, val) Gladius.db.profile.focusHighlight = val end,
                    },
                },
            },

            -- ==================================
            -- Class Icon Settings Tab
            -- ==================================
            classIcon = {
                type = "group",
                name = "Class Icon",
                order = 3,
                args = {
                    classIconEnabled = {
                        type = "toggle",
                        name = "Enable Class Icon",
                        order = 1,
                        get = function() return Gladius.db.profile.classIconEnabled end,
                        set = function(_, val)
                            Gladius.db.profile.classIconEnabled = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    classIconSize = {
                        type = "range",
                        name = "Class Icon Size",
                        min = 20, max = 64, step = 1,
                        order = 2,
                        get = function() return Gladius.db.profile.classIconSize end,
                        set = function(_, val)
                            Gladius.db.profile.classIconSize = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    showSpecIcon = {
                        type = "toggle",
                        name = "Show Spec Icon",
                        desc = "Show specialization icon on the class icon",
                        order = 3,
                        get = function() return Gladius.db.profile.showSpecIcon end,
                        set = function(_, val)
                            Gladius.db.profile.showSpecIcon = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    auraPriorityOnIcon = {
                        type = "toggle",
                        name = "Aura Priority Overlay",
                        desc = "Show important auras (CC, buffs) on the class icon",
                        order = 4,
                        get = function() return Gladius.db.profile.auraPriorityOnIcon end,
                        set = function(_, val) Gladius.db.profile.auraPriorityOnIcon = val end,
                    },
                },
            },

            -- ==================================
            -- Trinket Settings Tab
            -- ==================================
            trinket = {
                type = "group",
                name = "Trinket",
                order = 4,
                args = {
                    trinketEnabled = {
                        type = "toggle",
                        name = "Enable Trinket Tracking",
                        order = 1,
                        get = function() return Gladius.db.profile.trinketEnabled end,
                        set = function(_, val)
                            Gladius.db.profile.trinketEnabled = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    trinketSize = {
                        type = "range",
                        name = "Trinket Icon Size",
                        min = 16, max = 48, step = 1,
                        order = 2,
                        get = function() return Gladius.db.profile.trinketSize end,
                        set = function(_, val)
                            Gladius.db.profile.trinketSize = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    trinketDesaturateCD = {
                        type = "toggle",
                        name = "Desaturate on Cooldown",
                        desc = "Gray out the trinket icon when it is on cooldown",
                        order = 3,
                        get = function() return Gladius.db.profile.trinketDesaturateCD end,
                        set = function(_, val) Gladius.db.profile.trinketDesaturateCD = val end,
                    },
                },
            },

            -- ==================================
            -- Racial Settings Tab
            -- ==================================
            racial = {
                type = "group",
                name = "Racial",
                order = 5,
                args = {
                    racialEnabled = {
                        type = "toggle",
                        name = "Enable Racial Tracking",
                        order = 1,
                        get = function() return Gladius.db.profile.racialEnabled end,
                        set = function(_, val)
                            Gladius.db.profile.racialEnabled = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    racialSize = {
                        type = "range",
                        name = "Racial Icon Size",
                        min = 16, max = 48, step = 1,
                        order = 2,
                        get = function() return Gladius.db.profile.racialSize end,
                        set = function(_, val)
                            Gladius.db.profile.racialSize = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                },
            },

            -- ==================================
            -- DR Tracker Settings Tab
            -- ==================================
            drTracker = {
                type = "group",
                name = "DR Tracker",
                order = 6,
                args = {
                    drEnabled = {
                        type = "toggle",
                        name = "Enable DR Tracking",
                        order = 1,
                        get = function() return Gladius.db.profile.drEnabled end,
                        set = function(_, val)
                            Gladius.db.profile.drEnabled = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    drSize = {
                        type = "range",
                        name = "DR Icon Size",
                        min = 16, max = 40, step = 1,
                        order = 2,
                        get = function() return Gladius.db.profile.drSize end,
                        set = function(_, val)
                            Gladius.db.profile.drSize = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    drSpacing = {
                        type = "range",
                        name = "DR Icon Spacing",
                        min = 0, max = 10, step = 1,
                        order = 3,
                        get = function() return Gladius.db.profile.drSpacing end,
                        set = function(_, val)
                            Gladius.db.profile.drSpacing = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    drGrowDirection = {
                        type = "select",
                        name = "DR Growth Direction",
                        values = { RIGHT = "Right", LEFT = "Left", UP = "Up", DOWN = "Down" },
                        order = 4,
                        get = function() return Gladius.db.profile.drGrowDirection end,
                        set = function(_, val)
                            Gladius.db.profile.drGrowDirection = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    drShowSeverity = {
                        type = "toggle",
                        name = "Show DR Severity",
                        desc = "Display severity text on DR icons (1/2, 1/4, Immune)",
                        order = 5,
                        get = function() return Gladius.db.profile.drShowSeverity end,
                        set = function(_, val) Gladius.db.profile.drShowSeverity = val end,
                    },
                    drColorText = {
                        type = "toggle",
                        name = "Color Severity Text",
                        desc = "Color the severity text green/yellow/red",
                        order = 6,
                        get = function() return Gladius.db.profile.drColorText end,
                        set = function(_, val) Gladius.db.profile.drColorText = val end,
                    },
                    headerCategories = {
                        type = "header",
                        name = "DR Categories",
                        order = 10,
                    },
                },
            },

            -- ==================================
            -- Cast Bar Settings Tab
            -- ==================================
            castbar = {
                type = "group",
                name = "Cast Bar",
                order = 7,
                args = {
                    castBarEnabled = {
                        type = "toggle",
                        name = "Enable Cast Bar",
                        order = 1,
                        get = function() return Gladius.db.profile.castBarEnabled end,
                        set = function(_, val)
                            Gladius.db.profile.castBarEnabled = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    castBarHeight = {
                        type = "range",
                        name = "Cast Bar Height",
                        min = 8, max = 30, step = 1,
                        order = 2,
                        get = function() return Gladius.db.profile.castBarHeight end,
                        set = function(_, val)
                            Gladius.db.profile.castBarHeight = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    castBarShowIcon = {
                        type = "toggle",
                        name = "Show Spell Icon",
                        order = 3,
                        get = function() return Gladius.db.profile.castBarShowIcon end,
                        set = function(_, val)
                            Gladius.db.profile.castBarShowIcon = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    castBarShowTime = {
                        type = "toggle",
                        name = "Show Cast Time",
                        order = 4,
                        get = function() return Gladius.db.profile.castBarShowTime end,
                        set = function(_, val)
                            Gladius.db.profile.castBarShowTime = val
                            Gladius:RefreshAllSettings()
                        end,
                    },
                    interruptColorCastbar = {
                        type = "toggle",
                        name = "Color When Interrupt on CD",
                        desc = "Change castbar color when your interrupt is on cooldown",
                        order = 5,
                        get = function() return Gladius.db.profile.interruptColorCastbar end,
                        set = function(_, val) Gladius.db.profile.interruptColorCastbar = val end,
                    },
                    headerColors = {
                        type = "header",
                        name = "Cast Bar Colors",
                        order = 10,
                    },
                    normalColor = {
                        type = "color",
                        name = "Normal Cast",
                        order = 11,
                        get = function()
                            local c = Gladius.db.profile.castBarColors.normal
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            local c = Gladius.db.profile.castBarColors.normal
                            c.r, c.g, c.b = r, g, b
                        end,
                    },
                    channelColor = {
                        type = "color",
                        name = "Channel Cast",
                        order = 12,
                        get = function()
                            local c = Gladius.db.profile.castBarColors.channel
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            local c = Gladius.db.profile.castBarColors.channel
                            c.r, c.g, c.b = r, g, b
                        end,
                    },
                    uninterruptibleColor = {
                        type = "color",
                        name = "Uninterruptible",
                        order = 13,
                        get = function()
                            local c = Gladius.db.profile.castBarColors.uninterruptible
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            local c = Gladius.db.profile.castBarColors.uninterruptible
                            c.r, c.g, c.b = r, g, b
                        end,
                    },
                    interruptedColor = {
                        type = "color",
                        name = "Interrupt on Cooldown",
                        order = 14,
                        get = function()
                            local c = Gladius.db.profile.castBarColors.interrupted
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            local c = Gladius.db.profile.castBarColors.interrupted
                            c.r, c.g, c.b = r, g, b
                        end,
                    },
                },
            },

            -- ==================================
            -- Profiles Tab
            -- ==================================
            profiles = AceDBOptions:GetOptionsTable(Gladius.db),
        },
    }
end

-- =========================================================================
-- Add DR category toggles dynamically
-- =========================================================================
local function AddDRCategoryToggles(options)
    local drArgs = options.args.drTracker.args
    local order = 11

    for _, category in ipairs(Gladius.DR_CATEGORIES) do
        drArgs["drCat_" .. category] = {
            type = "toggle",
            name = "Track " .. category,
            order = order,
            get = function() return Gladius.db.profile.drCategories[category] end,
            set = function(_, val)
                Gladius.db.profile.drCategories[category] = val
                Gladius:RefreshAllSettings()
            end,
        }
        order = order + 1
    end
end

-- =========================================================================
-- Config Setup and Open
-- =========================================================================
function Gladius:SetupConfig()
    local options = BuildOptionsTable()
    AddDRCategoryToggles(options)

    AceConfig:RegisterOptionsTable("GladiusMidnight", options)
    self.configPanel = AceConfigDialog:AddToBlizOptions("GladiusMidnight", "Gladius Midnight")
end

function Gladius:OpenConfig()
    -- Open the AceConfig dialog
    AceConfigDialog:Open("GladiusMidnight")
end

-- =========================================================================
-- Refresh Helpers
-- =========================================================================
function Gladius:RefreshAllSettings()
    for i = 1, 5 do
        local frame = self.arenaFrames[i]
        if frame then
            frame:ApplySettings()
        end
    end
end

function Gladius:RepositionFrames()
    local db = self.db.profile
    for i = 2, 5 do
        local frame = self.arenaFrames[i]
        local prev = self.arenaFrames[i - 1]
        if frame and prev then
            frame:ClearAllPoints()
            if db.growDirection == "DOWN" then
                frame:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -db.frameSpacing)
            else
                frame:SetPoint("BOTTOMRIGHT", prev, "TOPRIGHT", 0, db.frameSpacing)
            end
        end
    end
end
