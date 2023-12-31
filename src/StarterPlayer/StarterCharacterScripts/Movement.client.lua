local MOVE_ACTION_NAME = "clickToMove"
local WALKABLE_TAG = "Walkable"
local UNWALKABLE_TAG = "Unwalkable"
local MAX_PATH_LENGTH = 100

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicatedFirstUtility = replicatedFirstShared:WaitForChild("Utility")
local sharedFolder = script.Parent

local Mouse = require(replicatedFirstUtility:WaitForChild("Mouse"))

local character = sharedFolder.Parent
local humanoid: Humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local path = PathfindingService:CreatePath{
        AgentRadius = 3,
        AgentCanClimb = true,
}

local movementEnabled = false
local moveIndex = 0

local function getPathLength(waypoints)
    local length = 0

    for i = 1, #waypoints - 1 do
        local start = waypoints[i].Position
        local endPoint = waypoints[i + 1].Position
        length += (start - endPoint).magnitude
    end

    return length
end

local function move(waypoints)
    local currentMoveIndex = moveIndex

    for i, waypoint in ipairs(waypoints) do
        if i == 1 then
            continue
        end

        local waypointPosition = waypoint.Position

        humanoid:MoveTo(waypointPosition)
        humanoid.MoveToFinished:Wait()

        if currentMoveIndex ~= moveIndex then
            return
        end
    end
end

local function onClickAction(action, state, input)
    if action == MOVE_ACTION_NAME then
        if state == Enum.UserInputState.Begin then
            -- print("Begin")
            movementEnabled = true
        elseif state == Enum.UserInputState.End then
            -- print("End")
            movementEnabled = false
        end
    end
end

local renderConnection, destroyingConnection do
    local pathRendering = false

    renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
        if movementEnabled and not pathRendering then
            local walkableParts = CollectionService:GetTagged(WALKABLE_TAG)
            local unwalkableParts = CollectionService:GetTagged(UNWALKABLE_TAG)

            local whitelist do
                whitelist = {}

                for _, part in pairs(walkableParts) do
                    table.insert(whitelist, part)
                end

                for _, part in pairs(unwalkableParts) do
                    table.insert(whitelist, part)
                end
            end

            local mouseTargetInfo = Mouse.getTarget(whitelist)

            if mouseTargetInfo then
                if table.find(walkableParts, mouseTargetInfo.Instance) then
                    pathRendering = true

                    local success = pcall(function()
                        path:ComputeAsync(rootPart.CFrame.Position, mouseTargetInfo.Position)
                    end)

                    pathRendering = false

                    if success and path.Status == Enum.PathStatus.Success then
                        moveIndex += 1

                        local waypoints = path:GetWaypoints()

                        if getPathLength(waypoints) <= MAX_PATH_LENGTH then
                            move(waypoints)
                        else
                            humanoid:MoveTo(mouseTargetInfo.Position)
                        end
                    end
                elseif table.find(unwalkableParts, mouseTargetInfo.Instance) then
                    moveIndex += 1

                    humanoid:MoveTo(mouseTargetInfo.Position)
                end


            end
        end
    end)

    destroyingConnection = character.Destroying:Connect(function()
        renderConnection:Disconnect()
        destroyingConnection:Disconnect()
    end)
end

ContextActionService:BindAction(MOVE_ACTION_NAME, onClickAction, false, Enum.UserInputType.MouseButton1)
