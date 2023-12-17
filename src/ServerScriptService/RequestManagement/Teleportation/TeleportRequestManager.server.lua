local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local serverFolder = replicatedStorageShared.Server
local serverStorageShared = ServerStorage.Shared
local serverStorageVendor = ServerStorage.Vendor
local teleportationFolder = serverStorageShared.Teleportation
local utilityFolder = replicatedFirstShared.Utility
local enumsFolder = replicatedFirstShared.Enums
local serverStorageSharedUtility = serverStorageShared.Utility
local configurationFolder = replicatedFirstShared.Configuration

local ReplicaService = require(serverStorageVendor.ReplicaService)
local Teleport = require(teleportationFolder.Teleport)
local TeleportRequestType = require(enumsFolder.TeleportRequestType)
local TeleportResponseType = require(enumsFolder.TeleportResponseType)
local ActiveParties = require(serverFolder.ActiveParties)
local ReplicaResponse = require(serverStorageSharedUtility.ReplicaResponse)
local Param = require(utilityFolder.Param)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(configurationFolder.ServerTypeGroups)

local Types = require(utilityFolder.Types)

type Promise = Types.Promise

local teleportRequest = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "TeleportRequest",
	Replication = "All",
}

ReplicaResponse.listen(teleportRequest, function(player: Player, teleportRequestType, ...)
	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
		warn "Routing server received a teleport request. This should never happen."
		return false, TeleportResponseType.invalid
	end

	if not Param.expect { teleportRequestType, "string", "number" } then
		warn "Invalid request: teleportRequestType is nil or invalid"
		return false, TeleportResponseType.invalid
	end

	if teleportRequestType == TeleportRequestType.toWorld then
		local worldIndex = ...

		if not Param.expect { worldIndex, "number" } then
			warn "Invalid request: worldIndex is nil or invalid"
			return false, TeleportResponseType.invalid
		end

		local success, result = Teleport.toWorld(player, worldIndex)

        if success then
            return result[player]:await()
        else
            warn("Teleport to world failed: " .. tostring(result))
            return false, result
        end
	elseif teleportRequestType == TeleportRequestType.toLocation then
		local locationEnum = ...

		if not Param.expect { locationEnum, "string" } then
            warn "Invalid request: locationEnum is nil or invalid"
            return false, TeleportResponseType.invalid
        end

        local success, result = Teleport.toLocation(player, locationEnum)

        if success then
            return result[player]:await()
        else
            warn("Teleport to location failed: " .. tostring(result))
            return false, result
        end
	elseif teleportRequestType == TeleportRequestType.toFriend then
		local targetPlayerId = ...

        if not Param.expect { targetPlayerId, "number" } then
            warn "Invalid request: targetPlayerId is nil or invalid"
            return false, TeleportResponseType.invalid
        end

        local success, result = Teleport.toPlayer(player, targetPlayerId)

        if success then
            return result[player]:await()
        else
            warn("Teleport to player failed: " .. tostring(result))
            return false, result
        end
	elseif teleportRequestType == TeleportRequestType.toParty then
		local partyType = ...

        if not Param.expect { partyType, "string" } then
            warn "Invalid request: partyType is nil or invalid"
            return false, TeleportResponseType.invalid
        end

        if partyType ~= ActiveParties.getActiveParty().partyType then
            warn "Invalid request: partyType is not the same as the player's active party"

            return false, TeleportResponseType.disabled
        end

        local success, result = Teleport.toParty(player, partyType)

        if success then
            return result[player]:await()
        else
            warn("Teleport to party failed: " .. tostring(result))

            return false, result
        end
	elseif teleportRequestType == TeleportRequestType.toHome then
		local homeOwnerUserId = ...

        if not Param.expect { homeOwnerUserId, "number" } then
            warn "Invalid request: homeOwnerUserId is nil or invalid"
            return false, TeleportResponseType.invalid
        end

        local success, result = Teleport.toHome(player, homeOwnerUserId)

        if success then
            return result[player]:await()
        else
            warn("Teleport to home failed: " .. tostring(result))
            return false, result
        end
	elseif teleportRequestType == TeleportRequestType.rejoin then
		Teleport.rejoin(player, "An unknown error occured on the client. (err code C1)")

        return false
	else
		warn "Invalid request: teleportRequestType is nil or invalid"

		return false, TeleportResponseType.invalid
	end
end)
