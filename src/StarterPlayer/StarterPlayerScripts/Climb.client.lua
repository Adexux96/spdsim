local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = nil
local leaderstats  = player:WaitForChild("leaderstats")
local temp = leaderstats:WaitForChild("temp")
local isClimbing = temp:WaitForChild("isClimbing")
local runService = game:GetService("RunService")

local cs = game:GetService("CollectionService")

local rs = game:GetService("ReplicatedStorage")
local animsFolder = rs:WaitForChild("animations")
local movementAnims = animsFolder:WaitForChild("movement")

local dataRemote = player:WaitForChild("dataRemote")

local rs =game:GetService("ReplicatedStorage")
local movement = require(rs:WaitForChild("playerMovement"))
local climb_idle=movementAnims:WaitForChild("Climb_Idle")

local hotbarUI = playerGui:WaitForChild("hotbarUI")
local abilitySelected = hotbarUI:WaitForChild("container"):WaitForChild("Selected")

local climbDebounce = .75 -- seconds it takes after you stop to be able to start climbing again

local BuildingBounds = workspace:WaitForChild("BuildingBounds")

local function castRay(whitelist,origin,target,length)
	length = length ~= nil and length or 50
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = whitelist
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	local raycastResult = workspace:Raycast(
		origin,
		(target - origin).Unit * length,
		raycastParams
	)
	--[[
	if (raycastResult ~= nil) then
		local distance = (origin - raycastResult.Position).Magnitude
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.Size = Vector3.new(.1, .1, distance)
		p.BrickColor = BrickColor.Red()
		p.Name = "Ray"
		p.CFrame = CFrame.lookAt(origin, ((origin + raycastResult.Position)/2))*CFrame.new(0, 0, -distance/2)
		p.Parent = workspace
		game:GetService("Debris"):AddItem(p,.1)
	end]]
	return raycastResult
end

local function getNormalFromFace(part, normalId)
	return part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(normalId))
end

local function getFaceFromNormal(normalVector, part)

	local TOLERANCE_VALUE = 1 - 0.001
	local allFaceNormalIds = {
		Enum.NormalId.Front,
		Enum.NormalId.Back,
		Enum.NormalId.Bottom,
		Enum.NormalId.Top,
		Enum.NormalId.Left,
		Enum.NormalId.Right
	}    

	for _, normalId in ( allFaceNormalIds ) do
		-- If the two vectors are almost parallel,
		if getNormalFromFace(part, normalId):Dot(normalVector) > TOLERANCE_VALUE then
			return normalId -- We found it!
		end
	end

	return nil -- None found within tolerance.

end

--[[
	[Enum.NormalId.Front] = Vector3.new(0,0,-1),
	[Enum.NormalId.Back] = Vector3.new(0,0,1),
	[Enum.NormalId.Left] = Vector3.new(-1,0,0),
	[Enum.NormalId.Right] = Vector3.new(1,0,0)
]]

local faces = { -- the current face you're on, then the nearest 2 faces

	[Enum.NormalId.Front] = {
		[Enum.NormalId.Left] = Vector3.new(-1,1,0),
		[Enum.NormalId.Right] = Vector3.new(1,1,0)
	},
	[Enum.NormalId.Back] = {
		[Enum.NormalId.Left] = Vector3.new(-1,1,0),
		[Enum.NormalId.Right] = Vector3.new(1,1,0)
	},
	[Enum.NormalId.Left] = {
		[Enum.NormalId.Front] = Vector3.new(0,1,-1),
		[Enum.NormalId.Back] = Vector3.new(0,1,1)
	},
	[Enum.NormalId.Right] = {
		[Enum.NormalId.Front] = Vector3.new(0,1,-1),
		[Enum.NormalId.Back] = Vector3.new(0,1,1)
	},
}

