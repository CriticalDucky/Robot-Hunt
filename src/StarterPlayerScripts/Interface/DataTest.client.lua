--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"

local RoundConfiguration = require(ReplicatedStorage:WaitForChild("Configuration"):WaitForChild("RoundConfiguration"))
local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("ClientState"))
local Enums = require(ReplicatedFirst:WaitForChild("Enums"))

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local peek = Fusion.peek

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild "PlayerGui"

local RoundType = Enums.RoundType
local PhaseType = Enums.PhaseType

local roundData = ClientState.external.roundData

local timeState = Value(os.time())

task.spawn(function()
    while true do
        timeState:set(os.time())
        RunService.RenderStepped:Wait()
    end
end)

local currentRoundType = Computed(function(use)
    local data = use(roundData)

    if not data then
        return nil
    end

    return data.currentRoundType
end)

local currentPhaseType = Computed(function(use)
    local data = use(roundData)

    if not data then
        return nil
    end

    return data.currentPhaseType
end)

local phaseStartTime = Computed(function(use)
    local data = use(roundData)

    if not data then
        return nil
    end

    return data.phaseStartTime
end)

local phaseLength = Computed(function(use)
    local currentRoundType = use(currentRoundType)
    local currentPhaseType = use(currentPhaseType)

    if not currentPhaseType then
        return 0
    end

    if currentRoundType then
        return RoundConfiguration.timeLengths[currentRoundType][currentPhaseType]
    else
        return RoundConfiguration.timeLengths.lobby[currentPhaseType] or 0
    end
end)

local phaseTimeRemaining = Computed(function(use)
    local phaseStartTime = use(phaseStartTime)

    if not phaseStartTime then
        return 0
    end

    local phaseLength = use(phaseLength)

    return phaseStartTime + phaseLength - use(timeState)
end)

local textComputed = Computed(function(use)
    local currentPhaseType = use(currentPhaseType)
    local phaseTimeRemaining = use(phaseTimeRemaining)

    if not currentPhaseType or not phaseTimeRemaining then
        return "Loading..."
    end

    return ("%s: %s"):format(currentPhaseType, phaseTimeRemaining)
end)

New "ScreenGui" {
    Parent = playerGui;

    [Children] = {
        New "TextLabel" {
            Name = "PhaseAndTimeRemaining";
            Text = textComputed;
            Size = UDim2.new(1, 20, 0, 0);
        }
    }
}