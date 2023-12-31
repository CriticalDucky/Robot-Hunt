--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local replicatedStorageSharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Data"

local Id = if isServer then require(ReplicatedFirst.Shared.Utility.Id) else nil
local PlayerDataManager = if isServer then require(ServerStorage.Shared.Data.PlayerDataManager) else nil
local ClientServerCommunication = require(replicatedStorageSharedData:WaitForChild "ClientServerCommunication")

local Types = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild "Types")

type ItemHome = Types.ItemHome

--#endregion

--[[
	A submodule of `PlayerData` that handles the player's homes inventory.
]]
local Homes = {}

--[[
	Adds a home to the player's inventory.

	---

	The ID of the added home is returned.

	This function is **server only**.

	This function does not check if the home inventory is full. It is up to the caller to check this when necessary.
]]
function Homes.addHome(home: ItemHome, player: Player)
	if not isServer then
		warn "Adding homes can only be done on the server."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so no home can be added."
		return
	end

	local homes = PlayerDataManager.viewPersistentData(player).inventory.homes

	local newHomeId = Id.generate(homes)

	PlayerDataManager.setValuePersistent(player, { "inventory", "homes", newHomeId }, home)
	ClientServerCommunication.replicateAsync("SetHomes", homes, player)

	return newHomeId
end

--[[
	Removes a home from the player's inventory.

	---

	This function is **server only**.
]]
function Homes.removeHome(homeId: string, player: Player)
	if not isServer then
		warn "Removing homes can only be done on the server."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so no home can be removed."
		return
	end

	local homes = PlayerDataManager.viewPersistentData(player).inventory.homes

	if not homes[homeId] then
		warn "The player does not own a home with the given ID, so no home can be removed."
		return
	end

	PlayerDataManager.setValuePersistent(player, { "inventory", "homes", homeId }, nil)
	ClientServerCommunication.replicateAsync("SetHomes", homes, player)
end

return Homes
