local Players =game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")


local productFunctions = {}

productFunctions[2662726640] = function(receipt, player)
	local leaderstats = player.leaderstats
	local spin = leaderstats.spins.Spins
	
	if spin then
		spin.Value += 1
		return true
	end
end

productFunctions[2662731939] = function(receipt, player)
	local leaderstats = player.leaderstats
	local spin = leaderstats.spins.Spins

	if spin then
		spin.Value += 10
		return true
	end
end

local function processReceipt(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	
	local player = Players:GetPlayerByUserId(userId)
	
	if player then
		local handler = productFunctions[productId]
		local success, result = pcall(handler, receiptInfo, player)
		if success then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			warn("Failed to process receipt:", receiptInfo, result)
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.ProcessReceipt = processReceipt