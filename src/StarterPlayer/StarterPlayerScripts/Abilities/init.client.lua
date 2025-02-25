local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hotbarUI = playerGui:WaitForChild("hotbarUI")
local selected = hotbarUI:WaitForChild("container"):WaitForChild("Selected")
local prevSelected=selected.Value

local actionRemote = player:WaitForChild("actionRemote")

local timeOfDay = player:WaitForChild("PlayerScripts"):WaitForChild("Day_Night"):WaitForChild("TimeOfDay")

local leaderstats  = player:WaitForChild("leaderstats")
local abilities = leaderstats:WaitForChild("abilities")
local temp = leaderstats:WaitForChild("temp")
local criticals = temp:WaitForChild("criticals")

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
	["Gauntlet"]={
		rng=Random.new(criticals["Gauntlet"].seed.Value)
	}
}

local isSwimming = temp:WaitForChild("isSwimming")
local isSprinting = temp:WaitForChild("isSprinting")
local isClimbing = temp:WaitForChild("isClimbing")
local isChargeJumping = temp:WaitForChild("isChargeJumping")
local isWebbing = temp:WaitForChild("isWebbing")
local isRolling = temp:WaitForChild("isRolling")

local camera = workspace.CurrentCamera

local rs = game:GetService("ReplicatedStorage")
local cs = game:GetService("CollectionService")
local ps = game:GetService("PhysicsService")
local ts = game:GetService("TweenService")
local sizeTween = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0)

local runService = game:GetService("RunService")
local animsFolder = rs:WaitForChild("animations")
local movementAnims = animsFolder:WaitForChild("movement")
local idleAnims = animsFolder:WaitForChild("idle")
local combatAnims = animsFolder:WaitForChild("combat")
local punchAnimFolder = combatAnims:WaitForChild("punch")
local shootAnimFolder = combatAnims:WaitForChild("shoot")

local _math = require(rs:WaitForChild("math"))
local items = require(rs:WaitForChild("items"))
local comicPops = require(rs:WaitForChild("comicPops"))

local clock = rs:WaitForChild("clock")

local hitAnims = combatAnims:WaitForChild("reaction")
local hitAnimPlaying = false

local effects= require(rs:WaitForChild("Effects"))
local Danger_Event = rs:WaitForChild("DangerEvent")

local triggers={
	["Melee"] = {
		["Punch"]=20,
		["Kick"]=20,
		["360 Kick"]=20
	},
	["Ranged"] = {
		["Impact Web"]=100,
		["Snare Web"]=100,
		["Shotgun Webs"]=100,
	},
	["Special"] = {
		["Spider Drone"]=100,
		["Web Bomb"]=100,
		-- for the gauntlet do it by case-by-case basis
	},
	["Traps"] = {
		["Anti Gravity"] = 100,
		["Trip Web"] = 100
	}
}

local function Get_Nearby_Civilians(pos,category,ability)
	local d = triggers[category][ability]
	if not d then return end
	local nearby={}
	for _,group in (workspace:WaitForChild("Civilians"):GetChildren()) do 
		for _,civilian in (group:GetChildren()) do 
			if (civilian.Value.Position-pos).Magnitude <= d then
				nearby[#nearby+1]=civilian
			end
		end
	end 
	return nearby
end

local function castRay(origin,target,length)
	length = length ~= nil and length or 50
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {
		workspace:WaitForChild("BuildingBounds"),
		workspace:WaitForChild("Traintracks")
	}
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		(target - origin).Unit * length,
		raycastParams
	)
	return raycastResult
end

local function stopAllOtherTracks(humanoid,ignore1,ignore2,ignore3)
	local AirTrickPlaying = nil
	for _,track in (humanoid:GetPlayingAnimationTracks()) do 
		local name = track.Animation.Name
		if name ~= ignore1 and name ~= ignore2 and name ~= ignore3 then
			if track.Animation:IsDescendantOf(animsFolder) then
				if track.Animation ~= idleAnims:WaitForChild("fight_idle") and track.Animation.Name ~= "Roll" then
					track:Stop()
				end
			end		
		else 
			AirTrickPlaying = track
		end
	end
	return AirTrickPlaying
end

local function returnTheta(startPos,endPos,axis)
	local adjascent = (startPos[axis] - endPos[axis]) -- greater number always first
	local hypotenuse = (startPos-endPos).magnitude
	return math.deg(math.acos(adjascent/hypotenuse))
end

-- if they hit the action button on mobile or if they click

local punchAnims = {
	[1] = punchAnimFolder:WaitForChild("LeftJab"),
	[2] = punchAnimFolder:WaitForChild("RightJab"),
	[3] = punchAnimFolder:WaitForChild("LeftCross"),
	[4] = punchAnimFolder:WaitForChild("RightCross"),
}

local punchCombos = {
	[1] = {
		[1] = punchAnims[1], 
		[2] = punchAnims[2], 
		[3] = punchAnims[3], 
		[4] = punchAnims[4]
	}
}

local minLines = 1
local maxLength = 1000
local minLength = 0.00001 -- small but not zero

local ActionButtonDown = temp:WaitForChild("ActionButtonDown")

--[[
local camPart = workspace.camPart
local offset = workspace.Offset

local direction = (camPart.Position - offset.Position).Unit -- the order matters for the first and last cframe for points
camPart.CFrame = CFrame.new(camPart.Position,CFrame.new(camPart.Position) * direction)
]]

local function getPoints(startPos,endPos,webAmount)
	local distance = (startPos - endPos).Magnitude
	local webLength = distance/webAmount
	local points = {}
	points[1] = CFrame.new(startPos,endPos)
	points[webAmount+1] = CFrame.new(endPos,CFrame.new(endPos) * (endPos - startPos).Unit)
	if (webAmount == 1) then return points end
	for i = 1,webAmount-1 do
		points[i+1] = CFrame.new(points[1].Position:Lerp(points[webAmount+1].Position, (i*webLength)/distance),points[webAmount+1].Position)
	end
	return points
end

local function ViewportPointToWorldCoordinates(x,y)
	local ray = workspace.CurrentCamera:ViewportPointToRay(x,y)
	return ray.Origin,ray.Direction * 200
end

local function ClampMagnitude(v, max)
	if v.magnitude == 0 then return Vector3.new(0,0,0) end -- prevents NAN,NAN,NAN
	return v.Unit * math.min(v.Magnitude, max) 
end

local renderedProjectiles = {}

local function isPlayer2099(plrName)
	local plr=game.Players:FindFirstChild(plrName)
	if not plr then return false end
	if not plr.Character then return false end
	local suit=plr.Character:FindFirstChild("Suit")
	local color
	local material
	if not suit then return false end
	local is2099=suit.Value=="ATSV 2099"
	local isSymbiote=suit.Value=="Symbiote" or suit.Value=="Supreme Sorcerer" or suit.Value=="Spider Girl"
	if is2099 then
		color=Color3.fromRGB(218, 133, 65)
		material=Enum.Material.Neon
	end
	if isSymbiote then
		color=Color3.fromRGB(0,0,0)
		material=Enum.Material.SmoothPlastic
	end
	return {color=color,material=material}
end

