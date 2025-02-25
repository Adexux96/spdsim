local rs = game:GetService("ReplicatedStorage")
local cs = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local NPCs = require(script.Parent.NPCs)
local _math = require(rs.math)

local ragdoll = require(rs.ragdoll)

local sss=game:GetService("ServerScriptService")
local rewards=require(sss.Rewards)

local thugs = rs.thugs
local remotes = thugs.RemoteEvents

local function ray(origin,direction,ignore1)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {
		ignore1,
		workspace.Buildings,
		workspace.water,
		workspace.Projectiles,
		workspace.Impacts,
		workspace.TripWebs,
		workspace.Webs,
		workspace.detectRay,
		workspace.Thugs,
		workspace.Villains,
		workspace.Drops
	}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local function obstructionRay(origin,direction,thugWhitelist,ignoreThug)
	local raycastParams = RaycastParams.new()
	if thugWhitelist then
		local whitelistThugs = {}
		for _,thug in pairs(workspace.Thugs:GetChildren()) do
			if thug ~= ignoreThug then
				whitelistThugs[#whitelistThugs+1] = thug
			end
		end
		raycastParams.FilterDescendantsInstances = whitelistThugs
	else 
		raycastParams.FilterDescendantsInstances = {
			workspace.BuildingBounds,
			workspace.BarrelFire1,
			workspace.Trash,
		}		
	end
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult	
end

local closeRangeTypes = {
	["ak"] =false,
	["bat"] = true,
	["shotgun"] = false,
	["flamethrower"] = false,
	["electric"] = true,
	["brute"] = true,
	["minigun"] = false
}

local function getPlayerTargetOffsetPos(characterPos,thugPos,_type,characterMoving,speed,newOffset)
	-- for ranged thugs:
	-- if thug is too far away, it will get closer, if it's within range it won't move back
	local ranged=closeRangeTypes[_type]==false
	local ignoreY=Vector3.new(1,0,1)
	local p1=characterPos*ignoreY
	local p2=thugPos*ignoreY
	local distance=(p1-p2).Magnitude
	local offset = ranged and 24 or 3
	local tooFar=distance>offset
	if characterMoving then
		offset = ranged and 24 or math.clamp(-speed * .25,-8,8)
	end
	local direction = (p1-p2).Unit * 1000000000
	if ranged then
		offset=tooFar and -(distance*2)+offset or 0
	else 
		offset=-distance+offset
	end
	local cf = CFrame.new(thugPos,direction) * CFrame.new(0,0,offset)
	return cf.Position,offset
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

local function getAttackablesFromParts(parts)
	local humanoids = {}
	local drones = {}
	for _,part in pairs(parts) do 
		local humanoid = part.Parent:FindFirstChild("Humanoid") or part.Parent.Parent:FindFirstChild("Humanoid")
		local drone = part.Parent:FindFirstChild("Drone") or part.Parent.Parent:FindFirstChild("Drone")
		if humanoid and humanoids[humanoid.Parent.Name] == nil then
			humanoids[humanoid.Parent.Name] = humanoid.Parent
		end
		if drone and drones[drone.Parent.Name] == nil then
			drones[drone.Parent.Name] = drone.Parent
		end
	end
	return humanoids,drones
end

local function visualizeHitBox(cframe,size)
	local part = workspace.placementB
	part.CFrame = cframe
	part.Size = size
	--part.Parent = workspace
	--game:GetService("Debris"):AddItem(part,1)
end

local function impactEffect(pos,lookAt,thugType,model)
	local parts = {
		["ak"] = rs.hitImpact,
		["shotgun"] = rs.hitImpact,
		["minigun"] = rs.hitImpact,
		["bat"] = rs.batImpact,
		["electric"] = rs.electricImpact,
	}
	if thugType == "flamethrower" then 
		-- if player not already on fire,
		-- set this player's onFire value to true and the timer
		local player = game.Players:GetPlayerFromCharacter(model)
		if player then
			local leaderstats = player.leaderstats
			local temp = leaderstats.temp
			local isOnFire = temp.isOnFire
			if isOnFire.Value then return end
			isOnFire.Value = true 
			rs.FireEvent:FireAllClients(model,true)
			isOnFire.tick.Value = workspace:GetServerTimeNow()
		end
		return
	end
	if thugType=="electric" then
		local player = game.Players:GetPlayerFromCharacter(model)
		if player then
			--local leaderstats = player.leaderstats
			--local temp = leaderstats.temp
			--local isElectrified = temp.isElectrified
			--if isElectrified.Value then return end
			--isElectrified.Value = true 
			rs.ElectricEvent:FireAllClients(model,workspace:GetServerTimeNow())
			--isElectrified.tick.Value = workspace:GetServerTimeNow()
		end
	end
	if thugType == "brute" and model ~= nil then
		rs.MeleeEvent:FireAllClients("Melee",model)
		return
	end
	if not parts[thugType] then return end
	local attachment = parts[thugType].Attachment:Clone()
	attachment.Name = "impact"
	attachment.CFrame = CFrame.new(pos,lookAt)
	attachment.Parent = workspace.Terrain
	game:GetService("Debris"):AddItem(attachment,2)
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

local function checkEligibility(thug,lastAttack)
	if lastAttack then
		if lastAttack.Value == "" then return false end -- attack in progress
	end
	if not thug or not (thug.Parent==workspace.Thugs) then return false end
	local properties = thug.Properties
	local target = properties.Target
	local health = properties.Health
	if health.Value == 0 then return false end
	if target.Value == nil then return false end
	if target.Value.Parent == nil then return false end
	if target.Value:IsA("Attachment") then return false end
	if cs:HasTag(thug,"ragdolled") then return false end
	return true
end

local function get_torso_cframe(originCF:CFrame, targetCF:CFrame)
	local look=originCF.LookVector*-1
	local ignoreY=Vector3.new(1,0,1)
	local direction=((originCF.Position*ignoreY)-(targetCF.Position*ignoreY)).Unit
	local dot=look:Dot(direction)
	dot=math.clamp(dot,0,1)
	local y_difference=targetCF.Position.Y-originCF.Position.Y
	local y=(dot*y_difference)+originCF.Position.Y
	local real_goal=(targetCF.Position*ignoreY)+Vector3.new(0,y,0)
	return CFrame.new(originCF.Position,real_goal)
end

local function torso_cf(model,target,p,offset)
	local origin = model.UpperTorso.Position
	local goal = ((model.UpperTorso.CFrame * CFrame.new(0,0,offset)).Position * Vector3.new(1,0,1)) + (target * Vector3.new(0,1,0))
	local progress = origin:Lerp(goal,math.clamp(p,0,1))
	local direction = (goal - origin).Unit * 1000000000
	return CFrame.new(progress,direction)
end

local function notify_spidey_sense(model)
	local target=model.Properties.Target
	if target.Value then
		local player=game.Players:GetPlayerFromCharacter(target.Value)
		if player then
			rs:WaitForChild("SpideySense"):FireAllClients(player)
		end
	end
end

local function melee(cframe,size,model,damage,thugType,action)
	--visualizeHitBox(cframe,size)
	local parts = getPartsInBoundingBoxForAttackables(cframe,size)
	local characters,drones = getAttackablesFromParts(parts)

	for characterName,character in pairs(characters) do 
		local player = game.Players:GetPlayerFromCharacter(character)
		if player then
			local leaderstats = player.leaderstats
			local temp = leaderstats.temp
			local isRolling = temp.isRolling
			if isRolling.Value then return end
			local humanoid = character.Humanoid
			humanoid:TakeDamage(damage)
			--print(damage)
			addDamageIndicator(player.leaderstats.indicators,model.Name,model.PrimaryPart)
			addAttackerValue(player.leaderstats.attackers,model.Name)
			NPCs[model.Name].attacking[player] = true -- add it to a list you can read from
			if not (humanoid.Health > 0) then
				cs:AddTag(humanoid.Parent,"Died")
			end
			impactEffect(humanoid.Parent.PrimaryPart.Position,model.PrimaryPart.Position,thugType,character)
			if thugType == "electric" then
				rs.ElectricEvent:FireAllClients(character,workspace:GetServerTimeNow())
				--local f = coroutine.wrap(ragdoll.ragdoll)
				--f(player,character,3,"recover")
			elseif thugType == "brute" and action == "uppercut" then
				local f = coroutine.wrap(ragdoll.ragdoll)
				f(player,character,3,"recover")
			end
		end
	end

	if thugType == "flamethrower" then return end -- can't damage drones

	for droneName,drone in pairs(drones) do 
		local health = drone.Properties.Health
		local maxHealth = drone.Properties.MaxHealth
		local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
		health.Value = newHealth -- deal damage to drone

		local owner = game.Players:FindFirstChild(drone.Name)
		if owner then
			addAttackerValue(owner.leaderstats.attackers,model.Name)
			addDamageIndicator(owner.leaderstats.indicators,model.Name,model.PrimaryPart)	
		end

		impactEffect(drone.PrimaryPart.Position,model.PrimaryPart.Position,thugType)

		local function killDrone()
			if not (health.Value > 0) and not cs:HasTag(drone,"Died") then
				cs:AddTag(drone,"Died")
				local index=drone.Properties.Tag.Value
				local listing = NPCs[index]
				if listing and listing.model and listing.model:IsDescendantOf(workspace) and listing.model.PrimaryPart then
					-- reward players who damaged drone
					local cashAdd = math.round(50*(listing.model.Properties.MaxHealth.Value/100))
					for i,v in pairs(listing.attackers) do 
						local plr = v.plr
						if plr:IsDescendantOf(game.Players) then
							local totalDamage=listing.totalDamage
							totalDamage=totalDamage or 0
							local damage=math.clamp(v.damage.Value,0,totalDamage)
							if damage==0 then continue end -- don't try to reward if the damage is 0
							local reward=math.ceil(math.clamp(damage/totalDamage,0,1) * cashAdd)
							rewards:RewardPlayer(plr,"Money",reward)
						end
					end
					task.wait(3)
					if listing.model~=nil then listing.model:Destroy() end
					NPCs[index].clear(NPCs[index])
					NPCs[index]=nil
				end
			end								
		end

		local f = coroutine.wrap(killDrone)
		f()
	end
end

local function attack_electric(model,lastAttack)
	local damage = 25
	if checkEligibility(model,lastAttack) == false then return end

	if workspace:GetServerTimeNow() - tonumber(lastAttack.Value) > 1 then
		lastAttack.Value = ""
		local timer = workspace:GetServerTimeNow()

		local animationSpeed = 3
		local totalFrames = 174
		local animationDuration = totalFrames/60 -- frames
		local realDuration = animationDuration * (1/animationSpeed)
		local swing1 = (60/totalFrames) * realDuration
		local swing2 = swing1 -- same in this case, swings are evenly spread apart

		local function waitUntilAttack()
			
			notify_spidey_sense(model)
			
			while (workspace:GetServerTimeNow() - timer) < 1 do
				task.wait(1/30)
			end

			if checkEligibility(model) == false then return end	
			
			--local cframe = model.UpperTorso.CFrame * CFrame.new(0,0,-3)
			local hitbox_length=5
			local target=model.Properties.Target
			local cframe=get_torso_cframe(model.UpperTorso.CFrame,target.Value.PrimaryPart.CFrame)
			cframe=cframe*CFrame.new(0,0,-hitbox_length/2)
			local size = model:GetExtentsSize() + Vector3.new(0,0,hitbox_length)
			melee(cframe,size,model,damage,"electric")

			task.wait(swing2)

			if checkEligibility(model) == false then return end
			--local cframe = model.UpperTorso.CFrame * CFrame.new(0,0,-3)
			local hitbox_length=5
			local target=model.Properties.Target
			local cframe=get_torso_cframe(model.UpperTorso.CFrame,target.Value.PrimaryPart.CFrame)
			cframe=cframe*CFrame.new(0,0,-hitbox_length/2)
			local size = model:GetExtentsSize() + Vector3.new(0,0,hitbox_length)
			melee(cframe,size,model,damage,"electric")
		end
		local remote = remotes:FindFirstChild(model.Name)
		if remote then
			remote:FireAllClients("attack",timer)
			waitUntilAttack()
		end
		lastAttack.Value = workspace:GetServerTimeNow()
	end
end

local function attack_bat(model,lastAttack)
	local damage = 20
	if checkEligibility(model,lastAttack) == false then return end

	if workspace:GetServerTimeNow() - tonumber(lastAttack.Value) > .5 then
		lastAttack.Value = ""
		local t = workspace:GetServerTimeNow()
		local function waitUntilAttack()
			
			notify_spidey_sense(model)
			
			while workspace:GetServerTimeNow() - t < 1 do
				task.wait(1/30)
			end
			if checkEligibility(model) == false then return end
			
			--local cframe = model.UpperTorso.CFrame * CFrame.new(0,0,-3)
			local hitbox_length=5
			local target=model.Properties.Target
			local cframe=get_torso_cframe(model.UpperTorso.CFrame,target.Value.PrimaryPart.CFrame)
			cframe=cframe*CFrame.new(0,0,-hitbox_length/2)
			local size = model:GetExtentsSize() + Vector3.new(0,0,hitbox_length)
			melee(cframe,size,model,damage,"bat")
		end
		local remote = remotes:FindFirstChild(model.Name)
		if remote then
			remote:FireAllClients("attack",t)
			waitUntilAttack()
		end
		lastAttack.Value = workspace:GetServerTimeNow()
	end
end

local function attack_brute(model,lastAttack)
	local n = _math.defined(0,100)
	local attackType = n <= 30 and "uppercut" or "hook"

	local damage = attackType == "uppercut" and 100 or 50
	if checkEligibility(model,lastAttack) == false then return end

	local _wait=attackType=="uppercut" and 1.233 or .3833

	if workspace:GetServerTimeNow() - tonumber(lastAttack.Value) > 1 then
		lastAttack.Value = ""
		local t = workspace:GetServerTimeNow()
		local function waitUntilAttack()
			notify_spidey_sense(model)
			while workspace:GetServerTimeNow() - t < _wait do
				task.wait(1/30)
			end
			if checkEligibility(model) == false then return end

			--local cframe = model.UpperTorso.CFrame * CFrame.new(0,0,-3)
			local hitbox_length=5*1.375
			local target=model.Properties.Target
			local cframe=get_torso_cframe(model.UpperTorso.CFrame,target.Value.PrimaryPart.CFrame)
			cframe=cframe*CFrame.new(0,0,-hitbox_length/2)
			local size = model:GetExtentsSize() + Vector3.new(0,0,hitbox_length)
			melee(cframe,size,model,damage,"brute",attackType)
		end
		local remote = remotes:FindFirstChild(model.Name)
		if remote then
			remote:FireAllClients("attack",t,attackType)
			waitUntilAttack()
		end
		lastAttack.Value = workspace:GetServerTimeNow()
	end
end

local ts = game:GetService("TweenService")
local tweenInfo_fifth = TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)

