local AC = _G.ArenaCore or {}

local Debuffs = {}

--[[
    Debuff tracking module for ArenaCore FrameManager.
    Handles live arena aura updates, test mode previews, and layout refreshes.
    Exposes helper APIs consumed via AC.MasterFrameManager.Debuffs.
]]

local function GetFrameManager()
    AC.MasterFrameManager = AC.MasterFrameManager or {}
    return AC.MasterFrameManager
end

local function GetFrames()
    local manager = GetFrameManager()
    if manager and manager.GetFrames then
        return manager:GetFrames()
    end
    return {}
end

local function GetDebuffSettings()
    return AC.DB and AC.DB.profile and AC.DB.profile.moreGoodies and AC.DB.profile.moreGoodies.debuffs
end

function Debuffs:EnsureContainer(parent)
    if parent.debuffContainer then
        return parent.debuffContainer
    end

    -- Read position from database immediately (prevents jump on reload)
    local settings = GetDebuffSettings()
    local horizontal = settings and settings.positioning and settings.positioning.horizontal or 8
    local vertical = settings and settings.positioning and settings.positioning.vertical or 6

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(220, 24)
    container:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", horizontal, vertical)
    container.debuffs = {}
    container.testDebuffsActive = false
    parent.debuffContainer = container
    return container
end

local function EnsureDebuffContainer(parent)
    return Debuffs:EnsureContainer(parent)
end

local function TrimTexture(texture)
    if texture and texture.SetTexCoord then
        texture:SetTexCoord(0.002, 0.998, 0.002, 0.998)
    end
end

local TEST_DEBUFFS = {
    {spellID = 589, icon = "Interface\\Icons\\spell_shadow_shadowwordpain", count = 1, duration = 18},
    {spellID = 30108, icon = "Interface\\Icons\\spell_shadow_unstableaffliction_3", count = 1, duration = 12},
    {spellID = 191587, icon = "Interface\\Icons\\spell_shadow_plaguecloud", count = 1, duration = 8},
    {spellID = 703, icon = "Interface\\Icons\\ability_rogue_garrote", count = 1, duration = 15},
    {spellID = 164812, icon = "Interface\\Icons\\spell_nature_starfall", count = 2, duration = 10},
    {spellID = 20271, icon = "Interface\\Icons\\spell_holy_righteousfury", count = 1, duration = 6},
    {spellID = 772, icon = "Interface\\Icons\\ability_gouge", count = 1, duration = 12},
    {spellID = 1715, icon = "Interface\\Icons\\ability_shockwave", count = 1, duration = 8},
}

local function ConfigureTimer(frame, duration)
    local castStart = GetTime()
    local expiration = castStart + duration

    local function UpdateText()
        if not AC.testModeEnabled or not frame or not frame.timer then
            return
        end

        local remaining = expiration - GetTime()
        if remaining > 0 then
            local minutes = math.floor(remaining / 60)
            local seconds = math.floor(remaining % 60)
            local text = minutes > 0 and string.format("%d:%02d", minutes, seconds) or string.format("%.0f", remaining)
            frame.timer:SetText(text)
            frame.timerUpdate = C_Timer.NewTimer(0.1, UpdateText)
        else
            frame.timer:SetText("")
            if frame.timerUpdate then
                frame.timerUpdate:Cancel()
                frame.timerUpdate = nil
            end
            C_Timer.After(0.5, function()
                if AC.testModeEnabled and frame and frame:IsVisible() then
                    ConfigureTimer(frame, duration)
                end
            end)
        end
    end

    frame.cooldown:SetCooldown(castStart, duration)
    UpdateText()
end

