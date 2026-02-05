-- =============================================================
-- File: modules/Auras/ClassPacksAuras.lua (ENHANCED WITH PRIORITY SUPPORT)
-- Purpose: Data library for default TriBadge spell lists with priority system.
-- =============================================================

local AC = _G.ArenaCore
if not AC then return end

-- Priority levels (lower number = higher priority = checked first)
AC.SPELL_PRIORITIES = {
  WATCH_FOR_THIS = 1,    -- "WATCH FOR THIS I CARE THE MOST"
  REALLY_CARE = 2,       -- "Really Care"
  KINDA_CARE = 3,        -- "Kinda Care"
  DONT_CARE = 4          -- "Don't Care For It But Have It Anyway"
}

-- Priority labels for UI
AC.PRIORITY_LABELS = {
  [1] = "WATCH FOR THIS I CARE THE MOST",
  [2] = "Really Care",
  [3] = "Kinda Care", 
  [4] = "Don't Care For It But Have It Anyway"
}

-- Spec information for each class
AC.CLASS_SPECS = {
  WARRIOR = {
    [1] = {name = "Arms", icon = 132355},
    [2] = {name = "Fury", icon = 132347},
    [3] = {name = "Protection", icon = 132341}
  },
  PALADIN = {
    [1] = {name = "Holy", icon = 135920},
    [2] = {name = "Protection", icon = 236264},
    [3] = {name = "Retribution", icon = 135873}
  },
  HUNTER = {
    [1] = {name = "Beast Mastery", icon = 461112},
    [2] = {name = "Marksmanship", icon = 236179},
    [3] = {name = "Survival", icon = 461113}
  },
  ROGUE = {
    [1] = {name = "Assassination", icon = 236270},
    [2] = {name = "Outlaw", icon = 236286},
    [3] = {name = "Subtlety", icon = 132320}
  },
  PRIEST = {
    [1] = {name = "Discipline", icon = 135940},
    [2] = {name = "Holy", icon = 237542},
    [3] = {name = "Shadow", icon = 136207}
  },
  DEATHKNIGHT = {
    [1] = {name = "Blood", icon = 135770},
    [2] = {name = "Frost", icon = 135773},
    [3] = {name = "Unholy", icon = 135775}
  },
  SHAMAN = {
    [1] = {name = "Elemental", icon = 136048},
    [2] = {name = "Enhancement", icon = 237581},
    [3] = {name = "Restoration", icon = 136052}
  },
  MAGE = {
    [1] = {name = "Arcane", icon = 135932},
    [2] = {name = "Fire", icon = 135810},
    [3] = {name = "Frost", icon = 135846}
  },
  WARLOCK = {
    [1] = {name = "Affliction", icon = 136145},
    [2] = {name = "Demonology", icon = 136172},
    [3] = {name = "Destruction", icon = 136186}
  },
  MONK = {
    [1] = {name = "Brewmaster", icon = 608951},
    [2] = {name = "Mistweaver", icon = 608952},
    [3] = {name = "Windwalker", icon = 608953}
  },
  DRUID = {
    [1] = {name = "Balance", icon = 136096},
    [2] = {name = "Feral", icon = 132115},
    [3] = {name = "Guardian", icon = 132276},
    [4] = {name = "Restoration", icon = 136041}
  },
  DEMONHUNTER = {
    [1] = {name = "Havoc", icon = 1247262},
    [2] = {name = "Vengeance", icon = 1247263}
  },
  EVOKER = {
    [1] = {name = "Devastation", icon = nil, specID = 1467}, -- Will be populated dynamically
    [2] = {name = "Preservation", icon = nil, specID = 1468}, -- Will be populated dynamically
    [3] = {name = "Augmentation", icon = nil, specID = 1473}  -- Will be populated dynamically
  }
}

