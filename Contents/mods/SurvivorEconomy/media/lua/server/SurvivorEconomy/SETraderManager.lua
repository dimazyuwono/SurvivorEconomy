-- SETraderManager.lua
-- Server-side trader inventory management, restocking, and transaction processing.

require "SurvivorEconomy/SEConstants"
require "SurvivorEconomy/SEConfig"
require "SurvivorEconomy/SEUtils"
require "SurvivorEconomy/SEItemValues"

SETraderManager = {}

--- B41-compatible ModData helper: get or create a global mod data table.
--- @param key string
--- @return table
local function getOrCreateModData(key)
    local data = ModData.get(key)
    if not data then
        ModData.create(key)
        data = ModData.get(key)
    end
    return data
end

--- Initialize or retrieve the global trader state from GlobalModData.
--- Called once on server start.
function SETraderManager.initGlobalState()
    local state = getOrCreateModData(SEConstants.GLOBAL.TRADER_STATE)

    if not state.traders then
        state.traders = {}
        state.lastRestockHour = 0

        -- Initialize each trader type with fresh stock
        for traderType, _ in pairs(SEConfig.TRADER_POOLS) do
            state.traders[traderType] = {
                inventory = {},
                priceMultipliers = {},  -- tracks escalation per item
            }
            SETraderManager.restockTrader(state.traders[traderType], traderType)
        end

        ModData.transmit(SEConstants.GLOBAL.TRADER_STATE)
    end

    return state
end

