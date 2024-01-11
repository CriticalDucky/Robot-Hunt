local AIM_ANIMATION = "rbxassetid://15940016280"

local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ContextActionService = game:GetService "ContextActionService"
local RunService = game:GetService "RunService"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Mouse = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Mouse")

local Observer = Fusion.Observer
local Hydrate = Fusion.Hydrate
local Out = Fusion.Out
local peek = Fusion.peek
local Value = Fusion.Value
local Computed = Fusion.Computed

local isShooting = ClientState.actions.isShooting
local isCrawling = ClientState.actions.isCrawling
local isHacking = ClientState.actions.isHacking

local aimAnimation = Instance.new "Animation"
aimAnimation.AnimationId = AIM_ANIMATION

local player = Players.LocalPlayer
local trackAim: AnimationTrack?
local humanoid: Humanoid?
local humanoidRootPart: BasePart?

local thread: thread?

local function shootThread()
    while true do
        RunService.RenderStepped:Wait()

        if humanoidRootPart then
            local raycastResult, ray = Mouse.getTarget(nil, {player.Character})

            -- Make the humanoid root part look at the raycast result (but make sure its only rotating on the Y axis)

            local lookVector do
                if not raycastResult then
                    local mousePosition = ray.Origin + ray.Direction * 250

                    lookVector = Vector3.new(
                        mousePosition.X,
                        humanoidRootPart.Position.Y,
                        mousePosition.Z
                    )
                else
                    lookVector = Vector3.new(
                        raycastResult.Position.X,
                        humanoidRootPart.Position.Y,
                        raycastResult.Position.Z
                    )
                end
            end
            

            humanoidRootPart.CFrame = CFrame.lookAt(
                humanoidRootPart.Position,
                lookVector
            )
        end

        print("shooting")
    end
end

local function onCharacterAdded(character)
    humanoid = character:WaitForChild "Humanoid"
    humanoidRootPart = character:WaitForChild "HumanoidRootPart"

    assert(humanoid and humanoid:IsA("Humanoid"), "Object is not a humanoid")

    local animator: Instance | Animator = humanoid:WaitForChild "Animator"

    assert(animator:IsA("Animator"), "Object is not an animator")

    trackAim = animator:LoadAnimation(aimAnimation)

    assert(trackAim, "Could not load aim animation")

    trackAim.Priority = Enum.AnimationPriority.Action
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterRemoving:Connect(function()
    isShooting:set(false)

    if not humanoid or not trackAim then
        return
    end

    trackAim:Stop()
    trackAim:Destroy()
    trackAim = nil

    humanoid = nil
    humanoidRootPart = nil
end)

local function onShootingStatusChange()
    local isShooting = peek(isShooting)
    local isDead = not humanoid or not trackAim or not humanoidRootPart

    if not isShooting then
        if thread then
            task.cancel(thread)
            thread = nil
        end

        if not isDead and trackAim then
            trackAim:Stop()
        end
    else -- isShooting == true
        if isDead or not trackAim then
            return
        end

        trackAim:Play()

        if not thread then
            thread = task.spawn(shootThread)
        end
    end 
end

Observer(isShooting):onChange(onShootingStatusChange)

local function onShootRequest(_, inputState)
    if not humanoid or not trackAim or not humanoidRootPart then
        return
    end

    if peek(isHacking) or peek(isCrawling) then
        return
    end

    if inputState == Enum.UserInputState.Begin then
        isShooting:set(true)
    elseif inputState == Enum.UserInputState.End then
        isShooting:set(false) 
    end
end

ContextActionService:BindAction("Shoot", onShootRequest, true, Enum.UserInputType.MouseButton1)