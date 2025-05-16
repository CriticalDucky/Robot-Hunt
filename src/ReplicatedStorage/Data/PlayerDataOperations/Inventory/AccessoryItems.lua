--#region Imports

-- Services

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

-- Source

local replicatedStorageData = ReplicatedStorage:WaitForChild "Data"

local ClientServerCommunication = require(replicatedStorageData:WaitForChild "ClientServerCommunication")
local Id = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Id")
local PlayerDataManager = if isServer then require(ServerStorage.Data.PlayerDataManager) else nil
local Types = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Types")

-- Types

type ItemAccessory = Types.ItemAccessory

--#endregion

local Accessories = {}

--[[
    Adds an accessory to the player's inventory.

    ---

    The ID of the added accessory is returned.

    This function is **server only**.

    This function does not check if the accessory inventory is full. It is up to the caller to check this when
    necessary.
]]
function Accessories.addAccessory(accessory: ItemAccessory, player: Player)
	if not isServer then
		warn "Adding accessories can only be done on the server."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so their accessories cannot be modified."
		return
	end

	local accessories = PlayerDataManager.viewPersistentData(player).inventory.accessories

	local newAccessoryId = Id.generate(accessories)

	PlayerDataManager.setValuePersistent(player, { "inventory", "accessories", newAccessoryId }, accessory)
	ClientServerCommunication.replicateAsync("SetAccessories", accessories, player)

	return newAccessoryId
end

--[[
    Removes an accessory from the player's inventory.

    ---

    This function is **server only**.
]]
function Accessories.removeAccessory(accessoryId: string, player: Player)
	if not isServer then
		warn "Removing accessories can only be done on the server."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so their accessories cannot be modified."
		return
	end

	local accessories = PlayerDataManager.viewPersistentData(player).inventory.accessories

	if not accessories[accessoryId] then
		warn "The player does not own an accessory with the given ID, so no accessory can be removed."
		return
	end

	PlayerDataManager.setValuePersistent(player, { "inventory", "accessories", accessoryId }, nil)
	ClientServerCommunication.replicateAsync("SetAccessories", accessories, player)
end

return Accessories
