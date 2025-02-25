local cs = game:GetService("CollectionService")

local player = game.Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local isSwimming = leaderstats:WaitForChild("temp"):WaitForChild("isSwimming")
local dataRemote = player:WaitForChild("dataRemote")
local character = nil
local playerGui = player:WaitForChild("PlayerGui")
local rs = game:GetService("ReplicatedStorage")
local cs = game:GetService("CollectionService")
local ragdoll = require(rs:WaitForChild("ragdoll"))
local camera = workspace.CurrentCamera
local waterHeight = rs:WaitForChild("waterHeight")

local animationFolder = rs:WaitForChild("animations")

_G.swimming = false
_G.jumping = false
_G.cameraUnderwater = false

local physicsService = game:GetService("PhysicsService")

local function ghostPlayer()
	if not player.Character then return end
	cs:AddTag(character,"ghosted")
	for index, part in (player.Character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CollisionGroup="Ghost"
		end
	end
	--print("ghosted ",player.Name)
end

local function undoGhost()
	if not player.Character then return end
	cs:RemoveTag(character,"ghosted")
	for index, part in (player.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			local collisionGroup = part.Name == "RootLegs" and "Ghost" or "Characters"
			part.CollisionGroup=collisionGroup
		end
	end
	--print("removed ghost for ",player.Name)
end


local yAngle = 0
local xAngle = 0
local zAngle = 0

local headPos,torsoPos = nil,nil
local lastRotation = nil

local gyro,velocity,position = nil,nil,nil

local function removeSwimMovers()
	--print("remove swim movers")
	if (gyro) then
		gyro:Destroy()
		--print("destroyed gyro")
	end
	if (velocity) then
		velocity:Destroy()
	end
	if (position) then
		position:Destroy()
	end	

	gyro = nil
	velocity = nil
	position = nil
end

local animsFolder = rs:WaitForChild("animations")
local idleAnims = animsFolder:WaitForChild("idle")

local function stopAllOtherTracks(humanoid)
	for _,track in (humanoid:GetPlayingAnimationTracks()) do 
		if track.Animation:IsDescendantOf(animsFolder) then
			if track.Animation ~= idleAnims:WaitForChild("fight_idle") then
				track:Stop()
			end
		end
	end
end

local function startSwim(arg)
	--print("start swim")
	workspace.Gravity = 0
	character = player.Character
	if not (character) then return end
	local hrp,humanoid = character:WaitForChild("HumanoidRootPart"),character:WaitForChild("Humanoid")
	
	--ghostPlayer()
	
	stopAllOtherTracks(humanoid)
	-- reminder: the destroying stuff is to prevent duping of swim movers ;)
	if (gyro) then
		gyro:Destroy()
	end

	if (velocity) then
		velocity:Destroy()
	end

	if (position) then
		position:Destroy()
	end

	if not (humanoid:GetState() == Enum.HumanoidStateType.Physics) then
		ragdoll.setStatesEnabled(humanoid,false,Enum.HumanoidStateType.Physics)
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	if (hrp:FindFirstChild("BodyGyro")) then
		gyro = hrp:FindFirstChild("BodyGyro")
		gyro.D = 200
		gyro.MaxTorque = Vector3.new(100000, 100000, 100000)
		gyro.P = 1000
	else 
		gyro = Instance.new("BodyGyro")
		gyro.D = 200
		gyro.MaxTorque = Vector3.new(100000, 100000, 100000)
		gyro.P = 1000
		gyro.Parent = hrp
	end

	velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(100000,100000,100000)
	velocity.P = 10000
	velocity.Velocity = Vector3.new(0,0,0)
	velocity.Parent = hrp

	position = Instance.new("BodyPosition")
	position.D = 1250
	position.MaxForce = Vector3.new(0,0,0)
	position.P = 1000000
	position.Position = Vector3.new(0,0,0)
	position.Parent = hrp

	dataRemote:FireServer("changeSwim",true)
	_G.jumping = false
	_G.swimming = true
	isSwimming.Value = true
end

local function stopSwim()
	--print("stop swim")
	headPos,torsoPos = nil,nil
	lastRotation = nil
	character = player.Character
	if not (character) then return end
	local hrp,humanoid = character:WaitForChild("HumanoidRootPart"),character:WaitForChild("Humanoid")
	
	if not cs:HasTag(character,"ragdolled") then
		workspace.Gravity = 98.1
		--undoGhost()
	end
	
	ragdoll.setStatesEnabled(humanoid,true)
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)	

	removeSwimMovers()

	dataRemote:FireServer("changeSwim",false)
	_G.jumping = false
	_G.swimming = false
	isSwimming.Value = false
end

