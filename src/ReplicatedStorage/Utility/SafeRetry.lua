local MAX_RETRIES = 10

--[[
	Attempts to call the callback, automatically retrying if it fails.

	---

	@param callback The function to call.
	@param ... The arguments to pass to the function.

	@return The success of the function call and either the function's results or the error that occurred.
]]
return function<T..., U...>(callback: (T...) -> U..., ...: T...): (boolean, U...)
	local results
	local tries = 0

	repeat
		results = { pcall(callback, ...) }
		tries += 1
	until results[1] or tries == MAX_RETRIES

	local success: boolean = results[1]

	table.remove(results, 1)

	return success, table.unpack(results)
end
