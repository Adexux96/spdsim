
local civilian_model = workspace.Civilians
local civilian_control = workspace.CivilianControl
local civilians = {}

local rs = game:GetService("ReplicatedStorage")
local physicsService = game:GetService("PhysicsService")
local civilian = rs.Civilian

local civiliansPerBlock = 2

local genders = {
	[1] = {75,"Male"}, 
	[2] = {25,"Female"} 
}

local colors = {
	[1] = {25,"Black"}, 
	[2] = {75,"White"} 
}

local outfits = {
	[1] = {10,"Pizza"},
	[2] = {30,"Business"}, 
	[3] = {60,"Casual"} 
}

local phone = {
	[1] = {3,"Pizza","Phone"},
	[2] = {10,"Business","Phone"},
	[3] = {50,"Casual","Phone"}
}

local suitcase = {
	[1] = {1,"Pizza","Suitcase"},
	[2] = {50,"Business","Suitcase"},
	[3] = {5,"Casual","Suitcase"}
}

local pizza = {
	[1] = {50,"Pizza","Pizza"},
	[2] = {1,"Business","Pizza"},
	[3] = {10,"Casual","Pizza"}
}

local tools = {
	[1] = pizza,
	[2] = suitcase,
	[3] = phone
}

local function least(a,b,n)
	return a[1] < b[1]
end

local function greatest(a,b,n)
	return a[1] > b[1]
end

local _math = require(game:GetService("ReplicatedStorage").math)

local function random1orN(n)
	return (math.round(_math.defined(1,100))%n)+1
end

local function Get_Random(array)
	local n = _math.defined(0,100)
	table.sort(array,least)
	local total = 0
	for index,value in pairs(array) do
		local percent=value[1]+total
		total=percent
		if n <= percent then
			return value[2],value[3]
		end
	end
	return false
end

local function Vector3Clamp(n,a,b)
	local x = a.X > b.X and 
		math.clamp(n.X,b.X,a.X) or 
		math.clamp(n.X,a.X,b.X)
	local y = b.Y
	local z = a.Z > b.Z and 
		math.clamp(n.Z,b.Z,a.Z) or 
		math.clamp(n.Z,a.Z,b.Z)
	return Vector3.new(x,y,z)
end

local function lerp(start,goal,alpha)
	return ((goal-start) * alpha) + start
end

