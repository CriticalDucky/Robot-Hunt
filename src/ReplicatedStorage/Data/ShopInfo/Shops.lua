local ReplicatedFirst = game:GetService "ReplicatedFirst"

local utilityFolder = ReplicatedFirst:WaitForChild "Utility"

local Time = require(utilityFolder:WaitForChild "Time")
local Enums = require(ReplicatedFirst:WaitForChild("Enums"))
local ItemCategory = Enums.ItemCategory
local CurrencyType = Enums.CurrencyType
local ItemTypeAccessory = Enums.ItemTypeAccessory

local timeRange = Time.newRange
local group = Time.newRangeGroup

return {
	items = {
		{ -- Test Item
			itemCategory = ItemCategory.accessory,
			item = ItemTypeAccessory.devAccessory,
			price = {
				type = CurrencyType.money,
				amount = 100,
			},
			sellingTime = group(timeRange({
				year = 2020,
				month = 1,
				day = 1,
				hour = 0,
				min = 0,
				sec = 0,
			}, {
				year = 2025,
				month = 1,
				day = 1,
				hour = 0,
				min = 0,
				sec = 0,
			})),
		},
	},
}
