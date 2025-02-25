-- Decompiled with the Synapse X Luau decompiler.

local camera = game:GetService("Workspace").CurrentCamera;

local sprint = script.Parent:WaitForChild("Sprint");
local tweenService = game:GetService("TweenService");
local debris = game:GetService("Debris");
local player = game:GetService("Players").LocalPlayer;

local rs =game:GetService("ReplicatedStorage")
local movement = require(rs:WaitForChild("playerMovement"))
local _math = require(rs:WaitForChild("math"))

local debounce = 0;

local function makeLine()
	local rotation = math.rad(math.random(360));
	local line = script.Line:Clone();
	line.Rotation = math.deg(rotation);
	line.Position = UDim2.fromScale(0.5 + math.cos(rotation) * 0.5, 0.5 + math.sin(rotation) * (sprint.AbsoluteSize.X / sprint.AbsoluteSize.Y) * 0.5);
	line.ImageLabel.Size = UDim2.fromScale(math.random(80, 120) / 100, 0.05);
	line.ImageLabel.ImageTransparency = 1;
	line.Parent = sprint;
	tweenService:Create(line.ImageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.5, 0), 
		ImageTransparency = 0
	}):Play();
	debris:AddItem(line, 0.25);
end;

local FOV_max = 85
local FOV_min = 70
local max_speed = 50
local min_speed = 24

local normal_speed = 16
local sprint_speed = 32

local FFTick = nil
local FFThresh = 1

local function streak()
	if tick() - debounce >= 0.05 then
		debounce = tick();
		for i = 1, math.random(3, 5) do
			makeLine();
		end;
	end;
end

local speedPercent = 0
local walkSpeed = 16

function lerp(speedPercent, percent, divide)
	return speedPercent + (percent - speedPercent) * divide;
end;

local leaderstats = player:WaitForChild("leaderstats")
local temp = leaderstats:WaitForChild("temp")

local isSprinting = temp:WaitForChild("isSprinting")
local isWebbing = temp:WaitForChild("isWebbing")
local isClimbing = temp:WaitForChild("isClimbing")
local isSwimming = temp:WaitForChild("isSwimming")

local runService = game:GetService("RunService")

local clock = rs:WaitForChild("clock")

local zOffsetValue=rs:WaitForChild("OTS_Camera"):WaitForChild("ZOffset")
local cs=game:GetService("CollectionService")

local ragdollStart=nil
local ragdollCameraPos=nil
local isRagdolled=false

local function FOVLerp(start,goal,alpha)
	return ((goal-start)*alpha)+start
end

local camShakeAmount = rs:WaitForChild("camShakeAmount")
local camShakeDuration = rs:WaitForChild("camShakeDuration")

while true do 
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local hrp = character:WaitForChild("HumanoidRootPart")
	local moveVector = movement.GetMoveVector(movement)
	if cs:HasTag(character,"ragdolled") then
		if not isRagdolled then
			isRagdolled=true
			ragdollStart=tick()
			ragdollCameraPos=camera.CFrame.Position
		end
		camera.CameraType=Enum.CameraType.Scriptable
		local goalCF=CFrame.new(ragdollCameraPos,hrp.Position)
		local lerpedCF=camera.CFrame:Lerp(goalCF,.15)
		if camShakeAmount.Value~=0 then
			local amount=math.round(camShakeDuration.Value/(1/60))
			local factor=camShakeAmount.Value/(amount/5)*2
			local rotation=CFrame.fromEulerAnglesXYZ(math.sin(tick() * 15) * 0.002 * factor, math.sin(tick() * 25) * 0.002 * factor, 0)
			camera.CFrame=lerpedCF*rotation
		else
			camera.CFrame=lerpedCF
		end
		local distanceFromCharacter=(ragdollCameraPos-character.PrimaryPart.Position).Magnitude
		local reduction=math.clamp(distanceFromCharacter/50,0,1)*20
		local FOVGoal=70-reduction
		local elapsed=tick()-ragdollStart
		local p=math.clamp(elapsed/1.5,0,1)
		camera.FieldOfView=FOVLerp(camera.FieldOfView,FOVGoal,p)
		--clock:GetPropertyChangedSignal("Value"):Wait()
		runService.RenderStepped:Wait()
		continue
	else 
		isRagdolled=false 
		ragdollStart=nil
		ragdollCameraPos=nil
		--speedPercent = math.clamp(lerp(speedPercent, (hrp.Velocity.magnitude - walkSpeed) / (64 - walkSpeed), 0.03), 0, 1)
		speedPercent=math.clamp(lerp(speedPercent, (hrp.Velocity.magnitude - walkSpeed) / (100 - walkSpeed), 0.03),0,math.huge)
		camera.FieldOfView = _G.cutscenePlaying and 85 or math.clamp(70 + (speedPercent * 20),70,90)
		zOffsetValue.Value=zOffsetValue:GetAttribute("base")+(speedPercent*8)
	end

	local isInFreefall = humanoid:GetState() == Enum.HumanoidStateType.Freefall
	local hasBeenFalling = false
	if (isInFreefall) then
		if (FFTick == nil) then
			FFTick = tick()
		else 
			if (tick() - FFTick >= FFThresh) then 
				hasBeenFalling = true
			end
		end
	else
		FFTick = nil
	end

	--humanoid.JumpHeight = isSprinting.Value and moveVector.Magnitude > 0 and 20 or 7.5
	
	if not (hasBeenFalling) then
		if (hrp.Velocity.Magnitude >= min_speed)--[[(isSprinting.Value)]] then
			local isDead = humanoid:GetState() == Enum.HumanoidStateType.Dead
			if (moveVector.Magnitude > 0) then
				if not isDead then
					streak()
				end
			end
		else
			if isWebbing.Value and hrp.Velocity.Magnitude >= min_speed then
				streak()
			end	
		end
	else
		if (hrp.Velocity.Magnitude >= min_speed) then
			streak()
		end
	end
	--clock:GetPropertyChangedSignal("Value"):Wait()
	runService.RenderStepped:Wait()
end

