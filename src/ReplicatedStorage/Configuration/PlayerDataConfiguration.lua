--!strict

type PlayerDataConfiguration = {
	inventoryLimits: {
		accessories: number,
	},
}

--[[
	Configuration for player data.
]]
local PlayerDataConfiguration: PlayerDataConfiguration = {
	inventoryLimits = {
		accessories = 500,
	},
}

return PlayerDataConfiguration
