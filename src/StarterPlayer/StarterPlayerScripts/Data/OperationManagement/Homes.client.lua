--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ReplicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"

local ClientState = require(ReplicatedStorageShared:WaitForChild("Data"):WaitForChild "ClientState")
local ClientServerCommunication =
	require(ReplicatedStorageShared:WaitForChild("Data"):WaitForChild "ClientServerCommunication")

--#endregion

ClientServerCommunication.registerActionAsync(
	"SetSelectedHome",
	function(homeId: string) ClientState.home.selected:set(homeId) end
)
