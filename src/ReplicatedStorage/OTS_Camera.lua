local camera = workspace.CurrentCamera
local ts = game:GetService("TweenService")
local rs = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")
local uis = game:GetService("UserInputService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")
local blur = lighting:WaitForChild("Blur")
local player = game.Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local temp = leaderstats:WaitForChild("temp")
local isSwimming = temp:WaitForChild("isSwimming")
local isClimbing = temp:WaitForChild("isClimbing")
local isWebbing = temp:WaitForChild("isWebbing")
local isRolling = temp:WaitForChild("isRolling")
local swingWebPivot = temp:WaitForChild("swingWebPivot")
local playerGui = player:WaitForChild("PlayerGui")
local targetUI = playerGui:WaitForChild("targetUI")
local hotbarUI = playerGui:WaitForChild("hotbarUI")
local leftUI = playerGui:WaitForChild("leftUI")
local leftUITab = leftUI:WaitForChild("selected")
local hotbarContainer = hotbarUI:WaitForChild("container")
local selectedValue = hotbarContainer:WaitForChild("Selected")

local cs = game:GetService('CollectionService')

local water = workspace:WaitForChild("water")

local CameraRotationsFolder = rs:WaitForChild("ThirdPersonCameraRotations")

local xRotation = CameraRotationsFolder:WaitForChild("X")
local yRotation = CameraRotationsFolder:WaitForChild("Y")

local offset = Vector3.new(2.75,2,8)

local x_offset = 2.75
local y_offset = 2
local z_offset = 8

local zOffsetValue=rs:WaitForChild("OTS_Camera"):WaitForChild("ZOffset")

local x, y, z
local gyro = nil

local handler = {}

handler.cameraToggle = false 
handler.running = false
handler.isShutDown = false

local function getCameraToPositionRotation(cam,pos)
	local A = Vector3.new(cam.X,0,cam.Z)
	local B = Vector3.new(pos.X,0,pos.Z)

	local back = A - B
	local right = Vector3.new(0, 1, 0):Cross(back)
	local up = back:Cross(right)

	local x,y,z = CFrame.fromMatrix(A, right, up, back):ToOrientation()
	return Vector3.new(x,y,x)
end

local function checkTargetForHumanoid(origin,direction,character)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	local result = workspace:Raycast(origin, direction, raycastParams)
	if result then
		local hit = result.Instance
		local humanoid = hit.Parent:FindFirstChild("Humanoid") or hit.Parent.Parent:FindFirstChild("Humanoid")
		if (humanoid) then 
			return humanoid.Parent	
		end
	end
	return nil
end

local buildingBounds = workspace:WaitForChild("BuildingBounds")
local vents = workspace:WaitForChild("Vents")
local blocks = workspace:WaitForChild("blocks")
local snow=workspace:WaitForChild("Ground")

local tracks=workspace:WaitForChild("Traintracks")
local carts=workspace:WaitForChild("cart_bounds")

local function checkObstructions(camCF,origin)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {buildingBounds,vents,blocks,snow,tracks,carts}
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	local raycastResult = workspace:Raycast(
		origin,
		(camCF.p - origin).Unit * 25,
		raycastParams
	)
	local transparencyResult = workspace:Raycast(
		origin,
		(camCF.p - origin).Unit * 5,
		raycastParams
	)
	return raycastResult,transparencyResult
end

local function solveVector(x,z)
	local x_final = 0
	local z_final = 0
	
	local front = x >= 0
	local back = x < 0
	local left = z < 0
	local right = z >= 0
	
	if (front) then -- front
		z_final = (x * 1) * -1
	elseif (back) then -- back
		z_final = math.abs(x * 1)
	end
	
	if (right) then -- right
		x_final = z * 1
	elseif (left) then -- left
		x_final = z * 1
	end

	return x_final, z_final
end

function becomeTransparent(controller,t)
	for i, _ in pairs(controller.cachedParts) do
		i.LocalTransparencyModifier = t
	end
end

function resetTransparency(controller)
	for i, _ in pairs(controller.cachedParts) do
		i.LocalTransparencyModifier = 0
	end
end

--[[
while wait(1) do
	becomeTransparent()
	wait(1)
	resetTransparency()
end
]]

