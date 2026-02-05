local AC = _G.ArenaCore or {}

local function GetAC()
    if _G.ArenaCore and AC ~= _G.ArenaCore then
        AC = _G.ArenaCore
    end
    return AC
end

local AbsorbsMidnight = {}

local absorbStates = {}

local function GetSettings()
    local ac = GetAC()
    return ac.DB and ac.DB.profile and ac.DB.profile.moreGoodies and ac.DB.profile.moreGoodies.absorbs
end

function AbsorbsMidnight:GetTotalAbsorbs(unitToken)
    if not UnitExists(unitToken) then
        return 0
    end
    
    -- Use standard UnitGetTotalAbsorbs (still available in Midnight)
    local totalAbsorbs = UnitGetTotalAbsorbs(unitToken) or 0
    
    return totalAbsorbs
end

function AbsorbsMidnight:ShowAbsorbLines(frameIndex)
    local settings = GetSettings()
    if not settings or not settings.enabled then
        return
    end
    
    local ac = GetAC()
    if not ac.FrameManager or not ac.FrameManager.frames then return end
    
    local frame = ac.FrameManager.frames[frameIndex]
    if not frame or not frame.healthBar then return end
    
    if not frame.liveAbsorbTexture then
        frame.liveAbsorbTexture = CreateFrame("Frame", nil, frame)
        frame.liveAbsorbTexture:SetAllPoints(frame.healthBar)
        frame.liveAbsorbTexture:SetFrameStrata("MEDIUM")
        frame.liveAbsorbTexture:SetFrameLevel(frame.healthBar:GetFrameLevel() + 1)
        
        local fillBar = frame.liveAbsorbTexture:CreateTexture(nil, "BACKGROUND")
        fillBar:SetAllPoints(frame.liveAbsorbTexture)
        fillBar:SetTexture("Interface\\RaidFrame\\Shield-Fill")
        fillBar:SetVertexColor(0.5, 0.8, 1, 0.7)
        fillBar:Show()
        frame.liveAbsorbTexture.fillBar = fillBar
        
        local overlay = frame.liveAbsorbTexture:CreateTexture(nil, "BORDER")
        overlay:SetAllPoints(frame.liveAbsorbTexture)
        overlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay", true, true)
        overlay:SetVertexColor(1, 1, 1, 1)
        overlay:SetAlpha(1.0)
        overlay.tileSize = 32
        overlay:Show()
        frame.liveAbsorbTexture.overlay = overlay
        
        local glow = frame.liveAbsorbTexture:CreateTexture(nil, "BORDER")
        glow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
        glow:SetBlendMode("ADD")
        glow:SetWidth(16)
        glow:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMRIGHT", -7, 0)
        glow:SetPoint("TOPLEFT", frame.healthBar, "TOPRIGHT", -7, 0)
        glow:Hide()
        frame.liveAbsorbTexture.overGlow = glow
    end
    
    frame.liveAbsorbTexture:Show()
    if frame.liveAbsorbTexture.fillBar then frame.liveAbsorbTexture.fillBar:Show() end
    if frame.liveAbsorbTexture.overlay then frame.liveAbsorbTexture.overlay:Show() end
    
    local unit = "arena" .. frameIndex
    if UnitExists(unit) then
        local totalAbsorbs = self:GetTotalAbsorbs(unit)
        local maxHealth = UnitHealthMax(unit) or 1
        local currentHealth = UnitHealth(unit) or 0
        
        if totalAbsorbs > 0 and (currentHealth + totalAbsorbs >= maxHealth) then
            if frame.liveAbsorbTexture.overGlow then
                frame.liveAbsorbTexture.overGlow:Show()
            end
        else
            if frame.liveAbsorbTexture.overGlow then
                frame.liveAbsorbTexture.overGlow:Hide()
            end
        end
    end
end

