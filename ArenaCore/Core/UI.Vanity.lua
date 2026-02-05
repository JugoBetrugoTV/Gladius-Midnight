-- =============================================================================
-- File: ArenaCore/Core/UI.Vanity.lua - v8.0 RENAMED
-- =============================================================================

local addonName, _ns = ...
local addon = _G.ArenaCore or {}
_G.ArenaCore = addon

local V = {}
addon.Vanity = V

-- START: REPLACE with this code block
do
  -- Method-style helpers to correctly handle calls from other files
  function addon:CreateFlatTexture(parent, layer, sublevel, color, alpha)
    local lvl = sublevel or 0
    -- Safety check to prevent this exact error
    if type(lvl) ~= "number" then lvl = 0 end
    
    if lvl > 7 then lvl = 7 elseif lvl < -8 then lvl = -8 end
    
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, math.floor(lvl))
    local c = color or {0.1, 0.1, 0.1, 1}
    local a = alpha or c[4] or 1
    t:SetColorTexture(c[1], c[2], c[3], a)
    return t
  end

  function addon:AddHairlineRect(frame, color, alpha, z)
    local c = color or COLORS.BORDER_LIGHT; local a = alpha or 1; local lvl = z or 6
    -- Use 'self:' to call the method version
    local t=self:CreateFlatTexture(frame,"OVERLAY",lvl,c,a);t:SetPoint("TOPLEFT",0,0);t:SetPoint("TOPRIGHT",0,0);t:SetHeight(1)
    local b=self:CreateFlatTexture(frame,"OVERLAY",lvl,c,a);b:SetPoint("BOTTOMLEFT",0,0);b:SetPoint("BOTTOMRIGHT",0,0);b:SetHeight(1)
    local l=self:CreateFlatTexture(frame,"OVERLAY",lvl,c,a);l:SetPoint("TOPLEFT",0,0);l:SetPoint("BOTTOMLEFT",0,0);l:SetWidth(1)
    local r=self:CreateFlatTexture(frame,"OVERLAY",lvl,c,a);r:SetPoint("TOPRIGHT",0,0);r:SetPoint("BOTTOMRIGHT",0,0);r:SetWidth(1)
  end

  function addon:CreateStyledText(parent, text, size, color, layer, flags)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    -- Set font BEFORE setting text to avoid "Font not set" errors
    local fontSet = fs:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", tonumber(size) or 12, flags or "")
    if not fontSet then
      -- Fallback to WoW default font
      fs:SetFont("Fonts\\FRIZQT__.TTF", tonumber(size) or 12, flags or "")
    end
    fs:SetText(text or "")
    if type(color) == "table" then
      fs:SetTextColor(unpack(color))
    else
      fs:SetTextColor(1, 1, 1, 1)
    end
    fs:SetShadowOffset(0, 0)
    return fs
  end

  function addon:CreateTexturedButton(parent, w, h, label, texBase, name)
    local b = CreateFrame("Button", name or nil, parent)
    b:SetSize(w, h)
    local path = "Interface\\AddOns\\ArenaCore\\Media\\" .. texBase .. ".tga"
    local n = b:CreateTexture(nil, "BACKGROUND")
    n:SetAllPoints(); n:SetTexture(path);
    b:SetNormalTexture(n)
    local hlt = b:CreateTexture(nil, "HIGHLIGHT")
    hlt:SetAllPoints(); hlt:SetTexture(path); hlt:SetVertexColor(1, 1, 1, 0.85)
    b:SetHighlightTexture(hlt)
    if label and label ~= "" then
      -- Use 'self:' to call the method version
      local t = self:CreateStyledText(b, label, 12, COLORS.TEXT, "OVERLAY", "")
      t:SetPoint("CENTER", 0, 0)
      b.text = t
    end
    return b
  end
end
-- END: REPLACE with this code block

-- Define necessary colors locally to avoid errors
local COLORS = {
  PRIMARY      = {0.545, 0.271, 1.000, 1}, -- #8B45FF
  TEXT         = {1.000, 1.000, 1.000, 1},
  TEXT_2       = {0.706, 0.706, 0.706, 1}, -- #B4B4B4
  BG           = {0.165, 0.165, 0.165, 1}, -- #2A2A2A
  -- INPUT_DARK removed - using centralized definition from UI.lua
  BORDER       = {0.196, 0.196, 0.196, 1}, -- #323232
  BORDER_LIGHT = {0.278, 0.278, 0.278, 1}, -- #474747
}

-- Icons
local ICONS = {
  HEART = "Interface\\AddOns\\ArenaCore\\Media\\UI\\arena-core-heart.tga",
  SWORD = "Interface\\AddOns\\ArenaCore\\Media\\UI\\arena-core-sword.tga",
}

-- Motto pool
V.MOTTO_LINES = {
  "No Excuses, Only Results",
  "One Mistake, Game Over",
  "Precision Over Panic",
  "Dominate or Be Dominated",
  "Every Bind Counts",
  "Pressure Creates Power",
  "Control The Chaos",
  "Only Skill Survives",
  "Strength Through Struggle",
  "Don't Forget To Press Wall",
  "Timing Beats Talent",
  "Fear The Calm Before The Burst",
  "Earn Every Victory",
  "It's Out Of Your Control, Just Press",
  "Best Game Ever Made",
  "Even Venruki Didn't Block Once",
}

