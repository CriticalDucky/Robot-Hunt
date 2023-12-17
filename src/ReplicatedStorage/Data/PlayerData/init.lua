--#region Imports

local Currency = require(script.Currency)
local Inventory = require(script.Inventory)
local PublicPlayerData = require(script.PublicPlayerData)
local Settings = require(script.Settings)

--#endregion

--[[
    Manages the player's state.
]]
local PlayerState = {}

PlayerState.currency = Currency

PlayerState.inventory = Inventory

PlayerState.publicPlayerData = PublicPlayerData

PlayerState.settings = Settings

return PlayerState
