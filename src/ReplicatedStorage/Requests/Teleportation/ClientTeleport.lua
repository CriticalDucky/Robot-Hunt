--[[
	Provides client access to teleportation requests.
]]

--#region Imports
local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local serverFolder = replicatedStorageShared:WaitForChild "Server"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local enumsFolder = replicatedFirstShared:WaitForChild "Enums"
local configurationFolder = replicatedFirstShared:WaitForChild "Configuration"

local ServerTypeGroups = require(configurationFolder.ServerTypeGroups)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")
local ReplicaRequest = require(requestsFolder:WaitForChild "ReplicaRequest")
local ReplicatedServerData = require(serverFolder:WaitForChild "ReplicatedServerData")
local LiveServerData = require(serverFolder:WaitForChild "LiveServerData")
local Table = require(utilityFolder:WaitForChild "Table")
local TeleportRequestType = require(enumsFolder:WaitForChild "TeleportRequestType")
local TeleportResponseType = require(enumsFolder:WaitForChild "TeleportResponseType")
local Locations = require(configurationFolder:WaitForChild "LocationConstants")
local FriendLocations = require(serverFolder:WaitForChild "FriendLocations")
local WorldOrigin = require(serverFolder:WaitForChild "WorldOrigin")
local ActiveParties = require(serverFolder:WaitForChild "ActiveParties")
local Types = require(utilityFolder:WaitForChild "Types")
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")
-- local HomeLockType = require(enumsFolder:WaitForChild "HomeLockType")
-- local Friends = require(utilityFolder:WaitForChild "Friends")

type ServerIdentifier = Types.ServerIdentifier
type UserEnum = Types.UserEnum
--#endregion

local player = Players.LocalPlayer

local ClientTeleport = {}
local Authorize = {}

--[[
	The general function for making a teleport request.
	Wrapped by other functions in this module.
]]
local function requestTeleport(teleportRequestType, ...)
	assert(
		Table.hasValue(TeleportRequestType, teleportRequestType),
		"Teleport.request() called with invalid teleportRequestType: " .. tostring(teleportRequestType)
	)

	local vararg = { ... }

	local TeleportRequest = ReplicaCollection.waitForReplica "TeleportRequest"

	local response = ReplicaRequest.new(TeleportRequest, teleportRequestType, unpack(vararg))

	Table.print(response, "request() response:", true)
	return unpack(response)
end

