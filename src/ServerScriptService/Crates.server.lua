local crates=workspace.crates

local rewards=require(script.Parent.Rewards)
local _math=require(game:GetService("ReplicatedStorage").math)
local debris=game:GetService("Debris")


local function least(a,b)
	return a[1] < b[1]
end

local function Get_Random(array)
	local n = _math.defined(0,100)
	table.sort(array,least)
	local total = 0
	for index,value in pairs(array) do
		local percent=value[1]+total
		total=percent
		if n <= percent then
			return value[2]
		end
	end
end

local types={
	[1]={25,"Comic"},
	[2]={75,"Money"}
}

local drops = {
	[1] = {5,100}, 
	[2] = {20,75}, 
	[3] = {30,50}, 
	[4] = {45,25}
}

local function respawn_crate(crate)
	crate.PrimaryPart.Transparency=0
	crate.PrimaryPart.CanCollide=true
	crate.PrimaryPart.ProximityPrompt.Enabled=true
end

local function open_crate(crate, plr)
	crate.opened.Value=tick()
	crate.PrimaryPart.Sound:Play()
	local topClone=crate.top:Clone()
	topClone.Parent=crate 
	local bottomClone=crate.bottom:Clone()
	bottomClone.Parent=crate 
	crate.PrimaryPart.Transparency=1
	crate.PrimaryPart.CanCollide=false
	for i,v in {topClone,bottomClone} do 
		v.Transparency=0
		v.Anchored=false
		v.CanCollide=true
		debris:AddItem(v,3)
	end
	--topClone.BodyVelocity.Velocity=Vector3.new(_math.defined(-5,5),2.5,_math.defined(-5,5))
	topClone.BodyVelocity.Velocity=Vector3.new(0,2.5,0)
	debris:AddItem(topClone.BodyVelocity,1)
	
	local amount=Get_Random(drops)*5
	local category=Get_Random(types)
	
	local leaderstats=plr.leaderstats
	local temp = leaderstats.temp
	local earningBoost = temp.EarningsBoost
	
	if category == "Money" then
		amount = (earningBoost.Value * amount) + amount
	end
	
	--amount=category=="Money" and amount*5 or amount
	--print("category=",category)
	rewards:CreateDrop(crate.PrimaryPart.Position,amount,nil,category)
end

for _,crate in crates:GetChildren() do 
	crate.PrimaryPart.ProximityPrompt.Triggered:Connect(function(plr)
		local lastOpen=plr:GetAttribute("lastOpen")
		if not lastOpen then
			plr:SetAttribute("lastOpen",tick()-1)
			lastOpen=plr:GetAttribute("lastOpen")
		end
		local elapsed=tick()-lastOpen
		if elapsed<1 then return end
		plr:SetAttribute("lastOpen",tick())
		open_crate(crate, plr)
	end)
	crate.opened:GetPropertyChangedSignal("Value"):Connect(function()
		crate.PrimaryPart.ProximityPrompt.Enabled=false
		task.wait(30)
		respawn_crate(crate)
	end)
end


