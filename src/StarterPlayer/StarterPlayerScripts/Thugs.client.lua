local thugs = workspace:WaitForChild("Thugs")
local collectionService = game:GetService("CollectionService")
local tweenService = game:GetService("TweenService")
local healthbarInfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0)

local replicatedStorage = game:GetService("ReplicatedStorage")
local thugFolder = replicatedStorage:WaitForChild("thugs")
local _math = require(replicatedStorage:WaitForChild("math"))

local runService = game:GetService("RunService")
local cs = game:GetService("CollectionService")

local effects = require(replicatedStorage:WaitForChild("Effects"))

local function random1or3()
	return (_math.nearest(_math.defined(1,100))%3)+1
end

local anims = thugFolder:WaitForChild("anims")
local walkAnimation = anims:WaitForChild("walk")
local runAnimation = anims:WaitForChild("run")
local idleAnimation = anims:WaitForChild("idle")
local jumpAnimation = anims:WaitForChild("jump")

local bat_idle = anims:WaitForChild("bat_idle")
local bat_swing = anims:WaitForChild("bat_swing")

local ak_idle = anims:WaitForChild("ak_idle")
local ak_fire = anims:WaitForChild("ak_fire")

local electric_attack = anims:WaitForChild("electric_attack")
local electric_idle = anims:WaitForChild("electric_idle")

local shotgun_attack = anims:WaitForChild("shotgun_fire")
local shotgun_idle = anims:WaitForChild("shotgun_idle")

local flamethrower_idle = anims:WaitForChild("flamethrower_idle")
local flamethrower_hold = anims:WaitForChild("flamethrower_hold")
local flamethrower_attack = anims:WaitForChild("flamethrower_fire")

local minigun_idle = anims:WaitForChild("minigun_idle")
local minigun_fire = anims:WaitForChild("minigun_fire")

local function checkEligibility(thug)
	local properties = thug:WaitForChild("Properties")
	local health = properties:WaitForChild("Health")
	local target = properties:WaitForChild("Target")
	if health.Value == 0 then return false end
	if target.Value == nil then return false end
	if target.Value:IsA("Attachment") then return false end
	if cs:HasTag(thug,"ragdolled") then return false end
	return true
end

local reactionAnims = anims:WaitForChild("reaction")
local reactions = {
	[1] = reactionAnims:WaitForChild("1"),
	[2] = reactionAnims:WaitForChild("2"),
	[3] = reactionAnims:WaitForChild("3")
}

local function stopReactionAnimations(humanoid)
	for _,track in (humanoid:GetPlayingAnimationTracks()) do 
		if track.Animation.Parent == reactionAnims then
			track:Stop()
		end
	end
end

local function stopJumpingAnimations(humanoid)
	for _,track in (humanoid:GetPlayingAnimationTracks()) do 
		if track.Animation.Name == jumpAnimation.Name then
			track:Stop()
		end
	end 	
end

local function batAttack(thug,timer)
	local humanoid = thug:WaitForChild("Humanoid")
	local root = thug.PrimaryPart
	local bat = thug:FindFirstChild("Bat")
	local swingSounds = {
		[1] = root["swing_01"],
		[2] = root["swing_02"],
		[3] = root["swing_03"]
	}
	local swingAnim = humanoid:LoadAnimation(bat_swing)
	swingAnim.Priority = Enum.AnimationPriority.Action

	local animSpeed = 2.5
	local totalFrames = 160
	local animLength = totalFrames/60
	local animDuration = animLength * (1/animSpeed)
	local length = (50/totalFrames) * animDuration

	while true do 
		if (workspace:GetServerTimeNow() - timer) + length > 1 then break end
		runService.RenderStepped:Wait()
	end
	if not checkEligibility(thug) then return end
	local trail = bat:WaitForChild("Handle"):WaitForChild("Trail")
	trail.Enabled = true

	local function swing()
		if not checkEligibility(thug) then return end
		swingSounds[math.random(1,3)]:Play()
	end
	local function ending()
		trail.Enabled = false
	end

	swingAnim:GetMarkerReachedSignal("Swing"):Connect(swing)
	swingAnim:GetMarkerReachedSignal("End"):Connect(ending)
	stopReactionAnimations(humanoid)
	swingAnim:Play(.1,1,animSpeed)
