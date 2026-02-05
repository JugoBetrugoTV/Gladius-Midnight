local AC = _G.ArenaCore or {}

local function GetAC()
    if _G.ArenaCore and AC ~= _G.ArenaCore then
        AC = _G.ArenaCore
    end
    return AC
end

local DR = {}

--[[
    Diminishing Returns (DR) module responsible for creating, positioning, and updating
    DR icons on arena frames. Extracted from the legacy core implementation so all DR
    visuals live in a single place and match the modular structure used by cast bars,
    debuffs, and dispels.
]]

-- CRITICAL FIX: Batch positioning updates to prevent multiple calls per frame
-- This ensures all DR icons are positioned in ONE pass
local pendingPositionUpdates = {}
local positionUpdateScheduled = false

local MAX_ARENA_ENEMIES = 3

local DR_CATEGORIES = {
    "stun",
    "silence",
    "root",
    "incapacitate",
    "disorient",
    "fear",
    "mc",
    "cyclone",
    "banish",
    "knockback",
    "disarm"
}

local TEST_CATEGORIES = {
    { category = "stun", defaultSpellID = 408 },
    { category = "silence", defaultSpellID = 15487 },
    { category = "root", defaultSpellID = 339 },
    { category = "incapacitate", defaultSpellID = 118 },
    { category = "disorient", defaultSpellID = 5782 },
    { category = "disarm", defaultSpellID = 207777 },
    { category = "knockback", defaultSpellID = 51490 }
}

local DEFAULT_ICON_SPELLS = {}
for _, data in ipairs(TEST_CATEGORIES) do
    DEFAULT_ICON_SPELLS[data.category] = data.defaultSpellID
end
DEFAULT_ICON_SPELLS.fear = DEFAULT_ICON_SPELLS.fear or 5782
DEFAULT_ICON_SPELLS.mc = DEFAULT_ICON_SPELLS.mc or 605
DEFAULT_ICON_SPELLS.cyclone = DEFAULT_ICON_SPELLS.cyclone or 33786
DEFAULT_ICON_SPELLS.banish = DEFAULT_ICON_SPELLS.banish or 710

local function GetFrames()
    local ac = GetAC()
    if not ac then return nil end

    local manager = ac.MasterFrameManager or ac.FrameManager
    if manager and manager.GetFrames then
        local frames = manager:GetFrames()
        if frames and next(frames) then
            return frames
        end
    end

    if ac.arenaFrames then
        return ac.arenaFrames
    end

    return nil
end

local function GetFrameIndex(unitID)
    if not unitID then return nil end
    local index = unitID:match("arena(%d+)")
    return index and tonumber(index) or nil
end

local function GetSettings()
    local ac = GetAC()
    return ac.DB and ac.DB.profile and ac.DB.profile.diminishingReturns
end

local function EnsureContainer(frame)
    -- Create DRHolder first (for Z-order policy)
    if not frame.DRHolder then
        frame.DRHolder = CreateFrame("Frame", nil, frame)
        frame.DRHolder:SetAllPoints(frame)
        frame.DRHolder:SetFrameStrata("HIGH")
        frame.DRHolder:SetFrameLevel((frame:GetFrameLevel() or 10) + 30)
        frame.DRHolder:SetToplevel(false)
    end
    
    if frame.drContainer then
        return frame.drContainer
    end

    -- Parent container to DRHolder instead of frame
    local container = CreateFrame("Frame", nil, frame.DRHolder)
    container:SetAllPoints(frame)
    container:SetFrameStrata(frame.DRHolder:GetFrameStrata())
    container:SetFrameLevel(frame.DRHolder:GetFrameLevel() + 1)
    frame.drContainer = container
    return container
end

local function SafeSetFont(fontString, size)
    if not fontString then return end
    local ac = GetAC()
    if ac.SafeSetFont then
        ac.SafeSetFont(fontString, ac.FONT_PATH, size, "OUTLINE")
    else
        fontString:SetFont("Interface/AddOns/ArenaCore/Media/Fonts/arenacore.ttf", size, "OUTLINE")
    end
end

