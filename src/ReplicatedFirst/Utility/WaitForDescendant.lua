local function waitForDescendant (descendantOf, identifier)
	local idType = typeof(identifier)

	assert(typeof(descendantOf) == "Instance", "Invalid type for argument 1 (descendatOf)")
	assert(idType == "string" or idType == "function", "Invalid type for argument 2 (identifier)")

	local TIMEOUT = 10

	if idType == "string" and descendantOf:FindFirstChild(identifier, true) then
		return descendantOf:FindFirstChild(identifier, true)
	elseif idType == "function" then
		for _, descendant in ipairs(descendantOf:GetDescendants()) do
			if identifier(descendant) then -- that was the bug lol
				return descendant
			end
		end

		return
	else
		local object

		task.spawn(function()
			task.wait(TIMEOUT)

			if not object then
				warn("Infinite yield possible on "..tostring(descendantOf)..":WaitForDescendant("..tostring(identifier).."). Traceback:", debug.traceback())
			end
		end)

		repeat
			local descendant = descendantOf.DescendantAdded:Wait()

			if idType == "string" then
				object = if descendant.Name == identifier then descendant else nil
			else -- strType == "function"
				object = if identifier(descendant) then descendant else nil
			end
		until object

		return object
	end
end

_G.waitForDescendant = waitForDescendant

return waitForDescendant