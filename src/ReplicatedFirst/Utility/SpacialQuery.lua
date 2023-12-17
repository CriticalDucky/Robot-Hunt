local COLLISION_PADDING = 0.02

local queryPart = Instance.new("Part")
queryPart.Size = Vector3.new(COLLISION_PADDING, COLLISION_PADDING, COLLISION_PADDING)
queryPart.Anchored = true

local function setUpQueryPart(cframe, size)
    queryPart.CFrame = cframe
    queryPart.Size = size
end

local function putAwayQueryPart()
    queryPart.CFrame = CFrame.new(0, -1000, 0)
end

local SpacialQuery = {}

function SpacialQuery.getPartsTouchingPoint(point)
    local cframe = if typeof(point) == "CFrame" then point else CFrame.new(point)

    setUpQueryPart(cframe, Vector3.new(COLLISION_PADDING, COLLISION_PADDING, COLLISION_PADDING))

    local parts = workspace:GetPartsInPart(queryPart)

    putAwayQueryPart()

    return parts
end

return SpacialQuery