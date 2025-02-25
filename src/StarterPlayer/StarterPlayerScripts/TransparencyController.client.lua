local camera = workspace.CurrentCamera
local player = game.Players.LocalPlayer

local rs = game:GetService("ReplicatedStorage")

local OTS_running = rs:WaitForChild("OTS_running")
local characterTransparency = rs:WaitForChild("characterTransparency")

local function isFirstPerson(head)
	return (head.CFrame.p - camera.CFrame.p).Magnitude < 1.5
end

local Gauntlet_Ignore={
	["RightHand"]=true,
	["RightLowerArm"]=true
}
local ignore={
	["HumanoidRootPart"]=true,
	["RootLegs"]=true
}
local ignoreTools={
	["Gauntlet"]=true,
	["WebBombTool"]=true,
	["AntiGravityTool"]=true,
	["SpiderDroneTool"]=true
}

local function changeCharacterTransparency()
	local value = characterTransparency.Value
	local character = player.Character 
	if not player.Character then return end
	for _,v in pairs(character:GetDescendants()) do
		if v.Name=="CapePart" then continue end
		if not v:IsA("BasePart") then continue end
		if ignoreTools[v.Parent.Name] or ignoreTools[v.Parent.Parent.Name] then continue end
		if character:FindFirstChild("Gauntlet") and Gauntlet_Ignore[v.Name] then continue end
		if ignore[v.Name] then continue end
		--print(v.Name)
		if character:FindFirstChild("Suit") then
			if v.Name ~= "Head" then
				v.Transparency = value
				v.LocalTransparencyModifier = value
			end
		else
			v.Transparency = value
			v.LocalTransparencyModifier = value
		end	
	end
end

characterTransparency:GetPropertyChangedSignal("Value"):Connect(changeCharacterTransparency)

if not _G.updateCharacterInvis then 
	repeat task.wait(1/30) until _G.updateCharacterInvis
end

while true do 
	local character = player.Character 
	if character then
		local head = character:WaitForChild("Head")
		if character:FindFirstChild("Suit") then
			head.Transparency = 1
			head.LocalTransparencyModifier = 1
		end
		if not OTS_running.Value then -- ots isn't running you can run this function
			if isFirstPerson(head) then
				_G.updateCharacterInvis(character,1)
			else 
				_G.updateCharacterInvis(character,0)
			end
		else 
			OTS_running:GetPropertyChangedSignal("Value"):Wait() -- pause this thread till the value changes to false
		end
	end
	task.wait(1/30)
end