local function attack_flamethrower(model,lastAttack)

	-- the length from your root to the flamethrower muzzle is 6 studs
	-- the length from the muzzle to the end is 30 studs
	-- gradually increase over time, reaches max length in the first second

	if checkEligibility(model,lastAttack) == false then return end

	if workspace:GetServerTimeNow() - tonumber(lastAttack.Value) > 2 then
		lastAttack.Value = ""
		local t = workspace:GetServerTimeNow()
		local function waitUntilAttack()
			notify_spidey_sense(model)
			while workspace:GetServerTimeNow() - t < 1 do
				task.wait(1/30)
			end
			if checkEligibility(model) == false then return end

			-- gotta get the flame length, position and size given the current elapsed time
			local properties = model.Properties
			local target = properties.Target

			local attachment = Instance.new("Attachment")
			--attachment.Visible = true
			attachment.WorldCFrame = model.PrimaryPart.CFrame
			attachment.Parent = workspace.Terrain

			local damage = 5

			local elapsed = workspace:GetServerTimeNow() - t 
			local p = 0
			local i = 0
			while p < 1.5 do
				if checkEligibility(model) == false then break end
				i+=1
				p = (workspace:GetServerTimeNow() - t) - elapsed
				local origin=model.UpperTorso.Position
				local torsoCF=get_torso_cframe(model.UpperTorso.CFrame,target.Value.PrimaryPart.CFrame)
				local goal=(torsoCF*CFrame.new(0,0,-30)).Position
				local progress = origin:Lerp(goal,math.clamp(p,0,1))
				local direction = (goal - origin).Unit * 1000000000
				local cf=CFrame.new(progress,direction)
				attachment.WorldCFrame=cf
				if i%3==0 then
					cf = CFrame.new(origin:Lerp(attachment.WorldPosition,.5),attachment.WorldPosition)
					local modelSize = model:GetExtentsSize()
					local size = Vector3.new(modelSize.X,modelSize.Y,(origin - attachment.WorldPosition).Magnitude)
					--visualizeHitBox(cf,size)
					melee(cf,size,model,(1.5-p)*damage,"flamethrower")
				end
				task.wait(1/30)
			end
			attachment:Destroy()
		end
		local remote = remotes:FindFirstChild(model.Name)
		if remote then
			remote:FireAllClients("attack",t)
			waitUntilAttack()
		end
		lastAttack.Value = workspace:GetServerTimeNow()
	end

