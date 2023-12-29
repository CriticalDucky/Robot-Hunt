
local OFFLINE_PROFILE_RETRIEVAL_INTERVAL = 5

--#region Imports

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageVendor = ServerStorage.Vendor

local ProfileService = require(serverStorageVendor.ProfileService)

local PlayerDataConfig = require(ReplicatedFirst.Configuration.PlayerDataConfig)
local Table = require(ReplicatedFirst.Utility.Table)
local Types = require(ReplicatedFirst.Utility.Types)

type DataTreeDictionary = Types.DataTreeDictionary
type DataTreeValue = Types.DataTreeValue
type PlayerPersistentData = Types.PlayerPersistentData
type PlayerPersistentDataPublic = Types.PlayerPersistentDataPublic
type Profile = Types.Profile

--#endregion

--#region Profile Setup

local ProfileStore = ProfileService.GetProfileStore("PlayerData", PlayerDataConfig.persistentDataTemplate)

local publicPlayerDataReplica = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "PublicPlayerData",
	Replication = "All",
}

local function filterProfileForPublic(data: PlayerPersistentData): PlayerPersistentDataPublic
	local filteredData = {}

	filteredData.inventory = Table.deepCopy(data.inventory)

	filteredData.settings = {}

	return filteredData
end

--#endregion

--#region Profile Archive

local profileArchive = {}

--[[
	Loads a profile into the archive.

	---

	For each player, the archive contains both the profile and the time the profile was updated. Loading a profile into
	the archive updates the time.

	The profile can be ommitted, in which case the update time is updated, but the profile in the archive does not
	change.
]]
local function loadProfileIntoArchive(playerId: number, profile: Profile?)
	local profileInfo = profileArchive[playerId] or {}
	profileArchive[playerId] = profileInfo

	profileInfo.lastUpdated = time()

	if profile then profileInfo.profile = profile end
end

--#endregion

--#region Persistent Data Update Events

--[[
	Mapping from user IDs to the update signal for that user's data. The signal is fired whenever the profile is
	retrieved or updated; essentially whenever the public data replica is updated.
]]
local persistentDataUpdatedSignals: { BindableEvent? } = {}

--#endregion

--#region Active Profiles

local profileLoadedEvent = Instance.new "BindableEvent"

local profileUnloadedEvent = Instance.new "BindableEvent"

local privatePlayerDataReplicas = {}

local profiles: { [Player]: Profile? } = {}

--[[
	Loads the player's data and replicates it to the client.
]]
local function loadPlayerProfileAsync(player: Player)
	local profile: Profile = ProfileStore:LoadProfileAsync(`Player_{player.UserId}`, "ForceLoad")

	if not profile then
		warn(`Failed to load profile for {player.Name} (User ID {player.UserId})`)

		-- TODO: Reroute player. Ideally this should reroute to the previous place they were if it's open, and simply
		-- reroute them otherwise.

		player:Kick "Failed to load your data."

		return
	end

	-- Set up profile

	profiles[player] = profile

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	-- Manage release of profile
	profile:ListenToRelease(function()
		-- TODO: Reroute player. Ideally this should reroute to the previous place they were if it's open, and simply
		-- reroute them otherwise.

		player:Kick "You have joined another server."

		loadProfileIntoArchive(player.UserId, profile)

		if privatePlayerDataReplicas[player] then
			privatePlayerDataReplicas[player]:Destroy()
			privatePlayerDataReplicas[player] = nil
		end

		profiles[player] = nil

		-- Fire profile unloaded event

		profileUnloadedEvent:Fire(player)
	end)

	if not player:IsDescendantOf(game) then
		profile:Release()

		return
	end

	-- Set up private data replica for player

	local privatePlayerData = ReplicaService.NewReplica {
		ClassToken = ReplicaService.NewClassToken(`PrivatePlayerData{player.UserId}__${math.floor(time() * 10)}`),
		Data = profile.Data,
		Replication = "All",
	}
	privatePlayerDataReplicas[player] = privatePlayerData

	-- Set up public data replica for player

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	-- Fire update signal for player, if it exists

	local updateSignal = persistentDataUpdatedSignals[player.UserId]

	if updateSignal then updateSignal:Fire(profile.Data) end

	-- Fire profile loaded event

	profileLoadedEvent:Fire(player, profile)
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

	if profileInfo and time() - profileInfo.lastUpdated < OFFLINE_PROFILE_RETRIEVAL_INTERVAL then
		return profileInfo.profile
	end

	-- Otherwise, retrieve the profile or wait for another retrieval to finish

	if loadingOfflineProfiles[playerId] then
		repeat
			task.wait()
		until not loadingOfflineProfiles[playerId]

		return profileArchive[playerId].profile
	end

	loadingOfflineProfiles[playerId] = true
	local profile = ProfileStore:ViewProfileAsync(`Player_{playerId}`) :: Profile
	loadingOfflineProfiles[playerId] = nil

	loadProfileIntoArchive(playerId, profile)

	player = Players:GetPlayerByUserId(playerId)

	if not profile and not profileArchive[playerId].profile then
		publicPlayerDataReplica:SetValue({ playerId }, false)
	elseif profile and not profiles[player] then
		publicPlayerDataReplica:SetValue({ playerId }, filterProfileForPublic(profile.Data))

		local updateSignal = persistentDataUpdatedSignals[playerId]

		if updateSignal then updateSignal:Fire(profile.Data) end
	end

	return profile