-- Function to populate Evoker spec icons dynamically using Blizzard API
local function PopulateEvokerSpecIcons()
    if AC.CLASS_SPECS and AC.CLASS_SPECS.EVOKER then
        -- Fallback icons in case API fails
        local fallbackIcons = {
            [1467] = 135808, -- Fire icon for Devastation
            [1468] = 136041, -- Nature icon for Preservation
            [1473] = 5198700 -- Augmentation (already set)
        }
        
        for specIndex, specData in pairs(AC.CLASS_SPECS.EVOKER) do
            if specData.specID then
                local specID, name, description, icon = GetSpecializationInfoByID(specData.specID)
                if icon then
                    specData.icon = icon
                else
                    -- Use fallback icon
                    specData.icon = fallbackIcons[specData.specID] or 134400 -- Default question mark
                end
            end
        end
    end
end

-- Populate Evoker spec icons when the addon loads
C_Timer.After(1, PopulateEvokerSpecIcons)

-- Enhanced data structure: now spec-based with each spell as {spellID, priority}
-- Structure: ClassPacks[CLASS][SPEC][SLOT] = {{spellID, priority}, ...}
-- DEFAULT DATA: Comprehensive spell configurations for all classes and specs
local ClassPacks = {
  WARRIOR = {
    [1] = { -- Arms
      [1] = { {107574, 1}, {167105, 2}, {198817, 2} }, -- Burst
      [2] = { {118038, 1}, {23920, 2}, {97462, 3} },   -- Defensives
      [3] = { {107570, 2}, {5246, 2} }                  -- Control
    },
    [2] = { -- Fury
      [1] = { {1719, 1}, {107574, 2}, {385059, 3} },   -- Burst
      [2] = { {23920, 2}, {97462, 3}, {184364, 2} },   -- Defensives
      [3] = { {5246, 1}, {107570, 2}, {12323, 3} }     -- Control
    },
    [3] = { -- Protection
      [1] = { {107574, 1}, {385952, 2}, {376079, 3} }, -- Burst
      [2] = { {23920, 1}, {12975, 2}, {871, 3} },      -- Defensives
      [3] = { {46968, 2}, {107570, 2} }                 -- Control
    }
  },
  PALADIN = {
    [1] = { -- Holy
      [1] = { {31884, 1}, {414170, 2}, {210294, 3} },  -- Burst
      [2] = { {642, 1}, {1022, 2}, {31821, 3} },       -- Defensives
      [3] = { {853, 2}, {20066, 1}, {6940, 3} }        -- Control
    },
    [2] = { -- Protection
      [1] = { {31884, 1} },                             -- Burst
      [2] = { {31850, 1}, {86659, 2}, {642, 1} },      -- Defensives
      [3] = { {853, 2}, {115750, 2}, {1044, 1} }       -- Control
    },
    [3] = { -- Retribution
      [1] = { {31884, 1}, {231895, 2}, {343721, 2} },  -- Burst
      [2] = { {642, 1}, {184662, 2}, {1022, 3} },      -- Defensives
      [3] = { {115750, 2}, {20066, 1}, {853, 3} }      -- Control
    }
  },
  HUNTER = {
    [1] = { -- Beast Mastery
      [1] = { {19574, 1}, {359844, 2} },               -- Burst
      [2] = { {186265, 1}, {264735, 2} },              -- Defensives
      [3] = { {3355, 1}, {109248, 2}, {213691, 3} }   -- Control
    },
    [2] = { -- Marksmanship
      [1] = { {288613, 1}, {257044, 2} },              -- Burst
      [2] = { {186265, 1}, {264735, 2} },              -- Defensives
      [3] = { {3355, 1}, {109248, 2}, {213691, 3} }   -- Control
    },
    [3] = { -- Survival
      [1] = { {360952, 1}, {360966, 2}, {203415, 3} }, -- Burst
      [2] = { {186265, 1}, {264735, 2} },              -- Defensives
      [3] = { {3355, 1}, {19577, 2}, {190925, 3} }    -- Control
    }
  },
  ROGUE = {
    [1] = { -- Assassination
      [1] = { {360194, 1}, {385627, 2}, {212182, 2} }, -- Burst
      [2] = { {31224, 1}, {5277, 2}, {1856, 3} },      -- Defensives
      [3] = { {408, 1}, {1833, 2}, {6770, 3} }         -- Control
    },
    [2] = { -- Outlaw
      [1] = { {13750, 1}, {51690, 3}, {13877, 2} },    -- Burst
      [2] = { {31224, 1}, {5277, 2}, {1856, 3} },      -- Defensives
      [3] = { {1776, 2}, {408, 1}, {1833, 3} }         -- Control
    },
    [3] = { -- Subtlety
      [1] = { {185313, 1}, {212283, 2}, {280719, 2} }, -- Burst
      [2] = { {31224, 1}, {5277, 2}, {1856, 3} },      -- Defensives
      [3] = { {1833, 2}, {408, 1}, {6770, 3} }         -- Control
    }
  },
  PRIEST = {
    [1] = { -- Discipline
      [1] = { {10060, 1}, {421543, 2} },               -- Burst
      [2] = { {33206, 1}, {62618, 2} },                -- Defensives
      [3] = { {8122, 2}, {605, 1} }                    -- Control
    },
    [2] = { -- Holy
      [1] = { {200183, 1}, {372616, 4}, {64843, 2} },  -- Burst
      [2] = { {47788, 1}, {64901, 3} },                -- Defensives
      [3] = { {8122, 2}, {88625, 1}, {605, 2} }        -- Control
    },
    [3] = { -- Shadow
      [1] = { {228260, 1}, {10060, 2}, {391109, 3} },  -- Burst
      [2] = { {47585, 1}, {108968, 2} },               -- Defensives
      [3] = { {15487, 2}, {64044, 2}, {8122, 1} }      -- Control
    }
  },
  DEATHKNIGHT = {
    [1] = { -- Blood
      [1] = { {47568, 2}, {49028, 3}, {383269, 2} },   -- Burst
      [2] = { {48792, 2}, {48707, 1}, {55233, 3} },    -- Defensives
      [3] = { {221562, 1}, {108199, 2}, {49576, 3} }   -- Control
    },
    [2] = { -- Frost
      [1] = { {47568, 3}, {51271, 2}, {196770, 1} },   -- Burst
      [2] = { {48707, 1}, {48792, 2}, {51052, 3} },    -- Defensives
      [3] = { {108194, 2}, {207167, 1}, {49576, 3} }   -- Control
    },
    [3] = { -- Unholy
      [1] = { {207289, 1}, {42650, 2} },               -- Burst
      [2] = { {48792, 2}, {48707, 1}, {51052, 3} },    -- Defensives
      [3] = { {108194, 1}, {49576, 2} }                -- Control
    }
  },
  SHAMAN = {
    [1] = { -- Elemental
      [1] = { {191634, 2}, {375982, 1}, {114050, 2} }, -- Burst
      [2] = { {108271, 1}, {108270, 2}, {198103, 4} }, -- Defensives
      [3] = { {192058, 2}, {51514, 1}, {204336, 2} }   -- Control
    },
    [2] = { -- Enhancement
      [1] = { {114051, 1}, {51533, 2}, {384352, 2} },  -- Burst
      [2] = { {108271, 1}, {108270, 2} },              -- Defensives
      [3] = { {51514, 1}, {192058, 2}, {204336, 2} }   -- Control
    },
    [3] = { -- Restoration
      [1] = { {114052, 1}, {108280, 2} },              -- Burst
      [2] = { {108271, 1}, {108270, 2}, {98008, 1} },  -- Defensives
      [3] = { {204336, 1}, {192058, 2}, {51514, 1} }   -- Control
    }
  },
  MAGE = {
    [1] = { -- Arcane
      [1] = { {365350, 1}, {321507, 2}, {376103, 3} }, -- Burst
      [2] = { {45438, 1}, {235450, 2}, {110959, 3} },  -- Defensives
      [3] = { {118, 1}, {31661, 2}, {82691, 2} }       -- Control
    },
    [2] = { -- Fire
      [1] = { {190319, 1}, {153561, 2}, {257541, 3} }, -- Burst
      [2] = { {45438, 1}, {235313, 2}, {86949, 3} },   -- Defensives
      [3] = { {118, 1}, {82691, 2}, {31661, 3} }       -- Control
    },
    [3] = { -- Frost
      [1] = { {12472, 1}, {153595, 2}, {205021, 3} },  -- Burst
      [2] = { {45438, 1}, {11426, 2}, {235219, 3} },   -- Defensives
      [3] = { {118, 1}, {82691, 2}, {31661, 3} }       -- Control
    }
  },
  WARLOCK = {
    [1] = { -- Affliction
      [1] = { {386997, 2}, {205180, 1}, {113860, 3} }, -- Burst
      [2] = { {104773, 1}, {48020, 3}, {108416, 2} },  -- Defensives
      [3] = { {5782, 1}, {6789, 2}, {30283, 2} }       -- Control
    },
    [2] = { -- Demonology
      [1] = { {265187, 1}, {111898, 2}, {267217, 3} }, -- Burst
      [2] = { {104773, 1}, {48020, 3}, {108416, 2} },  -- Defensives
      [3] = { {5782, 1}, {6789, 2}, {89766, 2} }       -- Control
    },
    [3] = { -- Destruction
      [1] = { {1122, 2}, {80240, 3}, {196670, 1} },    -- Burst
      [2] = { {104773, 1}, {48020, 3}, {108416, 2} },  -- Defensives
      [3] = { {5782, 1}, {6789, 2}, {30283, 2} }       -- Control
    }
  },
  MONK = {
    [1] = { -- Brewmaster
      [1] = { {132578, 1}, {387184, 2}, {386276, 3} }, -- Burst
      [2] = { {115203, 1}, {115176, 2}, {122278, 3} }, -- Defensives
      [3] = { {119381, 1}, {115078, 2}, {116844, 3} }  -- Control
    },
    [2] = { -- Mistweaver
      [1] = { {115310, 1}, {116680, 3}, {116849, 2} }, -- Burst
      [2] = { {115203, 1}, {122783, 2}, {122278, 3} }, -- Defensives
      [3] = { {119381, 2}, {115078, 1}, {116844, 3} }  -- Control
    },
    [3] = { -- Windwalker
      [1] = { {137639, 1}, {123904, 2}, {285272, 2} }, -- Burst
      [2] = { {122783, 1}, {122278, 2}, {115203, 2} }, -- Defensives
      [3] = { {116844, 3}, {115078, 1}, {119381, 2} }  -- Control
    }
  },
  DRUID = {
    [1] = { -- Balance
      [1] = { {102560, 1}, {391528, 2} },              -- Burst
      [2] = { {22812, 1}, {22842, 2} },                -- Defensives
      [3] = { {33786, 1}, {78675, 2}, {102793, 3} }   -- Control
    },
    [2] = { -- Feral
      [1] = { {102543, 1}, {391528, 3}, {106951, 2} }, -- Burst
      [2] = { {61336, 1}, {22812, 2} },                -- Defensives
      [3] = { {22570, 1}, {5211, 2}, {33786, 1} }     -- Control
    },
    [3] = { -- Guardian
      [1] = { {102558, 1}, {391528, 2}, {50334, 3} },  -- Burst
      [2] = { {61336, 1}, {22812, 2}, {22842, 3} },    -- Defensives
      [3] = { {99, 1}, {102793, 2}, {106839, 3} }      -- Control
    },
    [4] = { -- Restoration
      [1] = {},                                         -- Burst
      [2] = {},                                         -- Defensives
      [3] = {}                                          -- Control
    }
  },
  DEMONHUNTER = {
    [1] = { -- Havoc
      [1] = { {191427, 1}, {370965, 2}, {258860, 3} }, -- Burst
      [2] = { {198589, 1}, {196555, 2}, {196718, 3} }, -- Defensives
      [3] = { {217832, 1}, {179057, 3}, {207684, 2} }  -- Control
    },
    [2] = { -- Vengeance
      [1] = { {187827, 1}, {207407, 2} },              -- Burst
      [2] = { {196718, 1}, {204021, 2} },              -- Defensives
      [3] = { {202137, 1}, {217832, 3}, {207684, 2} }  -- Control
    }
  },
  EVOKER = {
    [1] = { -- Devastation
      [1] = { {375087, 1}, {370553, 2}, {357210, 3} }, -- Burst
      [2] = { {363916, 1}, {374348, 2}, {374227, 3} }, -- Defensives
      [3] = { {360806, 1}, {358385, 2}, {372048, 3} }  -- Control
    },
    [2] = { -- Preservation
      [1] = { {370960, 1}, {359816, 2}, {370537, 3} }, -- Burst
      [2] = { {363916, 1}, {363534, 2}, {357170, 3} }, -- Defensives
      [3] = { {360806, 1}, {370665, 2}, {374968, 3} }  -- Control
    },
    [3] = { -- Augmentation
      [1] = { {403631, 1}, {409311, 2}, {370553, 3} }, -- Burst
      [2] = { {363916, 1}, {374348, 2}, {357170, 3} }, -- Defensives
      [3] = { {360806, 1}, {358385, 2}, {395152, 3} }  -- Control
    }
  }
}

