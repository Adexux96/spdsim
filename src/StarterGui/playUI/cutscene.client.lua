local player = game.Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local temp = leaderstats:WaitForChild("temp")
local isClimbing = temp:WaitForChild("isClimbing")
local isSwimming = temp:WaitForChild("isSwimming")
local isSprinting = temp:WaitForChild("isSprinting")
local isWebbing=temp:WaitForChild("isWebbing")
local characterLoaded = temp:WaitForChild("characterLoaded")
local character
local playerGui = player:WaitForChild("PlayerGui")
local playerScripts = player:WaitForChild("PlayerScripts")
local rs = game:GetService("ReplicatedStorage")
local _math = require(rs:WaitForChild("math"))
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local blackFrameTweenInfo = TweenInfo.new(.5,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0)
local deathUI = playerGui:WaitForChild("deathUI")
local playUI = script.Parent

local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local interface = require(rs:WaitForChild("interface"))
local ragdoll = require(rs:WaitForChild("ragdoll"))
local OTS_CAM_HDLR = require(rs:WaitForChild("OTS_Camera"))

local camera = workspace.CurrentCamera
local cameras = rs:WaitForChild("cameras")
local sceneTween = TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.In)
local scene = 0
local numScenes = #cameras:GetChildren()
local blackGui = playerGui:WaitForChild("black")
_G.cutscenePlaying = true
_G.firstSpawn = true

local coreCall do
	local MAX_RETRIES = 1000

	local StarterGui = game:GetService('StarterGui')
	local RunService = game:GetService('RunService')

	function coreCall(method, ...)
		local result = {}
		while true do 
			result = {pcall(StarterGui[method], StarterGui, ...)}
			if result[1] then
				break
			end
			--print("running")
			RunService.Stepped:Wait()
		end
		return unpack(result)
	end
end

coreCall('SetCore', 'ResetButtonCallback', false)
--print("break")

local objectiveUI=playerGui:WaitForChild("objectiveUI")

local buttonSound = rs:WaitForChild("ui_sound"):WaitForChild("button")
local suitSound = rs:WaitForChild("ui_sound"):WaitForChild("suit") 

local function findHighestZindex(array)
	local highest = 0
	for i,v in pairs(array) do
		if (v.ZIndex > highest) then
			highest = v.ZIndex 
		end
	end
	return highest
end

local function stopIntro()
	
	--if (timeOfDay.Value == "morning") then

	--elseif (timeOfDay.Value == "night") then

	--end
end

local uis = game:GetService("UserInputService")
local focused_input_position = rs:WaitForChild("focused_input_position")

local cameraTweenInfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0)

local function introScene()
	local camPart = rs:WaitForChild("camPart")
	_G.cutscenePlaying = true
	local fadeIn = tweenService:Create(blackGui.frame,blackFrameTweenInfo,{BackgroundTransparency = 0})
	fadeIn:Play()
	fadeIn.Completed:Wait()
	local fadeOut = tweenService:Create(blackGui.frame,blackFrameTweenInfo,{BackgroundTransparency = 1})
	fadeOut:Play()
	if _G.cutscenePlaying == false then
		return
	end
	--print(yCenter)
	--print(screenSize.Y - topBarHeight)
	-- -up, +down, -left, +right
	local cameraTween=nil
	while true do
		--if cameraTween then
			--cameraTween:Destroy()
			--cameraTween=nil
		--end
		local topLeftCorner,bottomRightCorner= game:GetService("GuiService"):GetGuiInset()
		local topBarHeight = math.abs(topLeftCorner.Y - bottomRightCorner.Y)
		local screenSize = camera.ViewportSize
		local xCenter = math.round(screenSize.X/2)
		local yCenter = math.round(screenSize.Y/2)
		controls:UpdateTouchGuiVisibility()
		local xRange = screenSize.X - xCenter
		local yRange = screenSize.Y - yCenter
		local inputX = focused_input_position.Value.X
		local inputY = focused_input_position.Value.Y + topBarHeight
		if focused_input_position.Value ~= Vector3.new(0,0,0) then
			local xProgress = math.clamp((inputX/xRange)-1,-1,1)
			xProgress = math.round(xProgress*100)/100
			local yProgress = math.clamp((inputY/yRange)-1,-1,1)
			yProgress = math.round(yProgress*100)/100
			local adjustedCF = camPart.CFrame * CFrame.Angles(-math.rad(9 * yProgress),-math.rad(9 * xProgress),0)
			--cameraTween=tweenService:Create(camera,cameraTweenInfo,{CFrame = adjustedCF})
			--cameraTween:Play()
			camera.CFrame=camera.CFrame:Lerp(adjustedCF,.2)
		else 
			--cameraTween=tweenService:Create(camera,cameraTweenInfo,{CFrame = camPart.CFrame})
			--cameraTween:Play()	
			camera.CFrame=camera.CFrame:Lerp(camPart.CFrame,.2)
		end
		if _G.cutscenePlaying == false then 
			controls:UpdateTouchGuiVisibility()
			break 
		end
		runService.RenderStepped:Wait()
	end
