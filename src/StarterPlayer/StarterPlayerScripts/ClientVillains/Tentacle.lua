--!nocheck
local rng = Random.new(tick())
local function defined(x,y)
	return rng:NextNumber(x,y)
end

local function negOrPos(n)
	local nums = {-n,n}
	return nums[rng:NextInteger(1,2)]
end

local constraints={
	["A1Tentacle"]=0,
	["A2Tentacle"]=6,
	["A3Tentacle"]=4,
	["A4Tentacle"]=2,
	["A5Tentacle"]=3,
	["A6Tentacle"]=6,
}

local rs=game:GetService("ReplicatedStorage")
local ts=game:GetService("TweenService")
local tweeninfo=TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
local cs=game:GetService("CollectionService")
local math_loaded=rs:WaitForChild("math"):WaitForChild("loaded")

--// wait for the math module to fully load so it doesn't throw an error

if math_loaded.Value==false then
	math_loaded:GetPropertyChangedSignal("Value"):Wait()
end

local m=require(rs:WaitForChild("math"))
local tentacle_model=rs:WaitForChild("Tentacles")
local module = {}

function module.apply(value)
	if value.bone then
		local origin=value.bone:GetAttribute("origin")
		local current=value.bone.Orientation
		local goal=current:Lerp(value.goal,value.progress)--//define the goal
		value.bone.Orientation=goal
	end
end

function module.move(info:{})
	for i=1,6 do
		for key,value in {info} do
			local child=value.bone:FindFirstChildOfClass("Bone")
			value.bone=child --// change the variable to its child
			local progress=(1/(i*value.constraint))
			progress=ts:GetValue(progress,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out)
			value.progress=progress
			module.apply(value)
		end
	end
end

function module.reset(bone:Bone)
	bone:SetAttribute("constraint",constraints[bone.Name])
	bone:SetAttribute("timer",tick())
	bone:SetAttribute("duration",defined(1,2))
	bone:SetAttribute("x",negOrPos(defined(0,0)))
	bone:SetAttribute("z",negOrPos(defined(0,90)))
	bone:SetAttribute("xdamp",(defined(.1,.5)))
	bone:SetAttribute("zdamp",(defined(.1,.5)))
end

function module.update(tentacle:Model,venom:Model,spine:Bone,offset:CFrame)
	tentacle.PrimaryPart.Anchored=true
	--ts:Create(tentacle.PrimaryPart,tweeninfo,{CFrame=spine.TransformedWorldCFrame*offset}):Play()
	tentacle.PrimaryPart.CFrame=spine.TransformedWorldCFrame*offset
	for i,v in tentacle:WaitForChild("mesh"):WaitForChild("Root"):GetChildren() do
		local a=v:GetAttributes()
		local p=math.clamp((tick()-a["timer"])/a["duration"],0,1)
		local sinP=math.sin(math.pi*p)
		local goal=v.Orientation:Lerp(Vector3.new((a["x"]*sinP)*a["xdamp"],0,(a["z"]*sinP)*a["zdamp"]),sinP)
		module.move({bone=v,goal=goal,constraint=a["constraint"]})
		if p==1 then
			module.reset(v)
		end
	end
end

function module.new(parent:Model) 
	local clone=tentacle_model:Clone()
	local properties=parent:WaitForChild("Properties")
	local spine=properties:WaitForChild("Spine").Value
	local tentacle_offset=properties:WaitForChild("TentacleOffset")
	local root=clone.PrimaryPart:WaitForChild("Root")
	for i,v in root:GetDescendants() do 
		v:SetAttribute("origin",v.Orientation)
		if v.Parent==root then
			module.reset(v)
		end
	end
	--module.update(clone,parent,spine,tentacle_offset.Value)
	clone.Parent=parent
	return clone
end

function module.remove(tentacle:Model)
	tentacle:Destroy()
end

