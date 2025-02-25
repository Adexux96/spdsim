local civilians_model = workspace:WaitForChild("Civilians")

local rs = game:GetService("ReplicatedStorage")
local clock=rs:WaitForChild("clock")

local civs={}

local physicsService = game:GetService("PhysicsService")
local ragdoll=require(rs:WaitForChild("ragdoll"))

local function Adjust_Civilian_Collisions(body)
	for index,part in pairs(body:GetDescendants()) do 
		if part:IsA("BasePart") then
			part.CollisionGroup="Ghost"
		end
	end
end

local civilian = rs:WaitForChild("Civilian")
local anims = civilian:WaitForChild("Animations")
local run_track=anims:WaitForChild("Sprint"):WaitForChild("run")
local walk_track=anims:WaitForChild("Walk"):WaitForChild("walk")

local ragdoll=require(rs:WaitForChild("ragdoll"))

local function Customize_Civilian(body)
	
	local profile = body:WaitForChild("profile")
	local folder = rs:WaitForChild("Civilian")
	
	local outfit = profile:WaitForChild("outfit").Value
	local gender = profile:WaitForChild("gender").Value
	local skin = profile:WaitForChild("skin").Value
	
	local color = folder:WaitForChild("Color"):FindFirstChild(skin).Value
	
	local shirt = profile:WaitForChild("shirt").Value
	local pants= profile:WaitForChild("pants").Value
	local hat = profile:WaitForChild("hat").Value
	local glasses = profile:WaitForChild("glasses").Value
	local hair = profile:WaitForChild("hair").Value
	local tool = profile:WaitForChild("tool").Value
	local face = profile:WaitForChild("face").Value
	
	local _body = folder:WaitForChild("Body"):FindFirstChild(gender):Clone()
	_body.Parent = workspace
	_body.Humanoid.PlatformStand=true
	
	local outfit_folder = folder:WaitForChild("Clothes"):FindFirstChild(gender):FindFirstChild(outfit)
	
	local _pants = outfit_folder:WaitForChild("Pants"):FindFirstChild(pants)
	if _pants then
		_pants = _pants:Clone()
		_pants.Parent = _body		
	end
	
	local _shirt = outfit_folder:WaitForChild("Shirts"):FindFirstChild(shirt)
	if _shirt then
		_shirt = _shirt:Clone()
		_shirt.Parent = _body
	end
	
	local _hair = _body:WaitForChild("Hair"):FindFirstChild(skin):FindFirstChild(hair)
	if _hair then
		_hair.Value:WaitForChild("Handle").Transparency=0
	end
	
	local _glasses = _body:WaitForChild("Glasses"):FindFirstChild(outfit)
	if _glasses and _glasses:FindFirstChild(glasses) then
		_glasses = _glasses:FindFirstChild(glasses)
		_glasses.Value:WaitForChild("Handle").Transparency=0
	end
	
	local _hat = _body:WaitForChild("Hats"):FindFirstChild(outfit)
	if _hat and _hat:FindFirstChild(hat) then
		_hat = _hat:FindFirstChild(hat)
		_hat.Value:WaitForChild("Handle").Transparency=0
	end
	
	local _tool = _body:FindFirstChild(tool)
	if _tool then
		for _,part in pairs(_tool:GetChildren()) do 
			if part:IsA("BasePart") then
				part.Transparency=0
			end
		end
		--[[
			local tool_anim = folder:WaitForChild("Animations"):WaitForChild("Tools"):FindFirstChild(tool)
			local anim = _body:WaitForChild("Humanoid"):LoadAnimation(tool_anim)
			anim:Play(.2,1,tool_anim:WaitForChild("Speed").Value)
		]]
	end
	--[[
		local walkAnim = _body:WaitForChild("Humanoid"):LoadAnimation(walk_track)
		walkAnim:Play(.2,1,walk_track:WaitForChild("Speed").Value)
	]]
	
	local _face = folder:WaitForChild("Faces"):FindFirstChild(gender):FindFirstChild(face)
	if _face then
		_face=_face:Clone()
		_face.Parent = _body:WaitForChild("Head")
	end
	
	local scream = folder:WaitForChild("Sounds"):FindFirstChild(gender):WaitForChild("Scream"):Clone()
	scream.Parent = _body:WaitForChild("Head")
	
	for _,bodypart in pairs(_body:GetChildren()) do 
		if bodypart:IsA("BasePart") then
			bodypart.Color = color
		end
	end
	
	local humanoid=_body:WaitForChild("Humanoid")
	ragdoll.disableAllStates(humanoid)
	
	return _body
end