end

local function bulletEnd(model,result,bullet,humanoid,drone,damage)

	if humanoid then
		local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
		if player then
			local leaderstats = player:WaitForChild("leaderstats")
			local temp = leaderstats:WaitForChild("temp")
			local isRolling = temp:WaitForChild("isRolling")
			if isRolling.Value then return end
			humanoid:TakeDamage(damage)
			addDamageIndicator(player.leaderstats.indicators,model.Name,model.PrimaryPart)
			addAttackerValue(player.leaderstats.attackers,model.Name)
			NPCs[model.Name].attacking[player] = true -- add it to a list you can read from
			if not (humanoid.Health > 0) then
				cs:AddTag(humanoid.Parent,"Died")
			end
		end
	else
		if drone then
			drone = drone.Parent
			local health = drone.Properties.Health
			local maxHealth = drone.Properties.MaxHealth
			local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
			health.Value = newHealth -- deal damage to drone

			local owner = game.Players:FindFirstChild(drone.Name)
			if owner then
				addAttackerValue(owner.leaderstats.attackers,model.Name)
				addDamageIndicator(owner.leaderstats.indicators,model.Name,model.PrimaryPart)	
			end

			local function killDrone()
				if not (health.Value > 0) and not cs:HasTag(drone,"Died") then
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
			end

			local f = coroutine.wrap(killDrone)
			f()

		end
	end

