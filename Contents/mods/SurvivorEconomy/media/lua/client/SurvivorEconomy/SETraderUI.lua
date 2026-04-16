-- SETraderUI.lua
-- ISPanel-derived trading interface for NPC traders.
-- Shows trader inventory with buy/sell functionality.

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
require "ISUI/ISLabel"
require "SurvivorEconomy/SEConstants"
require "SurvivorEconomy/SEUtils"
require "SurvivorEconomy/SEItemValues"

SETraderUI = ISPanel:derive("SETraderUI")

local PANEL_WIDTH = 600
local PANEL_HEIGHT = 450
local HEADER_HEIGHT = 40
local FOOTER_HEIGHT = 60
local LIST_PADDING = 10
local BUTTON_WIDTH = 80
local BUTTON_HEIGHT = 28

-- Trader type display names
local TRADER_NAMES = {
    general  = "General Store",
    weapons  = "Weapons Dealer",
    medical  = "Medical Supplies",
    building = "Building Materials",
    farm     = "Farm Market",
    luxury   = "Luxury Goods",
}

--- Create a new trader UI panel.
--- @param x number
--- @param y number
--- @param player IsoPlayer
--- @param traderType string
--- @param traderData table snapshot from server
--- @return SETraderUI
function SETraderUI:new(x, y, player, traderType, traderData)
    local o = ISPanel:new(x, y, PANEL_WIDTH, PANEL_HEIGHT)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.traderType = traderType
    o.traderData = traderData or { items = {} }
    o.selectedBuyItem = nil
    o.selectedSellItem = nil
    o.moveWithMouse = true
    o.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1.0 }

    return o
end

--- Initialize UI elements.
function SETraderUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

--- Build all UI components.
function SETraderUI:create()
    local traderName = TRADER_NAMES[self.traderType] or "Trader"
    local halfWidth = (PANEL_WIDTH - LIST_PADDING * 3) / 2

    -- Title label
    self.titleLabel = ISLabel:new(
        PANEL_WIDTH / 2 - 60, 8, HEADER_HEIGHT - 16,
        traderName, 1, 1, 0.8, 1,
        UIFont.Medium, true
    )
    self:addChild(self.titleLabel)

    -- Token balance label
    self.tokenLabel = ISLabel:new(
        PANEL_WIDTH - 180, 12, 20,
        "Tokens: 0", 0.8, 1, 0.3, 1,
        UIFont.Small, true
    )
    self:addChild(self.tokenLabel)

    -- === Left side: Trader inventory (Buy from trader) ===
    local buyLabelY = HEADER_HEIGHT
    self.buyLabel = ISLabel:new(
        LIST_PADDING, buyLabelY, 20,
        "Buy from Trader", 0.7, 0.9, 1, 1,
        UIFont.Small, true
    )
    self:addChild(self.buyLabel)

    local listY = buyLabelY + 22
    local listHeight = PANEL_HEIGHT - listY - FOOTER_HEIGHT - LIST_PADDING

    self.buyList = ISScrollingListBox:new(
        LIST_PADDING, listY, halfWidth, listHeight
    )
    self.buyList:initialise()
    self.buyList:instantiate()
    self.buyList.itemheight = 28
    self.buyList.drawBorder = true
    self.buyList.doDrawItem = self.drawBuyItem
    self.buyList.target = self
    self.buyList.onmousedown = SETraderUI.onBuyListSelect
    self:addChild(self.buyList)

    -- Buy button
    self.buyButton = ISButton:new(
        LIST_PADDING + halfWidth / 2 - BUTTON_WIDTH / 2,
        PANEL_HEIGHT - FOOTER_HEIGHT + 8,
        BUTTON_WIDTH, BUTTON_HEIGHT,
        "Buy", self, SETraderUI.onBuyClick
    )
    self.buyButton:initialise()
    self.buyButton:instantiate()
    self.buyButton.borderColor = { r = 0.3, g = 0.7, b = 0.3, a = 1 }
    self:addChild(self.buyButton)

    -- === Right side: Player inventory (Sell to trader) ===
    local rightX = LIST_PADDING * 2 + halfWidth
    self.sellLabel = ISLabel:new(
        rightX, buyLabelY, 20,
        "Sell to Trader", 0.7, 0.9, 1, 1,
        UIFont.Small, true
    )
    self:addChild(self.sellLabel)

    self.sellList = ISScrollingListBox:new(
        rightX, listY, halfWidth, listHeight
    )
    self.sellList:initialise()
    self.sellList:instantiate()
    self.sellList.itemheight = 28
    self.sellList.drawBorder = true
    self.sellList.doDrawItem = self.drawSellItem
    self.sellList.target = self
    self.sellList.onmousedown = SETraderUI.onSellListSelect
    self:addChild(self.sellList)

    -- Sell button
    self.sellButton = ISButton:new(
        rightX + halfWidth / 2 - BUTTON_WIDTH / 2,
        PANEL_HEIGHT - FOOTER_HEIGHT + 8,
        BUTTON_WIDTH, BUTTON_HEIGHT,
        "Sell", self, SETraderUI.onSellClick
    )
    self.sellButton:initialise()
    self.sellButton:instantiate()
    self.sellButton.borderColor = { r = 0.7, g = 0.3, b = 0.3, a = 1 }
    self:addChild(self.sellButton)

    -- Close button
    self.closeButton = ISButton:new(
        PANEL_WIDTH - 70, 8, 60, 24,
        "Close", self, SETraderUI.onCloseClick
    )
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self:addChild(self.closeButton)

    -- Populate lists
    self:refreshBuyList()
    self:refreshSellList()
    self:updateTokenDisplay()
