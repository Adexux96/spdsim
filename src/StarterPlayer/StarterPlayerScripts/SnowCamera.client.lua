local rs=game:GetService("ReplicatedStorage")
local _snowPart=rs:WaitForChild("SnowPart")
local tweenService=game:GetService("TweenService")
local tweenInfo=TweenInfo.new(.5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
local camera=workspace.CurrentCamera

local player=game.Players.LocalPlayer

if _G.cutscenePlaying==nil or _G.cameraUnderwater==nil then repeat task.wait() until _G.cutscenePlaying~=nil and _G.cameraUnderwater~=nil end

local particleSizes={}

local function toggle_particles(part,canEmit,enabled)
	for i,v in part:GetChildren() do 
		if v:IsA("ParticleEmitter") then
			if not particleSizes[v.Name] then
				particleSizes[v.Name]=v.Size
			end
			v.Size=canEmit and particleSizes[v.Name] or NumberSequence.new(0)
			v.Enabled=enabled
		end
	end
end

local lastPos=camera.CFrame.Position
local dt=tick()
local function update(canEmit,enabled)
	local elapsed=tick()-dt 
	dt=tick()
	local part=camera:FindFirstChild("SnowPart")
	local camPos=camera.CFrame.Position
	if not part then
		part=_snowPart:Clone()
		part.CFrame=CFrame.new(camPos+Vector3.new(0,15,0))
		part.Parent=camera
	else 
		toggle_particles(part,canEmit,enabled)
	end
	local move=camPos-lastPos
	lastPos=camPos
	local velocity=move/elapsed
	part.Position=(camPos+Vector3.new(0,15,0))+velocity
end

while true do 
	update(not _G.cutscenePlaying and not _G.cameraUnderwater, not _G.cutscenePlaying)
	task.wait(.1)
end