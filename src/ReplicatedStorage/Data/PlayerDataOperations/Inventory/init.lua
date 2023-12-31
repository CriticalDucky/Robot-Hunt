--[[
    A submodule of `PlayerData` that handles the player's inventory.
]]
local Inventory = {}

Inventory.AccessoryItems = require(script:WaitForChild "AccessoryItems")

Inventory.FurnitureItems = require(script:WaitForChild "FurnitureItems")

Inventory.HomeItems = require(script:WaitForChild "HomeItems")

return Inventory
