local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local GameLoop = ServerStorage.GameLoop

local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Enums = require(ReplicatedFirst.Enums)

local Intermission = {}

function Intermission.begin()
    print("Intermission started")
    RoundDataManager.data.currentPhaseType = Enums.PhaseType.Intermission
    RoundDataManager.data.phaseStartTime = os.time()
    RoundDataManager.replicateDataAsync()

    local timer = Promise.delay(RoundConfiguration.timeLengths.lobby[Enums.PhaseType.Intermission])

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Intermission cancelled")
            timer:cancel()
        end)

        timer:andThen(function()
            print("Intermission ended")
            resolve()
        end)
    end)
end

return Intermission