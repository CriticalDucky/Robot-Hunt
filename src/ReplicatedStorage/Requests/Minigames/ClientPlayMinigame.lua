local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")

local requestsFolder = replicatedStorageShared:WaitForChild("Requests")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local enumsFolder = replicatedFirstShared:WaitForChild("Enums")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local serverFolder = replicatedStorageShared:WaitForChild("Server")

local ReplicaRequest = require(requestsFolder:WaitForChild("ReplicaRequest"))
local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local MinigameType = require(enumsFolder:WaitForChild("MinigameType"))
local Table = require(utilityFolder:WaitForChild("Table"))
local LocalServerInfo = require(serverFolder:WaitForChild("LocalServerInfo"))
local PlayMinigameResponseType = require(enumsFolder:WaitForChild("PlayMinigameResponseType"))

local ClientPlayMinigame = {}

function ClientPlayMinigame.request(minigameType, ...)
    assert(Table.hasValue(MinigameType, minigameType), "ClientPlayMinigame.request() called with invalid minigameType: " .. tostring(minigameType))

    local serverIdentifier = LocalServerInfo.getServerIdentifier()

    if not serverIdentifier then
        return
    end

    if serverIdentifier.minigameType == minigameType then
        warn("ClientPlayMinigame.request() called with own minigameType: " .. tostring(minigameType))

        return false, PlayMinigameResponseType.alreadyInPlace
    end

    return unpack(ReplicaRequest.new(ReplicaCollection.waitForReplica("PlayMinigameRequest"), minigameType, ...))
end

return ClientPlayMinigame
