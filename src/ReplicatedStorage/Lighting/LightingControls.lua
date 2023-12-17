-- Controls lighting and effects.

local SPRING_SPEED = 1
local SPRING_DAMPING = 1

--#region Imports

local Lighting = game:GetService "Lighting"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Hydrate = Fusion.Hydrate
local peek = Fusion.peek
local Spring = Fusion.Spring
local Value = Fusion.Value

--#endregion

--#region Atmosphere

local atmosphere = Lighting:WaitForChild "Atmosphere"

local atmosphereDefaults = {
	Color = atmosphere.Color,
	Decay = atmosphere.Decay,
	Density = atmosphere.Density,
	Glare = atmosphere.Glare,
	Haze = atmosphere.Haze,
	Offset = atmosphere.Offset,
}

local atmosphereValues = {}
local atmosphereSprings = {}

for key, value in pairs(atmosphereDefaults) do
	atmosphereValues[key] = Value(value)
	atmosphereSprings[key] = Spring(atmosphereValues[key], SPRING_SPEED, SPRING_DAMPING)
end

Hydrate(atmosphere)(atmosphereSprings)

--#endregion

--#region BloomEffect

local bloomEffect = Lighting:WaitForChild "BloomEffect"

local bloomEffectDefaults = {
	Intensity = bloomEffect.Intensity,
	Size = bloomEffect.Size,
	Threshold = bloomEffect.Threshold,
}

local bloomEffectValues = {}
local bloomEffectSprings = {}

for key, value in pairs(bloomEffectDefaults) do
	bloomEffectValues[key] = Value(value)
	bloomEffectSprings[key] = Spring(bloomEffectValues[key], SPRING_SPEED, SPRING_DAMPING)
end

Hydrate(bloomEffect)(bloomEffectSprings)

--#endregion

--#region BlurEffect

local blurEffect = Lighting:WaitForChild "BlurEffect"

local blurEffectDefaults = {
	Size = blurEffect.Size,
}

local blurEffectValues = {}
local blurEffectSprings = {}

for key, value in pairs(blurEffectDefaults) do
	blurEffectValues[key] = Value(value)
	blurEffectSprings[key] = Spring(blurEffectValues[key], SPRING_SPEED, SPRING_DAMPING)
end

Hydrate(blurEffect)(blurEffectSprings)

--#endregion

--#region Clouds

local clouds = workspace.Terrain:WaitForChild "Clouds"

local cloudsDefaults = {
	Color = clouds.Color,
	Cover = clouds.Cover,
	Density = clouds.Density,
}

local cloudsValues = {}
local cloudsSprings = {}

for key, value in pairs(cloudsDefaults) do
	cloudsValues[key] = Value(value)
	cloudsSprings[key] = Spring(cloudsValues[key], SPRING_SPEED, SPRING_DAMPING)
end

Hydrate(clouds)(cloudsSprings)

--#endregion

--#region ColorCorrectionEffect

local colorCorrectionEffect = Lighting:WaitForChild "ColorCorrectionEffect"

local colorCorrectionEffectDefaults = {
	Brightness = colorCorrectionEffect.Brightness,
	Contrast = colorCorrectionEffect.Contrast,
	Saturation = colorCorrectionEffect.Saturation,
	TintColor = colorCorrectionEffect.TintColor,
}

local colorCorrectionEffectValues = {}
local colorCorrectionEffectSprings = {}

for key, value in pairs(colorCorrectionEffectDefaults) do
	colorCorrectionEffectValues[key] = Value(value)
	colorCorrectionEffectSprings[key] = Spring(colorCorrectionEffectValues[key], SPRING_SPEED, SPRING_DAMPING)
end

Hydrate(colorCorrectionEffect)(colorCorrectionEffectSprings)

--#endregion

--#region DepthOfFieldEffect

local depthOfFieldEffect = Lighting:WaitForChild "DepthOfFieldEffect"

local depthOfFieldEffectDefaults = {
	FarIntensity = depthOfFieldEffect.FarIntensity,
	FocusDistance = depthOfFieldEffect.FocusDistance,
	InFocusRadius = depthOfFieldEffect.InFocusRadius,
	NearIntensity = depthOfFieldEffect.NearIntensity,
}

local depthOfFieldEffectValues = {}
local depthOfFieldEffectSprings = {}

for key, value in pairs(depthOfFieldEffectDefaults) do
	depthOfFieldEffectValues[key] = Value(value)
	depthOfFieldEffectSprings[key] = Spring(depthOfFieldEffectValues[key], SPRING_SPEED, SPRING_DAMPING)
end