--[[
    Creates a single DR icon frame for the given category.
    Each frame stores severity, cooldown, timer text, and stage text just like
    the original implementation but now isolated in this module.
]]
function DR:CreateIcon(frame, category)
    local parent = EnsureContainer(frame)
    local dr = CreateFrame("Frame", nil, parent)
    dr:SetSize(22, 22)
    dr.category = category
    dr.severity = 0
    dr.diminished = nil  -- CRITICAL: Initialize to nil so first TrackApplication resets to 1.0
    dr.reset = 0  -- CRITICAL: Initialize to 0 so first check treats it as expired
    dr.active = false
    dr:Hide()

    local bg1 = dr:CreateTexture(nil, "BACKGROUND")
    bg1:SetAllPoints()
    bg1:SetTexture("Interface/AddOns/ArenaCore/Media/Classicons/Overlays/orangeoverlay.tga")
    bg1:SetTexCoord(0, 1, 0, 1)
    bg1:SetVertexColor(1, 0.4, 0, 1)

    local bg2 = dr:CreateTexture(nil, "BACKGROUND", nil, 1)
    bg2:SetAllPoints()
    bg2:SetTexture("Interface/AddOns/ArenaCore/Media/Classicons/Overlays/orangeoverlay.tga")
    bg2:SetTexCoord(0, 1, 0, 1)
    bg2:SetVertexColor(1, 0.3, 0, 0.8)

    local icon = dr:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0, 1, 0, 1)

    local overlay = dr:CreateTexture(nil, "OVERLAY")
    overlay:SetAllPoints()
    overlay:SetTexture("Interface/AddOns/ArenaCore/Media/Classicons/Overlays/orangeoverlay.tga")
    overlay:SetTexCoord(0, 1, 0, 1)

    -- Create cooldown frame (using helper to block OmniCC)
    local cooldown = AC:CreateCooldown(dr, nil, "CooldownFrameTemplate")
    cooldown:SetSize(15, 15)
    cooldown:SetPoint("CENTER")
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetDrawEdge(true)
    cooldown:SetSwipeColor(0, 0, 0, 0.8)
    
    -- CRITICAL: Ensure OmniCC doesn't add its own numbers (belt and suspenders approach)
    cooldown.noCooldownCount = true
    cooldown.noOCC = true
    if cooldown.omnicc then
        cooldown.omnicc.enabled = false
    end
    
    -- CRITICAL: Apply spiral animation settings from isolated module
    if AC.DRSpiralAnimation and AC.DRSpiralAnimation.ApplySettings then
        AC.DRSpiralAnimation:ApplySettings(cooldown)
    end
    
    -- Create custom white timer text
    local timerText = cooldown:CreateFontString(nil, "OVERLAY")
    timerText:SetPoint("CENTER", dr, "CENTER", 0, 1)
    SafeSetFont(timerText, 12)
    timerText:SetTextColor(1, 1, 1, 1)

    -- User's custom colored stage text (1/3, 2/3, 3/3) - green/yellow/red
    local stageText = cooldown:CreateFontString(nil, "OVERLAY")
    stageText:SetPoint("BOTTOMRIGHT", dr, "BOTTOMRIGHT", -2, 2)
    SafeSetFont(stageText, 10)
    stageText:SetTextColor(1, 1, 0, 1)  -- Default yellow
    
    function dr:UpdateStage(stage)
        -- Check if we're in Midnight (2-stage DR system)
        local ac = GetAC()
        local isMidnight = ac and ac.Midnight and ac.Midnight.isMidnight
        
        -- Set diminished multiplier based on stage
        if isMidnight then
            -- Midnight: Only 2 stages (1=half, 2=immune)
            self.diminished = (stage or 1) >= 2 and 0 or 0.5
        else
            -- Pre-Midnight: 3 stages (1=1.0, 2=0.5, 3=0.25)
            if stage == 1 then
                self.diminished = 1.0
            elseif stage == 2 then
                self.diminished = 0.5
            elseif stage == 3 then
                self.diminished = 0.25
            else
                self.diminished = 1.0
            end
        end
        
        if not stageText then return end
        
        local db = GetSettings()
        local showStage = db and db.showStageIndicators
        if showStage == nil then showStage = true end
        
        if showStage then
            if isMidnight then
                -- Midnight: Only show 1/2 (green) or 2/2 (red)
                local isImmune = (stage or 1) >= 2
                if isImmune then
                    stageText:SetText("2/2")
                    stageText:SetTextColor(1, 0, 0, 1)  -- Red
                else
                    stageText:SetText("1/2")
                    stageText:SetTextColor(0, 1, 0, 1)  -- Green
                end
            else
                -- Pre-Midnight: 3 stages with 1/3, 2/3, 3/3
                local capped = math.min(stage or 1, 3)
                stageText:SetText(capped .. "/3")
                if capped == 1 then
                    stageText:SetTextColor(0, 1, 0, 1)  -- Green
                elseif capped == 2 then
                    stageText:SetTextColor(1, 1, 0, 1)  -- Yellow
                else
                    stageText:SetTextColor(1, 0, 0, 1)  -- Red
                end
            end
            stageText:Show()
        else
            stageText:Hide()
        end
        
        -- Update border colors if color-coded borders enabled
        local colorBorders = db and db.colorCodedBorders
        if colorBorders and self.overlay and self.background and self.background2 then
            if isMidnight then
                -- Midnight: Green or Red only
                local isImmune = (stage or 1) >= 2
                if isImmune then
                    self.overlay:SetVertexColor(1, 0, 0, 1)
                    self.background:SetVertexColor(0.8, 0, 0, 1)
                    self.background2:SetVertexColor(0.6, 0, 0, 0.8)
                else
                    self.overlay:SetVertexColor(0, 1, 0, 1)
                    self.background:SetVertexColor(0, 0.8, 0, 1)
                    self.background2:SetVertexColor(0, 0.6, 0, 0.8)
                end
            else
                -- Pre-Midnight: Green/Yellow/Red
                local capped = math.min(stage or 1, 3)
                if capped == 1 then
                    self.overlay:SetVertexColor(0, 1, 0, 1)
                    self.background:SetVertexColor(0, 0.8, 0, 1)
                    self.background2:SetVertexColor(0, 0.6, 0, 0.8)
                elseif capped == 2 then
                    self.overlay:SetVertexColor(1, 1, 0, 1)
                    self.background:SetVertexColor(1, 0.8, 0, 1)
                    self.background2:SetVertexColor(1, 0.6, 0, 0.8)
                else
                    self.overlay:SetVertexColor(1, 0, 0, 1)
                    self.background:SetVertexColor(0.8, 0, 0, 1)
                    self.background2:SetVertexColor(0.6, 0, 0, 0.8)
                end
            end
        else
            -- Default orange borders when color coding disabled
            if self.overlay then
                self.overlay:SetVertexColor(1, 1, 1, 1)
            end
            if self.background then
                self.background:SetVertexColor(1, 0.4, 0, 1)
            end
            if self.background2 then
                self.background2:SetVertexColor(1, 0.3, 0, 0.8)
            end
        end
    end

    function dr:UpdateFontPositioning(db)
        if not db or not db.positioning then return end
        local pos = db.positioning
        local timerX = pos.timerFontX or 0
        local timerY = pos.timerFontY or 1
        timerText:ClearAllPoints()
        timerText:SetPoint("CENTER", self, "CENTER", timerX, timerY)
        
        -- RESTORED: User's stage text positioning
        local stageX = pos.stageFontX or -2
        local stageY = pos.stageFontY or 2
        stageText:ClearAllPoints()
        stageText:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", stageX, stageY)
    end

    dr.icon = icon
    dr.cooldown = cooldown
    dr.timerText = timerText
    dr.stageText = stageText  -- RESTORED: User's custom white stage text
    dr.overlay = overlay
    dr.background = bg1
    dr.background2 = bg2

    return dr
