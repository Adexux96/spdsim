
--[[
for _,v in (game:GetService("StarterGui"):GetDescendants()) do
	if (v:IsA("ImageLabel")) then
		if (v.Image == "rbxassetid://8420011919") then
			v.Image = "rbxassetid://8420239485"
		end
	end
end]]

--[[
local offset = Vector3.new(3,2,6)

local rotation = CFrame.Angles(math.rad(-90),0,0)
local center = workspace:WaitForChild("Center")
local camCFrame = center.CFrame * CFrame.new(offset) * rotation

local offsetPart = workspace:WaitForChild("Offset")
offsetPart.CFrame = camCFrame

local function getCameraToPlayerRotation(cam,torso)
	local A = Vector3.new(cam.X,0,cam.Z)
	local B = Vector3.new(torso.X,0,torso.Z)

	local back = A - B
	local right = Vector3.new(0, 1, 0):Cross(back)
	local up = back:Cross(right)

	local x,y,z = CFrame.fromMatrix(A, right, up, back):ToOrientation()
	return Vector3.new(x,math.deg(y),x)
end]]

-- makes it so the RightVector and UpVector run parellel to the surface and LookVector = surface normal

local function checkObstructions(ignore,origin,target)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = ignore
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	local raycastResult = workspace:Raycast(
		origin,
		(target - origin).Unit * 50,
		raycastParams
	)
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
		game:GetService("Debris"):AddItem(p,2)
	end
	return raycastResult
end

-- Untested!

--[[**
   This function returns the face that we hit on the given part based on
   an input normal. If the normal vector is not within a certain tolerance of
   any face normal on the part, we return nil.

    @param normalVector (Vector3) The normal vector we are comparing to the normals of the faces of the given part.
    @param part (BasePart) The part in question.

    @return (Enum.NormalId) The face we hit.
**--]]
function NormalToFace(normalVector, part)

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
		if GetNormalFromFace(part, normalId):Dot(normalVector) > TOLERANCE_VALUE then
			return normalId -- We found it!
		end
	end

	return nil -- None found within tolerance.

end

--[[**
    This function returns a vector representing the normal for the given
    face of the given part.

    @param part (BasePart) The part for which to find the normal of the given face.
    @param normalId (Enum.NormalId) The face to find the normal of.

    @returns (Vector3) The normal for the given face.
**--]]

function GetNormalFromFace(part, normalId)
	return part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(normalId))
end

local function inverseNormal(normal)
	local x,y,z = 0,0,0
	x = normal.X > 0 and -normal.X or math.abs(normal.X)
	y = normal.Y > 0 and -normal.Y or math.abs(normal.Y)
	z = normal.Z > 0 and -normal.Z or math.abs(normal.Z)
	return Vector3.new(x,y,z)
end

local result = checkObstructions({workspace.BuildingBounds},workspace.pos.Position,(workspace.pos.CFrame * CFrame.new(0,0,-1)).Position)
if (result) then 
	local pos, normal = result.Position,result.Normal
	local face = NormalToFace(normal,result.Instance)
	print(face)
	print(normal)
	local invertedNormal = inverseNormal(normal)
	local surfaceCFrame = CFrame.new(pos,pos+invertedNormal)
	workspace.pos.CFrame = surfaceCFrame * CFrame.new(0,0,1)
end

local air_fx = game:GetService("ReplicatedStorage"):WaitForChild("Particles"):WaitForChild("FX_AirOutlet")
local vents = workspace.Vents

for _,ventGroup in (vents:GetChildren()) do 
	local vents = ventGroup:GetChildren()
	local numVents=  #vents
	
	for index,vent in (vents) do 
		local air_fx = vent:FindFirstChild("Air_FX")
		if air_fx then
			air_fx:WaitForChild("PRT_Smoke").Rate = 15
		end
	end
end

local sandFolder = Instance.new("Folder")
sandFolder.Name = "Sand"
sandFolder.Parent = workspace