Hydrate(depthOfFieldEffect)(depthOfFieldEffectSprings)

--#endregion

--#region Lighting

local lightingDefaults = {
	Ambient = Lighting.Ambient,
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	ColorShift_Bottom = Lighting.ColorShift_Bottom,
	ColorShift_Top = Lighting.ColorShift_Top,
	EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
	ExposureCompensation = Lighting.ExposureCompensation,
	GeographicLatitude = Lighting.GeographicLatitude,
	GlobalShadows = Lighting.GlobalShadows,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ShadowSoftness = Lighting.ShadowSoftness,
}

local lightingValues = {}
local lightingSprings = {}
local lightingStates = {}

for key, value in pairs(lightingDefaults) do
	lightingValues[key] = Value(value)

	if key == "GlobalShadows" then
		lightingStates[key] = lightingValues[key]
		continue
	end

	lightingSprings[key] = Spring(lightingValues[key], SPRING_SPEED, SPRING_DAMPING)
	lightingStates[key] = lightingSprings[key]
end

Hydrate(Lighting)(lightingStates)

--#endregion

--#region Sky

local sky = Lighting:WaitForChild "Sky"

local skyDefaults = {
	CelestialBodiesShown = sky.CelestialBodiesShown,
	MoonAngularSize = sky.MoonAngularSize,
	MoonTextureId = sky.MoonTextureId,
	SkyboxBk = sky.SkyboxBk,
	SkyboxDn = sky.SkyboxDn,
	SkyboxFt = sky.SkyboxFt,
	SkyboxLf = sky.SkyboxLf,
	SkyboxRt = sky.SkyboxRt,
	SkyboxUp = sky.SkyboxUp,
	StarCount = sky.StarCount,
	SunAngularSize = sky.SunAngularSize,
	SunTextureId = sky.SunTextureId,
}

local skyValues = {}
local skySprings = {}
local skyStates = {}

for key, value in pairs(skyDefaults) do
	skyValues[key] = Value(value)

	if typeof(value) == "boolean" or typeof(value) == "string" then
		skyStates[key] = skyValues[key]
		continue
	end

	skySprings[key] = Spring(skyValues[key], SPRING_SPEED, SPRING_DAMPING)
	skyStates[key] = skySprings[key]
end

Hydrate(sky)(skyStates)

--#endregion

--#region SunRaysEffect

local sunRaysEffect = Lighting:WaitForChild "SunRaysEffect"

local sunRaysEffectDefaults = {
	Intensity = sunRaysEffect.Intensity,
	Spread = sunRaysEffect.Spread,
}

local sunRaysEffectValues = {}
local sunRaysEffectSprings = {}

for key, value in pairs(sunRaysEffectDefaults) do
	sunRaysEffectValues[key] = Value(value)
	sunRaysEffectSprings[key] = Spring(sunRaysEffectValues[key], SPRING_SPEED, SPRING_DAMPING)
end

Hydrate(sunRaysEffect)(sunRaysEffectSprings)

--#endregion

local LightingSystem = {}

--[[
	Updates all lighting and effect properties to the given template, with ommitted properties being set to default.
	Quantitative values will be animated with a spring unless `instantly` is true.

	**Example:**
	```lua
	LightingSystem.applyTemplate({
		Atmosphere = {
			Density = 0.5,
			Color = Color3.fromRGB(255, 255, 255),
		},
		BloomEffect = {
			Intensity = 0.5,
		},
		BlurEffect = {
			Size = 0.5,
		},
	})
	```
]]
function LightingSystem.applyTemplate(template: { [string]: { [string]: any } }, instantly: boolean?)
	LightingSystem.resetAll(instantly)

	LightingSystem.updateAtmosphere(template.Atmosphere, instantly)
	LightingSystem.updateBloomEffect(template.BloomEffect, instantly)
	LightingSystem.updateBlurEffect(template.BlurEffect, instantly)
	LightingSystem.updateClouds(template.Clouds, instantly)
	LightingSystem.updateColorCorrectionEffect(template.ColorCorrectionEffect, instantly)
	LightingSystem.updateDepthOfFieldEffect(template.DepthOfFieldEffect, instantly)
	LightingSystem.updateLighting(template.Lighting, instantly)
	LightingSystem.updateSky(template.Sky, instantly)
	LightingSystem.updateSunRaysEffect(template.SunRaysEffect, instantly)
end

