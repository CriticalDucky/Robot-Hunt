local REBELS_COLOR = Color3.fromRGB(99, 153, 213)
local HUNTERS_COLOR = Color3.fromRGB(220, 116, 118)
local LOBBY_COLOR = Color3.fromRGB(220, 122, 220)

local players = game:GetService "Players"
local teams = game:GetService "Teams"

local character = script.Parent
local player = players:GetPlayerFromCharacter(character)

local rebelsTeam = teams:WaitForChild "Rebels"
local huntersTeam = teams:WaitForChild "Hunters"
local lobbyTeam = teams:WaitForChild "Lobby"

local neon = character:WaitForChild "Triangle" :: MeshPart

if player then
	function changeNeon()
		if player.Team == rebelsTeam then
			neon.Color = REBELS_COLOR
		elseif player.Team == huntersTeam then
			neon.Color = HUNTERS_COLOR
		elseif player.Team == lobbyTeam then
			neon.Color = LOBBY_COLOR
		end
	end

	changeNeon()

	player:GetPropertyChangedSignal("Team"):Connect(changeNeon)
else -- must be a dead body
	neon.Color = Color3.new(0.2, 0.2, 0.2)
end
