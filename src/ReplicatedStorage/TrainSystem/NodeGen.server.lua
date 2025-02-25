repeat
task.wait(1)
until workspace:FindFirstChild("TrainSystem")

local All = script.Parent
local Remake = Instance.new("BindableEvent", script.Parent)
local nodes = All.Nodes
local Track = All.Track
local Trash = Instance.new("Folder", script)
local Cou = 0
local Last = nodes.Start
local Nair = nil
local LowDist = 0
Remake.Name = "RebuildTrack"

local function createNode(order, nodeRef, align, process, to)
	local Pos = Instance.new("Part", to)
	local nextNode = Instance.new("ObjectValue", Pos)
	nextNode.Name = "NextNode"
	Cou = Cou + 1
	Pos.Name = "Node_" .. Cou
	Pos.Anchored = true
	Pos.CanCollide = false
	Pos.CFrame = nodeRef.CFrame * CFrame.new(0, 0, align * (nodeRef.Size.Z / 2))
	Pos.Transparency = 1
	if process == "End" then
		local End = Instance.new("ObjectValue", Pos)
		End.Name = "End"
	end
	Last = Pos
	Nair = nil
end

Last.Parent = Trash
createNode(1, Last, 1, "", nodes)

for c, v in pairs(Track:GetChildren()) do
	if v:IsA("Part") then
		for x, n in pairs(Track:GetChildren()) do
			local Dist = (Last.Position - n.Position).Magnitude
			if x == 1 or LowDist > Dist then
				LowDist = Dist
				Nair = n
			end
		end
		if Nair ~= nil then
			Nair.Parent = Trash
			if c == #Track:GetChildren() then
				createNode(c + 1, v, 1, "End", nodes)
			else
				createNode(c + 1, Nair, 1, "Connect", nodes)
			end
		end
	end
end

for _, node in pairs(nodes:GetChildren()) do
	local nextNode = node.NextNode
	local order = tonumber(node.Name:match('%d+'))
	if nodes:FindFirstChild("Node_" .. (order + 1)) then
		nextNode.Value = nodes:FindFirstChild("Node_" .. (order + 1))
	end
end

task.wait()
Trash:ClearAllChildren()
Track:Destroy()
All.NodeReady.Value = true

Remake.Event:Connect(function(train)
	Nair = nil
	LowDist = 0
	Cou = 0
	if nodes:FindFirstChild("Node_" .. #nodes:GetChildren()) then
		local Last = nodes:FindFirstChild("Node_" .. #nodes:GetChildren())
		local firstNode = nodes:FindFirstChild("Node_" .. 1)
		if firstNode then
			firstNode.Name = "Node_" .. (#nodes:GetChildren() + 1)
		end
		Cou = Cou + 1
		Last.Name = "Node_" .. Cou
		for c, v in pairs(nodes:GetChildren()) do
			if v:IsA("BasePart") then
				for _, Spwn in pairs(nodes:GetChildren()) do
					local Dist = (Last.Position - Spwn.Position).Magnitude
					if LowDist > Dist then
						LowDist = Dist
						Nair = Spwn
					end
				end
				if Nair ~= nil then
					Cou = Cou + 1
					Last = Nair
					Last.Name = "Node_" .. Cou
				end
			end
		end
		for _, node in pairs(nodes:GetChildren()) do
			local nextNode = node.NextNode
			local order = tonumber(node.Name:match('%d+'))
			if nodes:FindFirstChild("Node_" .. (order + 1)) then
				nextNode.Value = nodes:FindFirstChild("Node_" .. (order + 1))
			end
		end
	end
end)