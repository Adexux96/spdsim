
local webnew = workspace.webnew

local primary = webnew.PrimaryPart

local bones = {
	[1] = primary.Bone1,
	[2] = primary.Bone2,
	[3] = primary.Bone3,
	[4] = primary.Bone4,
	[5] = primary["Bone.5"],
	[6] = primary.Bone6,
	[7] = primary.Bone7
}

local function extendBones(size)
	primary.Size = size
	local startCF = primary.CFrame * CFrame.new(0,-size.Y*.75,-size.Z/2)
	local endCF = primary.CFrame * CFrame.new(0,-size.Y*.75,size.Z/2)

	for i = 1,#bones do 
		local p = (i-1)/(#bones-1)
		local startPos = startCF.Position:Lerp(endCF.Position,p)
		
	end

	workspace.Offset.CFrame = startCF
	workspace.Center.CFrame = endCF

end

extendBones(Vector3.new(0.6,0.6,25))

for i = 1,20 do 
	workspace.Center.CFrame = (workspace.camPart.CFrame * CFrame.Angles(0,0,i)) * CFrame.new(-1,1,-2)
	task.wait(1/30)
end
