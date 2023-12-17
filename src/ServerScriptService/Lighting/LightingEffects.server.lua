-- Sets up lighting effect instances.

local Lighting = game:GetService "Lighting"

Lighting.Ambient = Color3.fromRGB(70, 70, 70)
Lighting.Brightness = 3
Lighting.ClockTime = 14.5
Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 1
Lighting.ExposureCompensation = 0
Lighting.GeographicLatitude = 0
Lighting.GlobalShadows = true
Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
Lighting.ShadowSoftness = 0.2

local bloomEffect = Instance.new "BloomEffect"
bloomEffect.Name = "BloomEffect"
bloomEffect.Intensity = 1
bloomEffect.Size = 24
bloomEffect.Threshold = 2
bloomEffect.Parent = Lighting

local blurEffect = Instance.new "BlurEffect"
blurEffect.Name = "BlurEffect"
blurEffect.Size = 0
blurEffect.Parent = Lighting

local colorCorrectionEffect = Instance.new "ColorCorrectionEffect"
colorCorrectionEffect.Name = "ColorCorrectionEffect"
colorCorrectionEffect.Parent = Lighting

local depthOfFieldEffect = Instance.new "DepthOfFieldEffect"
depthOfFieldEffect.Name = "DepthOfFieldEffect"
depthOfFieldEffect.FarIntensity = 0
depthOfFieldEffect.NearIntensity = 0
depthOfFieldEffect.Parent = Lighting

local sunRaysEffect = Instance.new "SunRaysEffect"
sunRaysEffect.Name = "SunRaysEffect"
sunRaysEffect.Intensity = 0.01
sunRaysEffect.Spread = 0.1
sunRaysEffect.Parent = Lighting

local atmosphere = Instance.new "Atmosphere"
atmosphere.Name = "Atmosphere"
atmosphere.Color = Color3.fromRGB(199, 199, 199)
atmosphere.Decay = Color3.fromRGB(106, 112, 125)
atmosphere.Density = 0.3
atmosphere.Glare = 0
atmosphere.Haze = 0
atmosphere.Offset = 0.25
atmosphere.Parent = Lighting

local sky = Instance.new "Sky"
sky.Name = "Sky"
sky.CelestialBodiesShown = true
sky.MoonAngularSize = 11
sky.MoonTextureId = "rbxassetid://6444320592"
sky.SkyboxBk = "rbxassetid://6444884337"
sky.SkyboxDn = "rbxassetid://6444884785"
sky.SkyboxFt = "rbxassetid://6444884337"
sky.SkyboxLf = "rbxassetid://6444884337"
sky.SkyboxRt = "rbxassetid://6444884337"
sky.SkyboxUp = "rbxassetid://6412503613"
sky.StarCount = 3000
sky.SunAngularSize = 11
sky.SunTextureId = "rbxassetid://6196665106"
sky.Parent = Lighting

local clouds = Instance.new "Clouds"
clouds.Name = "Clouds"
clouds.Cover = 0
clouds.Density = 0
clouds.Parent = workspace.Terrain