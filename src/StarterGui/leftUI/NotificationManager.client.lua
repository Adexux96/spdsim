local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local leftUI = script.Parent
local container = leftUI:WaitForChild("container")
local inner=container:WaitForChild("inner")
local outer=container:WaitForChild("outer")
local middleUI = playerGui:WaitForChild("middleUI")
local currentAbilityTab = middleUI:WaitForChild("currentTab")
local abilityHolder = middleUI:WaitForChild("container"):WaitForChild("holder")

local rebirthUI = playerGui:WaitForChild("rebirthUI")
local innerRebirthContainer = rebirthUI:WaitForChild("bg"):WaitForChild("inner")
local rebirthNotificationContainer = innerRebirthContainer:WaitForChild("purchaseInfo"):WaitForChild("5purchase"):WaitForChild("notificationFolder"):WaitForChild("notificationContainer")

local skinsUI = playerGui:WaitForChild("skinsUI")
local currentSkinsTab = skinsUI:WaitForChild("currentTab")
local lowerText = skinsUI:WaitForChild("container"):WaitForChild("lowerText")
local notificationFolder = lowerText:WaitForChild("3buttonContainer"):WaitForChild("2Upgrade"):WaitForChild("notificationFolder")
local skinsNotificationContainer = notificationFolder:WaitForChild("notificationContainer")

local rebirthContainer = inner:WaitForChild("5rebirth"):WaitForChild("bg"):WaitForChild("notificationContainer")
local abilitiesContainer = outer:WaitForChild("3abilities"):WaitForChild("bg"):WaitForChild("notificationContainer")
local skinsContainer = outer:WaitForChild("2suit"):WaitForChild("bg"):WaitForChild("notificationContainer")

local leaderstats = player:WaitForChild("leaderstats")
local temp = leaderstats:WaitForChild("temp")
local cash = leaderstats:WaitForChild("Cash")
local skins = leaderstats:WaitForChild("skins")
local abilities = leaderstats:WaitForChild("abilities")
local rebirths = leaderstats:WaitForChild("Rebirths")
local objectives=leaderstats:WaitForChild("objectives")

local ts = game:GetService("TweenService")
local outTweenInfo = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
local elasticTweenInfo = TweenInfo.new(.2,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0)
local rs = game:GetService("ReplicatedStorage")
local _math = require(rs:WaitForChild("math"))
local items = require(rs:WaitForChild("items"))

local function activateNotification(container,bool)
	if bool then
		if container.Visible then return end
	end
	container.Visible = true
	container:WaitForChild("pop_bg").Size = UDim2.new(0,0,0,0)
	ts:Create(container:WaitForChild("pop_bg"),outTweenInfo,{Size = UDim2.new(1.6,0,1.6,0)}):Play()
	container:WaitForChild("notification").Size = UDim2.new(0,0,0,0)
	ts:Create(container:WaitForChild("notification"),elasticTweenInfo,{Size = UDim2.new(1,0,1,0)}):Play()
end

local function disableNotification(container)
	container.Visible = false
end

local function checkAbilities()
	local found = 0
	for _,category in pairs (abilities:GetChildren()) do 
		for _,ability in pairs(category:GetChildren()) do
			local item = items[category.Name][ability.Name]
			local level = ability:WaitForChild("Level")
			local unlocked = ability:WaitForChild("Unlocked")
			local layoutOrder = item.order
			local categorySlot = abilityHolder:WaitForChild(category.Name)
			local abilitySlot = categorySlot:WaitForChild(layoutOrder)
			local slot = abilitySlot:WaitForChild("slot")
			if unlocked.Value then
				local price = _math.getPriceFromLevel(level.Value,item.upgrade)
				if cash.Value >= price and level.Value < 12 then
					activateNotification(slot:WaitForChild("notificationContainer"))
					found += 1
				else
					disableNotification(slot:WaitForChild("notificationContainer"))
				end
			else -- for testing purposes
				local price=item.cost
				if cash.Value>=price then
					found+=1
					activateNotification(slot:WaitForChild("notificationContainer"))
				else 
					disableNotification(slot:WaitForChild("notificationContainer")) 
				end
			end
		end
	end
	if found > 0 then
		activateNotification(abilitiesContainer,true)
	else
		disableNotification(abilitiesContainer)
	end
end

