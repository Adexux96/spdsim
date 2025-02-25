local NPCs=require(script.Parent.Parent.NPCs)
local villainProfiles= {}

local rs=game:GetService("ReplicatedStorage")
local cs=game:GetService("CollectionService")
local debris=game:GetService("Debris")
local ragdoll=require(rs.ragdoll)
local rewards=require(game:GetService("ServerScriptService").Rewards)

local function notify_spidey_sense(model)
	local target=model.Properties.Target
	if target.Value then
		local player=game.Players:GetPlayerFromCharacter(target.Value)
		if player then
			rs:WaitForChild("SpideySense"):FireAllClients(player)
		end
	end
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

local function getPartsInBoundingBox(cframe,size)
	local whitelist = {
		workspace.BuildingBounds,
		workspace.BarrelFire1,
		workspace.Trash,
		--workspace.ConstructionSite,
		workspace.StreetLamp
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

local function getAttackablesInArea(villain,pos)
	local t = {}
	local ignoreY = Vector3.new(1,0,1)
	for _,player in pairs(game.Players:GetPlayers()) do 
		local character = player.Character
		if character and character.Parent == workspace and character.PrimaryPart then
			local distance = ((pos*ignoreY) - (character.PrimaryPart.Position*ignoreY)).Magnitude 
			local yDifference = math.abs(pos.Y - character.PrimaryPart.Position.Y)
			if distance <= 10 and yDifference < 4 then
				t[#t+1] = character
			end
		end
	end
	for _,drone in pairs(workspace.SpiderDrones:GetChildren()) do 
		local distance = ((villain.PrimaryPart.Position*ignoreY) - (drone.PrimaryPart.Position*ignoreY)).Magnitude
		local yDifference = math.abs(pos.Y - drone.PrimaryPart.Position.Y)
		if distance <= 10 and yDifference < 4 then
			t[#t+1] = drone
		end
	end
	return t
end

local function getCharacterModelsArray()
	local t = {}
	for _,plr in pairs(game.Players:GetPlayers()) do 
		t[#t+1] = plr.Character
	end
	return t
end

local function getPartsInBoundingBoxForAttackables(cframe,size)
	local array = getCharacterModelsArray()
	local whitelist = {
		workspace.SpiderDrones
	}
	for _,value in pairs(whitelist) do 
		array[#array+1] = value
	end
	local overlapParams = OverlapParams.new()
	overlapParams.MaxParts = 25
	--overlapParams.CollisionGroup = "Characters"
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = array
	overlapParams.BruteForceAllSlow = false

	local partsInBox = workspace:GetPartBoundsInBox(
		cframe,
		size,
		overlapParams
	)

	return partsInBox
end

local function addDamageIndicator(folder,name,part)
	local listing = folder:FindFirstChild(name)
	if listing then return end
	--rs.SpideySense:FireAllClients(folder.Parent.Parent)
	local objectValue = Instance.new("ObjectValue")
	objectValue.Name = name
	objectValue.Value = part 
	objectValue.Parent = folder
	game:GetService("Debris"):AddItem(objectValue,3)
end

local function addAttackerValue(folder,name)
	local listing = folder:FindFirstChild(name)
	if listing then
		-- update timestamp for last attacked
		listing.Value = workspace:GetServerTimeNow()
	else 
		local value = Instance.new("StringValue")
		value.Name = name
		value.Value = workspace:GetServerTimeNow()
		value.Parent = folder
	end
end

local function ray(origin,direction,whitelist)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = whitelist
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local function Get_Attackables_Array()
	local array = getCharacterModelsArray()
	local whitelist = {
		workspace.SpiderDrones
	}
	for _,value in pairs(whitelist) do 
		array[#array+1] = value
	end
	return array
end

local bounds={
	["BuildingBounds"]=true,
	["blocks"]=true,
	["Concrete"]=true,
	["BarrelFire1"]=true,
	["GaurdRails"]=true,
	["Trash"]=true,
	["crates"]=true,
	["PhoneBooths"]=true,
	["Sidewalk1"]=true,
	["Sidewalk2"]=true
}

local function Get_Bounds_Whitelist()
	return {
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
end

local function Get_Full_Ray_Whitelist()
	local array=Get_Attackables_Array()
	local whitelist=Get_Bounds_Whitelist()
	for _,value in pairs(whitelist) do 
		array[#array+1] = value
	end
	return array
end

local function visualizeRay(origin,goal)
	local rayVisual = game.ReplicatedStorage:WaitForChild("rayVisual"):Clone()
	rayVisual.CFrame = CFrame.new(origin:Lerp(goal,.5),goal)
	rayVisual.Size = Vector3.new(0.25,0.25,(origin - goal).Magnitude)
	rayVisual.Transparency = 0.75
	rayVisual.BrickColor = BrickColor.Green()
	rayVisual.Material = Enum.Material.Neon
	rayVisual.Parent = workspace.detectRay
	game:GetService("Debris"):AddItem(rayVisual,5)
end

local function Drone_Damage(villain,drone,damage)
	local health = drone.Properties.Health
	local maxHealth = drone.Properties.MaxHealth
	local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
	health.Value = newHealth -- deal damage to drone

	local owner = game.Players:FindFirstChild(drone.Name)
	if owner then
		addAttackerValue(owner.leaderstats.attackers,villain.Name)
		addDamageIndicator(owner.leaderstats.indicators,villain.Name,villain.PrimaryPart)	
	end

	local function killDrone()
		if health.Value>0 or cs:HasTag(drone,"Died") then return end
		cs:AddTag(drone,"Died")
		local index=drone.Properties.Tag.Value
		local listing = NPCs[index]
		if listing and listing.model and listing.model:IsDescendantOf(workspace) and listing.model.PrimaryPart then
			-- reward players who damaged drone
			local cashAdd = math.round(50*(listing.model.Properties.MaxHealth.Value/100))
			for i,v in pairs(listing.attackers) do 
				local plr = v.plr
				if plr:IsDescendantOf(game.Players) then
					if plr:IsDescendantOf(game.Players) then
						local totalDamage=listing.totalDamage
						totalDamage=totalDamage or 0
						local damage=math.clamp(v.damage.Value,0,totalDamage)
						if damage==0 then continue end -- don't try to reward if the damage is 0
						local reward=math.ceil(math.clamp(damage/totalDamage,0,1) * cashAdd)
						rewards:RewardPlayer(plr,"Money",reward)
					end
				end
			end
			task.wait(3)
			if listing.model~=nil then listing.model:Destroy() end
			NPCs[index].clear(NPCs[index])
			NPCs[index]=nil
		end							
	end

	local f = coroutine.wrap(killDrone)
	f()
end

local function Player_Damage(player,humanoid,villain,damage)
	local leaderstats = player:WaitForChild("leaderstats")
	local temp = leaderstats:WaitForChild("temp")
	local isRolling = temp:WaitForChild("isRolling")
	if isRolling.Value then return "isRolling" end
	humanoid:TakeDamage(damage)
	local model=villain
	addDamageIndicator(player.leaderstats.indicators,model.Name,model.PrimaryPart)
	addAttackerValue(player.leaderstats.attackers,model.Name)
	NPCs[model.Name].attacking[player] = true -- add it to a list you can read from
	if not (humanoid.Health > 0) then
		cs:AddTag(humanoid.Parent,"Died")
	end
	return false
end

local function Projectile_Damage(isDrone,player,humanoid,villain,hit,damage)
	--print("player",player)
	--print("villain=",villain)
	if isDrone then
		Drone_Damage(villain,hit.Parent,damage)
	end
	if player then
		Player_Damage(player,humanoid,villain,damage)
	end
end

local function Check_Attack_Eligibility(villain)
	if not villain then return false end
	if cs:HasTag(villain,"ragdolled") then return false end
	if not villain.Properties then return false end
	local properties=villain.Properties
	if not properties.Target.Value or not properties.Target.Value:IsA("Model") then return false end
	if not properties.Target.Value.PrimaryPart then return false end
	return true
end

local function Get_Start_And_Goal(villain,properties,speed,distance,offset)
	local start=villain.PrimaryPart.CFrame
	start=offset and start*offset or start
	if properties:FindFirstChild("HoverYOffset") then
		start=start*CFrame.new(0,properties.HoverYOffset.Value,0)
	end
	local goal=CFrame.new(properties.Target.Value.PrimaryPart.Position)

	local air_time = (start.Position - goal.Position).Magnitude / speed
	local nextPosition = goal.Position + ((properties.Target.Speed.Value*2) * air_time)
	
	start=CFrame.new(start.Position,nextPosition)
	goal=start*CFrame.new(0,0,-100)

	--local speed=100
	--local distance=100
	local duration=distance/speed
	return start,goal,duration
end

local function check_players_in_radius(pos,range)
	local players={}
	for i,player in game.Players:GetPlayers() do 
		if player.Character and player.Character.PrimaryPart then
			local distance=(player.Character.PrimaryPart.Position-pos).Magnitude
			if distance<=range then -- player is within damage range
				players[#players+1]={player,distance}
			end
		end
	end
	return players
end

local function check_drones_in_radius(pos,range)
	local drones={}
	for i,drone in workspace.SpiderDrones:GetChildren() do 
		if drone.PrimaryPart then
			local distance=(drone.PrimaryPart.Position-pos).Magnitude
			if distance<=range then -- drone is within damage range
				drones[#drones+1]={drone,distance}
			end
		end
	end
	return drones
end

local function least(a,b)
	return a[2]<b[2]
end

villainProfiles["Venom"]={
	health=50000,
	canJump=true,
	collisiongroup="Villains",
	attack_range=12,
	offset=8,
	move_back=true,

	GetActions=function(properties)
		local actions=nil
		actions = {
			[1] = {10,"Roar"},
			[2] = {20,"Smash"},
			-- add tentacle grab here later with a 30% chance
			[3] = {70,"Attack"},
		}

		if properties.Roar.Value then -- roar is already activated, don't redo it for like 20 seconds
			actions = {
				[1] = {20,"Smash"},
				[2] = {80,"Attack"},
			}
		end
		return actions
	end,

	smash=function(villain,pos)
		local damage = 100
		local duration = 3

		local properties=villain.Properties
		damage*=properties.Roar.Value and 2 or 1
		local target = properties.Target
		if target.Value:IsA("BasePart") then return end

		local attackables = getAttackablesInArea(villain,pos)

		for _,attackable in pairs(attackables) do 
			local humanoid = attackable:FindFirstChild("Humanoid")
			local drone = attackable:FindFirstChild("Drone")
			if humanoid then
				local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
				if player then
					local leaderstats = player:WaitForChild("leaderstats")
					local temp = leaderstats:WaitForChild("temp")
					local isRolling = temp:WaitForChild("isRolling")
					if isRolling.Value == true then return end
					local lastRespawn=player:GetAttribute("LastRespawn")
					if lastRespawn and tick()-lastRespawn<3 then print("Venom attacked player too soon!") return end
					humanoid:TakeDamage(damage)
					addDamageIndicator(player.leaderstats.indicators,villain.Name,villain.PrimaryPart)
					addAttackerValue(player.leaderstats.attackers,villain.Name)
					NPCs[villain.Name].attacking[player] = true -- add it to a list you can read from

					if not (humanoid.Health > 0) then
						cs:AddTag(humanoid.Parent,"Died")
					end

					local f=coroutine.wrap(ragdoll.ragdoll)
					f(player,humanoid.Parent,duration,"recover")
				end

			end

			if drone then
				drone = drone.Parent
				local health = drone.Properties.Health
				local maxHealth = drone.Properties.MaxHealth
				local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
				health.Value = newHealth -- deal damage to drone

				local owner = game.Players:FindFirstChild(drone.Name)
				if owner then
					addAttackerValue(owner.leaderstats.attackers,villain.Name)
					addDamageIndicator(owner.leaderstats.indicators,villain.Name,villain.PrimaryPart)	
				end

				local success,errorMessage = pcall(function()
					if not (health.Value > 0) and not cs:HasTag(drone,"Died") then
						cs:AddTag(drone,"Died")
						local tag=drone.Properties.Tag.Value
						local listing = NPCs[tag]
						if listing and listing.model and listing.model:IsDescendantOf(workspace) and listing.model.PrimaryPart then
							-- reward players who damaged drone
							local cashAdd = math.round(50*(listing.model.Properties.MaxHealth.Value/100))
							for i,v in pairs(listing.attackers) do 
								local plr = v.plr
								if plr:IsDescendantOf(game.Players) then
									local cash = plr.leaderstats.Cash
									cash.Value += math.round(math.clamp(v.damage/maxHealth.Value,0,1) * cashAdd)
								end
							end
							wait(3)
							if listing and listing.model then
								listing.model:Destroy()
							end
							if NPCs[tag] then
								NPCs[tag].clear(NPCs[tag])
							end	
						end
					end								
				end)

				if errorMessage then
					--print(errorMessage)
				end

			end
		end
	end,

	attack=function(villain)
		local damage = 50
		local properties = villain.Properties
		damage*=properties.Roar.Value and 2 or 1
		local target = properties.Target
		if not Check_Attack_Eligibility(villain) then return end
		local targetPos = target.Value.PrimaryPart.Position
		local origin = villain.PrimaryPart.Position
		local size = Vector3.new(9,10,12)
		local cframe = CFrame.new(origin,targetPos) * CFrame.new(0,0,-size.Z/2)
		--visualizeHitBox(cframe,size)
		local parts = getPartsInBoundingBoxForAttackables(cframe,size)
		local humanoids = {}
		local drones = {}

		for _,part in pairs(parts) do
			if not part:IsDescendantOf(game) then continue end
			local humanoid = part.Parent:FindFirstChild("Humanoid") or part.Parent.Parent:FindFirstChild("Humanoid")
			local drone = part.Parent:FindFirstChild("Drone") or part.Parent.Parent:FindFirstChild("Drone")
			if humanoid and humanoids[humanoid.Parent.Name] == nil then
				humanoids[humanoid.Parent.Name] = true
				local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
				if player then
					local leaderstats = player:WaitForChild("leaderstats")
					local temp = leaderstats:WaitForChild("temp")
					local isRolling = temp:WaitForChild("isRolling")
					if isRolling.Value == true then return end
					local lastRespawn=player:GetAttribute("LastRespawn")
					if lastRespawn and tick()-lastRespawn<3 then print("Venom attacked player too soon!") return end
					humanoid:TakeDamage(damage)
					addDamageIndicator(player.leaderstats.indicators,villain.Name,villain.PrimaryPart)
					addAttackerValue(player.leaderstats.attackers,villain.Name)
					NPCs[villain.Name].attacking[player] = true -- add it to a list you can read from
				end
				if not (humanoid.Health > 0) then
					cs:AddTag(humanoid.Parent,"Died")
				end
			end

			if drone and drones[drone.Parent.Name] == nil then
				drones[drone.Parent.Name] = true
				drone = drone.Parent
				local health = drone.Properties.Health
				local maxHealth = drone.Properties.MaxHealth
				local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
				health.Value = newHealth -- deal damage to drone

				local owner = game.Players:FindFirstChild(drone.Name)
				if owner then
					addAttackerValue(owner.leaderstats.attackers,villain.Name)
					addDamageIndicator(owner.leaderstats.indicators,villain.Name,villain.PrimaryPart)	
				end

				if not (health.Value > 0) and not cs:HasTag(drone,"Died") then
					cs:AddTag(drone,"Died")
					local tag=drone.Properties.Tag.Value
					local listing = NPCs[tag]
					if listing and listing.model and listing.model:IsDescendantOf(workspace) and listing.model.PrimaryPart then
						-- reward players who damaged drone
						local cashAdd = math.round(50*(listing.model.Properties.MaxHealth.Value/100))
						for i,v in pairs(listing.attackers) do 
							local plr = v.plr
							if plr:IsDescendantOf(game.Players) then
								local cash = plr.leaderstats.Cash
								cash.Value += math.round(math.clamp(v.damage/maxHealth.Value,0,1) * cashAdd)
							end
						end
						task.wait(3)
						if listing and listing.model then
							listing.model:Destroy()
						end
						if NPCs[tag] then
							NPCs[tag].clear(NPCs[tag])
						end
					end
				end	

			end
		end
	end,

	death=function(villain) -- turn certain things off when venom dies
		villain.Properties.Roar.Value=false -- just turn the roar off when venom dies
	end,

	actionFunctions = {
		["Attack"] = function(villain,timer,event)
			if not Check_Attack_Eligibility(villain) then return end
			event:FireAllClients(timer)
			notify_spidey_sense(villain)
			while workspace:GetServerTimeNow() - timer < .5 do 
				task.wait(1/30)
			end
			if not Check_Attack_Eligibility(villain) then return end
			local animationSpeed = .75
			local animationDuration = 42/60 -- frames
			local realDuration = animationDuration * animationSpeed
			local hit1 = (.15/.42) * realDuration
			local hit2 = (.33/.42) * realDuration
			task.wait(hit1)
			if not Check_Attack_Eligibility(villain) then return end
			villainProfiles["Venom"].attack(villain)
			task.wait(hit2)
			if not Check_Attack_Eligibility(villain) then return end
			villainProfiles["Venom"].attack(villain)
		end,
		["Smash"] = function(villain,timer,event)
			if not Check_Attack_Eligibility(villain) then return end
			event:FireAllClients(timer)
			notify_spidey_sense(villain)
			while workspace:GetServerTimeNow() - timer < .5 do 
				task.wait(1/30)
			end
			if not Check_Attack_Eligibility(villain) then return end
			local animationSpeed = 1
			local animationDuration = 60/60
			local realDuration = animationDuration * animationSpeed
			local hit = (.51/.6) * realDuration
			task.wait(hit)
			if not Check_Attack_Eligibility(villain) then return end
			local origin = villain.PrimaryPart.Position
			local goalCF = villain.PrimaryPart.CFrame * CFrame.new(0,-100,0)
			local direction = (goalCF.Position - origin).Unit * 100
			local result = ray(origin,direction,Get_Bounds_Whitelist())
			if result then
				villainProfiles["Venom"].smash(villain,result.Position)
			end
		end,
		["Roar"] = function(villain,timer,event,properties)
			if not Check_Attack_Eligibility(villain) then return end
			local roar=properties.Roar
			event:FireAllClients(timer)
			task.wait(.5) -- give it some time
			roar.Value=true
			task.delay(20,function() -- wait 20 seconds in a separate thread and turn it off cuz you can't have it universal in the main handler
				roar.Value=false
			end)
		end,
	}
}

villainProfiles["Green Goblin"]={
	health=50000,
	canJump=false,
	collisiongroup="FlyingVillains",
	attack_range=36,
	offset=24,
	move_back=false,

	death=function()
		--print("green goblin has died!")
	end,
	
	GetDamages=function(move)
		local moves={
			["Gas"]=50,
			["Bomb"]=100,
			["Gun"]=50,
			["Razor"]=100
		}
		return moves[move]
	end,
	
	GetActions=function(properties)
		local actions=nil
		local lastGas=properties.lastGas
		if lastGas.Value=="" then
			properties.lastGas.Value=tick()-10
		end
		if tick()-lastGas.Value<10 then -- don't let gas attacks stack
			actions={
				{15,"Bomb"},
				{35,"Gun"},
				{50,"Razor"},
			}
		else
			actions={
				{15,"Bomb"},
				{20,"Gas"},
				{25,"Gun"},
				{40,"Razor"},
			}
		end

		return actions
	end,

	projectile=function(start,goal,duration,name,projectile,timer,whitelist,destroy,villain)
		local last_pos=start.Position
		local i=0
		local actual_name=name
		name=(name=="Gas" or name=="Bomb") and "Bomb" or name
		name=name=="Gun" and "Bullet" or name
		local damage=villainProfiles["Green Goblin"].GetDamages(actual_name)
		local send=nil
		while true do
			i+=1
			local p=math.clamp((tick()-timer)/duration,0,1)
			if projectile:IsA("Model") then
				--print(name,"projectile")
				projectile:SetPrimaryPartCFrame(start:Lerp(goal,p))
			else
				projectile.CFrame=start:Lerp(goal,p)
			end
			if name=="Razor" then
				projectile[name].CFrame*=CFrame.Angles(0,math.rad(24),0)
			end
			if name=="Bomb" then
				local direction=(projectile[name].Position-goal.Position).Unit*1000000
				projectile[name].CFrame=CFrame.new(projectile[name].Position,direction)
			end
			if i%3==0 then -- check ray
				local current_pos=nil
				if projectile:IsA("Model") then
					current_pos=projectile.PrimaryPart.Position
				else
					current_pos=projectile.Position
				end
				local result=ray(last_pos,(current_pos-last_pos).Unit*(last_pos-current_pos).Magnitude,whitelist)
				if result then
					--print("projectile hit",result.Instance.Name)
					--print("child of",result.Instance.Parent.Name)
					--visualizeRay(last_pos,current_pos)
					if name=="Razor" or name=="Bullet" then -- only do this for razor not bomb
						local wasBounds=false
						for name,_ in bounds do 
							if result.Instance:IsDescendantOf(workspace:WaitForChild(name)) then
								wasBounds=true
								break
							end
						end
						if wasBounds then
							local attachment = rs:WaitForChild("hitImpact"):WaitForChild("Attachment"):Clone()
							attachment.Name = "impact"
							attachment.CFrame = CFrame.new(result.Position,last_pos)
							attachment.Parent = workspace.Terrain
							game:GetService("Debris"):AddItem(attachment,2)
						end
						local drone=result.Instance:IsDescendantOf(workspace.SpiderDrones) and true or false
						local humanoid=result.Instance.Parent:FindFirstChild("Humanoid") or result.Instance.Parent.Parent:FindFirstChild("Humanoid")
						local player=humanoid and game.Players:GetPlayerFromCharacter(humanoid.Parent) or false
						Projectile_Damage(drone,player,humanoid,villain,result.Instance,damage)
						if name=="Razor" then
							projectile[name].Transparency=1
						end
					elseif name=="Bomb" then
						local z=projectile:IsA("Model") and projectile[name].Size.Z/2 or projectile.Size.Z
						local cf = CFrame.new(result.Position, result.Position - result.Normal) * CFrame.new(0,0,z)
						local up=CFrame.new(cf.Position)
						if projectile:IsA("Model") then
							projectile:SetPrimaryPartCFrame(up)
							projectile[name].CFrame=CFrame.new(up.Position)*CFrame.Angles(math.rad(-90),0,0)
						else 
							projectile.CFrame=up
						end
						send=result.Position
					end
					debris:AddItem(projectile,destroy)
					send=send or "return"
				end
				last_pos=current_pos -- update the last position
			end
			if p==1 then
				projectile:Destroy()
				break
			end
			if send~=nil then 
				return send
			end
			task.wait()
		end
	end,
	
	throw=function()
		local speed=2
		local duration=3
		local event=78/180
		task.wait(event*(duration/speed))
	end,
	
	actionFunctions={
		["Gun"]=function(villain,timer,event,properties)
			if not Check_Attack_Eligibility(villain) then return end
			event:FireAllClients(timer)
			notify_spidey_sense(villain)
			while workspace:GetServerTimeNow() - timer < .5 do 
				task.wait(1/30)
			end
			if not Check_Attack_Eligibility(villain) then return end

			local muzzles={
				[0]={
					[0]=properties.MuzzleOffsets.LeftUpper,
					[1]=properties.MuzzleOffsets.LeftLower
				},
				[1]={
					[0]=properties.MuzzleOffsets.RightUpper,
					[1]=properties.MuzzleOffsets.RightLower
				}
			}

			local speed=150
			local distance=100
			local duration=distance/speed

			local last_offsets={}

			--local whitelist=name=="Razor" and Get_Full_Ray_Whitelist() or Get_Bounds_Whitelist()

			for i=1,6 do
				
				local side=muzzles[i%2]
				local offset=last_offsets[i%2]==0 and 1 or 0
				last_offsets[i%2]=offset
				
				local start,goal,duration=Get_Start_And_Goal(villain,properties,150,100,side[offset].Value)
				
				event:FireAllClients(workspace:GetServerTimeNow(),"MuzzleFlash",start.Position)
				
				local f=coroutine.wrap(villainProfiles["Green Goblin"].projectile)
				
				local projectile=rs.Particles.FX_Bullet_Trail:Clone()
				projectile.CFrame=start
				projectile.Parent=workspace.Bullets
				
				f(start,goal,duration,"Gun",projectile,tick(),Get_Full_Ray_Whitelist(),1,villain)
				
				task.wait(.2)
				
				if not Check_Attack_Eligibility(villain) then break end
			end

		end,
		
		["Gas"]=function(villain,timer,event,properties)
			if not Check_Attack_Eligibility(villain) then return end
			event:FireAllClients(timer)
			notify_spidey_sense(villain)
			while workspace:GetServerTimeNow() - timer < .5 do 
				task.wait()
			end
			if not Check_Attack_Eligibility(villain) then return end

			local start,goal,duration=Get_Start_And_Goal(villain,properties,100,100,properties.ProjectileOffset.Value)

			villainProfiles["Green Goblin"].throw()
			local projectile=rs.GoblinProjectile:Clone()
			projectile.PrimaryPart.PointLight.Enabled=true
			projectile.Bomb.Transparency=0
			projectile:SetPrimaryPartCFrame(start)
			projectile.Parent=workspace.Bullets
			local pos=villainProfiles["Green Goblin"].projectile(start,goal,duration,"Gas",projectile,tick(),Get_Bounds_Whitelist(),10,villain)
			--print("gas pos=",pos)
			if pos and Check_Attack_Eligibility(villain) then
				properties.lastGas.Value=tick()
				event:FireAllClients(workspace:GetServerTimeNow(),"Explode",projectile)
				while true do
					if not Check_Attack_Eligibility(villain) then break end
					if tick()-properties.lastGas.Value>=10 then break end
					local players=game.Players
					for _,player in players:GetPlayers() do 
						local character=player.Character
						if not character or not character.PrimaryPart or not character.Humanoid then continue end
						local humanoid=character.Humanoid
						local ignoreY=Vector3.new(1,0,1)
						local xDistance=((character.PrimaryPart.Position*ignoreY)-(pos*ignoreY)).Magnitude
						local yDistance=math.abs(character.PrimaryPart.Position.Y-pos.Y)
						if xDistance<=25 and yDistance<10 then
							--print("damaging gas")
							local leaderstats = player:WaitForChild("leaderstats")
							local temp = leaderstats:WaitForChild("temp")
							local isRolling = temp:WaitForChild("isRolling")
							if isRolling.Value then continue end
							humanoid:TakeDamage(villainProfiles["Green Goblin"].GetDamages("Gas"))
							local model=villain
							addDamageIndicator(player.leaderstats.indicators,model.Name,model.PrimaryPart)
							addAttackerValue(player.leaderstats.attackers,model.Name)
							NPCs[model.Name].attacking[player] = true -- add it to a list you can read from
							if not (humanoid.Health > 0) then
								cs:AddTag(humanoid.Parent,"Died")
							end
						end
					end
					task.wait(1)
				end
			end
		end,
		["Bomb"]=function(villain,timer,event,properties)
			if not Check_Attack_Eligibility(villain) then return end
			event:FireAllClients(timer)
			notify_spidey_sense(villain)
			while workspace:GetServerTimeNow() - timer < .5 do 
				task.wait()
			end
			if not Check_Attack_Eligibility(villain) then return end

			local start,goal,duration=Get_Start_And_Goal(villain,properties,100,100,properties.ProjectileOffset.Value)

			villainProfiles["Green Goblin"].throw()
			local projectile=rs.GoblinProjectile:Clone()
			projectile.PrimaryPart.PointLight.Enabled=true
			projectile.Bomb.Transparency=0
			projectile:SetPrimaryPartCFrame(start)
			projectile.Parent=workspace.Bullets
			local pos=villainProfiles["Green Goblin"].projectile(start,goal,duration,"Bomb",projectile,tick(),Get_Bounds_Whitelist(),3,villain)
			if pos and Check_Attack_Eligibility(villain) then
				properties.lastGas.Value=tick()
				event:FireAllClients(workspace:GetServerTimeNow(),"Explode",projectile)
				local damage=villainProfiles["Green Goblin"].GetDamages("Bomb")
				local players=game.Players
				-- players
				local range=50 
				for _,player in players:GetPlayers() do 
					local character=player.Character
					if not character or not character.PrimaryPart or not character.Humanoid then continue end
					local humanoid=character.Humanoid
					local distance=(character.PrimaryPart.Position-pos).Magnitude
					if distance<=range then
						local actual_damage=math.clamp((range-distance)/range,0,1)*damage
						local isRolling=Player_Damage(player,humanoid,villain,actual_damage)
						if not isRolling then
							local f = coroutine.wrap(ragdoll.ragdoll)
							f(player,character,3,"recover")
						end
					end
				end
				-- drones
				for _,drone in workspace.SpiderDrones:GetChildren() do 
					local distance=(drone.PrimaryPart.Position-pos).Magnitude
					if distance<=range then
						local actual_damage=math.clamp((range-distance)/range,0,1)*damage
						Drone_Damage(villain,drone,actual_damage)
					end
				end
			end
		end,
		["Razor"]=function(villain,timer,event,properties)
			if not Check_Attack_Eligibility(villain) then return end
			event:FireAllClients(timer)
			notify_spidey_sense(villain)
			while workspace:GetServerTimeNow() - timer < .5 do 
				task.wait()
			end
			if not Check_Attack_Eligibility(villain) then return end

			local start,goal,duration=Get_Start_And_Goal(villain,properties,100,100,properties.ProjectileOffset.Value)

			villainProfiles["Green Goblin"].throw()
			
			local projectile=rs.GoblinProjectile:Clone()
			--projectile.PrimaryPart.PointLight.Enabled=true
			projectile.Razor.Transparency=0
			projectile:SetPrimaryPartCFrame(start)
			projectile.Parent=workspace.Bullets
			villainProfiles["Green Goblin"].projectile(start,goal,duration,"Razor",projectile,tick(),Get_Full_Ray_Whitelist(),1,villain)
		end,
	}

}

villainProfiles["Doc Ock"]={
	health=50000,
	canJump=false,
	collisiongroup="FlyingVillains",
	attack_range=15,
	offset=10,
	move_back=false,
	lastGrab="Left",
	
	death=function(villain)
	end,
	
	attack=function(villain,attack,...)
		local properties=villain.Properties
		local offsets=properties.MovesOffsets
		local UpperTorsoOffset=properties.UpperTorsoOffset.Value
		local target=properties.Target
		if not target.Value then return end
		if target.Value:IsDescendantOf(workspace.nodes2) then return end
		if not target.Value.PrimaryPart then return end
		local TargetPos=target.Value.PrimaryPart.Position
		if attack=="Hooks" then
			local hookType={...}
			hookType=hookType[1]
			local offset=offsets[attack][hookType]
			local size=offset.Hitbox.Value
			local start=villain.PrimaryPart.CFrame*UpperTorsoOffset
			local goal=TargetPos
			
			local direction = (start.Position - target.Value.PrimaryPart.Position).Unit * 100
			local rotationCF=start*CFrame.Angles(-math.rad(direction.Y)*.525,0,0)
			
			local pos=(rotationCF*offset.Value).Position
			local players=check_players_in_radius(pos,25)
			local drones=check_drones_in_radius(pos,25)
			
			for _,listing in players do 
				Player_Damage(listing[1],listing[1].Character.Humanoid,villain,100)
			end
			
			for _,listing in drones do 
				Drone_Damage(villain,listing[1],100)
			end
			--[[
			local new=Instance.new("Part")
			new.Shape=Enum.PartType.Ball
			new.Anchored=true
			new.CanCollide=false
			new.CanQuery=false
			new.CanTouch=false
			new.BrickColor=BrickColor.Red()
			--local x,y,z=CFrame.new(start.Position,goal):ToOrientation()
			--new.CFrame=CFrame.new((start*offset.Value).Position)*CFrame.fromOrientation(x,y,z)
			new.CFrame=rotationCF*offset.Value
			new.Size=Vector3.new(25,25,25)
			new.Transparency=.75
			new.Parent=workspace
			game:GetService("Debris"):AddItem(new,2)
			]]
			
		end
		if attack=="Barrage" then
			local offset=offsets[attack].Offset
			local size=offset.Hitbox.Value
			local start=villain.PrimaryPart.CFrame*UpperTorsoOffset
			local direction = (start.Position - TargetPos).Unit * 100
			local rotationCF=start*CFrame.Angles(-math.rad(direction.Y)*.525,0,0)
			local goal=rotationCF*offset.Value
			
			local players=check_players_in_radius(goal.Position,25)
			local drones=check_drones_in_radius(goal.Position,25)

			for _,listing in players do 
				Player_Damage(listing[1],listing[1].Character.Humanoid,villain,50)
			end

			for _,listing in drones do 
				Drone_Damage(villain,listing[1],25)
			end
			
			--[[
			local new=Instance.new("Part")
			new.Shape=Enum.PartType.Ball
			new.Anchored=true
			new.CanCollide=false
			new.CanQuery=false
			new.CanTouch=false
			new.BrickColor=BrickColor.Red()
			new.CFrame=goal
			new.Size=Vector3.new(25,25,25)
			new.Transparency=.75
			new.Parent=workspace
			game:GetService("Debris"):AddItem(new,2)
			]]
			
		end
		if attack=="Grab" then
			local offset=offsets[attack].Offset
			local start=villain.PrimaryPart.CFrame*UpperTorsoOffset
			local direction = (start.Position - TargetPos).Unit * 100
			local rotationCF=start*CFrame.Angles(-math.rad(direction.Y)*.525,0,0)
			local goal=rotationCF*offset.Value

			local players=check_players_in_radius(goal.Position,15)
			table.sort(players,least)
			
			local closest=players[1]
			closest=closest and closest[1] or nil
			
			if not closest then return end
			local isRolling=Player_Damage(closest,closest.Character.Humanoid,villain,50)
			
			if isRolling then return end
			
			local args={...}
			local timer=args[1]
			
			for _,remote in villain.Events:GetChildren() do
				if remote.Name=="Tentacle" and remote:GetAttribute("player")==closest.Name then -- old one
					remote:Destroy()
				end
			end
			
			local remote=Instance.new("RemoteEvent")
			remote.Name="Tentacle"
			remote:SetAttribute("player",closest.Name)
			remote:SetAttribute("timer",timer)
			remote.Parent=villain.Events
			
			local TentacleCFrame=nil
			local isThrowing=false
			remote.OnServerEvent:Connect(function(plr,newCF,throwing)
				if plr~=closest then return end -- don't accept this request
				local sanity=(newCF.Position-villain.PrimaryPart.Position).Magnitude<50
				if not sanity then return end -- don't accept crazy CFrame requests
				TentacleCFrame=newCF
				isThrowing=throwing
			end)
			
			--// Ragdoll the player
			local f=coroutine.wrap(ragdoll.ragdoll)
			f(closest,closest.Character,5,"recover")
			
			local gyro
			local bodyPos
			local velocity
			
			local function generate_movers(parent)
				gyro=Instance.new("BodyGyro")
				gyro.D=100
				gyro.P=100000
				gyro.MaxTorque=Vector3.new(1000000,1000000,1000000)
				gyro.Parent=parent
				bodyPos=Instance.new("BodyPosition")
				bodyPos.MaxForce=Vector3.new(1000000,1000000,1000000)
				bodyPos.D=100
				bodyPos.P=100000
				bodyPos.Parent=parent
			end
			
			local function generate_force(parent)
				velocity=Instance.new("BodyVelocity")
				velocity.MaxForce=Vector3.new(1000000, 1000000, 1000000)
				velocity.P=100000
				velocity.Parent=parent
			end
			
			local direction=Vector3.new(0,10,0)
			while true do 
				local elapsed=workspace:GetServerTimeNow()-timer
				if not Check_Attack_Eligibility(villain) then break end
				if not closest or closest.Parent==nil then break end
				if remote.Parent==nil then break end -- it was replaced or removed!
				if not cs:HasTag(closest.Character,"ragdolled") then
					local f=coroutine.wrap(ragdoll.ragdoll)
					f(closest,closest.Character,5-elapsed,"recover")
				end
				if TentacleCFrame then
					--workspace.a.CFrame=TentacleCFrame
					if not isThrowing then
						if not gyro or not bodyPos then
							generate_movers(closest.Character.PrimaryPart)
						end
						bodyPos.Position=TentacleCFrame.Position
						gyro.CFrame=TentacleCFrame*CFrame.Angles(math.rad(0),math.rad(180),math.rad(0))
						direction=villain.PrimaryPart.CFrame.LookVector
					else
						local elapsed=workspace:GetServerTimeNow()-isThrowing
						if not velocity then
							generate_force(closest.Character.PrimaryPart)
						end
						if gyro then
							gyro:Destroy()
							gyro=nil
						end
						if bodyPos then
							bodyPos:Destroy()
							bodyPos=nil
						end
						velocity.Velocity=direction*100
						if elapsed>=.5 then -- time to stop
							velocity:Destroy()
							velocity=nil
							break
						end
					end
				end
				if elapsed>=5 then -- stop everything
					break
				end
				game:GetService("RunService").Heartbeat:Wait()
			end
			
			if gyro then
				gyro:Destroy()
			end
			if bodyPos then
				bodyPos:Destroy()
			end
			if velocity then
				velocity:Destroy()
			end
			remote:Destroy()
		end
	end,
	
	GetActions=function(properties)
		local actions=nil
		actions={
			{15,"Grab"},
			{35,"Barrage"},
			{50,"Hooks"},
		}

		return actions
	end,
	
	actionFunctions={
		["Hooks"]=function(villain,timer,event,properties)
			if not Check_Attack_Eligibility(villain) then return end
			event:FireAllClients(timer)
			notify_spidey_sense(villain)
			while workspace:GetServerTimeNow() - timer < .5 do 
				task.wait()
			end
			if not Check_Attack_Eligibility(villain) then return end
			local animationSpeed = 1
			local animationDuration = 154/60 -- frames
			local realDuration = animationDuration * animationSpeed
			local hit1 = (66/154) * realDuration
			local hit2 = (96/154) * realDuration
			task.wait(hit1)
			if not Check_Attack_Eligibility(villain) then return end
			villainProfiles["Doc Ock"].attack(villain,"Hooks","LeftHook")
			task.wait(hit2-hit1)
			if not Check_Attack_Eligibility(villain) then return end
			villainProfiles["Doc Ock"].attack(villain,"Hooks","RightHook")
		end,
		["Barrage"]=function(villain,timer,event,properties)
			if not Check_Attack_Eligibility(villain) then return end
			event:FireAllClients(timer)
			notify_spidey_sense(villain)
			while workspace:GetServerTimeNow() - timer < .5 do 
				task.wait()
			end
			if not Check_Attack_Eligibility(villain) then return end
			local animationSpeed = 1
			local animationDuration = 139/60 -- frames
			local realDuration = animationDuration * animationSpeed
			local first_hit = (47/154) * realDuration
			task.wait(first_hit)
			for i=1,8 do
				if not Check_Attack_Eligibility(villain) then return end
				villainProfiles["Doc Ock"].attack(villain,"Barrage")
				task.wait(1/6)
			end
		end,
		["Grab"]=function(villain,timer,event,properties)
			if not Check_Attack_Eligibility(villain) then return end
			local lastGrab=villainProfiles["Doc Ock"].lastGrab
			event:FireAllClients(timer,lastGrab)
			lastGrab=lastGrab=="Left" and "Right" or "Left"
			villainProfiles["Doc Ock"].lastGrab=lastGrab -- Update the value!
			notify_spidey_sense(villain)
			while workspace:GetServerTimeNow() - timer < .5 do 
				task.wait()
			end
			if not Check_Attack_Eligibility(villain) then return end
			local animationSpeed = 1
			local animationDuration = 159/60 -- frames
			local realDuration = animationDuration * animationSpeed
			local grab = (60/159) * realDuration
			local throw = (120/159) * realDuration
			task.wait(grab)
			villainProfiles["Doc Ock"].attack(villain,"Grab",workspace:GetServerTimeNow())
		end,
	}
	
}

return villainProfiles