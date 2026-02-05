-- Core/Init.lua --
-- v2.0 -- COMPLETE AND CORRECTED VERSION --
local addonName = ...
if type(_G.ArenaCore) ~= "table" then _G.ArenaCore = {} end
local addon = _G.ArenaCore

-- Basic addon metadata
addon.AddonName = addonName or "ArenaCore"
addon.Version   = addon.Version or "0.9.2.3"

-- Useful paths
local ADDON_PATH = "Interface\\AddOns\\" .. addon.AddonName .. "\\"
addon.MEDIA_PATH  = ADDON_PATH .. "Media\\"
addon.FONT_PATH   = addon.MEDIA_PATH .. "Fonts\\arenacore.ttf"
addon.CUSTOM_FONT = addon.FONT_PATH

-- ============================================================================
-- OMNICC EXCLUSION - Helper Function (TAINT-FREE APPROACH)
-- ============================================================================
-- CRITICAL: Instead of hooking metatables (causes taint), we set flags directly
-- on each cooldown frame when we CREATE it. This is 100% taint-free.
--
-- Usage: Replace CreateFrame("Cooldown", ...) with AC:CreateCooldown(...)
-- ============================================================================

function addon:CreateCooldown(parent, name, template)
    -- Create the cooldown frame
    local cooldown = CreateFrame("Cooldown", name, parent, template or "CooldownFrameTemplate")
    
    -- Set OmniCC exclusion flags IMMEDIATELY after creation
    -- These flags tell OmniCC to ignore this cooldown frame
    cooldown.noCooldownCount = true  -- OmniCC flag
    cooldown.noOCC = true             -- OmniCC flag (legacy)
    cooldown.omnicc = {enabled = false} -- OmniCC flag (modern)
    
    return cooldown
end

-- Make it globally accessible
_G.ArenaCore.CreateCooldown = addon.CreateCooldown

-- =========================================================================
-- BETA TESTER DEFAULTS - YOUR EXACT CONFIGURATION
-- =========================================================================
-- Version for tracking first-time installs and migrations
-- CRITICAL: Increment this number to force beta defaults on ALL users (even existing ones)
addon.DEFAULTS_VERSION = 3

