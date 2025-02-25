local rs=game:GetService("ReplicatedStorage")
local tutorial_beam=rs:WaitForChild("TutorialBeam")
local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local objectives=leaderstats:WaitForChild("objectives")
local talkedWithPolice=objectives:WaitForChild("talkedWithPolice")
local usedFirstPortal=objectives:WaitForChild("usedFirstPortal")
local current=objectives:WaitForChild("current")

local items=require(rs:WaitForChild("items"))
local _math=require(rs:WaitForChild("math"))

local progressUI=player:WaitForChild("PlayerGui"):WaitForChild("progressUI")
local running=progressUI:WaitForChild("Running")

local function UpdateBeam(start,goal,character)
	if running.Value then return end
	local bodyBeam=character.PrimaryPart:FindFirstChild("TutorialBeam")
	if not bodyBeam then
		bodyBeam=tutorial_beam:Clone()
		bodyBeam.Name="TutorialBeam"
		bodyBeam.Parent=character.PrimaryPart
	end
	local bodyAttachment=character.PrimaryPart:FindFirstChild("TutorialAttachment")
	if not bodyAttachment then
		bodyAttachment=Instance.new("Attachment")
		bodyAttachment.Name="TutorialAttachment"
		bodyAttachment.WorldPosition=start
		bodyAttachment.Parent=character.PrimaryPart
	end
	bodyAttachment.WorldPosition=start
	local trackerAttachment=workspace.Terrain:FindFirstChild("TrackerAttachment")
	if not trackerAttachment then
		trackerAttachment=Instance.new("Attachment")
		trackerAttachment.Name="TrackerAttachment"
		trackerAttachment.WorldPosition=goal
		trackerAttachment.Parent=workspace.Terrain
	end
	trackerAttachment.WorldPosition=goal
	bodyBeam.Attachment0=bodyAttachment
	bodyBeam.Attachment1=trackerAttachment
	
end

local function Delete(character)
	local bodyBeam=character.PrimaryPart:FindFirstChild("TutorialBeam")
	if bodyBeam then bodyBeam:Destroy() end
	local bodyAttachment=character.PrimaryPart:FindFirstChild("TutorialAttachment")
	if bodyAttachment then bodyAttachment:Destroy() end
	local trackerAttachment=workspace.Terrain:FindFirstChild("TrackerAttachment")
	if trackerAttachment then trackerAttachment:Destroy() end
end

local data={
	["bat"]={
		markerPos=Vector3.new(112.256, 2.929, -148.744),
		safePortal=Vector3.new(280.361, 222.577, -285),
		zonePortal=Vector3.new(97.324, 2.5, -148.775),
		zone="1",
		offset=Vector2.new(0,0),
	},
	["ak"]={
		markerPos=Vector3.new(323.256, 2.929, 227.256),
		safePortal=Vector3.new(280.361, 222.577, -273.5),
		zonePortal=Vector3.new(296.675, 2.5, 227.324),
		zone="2",
		offset=Vector2.new(128,0)
	},
	["shotgun"]={
		markerPos=Vector3.new(571.256, 2.929, -150.744),
		safePortal=Vector3.new(280.361, 222.577, -262),
		zonePortal=Vector3.new(557.001, 2.5, -150.6),
		zone="6",
		offset=Vector2.new(256,0)
	},
	["flamethrower"]={
		markerPos=Vector3.new(-347.744, 2.929, 106.256),
		safePortal=Vector3.new(280.361, 222.577, -250.5),
		zonePortal=Vector3.new(-363, 2.5, 106),
		zone="5",
		offset=Vector2.new(0,128)
	},
	["electric"]={
		markerPos=Vector3.new(-88.256, 2.929, -587.744),
		safePortal=Vector3.new(280.361, 222.577, -239),
		zonePortal=Vector3.new(-102.903, 2.5, -587.752),
		zone="4",
		offset=Vector2.new(128,128)
	},
	["brute"]={
		markerPos=Vector3.new(535.256, 2.929, -543.744),
		safePortal=Vector3.new(280.361, 222.577, -227.5),
		zonePortal=Vector3.new(517.25, 2.5, -543.853),
		zone="3",
		offset=Vector2.new(256,128)
	},
	["police"]={
		markerPos=Vector3.new(232, 224.1, -278.5),
		safePortal=nil,
		zonePortal=nil,
		zone="SafeZone",
		offset=Vector2.new(384,0)
	},
	["minigun"]={
		markerPos=Vector3.new(-348.156, 2.929, -239.944),
		safePortal=Vector3.new(280.361, 222.577, -216),
		zonePortal=Vector3.new(-363.575, 2.5, -240.176),
		zone="7",
		offset=Vector2.new(384,128)
	},	
}

lastMarkerName=nil
local function createMarker(name)
	local clone=rs:WaitForChild("trackerPart"):WaitForChild("tracker"):Clone()
	clone.WorldPosition=data[name].markerPos
	clone.Marker.icon.ImageRectOffset=data[name].offset
	clone.Parent=workspace.Terrain
end

