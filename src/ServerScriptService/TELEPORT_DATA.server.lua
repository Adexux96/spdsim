game.Players.PlayerAdded:Connect(function(plr)
	if plr:GetJoinData().TeleportData then
		print(plr:GetJoinData().TeleportData.data[1])
	end
end)