local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local temp=leaderstats:WaitForChild("temp")
local EarningsBoost=temp:WaitForChild("EarningsBoost")

local rs=game:GetService("ReplicatedStorage")
local earningsRemote=rs:WaitForChild("EarningsRemote")

EarningsBoost:GetPropertyChangedSignal("Value"):Connect(function()
	-- update the cash shop amounts
	print("update to x",EarningsBoost.Value," more cash")
end)