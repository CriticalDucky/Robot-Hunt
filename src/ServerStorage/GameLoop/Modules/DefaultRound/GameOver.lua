local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local GameLoop = ServerStorage.GameLoop

local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Enums = require(ReplicatedFirst.Enums)

local GameOver = {}

function GameOver.begin()
    print("Game Over started")
    
    local gameoverLength = RoundConfiguration.timeLengths[Enums.RoundType.defaultRound][Enums.PhaseType.GameOver]
    local endTime = os.time() + gameoverLength

    local timer = Actions.newPhaseTimer(endTime)

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Game Over cancelled")
            timer:cancel()
        end)

        timer:andThen(function()
            print("Game Over ended")
            resolve()
        end)

        RoundDataManager.setPhase(Enums.PhaseType.GameOver, endTime)
    end)
end

return GameOver