end

local function akAttack(thug,timer)
	local humanoid = thug:WaitForChild("Humanoid")
	local properties = thug:WaitForChild("Properties")
	local ak = thug:FindFirstChildOfClass("Tool")
	local handle = ak:WaitForChild("Handle")
	local fire = handle:WaitForChild("fire")
	local attachment = handle:WaitForChild("Attachment")
	local light = handle:WaitForChild("PointLight")
	local shootAnim = humanoid:LoadAnimation(ak_fire)
	shootAnim.Priority = Enum.AnimationPriority.Action

	local animSpeed = 1
	local totalFrames = 30
	local animLength = totalFrames/60
	local animDuration = animLength * (1/animSpeed)
	local length = (12/totalFrames) * animDuration

	while true do 
		if (workspace:GetServerTimeNow() - timer) + length > 1 then break end
		runService.RenderStepped:Wait()
	end
	if not checkEligibility(thug) then return end
	local function eventReached()
		if not checkEligibility(thug) then return end
		fire:Play()
		for i,v in (attachment:GetChildren()) do 
			v:Emit(1)
		end
		light.Brightness = 2
		task.wait(1/30)
		light.Brightness = 0
	end
	shootAnim:GetMarkerReachedSignal("fire"):Connect(eventReached)
	stopReactionAnimations(humanoid)
	shootAnim:Play(.1,1,1)
end

local function electricAttack(thug,timer)
	local humanoid = thug:WaitForChild("Humanoid")
	local properties = thug:WaitForChild("Properties")
	local root = thug.PrimaryPart
	local swingSounds = {
		[1] = root["swing_01"],
		[2] = root["swing_02"],
		[3] = root["swing_03"]
	}
	local attackAnim = humanoid:LoadAnimation(electric_attack)
	attackAnim.Priority = Enum.AnimationPriority.Action

	local animSpeed = 3
	local totalFrames = 174
	local animLength = totalFrames/60
	local animDuration = animLength * (1/animSpeed)
	local length = (60/totalFrames) * animDuration

	while true do 
		if (workspace:GetServerTimeNow() - timer) + length > 1 then break end
		runService.RenderStepped:Wait()
	end
	if not checkEligibility(thug) then return end

	local function swing()
		if not checkEligibility(thug) then return end
		swingSounds[math.random(1,3)]:Play()
	end

	attackAnim:GetMarkerReachedSignal("swing1"):Connect(swing)
	attackAnim:GetMarkerReachedSignal("swing2"):Connect(swing)
	stopReactionAnimations(humanoid)
	attackAnim:Play(.2,1,animSpeed)
end

local function shotgunAttack(thug,timer)
	local humanoid = thug:WaitForChild("Humanoid")
	local properties = thug:WaitForChild("Properties")
	local shotgun = thug:FindFirstChildOfClass("Tool")
	local handle = shotgun:WaitForChild("Handle")
	local fire = handle:WaitForChild("fire")
	local attachment = handle:WaitForChild("Attachment")
	local light = handle:WaitForChild("PointLight")
	local shootAnim = humanoid:LoadAnimation(shotgun_attack)
	shootAnim.Priority = Enum.AnimationPriority.Action

	local animSpeed = 1
	local totalFrames = 50
	local animLength = totalFrames/60
	local realDuration = animLength * (1/animSpeed)
	local length = (12/totalFrames) * realDuration

	while true do 
		if (workspace:GetServerTimeNow() - timer) + length > 1 then break end
		runService.RenderStepped:Wait()
	end
	if not checkEligibility(thug) then return end
	local function eventReached()
		if not checkEligibility(thug) then return end
		fire:Play()
		for i,v in (attachment:GetChildren()) do 
			v:Emit(1)
		end
		light.Brightness = 2
		task.wait(1/30)
		light.Brightness = 0
	end
	shootAnim:GetMarkerReachedSignal("fire"):Connect(eventReached)
	stopReactionAnimations(humanoid)
	shootAnim:Play(.1,1,animSpeed)
