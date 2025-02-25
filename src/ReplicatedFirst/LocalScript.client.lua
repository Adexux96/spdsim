local function createFutureIndex(array,currentIndex)
	if array[currentIndex+1] ~= nil then return end -- there's already a future index
	local current_node = array[currentIndex]
	local next_node = nil
	local next_folder = current_node:FindFirstChild("next")
	if next_folder then
		next_node = next_folder:FindFirstChildWhichIsA("ObjectValue").Value
	else 
		local ends_folder = current_node:FindFirstChild("ends")
		local end_folder_children = ends_folder:GetChildren()
		local end_node_listing = end_folder_children[math.random(1,#end_folder_children)]
		local end_node = current_node.Parent:FindFirstChild(end_node_listing.Name)
		next_node = end_node 
	end
	return next_node
end

local function createPreviousIndex(array,currentIndex) 
	if array[currentIndex-1] ~= nil then return end -- there's already a previous index
	local current_node = array[currentIndex]
	local previous_folder = current_node:FindFirstChild("previous")
	local previous_node = previous_folder:FindFirstChildWhichIsA("ObjectValue").Value
	return previous_node
end

local function Get_Random_Start_Node(array)
	local startNodes = {}
	for _, board in (array) do
		if board.Name:match("Intersection") then
			for _,child in (board:GetChildren()) do 
				if child.Name:match("start") and not child.Name:match("Turn") then
					startNodes[#startNodes+1] = child
				end
			end
		end
	end
	return startNodes[math.random(1,#startNodes)]
end

local traffic_control = workspace.TrafficControl

local function createPathData()

	local new = Get_Random_Start_Node(traffic_control:GetChildren())

	local path = {}

	path[2] = new -- the start point
	path[1] = createPreviousIndex(path,2) -- the previous
	for i = 1,3 do -- create the next 3 indices
		path[#path+1] = createFutureIndex(path,#path)
	end

	return path
end

local path = createPathData()
for index,value in (path) do
	print(index,"=",value, value.Parent)
end