--!nocheck
local players=game.Players 
local player=game.Players.LocalPlayer
local rs=game:GetService("ReplicatedStorage")

local items={
	["Anti Gravity"]={
		add=function(character)
			local RightHand=character:FindFirstChild("RightHand")
			if not RightHand then return end
			local RightGripAttachment=RightHand:FindFirstChild("RightGripAttachment")
			if not RightGripAttachment then return end
			local item=rs:WaitForChild("AntiGravityTool"):Clone()
			item.Name="Anti Gravity"
			item.CFrame=RightGripAttachment.WorldCFrame*CFrame.new(-.2,0,0)*CFrame.Angles(math.rad(-90),math.rad(0),math.rad(0))
			local weld=Instance.new("WeldConstraint")
			weld.Part0=item
			weld.Part1=RightHand
			weld.Parent=item
			item.Parent=character
		end,
		remove=function(character)
			local tool=character:FindFirstChild("Anti Gravity")
			if tool then tool:Destroy() end
		end,
	},
	["Spider Drone"]={
		add=function(character)
			local RightHand=character:FindFirstChild("RightHand")
			if not RightHand then return end
			local RightGripAttachment=RightHand:FindFirstChild("RightGripAttachment")
			if not RightGripAttachment then return end
			local item=rs:WaitForChild("SpiderDroneTool"):Clone()
			item.Name="Spider Drone"
			if item:FindFirstChild("Propeller") then
				item.Propeller.Transparency = 0
				item.Propeller.blur.SurfaceGui.Enabled = false
			end
			item:SetPrimaryPartCFrame(RightGripAttachment.WorldCFrame*CFrame.new(0,.1,-.1)*CFrame.Angles(math.rad(-90),math.rad(0),math.rad(0)))
			local weld=Instance.new("WeldConstraint")
			weld.Part0=item.PrimaryPart
			weld.Part1=RightHand
			weld.Parent=item.PrimaryPart
			item.Parent=character
		end,
		remove=function(character)
			local tool=character:FindFirstChild("Spider Drone")
			if tool then
				tool:Destroy()
			end
		end,
	},
	["Web Bomb"]={
		add=function(character)
			local RightHand=character:FindFirstChild("RightHand")
			if not RightHand then return end
			local RightGripAttachment=RightHand:FindFirstChild("RightGripAttachment")
			if not RightGripAttachment then return end
			local item=rs:WaitForChild("WebBombTool"):Clone()
			item.Name="Web Bomb"
			item.CFrame=RightGripAttachment.WorldCFrame*CFrame.new(-.2,0,0)*CFrame.Angles(math.rad(-90),math.rad(0),math.rad(0))
			local weld=Instance.new("WeldConstraint")
			weld.Part0=item
			weld.Part1=RightHand
			weld.Parent=item
			item.Parent=character
		end,
		remove=function(character)
			local tool=character:FindFirstChild("Web Bomb")
			if tool then tool:Destroy() end
		end,
	},
	["Gauntlet"]={
		add=function(character)
			local RightLowerArm=character:FindFirstChild("RightLowerArm")
			local RightHand=character:FindFirstChild("RightHand")
			if RightLowerArm and RightHand then
				local item=rs:WaitForChild("Gauntlet"):Clone()
				item.PrimaryPart.CFrame=RightLowerArm.CFrame*CFrame.new(.225,-.6,-.2)*CFrame.Angles(math.rad(0),math.rad(12),math.rad(12))
				local weld=Instance.new("WeldConstraint")
				weld.Part0=item.PrimaryPart
				weld.Part1=RightLowerArm
				weld.Parent=item.PrimaryPart
				item.PrimaryPart.Anchored=false
				item.PrimaryPart.CanCollide=false
				item.Parent=character
				RightLowerArm.Transparency=1
				RightLowerArm.LocalTransparencyModifier=1
				RightHand.Transparency=1
				RightHand.LocalTransparencyModifier=1
			end
		end,
		remove=function(character)
			local RightLowerArm=character:FindFirstChild("RightLowerArm")
			local RightHand=character:FindFirstChild("RightHand")
			local UpperTorso=character:FindFirstChild("UpperTorso")
			if RightLowerArm and RightHand then
				RightLowerArm.Transparency=UpperTorso.Transparency
				RightLowerArm.LocalTransparencyModifier=UpperTorso.LocalTransparencyModifier
				RightHand.Transparency=UpperTorso.Transparency
				RightHand.LocalTransparencyModifier=UpperTorso.LocalTransparencyModifier
				local tool=character:FindFirstChild("Gauntlet")
				if tool then -- destorys the weld inside as well
					tool:Destroy()
				end
			end		
		end,
	},
}

