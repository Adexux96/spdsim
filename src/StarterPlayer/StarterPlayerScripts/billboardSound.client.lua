local billboards=workspace:WaitForChild("billboards")

local current=0
while true do 
	task.wait(12)
	current+=1
	if current>2 then
		current=1
	end
	for _,billboard in billboards:GetChildren() do 
		if billboard.Name=="newsBillboard" then
			local screen=billboard:FindFirstChild("Screen")
			if not screen then continue end
			local sound=screen:FindFirstChild(tostring(current))
			if not sound then continue end
			sound:Play()
		end
	end
end