-- Migration flag to prevent infinite loops
AC._migrationInProgress = false

-- Helper function to get sorted spell list by priority (now spec-aware with migration support)
function AC:GetSortedSpellsForSlot(className, slot, specIndex)
  specIndex = specIndex or 1 -- Default to first spec if not specified
  
  -- First check if we have spec-based data
  if self.ClassPacks and self.ClassPacks[className] and self.ClassPacks[className][specIndex] and self.ClassPacks[className][specIndex][slot] then
    local spells = {}
    for _, spellData in ipairs(self.ClassPacks[className][specIndex][slot]) do
      -- Handle both old and new data formats with validation
      if type(spellData) == "table" and spellData[1] then
        -- New format: {spellID, priority} - validate both fields
        local spellID = type(spellData[1]) == "number" and spellData[1] or nil
        local priority = type(spellData[2]) == "number" and spellData[2] or 4
        
        if spellID then
          table.insert(spells, {
            spellID = spellID,
            priority = priority
          })
        else
        end
      elseif type(spellData) == "number" then
        -- Old format: just spellID number
        table.insert(spells, {
          spellID = spellData,
          priority = 4  -- Default priority for migrated data
        })
      else
      end
    end
    
    -- Sort by priority (lower number = higher priority) with safety checks
    table.sort(spells, function(a, b) 
      local aPriority = type(a.priority) == "number" and a.priority or 4
      local bPriority = type(b.priority) == "number" and b.priority or 4
      return aPriority < bPriority 
    end)
    return spells
  end
  
  -- Fallback: check for old non-spec data and migrate it (with loop protection)
  if not self._migrationInProgress and self.ClassPacks and self.ClassPacks[className] and self.ClassPacks[className][slot] and type(self.ClassPacks[className][slot]) == "table" then
    self._migrationInProgress = true
    
    
    -- Migrate old data to new spec-based format
    local oldData = self.ClassPacks[className]
    self.ClassPacks[className] = {}
    self.ClassPacks[className][1] = {[1] = {}, [2] = {}, [3] = {}} -- Create first spec
    
    -- Copy old data to first spec
    for oldSlot = 1, 3 do
      if oldData[oldSlot] then
        self.ClassPacks[className][1][oldSlot] = {}
        for _, spellData in ipairs(oldData[oldSlot]) do
          if type(spellData) == "table" then
            table.insert(self.ClassPacks[className][1][oldSlot], {spellData[1], spellData[2] or 4})
          else
            table.insert(self.ClassPacks[className][1][oldSlot], {spellData, 4})
          end
        end
      end
    end
    
    -- Save migrated data
    self:SaveClassPacksToDatabase()
    
    self._migrationInProgress = false -- Reset flag
    
    -- Now return the migrated data for the requested slot (direct access, no recursion)
    local spells = {}
    if self.ClassPacks[className] and self.ClassPacks[className][specIndex] and self.ClassPacks[className][specIndex][slot] then
      for _, spellData in ipairs(self.ClassPacks[className][specIndex][slot]) do
        if type(spellData) == "table" and spellData[1] then
          local spellID = type(spellData[1]) == "number" and spellData[1] or nil
          local priority = type(spellData[2]) == "number" and spellData[2] or 4
          if spellID then
            table.insert(spells, { spellID = spellID, priority = priority })
          end
        elseif type(spellData) == "number" then
          table.insert(spells, { spellID = spellData, priority = 4 })
        end
      end
      table.sort(spells, function(a, b) 
        local aPriority = type(a.priority) == "number" and a.priority or 4
        local bPriority = type(b.priority) == "number" and b.priority or 4
        return aPriority < bPriority 
      end)
    end
    return spells
  end
  
  return {}