end

--#endregion

--#region Profile Subscriptions

-- Map of user IDs (of players who are subscribed to) to the subscription info.
local subscriptionInfos: { { numberOfSubscribers: number, thread: thread }? } = {}

local function decrementSubscription(userId: number)
	local subscriptionInfo = subscriptionInfos[userId]

	if not subscriptionInfo then return end

	subscriptionInfo.numberOfSubscribers -= 1

	if subscriptionInfo.numberOfSubscribers ~= 0 then return end

	task.cancel(subscriptionInfo.thread)
	subscriptionInfos[userId] = nil
end

local function incrementSubscription(userId: number)
	local subscriptionInfo = subscriptionInfos[userId]

	if subscriptionInfo then
		subscriptionInfo.numberOfSubscribers += 1
		return
	end

	subscriptionInfo = {
		numberOfSubscribers = 1,
		thread = task.spawn(function()
			while true do
				-- Wait for the next interval. The player must be offline and the profile old enough.

				while true do
					local profileInfo = profileArchive[userId]
					local playerSubscribedTo = Players:GetPlayerByUserId(userId)

					if profileInfo and time() - profileInfo.lastUpdated < OFFLINE_PROFILE_RETRIEVAL_INTERVAL then
						task.wait(OFFLINE_PROFILE_RETRIEVAL_INTERVAL - (time() - profileInfo.lastUpdated))
					elseif playerSubscribedTo and profiles[playerSubscribedTo] then
						task.wait()
					else
						break
					end
				end

				-- Update the profile.

				viewOfflineProfileAsync(userId)
			end
		end),
	}
	subscriptionInfos[userId] = subscriptionInfo
end

--#region Players

-- Map of players to the user ID of the player whose profile they are subscribed to.
local subscriptions: { [Player]: number? } = {}

local function unsubscribePlayer(player: Player)
	local subscription = subscriptions[player]

	if not subscription then return end

	subscriptions[player] = nil

	decrementSubscription(subscription)
end

Players.PlayerRemoving:Connect(unsubscribePlayer)

--#endregion

--#region Server

local serverSubscriptions: { true? } = {}

--#endregion

--#endregion

--#region Temporary Data

local publicPlayerTempDataReplica = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "PublicPlayerTempData",
	Replication = "All",
}

local privatePlayerTempDataReplicas = {}

local tempDataLoadedEvent = Instance.new "BindableEvent"

local tempDataUnloadedEvent = Instance.new "BindableEvent"

-- Takes a temporary data and returns a copy filtered for public availability.
local function filterTempDataForPublic(data: {})
	-- For now, no temporary data is public

	return {}
end

local function loadPlayerTempData(player: Player)
	local initialTempData = Table.deepCopy(PlayerDataConfig.tempDataTemplate)

	local privatePlayerTempData = ReplicaService.NewReplica {
		ClassToken = ReplicaService.NewClassToken(`PrivatePlayerTempData{player.UserId}__${math.floor(time() * 10)}`),
		Data = initialTempData,
		Replication = "All",
	}
	privatePlayerTempDataReplicas[player] = privatePlayerTempData

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(initialTempData))

	-- Fire temp data loaded event

	tempDataLoadedEvent:Fire(player)
end

local function unloadPlayerTempData(player: Player)
	privatePlayerTempDataReplicas[player]:Destroy()
	privatePlayerTempDataReplicas[player] = nil

	publicPlayerTempDataReplica:SetValue({ player }, nil)

	-- Fire temp data unloaded event

	tempDataUnloadedEvent:Fire(player)
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
	Performs `ArrayInsert()` on the player's persistent data replica and updates the public data replica accordingly.

	---

	The player's persistent data must be loaded.
]]
function PlayerDataManager.arrayInsertPersistent(player: Player, path: { string }, value: DataTreeValue)
	local profile = profiles[player]

	if not profile then
		warn "This player's profile is not loaded, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player]:ArrayInsert(path, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	local updateSignal = persistentDataUpdatedSignals[player.UserId]

	if updateSignal then updateSignal:Fire(profile.Data) end
