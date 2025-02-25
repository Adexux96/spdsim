local rs = game:GetService("ReplicatedStorage") 
local runService = game:GetService("RunService")
local drops = workspace:WaitForChild("Drops")
local verifiedDrops = {}

local function addEvent(drop)
	verifiedDrops[#verifiedDrops+1] = {drop=drop,lastTween=nil}
end

for _,drop in pairs(drops:GetChildren()) do
	addEvent(drop)
end

drops.ChildAdded:Connect(function(child)
	addEvent(child)
end)

local max_brightness = .75
local duration = 10
local pause = 1/60
local max_time = 1/pause

local camera = workspace.CurrentCamera

local clock = rs:WaitForChild("clock")
local ts=game:GetService("TweenService")
local tweenInfo=TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)

local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local tutorial=leaderstats:WaitForChild("tutorial")
local thugs=tutorial:WaitForChild("Thugs")

--local purchasables=workspace:WaitForChild("Purchasables")
local teleports=workspace:WaitForChild("Teleports")

local iteration=0

local function run()
	-- if time expires, remove drop
	--local success,_error=pcall(function()
	for i,data in pairs(verifiedDrops) do 
		--print("verified drop!")
		local drop=data.drop
		if data.lastTween then
			data.lastTween:Destroy()
			data.lastTween=nil
		end
		if drop==nil or drop.Parent==nil then
			--print("removed from table!")
			table.remove(verifiedDrops,i)
			continue
		end
		local timer = drop:WaitForChild("timer")
		local iteration = drop:WaitForChild("iteration")
		local elapsed = workspace:GetServerTimeNow() - tonumber(timer.Value)
		if elapsed > duration then
			table.remove(verifiedDrops,i)
		else
			local icon = drop:FindFirstChild("icon")
			local hitBox = drop:FindFirstChild("hitbox")
			if not icon or not hitBox then --[[print("they're nil")]] continue end
			for _,particle in pairs(icon.Attachment:GetChildren()) do
				local t = (max_time/particle.Rate) * pause
				local particleTick = particle:WaitForChild("tick")
				if (tick() - particleTick.Value > t) then -- enough time has passed, you can emit now
					particleTick.Value = tick()
					local pos = icon.Position
					local vector, inViewport = camera:WorldToViewportPoint(pos)
					if (inViewport) then				
						particle:Emit(1)
					end
				end
			end
			local p = math.clamp((workspace:GetServerTimeNow() - timer.Value)/(pause*100),0,1)
			icon:WaitForChild("PointLight").Brightness = math.clamp(p * max_brightness,0,max_brightness)
			-- move it up and down, rotate it	
			if iteration.Value == 360 then
				iteration.Value = 0
			end
			iteration.Value += 1
			local p = iteration.Value/360
			local sine = math.sin(math.pi * p)
			local move_dt=workspace:GetServerTimeNow()-drop.moveTimer.Value
			local t=math.clamp(drop.distance.Value/100,0,1)
			local moveP=math.clamp(move_dt/t,0,1)
			local newPos
			if drop.assigned.Value and drop.assigned.Value.PrimaryPart then
				--print("detected")
				local goal=drop.assigned.Value.PrimaryPart.Position
				newPos=drop.PrimaryPart.Position:Lerp(goal,moveP)
				data.lastTween=ts:Create(drop.PrimaryPart,tweenInfo,{CFrame=CFrame.new(newPos)*CFrame.Angles(0,math.rad(iteration.Value),0)})
				data.lastTween:Play()
			else
				--print("not detected")
				newPos=drop.origin.Value.Position + Vector3.new(0,sine*1,0)
				icon.CFrame=CFrame.new(newPos) * CFrame.Angles(0,math.rad(iteration.Value),0)
			end
		end
	end

	if iteration==360 then
		iteration=0
	end
	iteration+=1
	local p = iteration/360
	local sine = math.sin(math.pi * p)
	
	--[[
	for _,purchasable in purchasables:GetChildren() do 
		local icon=purchasable:FindFirstChild("icon")
		if icon and icon:FindFirstChild("inner") and icon:FindFirstChild("outer") then
			if not icon:GetAttribute("Iteration") then
				icon:SetAttribute("Iteration",0)
				icon:SetAttribute("origin",icon.PrimaryPart.Position)
			end
			local origin=icon:GetAttribute("origin")
			local newPos=origin+Vector3.new(0,sine*1,0)
			icon:SetPrimaryPartCFrame(CFrame.new(newPos) * CFrame.Angles(0,math.rad(iteration),math.rad(90)))
		end
	end
	]]

	for _,teleport in teleports:GetChildren() do 
		local lock=teleport:FindFirstChild("Lock")
		if not lock then continue end
		local unlocked=teleport:FindFirstChild("Unlocked")
		if not unlocked then continue end
		if unlocked.Value then lock:Destroy() continue end
		local circle=teleport:FindFirstChild("circle")
		if not circle then continue end
		local origin=circle.Position+Vector3.new(0,.5,0)
		local newPos=origin+Vector3.new(0,sine*1,0)
		lock.CFrame=CFrame.new(newPos) * CFrame.Angles(0,math.rad(iteration),0)
	end

	if thugs.Value then
		local arrow=workspace:FindFirstChild("Arrow")
		if arrow then
			arrow:Destroy()
		end
	end

	local fast_movers={
		workspace:FindFirstChild("Arrow"),
		workspace:FindFirstChild("question"),
		workspace:FindFirstChild("question2")
	}	

	local offsets={
		["Arrow"]=1.5,
		["question"]=.75,
		["question2"]=.75
	}

	for _,mover in fast_movers do 
		if not mover:GetAttribute("origin") then
			mover:SetAttribute("origin",mover.Position)
		end
		local iteration=iteration*2
		local p=iteration/360
		local sine=math.sin(math.pi*p)
		local origin=mover:GetAttribute("origin")
		local newPos=origin+Vector3.new(0,sine*offsets[mover.Name],0)
		mover.CFrame=CFrame.new(newPos) * CFrame.Angles(0,math.rad(iteration),0)	
	end
end

clock:GetPropertyChangedSignal("Value"):Connect(run)