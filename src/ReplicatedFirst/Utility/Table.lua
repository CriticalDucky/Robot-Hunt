--!strict

local function tableToString(t: { [any]: any }, indent: number?, initialIndent: number?): string
	local textElements: { string } = {}

	table.insert(textElements, "{")

	for k, v in pairs(t) do
		if indent then
			table.insert(textElements, "\n")
			table.insert(textElements, (" "):rep(indent):rep((initialIndent or 0) + 1))
		else
			table.insert(textElements, " ")
		end

		if typeof(k) == "string" then
			table.insert(textElements, k)
		elseif typeof(k) == "number" then
			table.insert(textElements, ("[%s]"):format(tostring(k)))
		elseif typeof(k) == "table" then
			table.insert(textElements, "[table]")
		elseif typeof(k) == "Instance" then
			table.insert(textElements, ("[%s: %s]"):format(k.Name, k.ClassName))
		else
			table.insert(textElements, ("[%s: %s]"):format(tostring(k), typeof(k)))
		end

		table.insert(textElements, " = ")

		if typeof(v) == "string" then
			table.insert(textElements, ("%q"):format(v))
		elseif typeof(v) == "number" then
			table.insert(textElements, tostring(v))
		elseif typeof(v) == "table" then
			table.insert(textElements, tableToString(v, indent, if indent then (initialIndent or 0) + 1 else nil))
		elseif typeof(v) == "Instance" then
			table.insert(textElements, ("%s: %s"):format(v.Name, v.ClassName))
		else
			table.insert(textElements, ("%s: %s"):format(tostring(v), typeof(v)))
		end

		table.insert(textElements, ",")
	end

	if #textElements > 1 and not indent then
		table.remove(textElements)
	end

	if #textElements > 1 and indent then
		table.insert(textElements, "\n")
		table.insert(textElements, (" "):rep(indent):rep(initialIndent or 0))
	else
		table.insert(textElements, " ")
	end

	table.insert(textElements, "}")

	return table.concat(textElements)
end

local Table = {}

function Table.dictLen(dict) -- returns the length of a dictionary (table with no sequential keys)
	local count = 0

	for _ in pairs(dict) do
		count += 1
	end

	return count
end

function Table.deepCopy<T>(t: T): T -- returns a deep copy of a table
	if type(t) == "table" then
		local copy = {}

		for k, v in pairs(t) do
			copy[k] = Table.deepCopy(v)
		end

		return (copy :: any) :: T
	end

	return t
end

function Table.copy(t) -- returns a shallow copy of a table
	assert(type(t) == "table", "Table.copy: t must be a table")
	assert(t, "Table.copy: t must not be nil")

	local copy = {}

	for k, v in pairs(t) do
		copy[k] = v
	end

	return copy
end

function Table.hasValue(t, value) -- returns true if the table has the value
	for _, v in pairs(t) do
		if v == value then return true end
	end

	return false
end

function Table.findMax<T>(t: {[T]: number}) -- returns the key and value of the maximum value in a table
	local k, v

	for key, value in pairs(t) do
		if not k or value > v then
			k, v = key, value
		end
	end

	return k, v
end

function Table.findMin<T>(t: {[T]: number}) -- returns the key and value of the minimum value in a table
	local k, v

	for key, value in pairs(t) do
		if not k or value < v then
			k, v = key, value
		end
	end

	return k, v
end

function Table.toString(table: { [any]: any }, indent: number?)
	return tableToString(table, indent)
end

-- function Table.print(t, note, printTypes) -- takes a table and prints it to the console recursively with an optional note and printTypes flag
-- 	local MAX_PRINTS = 300
-- 	local prints = 0

-- 	local function printTable(t, indent)
-- 		if prints >= MAX_PRINTS then return end

-- 		for k, v in pairs(t) do
-- 			local baseString = (printTypes and " (%s)" or "")
-- 			local keyType = baseString:format(typeof(k))
-- 			local valueType = baseString:format(typeof(v))

-- 			if type(v) == "table" then
-- 				print(indent .. tostring(k) .. keyType .. ":")

-- 				prints += 1

-- 				printTable(v, indent .. "    ")
-- 			else
-- 				print(indent .. tostring(k) .. keyType .. " : " .. tostring(v) .. valueType)

-- 				prints += 1
-- 			end
-- 		end
-- 	end

-- 	print("Printing", note or tostring(t))

-- 	if type(t) == "table" then
-- 		printTable(t, "")
-- 	else
-- 		print(t)
-- 	end
-- end

function Table.merge(...) -- merges multiple tables into one, later tables overwrite earlier tables
	local merged = {}

	for _, t in { ... } do
		for k, v in pairs(t) do
			merged[k] = v
		end
	end

	return merged
end

function Table.arrayIntersection(t1, t2) -- returns an array of the values that are in both tables
	local intersection = {}

	for _, v in pairs(t1) do
		if Table.hasValue(t2, v) then
			table.insert(intersection, v)
		end
	end

	return intersection
end

