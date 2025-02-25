local rs = game:GetService("ReplicatedStorage")
local fakeCar = rs.fakeCar
local runService = game:GetService("RunService")
local httpService = game:GetService("HttpService")
local tweenService = game:GetService("TweenService")

local ragdoll = require(rs.ragdoll)

local cars = {}
local numberOfCars = 10
local spawnedCars = 0

local colors = {
	[1] = {25,"Red"},
	[2] = {25,"Blue"},
	[3] = {25,"Green"},
	[4] = {12.5,"Pizza"},
	[5] = {12.5,"Taxi"}
}

local function least(a,b)
	return a[1] < b[1]
end

local _math = require(rs.math)

local function Get_Random(array)
	local n = _math.defined(0,100)
	table.sort(array,least)
	local total = 0
	for index,value in (array) do
		local percent=value[1]+total
		total=percent
		if n <= percent then
			return value[2],value[3]
		end
	end
	return false
end

local function createListing(index,parent)
	local value = Instance.new("StringValue")
	value.Name = index
	value.Value = tick()
	value.Parent = parent
	return value
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

local function Car_Ahead_Lane(folder,ignoreName,start,goal,inLane) -- only if its linear phase will it call this function
	-- folder could be board, so other lanes should be considered
	
	local sorted = {}
	for index,listing in (folder:GetChildren()) do 
		local dict = cars[tonumber(listing.Name)]
		local ignoreBool = inLane and true or dict.name ~= ignoreName
		if dict.startPart == start and ignoreBool then
			-- need to verify same start point, 
			-- and ignore the name of car checking (in case car checking happened to reach the intersection and has a listing)
			local distanceFromStart = (dict.car.Position - dict.startPart.Position).Magnitude
			sorted[#sorted+1] = {
				[1] = distanceFromStart,
				[2] = listing
			}
		end
	end
	
	table.sort(sorted,least)
	
	if #sorted > 0 then
		if inLane then
			for i = 1,#sorted do 
				local listing = sorted[i][2]
				if listing.Name == ignoreName then
					local olderListing = sorted[i+1]
					if olderListing then
						local carData = cars[tonumber(olderListing[2].Name)]
						local car = carData.car
						--local offsetCF = CFrame.new(car.Position) * CFrame.new(0,0,36)
						local clamped = Vector3Clamp(carData.car.Position,carData.startPart.Position,carData.goalPart.Position)
						local x,y,z = carData.goalPart.CFrame:ToOrientation()
						local cf = CFrame.new(clamped) * CFrame.fromOrientation(x,y,z) * CFrame.new(0,0,36)
						return car,cf
					end
				end
			end
		else
			local closestListing = sorted[1][2]
			local carData = cars[tonumber(closestListing.Name)]
			if carData ~= nil then
				local excess = sorted[1][1]-36
				excess = excess < 0 and math.abs(excess) or 0
				return carData.car,excess
			end
		end
	end

	return nil
end

local function Car_Ahead_Intersection(folder,startPart,ignoreName) -- returns car in intersection that came from particular lane; returns the carData
	-- ignoreName is always the car name
	-- folder = the intersection board folder
	-- for when in intersection, startPart = dict.startPart
	-- for when in lane, startPart = dict.goalPart
	local sorted = {}
	for index,listing in (folder:GetChildren()) do
		local dict = cars[tonumber(listing.Name)]
		if dict ~= nil then
			if dict.startPart == startPart then -- verify the same start point
				local variable = nil
				if folder.Parent.Name == "board" then
					variable = tick() - listing.Value
				else
					local start = dict.path[dict.pathIndex]
					variable = (dict.car.Position - start.Position).Magnitude
				end
				sorted[#sorted+1] = {
					[1] = variable,
					[2] = dict
				}
			end
		end
	end
	table.sort(sorted,least)
	local foundIgnore = nil
	for i = 1,#sorted do 
		if sorted[i][2].name == ignoreName then
			foundIgnore = i
			local olderListing = sorted[i+1]
			if olderListing ~= nil then
				return olderListing[2]
			end
		end
	end
	-- needs to progress to this point cause you can't tell if there's a match from inside of the loop
	-- if didn't find ignore, this means your car is checking from lane
	if not foundIgnore then
		if sorted[1] then
			return sorted[1][2]
		end
	end
	return nil
