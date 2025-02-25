
local rs = game:GetService("ReplicatedStorage")

local cars = workspace:WaitForChild("Cars")
local carModels = rs:WaitForChild("CarModels")
local clientCars = workspace:WaitForChild("clientCars")

local ts = game:GetService("TweenService")
local camera = workspace.CurrentCamera
local comicPops = require(rs:WaitForChild("comicPops"))

local lastTime = nil
local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local TimeOfDay = playerScripts:WaitForChild("Day_Night"):WaitForChild("TimeOfDay")

local function explosion(car)
	local body = car.PrimaryPart
	local destroyedBody = car:WaitForChild("DestroyedBody")
	local tire = car:WaitForChild("FrontLeftTire") -- just need one
	
	for _,component in (car:GetChildren()) do 
		if component:IsA("BasePart") then
			if component ~= destroyedBody then
				component.Transparency = 1
			else 
				component.Transparency= 0
			end
		end
	end
	
	local headlight=car:WaitForChild("Headlight")
	if headlight then
		for _,child in headlight:GetChildren() do 
			if child:IsA("SpotLight") or child:IsA("Beam") then
				child.Enabled=false
			end
		end
	end
	
	car:WaitForChild("Taillight"):WaitForChild("SpotLight").Enabled = false
	
	-- turn off the engine fire
	local engine_attachment = body:WaitForChild("EngineAttachment")
	engine_attachment:WaitForChild("sparks").Enabled = false
	engine_attachment:WaitForChild("smoke").Enabled = false
	
	body:WaitForChild("explosion"):Play()
	
	-- turn on the destroyed effects
	for _,particle in (destroyedBody:GetChildren()) do 
		if particle:IsA("ParticleEmitter") and particle.Name ~= "fire" then
			particle:Emit(3)
		end
	end
	
	local pops = {"bam!","pow!"}
	local f = coroutine.wrap(comicPops.newPopup)
	f(pops[math.random(1,2)],body)
	
	local d = (camera.CFrame.Position - destroyedBody.Position).Magnitude
	local range = 200

	_G.camShake(1,math.clamp(range - d,0,math.huge)/(range/2))
end

local function damaged(car,health) -- have a comic pop up whenever it hits
	local body = car.PrimaryPart
	if not body then return end
	local horn = body:WaitForChild("horn")
	local hit = body:WaitForChild("hit")
	local d = (camera.CFrame.Position - body.Position).Magnitude
	local p = math.clamp((200-d)/200,0,1)
	local alpha = ts:GetValue(p,Enum.EasingStyle.Cubic,Enum.EasingDirection.In)
	horn.Volume = alpha*.25
	hit.Volume = alpha*.75
	hit:Play()
	horn:Play()
	
	local healthP = 1-math.clamp(health/300,0,1)
	
	local engine_attachment = body:WaitForChild("EngineAttachment")
	local smoke = engine_attachment:WaitForChild("smoke")
	local rate = math.clamp(healthP*8,1,8)
	smoke.Rate = rate
	--smoke.Enabled = true
	local sparks = engine_attachment:WaitForChild("sparks")
	sparks.Rate = rate
	--sparks.Enabled = true
	
	-- maybe a particle effect too
	local f = coroutine.wrap(comicPops.newPopup)
	local pops = {"bam!","pow!"}
	f(pops[math.random(1,2)],body)
	
	if not _G.tweenHighlight then 
		repeat task.wait(1/30) until _G.tweenHighlight
	end
	
	_G.tweenHighlight(car)
end

local movingCars = {}

local tweenInfo = TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)

