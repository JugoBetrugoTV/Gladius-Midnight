-- COMPLETE AND CORRECTED Auras.lua
-- =============================================================
-- File: modules/Auras/Auras.lua (v2.1 - API & LOGIC FIX)
-- =============================================================

local AC = _G.ArenaCore
if not AC then return end

-- Safe database initialization
local function InitializeAuraDatabase()
  if not AC.db and AC.DB and AC.DB.profile then
    AC.db = AC.DB.profile
  end
  
  AC.db = AC.db or {}
  AC.db.auras = AC.db.auras or {}
  AC.db.auras.tribadge = AC.db.auras.tribadge or {
    enabled = true,
    size = 18,
    spacing = 2,
    anchor = "TOPLEFT",
    offsetX = -20,
    offsetY = -2,
  }
end

function AC._AuraTriDB()
  InitializeAuraDatabase()
  local db = AC.db and AC.db.auras and AC.db.auras.tribadge
  if db then
    -- Force enable for testing
    db.enabled = true
    -- Database found and force-enabled
  else
    -- Database not found!
  end
  return db
end

function AC:PickTriBadge(unit, slot)
  if not unit or not slot then return nil end

  local db = AC._AuraTriDB()
  if not db then 
    -- Database not initialized!
    return nil 
  end
  if not db.enabled then 
    -- System disabled in settings
    return nil 
  end
  if not AC.ClassPacks then return nil end

  local _, classToken = UnitClass(unit)
  if not classToken or not AC.ClassPacks[classToken] then return nil end
  
  -- CRITICAL FIX: Get the enemy's spec for spec-based ClassPacks structure
  local arenaIndex = tonumber(unit:match("arena(%d)"))
  local specID = arenaIndex and GetArenaOpponentSpec(arenaIndex)
  -- Unit " .. unit .. " arenaIndex=" .. (arenaIndex or "nil") .. " specID=" .. (specID or "nil")
  
  -- Convert specID to spec index (1, 2, or 3)
  local specIndex = 1 -- Default to spec 1 if we can't determine
  if specID and specID > 0 then
    -- Get spec info and match it to class specs
    local _, specName, _, specIcon, _, specClass = GetSpecializationInfoByID(specID)
    -- SpecID " .. specID .. " = " .. (specName or "nil") .. " (" .. (specClass or "nil") .. ")"
    if specClass == classToken and AC.CLASS_SPECS and AC.CLASS_SPECS[classToken] then
      for i, specData in pairs(AC.CLASS_SPECS[classToken]) do
        -- Checking spec " .. i .. ": " .. (specData.name or "nil")
        if specData.name == specName then
          specIndex = i
          -- MATCHED spec index " .. i
          break
        end
      end
    else
      -- Class mismatch or missing CLASS_SPECS: " .. (specClass or "nil") .. " vs " .. classToken
    end
  else
    -- No valid specID, using default spec index 1
  end
  
  -- Access spec-based ClassPacks structure: ClassPacks[CLASS][SPEC][SLOT]
  -- Looking for ClassPacks[" .. classToken .. "][" .. specIndex .. "][" .. slot .. "]
  local specData = AC.ClassPacks[classToken][specIndex]
  if not specData then 
    -- No spec data for " .. classToken .. " spec " .. specIndex
    return nil 
  end
  
  local spellList = specData[slot]
  if not spellList then 
    -- No spell list for slot " .. slot
    return nil 
  end

  -- CRITICAL FIX: Handle new {spellID, priority} format and use modern AuraUtil API
  -- Checking " .. #spellList .. " spells for " .. unit .. " slot " .. slot
  for _, spellData in ipairs(spellList) do
    local spellID = type(spellData) == "table" and spellData[1] or spellData
    -- Checking spell " .. spellID .. " on " .. unit
    
    local aura = AuraUtil.FindAuraBySpellId(unit, spellID, "HARMFUL") -- Check for debuffs
    if not aura then
      aura = AuraUtil.FindAuraBySpellId(unit, spellID, "HELPFUL") -- Then check for buffs
    end

    if aura then
      -- Found aura on unit
      return {
        name = aura.name,
        icon = aura.icon,
        duration = aura.duration,
        expirationTime = aura.expirationTime,
        spellId = aura.spellId,
        applications = aura.applications,
        priority = type(spellData) == "table" and spellData[2] or 1, -- Include priority
      }
    else
      print("|cffFFAA00TriBadges:|r No aura found for spell " .. spellID)
    end
  end

  return nil
end

function AC:ApplyClassPack(packKey, options)
  packKey = (packKey or ""):upper()
  print("|cff8B45FFArenaCore:|r Applied settings for |cffFFFFFF"..packKey)
  
  if AC.Auras and AC.Auras.RefreshAll then
    AC.Auras.RefreshAll()
  end
end

function AC:ResetTriBadgeSettings()
    local db = AC._AuraTriDB()
    if not db then return end

    db.size = 18
    db.spacing = 2
    db.offsetX = -20
    db.offsetY = -2

    if AC.Auras and AC.Auras.RefreshAll then
        AC.Auras.RefreshAll()
    end

    if AC.RefreshConfigUI then
        AC:RefreshConfigUI()
    end

    print("|cff8B45FFArenaCore:|r Tri-Badge settings have been reset to default.")
end