end

--[[
	Performs `ArrayInsert()` on the player's temporary data replica and updates the public data replica accordingly.

	---

	The player's temporary data must be loaded.
]]
function PlayerDataManager.arrayInsertTemp(player: Player, path: { string }, value: DataTreeValue)
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	if not privateTempDataReplica then
		warn "This player's temporary data is not loaded, so no operation will be performed."
		return
	end

	privateTempDataReplica:ArrayInsert(path, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Performs `ArrayRemove()` on the player's persistent data replica and updates the public data replica accordingly.

	---

	The player's persistent data must be loaded.
]]
function PlayerDataManager.arrayRemovePersistent(player: Player, path: { string }, index: number)
	local profile = profiles[player]

	if not profile then
		warn "This player's profile is not loaded, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player]:ArrayRemove(path, index)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	local updateSignal = persistentDataUpdatedSignals[player.UserId]

	if updateSignal then updateSignal:Fire(profile.Data) end
end

--[[
	Performs `ArrayRemove()` on the player's temporary data replica and updates the public data replica accordingly.

	---

	The player's temporary data must be loaded.
]]
function PlayerDataManager.arrayRemoveTemp(player: Player, path: { string }, index: number)
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	if not privateTempDataReplica then
		warn "This player's temporary data is not loaded, so no operation will be performed."
		return
	end

	privateTempDataReplica:ArrayRemove(path, index)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Performs `ArraySet()` on the player's persistent data replica and updates the public data replica accordingly.

	---

	The player's persistent data must be loaded.
]]
function PlayerDataManager.arraySetPersistent(player: Player, path: { string }, index: number, value: DataTreeValue)
	local profile = profiles[player]

	if not profile then
		warn "This player's profile is not loaded, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player]:ArraySet(path, index, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	local updateSignal = persistentDataUpdatedSignals[player.UserId]

	if updateSignal then updateSignal:Fire(profile.Data) end
end

--[[
	Performs `ArraySet()` on the player's temporary data replica and updates the public data replica accordingly.

	---

	The player's temporary data must be loaded.
]]
function PlayerDataManager.arraySetTemp(player: Player, path: { string }, index: number, value: DataTreeValue)
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	if not privateTempDataReplica then
		warn "This player's temporary data is not loaded, so no operation will be performed."
		return
	end

	privateTempDataReplica:ArraySet(path, index, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Gets an event that fires when the given player's persistent data is updated.

	---

	@param userId The user ID of the player whose persistent data to get the update signal for.
]]
function PlayerDataManager.getPersistentDataUpdatedSignal(userId: number): RBXScriptSignal
	local updateSignal = persistentDataUpdatedSignals[userId]

	if not updateSignal then
		updateSignal = Instance.new "BindableEvent"
		persistentDataUpdatedSignals[userId] = updateSignal
	end

	return (updateSignal :: BindableEvent).Event
end

--[[
	Returns an array of all players whose persistent data are loaded.
]]
function PlayerDataManager.getPlayersWithLoadedPersistentData(): { Player }
	local players = {}

	for player in profiles do
		table.insert(players, player)
	end

	return players
end

--[[
	Returns an array of all players whose temporary data is loaded.
]]
function PlayerDataManager.getPlayersWithLoadedTempData(): { Player }
	local players = {}

	for player in privatePlayerTempDataReplicas do
		table.insert(players, player)
	end

	return players
end

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
	return privatePlayerTempDataReplicas[player] ~= nil
end

--[[
	Performs `SetValue()` on the player's persistent data replica and updates the public data replica accordingly.

	---

	The player's persistent data must be loaded.
]]
function PlayerDataManager.setValuePersistent(player: Player, path: { string }, value: DataTreeValue)
	local profile = profiles[player]

	if not profile then
		warn "This player's profile is not loaded, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player]:SetValue(path, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	local updateSignal = persistentDataUpdatedSignals[player.UserId]

	if updateSignal then updateSignal:Fire(profile.Data) end
end