end

local function yield(folder,ignoreName,dict) -- check your turn to go into the intersection
	local sorted = {}
	for index,listing in (folder:GetChildren()) do 
		sorted[#sorted+1] = {
			[1] = tick() - listing.Value,
			[2] = listing
		}
	end
	table.sort(sorted,least)

	local goal = dict.goalPart
	local nextGoal = dict.path[dict.pathIndex+2]
	local folder = goal.yield:FindFirstChild(nextGoal.Name)

	local obstructionFound = false
	for i = 1,#sorted do 
		if sorted[i][2].Name ~= ignoreName then -- this excludes the car 
			local carDict = cars[tonumber(sorted[i][2].Name)]
			local match1 = folder:FindFirstChild(carDict.startPart.Name)
			if match1 then
				local match2 = match1:FindFirstChild(carDict.goalPart.Name)
				if match2 then
					obstructionFound = true
				end
			end
		end
	end
	
	return obstructionFound
end

if not _G.damagePlayer then
	repeat task.wait(1/30) until _G.damagePlayer
end

if not _G.damageNPC then
	repeat task.wait(1/30) until _G.damageNPC
end

local NPCs = require(script.Parent.NPCs)

local function damageAttackablesNearby(pos)
	local villains = workspace.Villains
	for _,villain in (villains:GetChildren()) do 
		local d = (villain.PrimaryPart.Position - pos).Magnitude
		local damage = math.clamp((100-d)/100,0,1)*200
		local NPC = NPCs[villain.Name]
		if damage > 0 then
			local f = coroutine.wrap(_G.damageNPC)
			f(NPC,nil,damage,"Vehicle",3)
		end
	end
	local drones = workspace.SpiderDrones
	for _,drone in (drones:GetChildren()) do 
		local d = (drone.PrimaryPart.Position - pos).Magnitude
		local damage = ((100-d)/100)*200
		local NPC = NPCs[drone.Properties.Tag.Value]
		if damage > 0 then
			local f = coroutine.wrap(_G.damageNPC)
			f(NPC,nil,damage,"Vehicle",3)
		end
	end
	local players = game.Players:GetPlayers()
	for _,player in (players) do 
		local character = player.Character
		if character then
			local d = (character.PrimaryPart.Position - pos).Magnitude
			local damage = ((100-d)/100)*200
			if damage > 0 then
				local f = coroutine.wrap(_G.damagePlayer)
				f(character,nil,damage,"Vehicle",3)
			end
		end
	end
end

local function explodeCar(car)
	for _,group in (workspace.Civilians:GetChildren()) do
		for _,civilian in (group:GetChildren()) do 
			if (civilian.Value.Position-car.Position).Magnitude <= 100 then
				civilian.checkFleeing.Value=true
			end
		end
	end
	car.exploded.Value = true
	
	damageAttackablesNearby(car.Position)
end

local function returnNextNode(array,currentIndex)
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

local function returnPreviousNode(array,currentIndex) 
	if array[currentIndex-1] ~= nil then return end -- there's already a previous index
	local current_node = array[currentIndex]
	local previous_folder = current_node:FindFirstChild("previous")
	local previous_node = previous_folder:FindFirstChildWhichIsA("ObjectValue").Value
	return previous_node
end

local traffic_control = rs.TrafficControl

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

local function createPathData()

	local new = Get_Random_Start_Node(traffic_control:GetChildren())

	local path = {}

	path[2] = new -- the goal
	path[1] = returnPreviousNode(path,2) -- the start point
	
	for i = 1,2 do -- create the next 2 indices
		local next_index = (2-i) + #path
		local current_index = next_index-1
		--print("index=",current_index)
		local result = returnNextNode(path,current_index)
		path[next_index] = result ~= nil and result or path[next_index]
		if result ~= nil then
			--print(next_index,"was created (future)")
		end
	end

	return path
end

