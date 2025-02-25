local rs = game:GetService("ReplicatedStorage")
local ragdollEvent = rs:WaitForChild("ragdollEvent")
local constraints = rs:WaitForChild("constraints")
local cs = game:GetService("CollectionService")
local runService = game:GetService("RunService")

local _math = require(rs:WaitForChild("math"))

local ragdoll = {}

function ragdoll.setupJoints(c) -- server initiate
	local dict = {
		["Head"] = {c.UpperTorso.NeckRigAttachment, c.Head.NeckRigAttachment, constraints.Neck},
		["UpperTorso"] = {c.LowerTorso.WaistRigAttachment, c.UpperTorso.WaistRigAttachment, constraints.Waist},
		["LowerTorso"] = {c.HumanoidRootPart.RootRigAttachment, c.LowerTorso.RootRigAttachment, constraints.Root},
		["LeftUpperArm"] = {c.UpperTorso.LeftShoulderRigAttachment, c.LeftUpperArm.LeftShoulderRigAttachment, constraints.LeftShoulder},
		["LeftLowerArm"] = {c.LeftUpperArm.LeftElbowRigAttachment, c.LeftLowerArm.LeftElbowRigAttachment,constraints.LeftElbow},
		["LeftHand"] = {c.LeftLowerArm.LeftWristRigAttachment, c.LeftHand.LeftWristRigAttachment,constraints.LeftWrist},
		["RightUpperArm"] = {c.UpperTorso.RightShoulderRigAttachment, c.RightUpperArm.RightShoulderRigAttachment,constraints.RightShoulder},
		["RightLowerArm"] = {c.RightUpperArm.RightElbowRigAttachment, c.RightLowerArm.RightElbowRigAttachment,constraints.RightElbow},
		["RightHand"] = {c.RightLowerArm.RightWristRigAttachment, c.RightHand.RightWristRigAttachment,constraints.RightWrist},
		["LeftUpperLeg"] = {c.LowerTorso.LeftHipRigAttachment, c.LeftUpperLeg.LeftHipRigAttachment,constraints.LeftHip},
		["LeftLowerLeg"] = {c.LeftUpperLeg.LeftKneeRigAttachment, c.LeftLowerLeg.LeftKneeRigAttachment,constraints.LeftKnee},
		["LeftFoot"] = {c.LeftLowerLeg.LeftAnkleRigAttachment, c.LeftFoot.LeftAnkleRigAttachment,constraints.LeftAnkle},
		["RightUpperLeg"] = {c.LowerTorso.RightHipRigAttachment, c.RightUpperLeg.RightHipRigAttachment,constraints.RightHip},
		["RightLowerLeg"] = {c.RightUpperLeg.RightKneeRigAttachment, c.RightLowerLeg.RightKneeRigAttachment,constraints.RightKnee},
		["RightFoot"] = {c.RightLowerLeg.RightAnkleRigAttachment, c.RightFoot.RightAnkleRigAttachment,constraints.RightAnkle}
	}
	for i,v in pairs(dict) do
		local newConstraint = v[3]:Clone()
		newConstraint.Attachment0 = v[1]
		newConstraint.Attachment1 = v[2]
		newConstraint.Parent = c
		--v[1].Enabled = false
	end
	dict = nil -- cover tracks
	cs:AddTag(c,"setup")
	--print("set up joints!")
end

local disabledStates = {
	[Enum.HumanoidStateType.PlatformStanding] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Swimming] = true,
	[Enum.HumanoidStateType.Flying] = true,
	[Enum.HumanoidStateType.FallingDown] = true
}

local physicsService = game:GetService("PhysicsService")

function ragdoll.ray(origin,direction)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {workspace.Concrete}
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local ghost={
	["RightLowerLeg"]=true,
	["LeftLowerLeg"]=true,
	["RightUpperLeg"]=true,
	["LeftUpperLeg"]=true,
	["LeftUpperArm"]=true,
	["RightUpperArm"]=true,
	["LeftLowerArm"]=true,
	["RightLowerArm"]=true,
	["UpperTorso"]=true
}

