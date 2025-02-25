local countdownUI=script.Parent
local container=countdownUI:WaitForChild("container")
local bg=container:WaitForChild("bg")
local blue=container:WaitForChild("blue")
local white=container:WaitForChild("white")

local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local temp=leaderstats:WaitForChild("temp")
local RagdollRecovery=temp:WaitForChild("RagdollRecovery")

local rs=game:GetService("ReplicatedStorage")
local button=rs:WaitForChild("ui_sound"):WaitForChild("button3")
local _math=require(rs:WaitForChild("math"))

local ts=game:GetService("TweenService")
local tweenInfo1=TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
local tweenInfo2 = TweenInfo.new(.05,Enum.EasingStyle.Elastic,Enum.EasingDirection.InOut,1,true,0)
local tweenInfo3=TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
local tweenInfo4=TweenInfo.new(.333,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0.333)
local tweenInfo5=TweenInfo.new(.5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0.333)

--[[ on change:
	
--// blue text movement is 10 percent of text size
--// move the blue text forward on x, upward on y while gradually degrade blue text transparency till invisible
	
--// shake the white text each change;
--// change the text to the new amount
	
--// change bg; 
	rotation, 
	image, 
	size up from 0, 
	opaque from 0
	
if 0 time left, remove the ui
if died, remove the ui
	
]]

local bg_sizes={
	--["0"]=1.5, 
	--["128"]=1.25,
	["256"]=1.5, 
	["384"]=1.75
}

local offsets={
	Vector2.new(128,128),
	Vector2.new(128,0),
	Vector2.new(256,0),
	Vector2.new(0,128)
}

local function stop()
	countdownUI.Enabled=false
	bg.Size=UDim2.new(0,0,0,0)
	white.TextTransparency=1
	white.Position=UDim2.new(0,0,.5,0)
	white.Size=UDim2.new(0,0,0,0)
	blue.TextTransparency=1
	blue.Size=UDim2.new(0,0,0,0)
end

local function GetSmallerText(text:string, size:number)
	return [[<font size="]]..size..[[">]]..text..[[</font>]]
end

local function AddStrokeText(text:string, thickness:number, textColor:string, strokeColor:string)
	local transparency=".5"
	return [[<font color="]]..textColor..[["><stroke color="]]..strokeColor..[[" thickness="]]..thickness..[[" transparency="]]..transparency..[[">]]..text..[[</stroke></font>]]
end

local function changed2()
	if RagdollRecovery.Value==0 then
		stop()
		return
	end
	--container:WaitForChild("Sound"):Play()
	countdownUI.Enabled=true
	white.TextTransparency=0
	white.UIStroke.Transparency=0
	--white.TextStrokeTransparency=.5
	white.Size=UDim2.new(1,0,.6,0)
	local textSize=white.AbsoluteSize.Y
	white.UIStroke.Thickness=5
	local smaller=math.round(textSize*.875)
	local smaller2=math.round(smaller*.75)
	local s=--[[GetSmallerText("recover",smaller).." : "..]]RagdollRecovery.Value--..GetSmallerText(" s",smaller2)
	white.TextSize=textSize
	white.Text=s--AddStrokeText(s,math.round(textSize*.075),"#ffffff","#000000")
	local goal=UDim2.new(0,math.round(textSize*.25),.5,-math.round(textSize*.25))
	white.Position=UDim2.new(0,0,.5,0)
	ts:Create(white,tweenInfo2,{Position = goal}):Play()
	local offset=offsets[math.random(1,#offsets)]
	bg.ImageRectOffset=offset
	bg.ImageTransparency=1
	local y_size=math.round(container.AbsoluteSize.Y*1.287878787878788)
	local x_size=math.round(y_size*1.505882352941176)
	local size_goal=UDim2.new(0,x_size,0,x_size)
	--local multiplier=bg_sizes[tostring(offset.X)]
	--local size_goal=UDim2.new(0,math.round(x_size*multiplier),0,math.round(y_size*multiplier))
	--print("offset=",offset.X)
	--print("size_goal=",size_goal)
	bg.Size=UDim2.new(0,0,0,0)
	--ts:Create(bg,tweenInfo3,{Size=size_goal}):Play()
	ts:Create(white,tweenInfo4,{TextTransparency=1}):Play()
	ts:Create(white.UIStroke,tweenInfo5,{Transparency=1}):Play()
	blue.TextSize=textSize
	blue.Text=s
	blue.TextTransparency=0
	ts:Create(blue,tweenInfo3,{TextTransparency=1}):Play()
	blue.Position=UDim2.new(0,0,0.5,0)
	local pos_offset=math.ceil(textSize*.1)
	local x=_math.negOrPos(pos_offset)
	local y=_math.negOrPos(pos_offset)
	ts:Create(blue,tweenInfo3,{Position=UDim2.new(0,x,.5,y)}):Play()
	blue.Size=UDim2.new(1,0,0.5,0)
end

local Effects=require(rs:WaitForChild("Effects"))
local function changed()
	
end

stop()

RagdollRecovery:GetPropertyChangedSignal("Value"):Connect(changed)