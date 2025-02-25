local Spin = script.Parent:WaitForChild("Spin")
local SpinButton = script.Parent:WaitForChild("Button"):WaitForChild("ImageButton")

local TweenService = game:GetService("TweenService")

local Debounce = false
local SpinEvent = game:GetService("ReplicatedStorage"):WaitForChild("Spin")

local SpinModule = require(game:GetService("ReplicatedStorage"):WaitForChild("SpinModule"))

local Player = game:GetService("Players").LocalPlayer
local leaderstats = Player:WaitForChild("leaderstats")
local spins = leaderstats:WaitForChild("spins")
local SpinTime = spins:WaitForChild("SpinTime")
local SpinStats = spins:WaitForChild("Spins")

local function saniyeDakikaSaniyeCevirString(saniye)
	local saat = math.floor(saniye / 3600)     -- Get hours
	local kalanDakika = math.floor((saniye % 3600) / 60)  -- Get remaining minutes
	return string.format("%02d:%02d", saat, kalanDakika)
end

local function format(val)
	local suffixes = {'','k','m','b','t','qa','qi','sx','sp','oc'}
	for i=1, #suffixes do
		if tonumber(val) < 10^(i*3) then
			return math.floor(val/((10^((i-1)*3))/100))/(100)..suffixes[i]
		end
	end
end

local function SpinRewardModuleFired(Reward)
	local Animation = TweenService:Create(script.Parent.RewardName,TweenInfo.new(0.3),{Size = UDim2.fromScale(0.258,0.069)})
	local Animation2 = TweenService:Create(script.Parent.RewardName,TweenInfo.new(0.2),{Size = UDim2.fromScale(0,0)})
	script.Parent.RewardName.Text = "You won ".. Reward
	script.Parent.RewardName.Visible = true
	Animation:Play()
	Animation.Completed:Connect(function()
		spawn(function()
			wait(1)
			Animation2:Play()
			Animation2.Completed:Connect(function()
				script.Parent.RewardName.Visible = false
			end)
		end)
	end)
end

local temp = leaderstats:WaitForChild("temp")
local earningBoost = temp.EarningsBoost

script.Parent.Spin["3"].title.TextLabel.Text = math.round((earningBoost.Value * 1000) + 1000).." Cash"
script.Parent.Spin["3"].title["TextLabel - Stroke"].Text = math.round((earningBoost.Value * 1000) + 1000).." Cash"


script.Parent.Button.ImageButton.nextFreeSpin.TextLabel.Text = "FREE SPIN IN "..saniyeDakikaSaniyeCevirString(SpinTime.Value).. "!"

script.Parent.Button.ImageButton.nSpins.TextLabel.Text = SpinStats.Value

SpinTime.Changed:Connect(function()
	script.Parent.Button.ImageButton.nextFreeSpin.TextLabel.Text = "FREE SPIN IN "..saniyeDakikaSaniyeCevirString(SpinTime.Value).. "!"
end)

SpinStats.Changed:Connect(function()
	script.Parent.Button.ImageButton.nSpins.TextLabel.Text = SpinStats.Value
end)

local ImageAnimations = {
	Spectacular = 337,
	["Black Spectacular"] = 68,
	["Comic Pages"] = 113,
	Nothing = 158,
	["X2 Comic Pages"] = 203,
	["Cash"] = 248,
	Spin = 293,
	["X2 Cash"] = 23
}

local function endanimation()
	local Animation1 = TweenService:Create(Spin,TweenInfo.new(1),{Rotation = 0})
	Animation1:Play()
	Animation1.Completed:Connect(function()
		Debounce = false
	end)
end

local function animation()
	local RandomTable = SpinModule.getRandomReward()
	local Animation1 = TweenService:Create(Spin,TweenInfo.new(5),{Rotation = 360*SpinModule.Spin.SpinTime+ImageAnimations[RandomTable]})
	Animation1:Play()
	Animation1.Completed:Connect(function()
		SpinRewardModuleFired(RandomTable)
		SpinEvent:FireServer(RandomTable)
		wait(1)
		endanimation()
	end)
end

local AnimationButtonImage1 = TweenService:Create(SpinButton,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,0.575)})
local AnimationButtonImage2 = TweenService:Create(SpinButton,TweenInfo.new(0.2),{Size = UDim2.fromScale(0.9,0.500)})

local Debounce = false

SpinButton.MouseButton1Click:Connect(function()

	if Debounce then return end
	Debounce = true

	AnimationButtonImage1:Play()
	AnimationButtonImage1.Completed:Wait() 

	AnimationButtonImage2:Play()
	AnimationButtonImage2.Completed:Wait() 
	
	AnimationButtonImage1:Play()
	AnimationButtonImage1.Completed:Wait() 
	
	Debounce = false

	if SpinStats.Value >= 1 then
		animation()
	else
		print("Insufficient Spins")
	end
end)