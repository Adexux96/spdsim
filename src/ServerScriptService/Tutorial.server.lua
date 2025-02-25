local rs=game:GetService("ReplicatedStorage")
local drag=rs.DragEvent
local roll=rs.RollEvent

drag.OnServerEvent:Connect(function(plr,name)
	local leaderstats=plr.leaderstats
	local tutorial=leaderstats.tutorial
	tutorial.Drag.Value=true
end)

roll.OnServerEvent:Connect(function(plr)
	local leaderstats=plr.leaderstats
	local tutorial=leaderstats.tutorial
	tutorial.Roll.Value=true
end)