--[[
	Resets all lighting and effect properties to their default values. Quantitative values will be animated with a
	spring unless `instantly` is true.
]]
function LightingSystem.resetAll(instantly: boolean?)
	LightingSystem.resetAtmosphere(instantly)
	LightingSystem.resetBloomEffect(instantly)
	LightingSystem.resetBlurEffect(instantly)
	LightingSystem.resetClouds(instantly)
	LightingSystem.resetColorCorrectionEffect(instantly)
	LightingSystem.resetDepthOfFieldEffect(instantly)
	LightingSystem.resetLighting(instantly)
	LightingSystem.resetSky(instantly)
	LightingSystem.resetSunRaysEffect(instantly)
end

--[[
	Resets the `Atmosphere`'s properties to their default values. Quantitative values will be animated with a spring
	unless `instantly` is true.
]]
function LightingSystem.resetAtmosphere(instantly: boolean?)
	LightingSystem.updateAtmosphere(atmosphereDefaults, instantly)
end

--[[
	Resets the `BloomEffect`'s properties to their default values. Quantitative values will be animated with a spring
	unless `instantly` is true.
]]
function LightingSystem.resetBloomEffect(instantly: boolean?)
	LightingSystem.updateBloomEffect(bloomEffectDefaults, instantly)
end

--[[
	Resets the `BlurEffect`'s properties to their default values. Quantitative values will be animated with a spring
	unless `instantly` is true.
]]
function LightingSystem.resetBlurEffect(instantly: boolean?)
	LightingSystem.updateBlurEffect(blurEffectDefaults, instantly)
end


--[[
	Resets the `Clouds`'s properties to their default values. Quantitative values will be animated with a spring unless
	`instantly` is true.
]]
function LightingSystem.resetClouds(instantly: boolean?)
	LightingSystem.updateClouds(cloudsDefaults, instantly)
end

--[[
	Resets the `ColorCorrectionEffect`'s properties to their default values. Quantitative values will be animated with a
	spring unless `instantly` is true.
]]
function LightingSystem.resetColorCorrectionEffect(instantly: boolean?)
	LightingSystem.updateColorCorrectionEffect(colorCorrectionEffectDefaults, instantly)
end

--[[
	Resets the `DepthOfFieldEffect`'s properties to their default values. Quantitative values will be animated with a
	spring unless `instantly` is true.
]]
function LightingSystem.resetDepthOfFieldEffect(instantly: boolean?)
	LightingSystem.updateDepthOfFieldEffect(depthOfFieldEffectDefaults, instantly)
end

--[[
	Resets `Lighting`'s properties to their default values. Quantitative values will be animated with a spring unless
	`instantly` is true.
]]
function LightingSystem.resetLighting(instantly: boolean?)
	LightingSystem.updateLighting(lightingDefaults, instantly)
end

--[[
	Resets the `Sky`'s properties to their default values. Quantitative values will be animated with a spring unless
	`instantly` is true.
]]
function LightingSystem.resetSky(instantly: boolean?)
	LightingSystem.updateSky(skyDefaults, instantly)
end

--[[
	Resets the `SunRaysEffect`'s properties to their default values. Quantitative values will be animated with a spring
	unless `instantly` is true.
]]
function LightingSystem.resetSunRaysEffect(instantly: boolean?)
	LightingSystem.updateSunRaysEffect(sunRaysEffectDefaults, instantly)
end

--[[
	Updates the `Atmosphere`'s properties to the given values. Quantitative values will be animated with a spring unless
	`instantly` is true.
]]
function LightingSystem.updateAtmosphere(props: { [string]: any }, instantly: boolean?)
	for prop, newValue in pairs(props) do
		local value = atmosphereValues[prop]

		if not value then
			warn("Invalid/unsupported Atmosphere property ignored: " .. prop)
			continue
		end

		value:set(newValue)

		if not instantly then continue end

		local spring = atmosphereSprings[prop]

		spring:setPosition(newValue)

		if typeof(peek(spring)) == "Color3" then
			spring:setVelocity(Color3.new(0, 0, 0))
		else
			spring:setVelocity(0)
		end
	end
end

--[[
	Updates the `BloomEffect`'s properties to the given values. Quantitative values will be animated with a spring
	unless `instantly` is true.
]]
function LightingSystem.updateBloomEffect(props: { [string]: any }, instantly: boolean?)
	for prop, newValue in pairs(props) do
		local value = bloomEffectValues[prop]

		if not value then
			warn("Invalid/unsupported BloomEffect property ignored: " .. prop)
			continue
		end

		value:set(newValue)

		if not instantly then continue end

		local spring = bloomEffectSprings[prop]

		spring:setPosition(newValue)
		spring:setVelocity(0)
	end
end

