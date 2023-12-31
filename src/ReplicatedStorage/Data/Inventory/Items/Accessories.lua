local ReplicatedFirst = game:GetService "ReplicatedFirst"

local Enums = require(ReplicatedFirst:WaitForChild "Enums")

local ItemTypeAccessory = Enums.ItemTypeAccessory

return {
	[ItemTypeAccessory.devAccessory] = {
		name = "Hat",
	},
}