local function removeMarker()
	local tracker=workspace.Terrain:FindFirstChild("tracker")
	if tracker then
		tracker:Destroy()
	end
end

local function GetZones()
	local zones=rs:WaitForChild("Zones")
	local safeZone=rs:WaitForChild("SafeZone")
	local t={}
	for i,v in zones:GetChildren() do 
		t[#t+1]=v 
	end
	t[#t+1]=safeZone
	return t
end
local zones=GetZones()

local function GetInsideZone(pos)
	for _,zone in zones do 
		local isInZone=_math.checkBounds(zone.CFrame,zone.Size,pos)
		if isInZone then
			return zone
		end
	end
	return nil
end

--[[
-- new tracking rules:
	if objective doesn't exist, delete beam
	check if you're in a safezone or not
	if you aren't, don't show beam
	if you are:
		if the objective goal isn't in your zone:
			attach beam to portal of the zone you're in
]]

local function FindPortalPosFromZoneName(name)
	for _,data in data do 
		if data.zone==name then
			return data.zonePortal
		end
	end
end

-- only do beam if you're in the spawn area or you need to talk to police again AND you're in a safe zone

local function UpdateTutorialBeam(char)
	local pos=char.PrimaryPart.Position
	local zone=GetInsideZone(pos)
	if not zone then
		Delete(char)
	else 
		local objective=items.objectives[current.Value]
		if not objective or objective.name=="villain" then
			Delete(char)
			return
		end
		if objective.name=="police" then
			if data[objective.name].zone==zone.Name then -- you're in the same zone as the police guy
				local start=char.PrimaryPart.Position
				local goal=data[objective.name].markerPos
				UpdateBeam(start,goal,char)
			else -- you're not in the same zone as the police guy, but in a different zone
				local start=char.PrimaryPart.Position
				local goal=FindPortalPosFromZoneName(zone.Name)
				UpdateBeam(start,goal,char)
			end
		else -- it's a thug objective
			if zone.Name=="SafeZone" then -- you're in the safeZone when your goal is outside the safezone
				local start=char.PrimaryPart.Position
				local goal=data[objective.name].safePortal
				UpdateBeam(start,goal,char)
			else -- you're in a thug zone, but which one?
				Delete(char)
				--[[
				if data[objective.name].zone==zone.Name then -- you're where you're supposed to be, delete beam
					Delete(char)
				else 
					local start=char.PrimaryPart.Position
					local goal=FindPortalPosFromZoneName(zone.Name)
					UpdateBeam(start,goal,char)
				end]]
			end
		end
	end
		--[[
		if not talkedWithPolice.Value then
			-- create attachments and track police position
			CreateNew(character.PrimaryPart.Position,cop_pos,character)
		else 
			if not usedFirstPortal.Value then
				-- make sure attachments exist and track first portal
				CreateNew(character.PrimaryPart.Position,portal_pos,character)
			else 
				-- delete attachments and break
				Delete(character)
				--break
			end
		end]]
end

local villains=workspace:WaitForChild("Villains")

while true do 
	local character=player.Character 
	if character and character.PrimaryPart then
		UpdateTutorialBeam(character)
	end
	
	local objective=items.objectives[objectives:WaitForChild("current").Value]
	if objective~=nil and data[objective.name] then
		if lastMarkerName~=objective.name then
			--print("objective=",objectives:WaitForChild("current").Value)
			lastMarkerName=objective.name
			removeMarker()
			createMarker(objective.name)
		end
	else 
		lastMarkerName=nil
		removeMarker()
	end
	
	local tracker=workspace.Terrain:FindFirstChild("tracker")
	if tracker then
		local marker=tracker:WaitForChild("Marker")
		local d=(workspace.CurrentCamera.CFrame.Position-tracker.WorldPosition).Magnitude
		marker.Enabled = d>=100
		marker:WaitForChild("text").Text = math.round(d)
		if _G.slot_size then
			marker.Size=UDim2.new(0,_G.slot_size,0,_G.slot_size)
			local outlineSize=_G.slot_size*.25
			marker:WaitForChild("text"):WaitForChild("UIStroke").Thickness=outlineSize*.2
		end
	end
	
	local villain=villains:FindFirstChildOfClass("Model")
	if villain and villain.PrimaryPart then
		--print("found villain!")
		local marker = villain:WaitForChild("Marker")
		local camera = workspace.CurrentCamera
		local distance = (camera.CFrame.Position - villain.PrimaryPart.Position).Magnitude
		if distance >= 175 then
			marker.Enabled = true--objectives:WaitForChild("current").Value==#items.objectives -- only enable villain marker if player has the villain objective!
			marker:WaitForChild("icon"):WaitForChild("text").Text = math.round(distance)
			if _G.slot_size then
				marker.Size=UDim2.new(0,_G.slot_size,0,_G.slot_size)
				local outlineSize=_G.slot_size*.25
				marker:WaitForChild("icon"):WaitForChild("text"):WaitForChild("UIStroke").Thickness=outlineSize*.2
			end
		else 
			marker.Enabled = false
		end
	end
	task.wait(1/10)
end