end

local function bullet(model,target,origin,timer,damage,thugType)

	local direction = (target.Value.PrimaryPart.Position - origin).Unit
	local bulletAmount = thugType == "ak" and 1 or 3

	local bullets = {}
	for i = 1,bulletAmount do 
		local x = thugType == "ak" and 0 or _math.defined(-10,10)
		local y = thugType == "ak" and 0 or _math.defined(-10,10)
		local _endPos = (CFrame.new(origin,direction*1000000) * CFrame.new(x,y,-100)).Position
		local _bullet = rs.Particles.FX_Bullet_Trail:Clone()
		_bullet.CFrame = CFrame.new(origin,_endPos)
		_bullet.Parent = workspace.Bullets
		game:GetService("Debris"):AddItem(_bullet,2)
		bullets[#bullets+1] = {
			bullet = _bullet,
			endPos = _endPos,
			prevOrigin = origin,
			updatedOrigin = origin
		} 
	end

	local elapsed = workspace:GetServerTimeNow() - timer

	while true do
		local p = math.clamp((workspace:GetServerTimeNow() - timer) - elapsed / 1,0,1)
		for index,data in pairs(bullets) do 
			data.updatedOrigin = origin:Lerp(data.endPos,p)
			local rayLength = (data.updatedOrigin-data.prevOrigin).Magnitude
			local newDirection = (data.updatedOrigin - data.prevOrigin).Unit
			local newEndPos = CFrame.new(data.updatedOrigin,newDirection*rayLength).Position
			local result = ray(data.prevOrigin,newDirection*rayLength,model)
			data.prevOrigin = data.updatedOrigin
			if result then
				local cf = CFrame.new(result.Position, result.Position - result.Normal)
				data.bullet.CFrame = cf
				local hit = result.Instance
				local humanoid = hit.Parent:FindFirstChild("Humanoid") or hit.Parent.Parent:FindFirstChild("Humanoid")
				local drone = hit.Parent:FindFirstChild("Drone") or hit.Parent.Parent:FindFirstChild("Drone")

				bulletEnd(model,result,bullet,humanoid,drone,damage)

				if not humanoid and not drone then
					impactEffect(cf.Position,origin,thugType)
				end
				table.remove(bullets,index)
			else 
				data.bullet.CFrame = CFrame.new(data.updatedOrigin,data.endPos)
			end	
		end
		if p == 1 then break end
		task.wait(1/30)
	end