end

local function bruteAttack(thug,timer,attackType)
	local animations = {
		["jab"] = {
			[1] = anims:WaitForChild("jab"),
			[2] = 62, -- total frames
			[3] = 34, -- hit frame
			[4] = 2.5 -- speed
		},
		["hook"] = {
			[1] = anims:WaitForChild("hook"),
			[2] = 76,
			[3] = 34,
			[4] = 2
		},
		["uppercut"] = {
			[1] = anims:WaitForChild("uppercut"),
			[2] = 112,
			[3] = 68,
			[4] = 1
		}
	}

	local humanoid = thug:WaitForChild("Humanoid")

	local animationData = animations[attackType]
	local animation = animationData[1]
	local anim = humanoid:LoadAnimation(animation)
	anim.Priority = Enum.AnimationPriority.Action

	local animSpeed = animationData[4]
	local totalFrames = animationData[2]
	local animLength = totalFrames/60
	local realDuration = animLength * (1/animSpeed)
	local length = (animationData[3]/totalFrames) * realDuration

	--hook= 0.2833333333333333
	-- uppercut=1.133333333333334

	--[[
	while true do 
		if (workspace:GetServerTimeNow() - timer) + length > 1 then break end
		runService.RenderStepped:Wait()
	end
	]]

	if not checkEligibility(thug) then return end
	local function eventReached()
		if not checkEligibility(thug) then return end
		local root = thug.PrimaryPart
		local swingSounds = {
			[1] = root["swing_01"],
			[2] = root["swing_02"],
			[3] = root["swing_03"]
		}
		swingSounds[math.random(1,3)]:Play()
	end
	anim:GetMarkerReachedSignal("swing"):Connect(eventReached)
	stopReactionAnimations(humanoid)
	anim:Play(.2,1,animSpeed)
end

local tweenInfo_tenth = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
local tweenInfo_fifth = TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
local beamCurveTweenInfo = TweenInfo.new(1,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut,-1,true,0)

local function returnAngle(a,b)
	local ignoreY = Vector3.new(1,0,1)
	local lookAt = CFrame.new(a*ignoreY,b*ignoreY)
	local x,y,z = lookAt:ToOrientation()
	return math.deg(y)
end

