--!nocheck

local rs = game:GetService("ReplicatedStorage")
local cs = game:GetService("CollectionService")
local dataManager = require(rs:WaitForChild("dataManager"))
local ragdoll = require(rs.ragdoll)
local _math = require(rs.math)
local items = require(rs.items)
local EP = require(rs.EarningPotential)
local resetEvent = rs:WaitForChild("ResetEvent")
local gravityGyroEvent = rs.GravityGyroEvent
local runService = game:GetService("RunService")
local players = game:GetService("Players")
players.CharacterAutoLoads = false -- turn autoloads off, since custom respawn
local fallDamageEvent = rs:WaitForChild("fallDamageEvent")

local debris = game:GetService("Debris")

local serverStorage=game:GetService("ServerStorage")
local characters = serverStorage:WaitForChild("characters")

local AnalyticsService = game:GetService("AnalyticsService")

local function killPlayer(player)
	local character = player.Character
	if (character) and not (cs:HasTag(character,"Died"))then
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.BreakJointsOnDeath = false
		humanoid:TakeDamage(humanoid.MaxHealth)
		cs:AddTag(character,"Died")
	end
end

local badges={
	["Welcome"]=4446328998311087,
	["Your first million!"]=3660320096164296,
	["You are a killing machine!"]=4223196168727129,
	["You're the goat!"]=4419104347408170,
	["Goblin Exterminator!"]=1585810054067557,
	["Venom Smasher!"]=4096035486592815,
	["Octopus Cooker!"]=1394605183347325
}

local BadgeService=game:GetService("BadgeService")
local function Process_Badges(player,badgeName)
	-- Check if the player has the badge
	local dataFolder=player.leaderstats
	-- single badge!
	if badgeName and badges[badgeName] then
		local success, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badges[badgeName])
		end)
		if not success then
			--print("Error while checking if player has badge!")
			return
		end
		if not hasBadge then
			BadgeService:AwardBadge(player.UserId,badges[badgeName])
		else 
			--print("Player has",badgeName)
		end
		return
	end
	-- multiple badges!
	for name,id in badges do 
		local success, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, id)
		end)

		-- If there's an error, issue a warning and exit the function
		if not success then
			--print("Error while checking if player has badge!")
			return
		end

		if not hasBadge then
			if name=="Welcome" then
				BadgeService:AwardBadge(player.UserId,id)
			end
			if name=="Your first million!" and dataFolder.Cash.Value>=1000000 then
				BadgeService:AwardBadge(player.UserId,id)
			end
			if name=="You are a killing machine!" and dataFolder.Kills.Value>=1000 then
				BadgeService:AwardBadge(player.UserId,id)
			end
			if name=="You're the goat!" and dataFolder.Rebirths.Value==10 then
				BadgeService:AwardBadge(player.UserId,id)
			end
		else 
			--print("Player has",name)
		end

	end
end

local animationsFolder = rs:WaitForChild("animations")

for _,character in (characters:GetChildren()) do
	local _type = character:FindFirstChild("Type").Value
	if (_type == "Girl") then
		--local idleAnims = animationsFolder:WaitForChild("idle")
		--local anim = character:WaitForChild("Humanoid"):LoadAnimation(idleAnims:WaitForChild("ninja_idle"))
		--anim:Play()
	elseif (_type == "Boy") then
		--local idleAnims = animationsFolder:WaitForChild("idle")
		--local anim = character:WaitForChild("Humanoid"):LoadAnimation(idleAnims:WaitForChild("ninja_idle"))
		--anim:Play()
	end
end

fallDamageEvent.OnServerEvent:Connect(function(player,distance)
	--pcall(function()
	--print('distance fell = ',distance)
	--print('damage = ',damage)
	local damage = math.ceil(distance/15*150)
	if (damage < player.Character.Humanoid.Health) then
		local hitSound = rs.ded:Clone()
		hitSound.Parent = player.Character.Head
		hitSound:Play()
		debris:AddItem(hitSound,1)
	end
	player.Character.Humanoid:TakeDamage(damage)
	--end)
end)

resetEvent.OnServerEvent:Connect(function(player)
	--print("reset on server")
	killPlayer(player)
end)

local function UndoAllSkins(list)
	for _,v in (list:GetChildren()) do
		v.Equipped.Value = false
	end
end

local collision_groups={
	["Ghost"]={},
	["Pets"]={
		["Default"]=true
	},
	["Characters"]={
		["Default"]=true,
		["Characters"]=true
	},
	["Thugs"]={
		["Default"]=true
	},
	["Villains"]={
		["Default"]=true,
		["Villains"]=true
	},
	["Spheres"]={
		["Spheres"]=true
	},
	["Ragdoll"]={
		["Default"]=true,
		["Ragdoll"]=true
	},
	["Obstructions"]={
		["Villains"]=true,
		["Characters"]=true,
		["Pets"]=true,
		["Default"]=true
	},
	["FlyingVillains"]={
		["FlyingVillains"]=true,
		["Default"]=true,
	},
	["Default"]={
		["Default"]=true,
		["Characters"]=true,
		["Pets"]=true,
		["Thugs"]=true,
		["Villains"]=true,
		["Ragdoll"]=true
	},
}

local physicsService = game:GetService("PhysicsService")
for group,collideTable in collision_groups do
	if group=="Default" then continue end
	physicsService:RegisterCollisionGroup(group)
end

for groupName1,collideTable in collision_groups do 
	for groupName2,_ in collision_groups do 
		local collide=collideTable[groupName2] and true or false 
		physicsService:CollisionGroupSetCollidable(groupName1,groupName2,collide)
	end
end

--[[
physicsService:RegisterCollisionGroup("Pets")
physicsService:RegisterCollisionGroup("Ghost")
physicsService:RegisterCollisionGroup("Characters")
physicsService:RegisterCollisionGroup("Thugs")
physicsService:RegisterCollisionGroup("Villains")
physicsService:RegisterCollisionGroup("Spheres")
physicsService:RegisterCollisionGroup("Ragdoll")
physicsService:RegisterCollisionGroup("Obstructions")
physicsService:RegisterCollisionGroup("FlyingVillains")


physicsService:CollisionGroupSetCollidable("Ghost", "Characters", false)
physicsService:CollisionGroupSetCollidable("Ghost", "Pets", false)
physicsService:CollisionGroupSetCollidable("Ghost", "Ghost", false)
physicsService:CollisionGroupSetCollidable("Ghost", "Default", false)
physicsService:CollisionGroupSetCollidable("Ghost", "Thugs", false)
physicsService:CollisionGroupSetCollidable("Ghost", "Villains", false)
physicsService:CollisionGroupSetCollidable("Ghost", "Spheres", false)
physicsService:CollisionGroupSetCollidable("Ghost", "Ragdoll", false)

physicsService:CollisionGroupSetCollidable("Ragdoll", "Characters", false)
physicsService:CollisionGroupSetCollidable("Ragdoll", "Pets", false)
physicsService:CollisionGroupSetCollidable("Ragdoll", "Ghost", false)
physicsService:CollisionGroupSetCollidable("Ragdoll", "Default", true)
physicsService:CollisionGroupSetCollidable("Ragdoll", "Thugs", false)
physicsService:CollisionGroupSetCollidable("Ragdoll", "Villains", false)
physicsService:CollisionGroupSetCollidable("Ragdoll", "Spheres", false)
physicsService:CollisionGroupSetCollidable("Ragdoll", "Ragdoll", true)

physicsService:CollisionGroupSetCollidable("Characters", "Characters", true)
physicsService:CollisionGroupSetCollidable("Characters", "Pets", false)
physicsService:CollisionGroupSetCollidable("Characters", "Ghost", false)
physicsService:CollisionGroupSetCollidable("Characters", "Default", true)
physicsService:CollisionGroupSetCollidable("Characters", "Thugs", false)
physicsService:CollisionGroupSetCollidable("Characters", "Villains", false)
physicsService:CollisionGroupSetCollidable("Characters", "Spheres", false)
physicsService:CollisionGroupSetCollidable("Characters", "Ragdoll", false)

physicsService:CollisionGroupSetCollidable("Pets", "Characters", false)
physicsService:CollisionGroupSetCollidable("Pets", "Pets", false)
physicsService:CollisionGroupSetCollidable("Pets", "Ghost", false)
physicsService:CollisionGroupSetCollidable("Pets", "Default", true)
physicsService:CollisionGroupSetCollidable("Pets", "Thugs", false)
physicsService:CollisionGroupSetCollidable("Pets", "Villains", false)
physicsService:CollisionGroupSetCollidable("Pets", "Spheres", false)
physicsService:CollisionGroupSetCollidable("Pets", "Ragdoll", false)

physicsService:CollisionGroupSetCollidable("Default", "Characters", true)
physicsService:CollisionGroupSetCollidable("Default", "Pets", true)
physicsService:CollisionGroupSetCollidable("Default", "Ghost", false)
physicsService:CollisionGroupSetCollidable("Default", "Default", true)
physicsService:CollisionGroupSetCollidable("Default", "Thugs", true)
physicsService:CollisionGroupSetCollidable("Default", "Villains", true)
physicsService:CollisionGroupSetCollidable("Default", "Spheres", false)
physicsService:CollisionGroupSetCollidable("Default", "Ragdoll", true)

physicsService:CollisionGroupSetCollidable("Thugs", "Characters", false)
physicsService:CollisionGroupSetCollidable("Thugs", "Pets", false)
physicsService:CollisionGroupSetCollidable("Thugs", "Ghost", false)
physicsService:CollisionGroupSetCollidable("Thugs", "Default", true)
physicsService:CollisionGroupSetCollidable("Thugs", "Thugs", false)
physicsService:CollisionGroupSetCollidable("Thugs", "Villains", false)
physicsService:CollisionGroupSetCollidable("Thugs", "Spheres", false)
physicsService:CollisionGroupSetCollidable("Thugs", "Ragdoll", false)

physicsService:CollisionGroupSetCollidable("Villains", "Characters", false)
physicsService:CollisionGroupSetCollidable("Villains", "Pets", false)
physicsService:CollisionGroupSetCollidable("Villains", "Ghost", false)
physicsService:CollisionGroupSetCollidable("Villains", "Default", true)
physicsService:CollisionGroupSetCollidable("Villains", "Thugs", false)
physicsService:CollisionGroupSetCollidable("Villains", "Villains", false)
physicsService:CollisionGroupSetCollidable("Villains", "Spheres", false)
physicsService:CollisionGroupSetCollidable("Villains", "Ragdoll", false)

physicsService:CollisionGroupSetCollidable("Spheres", "Characters", false)
physicsService:CollisionGroupSetCollidable("Spheres", "Pets", false)
physicsService:CollisionGroupSetCollidable("Spheres", "Ghost", false)
physicsService:CollisionGroupSetCollidable("Spheres", "Default", false)
physicsService:CollisionGroupSetCollidable("Spheres", "Thugs", false)
physicsService:CollisionGroupSetCollidable("Spheres", "Villains", false)
physicsService:CollisionGroupSetCollidable("Spheres", "Spheres", true)
physicsService:CollisionGroupSetCollidable("Spheres", "Ragdoll", false)
]]

local function addModifiers(model,modifierName,passThrough)
	for _,v in (model:GetDescendants()) do 
		if v:IsA("BasePart") then
			local modifier = Instance.new("PathfindingModifier")
			modifier.Label = modifierName
			modifier.PassThrough = passThrough
			modifier.Parent = v 
		end
	end
end

local function characterCollisionGroup(character)
	for index, part in (character:GetDescendants()) do 
		if part:IsA("BasePart") then
			local collisionGroup = part.Name == "RootLegs" and "Ghost" or "Characters"
			part.CollisionGroup=collisionGroup
		end
	end
end

local cloneSounds = rs:WaitForChild("character_sound"):GetChildren()

local function findHalfwayWeb(parent)
	for i,v in (parent:GetChildren()) do 
		if v.Value == "halfway" then
			return v
		end
	end	
	return nil
end

local function getUpdates(data)
	-- check if data has certain things, if it doesn't add them here and save them
	return data
end

local verified_drones = rs:WaitForChild("VerifiedDrones")
local verified_web_bombs = rs:WaitForChild("VerifiedWebBombs")
local verified_gravity_bombs = rs:WaitForChild("VerifiedGravityBombs")

local liveProjectiles = require(script.Parent.LiveProjectiles) -- player, startPos, type
local liveMelee = require(script.Parent.LiveMelee)
local LiveTripWebs = {} -- player, tag, touchPart
-- make sure to check for npcs if the startpos is in the zone for bombs as well
-- gravity bomb will work regardless though

local NPCs = require(script.Parent.NPCs)

_G.getEquippedSkin=function(player)
	for i,v in (player.leaderstats.skins:GetChildren()) do 
		if v.Equipped.Value then
			return v.Name
		end
	end
	return nil
end

local function addDamageIndicator(folder,name,part)
	if not name or not part or not folder then return end
	--rs.SpideySense:FireAllClients(folder.Parent.Parent)
	local objectValue = Instance.new("ObjectValue")
	objectValue.Name = name
	objectValue.Value = part 
	objectValue.Parent = folder
	game:GetService("Debris"):AddItem(objectValue,3)
end

local rewards=require(script.Parent.Rewards)

local function createAttackingListing(player,model) -- if drone, send drone owner's character
	if not player:IsDescendantOf(game.Players) or not model or not model.PrimaryPart then return end
	local attacking = player.leaderstats.attacking
	local listing = attacking:FindFirstChild(model.Name)
	if listing then -- update the timestamp
		listing.Value = workspace:GetServerTimeNow()
	else 
		local stringValue = Instance.new("StringValue")
		stringValue.Value = workspace:GetServerTimeNow()
		stringValue.Name = model.Name
		stringValue.Parent = attacking
	end
end

local function createAttackerListing(playerHit,playerWhoHit,damage)
	if not playerWhoHit then return end
	if not playerHit or not playerHit.Character or not playerHit.Character.Humanoid then return end
	local attackers = playerHit.leaderstats.attackers
	local listing = attackers:FindFirstChild(playerWhoHit.Name)
	if listing then -- update the timestamp
		listing.Value = workspace:GetServerTimeNow()
		listing.damage.Value += damage
	else
		local stringValue = Instance.new("StringValue")
		stringValue.Name = playerWhoHit.Name
		stringValue.Value = workspace:GetServerTimeNow()
		stringValue.Parent = attackers
		local damageValue = Instance.new("NumberValue")
		damageValue.Name = "damage"
		damageValue.Parent = stringValue
		damageValue.Value = damage
	end
	local totalDamage=attackers:GetAttribute("totalDamage")
	totalDamage=totalDamage or 0
	attackers:SetAttribute("totalDamage",math.clamp(totalDamage+damage,0,playerHit.Character.Humanoid.MaxHealth))
end

local thugRewards = { -- 2x reduction
	["bat"] = 25,
	["ak"] = 50,
	["shotgun"] = 75,
	["flamethrower"] = 125,
	["electric"] = 300,
	["brute"] = 425,
	["minigun"] = 725
}

local function Kills(plr)
	local kills=plr.leaderstats.Kills
	kills.Value+=1
end

local function Multikill(plr)
	if not plr or not plr.leaderstats then return end
	local multikills=plr.leaderstats.temp.multikills
	local elapsed=tick()-multikills.tick.Value
	if elapsed<1 then
		multikills.Value+=1
		--print("multikills=",multikills.Value)
		local reward=100
		plr.leaderstats.Cash.Value+=reward
		--print("multikill rewarded:",plr.Name,reward)
	else 
		multikills.Value=0
	end
	multikills.tick.Value=tick()
end

local combo_abilities={
	["Melee"]=true,
	["Impact Web"]=true,
	["Shotgun Webs"]=true
}

local function Combo(health,player,damage,ability)
	if not (combo_abilities[ability]) then return damage end
	if not (health>0) then return damage end
	local leaderstats=player.leaderstats
	local temp=leaderstats.temp
	local combos=temp.combos
	local elapsed=workspace:GetServerTimeNow()-combos.timer.Value
	if elapsed<1 then -- if within 1 second from last attack, add combo
		combos.Value+=1
	else -- more than 1 second has elapsed, reset the combo
		combos.Value=0
	end
	--print("combos=",combos.Value)
	combos.timer.Value=workspace:GetServerTimeNow()
	local extra_damage=math.round(damage*(combos.Value*.1))
	--print("extra damage=",extra_damage)
	return damage==0 and 0 or damage+extra_damage
end

