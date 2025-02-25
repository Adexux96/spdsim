

local function inverseNormal(normal)
	local x,y,z = 0,0,0

	x = normal.X > 0 and -normal.X or math.abs(normal.X)
	y = normal.Y > 0 and -normal.Y or math.abs(normal.Y)
	z = normal.Z > 0 and -normal.Z or math.abs(normal.Z)

	return Vector3.new(x,y,z)
end

local function getNormalCFrame(pos,normal)
	local surfaceCFrame = CFrame.new(pos,pos+normal)
	return surfaceCFrame
end

local cf = getNormalCFrame(workspace.Offset.Position,workspace.camPart.CFrame.RightVector)
workspace.Offset.CFrame = cf