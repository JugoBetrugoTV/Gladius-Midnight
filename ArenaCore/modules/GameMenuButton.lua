-- =============================================================
-- File: modules/GameMenuButton.lua
-- ArenaCore Game Menu Button
-- Adds an ArenaCore button to the ESC menu (GameMenuFrame)
-- =============================================================

local AC = _G.ArenaCore
if not AC then return end

-- Create module
AC.GameMenuButton = AC.GameMenuButton or {}
local GameMenuButton = AC.GameMenuButton

-- Module state
GameMenuButton.isEnabled = false
GameMenuButton.isHooked = false

-- Add ArenaCore button to the game menu
function GameMenuButton:AddButton()
    if not GameMenuFrame then return end
    
    -- Add a section separator for visual organization
    GameMenuFrame:AddSection()
    
    -- Add the ArenaCore button
    -- The button text uses ArenaCore's signature colors with logo icon
    local iconPath = "Interface\\AddOns\\ArenaCore\\Media\\Textures\\aclogo"
    local buttonText = string.format("|cff8B45FFArena|r |cffB266FFCore|r |T%s:16:16:0:0|t", iconPath)
    
    GameMenuFrame:AddButton(
        buttonText,  -- Button text with colors and icon
        function()
            -- Open ArenaCore UI when clicked (same as /arena command)
            if AC and AC.OpenConfigPanel then
                AC:OpenConfigPanel(true)  -- true = toggle mode
            else
                print("|cffFF0000[ArenaCore]|r Config panel not loaded!")
            end
            
            -- Close the game menu after clicking
            HideUIPanel(GameMenuFrame)
        end
    )
end

-- Enable the game menu button
function GameMenuButton:Enable()
    if self.isEnabled then return end
    
    -- Hook GameMenuFrame's InitButtons to add our button
    -- This is called whenever the game menu is rebuilt
    if not self.isHooked then
        hooksecurefunc(GameMenuFrame, "InitButtons", function()
            GameMenuButton:AddButton()
        end)
        self.isHooked = true
    end
    
    self.isEnabled = true
    -- Silently enabled (no chat spam for users)
end

-- Disable the game menu button
function GameMenuButton:Disable()
    -- Note: Can't unhook, but we can stop adding the button
    self.isEnabled = false
    -- Silently disabled (no chat spam for users)
end

-- Initialize on addon load (silently)
