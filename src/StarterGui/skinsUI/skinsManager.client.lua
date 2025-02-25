local rs = game:GetService("ReplicatedStorage")
local cs = game:GetService("CollectionService")
local _math = require(rs:WaitForChild("math"))
local items = require(rs:WaitForChild("items"))
local sales=require(rs:WaitForChild("sales"))
local effects=require(rs:WaitForChild("Effects"))

local buttonSound = rs:WaitForChild("ui_sound"):WaitForChild("button")
local upgradeSound = rs:WaitForChild("ui_sound"):WaitForChild("upgrade")
local errorSound = rs:WaitForChild("ui_sound"):WaitForChild("error")

local player = game.Players.LocalPlayer
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local leaderstats = player:WaitForChild("leaderstats")
local skins = leaderstats:WaitForChild("skins")
local cash=leaderstats:WaitForChild("Cash")

local skinsRemote = player:WaitForChild("skinsRemote")

local playerGui = player:WaitForChild("PlayerGui")
local skinsUI = playerGui:WaitForChild("skinsUI")
local container = skinsUI:WaitForChild("container")
local left = container:WaitForChild("left")
local right = container:WaitForChild("right")
local lowerText = container:WaitForChild("lowerText")
local top = lowerText:WaitForChild("1top")
local bottom = lowerText:WaitForChild("2bottom")
local buttonContainer = lowerText:WaitForChild("3buttonContainer")
local equipButton = buttonContainer:WaitForChild("1Equip"):WaitForChild("text"):WaitForChild("button")
local upgradeButton = buttonContainer:WaitForChild("2Upgrade"):WaitForChild("text"):WaitForChild("button")
local image = container:WaitForChild("image")
local currentTab = "Classic"
local currentTabValue = skinsUI:WaitForChild("currentTab")
currentTabValue.Value = currentTab

local dataLoaded = leaderstats:WaitForChild("temp"):WaitForChild("dataLoaded")

if not (dataLoaded.Value) then repeat task.wait(1/30) until (dataLoaded.Value) end

