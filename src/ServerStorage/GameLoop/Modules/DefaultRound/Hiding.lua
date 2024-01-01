local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)

local Hiding = {}

function Hiding.begin()
    print("Hiding started")

    local timer = Promise.delay(RoundConfiguration.defaultRound.hidingTime)

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Hiding cancelled")
            timer:cancel()
        end)

        timer:andThen(function()
            print("Hiding ended")
            resolve()
        end)
    end)
end

return Hiding