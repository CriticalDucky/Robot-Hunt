local ReplicatedFirst = game:GetService "ReplicatedFirst"

local Types = require(ReplicatedFirst.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData

type PlayerDataConfig = {
	persistentDataTemplate: PlayerPersistentData,
	tempDataTemplate: {},
}

--[[
	Configuration for player data.
]]
local PlayerDataConfig: PlayerDataConfig = {
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

return PlayerDataConfig
