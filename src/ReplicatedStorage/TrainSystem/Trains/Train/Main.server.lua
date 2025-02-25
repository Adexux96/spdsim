local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainPositionUpdate = ReplicatedStorage:WaitForChild("TrainPositionUpdate")

local Speed = {
	Travel = math.random(20, 50),
}
local SpeedUp = true
local Throttle = Speed.Travel
local All = script.Parent
repeat
	task.wait()
until All.Parent.Parent.NodeReady.Value and All:FindFirstChild("Settings")
local Settings = All:FindFirstChild("Settings")
local Choice = Settings:FindFirstChild("Choice")
local nodes = All.Parent.Parent.Nodes
local total = 0
for i, z in pairs(All:GetChildren()) do
	if z:IsA("Model") then
		total = i
	end
end
total = total - 2
if Choice and Choice:FindFirstChild("TotalCars") then
	if Choice.Value then
		if #All:GetChildren() - 2 <= Choice.TotalCars.Value then
			local Correct = Choice.TotalCars.Value - total
			local v = All:FindFirstChild("Car" .. total)
			v.Name = "Car" .. Choice.TotalCars.Value
			for i = 1, Correct - 1 do
				local New = All:FindFirstChild("Car" .. 2):Clone()
				New.Part.CFrame = New.Part.CFrame + Vector3.new(0, 0, -20 * i)
				New.Parent = All
				New.Name = "Car" .. total + 1
				New.Base.CFrame = New.Base.CFrame + Vector3.new(0, 0, -20 * i)
				total = total + 1
				task.wait()
			end
		end
	end
end
All = script.Parent
for i, v in pairs(All:GetChildren()) do
	if v:IsA("Model") then
		total = i
		local function SetStartingNode()
			local train = v
			local loco = train.Locomotive
			local front = loco.Front
			local back = loco.Back
			front.Current.Value = nodes:FindFirstChild("Node_1")
			back.Current.Value = nodes:FindFirstChild("Node_1")
		end
		SetStartingNode()
	end
end
local cont = true
game:GetService("RunService").Heartbeat:Connect(function(dt)
	for i = 1, total - 2 do
		local v = All:FindFirstChild("Car" .. tostring(i))
		if cont == true then
			if v and v:IsA("Model") then
				local train = v
				local loco = train.Locomotive
				local front = loco.Front
				local back = loco.Back
				local base = train.Base
				local gap = (front.Position - back.Position).Magnitude
				local function NextNode(target)
					local nextNode = target.Current.Value.NextNode.Value
					if nextNode then
						target.Current.Value = nextNode
					else
						target.Current.Value = nodes:FindFirstChild("Node_1")
					end
				end
				local function Move(target, dt)
					if target:FindFirstChild("Current") then
						local curNode = target.Current.Value
						local nextNode = target.Current.Value.NextNode.Value or nodes:FindFirstChild("Node_1")
						local distanceTraveledOnSection = (target.Position - curNode.Position).Magnitude
						local sectionLength = (nextNode.Position - curNode.Position).Magnitude
						local alpha = (distanceTraveledOnSection + Throttle * dt) / sectionLength
						if alpha >= 1 then
							if SpeedUp and Throttle <= Speed.Travel then
								Throttle = Throttle + 1
							end
							NextNode(target)
						else
							target.CFrame = curNode.CFrame:Lerp(nextNode.CFrame, alpha)
						end
					else
						for z, c in pairs(All:GetChildren()) do
							if c:IsA("Model") then
								total = z
								local function SetStartingNode()
									local train = c
									local loco = train.Locomotive
									local front = loco.Front
									local back = loco.Back
									front.Current.Value = nodes:FindFirstChild("Node_1")
									back.Current.Value = nodes:FindFirstChild("Node_1")
								end
								SetStartingNode()
							end
						end
					end
				end
				Move(front, dt)
				Move(back, dt)
				base.CFrame = CFrame.new(back.Position, front.Position) * CFrame.new(0, 7.5, -gap / 2)

				TrainPositionUpdate:FireAllClients(base.CFrame)
			end
		end
	end
end)