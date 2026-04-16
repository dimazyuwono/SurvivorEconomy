-- SEContextMenus.lua
-- Client-side right-click context menu hooks for trading posts.
-- Adds "Trade" option when player right-clicks a Trading Post world object.

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
        -- Check if this is an IsoObject with an item attached
        local square = worldObj:getSquare()
        if square then
            local objects = square:getObjects()
            for i = 0, objects:size() - 1 do
                local obj = objects:get(i)
                local sprite = obj:getSprite()
                local objName = obj:getName()

                -- Check object modData for trading post type
                local modData = obj:getModData()
                if modData and modData["SE_TraderType"] then
                    local traderType = modData["SE_TraderType"]
                    local traderName = TRADER_NAMES[traderType] or "Trader"

                    local option = context:addOption("Trade - " .. traderName, player, onTradeAction, traderType)

                    -- Show token count in tooltip
                    local tokenCount = SEUtils.countTokens(player:getInventory())
                    local tooltip = ISWorldObjectContextMenu.addToolTip()
                    tooltip.description = "Your tokens: " .. tokenCount
                    option.toolTip = tooltip
                end
            end
        end
    end
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
                context:addOption("Open " .. traderName, player, onTradeAction, traderType)
            end
        end
    end
end

-- Register event hooks
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)

return SEContextMenus
