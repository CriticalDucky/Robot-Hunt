local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local GameLoop = ServerStorage.GameLoop

local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Enums = require(ReplicatedFirst.Enums)

local PhaseTwo = {}

function PhaseTwo.begin()
    print("Phase Two started")
    RoundDataManager.data.currentPhaseType = Enums.PhaseType.PhaseTwo
    RoundDataManager.data.phaseStartTime = os.time()
    Actions.replicateRoundData()

    local timer = Promise.delay(RoundConfiguration.timeLengths[Enums.RoundType.defaultRound][Enums.PhaseType.PhaseTwo])

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Phase Two cancelled")
            timer:cancel()
        end)

        timer:andThen(function()
            print("Phase Two ended")
            resolve()
        end)
    end)
end

return PhaseTwo