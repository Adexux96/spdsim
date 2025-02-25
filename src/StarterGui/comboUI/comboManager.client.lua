local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local temp=leaderstats:WaitForChild("temp")
local combos=temp:WaitForChild("combos")
local timer=combos:WaitForChild("timer")
local comboUI=script.Parent

local ts=game:GetService("TweenService")

local container=comboUI:WaitForChild("container")
local top=container:WaitForChild("top")
local bottom=container:WaitForChild("bottom")
local _1=top:WaitForChild("1")
local _2=top:WaitForChild("2")

local rs=game:GetService("ReplicatedStorage")
local _math=require(rs:WaitForChild("math"))

local duration=1

local transparency={
	{top,.5},
	{bottom,0},
	{_1,0},
	{_2,0}
}

local function goal(action)
	if not _G.slot_offset or not _G.slot_size then
		repeat task.wait() until _G.slot_offset and _G.slot_size
	end
	local offset=(_G.slot_offset*3)+(_G.slot_size*2)
	local out={
		start=UDim2.new(0,offset-_G.slot_size,0.5,0),
		goal=UDim2.new(0,offset,0.5,0)
	}
	local _in={
		start=UDim2.new(0,offset,0.5,0),
		goal=UDim2.new(0,offset-_G.slot_size,0.5,0)
	}
	return action=="out" and out or _in
end

local function slide(action)
	local data=goal(action)
	local elapsed=tick()-container:GetAttribute("Timer")
	local p=math.clamp(elapsed/.25,0,1)
	local x=_math.lerp(data.start.X.Offset,data.goal.X.Offset,p)
	container.Position=UDim2.new(0,x,0.5,0)
	--print("action=",action)
	--print("p=",p)
	
	for _,array in transparency do 
		local element=array[1]
		local start=action=="out" and 1 or array[2]
		local goal=action=="out" and array[2] or 1
		if element:IsA("TextLabel") then
			element.TextTransparency=_math.lerp(start,goal,p)
		end
		if element:IsA("ImageLabel") then
			element.ImageTransparency=_math.lerp(start,goal,p)
		end
	end
	
	if p==1 then
		return "finished"
	end
end

local function shake(x,y)
	local offset=-_G.slot_offset*3
	x=offset
	y=offset
	local elapsed=workspace:GetServerTimeNow()-timer.Value
	local p=math.clamp(elapsed/.5,0,1)
	local p2=1-ts:GetValue(p,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out)
	local p3=math.clamp(elapsed/.25,0,1)
	--[[
	local clone=_1.Parent:FindFirstChild("clone")
	if clone then
		local op_x=x>0 and x*-1 or math.abs(x)
		local op_y=y>0 and y*-1 or math.abs(y)
		clone.Visible=true
		clone.Position=UDim2.new(1,op_x*p3,0,op_y*p3)
		clone.TextTransparency=p3
	end
	]]
	_1.Position=UDim2.new(1,x*p2,0,y*p2)
end

--[[
local function test()
	local start=tick()
	local duration=.5
	local ts=game:GetService("TweenService")
	local move=game.StarterGui.comboUI.container.top["1"]
	local offset=-6
	while true do
		local elapsed=tick()-start
		local p=math.clamp(elapsed/duration,0,1)
		local p2=1-ts:GetValue(p,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out)
		move.Position=UDim2.new(1,offset*p2,0,offset*p2)
		if p==1 then break end
		task.wait()
	end
end

test()
]]

local function update(x,y)
	
	local elapsed=workspace:GetServerTimeNow()-timer.Value
	local p=combos.Value>0 and math.clamp(elapsed/duration,0,1) or 1
	
	_1.Text=combos.Value
	--_1:WaitForChild("bg").Text=combos.Value
	
	bottom.Size=UDim2.new(1-p,0,0,bottom.Size.Y.Offset)
	bottom.ImageRectOffset=Vector2.new(((1-p)*256)-256,0)
	
	if p==1 then  -- slide in
		if container:GetAttribute("Last")=="out" then
			container:SetAttribute("Last","in")
			container:SetAttribute("Timer",tick())
		end
		return slide("in")
	else 
		if container:GetAttribute("Last")~="out" then
			container:SetAttribute("Last","out")
			container:SetAttribute("Timer",tick())
		end
		slide("out")
	end
	
	shake(x,y)
end

--[[
local function check() -- check timer change instead
	if combos.Value>0 then
		mock.Value=combos.Value
	end
end

combos:GetPropertyChangedSignal("Value"):Connect(check)
]]

--[[
	if running then it'll also change to go out for a new change to 0 combo
]]

local last=combos.Value
local x,y=0,0
local running=false
while true do
	while workspace:GetServerTimeNow()-timer.Value<duration or running do
		--print("combos=",combos.Value)
		
		running=true
		
		if combos.Value~=last then
			--x=_math.negOrPos(_G.slot_offset*3)
			--y=_math.negOrPos(_G.slot_offset*3)
			last=combos.Value
			local lastClone=_1.Parent:FindFirstChild("clone")
			if lastClone then lastClone:Destroy() end
			--[[
			local clone=_1:Clone()
			clone.Position=UDim2.new(1,0,0,0)
			clone.Name="clone"
			clone.Visible=false
			clone.TextColor3=Color3.fromRGB(0, 255, 255)
			clone.ZIndex=0
			clone.Text=combos.Value
			clone.Parent=_1.Parent
			]]
		end
		
		local result=update(x,y)
		if result=="finished" then 
			running=false
			break 
		end
		task.wait()
	end
	combos:GetPropertyChangedSignal("Value"):Wait()
	--mock:GetPropertyChangedSignal("Value"):Wait()
end
