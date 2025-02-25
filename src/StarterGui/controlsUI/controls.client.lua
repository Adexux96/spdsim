--!nocheck
local player = game.Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local hotbarUI=playerGui:WaitForChild("hotbarUI")
local selected=hotbarUI:WaitForChild("container"):WaitForChild("Selected")
local controlsUI=script.Parent
local leaderstats = player:WaitForChild("leaderstats")
local temp = leaderstats:WaitForChild("temp")
local remote = player:WaitForChild("rollRemote")

local rs = game:GetService("ReplicatedStorage")
local cs = game:GetService("CollectionService")
local animations = rs:WaitForChild("animations")
local movement = animations:WaitForChild("movement")
local RollAnimation  = movement:WaitForChild("Roll")

local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local playerMovement = require(rs:WaitForChild("playerMovement"))
local items=require(rs:WaitForChild("items"))

local isRolling = temp:WaitForChild("isRolling")
local isClimbing = temp:WaitForChild("isClimbing")
local isSwimming = temp:WaitForChild("isSwimming")
local isWebbing = temp:WaitForChild("isWebbing")
local isSprinting = temp:WaitForChild("isSprinting")
local ActionButtonDown=temp:WaitForChild("ActionButtonDown")

local clock=rs:WaitForChild("clock")

if not _G.platform then repeat clock:GetPropertyChangedSignal("Value"):Wait() until _G.platform end
if not _G.cooling then repeat clock:GetPropertyChangedSignal("Value"):Wait() until _G.cooling end
local physicsService = game:GetService("PhysicsService")

