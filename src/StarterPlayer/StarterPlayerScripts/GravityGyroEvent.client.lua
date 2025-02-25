local cs = game:GetService("CollectionService")
local rs = game:GetService("ReplicatedStorage")
local GravityGyroEvent = rs:WaitForChild("GravityGyroEvent")

local player = game.Players.LocalPlayer

local function rotateCharacterInGravityField()
	local character = player.Character 
	if not character then return end
	local i = 0
	if not cs:HasTag(character,"gravity") then
		repeat task.wait(1/30) i+=1 until i == 30 or cs:HasTag(character,"gravity")
	end
	if i == 30 then print("didn't have the gravity tag") return end
	local gyro = character.PrimaryPart:FindFirstChildOfClass("BodyGyro")
	local i = 0
	while character.Parent ~= nil and cs:HasTag(character,"ragdolled") do 
		if not cs:HasTag(character,"gravity") then print("didn't have the gravity tag") break end
		gyro = character.PrimaryPart:FindFirstChildOfClass("BodyGyro")
		if not gyro then
			gyro = Instance.new("BodyGyro")
			gyro.D = 100
			gyro.MaxTorque = Vector3.new(100000, 100000, 100000)
			gyro.P = 2000
			gyro.Parent = character.PrimaryPart	
		else 
			gyro.D = 100
			gyro.MaxTorque = Vector3.new(100000, 100000, 100000)
			gyro.P = 2000
		end
		if i == 360 then i = 0 end
		i+=2
		character:WaitForChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Physics)
		gyro.CFrame = CFrame.new(character.PrimaryPart.Position) * CFrame.Angles(math.rad(90),math.rad(0),math.rad(i))
		task.wait(1/30)
	end
	if gyro then
		gyro.MaxTorque = Vector3.new(0, 0, 0)
	end
end

GravityGyroEvent.OnClientEvent:Connect(rotateCharacterInGravityField)
