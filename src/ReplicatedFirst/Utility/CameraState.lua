local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedFirstVendor = ReplicatedFirst:WaitForChild("Vendor")

local Fusion = require(replicatedFirstVendor:WaitForChild("Fusion"))
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate
local peek = Fusion.peek

local scope = Fusion.scoped(Fusion)

local watchingProps = {
    "CFrame",
    "ViewportSize",
}

local cameraState = scope:Value({}) :: Fusion.Value<{
    CFrame: CFrame?,
    ViewportSize: Vector2?,
}>

local function initCamera()
    local camera = workspace.CurrentCamera

    scope:Hydrate(camera){
        [OnEvent "Changed"] = function()
            local currentCameraState = peek(cameraState)

            for _, v in pairs(watchingProps) do
                currentCameraState[v] = camera[v]
            end

            cameraState:set(currentCameraState)
        end
    }

    cameraState:set({
        CFrame = camera.CFrame,
        ViewportSize = camera.ViewportSize,
    })
end

workspace.Changed:Connect(function(property)
    if property == "CurrentCamera" and workspace.CurrentCamera and workspace.CurrentCamera.Parent then
        initCamera()
    end
end)

if workspace.CurrentCamera then
    initCamera()
end

return cameraState