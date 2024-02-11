local ServerStorage = game:GetService "ServerStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"
local RunService = game:GetService "RunService"

local GameLoop = ServerStorage.GameLoop
local Data = ReplicatedStorage.Data

local RoundDataManager = require(GameLoop.RoundDataManager)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local ClientServerCommunication = require(Data.ClientServerCommunication)
local Enums = require(ReplicatedFirst.Enums)

local roundData = RoundDataManager.data

--[[
    This function checks if the player can be shooting. This does not do phyisical checks,
    only checks if the player is in the correct state to be shooting.

    If the result of the function is false, the gun must be stopped from shooting.
]]
local function canBeShooting(player: Player): boolean
	local playerData = roundData.playerData[player.UserId]

	if not playerData then return false end
	if playerData.status ~= Enums.PlayerStatus.alive then return false end
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

local function getHitPositionAndVictim(
	player: Player,
	hitPosition: Vector3
): { hitPosition: Vector3?, victim: Player?, distance: number? }
	local character = player.Character -- the character must exist, if it errors then we dont care

	local referencesFolder = character.Gun.References :: Configuration
	local gunTipAttachment = referencesFolder.AttachmentTip.Value :: Attachment
	local hitbox = referencesFolder.Hitbox.Value :: BasePart

	local function isAnythingIntersectingGun(): boolean
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = { player.Character }

		local intersectingParts = workspace:GetPartsInPart(hitbox, overlapParams)

		for _, part in ipairs(intersectingParts) do
			if part:IsDescendantOf(player.Character) then continue end

			return true
		end

		return false
	end

	local direction = (hitPosition - gunTipAttachment.WorldPosition).Unit
	local distance = (hitPosition - gunTipAttachment.WorldPosition).Magnitude
	local newHitPosition
	local hitInstance

	do
		if isAnythingIntersectingGun() then return { hitPosition = nil, victim = nil } end

        local guns = {}
        do
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character

                if char then
                    local gun = char:FindFirstChild "Gun"

                    if gun then table.insert(guns, gun) end
                end
            end
        end

        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { character, unpack(guns) }
        params.FilterType = Enum.RaycastFilterType.Exclude

		local raycastResult = workspace:Raycast(
			gunTipAttachment.WorldPosition,
			direction * 256,
			params
		)

		newHitPosition = raycastResult and raycastResult.Position or gunTipAttachment.WorldPosition + direction * 256
		hitInstance = raycastResult and raycastResult.Instance
	end


	if hitInstance then
		local hitPlayer = Players:GetPlayerFromCharacter(hitInstance.Parent)

		if hitPlayer then return { hitPosition = newHitPosition, victim = hitPlayer, distance = distance } end

		return { hitPosition = newHitPosition, victim = nil, distance = distance }
	else
		return { hitPosition = newHitPosition, victim = nil, distance = distance }
	end
end

ClientServerCommunication.registerActionAsync(
	"UpdateShootingStatus",
	function(player: Player, data: { hitPosition: Vector3 }?)
		if data then -- if the player is shooting
			if not canBeShooting(player) then return end
			local shootData = getHitPositionAndVictim(player, data.hitPosition)

            RoundDataManager.updateShootingStatus(player, true, shootData.hitPosition)

			if shootData.victim then
				RoundDataManager.addVictim(player, shootData.victim)
            else
                RoundDataManager.removeVictim(player)
            end
		elseif roundData.playerData[player.UserId].actions.isShooting then
			RoundDataManager.removeVictim(player)
			RoundDataManager.updateShootingStatus(player, false)
		end
	end
)

RoundDataManager.onDataUpdated:Connect(function(roundData)
	for userId, playerData in pairs(roundData.playerData) do
        local player = Players:GetPlayerByUserId(userId)

        if not player then continue end

		if playerData.actions.isShooting then
			if not canBeShooting(player) then
				RoundDataManager.updateShootingStatus(player, false)
			end
		end
	end
end)

RunService.Heartbeat:Connect(function(dt)
    for userId, playerData in pairs(roundData.playerData) do
        local player = Players:GetPlayerByUserId(userId)

        if not player then continue end

        if playerData.actions.isShooting and playerData.gunHitPosition then
            local shootData = getHitPositionAndVictim(player, playerData.gunHitPosition)

            if shootData.hitPosition and shootData.victim and shootData.distance then
                local damage

                do
                    local multiplier = RoundConfiguration.gunStrengthMultiplier
                    local baseDamage = RoundConfiguration.gunBaseDamagePerSecond
                    local powerupMultiplier = RoundConfiguration.gunPowerupMultiplier

                    damage = baseDamage * multiplier ^ (shootData.distance)

                    if false then -- if the player has a powerup (TODO: implement powerups)
                        damage *= powerupMultiplier
                    end

                    damage *= dt
                end

                RoundDataManager.incrementAccountedHealth(shootData.victim, -damage)
            end
        end
    end
end)