local function flamethrowerAttack(thug,timer)
	if cs:HasTag(thug,"flameAttack") then --[[print("was already playing attack")]] return end
	local humanoid = thug:WaitForChild("Humanoid")

	local animation = flamethrower_attack
	local anim = humanoid:LoadAnimation(animation)
	anim.Priority = Enum.AnimationPriority.Action

	local animSpeed = 1
	local totalFrames = 120
	local animLength = totalFrames/60
	local realDuration = animLength * (1/animSpeed)
	local length = (10/totalFrames) * realDuration

	while true do 
		if (workspace:GetServerTimeNow() - timer) + length > 1 then break end
		runService.RenderStepped:Wait()
	end

	if not checkEligibility(thug) then return end

	local flamethrower = thug:FindFirstChild("Flamethrower")

	local handle = flamethrower:WaitForChild("Handle")
	local endAttachment = Instance.new("Attachment")
	endAttachment.Parent = workspace.Terrain
	local attachment0 = handle:WaitForChild("0")

	local sound = handle:WaitForChild("Sound")
	local light = attachment0:WaitForChild("Light")
	local beam = attachment0:WaitForChild("Beam")
	local particle = handle:WaitForChild("Attachment"):WaitForChild("Particle")

	beam.Attachment1 = endAttachment

	local p = 0
	local ended = false
	local started = false 
	local startTick = nil

	local curveTween0 = nil
	local curveTween1 = nil

	local endOffset = Vector3.new(1.3, -2.8, -26.6)
	local startOffset = Vector3.new(0, .5, -4)

	local idleAnim = humanoid:LoadAnimation(flamethrower_idle)
	idleAnim.Priority = Enum.AnimationPriority.Core

	local frontPart = handle:WaitForChild("frontPart")
	local sparks0 = frontPart:WaitForChild("sparks0")
	local sparks1 = frontPart:WaitForChild("sparks1")
	local sparks2 = frontPart:WaitForChild("sparks2")

	local function attackStarted()
		if not checkEligibility(thug) then return end
		if started then return end
		cs:AddTag(thug,"flameAttack")
		for _,track in (humanoid:GetPlayingAnimationTracks()) do
			if track.Animation.Name == idleAnimation.Name then
				track:Stop()
			end
		end
		idleAnim:Play()
		endAttachment.WorldCFrame = handle.CFrame * CFrame.new(startOffset)
		p = 0
		startTick = tick()
		started = true
		sound.Volume = 1
		sound:Play()
		particle.Enabled = false
		sparks0.Enabled = true
		local function emit()
			sparks0:Emit(3)
			sparks1:Emit(3)
			sparks2:Emit(3)
		end
		delay(.2,emit)
	end

	local function attackEnded()
		if ended then return end
		--cs:RemoveTag(thug,"flameAttack")
		p = 0
		startTick = tick()
		ended = true
		particle.Enabled = true
		sparks0.Enabled = false
	end

	anim:GetMarkerReachedSignal("end"):Connect(attackEnded)
	anim:GetMarkerReachedSignal("fire"):Connect(attackStarted)
	stopReactionAnimations(humanoid)
	anim:Play(.2,1,animSpeed)

	local goal = nil
	local _start = tick()
	while tick() - _start < realDuration do
		if not checkEligibility(thug) and ended == false then
			started = true -- incase it wasn't already
			attackEnded()
			break
		end
		if startTick ~= nil then
			if started == true and ended == false then
				p = math.clamp(tick() - startTick / 1,0,1)
				beam.Transparency = NumberSequence.new{-- (time, value)
					NumberSequenceKeypoint.new(0, 1), -- leave 
					NumberSequenceKeypoint.new(.2, 1-p),
					NumberSequenceKeypoint.new(.6, 1-p),
					NumberSequenceKeypoint.new(.9, 1-(p*(1-.75))),
					NumberSequenceKeypoint.new(1, 1), -- leave
				}
				local start = handle.CFrame * CFrame.new(startOffset)
				local goal = handle.CFrame * CFrame.new(endOffset)
				tweenService:Create(
					endAttachment,
					tweenInfo_fifth,
					{
						WorldCFrame = start:Lerp(goal,p)
					}):Play()
				light.Brightness = 2.5*p
				light.Range = 40*p
			elseif started == true and ended == true then
				p = math.clamp(tick() - startTick / 1,0,1)
				beam.Transparency = NumberSequence.new{-- (time, value)
					NumberSequenceKeypoint.new(0, 1), -- leave 
					NumberSequenceKeypoint.new(.2, p),
					NumberSequenceKeypoint.new(.6, p),
					NumberSequenceKeypoint.new(.9, p),
					NumberSequenceKeypoint.new(1, 1), -- leave
				}
				local goal = handle.CFrame * CFrame.new(endOffset)
				tweenService:Create(
					endAttachment,
					tweenInfo_fifth,
					{
						WorldCFrame = goal
					}):Play()
				light.Brightness = 2.5-(p*2.5)
				sound.Volume = 1-p
				if p > .75 then
					cs:RemoveTag(thug,"flameAttack")
				end
			end
		end
		task.wait(1/30)
	end
	cs:RemoveTag(thug,"flameAttack")
	-- reset everything that needs to be reset here
	beam.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 1),  
		NumberSequenceKeypoint.new(.2, 1),
		NumberSequenceKeypoint.new(.6, 1),
		NumberSequenceKeypoint.new(.9, 1),
		NumberSequenceKeypoint.new(1, 1), 
	}
	sound.Volume = 0
	sparks0.Enabled = false
	particle.Enabled = true
	anim:Stop()
	idleAnim:Stop()
	light.Brightness = 0
	light.Range = 0
	endAttachment.WorldCFrame = handle.CFrame * CFrame.new(startOffset)
	beam.Attachment1 = nil
	endAttachment:Destroy()
