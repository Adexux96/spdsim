local SocialService=game:GetService("SocialService")

local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local incentives=leaderstats:WaitForChild("incentives")

local function InviteRequest(briefcase)
	local plr=game.Players.LocalPlayer
	-- Function to check whether the player can send an invite

	if briefcase.Name=="Invite" then
		local function canSendGameInvite(sendingPlayer)
			local success, canSend = pcall(function()
				return SocialService:CanSendGameInviteAsync(sendingPlayer)
			end)
			return success and canSend
		end

		local canInvite = canSendGameInvite(plr)
		if canInvite then
			local inviteOptions = Instance.new("ExperienceInviteOptions")
			inviteOptions.InviteMessageId="887aa63c-049b-3b4f-96aa-5fbf1645741b"
			local success, errorMessage = pcall(function()
				SocialService:PromptGameInvite(plr,inviteOptions)
			end)
		end
		task.wait(5)
		briefcase:Destroy()
		return
	end
	
	briefcase:Destroy()
end

local rs=game:GetService("ReplicatedStorage")
rs:WaitForChild("IncentiveRequest").OnClientEvent:Connect(InviteRequest)

if incentives:WaitForChild("like").Value then
	local like=workspace:WaitForChild("Like")
	like:Destroy()
end

if incentives:WaitForChild("invite").Value then
	local invite=workspace:WaitForChild("Invite")
	invite:Destroy()
end