function module.run(roar:boolean,venom:Model,properties:Folder)
	local tentacle=venom:FindFirstChild("Tentacle")
	if roar then
		if not tentacle then
			tentacle=module.new(venom)
		else 
			module.update(tentacle,venom,properties:WaitForChild("Spine").Value,properties:WaitForChild("TentacleOffset").Value)
		end
	else 
		if tentacle then
			tentacle=module.remove(tentacle)
		end
	end
end

local cs=game:GetService("CollectionService")
function module:setup(venom)
	local properties=venom:WaitForChild("Properties")
	local roar=properties:WaitForChild("Roar")
	cs:AddTag(venom,"setup")
	roar:GetPropertyChangedSignal("Value"):Connect(function()
		local tentacle=venom:FindFirstChild("Tentacles")
		if roar.Value then
			if not tentacle then
				tentacle=module.new(venom)
			end
		else 
			if tentacle then
				module.remove(tentacle)
			end
		end
		while roar.Value do
			module.update(tentacle,venom,properties:WaitForChild("Spine").Value,properties:WaitForChild("TentacleOffset").Value)
			task.wait()
		end
	end)
end

function module:runGrab(venom)
	
end

function module:setupGrab(venom)
	
end


local offsets={
	["BottomRight"]=Vector3.new()
}

--[[
local ts=game:GetService("TweenService")
local function get_positions(startCF)
	local endCF=startCF*CFrame.new(0,0,10)
	--local x,y,z=CFrame.new(startCF.Position,endCF.Position):ToOrientation()
	local positions={}
	local nodes=6
	for i=1,nodes do
		local p=(i-1)/(nodes-1)
		local baseCF=startCF:Lerp(endCF,p)
		local x=math.sin(math.pi*p)*-2
		local y=math.sin(math.pi*p)*-2
		local z=i==1 and 0 or (1-p)*-3
		positions[i]=baseCF*CFrame.new(x,y,z).Position
	end
	return positions
end

]]

--[[
generate the sine wave paths and gradually move the tentacles out while also increasing the length and girth
]]

--[[
local function setup(venom)
	local args={}
	args.body=venom:WaitForChild("Body")
	local x,y,z=args.body.PrimaryPart.CFrame:ToOrientation()
	args.spine=args.body.PrimaryPart:WaitForChild("Root"):WaitForChild("Spine")
	args.spine2=args.spine:WaitForChild("Spine2")
	args.spine3=args.spine2:WaitForChild("Spine3")
	args.topCF = CFrame.new(args.spine3.WorldPosition)*CFrame.fromOrientation(x,y,z)
	args.TopLeft = args.topCF*CFrame.new(1,0,0)
	args.TopRight = args.topCF*CFrame.new(-1,0,0)
	args.bottomCF=CFrame.new(args.spine2.WorldPosition)*CFrame.fromOrientation(x,y,z)
	args.BottomLeft=args.bottomCF*CFrame.new(.5,0,0)
	args.BottomRight=args.bottomCF*CFrame.new(-.5,0,0)
	local tentacle_size=Vector3.new(0.85, 0.85, 14.768)
	local tentacles={}
	local points={args.TopLeft,args.TopRight,args.BottomLeft,args.BottomRight}
	local positions=get_positions(args.BottomRight)
	for i=1,#positions do 
		local clone=workspace.p:Clone()
		clone.Transparency=1-(i/#positions)
		clone.Position=positions[i]
		clone.Name=i
		clone.Parent=workspace
		game:GetService("Debris"):AddItem(clone,5)
	end
	--[[
		for i,v in points do 
		local tentacle=workspace.Tentacle2:Clone()
		tentacle.Size=tentacle_size/2
		tentacle.CFrame=v*CFrame.new(0,0,-tentacle.Size.Z/2)
		tentacle.Name="clone"
		tentacle.Parent=workspace
	end
	--workspace.p.CFrame=args.BottomRight
end

setup(workspace.Venom2)
]]

local venomObjectValue=script:WaitForChild("Venom")
venomObjectValue:GetPropertyChangedSignal("Value"):Connect(function()
	local venom=venomObjectValue.Value
	if cs:HasTag(venom,"Venom") then
		module:setup(venom)
	end
end)

return module
