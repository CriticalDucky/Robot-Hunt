--[[ 
    ItemCollector Module
    Tracks and caches parts with specific qualities in specified Instance hierarchies.
]]

local RunService = game:GetService("RunService")

local ItemCollector = {}

-- Private variables
local activeBinders = {} -- {qualityId = {ancestor = Instance, check = function, parts = {Instance}, monitored = {Instance}}}
local connections = {} -- {qualityId = {added = RBXScriptConnection, removing = RBXScriptConnection, heartbeat = RBXScriptConnection}}

-- Utility functions
local function defaultCheckFunction(part: Instance): (boolean, boolean?)
    return part:IsA("BasePart"), false
end

type QualityCheck = (part: Instance) -> (boolean, boolean?)
type QualityId = string

-- Main functions

--[[
    Binds a quality check to an ancestor Instance to track its descendants.

    @param qualityId string -- Unique identifier for this quality binding
    @param ancestor Instance -- The root Instance to search for qualifying descendants
    @param checkFunction? (part: Instance) -> (boolean, boolean?) -- Optional function to determine if a part qualifies. If the second boolean is true, the part will be monitored for changes.
]]
function ItemCollector:BindQuality(qualityId: QualityId, ancestor: Instance, checkFunction: QualityCheck?)
    if activeBinders[qualityId] then
        warn(string.format("Quality %s is already bound!", qualityId))
        return
    end

    -- Initialize binder data
    local check = checkFunction or defaultCheckFunction
    activeBinders[qualityId] = {
        ancestor = ancestor,
        check = check,
        parts = {},
        monitored = {},
    }

	local function checkDescendant(descendant: Instance)
		local qualifies, shouldMonitor = check(descendant)
        if qualifies then 
            table.insert(activeBinders[qualityId].parts, descendant)
		end
        if shouldMonitor then
            activeBinders[qualityId].monitored[descendant] = true
        end
	end

    -- Perform initial collection
    for _, descendant in ipairs(ancestor:GetDescendants()) do
        checkDescendant(descendant)
    end

    -- Set up descendant added/removing connections
    connections[qualityId] = {
        added = ancestor.DescendantAdded:Connect(function(descendant)
            checkDescendant(descendant)
        end),
        removing = ancestor.DescendantRemoving:Connect(function(descendant)
            local parts = activeBinders[qualityId].parts
            for i, part in ipairs(parts) do
                if part == descendant then
                    table.remove(parts, i)
                    break
                end
            end
            activeBinders[qualityId].monitored[descendant] = nil
        end),
    }

    -- Set up heartbeat for monitored objects
    connections[qualityId].heartbeat = RunService.Heartbeat:Connect(function()
        local binder = activeBinders[qualityId]
        if not binder then return end
        
        for obj in pairs(binder.monitored) do
            local qualifies = binder.check(obj)
            if qualifies then
                binder.monitored[obj] = nil
                table.insert(binder.parts, obj)
            end
        end
    end)

    if ancestor ~= workspace then
        connections[qualityId].destroyed = ancestor.Destroying:Connect(function()
            self:UnbindQuality(qualityId)
        end)
    end
end

--[[
    Unbinds a previously bound quality and cleans up its connections.
    
    @param qualityId string -- The identifier of the quality binding to remove
    
    ```lua
    ItemCollector:UnbindQuality("AnchordParts")
    ```
]]
function ItemCollector:UnbindQuality(qualityId: QualityId)
    if not activeBinders[qualityId] then
        warn(string.format("Quality %s is not bound!", qualityId))
        return
    end

    -- Disconnect events
    if connections[qualityId] then
        for _, connection in pairs(connections[qualityId]) do
            connection:Disconnect()
        end
        connections[qualityId] = nil
    end

    -- Clear data
    activeBinders[qualityId] = nil
end

--[[
    Returns a copy of all parts that currently match the specified quality.
    
    @param qualityId string -- The identifier of the quality binding
    @return {Instance} -- Array of Instances that match the quality
    @error If the quality is not bound
    
    ```lua
    local anchordParts = ItemCollector:GetPartsWithQuality("AnchordParts")
    for _, part in ipairs(anchordParts) do
        print(part.Name, "is anchored")
    end
    ```
]]
function ItemCollector:GetPartsWithQuality(qualityId: QualityId): { Instance }
	assert(activeBinders[qualityId], string.format("Cannot get parts: Quality %s is not bound!", qualityId))

	return table.clone(activeBinders[qualityId].parts)
end

--[[
    Checks if a quality ID is currently bound.
    
    @param qualityId string -- The identifier to check
    @return boolean -- True if the quality is bound, false otherwise
    
    ```lua
    if ItemCollector:IsQualityBound("AnchordParts") then
        print("Anchored parts are being tracked")
    end
    ```
]]
function ItemCollector:IsQualityBound(qualityId: QualityId): boolean return activeBinders[qualityId] ~= nil end

--[[
    Cleans up all quality bindings and their connections.
    Should be called when the module is no longer needed.
    
    ```lua
    -- When done with the collector
    ItemCollector:Destroy()
    ```
]]
function ItemCollector:Destroy()
	for qualityId in pairs(activeBinders) do
		self:UnbindQuality(qualityId)
	end
end

-- Return the module
return ItemCollector