-- CRITICAL: This function exports YOUR CURRENT database to use as defaults
-- Run /ac_exportfull in-game to generate this table from your live settings
function addon:GetBetaDefaults()
  -- COMPLETE BETA DEFAULTS - Exported from your live database
  -- ArenaCore Settings Export
  -- Generated: 2025-10-14 13:16:14

  local settings = {
  other = {
    classicBarTextures = false
  },
  blackout = {
    enabled = true,
    -- NEW: Blackout effect customization (Hybrid System)
    effectType = "default",  -- "default", "fire", "ice", "poison", "shadow", "custom"
    customColor = {r = 0, g = 0, b = 0},  -- Custom RGB color (0-1 range)
    useTexture = true,  -- Enable texture overlay on health bar (DEFAULT: CR Protection Plan for new users)
    texturePath = "charactercreate-icon-requiredarrow",  -- CR Protection Plan™ texture (default for new users)
    textureIsAtlas = true,  -- CR Protection Plan is an atlas texture
    textureIsExternal = true,  -- CR Protection Plan is an external indicator (above health bar)
    -- External indicator positioning (for CR Protection Plan and Bigdam Certified)
    externalOffsetX = 0,  -- Horizontal offset (-100 to 100)
    externalOffsetY = 5,  -- Vertical offset (-100 to 100), default 5px above health bar
    externalScale = 100,  -- Scale/size percentage (50-200%) for Bigdam and CR Protection textures
    externalTestMode = false,  -- Test mode for external indicators (shows on all nameplates)
    healthBarTestMode = false,  -- Test mode for health bar textures (shows on all nameplates)
     spells = {
      [1] = 107574,
      [2] = 31884,
      [3] = 190319,
      [4] = 19574,
      [5] = 114050,
      [6] = 114051,
      [7] = 359844,
      [8] = 167105,
      [9] = 231895,
      [10] = 384352,
      [11] = 343721,
      [12] = 12472,
      [13] = 102543,
      [14] = 102560,
      [15] = 123904,
      [16] = 191427,
      [17] = 51271,
      [18] = 10060,
      [19] = 375982,
      [20] = 196770,
      [21] = 121471,
      [22] = 185313,
      [23] = 137639,
      [24] = 207289,
      [25] = 1719,
      [26] = 391109,
      [27] = 228260,
      [28] = 357715,
      [29] = 266779,
      [30] = 378957,
      [31] = 203415,
      [32] = 205180,
      [33] = 205179,
      [34] = 265187,
      [35] = 111898,
      [36] = 267217,
      [37] = 1122,
      [38] = 446285,
      [39] = 288613,
      [40] = 205320,
      [41] = 365350,
      [42] = 257044,
    }
  },
  kickBar = {
    showPlayerNames = false,
    showBackground = false,
    position = {
      y = -245.00012207031,
      x = 1.9998836517334,
      point = "CENTER",
      relativePoint = "CENTER",
      relative = "UIParent"
    }
  },
  textScale = {},
  auras = {
    tribadge = {
      enabled = true,
      autoByEnemyClass = true,
      offsetX = -16,
      spacing = 2,
      anchor = "TOPLEFT",
      offsetY = -2,
      size = 25
    }
  },
  moreGoodies = {
    absorbs = {
      enabled = true,
      opacity = 20
    },
    auras = {
      enabled = true,
      interrupt = true,  -- CRITICAL: Track interrupts (kicks, silences)
      crowdControl = true,
      defensive = true,
      utility = true
    },
    debuffs = {
      enabled = true,
      showTimer = true,
      positioning = {
        vertical = 0,
        horizontal = 55
      },
      sizing = {
        scale = 89
      },
      playerDebuffsOnly = false,
      maxCount = 5,
      timerFontSize = 7
    },
    partyClassSpecs = {
      healerOffsetX = 0,
      scale = 280,
      healerScale = 201,
      pointerOffsetY = -57,
      pointerOffsetX = -3,
      pointerScale = 252,
      offsetY = 26,
      offsetX = -2,
      showPointers = true,
      hideHealthBars = false,
      mode = "all",
      healerOffsetY = 0,
      showHealerIcon = true
    },
    dispels = {
      enabled = true,
      boxWidth = 136,
      size = 28,
      textEnabled = false,
      scale = 139,
      textOffsetX = 0,
      textScale = 77,
      growthDirection = "Vertical",
      showCooldown = true,
      showBackground = false,
      offsetX = -40,
      textOffsetY = -1,
      boxHeight = 48,
      offsetY = -40,
      framePos = {
        y = 114.66694641113,
        x = -55.249111175537,
        point = "RIGHT",
        relativePoint = "RIGHT",
        relative = "UIParent"
      },
      cooldownDuration = 8
    },
    auras = {
      enabled = true,
      crowdControl = true,
      hideTooltips = false,
      defensive = true,  -- CRITICAL: Enable by default for Precognition tracking
      utility = false
    }
  },
  tooltipIDs = {
    enabled = true
  },
  moreFeatures = {
    hideBlizzardArenaFrames = true,
    globalFontOutline = true,
    globalFontEnabled = false,  -- OFF by default for new users
    actionBarFontOnly = false,  -- Action bar font only mode (mutually exclusive with globalFontEnabled)
    surrenderGGEnabled = true
  },
  trinkets = {
    enabled = true,
    iconDesign = "retail",
    positioning = {
      vertical = 11,
      overrides = {},
      horizontal = 69
    },
    sizing = {
      scale = 142,
      fontSize = 10
    }
  },
  theme = {
    primary = {
      [1] = 0.545,
      [2] = 0.271,
      [3] = 1,
      [4] = 1
    },
    text = {
      [1] = 1,
      [2] = 1,
      [3] = 1,
      [4] = 1
    }
  },
  sizing = {
    height = 72,
    scale = 100,
    targetBorderThickness = 2,
    width = 220
  },
  textures = {
    powerBarTexture = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture8.tga",
    sizing = {
      healthHeight = 21,
      healthWidth = 132,
      resourceWidth = 132,
      resourceHeight = 11
    },
    barPosition = {
      horizontal = 56,
      vertical = 15,
      spacing = 2
    },
    castBarTexture = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture8.tga",
    barSizing = {
      healthHeight = 18,
      healthWidth = 128,
      resourceWidth = 136,
      resourceHeight = 8
    },
    positioning = {
      sliderOffsetY = 16,
      horizontal = 56,
      vertical = 16,
      spacing = 1
    },
    useDifferentPowerBarTexture = true,
    healthBarTexture = "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture8.tga",
    useDifferentCastBarTexture = true
  },
  classIcons = {
    enabled = true,
    theme = "arenacore",  -- "arenacore" or "coldclasses"
    showAuras = true,  -- Show CC auras over class icon (Midnight only)
    positioning = {
      vertical = 7,
      overrides = {},
      horizontal = -2
    },
    sizing = {
      scale = 109,
      borderThickness = 100  -- Border thickness: 100% = full border (default), 80% = thinner (shrunk inward)
    }
  },
  castBars = {
    backgroundStyle = "Arena Core",  -- Default cast bar background style
    spellIcons = {
      enabled = true,
      positioning = {
        horizontal = -5,
        vertical = 4
      },
      sizing = {
        scale = 94
      }
    },
    spellSchoolColors = true,
    positioning = {
      vertical = -86,
      sliderOffsetY = -5,
      horizontal = -4,
      sliderOffsetX = -1,
    },
    sizing = {
      height = 24,
      scale = 87,
      width = 220
    }
  },
  dispels = {
    scale = 83,
    offsetX = -22,
    size = 104
  },
  ui = {
    scale = 1,
    fontSize = 12,
    height = 580,
    width = 720
  },
  layout = {
    baseAnchor = {
      y = 0,
      relPoint = "TOP",
      point = "TOP",
      scale = 0.71111112833023,
      relTo = "UIParent",
      x = 109.86669102841
    }
  },
  diminishingReturns = {
    initialized = true,
    customSpellsList = {},
    sizing = {
      fontSize = 18,
      scale = 100,
      stageFontSize = 12,
      borderSize = 0,
      size = 39
    },
    rows = {
      dynamicPositioning = true,
      mode = "Straight"
    },
    classSpecEnabled = false,
    enabled = true,
    positioning = {
      timerFontY = 1,
      growthDirection = "Left",
      vertical = 0,
      spacing = 3,
      stageFontY = 2,
      sliderOffsetX = 115,
      horizontal = -172,
      timerFontX = 0,
      stageFontX = -2
    },
    lastSelectedCategory = "stun",
    classSpecSelection = "",
    iconSettings = {
      stun = "dynamic",
      knockback = "61391",
      incapacitate = "115078",
      disarm = "dynamic"
    },
    customSpells = {},
    categories = {
      incapacitate = true,
      disarm = true,
      banish = true,
      cyclone = true,
      disorient = true,
      root = true,
      knockback = true,
      silence = true,
      stun = true,
      mc = true,
      fear = true
    }
  },
  actionBarFont = {
    scale = 100,
    horizontal = 0,
    vertical = 0
  },
  specIcons = {
    enabled = true,
    positioning = {
      vertical = -14,
      overrides = {},
      sliderOffsetY = -46,
      horizontal = -144,
      sliderOffsetX = -52,
    },
    sizing = {
      scale = 73
    }
  },
  classPortraitSwap = {
    enabled = true,
    useCustomIcons = true  -- When true, uses ArenaCore custom icons; when false, uses theme icons (ColdClasses/etc) - DEFAULT ON
  },
  positioning = {
    vertical = -270,
    spacing = 25,
    horizontal = 166,
    visualCenterAlignment = true,
    growthDirection = "Down"
  },
  classPacks = {
    HUNTER = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 19574,
            [2] = 1
          },
          [2] = {
            [1] = 359844,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 186265,
            [2] = 1
          },
          [2] = {
            [1] = 264735,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 3355,
            [2] = 1
          },
          [2] = {
            [1] = 109248,
            [2] = 2
          },
          [3] = {
            [1] = 213691,
            [2] = 3
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 288613,
            [2] = 1
          },
          [2] = {
            [1] = 257044,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 186265,
            [2] = 1
          },
          [2] = {
            [1] = 264735,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 3355,
            [2] = 1
          },
          [2] = {
            [1] = 109248,
            [2] = 2
          },
          [3] = {
            [1] = 213691,
            [2] = 3
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 360952,
            [2] = 1
          },
          [2] = {
            [1] = 360966,
            [2] = 2
          },
          [3] = {
            [1] = 203415,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 186265,
            [2] = 1
          },
          [2] = {
            [1] = 264735,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 3355,
            [2] = 1
          },
          [2] = {
            [1] = 19577,
            [2] = 2
          },
          [3] = {
            [1] = 190925,
            [2] = 3
          }
        }
      }
    },
    fontSize = 14,
    PALADIN = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 31884,
            [2] = 1
          },
          [2] = {
            [1] = 414170,
            [2] = 2
          },
          [3] = {
            [1] = 210294,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 642,
            [2] = 1
          },
          [2] = {
            [1] = 1022,
            [2] = 2
          },
          [3] = {
            [1] = 31821,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 853,
            [2] = 2
          },
          [2] = {
            [1] = 20066,
            [2] = 1
          },
          [3] = {
            [1] = 6940,
            [2] = 3
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 31884,
            [2] = 1
          }
        },
        [2] = {
          [1] = {
            [1] = 31850,
            [2] = 1
          },
          [2] = {
            [1] = 86659,
            [2] = 2
          },
          [3] = {
            [1] = 642,
            [2] = 1
          }
        },
        [3] = {
          [1] = {
            [1] = 853,
            [2] = 2
          },
          [2] = {
            [1] = 115750,
            [2] = 2
          },
          [3] = {
            [1] = 1044,
            [2] = 1
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 31884,
            [2] = 1
          },
          [2] = {
            [1] = 231895,
            [2] = 2
          },
          [3] = {
            [1] = 343721,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 642,
            [2] = 1
          },
          [2] = {
            [1] = 184662,
            [2] = 2
          },
          [3] = {
            [1] = 1022,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 115750,
            [2] = 2
          },
          [2] = {
            [1] = 20066,
            [2] = 1
          },
          [3] = {
            [1] = 853,
            [2] = 3
          }
        }
      }
    },
    MAGE = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 365350,
            [2] = 1
          },
          [2] = {
            [1] = 321507,
            [2] = 2
          },
          [3] = {
            [1] = 376103,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 45438,
            [2] = 1
          },
          [2] = {
            [1] = 235450,
            [2] = 2
          },
          [3] = {
            [1] = 110959,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 118,
            [2] = 1
          },
          [2] = {
            [1] = 31661,
            [2] = 2
          },
          [3] = {
            [1] = 82691,
            [2] = 2
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 190319,
            [2] = 1
          },
          [2] = {
            [1] = 153561,
            [2] = 2
          },
          [3] = {
            [1] = 257541,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 45438,
            [2] = 1
          },
          [2] = {
            [1] = 235313,
            [2] = 2
          },
          [3] = {
            [1] = 86949,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 118,
            [2] = 1
          },
          [2] = {
            [1] = 82691,
            [2] = 2
          },
          [3] = {
            [1] = 31661,
            [2] = 3
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 12472,
            [2] = 1
          },
          [2] = {
            [1] = 153595,
            [2] = 2
          },
          [3] = {
            [1] = 205021,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 45438,
            [2] = 1
          },
          [2] = {
            [1] = 11426,
            [2] = 2
          },
          [3] = {
            [1] = 235219,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 118,
            [2] = 1
          },
          [2] = {
            [1] = 82691,
            [2] = 2
          },
          [3] = {
            [1] = 31661,
            [2] = 3
          }
        }
      }
    },
    offsetX = -28,
    spacing = 1,
    anchor = "TOPLEFT",
    DRUID = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 102560,
            [2] = 1
          },
          [2] = {
            [1] = 391528,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 22812,
            [2] = 1
          },
          [2] = {
            [1] = 22842,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 33786,
            [2] = 1
          },
          [2] = {
            [1] = 78675,
            [2] = 2
          },
          [3] = {
            [1] = 102793,
            [2] = 3
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 102543,
            [2] = 1
          },
          [2] = {
            [1] = 391528,
            [2] = 3
          },
          [3] = {
            [1] = 106951,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 61336,
            [2] = 1
          },
          [2] = {
            [1] = 22812,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 22570,
            [2] = 1
          },
          [2] = {
            [1] = 5211,
            [2] = 2
          },
          [3] = {
            [1] = 33786,
            [2] = 1
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 102558,
            [2] = 1
          },
          [2] = {
            [1] = 391528,
            [2] = 2
          },
          [3] = {
            [1] = 50334,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 61336,
            [2] = 1
          },
          [2] = {
            [1] = 22812,
            [2] = 2
          },
          [3] = {
            [1] = 22842,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 99,
            [2] = 1
          },
          [2] = {
            [1] = 102793,
            [2] = 2
          },
          [3] = {
            [1] = 106839,
            [2] = 3
          }
        }
      },
      [4] = {
        [1] = {},
        [2] = {},
        [3] = {}
      }
    },
    MONK = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 132578,
            [2] = 1
          },
          [2] = {
            [1] = 387184,
            [2] = 2
          },
          [3] = {
            [1] = 386276,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 115203,
            [2] = 1
          },
          [2] = {
            [1] = 115176,
            [2] = 2
          },
          [3] = {
            [1] = 122278,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 119381,
            [2] = 1
          },
          [2] = {
            [1] = 115078,
            [2] = 2
          },
          [3] = {
            [1] = 116844,
            [2] = 3
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 115310,
            [2] = 1
          },
          [2] = {
            [1] = 116680,
            [2] = 3
          },
          [3] = {
            [1] = 116849,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 115203,
            [2] = 1
          },
          [2] = {
            [1] = 122783,
            [2] = 2
          },
          [3] = {
            [1] = 122278,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 119381,
            [2] = 2
          },
          [2] = {
            [1] = 115078,
            [2] = 1
          },
          [3] = {
            [1] = 116844,
            [2] = 3
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 137639,
            [2] = 1
          },
          [2] = {
            [1] = 123904,
            [2] = 2
          },
          [3] = {
            [1] = 285272,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 122783,
            [2] = 1
          },
          [2] = {
            [1] = 122278,
            [2] = 2
          },
          [3] = {
            [1] = 115203,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 116844,
            [2] = 3
          },
          [2] = {
            [1] = 115078,
            [2] = 1
          },
          [3] = {
            [1] = 119381,
            [2] = 2
          }
        }
      }
    },
    size = 26,
    DEATHKNIGHT = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 47568,
            [2] = 2
          },
          [2] = {
            [1] = 49028,
            [2] = 3
          },
          [3] = {
            [1] = 383269,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 48792,
            [2] = 2
          },
          [2] = {
            [1] = 48707,
            [2] = 1
          },
          [3] = {
            [1] = 55233,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 221562,
            [2] = 1
          },
          [2] = {
            [1] = 108199,
            [2] = 2
          },
          [3] = {
            [1] = 49576,
            [2] = 3
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 47568,
            [2] = 3
          },
          [2] = {
            [1] = 51271,
            [2] = 2
          },
          [3] = {
            [1] = 196770,
            [2] = 1
          }
        },
        [2] = {
          [1] = {
            [1] = 48707,
            [2] = 1
          },
          [2] = {
            [1] = 48792,
            [2] = 2
          },
          [3] = {
            [1] = 51052,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 108194,
            [2] = 2
          },
          [2] = {
            [1] = 207167,
            [2] = 1
          },
          [3] = {
            [1] = 49576,
            [2] = 3
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 207289,
            [2] = 1
          },
          [2] = {
            [1] = 42650,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 48792,
            [2] = 2
          },
          [2] = {
            [1] = 48707,
            [2] = 1
          },
          [3] = {
            [1] = 51052,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 108194,
            [2] = 1
          },
          [2] = {
            [1] = 49576,
            [2] = 2
          }
        }
      }
    },
    PRIEST = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 10060,
            [2] = 1
          },
          [2] = {
            [1] = 421543,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 33206,
            [2] = 1
          },
          [2] = {
            [1] = 62618,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 8122,
            [2] = 2
          },
          [2] = {
            [1] = 605,
            [2] = 1
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 200183,
            [2] = 1
          },
          [2] = {
            [1] = 372616,
            [2] = 4
          },
          [3] = {
            [1] = 64843,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 47788,
            [2] = 1
          },
          [2] = {
            [1] = 64901,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 8122,
            [2] = 2
          },
          [2] = {
            [1] = 88625,
            [2] = 1
          },
          [3] = {
            [1] = 605,
            [2] = 2
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 228260,
            [2] = 1
          },
          [2] = {
            [1] = 10060,
            [2] = 2
          },
          [3] = {
            [1] = 391109,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 47585,
            [2] = 1
          },
          [2] = {
            [1] = 108968,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 15487,
            [2] = 2
          },
          [2] = {
            [1] = 64044,
            [2] = 2
          },
          [3] = {
            [1] = 8122,
            [2] = 1
          }
        }
      }
    },
    enabled = true,
    SHAMAN = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 191634,
            [2] = 2
          },
          [2] = {
            [1] = 375982,
            [2] = 1
          },
          [3] = {
            [1] = 114050,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 108271,
            [2] = 1
          },
          [2] = {
            [1] = 108270,
            [2] = 2
          },
          [3] = {
            [1] = 198103,
            [2] = 4
          }
        },
        [3] = {
          [1] = {
            [1] = 192058,
            [2] = 2
          },
          [2] = {
            [1] = 51514,
            [2] = 1
          },
          [3] = {
            [1] = 204336,
            [2] = 2
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 114051,
            [2] = 1
          },
          [2] = {
            [1] = 51533,
            [2] = 2
          },
          [3] = {
            [1] = 384352,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 108271,
            [2] = 1
          },
          [2] = {
            [1] = 108270,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 51514,
            [2] = 1
          },
          [2] = {
            [1] = 192058,
            [2] = 2
          },
          [3] = {
            [1] = 204336,
            [2] = 2
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 114052,
            [2] = 1
          },
          [2] = {
            [1] = 108280,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 108271,
            [2] = 1
          },
          [2] = {
            [1] = 108270,
            [2] = 2
          },
          [3] = {
            [1] = 98008,
            [2] = 1
          }
        },
        [3] = {
          [1] = {
            [1] = 204336,
            [2] = 1
          },
          [2] = {
            [1] = 192058,
            [2] = 2
          },
          [3] = {
            [1] = 51514,
            [2] = 1
          }
        }
      }
    },
    WARLOCK = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 386997,
            [2] = 2
          },
          [2] = {
            [1] = 205180,
            [2] = 1
          },
          [3] = {
            [1] = 113860,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 104773,
            [2] = 1
          },
          [2] = {
            [1] = 48020,
            [2] = 3
          },
          [3] = {
            [1] = 108416,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 5782,
            [2] = 1
          },
          [2] = {
            [1] = 6789,
            [2] = 2
          },
          [3] = {
            [1] = 30283,
            [2] = 2
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 265187,
            [2] = 1
          },
          [2] = {
            [1] = 111898,
            [2] = 2
          },
          [3] = {
            [1] = 267217,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 104773,
            [2] = 1
          },
          [2] = {
            [1] = 48020,
            [2] = 3
          },
          [3] = {
            [1] = 108416,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 5782,
            [2] = 1
          },
          [2] = {
            [1] = 6789,
            [2] = 2
          },
          [3] = {
            [1] = 89766,
            [2] = 2
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 1122,
            [2] = 2
          },
          [2] = {
            [1] = 80240,
            [2] = 3
          },
          [3] = {
            [1] = 196670,
            [2] = 1
          }
        },
        [2] = {
          [1] = {
            [1] = 104773,
            [2] = 1
          },
          [2] = {
            [1] = 48020,
            [2] = 3
          },
          [3] = {
            [1] = 108416,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 5782,
            [2] = 1
          },
          [2] = {
            [1] = 6789,
            [2] = 2
          },
          [3] = {
            [1] = 30283,
            [2] = 2
          }
        }
      }
    },
    DEMONHUNTER = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 191427,
            [2] = 1
          },
          [2] = {
            [1] = 370965,
            [2] = 2
          },
          [3] = {
            [1] = 258860,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 198589,
            [2] = 1
          },
          [2] = {
            [1] = 196555,
            [2] = 2
          },
          [3] = {
            [1] = 196718,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 217832,
            [2] = 1
          },
          [2] = {
            [1] = 179057,
            [2] = 3
          },
          [3] = {
            [1] = 207684,
            [2] = 2
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 187827,
            [2] = 1
          },
          [2] = {
            [1] = 207407,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 196718,
            [2] = 1
          },
          [2] = {
            [1] = 204021,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 202137,
            [2] = 1
          },
          [2] = {
            [1] = 217832,
            [2] = 3
          },
          [3] = {
            [1] = 207684,
            [2] = 2
          }
        }
      },
      [3] = {
        [1] = {},
        [2] = {},
        [3] = {}
      }
    },
    WARRIOR = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 107574,
            [2] = 1
          },
          [2] = {
            [1] = 167105,
            [2] = 2
          },
          [3] = {
            [1] = 198817,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 118038,
            [2] = 1
          },
          [2] = {
            [1] = 23920,
            [2] = 2
          },
          [3] = {
            [1] = 97462,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 107570,
            [2] = 2
          },
          [2] = {
            [1] = 5246,
            [2] = 2
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 1719,
            [2] = 1
          },
          [2] = {
            [1] = 107574,
            [2] = 2
          },
          [3] = {
            [1] = 385059,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 23920,
            [2] = 2
          },
          [2] = {
            [1] = 97462,
            [2] = 3
          },
          [3] = {
            [1] = 184364,
            [2] = 2
          }
        },
        [3] = {
          [1] = {
            [1] = 5246,
            [2] = 1
          },
          [2] = {
            [1] = 107570,
            [2] = 2
          },
          [3] = {
            [1] = 12323,
            [2] = 3
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 107574,
            [2] = 1
          },
          [2] = {
            [1] = 385952,
            [2] = 2
          },
          [3] = {
            [1] = 376079,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 23920,
            [2] = 1
          },
          [2] = {
            [1] = 12975,
            [2] = 2
          },
          [3] = {
            [1] = 871,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 46968,
            [2] = 2
          },
          [2] = {
            [1] = 107570,
            [2] = 2
          }
        }
      }
    },
    offsetY = 1,
    EVOKER = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 375087,
            [2] = 1
          },
          [2] = {
            [1] = 370553,
            [2] = 2
          },
          [3] = {
            [1] = 357210,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 363916,
            [2] = 1
          },
          [2] = {
            [1] = 374348,
            [2] = 2
          },
          [3] = {
            [1] = 374227,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 360806,
            [2] = 1
          },
          [2] = {
            [1] = 358385,
            [2] = 2
          },
          [3] = {
            [1] = 372048,
            [2] = 3
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 370960,
            [2] = 1
          },
          [2] = {
            [1] = 359816,
            [2] = 2
          },
          [3] = {
            [1] = 370537,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 363916,
            [2] = 1
          },
          [2] = {
            [1] = 363534,
            [2] = 2
          },
          [3] = {
            [1] = 357170,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 360806,
            [2] = 1
          },
          [2] = {
            [1] = 370665,
            [2] = 2
          },
          [3] = {
            [1] = 374968,
            [2] = 3
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 403631,
            [2] = 1
          },
          [2] = {
            [1] = 409311,
            [2] = 2
          },
          [3] = {
            [1] = 370553,
            [2] = 3
          }
        },
        [2] = {
          [1] = {
            [1] = 363916,
            [2] = 1
          },
          [2] = {
            [1] = 374348,
            [2] = 2
          },
          [3] = {
            [1] = 357170,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 360806,
            [2] = 1
          },
          [2] = {
            [1] = 358385,
            [2] = 2
          },
          [3] = {
            [1] = 395152,
            [2] = 3
          }
        }
      }
    },
    ROGUE = {
      [1] = {
        [1] = {
          [1] = {
            [1] = 360194,
            [2] = 1
          },
          [2] = {
            [1] = 385627,
            [2] = 2
          },
          [3] = {
            [1] = 212182,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 31224,
            [2] = 1
          },
          [2] = {
            [1] = 5277,
            [2] = 2
          },
          [3] = {
            [1] = 1856,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 408,
            [2] = 1
          },
          [2] = {
            [1] = 1833,
            [2] = 2
          },
          [3] = {
            [1] = 6770,
            [2] = 3
          }
        }
      },
      [2] = {
        [1] = {
          [1] = {
            [1] = 13750,
            [2] = 1
          },
          [2] = {
            [1] = 51690,
            [2] = 3
          },
          [3] = {
            [1] = 13877,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 31224,
            [2] = 1
          },
          [2] = {
            [1] = 5277,
            [2] = 2
          },
          [3] = {
            [1] = 1856,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 1776,
            [2] = 2
          },
          [2] = {
            [1] = 408,
            [2] = 1
          },
          [3] = {
            [1] = 1833,
            [2] = 3
          }
        }
      },
      [3] = {
        [1] = {
          [1] = {
            [1] = 185313,
            [2] = 1
          },
          [2] = {
            [1] = 212283,
            [2] = 2
          },
          [3] = {
            [1] = 280719,
            [2] = 2
          }
        },
        [2] = {
          [1] = {
            [1] = 31224,
            [2] = 1
          },
          [2] = {
            [1] = 5277,
            [2] = 2
          },
          [3] = {
            [1] = 1856,
            [2] = 3
          }
        },
        [3] = {
          [1] = {
            [1] = 1833,
            [2] = 2
          },
          [2] = {
            [1] = 408,
            [2] = 1
          },
          [3] = {
            [1] = 6770,
            [2] = 3
          }
        }
      }
    }
  },
  racials = {
    enabled = true,
    positioning = {
      vertical = -10,
      overrides = {},
      sliderOffsetY = 6,
      horizontal = 96,
    },
    sizing = {
      scale = 105,
      fontSize = 10
    }
  },
  arenaNameplates = {
    enabled = true,
    mode = "both",  -- "default", "arena", "spec", "both"
    useShortNames = false  -- Use short spec names (Aff, Ret, Sub) vs full names
  },
  arenaFrames = {
    testModeActive = true,
    general = {
      playerNameY = -3,
      resourceTextScale = 83,
      usePercentage = true,
      playerNameX = 50,
      arenaNumberX = 190,
      showNames = true,
      playerNameScale = 106,
      showArenaNumbers = false,
      useClassColors = true,
      spellTextScale = 113,
      showArenaServerNames = false,
      healthTextScale = 100,
      statusText = true,
      arenaNumberY = -3,
      arenaNumberScale = 119
    },
    positioning = {
      growthDirection = "Down",
      vertical = 766,
      spacing = 25,
      sliderOffsetX = 0,
      horizontal = 1358,
      sliderOffsetY = 0,
    },
    sizing = {
      height = 73,
      scale = 123,
      width = 235
    }
  },
  modules = {
    TriBadges = {},
    LegacyBridge = {
      disabled = false
    },
    TrinketsRacials = {}
  }
}

  return settings