end

--[[
local function runScenes()
	_G.cutscenePlaying = true
	scene = 0
	local first = true
	while true do
		if (_G.cutscenePlaying == false) then 
			stopIntro()
			break 
		end
		if (scene == numScenes) then
			scene = 0
		end
		scene = scene + 1
		if (scene == 1) then
			--introMusic:Play()
		end
		if not first then
			local fadeIn = tweenService:Create(blackGui.frame,blackFrameTweenInfo,{BackgroundTransparency = 0})
			fadeIn:Play()
			fadeIn.Completed:Wait()
			if (_G.cutscenePlaying == false) then 
				stopIntro()
				break 
			end -- check again
			camera.CFrame = cameras[scene]:WaitForChild("1").CFrame -- set the camera up
			local fadeOut = tweenService:Create(blackGui.frame,blackFrameTweenInfo,{BackgroundTransparency = 1})
			fadeOut:Play()
		elseif first then
			camera.CFrame = cameras[scene]:WaitForChild("1").CFrame -- set the camera up
			first = false -- not the first time on camera anymore
		end
		local cameraFolder = cameras[scene]
		local cam1,cam2 = cameraFolder:WaitForChild("1"),cameraFolder:WaitForChild("2")
		local startCF = cam1.CFrame
		local goalCF = cam2.CFrame
		local start = tick()
		local allowedTime = 10 
		while (tick() - start < allowedTime) do
			if (_G.cutscenePlaying == false) then 
				stopIntro()
				break 
			end -- check every iteration
			runService.RenderStepped:Wait()
			local percent = (tick() - start)/allowedTime
			camera.CFrame = startCF:Lerp(goalCF,percent)
			camera.Focus = camera.CFrame
		end
	end	
end]]

local reactionAnimations = rs:WaitForChild("animations"):WaitForChild('combat'):WaitForChild("reaction")

local reactionAnims = {
	[1] = reactionAnimations:WaitForChild("1"),
	[2] = reactionAnimations:WaitForChild("2"),
	[3] = reactionAnimations:WaitForChild("3")
}

local physicsService = game:GetService("PhysicsService")

local cs = game:GetService("CollectionService")

local function playerRagdollCollisions(model)
	for index, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CollisionGroup="Ragdoll"
		end
		if part.Name == "HumanoidRootPart" then
			part.CollisionGroup="Characters"
		end
	end
	--print("ghosted ",player.Name)
end

local bloodUI=playerGui:WaitForChild("bloodUI")
local oldHealth = nil
local diedEvent=rs:WaitForChild("DiedEvent")
local function healthChanged()
	local humanoid = character:WaitForChild("Humanoid")
	if oldHealth == nil then
		oldHealth = humanoid.MaxHealth
	end
	local difference = humanoid.Health - oldHealth
	if difference < 0 then
		-- took damage
		local anim = reactionAnims[math.random(1,3)]
		humanoid:LoadAnimation(anim):Play()
	end
	oldHealth = humanoid.Health
	bloodUI:WaitForChild("blood").ImageTransparency=humanoid.Health/humanoid.MaxHealth
	if not (humanoid.Health > 0) then -- you're dead
		--playerRagdollCollisions(humanoid.Parent)
		diedEvent:FireServer(workspace:GetServerTimeNow())
		--print("told server you died")
		OTS_CAM_HDLR.ShutDown()
		player:WaitForChild("LastRootCFrame").Value = CFrame.new(0,0,0)
		--print("you died!")		
		if (_G.cutscenePlaying) then return end -- if you die while picking team, don't do any of this
		_G.firstSpawn = false
		game.Lighting:WaitForChild("colorCorrection").Saturation = -1
		deathUI.Enabled = true
		tweenService:Create(deathUI:WaitForChild("bg"):WaitForChild("inner"),blackFrameTweenInfo,{Size = UDim2.new(1,0,.2,0)}):Play()
	end
