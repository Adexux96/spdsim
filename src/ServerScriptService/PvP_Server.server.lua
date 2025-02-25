local pvpEvent=game:GetService("ReplicatedStorage").pvpEvent

pvpEvent.OnServerEvent:Connect(function(player)
	local pvp=player.leaderstats.temp.PvP
	local last=pvp:GetAttribute("Last")
	if not last then
		last=workspace:GetServerTimeNow()-10
		pvp:SetAttribute("Last",last)
	end
	local elapsed=workspace:GetServerTimeNow()-last
	if elapsed<10 then return end -- don't allow past this point if not enough time has elapsed
	pvp:SetAttribute("Last",workspace:GetServerTimeNow())
	local last_combat=player:GetAttribute("LastCombat") or -5
	if workspace:GetServerTimeNow()-last_combat<5 then return end -- don't allow past this point if was in combat recently
	pvp.Value=not pvp.Value
	local s=pvp.Value and "on" or "off"
	pvpEvent:FireClient(player,"PvP was turned "..s)
end)

