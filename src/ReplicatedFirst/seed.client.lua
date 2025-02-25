local rs = game:GetService("ReplicatedStorage")
local seedRemote = rs:WaitForChild("seed")

local player = game.Players.LocalPlayer
local randomSeed = player:WaitForChild("leaderstats"):WaitForChild("temp"):WaitForChild("randomSeed")

local rng = Random.new(tonumber(randomSeed.Value))

local function readValues()
	local randoms = {}
	
	for i = 1,5 do 
		randoms[#randoms+1] = rng:NextNumber(1,100)
	end
	
	for i = 1,#randoms do 
		print(i," = ",randoms[i])
	end
	
	seedRemote:FireServer()
end

local seedBrick = workspace:WaitForChild("seedBrick")
seedBrick.ClickDetector.MouseClick:Connect(readValues)
