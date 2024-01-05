local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local character = script.Parent
local player = Players:GetPlayerFromCharacter(character)
local name = player.Name

local plate = character:WaitForChild("Plate")
local surfaceGui = plate:WaitForChild("SurfaceGui")
local frame = surfaceGui:WaitForChild("Frame")
local TextLabel = frame:WaitForChild("TextLabel")

local splitName = string.split(name, "")
local unfilteredString = ""
local filteredResult

for _, v in pairs(splitName) do
	if string.match(v, "%u") then
		unfilteredString = unfilteredString .. v
	end
end

if unfilteredString == "" then
	unfilteredString = string.upper(string.sub(name, 1, 3))
end

local success, errorMessage = pcall(function()
	filteredResult = TextService:FilterStringAsync(unfilteredString, player.UserId)
end)

if success then
	local stringResult = filteredResult:GetNonChatStringForBroadcastAsync()
	if stringResult == unfilteredString then
		TextLabel.Text = stringResult
	else
		TextLabel.Text = string.upper(splitName[1] .. splitName[#splitName]) 
	end 
else
	warn(errorMessage)
	TextLabel.Text = name
end