local function Find_Block()
	for _,node_model in pairs(civilian_control:GetChildren()) do
		local civilians = civilian_model:FindFirstChild(node_model.Name)
		if #civilians:GetChildren() < civiliansPerBlock then
			return civilians,node_model,(#civilians:GetChildren())+1 -- parent,block,name
		end
	end
	return nil
end

local algorithm = require(script.Parent["Astar"])

local function New_Path(block,start)
	local nodes = block:GetChildren()
	local index
	if not start then
		index = math.random(1,#nodes)
	else
		for i,node in pairs(nodes) do 
			if start == node then
				index=i
				break
			else
				continue
			end
		end
	end
	start = nodes[index]
	table.remove(nodes,index) -- remove so goal & start can't be same
	local goal = nodes[math.random(1,#nodes)]
	local path = algorithm:GeneratePath(start,goal,block,{})
	return path
end

local function Get_Nearby_Civilians(array) -- array = the array of the civilian calling this
	
	local start = array.body.start.Value
	local start_listings = start:FindFirstChild("listings"):GetChildren()
	local goal = array.body.goal.Value
	local goal_listings = goal:FindFirstChild("listings"):GetChildren()
	
	local listings = {start_listings,goal_listings}
	
	local opposite_ahead={}
	local opposite_behind={}
	local same_ahead={}
	local same_behind={}
	
	local ignore={} -- for repeat prevention
	
	for _,listingArray in pairs(listings) do 
		for i,listing in pairs(listingArray) do
			if listing.Name == array.body.Name then continue end
			if ignore[listing.Name] then continue end
			ignore[listing.Name] = true
			local same_goal = listing.Value.goal.Value == goal
			local same_start = listing.Value.start.Value == start
			local different_goal = listing.Value.goal.Value ~= goal
			local different_start = listing.Value.start.Value ~= start
			local start_is_goal = listing.Value.start.Value == goal
			local goal_is_start = listing.Value.goal.Value == start
			
			local opposite_same_lane = goal_is_start and start_is_goal
			local opposite_other_lane_ahead = same_goal and different_start
			local opposite_other_lane_behind = same_start and different_goal
			
			local opposite = opposite_same_lane or opposite_other_lane_ahead or opposite_other_lane_behind
			
			local same_lane = same_goal and same_start
			local same_other_lane_behind = goal_is_start and start_is_goal == false
			local same_other_lane_ahead = start_is_goal and goal_is_start == false
			
			local same = same_lane or same_other_lane_behind or same_other_lane_ahead
			
			local your_distance_from_start = (array.body.clampedV3.Value-start.Position).Magnitude
			local your_distance_from_goal = (array.body.clampedV3.Value-goal.Position).Magnitude
			local listing_distance_from_start = (listing.Value.clampedV3.Value-start.Position).Magnitude
			local listing_distance_from_goal = (listing.Value.clampedV3.Value-goal.Position).Magnitude
			local start_to_goal_length = (goal.Position-start.Position).Magnitude
			
			local listing_from_body = (array.body.clampedV3.Value-listing.Value.clampedV3.Value).Magnitude
			
			if opposite then 
				if not (listing.Value.offsetP.Value > 0) then
					if opposite_same_lane then -- same lane
						if your_distance_from_start < listing_distance_from_start then -- ahead
							opposite_ahead[#opposite_ahead+1]={
								[1] = listing_from_body,
								[2] = listing.Value,
								[3] = listing_from_body
							}
						else -- behind
							opposite_behind[#opposite_behind+1] = {
								[1] = listing_from_body,
								[2] = listing.Value,
								[3] = listing_from_body
							}
						end
					end
					if opposite_other_lane_ahead then -- other lane; ahead
						opposite_ahead[#opposite_ahead+1] = {
							[1] = listing_distance_from_goal + your_distance_from_goal,
							[2] = listing.Value,
							[3] = listing_distance_from_goal + your_distance_from_goal,
						}
					end
					if opposite_other_lane_behind then -- other lane; behind
						opposite_behind[#opposite_behind+1] = {
							[1] = listing_distance_from_start + your_distance_from_start,
							[2] = listing.Value,
							[3] = listing_distance_from_start + your_distance_from_start,
						}
					end
				end
			end
			
			if same then
				--[[
				if array.body.offsetP.Value > 0 then -- only check for avoiding civs ahead while you're fully avoiding
					if listing.Value.offsetP.Value == 0 then continue end
				else -- only check for civs who aren't fully avoiding while you're not avoiding
					if listing.Value.offsetP.Value > 0 then continue end
				end]]
				if same_lane then -- same lane
					if your_distance_from_start < listing_distance_from_start then -- ahead
						same_ahead[#same_ahead+1]={
							[1] = listing_distance_from_start,
							[2] = listing.Value,
							[3] = (listing.Value.clampedV3.Value-array.body.clampedV3.Value).Magnitude
						}
					else -- behind 
						same_behind[#same_behind+1] = {
							[1] = listing_distance_from_start,
							[2] = listing.Value,
							[3] = (listing.Value.clampedV3.Value-array.body.clampedV3.Value).Magnitude
						}
					end
				end
				if same_other_lane_behind then -- behind
					same_behind[#same_behind+1] = {
						[1] = start_to_goal_length + listing_distance_from_goal,
						[2] = listing.Value,
						[3] = your_distance_from_start + listing_distance_from_start
					}
				end
				if same_other_lane_ahead then -- ahead
					same_ahead[#same_ahead+1]={
						[1] = listing_distance_from_goal + start_to_goal_length,
						[2] = listing.Value,
						[3] = your_distance_from_goal + listing_distance_from_goal
					}
				end
			end
		end
	end
	
	table.sort(opposite_ahead,least)
	table.sort(opposite_behind,least)
	table.sort(same_ahead,least)
	table.sort(same_behind,least)
	return opposite_ahead, opposite_behind, same_ahead[1], same_behind[1]
end

local function Customize_Civilian(gender,skincolor,outfit,body)

	body.profile.skin.Value=skincolor
	body.profile.outfit.Value=outfit
	body.profile.gender.Value=gender

	local outfits = civilian.Clothes:FindFirstChild(gender):FindFirstChild(outfit)
	local shirts = outfits.Shirts:GetChildren()
	local shirt = shirts[random1orN(#shirts)]
	body.profile.shirt.Value = shirt.Name
	
	local pants = outfits.Pants:GetChildren()
	local pant = pants[random1orN(#pants)]
	body.profile.pants.Value = pant.Name

	local faces = civilian.Faces:FindFirstChild(gender):GetChildren()
	local face = faces[random1orN(#faces)]
	body.profile.face.Value = face.Name

	local can_wear_glasses = random1orN(2)%2==1 and true or false
	local glasses = can_wear_glasses and civilian.Glasses:FindFirstChild(gender):FindFirstChild(outfit)
	if glasses then
		glasses = glasses:GetChildren()
		local _glasses = glasses[random1orN(#glasses)]
		body.profile.glasses.Value=_glasses.Name
	end

	local hair = civilian.Hair:FindFirstChild(gender):FindFirstChild(skincolor):GetChildren()
	local _hair = hair[random1orN(#hair)]
	body.profile.hair.Value = _hair.Name

	local hats = civilian.Hats:FindFirstChild(outfit)
	if hats then
		hats = hats:GetChildren()
		local hat = hats[random1orN(#hats)]
		body.profile.hat.Value=hat.Name
	end
	
	for i,v in pairs(tools) do 
		local _outfit,_toolname=Get_Random(v)
		if _outfit == outfit then
			body.profile.tool.Value=_toolname
		end
	end

end

local function Spawn_Civilian(parent,block,name)
	
	local node = block:FindFirstChild(math.random(1,#block:GetChildren()))
	local obstructions=parent:GetChildren()
	for i,obstruction in pairs(obstructions) do
		if obstruction.goal.Value == node or obstruction.start.Value == node then
			local distance_from_node = (obstruction.clampedV3.Value-node.Position).Magnitude
			if distance_from_node < 36 then return end
		end
	end
	
	local path = New_Path(block,node)
	
	local body = rs.civilian_value:Clone()
	--body.FrontSurface = Enum.SurfaceType.Hinge
	body.Name = name
	body.start.Value = path[1]
	body.goal.Value = path[2]
	local start,goal = path[1].Position,path[2].Position
	body.Value = CFrame.new(start,goal)
	body.Parent = parent
	
	local gender = Get_Random(genders)
	local skincolor = Get_Random(colors)
	local outfit = Get_Random(outfits)

	Customize_Civilian(gender,skincolor,outfit,body)
	
	civilians[#civilians+1] = {
		block = block,
		path = path,
		new_path = nil,
		body = body,
		lastFlee = tick() - 10, -- 10 seconds in the past
		dt = tick(),
		path_index = 1
	}
end

local function create_listing(folder,value)
	local listing = Instance.new("ObjectValue")
	listing.Value = value 
	listing.Name = value.Name
	listing.Parent = folder
end

local ts = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)

--[[
local rips=workspace.rips
--local rips2=workspace.rips2
local characters=game.ServerStorage.characters 

for _,gui in characters:GetDescendants() do 
	if gui:IsA("SurfaceGui") then gui:Destroy() end
end

for _,gui in rips:GetDescendants() do 
	if gui:IsA("SurfaceGui") then
		print("gui")
		local parentName=gui.Parent.Name
		for _,character in characters:GetChildren() do 
			local clone=gui:Clone()
			clone.ImageLabel.ImageColor3=character.Color.Value
			clone.Parent=character:FindFirstChild(parentName)
			clone.ImageLabel.ImageTransparency=1
		end
	end
end
]]

while true do
	local parent,block,name = Find_Block()
	if block then
		Spawn_Civilian(parent,block,name)
	end
	
	for _,array in pairs(civilians) do 
		
		local dt = tick() - array.dt
		array.dt = tick() -- reset
		
		local move = dt*array.body.speed.Value
		
		local goal_node = array.path[array.path_index+1]
		local goal = goal_node.Position
		local goal_listing = goal_node.listings:FindFirstChild(array.body.Name)
		if not goal_listing then
			create_listing(goal_node.listings,array.body)
		end
		
		local start_node = array.path[array.path_index]
		local start = start_node.Position
		local start_listing = start_node.listings:FindFirstChild(array.body.Name)
		if not start_listing then
			create_listing(start_node.listings,array.body)
		end
		
		local opposite_ahead, opposite_behind, same_ahead, same_behind = Get_Nearby_Civilians(array)
		
		local function flee()
			if array.body.isFleeing.Value == false then -- check fleeing
				if tick()-array.lastFlee >= 10 then
					array.lastFlee = tick()
					array.body.isFleeing.Value=true
					array.body.goal_speed.Value=16
				end
			end
			array.body.checkFleeing.Value = false -- turn it off for now until it's triggered again
		end
		
		if same_behind then
			array.body.weight.Value = same_behind[2].weight.Value + 1
			if same_behind[2].isFleeing.Value and same_behind[3] <= 36 then
				array.body.checkFleeing.Value = true
			end
		else
			array.body.weight.Value = 0
		end

		if same_ahead then
			-- 1. only adjust speed if you're behind
			-- 2. only adjust speed for your body
			found_directly_ahead = true
			local d = same_ahead[3]
			local ahead_speed = same_ahead[2].speed.Value
			local goal_speed = array.body.goal_speed.Value
			local p = math.clamp((d-36)/12,0,1)
			local s = lerp(ahead_speed,goal_speed,p)
			array.body.speed.Value = math.clamp(math.clamp(d/36,0,1) * s,0,goal_speed)
		end

		if not same_ahead then -- change the speed back
			array.body.speed.Value = array.body.goal_speed.Value
		end
		
		local offsetP_goal = array.body.offsetP.Value
		
		if opposite_behind and array.body.offsetP.Value > 0 then
			for i = #opposite_behind,1,-1 do 
				local index = opposite_behind[i]
				local d = index[3]
				local p = 1-math.clamp((d-24)/12,0,1)
				offsetP_goal = p
			end
		else -- start moving it back
			if not opposite_ahead[1] or opposite_ahead[1][3] > 36 then
				local p = math.clamp(array.body.offsetP.Value-.2,0,1)
				offsetP_goal = p
			end
		end
		
		if opposite_ahead then
			for i = #opposite_ahead,1,-1 do 
				local index = opposite_ahead[i]
				local you_have_less_weight = index[2].weight.Value > array.body.weight.Value
				local your_name_is_lesser = tonumber(index[2].Name) > tonumber(array.body.Name)
				local is_within_range = index[3] <= 36
				if is_within_range then
					if you_have_less_weight or your_name_is_lesser then
						local d = index[3]
						local p = 1-math.clamp((d-24)/12,0,1)
						offsetP_goal = p
					end
				end
			end
		end
		
		array.body.offsetP.Value = offsetP_goal
		--ts:Create(array.body.offsetP,tweenInfo,{Value=offsetP_goal}):Play()
		
		for _,villain in pairs(workspace.Villains:GetChildren()) do -- check if villain is nearby 
			local d=(villain.PrimaryPart.Position-array.body.clampedV3.Value).Magnitude
			if d <=100 then array.body.checkFleeing.Value=true end
		end
		
		if array.body.checkFleeing.Value == true then -- turn on
			flee()
		end
		
		if tick()-array.lastFlee >= 10 then -- turn off 
			array.body.isFleeing.Value=false
			array.body.goal_speed.Value=8
		end
		
		local start_attachment = start_node:FindFirstChild(goal_node.Name)
		local goal_attachment = goal_node:FindFirstChild(start_node.Name)
		
		local adjusted_start = start:Lerp(start_attachment.WorldPosition,array.body.offsetP.Value)
		local adjusted_goal = goal:Lerp(goal_attachment.WorldPosition,array.body.offsetP.Value)
		
		local length = (start-goal).Magnitude
		local travelled = (array.body.clampedV3.Value-start).Magnitude
		local travel_progress = math.clamp(travelled/length,0,1)
		
		local x,y,z = CFrame.new(start,goal):ToOrientation()
		
		local p = math.clamp(travel_progress+(move/length),0,1)
		
		local pos = adjusted_start:Lerp(adjusted_goal,p)
		local clamped_pos = Vector3.new(pos.X,4,pos.Z)
		local cf = CFrame.new(clamped_pos) * CFrame.fromOrientation(x,y,z)
		if array.body.isRotating.Value == false then -- can't move here while rotating
			--local x,y,z = CFrame.new(array.body.Position,cf.Position):ToOrientation()
			array.body.Value = cf --* CFrame.fromOrientation(x,y,z)
			--ts:Create(array.body,tweenInfo,{CFrame=cf}):Play()
			array.body.clampedV3.Value = Vector3Clamp(cf.Position,start,goal)
		end
		
		if p == 1 then -- reached goal; 1 reached 2, or 2 reached 3
			
			if array.path_index+1 == #array.path then -- end of path, create a new one
				if array.new_path == nil then
					array.new_path = New_Path(array.block,goal_node)
				end
			end
			
			local next_goal = array.new_path ~= nil and array.new_path[2] or array.path[array.path_index+2]
			
			local function check_can_rotate()
				local next_goal_isnt_start = next_goal ~= start_node
				local offset_greater_than_0 = array.body.offsetP.Value > 0
				local rotation_progress_not_1 = array.body.rotation_progress.Value ~= 1

				return next_goal_isnt_start and offset_greater_than_0 and rotation_progress_not_1
			end
			
			if check_can_rotate() then
				local body = array.body
				body.isRotating.Value = true
				local rotation_progress = body.rotation_progress
				local offsetP = body.offsetP
				local radius = offsetP.Value * 6
				local diameter = radius*2
				local circumference = diameter * math.pi
				local rotationLength = circumference/4
				local moveP = move/rotationLength
				rotation_progress.Value = math.clamp(rotation_progress.Value+moveP,0,1)
				local start_attachment = goal_node:FindFirstChild(start_node.Name)
				local goal_attachment = goal_node:FindFirstChild(next_goal.Name)
				local x1,y1,z1 = CFrame.new(goal_node.Position,goal_attachment.WorldPosition):ToOrientation()
				local x2,y2,z2 = CFrame.new(start_attachment.WorldPosition,goal_node.Position):ToOrientation()
				local offset_cf_start = CFrame.new(goal_node.Position,start_attachment.WorldPosition)
				local offset_cf_goal = CFrame.new(goal_node.Position,goal_attachment.WorldPosition)
				local offset_cf = offset_cf_start:Lerp(offset_cf_goal,rotation_progress.Value) * CFrame.new(0,0,-offsetP.Value*6)
				local clamped_pos = Vector3.new(offset_cf.Position.X,4,offset_cf.Position.Z)
				local start_cf = CFrame.new(clamped_pos)*CFrame.fromOrientation(x1,y1,z1)
				local goal_cf = CFrame.new(clamped_pos)*CFrame.fromOrientation(x2,y2,z2)
				array.body.Value = start_cf:Lerp(goal_cf,rotation_progress.Value)
				--ts:Create(array.body,tweenInfo,{CFrame=start_cf:Lerp(goal_cf,rotation_progress.Value)}):Play()
			end 
			
			if not check_can_rotate() then
				array.body.rotation_progress.Value = 0
				array.body.isRotating.Value = false
				if array.path_index+1 == #array.path then 
					array.path_index = 1
					array.path = array.new_path or New_Path(array.block,goal_node)
					array.new_path = nil
				else
					array.path_index += 1
				end
				if start_listing then
					start_listing:Destroy()
				end
				if goal_listing then
					goal_listing:Destroy()
				end
			end
			
			array.body.start.Value = array.path[array.path_index]
			array.body.goal.Value = array.path[array.path_index+1]
		end
	end
	task.wait(1/10)
end

