local Spin = script.Parent:WaitForChild("Spin")
local SpinButton = script.Parent:WaitForChild("Button"):WaitForChild("ImageButton")
local TweenService = game:GetService("TweenService")

-- Add UIAspectRatioConstraint
local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 1 -- 1:1 ratio since it's a circular spinner
aspectRatio.DominantAxis = Enum.DominantAxis.Width
aspectRatio.Parent = script.Parent

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

script.Parent.Button.ImageButton.nextFreeSpin.TextLabel.Text = "FREE SPIN:"..saniyeDakikaSaniyeCevirString(SpinTime.Value)

script.Parent.Button.ImageButton.spin.amount.Text = "x"..SpinStats.Value

SpinTime.Changed:Connect(function()
	script.Parent.Button.ImageButton.nextFreeSpin.TextLabel.Text = "FREE SPIN:"..saniyeDakikaSaniyeCevirString(SpinTime.Value)
end)

SpinStats.Changed:Connect(function()
	script.Parent.Button.ImageButton.spin.amount.Text = "x"..SpinStats.Value
end)

local ImageAnimations = {
	Spectacular = 337,
	["Black Spectacular"] = 68,
	["1k Cash"] = 293,
	["10k Cash"] = 113,
	["50k Cash"] = 23,
	["5k Cash"] = 203,
	Spin = 158,
	["X2 Cash"] = 248
}

local function endanimation()
	local Animation1 = TweenService:Create(Spin,TweenInfo.new(1),{Rotation = 0})
	Animation1:Play()
	Animation1.Completed:Connect(function()
	end)
end

local function animation()
	local RandomTable = SpinModule.getRandomReward()
	local Animation1 = TweenService:Create(Spin,TweenInfo.new(5),{Rotation = 360*SpinModule.Spin.SpinTime+ImageAnimations[RandomTable]})
	Animation1:Play()
	Animation1.Completed:Connect(function()
			SpinEvent:FireServer(RandomTable)
		wait(1)
		endanimation()
	end)
end

SpinButton.Activated:Connect(function()

	if SpinStats.Value >= 1 then
		animation()
	else
		print("Insufficient Spins")
	end
end)