end

local function minigunAttack(thug,timer)
	
	local latency=workspace:GetServerTimeNow()-timer
	
	local humanoid=thug:WaitForChild("Humanoid")
	local anim=humanoid:LoadAnimation(minigun_fire)
	local anim_length=2 -- seconds
	local anim_speed=1-(latency/anim_length)
	
	local minigun=thug:WaitForChild("Minigun")
	local animationController=minigun:WaitForChild("AnimationController")
	local rotate=minigun:WaitForChild("Folder"):WaitForChild("Rotate")
	local rotate_anim=animationController:LoadAnimation(rotate)
	local muzzle=minigun:WaitForChild("Cylinder"):WaitForChild("Muzzle")
	local root=minigun:WaitForChild("Root")
	
	--// sounds
	local shoot=root:WaitForChild("shoot")
	local start=root:WaitForChild("start")
	local stop=root:WaitForChild("stop")
	
	if not checkEligibility(thug) then return end
	
	local isShooting=false
	local function StartShoot()
		if not checkEligibility(thug) then return end
		isShooting=true
		shoot:Play()
		local light=muzzle:WaitForChild("Light")
		while isShooting do 
			muzzle:WaitForChild("Flash"):Emit(1)
			local isOn=light.Brightness==2
			light.Brightness=isOn and 0 or 2
			task.wait(.1)
		end
		light.Brightness=0
	end
	
	local function EndShoot()
		isShooting=false
		shoot:Stop()
	end
	
	local function StartRotate()
		rotate_anim:Play()
		start:Play()
	end
	
	local function EndRotate()
		for _,track in animationController:GetPlayingAnimationTracks() do 
			track:Stop()
		end
		if not checkEligibility(thug) then return end
		stop:Play()
	end
	
	anim.Priority=Enum.AnimationPriority.Action 
	anim:GetMarkerReachedSignal("StartShoot"):Connect(StartShoot)
	anim:GetMarkerReachedSignal("EndShoot"):Connect(EndShoot)
	anim:GetMarkerReachedSignal("EndRotate"):Connect(EndRotate)
	stopReactionAnimations(humanoid)
	anim:Play(.2,1,anim_speed)
	StartRotate()
	
end

local attackFunctions = {
	["ak"] = akAttack,
	["bat"] = batAttack,
	["electric"] = electricAttack,
	["shotgun"] = shotgunAttack,
	["brute"] = bruteAttack,
	["flamethrower"] = flamethrowerAttack,
	["minigun"] = minigunAttack
}

local function createSignals(thug)
	local anims = thugFolder:WaitForChild("anims")
	local humanoid = thug:WaitForChild("Humanoid")
	local properties = thug:WaitForChild("Properties")

	local remote = thugFolder:WaitForChild("RemoteEvents"):FindFirstChild(thug.Name)
	if remote then
		remote.OnClientEvent:Connect(function(action,timer,attackType)
			if action == "Melee" then
				effects.MeleeEffect(thug:WaitForChild("Head").Position)
			elseif action == "attack" then
				local attackFunction = attackFunctions[properties:WaitForChild("Type").Value]
				if attackFunction then
					attackFunction(thug,timer,attackType)
				end
			end
		end)
	end

	local leftBaton
	local rightBaton
	if properties.Type.Value == "electric" then
		rightBaton= thug:WaitForChild("RightBaton")
		leftBaton= thug:WaitForChild("LeftBaton")
		rightBaton:WaitForChild("Trail").Enabled = true
		rightBaton:WaitForChild("loop"):Play()
		leftBaton:WaitForChild("Trail").Enabled = true
		leftBaton:WaitForChild("loop"):Play()
	end

	local root = thug:WaitForChild("HumanoidRootPart")
	local runSound = root:WaitForChild("run")
	local jumpSound = root:WaitForChild("jump")

	local health = properties:WaitForChild("Health")
	local maxHealth = properties:WaitForChild("MaxHealth")

	local healthUI = thug:WaitForChild("Health")
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
			thug.PrimaryPart:WaitForChild("death"):Play()
			runSound.Volume = 0
			jumpSound.Volume = 0
			if properties.Type.Value == "electric" then
				rightBaton:WaitForChild("Trail").Enabled = false
				rightBaton:WaitForChild("loop"):Stop()
				leftBaton:WaitForChild("Trail").Enabled = false
				leftBaton:WaitForChild("loop"):Stop()
			end
			tweenHealth()
			--return
		end
		healthUI.Enabled = health.Value < maxHealth.Value and true or false
		if health.Value ~= healthAmount then
			local difference = healthAmount - health.Value
			healthAmount = health.Value
			if difference > 0 then -- took damage
				local random = random1or3()
				local anim = humanoid:LoadAnimation(reactions[random])
				anim.Priority = Enum.AnimationPriority.Movement
				stopJumpingAnimations(humanoid)
				anim:Play()
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

	thug:SetAttribute("Connected", true)