end

local function resetCam()
	local function change()
		camera.CameraType = Enum.CameraType.Scriptable
		--camera.CameraType = Enum.CameraType.Custom
		local offsetCFrame = character:WaitForChild("HumanoidRootPart").CFrame*CFrame.new(Vector3.new(0,2.5,10))
		local cframe = CFrame.new(offsetCFrame.Position,character:WaitForChild("Head").Position)
		camera.CFrame = cframe
		camera.CameraType = Enum.CameraType.Custom
	end
	change()
	task.delay(1/30,change)
end

local UserGameSettings = UserSettings():GetService("UserGameSettings")

local function loadImportantAnimations(humanoid)
	if humanoid.Parent.Parent ~= workspace then
		repeat task.wait(1/30) until humanoid.Parent.Parent == workspace
	end
	local animFolder = rs:WaitForChild("animations")
	for i,v in pairs(animFolder:WaitForChild("movement"):GetChildren()) do 
		humanoid:LoadAnimation(v)
	end
	for i,v in pairs(animFolder:WaitForChild("combat"):GetDescendants()) do 
		if (v:IsA("Animation")) then
			humanoid:LoadAnimation(v)
		end
	end
	humanoid:LoadAnimation(animFolder:WaitForChild("idle"):WaitForChild("fight_idle"))
end

local CFrameTweenInfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0)

local respawnEvent = rs:WaitForChild("Respawn")

local controls_reset=playerGui:WaitForChild("controlsUI"):WaitForChild("Reset")

--[[

local t2=workspace.Tentacle2
local armL=t2.TentacleL2["Arm1.L"]
for _,descendant in armL:GetDescendants() do 
	if descendant.Name=="Holder.L" then
		workspace.front.CFrame=descendant.WorldCFrame
	end
end

local t2=workspace.Tentacle2
local armL=t2.TentacleL2["Arm1.L"]

local RightHookSize=Vector3.new(10.866, 5.433, 15.514)
local LeftHookSize=Vector3.new(10.93, 5.465, 15.752)

local cframes={}

for _,descendant in armL:GetDescendants() do 
	if descendant.Name=="Holder.R" or descendant.Name=="Arm7.R" then
		cframes[descendant.Name]=descendant.WorldCFrame
	end
end
cframes["Doc"]=workspace.DocOck2.UpperTorso.CFrame 

local total_position=Vector3.new()
for i,v in cframes do 
	total_position+=v.Position
end

local middle=total_position/3
workspace.front.CFrame=CFrame.new(middle)
local x,y,z=CFrame.new(cframes["Doc"].Position,cframes["Holder.R"].Position):ToOrientation()
workspace.L2.CFrame=CFrame.new(middle)*CFrame.fromOrientation(x,y,z)
local x_size=(cframes["Arm7.R"].Position-workspace.front.Position).Magnitude*2
local y_size=x_size/2
local z_size=(cframes["Doc"].Position-cframes["Holder.R"].Position).Magnitude+4

workspace.L2.Size=Vector3.new(x_size,y_size,z_size)

local start,goal=workspace.Rig.UpperTorso.CFrame,workspace.front.CFrame
local middlePos=start:Lerp(goal,.5).Position 
workspace.L2.CFrame=CFrame.new(middlePos,goal.Position) 
workspace.L2.Size=Vector3.new(5,5,(start.Position-goal.Position).Magnitude)

local offset=workspace.DocOck2.UpperTorso.CFrame:ToObjectSpace(workspace.front.CFrame)
game.ReplicatedStorage.Villains["Doc Ock"].Properties.MovesOffsets.Hooks.LeftHook.Value=offset
]]

