local BATTERY_ANIMATION = "rbxassetid://16082327113"

local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ContextActionService = game:GetService "ContextActionService"

local DataFolder = ReplicatedStorage:WaitForChild "Data"

local ClientState = require(DataFolder:WaitForChild "ClientState")
local ClientServerCommunication = require(DataFolder:WaitForChild "ClientServerCommunication")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Observer = Fusion.Observer
local Hydrate = Fusion.Hydrate
local peek = Fusion.peek
local Computed = Fusion.Computed

local localPlayer = Players.LocalPlayer

local isHoldingBattery = Computed(function(use)
	local batteryData = use(ClientState.external.roundData.batteryData)

	for _, data in pairs(batteryData) do
		if data.holder == localPlayer.UserId then return true end
	end

	return false
end)

local isCrawling = ClientState.actions.isCrawling

local batteryAnimation = Instance.new "Animation"
batteryAnimation.AnimationId = BATTERY_ANIMATION

local trackBattery: AnimationTrack?
local humanoid: Humanoid?
local humanoidRootPart: BasePart?

local function onCharacterAdded(player: Player, character)
	if player == localPlayer then
		humanoid = character:WaitForChild "Humanoid"
		humanoidRootPart = character:WaitForChild "HumanoidRootPart"

		assert(humanoid and humanoid:IsA "Humanoid", "Object is not a humanoid")

		local animator: Instance | Animator = humanoid:WaitForChild "Animator"

		assert(animator:IsA "Animator", "Object is not an animator")

		trackBattery = animator:LoadAnimation(batteryAnimation)

		assert(trackBattery, "Failed to load animation")

		trackBattery.Priority = Enum.AnimationPriority.Action2
	end

	local batteryModel = character:WaitForChild "Battery"
	local body = batteryModel:WaitForChild "Body"
	local neon = batteryModel:WaitForChild "Neon"

	body:WaitForChild("Battery"):Destroy()

	for _, part in { body, neon } do
		Hydrate(part) {
			Transparency = Computed(function(use)
				local batteryDatas = use(ClientState.external.roundData.batteryData)

				for _, batterData in pairs(batteryDatas) do
					if batterData.holder == player.UserId then return 0 end
				end

				return 1
			end),
			Massless = true,
			CanCollide = false,
			CanQuery = false,
		}
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character) onCharacterAdded(player, character) end)

	if player.Character then onCharacterAdded(player, player.Character) end
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in pairs(Players:GetPlayers()) do onPlayerAdded(player) end

localPlayer.CharacterRemoving:Connect(function()
	if not humanoid or not trackBattery then return end

	assert(trackBattery)

	trackBattery:Stop()
	trackBattery:Destroy()

	trackBattery = nil

	humanoid = nil
	humanoidRootPart = nil
end)

local function onBatteryStatusChange()
	if not humanoid or not trackBattery or not humanoidRootPart then
		print("Humanoid or trackBattery or humanoidRootPart is nil", humanoid, trackBattery, humanoidRootPart)

		return
	end

	assert(trackBattery and humanoidRootPart)

	local isHoldingBattery = peek(isHoldingBattery)

	if isHoldingBattery then
		trackBattery:Play()
	else
		trackBattery:Stop()
	end
end

local function onPutDownRequest(_, state)
	-- print("PutDownBattery", state)

	if state == Enum.UserInputState.End then
		ClientServerCommunication.replicateAsync "PutDownBattery"
	end
end

Observer(isHoldingBattery):onChange(onBatteryStatusChange)
Observer(isCrawling):onChange(function()
	ClientServerCommunication.replicateAsync "PutDownBattery"
end)

ClientServerCommunication.registerActionAsync "PutDownBattery"

ContextActionService:BindAction(
	"PutDownBattery",
	onPutDownRequest,
	false,
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.Touch
)
