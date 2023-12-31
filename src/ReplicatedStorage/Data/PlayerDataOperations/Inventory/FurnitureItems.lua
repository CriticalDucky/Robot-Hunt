--#region Imports

-- Services

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

-- Source

local replicatedStorageSharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Data"

local ClientServerCommunication = require(replicatedStorageSharedData:WaitForChild "ClientServerCommunication")
local Id = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild("Id"))
local PlayerDataManager = if isServer then require(ServerStorage.Shared.Data.PlayerDataManager) else nil
local Types = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild "Types")

-- Types

type ItemFurniture = Types.ItemFurniture

--#endregion

local Furniture = {}

--[[
    Adds a piece of furniture to the player's inventory.

    ---

    The ID of the added furniture is returned.

    This function is **server only**.

    This function does not check if the furniture inventory is full. It is up to the caller to check this when
    necessary.
]]
function Furniture.addFurniture(furniture: ItemFurniture, player: Player)
    if not isServer then
        warn "Adding furniture can only be done on the server."
        return
    end

    if not PlayerDataManager.persistentDataIsLoaded(player) then
        warn "The player's persistent data is not loaded, so their furniture cannot be modified."
        return
    end

    local allFurniture = PlayerDataManager.viewPersistentData(player).inventory.furniture

    local newFurnitureId = Id.generate(allFurniture)

    PlayerDataManager.setValuePersistent(player, { "inventory", "furniture", newFurnitureId }, allFurniture)
    ClientServerCommunication.replicateAsync("SetFurniture", allFurniture, player)

    return newFurnitureId
end

--[[
    Removes a piece of furniture from the player's inventory.

    ---

    This function is **server only**.
]]
function Furniture.removeFurniture(furnitureId: string, player: Player)
    if not isServer then
        warn "Removing accessories can only be done on the server."
        return
    end

    if not PlayerDataManager.persistentDataIsLoaded(player) then
        warn "The player's persistent data is not loaded, so their furniture cannot be modified."
        return
    end

    local allFurniture = PlayerDataManager.viewPersistentData(player).inventory.furniture

    if not allFurniture[furnitureId] then
        warn "The player does not own an accessory with the given ID, so no accessory can be removed."
        return
    end

    PlayerDataManager.setValuePersistent(player, { "inventory", "furniture", furnitureId }, nil)
    ClientServerCommunication.replicateAsync("SetFurniture", allFurniture, player)
end

return Furniture