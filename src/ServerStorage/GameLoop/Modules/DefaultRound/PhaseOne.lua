local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local GameLoop = ServerStorage.GameLoop

local Actions = require(GameLoop.Actions)
local RoundData = require(GameLoop.RoundData)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Enums = require(ReplicatedFirst.Enums)

local PhaseOne = {}

function PhaseOne.begin()
    print("Phase One started")
    RoundData.data.currentPhaseType = Enums.PhaseType.PhaseOne
    RoundData.data.phaseStartTime = os.time()
    Actions.replicateRoundData()

    local timer = Promise.delay(RoundConfiguration.timeLengths[Enums.RoundType.defaultRound][Enums.PhaseType.PhaseOne])

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Phase One cancelled")
            timer:cancel()
        end)

        timer:andThen(function()
            print("Phase One ended")
            resolve()
        end)
    end)
end

return PhaseOne