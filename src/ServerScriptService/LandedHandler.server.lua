local rs=game:GetService("ReplicatedStorage")
local LandedEvent=rs.LandedEvent

LandedEvent.OnServerEvent:Connect(function(plr)
	local timer=workspace:GetServerTimeNow()
	for _,player in game.Players:GetPlayers() do 
		if player~=plr then
			LandedEvent:FireClient(player,plr,timer)
		end
	end
end)
