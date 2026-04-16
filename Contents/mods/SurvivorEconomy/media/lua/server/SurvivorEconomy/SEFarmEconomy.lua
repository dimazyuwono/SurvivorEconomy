-- SEFarmEconomy.lua
-- Server-side farming economy: crop pricing, farming supply effects.

require "SurvivorEconomy/SEConstants"
require "SurvivorEconomy/SEConfig"
require "SurvivorEconomy/SEUtils"

SEFarmEconomy = {}

-- Farm supply item types
local FARM_SUPPLIES = {
    ["SurvivorEconomy.Manure"]        = "manure",
    ["SurvivorEconomy.PremiumSeeds"]   = "premiumSeeds",
    ["SurvivorEconomy.IrrigationKit"]  = "irrigationKit",
    ["SurvivorEconomy.PestSpray"]      = "pestSpray",
}

--- Process using a farming supply item on a crop plot.
--- The item is consumed (removed from inventory) and the effect is applied
--- to the target crop plot via its modData.
--- @param player IsoPlayer
--- @param itemType string the farm supply item type
--- @param args table additional args (e.g., target plot coordinates)
--- @return table result {success, message}
function SEFarmEconomy.useFarmItem(player, itemType, args)
    local supplyKey = FARM_SUPPLIES[itemType]
    if not supplyKey then
        return { success = false, message = "Not a farming supply" }
    end

    -- Check player has the item
    local container = player:getInventory()
    local item = container:getFirstTypeRecurse(itemType)
    if not item then
        return { success = false, message = "You don't have this item" }
    end

    -- Get the target square (where the crop plot is)
    local targetX = args.x
    local targetY = args.y
    local targetZ = args.z

    if not targetX or not targetY then
        return { success = false, message = "No target location specified" }
    end

    local square = getCell():getGridSquare(targetX, targetY, targetZ or 0)
    if not square then
        return { success = false, message = "Invalid location" }
    end

    -- Apply the effect based on supply type
    local result = SEFarmEconomy.applySupplyEffect(supplyKey, square, player)

    if result.success then
        -- Consume the item
        container:Remove(item)
        print("[SurvivorEconomy] " .. player:getUsername() .. " used " .. supplyKey .. " at " .. targetX .. "," .. targetY)
    end

    return result
end

--- Apply a farming supply's effect to a square.
--- Effects are stored in the square's modData for the farming system to read.
--- @param supplyKey string
--- @param square IsoGridSquare
--- @param player IsoPlayer
--- @return table result
function SEFarmEconomy.applySupplyEffect(supplyKey, square, player)
    local modData = square:getModData()

    if supplyKey == "manure" then
        -- Manure: boost growth speed by 50%
        modData["SE_GrowthBoost"] = SEConfig.MANURE_GROWTH_BOOST
        modData["SE_GrowthBoostExpiry"] = getGameTime():getWorldAgeHours() + (24 * 7) -- lasts 7 days
        return { success = true, message = "Applied manure - crops will grow 50% faster" }

    elseif supplyKey == "premiumSeeds" then
        -- Premium Seeds: boost yield by 50% for next harvest
        modData["SE_YieldBoost"] = SEConfig.PREMIUM_SEED_YIELD_BONUS
        return { success = true, message = "Planted premium seeds - next harvest yields 50% more" }

    elseif supplyKey == "irrigationKit" then
        -- Irrigation Kit: auto-water for 7 days
        modData["SE_AutoWater"] = true
        modData["SE_AutoWaterExpiry"] = getGameTime():getWorldAgeHours() + (24 * SEConfig.IRRIGATION_DURATION_DAYS)
        return { success = true, message = "Installed irrigation - auto-watering for " .. SEConfig.IRRIGATION_DURATION_DAYS .. " days" }

    elseif supplyKey == "pestSpray" then
        -- Pest Spray: prevent disease for this growing cycle
        modData["SE_PestProtection"] = true
        modData["SE_PestProtectionExpiry"] = getGameTime():getWorldAgeHours() + (24 * 14) -- 14 day protection
        return { success = true, message = "Applied pest spray - crops protected from disease" }
    end

    return { success = false, message = "Unknown supply type" }
end

--- Check if a square has an active farming boost.
--- Can be called by other systems to check buff status.
--- @param square IsoGridSquare
--- @param boostKey string modData key to check
--- @return boolean
function SEFarmEconomy.hasActiveBoost(square, boostKey)
    local modData = square:getModData()
    local value = modData[boostKey]
    if not value then return false end

    -- Check expiry if applicable
    local expiryKey = boostKey .. "Expiry"
    local expiry = modData[expiryKey]
    if expiry then
        local currentHour = getGameTime():getWorldAgeHours()
        if currentHour > expiry then
            -- Expired, clean up
            modData[boostKey] = nil
            modData[expiryKey] = nil
            return false
        end
    end

    return true
end

--- Get the effective sell price modifier for a crop from a specific square.
--- Accounts for premium seeds yield boost.
--- @param square IsoGridSquare
--- @return number multiplier (1.0 = normal, 1.5 = premium seeds active)
function SEFarmEconomy.getHarvestMultiplier(square)
    local multiplier = 1.0

    if SEFarmEconomy.hasActiveBoost(square, "SE_YieldBoost") then
        multiplier = multiplier + (square:getModData()["SE_YieldBoost"] or 0)
        -- Consume the boost on harvest
        square:getModData()["SE_YieldBoost"] = nil
    end

    return multiplier
end

return SEFarmEconomy