end

-- Simple deep-copy utility for tables
local function DeepCopy(tbl)
  if type(tbl) ~= "table" then return tbl end
  local out = {}
  for k, v in pairs(tbl) do out[k] = DeepCopy(v) end
  return out
end

-- Serialize a Lua table (compact) for exporting defaults
local function QuoteStr(s)
  s = tostring(s):gsub("\\", "\\\\"):gsub("\"", "\\\"")
  return '"' .. s .. '"'
end

local function ToLua(o)
  local t = type(o)
  if t == "number" or t == "boolean" then return tostring(o)
  elseif t == "string" then return QuoteStr(o)
  elseif t == "table" then
    local parts = {}
    for k, v in pairs(o) do
      local key
      if type(k) == "string" and k:match("^[_%a][_%w]*$") then
        key = k .. " = "
      else
        key = "[" .. ToLua(k) .. "] = "
      end
      table.insert(parts, key .. ToLua(v))
    end
    return "{" .. table.concat(parts, ", ") .. "}"
  else
    return "nil"
  end
end

-- NEW: Pretty-print Lua table with proper indentation and line breaks
local function ToLuaPretty(o, indent)
  indent = indent or "  "
  local t = type(o)
  
  if t == "number" or t == "boolean" then 
    return tostring(o)
  elseif t == "string" then 
    return QuoteStr(o)
  elseif t == "table" then
    local parts = {}
    local hasContent = false
    
    for k, v in pairs(o) do
      hasContent = true
      local key
      if type(k) == "string" and k:match("^[_%a][_%w]*$") then
        key = k
      else
        key = "[" .. ToLuaPretty(k, indent) .. "]"
      end
      
      local value = ToLuaPretty(v, indent .. "  ")
      table.insert(parts, indent .. key .. " = " .. value)
    end
    
    if not hasContent then
      return "{}"
    end
    
    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent:sub(3) .. "}"
  else
    return "nil"
  end
