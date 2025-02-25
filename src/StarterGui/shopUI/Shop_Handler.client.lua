local ui=script.Parent
local container=ui:WaitForChild("container")
local bg_container=container:WaitForChild("bg_container")
local exit=bg_container:WaitForChild("5"):WaitForChild("exit")

local ts=game:GetService("TweenService")
local rotate_info=TweenInfo.new(20,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,-1,false,0)

local cash=container:WaitForChild("cash")
local best_deal=cash:WaitForChild("5")
local ray=best_deal:WaitForChild("ray")

local ray_rotate_tween

--[[
ui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if ui.Enabled then
		--print("true")
		ray.Rotation=0
		ray_rotate_tween=ts:Create(ray,rotate_info,{Rotation=360})
		ray_rotate_tween:Play()
	elseif ui.Enabled==false then
		--print("false")
		ray_rotate_tween:Cancel()
		ray_rotate_tween:Destroy()
		ray_rotate_tween=nil
		ray.Rotation=0
	end
end)
]]

local productIDs={
	["2652245835"]=1000,
	["2652246244"]=10000,
	["2652246456"]=50000,
	["2652246628"]=100000,
	["2652246812"]=250000,
	["2652246909"]=1000000
}

local MarketplaceService=game:GetService("MarketplaceService")

-- Function to prompt purchase of the Pass
local function promptPurchase(id)
	local player = game.Players.LocalPlayer
	local hasPass = false
	local product=productIDs[id]
	MarketplaceService:PromptProductPurchase(player, id)
	--[[
	local gamepass=gamepassIDs[id]
	
	if gamepass then
		local success, message = pcall(function()
			hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
		end)
		if not success then
			warn("Error while checking if player has pass: " .. tostring(message))
			return
		end
	end

	if hasPass then
		-- Player already owns the Pass; tell them somehow
		--print("you already own this pass!")
	else
		-- Player does NOT own the Pass; prompt them to purchase
		if gamepass then
			--print("gamepass")
			MarketplaceService:PromptGamePassPurchase(player, id)
		else 
			--print("product")
			MarketplaceService:PromptProductPurchase(player, id)
		end
	end
	]]
end

local rs=game:GetService("ReplicatedStorage")
local buttonSound2=rs:WaitForChild("ui_sound"):WaitForChild("button3")
local cash=container:WaitForChild("cash")
for _,slot in cash:GetChildren() do 
	if slot:IsA("Frame") then
		local id=slot:WaitForChild("id").Value
		slot:WaitForChild("button").Activated:Connect(function()
			buttonSound2:Play()
			promptPurchase(id)
		end)
	end
end

local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local temp=leaderstats:WaitForChild("temp")
local EarningsBoost=temp:WaitForChild("EarningsBoost")
local m=require(rs:WaitForChild("math"))

local function UpdateCashPrices()
	for _,slot in cash:GetChildren() do 
		if slot:IsA("UIListLayout") then continue end
		local id=slot:WaitForChild("id")
		local text=slot:WaitForChild("top"):WaitForChild("Folder"):WaitForChild("text")
		local price=productIDs[id.Value]
		--print("price=",price)
		local new=price+math.round(price*EarningsBoost.Value)
		new=math.floor(new/100+.5)*100
		--print("new1=",new)
		new=m.giveNumberCommas(new)
		--print("new=",new)
		text.Text=new
	end
end

EarningsBoost:GetPropertyChangedSignal("Value"):Connect(UpdateCashPrices)

UpdateCashPrices()
