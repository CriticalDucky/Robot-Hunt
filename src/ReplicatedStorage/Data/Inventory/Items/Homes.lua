local ReplicatedFirst = game:GetService("ReplicatedFirst")

local enumsFolder = ReplicatedFirst.Shared.Enums

local homeTypeEnum = require(enumsFolder.ItemTypeHome)
local Model = require(ReplicatedFirst.Shared.Utility.Model)
local ModelType = require(enumsFolder.ModelType)

local function model(name)
	return Model(ModelType.home, name)
end

return {
	[homeTypeEnum.developerHome] = {
		name = "Developer Home",
		model = model "DevHome",
	},
}
