local HIDERS_COLOR = Color3.fromRGB(99, 153, 213)
local SEEKERS_COLOR = Color3.fromRGB(220, 116, 118)
local LOBBY_COLOR = Color3.fromRGB(220, 122, 220)

local players = game:GetService("Players")
local teams = game:GetService("Teams")

local character = script.Parent
local player = players:GetPlayerFromCharacter(character)

local hidersTeam = teams:WaitForChild("Hiders")
local seekersTeam = teams:WaitForChild("Seekers")
local lobbyTeam = teams:WaitForChild("Lobby")

local neon = character:WaitForChild("Neon")

function changeNeon()
	if player.Team == hidersTeam then
		neon.Color = HIDERS_COLOR
	elseif player.Team == seekersTeam then
		neon.Color = SEEKERS_COLOR
	elseif player.Team == lobbyTeam then
		neon.Color = LOBBY_COLOR
	end
end

changeNeon()

player:GetPropertyChangedSignal("Team"):Connect(changeNeon)