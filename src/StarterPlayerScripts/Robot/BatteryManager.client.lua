local BATTERY_ANIMATION = "rbxassetid://16082327113"

local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ContextActionService = game:GetService "ContextActionService"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Observer = Fusion.Observer
local Hydrate = Fusion.Hydrate
local Out = Fusion.Out
local peek = Fusion.peek
local Value = Fusion.Value
local Computed = Fusion.Computed

local player = Players.LocalPlayer

local isCrawling = ClientState.actions.isCrawling

local isShooting = Computed(function(use)
	local playerData = use(ClientState.external.roundData.playerData)[player.UserId]

	return playerData and playerData.actions.isShooting or false
end)

local isHacking = Computed(function(use)
	local playerData = use(ClientState.external.roundData.playerData)[player.UserId]

	return playerData and playerData.actions.isHacking or false
end)

local isHoldingBattery = ClientState.actions.tempIsHoldingBattery

local function changeHoldingBatteryState(state)
    -- local playerData = peek(ClientState.external.roundData.playerData)[player.UserId]

    -- if not playerData then
    --     return
    -- end

    -- playerData.actions.isHoldingBattery = state

    -- ClientState.external.roundData.playerData:set(playerData)

    isHoldingBattery:set(state)
end

local batteryAnimation = Instance.new "Animation"
batteryAnimation.AnimationId = BATTERY_ANIMATION

local trackBattery: AnimationTrack?
local humanoid: Humanoid?
local humanoidRootPart: BasePart?

local function onCharacterAdded(character)
    humanoid = character:WaitForChild "Humanoid"
    humanoidRootPart = character:WaitForChild "HumanoidRootPart"

    assert(humanoid and humanoid:IsA("Humanoid"), "Object is not a humanoid")

    local animator: Instance | Animator = humanoid:WaitForChild "Animator"

    assert(animator:IsA("Animator"), "Object is not an animator")

    trackBattery = animator:LoadAnimation(batteryAnimation)

    assert(trackBattery, "Failed to load animation")

    trackBattery.Priority = Enum.AnimationPriority.Action2

    local batteryModel = character:WaitForChild "Battery"
    local body = batteryModel:WaitForChild "Body"
    local neon = batteryModel:WaitForChild "Neon"

    body:WaitForChild ("ProximityPrompt"):Destroy()

    for _, part in {body, neon} do
        Hydrate(part) {
            Transparency = Computed(function(use)
                local isHoldingBattery = use(isHoldingBattery)

                return if isHoldingBattery then 0 else 1
            end),
            Massless = true,
            CanCollide = false,
            CanQuery = false,
        }
    end
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterRemoving:Connect(function()
    changeHoldingBatteryState(false)

    if not humanoid or not trackBattery then
        return
    end

    assert(trackBattery)

    trackBattery:Stop()
    trackBattery:Destroy()

    trackBattery = nil

    humanoid = nil
    humanoidRootPart = nil
end)

local function onBatteryStatusChange()
    if not humanoid or not trackBattery or not humanoidRootPart then
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

Observer(isHoldingBattery):onChange(onBatteryStatusChange)

while task.wait(5) do
    changeHoldingBatteryState(not peek(isHoldingBattery))
end

-- local function onBatteryRequest(_, inputState)
--     if not humanoid or not trackBattery then
--         return
--     end

--     local playerDatas = peek(ClientState.external.roundData.playerData)
--     local playerData = playerDatas[player.UserId]

--     if playerData and playerData.actions.isHacking then
--         return
--     end

--     if inputState == Enum.UserInputState.Begin then
--         isCrawling:set(true)

--         if playerData then
--             playerData.actions.isShooting = false

--             ClientState.external.roundData.playerData:set(playerDatas)
--         end
--     elseif inputState == Enum.UserInputState.End then
--         isCrawling:set(false)
--     end
-- end

-- ContextActionService:BindAction("Crawl", onBatteryRequest, true, Enum.KeyCode.LeftShift)