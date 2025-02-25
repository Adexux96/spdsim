
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local leaderstats = player:WaitForChild("leaderstats")
local temp = leaderstats:WaitForChild("temp")
local isSwimming = temp:WaitForChild("isSwimming")
local isClimbing = temp:WaitForChild("isClimbing")
local isWebbing = temp:WaitForChild("isWebbing")
local character = script.Parent
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local head = character:WaitForChild("Head")

--local TransparencyModule = require(player.PlayerScripts:WaitForChild("PlayerModule").CameraModule.TransparencyController)
--local controller = TransparencyModule.new()
--controller:SetupTransparency(character)
--_G.controller = controller

--if not _G.controller then
--repeat task.wait(1/30) until _G.controller
--end

--_G.controller:SetSubject(humanoid)

--_G.controller:TeardownTransparency()
--print("teared down transparency controller")

local cs = game:GetService("CollectionService")
local rs = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local runService = game:GetService("RunService")
local fallDamageEvent = rs:WaitForChild("fallDamageEvent")
local camera = workspace.CurrentCamera

local NOHANDOUT_ID = 04484494845

local animationsLoaded = character:WaitForChild("AnimationsLoaded")

local customAnimate = rs:WaitForChild("Animate")
local defaultAnimate = character:WaitForChild("Animate")
if not defaultAnimate:FindFirstChild("Custom") then
	defaultAnimate.Parent = game:GetService("ReplicatedFirst")
	local customClone = customAnimate:Clone()
	for i_,stringValue in pairs(defaultAnimate:GetChildren()) do
		if stringValue:IsA("StringValue") then
			local clone = stringValue:Clone()
			clone.Parent = customClone
		end
	end
	defaultAnimate:Destroy()
	for _,track in pairs(humanoid:GetPlayingAnimationTracks()) do 
		track:Stop()
	end
	task.wait(1/30)
	customClone.Parent = character
	customClone.Disabled = false
	if character.PrimaryPart.Velocity.Magnitude > 0 then
		
	end
end

animationsLoaded.Value = true

local function DisableHandOut(character)
	local Animator = character:WaitForChild("Animate")
	local Animation = Instance.new("Animation")
	Animation.AnimationId = "http://www.roblox.com/asset/?id="..NOHANDOUT_ID
	
	local ToolNone = Animator:FindFirstChild("toolnone")
	if ToolNone then
		local NewTool = Instance.new("StringValue")
		NewTool.Name = "toolnone"
		Animation.Name = "ToolNoneAnim"
		Animation.Parent = NewTool
		ToolNone:Destroy()
		NewTool.Parent = Animator
	end
end

DisableHandOut(character)

local _math = require(rs:WaitForChild("math"))

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

local animsFolder = game:GetService("ReplicatedStorage"):WaitForChild("animations")
local idleAnim = animsFolder:WaitForChild("idle"):WaitForChild("fight_idle")

local function stopIdle(humanoid)
	for key,track in pairs(humanoid:GetPlayingAnimationTracks()) do
		if track.Animation == idleAnim or track.Animation.Parent==nil then
			track:Stop()
		end
	end
end
stopIdle(humanoid)

local function playIdle(humanoid)
	stopIdle(humanoid)
	local anim = humanoid:LoadAnimation(idleAnim)
	anim:Play()
end

local selected = playerGui:WaitForChild("hotbarUI"):WaitForChild("container"):WaitForChild("Selected")
if selected.Value ~= 0 then 
	playIdle(humanoid)
end

--humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
--humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
--humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
humanoid.UseJumpPower = false

--humanoid.BreakJointsOnDeath = false

local movementAnims = rs:WaitForChild("animations"):WaitForChild("movement")
local landingAnimation = movementAnims:WaitForChild("Landing")
local hardLandingAnimation=movementAnims:WaitForChild("HardLanding")

local wasHighEnough = false
local runningCheck = false

local function castRay(origin,target,length)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	local raycastResult = workspace:Raycast(
		origin,
		(target - origin).Unit * length,
		raycastParams
	)
	return raycastResult
end

local function checkHeight(root)
	while runningCheck do 
		if not wasHighEnough then
			local result = castRay(root.Position,(root.CFrame * CFrame.new(Vector3.new(0,-humanoid.JumpHeight,0)).Position),humanoid.JumpHeight)
			if not result then
				wasHighEnough = true
				break
			end			
		end
		task.wait(1/30)
	end
end

