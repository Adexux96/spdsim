
local rs = game:GetService("ReplicatedStorage")
local algorithm=require(script.Parent["Astar"])

local nodes=workspace.nodes2

local villains = workspace.Villains

local serverHeli = rs.serverHeli
local helicopter = nil
local horizontalSpeed=72
local verticalSpeed=36
local p=0
local heightP=0
local dt = tick()
local ignoreY=Vector3.new(1,0,1)

local function least(a,b)
	return a[1] < b[1]
end

local function Get_Closest_Node(pos)
	local array={}
	for _,node in pairs(nodes:GetChildren()) do 
		--if node.Name=="spawn" then continue end
		local d = ((node.Position*ignoreY)-(pos*ignoreY)).Magnitude
		array[#array+1]={
			[1]=d,
			[2]=node
		}
	end
	table.sort(array,least)
	return array[1][2]
end

local closest_villain_node=nil
local path={}
local start
local goal

local path_index

local function update(_start,_goal)
	path=algorithm:GeneratePath(_start,_goal,workspace.nodes2,{},{total=tick(),runs=0,start=tick()})
	--print("new path")
	--// exclude the movement from the path progress, use moveto instead of lerp
	--// when the helicopter gets within a certain distance of a node, you can
	
	if not path[1] then
		path={[1]={Position=_goal.Position,Name=_goal.Name}}
	end
	
	for i,v in path do -- create new structure
		local t={}
		t.Position=v.Position*ignoreY
		t.Name=v.Name
		path[i]=t
	end
	
	if path[2]~=nil then
		local heli_to_path2=((helicopter.Position*ignoreY)-path[2].Position).Magnitude
		local path1_to_path2=(path[1].Position-path[2].Position).Magnitude
		if heli_to_path2 < path1_to_path2 then
			table.remove(path,1)
		end
	end
	
	path_index=1
	--local closest_node=Get_Closest_Node(helicopter.Position)
	table.insert(path,1,{Position=helicopter.Position*ignoreY,Name="helicopter"})
	
	--// assign height values for each index
		--// padHeight is assigned if:
			--// name=="spawn"
			--// name=="helicopter" and the next index is named "spawn"	
	
	local padHeight=Vector3.new(0,(helicopter.Size.Y/2)+502.5,0) 
	local flyHeight=Vector3.new(0,600,0)
	local currentHeight=Vector3.new(0,helicopter.Position.Y,0)
	
	for i,v in path do 
		local takeoff=(v.Name=="spawn" and i~=#path) and "takeoff" or nil
		takeoff=takeoff or (v.Name=="helicopter" and helicopter.landed.Value) and "takeoff" or nil
		local landing=(v.Name=="spawn" and i==#path) and "landing" or nil
		local flying=(not (takeoff or landing)) and "flying" or nil
		v.action=flying and flying or (takeoff or landing)
		--print("index=",i,"name=",v.Name,"action=",v.action)
	end
	
	start=path[1].Position
	goal=path[2].Position
	
end

local function Check_Path_Eligibility()
	local villain=villains:FindFirstChildOfClass("Model")
	if villain and villain.Properties.Health.Value>0 then -- there is a villain!
		helicopter.returning.Value=false
		helicopter.target.Value=villain
		local _start=Get_Closest_Node(helicopter.Position)
		local _goal=Get_Closest_Node(villain.PrimaryPart.Position)
		--print("closest villain node=",_goal)
		if closest_villain_node ~= _goal then
			closest_villain_node=_goal
			update(_start,_goal)
		end
	else -- there isn't a villain 
		if helicopter.returning.Value == false then
			helicopter.target.Value=nil
			helicopter.returning.Value=true
			local _start=Get_Closest_Node(helicopter.Position)
			local _goal=nodes.spawn
			update(_start,_goal)
		end
	end
end

local padHeight=502.5
local flyHeight=600
local small_but_not_zero=0.000001

local ts=game:GetService("TweenService")

while true do
	local elapsed=tick()-dt
	dt=tick()
	if not helicopter then
		helicopter = serverHeli:Clone()
		helicopter.Name = "serverHeli"
		helicopter.CFrame = nodes.spawn.CFrame + Vector3.new(0,padHeight+(helicopter.Size.Y/2),0)
		--// use attributes for the client to read like progress, current, next, action 
		helicopter.Parent = workspace
		Check_Path_Eligibility()
	end
	--// use attributes for the client to read like progress, current, next, action 
	if #path>0 then
		local move=horizontalSpeed*elapsed
		local length=(start-goal).Magnitude
		length=math.clamp(length,small_but_not_zero,math.huge)
		local travelled=(helicopter.Position*ignoreY-start).Magnitude
		travelled=math.clamp(travelled,small_but_not_zero,length)
		local travel_progress=math.clamp(travelled/length,0,1)
		
		local startPos=start+Vector3.new(0,600,0)
		local goalPos=goal+Vector3.new(0,600,0)
		
		local function Progress_Path()
			if path_index < #path then
				start=path[path_index].Position
				goal=path[path_index+1].Position
				path_index+=1
			end
		end
		
		local function Progress()
			Progress_Path()
			Check_Path_Eligibility()
		end
		
		p=math.clamp(travel_progress+(move/length),0,1)
		helicopter.progress.Value=p
		--print("p=",p)
		--// issue: shouldn't be able to travel horizontally until the vertical goal is reached
		--// but when coming back to the pad, it needs to travel horizontally before it can float down to the pad.
		
		--// on what terms can the heli travel vertically?
			--// if it's on top of the pad at the last index of the path
			--// if it's the first index of the path and the name of the index is spawn
			
		local action=path[path_index].action 
		helicopter.action.Value=action
		local horizontal=action=="flying" or (action=="landing" and p<1)
		horizontal=horizontal and not helicopter.landed.Value
		local vertical=action=="takeoff" or (action=="landing" and p==1)
		vertical=vertical or (horizontal==false) --// if horizontal is false, just set vert to true
		
		helicopter.horizontal.Value=horizontal
		helicopter.vertical.Value=vertical
		
		if vertical then
			local startHeight
			local goalHeight
			if path[path_index].action=="takeoff" then
				startHeight=Vector3.new(0,padHeight+(helicopter.Size.Y/2),0)
				goalHeight=Vector3.new(0,600,0)
			else
				startHeight=Vector3.new(0,600,0)
				goalHeight=Vector3.new(0,padHeight+(helicopter.Size.Y/2),0)
			end
			local length=(startHeight-goalHeight).Magnitude
			local travelled=(Vector3.new(0,helicopter.Position.Y,0)-startHeight).Magnitude
			travelled=math.clamp(travelled,small_but_not_zero,length)
			local travel_progress=math.clamp(travelled/length,0,1)
			local move=verticalSpeed*elapsed
			heightP=math.clamp(travel_progress+(move/length),0,1)
			helicopter.heightP.Value=heightP
			startPos=(helicopter.Position*ignoreY)+startHeight
			goalPos=(helicopter.Position*ignoreY)+goalHeight
			local pos=startPos:Lerp(goalPos,heightP)
			helicopter.CFrame=CFrame.new(pos)
			if heightP==1 then
				helicopter.landed.Value=path[path_index].action=="landing" and true or false 
				Progress()
			end
		elseif horizontal then
			local pos=startPos:Lerp(goalPos,p)
			helicopter.CFrame=CFrame.new(pos)
			if p==1 then -- reached horizontal goal
				Progress()
			end
		end
		helicopter.current.Value=startPos
		helicopter.next.Value=goalPos
		--print("current node=",path[path_index].Name)
	else
		Check_Path_Eligibility()
	end
	
	task.wait(1/10)
end
