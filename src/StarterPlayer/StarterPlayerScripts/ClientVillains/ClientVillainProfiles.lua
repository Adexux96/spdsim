local cs=game:GetService("CollectionService")
local runService=game:GetService("RunService")
local rs=game:GetService("ReplicatedStorage")
local effects=require(rs:WaitForChild("Effects"))
local m=require(rs:WaitForChild("math"))

local ragdoll=require(rs:WaitForChild("ragdoll"))

local debris=game:GetService("Debris")

local ts=game:GetService("TweenService")
local tweeninfo=TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
local tween=.1

local camera=workspace.CurrentCamera

local VenomAnimations=rs:WaitForChild("VenomAnimations")
local GoblinAnimations=rs:WaitForChild("GoblinAnimations")
local DocAnimations=rs:WaitForChild("DocAnimations")

local ClientVillainProfiles = {}

local function getPlayingAnimations(controller)
	local dict = {}
	for _,track in pairs(controller:GetPlayingAnimationTracks()) do 
		dict[track.Animation.Name] = track
	end
	return dict
end

local function ray(origin,direction,whitelist)
	local raycastParams = RaycastParams.new()
	whitelist=whitelist or {
		workspace:WaitForChild("BuildingBounds"),
		workspace:WaitForChild("blocks"),
		workspace:WaitForChild("Concrete")
	}
	raycastParams.FilterDescendantsInstances = whitelist
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local headTween=nil
local function tweenFalseHead(head,cframe)
	local ts = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0)
	if headTween then
		headTween:Destroy()
		headTween=nil
	end
	headTween = ts:Create(head,tweenInfo,{CFrame = cframe})
	headTween:Play()	
end

local randomGenerator = Random.new()