local function playerRagdollCollisions(model)
	for index, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CollisionGroup="Ragdoll"
		end
		if part.Name == "HumanoidRootPart" then
			part.CollisionGroup="Characters"
		end
	end
	--print("ghosted ",player.Name)
end

local ignoreNames = {
	["RightBaton"] = true,
	["LeftBaton"] = true,
	["LeftGlove"] = true,
	["RightGlove"] = true,
	["Box"] = true
}

local function thugCollisions(thug,bool)
	for index,part in pairs(thug:GetDescendants()) do 
		if part:IsA("BasePart") then
			if ignoreNames[part.Name] or part.Parent:IsA("Tool") then
				part.CollisionGroup="Ghost"
			else 
				if part.Name == "Sphere" then
					part.CollisionGroup="Spheres"
				else 
					local group = bool == true and "Ragdoll" or "Thugs"
					part.CollisionGroup=group
				end
			end
		end
	end
end

local function ghostCollisions(model)
	cs:AddTag(model,"ghosted")
	for index, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CollisionGroup="Ghost"
		end
	end
end

local function characterCollisions(model)
	cs:RemoveTag(model,"ghosted")
	for index, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local collisionGroup = part.Name == "RootLegs" and "Ghost" or "Characters"
			part.CollisionGroup=collisionGroup
		end
	end
	--print("removed ghost for ",player.Name)
end

function ragdoll.disableStates(humanoid)
	for i,_ in disabledStates do 
		humanoid:SetStateEnabled(i,false)
	end
end

function ragdoll.disableAllStates(humanoid)
	local states=Enum.HumanoidStateType:GetEnumItems()
	for key,state in states do 
		if state~=Enum.HumanoidStateType.None and state~=Enum.HumanoidStateType.Dead then
			humanoid:SetStateEnabled(state,false)
		end
	end
end

function ragdoll.setStatesEnabled(humanoid,bool,ignore)
	local stateTypes, secondArg = Enum.HumanoidStateType:GetEnumItems()
	while true do
		local key, value = next(stateTypes, secondArg)
		if not (key) then
			break
		end
		secondArg = key
		if not disabledStates[value] then
			if value ~= ignore and value ~= Enum.HumanoidStateType.None and value ~= Enum.HumanoidStateType.Dead then
				humanoid:SetStateEnabled(value, bool)
			end
		else 
			if value ~= Enum.HumanoidStateType.None and value ~= Enum.HumanoidStateType.Dead then
				humanoid:SetStateEnabled(value,false)
			end
		end
	end
end

function ragdoll.startNPC(humanoid,hrp)
	thugCollisions(humanoid.Parent,true)
	humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	ragdoll.setStatesEnabled(humanoid,false,Enum.HumanoidStateType.Ragdoll)
	hrp.CanCollide = false
	humanoid.AutoRotate = false
	--print("start NPC")
end

function ragdoll.endNPC(humanoid,hrp)
	--local bp=rs:WaitForChild("RecoveryBodyPosition"):Clone()
	local model=hrp.Parent 
	local offset=model.Properties.Type.Value=="brute" and 4.5 or 3
	local origin=hrp.Position
	local result=ragdoll.ray(origin,Vector3.new(0,-100,0))
	if result then
		local groundPos=result.Position
		local distance=(groundPos-origin).Magnitude
		offset=distance>offset and 0 or offset
	end
	local pos=offset+origin.Y
	local ignoreY=Vector3.new(1,0,1)
	local target=model.Properties.Target.Value
	local lookAt=(not target:IsA("Attachment") and target.PrimaryPart) and 
		target.PrimaryPart.Position*ignoreY+Vector3.new(0, pos, 0) or 
		Vector3.new(target.WorldPosition.X, pos, target.WorldPosition.Z)
	hrp.CFrame=CFrame.new(Vector3.new(origin.X,pos,origin.Z),lookAt)
	--bp.Parent=hrp
	--game:GetService("Debris"):AddItem(bp,1)
	thugCollisions(humanoid.Parent,false)
	ragdoll.setStatesEnabled(humanoid,true)
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	hrp.CanCollide = true
	humanoid.AutoRotate = true
	--print("end NPC")
