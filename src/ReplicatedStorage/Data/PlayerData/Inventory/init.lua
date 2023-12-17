local Accessories = require(script.Accessories)
local Furniture = require(script.Furniture)
local Homes = require(script.Homes)

--[[
    A submodule of `PlayerData` that handles the player's inventory.
]]
local Inventory = {}

Inventory.accessories = Accessories

Inventory.furniture = Furniture

Inventory.homes = Homes

return Inventory