local lastSpawnTick = 0
local function spawnCar(spawnPoint)
	if tick() - lastSpawnTick < .25 then return end
	local path = createPathData()
	
	local goal = path[2]
	local start = path[1]
	local spawnCF = goal.CFrame * CFrame.new(0,0,50) -- 50 studs behind the goal
	local length = (goal.Position - start.Position).Magnitude
	local spawn_length = (spawnCF.Position - goal.Position).Magnitude
	local spawnProgress = spawn_length/length
	local offset = math.clamp(36/length,0,1) -- length of car compared to length of path
	
	local start_to_spawn_length = (start.Position-spawnCF.Position).Magnitude
	local excess = math.clamp(36-start_to_spawn_length,0,math.huge)
	
	local foundCarWithinThreshold = false
	local reason = nil
	
	if excess > 0 then
		if start.Parent.Name == "Intersection6" then
			--print("excess=",excess)
		end
		local board = start.Parent.board.cars
		for _,listing in (board:GetChildren()) do 
			local carDict = cars[tonumber(listing.Name)]
			if carDict.goalPart == start then -- if the car is headed to the start node
				if carDict.phase == "rotation" then
					local distance_from_goal = carDict.rotationLength-(carDict.rotationProgress*carDict.rotationLength)
					--[[
					if start.Parent.Name == "Intersection6" then
						reason="rotation "..math.round(distance_from_goal)
					end
					]]
					if distance_from_goal < excess then
						foundCarWithinThreshold = true
					end
				elseif carDict.phase == "linear" then
					local distance_from_goal = (carDict.car.Position - start.Position).Magnitude
					--[[
					if start.Parent.Name == "Intersection6" then
						reason = "linear "..math.round(distance_from_goal)
					end
					]]
					if distance_from_goal < excess then
						foundCarWithinThreshold = true
					end
				end
			end
		end
	end
	
	--[[
	if start.Parent.Name == "Intersection6" then
		if foundCarWithinThreshold then
			print("can't spawn, reason: "..reason,"w/ excess",excess)
		end
	end
	]]
	
	if foundCarWithinThreshold then return end
	
	for index,listing in (goal.cars:GetChildren()) do
		local car = workspace.Cars:FindFirstChild(listing.Name)
		if car then
			local carProgress = (car.Position - start.Position).Magnitude/length
			local behindThreshold = (1-spawnProgress) - offset -- = spawn pos - 2 car lengths
			--workspace.placementA.Position = start.Position:Lerp(goal.Position,behindThreshold)
			local aheadThreshold = (1-spawnProgress) + offset
			--workspace.placementB.Position = start.Position:Lerp(goal.Position,aheadThreshold)
			if carProgress > behindThreshold and carProgress < aheadThreshold then
				foundCarWithinThreshold = true
			end
		end
	end
	
	if foundCarWithinThreshold then return end -- only spawn car in if there's room
	
	spawnedCars += 1
	--print("SPAWNED CAR")
	
	lastSpawnTick = tick()
	local index = #cars+1
	cars[index] = {
		name = tostring(index),
		car = fakeCar:Clone(),
		path = path,
		prevPathIndex = -1,
		pathIndex = 0,
		dt = nil,
		destroyTimer = nil,
		startTimer = nil, -- reset whenever start point is reset
		speed = 36,
		max = 36,
		start = nil,
		goal = nil,
		startPart = nil,
		goalPart = nil,
		carAhead = nil,
		progress = nil,
		reverses = nil,
		lastGoalChange = nil,
		rotation = nil,
		rotator = nil,
		rotationLength = nil,
		rotationProgress = nil,
		startRotation = nil,
		phase = nil
	}
	
	local listing = cars[index]
	local car = listing.car
	car.Name = listing.name
	car.color.Value = Get_Random(colors)
	car.health.Value =300
	car.CFrame = spawnCF
	car.Parent = workspace.Cars
	
	car.hitPart.Touched:Connect(function(part)
		if car.speed.Value < 20 then return end
		local speed=car.speed.Value
		
		local damage= (((speed-20)/(36-20))*50)+75
		local properties = part.Parent:FindFirstChild("Properties") or part.Parent.Parent:FindFirstChild("Properties")
		local humanoid = not properties and part.Parent:FindFirstChild("Humanoid") or part.Parent.Parent:FindFirstChild("Humanoid")
		
		local name = nil
		local model = nil -- if NPC, this will be the NPCs module index
		local isNPC = nil
		
		if humanoid then
			--print(car.Name,"hit humanoid")
			name = humanoid.Parent.Name
			model = humanoid.Parent
		end
		
		if properties then
			--print(car.Name,"hit NPC")
			local isDrone = properties:IsDescendantOf(workspace.SpiderDrones)
			name= isDrone and properties.Tag.Value or properties.Parent.Name
			isNPC = true
			model = NPCs[name]
		end
		
		if name == nil then return end
		
		local listing = car.hit:FindFirstChild(name)
		if not listing then
			listing = Instance.new("StringValue")
			listing.Name = name
			listing.Value = tick() - 2
			listing.Parent = car.hit
		end
		
		if tick() - listing.Value >= 2 and not car.exploded.Value then
			listing.Value = tick()
			car.health.Value = math.clamp(car.health.Value - damage,0,300)
			if car.health.Value == 0 then
				local f = coroutine.wrap(explodeCar)
				f(car)
			else 
				if isNPC then
					_G.damageNPC(model,nil,damage,"Vehicle",3)
				else
					_G.damagePlayer(model,nil,damage,"Vehicle",3)
				end
			end
		end
		
	end)
	
