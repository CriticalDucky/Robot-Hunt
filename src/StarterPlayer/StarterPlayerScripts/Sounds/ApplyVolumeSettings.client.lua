local ReplicatedFirst = game:GetService "ReplicatedFirst"
local SoundService = game:GetService "SoundService"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
-- local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

local Computed = Fusion.Computed
local Hydrate = Fusion.Hydrate

local musicVolume = Computed(function(use)
	-- return ClientPlayerSettings.withData.getSetting(use(ClientPlayerSettings.value), "musicVolume")
end)

local sfxVolume = Computed(function(use)
	-- return ClientPlayerSettings.withData.getSetting(use(ClientPlayerSettings.value), "sfxVolume")
end)

Hydrate(SoundService:WaitForChild "Music") {
	Volume = musicVolume,
}

Hydrate(SoundService:WaitForChild "SFX") {
	Volume = sfxVolume,
}
