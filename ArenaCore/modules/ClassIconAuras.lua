-- ============================================================================
-- File: ArenaCore/modules/ClassIconAuras.lua
-- Purpose: Display CC/important auras over class portraits in Midnight
-- Hooks into Blizzard's DebuffFrame to mirror aura display to class icon
-- ============================================================================

local AC = _G.ArenaCore
if not AC then return end

-- Only works in Midnight (TWW+)
if not (AC.Midnight and AC.Midnight.isMidnight) then return end

local ClassIconAuras = {}
AC.ClassIconAuras = ClassIconAuras

local MAX_ARENA_ENEMIES = 3

-- State tracking
ClassIconAuras.initialized = false
ClassIconAuras.hookedFrames = {}

-- ============================================================================
-- CORE FUNCTIONALITY
-- ============================================================================

-- Storage for original class textures (stored as string paths, not secret values)
ClassIconAuras.originalTextures = {}

-- Hook a single arena frame's DebuffFrame to mirror to class icon
function ClassIconAuras:HookDebuffFrame(arenaIndex)
    if self.hookedFrames[arenaIndex] then return end
    
    local blizzArenaFrame = _G["CompactArenaFrameMember" .. arenaIndex]
    if not blizzArenaFrame then return end
    
    local debuffFrame = blizzArenaFrame.DebuffFrame
    if not debuffFrame then return end
    
    -- Get ArenaCore frame
    local MFM = AC.MasterFrameManager
    local acFrame = MFM and MFM.frames and MFM.frames[arenaIndex]
    if not acFrame then return end
    
    -- Get class icon reference
    local classIcon = acFrame.classIcon
    if not classIcon then return end
    
    -- Create cooldown frame for aura display if not exists
    if not classIcon.auraCooldown then
        classIcon.auraCooldown = CreateFrame("Cooldown", nil, classIcon, "CooldownFrameTemplate")
        classIcon.auraCooldown:SetAllPoints(classIcon.icon or classIcon)
        classIcon.auraCooldown:SetDrawEdge(true)
        classIcon.auraCooldown:SetDrawSwipe(true)
        classIcon.auraCooldown:SetHideCountdownNumbers(false)
        classIcon.auraCooldown:SetSwipeColor(0, 0, 0, 0.6)
    end
    
    -- Restore class icon to stored original texture
    -- CRITICAL: Do NOT call UpdateClassIcon - it re-detects class incorrectly in Midnight
    local function RestoreClassIcon()
        local stored = ClassIconAuras.originalTextures[arenaIndex]
        if stored and classIcon.icon then
            classIcon.icon:SetTexture(stored.iconPath)
            if classIcon.overlay and stored.overlayPath then
                classIcon.overlay:SetTexture(stored.overlayPath)
            end
        end
        if classIcon.auraCooldown then
            classIcon.auraCooldown:Clear()
        end
        classIcon._showingAura = false
    end
    
    -- Store the current class texture before showing aura
    local function StoreOriginalTexture()
        -- Only store if we have a valid class texture (string path, not secret value)
        -- Build path from acFrame's stored class data
        local unit = acFrame.unit
        if not unit then return end
        
        -- Get class from the frame's stored data or from GetArenaOpponentSpec
        local classFile = nil
        local specID = GetArenaOpponentSpec(arenaIndex)
        if specID and specID > 0 then
            local _, _, _, _, _, class = GetSpecializationInfoByID(specID)
            classFile = class
        end
        
        if not classFile then return end
        
        -- Build texture paths based on theme setting
        local db = AC.DB and AC.DB.profile
        local theme = db and db.classIcons and db.classIcons.theme or "arenacore"
        
        local iconPath, overlayPath
        if theme == "coldclasses" then
            iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\ColdClasses\\" .. classFile:lower() .. ".png"
        else
            iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\" .. classFile .. ".tga"
        end
        overlayPath = "Interface\\AddOns\\ArenaCore\\Media\\Classicons\\Overlays\\" .. classFile:lower() .. "overlay.tga"
        
        ClassIconAuras.originalTextures[arenaIndex] = {
            iconPath = iconPath,
            overlayPath = overlayPath,
            classFile = classFile
        }
    end
    
    -- Check if auras on class icon are disabled (showAuras defaults to true)
    local function IsDisabled()
        local db = AC.DB and AC.DB.profile
        -- If showAuras is explicitly set to false, disable auras
        return db and db.classIcons and db.classIcons.showAuras == false
    end
    
    -- Hook DebuffFrame.Icon:SetTexture to mirror aura texture to class icon
    -- CRITICAL: tex is a secret value - pass directly to SetTexture (no pcall, no comparisons)
    if debuffFrame.Icon then
        hooksecurefunc(debuffFrame.Icon, "SetTexture", function(_, tex)
            if IsDisabled() then
                RestoreClassIcon()
                return
            end
            
            -- Check if this is the question mark texture (no aura)
            -- Direct comparison works for string paths, silently fails for secret values
            if tex == "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK.BLP" then
                RestoreClassIcon()
                return
            end
            
            -- Store original texture before showing aura (if not already stored)
            if not classIcon._showingAura then
                StoreOriginalTexture()
            end
            
            -- Show aura texture on class icon
            -- Pass tex directly - SetTexture accepts secret values natively
            if classIcon.icon then
                classIcon.icon:SetTexture(tex)
                classIcon._showingAura = true
            end
        end)
    end
    
    -- Hook DebuffFrame.Cooldown:SetCooldown to mirror cooldown to class icon
    -- CRITICAL: start and duration are secret values - pass directly (no pcall)
    if debuffFrame.Cooldown then
        hooksecurefunc(debuffFrame.Cooldown, "SetCooldown", function(_, start, duration)
            if IsDisabled() then return end
            
            -- Pass values directly - SetCooldown accepts secret values natively
            if classIcon.auraCooldown then
                classIcon.auraCooldown:SetCooldown(start, duration)
            end
        end)
    end
    
    self.hookedFrames[arenaIndex] = true
