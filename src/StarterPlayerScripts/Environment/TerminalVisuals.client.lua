local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local dataFolder = ReplicatedStorage:WaitForChild "Data"

local Configuration = require(ReplicatedFirst:WaitForChild "Configuration")
local Enums = require(ReplicatedFirst:WaitForChild "Enums")
local ClientState = require(dataFolder:WaitForChild "ClientState")
local ClientRoundDataUtility = require(dataFolder:WaitForChild("RoundData"):WaitForChild "ClientRoundDataUtility")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local scope = Fusion:scoped()
local peek = Fusion.peek
local Children = Fusion.Children

local mapScope = scope:deriveScope()
local hydratedInstances = {}

function hydrateInstances()
	for _, instance in workspace:GetDescendants() do
		if not instance:FindFirstAncestor "Terminal" then continue end

		local terminalId
		do
			local terminalModel = instance:FindFirstAncestor "Terminal"

			for _, data in pairs(peek(ClientState.external.roundData.terminalData)) do
				if data.model == terminalModel then
					terminalId = data.id
					break
				end
			end
		end

		if not terminalId then continue end

		if instance.Name == "Colors" and instance:IsA "Configuration" then
			local completeColorValue = instance:FindFirstChild "Complete" :: Color3Value?
			local defaultColorValue = instance:FindFirstChild "Default" :: Color3Value?
			local errorColorValue = instance:FindFirstChild "Error" :: Color3Value?

			assert(
				completeColorValue and defaultColorValue and errorColorValue,
				"Terminal color values incorrectly configured"
			)

			local root = instance.Parent -- all descendants of this root will by hydrated

			for _, descendant in root:GetDescendants() do
				if descendant:IsA "BasePart" and not table.find(hydratedInstances, descendant) then
					table.insert(hydratedInstances, descendant)

					mapScope:Hydrate(descendant) {
						Color = mapScope:Computed(function(use)
							local terminals = use(ClientState.external.roundData.terminalData)
							local terminalData

							if not terminals then return defaultColorValue.Value end

							for _, data in pairs(terminals) do
								if data.id == terminalId then
									terminalData = data
									break
								end
							end

							if not terminalData then return defaultColorValue.Value end

							local isComplete = terminalData.progress >= 100
							local isErrored = terminalData.isErrored

							if isComplete then
								return completeColorValue.Value
							elseif isErrored then
								return errorColorValue.Value
							else
								return defaultColorValue.Value
							end
						end),
					}
				end
			end
		elseif instance.Name == "Icon" and instance:IsA "BasePart" then
			mapScope:New "BillboardGui" {
				Name = "Locator",
				Active = true,
				AlwaysOnTop = true,
				LightInfluence = 1,
				Size = UDim2.fromOffset(1, 1),
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                Parent = instance,

				[Children] = {
					mapScope:New "ImageButton" {
						Name = "Icon",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Image = "rbxassetid://102168697684957",
						ImageTransparency = mapScope:Spring(
							mapScope:Computed(function(use)
								local terminals = use(ClientState.external.roundData.terminalData)
								local terminalData

								if not terminals then return 1 end

								for _, data in pairs(terminals) do
									if data.id == terminalId then
										terminalData = data
										break
									end
								end

								if not terminalData then return 1 end

								local isComplete = terminalData.progress >= 100
								local isErrored = terminalData.isErrored

								if isComplete then
									return 1
								elseif isErrored then
									return 0
								else
									return 1
								end
							end),
							25,
							1
						),
						ImageColor3 = Color3.fromRGB(255, 96, 44),
						Position = UDim2.new(0.5, 0, 0.5, -2),
						Size = UDim2.fromOffset(25, 25),
					},

					mapScope:New "Frame" {
						Name = "Frame",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.new(),
						BackgroundTransparency = mapScope:Spring(
							mapScope:Computed(function(use)
								local terminals = use(ClientState.external.roundData.terminalData)
								local terminalData

								if not terminals then return 1 end

								for _, data in pairs(terminals) do
									if data.id == terminalId then
										terminalData = data
										break
									end
								end

								if not terminalData then return 1 end

								local isComplete = terminalData.progress >= 100
								local isErrored = terminalData.isErrored

								if isComplete then
									return 1
								elseif isErrored then
									return 0.75
								else
									return 1
								end
							end),
							25,
							1
						),
						Size = UDim2.fromOffset(32, 28),
						ZIndex = 0,

						[Children] = {
							mapScope:New "UICorner" {
								Name = "UICorner",
							},
						},
					},
				},
			}
		end
	end
end

ClientRoundDataUtility.setUpRound.Event:Connect(function()
	mapScope:doCleanup()
	mapScope = scope:deriveScope()
	table.clear(hydratedInstances)
	hydrateInstances()
end)

task.wait(Configuration.ClientInitiation.clientLoadingTime)

while not peek(ClientState.external.roundData.currentPhaseType) do
	task.wait()
end

if not (peek(ClientState.external.roundData.currentPhaseType) == Enums.PhaseType.Loading) then hydrateInstances() end
