local resetBindable = Instance.new("BindableEvent")

local resetEvent = game:GetService("ReplicatedStorage"):WaitForChild("ResetEvent")
local resetBindable = Instance.new("BindableEvent")
resetBindable.Event:Connect(function()
	resetEvent:FireServer()
end)

local success = false

while not success do
	success = pcall(function()
		game:GetService("StarterGui"):SetCore("ResetButtonCallback", resetBindable)
	end)
	if success then
		break
	end
	task.wait(1/30)
end