local DS = game:GetService("DataStoreService"):GetDataStore("CashBoost")

local function updateBoostStatus(plr)
	local leaderstats=plr:WaitForChild("leaderstats")
	local CashBoost = leaderstats.CashBoost
	local active = CashBoost:WaitForChild("active")
	local duration = CashBoost:WaitForChild("duration")
	
	task.spawn(function()
		while true do
			if duration.Value > 0 then
				active.Value = true
				duration.Value = duration.Value - 1
			else
				active.Value = false
			end
			task.wait(1)
		end
	end)
end

local function PlayerRemoved(Player)
	local leaderstats = Player:WaitForChild("leaderstats")

	DS:SetAsync("duration"..Player.UserId, Player.leaderstats.CashBoost.duration.Value)
end

game.Players.PlayerAdded:Connect(updateBoostStatus)
game.Players.PlayerRemoving:Connect(PlayerRemoved)