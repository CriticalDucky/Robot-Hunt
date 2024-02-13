local AIM_ANIMATION = "rbxassetid://15940016280"

local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ContextActionService = game:GetService "ContextActionService"
local RunService = game:GetService "RunService"

local dataFolder = ReplicatedStorage:WaitForChild "Data"

local ClientState = require(dataFolder:WaitForChild "ClientState")
local ClientRoundDataUtility = require(dataFolder:WaitForChild("RoundData"):WaitForChild "ClientRoundDataUtility")
local ClientServerCommunication = require(dataFolder:WaitForChild "ClientServerCommunication")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Mouse = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Mouse")
local RoundConfiguration = require(ReplicatedStorage:WaitForChild("Configuration"):WaitForChild "RoundConfiguration")

local Observer = Fusion.Observer
local Hydrate = Fusion.Hydrate
local Out = Fusion.Out
local peek = Fusion.peek
local Value = Fusion.Value
local Computed = Fusion.Computed

local aimAnimation = Instance.new "Animation"
aimAnimation.AnimationId = AIM_ANIMATION

local player = Players.LocalPlayer
local trackAim: AnimationTrack?
local humanoid: Humanoid?
local humanoidRootPart: BasePart?
local gunTipAttachmentObjectValue: ObjectValue?
local hitboxObjectValue: ObjectValue?

local isCrawling = ClientState.actions.isCrawling

local isShooting = Computed(function(use)
	local playerData = use(ClientState.external.roundData.playerData)[player.UserId]

	return playerData and playerData.actions.isShooting or false
end)

local isHacking = Computed(function(use)
	local playerData = use(ClientState.external.roundData.playerData)[player.UserId]

	return playerData and playerData.actions.isHacking or false
end)

local isGunEnabled = Computed(function(use) return use(ClientRoundDataUtility.isGunEnabled)[player.UserId] end)

local thread: thread?

local function shootThread()
	while true do
		RunService.RenderStepped:Wait()

		local gunTipAttachment = gunTipAttachmentObjectValue and gunTipAttachmentObjectValue.Value
		local hitbox = hitboxObjectValue and hitboxObjectValue.Value

		local function isAnythingIntersectingGun(): boolean
			local overlapParams = OverlapParams.new()

			local intersectingParts = workspace:GetPartsInPart(hitbox, overlapParams)

			for _, part in ipairs(intersectingParts) do
				if not part:IsDescendantOf(player.Character) then return true end
			end

			return false
		end

		if humanoidRootPart and gunTipAttachment and hitbox then
			local direction, hitPosition, victim

			do
				local mouseWorldPosition = Mouse.getWorldPosition(nil, { player.Character }, 256)

				-- Make the humanoid root part look at the position (but make sure its only rotating on the Y axis)

				local lookVector = Vector3.new(mouseWorldPosition.X, humanoidRootPart.Position.Y, mouseWorldPosition.Z)

				humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, lookVector)

				direction = (mouseWorldPosition - gunTipAttachment.WorldPosition).Unit

				local guns = {}
				do
					for _, player in ipairs(Players:GetPlayers()) do
						local character = player.Character

						if character then
							local gun = character:FindFirstChild "Gun"

							if gun then table.insert(guns, gun) end
						end
					end
				end

				local params = RaycastParams.new()
				params.FilterDescendantsInstances = { player.Character, unpack(guns) }
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.IgnoreWater = true

				local raycastResult = workspace:Raycast(gunTipAttachment.WorldPosition, direction * 256, params)

				hitPosition = if raycastResult then raycastResult.Position else mouseWorldPosition

				victim = if raycastResult and raycastResult.Instance
					then Players:GetPlayerFromCharacter(raycastResult.Instance.Parent)
					else nil
			end

			ClientServerCommunication.replicateAsync("UpdateShootingStatus", { hitPosition = hitPosition })

			if isAnythingIntersectingGun() then
				local newPlayerData = peek(ClientState.external.roundData.playerData)

				local playerData = newPlayerData[player.UserId]

				if playerData then
					playerData.gunHitPosition = nil

					ClientState.external.roundData.playerData:set(newPlayerData)
				end

				continue
			end

			local newPlayerData = peek(ClientState.external.roundData.playerData)

			local playerData = newPlayerData[player.UserId]

			if playerData then
				playerData.gunHitPosition = hitPosition

				if victim and newPlayerData[victim.UserId] and newPlayerData[victim.UserId].team ~= playerData.team then
					playerData.victims[victim.UserId] = true
				else
					playerData.victims = {}
				end

				ClientState.external.roundData.playerData:set(newPlayerData)
			end
		end
	end
