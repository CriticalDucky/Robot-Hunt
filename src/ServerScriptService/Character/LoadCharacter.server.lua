-- local ReplicatedFirst = game:GetService "ReplicatedFirst"
-- local ServerStorage = game:GetService "ServerStorage"
-- local Players = game:GetService "Players"

-- local replicatedFirstShared = ReplicatedFirst.Shared
-- local enumsFolder = replicatedFirstShared.Enums
-- local utilityFolder = replicatedFirstShared.Utility
-- local configurationFolder = replicatedFirstShared.Configuration

-- local ServerGroupEnum = require(enumsFolder.ServerGroup)
-- local ServerTypeGroups = require(configurationFolder.ServerTypeGroups)
-- local WaitForDescendant = require(utilityFolder.WaitForDescendant)

-- local function playerAdded(player: Player)
-- 	local spawnpoint

-- 	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
-- 		local entranceDataFolder = ServerStorage.EntranceData
-- 		local Entrances = require(entranceDataFolder.Entrances)

-- 		local joinData = player:GetJoinData()
-- 		local locationFrom = joinData and joinData.TeleportData and joinData.TeleportData.locationFrom

-- 		if locationFrom then
-- 			local entranceGroup = Entrances.groups[locationFrom]
-- 			spawnpoint = if entranceGroup then entranceGroup.entrance else Entrances.main
-- 		else
-- 			spawnpoint = Entrances.main
-- 		end
-- 	elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldInfo) then
-- 		spawnpoint = WaitForDescendant(workspace, function(descendant)
-- 			local name = descendant.Name

-- 			return string.find(name, "Spawn")
-- 		end)
-- 	end

-- 	player.RespawnLocation = spawnpoint
-- 	player:LoadCharacter()
-- end

-- if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
-- 	for _, player in pairs(Players:GetPlayers()) do
-- 		playerAdded(player)
-- 	end

-- 	Players.PlayerAdded:Connect(playerAdded)
-- end