end

local function updateGlobals(index)
	local dict = cars[index]
	
	dict.pathIndex += 1 -- increase the path index
	
	--print("current index=",dict.pathIndex)
	
	for i = 1,3 do -- make sure there's 3 incides past current index
		local next_index = i + dict.pathIndex
		local current_index = next_index-1
		--print("index=",current_index)
		local result = returnNextNode(dict.path,current_index)
		dict.path[next_index] = result ~= nil and result or dict.path[next_index]
		if result ~= nil then
			--print(next_index,"was created (future)")
		end		
	end
	
	dict.startPart = dict.path[dict.pathIndex]
	dict.goalPart = dict.path[dict.pathIndex+1]
	
	local startValue = dict.car.startPart:FindFirstChildOfClass("ObjectValue")
	startValue.Name = dict.startPart.Parent.Name
	startValue.Value = dict.startPart
	local goalValue = dict.car.goalPart:FindFirstChildOfClass("ObjectValue")
	goalValue.Name = dict.goalPart.Parent.Name
	goalValue.Value = dict.goalPart
	
	local direction = "straight"
	
	if dict.goalPart.Name:match("end") then -- red node
		local rotator = dict.goalPart:FindFirstChild(dict.startPart.Name)
		if rotator then
			dict.phase = "rotation"
			direction = rotator.Value.Name:match("Right") and "right" or "left"
		else
			dict.phase = "linear"
		end
	else
		dict.phase = "linear"
	end
	
	if dict.phase == "rotation" then
		local rotator = dict.goalPart:FindFirstChild(dict.startPart.Name)
		dict.rotator = rotator.Value:Clone()
		dict.rotator.Name = dict.name
		dict.rotator.Parent = dict.goalPart.Parent
		dict.startRotation = dict.rotator.Orientation.Y
		dict.rotation = dict.rotator.rotation.Value--dict.rotator.Orientation
		local radius = math.abs(dict.rotator.Attachment.Position.X)
		local diameter = radius*2
		local circumference = diameter * math.pi
		dict.rotationLength = circumference/4
		dict.rotationProgress = 0
		dict.progress = nil
		dict.start = 0
		dict.goal = 1 
	elseif dict.phase == "linear" then
		dict.rotator = nil
		dict.rotation = nil
		dict.progress = 0
		dict.reverses = 0
		dict.start = dict.pathIndex == 1 and dict.goalPart.CFrame * CFrame.new(0,0,50) or dict.startPart.CFrame
		dict.goal = dict.goalPart.CFrame
	end
	
	--print("UPDATED:",dict.name,"start=",dict.start)
	
	dict.car.phase.Value = dict.phase
	dict.car.direction.Value = direction
	dict.car.progress.Value = 0
	
	dict.carAhead = nil
	dict.carAheadInt = nil
	dict.car.CFrame = dict.phase == "linear" and dict.start or dict.startPart.CFrame
	dict.prevPathIndex = dict.pathIndex
	dict.startTimer = tick() -- reset start timer
	dict.dt = tick() -- reset elapsed time
end

