local NPCs = require(script.Parent.NPCs)
local replicatedStorage = game:GetService("ReplicatedStorage")
local thugs = replicatedStorage.thugs
local thugRemoteEvents = thugs.RemoteEvents
local physicalZones = replicatedStorage.Zones
local httpService = game:GetService("HttpService")

local ragdoll = require(replicatedStorage.ragdoll)

local physicsService = game:GetService("PhysicsService")

local _math = require(replicatedStorage.math)

local virtualZones = {
	[1] = {}, -- these are dictionaries with setup: tag,
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	[6] = {},
	[7]= {}
}

local function setNetworkOwnerThug(thug, networkOwner)
	for _, descendant in pairs(thug:GetDescendants()) do
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

local ignoreNames = {
	["RightBaton"] = true,
	["LeftBaton"] = true,
	["LeftGlove"] = true,
	["RightGlove"] = true,
	["Box"] = true
}

local function setCollisionsThug(thug)
	for index,part in pairs(thug:GetDescendants()) do 
		if part:IsA("BasePart") then
			if ignoreNames[part.Name] or part.Parent:IsA("Tool") then
				part.CollisionGroup="Ghost"
			else 
				if part.Name == "Sphere" then
					part.CollisionGroup="Spheres"
				else 
					part.CollisionGroup="Thugs"
				end
			end
		end
	end
end

local ServerStorage = game:GetService("ServerStorage")

local function random1orN(n)
	return (math.round(_math.defined(1,100))%n)+1
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

local function least(a,b)
	return a[1] < b[1]
end

local thug_types = {
	[1] = {0.25,"brute"}, -- 0.5
	[2] = {0.5,"electric"}, -- 1
	[3] = {1.25,"flamethrower"}, -- 2.5
	[4] = {3,"shotgun"}, -- 6
	[5] = {10,"ak"}, -- 20
	[6] = {85,"bat"} --70
}

local thug_zones={
	[1]="bat",
	[2]="ak",
	[6]="shotgun",
	[5]="flamethrower",
	[4]="electric",
	[3]="brute",
	[7]="minigun"
}

local function Get_Random(array)
	local n = _math.defined(0,100)
	table.sort(array,least)
	local total = 0
	for index,value in pairs(array) do
		local percent=value[1]+total
		total=percent
		if n <= percent then
			return value[2]
		end
	end
end

local function addHatsToThug(thug,thugType)
	local hatFolder = thugs.hats[thugType]
	for i,v in pairs(hatFolder:GetChildren()) do 
		local clone = v:Clone()
		clone.Parent = thug
	end
end

local weapons = {
	["bat"] = thugs.weapons.Bat,
	["ak"] = thugs.weapons["AK-47"],
	["shotgun"] = thugs.weapons.Shotgun,
	["flamethrower"] = thugs.weapons.Flamethrower,
	["minigun"]=thugs.weapons.Minigun
}

local function addWeaponToThug(thug,thugType)
	if thugType == "brute" then
		local leftGlove = thug.LeftGlove
		leftGlove.Transparency = 0
		local rightGlove = thug.RightGlove
		rightGlove.Transparency = 0
		thug.RightHand.Transparency = 1
		thug.LeftHand.Transparency = 1
	elseif thugType == "electric" then
		local leftBaton = thug.LeftBaton
		leftBaton.Transparency = 0
		local rightBaton = thug.RightBaton
		rightBaton.Transparency = 0
	else
		local weapon = weapons[thugType]
		local cloneTool = weapon:Clone()
		if cloneTool.Name=="Minigun" then -- it's the minigun
			cloneTool:SetPrimaryPartCFrame(thug.RightHand.CFrame*cloneTool.Offset.Value)
			local weld=cloneTool.PrimaryPart.WeldConstraint
			weld.Part0=thug.RightHand
			weld.Part1=cloneTool.PrimaryPart
			cloneTool.Parent = thug
		else
			cloneTool.Parent = thug
			thug.Humanoid:EquipTool(cloneTool)
		end
	end
end

local function addClothesToThug(thug,thugType)
	local folder = thugs.clothes[thugType]
	for i,clothing in pairs(folder:GetChildren()) do 
		local clone = clothing:Clone()
		clone.Parent = thug
	end
end