local function checkSkins()
	local found = 0
	for _,skin in pairs(skins:GetChildren()) do 
		local level = skin:WaitForChild("Level")
		local unlocked = skin:WaitForChild("Unlocked")
		local item = items.Skins[skin.Name]
		local cashAmount = cash.Value
		if unlocked.Value then
			local price = _math.getPriceFromLevel(level.Value,item.upgrade)
			if cashAmount >= price and level.Value < 12 then
				found += 1
				if currentSkinsTab.Value == skin.Name then
					activateNotification(skinsNotificationContainer)
				end
			else
				if currentSkinsTab.Value == skin.Name then
					disableNotification(skinsNotificationContainer)
				end				
			end
		else -- for testing purposes
			if item.unlock then -- can't be unlocked by cash
				if skin.Name=="Stealth" then
					if objectives:WaitForChild("current").Value>#items.objectives or objectives:WaitForChild("completed").Value then
						found+=1
						if currentSkinsTab.Value == skin.Name then
							activateNotification(skinsNotificationContainer)
						end
					else 
						if currentSkinsTab.Value == skin.Name then
							disableNotification(skinsNotificationContainer)
						end
					end
				elseif skin.Name=="Supreme Sorcerer" then
					if rebirths.Value>=10 then
						found+=1
						if currentSkinsTab.Value == skin.Name then
							activateNotification(skinsNotificationContainer)
						end
					else 
						if currentSkinsTab.Value == skin.Name then
							disableNotification(skinsNotificationContainer)
						end
					end
				end
			else 
				local price=item.cost
				if cashAmount>=price then --// can afford
					found+=1
					if currentSkinsTab.Value == skin.Name then
						activateNotification(skinsNotificationContainer)
					end
				else 
					if currentSkinsTab.Value == skin.Name then
						disableNotification(skinsNotificationContainer)
					end		
				end
			end
		end
	end
	if found > 0 then
		activateNotification(skinsContainer,true)
	else
		disableNotification(skinsContainer)
	end
end

if not _G.cash_changed then
	repeat task.wait() until _G.cash_changed
end

for _,category in pairs (abilities:GetChildren()) do 
	for _,ability in pairs(category:GetChildren()) do 
		local level = ability:WaitForChild("Level")
		local unlocked = ability:WaitForChild("Unlocked")
		level:GetPropertyChangedSignal("Value"):Connect(checkAbilities)
		unlocked:GetPropertyChangedSignal("Value"):Connect(function()
			checkAbilities()
			_G.cash_changed()
		end)
	end
end

for _,skin in pairs(skins:GetChildren()) do 
	local level = skin:WaitForChild("Level")
	local unlocked = skin:WaitForChild("Unlocked")
	local item = items.Skins[skin.Name]
	level:GetPropertyChangedSignal("Value"):Connect(checkSkins)
	unlocked:GetPropertyChangedSignal("Value"):Connect(function()
		checkSkins()
		_G.cash_changed()
	end)
end

local function checkRebirth()
	local rebirthPrice = _math.getRebirthPrice(rebirths.Value)
	local cashAmount = cash.Value
	if cashAmount >= rebirthPrice and rebirths.Value < 10 then
		activateNotification(rebirthNotificationContainer)
		activateNotification(rebirthContainer,true)
	else
		disableNotification(rebirthNotificationContainer)
		disableNotification(rebirthContainer)
	end
end

local function checkAvailableUpgrades()
	checkAbilities()
	checkSkins()
	checkRebirth()
end

cash:GetPropertyChangedSignal("Value"):Connect(function()
	checkAvailableUpgrades()
	_G.cash_changed()
end)

currentSkinsTab:GetPropertyChangedSignal("Value"):Connect(checkSkins)
skinsUI:GetPropertyChangedSignal("Enabled"):Connect(checkSkins)

currentAbilityTab:GetPropertyChangedSignal("Value"):Connect(checkAbilities)
middleUI:GetPropertyChangedSignal("Enabled"):Connect(checkAbilities)

rebirthUI:GetPropertyChangedSignal("Enabled"):Connect(function()
	checkRebirth()
	_G.cash_changed()
end)

--objectives:WaitForChild("current"):GetPropertyChangedSignal("Value"):Connect(checkSkins)
objectives:WaitForChild("completed"):GetPropertyChangedSignal("Value"):Connect(function()
	checkSkins()
	_G.cash_changed()
end)

checkAbilities()
checkSkins()
checkRebirth()

local shop=inner:WaitForChild("1shop")
local shopUI=playerGui:WaitForChild("shopUI")
local EarningsBoost=temp:WaitForChild("EarningsBoost")

--activateNotification(shop:WaitForChild("bg"):WaitForChild("notificationContainer"))

EarningsBoost:GetPropertyChangedSignal("Value"):Connect(function()
	if not shopUI.Enabled then -- don't notify
		activateNotification(shop:WaitForChild("bg"):WaitForChild("notificationContainer"))
	end
end)

shopUI:GetPropertyChangedSignal("Enabled"):Connect(function()
	if shopUI.Enabled then
		disableNotification(shop:WaitForChild("bg"):WaitForChild("notificationContainer"))
	end
end)