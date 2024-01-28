local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Promise = require(ReplicatedFirst.Vendor.Promise)

return function(endTime)
    return Promise.new(function(resolve, reject, onCancel)
        local connection

        connection = game:GetService("RunService").Stepped:Connect(function()
            if os.time() >= endTime then
                connection:Disconnect()

                resolve()
            end
        end)

        onCancel(function()
            connection:Disconnect()
        end)
    end)
end