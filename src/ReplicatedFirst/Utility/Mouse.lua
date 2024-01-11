local UserInputService = game:GetService("UserInputService")

local Mouse = {}

function Mouse.getTarget(whitelist, ignoreList)
    local screenPosition = UserInputService:GetMouseLocation()
    local currentCamera = workspace.CurrentCamera

    assert(currentCamera, "Mouse.getTarget() requires a camera to be present in the workspace")

    local ray = currentCamera:ViewportPointToRay(screenPosition.X, screenPosition.Y, 1000)

    local rayCastParams = RaycastParams.new()

    if whitelist then
        rayCastParams.FilterType = Enum.RaycastFilterType.Include
        rayCastParams.FilterDescendantsInstances = whitelist
    elseif ignoreList then
        rayCastParams.FilterType = Enum.RaycastFilterType.Exclude
        rayCastParams.FilterDescendantsInstances = ignoreList
    end

    return workspace:Raycast(currentCamera.CFrame.Position, ray.Direction * 1000, rayCastParams), ray
end

--#region Testing

-- local smallGreenSphere do
--     local sphere = Instance.new("Part")
--     sphere.Shape = Enum.PartType.Ball
--     sphere.Size = Vector3.new(0.4, 0.4, 0.4)
--     sphere.Color = Color3.new(0, 1, 0)
--     sphere.Anchored = true
--     sphere.Material = Enum.Material.Neon
--     sphere.CanCollide = false
--     sphere.CanTouch = false
--     sphere.CanQuery = false
--     sphere.Parent = game.Workspace
--     smallGreenSphere = sphere
-- end

-- RunService.RenderStepped:Connect(function()
--     local targetInfo = Mouse.getTarget()
--     if targetInfo then
--         smallGreenSphere.CFrame = CFrame.lookAt(targetInfo.Position, targetInfo.Position + targetInfo.Normal) + targetInfo.Normal
--     else
--         print("No target")
--     end
-- end)

-- print("Mouse script is loaded")

--#endregion

return Mouse