local function AcquireDebuffFrame(container, index, scale)
    container.debuffs = container.debuffs or {}

    if container.debuffs[index] then
        return container.debuffs[index]
    end

    local frameSize = 20 * scale
    local iconSize = 16 * scale
    local spacing = 23 * scale

    local debuffFrame = CreateFrame("Frame", nil, container)
    debuffFrame:SetSize(frameSize, frameSize)
    debuffFrame:SetPoint("LEFT", (index - 1) * spacing, 0)
    debuffFrame:SetFrameStrata("MEDIUM")
    debuffFrame:SetFrameLevel(30)

    local background = debuffFrame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetTexture(1, 1, 1, 1)
    background:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    if AC.CreateFlatTexture then
        local border = AC:CreateFlatTexture(debuffFrame, "BORDER", 1, {0, 0, 0, 1}, 1)
        border:SetAllPoints()

        local inner = AC:CreateFlatTexture(debuffFrame, "BACKGROUND", 2, {0.15, 0.15, 0.15, 1}, 1)
        inner:SetPoint("TOPLEFT", 1, -1)
        inner:SetPoint("BOTTOMRIGHT", -1, 1)
    end

    local icon = debuffFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(iconSize, iconSize)
    icon:SetPoint("CENTER")
    TrimTexture(icon)
    
    -- CRITICAL: Override SetTexture to apply TRILINEAR filtering for smooth scaling
    -- This prevents pixelation when debuff icons are scaled up beyond base size
    icon.SetTexture = function(self, texture, ...)
        getmetatable(self).__index.SetTexture(self, texture, true, true)
    end

    local stack = debuffFrame:CreateFontString(nil, "OVERLAY")
    stack:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", math.max(6, 7 * scale), "OUTLINE")
    stack:SetPoint("BOTTOMRIGHT", 2, -2)
    stack:SetTextColor(1, 1, 1, 1)

    -- Create cooldown frame (using helper to block OmniCC)
    local cooldown = AC:CreateCooldown(debuffFrame, nil, "CooldownFrameTemplate")
    cooldown:SetAllPoints(debuffFrame)
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetDrawEdge(false)
    cooldown.noCooldownCount = true
    cooldown:SetSwipeColor(0, 0, 0, 0.3)

    local timerFontSize = 10
    local settings = GetDebuffSettings()
    if settings and settings.timerFontSize then
        timerFontSize = settings.timerFontSize
    end

    local timer = cooldown:CreateFontString(nil, "OVERLAY")
    timer:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", timerFontSize, "OUTLINE")
    timer:SetPoint("CENTER", cooldown, "CENTER", 0, 0)
    timer:SetTextColor(1, 1, 1, 1)
    cooldown.Text = timer

    debuffFrame.icon = icon
    debuffFrame.stack = stack
    debuffFrame.cooldown = cooldown
    debuffFrame.timer = timer

    container.debuffs[index] = debuffFrame
    return debuffFrame
end

---Update live arena debuffs on the supplied frame.
function Debuffs:Update(frame, unit)
    -- Midnight compatibility: Disable debuff tracking in Midnight due to API restrictions
    if AC.Midnight and AC.Midnight.isMidnight then
        if not self.disabledWarningShown then
            print("|cffFF0000[Debuffs]|r Disabled in Midnight due to API restrictions")
            self.disabledWarningShown = true
        end
        return
    end
    
    if AC.testModeEnabled then return end
    if not frame then return end

    local container = EnsureDebuffContainer(frame)
    if not container then return end
    
    local settings = GetDebuffSettings()
    if not settings or not settings.enabled then
        container:Hide()
        return
    end

    local maxCount = settings.maxCount or 6
    local scale = (settings.sizing and settings.sizing.scale or 100) / 100
    -- CRITICAL FIX: Get playerDebuffsOnly setting
    local playerDebuffsOnly = settings.playerDebuffsOnly or false

    for i = 1, #container.debuffs do
        if container.debuffs[i] then
            container.debuffs[i]:SetAlpha(0)
            container.debuffs[i]:Hide()
        end
    end

    local debuffMap = {}

    for index = 1, 40 do
        local auraData = C_UnitAuras.GetDebuffDataByIndex(unit, index)
        if not auraData then
            break
        end

        local spellID = auraData.spellId
        local sourceUnit = auraData.sourceUnit
        
        -- FILTER OUT DAMPENING (spell ID 110310)
        if spellID == 110310 then
            -- Skip Dampening debuff entirely
        -- CRITICAL FIX: Filter out non-player debuffs when playerDebuffsOnly is enabled
        elseif playerDebuffsOnly and sourceUnit ~= "player" then
            -- Skip debuffs not created by the player
        elseif auraData.name then
            if not debuffMap[spellID] then
                debuffMap[spellID] = {
                    name = auraData.name,
                    icon = auraData.icon,
                    count = auraData.applications or 1,
                    duration = auraData.duration,
                    expirationTime = auraData.expirationTime,
                    auraInstanceID = auraData.auraInstanceID,  -- TOOLTIP FIX: Store auraInstanceID for Blizzard tooltip system
                }
            else
                debuffMap[spellID].count = debuffMap[spellID].count + 1
            end
        end
    end

    local debuffArray = {}
    for _, data in pairs(debuffMap) do
        table.insert(debuffArray, data)
    end

    local shown = 0
    for _, data in ipairs(debuffArray) do
        if shown >= maxCount then
            break
        end

        shown = shown + 1
        local debuffFrame = AcquireDebuffFrame(container, shown, scale)
        debuffFrame:SetAlpha(1)
        debuffFrame:Show()
        debuffFrame.icon:SetTexture(data.icon)
        debuffFrame.auraInstanceID = data.auraInstanceID  -- TOOLTIP FIX: Set auraInstanceID for Blizzard tooltip system
        debuffFrame.unit = unit  -- TOOLTIP FIX: Store unit token for tooltip queries

        if data.count and data.count > 1 then
            debuffFrame.stack:SetText(data.count)
            debuffFrame.stack:Show()
        else
            debuffFrame.stack:Hide()
        end

        if data.duration and data.duration > 0 and data.expirationTime then
            local remaining = data.expirationTime - GetTime()
            if remaining > 0 then
                debuffFrame.cooldown:SetCooldown(GetTime() - (data.duration - remaining), data.duration)
                debuffFrame.timer:SetText(math.floor(remaining))
            else
                debuffFrame.cooldown:Clear()
                debuffFrame.timer:SetText("")
            end
        else
            debuffFrame.cooldown:Clear()
            debuffFrame.timer:SetText("")
        end
    end

    container:SetShown(shown > 0)