local function UpdateVenomCollisionBox(villain)
	local VenomCollisionPart=villain:FindFirstChild("CollisionPart")
	local bones=villain:WaitForChild("Body"):WaitForChild("Bones")
	local root=bones:WaitForChild("Root").Value
	local rootCF=CFrame.fromMatrix(root.WorldPosition,root.WorldCFrame.RightVector*-1,root.WorldCFrame.UpVector)
	local function greatest(a,b)
		return a[1] > b[1]
	end
	local axes={
		["X"]={},
		["Y"]={},
		["Z"]={}
	}
	local function add(a,b,axis,info)
		axes[axis][#axes[axis]+1]={math.abs(a:ToObjectSpace(b).Position[axis]),info}
	end
	for i1,v1 in bones:GetChildren() do 
		for i2,v2 in bones:GetChildren() do
			for i3,v3 in axes do
				add(CFrame.fromMatrix(v1.Value.TransformedWorldCFrame.Position,rootCF.RightVector,rootCF.UpVector),CFrame.fromMatrix(v2.Value.TransformedWorldCFrame.Position,rootCF.RightVector,rootCF.UpVector),i3,{v1.Value,v2.Value})
			end
		end
	end

	--// if math.abs(from_root)>=half_distance :
	--// if from_root>=0 :
	--// greater goes first
	--// elseif from_root<0 :
	--// lesser goes first
	--// elseif math.abs(from_root)<half_distance :
	--// if from_root>=0 :
	--// lesser goes first
	--// elseif from_root<0 :
	--// greater goes first

	local size={X=0,Y=0,Z=0}
	local offset={X=0,Y=0,Z=0}
	for axis,v in axes do 
		table.sort(axes[axis],greatest) 
		local distance,parts=axes[axis][1][1],axes[axis][1][2]
		local a,b=rootCF,CFrame.fromMatrix(parts[1].TransformedWorldCFrame.Position,rootCF.RightVector,rootCF.UpVector)
		local from_root=a:ToObjectSpace(b).Position[axis]
		local half_distance=distance/2
		local abs_root=math.abs(from_root)
		local result=math.abs(abs_root-half_distance)
		offset[axis]=abs_root>=half_distance and result*(from_root>=0 and 1 or -1) or (result*(from_root>=0 and -1 or 1))
		size[axis]=math.clamp(distance,2,math.huge)
	end
	VenomCollisionPart.CFrame=rootCF*CFrame.new(offset.X,offset.Y,offset.Z)
	VenomCollisionPart.Size=Vector3.new(size.X,size.Y,size.Z)
end

local function GenerateVenomCollisionBox(villain)
	local VenomCollisionPart=villain:FindFirstChild("CollisionPart")
	if not VenomCollisionPart then
		VenomCollisionPart=rs:WaitForChild("CollisionPart"):Clone()
		VenomCollisionPart.Parent=villain
	end
	UpdateVenomCollisionBox(villain)
end

local adjustCFTween=nil
local adjustCFTween2=nil
local function adjustCF(villain:Model)
	if not villain:FindFirstChild("HumanoidRootPart") then return end
	local properties=villain:WaitForChild("Properties")
	local venom_mesh_hrp=villain:WaitForChild("Body"):WaitForChild("HumanoidRootPart")
	local hrp=villain.PrimaryPart
	local offset=properties:WaitForChild("BodyOffset")
	local cf=hrp.CFrame*offset.Value
	if adjustCFTween then
		adjustCFTween:Destroy()
		adjustCFTween=nil
	end
	adjustCFTween=ts:Create(venom_mesh_hrp,tweeninfo,{CFrame=cf})
	adjustCFTween:Play()
end

local spineTween=nil
local function updateSpineC0(villain,RunningPath)
	if villain == nil or not villain.PrimaryPart then return end
	if spineTween then
		spineTween:Destroy()
		spineTween=nil
	end
	local properties = villain.Properties
	local health = properties.Health.Value
	local spineC0 = properties.spineC0
	local C0 = properties.C0
	local target = properties.Target
	if target.Value == nil then return end
	if target.Value:IsA("BasePart") or RunningPath or health == 0 or cs:HasTag(villain,"ragdolled") then
		local spine = properties.Spine.Value
		local spineC0 = properties.spineC0.Value
		spineTween=ts:Create(spine,tweeninfo,{CFrame = spineC0})
		spineTween:Play()
		--ts:Create(C0,tweeninfo,{Value = spineC0}):Play()
		--spine.CFrame = C0.Value
	elseif game.Players:GetPlayerFromCharacter(target.Value) and not RunningPath and health > 0 then
		if not target.Value.PrimaryPart then return end
		local targetPos = target.Value.PrimaryPart.Position
		local rootPos = villain.PrimaryPart.Position
		local spine = properties.Spine.Value
		local spineC0 = properties.spineC0.Value
		local direction = (targetPos - rootPos).Unit * 100
		local xAngle = -math.rad(direction.Y)*.625
		xAngle = math.clamp(xAngle,-.9,.75)
		spineTween=ts:Create(spine,tweeninfo,{CFrame = spineC0*CFrame.Angles(xAngle,0,0)})
		spineTween:Play()
		--ts:Create(C0,tweeninfo,{Value = spineC0*CFrame.Angles(xAngle,0,0)}):Play()
		--spine.CFrame = C0.Value
	end
end

local tentacle_module=require(script.Parent:WaitForChild("Tentacle"))
local function Generate_Venom_Mesh(villain)
	local hrp=villain:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local clone=rs:WaitForChild("VenomMesh"):Clone()
	clone.Name="Body"
	local root=clone.PrimaryPart.Root
	villain.Properties.Head.Value=root.Spine.Spine2.Spine3.Neck.Head
	villain.Properties.Spine.Value=root.Spine.Spine2
	clone:SetPrimaryPartCFrame(hrp.CFrame)
	clone.Parent=villain
	script.Parent:WaitForChild("Tentacle"):WaitForChild("Venom").Value=villain
	return clone
end

local function adjustGoblinCF(goblin,glider,villain)
	local properties=villain:FindFirstChild("Properties")
	local GliderOffset=properties and properties:FindFirstChild("GliderOffset") or nil
	local hoverYOffset=properties and properties:FindFirstChild("HoverYOffset") or nil
	if not GliderOffset then return end
	local cf=villain.PrimaryPart.CFrame*GliderOffset.Value
	
	--adjustCFTween=ts:Create(glider.PrimaryPart,tweeninfo,{CFrame=cf})
	local start=glider.PrimaryPart.CFrame
	local goal=cf*CFrame.new(0,hoverYOffset.Value,0)
	
	if cs:HasTag(goblin,"ragdolled") then
		goal=villain.PrimaryPart.CFrame*CFrame.new(0,-1.75,0)
	end
	
	glider.PrimaryPart.CFrame=start:Lerp(goal,tween)
	
	local bodyOffset=glider:FindFirstChild("BodyOffset")
	if not bodyOffset then return end
	local bodyCF=goal*bodyOffset.Value
	
	local start=goblin.PrimaryPart.CFrame
	local goal=bodyCF 
	
	if cs:HasTag(goblin,"ragdolled") then
		goal=villain.PrimaryPart.CFrame*CFrame.new(0,-1.75,0)
	end
	
	goblin:SetPrimaryPartCFrame(start:Lerp(goal,tween))
	
end

local function adjustGliderSound(glider,speed)
	--print("glider speed=",speed)
	local root=glider.PrimaryPart
	local sound=root and root:FindFirstChild("hover")
	if not sound then return end
	local p=math.clamp(speed/16,0,1)
	local s=.75+(p*.25)
	sound.PlaybackSpeed=m.lerp(sound.PlaybackSpeed,s,tween)
end

local function adjustDocCF(lowerTentacle,upperTentacle,Doc,villain)
	--print(lowerTentacle,Doc,villain)
	local properties=villain:FindFirstChild("Properties")
	local TentacleOffsets=properties and properties:FindFirstChild("TentacleOffsets") or nil
	local LowerTentacleOffset=TentacleOffsets and TentacleOffsets:FindFirstChild("Lower")
	local UpperTentacleOffset=TentacleOffsets and TentacleOffsets:FindFirstChild("Upper")
	if not LowerTentacleOffset or not UpperTentacleOffset then return end
	if not Doc then return end
	
	local BodyOffset=properties:FindFirstChild("BodyOffset")
	if not BodyOffset then return end
	
	--//CFrame for the Lower Tentacles
	local cf=villain.PrimaryPart.CFrame*LowerTentacleOffset.Value
	local lower_tentacle_cf=cf
	local start=lowerTentacle.PrimaryPart.CFrame
	lowerTentacle:SetPrimaryPartCFrame(start:Lerp(lower_tentacle_cf,tween))
	
	--// CFrame for the Body
	local LowerTentacleMain=lowerTentacle.PrimaryPart 
	local Arm1L=LowerTentacleMain:FindFirstChild("Arm1.L")
	local Arm1R=LowerTentacleMain:FindFirstChild("Arm1.R")
	if Arm1L==nil or Arm1R==nil then return end 
	local ReverseCF=LowerTentacleMain.CFrame*CFrame.Angles(math.rad(180),0,math.rad(180))
	local x,y,z=ReverseCF:ToOrientation()
	local middleCF=Arm1L.TransformedWorldCFrame:Lerp(Arm1R.TransformedWorldCFrame,.5)
	
	if cs:HasTag(Doc,"ragdolled") then
		local goal=villain.PrimaryPart.CFrame*CFrame.new(0,-1.75,0)
		Doc.PrimaryPart.CFrame=Doc.PrimaryPart.CFrame:Lerp(goal,tween)
	else 
		local lastRagdolled=Doc:GetAttribute("LastRagdolled")
		if lastRagdolled and tick()-lastRagdolled<=1 then -- give 1 sec for doc's body to gradually make it back up
			local goal=CFrame.new((middleCF*BodyOffset.Value).Position)*CFrame.fromOrientation(x,y,z)
			Doc.PrimaryPart.CFrame=Doc.PrimaryPart.CFrame:Lerp(goal,tween)
		else 
			Doc:SetAttribute("LastRagdolled",nil)
			Doc.PrimaryPart.CFrame=CFrame.new((middleCF*BodyOffset.Value).Position)*CFrame.fromOrientation(x,y,z)
		end
	end
	
	--// CFrame for the Upper Tentacles
	local UpperTorso=Doc:FindFirstChild("UpperTorso")
	if not UpperTorso then return end
	upperTentacle.PrimaryPart.CFrame=UpperTorso.CFrame*UpperTentacleOffset.Value
	
end

local function Generate_Doc_Ock(villain)
	--print("villain=",villain)
	local Doc=rs:WaitForChild("DocOck"):Clone()
	Doc.Name="Body"
	Doc.PrimaryPart.CFrame=villain.PrimaryPart.CFrame
	Doc.Parent=villain 
	
	local LowerTentacle=rs:WaitForChild("DocTentacle"):Clone()
	LowerTentacle.Name="LowerTentacle"
	LowerTentacle.PrimaryPart.CFrame=villain.PrimaryPart.CFrame
	LowerTentacle.Parent=villain
	
	local UpperTentacle=rs:WaitForChild("DocTentacle"):Clone()
	UpperTentacle.Name="UpperTentacle"
	UpperTentacle.PrimaryPart.CFrame=villain.PrimaryPart.CFrame
	UpperTentacle.Parent=villain
	
	adjustDocCF(LowerTentacle,UpperTentacle,Doc,villain)
	return LowerTentacle,UpperTentacle,Doc
end

local function setCollisions(model,collisiongroup)
	for index,part in pairs(model:GetDescendants()) do 
		if part:IsA("BasePart") then
			part.CollisionGroup=collisiongroup
		end
	end
end

local function Generate_Green_Goblin(villain)
	local Glider=rs:WaitForChild("Glider"):Clone()
	Glider.PrimaryPart.hover.Volume=.25
	Glider.Parent=villain
	local Goblin=rs:WaitForChild("GreenGoblin"):Clone()
	Goblin.Name="Body"
	Goblin.Parent=villain
	--setCollisions(Goblin,"Villains")
	--setCollisions(Glider,"Character")
	--ragdoll.disableAllStates(Goblin:WaitForChild("Humanoid"))
	adjustGoblinCF(Goblin,Glider,villain)
	return Goblin,Glider
end

local function Get_Goblin_Speed(glider) -- compare last position
	local elapsed=tick()-ClientVillainProfiles["Green Goblin"].last_step
	local ignoreY=Vector3.new(1,0,1)
	local travelled=((glider.PrimaryPart.Position*ignoreY)-(ClientVillainProfiles["Green Goblin"].last_pos*ignoreY)).Magnitude
	return (1/elapsed)*travelled
end

local function Get_Rotation(part,lastRotation) -- compare last rotation
	local _,y,_=part.CFrame:ToOrientation()
	local start,goal=math.deg(y),lastRotation
	local rotation=(goal-start+540)%360-180
	local direction=nil
	if math.round(rotation)==0 then
		direction="None"
	else 
		direction=math.round(rotation)>0 and "Right" or "Left"
	end
	return direction,math.round(rotation)
end

local function Adjust_Glider_Wings(glider,speed,rotation)
	-- pos x = forward tilt
	-- neg x = backward tilt
	-- left rotate = left wing goes up
	-- right rotate = right wing goes up
	
	local body=glider.PrimaryPart:WaitForChild("base"):WaitForChild("body")
	local leftWing=body:WaitForChild("LeftWing")
	local rightWing=body:WaitForChild("RightWing")
	
	local left_x=0
	local right_x=0
	
	if math.round(speed)>1 then -- you're moving
		left_x=16*math.clamp(speed/16,0,1)
		right_x=16*math.clamp(speed/16,0,1)
	end
	
	if rotation~="None" then -- you're rotating
		left_x=rotation=="Left" and -16 or left_x
		right_x=rotation=="Right" and -16 or right_x
	end
	
	local start=leftWing.Orientation
	local goal=Vector3.new(left_x,0,-90)
	leftWing.Orientation=start:Lerp(goal,tween)
	
	local start=rightWing.Orientation
	local goal=Vector3.new(right_x,0,90)
	rightWing.Orientation=start:Lerp(goal,tween)
	
end

local function Adjust_Waist(body,properties)
	local target=properties and properties:FindFirstChild("Target")
	local WaistC0=properties and properties:FindFirstChild("WaistC0")
	if not target or not target.Value or not WaistC0 then return end
	local UpperTorso=body and body:FindFirstChild("UpperTorso")
	local Root=body and body.PrimaryPart
	local Waist=UpperTorso and UpperTorso:FindFirstChild("Waist")
	if not Waist or not Root then return end
	local current=Waist.C0
	local goal=WaistC0.Value
	
	if not target.Value:IsDescendantOf(workspace:WaitForChild("nodes2")) and target.Value.PrimaryPart then
		local direction = (Root.Position - target.Value.PrimaryPart.Position).Unit * 100
		goal=WaistC0.Value*CFrame.Angles(-math.rad(direction.Y)*.525,0,0)
	end
	
	if cs:HasTag(body,"ragdolled") then
		goal=WaistC0.Value
	end
	
	Waist.C0=current:Lerp(goal,tween)
end

local function getCharacterModelsArray()
	local t = {}
	for _,plr in pairs(game.Players:GetPlayers()) do 
		t[#t+1] = plr.Character
	end
	return t
end

local function Get_Attackables_Array()
	local array = getCharacterModelsArray()
	local whitelist = {
		workspace.SpiderDrones
	}
	for _,value in pairs(whitelist) do 
		array[#array+1] = value
	end
	return array
end

local bounds={
	["BuildingBounds"]=true,
	["blocks"]=true,
	["Concrete"]=true
}

local function Get_Bounds_Whitelist()
	return {
		workspace:WaitForChild("BuildingBounds"),
		workspace:WaitForChild("blocks"),
		workspace:WaitForChild("Concrete")
	}
end

local function Get_Full_Ray_Whitelist()
	local array=Get_Attackables_Array()
	local whitelist={
		workspace:WaitForChild("BuildingBounds"),
		workspace:WaitForChild("blocks"),
		workspace:WaitForChild("Concrete")
	}
	for _,value in pairs(whitelist) do 
		array[#array+1] = value
	end
	return array
end

local function visualizeRay(origin,goal)
	local rayVisual = game.ReplicatedStorage:WaitForChild("rayVisual"):Clone()
	rayVisual.CFrame = CFrame.new(origin:Lerp(goal,.5),goal)
	rayVisual.Size = Vector3.new(0.25,0.25,(origin - goal).Magnitude)
	rayVisual.Transparency = 0.75
	rayVisual.BrickColor = BrickColor.Green()
	rayVisual.Material = Enum.Material.Neon
	rayVisual.Parent = workspace.detectRay
	game:GetService("Debris"):AddItem(rayVisual,5)
end

local function random1or3()
	return (m.nearest(m.defined(1,100))%3)+1
end

ClientVillainProfiles["Venom"]={
	animations={
		jumpAnimation = VenomAnimations:WaitForChild("Jump"),
		runAnimation = VenomAnimations:WaitForChild("Run"),
		idleAnimation = VenomAnimations:WaitForChild("Idle"),
		landedAnimation = VenomAnimations:WaitForChild("Landed"),
		roarAnimation = VenomAnimations:WaitForChild("Roar"),
		smashAnimation = VenomAnimations:WaitForChild("Ground Smash"),
		attackAnimation = VenomAnimations:WaitForChild("Attack"),
		hitAnimation = VenomAnimations:WaitForChild("Hit Reaction"),
		ragdollAnimation = VenomAnimations:WaitForChild("Ragdoll"),
		ragdollLoopAnimation = VenomAnimations:WaitForChild("Ragdoll Loop")
	},
	
	AdjustAnimationSpeed=function(villain,root,properties)
		local venomMesh = villain:WaitForChild("Body")
		local animationController = venomMesh.AnimationController
		--//local humanoid = villain:WaitForChild("Humanoid")
		local horizontalSpeed = (root.Velocity * Vector3.new(1,0,1)).Magnitude
		--//local verticalSpeed = (root.Velocity * Vector3.new(0,1,0)).Magnitude
		local playingAnimations = getPlayingAnimations(animationController)
		local runPlaying = playingAnimations["Run"]--playingAnimations["Run"]

		if not playingAnimations["Idle"] then
			--print("had to play idle")
			local idleAnim = animationController:LoadAnimation(ClientVillainProfiles["Venom"].animations.idleAnimation)
			idleAnim.Priority = Enum.AnimationPriority.Core
			idleAnim:Play(.1,1,.5)
		end	

		if horizontalSpeed > 1 then
			local minimumSpeed = 0--(properties.Target.Value ~= nil and properties.Target.Value:IsA("Attachment")) and 0 or .75 
			local maximumSpeed = 1
			local animSpeed = math.clamp(horizontalSpeed/32,minimumSpeed,maximumSpeed)
			local function eventReached()
				--local runSound = root:WaitForChild("run")
				--runSound.TimePosition = 0
				--runSound.Volume = animSpeed*.75
				--runSound.PlaybackSpeed = randomGenerator:NextNumber(1.3,1.5)
				if not cs:HasTag(villain,"ragdolled") then
					--runSound:Play()
				end
			end
			if not runPlaying then
				local runAnim = animationController:LoadAnimation(ClientVillainProfiles["Venom"].animations.runAnimation)
				runAnim.Priority = Enum.AnimationPriority.Idle
				runAnim:GetMarkerReachedSignal("Step1"):Connect(eventReached)
				runAnim:GetMarkerReachedSignal("Step2"):Connect(eventReached)
				runAnim:Play(.2,1,animSpeed)
			else
				runPlaying:AdjustSpeed(animSpeed)
				--local runSound = root:WaitForChild("run")
				--runSound.Volume = animSpeed*.75
			end
		else
			if runPlaying then
				runPlaying:Stop()
			end			
		end

	end,
	events=function(villain)
		if not villain then return end
		local eventsConnected = villain:WaitForChild("EventsConnected")
		if eventsConnected.Value then return end
		eventsConnected.Value = true
		local mesh = villain:WaitForChild("Body")
		local animationController = mesh:WaitForChild("AnimationController")
		local humanoid = villain:WaitForChild("Humanoid")
		local properties = villain:WaitForChild("Properties")
		local events = villain:WaitForChild("Events")

		local root = villain:WaitForChild("HumanoidRootPart")

		local ragdollValue = villain:WaitForChild("Ragdoll")
		events:WaitForChild("Ragdoll").OnClientEvent:Connect(function(ragdoll)
			local playingAnimations = getPlayingAnimations(animationController)
			local ragdollPlaying = playingAnimations["Ragdoll"]
			local ragdollLoopPlaying = playingAnimations["Ragdoll Loop"]
			if ragdoll then
				root:WaitForChild("hit"):Play()
				--print("start venom ragdoll")
				local animsNotPlaying = ragdollPlaying == nil and ragdollLoopPlaying == nil
				local notRagdolled = ragdollValue.Value == false
				if animsNotPlaying or notRagdolled then
					ragdollValue.Value = true
					local function eventReached()
						local ragdollLoopAnim = animationController:LoadAnimation(ClientVillainProfiles["Venom"].animations.ragdollLoopAnimation)
						ragdollLoopAnim.Priority = Enum.AnimationPriority.Action3 
						ragdollLoopAnim:Play(.2,1,1)
					end
					local ragdollAnim = animationController:LoadAnimation(ClientVillainProfiles["Venom"].animations.ragdollAnimation)
					ragdollAnim.Priority = Enum.AnimationPriority.Action2
					ragdollAnim:GetMarkerReachedSignal("End"):Connect(eventReached)
					ragdollAnim:Play(.2,1,.4)
				else 
					--print("ragdoll animations were still playing")
				end
			else
				if not (properties:WaitForChild("Health").Value > 0) then return end
				ragdollValue.Value = false
				--print("stop venom ragdoll")
				if ragdollPlaying then
					ragdollPlaying:Stop()
				end			
				if ragdollLoopPlaying then
					ragdollLoopPlaying:Stop()
				end
			end
		end)

		events:WaitForChild("Damage").OnClientEvent:Connect(function(action)
			if action == "Melee" then

				local head = properties:WaitForChild("Head")
				effects.MeleeEffect(head.Value.WorldPosition)
			elseif action == "Ragdoll" then
				-- play ragdoll animation
			end
		end)

		events:WaitForChild("Roar").OnClientEvent:Connect(function(timer)
			if cs:HasTag(villain,"ragdolled") then return end
			while workspace:GetServerTimeNow() - timer < .5 do
				runService.RenderStepped:Wait()
			end
			if cs:HasTag(villain,"ragdolled") then return end
			local roarAnim = animationController:LoadAnimation(ClientVillainProfiles["Venom"].animations.roarAnimation)
			roarAnim.Priority = Enum.AnimationPriority.Action
			roarAnim:Play(.2,1,.5)
			root:WaitForChild("roar"):Play()
		end)

		events:WaitForChild("Attack").OnClientEvent:Connect(function(timer)
			if not properties.Target.Value then return end
			if properties.Target.Value:IsA("Attachment") then return end
			if cs:HasTag(villain,"ragdolled") then return end
			while workspace:GetServerTimeNow() - timer < .5 do 
				runService.RenderStepped:Wait()
			end
			if properties.Target.Value:IsA("Attachment") then return end
			if cs:HasTag(villain,"ragdolled") then return end
			local function eventReached()
				if cs:HasTag(villain,"ragdolled") then return end
				root:WaitForChild("attack"):Play()
			end
			local attackAnim = animationController:LoadAnimation(ClientVillainProfiles["Venom"].animations.attackAnimation)
			attackAnim.Priority = Enum.AnimationPriority.Action2
			attackAnim:GetMarkerReachedSignal("Hit1"):Connect(eventReached)
			attackAnim:GetMarkerReachedSignal("Hit2"):Connect(eventReached)
			attackAnim:Play(.1,1,.75)
		end)

		events:WaitForChild("Smash").OnClientEvent:Connect(function(timer)
			if cs:HasTag(villain,"ragdolled") then return end
			if properties.Target.Value:IsA("Attachment") then return end
			while workspace:GetServerTimeNow() - timer < .5 do 
				runService.RenderStepped:Wait()
			end
			if cs:HasTag(villain,"ragdolled") then return end
			if properties.Target.Value:IsA("Attachment") then return end
			local function SmashReached()
				if cs:HasTag(villain,"ragdolled") then return end
				local origin = root.Position
				local goalCF = root.CFrame * CFrame.new(0,-100,0)
				local direction = (goalCF.Position - origin).Unit * 100
				local result = ray(origin,direction)
				
				--print("smash effect!")

			--[[
			local rayVisual = rs:WaitForChild("rayVisual"):Clone()
			rayVisual.CFrame = CFrame.new(origin:Lerp(goalCF.Position,.5),goalCF.Position)
			rayVisual.Size = Vector3.new(0.25,0.25,(goalCF.Position - origin).Magnitude)
			rayVisual.Parent = workspace:WaitForChild("detectRay")
			game:GetService("Debris"):AddItem(rayVisual,1)
			]]

				if result then
					local aboveCF = CFrame.new(result.Position) * CFrame.new(0,1,0)
					local smashPart = rs:WaitForChild("GroundSmashPart"):Clone()
					local normalCF = CFrame.new(result.Position, result.Position + result.Normal) --* CFrame.new(0,0,0.5)
					smashPart.CFrame = normalCF
					smashPart.Parent = workspace
					smashPart.Attachment.Sound:Play()
					for _,particle in pairs(smashPart.Attachment:GetChildren()) do 
						if particle:IsA("ParticleEmitter") then
							particle:Emit(3)
						end
					end
					local camera = workspace.CurrentCamera
					local distanceFromCamera = (camera.CFrame.Position - smashPart.Position).Magnitude
					local percent = math.clamp(1-(math.clamp(distanceFromCamera - 15,0,100) / 100),0,1)
					_G.camShake(1.5,percent)
					local start = tick()
					while true do
						local p = math.clamp((tick() - start)/3,0,1)
						smashPart.Texture.Transparency = (p*.5)+.5 
						if p == 1 then
							smashPart:Destroy()
							break
						end
						task.wait(1/30)
					end
				end
			end

			local function RoarReached()
				root:WaitForChild("smash"):Play()
			end

			local smashAnim = animationController:LoadAnimation(ClientVillainProfiles["Venom"].animations.smashAnimation)
			smashAnim.Priority = Enum.AnimationPriority.Action2
			smashAnim:GetMarkerReachedSignal("Roar"):Connect(RoarReached)
			smashAnim:GetMarkerReachedSignal("Smash"):Connect(SmashReached)
			smashAnim:Play(.1,1,1)

		end)

		local idleAnim = animationController:LoadAnimation(ClientVillainProfiles["Venom"].animations.idleAnimation)
		idleAnim.Priority = Enum.AnimationPriority.Core
		idleAnim:Play(.1,1,.5)

		--local runSound = root:WaitForChild("run")
		local jumpSound = root:WaitForChild("jump")
		local hitSound = root:WaitForChild("hit")

		humanoid.StateChanged:Connect(function(oldState,newState)
			if oldState == Enum.HumanoidStateType.Freefall then
				--print("landed event")
				local playingAnimations = getPlayingAnimations(animationController)
				local jumpPlaying = playingAnimations["Jump"]
				local landedPlaying = playingAnimations["Landed"]
				if jumpPlaying then
					jumpPlaying:Stop()
				end
				if not landedPlaying then
					local landedAnim = animationController:LoadAnimation(ClientVillainProfiles["Venom"].animations.landedAnimation)
					landedAnim.Priority = Enum.AnimationPriority.Movement
					landedAnim:Play(.2,1,1)
				end
			end
			if newState == Enum.HumanoidStateType.Freefall then
				--print("jumping event")
				local playingAnimations = getPlayingAnimations(animationController)
				local runPlaying = playingAnimations["Run"]
				local jumpPlaying = playingAnimations["Jump"]
				if runPlaying then
					runPlaying:Stop()
				end
				if not jumpPlaying then
					local jumpAnim = animationController:LoadAnimation(ClientVillainProfiles["Venom"].animations.jumpAnimation)
					jumpAnim.Priority = Enum.AnimationPriority.Movement
					jumpAnim:Play(.2,1,1)
					jumpSound:Play()
				end
			end
		end)

		local health = properties:WaitForChild("Health")
		local maxHealth = properties:WaitForChild("MaxHealth")

		local healthUI = villain:WaitForChild("Health")
		healthUI.Enabled = health.Value < maxHealth.Value and true or false
		local bg = healthUI:WaitForChild("bg")
		local top = bg:WaitForChild("top")
		local white = bg:WaitForChild("white")

		local function tweenHealth()
			local p = math.clamp(health.Value/maxHealth.Value,0,1)
			local function completed(didComplete)
				if didComplete then
					white:TweenSize(
						UDim2.new(p,0,1,0),
						Enum.EasingDirection.InOut,
						Enum.EasingStyle.Linear,
						.15,
						true
					)						
				end
			end
			top:TweenSize(
				UDim2.new(p,0,1,0),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Linear,
				.15,
				true,
				completed
			)
		end

		local healthAmount = health.Value
		health:GetPropertyChangedSignal("Value"):Connect(function()
			if health.Value == 0 then
				root:WaitForChild("death"):Play()
				--runSound.Volume = 0
				jumpSound.Volume = 0
				tweenHealth()
				--return
			end
			healthUI.Enabled = health.Value < maxHealth.Value and true or false
			if health.Value ~= healthAmount then
				local difference = healthAmount - health.Value
				healthAmount = health.Value
				if difference > 0 then -- took damage
					local playingAnimations = getPlayingAnimations(animationController)
					local hitPlaying = playingAnimations["Hit Reaction"]
					local attackPlaying = playingAnimations["Attack"]
					local smashPlaying = playingAnimations["Ground Smash"]
					local ragdollPlaying = playingAnimations["Ragdoll"]
					local ragdollLoopPlaying = playingAnimations["Ragdoll Loop"]
					local roarPlaying = playingAnimations["Roar"]

					local canContinue = 
						attackPlaying == nil and 
						smashPlaying == nil and 
						--ragdollPlaying == nil and 
						--ragdollLoopPlaying == nil and 
						roarPlaying == nil and 
						hitPlaying == nil

					if canContinue then
						local anim = animationController:LoadAnimation(ClientVillainProfiles["Venom"].animations.hitAnimation)
						anim.Priority = Enum.AnimationPriority.Movement
						anim:Play(.2,1,.75)
						hitSound:Play()
						--[[
							if not cs:HasTag(villain,"ragdolled") then
								hitSound:Play()
							end				
						]]
					end
					tweenHealth()
				else -- healed 
					local p = math.clamp(health.Value/maxHealth.Value,0,1)
					local function tweenDone(didComplete)
						if didComplete then
							white.Size = UDim2.new(p,0,1,0)	
						end
					end
					top:TweenSize(
						UDim2.new(p,0,1,0),
						Enum.EasingDirection.InOut,
						Enum.EasingStyle.Linear,
						.15,
						true,
						tweenDone
					)
				end
			end
		end)

	end,
	runtime=function(villain)
		local venomMesh=villain:FindFirstChild("Body")
		while not venomMesh do 
			venomMesh=Generate_Venom_Mesh(villain)
			task.wait()
		end
		local eventsConnected = villain:WaitForChild("EventsConnected")		
		if not eventsConnected.Value then
			ClientVillainProfiles["Venom"].events(villain)
		end
		adjustCF(villain)
		local properties = villain:WaitForChild("Properties")
		local head = properties:WaitForChild("Head")	
		local falseHead = venomMesh:FindFirstChild("FalseHead")
		if not falseHead then
			falseHead = rs:WaitForChild("FalseHead"):Clone()
			falseHead.CFrame=head.Value.TransformedWorldCFrame
			falseHead.Parent = venomMesh	
		end

		villain:WaitForChild("Health").Adornee = falseHead
		tweenFalseHead(falseHead,head.Value.TransformedWorldCFrame)

		if not villain:FindFirstChild("VenomCollisionPart") then
			GenerateVenomCollisionBox(villain)
		else
			UpdateVenomCollisionBox(villain)
		end

		ClientVillainProfiles["Venom"].AdjustAnimationSpeed(villain,villain.PrimaryPart,properties)
		updateSpineC0(villain,false)
	end,
}

ClientVillainProfiles["Green Goblin"]={
	last_step=tick(),
	last_pos=nil,
	last_rotation=nil,
	animations={
		idleAnimation=GoblinAnimations:WaitForChild("Idle"),
		throwAnimation=GoblinAnimations:WaitForChild("Throw"),
		laughAnimation=GoblinAnimations:WaitForChild("Laugh"),
		ragdollAnimation=GoblinAnimations:WaitForChild("Ragdoll"),
		reactions={
			GoblinAnimations:WaitForChild("reaction"):WaitForChild("1"),
			GoblinAnimations:WaitForChild("reaction"):WaitForChild("2"),
			GoblinAnimations:WaitForChild("reaction"):WaitForChild("3"),
		}
		
	},
	
	throw=function(goblin,humanoid,properties,name)
		local animation=humanoid:LoadAnimation(ClientVillainProfiles["Green Goblin"].animations.throwAnimation)
		goblin:WaitForChild(name).Transparency=0
		animation:Play(.1,1,2)
		animation:GetMarkerReachedSignal("Release"):Wait()
		goblin:WaitForChild(name).Transparency=1
	end,
	
	events=function(villain)
		if not villain then return end
		local eventsConnected = villain:WaitForChild("EventsConnected")
		if eventsConnected.Value then return end
		eventsConnected.Value = true
		local goblin = villain:WaitForChild("Body")
		local glider=villain:WaitForChild("Glider")
		local humanoid = goblin:WaitForChild("Humanoid")
		local properties = villain:WaitForChild("Properties")
		local events = villain:WaitForChild("Events")
		
		local healthUI=villain:WaitForChild("Health")
		healthUI.Adornee=goblin:WaitForChild("Head")
		
		local health = properties:WaitForChild("Health")
		local maxHealth = properties:WaitForChild("MaxHealth")

		healthUI.Enabled = health.Value < maxHealth.Value and true or false
		local bg = healthUI:WaitForChild("bg")
		local top = bg:WaitForChild("top")
		local white = bg:WaitForChild("white")

		local function tweenHealth()
			local p = math.clamp(health.Value/maxHealth.Value,0,1)
			local function completed(didComplete)
				if didComplete then
					white:TweenSize(
						UDim2.new(p,0,1,0),
						Enum.EasingDirection.InOut,
						Enum.EasingStyle.Linear,
						.15,
						true
					)						
				end
			end
			top:TweenSize(
				UDim2.new(p,0,1,0),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Linear,
				.15,
				true,
				completed
			)
		end
		
		local healthAmount = health.Value
		health:GetPropertyChangedSignal("Value"):Connect(function()
			if health.Value == healthAmount then return end
			local difference = healthAmount - health.Value
			healthAmount = health.Value
			healthUI.Enabled = health.Value < maxHealth.Value and true or false
			if health.Value==0 then
				local sound=villain.PrimaryPart:WaitForChild("Death")
				sound:Play()
			end
			if difference > 0 then -- took damage
				local playingAnimations = getPlayingAnimations(humanoid)
				local hitPlaying=playingAnimations["1"] or playingAnimations["2"] or playingAnimations["3"]
				local laughPlaying=playingAnimations["Laugh"]
				local throwPlaying=playingAnimations["Throw"]
				
				if laughPlaying and laughPlaying.TimePosition/laughPlaying.Length>.5 then
					local sound=villain.PrimaryPart:WaitForChild("Gun")
					sound:Stop()
					laughPlaying:Stop()
					laughPlaying=false
				end
				
				if throwPlaying and throwPlaying.TimePosition/throwPlaying.Length>.75 then
					throwPlaying:Stop()
					throwPlaying=false
				end
				
				local canContinue= not laughPlaying and not throwPlaying and not hitPlaying

				if canContinue then
					local anims = ClientVillainProfiles["Green Goblin"].animations.reactions
					local index=random1or3()
					--print("index=",index)
					local anim=humanoid:LoadAnimation(anims[index])
					anim.Priority = Enum.AnimationPriority.Movement
					anim:Play()
					local hitSound=villain.PrimaryPart:WaitForChild("Hit")
					hitSound:Play()
					--[[
					if not cs:HasTag(villain,"ragdolled") then
						local hitSound=villain.PrimaryPart:WaitForChild("Hit")
						hitSound:Play()
					end	
					]]
				end
				tweenHealth()
			else -- healed 
				local p = math.clamp(health.Value/maxHealth.Value,0,1)
				local function tweenDone(didComplete)
					if didComplete then
						white.Size = UDim2.new(p,0,1,0)	
					end
				end
				top:TweenSize(
					UDim2.new(p,0,1,0),
					Enum.EasingDirection.InOut,
					Enum.EasingStyle.Linear,
					.15,
					true,
					tweenDone
				)
			end
		end)
		
		events:WaitForChild("Ragdoll").OnClientEvent:Connect(function(bool)
			--print("Ragdoll",bool)
			if bool then
				cs:AddTag(goblin,"ragdolled")
			else 
				cs:RemoveTag(goblin,"ragdolled")
			end
			
			local hitSound=villain.PrimaryPart:WaitForChild("Hit")
			hitSound:Play()
			
			glider.PrimaryPart.CanCollide=bool==false and true or false
			glider.PrimaryPart.Transparency=bool==false and 0 or 1
			glider.PrimaryPart:WaitForChild("hover").Volume=bool==false and .25 or 0
			for _,element in glider.PrimaryPart:WaitForChild("Attachment"):GetChildren() do 
				element.Enabled=bool==false and true or false
			end
			local trail=glider:WaitForChild("effect"):WaitForChild("Trail")
			trail.Enabled=bool==false and true or false
			--ragdoll.ragdoll(nil,goblin,nil,bool and "start" or "recover",nil,nil,nil,true)
			local playingAnimations = getPlayingAnimations(humanoid)
			local hitPlaying=playingAnimations["1"] or playingAnimations["2"] or playingAnimations["3"]
			local laughPlaying=playingAnimations["Laugh"]
			local throwPlaying=playingAnimations["Throw"]
			local ragdollPlaying=playingAnimations["Ragdoll"]

			if laughPlaying then
				local sound=villain.PrimaryPart:WaitForChild("Gun")
				sound:Stop()
				laughPlaying:Stop()
				laughPlaying=false
			end

			if throwPlaying then
				throwPlaying:Stop()
				throwPlaying=false
				local sound=villain.PrimaryPart:WaitForChild("Throw")
				sound:Stop()
			end
			
			if hitPlaying then
				hitPlaying:Stop()
				hitPlaying=false
				--local sound=villain.PrimaryPart:WaitForChild("Hit")
				--sound:Stop()
			end
			
			if bool then
				local anim=humanoid:LoadAnimation(ClientVillainProfiles["Green Goblin"].animations.ragdollAnimation)
				anim:Play(.1,1,1)
			else 
				if ragdollPlaying then
					ragdollPlaying:Stop()
				end
			end
			
		end)
		
		events:WaitForChild("Damage").OnClientEvent:Connect(function(action)
			if action == "Melee" then
				local head = goblin:WaitForChild("Head")
				effects.MeleeEffect(head.Position)
			end
		end)
		
		events:WaitForChild("Gun").OnClientEvent:Connect(function(timer,action,pos)
			if action=="MuzzleFlash" then
				local attachment=rs:WaitForChild("muzzle_flash"):WaitForChild("Attachment"):Clone()
				attachment.WorldPosition=pos
				attachment.Parent=workspace.Terrain
				attachment.fire:Play()
				attachment.ParticleEmitter:Emit(1)
				attachment.light.Brightness = 2
				task.wait(1/30)
				attachment.light.Brightness = 0
				game:GetService("Debris"):AddItem(attachment,.5)
				return
			end
			local latency=workspace:GetServerTimeNow()-timer
			while workspace:GetServerTimeNow()-timer<(.5-latency) do 
				runService.RenderStepped:Wait()
			end
			if properties.Target.Value:IsA("Attachment") then return end
			if cs:HasTag(villain,"ragdolled") then return end
			
			local animation=humanoid:LoadAnimation(ClientVillainProfiles["Green Goblin"].animations.laughAnimation)
			animation:Play(.1,1,1.5)
			local sound=villain.PrimaryPart:WaitForChild("Gun")
			sound:Play()
			-- muzzle flash at the start position, sound effect!
			
		end)
		
		events:WaitForChild("Bomb").OnClientEvent:Connect(function(timer,action,projectile)
			if action=="Explode" then
				local bomb=projectile:WaitForChild("Bomb")
				local ExplodeSound=bomb:WaitForChild("Explode")
				ExplodeSound:Play()
				local ExplodeAttachment=bomb:WaitForChild("ExplodeAttachment")
				for _,particle in ExplodeAttachment:GetChildren() do 
					particle:Emit(5)
				end
				local d = (camera.CFrame.Position - projectile.PrimaryPart.Position).Magnitude
				local range = 100
				_G.camShake(1,math.clamp(range - d,0,math.huge)/(range/2))
				return
			end
			local latency=workspace:GetServerTimeNow()-timer
			while workspace:GetServerTimeNow()-timer<(.5-latency) do 
				runService.RenderStepped:Wait()
			end
			if properties.Target.Value:IsA("Attachment") then return end
			if cs:HasTag(villain,"ragdolled") then return end
			
			local sound=villain.PrimaryPart:WaitForChild("Throw")
			sound:Play()
			
			ClientVillainProfiles["Green Goblin"].throw(goblin,humanoid,properties,"Bomb")
		end)
		
		events:WaitForChild("Gas").OnClientEvent:Connect(function(timer,action,projectile)
			if action=="Explode" then
				local bomb=projectile:WaitForChild("Bomb")
				local HissSound=bomb:WaitForChild("Hiss")
				HissSound:Play()
				local GasAttachment=bomb:WaitForChild("GasAttachment")
				local particle=GasAttachment:WaitForChild("gas")
				local last=tick()
				local rate=1/particle.Rate
				GasAttachment.WorldCFrame=CFrame.new(GasAttachment.WorldPosition)
				local soundStart=tick()
				while workspace:GetServerTimeNow()-timer<10 do 
					local p=tick()-soundStart
					HissSound.Volume=math.clamp(p/1,0,1)*.5
					local elapsed=tick()-last 
					if elapsed>=rate then
						last=tick()
						local vector, onScreen = camera:WorldToScreenPoint(GasAttachment.WorldPosition)
						if onScreen then
							particle:Emit(1)
						end
					end
					task.wait()
				end
				return
			end
			local latency=workspace:GetServerTimeNow()-timer
			while workspace:GetServerTimeNow()-timer<(.5-latency) do 
				runService.RenderStepped:Wait()
			end
			if properties.Target.Value:IsA("Attachment") then return end
			if cs:HasTag(villain,"ragdolled") then return end
			
			local sound=villain.PrimaryPart:WaitForChild("Throw")
			sound:Play()
			
			ClientVillainProfiles["Green Goblin"].throw(goblin,humanoid,properties,"Bomb")
		end)
		
		events:WaitForChild("Razor").OnClientEvent:Connect(function(timer)
			local latency=workspace:GetServerTimeNow()-timer
			while workspace:GetServerTimeNow()-timer<(.5-latency) do 
				runService.RenderStepped:Wait()
			end
			if properties.Target.Value:IsA("Attachment") then return end
			if cs:HasTag(villain,"ragdolled") then return end
			
			local sound=villain.PrimaryPart:WaitForChild("Throw")
			sound:Play()
			
			ClientVillainProfiles["Green Goblin"].throw(goblin,humanoid,properties,"Razor")
		end)
		
	end,
	runtime=function(villain)
		local goblin=villain:FindFirstChild("Body")
		local glider=villain:FindFirstChild("Glider")
		if not goblin or not glider then
			goblin,glider=Generate_Green_Goblin(villain)
		end
		
		local eventsConnected = villain:WaitForChild("EventsConnected")		
		if not eventsConnected.Value then
			ClientVillainProfiles["Green Goblin"].events(villain)
		end
		
		if not ClientVillainProfiles["Green Goblin"].last_pos then
			ClientVillainProfiles["Green Goblin"].last_pos=glider.PrimaryPart.Position
		end
		
		if not ClientVillainProfiles["Green Goblin"].last_rotation then
			local _,y,_=glider.PrimaryPart.CFrame:ToOrientation()
			ClientVillainProfiles["Green Goblin"].last_rotation=math.deg(y)
		end
		
		adjustGoblinCF(goblin,glider,villain)
		
		local speed=Get_Goblin_Speed(glider)
		local rotation=Get_Rotation(glider.PrimaryPart,ClientVillainProfiles["Green Goblin"].last_rotation)
		Adjust_Glider_Wings(glider,speed,rotation)
		
		local humanoid=goblin:WaitForChild("Humanoid")
		local playingAnimations = getPlayingAnimations(humanoid)
		if not playingAnimations["Idle"] then
			--print("goblin had to play idle")
			local idleAnim = humanoid:LoadAnimation(ClientVillainProfiles["Green Goblin"].animations.idleAnimation)
			idleAnim.Priority = Enum.AnimationPriority.Core
			idleAnim:Play(.1,1,.5)
		end
		
		adjustGliderSound(glider,speed)
		
		ClientVillainProfiles["Green Goblin"].last_pos=glider.PrimaryPart.Position -- update last_pos
		ClientVillainProfiles["Green Goblin"].last_step=tick() -- update last_step
		local _,y,_=glider.PrimaryPart.CFrame:ToOrientation()
		ClientVillainProfiles["Green Goblin"].last_rotation=math.deg(y) -- update last_rotation
		
	end,
}

ClientVillainProfiles["Doc Ock"]={
	last_move_animation=1,
	last_rotation=nil,
	animations={
		BottomMove=DocAnimations:WaitForChild("Bottom Move"),
		BottomMove2=DocAnimations:WaitForChild("Bottom Move 2"),
		BottomIdle=DocAnimations:WaitForChild("Bottom Idle"),
		BottomShuffle=DocAnimations:WaitForChild("Bottom Shuffle"),
		TopIdle=DocAnimations:WaitForChild("Top Idle"),
		TopBarrage=DocAnimations:WaitForChild("Top Barrage"),
		TopHooks=DocAnimations:WaitForChild("Top Hooks"),
		TopGrabLeft=DocAnimations:WaitForChild("Top Grab Left"),
		TopGrabRight=DocAnimations:WaitForChild("Top Grab Right"),
		BodyIdle=DocAnimations:WaitForChild("Body Idle"),
		BodyHooks=DocAnimations:WaitForChild("Body Hooks"),
		BodyBarrage=DocAnimations:WaitForChild("Body Barrage"),
		BodyGrabLeft=DocAnimations:WaitForChild("Body Grab Left"),
		BodyGrabRight=DocAnimations:WaitForChild("Body Grab Right"),
		Ragdoll=DocAnimations:WaitForChild("Ragdoll"),
		reactions={
			DocAnimations:WaitForChild("reaction"):WaitForChild("1"),
			DocAnimations:WaitForChild("reaction"):WaitForChild("2"),
			DocAnimations:WaitForChild("reaction"):WaitForChild("3")
		}
	},
	events=function(villain)
		if not villain then return end
		local eventsConnected = villain:WaitForChild("EventsConnected")
		if eventsConnected.Value then return end
		eventsConnected.Value = true
		local properties = villain:WaitForChild("Properties")
		local Body=villain:FindFirstChild("Body")
		local LowerTentacle=villain:FindFirstChild("LowerTentacle")
		local UpperTentacle=villain:FindFirstChild("UpperTentacle")
		local controller1=UpperTentacle:FindFirstChild("AnimationController")
		local Humanoid=Body and Body:FindFirstChild("Humanoid")
		local events = villain:WaitForChild("Events")
		
		local healthUI=villain:WaitForChild("Health")
		healthUI.Adornee=Body:WaitForChild("Head")

		local health = properties:WaitForChild("Health")
		local maxHealth = properties:WaitForChild("MaxHealth")

		healthUI.Enabled = health.Value < maxHealth.Value and true or false
		local bg = healthUI:WaitForChild("bg")
		local top = bg:WaitForChild("top")
		local white = bg:WaitForChild("white")		
		
		local function tweenHealth()
			local p = math.clamp(health.Value/maxHealth.Value,0,1)
			local function completed(didComplete)
				if didComplete then
					white:TweenSize(
						UDim2.new(p,0,1,0),
						Enum.EasingDirection.InOut,
						Enum.EasingStyle.Linear,
						.15,
						true
					)						
				end
			end
			top:TweenSize(
				UDim2.new(p,0,1,0),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Linear,
				.15,
				true,
				completed
			)
		end
		
		local healthAmount = health.Value
		health:GetPropertyChangedSignal("Value"):Connect(function()
			if health.Value == healthAmount then return end
			local difference = healthAmount - health.Value
			healthAmount = health.Value
			healthUI.Enabled = health.Value < maxHealth.Value and true or false
			if health.Value==0 then
				--local sound=villain.PrimaryPart:WaitForChild("Death")
				--sound:Play()
			end
			if difference > 0 then -- took damage
				local playing_anims=getPlayingAnimations(Humanoid)
				local restricted_anims={
					["Body Hooks"]=true,
					["Body Barrage"]=true,
					["Body Grab Left"]=true,
					["Body Grab Right"]=true,
					["1"]=true,
					["2"]=true,
					["3"]=true,
					--["Ragdoll"]=true
				}
				local restrictedPlaying=false
				for i,v in playing_anims do 
					if restricted_anims[i] then
						restrictedPlaying=true 
						break
					end
				end
				if restrictedPlaying==false then
					local anims = ClientVillainProfiles["Doc Ock"].animations.reactions
					local index=random1or3()
					--print("index=",index)
					local anim=Humanoid:LoadAnimation(anims[index])
					anim.Priority = Enum.AnimationPriority.Movement
					anim:Play()
					villain.PrimaryPart:WaitForChild("hit"):Play()
				end
				tweenHealth()
			else -- healed 
				local p = math.clamp(health.Value/maxHealth.Value,0,1)
				local function tweenDone(didComplete)
					if didComplete then
						white.Size = UDim2.new(p,0,1,0)	
					end
				end
				top:TweenSize(
					UDim2.new(p,0,1,0),
					Enum.EasingDirection.InOut,
					Enum.EasingStyle.Linear,
					.15,
					true,
					tweenDone
				)
			end
		end)
		
		events:WaitForChild("Ragdoll").OnClientEvent:Connect(function(bool)
			if bool then
				cs:AddTag(Body,"ragdolled")
				local playingAnimations=getPlayingAnimations(Humanoid)
				for name,anim in playingAnimations do 
					if name~="Ragdoll" then
						anim:Stop()
					end
				end
				
				local anim=Humanoid:LoadAnimation(ClientVillainProfiles["Doc Ock"].animations.Ragdoll)
				anim:Play(.1,1,1)
				villain.PrimaryPart:WaitForChild("death"):Play()
				local LowerTentacle=villain:FindFirstChild("LowerTentacle")
				local UpperTentacle=villain:FindFirstChild("UpperTentacle")
				LowerTentacle.PrimaryPart.Transparency=1
				UpperTentacle.PrimaryPart.Transparency=1
			else 
				Body:SetAttribute("LastRagdolled",tick())
				cs:RemoveTag(Body,"ragdolled")
				local playingAnimations=getPlayingAnimations(Humanoid)
				local ragdollPlaying=playingAnimations["Ragdoll"]
				if ragdollPlaying then
					ragdollPlaying:Stop()
				end
				local LowerTentacle=villain:FindFirstChild("LowerTentacle")
				local UpperTentacle=villain:FindFirstChild("UpperTentacle")
				LowerTentacle.PrimaryPart.Transparency=0
				UpperTentacle.PrimaryPart.Transparency=0
			end
			
		end)
		
		events:WaitForChild("Hooks").OnClientEvent:Connect(function(timer)
			--print("client hooks!")
			local latency=workspace:GetServerTimeNow()-timer
			while workspace:GetServerTimeNow()-timer<(.5-latency) do 
				runService.RenderStepped:Wait()
			end
			if properties.Target.Value:IsA("Attachment") then return end
			if cs:HasTag(villain,"ragdolled") then return end
			local UpperTentacle=villain:FindFirstChild("UpperTentacle")
			local Controller=UpperTentacle and UpperTentacle:FindFirstChild("AnimationController")
			if not Controller then return end
			local anim=Controller:LoadAnimation(ClientVillainProfiles["Doc Ock"].animations.TopHooks)
			anim.Priority=Enum.AnimationPriority.Action
			anim:Play()
			anim:GetMarkerReachedSignal("Rotate"):Connect(function()
				villain.PrimaryPart:WaitForChild("tentacle_twist1"):Play()
			end)

			anim:GetMarkerReachedSignal("Move"):Connect(function()
				villain.PrimaryPart:WaitForChild("tentacle_move2"):Play()
			end)
			
			anim:GetMarkerReachedSignal("Clamp"):Connect(function()
				villain.PrimaryPart:WaitForChild("tentacle_twist2"):Play()
			end)
			local body=villain:FindFirstChild("Body")
			local humanoid=body and body:FindFirstChild("Humanoid")
			if not humanoid then return end
			local body_anim=humanoid:LoadAnimation(ClientVillainProfiles["Doc Ock"].animations["BodyHooks"])
			body_anim:Play(.2,1,1.1)
			
			body_anim:GetMarkerReachedSignal("Start"):Connect(function()
				villain.PrimaryPart:WaitForChild("voice_taunt2"):Play()
			end)
			
		end)
		
		events:WaitForChild("Barrage").OnClientEvent:Connect(function(timer)
			--print("client barrage!")
			local latency=workspace:GetServerTimeNow()-timer
			while workspace:GetServerTimeNow()-timer<(.5-latency) do 
				runService.RenderStepped:Wait()
			end
			if properties.Target.Value:IsA("Attachment") then return end
			if cs:HasTag(villain,"ragdolled") then return end
			local UpperTentacle=villain:FindFirstChild("UpperTentacle")
			local Controller=UpperTentacle and UpperTentacle:FindFirstChild("AnimationController")
			if not Controller then return end
			local anim=Controller:LoadAnimation(ClientVillainProfiles["Doc Ock"].animations.TopBarrage)
			anim.Priority=Enum.AnimationPriority.Action
			anim:Play()
			
			anim:GetMarkerReachedSignal("Rotate"):Connect(function()
				villain.PrimaryPart:WaitForChild("tentacle_twist1"):Play()
			end)
			
			anim:GetMarkerReachedSignal("Move"):Connect(function()
				villain.PrimaryPart:WaitForChild("tentacle_move1"):Play()
			end)
			
			local body=villain:FindFirstChild("Body")
			local humanoid=body and body:FindFirstChild("Humanoid")
			if not humanoid then return end
			local body_anim=humanoid:LoadAnimation(ClientVillainProfiles["Doc Ock"].animations["BodyBarrage"])
			body_anim:Play(.2,1,1)
			
			body_anim:GetMarkerReachedSignal("Start"):Connect(function()
				villain.PrimaryPart:WaitForChild("voice_taunt3"):Play()
			end)
			
		end)
		
		events.ChildAdded:Connect(function(child)
			if child.Name~="Tentacle" then return end
			if child:GetAttribute("player")~=game.Players.LocalPlayer.Name then return end -- must be your name
			local timer=child:GetAttribute("timer")
			
			local throwing=false
			local function throw()
				throwing=workspace:GetServerTimeNow()
			end
			
			local Side="L"
			for _,track in controller1:GetPlayingAnimationTracks() do 
				if track.Name=="Top Grab Left" then
					Side="R"
				elseif track.Name=="Top Grab Right" then
					Side="L"
				end
				track:GetMarkerReachedSignal("Throw"):Connect(throw)
			end
			
			local Bones=UpperTentacle.PrimaryPart:FindFirstChild("Arm1."..Side)
			local Bone_To_Track=nil
			for i,bone in Bones:GetDescendants() do 
				if bone.Name=="Holder."..Side then
					Bone_To_Track=bone
				end
			end
			
			if not Bone_To_Track then return end -- bone doesn't exist?
			local clock=rs:WaitForChild("clock")
			while true do -- let the server know what's up!
				if child.Parent==nil then break end
				child:FireServer(Bone_To_Track.TransformedWorldCFrame,throwing)
				local elapsed=workspace:GetServerTimeNow()-timer
				if elapsed>=5 then break end
				clock:GetPropertyChangedSignal("Value"):Wait()
			end
			
		end)
		
		events:WaitForChild("Grab").OnClientEvent:Connect(function(timer,side)
			--print("client grab!")
			local latency=workspace:GetServerTimeNow()-timer
			while workspace:GetServerTimeNow()-timer<(.5-latency) do 
				runService.RenderStepped:Wait()
			end
			if properties.Target.Value:IsA("Attachment") then return end
			if cs:HasTag(villain,"ragdolled") then return end
			local UpperTentacle=villain:FindFirstChild("UpperTentacle")
			local Controller=UpperTentacle and UpperTentacle:FindFirstChild("AnimationController")
			if not Controller then return end
			local anims={
				["Left"]=ClientVillainProfiles["Doc Ock"].animations.TopGrabLeft,
				["Right"]=ClientVillainProfiles["Doc Ock"].animations.TopGrabRight
			}
			local anim=anims[side]
			anim=Controller:LoadAnimation(anim)
			anim:Play()
			
			anim:GetMarkerReachedSignal("Rotate"):Connect(function()
				villain.PrimaryPart:WaitForChild("tentacle_twist1"):Play()
			end)

			anim:GetMarkerReachedSignal("Move"):Connect(function()
				villain.PrimaryPart:WaitForChild("tentacle_move2"):Play()
			end)
			
			anim:GetMarkerReachedSignal("Clamp"):Connect(function()
				villain.PrimaryPart:WaitForChild("tentacle_twist2"):Play()
			end)
			
			local body=villain:FindFirstChild("Body")
			local humanoid=body and body:FindFirstChild("Humanoid")
			if not humanoid then return end
			local body_anims={
				["Left"]=ClientVillainProfiles["Doc Ock"].animations.BodyGrabLeft,
				["Right"]=ClientVillainProfiles["Doc Ock"].animations.BodyGrabRight
			}
			local body_anim=body_anims[side]
			body_anim=humanoid:LoadAnimation(body_anim)
			body_anim:Play(.2,1,1)
			
			body_anim:GetMarkerReachedSignal("Start"):Connect(function()
				villain.PrimaryPart:WaitForChild("voice_taunt1"):Play()
			end)
		end)
		
		events:WaitForChild("Damage").OnClientEvent:Connect(function(action)
			if action == "Melee" then
				local head = Body:WaitForChild("Head")
				effects.MeleeEffect(head.Position)
			end
		end)
		
	end,
	
	AdjustAnimationSpeed=function(villain,root,properties,LowerTentacle,UpperTentacle,Body,rotation)
		local controller1=LowerTentacle:FindFirstChildOfClass("AnimationController")
		local controller2=UpperTentacle:FindFirstChildOfClass("AnimationController")
		if not controller1 or not controller2 then return end
		local LT_PlayingAnims=getPlayingAnimations(controller1)
		local UT_PlayingAnims=getPlayingAnimations(controller2)
		local Humanoid=Body:FindFirstChild("Humanoid")
		if not Humanoid then return end
		local Body_PlayingAnims=getPlayingAnimations(Humanoid)
		
		if cs:HasTag(Body,"ragdolled") then
			for i,v in LT_PlayingAnims do 
				v:Stop()
			end
			for i,v in UT_PlayingAnims do 
				v:Stop()
			end
			return
		end
		
		local horizontalSpeed = (root.Velocity * Vector3.new(1,0,1)).Magnitude
		local movePlaying=LT_PlayingAnims["Bottom Move"] or LT_PlayingAnims["Bottom Move 2"]
		local idlePlaying=LT_PlayingAnims["Bottom Idle"]
		local shufflePlaying=LT_PlayingAnims["Bottom Shuffle"]
		local topIdlePlaying=UT_PlayingAnims["Top Idle"]
		
		local attacks={
			["Top Barrage"]=true,
			["Top Hooks"]=true,
			["Top Grab Left"]=true,
			["Top Grab Right"]=true
		}
		
		local bodyIdlePlaying=Body_PlayingAnims["Body Idle"]
		if not bodyIdlePlaying then
			local anim=Humanoid:LoadAnimation(ClientVillainProfiles["Doc Ock"].animations["BodyIdle"])
			anim.Priority=Enum.AnimationPriority.Idle
			anim:Play()
		end
		
		if not topIdlePlaying then
			local anim=controller2:LoadAnimation(ClientVillainProfiles["Doc Ock"].animations["TopIdle"])
			anim.Priority=Enum.AnimationPriority.Idle
			anim:Play()
			local function check_playing_attack()
				local playingAttack=false
				for i,v in attacks do 
					if UT_PlayingAnims[i] then
						playingAttack=true
						break
					end
				end
				return playingAttack
			end
			anim:GetMarkerReachedSignal("Rotate"):Connect(function()
				if not check_playing_attack() then
					villain.PrimaryPart:WaitForChild("tentacle_twist1"):Play()
				end
			end)
			anim:GetMarkerReachedSignal("Clamp"):Connect(function()
				if not check_playing_attack() then
					villain.PrimaryPart:WaitForChild("tentacle_twist2"):Play()
				end
			end)
		end
		
		if not idlePlaying then
			local anim=controller1:LoadAnimation(ClientVillainProfiles["Doc Ock"].animations["BottomIdle"])
			anim.Priority=Enum.AnimationPriority.Idle
			anim:Play()
		end
		
		if horizontalSpeed > 1 then
			local minimumSpeed = 0--(properties.Target.Value ~= nil and properties.Target.Value:IsA("Attachment")) and 0 or .75 
			local maximumSpeed = 1.483333333333333
			local animSpeed = math.clamp((horizontalSpeed/32)*maximumSpeed,minimumSpeed,maximumSpeed)
			--print(animSpeed)
			--needs to be 0.6741573033707867 percent of the speed
			
			if shufflePlaying then
				shufflePlaying:Stop()
			end
			
			if not movePlaying then
				local current_move_anim=ClientVillainProfiles["Doc Ock"].last_move_animation
				local anims={
					ClientVillainProfiles["Doc Ock"].animations["BottomMove"],
					ClientVillainProfiles["Doc Ock"].animations["BottomMove2"]
				}
				local anim=controller1:LoadAnimation(anims[current_move_anim])
				anim.Priority=Enum.AnimationPriority.Movement
				anim:Play(.2,1,animSpeed)
				anim:GetMarkerReachedSignal("Landed"):Connect(function()
					local sounds={
						villain.PrimaryPart:WaitForChild("tentacle_impact1"),
						villain.PrimaryPart:WaitForChild("tentacle_impact2")
					}
					sounds[math.random(1,2)]:Play()
				end)
				anim:GetMarkerReachedSignal("Move"):Connect(function()
					villain.PrimaryPart:WaitForChild("tentacle_move3"):Play()
				end)
				anim:GetMarkerReachedSignal("Rotate"):Connect(function()
					villain.PrimaryPart:WaitForChild("tentacle_twist1"):Play()
				end)
				current_move_anim+=1
				if current_move_anim>2 then
					current_move_anim=1
				end
				ClientVillainProfiles["Doc Ock"].last_move_animation=current_move_anim
			else
				movePlaying:AdjustSpeed(animSpeed)
			end
		else
			if movePlaying then
				movePlaying:Stop()
				local sounds={
					villain.PrimaryPart:WaitForChild("tentacle_impact1"),
					villain.PrimaryPart:WaitForChild("tentacle_impact2")
				}
				sounds[math.random(1,2)]:Play()
			end
			if rotation=="None" then
				local canStop=true
				local LastRotated=Body:GetAttribute("LastRotated")
				if LastRotated then
					canStop=tick()-LastRotated>0.5
				end
				if shufflePlaying and canStop then
					shufflePlaying:Stop()
				end
			else
				if not shufflePlaying then
					local anim=controller1:LoadAnimation(ClientVillainProfiles["Doc Ock"].animations.BottomShuffle)
					anim:Play(.2,1,1)
					anim:GetMarkerReachedSignal("Landed"):Connect(function()
						local sounds={
							villain.PrimaryPart:WaitForChild("tentacle_impact1"),
							villain.PrimaryPart:WaitForChild("tentacle_impact2")
						}
						sounds[math.random(1,2)]:Play()
					end)
					anim:GetMarkerReachedSignal("Move"):Connect(function()
						villain.PrimaryPart:WaitForChild("tentacle_move2"):Play()
					end)
				end
			end
		end
		
	end,
	runtime=function(villain)		
		local Body=villain:FindFirstChild("Body")
		local LowerTentacle=villain:FindFirstChild("LowerTentacle")
		local UpperTentacle=villain:FindFirstChild("UpperTentacle")
		if not LowerTentacle or not Body then
			LowerTentacle,UpperTentacle,Body=Generate_Doc_Ock(villain)
		end
		
		local eventsConnected = villain:WaitForChild("EventsConnected")		
		if not eventsConnected.Value then
			ClientVillainProfiles["Doc Ock"].events(villain)
		end
		
		adjustDocCF(LowerTentacle,UpperTentacle,Body,villain)
		local properties = villain:WaitForChild("Properties")
		Adjust_Waist(Body,properties)
		
		if not ClientVillainProfiles["Doc Ock"].last_rotation then
			local _,y,_=villain.PrimaryPart.CFrame:ToOrientation()
			ClientVillainProfiles["Doc Ock"].last_rotation=math.deg(y)
		end
		
		local rotation,amount=Get_Rotation(villain.PrimaryPart,ClientVillainProfiles["Doc Ock"].last_rotation)
		if rotation~="None" then
			Body:SetAttribute("LastRotated",tick())
		end
		ClientVillainProfiles["Doc Ock"].AdjustAnimationSpeed(villain,villain.PrimaryPart,properties,LowerTentacle,UpperTentacle,Body,rotation)
		
		local _,y,_=villain.PrimaryPart.CFrame:ToOrientation()
		ClientVillainProfiles["Doc Ock"].last_rotation=math.deg(y) -- update last_rotation
		
	end,
}

return ClientVillainProfiles
