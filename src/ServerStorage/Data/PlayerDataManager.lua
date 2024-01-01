--!strict

local PROFILE_ARCHIVE_CACHE_LIFETIME = 60
local PROFILE_ARCHIVE_GARBAGE_COLLECTION_INTERVAL = 60

--#region Imports

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageVendor = ServerStorage.Vendor

local ProfileService = require(serverStorageVendor.ProfileService)

local PlayerDataTemplates = require(ServerStorage.Configuration.PlayerDataTemplates)
local ServerDirectives = require(ServerStorage.Utility.ServerDirectives)
local Table = require(ReplicatedFirst.Utility.Table)
local Types = require(ReplicatedFirst.Utility.Types)

type DataTreeDictionary = Types.DataTreeDictionary
type DataTreeValue = Types.DataTreeValue
type PlayerPersistentData = Types.PlayerPersistentData
type PlayerPersistentDataPublic = Types.PlayerPersistentDataPublic
type PlayerTempData = Types.PlayerTempData
type Profile = Types.Profile

--#endregion

--#region Profile Setup

local ProfileStore = ProfileService.GetProfileStore("PlayerData", PlayerDataTemplates.persistentDataTemplate)

--#endregion

--#region Profile Archive

local profileArchive = {}

--[[
	Loads a profile into the archive.

	---

	For each player, the archive contains both the profile and the time the profile was updated. Loading a profile into
	the archive updates the time.
]]
local function loadProfileIntoArchive(playerId: number, profile: Profile?)
	local profileInfo = {}

	profileInfo.lastUpdated = time()
	profileInfo.profile = profile

	profileArchive[playerId] = profileInfo
end

-- Garbage Collection

task.spawn(function()
	while task.wait(PROFILE_ARCHIVE_GARBAGE_COLLECTION_INTERVAL) do
		for playerId, profileInfo in pairs(profileArchive) do
			if time() - profileInfo.lastUpdated > PROFILE_ARCHIVE_CACHE_LIFETIME then profileArchive[playerId] = nil end
		end
	end
end)

--#endregion

--#region Active Profiles

local profileLoadedEvent = Instance.new "BindableEvent"

local profileUnloadingEvent = Instance.new "BindableEvent"

local profiles: { [Player]: Profile } = {}

--[[
	Loads the player's data and replicates it to the client.
]]
local function loadPlayerProfileAsync(player: Player)
	local profile: Profile = ProfileStore:LoadProfileAsync(`Player{player.UserId}`, "ForceLoad")

	if not profile then
		warn(`Failed to load profile for {player.Name} (User ID {player.UserId})`)

		ServerDirectives.kickPlayer(player, "Failed to load your data.")

		return
	end

	-- Set up profile

	profiles[player] = profile

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	-- Manage release of profile

	profile:ListenToRelease(function()
		-- Fire profile unloading event

		profileUnloadingEvent:Fire(player, profile.Data)

		-- Unload profile

		ServerDirectives.kickPlayer(player, "Your data has been unloaded.")

		loadProfileIntoArchive(player.UserId, profile)

		profiles[player] = nil
	end)

	-- Fire profile loaded event

	profileLoadedEvent:Fire(player, profile.Data)

	-- Release profile if the player has left

	if not player:IsDescendantOf(game) then
		profile:Release()

		return
	end
end

local function unloadPlayerProfile(player: Player)
	local profile = profiles[player]

	if profile then profile:Release() end
end

-- Initialization

for _, player in Players:GetPlayers() do
	task.spawn(loadPlayerProfileAsync, player)
end

Players.PlayerAdded:Connect(loadPlayerProfileAsync)

Players.PlayerRemoving:Connect(unloadPlayerProfile)

--#endregion

--#region Offline Profiles

local loadingOfflineProfiles = {}

local function viewOfflineProfileAsync(playerId: number): Profile?
	-- If the player is online, return their profile

	local player = Players:GetPlayerByUserId(playerId)

	if player and profiles[player] then return profiles[player] end

	-- Simply return the profile if it is young enough

	local profileInfo = profileArchive[playerId]

	if profileInfo and time() - profileInfo.lastUpdated < PROFILE_ARCHIVE_CACHE_LIFETIME then
		return profileInfo.profile
	end

	-- If the profile is already being retrieved, wait for it to finish

	if loadingOfflineProfiles[playerId] then
		repeat
			task.wait()
		until not loadingOfflineProfiles[playerId]

		return profileArchive[playerId].profile
	end

	-- Retrieve the profile

	loadingOfflineProfiles[playerId] = true
	local profile = ProfileStore:ViewProfileAsync(`Player{playerId}`) :: Profile?
	loadingOfflineProfiles[playerId] = nil

	player = Players:GetPlayerByUserId(playerId)

	if player and profiles[player] then return profiles[player] end

	loadProfileIntoArchive(playerId, profile)

	return profile
