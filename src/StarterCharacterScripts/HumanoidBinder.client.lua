local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local utilityFolder = ReplicatedFirst:WaitForChild("Utility")

local Platform = require(utilityFolder:WaitForChild("Platform"))
local Enums = require(ReplicatedFirst:WaitForChild("Enums"))
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild("Fusion"))
local scope = Fusion:scoped()
local peek = Fusion.peek

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("ClientState"))
local ClientRoundDataUtility = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("RoundData"):WaitForChild("ClientRoundDataUtility"))

local humanoid = script.Parent:WaitForChild("Humanoid")

local cameraOffeset = scope:Computed(function(use)
    local platform = use(Platform.platform)
    -- local isGunEnabled = use(ClientRoundDataUtility.isGunEnabled)[Players.LocalPlayer.UserId]
    local playerData = use(ClientState.external.roundData.playerData)[Players.LocalPlayer.UserId]
    if not playerData then
        return Vector3.new(0, 0, 0)
    end

    if platform == Enums.PlatformType.Mobile and playerData.actions.isShooting then
        return Vector3.new(2, 1, 0)
    else
        return Vector3.new(0, 0, 0)
    end
end)

scope:Hydrate(humanoid) {
    CameraOffset = scope:Spring(cameraOffeset, 25, 1),
    AutoRotate = scope:Computed(function(use)
        local platform = use(Platform.platform)
        local playerData = use(ClientState.external.roundData.playerData)[Players.LocalPlayer.UserId]
        if not playerData then
            return true
        end

        if platform == Enums.PlatformType.Mobile and playerData.actions.isShooting then
            return false
        else
            return true
        end
    end),
}

script.Destroying:Connect(function()
    scope:doCleanup()
end)