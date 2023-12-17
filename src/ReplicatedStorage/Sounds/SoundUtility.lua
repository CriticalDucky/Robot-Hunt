-- Provides sound functionalities for the client.

local BG_MUSIC_VOLUME = 0.5
local BG_MUSIC_SPRING_SPEED = 5
local BG_MUSIC_SPRING_DAMPING = 1
local BG_MUSIC_TRANSITION_TIME = 3

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local SoundService = game:GetService "SoundService"

assert(RunService:IsClient(), "SoundUtility can only be used on the client.")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Hydrate = Fusion.Hydrate
local Spring = Fusion.Spring
local Value = Fusion.Value

--#endregion

--#region Background Music

local musicGroup = SoundService:WaitForChild "Music"

local bgMusicVolume = Value(BG_MUSIC_VOLUME)
local bgMusicVolumeSpring = Spring(bgMusicVolume, BG_MUSIC_SPRING_SPEED, BG_MUSIC_SPRING_DAMPING)

local bgMusic: Sound = Hydrate(Instance.new "Sound") {
	Name = "BackgroundMusic",
	SoundGroup = musicGroup,
	Volume = bgMusicVolumeSpring,
}
bgMusic.Parent = musicGroup

local currentBgMusic
local bgMusicManagerThread

--[[
	Manages the playing of a single track or a playlist of tracks.
]]
local function playBgMusic(music: (string | { [number]: string })?)
	currentBgMusic = music
	if bgMusicManagerThread then task.cancel(bgMusicManagerThread) end
	bgMusicManagerThread = nil

	bgMusic:Stop()

	if type(music) == "string" then
		bgMusic.Looped = true

		bgMusic.SoundId = music
		bgMusic:Play()
	elseif type(music) == "table" then
		bgMusicManagerThread = task.spawn(function()
			bgMusic.Looped = false

			local currentTrackIndex = 1

			while true do
				bgMusic.SoundId = music[currentTrackIndex]
				bgMusic:Play()
				--[[
				 	Sound.Ended:Wait() is buggy with coroutines, and TimeLength takes a moment to update, so we
				 	essentially clamp TimeLength to a minimum of 1 second to give it a chance to update.
				]]
				task.wait(1)
				if bgMusic.TimeLength > 1 then task.wait(bgMusic.TimeLength - 1) end
				currentTrackIndex = currentTrackIndex % #music + 1
			end
		end)
	end
end

local queuedBgMusic
local bgMusicChangingThread

--#endregion

local SoundUtility = {}

--[[
	Plays the provided sound ID or playlist (array) of sound IDs as background music. To stop the current background
	music, omit `music`.

	**Examples:**
	```lua
	-- Plays a single track.
	SoundUtility.setBackgroundMusic("rbxassetid://1234567890")
	
	-- Plays a playlist of tracks.
	SoundUtility.setBackgroundMusic({
		"rbxassetid://1234567890",
		"rbxassetid://0987654321",
	})

	-- Stops the current background music.
	SoundUtility.setBackgroundMusic()
	```
]]
function SoundUtility.setBackgroundMusic(music: (string | { [number]: string })?)
	if music == "" then warn "An empty string song ID will be treated as a playing track. Did you mean to omit it?" end

	if type(music) == "table" and not music[1] then
		warn "Cannot play an empty playlist."
		return
	end

	if music == currentBgMusic and bgMusicChangingThread then
		queuedBgMusic = nil
		task.cancel(bgMusicChangingThread)
		bgMusicChangingThread = nil

		bgMusicVolume:set(BG_MUSIC_VOLUME)
	elseif music ~= currentBgMusic and bgMusicChangingThread then
		queuedBgMusic = music
	elseif music ~= currentBgMusic and not bgMusicChangingThread then
		if not currentBgMusic then
			playBgMusic(music)
			return
		end

		queuedBgMusic = music

		bgMusicChangingThread = task.spawn(function()
			bgMusicVolume:set(0)
			task.wait(BG_MUSIC_TRANSITION_TIME)
			bgMusicVolume:set(BG_MUSIC_VOLUME)
			bgMusicVolumeSpring:setPosition(BG_MUSIC_VOLUME)
			bgMusicVolumeSpring:setVelocity(0)

			playBgMusic(queuedBgMusic)

			queuedBgMusic = nil
			bgMusicChangingThread = nil
		end)
	end
end

return SoundUtility
