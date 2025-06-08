-- ServerGunManagerDual.lua  – supports two barrels & two GunCage parts
---------------------------------------------------------------------
-- SERVICES
---------------------------------------------------------------------
local ServerStorage = game:GetService "ServerStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"
local RunService = game:GetService "RunService"

---------------------------------------------------------------------
-- MODULES
---------------------------------------------------------------------
local RoundDataManager = require(ServerStorage.GameLoop.RoundDataManager)
local RoundConfig = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Net = require(ReplicatedStorage.Data.ClientServerCommunication)
local Enums = require(ReplicatedFirst.Enums)
local ItemCollector = require(ReplicatedFirst.Utility.ItemCollector)

local roundData = RoundDataManager.data

ItemCollector:BindQuality("GunTransparentParts", workspace, function(descendant)
	if descendant:IsA "BasePart" and descendant.Transparency >= RoundConfig.gunMinimumTransparencyThreshold then
		return true
	end
	return false
end)

---------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------
local function canBeShooting(plr: Player): boolean
	local pd = roundData.playerData[plr.UserId]
	if not pd then return false end
	if pd.status ~= Enums.PlayerStatus.alive then return false end
	if pd.ammo <= 0 then return false end
	if pd.actions.isHacking then return false end

	if roundData.currentRoundType == Enums.RoundType.defaultRound then
		local phase = roundData.currentPhaseType
		local perms = {
			[Enums.TeamType.rebels] = { [Enums.PhaseType.PhaseTwo] = true },
			[Enums.TeamType.hunters] = {
				[Enums.PhaseType.PhaseOne] = true,
				[Enums.PhaseType.PhaseTwo] = true,
				[Enums.PhaseType.Purge] = true,
			},
		}
		if not perms[pd.team][phase] then return false end
	end

	return true
end

local function getPlayerFromCharDescendant(descendant: Instance): Player?
	local player = Players:GetPlayerFromCharacter(descendant.Parent)
	if not player and descendant.Parent then player = Players:GetPlayerFromCharacter(descendant.Parent.Parent) end
	return player
end

---------------------------------------------------------------------
-- collision check using two GunCage parts
---------------------------------------------------------------------
local function gunColliding(char: Model): boolean
	local cages = {
		-- char:FindFirstChild "LeftGunCage",
		char:FindFirstChild "RightGunCage",
	}
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = { char, table.unpack(ItemCollector:GetPartsWithQuality "GunTransparentParts") }
	for _, cage in ipairs(cages) do
		if cage then
			for _, p in ipairs(workspace:GetPartsInPart(cage, params)) do
				if not p:IsDescendantOf(char) then return true end
			end
		end
	end
	return false
end

---------------------------------------------------------------------
-- returns hitPos, victim and distance for a single muzzle
---------------------------------------------------------------------
local function solveRay(player: Player, tip: Vector3, hitPos: Vector3): { pos: Vector3, victim: Player?, dist: number }
	local char = player.Character
	local origin = tip

	local dir = (hitPos - origin).Unit
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char, table.unpack(ItemCollector:GetPartsWithQuality "GunTransparentParts") }
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, dir * 256, params)
	hitPos = result and result.Position or (origin + dir * 256)
	local hitInst = result and result.Instance
	local victim = hitInst and getPlayerFromCharDescendant(hitInst)
	return { pos = hitPos, victim = victim, dist = (hitPos - origin).Magnitude }
end

---------------------------------------------------------------------
-- per-player shoot resolve (handles both muzzles)
---------------------------------------------------------------------
local function getShootData(player: Player, hitPosL: Vector3?, hitPosR: Vector3?)
	local char = player.Character
	if not char then return nil end

	local leftUpperArm = char:FindFirstChild "LeftUpperArm"
	local rightUpperArm = char:FindFirstChild "RightUpperArm"
	if not leftUpperArm or not rightUpperArm then
		warn "LeftUpperArm or RightUpperArm not found"
		return nil
	end

	-- if gun blocked -> no shot
	if gunColliding(char) then
		return {
			hitL = nil,
			hitR = nil,
			victimL = nil,
			victimR = nil,
			distL = nil,
			distR = nil,
		}
	end

	local resL = if hitPosL then solveRay(player, leftUpperArm.Position, hitPosL) else nil
	local resR = if hitPosR then solveRay(player, rightUpperArm.Position, hitPosR) else nil

	return {
		hitL = resL and resL.pos,
		hitR = resR and resR.pos,
		victimL = resL and resL.victim,
		victimR = resR and resR.victim,
		distL = resL and resL.dist,
		distR = resR and resR.dist,
	}
