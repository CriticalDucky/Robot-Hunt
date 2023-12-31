local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Types = require(ReplicatedFirst.Shared.Utility.Types)

type ItemCategory = Types.ItemCategory
type InventoryItem = Types.InventoryItem

local Items = {
	furniture = require(script:WaitForChild "Furniture"),
	accessory = require(script:WaitForChild "Accessories"),
	home = require(script:WaitForChild "Homes"),
}

--[[
    Returns an item from the given item category and item enum
]]
function Items.getItem(itemCategory, itemEnum): InventoryItem
	return Items[itemCategory] and Items[itemCategory][itemEnum]
end

return Items