local characterTransparencyValue = rs:WaitForChild("characterTransparency")
local tweenInfoTransparency = TweenInfo.new(.5,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false)
_G.lastUpdate = 0
_G.lastTransparencyTween = nil

_G.updateCharacterInvis = function(character,p)
	if p == _G.lastUpdate then return end 
	_G.lastUpdate = p
	--print("transparency = ",p)
	if _G.lastTransparencyTween ~= nil then
		_G.lastTransparencyTween:Pause()
		--_G.lastTransparencyTween:Destroy()
	end
	_G.lastTransparencyTween = ts:Create(characterTransparencyValue,tweenInfoTransparency,{Value = p})
	_G.lastTransparencyTween:Play()
end

local function returnTheta(startPos,endPos,axis)
	local adjascent = (startPos[axis] - endPos[axis]) -- greater number always first
	local hypotenuse = (startPos-endPos).magnitude
	return math.deg(math.acos(adjascent/hypotenuse))
end

local camShakeAmount = rs:WaitForChild("camShakeAmount")
local camShakeDuration = rs:WaitForChild("camShakeDuration")
local springModule=require(rs:WaitForChild("Spring"))
local springProgress=rs:WaitForChild("Spring"):WaitForChild("progress")
local spring=nil

local playerScripts=player:WaitForChild("PlayerScripts")
local controls=require(playerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
local userInputService=game:GetService("UserInputService")

function handler.Run(controller)
	if (handler.running) then --[[print("already running")]] return end -- prevent thread stack
	handler.running = true
	rs:WaitForChild("OTS_running").Value = true
	-- separate the rotation from the character's position here
	--print("it's running")
	--[[
	
	]]
	local function off()
		_G.updateCharacterInvis(player.Character,0)
		--controller.lastTransparency = 0
		--controller:Update(true)
		--controller:TeardownTransparency()
		--resetTransparency(controller)
		handler.running = false
		rs:WaitForChild("OTS_running").Value = false
	end
	
	local connection
	connection=runService.RenderStepped:Connect(function(dt)
		if not handler.cameraToggle then
			off()
			connection:Disconnect()
			return
		end
		if not (uis.MouseBehavior == Enum.MouseBehavior.LockCenter) then uis.MouseBehavior = Enum.MouseBehavior.LockCenter end
		if (player.Character) and (player.Character.PrimaryPart) then
			--controller:TeardownTransparency()
			local character = player.Character
			local hrp = character.PrimaryPart
			local rightVector = camera.CFrame.RightVector
			local xSurface,zSurface = solveVector(rightVector.X,rightVector.Z)
			local x_rotation = CFrame.Angles(0,math.rad(xRotation.Value),0)
			local y_rotation = CFrame.Angles(math.rad(yRotation.Value),0,0)
			local center = ((CFrame.new(hrp.Position) * CFrame.Angles(x,y,z)) * x_rotation) * y_rotation
			local hrp_offset = CFrame.new(hrp.Position) * CFrame.new(xSurface,camera.CFrame.LookVector.Y * 1,zSurface)
			local result,transparencyResult = checkObstructions(center * CFrame.new(offset),hrp_offset.Position)
			local p = 1
			local transparency = 1

			if result then
				p = math.clamp((result.Position - center.Position).Magnitude/zOffsetValue.Value,0,1)
			end

			if transparencyResult then
				_G.updateCharacterInvis(character,1)
			else 
				_G.updateCharacterInvis(character,0)
			end

			local goalCF=nil
			offset = Vector3.new(p*x_offset,p*y_offset,(p-0.1)*zOffsetValue.Value)
			goalCF=center * CFrame.new(offset) * CFrame.new(-1,0,0)
			
			--[[
			if not spring then
				local start={RightVector=camera.CFrame.RightVector,UpVector=camera.CFrame.UpVector,Position=camera.CFrame.Position}
				local velocity={RightVector=Vector3.new(),UpVector=Vector3.new(),Position=Vector3.new()}
				local goal={RightVector=camera.CFrame.RightVector,UpVector=camera.CFrame.UpVector,Position=goalCF.Position}
				spring=springModule.new(start,velocity,goal)
				spring.frequency=5
				spring.dampener=1
			end
			]]
			
			if camShakeAmount.Value~=0 then
				local amount=math.round(camShakeDuration.Value/(1/60))
				local factor=camShakeAmount.Value/(amount/5)*2
				goalCF*=CFrame.fromEulerAnglesXYZ(math.sin(tick() * 15) * 0.002 * factor, math.sin(tick() * 25) * 0.002 * factor, 0)
			end

			--spring.goal={Position=goalCF.Position,RightVector=camera.CFrame.RightVector,UpVector=camera.CFrame.UpVector}
			--local x,y,z=goalCF:ToOrientation()
			camera.CFrame=goalCF--CFrame.new(spring:update(dt))*CFrame.fromOrientation(x,y,z)
			camera.Focus = camera.CFrame

			local foundGyro = character.PrimaryPart:FindFirstChildOfClass("BodyGyro")

			if not gyro or not foundGyro then
				if not foundGyro then
					gyro = Instance.new("BodyGyro")
					gyro.D = 5
					gyro.MaxTorque = Vector3.new(100000, 100000, 100000)
					gyro.P = 1250
					gyro.Parent = hrp
				else 
					gyro = foundGyro				
				end	
			end

			local canRotate = isWebbing.Value == false and isRolling.Value == false and not cs:HasTag(character,"ragdolled")
			
			if canRotate then
				gyro.D = 5 
				gyro.P = 1250
				gyro.MaxTorque = Vector3.new(100000,100000,100000)
				local x,y,z = center:ToOrientation()
				gyro.CFrame = CFrame.new(center.Position) * CFrame.fromOrientation(0, y, 0)
			end

			if isWebbing.Value then
				gyro.D = 100
				gyro.P = 1250
				if temp:WaitForChild("launching").Value == false then
					local x,y,z = swingWebPivot.Value:ToOrientation()
					local theta = math.abs(returnTheta(swingWebPivot.Value.Position,hrp.Position,"Y"))

					local function isNaN(v)
						return tostring(v) == tostring(0/0)
					end

					if isNaN(theta) then
						theta = 0
					end

					local centerX,centerY,centerZ = center:ToOrientation()
					gyro.CFrame = CFrame.new(gyro.CFrame.Position) * CFrame.fromOrientation(math.rad(theta), y, 0)
				else
					local rotationY = temp:WaitForChild("launchRotation").Value
					if rotationY ~= 0 then
						gyro.CFrame = CFrame.new(center.Position) * CFrame.fromOrientation(0, rotationY, 0)
					end
				end
			end

			--if isRolling.Value then
			--gyro.MaxTorque = Vector3.new(100000,0,100000)
			--end

		else 
			--handler.ShutDown()
			handler.isShutDown = false
			off()
			connection:Disconnect()
			return
		end
	end)
	
end

function handler.Activate()
	--print("activate ots cam")
	if (leftUITab.Value ~= nil) then --[[print("a left ui tab was open")]] return end
	if (handler.isShutDown) then --[[print("can't active ots, shut down.")]] return end
	if handler.cameraToggle then --[[print("ots is already on")]] return end
	if blur.Enabled then --[[print("ui was open")]] return end
	handler.cameraToggle = true
	uis.MouseIconEnabled = false
	targetUI.Enabled = true
	camera.CameraType = Enum.CameraType.Scriptable
	uis.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserGameSettings.RotationType = Enum.RotationType.CameraRelative
	player.Character:WaitForChild("Humanoid").AutoRotate = false
	local camToPlrRotation = getCameraToPositionRotation(camera.CFrame.Position,player.Character.PrimaryPart.Position)
	x,y,z = camToPlrRotation.X, camToPlrRotation.Y, camToPlrRotation.Z
	local foundGyro = player.Character:WaitForChild("HumanoidRootPart"):FindFirstChildOfClass("BodyGyro")
	if (foundGyro) then
		gyro = foundGyro
		gyro.D = 5
		gyro.MaxTorque = Vector3.new(100000, 100000, 100000)
		gyro.P = 1250
		--print("found gyro in ots cam")
	end
	
	--if not _G.controller then
	--repeat task.wait(1/30) until _G.controller
	--end
	--_G.controller:TeardownTransparency()
	
	local run = coroutine.wrap(handler.Run)
	run()
end

function handler.Deactivate()
	--print("ots cam deactivated")
	handler.cameraToggle = false
	uis.MouseIconEnabled = true
	targetUI.Enabled = false
	camera.CameraType = Enum.CameraType.Custom
	UserGameSettings.RotationType = Enum.RotationType.MovementRelative
	player.CameraMaxZoomDistance = 8
	player.CameraMinZoomDistance = 8
	player.CameraMaxZoomDistance = 20
	player.CameraMinZoomDistance = .5
	uis.MouseBehavior = Enum.MouseBehavior.Default
	xRotation.Value = 0
	yRotation.Value = 0
	if not (isSwimming.Value) and not (isClimbing.Value) then -- reminder: if you're swimming OR climbing don't destroy the gyro, use it in those scripts
		if (gyro) then --[[print("gyro destroyed")]] gyro:Destroy() end
	end
	gyro = nil
	spring=nil
	if not (isClimbing.Value) then -- if you're climbing don't change auto rotate back to true
		player.Character:WaitForChild("Humanoid").AutoRotate = true
	end
	--if not _G.controller or handler.running then
	--repeat task.wait(1/30) until _G.controller and handler.running == false
	--end
	
	--_G.controller:SetSubject(player.Character:WaitForChild("Humanoid"))
	--wait(1)
	--resetTransparency(_G.controller)
	--task.wait(1/30)
	--updateCharacterInvis(player.Character,0)
end

function handler.ShutDown() -- reminder: this function turns off OTS cam
	--print("shutdown ots cam")
	handler.isShutDown = true
	if (handler.cameraToggle) then
		handler.Deactivate()
	end
end

function handler.Reboot() -- reminder: this function allows you to use the hotbar and OTS cam after shutdown
	if (isSwimming.Value) then return end
	handler.isShutDown = false
	if (selectedValue.Value ~= 0) then
		--print("activated by reboot")
		handler.Activate()			
	end
end

local TOUCH_SENSITIVTY = Vector2.new(0.00945 * math.pi, 0.003375 * math.pi)
local MOUSE_SENSITIVITY = Vector2.new(0.002 * math.pi, 0.0015 * math.pi)
local PAN_SENSITIVITY = 50

local sensitivityList = {
	["mobile"] = TOUCH_SENSITIVTY,
	["PC"] = MOUSE_SENSITIVITY
}

local function InputTranslationToCameraAngleChange(translationVector, sensitivity)
	if not translationVector or not sensitivity then return end
	local camera = game.Workspace.CurrentCamera
	if camera and camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0 and (camera.ViewportSize.Y > camera.ViewportSize.X) then
		-- Screen has portrait orientation, swap X and Y sensitivity
		return translationVector * Vector2.new( sensitivity.Y, sensitivity.X)
	end
	return translationVector * sensitivity
end

function handler.Update(pan)
	if (handler.cameraToggle) and (blur.Enabled==false) then
		
		if _G.platform == nil then return end
		
		local inversionVector = Vector2.new(1, UserGameSettings:GetCameraYInvertValue())
		local rotateDelta = InputTranslationToCameraAngleChange(PAN_SENSITIVITY*pan, sensitivityList[_G.platform])*inversionVector
		
		xRotation.Value = math.clamp(xRotation.Value - rotateDelta.X,0,360)
		local X = xRotation.Value
		xRotation.Value = X == 0 and 360 or xRotation.Value -- set to 360
		xRotation.Value = X == 360 and 0 or xRotation.Value -- set to 0
		yRotation.Value = math.clamp(yRotation.Value - rotateDelta.Y,-80,80)
	end
end

local previousValue = selectedValue.Value
function handler.DetectAbilitySelected()
	if (selectedValue.Value ~= 0) then
		if (previousValue == 0) then
			handler.Activate()			
		end
	else
		handler.Deactivate()
	end
	previousValue = selectedValue.Value
end

selectedValue:GetPropertyChangedSignal("Value"):Connect(function()
	handler.DetectAbilitySelected()
end)

isSwimming:GetPropertyChangedSignal("Value"):Connect(function()
	if (isSwimming.Value) then 
		handler.ShutDown()
	else 
		handler.Reboot()
	end
end)

isClimbing:GetPropertyChangedSignal("Value"):Connect(function()
	if (isClimbing.Value) then 
		handler.ShutDown()
	else 
		if not cs:HasTag(player.Character,"ragdolled") then
			handler.Reboot()	
		end
	end
end)

return handler
