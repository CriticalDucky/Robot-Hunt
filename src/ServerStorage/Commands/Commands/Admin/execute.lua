local SCRIPT = [[
    local i
    local m

    do
        local ReplicatedStorage = game:GetService "ReplicatedStorage"

        local ExecuteGlobals = require(
            ReplicatedStorage
                :WaitForChild("Commands")
                :WaitForChild("Utility")
                :WaitForChild "ExecuteGlobals"
        )

        i = ExecuteGlobals.i
        m = ExecuteGlobals.m
    end

    %s
]]

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local loadstring = require(ReplicatedStorage:WaitForChild("Vendor"):WaitForChild "Loadstring")

return {
	Name = "execute",
	Aliases = {},
	Description = "Execute Lua 5.1 code on either the client or server.",
	Group = "DefaultAdmin",
	Args = {
		{
			Type = "string",
			Name = "runContext",
			Description = "'Client' or 'Server': where to run the command",
			Optional = false,
			Default = "Client",
		},

		{
			Type = "string",
			Name = "command",
			Description = "The command to run",
			Optional = false,
			Default = "print('Hello, world!')",
		},
	},
	ClientRun = function(context, runContext, command)
		local function replyError(message) context:Reply(message, Color3.new(1, 0.188235, 0.188235)) end

		if string.lower(runContext) == "client" then
			local executable, failureReason = loadstring(SCRIPT:format(command))

			if not failureReason then
				local success, err = pcall(executable)

				if not success then replyError(err) end
			else
				replyError(failureReason)
			end

			return ""
		else
			return
		end
	end,
}
