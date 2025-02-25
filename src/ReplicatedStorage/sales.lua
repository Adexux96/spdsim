local marketplaceService=game:GetService("MarketplaceService")
local sales = {}

sales.gamepassIDs={
	["957141741"]="Collector",
	["957115694"]="test"
}

sales.productIDs={
	["2652245835"]=1000,
	["2652246244"]=10000,
	["2652246456"]=50000,
	["2652246628"]=100000,
	["2652246812"]=250000,
	["2652246909"]=1000000
}

sales.donationIDs={
	["2652255501"]=10,
	["2652255691"]=25,
	["2652255786"]=100,
	["2652255892"]=500,
	["2652255966"]=1000,
	["2652256049"]=5000,
	["2652256192"]=10000,
	["2652256342"]=100000
}

local function least(a,b)
	return sales.productIDs[a]<sales.productIDs[b]
end

function sales:ClosestProduct(deficit)
	--print("deficit=",deficit)
	local t={}
	for id,amount in self.productIDs do 
		local plr=game.Players.LocalPlayer 
		local EarningsBoost=plr:WaitForChild("leaderstats"):WaitForChild("temp"):WaitForChild("EarningsBoost")
		amount=amount+math.round(amount*EarningsBoost.Value)
		amount=math.floor(amount/100+.5)*100 -- round to nearest hundred
		if deficit<=amount then -- edit this 
			--print(amount)
			t[#t+1]=id
		end
	end
	table.sort(t,least)
	return t[1] or "2652246909" -- if it's too big, just prompt the most
end

function sales:GetProductType(id)
	local gamepass=self.gamepassIDs[id] and true or false
	local product=self.productIDs[id] and true or false
	return gamepass,product
end

function sales:GamepassOwnership(id:number, player:Player)
	local hasPass=false
	local success, message = pcall(function()
		hasPass = marketplaceService:UserOwnsGamePassAsync(player.UserId, id)
	end)
	if not success then
		warn("Error while checking if player has pass: " .. tostring(message))
	end
	return hasPass
end

function sales:PromptProduct(id, player)
	marketplaceService:PromptProductPurchase(player, id)
end

function sales:PromptGamepass(id, player)
	marketplaceService:PromptGamePassPurchase(player, id)
end

return sales