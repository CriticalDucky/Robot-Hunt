local CHAR_LIST = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
local ID_LENGTH = 4

--#region Character Array Setup

local characters = {}

for i = 1, CHAR_LIST:len() do
	characters[i] = CHAR_LIST:sub(i, i)
end

--#endregion

local Id = {}

--[[
	Generates a random ID.

	---

	Given IDs should not be assumed to be universally unique. The `exclude` parameter is an optional set of IDs to
	exclude from possible results. It must contain the IDs as keys, with the values being any truthy value.
]]
function Id.generate(exclude: {[string]: any}?): string
	local id

	repeat
		id = {}

		for _ = 1, ID_LENGTH do
			table.insert(id, characters[math.random(1, #characters)])
		end

		id = table.concat(id)
	until not exclude or not exclude[id]

	return id
end

return Id
