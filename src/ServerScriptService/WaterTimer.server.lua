local rs=game:GetService("ReplicatedStorage")
local runService=game:GetService("RunService")
local waterHeight=rs.waterHeight

runService.Stepped:Connect(function()
	waterHeight.Value=math.sin(tick())
end)