-- Public helper: page motto strip (callable anytime)
function V:EnsureMottoStrip(parent)
  parent._mottoStrip = parent._mottoStrip or CreateFrame("Frame", nil, parent)
  local bar = parent._mottoStrip
  bar:ClearAllPoints()
  bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -8)
  bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -8)
  bar:SetHeight(40)

  if not bar.bg then
    bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, 0)
    bar.bg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\bar-orange-matte.tga") -- Using your matte texture
    bar.bg:SetAllPoints()
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    -- CRITICAL FIX: Set font BEFORE setting text
    local fontSet = bar.text:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 13, "")
    if not fontSet then
      -- Fallback to WoW default font if custom font fails
      bar.text:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    end
    bar.text:SetPoint("CENTER", 0, 0)
  end

  local pick = math.random(1, #self.MOTTO_LINES)
  bar.text:SetText(self.MOTTO_LINES[pick])
  return bar
end

-- ============================================================================
-- Patch Notes Popup (RE-SKINNED)
-- ============================================================================
function V:ShowPatchNotes()
  -- Patch notes popup - debug removed for clean release
  
  -- FORCE RECREATE: Destroy old frame to apply new styling
  if addon._patchFrame then
    -- Destroying old frame for fresh styling
    addon._patchFrame:Hide()
    addon._patchFrame = nil
  end

  -- Create a plain Frame, NOT a BackdropTemplate
  local f = CreateFrame("Frame", "ArenaCorePatchNotes", UIParent)
  f:SetSize(520, 600); f:SetPoint("CENTER", 0, 0); f:SetFrameStrata("DIALOG")
  f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
  
  -- Frame created, applying ArenaCore skin

  if not f._skin then
   -- Background using ArenaCore styling (matching other pages)
local bg = addon:CreateFlatTexture(f, "BACKGROUND", 1, COLORS.BG, 1)
bg:SetAllPoints()

-- Border using ArenaCore styling
addon:AddWindowEdge(f, 1, 0)

-- Header matching other configuration windows
local header = CreateFrame("Frame", nil, f)
header:SetPoint("TOPLEFT", 8, -8)
header:SetPoint("TOPRIGHT", -8, -8)
header:SetHeight(50)

-- Header background - solid dark color (no texture, simpler approach)
local headerBg = addon:CreateFlatTexture(header, "BACKGROUND", 1, {0.12, 0.12, 0.12, 1}, 1)
headerBg:SetAllPoints()

-- Purple accent line (hairline like main UI)
local accent = addon:CreateFlatTexture(header, "OVERLAY", 3, COLORS.PRIMARY, 1)
accent:SetPoint("TOPLEFT", 0, 0)
accent:SetPoint("TOPRIGHT", 0, 0)
accent:SetHeight(2)

-- Header border
local hbLight = addon:CreateFlatTexture(header, "OVERLAY", 2, COLORS.BORDER_LIGHT, 0.8)
hbLight:SetPoint("BOTTOMLEFT", 0, 0)
hbLight:SetPoint("BOTTOMRIGHT", 0, 0)
hbLight:SetHeight(1)

       -- Style the title text (NO outline) - now in header
    f._title = addon:CreateStyledText(header, "What's new in v" .. (addon.Version or "0.9.2.3"), 14, COLORS.TEXT, "OVERLAY", "")
    f._title:SetPoint("LEFT", 15, 0)

    -- Style the close button to match the main panel's - now in header
    f._close = addon:CreateTexturedButton(header, 36, 36, "", "button-close")
    f._close:SetPoint("RIGHT", -10, 0)
    local xText = addon:CreateStyledText(f._close, "×", 16, COLORS.TEXT, "OVERLAY", "")
    xText:SetPoint("CENTER", 0, 0)
    f._close:SetScript("OnClick", function() f:Hide() end)

    -- Create scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, f)
    scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 7, -15)
    scrollFrame:SetPoint("BOTTOMRIGHT", -14, 14)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 20)
    scrollChild:SetHeight(1000) -- Set initial height for dividers to show
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Style the body text (NO outline) - positioned in scroll child
    f._body = addon:CreateStyledText(scrollChild, "", 12, COLORS.TEXT_2, "OVERLAY", "")
    f._body:SetPoint("TOPLEFT", 0, 0)
    f._body:SetPoint("TOPRIGHT", 0, 0)
    f._body:SetJustifyH("LEFT"); f._body:SetJustifyV("TOP")
    f._body:SetSpacing(3)
    
    -- Enable mouse wheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(maxScroll, current - (delta * 20)))
        self:SetVerticalScroll(newScroll)
    end)
    
    f._scrollFrame = scrollFrame
    f._scrollChild = scrollChild
    
    -- URGENT UPDATE BANNER with custom glow border (positioned in scroll child, below release date)
    -- This will appear after the release date line in the notes
    local urgentBanner = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
    urgentBanner:SetSize(460, 40)
    urgentBanner:SetPoint("TOP", scrollChild, "TOP", 0, -200)  -- Position further down below release date info
    urgentBanner:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 16,
        edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    urgentBanner:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    urgentBanner:SetBackdropBorderColor(1, 0.84, 0, 1)  -- Gold border
    
    -- Urgent text inside the banner
    local urgentText = addon:CreateStyledText(urgentBanner, "URGENT PLEASE READ v0.9.2.0 MIDNIGHT CHANGES", 13, {r=1, g=0, b=0, a=1}, "OVERLAY", "OUTLINE")
    urgentText:SetPoint("CENTER", 0, 0)
    urgentText:SetFont(addon.CUSTOM_FONT, 13, "OUTLINE, THICKOUTLINE")
    urgentText:SetTextColor(1, 0, 0, 1)  -- Bright red color
    
    -- Pulsing animation for the text only
    local textAnim = urgentText:CreateAnimationGroup()
    textAnim:SetLooping("BOUNCE")
    
    local textFade = textAnim:CreateAnimation("Alpha")
    textFade:SetFromAlpha(1.0)
    textFade:SetToAlpha(0.5)
    textFade:SetDuration(1.2)
    textFade:SetSmoothing("IN_OUT")
    
    textAnim:Play()
    
    -- Create clean professional glow using WoW's native ActionButton glow system
    -- This is the same glow used for usable abilities on your action bars
    local glowFrame = CreateFrame("Frame", nil, urgentBanner)
    glowFrame:SetAllPoints(urgentBanner)
    glowFrame:SetFrameLevel(urgentBanner:GetFrameLevel() - 1)  -- Behind the banner
    
    -- Top glow line
    local topGlow = glowFrame:CreateTexture(nil, "BACKGROUND")
    topGlow:SetAtlas("UI-HUD-ActionBar-Gryphon-Wyvern-Glow", true)
    topGlow:SetPoint("TOPLEFT", urgentBanner, "TOPLEFT", -8, 8)
    topGlow:SetPoint("TOPRIGHT", urgentBanner, "TOPRIGHT", 8, 8)
    topGlow:SetHeight(16)
    topGlow:SetBlendMode("ADD")
    topGlow:SetVertexColor(1, 0.84, 0, 0.8)  -- Gold color
    
    -- Bottom glow line
    local bottomGlow = glowFrame:CreateTexture(nil, "BACKGROUND")
    bottomGlow:SetAtlas("UI-HUD-ActionBar-Gryphon-Wyvern-Glow", true)
    bottomGlow:SetPoint("BOTTOMLEFT", urgentBanner, "BOTTOMLEFT", -8, -8)
    bottomGlow:SetPoint("BOTTOMRIGHT", urgentBanner, "BOTTOMRIGHT", 8, -8)
    bottomGlow:SetHeight(16)
    bottomGlow:SetBlendMode("ADD")
    bottomGlow:SetVertexColor(1, 0.84, 0, 0.8)  -- Gold color
    bottomGlow:SetTexCoord(0, 1, 1, 0)  -- Flip vertically
    
    -- Left glow line
    local leftGlow = glowFrame:CreateTexture(nil, "BACKGROUND")
    leftGlow:SetAtlas("UI-HUD-ActionBar-Gryphon-Wyvern-Glow", true)
    leftGlow:SetPoint("TOPLEFT", urgentBanner, "TOPLEFT", -8, 8)
    leftGlow:SetPoint("BOTTOMLEFT", urgentBanner, "BOTTOMLEFT", -8, -8)
    leftGlow:SetWidth(16)
    leftGlow:SetBlendMode("ADD")
    leftGlow:SetVertexColor(1, 0.84, 0, 0.8)  -- Gold color
    leftGlow:SetTexCoord(0, 1, 1, 0)  -- Rotate for vertical
    
    -- Right glow line
    local rightGlow = glowFrame:CreateTexture(nil, "BACKGROUND")
    rightGlow:SetAtlas("UI-HUD-ActionBar-Gryphon-Wyvern-Glow", true)
    rightGlow:SetPoint("TOPRIGHT", urgentBanner, "TOPRIGHT", 8, 8)
    rightGlow:SetPoint("BOTTOMRIGHT", urgentBanner, "BOTTOMRIGHT", 8, -8)
    rightGlow:SetWidth(16)
    rightGlow:SetBlendMode("ADD")
    rightGlow:SetVertexColor(1, 0.84, 0, 0.8)  -- Gold color
    rightGlow:SetTexCoord(0, 1, 1, 0)  -- Rotate for vertical
    
    f._skin = true
  end

  -- Build release notes with color coding and formatting
  local notes = 
    "\n|A:Crosshair_Important_128:32:32|a |cffB266FFScroll down to see all changes in this build|r\n\n" ..
    "|cffFFD700-----------------------------------------------------|r\n" ..
    "|cffFFD700              ADDON RELEASE NOTES              |r\n" ..
    "|cffFFD700-----------------------------------------------------|r\n\n" ..
    
    "|cffFFD700Addon:|r ARENA CORE\n" ..
    "|cffFFD700Version:|r |cffB266FFv0.9.2.3|r\n" ..
    "|cffFFD700Build:|r |cffB266FF12.0+|r\n" ..
    "|cffFFD700Game Version:|r |cff8B45FFRetail - Midnight|r\n" ..
    "|cffFFD700Release Date:|r 01/29/2026\n\n\n\n\n\n" ..
    
    "|cffFFD700-----------------------------------------------------|r\n" ..
    "|cff44FF44              v0.9.2.3 CHANGELOG              |r\n" ..
    "|cffFFD700-----------------------------------------------------|r\n\n" ..
    
    "|cff00FF00>> BUG FIXES:|r\n\n" ..
    
    "|cffFFD700• Test Mode Data Leak|r\n" ..
    "|cffFFFFFFFixed an issue with stale data from test mode leaking into arena prep room.|r\n\n" ..
    
    "|cffFFD700• Cast Bar Alignment|r\n" ..
    "|cffFFFFFFFixed issues with cast bars not properly lining up exactly as it shows in test mode.|r\n\n" ..
    
    "|cffFFD700• Friendly Health Bars|r\n" ..
    "|cffFFFFFFFixed an issue with health bars not being hidden when you use the Hide Friendly Health Bar toggle.|r\n\n" ..
    
    "|cffFFD700• Trinket Data|r\n" ..
    "|cffFFFFFFFixed an issue with Trinkets using proper data.|r\n\n" ..
    
    "|cff44FF44>> NEW FEATURES:|r\n\n" ..
    
    "|cffB266FF• Link Horizontal Toggle|r\n" ..
    "|cffFFFFFFAdded a new \"Link Horizontal\" toggle on the More Goodies page for the Class/Pointer Icons on friendly targets\n" ..
    "so you can easily auto align them pixel perfectly, along with new values it uses so they match up better.|r\n\n" ..
    
    "|cffB266FF• Easter Egg|r\n" ..
    "|cffFFFFFFAdded an easter egg to frames for lol's.|r\n\n" ..
    
    "|cffFFD700-----------------------------------------------------|r\n" ..
    "|cff44FF44              v0.9.2.2 CHANGELOG              |r\n" ..
    "|cffFFD700-----------------------------------------------------|r\n\n" ..
    
    "|cff44FF44>> NEW FEATURES:\n\n" ..
    
    "|cffB266FF• Platynator Addon Support|r\n" ..
    "|cffFFFFFFAdded support for Platynator addon with various features connecting directly such as Enemy Nameplate Names and more.\n" ..
    "All functions now work correctly with proper integration between ArenaCore and Platynator.|r\n\n" ..
    
    "|cffB266FF• Target Highlight Thickness Control|r\n" ..
    "|cffFFFFFFYou can now edit the thickness/thinness of the Target highlight around the arena frames.\n" ..
    "Find this in the Arena Frames page at the very bottom using the toggle.|r\n\n" ..
    
    "|cffB266FF• NEW PAGE: Frames/Nameplates|r\n" ..
    "|cffFFFFFFVarious new mods coming soon! On this page you can find a new feature for Enemy Nameplate Names\n" ..
    "with various options. For example, you can set enemy player nameplate names to their Spec, Arena number, and more!|r\n\n" ..
    
    "|cff00FF00>> BUG FIXES:|r\n\n" ..
    
    "|cffFFD700• Racial Icons|r\n" ..
    "|cffFFFFFFFixed small issue with racial icons choosing random icons on first round of solo shuffle or normal arena games.|r\n\n" ..
    
    "|cffFFD700• Cast Bars|r\n" ..
    "|cffFFFFFFFixed issue with some cast bars/info not properly clearing per round in solo shuffle.|r\n\n" ..
    
    "|cffFFD700• Death Icons|r\n" ..
    "|cffFFFFFFFixed Death icons randomly showing over portraits in prep room and when gates open.|r\n\n" ..
    
    "|cffFFD700• Settings Persistence|r\n" ..
    "|cffFFFFFFFixed an issue with certain positioning settings not properly saving on reload/new game load.|r\n\n" ..
    
    "|cffFFAA00>> PATCH 0.9.2.1 NOTES:|r\n\n" ..
    
    "|cffB266FF• Added support for Platynator addon|r\n" ..
    "|cffFFFFFFVarious features connect directly to Platynator with working correct functions such as Enemy Name Plate Names etc.|r\n\n" ..
    
    "|cffFFD700-----------------------------------------------------|r\n" ..
    
    "|cffFF6644Please understand there are various issues within the Blizzard default UI that are out of my control,\n" ..
    "such as Party/Class indicators overlapping on certain UI elements, Health bars of nameplates not properly\n" ..
    "hiding when you toggle the checkbox for it, and more.\n\n" ..
    
    "When Blizzard fixes their UI issues, Arena Core will continue to update to ensure everything keeps running\n" ..
    "as smoothly as it can. Please join the Discord for more active updates and insight with us. <3|r\n\n" ..
    
    "|cffFFD700-----------------------------------------------------|r\n" ..
    "|cff8B45FF              v0.9.2.0 CHANGELOG              |r\n" ..
    "|cffFFD700-----------------------------------------------------|r\n\n" ..
    
    "|cffFFD700BIG UPDATES AND CHANGES:|r\n\n" ..
    
    "|cffFF6644COMPLETE Arena Core OVERHAUL: PLEASE READ!|r\n\n" ..
    
    "|cffFFFFFFMidnight has taken its toll on every addon in the game in some form or light, unfortunately that means Arena Core was hit hard.\n" ..
    "For the time being, a lot of features you have come to love have been disabled. As Midnight continues to create new addon API's, \n" ..
    "Arena Core will adjust in real time as needed and re enable features as they become available. (if ever)\n" ..
    "I will personally be updating any news/big changes coming to Arena Core on my Twitter/X if you would like to stay in the loop\n" ..
    "https://x.com/PeralexIRL\n\n" ..
    
    "|cff44FF44Right now, the core values you expect from an Arena Frame addon are working just fine. As well as additional features you will find.\n" ..
    "Fun and useful additions that range from Party/Class icon indicators for friendly players, Font modding, custom cast bars, textures,\n" ..
    "even the loved Arena Core reward system etc are all working as intended.\n\n" ..
    
    "|cffFFFFFFThere will be constant updates as I continue to find new ways to come out with features as well as new cosmetics so this can be the\n" ..
    "full feature packed addon you know and love.\n\n" ..
    
    "|cffFFAA00If you are not someone who updates addons very often, I urge you not only for Arena Core, but addons as a whole to check DAILY\n" ..
    "for the foreseeable future as Midnight addon developers are surely going to be working over time to create bug fixes and new features.\n\n" ..
    
    "|cff8B45FFBIG INCOMING: Arena Core will be coming out with its own \"weak aura\" style maker for arena prep room, think \"change talents\" reminders etc.\n" ..
    "along with other goodies people are wanting. As well as a big update to the Blackout feature I have ideas for and more that will be PUMPING OUT,\n" ..
    "so please keep checking for updates.\n\n" ..
    
    "|cffFFFFFFYou will find various other areas within the UI that explain certain changes and updates.\n" ..
    "My core focus for this update was STABILITY and function over form. Some things I went the safe route with to ensure you have virtually no errors or problems as much as possible.\n" ..
    "Things will change almost daily as I continue to work on things and make improvements and create new features for.\n\n" ..
    
    "|cff44FF44PLEASE join the discord as I am keeping people updated not only about Arena Core, but addons in general so you can stay in the loop about API changes and what might be coming back.\n\n" ..
    
    "|cffFF69B4<3 you.\n"
  
  f._body:SetText(notes)
  
  -- Update scroll child height based on text height
  C_Timer.After(0.1, function()
    if f._body and f._scrollChild then
      local textHeight = f._body:GetStringHeight()
      f._scrollChild:SetHeight(math.max(textHeight + 20, f._scrollFrame:GetHeight()))
    end
  end)
  
  -- Reset scroll to top
  if f._scrollFrame then
    f._scrollFrame:SetVerticalScroll(0)
  end
  
  f:Show(); addon._patchFrame = f
