local player=game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local cashUI = playerGui:WaitForChild("cashUI")
local cash_container=cashUI:WaitForChild("container")
local cash_upper_text=cash_container:WaitForChild("cash"):WaitForChild("upperText")
local cash_goal_icon=cash_container:WaitForChild("cash"):WaitForChild("info"):WaitForChild("iconContainer"):WaitForChild("icon")

local comicUI = playerGui:WaitForChild("comicUI")
local comic_container=comicUI:WaitForChild("container")
local comic_upper_text=comic_container:WaitForChild("cash"):WaitForChild("upperText")
local comic_goal_icon=comic_container:WaitForChild("cash"):WaitForChild("info"):WaitForChild("iconContainer"):WaitForChild("icon")

local rs = game:GetService("ReplicatedStorage")
local ts = game:GetService("TweenService")
--local iconTweenInfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,true,0)
local flyOffTweenInfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0)
local _math = require(rs:WaitForChild("math"))
local interface=require(rs:WaitForChild("interface"))

local effect=require(rs:WaitForChild("Effects"))

local player = game.Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local comicPages= leaderstats:WaitForChild("Comic pages")

local oldCashValue = cash.Value
local oldComicValue= comicPages.Value

local lastCashTick = tick()
local lastFlyOffType = nil
local lastCashDifference = 0

local function flyoff(flyOffText,difference,category)
	local color=category=="cash" and Color3.fromRGB(164, 193, 76) or Color3.fromRGB(255,255,255)
	color=difference>0 and color or Color3.fromRGB(255, 98, 84)
	local s=difference>0 and "+" or "-"
	local text= s.._math.giveNumberCommas(math.abs(difference))
	local tween=true
	if (lastFlyOffType=="gain" and difference>0) or (lastFlyOffType=="loss" and difference<0) then
		text= s.._math.giveNumberCommas(math.abs(difference)+lastCashDifference)
		tween=false
		--print("last was the same!")
	end
	lastCashDifference = math.abs(difference)
	lastFlyOffType=difference>0 and "gain" or "loss"
	
	local elements=category=="cash" and cash_upper_text:WaitForChild("text"):GetChildren() or comic_upper_text:WaitForChild("text"):GetChildren()
	for i,v in elements do 
		v.TextColor3=v.Name=="top" and color or Color3.fromRGB(0,0,0)
		v.Text=text
		if tween then
			v.Size=UDim2.new(0,0,0,0)
			ts:Create(v,flyOffTweenInfo,{Size=UDim2.new(1,0,0.6,0)}):Play()
			local t = lastCashTick
			task.delay(2,function()
				if t == lastCashTick then -- no change since then, reset
					lastCashDifference = 0
					lastFlyOffType=nil
					ts:Create(v,flyOffTweenInfo,{Size=UDim2.new(0,0,0,0)}):Play()
					--v.Size=UDim2.new(0,0,0,0)
				end
			end)
		end
	end
end

--[[
local function flyoff(flyOffText,difference,category)
	--local difference = cash.Value - oldCashValue
	if difference > 0 then -- gained money
		if lastFlyOffType == "gain" then
			lastCashTick = tick()
			flyOffText.Text = "+".._math.giveNumberCommas(difference+lastCashDifference)
		else -- start a new one
			lastCashTick = tick()
			lastFlyOffType = "gain"
			flyOffText.TextColor3 = category=="cash" and Color3.fromRGB(130, 199, 98) or Color3.fromRGB(255,255,255)
			flyOffText.Text = "+".._math.giveNumberCommas(difference)
			flyOffText.Position = UDim2.new(0,0,0,0)
			flyOffText.Visible = true
			ts:Create(flyOffText,flyOffTweenInfo,{Position = UDim2.new(0,0,-1,0)}):Play()
		end
	else -- lose money
		if lastFlyOffType == "loss" then
			lastCashTick = tick()
			flyOffText.Text = "-".._math.giveNumberCommas(math.abs(difference)+lastCashDifference)
		else
			lastCashTick = tick()
			lastFlyOffType = "loss"
			flyOffText.TextColor3 = Color3.fromRGB(255, 98, 84)
			flyOffText.Text = "-".._math.giveNumberCommas(math.abs(difference))
			flyOffText.Position = UDim2.new(0,0,0,0)
			flyOffText.Visible = true
			ts:Create(flyOffText,flyOffTweenInfo,{Position = UDim2.new(0,0,-1,0)}):Play()			
		end
	end
	
	lastCashDifference = math.abs(difference)
	spawn(function()
		local t = lastCashTick
		task.wait(2)
		if t == lastCashTick then -- no change since then, reset
			lastFlyOffType = nil
			lastCashDifference = 0
			flyOffText.Position = UDim2.new(0,0,0,0)
			flyOffText.Visible = false
		end
	end)
	
end
]]

local fly={}
local fly_value=Instance.new("StringValue")
fly_value.Value=tick()

