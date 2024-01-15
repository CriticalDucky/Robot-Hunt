local AIM_ANIMATION = "rbxassetid://15940016280"

local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ContextActionService = game:GetService "ContextActionService"
local RunService = game:GetService "RunService"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Mouse = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Mouse")

local Observer = Fusion.Observer
local Hydrate = Fusion.Hydrate
local Out = Fusion.Out
local peek = Fusion.peek
local Value = Fusion.Value
local Computed = Fusion.Computed

local isShooting = ClientState.actions.isShooting
local isCrawling = ClientState.actions.isCrawling
local isHacking = ClientState.actions.isHacking

local aimAnimation = Instance.new "Animation"
aimAnimation.AnimationId = AIM_ANIMATION

local player = Players.LocalPlayer
local trackAim: AnimationTrack?
local humanoid: Humanoid?
local humanoidRootPart: BasePart?
local gunTipAttachmentObjectValue: ObjectValue?
local hitboxObjectValue: ObjectValue?

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
				if part:IsDescendantOf(player.Character) then continue end

				return true
			end

			return false
		end

		if humanoidRootPart and gunTipAttachment and hitbox then
			local direction, hitPosition

			do
				local mouseWorldPosition = Mouse.getWorldPosition(nil, { player.Character }, 256)

				-- Make the humanoid root part look at the position (but make sure its only rotating on the Y axis)

				local lookVector = Vector3.new(mouseWorldPosition.X, humanoidRootPart.Position.Y, mouseWorldPosition.Z)

				humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, lookVector)

				if isAnythingIntersectingGun() then
					ClientState.actions.gunHitPosition:set(nil)

					continue
				end

				direction = (mouseWorldPosition - gunTipAttachment.WorldPosition).Unit

				local params = RaycastParams.new()
				params.FilterDescendantsInstances = { player.Character }
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.IgnoreWater = true

				local raycastResult = workspace:Raycast(gunTipAttachment.WorldPosition, direction * 256, params)

				hitPosition = if raycastResult then raycastResult.Position else mouseWorldPosition
			end

			ClientState.actions.gunHitPosition:set(hitPosition)

			-- TODO: Replicate to server
		end
	end
end

local function onCharacterAdded(character)
	humanoid = character:WaitForChild "Humanoid"
	humanoidRootPart = character:WaitForChild "HumanoidRootPart"

	local referencesFolder: Configuration = character:WaitForChild("Gun"):WaitForChild("References") :: Configuration

	gunTipAttachmentObjectValue = referencesFolder:WaitForChild("AttachmentTip") :: ObjectValue
	hitboxObjectValue = referencesFolder:WaitForChild("Hitbox") :: ObjectValue

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
	isShooting:set(false)

	if not humanoid or not trackAim then return end

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
	local isDead = not humanoid or not trackAim or not humanoidRootPart

	if not isShooting then
		if thread then
			task.cancel(thread)
			thread = nil
		end

		local newPlayerData = peek(ClientState.external.roundData.playerData)

		if newPlayerData[player.UserId] then
			local gunData = newPlayerData[player.UserId] and newPlayerData[player.UserId].gunData or {}

			gunData.hitPosition = nil

			ClientState.external.roundData.playerData:set(newPlayerData)
		end

		if not isDead and trackAim then trackAim:Stop() end
	else -- isShooting == true
		if isDead or not trackAim then return end

		trackAim:Play()

		if not thread then thread = task.spawn(shootThread) end
	end
end

Observer(isShooting):onChange(onShootingStatusChange)

local function onShootRequest(_, inputState)
	if not humanoid or not trackAim or not humanoidRootPart then return end

	if peek(isHacking) or peek(isCrawling) then return end

	if inputState == Enum.UserInputState.Begin then
		isShooting:set(true)
	elseif inputState == Enum.UserInputState.End then
		isShooting:set(false)
	end
end

ContextActionService:BindAction("Shoot", onShootRequest, true, Enum.UserInputType.MouseButton1)
