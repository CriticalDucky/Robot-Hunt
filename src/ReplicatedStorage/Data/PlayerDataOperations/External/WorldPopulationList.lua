--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageData = ReplicatedStorage:WaitForChild "Data"

local ClientServerCommunication = require(replicatedStorageData:WaitForChild "ClientServerCommunication")

--#endregion

local WorldPopulationList = {}

function WorldPopulationList.SubscribeToWorldPopulationList()
	ClientServerCommunication.replicateAsync "SubscribeToWorldPopulationList"
end

function WorldPopulationList.UnsubscribeFromWorldPopulationList()
    ClientServerCommunication.replicateAsync "UnsubscribeFromWorldPopulationList"
end

return WorldPopulationList