local function _2D_Effect(difference,category)
	local factor=category=="cash" and 1000 or 100
	local amount=math.clamp(math.ceil(difference/factor),1,4)
	local icon=category=="cash" and cashUI:WaitForChild("icon") or comicUI:WaitForChild("icon")
	local goal_icon=category=="cash" and cash_goal_icon or comic_goal_icon
	for i=1,amount do
		local clone=icon:Clone()
		clone.AnchorPoint=Vector2.new(0,0)
		local size=icon.AbsoluteSize.X*2
		local size2=icon.AbsoluteSize.X*1.5
		local x = icon.AbsolutePosition.X + math.random(-size,size)
		local y = icon.AbsolutePosition.Y + math.random(-size,size)
		clone.Position=UDim2.new(0,x,0,y)
		clone.Visible=true
		clone.Parent=category=="cash" and cashUI or comicUI
		local n=#fly+1
		local duration=_math.defined(.75,1)
		--print("duration=",duration)
		fly[n]={
			start=tick(),
			icon=clone,
			duration=duration,
			index=n,
			category=category,
			x=icon.AbsolutePosition.X,
			y=icon.AbsolutePosition.Y,
			goal_icon=goal_icon,
			size=goal_icon.AbsoluteSize.X,
			offset = i%2==0 and _math.defined(size2/2,size2) or -_math.defined(size2/2,size2)
		}
	end
	fly_value.Value=tick() -- update the value
end

local function size_everything(category)
	local difference=category=="cash" and cash.Value-oldCashValue or comicPages.Value-oldComicValue
	oldCashValue = cash.Value
	oldComicValue= comicPages.Value
	local value=category=="cash" and oldCashValue or oldComicValue
	local container=category=="cash" and cash_container or comic_container
	local yOffset=category=="cash" and 0 or math.round(_G.slot_size/1.75)+_G.slot_offset
	local flyOffText=interface.currencyUI(true,container,yOffset,value)
	flyoff(flyOffText,difference,category)
	if difference<=0 then return end
	_2D_Effect(difference,category)
end

local function cashChanged()
	size_everything("cash")
end

local function comicsChanged()
	size_everything("comic")
end

cash:GetPropertyChangedSignal("Value"):Connect(cashChanged)
comicPages:GetPropertyChangedSignal("Value"):Connect(comicsChanged)

local size_icon_cash=false
local size_icon_comic=false

local function size_icon(cash,comic)
	
	if cash then
		local last=cash_goal_icon:GetAttribute("Last")
		
		local elapsed=tick()-last 
		local p=math.clamp(elapsed/.5,0,1)
		local increase=math.sin(math.pi*p)*.4
		cash_goal_icon.Size=UDim2.new(1+increase,0,1+increase,0)
		
		if p==1 then
			size_icon_cash=false
		end		
	end
	
	if comic then
		local last=comic_goal_icon:GetAttribute("Last")
		
		local elapsed=tick()-last 
		local p=math.clamp(elapsed/.5,0,1)
		local increase=math.sin(math.pi*p)*.4
		comic_goal_icon.Size=UDim2.new(1+increase,0,1+increase,0)
		
		if p==1 then
			size_icon_comic=false
		end	
	end
	
end

while true do
	while #fly>0 or (size_icon_cash or size_icon_comic) do
		for i,v in fly do
			local goal_X = v.goal_icon.AbsolutePosition.X
			local goal_Y = v.goal_icon.AbsolutePosition.Y+36
			local elapsed = tick()-v.start
			local p=math.clamp(elapsed/v.duration,0,1)
			local p2=math.clamp(p/.5,0,1)
			--p=ts:GetValue(p,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut)
			
			local sin=math.sin(math.pi*p)
			local offset=sin*v.offset
			
			v.icon.Position=UDim2.new(0,_math.lerp(v.x,goal_X,p),0,_math.lerp(v.y+offset,goal_Y+offset,p))
			--v.icon.Size=UDim2.new(0,_math.lerp(v.size,icon.AbsoluteSize.X,p),0,_math.lerp(v.size,icon.AbsoluteSize.Y,p))
			local increase=sin*(v.size*.5)
			increase=math.round(increase)
			v.icon.Size=UDim2.new(0,increase+v.size,0,increase+v.size)
			
			v.icon.white.ImageTransparency=p2
			--v.icon.ImageTransparency=1-p
			
			if p==1 then
				if v.category=="cash" and not size_icon_cash then
					size_icon_cash=true
					v.goal_icon:SetAttribute("Last",tick())
				elseif v.category=="comic" and not size_icon_comic then
					size_icon_comic=true
					v.goal_icon:SetAttribute("Last",tick())
				end
				v.icon:Destroy()
				table.remove(fly,i)
			end
		end
		if size_icon_cash or size_icon_comic then
			size_icon(size_icon_cash, size_icon_comic)
		end
		task.wait()
		--print("running")
	end
	fly_value:GetPropertyChangedSignal("Value"):Wait()
end