end

function addon:ExportCurrentAsDefaults()
  local roots = {
    "arenaFrames","trinkets","specIcons","racials","classIcons",
    "castBars","diminishingReturns","blackoutAuras"
  }
  local export = {}
  local profile = _G.ArenaCoreDB and _G.ArenaCoreDB.profile or {}
  for _, key in ipairs(roots) do
    if profile[key] ~= nil then export[key] = DeepCopy(profile[key]) end
  end
  local s = "addon.DEFAULTS = " .. ToLua(export)
  -- Print in chunks to chat
  local maxLen = 230
  for i = 1, #s, maxLen do
    print(string.sub(s, i, i + maxLen - 1))
  end
  -- Also open a copy window for convenience
  if addon.ShowExportWindow then addon:ShowExportWindow(s) end
  return s
end

-- CRITICAL: Export COMPLETE database for beta testers (includes EVERYTHING)
function addon:ExportFullDatabase()
  if not _G.ArenaCoreDB or not _G.ArenaCoreDB.profile then
    print("|cffFF0000ArenaCore:|r No database found to export!")
    return
  end
  
  -- Export profile WITHOUT backups (too large)
  local profile = DeepCopy(_G.ArenaCoreDB.profile)
  
  -- CRITICAL: Remove backups to reduce size
  profile.backups = nil
  
  -- Generate COMPLETE function with proper formatting using pretty-print
  local code = "function addon:GetBetaDefaults()\n"
  code = code .. "  -- COMPLETE BETA DEFAULTS - Exported from your live database\n"
  code = code .. "  -- ArenaCore Settings Export\n"
  code = code .. "  -- Generated: " .. date("%Y-%m-%d %H:%M:%S") .. "\n\n"
  code = code .. "  local settings = " .. ToLuaPretty(profile, "  ") .. "\n\n"
  code = code .. "  return settings\n"
  code = code .. "end"
  
  -- Show in export window
  if addon.ShowExportWindow then 
    addon:ShowExportWindow(code)
  end
  
  print("|cff8B45FFArenaCore:|r Full database exported! Copy from the window.")
  print("|cffFFAA00Instructions:|r")
  print("1. Copy the ENTIRE text from the export window")
  print("2. Replace lines 26-2019 in Init.lua (the entire GetBetaDefaults function)")
  print("3. Save Init.lua and distribute to beta testers")
  print("|cffFFAA00Note:|r Backups excluded to reduce size")
  
  return code
