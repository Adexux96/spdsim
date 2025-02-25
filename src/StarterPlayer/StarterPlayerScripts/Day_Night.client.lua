local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local timeEvent = rs:WaitForChild("TimeEvent")
local lighting = game:GetService("Lighting")
local colorCorrection = lighting:WaitForChild("colorCorrection")

local morningInfo = {
	[1] = {lighting, "Ambient", Color3.fromRGB(128, 122, 173)},
	[2] = {lighting, "Brightness", 2},
	[3] = {lighting, "ColorShift_Bottom", Color3.fromRGB(0,0,0)},
	[4] = {lighting, "ColorShift_Top", Color3.fromRGB(255,255,255)},
	[5] = {lighting, "OutdoorAmbient", Color3.fromRGB(217, 206, 240)}, -- 221, 212, 240
	[6] = {lighting, "ClockTime", 12},
	[7] = {lighting, "GeographicLatitude", 12},
	[8] = {lighting, "ExposureCompensation", -0.6},
	[9] = {colorCorrection, "Brightness", .125},
	[10] = {colorCorrection, "Contrast", 0.25},
	[11] = {colorCorrection, "Saturation", 0.25},
	[12] = {colorCorrection, "TintColor", Color3.fromRGB(250, 240, 255)},
	[13] = {lighting, "FogEnd", math.huge},
	[14] = {lighting, "FogStart", math.huge},
	[15] = {lighting, "FogColor", Color3.fromRGB(255,255,255)},
}

local nightInfo = {
	[1] = {lighting, "Ambient", Color3.fromRGB(128, 122, 173)},
	[2] = {lighting, "Brightness", 0.25},
	[3] = {lighting, "ColorShift_Bottom", Color3.fromRGB(0,0,0)},
	[4] = {lighting, "ColorShift_Top", Color3.fromRGB(0,0,0)},
	[5] = {lighting, "OutdoorAmbient", Color3.fromRGB(0,0,0)},
	[6] = {lighting, "ClockTime", 9.1},
	[7] = {lighting, "GeographicLatitude", -139},
	[8] = {lighting, "ExposureCompensation", -0.6},
	[9] = {colorCorrection, "Brightness", .1},
	[10] = {colorCorrection, "Contrast", 0.25},
	[11] = {colorCorrection, "Saturation", 0.25},
	[12] = {colorCorrection, "TintColor", Color3.fromRGB(250, 240, 255)},
	[13] = {lighting, "FogEnd", math.huge},
	[14] = {lighting, "FogStart", math.huge},
	[15] = {lighting, "FogColor", Color3.fromRGB(255,255,255)},
}

local skyFolder = lighting:WaitForChild("skys")
local timeOfDay = script:WaitForChild("TimeOfDay")
local currentInfo
local water = workspace:WaitForChild("water")

local streetlights=workspace:WaitForChild("StreetLamp")
local spotlights=workspace:WaitForChild("Spotlights")
local clientCars=workspace:WaitForChild("clientCars")

local function ToggleSpotlight(model)
	local light=model:FindFirstChild("light1")
	local spotlight=light and light:FindFirstChild("light1")
	local beam=spotlight and spotlight:FindFirstChild("light")
	if not beam then return end
	beam.Enabled = timeOfDay.Value == "night" and true or false
end

local function ToggleStreetlight(model)
	local light=model:FindFirstChild("Light")
	if not light then return end
	local bool=timeOfDay.Value=="night"
	light.Material=bool and Enum.Material.Neon or Enum.Material.Plastic
	light.Color=bool and Color3.fromRGB(184, 169, 126) or Color3.fromRGB(234, 229, 161)
	for _,descendant in light:GetDescendants() do 
		if descendant:IsA("SpotLight") or descendant:IsA("Beam") then
			descendant.Enabled=bool
		end
	end
end

local function toggleStreetlights()
	for i,v in streetlights:GetChildren() do
		ToggleStreetlight(v)
	end
end

local function toggleSpotlights()
	for _,v in spotlights:GetChildren() do 
		ToggleSpotlight(v)
	end
end

local function toggleRooftopLight()
	local rooftopdoor=workspace:FindFirstChild("RoofTopDoor1")
	if not rooftopdoor then return end
	local light=rooftopdoor:FindFirstChild("light")
	if not light then return end
	local beam=light:FindFirstChild("LightBeam")
	if not beam then return end
	local spotlight=light:FindFirstChild("SpotLight")
	if not spotlight then return end
	local bool=timeOfDay.Value=="night"
	for _,v in {beam,spotlight} do 
		v.Enabled=bool
	end
	light.Material=bool and Enum.Material.Neon or Enum.Material.Plastic
end

local function toggleRooftopBillboardLight()
	local rooftopbillboard=workspace:FindFirstChild("RooftopBillboard")
	if not rooftopbillboard then return end
	local light=rooftopbillboard:FindFirstChild("Lights")
	if not light then return end
	local bool=timeOfDay.Value=="night"
	for _,v in light:GetDescendants() do 
		if v:IsA("Attachment") then continue end
		v.Enabled=bool
	end
	light.Material=bool and Enum.Material.Neon or Enum.Material.Plastic	
