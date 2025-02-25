local module = {
	["Spin"] = {
		["SpinTime"] = 3,
		["SpinTimeForReward"] = 86400,
		["Rewards"] = {
			["Spectacular"] = { ["Rarity"] = 8 },
			["Black Spectacular"] = { ["Rarity"] = 8 },
			["Comic Pages"] = { ["Rarity"] = 21 },
			["Nothing"] = { ["Rarity"] = 18 },
			["X2 Comic Pages"] = { ["Rarity"] = 7 },
			["Cash"] = { ["Rarity"] = 21 },
			["Spin"] = { ["Rarity"] = 10 },
			["X2 Cash"] = { ["Rarity"] = 7 },
		},
	},
}
	local totalChance = 0
	for _, rewardData in pairs(module.Spin.Rewards) do
		totalChance = totalChance + rewardData.Rarity
	end

	local cumulativeRarities = {}
	local accumulatedChance = 0
	for rewardName, rewardData in pairs(module.Spin.Rewards) do
		accumulatedChance = accumulatedChance + rewardData.Rarity
		table.insert(cumulativeRarities, { name = rewardName, threshold = accumulatedChance })
	end

	module.getRandomReward = function()
		local randomValue = math.random() * totalChance
		for _, entry in ipairs(cumulativeRarities) do
			if randomValue <= entry.threshold then
				return entry.name
			end
		end
		
	return nil
end

return module
