local camera = workspace.CurrentCamera
local button = script.Parent.button

local n = 1

local characters = workspace:WaitForChild("characters")

local suits = {}

for i,suit in pairs(characters:GetChildren()) do 
	suits[#suits+1] = suit
end

local isRunning = false

local function setScene()
	isRunning = true
	while true do 
		local character = suits[n]
		if not character then print("no character found") break end
		local root = character:FindFirstChild("HumanoidRootPart")--character:WaitForChild("HumanoidRootPart")
		if not root then print("no root found") break end
		local offsetCF = root.CFrame * CFrame.new(0,1,-10.5)
		--local offsetCF = root.CFrame * CFrame.new(0,1,-40.5)
		camera.CameraType=Enum.CameraType.Scriptable
		camera.CFrame = CFrame.new(offsetCF.Position,root.Position)	
		game:GetService("RunService").RenderStepped:Wait()
	end	
	camera.CameraType=Enum.CameraType.Custom
	isRunning=false
end

local function switchCameraScene()
	if n == #suits then
		n = 0
	end
	n+=1
	if not isRunning then
		setScene()
	end
end

button.Activated:Connect(switchCameraScene)