end

function ragdoll.clientStart(cam,character,hrp,head,humanoid)
	if _G.deathScreen then
		_G.deathScreen(true)
	end
	character:SetAttribute("GettingUp", true)
	local player = game.Players:GetPlayerFromCharacter(character)
	--if humanoid.Health > 0 then
	--playerRagdollCollisions(character)	
	--end
	ragdoll.setStatesEnabled(humanoid,false,Enum.HumanoidStateType.Ragdoll)
	humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	--humanoid.Animator:Destroy()--smoother ragdoll
	--cam.CameraSubject = hrp
	if player then 
		local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
		controls:Disable()
		--player.CameraMaxZoomDistance = 8
		--player.CameraMinZoomDistance = 8		
	end
	--cam.CameraType = Enum.CameraType.Watch
	humanoid.AutoRotate = false
	workspace.Gravity = 35 -- cool slomo effect
end

function ragdoll.clientEnd(cam,hrp,head,humanoid)
	--print("client end")
	--Instance.new("Animator",humanoid)
	if _G.deathScreen then
		_G.deathScreen(false)
	end
	ghostCollisions(hrp.Parent)
	ragdoll.setStatesEnabled(humanoid,true)
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	local player = game.Players:GetPlayerFromCharacter(hrp.Parent)
	if player then
		local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
		controls:Enable()
		player.CameraMaxZoomDistance = 20
		player.CameraMinZoomDistance = .5
	end
	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = humanoid
	humanoid.AutoRotate = true
	--characterCollisions(hrp.Parent)
	local function change()
		task.wait(1/20)
		local character = hrp.Parent
		local isRagdolled = cs:HasTag(character,"ragdolled")
		if isRagdolled then return end
		character:SetAttribute("GettingUp", false)
		characterCollisions(hrp.Parent)
	end
	local f = coroutine.wrap(change)
	f()
	workspace.Gravity = 98.1 -- reset the gravity
end

local function ServerNetworkOwnership(model,timer,duration,player)
	while true do 
		local elapsed=workspace:GetServerTimeNow()-timer
		local p=math.clamp(elapsed/duration,0,1)
		if p==1 or model.Parent==nil then 
			if model.Parent~=nil then
				model.PrimaryPart:SetNetworkOwner(player)--[[print("ended network ownership")]] 
			end
			break 
		end
		model.PrimaryPart:SetNetworkOwner()
		playerRagdollCollisions(model)
		task.wait()
	end
end

function ragdoll.startPlayer(player,timer,duration)
	local character=player.Character
	local humanoid=character:WaitForChild("Humanoid")
	local hrp=character:WaitForChild("HumanoidRootPart")
	humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	local f=coroutine.wrap(ServerNetworkOwnership)
	f(character,timer,duration,player)
	ragdoll.setStatesEnabled(humanoid,false,Enum.HumanoidStateType.Ragdoll)
	--hrp.CanCollide = false
	humanoid.AutoRotate = false
end

function ragdoll.endPlayer(player)
	local character=player.Character
	--character.PrimaryPart.CanCollide = true
	characterCollisions(character)
	character.PrimaryPart:SetNetworkOwner(player)
end

local function get_motors(model)
	local motor6s = {
		model.Head.Neck,
		model.UpperTorso.Waist,
		model.LowerTorso.Root,
		model.LeftUpperArm.LeftShoulder,
		model.LeftLowerArm.LeftElbow,
		model.LeftHand.LeftWrist,
		model.RightUpperArm.RightShoulder,
		model.RightLowerArm.RightElbow,
		model.RightHand.RightWrist,
		model.LeftUpperLeg.LeftHip,
		model.LeftLowerLeg.LeftKnee,
		model.LeftFoot.LeftAnkle,
		model.RightUpperLeg.RightHip,
		model.RightLowerLeg.RightKnee,
		model.RightFoot.RightAnkle
	}
	return motor6s
