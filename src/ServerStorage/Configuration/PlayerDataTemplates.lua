--!strict

local ReplicatedFirst = game:GetService "ReplicatedFirst"

local Types = require(ReplicatedFirst.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData
type PlayerTempData = Types.PlayerTempData

type PlayerDataTemplates = {
	persistentDataTemplate: PlayerPersistentData,
	tempDataTemplate: PlayerTempData,
}

--[[
	Configuration for player data.
]]
local PlayerDataTemplates: PlayerDataTemplates = {
	persistentDataTemplate = {
		currency = {
			money = 0,
		},

		inventory = {
			accessories = {},
		},

		settings = {
			musicVolume = 1,
			sfxVolume = 1,
		},
	},
	tempDataTemplate = {},
}

return PlayerDataTemplates
