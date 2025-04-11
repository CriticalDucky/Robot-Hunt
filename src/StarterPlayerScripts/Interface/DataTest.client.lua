--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local Players = game:GetService "Players"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"

local RoundConfiguration = require(ReplicatedStorage:WaitForChild("Configuration"):WaitForChild("RoundConfiguration"))
local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("ClientState"))
local Enums = require(ReplicatedFirst:WaitForChild("Enums"))

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local Children = Fusion.Children

local scope = Fusion.scoped(Fusion)

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild "PlayerGui"

local RoundType = Enums.RoundType
local PhaseType = Enums.PhaseType

local roundData = ClientState.external.roundData

local health = scope:Computed(function(use)
    local playerDatas = use(roundData.playerData)
    local playerData = playerDatas[Players.LocalPlayer.UserId]

    if playerData then
        return playerData.health
    else
        return 0
    end
end)

scope:New "ScreenGui" {
    Parent = playerGui;

    [Children] = {
        scope:New "Frame" { -- Health bar
            Name = "HealthBar";
            BackgroundTransparency = 0;
            BackgroundColor3 = Color3.fromRGB(0, 0, 0);
            Size = UDim2.new(0.2, 0, 0.05, 0);
            Position = UDim2.new(0.5, 0, 0.9, 0);
            AnchorPoint = Vector2.new(0.5, 0.5);
            [Children] = {
                scope:New "Frame" {
                    Name = "Fill";
                    BackgroundColor3 = Color3.fromRGB(255, 0, 0);
                    AnchorPoint = Vector2.new(0, 0.5);
                    Position = UDim2.new(0, 0, 0.5, 0);
                    BorderSizePixel = 0;
                    Size = scope:Computed(function(use)
                        local health = use(health)
                        return UDim2.new(health / 100, 0, 1, 0)
                    end);
                };
            };
        };
    }
}