end

-- Helper function to remove a spell from a class/slot (now spec-aware with migration support)
function AC:RemoveSpellFromPack(className, slot, spellID, specIndex)
  specIndex = specIndex or 1 -- Default to first spec if not specified
  
  if not self.ClassPacks or not self.ClassPacks[className] or not self.ClassPacks[className][specIndex] or not self.ClassPacks[className][specIndex][slot] then
    return false
  end
  
  local spellList = self.ClassPacks[className][specIndex][slot]
  for i = #spellList, 1, -1 do
    local currentSpellID
    
    -- Handle both old and new data formats
    if type(spellList[i]) == "table" then
      -- New format: {spellID, priority}
      currentSpellID = spellList[i][1]
    else
      -- Old format: just spellID number
      currentSpellID = spellList[i]
    end
    
    if currentSpellID == spellID then
      table.remove(spellList, i)
      local specName = self.CLASS_SPECS[className] and self.CLASS_SPECS[className][specIndex] and self.CLASS_SPECS[className][specIndex].name or "Spec " .. specIndex
      
      -- CRITICAL: Save to persistent database immediately
      self:SaveClassPacksToDatabase()
      
      return true
    end
  end
  
  return false
end

-- Helper function to add a spell to a class/slot (now spec-aware)
function AC:AddSpellToPack(className, slot, spellID, priority, specIndex)
  specIndex = specIndex or 1 -- Default to first spec if not specified
  
  if not self.ClassPacks then
    self.ClassPacks = {}
  end
  if not self.ClassPacks[className] then
    self.ClassPacks[className] = {}
  end
  if not self.ClassPacks[className][specIndex] then
    self.ClassPacks[className][specIndex] = {[1] = {}, [2] = {}, [3] = {}}
  end
  if not self.ClassPacks[className][specIndex][slot] then
    self.ClassPacks[className][specIndex][slot] = {}
  end
  
  local spellList = self.ClassPacks[className][specIndex][slot]
  
  -- Check if spell already exists
  for _, spellData in ipairs(spellList) do
    if spellData[1] == spellID then
      return false, "Spell already exists in this slot"
    end
  end
  
  -- Check total spell count for this spec (max 9 total per spec)
  local totalSpells = 0
  for i = 1, 3 do
    totalSpells = totalSpells + #(self.ClassPacks[className][specIndex][i] or {})
  end
  
  if totalSpells >= 9 then
    return false, "Maximum 9 spells per spec reached"
  end
  
  -- Check slot count (max 3 per slot)
  if #spellList >= 3 then
    return false, "Maximum 3 spells per slot reached"
  end
  
  -- Add the spell
  table.insert(spellList, {spellID, priority or 4})
  
  local specName = self.CLASS_SPECS[className] and self.CLASS_SPECS[className][specIndex] and self.CLASS_SPECS[className][specIndex].name or "Spec " .. specIndex
  
  -- CRITICAL: Also save to persistent database immediately
  self:SaveClassPacksToDatabase()
  
  return true, "Spell added successfully to " .. className .. " (" .. specName .. ")"
