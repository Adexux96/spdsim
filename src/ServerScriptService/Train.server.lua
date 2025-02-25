
local function Get_Ahead_Node(node,nodes)
	local number=node.Name:match("%d+")
	local ahead=nodes:FindFirstChild("node"..number+1)
	if not ahead then --probably the last node in the track
		ahead=nodes:FindFirstChild("node0")
	end
	return ahead
end

local NPCs = require(script.Parent.NPCs)

local function part_hit(BasePart,speed,hitpart) -- this is to detect if the train hit something
	if speed <= 16 then return end
	local max_speed=36
	local min_speed=20
	local s=math.clamp(speed-min_speed,0,1)
	local damage=(s/(max_speed-min_speed))*100

	local humanoid=BasePart.Parent:FindFirstChild("Humanoid") or BasePart.Parent.Parent:FindFirstChild("Humanoid")
	local properties = BasePart.Parent:FindFirstChild("Properties") or BasePart.Parent.Parent:FindFirstChild("Properties")

	local name = nil
	local model = nil -- if NPC, this will be the NPCs module index
	local isNPC = nil

	if humanoid then
		--print(car.Name,"hit humanoid")
		name = humanoid.Parent.Name
		model = humanoid.Parent
	end

	if properties then
		--print(car.Name,"hit NPC")
		local isDrone = properties:IsDescendantOf(workspace.SpiderDrones)
		name= isDrone and properties.Tag.Value or properties.Parent.Name
		isNPC = true
		model = NPCs[name]
	end

	if name == nil then return end

	local listing = hitpart.hit:FindFirstChild(name)
	if not listing then
		listing = Instance.new("StringValue")
		listing.Name = name
		listing.Value = tick() - 2
		listing.Parent = hitpart.hit
	end

	if tick() - listing.Value >= 2 then
		listing.Value = tick()
		if isNPC then
			_G.damageNPC(model,nil,damage,"Vehicle",3)
		else
			_G.damagePlayer(model,nil,damage,"Vehicle",3)
		end
	end
end

local hitpart=workspace.hitPart
local hitpart2=workspace.hitPart2

for _,hitpart in {hitpart,hitpart2} do 
	local train=hitpart.train.Value
	local speed=train.speed.Value
	hitpart.Touched:Connect(function(BasePart)
		part_hit(BasePart,speed,hitpart)
	end)
end

local function Move_Train(train,node,ahead,hitpart,distance,travelled,start)
	local p=(tick()-start)/1
	local speed=train.speed
	local move=speed.Value*p
	travelled+=move
	local cf=node.Value:Lerp(ahead.Value,travelled/distance)
	train.GoalCFrame.Value=cf
	--train.CFrame=cf
	
	local hitbox_offset=train.hitboxOffset.Value
	local x,y,z=hitbox_offset:ToOrientation()
	local pos=hitbox_offset.Position
	local min_Z=36 -- fastest
	local max_Z=53.6 -- slowest
	local progress=1-(speed.Value/36)
	local new_Z=progress*(max_Z-min_Z)+min_Z
	new_Z*=-1	
	local offsetCF=CFrame.new(pos.X,pos.Y,new_Z)*CFrame.fromOrientation(x,y,z)
	
	hitpart.OffsetCFrame.Value=offsetCF
	--hitpart.CFrame=cf*offsetCF
	train.node.Value=node
	train.progress.Value=travelled/distance
	return travelled
end

local rs=game:GetService("ReplicatedStorage")

local track1={}
track1.excess=0
track1.travelled=0
track1.iteration=0
track1.nodes=rs.inner_track
track1.hitpart=workspace.hitPart
track1.train=workspace.train1

local track2={}
track2.excess=0
track2.travelled=0
track2.iteration=0
track2.nodes=rs.outer_track
track2.hitpart=workspace.hitPart2
track2.train=workspace.train2

while true do
	local start=tick()
	task.wait()
	for _,track in {track1,--[[track2]]} do 
		local nodes=track.nodes
		local node=nodes:FindFirstChild("node"..track.iteration)
		local ahead=Get_Ahead_Node(node,nodes)
		local distance=(node.Value.Position-ahead.Value.Position).Magnitude
		track.travelled=Move_Train(track.train, node, ahead, track.hitpart, distance, track.travelled, start)
		if track.travelled/distance>=1 then
			local _next=track.iteration+1
			local n=#track.nodes:GetChildren()
			track.iteration=_next > n-1 and 0 or _next
			track.travelled-=distance
		end
	end
end

--[[
Step1: Place the 1st cart
Step2: Use position data of 1st cart to place the 2nd cart
Step3: Couple 1st & 2nd cart
Step4: Repeat this on the rest of the carts

issue:
	the carts are sometimes too far apart or too close
cause:
	distance of current node to ahead node isn't the same distance as you used
solution:
	
]]
