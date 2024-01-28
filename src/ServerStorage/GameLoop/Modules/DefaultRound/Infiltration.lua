local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local GameLoop = ServerStorage.GameLoop

local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Enums = require(ReplicatedFirst.Enums)

local Infiltration = {}

function Infiltration.begin()
    print("Infiltration started")
    
    local infiltrationLength = RoundConfiguration.timeLengths[Enums.RoundType.defaultRound][Enums.PhaseType.Infiltration]
    local endTime = os.time() + infiltrationLength

    local timer = Actions.newPhaseTimer(endTime)

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Infiltration cancelled")
            timer:cancel()
        end)

        timer:andThen(function()
            print("Infiltration ended")
            resolve()
        end)

        RoundDataManager.setPhase(Enums.PhaseType.Infiltration, endTime)
    end)
end

return Infiltration