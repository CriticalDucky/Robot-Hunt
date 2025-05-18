-- ShootManagerDual.lua  – dual‑wield update using unified shootThread
-------------------------------------------------------------------
-- services
local Players = game:GetService "Players"
local RS = game:GetService "ReplicatedStorage"
local RF = game:GetService "ReplicatedFirst"
local CAS = game:GetService "ContextActionService"
local UIS = game:GetService "UserInputService"
local RunService = game:GetService "RunService"

-- modules
local ClientState = require(RS.Data.ClientState)
local CRDU = require(RS.Data.RoundData.ClientRoundDataUtility)
local Net = require(RS.Data.ClientServerCommunication)
local Fusion = require(RF.Vendor.Fusion)
local Mouse = require(RF.Utility.Mouse)
local RoundConfig = require(RS.Configuration.RoundConfiguration)
local Enums = require(RF.Enums)

-------------------------------------------------------------------
-- Fusion helpers
-------------------------------------------------------------------
local peek = Fusion.peek
local scope = Fusion.scoped(Fusion)

-------------------------------------------------------------------
-- runtime references
-------------------------------------------------------------------
local player = Players.LocalPlayer
local humanoid
local rootPart

-- gun parts (populated on character spawn)
local neonL
local neonR
local cageL -- LeftGunCage Part (hitbox)
local cageR -- RightGunCage Part (hitbox)

-------------------------------------------------------------------
-- derived Fusion states
-------------------------------------------------------------------
local parkourState = ClientState.actions.parkourState

local isShooting = scope:Computed(function(use)
	local pd = use(ClientState.external.roundData.playerData)[player.UserId]
	return pd and pd.actions.isShooting or false
end)

local isHacking = scope:Computed(function(use)
	local pd = use(ClientState.external.roundData.playerData)[player.UserId]
	return pd and pd.actions.isHacking or false
end)

local isGunEnabled = scope:Computed(function(use) return use(CRDU.isGunEnabled)[player.UserId] end)

-------------------------------------------------------------------
-- utilities
-------------------------------------------------------------------
local function isAnythingIntersectingGun(): boolean
	local overlapParams = OverlapParams.new()
	for _, part in ipairs(workspace:GetPartsInPart(cageL, overlapParams)) do
		if not part:IsDescendantOf(player.Character) then return true end
	end
	for _, part in ipairs(workspace:GetPartsInPart(cageR, overlapParams)) do
		if not part:IsDescendantOf(player.Character) then return true end
	end
	return false
end

local function getPlayerFromCharDescendant(descendant: Instance): Player?
	local player = Players:GetPlayerFromCharacter(descendant.Parent)
	if not player and descendant.Parent then player = Players:GetPlayerFromCharacter(descendant.Parent.Parent) end
	return player