end

local function toggleCarLights(bool)
	for index,car in (clientCars:GetChildren()) do 
		local destroyedBody=car:FindFirstChild("DestroyedBody")
		if not destroyedBody then return end
		if destroyedBody.Transparency==0 then continue end
		local headlight = car:FindFirstChild("Headlight")
		if not headlight then continue end
		headlight.Color=bool and Color3.fromRGB(184, 169, 126) or Color3.fromRGB(234, 229, 161)
		headlight.Material=bool and Enum.Material.Neon or Enum.Material.Plastic
		for _,child in headlight:GetChildren() do 
			if child:IsA("SpotLight") or child:IsA("Beam") then
				child.Enabled=bool
			end
		end
		local taillight = car:FindFirstChild("Taillight")
		if not taillight then continue end
		taillight:WaitForChild("SpotLight").Enabled = bool
	end
end

function _G.updateLighting(mode,bool)
	if (mode == "night") then
		timeOfDay.Value = "night"
		currentInfo = nightInfo
		local sky = skyFolder:FindFirstChild(mode)
		if (sky) then -- replace the current sky
			local skyClone = sky:Clone()
			local oldSky = lighting:FindFirstChildWhichIsA("Sky")
			if (oldSky) then
				oldSky:Destroy()
			end
			skyClone.Parent = lighting
		end
	elseif (mode == "morning") then
		timeOfDay.Value = "morning"
		currentInfo = morningInfo
		local sky = skyFolder:FindFirstChild(mode)
		if (sky) then -- replace the current sky
			local skyClone = sky:Clone()
			local oldSky = lighting:FindFirstChildWhichIsA("Sky")
			if (oldSky) then
				oldSky:Destroy()
			end
			skyClone.Parent = lighting
		end
	elseif (mode == "underwater") then
		if (bool) then
			--local atmosphere = lighting:WaitForChild("atmosphere")
			--atmosphere.Density = .5
			--atmosphere.Haze = 10
			for i,v in (water:GetChildren()) do
				--v.Orientation = Vector3.new(0,-180,180)
				v.Transparency = 1
				v:FindFirstChild("Texture").Transparency = .5
				v.Orientation = Vector3.new(0,0,-180)
			end
			for i,v in (workspace:WaitForChild("Sand"):GetChildren()) do 
				local texture = v:WaitForChild("Texture")
				texture.Transparency = .5
			end
			rs:WaitForChild("underwater"):Play()
		elseif not (bool) then
			--local atmosphere = lighting:WaitForChild("atmosphere")
			--atmosphere.Density = 0
			--atmosphere.Haze = 0	
			for i,v in (water:GetChildren()) do
				v.Transparency = 0
				v:FindFirstChild("Texture").Transparency = 0
				v.Orientation = Vector3.new(0,0,0)
			end
			for i,v in (workspace:WaitForChild("Sand"):GetChildren()) do 
				local texture = v:WaitForChild("Texture")
				texture.Transparency = 1
			end
			rs:WaitForChild("underwater"):Stop()
		end
	end
	if (currentInfo) then
		for i,v in (currentInfo) do
			if (i == 11) then
				if not (player.Character) then repeat task.wait(1/30) until player.Character end
				local humanoid = player.Character:WaitForChild("Humanoid")
				if (humanoid.Health > 0) then
					v[1][v[2]] = v[3]
				else
					v[1][v[2]] = -1
				end
			else
				--ts:Create(v[1],TweenData6,v[2]):Play()
				v[1][v[2]] = v[3]		
			end
		end
	end
	for i,v in water:GetChildren() do 
		--80, 165, 239
		v:FindFirstChild("Texture").Color3=timeOfDay.Value=="morning" and Color3.fromRGB(83, 166, 255) or Color3.fromRGB(0, 172, 235)
		--v:FindFirstChild("Texture").Color3=timeOfDay.Value=="morning" and Color3.fromRGB(80, 165, 239) or Color3.fromRGB(0, 172, 235)
	end
end

timeEvent.OnClientEvent:Connect(function(t) -- this tell you if it's morning or night and gets the initial time when you join the game
	--print("yeet")
	_G.timeOfDay = t
	--print(t," is the current time of day")
	--audioOperator.updateTime(t)
	_G.updateLighting(t)
end)

water.ChildAdded:Connect(function(child)
	child:WaitForChild("Texture").Color3=timeOfDay.Value == "morning" and Color3.fromRGB(83, 166, 255) or Color3.fromRGB(0, 172, 235)
end)

while true do 
	task.wait(1)
	toggleRooftopLight()
	toggleStreetlights()
	toggleSpotlights()
	toggleRooftopBillboardLight()
	toggleCarLights(timeOfDay.Value=="night")
end