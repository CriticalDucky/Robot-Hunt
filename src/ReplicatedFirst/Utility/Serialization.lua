
local Serialize = {}

function Serialize.Vector3(vector3)
    return {
        x = vector3.X,
        y = vector3.Y,
        z = vector3.Z,
        _tag = "Vector3",
    }
end

function Serialize.CFrame(cframe: CFrame)
    local components = table.pack(cframe:GetComponents())

    return {
        x = components[1],
        y = components[2],
        z = components[3],
        r00 = components[4],
        r01 = components[5],
        r02 = components[6],
        r10 = components[7],
        r11 = components[8],
        r12 = components[9],
        r20 = components[10],
        r21 = components[11],
        r22 = components[12],
        _tag = "CFrame",
    }
end

function Serialize.Color3(color3)
    return {
        r = color3.R,
        g = color3.G,
        b = color3.B,
        _tag = "Color3",
    }
end

function Serialize.ColorSequence(colorSequence)
    local colorSequenceKeypoints = {}
    for _, colorSequenceKeypoint in ipairs(colorSequence.Keypoints) do
        table.insert(colorSequenceKeypoints, {
            time = colorSequenceKeypoint.Time,
            color = Serialize.Color3(colorSequenceKeypoint.Value),
        })
    end
    return {
        keypoints = colorSequenceKeypoints,
        _tag = "ColorSequence",
    }
end

function Serialize.NumberSequence(numberSequence)
    local numberSequenceKeypoints = {}
    for _, numberSequenceKeypoint in ipairs(numberSequence.Keypoints) do
        table.insert(numberSequenceKeypoints, {
            time = numberSequenceKeypoint.Time,
            value = numberSequenceKeypoint.Value,
        })
    end
    return {
        keypoints = numberSequenceKeypoints,
        _tag = "NumberSequence",
    }
end

function Serialize.NumberRange(numberRange)
    return {
        min = numberRange.Min,
        max = numberRange.Max,
        _tag = "NumberRange",
    }
end

function Serialize.Rect(rect)
    return {
        min = Serialize.Vector2(rect.Min),
        max = Serialize.Vector2(rect.Max),
        _tag = "Rect",
    }
end

function Serialize.Vector2(vector2)
    return {
        x = vector2.X,
        y = vector2.Y,
        _tag = "Vector2",
    }
end

function Serialize.UDim(udim)
    return {
        scale = udim.Scale,
        offset = udim.Offset,
        _tag = "UDim",
    }
end

function Serialize.UDim2(udim2)
    return {
        x = Serialize.UDim(udim2.X),
        y = Serialize.UDim(udim2.Y),
        _tag = "UDim2",
    }
end

local Deserialize = {}

function Deserialize.Vector3(vector3)
    return Vector3.new(vector3.x, vector3.y, vector3.z)
end

function Deserialize.CFrame(cframe)
    return CFrame.new(
        cframe.x,
        cframe.y,
        cframe.z,
        cframe.r00,
        cframe.r01,
        cframe.r02,
        cframe.r10,
        cframe.r11,
        cframe.r12,
        cframe.r20,
        cframe.r21,
        cframe.r22
    )
end

function Deserialize.Color3(color3)
    return Color3.new(color3.r, color3.g, color3.b)
end

function Deserialize.ColorSequence(colorSequence)
    local colorSequenceKeypoints = {}
    for _, colorSequenceKeypoint in ipairs(colorSequence.keypoints) do
        table.insert(colorSequenceKeypoints, ColorSequenceKeypoint.new(
            colorSequenceKeypoint.time,
            Deserialize.Color3(colorSequenceKeypoint.color)
        ))
    end
    return ColorSequence.new(colorSequenceKeypoints)
end

function Deserialize.NumberSequence(numberSequence)
    local numberSequenceKeypoints = {}
    for _, numberSequenceKeypoint in ipairs(numberSequence.keypoints) do
        table.insert(numberSequenceKeypoints, NumberSequenceKeypoint.new(
            numberSequenceKeypoint.time,
            numberSequenceKeypoint.value
        ))
    end
    return NumberSequence.new(numberSequenceKeypoints)
end

function Deserialize.NumberRange(numberRange)
    return NumberRange.new(numberRange.min, numberRange.max)
end

function Deserialize.Rect(rect)
    return Rect.new(
        Deserialize.Vector2(rect.min),
        Deserialize.Vector2(rect.max)
    )
end

function Deserialize.Vector2(vector2)
    return Vector2.new(vector2.x, vector2.y)
end

function Deserialize.UDim(udim)
    return UDim.new(udim.scale, udim.offset)
end

function Deserialize.UDim2(udim2)
    return UDim2.new(
        Deserialize.UDim(udim2.x),
        Deserialize.UDim(udim2.y)
    )
end

local function serialize(object)
    local objectType = typeof(object)

    if Serialize[objectType] then
        return Serialize[objectType](object)
    end
    return
end

local function deserialize(object)
    local type = object._tag

    if Deserialize[type] then
        return Deserialize[type](object)
    end
    return
end

return {
    serialize = serialize,
    deserialize = deserialize,
}