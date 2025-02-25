local NPCs = require(script.Parent.NPCs)
local cs = game:GetService("CollectionService")
local rs = game:GetService("ReplicatedStorage")
local _math = require(rs.math)
local ragdoll = require(rs.ragdoll)
local Villains = workspace.Villains

local ServerStorage = game:GetService("ServerStorage")

local algorithm = require(script.Parent["Astar"])
local villainProfiles=require(script.VillainProfiles)
local multiverse_Event = rs.Multiverse_Event

local physicsService = game:GetService("PhysicsService")

local ts = game:GetService("TweenService")
local tweeninfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false)

local function setCollisions(villain,collisiongroup)
	for index,part in pairs(villain:GetDescendants()) do 
		if part:IsA("BasePart") then
			part.CollisionGroup=collisiongroup
		end
	end
end

local function setNetworkOwner(villain, networkOwner)
	for _, descendant in pairs(villain:GetDescendants()) do
		-- Go through each part of the model
		if descendant:IsA("BasePart") then
			-- Try to set the network owner
			local success, errorReason = descendant:CanSetNetworkOwnership()
			if success then
				descendant:SetNetworkOwner(networkOwner)
			else
				-- Sometimes this can fail, so throw an error to prevent
				-- ... mixed networkownership in the 'model'
				error(errorReason)
			end
		end
	end
end

local function addModifiers(model,modifierName,passThrough)
	for _,v in pairs(model:GetDescendants()) do 
		if v:IsA("BasePart") then
			local modifier = Instance.new("PathfindingModifier")
			modifier.Label = modifierName
			modifier.PassThrough = passThrough
			modifier.Parent = v 
		end
	end
end

local villain = nil
local villain_number=0
local villain_name=nil
local deathTick = nil
local respawn = 5
local range = 100

local villain_names={
	--"Venom",
	"Green Goblin",
	--"Doc Ock",
}

local function Get_Next_Villain()
	villain_number+=1
	if not villain_names[villain_number] then
		villain_number=1 -- reset
	end
	villain_name=villain_names[villain_number]
	return villain_name
end

