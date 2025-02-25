local rs = game:GetService("ReplicatedStorage")
local soundEvent = rs:WaitForChild("SoundEvent")
local player = game.Players.LocalPlayer

_G.playAbilitySound = function(character,action)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if action == "kick" then
		local sound = root:WaitForChild("kick_01")
		sound:Stop()
		sound:Play()
	elseif action == "projectile" then
		local shoot = root:WaitForChild("shoot")
		shoot:Stop()
		shoot:Play()
	elseif action == "travel" then
		local swing = root:WaitForChild("swing")
		swing:Stop()
		swing:Play()
	elseif action == "throw" then
		local sounds = {
			[1] = root:WaitForChild("swing_01"),
			[2] = root:WaitForChild("swing_02"),
			[3] = root:WaitForChild("swing_03")
		}
		local sound = sounds[math.random(1,3)] 
		sound:Stop()
		sound:Play()
	elseif action=="Gauntlet" then
		local gauntlet=character:FindFirstChild("Gauntlet")
		if not gauntlet or not gauntlet.PrimaryPart then return end
		gauntlet.PrimaryPart.Sound:Play()
		--print("played sound")
	end
end

soundEvent.OnClientEvent:Connect(function(ignorePlayer,action)
	if player == ignorePlayer then return end
	local character = ignorePlayer.Character
	if character then
		_G.playAbilitySound(character,action)
	end
end)