end

-- ============================================================================
-- Links Popup (similar to patch notes)
-- ============================================================================
function V:ShowLinksPopup()
  if addon._linksFrame and addon._linksFrame:IsShown() then return end

  -- Create a plain Frame, NOT a BackdropTemplate
  local f = addon._linksFrame or CreateFrame("Frame", "ArenaCoreLinks", UIParent)
  f:SetSize(280, 140); f:SetPoint("CENTER", 0, 60); f:SetFrameStrata("DIALOG")
  f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)

  if not f._skin then
    -- Apply the dark matte background texture, just like a group box
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\box-dark-matte.tga")
    bg:SetAllPoints()

    -- Add the hairline border
    addon:AddHairlineRect(f, COLORS.BORDER_LIGHT, 0.9, 6)

    -- Add the purple accent line at the top
    local accent = addon:CreateFlatTexture(f, "OVERLAY", 7, COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0); accent:SetPoint("TOPRIGHT", 0, 0); accent:SetHeight(1)

    -- Style the title text
    f._title = addon:CreateStyledText(f, "Arena Core Social", 13, COLORS.PRIMARY, "OVERLAY", "")
    f._title:SetPoint("TOPLEFT", 14, -12)

    -- Style the close button to match the main panel's
    f._close = addon:CreateTexturedButton(f, 30, 30, "", "button-close")
    f._close:SetPoint("TOPRIGHT", -8, -8)
    local xText = addon:CreateStyledText(f._close, "×", 16, COLORS.TEXT, "OVERLAY", "")
    xText:SetPoint("CENTER", 0, 0)
    f._close:SetScript("OnClick", function() f:Hide() end)

    -- Create Discord button
    f._discordBtn = addon:CreateTexturedButton(f, 100, 32, "Discord", "UI\\tab-purple-matte")
    f._discordBtn:SetPoint("BOTTOM", 0, 50)
    f._discordBtn:SetScript("OnClick", function()
      -- Show chat message
      if ChatFrame1 then
        ChatFrame1:AddMessage("|cff8B45FFArenaCore:|r https://acdiscord.com", 1, 1, 1)
      end
      -- Open copy/paste window
      V:ShowDiscordLinkPopup()
    end)

    -- Create Website button
    f._websiteBtn = addon:CreateTexturedButton(f, 100, 32, "Website", "UI\\tab-purple-matte")
    f._websiteBtn:SetPoint("BOTTOM", 0, 14)
    f._websiteBtn:SetScript("OnClick", function()
      if ChatFrame1 then
        ChatFrame1:AddMessage("|cff8B45FFArenaCore:|r https://ArenaCore.io", 1, 1, 1)
      end
    end)

    f._skin = true
  end

  f:Show(); addon._linksFrame = f