end

local function visualizeRay(origin,pos)
	local rayVisual = rs:WaitForChild("rayVisual"):Clone()
	rayVisual.CFrame = CFrame.new(origin:Lerp(pos,.5),pos)
	rayVisual.Size = Vector3.new(0.25,0.25,(origin - pos).Magnitude)
	rayVisual.Transparency = 0.75
	rayVisual.BrickColor = BrickColor.Green()
	rayVisual.Material = Enum.Material.Neon
	rayVisual.Parent = workspace.detectRay
	game:GetService("Debris"):AddItem(rayVisual,1)
end

local ak_muzzle_offset = Vector3.new(0.505218505859375, 0.924654483795166, -4.609122276306152)
local shotgun_muzzle_offset = Vector3.new(0.8579559326171875, 0.8513813018798828, -4.376463890075684)

local function attack_gun(model,lastAttack)
	local properties = model.Properties
	if not checkEligibility(model,lastAttack) then return end
	local damage = properties.Type.Value == "ak" and 30 or 15

	if workspace:GetServerTimeNow() - tonumber(lastAttack.Value) > .5 then
		lastAttack.Value = ""
		local timer = workspace:GetServerTimeNow()
		local function waitUntilAttack()
			notify_spidey_sense(model)
			while workspace:GetServerTimeNow() - timer < 1 do 
				task.wait(1/30)
			end
			if not checkEligibility(model) then return end

			local muzzle_offset = properties.Type.Value == "ak" and ak_muzzle_offset or shotgun_muzzle_offset

			local target = properties.Target
			local torsoCF=get_torso_cframe(model.UpperTorso.CFrame,target.Value.PrimaryPart.CFrame)
			local origin = (torsoCF * CFrame.new(muzzle_offset)).Position

			bullet(model,target,origin,timer,damage,properties.Type.Value)
		end
		local remote = remotes:FindFirstChild(model.Name)
		if remote then
			remote:FireAllClients("attack",timer)
			waitUntilAttack()
		end
		lastAttack.Value = workspace:GetServerTimeNow()
	end

