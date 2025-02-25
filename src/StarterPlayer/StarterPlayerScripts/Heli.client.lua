--!nocheck
--// services
local rs=game:GetService("ReplicatedStorage")
local ts=game:GetService("TweenService")
local physicsService=game:GetService("PhysicsService")
--// constants
local serverHeli
local clientHeliStorage=rs:WaitForChild("clientHeli")
local ignoreY=Vector3.new(1,0,1)
local includeY=Vector3.new(0,1,0)
local timeOfDay=script.Parent:WaitForChild("Day_Night"):WaitForChild("TimeOfDay")
local villains=workspace:WaitForChild("Villains")
local buildingBounds=workspace:WaitForChild("BuildingBounds")

local player=game.Players.LocalPlayer

local function adjustcollisions(model)
	for index, part in (model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup="Ghost"
		end
	end
end

local function moveClientHeli(clientHeli:Model, start:Vector3, goal:Vector3, alpha:number)
	if not clientHeli.PrimaryPart then return end
	local horizontalDistance=((start*ignoreY)-(goal*ignoreY)).Magnitude
	if horizontalDistance>=1 then
		local startCF=clientHeli.PrimaryPart.CFrame
		local goalCF=CFrame.new(start*ignoreY,goal*ignoreY)
		local start_x,start_y,start_z=startCF:ToOrientation()
		local goal_x,goal_y,goal_z=goalCF:ToOrientation()
		local adjustedAlpha=math.sin(math.pi*alpha)
		local target=math.deg(goal_y) 
		local current=math.deg(start_y)
		local y=(target-current+540)%360-180
		y=math.rad((y/2)*adjustedAlpha)
		local x=math.rad(math.clamp(horizontalDistance/72,0,1)*-22.5)*adjustedAlpha
		--// whenever the goal changes, it radically changes the trajectory of the heli, 
		--// causing it to "stutter" when moving to a different goal
		clientHeli.PrimaryPart.BodyGyro.CFrame=startCF:Lerp(goalCF,alpha)*CFrame.fromOrientation(x,0,y)
	else
		local x,y,z=clientHeli.PrimaryPart.CFrame:ToOrientation()
		clientHeli.PrimaryPart.BodyGyro.CFrame=CFrame.new(clientHeli.PrimaryPart.Position)*CFrame.fromOrientation(0,y,0)
	end
	clientHeli.PrimaryPart.BodyPosition.Position=start:Lerp(goal,alpha)
end

local function createCrew(heli:Model)
	if not heli.PrimaryPart then return end
	local pilot=heli:FindFirstChild("Pilot")
	local cameraman=heli:FindFirstChild("Cameraman")
	if pilot and cameraman then return end --// don't create crew if already exist
	local anims=heli.Animations

	--// create a pilot
	if not pilot then
		pilot=rs:WaitForChild("Pilot"):Clone()
		pilot.PrimaryPart.CFrame=heli.Pilot_Seat.CFrame
		heli.Pilot_Seat.seat.Part1=pilot.PrimaryPart
		adjustcollisions(pilot)
		pilot.Parent=heli
		pilot.Humanoid.PlatformStand=true
		local pilot_Anim=pilot.Humanoid:LoadAnimation(anims.Crew.Pilot)
		pilot_Anim:Play(.1,1,.25)
	end

	--// create a cameraman
	if not cameraman then
		cameraman=rs:WaitForChild("Cameraman"):Clone()
		cameraman.PrimaryPart.CFrame=heli.Cameraman_Seat.CFrame
		heli.Cameraman_Seat.seat.Part1=cameraman.PrimaryPart
		adjustcollisions(cameraman)
		cameraman.Parent=heli
		cameraman.Humanoid.PlatformStand=true
		local cameraman_Anim=cameraman.Humanoid:LoadAnimation(anims.Crew.Cameraman)
		cameraman_Anim:Play(.1,1,.25)
	end
end

local function removeCrew(heli:Model)
	local cameraman=heli:FindFirstChild("Cameraman")
	if cameraman then
		cameraman:Destroy()
	end
	local pilot=heli:FindFirstChild("Pilot")
	if pilot then 
		pilot:Destroy()
	end
end

local lastAdjustment=nil
local function adjustRotors(heli:Model,alpha:number)
	if not heli or not heli.PrimaryPart then return end
	--print("adjust rotors2")
	local Frame=heli:FindFirstChild("Frame")
	local Main_Textures=heli:FindFirstChild("Main_Rotor_Textures")
	local Tail_Textures=heli:FindFirstChild("Tail_Rotor_Textures")
	local anims=heli.Animations
	local animationController=heli.AnimationController
	local rotor_track=nil
	for _,track in animationController:GetPlayingAnimationTracks() do 
		if track.Animation.Name=="Helicopter_rotors" then
			rotor_track=track
		end
	end
	if not rotor_track then
		rotor_track=animationController:LoadAnimation(anims.Rotors.Helicopter_rotors)
		rotor_track:Play(.1,1,alpha*4)
	end
	rotor_track:AdjustSpeed(alpha*4)
	--print("adjust rotors1")
	if not Frame or not Main_Textures or not Tail_Textures then return end
	--print("adjust rotors3")
	if lastAdjustment==alpha then return end --// don't overwrite same changes
	--print("adjust rotors4")
	lastAdjustment=alpha
	--// purpose: turn the rotors, adjust the sound playbackspeed and texture transparency
	heli.Frame.loop.PlaybackSpeed=alpha*.5
	local main_textures=heli.Main_Rotor_Textures
	main_textures.Top.Transparency=alpha==0 and 1 or 0
	main_textures.Bottom.Transparency=alpha==0 and 1 or 0
	local tail_textures=heli.Tail_Rotor_Textures
	tail_textures.Front.Transparency=alpha==0 and 1 or 0
	tail_textures.Back.Transparency=alpha==0 and 1 or 0
end

local radioDelay=math.random(5,10)
local lastNoise=tick()
local lastPlayed=nil
local function radioChatter(heli:Model)
	if not heli.Frame then return end
	if tick()-lastNoise>=radioDelay then
		lastNoise=tick()
		radioDelay=math.random(5,10)
		local sounds={heli.Frame["1"],heli.Frame["2"],heli.Frame["3"]}
		if lastPlayed then
			table.remove(sounds,lastPlayed)
		end
		local sound=sounds[math.random(1,#sounds)]
		sound:Play()
		lastPlayed=tonumber(sound.Name)
	end
end

local function ray(origin,direction,whitelist)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {whitelist}
	params.FilterType = Enum.RaycastFilterType.Whitelist
	local ray = workspace:Raycast(origin,direction,params)
	return ray
end

local function createNewHeli(serverHeli:Part)
	if not serverHeli then return end
	local clientHeli=rs:WaitForChild("NewsHeli"):Clone()
	clientHeli.Name="clientHeli"
	clientHeli.PrimaryPart.CFrame=serverHeli.CFrame
	clientHeli.PrimaryPart.BodyGyro.CFrame=serverHeli.CFrame
	clientHeli.Parent=workspace
	return clientHeli
end

local function adjustSpotlight(spotlight:Part,goal:Vector3,toggle:boolean)
	if not spotlight then return end
	if goal then
		spotlight.CFrame=CFrame.new(spotlight.Position,goal)
		spotlight["01"].WorldPosition=goal
	end
	spotlight.light.Enabled=toggle
	spotlight["01"].PointLight.Enabled=toggle
end

local function manageClientDistance(clientHeli:Model, serverHeli:BasePart)
	if not clientHeli.PrimaryPart or not serverHeli then return end
	if (clientHeli.PrimaryPart.Position*ignoreY-serverHeli.Position*ignoreY).Magnitude>100 then
		clientHeli.PrimaryPart.BodyPosition.Position=serverHeli.Position
		clientHeli.PrimaryPart.BodyGyro.CFrame=serverHeli.CFrame
		clientHeli:PivotTo(serverHeli.CFrame)
	end
end

local function adjustClientHeli(serverHeli:Part)
	if not serverHeli then return end
	local clientHeli=workspace:FindFirstChild("clientHeli")
	if not clientHeli then
		clientHeli=createNewHeli(serverHeli)
		if not clientHeli then return end -- don't continue the thread if serverHeli doesn't exist
		if not clientHeli.PrimaryPart then return end
	end
	local p=serverHeli.progress.Value
	local heightP=serverHeli.heightP.Value
	local start=serverHeli.current.Value
	local goal=serverHeli.next.Value
	local horizontal=serverHeli.horizontal.Value
	local vertical=serverHeli.vertical.Value
	local action=serverHeli.action.Value

	local spotlightGoal=nil
	local spotlightToggle=false
	if action=="landing" and heightP==1 and p==1 then
		removeCrew(clientHeli)
		adjustRotors(clientHeli,0)
	end
	if action=="takeoff" then
		createCrew(clientHeli)
		adjustRotors(clientHeli,1)
		radioChatter(clientHeli)
	end
	if action=="flying" then
		createCrew(clientHeli)
		adjustRotors(clientHeli,1)
		radioChatter(clientHeli)
		local villain=villains:FindFirstChildOfClass("Model")
		local properties=villain and villain:FindFirstChild("Properties") or nil
		local health=properties and properties:FindFirstChild("Health") or nil
		if villain and properties and health and health.Value>0 then -- there is a live villain
			--print("working")
			--if not clientHeli.PrimaryPart then return end 
			if not villain.PrimaryPart then return end
			local origin=(clientHeli.PrimaryPart.Position*ignoreY)+Vector3.new(0,1.5,0) -- 1.5 studs above ground, where nodes are
			local goal=(villain.PrimaryPart.Position*ignoreY)+Vector3.new(0,1.5,0)
			local distance=(origin-goal).Magnitude
			if distance<=250 then
				local direction=(goal-origin).Unit*distance
				local raycast=ray(origin,direction,{buildingBounds,villains})
				if raycast and raycast.Instance:IsDescendantOf(villains) then
					spotlightGoal=goal
					spotlightToggle=true
				else 
					spotlightGoal=origin
					spotlightToggle=true
				end
			else 
				spotlightGoal=origin
				spotlightToggle=true
			end
		end
	end
	if not clientHeli.Spotlight then return end
	spotlightToggle=timeOfDay.Value=="night" and spotlightToggle or false
	adjustSpotlight(clientHeli.Spotlight,spotlightGoal,spotlightToggle)
	manageClientDistance(clientHeli,serverHeli)
	moveClientHeli(clientHeli,start,goal,horizontal and p or heightP)
end

while true do 
	local serverHeli=workspace:FindFirstChild("serverHeli")
	if serverHeli then
		adjustClientHeli(serverHeli)
	end
	task.wait()
end

		--[[
		local whitelist=workspace:WaitForChild("Train")
		local origin=goal
		local range=(origin-goal).Magnitude
		local direction=(goal-origin).Unit*100
		local result=ray(origin,direction,whitelist)
		if result then
			print(result.Instance.Name)
		end
		]]