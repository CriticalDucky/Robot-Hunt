--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Shared.Data.ClientServerCommunication)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)

--#endregion

ClientServerCommunication.registerActionAsync("SetSelectedHome", function(player, homeId)
	if typeof(homeId) ~= "string" then return end

	local data = PlayerDataManager.getPersistentData(player)
	assert(data)

	if not data.inventory.homes[homeId] then
		ClientServerCommunication.replicateAsync("SetSelectedHome", data.home.selected, player)
		return
	end

	data.home.selected = homeId
end)
