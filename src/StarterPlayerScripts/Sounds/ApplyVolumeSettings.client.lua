local ReplicatedFirst = game:GetService "ReplicatedFirst"
local SoundService = game:GetService "SoundService"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

local scope = Fusion.scoped(Fusion)

local musicVolume = scope:Computed(function(use)
	-- return ClientPlayerSettings.withData.getSetting(use(ClientPlayerSettings.value), "musicVolume")
end)

local sfxVolume = scope:Computed(function(use)
	-- return ClientPlayerSettings.withData.getSetting(use(ClientPlayerSettings.value), "sfxVolume")
end)

scope:Hydrate(SoundService:WaitForChild "Music") {
	Volume = musicVolume,
}

scope:Hydrate(SoundService:WaitForChild "SFX") {
	Volume = sfxVolume,
}
