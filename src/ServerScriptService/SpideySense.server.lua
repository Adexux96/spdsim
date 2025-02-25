local remote=game.ReplicatedStorage.SpideySense 

remote.OnServerEvent:Connect(function(player)
	-- tell all clients that this player needs to show their spidey sense!
	remote:FireAllClients(player)
end)