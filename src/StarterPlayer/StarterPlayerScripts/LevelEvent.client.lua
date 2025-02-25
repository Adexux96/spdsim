local rs = game:GetService("ReplicatedStorage")
local levelEvent = rs:WaitForChild("LevelEvent")
local levelBeacon = rs:WaitForChild("LevelBeacon")

local ts = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0)

local clock = rs:WaitForChild("clock")

local camera = workspace.CurrentCamera

levelEvent.OnClientEvent:Connect(function(player)
	local character = player.Character
	if not character or not character.PrimaryPart then return end
	local isLevellingUp = character:GetAttribute("LevelUp")
	if isLevellingUp then return end
	character:SetAttribute("LevelUp",true)
	local hrp = character:WaitForChild("HumanoidRootPart")
	local beaconClone = levelBeacon:Clone()
	beaconClone.Position = (hrp.Position - Vector3.new(0,3,0))
	beaconClone.Parent = workspace 

	beaconClone:WaitForChild("Sound"):Play()

	local light = beaconClone.PointLight
	local particles = {
		beaconClone.Sparkles,
		beaconClone.start.Ray,
		--beaconClone.start.slash
	}

	local middleBeam = beaconClone.middle
	middleBeam.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0,1),
		NumberSequenceKeypoint.new(.1,1), -- change this
		NumberSequenceKeypoint.new(.5,1),
		NumberSequenceKeypoint.new(1,1),
	}
	local outerBeam = beaconClone.outer
	outerBeam.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0,1),
		NumberSequenceKeypoint.new(.1,1), -- change this
		NumberSequenceKeypoint.new(1,1),
	}
	local twirlyBeam = beaconClone.twirly
	twirlyBeam.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0,1),
		NumberSequenceKeypoint.new(.1,1), -- change this
		NumberSequenceKeypoint.new(1,1),
	}

	local pause = 1/60
	local max_time = 1/pause
	local duration = 1.5
	local start = tick()
	local finish = nil

	local changedAttribute = false
	local moveTween=nil
	while true do
		if not character or not character.PrimaryPart then break end
		if tick() - start >= 2 then
			if not changedAttribute then
				character:SetAttribute("LevelUp",false)
				changedAttribute = true
			end
		end
		local p = nil
		local beamTransparency = nil
		local lightBrightness = nil
		if tick() - start < duration then
			p = math.clamp((tick() - start) / 1,0,1)
			beamTransparency = math.clamp(1-p,0,1)
			lightBrightness = math.clamp(p*1,0,1)
			for _,particle in pairs(particles) do
				local t = (max_time/particle.Rate) * pause
				local amount = 0
				local particleTick = particle:WaitForChild("tick")
				if (tick() - particleTick.Value > t) then -- enough time has passed, you can emit now
					particleTick.Value = tick()
					amount = 1
					local pos = character.PrimaryPart.Position
					local vector, inViewport = camera:WorldToViewportPoint(pos)
					if (inViewport) then
						local castPoints = {pos}
						local ignoreList = {}
						local partsObscuring = camera:GetPartsObscuringTarget(castPoints,ignoreList)
						if (#partsObscuring > 0) then
							local foundBuilding = false
							for _,part in pairs(partsObscuring) do 
								if (part:IsDescendantOf(workspace:WaitForChild("Buildings"))) then 
									foundBuilding = true
									break
								end
							end
							if foundBuilding then 
								amount = 0
							end
						end				
						particle:Emit(amount)
					end
				end
			end
		else 
			if not tonumber(finish) then
				finish = tick()
			end
			p = math.clamp((tick() - finish) / 1,0,1)
			beamTransparency = p
			lightBrightness = math.clamp(1-p,0,1)
			if tick() - finish >= 2 then
				break
			end
		end

		light.Brightness = lightBrightness
		middleBeam.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0,1),
			NumberSequenceKeypoint.new(.1,beamTransparency), -- change this
			NumberSequenceKeypoint.new(.5,1),
			NumberSequenceKeypoint.new(1,1),
		}
		outerBeam.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0,1),
			NumberSequenceKeypoint.new(.1,beamTransparency), -- change this
			NumberSequenceKeypoint.new(1,1),
		}
		twirlyBeam.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0,1),
			NumberSequenceKeypoint.new(.1,beamTransparency), -- change this
			NumberSequenceKeypoint.new(1,1),
		}
		if moveTween then
			moveTween:Destroy()
			moveTween=nil
		end
		moveTween=ts:Create(beaconClone,tweenInfo,{Position = (hrp.Position - Vector3.new(0,3,0))})
		moveTween:Play()
		clock:GetPropertyChangedSignal("Value"):Wait()
	end
	beaconClone:Destroy()
end)