end

-- Helper function to update spell priority (now spec-aware with migration support)
function AC:UpdateSpellPriority(className, slot, spellID, newPriority, specIndex)
  specIndex = specIndex or 1 -- Default to first spec if not specified
  
  if not self.ClassPacks or not self.ClassPacks[className] or not self.ClassPacks[className][specIndex] or not self.ClassPacks[className][specIndex][slot] then
    return false
  end
  
  local spellList = self.ClassPacks[className][specIndex][slot]
  for i, spellData in ipairs(spellList) do
    local currentSpellID
    
    -- Handle both old and new data formats
    if type(spellData) == "table" then
      -- New format: {spellID, priority}
      currentSpellID = spellData[1]
    else
      -- Old format: just spellID number - convert it
      currentSpellID = spellData
      spellList[i] = {spellData, 4} -- Convert to new format with default priority
      spellData = spellList[i] -- Update reference
    end
    
    if currentSpellID == spellID then
      spellData[2] = newPriority
      local specName = self.CLASS_SPECS[className] and self.CLASS_SPECS[className][specIndex] and self.CLASS_SPECS[className][specIndex].name or "Spec " .. specIndex
      
      -- CRITICAL: Save to persistent database immediately
      self:SaveClassPacksToDatabase()
      
      return true
    end
  end
  
  return false
