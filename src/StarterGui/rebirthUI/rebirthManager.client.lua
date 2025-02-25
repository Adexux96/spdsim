local rebirthUI = script.Parent
local player = game.Players.LocalPlayer 
local playerGui = player:WaitForChild("PlayerGui")
local leaderstats = player:WaitForChild("leaderstats")
local rebirths = leaderstats:WaitForChild("Rebirths")
local cash = leaderstats:WaitForChild("Cash")

local rs = game:GetService("ReplicatedStorage")

local rebirthRemote = rs:WaitForChild("RebirthEvent")
local _math = require(rs:WaitForChild("math"))
local sales=require(rs:WaitForChild("sales"))

local bg = rebirthUI:WaitForChild("bg")
local inner = bg:WaitForChild("inner")

local blur = game:GetService("Lighting"):WaitForChild("Blur")
local buttonSound = rs:WaitForChild("ui_sound"):WaitForChild("button3")
local errorSound = rs:WaitForChild("ui_sound"):WaitForChild("error")
local upgradeSound = rs:WaitForChild("ui_sound"):WaitForChild("upgrade")

local purchaseInfo = inner:WaitForChild("purchaseInfo")
local priceContainer = purchaseInfo:WaitForChild("4price")
local purchaseContainer = purchaseInfo:WaitForChild("5purchase")
local textContainer = purchaseInfo:WaitForChild("1text")

local spinner = inner:WaitForChild("spinner")
local icon = spinner:WaitForChild("icon")

local ts = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,false,0)
local tween = ts:Create(icon,tweenInfo,{Rotation = 180})

local function EnabledChanged()
	if rebirthUI.Enabled then
		tween:Play()
	else 
		tween:Pause()
	end
end

--rebirthUI:GetPropertyChangedSignal("Enabled"):Connect(EnabledChanged)

local function rebirthActivated()
	if rebirths.Value==10 then return end
	local rebirthCost = _math.getRebirthPrice(rebirths.Value)
	local f=coroutine.wrap(_G.tweenButton)
	f(purchaseContainer)
	if cash.Value < rebirthCost then
		errorSound:Play()
		local deficit=rebirthCost-cash.Value
		sales:PromptProduct(sales:ClosestProduct(deficit),player)
		return
	end
	buttonSound:Play()
	rebirthRemote:FireServer()
end

local rebirthButton = purchaseContainer:WaitForChild("text"):WaitForChild("button")
rebirthButton.Activated:Connect(rebirthActivated)

local rebirthPriceText = priceContainer:WaitForChild("text"):WaitForChild("cash"):WaitForChild("text")
local rebirthAmountText = textContainer:WaitForChild("4info")
local percentChangeText=textContainer:WaitForChild("1info")
local currentRebirths = rebirths.Value

local function updateRebirthInfo()
	if rebirths.Value > currentRebirths then
		currentRebirths = rebirths.Value
		upgradeSound:Play()
	end
	--// update the text and buttons, and price
	for i,v in purchaseContainer:GetChildren() do 
		if v.Name=="text" then
			v.button.TextTransparency=rebirths.Value<10 and 0 or .5
		end
		if v:IsA("ImageLabel") then
			v.ImageTransparency=rebirths.Value<10 and 0 or .5
		end
	end
	
	local rebirthCost = _math.getRebirthPrice(rebirths.Value)
	
	local base = 1
	local multiplier=rebirths.Value<10 and 1 or 0
	local amount=0.1*base*multiplier*100
	
	percentChangeText.Text="Increase cash earning by +"..amount.."%!"
	rebirthAmountText.Text = "Rebirths: "..rebirths.Value.."/10"
	rebirthPriceText.Text = _math.giveNumberCommas(rebirths.Value<10 and rebirthCost or 000000)
	
	local ySize = priceContainer.AbsoluteSize.Y
	local stringLength = math.ceil(ySize*0.37)
	local cashString = rebirthPriceText.Text
	rebirthPriceText.Size = UDim2.new(0,stringLength*#cashString,0,ySize)
	rebirthPriceText.TextSize = math.round(ySize*.75)
end

cash:GetPropertyChangedSignal("Value"):Connect(updateRebirthInfo)
rebirths:GetPropertyChangedSignal("Value"):Connect(updateRebirthInfo)
updateRebirthInfo()

return 