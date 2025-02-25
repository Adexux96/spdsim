local rs = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local Multiverse_Remote = rs:WaitForChild("Multiverse_Event")

local function resetTicks(part)
	for _,particle in (part:GetDescendants()) do
		if (particle:IsA("ParticleEmitter")) then
			particle.tick.Value = 0
		end
	end
end

local runService = game:GetService("RunService")

local function startBlackHole(blackHole)
	local max_brightness = 2
	local start = tick()
	local duration = 5
	local pause = 1/60
	local max_time = 1/pause
	local iteration = 0
	
	blackHole:WaitForChild("Attachment"):WaitForChild("Sound"):Play()
	
	local camera = workspace.CurrentCamera
	local pointLight = blackHole:WaitForChild("Attachment"):WaitForChild("PointLight")
	
	while tick() - start < duration do
		for _,particle in (blackHole:GetDescendants()) do
			if (particle:IsA("ParticleEmitter")) then
				local t = (max_time/particle.Rate) * pause
				local amount = 0
				local particleTick = particle:WaitForChild("tick")
				if (tick() - particleTick.Value > t) then -- enough time has passed, you can emit now
					particleTick.Value = tick()
					amount = 1
					particle:Emit(amount)
					--[[
					local portalPosition = particle.Parent.WorldPosition
					local vector, inViewport = camera:WorldToViewportPoint(portalPosition)
					if (inViewport) then
						local castPoints = {portalPosition}
						local ignoreList = {}
						local partsObscuring = camera:GetPartsObscuringTarget(castPoints,ignoreList)
						if (#partsObscuring > 0) then
							local foundBuilding = false
							for _,part in (partsObscuring) do 
								if (part:IsDescendantOf(workspace:WaitForChild("Buildings"))) then 
									foundBuilding = true
									break
								end
							end
							if foundBuilding then 
								amount = 0
							end
						end				
						
					end
					]]
				end
			end
		end
		local p = math.clamp((tick() - start)/(pause*100),0,1)
		pointLight.Brightness = math.clamp(p * max_brightness,0,max_brightness)
		runService.RenderStepped:Wait()
	end
	
	blackHole:Destroy()
end

Multiverse_Remote.OnClientEvent:Connect(function(part)
	if part == nil then --[[print("part was nil")]] return end
	if not _G.cash_changed then return end
	_G.cash_changed("A multiverse portal has opened in the city!")
	local clone = rs:WaitForChild("Particles"):WaitForChild("blackhole"):Clone()
	local offset=Vector3.new(0,15,0)
	clone.CFrame = CFrame.new(part.Position+offset,workspace:WaitForChild("blocks"):WaitForChild("middle").Position+offset)
	clone.Parent = workspace:WaitForChild("BlackHoles")
	startBlackHole(clone)
end)
