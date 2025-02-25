local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local GameLoop = ServerStorage.GameLoop

local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Enums = require(ReplicatedFirst.Enums)

local Results = {}

function Results.begin()
    print("Results started")
    
    local resultsLength = RoundConfiguration.timeLengths.lobby[Enums.PhaseType.Results]
    local endTime = os.time() + resultsLength

    local timer = Actions.newPhaseTimer(endTime)

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Results cancelled")
            timer:cancel()
        end)

        timer:andThen(function()
            print("Results ended")
            resolve()
        end)

        RoundDataManager.setPhase(Enums.PhaseType.Results, endTime)
    end)
end

return Results