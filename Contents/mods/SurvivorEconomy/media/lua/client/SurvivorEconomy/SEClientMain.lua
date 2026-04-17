-- SEClientMain.lua
-- Client-side entry point. Registers event handlers for server responses.

require "SurvivorEconomy/SEConstants"
require "SurvivorEconomy/SEUtils"
require "SurvivorEconomy/SETraderUI"
require "SurvivorEconomy/SEWalletHUD"

SEClientMain = {}

--- Handle server commands sent to the client.
--- @param module string
--- @param command string
--- @param args table
local function onServerCommand(module, command, args)
    if module ~= SEConstants.MOD_ID then return end

    if command == SEConstants.RESP.TRADER_DATA then
        -- Server sent trader data in response to our request
        local player = getPlayer()
        if player and args.traderType and args.items then
            SETraderUI.open(player, args.traderType, args)
        end

    elseif command == SEConstants.RESP.BUY_RESULT then
        if args.success then
            -- Refresh the UI with updated data
            if SETraderUI.instance then
                -- Request fresh trader data to update the UI
                local player = getPlayer()
                if player then
                    sendClientCommand(player, SEConstants.MOD_ID, SEConstants.CMD.REQUEST_TRADER, {
                        traderType = SETraderUI.instance.traderType,
                    })
                end
            end
        else
            -- Show error message to player
            local player = getPlayer()
            if player then
                player:Say(args.message or "Purchase failed")
            end
        end

    elseif command == SEConstants.RESP.SELL_RESULT then
        if args.success then
            -- Refresh the UI with fresh data from server
            if SETraderUI.instance then
                local player = getPlayer()
                if player then
                    sendClientCommand(player, SEConstants.MOD_ID, SEConstants.CMD.REQUEST_TRADER, {
                        traderType = SETraderUI.instance.traderType,
                    })
                end
            end
        else
            local player = getPlayer()
            if player then
                player:Say(args.message or "Sale failed")
            end
        end

    elseif command == SEConstants.RESP.FARM_RESULT then
        if not args.success then
            local player = getPlayer()
            if player then
                player:Say(args.message or "Action failed")
            end
        end
    end
end

--- Initialize client when game starts.
local function onGameStart()
    local player = getPlayer()
    if player then
        SEUtils.initPlayerData(player)
    end
end

-- Register events
Events.OnServerCommand.Add(onServerCommand)
Events.OnGameStart.Add(onGameStart)

return SEClientMain
