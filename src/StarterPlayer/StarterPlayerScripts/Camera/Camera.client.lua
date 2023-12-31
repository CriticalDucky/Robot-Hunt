local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

player.CharacterAdded:Connect(function()
    character = player.Character
end)

local UNIT_VECTOR = Vector3.new(1, 1.2, 1).Unit
local DISTANCE = 100
local FOV = 20

RunService.Heartbeat:Connect(function(deltaTime)
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Scriptable

        if character and character.Parent then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local position = humanoidRootPart.Position + UNIT_VECTOR * DISTANCE + Vector3.new(0, 1.5, 0)
                camera.CFrame = CFrame.lookAt(position, humanoidRootPart.Position)
                camera.FieldOfView = FOV
            end
        end
    end
end)