end

-- ============================================================================
-- Discord Link Popup (copyable link window)
-- ============================================================================
function V:ShowDiscordLinkPopup()
  if addon._discordLinkFrame and addon._discordLinkFrame:IsShown() then return end

  -- Create a plain Frame, NOT a BackdropTemplate
  local f = addon._discordLinkFrame or CreateFrame("Frame", "ArenaCoreDiscordLink", UIParent)
  f:SetSize(320, 160); f:SetPoint("CENTER", 0, 60); f:SetFrameStrata("FULLSCREEN_DIALOG")
  f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)

  if not f._skin then
    -- Apply the dark matte background texture, just like a group box
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\box-dark-matte.tga")
    bg:SetAllPoints()

    -- Add the hairline border
    addon:AddHairlineRect(f, COLORS.BORDER_LIGHT, 0.9, 6)

    -- Add the purple accent line at the top
    local accent = addon:CreateFlatTexture(f, "OVERLAY", 7, COLORS.PRIMARY, 1)
    accent:SetPoint("TOPLEFT", 0, 0); accent:SetPoint("TOPRIGHT", 0, 0); accent:SetHeight(1)

    -- Style the title text
    f._title = addon:CreateStyledText(f, "Arena Core Discord", 13, COLORS.PRIMARY, "OVERLAY", "")
    f._title:SetPoint("TOPLEFT", 14, -12)

    -- Style the close button to match the main panel's
    f._close = addon:CreateTexturedButton(f, 30, 30, "", "button-close")
    f._close:SetPoint("TOPRIGHT", -8, -8)
    local xText = addon:CreateStyledText(f._close, "×", 16, COLORS.TEXT, "OVERLAY", "")
    xText:SetPoint("CENTER", 0, 0)
    f._close:SetScript("OnClick", function() f:Hide() end)

    -- Instruction text
    f._instructionText = addon:CreateStyledText(f, "Copy the Discord link below:", 11, COLORS.TEXT_2, "OVERLAY", "")
    f._instructionText:SetPoint("TOP", 0, -45)

    -- Create EditBox for copyable link
    local linkBox = CreateFrame("EditBox", nil, f)
    linkBox:SetSize(280, 32)
    linkBox:SetPoint("TOP", 0, -70)
    linkBox:SetAutoFocus(false)
    linkBox:SetMultiLine(false)
    linkBox:SetMaxLetters(0)
    
    -- Set font for EditBox
    local fontSet = linkBox:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 12, "")
    if not fontSet then
      linkBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    end
    
    -- EditBox background
    local linkBg = addon:CreateFlatTexture(linkBox, "BACKGROUND", 1, {0.08, 0.08, 0.08, 1}, 1)
    linkBg:SetAllPoints()
    
    -- EditBox border
    addon:AddHairlineRect(linkBox, COLORS.BORDER_LIGHT, 0.8, 6)
    
    -- Set the Discord link
    linkBox:SetText("https://acdiscord.com")
    linkBox:SetTextColor(1, 1, 1, 1)  -- White text color
    linkBox:SetCursorPosition(0)
    
    -- Select all text when clicked
    linkBox:SetScript("OnEditFocusGained", function(self)
      self:HighlightText()
    end)
    
    linkBox:SetScript("OnEscapePressed", function(self)
      self:ClearFocus()
    end)
    
    linkBox:SetScript("OnEnterPressed", function(self)
      self:ClearFocus()
    end)
    
    f._linkBox = linkBox

    -- Helper text
    f._helperText = addon:CreateStyledText(f, "Click the link to select all, then Ctrl+C to copy", 10, COLORS.TEXT_2, "OVERLAY", "")
    f._helperText:SetPoint("BOTTOM", 0, 14)

    f._skin = true
  end

  -- Auto-select the link when window opens
  if f._linkBox then
    C_Timer.After(0.1, function()
      if f._linkBox then
        f._linkBox:SetFocus()
        f._linkBox:HighlightText()
      end
    end)
  end

  f:Show(); addon._discordLinkFrame = f
