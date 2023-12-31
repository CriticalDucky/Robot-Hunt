--[[
    Manages the player's state.
]]
local PlayerDataOperations = {}

PlayerDataOperations.Currency = require(script:WaitForChild "Currency")

PlayerDataOperations.External = require(script:WaitForChild "External")

PlayerDataOperations.Inventory = require(script:WaitForChild "Inventory")

PlayerDataOperations.Settings = require(script:WaitForChild "Settings")

return PlayerDataOperations
