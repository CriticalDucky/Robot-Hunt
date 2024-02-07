local PhysicsService = game:GetService "PhysicsService"
local ServerStorage = game:GetService "ServerStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local GameLoop = ServerStorage.GameLoop
local Data = ReplicatedStorage.Data
local Utility = ReplicatedFirst.Utility

local RoundDataManager = require(GameLoop.RoundDataManager)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local ClientServerCommunication = require(Data.ClientServerCommunication)
local SpacialQuery = require(Utility.SpacialQuery)
local Table = require(Utility.Table)
local Types = require(Utility.Types)
local Enums = require(ReplicatedFirst.Enums)

local roundData = RoundDataManager.data

local function stopShooting(player: Player)
    RoundDataManager.setGunHitPosition(player, nil)
    RoundDataManager.removeVictim(player)
    RoundDataManager.stop
end

--[[
    This function checks if the player can be shooting. This does not do phyisical checks,
    only checks if the player is in the correct state to be shooting.

    If the result of the function is false, the gun must be stopped from shooting.
]]
local function canBeShooting(player: Player): boolean
	local playerData = roundData.playerData[player.UserId]

	if not playerData then return false end

	if playerData.state ~= Enums.PlayerStatus.alive then return false end
	if playerData.ammo <= 0 then return false end
	if playerData.actions.isHacking then return false end

	if roundData.currentRoundType == Enums.RoundType.defaultRound then
		local currentPhase = roundData.currentPhaseType

		local gunPerms = {
			[Enums.TeamType.rebels] = {
				[Enums.PhaseType.PhaseTwo] = true,
			},
			[Enums.TeamType.hunters] = {
				[Enums.PhaseType.PhaseOne] = true,
				[Enums.PhaseType.PhaseTwo] = true,
				[Enums.PhaseType.Purge] = true,
			},
		}

		if not gunPerms[playerData.team][currentPhase] then return false end
	end

	return true
end

local function getHitPositionAndVictim(player: Player, hitPosition: Vector3): { hitPosition: Vector3?, victim: Player? }
	local character = player.Character -- the character must exist, if it errors then we dont care

	local referencesFolder = character.Gun.References :: Configuration
	local gunTipAttachment = referencesFolder.AttachmentTip.Value :: Attachment
	local hitbox = referencesFolder.Hitbox.Value :: BasePart

	local function isAnythingIntersectingGun(): boolean
		local overlapParams = PhysicsService:CreatePartCollisionParams()
		overlapParams.FilterDescendantsInstances = { player.Character }

		local intersectingParts = PhysicsService:GetPartsInPart(hitbox, overlapParams)

		for _, part in ipairs(intersectingParts) do
			if part:IsDescendantOf(player.Character) then continue end

			return true
		end

		return false
	end

	local direction = (hitPosition - gunTipAttachment.WorldPosition).Unit
	local newHitPosition
	local hitInstance

	do
		if isAnythingIntersectingGun() then return { hitPosition = nil, victim = nil } end

		local raycastResult = workspace:Raycast(
			gunTipAttachment.WorldPosition,
			direction * 256,
			{ FilterDescendantsInstances = { player.Character } }
		)

		newHitPosition = raycastResult and raycastResult.Position or gunTipAttachment.WorldPosition + direction * 256
		hitInstance = raycastResult and raycastResult.Instance
	end

	if hitInstance then
		local hitPlayer = Players:GetPlayerFromCharacter(hitInstance.Parent)

		if hitPlayer then return { hitPosition = newHitPosition, victim = hitPlayer } end

		return { hitPosition = newHitPosition, victim = nil }
	else
		return { hitPosition = newHitPosition, victim = nil }
	end
end

ClientServerCommunication.registerActionAsync(
	"UpdateShootingStatus",
	function(player: Player, data: { hitPosition: Vector3 }?)
		if data then -- if the player is shooting
			if not canBeShooting(player) then return end

			local shootData = getHitPositionAndVictim(player, data.hitPosition)

			if shootData.hitPosition and shootData.victim then
				RoundDataManager.addVictim(player, shootData.victim)
				RoundDataManager.setGunHitPosition(player, shootData.hitPosition)
			end
		else -- if the player is not shooting
            stopShooting(player)
		end
	end
)