local function Create_Villain()
	Get_Next_Villain()
	local tag = game:GetService("HttpService"):GenerateGUID(false)
	local random = math.random(1,#rs.VillainSpawnPoints:GetChildren())
	local spawn_folder = rs.VillainSpawnPoints:FindFirstChild(random)
	local spawn_point=spawn_folder:FindFirstChild("spawn")
	multiverse_Event:FireAllClients(spawn_point.Value) -- open portal for all players
	villain = rs.Villains[villain_name]:Clone()
	cs:AddTag(villain,villain_name)
	villain.Name = tag
	local offset=Vector3.new(0,15,0)
	local lookAt=CFrame.new(spawn_point.Value.Position+offset,workspace.blocks.middle.Position+offset)
	villain:SetPrimaryPartCFrame(lookAt)
	villain.Properties.SpawnPoint.Value = spawn_folder.Name
	villain.BossName.Value=villain_name

	villain.Properties.MaxHealth.Value = villainProfiles[villain_name].health
	villain.Properties.Health.Value = villainProfiles[villain_name].health

	local closest_node=Instance.new("ObjectValue")
	closest_node.Value=nil
	closest_node.Name="ClosestNode"
	closest_node.Parent=villain

	local function clear(dict)
		for i,v in dict do 
			v=nil
			dict[i]=nil
		end
	end

	NPCs[tag] = {
		model = villain,
		agentRadius = 9,
		path = {stagnant=false,waypoints=nil,Destroy=function()end},
		pathIndex=1,
		thread = false,
		attackers = {},
		lastAttacked = workspace:GetServerTimeNow(),
		lastHeal = workspace:GetServerTimeNow(),
		drone = false,
		attacking = {},
		staticChecks = 0,
		target_closest_node=nil,
		lastPosition=nil,
		horizontalRange=100,
		verticalRange=8,
		clear=clear,
		off_ground=0
	}

	villain.Parent = workspace.Villains
	setNetworkOwner(villain)
	setCollisions(villain,villainProfiles[villain_name].collisiongroup)
	addModifiers(villain,"Villains",true)
	villain.Humanoid.BreakJointsOnDeath = false

	local start = tick()
	while tick() - start < 1 do 
		local percent = math.clamp((tick() - start) / 1,0,1)
		local p = 1-percent
		villain.PrimaryPart.BodyVelocity.Velocity = villain.PrimaryPart.CFrame.LookVector * (100*percent)
		task.wait(1/30)
	end
	villain.PrimaryPart.BodyVelocity.MaxForce = Vector3.new(0,0,0) -- turn it off
end

local last_step=nil
local last_pos=nil
local last_target=nil
local function getPlayerTargetOffsetPos(characterPos,villainPos,targetMoving,speed)
	local move_back=villainProfiles[villain_name].move_back
	local offset= villainProfiles[villain_name].offset
	local modifiedPlayerPosition = Vector3.new(characterPos.X,villainPos.Y,characterPos.Z)
	local distance=(modifiedPlayerPosition - villainPos).Magnitude
	local cf=CFrame.new(villainPos)
	
	--[[
	if not last_step or not last_pos then
		last_step=tick()-.25
		last_pos=villainPos
	end
	
	local elapsed=tick()-last_step
	local ignoreY=Vector3.new(1,0,1)
	local distance_covered=((villainPos*ignoreY)-(last_pos*ignoreY)).Magnitude
	
	last_step=tick()
	last_pos=villainPos
	
	local villain_speed=distance_covered*(1/elapsed)
	]]
	
	if distance>offset then -- out of range

		local direction = (villainPos - modifiedPlayerPosition).Unit * 1000000000
		cf = CFrame.new(modifiedPlayerPosition,direction) * CFrame.new(0,0,-offset+speed)
		
	end
	
	--workspace.placementB.CFrame = cf
	return cf.Position,offset
end

local function getCharacterModelsArray()
	local t = {}
	for _,plr in pairs(game.Players:GetPlayers()) do 
		t[#t+1] = plr.Character
	end
	return t
end

local function updateGyro(villain,RunningPath) -- meant to change the rotation movement type for difference circumstances
	if not villain then return end
	local properties = villain.Properties
	local health = properties.Health.Value
	local target = properties.Target
	local gyro = villain.PrimaryPart.BodyGyro
	if target.Value == nil then return end
	if not cs:HasTag(villain,"ragdolled") then
		if target.Value:IsA("BasePart") then
			gyro.MaxTorque = Vector3.new(0,0,0)
		elseif game.Players:GetPlayerFromCharacter(target.Value) then
			gyro.MaxTorque = RunningPath and Vector3.new(0,0,0) or Vector3.new(100000,100000,100000)
			local targetPos = target.Value.PrimaryPart.Position
			local rootPos = villain.PrimaryPart.Position
			local ignoreYTargetPos = Vector3.new(targetPos.X,rootPos.Y,targetPos.Z)
			gyro.CFrame = CFrame.new(rootPos,ignoreYTargetPos)
		end		
	end
end

local mapCF = CFrame.new(Vector3.new(92, 14.5, -170))
local mapSize = Vector3.new(1400, 34, 1260)

local function least(a,b)
	return a[1]<b[1]
end

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

local function Get_Next_Action(actions)
	return Get_Random(actions)
end

local function visualizeHitBox(cframe,size)
	local part = workspace.mover:Clone()
	part.CFrame = cframe
	part.Size = size
	part.Parent = workspace
	game:GetService("Debris"):AddItem(part,1)
end

local function visualizeRay(origin,goal)
	local rayVisual = game.ReplicatedStorage:WaitForChild("rayVisual"):Clone()
	rayVisual.CFrame = CFrame.new(origin:Lerp(goal,.5),goal)
	rayVisual.Size = Vector3.new(0.25,0.25,(origin - goal).Magnitude)
	rayVisual.Transparency = 0.75
	rayVisual.BrickColor = BrickColor.Green()
	rayVisual.Material = Enum.Material.Neon
	rayVisual.Parent = workspace.detectRay
	game:GetService("Debris"):AddItem(rayVisual,.25)
end

local function ray(origin,direction)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {
		workspace.BuildingBounds,
		workspace.Trash,
		workspace.BarrelFire1,
		workspace.PhoneBooths,
		workspace.GaurdRails,
		workspace.crates,
		--workspace.ConstructionSite,
		workspace.Concrete,
		workspace.Sidewalk1,
		workspace.Sidewalk2,
	}
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local function getPartsInBoundingBox(cframe,size)
	local whitelist = {
		workspace.BuildingBounds,
		workspace.Trash,
		workspace.BarrelFire1,
		workspace.PhoneBooths,
		workspace.GaurdRails,
		workspace.crates
	}
	local overlapParams = OverlapParams.new()
	overlapParams.MaxParts = 25
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = whitelist
	overlapParams.BruteForceAllSlow = false

	local partsInBox = workspace:GetPartBoundsInBox(
		cframe,
		size,
		overlapParams
	)

	return partsInBox
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

local function findUnoccupiedPoint(villain)
	local properties = villain.Properties
	local target = properties.Target
	local spawnPointName = properties.SpawnPoint.Value
	local spawn_folder = rs.VillainSpawnPoints:FindFirstChild(spawnPointName)
	local ignore = (target.Value ~= nil and target.Value:IsA("BasePart")) and target.Value.Name or nil 
	local spawn_points = #spawn_folder:GetChildren()
	local function findEligiblePoint()
		local random = math.random(1,spawn_points)
		for i, v in spawn_folder:GetChildren() do 
			if i == random and v.Value.Name~=ignore then
				target.Value = v.Value
				return
			end
		end
		return findEligiblePoint()
	end
	findEligiblePoint()
end

local function Find_Nearest_Node(pos1,pos2,ignore)
	local _node1,d1=nil,math.huge
	local _node2,d2=nil,math.huge
	for i,node in next,workspace.nodes2:GetChildren() do 
		if ignore[node.Name] then continue end
		local m=(node.Position-pos1).Magnitude
		if m<d1 then
			d1=m _node1=node
		end
		if pos2 then
			m=(node.Position-pos2).Magnitude
			if m<d2 then
				d2=m _node2=node
			end
		end
	end
	return _node1,_node2
end

local function Perform_Next_Action(actions)
	local action = Get_Next_Action(actions)
	local f = coroutine.wrap(villainProfiles[villain_name].actionFunctions[action])
	f(villain,workspace:GetServerTimeNow(),villain.Events[action],villain.Properties)
end

local function GetNearestCharacter(fromPosition)
	local character, dist = nil, math.huge
	for _, player in ipairs(game.Players:GetPlayers()) do
		if player.Character and (player.Character.PrimaryPart.Position - fromPosition).Magnitude < dist then
			character, dist = player.Character, (player.Character.PrimaryPart.Position - fromPosition).Magnitude
		end
	end
	return character
end

local villain_cooldown_times={
	["Venom"]=2.5,
	["Green Goblin"]=2.5,
	["Doc Ock"]=3.5
}

local RunningPath = false
local start = tick()
while true do
	--local success,errorMessage = pcall(function()
	if not villain then -- he died, wait respawn time then add him back in
		if not deathTick then deathTick=tick() end	
		if tick() - deathTick > respawn then
			--print("adding villain")
			Create_Villain()
			deathTick=nil
		end
	else
		local listing = NPCs[villain.Name]
		if listing and listing.model.Parent ~= nil then
			--print("made it here0")
			local health = villain.Properties.Health 
			if health.Value > 0 then
				--print("made it here1")
				if cs:HasTag(villain,"ragdolled") then
					--[[
						if listing.path._status == SimplePath.StatusType.Active then
							listing.path:Stop()
						end
						]]
				else 
					if tick() - start >= .25 then
						-- print("running loop")
						start = tick()
						local properties = villain.Properties
						local target = properties.Target
						local humanoid = villain.Humanoid

						local nearestCharacter =GetNearestCharacter(villain.PrimaryPart.Position)
						local canContinue = false
						if nearestCharacter then
							local nearestCharacterModifiedPos = nearestCharacter.PrimaryPart.Position * Vector3.new(1,0,1)
							local venomModifiedPos = villain.PrimaryPart.Position * Vector3.new(1,0,1)

							local characterIsInCity = _math.checkBounds(mapCF,mapSize,nearestCharacter.PrimaryPart.Position)

							if (venomModifiedPos - nearestCharacterModifiedPos).Magnitude <= range and characterIsInCity then
								canContinue = true
								target.Value = nearestCharacter
							end
						end	

						if not nearestCharacter or not canContinue then
							if target.Value == nil or not target.Value:IsA("BasePart") then
								findUnoccupiedPoint(villain)
								properties.moveDelta.Value = tick()
								properties.moveWait.Value = math.random(5,10)
							else 
								if (tick() - properties.moveDelta.Value) >= tonumber(properties.moveWait.Value) then
									findUnoccupiedPoint(villain)
									properties.moveDelta.Value = tick()
									properties.moveWait.Value = math.random(5,10)
								end
							end
						end

						local goal = Vector3.new()
						if target.Value:IsA("BasePart") then
							local pos = target.Value.Position
							goal = Vector3.new(pos.X,villain.PrimaryPart.Position.Y,pos.Z)
						elseif game.Players:GetPlayerFromCharacter(target.Value) then
							if nearestCharacter and nearestCharacter.Parent ~= nil then
								local nearestCharacterModifiedPos = nearestCharacter.PrimaryPart.Position * Vector3.new(1,0,1)
								local venomModifiedPos = villain.PrimaryPart.Position * Vector3.new(1,0,1)

								local pos = nearestCharacter.PrimaryPart.Position
								local targetHumanoid = nearestCharacter.Humanoid
								local targetMoving = targetHumanoid.MoveDirection.Magnitude ~= 0
								local targetSpeed = (nearestCharacter.PrimaryPart.Velocity * Vector3.new(1,0,1)).Magnitude

								goal = getPlayerTargetOffsetPos(nearestCharacterModifiedPos,venomModifiedPos,targetMoving,targetSpeed)
								goal = Vector3.new(goal.X,villain.PrimaryPart.Position.Y,goal.Z)
							else 
								findUnoccupiedPoint(villain)
								properties.moveDelta.Value = tick()
								properties.moveWait.Value = math.random(5,10)	
							end
						end

						local found={}
						found.trashFound=false
						found.barrelFound=false
						found.fenceFound=false
						found.crateFound=false
						found.structureFound=false
						found.miscFound=false
						found.phoneboothFound=false
						found.gaurdrailFound=false

						local origin=villain.PrimaryPart.Position

						local function jump()
							if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
								humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
							end
						end

						local function search_obstructions(array)
							for _,instance in array do 
								--print("instance=",instance)
								if instance:IsDescendantOf(workspace.Trash) and instance.Name=="Garbage" then
									found.trashFound=instance
								end
								if instance:IsDescendantOf(workspace.BarrelFire1) then
									found.barrelFound=instance
								end
								if instance:IsDescendantOf(workspace.PhoneBooths) then
									found.phoneboothFound=instance
								end
								if instance:IsDescendantOf(workspace.GaurdRails) then
									found.gaurdrailFound=instance
								end
								if instance:IsDescendantOf(workspace.crates) then
									found.crateFound=instance
								end
								local structure=(instance:IsDescendantOf(workspace.BuildingBounds) and instance.Name=="Part") or instance.Name=="StreetLamp1"
								if structure then
									found.structureFound=instance
								end
							end
						end

						local ignoreY = Vector3.new(1,0,1)
						if target.Value:IsA("BasePart") then
							humanoid.WalkSpeed = 32
						else
							local distance = ((target.Value.PrimaryPart.Position * ignoreY) - (villain.PrimaryPart.Position * ignoreY)).Magnitude
							local allowedDistance = 8
							humanoid.WalkSpeed = math.clamp(16*((distance*2)/allowedDistance),16,32)					
						end

						local obstructionsFound=nil
						if not target.Value:IsA("BasePart") then -- its a character
							obstructionsFound=getPartsInBoundingBox(CFrame.new(goal),Vector3.new(2,1,2))
							search_obstructions(obstructionsFound)
						end

						local function Get_Jumpable()
							local allowedDistance = 8
							for index,value in found do 
								if not value then continue end
								--print("jumpable found=",index)
								local closestPointOnPart = closestPointOnPart(value,origin)	
								local d=((closestPointOnPart*ignoreY)-(origin*ignoreY)).Magnitude
								if d <= allowedDistance then
									return true
								end
							end
							return false
						end

						if obstructionsFound then -- wouldn't want unintentional functionality w/ non-character targets
							local isInsideObstruction = #obstructionsFound > 0
							if isInsideObstruction and found.structureFound then
								local targetPos = target.Value.PrimaryPart.Position
								goal = Vector3.new(targetPos.X,goal.Y,targetPos.Z)
								local closestPointOnPart = closestPointOnPart(found.structureFound,goal)
								local direction = (closestPointOnPart - goal).Unit * 1000000000
								local goalCF = CFrame.new(goal,direction) * CFrame.new(0,0,4)
								goal = goalCF.Position
							end
						end

						local function Get_Path_Goal()
							if listing.path.waypoints==nil then return {Position=goal,Name="goal"} end
							local path_goal=listing.path.waypoints[math.clamp(listing.pathIndex+1,listing.pathIndex,#listing.path.waypoints)]
							RunningPath=type(path_goal)~="table" --[[and (path_goal.Position-origin).Magnitude<=16]]
							return path_goal
						end

						local path_goal=Get_Path_Goal()
						local lookAt=CFrame.new(origin:Lerp(path_goal.Position,.5),path_goal.Position)
						local size=Vector3.new(villain.PrimaryPart.Size.X,villain.PrimaryPart.Size.Y,(origin-path_goal.Position).Magnitude)
						obstructionsFound=getPartsInBoundingBox(lookAt,size)
						if #obstructionsFound>0 then
							search_obstructions(obstructionsFound)
						end
						--visualizeHitBox(lookAt,size)

						local function castRay(origin: Vector3, goal: Vector3)
							--visualizeRay(origin,goal)
							local d=(goal-origin).Magnitude
							local direction=(goal-origin).Unit*d
							local rayResult=ray(origin,direction)
							if rayResult then
								search_obstructions({rayResult.Instance})
							end
						end

						found.structureFound=false --// turn off so ray can determine
						castRay(origin-Vector3.new(0,2.5,0),goal-Vector3.new(0,2.5,0))

						--workspace.mover.Position=goal

						local jumpable=villainProfiles[villain_name].canJump and Get_Jumpable() or false
						--print("jumpable=",jumpable)
						if jumpable then
							local distance_from_goal=((origin*ignoreY)-(goal*ignoreY)).Magnitude
							local target_pos=target.Value:IsA("BasePart") and target.Value.Position or target.Value.PrimaryPart.Position
							local target_is_higher=target_pos.Y>origin.Y
							if distance_from_goal>8 or target_is_higher then
								jump()
							end
						end

						local function moveTo(goal: {Position: Vector3})
							villain.Humanoid:MoveTo(goal.Position)
							--workspace.visual.Position=goal.Position
						end

						local function createPath(mock: boolean, tentative: boolean, source: string)
							--print("source=",source)
							local ignore={["spawn"]=true}
							local nodeA,nodeB=Find_Nearest_Node(origin,goal,ignore)	
							if mock then
								listing.path.waypoints={
									[1]={Position=origin,Name="start"},
									[2]={Position=goal,Name="goal"}
								}
								listing.pathIndex=1
							else
								local path,dt = algorithm:GeneratePath(nodeA,nodeB,workspace.nodes2,ignore,{total=tick(),runs=0,start=tick()})
								table.insert(path,{Position=goal,Name="goal"})
								if path[2]~=nil and tentative then
									local venom_to_path2=((origin*ignoreY)-(path[2].Position*ignoreY)).Magnitude
									local path1_to_path2=((path[1].Position*ignoreY)-(path[2].Position*ignoreY)).Magnitude
									if venom_to_path2 < path1_to_path2 then
										table.remove(path,1)
									end
								end
								table.insert(path,1,{Position=origin,Name="start"})
								listing.path.waypoints=path
								listing.pathIndex=1
							end
							for i,v in listing.path.waypoints do
								--print(i,"=",v.Name)
							end
						end

						local function runPath()
							if listing.path.waypoints==nil then
								createPath(true,false,"1")
							else
								--// what if the target moved?
								--// you'd need to create a new path to accomodate for that
								local final_path_goal=listing.path.waypoints[#listing.path.waypoints].Position
								local goal_difference=((final_path_goal*ignoreY)-(goal*ignoreY)).Magnitude
								if target.Value:IsA("BasePart") then
									if goal_difference>=1 then
										local mock=not listing.path.stagnant and not found.structureFound
										local tentative=true
										createPath(mock,tentative,"2")
									end
									if listing.path.stagnant then
										createPath(false,false,"3")
									end
								else
									local mock=not listing.path.stagnant and not found.structureFound
									local tentative=not listing.path.stagnant
									createPath(mock,tentative,"4")
								end
								local path_goal=Get_Path_Goal()
								if ((path_goal.Position*ignoreY)-(origin*ignoreY)).Magnitude<=8 then
									listing.pathIndex=math.clamp(listing.pathIndex+1,listing.pathIndex,#listing.path.waypoints)
								end
							end
							local path_goal=Get_Path_Goal()
							moveTo(path_goal)
							--print("fence=",found.fenceFound)
						end
						runPath()

						--// stagnant check
						if not listing.lastPosition then
							listing.lastPosition=origin*ignoreY
						else
							local path_goal=Get_Path_Goal()
							local distance_from_goal=((origin*ignoreY)-(path_goal.Position*ignoreY)).Magnitude	
							local d=((origin*ignoreY)-(listing.lastPosition*ignoreY)).Magnitude
							listing.lastPosition=origin*ignoreY
							if d<4 and distance_from_goal>8 then
								listing.staticChecks+=1
								--print("stagnant")
							else
								listing.staticChecks=0
								listing.path.stagnant=false	
								--print("not stagnant")
							end
							if listing.staticChecks>=2 then
								listing.path.stagnant=true
							end
							--print("stagnant=",listing.path.stagnant)
						end
					end

					local properties = villain.Properties
					local target = villain.Properties.Target
					
					if target:FindFirstChild("Speed") then -- u need to get the target's speed now
						if target.Value and target.Value:IsA("Model") and target.Value.PrimaryPart then
							if not last_pos or target.Value~=last_target then -- reset the last position to this target's position
								last_pos=target.Value.PrimaryPart.Position
							end
							if not last_step then
								last_step=tick()
							end
							local elapsed=tick()-last_step
							local dif=target.Value.PrimaryPart.Position-last_pos
							target.Speed.Value=(1/elapsed)*dif
							last_step=tick()
							last_pos=target.Value.PrimaryPart.Position
							last_target=target.Value
						else
							target.Speed.Value=Vector3.new(0,0,0)
							last_step=nil
							last_pos=nil
							last_target=nil
						end
					end
					
					if properties:FindFirstChild("HoverYOffset") then
						properties.HoverYOffset.Value=math.sin(tick())/2
					end
					
					if game.Players:GetPlayerFromCharacter(target.Value) and not cs:HasTag(villain,"ragdolled") then
						local ignoreY = Vector3.new(1,0,1)
						local distanceFromTarget = ((target.Value.PrimaryPart.Position * ignoreY) - (villain.PrimaryPart.Position * ignoreY)).Magnitude
						if distanceFromTarget <= villainProfiles[villain_name].attack_range then -- needs to be close to attack
							local actionDelta = properties.actionDelta
							if tick() - actionDelta.Value > villain_cooldown_times[villain_name] then
								actionDelta.Value=tick()
								local actions=villainProfiles[villain_name].GetActions(properties)
								Perform_Next_Action(actions)
							end		
						end
					end
				end	

				-- regen health
				local currentTime = workspace:GetServerTimeNow()
				local NPC=NPCs[villain.Name]
				if currentTime - NPC.lastAttacked > 5 then
					if currentTime - NPC.lastHeal > 1 then
						NPC.lastHeal = currentTime
						local properties = villain.Properties
						local health = properties.Health
						local maxHealth = properties.MaxHealth
						local increase = maxHealth.Value/1000
						health.Value = math.clamp(math.round(health.Value + increase),0,maxHealth.Value)
						NPC.totalDamage=NPC.totalDamage~=nil and NPC.totalDamage or 0
						for i,v in NPC.attackers do -- reduce attacker damages
							local damage=math.clamp(v.damage,0,NPC.totalDamage)
							--print("damage=",damage)
							--print("totalDamage=",NPC.totalDamage)
							local subtract=(damage/NPC.totalDamage)*increase
							subtract=subtract==subtract and subtract or 0
							v.damage=math.clamp(v.damage-subtract,0,maxHealth.Value)
							--print("newDamage=",v.damage)
							if v.damage==0 then
								NPC.attackers[i]=nil -- remove the listing at 0
							end
						end
						NPC.totalDamage=math.clamp(NPC.totalDamage-increase,0,maxHealth.Value)
					end
				end	 
			else
				if deathTick==nil then
					villainProfiles[villain_name].death(villain)
					deathTick = tick()
					spawn(function()
						task.wait(respawn)
						villain = nil
					end)
				end	
			end
		end	
	end
	local foundVillain=workspace.Villains:FindFirstChildOfClass("Model")

	updateGyro(foundVillain,RunningPath)
	--end)
	task.wait(1/30)
end