function Table.compare(t1, t2) -- compares two tables recursively, returns true if they are the same
	if type(t1) ~= "table" or type(t2) ~= "table" then return t1 == t2 end

	for k, v in pairs(t1) do
		if not Table.compare(v, t2[k]) then return false end
	end

	for k, v in pairs(t2) do
		if not Table.compare(v, t1[k]) then return false end
	end

	return true
end

--[[
    Iterates through a table recursively, calling the callback with the path and value of each item:
    ```lua
    Table.recursiveIterate({a = {b = {c = 1}}}, function(path, value)
        print(path, value)
    end)
    ```
]]
function Table.recursiveIterate(t, callback)
	local function recursiveIterate(t1, path)
		for k, v in pairs(t1) do
			local newPath = Table.copy(path)
			table.insert(newPath, k)

			if type(v) == "table" then
				callback(Table.copy(newPath), v) -- Copy the path so it doesn't get modified by the callback
				recursiveIterate(v, newPath)
			else
				callback(Table.copy(newPath), v)
			end
		end
	end

	recursiveIterate(t, {})
end

-- function Table.findFirstKey(t, callback) -- returns the first key that passes the callback
-- 	for k, v in pairs(t) do
-- 		if not callback or callback(k, v) then return k, v end
-- 	end
-- 	return
-- end

function Table.hasAnything(t) -- returns true if the table has anything in it
	for _, _ in pairs(t) do
		return true
	end

	return false
end

function Table.deepReconcile(template, t) -- reconciles t with template, adding any missing values from template to t
	local function deepReconcile(t1, t2)
		for k, v in pairs(t1) do
			if type(v) == "table" then
				if type(t2[k]) ~= "table" then
					t2[k] = Table.deepCopy(v)
				else
					deepReconcile(v, t2[k])
				end
			else
				if t2[k] == nil then t2[k] = v end
			end
		end
	end

	deepReconcile(template, t)
end

-- function Table.safeIndex(t, ...) -- safely indexes a table using a path, returns nil if normally would error
-- 	local value = t

-- 	for _, key in pairs { ... } do
-- 		if type(value) == "table" then
-- 			value = value[key]
-- 		else
-- 			return nil
-- 		end
-- 	end

-- 	return value
-- end

-- function Table.deepToNumber(t, copy) -- converts all values to numbers if possible
-- 	t = if copy then Table.deepCopy(t) else t

-- 	local function deepToNumber(t1)
-- 		for k, v in pairs(t1) do
-- 			if type(v) == "table" then
-- 				deepToNumber(v)
-- 			else
-- 				t1[k] = tonumber(v) or v
-- 			end
-- 		end
-- 	end

-- 	deepToNumber(t)

-- 	return t
-- end

-- function Table.deepToNumberKeys(t, copy): { [any]: any } -- converts all string keys to numbers if possible
-- 	t = if copy then Table.deepCopy(t) else t

-- 	local function deepToNumberKeys(t1)
-- 		for k, v in pairs(Table.copy(t1)) do
-- 			if type(v) == "table" then deepToNumberKeys(v) end

-- 			if type(k) == "string" then
-- 				local numberKey = tonumber(k)

-- 				if numberKey then
-- 					t1[numberKey] = v
-- 					t1[k] = nil
-- 				end
-- 			end
-- 		end
-- 	end

-- 	deepToNumberKeys(t)

-- 	return t
-- end

function Table.selectWithKeys(t, keys) -- takes in an array of keys and returns a table with only those keys
	local selected = {}

	for _, key in pairs(keys) do
		selected[key] = t[key]
	end

	return selected
end

function Table.indexOf(t, value) -- returns the index of the value in the table, or nil if it doesn't exist
	for i, v in pairs(t) do
		if v == value then return i end
	end

	return nil
end

function Table.callAll(t, ...) -- calls all functions in the table with the given arguments
	for _, v in pairs(t) do
		if type(v) == "function" then v(...) end
	end
end

function Table.append(...) -- appends multiple tables together in order. If a value in the tuple is not a table, it is ignored
	local appended = {}

	for _, t in pairs { ... } do
		if type(t) == "table" then
			for _, v in pairs(t) do
				table.insert(appended, v)
			end
		end
	end

	return appended
end

function Table.setProps(object, props) -- sets the properties of an object to the values in the table
	for k, v in pairs(props) do
		object[k] = v
	end
end

function Table.build(length, callback) -- builds a table with the given length, calling the callback with the index and returning the value
	local t = {}

	for i = 1, length do
		t[i] = callback(i)
	end

	return t
end

function Table.map(t, callback) -- maps a table to a new table using the callback
	local mapped = {}

	for k, v in pairs(t) do
		mapped[k] = callback(k, v)
	end

	return mapped
end

function Table.editValues(t, callback) -- maps a table to a new table using the callback, only passing the value
	local mapped = {}

	for k, v in pairs(t) do
		mapped[k] = callback(v)
	end

	return mapped
end

function Table.deepFreeze(t)
	local function deepFreeze(t1)
		for _, v in pairs(t1) do
			if type(v) == "table" then deepFreeze(v) end
		end

		table.freeze(t1)
	end

	deepFreeze(t)

	return t
end

return Table
