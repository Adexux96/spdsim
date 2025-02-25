local teleports=workspace.Teleports
local rs=game:GetService("ReplicatedStorage")
local remote=rs.TeleportEvent
local sales=require(rs.sales)
local items=require(rs.items)

for index,teleport in teleports:GetChildren() do 
	local circle=teleport:WaitForChild("circle")
	local connecting=teleport:WaitForChild("Connecting")
	local proximityPrompt=circle:WaitForChild("ProximityPrompt")
	proximityPrompt.Triggered:Connect(function(plr)
		
		local lastTeleport=plr:GetAttribute("lastTeleport")
		if not lastTeleport then
			plr:SetAttribute("lastTeleport",tick()-.5)
			lastTeleport=plr:GetAttribute("lastTeleport")
		end
		local elapsed=tick()-lastTeleport
		if elapsed<.5 then return end
		plr:SetAttribute("lastTeleport",tick())
		
		local leaderstats=plr.leaderstats
		local objectives=leaderstats.objectives
		--local cash=leaderstats.Cash
		local portals=leaderstats.portals
		local value=portals[teleport.Name]
		if not value then return end -- make sure it exists
		if not value.Value then -- you're trying to purchase!
			local canAfford=objectives.completed.Value or objectives.current.Value>=items.Portals[teleport.Name]
			if canAfford then -- can afford!
				value.Value=true
			else -- can't afford!
				--local deficit=price-cash.Value
				--sales:PromptProduct(sales:ClosestProduct(deficit),plr)
			end
		else -- you're trying to teleport! 
			if teleport.Name=="bat" then
				leaderstats.tutorial.Thugs.Value=true
				if leaderstats.objectives.talkedWithPolice.Value then
					leaderstats.objectives.usedFirstPortal.Value=true
				end
			end
			remote:FireClient(plr,"Teleport",teleport)
			remote:FireAllClients("Effect",teleport)
		end
	end)
end