end

-- Slash command: /ac_export defaults
SLASH_ARENA_CORE_EXPORT1 = "/ac_export"
SLASH_ARENA_CORE_EXPORT2 = "/ac_exportfull"
SlashCmdList.ARENA_CORE_EXPORT = function(msg)
  msg = (msg or ""):lower()
  if msg == "defaults" or msg == "def" then
    addon:ExportCurrentAsDefaults()
  elseif msg == "full" or msg == "complete" or msg == "" then
    addon:ExportFullDatabase()
  else
    print("ArenaCore: usage /ac_export full (exports complete database)")
    print("ArenaCore: usage /ac_export defaults (exports partial)")
  end
end

-- Slash command: /ac_restore (restore your exported defaults to current profile)
SLASH_ARENA_CORE_RESTORE1 = "/ac_restore"
SlashCmdList.ARENA_CORE_RESTORE = function()
  if not addon.DEFAULTS then
    print("ArenaCore: No DEFAULTS found. Run /ac_export defaults first.")
    return
  end
  if not _G.ArenaCoreDB or not _G.ArenaCoreDB.profile then
    print("ArenaCore: No profile found.")
    return
  end
  local roots = {"arenaFrames","trinkets","specIcons","racials","classIcons","castBars","diminishingReturns","blackoutAuras"}
  for _, key in ipairs(roots) do
    if addon.DEFAULTS[key] then
      _G.ArenaCoreDB.profile[key] = DeepCopy(addon.DEFAULTS[key])
    end
  end
  print("ArenaCore: Restored profile from DEFAULTS. Reloading UI...")
  ReloadUI()
end

-- Simple export window to make copying easy
function addon:ShowExportWindow(text)
  if self._exportFrame and self._exportFrame:IsShown() then
    self._exportEditBox:SetText(text)
    self._exportEditBox:HighlightText()
    self._exportEditBox:SetFocus()
    return
  end

  local f = CreateFrame("Frame", "ArenaCore_ExportWindow", UIParent, "BackdropTemplate")
  f:SetSize(780, 420)
  f:SetPoint("CENTER")
  f:SetFrameStrata("FULLSCREEN_DIALOG")
  f:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  f:SetBackdropColor(0, 0, 0, 0.9)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText("ArenaCore Defaults Export")

  local instr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  instr:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  instr:SetText("Press Ctrl+A, then Ctrl+C to copy. Paste into Core/Init.lua replacing addon.DEFAULTS = {...}")

  local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 12, -50)
  scroll:SetPoint("BOTTOMRIGHT", -36, 50)

  local edit = CreateFrame("EditBox", nil, scroll)
  edit:SetMultiLine(true)
  edit:SetAutoFocus(true)
  edit:SetFontObject(ChatFontNormal)
  edit:SetWidth(720)
  edit:SetText(text)
  edit:HighlightText()
  scroll:SetScrollChild(edit)

  local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  close:SetSize(100, 24)
  close:SetPoint("BOTTOMRIGHT", -12, 12)
  close:SetText("Close")
  close:SetScript("OnClick", function() f:Hide() end)

  local copy = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  copy:SetSize(100, 24)
  copy:SetPoint("RIGHT", close, "LEFT", -8, 0)
  copy:SetText("Select All")
  copy:SetScript("OnClick", function()
    edit:SetFocus()
    edit:HighlightText()
  end)

  self._exportFrame = f
  self._exportEditBox = edit
  f:Show()