end

-- Helper function to save ClassPacks to persistent database (now spec-aware with migration support)
function AC:SaveClassPacksToDatabase()
  -- Ensure database structure exists
  self.DB = self.DB or {}
  self.DB.profile = self.DB.profile or {}
  self.DB.profile.classPacks = self.DB.profile.classPacks or {}
  
  -- Deep copy current ClassPacks to database
  for className, classData in pairs(self.ClassPacks or {}) do
    self.DB.profile.classPacks[className] = self.DB.profile.classPacks[className] or {}
    for specIndex, specData in pairs(classData) do
      if type(specData) == "table" then
        self.DB.profile.classPacks[className][specIndex] = self.DB.profile.classPacks[className][specIndex] or {}
        for slot = 1, 3 do
          if specData[slot] then
            self.DB.profile.classPacks[className][specIndex][slot] = {}
            for i, spellData in ipairs(specData[slot]) do
              -- Handle both old and new data formats during save
              if type(spellData) == "table" then
                -- New format: {spellID, priority}
                table.insert(self.DB.profile.classPacks[className][specIndex][slot], {spellData[1], spellData[2]})
              else
                -- Old format: just spellID number - convert and save as new format
                table.insert(self.DB.profile.classPacks[className][specIndex][slot], {spellData, 4})
                -- Also update the in-memory data to prevent future issues
                specData[slot][i] = {spellData, 4}
              end
            end
          end
        end
      end
    end
  end
  