end

local function Get_Ahead_Goal(start,goal,target,speed)
	--print("start=",start)
	--print("goal=",goal)
	--print("speed=",speed)
	local air_time = (start - goal).Magnitude / speed
	local nextPosition = goal + ((target.PrimaryPart.Velocity*2) * air_time)

	start=CFrame.new(start,nextPosition)
	goal=start*CFrame.new(0,0,-100)

	return goal
end

local function attack_minigun(model,lastAttack)
	local properties = model.Properties
	if not checkEligibility(model,lastAttack) then return end
	local damage = 15
	local minigun=model.Minigun
	
	if workspace:GetServerTimeNow() - tonumber(lastAttack.Value) > 1 then
		lastAttack.Value = ""
		local timer = workspace:GetServerTimeNow()
		local time_until_fire=.65
		local function waitUntilAttack()
			notify_spidey_sense(model)
			while workspace:GetServerTimeNow() - timer < time_until_fire do 
				task.wait()
			end
		end
		
		local remote = remotes:FindFirstChild(model.Name)
		if remote then
			remote:FireAllClients("attack",timer)
			waitUntilAttack()
		end
		
		if not checkEligibility(model) then return end
		
		local muzzle_offset = minigun.MuzzleOffset.Value.Position
		
		local bullet_amount=6
		local bullets={}
		
		local function create_new_bullet(origin,direction)
			local _endPos = (CFrame.new(origin,direction*1000000) * CFrame.new(0,0,-200)).Position
			local _bullet = rs.Particles.FX_Bullet_Trail:Clone()
			_bullet.CFrame = CFrame.new(origin,_endPos)
			_bullet.Parent = workspace.Bullets
			game:GetService("Debris"):AddItem(_bullet,3)
			bullets[#bullets+1]={
				bullet = _bullet,
				origin = origin,
				endPos = _endPos,
				prevOrigin = origin,
				updatedOrigin = origin,
				timer=workspace:GetServerTimeNow(),
				p=0
			} 
		end
		
		local elapsed = workspace:GetServerTimeNow() - timer
		
		local target=properties.Target.Value
		local start=tick()
		while true do   
			local targetCF=target.PrimaryPart.CFrame
			if #bullets<bullet_amount then
				if tick()-start>=.2 or #bullets==0 then
					if not checkEligibility(model) then 
						bullet_amount=#bullets
						break   
					end
					start=tick()
					local torsoCF=get_torso_cframe(model.UpperTorso.CFrame,target.PrimaryPart.CFrame)
					local origin = (torsoCF * CFrame.new(muzzle_offset)).Position
					local goal = targetCF
					local direction = (goal.Position - origin).Unit
					--workspace.move2.Position=(CFrame.new(origin,goal.Position)*CFrame.new(0,0,-10)).Position
					create_new_bullet(origin,direction)
				end
			end
			
			--workspace:WaitForChild("move").Position=targetCF.Position
			
			local bullets_finished=0
			for index,data in pairs(bullets) do 
				if data.p==1 then
					bullets_finished+=1 
					continue
				end  
				data.p = math.clamp((workspace:GetServerTimeNow() - data.timer) / 1,0,1)
				data.updatedOrigin = data.origin:Lerp(data.endPos,data.p)
				local rayLength = (data.updatedOrigin-data.prevOrigin).Magnitude
				local newDirection = (data.updatedOrigin - data.prevOrigin).Unit
				local newEndPos = CFrame.new(data.updatedOrigin,newDirection*rayLength).Position
				local result = ray(data.prevOrigin,newDirection*rayLength,model)
				data.prevOrigin = data.updatedOrigin
				if result then
					local cf = CFrame.new(result.Position, result.Position - result.Normal)
					data.bullet.CFrame = cf
					local hit = result.Instance
					local humanoid = hit.Parent:FindFirstChild("Humanoid") or hit.Parent.Parent:FindFirstChild("Humanoid")
					local drone = hit.Parent:FindFirstChild("Drone") or hit.Parent.Parent:FindFirstChild("Drone")

					bulletEnd(model,result,bullet,humanoid,drone,damage)

					if not humanoid and not drone then
						impactEffect(cf.Position,data.origin,properties.Type.Value)
					end
					--table.remove(bullets,index)
					data.p=1
					continue
				else 
					data.bullet.CFrame = CFrame.new(data.updatedOrigin,data.endPos)
				end
			end
			
			if bullets_finished==bullet_amount then break end -- all bullets finished
			task.wait()
		end
		
		lastAttack.Value = workspace:GetServerTimeNow()
	end
