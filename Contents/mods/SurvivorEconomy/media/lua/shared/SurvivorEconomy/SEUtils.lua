-- SEUtils.lua
-- Shared utility functions for token counting, adding, and removing.
-- Used by both client (for display) and server (for transactions).

require "SurvivorEconomy/SEConstants"
require "SurvivorEconomy/SEConfig"

SEUtils = {}

--- Count the total token value in an inventory container.
--- @param container ItemContainer
--- @return number total value in token units
function SEUtils.countTokens(container)
    local total = 0
    for _, denom in ipairs(SEConstants.DENOMINATIONS) do
        local items = container:getItemsFromFullType(denom.type)
        if items then
            total = total + (items:size() * denom.value)
        end
    end
    return total
end

--- Remove a specific token value from an inventory container.
--- Uses largest denominations first to minimize item count.
--- @param container ItemContainer
--- @param amount number value to remove
--- @return boolean true if successful, false if insufficient funds
function SEUtils.removeTokens(container, amount)
    if SEUtils.countTokens(container) < amount then
        return false
    end

    local remaining = amount

    -- Remove from largest denomination first
    for _, denom in ipairs(SEConstants.DENOMINATIONS) do
        if remaining <= 0 then break end

        local items = container:getItemsFromFullType(denom.type)
        if items then
            local count = items:size()
            local needed = math.floor(remaining / denom.value)
            local toRemove = math.min(needed, count)

            for i = 1, toRemove do
                container:Remove(items:get(i - 1))
            end
            remaining = remaining - (toRemove * denom.value)
        end
    end

    -- If we over-removed (because we removed a large coin for a small amount),
    -- give back change
    if remaining < 0 then
        SEUtils.addTokens(container, math.abs(remaining))
    end

    return true
end

--- Add tokens of a specific value to an inventory container.
--- Automatically uses the most efficient denomination combination.
--- @param container ItemContainer
--- @param amount number value to add
function SEUtils.addTokens(container, amount)
    local remaining = amount

    for _, denom in ipairs(SEConstants.DENOMINATIONS) do
        if remaining <= 0 then break end

        local count = math.floor(remaining / denom.value)
        for _ = 1, count do
            container:AddItem(denom.type)
        end
        remaining = remaining - (count * denom.value)
    end
end

--- Get the sell price of an item at a trader.
--- Returns nil if the item is not tradeable.
--- @param itemFullType string e.g. "Base.Axe"
--- @param traderType string e.g. "general", "farm"
--- @return number|nil sell price or nil
function SEUtils.getItemSellPrice(itemFullType, traderType)
    -- Check crop prices first
    local cropPrice = SEConfig.CROP_PRICES[itemFullType]
    if cropPrice then
        local price = cropPrice
        -- Farm trader pays more for crops
        if traderType == SEConstants.TRADER_TYPE.FARM then
            price = math.floor(price * (1 + SEConfig.FARM_TRADER_BUY_BONUS))
        end
        return math.floor(price * SEConfig.BUY_SELL_SPREAD)
    end

    -- Check trader pool for base price
    local pools = SEConfig.TRADER_POOLS
    for _, pool in pairs(pools) do
        for _, entry in ipairs(pool) do
            if entry.itemType == itemFullType then
                return math.floor(entry.basePrice * SEConfig.BUY_SELL_SPREAD)
            end
        end
    end

    return nil
end

--- Get the current in-game season based on month.
--- @return string season name from SEConstants.SEASON
function SEUtils.getCurrentSeason()
    local gameTime = getGameTime()
    if not gameTime then return SEConstants.SEASON.SUMMER end

    local month = gameTime:getMonth() + 1  -- getMonth() is 0-indexed

    if month >= 3 and month <= 5 then
        return SEConstants.SEASON.SPRING
    elseif month >= 6 and month <= 8 then
        return SEConstants.SEASON.SUMMER
    elseif month >= 9 and month <= 11 then
        return SEConstants.SEASON.AUTUMN
    else
        return SEConstants.SEASON.WINTER
    end
end

--- Check if a crop is in season based on the current in-game month.
--- @param cropKey string key into SEConfig.CROP_SEASONS (e.g. "tomato")
--- @return boolean
function SEUtils.isCropInSeason(cropKey)
    local season = SEConfig.CROP_SEASONS[cropKey]
    if not season then return true end

    local gameTime = getGameTime()
    if not gameTime then return true end

    local month = gameTime:getMonth() + 1
    return month >= season.start and month <= season.stop
end

--- Calculate the sell price for a crop, factoring in season and bulk.
--- @param cropFullType string e.g. "farming.Tomato"
--- @param cropKey string e.g. "tomato" (key for season lookup)
--- @param quantity number how many being sold
--- @param traderType string trader type
--- @return number price per unit
function SEUtils.getCropSellPrice(cropFullType, cropKey, quantity, traderType)
    local basePrice = SEConfig.CROP_PRICES[cropFullType]
    if not basePrice then return 0 end

    local price = basePrice

    -- Farm trader bonus
    if traderType == SEConstants.TRADER_TYPE.FARM then
        price = price * (1 + SEConfig.FARM_TRADER_BUY_BONUS)
    end

    -- Buy/sell spread (traders buy at fraction of value)
    price = price * SEConfig.BUY_SELL_SPREAD

    -- Seasonal multiplier (out of season = bonus)
    if not SEUtils.isCropInSeason(cropKey) then
        price = price * SEConfig.SEASONAL_PRICE_MULTIPLIER
    end

    -- Bulk bonus
    if quantity >= SEConfig.BULK_SELL_THRESHOLD then
        price = price * (1 + SEConfig.BULK_SELL_BONUS)
    end

    return math.floor(price)
end

--- Initialize player modData for the economy system.
--- @param player IsoPlayer
function SEUtils.initPlayerData(player)
    local modData = player:getModData()
    if not modData[SEConstants.PLAYER.ROOT] then
        modData[SEConstants.PLAYER.ROOT] = {
            [SEConstants.PLAYER.LIFETIME_EARNED] = 0,
            [SEConstants.PLAYER.LIFETIME_SPENT] = 0,
            [SEConstants.PLAYER.SERVICE_USES] = {},
        }
    end
end

--- Track tokens earned by a player (for stats).
--- @param player IsoPlayer
--- @param amount number
function SEUtils.trackEarned(player, amount)
    SEUtils.initPlayerData(player)
    local data = player:getModData()[SEConstants.PLAYER.ROOT]
    data[SEConstants.PLAYER.LIFETIME_EARNED] = (data[SEConstants.PLAYER.LIFETIME_EARNED] or 0) + amount
end

--- Track tokens spent by a player (for stats).
--- @param player IsoPlayer
--- @param amount number
function SEUtils.trackSpent(player, amount)
    SEUtils.initPlayerData(player)
    local data = player:getModData()[SEConstants.PLAYER.ROOT]
    data[SEConstants.PLAYER.LIFETIME_SPENT] = (data[SEConstants.PLAYER.LIFETIME_SPENT] or 0) + amount
end

return SEUtils