end

--- Refresh the buy list with current trader data.
function SETraderUI:refreshBuyList()
    self.buyList:clear()

    if not self.traderData or not self.traderData.items then return end

    for _, item in ipairs(self.traderData.items) do
        if item.quantity > 0 then
            local scriptItem = ScriptManager.instance:getItem(item.itemType)
            local displayName = scriptItem and scriptItem:getDisplayName() or item.itemType
            self.buyList:addItem(displayName, {
                itemType = item.itemType,
                quantity = item.quantity,
                buyPrice = item.buyPrice,
                displayName = displayName,
            })
        end
    end
end

--- Refresh the sell list with sellable items from player inventory.
function SETraderUI:refreshSellList()
    self.sellList:clear()

    local container = self.player:getInventory()
    local allItems = container:getItems()

    -- Group items by type and count
    local itemCounts = {}
    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        local fullType = item:getFullType()

        -- Skip currency items
        if not SEConstants.CURRENCY_VALUES[fullType] then
            local sellPrice = SEItemValues.getBuyFromPlayerPrice(fullType)
            if sellPrice and sellPrice > 0 then
                if not itemCounts[fullType] then
                    itemCounts[fullType] = {
                        itemType = fullType,
                        quantity = 0,
                        sellPrice = sellPrice,
                        displayName = item:getDisplayName(),
                    }
                end
                itemCounts[fullType].quantity = itemCounts[fullType].quantity + 1
            end
        end
    end

    for _, data in pairs(itemCounts) do
        self.sellList:addItem(data.displayName, data)
    end
end

--- Update the token balance display.
function SETraderUI:updateTokenDisplay()
    local tokens = SEUtils.countTokens(self.player:getInventory())
    self.tokenLabel:setName("Tokens: " .. tokens)
end