end

local function getPartsInBoundingBox(cframe,size)
	local whitelist = {
		workspace.BarrelFire1,
		workspace.Trash
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

local attackFunctions = {
	["bat"] = attack_bat,
	["ak"] = attack_gun,
	["electric"] = attack_electric,
	["shotgun"] = attack_gun,
	["brute"] = attack_brute,
	["flamethrower"] = attack_flamethrower,
	["minigun"] = attack_minigun
}

local foundThug = nil
local function newThugPath(model) 
	while model.Parent ~= nil do
		if model.Properties.Health.Value > 0 then
			if not cs:HasTag(model,"ragdolled") then -- don't move while ragdolled
				local target = model.Properties.Target
				if target.Value ~= nil and target.Value.Parent ~= nil then
					local _type = model.Properties.Type
					local targetIsAttachment = target.Value:IsA("Attachment")
					local goal,offset
					local targetPosition
					local lastAttack = model.Properties.lastAttack
					local ignoreY = Vector3.new(1,0,1)
					if targetIsAttachment then
						goal = target.Value.WorldPosition
						targetPosition = goal
						offset = 0
					else
						targetPosition = target.Value.PrimaryPart.Position
						local targetHumanoid = target.Value.Humanoid
						local isMoving = targetHumanoid.MoveDirection.Magnitude ~= 0
						local targetSpeed = (target.Value.PrimaryPart.Velocity * ignoreY).Magnitude
						local pos,number = getPlayerTargetOffsetPos(targetPosition,model.PrimaryPart.Position,_type.Value,isMoving,targetSpeed) 
						offset = 0--number
						goal = pos
						local distance = ((targetPosition * ignoreY) - (model.PrimaryPart.Position * ignoreY)).Magnitude
						local allowedDistance = closeRangeTypes[_type.Value] and 6 or 100
						if distance <= allowedDistance then
							local attackFunction = attackFunctions[_type.Value]
							if attackFunction then
								local f = coroutine.wrap(attackFunction)
								f(model,lastAttack)
							else 
								--print("attack function wasn't found")
							end
						end
					end

					local distance = ((targetPosition * ignoreY) - (model.PrimaryPart.Position * ignoreY)).Magnitude
					local allowedDistance = closeRangeTypes[_type.Value] and 6 or 24
					if targetIsAttachment then -- npc can stop trying to find a path if you're within this distance of the goal
						allowedDistance = 2
					end
					local tooClose = not targetIsAttachment --and closeRangeTypes[_type.Value] == false and distance < 6

					if target.Value:IsA("Attachment") then
						model.Humanoid.WalkSpeed = 8
					else 
						model.Humanoid.WalkSpeed = math.clamp(allowedDistance*((distance*2)/allowedDistance),16,32)+2
					end

					if distance > allowedDistance or tooClose then
						if tooClose and closeRangeTypes[_type]==false then
							goal = getPlayerTargetOffsetPos(targetPosition,model.PrimaryPart.Position,nil,nil,nil,12)
						end
						goal = Vector3.new(goal.X,4,goal.Z)
						--[[
						local part= NPCs[model.Name].part
						if not part then
							part=Instance.new("Part")
							part.Anchored=true
							part.CanCollide=false
							part.Transparency=.5
							part.BrickColor=BrickColor.Red()
							part.Size=Vector3.new(1,1,1)
							part.Parent=workspace
							NPCs[model.Name].part=part
						end
						part.Position=goal
						]]
						local PhysicalZone = rs.Zones[model.Properties.Zone.Value]
						local isInZone = _math.checkBounds(PhysicalZone.CFrame,PhysicalZone.Size,goal)
						if isInZone then
							local rootPos = model.PrimaryPart.Position
							local modifiedRootPos = Vector3.new(rootPos.X,goal.Y,rootPos.Z)
							local distance = (goal - modifiedRootPos).Magnitude
							local cframe = CFrame.new(modifiedRootPos:Lerp(goal,.5),goal)
							local size = Vector3.new(4,4,distance)
							local obstructionsFound = getPartsInBoundingBox(cframe,size)

							local trashFound = nil
							local barrelFound = nil

							for _,obstruction in pairs(obstructionsFound) do 
								if obstruction:IsDescendantOf(workspace.Trash) and obstruction.Name == "Garbage" then
									trashFound = obstruction
								end
								if obstruction:IsDescendantOf(workspace.BarrelFire1) then
									barrelFound = obstruction
								end
							end

							local obstruction = barrelFound or trashFound
							if obstruction then
								local distance = ((obstruction.Position * ignoreY) - (model.PrimaryPart.Position * ignoreY)).Magnitude
								if distance <= 6 then
									if model.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
										model.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
									end									
								end
							end

							model.Humanoid:MoveTo(goal)
						end
					end	
				end
			end
		else -- stop the loop, this npc is dead
			for player,bool in pairs(NPCs[model.Name].attacking) do
				local leaderstats = player.leaderstats
				local attackingListing = leaderstats.attacking:FindFirstChild(model.Name)
				if attackingListing then 
					attackingListing:Destroy() 
				end
				local attackerListing = leaderstats.attackers:FindFirstChild(model.Name)
				if attackerListing then 
					attackerListing:Destroy() 
				end
			end
			break
		end
		task.wait(.25)
	end
end

local ts = game:GetService("TweenService")
local tweeninfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false)
--local waistC0 = CFrame.new(0, 0.2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)

