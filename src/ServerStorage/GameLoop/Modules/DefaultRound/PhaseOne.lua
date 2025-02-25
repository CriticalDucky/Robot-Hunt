local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local GameLoop = ServerStorage.GameLoop

local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Enums = require(ReplicatedFirst.Enums)

local PhaseOne = {}

function PhaseOne.begin()
    print("Phase One started")
    
    local intermissionLength = RoundConfiguration.timeLengths[Enums.RoundType.defaultRound][Enums.PhaseType.PhaseOne]
    local endTime = os.time() + intermissionLength

    local timer = Actions.newPhaseTimer(endTime)

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Phase One cancelled")
            timer:cancel()
        end)

        timer:andThen(function()
            print("Phase One ended")
            resolve()
        end)

        RoundDataManager.setPhase(Enums.PhaseType.PhaseOne, endTime)
    end)
end

return PhaseOne