end

---Apply static debuffs for test mode visualization.
function Debuffs:ApplyTestDebuffs(frame, testClass)
    local container = EnsureDebuffContainer(frame)
    local settings = GetDebuffSettings()

    if container.testDebuffsActive then return end

    if not settings or not settings.enabled then
        container:Hide()
        container.testDebuffsActive = false
        return
    end

    local maxCount = settings.maxCount or 6
    local scale = (settings.sizing and settings.sizing.scale or 100) / 100

    for i = 1, #container.debuffs do
        if container.debuffs[i] then
            container.debuffs[i]:SetAlpha(0)
            container.debuffs[i]:Hide()
        end
    end

    container:Show()

    local count = math.min(#TEST_DEBUFFS, maxCount)
    for index = 1, count do
        local data = TEST_DEBUFFS[index]
        local debuffFrame = AcquireDebuffFrame(container, index, scale)
        debuffFrame:SetAlpha(1)
        debuffFrame:Show()
        debuffFrame.icon:SetTexture(data.icon)

        if data.count and data.count > 1 then
            debuffFrame.stack:SetText(data.count)
            debuffFrame.stack:Show()
        else
            debuffFrame.stack:Hide()
        end

        if settings.showTimer ~= false and debuffFrame.cooldown and debuffFrame.timer and data.duration then
            ConfigureTimer(debuffFrame, data.duration)
        else
            if debuffFrame.cooldown then debuffFrame.cooldown:Clear() end
            if debuffFrame.timer then debuffFrame.timer:SetText("") end
            if debuffFrame.timerUpdate then
                debuffFrame.timerUpdate:Cancel()
                debuffFrame.timerUpdate = nil
            end
        end
    end

    container.testDebuffsActive = true
end

---Loop through frames and reset test debuffs before reapplying.
function Debuffs:TestMode()
    local frames = GetFrames()
    local classes = {"Deathknight", "Mage", "Hunter"}

    for index, frame in ipairs(frames) do
        if frame and EnsureDebuffContainer(frame) then
            frame.debuffContainer.testDebuffsActive = false
            self:ApplyTestDebuffs(frame, classes[index] or "Mage")
        end
    end
end

---Reposition and rebuild debuff containers when settings change.
function Debuffs:RefreshSettings()
    local frames = GetFrames()
    local settings = GetDebuffSettings()

    for _, frame in ipairs(frames) do
        local container = frame and EnsureDebuffContainer(frame)
        if container then
            container:ClearAllPoints()
            local horizontal = settings and settings.positioning and settings.positioning.horizontal or 8
            local vertical = settings and settings.positioning and settings.positioning.vertical or 6
            container:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", horizontal, vertical)

            for i = 1, #container.debuffs do
                if container.debuffs[i] then
                    container.debuffs[i]:SetAlpha(0)
                    container.debuffs[i]:Hide()
                end
            end

            container.debuffs = {}
            container.testDebuffsActive = false

            if not settings or not settings.enabled then
                container:Hide()
            end
        end
    end

    if settings and settings.enabled and AC.testModeEnabled then
        self:TestMode()
    end
end

AC.MasterFrameManager = AC.MasterFrameManager or {}
AC.MasterFrameManager.Debuffs = Debuffs

-- CRITICAL: Also register to AC.FrameManager for compatibility
AC.FrameManager = AC.FrameManager or {}
AC.FrameManager.Debuffs = Debuffs

return Debuffs