local lastSpawn=tick()
local function make_copy(child)
	local debounce=1/20
	if tick()-lastSpawn<debounce then
		repeat task.wait(1/30) until tick()-lastSpawn>=debounce
	end
	lastSpawn=tick()
	local body = Customize_Civilian(child)
	Adjust_Civilian_Collisions(body)
	ragdoll.disableAllStates(body:WaitForChild("Humanoid"))
	civs[#civs+1]={
		main=child,
		mock=body
	}
end

for _,civilians in pairs(civilians_model:GetChildren()) do 
	civilians.ChildAdded:Connect(make_copy)
	for _,child in pairs(civilians:GetChildren()) do 
		make_copy(child)
	end
end

local ts = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)

local function Check_IsPlaying(humanoid,listing)
	local runPlaying,walkPlaying,toolPlaying
	local toolName=listing.main:WaitForChild("profile"):WaitForChild("tool").Value
	local _tool = listing.mock:FindFirstChild(toolName)
	for _,track in pairs(humanoid:GetPlayingAnimationTracks()) do 
		if track.Animation.Name=="run" then
			runPlaying=track
		end
		if track.Animation.Name=="walk" then
			walkPlaying=track
		end
		if _tool and track.Animation.Name==toolName then
			toolPlaying=track
		end
	end
	return runPlaying,walkPlaying,toolPlaying
end

local comic_pops = require(rs:WaitForChild("comicPops"))

while true do
	for i,listing in pairs(civs) do 
		local hrp = listing.mock:WaitForChild("HumanoidRootPart")
		--local offset = Vector3.new(0,2.5,0)
		local clamped_position = Vector3.new(listing.main.Value.Position.X,4,listing.main.Value.Position.Z)
		--[[
		if not listing.node then
			listing.node=rs:WaitForChild("civilian_node"):Clone()
			listing.node.Parent=workspace
		end
		listing.node.CFrame=CFrame.new(clamped_position)
		]]
		local lookAt = CFrame.new(hrp.Position,clamped_position)
		local x,y,z = lookAt:ToOrientation()
		x=x==x and x or 0
		y=y==y and y or 0 
		z=z==z and z or 0
		local cf = CFrame.new(clamped_position)*CFrame.fromOrientation(x,y,z)
		hrp.CFrame=hrp.CFrame:Lerp(cf,.05)
		if hrp.Position.Y<0 then
			print("lookAt=",x,y,z)
			print("pos=",clamped_position)
		end
		--[[
		if hrp.Position.Y < 0 then
			hrp.CFrame=cf
			--print("had to change civ Y")
		end]]
		--if civs[i].moveTween then
			--civs[i].moveTween:Destroy()
			--civs[i].moveTween=nil
		--end
		--civs[i].moveTween=ts:Create(hrp,tweenInfo,{CFrame=cf})
		--civs[i].moveTween:Play()
		local humanoid=listing.mock:WaitForChild("Humanoid")
		local folder = rs:WaitForChild("Civilian")
		
		local runPlaying,walkPlaying,toolPlaying=Check_IsPlaying(humanoid,listing)
		
		local toolName=listing.main:WaitForChild("profile"):WaitForChild("tool").Value
		local _tool = listing.mock:FindFirstChild(toolName)
		if _tool and not toolPlaying then
			local tool_anim = folder:WaitForChild("Animations"):WaitForChild("Tools"):FindFirstChild(toolName)
			local anim = humanoid:LoadAnimation(tool_anim)
			anim:Play(.2,1,tool_anim:WaitForChild("Speed").Value)
		end
		
		if not walkPlaying then
			local walkAnim = humanoid:LoadAnimation(walk_track)
			walkAnim:Play(.2,1,walk_track:WaitForChild("Speed").Value)
			listing.walkAnim=walkAnim
		end
		
		local speed = listing.main.speed.Value
		listing.walkAnim:AdjustSpeed(math.clamp(speed/8,0,1))
		local isFleeing =listing.main.isFleeing.Value
		if isFleeing then
			if not runPlaying then -- play sound and do comic pop here
				listing.mock:WaitForChild("Head"):WaitForChild("Scream"):Play()
				local f = coroutine.wrap(comic_pops.newPopup)
				f("ahh!",listing.mock:WaitForChild("Head"))	
				runPlaying=listing.mock:WaitForChild("Humanoid"):LoadAnimation(run_track)
				runPlaying:Play(.2,1,1)
			end
			runPlaying:AdjustSpeed(math.clamp(speed/16,0,1))
		else
			if runPlaying then
				runPlaying:Stop()
			end
		end
	end
	--task.wait(1/30)
	clock:GetPropertyChangedSignal("Value"):Wait()
end