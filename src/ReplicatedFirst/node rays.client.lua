local nodes = workspace.nodes2

local function ray(origin,direction,whitelist)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {whitelist}
	params.FilterType = Enum.RaycastFilterType.Whitelist
	local ray = workspace:Raycast(origin,direction,params)
	return ray
end

local function visualizeRay(origin,goal)
	local rayVisual = game.ReplicatedStorage:WaitForChild("rayVisual"):Clone()
	rayVisual.CFrame = CFrame.new(origin:Lerp(goal,.5),goal)
	rayVisual.Size = Vector3.new(0.25,0.25,(origin - goal).Magnitude)
	rayVisual.Transparency = 0.75
	rayVisual.BrickColor = BrickColor.Green()
	rayVisual.Material = Enum.Material.Neon
	rayVisual.Parent = workspace.detectRay
	--game:GetService("Debris"):AddItem(rayVisual,1)
end

-- make sure parts are collidable

for _,nodeA in (nodes:GetChildren()) do
	if nodeA.Name=="spawn" then continue end
	if nodeA.Name=="bounds" then continue end
	local neighbors = nodeA:FindFirstChild("neighbors")
	if not neighbors then
		neighbors = Instance.new("Folder")
		neighbors.Name = "neighbors"
		neighbors.Parent = nodeA
	end
	for _,nodeB in (nodes:GetChildren()) do
		if nodeB.Name==nodeA.Name then continue end
		if nodeB.Name=="bounds" then continue end
		--print(nodeA.Name,nodeB.Name)
		local origin = nodeA.Position
		local goal = nodeB.Position
		local length = (origin-goal).Magnitude
		local direction = (goal-origin).Unit * length
		--visualizeRay(origin,goal)
		local result = ray(origin,direction,nodes)
		if result and result.Instance.Name == nodeB.Name then -- found nodeB
			local listing = Instance.new("StringValue")
			listing.Name = nodeB.Name
			listing.Value = (nodeA.Position-nodeB.Position).Magnitude
			listing.Parent = neighbors
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = nodeA 
			weld.Part1 = nodeB 
			weld.Parent = nodeA
			
		end
	end
	task.wait()
end

local function removeWelds(nodes)
	for i,v in nodes:GetChildren() do 
		for i2,v2 in v:GetChildren() do 
			if v2:IsA("WeldConstraint") then v2:Destroy() end
		end
	end
end
removeWelds(workspace.nodes2)

local function nameNodes(nodes)
	local name=0
	local children=nodes:GetChildren()
	for i=1,#children do 
		if children[i].Name=="node" then
			name+=1
			children[i].Name=name
		end
	end
end
local nodes=workspace.nodes2
nameNodes(nodes)

local function rigNodes(nodeA,nodeB)
	local nodes={nodeA,nodeB}
	for i1,node1 in (nodes) do 
		local neighbors = node1:FindFirstChild("neighbors")
		if not neighbors then
			neighbors = Instance.new("Folder")
			neighbors.Name = "neighbors"
			neighbors.Parent = node1
		end
		for i2,node2 in (nodes) do 
			if node2==node1 then continue end
			local listing = Instance.new("StringValue")
			listing.Name = node2.Name
			listing.Value = (node1.Position-node2.Position).Magnitude
			listing.Parent = neighbors

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = node1 
			weld.Part1 = node2 
			weld.Parent = node1
		end
	end
end

local nodes=workspace.nodes2
for i,v in ({nodes["97"],nodes["98"],nodes["95"],nodes["96"]}) do 
	rigNodes(nodes["spawn"],v)
end
