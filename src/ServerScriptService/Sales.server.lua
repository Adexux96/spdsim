local rs=game:GetService("ReplicatedStorage")
local sales=require(rs.sales)
local dataManager = require(rs:WaitForChild("dataManager"))
local marketplaceService=game:GetService("MarketplaceService")
local AnalyticsService = game:GetService("AnalyticsService")

local function GamepassOwnershipChanged(plr,id)
	local gamepassName=sales.gamepassIDs[id]
	if not gamepassName then return end
	if sales:GamepassOwnership(id,plr) then
		local leaderstats=plr:FindFirstChild("leaderstats")
		if not leaderstats or not leaderstats:FindFirstChild("gamepasses") then return end
		local value=leaderstats.gamepasses:FindFirstChild(gamepassName)
		if value then
			value.Value=true
		end
	end
end

local function ProductFinished(userID,productID,wasPurchased)
	if wasPurchased==false then --[[print("wasn't purchased")]] return end
	local plr=game.Players:GetPlayerByUserId(userID)
	local amount=sales.productIDs[tostring(productID)]
	--// since the only products are cash, just add cash to player's cash value
	plr.leaderstats.Cash.Value+=amount
	
	AnalyticsService:LogEconomyEvent(
		plr,
		Enum.AnalyticsEconomyFlowType.Source,
		"Cash",
		amount,
		plr.leaderstats.Cash.Value,
		Enum.AnalyticsEconomyTransactionType.IAP.Name,
		"Dev Products"
	)
end

local function GamepassFinished(plr,gamepassID,wasPurchased)
	if wasPurchased==false then --[[print("wasn't purchased")]] return end
	local gamepassName=sales.gamepassIDs[tostring(gamepassID)]
	--// since the only products are cash, just add cash to player's cash value
	local value=plr.leaderstats.gamepasses:FindFirstChild(gamepassName)
	if value then
		value.Value=true
	end
end

--marketplaceService.PromptProductPurchaseFinished:Connect(ProductFinished)
--marketplaceService.ProcessReceipt:Connect(ProductFinished)
marketplaceService.PromptGamePassPurchaseFinished:Connect(GamepassFinished)


local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Data store for tracking purchases that were successfully processed
local purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")

-- The core 'ProcessReceipt' callback function
local function processReceipt(receiptInfo)
	-- Determine if the product was already granted by checking the data store
	local playerProductKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
	local purchased = false
	local success, result, errorMessage

	success, errorMessage = pcall(function()
		purchased = purchaseHistoryStore:GetAsync(playerProductKey)
	end)
	
	-- If purchase was recorded, the product was already granted
	if success and purchased then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif not success then
		error("Data store error:" .. errorMessage)
	end

	-- Determine if the product was already granted by checking the data store  
	local playerProductKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId

	local success, isPurchaseRecorded = pcall(function()
		return purchaseHistoryStore:UpdateAsync(playerProductKey, function(alreadyPurchased)
			if alreadyPurchased then
				return true
			end

			-- Find the player who made the purchase in the server
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				-- The player probably left the game
				-- If they come back, the callback will be called again
				return nil
			end
			
			local cash=sales.productIDs[tostring(receiptInfo.ProductId)]
			local donation=sales.donationIDs[tostring(receiptInfo.ProductId)]
			
			if cash then
				local amount=cash
				--// since the only products are cash, just add cash to player's cash value
				local plr=game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
				amount=amount+math.round(amount*plr.leaderstats.temp.EarningsBoost.Value)
				amount=math.floor(amount/100+.5)*100 -- round to nearest hundred
				plr.leaderstats.Cash.Value+=amount

				AnalyticsService:LogEconomyEvent(
					plr,
					Enum.AnalyticsEconomyFlowType.Source,
					"Cash",
					amount,
					plr.leaderstats.Cash.Value,
					Enum.AnalyticsEconomyTransactionType.IAP.Name,
					"Dev Products"
				)
			end
			
			if donation then
				local amount=donation
				--// since the only products are cash, just add cash to player's cash value
				local plr=game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
				plr.leaderstats.Donations.Donated.Value+=amount
			end
			
			-- Record the transcation in purchaseHistoryStore.
			return true
		end)
	end)

	if not success then
		error("Failed to process receipt due to data store error.")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	elseif isPurchaseRecorded == nil then
		-- Didn't update the value in data store.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	else	
		-- IMPORTANT: Tell Roblox that the game successfully handled the purchase
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

-- Set the callback; this can only be done once by one script on the server!
MarketplaceService.ProcessReceipt = processReceipt


while true do 
	for _,player in game.Players:GetPlayers() do 
		GamepassOwnershipChanged(player,"112925601")
		GamepassOwnershipChanged(player,"112926439")
	end
	task.wait(5)
end