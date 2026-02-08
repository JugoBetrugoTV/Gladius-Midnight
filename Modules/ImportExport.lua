--[[
    Gladius Midnight - Import/Export Module
    Serializes, compresses, and encodes addon profiles for sharing.
    Uses LibDeflate and LibSerialize for data transformation.
    Format: "!Gladius:ENCODED_DATA:Gladius!"
]]

local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")
local L = GladiusMixin.L

-----------------------------------------------------------------------
-- Import confirmation dialog (prevents accidental profile overwrite)
-----------------------------------------------------------------------
local confirmDialog

local function ShowConfirmDialog(message, onAccept, payload)
    if confirmDialog and confirmDialog:IsShown() then
        return
    end

    if not confirmDialog then
        local dlg = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        dlg:SetSize(320, 160)
        dlg:SetPoint("CENTER")
        dlg:SetFrameStrata("TOOLTIP")
        dlg:SetFrameLevel(1000)

        dlg:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })

        dlg.title = dlg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dlg.title:SetPoint("TOP", 0, -15)
        dlg.title:SetText(L["ImportExport_DialogTitle"])

        dlg.body = dlg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        dlg.body:SetPoint("TOP", 0, -45)
        dlg.body:SetWidth(270)
        dlg.body:SetJustifyH("CENTER")

        dlg.acceptBtn = CreateFrame("Button", nil, dlg, "UIPanelButtonTemplate")
        dlg.acceptBtn:SetSize(100, 22)
        dlg.acceptBtn:SetPoint("BOTTOM", dlg, "BOTTOM", -55, 20)
        dlg.acceptBtn:SetText(L["Yes"])

        dlg.cancelBtn = CreateFrame("Button", nil, dlg, "UIPanelButtonTemplate")
        dlg.cancelBtn:SetSize(100, 22)
        dlg.cancelBtn:SetPoint("BOTTOM", dlg, "BOTTOM", 55, 20)
        dlg.cancelBtn:SetText(L["No"])
        dlg.cancelBtn:SetScript("OnClick", function()
            dlg:Hide()
        end)

        confirmDialog = dlg
    end

    confirmDialog.body:SetText(message)
    confirmDialog.acceptBtn:SetScript("OnClick", function()
        confirmDialog:Hide()
        if onAccept then
            onAccept(payload)
        end
    end)

    confirmDialog:Show()
end

-----------------------------------------------------------------------
-- ExportProfile: Serialize + compress + encode the current profile
-- Returns: "!Gladius:ENCODED_DATA:Gladius!" or nil, errorMsg
-----------------------------------------------------------------------
function GladiusMixin:ExportProfile(profileKeyOverride)
    local charName, charRealm = UnitName("player")
    charRealm = charRealm or GetRealmName()
    local fullCharKey = charName .. " - " .. charRealm

    local profileKey = profileKeyOverride or GladiusMidnightDB.profileKeys[fullCharKey]
    if not profileKey then
        return nil, L["Message_NoProfileFound"]
    end

    local profileData = GladiusMidnightDB.profiles[profileKey]
    if not profileData then
        return nil, L["Message_ProfileDataNotFound"]
    end

    local exportPayload = {
        dataType = "GladiusProfile",
        profileName = profileKey,
        data = profileData,
    }

    local serialized = LibSerialize:Serialize(exportPayload)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)

    return "!Gladius:" .. encoded .. ":Gladius!"
end

-----------------------------------------------------------------------
-- ImportProfile: Decode + decompress + deserialize an encoded string
-- Creates a new profile and optionally reloads the UI
-----------------------------------------------------------------------
function GladiusMixin:ImportProfile(encodedString, customProfileName, externalSource)
    -- Trim whitespace
    encodedString = encodedString:match("^%s*(.-)%s*$")

    -- Validate format wrapper
    if not encodedString:match("^!Gladius:.+:Gladius!$") then
        return nil, L["Message_InvalidFormat"]
    end

    -- Extract the encoded payload
    local rawEncoded = encodedString:match("^!Gladius:(.+):Gladius!$")
    local compressed = LibDeflate:DecodeForPrint(rawEncoded)
    local serialized, decompErr = LibDeflate:DecompressDeflate(compressed)

    if not serialized then
        return nil, string.format(L["Message_DecompressionError"], decompErr or L["Unknown"])
    end

    local ok, importTable = LibSerialize:Deserialize(serialized)
    if not ok or type(importTable) ~= "table" then
        return nil, L["Message_DeserializationError"]
    end

    if importTable.dataType ~= "GladiusProfile" or type(importTable.data) ~= "table" then
        return nil, L["Message_IncorrectDataType"]
    end

    -- Determine the profile name to use
    local newProfileName
    if customProfileName then
        newProfileName = customProfileName
    else
        local baseName = importTable.profileName or "Imported"

        -- If a profile with that name exists, strip old time suffix first
        if GladiusMidnightDB.profiles[baseName] then
            baseName = baseName:gsub(" %d%d:%d%d$", "")
        end

        newProfileName = baseName
        if GladiusMidnightDB.profiles[newProfileName] then
            newProfileName = baseName .. " " .. date("%H:%M")
        end
    end

    -- Store the imported profile
    GladiusMidnightDB.profiles[newProfileName] = importTable.data

    -- Apply the profile to the current character
    for charKey in pairs(GladiusMidnightDB.profileKeys) do
        GladiusMidnightDB.profileKeys[charKey] = newProfileName
    end

    if not externalSource then
        GladiusMidnightDB.reOpenOptions = true
        ReloadUI()
    end

    return true
end

-----------------------------------------------------------------------
-- ImportStreamerProfile: Import a named streamer profile with dialog
-----------------------------------------------------------------------
function GladiusMixin:ImportStreamerProfile(streamerName, profileString, displayName, classColor)
    local profileName = streamerName .. " StreamProfile"
    local alreadyExists = GladiusMidnightDB.profiles[profileName] ~= nil

    -- Get current profile name for reference
    local charName, charRealm = UnitName("player")
    charRealm = charRealm or GetRealmName()
    local fullKey = charName .. " - " .. charRealm
    local currentProfile = GladiusMidnightDB.profileKeys[fullKey]

    local payload = {
        profileString = profileString,
        profileName = profileName,
        currentProfileName = currentProfile or "Default",
    }

    -- If no existing profile, import without confirmation
    if not alreadyExists then
        local success, err = self:ImportProfile(payload.profileString, payload.profileName)
        if not success then
            self:Print(L["Message_ImportFailed"], err)
        end
        return
    end

    -- Existing profile: ask for overwrite confirmation
    local coloredName = (classColor or "|cffffffff") .. (displayName or streamerName) .. "|r"
    local confirmMsg = string.format(L["Message_ProfileOverwrite"], coloredName)

    ShowConfirmDialog(confirmMsg, function(data)
        local success, err = self:ImportProfile(data.profileString, data.profileName)
        if not success then
            self:Print(L["Message_ImportFailed"], err)
        end
    end, payload)
end