end

-- Header vanity -------------------------------------------------------------
function V:AttachHeader()
  if not addon.header or not addon.versionFrame or addon._vanityHeader then return end
  
  -- Check if Shade UI theme is active
  local activeTheme = addon.ThemeManager and addon.ThemeManager:GetActiveTheme() or "default"
  local isShadeUI = (activeTheme == "shade_ui")

  -- Header title text next to logo (far left, large) - ONLY for default theme
  if not addon._headerTitle and not isShadeUI then
    -- Create container for title + underline
    local titleContainer = CreateFrame("Frame", nil, addon.header)
    titleContainer:SetPoint("LEFT", 70, 0) -- Position to match original
    titleContainer:SetSize(250, 40)
    
    local title = titleContainer:CreateFontString(nil, "OVERLAY", nil, 7)
    -- Set font BEFORE setting text - large bold size
    local fontSet = title:SetFont("Interface\\AddOns\\ArenaCore\\Media\\Fonts\\arenacore.ttf", 28, "OUTLINE")
    if not fontSet then
      title:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
    end
    title:SetTextColor(1, 1, 1, 1)
    title:SetText("ARENA CORE")
    title:SetPoint("TOPLEFT", 0, 0)
    
    -- Purple gradient underline effect using custom texture
    local underline = titleContainer:CreateTexture(nil, "OVERLAY", nil, 6)
    underline:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\purpleheader.tga")
    underline:SetPoint("BOTTOM", title, "BOTTOM", 0, -6)
    underline:SetSize(220, 8) -- Adjust width to match text length
    
    addon._headerTitle = title
    addon._headerTitleUnderline = underline
  end

  -- Version tag click easter egg
  local vClick = CreateFrame("Button", nil, addon.versionFrame)
  vClick:SetAllPoints()
  vClick:SetScript("OnClick", function()
    if IsControlKeyDown() and IsAltKeyDown() then
      local sword = "|T"..ICONS.SWORD..":14:14:0:0:64:64:2:62:2:62|t"
      print("|cff8B45FFArena Core:|r " .. sword .. " Obsidian Mode Unlocked " .. sword)
      if PlaySound and SOUNDKIT then pcall(PlaySound, SOUNDKIT.UI_EPICLOOT_TOAST, "Master") end
    end
  end)

  -- Patch notes button "?" with hover animation
  local notesBtn = addon:CreateTexturedButton(addon.header, 28, 24, "?", "UI\\tab-purple-matte")
  notesBtn:SetPoint("LEFT", addon.versionFrame, "RIGHT", 6, 0)
  notesBtn:SetScript("OnClick", function() V:ShowPatchNotes() end)

  -- Subtle pulse on header accent (one-time)
  local target = addon.header._accent
  if target and not addon._accentPulse then
    local ag = target:CreateAnimationGroup()
    local a1 = ag:CreateAnimation("Alpha"); a1:SetFromAlpha(1); a1:SetToAlpha(0.85); a1:SetDuration(1.6); a1:SetSmoothing("IN_OUT")
    local a2 = ag:CreateAnimation("Alpha"); a2:SetFromAlpha(0.85); a2:SetToAlpha(1); a2:SetDuration(1.6); a2:SetSmoothing("IN_OUT")
    ag:SetLooping("REPEAT"); ag:Play()
    addon._accentPulse = ag
  end

  -- Sword logo
  if not addon._swordLogo then
    local logo = addon.header:CreateTexture(nil, "OVERLAY", nil, 7)
    logo:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\UI\\logoarena.tga")
    logo:SetSize(160, 160)
    logo:SetPoint("TOPLEFT", addon.header, "TOPLEFT", -60, 50)  -- Moved up from 36 to 50
    logo:SetTexCoord(0.002, 0.998, 0.002, 0.998)
    logo:SetVertexColor(1, 1, 1, 1)
    logo:SetBlendMode("BLEND")
    logo:SetRotation(math.rad(-25))
    addon._swordLogo = logo
  end

  addon._vanityHeader = true
