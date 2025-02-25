local module = {}

local function Least_Value(a,b)
	return tonumber(a.Value) < tonumber(b.Value)
end

local function Least_1(a,b)
	return a[1]<b[1]
end

local function Least_Unvisited(t)
	local least,node=math.huge,nil
	for i,v in next,t do 
		if v[1]<least then
			least=v[1] node=v[2]
		end
	end
	return node,least
end

function module.GetDictionaries(self,nodes,start,goal,ignore)
	local unvisited = {}
	local deepCopy={}
	local matrices = {}
	for _,node in pairs(nodes:GetChildren()) do 
		unvisited[node.Name] = ignore[node.Name]~=true and {math.huge,node} or nil
		deepCopy[node.Name]= ignore[node.Name]~=true and {math.huge,node} or nil
		if node == start then
			matrices[node.Name] = {prev=nil,gscore=0,fscore=(node.Position-goal.Position).Magnitude}
			unvisited[node.Name]={0,node}
			continue
		end
		matrices[node.Name] = ignore[node.Name]~=true and {prev=nil,gscore=math.huge,fscore=math.huge} or nil
	end
	return unvisited, matrices, deepCopy
end

function module.SecurityCheck(self,dt,n)
	if tick()-dt.start>.1 then -- prevent stack overflow
		print("waiting")
		task.wait()
		dt.start=tick()
		dt.runs+=1
		if dt.runs>=n then -- stop the algorithm if take too long
			return true
		end 
	end
	return false
end

function module.GetPath(self, current, goal, nodes, ignore, dt)
	if current==goal then
		return {
			[current.Name]={prev=goal.Name},
			[goal.Name]={prev=nil}
		},dt
	end
	local unvisited, matrices, deepCopy = module:GetDictionaries(nodes,current,goal,ignore)
	local function Update_Matrix(update,prev,gscore,node)
		--print("updated:",update,"w/",gscore)
		matrices[update].prev = prev
		matrices[update].gscore = gscore
		unvisited[update][1]=gscore+(node.Position-goal.Position).Magnitude
	end
	local start=current
	for key,value in next,deepCopy do
		current=Least_Unvisited(unvisited)
		local neighbors = current.neighbors:GetChildren()
		table.sort(neighbors,Least_Value)
		for i = 1,#neighbors do
			local neighbor = neighbors[i]
			if ignore[neighbor.Name] then continue end
			local isUnvisited=unvisited[neighbor.Name]~=nil
			if not matrices[neighbor.Name] then 
				print("neighborName=",neighbor.Name)
			end
			local neighbors_gscore = matrices[neighbor.Name].gscore
			local current_gscore = matrices[current.Name].gscore + tonumber(neighbor.Value)
			if current_gscore < neighbors_gscore then
				if isUnvisited or matrices[neighbor.Name].prev==nil then
					Update_Matrix(neighbor.Name,current.Name,current_gscore,deepCopy[neighbor.Name][2])
				end
			end
		end
		unvisited[current.Name]=nil
		if current == goal then --[[print("break2")]] break end
		if module:SecurityCheck(dt,3) then -- worst case scenario, send mock path
			return {
				[current.Name]={prev=goal.Name},
				[goal.Name]={prev=nil}
			},dt
		end
	end
	return matrices,dt
end

function module.ReverseSearch(self,path,nodes,goal,list)
	list = list or {}
	table.insert(list,1,nodes:FindFirstChild(goal))
	goal=path[goal].prev
	if goal == nil then
		return list
	end
	return module:ReverseSearch(path,nodes,goal,list)
end

function module.GeneratePath(self,start,goal,nodes,ignore,dt)
	dt=dt or {total=tick(),runs=0,start=tick()}
	local matrices,dt = module:GetPath(start,goal,nodes,ignore,dt)
	local path = module:ReverseSearch(matrices,nodes,goal.Name)
	return path,dt
end

return module