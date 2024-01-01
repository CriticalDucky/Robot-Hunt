local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)

local PhaseTwo = {}

function PhaseTwo.begin()
    print("Phase Two started")

    local timer = Promise.delay(RoundConfiguration.defaultRound.phaseTwoLength)

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Phase Two cancelled")
        end)

        timer:andThen(function()
            print("Phase Two ended")
            resolve()
        end)
    end)
end

return PhaseTwo