end

--[[
    Ensures a frame has the complete DR setup (container + icon table).
]]
function DR:EnsureFrame(frame)
    EnsureContainer(frame)
    frame.drIcons = frame.drIcons or {}
    for _, category in ipairs(DR_CATEGORIES) do
        if not frame.drIcons[category] then
            frame.drIcons[category] = self:CreateIcon(frame, category)
        end
    end
end

local PRIORITY_ORDER = {
    stun = 1,
    disorient = 2,
    silence = 3,
    incapacitate = 4,
    root = 5,
    disarm = 6,
    knockback = 7
}

--[[
    CRITICAL FIX: Queue a position update instead of executing immediately.
    This batches multiple DR updates into a single positioning pass.
    Prevents the bug where each DR icon thinks it's the first one.
]]
local function QueuePositionUpdate(frame)
    if not frame then return end
    
    -- Mark this frame as needing a position update
    pendingPositionUpdates[frame] = true
    
    -- Schedule the batch update if not already scheduled
    if not positionUpdateScheduled then
        positionUpdateScheduled = true
        C_Timer.After(0, function()
            -- Process all pending updates in one pass
            for pendingFrame in pairs(pendingPositionUpdates) do
                DR:UpdatePositions(pendingFrame)
            end
            -- Clear the queue
            pendingPositionUpdates = {}
            positionUpdateScheduled = false
        end)
    end
end