--- Generate a restocked inventory for a trader from its item pool.
--- @param trader table trader state table
--- @param traderType string type key from SEConstants.TRADER_TYPE
function SETraderManager.restockTrader(trader, traderType)
    local pool = SEConfig.TRADER_POOLS[traderType]
    if not pool then return end

    trader.inventory = {}
    trader.priceMultipliers = {}

    -- Calculate total weight for probability
    local totalWeight = 0
    for _, entry in ipairs(pool) do
        totalWeight = totalWeight + entry.weight
    end

    -- Generate stock: pick items weighted by pool config
    for _, entry in ipairs(pool) do
        -- Higher weight = more likely to appear, and more stock
        local chance = entry.weight / totalWeight
        local maxQty = SEConfig.TRADER_MAX_STOCK_PER_ITEM

        -- Quantity based on weight: common items get more stock
        local qty = math.max(1, math.floor(maxQty * chance * #pool / 2))
        qty = math.min(qty, maxQty)

        -- Random variance: +/- 1
        qty = math.max(1, qty + ZombRand(-1, 2))
        qty = math.min(qty, maxQty)

        trader.inventory[entry.itemType] = {
            quantity = qty,
            basePrice = entry.basePrice,
        }
        trader.priceMultipliers[entry.itemType] = 1.0
    end
end

--- Restock all traders. Called periodically from EveryHours.
function SETraderManager.restockAllTraders()
    local state = getOrCreateModData(SEConstants.GLOBAL.TRADER_STATE)
    if not state.traders then return end

    local gameTime = getGameTime()
    local currentHour = gameTime:getWorldAgeHours()

    -- Check if enough time has passed since last restock
    if currentHour - (state.lastRestockHour or 0) < SEConfig.TRADER_RESTOCK_HOURS then
        return
    end

    state.lastRestockHour = currentHour

    for traderType, trader in pairs(state.traders) do
        SETraderManager.restockTrader(trader, traderType)
    end

    ModData.transmit(SEConstants.GLOBAL.TRADER_STATE)
end

--- Get the current price for an item at a trader (with escalation).
--- @param traderType string
--- @param itemType string
--- @return number|nil current price, or nil if not stocked
function SETraderManager.getCurrentPrice(traderType, itemType)
    local state = getOrCreateModData(SEConstants.GLOBAL.TRADER_STATE)
    if not state.traders or not state.traders[traderType] then return nil end

    local trader = state.traders[traderType]
    local stock = trader.inventory[itemType]
    if not stock then return nil end

    local multiplier = trader.priceMultipliers[itemType] or 1.0
    return math.max(1, math.floor(stock.basePrice * multiplier))
end

--- Process a buy request from a player.
--- @param player IsoPlayer
--- @param traderType string
--- @param itemType string
--- @param quantity number
--- @return table result {success, message, totalCost}
function SETraderManager.processBuy(player, traderType, itemType, quantity)
    local state = getOrCreateModData(SEConstants.GLOBAL.TRADER_STATE)
    if not state.traders or not state.traders[traderType] then
        return { success = false, message = "Trader not found" }
    end

    local trader = state.traders[traderType]
    local stock = trader.inventory[itemType]

    if not stock or stock.quantity <= 0 then
        return { success = false, message = "Out of stock" }
    end

    local actualQty = math.min(quantity, stock.quantity)
    local multiplier = trader.priceMultipliers[itemType] or 1.0

    -- Calculate total cost with escalation
    local totalCost = 0
    local tempMultiplier = multiplier
    for _ = 1, actualQty do
        totalCost = totalCost + math.max(1, math.floor(stock.basePrice * tempMultiplier))
        tempMultiplier = tempMultiplier * (1 + SEConfig.PRICE_ESCALATION_PERCENT / 100)
    end

    -- Check if player can afford it
    local container = player:getInventory()
    if SEUtils.countTokens(container) < totalCost then
        return { success = false, message = "Not enough tokens" }
    end

    -- Execute transaction
    SEUtils.removeTokens(container, totalCost)
    for _ = 1, actualQty do
        container:AddItem(itemType)
    end

    -- Update trader state
    stock.quantity = stock.quantity - actualQty
    trader.priceMultipliers[itemType] = tempMultiplier

    -- Track stats
    SEUtils.trackSpent(player, totalCost)

    ModData.transmit(SEConstants.GLOBAL.TRADER_STATE)

    return {
        success = true,
        message = "Purchased " .. actualQty .. "x for " .. totalCost .. " tokens",
        totalCost = totalCost,
        newPrice = SETraderManager.getCurrentPrice(traderType, itemType),
    }
end

--- Process a sell request from a player.
--- @param player IsoPlayer
--- @param traderType string
--- @param itemType string
--- @param quantity number
--- @return table result {success, message, totalEarned}
function SETraderManager.processSell(player, traderType, itemType, quantity)
    local container = player:getInventory()

    -- Find the items in player inventory (B41-compatible manual iteration)
    local matchingItems = {}
    local allItems = container:getItems()
    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item:getFullType() == itemType then
            table.insert(matchingItems, item)
        end
    end

    if #matchingItems < quantity then
        return { success = false, message = "You don't have enough of that item" }
    end

    -- Calculate sell price
    local basePrice = SEItemValues.getBasePrice(itemType)
    if not basePrice then
        return { success = false, message = "This item cannot be sold" }
    end

    local pricePerUnit = math.max(1, math.floor(basePrice * SEConfig.BUY_SELL_SPREAD))

    -- Check if this is a crop for special pricing
    local cropKey = SETraderManager.getCropKey(itemType)
    if cropKey then
        pricePerUnit = SEUtils.getCropSellPrice(itemType, cropKey, quantity, traderType)
    end

    local totalEarned = pricePerUnit * quantity

    -- Execute transaction: remove items, add tokens
    for i = 1, quantity do
        container:Remove(matchingItems[i])
    end

    SEUtils.addTokens(container, totalEarned)

    -- Track stats
    SEUtils.trackEarned(player, totalEarned)

    return {
        success = true,
        message = "Sold " .. quantity .. "x for " .. totalEarned .. " tokens",
        totalEarned = totalEarned,
    }
end

--- Map item full types to crop keys for season/bulk lookups.
--- @param itemType string
--- @return string|nil crop key
function SETraderManager.getCropKey(itemType)
    local cropMap = {
        ["farming.Cabbage"]    = "cabbage",
        ["farming.Potato"]     = "potato",
        ["farming.Tomato"]     = "tomato",
        ["farming.Strawberry"] = "strawberry",
        ["farming.Corn"]       = "corn",
        ["farming.Broccoli"]   = "broccoli",
    }
    return cropMap[itemType]
end

--- Get a snapshot of a trader's current state for sending to a client.
--- @param traderType string
--- @return table trader data for client display
function SETraderManager.getTraderSnapshot(traderType)
    local state = getOrCreateModData(SEConstants.GLOBAL.TRADER_STATE)
    if not state.traders or not state.traders[traderType] then
        return { traderType = traderType, items = {} }
    end

    local trader = state.traders[traderType]
    local snapshot = {
        traderType = traderType,
        items = {},
    }

    for itemType, stock in pairs(trader.inventory) do
        if stock.quantity > 0 then
            local multiplier = trader.priceMultipliers[itemType] or 1.0
            table.insert(snapshot.items, {
                itemType = itemType,
                quantity = stock.quantity,
                buyPrice = math.max(1, math.floor(stock.basePrice * multiplier)),
                sellPrice = math.max(1, math.floor(stock.basePrice * SEConfig.BUY_SELL_SPREAD)),
            })
        end
    end

    return snapshot
end

return SETraderManager
