local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Enums = require(ReplicatedFirst:WaitForChild("Enums"))
local RoundType = Enums.RoundType

local Rounds = {}

Rounds[RoundType.defaultRound] = require(script.DefaultRound)

return Rounds