--[[
    Gladius Midnight - Custom Settings UI
    A dark-themed settings panel with sidebar tabs.
    Replaces the AceConfig dialog with a hand-crafted GUI.
    All settings from Config.lua are preserved and wired up.
]]

local addonName = "GladiusMidnight"
local LSM = LibStub("LibSharedMedia-3.0")

-----------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------
local PANEL_W, PANEL_H = 840, 600
local SIDEBAR_W = 175
local TOPBAR_H = 52
local PAD = 12
local ROW_H = 28
local SLIDER_W = 180
local DROPDOWN_W = 180
local CHECK_SIZE = 18

-----------------------------------------------------------------------
-- Color palette
-----------------------------------------------------------------------
local C = {
    bg        = CreateColor(0.06, 0.06, 0.06, 0.97),
    sidebar   = CreateColor(0.04, 0.04, 0.04, 1),
    tabNorm   = CreateColor(0.11, 0.11, 0.11, 1),
    tabHover  = CreateColor(0.18, 0.18, 0.18, 1),
    tabActive = CreateColor(0.06, 0.40, 0.06, 0.95),
    accent    = CreateColor(0.00, 0.80, 0.00, 1),
    title     = CreateColor(1, 1, 1, 1),
    header    = CreateColor(0.85, 0.85, 0.85, 1),
    text      = CreateColor(0.78, 0.78, 0.78, 1),
    sub       = CreateColor(0.50, 0.50, 0.50, 1),
    divider   = CreateColor(0.20, 0.20, 0.20, 1),
    inputBg   = CreateColor(0.10, 0.10, 0.10, 1),
    sliderBg  = CreateColor(0.14, 0.14, 0.14, 1),
    sliderFill= CreateColor(0.00, 0.65, 0.00, 0.85),
    btnBg     = CreateColor(0.14, 0.14, 0.14, 1),
    btnHover  = CreateColor(0.22, 0.22, 0.22, 1),
    checkOn   = CreateColor(0.00, 0.75, 0.00, 1),
    checkOff  = CreateColor(0.25, 0.25, 0.25, 1),
    red       = CreateColor(0.90, 0.20, 0.20, 1),
}

-----------------------------------------------------------------------
-- DB accessors (same paths as Config.lua)
-----------------------------------------------------------------------
local function getProfile()
    return GladiusMidnight and GladiusMidnight.db and GladiusMidnight.db.profile
end

local function getLS()
    local p = getProfile()
    if not p then return nil end
    local ln = p.currentLayout or "Gladiuish"
    p.layoutSettings[ln] = p.layoutSettings[ln] or {}
    return p.layoutSettings[ln]
end

local function ensureTable(parent, key)
    if not parent[key] then parent[key] = {} end
    return parent[key]
end

-- Deep get: getNested(tbl, "a.b.c") -> tbl.a.b.c
local function getNested(root, path)
    local cur = root
    for segment in path:gmatch("[^%.]+") do
        if type(cur) ~= "table" then return nil end
        cur = cur[segment]
    end
    return cur
end