local healths = {
	["bat"] = 50,--100,
	["ak"] = 100,--200,
	["shotgun"] = 200,--400,
	["flamethrower"] = 400,--800,
	["electric"] = 800,--1600,
	["brute"] = 1600,--3200,
	["minigun"] = 3200
}

local function changeHipHeight(thug)
	local newHeight = (thug:GetExtentsSize().Y - thug.HumanoidRootPart.Size.Y) - (thug.HumanoidRootPart.Size.Y / 2) 
	thug.Humanoid.HipHeight = newHeight
end

-- did the code on the command line

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
	--print("changed rig size!")
end

local function clear(dict)
	for i,v in dict do 
		v=nil
		dict[i]=nil
	end
end

local function addThug(tag,zoneNumber,elementNumber,attachment)
	--print("added thug to zone ", zoneNumber)
	local _type=thug_zones[zoneNumber]
	virtualZones[zoneNumber][elementNumber] = tag
	local thug = thugs.Thug:Clone()
	thug.Name = tag
	thug:SetPrimaryPartCFrame(CFrame.new(attachment.WorldPosition + Vector3.new(0,3,0)))
	thug.PrimaryPart.Anchored = false
	local properties = thug.Properties
	properties.Zone.Value = zoneNumber
	properties.lastAttack.Value = workspace:GetServerTimeNow()
	
	--local _type = Get_Random(thug_types)
	
	if _type == "brute" then
		changeRigSize(thug,1.375,1.375,1.375,1.375)
		changeHipHeight(thug)
	end
	
	properties.Type.Value = _type
	properties.Health.Value = healths[_type]
	properties.MaxHealth.Value = healths[_type]
	
	addHatsToThug(thug,_type)
	addClothesToThug(thug,_type)
	
	local color = thugs.color:FindFirstChild(random1orN(2)).Value
	
	for i,v in pairs(thug:GetChildren()) do 
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			v.Color = color
		end
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = tag
	remote.Parent = thugRemoteEvents

	--local pathfindingModifier = Instance.new("PathfindingModifier")
	--pathfindingModifier.Label = "NPC"
	--pathfindingModifier.Parent = thug.PrimaryPart

	local agentParams = {
		AgentRadius = 4,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 16,
		Costs = {
			BarrelFire = 1,
			Thugs = 1,
			TripWeb = 0,
			drone = 0,
			ignore = math.huge
		},
		
	}

	NPCs[tag] = {
		model = thug,
		--agentRadius = 4,
		--path = SimplePath.new(thug,agentParams),
		thread = false,
		attackers = {},
		lastAttacked = workspace:GetServerTimeNow(),
		lastHeal = workspace:GetServerTimeNow(),
		drone = false,
		attacking = {},
		comparisonChecks = 0,
		clear=clear
	} -- add it to the NPCs list
	--NPCs[tag].path.Visualize = true

	thug.Parent = workspace.Thugs
	addWeaponToThug(thug,_type)
	ragdoll.setupJoints(thug)
	ragdoll.disableStates(thug.Humanoid)
	thug.Humanoid.BreakJointsOnDeath = false
	setNetworkOwnerThug(thug)
	setCollisionsThug(thug)
	addModifiers(thug,"Thugs",true)
	
end

local function getCharactersInZone(characters,zoneName)
	local charactersInsideZone = {}
	for _,character in pairs(characters) do -- check if enemies nearby
		local zonePart = physicalZones:FindFirstChild(zoneName)
		if zonePart then
			local isWithinBounds = _math.checkBounds(zonePart.CFrame,zonePart.Size,character.PrimaryPart.Position)
			if isWithinBounds then
				charactersInsideZone[character.Name] = character
			end
		end
	end
	return charactersInsideZone
end

local function closestToFarthestAttackers(listing,thugPos)
	local newCharTable = {}
	for	plrName,dictionary in pairs(listing.attackers) do
		local player = game.Players:FindFirstChild(plrName)
		if player then
			local validCharacter = player.Character and player.Character:IsDescendantOf(workspace)
			if validCharacter then
				newCharTable[#newCharTable+1] = {
					[1] = (thugPos - player.Character.PrimaryPart.Position).Magnitude,
					[2] = player.Character
				}				
			end
		end
	end
	table.sort(newCharTable,least)
	return newCharTable
end