end

-- Content vanity ------------------------------------------------------------
function V:AttachContent()
  if not addon.contentBox or addon._vanityContent then return end
  -- tiny mascot bottom-right
  local m = addon.contentBox:CreateTexture(nil, "OVERLAY", nil, 6)
  m:SetTexture("Interface\\AddOns\\ArenaCore\\Media\\Logo\\arena_core_clean.tga")
  m:SetSize(80, 22)
  m:SetPoint("BOTTOMRIGHT", -12, 10)
  m:SetVertexColor(1, 1, 1, 0.10)
  addon._mascot = m
  addon._vanityContent = true
end

-- Footer vanity -------------------------------------------------------------
local FOOTER_HEIGHT = 28
function V:AttachFooter()
  if not addon.configFrame or addon._footer then return end
  local frame = addon.configFrame

  -- Grow once only
  local w, h = frame:GetSize(); frame:SetSize(w, h + FOOTER_HEIGHT)

  local footer = CreateFrame("Frame", nil, frame)
  footer:SetPoint("BOTTOMLEFT", 1, 1); footer:SetPoint("BOTTOMRIGHT", -1, 1)
  footer:SetHeight(FOOTER_HEIGHT)

  -- Check if Shade UI theme is active
  local activeTheme = addon.ThemeManager and addon.ThemeManager:GetActiveTheme() or "default"
  local isShadeUI = (activeTheme == "shade_ui")
  
  -- Use HEADER_BG for footer (darker, more consistent) - but hide for Shade UI
  local footerColor = addon.COLORS.HEADER_BG or addon.COLORS.INPUT_DARK or {0.102, 0.102, 0.102, 1}
  local fill = addon:CreateFlatTexture(footer, "BACKGROUND", 1, footerColor, 1)
  fill:SetAllPoints()
  if isShadeUI then
    fill:Hide() -- Hide footer background for Shade UI theme
  end
  
  local top  = addon:CreateFlatTexture(footer, "OVERLAY", 1, COLORS.PRIMARY, 0.9)
  top:SetPoint("TOPLEFT", 0, 0); top:SetPoint("TOPRIGHT", 0, 0); top:SetHeight(1)

  local row = CreateFrame("Frame", nil, footer); row:SetPoint("CENTER", 0, 0); row:SetHeight(FOOTER_HEIGHT)
  row:SetWidth(200) -- Set initial width
  
  local pre = addon:CreateStyledText(row, "made with", 12, COLORS.TEXT_2); pre:SetPoint("CENTER", -40, 0)
  
  local heart = row:CreateTexture(nil, "OVERLAY", nil, 7)
  heart:SetTexture(ICONS.HEART); heart:SetSize(20, 20); heart:SetPoint("LEFT", pre, "RIGHT", 6, 0)
  heart:SetTexCoord(0.002, 0.998, 0.002, 0.998); heart:SetBlendMode("BLEND"); heart:SetVertexColor(0.95, 0.15, 0.20, 1)
  
  local post = addon:CreateStyledText(row, "by peralex", 12, COLORS.TEXT_2); post:SetPoint("LEFT", heart, "RIGHT", 6, 0)

  -- Add subtle button next to the footer text
  local subtleBtn = CreateFrame("Button", nil, footer)
  subtleBtn:SetSize(110, 20)
  subtleBtn:SetPoint("LEFT", post, "RIGHT", 15, 0)

  -- Add background texture to make it look like a proper button
  local btnBg = addon:CreateFlatTexture(subtleBtn, "BACKGROUND", 1, COLORS.BG, 1)
  btnBg:SetAllPoints()

  -- Add border for definition
  addon:AddHairlineRect(subtleBtn, COLORS.BORDER_LIGHT, 0.6, 6)
  
  local btnText = addon:CreateStyledText(subtleBtn, "click this, do it", 11, COLORS.TEXT_2)
  btnText:ClearAllPoints()
  btnText:SetPoint("CENTER", 0, 0)
  subtleBtn:SetScript("OnClick", function() V:ShowLinksPopup() end)

  -- Update width after UI is loaded to ensure proper centering
  C_Timer.After(0.1, function()
    local wpre = pre and pre:GetStringWidth() or 60
    local wpost = post and post:GetStringWidth() or 70
    local wbtn = subtleBtn and subtleBtn:GetWidth() or 80
    local totalWidth = wpre + wpost + heart:GetWidth() + wbtn + 30
    row:SetWidth(totalWidth)
    -- Shift left to compensate for the longer button and center properly
    row:ClearAllPoints()
    row:SetPoint("CENTER", footer, "CENTER", -60, 0)
  end)

  addon._footer = footer

  -- Re-anchor sidebar/content bottoms upward by FOOTER_HEIGHT
  -- CRITICAL FIX: Don't override sidebar width - let the theme control it
  -- The hardcoded 240 was causing Shade UI's 160px sidebar to be resized
  if addon.sidebar then 
    -- Don't call ClearAllPoints or SetWidth - let the theme's sidebar positioning stay intact
    -- Just adjust the bottom position for the footer
    -- addon.sidebar:ClearAllPoints(); addon.sidebar:SetPoint("TOPLEFT", 8, -(70 + 8)); addon.sidebar:SetPoint("BOTTOMLEFT", 8, 8 + FOOTER_HEIGHT); addon.sidebar:SetWidth(240)
  end
  if addon.contentArea then 
    -- Don't reposition content area - let the theme control it
    -- addon.contentArea:ClearAllPoints(); addon.contentArea:SetPoint("TOPLEFT", 240 + 8 + 1, -(70 + 8)); addon.contentArea:SetPoint("BOTTOMRIGHT", -8, 8 + FOOTER_HEIGHT)
  end
end

-- Attach everything once -----------------------------------------------------
function V:AttachAll()
  V:AttachHeader(); V:AttachContent(); V:AttachFooter()
  
  if addon.configFrame and addon.tipText then
    local initial_pick = math.random(1, #V.MOTTO_LINES)
    addon.tipText:SetText(V.MOTTO_LINES[initial_pick])

    addon.configFrame:HookScript("OnShow", function()
        -- CRITICAL FIX: Ensure all UI fonts are set before showing
        if addon.EnsureUIFontObjects then
            addon.EnsureUIFontObjects()
        end
        if addon.FixUIFontsRecursively then
            addon.FixUIFontsRecursively(addon.configFrame)
        end
        
        if addon.tipText:IsShown() then
            local pick = math.random(1, #V.MOTTO_LINES)
            addon.tipText:SetText(V.MOTTO_LINES[pick])
        end
    end)
  end
end
