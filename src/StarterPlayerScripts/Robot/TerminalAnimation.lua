local HACK_ANIMATION = "rbxassetid://16357555206"

local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Observer = Fusion.Observer
local peek = Fusion.peek
local Computed = Fusion.Computed

local player = Players.LocalPlayer

local isHacking = Computed(function(use)
	local playerData = use(ClientState.external.roundData.playerData)[player.UserId]

	return playerData and playerData.actions.isHacking or false
end)

local hackAnimation = Instance.new "Animation"
hackAnimation.AnimationId = HACK_ANIMATION

local trackHack: AnimationTrack?
local humanoid: Humanoid?
local humanoidRootPart: BasePart?

local function onCharacterAdded(character)
    isHacking:set(false)

    humanoid = character:WaitForChild "Humanoid"
    humanoidRootPart = character:WaitForChild "HumanoidRootPart"

    assert(humanoid and humanoid:IsA("Humanoid"), "Object is not a humanoid")

    local animator: Instance | Animator = humanoid:WaitForChild "Animator"

    assert(animator:IsA("Animator"), "Object is not an animator")

    trackHack = animator:LoadAnimation(hackAnimation)

    assert(trackHack, "Failed to load animations")

    trackHack.Priority = Enum.AnimationPriority.Action
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterRemoving:Connect(function()
    isHacking:set(false)

    if not humanoid or not trackHack then
        return
    end

    assert(trackHack)

    trackHack:Stop()
    trackHack:Destroy()
    trackHack = nil

    humanoid = nil
    humanoidRootPart = nil
end)

local function onHackingStatusChange()
    if not humanoid or not trackHack or not humanoidRootPart then
        return
    end

    assert(trackHack and humanoidRootPart)

    local state = peek(isHacking)

    if state then
        trackHack:Play()
    else
        trackHack:Stop()
    end
end

Observer(isHacking):onChange(onHackingStatusChange)