end

-- Helper function to fully migrate and clean up data format
function AC:MigrateClassPacksData()
  if not self.ClassPacks or self._migrationInProgress then return end
  
  self._migrationInProgress = true
  
  local migrationCount = 0
  
  for className, classData in pairs(self.ClassPacks) do
    if type(classData) == "table" then
      -- Check if this is old format (direct slot access) or new format (spec-based)
      if classData[1] and not classData[1][1] then
        -- This looks like old format: classData[slot] instead of classData[spec][slot]
        
        local oldData = {}
        for slot = 1, 3 do
          if classData[slot] then
            oldData[slot] = classData[slot]
          end
        end
        
        -- Replace with new spec-based structure
        self.ClassPacks[className] = {}
        self.ClassPacks[className][1] = {[1] = {}, [2] = {}, [3] = {}} -- Create first spec
        
        -- Migrate old data to first spec
        for slot = 1, 3 do
          if oldData[slot] then
            for _, spellData in ipairs(oldData[slot]) do
              if type(spellData) == "table" then
                table.insert(self.ClassPacks[className][1][slot], {spellData[1], spellData[2] or 4})
              else
                table.insert(self.ClassPacks[className][1][slot], {spellData, 4})
              end
            end
          end
        end
        
        migrationCount = migrationCount + 1
      else
        -- This is new format, but check for any remaining number-only spells
        for specIndex, specData in pairs(classData) do
          if type(specData) == "table" then
            for slot = 1, 3 do
              if specData[slot] then
                for i, spellData in ipairs(specData[slot]) do
                  if type(spellData) == "number" then
                    -- Convert number to {spellID, priority} format
                    specData[slot][i] = {spellData, 4}
                    migrationCount = migrationCount + 1
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  
  if migrationCount > 0 then
    self:SaveClassPacksToDatabase()
  end
  
  self._migrationInProgress = false