local function lerp(start,goal,alpha)
	return ((goal-start) * alpha) + start
end

local function Get_Rotation_Length_Intersection(startPart,endPart)
	local rotator = endPart:FindFirstChild(startPart.Name).Value
	local radius = math.abs(rotator.Attachment.Position.X)
	local diameter = radius*2
	local circumference = diameter * math.pi
	return circumference/4 -- this is the rotation length of the intersection
end

local function Get_Speed(dict,initial)
	local speed_element = dict.goalPart:FindFirstChild("speed")
	if speed_element then
		if speed_element:IsA("NumberValue") then
			return initial ~= nil and speed_element.initial.Value or speed_element.Value
		else 
			local speed_value = speed_element:FindFirstChild(dict.startPart.Name)
			if speed_value then
				return initial ~= nil and speed_value.initial.Value or speed_value.Value
			end
		end
	end
	return 1
end

local function Update_Speed_Value(value,alpha)
	local speed_element = value
	if speed_element then
		if speed_element:IsA("Folder") then
			for index,speedValue in (speed_element:GetChildren()) do 
				speedValue.Value = lerp(0, speedValue.initial.Value, alpha)
				speedValue.Value = math.clamp(speedValue.Value,1,speedValue.initial.Value)
			end
		else 
			if speed_element.initial.Value ~= 1 then
				speed_element.Value = lerp(0, speed_element.initial.Value, alpha)
				speed_element.Value = math.clamp(speed_element.Value,1,speed_element.initial.Value)
			end
		end			
	end
end

local function Reset_Speed_Value(value)
	local speed_element = value
	if speed_element then
		if speed_element:IsA("Folder") then
			for index,speedValue in (speed_element:GetChildren()) do 
				speedValue.Value = speedValue.initial.Value
			end
		else 
			if speed_element.initial.Value ~= 1 then
				speed_element.Value = speed_element.initial.Value
			end
		end			
	end
end