--[[
    Positions DR icons according to user settings. Mirrors the logic from
    `AC:UpdateDRPositions` but scoped to the module.
]]
function DR:UpdatePositions(frame)
    if not frame or not frame.drIcons then return end

    local db = GetSettings()
    if not db or db.enabled == false then
        -- CRITICAL FIX: Hide all DR icons when DR tracking is disabled
        if frame.drContainer then
            frame.drContainer:Hide()
        end
        for _, icon in pairs(frame.drIcons) do
            if icon then
                icon:Hide()
            end
        end
        return
    end
    
    -- CRITICAL FIX: Show drContainer when DR tracking is enabled
    if frame.drContainer then
        frame.drContainer:Show()
    end

    local pos = db.positioning or {}
    local rowsCfg = db.rows or {}
    
    local spacing = tonumber(pos.spacing) or 5
    local iconSize = tonumber((db.sizing and db.sizing.size) or 22)
    local growthDirection = rowsCfg.growthDirection or 4 -- 1=Up, 2=Down, 3=Left, 4=Right
    local dynamicPositioning = (rowsCfg.dynamicPositioning ~= false) -- Default true
    local stackingMode = rowsCfg.stackingMode or "straight" -- "straight" or "stacked"
    
    local ordered = {}
    for key, icon in pairs(frame.drIcons) do
        if icon then
            table.insert(ordered, { key = key, frame = icon })
        end
    end

    -- Icons always stay in same order (Stun → Knockback)
    table.sort(ordered, function(a, b)
        local aPriority = PRIORITY_ORDER[tostring(a.key)] or 999
        local bPriority = PRIORITY_ORDER[tostring(b.key)] or 999
        
        if aPriority ~= bPriority then
            return aPriority < bPriority
        end
        return tostring(a.key) < tostring(b.key)
    end)

    if #ordered == 0 then return end

    local baseX = pos.horizontal or 0
    local baseY = pos.vertical or 0

    -- STACKED MODE: 4 icons on top row, 3 icons on bottom row
    if stackingMode == "stacked" then
        -- Split icons into two rows: first 4 (top), next 3 (bottom)
        local topRow = {}
        local bottomRow = {}
        
        for i = 1, #ordered do
            if i <= 4 then
                table.insert(topRow, ordered[i])
            else
                table.insert(bottomRow, ordered[i])
            end
        end
        
        -- Helper function to position a single row with dynamic positioning
        local function PositionRow(rowIcons, rowBaseX, rowBaseY)
            if dynamicPositioning then
                -- DYNAMIC: Collapse gaps within this row
                local numActive = 0
                local prevFrame = nil
                
                for i = 1, #rowIcons do
                    local item = rowIcons[i]
                    local iconFrame = item.frame
                    
                    if iconFrame and iconFrame:IsShown() then
                        iconFrame:ClearAllPoints()
                        
                        if numActive == 0 then
                            -- First visible icon in row: anchor to frame
                            iconFrame:SetPoint("CENTER", frame, "CENTER", rowBaseX, rowBaseY)
                        else
                            -- Chain to previous active icon in this row
                            if growthDirection == 1 then
                                -- Up: horizontal row, icons go left
                                iconFrame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                            elseif growthDirection == 2 then
                                -- Down: horizontal row, icons go left
                                iconFrame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                            elseif growthDirection == 3 then
                                -- Left: vertical row, icons go up
                                iconFrame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
                            elseif growthDirection == 4 then
                                -- Right: horizontal row, icons go left
                                iconFrame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                            else
                                iconFrame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                            end
                        end
                        
                        prevFrame = iconFrame
                        numActive = numActive + 1
                    end
                end
            else
                -- STATIC: Fixed positions with gaps
                for idx, item in ipairs(rowIcons) do
                    local iconFrame = item.frame
                    if iconFrame then
                        iconFrame:ClearAllPoints()
                        
                        local offset = (idx - 1) * (iconSize + spacing)
                        
                        if growthDirection == 1 then
                            -- Up: horizontal row
                            iconFrame:SetPoint("RIGHT", frame, "RIGHT", rowBaseX - offset, rowBaseY)
                        elseif growthDirection == 2 then
                            -- Down: horizontal row
                            iconFrame:SetPoint("RIGHT", frame, "RIGHT", rowBaseX - offset, rowBaseY)
                        elseif growthDirection == 3 then
                            -- Left: vertical row
                            iconFrame:SetPoint("TOP", frame, "TOP", rowBaseX, rowBaseY - offset)
                        elseif growthDirection == 4 then
                            -- Right: horizontal row
                            iconFrame:SetPoint("RIGHT", frame, "RIGHT", rowBaseX - offset, rowBaseY)
                        else
                            iconFrame:SetPoint("RIGHT", frame, "RIGHT", rowBaseX - offset, rowBaseY)
                        end
                    end
                end
            end
        end
        
        -- Calculate row offsets based on growth direction
        local rowSpacing = iconSize + spacing
        
        if growthDirection == 1 then
            -- Up: rows stack horizontally (top row left, bottom row right)
            PositionRow(topRow, baseX, baseY)
            PositionRow(bottomRow, baseX, baseY - rowSpacing)
        elseif growthDirection == 2 then
            -- Down: rows stack horizontally (top row left, bottom row right)
            PositionRow(topRow, baseX, baseY)
            PositionRow(bottomRow, baseX, baseY + rowSpacing)
        elseif growthDirection == 3 then
            -- Left: rows stack vertically (top row left, bottom row right)
            PositionRow(topRow, baseX, baseY)
            PositionRow(bottomRow, baseX + rowSpacing, baseY)
        elseif growthDirection == 4 then
            -- Right: rows stack horizontally (top row left, bottom row right)
            PositionRow(topRow, baseX, baseY)
            PositionRow(bottomRow, baseX, baseY - rowSpacing)
        else
            PositionRow(topRow, baseX, baseY)
            PositionRow(bottomRow, baseX, baseY - rowSpacing)
        end
        
    else
        -- STRAIGHT MODE: Original single-line behavior
        if dynamicPositioning then
            -- DYNAMIC ON: Icons collapse together, filling gaps
            local numActive = 0
            local prevFrame = nil
            
            for i = 1, #ordered do
                local item = ordered[i]
                local iconFrame = item.frame
                
                if iconFrame and iconFrame:IsShown() then
                    iconFrame:ClearAllPoints()
                    
                    if numActive == 0 then
                        iconFrame:SetPoint("CENTER", frame, "CENTER", baseX, baseY)
                    else
                        if growthDirection == 1 then
                            iconFrame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
                        elseif growthDirection == 2 then
                            iconFrame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
                        elseif growthDirection == 3 then
                            iconFrame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
                        elseif growthDirection == 4 then
                            iconFrame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                        else
                            iconFrame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                        end
                    end
                    
                    prevFrame = iconFrame
                    numActive = numActive + 1
                end
            end
        else
            -- DYNAMIC OFF: Fixed positions with gaps
            for idx, item in ipairs(ordered) do
                local iconFrame = item.frame
                if iconFrame then
                    iconFrame:ClearAllPoints()
                    
                    local offset = (idx - 1) * (iconSize + spacing)
                    
                    if growthDirection == 1 then
                        iconFrame:SetPoint("TOP", frame, "TOP", baseX, baseY - offset)
                    elseif growthDirection == 2 then
                        iconFrame:SetPoint("BOTTOM", frame, "BOTTOM", baseX, baseY + offset)
                    elseif growthDirection == 3 then
                        iconFrame:SetPoint("LEFT", frame, "LEFT", baseX + offset, baseY)
                    elseif growthDirection == 4 then
                        iconFrame:SetPoint("RIGHT", frame, "RIGHT", baseX - offset, baseY)
                    else
                        iconFrame:SetPoint("RIGHT", frame, "RIGHT", baseX - offset, baseY)
                    end
                end
            end
        end
    end
end

