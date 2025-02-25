local screenGui = script.Parent
local avatarImage = screenGui:WaitForChild("Avatar")
local playerNameLabel = screenGui:WaitForChild("PlayerName")
local cashRewardLabel = screenGui:WaitForChild("CashReward")
local inviteButton = screenGui:WaitForChild("InviteButton")
local closeButton = screenGui:WaitForChild("CloseButton")
local socialService = game:GetService("SocialService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size100x100

local leaderstats=localPlayer:WaitForChild("leaderstats")
local temp = leaderstats:FindFirstChild("temp")
local earningBoost = temp:FindFirstChild("EarningsBoost")
local cashMath = (earningBoost.Value * 500) + 500
local cashRound = math.round(cashMath)

local suffixes = { "", "K", "M", "B", "T" }

function cashFormat()
	local i = math.floor(math.log(cashRound, 1e3)) 
	local v = math.pow(10, i * 3)
	local s = ("%.1f"):format(cashRound / v):gsub("%.?0+$", "") .. (suffixes[i + 1] or "")
	return s
end

local invitedFriendId = nil
local currentFriendInfo = nil

local function getRandomOnlineFriend()
	local friends = localPlayer:GetFriendsOnline()
	if #friends == 0 then
		return nil
	end
	return friends[math.random(1, #friends)]
end

local function displayInvite(friendInfo)
	
	currentFriendInfo = friendInfo
	
	local userId = friendInfo.VisitorId 
	local playerName = friendInfo.UserName
	local content, isReady = players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
	local cashReward = cashFormat(cashRound)

	avatarImage.Image = content 
	playerNameLabel.Text = playerName .. " is online!"
	cashRewardLabel.Text = "Invite for " .. cashReward .. " cash!"
	screenGui.Enabled = true
end

local function hideInviteUI()
	screenGui.Enabled = false
end

inviteButton.MouseButton1Click:Connect(function()
	local friendInfo = currentFriendInfo
	if friendInfo then
		local userId = friendInfo.VisitorId

		local inviteOptions = Instance.new("ExperienceInviteOptions")
		inviteOptions.InviteUser = userId
		
		local SocialService = game:GetService("SocialService")
		
		local function canSendGameInvite(sendingPlayer)
			local success, canSend = pcall(function()
				return SocialService:CanSendGameInviteAsync(sendingPlayer, userId)
			end)
			return success and canSend
		end
		
		local canInvite = canSendGameInvite(localPlayer)
		if canInvite then
			SocialService:PromptGameInvite(localPlayer, inviteOptions)
		end
		
		hideInviteUI()
	end
end)

players.PlayerAdded:Connect(function(newPlayer)
	local joinData = socialService:GetPlayerJoinData(newPlayer)
	if joinData and joinData.InvitedByUserId == invitedFriendId then
		local leaderstats = localPlayer:FindFirstChild("leaderstats")
		local cash = leaderstats:FindFirstChild("Cash")
		cash.Value = cash.Value + cashRound
		
		invitedFriendId = nil
			end
		end)		


closeButton.MouseButton1Click:Connect(function()
	hideInviteUI()
end)

local function showInviteRandomly()
	while true do
		local randomTime = math.random(15, 30)
		task.wait(randomTime)

		local friendInfo = getRandomOnlineFriend()
		if friendInfo then
			displayInvite(friendInfo)
		end
	end
end

screenGui.Enabled = false

showInviteRandomly()