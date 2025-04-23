--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local dataFolder = ReplicatedStorage:WaitForChild "Data"

local ClientState = require(dataFolder:WaitForChild "ClientState")
local ClientServerCommunication = require(dataFolder:WaitForChild "ClientServerCommunication")

--#endregion

ClientServerCommunication.registerActionAsync(
	"SetAccessories",
	function(accessories) ClientState.inventory.accessories:set(accessories) end
)
