local rs=game:GetService("ReplicatedStorage")
local codeRemote=rs.CodeRemote
local AnalyticsService = game:GetService("AnalyticsService")

local requiredIDs={
	["Biffle"]=3568451957
}

codeRemote.OnServerEvent:Connect(function(plr,code)
	local leaderstats=plr.leaderstats
	local codes=leaderstats.codes
	local temp = leaderstats.temp
	local earningBoost = temp.EarningsBoost
	local validCode=codes:FindFirstChild(code)
	local IdRequired=requiredIDs[code]
	if IdRequired and plr.UserId~=IdRequired then return end
	if validCode and validCode.Redeemed.Value==false then
		validCode.Redeemed.Value=true
		leaderstats.Cash.Value+= (earningBoost.Value * validCode.Reward.Value) + validCode.Reward.Value
		
		AnalyticsService:LogEconomyEvent(
			plr,
			Enum.AnalyticsEconomyFlowType.Source,
			"Cash",
			validCode.Reward.Value,
			leaderstats.Cash.Value,
			Enum.AnalyticsEconomyTransactionType.Onboarding.Name,
			"Codes"
		)
	end
end)
