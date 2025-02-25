local runService = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")
local clock = rs:WaitForChild("clock")

local n = 0
game:GetService("RunService").RenderStepped:Connect(function(dt)
	n += dt
	if n >= 1/60 then
		clock.Value = tick()
		n -= 1/60
	end
end)