end

local function enable_motors(motor6s)
	for i = 1,#motor6s do
		motor6s[i].Enabled = true
		motor6s[i] = nil -- clear the table
	end
end

local function disable_motors(motor6s)
	for i = 1,#motor6s do
		motor6s[i].Enabled = false
	end
end

function ragdoll.recover(player,model,motor6s)
	-- check health if not dead first
	local isNPC = player == nil
	if isNPC then
		local health = model.Properties.Health
		if not (health.Value > 0) then return end
	else 
		if not (model.Humanoid.Health > 0) then return end		
	end
	
	if not (cs:HasTag(model,"Died")) then
		--print("re-enabling motor6D joints!")
		enable_motors(motor6s)
		cs:RemoveTag(model,"ragdolled")
		cs:RemoveTag(model,"tripped")
		if player then
			player.leaderstats.temp.lastRagdollRecovery.Value = tick()
			ragdoll.endPlayer(player)
			ragdollEvent:FireClient(player,false)
		else
			--print("recover NPC")
			model.Properties.lastRagdollRecovery.Value = tick()
			ragdoll.endNPC(model.Humanoid,model.PrimaryPart)
		end
	else 
		--print("dead, don't recover")
	end
end

local function recoverVillain(villain,humanoid)
	local properties = villain.Properties
	if not (properties.Health.Value > 0) then return end -- don't recover venom if health is 0
	villain.Events.Ragdoll:FireAllClients(false)
	local currentCF = villain.PrimaryPart.CFrame
	local gyro = villain.PrimaryPart:FindFirstChildOfClass("BodyGyro")
	if gyro then
		gyro.MaxTorque = Vector3.new(0,0,0)
	end
	ragdoll.setStatesEnabled(humanoid,true)
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)	
	cs:RemoveTag(villain,"ragdolled")
	cs:RemoveTag(villain,"tripped")
	properties.lastRagdollRecovery.Value = tick()
	print("recovered villain")
end

local function ragdollVillain(villain,humanoid)
	villain.Events.Ragdoll:FireAllClients(true)
	local currentCF = villain.PrimaryPart.CFrame
	local gyro = villain.PrimaryPart:FindFirstChildOfClass("BodyGyro")
	if gyro then
		gyro.CFrame = currentCF
		gyro.MaxTorque = Vector3.new(100000,100000,100000)
	end
	ragdoll.setStatesEnabled(humanoid,false,Enum.HumanoidStateType.Physics)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	print("ragdolled villain")
end

local function setCollisions(model,collisiongroup)
	for index,part in pairs(model:GetDescendants()) do 
		if part:IsA("BasePart") then
			part.CollisionGroup=collisiongroup
		end
	end
end

local WebStunRemote=rs:WaitForChild("WebStunRemote")

