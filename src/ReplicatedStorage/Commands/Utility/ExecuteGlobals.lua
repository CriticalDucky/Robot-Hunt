local ExecuteGlobals = {}

function ExecuteGlobals.i(instanceName: string): Instance?
    return game:FindFirstChild(instanceName, true)
end

function ExecuteGlobals.m(moduleName: string): any?
    local module = ExecuteGlobals.i(moduleName)

    return if module and module:IsA("ModuleScript") then require(module) else nil
end

return ExecuteGlobals