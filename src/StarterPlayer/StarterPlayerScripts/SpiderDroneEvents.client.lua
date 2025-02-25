local drones=workspace:WaitForChild("SpiderDrones")

while true do 
	task.wait(1)
	if not _G.createSpiderDroneEvents then continue end
	for _,drone in drones:GetChildren() do 
		_G.createSpiderDroneEvents(drone)
	end
end