local faceEdges = {
	[Enum.NormalId.Front] = {
		[Enum.NormalId.Right] = function(part)
			local size = Vector3.new(2, 2, 1)
			local pX = (size.X/part.Size.X) - (size.X/part.Size.X)
			local xOffset = math.abs(pX-1)
			local zOffset = -math.abs((size.Z/part.Size.Z)+1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(0,0,part.Size.Z)

			return CFrame.new(cf.Position,lookAt.Position)	
		end,
		[Enum.NormalId.Left] = function(part)
			local size = Vector3.new(2, 2, 1)
			local pX = (size.X/part.Size.X) - (size.X/part.Size.X)
			local xOffset = -math.abs(pX-1)
			local zOffset = -math.abs((size.Z/part.Size.Z)+1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(0,0,part.Size.Z)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
	},
	[Enum.NormalId.Back] = {
		[Enum.NormalId.Left] = function(part) 
			local size = Vector3.new(2, 2, 1)
			local pX = (size.X/part.Size.X) - (size.X/part.Size.X)
			local xOffset = -math.abs(pX-1)
			local zOffset = math.abs((size.Z/part.Size.Z)+1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(0,0,-part.Size.Z)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
		[Enum.NormalId.Right] = function(part)
			local size = Vector3.new(2, 2, 1)
			local pX = (size.X/part.Size.X) - (size.X/part.Size.X)
			local xOffset = math.abs(pX-1)
			local zOffset = math.abs((size.Z/part.Size.Z)+1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(0,0,-part.Size.Z)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
	},
	[Enum.NormalId.Left] = {
		[Enum.NormalId.Front] = function(part)
			local size = Vector3.new(2, 2, 1)
			local xOffset = -math.abs((size.Z/part.Size.X)+1)
			local pZ = (size.Z/part.Size.Z) - (size.Z/part.Size.Z)
			local zOffset = -math.abs(pZ-1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(part.Size.Z,0,0)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
		[Enum.NormalId.Back] = function(part)
			local size = Vector3.new(2, 2, 1)
			local xOffset = -math.abs((size.Z/part.Size.X)+1)
			local pZ = (size.Z/part.Size.Z) - (size.Z/part.Size.Z)
			local zOffset = math.abs(pZ-1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(part.Size.Z,0,0)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
	},
	[Enum.NormalId.Right] = {
		[Enum.NormalId.Back] = function(part)
			local size = Vector3.new(2, 2, 1)
			local xOffset = math.abs((size.Z/part.Size.X)+1)
			local pZ = (size.Z/part.Size.Z) - (size.Z/part.Size.Z)
			local zOffset = math.abs(pZ-1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(-part.Size.Z,0,0)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
		[Enum.NormalId.Front] = function(part)
			local size = Vector3.new(2, 2, 1)
			local xOffset = math.abs((size.Z/part.Size.X)+1)
			local pZ = (size.Z/part.Size.Z) - (size.Z/part.Size.Z)
			local zOffset = -math.abs(pZ-1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(-part.Size.Z,0,0)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
	}
}

--[[
local faceEdges = {
	[Enum.NormalId.Front] = {
		[Enum.NormalId.Right] = function(part)
			local size = Vector3.new(2, 2, 1)
			local xOffset = math.abs((size.X/part.Size.X)-1)
			local zOffset = -math.abs((size.Z/part.Size.Z)+1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(0,0,part.Size.Z)

			return CFrame.new(cf.Position,lookAt.Position)	
		end,
		[Enum.NormalId.Left] = function(part)
			local size = Vector3.new(2, 2, 1)
			local xOffset = -math.abs((size.X/part.Size.X)-1)
			local zOffset = -math.abs((size.Z/part.Size.Z)+1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(0,0,part.Size.Z)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
	},
	[Enum.NormalId.Back] = {
		[Enum.NormalId.Left] = function(part) 
			local size = Vector3.new(2, 2, 1)
			local xOffset = -math.abs((size.X/part.Size.X)-1)
			local zOffset = math.abs((size.Z/part.Size.Z)+1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(0,0,-part.Size.Z)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
		[Enum.NormalId.Right] = function(part)
			local size = Vector3.new(2, 2, 1)
			local xOffset = math.abs((size.X/part.Size.X)-1)
			local zOffset = math.abs((size.Z/part.Size.Z)+1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(0,0,-part.Size.Z)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
	},
	[Enum.NormalId.Left] = {
		[Enum.NormalId.Front] = function(part)
			local size = Vector3.new(2, 2, 1)
			local xOffset = -math.abs((size.Z/part.Size.X)+1)
			local zOffset = -math.abs((size.X/part.Size.Z)-1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(part.Size.Z,0,0)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
		[Enum.NormalId.Back] = function(part)
			local size = Vector3.new(2, 2, 1)
			local xOffset = -math.abs((size.Z/part.Size.X)+1)
			local zOffset = math.abs((size.X/part.Size.Z)-1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(part.Size.Z,0,0)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
	},
	[Enum.NormalId.Right] = {
		[Enum.NormalId.Back] = function(part)
			local size = Vector3.new(2, 2, 1)
			local xOffset = math.abs((size.Z/part.Size.X)+1)
			local zOffset = math.abs((size.X/part.Size.Z)-1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(-part.Size.Z,0,0)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
		[Enum.NormalId.Front] = function(part)
			local size = Vector3.new(2, 2, 1)
			local xOffset = math.abs((size.Z/part.Size.X)+1)
			local zOffset = -math.abs((size.X/part.Size.Z)-1)

			local cf = part.CFrame * CFrame.new(Vector3.new(xOffset,0,zOffset) * part.Size/2)
			local lookAt = cf * CFrame.new(-part.Size.Z,0,0)

			return CFrame.new(cf.Position,lookAt.Position)
		end,
	}
}]]

-- this works like:
-- if you're on the front, and closest to the left face, and the ray detects you, if your X move vector isn't positive then dont change the face
-- if its positive then change the face
local faceMovement = {-- -1 = left, 1 = right
	[Enum.NormalId.Front] = { -- current face
		[Enum.NormalId.Left] = 1, -- closest face
		[Enum.NormalId.Right] = -1
	},
	[Enum.NormalId.Back] = {
		[Enum.NormalId.Left] = -1,
		[Enum.NormalId.Right] = 1
	},
	[Enum.NormalId.Right] = {
		[Enum.NormalId.Front] = 1,
		[Enum.NormalId.Back] = -1
	},
	[Enum.NormalId.Left] = {
		[Enum.NormalId.Front] = -1,
		[Enum.NormalId.Back] = 1
	}
}

local function least(a,b)
	return a[1] < b[1]
end

local function checkBounds(cframe,size,pos) -- cframe of the hitbox, size of hitbox, foreign position to check
	local relativePoint = cframe:Inverse() * pos
	local isInsideHitbox = true
	local axisTable = {
		[1] = "X",
		[2] = "Y",
		[3] = "Z"
	}
	for i = 1,#axisTable do
		local axis = axisTable[i]
		if math.abs(relativePoint[axis]) > size[axis]/2 then
			isInsideHitbox = false
			break
		end
	end
	return isInsideHitbox	
end

-- this function is intended to get the closest side to shoot ray from
local function getNearestFace(part,currentFace,pos) -- ignore the side you're on cause you want to be shooting the ray from that side that's closest
	local positions = {}
	local nearestSides = faces[currentFace]
	if not (nearestSides) then return end
	for i,v in (nearestSides) do
		local side_cf = part.CFrame * CFrame.new(v*(part.Size/2))
		local offset = (side_cf * CFrame.new(v/2)).Position
		positions[#positions+1] = {(offset - pos).Magnitude,i,offset} -- distance, face id, position
	end

	table.sort(positions,least)

	local registeredFace = nil

	-- now check if side is blocked by another bounds part
	local inRadius = part:FindFirstChild("inRadius")

	if inRadius then
		for index = 1,#positions do
			local foundBlocking = false
			for key,value in (inRadius:GetChildren()) do 
				--print(value.Name)
				--print(value.Value)
				if checkBounds(value.Value.CFrame,value.Value.Size,positions[index][3]) then -- is blocked by another part
					foundBlocking = true
				end
			end
			if not (foundBlocking) then
				registeredFace = positions[index]
				break
			end
		end
	end

	return registeredFace
end

local function getEdgeCFrame(part,nearestFace,currentFace) -- part you're on, nearest next face, hrp position
	-- this allows the ray to fire at a certain spot, 
	-- if you're closer to a side of the face, you can shoot in that direction and adjust height to your hrp Y pos
	local func = faceEdges[currentFace][nearestFace]
	if (func ~= nil) then 
		local cf = func(part)
		return cf
	end
	return nil
end

-- set these to nil when stop() is called
local startTick = nil
local endTick = nil
local timeSinceStart = nil
local oldFace = nil 
local oldRayHit = nil 
local frontRayHit = false
local oldX = 0
local xAngle = 0
local anim = nil
local surfaceCF = CFrame.new()
local center = Instance.new("Part")
center.CFrame = surfaceCF
local surfaceFaceID = nil

local climbMove	= Instance.new("BodyVelocity")
climbMove.MaxForce = Vector3.new(1,1,1)*math.huge
climbMove.P = math.huge
climbMove.Velocity = Vector3.new()

local climbGyro	= Instance.new("BodyGyro")
climbGyro.CFrame = CFrame.new()
climbGyro.D	= 500
climbGyro.MaxTorque	= Vector3.new(1,1,1)*math.huge
climbGyro.P	= 5000

--local climbPos	= Instance.new("BodyPosition")
--climbPos.Position = Vector3.new()
--climbPos.D	= 100
--climbPos.MaxForce	= Vector3.new(1,1,1)*1000000
--climbPos.P	= 1000

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

local ragdoll = require(rs:WaitForChild("ragdoll"))

local function Get_Climb_Idle(humanoid)
	for _,track in humanoid:GetPlayingAnimationTracks() do 
		if track.Name=="Climb_Idle" then
			return track
		end
	end
end

local function start(hrp,humanoid,bool,s)
	if (isClimbing.Value) and (bool == nil) then return end -- if already started, don't run again
	--print("start climb",s)
	dataRemote:FireServer("changeClimb",true)
	isClimbing.Value = true
	ghostPlayer()
	player.CameraMaxZoomDistance = 20
	player.CameraMinZoomDistance = 7
	local gyroFound = hrp:FindFirstChildOfClass("BodyGyro")
	if (gyroFound) then
		--print("gyro found")
		climbGyro = gyroFound
		climbGyro.CFrame = CFrame.new()
		climbGyro.D	= 500
		climbGyro.MaxTorque	= Vector3.new(1,1,1)*math.huge
		climbGyro.P	= 5000
	else
		if (climbGyro.Parent ~= nil) then
			climbGyro.Parent = hrp
		else
			climbGyro = Instance.new("BodyGyro")
			climbGyro.CFrame = CFrame.new()
			climbGyro.D	= 500
			climbGyro.MaxTorque	= Vector3.new(1,1,1)*math.huge
			climbGyro.P	= 5000
			climbGyro.Parent = hrp
		end
	end

	local velocityFound = hrp:FindFirstChildOfClass("BodyVelocity")
	if (velocityFound) then
		climbMove = velocityFound
		climbMove.MaxForce = Vector3.new(1,1,1)*math.huge
		climbMove.P = math.huge
		climbMove.Velocity = Vector3.new()
	else
		if (climbMove.Parent ~= nil) then
			climbMove.Parent = hrp
		else
			climbMove = Instance.new("BodyVelocity")
			climbMove.MaxForce = Vector3.new(1,1,1)*math.huge
			climbMove.P = math.huge
			climbMove.Velocity = Vector3.new()
			climbMove.Parent = hrp
		end
	end

	humanoid.AutoRotate=false
	humanoid.PlatformStand=true
	ragdoll.setStatesEnabled(humanoid,false,Enum.HumanoidStateType.Physics)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	for _,track in (humanoid:GetPlayingAnimationTracks()) do
		if (track.Animation:IsDescendantOf(animsFolder)) then
			track:Stop()
		end
	end
	
	local animationsLoaded = humanoid.Parent:WaitForChild("AnimationsLoaded")
	if not animationsLoaded.Value then
		repeat task.wait(1/30) until animationsLoaded.Value
	end
	
	local movement = animsFolder:WaitForChild("movement")
	anim = humanoid:LoadAnimation(movement:WaitForChild("Crawl"))
	anim:Play()
	
	startTick=tick()
	--hotbarUI.Enabled = false
	-- send message to server about it; wait why? maybe for ragdoll or something, cause it changes the value
	-- give bodymovers 
	-- change to physics
end

_G.start_climb=function(part,hrp,humanoid)
	oldRayHit=part
	start(hrp,humanoid)
end

local blur = game:GetService("Lighting"):WaitForChild("Blur")
local isWebbing = temp:WaitForChild("isWebbing")

local function stop(humanoid)
	if (isClimbing.Value == false) then return end
	--print("stop climb")
	dataRemote:FireServer("changeClimb",false)
	isClimbing.Value = false
	if not cs:HasTag(character,"ragdolled")  and humanoid.Health>0 then
		-- if you are already ragdolled and die, your limbs will collide with default
		--print("climb disabled ghost")
		undoGhost()	
	end
	player.CameraMaxZoomDistance = 20
	player.CameraMinZoomDistance = .5
	if blur.Enabled or abilitySelected.Value == 0 then
		climbGyro.Parent = nil
		humanoid.AutoRotate = true
	end
	if cs:HasTag(humanoid.Parent,"ragdolled") then
		--print("CLIMB: disabled torque")
		climbGyro.P = 0
		climbGyro.D = 0
		climbGyro.MaxTorque = Vector3.new()
		--climbMove.MaxForce = Vector3.new()
		--climbMove.P = 0
		--climbMove.Velocity = Vector3.new()
	end
	humanoid.PlatformStand=false
	if (humanoid.Health > 0) and not cs:HasTag(humanoid.Parent,"ragdolled") then
		--print("CLIMB: enabled states")
		ragdoll.setStatesEnabled(humanoid,true)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		local animate=character:FindFirstChild("Animate")
		local jump=animate and animate:FindFirstChild("jump")
		local jumpAnim=jump and jump:FindFirstChildOfClass("Animation")
		if jumpAnim then
			local clone=jumpAnim:Clone()
			clone.Name="SecondJump"
			clone.Parent=animsFolder
			local newJump=humanoid:LoadAnimation(clone)
			newJump:Play()
		end
	end
	climbMove.Parent = nil
	endTick = tick()
	oldFace = nil 
	oldRayHit = nil 
	frontRayHit = false
	oldX = 0
	xAngle = 0
	local idle=Get_Climb_Idle(humanoid)
	if idle then
		idle:Stop()
	end
	if anim then
		anim:AdjustSpeed(0)
		anim:Stop()
		anim = nil		
	end
	surfaceCF = CFrame.new()
	surfaceFaceID = nil
	
	--hotbarUI.Enabled = true
	-- destroy gyro
	-- add force backwards and upwards, then destroy velocity
	-- play backflip animation
	-- don't allow climbing again until threshold is over
end

local function returnTheta(startPos,endPos,axis)
	local adjascent = (startPos[axis] - endPos[axis]) -- greater number always first
	local hypotenuse = (startPos-endPos).magnitude
	return math.deg(math.acos(adjascent/hypotenuse))
end

local function clampMagnitude(v, max)
	if (v.magnitude == 0) then return Vector3.new(0,0,0) end -- prevents NAN,NAN,NAN
	return v.Unit * math.min(v.Magnitude, max)
end

local function getXRotation(vector)
	if (vector.Magnitude == 0) then return xAngle end -- prevents nan
	local x = vector.X
	local z = vector.Z 
	local theta = returnTheta(Vector2.new(0,0),Vector2.new(x,z),"Y")
	theta = x > 0 and -theta or theta
	return theta
end

--[[
local debounce = false
local lerping = false
local function lerpCF(hrp)
	--if (debounce) then return end
	--debounce = true
	local t = math.ceil(.25/(1/60)) -- 60fps
	for i = 1,t do
		if not (isClimbing.Value) then break end
		lerping = true
		local goal = surfaceCF * CFrame.Angles(0,0,math.rad(xAngle))
		climbGyro.CFrame = hrp.CFrame:Lerp(goal,i/t)
		--climbPos.Position = hrp.CFrame:Lerp(goal,i/t).Position
		local direction = (hrp.Position - surfaceCF.Position).Unit
		local excludeY = Vector3.new(1,0,1)
		local speed = ((hrp.Position*excludeY) - (surfaceCF.Position*excludeY)).Magnitude - hrp.Size.Z/2

		--climbMove.Velocity = climbMove.Velocity + (climbGyro.CFrame.LookVector * 3)
		--hrp.CFrame = hrp.CFrame:Lerp(goal,i/t)
		game:GetService("RunService").Stepped:Wait()
	end
	lerping = false
	--debounce = false
end]]

local function searchForSides(hrp)
	local nearestFaceInfo = getNearestFace(oldRayHit,oldFace,hrp.Position) -- distanceFromNearestFace, nearestFace, nearestFacePosition
	if not (nearestFaceInfo) then return end
	local nearestFaceID = nearestFaceInfo[2]
	local nearestFacePosition = nearestFaceInfo[3]

	local distance = (hrp.Position - nearestFacePosition).Magnitude
	local yDifference = hrp.Position.Y - nearestFacePosition.Y
	local length = distance * 1.5
	
	local sideRay = castRay({hrp,oldRayHit},nearestFacePosition,hrp.Position,length)
	if (sideRay) and (sideRay.Instance == hrp) then

		-- check if its still able to be hit by 

		local moveVector = movement.GetMoveVector(movement)
		if (moveVector.X ~= 0) then 
			local x = moveVector.X > 0 and 1 or -1
			if (x ~= oldX) then
				oldX = x
			end
		else
			--return
			--[[
			if (oldX == 0) and frontRayHit then -- you have to choose a side or it'll spazz out
				--print("had to choose a side")
				local x = moveVector.X >= 0 and 1 or -1
				oldX = x
			end
			]]
		end
		
		local listing = faceMovement[oldFace][nearestFaceID]
		if (listing == oldX) then
			oldFace = nearestFaceID

			nearestFaceInfo = getNearestFace(oldRayHit,oldFace,hrp.Position) -- distanceFromNearestFace, nearestFace, nearestFacePosition
			if not (nearestFaceInfo) then return end
			nearestFaceID = nearestFaceInfo[2]
			nearestFacePosition = nearestFaceInfo[3]

			local edgeCF = getEdgeCFrame(oldRayHit,nearestFaceID,oldFace)
			if (edgeCF) then
				surfaceCF = edgeCF + Vector3.new(0,yDifference,0)
				center.CFrame = surfaceCF
			end
		end
	end
end

local function closestPointOnPart(part, point)
	local Transform = part.CFrame:pointToObjectSpace(point) -- Transform into local space
	local HalfSize = part.Size * 0.5
	return part.CFrame * Vector3.new( -- Clamp & transform into world space
		math.clamp(Transform.x, -HalfSize.x, HalfSize.x),
		math.clamp(Transform.y, -HalfSize.y, HalfSize.y),
		math.clamp(Transform.z, -HalfSize.z, HalfSize.z)
	)
end

local function invertNumber(n)
	if (n > 0) then 
		return -n 
	elseif (n < 0) then 
		return math.abs(n)
	end
	return 0
end

local function visualizeHitBox(cframe,size,bool)
	local part = workspace:WaitForChild("placement"):Clone()
	part.CFrame = cframe
	part.Size = size
	part.BrickColor = bool and BrickColor.Red() or BrickColor.Green()
	part.Parent = workspace
	game:GetService("Debris"):AddItem(part,.03)
end

local function getCharacterModelsArray()
	local t = {}
	for _,plr in (game.Players:GetPlayers()) do 
		t[#t+1] = plr.Character
	end
	return t
end

local function getPartsInBoundingBoxForAttackables(cframe,size)
	local array = getCharacterModelsArray()
	local whitelist = {
		workspace:WaitForChild("SpiderDrones"),
		workspace:WaitForChild("Thugs"),
		workspace:WaitForChild("Villains")
	}
	for _,value in (whitelist) do 
		array[#array+1] = value
	end
	local overlapParams = OverlapParams.new()
	overlapParams.MaxParts = 25
	--overlapParams.CollisionGroup = "Characters"
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = array
	overlapParams.BruteForceAllSlow = false

	local partsInBox = workspace:GetPartBoundsInBox(
		cframe,
		size,
		overlapParams
	)

	return partsInBox
end

while true do 
	character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")
	local gettingUp = character:GetAttribute("GettingUp")
	local teleporting = character:GetAttribute("Teleporting")
	
	local canClimb = not gettingUp 
		and not teleporting
		and not cs:HasTag(character,"ragdolled") 
		and (humanoid.Health > 0) 
		and not cs:HasTag(character,"Died")
	if canClimb == false then
		stop(humanoid)
	elseif canClimb == true then
		local bodyGyro = hrp:FindFirstChildOfClass("BodyGyro")
		local bodyVelocity = hrp:FindFirstChildOfClass("BodyVelocity")
		if (isClimbing.Value) then
			if not (bodyGyro) or not (bodyVelocity) then
				start(hrp,humanoid,true,"first")
			end
			climbMove.MaxForce = Vector3.new(1,1,1)*math.huge
			climbMove.P = math.huge
			climbGyro.D	= 500
			climbGyro.MaxTorque	= Vector3.new(1,1,1)*math.huge
			climbGyro.P	= 5000
		end
		if (endTick ~= nil) then
			if (tick() - endTick > climbDebounce) then -- you can start looking for walls to climb
				endTick = nil
			end
		end
		if startTick~=nil then
			if (tick()-startTick)>=climbDebounce then -- you can stop the climb if needed
				startTick=nil
			end
		end
		if endTick==nil then -- proceed climb
			local frontRay = castRay({BuildingBounds},hrp.Position,(hrp.CFrame * CFrame.new(0,0,-3)).Position,3)
			local moveVector3 = movement.GetMoveVector(movement)
			local topRay = castRay({BuildingBounds},hrp.Position,(hrp.CFrame * CFrame.new(moveVector3.X * invertNumber(moveVector3.Z),1,0)).Position,5)
			if frontRay and (_G.jumping or isClimbing.Value) then -- you just discovered a new part infront of you
				frontRayHit = true
				if (frontRay.Instance ~= oldRayHit) then
					oldRayHit = frontRay.Instance
					start(hrp,humanoid,nil,"second")
					local face = getFaceFromNormal(frontRay.Normal,frontRay.Instance)
					if (face == Enum.NormalId.Top) then 
						stop(humanoid)
					elseif (face ~= Enum.NormalId.Top) and (face ~= Enum.NormalId.Bottom) then  
						oldFace = face
						surfaceFaceID = oldFace
						surfaceCF = CFrame.new(frontRay.Position + frontRay.Normal/2, frontRay.Position - frontRay.Normal)
						center.CFrame = surfaceCF
					end
				else
					local face = getFaceFromNormal(frontRay.Normal,frontRay.Instance)
					if (face == Enum.NormalId.Top) then 
						stop(humanoid)
					elseif (face ~= Enum.NormalId.Top) and (face ~= Enum.NormalId.Bottom) then 
						oldFace = face
						surfaceFaceID = oldFace
						surfaceCF = CFrame.new(frontRay.Position + frontRay.Normal/2, frontRay.Position - frontRay.Normal)
						center.CFrame = surfaceCF
					end
				end
			else
				frontRayHit = false
				if (isClimbing.Value) and (oldRayHit ~= nil) then
					local closestPoint = closestPointOnPart(oldRayHit,hrp.Position)
					local excludeY = Vector3.new(1,0,1)
					if ((closestPoint) - (hrp.Position)).Magnitude > 5 then
						stop(humanoid)
					end
				end
			end
			if topRay and (_G.jumping or isClimbing.Value) then  -- you just discovered a new part above your head
				if (topRay.Instance ~= oldRayHit) then
					local face = getFaceFromNormal(topRay.Normal,topRay.Instance)
					--print("top hit ",face)
					if (face == Enum.NormalId.Top) then 
						stop(humanoid)
					elseif (face ~= Enum.NormalId.Top) and (face ~= Enum.NormalId.Bottom) then 
						oldRayHit = topRay.Instance
						start(hrp,humanoid,nil,"third")
						oldFace = face
						surfaceFaceID = oldFace
						surfaceCF = CFrame.new(topRay.Position + topRay.Normal/2, topRay.Position - topRay.Normal)
						center.CFrame = surfaceCF
					end
				end	
			end
			if (isClimbing.Value) and (oldRayHit ~= nil) then
				searchForSides(hrp)

				local closestPoint = closestPointOnPart(oldRayHit,hrp.Position)

				local moveVector = movement.GetMoveVector(movement)
				xAngle = getXRotation(moveVector)

				if (surfaceCF ~= nil) then 
					local goal = surfaceCF * CFrame.Angles(0,0,math.rad(xAngle))
					climbGyro.CFrame = goal
				end

				local x = moveVector.X
				local upVector = hrp.CFrame.UpVector
				local speed = _G.sprinting and 32 or 16
				local moveForce = (center.CFrame.RightVector * (moveVector.X * speed) + Vector3.new(0, moveVector.Z*-speed, 0))
				local surfaceForce = Vector3.new()
				if (surfaceCF ~= nil) then
					local excludeY = Vector3.new(1,0,1)
					local excludedYSurfacePos = (closestPoint * excludeY)
					local excludedYHrpPos = (hrp.Position * excludeY)
					local surfacePos = closestPoint
					local hrpPos = hrp.Position
					local speed = ((excludedYHrpPos - excludedYSurfacePos).Magnitude - .5) * 5
					surfaceForce = (surfacePos - hrpPos).Unit * speed
				end

				local vel = moveForce + surfaceForce
				climbMove.Velocity = clampMagnitude(vel, speed)
				
				anim:AdjustSpeed(climbMove.Velocity.Magnitude/16)

				local partHeight = oldRayHit.Position.Y + (oldRayHit.Size.Y/2)
				if (hrp.Position.Y - (hrp.Size.Y/2)) > partHeight then 
					stop(humanoid)
				end
			end
		end
		if _G.jumping then 
			if isClimbing.Value and startTick==nil then
				stop(humanoid)	
			end
		end
	end
	runService.Heartbeat:Wait()
end

--[[

local folder = Instance.new("Folder")
folder.Name = "AnimSaves"
folder.Parent = game:GetService("ReplicatedStorage")

local i = 0
while true do 
	i += 1 
	if (i==100) then break end
	task.wait(1/30)
	local player = game.Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()

	local humanoid = character:WaitForChild("Humanoid")
	local playingtracks= humanoid:GetPlayingAnimationTracks()

	for index,anim in (playingtracks) do 
		local id = tostring(anim.Animation.AnimationId)
		local anims = folder:GetChildren()
		local match = false
		for i,v in (anims) do 
			if v.Value == id then
				match = true
			end
		end
		if not (match) then 
			local animation = Instance.new("StringValue")
			animation.Name = tostring(anim.Animation)
			animation.Value = tostring(anim.Animation.AnimationId)
			animation.Parent = folder
		end
	end
end

]]