local function getCharacterModelsArray()
	local t = {}
	for _,plr in (game.Players:GetPlayers()) do 
		if plr.Character and plr.Character ~= player.Character then
			t[#t+1] = plr.Character
		end
	end
	return t
end

local function renderProjectile(origin,target,category,offset,playerWhoShotName,dt,tag)
	local distance = 250

	local projectiles = {
		["Impact Web"] = rs:WaitForChild("ImpactWeb"),
		["Shotgun Webs"] = rs:WaitForChild("ImpactWeb"),
		["Snare Web"] = rs:WaitForChild("TrapWeb")
	}

	local sizes = {
		["Impact Web"] = Vector3.new(1.189, 1.163, 3.144),
		["Shotgun Webs"] = Vector3.new(1.189, 1.163, 3.144),
		["Snare Web"] = Vector3.new(4, 4, 3.334) *.75
	}

	local speeds = {
		["Impact Web"] = 80,
		["Snare Web"] = 40,
		["Shotgun Webs"] = 80
	}

	local startCFrame = CFrame.new(origin,target)
	local endCFrame = startCFrame * CFrame.new(0,0,-distance) * CFrame.new(offset)
	local is2099=isPlayer2099(playerWhoShotName)
	local projectile = projectiles[category]:Clone()
	projectile.Name = tag
	projectile.CFrame = startCFrame
	projectile.Size = Vector3.new(0,0,0)
	projectile.Color=is2099 and is2099.color or Color3.fromRGB(255,255,255)
	projectile.Material=is2099 and is2099.material or Enum.Material.Plastic
	projectile.Parent = workspace:WaitForChild("Projectiles")

	-- send in the projectile, startCF, endCF, timer, startTick, i, player

	renderedProjectiles[#renderedProjectiles+1] = {
		bullet = projectile,
		startCF = startCFrame,
		endCF = endCFrame,
		drop = distance/2,
		timer = (distance/speeds[category]) - (workspace:GetServerTimeNow() - dt),
		startTick = tick(),
		size = sizes[category],
		category = category,
		iteration = 0,
		lastRayCF = projectile.CFrame,
		plrName = playerWhoShotName,
		finish = false,
		impactTick = nil,
		attachWeb = rs:WaitForChild("AttachWeb"):Clone(),
		hit = false,
	}

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

local function hitMarker(model,dmg,crit,ability,category,origin)
	--print("model=",model.Name)
	local headPart = model:FindFirstChild("Head")
	local pos = model.PrimaryPart.Position
	
	local villain = model:IsDescendantOf(workspace:WaitForChild("Villains"))
	if villain then
		-- check for spine and falsehead, if spine doesn't exist use falsehead/head
		local falseHead = model:FindFirstChild("FalseHead")
		headPart=falseHead or headPart
		local properties=model:FindFirstChild("Properties")
		local spine = properties and properties:FindFirstChild("Spine") or nil
		pos = spine and spine.Value.TransformedWorldCFrame.Position or nil
		pos= pos or headPart.Position
	end
	
	local isPlayer=game.Players:GetPlayerFromCharacter(model)
	local hideDamage=false
	if isPlayer then
		local yourPVPfalse=temp:WaitForChild("PvP").Value==false
		local playerPVPfalse=isPlayer:WaitForChild("leaderstats"):WaitForChild("temp"):WaitForChild("PvP").Value==false
		local isInSafeZone=checkSafeZones(model.PrimaryPart.Position)
		hideDamage= yourPVPfalse or playerPVPfalse or isInSafeZone
	end
	
	local random = _math.defined(0,100)
	if random <= 33.3 and headPart ~= nil then
		local popNames = items[category][ability].comicPops
		local popName = popNames[math.random(1,#popNames)]
		local f = coroutine.wrap(comicPops.newPopup)
		f(popName,headPart)		
	end
	
	_G.tweenHighlight(model)
	
	local isDrone=model:FindFirstChild("Drone")
	if isDrone then
		hideDamage=checkSafeZones(model.PrimaryPart.Position)
	end
	
	local isThug=model:IsDescendantOf(workspace:WaitForChild("Thugs"))
	if isThug then
		local zone_name=tostring(model:WaitForChild("Properties"):WaitForChild("Zone").Value)
		local zone=rs:WaitForChild("Zones"):FindFirstChild(zone_name)
		if category=="Ranged" or ability=="Gauntlet" or ability=="Web Bomb" then
			hideDamage=not _math.checkBounds(zone.CFrame,zone.Size,origin)
		end
		--[[
		local part=Instance.new("Part")
		part.Anchored=true
		part.CanCollide=false
		part.Size=Vector3.new(1,1,1)
		part.Position=origin
		part.Transparency=.5
		part.BrickColor=BrickColor.Red()
		part.Parent=workspace
		]]
	end
	
	local size = .6
	local color=Color3.fromRGB(255,255,255)
	local font=Enum.Font.LuckiestGuy
	if crit then
		color=Color3.fromRGB(239, 205, 48)
		font=Enum.Font.Bangers
		size=.8
	end
	
	local s=hideDamage and "0" or math.round(dmg)
	local offset = Vector3.new(_math.defined(-2,2),2,_math.defined(-2,2))
	local size=UDim2.new(2,10,size,10)
	--print("size=",size)
	local timer={total=40,up=10,down=30}
	local t={
		s=s,
		difference=0,
		size=size,
		color=color,
		font=font,
		pos=pos,
		offset=offset,
		timer=timer,
		--strokeColor=Color3.fromRGB(25,25,25)
	}
	effects:PrepareFlyoff("damage",t,true)
end

local function getEquippedSkin()
	for i,v in (leaderstats:WaitForChild("skins"):GetChildren()) do 
		if v:WaitForChild("Equipped").Value then
			return v.Name
		end
	end
end

local function combo(misc,level)
	local damage = _math.getStat(level,misc.base,misc.multiplier)
	local combos=temp.combos
	local elapsed=workspace:GetServerTimeNow()-combos.timer.Value
	local add=elapsed<1 and 1 or 0
	local base=elapsed<1 and combos.Value or 0
	return math.round(((base+add)*.1)*damage)+damage
end

local function getNewDamageWithCritical(dmg,critical)
	local damage = dmg
	local skin = getEquippedSkin()
	local crit = false
	if skin then
		local level = leaderstats:WaitForChild("skins"):WaitForChild(skin):WaitForChild("Level").Value
		local criticalAmount = _math.getSuitCrit(level)
		local number = critical
		--print("critical = ",number)
		if number <= criticalAmount then
			damage = math.round(damage * 1.5)
			crit = true
		end
	end
	return damage,crit
end

local _ray_ignore_instances={
	workspace:WaitForChild("Buildings"),
	workspace:WaitForChild("water"),
	workspace:WaitForChild("Projectiles"),
	workspace:WaitForChild("Impacts"),
	workspace:WaitForChild("TripWebs"),
	workspace:WaitForChild("Webs"),
	workspace:WaitForChild("water"),
	workspace:WaitForChild("Bullets"),
	workspace:WaitForChild("SpiderDroneBullets"),
	workspace:WaitForChild("Drops")
}

local function ray(origin,direction,ignoreList) -- main ray function
	--print("ignore2 = ",ignore2)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = ignoreList
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local function ray2(origin,direction,whitelist) -- main ray function
	--print("ignore2 = ",ignore2)
	local raycastParams = RaycastParams.new()
	--raycastParams.CollisionGroup=
	raycastParams.FilterDescendantsInstances = whitelist
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

--[[
local beamTemplate = Instance.new("Part") -- good practice to avoid repetitive instancing
beamTemplate.BrickColor = BrickColor.new("Daisy orange")
beamTemplate.Material = "Neon"
beamTemplate.Transparency = 0.45
beamTemplate.Anchored = true
beamTemplate.CanTouch = false
beamTemplate.CanQuery = false
beamTemplate.CanCollide = false

local function showRay(origin, hitPos)
	local distance = (origin - hitPos).Magnitude
	local beam = beamTemplate:Clone()
	beam.Size = Vector3.new(0.025, 0.025, distance);
	beam.CFrame = CFrame.new(origin, hitPos) * CFrame.new(0, 0, -distance/2);
	beam.Parent = workspace; -- you want these to, uh, get ignored, yeah?
	game:GetService("Debris"):AddItem(beam, 1)
end
]]

local function getVillainsIgnoreArray() -- so projectiles can ignore the stuff we don't want to detect in villains
	local villain=workspace:WaitForChild("Villains"):FindFirstChildOfClass("Model")
	if not villain then return {} end
	local t={}
	for _,part in villain:GetChildren() do 
		if part:IsA("BasePart") and part.Name~="CollisionPart" then
			t[#t+1]=part
		end
	end
	return t
end

local function projectileWeb(anim,category,tag)

	local x,y = 0,0
	if category == "Shotgun Webs" then
		x = rngs["Shotgun Webs"].spreadRng:NextNumber(-10,10)	
		y = rngs["Shotgun Webs"].spreadRng:NextNumber(-10,10)
		--print(x)
		--print(y)
	end

	local character = player.Character
	if not character or not character.PrimaryPart then return end

	local humanoid = character:WaitForChild("Humanoid")
	local origin
	local target = (camera.CFrame * CFrame.new(0,0,-250)).Position

	if anim.Name:match("Left") then
		origin = character:WaitForChild("LeftHand"):WaitForChild("LeftGripAttachment").WorldPosition
	elseif anim.Name:match("Right") then
		origin = character:WaitForChild("RightHand"):WaitForChild("RightGripAttachment").WorldPosition
	end	

	stopAllOtherTracks(humanoid)

	local shootAnim = humanoid:LoadAnimation(anim)
	shootAnim:Play(0.100000001,1,6)
	_G.playAbilitySound(character,"projectile")

	local aheadOfCam = camera.CFrame * CFrame.new(Vector3.new(0,0,-3))
	--local ignore = player.Character
	--local ignore2 = workspace:WaitForChild("SpiderDrones"):FindFirstChild(player.Name)
	--local ignore3 = player.Character:FindFirstChild("SpiderLegs")
	
	local whitelist={
		workspace:WaitForChild("BuildingBounds"),
		--workspace:WaitForChild("Villains"),
		workspace:WaitForChild("Thugs")
	}
	
	for _,villain in workspace:WaitForChild("Villains"):GetChildren() do 
		local model=villain:WaitForChild("isMesh").Value and villain or villain:WaitForChild("Body")
		whitelist[#whitelist+1]=model
	end
	local characters=getCharacterModelsArray()
	for _,character in characters do 
		whitelist[#whitelist+1]=character
	end
	
	--for _,part in getVillainsIgnoreArray() do 
		--ignore_list[#ignore_list+1]=part
	--end 
	local raycastResult = ray2(aheadOfCam.Position,((target - aheadOfCam.Position).Unit * 250),whitelist)
	if raycastResult then
		--print(raycastResult.Instance.Name,raycastResult.Instance.Parent)
		target = raycastResult.Position
		--showRay(origin,target)
	end

	local dt = workspace:GetServerTimeNow()
	renderProjectile(origin,target,category,Vector3.new(x,y,0),player.Name,dt,tag) 
end

local renderedWebs = {}
local PlayerWebs={}

local function isSwingStartPlaying(humanoid)
	for _,track in (humanoid:GetPlayingAnimationTracks()) do
		if (track.Animation.Name:match("Start")) then
			if track.TimePosition/track.Length <= .86 then
				return track.TimePosition/track.Length
			else
				return nil
			end
		end
	end
	return nil
end

local tripWebs = temp:WaitForChild("tripWebs")
local TR_target = tripWebs:WaitForChild("target")
local TR_goalReached = tripWebs:WaitForChild("goalReached")
local TR_amount = tripWebs:WaitForChild("amount")

local trip_web_whitelist={
	workspace:WaitForChild("BuildingBounds"),
	workspace:WaitForChild("Grass"),
	workspace:WaitForChild("Trees"),
	workspace:WaitForChild("Trash"),
	workspace:WaitForChild("billboards"),
	workspace:WaitForChild("FireEscapes"),
	workspace:WaitForChild("StreetLamp"),
	workspace:WaitForChild("Vents"),
	workspace:WaitForChild("BarrelFire1"),
	--workspace:WaitForChild("Rock1"),
	workspace:WaitForChild("Sand"),
	workspace:WaitForChild("blocks"),
	--workspace:WaitForChild("Cars")	
	workspace:WaitForChild("Ground"),
	workspace:WaitForChild("Traintracks")
}

local function tripWebRay(origin,direction)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = trip_web_whitelist
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local offset = Vector3.new(-0.35, 0.19, -0.25)
local size = Vector3.new(4,4,1)
local function update3DWebs(folder,startPos,endPos,attach_start_CF,attach_finish_CF,p,plrName,transparency,dataTable)
	local distance = (startPos - endPos).Magnitude
	local numWebs = math.clamp(math.floor(distance/maxLength),1,math.huge)
	local webLength = distance/numWebs
	local points = getPoints(startPos, endPos, numWebs)

	local extras = 0

	if attach_start_CF ~= nil then
		local start = folder:FindFirstChild("start")
		if start then
			extras += 1
			--print("then")
			start.CFrame = attach_start_CF * CFrame.new(offset)
			start.Size = size
		else 
			extras += 1
			--print("else")
			local is2099=isPlayer2099(plrName)
			local attach_clone = rs:WaitForChild("AttachWeb"):Clone()
			attach_clone.Name = "start"
			attach_clone.Anchored = true
			attach_clone.Transparency = transparency ~= nil and transparency or 0
			attach_clone.Size = size
			attach_clone.CFrame = attach_start_CF * CFrame.new(offset)
			attach_clone.Color=is2099 and is2099.color or Color3.fromRGB(255,255,255)
			attach_clone.Material=is2099 and is2099.material or Enum.Material.Plastic
			attach_clone.Parent = folder 
		end
	else 
		local start = folder:FindFirstChild("start")
		if start then 
			extras += 1
		end
	end

	if attach_finish_CF ~= nil then
		local finish = folder:FindFirstChild("finish")
		if finish then 
			extras += 1
			finish.CFrame = attach_finish_CF * CFrame.new(offset)
			finish.Size = size
		else 
			extras += 1
			local is2099=isPlayer2099(plrName)
			local attach_clone = rs:WaitForChild("AttachWeb"):Clone()
			attach_clone.Name = "finish"
			attach_clone.Anchored = true
			attach_clone.Transparency = transparency ~= nil and transparency or 0
			attach_clone.Size = size
			attach_clone.CFrame = attach_finish_CF * CFrame.new(offset)
			attach_clone.Color=is2099 and is2099.color or Color3.fromRGB(255,255,255)
			attach_clone.Material=is2099 and is2099.material or Enum.Material.Plastic
			attach_clone.Parent = folder 
		end
	else
		local finish = folder:FindFirstChild("finish")
		if finish then
			extras += 1
		end
	end

--[[
	local hitbox = folder:FindFirstChild("hitbox")
	if hitbox then 
		extras += 1
		local webLength = (startPos - endPos).Magnitude
		hitbox.Size = Vector3.new(0.75,0.75,webLength*p)
		hitbox.CFrame = CFrame.new(startPos:Lerp(endPos,p/2),endPos)
	else 
		if plrName ~= nil and p == 1 then
			extras += 1
			local hitbox = Instance.new("Part")
			hitbox.Anchored = true
			hitbox.CanCollide = plrName == player.Name and true or false
			hitbox.Name = "hitbox"
			hitbox.Transparency = 1 
			local webLength = (startPos - endPos).Magnitude
			hitbox.Size = Vector3.new(0.35,0.35,webLength*p)
			hitbox.CFrame = CFrame.new(startPos:Lerp(endPos,p/2),endPos)
			hitbox.Parent = folder			
		end
	end
]]

	local children = #folder:GetChildren()

	local function removeUnwantedChildren()
		for i,v in (folder:GetChildren()) do 
			if v.Name ~= "start" and v.Name ~= "finish" and v.Name ~= "hitbox" then 
				v:Destroy()
			end
		end
	end

	if (children - extras) ~= numWebs then -- isn't the same, clear children and reload the webs
		removeUnwantedChildren()
		for i = 1,numWebs do
			local is2099=isPlayer2099(plrName)
			local webClone = rs:WaitForChild("SlingWeb"):Clone()
			webClone.Name = i
			local beforePos,afterPos = points[i].Position,points[i+1].Position
			webClone.CFrame = CFrame.new(beforePos:Lerp(afterPos,.5),afterPos)
			local orientation = webClone.Orientation
			webClone.Orientation = Vector3.new(orientation.X,orientation.Y,0) -- make sure z doesn't change
			webClone.Size = Vector3.new(0.6,0.6,webLength)
			webClone.Color=is2099 and is2099.color or Color3.fromRGB(255,255,255)
			webClone.Material=is2099 and is2099.material or Enum.Material.Plastic
			webClone.Parent = folder
		end
	else 
		for i = 1,children do 
			local web = folder:FindFirstChild(tostring(i))
			if web then
				web.Size = Vector3.new(0.6,0.6,webLength)
				local beforePos, afterPos = points[i].Position,points[i+1].Position
				--(beforePos+afterPos)/2
				web.CFrame = CFrame.new(beforePos:Lerp(afterPos,.5),afterPos)
				local orientation = web.Orientation
				web.Orientation = Vector3.new(orientation.X,orientation.Y,0) -- make sure z doesn't change
			end					
		end		
	end	

	local primary = folder:FindFirstChild("1")
	local iteration = primary.iteration
	if dataTable then
		if tick() - dataTable.lastTick >= 1/60 then
			iteration.Value += 1
			dataTable.lastTick = tick()
		end
	else 
		iteration.Value += 1
	end

	if primary then
		local bones = {
			[1] = primary.Bone1,
			[2] = primary.Bone2,
			[3] = primary.Bone3,
			[4] = primary.Bone4,
			[5] = primary["Bone.5"],
			[6] = primary.Bone6,
			[7] = primary.Bone7
		}

		local function extendBones(size)
			local startCF = primary.CFrame * CFrame.new(0,-size.Y*.75,-size.Z/2)
			local endCF = primary.CFrame * CFrame.new(0,-size.Y*.75,size.Z/2)

			for i = 1,#bones do 
				local boneP = (i-1)/(#bones-1)
				local bone = bones[i]
				local canManipulate = i~=1 and i~=#bones
				local cf = startCF:Lerp(endCF,boneP)
				local pos = startCF.Position:Lerp(endCF.Position,boneP)
				if canManipulate then
					local bool = i%2==0
					local offset = bool and .5 or -.5
					local rotation = bool and 45 or -45
					local cf2 = (cf * CFrame.Angles(0,0,math.rad(rotation*iteration.Value))) * CFrame.new((offset*math.clamp(p*1.5,0,1))-offset,0,0) 
					bone.WorldPosition = cf2.Position
				else 
					bone.WorldPosition = pos
				end												
			end
		end
		extendBones(primary.Size)		
	end
end

local function getTripWebFolder(parentFolder,action,folderName)
	if folderName ~= nil then
		local folder = parentFolder:FindFirstChild(folderName)
		if folder then
			return folder
		end
		return nil
	end
	local array = parentFolder:GetChildren()
	if #array > 0 then
		if action == "first" then
			return array[1]
		elseif action == "last" then
			return array[#array]
		else 
			return nil
		end
	end
	return nil
end

local function gradualWebRemove(folder)
	local start = tick()
	-- make the hitbox the primary part and use :SetPrimaryPartCFrame()
	while true do
		if tick() - start > 1 then break end
		for i,v in (folder:GetChildren()) do 
			if v:IsA("BasePart") then
				v.Position += Vector3.new(0,-.025,0)
				if v.Transparency < 1 then
					v.Transparency = (tick() - start)/1
				end
			end
		end
		clock:GetPropertyChangedSignal("Value"):Wait()
	end
	
	folder:Destroy()
end

local function removeTripWebAndReSort(plrName,action,folderName)
	local parentFolder = workspace:WaitForChild("TripWebs"):FindFirstChild(plrName)
	if not parentFolder then return end 

	if action == "all" then -- only for when player leaves
		parentFolder:ClearAllChildren()
		parentFolder:Destroy()
		return
	end

	local folder = getTripWebFolder(parentFolder,action,folderName)
	if not folder then --[[print("couldn't find ",folderName)]] return end
	local plr = game.Players:FindFirstChild(plrName)

	if plr and plr == player then  -- this is your client
		if action == "last" then
			TR_goalReached.Value = false 
			TR_target.Value = Vector3.new(0,0,0)	
		end
		if TR_amount.Value > 0 then
			TR_amount.Value -= 1
			actionRemote:FireServer( 
				"Traps",
				"Trip Web",
				"reset",
				folder.Name
			)
		end	
	end

	folder:Destroy()

end

local function halfwayTripWebRemove(plrName,action,index,folderName)
	table.remove(renderedWebs,index) -- remove this index from the loop
	removeTripWebAndReSort(plrName,action,folderName)
end

local function removeWeb3D(t,folder,index)
	table.remove(t,index) -- remove this index if the player isn't webbing anymore
	local f = coroutine.wrap(gradualWebRemove)
	f(folder)
end

local function Web_Eligibility(value,plr)
	--local plr = game.Players:FindFirstChild(value.plrName)
	if not plr then return false end
	if not plr.Character or not plr.Character.PrimaryPart then return false end
	return true
end

local function runningLoopForRenderingWebs()
	for index,value in (renderedWebs) do
		local plr = game.Players:FindFirstChild(value.plrName)
		if not Web_Eligibility(value,plr) then
			if value.category == "travel" then
				removeWeb3D(renderedWebs,value.folder,index)
			elseif value.category == "trip" then
				halfwayTripWebRemove(value.plrName,"all",index)
			end
			continue
		end
		local humanoid=plr.Character:WaitForChild("Humanoid")
		local isAlive=humanoid.Health>0
		if not isAlive and plr==player then
			if value.category == "trip" then -- own player's travel web wouldn't be here
				halfwayTripWebRemove(value.plrName,"last",index,value.folder.Name)
			end
			continue
		end
		if value.category == "travel" then
			if not value.leftGrip or not value.rightGrip then
				continue
			end
			local leaderstats = plr.leaderstats
			local playerIsWebbing = leaderstats.temp.isWebbing.Value
			if not playerIsWebbing or not value.humanoid or not value.humanoid:IsDescendantOf(workspace) then
				removeWeb3D(renderedWebs,value.folder,index)
				continue
			end
			local swingingPercentage = isSwingStartPlaying(value.humanoid)
			if (swingingPercentage) then
				value.hdp = swingingPercentage/8
			else
				value.hdp = 0.125
			end

			local startPos = value.leftGrip.WorldPosition:Lerp((value.leftGrip.WorldPosition + value.rightGrip.WorldPosition) / 2,0.125)

			local distance_percentage = (startPos - value.targetCF.Position).Magnitude / 200
			local p = (workspace:GetServerTimeNow() - value.timer) / distance_percentage
			p = math.clamp(p,0,1)
			local endPos = startPos:Lerp(value.targetCF.Position,p)

			local attachCF = CFrame.new(startPos,endPos) * CFrame.new(0,0,-(startPos - endPos).Magnitude)
			if p == 1 then
				attachCF = value.targetCF
			end

			update3DWebs(value.folder,startPos,endPos,attachCF,nil,p,value.plrName,1,value)
		elseif value.category == "trip" then --- update positions of the trip web to the player's hand
			if value.action == "halfway" then
				if not value.grip then continue end
				if plr == player then -- this is your client
					if value.targetCF.Position ~= TR_target.Value then -- it's changed, either 0,0,0 or another target was created
						table.remove(renderedWebs,index) -- remove this index from the loop
						continue
						--print("break loop for: ",value.folder.Name)
										--[[
										if TR_target.Value == Vector3.new(0,0,0) then
											halfwayTripWebRemove(plr.Name,"last",index,value.folder.Name)
										end
										]]
						-- don't remove the folder from workspace, use that for the finalize function
					end
				else -- this is other clients
					local tripWebsFolder = plr.leaderstats.temp.tripWebs
					local serverTarget = tripWebsFolder.serverTarget
					if value.targetCF.Position ~= serverTarget.Value or not value.grip then -- it's changed, either 0,0,0 or another target was created
						table.remove(renderedWebs,index) -- remove this index from the loop
						--print("break loop for: ",value.folder.Name)
						-- don't remove the folder from workspace, use that for the finalize function
					end
				end
				-- the attach webs normal cannot be focused on the target normal
				-- it must be facing the direction it's travelling, then when it reaches the goal it changes the normal to the target normal

				local startPos = value.grip.WorldPosition
				local distance_percentage = (startPos - value.targetCF.Position).Magnitude / 200
				local p = (workspace:GetServerTimeNow() - value.timer) / distance_percentage
				p = math.clamp(p,0,1)
				local progressPos = startPos:Lerp(value.targetCF.Position,p)
				local attachCF
				if p == 1 then
					if plr == player then -- this is your player
						TR_goalReached.Value = true -- you set this client's value
					end	
					attachCF = value.targetCF
				else
					attachCF = CFrame.new(startPos:Lerp(value.targetCF.Position,p),value.targetCF.Position) * CFrame.new(0,0,0.5)
				end
				update3DWebs(value.folder,value.grip.WorldPosition,progressPos,attachCF,nil,p,value.plrName)
				if plr == player then
					if (value.grip.WorldPosition - progressPos).Magnitude > 200 then
						halfwayTripWebRemove(value.plrName,"last",index,value.folder.Name)
					end									
				end
			end
		end
	end
end

--local runWebLoop = coroutine.wrap(runningLoopForRenderingWebs)
--runWebLoop()

local function finalizeTripWeb(plrName,origin,lastOrigin,targetCF,timer,tag) -- halfway trip web will naturally get removed by the loop
	-- run the percentage progress distance thingy
	-- have the attach web face the target at all times until target has been reached or 200 studs have been realized
	-- keep the attach web where it is

	local data = {
		lastTick = tick()
	}

	local parentFolder = workspace:WaitForChild("TripWebs"):FindFirstChild(plrName)
	if parentFolder then
		local folder = parentFolder:FindFirstChild(tag)
		if folder then
			for index,value in (renderedWebs) do 
				if value.category == "trip" and value.folder.Name == tag then 
					table.remove(renderedWebs,index) -- remove this index from the loop
				end
			end

			while true do
				local distance_percentage = (origin - targetCF.Position).Magnitude / 200
				local p = (workspace:GetServerTimeNow() - timer) / distance_percentage
				p = math.clamp(p,0,1)
				local progressPos = origin:Lerp(targetCF.Position,p)
				local attachCF = CFrame.new(origin:Lerp(targetCF.Position,p),targetCF.Position) * CFrame.new(0,0,0.5)
				update3DWebs(folder,lastOrigin,progressPos,nil,attachCF,p,plrName,0,data)

				if plrName == player.Name then -- only do this on your client
					if (lastOrigin - progressPos).Magnitude > 200 then 
						removeTripWebAndReSort(plrName,"last",folder.Name)
						break
					end					
				end

				if p == 1 then 

					local distance = (lastOrigin - progressPos).Magnitude + 1
					local direction = (progressPos - lastOrigin).Unit * distance
					local result = tripWebRay(lastOrigin, direction)
					if result then -- this prevents going thru walls
						local normalCF = CFrame.new(result.Position, result.Position - result.Normal) * CFrame.new(0,0,0.5)
						update3DWebs(folder,lastOrigin,normalCF.Position,nil,normalCF,1,plrName,0,data)
						break
					end

					attachCF = targetCF
					update3DWebs(folder,lastOrigin,attachCF.Position,nil,attachCF,1,plrName,0,data)
					break 
				end
				runService.RenderStepped:Wait()
			end

		end
	end
end

local function render3DWeb(...)
	
	local function addChildFolder(parentFolder,tag)
		local children = parentFolder:GetChildren()
		local childFolder = Instance.new("Model")
		childFolder.Name = tag
		--print(tag)
		childFolder.Parent = parentFolder
		return childFolder
	end

	local childFolder
	local function addParentFolder(parent,plrName,tag)
		local old_folder = parent:FindFirstChild(plrName)
		if old_folder then
			childFolder = addChildFolder(old_folder,tag)
		else 
			local parentFolder = Instance.new("Model")
			parentFolder.Name = plrName
			parentFolder.Parent = parent
			childFolder = addChildFolder(parentFolder,tag)
		end
	end

	local args = {...}
	if args[1] == "finalize" then
		local action = args[1]
		local plrName = args[2]
		local origin = args[3]
		local lastOrigin = args[4]
		local targetCF = args[5]
		local timer = args[6]
		local tag = args[7]

		local f = coroutine.wrap(finalizeTripWeb)
		f(plrName,origin,lastOrigin,targetCF,timer,tag)
		return
	elseif args[1] == "halfway" then
		local plrName = args[2]
		local grip = args[3]
		local targetCF = args[4]
		local timer = args[5]
		local tag = args[6]

		addParentFolder(workspace:WaitForChild("TripWebs"),plrName,tag)

		renderedWebs[#renderedWebs+1] = {
			plrName = plrName,
			category = "trip",
			action = "halfway",
			grip = grip,
			folder = childFolder,
			targetCF = targetCF,
			timer = timer,
			lastTick = tick()
		}
	elseif args[1] == "travel" then
		local plrName = args[2]
		local humanoid = args[3]
		local targetCF = args[4]
		local leftGrip = args[5]
		local rightGrip = args[6]
		local timer = args[7]
		--local tag=args[9]
		if plrName and humanoid and targetCF and leftGrip and rightGrip and timer then
			local tag = game:GetService("HttpService"):GenerateGUID(false)
			
			addParentFolder(workspace:WaitForChild("Webs"),plrName,tag)
			
			local t=player.Name==plrName and PlayerWebs or renderedWebs
			t[#t+1] = {
				plrName = plrName,
				category = "travel",
				humanoid = humanoid,
				leftGrip = leftGrip,
				rightGrip = rightGrip,
				targetCF = targetCF,
				folder = childFolder,
				timer = timer,
				hdp = .5,
				lastTick = tick(),
			}	
			--print("total=",#t)
		end
	end
end

--local cam = workspace.camPart
--local center = workspace.Center

--local normal = (cam.Position - center.Position).Unit
--cam.CFrame = CFrame.new(cam.Position, cam.Position-normal)

local function tripWeb(max,current)
	local character = player.Character
	if not character or not character.PrimaryPart then return end

	local rightGrip = character:WaitForChild("RightHand"):WaitForChild("RightGripAttachment")
	local anim = combatAnims:WaitForChild("shoot"):WaitForChild("tripWeb"):WaitForChild("shoot")

	local attachWeb = rs:WaitForChild("AttachWeb")

	local humanoid = character:WaitForChild("Humanoid")
	local targetCF = camera.CFrame * CFrame.new(0,0,-250)

	stopAllOtherTracks(humanoid)

	local shootAnim = humanoid:LoadAnimation(anim)
	shootAnim:Play(0.100000001,1,6)

	local aheadOfCam = camera.CFrame * CFrame.new(Vector3.new(0,0,-3))
	local raycastResult = tripWebRay(aheadOfCam.Position,(targetCF.Position - aheadOfCam.Position).Unit * 250)
	if raycastResult then
		local normalCF = CFrame.new(raycastResult.Position, raycastResult.Position - raycastResult.Normal) * CFrame.new(0,0,.5)
		targetCF = normalCF
		--target = raycastResult.Position
	end

	local function startNewTripWeb()
		TR_target.Value = targetCF.Position
		TR_goalReached.Value = false
		TR_amount.Value += 1
		local tag = game:GetService("HttpService"):GenerateGUID(false)
		local timer = workspace:GetServerTimeNow()
		actionRemote:FireServer(
			"Traps",
			"Trip Web",
			"halfway",
			rightGrip,
			targetCF, -- target normal will be found after you hit something
			timer,
			tag
		)
		render3DWeb("halfway",player.Name,rightGrip,targetCF,timer,tag)
	end

	local function finalize()
		local parentFolder = workspace:WaitForChild("TripWebs"):FindFirstChild(player.Name)
		if parentFolder then
			local array = parentFolder:GetChildren()
			if #array > 0 then
				local folder = array[#array]
				local origin = rightGrip.WorldPosition
				local lastOrigin = TR_target.Value
				local timer = workspace:GetServerTimeNow()
				local distance = (targetCF.Position - origin).Magnitude + 1
				local direction = (targetCF.Position - lastOrigin).Unit * distance
				local result = tripWebRay(lastOrigin, direction)
				local normalCF = targetCF
				if result then -- this prevents going thru walls
					normalCF = CFrame.new(result.Position, result.Position - result.Normal) * CFrame.new(0,0,0.5)
				end
				actionRemote:FireServer(
					"Traps",
					"Trip Web",
					"finalize",
					origin,
					lastOrigin,
					targetCF,
					timer,
					folder.Name,
					normalCF
				)
				TR_target.Value = targetCF.Position -- reset the value
				render3DWeb("finalize",player.Name,origin,lastOrigin,targetCF,timer,folder.Name)
				TR_target.Value = Vector3.new(0,0,0)
			end
		end
	end

	if current < max then
		if TR_target.Value ~= Vector3.new(0,0,0) then -- you're working on a trip web
			if TR_goalReached.Value then
				finalize()
				return
			end
		else
			startNewTripWeb()
			return
		end
	elseif current == max then
		if TR_target.Value ~= Vector3.new(0,0,0) then -- you're working on a trip web
			if TR_goalReached.Value then
				finalize()
				return
			end
		else 
			removeTripWebAndReSort(player.Name,"first") -- this will remove the first trip web you set
			startNewTripWeb()			
		end
		return
	end
end

local function setStatesEnabled(humanoid,bool,ignore)
	local stateTypes, secondArg = Enum.HumanoidStateType:GetEnumItems()
	while true do
		local key, value = next(stateTypes, secondArg)
		if not (key) then
			break
		end
		secondArg = key
		if (value ~= Enum.HumanoidStateType.None) and (value ~= Enum.HumanoidStateType.Dead) and (value ~= ignore) then
			humanoid:SetStateEnabled(value, bool)
		end	
	end
end

local function web_ray(origin,direction)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {workspace:WaitForChild("BuildingBounds")}
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local function get_swing_animations(humanoid,leftGrip,rightGrip)
	local movementAnims=animsFolder:WaitForChild("movement")
	local last_swing=humanoid:GetAttribute("LastSwing")
	local animations={
		{ -- classic left
			movementAnims:WaitForChild("Classic_Start"),
			movementAnims:WaitForChild("Classic_Hold"),
			movementAnims:WaitForChild("End_Left"),
			"Left",
			1
		},
		{ -- leap right 
			movementAnims:WaitForChild("Leap_Start"),
			movementAnims:WaitForChild("Leap_Hold"),
			movementAnims:WaitForChild("End_Right"),
			"Right",
			1.25
		},
		{ -- pull left 
			movementAnims:WaitForChild("Pull_Start"),
			movementAnims:WaitForChild("Pull_Hold"),
			movementAnims:WaitForChild("End_Left"),
			"Left",
			.75
		},
		{ -- twirl right
			movementAnims:WaitForChild("Twirl_Start"),
			movementAnims:WaitForChild("Twirl_Hold"),
			movementAnims:WaitForChild("End_Right"),
			"Right",
			1.25
		},
	}
	if not last_swing then
		last_swing=1--math.random(2,#animations)
	else
		last_swing+=1
	end
	if last_swing>#animations then
		last_swing=1
	end
	humanoid:SetAttribute("LastSwing",last_swing)
	--table.remove(animations,last_swing)
	--local random=math.random(1,#animations)
	local set=animations[last_swing]
	local grip=set[4]=="Left" and leftGrip or rightGrip
	local nonGrip=set[4]=="Left" and rightGrip or leftGrip
	return humanoid:LoadAnimation(set[1]),humanoid:LoadAnimation(set[2]),humanoid:LoadAnimation(set[3]),set[5],grip,nonGrip -- swing,hold
end

local function swingWeb()
	local character = player.Character
	if not character or not character.PrimaryPart then return end
	if (isWebbing.Value) then return end
	isWebbing.Value = true
	
	local wasSprintingBefore=false
	if isSprinting.Value then
		wasSprintingBefore=true
		isSprinting.Value=false
		_G.sprinting=false
		character:SetAttribute("Moving",false)
	end
	
	local humanoid = character:WaitForChild("Humanoid")
	
	setStatesEnabled(humanoid,false,Enum.HumanoidStateType.Physics)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	local freefallPlaying = stopAllOtherTracks(humanoid,"freefall","Swing_Flip2")
	
	local leftGripAttachment = character:WaitForChild("LeftHand"):WaitForChild("LeftGripAttachment")
	local rightGripAttachment = character:WaitForChild("RightHand"):WaitForChild("RightGripAttachment")
	
	--local swingStartAnim = humanoid:LoadAnimation(movementAnims:WaitForChild("Swing_Start2"))
	--local swingHoldAnim = humanoid:LoadAnimation(movementAnims:WaitForChild("Swing_Hold2"))
	local swingStartAnim,swingHoldAnim,swingEndAnim,anim_speed,grip,nongrip=get_swing_animations(humanoid,leftGripAttachment,rightGripAttachment)
	--local swingEndAnim = humanoid:LoadAnimation(movementAnims:WaitForChild("Swing_End2"))
	local swingFlipAnim = humanoid:LoadAnimation(movementAnims:WaitForChild("Swing_Flip2"))
	local swingTwirlAnim = humanoid:LoadAnimation(movementAnims:WaitForChild("Swing_Twirl"))
	local airwalkAnim = humanoid:LoadAnimation(movementAnims:WaitForChild("Airwalk"))
	--local swingTwirlAnim = humanoid:LoadAnimation(movementAnims:WaitForChild("Swing_Twirl"))
	--local swingDoubleFlipAnim = humanoid:LoadAnimation(movementAnims:WaitForChild("Swing_DoubleFlip"))
	
	local transitionSpeed = .2
	if freefallPlaying then
		local length = freefallPlaying.Length
		local timePosition = freefallPlaying.TimePosition
		local p = timePosition/length 
		transitionSpeed = math.clamp(1-p,.2,.5)
	end
	
	swingStartAnim:Play(.2,1,anim_speed)
	task.spawn(function()
		if swingStartAnim then
			swingStartAnim:GetMarkerReachedSignal("End"):Wait()
			local hold_speed=swingHoldAnim.Animation.Name=="Twirl_Hold" and 1.25 or 1
			swingHoldAnim:Play(.1,1,hold_speed)
			--print("freefallPlaying = ",freefallPlaying)
		end
	end)
	
	local swing_level = abilities:WaitForChild("Travel"):WaitForChild("Swing Web"):WaitForChild("Level").Value
	local misc = items.Travel["Swing Web"].misc[1]
	local baseSpeed = _math.getStat(swing_level,misc.base,misc.multiplier)
	local webLength = 200
	
	-- play animation
	local startPos 
	
	local x,y,z = character.PrimaryPart.CFrame:ToOrientation()
	local targetCF = CFrame.new(character.PrimaryPart.Position,character.PrimaryPart.Position + Vector3.new(0,webLength,0)) * CFrame.new(0,0,-webLength)
	
	local result = castRay(character.PrimaryPart.Position,targetCF.Position,webLength)
	if (result) then
		local distance=(character.PrimaryPart.Position-result.Position).Magnitude
		--webLength=distance
		targetCF = CFrame.new(character.PrimaryPart.Position,result.Position) * CFrame.new(0,0,-webLength)
	end	
	
	--temp:WaitForChild("swingWebPivot").Value = CFrame.new(endPos) * CFrame.fromOrientation(0,y,0)
	
	local centerDistance = webLength
	local centerCF = camera.CFrame * CFrame.new(0,0,-centerDistance)
	local aheadOfCam = camera.CFrame * CFrame.new(Vector3.new(0,0,-3))
	local raycastResult = web_ray(aheadOfCam.Position,((centerCF.Position - aheadOfCam.Position).Unit * centerDistance))
	if raycastResult then
		centerDistance = (raycastResult.Position - camera.CFrame.Position).Magnitude
		local lookAtCamCF = CFrame.new(raycastResult.Position,camera.CFrame.Position)
		local turnAroundCF = CFrame.new(lookAtCamCF.Position,(lookAtCamCF*CFrame.new(Vector3.new(0,0,1)).Position))
		centerCF = turnAroundCF
	end
	
	temp:WaitForChild("swingWebPivot").Value = CFrame.new(targetCF.Position,centerCF.Position)
	
	actionRemote:FireServer(
		"Travel",
		"New",
		"Swing Web",
		humanoid,
		targetCF,
		grip,
		nongrip,
		--leftGripAttachment,
		--rightGripAttachment,
		workspace:GetServerTimeNow()
	)
	
	--local tag=game:GetService("HttpService"):GenerateGUID(false)
	render3DWeb("travel",player.Name,humanoid,targetCF,grip,nongrip,workspace:GetServerTimeNow(),1)
	--print("after render:",#PlayerWebs)
	
	local handDistancePercentage = 0
	local startTick = tick()
	local forceTime = 1
	local p = 0
	
	local fallspeed = math.clamp(math.abs(character.PrimaryPart.Velocity.Y),0,baseSpeed/2)
	local start = tick()
	--humanoid.HipHeight = 0
	
	--[[
		local function detect_building(part)
		local building_bounds=workspace:WaitForChild("BuildingBounds")
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {building_bounds}
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.IgnoreWater = true
		local origin=part.Position
		local target=(part.CFrame*CFrame.new(0,0,-10)).Position
		local direction=(target-origin).Unit*3
		local result=workspace:Raycast(origin,direction,raycastParams)
		return result
		--print(result and result.Instance or nil)
	end
	]]
	
	while ActionButtonDown.Value and player.Character and player.Character.Humanoid.Health > 0 and not isClimbing.Value and not isSwimming.Value do
		local handDistancePercentage = isSwingStartPlaying(humanoid)
		handDistancePercentage = handDistancePercentage ~= nil and handDistancePercentage/2 or 1
		
		local hrp=character.PrimaryPart
		
		p = math.clamp(math.abs((tick() - startTick) / (forceTime)),0,1)
		local speed = (baseSpeed + fallspeed) * p
		local vForce = (hrp.CFrame.LookVector) * speed
		local goalVelocity = ClampMagnitude(vForce,speed)
		hrp.Velocity = hrp.Velocity:Lerp(goalVelocity,p) 
		
		local xDist = ((hrp.Position * Vector3.new(1,0,1)) - (targetCF.Position * Vector3.new(1,0,1))).Magnitude
		local yDist =  ((hrp.Position * Vector3.new(0,1,0)) - (targetCF.Position * Vector3.new(0,1,0))).Magnitude

		if (xDist >= (webLength - (webLength * .25))) or (yDist <= (webLength * .25)) then
			break
		end

		--[[
		local distance = (startPos - targetCF.Position).Magnitude
		if (castRay(startPos,targetCF.Position,distance)) then
			break
		end
		]]
		
		for index,value in PlayerWebs do
			local plr = game.Players:FindFirstChild(value.plrName)
			if not plr or not plr.Character or not plr.Character.PrimaryPart or not value.humanoid then
				--print("fault1")
				removeWeb3D(PlayerWebs,value.folder,index)
				continue
			end
			local isAlive=value.humanoid.Health>0
			if not isAlive then
				--print("fault2")
				removeWeb3D(PlayerWebs,value.folder,index)
				continue
			end
			local leaderstats = plr.leaderstats
			local playerIsWebbing = leaderstats.temp.isWebbing.Value
			if not playerIsWebbing then
				--print("fault3")
				removeWeb3D(PlayerWebs,value.folder,index)
				continue
			end
			local swingingPercentage = isSwingStartPlaying(value.humanoid)
			if (swingingPercentage) then
				value.hdp = swingingPercentage/8
			else
				value.hdp = 0.125
			end

			local startPos = value.leftGrip.WorldPosition:Lerp((value.leftGrip.WorldPosition + value.rightGrip.WorldPosition) / 2,0.125)

			local distance_percentage = (startPos - value.targetCF.Position).Magnitude / 200
			local p = (workspace:GetServerTimeNow() - value.timer) / distance_percentage
			p = math.clamp(p,0,1)
			local endPos = startPos:Lerp(value.targetCF.Position,p)

			local attachCF = CFrame.new(startPos,endPos) * CFrame.new(0,0,-(startPos - endPos).Magnitude)
			if p == 1 then
				attachCF = value.targetCF
			end

			update3DWebs(value.folder,startPos,endPos,attachCF,nil,p,player.Name,1,value)
		end	
		
		--[[
		local result=detect_building(hrp)
		if result then 
			_G.start_climb(result.Instance,hrp,humanoid)
			break
		end
		]]
		
		if cs:HasTag(character,"ragdolled") then print("break1") break end
		runService.RenderStepped:Wait()
	end
	
	--print("ActionButtonDown=",ActionButtonDown.Value)
	--humanoid.HipHeight = 2
	actionRemote:FireServer("Travel","Remove")
	
	for i=1,#PlayerWebs do 
		removeWeb3D(PlayerWebs,PlayerWebs[1].folder,1)
	end
	
	--[[
	when you swing, you activate, then release (which destroys)
	if you release then activate too fast, the new web gets removed as well!
	]]
	
	--print("after remove:",#PlayerWebs)
	
	--workspace.Gravity = 98.1
	local gettingUp = character:GetAttribute("GettingUp")
	if not isClimbing.Value and not gettingUp then
		--undoGhost()
	end
	
	local isDead = humanoid:GetState() == Enum.HumanoidStateType.Dead
	local isLanded = humanoid:GetState() == Enum.HumanoidStateType.Landed
	local isRunning = humanoid:GetState() == Enum.HumanoidStateType.Running
	
	if not isDead and not isLanded and not isRunning and not isSwimming.Value and not isClimbing.Value then
		stopAllOtherTracks(humanoid)
		if p >= 1 then
			local t={
				{swingFlipAnim,1},
				{swingTwirlAnim,1},
				{airwalkAnim,1.75}
			}
			local last_end_anim=humanoid:GetAttribute("LastEndAnim")
			if not last_end_anim then
				last_end_anim=1
			else 
				last_end_anim+=1
			end
			if last_end_anim>#t then
				last_end_anim=1
			end
			humanoid:SetAttribute("LastEndAnim",last_end_anim)
			local anim=t[last_end_anim][1]
			anim:Play(0,1,t[last_end_anim][2])
		else 
			swingEndAnim:Play(.1,1,1.5)	
		end
	end
	
	--local gettingUp = character:GetAttribute("GettingUp")
	if not isSwimming.Value and not isClimbing.Value and not cs:HasTag(character,"ragdolled") --[[and not gettingUp]] then
		setStatesEnabled(humanoid,true)
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		if wasSprintingBefore and humanoid.MoveDirection.Magnitude>0 --[[and _G.platform=="mobile"]] then
			character:SetAttribute("Moving",true)
			_G.sprinting=true
			isSprinting.Value=true
		end
	else 
		--print("gettingUp=",gettingUp)
		--print("was swimming, climbing or ragdolled")
	end
	
	isWebbing.Value = false
end

local function launchWeb()
	
	local n = 5
	local t = n/10
	
	local character = player.Character
	if not character or not character.PrimaryPart then return end
	if (isWebbing.Value) then return end
	isWebbing.Value = true
	isSprinting.Value=false
	_G.sprinting=false
	character:SetAttribute("Moving",false)
	
	for i=1,#PlayerWebs do
		removeWeb3D(PlayerWebs,PlayerWebs[1].folder,1)
	end	
	
	local humanoid = character:WaitForChild("Humanoid")
	
	temp:WaitForChild("launching").Value = true
	
	setStatesEnabled(humanoid,false,Enum.HumanoidStateType.Physics)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	local leftGripAttachment = character:WaitForChild("LeftHand"):WaitForChild("LeftGripAttachment")
	local rightGripAttachment = character:WaitForChild("RightHand"):WaitForChild("RightGripAttachment")
	
	local freefallPlaying = stopAllOtherTracks(humanoid,"freefall")
	
	local launchStartAnim = humanoid:LoadAnimation(movementAnims:WaitForChild("Launch_Start2"))
	local launchHoldAnim = humanoid:LoadAnimation(movementAnims:WaitForChild("Launch_Hold2"))
	
	local transitionSpeed = .25
	--[[
	if freefallPlaying then
		local length = freefallPlaying.Length
		local timePosition = freefallPlaying.TimePosition
		local p = timePosition/length 
		transitionSpeed = math.clamp(1-p,.2,.2)
	end]]
	
	launchStartAnim:Play(transitionSpeed,1,1)
	spawn(function()
		if launchStartAnim then
			launchStartAnim:GetMarkerReachedSignal("End"):Wait()
			launchHoldAnim:Play(.5,1,1)
			--print("freefallPlaying = ",freefallPlaying)
		end
	end)
	
	local launch_level = abilities:WaitForChild("Travel"):WaitForChild("Launch Webs"):WaitForChild("Level").Value
	local misc = items.Travel["Launch Webs"].misc[1]
	local baseSpeed = _math.getStat(launch_level,misc.base,misc.multiplier)
	
	local startCF = character.PrimaryPart.CFrame
	local root = character.PrimaryPart

	local centerDistance = 200
	local centerCF = camera.CFrame * CFrame.new(0,0,-centerDistance)
	local aheadOfCam = camera.CFrame * CFrame.new(Vector3.new(0,0,-3))
	
	local raycastResult = web_ray(aheadOfCam.Position,(centerCF.Position - aheadOfCam.Position).Unit * centerDistance)
	if raycastResult then
		centerDistance = (raycastResult.Position - camera.CFrame.Position).Magnitude
		local lookAtCamCF = CFrame.new(raycastResult.Position,camera.CFrame.Position)
		local turnAroundCF = CFrame.new(lookAtCamCF.Position,(lookAtCamCF*CFrame.new(Vector3.new(0,0,1)).Position))
		centerCF = turnAroundCF
	end

	--workspace.camPart.CFrame = centerCF

	local x,y,z = CFrame.new(startCF.Position,centerCF.Position):ToOrientation()
	temp:WaitForChild("launchRotation").Value = y

	local leftCF = centerCF * CFrame.new(-centerDistance/6,0,0)
	local ignoreList={character}
	for _,part in getVillainsIgnoreArray() do 
		ignoreList[#ignoreList+1]=part
	end
	local raycastResult = ray(aheadOfCam.Position,(leftCF.Position - aheadOfCam.Position).Unit * centerDistance*2,ignoreList)
	if raycastResult and (raycastResult.Position - leftGripAttachment.WorldPosition).Magnitude <= 200 then
		leftCF = CFrame.new(raycastResult.Position,raycastResult.Position - raycastResult.Normal) * CFrame.new(0,0,0.5)
	end

	local rightCF = centerCF * CFrame.new(centerDistance/6,0,0)
	local raycastResult = ray(aheadOfCam.Position,(rightCF.Position - aheadOfCam.Position).Unit * centerDistance*2,ignoreList)
	if raycastResult and (raycastResult.Position - rightGripAttachment.WorldPosition).Magnitude <= 200 then
		rightCF = CFrame.new(raycastResult.Position,raycastResult.Position - raycastResult.Normal) * CFrame.new(0,0,0.5)
	end

	--workspace.Center.CFrame = rightCF
	--workspace.Offset.CFrame = leftCF

	local t = workspace:GetServerTimeNow()

	actionRemote:FireServer(
		"Travel",
		"New",
		"Launch Webs",
		humanoid,
		leftCF,
		rightCF,
		leftGripAttachment,
		rightGripAttachment,
		t
	)

	for i = 1,2 do
		local attachment = i == 1 and leftGripAttachment or rightGripAttachment
		local targetCF = i == 1 and leftCF or rightCF 
		render3DWeb("travel",player.Name,humanoid,targetCF,attachment,attachment,t,1)
	end
	
	--print("before render:",#PlayerWebs)
	
	local yVelocity = character.PrimaryPart.Velocity * Vector3.new(0,1,0)
	local multiplier = camera.CFrame.LookVector.Y < 0 and math.abs(camera.CFrame.LookVector.Y) or 0
	yVelocity *= multiplier

	local yMultiplier = math.abs(camera.CFrame.LookVector.Y)

	local forceTime = 1
	local startTick = tick()

	local start = tick()

	while (tick() - startTick <= forceTime) and ActionButtonDown.Value and player.Character and player.Character.Humanoid.Health > 0 and not isClimbing.Value and selected.Value ~= 0 do
		local p = math.clamp(math.abs((tick() - startTick) / (forceTime - 0.5)),0,1)
		local speed = baseSpeed * p
		local vForce = ((centerCF.Position - startCF.Position).Unit * speed)
		local goalVelocity = ClampMagnitude(vForce,speed) + yVelocity
		character.PrimaryPart.Velocity = character.PrimaryPart.Velocity:Lerp(goalVelocity,p)

		local excludeY = Vector3.new(1,yMultiplier,1)
		local distanceFromTarget = ((character.PrimaryPart.Position * excludeY) - (centerCF.Position * excludeY)).Magnitude
		if distanceFromTarget < math.clamp(speed/10,3,math.huge) then
			break
		end
		
		for index,value in (PlayerWebs) do
			local plr = game.Players:FindFirstChild(value.plrName)
			if not plr or not plr.Character or not plr.Character.PrimaryPart or not value.humanoid then
				removeWeb3D(PlayerWebs,value.folder,index)
				continue
			end
			local isAlive=value.humanoid.Health>0
			if not isAlive then
				removeWeb3D(PlayerWebs,value.folder,index)
				continue
			end
			local leaderstats = plr.leaderstats
			local playerIsWebbing = leaderstats.temp.isWebbing.Value
			if not playerIsWebbing then
				removeWeb3D(PlayerWebs,value.folder,index)
				continue
			end
			local swingingPercentage = isSwingStartPlaying(value.humanoid)
			if (swingingPercentage) then
				value.hdp = swingingPercentage/8
			else
				value.hdp = 0.125
			end

			local startPos =  value.leftGrip.WorldPosition:Lerp((value.leftGrip.WorldPosition + value.rightGrip.WorldPosition) / 2,0.125)

			local distance_percentage = (startPos - value.targetCF.Position).Magnitude / 200
			local p = (workspace:GetServerTimeNow() - value.timer) / distance_percentage
			p = math.clamp(p,0,1)
			local endPos = startPos:Lerp(value.targetCF.Position,p)

			local attachCF = CFrame.new(startPos,endPos) * CFrame.new(0,0,-(startPos - endPos).Magnitude)
			if p == 1 then
				attachCF = value.targetCF
			end

			update3DWebs(value.folder,startPos,endPos,attachCF,nil,p,player.Name,1,value)
		end	
		
		if cs:HasTag(character,"ragdolled") then break end
		runService.RenderStepped:Wait()
	end

	actionRemote:FireServer("Travel","Remove")	
	
	--print("before render:",#PlayerWebs)
	
	stopAllOtherTracks(humanoid)

	--local gettingUp = character:GetAttribute("GettingUp")
	if not isSwimming.Value and not isClimbing.Value and not cs:HasTag(character,"ragdolled") --[[and not gettingUp]] then
		setStatesEnabled(humanoid,true)
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	else 
		--print("was swimming, climbing or ragdolled")
	end
	
	for i=1,#PlayerWebs do
		removeWeb3D(PlayerWebs,PlayerWebs[1].folder,1)
	end
	
	temp:WaitForChild("launchRotation").Value = 0
	temp:WaitForChild("launching").Value = false
	isWebbing.Value = false
	
end

local function getNPCs(position)
	local NPCs = {}
	local spiderDrones = workspace:WaitForChild("SpiderDrones"):GetChildren()
	for i,v in (spiderDrones) do 
		if not v.PrimaryPart then continue end
		if v.Name ~= player.Name then -- don't add your drone in the mix
			local isWithinRange = (v.PrimaryPart.Position - position).Magnitude <= 50
			if isWithinRange then
				NPCs[#NPCs+1] = v
			end
		end
	end
	local thugs = workspace:WaitForChild("Thugs"):GetChildren()
	for i,v in (thugs) do 
		if not v.PrimaryPart then continue end
		local properties = v.Properties
		local isWithinRange = (v.PrimaryPart.Position - position).Magnitude <= 50
		if isWithinRange then
			NPCs[#NPCs+1] = v
		end
	end
	local villains = workspace:WaitForChild("Villains"):GetChildren()
	for i,v in (villains) do 
		if not v.PrimaryPart then continue end
		local isWithinRange = (v.PrimaryPart.Position - position).Magnitude <= 50
		if isWithinRange then
			NPCs[#NPCs+1] = v
		end
	end
	return NPCs
end

local function explodeWebBomb(tag,timer,critical,ignorePlayer)
	local bomb = workspace:WaitForChild("Projectiles"):FindFirstChild(tag)
	if not bomb then return end
	while workspace:GetServerTimeNow() - timer < .25 do
		clock:GetPropertyChangedSignal("Value"):Wait()
	end
	bomb.Attachment.explode:Emit(20)
	bomb["Web Bomb"]:Play()
	--local listing = rs:WaitForChild("VerifiedWebBombs"):FindFirstChild(tag)
	game:GetService("Debris"):AddItem(bomb,3)
	
	local GroundWeb=rs:WaitForChild("GroundWeb"):Clone()
	GroundWeb.CFrame=bomb.CFrame*CFrame.new(0,-.1,0)
	GroundWeb.Parent=workspace
	ts:Create(
		GroundWeb,
		TweenInfo.new(
			.1,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		),
		{Size=Vector3.new(25,25,.1)}
	):Play()
	
	task.spawn(function()
		local start=tick()
		while true do 
			local elapsed=tick()-start
			local p=elapsed/1
			for _,image in GroundWeb.SurfaceGui:GetChildren() do 
				image.ImageTransparency=.25*p
			end
			if p>=4 then 
				GroundWeb:Destroy()
				break 
			end
			task.wait(1/30)
		end
	end)
	
	if ignorePlayer~=player then return end -- don't continue past this point if you weren't the thrower
	local level = abilities.Special["Web Bomb"].Level.Value
	local misc = items.Special["Web Bomb"].misc[1]
	local damage = _math.getStat(level,misc.base,misc.multiplier)
	local crit = critical
	--print("Web Bomb crit = ",crit)
	damage,crit = getNewDamageWithCritical(damage,crit)
	local function getAttackables()
		local attackables = {}
		local players = game.Players:GetPlayers()
		for _,plr in (players) do
			if plr ~= player then -- don't detect your player
				local character = plr.Character
				if not character or not character.PrimaryPart then continue end
				local isWithinRange = (character.PrimaryPart.Position - bomb.Position).Magnitude <= 50
				if isWithinRange then
					attackables[#attackables+1] = character
				end							
			end	
		end

		local NPCs = getNPCs(bomb.Position)
		for i,model in (NPCs) do 
			attackables[#attackables+1] = model
		end
		return attackables
	end

	local attackables = getAttackables()

	for _,attackable in (attackables) do  -- these are attackables within range
		local origin = bomb.Position
		if not attackable.PrimaryPart then continue end
		local target = attackable.PrimaryPart.Position
		local distance = (origin - target).Magnitude
		local direction = (target - origin).Unit * distance
		local result = tripWebRay(origin,direction)
		if not result then -- no obstructions in the way, can damage
			local isNPC = attackable:FindFirstChild("Properties")
			local isCharacter = game.Players:GetPlayerFromCharacter(attackable)
			local remaining = 0
			if isNPC then
				local properties = attackable.Properties
				local health = properties.Health
				local maxHealth = properties.MaxHealth
				remaining = health.Value - damage < 0 and health.Value or damage
				remaining = math.clamp(remaining,0,maxHealth.Value)
				--local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
				--health.Value = newHealth -- deal damage
			else 
				if isCharacter then
					local humanoid = attackable.Humanoid
					local health = humanoid.Health
					remaining = health - damage < 0 and health or damage
					remaining = math.clamp(remaining,0,humanoid.MaxHealth)
					--humanoid:TakeDamage(damage)
				end
			end
			local f = coroutine.wrap(hitMarker)
			f(attackable,remaining,crit,"Web Bomb","Special",origin)
		end
	end
	--print("since landed, web bomb took ",workspace:GetServerTimeNow() - timer," seconds to finish.")
end

local function gravityBombEffect(plrName,bomb,timer)
	local plr = game.Players:FindFirstChild(plrName)
	if not plr then return end

	local level = plr.leaderstats.abilities.Traps["Anti Gravity"].Level.Value
	local misc = items.Traps["Anti Gravity"].misc[1]
	local duration = 8
	local range = _math.getStat(level,misc.base,misc.multiplier)

	local f = coroutine.wrap(_G.camShake)
	local distance = (camera.CFrame.Position - bomb.Position).Magnitude / 2
	f(1.5,math.clamp(range - distance,0,math.huge)/(range/2))

	bomb.Attachment.warp.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, range/2),
		NumberSequenceKeypoint.new(1,0)
	}

	local max_brightness = 2.5
	local pause = 1/60
	local max_time = 1/pause

	local camera = workspace.CurrentCamera
	local pointLight = bomb:WaitForChild("PointLight")
	pointLight.Brightness = 0
	pointLight.Range = range

	local elapsed = workspace:GetServerTimeNow() - timer

	bomb.loop:Play()
	bomb.start:Play()

	local isPlayer = plrName == player.Name

	while (workspace:GetServerTimeNow() - timer) - elapsed < duration do
		local t = (workspace:GetServerTimeNow() - timer) - elapsed
		for _,particle in (bomb:GetDescendants()) do
			if (particle:IsA("ParticleEmitter")) then
				local t = (max_time/particle.Rate) * pause
				local amount = 0
				local particleTick = particle:WaitForChild("tick")
				local particleTickValue = tonumber(particle:WaitForChild("tick").Value)
				local elapsed = tick() - particleTickValue
				if elapsed > t then -- enough time has passed, you can emit now
					particleTick.Value = tick()
					amount = 1
				end
				particle:Emit(amount)
			end
		end
		local p = math.clamp(t/1,0,1)
		pointLight.Brightness = math.clamp(p * max_brightness,0,max_brightness)
		pointLight.Range = range * p
		bomb.zone.Size = Vector3.new(range,2,range) * p
		clock:GetPropertyChangedSignal("Value"):Wait()
	end
	bomb.loop:Stop()
	pointLight.Enabled = false
	bomb.zone.Transparency = 1
	if bomb then bomb:Destroy() end
	--print("since landed, gravity bomb took ",workspace:GetServerTimeNow() - timer," seconds to finish.")
end

local function explodeGravityBomb(plrName,tag,timer)
	-- needs to get the level and stuff to make the end effect
	local bomb = workspace:WaitForChild("Projectiles"):FindFirstChild(tag)
	if (bomb) then
		while workspace:GetServerTimeNow() - timer < .25 do
			clock:GetPropertyChangedSignal("Value"):Wait()
		end
		gravityBombEffect(plrName,bomb,timer)
	end
end

local function renderThrowable(_type,plrName,origin,target,dt,tag)
	local plr = game.Players:FindFirstChild(plrName)
	if not plr then return end

	local distance = 250
	local startCFrame = CFrame.new(origin,target)
	local endCFrame = startCFrame * CFrame.new(0,0,-distance)
	local drop = distance/2
	local allowedTime = (distance/80) - (workspace:GetServerTimeNow() - dt)
	local start = tick()

	local WebBombProjectile = nil
	local destroyTime = 0
	if _type == "web bomb" then
		WebBombProjectile = rs:WaitForChild("WebBombProjectile")
		destroyTime = 4
	elseif _type == "gravity bomb" then 
		WebBombProjectile = rs:WaitForChild("AntiGravityProjectile")
		destroyTime = 12
	elseif _type == "spider drone" then
		WebBombProjectile = rs:WaitForChild("SpiderDroneProjectile")
		destroyTime = .25
	end

	local throwable = WebBombProjectile:Clone()
	throwable.CFrame = startCFrame
	throwable.Name = tag
	throwable.Parent = workspace.Projectiles

	local iteration = 0
	local lastRayCF = startCFrame

	while true do 
		local _,errorMessage = pcall(function()
			iteration += 1
			local p = math.clamp((tick() - start) / allowedTime,0,1)
			local sine = math.sin((0.5 - p)*(math.pi * (250/1000)))
			local newEndCF = (endCFrame * CFrame.new(0,(sine*drop)/2,0))
			throwable.CFrame = CFrame.new(startCFrame:Lerp(newEndCF,p).Position,newEndCF.Position) --* CFrame.Angles(0,0,math.rad(-((p)*1000)))

			if (iteration % 2 == 0) then
				local realCurrentCF = throwable.CFrame * CFrame.new(0,0,-throwable.Size.Z/2)
				local currentDistanceFromOrigin = (realCurrentCF.Position - lastRayCF.Position).Magnitude

				local origin = lastRayCF.Position
				local target = realCurrentCF.Position
				local direction = (target - origin).Unit * currentDistanceFromOrigin
				local result = tripWebRay(origin,direction)

				if (result) then
					local cf = CFrame.new(result.Position, result.Position - result.Normal) * CFrame.new(0,0,throwable.Size.Z/2)
					local up=CFrame.new(cf.Position)
					local surface=CFrame.new(cf.Position,result.Position+result.Normal)
					throwable.CFrame = _type=="web bomb" and surface or up
					throwable.Anchored=true
					--throwable.weld.Part0 = throwable
					--throwable.weld.Part1 = result.Instance

					if plr == player then 
						if _type == "web bomb" then
							actionRemote:FireServer("Special","Web Bomb","Explode",tag,result.Position,workspace:GetServerTimeNow())
						elseif _type == "gravity bomb" then 
							actionRemote:FireServer("Traps","Anti Gravity","Explode",tag,result.Position,workspace:GetServerTimeNow())
						elseif _type == "spider drone" then 
							actionRemote:FireServer("Special","Spider Drone","Deploy",cf,tag)
						end
					end

					game:GetService("Debris"):AddItem(throwable,destroyTime)
					return "break"
				end
				lastRayCF = throwable.CFrame * CFrame.new(0,0,throwable.Size.Z/2)
			end

			if p == 1 then 
				throwable:Destroy()
				return "break"
			end
		end)
		if errorMessage == "break" then break end
		runService.RenderStepped:Wait()
	end
end

local function webBomb() -- this is for your client only
	local character = player.Character
	if not character or not character.PrimaryPart then return end 

	local throw = combatAnims:WaitForChild("bomb"):WaitForChild("Throw")
	local humanoid = character:WaitForChild("Humanoid")

	local throwAnim = humanoid:LoadAnimation(throw)
	throwAnim:Play(.1,1,4)

	throwAnim:GetMarkerReachedSignal("Release"):Wait()

	local rightGrip = character:WaitForChild("RightHand"):WaitForChild("RightGripAttachment")
	local target = (camera.CFrame * CFrame.new(0,0,-250)).Position

	local origin = rightGrip.WorldPosition
	local direction = (target - origin).Unit * 250
	local result = ray(origin,direction,{character})
	if result then
		target = result.Position
	end

	local tag = game:GetService("HttpService"):GenerateGUID(false)
	local timer = workspace:GetServerTimeNow()
	actionRemote:FireServer("Special","Web Bomb","New",tag,origin,target,timer)

	local render_Throwable = coroutine.wrap(renderThrowable)
	render_Throwable("web bomb",player.Name,origin,target,timer,tag)
end

local function antiGravityBomb()
	local character = player.Character
	if not character or not character.PrimaryPart then return end 

	local throw = combatAnims:WaitForChild("bomb"):WaitForChild("Throw")
	local humanoid = character:WaitForChild("Humanoid")

	local throwAnim = humanoid:LoadAnimation(throw)
	throwAnim:Play(.1,1,4)

	throwAnim:GetMarkerReachedSignal("Release"):Wait()

	local rightGrip = character:WaitForChild("RightHand"):WaitForChild("RightGripAttachment")
	local target = (camera.CFrame * CFrame.new(0,0,-250)).Position

	local origin = rightGrip.WorldPosition
	local direction = (target - origin).Unit * 250
	local result = ray(origin,direction,{character})
	if result then
		target = result.Position
	end

	local tag = game:GetService("HttpService"):GenerateGUID(false)
	local timer = workspace:GetServerTimeNow()
	actionRemote:FireServer("Traps","Anti Gravity","New",tag,origin,target,timer)

	local render_Throwable = coroutine.wrap(renderThrowable)
	render_Throwable("gravity bomb",player.Name,origin,target,timer,tag)
end

_G.tweenHealth = function(health,maxHealth,healthUI)
	healthUI.Enabled = health.Value < maxHealth.Value and true or false
	local bg = healthUI:WaitForChild("bg")
	local top = bg:WaitForChild("top")
	local white = bg:WaitForChild("white")

	local p = math.clamp(health.Value/maxHealth.Value,0,1)
	local function completed(didComplete)
		if didComplete then
			white:TweenSize(
				UDim2.new(p,0,1,0),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Linear,
				.15,
				true
			)						
		end
	end
	top:TweenSize(
		UDim2.new(p,0,1,0),
		Enum.EasingDirection.InOut,
		Enum.EasingStyle.Linear,
		.15,
		true,
		completed
	)
end

local function getSpiderDroneDamage(model)
	local crit = rngs["Spider Drone"].rng:NextNumber(0,100)
	local level = abilities:WaitForChild("Special"):WaitForChild("Spider Drone").Level.Value
	local misc = items.Special["Spider Drone"].misc[2]
	local damage = _math.getStat(level,misc.base,misc.multiplier)
	damage,crit = getNewDamageWithCritical(damage,crit)
	local f = coroutine.wrap(hitMarker)
	f(model,damage,crit,"Spider Drone","Special")
	return damage
end

local droneRange = 200
local droneAnimations = rs:WaitForChild("DroneAnimations")

local function Get_Drone_Villain_Goal(attacking)
	local isVillain=attacking:IsDescendantOf(workspace:WaitForChild("Villains"))
	local goal
	if isVillain then
		local isMesh=attacking:WaitForChild("isMesh").Value
		if isMesh then
			goal=attacking:WaitForChild("CollisionPart").Position
		end
		goal=attacking:WaitForChild("Body").PrimaryPart.Position
	end
	return goal
end

local function createDroneProjectile(drone,target,tag,timer)
	local owner = game.Players:FindFirstChild(drone.Name)
	if not owner then return end
	if not drone.PrimaryPart then return end
	if not target or not target.PrimaryPart then return end

	local hitRemote = drone:WaitForChild("Hit")
	local properties = drone:WaitForChild("Properties")
	local thug = target:IsDescendantOf(workspace.Thugs)
	local plr = game.Players:GetPlayerFromCharacter(target)
	local villain = target:IsDescendantOf(workspace.Villains)
	local canContinue = false

	if plr then
		local withinRange = (target.PrimaryPart.Position - drone.PrimaryPart.Position).Magnitude < droneRange
		local healthAbove0 = target.Humanoid.Health > 0
		if withinRange and healthAbove0 then
			canContinue = true
		end
	end

	if thug then
		local thug = target
		local physicalZone = rs:WaitForChild("Zones"):FindFirstChild(thug.Properties.Zone.Value)
		local isWithinZone = _math.checkBounds(physicalZone.CFrame,physicalZone.Size,drone.PrimaryPart.Position)
		local isWithinRange = (thug.PrimaryPart.Position - drone.PrimaryPart.Position).Magnitude < droneRange
		local healthAbove0 = thug.Properties.Health.Value > 0
		if isWithinZone and isWithinRange and healthAbove0 then
			canContinue = true
		end
	end

	if villain then
		local isWithinRange = (target.PrimaryPart.Position - drone.PrimaryPart.Position).Magnitude < droneRange
		local healthAbove0 = target.Properties.Health.Value > 0
		if isWithinRange and healthAbove0 then
			canContinue = true
		end
	end

	if not canContinue then return end
	local fireSound = drone.PrimaryPart.fire
	fireSound:Play()

		--[[
		spawn(function()
			local light = drone.PrimaryPart.firePoint.PointLight
			light.Brightness = 1
			task.wait(1/30)
			light.Brightness = 0
		end)]]

	local fireAnimation = droneAnimations.shoot
	local fireAnim = drone.AnimationController:LoadAnimation(fireAnimation)
	fireAnim:Play(.1,1,1.5)

	local origin = drone.PrimaryPart.firePoint.WorldPosition
	local elapsed = workspace:GetServerTimeNow() - timer
	
	local goal=Get_Drone_Villain_Goal(target) or target.PrimaryPart.Position
	local direction = (goal - origin).Unit
	local endPos = (CFrame.new(origin,direction*1000000) * CFrame.new(0,0,-200)).Position
	local startTime = tick()
	local prevOrigin = origin
	local updatedOrigin = origin

	local bullet = rs.Particles.laser_bullet_trail:Clone()
	bullet.CFrame = CFrame.new(origin,endPos)
	bullet.Parent = workspace.Bullets
	game:GetService("Debris"):AddItem(bullet,2)

	task.wait(1/30) -- so the trail can load

	--print("target=",target)
	--print("owner=",owner.Name)

	while true do 
		if not owner or not owner.Character then break end
		local p = math.clamp((workspace:GetServerTimeNow() - timer) - elapsed / 1,0,1)
		updatedOrigin = origin:Lerp(endPos,p)
		local rayLength = (updatedOrigin-prevOrigin).Magnitude
		local newDirection = (updatedOrigin - prevOrigin).Unit
		local newEndPos = CFrame.new(updatedOrigin,newDirection*rayLength).Position
		local result = ray(prevOrigin,newDirection*rayLength,{owner.Character,drone})
		prevOrigin = updatedOrigin

		if result then

			local cf = CFrame.new(result.Position, result.Position - result.Normal)
			bullet.CFrame = cf
			local hit = result.Instance
			local humanoid = hit.Parent:FindFirstChild("Humanoid") or hit.Parent.Parent:FindFirstChild("Humanoid")
			local properties=hit.Parent:FindFirstChild("Properties") or hit.Parent.Parent:FindFirstChild("Properties")

			local isVillain
			local isThug
			local isDrone
			local isPlayer

			if properties then
				isVillain=properties.Parent:IsDescendantOf(workspace:WaitForChild("Villains"))
				isThug=properties.Parent:IsDescendantOf(workspace:WaitForChild("Thugs"))
				isDrone=properties.Parent:IsDescendantOf(workspace:WaitForChild("SpiderDrones"))
			elseif humanoid then
				isPlayer=game.Players:GetPlayerFromCharacter(humanoid.Parent)
			end

			if not owner or not owner:IsDescendantOf(game.Players) then break end

			if owner == player then
				if isPlayer then
					local damage = getSpiderDroneDamage(humanoid.Parent)
					humanoid:TakeDamage(damage)
					hitRemote:FireServer(humanoid.Parent,tag)
					break
				end

				if isDrone then
					local drone = properties.Parent
					local damage = getSpiderDroneDamage(drone)
					hitRemote:FireServer(drone,tag)
					local health = drone.Properties.Health
					local maxHealth = drone.Properties.MaxHealth
					local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
					health.Value = newHealth -- deal damage
					break
				end

				if isThug then
					local model=properties.Parent
					local damage = getSpiderDroneDamage(model)
					hitRemote:FireServer(model,tag)
					local health = model.Properties.Health
					local maxHealth = model.Properties.MaxHealth
					local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
					health.Value = newHealth -- deal damage
					break
				end

				if isVillain then
					local model=properties.Parent
					local isMesh=model:WaitForChild("isMesh")
					local target=isMesh.Value and model or model:WaitForChild("Body")
					local damage = getSpiderDroneDamage(target)
					hitRemote:FireServer(model,tag)
					local health = model.Properties.Health
					local maxHealth = model.Properties.MaxHealth
					local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
					health.Value = newHealth -- deal damage
					break
				end
			end

			break
		end
		bullet.CFrame = CFrame.new(updatedOrigin,endPos)
		if p == 1 then break end
		clock:GetPropertyChangedSignal("Value"):Wait()
	end
	bullet:WaitForChild("PointLight").Enabled = false
end
-- Lol oof
_G.createSpiderDroneEvents=function(child)
	local drone = child
	if child:GetAttribute("EventsLoaded") then return end
	if not drone.PrimaryPart then return end
	local root = drone:WaitForChild("HumanoidRootPart")
	local centerAttachment = root:WaitForChild("center")
	local controller = drone:WaitForChild("AnimationController")
	local idleAnim = controller:LoadAnimation(droneAnimations:WaitForChild("idle"))
	local hitAnim = controller:LoadAnimation(droneAnimations:WaitForChild("hit"))
	--root:WaitForChild("loop"):Play()
	idleAnim.Priority = Enum.AnimationPriority.Idle
	idleAnim:Play(.1,1,6)
	root:WaitForChild("start"):Play()
	local properties = drone:WaitForChild("Properties")
	local health = properties:WaitForChild("Health")
	local maxHealth = properties:WaitForChild("MaxHealth")

	drone:WaitForChild("Health").Enabled = health.Value < maxHealth.Value

	local oldHealth = health.Value
	health:GetPropertyChangedSignal("Value"):Connect(function()
		if oldHealth > health.Value then -- drone took damage
			hitAnim.Priority = Enum.AnimationPriority.Action
			hitAnim:Play(.1,10,2)
			root:WaitForChild("hit"):Play()
			root:WaitForChild("Bolts"):Emit(3)
			for i,v in (centerAttachment:GetChildren()) do
				if v:IsA("ParticleEmitter") then
					v:Emit(3)
				end
			end
		end
		oldHealth = health.Value
		centerAttachment:WaitForChild("smoke").Enabled = health.Value < 50
		_G.tweenHealth(health,maxHealth,drone:WaitForChild("Health"))
		drone:WaitForChild("Health").Enabled = health.Value < maxHealth.Value

		if not (health.Value > 0) then -- drone died
			local controller = drone:WaitForChild("AnimationController")
			for _,track in (controller:GetPlayingAnimationTracks()) do 
				track:Stop()
			end
		end
	end)

	maxHealth:GetPropertyChangedSignal("Value"):Connect(function()
		_G.tweenHealth(health,maxHealth,drone:WaitForChild("Health"))
	end)

	drone:WaitForChild("Fire").OnClientEvent:Connect(function(target,tag,timer)
		createDroneProjectile(drone,target,tag,timer)
	end)
	child:SetAttribute("EventsLoaded",true)
end

local spiderDrones = workspace:WaitForChild("SpiderDrones")
spiderDrones.ChildAdded:Connect(_G.createSpiderDroneEvents)

--[[
for _,drone in (spiderDrones:GetChildren()) do -- create events for those already existing
	createSpiderDroneEvents(drone)
end]]

local function getAttackers(attackersFolder)
	-- get the first attacker
	local orderedList = {}
	local function least(a,b)
		return a[1] < b[1]
	end
	for i,attacker in (attackersFolder:GetChildren()) do 
		local timestamp = attacker.Value
		local timeSinceLastAttack = workspace:GetServerTimeNow() - timestamp
		orderedList[#orderedList+1] = {
			[1] = timeSinceLastAttack,
			[2] = attacker
		}
	end
	table.sort(orderedList,least)
	if #orderedList > 0 then
		--print("the latest attacker is ..", orderedList[1][2].Name)
		--print("the oldest attacker is ..",orderedList[#orderedList][2].Name)		
	end
	return orderedList
end

local function getAttacking(attackingFolder)
	local orderedList = {}
	local function least(a,b)
		return a[1] < b[1]
	end
	for i,attackee in (attackingFolder:GetChildren()) do
		local timestamp = attackee.Value
		local timeSinceLastAttack = workspace:GetServerTimeNow() - timestamp
		orderedList[#orderedList+1] = {
			[1] = timeSinceLastAttack,
			[2] = attackee
		} 
	end
	table.sort(orderedList,least)
	return orderedList
end

local function droneRay(origin,direction)
	--print("ignore2 = ",ignore2)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {
		workspace.BuildingBounds
	}
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

local function droneAttackingEligibility(attacking,root,attackingFolder,attackersFolder)
	local ignoreY = Vector3.new(1,0,1)
	if attacking.Value ~= nil and attacking.Value.Parent ~= nil then
		local attackingListing = attackingFolder:FindFirstChild(attacking.Value.Name)
		local attackerListing = attackersFolder:FindFirstChild(attacking.Value.Name)
		local isStillActive = attackingListing or attackerListing
		if not isStillActive then
			return true
		end		
		local plr = game.Players:GetPlayerFromCharacter(attacking.Value)
		if plr then
			local recent=false
			for i,v in {attackingListing,attackerListing} do 
				local elapsed=workspace:GetServerTimeNow()-v.Value
				if elapsed<5 then
					recent=true
				end
			end
			if not recent then return true end
			local healthIsAbove0 = attacking.Value.Humanoid.Health > 0
			local isWithinRange = ((attacking.Value.PrimaryPart.Position * ignoreY) - (root.Position * ignoreY)).Magnitude < droneRange
			if healthIsAbove0 and isWithinRange then
				return false
			else 
				return true
			end
		end
		local thug = workspace:WaitForChild("Thugs"):FindFirstChild(attacking.Value.Name)
		local villain = workspace:WaitForChild("Villains"):FindFirstChild(attacking.Value.Name)
		if thug then
			local properties = thug.Properties
			local healthIsAbove0 = properties.Health.Value > 0
			local physicalZone = rs:WaitForChild("Zones"):WaitForChild(properties.Zone.Value)
			local isWithinZone = _math.checkBounds(physicalZone.CFrame,physicalZone.Size,root.Position)
			local isWithinRange = ((root.Position * ignoreY) - (thug.PrimaryPart.Position * ignoreY)).Magnitude < droneRange
			if isWithinRange and isWithinZone and healthIsAbove0 then
				return false
			else 
				return true
			end
		end
		if villain then
			local venom = villain:FindFirstChild("VenomMesh")
			if venom then
				venom = venom.Parent
				local properties = venom.Properties
				local healthIsAbove0 = properties.Health.Value > 0
				local isWithinRange = ((root.Position * ignoreY) - (venom.PrimaryPart.Position * ignoreY)).Magnitude < droneRange
				if isWithinRange and healthIsAbove0 then
					return false
				else 
					return true
				end			
			end
		end
	else 
		return true
	end
end

local function checkCharacter(plr,char,root,attacking,ignoreY)
	local healthIsOver0 = char.Humanoid.Health > 0
	local withinRange = ((char.PrimaryPart.Position * ignoreY) - (root.Position * ignoreY)).Magnitude < droneRange
	if healthIsOver0 and withinRange then
		attacking.Value = plr.Character
	end
end

local function find_next_target(ignoreY,root,search,attacking)
	local plr = game.Players:FindFirstChild(search)
	if plr then -- change target to this
		local char = plr.Character
		if char and char.PrimaryPart then
			local healthIsOver0 = char.Humanoid.Health > 0
			local withinRange = ((char.PrimaryPart.Position * ignoreY) - (root.Position * ignoreY)).Magnitude < droneRange
			if healthIsOver0 and withinRange then
				attacking.Value = plr.Character
			end
		end
	else 
		local thug = workspace:WaitForChild("Thugs"):FindFirstChild(search)
		local villain = workspace:WaitForChild("Villains"):FindFirstChild(search)
		if thug and thug.PrimaryPart then
			local properties = thug.Properties
			local physicalZone = rs:WaitForChild("Zones"):WaitForChild(properties.Zone.Value)
			local isWithinZone = _math.checkBounds(physicalZone.CFrame,physicalZone.Size,root.Position)
			local isWithinRange = ((root.Position * ignoreY) - (thug.PrimaryPart.Position * ignoreY)).Magnitude < droneRange
			local healthIsOver0 = properties.Health.Value > 0
			if healthIsOver0 and isWithinRange and isWithinZone then
				attacking.Value = thug
			end
		end
		if villain and villain.PrimaryPart then
			local properties = villain.Properties
			local isWithinRange = ((root.Position * ignoreY) - (villain.PrimaryPart.Position * ignoreY)).Magnitude < droneRange
			local healthIsOver0 = properties.Health.Value > 0
			if healthIsOver0 and isWithinRange then
				attacking.Value = villain
			end
		end
	end
end

local function deploySpiderDrone()
	local drones = workspace:WaitForChild("SpiderDrones")
	local drone = drones:FindFirstChild(player.Name)
	if drone then
		local root = drone:WaitForChild("HumanoidRootPart")
		local gyro = root:WaitForChild("BodyGyro")
		local position = root:WaitForChild("BodyPosition")
		local properties = drone:WaitForChild("Properties")
		local target = properties:WaitForChild("Target")
		local attacking = properties:WaitForChild("Attacking")
		local lastAttack = properties:WaitForChild("lastAttack")
		local attackingFolder = leaderstats:WaitForChild("attacking")
		local attackersFolder = leaderstats:WaitForChild("attackers")
		local ignoreY = Vector3.new(1,0,1)
		local health = properties:WaitForChild("Health")
		local i = 0
		while drone.Parent ~= nil do
			local character = player.Character
			if not character or not character.PrimaryPart or not (character.Humanoid.Health > 0) then break end
			if health.Value > 0 then
				--pcall(function()
				local attackerArray = getAttackers(attackersFolder)
				local attackingArray = getAttacking(attackingFolder)
				local searchForNextAttacker = droneAttackingEligibility(attacking,root,attackingFolder,attackersFolder)
				if searchForNextAttacker then
					attacking.Value = nil -- reset the attacking value
					target.Value = nil
					if #attackingArray > 0 then
						local lastAttacked = attackingArray[1][2].Name
						find_next_target(ignoreY,root,lastAttacked,attacking)
					else 
						if #attackerArray > 0 and not attacking.Value then
							local lastAttacker = attackerArray[1][2].Name
							find_next_target(ignoreY,root,lastAttacker,attacking)
						end				
					end
				end

				if attacking.Value and attacking.Value.PrimaryPart then
					local origin = root.Position
					local goal = attacking.Value.PrimaryPart.Position
					goal=Get_Drone_Villain_Goal(attacking.Value) or goal
					local direction = (goal - origin).Unit * (origin - goal).Magnitude
					local result = droneRay(origin,direction)
					if result then -- there was an obstruction in the way of the target
						attacking.Value = nil
					end
				end

				if attacking.Value then 
					target.Value = attacking.Value -- look towards the enemy
					if tonumber(lastAttack.Value) then
						if workspace:GetServerTimeNow() - lastAttack.Value > 2 then
							local tag = game:GetService("HttpService"):GenerateGUID(false)
							drone:WaitForChild("Fire"):FireServer(target.Value,tag)	
						end								
					else
						local tag = game:GetService("HttpService"):GenerateGUID(false)
						drone:WaitForChild("Fire"):FireServer(target.Value,tag)	
					end
				else -- look ahead
					target.Value = character
				end

				if target.Value and character:FindFirstChild("HumanoidRootPart") then 
					i += (math.pi*2)/300
					if i >= math.pi*2 then
						i = 0
					end
					--local x,y,z = nil,nil,nil
					local lookAtCF = nil
					if target.Value == character then
						local ahead = character.PrimaryPart.CFrame * CFrame.new(0,0,-100)
						lookAtCF = CFrame.new(root.Position,ahead.Position)
						--x,y,z = lookAtCF:ToOrientation()				
					else -- its an enemy, make the drone look at the enemy
						local goal=Get_Drone_Villain_Goal(attacking.Value) or target.Value.PrimaryPart.Position
						lookAtCF = CFrame.new(root.Position,goal)
						--x,y,z = lookAtCF:ToOrientation()
					end
					local rootOffset = character.PrimaryPart.CFrame * CFrame.new(4,2+math.sin(i),-1)
					gyro.CFrame = lookAtCF--CFrame.new(root.Position) * CFrame.fromOrientation(0,y,0)
					position.Position = rootOffset.Position
					if (character.PrimaryPart.Position-drone.PrimaryPart.Position).Magnitude>50 then
						drone:SetPrimaryPartCFrame(rootOffset)
					end
				end	

				--end)
			else 
				gyro.MaxTorque = Vector3.new(0,0,0)	
				position.MaxForce = Vector3.new(0,0,0)
			end
			task.wait(1/30)
		end
	end
end

local function spiderDrone()
	local character = player.Character
	if not character or not character.PrimaryPart then return end 

	local throw = combatAnims:WaitForChild("bomb"):WaitForChild("Throw")
	local humanoid = character:WaitForChild("Humanoid")

	local throwAnim = humanoid:LoadAnimation(throw)
	throwAnim:Play(.1,1,4)

	throwAnim:GetMarkerReachedSignal("Release"):Wait()

	local rightGrip = character:WaitForChild("RightHand"):WaitForChild("RightGripAttachment")
	local target = (camera.CFrame * CFrame.new(0,0,-250)).Position

	local origin = rightGrip.WorldPosition
	local direction = (target - origin).Unit * 250
	local result = ray(origin,direction,{character})
	if result then
		target = result.Position
	end

	local tag = game:GetService("HttpService"):GenerateGUID(false)
	local timer = workspace:GetServerTimeNow()
	actionRemote:FireServer("Special","Spider Drone","New",tag,origin,target,timer)

	local render_Throwable = coroutine.wrap(renderThrowable)
	render_Throwable("spider drone",player.Name,origin,target,timer,tag)
end

local function GauntletSnap(plr) -- other players need to play the snap animation!
	if not plr.Character then return end
	local vars={}
	vars.character=plr.Character
	if not vars.character.PrimaryPart then return end
	if not vars.character:FindFirstChild("Gauntlet") then
		vars.start=tick()
		repeat task.wait() until vars.character:FindFirstChild("Gauntlet") or tick()-vars.start>=.5
	end
	vars.humanoid=vars.character:WaitForChild("Humanoid")

	local function PlaySnap()
		if not vars.character:FindFirstChild("Gauntlet") then return end
		vars.gauntlet=vars.character.Gauntlet
		vars.GauntletSnapAnimation=vars.gauntlet:WaitForChild("Animations"):WaitForChild("Snap")
		vars.GauntletSnapAnim=vars.gauntlet:WaitForChild("AnimationController"):LoadAnimation(vars.GauntletSnapAnimation)
		vars.GauntletSnapAnim:Play(.2,1,1)
	end

	-- snap gauntlet anim takes .25 seconds to play to the snap
	-- player snap anim takes .25 seconds

	if plr==player then -- play your animations here
		vars.tag = game:GetService("HttpService"):GenerateGUID(false)
		stopAllOtherTracks(vars.humanoid)
		vars.PlayerSnapAnimation=combatAnims:WaitForChild("gauntlet"):WaitForChild("Snap")
		vars.PlayerSnapAnim=vars.humanoid:LoadAnimation(vars.PlayerSnapAnimation)
		vars.PlayerSnapAnim:Play(.2,1,1)
		PlaySnap()
		vars.PlayerSnapAnim:GetMarkerReachedSignal("snap"):Wait()
		actionRemote:FireServer("Special","Gauntlet","Snap",workspace:GetServerTimeNow(),vars.tag)
		_G.playAbilitySound(vars.character,"Gauntlet")
	else 
		-- get the elapsed time, subtract the time it takes to snap 
		PlaySnap()
		_G.playAbilitySound(vars.character,"Gauntlet")
	end
	
	return workspace:GetServerTimeNow()
end

local function Gauntlet(plrName,timer,origin)
	local vars={}
	vars.plr=game.Players:FindFirstChild(plrName)
	if not vars.plr then return end -- plr doesn't exist
	if not vars.plr.Character or not vars.plr.Character.PrimaryPart then return end
	origin=origin or vars.plr.Character.PrimaryPart.Position
	if vars.plr~=player then
		GauntletSnap(vars.plr) -- play the snap animation and sound for everyone else!
		--timer+=.25 -- add the time it took for the original client to snap
	end
	vars.character=vars.plr.Character

	if vars.plr==player then
		vars.level = abilities.Special.Gauntlet.Level.Value
		vars.misc = items.Special.Gauntlet.misc[2]
		vars.damage = _math.getStat(vars.level,vars.misc.base,vars.misc.multiplier)
		vars.crit = rngs["Gauntlet"].rng:NextNumber(0,100)
		--print("client crit=",vars.crit)
		vars.damage,vars.crit = getNewDamageWithCritical(vars.damage,vars.crit)
	end

	vars.blacklist={}

	vars.runNPC=function(model)
		vars.properties = model.Properties
		vars.health = vars.properties.Health
		vars.maxHealth = vars.properties.MaxHealth
		vars.remaining = vars.health.Value - vars.damage < 0 and vars.health.Value or vars.damage
		vars.remaining = math.clamp(vars.remaining,0,vars.maxHealth.Value)
		--print("damage=",vars.damage)
		--print("remaining=",vars.remaining)
		--print("health=",vars.health.Value)
		local f = coroutine.wrap(hitMarker)
		f(model,vars.remaining,vars.crit,"Gauntlet","Special",origin)	
	end

	vars.runPlayer=function(model)
		vars.humanoid = model.Humanoid
		vars.health = vars.humanoid.Health
		vars.remaining = vars.health - vars.damage < 0 and vars.health or vars.damage
		vars.remaining = math.clamp(vars.remaining,0,vars.humanoid.MaxHealth)
		local f = coroutine.wrap(hitMarker)
		f(model,vars.remaining,vars.crit,"Gauntlet","Special",origin)	
	end

	vars.checkNPCs=function(range)
		for _,drone in workspace:WaitForChild("SpiderDrones"):GetChildren() do 
			if drone.Name==player.Name then continue end -- exclude your drone
			if vars.blacklist[drone] then continue end
			if not drone.PrimaryPart then return end
			vars.distance=(drone.PrimaryPart.Position-origin).Magnitude
			if vars.distance<=range then
				vars.blacklist[drone]=true
				vars.runNPC(drone)
			end
		end

		for _,thug in workspace:WaitForChild("Thugs"):GetChildren() do 
			if vars.blacklist[thug] then continue end
			if not thug.PrimaryPart then continue end
			vars.distance=(thug.PrimaryPart.Position-origin).Magnitude
			if vars.distance<=range then
				vars.blacklist[thug]=true
				vars.runNPC(thug)
			end
		end

		for _,villain in workspace:WaitForChild("Villains"):GetChildren() do 
			if vars.blacklist[villain] then continue end
			if not villain.PrimaryPart then continue end
			vars.distance=(villain.PrimaryPart.Position-origin).Magnitude
			if vars.distance<=range then
				vars.blacklist[villain]=true
				vars.runNPC(villain)
			end
		end
	end

	vars.checkPlayers=function(range)
		for _,player in game.Players:GetPlayers() do 
			if player==vars.plr then continue end -- ignore the snapper
			if not player.Character or not player.Character.PrimaryPart then continue end
			if vars.blacklist[player.Name] then continue end
			vars.distance=(player.Character.PrimaryPart.Position-origin).Magnitude
			if vars.distance<=range then
				vars.blacklist[player.Name]=true
				vars.runPlayer(player.Character)
			end
		end
	end

	vars.shockwave=rs:WaitForChild("GauntletShockWave"):Clone()
	vars.shockwave.Position=origin
	vars.shockwave.Size=Vector3.new()
	vars.shockwave.Parent=workspace

	vars.level = vars.plr.leaderstats.abilities.Special.Gauntlet.Level.Value
	vars.misc = items.Special.Gauntlet.misc[1]
	vars.range = _math.getStat(vars.level,vars.misc.base,vars.misc.multiplier)
	vars.duration = (vars.range/375)*3

	local distanceFromCamera = (camera.CFrame.Position - origin).Magnitude
	if vars.plr~=player then
		if distanceFromCamera>vars.range then return end -- don't play these effects cause you're too far away!
	end

	--local percent = math.clamp(1-(math.clamp(distanceFromCamera - 15,0,vars.range) / vars.range),0,1)
	--local f = coroutine.wrap(_G.camShake)
	--f(.5,percent)

	--local tweenInfo1=TweenInfo.new(.5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,true,0)
	--ts:Create(game.Lighting:WaitForChild("colorCorrection"),tweenInfo1,{Saturation=-1}):Play()
	vars.colorCorrection=game.Lighting:WaitForChild("colorCorrection")
	
	vars.i=0
	while true do
		vars.i+=1
		vars.elapsed=workspace:GetServerTimeNow()-timer
		vars.p=math.clamp(vars.elapsed/vars.duration,0,1)
		vars.saturationP=math.clamp(vars.elapsed/.8,0,1)
		
		if vars.i%2==0 and vars.plr==player then -- every other iteration
			vars.checkNPCs(vars.range*vars.p)
			vars.checkPlayers(vars.range*vars.p)
		end
		
		if player.Character then
			vars.colorCorrection.Saturation=cs:HasTag(player.Character,"Died") and -1 or _math.lerp(.25,-1,math.sin(math.pi*vars.saturationP))
		end
		
		for _,surfaceGui in vars.shockwave:GetChildren() do 
			surfaceGui.ImageLabel.ImageTransparency=1*vars.p
		end
		
		vars.shockwave.Size=Vector3.new((vars.range*2)*vars.p,0,(vars.range*2)*vars.p)
		if vars.p==1 then break end
		clock:GetPropertyChangedSignal("Value"):Wait()
	end
	vars.shockwave:Destroy()
	
end

actionRemote.OnClientEvent:Connect(function(...)
	local args = {...} 
	--pcall(function()
	if args[1] == "travel" then
		render3DWeb(args[1],args[2],args[3],args[4],args[5],args[6],args[7])
	elseif args[1] == "projectile" then
		renderProjectile(args[2],args[3],args[4],args[5],args[6],args[7],args[8])
	elseif args[1] == "trip" then
		render3DWeb(args[2],args[3],args[4],args[5],args[6],args[7],args[8])
	elseif args[1] == "trip remove" then
		removeTripWebAndReSort(args[2],args[3],args[4])
	elseif args[1] == "webBombAdd" then 
		renderThrowable("web bomb",args[2],args[3],args[4],args[5],args[6])
	elseif args[1] == "webBombExplode" then 
		explodeWebBomb(args[2],args[3],args[4],args[5])
	elseif args[1] == "gravityBombAdd" then
		renderThrowable("gravity bomb",args[2],args[3],args[4],args[5],args[6])
	elseif args[1] == "gravityBombExplode" then 
		explodeGravityBomb(args[2],args[3],args[4])
	elseif args[1] == "spiderDroneAdd" then
		renderThrowable("spider drone",args[2],args[3],args[4],args[5],args[6])
	elseif args[1] == "spiderDroneDeploy" then
		deploySpiderDrone()
	elseif args[1]=="ReplicateGauntletEffect" then
		Gauntlet(args[2],args[3],args[4]) -- playerName,timer,origin
	end
	--end)
end)

local function projectileServerSignal(anim,category,tag)
	local character = player.Character
	if not character or not character.PrimaryPart then return end

	local origins = {
		[1] = character:WaitForChild("LeftHand"):WaitForChild("LeftGripAttachment").WorldPosition,
		[2] = character:WaitForChild("RightHand"):WaitForChild("RightGripAttachment").WorldPosition
	}

	local origin = origins[anim]
	local target = (camera.CFrame * CFrame.new(0,0,-250)).Position
	local ignore = player.Character 
	local ignore2 = workspace:WaitForChild("SpiderDrones"):FindFirstChild(player.Name)
	local ignore3 = player.Character:FindFirstChild("SpiderLegs")
	local aheadOfCam = camera.CFrame * CFrame.new(Vector3.new(0,0,-3))
	local raycastResult = ray(aheadOfCam.Position,((target - aheadOfCam.Position).Unit * 250),{ignore,ignore2,ignore3})
	if raycastResult then
		target = raycastResult.Position
	end

	actionRemote:FireServer("Ranged",origin,target,category,workspace:GetServerTimeNow(),tag)
end

local flyingKick = combatAnims:WaitForChild("kick"):WaitForChild("FlyingKick")
local sideKick = combatAnims:WaitForChild("kick"):WaitForChild("SideKick")
local spinningKick = combatAnims:WaitForChild("kick"):WaitForChild("SpinningKick")

local comboResetThreshold = 1 -- seconds to punch again or combos will reset
local currentPunchCombo = 1
local currentPunch = 1

local function resetPunchCombo()
	currentPunchCombo = 1
	currentPunch = 1
end

local impactAnims = {
	[1] = shootAnimFolder:WaitForChild("impact"):WaitForChild("WebShootLeft"),
	[2] = shootAnimFolder:WaitForChild("impact"):WaitForChild("WebShootRight"),
}

local snareAnims = {
	[1] = shootAnimFolder:WaitForChild("snare"):WaitForChild("WebShootLeft"),
	[2] = shootAnimFolder:WaitForChild("snare"):WaitForChild("WebShootRight"),
}

local currentShootAnim = 1
local _start = tick() - 50

local ticks={}
ticks.punchTick = _start
ticks.kickTick = _start
ticks._360KickTick = _start
ticks.impactWebTick = _start
ticks.shotgunTick = _start
ticks.snareTick = _start
ticks.swingTick = _start
ticks.launchTick = _start
ticks.tripTick = _start
ticks.webBombTick = _start
ticks.antiGravityBombTick = _start
ticks.spiderDroneTick = _start
ticks.gauntletTick = _start

local function TripWebInfo()
	local level = abilities:WaitForChild("Traps"):WaitForChild("Trip Web").Level.Value
	local trip_web_amt_base = items.Traps["Trip Web"].misc[1].base
	local trip_web_amt_multiplier = items.Traps["Trip Web"].misc[1].multiplier
	local allowed_trip_webs = _math.getStat(level,trip_web_amt_base,trip_web_amt_multiplier)
	local current_trip_web_amt = TR_amount.Value
	return allowed_trip_webs, current_trip_web_amt
end

local function getVillainsArray()
	local t={}
	for _,villain in workspace:WaitForChild("Villains"):GetChildren() do 
		local body=villain:FindFirstChild("Body")
		local collisionPart=villain:FindFirstChild("CollisionPart")
		body=collisionPart or body
		t[#t+1]=body
	end
	return t
end

local function getPartsInBoundingBoxForAttackables(cframe,size)
	local inSafeZone=checkSafeZones(cframe.Position)
	local array=inSafeZone and {} or getCharacterModelsArray()
	local whitelist = {
		workspace.Thugs,
		not inSafeZone and workspace.SpiderDrones or nil
	}
	
	for _,value in getVillainsArray() do -- add the villain collisions
		array[#array+1] = value
	end
	
	for _,value in (whitelist) do 
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

local thugs=workspace:WaitForChild("Thugs")
local villains=workspace:WaitForChild("Villains")
local function getClosestOrderedModels(attackablePartsBounds,cf)
	local dict = {}
	local models = {}
	if #attackablePartsBounds > 0 then
		for _,part in (attackablePartsBounds) do 
			local humanoid = part.Parent:FindFirstChild("Humanoid") or part.Parent.Parent:FindFirstChild("Humanoid")
			local properties = part.Parent:FindFirstChild("Properties") or part.Parent.Parent:FindFirstChild("Properties")
			local thug_or_villain=humanoid and (humanoid:IsDescendantOf(thugs) or humanoid:IsDescendantOf(villains))
			if humanoid and not thug_or_villain then
				if not dict[humanoid.Parent.Name] then
					dict[humanoid.Parent.Name] = true
					--print("found",humanoid.Parent)
					local enemyRootPos = humanoid.Parent.PrimaryPart.Position
					models[#models+1] = {
						[1] = (cf.Position - enemyRootPos).Magnitude,
						[2] = humanoid.Parent
					}					
				end	
			end
			if properties and properties.Parent.Name ~= player.Name then -- make sure its not your drone
				local isDrone = properties.Parent:IsDescendantOf(workspace:WaitForChild("SpiderDrones"))
				if isDrone then
					local tag = properties:WaitForChild("Tag").Value
					if not dict[tag] then
						dict[tag] = true
						local enemyRootPos = properties.Parent.PrimaryPart.Position
						models[#models+1] = {
							[1] = (cf.Position - enemyRootPos).Magnitude,
							[2] = properties.Parent
						}
					end
				else -- villains n thugs
					if not dict[properties.Parent.Name] then
						dict[properties.Parent.Name] = true
						--print("found",properties.Parent)
						local enemyRootPos = properties.Parent.PrimaryPart.Position
						models[#models+1] = {
							[1] = (cf.Position - enemyRootPos).Magnitude,
							[2] = properties.Parent
						}
					end					
				end	
			end
		end
	else
		--print("there were no attackables infront of player")
	end
	table.sort(models,_math.least)
	return models
end

local function punch(arm,hand,tag,comboDamage)
	local character = player.Character
	if not character or not character.PrimaryPart or not (character:WaitForChild("Humanoid").Health > 0) then 
		--[[print("you died so can't deal damage")]] 
		return 
	end
	local size = Vector3.new(arm.Size.X*2,arm.Size.Y*2.5,(arm.Position - hand.Position).Magnitude*1.25)
	local cf = CFrame.new(arm.Position:Lerp(hand.Position,.5),hand.Position) * CFrame.new(0,-arm.Size.Y/2.5,-size.Z/2)
	--workspace.placementA.CFrame = cf
	--workspace.placementA.Size = size

	--local cframe = character.PrimaryPart.CFrame * CFrame.new(0,0,-2)
	--local size = Vector3.new(3,4,4)
	local attackablePartsBounds = getPartsInBoundingBoxForAttackables(cf,size)
	local models = getClosestOrderedModels(attackablePartsBounds,cf)
	if #models>0 then
		local model = models[1][2]
		--print("punched ",model.Name)
		actionRemote:FireServer("Melee","Hit","Punch",model,tag)

		local level = abilities.Melee.Punch.Level.Value
		local misc = items.Melee.Punch.misc[1]
		local damage = 0--_math.getStat(level,misc.base,misc.multiplier)
		local crit = rngs["Punch"].rng:NextNumber(0,100)
		--print("Punch crit = ",crit)
		damage,crit = getNewDamageWithCritical(comboDamage,crit)

		local isNPC = model:FindFirstChild("Properties")
		local isCharacter = game.Players:GetPlayerFromCharacter(model)
		local remaining = 0
		if isNPC then
			local properties = model.Properties
			local health = properties.Health
			local maxHealth = properties.MaxHealth
			remaining = health.Value - damage < 0 and health.Value or damage
			remaining = math.clamp(remaining,0,maxHealth.Value)
			--local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
			--health.Value = newHealth -- deal damage	
		else
			if isCharacter then
				local humanoid = model.Humanoid
				local health = humanoid.Health
				remaining = health - damage < 0 and health or damage
				remaining = math.clamp(remaining,0,humanoid.MaxHealth)
				--humanoid:TakeDamage(damage)
			end
		end
		local isVillain = model:IsDescendantOf(workspace:WaitForChild("Villains"))
		if isVillain then
			--print("detected head")
			local properties = model:WaitForChild("Properties")
			local isMesh=model:WaitForChild("isMesh")
			local head=isMesh.Value and properties:WaitForChild("Head").Value or model:WaitForChild("Body"):WaitForChild("Head")
			if not isMesh.Value then
				model=model:WaitForChild("Body")
			end
			local pos = isMesh.Value and head.TransformedWorldCFrame.Position or head.Position
			effects.MeleeEffect(pos)
		else
			local head = model:FindFirstChild("Head")
			effects.MeleeEffect(head and head.Position or model.PrimaryPart.Position)				
		end
		local f = coroutine.wrap(hitMarker)
		f(model,remaining,crit,"Punch","Melee")		
	end
end

local function kick(hrp,tag,comboDamage)
	local size = Vector3.new(3.5,5,4)
	local cf = hrp.CFrame * CFrame.new(size.X*.25,0,-size.Z*.75)
	--workspace.placementA.CFrame = cf
	--workspace.placementA.Size = size
	local attackablePartsBounds = getPartsInBoundingBoxForAttackables(cf,size)
	local models = getClosestOrderedModels(attackablePartsBounds,cf)
	if #models>0 then
		local model = models[1][2]
		--print("kicked ",model.Name)
		actionRemote:FireServer("Melee","Hit","Kick",model,tag)

		local level = abilities.Melee.Kick.Level.Value
		local misc = items.Melee.Kick.misc[1]
		local damage = 0--_math.getStat(level,misc.base,misc.multiplier)
		local crit = rngs["Kick"].rng:NextNumber(0,100)
		--print("Kick crit = ",crit)
		damage,crit = getNewDamageWithCritical(comboDamage,crit)

		local isNPC = model:FindFirstChild("Properties")
		local isCharacter = game.Players:GetPlayerFromCharacter(model)
		local remaining = 0
		if isNPC then
			local properties = model.Properties
			local health = properties.Health
			local maxHealth = properties.MaxHealth
			remaining = health.Value - damage < 0 and health.Value or damage
			remaining = math.clamp(remaining,0,maxHealth.Value)
			--local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
			--health.Value = newHealth -- deal damage	
		else
			if isCharacter then
				local humanoid = model.Humanoid
				local health = humanoid.Health
				remaining = health - damage < 0 and health or damage
				remaining = math.clamp(remaining,0,humanoid.MaxHealth)
				--humanoid:TakeDamage(damage)
			end
		end

		local isVillain = model:IsDescendantOf(workspace:WaitForChild("Villains"))
		if isVillain then
			--print("detected head")
			local properties = model:WaitForChild("Properties")
			local isMesh=model:WaitForChild("isMesh")
			local head=isMesh.Value and properties:WaitForChild("Head").Value or model:WaitForChild("Body"):WaitForChild("Head")
			if not isMesh.Value then
				model=model:WaitForChild("Body")
			end
			local pos = isMesh.Value and head.TransformedWorldCFrame.Position or head.Position
			effects.MeleeEffect(pos)
		else
			local head = model:FindFirstChild("Head")
			effects.MeleeEffect(head and head.Position or model.PrimaryPart.Position)				
		end
		local f = coroutine.wrap(hitMarker)
		f(model,remaining,crit,"Kick","Melee")		
	end
end

local function kick360(hrp,tag,comboDamage)
	local size = Vector3.new(8,5,4)
	local cf = hrp.CFrame * CFrame.new(0,0,-size.Z*.75)
	--workspace.placementA.CFrame = cf
	--workspace.placementA.Size = size
	local attackablePartsBounds = getPartsInBoundingBoxForAttackables(cf,size)
	local models = getClosestOrderedModels(attackablePartsBounds,cf)
	if #models>0 then
		--print("360 kicked:")
		--[[
		for i,v in (models) do 
			for a,b in (v) do 
				--print(a,b)
			end
		end
		]]
		actionRemote:FireServer("Melee","Hit","360 Kick",models,tag)

		local level = abilities.Melee["360 Kick"].Level.Value
		local misc = items.Melee["360 Kick"].misc[1]
		local damage = 0--_math.getStat(level,misc.base,misc.multiplier)
		local crit = rngs["360 Kick"].rng:NextNumber(0,100)
		--print("360 Kick crit = ",crit)
		damage,crit = getNewDamageWithCritical(comboDamage,crit)

		for i,v in (models) do
			local model = v[2]
			local isNPC = model:FindFirstChild("Properties")
			local isCharacter = game.Players:GetPlayerFromCharacter(model)
			local remaining = 0
			if isNPC then
				local properties = model.Properties
				local health = properties.Health
				local maxHealth = properties.MaxHealth
				remaining = health.Value - damage < 0 and health.Value or damage
				remaining = math.clamp(remaining,0,maxHealth.Value)
				--local newHealth = math.clamp(health.Value - damage,0,maxHealth.Value)
				--health.Value = newHealth -- deal damage	
			else
				if isCharacter then
					local humanoid = model.Humanoid
					local health = humanoid.Health
					remaining = health - damage < 0 and health or damage
					remaining = math.clamp(remaining,0,humanoid.MaxHealth)
					--humanoid:TakeDamage(damage)
				end
			end

			--local isDrone = model:FindFirstChild("Drone")
			local isVillain = model:IsDescendantOf(workspace:WaitForChild("Villains"))
			if isVillain then
				--print("detected head")
				local properties = model:WaitForChild("Properties")
				local isMesh=model:WaitForChild("isMesh")
				local head=isMesh.Value and properties:WaitForChild("Head").Value or model:WaitForChild("Body"):WaitForChild("Head")
				if not isMesh.Value then
					model=model:WaitForChild("Body")
				end
				local pos = isMesh.Value and head.TransformedWorldCFrame.Position or head.Position
				effects.MeleeEffect(pos)
			else
				local head = model:FindFirstChild("Head")
				effects.MeleeEffect(head and head.Position or model.PrimaryPart.Position)				
			end
			local f = coroutine.wrap(hitMarker)
			f(model,remaining,crit,"360 Kick","Melee")		
		end
	end
end

if not _G.playAbilitySound then
	repeat task.wait(1/30) until _G.playAbilitySound
end

local cooldowns = {
	["Roll"]=1,
	["Punch"] = .25,
	["Kick"] = .5,
	["360 Kick"] = .75,
	["Swing Web"] = .5,--.25,
	["Launch Webs"] = .5,--.25,
	["Impact Web"] = .25,
	["Snare Web"] = 30,
	["Shotgun Webs"] = .5,
	["Trip Web"] = .25,
	["Web Bomb"] = 10,
	["Anti Gravity"] = 30,
	["Spider Drone"] = 10,
	["Gauntlet"] = 10
}

local f = {
	["Punch"] = function()
		if (tick() - ticks.punchTick >= comboResetThreshold) then -- reset the combo
			resetPunchCombo()
		end
		if tick() - ticks.punchTick >= cooldowns["Punch"] then
			local character = player.Character
			if character and character.PrimaryPart then
				ticks.punchTick = tick()
				local humanoid = character:WaitForChild("Humanoid")
				stopAllOtherTracks(humanoid)
				local currentCombo = punchCombos[currentPunchCombo]
				local currentAnim = humanoid:LoadAnimation(currentCombo[currentPunch])
				currentAnim:Play(0.100000001,1,2)
				local tag = game:GetService("HttpService"):GenerateGUID(false)
				local comboDamage=combo(items["Melee"]["Punch"].misc[1],abilities["Melee"]["Punch"].Level.Value)
				actionRemote:FireServer("Melee","Punch",workspace:GetServerTimeNow(),tag)
				local hands = {
					[1] = character:WaitForChild("RightHand"),
					[2] = character:WaitForChild("LeftHand")
				}
				local arms = {
					[1] = character:WaitForChild("RightUpperArm"),
					[2] = character:WaitForChild("LeftUpperArm")
				}
				local hand = hands[(currentPunch%2)+1]
				local arm = arms[(currentPunch%2)+1]
				currentPunch +=1
				local function waitForSignal()
					_G.playAbilitySound(character,"throw")
					punch(character.PrimaryPart,hand,tag,comboDamage)
				end
				currentAnim:GetMarkerReachedSignal("hit"):Connect(waitForSignal)
				if (currentPunch > #currentCombo) then -- move on to next combo
					currentPunchCombo += 1
					currentPunch = 1
					if (currentPunchCombo > #punchCombos) then -- reset punch combos
						resetPunchCombo()
					end
				end
			end
		end
	end,
	["Kick"] = function()
		if (tick() - ticks.kickTick >= cooldowns["Kick"]) then
			ticks.kickTick = tick()
			local character = player.Character
			if not character or not character.PrimaryPart then return end
			local humanoid = character:WaitForChild("Humanoid")
			stopAllOtherTracks(humanoid)
			local currentAnim = nil
			if (humanoid.MoveDirection.Magnitude > 0) then -- is moving, do flying kick
				currentAnim = humanoid:LoadAnimation(flyingKick)
				currentAnim:Play(0.100000001,1,2)
			else 
				currentAnim = humanoid:LoadAnimation(sideKick)
				currentAnim:Play(0.100000001,1,2)
			end
			local tag = game:GetService("HttpService"):GenerateGUID(false)
			local comboDamage=combo(items["Melee"]["Kick"].misc[1],abilities["Melee"]["Kick"].Level.Value)
			actionRemote:FireServer("Melee","Kick",workspace:GetServerTimeNow(),tag)
			local function waitForSignal()
				_G.playAbilitySound(character,"kick")
				kick(character.PrimaryPart,tag,comboDamage)
			end
			currentAnim:GetMarkerReachedSignal("hit"):Connect(waitForSignal)
		end 
	end,
	["360 Kick"] = function()
		if (tick() - ticks._360KickTick >= cooldowns["360 Kick"]) then
			ticks._360KickTick = tick()
			local character = player.Character
			if not character or not character.PrimaryPart then return end
			local humanoid = character:WaitForChild("Humanoid")
			stopAllOtherTracks(humanoid)
			local currentAnim = humanoid:LoadAnimation(spinningKick)
			currentAnim:Play(0.2,1,2)
			local tag = game:GetService("HttpService"):GenerateGUID(false)
			local comboDamage=combo(items["Melee"]["360 Kick"].misc[1],abilities["Melee"]["360 Kick"].Level.Value)
			actionRemote:FireServer("Melee","360 Kick",workspace:GetServerTimeNow(),tag)
			local function waitForSignal()
				_G.playAbilitySound(character,"kick")
				kick360(character.PrimaryPart,tag,comboDamage)
			end
			currentAnim:GetMarkerReachedSignal("hit"):Connect(waitForSignal)
		end
	end,
	["Swing Web"] = function()
		if (tick() - ticks.swingTick >= cooldowns["Swing Web"]) then
			ticks.swingTick = tick()
			local character = player.Character
			if character and character.PrimaryPart then
				_G.playAbilitySound(character,"travel")
				swingWeb()				
			end
		end
	end,
	["Launch Webs"] = function()
		if (tick() - ticks.launchTick >= cooldowns["Launch Webs"]) then
			ticks.launchTick = tick()
			local character = player.Character
			if character and character.PrimaryPart then
				_G.playAbilitySound(character,"travel")
				launchWeb()				
			end
		end
	end,
	["Impact Web"] = function()
		if (tick() - ticks.impactWebTick >= cooldowns["Impact Web"]) then
			ticks.impactWebTick = tick()
			local tag = game:GetService("HttpService"):GenerateGUID(false)
			projectileServerSignal(currentShootAnim,"Impact Web",tag)
			projectileWeb(impactAnims[currentShootAnim],"Impact Web",tag)
			currentShootAnim += 1
			if (currentShootAnim > 2) then
				currentShootAnim = 1
			end	
		end
	end,
	["Snare Web"] = function()
		if (tick() - ticks.snareTick >= cooldowns["Snare Web"]) then
			ticks.snareTick = tick()
			local tag = game:GetService("HttpService"):GenerateGUID(false)
			projectileServerSignal(currentShootAnim,"Snare Web",tag)
			projectileWeb(snareAnims[currentShootAnim],"Snare Web",tag)
			currentShootAnim += 1
			if (currentShootAnim > 2) then
				currentShootAnim = 1
			end
		end
	end,
	["Shotgun Webs"] = function()
		if (tick() - ticks.shotgunTick >= cooldowns["Shotgun Webs"]) then
			ticks.shotgunTick = tick()
			local tags = {
				[1] = game:GetService("HttpService"):GenerateGUID(false),
				[2] = game:GetService("HttpService"):GenerateGUID(false),
				[3] = game:GetService("HttpService"):GenerateGUID(false)
			}
			projectileServerSignal(currentShootAnim,"Shotgun Webs",tags)
			for i = 1,3 do
				projectileWeb(impactAnims[currentShootAnim],"Shotgun Webs",tags[i])	
			end
			currentShootAnim += 1
			if (currentShootAnim > 2) then
				currentShootAnim = 1
			end
		end
	end,
	["Trip Web"] = function()
		if (tick() - ticks.tripTick >= cooldowns["Trip Web"]) then
			ticks.tripTick = tick()
			local trip_web_max_amt, trip_web_current_amt = TripWebInfo()
			local character = player.Character
			if character and character.PrimaryPart then
				_G.playAbilitySound(character,"travel")
				tripWeb(trip_web_max_amt, trip_web_current_amt)				
			end
		end		
	end,
	["Web Bomb"] = function()
		if (tick() - ticks.webBombTick >= cooldowns["Web Bomb"]) then
			ticks.webBombTick = tick()
			local character = player.Character
			if character and character.PrimaryPart then
				_G.playAbilitySound(character,"throw")
				webBomb()				
			end
		end
	end,
	["Anti Gravity"] = function()
		if (tick() - ticks.antiGravityBombTick >= cooldowns["Anti Gravity"]) then
			ticks.antiGravityBombTick = tick()
			local character = player.Character
			if character and character.PrimaryPart then
				_G.playAbilitySound(character,"throw")
				antiGravityBomb()				
			end
		end
	end,
	["Spider Drone"] = function()
		if (tick() - ticks.spiderDroneTick >= cooldowns["Spider Drone"]) then 
			ticks.spiderDroneTick = tick()
			local character = player.Character
			if character and character.PrimaryPart then
				_G.playAbilitySound(character,"throw")
				spiderDrone()				
			end
		end
	end,
	["Gauntlet"] = function()
		if (tick() - ticks.gauntletTick >= cooldowns["Gauntlet"]) then 
			ticks.gauntletTick = tick()
			if not player.Character or not player.Character.PrimaryPart then return end
			local timer=GauntletSnap(player)
			Gauntlet(player.Name,timer,player.Character.PrimaryPart.Position)
		end		
	end,
}

local function setAllSlotCooldownsWithAbilityName(abilityName,timer)
	for _,slot in (hotbarUI:WaitForChild("container"):GetChildren()) do 
		if slot:IsA("Frame") then
			local cooldown = slot:WaitForChild("cooldown")
			local cooldownTimer = slot:WaitForChild("cooldownTimer")
			local name = slot:WaitForChild("name")
			if name.Value == abilityName then
				cooldownTimer.Value = timer
				cooldown.Value = true
			end
		end
	end
end

local function round(n)
	return math.floor(n * 100) / 100
end

for _,slot in (hotbarUI:WaitForChild("container"):GetChildren()) do 
	if slot:IsA("Frame") then
		local cooldown = slot:WaitForChild("cooldown")
		local ability=slot:WaitForChild("name")
		cooldown:GetPropertyChangedSignal("Value"):Connect(function()
			if cooldown.Value then
				slot:WaitForChild("slot"):WaitForChild("counter").Visible = true
				slot:WaitForChild("slot"):WaitForChild("icon").ImageTransparency = 0.5
				slot:WaitForChild("slot").ImageTransparency = 0.5
			else 
				slot:WaitForChild("slot"):WaitForChild("counter").Visible = false
				slot:WaitForChild("slot"):WaitForChild("icon").ImageTransparency = 0
				slot:WaitForChild("slot").ImageTransparency = ability.Value=="" and .5 or 0
			end
		end)
	end
end

local function ownsAbility(ability)
	local abilities = abilities:GetDescendants()
	for i,v in (abilities) do 
		if v.Name == ability then
			return v.Unlocked.Value
		end	
	end
	return nil
end

local function ActionButtonChanged()
	if selected.Value==0 then return end
	if ActionButtonDown.Value then -- perform action
		local slot = hotbarUI:WaitForChild("container"):FindFirstChild(tostring(selected.Value))
		local cooldown = slot:WaitForChild("cooldown").Value
		local ability = slot:WaitForChild("name").Value
		local sprinting = false
		local isAlive = true
		
		local character = player.Character
		if not character or not character.PrimaryPart then return end
		local humanoid = character:WaitForChild("Humanoid")
		isAlive = humanoid.Health > 0
		
		if isSprinting.Value then
			sprinting = humanoid.MoveDirection.Magnitude > 0
		end
		local ragdolled = cs:HasTag(character,"ragdolled")

		local pageOpen = game:GetService("Lighting"):WaitForChild("Blur").Enabled
		local canPerform = 
			isSwimming.Value == false 
			and isClimbing.Value == false
			and isChargeJumping.Value == false
			--and sprinting == false 
			and isAlive 
			and cooldown == false 
			and pageOpen == false
			and not ragdolled
			and isRolling.Value == false
		local unlocked = ownsAbility(ability)
		--print(canPerform, unlocked)
		if canPerform and unlocked then
			--print("running")
			setAllSlotCooldownsWithAbilityName(ability,tick())
			f[ability]()
		end
	end
end

ActionButtonDown:GetPropertyChangedSignal("Value"):Connect(ActionButtonChanged)

local idleAnim = animsFolder:WaitForChild("idle"):WaitForChild("fight_idle")
local idlePlaying = false
local defaultIdleAnims = {}

local prevCharacter = nil
local moveDirectionChangedEvent = nil
local stateChangedEvent = nil

local function stopIdle(humanoid)
	for key,track in (humanoid:GetPlayingAnimationTracks()) do
		if track.Animation == idleAnim or track.Animation.Parent==nil then
			track:Stop()
		end
	end
	idlePlaying = false
end

local function playIdle(humanoid)
	stopIdle(humanoid)
	local anim = humanoid:LoadAnimation(idleAnim)
	anim:Play()
	idlePlaying = true
end

local function moveDirectionChanged()
	local character = player.Character
	if character and character.PrimaryPart then
		local humanoid = character:WaitForChild("Humanoid")
		local canIdle = isClimbing.Value == false and isSwimming.Value == false
		if humanoid:GetState() == Enum.HumanoidStateType.Running and canIdle then
			if humanoid.MoveDirection.Magnitude ~= 0 then -- stop the animation
				stopIdle(humanoid)
			else
				playIdle(humanoid)
			end
		end
	end
end

local function stateChanged(oldState,newSate)
	local character = player.Character
	if character and character.PrimaryPart then
		local humanoid = character:WaitForChild("Humanoid")
		if newSate ~= Enum.HumanoidStateType.Running then
			stopIdle(humanoid)
		else 
			if selected.Value ~= 0 and humanoid.MoveDirection.Magnitude == 0 then
				playIdle(humanoid)
			end
		end
	end
end

local Equippables={
	["Anti Gravity"]=true,
	["Web Bomb"]=true,
	["Spider Drone"]=true,
	["Gauntlet"]=true
}

local indicateWebBomb = false
local function selectedChanged()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	if (prevCharacter ~= character) then -- new character
		prevCharacter = character
		if moveDirectionChangedEvent ~= nil then
			moveDirectionChangedEvent:Disconnect()
		end
		moveDirectionChangedEvent = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(moveDirectionChanged)

		if stateChangedEvent ~= nil then
			stateChangedEvent:Disconnect()
		end
		stateChangedEvent = humanoid.StateChanged:Connect(stateChanged)
	end
	if selected.Value ~= 0 then
		if selected.Value==prevSelected then return end -- don't allow unnecessary repeats
		local new_slot = hotbarUI:WaitForChild("container"):FindFirstChild(tostring(selected.Value))
		local new_ability = new_slot:WaitForChild("name").Value
		local new_ability_category=new_slot:WaitForChild("category").Value
		--print("selected wasn't 0")
		actionRemote:FireServer("equip",new_ability,new_ability_category,true)
		if (prevSelected == 0) then			
			if moveDirectionChangedEvent == nil then
				moveDirectionChangedEvent = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(moveDirectionChanged)
			end
			if stateChangedEvent == nil then
				stateChangedEvent = humanoid.StateChanged:Connect(stateChanged)
			end
			if (humanoid.MoveDirection.Magnitude == 0) and (humanoid:GetState() == Enum.HumanoidStateType.Running) then
				playIdle(humanoid)
			end
		end
	else
		stopIdle(humanoid)
		if moveDirectionChangedEvent ~= nil then
			moveDirectionChangedEvent:Disconnect()
			moveDirectionChangedEvent = nil
		end
		if stateChangedEvent ~= nil then
			stateChangedEvent:Disconnect()
			stateChangedEvent = nil
		end
		if prevSelected ~= 0 then 
			local old_slot = hotbarUI:WaitForChild("container"):FindFirstChild(tostring(prevSelected))
			local prev_ability = old_slot:WaitForChild("name").Value
			local prev_ability_category=old_slot:WaitForChild("category").Value
			--print("prevSelected wasn't 0")
			actionRemote:FireServer("equip",prev_ability,prev_ability_category,false)
		end
	end
	prevSelected = selected.Value
end

player.CharacterAdded:Connect(selectedChanged)
selected:GetPropertyChangedSignal("Value"):Connect(selectedChanged)

isSwimming:GetPropertyChangedSignal("Value"):Connect(function()
	if (isSwimming.Value) then
		local character = player.Character
		if character and character.PrimaryPart then
			local humanoid = character:WaitForChild("Humanoid")	
			stopIdle(humanoid)	
		end	
	else 
		if (selected.Value ~= 0) then
			local character = player.Character
			if character and character.PrimaryPart then
				local humanoid = character:WaitForChild("Humanoid")	
				playIdle(humanoid)	
			end	
		end
	end
end)

isClimbing:GetPropertyChangedSignal("Value"):Connect(function()
	if (isClimbing.Value) then
		local character = player.Character
		if character and character.PrimaryPart then
			local humanoid = character:WaitForChild("Humanoid")	
			stopIdle(humanoid)	
		end	
	else
		if (selected.Value ~= 0) then
			local character = player.Character
			if character and character.PrimaryPart then
				local humanoid = character:WaitForChild("Humanoid")	
				playIdle(humanoid)	
			end	
		end
	end
end)

local function returnCombatAnimPlaying(humanoid)
	local anims=  humanoid:GetPlayingAnimationTracks()
	local foundAnimationPlaying = false
	local tracks = {}
	for index,track in (anims) do 
		local parent = track.Animation.Parent
		if parent ~= nil then
			if parent:IsDescendantOf(rs:WaitForChild("animations"):WaitForChild("combat")) then
				--print(track.TimePosition/track.Length)
				tracks[#tracks+1] = track.TimePosition/track.Length 
			end				
		end
	end
	local function least(a,b)
		return a < b
	end
	table.sort(tracks,least)
	return tracks[1]
end

local function get_sprint_anim(humanoid)
	for _,track in humanoid:GetPlayingAnimationTracks() do 
		if track.Animation.Name=="Sprint" then
			return track
		end
	end
	return nil
end

local function stop_sprint(humanoid)
	local track=get_sprint_anim(humanoid)
	if track then 
		track:Stop() 
	end
end

local sprintAnim = movementAnims:WaitForChild("Sprint")
local sprintAnimTrack = nil

isSprinting:GetPropertyChangedSignal("Value"):Connect(function()
	--print("changed")
	local character = player.Character
	local humanoid = character:WaitForChild("Humanoid")
	if not isSprinting.Value then 
		stop_sprint(humanoid)
		sprintAnimTrack=nil
		return 
	end
	if character and character.PrimaryPart then
		local isDead = not (humanoid.Health > 0)
		local isRagdolled = cs:HasTag(character,"ragdolled")
		local canContinue = not isDead and not isRagdolled
		if not canContinue then --[[print(isDead,isRagdolled)]] return end
	else
		--print("else, return")
		return
	end
	sprintAnimTrack = nil
	--humanoid.JumpHeight=0
	humanoid.WalkSpeed = 32
	while isSprinting.Value and character and character.PrimaryPart do
		--	print("sprinting")
		local root = character:WaitForChild("HumanoidRootPart")
		if (humanoid.MoveDirection.Magnitude > 0) then -- means you're moving
			if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then -- stops disabling hotbar while dead
				--[[
				if not _G.deathScreen then
					repeat task.wait(1/30) until _G.deathScreen
				end
				_G.deathScreen(true)
				]]
			end
			if humanoid:GetState() == Enum.HumanoidStateType.Running then
				if not get_sprint_anim(humanoid) then
					if not isSwimming.Value and not isClimbing.Value then
						sprintAnimTrack = humanoid:LoadAnimation(sprintAnim)
						if (returnCombatAnimPlaying(humanoid)) then
							while true do
								local animTimePosition = returnCombatAnimPlaying(humanoid)
								if (animTimePosition) then
									if animTimePosition >= .75 then
										break
									end
								else 
									break
								end
								task.wait(1/30)
							end 
						end
						if (sprintAnimTrack) then
							local speed = root.Velocity * Vector3.new(1,0,1) -- ignore y speed
							sprintAnimTrack:Play(0.1,1,math.clamp(speed.Magnitude/21.33333333333333,0,1.5))
						end
					end
				end
			else
				if (sprintAnimTrack) then
					sprintAnimTrack:Stop()
					sprintAnimTrack = nil
				end
			end
			if (sprintAnimTrack) then
				sprintAnimTrack:AdjustSpeed(math.clamp(root.Velocity.Magnitude/21.33333333333333,0,1.5))
			end
		else
			--[[
			if not _G.deathScreen then
				repeat task.wait(1/30) until _G.deathScreen
			end
			local isDead = not (character:WaitForChild("Humanoid").Health > 0)
			local isRagdolled = cs:HasTag(character,"ragdolled")
			if not isDead and not isRagdolled then
				_G.deathScreen(false)
			end
			]]
			if (sprintAnimTrack) then
				--print("stopped track")
				sprintAnimTrack:Stop()
				sprintAnimTrack = nil
			end
		end
		task.wait(1/30)
	end
	humanoid.WalkSpeed = 16
	--humanoid.JumpHeight=0
	if not _G.deathScreen then
		--repeat task.wait(1/30) until _G.deathScreen
	end
	local isDead = not (humanoid.Health > 0)
	local isRagdolled = cs:HasTag(character,"ragdolled")
	if not isDead and not isRagdolled then
		--_G.deathScreen(false)
	end
	if (sprintAnimTrack) then
		sprintAnimTrack:Stop()
		sprintAnimTrack = nil
	end
end)

local removingProjectiles = {} -- makes sure they reach their end target and does 1 last ray check.

local impactSize = Vector3.new(4, 4, .5)

local function closestPointOnPart(part, point)
	local Transform = part.CFrame:pointToObjectSpace(point) -- Transform into local space
	local HalfSize = part.Size * 0.5
	return part.CFrame * Vector3.new( -- Clamp & transform into world space
		math.clamp(Transform.x, -HalfSize.x, HalfSize.x),
		math.clamp(Transform.y, -HalfSize.y, HalfSize.y),
		math.clamp(Transform.z, -HalfSize.z, HalfSize.z)
	)
end

local function raycastWithWhitelist(origin,direction,whitelist)
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

local function webProjectileHit(value,result,wasAttackable)
	if not wasAttackable then
		local impact = rs:WaitForChild("AttachWeb"):Clone()
		--local attachment = impact:WaitForChild("Attachment"):Clone()
		local is2099=isPlayer2099(value.plrName)
		ts:Create(impact,sizeTween,{Size = impactSize}):Play()
		impact.Transparency = 0
		impact.Color=is2099 and is2099.color or Color3.fromRGB(255,255,255)
		impact.Material=is2099 and is2099.material or Enum.Material.Plastic
		impact.CFrame = CFrame.new(result.Position, result.Position - result.Normal) * CFrame.new(0,0,impactSize.Z/2)
		impact.weld.Part0 = impact
		impact.weld.Part1 = result.Instance
		impact.Parent = workspace:WaitForChild("Impacts")
		impact.Sound.PlaybackSpeed = _math.defined(1,1.1)
		impact.Sound:Play()
		game:GetService("Debris"):AddItem(impact,1)
		--attachment.Name = "projectileHit"
		--attachment.Position = pos
		--attachment.Parent = workspace.Terrain
		--attachment.Sound.PlaybackSpeed = _math.defined(1,1.1)
		--attachment.Sound:Play()
		--game:GetService("Debris"):AddItem(attachment,1)
	end

	value.hit = true
	value.finish = true

	local f=coroutine.wrap(function()
		local nearby=Get_Nearby_Civilians(result.Position,"Ranged",value.category)
		Danger_Event:FireServer("Ranged",value.category,value.bullet.Name,result.Position,nearby)
	end)
	f()
end

local function getPartsInBoundingBox(cframe,size,ignore)
	local overlapParams = OverlapParams.new()
	overlapParams.MaxParts = 25
	--overlapParams.CollisionGroup = "Characters"
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = ignore
	overlapParams.BruteForceAllSlow = false
	local partsInBox = workspace:GetPartBoundsInBox(
		cframe,
		size,
		overlapParams
	)

	return partsInBox
end

local function dealRangedDamage(level, misc, bulletName, model, category, origin)
	actionRemote:FireServer("Ranged", "hit", bulletName, model, category)
	--local damage = _math.getStat(level,misc.base,misc.multiplier)
	local crit = rngs[category].rng:NextNumber(0,100)
	local damage=combo(items["Ranged"][category].misc[1],abilities["Ranged"][category].Level.Value)
	--print(category," crit = ",crit)
	damage,crit = getNewDamageWithCritical(damage,crit)
	local properties = model:FindFirstChild("Properties")
	local remaining=0
	if properties then
		local health = properties.Health
		local maxHealth = properties.MaxHealth
		remaining = health.Value - damage < 0 and health.Value or damage
	else -- its a player 
		local char = game.Players:GetPlayerFromCharacter(model)
		if char then
			local health = model.Humanoid.Health
			remaining = health - damage < 0 and health or damage
			remaining = math.clamp(remaining,0,model.Humanoid.MaxHealth)
		end
	end
	local isVillain=model:IsDescendantOf(villains)
	if isVillain then
		model=model:WaitForChild("Body")
	end
	hitMarker(model, remaining, crit, category, "Ranged", origin)
end

local ignore_list={}
ignore_list.impacts=workspace:WaitForChild("Impacts")
ignore_list.projectiles=workspace:WaitForChild("Projectiles")
ignore_list.tripWebs=workspace:WaitForChild("TripWebs")
ignore_list.bullets=workspace:WaitForChild("Bullets")
ignore_list.droneBullets=workspace:WaitForChild("SpiderDroneBullets")
ignore_list.drops=workspace:WaitForChild("Drops")
ignore_list.buildings=workspace:WaitForChild("Buildings")

local function renderProjectiles()
	for index,value in (renderedProjectiles) do 
		value.iteration+=1

		local vars={
			p=math.clamp((tick() - value.startTick) / .2,0,1),
			sine=nil,
			newEndCF=nil,
			revolutions_per_second=.025,
			roation=nil
		}
		value.bullet.Size = Vector3.new(0,0,0):Lerp(value.size,vars.p)

		vars.p = math.clamp((tick() - value.startTick) / value.timer,0,1)
		vars.sine = math.sin((0.5 - vars.p)*(math.pi * (.25)))*vars.p
		vars.sine=math.clamp(vars.sine,-1,0)
		vars.newEndCF = (value.endCF * CFrame.new(0,(vars.sine*value.drop)/2,0))
		vars.rotation=CFrame.fromOrientation(0,0,-((360*vars.revolutions_per_second)*value.timer)*vars.p)
		value.bullet.CFrame = CFrame.new(value.startCF:Lerp(vars.newEndCF,vars.p).Position,vars.newEndCF.Position)*vars.rotation

		if (value.iteration % 2 == 0) then
			vars.realCurrentCF = value.bullet.CFrame * CFrame.new(0,0,-value.bullet.Size.Z/2)
			vars.currentDistanceFromOrigin = (vars.realCurrentCF.Position - value.lastRayCF.Position).Magnitude

			local plr = game.Players:FindFirstChild(value.plrName)
			if not plr then
				value.bullet.Transparency = 1
				value.bullet:Destroy()
				value.impactTick = tick()
				--removingProjectiles[#removingProjectiles+1] = renderedProjectiles[index]
				table.remove(renderedProjectiles,index)
				continue
			end

			vars.origin = value.lastRayCF.Position
			vars.target = vars.realCurrentCF.Position
			vars.direction = (vars.target - vars.origin).Unit * vars.currentDistanceFromOrigin
			ignore_list.ignore = plr ~= nil and plr.Character or nil
			vars.drone = plr~=nil and workspace:WaitForChild("SpiderDrones"):FindFirstChild(plr.Name) or nil
			ignore_list.ignore2 = (plr ~= nil and plr == player and vars.drone) and vars.drone or nil
			ignore_list.ignore3 = (plr~=nil and plr.Character) and plr.Character:FindFirstChild("SpiderLegs") or nil
			vars.impactProjectile = value.bullet.MeshId == "rbxassetid://8175165745"

			vars.cf = CFrame.new(vars.origin:Lerp(vars.target,.5),vars.target)
			vars.distance = (vars.origin-vars.target).Magnitude
			vars.size = value.size

			vars.attackableFound = nil
			vars.partFound = nil
			vars.ignore={}

			for i,v in ignore_list do
				vars.ignore[#vars.ignore+1]=v
			end
			
			for _,part in getVillainsIgnoreArray() do -- ignore the villain greybox 
				vars.ignore[#vars.ignore+1]=part
			end
			
			vars.parts = getPartsInBoundingBox(vars.cf,vars.size,vars.ignore)
			vars.sorted = {}
			if #vars.parts > 0 then
				for _,part in (vars.parts) do 
					vars.closestPoint = closestPointOnPart(part,vars.target)
					vars.sorted[#vars.sorted+1] = {
						[1] = (part.Position - vars.origin).Magnitude,
						[2] = part
					}
				end
				table.sort(vars.sorted,_math.least)

				for i = 1,#vars.sorted do 
					vars.part = vars.sorted[i][2]
					--print("part found=",vars.part.Name)
					vars.humanoid = vars.part.Parent:FindFirstChild("Humanoid") or vars.part.Parent.Parent:FindFirstChild("Humanoid")
					vars.properties = vars.part.Parent:FindFirstChild("Properties") or vars.part.Parent.Parent:FindFirstChild("Properties")
					local thug_or_villain=vars.humanoid and (vars.humanoid:IsDescendantOf(villains) or vars.humanoid:IsDescendantOf(thugs))
					if vars.humanoid and not thug_or_villain then -- this can't be your character
						--print("found humanoid")
						if not vars.attackableFound then
							vars.attackableFound = {
								model = vars.humanoid.Parent,
								part = vars.part
							}
						end
					elseif vars.properties then 
						if not vars.attackableFound then
							vars.attackableFound = {
								model = vars.properties.Parent,
								part = vars.part
							}
						end
					else
						if not vars.partFound then
							vars.partFound = vars.part
						end
					end
				end

				if vars.attackableFound then
					--print("attackable found=",vars.attackableFound.model.Name)
					value.bullet.Transparency = 1
					vars.model = vars.attackableFound.model
					vars.start = value.startCF.Position
					--local closestPoint = closestPointOnPart(attackableFound.part,target)
					vars.result = raycastWithWhitelist(vars.start,(vars.attackableFound.part.Position - vars.start).Unit * 300,{vars.attackableFound.part})
					if vars.result then	
						--print("ray hit!")
						webProjectileHit(value,vars.result,vars.attackableFound~=nil)
					else 
						--print("ray didn't hit!")
						value.hit = true
						value.finish = true						
					end	
					if plr == player then -- for this portion, make sure its your player
						vars.category = value.category
						vars.level = abilities:WaitForChild("Ranged"):WaitForChild(vars.category):WaitForChild("Level").Value
						vars.misc = items.Ranged[vars.category].misc[1]
						vars.f = coroutine.wrap(dealRangedDamage)
						vars.f(vars.level,vars.misc,value.bullet.Name,vars.model,vars.category,value.startCF.Position)					
					end
				end

				if not vars.attackableFound then 
					--print("no attackables found")	
					if vars.partFound then
						--print(partFound," found!")
						vars.start = value.startCF.Position
						vars.closestPoint = closestPointOnPart(vars.partFound,vars.target)
						vars.result = raycastWithWhitelist(vars.start,(vars.closestPoint - vars.start).Unit * 300,{vars.partFound})

						if vars.result then
							--print("result found")
							value.bullet.Transparency = 1
							webProjectileHit(value,vars.result,vars.attackableFound~=nil)
						else 
							vars.attackableFound = nil
							vars.partFound = nil
						end
					end
				end				
			end

			value.lastRayCF = value.bullet.CFrame * CFrame.new(0,0,value.bullet.Size.Z/2)
		end
		if (value.finish == true) or vars.p == 1 then
			value.bullet.Transparency = 1
			value.bullet:Destroy()
			value.impactTick = tick()
			--removingProjectiles[#removingProjectiles+1] = renderedProjectiles[index]
			table.remove(renderedProjectiles,index)
		end
	end
end

runService.RenderStepped:Connect(function()
	runningLoopForRenderingWebs()
	renderProjectiles()
end)