local Like=workspace.Like
local Invite=workspace.Invite
local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")

local incentiveRequest=game.ReplicatedStorage.IncentiveRequest

local function InvitePrompted(plr) -- just prompt them the invite friends window and reward them
	-- check debounce if already did it too quickly
	if plr:GetAttribute("InvitePrompt") ~= nil then return end
	plr:SetAttribute("InvitePrompt",true)
	print("invite triggered, plr=",plr.Name)
	incentiveRequest:FireClient(plr,Invite)
	task.wait(5) -- wait 5 seconds then give the player cash
	if plr then
		local leaderstats=plr.leaderstats
		local cash=leaderstats.Cash
		cash.Value+=500
		leaderstats.incentives.invite.Value=true
		
		AnalyticsService:LogEconomyEvent(
			plr,
			Enum.AnalyticsEconomyFlowType.Source,
			"Cash",
			500,
			cash.Value,
			Enum.AnalyticsEconomyTransactionType.Onboarding.Name,
			"Invite"
		)
	end
	-- give cash
end

local function LikePrompted(plr) -- just check if they're in the group or not and reward them if they are
	-- check debounce if already did it too quickly
	if plr:IsInGroup(3735300) then
		if plr:GetAttribute("LikePrompt") then return end
		plr:SetAttribute("LikePrompt",true)
		incentiveRequest:FireClient(plr,Like)
		local leaderstats=plr.leaderstats
		local cash=leaderstats.Cash
		cash.Value+=500
		leaderstats.incentives.like.Value=true
		
		AnalyticsService:LogEconomyEvent(
			plr,
			Enum.AnalyticsEconomyFlowType.Source,
			"Cash",
			500,
			cash.Value,
			Enum.AnalyticsEconomyTransactionType.Onboarding.Name,
			"Group"
		)
	end
end

Like.PrimaryPart.ProximityPrompt.Triggered:Connect(LikePrompted)
Invite.PrimaryPart.ProximityPrompt.Triggered:Connect(InvitePrompted)