--[[
    Reapplies layout, sizing, and font settings to every active frame.
]]
function DR:RefreshLayout()
    local db = GetSettings()
    if not db then return end

    local iconSize = (db.sizing and db.sizing.size) or 22
    local fontSize = (db.sizing and db.sizing.fontSize) or 10
    local stageSize = (db.sizing and db.sizing.stageFontSize) or 8

    local ac = GetAC()
    local manager = ac.MasterFrameManager or ac.FrameManager
    if not manager or not manager.GetFrames then
        return
    end

    local frames = manager:GetFrames() or {}

    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            self:EnsureFrame(frame)
            for _, drFrame in pairs(frame.drIcons or {}) do
                drFrame:SetSize(iconSize, iconSize)
                if drFrame.icon then
                    local inset = math.max(2, iconSize * 0.15)
                    drFrame.icon:SetSize(iconSize - inset, iconSize - inset)
                end
                if drFrame.cooldown then
                    local cooldownSize = iconSize - (iconSize * 0.1)
                    drFrame.cooldown:SetSize(cooldownSize, cooldownSize)
                end
                if drFrame.timerText then
                    SafeSetFont(drFrame.timerText, fontSize)
                end
                -- RESTORED: User's stage text font sizing
                if drFrame.stageText then
                    SafeSetFont(drFrame.stageText, stageSize)
                end
            end
            self:UpdatePositions(frame)
        end
    end

    if ac.testModeEnabled then
        self:ShowTestIcons(manager)
    end
end

local testTicker
local realArenaTicker

local function CancelTestTicker(manager)
    if testTicker then
        testTicker:Cancel()
        testTicker = nil
    end
    if manager then
        manager.drTestRefreshTimer = nil
    end
end

