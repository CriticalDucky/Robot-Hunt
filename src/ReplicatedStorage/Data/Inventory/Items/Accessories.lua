local ReplicatedFirst = game:GetService "ReplicatedFirst"

local enumsFolder = ReplicatedFirst.Shared.Enums

local AccessoryTypeEnum = require(enumsFolder.AccessoryType)

return {
	[AccessoryTypeEnum.hat_var1] = {
		name = "Hat",
	},

	[AccessoryTypeEnum.hat_var2] = {
		name = "Hat",
	},
}
