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

    local intermissionLength = RoundConfiguration.timeLengths.lobby[Enums.PhaseType.Intermission]
    local endTime = os.time() + intermissionLength

    local timer = Actions.newPhaseTimer(endTime)

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Intermission cancelled")
            timer:cancel()
        end)

        timer:andThen(function()
            print("Intermission ended")
            resolve()
        end)

        RoundDataManager.setPhase(Enums.PhaseType.Intermission, endTime)
    end)
end

return Intermission