local function Adjust_Speed_Values(folder,dict,delete)
	local sorted = {}
	for _,listing in (folder:GetChildren()) do -- check folder for last car, if any
		local carDict = cars[tonumber(listing.name)]
		if carDict.goalPart.Name:match("end") then -- intersection
			if carDict.startPart == dict.startPart and carDict.goalPart == dict.goalPart then -- exact same path
				sorted[#sorted+1] = {
					[1] = tick() - listing.Value,
					[2] = carDict
				}
			end
		elseif (carDict.goalPart.Name:match("start")) then -- lane
			if carDict.goalPart == dict.goalPart then -- exact same path
				sorted[#sorted+1] = {
					[1] = tick() - listing.Value,
					[2] = carDict
				}
			end			
		end
	end

	table.sort(sorted,least)

	if not (#sorted > 0) then return end

	local action = nil
	local closest = sorted[1][2]
	if closest == delete then
		action = "reset"
		local _next = sorted[2]
		if _next then -- just adjust to next car in line
			action = "adjust"
			closest = _next[2]
		end
	else -- just adjust since there's no deletion to consider
		action = "adjust"
	end

	local _dict = closest -- this could be destroyed tho

	if action == "adjust" then
		local length = nil
		local travelled = nil
		local alpha = nil
		if _dict.phase == "rotation" then
			length = _dict.rotationLength
			travelled = length*_dict.rotationProgress
			local max = _dict.max
			if length < (max*2) then
				max = length/2
			end
			alpha = math.clamp((travelled-max)/max,0,1)
		elseif _dict.phase == "linear" then
			length = (_dict.startPart.Position - _dict.goalPart.Position).Magnitude
			travelled = (_dict.car.Position - _dict.startPart.Position).Magnitude
			local max = _dict.max
			if length < (max*2) then
				max = length/2
			end
			alpha = math.clamp((travelled-max)/max,0,1)
		end
		
		-- update the speed value of the startPart (if it has one)
		Update_Speed_Value(_dict.startPart:FindFirstChild("speed"),alpha)
	elseif action == "reset" then
		-- only use this if there aren't any cars left
		Reset_Speed_Value(_dict.startPart:FindFirstChild("speed"))
	end
end

local _break = false
while true do
	if spawnedCars < numberOfCars then
		spawnCar()
	end
	for index,dict in (cars) do
		
		if dict.prevPathIndex ~= dict.pathIndex then -- you changed goals, update the globals
			updateGlobals(index)
		end
		
		local dt = tick() - dict.dt
		dict.dt = tick() -- reset the timer every iteration

		if dict.phase == "rotation" then
			dict.goal = 1
			local _carAhead = nil
			local nextGoalPart = dict.path[dict.pathIndex+2]
			local goalPartFolder = nextGoalPart.cars
			local carAhead,excess = Car_Ahead_Lane(goalPartFolder,dict.name,dict.goalPart,nextGoalPart) -- send ignore name cause what if reached goal and adds listing
			if carAhead then
				local excessProgress = excess/dict.rotationLength
				dict.goal = math.clamp(1-excessProgress,0,1)
				_carAhead = carAhead
			end

			local board_folder = dict.goalPart.Parent.board.cars
			local carAheadInt = Car_Ahead_Intersection(board_folder,dict.startPart,dict.name)
			if carAheadInt then
				local rotationLength = carAheadInt.rotationLength
				local progress = carAheadInt.rotationProgress
				dict.goal = math.clamp(progress - (36/rotationLength),0,1)	
				_carAhead = carAheadInt.car	
			end

			if _carAhead ~= dict.carAhead then
				dict.car.carAhead.Value = _carAhead
				dict.carAhead = _carAhead 
				dict.start = dict.rotationProgress
				--dict.startTimer = tick()
			end

			if dict.car.exploded.Value then
				dict.car.BrickColor = BrickColor.Black()
				if not dict.destroyTimer then
					dict.destroyTimer = tick()
				end
				local p = math.clamp((tick() - dict.destroyTimer)/4,0,1)
				dict.speed = lerp(dict.speed,0,p)
			else
				local distanceFromStart = (dict.rotationProgress - dict.start) * dict.rotationLength
				local distanceFromGoal = (dict.goal - dict.rotationProgress) * dict.rotationLength
				
				local max = Get_Speed(dict,true)
				if distanceFromGoal > max then
					local goal_speed = max
					local p = math.clamp(distanceFromStart/max,0,1)
					dict.speed = lerp(dict.speed,goal_speed,p)
				else 
					dict.speed = max
				end

				goal_speed = dict.goal ~= 1 and 1 or Get_Speed(dict)
				local p = 1-math.clamp(distanceFromGoal/dict.max,0,1)
				dict.speed = lerp(dict.speed,goal_speed,p)
			end
			
			local min_speed = dict.car.exploded.Value and 0 or 1
			dict.speed = math.clamp(dict.speed,min_speed,dict.max) -- make sure speed is within threshold

			dict.car.speed.Value = dict.speed

			local move = dict.speed*dt
			
			local min = dict.start
			local max = math.clamp(dict.goal,min,1)
			local progress = math.clamp(dict.rotationProgress+(move/dict.rotationLength),min,max)
			dict.rotationProgress = progress
			dict.car.progress.Value = dict.rotationProgress
			local rotation = lerp(0,dict.rotation,progress)
			dict.rotator.Orientation = Vector3.new(0,dict.startRotation+rotation,0)
			--local x,y,z = dict.rotator.CFrame:ToOrientation()
			--local alpha = tweenService:GetValue(progress,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)
			local x,y,z = dict.startPart.CFrame:Lerp(dict.goalPart.CFrame,progress):ToOrientation()
			dict.car.CFrame = CFrame.new(dict.rotator.Attachment.WorldPosition) * CFrame.fromOrientation(x,y,z)

			Adjust_Speed_Values(board_folder,dict)

			if dict.rotationProgress == 1 then -- advance to next goal
				local listing = dict.goalPart.Parent.board.cars:FindFirstChild(dict.name)
				if listing then
					listing:Destroy() -- remove from board
				end
				local next_goal = dict.path[dict.pathIndex+2]
				local folder = next_goal.cars
				local listing = folder:FindFirstChild(dict.name)
				if not listing then
					createListing(dict.name,folder)
				end
				dict.rotator:Destroy()
				dict.rotator = nil
				updateGlobals(index)
			end

		elseif dict.phase == "linear" then
			local folder = dict.goalPart:FindFirstChild("cars") -- this means goal is green node if truthy, red node if nil
			local board_folder = dict.goalPart.Parent.board.cars

			-- check if listing exists, if it doesn't make one
			if folder then
				local listing = folder:FindFirstChild(dict.name)
				if not listing then 
					listing = createListing(dict.name,folder)
				end				
			end

			dict.goal = dict.goalPart.CFrame
			local _carAhead = nil 
			local next_goal = dict.path[dict.pathIndex+2]

			if dict.goalPart.Parent.Name:match("Corner") then -- make sure car in lane ahead's offset isn't spilling into your lane
				-- 1. get the excess from closest car in next lane, past the intersection.
				local _3rd_goal = dict.path[dict.pathIndex+3]
				local folder = _3rd_goal.cars
				local carAheadNextLane,excess = Car_Ahead_Lane(folder,dict.name,next_goal,_3rd_goal)
				if carAheadNextLane then
					-- 2. get the intersection length
					local intersectionPathLength = Get_Rotation_Length_Intersection(dict.goalPart,next_goal)
					-- 3. set the goal offset
					local d = intersectionPathLength - excess
					local offset = d < 0 and math.abs(d) or 0 
					dict.goal = dict.goalPart.CFrame * CFrame.new(0,0,offset)
					dict.lastGoalChange = "1,carAheadPos= "..tostring(carAheadNextLane.Position)
					_carAhead = carAheadNextLane					
				end
			end

			local _startPart = nil
			local _folder = nil
			
			if dict.goalPart.Name:match("end") then -- definitely in intersection
				_startPart = dict.goalPart -- used to verify same lane
				_folder = next_goal.cars
			else -- definitely in lane 
				_startPart = dict.goalPart -- used to verify same lane
				_folder = board_folder
			end

			local carAheadInt = Car_Ahead_Intersection(_folder,_startPart,dict.name)
			if carAheadInt then
				if carAheadInt.phase == "rotation" then
					local rotationLength = carAheadInt.rotationLength
					local rotationProgress = carAheadInt.rotationProgress
					local travelled = rotationLength*rotationProgress
					local excess = travelled-36
					local offset = excess < 0 and math.abs(excess) or 0
					dict.goal = dict.goalPart.CFrame * CFrame.new(0,0,offset)
					dict.lastGoalChange = "2,carAheadPos= "..tostring(carAheadInt.car.Position).." excess= "..tostring(offset)
					_carAhead = carAheadInt.car
				elseif carAheadInt.phase == "linear" then
					local carAhead,excess = Car_Ahead_Lane(_folder,dict.name,dict.goalPart,next_goal)
					if carAhead then
						dict.goal = dict.goalPart.CFrame * CFrame.new(0,0,excess)
						dict.lastGoalChange = "3,carAheadPos= "..tostring(carAheadInt.car.Position).." excess= "..tostring(excess)
						_carAhead = carAhead
					end
				end
			end

			if folder then
				local carAhead,carAheadCF = Car_Ahead_Lane(folder,dict.name,dict.startPart,dict.goalPart,true)
				if carAhead then
					dict.goal = carAheadCF
					dict.lastGoalChange = "4,carAheadPos= "..tostring(carAhead.Position).." offset ="..tostring(carAheadCF.Position)
					_carAhead = carAhead
				end				
			end
			
			if _carAhead ~= dict.carAhead then
				dict.carAhead = _carAhead
				dict.start = dict.car.CFrame
				dict.car.carAhead.Value = _carAhead
			end
			
			local max_length = (dict.startPart.Position - dict.goalPart.Position).Magnitude
			local small_but_not_zero = 0.00001
			
			local travelled = (dict.car.Position - dict.start.Position).Magnitude
			local length = math.clamp((dict.start.Position - dict.goal.Position).Magnitude,small_but_not_zero,max_length)
			local travel_progress = math.clamp(travelled/length, 0, 1)
			
			local real_length = (dict.startPart.Position - dict.goalPart.Position).Magnitude
			local real_travelled = (dict.car.Position - dict.startPart.Position).Magnitude
			
			local p = math.clamp(real_travelled/real_length,0,1)
			if p < dict.progress then
				dict.car.movedBackwards.Value = true
				dict.reverses += 1
				--print conditions to get an idea of what's happening
				--print("reverses=",dict.reverses)
				--print("travelled=",travelled)
				--print("length=",length)
				--print("travel_progress=",travel_progress)
				--print("start=",dict.start.Position)
				--print("goal=",dict.goal.Position)
				--print("changed by:",dict.lastGoalChange)
				--print("dict.progress=",dict.progress)
				
			elseif p > dict.progress then
				dict.car.movedBackwards.Value = false
			end
			dict.progress = p
			
			local goal_speed = nil

			if dict.car.exploded.Value then
				dict.car.BrickColor = BrickColor.Black()
				if not dict.destroyTimer then
					dict.destroyTimer = tick()
				end
				local p = math.clamp((tick() - dict.destroyTimer)/4,0,1)
				dict.speed = lerp(dict.speed,0,p)
			else
				local distanceFromStart = (dict.car.Position - dict.start.Position).Magnitude
				local distanceFromGoal = (dict.car.Position - dict.goal.Position).Magnitude
				
				if distanceFromGoal > dict.max then
					goal_speed = dict.max
					local p = math.clamp(distanceFromStart/dict.max,0,1)
					dict.speed = lerp(dict.speed,goal_speed,p)
				else 
					dict.speed = dict.max
				end

				goal_speed = dict.goal ~= dict.goalPart.CFrame and 1 or Get_Speed(dict)
				local p = 1-math.clamp(distanceFromGoal/dict.max,0,1)
				dict.speed = lerp(dict.speed,goal_speed,p)
			end
			
			local min_speed = dict.car.exploded.Value and 0 or 1
			dict.speed = math.clamp(dict.speed,min_speed,dict.max) -- make sure speed is within threshold

			dict.car.speed.Value = dict.speed

			local move = dict.speed*dt

			local progress = math.clamp(travel_progress+(move/length),0,1)
			local newCF = dict.start:Lerp(dict.goal,progress)
			dict.car.CFrame = newCF 
			
			if folder then
				Adjust_Speed_Values(folder,dict)
			else 
				Adjust_Speed_Values(board_folder,dict)
			end

			if dict.car.Position == dict.goalPart.Position then -- goal reached
				--print(dict.name,"reached goal")
				local boardFolder = dict.goalPart.Parent.board.cars
				local boardListing = boardFolder:FindFirstChild(dict.name)

				if folder then -- goal was green node, you just reached intersection
					if not boardListing then
						createListing(dict.name,boardFolder)
					end		
				else -- goal was red node, you just reached the end of the intersection
					if boardListing then
						boardListing:Destroy()
					end
					local next_goal = dict.path[dict.pathIndex+2]
					local folder = next_goal.cars
					local listing = folder:FindFirstChild(dict.name)
					if not listing then
						createListing(dict.name,folder)
					end
				end
				
				local function update()
					if folder then
						local listing = folder:FindFirstChild(dict.name)
						if listing then
							listing:Destroy()
						end		
					end
					updateGlobals(index)
				end
				
				if dict.goalPart.Parent.Name:match("Intersection") then -- intersection
					if folder then -- wait for your turn
						if not yield(boardFolder,dict.name,dict) then -- you can move up
							update()
						end
					else -- you're already at the end of the intersection, don't wait
						update()	
					end
				else -- corner intersection
					update()
				end

			end
		end

		if dict.car.exploded.Value then
			if dict.destroyTimer then
				local elapsed = tick() - dict.destroyTimer
				if elapsed > 10 then
					local folder = dict.goalPart:FindFirstChild("cars")
					if folder then
						local listing = folder:FindFirstChild(dict.name)
						if listing then
							Adjust_Speed_Values(listing.Parent,dict,dict)
							listing:Destroy()
						end
					end
					local board_listing = dict.goalPart.Parent.board.cars:FindFirstChild(dict.name)
					if board_listing then 
						Adjust_Speed_Values(board_listing.Parent,dict,dict)
						board_listing:Destroy()
					end
					dict.car:Destroy()
					cars[index] = nil
					spawnedCars -=1
					if dict.rotator then
						dict.rotator:Destroy()
					end
				end
			end
		end	

	end
	task.wait(1/10)--runService.Stepped:Wait()
end