function DR:ShowTestIcons(manager)
    local ac = GetAC()
    if not ac.testModeEnabled then
        return
    end

    local db = GetSettings()
    if not db or db.enabled == false then
        self:HideTestIcons(manager)
        return
    end

    manager = manager or ac.MasterFrameManager or ac.FrameManager
    if not manager or not manager.GetFrames then
        return
    end

    local frames = manager:GetFrames()
    if not frames then return end

    -- CRITICAL FIX: Force clear all DR icons BEFORE showing test icons
    -- This prevents broken arena DR state (active cooldowns, stage counters) from persisting
    -- Without this, DR icons from previous arena match can cause missing/broken test icons
    self:ClearAllDRs()

    local activeDB = (ac.GetActiveDRSettingsDB and ac:GetActiveDRSettingsDB()) or db
    activeDB.categories = activeDB.categories or {}

    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            self:EnsureFrame(frame)
            
            -- CRITICAL FIX: Use frame ID for stage calculation, not array index
            -- This ensures correct DR stages even if frames array is reordered
            local frameID = frame.id or i

            for j, data in ipairs(TEST_CATEGORIES) do
                local iconFrame = frame.drIcons[data.category]
                if iconFrame then
                    local categoryEnabled = (activeDB.categories[data.category] ~= false)
                    if categoryEnabled then
                        local spellID = data.defaultSpellID
                        if ac.ResolveDRIconSpellID then
                            spellID = ac:ResolveDRIconSpellID(data.category, nil, data.defaultSpellID)
                        end

                        -- Check if we're in Midnight (2-stage DR system)
                        local isMidnight = ac and ac.Midnight and ac.Midnight.isMidnight
                        local stage
                        
                        if isMidnight then
                            -- Midnight: Only 2 stages - Arena 1 = green ½, Arena 2/3 = red %
                            stage = (frameID == 1) and 1 or 2
                            iconFrame.diminished = (stage >= 2) and 0 or 0.5
                        else
                            -- Pre-Midnight: 3 stages
                            stage = ((frameID - 1) % 3) + 1
                            if stage == 1 then
                                iconFrame.diminished = 1.0
                            elseif stage == 2 then
                                iconFrame.diminished = 0.5
                            else
                                iconFrame.diminished = 0.25
                            end
                        end
                        
                        -- Update stage display (respects Midnight 2-stage system)
                        if iconFrame.UpdateStage then
                            iconFrame:UpdateStage(stage)
                        end

                        -- CRITICAL FIX: Ensure icon texture is always set and visible
                        if iconFrame.icon then
                            local spellInfo = C_Spell.GetSpellInfo(spellID)
                            if spellInfo and spellInfo.iconID then
                                iconFrame.icon:SetTexture(spellInfo.iconID)
                                iconFrame.icon:Show()
                                iconFrame.icon:SetAlpha(1)
                            else
                                -- Fallback: Use a default question mark icon if spell info fails
                                iconFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                                iconFrame.icon:Show()
                                iconFrame.icon:SetAlpha(1)
                            end
                        end

                        iconFrame:Show()
                        iconFrame:SetAlpha(1)
                        if iconFrame.cooldown then
                            local cooldownTime = 18.5 - (j * 2)
                            iconFrame.cooldown:SetCooldown(GetTime(), cooldownTime)
                            iconFrame.testCooldownDuration = cooldownTime
                            
                            -- CRITICAL FIX: Hide built-in cooldown numbers after SetCooldown
                            -- SetCooldown() can re-enable built-in numbers, causing duplicate timers
                            iconFrame.cooldown:SetHideCountdownNumbers(true)
                            
                            -- CRITICAL: Reapply spiral animation settings after SetCooldown
                            if AC.DRSpiralAnimation and AC.DRSpiralAnimation.ApplySettings then
                                AC.DRSpiralAnimation:ApplySettings(iconFrame.cooldown)
                            end
                        end
                    else
                        iconFrame:Hide()
                    end
                end
            end

            self:UpdatePositions(frame)
        end
    end

    if not testTicker then
        testTicker = C_Timer.NewTicker(1, function()
            local acInner = GetAC()
            if not acInner or not acInner.testModeEnabled then
                CancelTestTicker(manager)
                return
            end

            local mgrInner = manager or acInner.MasterFrameManager or acInner.FrameManager
            if not mgrInner or not mgrInner.GetFrames then
                return
            end

            local framesInner = mgrInner:GetFrames()
            if not framesInner then 
                return 
            end

            for i = 1, MAX_ARENA_ENEMIES do
                local frame = framesInner[i]
                if frame and frame.drIcons then
                    for _, iconFrame in pairs(frame.drIcons) do
                        -- CRITICAL FIX: Keep ALL visible DR icons alive in test mode
                        -- Don't check for testCooldownDuration - if icon is shown, keep it alive
                        if iconFrame and iconFrame:IsShown() and iconFrame.cooldown then
                            -- Ensure testCooldownDuration exists (fallback to default if missing)
                            if not iconFrame.testCooldownDuration then
                                iconFrame.testCooldownDuration = 15  -- Default test cooldown
                            end
                            
                            local start, duration = iconFrame.cooldown:GetCooldownTimes()
                            local now = GetTime() * 1000
                            if start == 0 or now >= (start + duration) then
                                iconFrame.cooldown:SetCooldown(GetTime(), iconFrame.testCooldownDuration)
                                
                                -- CRITICAL FIX: Hide built-in cooldown numbers after SetCooldown
                                -- SetCooldown() can re-enable built-in numbers, causing duplicate timers
                                iconFrame.cooldown:SetHideCountdownNumbers(true)
                                
                                -- CRITICAL: Reapply spiral animation settings after cooldown reset
                                if AC.DRSpiralAnimation and AC.DRSpiralAnimation.ApplySettings then
                                    AC.DRSpiralAnimation:ApplySettings(iconFrame.cooldown)
                                end
                            end

                            if iconFrame.timerText and start > 0 then
                                local remaining = math.ceil((start + duration - now) / 1000)
                                if remaining > 0 then
                                    iconFrame.timerText:SetText(tostring(remaining))
                                else
                                    iconFrame.timerText:SetText("")
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    manager.drTestRefreshTimer = testTicker
end

function DR:HideTestIcons(manager)
    CancelTestTicker(manager)

    local ac = GetAC()
    manager = manager or ac.MasterFrameManager or ac.FrameManager
    if not manager or not manager.GetFrames then
        return
    end

    local frames = manager:GetFrames()
    if not frames then return end

    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame then
            -- CRITICAL FIX: Hide drContainer when hiding test icons
            if frame.drContainer then
                frame.drContainer:Hide()
            end
            if frame.drIcons then
                for _, icon in pairs(frame.drIcons) do
                    icon:Hide()
                    if icon.cooldown then icon.cooldown:Clear() end
                    if icon.timerText then icon.timerText:SetText("") end
                end
            end
        end
    end
end

function DR:EnsureTestTicker(manager)
    if testTicker and (not manager or manager.drTestRefreshTimer == testTicker) then
        return
    end
    self:ShowTestIcons(manager)
end

local function CancelRealArenaTicker()
    if realArenaTicker then
        realArenaTicker:Cancel()
        realArenaTicker = nil
    end
end

-- Handles severity tracking and cooldown state for live arena diminishing returns
-- Uses combat log events (SPELL_AURA_APPLIED) to track DR applications
-- Optional parameters: stage, text, r, g, b (passed by DRTracker_Fixed.lua)
function DR:TrackApplication(unitGUID, spellID, category, stage, text, r, g, b)
    if not unitGUID or not category then return end

    -- Convert GUID to unitID (arena1, arena2, arena3)
    local unitID = nil
    for i = 1, 3 do
        local unit = "arena" .. i
        if UnitGUID(unit) == unitGUID then
            unitID = unit
            break
        end
    end
    
    if not unitID then return end

    local frames = GetFrames()
    if not frames then return end

    local index = GetFrameIndex(unitID)
    if not index or not frames[index] then return end

    local frame = frames[index]
    if not frame or not frame.drIcons then return end

    local drFrame = frame.drIcons[category]
    if not drFrame then return end

    local now = GetTime()

    local auraDuration
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local auraData = C_UnitAuras.GetAuraDataByIndex(unitID, i, "HARMFUL")
            if not auraData then break end
            if auraData.spellId == spellID then
                auraDuration = auraData.duration
                break
            end
        end
    end

    -- FIXED: Use diminished multiplier system (not integer severity)
    -- Duration multipliers: 1.0 (full) -> 0.5 (half) -> 0.25 (quarter) -> 0 (immune)
    local diminished = drFrame.diminished
    
    if not diminished or (drFrame.reset and drFrame.reset <= now) then
        -- First application OR DR window expired - reset to full duration
        if DRList and DRList.GetNextDR then
            diminished = DRList:GetNextDR(1, category) * 2  -- Returns 0.5 * 2 = 1.0
        else
            diminished = 1.0
        end
    elseif auraDuration then
        -- DR window still active - calculate next diminished value
        if DRList and DRList.NextDR then
            diminished = DRList:NextDR(diminished, category)  -- 1.0 -> 0.5 -> 0.25 -> 0
        else
            diminished = diminished * 0.5
        end
    end
    
    drFrame.diminished = diminished
    drFrame.active = true
    
    -- FIXED: Use proper timer logic - resetTime + auraDuration
    -- This makes DR expire 18.5s AFTER the CC ends, not from when it starts
    local resetTime
    if DRList and DRList.GetResetTime then
        resetTime = DRList:GetResetTime(category)
    else
        resetTime = 18.5  -- fallback
    end
    
    local timeLeft
    if auraDuration then
        timeLeft = resetTime + auraDuration  -- 18.5s + CC duration
    else
        timeLeft = resetTime  -- Just 18.5s if no duration found
    end
    
    drFrame.reset = timeLeft + now  -- Use 'reset' not 'expirationTime'
    drFrame.activeCooldownStart = now
    drFrame.activeCooldownDuration = timeLeft
    drFrame.actualDuration = auraDuration  -- Store actual spell duration for reference

    -- CRITICAL FIX: Use ResolveDRIconSpellID to respect user's custom icon selection
    -- This matches test mode behavior and ensures Detailed DR Settings work in live arena
    local resolvedSpellID = spellID
    local ac = GetAC()
    if ac and ac.ResolveDRIconSpellID then
        resolvedSpellID = ac:ResolveDRIconSpellID(category, unitGUID, spellID)
    end
    
    if resolvedSpellID and drFrame.icon then
        local spellInfo = C_Spell.GetSpellInfo(resolvedSpellID)
        if spellInfo and spellInfo.iconID then
            drFrame.icon:SetTexture(spellInfo.iconID)
        end
    end

    -- Use stage parameter if provided by DRTracker_Fixed.lua, otherwise calculate from diminished value
    local displayStage = stage
    if not displayStage then
        -- Convert diminished multiplier to stage for display (1.0=stage1, 0.5=stage2, 0.25=stage3, 0=immune)
        -- CRITICAL FIX: Check conditions from LARGEST to SMALLEST
        -- 1.0 = ½ symbol (green), 0.5 = ¼ symbol (orange), 0.25 = % (red), 0 = % (red)
        if diminished >= 1.0 then
            displayStage = 1  -- Full duration (green) - FIRST application
        elseif diminished >= 0.5 then
            displayStage = 2  -- Half duration (yellow) - SECOND application
        elseif diminished > 0 then
            displayStage = 3  -- Quarter duration (red) - THIRD application
        else
            displayStage = 3  -- Immune (red) - FOURTH+ application
        end
    end
    
    -- CRITICAL FIX: Use UpdateStage to respect showStageIndicators and colorCodedBorders settings
    if drFrame.UpdateStage then
        drFrame:UpdateStage(displayStage)
    end

    -- Set cooldown spiral
    if drFrame.cooldown then
        drFrame.cooldown:SetCooldown(now, timeLeft)
        drFrame.cooldown:SetHideCountdownNumbers(false)  -- Show countdown numbers
        
        -- CRITICAL: Reapply spiral animation settings after SetCooldown in live arena
        if AC.DRSpiralAnimation and AC.DRSpiralAnimation.ApplySettings then
            AC.DRSpiralAnimation:ApplySettings(drFrame.cooldown)
        end
    end
    
    -- Store timer data
    drFrame.timeLeft = timeLeft
    drFrame.timerStartTime = now
    drFrame.timerDuration = timeLeft
    
    -- Set up OnUpdate script to count down and hide when expired
    drFrame:SetScript("OnUpdate", function(f, elapsed)
        f.timeLeft = f.timeLeft - elapsed
        if f.timeLeft <= 0 then
            f.active = false
            f:Hide()
            f:SetAlpha(0)
            f:SetScript("OnUpdate", nil)
            QueuePositionUpdate(frame)
        end
    end)

    drFrame:Show()
    drFrame:SetAlpha(1)  -- Force full visibility
    
    -- CRITICAL FIX: Queue position update instead of immediate call (batching)
    QueuePositionUpdate(frame)
end

-- Updates icon visuals for a tracked DR category on demand (e.g., combat log callbacks)
function DR:UpdateLiveDisplay(unitID, category, actualSpellID)
    local frames = GetFrames()
    if not frames then return end

    local index = GetFrameIndex(unitID)
    if not index or not frames[index] then return end

    local frame = frames[index]
    if not frame or not frame.drIcons then return end

    local drFrame = frame.drIcons[category]
    if not drFrame then return end

    -- CRITICAL FIX: Use ResolveDRIconSpellID to respect user's custom icon selection
    -- This matches test mode behavior and ensures Detailed DR Settings work in live arena
    local spellID = actualSpellID or DEFAULT_ICON_SPELLS[category]
    local ac = GetAC()
    if ac and ac.ResolveDRIconSpellID then
        -- Get unit GUID for resolver (may use it for per-unit tracking in future)
        local unitGUID = UnitGUID(unitID)
        spellID = ac:ResolveDRIconSpellID(category, unitGUID, actualSpellID)
    end
    
    if spellID and drFrame.icon then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo and spellInfo.iconID then
            drFrame.icon:SetTexture(spellInfo.iconID)
        end
    end

    -- FIXED: Convert diminished multiplier to display stage
    -- CRITICAL: Check from LARGEST to SMALLEST using >= operators (not <=)
    local diminished = drFrame.diminished or 1.0
    local displayStage = 1
    if diminished >= 1.0 then
        displayStage = 1  -- Full duration (green) - FIRST application
    elseif diminished >= 0.5 then
        displayStage = 2  -- Half duration (orange) - SECOND application
    elseif diminished > 0 then
        displayStage = 3  -- Quarter duration (red) - THIRD application
    else
        displayStage = 3  -- Immune (red) - FOURTH+ application
    end

    -- CRITICAL FIX: Use UpdateStage to respect showStageIndicators and colorCodedBorders settings
    if drFrame.UpdateStage then
        drFrame:UpdateStage(displayStage)
    end

    drFrame:Show()
    -- CRITICAL FIX: Queue position update instead of immediate call (batching)
    QueuePositionUpdate(frame)
end

-- Maintains live arena DR timer text and auto-cleans icons when the window expires
function DR:StartRealArenaTicker()
    CancelRealArenaTicker()

    realArenaTicker = C_Timer.NewTicker(0.1, function()
        local ac = GetAC()
        if ac and ac.testModeEnabled then
            return
        end

        local frames = GetFrames()
        if not frames then return end

        local now = GetTime()

        for i = 1, MAX_ARENA_ENEMIES do
            local frame = frames[i]
            if frame and frame.drIcons then
                -- FIXED: Process DR expiration for ALL units (alive, dead, or disconnected)
                -- DRs should continue running even if the player dies/leaves
                for _, drFrame in pairs(frame.drIcons) do
                    if drFrame and drFrame:IsShown() and drFrame.activeCooldownStart and drFrame.activeCooldownDuration then
                        local elapsed = now - drFrame.activeCooldownStart
                        local remaining = drFrame.activeCooldownDuration - elapsed

                        if remaining <= 0 then
                            -- FIXED: DR expired - hide icon immediately (works for alive AND dead units)
                            if drFrame.timerText then
                                drFrame.timerText:SetText("")
                            end
                            drFrame:Hide()
                            drFrame.active = false
                            drFrame.diminished = 0  -- FIXED: Use diminished instead of severity
                            drFrame.reset = nil  -- FIXED: Use reset instead of expirationTime
                            drFrame.activeCooldownStart = nil
                            drFrame.activeCooldownDuration = nil
                            drFrame.actualDuration = nil
                            
                            -- CRITICAL FIX: Queue position update when icon expires (collapsing effect with batching)
                            QueuePositionUpdate(frame)
                        elseif drFrame.timerText then
                            -- DR still active - update timer text
                            if remaining <= 4 then
                                drFrame.timerText:SetText(string.format("%.1f", remaining))
                            else
                                drFrame.timerText:SetText(string.format("%d", math.ceil(remaining)))
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================================
-- SOLO SHUFFLE CLEANUP (GROUP_ROSTER_UPDATE)
-- ============================================================================
-- Clear all DR icons between Solo Shuffle rounds
-- Matches pattern used by Trinkets, Racials, Auras, Dispels, KickBar, Blackout

function DR:ClearAllDRs()
    local frames = GetFrames()
    if not frames then return end
    
    -- Clear all DR icons on all frames
    for i = 1, MAX_ARENA_ENEMIES do
        local frame = frames[i]
        if frame and frame.drIcons then
            for category, drFrame in pairs(frame.drIcons) do
                if drFrame then
                    -- Hide the icon
                    drFrame:Hide()
                    
                    -- Clear cooldown
                    if drFrame.cooldown then
                        drFrame.cooldown:Clear()
                    end
                    
                    -- Clear timer text
                    if drFrame.timerText then
                        drFrame.timerText:SetText("")
                    end
                    
                    -- Clear stage text
                    if drFrame.stageText then
                        drFrame.stageText:SetText("")
                    end
                    
                    -- Reset state
                    drFrame.active = false
                    drFrame.severity = 0
                    drFrame.diminished = nil  -- CRITICAL: Reset to nil so next arena starts fresh
                    drFrame.reset = 0  -- CRITICAL: Reset to 0 so next arena treats as expired
                    drFrame.expirationTime = nil
                    drFrame.activeCooldownStart = nil
                    drFrame.activeCooldownDuration = nil
                    drFrame.actualDuration = nil
                end
            end
        end
    end
end

-- Register GROUP_ROSTER_UPDATE event (Solo Shuffle round transitions)
local soloShuffleFrame = CreateFrame("Frame")
soloShuffleFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
soloShuffleFrame:SetScript("OnEvent", function(self, event)
    if event == "GROUP_ROSTER_UPDATE" then
        -- Only clear if we're in arena (Solo Shuffle)
        local _, instanceType = IsInInstance()
        if instanceType == "arena" then
            DR:ClearAllDRs()
        end
    end
end)

local function HookCoreFunctions()
    local ac = GetAC()
    local manager = ac.MasterFrameManager or ac.FrameManager
    if not manager then
        if C_Timer and C_Timer.After then
            C_Timer.After(0.1, HookCoreFunctions)
        end
        return
    end

    if not manager._drModuleHooked then
        manager.CreateDRIcon = function(self, parent, category)
            return DR:CreateIcon(parent, category)
        end

        manager.ShowTestDRIcons = function(self)
            return DR:ShowTestIcons(self)
        end

        manager.HideTestDRIcons = function(self)
            return DR:HideTestIcons(self)
        end

        manager.StartDRTestRefreshTimer = function(self)
            DR:EnsureTestTicker(self)
        end

        manager.StartRealArenaDRTicker = function(self)
            DR:StartRealArenaTicker()
        end

        manager._drModuleHooked = true
    end

    function ac:RefreshDRLayout()
        DR:RefreshLayout()
    end

    function ac:UpdateDRPositions(frame)
        DR:UpdatePositions(frame)
    end
end

HookCoreFunctions()

AC.MasterFrameManager = AC.MasterFrameManager or {}
AC.MasterFrameManager.DR = DR

-- CRITICAL FIX: Also assign to FrameManager for Tracker.lua to find it
AC.FrameManager = AC.FrameManager or AC.MasterFrameManager
AC.FrameManager.DR = DR

return DR