end

workspace.Terrain.ChildAdded:Connect(function(child)
	if child.Name == "impact" then
		child:WaitForChild("Sound"):Play()
		--print("impact sound played!")
		for i,v in (child:GetChildren()) do 
			if v:IsA("ParticleEmitter") then 
				v:Emit(1)
			end
		end
	end 
end)

local function playHoldAnimation(humanoid,holdAnimation,speed)
	if not holdAnimation then return end
	local holdAnim = humanoid:LoadAnimation(holdAnimation)
	holdAnim.Priority = Enum.AnimationPriority.Movement
	holdAnim:Play(.2,1,speed)
end

local function playIdleAnimation(humanoid)
	if cs:HasTag(humanoid.Parent,"flameAttack") then return end
	local idleAnim = humanoid:LoadAnimation(idleAnimation)
	idleAnim.Priority = Enum.AnimationPriority.Core
	idleAnim:Play()
end

local function stopMovingAnimations(humanoid)
	for _,track in (humanoid:GetPlayingAnimationTracks()) do 
		if track.Animation.Name == runAnimation.Name then
			track:Stop()
		end
		if track.Animation.Name == walkAnimation.Name then
			track:Stop()
		end
	end
end

local function getPlayingAnimations(humanoid)
	local dictionary = {}
	for _,track in (humanoid:GetPlayingAnimationTracks()) do 
		if dictionary[track.Animation.Name] then -- this is a double
			track:Stop()
		else 
			dictionary[track.Animation.Name] = track
		end
	end
	return dictionary
end

local holdAnimations = {
	["ak"] = {
		[1] = ak_idle,
		[2] = 1
	},
	["bat"] = {
		[1] = bat_idle,
		[2] = 1
	},
	["electric"] = {
		[1] = electric_idle,
		[2] = .1
	},
	["shotgun"] = {
		[1] = shotgun_idle,
		[2] = 1
	},
	["brute"] = {
		[1] = nil,
		[2] = nil
	},
	["flamethrower"] = {
		[1] = flamethrower_hold,
		[2] = 1
	},
	["minigun"] = {
		[1] = minigun_idle,
		[2] = 1
	}
}

local ts = game:GetService("TweenService")
local lightTweenInfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,true,0)
local function electricBatonEffect(leftBaton,rightBaton)
	local batons = {leftBaton,rightBaton}
	for _,baton in (batons) do
		local box = baton:WaitForChild("Box")
		local particle = box:WaitForChild("Bolts")
		--local light = box:WaitForChild("PointLight")
		particle:Emit(2)
		--ts:Create(light,lightTweenInfo,{Brightness = math.random(6,9)}):Play()
	end
end

local tweenInfo=TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)