local function characterAdded(char)
	--print("character added")
	bloodUI:WaitForChild("blood").ImageTransparency=1
	game:GetService("StarterGui"):SetCore("ResetButtonCallback", true)
	workspace.Gravity = 98.1 -- reset the gravity
	if not _G.deathScreen then
		repeat task.wait(1/30) until _G.deathScreen
	end
	isSprinting.Value = false
	_G.deathScreen(false)
	controls_reset.Value=tick()
	character = char
	local humanoid = character:WaitForChild("Humanoid")
	oldHealth = nil
	loadImportantAnimations(humanoid)
	player.CameraMaxZoomDistance = 7
	player.CameraMinZoomDistance = 7
	game.Lighting:WaitForChild("colorCorrection").Saturation = .35
	deathUI:WaitForChild("bg"):WaitForChild("inner").Size = UDim2.new(0,0,0.2,0) -- reset size
	deathUI.Enabled = false
	
	if not (character.PrimaryPart) then
		repeat task.wait(1/30) until character.PrimaryPart
	end
	
	if (_G.cutscenePlaying) then -- player reset while picking team
		ragdoll.setStatesEnabled(humanoid,false) -- set all states to false
		controls:Disable() -- disable controls		
		return
	end
	
	--local spawns = workspace:WaitForChild("spawns")
	
	local LastRootCFrame = player:WaitForChild("LastRootCFrame")
	local LastCameraCFrame = player:WaitForChild("LastCameraCFrame")
	
	local spawnPoint = rs:WaitForChild("rooftop_spawn2")--player.Name=="Moralty" and rs:WaitForChild("rooftop_spawn") or rs:WaitForChild("rooftop_spawn2")
	
	--camera.CameraSubject = humanoid
	if (LastRootCFrame.Value.Position ~= Vector3.new(0,0,0)) then
		suitSound:Play()
		if (character.PrimaryPart.Position - LastRootCFrame.Value.Position).Magnitude > 5 then
			local tween = tweenService:Create(character.PrimaryPart,CFrameTweenInfo,{CFrame = LastRootCFrame.Value})
			character:SetAttribute("Teleporting",true)
			tween:Play()
			tween.Completed:Wait()			
		end
		camera.CameraSubject = humanoid
		camera.CFrame = LastCameraCFrame.Value
		task.wait(1/30)
		camera.CameraType = Enum.CameraType.Custom
		character:SetAttribute("Teleporting",false)
	else
		--print(">>> TO SPAWN <<<<")
		camera.CameraSubject = humanoid
		character:SetPrimaryPartCFrame(spawnPoint.CFrame + Vector3.new(0,3,0)--[[Vector3.new(math.random(-5,5),3,math.random(-5,5))]])
		resetCam()
	end

	-- enable controls
	--controls:Enable()
	player.CameraMaxZoomDistance = 20 
	player.CameraMinZoomDistance = .5
	humanoid:GetPropertyChangedSignal("Health"):Connect(healthChanged)
	-- fade the black screen away
	local fadeOut = tweenService:Create(blackGui.frame,blackFrameTweenInfo,{BackgroundTransparency = 1})
	fadeOut:Play()
	interface.toggleUI("cutsceneEnd") -- false cause it's not first spawn
	--task.wait(1/30)
	if OTS_CAM_HDLR.isShutDown and not isClimbing.Value and not isSwimming.Value then
		OTS_CAM_HDLR.Reboot()
	end
	characterLoaded.Value = true

	task.wait(1/30)
	character:WaitForChild("Animate").Enabled = true
	character:WaitForChild("Client").Enabled = true
	character:WaitForChild("Reset").Enabled = true
	local spiderLegAnimate = character:FindFirstChild("SpiderLegAnimate")
	if spiderLegAnimate then
		spiderLegAnimate.Enabled = true
	end
	local function respawn()
		respawnEvent:FireServer()
		--print("fired server")
	end
	task.delay(1,respawn)
	controls:Enable()
end

local function firstCharacterAdded(char)
	if not (_G.firstSpawn) then
		characterAdded(char)
		return
	end
	--print("first character")
	game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)
	--print("first character added")
	game.Lighting:WaitForChild("colorCorrection").Saturation = .35
	deathUI:WaitForChild("bg"):WaitForChild("inner").Size = UDim2.new(0,0,0.2,0) -- reset size
	deathUI.Enabled = false
	character = char
	local humanoid = character:WaitForChild("Humanoid")
	loadImportantAnimations(humanoid)
	camera.CameraType = Enum.CameraType.Scriptable
	local dataLoaded = player:WaitForChild("leaderstats"):WaitForChild("temp"):WaitForChild("dataLoaded")
	interface.toggleUI("cutsceneStart") -- true cause it's first spawn
	if not (dataLoaded.Value) then repeat task.wait(1/30) until dataLoaded.Value end
	--audio.introMusic(false) -- play intro music
	playUI.Enabled = true -- Enable the team select screen
	if not (character.PrimaryPart) then
		repeat runService.RenderStepped:Wait() until character.PrimaryPart
	end
	
	character:WaitForChild("HumanoidRootPart").Anchored=true
	
	local spawnPoint=rs:WaitForChild("first_spawn")
	character:SetPrimaryPartCFrame(spawnPoint.CFrame + Vector3.new(math.random(-45,45),3,math.random(-45,45)))
	
	ragdoll.setStatesEnabled(humanoid,false) -- set all states to false
	controls:Disable() -- disable controls
	--game:GetService("StarterGui"):SetCore("ResetButtonCallback",false) -- prevent reset
	local f = coroutine.wrap(introScene)
	f()
