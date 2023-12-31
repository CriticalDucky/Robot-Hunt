--!strict

type PlayerDataConfiguration = {
	inventoryLimits: {
		accessories: number,
		furniture: number,
		homes: number,
	},
}

--[[
	Configuration for player data.
]]
local PlayerDataConfiguration: PlayerDataConfiguration = {
	inventoryLimits = {
		accessories = 500,
		furniture = 500,
		homes = 200,
	},
}

return PlayerDataConfiguration
