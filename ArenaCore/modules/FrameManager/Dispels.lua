local AC = _G.ArenaCore or {}

local Dispels = {}

--[[
    Dispel tracking module for ArenaCore. Handles live cooldown tracking,
    container lifecycle, and layout refresh logic for dispel indicators.
]]

local function GetSettings()
    return AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.dispels
end

local function EnsureContainer(frame)
    -- DISABLED: This is the old duplicate dispel system
    -- The new DispelTracker.lua system is the active one
    -- Keeping this disabled to prevent duplicate dispel icons
    return nil
    
    --[[
    if frame.dispelContainer then
        return frame.dispelContainer
    end

    local settings = GetSettings() or {}
    local iconSize = settings.size or 26

    local container = CreateFrame("Frame", nil, frame)
    container:SetSize(iconSize, iconSize)
    container:SetFrameStrata("MEDIUM")
    container:SetFrameLevel(60)

    -- CRITICAL FIX: Use proper positioning settings (match test mode positioning)
    local horizontal = (settings.positioning and settings.positioning.horizontal) or 5
    local vertical = (settings.positioning and settings.positioning.vertical) or 0
    
    -- Position to the right of the arena frame (like trinkets/racials)
    container:ClearAllPoints()
    container:SetPoint("LEFT", frame, "RIGHT", horizontal, vertical)

    container:Hide()
    frame.dispelContainer = container
    return container
    ]]--
end

local function EnsureIcon(frame)
    -- DISABLED: Old duplicate dispel system
    return nil
    
    --[[
    if frame.dispelIcon then
        return frame.dispelIcon
    end

    local container = EnsureContainer(frame)
    if not container then return nil end -- Safety check
    local settings = GetSettings() or {}
    local iconSize = settings.size or 26

    local iconFrame = CreateFrame("Frame", nil, container)
    iconFrame:SetSize(iconSize, iconSize)
    iconFrame:SetPoint("LEFT", container, "LEFT", 0, 0)
    iconFrame:SetFrameStrata("MEDIUM")
    iconFrame:SetFrameLevel(61)

    -- Icon texture with proper cropping
    local texture = iconFrame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- CRITICAL: Override SetTexture to apply TRILINEAR filtering for smooth scaling
    -- This prevents pixelation when dispel icons are scaled up beyond base size
    texture.SetTexture = function(self, tex, ...)
        getmetatable(self).__index.SetTexture(self, tex, true, true)
    end

    -- CRITICAL FIX: Apply ArenaCore's custom black border styling (same as test mode)
    if AC and AC.StyleIcon then
        AC:StyleIcon(texture, iconFrame, true)
    end

    -- Cooldown spiral (using helper to block OmniCC)
    local cooldown = AC:CreateCooldown(iconFrame, nil, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(true)

    iconFrame.texture = texture
    iconFrame.cooldown = cooldown

    frame.dispelIcon = iconFrame
    return iconFrame
    ]]--
end

function Dispels:EnsureFrame(frame)
    EnsureContainer(frame)
    EnsureIcon(frame)
end

function Dispels:Update(frame)
    local container = EnsureContainer(frame)
    
    -- CRITICAL: Old dispel system is disabled, return early
    if not container then
        return
    end
    
    local settings = GetSettings()

    if not settings or not settings.enabled then
        container:Hide()
        if frame.dispelIcon then
            frame.dispelIcon:Hide()
        end
        return
    end

    -- CRITICAL FIX: Hide dispels in prep room (only show in real arena)
    local _, instanceType = IsInInstance()
    local inPrepRoom = false
    if instanceType == "arena" then
        local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs()
        if numOpponents and numOpponents > 0 then
            -- In prep room - hide dispels
            inPrepRoom = true
        end
    end
    
    if inPrepRoom then
        container:Hide()
        if frame.dispelIcon then
            frame.dispelIcon:Hide()
        end
        return
    end

    container:Show()
    if frame.dispelIcon then
        frame.dispelIcon:Show()
    end
end

function Dispels:TrackCooldown(frame, spellID, duration)
    -- CRITICAL: Old dispel system is disabled, return early
    return
    
    --[[
    local settings = GetSettings()
    if not settings or not settings.enabled then
        return
    end

    local iconFrame = EnsureIcon(frame)
    if not iconFrame then
        return -- Old system disabled
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo and spellInfo.iconID then
        iconFrame.texture:SetTexture(spellInfo.iconID)
    end

    iconFrame.cooldown:SetCooldown(GetTime(), duration)
    iconFrame:Show()
    iconFrame:GetParent():Show()
    ]]--
end

function Dispels:Hide(frame)
    if frame.dispelContainer then
        frame.dispelContainer:Hide()
    end
    if frame.dispelIcon then
        frame.dispelIcon:Hide()
    end
end

AC.MasterFrameManager = AC.MasterFrameManager or {}
AC.MasterFrameManager.Dispels = Dispels

return Dispels
