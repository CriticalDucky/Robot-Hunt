--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedStorageData = ReplicatedStorage:WaitForChild "Data"

local ClientState = require(replicatedStorageData:WaitForChild "ClientState")
local ClientServerCommunication = require(replicatedStorageData:WaitForChild "ClientServerCommunication")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local peek = Fusion.peek

--#endregion

ClientServerCommunication.registerActionAsync(
	"InitializeRoundData",
	function(roundData) ClientState.external.roundData:set(roundData) end
)

ClientServerCommunication.registerActionAsync("UpdateRoundType", function(roundType)
	local roundData = peek(ClientState.external.roundData)

	if roundData then roundData.roundType = roundType end

	ClientState.external.roundData:set(roundData)
end)

ClientServerCommunication.registerActionAsync("UpdatePhaseType", function(phaseType)
	local roundData = peek(ClientState.external.roundData)

	if roundData then roundData.phaseType = phaseType end

	ClientState.external.roundData:set(roundData)
end)

ClientServerCommunication.registerActionAsync("UpdatePhaseEndTime", function(phaseEndTime)
	local roundData = peek(ClientState.external.roundData)

	if roundData then roundData.phaseEndTime = phaseEndTime end

	ClientState.external.roundData:set(roundData)
end)

ClientServerCommunication.registerActionAsync("UpdatePlayerData", function(data)
	local roundData = peek(ClientState.external.roundData)

	local playerId = data.targetPlayerId
	local playerData = data.playerData

	if not roundData then return end

	if playerId then
		for i, currentPlayerData in ipairs(roundData.playerData) do
			if not (currentPlayerData.playerId == playerId) then continue end

			if data.data then
				roundData.playerData[i] = data.data
			else
				table.remove(roundData.playerData, i)
			end
		end
	elseif playerData then
		roundData.playerData = playerData
	end

	ClientState.external.roundData:set(roundData)
end)

ClientServerCommunication.replicateAsync "InitializeRoundData"
