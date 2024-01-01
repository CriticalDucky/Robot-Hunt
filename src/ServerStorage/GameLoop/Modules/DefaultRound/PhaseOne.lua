local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)

local PhaseOne = {}

function PhaseOne.begin()
    print("Phase One started")

    local timer = Promise.delay(RoundConfiguration.defaultRound.phaseOneLength)

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Phase One cancelled")
        end)

        timer:andThen(function()
            print("Phase One ended")
            resolve()
        end)
    end)
end

return PhaseOne