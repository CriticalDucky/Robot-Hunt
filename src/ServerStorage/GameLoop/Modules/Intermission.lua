local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)

local Intermission = {}

function Intermission.begin()
    print("Intermission started")

    local timer = Promise.delay(RoundConfiguration.intermissionLength)

    return Promise.new(function(resolve, reject, onCancel)
        onCancel(function()
            print("Intermission cancelled")
        end)

        timer:andThen(function()
            print("Intermission ended")
            resolve()
        end)
    end)
end

return Intermission