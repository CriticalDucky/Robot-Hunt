--#region Imports

-- Services

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

local isServer = RunService:IsServer()

-- Source

local replicatedStorageSharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Data"

local DataReplication = require(replicatedStorageSharedData:WaitForChild "DataReplication")

--#endregion

--[[
    A submodule of `PlayerData` that handles players' public data.
]]

local PublicPlayerData = {}

--[[
    Subscribes the given player to the persistent data of the (likely) offline player with the given ID.

    ---

    This function is **client only**. The server can subscribe a player directly in `PlayerDataManager`.

    For more info on subscriptions, see `PlayerDataManager`.
]]
function PublicPlayerData.subscribeToPersistentData(userId: number)
	if isServer then
		warn "This function can only be called on the client. No player will be subscribed to."
		return
	end

	DataReplication.replicateAsync("SubscribeToPersistentData", userId)
end

return PublicPlayerData
