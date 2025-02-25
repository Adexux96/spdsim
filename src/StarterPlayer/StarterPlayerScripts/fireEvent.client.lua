local rs = game:GetService("ReplicatedStorage")
local FireEvent = rs:WaitForChild("FireEvent")

local cs = game:GetService("CollectionService")

local effectsPart = rs:WaitForChild("Particles"):WaitForChild("fireEffect")

local function event(character,bool)
	if game.Players:GetPlayerFromCharacter(character) then
		if bool == true and cs:HasTag(character,"onFire") then return end
		if bool then
			cs:AddTag(character,"onFire")
		end
		local upperTorso = character:WaitForChild("UpperTorso")
		local particle = upperTorso:FindFirstChild("Fire")
		if bool then
			if not particle then
				particle = effectsPart:WaitForChild("Fire"):Clone()
				particle.Parent = upperTorso				
			end
		else
			if particle then
				particle:Destroy()
			end
		end
		local light = upperTorso:FindFirstChild("Light")
		if bool then
			if not light then
				light = effectsPart:WaitForChild("Light"):Clone()
				light.Parent = upperTorso				
			end
		else 
			if light then
				light:Destroy()
			end
		end
		if not bool then
			cs:RemoveTag(character,"onFire")
		end
	end
end

FireEvent.OnClientEvent:Connect(event)