end

---------------------------------------------------------------------
-- NETWORK
---------------------------------------------------------------------
Net.registerActionAsync("UpdateShootingStatus", function(plr, data)
	-- data may contain hitPositionL / hitPositionR when client is shooting
	local pd = roundData.playerData[plr.UserId]
	if not pd then return end

	if data then
		-- begin/continue shooting
		if not canBeShooting(plr) then return end

		local shot = getShootData(plr, data.gunHitPositionL, data.gunHitPositionR)

		if not shot then return end

		RoundDataManager.updateShootingStatus(plr, true, shot.hitL, shot.hitR)

		-- victims
		if
			shot.victimL
			and roundData.playerData[shot.victimL.UserId]
			and roundData.playerData[shot.victimL.UserId].team ~= pd.team
		then
			RoundDataManager.addVictim(plr, shot.victimL)
		elseif
			shot.victimR
			and roundData.playerData[shot.victimR.UserId]
			and roundData.playerData[shot.victimR.UserId].team ~= pd.team
		then
			RoundDataManager.addVictim(plr, shot.victimR)
		else
			RoundDataManager.removeVictim(plr)
		end
	else
		-- stop shooting
		RoundDataManager.removeVictim(plr)
		RoundDataManager.updateShootingStatus(plr, false)
	end
end)

---------------------------------------------------------------------
-- keep data consistent if player can no longer shoot
---------------------------------------------------------------------
RoundDataManager.onDataUpdated:Connect(function()
	for uid, pd in pairs(roundData.playerData) do
		local plr = Players:GetPlayerByUserId(uid)
		if plr and pd.actions.isShooting and not canBeShooting(plr) then
			RoundDataManager.updateShootingStatus(plr, false)
		end
	end
end)

---------------------------------------------------------------------
-- DAMAGE LOOP
---------------------------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	for uid, pd in pairs(roundData.playerData) do
		if not pd.actions.isShooting or not (pd.gunHitPositionL or pd.gunHitPositionR) then continue end
		local plr = Players:GetPlayerByUserId(uid)
		if not plr then continue end

		local char = plr.Character
		if not char then continue end

		local cagesBlocked = gunColliding(char)
		if cagesBlocked then continue end

		local damageTaken = false

		-- Left hit
		if pd.gunHitPositionL then
			local result = getShootData(plr, pd.gunHitPositionL, pd.gunHitPositionL)
			if result.victimL and result.distL then
				local victimPd = roundData.playerData[result.victimL.UserId]
				if victimPd and victimPd.status == Enums.PlayerStatus.alive then
					local dmg = RoundConfig.gunBaseDamagePerSecond
						* RoundConfig.gunStrengthMultiplier ^ result.distL
						* dt
					RoundDataManager.incrementAccountedHealth(result.victimL, -dmg)
					damageTaken = true
				end
			end
		end

		-- Right hit
		if pd.gunHitPositionR and not damageTaken then
			local result = getShootData(plr, pd.gunHitPositionR, pd.gunHitPositionR)
			if result.victimR and result.distR then
				local victimPd = roundData.playerData[result.victimR.UserId]
				if victimPd and victimPd.status == Enums.PlayerStatus.alive then
					local dmg = RoundConfig.gunBaseDamagePerSecond
						* RoundConfig.gunStrengthMultiplier ^ result.distR
						* dt
					RoundDataManager.incrementAccountedHealth(result.victimR, -dmg)
				end
			end
		end
	end
end)
