--[[
    This script collects souls from the dead and gives them to the living.
]]

local ServerStorage = game:GetService "ServerStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local Players = game:GetService "Players"

local GameLoop = ServerStorage.GameLoop

local RoundDataManager = require(GameLoop.RoundDataManager)
local Enums = require(ReplicatedFirst.Enums)

RoundDataManager.onPlayerStatusUpdated:Connect(function(playerData)
	if playerData.status == Enums.PlayerStatus.dead then
		local player = Players:GetPlayerByUserId(playerData.playerId)
		local character = player.Character

		if character then
			character.HumanoidRootPart.Anchored = true -- temporary; will change later :D
		end
	end
end)

local function onPlayerManuallyQuits(player: Player)
	local playerData = RoundDataManager.data.playerData[player.UserId]

	if playerData and playerData.status ~= Enums.PlayerStatus.dead and RoundDataManager.data.isGameOver == false then
		RoundDataManager.killPlayer(player)
	end
end

Players.PlayerRemoving:Connect(function(player) onPlayerManuallyQuits(player) end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function(character)
		if RoundDataManager.data.currentPhaseType ~= Enums.PhaseType.Loading and not RoundDataManager.data.isGameOver then
			onPlayerManuallyQuits(player)
		end
	end)
end)