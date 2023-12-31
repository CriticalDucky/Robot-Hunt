--#region Imports

-- Services

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

-- Source

local replicatedStorageData = ReplicatedStorage:WaitForChild "Data"

local PlayerDataManager = if isServer then require(ServerStorage.Data.PlayerDataManager) else nil
local ClientServerCommunication = require(replicatedStorageData:WaitForChild "ClientServerCommunication")

--#endregion

--[[
	A submodule of `PlayerData` that handles the player's currency.
]]
local Currency = {}

--[[
	Increments the amount of money the player has. The amount provided will be rounded up to the nearest integer.

	---

	This function is **server only**.
]]
function Currency.incrementMoney(player: Player, amount: number)
	if not isServer then
		warn "This function can only be called on the server. No state will be modified."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so their money cannot be modified."
		return
	end

	amount = math.ceil(amount) + PlayerDataManager.viewPersistentData(player).currency.money

	PlayerDataManager.setValuePersistent(player, { "currency", "money" }, amount)
	ClientServerCommunication.replicateAsync("SetMoney", amount, player)
end

--[[
	Sets the amount of money the player has. The amount provided will be rounded up to the nearest integer.

	---

	This function is **server only**.
]]
function Currency.setMoney(player: Player, amount: number)
	if not isServer then
		warn "This function can only be called on the server. No data will be modified."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so their money cannot be modified."
		return
	end

	amount = math.ceil(amount)

	PlayerDataManager.setValuePersistent(player, { "currency", "money" }, amount)
	ClientServerCommunication.replicateAsync("SetMoney", amount, player)
end

return Currency