--- Custom draw function for buy list items.
function SETraderUI.drawBuyItem(self, y, item, alt)
    local data = item.item
    if not data then return y + self.itemheight end

    local isSelected = self.selected == item.index

    -- Background
    if isSelected then
        self:drawRect(0, y, self:getWidth(), self.itemheight, 0.3, 0.3, 0.5, 0.8)
    elseif alt then
        self:drawRect(0, y, self:getWidth(), self.itemheight, 0.08, 0.08, 0.08, 0.5)
    end

    -- Item name
    self:drawText(data.displayName, 8, y + 4, 1, 1, 1, 1, UIFont.Small)

    -- Quantity
    self:drawText("x" .. data.quantity, self:getWidth() - 120, y + 4, 0.7, 0.7, 0.7, 1, UIFont.Small)

    -- Price
    self:drawText(data.buyPrice .. "t", self:getWidth() - 60, y + 4, 1, 0.85, 0.3, 1, UIFont.Small)

    return y + self.itemheight
end

--- Custom draw function for sell list items.
function SETraderUI.drawSellItem(self, y, item, alt)
    local data = item.item
    if not data then return y + self.itemheight end

    local isSelected = self.selected == item.index

    if isSelected then
        self:drawRect(0, y, self:getWidth(), self.itemheight, 0.3, 0.5, 0.3, 0.8)
    elseif alt then
        self:drawRect(0, y, self:getWidth(), self.itemheight, 0.08, 0.08, 0.08, 0.5)
    end

    -- Item name
    self:drawText(data.displayName, 8, y + 4, 1, 1, 1, 1, UIFont.Small)

    -- Quantity
    self:drawText("x" .. data.quantity, self:getWidth() - 120, y + 4, 0.7, 0.7, 0.7, 1, UIFont.Small)

    -- Sell price
    self:drawText(data.sellPrice .. "t", self:getWidth() - 60, y + 4, 0.3, 1, 0.3, 1, UIFont.Small)

    return y + self.itemheight
end

--- Handle buy list item selection.
function SETraderUI:onBuyListSelect(item)
    if self.buyList.selected then
        local selected = self.buyList.items[self.buyList.selected]
        if selected then
            self.selectedBuyItem = selected.item
        end
    end
end

--- Handle sell list item selection.
function SETraderUI:onSellListSelect(item)
    if self.sellList.selected then
        local selected = self.sellList.items[self.sellList.selected]
        if selected then
            self.selectedSellItem = selected.item
        end
    end
end

--- Handle buy button click.
function SETraderUI:onBuyClick()
    if not self.selectedBuyItem then return end

    sendClientCommand(self.player, SEConstants.MOD_ID, SEConstants.CMD.BUY_ITEM, {
        traderType = self.traderType,
        itemType = self.selectedBuyItem.itemType,
        quantity = 1,
    })
end

--- Handle sell button click.
function SETraderUI:onSellClick()
    if not self.selectedSellItem then return end

    sendClientCommand(self.player, SEConstants.MOD_ID, SEConstants.CMD.SELL_ITEM, {
        traderType = self.traderType,
        itemType = self.selectedSellItem.itemType,
        quantity = 1,
    })
end

--- Handle close button click.
function SETraderUI:onCloseClick()
    self:setVisible(false)
    self:removeFromUIManager()
    SETraderUI.instance = nil
end

--- Update trader data and refresh the UI (called when server sends new data).
--- @param traderData table
function SETraderUI:updateTraderData(traderData)
    self.traderData = traderData
    self:refreshBuyList()
    self:refreshSellList()
    self:updateTokenDisplay()
end

--- Called every frame.
function SETraderUI:update()
    ISPanel.update(self)
    self:updateTokenDisplay()
end

--- Open the trader UI (static method).
--- @param player IsoPlayer
--- @param traderType string
--- @param traderData table
function SETraderUI.open(player, traderType, traderData)
    if SETraderUI.instance then
        SETraderUI.instance:onCloseClick()
    end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = (screenW - PANEL_WIDTH) / 2
    local y = (screenH - PANEL_HEIGHT) / 2

    local ui = SETraderUI:new(x, y, player, traderType, traderData)
    ui:initialise()
    ui:addToUIManager()
    ui:setVisible(true)

    SETraderUI.instance = ui
    return ui
end

return SETraderUI