end

-- ============================================================================
-- ADDON EVENT HANDLER
-- ============================================================================
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
  if event == "ADDON_LOADED" and name == addon.AddonName then
    -- STEP 1: Initialize database and settings module
    if not _G.ArenaCoreDB then _G.ArenaCoreDB = {} end
    if not _G.ArenaCoreDB.profile then _G.ArenaCoreDB.profile = {} end
    
    -- CRITICAL: Initialize profile system database structure
    if not _G.ArenaCoreDB.profiles then
        _G.ArenaCoreDB.profiles = {}
    end
    
    if not _G.ArenaCoreDB.profileSettings then
        _G.ArenaCoreDB.profileSettings = {
            currentProfile = "ArenaCore Default",
            maxProfiles = 8
        }
    end
    
    -- CRITICAL: Create default profile if it doesn't exist
    if not _G.ArenaCoreDB.profiles["ArenaCore Default"] then
        -- Deep copy current profile as default
        local function DeepCopyInit(tbl)
            if type(tbl) ~= "table" then return tbl end
            local out = {}
            for k, v in pairs(tbl) do out[k] = DeepCopyInit(v) end
            return out
        end
        _G.ArenaCoreDB.profiles["ArenaCore Default"] = DeepCopyInit(_G.ArenaCoreDB.profile)
    end
    
    -- CRITICAL FIX: Link addon.DB to the global database
    addon.DB = _G.ArenaCoreDB
    
    addon.Settings:Initialize()

    -- STEP 3: Load core modules
    -- Note: TriBadges is loaded via .toc file, no need for dofile

    -- STEP 2: Define and ensure all addon defaults
    local function InitializeDefaults()
        local S = addon.Settings
        
        -- CRITICAL: Set addon.DEFAULTS from beta defaults for blackout spells
        -- Force reload if DEFAULTS exists but is empty or missing blackout data
        if (not addon.DEFAULTS or not addon.DEFAULTS.blackout) and addon.GetBetaDefaults then
            addon.DEFAULTS = addon:GetBetaDefaults()
        end

        -- Arena Frames: General (Updated to user's settings) - FIXED STRUCTURE
        S:EnsureDefault("arenaFrames.general.statusText", true)
        S:EnsureDefault("arenaFrames.general.usePercentage", true)
        S:EnsureDefault("arenaFrames.general.useClassColors", true)
        S:EnsureDefault("arenaFrames.general.showNames", true)
        S:EnsureDefault("arenaFrames.general.showArenaLabels", false)
        S:EnsureDefault("arenaFrames.general.showArenaNumbers", true)
        S:EnsureDefault("arenaFrames.general.enableFrameSortIntegration", false)  -- FrameSort integration (default OFF)
        
        -- CRITICAL FIX: Enforce mutual exclusivity between Show Names and Arena 1/2/3 Names
        -- If both are enabled (from old profile), disable Arena Labels (keep Show Names as default)
        if addon.DB.profile.arenaFrames and addon.DB.profile.arenaFrames.general then
            local general = addon.DB.profile.arenaFrames.general
            if general.showNames and general.showArenaLabels then
                print("|cffFFAA00[ArenaCore]|r Both 'Show Names' and 'Arena 1/2/3 Names' were enabled - disabling Arena Labels")
                general.showArenaLabels = false
            end
        end
        -- REMOVED: playerNameX/Y and arenaNumberX/Y are THEME-SPECIFIC
        -- These values come from theme defaults (GetThe1500SpecialDefaults, GetArenaCoreDefaults)
        -- Setting global defaults here overwrites theme-specific positioning after reload
        -- S:EnsureDefault("arenaFrames.general.playerNameX", 52)
        -- S:EnsureDefault("arenaFrames.general.playerNameY", 0)
        -- S:EnsureDefault("arenaFrames.general.arenaNumberX", 190)
        -- S:EnsureDefault("arenaFrames.general.arenaNumberY", -3)
        S:EnsureDefault("arenaFrames.general.playerNameScale", 86)
        S:EnsureDefault("arenaFrames.general.arenaNumberScale", 119)
        S:EnsureDefault("arenaFrames.general.healthTextScale", 100)
        S:EnsureDefault("arenaFrames.general.resourceTextScale", 83)
        S:EnsureDefault("arenaFrames.general.spellTextScale", 113)

        -- REMOVED: Arena Frames positioning/sizing defaults moved to theme system
        -- These are now loaded from ArenaFrameThemes:GetArenaCoreDefaults() for new users
        -- This ensures the theme system is the SINGLE SOURCE OF TRUTH

        -- REMOVED: Cast Bars, Trinkets, Racials, Spec/Class Icons, DR defaults moved to theme system
        -- These are now loaded from ArenaFrameThemes:GetArenaCoreDefaults() for new users
        -- Only keep truly global settings that don't change between themes:
        
        S:EnsureDefault("trinkets.iconDesign", "retail") -- Global setting (not theme-specific)
        S:EnsureDefault("classIcons.theme", "arenacore") -- Global setting (not theme-specific)
        
        -- UI Features: Resizable UI scale persistence
        S:EnsureDefault("uiScale", 1.0) -- Default UI scale (1.0 = 100%)
        S:EnsureDefault("classPackEditorScale", 1.0) -- Class Pack Editor window scale
        S:EnsureDefault("drSettingsScale", 1.0) -- Detailed DR Settings window scale
        S:EnsureDefault("dispelWindowScale", 1.0) -- Dispel Configuration window scale
        S:EnsureDefault("aurasWindowScale", 1.0) -- Auras Configuration window scale
        S:EnsureDefault("debuffsWindowScale", 1.0) -- Debuffs Configuration window scale
        S:EnsureDefault("kickBarWindowScale", 1.0) -- Kick Bar Settings window scale
        S:EnsureDefault("diminishingReturns.showStageIndicators", true) -- Show stage indicators (1/3, 2/3, 3/3) - default ON
        S:EnsureDefault("diminishingReturns.colorCodedBorders", false) -- Color-code borders by DR stage (green/yellow/red) - default OFF
        S:EnsureDefault("diminishingReturns.spiralAnimation.enabled", true) -- Spiral animation enabled - default ON
        S:EnsureDefault("diminishingReturns.spiralAnimation.opacity", 100) -- Spiral dark overlay opacity (1-100%) - default 100%

        -- More Goodies defaults (Updated to user's settings)
        S:EnsureDefault("moreGoodies.absorbs.enabled", true)
        S:EnsureDefault("moreGoodies.partyClassSpecs.mode", "all") -- "off", "party", "all"
        S:EnsureDefault("moreGoodies.partyClassSpecs.scale", 178)
        S:EnsureDefault("moreGoodies.partyClassSpecs.showHealerIcon", true)
        S:EnsureDefault("moreGoodies.partyClassSpecs.hideHealthBars", false) -- Default OFF
        S:EnsureDefault("moreGoodies.partyClassSpecs.useCustomIcons", true) -- When true, uses ArenaCore custom icons - DEFAULT ON
        S:EnsureDefault("moreGoodies.partyClassSpecs.offsetX", 0) -- 0 = horizontally centered above player
        S:EnsureDefault("moreGoodies.partyClassSpecs.offsetY", 0) -- 0 = default height above player
        S:EnsureDefault("moreGoodies.partyClassSpecs.showPointers", true) -- Default ON
        S:EnsureDefault("moreGoodies.partyClassSpecs.pointerScale", 178) -- Triangle pointer scale
        S:EnsureDefault("moreGoodies.partyClassSpecs.pointerOffsetX", 0) -- 0 = horizontally centered (same as class icon)
        S:EnsureDefault("moreGoodies.partyClassSpecs.pointerOffsetY", 0) -- 0 = default height above class icon
        S:EnsureDefault("moreGoodies.partyClassSpecs.linkHorizontal", false) -- When true, pointer horizontal follows class icon
        S:EnsureDefault("moreGoodies.dispels.enabled", true)
        S:EnsureDefault("moreGoodies.dispels.size", 26)
        S:EnsureDefault("moreGoodies.dispels.offsetX", 419)
        S:EnsureDefault("moreGoodies.dispels.offsetY", -249)
        S:EnsureDefault("moreGoodies.dispels.scale", 136)
        S:EnsureDefault("moreGoodies.dispels.showCooldown", true)
        S:EnsureDefault("moreGoodies.dispels.cooldownDuration", 8)
        S:EnsureDefault("moreGoodies.dispels.showBackground", true) -- Default ON
        S:EnsureDefault("moreGoodies.dispels.growthDirection", "Horizontal") -- NEW: Growth direction for icon layout
        S:EnsureDefault("moreGoodies.auras.enabled", true)
        S:EnsureDefault("moreGoodies.auras.hideTooltips", false) -- Default OFF (tooltips shown)
        S:EnsureDefault("moreGoodies.auras.interrupt", true) -- CRITICAL: Track interrupts (kicks, silences)
        S:EnsureDefault("moreGoodies.auras.crowdControl", true)
        S:EnsureDefault("moreGoodies.auras.defensive", true)
        S:EnsureDefault("moreGoodies.auras.utility", true)
        
        -- NEW FEATURE: Debuff countdown timer settings
        S:EnsureDefault("moreGoodies.debuffs.showTimer", true) -- Enable countdown timers by default
        S:EnsureDefault("moreGoodies.debuffs.timerFontSize", 10) -- Default font size for timers

        
        -- Other modules (Updated to user's settings)
        S:EnsureDefault("blackout.enabled", true)
        -- FIXED: Ensure blackout.spells table exists and preserves user additions
        if not addon.DB.profile.blackout then
            addon.DB.profile.blackout = {}
        end
        if not addon.DB.profile.blackout.spells then
            -- First time: use default spell list
            addon.DB.profile.blackout.spells = addon.DEFAULTS.blackout.spells
        end
        -- Note: User-added spells will persist because we don't overwrite existing table
        
        S:EnsureDefault("tooltipIDs.enabled", true)
        S:EnsureDefault("classPortraitSwap.enabled", true)
        S:EnsureDefault("classPortraitSwap.useCustomIcons", true) -- When true, uses ArenaCore custom icons - DEFAULT ON
        S:EnsureDefault("classPacks.enabled", true)
        S:EnsureDefault("classPacks.fontSize", 10) -- NEW: Font size for countdown timers
        S:EnsureDefault("classPacks.growthDirection", "Vertical") -- NEW: Growth direction for icon layout
        
        -- TARGET HIGHLIGHT: Show outline around targeted arena frame
        S:EnsureDefault("targetHighlight.enabled", true)
        S:EnsureDefault("targetHighlight.color.r", 1)
        S:EnsureDefault("targetHighlight.color.g", 0.4)
        S:EnsureDefault("targetHighlight.color.b", 0)
        S:EnsureDefault("targetHighlight.color.a", 1)
        S:EnsureDefault("targetHighlight.fadeEnabled", true)
        S:EnsureDefault("targetHighlight.fadeDuration", 0.15)
        
        -- ARENA FRAME TOOLTIPS: Show player info on hover
        S:EnsureDefault("arenaTooltips.enabled", true)
        S:EnsureDefault("arenaTooltips.showInCombat", true)
        
		-- NEW FEATURE: Kick Bar (Interrupt tracking)
		S:EnsureDefault("kickBar.enabled", true)
		S:EnsureDefault("kickBar.iconSize", 40)
		S:EnsureDefault("kickBar.spacing", 5)
		S:EnsureDefault("kickBar.scale", 100)
		S:EnsureDefault("kickBar.growthDirection", "RIGHT")
		S:EnsureDefault("kickBar.showCooldown", true)
		S:EnsureDefault("kickBar.showTimerText", true)
		S:EnsureDefault("kickBar.showPlayerNames", true)
		S:EnsureDefault("kickBar.showBackground", false)
        -- Textures (Updated to user's ACTUAL settings from export)
        S:EnsureDefault("textures.powerBarTexture", "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture8.tga")
        S:EnsureDefault("textures.useDifferentPowerBarTexture", true)
        -- Legacy keys (kept for backward compatibility)
        S:EnsureDefault("textures.barPosition.horizontal", 56)
        S:EnsureDefault("textures.barPosition.vertical", 15)
        S:EnsureDefault("textures.barPosition.spacing", 2)
        -- Legacy sizing
        S:EnsureDefault("textures.barSizing.healthWidth", 128)
        S:EnsureDefault("textures.barSizing.healthHeight", 18)
        S:EnsureDefault("textures.barSizing.resourceWidth", 136)
        S:EnsureDefault("textures.barSizing.resourceHeight", 8)
        -- New unified structure keys (preferred)
        S:EnsureDefault("textures.positioning.horizontal", 56)
        S:EnsureDefault("textures.positioning.vertical", 15)
        S:EnsureDefault("textures.positioning.spacing", 2)
        S:EnsureDefault("textures.sizing.healthWidth", 128)
        S:EnsureDefault("textures.sizing.healthHeight", 18)
        S:EnsureDefault("textures.sizing.resourceWidth", 136)
        S:EnsureDefault("textures.sizing.resourceHeight", 8)
        S:EnsureDefault("textures.useDifferentCastBarTexture", true)
        S:EnsureDefault("textures.healthBarTexture", "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture17.tga")
        S:EnsureDefault("textures.castBarTexture", "Interface\\AddOns\\ArenaCore\\Media\\Frametextures\\texture16.tga")

        -- One-time migration from legacy to unified structure if needed
        do
            local profile = _G.ArenaCoreDB and _G.ArenaCoreDB.profile or nil
            if profile and profile.textures then
                local t = profile.textures
                if t.barPosition and not t.positioning then
                    t.positioning = {
                        horizontal = t.barPosition.horizontal or 56,
                        vertical   = t.barPosition.vertical or 15,
                        spacing    = t.barPosition.spacing or 2,
                    }
                end
                if t.barSizing and not t.sizing then
                    t.sizing = {
                        healthWidth    = t.barSizing.healthWidth or 128,
                        healthHeight   = t.barSizing.healthHeight or 18,
                        resourceWidth  = t.barSizing.resourceWidth or 136,
                        resourceHeight = t.barSizing.resourceHeight or 8,
                    }
                end
            end
        end

        -- Announcements (CRITICAL FIX: Chat announcements for interrupts)
        S:EnsureDefault("announcements.interrupts", true) -- Announce when you/teammates interrupt enemies
        S:EnsureDefault("announcements.trinkets", false) -- Announce trinket usage (disabled by default)
        S:EnsureDefault("announcements.racials", false) -- Announce racial usage (disabled by default)
        
        -- Player DR Tracking (NEW)
        S:EnsureDefault("playerDR.enabled", true) -- Enable Player DR tracking
        S:EnsureDefault("playerDR.anchorPoint", "TOPLEFT") -- Anchor point relative to player frame
        S:EnsureDefault("playerDR.offsetX", 5) -- Horizontal offset from player frame
        S:EnsureDefault("playerDR.offsetY", -20) -- Vertical offset from player frame
        S:EnsureDefault("playerDR.iconSize", 18) -- Size of DR icons
        S:EnsureDefault("playerDR.spacing", 22) -- Spacing between DR icons
        S:EnsureDefault("playerDR.maxIcons", 4) -- Maximum simultaneous DR icons to show
        
        -- Layout System: Single Source of Truth (NEW)
        S:EnsureDefault("layout.baseAnchor.point", "TOPLEFT")
        S:EnsureDefault("layout.baseAnchor.relTo", "UIParent")
        S:EnsureDefault("layout.baseAnchor.relPoint", "TOPLEFT")
        S:EnsureDefault("layout.baseAnchor.x", 1239)
        S:EnsureDefault("layout.baseAnchor.y", -308)
        S:EnsureDefault("layout.baseAnchor.scale", 1.21)

        -- Initialize Layout system on first load
        if addon.Layout and addon.Layout.ApplyLayoutFromDB then
            C_Timer.After(0.1, function()
                addon.Layout:ApplyLayoutFromDB()
            end)
        end


        -- Seed only when keys are missing
        local profile = _G.ArenaCoreDB.profile
        local roots = {
          "arenaFrames","trinkets","specIcons","racials","classIcons",
          "castBars","diminishingReturns","blackoutAuras","textures","moreGoodies"
        }
        for _, key in ipairs(roots) do
          if profile[key] == nil and addon.DEFAULTS and addon.DEFAULTS[key] ~= nil then
            profile[key] = DeepCopy(addon.DEFAULTS[key])
          end
        end

    end

    -- Call the initialization function
    InitializeDefaults()

    -- Set up addon database references
    addon.Settings:Initialize()
    addon.db = addon.DB.profile
    
    -- CRITICAL: Also set _G.ArenaCore.DB so that AC.DB works in other files
    _G.ArenaCore.DB = _G.ArenaCoreDB
    
    -- Initialize Profile Manager (In-house system) - EARLY
    if addon.ProfileManager and addon.ProfileManager.Initialize then
        addon.ProfileManager:Initialize()
        -- DEBUG: Profile Manager initialized early
        -- print("|cff22AA44ArenaCore:|r Profile Manager initialized early")
    end
    
    -- Initialize Achievement Unlock System - EARLY (requires DB to be ready)
    if addon.InitializeAchievementUnlockDB then
        addon:InitializeAchievementUnlockDB()
    end
    
    -- Initialize Theme Manager - AFTER DB and Achievement system
    if addon.ThemeManager and addon.ThemeManager.Initialize then
        addon.ThemeManager:Initialize()
    end

    -- DEBUG: Initializing addon
    -- print("|cff22AA44ArenaCore:|r Initializing addon...")

    -- Initialize Frame System - EARLY
    if addon.FrameSystem and addon.FrameSystem.Initialize then
        addon.FrameSystem:Initialize()
        print("|cff22AA44ArenaCore:|r FrameSystem initialized early")
    end

    -- CRITICAL: Check if this is a first-time install
    if not _G.ArenaCoreDB.__version then
      -- First-time install: Apply COMPLETE beta defaults
      _G.ArenaCoreDB.__version = addon.DEFAULTS_VERSION
      _G.ArenaCoreDB.__firstInstall = true
      
      -- CRITICAL: Apply your COMPLETE configuration
      if addon.GetBetaDefaults then
        local betaDefaults = addon:GetBetaDefaults()
        if betaDefaults then
          -- Deep copy ALL your settings to their profile
          local function DeepCopyLocal(tbl)
            if type(tbl) ~= "table" then return tbl end
            local out = {}
            for k, v in pairs(tbl) do out[k] = DeepCopyLocal(v) end
            return out
          end
          
          for key, value in pairs(betaDefaults) do
            _G.ArenaCoreDB.profile[key] = DeepCopyLocal(value)
          end
          
          print(("|cff8B45FFArena Core:|r First-time setup complete! Beta preset applied."))
          print(("|cffFFAA00Note:|r All settings, Blackout spells, debuffs, and features configured!"))
        end
      end
    elseif _G.ArenaCoreDB.__version < addon.DEFAULTS_VERSION then
      -- Migration: Update version number ONLY (do NOT overwrite user settings)
      _G.ArenaCoreDB.__version = addon.DEFAULTS_VERSION
      
      -- DISABLED: Automatic settings overwrite removed to preserve user customizations
      -- Users can manually apply beta defaults with /ac betapreset if they want them
      
      print(("|cff8B45FFArena Core:|r Updated to v%d"):format(addon.DEFAULTS_VERSION))
      print(("|cffFFAA00Note:|r Your settings have been preserved!"))
      print(("|cff00FF00Tip:|r Use /ac betapreset to apply creator's defaults (optional)"))
    end

  elseif event == "PLAYER_LOGOUT" then
    -- Force save on logout
    print("ArenaCore: Forcing SavedVariables write on logout")
  end

  -- Only run initialization after ADDON_LOADED
  if event == "ADDON_LOADED" and name == addon.AddonName then
    -- Validate custom font
    do
      local f = CreateFont("ArenaCore_TMP_FONT_VALIDATE")
      if not f:SetFont(addon.CUSTOM_FONT, 12, "") then
        addon.CUSTOM_FONT = STANDARD_TEXT_FONT
      end
    end
  end

  loader:UnregisterEvent("ADDON_LOADED")
end)

-- New frame to handle the final loaded message
local finalMessageFrame = CreateFrame("Frame")
finalMessageFrame:RegisterEvent("PLAYER_LOGIN")
finalMessageFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1.0, function() -- Delay to ensure it's the last message
            local iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Textures\\aclogo.png"
            local icon = ("|T%s:16:16:0:-2|t"):format(iconPath)  -- offsetY:-2 to align with text baseline
            local msg = ("|cff8B45FFArena Core|r %s v%s loaded. Use |cffffff00/arena|r to open."):format(icon, addon.Version)
            print(msg)
            print("|cff8B45FFArena Core|r Discord - www.AcDiscord.com")
        end)
        
        -- Apply global font if enabled (using new GlobalFont module)
        C_Timer.After(2.0, function()
            if addon.DB and addon.DB.profile and addon.DB.profile.moreFeatures and addon.DB.profile.moreFeatures.globalFontEnabled then
                -- Use the new GlobalFont module
                if addon.GlobalFont then
                    local fontPath = "Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf"
                    local useOutline = addon.DB.profile.moreFeatures.globalFontOutline ~= false
                    local useShadow = addon.DB.profile.moreFeatures.globalFontShadow ~= false
                    local fontFlags = useOutline and "OUTLINE" or ""
                    
                    -- Update module settings
                    addon.GlobalFont:UpdateSettings(fontPath, fontFlags, useShadow)
                    
                    -- Enable the module (this will apply to all fonts)
                    addon.GlobalFont:Enable()
                else
                    print("|cffFF0000[ArenaCore]|r GlobalFont module not loaded!")
                end
            end
        end)
        
        -- Enable Game Menu Button (ESC menu)
        C_Timer.After(0.5, function()
            if addon.GameMenuButton then
                addon.GameMenuButton:Enable()
            end
        end)
        
        -- ============================================================================
        -- OLD GLOBAL FONT CODE REMOVED - Now using modules/GlobalFont.lua
        -- ============================================================================
        -- The old font system (256 lines) has been completely removed to prevent
        -- duplicate functionality and confusion. All global font features are now
        -- handled by the modular GlobalFont.lua system which uses metatable hooking
        -- and preserves original font flags for quest/achievement text.
        -- ============================================================================
        
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

