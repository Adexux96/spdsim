
local Players = game:GetService("Players")
local player = game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local temp=leaderstats:WaitForChild("temp")
local isWebbing=temp:WaitForChild("isWebbing")
local isRolling=temp:WaitForChild("isRolling")

local RunService = game:GetService('RunService')
local cs=game:GetService("CollectionService")

local LastTrainCFrame

local rs=game:GetService("ReplicatedStorage")
local clock=rs:WaitForChild("clock")

while true do 
	--------------------------------------------------------------- CHECK PLATFORM BELOW

	local character=player.Character
	if not character or not character.PrimaryPart then
		task.wait()
		continue
	end
	
	if isWebbing.Value or isRolling.Value or cs:HasTag(character,"ragdolled") then
		task.wait()
		continue
	end -- don't move along platform while swinging webs
	
	local RootPart = character.PrimaryPart
	local Ignore = character
	local ray = Ray.new(RootPart.CFrame.p,Vector3.new(0,-15,0))

	local Hit, Position, Normal, Material = workspace:FindPartOnRay(ray,Ignore)

	if (Hit and Hit.Name == "Car") or (Hit and Hit.Parent and Hit.Parent.Name:match("Cart") and Hit.Name=="Body") then -- Change "RaftTop" to whatever the moving part's name is

		--------------------------------------------------------------- MOVE PLAYER TO NEW POSITON FROM OLD POSITION

		local Train = Hit
		if LastTrainCFrame == nil then -- If no LastTrainCFrame exists, make one!
			LastTrainCFrame = Train.CFrame -- This is updated later.
		end
		local TrainCF = Train.CFrame 

		local Rel = TrainCF * LastTrainCFrame:inverse()

		LastTrainCFrame = Train.CFrame -- Updated here.

		RootPart.CFrame = Rel * RootPart.CFrame -- Set the player's CFrame
		--print("set")

	else
		LastTrainCFrame = nil -- Clear the value when the player gets off.

	end

	local move=math.sin(math.pi*tick())

	local platform=workspace:FindFirstChild("Platform")
	if platform then
		platform.CFrame*=CFrame.new(move/2,0,move)
	end
	
	--clock:GetPropertyChangedSignal("Value"):Wait()
	--RunService.Heartbeat:Wait()
	task.wait()
end