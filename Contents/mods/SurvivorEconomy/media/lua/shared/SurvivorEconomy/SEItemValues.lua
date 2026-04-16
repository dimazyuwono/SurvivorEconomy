-- SEItemValues.lua
-- Master price table for all tradeable items.
-- Maps item full types to their base sell prices at traders.
-- Buy price (what players pay) = basePrice
-- Sell price (what players receive) = basePrice * SEConfig.BUY_SELL_SPREAD

require "SurvivorEconomy/SEConfig"

SEItemValues = {}

-- Base prices for common PZ items (what traders charge to sell)
-- Traders buy FROM players at BUY_SELL_SPREAD (50%) of these prices
SEItemValues.PRICES = {
    -- Tools
    ["Base.Axe"]             = 15,
    ["Base.Hammer"]          = 8,
    ["Base.Screwdriver"]     = 6,
    ["Base.Saw"]             = 10,
    ["Base.Crowbar"]         = 15,
    ["Base.Wrench"]          = 8,
    ["Base.Trowel"]          = 5,

    -- Building materials
    ["Base.Plank"]           = 3,
    ["Base.Nails"]           = 2,
    ["Base.MetalSheet"]      = 8,
    ["Base.MetalBar"]        = 6,
    ["Base.Wire"]            = 4,
    ["Base.Gravelbag"]       = 5,
    ["Base.Sandbag"]         = 4,
    ["Base.DuctTape"]        = 6,
    ["Base.Rope"]            = 5,
    ["Base.Generator"]       = 80,

    -- Weapons
    ["Base.Pistol"]          = 40,
    ["Base.Shotgun"]         = 60,
    ["Base.HuntingRifle"]    = 55,
    ["Base.BaseballBat"]     = 12,
    ["Base.Katana"]          = 50,
    ["Base.HuntingKnife"]    = 10,

    -- Ammo
    ["Base.Bullets9mm"]      = 10,
    ["Base.ShotgunShells"]   = 12,
    ["Base.223Bullets"]      = 12,

    -- Medical
    ["Base.Bandage"]         = 3,
    ["Base.AlcoholBandage"]  = 5,
    ["Base.SutureNeedle"]    = 8,
    ["Base.Antibiotics"]     = 15,
    ["Base.PainKillers"]     = 6,
    ["Base.Disinfectant"]    = 8,
    ["Base.FirstAidKit"]     = 20,
    ["Base.Vitamins"]        = 5,

    -- Food & Water
    ["Base.WaterBottleFull"] = 3,
    ["Base.CannedBeans"]     = 4,
    ["Base.Can"]             = 3,
    ["Base.CannedCorn"]      = 4,
    ["Base.CannedChili"]     = 5,
    ["Base.Rice"]            = 4,
    ["Base.Pasta"]           = 3,
    ["Base.Sugar"]           = 2,
    ["Base.Flour"]           = 3,

    -- Luxury
    ["Base.Cigarettes"]      = 8,
    ["Base.Wine"]            = 12,
    ["Base.Whiskey"]         = 15,
    ["Base.CDplayer"]        = 10,
    ["Base.Magazine"]        = 5,

    -- Skill books (premium)
    ["Base.BookCarpentry1"]  = 10,
    ["Base.BookCarpentry2"]  = 15,
    ["Base.BookCarpentry3"]  = 20,
    ["Base.BookCarpentry4"]  = 30,
    ["Base.BookElectricity1"] = 10,
    ["Base.BookElectricity2"] = 15,
    ["Base.BookElectricity3"] = 20,
    ["Base.BookElectricity4"] = 30,
    ["Base.BookFirstAid1"]   = 10,
    ["Base.BookFirstAid2"]   = 15,
    ["Base.BookCooking1"]    = 8,
    ["Base.BookCooking2"]    = 12,
    ["Base.BookFarming1"]    = 10,
    ["Base.BookFarming2"]    = 15,

    -- Farming supplies (economy items)
    ["SurvivorEconomy.Manure"]        = 8,
    ["SurvivorEconomy.PremiumSeeds"]   = 15,
    ["SurvivorEconomy.IrrigationKit"]  = 15,
    ["SurvivorEconomy.PestSpray"]      = 6,

    -- Crops (base sell value — players sell these TO traders)
    ["farming.Cabbage"]      = 2,
    ["farming.Potato"]       = 2,
    ["farming.Tomato"]       = 3,
    ["farming.Strawberry"]   = 4,
    ["farming.Corn"]         = 5,
    ["farming.Broccoli"]     = 5,

    -- Clothing (common)
    ["Base.Shoes"]           = 3,
    ["Base.Jacket"]          = 5,
    ["Base.Bag_BigHikingBag"] = 20,
    ["Base.Bag_NormalHikingBag"] = 15,

    -- Vehicle parts
    ["Base.TirePump"]        = 6,
    ["Base.JackHandle"]      = 5,
    ["Base.LugWrench"]       = 5,
    ["Base.GasCan"]          = 8,
}

--- Look up the base price for an item.
--- @param itemFullType string
--- @return number|nil
function SEItemValues.getBasePrice(itemFullType)
    return SEItemValues.PRICES[itemFullType]
end

--- Get what a trader would pay the player for an item (buy price).
--- @param itemFullType string
--- @return number|nil
function SEItemValues.getBuyFromPlayerPrice(itemFullType)
    local base = SEItemValues.PRICES[itemFullType]
    if not base then return nil end
    return math.max(1, math.floor(base * SEConfig.BUY_SELL_SPREAD))
end

return SEItemValues
