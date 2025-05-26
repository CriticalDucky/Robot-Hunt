LIFESUPPORT_POSE1_ID = "rbxassetid://120745871314035"

local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local DataFolder = ReplicatedStorage:WaitForChild "Data"

local ClientState = require(DataFolder:WaitForChild "ClientState")
local RoundConfiguration = require(ReplicatedStorage:WaitForChild("Configuration"):WaitForChild "RoundConfiguration")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Enums = require(ReplicatedFirst:WaitForChild "Enums")
local IK = require(ReplicatedStorage:WaitForChild("Utility"):WaitForChild "IK")

local peek = Fusion.peek
local scope = Fusion.scoped(Fusion)

local localPlayer = Players.LocalPlayer

local playerState = scope:Computed(function(use)
	local playerData = use(ClientState.external.roundData.playerData)[localPlayer.UserId]

	if not playerData then return end

	return playerData.status
end)

local isLobby = scope:Computed(function(use)
	local playerData = use(ClientState.external.roundData.playerData)[localPlayer.UserId]

	if not playerData then return true end

	return playerData.isLobby
end)

local characterScope
local isLifeSupportPlaying = false

local function onCharacterAdded(character)
	if characterScope then characterScope:doCleanup() end

	characterScope = scope:deriveScope()

	table.insert(characterScope, function()
		IK.SetLookAround(true)
	end)

	local humanoid = character:WaitForChild "Humanoid" :: Humanoid
	local humanoidRootPart = character:WaitForChild "HumanoidRootPart"
    local anim = Instance.new("Animation")
    anim.AnimationId = LIFESUPPORT_POSE1_ID

	assert(humanoid and humanoid:IsA "Humanoid", "Object is not a humanoid")

	local animator: Instance | Animator = humanoid:WaitForChild "Animator"

	assert(animator:IsA "Animator", "Object is not an animator")

	local track = animator:LoadAnimation(anim)

	assert(track, "Failed to load animation")

	track.Priority = Enum.AnimationPriority.Action4

	local function onStateChanged()
		local currentPlayerState = peek(playerState)

		if currentPlayerState == Enums.PlayerStatus.alive or peek(isLobby) then
            if not isLifeSupportPlaying then return end
            isLifeSupportPlaying = false
			track:Stop(0.2)
            humanoid.WalkSpeed = RoundConfiguration.walkSpeed
            humanoid.JumpPower = RoundConfiguration.jumpPower
            humanoidRootPart.Anchored = false
			IK.SetLookAround(true)
        elseif currentPlayerState == Enums.PlayerStatus.lifeSupport then
            if isLifeSupportPlaying then return end
            isLifeSupportPlaying = true
			track:Play(0.2)
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoidRootPart.Anchored = true
			IK.SetLookAround(false)
		end
	end

	characterScope:Observer(playerState):onChange(onStateChanged)
	characterScope:Observer(isLobby):onChange(onStateChanged)
end

if localPlayer.Character then onCharacterAdded(localPlayer.Character) end
localPlayer.CharacterAdded:Connect(onCharacterAdded)