end

--#endregion

--#region Temporary Data

local tempDatas: { [Player]: PlayerTempData } = {}

local tempDataLoadedEvent = Instance.new "BindableEvent"

local tempDataUnloadingEvent = Instance.new "BindableEvent"

local function loadPlayerTempData(player: Player)
	local initialTempData = Table.deepCopy(PlayerDataTemplates.tempDataTemplate)

	tempDatas[player] = initialTempData

	-- Fire temp data loaded event

	tempDataLoadedEvent:Fire(player, initialTempData)
end

local function unloadPlayerTempData(player: Player)
	-- Fire temp data unloading event

	tempDataUnloadingEvent:Fire(player, tempDatas[player])

	-- Unload temp data

	tempDatas[player] = nil
end

-- Initialization

for _, player in Players:GetPlayers() do
	loadPlayerTempData(player)
end

Players.PlayerAdded:Connect(loadPlayerTempData)

Players.PlayerRemoving:Connect(unloadPlayerTempData)

--#endregion

--[[
	Manages players' persistent and temporary player data.

	---

	For proper client replication when modifying player data, use the `PlayerData` module.
]]
local PlayerDataManager = {}

--[[
	Returns the player's persistent data, or `nil` if it is not loaded. The returned table may be modified.
]]
function PlayerDataManager.getPersistentData(player: Player): PlayerPersistentData?
	local profile = profiles[player]

	return if profile then profile.Data else nil
end

--[[
	Returns an array of all players whose persistent data are loaded.
]]
function PlayerDataManager.getPlayersWithLoadedPersistentData()
	local players = {}

	for player in profiles do
		table.insert(players, player)
	end

	return players
end

--[[
	Returns an array of all players whose temporary data is loaded.
]]
function PlayerDataManager.getPlayersWithLoadedTempData()
	local players = {}

	for player in tempDatas do
		table.insert(players, player)
	end

	return players
end

function PlayerDataManager.getPlayersWithDataLoaded()
	local playersWithTempData = PlayerDataManager.getPlayersWithLoadedTempData()
	local playersWithPersistentData = PlayerDataManager.getPlayersWithLoadedPersistentData()

	return Table.arrayIntersection(playersWithTempData, playersWithPersistentData)
end

--[[
	Returns the player's temporary data, or `nil` if it is not loaded. The returned table may be modified.
]]
function PlayerDataManager.getTempData(player: Player): PlayerTempData? return tempDatas[player] end

--[[
	Returns if the player's persistent data is loaded.
]]
function PlayerDataManager.persistentDataIsLoaded(player: Player): boolean
	--
	return profiles[player] ~= nil
end

--[[
	Returns if the player's temporary data is loaded.
]]
function PlayerDataManager.tempDataIsLoaded(player: Player): boolean
	--
	return tempDatas[player] ~= nil
end

--[[
	Returns if the player's data is loaded, checking both persistent and temporary data.
]]
function PlayerDataManager.dataIsLoaded(player: Player): boolean
	return PlayerDataManager.persistentDataIsLoaded(player) and PlayerDataManager.tempDataIsLoaded(player)
end

--[[
	Returns a copy of the offline player's persistent data for viewing only. Returns `nil` if no such data exists or the
	retrieval failed.
]]
function PlayerDataManager.viewOfflinePersistentDataAsync(playerId: number): PlayerPersistentData?
	local profile = viewOfflineProfileAsync(playerId)

	return if profile then profile.Data else nil
end

--[[
	An event that fires when the player's persistent data is loaded.
]]
PlayerDataManager.persistentDataLoaded = profileLoadedEvent.Event :: RBXScriptSignal<Player, PlayerPersistentData>

--[[
	An event that fires when the player's persistent data is unloading.
]]
PlayerDataManager.persistentDataUnloading = profileUnloadingEvent.Event :: RBXScriptSignal<Player, PlayerPersistentData>

--[[
	An event that fires when the player's temporary data is loaded.
]]
PlayerDataManager.tempDataLoaded = tempDataLoadedEvent.Event :: RBXScriptSignal<Player, PlayerTempData>

--[[
	An event that fires when the player's temporary data is unloaded.
]]
PlayerDataManager.tempDataUnloaded = tempDataUnloadingEvent.Event :: RBXScriptSignal<Player, PlayerTempData>

return PlayerDataManager
