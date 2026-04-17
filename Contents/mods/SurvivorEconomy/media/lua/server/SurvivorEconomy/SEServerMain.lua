-- SEServerMain.lua
-- Server-side entry point. Registers all event handlers and routes client commands.

require "SurvivorEconomy/SEConstants"
require "SurvivorEconomy/SEConfig"
require "SurvivorEconomy/SEUtils"

SEServerMain = {}

--- Handle client commands sent to the server.
--- @param module string
--- @param command string
--- @param player IsoPlayer
--- @param args table
local function onClientCommand(module, command, player, args)
    if module ~= SEConstants.MOD_ID then return end
    if not args then return end

    -- Lazy-load server modules (they require server-only APIs)
    local SETraderManager = require "SurvivorEconomy/SETraderManager"

    if command == SEConstants.CMD.REQUEST_TRADER then
        local traderType = args.traderType
        if traderType then
            local snapshot = SETraderManager.getTraderSnapshot(traderType)
            sendServerCommand(player, SEConstants.MOD_ID, SEConstants.RESP.TRADER_DATA, snapshot)
        end

    elseif command == SEConstants.CMD.BUY_ITEM then
        local result = SETraderManager.processBuy(
            player,
            args.traderType,
            args.itemType,
            args.quantity or 1
        )
        sendServerCommand(player, SEConstants.MOD_ID, SEConstants.RESP.BUY_RESULT, result)

    elseif command == SEConstants.CMD.SELL_ITEM then
        local result = SETraderManager.processSell(
            player,
            args.traderType,
            args.itemType,
            args.quantity or 1
        )
        sendServerCommand(player, SEConstants.MOD_ID, SEConstants.RESP.SELL_RESULT, result)

    elseif command == SEConstants.CMD.USE_FARM_ITEM then
        local SEFarmEconomy = require "SurvivorEconomy/SEFarmEconomy"
        local result = SEFarmEconomy.useFarmItem(player, args.itemType, args)
        sendServerCommand(player, SEConstants.MOD_ID, SEConstants.RESP.FARM_RESULT, result)
    end
end

--- Periodic hourly check for trader restocks and token decay.
local function onEveryHours()
    local SETraderManager = require "SurvivorEconomy/SETraderManager"
    SETraderManager.restockAllTraders()

    local SECurrencySink = require "SurvivorEconomy/SECurrencySink"
    SECurrencySink.checkTokenDecay()
end

--- Initialize server state when global mod data is ready.
local function onInitGlobalModData()
    local SETraderManager = require "SurvivorEconomy/SETraderManager"
    SETraderManager.initGlobalState()
    print("[SurvivorEconomy] Server initialized - trader state loaded")
end

--- Handle player death for currency sink.
--- @param player IsoPlayer
local function onPlayerDeath(player)
    local SECurrencySink = require "SurvivorEconomy/SECurrencySink"
    SECurrencySink.onPlayerDeath(player)
end

-- Register events
Events.OnClientCommand.Add(onClientCommand)
Events.EveryHours.Add(onEveryHours)
Events.OnInitGlobalModData.Add(onInitGlobalModData)
Events.OnPlayerDeath.Add(onPlayerDeath)

return SEServerMain
