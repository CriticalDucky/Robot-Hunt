local RunService = game:GetService("RunService")

local function getModel(modelType, name)
    local model

    local function iterate(_, object)
        if object:IsA("Folder") and object.Name == "Models" then
            for _, descendant in ipairs(object:GetDescendants()) do
                if descendant.Name == name and descendant:FindFirstAncestor(modelType) then
                    model = descendant
                    break
                end
            end
        end
    end

    for i, v in game:GetService("ReplicatedStorage"):GetDescendants() do
        iterate(i, v)
    end

    for i, v in game:GetService("ReplicatedFirst"):GetDescendants() do
        iterate(i, v)
    end

    if RunService:IsServer() then
        for i, v in game:GetService("ServerStorage"):GetDescendants() do
            iterate(i, v)
        end
    end

    return model
end

return getModel