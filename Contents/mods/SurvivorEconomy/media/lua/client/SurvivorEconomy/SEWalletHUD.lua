-- SEWalletHUD.lua
-- Small persistent HUD element in the corner showing the player's token balance.

require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "SurvivorEconomy/SEConstants"
require "SurvivorEconomy/SEUtils"

SEWalletHUD = ISPanel:derive("SEWalletHUD")

local HUD_WIDTH = 140
local HUD_HEIGHT = 32
local HUD_MARGIN = 10
local UPDATE_INTERVAL = 30  -- update every N ticks (~0.5 seconds at 60fps)

--- Create a new wallet HUD.
--- @param player IsoPlayer
--- @return SEWalletHUD
function SEWalletHUD:new(player)
    local screenW = getCore():getScreenWidth()
    local x = screenW - HUD_WIDTH - HUD_MARGIN
    local y = HUD_MARGIN

    local o = ISPanel:new(x, y, HUD_WIDTH, HUD_HEIGHT)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.7 }
    o.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.8 }
    o.moveWithMouse = false
    o.tickCount = 0
    o.lastTokenCount = 0

    return o
end

--- Initialize the HUD.
function SEWalletHUD:initialise()
    ISPanel.initialise(self)

    -- Token icon label (coin symbol)
    self.iconLabel = ISLabel:new(8, 6, 20, "[T]", 1, 0.85, 0.3, 1, UIFont.Small, true)
    self:addChild(self.iconLabel)

    -- Token count label
    self.countLabel = ISLabel:new(36, 6, 20, "0", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.countLabel)

    self:updateBalance()
end

--- Update the displayed token balance.
function SEWalletHUD:updateBalance()
    if not self.player or not self.player:getInventory() then return end

    local count = SEUtils.countTokens(self.player:getInventory())
    if count ~= self.lastTokenCount then
        self.lastTokenCount = count
        self.countLabel:setName(tostring(count) .. " tokens")
    end
end

--- Called every frame.
function SEWalletHUD:update()
    ISPanel.update(self)

    self.tickCount = self.tickCount + 1
    if self.tickCount >= UPDATE_INTERVAL then
        self.tickCount = 0
        self:updateBalance()
    end
end

--- Custom render with a subtle coin-colored top border.
function SEWalletHUD:render()
    ISPanel.render(self)
    -- Draw a small gold accent line at the top
    self:drawRect(0, 0, self:getWidth(), 2, 0.8, 1, 0.85, 0.3)
end

-- Static instance reference
SEWalletHUD.instance = nil

--- Show the wallet HUD (called on game start).
--- @param player IsoPlayer
function SEWalletHUD.show(player)
    if SEWalletHUD.instance then
        SEWalletHUD.instance:removeFromUIManager()
    end

    local hud = SEWalletHUD:new(player)
    hud:initialise()
    hud:addToUIManager()
    hud:setVisible(true)

    SEWalletHUD.instance = hud
end

--- Hide the wallet HUD.
function SEWalletHUD.hide()
    if SEWalletHUD.instance then
        SEWalletHUD.instance:setVisible(false)
        SEWalletHUD.instance:removeFromUIManager()
        SEWalletHUD.instance = nil
    end
end

-- Auto-show on game start
local function onGameStart()
    local player = getPlayer()
    if player then
        SEWalletHUD.show(player)
    end
end

Events.OnGameStart.Add(onGameStart)

return SEWalletHUD