--[[
	Authorize a teleport to a world.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.

	```lua
	local isAllowed, responseType = Authorize.toWorld(worldIndex)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toWorld(worldIndex: number)
	local isWorldFull = LiveServerData.isWorldFull(worldIndex, 1)

	if isWorldFull then
		warn("ClientTeleport.toWorld() called with full world: " .. tostring(worldIndex))

		return false, TeleportResponseType.full
	else
		return true
	end
end

--[[
	Authorize a teleport to a location.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.

	```lua
	local isAllowed, teleportResponseType = Authorize.toLocation(locationEnum)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toLocation(locationEnum: UserEnum)
	local localWorldIndex -- The world index of the server we're on (or the world origin if we're in a minigame, party, or home)

	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
		local serverIdentifier = LocalServerInfo.getServerIdentifier()

		if locationEnum == serverIdentifier.locationEnum then
			warn("ClientTeleport.toLocation() called with current locationEnum: " .. tostring(locationEnum))

			return false, TeleportResponseType.alreadyInPlace
		end

		localWorldIndex = serverIdentifier.worldIndex
	elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
		localWorldIndex = WorldOrigin.get(player)
	else
		error "ClientTeleport.toLocation() called on server without world info"
	end

	if not ReplicatedServerData.worldHasLocation(localWorldIndex, locationEnum) then
		warn("ClientTeleport.toLocation() called with invalid locationEnum: " .. tostring(locationEnum))

		return false, TeleportResponseType.invalid -- The replicated server data might not have replicated yet, so we can't be sure
	end

	if LiveServerData.isLocationFull(localWorldIndex, locationEnum, 1) then
		-- local setting =

		-- if setting then
		-- 	return true
		-- else
		-- 	warn("ClientTeleport.toLocation() called with full location: " .. tostring(locationEnum))

		-- 	return false, TeleportResponseType.full
		-- end
	end

	return true
end

--[[
	Authorize a teleport to a friend.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.

	```lua
	local isAllowed, teleportResponseType = Authorize.toFriend(playerId)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toFriend(playerId: number)
	local friendLocation = FriendLocations.get(true)[playerId]

	if friendLocation then
		local serverType = friendLocation.serverType

		if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, serverType) then
			if not ReplicatedServerData.worldHasLocation(friendLocation.worldIndex, friendLocation.locationEnum) then
				warn("Authorize.toFriend() called with invalid locationEnum: " .. tostring(friendLocation.locationEnum))

				return false, TeleportResponseType.invalid
			end

			if LiveServerData.isLocationFull(friendLocation.worldIndex, friendLocation.locationEnum, 1) then
				warn("Authorize.toFriend() called with full location: " .. tostring(friendLocation.locationEnum))

				return false, TeleportResponseType.full
			end

			if Locations.info[friendLocation.locationEnum].cantJoinPlayer then
				warn(
					"Authorize.toFriend() called with location that can't be joined: "
						.. tostring(friendLocation.locationEnum)
				)

				return false, TeleportResponseType.invalid
			end
		elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, serverType) then
			if LiveServerData.isPartyFull(friendLocation.partyType, friendLocation.partyIndex, 1) then
				warn("Authorize.toFriend() called with full party: " .. tostring(friendLocation.partyType))

				return false, TeleportResponseType.full
			end
		elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isMinigame, serverType) then
			if typeof(friendLocation.minigameIndex) == "string" or friendLocation.minigameIndex == nil then
				warn "Authorize.toFriend(): friend is in an instance minigame server"

				return false, TeleportResponseType.invalid
			end

			if LiveServerData.isMinigameFull(friendLocation.minigameType, friendLocation.minigameIndex) then
				warn("ClientTeleport.toFriend() called with full minigame: " .. tostring(friendLocation.minigameType))

				return false, TeleportResponseType.full
			end
		else
			warn("ClientTeleport.toFriend() called with invalid serverType: " .. tostring(serverType))

			return false, TeleportResponseType.invalid
		end
	else
		warn("ClientTeleport.toFriend() called with invalid playerId: " .. tostring(playerId))

		return false, TeleportResponseType.invalid
	end

	return true
end

--[[
	Authorize a teleport to a party.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.

	```lua
	local isAllowed, teleportResponseType = Authorize.toParty(partyType)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toParty(partyType: UserEnum)
	assert(partyType, "ClientTeleport.toParty() called with nil partyType")

	local activeParty = ActiveParties.getActiveParty()

	if activeParty.partyType ~= partyType then
		warn("ClientTeleport.toParty() called with an inactive partyType: " .. tostring(partyType))

		return false, TeleportResponseType.disabled
	end

	return true
end

--[[
	Authorize a teleport to a home.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.

	```lua
	local isAllowed, teleportResponseType = Authorize.toHome(homeOwnerUserId)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toHome(homeOwnerUserId: number)
	-- if ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
	-- 	local serverIdentifier = LocalServerInfo.getServerIdentifier()

	-- 	if serverIdentifier.homeOwner == homeOwnerUserId then
	-- 		warn("ClientTeleport.toHome() called with current homeOwnerUserId: " .. tostring(homeOwnerUserId))

	-- 		return false, TeleportResponseType.alreadyInPlace
	-- 	end
	-- end

	-- if homeOwnerUserId == player.UserId then return true end -- If we're trying to teleport to our own home, we don't need to check if it's full

	-- if LiveServerData.isHomeFull(homeOwnerUserId, 1) then
	-- 	warn("ClientTeleport.toHome() called with full home: " .. tostring(homeOwnerUserId))

	-- 	return false, TeleportResponseType.full
	-- end

	-- local isFriend = Friends.are(player.UserId, homeOwnerUserId)
	-- local homeLockType = ClientPlayerSettings.getSetting("homeLock", homeOwnerUserId)

	-- local friendsOnlyButNotFriend = homeLockType == HomeLockType.friendsOnly and not isFriend
	-- local lockedToEveryone = homeLockType == HomeLockType.locked

	-- if friendsOnlyButNotFriend or lockedToEveryone then
	-- 	warn("ClientTeleport.toHome() called with locked home: " .. tostring(homeOwnerUserId))
	-- 	warn(friendsOnlyButNotFriend, lockedToEveryone) -- For debugging when I inevitably run into this

	-- 	return false, TeleportResponseType.locked
	-- end

	-- return true
end

--[[
	Initializes a teleport request to the given world.
	Returns the success of the request along with a TeleportResponseType if not.

	```lua
	local success, teleportResponseType = ClientTeleport.toWorld(worldIndex)
	```
]]
function ClientTeleport.toWorld(worldIndex: number)
	local isAllowed, teleportResponseType = Authorize.toWorld(worldIndex)

	if isAllowed then
		return requestTeleport(TeleportRequestType.toWorld, worldIndex)
	else
		warn("ClientTeleport.toWorld() unauthorized: " .. tostring(teleportResponseType))

		return false, teleportResponseType
	end
end

--[[
	Initializes a teleport request to the given location.
	Returns the success of the request along with a TeleportResponseType if not.

	```lua
	local success, teleportResponseType = ClientTeleport.toLocation(locationEnum)
	```
]]
function ClientTeleport.toLocation(locationEnum: UserEnum)
	local isAllowed, teleportResponseType = Authorize.toLocation(locationEnum)

	if isAllowed then
		return requestTeleport(TeleportRequestType.toLocation, locationEnum)
	else
		warn("ClientTeleport.toLocation() unauthorized: " .. tostring(teleportResponseType))

		return false, teleportResponseType
	end
end

--[[
	Initializes a teleport request to the given friend.
	Returns the success of the request along with a TeleportResponseType if not.

	```lua
	local success, teleportResponseType = ClientTeleport.toFriend(playerId)
	```
]]
function ClientTeleport.toFriend(playerId: number)
	local isAllowed, teleportResponseType = Authorize.toFriend(playerId)

	if isAllowed then
		return requestTeleport(TeleportRequestType.toFriend, playerId)
	else
		warn("ClientTeleport.toFriend() unauthorized: " .. tostring(teleportResponseType))

		return false, teleportResponseType
	end
end

--[[
	Initializes a teleport request to the given party.
	Returns the success of the request along with a TeleportResponseType if not.

	```lua
	local success, teleportResponseType = ClientTeleport.toParty(partyType)
	```
]]
function ClientTeleport.toParty(partyType: UserEnum)
	local isAllowed, teleportResponseType = Authorize.toParty(partyType)

	if isAllowed then
		return requestTeleport(TeleportRequestType.toParty, partyType)
	else
		warn("ClientTeleport.toParty() unauthorized: " .. tostring(teleportResponseType))

		return false, teleportResponseType
	end
end

--[[
	Initializes a teleport request to the given home.
	Returns the success of the request along with a TeleportResponseType if not.

	NOTE: Currently only supports teleporting to your own home.

	```lua
	local success, teleportResponseType = ClientTeleport.toHome(homeOwnerUserId)
	```
]]
function ClientTeleport.toHome(homeOwnerUserId: number)
	local isAllowed, teleportResponseType = Authorize.toHome(homeOwnerUserId)

	if isAllowed then
		return requestTeleport(TeleportRequestType.toHome, homeOwnerUserId)
	else
		warn("ClientTeleport.toHome() unauthorized: " .. tostring(teleportResponseType))

		return false, teleportResponseType
	end
end

--[[
	Initializes a client-requested rejoin.
	Guaranteed to succeed, does not return anything.

	No rejoin reason providable due to security reasons

	```lua
	local success, teleportResponseType = ClientTeleport.rejoin()
	```
]]
function ClientTeleport.rejoin()
	requestTeleport(TeleportRequestType.rejoin)
end

return ClientTeleport
