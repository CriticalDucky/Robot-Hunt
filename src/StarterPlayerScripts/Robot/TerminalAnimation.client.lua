local HACK_ANIMATION = "rbxassetid://121741743565097"

local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local scope = Fusion.scoped(Fusion)

local peek = Fusion.peek

local player = Players.LocalPlayer

local isHacking = scope:Computed(function(use)
	local playerData = use(ClientState.external.roundData.playerData)[player.UserId]

	return playerData and playerData.actions.isHacking or false
end)

local hackAnimation = Instance.new "Animation"
hackAnimation.AnimationId = HACK_ANIMATION

local trackHack: AnimationTrack?
local humanoid: Humanoid?
local humanoidRootPart: BasePart?

local function onCharacterAdded(character)
    humanoid = character:WaitForChild "Humanoid"
    humanoidRootPart = character:WaitForChild "HumanoidRootPart"

    assert(humanoid and humanoid:IsA("Humanoid"), "Object is not a humanoid")

    local animator: Instance | Animator = humanoid:WaitForChild "Animator"

    assert(animator:IsA("Animator"), "Object is not an animator")

    trackHack = animator:LoadAnimation(hackAnimation)

    assert(trackHack, "Failed to load animations")

    trackHack.Priority = Enum.AnimationPriority.Action
    trackHack.Looped = true
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterRemoving:Connect(function()
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

scope:Observer(isHacking):onChange(onHackingStatusChange)