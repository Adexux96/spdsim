local rs=game:GetService("ReplicatedStorage")
local cape=rs:WaitForChild("Cape")
local cape_part=rs:WaitForChild("Cape_Part")

local clock=rs:WaitForChild("clock")

local capes={}

local function Wear_Cape(character)
	local player=game.Players:GetPlayerFromCharacter(character)
	if not player then return end
	
	--local leaderstats=player:WaitForChild("leaderstats")
	--local temp=leaderstats:WaitForChild("temp")
	--local isWebbing=temp:WaitForChild("isWebbing")
	
	local uppertorso=character:WaitForChild("UpperTorso")
	local head=character:WaitForChild("Head")
	local clone=cape:Clone()
	clone.PrimaryPart.CFrame=uppertorso.CFrame*clone.offset.Value
	clone.Parent=character
	local weld=Instance.new("WeldConstraint")
	weld.Name="capeWeld"
	weld.Part0=clone.PrimaryPart
	weld.Part1=uppertorso 
	weld.Parent=character
	
	local p=rs:WaitForChild("CapePart"):Clone()
	p.Parent=character
	
	local motor=Instance.new("Motor",p)
	motor.Part0=p
	motor.Part1=uppertorso
	motor.MaxVelocity=0
	motor.C0=CFrame.new(0,2,-.25)*CFrame.Angles(0,math.rad(90),0)
	motor.C1=CFrame.new(0,1,0.45)*CFrame.Angles(0,math.rad(90),0)
	
	local root=clone:WaitForChild("Mesh"):WaitForChild("Root")
	
	local bones={
		[1]={root.A1,root.A2,root.A3,root.A4},
		[2]={root.A5,root.A6,root.A7,root.A8},
		[3]={root.A9,root.A10,root.A11,root.A12},
		[4]={root.A13,root.A14,root.A15,root.A16}
	}
	
	capes[character.Name]={
		cape=clone,
		root=root,
		neck=root:WaitForChild("Neck"),
		character=character,
		head=character:WaitForChild("fakeHead"),
		part=p,
		bones=bones,
		lastSpeed=0,
		lastEmit=tick()-2
	}
	
end

local runservice=game:GetService("RunService")

local function lerp(start,goal,alpha)
	return ((goal-start)*alpha)+start
end

local function updateBones(root,part,bones,velocity,lastSpeed)
	local fastest=9
	local slowest=2
	local newSpeed=math.clamp((velocity/50)*fastest,slowest,fastest)
	local speed=lerp(lastSpeed,newSpeed,.1)
	for r,row in bones do 
		local rowP=r/#bones
		local offset=.75*rowP*rowP
		local degrees=speed
		local _p=(r-1)/(#bones-1)
		local p=1-(_p*.25)
		for b,bone in row do 
			local last=bone:FindFirstChild("last") 
			if not last then continue end
			local boneP=(b-1)/(#row-1)
			local increase=speed*(boneP*offset)
			local rotation=degrees+increase
			local attachment=part:FindFirstChild(bone.Name)
			local pos=attachment.WorldPosition
			local _cf=attachment.WorldCFrame
			if lastSpeed==0 then
				last.Value=CFrame.fromMatrix(pos,_cf.RightVector*-1,_cf.UpVector*-1)
			end
			local x,y,z=last.Value:ToOrientation()
			local cf=CFrame.new(pos)*CFrame.fromOrientation(x,y,z)*CFrame.Angles(math.rad(rotation/2),0,math.rad(rotation))
			last.Value=last.Value:Lerp(cf,p)
			local newCF=last.Value*CFrame.new(offset+(offset*(speed/fastest)),0,0)
			bone.WorldCFrame=CFrame.fromMatrix(newCF.Position,_cf.RightVector*-1,_cf.UpVector*-1)
		end 
	end
	return speed
end

local function emitMagicCircles(character,lastEmit)
	local LeftLowerArm=character:FindFirstChild("LeftLowerArm")
	local RightLowerArm=character:FindFirstChild("RightLowerArm")
	local LeftWristAttachment=LeftLowerArm and LeftLowerArm:FindFirstChild("LeftWristRigAttachment") or nil
	local RightWristAttachment=RightLowerArm and RightLowerArm:FindFirstChild("RightWristRigAttachment") or nil
	local LeftMagicCircle=LeftWristAttachment and LeftWristAttachment:FindFirstChild("magic_circle") or nil
	local RightMagicCircle=RightWristAttachment and RightWristAttachment:FindFirstChild("magic_circle") or nil
	if not LeftMagicCircle or not RightMagicCircle then return lastEmit end
	local elapsed=tick()-lastEmit
	if elapsed<2.7 then return lastEmit end
	local camera=workspace.CurrentCamera
	local vector, left = camera:WorldToScreenPoint(LeftWristAttachment.WorldPosition)
	local vector, right = camera:WorldToScreenPoint(RightWristAttachment.WorldPosition)
	if left then
		LeftMagicCircle:Emit(1)
	end
	if right then
		RightMagicCircle:Emit(1)
	end
	return tick()
end

local function checkPlayers()
	for _,plr in game.Players:GetPlayers() do 
		local character=plr.Character
		if not character or not character.PrimaryPart then continue end
		local suit=character:FindFirstChild("Suit")
		if not suit then continue end
		if suit.Value~="Supreme Sorcerer" then continue end
		if plr.Character:GetAttribute("Cape") then continue end
		Wear_Cape(plr.Character)
		plr.Character:SetAttribute("Cape",true)
	end
end

local n=0
while true do 
	n+=1
	--runservice.Stepped:Wait()
	clock:GetPropertyChangedSignal("Value"):Wait()
	if n%2==0 then -- 30fps player check
		checkPlayers()
	end
	for i,data in capes do
		local primarypart=data.character.PrimaryPart
		if not primarypart or not data.cape then 
			if data.cape then data.cape:Destroy() end
			data.character:SetAttribute("Cape",false) 
			continue 
		end
		
		local speed=primarypart.Velocity.Magnitude
		local p=math.clamp(speed/50,0,1)
		local goal=-1*p
		
		local motor=data.part.Motor
		local angle=lerp(motor.CurrentAngle,goal,.05)
		angle=math.clamp(angle,-1,-.1)
		motor.CurrentAngle=angle
		
		data.lastEmit=emitMagicCircles(data.character,data.lastEmit)
		data.lastSpeed=updateBones(data.root,data.part,data.bones,speed,data.lastSpeed)
		local cf=data.head.CFrame*CFrame.new(0,-.5,-.05)
		data.neck.WorldCFrame=cf
		
	end
end
