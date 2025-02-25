local rs = game:GetService("ReplicatedStorage")
local electricEvent = rs:WaitForChild("ElectricEvent")

local ts = game:GetService("TweenService")
local lightTweenInfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,true,0)

local electricPart = rs:WaitForChild("electricImpact")
local particle = electricPart:WaitForChild("Bolts")
local sound = electricPart:WaitForChild("loop")
local pointlight = electricPart:WaitForChild("PointLight")

local cs = game:GetService("CollectionService")

local electrify = {} -- character, timer, bodyParts

local camera = workspace.CurrentCamera

local function electricHit(character,timer)
	--if cs:HasTag(character,"electrified") then return end
	--cs:AddTag(character,"electrified")
	local bodyParts = {
		character:WaitForChild("UpperTorso"),
		character:WaitForChild("LeftLowerLeg"),
		character:WaitForChild("RightLowerLeg"),
		character:WaitForChild("LeftLowerArm"),
		character:WaitForChild("RightLowerArm")
	}
	local function electrifyBodyParts(bool)
		for _,part in pairs(bodyParts) do 
			local _particle = part:FindFirstChild("Bolts")
			if bool == true then
				if not _particle then
					_particle = particle:Clone()
					_particle.Parent = part 
				end
				local pos = part.Position
				local vector, inViewport = camera:WorldToViewportPoint(pos)
				if (inViewport) then				
					_particle:Emit(1)
				end
			else 
				if _particle then _particle:Destroy() end
			end
			if part.Name == "UpperTorso" then
				--local _light = part:FindFirstChild("PointLight")
				local _sound = part:FindFirstChild("loop")
				if bool == true then
					--if not _light then
						--_light = pointlight:Clone()
						--_light.Parent = part
					--end
					if not _sound then
						_sound = sound:Clone()
						_sound.Parent = part 
					end
					--ts:Create(_light,lightTweenInfo,{Brightness = math.random(6,9)}):Play()
					if not _sound.IsPlaying then
						_sound:Play()
					end	
				else 
					--if _light then _light:Destroy() end 
					if _sound then _sound:Destroy() end					
				end
			end
		end
	end
	local start = tick()
	local player=game.Players:GetPlayerFromCharacter(character)
	if not player then return end
	
	--while workspace:GetServerTimeNow() - timer < 5 do 
		--if tick() - start >= .2 then 
			--if not cs:HasTag(character,"ragdolled") then break end
		--end
		--print("working")
		--electrifyBodyParts(true)
		--task.wait(.2)
	--end
	electrifyBodyParts(true)
	--cs:RemoveTag(character,"electrified")
end

electricEvent.OnClientEvent:Connect(electricHit)