local controlMod = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
--controlMod:Disable()
local playerMovement = require(game:GetService("ReplicatedStorage"):WaitForChild("playerMovement"))
local controls = {forward = false, backward = false, left = false, right = false, notMoving = true}

local function getAngle(v1,v2) -- X = Z; Y = X
	local dir = v1 - v2
	local Angle =  math.atan2(dir.Y,dir.X)
	return  math.deg(Angle)
end

local function returnSwimData(vector,direction,cf)
	local x,y,z = direction.X,direction.Y,direction.Z
	controls.forward = vector.Z < 0
	controls.backward = vector.Z > 0
	controls.left = vector.X <= -.1
	controls.right = vector.X >= .1
	controls.notMoving = (vector.Z == 0) and (vector.X == 0)
	if (controls.forward) and not (controls.left) and not (controls.right) then
		x = -90 
		x += (cf.LookVector.Y/2 * math.abs(x))
		z = 0
		return "forward",x,y,z

	elseif (controls.backward) and not (controls.left) and not (controls.right) then 
		x = 90 
		x += (cf.LookVector.Y/2 * math.abs(x))
		z = 0
		return "backward",x,y,z

	elseif (controls.left) and not (controls.forward) and not (controls.backward) then 
		x = -90
		z = y	
		y = 0
		return "left",x,y,z

	elseif (controls.right) and not (controls.forward) and not (controls.backward) then 
		x = -90
		z = y 
		y = 0
		return "right",x,y,z

	elseif (controls.right) and (controls.forward) then 
		x = -90
		x += (cf.LookVector.Y/2 * math.abs(x))
		z = y
		y = 0
		return "upper right",x,y,z

	elseif (controls.left) and (controls.forward) then
		x = -90
		x += (cf.LookVector.Y/2 * math.abs(x))
		z = y
		y = 0
		return "upper left",x,y,z

	elseif (controls.right) and (controls.backward) then 
		x = 90
		x += (cf.LookVector.Y/2 * math.abs(x))
		z = y-180
		y = 180
		return "lower right",x,y,z

	elseif (controls.left) and (controls.backward) then 
		x = 90
		x += (cf.LookVector.Y/2 * math.abs(x))
		z = y-180
		y = 180
		return "lower left",x,y,z

	elseif (controls.notMoving) then 
		return "none"
	end
end

local tween = TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
local ts = game:GetService("TweenService")

local function clampMagnitude(v, max)
	if (v.magnitude == 0) then return Vector3.new(0,0,0) end -- prevents NAN,NAN,NAN
	return v.Unit * math.min(v.Magnitude, max)
end

local function getPlayerRotation(headPos,torsoPos)
	local A = Vector3.new(torsoPos.X,0,torsoPos.Z)
	local B = Vector3.new(headPos.X,0,headPos.Z)

	local back = A - B
	local right = Vector3.new(0, 1, 0):Cross(back)
	local up = back:Cross(right)

	local x,y,z = CFrame.fromMatrix(A, right, up, back):ToOrientation()
	return Vector3.new(x,y,x)
end

local _math = require(rs:WaitForChild("math"))

local swim_movement = "none"
local function isMovingDownward(yLook)
	--print(yLook)
	local standard = .5
	if (yLook > standard) then
		if (swim_movement == "lower left") then
			return true
		end
		if (swim_movement == "lower right") then
			return true
		end
		if (swim_movement == "backward") then
			return true
		end
	elseif (yLook < -standard) then
		if (swim_movement == "forward") then
			return true
		end
		if (swim_movement == "upper left") then
			return true
		end
		if (swim_movement == "upper right") then
			return true
		end		
	end
	return false
end

local waveHeight = nil
local movingDown = nil

local isPlaying = leaderstats:WaitForChild("temp"):WaitForChild("isPlaying")

