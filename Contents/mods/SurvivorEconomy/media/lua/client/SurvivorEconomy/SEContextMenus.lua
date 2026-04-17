-- SEContextMenus.lua
-- Client-side right-click context menu hooks for trading posts.
-- Adds "Trade" option when player right-clicks a Trading Post world object.

require "ISUI/ISToolTip"
require "SurvivorEconomy/SEConstants"
require "SurvivorEconomy/SEUtils"

SEContextMenus = {}

-- Map Trading Post item types to trader types
local TRADING_POST_MAP = {
    ["SurvivorEconomy.TradingPost_General"]  = SEConstants.TRADER_TYPE.GENERAL,
    ["SurvivorEconomy.TradingPost_Weapons"]  = SEConstants.TRADER_TYPE.WEAPONS,
    ["SurvivorEconomy.TradingPost_Medical"]  = SEConstants.TRADER_TYPE.MEDICAL,
    ["SurvivorEconomy.TradingPost_Building"] = SEConstants.TRADER_TYPE.BUILDING,
    ["SurvivorEconomy.TradingPost_Farm"]     = SEConstants.TRADER_TYPE.FARM,
    ["SurvivorEconomy.TradingPost_Luxury"]   = SEConstants.TRADER_TYPE.LUXURY,
}

-- Trader type display names
local TRADER_NAMES = {
    [SEConstants.TRADER_TYPE.GENERAL]  = "General Store",
    [SEConstants.TRADER_TYPE.WEAPONS]  = "Weapons Dealer",
    [SEConstants.TRADER_TYPE.MEDICAL]  = "Medical Supplies",
    [SEConstants.TRADER_TYPE.BUILDING] = "Building Materials",
    [SEConstants.TRADER_TYPE.FARM]     = "Farm Market",
    [SEConstants.TRADER_TYPE.LUXURY]   = "Luxury Goods",
}

--- Handle the "Trade" context menu action.
--- Sends a request to the server for trader data, then opens the UI.
--- @param player IsoPlayer
--- @param traderType string
local function onTradeAction(player, traderType)
    -- Request trader data from server
    sendClientCommand(player, SEConstants.MOD_ID, SEConstants.CMD.REQUEST_TRADER, {
        traderType = traderType,
    })
end

--- Hook into world object context menu to add trading options.
--- @param playerIndex number
--- @param context ISContextMenu
--- @param worldObjects table
--- @param test boolean
local function onFillWorldObjectContextMenu(playerIndex, context, worldObjects, test)
    if test then return end

    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    for _, worldObj in ipairs(worldObjects) do
        if not worldObj or not worldObj.getSquare then break end
        local square = worldObj:getSquare()
        if square then
            local objects = square:getObjects()
            for i = 0, objects:size() - 1 do
                local obj = objects:get(i)

                -- Check object modData for trading post type
                local modData = obj:getModData()
                if modData and modData["SE_TraderType"] then
                    local traderType = modData["SE_TraderType"]
                    local traderName = TRADER_NAMES[traderType] or "Trader"

                    local option = context:addOption("Trade - " .. traderName, player, onTradeAction, traderType)

                    -- Show token count in tooltip
                    local tokenCount = SEUtils.countTokens(player:getInventory())
                    local tooltip = ISToolTip:new()
                    tooltip:initialise()
                    tooltip:setVisible(false)
                    tooltip.description = "Your tokens: " .. tokenCount
                    option.toolTip = tooltip

                    -- Add pickup option (admin)
                    if player:isAccessLevel("admin") or player:isAccessLevel("moderator") then
                        context:addOption("Pick Up " .. traderName, player, onPickupTradingPost, obj)
                    end
                end
            end
        end
    end
end

--- Place a Trading Post on the ground at the player's current square.
--- Creates an IsoObject with a table/crate sprite and tags it with SE_TraderType.
--- @param player IsoPlayer
--- @param item InventoryItem the Trading Post item to consume
--- @param traderType string
local function onPlaceTradingPost(player, item, traderType)
    local square = player:getCurrentSquare()
    if not square then return end

    -- Check if this square already has a trading post
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj:getModData() and obj:getModData()["SE_TraderType"] then
            player:Say("There's already a Trading Post here.")
            return
        end
    end

    -- Create a new world object with a crate sprite
    local cell = getCell()
    if not cell then return end
    local isoObj = IsoObject.new(cell, square, "furniture_storage_02_0")
    isoObj:setName("Trading Post")
    isoObj:getModData()["SE_TraderType"] = traderType
    square:AddSpecialObject(isoObj)
    isoObj:transmitCompleteItemToClients()

    -- Remove the item from inventory
    player:getInventory():Remove(item)

    local traderName = TRADER_NAMES[traderType] or "Trader"
    player:Say("Placed " .. traderName .. " Trading Post.")
end

--- Remove a Trading Post world object from the ground.
--- @param player IsoPlayer
--- @param worldObj IsoObject the trading post object to remove
local function onPickupTradingPost(player, worldObj)
    local traderType = worldObj:getModData()["SE_TraderType"]
    local square = worldObj:getSquare()

    -- Give back the Trading Post item
    local itemTypeMap = {
        [SEConstants.TRADER_TYPE.GENERAL]  = "SurvivorEconomy.TradingPost_General",
        [SEConstants.TRADER_TYPE.WEAPONS]  = "SurvivorEconomy.TradingPost_Weapons",
        [SEConstants.TRADER_TYPE.MEDICAL]  = "SurvivorEconomy.TradingPost_Medical",
        [SEConstants.TRADER_TYPE.BUILDING] = "SurvivorEconomy.TradingPost_Building",
        [SEConstants.TRADER_TYPE.FARM]     = "SurvivorEconomy.TradingPost_Farm",
        [SEConstants.TRADER_TYPE.LUXURY]   = "SurvivorEconomy.TradingPost_Luxury",
    }

    local itemType = itemTypeMap[traderType]
    if itemType then
        player:getInventory():AddItem(itemType)
    end

    -- Remove the world object
    square:transmitRemoveItemFromSquare(worldObj)

    local traderName = TRADER_NAMES[traderType] or "Trader"
    player:Say("Picked up " .. traderName .. " Trading Post.")
end

--- Also check inventory items that are Trading Posts (for placed items).
--- @param playerIndex number
--- @param context ISContextMenu
--- @param items table
local function onFillInventoryObjectContextMenu(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    for _, itemOrStack in ipairs(items) do
        local item
        if type(itemOrStack) == "table" then
            item = itemOrStack.items[1]
        else
            item = itemOrStack
        end

        if item then
            local fullType = item:getFullType()
            local traderType = TRADING_POST_MAP[fullType]

            if traderType then
                local traderName = TRADER_NAMES[traderType] or "Trader"
                context:addOption("Place " .. traderName, player, onPlaceTradingPost, item, traderType)
            end
        end
    end
end

-- Register event hooks
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)

return SEContextMenus