local function startFreefallLoop()
	local start = tick()
	local animPlaying = false
	while humanoid:GetState() == Enum.HumanoidStateType.Freefall do 
		if tick() - start >= 1 then -- has been falling for 1 second or more
			if not animPlaying then
				local result = castRay(root.Position,(root.CFrame * CFrame.new(Vector3.new(0,-30,0)).Position),30)
				if not result then
					animPlaying = true
					local freefallAnim = humanoid:LoadAnimation(movementAnims:WaitForChild("freefall"))
					freefallAnim:Play(.5,1,1)
					break
				end
			end
		end
		task.wait(1/30)
	end
end

local function Custom_Physical_Properties(density)
	for i,v in character:GetDescendants() do 
		if v:IsA("BasePart") and v.Name~="HumanoidRootPart" then
			local properties=PhysicalProperties.new(Enum.Material.Plastic)
			v.CustomPhysicalProperties=PhysicalProperties.new(density,properties.Friction,properties.Elasticity,properties.FrictionWeight,properties.ElasticityWeight)
		end
	end
end
Custom_Physical_Properties(0.0001)

local effects=require(rs:WaitForChild("Effects"))
local LandedEvent=rs:WaitForChild("LandedEvent")
local DangerEvent=rs:WaitForChild("DangerEvent")

humanoid.StateChanged:Connect(function(oldState,newState)
	
	local root = character:WaitForChild("HumanoidRootPart")
	
	if oldState == Enum.HumanoidStateType.GettingUp then
		if newState == Enum.HumanoidStateType.Physics then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	local startPos
	local newFalling = newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.FallingDown
	local oldFalling = oldState == Enum.HumanoidStateType.Freefall or oldState == Enum.HumanoidStateType.FallingDown
	local landed = newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.GettingUp
	
	local hard_landing=false
	if newState==Enum.HumanoidStateType.Freefall then
		player:SetAttribute("LastFall",tick())
	end
	
	if newState==Enum.HumanoidStateType.Landed then
		local last_fall=player:GetAttribute("LastFall")
		if last_fall then
			local elapsed=tick()-last_fall 
			if elapsed>=1.5 then
				hard_landing=true
				LandedEvent:FireServer()
				DangerEvent:FireServer("HardFall","Landed",nil,root.Position,nil)
				
				local f=coroutine.wrap(effects.LandedEffect)
				f(root)
				root.Velocity=Vector3.new(0,0,0)
				--root.Anchored=true
				--task.delay(1/5,function()
					--root.Anchored=false
				--end)
			end
		end
		character:SetAttribute("LastLanded",tick())
	end	
	
	local running = newState == Enum.HumanoidStateType.Running
	local dead = newState == Enum.HumanoidStateType.Dead
	local physics = newState == Enum.HumanoidStateType.Physics
	
	if running or dead or physics then
		runningCheck = false
		wasHighEnough = false 
	end
	
	if (landed) then
		cs:RemoveTag(character,'isFalling')
		local hardLandingPlaying=false
		local ignore={
			["Roll"]=true,
			["HardLanding"]=true
		}
		for i,track in pairs(humanoid:GetPlayingAnimationTracks()) do
			if track.Animation.Name=="HardLanding" then
				hardLandingPlaying=true
			end
			local isMovement=track.Animation.Parent.Name == "movement"
			local isIgnored=ignore[track.Animation.Name]
			local isSecondJump=track.Animation.Name=="SecondJump"
			if track.Animation.Parent then
				if not isIgnored and (isMovement or isSecondJump) then
					track:Stop()
					--print("stopped",track.Animation.Name)
				end
			end
		end
		for _,animation in animsFolder:GetChildren() do 
			if animation.Name=="SecondJump" then
				animation:Destroy()
			end
		end
		--if wasHighEnough then
		if isWebbing.Value or hardLandingPlaying then return end
			local landedAnim = hard_landing and humanoid:LoadAnimation(hardLandingAnimation) or humanoid:LoadAnimation(landingAnimation)
			--print("playing",landedAnim.Animation.Name)
		landedAnim:Play()
		landedAnim.Stopped:Wait()
		
		--end
	end
	
	if (newFalling) then
		cs:AddTag(character,'isFalling')
		local f = coroutine.wrap(startFreefallLoop)
		f()
		--startPos = player.Character.HumanoidRootPart.Position.Y
		--local f = coroutine.wrap(checkHeight)
		--runningCheck = true
		--f(root)
	end
	
	if (oldFalling) then -- or if swimming (idk if i'm going to use physics yet)
		--runningCheck = false
		--wasHighEnough = false 
		if (landed) then
			
			--[[
			if not (startPos) then return end
			local distance = math.floor((startPos - player.Character.HumanoidRootPart.Position.Y)*10)/10
			if (distance >= 15) then
				fallDamageEvent:FireServer(distance)
				--print("fell ",distance)
			end
			]]
		end
	end
	
end)

local ragdoll=require(rs:WaitForChild("ragdoll"))
ragdoll.setStatesEnabled(humanoid,true,nil)