end

-- Initialize hooks for all arena frames
function ClassIconAuras:Initialize()
    if self.initialized then return end
    
    -- Hook existing frames
    for i = 1, MAX_ARENA_ENEMIES do
        self:HookDebuffFrame(i)
    end
    
    self.initialized = true
end

-- Refresh hooks (called when entering arena)
function ClassIconAuras:RefreshHooks()
    for i = 1, MAX_ARENA_ENEMIES do
        self:HookDebuffFrame(i)
    end
end

-- Restore all class icons to original textures
function ClassIconAuras:RestoreAll()
    local MFM = AC.MasterFrameManager
    if not MFM or not MFM.frames then return end
    
    for i = 1, MAX_ARENA_ENEMIES do
        local acFrame = MFM.frames[i]
        if acFrame and acFrame.classIcon then
            local classIcon = acFrame.classIcon
            -- Use stored textures to restore (NOT UpdateClassIcon which re-detects incorrectly)
            local stored = self.originalTextures[i]
            if stored and classIcon.icon then
                classIcon.icon:SetTexture(stored.iconPath)
                if classIcon.overlay and stored.overlayPath then
                    classIcon.overlay:SetTexture(stored.overlayPath)
                end
            end
            if classIcon.auraCooldown then
                classIcon.auraCooldown:Clear()
            end
            classIcon._showingAura = false
        end
    end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local _, instanceType = IsInInstance()
    
    if event == "PLAYER_ENTERING_WORLD" then
        if instanceType == "arena" then
            -- Delay to ensure Blizzard frames are created
            C_Timer.After(0.5, function()
                ClassIconAuras:RefreshHooks()
            end)
        else
            -- Leaving arena - restore class icons
            ClassIconAuras:RestoreAll()
        end
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" or event == "ARENA_OPPONENT_UPDATE" then
        -- Ensure hooks are set up
        C_Timer.After(0.1, function()
            ClassIconAuras:RefreshHooks()
        end)
    end
end)

-- Initialize after a short delay to ensure AC.Midnight is loaded
C_Timer.After(0.5, function()
    if AC.Midnight and AC.Midnight.isMidnight then
        ClassIconAuras:Initialize()
    end
end)