-- Deep set: setNested(tbl, "a.b.c", val)
local function setNested(root, path, val)
    local parts = {}
    for segment in path:gmatch("[^%.]+") do
        parts[#parts + 1] = segment
    end
    local cur = root
    for i = 1, #parts - 1 do
        if type(cur[parts[i]]) ~= "table" then
            cur[parts[i]] = {}
        end
        cur = cur[parts[i]]
    end
    cur[parts[#parts]] = val
end

-----------------------------------------------------------------------
-- Refresh helpers
-----------------------------------------------------------------------
local function refreshConfig()
    if GladiusMidnight and GladiusMidnight.RefreshConfig then
        GladiusMidnight:RefreshConfig()
    end
end

local function refreshTest()
    if not GladiusMidnight or not GladiusMidnight.Test then return end
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" and GladiusMidnight.arena1
       and GladiusMidnight.arena1:IsShown() then
        GladiusMidnight:Test()
    end
end

local function refreshFrameColors()
    if not GladiusMidnight then return end
    for i = 1, GladiusMidnight.maxArenaOpponents do
        local f = GladiusMidnight["arena" .. i]
        if f and f.UpdateFrameColors then f:UpdateFrameColors() end
    end
end

local function refreshStatusText()
    if not GladiusMidnight then return end
    for i = 1, GladiusMidnight.maxArenaOpponents do
        local f = GladiusMidnight["arena" .. i]
        if f and f.UpdateStatusTextVisible then f:UpdateStatusTextVisible() end
    end
end

-----------------------------------------------------------------------
-- Tooltip helper
-----------------------------------------------------------------------
local function ShowTip(frame, title, text)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 1, 1)
    if text then GameTooltip:AddLine(text, 0.8, 0.8, 0.8, true) end
    GameTooltip:Show()
end

-----------------------------------------------------------------------
-- Layout list
-----------------------------------------------------------------------
local function getLayoutTable()
    local t = {}
    for k, v in pairs(GladiusMixin.layouts) do
        t[#t + 1] = { key = k, name = (v.name or k) }
    end
    table.sort(t, function(a, b) return a.name < b.name end)
    return t
end

-----------------------------------------------------------------------
-- DR category display
-----------------------------------------------------------------------
local function getDRCategoryDisplay()
    local t = {}
    for _, cat in ipairs(GladiusMixin.drCategories or {}) do
        local tex = GladiusMixin.drIcons and GladiusMixin.drIcons[cat]
        t[#t + 1] = { key = cat, icon = tex }
    end
    return t
end

-----------------------------------------------------------------------
-- StatusBar media list
-----------------------------------------------------------------------
local function getStatusBarList()
    local t = {}
    for k in pairs(LSM:HashTable(LSM.MediaType.STATUSBAR)) do
        t[#t + 1] = k
    end
    table.sort(t)
    return t
end

local function getFontList()
    local t = {}
    for k in pairs(LSM:HashTable(LSM.MediaType.FONT)) do
        t[#t + 1] = k
    end
    table.sort(t)
    return t
end

-----------------------------------------------------------------------
-- WIDGET FACTORIES
-- Each factory creates a control, anchors it, returns (widget, height).
-- All controls are created as children of a scrollChild frame.
-----------------------------------------------------------------------

local widgetID = 0
local function nextID()
    widgetID = widgetID + 1
    return widgetID
end

-- ===== HEADER =====
local function CreateSettingsHeader(parent, yOff, label)
    local h = ROW_H + 6
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth() - PAD * 2, h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, yOff)

    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", 0, 0)
    line:SetColorTexture(C.divider:GetRGBA())

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("BOTTOMLEFT", 0, 6)
    text:SetText(label)
    text:SetTextColor(C.accent:GetRGBA())

    return frame, h
end

-- ===== DESCRIPTION =====
local function CreateSettingsDesc(parent, yOff, label)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, yOff)
    fs:SetWidth(parent:GetWidth() - PAD * 2)
    fs:SetJustifyH("LEFT")
    fs:SetText(label)
    fs:SetTextColor(C.sub:GetRGBA())
    local h = fs:GetStringHeight() + 6
    return fs, h
end

-- ===== CHECKBOX =====
local function CreateSettingsCheckbox(parent, yOff, def)
    local id = nextID()
    local frame = CreateFrame("Frame", "GladiusSettingsCheck" .. id, parent)
    frame:SetSize(parent:GetWidth() - PAD * 2, ROW_H)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, yOff)

    -- Check box
    local box = CreateFrame("Frame", nil, frame)
    box:SetSize(CHECK_SIZE, CHECK_SIZE)
    box:SetPoint("LEFT", 0, 0)

    local boxBg = box:CreateTexture(nil, "BACKGROUND")
    boxBg:SetAllPoints()
    boxBg:SetColorTexture(C.checkOff:GetRGBA())
    box.bg = boxBg

    local checkMark = box:CreateTexture(nil, "OVERLAY")
    checkMark:SetSize(CHECK_SIZE - 4, CHECK_SIZE - 4)
    checkMark:SetPoint("CENTER")
    checkMark:SetAtlas("checkmark-minimal")
    checkMark:SetDesaturated(true)
    checkMark:SetVertexColor(1, 1, 1)
    checkMark:Hide()
    box.check = checkMark

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", box, "RIGHT", 8, 0)
    label:SetText(def.label)
    label:SetTextColor(C.text:GetRGBA())

    -- State
    local function updateVisual()
        local val = def.get()
        if val then
            boxBg:SetColorTexture(C.checkOn:GetRGBA())
            checkMark:Show()
        else
            boxBg:SetColorTexture(C.checkOff:GetRGBA())
            checkMark:Hide()
        end
        local disabled = def.disabled and def.disabled()
        if disabled then
            frame:SetAlpha(0.4)
        else
            frame:SetAlpha(1)
        end
    end
    frame.Refresh = updateVisual

    -- Click
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function()
        if def.disabled and def.disabled() then return end
        if InCombatLockdown() then return end
        local cur = def.get()
        def.set(not cur)
        updateVisual()
        -- Also refresh sibling controls in the same tab (disabled states etc.)
        if frame:GetParent().RefreshAll then
            frame:GetParent():RefreshAll()
        end
    end)

    -- Tooltip
    if def.desc then
        frame:SetScript("OnEnter", function(self) ShowTip(self, def.label, def.desc) end)
        frame:SetScript("OnLeave", GameTooltip_Hide)
    end

    updateVisual()
    return frame, ROW_H
end

-- ===== SLIDER =====
local function CreateSettingsSlider(parent, yOff, def)
    local id = nextID()
    local h = ROW_H + 22
    local frame = CreateFrame("Frame", "GladiusSettingsSlider" .. id, parent)
    frame:SetSize(parent:GetWidth() - PAD * 2, h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, yOff)

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(def.label)
    label:SetTextColor(C.text:GetRGBA())

    -- Value text
    local valText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valText:SetPoint("TOPRIGHT", 0, 0)
    valText:SetTextColor(C.accent:GetRGBA())

    -- Slider
    local slider = CreateFrame("Slider", "GladiusSettingsSliderCtrl" .. id, frame, "OptionsSliderTemplate")
    slider:SetSize(SLIDER_W, 16)
    slider:SetPoint("TOPLEFT", 0, -18)
    slider:SetMinMaxValues(def.min, def.max)
    slider:SetValueStep(def.step or 1)
    slider:SetObeyStepOnDrag(true)

    -- Hide default labels
    local sliderName = slider:GetName()
    if sliderName then
        local low = _G[sliderName .. "Low"]
        local high = _G[sliderName .. "High"]
        local txt = _G[sliderName .. "Text"]
        if low then low:SetText("") end
        if high then high:SetText("") end
        if txt then txt:SetText("") end
    end

    local function formatVal(v)
        if def.isPercent then return string.format("%.0f%%", v * 100) end
        if def.step and def.step < 1 then return string.format("%.2f", v) end
        return string.format("%.0f", v)
    end

    local function updateVisual()
        local v = def.get()
        if v == nil then v = def.min end
        v = max(def.min, min(def.max, v))
        slider:SetValue(v)
        valText:SetText(formatVal(v))
        local disabled = def.disabled and def.disabled()
        frame:SetAlpha(disabled and 0.4 or 1)
        if disabled then
            slider:EnableMouse(false)
        else
            slider:EnableMouse(true)
        end
    end
    frame.Refresh = updateVisual

    slider:SetScript("OnValueChanged", function(_, v)
        if def.disabled and def.disabled() then return end
        v = tonumber(string.format("%." .. (def.decimals or (def.step < 1 and 2 or 0)) .. "f", v))
        valText:SetText(formatVal(v))
        def.set(v)
    end)

    if def.desc then
        frame:SetScript("OnEnter", function(self) ShowTip(self, def.label, def.desc) end)
        frame:SetScript("OnLeave", GameTooltip_Hide)
    end

    updateVisual()
    return frame, h
end

-- ===== DROPDOWN =====
local function CreateSettingsDropdown(parent, yOff, def)
    local id = nextID()
    local h = ROW_H + 26
    local frame = CreateFrame("Frame", "GladiusSettingsDrop" .. id, parent)
    frame:SetSize(parent:GetWidth() - PAD * 2, h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, yOff)

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(def.label)
    label:SetTextColor(C.text:GetRGBA())

    -- Button background
    local btn = CreateFrame("Button", "GladiusSettingsDropBtn" .. id, frame)
    btn:SetSize(DROPDOWN_W, 22)
    btn:SetPoint("TOPLEFT", 0, -18)

    local btnBg = btn:CreateTexture(nil, "BACKGROUND")
    btnBg:SetAllPoints()
    btnBg:SetColorTexture(C.inputBg:GetRGBA())

    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btnText:SetPoint("LEFT", 6, 0)
    btnText:SetPoint("RIGHT", -20, 0)
    btnText:SetJustifyH("LEFT")
    btnText:SetTextColor(C.text:GetRGBA())

    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(12, 12)
    arrow:SetPoint("RIGHT", -4, 0)
    arrow:SetAtlas("arrow-down-active")

    -- Dropdown list (created on demand)
    local listFrame

    local function closeList()
        if listFrame then listFrame:Hide() end
    end

    local function updateVisual()
        local curVal = def.get()
        local values = type(def.values) == "function" and def.values() or def.values
        -- values can be {key=display,...} or {{key=k,name=n},...}
        local displayText = tostring(curVal) or ""
        if type(values) == "table" then
            if values[1] and type(values[1]) == "table" then
                for _, entry in ipairs(values) do
                    if entry.key == curVal then displayText = entry.name; break end
                end
            else
                for k, v in pairs(values) do
                    if k == curVal then displayText = tostring(v); break end
                end
            end
        end
        btnText:SetText(displayText)
        local disabled = def.disabled and def.disabled()
        frame:SetAlpha(disabled and 0.4 or 1)
    end
    frame.Refresh = updateVisual

    btn:SetScript("OnClick", function()
        if def.disabled and def.disabled() then return end
        if listFrame and listFrame:IsShown() then closeList(); return end

        local values = type(def.values) == "function" and def.values() or def.values
        -- Build ordered list
        local items = {}
        if type(values) == "table" then
            if values[1] and type(values[1]) == "table" then
                items = values
            else
                for k, v in pairs(values) do
                    items[#items + 1] = { key = k, name = tostring(v) }
                end
                table.sort(items, function(a, b) return a.name < b.name end)
            end
        end

        if not listFrame then
            listFrame = CreateFrame("Frame", "GladiusSettingsDropList" .. id, btn)
            listFrame:SetFrameStrata("TOOLTIP")
            listFrame:SetClampedToScreen(true)
            local listBg = listFrame:CreateTexture(nil, "BACKGROUND")
            listBg:SetAllPoints()
            listBg:SetColorTexture(0.08, 0.08, 0.08, 0.98)
            local listBorder = CreateFrame("Frame", nil, listFrame, "BackdropTemplate")
            listBorder:SetAllPoints()
            listBorder:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            listBorder:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            listFrame.items = {}
        end

        -- Clear old items
        for _, item in ipairs(listFrame.items) do item:Hide() end
        wipe(listFrame.items)

        local maxShow = min(#items, 15)
        local itemH = 20
        local totalH = maxShow * itemH

        listFrame:SetSize(DROPDOWN_W, totalH + 2)
        listFrame:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -1)

        -- If we need a scroll, add scroll child
        local listContent = listFrame
        if #items > 15 then
            if not listFrame.scroll then
                local sf = CreateFrame("ScrollFrame", nil, listFrame, "UIPanelScrollFrameTemplate")
                sf:SetPoint("TOPLEFT", 1, -1)
                sf:SetPoint("BOTTOMRIGHT", -18, 1)
                local sc = CreateFrame("Frame", nil, sf)
                sc:SetWidth(DROPDOWN_W - 20)
                sf:SetScrollChild(sc)
                listFrame.scroll = sf
                listFrame.scrollChild = sc
            end
            listFrame.scroll:Show()
            listFrame.scrollChild:SetHeight(#items * itemH)
            listContent = listFrame.scrollChild
            listFrame:SetSize(DROPDOWN_W + 18, totalH + 2)
        else
            if listFrame.scroll then listFrame.scroll:Hide() end
        end

        local curVal = def.get()
        for idx, entry in ipairs(items) do
            local itemBtn = CreateFrame("Button", nil, listContent)
            itemBtn:SetSize(listContent:GetWidth(), itemH)
            itemBtn:SetPoint("TOPLEFT", 1, -((idx - 1) * itemH))

            local itemBg = itemBtn:CreateTexture(nil, "BACKGROUND")
            itemBg:SetAllPoints()
            itemBg:SetColorTexture(0, 0, 0, 0)

            local itemText = itemBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            itemText:SetPoint("LEFT", 6, 0)
            itemText:SetText(entry.name)
            if entry.key == curVal then
                itemText:SetTextColor(C.accent:GetRGBA())
            else
                itemText:SetTextColor(C.text:GetRGBA())
            end

            itemBtn:SetScript("OnEnter", function()
                itemBg:SetColorTexture(0.2, 0.2, 0.2, 0.6)
            end)
            itemBtn:SetScript("OnLeave", function()
                itemBg:SetColorTexture(0, 0, 0, 0)
            end)
            itemBtn:SetScript("OnClick", function()
                def.set(entry.key)
                closeList()
                updateVisual()
                if frame:GetParent().RefreshAll then
                    frame:GetParent():RefreshAll()
                end
            end)

            listFrame.items[#listFrame.items + 1] = itemBtn
        end

        listFrame:Show()
    end)

    -- Close dropdown when clicking elsewhere
    btn:SetScript("OnHide", closeList)

    if def.desc then
        frame:SetScript("OnEnter", function(self) ShowTip(self, def.label, def.desc) end)
        frame:SetScript("OnLeave", GameTooltip_Hide)
    end

    updateVisual()
    return frame, h
end

-- ===== COLOR PICKER =====
local function CreateSettingsColor(parent, yOff, def)
    local id = nextID()
    local frame = CreateFrame("Frame", "GladiusSettingsColor" .. id, parent)
    frame:SetSize(parent:GetWidth() - PAD * 2, ROW_H)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, yOff)

    -- Swatch
    local swatch = CreateFrame("Button", nil, frame)
    swatch:SetSize(22, 22)
    swatch:SetPoint("LEFT", 0, 0)

    local swatchBorder = swatch:CreateTexture(nil, "BACKGROUND")
    swatchBorder:SetAllPoints()
    swatchBorder:SetColorTexture(0.3, 0.3, 0.3, 1)

    local swatchColor = swatch:CreateTexture(nil, "ARTWORK")
    swatchColor:SetPoint("TOPLEFT", 1, -1)
    swatchColor:SetPoint("BOTTOMRIGHT", -1, 1)
    swatch.colorTex = swatchColor

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
    label:SetText(def.label)
    label:SetTextColor(C.text:GetRGBA())

    local function updateVisual()
        local r, g, b, a = def.get()
        swatchColor:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
    end
    frame.Refresh = updateVisual

    swatch:SetScript("OnClick", function()
        local r, g, b, a = def.get()
        local info = {}
        info.r, info.g, info.b = r or 1, g or 1, b or 1
        info.opacity = 1 - (a or 1)
        info.hasOpacity = def.hasAlpha
        info.swatchFunc = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            local na = 1 - (info.hasOpacity and ColorPickerFrame:GetColorAlpha() or 0)
            def.set(nr, ng, nb, na)
            updateVisual()
        end
        info.cancelFunc = function(prev)
            def.set(prev.r, prev.g, prev.b, 1 - (prev.opacity or 0))
            updateVisual()
        end
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)

    if def.desc then
        frame:SetScript("OnEnter", function(self) ShowTip(self, def.label, def.desc) end)
        frame:SetScript("OnLeave", GameTooltip_Hide)
    end

    updateVisual()
    return frame, ROW_H
end

-- ===== BUTTON =====
local function CreateSettingsButton(parent, yOff, def)
    local id = nextID()
    local frame = CreateFrame("Button", "GladiusSettingsBtn" .. id, parent)
    frame:SetSize(def.width or 140, 26)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, yOff)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(C.btnBg:GetRGBA())

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("CENTER")
    text:SetText(def.label)
    text:SetTextColor(C.text:GetRGBA())

    frame:SetScript("OnEnter", function()
        bg:SetColorTexture(C.btnHover:GetRGBA())
    end)
    frame:SetScript("OnLeave", function()
        bg:SetColorTexture(C.btnBg:GetRGBA())
        GameTooltip:Hide()
    end)
    frame:SetScript("OnClick", function()
        if InCombatLockdown() then return end
        def.func()
    end)

    frame.Refresh = function() end
    return frame, ROW_H + 4
end

-- ===== MULTISELECT (checkboxes in a grid) =====
local function CreateSettingsMultiSelect(parent, yOff, def)
    local id = nextID()
    local items = type(def.values) == "function" and def.values() or def.values
    local cols = 2
    local rowsPer = math.ceil(#items / cols)
    local totalH = rowsPer * (ROW_H - 2) + 8

    local frame = CreateFrame("Frame", "GladiusSettingsMulti" .. id, parent)
    frame:SetSize(parent:GetWidth() - PAD * 2, totalH)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, yOff)

    frame._checks = {}
    local colW = (frame:GetWidth() - 10) / cols

    for idx, entry in ipairs(items) do
        local col = (idx - 1) % cols
        local row = math.floor((idx - 1) / cols)
        local cx = col * colW
        local cy = -(row * (ROW_H - 2))

        local check = CreateFrame("Frame", nil, frame)
        check:SetSize(colW, ROW_H - 4)
        check:SetPoint("TOPLEFT", cx, cy)

        local box = CreateFrame("Frame", nil, check)
        box:SetSize(CHECK_SIZE - 2, CHECK_SIZE - 2)
        box:SetPoint("LEFT", 0, 0)

        local boxBg = box:CreateTexture(nil, "BACKGROUND")
        boxBg:SetAllPoints()
        box.bg = boxBg

        local checkMark = box:CreateTexture(nil, "OVERLAY")
        checkMark:SetSize(CHECK_SIZE - 6, CHECK_SIZE - 6)
        checkMark:SetPoint("CENTER")
        checkMark:SetAtlas("checkmark-minimal")
        checkMark:SetDesaturated(true)
        checkMark:SetVertexColor(1, 1, 1)
        checkMark:Hide()
        box.check = checkMark

        -- Icon + name
        local labelText = entry.key
        if entry.icon then
            labelText = "|T" .. tostring(entry.icon) .. ":14|t " .. entry.key
        end

        local lbl = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("LEFT", box, "RIGHT", 4, 0)
        lbl:SetText(labelText)
        lbl:SetTextColor(C.text:GetRGBA())

        local function updateCheck()
            local val = def.get(entry.key)
            if val or val == nil then -- nil means default enabled
                boxBg:SetColorTexture(C.checkOn:GetRGBA())
                checkMark:Show()
            else
                boxBg:SetColorTexture(C.checkOff:GetRGBA())
                checkMark:Hide()
            end
        end

        check:EnableMouse(true)
        check:SetScript("OnMouseDown", function()
            local cur = def.get(entry.key)
            if cur == nil then cur = true end
            def.set(entry.key, not cur)
            updateCheck()
        end)

        check.Refresh = updateCheck
        frame._checks[#frame._checks + 1] = check
        updateCheck()
    end

    frame.Refresh = function()
        for _, ch in ipairs(frame._checks) do
            if ch.Refresh then ch:Refresh() end
        end
    end

    return frame, totalH
end

-- ===== SPACER =====
local function CreateSettingsSpacer(parent, yOff, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(1, height or 8)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOff)
    frame.Refresh = function() end
    return frame, height or 8
end

-----------------------------------------------------------------------
-- TAB DEFINITIONS (data tables)
-- source: "profile" = db.profile, "layout" = getLS()
-- For nested keys use dot notation: "statusText.alwaysShow"
-----------------------------------------------------------------------

local function profileGet(key)
    return function()
        local p = getProfile()
        if not p then return nil end
        return getNested(p, key)
    end
end
local function profileSet(key, afterFn)
    return function(val)
        local p = getProfile()
        if not p then return end
        setNested(p, key, val)
        if afterFn then afterFn() end
    end
end

local function layoutGet(key)
    return function()
        local ls = getLS()
        if not ls then return nil end
        return getNested(ls, key)
    end
end
local function layoutSet(key, afterFn)
    return function(val)
        local ls = getLS()
        if not ls then return end
        setNested(ls, key, val)
        if afterFn then afterFn() end
    end
end

-- Shorthand for common patterns
local function pToggle(label, key, desc, afterFn, disabledFn)
    return {
        type = "checkbox",
        label = label,
        desc = desc,
        get = profileGet(key),
        set = profileSet(key, afterFn),
        disabled = disabledFn,
    }
end

local function lToggle(label, key, desc, afterFn, disabledFn)
    return {
        type = "checkbox",
        label = label,
        desc = desc,
        get = layoutGet(key),
        set = layoutSet(key, afterFn),
        disabled = disabledFn,
    }
end

local function pSlider(label, key, desc, mn, mx, step, afterFn, opts)
    opts = opts or {}
    return {
        type = "slider",
        label = label,
        desc = desc,
        min = mn, max = mx, step = step,
        isPercent = opts.isPercent,
        get = profileGet(key),
        set = profileSet(key, afterFn),
        disabled = opts.disabled,
    }
end

local function lSlider(label, key, desc, mn, mx, step, afterFn, opts)
    opts = opts or {}
    return {
        type = "slider",
        label = label,
        desc = desc,
        min = mn, max = mx, step = step,
        isPercent = opts.isPercent,
        get = layoutGet(key),
        set = layoutSet(key, afterFn),
        disabled = opts.disabled,
    }
end

-- Refresh combined
local function rfConfigTest() refreshConfig(); refreshTest() end
local function rfColors() refreshFrameColors() end
local function rfColorsTest() refreshFrameColors(); refreshTest() end
local function rfTest() refreshTest() end
local function rfStatus() refreshStatusText() end

-----------------------------------------------------------------------
-- TAB 1: GENERAL
-----------------------------------------------------------------------
local tabGeneral = {
    name = "General",
    icon = 136243, -- Spell_Holy_MagicalSentry
    controls = {
        { type = "header", label = "Health Bars" },
        pToggle("Class Colored Health Bars", "classColors",
            "Color health bars by class color instead of green.", rfConfigTest),
        { type = "header", label = "Names" },
        pToggle("Show Player Names", "showNames",
            "Display opponent names on frames.", rfTest),
        { type = "header", label = "Dark Mode" },
        pToggle("Enable Dark Mode", "darkMode",
            "Darken frame borders and textures.", rfColorsTest),
        pSlider("Darkness", "darkModeValue",
            "How dark the frame borders should be (0 = black, 1 = white).",
            0, 1, 0.01, rfColors,
            { disabled = function() local p = getProfile(); return not (p and p.darkMode) end }),
        pToggle("Desaturate in Dark Mode", "darkModeDesaturate",
            "Desaturate frame textures in dark mode.", rfColors,
            function() local p = getProfile(); return not (p and p.darkMode) end),
        { type = "header", label = "Status Text" },
        {
            type = "checkbox",
            label = "Always Show",
            desc = "Always show health/power text instead of on mouseover only.",
            get = profileGet("statusText.alwaysShow"),
            set = profileSet("statusText.alwaysShow", rfStatus),
        },
        {
            type = "checkbox",
            label = "Format Numbers",
            desc = "Abbreviate large health values (e.g. 500K).",
            get = profileGet("statusText.formatNumbers"),
            set = function(val)
                local p = getProfile(); if not p then return end
                ensureTable(p, "statusText")
                p.statusText.formatNumbers = val
                if val then p.statusText.usePercentage = false end
                rfTest()
            end,
        },
        {
            type = "checkbox",
            label = "Use Percentage",
            desc = "Show health and power as percentage values.",
            get = profileGet("statusText.usePercentage"),
            set = function(val)
                local p = getProfile(); if not p then return end
                ensureTable(p, "statusText")
                p.statusText.usePercentage = val
                if val then p.statusText.formatNumbers = false end
                rfTest()
            end,
        },
        lToggle("Hide Status Text", "hideStatusText",
            "Completely hide all health/power text.", rfTest),
        pToggle("Hide Power Text", "hidePowerText",
            "Hide power bar text (mana/energy/rage numbers).", rfStatus),
        { type = "header", label = "Miscellaneous" },
        pSlider("Stealth Alpha", "stealthAlpha",
            "Transparency of frames for stealthed opponents.",
            0, 1, 0.05, function()
                local p = getProfile()
                if p and GladiusMidnight then
                    GladiusMidnight.stealthAlpha = p.stealthAlpha or 0.4
                end
            end),
        pToggle("Shadowsight Timer", "shadowSightTimer",
            "Show a timer for Shadowsight orb spawns in arena."),
        { type = "header", label = "Test Mode" },
        pSlider("Number of Test Units", "testUnits",
            "How many arena frames to show in test mode.", 1, 3, 1),
    },
}

-----------------------------------------------------------------------
-- TAB 2: CLASS ICON
-----------------------------------------------------------------------
local tabClassIcon = {
    name = "Class Icon",
    icon = 132089, -- INV_Misc_QuestionMark (class portrait)
    controls = {
        { type = "header", label = "Display" },
        lToggle("Hide Class Icon", "hideClassIcon",
            "Hide the class icon completely.", rfConfigTest),
        lToggle("Replace with Spec Icon", "replaceClassIcon",
            "Show the specialization icon instead of the class icon.", rfConfigTest,
            function() local ls = getLS(); return ls and ls.hideClassIcon end),
        lToggle("Show Healer Icon", "showHealerIcon",
            "Display a healer role icon for healer specializations.", rfConfigTest,
            function() local ls = getLS(); return ls and (ls.hideClassIcon or ls.replaceClassIcon) end),
        lToggle("Crop Icons", "cropIcons",
            "Slightly crop class/spec icons to remove border artifacts.", rfConfigTest),
        { type = "header", label = "Cooldown Display" },
        pToggle("Invert Cooldown Swipe", "invertClassIconCooldown",
            "Reverse the direction of the cooldown swipe animation.", function()
                if not GladiusMidnight then return end
                for i = 1, GladiusMidnight.maxArenaOpponents do
                    local f = GladiusMidnight["arena" .. i]
                    if f and f.UpdateClassIconCooldownReverse then
                        f:UpdateClassIconCooldownReverse()
                    end
                end
            end),
        pToggle("Show Decimal Countdown", "showDecimalsClassIcon",
            "Display cooldown time with decimal precision.", function()
                if GladiusMidnight and GladiusMidnight.SetupCustomCD then
                    GladiusMidnight:SetupCustomCD()
                end
            end),
        pSlider("Decimal Threshold", "decimalThreshold",
            "Show decimals only when remaining time is below this threshold.",
            1, 10, 0.1, function()
                if GladiusMidnight then
                    GladiusMidnight:UpdateDecimalThreshold()
                    GladiusMidnight:SetupCustomCD()
                end
            end, { disabled = function() local p = getProfile(); return not (p and p.showDecimalsClassIcon) end }),
    },
}

-----------------------------------------------------------------------
-- TAB 3: CASTBAR
-----------------------------------------------------------------------
local tabCastBar = {
    name = "CastBar",
    icon = 136170, -- Spell_Shadow_ChillTouch (castbar icon)
    controls = {
        { type = "header", label = "CastBar Style" },
        lToggle("Modern CastBar", "modernCastbar",
            "Use the modern Blizzard-style castbar appearance.", function()
                if GladiusMidnight then GladiusMidnight:ModernOrClassicCastbar() end
                rfTest()
            end),
        lToggle("Simple CastBar", "simpleCastbar",
            "Simplified castbar with fewer visual elements.", function()
                if GladiusMidnight then GladiusMidnight:ModernOrClassicCastbar() end
                rfTest()
            end, function() local ls = getLS(); return not (ls and ls.modernCastbar) end),
        lToggle("Keep Default Modern Textures", "keepDefaultModernTextures",
            "Keep Blizzard's default textures instead of applying custom ones.", function()
                if GladiusMidnight then GladiusMidnight:UpdateTextures() end
                rfTest()
            end, function() local ls = getLS(); return not (ls and ls.modernCastbar) end),
        { type = "header", label = "CastBar Colors" },
        { type = "desc", label = "Customize the colors for different cast bar states." },
        {
            type = "color", label = "Standard Cast", hasAlpha = true,
            desc = "Color for interruptible casts.",
            get = function()
                local p = getProfile()
                local c = p and p.castBarColors and p.castBarColors.standard
                if c then return c[1], c[2], c[3], c[4] end
                return 1.0, 0.7, 0.0, 1
            end,
            set = function(r, g, b, a)
                local p = getProfile(); if not p then return end
                ensureTable(p, "castBarColors")
                p.castBarColors.standard = { r, g, b, a }
                if GladiusMidnight then GladiusMidnight.castbarColors = p.castBarColors end
                rfTest()
            end,
        },
        {
            type = "color", label = "Channeled Cast", hasAlpha = true,
            desc = "Color for channeled spells.",
            get = function()
                local p = getProfile()
                local c = p and p.castBarColors and p.castBarColors.channel
                if c then return c[1], c[2], c[3], c[4] end
                return 0.0, 1.0, 0.0, 1
            end,
            set = function(r, g, b, a)
                local p = getProfile(); if not p then return end
                ensureTable(p, "castBarColors")
                p.castBarColors.channel = { r, g, b, a }
                if GladiusMidnight then GladiusMidnight.castbarColors = p.castBarColors end
                rfTest()
            end,
        },
        {
            type = "color", label = "Uninterruptible", hasAlpha = true,
            desc = "Color for casts that cannot be interrupted.",
            get = function()
                local p = getProfile()
                local c = p and p.castBarColors and p.castBarColors.uninterruptable
                if c then return c[1], c[2], c[3], c[4] end
                return 0.7, 0.7, 0.7, 1
            end,
            set = function(r, g, b, a)
                local p = getProfile(); if not p then return end
                ensureTable(p, "castBarColors")
                p.castBarColors.uninterruptable = { r, g, b, a }
                if GladiusMidnight then GladiusMidnight.castbarColors = p.castBarColors end
                rfTest()
            end,
        },
        {
            type = "color", label = "Interrupt Not Ready", hasAlpha = true,
            desc = "Color shown when your interrupt is on cooldown.",
            get = function()
                local p = getProfile()
                local c = p and p.castBarColors and p.castBarColors.interruptNotReady
                if c then return c[1], c[2], c[3], c[4] end
                return 1.0, 0.0, 0.0, 1
            end,
            set = function(r, g, b, a)
                local p = getProfile(); if not p then return end
                ensureTable(p, "castBarColors")
                p.castBarColors.interruptNotReady = { r, g, b, a }
                if GladiusMidnight then GladiusMidnight.castbarColors = p.castBarColors end
                rfTest()
            end,
        },
    },
}

-----------------------------------------------------------------------
-- TAB 4: TRINKET / RACIAL
-----------------------------------------------------------------------
local tabTrinket = {
    name = "Trinket / Racial",
    icon = 1322720, -- INV_Jewelry_TrinketPVP (trinket icon)
    controls = {
        { type = "header", label = "Display" },
        lToggle("Show Racial Ability", "showRacial",
            "Display the racial ability icon next to the trinket.", rfConfigTest),
        pToggle("Swap Racial / Trinket Position", "swapRacialTrinket",
            "Swap the positions of the racial and PvP trinket icons.", rfConfigTest),
        pToggle("Desaturate Trinket on Cooldown", "desaturateTrinketCD",
            "Gray out the trinket icon while it is on cooldown."),
        {
            type = "checkbox",
            label = "Invert Trinket/Racial Cooldown Swipe",
            desc = "Reverse the direction of the cooldown swipe animation.",
            get = layoutGet("invertTrinketCooldown"),
            set = function(val)
                local ls = getLS(); if not ls then return end
                ls.invertTrinketCooldown = val
                if not GladiusMidnight then return end
                for i = 1, GladiusMidnight.maxArenaOpponents do
                    local f = GladiusMidnight["arena" .. i]
                    if f and f.UpdateTrinketRacialCooldownReverse then
                        f:UpdateTrinketRacialCooldownReverse()
                    end
                end
            end,
        },
    },
}

-----------------------------------------------------------------------
-- TAB 5: DIMINISHING RETURNS
-----------------------------------------------------------------------
local tabDR = {
    name = "Diminishing Returns",
    icon = 136071, -- Spell_Frost_Stun
    controls = {
        { type = "header", label = "DR Options" },
        pToggle("Show Decimal Countdown", "showDecimalsDR",
            "Display DR cooldown time with decimal precision.", function()
                if GladiusMidnight and GladiusMidnight.SetupCustomCD then
                    GladiusMidnight:SetupCustomCD()
                end
            end),
        pToggle("Color DR Cooldown Text", "colorDRCooldownText",
            "Color the countdown text based on DR severity level.", function()
                if GladiusMidnight and GladiusMidnight.SetupCustomCD then
                    GladiusMidnight:SetupCustomCD()
                end
                rfTest()
            end),
        pToggle("Black DR Border", "blackDRBorder",
            "Force DR icon borders to be black instead of colored by severity.", rfTest),
        { type = "header", label = "DR Layout (Per-Layout)" },
        {
            type = "dropdown",
            label = "Growth Direction",
            desc = "Direction in which new DR icons appear.",
            values = function()
                return {
                    { key = 1, name = "Down" },
                    { key = 2, name = "Up" },
                    { key = 3, name = "Right" },
                    { key = 4, name = "Left" },
                }
            end,
            get = function()
                local ls = getLS()
                local dr = ls and ls.dr
                return dr and dr.growthDirection or 4
            end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ensureTable(ls, "dr")
                ls.dr.growthDirection = val
                rfConfigTest()
            end,
        },
        {
            type = "slider", label = "Icon Size",
            desc = "Size of each DR icon in pixels.",
            min = 12, max = 64, step = 1,
            get = function()
                local ls = getLS(); local dr = ls and ls.dr
                return dr and dr.size or 28
            end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ensureTable(ls, "dr"); ls.dr.size = val; rfConfigTest()
            end,
        },
        {
            type = "slider", label = "Icon Spacing",
            desc = "Space between DR icons in pixels.",
            min = 0, max = 20, step = 1,
            get = function()
                local ls = getLS(); local dr = ls and ls.dr
                return dr and dr.spacing or 6
            end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ensureTable(ls, "dr"); ls.dr.spacing = val; rfConfigTest()
            end,
        },
        {
            type = "slider", label = "Border Size",
            desc = "Thickness of the DR icon border.",
            min = 0, max = 4, step = 0.5,
            get = function()
                local ls = getLS(); local dr = ls and ls.dr
                return dr and dr.borderSize or 1
            end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ensureTable(ls, "dr"); ls.dr.borderSize = val; rfConfigTest()
            end,
        },
        { type = "header", label = "DR Categories" },
        { type = "desc", label = "Enable or disable tracking for each DR category." },
        {
            type = "multiselect",
            values = getDRCategoryDisplay,
            get = function(key)
                local p = getProfile()
                if not p or not p.drCategories then return true end
                if p.drCategories[key] == nil then return true end
                return p.drCategories[key]
            end,
            set = function(key, val)
                local p = getProfile(); if not p then return end
                p.drCategories = p.drCategories or {}
                p.drCategories[key] = val
            end,
        },
    },
}

-----------------------------------------------------------------------
-- TAB 6: DISPEL
-----------------------------------------------------------------------
local tabDispel = {
    name = "Dispel",
    icon = 135894, -- Spell_Holy_DispelMagic
    controls = {
        { type = "header", label = "Dispel Display" },
        lToggle("Show Dispel Icon", "showDispels",
            "Display the enemy's dispel ability icon on their frame.", rfConfigTest),
        pToggle("Desaturate on Cooldown", "desaturateDispelCD",
            "Gray out the dispel icon when the ability is on cooldown."),
    },
}

-----------------------------------------------------------------------
-- TAB 7: WIDGETS
-----------------------------------------------------------------------
local function widgetToggle(widgetKey, label, desc)
    return {
        type = "checkbox",
        label = label,
        desc = desc,
        get = function()
            local ls = getLS()
            local w = ls and ls.widgets and ls.widgets[widgetKey]
            return w and w.enabled
        end,
        set = function(val)
            local ls = getLS(); if not ls then return end
            ensureTable(ls, "widgets")
            ensureTable(ls.widgets, widgetKey)
            ls.widgets[widgetKey].enabled = val
            if GladiusMidnight then GladiusMidnight:RegisterWidgetEvents() end
            rfTest()
        end,
    }
end

local function widgetSlider(widgetKey, axis, label)
    return {
        type = "slider",
        label = label,
        min = -200, max = 200, step = 1,
        get = function()
            local ls = getLS()
            local w = ls and ls.widgets and ls.widgets[widgetKey]
            return w and w[axis] or 0
        end,
        set = function(val)
            local ls = getLS(); if not ls then return end
            ensureTable(ls, "widgets")
            ensureTable(ls.widgets, widgetKey)
            ls.widgets[widgetKey][axis] = val
            refreshConfig()
        end,
    }
end

local tabWidgets = {
    name = "Widgets",
    icon = 525134, -- Achievement_Arena (widget icon)
    controls = {
        { type = "desc", label = "Overlay indicators shown on arena frames. Position values are offsets from the frame center." },
        { type = "header", label = "Target Indicator" },
        widgetToggle("targetIndicator", "Enable", "Show a crosshair on your current target."),
        widgetSlider("targetIndicator", "posX", "X Offset"),
        widgetSlider("targetIndicator", "posY", "Y Offset"),
        { type = "header", label = "Focus Indicator" },
        widgetToggle("focusIndicator", "Enable", "Show a pin on your focus target."),
        widgetSlider("focusIndicator", "posX", "X Offset"),
        widgetSlider("focusIndicator", "posY", "Y Offset"),
        { type = "header", label = "Combat Indicator" },
        widgetToggle("combatIndicator", "Enable", "Show food/drink icon when enemy is out of combat."),
        widgetSlider("combatIndicator", "posX", "X Offset"),
        widgetSlider("combatIndicator", "posY", "Y Offset"),
        { type = "header", label = "Party Target Indicators" },
        widgetToggle("partyTargetIndicators", "Enable", "Show colored dots when party members are targeting."),
        widgetSlider("partyTargetIndicators", "posX", "X Offset"),
        widgetSlider("partyTargetIndicators", "posY", "Y Offset"),
    },
}

-----------------------------------------------------------------------
-- TAB 8: FONT
-----------------------------------------------------------------------
local tabFont = {
    name = "Font",
    icon = 134332, -- INV_Inscription_Scroll
    controls = {
        { type = "header", label = "Custom Font" },
        lToggle("Use Custom Font", "changeFont",
            "Override the default layout font.", function()
                if GladiusMidnight and GladiusMidnight.UpdateFonts then
                    GladiusMidnight:UpdateFonts()
                end
            end),
        {
            type = "dropdown",
            label = "Font",
            desc = "Select a font from LibSharedMedia.",
            values = function()
                local list = getFontList()
                local t = {}
                for _, k in ipairs(list) do
                    t[#t + 1] = { key = k, name = k }
                end
                return t
            end,
            get = function() local ls = getLS(); return ls and ls.fontName or "Prototype" end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ls.fontName = val
                if GladiusMidnight and GladiusMidnight.UpdateFonts then
                    GladiusMidnight:UpdateFonts()
                end
            end,
            disabled = function() local ls = getLS(); return not (ls and ls.changeFont) end,
        },
        lSlider("Font Size", "fontSize", "Size of the font in points.",
            4, 32, 1, function()
                if GladiusMidnight and GladiusMidnight.UpdateFonts then
                    GladiusMidnight:UpdateFonts()
                end
            end, { disabled = function() local ls = getLS(); return not (ls and ls.changeFont) end }),
        {
            type = "dropdown",
            label = "Font Outline",
            desc = "Outline style applied to font text.",
            values = function()
                return {
                    { key = "", name = "None" },
                    { key = "OUTLINE", name = "Normal" },
                    { key = "THICKOUTLINE", name = "Thick" },
                }
            end,
            get = function() local ls = getLS(); return ls and ls.fontOutline or "OUTLINE" end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ls.fontOutline = val
                if GladiusMidnight and GladiusMidnight.UpdateFonts then
                    GladiusMidnight:UpdateFonts()
                end
            end,
            disabled = function() local ls = getLS(); return not (ls and ls.changeFont) end,
        },
    },
}

-----------------------------------------------------------------------
-- TAB 9: TEXTURES
-----------------------------------------------------------------------
local tabTextures = {
    name = "Textures",
    icon = 136104, -- Spell_Nature_EnchantArmor
    controls = {
        { type = "desc", label = "Texture settings are per-layout. Changing layout will show that layout's texture configuration." },
        { type = "header", label = "StatusBar Textures" },
        {
            type = "dropdown",
            label = "General StatusBar Texture",
            desc = "Texture used for health and power bars.",
            values = function()
                local list = getStatusBarList()
                local t = {}
                for _, k in ipairs(list) do t[#t + 1] = { key = k, name = k } end
                return t
            end,
            get = function()
                local ls = getLS()
                local t = ls and ls.textures
                return (t and t.generalStatusBarTexture) or "Gladius Default"
            end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ensureTable(ls, "textures")
                ls.textures.generalStatusBarTexture = val
                if GladiusMidnight then GladiusMidnight:UpdateTextures() end
            end,
        },
        {
            type = "dropdown",
            label = "Healer StatusBar Texture",
            desc = "Alternate texture for healer specialization bars.",
            values = function()
                local list = getStatusBarList()
                local t = {}
                for _, k in ipairs(list) do t[#t + 1] = { key = k, name = k } end
                return t
            end,
            get = function()
                local ls = getLS()
                local t = ls and ls.textures
                return (t and t.healStatusBarTexture) or "Gladius Default"
            end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ensureTable(ls, "textures")
                ls.textures.healStatusBarTexture = val
                if GladiusMidnight then GladiusMidnight:UpdateTextures() end
            end,
        },
        lToggle("Healer Texture Only on Class Stacking", "retextureHealerClassStackOnly",
            "Only use the healer texture when there are duplicate classes.", function()
                if GladiusMidnight then GladiusMidnight:UpdateTextures() end
            end),
        {
            type = "dropdown",
            label = "CastBar Texture",
            desc = "Texture used for cast bars.",
            values = function()
                local list = getStatusBarList()
                local t = {}
                for _, k in ipairs(list) do t[#t + 1] = { key = k, name = k } end
                return t
            end,
            get = function()
                local ls = getLS()
                local t = ls and ls.textures
                return (t and t.castbarStatusBarTexture) or "Gladius Default"
            end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ensureTable(ls, "textures")
                ls.textures.castbarStatusBarTexture = val
                if GladiusMidnight then GladiusMidnight:UpdateTextures() end
            end,
        },
        { type = "header", label = "Background" },
        {
            type = "dropdown",
            label = "Background Texture",
            desc = "Texture used behind health bars.",
            values = function()
                local list = getStatusBarList()
                local t = {}
                for _, k in ipairs(list) do t[#t + 1] = { key = k, name = k } end
                return t
            end,
            get = function()
                local ls = getLS()
                local t = ls and ls.textures
                return (t and t.bgTexture) or "Solid"
            end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ensureTable(ls, "textures")
                ls.textures.bgTexture = val
                if GladiusMidnight then GladiusMidnight:UpdateTextures() end
            end,
        },
        {
            type = "color", label = "Background Color", hasAlpha = true,
            desc = "Color and transparency of the background texture.",
            get = function()
                local ls = getLS()
                local t = ls and ls.textures
                local c = t and t.bgColor or { 0, 0, 0, 0.6 }
                return c[1], c[2], c[3], c[4]
            end,
            set = function(r, g, b, a)
                local ls = getLS(); if not ls then return end
                ensureTable(ls, "textures")
                ls.textures.bgColor = { r, g, b, a }
                if GladiusMidnight then GladiusMidnight:UpdateTextures() end
            end,
        },
    },
}

-----------------------------------------------------------------------
-- TAB 10: POSITIONING
-----------------------------------------------------------------------
local function posSlider(label, key, desc)
    return lSlider(label, key, desc, -1000, 1000, 0.1, refreshConfig)
end
local function posNestedSlider(tbl, key, label, desc)
    return {
        type = "slider",
        label = label,
        desc = desc,
        min = -700, max = 700, step = 0.1,
        get = function()
            local ls = getLS()
            local sub = ls and ls[tbl]
            return sub and sub[key] or 0
        end,
        set = function(val)
            local ls = getLS(); if not ls then return end
            ensureTable(ls, tbl)
            ls[tbl][key] = val
            refreshConfig()
        end,
    }
end

local tabPositioning = {
    name = "Positioning",
    icon = 133015, -- INV_Misc_EngGizmos_27 (positioning icon)
    controls = {
        { type = "desc", label = "Position settings are per-layout. Use Shift+Ctrl+Drag in test mode for quick positioning." },
        { type = "header", label = "Frame Position" },
        posSlider("Horizontal (X)", "posX"),
        posSlider("Vertical (Y)", "posY"),
        lSlider("Scale", "scale", "Overall scale of all arena frames.",
            0.1, 5.0, 0.01, refreshConfig, { isPercent = true }),
        lSlider("Spacing", "spacing", "Vertical spacing between arena frames.",
            0, 100, 1, refreshConfig),
        {
            type = "dropdown",
            label = "Growth Direction",
            desc = "Direction in which additional arena frames are placed.",
            values = function()
                return { { key = 1, name = "Down" }, { key = 2, name = "Up" } }
            end,
            get = function() local ls = getLS(); return ls and ls.growthDirection or 1 end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ls.growthDirection = val; refreshConfig()
            end,
        },
        lToggle("Mirrored", "mirrored",
            "Mirror frame layout horizontally.", refreshConfig),
        { type = "header", label = "CastBar Position" },
        posNestedSlider("castBar", "posX", "X Offset"),
        posNestedSlider("castBar", "posY", "Y Offset"),
        { type = "header", label = "Spec Icon Position" },
        posNestedSlider("specIcon", "posX", "X Offset"),
        posNestedSlider("specIcon", "posY", "Y Offset"),
        { type = "header", label = "Trinket Position" },
        posNestedSlider("trinket", "posX", "X Offset"),
        posNestedSlider("trinket", "posY", "Y Offset"),
        { type = "header", label = "Racial Position" },
        posNestedSlider("racial", "posX", "X Offset"),
        posNestedSlider("racial", "posY", "Y Offset"),
        { type = "header", label = "Dispel Position" },
        posNestedSlider("dispel", "posX", "X Offset"),
        posNestedSlider("dispel", "posY", "Y Offset"),
        { type = "header", label = "Class Icon Position" },
        posNestedSlider("classIcon", "posX", "X Offset"),
        posNestedSlider("classIcon", "posY", "Y Offset"),
        { type = "header", label = "DR Icons Position" },
        {
            type = "slider", label = "X Offset",
            min = -700, max = 700, step = 0.1,
            get = function()
                local ls = getLS(); local dr = ls and ls.dr
                return dr and dr.posX or 0
            end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ensureTable(ls, "dr"); ls.dr.posX = val; rfConfigTest()
            end,
        },
        {
            type = "slider", label = "Y Offset",
            min = -700, max = 700, step = 0.1,
            get = function()
                local ls = getLS(); local dr = ls and ls.dr
                return dr and dr.posY or 0
            end,
            set = function(val)
                local ls = getLS(); if not ls then return end
                ensureTable(ls, "dr"); ls.dr.posY = val; rfConfigTest()
            end,
        },
    },
}

-----------------------------------------------------------------------
-- TAB 11: PROFILES
-----------------------------------------------------------------------
local tabProfiles = {
    name = "Profiles",
    icon = 134400, -- INV_Misc_Book_09
    controls = {
        { type = "desc", label = "Profile management. AceDB profile switching, import and export." },
        { type = "header", label = "Quick Actions" },
        {
            type = "button", label = "Open AceDB Profiles",
            width = 200,
            func = function()
                -- Fall back to AceConfig dialog for profile management
                Settings.OpenToCategory("Gladius Midnight")
            end,
        },
        { type = "spacer" },
        {
            type = "button", label = "Export Profile",
            width = 160,
            func = function()
                if GladiusMidnight and GladiusMidnight.ExportProfile then
                    GladiusMidnight:ExportProfile()
                end
            end,
        },
    },
}

-----------------------------------------------------------------------
-- ALL TABS
-----------------------------------------------------------------------
local allTabs = {
    tabGeneral,
    tabClassIcon,
    tabCastBar,
    tabTrinket,
    tabDR,
    tabDispel,
    tabWidgets,
    tabFont,
    tabTextures,
    tabPositioning,
    tabProfiles,
}

-----------------------------------------------------------------------
-- BUILD CONTENT from a tab definition
-----------------------------------------------------------------------
local function BuildTabContent(scrollChild, tabDef)
    -- Clear previous children
    local kids = { scrollChild:GetChildren() }
    for _, kid in ipairs(kids) do kid:Hide(); kid:SetParent(nil) end
    -- Also clear fontstrings we may have created as descriptions
    -- (They're regions, not children, so we track them separately)

    scrollChild._controls = {}
    local yOff = -PAD
    local contentW = scrollChild:GetWidth()

    for _, def in ipairs(tabDef.controls) do
        local widget, h

        if def.type == "header" then
            widget, h = CreateSettingsHeader(scrollChild, yOff, def.label)
        elseif def.type == "desc" then
            widget, h = CreateSettingsDesc(scrollChild, yOff, def.label)
        elseif def.type == "checkbox" then
            widget, h = CreateSettingsCheckbox(scrollChild, yOff, def)
        elseif def.type == "slider" then
            widget, h = CreateSettingsSlider(scrollChild, yOff, def)
        elseif def.type == "dropdown" then
            widget, h = CreateSettingsDropdown(scrollChild, yOff, def)
        elseif def.type == "color" then
            widget, h = CreateSettingsColor(scrollChild, yOff, def)
        elseif def.type == "button" then
            widget, h = CreateSettingsButton(scrollChild, yOff, def)
        elseif def.type == "multiselect" then
            widget, h = CreateSettingsMultiSelect(scrollChild, yOff, def)
        elseif def.type == "spacer" then
            widget, h = CreateSettingsSpacer(scrollChild, yOff, def.height)
        end

        if widget then
            scrollChild._controls[#scrollChild._controls + 1] = widget
            yOff = yOff - h - 4
        end
    end

    -- Set scroll child height
    scrollChild:SetHeight(math.abs(yOff) + PAD)

    -- RefreshAll function
    scrollChild.RefreshAll = function()
        for _, ctrl in ipairs(scrollChild._controls) do
            if ctrl.Refresh then ctrl:Refresh() end
        end
    end
end

-----------------------------------------------------------------------
-- MAIN FRAME CREATION
-----------------------------------------------------------------------
local mainFrame

local function CreateMainFrame()
    if mainFrame then return mainFrame end

    local f = CreateFrame("Frame", "GladiusMidnightSettings", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:Hide()

    -- Background
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(C.bg:GetRGBA())
    f:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(TOPBAR_H)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.03, 0.03, 0.03, 1)

    local titleDivider = titleBar:CreateTexture(nil, "ARTWORK")
    titleDivider:SetHeight(1)
    titleDivider:SetPoint("BOTTOMLEFT")
    titleDivider:SetPoint("BOTTOMRIGHT")
    titleDivider:SetColorTexture(C.divider:GetRGBA())

    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("LEFT", SIDEBAR_W + PAD, 0)
    titleText:SetText("Gladius |cff00ff00Midnight|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(TOPBAR_H - 16, TOPBAR_H - 16)
    closeBtn:SetPoint("RIGHT", -8, 0)
    local closeTex = closeBtn:CreateTexture(nil, "ARTWORK")
    closeTex:SetAllPoints()
    closeTex:SetAtlas("RedButton-Exit")
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeTex:SetAlpha(0.8) end)
    closeBtn:SetScript("OnLeave", function() closeTex:SetAlpha(1) end)

    -- Layout dropdown in title bar
    local layoutLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layoutLabel:SetPoint("RIGHT", closeBtn, "LEFT", -160, 0)
    layoutLabel:SetText("Layout:")
    layoutLabel:SetTextColor(C.sub:GetRGBA())

    local layoutBtn = CreateFrame("Button", "GladiusMidnightSettingsLayoutBtn", titleBar)
    layoutBtn:SetSize(140, 22)
    layoutBtn:SetPoint("LEFT", layoutLabel, "RIGHT", 6, 0)

    local layoutBtnBg = layoutBtn:CreateTexture(nil, "BACKGROUND")
    layoutBtnBg:SetAllPoints()
    layoutBtnBg:SetColorTexture(C.inputBg:GetRGBA())

    local layoutBtnText = layoutBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layoutBtnText:SetPoint("LEFT", 6, 0)
    layoutBtnText:SetPoint("RIGHT", -18, 0)
    layoutBtnText:SetJustifyH("LEFT")
    layoutBtnText:SetTextColor(C.accent:GetRGBA())

    local layoutArrow = layoutBtn:CreateTexture(nil, "OVERLAY")
    layoutArrow:SetSize(12, 12)
    layoutArrow:SetPoint("RIGHT", -3, 0)
    layoutArrow:SetAtlas("arrow-down-active")

    f.layoutBtnText = layoutBtnText

    -- Layout dropdown list
    local layoutList
    local function closeLayoutList()
        if layoutList then layoutList:Hide() end
    end

    local function updateLayoutDisplay()
        local p = getProfile()
        layoutBtnText:SetText(p and p.currentLayout or "Gladiuish")
    end

    layoutBtn:SetScript("OnClick", function()
        if layoutList and layoutList:IsShown() then closeLayoutList(); return end

        local layouts = getLayoutTable()
        if not layoutList then
            layoutList = CreateFrame("Frame", nil, layoutBtn)
            layoutList:SetFrameStrata("TOOLTIP")
            local bg = layoutList:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.08, 0.08, 0.08, 0.98)
            local border = CreateFrame("Frame", nil, layoutList, "BackdropTemplate")
            border:SetAllPoints()
            border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            layoutList._items = {}
        end

        for _, item in ipairs(layoutList._items) do item:Hide() end
        wipe(layoutList._items)

        local itemH = 20
        layoutList:SetSize(140, #layouts * itemH + 2)
        layoutList:SetPoint("TOPLEFT", layoutBtn, "BOTTOMLEFT", 0, -1)

        local p = getProfile()
        local curLayout = p and p.currentLayout

        for idx, entry in ipairs(layouts) do
            local itemBtn = CreateFrame("Button", nil, layoutList)
            itemBtn:SetSize(138, itemH)
            itemBtn:SetPoint("TOPLEFT", 1, -((idx - 1) * itemH))

            local itemBg = itemBtn:CreateTexture(nil, "BACKGROUND")
            itemBg:SetAllPoints()
            itemBg:SetColorTexture(0, 0, 0, 0)

            local itemText = itemBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            itemText:SetPoint("LEFT", 6, 0)
            itemText:SetText(entry.name)
            if entry.key == curLayout then
                itemText:SetTextColor(C.accent:GetRGBA())
            else
                itemText:SetTextColor(C.text:GetRGBA())
            end

            itemBtn:SetScript("OnEnter", function() itemBg:SetColorTexture(0.2, 0.2, 0.2, 0.6) end)
            itemBtn:SetScript("OnLeave", function() itemBg:SetColorTexture(0, 0, 0, 0) end)
            itemBtn:SetScript("OnClick", function()
                if GladiusMidnight and GladiusMidnight.SetLayout then
                    GladiusMidnight:SetLayout(nil, entry.key)
                end
                closeLayoutList()
                updateLayoutDisplay()
                -- Rebuild current tab to reflect new layout settings
                if f.currentTabIndex and f.scrollChild then
                    BuildTabContent(f.scrollChild, allTabs[f.currentTabIndex])
                end
            end)

            layoutList._items[#layoutList._items + 1] = itemBtn
        end
        layoutList:Show()
    end)

    layoutBtn:SetScript("OnHide", closeLayoutList)

    -- Test / Hide buttons in title bar
    local testBtn = CreateFrame("Button", nil, titleBar)
    testBtn:SetSize(50, 22)
    testBtn:SetPoint("RIGHT", layoutLabel, "LEFT", -12, 0)
    local testBg = testBtn:CreateTexture(nil, "BACKGROUND")
    testBg:SetAllPoints()
    testBg:SetColorTexture(C.btnBg:GetRGBA())
    local testText = testBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    testText:SetPoint("CENTER")
    testText:SetText("Test")
    testBtn:SetScript("OnClick", function()
        if GladiusMidnight and GladiusMidnight.Test then
            GladiusMidnight:Test()
        end
    end)
    testBtn:SetScript("OnEnter", function() testBg:SetColorTexture(C.btnHover:GetRGBA()) end)
    testBtn:SetScript("OnLeave", function() testBg:SetColorTexture(C.btnBg:GetRGBA()) end)

    local hideBtn = CreateFrame("Button", nil, titleBar)
    hideBtn:SetSize(50, 22)
    hideBtn:SetPoint("RIGHT", testBtn, "LEFT", -4, 0)
    local hideBg = hideBtn:CreateTexture(nil, "BACKGROUND")
    hideBg:SetAllPoints()
    hideBg:SetColorTexture(C.btnBg:GetRGBA())
    local hideText = hideBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hideText:SetPoint("CENTER")
    hideText:SetText("Hide")
    hideBtn:SetScript("OnClick", function()
        if not GladiusMidnight then return end
        for i = 1, GladiusMidnight.maxArenaOpponents do
            local frame = GladiusMidnight["arena" .. i]
            if frame then frame:Hide() end
        end
    end)
    hideBtn:SetScript("OnEnter", function() hideBg:SetColorTexture(C.btnHover:GetRGBA()) end)
    hideBtn:SetScript("OnLeave", function() hideBg:SetColorTexture(C.btnBg:GetRGBA()) end)

    ---------------------------------------------------------------
    -- SIDEBAR
    ---------------------------------------------------------------
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetWidth(SIDEBAR_W)
    sidebar:SetPoint("TOPLEFT", 0, 0)
    sidebar:SetPoint("BOTTOMLEFT", 0, 0)

    local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
    sidebarBg:SetAllPoints()
    sidebarBg:SetColorTexture(C.sidebar:GetRGBA())

    local sidebarBorder = sidebar:CreateTexture(nil, "ARTWORK")
    sidebarBorder:SetWidth(1)
    sidebarBorder:SetPoint("TOPRIGHT", 0, 0)
    sidebarBorder:SetPoint("BOTTOMRIGHT", 0, 0)
    sidebarBorder:SetColorTexture(C.divider:GetRGBA())

    -- Sidebar title
    local sideTitle = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sideTitle:SetPoint("TOPLEFT", PAD, -PAD)
    sideTitle:SetText("|cff00ff00GM|r Settings")
    sideTitle:SetTextColor(C.header:GetRGBA())

    -- Tab buttons
    f.tabButtons = {}
    local tabBtnH = 30
    local tabStartY = -(TOPBAR_H + 4)

    for idx, tabDef in ipairs(allTabs) do
        local tabBtn = CreateFrame("Button", nil, sidebar)
        tabBtn:SetSize(SIDEBAR_W - 2, tabBtnH)
        tabBtn:SetPoint("TOPLEFT", 1, tabStartY - (idx - 1) * (tabBtnH + 1))

        local tabBg = tabBtn:CreateTexture(nil, "BACKGROUND")
        tabBg:SetAllPoints()
        tabBg:SetColorTexture(C.tabNorm:GetRGBA())
        tabBtn.bg = tabBg

        -- Icon
        if tabDef.icon then
            local icon = tabBtn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(16, 16)
            icon:SetPoint("LEFT", 8, 0)
            icon:SetTexture(tabDef.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        local tabLabel = tabBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tabLabel:SetPoint("LEFT", tabDef.icon and 30 or 8, 0)
        tabLabel:SetText(tabDef.name)
        tabLabel:SetTextColor(C.text:GetRGBA())
        tabBtn.label = tabLabel

        tabBtn:SetScript("OnEnter", function()
            if f.currentTabIndex ~= idx then
                tabBg:SetColorTexture(C.tabHover:GetRGBA())
            end
        end)
        tabBtn:SetScript("OnLeave", function()
            if f.currentTabIndex ~= idx then
                tabBg:SetColorTexture(C.tabNorm:GetRGBA())
            end
        end)
        tabBtn:SetScript("OnClick", function()
            f:SelectTab(idx)
        end)

        f.tabButtons[idx] = tabBtn
    end

    ---------------------------------------------------------------
    -- CONTENT AREA (scroll frame)
    ---------------------------------------------------------------
    local contentFrame = CreateFrame("Frame", nil, f)
    contentFrame:SetPoint("TOPLEFT", SIDEBAR_W + 1, -TOPBAR_H)
    contentFrame:SetPoint("BOTTOMRIGHT", 0, 0)

    local scrollFrame = CreateFrame("ScrollFrame", "GladiusMidnightSettingsScroll", contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -24, 0)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1) -- Updated dynamically
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild
    f.scrollFrame = scrollFrame

    -- Update scrollChild width when frame resizes
    scrollFrame:SetScript("OnSizeChanged", function(self, w, h)
        scrollChild:SetWidth(w)
    end)

    ---------------------------------------------------------------
    -- TAB SELECTION
    ---------------------------------------------------------------
    function f:SelectTab(idx)
        -- Update button visuals
        for i, btn in ipairs(self.tabButtons) do
            if i == idx then
                btn.bg:SetColorTexture(C.tabActive:GetRGBA())
                btn.label:SetTextColor(1, 1, 1, 1)
            else
                btn.bg:SetColorTexture(C.tabNorm:GetRGBA())
                btn.label:SetTextColor(C.text:GetRGBA())
            end
        end

        self.currentTabIndex = idx
        -- Reset scroll position
        self.scrollFrame:SetVerticalScroll(0)
        -- Build content
        BuildTabContent(self.scrollChild, allTabs[idx])
    end

    ---------------------------------------------------------------
    -- ESCAPE TO CLOSE
    ---------------------------------------------------------------
    tinsert(UISpecialFrames, "GladiusMidnightSettings")

    -- On show: refresh layout display and select first tab
    f:SetScript("OnShow", function(self)
        updateLayoutDisplay()
        self:SelectTab(self.currentTabIndex or 1)
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    end)

    f:SetScript("OnHide", function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    end)

    mainFrame = f
    return f
end

-----------------------------------------------------------------------
-- PUBLIC API
-----------------------------------------------------------------------
function GladiusMixin:ToggleSettingsUI()
    local f = CreateMainFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
    end
end

function GladiusMixin:OpenSettingsUI()
    local f = CreateMainFrame()
    f:Show()
end

function GladiusMixin:CloseSettingsUI()
    if mainFrame then mainFrame:Hide() end
end