--[[
if temp.WebBombEquipped.Value then 
	local serverBomb = character:WaitForChild("ServerWebBomb")
	serverBomb:WaitForChild("Handle").Transparency = 0
	--serverBomb:WaitForChild("Handle"):WaitForChild("PointLight").Enabled = true
end

if temp.GravityBombEquipped.Value then
	local serverBomb = character:WaitForChild("ServerGravityBomb")
	serverBomb:WaitForChild("Handle").Transparency = 0
	--serverBomb:WaitForChild("Handle"):WaitForChild("PointLight").Enabled = true
end

if temp.SpiderDroneEquipped.Value then
	local SpiderDrone = character:WaitForChild("ServerSpiderDrone")
	local handle = SpiderDrone:WaitForChild("Handle")
	handle.Transparency = 0
	handle:WaitForChild("Propeller").Transparency = 0
	handle:WaitForChild("Propeller"):WaitForChild("blur"):WaitForChild("SurfaceGui").Enabled = true
	--handle:WaitForChild("SpotLight").Enabled = true
end
]]

		--[[
		local webBomb = rs:WaitForChild("WebBombTool"):Clone()
		webBomb.Name = "ServerWebBomb"
		if webBombEquipped.Value == false then
			webBomb.Handle.Transparency = 1		
		end
		webBomb.Parent = character

		local gravityBomb = rs:WaitForChild("AntiGravityTool"):Clone()
		gravityBomb.Name = "ServerGravityBomb"
		if gravityBombEquipped.Value == false then
			gravityBomb.Handle.Transparency = 1		
		end
		gravityBomb.Parent = character

		local spiderDrone = rs:WaitForChild("SpiderDroneTool"):Clone()
		spiderDrone.Name = "ServerSpiderDrone"
		if spiderDroneEquipped.Value == false then
			spiderDrone.Handle.Transparency = 1
			spiderDrone.Handle.Propeller.Transparency = 1
			spiderDrone.Handle.Propeller.blur.SurfaceGui.Enabled = false			
		end
		spiderDrone.Parent = character
		]]

local function removeItem(player:Player, character:Model, name:string)
	local exists=character:FindFirstChild(name)
	if name=="Gauntlet" then
		local RightLowerArm=character:FindFirstChild("RightLowerArm")
		local RightHand=character:FindFirstChild("RightHand")
		local UpperTorso=character:FindFirstChild("UpperTorso")
		if RightLowerArm and RightHand then
			RightLowerArm.Transparency=UpperTorso.Transparency
			RightLowerArm.LocalTransparencyModifier=UpperTorso.LocalTransparencyModifier
			RightHand.Transparency=UpperTorso.Transparency
			RightHand.LocalTransparencyModifier=UpperTorso.LocalTransparencyModifier
			if exists then
				exists:Destroy()
			end
		end
	else 
		if exists then
			exists:Destroy()
		end
	end
end

local function ManageEquippables()
	for _,plr in players:GetPlayers() do 
		if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
		local character=plr.Character
		local leaderstats=plr:WaitForChild("leaderstats")
		local temp=leaderstats:WaitForChild("temp")
		local Equippables=temp:WaitForChild("Equippables")
		for _,value in Equippables:GetChildren() do 
			if value.Value then
				if not character:FindFirstChild(value.Name) then -- it doesn't exist
					items[value.Name].add(character)
				end
			else 
				if character:FindFirstChild(value.Name) then -- it already exists
					items[value.Name].remove(character)
				end
			end
		end
	end
end

while true do 
	ManageEquippables()
	task.wait(1/10)
end