function ragdoll.ragdoll(player,model,recoveryTime,action,villain,override,ability,isClient) -- server initiate
	
	if not model.PrimaryPart then return end
	
	if isClient then -- Client-sided ragdoll for R15 villains
		if not cs:HasTag(model,"setup") then
			ragdoll.setupJoints(model)
			cs:AddTag(model,"setup")
		end
		cs:AddTag(model,"ragdolled")
		local motor6s=get_motors(model)
		if action=="recover" then
			cs:RemoveTag(model,"ragdolled")
			enable_motors(motor6s)
			return
		end
		--setCollisions(model,"Default")
		--local humanoid=model:WaitForChild("Humanoid")
		--humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,true)
		--humanoid:ChangeState(Enum.HumanoidStateType.Physics) 
		--humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
		--humanoid.PlatformStand=false
		--humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll) 
		disable_motors(motor6s)
		return
	end
	
	--print("tried to ragdoll")
	if cs:HasTag(model,"ragdolled") and not override then return end -- one needs to be true to continue
	
	local canContinue = false
	
	if player ~= nil then
		local leaderstats = player.leaderstats
		local temp = leaderstats.temp
		local lastRagdollRecovery = temp.lastRagdollRecovery
		local elapsed = tick() - lastRagdollRecovery.Value
		local isDead=not(model.Humanoid.Health>0)
		if elapsed>=.25 or isDead then -- ragdoll debounce for players
			canContinue = true
		else
			--print("recovery for player was only",elapsed,"seconds ago")
			local states={
				[Enum.HumanoidStateType.PlatformStanding]=true,
				[Enum.HumanoidStateType.Physics]=true,
				[Enum.HumanoidStateType.Flying]=true,
				[Enum.HumanoidStateType.FallingDown]=true
			}
			if states[model.Humanoid:GetState()] then
				model.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
	else
		local properties = model.Properties
		local lastRagdollRecovery = properties.lastRagdollRecovery
		local elapsed = tick() - lastRagdollRecovery.Value
		local isDead=not(properties.Health.Value>0)
		if elapsed>=.5 or isDead or ability=="Anti Gravity" then -- ragdoll debounce for NPCs
			canContinue = true
		else 
			--print("recovery for NPC was only",elapsed,"seconds ago")
		end
	end
	
	if not canContinue then return end
	
	if ability=="Snare Web" or ability=="Trip Web" or ability=="Anti Gravity" then
		WebStunRemote:FireAllClients(model,recoveryTime,workspace:GetServerTimeNow())
	end
	
	cs:AddTag(model,"ragdolled")
	local ragdollData = nil
	local originalPosition = model.PrimaryPart.Position
	if villain then -- custom ragdoll for villains (skinned meshes)
		ragdollData = model.ragdollData
		local humanoid = model.Humanoid
		ragdollVillain(model,humanoid)
		if (action == "recover") and ragdollData ~= nil then
			--[[
			local start = ragdollData.start
			local duration = ragdollData.duration
			while true do
				if workspace:GetServerTimeNow() - tonumber(start.Value) >= duration.Value then -- these values can change
					break
				end
				wait(.2)
			end
			]]
			task.wait(recoveryTime)
			if model.Parent ~= nil then -- make sure model still exists
				local humanoid = model.Humanoid
				recoverVillain(model,humanoid)
			end	
		end
		return
	end
	
	local push = coroutine.wrap(function()
		local root = model.PrimaryPart
		local direction = root.Velocity.Magnitude > 3 and 1 or -1
		local start = tick()
		while tick() - start < 1 do 
			local percent = math.clamp((tick() - start) / 1,0,1)
			local p = 1-percent
			root.Velocity = (root.CFrame.LookVector*direction) * 2.5
			task.wait(1/30)
		end
	end)
	
	if player ~= nil then
		if (model == player.Character) then
			ragdollData = player.leaderstats.ragdollData
			local humanoid = model.Humanoid
			--ragdoll.setStatesEnabled(humanoid,false,Enum.HumanoidStateType.Ragdoll)
			--humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
			ragdollEvent:FireClient(player,true,recoveryTime,workspace:GetServerTimeNow())
			ragdoll.startPlayer(player,workspace:GetServerTimeNow(),recoveryTime==0 and 100 or recoveryTime)
		end
	else
		ragdollData = model:FindFirstChild("ragdollData")
		ragdoll.startNPC(model.Humanoid,model.PrimaryPart)
		push()
	end
	
	local motor6s=get_motors(model)
	disable_motors(motor6s)
	
	if (action == "recover") and ragdollData ~= nil then
		--[[
		local start = ragdollData.start
		local duration = ragdollData.duration
		while true do
			if workspace:GetServerTimeNow() - tonumber(start.Value) >= duration.Value then -- these values can change
				break
			end
			wait(.2)
		end
		]]
		task.wait(recoveryTime)
		if model.Parent ~= nil then
			ragdoll.recover(player,model,motor6s)
		else 
			--print("it's a different character now")
		end	
	end
	
end


return ragdoll

