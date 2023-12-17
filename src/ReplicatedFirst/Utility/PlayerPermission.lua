local GROUP_ID = 6630311

local ReplicatedFirst = game:GetService "ReplicatedFirst"

local Enums = require(ReplicatedFirst:WaitForChild "Enums")

local PlayerPermissionLevel = Enums.PlayerPermissionLevel

local RANK_TO_PERMISSION = {
	[0] = PlayerPermissionLevel.player,
	[64] = PlayerPermissionLevel.moderator,
	[128] = PlayerPermissionLevel.admin,
	[255] = PlayerPermissionLevel.owner,
}

local PERMISSION_TO_RANK
do
	PERMISSION_TO_RANK = {}

	for rank, permission in pairs(RANK_TO_PERMISSION) do
		PERMISSION_TO_RANK[permission] = rank
	end
end

local cachedPermissions = {}

local function getPermissionLevel(player: Player)
	assert(typeof(player) == "Instance" and player:IsA "Player", "player must be a Player")

	local success, rank = pcall(function() return player:GetRankInGroup(GROUP_ID) end)

	if not success then
		warn("Failed to get rank for player " .. player.Name .. " in group " .. GROUP_ID)
		return PlayerPermissionLevel.player
	end

	local roundedRank
	do
		for rankIter, _ in pairs(RANK_TO_PERMISSION) do
			local distanceFromRank = rank - rankIter

			if distanceFromRank >= 0 and (not roundedRank or distanceFromRank < (rank - roundedRank)) then
				roundedRank = rankIter
			end
		end
	end

	return RANK_TO_PERMISSION[roundedRank]
end

local PlayerPermission = {}

function PlayerPermission.get(player: Player)
	local permissionLevel = cachedPermissions[player]

	if not permissionLevel then
		permissionLevel = getPermissionLevel(player)
		cachedPermissions[player] = permissionLevel
	end

	return permissionLevel
end

function PlayerPermission.hasPermission(player: Player, permissionLevel)
	return PERMISSION_TO_RANK[PlayerPermission.get(player)] >= PERMISSION_TO_RANK[permissionLevel]
end

return PlayerPermission
