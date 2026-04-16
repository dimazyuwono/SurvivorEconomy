-- SEConfig.lua
-- Central configuration for all tunable economy parameters.
-- Server admins can adjust these values via sandbox options.

SEConfig = {}

---------------------------------------------------------------------------
-- Currency
---------------------------------------------------------------------------
SEConfig.DEATH_TOKEN_LOSS_PERCENT = 20       -- % of carried tokens destroyed on death

---------------------------------------------------------------------------
-- Traders
---------------------------------------------------------------------------
SEConfig.TRADER_RESTOCK_HOURS = 72           -- in-game hours between restocks
SEConfig.TRADER_MAX_STOCK_PER_ITEM = 5       -- max quantity of any single item per restock
SEConfig.BUY_SELL_SPREAD = 0.5               -- traders buy at this fraction of sell price
SEConfig.PRICE_ESCALATION_PERCENT = 5        -- price increase per purchase until restock

---------------------------------------------------------------------------
-- Token Decay
---------------------------------------------------------------------------
SEConfig.TOKEN_DECAY_DAYS = 14               -- in-game days before tokens in unvisited containers decay

---------------------------------------------------------------------------
-- Farming Economy
---------------------------------------------------------------------------
SEConfig.SEASONAL_PRICE_MULTIPLIER = 2.0     -- out-of-season crop sell multiplier
SEConfig.BULK_SELL_THRESHOLD = 10            -- minimum quantity for bulk bonus
SEConfig.BULK_SELL_BONUS = 0.10              -- 10% bonus for bulk sales
SEConfig.FARM_TRADER_BUY_BONUS = 0.25        -- Farm Trader pays 25% more for crops than General

-- Farming supply costs (in token value)
SEConfig.FARM_SUPPLY_PRICES = {
    manure          = 8,
    premiumSeeds    = 15,
    irrigationKit   = 15,
    pestSpray       = 6,
}

-- Farming supply effects
SEConfig.MANURE_GROWTH_BOOST = 0.50          -- 50% faster crop growth
SEConfig.IRRIGATION_DURATION_DAYS = 7        -- days the irrigation kit lasts
SEConfig.PREMIUM_SEED_YIELD_BONUS = 0.50     -- 50% more crop yield

-- Crop growing seasons (month ranges, 1=Jan)
SEConfig.CROP_SEASONS = {
    cabbage    = { start = 3, stop = 9 },    -- Mar-Sep
    potato     = { start = 3, stop = 9 },
    tomato     = { start = 4, stop = 8 },
    strawberry = { start = 4, stop = 8 },
    corn       = { start = 5, stop = 9 },
    broccoli   = { start = 3, stop = 10 },
}

-- Base crop sell prices (at General Trader; Farm Trader pays more)
SEConfig.CROP_PRICES = {
    ["farming.Cabbage"]    = 2,
    ["farming.Potato"]     = 2,
    ["farming.Tomato"]     = 3,
    ["farming.Strawberry"] = 4,
    ["farming.Corn"]       = 5,
    ["farming.Broccoli"]   = 5,
}

---------------------------------------------------------------------------
-- Trader Inventory Pools (items available per trader type)
-- Format: { itemType = "Module.ItemName", basePrice = N, weight = N }
-- weight = relative spawn chance during restock
---------------------------------------------------------------------------
SEConfig.TRADER_POOLS = {
    general = {
        { itemType = "Base.Axe",            basePrice = 15, weight = 3 },
        { itemType = "Base.Hammer",         basePrice = 8,  weight = 5 },
        { itemType = "Base.Nails",          basePrice = 2,  weight = 8 },
        { itemType = "Base.Screwdriver",    basePrice = 6,  weight = 5 },
        { itemType = "Base.Saw",            basePrice = 10, weight = 3 },
        { itemType = "Base.WaterBottleFull", basePrice = 3, weight = 6 },
        { itemType = "Base.CannedBeans",    basePrice = 4,  weight = 6 },
        { itemType = "Base.Can",            basePrice = 3,  weight = 7 },
        { itemType = "Base.Rope",           basePrice = 5,  weight = 4 },
        { itemType = "Base.DuctTape",       basePrice = 6,  weight = 4 },
    },
    weapons = {
        { itemType = "Base.Pistol",         basePrice = 40, weight = 2 },
        { itemType = "Base.Shotgun",        basePrice = 60, weight = 1 },
        { itemType = "Base.HuntingRifle",   basePrice = 55, weight = 1 },
        { itemType = "Base.BaseballBat",    basePrice = 12, weight = 5 },
        { itemType = "Base.Crowbar",        basePrice = 15, weight = 4 },
        { itemType = "Base.Katana",         basePrice = 50, weight = 1 },
        { itemType = "Base.Bullets9mm",     basePrice = 10, weight = 4 },
        { itemType = "Base.ShotgunShells",  basePrice = 12, weight = 3 },
        { itemType = "Base.HuntingKnife",   basePrice = 10, weight = 4 },
    },
    medical = {
        { itemType = "Base.Bandage",        basePrice = 3,  weight = 8 },
        { itemType = "Base.AlcoholBandage", basePrice = 5,  weight = 5 },
        { itemType = "Base.SutureNeedle",   basePrice = 8,  weight = 3 },
        { itemType = "Base.Antibiotics",    basePrice = 15, weight = 2 },
        { itemType = "Base.PainKillers",    basePrice = 6,  weight = 5 },
        { itemType = "Base.Disinfectant",   basePrice = 8,  weight = 4 },
        { itemType = "Base.FirstAidKit",    basePrice = 20, weight = 1 },
        { itemType = "Base.Vitamins",       basePrice = 5,  weight = 5 },
    },
    building = {
        { itemType = "Base.Plank",          basePrice = 3,  weight = 8 },
        { itemType = "Base.Nails",          basePrice = 2,  weight = 10 },
        { itemType = "Base.MetalSheet",     basePrice = 8,  weight = 4 },
        { itemType = "Base.MetalBar",       basePrice = 6,  weight = 5 },
        { itemType = "Base.Wire",           basePrice = 4,  weight = 6 },
        { itemType = "Base.Gravelbag",      basePrice = 5,  weight = 5 },
        { itemType = "Base.Sandbag",        basePrice = 4,  weight = 6 },
        { itemType = "Base.Generator",      basePrice = 80, weight = 1 },
    },
    farm = {
        { itemType = "SurvivorEconomy.Manure",         basePrice = 8,  weight = 6 },
        { itemType = "SurvivorEconomy.PremiumSeeds",    basePrice = 15, weight = 3 },
        { itemType = "SurvivorEconomy.IrrigationKit",   basePrice = 15, weight = 3 },
        { itemType = "SurvivorEconomy.PestSpray",       basePrice = 6,  weight = 5 },
        { itemType = "Base.Trowel",                     basePrice = 5,  weight = 5 },
        { itemType = "Base.GardeningSprayEmpty",        basePrice = 3,  weight = 4 },
    },
    luxury = {
        { itemType = "Base.Cigarettes",     basePrice = 8,  weight = 5 },
        { itemType = "Base.Wine",           basePrice = 12, weight = 3 },
        { itemType = "Base.Whiskey",        basePrice = 15, weight = 2 },
        { itemType = "Base.CDplayer",       basePrice = 10, weight = 3 },
        { itemType = "Base.Magazine",       basePrice = 5,  weight = 6 },
        { itemType = "Base.BookCarpentry4", basePrice = 30, weight = 1 },
        { itemType = "Base.BookElectricity4", basePrice = 30, weight = 1 },
    },
}

return SEConfig
