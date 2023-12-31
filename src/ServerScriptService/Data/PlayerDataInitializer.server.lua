--!strict

--#region Imports

local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local Enums = require(ReplicatedFirst.Shared.Enums)
local ItemTypeHome = Enums.ItemTypeHome
local PlayerDataOperations = require(ReplicatedStorage.Shared.Data.PlayerDataOperations)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)
local DataStoreUtility = require(ServerStorage.Shared.Utility.DataStoreUtility)
local TeleportUtility = require(ServerStorage.Shared.Utility.TeleportUtility)
local PlaceIDs = require(ServerStorage.Shared.Configuration.PlaceIDs)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type ItemHome = Types.ItemHome
type ServerDataHome = Types.ServerInfoHome

local serverDictionary = DataStoreService:GetDataStore "ServerDictionary"

--#endregion

--#region Initializers

local function initializeDefaultHomes(player: Player)
	local data = PlayerDataManager.getPersistentData(player)
	assert(data)

	local homes = data.inventory.homes

	local hasHomes = false

	for _, _ in pairs(homes) do
		hasHomes = true
		break
	end

	if hasHomes then return end

	local newDefaultHome: ItemHome = {
		type = ItemTypeHome.defaultHome,
	}

	local newDeveloperHome: ItemHome = {
		type = ItemTypeHome.developerHome,
	}

	PlayerDataOperations.Inventory.HomeItems.addHome(newDefaultHome, player)
	PlayerDataOperations.Inventory.HomeItems.addHome(newDeveloperHome, player) -- TODO: Remove.
end

local function initializeSelectedHome(player: Player)
	local data = PlayerDataManager.getPersistentData(player)
	assert(data)

	if data.home.selected then return end

	for homeId in pairs(data.inventory.homes) do
		PlayerDataOperations.Homes.setSelectedHome(homeId, player)
		break
	end
end

local function initializeHomeServer(player: Player)
	local data = PlayerDataManager.getPersistentData(player)
	assert(data)

	if data.home.server then return end

	local reserveSuccess, newAccessCode, newServerId = TeleportUtility.safeReserveServerAsync(PlaceIDs.home)

	if not reserveSuccess then
		warn(`Failed to reserve a home server for {player}!`)
		return
	end

	local serverData: ServerDataHome = {
		homeOwner = player.UserId,
	}

	local registerSuccess = DataStoreUtility.safeSetAsync(serverDictionary, newServerId, serverData, { player.UserId })

	if not registerSuccess then
		warn(`Failed to register a home server for {player}!`)
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn(`{player}'s persistent data is no longer loaded, so the home server cannot be registered.`)
		return
	end

	data.home.server = {
		accessCode = newAccessCode,
		privateServerId = newServerId,
	}
end

--#endregion

local function initializePersistentData(player: Player)
	local data = PlayerDataManager.getPersistentData(player)
	assert(data)

	-- Initialize default home if none exists.

	initializeDefaultHomes(player)

	-- Set selected home if none is selected.

	initializeSelectedHome(player)

	-- Reserve a home server if none is reserved.

	initializeHomeServer(player)
end

for _, player in pairs(PlayerDataManager.getPlayersWithLoadedPersistentData()) do
	initializePersistentData(player)
end

PlayerDataManager.persistentDataLoaded:Connect(initializePersistentData)