while true do 
	for index,value in pairs(NPCs) do 
		if not value.model or not value.model:IsDescendantOf(workspace.Thugs) then continue end
		if value.thread == false and value.model.Properties.Target.Value ~= nil then
			value.thread = true
			local f = coroutine.wrap(newThugPath)
			f(value.model)	
		else
			local model = value.model
			local humanoid = model.Humanoid
			local gyro = model.PrimaryPart:FindFirstChild("BodyGyro")
			local properties = model.Properties
			local target = properties.Target
			if target.Value ~= nil and target.Value.Parent ~= nil then
				local isAttachment = target.Value:IsA("Attachment")
				if cs:HasTag(model,"ragdolled") then
					if not cs:HasTag(model,"gravity") then
						gyro.MaxTorque = Vector3.new(0,0,0)
					end
					humanoid.AutoRotate = false
				else
					if isAttachment then
						humanoid.AutoRotate = true
						gyro.MaxTorque = Vector3.new(0,0,0)
					else
						humanoid.AutoRotate = false
						gyro.MaxTorque = Vector3.new(1000000,1000000,1000000)
						local targetPos = target.Value.PrimaryPart.Position
						local rootPos = model.PrimaryPart.Position
						local ignoreYTargetPos = Vector3.new(targetPos.X,rootPos.Y,targetPos.Z)
						gyro.CFrame = CFrame.new(rootPos,ignoreYTargetPos)
					end
				end					
			end	
		end
	end
	task.wait(1/15)
end