end

local function onCharacterAdded(character)
	humanoid = character:WaitForChild "Humanoid"
	humanoidRootPart = character:WaitForChild "HumanoidRootPart"

	local referencesFolder: Configuration = character:WaitForChild("Gun"):WaitForChild "References" :: Configuration

	gunTipAttachmentObjectValue = referencesFolder:WaitForChild "AttachmentTip" :: ObjectValue
	hitboxObjectValue = referencesFolder:WaitForChild "Hitbox" :: ObjectValue

	assert(humanoid and humanoid:IsA "Humanoid", "Object is not a humanoid")

	local animator: Instance | Animator = humanoid:WaitForChild "Animator"

	assert(animator:IsA "Animator", "Object is not an animator")

	trackAim = animator:LoadAnimation(aimAnimation)

	assert(trackAim, "Could not load aim animation")

	trackAim.Priority = Enum.AnimationPriority.Action
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then onCharacterAdded(player.Character) end

player.CharacterRemoving:Connect(function()
	local newPlayerData = peek(ClientState.external.roundData.playerData)
	local playerData = newPlayerData[player.UserId]

	if playerData then
		playerData.actions.isShooting = false

		ClientState.external.roundData.playerData:set(newPlayerData)
	end

	if not humanoid or not trackAim then return end

	assert(trackAim)

	trackAim:Stop()
	trackAim:Destroy()
	trackAim = nil

	humanoid = nil
	humanoidRootPart = nil

	gunTipAttachmentObjectValue = nil
	hitboxObjectValue = nil
end)

local function onShootingStatusChange()
	local isShooting = peek(isShooting)
	local isGunEnabled = peek(isGunEnabled)
	local isDead = not humanoid or not trackAim or not humanoidRootPart

	if not isShooting or not isGunEnabled then
		if thread then
			task.cancel(thread)
			thread = nil
		end

		local newPlayerData = peek(ClientState.external.roundData.playerData)

		local playerData = newPlayerData[player.UserId]

		if playerData then
			playerData.gunHitPosition = nil
			playerData.victims = {}

			ClientState.external.roundData.playerData:set(newPlayerData)
		end

		if not isDead and trackAim then trackAim:Stop() end

		ClientServerCommunication.replicateAsync "UpdateShootingStatus"
	else -- isShooting == true and isGunEnabled == true
		if isDead or not trackAim then return end

		assert(trackAim)

		trackAim:Play()

		if not thread then thread = task.spawn(shootThread) end
	end
end

-- connect all relevant states to the onShootingStatusChange function
Observer(isShooting):onChange(onShootingStatusChange)
Observer(isGunEnabled):onChange(onShootingStatusChange)

local function onShootRequest(_, inputState)
	if not humanoid or not trackAim or not humanoidRootPart then return end

	if peek(isHacking) or peek(isCrawling) or not peek(isGunEnabled) then return end

	local newPlayerData = peek(ClientState.external.roundData.playerData)
	local playerData = newPlayerData[player.UserId]

	if not playerData then return end

	if inputState == Enum.UserInputState.Begin then
		playerData.actions.isShooting = true
	elseif inputState == Enum.UserInputState.End then
		playerData.actions.isShooting = false
	end

	ClientState.external.roundData.playerData:set(newPlayerData)
end

Observer(isGunEnabled):onChange(function()
	local isGunEnabled = peek(isGunEnabled)

	if isGunEnabled then
		ContextActionService:BindActionAtPriority(
			"Shoot",
			onShootRequest,
			true,
			RoundConfiguration.controlPriorities.shootGun,
			Enum.UserInputType.MouseButton1
		)
	else
		ContextActionService:UnbindAction "Shoot"
	end
end)
