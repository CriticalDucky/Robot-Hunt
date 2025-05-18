-- local ReplicatedStorage = game:GetService "ReplicatedStorage"
-- local ReplicatedFirst = game:GetService "ReplicatedFirst"
-- local Players = game:GetService "Players"

-- local componentsFolder = ReplicatedStorage:WaitForChild("Interface"):WaitForChild "Components"

-- local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
-- local New = Fusion.New
-- local peek = Fusion.peek
-- local Children = Fusion.Children
-- local RadialProgress = require(componentsFolder:WaitForChild "RadialProgress")

-- local scope = Fusion.scoped(Fusion, { RadialProgress = RadialProgress })
-- local player = Players.LocalPlayer

-- local screenGui = Instance.new "ScreenGui"
-- screenGui.Name = "TestRadialProgress"
-- screenGui.Parent = player:WaitForChild "PlayerGui"

-- -- tanslate above into fusion

-- local progress = scope:Value(40)
-- local flip = scope:Value(false)

-- scope:New "ScreenGui" {
-- 	Name = "TastRadialProgress",
-- 	Parent = player:WaitForChild "PlayerGui",

-- 	[Children] = {
-- 		scope:RadialProgress {
-- 			Progress = progress,
-- 			Size = UDim2.new(0, 100, 0, 100),
-- 			Position = UDim2.fromScale(0, 0),
-- 			AnchorPoint = Vector2.new(0, 0),
--             ProgressThickness = 20,
--             ProgressColor = Color3.fromRGB(0, 0, 255),
-- 			Rotation = 0,
-- 			Visible = true,
-- 			ZIndex = 1,

-- 			IsPie = false,
-- 			Flip = flip,

-- 			BackgroundColor = Color3.fromRGB(255, 0, 0),
-- 			BackgroundTransparency = 0.75,
-- 		},

-- 		scope:RadialProgress {
-- 			Progress = progress,
--             Size = UDim2.new(0, 100, 0, 100),
--             Position = UDim2.fromOffset(100, 0),
--             AnchorPoint = Vector2.new(0, 0),
--             Rotation = 0,
--             Visible = true,
--             ZIndex = 1,

--             IsPie = true,
--             Flip = flip,

--             BackgroundColor = Color3.fromRGB(0, 0, 0),
--             BackgroundTransparency = 0.75,
-- 		},
-- 	},
-- }

-- task.spawn(function()
-- 	while true do
-- 		local dt = task.wait()
-- 		progress:set(peek(progress) + dt * 10)

-- 		if peek(progress) >= 100 then progress:set(0) end
-- 	end
-- end)