local function ghostPlayer()
	if not player.Character then return end
	cs:AddTag(player.Character,"ghosted")
	for index, part in pairs(player.Character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CollisionGroup="Ghost"
		end
	end
	--print("ghosted ",player.Name)
end

local function undoGhost()
	if not player.Character then return end
	cs:RemoveTag(player.Character,"ghosted")
	for index, part in pairs(player.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			local collisionGroup = part.Name == "RootLegs" and "Ghost" or "Characters"
			part.CollisionGroup=collisionGroup
		end
	end
	--print("removed ghost for ",player.Name)
end

local function getAngle(v1,v2) -- X = Z; Y = X
	local dir = v1 - v2
	local Angle =math.atan2(dir.Y,dir.X)
	return  math.deg(Angle)
end

local function ClampMagnitude(v, max)
	if (v.magnitude == 0) then return Vector3.new(0,0,0) end -- prevents NAN,NAN,NAN
	return v.Unit * math.min(v.Magnitude, max) 
end

local rollStopped=false
local function stopped(character:Model, humanoid:Humanoid)
	local gyro = character.PrimaryPart:FindFirstChild("BodyGyro")
	if gyro then
		gyro.MaxTorque = Vector3.new(0,0,0)
	end
	local velocity = character.PrimaryPart:FindFirstChildOfClass("BodyVelocity")
	if velocity then
		velocity.MaxForce = Vector3.new(0,0,0)
	end
	rollStopped = true
	--task.wait(.3)
	controls:Enable()
	if not isClimbing.Value and not cs:HasTag(character,"ragdolled") and humanoid.Health > 0 then
		undoGhost()
	end
	isRolling.Value = false
end

local function ray(origin:Vector3,direction:Vector3,whitelist:{})
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = whitelist
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local whitelist={
	workspace:WaitForChild("BuildingBounds"),
	workspace:WaitForChild("Trash"),
	workspace:WaitForChild("BarrelFire1"),
	workspace:WaitForChild("Vents"),
	workspace:WaitForChild("Trees"),
	workspace:WaitForChild("crates"),
	--workspace:WaitForChild("Rock1"),
	--workspace:WaitForChild("ConstructionSite"),
	workspace:WaitForChild("Ground")
}

local function visualizeRay(origin,target,size)
	local part=workspace:FindFirstChild("RayVisual")
	if not part then
		part=Instance.new("Part")
		part.Name="RayVisual"
		part.Anchored=true
		part.CanCollide=false
		part.BrickColor=BrickColor.Blue()
		part.Transparency=.75
		part.Parent=workspace
	end
	local position=origin:Lerp(target,.5)
	local cf=CFrame.new(position,target)
	part.CFrame=cf
	part.Size=Vector3.new(.5,.5,size)
	--print("made it here")
end

local function cast_ray(character,speed,cframe)
	local duration=0.9166666865348816
	local distance=speed*duration
	local origin=character.PrimaryPart.Position
	local target=(cframe*CFrame.new(0,0,-distance)).Position
	local direction=(target-origin).Unit*distance
	local result=ray(origin,direction,whitelist)
	return result,origin
end

local function roll(t)
	local canContinue = isRolling.Value == false and isClimbing.Value == false and isSwimming.Value == false and isWebbing.Value == false 
	local characterExists = player.Character and player.Character:IsDescendantOf(workspace) and player.Character.PrimaryPart
	if canContinue and characterExists then
		local moveVector = playerMovement.GetMoveVector(playerMovement)
		local character=player.Character
		if cs:HasTag(character,"ragdolled") then return end
		local angle = getAngle(Vector2.new(0,0),Vector2.new(moveVector.Z,moveVector.X))
		local x,y,z = workspace.CurrentCamera.CFrame:ToOrientation()
		local cframe = CFrame.new(character.PrimaryPart.Position) * CFrame.Angles(0,y,0)
		local gyroCFrame = cframe * CFrame.Angles(math.rad(0),math.rad(angle),math.rad(0))
		local speed=16
		local result,origin=cast_ray(character,speed,gyroCFrame)
		local distance=nil
		if result~=nil then
			distance=(origin-result.Position).Magnitude
			speed=math.clamp(distance-2,0,16)
			--print("distance=",distance)
			--print("speed=",speed)
			--visualizeRay(origin,result.Position,distance)
		end
		isRolling.Value = true
		remote:FireServer(t)
		--controls:Disable()
		ghostPlayer()
		local humanoid = character:WaitForChild("Humanoid")
		local rollAnim = humanoid:LoadAnimation(RollAnimation)
		rollStopped = false
		local function stop()
			rollStopped=true
		end
		--rollAnim.Priority = Enum.AnimationPriority.Action2
		rollAnim.Stopped:Connect(stop)
		rollAnim:Play(.2,1,2)
		local start=tick()
		local rollSound = character.PrimaryPart:FindFirstChild("roll")
		if rollSound then
			rollSound:Play()
		end

		local gyro = character.PrimaryPart:FindFirstChildOfClass("BodyGyro")
		if not gyro then
			gyro = Instance.new("BodyGyro")
			gyro.D = 200
			gyro.P = 2500
			gyro.MaxTorque = Vector3.new(100000, 100000, 100000)
			gyro.Parent = character.PrimaryPart
		end
		gyro.MaxTorque = Vector3.new(100000, 100000, 100000)
		gyro.D = 300
		gyro.P = 5000

		local velocity = character.PrimaryPart:FindFirstChildOfClass("BodyVelocity")
		if not velocity then
			velocity = Instance.new("BodyVelocity")
			velocity.MaxForce = Vector3.new(1,1,1)*math.huge
			velocity.P = math.huge
			velocity.Velocity = Vector3.new()
			velocity.Parent = character.PrimaryPart
		end
		velocity.MaxForce = Vector3.new(100000,0,100000)
		velocity.P = math.huge

		while rollStopped == false do
			if cs:HasTag(character,"ragdolled") then break end
			if cs:HasTag(character,"Died") then break end
			--local dt=tick()-start
			--local p=math.clamp(dt/0.9166666865348816,0,1)
			--print("p=",p)
			velocity.Velocity = ClampMagnitude(gyroCFrame.LookVector * speed,speed)
			gyro.CFrame = gyroCFrame
			task.wait(1/30)
		end

		stopped(character,humanoid)
		-- get the rotation of the move vector, apply to gyro
		-- apply a force to the character in that direction for the duration of the animation
		-- ignore the y force, lets players fall
	end
end

local mobile=controlsUI:WaitForChild("mobile")
local _jump=mobile:WaitForChild("jump")
local Jump_Focused_Input=nil

local _sprint=mobile:WaitForChild("sprint")
local Sprint_Focused_Input=nil

local _ability=mobile:WaitForChild("ability")
local Ability_Focused_Input=nil

local _roll=mobile:WaitForChild("roll")
local Roll_Focused_Input=nil

local pc=controlsUI:WaitForChild("pc")
local pc_roll=pc:WaitForChild("roll")
local pc_ability=pc:WaitForChild("ability")

local function GetAbilityName(slotName)
	local slot=hotbarUI:WaitForChild("container"):FindFirstChild(slotName)
	if not slot then return nil end
	local ability=slot:WaitForChild("name").Value
	if ability=="" then return nil end
	return ability
end

local function CheckRagdolled()
	if player.Character and cs:HasTag(player.Character,"ragdolled") then
		return true
	end
	return false
end

local function get_charge_anim(humanoid)
	for _,track in humanoid:GetPlayingAnimationTracks() do 
		if track.Name=="Jump_Charge" then return track end
	end
end

local function stop_charge_jump(humanoid)
	local chargeAnim=get_charge_anim(humanoid)
	if chargeAnim then
		chargeAnim:Stop()
	end
end

_G.sprinting = false
local jumpStart=nil
local jumpCancelled=false
local effects=require(rs:WaitForChild("Effects"))
local LandedEvent=rs:WaitForChild("LandedEvent")
local DangerEvent=rs:WaitForChild("DangerEvent")
local isChargeJumping=temp:WaitForChild("isChargeJumping")

local function jump_start()
	if _G.jumping then return end
	local canContinue=isClimbing.Value==false and isSwimming.Value==false
	_G.jumping=true
	if not canContinue then 
		jumpStart=nil
		return 
	end
	isChargeJumping.Value=true
	local character=player.Character
	if not character then return end
	local lastLanded=character:GetAttribute("LastLanded")
	local humanoid=character:WaitForChild("Humanoid")
	humanoid.JumpHeight=0
	if cs:HasTag(character,"ragdolled") then
		stop_charge_jump(humanoid)
		return
	end
	if humanoid:GetState()==Enum.HumanoidStateType.Freefall or humanoid:GetState()==Enum.HumanoidStateType.Physics then
		stop_charge_jump(humanoid)
		return 
	end
	jumpStart=tick()
	local chargeAnim=humanoid:LoadAnimation(movement:WaitForChild("Jump_Charge"))
	chargeAnim:Play()
	while _G.jumping do
		task.wait()
		if not jumpStart then break end
		local MaxWalkspeed=isSprinting.Value and 32 or 16
		local elapsed=tick()-jumpStart
		local p=math.clamp(elapsed/1,0,1)
		humanoid.WalkSpeed=MaxWalkspeed-(MaxWalkspeed*p)
		if humanoid:GetState()==Enum.HumanoidStateType.Freefall or humanoid:GetState()==Enum.HumanoidStateType.Physics then
			jumpCancelled=true
			break
		end
	end
	stop_charge_jump(humanoid)
	humanoid.WalkSpeed=isSprinting.Value and 32 or 16
end

local function jump_end()
	_G.jumping=false
	isChargeJumping.Value=false
	if jumpCancelled then jumpCancelled=false return end
	if jumpStart==nil then return end
	if isSwimming.Value or isClimbing.Value then return end
	local character=player.Character
	if not character then return end
	local humanoid=character:WaitForChild("Humanoid")
	stop_charge_jump(humanoid)
	if humanoid:GetState()~=Enum.HumanoidStateType.Running and humanoid:GetState()~=Enum.HumanoidStateType.Landed then return end
	humanoid.WalkSpeed=isSprinting.Value and 32 or 16
	local elapsed=tick()-jumpStart
	local p=math.clamp(elapsed/1,0,1)
	humanoid.JumpHeight=math.clamp(p*100,7.5,100)
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	if p>=.5 then -- held for .5 sec or more
		LandedEvent:FireServer()
		DangerEvent:FireServer("HardFall","Landed",nil,character.PrimaryPart.Position,nil)
		local jump=humanoid:LoadAnimation(movement:WaitForChild("Hero_Jump"))
		jump:Play()
		local camera=workspace.CurrentCamera
		local distanceFromCamera = (camera.CFrame.Position - character.PrimaryPart.Position).Magnitude
		local percent = math.clamp(1-(math.clamp(distanceFromCamera - 15,0,100) / 100),0,1)
		_G.camShake(p*1.5,percent)
		effects.LandedEffect(character.PrimaryPart)
	end
	jumpStart=nil
end

local function inputBegan(input:InputObject, gpe:boolean)
	--if _G.tutorial_playing then return end
	if gpe then return end
	if input.UserInputType==Enum.UserInputType.Keyboard then
		if (input.KeyCode == Enum.KeyCode.Space) then
			jump_start()
		elseif input.KeyCode==Enum.KeyCode.LeftShift then
			_G.sprinting = true
			isSprinting.Value = true
		elseif input.KeyCode==Enum.KeyCode.LeftControl then
			if not _G.cooling["Roll"] and not isClimbing.Value then
				_G.cooling["Roll"]=tick()
				roll(workspace:GetServerTimeNow())
			end
		end
	elseif input.UserInputType==Enum.UserInputType.MouseButton1 and selected.Value~=0 then
		if _G.dialogueEngaged==true then return end
		ActionButtonDown.Value=true
		if CheckRagdolled() then return end
		if isRolling.Value then return end
		if isClimbing.Value then return end
		if isChargeJumping.Value then return end
		--if isSprinting.Value then return end
		local ability=GetAbilityName(tostring(selected.Value))
		if ability and not _G.cooling[ability] then
			_G.cooling[ability]=tick()
		end
	end
end

local function inputEnded(input:InputObject)
	if input.UserInputType==Enum.UserInputType.Keyboard then
		if (input.KeyCode == Enum.KeyCode.Space) then
			jump_end()
		elseif (input.KeyCode == Enum.KeyCode.LeftShift) then
			_G.sprinting = false
			isSprinting.Value = false
		end	
	elseif input.UserInputType==Enum.UserInputType.MouseButton1 then -- always turn ActionButtonDown off when you release MB1
		ActionButtonDown.Value = false
	end
end

_ability:WaitForChild("button").InputBegan:Connect(function(input)
	if CheckRagdolled() then return end
	if isRolling.Value then return end
	if isClimbing.Value then return end
	if isChargeJumping.Value then return end
	--if isSprinting.Value then return end
	if input.UserInputType~=Enum.UserInputType.Touch then return end
	if input.UserInputState~=Enum.UserInputState.Begin then return end
	if _G.dialogueEngaged==true then return end
	local ability=GetAbilityName(tostring(selected.Value))
	if ability and not _G.cooling[ability] and not Ability_Focused_Input then
		Ability_Focused_Input=input
		_G.cooling[ability]=tick()
		ActionButtonDown.Value=true	
	end
end)

_ability:WaitForChild("button").InputEnded:Connect(function(input)
	Ability_Focused_Input=nil
	ActionButtonDown.Value=false
end)

_roll:WaitForChild("button").InputBegan:Connect(function(input)
	if input.UserInputType~=Enum.UserInputType.Touch then return end
	if input.UserInputState~=Enum.UserInputState.Begin then return end
	if CheckRagdolled() then return end
	if not Roll_Focused_Input and not isClimbing.Value then
		Roll_Focused_Input=input
		if not _G.cooling["Roll"] then
			_G.cooling["Roll"]=tick()
			roll(workspace:GetServerTimeNow())
		end
	end
end)

_roll:WaitForChild("button").InputEnded:Connect(function(input)
	Roll_Focused_Input=nil
end)

local function jump()
	if _G.jumping then return end --// if already jumping then don't re-jump
	_G.jumping=true
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if humanoid then
		if humanoid:GetState()==Enum.HumanoidStateType.Physics then return end --// don't jump while applying physics
		while _G.jumping do 
			local state=humanoid:GetState()
			if state~=Enum.HumanoidStateType.Freefall and state~=Enum.HumanoidStateType.Jumping then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
			task.wait(1/30)
		end
	end
end

_jump:WaitForChild("button").InputBegan:Connect(function(input)
	if input.UserInputType~=Enum.UserInputType.Touch then return end
	if input.UserInputState~=Enum.UserInputState.Begin then return end
	if CheckRagdolled() then return end
	if Jump_Focused_Input or _G.cooling["Roll"] then return end --// start jump
	Jump_Focused_Input=input
	_jump.icon.ImageTransparency=.5
	--jump()
	jump_start()
end)

_jump:WaitForChild("button").InputEnded:Connect(function(input)
	Jump_Focused_Input=nil
	_G.jumping=false
	_jump.icon.ImageTransparency=.1
	jump_end()
end)

_sprint:WaitForChild("button").InputBegan:Connect(function(input)
	if input.UserInputType~=Enum.UserInputType.Touch then return end
	if input.UserInputState~=Enum.UserInputState.Begin then return end
	if not Sprint_Focused_Input then
		Sprint_Focused_Input=input 
		_G.sprinting = true
		isSprinting.Value=true
		_sprint.icon.ImageTransparency=.5
	end
end)

_sprint:WaitForChild("button").InputEnded:Connect(function(input)
	Sprint_Focused_Input=nil
	_G.sprinting=false 
	isSprinting.Value=false
	_sprint.icon.ImageTransparency=.1
end)

_G.reset_inputs=function()
	Sprint_Focused_Input=nil
	_G.sprinting=false 
	isSprinting.Value=false
	_sprint.icon.ImageTransparency=.1
	
	Jump_Focused_Input=nil
	_G.jumping=false
	_jump.icon.ImageTransparency=.1
	
	Roll_Focused_Input=nil
	Ability_Focused_Input=nil
	ActionButtonDown.Value=false
end

local Reset=controlsUI:WaitForChild("Reset")
Reset:GetPropertyChangedSignal("Value"):Connect(_G.reset_inputs)

local uis=game:GetService("UserInputService")
uis.InputBegan:Connect(inputBegan)
uis.InputEnded:Connect(inputEnded)

player.CharacterAdded:Connect(function(character)
	local humanoid=character:WaitForChild("Humanoid")
	if _G.platform~="mobile" then return end
	humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		local canMove=isWebbing.Value==false and isSwimming.Value==false
		local moving=character:GetAttribute("Moving")
		if humanoid.MoveDirection.Magnitude > 0 then
			if not canMove or moving then return end
			character:SetAttribute("Moving",true)
			task.wait(1)
			if character:GetAttribute("Moving")==true then
				_G.sprinting=true 
				isSprinting.Value=true
			end
		else
			character:SetAttribute("Moving",false)
			_G.sprinting=false
			isSprinting.Value=false
		end
	end)
end)