end

-- MEMORY FIX: Don't duplicate ClassPacks in memory!
-- The local ClassPacks table above has ~500 entries of default data
-- Copying it to AC.ClassPacks doubles memory usage (500 entries × 2 = 1000 entries!)
-- Instead, we'll load defaults into the database ONCE, then reference the database
-- This cuts ClassPacks memory usage in HALF!

-- Initialize database with defaults if empty
if AC.DB and AC.DB.profile then
    AC.DB.profile.classPacks = AC.DB.profile.classPacks or {}
    
    -- Only copy defaults if database is empty (first time setup)
    local isEmpty = true
    for _ in pairs(AC.DB.profile.classPacks) do
        isEmpty = false
        break
    end
    
    if isEmpty then
        -- First time: copy defaults to database
        for className, classData in pairs(ClassPacks) do
            AC.DB.profile.classPacks[className] = classData
        end
    end
end

-- AC.ClassPacks now references the database (not a separate copy!)
-- This saves ~15-20MB of memory!
AC.ClassPacks = AC.DB and AC.DB.profile and AC.DB.profile.classPacks or {}

-- Helper function to clean corrupted data
function AC:CleanCorruptedClassPacksData()
  if not self.ClassPacks or self._migrationInProgress then return end
  
  self._migrationInProgress = true
  
  local cleanupCount = 0
  
  for className, classData in pairs(self.ClassPacks) do
    if type(classData) == "table" then
      for specIndex, specData in pairs(classData) do
        if type(specData) == "table" then
          for slot = 1, 3 do
            if specData[slot] then
              -- Clean up corrupted entries
              for i = #specData[slot], 1, -1 do
                local spellData = specData[slot][i]
                local isCorrupted = false
                
                if type(spellData) == "table" then
                  -- Check if spellID is valid
                  if type(spellData[1]) ~= "number" then
                    isCorrupted = true
                  end
                  -- Check if priority is valid (should be number 1-4)
                  if spellData[2] and (type(spellData[2]) ~= "number" or spellData[2] < 1 or spellData[2] > 4) then
                    isCorrupted = true
                  end
                elseif type(spellData) ~= "number" then
                  isCorrupted = true
                end
                
                if isCorrupted then
                  print("|cff8B45FFArenaCore:|r [CLEANUP] Removing corrupted data from " .. className .. " spec " .. specIndex .. " slot " .. slot)
                  table.remove(specData[slot], i)
                  cleanupCount = cleanupCount + 1
                end
              end
            end
          end
        end
      end
    end
  end
  
  if cleanupCount > 0 then
    print("|cff8B45FFArenaCore:|r [CLEANUP] Removed " .. cleanupCount .. " corrupted data entries")
    self:SaveClassPacksToDatabase()
  end
  
  self._migrationInProgress = false
end

-- Auto-migrate and clean data when the addon loads
C_Timer.After(1, function()
  if AC and AC.MigrateClassPacksData then
    AC:MigrateClassPacksData()
  end
  if AC and AC.CleanCorruptedClassPacksData then
    AC:CleanCorruptedClassPacksData()
  end
end)
