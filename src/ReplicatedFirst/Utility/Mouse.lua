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

--[[ 
    Uses Mouse.getTarget to get the raycast result.
    Then, if the raycast result is nil, it returns the ray's origin + the ray's direction * 1000.
    Otherwise, it returns the raycast result's Position.
]]
function Mouse.getWorldPosition(whitelist, ignoreList): Vector3
    local raycastResult, ray = Mouse.getTarget(whitelist, ignoreList)

    if raycastResult then
        return raycastResult.Position
    else
        return ray.Origin + ray.Direction * 1000
    end
end

return Mouse