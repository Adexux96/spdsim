local Players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local DS = game:GetService("DataStoreService"):GetDataStore("SpinService")
local SpinEvent = rs:WaitForChild("Spin")
local SpinModule = require(rs:WaitForChild("SpinModule"))

local function getCurrentTimestamp()
	return os.time()
end

local function getTimeRemaining(nextSpinTime)
	local currentTime = getCurrentTimestamp()
	return math.max(0, nextSpinTime - currentTime)
end


local function updateTimeForReward(player)
	local leaderstats = player:WaitForChild("leaderstats")
	local spins = leaderstats.spins
	local Spin = spins.Spins
	local SpinTime = spins.SpinTime
	
	Spin.Value = DS:GetAsync("Spin"..player.UserId) or 1
	
	local nextSpinTimestamp = DS:GetAsync("NextSpinTime"..player.UserId)
	
	if not nextSpinTimestamp or nextSpinTimestamp < getCurrentTimestamp() then
		nextSpinTimestamp = getCurrentTimestamp() + SpinModule.Spin.SpinTimeForReward
		DS:SetAsync("NextSpinTime"..player.UserId, nextSpinTimestamp)
	end
	
	SpinTime.Value = getTimeRemaining(nextSpinTimestamp)
	
	spawn(function()
		while task.wait(1) do
			local timeRemaining = getTimeRemaining(nextSpinTimestamp)
			SpinTime.Value = timeRemaining

			if timeRemaining == 0 then
				Spin.Value += 1
				nextSpinTimestamp = getCurrentTimestamp() + SpinModule.Spin.SpinTimeForReward
				DS:SetAsync("NextSpinTime"..player.UserId, nextSpinTimestamp)
			end
		end
	end)
end

local function PlayerRemoved(Player)
	local leaderstats = Player:WaitForChild("leaderstats")
	
	DS:SetAsync("SpinTime"..Player.UserId, Player.leaderstats.spins.SpinTime.Value)
	DS:SetAsync("Spin"..Player.UserId, Player.leaderstats.spins.Spins.Value)
end

local function SpinEventFire(Player, SpinReward)
	local leaderstats = Player:WaitForChild("leaderstats")
	local temp = leaderstats:WaitForChild("temp")
	local skins = leaderstats:WaitForChild("skins")
	local spins = leaderstats:WaitForChild("spins")
	local Spin = spins:WaitForChild("Spins")
	if Spin.Value >= 1 then
		Spin.Value -= 1
		local reward = SpinReward
		if SpinReward == "Spectacular" then
			
			local spectacular = skins:WaitForChild("Spectacular")
			
			if spectacular.Unlocked.Value == true then
				leaderstats.Cash.Value+= 10000
			end
			
			spectacular.Unlocked.Value = true
			
		elseif SpinReward == "Black Spectacular" then
			
			local spectacular = skins:WaitForChild("Black Spectacular")
			
			if spectacular.Unlocked.Value == true then
				leaderstats.Cash.Value+= 10000
			end
			
			spectacular.Unlocked.Value = true
			
		elseif SpinReward == "Cash" then
			
			local earningBoost = temp.EarningsBoost
			
			leaderstats.Cash.Value+= (earningBoost.Value * 1000) + 1000
						
		elseif SpinReward == "Comic Pages" then
			
			leaderstats["Comic pages"].Value+= 1000
						
		elseif SpinReward == "Spin" then
			
			Spin.Value+= 1
						
		elseif SpinReward == "X2 Cash" then
			
		leaderstats.CashBoost.duration.Value+=600	
						
		elseif SpinReward == "X2 Comic Pages" then
			
		leaderstats.ComicPagesBoost.duration.Value+=600
						
		end
	end
end

Players.PlayerAdded:Connect(updateTimeForReward)
Players.PlayerRemoving:Connect(PlayerRemoved)
SpinEvent.OnServerEvent:Connect(SpinEventFire)