local function Get_Safe_Zones()
	local t={}
	for i,v in rs.Zones:GetChildren() do 
		t[#t+1]=v
	end
	t[#t+1]=rs.SafeZone
	return t
end

local function checkSafeZones(pos)
	local inSafeZone=false
	local safeZones=Get_Safe_Zones()
	for _,safeZone in safeZones do 
		if _math.checkBounds(safeZone.CFrame,safeZone.Size,pos) then
			return true
		end
	end
	return false
end

_G.damageNPC = function(NPC,player,damage,ability,duration,crit)
	if not NPC then return end
	if player ~= nil then
		damage=Combo(NPC.model.Properties.Health.Value,player,damage,ability)
		--local attackerCharacter = player.Character
		--local attackerInSafeZone = checkSafeZones(attackerCharacter.PrimaryPart.Position)
		--if attackerInSafeZone then return end
		local skin = _G.getEquippedSkin(player)
		if skin and crit then
			local skinLevel = player.leaderstats.skins[skin].Level.Value
			local critical = _math.getSuitCrit(skinLevel)
			local number = crit
			--print("critical = ",number)
			if number <= critical then
				--print("critical hit!")
				damage = math.round(damage * 1.5)
			end
		end
	end

	local isVillain = NPC.model:IsDescendantOf(workspace.Villains)
	local isThug = NPC.model:IsDescendantOf(workspace.Thugs)
	local isDrone = NPC.model:IsDescendantOf(workspace.SpiderDrones)

	local health=NPC.model.Properties.Health
	local maxHealth=NPC.model.Properties.MaxHealth
	local function damageNPC()
		local root = NPC.model.PrimaryPart 
		local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
		local actualDamage = health.Value - newHealth
		health.Value = newHealth -- deal damage
		--print("dealt ",actualDamage," damage")
		NPC.lastAttacked = workspace:GetServerTimeNow()
		if player ~= nil then
			local listing = NPC.attackers[player.Name]
			if listing then
				listing.damage += actualDamage
			else 
				NPC.attackers[player.Name] = {
					damage = actualDamage,
					plr = player
				}	
			end
			NPC.totalDamage=NPC.totalDamage~=nil and math.clamp(NPC.totalDamage+actualDamage,0,maxHealth.Value) or actualDamage
		end
	end

	if isVillain and player~=nil then --// damage protocol for villains
		--// can make separate functionality for different villains here later
		local villain=NPC.model
		if not villain then return end
		local target=villain.PrimaryPart.Position
		local origin=player.Character.PrimaryPart.Position
		local ignoreY=Vector3.new(1,0,1)
		local Within_Horizontal_Range=((target*ignoreY)-(origin*ignoreY)).Magnitude<=NPC.horizontalRange
		local Within_Vertical_Range=math.abs(target.Y-origin.Y)<=NPC.verticalRange
		if Within_Horizontal_Range and Within_Vertical_Range then
			damageNPC()
		else
			--print("was beyond threshold")
			return
		end
	else
		damageNPC()
	end

	local NPCIndex = isDrone and NPC.model.Properties.Tag.Value or NPC.model.Name

	if not isDrone then -- this is a non drone NPC
		if NPC.model.Properties.Health.Value > 0 then
			if player ~= nil then
				createAttackingListing(player,NPC.model)
			end
		end
	else -- this is someone's drone, send the owner's character
		local droneOwner = game.Players:FindFirstChild(NPC.model.Name)
		if droneOwner then
			--print("found drone owner")
			local character = droneOwner.Character
			if character and NPC.model.Properties.Health.Value > 0 then
				if player ~= nil then
					createAttackingListing(player,character)
					createAttackerListing(droneOwner,player,damage)					
				end
			end
		end
	end

	local remote=nil
	if isThug then
		remote = rs.thugs.RemoteEvents:FindFirstChild(NPC.model.Name)
	end

	if isVillain then
		remote = NPC.model.Events.Damage
	end

	if remote then
		if ability == "Melee" then
			for _,playerInstance in (game.Players:GetChildren()) do
				if playerInstance ~= player then
					remote:FireClient(
						playerInstance,
						"Melee",
						NPC.model
					)										
				end
			end
		else
			if ability == "Snare Web" or ability == "Trip Web" or ability == "Anti Gravity" or ability == "Vehicle" then
				local override=ability=="Anti Gravity"
				if ability=="Vehicle" then
					local f=coroutine.wrap(ragdoll.ragdoll)
					f(nil,NPC.model,duration,"recover",isVillain,override,ability)
				else 
					ragdoll.ragdoll(nil,NPC.model,duration,"recover",isVillain,override,ability)
					return
				end
			end
		end
	end

	local function RewardAttackers(reward)
		for i,v in (NPC.attackers) do 
			local plr = v.plr
			if not plr or not plr:IsDescendantOf(game.Players) then continue end 
			local damage=math.clamp(v.damage,0,NPC.totalDamage)
			local isThug=NPC.model:IsDescendantOf(workspace.Thugs)
			local isVillain=NPC.model:IsDescendantOf(workspace.Villains)
			local percent=damage/NPC.totalDamage
			local leaderstats=plr.leaderstats
			local objectives=leaderstats.objectives
			local current=objectives.current
			local objective=items.objectives[current.Value]
			if current.Value<=#items.objectives then -- only detect if you still have an objective
				if isThug then
					local category=objective.category
					if category and NPC.model.Properties.Type.Value==category and percent>=.25 then
						objectives.amount.Value=math.clamp(objectives.amount.Value+1,0,objective.amount)
					end
				end
				if isVillain then
					if current.Value==#items.objectives then
						objectives.amount.Value=math.clamp(objectives.amount.Value+1,0,objective.amount)
					end
				end
			end
			local amount= math.ceil((damage/NPC.totalDamage)*reward) -- award the player for their respective damage
			--print(plr.Name,"dealt",v.damage,"damage")
			rewards:RewardPlayer(plr,"Money",amount)
			if isVillain then
				spawn(function()
					if NPC.model.BossName.Value=="Venom" then
						Process_Badges(plr,"Venom Smasher!")
					elseif NPC.model.BossName.Value=="Green Goblin" then
						Process_Badges(plr,"Goblin Exterminator!")
					elseif NPC.model.BossName.Value=="Doc Ock" then 
						Process_Badges(plr,"Octopus Cooker!")
					end
				end)
			end
		end
	end

	local success,errorMessage = pcall(function()
		if health.Value == 0 and not cs:HasTag(NPC.model,"Died") then
			cs:AddTag(NPC.model,"Died")
			if player~=nil then
				Multikill(player)
			end
			-- work out the damage, give money to
			if isThug then
				if ability=="Gauntlet" then
					rs.AshEvent:FireAllClients(NPC.model)
				end
				rewards:CreateDrop(NPC.model.PrimaryPart.Position,maxHealth.Value,nil,nil,ability=="Gauntlet")
				local _type = NPC.model.Properties.Type
				local reward=thugRewards[_type.Value]
				RewardAttackers(reward)
				ragdoll.ragdoll(nil,NPC.model,0,nil)
				wait(3) -- wait here cause thugs need to ragdoll for a bit before removal
			elseif isVillain then
				--// create support for different villains later
				local waitTime=5
				if ability=="Gauntlet" then
					rs.AshEvent:FireAllClients(NPC.model)
					waitTime=3
				end
				local reward=maxHealth.Value--maxHealth.Value*2
				rewards:CreateDrop(NPC.model.PrimaryPart.Position,reward,nil,nil,ability=="Gauntlet")
				RewardAttackers(reward)
				ragdoll.ragdoll(nil,NPC.model,0,nil,true)
				wait(waitTime) -- wait 5 seconds before villain gets destroyed after it died
			elseif isDrone then
				local droneOwner = game.Players:FindFirstChild(NPC.model.Name)
				rewards:CreateDrop(NPC.model.PrimaryPart.Position,maxHealth.Value,droneOwner and droneOwner.Name or nil,nil,ability=="Gauntlet") 
				-- amount of money given needs to be according to how much health
				local reward=math.round(50*(NPC.model.Properties.MaxHealth.Value/100))
				RewardAttackers(reward)
				wait(3)
			end
			local path = NPC.path
			if remote then remote:Destroy() end
			if path then path:Destroy() end
			NPC.model:Destroy()
			local part=NPCs[NPCIndex].part
			if part then
				part:Destroy()
			end
			NPCs[NPCIndex].clear(NPCs[NPCIndex])
			NPCs[NPCIndex] = nil
		end	
	end)

	if errorMessage then
		print("ERROR:",errorMessage)
	end
end

local function rewardPlayerAttackers(player,baseCash,totalDamage)
	local attackers = player.leaderstats.attackers
	for i,v in (attackers:GetChildren()) do 
		local plr = game.Players:FindFirstChild(v.Name)
		if plr then
			local totalDamage=totalDamage or attackers:GetAttribute("totalDamage")
			totalDamage=totalDamage or 0
			local damage=math.clamp(v.damage.Value,0,totalDamage)
			if damage==0 then continue end -- don't try to reward if the damage is 0
			local reward=math.ceil(math.clamp(damage/totalDamage,0,1) * baseCash)
			rewards:RewardPlayer(plr,"Money",reward)
		end
	end
	attackers:ClearAllChildren()
	local attacking = player.leaderstats.attacking
	attacking:ClearAllChildren()
	attackers:SetAttribute("totalDamage",0)
end

_G.damagePlayer = function(character,playerWhoHit,damage,ability,duration,crit)
	local playerHit = game.Players:GetPlayerFromCharacter(character)
	if not character then return end -- verify character model exists
	if not (character.Humanoid.Health>0) then return end
	if not playerHit then return end -- verify character is a player

	local lastRespawn=playerHit:GetAttribute("LastRespawn")
	if lastRespawn and tick()-lastRespawn<3 then -- don't allow player to recieve any damage for 3 seconds after they respawn
		--print("was within 3 seconds from last respawn!")
		return 
	end

	if playerWhoHit ~= nil then
		local attackerCharacter = playerWhoHit.Character
		local victimCharacter = character 
		if not attackerCharacter then return end
		if not attackerCharacter.PrimaryPart or not victimCharacter.PrimaryPart then return end
		if playerWhoHit.leaderstats.temp.PvP.Value==false then return end
		if playerHit.leaderstats.temp.PvP.Value==false then return end
		--// change this to the group of safe zones
		local safeZone = rs.SafeZone
		local attackerInSafeZone = checkSafeZones(attackerCharacter.PrimaryPart.Position)
		--print("attacker in safe zone=",attackerInSafeZone)
		local victimInSafeZone = checkSafeZones(victimCharacter.PrimaryPart.Position)
		--print("victim in safe zone=",victimInSafeZone)
		if attackerInSafeZone or victimInSafeZone then return end
		damage=Combo(character.Humanoid.Health,playerWhoHit,damage,ability)
		local skin = _G.getEquippedSkin(playerWhoHit)
		if skin and crit then
			local skinLevel = playerWhoHit.leaderstats.skins[skin].Level.Value
			local critical = _math.getSuitCrit(skinLevel)
			local number = crit
			--print("critical = ",number)
			if number <= critical then
				--print("critical hit!")
				damage = math.round(damage * 1.5)
			end
		end
		playerWhoHit:SetAttribute("LastCombat",workspace:GetServerTimeNow())
		playerHit:SetAttribute("LastCombat",workspace:GetServerTimeNow())
	end

	local playerHitLeaderstats = playerHit:WaitForChild("leaderstats")
	local playerHitTemp = playerHitLeaderstats:WaitForChild("temp")
	local isRolling = playerHitTemp:WaitForChild("isRolling")

	if isRolling.Value then return end

	--character.Humanoid:TakeDamage(damage)
	character.Humanoid.Health -= damage
	--print("dealt ",damage," damage")

	if playerWhoHit ~= nil then
		createAttackerListing(playerHit,playerWhoHit,damage)
		createAttackingListing(playerWhoHit,character)			
	end

	local ragdollData = playerHit.leaderstats.ragdollData
	local start = ragdollData.start
	local _duration = ragdollData.duration

	local indicators = playerHit.leaderstats.indicators
	if playerWhoHit ~= nil then
		local listing = indicators:FindFirstChild(playerWhoHit.Name)
		if not listing then
			addDamageIndicator(indicators,playerWhoHit.Name,playerWhoHit.Character.PrimaryPart)			
		end		
	end

	if ability == "Melee" then
		local meleeEvent = rs.MeleeEvent
		for _,playerInstance in (game.Players:GetChildren()) do
			if playerInstance ~= playerWhoHit then
				meleeEvent:FireClient(
					playerInstance,
					"Melee",
					character
				)										
			end
		end
	elseif ability == "Snare Web" or ability == "Trip Web" or ability == "Anti Gravity" or ability == "Vehicle" then
		ragdoll.ragdoll(playerHit,character,duration,"recover")
		return
		--[[
		if start.Value ~= "" then
			local remaining = _duration.Value - (workspace:GetServerTimeNow() - tonumber(start.Value))
			if duration > remaining then -- only change ragdoll data if new duration is longer
				start.Value = workspace:GetServerTimeNow()
				_duration.Value = duration		
				ragdoll.ragdoll(playerHit,character,duration,"recover")
			else
				print("duration wasn't long enough to change")
				print(remaining,duration)
			end
		else
			start.Value = workspace:GetServerTimeNow()
			_duration.Value = duration
			ragdoll.ragdoll(playerHit,character,duration,"recover")
		end
		]]
	end

	if not (character.Humanoid.Health > 0) and not cs:HasTag(character,"Died") then
		cs:AddTag(character,"Died")
		if ability=="Gauntlet" then
			rs.AshEvent:FireAllClients(character)
		end
		if playerWhoHit~=nil then
			Multikill(playerWhoHit)
			Kills(playerWhoHit)
		end
		_duration.Value = 0
		start.Value = workspace:GetServerTimeNow()
		rewards:CreateDrop(character.PrimaryPart.Position,character.Humanoid.MaxHealth,playerHit.Name,nil,ability=="Gauntlet")
	end
end

local function rangedRaycastCheck(origin,direction)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {
		workspace.BuildingBounds,
		workspace.FireEscapes,
		workspace.StreetLamp,
		workspace.Trash,
		workspace.billboards,
		workspace.Trees,
		--workspace.Rock1,
		workspace.BarrelFire1
	}
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local function generate8DigitNumber()
	local rand = math.random(0, 99999999)
	local randLen = tonumber(string.len(tostring(rand)))
	if randLen < 8 then
		rand = string.rep("0", 8 - randLen)..rand
	end
	return rand
end

--print(generate8DigitNumber())

local function webBombRay(origin,direction)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {
		workspace:WaitForChild("Buildings"),
		workspace:WaitForChild("StreetLamp"),
		workspace:WaitForChild("Trash"),
		workspace:WaitForChild("BarrelFire1"),
		workspace:WaitForChild("Trees"),
		--workspace:WaitForChild("Rock1"),
		workspace:WaitForChild("FireEscapes")
	}
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local function createHitbox(cframe,size,partType,owner,tag)
	local hitbox = Instance.new("Part")
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.Name = "hitbox"
	hitbox.BrickColor = BrickColor.Red()
	hitbox.Shape = partType
	hitbox.Transparency = 1
	hitbox.Size = size
	hitbox.CFrame = cframe
	local _owner=Instance.new("StringValue")
	_owner.Name = "owner"
	_owner.Value=owner
	_owner.Parent=hitbox
	local _tag=Instance.new("StringValue")
	_tag.Name="tag"
	_tag.Value=tag
	_tag.Parent=hitbox
	local modifier = Instance.new("PathfindingModifier")
	modifier.Label = "TripWeb"
	modifier.PassThrough = true
	modifier.Parent = hitbox
	hitbox.Parent = workspace.Trip_Web_Hitboxes
	return hitbox
end

local function clear(dict)
	for i,v in dict do 
		v=nil
		dict[i]=nil
	end
end

local soundEvent = rs.SoundEvent
local rebirthEvent = rs.RebirthEvent
local levelEvent = rs.LevelEvent
local respawnEvent = rs.Respawn

local Danger_Event = rs.DangerEvent

local civs = workspace.Civilians

local triggers={
	["Melee"] = {
		["Punch"]=10,
		["Kick"]=10,
		["360 Kick"]=10
	},
	["Ranged"] = {
		["Impact Web"]=100,
		["Snare Web"]=100,
		["Shotgun Webs"]=100,
	},
	["Special"] = {
		["Spider Drone"]=100,
		["Web Bomb"]=100,
	},
	["Traps"] = {
		["Anti Gravity"] = 100,
		["Trip Web"] = 100
	},
	["HardFall"]={
		["Landed"]= 100
	}
}

local function Danger_Event_Ray(origin,direction)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {
		workspace:WaitForChild("Buildings"),
	}
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local cooldowns={}

local function Get_Nearby(pos,limit)
	local nearby={}
	for _,group in (workspace.Civilians:GetChildren()) do 
		for _,civilian in (group:GetChildren()) do
			if (pos-civilian.Value.Position).Magnitude <= limit then
				nearby[#nearby+1]=civilian
			end
		end
	end
	return nearby
end

local function Danger(...)
	local args={...}
	local plr=args[1]
	local main_category=args[2]
	local sub_category=args[3]
	if not triggers[main_category][sub_category] then return end
	local reference_name=args[4] -- this is the tag/reference for the ability attack
	local pos = args[5] -- position to compare from
	local nearby=args[6] and args[6] or Get_Nearby(pos,triggers[main_category][sub_category]) -- this is a table of nearby, if doesn't exist, it will create 
	local range=args[7]
	--print(main_category,sub_category,"made it here1")
	if not cooldowns[plr] then
		cooldowns[plr]=tick()-.25
	end
	if not (tick()-cooldowns[plr]>=.25) then return end
	cooldowns[plr] = tick()
	--print(main_category,sub_category,"made it here2")
	if main_category == "Ranged" then
		if not liveProjectiles[reference_name] or liveProjectiles[reference_name].plr ~= plr then return end	
	elseif main_category == "Melee" then
		if not liveMelee[reference_name] or liveMelee[reference_name].plr ~= plr then return end
	elseif main_category == "Traps" then
		if sub_category == "Anti Gravity" then
			local listing = verified_gravity_bombs:FindFirstChild(reference_name)
			if not listing or listing.Value ~= plr.Name then return end
		elseif sub_category == "Trip Web" then
			local leaderstats = plr.leaderstats
			local tripWebFolder = leaderstats:WaitForChild("temp"):WaitForChild("tripWebs")
			local TripWebAmount = tripWebFolder:WaitForChild("serverAmount")
			local listing = TripWebAmount:FindFirstChild(reference_name)
			if not listing then return end
		end
	elseif main_category == "Special" then
		if sub_category == "Spider Drone" then
			local listing1 = NPCs[reference_name]
			local listing2 = liveProjectiles[reference_name]
			local option1=listing1 and listing1.owner==plr
			local option2=listing2 and listing2.plr==plr
			if option1==false and option2==false then return end
		elseif sub_category == "Web Bomb" then
			local listing = verified_web_bombs:FindFirstChild(reference_name)
			if not listing or (listing.Value ~= plr.Name) then return end 
		end
	end
	--print(main_category,sub_category,"made it here3")
	for _,civilian in (nearby) do 
		local origin = pos
		local goal = civilian.Value.Position
		local d=(origin-goal).Magnitude
		range=triggers[main_category][sub_category] or range
		if d > range then continue end
		local direction = (goal-origin).Unit*d
		local result = Danger_Event_Ray(origin,direction)
		if not result then
			civilian.checkFleeing.Value = true
		end
	end

end

Danger_Event.OnServerEvent:Connect(Danger)

local rs=game:GetService("ReplicatedStorage")
local LeaderboardEvent=rs.LeaderboardEvent
local Leaderboards=require(script.Leaderboards)

Leaderboards.Sorted_Cash={}
Leaderboards.Sorted_Killstreak={}
Leaderboards.Sorted_Donations={}

local function changeRigSize(rig,height,width,depth,headSize)
	local humanoid = rig:WaitForChild("Humanoid")
	if humanoid then
		if not (humanoid:FindFirstChild("BodyHeightScale")) then -- if it doesn't have this
			--print("didn't find BodyHeightScale, making one!")
			local _bodyHeightScale = Instance.new("NumberValue")
			_bodyHeightScale.Name = "BodyHeightScale"
			_bodyHeightScale.Parent = humanoid
			_bodyHeightScale.Value = height
		else -- if it has it already
			--print("found BodyHeightScale, scaling!")
			humanoid.BodyHeightScale.Value = height
		end
		if not (humanoid:FindFirstChild("BodyWidthScale")) then -- if it doesn't have this
			local _bodyWidthScale = Instance.new("NumberValue")
			_bodyWidthScale.Name = "BodyWidthScale"
			_bodyWidthScale.Parent = humanoid
			_bodyWidthScale.Value = width
		else -- if it has it already
			humanoid.BodyWidthScale.Value = width
		end
		if not (humanoid:FindFirstChild("BodyDepthScale")) then -- if it doesn't have this
			local _bodyDepthScale = Instance.new("NumberValue")
			_bodyDepthScale.Name = "BodyDepthScale"
			_bodyDepthScale.Parent = humanoid
			_bodyDepthScale.Value = depth
		else -- if it has it already
			humanoid.BodyDepthScale.Value = depth
		end
		if not (humanoid:FindFirstChild("HeadScale")) then -- if it doesn't have this
			local _headScale = Instance.new("NumberValue")
			_headScale.Name = "HeadScale"
			_headScale.Parent = humanoid
			_headScale.Value = headSize
		else -- if it has it already
			humanoid.HeadScale.Value = headSize
		end
	end
end

local function Update_Top_Donor_Avatar(id,name)
	local Humanoid=workspace.Top_Donator_Rig.Humanoid
	local HumanoidDescription = game:GetService("Players"):GetHumanoidDescriptionFromUserId(id)
	Humanoid:ApplyDescription(HumanoidDescription)
	--local TopDonorUI=workspace.Top_Donator_Rig.Head.TopDonor
	--TopDonorUI["2"].Text=name
	changeRigSize(workspace.Top_Donator_Rig,1,1,1,1)
end

local function Update_Folder(folder:Folder, t:{})
	Leaderboards.Sorted_Cash=folder.Name=="Top Cash" and t or Leaderboards.Sorted_Cash
	Leaderboards.Sorted_Killstreak=folder.Name=="Top Killstreak" and t or Leaderboards.Sorted_Killstreak
	Leaderboards.Sorted_Donations=folder.Name=="Top Donors" and t or Leaderboards.Sorted_Donations
	folder:ClearAllChildren() -- don't worry, client only reads .ChildAdded
	for index,data in t do 
		local _folder=Instance.new("Folder")
		_folder.Name=index
		_folder.Parent=folder
		local NumberValue=Instance.new("NumberValue")
		NumberValue.Name=data.name
		NumberValue.Value=data.amount
		NumberValue:SetAttribute("id",data.id)
		NumberValue.Parent=_folder
	end
	if folder.Name=="Top Donors" then
		Update_Top_Donor_Avatar(t[1].id,t[1].name)
	end
	--print("server updated",folder.Name)
	folder:SetAttribute("LastUpdate",tick()) -- clients read from this
end

local function Update_Folders(cash:{}, killstreak:{})
	Update_Folder(rs["Top Cash"],cash)
	Update_Folder(rs["Top Killstreak"],killstreak)
end

task.spawn(function()
	Update_Folder(rs["Top Cash"],Leaderboards:FetchCash())
	Update_Folder(rs["Top Killstreak"],Leaderboards:FetchKills())
	Update_Folder(rs["Top Donors"],Leaderboards:FetchDonations())
end)

local lastRefresh=tick()

local function Sort_Greatest(a,b)
	return a.amount>b.amount
end

-- whenever a player gets enough money to be on the board but the refresh is a long ways off
-- this may end up looking entirely different when it eventually gets refreshed, but for instant effect do this.
local function Shallow_Update_Folders(player:Player, amount:number, folder:Folder, t:{})
	--print("shallow updated for",player.Name,folder.Name)
	local elapsed=tick()-lastRefresh
	if elapsed>=59 then -- you only have to wait 1 sec for it to update, just wait.
		--print("there was only ",tick()-lastRefresh," seconds left till refresh") 
		return 
	end 
	if elapsed<=1 then -- the board was recently refreshed, don't update.
		--print("the board was refreshed only",elapsed," seconds ago! don't update")
		return
	end
	--print("updating board!")
	local on_board=false
	for index,data in t do -- check if player is already on the board
		if data.name==player.Name then
			on_board=true
			data.amount=amount -- update the amount
		end
	end
	-- if player isn't on the leaderboard but has higher value than the last listing on the leaderboard
	if not on_board then
		local pos=#t
		if folder.Name=="Top Donors" then
			pos=#t<50 and #t+1 or #t
		end
		t[#t]={name=player.Name,amount=amount,id=player.UserId}
	end
	table.sort(t,Sort_Greatest)
	Update_Folder(folder,t)
end

local badgeService=game:GetService("BadgeService")

local new_suits={
	["ATSV India"] = true,
	["ATSV Miles"]=true,
	["ATSV 2099"]=true,
	["ATSV Punk"]=true,
	["ATSV Scarlet"]=true,
	["Miles 2099"]=true,
	["Mayday Parker"]=true,
	["Spider Woman"]=true
}

local function addValues(dataFolder)
	local Cash=Instance.new("IntValue")
	Cash.Name="Cash"
	Cash.Parent=dataFolder
	local Rebirths=Instance.new("IntValue")
	Rebirths.Name="Rebirths"
	Rebirths.Parent=dataFolder
	local Kills=Instance.new("IntValue")
	Kills.Name="Kills"
	Kills.Parent=dataFolder
	local active=Instance.new("BoolValue")
	active.Name="active"
	active.Parent=Kills
	local _tick=Instance.new("StringValue")
	_tick.Name="tick"
	_tick.Value="0"
	_tick.Parent=Kills
	local comic=Instance.new("IntValue")
	comic.Name="Comic pages"
	comic.Parent=dataFolder
end

local function get_time_from_seconds(seconds)
	return seconds/60/60
end

--[[
local profileService=require(rs.ProfileService)

local function remove_cash_data()
	local userIDs={
		
		"4440922822",
		"2463032173",
		"2737449310",
		"3243578805",
		"2692949629"
		
		--"14664696"
	}
	local profileStore = profileService.GetProfileStore(
		"Player",
		dataManager.defaultData
	)
	for _,id in userIDs do 
		local profile = profileStore:LoadProfileAsync(
			"Player_"..id,
			"ForceLoad" 
		)
		if profile then
			local data=profile.Data
			profile.Data=dataManager.defaultData
			print("cash amount=",data.cash)
			profile:Release()
		end
		
	end
end

remove_cash_data()
]]

_G.prepareCharacter=function(player,character)
	if cs:HasTag(character,"prepared") then return end
	cs:AddTag(character,"prepared")
	local dataFolder=player.leaderstats
	if not (player:HasAppearanceLoaded()) then -- if it hasn't loaded yet, wait until it's loaded
		player.CharacterAppearanceLoaded:wait()
	end
	characterCollisionGroup(character)
	addModifiers(character,"ignore",true)
	local root = character:FindFirstChild("HumanoidRootPart")
		--[[
		local hasDrone = workspace.SpiderDrones:FindFirstChild(player.Name)
		if hasDrone then
			local target = hasDrone.Properties.Target 
			if target.Value.Name == player.Name then
				target.Value = character
			end
		end
		]]
	if root then
		for index, sound in (cloneSounds) do
			local clone = sound:Clone()
			clone.Parent = root
		end
	end

	--UndoAllSkins(dataFolder.skins)

	--local neck = character:FindFirstChild("UpperTorso"):FindFirstChild("NeckRigAttachment")
	--if not (neck) then
	--repeat task.wait(1/30) until (neck)
	--end

	ragdoll.setupJoints(character)

	--print("set up joints")

	local humanoid = character:WaitForChild("Humanoid")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
	humanoid.BreakJointsOnDeath = false

	if tonumber(dataFolder.temp.previousHealth.Value) then
		local multiple=tonumber(dataFolder.temp.previousHealth.Value)
		--print("multiple=",multiple)
		humanoid.Health = humanoid.MaxHealth*multiple
	end

	task.wait(1/30)

		--[[
		local webBomb = rs:WaitForChild("WebBombTool"):Clone()
		webBomb.Name = "ServerWebBomb"
		if webBombEquipped.Value == false then
			webBomb.Handle.Transparency = 1		
		end
		webBomb.Parent = character

		local gravityBomb = rs:WaitForChild("AntiGravityTool"):Clone()
		gravityBomb.Name = "ServerGravityBomb"
		if gravityBombEquipped.Value == false then
			gravityBomb.Handle.Transparency = 1		
		end
		gravityBomb.Parent = character

		local spiderDrone = rs:WaitForChild("SpiderDroneTool"):Clone()
		spiderDrone.Name = "ServerSpiderDrone"
		if spiderDroneEquipped.Value == false then
			spiderDrone.Handle.Transparency = 1
			spiderDrone.Handle.Propeller.Transparency = 1
			spiderDrone.Handle.Propeller.blur.SurfaceGui.Enabled = false			
		end
		spiderDrone.Parent = character
		]]

end

_G.putOnSkin=function(plr,skin,cframe)
	local oldCharacter = plr.Character
	local oldHumanoid = oldCharacter.Humanoid
	local oldHealth = oldHumanoid.Health
	local oldMaxHealth = oldHumanoid.MaxHealth 
	local newCharacter = characters[skin]:Clone()
	local humanoid = newCharacter.Humanoid
	local dataFolder=plr.leaderstats
	local level = dataFolder.skins[skin].Level.Value
	local extraHealth = _math.getSuitHealth(level)
	local maxHealth = extraHealth + 100
	humanoid.MaxHealth = maxHealth
	local equippedSkin = _G.getEquippedSkin(plr)
	if equippedSkin and equippedSkin == skin then
		humanoid.Health = maxHealth
	else
		if oldHealth > maxHealth then
			humanoid.Health = maxHealth
		else 
			if oldHealth >= oldMaxHealth then -- if you had full health, give full health
				humanoid.Health = maxHealth
			else 
				humanoid.Health = oldHealth
			end
		end			
	end
	humanoid.DisplayName = plr.Name
	newCharacter.Name = plr.Name

	local healthScript = newCharacter.Health
	healthScript.Disabled = false
	if cframe ~= nil then
		newCharacter:SetPrimaryPartCFrame(cframe)
	end

	plr.Character = newCharacter
	newCharacter.Parent = workspace

	oldCharacter:Destroy()

	UndoAllSkins(dataFolder.skins)
	dataFolder.skins[skin].Equipped.Value = true

	_G.prepareCharacter(plr,plr.Character)
end

local function onPlayerAdded(player:Player)
	if cs:HasTag(player,"Added") then return end
	cs:AddTag(player,"Added")
	player:SetAttribute("LastRespawn",tick())
	player:SetAttribute("LastAttacked",workspace:GetServerTimeNow()-10)
	
	local dataCopy=dataManager:Get(player)
	if not dataCopy then
		repeat task.wait(1/30) dataCopy=dataManager:Get(player) until dataCopy
	end
	
	local RootCFrame = Instance.new("CFrameValue")
	RootCFrame.Name = "LastRootCFrame"
	RootCFrame.Parent = player
	
	local CameraCFrame = Instance.new("CFrameValue")
	CameraCFrame.Name = "LastCameraCFrame"
	CameraCFrame.Parent = player
	
	local dataFolder = script.leaderstats:Clone()
	addValues(dataFolder)
	
	--update the impact web!
	if dataCopy.abilities.Ranged["Impact Web"].Unlocked==false then
		dataCopy.abilities.Ranged["Impact Web"].Unlocked=true
		local found_impact_web=false
		local empty_slot=nil
		for i=1,#dataCopy.hotbar do 
			--print(i)
			local data=dataCopy.hotbar[i]
			if data.Ability=="Impact Web" then -- found impact web in hotbar
				found_impact_web=true
			end
			if data.Ability=="" and empty_slot==nil then -- always get the lowest number
				empty_slot=i
			end
		end
		if found_impact_web==false and empty_slot then -- doesn't have impact web in hotbar, but has an open slot!
			dataCopy.hotbar[empty_slot].Ability="Impact Web"
			dataCopy.hotbar[empty_slot].Category="Ranged"
		end
	end
	
	for category,abilityTable in (dataCopy.abilities) do
		local categoryFolder = dataFolder.abilities[category]
		for abilityName,abilityData in (abilityTable) do
			local abilityFolder = categoryFolder[abilityName]
			for data,value in (abilityData) do
				local valueInstance = abilityFolder[data]
				valueInstance.Value = value
			end
		end
	end
	
	--incentives
	for key,value in dataCopy.incentives do
		dataFolder.incentives[key].Value=value
	end
	
	-- hotbar
	for slot,data in (dataCopy.hotbar) do
		local folder = dataFolder.hotbar[slot]
		folder.Ability.Value = data.Ability
		folder.Category.Value = data.Category
	end
	
	-- test
	--dataCopy.skins["Gwen"]=true
	
	-- skins
	for valueName,value in (dataCopy.skins) do
		if not dataFolder.skins:FindFirstChild(valueName) then continue end
		local Level = dataFolder.skins[valueName].Level
		local Unlocked = dataFolder.skins[valueName].Unlocked
		local Equipped = dataFolder.skins[valueName].Equipped
		if typeof(value)~="table" then -- if it's not a table, renew this data with default datastore values!
			--print("found",valueName,"was not a table!")
			--print("changing it to:")
			for i,v in dataManager.defaultData.skins[valueName] do 
				--print(i,v)
			end
			dataCopy.skins[valueName]=dataManager.defaultData.skins[valueName]
			local copy=dataCopy.skins[valueName]
			Level.Value = copy.Level
			Unlocked.Value = copy.Unlocked
			Equipped.Value = copy.Equipped
			continue
		end
		Level.Value = value.Level
		Unlocked.Value = value.Unlocked
		Equipped.Value = value.Equipped
	end
	
	-- gamepasses
	for valueName,value in dataCopy.gamepasses do 
		local boolValue=dataFolder.gamepasses[valueName]
		boolValue.Value=value
	end
	
	-- codes 
	for code,data in dataManager.defaultData.codes do 
		if not dataCopy.codes[code] then
			dataCopy.codes[code]=data
		end
	end
	
	for valueName,value in dataCopy.codes do 
		local folder=dataFolder.codes:FindFirstChild(valueName)
		if folder then
			folder.Redeemed.Value=value.Redeemed
			folder.Reward.Value=value.Reward
		end
		--print(valueName,"redeemed=",value.Redeemed,"reward=",value.Reward)
	end
	
	-- tutorial
	if dataCopy.tutorial.Roll==nil then -- update the tutorial!
		dataCopy.tutorial.Roll=false
		dataCopy.tutorial.Drag=false
	end
	
	for valueName,value in dataCopy.tutorial do
		local boolValue=dataFolder.tutorial[valueName]
		boolValue.Value=value
	end
	
	--portals
	if not dataCopy.FiskPortalReset then -- reset portals first
		dataCopy.FiskPortalReset=true 
		dataCopy.portals["minigun"]=false
	end
	
	for valueName,value in dataCopy.portals do 
		local boolValue=dataFolder.portals[valueName]
		boolValue.Value=value
	end
	
	if not dataCopy.kills or dataCopy.killstreak>dataCopy.kills then -- set the kills to their killstreak
		dataCopy.kills=dataCopy.killstreak
	end
	
	if not dataCopy["comic pages"] then
		dataCopy["comic pages"]=0
	end
	
	dataFolder.Cash.Value = dataCopy.cash
	dataFolder.Kills.Value=dataCopy.kills
	dataFolder.Rebirths.Value = dataCopy.rebirths
	dataFolder["Comic pages"].Value = dataCopy["comic pages"]
	dataFolder.temp.dataLoaded.Value = true
	dataFolder.Parent = player
	
	if dataFolder.Rebirths.Value>=1 then -- turn PvP on by default if the player has at least 1 rebirth
		dataFolder.temp.PvP.Value=true
	end
	
	-- objectives
	local function resetStealthSkin()
		dataCopy.skins["Stealth"].Level = 1
		dataCopy.skins["Stealth"].Unlocked = false
		dataCopy.skins["Stealth"].Equipped = false
		
		dataFolder.skins["Stealth"].Level.Value=1
		dataFolder.skins["Stealth"].Unlocked.Value=false
		dataFolder.skins["Stealth"].Equipped.Value=false
	end
	
	local function resetSupremeSkin()
		dataCopy.skins["Supreme Sorcerer"].Level = 1
		dataCopy.skins["Supreme Sorcerer"].Unlocked = false
		dataCopy.skins["Supreme Sorcerer"].Equipped = false
		
		dataFolder.skins["Supreme Sorcerer"].Level.Value=1
		dataFolder.skins["Supreme Sorcerer"].Unlocked.Value=false
		dataFolder.skins["Supreme Sorcerer"].Equipped.Value=false
	end
	
	if dataCopy.suitsWipe==false then
		--print("wiping suits")
		dataCopy.suitsWipe=true
		for name,data in dataCopy.skins do 
			if new_suits[name] then
				data.Level=1
				data.Unlocked=false
				data.Equipped=false
				dataFolder.skins[name].Level.Value=1
				dataFolder.skins[name].Unlocked.Value=false
				dataFolder.skins[name].Equipped.Value=false
			end
		end
	end
	
	if dataCopy.objectivesWiped==false then
		--print("wiping objectives")
		dataCopy.objectivesWiped=true
		dataCopy.objectives.completed=false
		dataCopy.objectives.talkedWithPolice=false
		dataCopy.objectives.usedFirstPortal=false
		dataCopy.objectives.amount=0
		dataCopy.objectives.current=1
		resetStealthSkin()
	end
	
	if dataCopy.objectives.completed==false then -- if they haven't completed the objectives before then make sure they don't have the stealth skin
		resetStealthSkin()
	end
	
	if dataCopy.rebirths<10 then
		resetSupremeSkin()
	end
	
	local objective=items.objectives[dataCopy.objectives.current]
	if objective then
		if dataCopy.objectives.amount>=objective.amount and objective.amount>0 then -- if you have more amount than required (rare case)
			-- reward the player and increase the objective
			--print("did this")
			dataCopy.objectives.amount=0
			dataCopy.objectives.current+=1
			dataFolder.objectives.amount.Value=0
			dataFolder.objectives.current.Value+=1
			rewards:RewardPlayer(player,"Money",objective.reward)
		end
	end
	
	if dataCopy.objectives.current>#items.objectives then -- rest the objective!
		dataCopy.objectives.current=1
	end
	
	-- load the objectives value
	for key,value in dataCopy.objectives do 
		dataFolder.objectives[key].Value=value
	end
	
	if not dataCopy.donated then -- doesn't have the donated data
		dataCopy.donated=dataManager.defaultData.donated
	end
	dataFolder.Donations.Donated.Value=dataCopy.donated
	
	EP.Calculate(player) -- this will set the EarningsBoost value for the player
	
	for _,value in dataFolder.incentives:GetChildren() do 
		value:GetPropertyChangedSignal("Value"):Connect(function()
			dataCopy.incentives[value.Name]=value.Value
		end)
	end
	
	spawn(function()
		Process_Badges(player)
	end)
	
	dataFolder.Donations.Donated:GetPropertyChangedSignal("Value"):Connect(function()
		dataCopy.donated = dataFolder.Donations.Donated.Value
		local t=Leaderboards.Sorted_Donations
		if t[#t].amount<dataFolder.Donations.Donated.Value or #t<50 then
			Shallow_Update_Folders(player, dataFolder.Donations.Donated.Value, rs["Top Donors"], t)
		end
	end)
	
	dataFolder.Cash:GetPropertyChangedSignal("Value"):Connect(function()
		if dataFolder.Cash.Value<0 then dataFolder.Cash.Value=dataCopy.cash return end -- under any circumstances do not change cash to negative
		dataCopy.cash = dataFolder.Cash.Value
		rs.CashEvent:FireAllClients(player)
		local t=Leaderboards.Sorted_Cash
		if t[#t].amount<dataFolder.Cash.Value then
			Shallow_Update_Folders(player, dataFolder.Cash.Value, rs["Top Cash"], t)
		end
		if dataFolder.Cash.Value>=1000000 then
			Process_Badges(player,"Your first million!")
		end
	end)
	
	dataFolder["Comic pages"]:GetPropertyChangedSignal("Value"):Connect(function()
		if dataFolder["Comic pages"].Value<0 then dataFolder["Comic pages"].Value=dataCopy["comic pages"] return end -- under any circumstances do not change comic pages to negative
		dataCopy["comic pages"] = dataFolder["Comic pages"].Value
		rs.ComicEvent:FireAllClients(player)
	end)
	
	dataFolder.Kills:GetPropertyChangedSignal("Value"):Connect(function()
		--print(player.Name,"Killstreak changed to",dataFolder.Killstreak.Value)
		dataCopy.kills=dataFolder.Kills.Value
		local t=Leaderboards.Sorted_Killstreak
		if t[#t].amount<dataFolder.Kills.Value then
			Shallow_Update_Folders(player, dataFolder.Kills.Value, rs["Top Killstreak"], t)
		end
		if dataFolder.Kills.Value>=1000 then
			Process_Badges(player,"You are a killing machine!")
		end
	end)
	
	dataFolder.Rebirths:GetPropertyChangedSignal("Value"):Connect(function()
		dataCopy.rebirths = dataFolder.Rebirths.Value
		dataFolder.objectives.talkedWithPolice.Value=true
		dataFolder.objectives.usedFirstPortal.Value=true
		dataFolder.objectives.amount.Value=0
		dataFolder.objectives.current.Value=1
		if dataFolder.Rebirths.Value==10 then
			Process_Badges(player,"You're the goat!")
		end
	end)
	
	dataFolder.gamepasses["Collector"]:GetPropertyChangedSignal("Value"):Connect(function()
		dataCopy.gamepasses["Collector"] = dataFolder.gamepasses["Collector"].Value
		levelEvent:FireAllClients(player)
	end)
	
	for index,value in dataFolder.tutorial:GetChildren() do 
		value:GetPropertyChangedSignal("Value"):Connect(function()
			dataCopy.tutorial[value.Name]=value.Value
		end)
	end
	
	local function update_portals(n,completed)
		if completed then
			for name,number in items.Portals do 
				local portalValue=dataFolder.portals:FindFirstChild(name)
				if portalValue then
					portalValue.Value=true -- auto unlock portals!
				end
			end
			return
		end
		for name,number in items.Portals do 
			if n==number then
				local portalValue=dataFolder.portals:FindFirstChild(name)
				if portalValue then
					portalValue.Value=true -- auto unlock portals!
				end
			end
		end
	end
	
	for index,value in dataFolder.objectives:GetChildren() do 
		value:GetPropertyChangedSignal("Value"):Connect(function()
			dataCopy.objectives[value.Name]=value.Value
			if value.Name=="amount" then
				local objective=items.objectives[dataFolder.objectives.current.Value]
				if value.Value>=objective.amount then
					rewards:RewardPlayer(player,"Money",objective.reward)
					dataFolder.objectives.amount.Value=0 -- reset the amount!
					dataFolder.objectives.current.Value+=1 -- advance to next objective!
				end
			end
			if value.Name=="current" then 
				if value.Value>#items.objectives then-- completed all objectives!
					dataFolder.objectives.completed.Value=true
					--if dataFolder.Rebirths.Value==10 then
						value.Value=1 -- reset it if u have 10 rebirths already!
					--end
				end
				-- update portal(s)!
				update_portals(value.Value,dataFolder.objectives.completed.Value)
			end
		end)
		if value.Name=="current" then
			if value.Value>#items.objectives and dataFolder.Rebirths.Value==10 then
				value.Value=1 -- reset it!
			end 
			if value.Value==14 and not dataCopy.resetFisk then -- reset the fisk thug
				dataCopy.resetFisk=true
				value.Value=16
			end
			-- update portal(s)!
			update_portals(value.Value,dataFolder.objectives.completed.Value)
		end
	end
	
	for index,value in dataFolder.portals:GetChildren() do 
		value:GetPropertyChangedSignal("Value"):Connect(function()
			if value.Value==true then -- was changed to true!
				dataCopy.portals[value.Name]=value.Value
			end
		end)
	end
	
	for key,value in dataFolder.codes:GetChildren() do 
		value.Redeemed:GetPropertyChangedSignal("Value"):Connect(function()
			--print("current value=",dataCopy.codes[value.Name].Redeemed)
			dataCopy.codes[value.Name].Redeemed=value.Redeemed.Value
			--print("set",value.Name,"to",value.Redeemed.Value)
		end)
	end
	
	for _,folder in dataFolder.skins:GetChildren() do 
		folder.Equipped:GetPropertyChangedSignal("Value"):Connect(function()
			dataCopy.skins[folder.Name].Equipped=folder.Equipped.Value
			--print("set",folder.Name," equipped to", folder.Equipped.Value)
		end)
	end
	
	local criticals = dataFolder.temp.criticals
	for i,v in (criticals:GetDescendants()) do 
		if v.Name == "seed" then
			v.Value = generate8DigitNumber() -- generate seed for this
		end
	end
	
	local rngs = {
		["Impact Web"] = {
			rng = Random.new(criticals["Impact Web"].seed.Value),
		},
		["Shotgun Webs"] = {
			rng = Random.new(criticals["Shotgun Webs"].seed.Value),
			spreadRng = Random.new(criticals["Shotgun Webs"].spread.seed.Value)
		},
		["Snare Web"] = {
			rng = Random.new(criticals["Snare Web"].seed.Value),
		},
		["Punch"] = {
			rng = Random.new(criticals["Punch"].seed.Value),
		},
		["Web Bomb"] = {
			rng = Random.new(criticals["Web Bomb"].seed.Value)
		},
		["Kick"] = {
			rng = Random.new(criticals["Kick"].seed.Value)
		},
		["360 Kick"] = {
			rng = Random.new(criticals["360 Kick"].seed.Value)
		},
		["Spider Drone"] = {
			rng = Random.new(criticals["Spider Drone"].seed.Value)
		},
		["Gauntlet"] = {
			rng=Random.new(criticals["Gauntlet"].seed.Value)
		}

	}
	
	local rollRemote = Instance.new("RemoteEvent")
	rollRemote.Name = "rollRemote"
	rollRemote.Parent = player
	
	local actionRemote = Instance.new("RemoteEvent")
	actionRemote.Name = "actionRemote"
	actionRemote.Parent = player
	
	local dataRemote = Instance.new("RemoteEvent")
	dataRemote.Name = "dataRemote"
	dataRemote.Parent = player
	
	local abilityRemote = Instance.new("RemoteEvent")
	abilityRemote.Name = "abilityRemote"
	abilityRemote.Parent = player
	
	local skinsRemote = Instance.new("RemoteEvent")
	skinsRemote.Name = "skinsRemote"
	skinsRemote.Parent = player
	
	local dragRemote = Instance.new("RemoteEvent")
	dragRemote.Name = "dragRemote"
	dragRemote.Parent = player
	
	local startTime = workspace:GetServerTimeNow() - 50
	
	local timeTrackers = {
		["Swing Web"] = startTime,
		["Launch Webs"] = startTime,
		["Shotgun Webs"] = startTime,
		["Impact Web"] = startTime,
		["Snare Web"] = startTime,
		["Punch"] = startTime,
		["Kick"] = startTime,
		["360 Kick"] = startTime,
		["Trip Web"] = startTime,
		["Web Bomb"] = startTime,
		["Anti Gravity"] = startTime,
		["Spider Drone"] = startTime,
		["Gauntlet"]=startTime,
		["Roll"] = startTime
	}
	
	local tripWebFolder = dataFolder:WaitForChild("temp"):WaitForChild("tripWebs")
	local TripWebAmount = tripWebFolder:WaitForChild("serverAmount")
	local TripWebTarget = tripWebFolder:WaitForChild("serverTarget")
	
	local function TripWebInfo()
		local level = dataFolder:WaitForChild("abilities"):WaitForChild("Traps"):WaitForChild("Trip Web").Level.Value
		local trip_web_amt_base = items.Traps["Trip Web"].misc[1].base
		local trip_web_amt_multiplier = items.Traps["Trip Web"].misc[1].multiplier
		local allowed_trip_webs = _math.getStat(level,trip_web_amt_base,trip_web_amt_multiplier)
		return allowed_trip_webs
	end
	
	local function addTripWebValue(tag)
		local newTripWeb = Instance.new("StringValue")
		newTripWeb.Name = tag
		newTripWeb.Value = "halfway"
		newTripWeb.Parent = TripWebAmount
	end
	
	local function getTripWeb(action)
		if action == "last" then
			local array = TripWebAmount:GetChildren()
			local last = array[#array]
			if last then 
				return last
			end
		elseif action == "first" then
			local array = TripWebAmount:GetChildren()
			local first = array[1]
			if first then 
				return first
			end
		end
		return nil
	end
	
	local function removeTripWebForOtherClients(folderName,action)
		for _,playerInstance in (game.Players:GetChildren()) do
			if player ~= playerInstance then
				local remote=playerInstance:FindFirstChild("actionRemote")
				if not remote then continue end
				remote:FireClient(
					playerInstance,
					"trip remove",
					player.Name, -- plr name
					action, -- action
					folderName -- tag
				)
			end
		end
	end
		
	local shotgunSpreads = {}
		
	local function checkInZone(zone,pos)
		if zone then
			local physicalZone = rs.Zones[zone.Value]
			local inPhysicalZone = _math.checkBounds(physicalZone.CFrame,physicalZone.Size,pos)
			if inPhysicalZone then
				return true	
			else 
				--print("you're not in the zone")
				return false
			end
		else 
			return true			
		end
	end
	
	local function getAbilityCrit(args)
		local ability = nil
		local crit = nil
		if args[1] == "Ranged" then
			if args[2] == "hit" then
				ability = args[5]
				crit = rngs[ability].rng:NextNumber(0,100)
			else
				if args[4] == "Shotgun Webs" then
					local tags = {
						[1] = args[6][1],
						[2] = args[6][2],
						[3] = args[6][3]
					}
					ability = args[4]
					for i = 1,3 do 
						local array = {
							x = rngs[ability].spreadRng:NextNumber(-10,10),
							y = rngs[ability].spreadRng:NextNumber(-10,10)
						}
						shotgunSpreads[tags[i]] = array
						--print(array.x)
						--print(array.y)
					end
				end
			end
		elseif args[1] == "Special" then
			ability = args[2]
			if args[3] == "Explode" or args[3]=="Snap" then
				crit = rngs[ability].rng:NextNumber(0,100)
			end
		elseif args[1] == "Melee" then
			if args[2] == "Hit" then
				ability = args[3]
				crit = rngs[ability].rng:NextNumber(0,100)
			end
		end
		if crit ~= nil then
			--print(ability,"crit = ",crit)
		end
		return crit
	end
	
	local function cooldownCheck(currentTime,clientTime,cooldown,category)
		local latency = currentTime - clientTime
		if latency < 0 then 
			--print(category,"latency less than 0") 
			return false
		end -- this is impossible naturally, so don't replicate.
		local dt = (currentTime - timeTrackers[category]) - latency
		if dt < 0 then 
			--print(category,"dt less than 0") 
			return false
		end -- this is impossible naturally, so don't replicate.
		if (dt+.05) < cooldown then 
			--print(category,"wasn't enough time, time difference = ",cooldown-dt) 
			return false
		end -- you can't replicate
		--print(category,"passed cooldown")
		return true
	end
	
	local equippables=dataFolder.temp.Equippables
	
	actionRemote.OnServerEvent:Connect(function(plr,...) -- make sure to negate the latency time
		-- don't forget to check if player unlocked abilities they're sending singals for!
		local args = {...}
		--pcall(function()
		local currentTime = workspace:GetServerTimeNow()
		if (plr ~= player) then return end -- this needs to be from your player only
		
		local crit = getAbilityCrit(args)
		--print("server crit=",crit)
		
		if not plr.Character or not plr.Character.PrimaryPart then return end -- don't continue if character doesn't exist
		
		if plr.Character then
			if not (plr.Character:WaitForChild("Humanoid").Health > 0) then return end -- make sure your character isn't dead
			if dataFolder.temp.isRolling.Value then 
				-- there are certain abilities allowed while rolling:
				--// all traps and special
				--// anything that isn't an ability, like equipping things
				local isNotAbility=timeTrackers[args[1]]==nil
				local isTrap=args[1]=="Traps"
				local isSpecial=args[1]=="Special"
				if not isNotAbility and not isTrap and not isSpecial then return end
			end -- can't attack while rolling	
		else 
			return 
		end
		
		local notTripWeb = args[2] ~= "Trip Web"
		
		if notTripWeb then  -- trying to do an action other than trip web
			local halfway = findHalfwayWeb(TripWebAmount)
			if halfway then
				if TripWebAmount.Value > 0 then 
					TripWebAmount.Value -= 1
				end
				TripWebTarget.Value = Vector3.new(0,0,0) -- this will remove the halfway trip web index for other clients loops
				removeTripWebForOtherClients(halfway.Name,"last")
				halfway:Destroy()
			end
		end
		
		if args[1]=="equip" then
			local AbilityString=type(args[2])=="string"
			local CategoryString=type(args[3])=="string"
			local isBoolean=type(args[4])=="boolean"
			if not AbilityString or not CategoryString or not isBoolean then return end
			local category=dataFolder.abilities:FindFirstChild(args[3])
			local ability=category and category:FindFirstChild(args[2])
			local owns=ability and ability.Unlocked.Value or true
			if not owns then return end -- the ability exists and you don't own it, don't continue
			local _value=equippables:FindFirstChild(args[2])
			for _,value in equippables:GetChildren() do 
				value.Value=value==_value and args[4] or false
			end
			return
		end
		
		if args[1] == "Ranged" then 
			if args[2] == "hit" then
				local name = args[3]
				local listing = liveProjectiles[name]
				if not listing then --[[print("doesn't own ability")]] return end
				local owner = listing.plr
				if owner ~= player then return end -- another person's projectile
				local origin = listing.startPos
				local category = listing.category
				local random = listing.random
				local hit = args[4]
				if hit and hit:IsDescendantOf(workspace) and hit.PrimaryPart then
					--print("bullet hit something")
					local distance = (hit.PrimaryPart.Position - origin).Magnitude
					local direction = (hit.PrimaryPart.Position - origin).Unit * distance
					local result = rangedRaycastCheck(origin,direction)
					if not result then -- there weren't obstructions in the way
						--print("bullet was cleared")
						local level = dataFolder.abilities.Ranged[category].Level.Value
						local misc = items.Ranged[category].misc[1]
						local damage = _math.getStat(level,misc.base,misc.multiplier)

						local duration = 0
						local misc2 = items.Ranged[category].misc[2]
						if misc2 then
							duration = _math.getStat(level,misc2.base,misc2.multiplier)
						end

						local charPos = player.Character.PrimaryPart.Position

						local isDrone = hit:FindFirstChild("Drone") and NPCs[hit.Properties.Tag.Value]
						local NPC = isDrone or NPCs[hit.Name]

						if NPC and NPC.model then
							local zone = NPC.model.Properties:FindFirstChild("Zone")
							if zone then
								if checkInZone(NPC.model.Properties:FindFirstChild("Zone"),charPos) then
									local f = coroutine.wrap(_G.damageNPC)
									f(NPC,player,damage,category,duration,crit)	
								end
							else
								local venom = NPC.model:IsDescendantOf(workspace.Villains) and NPC.model or false
								if venom then
									local mapCF = CFrame.new(Vector3.new(92, 14.5, -170))
									local mapSize = Vector3.new(1400, 34, 1260)
									local distance = (listing.startPos - venom.PrimaryPart.Position).Magnitude
									if _math.checkBounds(mapCF,mapSize,listing.startPos) and distance <= 250 then
										--print("venom hit")
										local f = coroutine.wrap(_G.damageNPC)
										f(NPC,player,damage,category,duration,crit)
									else
										--print("venom wasn't hit, projectile wasn't in bounds")
									end
								end
								if isDrone and not checkSafeZones(NPC.model.PrimaryPart.Position) then
									local f = coroutine.wrap(_G.damageNPC)
									f(NPC,player,damage,category,duration,crit)
								end
							end
						else
							local char = game.Players:GetPlayerFromCharacter(hit)
							if char then
								local f = coroutine.wrap(_G.damagePlayer)
								f(hit,player,damage,category,duration,crit)
							end
						end	
					end
					Danger(player,"Ranged",listing.category,name,hit.PrimaryPart.Position)
					liveProjectiles[name].clear(liveProjectiles[name])
					liveProjectiles[name] = nil -- clear the projectile listing
				end
				return		
			end

			local origin = typeof(args[2]) == "Vector3" and args[2] or nil
			local target = typeof(args[3]) == "Vector3" and args[3] or nil
			local category = type(args[4]) == "string" and args[4] or nil
			local timer = type(args[5]) == "number" and args[5] or nil

			local canContinue = origin and target and category and timer
			if not canContinue then --[[print("can't continue")]] return end

			local cooldowns = {
				["Shotgun Webs"] = .5,
				["Impact Web"] = .25,
				["Snare Web"] = 30
			}

			if not cooldowns[category] then return end

			local hasShotgunTags = category == "Shotgun Webs" and type(args[6]) == "table" and type(args[6][1]) == "string" and type(args[6][2]) == "string" and type(args[6][3]) == "string"
			local hasOneTag = category ~= "Shotgun Webs" and type(args[6]) == "string"

			if not hasShotgunTags and not hasOneTag then --[[print("doesn't have tags")]] return end -- doesn't have either

			local ability = dataFolder.abilities.Ranged[category]
			if ability then 
				local ownsAbility = ability.Unlocked.Value
				if not ownsAbility then --[[print("doesn't own ability")]] return end
			else 
				return
			end

			if not cooldownCheck(currentTime,timer,cooldowns[category],category) then return end

			soundEvent:FireAllClients(player,"projectile")

			local tags
			if category == "Shotgun Webs" then
				tags = {
					[1] = args[6][1],
					[2] = args[6][2],
					[3] = args[6][3]
				}
				for i = 1,3 do
					local listing = liveProjectiles[tags[i]]
					if listing then return end -- if even one already exists they all already exist
					liveProjectiles[tags[i]] = {
						plr = player,
						startPos = player.Character.PrimaryPart.Position,
						category = category,
						clear=clear,
						start=tick()
					}
				end
			else 
				local listing = liveProjectiles[args[6]]
				if listing then return end
				liveProjectiles[args[6]] = {
					plr = player,
					startPos = player.Character.PrimaryPart.Position,
					category = category,
					clear=clear,
					start=tick()
				}	
			end

			timeTrackers[category] = currentTime

			for _,playerInstance in (game.Players:GetChildren()) do
				if player ~= playerInstance then
					if category == "Shotgun Webs" then
						for i = 1,3 do
							local listing = shotgunSpreads[tags[i]]
							if not listing then continue end
							local x,y = listing.x,listing.y
							shotgunSpreads[tags[i]] = nil -- clear listing
							local remote=playerInstance:FindFirstChild("actionRemote")
							if not remote then continue end
							remote:FireClient(
								playerInstance,
								"projectile",
								origin,
								target,
								category,
								Vector3.new(x,y,0),
								player.Name, -- player's name
								timer,
								tags[i] -- tag
							)
						end
					else
						local remote=playerInstance:FindFirstChild("actionRemote")
						if not remote then continue end
						remote:FireClient(
							playerInstance,
							"projectile",
							origin,
							target,
							category,
							Vector3.new(0,0,0),
							player.Name, -- player's name
							timer,
							args[6] -- tag
						)
					end
				end
			end

			local tag =args[6][1] and args[6][1] or args[6]
			Danger(player,"Ranged",category,tag,origin)

		elseif args[1] == "Travel" then

			local cooldowns = {
				["Swing Web"] = .5,--.25,
				["Launch Webs"] = .5,--.25,
			}

			if args[2] == "New" then

				if args[3] == "Swing Web" then
					local ownsAbility = dataFolder.abilities.Travel["Swing Web"].Unlocked.Value
					if not ownsAbility then --[[print("doesn't own ability")]] return end

					local humanoid = args[4]:IsA("Humanoid") and args[4] or nil
					local cf = typeof(args[5]) == "CFrame" and args[5] or nil
					local grips = (args[6]:IsA("Attachment") and args[7]:IsA("Attachment") and args[6]:IsDescendantOf(player.Character) and args[7]:IsDescendantOf(player.Character)) and {left = args[6],right = args[7]} or nil
					local timer = type(args[8]) == "number" and args[8] or nil

					local canContinue = humanoid and cf and grips and timer
					if not canContinue then return end

					if not cooldownCheck(currentTime,timer,cooldowns["Swing Web"],"Swing Web") then return end	

					soundEvent:FireAllClients(player,"travel")

					timeTrackers["Swing Web"] = currentTime
					if (dataFolder.temp.isWebbing.Value) then return end -- if player already webbing, don't allow another travel web render for other clients.
					dataFolder.temp.isWebbing.Value = true
					for _,playerInstance in (game.Players:GetChildren()) do
						if player ~= playerInstance then
							local remote=playerInstance:FindFirstChild("actionRemote")
							if not remote then continue end
							remote:FireClient(
								playerInstance,
								"travel",
								plr.Name, 
								humanoid,
								cf, 
								grips.left, 
								grips.right, 
								timer 
							)
						end
					end
				elseif args[3] == "Launch Webs" then
					local ownsAbility = dataFolder.abilities.Travel["Launch Webs"].Unlocked.Value
					if not ownsAbility then --[[print("doesn't own ability")]] return end

					local humanoid = args[4]:IsA("Humanoid") and args[4] or nil
					local cf = (typeof(args[5]) == "CFrame" and typeof(args[6]) == "CFrame") and {leftCF = args[5],rightCF = args[6]} or nil
					local grips = (args[7]:IsA("Attachment") and args[8]:IsA("Attachment") and args[7]:IsDescendantOf(player.Character) and args[8]:IsDescendantOf(player.Character)) and {left = args[7],right = args[8]} or nil
					local timer = type(args[9]) == "number" and args[9] or nil

					local canContinue = humanoid and cf and grips and timer
					if not canContinue then return end

					if not cooldownCheck(currentTime,timer,cooldowns["Launch Webs"],"Launch Webs") then return end

					if (dataFolder.temp.isWebbing.Value) then return end -- if player already webbing, don't allow another travel web render for other clients.

					soundEvent:FireAllClients(player,"travel")

					timeTrackers["Launch Webs"] = currentTime
					dataFolder.temp.isWebbing.Value = true
					for _,playerInstance in (game.Players:GetChildren()) do
						if player ~= playerInstance then
							for i = 1,2 do 
								local attachment = i == 1 and grips.left or grips.right
								local targetCF = i == 1 and cf.leftCF or cf.rightCF
								local remote=playerInstance:FindFirstChild("actionRemote")
								if not remote then continue end
								remote:FireClient(
									playerInstance,
									"travel",
									plr.Name, 
									humanoid, 
									targetCF, 
									attachment, 
									attachment,
									timer 
								)
							end
						end
					end
				end
			elseif args[2] == "Remove" then
				dataFolder.temp.isWebbing.Value = false -- this should remove the web from other clients
			end
		elseif args[1] == "Traps" then	

			local function removeTripWeb(tag)
				local listing = TripWebAmount:FindFirstChild(tag)
				if listing then
					listing:Destroy() -- destroy the listing under serverAmount
				else 
					return -- don't continue if this listing doesn't exist
				end
				if TripWebAmount.Value > 0 then
					TripWebAmount.Value -= 1
				end
				for _,playerInstance in (game.Players:GetChildren()) do
					local remote=playerInstance:FindFirstChild("actionRemote")
					if not remote then continue end
					remote:FireClient(
						playerInstance,
						"trip remove",
						player.Name,
						"specific", -- action
						tag -- tag
					)
				end
				LiveTripWebs[tag].hitbox:Destroy()
				LiveTripWebs[tag].clear(LiveTripWebs[tag])
				LiveTripWebs[tag] = nil
			end

			local cooldowns = {
				["Trip Web"] = .25,
				["Anti Gravity"] = 30
			}

			if args[2] == "Trip Web" then
				local ownsAbility = dataFolder.abilities.Traps["Trip Web"].Unlocked.Value
				if not ownsAbility then --[[print("doesn't own ability")]] return end
				if args[3] == "finalize" then
					local origin = typeof(args[4]) == "Vector3" and args[4] or nil
					local lastOrigin = typeof(args[5]) == "Vector3" and args[5] or nil
					local cf = typeof(args[6]) == "CFrame" and args[6] or nil
					local timer = type(args[7]) == "number" and args[7] or nil
					local tag = type(args[8]) == "string" and args[8] or nil
					local obstructionCF = typeof(args[9]) == "CFrame" and args[9] or nil
					local canContinue = origin and cf and timer and tag and lastOrigin and obstructionCF
					if not canContinue then return end

					if not cooldownCheck(currentTime,timer,cooldowns["Trip Web"],"Trip Web") then return end

					local listing = TripWebAmount:FindFirstChild(tag)
					if not listing then return end -- doesn't have a listing, don't render for other clients
					if listing.Value ~= "halfway" then return end -- isn't halfway, don't render for other clients

					soundEvent:FireAllClients(player,"travel")

					listing.Value = "finalized" -- set the value to finalized so it can't go through here again
					timeTrackers["Trip Web"] = currentTime
					TripWebTarget.Value = cf.Position -- this stops the halfway web from connecting to hand for all other clients

					for _,playerInstance in(game.Players:GetChildren()) do
						if player ~= playerInstance then
							local remote=playerInstance:FindFirstChild("actionRemote")
							if not remote then continue end
							remote:FireClient(
								playerInstance,
								"trip",
								"finalize", 
								player.Name, 
								origin, 
								lastOrigin,
								cf, 
								timer, 
								tag 
							)
						end
					end		

					Danger(player,"Traps","Trip Web",tag,player.Character.PrimaryPart.Position)

					cf = cf ~= obstructionCF and obstructionCF or cf -- make sure its obstructionCF
					if (lastOrigin - cf.Position).Magnitude > 200 then
						local i = 0
						while true do -- mimick the trip web trajectory, wait for a sec to remove it
							i+=1
							local distance_percentage = (origin - cf.Position).Magnitude / 200
							local p = (workspace:GetServerTimeNow() - timer) / distance_percentage
							p = math.clamp(p,0,1)
							if p == 1 or i > 100 then break end
							task.wait(1/30)
						end
						for i,playerInstance in (game.Players:GetChildren()) do 
							local remote=playerInstance:FindFirstChild("actionRemote")
							if not remote then continue end
							remote:FireClient( -- everyone including you
								playerInstance,
								"trip remove",
								player.Name, 
								"specific", 
								tag
							)
						end
						if TripWebAmount.Value > 0 then 
							TripWebAmount.Value -= 1 
						end
						listing:Destroy()
						TripWebTarget.Value = Vector3.new(0,0,0) -- this will remove the halfway trip web index for other clients loops
						-- this wouldn't have a listing in livetripwebs
						return
					end

					local distance_percentage = (origin - cf.Position).Magnitude / 200
					task.wait(math.clamp(distance_percentage,0,1))

					local webLength = (lastOrigin - cf.Position).Magnitude
					local size = Vector3.new(0.35,0.35,webLength)
					local cframe = CFrame.new(lastOrigin:Lerp(cf.Position,.5),cf.Position)

					local hitbox = createHitbox(cframe,size,Enum.PartType.Block,player.Name,tag)

					LiveTripWebs[tag] = {
						plr = player,
						start = workspace:GetServerTimeNow(), 
						hitbox = hitbox,
						clear=clear
					}

					hitbox.Touched:Connect(function(touched)
						--print("trip web touched",touched)
						local humanoid = touched.Parent:FindFirstChild("Humanoid") or touched.Parent.Parent:FindFirstChild("Humanoid")
						local properties = touched.Parent:FindFirstChild("Properties") or touched.Parent.Parent:FindFirstChild("Properties")
						local isDrone = touched.Parent:FindFirstChild("Drone") or touched.Parent.Parent:FindFirstChild("Drone")
						if properties and not isDrone then -- a non-drone NPC
							local NPC = NPCs[properties.Parent.Name]
							if NPC --[[and not cs:HasTag(NPC.model,"tripped")]] and not cs:HasTag(NPC.model,"gravity") then
								local listing = LiveTripWebs[tag]
								if not listing then return end
								if not cs:HasTag(NPC.model,"ragdolled") then
									local elapsed = tick()-properties.lastRagdollRecovery.Value
									if not (elapsed >= .5) then return end
									--cs:AddTag(NPC.model,"tripped")
									removeTripWeb(tag)
									local f = coroutine.wrap(_G.damageNPC)
									f(NPC,player,0,"Trip Web",3,crit)
								end
							end
							return
						end
						if humanoid then -- likely a player
							local plr = game.Players:GetPlayerFromCharacter(humanoid.Parent)
							if plr and plr ~= player --[[and not cs:HasTag(humanoid.Parent,"tripped")]] and not cs:HasTag(humanoid.Parent,"gravity") then
								local listing = LiveTripWebs[tag]
								if not listing then return end
								if not cs:HasTag(humanoid.Parent,"ragdolled") then
									local elapsed = tick()-plr.leaderstats.temp.lastRagdollRecovery.Value
									if not (elapsed >= .5) then return end
									--[[cs:AddTag(humanoid.Parent,"tripped")]]
									removeTripWeb(tag)
									local f = coroutine.wrap(_G.damagePlayer)
									f(plr.Character,player,0,"Trip Web",3,crit)										
								end
							else 
								-- hit your player!
							end
						end
					end)

				elseif args[3] == "halfway" then
					local tag = type(args[7]) == "string" and args[7] or nil
					local timer = type(args[6]) == "number" and args[6] or nil
					local grip = (args[4]:IsA("Attachment") and args[4]:IsDescendantOf(player.Character)) and args[4] or nil
					local cf = typeof(args[5]) == "CFrame" and args[5] or nil
					local canContinue = grip and cf and timer and tag
					if not canContinue then return end

					if not cooldownCheck(currentTime,timer,cooldowns["Trip Web"],"Trip Web") then return end

					local listing = TripWebAmount:FindFirstChild(tag)
					if listing then return end -- already exists, don't re-render halfway for other clients
					local alreadyHasHalfwayWeb = findHalfwayWeb(TripWebAmount)
					if alreadyHasHalfwayWeb then return end

					soundEvent:FireAllClients(player,"travel")

					timeTrackers["Trip Web"] = currentTime
					TripWebTarget.Value = cf.Position -- this shuts off any already visible halfway web for all other clients

					local allowed = TripWebInfo()
					if TripWebAmount.Value < allowed  then
						TripWebAmount.Value += 1
						addTripWebValue(tag)
					elseif allowed == TripWebAmount.Value then 
						local first = getTripWeb("first")
						if first then 
							removeTripWebForOtherClients(tag,"first")
							if TripWebAmount.Value > 0 then
								first:Destroy()
								TripWebAmount.Value -= 1
							end 
						end
						addTripWebValue(tag)
					end

					for _,playerInstance in (game.Players:GetChildren()) do
						if player ~= playerInstance then
							local remote=playerInstance:FindFirstChild("actionRemote")
							if not remote then continue end
							remote:FireClient(
								playerInstance,
								"trip",
								"halfway", 
								player.Name, 
								grip, 
								cf, 
								timer, 
								tag 
							)
						end
					end	 

					Danger(player,"Traps","Trip Web",tag,player.Character.PrimaryPart.Position)

				elseif args[3] == "reset" then
					local tag = type(args[4]) == "string" and args[4] or nil
					if not tag then return end
					local listing = TripWebAmount:FindFirstChild(tag)
					if not listing then return end

					listing:Destroy()

					local tripWebListing = LiveTripWebs[tag]
					if tripWebListing then
						tripWebListing.hitbox:Destroy()
						LiveTripWebs[tag].clear(LiveTripWebs[tag])
						LiveTripWebs[tag] = nil
						--print("removed trip web named",tag)
					end

					if TripWebAmount.Value > 0 then
						TripWebAmount.Value -= 1
					end 

					TripWebTarget.Value = Vector3.new(0,0,0) -- this will remove the halfway trip web for other clients

					removeTripWebForOtherClients(tag,"last")

				end
			elseif args[2] == "Anti Gravity" then 
				local ownsAbility = dataFolder.abilities.Traps["Anti Gravity"].Unlocked.Value
				if not ownsAbility then --[[print("doesn't own ability")]] return end
				if args[3] == "New" then 
					local tag = type(args[4]) == "string" and args[4] or nil
					local origin = typeof(args[5]) == "Vector3" and args[5] or nil
					local target = typeof(args[6]) == "Vector3" and args[6] or nil 
					local timer = type(args[7]) == "number" and args[7] or nil

					local canContinue = tag and origin and target and timer
					if not canContinue then return end

					if not cooldownCheck(currentTime,timer,cooldowns["Anti Gravity"],"Anti Gravity") then return end

					soundEvent:FireAllClients(player,"throw")

					timeTrackers["Anti Gravity"] = currentTime

					local newValue = Instance.new("StringValue") -- you add the listing here, then remove it on explode after verifying
					newValue.Name = tag
					newValue.Value = player.Name
					newValue:SetAttribute("Origin",origin)
					newValue:SetAttribute("Exploded",false)
					newValue.Parent = verified_gravity_bombs

					for _,playerInstance in (game.Players:GetChildren()) do
						if player ~= playerInstance then
							local remote=playerInstance:FindFirstChild("actionRemote")
							if not remote then continue end
							remote:FireClient(
								playerInstance,
								"gravityBombAdd",
								player.Name,
								origin,
								target, 
								timer,
								tag
							)
						end
					end
					Danger(player,"Traps","Anti Gravity",tag,origin)
				elseif args[3] == "Explode" then
					local tag = type(args[4]) == "string" and args[4] or nil
					local endPos = typeof(args[5]) == "Vector3" and args[5] or nil
					local timer = type(args[6]) == "number" and args[6] or nil
					local canContinue = tag and endPos and timer
					if not canContinue then return end

					local listing = verified_gravity_bombs:FindFirstChild(tag)
					if not listing then return end 
					if not (listing.Value == player.Name) then return end
					if listing:GetAttribute("Exploded") == true then return end

					listing:SetAttribute("Exploded",true)

					local throwPosition = listing:GetAttribute("Origin")
					local throwPosInSafeZone = checkSafeZones(throwPosition)
					local endPosInSafeZone = checkSafeZones(endPos)

					--listing:Destroy()

					for _,playerInstance in (game.Players:GetChildren()) do
						local remote=playerInstance:FindFirstChild("actionRemote")
						if not remote then continue end
						remote:FireClient(
							playerInstance,
							"gravityBombExplode",
							player.Name,
							tag,
							timer 
						)
					end

					Danger(player,"Traps","Anti Gravity",tag,endPos)

					-- wait for 1.5 seconds elapsed to do a area check and ragdoll everyone inside this area
					while workspace:GetServerTimeNow() - timer < .25 do
						task.wait(1/30)
					end	

					local level = dataFolder.abilities.Traps["Anti Gravity"].Level.Value
					local misc = items.Traps["Anti Gravity"].misc[1]
					local diameter = _math.getStat(level,misc.base,misc.multiplier)
					local radius = diameter/2
					-- 2 conditions have met to ragdoll and float:
					-- x and z magnitude must be within diameter
					-- y must be at or above the y position of the bomb but under 15 studs above the y pos
					local ignoreY = Vector3.new(1,0,1)
					local elapsed = workspace:GetServerTimeNow() - timer
					local duration = 8

					local caught = {}

					local function addPlayerToCaughtList(character,ragdollDuration)
						local model = character
						local rootPos = model.PrimaryPart.Position
						cs:AddTag(model,"gravity")
						local bodyPosition = rs.GravityPosition:Clone()
						bodyPosition.Position = Vector3.new(rootPos.X,endPos.Y + 10,rootPos.Z)
						bodyPosition.Parent = model.PrimaryPart
						game:GetService("Debris"):AddItem(bodyPosition,ragdollDuration)
						local gyro = model.PrimaryPart:FindFirstChildOfClass("BodyGyro")
						gyro=gyro or rs.thugs.Thug.HumanoidRootPart.BodyGyro:Clone()
						gyro.Parent=model.PrimaryPart
						caught[#caught+1] = {
							model = model,
							i = 0,
							bodyposition = bodyPosition,
							bodyPos = Vector3.new(rootPos.X,endPos.Y + 10,rootPos.Z),
							gyro = gyro,
							isPlayer=true
						}
						local f = coroutine.wrap(_G.damagePlayer)
						f(character,player,0,"Anti Gravity",ragdollDuration,0)							
					end

					local function addNPCToCaughtList(NPC,ragdollDuration)
						local model = NPC.model
						local rootPos = model.PrimaryPart.Position
						cs:AddTag(model,"gravity")
						local bodyPosition = rs.GravityPosition:Clone()
						bodyPosition.Position = Vector3.new(rootPos.X,endPos.Y + 10,rootPos.Z)
						bodyPosition.Parent = model.PrimaryPart
						game:GetService("Debris"):AddItem(bodyPosition,ragdollDuration)
						local gyro = model.PrimaryPart:FindFirstChildOfClass("BodyGyro")
						caught[#caught+1] = {
							model = model,
							i = 0,
							bodyposition = bodyPosition,
							bodyPos = Vector3.new(rootPos.X,endPos.Y + 10,rootPos.Z),
							gyro = gyro,
							isPlayer=false
						}
						local f = coroutine.wrap(_G.damageNPC)
						f(NPC,player,0,"Anti Gravity",ragdollDuration,0)
					end

					while (workspace:GetServerTimeNow() - timer) - elapsed < duration do
						local t = (workspace:GetServerTimeNow() - timer) - elapsed
						--print(t)
						local ragdollDuration = math.clamp(8-t,0,duration)

						if not throwPosInSafeZone and not endPosInSafeZone then
							local players = game.Players:GetPlayers()
							local playerPvP=player.leaderstats.temp.PvP
							for _,plr in (players) do
								if plr ~= player then -- don't detect your own player
									local character = plr.Character
									if character and character:IsDescendantOf(workspace) and character.PrimaryPart then
										if plr.leaderstats.temp.isRolling.Value then continue end
										if cs:HasTag(character,"gravity") then continue end
										if plr.leaderstats.temp.PvP.Value==false then continue end
										if playerPvP.Value==false then continue end
										local rootPos = character.PrimaryPart.Position
										local withinXZ = ((rootPos * ignoreY) - (endPos * ignoreY)).Magnitude <= radius
										local withinY = rootPos.Y >= endPos.Y and rootPos.Y < endPos.Y + 15
										local isWithinRange = withinXZ and withinY
										if isWithinRange and ragdollDuration > 0.5 --[[and not cs:HasTag(character,"ragdolled")]] then
											addPlayerToCaughtList(character,ragdollDuration)
										end
									end								
								end
							end
						end

						for tag,NPC in (NPCs) do 
							if not NPC.model then continue end
							local model = NPC.model
							if not model:IsDescendantOf(workspace) or not model.PrimaryPart then continue end
							local drone = model:FindFirstChild("Drone")
							if drone then continue end
							if cs:HasTag(model,"gravity") then continue end
							local rootPos = model.PrimaryPart.Position	
							local withinXZ = ((rootPos * ignoreY) - (endPos * ignoreY)).Magnitude <= radius
							local withinY = rootPos.Y >= endPos.Y and rootPos.Y < endPos.Y + 15
							local isWithinRange = withinXZ and withinY
							if isWithinRange and ragdollDuration > 0.5 --[[and not cs:HasTag(model,"ragdolled")]] then
								local properties = model.Properties
								local zone = properties:FindFirstChild("Zone")
								if zone then
									local physicalZone = rs.Zones[zone.Value]
									local isInZone = _math.checkBounds(physicalZone.CFrame,physicalZone.Size,throwPosition) -- you threw it inside the zone
									if isInZone then
										addNPCToCaughtList(NPC,ragdollDuration)
									end
								else
									local venom = model:IsDescendantOf(workspace.Villains)
									if venom then
										venom = model
										local mapCF = CFrame.new(Vector3.new(92, 14.5, -170))
										local mapSize = Vector3.new(1400, 34, 1260)
										local distance = (throwPosition - venom.PrimaryPart.Position).Magnitude
										if _math.checkBounds(mapCF,mapSize,throwPosition) and distance <= 250 then
											print("added villain to the list")
											addNPCToCaughtList(NPC,ragdollDuration)
										end
									end
									-- add more functionality for other bosses here
								end									
							end
						end

						for _,array in (caught) do
							if array.i == 360 then array.i = 0 end -- reset sine wave
							array.i += 2
							local p = array.i/360
							local sine = math.sin((math.pi*2) * p)
							if array.bodyposition.Parent ~= nil then -- hasn't been destroyed yet

								local newPos = array.bodyPos + Vector3.new(0,sine*2,0)
								array.bodyposition.Position = newPos
							end	
							if array.gyro ~= nil and array.gyro.Parent ~= nil then
								if array.gyro.MaxTorque == Vector3.new(0,0,0) then
									array.gyro.MaxTorque = Vector3.new(1000000,1000000,1000000)	
								end	
								local xAngle = math.rad(90)
								local yAngle = math.rad(0)
								local zAngle = math.rad(array.i)
								local isVenom = array.gyro:IsDescendantOf(workspace.Villains)
								if isVenom then
									xAngle = math.rad(0)
									yAngle = math.rad(array.i)
									zAngle = math.rad(0)
								end
								array.gyro.CFrame = CFrame.new(array.model.PrimaryPart.Position) * CFrame.Angles(xAngle,yAngle,zAngle)
							end
							if ragdollDuration < .25 then -- destroy the player's gyro a little early
								if array.isPlayer then
									array.gyro:Destroy()
								end
							end
						end

						task.wait(1/15)
					end

					for _,array in (caught) do
						cs:RemoveTag(array.model,"gravity")	
					end
					listing:Destroy()
				end
			end
		elseif args[1] == "Special" then
			local cooldowns = {
				["Web Bomb"] = 10,
				["Spider Drone"] = 10,
				["Gauntlet"]=10
			}
			if args[2] == "Web Bomb" then
				local ownsAbility = dataFolder.abilities.Special["Web Bomb"].Unlocked.Value
				if not ownsAbility then --[[print("doesn't own ability")]] return end
				if args[3] == "New" then
					local tag = type(args[4]) == "string" and args[4] or nil
					local origin = typeof(args[5]) == "Vector3" and args[5] or nil
					local target = typeof(args[6]) == "Vector3" and args[6] or nil
					local timer = type(args[7]) == "number" and args[7] or nil

					local canContinue = tag and origin and target and timer
					if not canContinue then return end

					if not cooldownCheck(currentTime,timer,cooldowns["Web Bomb"],"Web Bomb") then return end

					local hasListing = verified_web_bombs:FindFirstChild(tag)
					if hasListing then return end

					soundEvent:FireAllClients(player,"throw")

					timeTrackers["Web Bomb"] = currentTime

					local newValue = Instance.new("StringValue") -- you add the listing here, then remove it on explode after verifying
					newValue.Name = tag
					newValue.Value = player.Name
					newValue:SetAttribute("Origin",origin)
					newValue:SetAttribute("Exploded",false)
					newValue.Parent = verified_web_bombs

					for _,playerInstance in (game.Players:GetChildren()) do
						if player ~= playerInstance then
							local remote=playerInstance:FindFirstChild("actionRemote")
							if not remote then continue end
							remote:FireClient(
								playerInstance,
								"webBombAdd",
								player.Name, -- plr name
								origin, -- origin
								target, -- target
								timer, -- timer
								tag -- tag
							)
						end
					end
					Danger(player,"Special","Web Bomb",tag,origin)
				elseif args[3] == "Explode" then
					local critical = crit	
					local tag = type(args[4]) == "string" and args[4] or nil
					local endPos = typeof(args[5]) == "Vector3" and args[5] or nil
					local timer = type(args[6]) == "number" and args[6] or nil
					local canContinue = tag and endPos and timer
					if not canContinue then --[[print("web bomb couldn't continue")]] return end

					local listing = verified_web_bombs:FindFirstChild(tag)
					if not listing then return end 
					if not (listing.Value == player.Name) then return end 
					if listing:GetAttribute("Exploded") == true then return end

					listing:SetAttribute("Exploded",true)

					local throwPosition = listing:GetAttribute("Origin")

					for _,playerInstance in (game.Players:GetChildren()) do
						local remote=playerInstance:FindFirstChild("actionRemote")
						if not remote then continue end
						remote:FireClient(
							playerInstance,
							"webBombExplode",
							tag,
							timer,
							critical,
							player
						)
					end

					local throwPosInSafeZone = checkSafeZones(throwPosition)
					local endPosInSafeZone = checkSafeZones(endPos)

					Danger(player,"Special","Web Bomb",tag,endPos)

					while workspace:GetServerTimeNow() - timer < .25 do
						task.wait(1/30)
					end

					local elapsed = workspace:GetServerTimeNow() - timer
					local level = dataFolder.abilities.Special["Web Bomb"].Level.Value
					local misc = items.Special["Web Bomb"].misc[1]
					local damage = _math.getStat(level,misc.base,misc.multiplier) --((misc.multiplier * (level - 1)) + misc.base)

					--local hitbox = createHitbox(CFrame.new(endPos),Vector3.new(50,50,50),Enum.PartType.Ball)
					--game:GetService("Debris"):AddItem(hitbox,3)

					if not throwPosInSafeZone and not endPosInSafeZone then
						for _,plr in (game.Players:GetPlayers()) do
							if plr ~= player then -- don't detect your own player
								local character = plr.Character
								if character and character:IsDescendantOf(workspace) and character.PrimaryPart then
									local isWithinRange = (character.PrimaryPart.Position - endPos).Magnitude <= 50
									if isWithinRange then
										local origin = endPos
										local target = character.PrimaryPart.Position
										local distance = (origin - target).Magnitude
										local direction = (target - origin).Unit * distance
										local result = webBombRay(origin,direction)
										if not result then
											local f = coroutine.wrap(_G.damagePlayer)	
											f(character,player,damage,"Web Bomb",0,critical)
										else 
											--print("Web bomb hit:",result.Instance.Name,result.Parent.Name)
										end
									else
										--print(plr.Name,"wasn't in range")
									end
								else
									--print("character isn't valid for ",plr.Name)
								end								
							end	
						end
					end

					local function checkObstructionsNPC(origin,direction,NPC)
						local result = webBombRay(origin,direction)
						if not result then
							-- NPC,player,damage,ability,duration,crit
							local f = coroutine.wrap(_G.damageNPC)
							f(NPC,player,damage,"Web Bomb",0,critical)
						else 
							--print("there was an obstruction to the web bomb ray, ",result.Instance.Name,result.Instance.Parent.Name)
						end
					end

					for tag,NPC in (NPCs) do
						local model = NPC.model
						if model and model:IsDescendantOf(workspace) and model.PrimaryPart then
							local origin = endPos
							local target = model.PrimaryPart.Position
							local distance = (origin - target).Magnitude
							local direction = (target - origin).Unit * distance
							local isDrone = model:FindFirstChild("Drone")
							if isDrone then
								if not (model.Name == player.Name) and not checkSafeZones(model.PrimaryPart.Position) then -- you're not the owner of this drone
									checkObstructionsNPC(origin,direction,NPC)
								end
							else 
								local isWithinRange = (model.PrimaryPart.Position - endPos).Magnitude <= 50
								if isWithinRange then
									local properties = model.Properties
									local zone = properties:FindFirstChild("Zone")
									if zone then
										local physicalZone = rs.Zones[zone.Value]
										local isInZone = _math.checkBounds(physicalZone.CFrame,physicalZone.Size,throwPosition)
										if isInZone then
											--print("throw position was inside zone")
											checkObstructionsNPC(origin,direction,NPC)
										else 
											--print("throw position wasn't inside zone")
										end
									else
										local venom = model:IsDescendantOf(workspace.Villains)
										if venom then
											venom = model
											local mapCF = CFrame.new(Vector3.new(92, 14.5, -170))
											local mapSize = Vector3.new(1400, 34, 1260)
											local distance = (throwPosition - venom.PrimaryPart.Position).Magnitude
											if _math.checkBounds(mapCF,mapSize,throwPosition) and distance <= 250 then
												checkObstructionsNPC(origin,direction,NPC)
											end
										end
									end						
								end
							end
						end
					end

					Danger(player,"Special","Web Bomb",tag,endPos)
					listing:Destroy()
				end
			elseif args[2] == "Spider Drone" then
				local ownsAbility = dataFolder.abilities.Special["Spider Drone"].Unlocked.Value
				if not ownsAbility then --[[print("doesn't own ability")]] return end
				if args[3] == "New" then
					local tag = type(args[4]) == "string" and args[4] or nil
					local origin = typeof(args[5]) == "Vector3" and args[5] or nil
					local target = typeof(args[6]) == "Vector3" and args[6] or nil
					local timer = type(args[7]) == "number" and args[7] or nil

					local canContinue = tag and origin and target and timer
					if not canContinue then return end

					if not cooldownCheck(currentTime,timer,cooldowns["Spider Drone"],"Spider Drone") then return end

					local hasListing = verified_drones:FindFirstChild(tag)
					if hasListing then return end

					soundEvent:FireAllClients(player,"throw")

					timeTrackers["Spider Drone"] = currentTime

					local newValue = Instance.new("StringValue") -- you add the listing here, then remove it after verifying deployment
					newValue.Name = tag
					newValue.Value = player.Name
					newValue.Parent = verified_drones

					for _,playerInstance in (game.Players:GetChildren()) do
						if player ~= playerInstance then
							local remote=playerInstance:FindFirstChild("actionRemote")
							if not remote then continue end
							remote:FireClient(
								playerInstance,
								"spiderDroneAdd",
								player.Name, -- plr name
								origin,
								target, 
								timer,
								tag 
							)
						end
					end
					Danger(player,"Special","Spider Drone",tag,origin)
				elseif args[3] == "Deploy" then
					local cf = typeof(args[4]) == "CFrame" and args[4] or nil
					local tag = type(args[5]) == "string" and args[5] or nil
					local canContinue = cf and tag
					if not canContinue then return end 

					-- if old drone, reward and destroy
					local foundDrone = workspace:WaitForChild("SpiderDrones"):FindFirstChild(player.Name)
					if foundDrone then 
						local properties = foundDrone.Properties
						local tag = properties.Tag
						local health = properties.Health
						local maxHealth = properties.MaxHealth
						local listing = NPCs[tag.Value]
						if listing then
							local cashAdd = math.round(25*(maxHealth.Value/100))
							for i,v in (listing.attackers) do 
								local plr = v.plr
								local cash = plr.leaderstats.Cash
								cash.Value += math.round(math.clamp(v.damage/maxHealth.Value,0,1) * cashAdd)
							end
						end
						foundDrone:Destroy() 
					end 

					local listing = verified_drones:FindFirstChild(tag)
					if not listing then return end -- doesn't exist
					if not (listing.Value == player.Name) then return end -- isn't yours

					listing:Destroy()

					local newDrone = rs:WaitForChild("SpiderDroneModel"):Clone()
					newDrone:SetPrimaryPartCFrame(cf)
					newDrone.Name = player.Name
					newDrone.Properties.Target.Value = player.Character

					newDrone.Hit.OnServerEvent:Connect(function(plr,modelHit,tag)
						if plr == player then
							local listing = liveProjectiles[tag]
							if listing and modelHit and modelHit.PrimaryPart then
								-- do a ray check for obstructions
								local origin = listing.startPos
								local goal = modelHit.PrimaryPart.Position
								local direction = (goal - origin).Unit * (origin - goal).Magnitude
								local result = rangedRaycastCheck(origin,direction)
								if not result then -- no obstructions detected
									local level = dataFolder.abilities.Special["Spider Drone"].Level.Value
									local misc = items.Special["Spider Drone"].misc[2]
									local damage = _math.getStat(level,misc.base,misc.multiplier)
									crit = math.round(rngs["Spider Drone"].rng:NextNumber(0,100))
									local isPlayer = game.Players:GetPlayerFromCharacter(modelHit)
									local isDrone = modelHit:FindFirstChild("Drone")
									local isThug = modelHit:IsDescendantOf(workspace.Thugs)
									local isVillain = modelHit:IsDescendantOf(workspace.Villains)
									if isPlayer and not checkSafeZones(goal) then
										--print(plr.Name,"was hit")
										_G.damagePlayer(modelHit,player,damage,"Spider Drone",0,crit)
									end
									--NPC,player,damage,ability,duration,crit
									if isDrone then
										local NPC = NPCs[modelHit.Properties.Tag.Value]
										if NPC and not checkSafeZones(goal) then
											_G.damageNPC(NPC,player,damage,"Spider Drone",0,crit)
										end
									end
									if isThug then
										local NPC = NPCs[modelHit.Name]
										if NPC and NPC.model then
											local zone = NPC.model.Properties.Zone
											local physicalZone = rs.Zones:FindFirstChild(zone.Value)
											if _math.checkBounds(physicalZone.CFrame,physicalZone.Size,newDrone.PrimaryPart.Position) then
												_G.damageNPC(NPC,player,damage,"Spider Drone",0,crit)
											end
										end
									end
									if isVillain then
										local NPC = NPCs[modelHit.Name]
										if NPC and NPC.model then
											local venom = NPC.model:IsDescendantOf(workspace.Villains)
											if venom then
												venom = NPC.model
												local mapCF = CFrame.new(Vector3.new(92, 14.5, -170))
												local mapSize = Vector3.new(1400, 34, 1260)
												if _math.checkBounds(mapCF,mapSize,newDrone.PrimaryPart.Position) then
													_G.damageNPC(NPC,player,damage,"Spider Drone",0,crit)
												end
											end
										end
									end									
								end
								Danger(player,"Special","Spider Drone",tag,goal)
								liveProjectiles[tag] = nil -- remove the tag forever, can't be used again
							end
						end
					end)

					newDrone.Fire.OnServerEvent:Connect(function(plr,target,tag)
						if liveProjectiles[tag] then return end -- don't allow using the same tag
						if plr == player then -- only allow your player to fire this
							local lastAttack = newDrone.Properties.lastAttack
							if tonumber(lastAttack.Value) == nil then -- not a number
								lastAttack.Value = workspace:GetServerTimeNow()
								liveProjectiles[tag] = {
									plr = player,
									startPos = newDrone.PrimaryPart.Position,
									category = "Spider Drone",
									clear=clear,
									start=tick()
								}
								newDrone.Fire:FireAllClients(target,tag,workspace:GetServerTimeNow())
								Danger(player,"Special","Spider Drone",tag,newDrone.PrimaryPart.Position)
							else 
								if workspace:GetServerTimeNow() - lastAttack.Value > 2 then
									lastAttack.Value = workspace:GetServerTimeNow()
									liveProjectiles[tag] = {
										plr = player,
										startPos = newDrone.PrimaryPart.Position,
										category = "Spider Drone",
										clear=clear,
										start=tick()
									}	
									newDrone.Fire:FireAllClients(target,tag,workspace:GetServerTimeNow())
									Danger(player,"Special","Spider Drone",tag,newDrone.PrimaryPart.Position)
								else -- was firing too rapidly, return
									return
								end
							end
						end
					end)

					local level = dataFolder.abilities.Special["Spider Drone"].Level.Value
					local misc = items.Special["Spider Drone"].misc[1]
					local healthAmount = _math.getStat(level,misc.base,misc.multiplier)
					newDrone.Properties.MaxHealth.Value = healthAmount
					newDrone.Properties.Health.Value = healthAmount
					newDrone.Properties.Tag.Value = tag

					newDrone.Parent = workspace.SpiderDrones
					newDrone.PrimaryPart:SetNetworkOwner(player)

					for index,part in (newDrone:GetDescendants()) do 
						if part:IsA("BasePart") then
							part.CollisionGroup="Pets"
						end
					end

					NPCs[tag] = {
						owner=player,
						model = newDrone,
						path = {
							Destroy = function()

							end,
						},
						thread = false,
						attackers = {},
						lastAttacked = workspace:GetServerTimeNow(),
						lastHeal = workspace:GetServerTimeNow(),
						drone = true,
						lastShot = workspace:GetServerTimeNow(),
						clear=clear
					}

					actionRemote:FireClient(player,"spiderDroneDeploy")
					Danger(player,"Special","Spider Drone",tag,newDrone.PrimaryPart.Position)
				end
			elseif args[2]=="Gauntlet" then
				local ownsAbility = dataFolder.abilities.Special["Gauntlet"].Unlocked.Value
				if not ownsAbility then --[[print("doesn't own ability")]] return end
				if args[3]=="Snap" then
					-- tell other players
					local timer=type(args[4])=="number" and args[4] or nil
					local tag=type(args[5])=="string" and args[5] or nil

					local canContinue = tag and timer
					if not canContinue then return end

					if not cooldownCheck(currentTime,timer,cooldowns["Gauntlet"],"Gauntlet") then return end
					
					plr.Character.Humanoid.Health -= math.round(plr.Character.Humanoid.MaxHealth*.33)
					
					local vars={}

					vars.blacklist={}

					vars.origin=plr.Character.PrimaryPart.Position

					vars.level = plr.leaderstats.abilities.Special.Gauntlet.Level.Value
					vars.misc = items.Special.Gauntlet.misc[1]
					vars.range = _math.getStat(vars.level,vars.misc.base,vars.misc.multiplier)
					vars.duration = (vars.range/375)*3

					vars.misc = items.Special.Gauntlet.misc[2]
					vars.damage = _math.getStat(vars.level,vars.misc.base,vars.misc.multiplier)

					for _,playerInstance in (game.Players:GetChildren()) do
						if player ~= playerInstance then
							local remote=playerInstance:FindFirstChild("actionRemote")
							if not remote then continue end
							remote:FireClient(
								playerInstance,
								"ReplicateGauntletEffect",
								player.Name, -- plr name
								timer,
								vars.origin
							)
						end
					end

					vars.checkPlayers=function(range)
						for _,plr in game.Players:GetPlayers() do 
							if plr==player then continue end -- exclude your player 
							if not plr.Character or not plr.Character.PrimaryPart then return end
							if checkSafeZones(plr.Character.PrimaryPart.Position) then continue end -- player can't be in safe zone
							local distance=(plr.Character.PrimaryPart.Position-vars.origin).Magnitude
							if distance<=range and not vars.blacklist[plr.Character] then
								vars.blacklist[plr.Character]=true
								local f = coroutine.wrap(_G.damagePlayer)	
								f(plr.Character,player,vars.damage,"Gauntlet",0,crit)
							end
						end
					end

					vars.runNPC=function(NPC,range,category)
						vars.distance=(vars.origin-vars.model.PrimaryPart.Position).Magnitude
						if vars.distance<=range and not vars.blacklist[vars.model] then
							vars.blacklist[vars.model]=true
							if category=="Thug" then
								local zone_name=NPC.model.Properties.Zone.Value
								local zone=rs.Zones:FindFirstChild(tostring(zone_name))
								if not _math.checkBounds(zone.CFrame,zone.Size,vars.origin) then return end
							end
							if category=="Drone" then
								if checkSafeZones(NPC.model.PrimaryPart.Position) then return end
							end
							local f = coroutine.wrap(_G.damageNPC)
							f(NPC,player,vars.damage,"Gauntlet",0,crit)
						end
					end

					vars.checkNPCs=function(range)
						for tag,NPC in NPCs do 
							vars.model = NPC.model
							if not vars.model or not vars.model:IsDescendantOf(workspace) or not vars.model.PrimaryPart then continue end
							vars.isDrone = vars.model:IsDescendantOf(workspace.SpiderDrones)
							vars.isVillain=vars.model:IsDescendantOf(workspace.Villains)
							vars.isThug=vars.model:IsDescendantOf(workspace.Thugs)
							if vars.isDrone then
								if (vars.model.Name == player.Name) then continue end -- you're not the owner of this drone
								vars.runNPC(NPC,range,"Drone")
							end
							if vars.isVillain then
								vars.runNPC(NPC,range,"Villain")
							end
							if vars.isThug then
								vars.runNPC(NPC,range,"Thug")
							end
						end
					end

					vars.checkCivilians=function(range)
						for _,civilian in workspace.Civilians:GetDescendants() do 
							if civilian:IsA("CFrameValue") then
								local d=(civilian.Value.Position-vars.origin).Magnitude
								if d<=range and not vars.blacklist[civilian] then
									vars.blacklist[civilian]=true
									civilian.checkFleeing.Value = true
								end
							end
						end
					end

					vars.elapsed=(workspace:GetServerTimeNow()-timer)
					vars.duration-=vars.elapsed
					vars.timer=tick()
					while true do 
						vars.elapsed=tick()-vars.timer
						vars.p=math.clamp(vars.elapsed/vars.duration,0,1)
						vars.checkNPCs(vars.range*vars.p)
						vars.checkPlayers(vars.range*vars.p)
						vars.checkCivilians(vars.range*vars.p)
						if vars.p==1 then break end
						task.wait(1/15)
					end

				end
			end
		elseif args[1] == "Melee" then
			local cooldowns = {
				["Punch"] = .25,
				["Kick"] = .5,
				["360 Kick"] = .75
			}
			if args[2] == "Hit" then
				local function checkforModels(item)
					if type(item) == "table" then
						local verifiedArray = {}
						local models = {}
						for i,v in (item) do 
							local model = v[2]
							if model and model:IsA("Model") then
								local isDrone = model:FindFirstChild("Drone")
								if isDrone then 
									local tag = model.Properties.Tag.Value
									if not models[tag] then
										models[tag] = true
										verifiedArray[#verifiedArray+1] = model
									end
								else 
									if not models[model.Name] then -- no dupes
										models[model.Name] = true
										verifiedArray[#verifiedArray+1] = model
									end
								end
							end
						end
						if #verifiedArray > 0 then return verifiedArray end
					else 
						if item and item:IsA("Model") then return item end
					end
					return nil
				end
				local category = (type(args[3]) == "string" and cooldowns[args[3]]) and args[3] or nil
				local hit = checkforModels(args[4])
				local tag = type(args[5]) == "string" and args[5] or nil
				local canContinue = hit and tag and category
				if not canContinue then return end
				
				--[[
				if type(hit) == "table" then
					for _,v in (hit) do 
						print("melee model found = ",v.Name," model is drone = ",v:FindFirstChild("Drone"))
					end
				else 
					print("melee model found = ",hit.Name," model is drone = ",hit:FindFirstChild("Drone"))
				end
				]]
				
				local listing = liveMelee[tag]
				if not listing then return end
				if listing.plr ~= player then return end
				if listing.category ~= category then return end 
				
				local level = dataFolder.abilities.Melee[category].Level.Value
				local misc = items.Melee[category].misc[1]
				local damage = _math.getStat(level,misc.base,misc.multiplier)
				
				local charPos = player.Character.PrimaryPart.Position
				
				local meleeRange = 20
				
				local function sift_through_model(model)
					if model and model:IsDescendantOf(workspace) and model.PrimaryPart then
						if (charPos - model.PrimaryPart.Position).Magnitude < meleeRange then
							local isDrone = model:FindFirstChild("Drone")	
							local NPC = isDrone and NPCs[model.Properties.Tag.Value] or NPCs[model.Name]
							local char = game.Players:GetPlayerFromCharacter(model)

							if NPC and NPC.model and NPC.model:IsDescendantOf(workspace) and NPC.model.PrimaryPart then
								local zone = NPC.model.Properties:FindFirstChild("Zone")
								local canContinue = false
								if zone then
									if checkInZone(zone,charPos) then
										canContinue = true
									end
								else 
									canContinue = true
									if isDrone and checkSafeZones(NPC.model.PrimaryPart.Position) then
										canContinue = false
									end
								end
								if canContinue then
									local f = coroutine.wrap(_G.damageNPC)
									f(NPC,player,damage,"Melee",0,crit)											
								end
							else 
								if char then
									local f = coroutine.wrap(_G.damagePlayer)
									f(model,player,damage,"Melee",0,crit)
								end
							end
						end							
					end
				end
				
				if type(hit) == "table" then -- multiple models
					for _,model in (hit) do
						sift_through_model(model)
					end
				else -- is a single model
					sift_through_model(hit)
				end
				liveMelee[tag].clear(liveMelee[tag])
				liveMelee[tag] = nil -- remove from list after damage
			else
				local category = (type(args[2]) == "string" and cooldowns[args[2]]) and args[2] or nil
				local timer = type(args[3]) == "number" and args[3] or nil
				local tag = type(args[4]) == "string" and args[4] or nil
				local canContinue = timer and tag and category
				if not canContinue then return end

				if not cooldownCheck(currentTime,timer,cooldowns[category],category) then return end

				if category == "Kick" or category == "360 Kick" then
					soundEvent:FireAllClients(player,"kick")
				else 
					soundEvent:FireAllClients(player,"throw")
				end

				timeTrackers[category] = currentTime
				liveMelee[tag] = {
					category = category,
					plr = player,
					clear=clear,
					start=tick()
				}
				
				Danger(player,"Melee",category,tag,player.Character.PrimaryPart.Position)
				
			end
		end			
	end)
	--end)
	
	respawnEvent.OnServerEvent:Connect(function(plr,action)
		if plr ~= player then return end
		if action == "play" then
			player.TeamColor = BrickColor.new(1)
			player.RespawnLocation = workspace.spawn2
			local skin = _G.getEquippedSkin(player)
			if not skin then -- just put on the classic suit if you didn't ahve anything else on
				player.leaderstats.skins["Classic"].Equipped.Value=true
			end
			skin=skin or "Classic"
			local character=plr.Character or plr.CharacterAdded:Wait()
			local suit = character:FindFirstChild("Suit")
			if skin then
				if not suit then -- you're not wearing a suit
					_G.putOnSkin(player,skin,character.PrimaryPart.CFrame)
				else -- you're wearing a suit
					if suit.Value ~= skin then -- isn't the same skin, change
						_G.putOnSkin(player,skin,character.PrimaryPart.CFrame)	
					end
				end
				return
			end
			return			
		end
		plr:SetAttribute("spawned",true)
		--print("set attribute")
		local isPlaying = player.leaderstats.temp.isPlaying
		isPlaying.Value = true
	end)

	rebirthEvent.OnServerEvent:Connect(function(plr)
		if plr ~= player then return end
		local leaderstats = player.leaderstats
		local rebirths = dataFolder.Rebirths
		if rebirths.Value == 10 then return end -- don't let them get more than 10 rebirths
		local cash = dataFolder.Cash
		local rebirthCost = _math.getRebirthPrice(rebirths.Value)
		if cash.Value >= rebirthCost then
			dataCopy.cash -= rebirthCost
			dataFolder.Cash.Value -= rebirthCost
			dataCopy.rebirths += 1
			dataFolder.Rebirths.Value += 1
			
			AnalyticsService:LogEconomyEvent(
				plr,
				Enum.AnalyticsEconomyFlowType.Sink,
				"Cash",
				rebirthCost,
				cash.Value,
				Enum.AnalyticsEconomyTransactionType.Shop.Name,
				"Rebirths"
			)
			
			-- reset abilities
			for categoryName,data1 in (dataCopy.abilities) do 
				for abilityName,data2 in (data1) do 
					for i,v in (data2) do 
						data2.Level = 1
						dataFolder.abilities[categoryName][abilityName].Level.Value = 1
					end
				end
			end
			levelEvent:FireAllClients(plr)
			--rs.CashEvent:FireAllClients(plr)
			EP.Calculate(player)
		end
	end)

	rollRemote.OnServerEvent:Connect(function(plr,clientTime)
		local currentTime = workspace:GetServerTimeNow()
		if plr ~= player then return end -- don't allow other players to trigger your remote
		local hasCharacter = plr.Character and plr.Character:IsDescendantOf(workspace)
		if not hasCharacter then return end
		local cooldown = 1
		if cooldownCheck(currentTime,clientTime,cooldown,"Roll") and not cs:HasTag(plr.Character,"ragdolled") then
			timeTrackers["Roll"] = currentTime
			local isRolling = dataFolder.temp.isRolling
			isRolling.Value = true
			if dataFolder.temp.isOnFire.Value then
				dataFolder.temp.isOnFire.Value = false
				rs.FireEvent:FireAllClients(plr.Character,false)
			end
			local elapsed = workspace:GetServerTimeNow() - clientTime
			task.wait(1-elapsed) -- close enough
			isRolling.Value = false
		end
	end)

	dataRemote.OnServerEvent:Connect(function(plr,data,...)
		if (plr ~= player) then return end
		-- wrap in pcall
		if (data == "changeSwim") then
			local args = {...}
			dataFolder.temp.isSwimming.Value = args[1]
			--print("SERVER changed swimming to ",dataFolder.temp.isSwimming.Value)
		elseif (data == "changeClimb") then 
			local args = {...}
			dataFolder.temp.isClimbing.Value = args[1]
			--print("SERVER changed climbing to ",dataFolder.temp.isClimbing.Value)			
		end
	end)

	abilityRemote.OnServerEvent:Connect(function(plr,category,ability)
		if (plr ~= player) then return end
		-- wrap in pcall
		-- update health of drone here
		local value = dataFolder.abilities[category][ability]
		if not value then return end --// value doesn't exist
		local ownsItem = value.Unlocked.Value
		local item=items[category][ability]
		local cost = ownsItem and _math.getPriceFromLevel(value.Level.Value,item.upgrade) or item.cost
		if not (ownsItem) then -- purchase item
			if cost<=dataFolder.Cash.Value then -- can afford
				dataCopy.cash -= cost -- set the data
				dataFolder.Cash.Value -= cost
				dataCopy.abilities[category][ability].Unlocked=true
				value.Unlocked.Value=true
				
				AnalyticsService:LogEconomyEvent(
					plr,
					Enum.AnalyticsEconomyFlowType.Sink,
					"Cash",
					cost,
					dataFolder.Cash.Value,
					Enum.AnalyticsEconomyTransactionType.Shop.Name,
					"Ability Purchase"
				)
				
				levelEvent:FireAllClients(plr)
				--rs.CashEvent:FireAllClients(plr)
			end
		else -- upgrade item
			if (cost <= dataFolder.Cash.Value) then -- if you have enough
				if value.Level.Value == 12 then return end
				--print("changed data")
				dataCopy.cash -= cost -- set the data
				dataFolder.Cash.Value -= cost
				dataCopy.abilities[category][ability].Level += 1 -- set the data
				value.Level.Value += 1
				
				AnalyticsService:LogEconomyEvent(
					plr,
					Enum.AnalyticsEconomyFlowType.Sink,
					"Cash",
					cost,
					dataFolder.Cash.Value,
					Enum.AnalyticsEconomyTransactionType.Shop.Name,
					"Ability Upgrade"
				)
				
				levelEvent:FireAllClients(plr)
				--rs.CashEvent:FireAllClients(plr)
				if ability == "Spider Drone" then
					local foundDrone = workspace.SpiderDrones:FindFirstChild(plr.Name)
					if foundDrone then
						local level = value.Level.Value
						local misc = items.Special["Spider Drone"].misc[1]
						local newHealth = _math.getStat(level,misc.base,misc.multiplier)
						foundDrone.Properties.MaxHealth.Value = newHealth
					end
				end
				
				for _,slot in dataFolder.hotbar:GetChildren() do -- check the hotbar if you have 
					if slot.Ability.Value==ability then -- you found the ability!
						EP.Calculate(player)
					end
				end
				
				return
			end
		end
	end)

	skinsRemote.OnServerEvent:Connect(function(plr,skin,action,cframe)
		if (plr ~= player) then return end
		local skinExists = dataFolder.skins[skin]
		if not skinExists then --[[print("skin doesn't exist")]] return end
		local isEquipped = dataFolder.skins[skin].Equipped.Value
		local isUnlocked = dataFolder.skins[skin].Unlocked.Value
		local level = dataFolder.skins[skin].Level
		local character = player.Character 
		if not character then return end
		if cs:HasTag(character,"ragdolled") then return end

		if isUnlocked then
			if action=="upgrade" then -- you upgrade the skin here
				local upgradeCost = _math.getPriceFromLevel(level.Value,1000)
				if dataFolder.Cash.Value >= upgradeCost then
					if level.Value == 24 then return end
					dataCopy.cash -= upgradeCost -- change the data
					dataCopy.skins[skin].Level += 1
					dataFolder.Cash.Value -= upgradeCost
					dataFolder.skins[skin].Level.Value += 1
					
					AnalyticsService:LogEconomyEvent(
						plr,
						Enum.AnalyticsEconomyFlowType.Sink,
						"Cash",
						upgradeCost,
						dataFolder.Cash.Value,
						Enum.AnalyticsEconomyTransactionType.Shop.Name,
						"Suit Upgrade"
					)
					
					local extraHealth = _math.getSuitHealth(dataFolder.skins[skin].Level.Value)
					local character = player.Character
					local isSuit = character:FindFirstChild("Suit")
					if isSuit then
						if isSuit.Value == skin then
							local humanoid = character:WaitForChild("Humanoid")
							humanoid.MaxHealth = 100 + extraHealth
						end
					end
					levelEvent:FireAllClients(plr)
					--rs.CashEvent:FireAllClients(plr)
					EP.Calculate(player)
				end
				return
			end
			if isEquipped then
				--print("take off!")
				dataFolder.skins[skin].Equipped.Value = false
				-- reward the player's attackers before taking off skin
				local excess=player.Character.Humanoid.MaxHealth-100
				local baseCash = math.round(50*(excess/100))
				rewardPlayerAttackers(player,baseCash)
				dataFolder.temp.previousHealth.Value = character.Humanoid.Health/character.Humanoid.MaxHealth -- update the previous health before taking the skin off
				pcall(function()
					player:LoadCharacter()
				end)
				return
			else
				-- reward the player's attackers before putting on skin
				--local baseCash = math.round(50*(100/player.Character.Humanoid.MaxHealth))
				--rewardPlayerAttackers(player,baseCash)

				UndoAllSkins(dataFolder.skins)
				--dataFolder.temp.previousHealth.Value = "" -- reset the previous health when you put a skin on
				_G.putOnSkin(plr,skin,cframe)
				return
			end
		else
			--print("changed data")
			if items.Skins[skin].unlock then
				if skin=="Stealth" then
					local amount=dataFolder.objectives.current.Value
					local cost=15
					if amount>=cost or dataFolder.objectives.completed.Value then -- you can unlock this suit
						dataCopy.skins[skin].Unlocked = true -- change the data
						dataFolder.skins[skin].Unlocked.Value = true
						levelEvent:FireAllClients(plr)
					else 
						--print("you haven't completed all of the objectives!")
					end
				elseif skin=="Supreme Sorcerer" then
					local amount=dataFolder.Rebirths.Value
					local cost=10
					if amount>=cost then -- you can unlock this suit
						dataCopy.skins[skin].Unlocked = true -- change the data
						dataFolder.skins[skin].Unlocked.Value = true
						levelEvent:FireAllClients(plr)
					end					
				end
			else 
				local cash = dataCopy.cash
				local cost = items.Skins[skin].cost
				if (cost <= cash) then -- you have enough money
					dataCopy.skins[skin].Unlocked = true -- change the data
					dataFolder.skins[skin].Unlocked.Value = true
					dataCopy.cash -= cost -- change the data
					dataFolder.Cash.Value -= cost
					
					AnalyticsService:LogEconomyEvent(
						plr,
						Enum.AnalyticsEconomyFlowType.Sink,
						"Cash",
						cost,
						dataFolder.Cash.Value,
						Enum.AnalyticsEconomyTransactionType.Shop.Name,
						"Suit Unlock"
					)
					
					levelEvent:FireAllClients(plr)
					--rs.CashEvent:FireAllClients(plr)
				end
			end
		end
	end)

	dragRemote.OnServerEvent:Connect(function(plr,...)
		if (plr ~= player) then return end
		-- wrap in pcall
		--print("changed data")
		local data = {...}
		if (data[1] == "swap") then
			local startPos = dataCopy.hotbar[data[2][1]]
			local startAbility = startPos.Ability
			local startCategory = startPos.Category

			local endPos = dataCopy.hotbar[data[2][2]]
			local endAbility = endPos.Ability
			local endCategory = endPos.Category

			startPos.Ability = endAbility
			startPos.Category = endCategory
			
			local slot1=dataFolder.hotbar:FindFirstChild(tostring(data[2][1]))
			slot1.Category.Value=endCategory
			slot1.Ability.Value=endAbility
			
			endPos.Ability = startAbility
			endPos.Category = startCategory		
			
			local slot2=dataFolder.hotbar:FindFirstChild(tostring(data[2][2]))
			slot2.Category.Value=startCategory
			slot2.Ability.Value=startAbility	
			
			--print("start ability = ",startPos.Ability)
			--print("start Category = ",startPos.Category)
			--print("end ability = ",endPos.Ability)
			--print("end ability = ",endPos.Category)
			
		elseif (data[1] == "add") then
			local startAbility = dataFolder.abilities[data[2][1]][data[2][2]]
			local startAbilityUnlocked = startAbility.Unlocked.Value
			if (startAbilityUnlocked) then
				--print(startAbility.Name.." ability is unlocked")
				local endPos = dataCopy.hotbar[data[2][3]]
				endPos.Category = data[2][1]
				endPos.Ability = data[2][2]
				
				local slot=dataFolder.hotbar:FindFirstChild(tostring(data[2][3]))
				slot.Category.Value=data[2][1]
				slot.Ability.Value=data[2][2]
				--print("end ability = ",endPos.Ability)
				--print("end ability = ",endPos.Category)
			end
		elseif (data[1] == "remove") then
			local itemPos = dataCopy.hotbar[data[2][1]]
			itemPos.Category = ""
			itemPos.Ability = ""
			local slot=dataFolder.hotbar:FindFirstChild(tostring(data[2][1]))
			slot.Category.Value=""
			slot.Ability.Value=""
		end
		EP.Calculate(player)
	end)

	player.CharacterAdded:Connect(function(character)
		--print("CharacterAdded")
		player:SetAttribute("LastRespawn",tick())
		--dataFolder.attackers:SetAttribute("totalDamage",0)
		local duration = dataFolder.ragdollData.duration
		local start = dataFolder.ragdollData.start
		duration.Value = 0
		start.Value = workspace:GetServerTimeNow()
		dataFolder.temp.isOnFire.Value = false -- reset fire
		rs.FireEvent:FireAllClients(character,false)

		local isPlaying = player.leaderstats.temp.isPlaying
		if isPlaying.Value then
			local skin = _G.getEquippedSkin(player)
			local suit = character:FindFirstChild("Suit")
			if skin then
				rs.EarningsRemote:FireClient(player,skin)
				if not suit then -- you're not wearing a suit
					_G.putOnSkin(player,skin,character.PrimaryPart.CFrame)
				else -- you're wearing a suit
					if suit.Value ~= skin then -- isn't the same skin, change
						_G.putOnSkin(player,skin,character.PrimaryPart.CFrame)	
					end
				end
				return
			end
		end
		
		_G.prepareCharacter(player,character)
	end)
	pcall(function()
		player:LoadCharacter()
	end)
end

local function Remove_Player_Trip_Webs(plr:Player, temp:Folder)
	local tripWebs = temp.tripWebs
	local hasListing=#tripWebs.serverAmount:GetChildren() > 0
	local playerExists=plr:IsDescendantOf(game.Players)
	local canContinue=hasListing and playerExists
	if not canContinue then return end
	local children = tripWebs.serverAmount:GetChildren()
	for i = 1,#children do 
		local tag = children[i].Name
		local TripWebListing = LiveTripWebs[tag]
		if not TripWebListing then continue end
		TripWebListing.hitbox:Destroy()
		TripWebListing.clear(LiveTripWebs[tag])
		LiveTripWebs[tag] = nil
		--print("removed hitbox and listing")
	end
	for _,playerInstance in (game.Players:GetChildren()) do
		if plr ~= playerInstance then
			local remote=playerInstance:FindFirstChild("actionRemote")
			if not remote then continue end
			remote:FireClient(
				playerInstance,
				"trip remove",
				plr.Name, -- plr name
				"all", -- tag
				nil -- usually folder name goes here
			)
		end
	end
end

players.PlayerAdded:Connect(onPlayerAdded)

for index,player in game.Players:GetPlayers() do 
	onPlayerAdded(player)
end

players.PlayerRemoving:Connect(function(plr)
	local leaderstats = plr:FindFirstChild("leaderstats")
	if not leaderstats then return end
	local temp = leaderstats.temp 
	Remove_Player_Trip_Webs(plr,temp)
end)

local function Manage_Attacking(leaderstats:Folder)
	local attacking = leaderstats.attacking
	for i,v in (attacking:GetChildren()) do 
		local destroyed = false
		local name = v.Name
		local plr = game.Players:FindFirstChild(name)
		local NPC = NPCs[name]
		if plr then
			if plr.Character and plr.Character:FindFirstChild("Humanoid") and not (plr.Character.Humanoid.Health > 0) then
				destroyed = true
				v:Destroy()
			end
		end
		if NPC then
			if NPC.model and not (NPC.model.Properties.Health.Value > 0) then
				destroyed = true
				v:Destroy()
			end
		end
		local timeSinceLastAttack = workspace:GetServerTimeNow() - v.Value
		if timeSinceLastAttack > 5 then
			if not destroyed then
				v:Destroy()
			end
		end
	end
end

local function Manage_Attackers(leaderstats:Folder)
	local attackers = leaderstats.attackers
	for i,v in (attackers:GetChildren()) do
		local destroyed = false
		local name = v.Name
		--local plr = game.Players:FindFirstChild(name)
		local NPC = NPCs[name]
		if NPC then
			if NPC.model and not (NPC.model.Properties.Health.Value > 0) then -- the NPC is dead
				v:Destroy()
			end
		end
	end
end

local function Manage_Fire(temp:Folder, character:Model, humanoid:Humanoid)
	local isOnFire = temp.isOnFire
	local fireTick = isOnFire.tick
	local lastHit = isOnFire.hit
	if not isOnFire.Value then return end
	local currentTime = workspace:GetServerTimeNow()
	local elapsed = currentTime - fireTick.Value
	if elapsed >= 5 then -- over 5 seconds, stop it
		isOnFire.Value = false 
		rs.FireEvent:FireAllClients(character,false)
	else -- dmg every second 
		if workspace:GetServerTimeNow() - lastHit.Value >= 1 then
			lastHit.Value = currentTime
			humanoid:TakeDamage(5)
		end
	end
end

local function Manage_Electric(temp:Folder, character:Model, humanoid:Humanoid)
	local isElectrified = temp.isElectrified
	local _tick = isElectrified.tick
	local lastHit = isElectrified.hit
	if not isElectrified.Value then return end
	local currentTime = workspace:GetServerTimeNow()
	local elapsed = currentTime - _tick.Value
	if elapsed >= 5 then -- over 5 seconds, stop it
		isElectrified.Value = false 
		rs.FireEvent:FireAllClients(character,false)
	else -- dmg every second 
		if workspace:GetServerTimeNow() - lastHit.Value >= 1 then
			lastHit.Value = currentTime
			humanoid:TakeDamage(10)
		end
	end
end

local REGEN_RATE = 1/100 -- Regenerate this fraction of MaxHealth per second.
local function Heal_Drone(player:Player)
	local drone = workspace.SpiderDrones:FindFirstChild(player.Name)
	if not drone then return end
	local properties = drone.Properties
	local health = properties.Health
	local maxHealth = properties.MaxHealth
	local tag = properties.Tag
	local listing = NPCs[tag.Value]
	local degradedHealth=health.Value < maxHealth.Value
	local stillAlive=health.Value > 0 and not cs:HasTag(drone,"Died")

	local canContinue=listing and degradedHealth and stillAlive

	if not canContinue then return end

	local currentTime = workspace:GetServerTimeNow()
	local canHeal=currentTime - listing.lastHeal > 1
	if not canHeal then return end

	local elapsed = math.clamp(currentTime - listing.lastHeal,0,1)
	local dh = math.round(elapsed*REGEN_RATE*maxHealth.Value)
	health.Value = math.min(health.Value + dh, maxHealth.Value)
	listing.lastHeal = workspace:GetServerTimeNow()
	listing.totalDamage=listing.totalDamage~=nil and listing.totalDamage or 0
	for i,v in (listing.attackers) do -- remove damage from attackers
		local damage=math.clamp(v.damage,0,listing.totalDamage)
		local subtract=(damage/listing.totalDamage)*dh
		subtract=subtract==subtract and subtract or 0
		v.damage = math.clamp(v.damage - subtract,0,maxHealth.Value)
		if v.damage==0 then 
			listing.attackers[i]=nil
		end
		--print("reduced",i,"damage to",v.damage)
	end
	listing.totalDamage=math.clamp(listing.totalDamage-dh,0,maxHealth.Value)

end

local function Regen_Health(humanoid:Humanoid, leaderstats:Folder)
	local temp=leaderstats.temp
	local degradedHealth=humanoid.Health < humanoid.MaxHealth
	local stillAlive=humanoid.Health > 0
	local lastHealValue = temp.lastHeal
	local lastHeal = tonumber(lastHealValue.Value)
	local elapsed = tick() - lastHeal
	local canHeal=elapsed>=1
	local canContinue=degradedHealth and stillAlive and canHeal
	if not canContinue then return end

	elapsed = math.clamp(elapsed,0,1)
	local dh = math.round(elapsed*REGEN_RATE*humanoid.MaxHealth)
	humanoid.Health = math.min(humanoid.Health + dh, humanoid.MaxHealth)
	temp.previousHealth.Value=humanoid.Health/humanoid.MaxHealth
	-- take away recorded damage from attackers when you regen
	if not leaderstats.attackers:GetAttribute("totalDamage") then
		leaderstats.attackers:SetAttribute("totalDamage",0)
	end
	local totalDamage=leaderstats.attackers:GetAttribute("totalDamage")
	for i,v in (leaderstats.attackers:GetChildren()) do
		local damage = v:FindFirstChild("damage")
		if not damage then continue end
		local _damage=math.clamp(damage.Value,0,totalDamage)
		local subtract=(_damage/totalDamage)*dh
		subtract=subtract==subtract and subtract or 0
		damage.Value=math.clamp(damage.Value-subtract,0,humanoid.MaxHealth)
		if damage.Value == 0 then
			v:Destroy() -- remove the listing if damage reaches 0
		end	
	end
	leaderstats.attackers:SetAttribute("totalDamage",math.clamp(totalDamage-dh,0,humanoid.MaxHealth))
	lastHealValue.Value = tick()
end

local function Manage_Combos(temp:Folder)
	if workspace:GetServerTimeNow()-temp.combos.timer.Value >=1 then -- reset to 0
		temp.combos.Value=0
	end	
end

local function Manage_Multikills(temp:Folder)
	if tick()-temp.multikills.tick.Value >=1 then -- reset to 0
		temp.multikills.Value=0
	end
end

local function Manage_Killstreak_Active(leaderstats:Folder)
	local killstreak=leaderstats.Kills
	if tick()-killstreak.tick.Value>=1 then
		killstreak.active.Value=false
	end
end

local function Check_Player_Location(player:Player, character:Model, temp:Folder)
	--local fellTooFar = character:GetPivot().Position.Y <= -500
	local mapCF = CFrame.new(Vector3.new(92, 1000, -170)) * CFrame.Angles(0,math.rad(90),0)
	local mapSize = Vector3.new(4000,2200,4000)
	local wentTooFar = not _math.checkBounds(mapCF,mapSize,character.PrimaryPart.Position)
	if wentTooFar and temp.isPlaying.Value then
		player.Character:SetPrimaryPartCFrame(workspace.spawn2.CFrame+Vector3.new(math.random(-20,20),3,math.random(-20,20)))--player:LoadCharacter()
	end
end

local function Manage_Players()
	for _,player in (players:GetPlayers()) do
		if not player.Character then continue end
		local leaderstats = player:WaitForChild("leaderstats")
		local temp = leaderstats:WaitForChild("temp")
		local character = player.Character
		local humanoid = character.Humanoid			

		Manage_Combos(temp)
		Manage_Multikills(temp)
		--Manage_Killstreak_Active(leaderstats)
		Manage_Attacking(leaderstats)
		Manage_Attackers(leaderstats)
		Manage_Fire(temp,character,humanoid)
		--Manage_Electric(temp,character,humanoid)
		Check_Player_Location(player,character,temp)

		if not (humanoid.Health > 0) then
			cs:AddTag(character,"Died")
		end

		Regen_Health(humanoid, leaderstats)
		Heal_Drone(player)
	end
end

local value=Instance.new("StringValue")
value:GetPropertyChangedSignal("Value"):Connect(Manage_Players)

local Leaderboards_Running=false 
local function Manage_Leaderboards()
	Leaderboards_Running=true
	Leaderboards:Refresh()
	Update_Folder(rs["Top Cash"],Leaderboards:FetchCash())
	Update_Folder(rs["Top Killstreak"],Leaderboards:FetchKills())
	Update_Folder(rs["Top Donors"],Leaderboards:FetchDonations())
	lastRefresh=tick()
	Leaderboards_Running=false
	--print("loaded leaderboards!")
end

while true do
	if tick()-lastRefresh>=60 and Leaderboards_Running==false then
		task.spawn(Manage_Leaderboards)
	end
	value.Value=tick()
	task.wait(1/15)
end