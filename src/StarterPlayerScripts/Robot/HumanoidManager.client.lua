local NORMAL_SPEED = 16
local SPEED_BOOST = 3
local CRAWL_SPEED = 7
local JUMP_HEIGHT = 9

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Hydrate = Fusion.Hydrate
local Computed = Fusion.Computed
local Spring = Fusion.Spring

local isCrawling = ClientState.actions.isCrawling

local player = Players.LocalPlayer

local speedBoost = Computed(function()
    return false -- TODO: update this with the client state
end)

local cameraOffset = Spring(Computed(function(Use)
    if Use(isCrawling) then
        return Vector3.new(0, -3, 0)
    else
        return Vector3.new(0, 0, 0)
    end
end), 25, 1)

local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")

    Hydrate(humanoid) {
        WalkSpeed = Computed(function(use)
            local isCrawling = use(isCrawling)
            local isSpeedBoosted = use(speedBoost)
    
            local base_speed = if isCrawling then CRAWL_SPEED else NORMAL_SPEED
    
            return base_speed + if isSpeedBoosted then SPEED_BOOST else 0
        end),
        JumpHeight = Computed(function(use)
            local isCrawling = use(isCrawling)
    
            return if isCrawling then 0 else JUMP_HEIGHT
        end),
        CameraOffset = cameraOffset
    }
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end