for _,water in (workspace.water:GetChildren()) do 
	local sandClone = workspace.Sand:clone()
	sandClone.CFrame = water.CFrame
	sandClone.Position -= Vector3.new(0,8,0)
	sandClone.Size = water.Size
	sandClone.Parent = sandFolder
end

local impactWeb = workspace.ImpactWeb
local startCF = CFrame.new(Vector3.new(720.419, 8.594, -172.428))
local distance = 100
local speed = 75
local target = startCF * CFrame.new(Vector3.new(0,0,-distance))
local _math = require(game:GetService("ReplicatedStorage"):WaitForChild("math"))
local totalReps = _math.nearest((distance/speed)/(1/60))
local rs = game:GetService("RunService")

local currentCF = startCF
for i = 1,totalReps do
	local p = i/totalReps
	local distanceToTarget = ((totalReps - (i-1))/totalReps) * distance

	local lookAtCF = CFrame.new(currentCF.Position,((currentCF * CFrame.new(Vector3.new(0,0,-1))).Position) + Vector3.new(0,-i/100,0)) * CFrame.Angles(0,0,math.rad(-speed/20) * ((i-1)*3) )
	impactWeb.CFrame = startCF:Lerp(lookAtCF * CFrame.new(Vector3.new(0,0,-distanceToTarget)),p)
	currentCF = CFrame.new(impactWeb.Position,(impactWeb.CFrame * CFrame.new((startCF.Position - target.Position).Unit)))
	rs.RenderStepped:Wait()
end

local excludeY = Vector3.new(1,0,1)
print((impactWeb.Position - startCF.Position).Magnitude)

local function returnTheta(startPos,endPos,axis)
	local adjascent = (startPos[axis] - endPos[axis]) -- greater number always first
	local hypotenuse = (startPos-endPos).magnitude
	return math.deg(math.acos(adjascent/hypotenuse))
end

local buildingBounds = workspace:WaitForChild("BuildingBounds")

for k1,v1 in (buildingBounds:GetChildren()) do 
	
	local oldFolder = v1:FindFirstChild("inRadius")
	for i,v in v1:GetChildren() do 
		if v:IsA("PathfindingModifier") then
			v:Destroy()
		end
		if v:IsA("Folder") then
			v:Destroy()
		end
	end
	if oldFolder then oldFolder:Destroy() end
	
	if v1:IsA("Model") then continue end
	if v1.Name=="Road" then continue end
	--if true then continue end
	local inRadius = {}
	for k2, v2 in (buildingBounds:GetChildren()) do
		if v2:IsA("Model") then continue end
		if v2.Name=="Road" then continue end
		if (v2 ~= v1) then -- ignore the part you're guaging from obviously
			if ((v2.Position - v1.Position).Magnitude <=250) then
				inRadius[#inRadius+1] = v2
			end			
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "inRadius"
	folder.Parent = v1 
	for key,value in (inRadius) do 
		local newListing = Instance.new("ObjectValue")
		newListing.Name = key 
		newListing.Value = value
		newListing.Parent = folder
	end
	task.wait(1/30)
end

local placement = workspace.placementB
local venom = workspace.Venom
local venomRoot = venom.PrimaryPart
local venomMeshRoot = venom.VenomMesh.PrimaryPart

local size = Vector3.new(venomMeshRoot.Size.X/2,venomMeshRoot.Size.Y/2,15)
local cframe = venomRoot.CFrame * CFrame.new(0,0,-size.Z/2)

placement.Size = size
placement.CFrame = cframe

local function closestPointOnPart(part, point)
	local Transform = part.CFrame:pointToObjectSpace(point) -- Transform into local space
	local HalfSize = part.Size * 0.5
	return part.CFrame * Vector3.new( -- Clamp & transform into world space
		math.clamp(Transform.x, -HalfSize.x, HalfSize.x),
		math.clamp(Transform.y, -HalfSize.y, HalfSize.y),
		math.clamp(Transform.z, -HalfSize.z, HalfSize.z)
	)
end

part = workspace.Box
point = workspace.placementB.Position

part.Attachment.WorldPosition = closestPointOnPart(part,point)