local function adjustSounds(car,speed,index)
	local body = car.PrimaryPart
	local engine = body:WaitForChild("engine")
	if movingCars[index].server.exploded.Value then engine.Volume=0 return end
	
	--local speed=body.Velocity.Magnitude
	
	local p = math.clamp(speed/36,0,1)
	--local alpha = ts:GetValue(p,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
	--engine.PlaybackSpeed = 1*alpha 
	--ts:Create(engine,tweenInfo,{PlaybackSpeed=1*alpha}):Play()
	engine.PlaybackSpeed=.5+(p*.5)
	engine.Volume =.05+(p*.05)
	
	local horn = body:WaitForChild("horn")
	local hit = body:WaitForChild("hit")
	
	local hornTick = body:WaitForChild("hornTick")
	if tick() - hornTick.Value > movingCars[index].hornCooldown then
		hornTick.Value = tick()
		movingCars[index].hornCooldown = math.random(10,15)
		horn:Play()
	end
end

local function carAdded(car)
	local listing = carModels:FindFirstChild(car:WaitForChild("color").Value)
	if not listing then return end
	local clone = listing:Clone()
	local offsetCF = car.CFrame * CFrame.new(0,2.5,0)
	-- set the physics
	--clone.Body.gyro.CFrame = offsetCF
	--clone.Body.position.Position = offsetCF.Position
	--[[
	for _,component in (clone:GetChildren()) do
		if component:IsA("BasePart") then
			component.Anchored = false
		end
	end
	]]
	
	clone:SetPrimaryPartCFrame(offsetCF)
	clone.Name = car.Name
	clone.Parent = clientCars
	
	movingCars[#movingCars+1] = {
		server = car,
		client = clone,
		timer = tick(),
		start = tick(),
		visible = false,
		destroyed = nil,
		lastPosition = offsetCF.Position,
		hornCooldown = 0,
		tires = {
			clone.BackLeftTire,
			clone.BackRightTire,
			clone.FrontLeftTire,
			clone.FrontRightTire
		},
		explodedTires={}
	}
	
	if not _G.tweenHealth then 
		repeat task.wait(1/30) until _G.tweenHealth
	end
	
	local health = car.health
	local oldHealth = health.Value
	health:GetPropertyChangedSignal("Value"):Connect(function()
		local difference = health.Value - oldHealth
		if difference < 0 then
			damaged(clone,health.Value)
		end
		oldHealth = health.Value
		if oldHealth == 0 then
			explosion(clone)
		end
	end)
	
	local movedBackwards = car.movedBackwards
	movedBackwards:GetPropertyChangedSignal("Value"):Connect(function()
		if movedBackwards.Value then
			--camera.CameraSubject = car 
			--print("MOVED BACKWARDS!")
		end
	end)
	
end

cars.ChildAdded:Connect(carAdded)

for _,car in (cars:GetChildren()) do 
	carAdded(car)
end

local clock=rs:WaitForChild("clock")

while true do
	for index,value in (movingCars) do
		local server = value.server
		if server ~= nil and server.Parent ~= nil then
			local speed = server.speed.Value
			--local speedP = math.clamp(speed/36,0,1)
			
			--[[
			if value.lastPosition == server.Position then
				speed = 0
			end
			]]

			local y_offset = 2.5

			local model = value.client
			local body = model.PrimaryPart
			
			local dt = tick()-value.timer
			local lastPos=value.lastPosition
			local travelled=(lastPos-model.PrimaryPart.Position).Magnitude
			
			value.timer = tick()
			value.lastPosition = model.PrimaryPart.Position
			
			local wheel_diameter = 2.787
			local wheel_circumference=(wheel_diameter*math.pi)
			local rps = speed/wheel_circumference
			local rotate=dt*rps*360 
			
			--[[
			local angle=0
			if server.direction.Value ~= "straight" then
				local target_angle = server.direction.Value == "right" and -22.5 or 22.5
				local p = math.round(math.sin(server.progress.Value*math.pi)*1000)/1000
				angle = target_angle*p
			end
			]]
			
			for _,wheel in value.tires do   
				-- get offset from car use that to steer right/left
				-- use the current x angle and add onto it to apply forward rotation
				wheel.CFrame*=CFrame.Angles(-math.rad(rotate),0,0)
			end
			
			--[[
			for _,motor in (model:WaitForChild("AxleMotors"):GetChildren()) do 
				motor.AngularVelocity = -angular_velocity
			end

			]]
			
			local offsetCF = value.server.CFrame * CFrame.new(0,y_offset,0)
			local start=model.PrimaryPart.CFrame
			local goal=offsetCF
			model:SetPrimaryPartCFrame(start:Lerp(goal,.1))
			
			--local gyro = body:WaitForChild("gyro")
			--local position = body:WaitForChild("position")
			--gyro.CFrame = gyro.CFrame:Lerp(offsetCF,.4)
			--position.Position = position.Position:Lerp(offsetCF.Position,.4)
			
			adjustSounds(model,speed,index)
			
			--[[
			local d = (server.Position - model.PrimaryPart.Position).Magnitude
			if d >= 20 then
				local offsetCF = value.server.CFrame * CFrame.new(0,y_offset,0)
				model:SetPrimaryPartCFrame(offsetCF)
			end
			model.PrimaryPart.CanCollide = d <= 20 and true or false
			]]
			
			if server.exploded.Value then
				if not value.destroyed then
					value.destroyed = tick()
					local tireModel = rs:WaitForChild("tire")
					
					--[[
					for i,tire in (value.tires) do
						local clone = tireModel:Clone()
						local x = tire.Name:match("Left") and -1 or 1
						clone.CFrame = tire.CFrame * CFrame.new(x*2,0,0)
						local directions = {-1,1}
						local directionCF = clone.CFrame * CFrame.new(20*x,20,0)
						clone.direction.Value = (directionCF.Position-clone.Position).Unit
						clone.Parent = workspace
						value.explodedTires[#value.explodedTires+1] = clone
						game:GetService("Debris"):AddItem(clone,10)
					end
					]]
					
				end
				elapsed = tick()-value.destroyed
				local destroyedP = math.clamp(elapsed/10,0,1)
				local movementP = math.clamp(elapsed/5,0,1)
				
				local p = math.clamp(elapsed/2,0.5,1)
				local multiplier = math.sin(p*math.pi)
				
				for _,tire in (value.tires) do 
					local mover = tire:FindFirstChild("mover")
					if mover then
						mover.MaxForce = Vector3.new(4000,4000,4000)*multiplier 
						mover.Velocity = tire.direction.Value * 20
					end
				end
				
				if movementP == 1 then
					for _,component in (model:GetChildren()) do
						if component:IsA("BasePart") then
							component.Anchored = true
						end
					end
					local offsetCF = value.server.CFrame * CFrame.new(0,y_offset,0)
					model:SetPrimaryPartCFrame(offsetCF)
				end

				if destroyedP == 1 then
					model:Destroy()
					table.remove(movingCars,index)
				end
			else
				local pause = 1/30
				local max_time = 1/pause
				for _,particle in (body:GetDescendants()) do
					if (particle:IsA("ParticleEmitter")) then
						local t = (max_time/particle.Rate) * pause
						local amount = 0
						local particleTick = particle:WaitForChild("tick")
						if (tick() - particleTick.Value > t) then -- enough time has passed, you can emit now
							particleTick.Value = tick()
							amount = 1			
							particle:Emit(amount)
						end
					end
				end
			end
		else -- server car is destroyed
			local model = value.client
			model:Destroy()
			table.remove(movingCars,index)
		end
		
	end
	--clock:GetPropertyChangedSignal("Value"):Wait()
	task.wait()
end