end
-------------------------------------------------------------------
-- main shoot thread (dual‑ray version of legacy function)
-------------------------------------------------------------------
local thread
local function shootThread()
	while true do
		RunService.RenderStepped:Wait()

		-- make sure character & parts exist
		if not (rootPart and neonL and neonR and cageL and cageR) then continue end

		local mouseWorldPosition = Mouse.getWorldPosition(nil, { player.Character }, 256)

		-------------------------------------------------------------------
		-- build exclusion list (own character + every gun model)
		-------------------------------------------------------------------
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { player.Character }
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = true

		-------------------------------------------------------------------
		-- cast LEFT bullet
		-------------------------------------------------------------------
		--[[
		local directionL = (mouseWorldPosition - neonL.Position).Unit
		local resultL = workspace:Raycast(neonL.Position, directionL * 256, params)
		local hitPositionL = resultL and resultL.Position or mouseWorldPosition
		local victimL = (resultL and resultL.Instance) and getPlayerFromCharDescendant(resultL.Instance) or nil
		--]]
		-------------------------------------------------------------------
		-- cast RIGHT bullet
		-------------------------------------------------------------------
		local directionR = (mouseWorldPosition - neonR.Position).Unit
		local resultR = workspace:Raycast(neonR.Position, directionR * 256, params)
		local hitPositionR = resultR and resultR.Position or mouseWorldPosition
		local victimR = (resultR and resultR.Instance) and getPlayerFromCharDescendant(resultR.Instance) or nil

		-------------------------------------------------------------------
		-- replicate to server
		-------------------------------------------------------------------
		Net.replicateAsync("UpdateShootingStatus", {
			-- gunHitPositionL = hitPositionL,
			gunHitPositionR = hitPositionR,
		})

		-------------------------------------------------------------------
		-- gun collision check (stops shooting if barrels clipped)
		-------------------------------------------------------------------
		if isAnythingIntersectingGun() then
			local newData = peek(ClientState.external.roundData.playerData)
			local pd = newData[player.UserId]
			if pd then
				pd.gunHitPositionL = nil
				pd.gunHitPositionR = nil
				pd.victims = {}
				ClientState.external.roundData.playerData:set(newData)
			end
			continue
		end

		-------------------------------------------------------------------
		-- write results into Fusion roundData
		-------------------------------------------------------------------
		local newData = peek(ClientState.external.roundData.playerData)
		local pd = newData[player.UserId]
		if pd then
			-- pd.gunHitPositionL = hitPositionL
			pd.gunHitPositionR = hitPositionR

			-- victim bookkeeping (team‑safe)
			local function registerVictim(victim)
				if not victim then return end

				local victimPlayerData = newData[victim.UserId]

				if victimPlayerData and newData[victim.UserId].team ~= pd.team and victimPlayerData.status == Enums.PlayerStatus.alive then
					pd.victims[victim.UserId] = true
				end
			end
			-- registerVictim(victimL)
			registerVictim(victimR)
			ClientState.external.roundData.playerData:set(newData)
		end
	end
end

-------------------------------------------------------------------
-- character init / cleanup
-------------------------------------------------------------------
local function onCharacterAdded(char: Model)
humanoid = char:WaitForChild "Humanoid"
	rootPart = char:WaitForChild "HumanoidRootPart"

	neonL = char:WaitForChild "LeftGunNeon"
	neonR = char:WaitForChild "RightGunNeon"

	cageL = char:WaitForChild "LeftGunCage"
	cageR = char:WaitForChild "RightGunCage"
end

local function onCharacterRemoving()
	-- stop remote shooting flag
	local d = peek(ClientState.external.roundData.playerData)
	local pd = d[player.UserId]
	if pd then
		pd.actions.isShooting = false
		ClientState.external.roundData.playerData:set(d)
	end

	if thread then
		task.cancel(thread)
		thread = nil
	end

	humanoid, rootPart = nil, nil
	neonL, neonR, cageL, cageR = nil
end

player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(onCharacterRemoving)
if player.Character then onCharacterAdded(player.Character) end

-------------------------------------------------------------------
-- Fusion observers – start / stop shootThread
-------------------------------------------------------------------
local function updateShooting()
	if not humanoid then return end
	if peek(isShooting) and peek(isGunEnabled) then
		if not thread then thread = task.spawn(shootThread) end
	else
		if thread then
			task.cancel(thread)
			thread = nil
		end
		Net.replicateAsync "UpdateShootingStatus"
	end
end

scope:Observer(isShooting):onChange(updateShooting)
scope:Observer(isGunEnabled):onChange(updateShooting)

-------------------------------------------------------------------
-- input binding
-------------------------------------------------------------------
local function onShoot(_, state)
	if not humanoid then return end

	local data = peek(ClientState.external.roundData.playerData)

	if state == Enum.UserInputState.Begin then
		if state == Enum.UserInputState.Begin and peek(isHacking) or not peek(isGunEnabled) then return end

		data[player.UserId].actions.isShooting = true
	elseif state == Enum.UserInputState.End then
		data[player.UserId].actions.isShooting = false
	end

	ClientState.external.roundData.playerData:set(data)
end

scope:Observer(isGunEnabled):onChange(function()
	if peek(isGunEnabled) then
		CAS:BindActionAtPriority(
			"Shoot",
			onShoot,
			true,
			RoundConfig.controlPriorities.shootGun,
			Enum.UserInputType.MouseButton1
		)
	else
		CAS:UnbindAction "Shoot"
	end
end)

UIS.InputEnded:Connect(function(input)
	if peek(isGunEnabled) and input.UserInputType == Enum.UserInputType.MouseButton1 then
		onShoot(nil, Enum.UserInputState.End)
	end
end)