function AbsorbsMidnight:HideAbsorbLines(frameIndex)
    local ac = GetAC()
    if not ac.FrameManager or not ac.FrameManager.frames then return end
    
    local frame = ac.FrameManager.frames[frameIndex]
    if frame and frame.liveAbsorbTexture then
        frame.liveAbsorbTexture:Hide()
    end
end

function AbsorbsMidnight:CheckAbsorbsOnFrame(frameIndex)
    local settings = GetSettings()
    if not settings or not settings.enabled then
        self:HideAbsorbLines(frameIndex)
        return
    end
    
    local ac = GetAC()
    if not ac.FrameManager or not ac.FrameManager.frames then return end
    
    local frame = ac.FrameManager.frames[frameIndex]
    if not frame then return end
    
    local unit = "arena" .. frameIndex
    
    if UnitExists(unit) then
        local totalAbsorbs = self:GetTotalAbsorbs(unit)
        
        -- CRITICAL FIX: Safely compare totalAbsorbs (may be secret value)
        local hasAbsorb = false
        pcall(function()
            hasAbsorb = totalAbsorbs > 0
        end)
        
        local hasImmunity = false
        if ac.ImmunityTracker and ac.ImmunityTracker.CheckImmunity then
            local immunityType = ac.ImmunityTracker:CheckImmunity(unit)
            hasImmunity = (immunityType ~= nil)
        end
        
        local shouldShowLines = hasAbsorb or hasImmunity
        
        if absorbStates[frameIndex] ~= shouldShowLines then
            absorbStates[frameIndex] = shouldShowLines
            
            if shouldShowLines then
                self:ShowAbsorbLines(frameIndex)
            else
                self:HideAbsorbLines(frameIndex)
            end
        end
    else
        if absorbStates[frameIndex] ~= false then
            absorbStates[frameIndex] = false
            self:HideAbsorbLines(frameIndex)
        end
    end
end

function AbsorbsMidnight:UpdateAllAbsorbs()
    for i = 1, 3 do
        self:CheckAbsorbsOnFrame(i)
    end
end

function AbsorbsMidnight:Initialize()
    if self.initialized then return true end
    
    -- Check if UnitGetTotalAbsorbs is available
    if not UnitGetTotalAbsorbs then
        print("|cffFF0000[Absorbs Midnight]|r UnitGetTotalAbsorbs API not available")
        return false
    end
    
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        
        self.eventFrame:RegisterEvent("UNIT_HEALTH")
        self.eventFrame:RegisterEvent("UNIT_MAXHEALTH")
        self.eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
        self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        
        self.eventFrame:SetScript("OnEvent", function(_, event, ...)
            if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
                local unit = ...
                if unit and unit:match("^arena%d$") then
                    local frameIndex = tonumber(unit:match("arena(%d)"))
                    if frameIndex then
                        AbsorbsMidnight:CheckAbsorbsOnFrame(frameIndex)
                    end
                end
            elseif event == "ARENA_OPPONENT_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
                C_Timer.After(0.5, function()
                    AbsorbsMidnight:UpdateAllAbsorbs()
                end)
            end
        end)
    end
    
    if not self.ticker then
        self.ticker = C_Timer.NewTicker(0.5, function()
            local _, instanceType = IsInInstance()
            if instanceType == "arena" then
                AbsorbsMidnight:UpdateAllAbsorbs()
            end
        end)
    end
    
    self.initialized = true
    -- Midnight absorbs tracking enabled silently
    return true
end

function AbsorbsMidnight:Cleanup()
    absorbStates = {}
end

AC.AbsorbsMidnight = AbsorbsMidnight

local function TryInitialize()
    local ac = GetAC()
    
    if not ac.Midnight or not ac.Midnight.isMidnight then
        return
    end
    
    if AbsorbsMidnight:Initialize() then
    else
        print("|cff8B45FFArena|r|cffB266FFCore|r |cffFF0000Midnight absorbs tracking failed to initialize|r")
    end
end

C_Timer.After(1, TryInitialize)

if AC.Midnight and AC.Midnight.isMidnight then
    TryInitialize()
end

return AbsorbsMidnight