--[[
	Performs `SetValue()` on the player's temporary data replica and updates the public data replica accordingly.

	---

	The player's temporary data must be loaded.
]]
function PlayerDataManager.setValueTemp(player: Player, path: { string }, value: DataTreeValue)
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	if not privateTempDataReplica then
		warn "This player's temporary data is not loaded, so no operation will be performed."
		return
	end

	privateTempDataReplica:SetValue(path, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Performs `SetValues()` on the player's persistent data replica and updates the public data replica accordingly.

	---

	The player's persistent data must be loaded.
]]
function PlayerDataManager.setValuesPersistent(player: Player, path: { string }, values: DataTreeDictionary)
	local profile = profiles[player]

	if not profile then
		warn "This player's profile is not loaded, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player]:SetValues(path, values)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	local updateSignal = persistentDataUpdatedSignals[player.UserId]

	if updateSignal then updateSignal:Fire(profile.Data) end
end

--[[
	Performs `SetValues()` on the player's temporary data replica and updates the public data replica accordingly.

	---

	The player's temporary data must be loaded.
]]
function PlayerDataManager.setValuesTemp(player: Player, path: { string }, values: DataTreeDictionary)
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	if not privateTempDataReplica then
		warn "This player's temporary data is not loaded, so no operation will be performed."
		return
	end

	privateTempDataReplica:SetValues(path, values)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Subscribes the given player to the persistent data of the (likely) offline player with the given ID. Doing so means
	that the persistent data of the given offline player will be routinely retrieved. If no ID is given, the given
	player will be unsubscribed from any persistent data they're currently subscribed to.

	---

	A player can only be subscribed to one player's persistent data at a time, so subscribing to a new player while
	already having a subscription will cancel the previous one. Any subscription will be cancelled if the player leaves
	the game.

	It is recommended that the player be unsubscribed when they no longer need to view the persistent data to reduce
	unnecessary requests.

	---

	@param player The player to subscribe.
	@param dataUserId The user ID of the player whose persistent data to subscribe to.
]]
function PlayerDataManager.subscribePlayerToPersistentData(player: Player, dataUserId: number?)
	if subscriptions[player] == dataUserId then return end

	unsubscribePlayer(player)

	if not dataUserId then return end

	subscriptions[player] = dataUserId

	incrementSubscription(dataUserId)
end

--[[
	Subscribes the server to a player's persistent data. Doing so means that the persistent data of the given player
	will be routinely retrieved.

	---

	The server can subscribe to any number of players' persistent data at a time.

	It is recommended that the server be unsubscribed when it no longer needs to view the persistent data to reduce
	unnecessary requests.

	---

	@param userId The user ID of the player whose persistent data to subscribe to.
]]
function PlayerDataManager.subscribeServerToPersistentData(userId: number)
	if serverSubscriptions[userId] then return end

	serverSubscriptions[userId] = true

	incrementSubscription(userId)
end

--[[
	Unsubscribes the given player from any persistent data they're currently subscribed to.

	---

	@param userId The user ID of the player whose persistent data to unsubscribe from.
]]
function PlayerDataManager.unsubscribeServerFromPersistentData(userId: number)
	if not serverSubscriptions[userId] then return end

	serverSubscriptions[userId] = nil

	decrementSubscription(userId)
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
	Returns the player's persistent data for viewing only. Returns `nil` if it is not loaded.

	---

	*Do **NOT** motify the returned data under any circumstances! Use the modifier functions in this module instead.*
]]
function PlayerDataManager.viewPersistentData(player: Player): PlayerPersistentData?
	local profile = profiles[player]

	return if profile then profile.Data else nil
end

--[[
	Returns the player's temporary data for viewing only. Returns `nil` if it is not loaded.

	---

	*Do **NOT** motify the returned data under any circumstances! Use the modifier functions in this module instead.*
]]
function PlayerDataManager.viewTempData(player: Player): {}?
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	return if privateTempDataReplica then privateTempDataReplica.Data else nil
end

--[[
	An event that fires when the player's persistent data is loaded. The player is passed as the first argument.
]]
PlayerDataManager.persistentDataLoaded = profileLoadedEvent.Event

--[[
	An event that fires when the player's persistent data is unloaded. The player is passed as the first argument.
]]
PlayerDataManager.persistentDataUnloaded = profileUnloadedEvent.Event

--[[
	An event that fires when the player's temporary data is loaded. The player is passed as the first argument.
]]
PlayerDataManager.tempDataLoaded = tempDataLoadedEvent.Event

--[[
	An event that fires when the player's temporary data is unloaded. The player is passed as the first argument.
]]
PlayerDataManager.tempDataUnloaded = tempDataUnloadedEvent.Event

return PlayerDataManager
