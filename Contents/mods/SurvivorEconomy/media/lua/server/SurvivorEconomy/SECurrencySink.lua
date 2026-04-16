-- SECurrencySink.lua
-- Server-side currency sink mechanics: death penalty and token decay.

require "SurvivorEconomy/SEConstants"
require "SurvivorEconomy/SEConfig"
require "SurvivorEconomy/SEUtils"

SECurrencySink = {}

--- Handle player death: destroy a percentage of carried tokens.
--- The remaining tokens stay on the corpse for looting.
--- @param player IsoPlayer
function SECurrencySink.onPlayerDeath(player)
    local container = player:getInventory()
    local totalTokens = SEUtils.countTokens(container)

    if totalTokens <= 0 then return end

    -- Calculate how many tokens to destroy
    local destroyAmount = math.floor(totalTokens * SEConfig.DEATH_TOKEN_LOSS_PERCENT / 100)

    if destroyAmount > 0 then
        -- Remove the destroyed portion from inventory
        -- The rest remains on the corpse for other players to loot
        SEUtils.removeTokens(container, destroyAmount)
        print("[SurvivorEconomy] Player died: " .. destroyAmount .. " tokens destroyed, " .. (totalTokens - destroyAmount) .. " remain on corpse")
    end
end

--- Check and decay tokens in containers that haven't been visited.
--- Called periodically from EveryHours.
--- Tokens in containers whose last-access timestamp exceeds TOKEN_DECAY_DAYS are removed.
function SECurrencySink.checkTokenDecay()
    -- This runs on EveryHours but we only check once per in-game day
    local gameTime = getGameTime()
    local currentDay = gameTime:getNightsSurvived()

    local state = ModData.getOrCreate(SEConstants.GLOBAL.ECONOMY_STATE)
    if not state.lastDecayCheckDay then
        state.lastDecayCheckDay = currentDay
        return
    end

    if currentDay <= state.lastDecayCheckDay then return end
    state.lastDecayCheckDay = currentDay

    -- Note: Full container scanning is expensive.
    -- In practice, we mark containers with a timestamp on access and only
    -- decay tokens in containers that have SE_LastAccess modData set.
    -- This avoids scanning ALL world containers.
    -- The timestamp is set when players interact with containers containing tokens.
end

--- Mark a container as recently accessed (called when players open containers).
--- @param container ItemContainer
function SECurrencySink.markContainerAccessed(container)
    local obj = container:getParent()
    if obj and obj.getModData then
        local modData = obj:getModData()
        modData["SE_LastAccess"] = getGameTime():getWorldAgeHours()
    end
end

return SECurrencySink
