-- SEConstants.lua
-- String constants for modData keys, command names, and identifiers.
-- Centralizes all magic strings to prevent typos.

SEConstants = {}

-- Mod identifier used for sendClientCommand / sendServerCommand
SEConstants.MOD_ID = "SurvivorEconomy"

-- Item full types for currency denominations
SEConstants.CURRENCY = {
    SCRAP_CHIP   = "SurvivorEconomy.ScrapChip",
    TRADE_TOKEN  = "SurvivorEconomy.TradeToken",
    SURVIVOR_COIN = "SurvivorEconomy.SurvivorCoin",
}

-- Currency values per denomination
SEConstants.CURRENCY_VALUES = {
    ["SurvivorEconomy.ScrapChip"]   = 1,
    ["SurvivorEconomy.TradeToken"]  = 5,
    ["SurvivorEconomy.SurvivorCoin"] = 25,
}

-- Ordered from highest to lowest for optimal change-making
SEConstants.DENOMINATIONS = {
    { type = "SurvivorEconomy.SurvivorCoin", value = 25 },
    { type = "SurvivorEconomy.TradeToken",   value = 5 },
    { type = "SurvivorEconomy.ScrapChip",    value = 1 },
}

-- Client -> Server command names
SEConstants.CMD = {
    BUY_ITEM      = "buyItem",
    SELL_ITEM     = "sellItem",
    REQUEST_TRADER = "requestTrader",
    USE_FARM_ITEM = "useFarmItem",
}

-- Server -> Client response names
SEConstants.RESP = {
    BUY_RESULT     = "buyResult",
    SELL_RESULT    = "sellResult",
    TRADER_DATA    = "traderData",
    FARM_RESULT    = "farmResult",
}

-- GlobalModData keys
SEConstants.GLOBAL = {
    TRADER_STATE   = "SE_TraderState",
    ECONOMY_STATE  = "SE_EconomyState",
}

-- Player modData keys (nested under player:getModData().SurvivorEconomy)
SEConstants.PLAYER = {
    ROOT           = "SurvivorEconomy",
    LIFETIME_EARNED = "lifetimeEarned",
    LIFETIME_SPENT  = "lifetimeSpent",
    SERVICE_USES    = "serviceUses",
}

-- Trader type identifiers
SEConstants.TRADER_TYPE = {
    GENERAL  = "general",
    WEAPONS  = "weapons",
    MEDICAL  = "medical",
    BUILDING = "building",
    FARM     = "farm",
    LUXURY   = "luxury",
}

-- Seasons for farming price multipliers
SEConstants.SEASON = {
    SPRING = "spring",
    SUMMER = "summer",
    AUTUMN = "autumn",
    WINTER = "winter",
}

return SEConstants
