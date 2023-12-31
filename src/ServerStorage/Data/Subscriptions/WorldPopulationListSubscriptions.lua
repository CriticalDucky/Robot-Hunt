--!strict

local SUBSCRIPTION_RETRIEVAL_INTERVAL = 10

--#region Imports

local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Shared.Data.ClientServerCommunication)
local WorldPopulationList = require(ServerStorage.Shared.Universe.WorldPopulationList)

--#endregion

--#region Subscriptions

local subscriptions = {}

local function subscribe(player: Player)
	if subscriptions[player] then return end

	subscriptions[player] = task.spawn(function()
		repeat
			ClientServerCommunication.replicateAsync("UpdateWorldPopulationList", WorldPopulationList.get(), player)
		until not task.wait(SUBSCRIPTION_RETRIEVAL_INTERVAL)
	end)
end

local function unsubscribe(player: Player)
	if not subscriptions[player] then return end

	task.cancel(subscriptions[player])
	subscriptions[player] = nil
end

Players.PlayerRemoving:Connect(unsubscribe)

--#endregion

local WorldPopulationListSubscriptions = {}

function WorldPopulationListSubscriptions.subscribe(player: Player)
	if not player:IsDescendantOf(game) then return end

	subscribe(player)
end

function WorldPopulationListSubscriptions.unsubscribe(player: Player)
	if not player:IsDescendantOf(game) then return end

	unsubscribe(player)
end

return WorldPopulationListSubscriptions