local function findUnoccupiedAttachment(attachments,occupiedAttachments)
	for i = 1,#attachments do 
		if occupiedAttachments[attachments[i].Name] == nil then
			return attachments[i]
		end
	end
	return nil
end

local function findNearestAttachment(thug,attachments)
	local thugPos = thug.PrimaryPart.Position
	local orderedTable = {}
	for index,attachment in pairs(attachments) do 
		orderedTable[#orderedTable+1] = {
			[1] = (thugPos - attachment.WorldPosition).Magnitude,
			[2] = attachment
		}
	end
	local function least(a,b)
		return a[1] < b[1]
	end
	table.sort(orderedTable,least)
	return orderedTable[1][2]
end

local thugRespawnTime = .5

while true do 
	local characters = {}
	for index,player in pairs(game.Players:GetPlayers()) do 
		if player.Character then
			characters[#characters+1] = player.Character
		end
	end
	for i1 = 1,#virtualZones do
		local charsInZone = getCharactersInZone(characters,i1)
		local physicalZone = physicalZones[i1]
		local attachments = {
			[1] = physicalZone["1"],
			[2] = physicalZone["2"],
			[3] = physicalZone["3"],
			[4] = physicalZone["4"],
			[5] = physicalZone["5"],
			[6] = physicalZone["6"]
		}
		local occupiedAttachments = {}
		local thugsThatNeedToMove = {}
		local addThugs = {}
		for i2 = 1,4 do
			local zone = virtualZones[i1]
			local zoneElement = zone[i2]
			if zoneElement == nil then 
				addThugs[#addThugs+1] = {
					[1] = httpService:GenerateGUID(false),
					[2] = i1,
					[3] = i2
				}
			elseif type(zoneElement) == "number" then -- doesn't exist, this is a respawn time
				if workspace:GetServerTimeNow() - zoneElement >= thugRespawnTime then
					addThugs[#addThugs+1] = {
						[1] = httpService:GenerateGUID(false),
						[2] = i1,
						[3] = i2
					}
				end
			elseif type(zoneElement) == "string" then -- still exists
				if NPCs[zoneElement] ~= nil then -- still alive, there is still a listing in the NPCs module.
					local physicalThug = workspace.Thugs:FindFirstChild(zoneElement)
					if physicalThug then
						local properties = physicalThug.Properties
						local Target = properties.Target
						local oldTarget = properties.oldTarget
						local moveWait = properties.moveWait
						local moveDelta = properties.moveDelta
						local inZone = properties.inZone
						local health = properties.Health
						local maxhealth = properties.MaxHealth
						local function changeTargetToCharacter(character)
							Target.Value = character
							oldTarget.Value = false
							moveDelta.Value = ""
							moveWait.Value = ""
						end
						local function changeTargetToAttachment()
							oldTarget.Value = true
							moveDelta.Value = workspace:GetServerTimeNow()
							moveWait.Value = math.random(5,10)
							thugsThatNeedToMove[#thugsThatNeedToMove+1] = physicalThug
						end
						local thugIsInZone = _math.checkBounds(physicalZone.CFrame,physicalZone.Size,physicalThug.PrimaryPart.Position)
						if not thugIsInZone then
							--[[
							print(physicalThug.Name," got out of ",physicalZone.Name)
							thugsThatNeedToMove[#thugsThatNeedToMove+1] = physicalThug
							inZone.Value = false
							]]
						end
						if Target.Value ~= nil then
							local orderedCharArray = closestToFarthestAttackers(NPCs[zoneElement],physicalThug.PrimaryPart.Position)
							if not charsInZone[Target.Value.Name] then -- target is not a character in the zone
								local foundCharacter
								if #orderedCharArray > 0 then -- there are characters to chase
									for i = 1,#orderedCharArray do 
										local character = orderedCharArray[i][2]
										if character.Humanoid.Health > 0 and charsInZone[character.Name] then -- make sure character is alive and in the zone
											foundCharacter = character
											break
										end
									end
								end
								if foundCharacter then
									changeTargetToCharacter(foundCharacter)
								else -- there are no characters to chase
									if health.Value < maxhealth.Value and health.Value > 0 then -- this thug has been damaged, but not dead
										local listing = NPCs[zoneElement]
										if workspace:GetServerTimeNow() - listing.lastAttacked > 5 then
											listing.lastHeal=listing.lastHeal~=nil and listing.lastHeal or workspace:GetServerTimeNow()
											if workspace:GetServerTimeNow()-listing.lastHeal>1 then
												local rate=1/100
												local increase=maxhealth.Value*rate
												health.Value=math.clamp(health.Value+increase,0,maxhealth.Value)
												listing.totalDamage=listing.totalDamage~=nil and listing.totalDamage or 0
												for playerName,v in listing.attackers do
													local damage=math.clamp(v.damage,0,listing.totalDamage)
													local subtract=(damage/listing.totalDamage)*increase
													subtract=subtract==subtract and subtract or 0
													v.damage=math.clamp(v.damage-subtract,0,maxhealth.Value)
													if v.damage==0 then
														listing.attackers[playerName]=nil -- remove the listing at 0
													end
												end
												listing.totalDamage=math.clamp(listing.totalDamage-increase,0,maxhealth.Value)
											end
										end
									end
									if moveDelta.Value ~= "" and moveWait.Value ~= "" then -- is an attachment
										if workspace:GetServerTimeNow() - tonumber(moveDelta.Value) >= tonumber(moveWait.Value) then
											occupiedAttachments[Target.Value.Name] = true
											moveDelta.Value = workspace:GetServerTimeNow()
											moveWait.Value = _math.defined(5,10)
											thugsThatNeedToMove[#thugsThatNeedToMove+1] = physicalThug
										else
											occupiedAttachments[Target.Value.Name] = true
										end
									else -- value is a character outside of the zone
										changeTargetToAttachment()				
									end
								end
							else -- target is a character in the zone
								local nearestAttachment = findNearestAttachment(physicalThug,attachments)
								occupiedAttachments[nearestAttachment.Name] = true
								local char = Target.Value
								if char.Parent == nil or not (char.Humanoid.Health > 0) then -- character target is dead or nil.
									local foundAnotherChar = false
									for i = 1,#orderedCharArray do
										local listedChar = orderedCharArray[i][2]
										if listedChar ~= char then
											foundAnotherChar = true
											changeTargetToCharacter(listedChar)
											break
										end
									end
									if not foundAnotherChar then
										changeTargetToAttachment()
									end
								else 
									oldTarget.Value = false
								end
							end
						else -- target is nil
							moveDelta.Value = workspace:GetServerTimeNow()
							moveWait.Value = _math.defined(5,10)
							thugsThatNeedToMove[#thugsThatNeedToMove+1] = physicalThug
						end
					end
				else
					zone[i2] = workspace:GetServerTimeNow()
				end
			end
		end
		local function findAttachmentTarget(properties)
			local attachment = findUnoccupiedAttachment(attachments,occupiedAttachments)
			if attachment ~= nil then
				properties.Target.Value = attachment
				properties.moveDelta.Value = workspace:GetServerTimeNow()
				properties.moveWait.Value = math.random(5,10)
				occupiedAttachments[attachment.Name] = true
			end
		end
		if #thugsThatNeedToMove > 0 then -- set the targets
			for i = 1,#thugsThatNeedToMove do
				local thug = thugsThatNeedToMove[i]
				local properties = thug.Properties
				if properties.inZone.Value == false then -- isn't in zone, tele

				end 
				if properties.Target.Value == nil then
					-- a thug who doesn't have a target
					findAttachmentTarget(properties)
				else
					local isAttachment = properties.Target.Value:IsA("Attachment")
					if isAttachment and occupiedAttachments[properties.Target.Value.Name] then
						-- a thug walking to attachment whos wait time has expired
						findAttachmentTarget(properties)							
					else -- is a character
						if properties.oldTarget.Value then
							-- a thug whos target is a character that left the zone
							findAttachmentTarget(properties)
							properties.oldTarget.Value = false
						end
					end
				end	
			end
		end
		if #addThugs > 0 then 
			for i = 1,#addThugs do 
				local current = addThugs[i]
				local tag = current[1]
				local zoneNumber = current[2]
				local elementNumber = current[3]
				local attachment = findUnoccupiedAttachment(attachments,occupiedAttachments)
				if attachment ~= nil then
					addThug(tag,zoneNumber,elementNumber,attachment)
					occupiedAttachments[attachment.Name] = true		
				end
			end
		end
	end
	wait(.25)
end