local function generateDescription()
	--print("generate description")
	if not _G.currencyTextSize then
		repeat task.wait() until _G.currencyTextSize
	end
	local dataFolder = skins[currentTab]
	local equipped = dataFolder:WaitForChild("Equipped")
	local level = dataFolder:WaitForChild("Level")
	local unlocked = dataFolder:WaitForChild("Unlocked")

	local item = items.Skins[currentTab]
	image.Image = items.SuitSprites[item.image]
	image.ImageRectOffset = item.offset
	local nameContainer = top:WaitForChild("1name")
	local nameContainerText=nameContainer:WaitForChild("text"):WaitForChild("text")
	nameContainerText.TextSize=_G.currencyTextSize
	nameContainerText.Text = unlocked.Value and currentTab..": Level "..level.Value or currentTab
	local price = top:WaitForChild("2price")

	local custom=price:WaitForChild("text"):WaitForChild("custom")
	local robux = price:WaitForChild("text"):WaitForChild("robux")
	local cash = price:WaitForChild("text"):WaitForChild("cash")
	local cash_text = cash:WaitForChild("text")

	local stringHeight = cash_text.AbsoluteSize.Y
	local stringLength = math.ceil(stringHeight*0.37)

	local cost=unlocked.Value and _math.getPriceFromLevel(level.Value,1000) or item.cost

	local cashString = _math.giveNumberCommas(cost)
	cash_text.Text = cashString
	cash_text.TextSize=_G.currencyTextSize
	cash_text.Size = UDim2.new(0,stringLength*#cashString,0,stringHeight)

	--[[
	local robuxPrice = items.Skins[currentTab].cost
	local robux_text = robux:WaitForChild("text")
	robux_text.Text = robuxPrice
	robux_text.TextSize=_G.currencyTextSize
	robux_text.Size = UDim2.new(0,stringLength*#robux_text.Text,0,stringHeight)
	]]

	local strings = {
		[1] = "",
		[2] = "",
		[3] = ""
	}

	local health = _math.getSuitHealth(level.Value)
	local crit = _math.getSuitCrit(level.Value)

	local misc = {
		[1] = crit.."%",
		[2] = health.." extra",
		[3] = ""
	}

	local desc = item.desc

	for i = 1,#desc do
		strings[i] = desc[i]..misc[i]
	end

	local bottomText=bottom:WaitForChild("text"):WaitForChild("text")
	bottomText.TextSize=_G.currencyTextSize
	bottomText.Text = table.concat(strings)

	local buttonContainer = lowerText:WaitForChild("3buttonContainer")
	local equipContainer = buttonContainer:WaitForChild("1Equip")
	local upgradeContainer = buttonContainer:WaitForChild("2Upgrade")

	robux.Visible = false
	custom.Visible=false
	cash.Visible=true

	upgradeContainer:WaitForChild("text"):WaitForChild("button").Text = unlocked.Value and "Upgrade" or "Unlock"

	if unlocked.Value then
		equipContainer.Visible=true
		equipContainer:WaitForChild("text"):WaitForChild("button").Text = equipped.Value and "Unequip" or "Equip"
		if level.Value < 24 then
			upgradeContainer.Visible = true
			price.Visible = true
		else
			upgradeContainer.Visible = false
			price.Visible = false
		end
	else
		--print("made it here")
		equipContainer.Visible=false
		upgradeContainer.Visible = true
		price.Visible = true
		if cost==0 and item.unlock then
			--print("made it here2")
			cash.Visible=false
			custom.Visible=true
			custom:WaitForChild("text").Text=item.unlock
		end
	end
end

generateDescription()

local slides_names = {
	["Classic"]=1,
	["Mayday Parker"]=2,
	["Gwen"]=3,
	["ATSV 2099"]=4,
	["Miles 2099"]=5,
	["ATSV Miles"]=6,
	["Miles Spider Verse"]=7,
	["Miles"]=8,
	["Miles Classic"]=9,
	["ATSV India"]=10,
	["Symbiote"]=11,
	["Spider Girl"]=12,
	["Spider Woman"]=13,
	["Homemade"]=14,
	["Yellow Jacket"]=15,
	["Far From Home"]=16,
	["No Way Home"]=17,
	["Noir"]=18,
	["ATSV Scarlet"]=19,
	["Scarlet"]=20,
	["Damage Control"]=21,
	["ATSV Punk"]=22,
	["Punk"]=23,
	["Homecoming"]=24,
	["Advanced"]=25,
	["Iron Spider"]=26,
	["Stealth"]=27,
	["Spectacular"]=28,
	["Black Spectacular"]=29,
	["Supreme Sorcerer"]=30
}

local slides_numbers = {
	"Classic",
	"Mayday Parker",
	"Gwen",
	"ATSV 2099",
	"Miles 2099",
	"ATSV Miles",
	"Miles Spider Verse",
	"Miles",
	"Miles Classic",
	"ATSV India",
	"Symbiote",
	"Spider Girl",
	"Spider Woman",
	"Homemade",
	"Yellow Jacket",
	"Far From Home",
	"No Way Home",
	"Noir",
	"ATSV Scarlet",
	"Scarlet",
	"Damage Control",
	"ATSV Punk",
	"Punk",
	"Homecoming",
	"Advanced",
	"Iron Spider",
	"Stealth",
	"Spectacular",
	"Black Spectacular",
	"Supreme Sorcerer"
}

local tweenInfo1 = TweenInfo.new(.1,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out,0,false,0)
local ts = game:GetService("TweenService")

local dots=container:WaitForChild("dots")
local function changeText(s)
	for _,child in dots:GetChildren() do
		if child:IsA("ImageLabel") then continue end
		child.Text=s.."/"..tostring(#slides_numbers)
	end
	effects:TweenDots(dots)
end
changeText("1")

local function changeSlide(direction)
	local image = container:WaitForChild("image")
	effects:TweenSkinsImage(image,direction)
	buttonSound:Play()
	if (direction == "left") then
		currentTab = slides_names[currentTab] == 1 and slides_numbers[#slides_numbers] or slides_numbers[slides_names[currentTab]-1]
	elseif (direction == "right") then
		currentTab = slides_names[currentTab] == #slides_numbers and slides_numbers[1] or slides_numbers[slides_names[currentTab]+1]	
	end
	changeText(tostring(slides_names[currentTab]))
	local sizeTween = ts:Create(image,tweenInfo1,{Size = UDim2.new(1,0,1,0)})
	currentTabValue.Value = currentTab
	generateDescription()
end

left:WaitForChild("bg"):WaitForChild("button").Activated:Connect(function()
	effects:TweenNavButton(left.bg)
	changeSlide("left")
end)

right:WaitForChild("bg"):WaitForChild("button").Activated:Connect(function()
	effects:TweenNavButton(right.bg)
	changeSlide("right")
end)

for _,skin in pairs(skins:GetChildren()) do
	local equipped = skin:WaitForChild("Equipped")
	local unlocked = skin:WaitForChild("Unlocked")
	local level = skin:WaitForChild("Level")

	level:GetPropertyChangedSignal("Value"):Connect(function()
		upgradeSound:Play()
		generateDescription() -- this updates everything after you unlocked the skin		
	end)

	unlocked:GetPropertyChangedSignal("Value"):Connect(function()
		if unlocked.Value then
			upgradeSound:Play()			
		end
		generateDescription() -- this updates everything after you unlocked the skin
	end)

	equipped:GetPropertyChangedSignal("Value"):Connect(function()
		generateDescription() -- changes the button text from equip to unequip
	end)
end

local characterLoaded = player:WaitForChild("leaderstats"):WaitForChild("temp"):WaitForChild("characterLoaded")

local lastCFrame = player:WaitForChild("LastRootCFrame")
local lastCameraCFrame = player:WaitForChild("LastCameraCFrame")
local activated = false 

local OTS_CAM_HDLR = require(rs:WaitForChild("OTS_Camera"))

local errorSound = rs:WaitForChild("ui_sound"):WaitForChild("error")

upgradeButton.Activated:Connect(function()
	local f = coroutine.wrap(_G.tweenButton)
	f(upgradeButton.Parent.Parent)
	local item=items.Skins[currentTab]
	local cash = leaderstats:WaitForChild("Cash")
	local dataFolder = skins[currentTab]
	local level = dataFolder:WaitForChild("Level")
	local cost = _math.getPriceFromLevel(level.Value,1000)
	local unlocked=dataFolder:WaitForChild("Unlocked")
	if unlocked.Value then --// upgrade
		if cash.Value >= cost then --// can afford
			rs:WaitForChild("ui_sound"):WaitForChild("button3"):Play()
			skinsRemote:FireServer(currentTab,"upgrade")
		else --// can't afford it
			errorSound:Play()
			local deficit=cost-cash.Value
			sales:PromptProduct(sales:ClosestProduct(deficit),player)
		end
	else  --// unlock
		if item.unlock then -- has to be unlocked by different way other than cash
			if currentTab=="Stealth" then
				local objectives=leaderstats:WaitForChild("objectives")
				if objectives:WaitForChild("current").Value<15 and objectives:WaitForChild("completed").Value==false then
					errorSound:Play()
					return
				end
				rs:WaitForChild("ui_sound"):WaitForChild("button3"):Play()
				skinsRemote:FireServer(currentTab,"unlock")
				
			elseif currentTab=="Spectacular" then
				local spectacularUnlocked = player:WaitForChild("leaderstats"):WaitForChild("skins"):WaitForChild("Spectacular"):WaitForChild("Unlocked")
				if spectacularUnlocked.Value==false then
					errorSound:Play()
					return
				end
				rs:WaitForChild("ui_sound"):WaitForChild("button3"):Play()
				skinsRemote:FireServer(currentTab,"unlock")
				
			elseif currentTab=="Black Spectacular" then
				local blackSpectacularUnlocked = player:WaitForChild("leaderstats"):WaitForChild("skins"):WaitForChild("Black Spectacular"):WaitForChild("Unlocked")
				if blackSpectacularUnlocked.Value==false then
					errorSound:Play()
					return
				end
				rs:WaitForChild("ui_sound"):WaitForChild("button3"):Play()
				skinsRemote:FireServer(currentTab,"unlock")
			
			elseif currentTab=="Supreme Sorcerer" then
				local rebirths=leaderstats:WaitForChild("Rebirths")
				if rebirths.Value<10 then
					errorSound:Play()
					return
				end
				rs:WaitForChild("ui_sound"):WaitForChild("button3"):Play()
				skinsRemote:FireServer(currentTab,"unlock")
			end
		else 
			local cost=item.cost
			if cash.Value>=cost then--can afford
				rs:WaitForChild("ui_sound"):WaitForChild("button3"):Play()
				skinsRemote:FireServer(currentTab,"unlock")
			else--can't afford
				errorSound:Play()
				local deficit=cost-cash.Value
				sales:PromptProduct(sales:ClosestProduct(deficit),player)
			end
		end
	end
end)

equipButton.Activated:Connect(function()
	if (activated) then return end
	if (player.Character) and not (player.Character:WaitForChild("Humanoid").Health > 0) then errorSound:Play() return end
	if cs:HasTag(player.Character,"ragdolled") then return end

	local dataFolder = skins[currentTab]
	local item=items.Skins[currentTab]
	local unlocked = dataFolder:WaitForChild("Unlocked")
	local equipped = dataFolder:WaitForChild("Equipped")

	activated = true

	local f = coroutine.wrap(_G.tweenButton)
	f(equipButton.Parent.Parent)

	if (unlocked.Value) then -- equip/unequip
		rs:WaitForChild("ui_sound"):WaitForChild("button3"):Play()

		characterLoaded.Value = false

		player.Character.PrimaryPart.Anchored = true
		--controls:Disable()

		workspace.Camera.CameraType = Enum.CameraType.Scriptable
		workspace.Camera.CameraSubject = nil

		lastCFrame.Value = player.Character.PrimaryPart.CFrame
		lastCameraCFrame.Value = workspace.CurrentCamera.CFrame

		skinsRemote:FireServer(currentTab,false,lastCFrame.Value)
		OTS_CAM_HDLR.ShutDown()
		characterLoaded:GetPropertyChangedSignal("Value"):Wait()
		activated = false
		return
	--[[
	else -- not unlocked yet
		local cost=item.cost
		if cash.Value>=cost then--can afford
			rs:WaitForChild("ui_sound"):WaitForChild("button3"):Play()
			skinsRemote:FireServer(currentTab)
		else--can't afford
			-- open the cash shop
			errorSound:Play()
		end
	]]
	end
	activated = false
end)

local tweenInfo2=TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,true,0)

local function TweenNavButtons()
	if not skinsUI.Enabled then return end
	-- make sure buttons are at original positions
	left.Position=UDim2.new(0,0,0.5,0)
	right.Position=UDim2.new(1,0,0.5,0)
	local offset=math.round(_G.slot_size/2)
	ts:Create(left,tweenInfo2,{Position=UDim2.new(0,-offset,0.5,0)}):Play()
	ts:Create(right,tweenInfo2,{Position=UDim2.new(1,offset,0.5,0)}):Play()
end

skinsUI:GetPropertyChangedSignal("Enabled"):Connect(TweenNavButtons)