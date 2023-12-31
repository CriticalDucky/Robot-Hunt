--!strict

local SUBSCRIPTION_RETRIEVAL_INTERVAL = 10

--#region Imports

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
local PlayerDataManager = require(ServerStorage.Data.PlayerDataManager)
local Types = require(ReplicatedFirst.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData
type PlayerPersistentDataPublic = Types.PlayerPersistentDataPublic

--#endregion

--#region Utility

local function filter(data: PlayerPersistentData): PlayerPersistentDataPublic
	local publicData = {}

	publicData.inventory = data.inventory

	return publicData
end

--#endregion

--#region Subscriptions

local subscriptions = {}

local function subscribe(player: Player, userId: number)
	if subscriptions[player] then return end

	local subscriptionInfo = {}
	subscriptions[player] = subscriptionInfo

	subscriptionInfo.userId = userId
	subscriptionInfo.thread = task.spawn(function()
		repeat
			local data = PlayerDataManager.viewOfflinePersistentDataAsync(userId)

			if not data then continue end
			assert(data)

			ClientServerCommunication.replicateAsync(
				"UpdatePublicPlayerData",
				filter(data),
				player
			)
		until not task.wait(SUBSCRIPTION_RETRIEVAL_INTERVAL)
	end)
end

local function unsubscribe(player: Player)
	if not subscriptions[player] then return end

	task.cancel(subscriptions[player].thread)
	subscriptions[player] = nil
end

Players.PlayerRemoving:Connect(unsubscribe)

--#endregion

local PublicPlayerDataSubscriptions = {}

function PublicPlayerDataSubscriptions.subscribe(player: Player, userId: number)
	if not player:IsDescendantOf(game) then return end

	local subscriptionInfo = subscriptions[player]

	if subscriptionInfo then
		if subscriptionInfo.userId == userId then
			return
		else
			unsubscribe(player)
		end
	end

	subscribe(player, userId)
end

function PublicPlayerDataSubscriptions.unsubscribe(player: Player)
	if not player:IsDescendantOf(game) then return end

	unsubscribe(player)
end

return PublicPlayerDataSubscriptions