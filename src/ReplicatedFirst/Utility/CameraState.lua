local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedFirstVendor = ReplicatedFirst:WaitForChild("Vendor")

local Fusion = require(replicatedFirstVendor:WaitForChild("Fusion"))
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate
local peek = Fusion.peek

local cameraState = Value({})

local watchingProps = {
    "CFrame",
    "ViewportSize",
}

local function initCamera()
    local camera = workspace.CurrentCamera

    Hydrate(camera){
        [OnEvent "Changed"] = function()
            local currentCameraState = peek(cameraState)

            for _, v in pairs(watchingProps) do
                currentCameraState[v] = camera[v]
            end

            cameraState:set(currentCameraState)
        end
    }
end

workspace.Changed:Connect(function(property)
    if property == "CurrentCamera" and workspace.CurrentCamera and workspace.CurrentCamera.Parent then
        initCamera()
    end
end)

return cameraState