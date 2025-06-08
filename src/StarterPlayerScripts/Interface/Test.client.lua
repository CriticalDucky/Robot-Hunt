-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local ReplicatedFirst = game:GetService("ReplicatedFirst")
-- local Players = game:GetService("Players")

-- local BannerNotifications = require(ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Utility"):WaitForChild("BannerNotifications"))
-- local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild("Fusion"))

-- local scope = Fusion.scoped(Fusion)
-- local Children = Fusion.Children
-- local player = Players.LocalPlayer

-- local function createTestButton(position: UDim2, text: string, callback: () -> ())
--     return scope:New "TextButton" {
--         Size = UDim2.fromOffset(200, 50),
--         Position = position,
--         Text = text,
--         BackgroundColor3 = Color3.fromRGB(50, 50, 50),
--         TextColor3 = Color3.new(1, 1, 1),
--         BorderSizePixel = 0,
--         FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
--         TextSize = 18,

--         [Fusion.OnEvent "Activated"] = callback,
--     }
-- end

-- scope:New "ScreenGui" {
--     Name = "BannerTest",
--     Parent = player:WaitForChild("PlayerGui"),

--     [Children] = {
--         createTestButton(UDim2.fromOffset(10, 10), "Normal Notification", function()
--             BannerNotifications.addToQueue(4, "Normal Banner", "This is a normal banner notification")
--         end),

--         createTestButton(UDim2.fromOffset(10, 70), "Priority Notification", function()
--             BannerNotifications.addToQueue(3, "Priority Banner!", "This notification jumps the queue!", nil, true)
--         end),

--         createTestButton(UDim2.fromOffset(10, 130), "Queue Multiple", function()
--             for i = 1, 3 do
--                 BannerNotifications.addToQueue(
--                     2,
--                     string.format("Banner %d", i),
--                     string.format("This is notification %d of 3", i)
--                 )
--             end
--         end),

--         createTestButton(UDim2.fromOffset(10, 190), "No Info Text", function()
--             BannerNotifications.addToQueue(3, "Centered Title")
--         end),

--         createTestButton(UDim2.fromOffset(10, 250), "Color Test", function()
--             BannerNotifications.addToQueue(4, "Colored Title", "With info text", Color3.fromRGB(255, 100, 100))
--         end),

--         createTestButton(UDim2.fromOffset(10, 310), "Cancel All", function()
--             BannerNotifications.cancelAll()
--         end),

--         createTestButton(UDim2.fromOffset(10, 370), "Game Event Test", function()
--             -- Simulates a sequence of game events
--             local id1 = BannerNotifications.addToQueue(5, "Phase One Starting!", "Hack the terminals!")
            
--             task.delay(2, function()
--                 BannerNotifications.addToQueue(2, "Terminal Hacked!", "4 terminals remaining", Color3.fromRGB(100, 255, 100), true)
--             end)
            
--             task.delay(4, function()
--                 BannerNotifications.cancelNotification(id1)
--                 BannerNotifications.addToQueue(3, "Player Eliminated!", "CriticalDucky was eliminated!", Color3.fromRGB(255, 100, 100))
--             end)
--         end),
--     }
-- }