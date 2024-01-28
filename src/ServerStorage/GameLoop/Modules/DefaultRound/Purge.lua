local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local GameLoop = ServerStorage.GameLoop

local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Enums = require(ReplicatedFirst.Enums)

local Purge = {}

function Purge.begin()
    print("Purge started")
    
    local purgeLength = RoundConfiguration.timeLengths[Enums.RoundType.defaultRound][Enums.PhaseType.Purge]
    local endTime = os.time() + purgeLength

    local timer = Actions.newPhaseTimer(endTime)

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Purge cancelled")
            timer:cancel()
        end)

        timer:andThen(function()
            print("Purge ended")
            resolve()
        end)

        RoundDataManager.setPhase(Enums.PhaseType.Purge, endTime)
    end)
end

return Purge