end

character = player.Character or player.CharacterAdded:Wait()
firstCharacterAdded(character)
player.CharacterAdded:Connect(characterAdded)

local playButtonTweenInfo = TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0)

_G.tweenButton = function(container)
	local layout = container:FindFirstChild("UIListLayout")
	if layout then
		local size = layout.AbsoluteContentSize.Y
		local endSize = math.round(size*1.5)
		--print("end size = ",endSize)
		local clone = rs:WaitForChild("button_bg"):Clone()
		clone.Parent = container
		game:GetService("Debris"):AddItem(clone,1)
		
		for _,v in pairs(clone:GetChildren()) do
			if v:IsA("ImageLabel") then
				v.ImageTransparency = 0
				v.Size = UDim2.new(0,size,0,size)				
			end
		end	
		
		local start = tick()
		while true do 
			local p = math.clamp((tick() - start)/.25,0,1)
			local range = endSize-size
			local updatedSize = math.clamp(size + (range * p),size,endSize)
			for _,v in pairs(clone:GetChildren()) do 
				if v:IsA("ImageLabel") then
					v.Size = UDim2.new(0,updatedSize,0,updatedSize) 
					v.ImageTransparency = p
				end
			end
			
			if p == 1 then break end
			runService.RenderStepped:Wait()
		end
	end
end

local container = playUI:WaitForChild("container")

local function playButtonPressed()
	task.delay(2,_G.updateLighting)
	respawnEvent:FireServer("play")
	rs:WaitForChild("ui_sound"):WaitForChild("button3"):Play()
	_G.tweenButton(container:WaitForChild("1play"))
	local humanoid = character:WaitForChild("Humanoid")
	ragdoll.setStatesEnabled(humanoid,true) -- set all states to true on the client
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
	playUI.Enabled = false -- disable the house pick screen
	local fadeIn = tweenService:Create(blackGui.frame,blackFrameTweenInfo,{BackgroundTransparency = 0})
	fadeIn:Play()
	fadeIn.Completed:Wait()
	--task.wait(1)
	_G.cutscenePlaying = false -- this'll stop the loop for camera moving around map
	task.wait(.25)
	-- check if you already played the intro cutscene before
	
	characterAdded(character)
	-- enable scripts
	local scripts={
		playerScripts:WaitForChild("Abilities"),
		--playerScripts:WaitForChild("Leaderboards"),
		objectiveUI:WaitForChild("objectiveManager"),
		playerScripts:WaitForChild("Trackers"),
		--playerScripts:WaitForChild("Trains"), -- put this at the bottom later
		playerGui:WaitForChild("notificationUI"):WaitForChild("notificationManager"),
		playerScripts:WaitForChild("Teleports"),
		playerScripts:WaitForChild("Thugs"),
		playerScripts:WaitForChild("ClientVillains"),
		playerScripts:WaitForChild("Cars"),
		playerScripts:WaitForChild("Civs"),
		playerScripts:WaitForChild("Heli"),
	}
	
	task.spawn(function()
		for _,_script in scripts do 
			_script.Enabled=true
			task.wait(.5)
		end
	end)
	
	if not _G.cash_changed then
		repeat task.wait() until _G.cash_changed
	end

	_G.cash_changed()
	
	local roomScene = workspace:FindFirstChild("RoomScene")
	if roomScene then
		roomScene:Destroy()
	end
end

local credits=container:WaitForChild("2credits")
local creditsContainer=playUI:WaitForChild("creditsContainer")
local function creditButtonPressed()
	rs:WaitForChild("ui_sound"):WaitForChild("button3"):Play()
	_G.tweenButton(credits)
	creditsContainer.Visible=not creditsContainer.Visible
end

container:WaitForChild("1play"):WaitForChild("text"):WaitForChild("button").Activated:Connect(playButtonPressed)
credits:WaitForChild("text"):WaitForChild("button").Activated:Connect(creditButtonPressed)