--[[
	Updates the `BlurEffect`'s properties to the given values. Quantitative values will be animated with a spring unless
	`instantly` is true.
]]
function LightingSystem.updateBlurEffect(props: { [string]: any }, instantly: boolean?)
	for prop, newValue in pairs(props) do
		local value = blurEffectValues[prop]

		if not value then
			warn("Invalid/unsupported BlurEffect property ignored: " .. prop)
			continue
		end

		value:set(newValue)

		if not instantly then continue end

		local spring = blurEffectSprings[prop]

		spring:setPosition(newValue)
		spring:setVelocity(0)
	end
end

--[[
	Updates the `Clouds`'s properties to the given values. Quantitative values will be animated with a spring unless
	`instantly` is true.
]]
function LightingSystem.updateClouds(props: { [string]: any }, instantly: boolean?)
	for prop, newValue in pairs(props) do
		local value = cloudsValues[prop]

		if not value then
			warn("Invalid/unsupported Clouds property ignored: " .. prop)
			continue
		end

		value:set(newValue)

		if not instantly then continue end

		local spring = cloudsSprings[prop]

		spring:setPosition(newValue)

		if typeof(peek(spring)) == "Color3" then
			spring:setVelocity(Color3.new(0, 0, 0))
		else
			spring:setVelocity(0)
		end
	end
end

--[[
	Updates the `ColorCorrectionEffect`'s properties to the given values. Quantitative values will be animated with a
	spring unless `instantly` is true.
]]
function LightingSystem.updateColorCorrectionEffect(props: { [string]: any }, instantly: boolean?)
	for prop, newValue in pairs(props) do
		local value = colorCorrectionEffectValues[prop]

		if not value then
			warn("Invalid/unsupported ColorCorrectionEffect property ignored: " .. prop)
			continue
		end

		value:set(newValue)

		if not instantly then continue end

		local spring = colorCorrectionEffectSprings[prop]

		spring:setPosition(newValue)

		if typeof(peek(spring)) == "Color3" then
			spring:setVelocity(Color3.new(0, 0, 0))
		else
			spring:setVelocity(0)
		end
	end
end

--[[
	Updates the `DepthOfFieldEffect`'s properties to the given values. Quantitative values will be animated with a
	spring unless `instantly` is true.
]]
function LightingSystem.updateDepthOfFieldEffect(props: { [string]: any }, instantly: boolean?)
	for prop, newValue in pairs(props) do
		local value = depthOfFieldEffectValues[prop]

		if not value then
			warn("Invalid/unsupported DepthOfFieldEffect property ignored: " .. prop)
			continue
		end

		value:set(newValue)

		if not instantly then continue end

		local spring = depthOfFieldEffectSprings[prop]

		spring:setPosition(newValue)
		spring:setVelocity(0)
	end
end

--[[
	Updates `Lighting`'s properties to the given values. Quantitative values will be animated with a spring unless
	`instantly` is true.
]]
function LightingSystem.updateLighting(props: { [string]: any }, instantly: boolean?)
	for prop, newValue in pairs(props) do
		local value = lightingValues[prop]

		if not value then
			warn("Invalid/unsupported Lighting property ignored: " .. prop)
			continue
		end

		value:set(newValue)

		if not instantly then continue end

		local spring = lightingSprings[prop]

		if not spring then continue end

		spring:setPosition(newValue)

		if typeof(peek(spring)) == "Color3" then
			spring:setVelocity(Color3.new(0, 0, 0))
		else
			spring:setVelocity(0)
		end
	end
end

--[[
	Updates the `Sky`'s properties to the given values. Quantitative values will be animated with a spring unless
	`instantly` is true.
]]
function LightingSystem.updateSky(props: { [string]: any }, instantly: boolean?)
	for prop, newValue in pairs(props) do
		local value = skyValues[prop]

		if not value then
			warn("Invalid/unsupported Sky property ignored: " .. prop)
			continue
		end

		value:set(newValue)

		if not instantly then continue end

		local spring = skySprings[prop]

		if not spring then continue end

		spring:setPosition(newValue)

		spring:setVelocity(0)
	end
end

--[[
	Updates the `SunRaysEffect`'s properties to the given values. Quantitative values will be animated with a spring
	unless `instantly` is true.
]]
function LightingSystem.updateSunRaysEffect(props: { [string]: any }, instantly: boolean?)
	for prop, newValue in pairs(props) do
		local value = sunRaysEffectValues[prop]

		if not value then
			warn("Invalid/unsupported SunRaysEffect property ignored: " .. prop)
			continue
		end

		value:set(newValue)

		if not instantly then continue end

		local spring = sunRaysEffectSprings[prop]

		spring:setPosition(newValue)
		spring:setVelocity(0)
	end
end

return LightingSystem
