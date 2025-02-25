local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainPositionUpdate = ReplicatedStorage:WaitForChild("TrainPositionUpdate")

TrainPositionUpdate.OnClientEvent:Connect(function(cframe)
	local train = workspace:FindFirstChild("TrainSystem.Trains.Train")
	if train then
		train:SetPrimaryPartCFrame(cframe)
	end
end)