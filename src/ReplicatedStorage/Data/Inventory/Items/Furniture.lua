local ReplicatedFirst = game:GetService "ReplicatedFirst"

local enumsFolder = ReplicatedFirst.Shared.Enums

local FurnitureType = require(enumsFolder.FurnitureType)
local Model = require(ReplicatedFirst.Shared.Utility.Model)
local ModelType = require(enumsFolder.ModelType)

local function model(name)
	return Model(ModelType.furniture, name)
end

return {
	[FurnitureType.beachBall] = {
		name = "Beach Ball",
		model = model "BeachBall",
	},
}