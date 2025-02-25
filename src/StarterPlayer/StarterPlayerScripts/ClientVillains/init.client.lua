--!nocheck
local player = game.Players.LocalPlayer

local rs = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local cs = game:GetService("CollectionService")

local VenomAnimations = rs:WaitForChild("VenomAnimations")
local jumpAnimation = VenomAnimations:WaitForChild("Jump")
local runAnimation = VenomAnimations:WaitForChild("Run")
local idleAnimation = VenomAnimations:WaitForChild("Idle")
local landedAnimation = VenomAnimations:WaitForChild("Landed")
local roarAnimation = VenomAnimations:WaitForChild("Roar")
local smashAnimation = VenomAnimations:WaitForChild("Ground Smash")
local attackAnimation = VenomAnimations:WaitForChild("Attack")
local hitAnimation = VenomAnimations:WaitForChild("Hit Reaction")

local ragdollAnimation = VenomAnimations:WaitForChild("Ragdoll")
local ragdollLoopAnimation = VenomAnimations:WaitForChild("Ragdoll Loop")

local villains = workspace:WaitForChild("Villains")
local villain = nil
local effects = require(rs:WaitForChild("Effects"))

local function findVillain()
	for _,_villain in pairs(villains:GetChildren()) do 
		if _villain and _villain.PrimaryPart then
			villain = _villain
		end
	end
end

local villains_names={
	["isVenom"]="Venom",
	["isGreenGoblin"]="Green Goblin",
	["isDocOck"]="Doc Ock"
}

local ClientVillainProfiles=require(script:WaitForChild("ClientVillainProfiles"))

while true do
	--local success,errorMessage = pcall(function()
	local villain_name=nil
	if villain and villain.PrimaryPart then
		for name,actual in villains_names do 
			if villain:FindFirstChild(name) then
				villain_name=actual
				break
			end
		end
		if villain_name then
			ClientVillainProfiles[villain_name].runtime(villain)
		end
	else 
		findVillain()
	end		
	--end)
	task.wait()
end