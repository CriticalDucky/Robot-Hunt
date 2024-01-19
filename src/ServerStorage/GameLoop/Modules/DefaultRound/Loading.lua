local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local GameLoop = ServerStorage.GameLoop

local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Enums = require(ReplicatedFirst.Enums)

local Loading = {}

function Loading.begin()
    print("Loading started")

    local loadingLength = RoundConfiguration.timeLengths.lobby[Enums.PhaseType.Loading]

    local timer = Promise.delay(loadingLength)

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Loading cancelled")
            timer:cancel()
        end)

        timer:andThen(function()
            print("Loading ended")
            resolve()
        end)

        RoundDataManager.setPhaseToLoadingAsync(loadingLength)
    end)
end

return Loading