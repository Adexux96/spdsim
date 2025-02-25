local rs =game:GetService("ReplicatedStorage")
local animsFolder = rs:WaitForChild("animations"):WaitForChild("Folder")
--local idleAnim = animsFolder:WaitForChild("fight_idle")

local characters = workspace:WaitForChild("characters")

for _,character in (characters:GetChildren()) do 
	if character.Name == "Iron Spider" then
		local spiderLegs = character:WaitForChild("SpiderLegs")
		local animationController = spiderLegs:WaitForChild("AnimationController")
		local idleAnim = animationController:WaitForChild("Animations"):WaitForChild("Idle")
		local idle = animationController:LoadAnimation(idleAnim)
		idle:Play()
	end
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	local _type=character:WaitForChild("Type").Value
	local idle = character.Name:match("Punk") and humanoid:LoadAnimation(animsFolder:WaitForChild("punk_pose")) or humanoid:LoadAnimation(animsFolder:WaitForChild(_type))
	idle.Priority=Enum.AnimationPriority.Core
	idle:Play()
	local speed=character.Name=="cop" and .1 or 1
	local anim=animsFolder:FindFirstChild(character.Name)
	if not anim then continue end
	local idle = humanoid:LoadAnimation(anim)
	idle.Priority=Enum.AnimationPriority.Idle
	idle:Play(.1,1,speed)
end
