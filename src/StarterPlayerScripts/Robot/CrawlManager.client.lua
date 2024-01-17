local CRAWL_ANIMATION = "rbxassetid://15921580019"
local IDLE_ANIMATION = "rbxassetid://15921994824"

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

local isCrawling = ClientState.actions.isCrawling

local crawlAnimation = Instance.new "Animation"
crawlAnimation.AnimationId = CRAWL_ANIMATION

local idleAnimation = Instance.new "Animation"
idleAnimation.AnimationId = IDLE_ANIMATION

local player = Players.LocalPlayer
local trackCrawl: AnimationTrack?
local trackIdle: AnimationTrack?
local humanoid: Humanoid?
local humanoidRootPart: BasePart?
local humanoidMoveDirection = Value()

local isMoving = Computed(function(Use)
    return Use(humanoidMoveDirection) and Use(humanoidMoveDirection).Magnitude > 0
end)

local state = Computed(function(Use)
    local isMoving = Use(isMoving)
    local isCrawling = Use(isCrawling)

    if isCrawling and not isMoving then
        return "idle_crawl"
    elseif isCrawling and isMoving then
        return "crawl"
    else
        return "stand"
    end
end)

local function onCharacterAdded(character)
    isCrawling:set(false)

    humanoid = character:WaitForChild "Humanoid"
    humanoidRootPart = character:WaitForChild "HumanoidRootPart"

    assert(humanoid and humanoid:IsA("Humanoid"), "Object is not a humanoid")

    local animator: Instance | Animator = humanoid:WaitForChild "Animator"

    assert(animator:IsA("Animator"), "Object is not an animator")

    trackCrawl = animator:LoadAnimation(crawlAnimation)
    trackIdle = animator:LoadAnimation(idleAnimation)

    assert(trackCrawl and trackIdle, "Failed to load animations")

    trackCrawl.Priority = Enum.AnimationPriority.Action
    trackIdle.Priority = Enum.AnimationPriority.Action

    Hydrate(humanoid) {
        [Out "MoveDirection"] = humanoidMoveDirection
    }
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterRemoving:Connect(function()
    isCrawling:set(false)

    if not humanoid or not trackCrawl or not trackIdle then
        return
    end

    assert(trackCrawl and trackIdle)

    trackCrawl:Stop()
    trackIdle:Stop()

    trackCrawl:Destroy()
    trackIdle:Destroy()

    trackCrawl = nil
    trackIdle = nil

    humanoid = nil
    humanoidRootPart = nil

    humanoidMoveDirection:set(nil)
end)

local function onCrawlingStatusChange()
    if not humanoid or not trackCrawl or not trackIdle or not humanoidRootPart then
        return
    end

    assert(trackCrawl and trackIdle and humanoidRootPart)

    local state = peek(state)

    if state == "crawl" then
        trackCrawl:Play()
        trackIdle:Stop()

        humanoidRootPart.CanCollide = false
    elseif state == "idle_crawl" then
        trackCrawl:Stop()
        trackIdle:Play()

        humanoidRootPart.CanCollide = false
    else
        trackCrawl:Stop()
        trackIdle:Stop()
    end
end

Observer(state):onChange(onCrawlingStatusChange)

local function onCrawlRequest(_, inputState)
    if not humanoid or not trackCrawl or not trackIdle then
        return
    end

    local playerDatas = peek(ClientState.external.roundData.playerData)
    local playerData = playerDatas[player.UserId]

    if playerData and playerData.actions.isHacking then
        return
    end

    if inputState == Enum.UserInputState.Begin then
        isCrawling:set(true)

        if playerData then
            playerData.actions.isShooting = false

            ClientState.external.roundData.playerData:set(playerDatas)
        end
    elseif inputState == Enum.UserInputState.End then
        isCrawling:set(false)
    end
end

ContextActionService:BindAction("Crawl", onCrawlRequest, true, Enum.KeyCode.LeftShift)