while true do
	waveHeight = -13+waterHeight.Value 
	local character = player.Character
	local root,head,humanoid = nil,nil,nil
	gyro = nil
	position = nil
	velocity = nil
	if (character) then
		root = character:FindFirstChild("HumanoidRootPart")
		head = character:FindFirstChild("Head")
		humanoid = character:FindFirstChild("Humanoid")
		if (root) then 
			gyro = root:FindFirstChild("BodyGyro")
			position = root:FindFirstChild("BodyPosition")
			velocity = root:FindFirstChild("BodyVelocity")
		end
	end
	if root and _G.jumping ~= nil and isPlaying.Value then -- necesary elements in order to continue
		local rootPos = root.Position
		local isInWaterZone = true
		local camInWaterZone = true
		local isWebSlinging = false
		if (camInWaterZone) then
			if (waveHeight) then
				local aboveWater = camera.CFrame.Position.Y > (waveHeight+.01)
				local belowWater = camera.CFrame.Position.Y <= (waveHeight-.01)
				if (aboveWater) and (_G.cameraUnderwater) then
					_G.cameraUnderwater = false
					_G.updateLighting("underwater",false)
				elseif (belowWater) and not (_G.cameraUnderwater) then
					_G.cameraUnderwater = true
					_G.updateLighting("underwater",true)
				end
			end
		else
			_G.cameraUnderwater = false
			_G.updateLighting("underwater",false)
		end
		if (isInWaterZone) then
			local aboveWater = rootPos.Y > (waveHeight+1)
			local belowWater = rootPos.Y <= (waveHeight-1)
			if not (_G.swimming) then
				if (belowWater) then
					startSwim()
				end
			elseif (_G.swimming) then
				if (aboveWater) then
					stopSwim()
				end
				if (belowWater) then
					if not (gyro) or not (velocity) or not (position) then -- if you do not have either of these body movers
						--print("underwater, no movers, yet not swimming?")
						startSwim()
					end
				end
			end
		end					
		if (isWebSlinging == false) and (_G.swimming) and (gyro) and (velocity) and (position) and (humanoid) then
			movingDown = isMovingDownward(camera.CFrame.LookVector.Y)
			if (humanoid.Health < 1) or (cs:HasTag(character,"ragdolled")) then -- player is dead or ragdolled later make incapacitated functionality
				if (gyro) and (lastRotation ~= nil) then
					gyro.CFrame = CFrame.new(root.Position) * CFrame.Angles(math.rad(90),0,lastRotation.Y > 0 and -lastRotation.Y or math.abs(lastRotation.Y)) -- x,z,y
				end
				if (velocity) then
					velocity.Velocity = Vector3.new(0,7,0)
				end
				if (position) then
					position.Position = Vector3.new(rootPos.X,waveHeight,rootPos.Z)
					position.MaxForce = Vector3.new(0,rootPos.Y > (waveHeight-.5) and 1000000 or 0,0)
				end	
			else -- player is alive and not ragdolled, later make incapacitated functionality
				if (movingDown) or (_G.jumping) then
					if (position) then
						position.MaxForce = Vector3.new(0,0,0)
					end
				elseif not (movingDown) then
					if not (_G.jumping) then
						if (position) then
							position.Position = Vector3.new(rootPos.X,waveHeight,rootPos.Z)
							position.MaxForce = Vector3.new(0,rootPos.Y > (waveHeight-.5) and 1000000 or 0,0)
						end					
					end
				end				
			end

			if not (humanoid.Health < 1) and not (cs:HasTag(character,"ragdolled")) then
				local moveVector = playerMovement.GetMoveVector(playerMovement)
				local x = math.clamp(moveVector.X,-1,1)
				local z = math.clamp(moveVector.Z,-1,1)
				local cf = camera.CFrame
				local movement,xAngle,yAngle,zAngle = returnSwimData(Vector3.new(x,0,z),Vector3.new(0,getAngle(Vector2.new(0,0),Vector2.new(z,x)),0),cf)
				swim_movement = movement
				local direction = cf:VectorToWorldSpace(Vector3.new(x,0,z))
				if (movement ~= "none") then
					lastRotation = getPlayerRotation(head.Position,root.Position)
					local _modifiedLookVector = Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
					local newCF = CFrame.new(root.Position,root.Position + _modifiedLookVector) * CFrame.Angles(math.rad(xAngle),math.rad(yAngle),math.rad(zAngle))
					gyro.CFrame = newCF					
				elseif (movement == "none") then
					if (lastRotation == nil) then
						local x,y,z = root.CFrame:ToOrientation()
						gyro.CFrame = CFrame.new(root.Position) * CFrame.Angles(0,y,0)
					else
						gyro.CFrame = CFrame.new(root.Position) * CFrame.Angles(lastRotation.X,lastRotation.Y,lastRotation.Z)
					end		
				end
				local topSpeed = humanoid.WalkSpeed
				local bouyancy = 0--movingDown and 0 or 7
				if (_G.jumping) then
					bouyancy = 14
				else
					bouyancy = 0
				end
				if (cs:HasTag(root.Parent,'isFalling')) then
					local fallingSpeed = _math.clampMagnitude(root.Velocity,120)
					velocity.Velocity = fallingSpeed
					topSpeed = math.floor(fallingSpeed.magnitude)
					cs:RemoveTag(root.Parent,'isFalling')
				end
				ts:Create(velocity,tween,{Velocity = clampMagnitude(direction*topSpeed,topSpeed)+ Vector3.new(0,bouyancy,0)}):Play()
			end
		end	
	end
	waterHeight:GetPropertyChangedSignal("Value"):Wait()
end