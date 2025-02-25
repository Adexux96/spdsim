local player=game.Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local progressUI=playerGui:WaitForChild("progressUI")
local container=progressUI:WaitForChild("container")
local bar=container:WaitForChild("bg"):WaitForChild("bar")
local title=container:WaitForChild("title")

local leaderstats=player:WaitForChild("leaderstats")
local objectives=leaderstats:WaitForChild("objectives")
local current=objectives:WaitForChild("current")
local amount=objectives:WaitForChild("amount")

local rs=game:GetService("ReplicatedStorage")
local items=require(rs:WaitForChild("items"))
local _math=require(rs:WaitForChild("math"))

local function pos(action)
	if not _G.slot_offset then
		repeat task.wait() until _G.slot_offset
	end
	--local bar_size_Y=bar.Size.Y.Offset
	local title_size_Y=title.Size.Y.Offset
	local contents_size=title_size_Y+(_G.slot_offset*2)+36
	return action=="up" and UDim2.new(.5,0,0,-contents_size) or UDim2.new(.5,0,0,contents_size)
end

local function update(goal,bar)
	bar.Size=UDim2.new(goal,0,1,0)
	for i,v in bar:GetChildren() do 
		v.ImageRectOffset=Vector2.new((goal*512)-512,0)
	end
end

local function move(last,action) -- action: "up" or "down"
	if bar:GetAttribute("Last") ~= last then --[[print("return move",action)]] return end
	local start=tick()
	local goal=pos(action)
	local current=container.Position.Y.Offset
	--print("current=",current)
	local y=goal.Y.Offset
	--print("y=",y)
	local max=math.abs(y)*2
	local min=math.abs(y-current)
	--print("min=",min)
	--print("max=",max)
	local duration=math.clamp(min/max,0,1)*.5
	--print("duration=",duration)
	local broke=false
	while true do
		if last ~= bar:GetAttribute("Last") then
			--print("break move",action)
			broke=true
			break -- stop this loop if there's a new change to the bar
		end
		local elapsed=tick()-start
		local p=math.clamp(elapsed/duration,0,1)
		local new_goal=_math.lerp(current,goal.Y.Offset,p)
		container.Position=UDim2.new(.5,0,0,new_goal)
		if p==1 then
			break -- end the loop
		end
		task.wait()
	end
	if action == "up" and amount.Value==0 and broke==false then
		update(0,bar)
	end
end

local sparkles={}

local function create_sparkle(x,y,i)
	if not _G.slot_size then repeat task.wait() until _G.slot_size end
	local sparkle=progressUI:WaitForChild("sparkle")
	local pos=sparkle.AbsolutePosition
	local clone=sparkle:Clone()
	clone.Visible=true
	clone.AnchorPoint=Vector2.new(0,0)
	clone.Parent=progressUI
	local multiplier= i%2==0 and 1 or -1
	sparkles[#sparkles+1]={
		sparkle=clone,
		timer=tick(),
		start=Vector2.new(pos.X,pos.Y),
		goal=Vector2.new(x,y),
		offset=_math.defined(_G.slot_size,_G.slot_size*2) * multiplier
	}
end

local signal
local running=progressUI:WaitForChild("Running")

local function new_signal(bool)
	local objective=items.objectives[current.Value]
	if bool then
		local new=tick()
		bar:SetAttribute("Last",new)
		local goal=amount.Value==0 and 0 or amount.Value/objective.amount
		update(goal,bar)
		move(new,"up")
	end
	if not objective or objective.amount==0 then return end -- this is the police objective, don't read for it
	--print("start")
	container:WaitForChild("title").Text="Objective: "
	
	signal=amount:GetPropertyChangedSignal("Value"):Connect(function()
		running.Value=true
		--if amount.Value==0 then print("had to return") return end -- don't let it update to an empty bar
		local new=tick()
		bar:SetAttribute("Last",new)
		local current=bar.Size.X.Scale
		local goal=amount.Value/objective.amount
		goal=goal==0 and 1 or goal
		local duration=.25
		
		move(new,"down")
		
		
		local _goal=pos("down")
		task.spawn(function()
			local amount=amount.Value==0 and 12 or amount.Value
			local x=bar.AbsolutePosition.X+(container.AbsoluteSize.X*(amount/objective.amount))
			local y=_goal.Y.Offset
			local n=3
			for i=1,n do
				create_sparkle(x,y,i)
				task.wait(.1)
			end
		end)
		
		local start=tick()
		
		while true do
			if bar:GetAttribute("Last") ~= new then -- another loop has started!
				--print("had to break this loop cause it started a new loop!")
				bar:WaitForChild("white").ImageTransparency=1
				break
			end
			
			if #sparkles==0 then
				local elapsed=tick()-start
				local p=math.clamp(elapsed/duration,0,1)
				update(_math.lerp(current,goal,p),bar)
				local p2=math.clamp(elapsed/.5,0,1)
				bar:WaitForChild("white").ImageTransparency=1-math.sin(math.pi*p2)
				if #sparkles==0 and p2==1 then
					break
				end
			else
				start=tick()
			end
			--print("p2=",p2)
			
			
			for i,v in sparkles do 
				local elapsed=tick()-v.timer
				local p=math.clamp(elapsed/1,0,1)

				local x=_math.lerp(v.start.X,v.goal.X,p)
				local y=_math.lerp(v.start.Y,v.goal.Y,p)

				local sin_p=math.sin(math.pi*p)

				v.sparkle.Position=UDim2.new(0,x+(v.offset*sin_p),0,y)
				v.sparkle.ImageTransparency=1-sin_p
				v.sparkle.sparkle.ImageTransparency=1-sin_p

				if p==1 then
					v.sparkle:Destroy()
					table.remove(sparkles,i)
				end
			end
			
			
			task.wait()
		end
		
		running.Value=false
		
		task.delay(3,function()
			move(new,"up")
		end)
		
	end)
end

local function start()
	if signal then -- disconnect the old signal
		signal:Disconnect()
		signal=nil
		--print("disconnected old signal!")
	end
	new_signal(false)
end

current:GetPropertyChangedSignal("Value"):Connect(start)
--local objective=items.objectives[current.Value]
new_signal(true)