while true do 
	for i,thug in thugs:GetChildren() do 
		--if i%5==0 then task.wait(1/30) end
		if not thug:IsDescendantOf(workspace) or not thug.PrimaryPart then continue end
		if not thug:GetAttribute("Connected") then
			--print("made signal!")
			createSignals(thug)
		end
		local root = thug.PrimaryPart
		local runSound = root:WaitForChild("run")
		local jumpSound = root:WaitForChild("jump")

		local verticalSpeed = (root.Velocity * Vector3.new(0,1,0)).Magnitude
		local horizontalSpeed = (root.Velocity * Vector3.new(1,0,1)).Magnitude

		local humanoid = thug:WaitForChild("Humanoid")

		local properties = thug:WaitForChild("Properties")
		local health = properties:WaitForChild("Health")

		if properties.Type.Value == "electric" then
			electricBatonEffect(thug:WaitForChild("LeftBaton"),thug:WaitForChild("RightBaton"))
		end

		if not (health.Value>0) then continue end
		if cs:HasTag(thug,"ragdolled") then
			-- check if sound was played before
			-- if it wasn't, play death sound
			local played=thug:GetAttribute("RagdollSoundPlayed")
			if not played then
				root:WaitForChild("death"):Play()
				thug:SetAttribute("RagdollSoundPlayed",true)
			end
			
			continue 
		else 
			thug:SetAttribute("RagdollSoundPlayed",false) -- reset the attribute
		end

		local target = properties:WaitForChild("Target")

		local holdAnimation = holdAnimations[properties.Type.Value][1]
		local holdAnimationSpeed = holdAnimations[properties.Type.Value][2]
		-- get the playing animations, get rid of dupes automatically
		local playingAnimations = getPlayingAnimations(humanoid)

		local idleAnim = playingAnimations[idleAnimation.Name]
		local holdAnim = holdAnimation == nil and true or playingAnimations[holdAnimation.Name]
		local runAnim = playingAnimations[runAnimation.Name]
		local walkAnim = playingAnimations[walkAnimation.Name]
		local jumpAnim = playingAnimations[jumpAnimation.Name]

		if not idleAnim then
			playIdleAnimation(humanoid)
		end

		if not holdAnim then
			playHoldAnimation(humanoid,holdAnimation,holdAnimationSpeed)
		end

		local waist=thug:WaitForChild("UpperTorso"):WaitForChild("Waist")
		local waistC0 = properties:WaitForChild("WaistC0").Value

		if target.Value ~= nil then
			if target.Value:IsA("Attachment") then
				if horizontalSpeed >= 3 then
					if runAnim then
						runAnim:Stop()
						runAnim = nil
					end	
					if not walkAnim then
						local walkAnim = humanoid:LoadAnimation(walkAnimation)
						walkAnim.Priority = Enum.AnimationPriority.Idle
						walkAnim:Play(.2,1,1)
						runSound.PlaybackSpeed = 0.75
						runSound.Volume = 0.5
					end
				else 
					stopMovingAnimations(humanoid)
				end
				ts:Create(waist,tweenInfo,{C0=waistC0}):Play()
			elseif target.Value.PrimaryPart then 
				if horizontalSpeed >= 3 then
					if walkAnim then
						walkAnim:Stop()
						walkAnim = nil
					end
					if not runAnim then
						local runAnim = humanoid:LoadAnimation(runAnimation)
						runAnim.Priority = Enum.AnimationPriority.Idle
						runAnim:Play(.2,1,1)
						runSound.PlaybackSpeed = 3
						runSound.Volume = 1.25
					end							
				else 
					stopMovingAnimations(humanoid)
				end
				local targetPos = target.Value.PrimaryPart.Position
				local rootPos = thug.PrimaryPart.Position
				local direction = (rootPos - targetPos).Unit * 100
				ts:Create(waist,tweenInfo,{C0=waistC0*CFrame.Angles(-math.rad(direction.Y)*.625,0,0)}):Play()
			end
		end
		if verticalSpeed > 1 then
			if not jumpAnim then
				local jumpAnim = humanoid:LoadAnimation(jumpAnimation)
				jumpAnim.Priority = Enum.AnimationPriority.Movement
				stopReactionAnimations(humanoid)
				jumpAnim:Play(.2,1,1)
				jumpSound:Play()
			end
		else 
			stopJumpingAnimations(humanoid)
		end
	end
	task.wait(1/10)
end