-- ArenaCore Ticker Checker
-- Check if old tickers are still running

local AC = _G.ArenaCore
if not AC then return end

SLASH_ACTICKERS1 = "/actickers"
SlashCmdList.ACTICKERS = function()
    print("|cff8B45FF=== Active Ticker Check ===|r")
    
    -- Check for arena frames
    local frames = AC.arenaFrames or {}
    local tickerCount = 0
    
    for i = 1, 3 do
        local frame = frames[i]
        if frame then
            -- Check trinket ticker
            if frame.trinketIndicator and frame.trinketIndicator.ticker then
                print(string.format("|cffFF0000Frame %d: Trinket ticker STILL RUNNING!|r", i))
                tickerCount = tickerCount + 1
                
                -- Try to cancel it
                frame.trinketIndicator.ticker:Cancel()
                frame.trinketIndicator.ticker = nil
                print(string.format("|cff00FF00  → Cancelled trinket ticker for frame %d|r", i))
            end
            
            -- Check racial ticker
            if frame.racialIndicator and frame.racialIndicator.ticker then
                print(string.format("|cffFF0000Frame %d: Racial ticker STILL RUNNING!|r", i))
                tickerCount = tickerCount + 1
                
                -- Try to cancel it
                frame.racialIndicator.ticker:Cancel()
                frame.racialIndicator.ticker = nil
                print(string.format("|cff00FF00  → Cancelled racial ticker for frame %d|r", i))
            end
        end
    end
    
    if tickerCount == 0 then
        print("|cff00FF00No active tickers found - all clean!|r")
    else
        print(string.format("|cffFFAA00Found and cancelled %d tickers!|r", tickerCount))
        print("|cff00FF00Use /reload to see memory reduction|r")
    end
    
    -- Force garbage collection
    local before = collectgarbage("count")
    collectgarbage("collect")
    local after = collectgarbage("count")
    print(string.format("Garbage collected: %.2f KB", before - after))
end

-- Disabled startup message for end users
-- print("|cff8B45FFArenaCore:|r Ticker checker loaded. Use |cffffff00/actickers|r to check for running tickers.")
