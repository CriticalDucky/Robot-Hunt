local ServerStorage = game:GetService("ServerStorage")

local function mergeDictionary(d1, d2)
    for k, v in pairs(d2) do
        if type(v) == "table" then
            d1[k] = mergeDictionary(d1[k] or {}, v)
        else
            d1[k] = v
        end
    end

    return d1
end

local activeShops = {}

for _, descendant in pairs(ServerStorage:GetDescendants()) do
    if descendant.Name == "ActiveShop" and descendant:IsA("ModuleScript") then
        mergeDictionary(activeShops, require(descendant))
    end
end

return activeShops