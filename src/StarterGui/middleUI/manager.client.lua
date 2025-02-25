local player = 			 game.Players.LocalPlayer
local mouse = 			 player:GetMouse()
local abilityRemote = 	 player:WaitForChild("abilityRemote")
local dragRemote = 		 player:WaitForChild("dragRemote")
local playerGui = 		 player:WaitForChild("PlayerGui")
local middleUI = 		 playerGui:WaitForChild("middleUI")
local leftUI = 			 playerGui:WaitForChild("leftUI")
local skinsUI = 		 playerGui:WaitForChild("skinsUI")
local shopUI = 			 playerGui:WaitForChild("shopUI")
local hotbarUI = 		 playerGui:WaitForChild("hotbarUI")
local hotbar_container = hotbarUI:WaitForChild("container")
local dragUI = 			 playerGui:WaitForChild("dragUI")
local trashUI = 		 playerGui:WaitForChild("trashUI")
local advertsUI = 		 playerGui:WaitForChild("adverts")
local rebirthUI = 		 playerGui:WaitForChild("rebirthUI")
local controlsUI =		 playerGui:WaitForChild("controlsUI")
local twitterUI=		 playerGui:WaitForChild("twitterUI")
local uis = 			 game:GetService("UserInputService")
local rs = 				 game:GetService("ReplicatedStorage")
local buttonSound2 = 	 rs:WaitForChild("ui_sound"):WaitForChild("button3")
local buttonSound = 	 rs:WaitForChild("ui_sound"):WaitForChild("button")
local upgradeSound = 	 rs:WaitForChild("ui_sound"):WaitForChild("upgrade")
local errorSound = 	 	 rs:WaitForChild("ui_sound"):WaitForChild("error")
local dragSound = 		 rs:WaitForChild("ui_sound"):WaitForChild("drag")
local ui_loop_sound = 	 rs:WaitForChild("ui_sound"):WaitForChild("loop")
local interface=		 require(rs:WaitForChild("interface"))
local items = 			 require(rs:WaitForChild("items"))
local _math = 			 require(rs:WaitForChild("math"))
local OTS_CAM_HDLR = 	 require(rs:WaitForChild("OTS_Camera"))
local sales=			 require(rs:WaitForChild("sales"))
local effects=			 require(rs:WaitForChild("Effects"))
local cs = 				 game:GetService("CollectionService")
local ts =				 game:GetService("TweenService")

local function destroyJumpButton(TouchGui)
	if (TouchGui) then
		local JumpButton = TouchGui:WaitForChild("TouchControlFrame"):FindFirstChild("JumpButton")
		if JumpButton then
			JumpButton:Destroy() -- if there's a jump button, get rid of it.
		end
	end
end

local touchGui = nil

local function Wait_For_TouchGui()
	local iterations = 0
	repeat iterations += 1 task.wait(1/30) until iterations == 100 or playerGui:FindFirstChild("TouchGui")
	return playerGui:FindFirstChild("TouchGui")
end

_G.platform = nil
local function detectDevice()
	touchGui = playerGui:FindFirstChild("TouchGui")

	if not touchGui then
		spawn(function()
			touchGui= Wait_For_TouchGui()
			if touchGui then return detectDevice() end
		end)
	end

	local isMobile = uis.TouchEnabled and touchGui ~= nil
	local isPC = uis.MouseEnabled and uis.KeyboardEnabled
	--local isXbox = uis.GamepadEnabled
	-- Xbox coming soon
	destroyJumpButton(touchGui)

	if (isMobile) then
		_G.platform = "mobile"
		return
	elseif (isPC) then
		_G.platform = "PC"
		return
			--elseif (isXbox) then
			--_G.platform = "Xbox"
			--return
	end
end

spawn(function()
	detectDevice()
end)

local dataFolder = player:WaitForChild("leaderstats")
local dataLoaded = dataFolder:WaitForChild("temp"):WaitForChild("dataLoaded")
local abilities = dataFolder:WaitForChild("abilities")
local hotbar = dataFolder:WaitForChild("hotbar")

local temp = dataFolder:WaitForChild("temp")
local isSwimming = temp:WaitForChild("isSwimming")
local isClimbing = temp:WaitForChild("isClimbing")
local isSprinting = temp:WaitForChild("isSprinting")

if not (dataLoaded.Value == true) then
	repeat task.wait(1/30) until dataLoaded.Value == true
end

local middleUI_container = middleUI:WaitForChild("container")
local middleUI_lowerText = middleUI_container:WaitForChild("lowerText")
local middleUI_upperText = middleUI_container:WaitForChild("upperText")
local middleUI_exit = middleUI_container:WaitForChild("exit")
local middleUI_left = middleUI_container:WaitForChild("left")
local middleUI_right = middleUI_container:WaitForChild("right")
local middleUI_holder = middleUI_container:WaitForChild("holder")
local middleUI_upgrade_button = middleUI_lowerText:WaitForChild("3buttonContainer"):WaitForChild("text"):WaitForChild("button")
local currentAbilityTab = "Melee"
local currentTab = middleUI:WaitForChild("currentTab")
currentTab.Value = currentAbilityTab
local ABILITY_SELECTED = nil
local HOTBAR_ABILITY_SELECTED = nil

local startDrag = nil
local endDrag = nil
local focused_input = nil
local thumbstick_input = nil
local touchMove = nil

local function generateAbilities()
	for _,category in pairs(abilities:GetChildren()) do
		local clone = middleUI_holder:WaitForChild("clone"):Clone()
		clone.Name = category.Name
		clone.slots.Value = #category:GetChildren()
		if (clone.slots.Value < 3) then
			clone:WaitForChild("2"):Destroy()
			clone:WaitForChild("3").Name = "2"
		end
		local categoryName = category.Name
		for _,ability in pairs(category:GetChildren()) do
			local abilityName = ability.Name
			local item = items[categoryName][abilityName]
			local unlocked = abilities[categoryName][abilityName].Unlocked
			local slot = clone[item.order]
			slot.category.Value = categoryName
			slot.name.Value = abilityName
			slot.slot.icon.ImageRectOffset = item.offset
			slot.slot.icon.ImageTransparency = unlocked.Value and 0 or .5
			if (abilityName == "Punch") then
				ABILITY_SELECTED = slot
			end
		end
		if (currentAbilityTab == categoryName) then
			clone.Visible = true
			middleUI_container:WaitForChild("upperText"):WaitForChild("text"):WaitForChild("text").Text = currentAbilityTab
		end
		clone.Parent = middleUI_holder
	end
end

generateAbilities()

local function addConnection(item)
	local slot = item:WaitForChild("slot")
	local name = item:WaitForChild("name")

	slot:WaitForChild("button").InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then --// clicks
			if (name.Value == "") then return end
			startDrag = item
			endDrag = item
		elseif (input.UserInputType == Enum.UserInputType.MouseMovement) then --// hovers
			endDrag = item
		elseif (input.UserInputType == Enum.UserInputType.Touch) then
			if (input == thumbstick_input) then
				--print("registered thumbstick over slot")
				return
			end
			if input.UserInputState==Enum.UserInputState.Begin then --// clicks
				if not startDrag then
					if (name.Value == "") then return end 
					focused_input = input
					startDrag = item
					endDrag = item
				end
			elseif input.UserInputState==Enum.UserInputState.Change then --// hovers
				if startDrag then
					endDrag = item
				end
			end
		end
	end)

	slot:WaitForChild("button").InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseMovement then --// hovers
			if endDrag and endDrag==item then
				endDrag=nil
			end
		elseif input.UserInputType==Enum.UserInputType.Touch then
			if input.UserInputState==Enum.UserInputState.Change then --// hovers
				if endDrag and endDrag==item then
					endDrag=nil
				end
			end
		end
	end)

end

for _,category in pairs(middleUI_holder:GetChildren()) do 
	if (category.Name ~= "clone") then
		for _,slot in pairs(category:GetChildren()) do 
			if (slot:IsA("Frame")) then
				addConnection(slot)
			end
		end
	end
end

local function generateAbilityDescription(ability)

	if not _G.currencyTextSize then
		repeat task.wait() until _G.currencyTextSize
	end

	ability.slot.ImageRectOffset = Vector2.new(256,0)
	local top = middleUI_lowerText:WaitForChild("1top")
	local bottom = middleUI_lowerText:WaitForChild("2bottom")
	local button = middleUI_lowerText:WaitForChild("3buttonContainer")
	local abilityFolder = abilities[ability.category.Value][ability.name.Value]
	local unlocked = abilityFolder.Unlocked.Value
	ability.slot.icon.ImageTransparency = unlocked and 0 or .5
	local level = abilityFolder.Level.Value
	local item = items[ability.category.Value][ability.name.Value]
	local bottom_button = button:WaitForChild("text"):WaitForChild("button")
	--local upgradeText = top:WaitForChild("2price"):WaitForChild("text"):WaitForChild("text")
	local nameText = top:WaitForChild("1name"):WaitForChild("text"):WaitForChild("text")
	nameText.TextSize=_G.currencyTextSize
	local description = bottom:WaitForChild("text"):WaitForChild("text")
	description.TextSize=_G.currencyTextSize
	local price = top:WaitForChild("2price")
	local cash = price:WaitForChild("text"):WaitForChild("cash")
	local robux = price:WaitForChild("text"):WaitForChild("robux")
	local levelCap = 12
	button.Visible = level < levelCap and true or false 
	bottom_button.Text = unlocked and "upgrade" or "unlock"
	nameText.Text = unlocked and ability.name.Value..": Level "..level or ability.name.Value

	robux.Visible = false--unlocked == false and true or false
	cash.Visible = true--unlocked == true and true or false

	price.Visible = level < levelCap and true or false

	local stringHeight = robux:WaitForChild("text").AbsoluteSize.Y
	local stringLength = math.ceil(stringHeight*0.37)

	local text=unlocked and _math.giveNumberCommas(_math.getPriceFromLevel(level,item.upgrade)) or _math.giveNumberCommas(tostring(item.cost))

	--robux:WaitForChild("text").Size = UDim2.new(0,stringLength*#tostring(item.cost),0,stringHeight)
	--robux:WaitForChild("text").TextSize=_G.currencyTextSize
	--robux:WaitForChild("text").Text = item.cost

	cash:WaitForChild("text").Size = UDim2.new(0,stringLength*#text,0,stringHeight)
	cash:WaitForChild("text").TextSize=_G.currencyTextSize
	cash:WaitForChild("text").Text = text

	local desc = item.desc
	local misc = item.misc

	local function returnNumber(t)
		if (t == nil) or t.base == 0 then return "" end
		--return _math.nearest(t.base + ((t.multiplier * level) - t.multiplier))
		local stat = _math.getStat(level,t.base,t.multiplier)
		return stat
	end

	local strings = {
		[1] = "",
		[2] = "",
		[3] = ""
	}

	for i = 1,#desc do
		strings[i] = desc[i]..returnNumber(misc[i])
	end

	description.Text = table.concat(strings)

	middleUI_lowerText.Visible = true
end

--generateAbilityDescription(ABILITY_SELECTED)

local slides_names = {
	["Melee"] = 1,
	["Ranged"] = 2,
	["Travel"] = 3,
	["Traps"] = 4,
	["Special"] = 5
}

local slides_numbers = {
	[1] = "Melee",
	[2] = "Ranged",
	[3] = "Travel",
	[4] = "Traps",
	[5] = "Special"
}

local dots=middleUI_container:WaitForChild("dots")
local function changeText(s)
	for _,child in dots:GetChildren() do
		if child:IsA("ImageLabel") then continue end
		child.Text=s.."/"..tostring(#slides_numbers)
	end
	effects:TweenDots(dots)
end
changeText("1")

local function changeMiddleUISlide(direction)
	ABILITY_SELECTED.slot.ImageRectOffset = Vector2.new(0,0)
	buttonSound:Play()
	if (direction == "left") then
		currentAbilityTab = slides_names[currentAbilityTab] == 1 and slides_numbers[#slides_numbers] or slides_numbers[slides_names[currentAbilityTab]-1]	
	elseif (direction == "right") then
		currentAbilityTab = slides_names[currentAbilityTab] == #slides_numbers and slides_numbers[1] or slides_numbers[slides_names[currentAbilityTab]+1]	
	end
	middleUI_upperText:WaitForChild("text"):WaitForChild("text").Text = currentAbilityTab
	for _,child in pairs(middleUI_holder:GetChildren()) do
		if (slides_names[child.Name] ~= nil) then
			child.Visible = child.Name == currentAbilityTab and true or false
		end
	end
	currentTab.Value = currentAbilityTab
	ABILITY_SELECTED = middleUI_holder[currentAbilityTab]["1"] -- select the first slot in the newly opened tab
	generateAbilityDescription(ABILITY_SELECTED)
	changeText(tostring(slides_names[currentAbilityTab]))
end

middleUI_left:WaitForChild("bg"):WaitForChild("button").Activated:Connect(function()
	effects:TweenNavButton(middleUI_left.bg)
	changeMiddleUISlide("left")
end)

middleUI_right:WaitForChild("bg"):WaitForChild("button").Activated:Connect(function()
	effects:TweenNavButton(middleUI_right.bg)
	changeMiddleUISlide("right")
end)

local function abilityActivated(ability)
	buttonSound:Play()
	if (ABILITY_SELECTED ~= ability) then -- prevents redo of same ability
		ABILITY_SELECTED.slot.ImageRectOffset = Vector2.new(0,0)
		ABILITY_SELECTED = ability
		ABILITY_SELECTED.slot.ImageRectOffset = Vector2.new(256,0)
		generateAbilityDescription(ability)
	end
end

local function clearHotbarAbility()
	if (HOTBAR_ABILITY_SELECTED ~= nil) then
		HOTBAR_ABILITY_SELECTED.slot.ImageRectOffset = Vector2.new(0,0)
		HOTBAR_ABILITY_SELECTED = nil
	end
	hotbar_container:WaitForChild("Selected").Value = 0
end

local twitterUI=playerGui:WaitForChild("twitterUI")

_G.hotbarAbilityActivated=function(ability)
	if not ability then return end
	if isClimbing.Value then return end
	if isSwimming.Value then return end
	if _G.cutscenePlaying then return end
	if _G.dialogueEngaged then return end -- don't allow ability selection during dialogue
	if not (player.Character and player.Character:WaitForChild("Humanoid").Health > 0) then return end
	if cs:HasTag(player.Character,"ragdolled") then return end
	--[[
	if (isSprinting.Value) then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid and humanoid.MoveDirection.Magnitude > 0 then return end -- only return if you're moving while sprinting
	end
	]]
	if (ability.name.Value == "") then return end
	
	if (HOTBAR_ABILITY_SELECTED == ability) then -- turn it off
		rs:WaitForChild("ui_sound"):WaitForChild("unselect"):Play()
		clearHotbarAbility()
		return
	end
	
	buttonSound:Play()
	if (HOTBAR_ABILITY_SELECTED ~= ability) then -- prevents redo of same ability
		if (HOTBAR_ABILITY_SELECTED ~= nil) then
			HOTBAR_ABILITY_SELECTED.slot.ImageRectOffset = Vector2.new(0,0)
		end
		HOTBAR_ABILITY_SELECTED = ability
		HOTBAR_ABILITY_SELECTED.slot.ImageRectOffset = Vector2.new(256,0)
	end
	hotbar_container:WaitForChild("Selected").Value = HOTBAR_ABILITY_SELECTED.Name
end

local function removeItem(_remove,clientOnly) -- can only remove from hotbar
	local data = {
		tonumber(_remove.Name)
	}
	_remove.slot.icon.ImageRectOffset = Vector2.new(0,0)
	_remove.slot.ImageTransparency = 0.5
	_remove.slot.icon.Visible = false
	_remove.name.Value = ""
	_remove.category.Value = ""
	_remove.cooldown.Value=false
	--_remove.cooldownTimer.Value="0"
	
	--print("removed",_remove.Name)
	
	if not (clientOnly) then
		dragRemote:FireServer("remove",data)
	end
	if _remove==HOTBAR_ABILITY_SELECTED then
		clearHotbarAbility()
	end
end

local function addItem(_start,_end) -- goes from abilities to hotbar only
	dragSound:Play()

	local data = {
		_start.category.Value, -- start category
		_start.name.Value, -- start ability
		tonumber(_end.Name) -- end pos
	}

	_end.slot.icon.ImageRectOffset = _start.slot.icon.ImageRectOffset
	_end.slot.ImageTransparency = 0
	_end.slot.icon.Visible = true
	_end.name.Value = _start.name.Value
	_end.category.Value = _start.category.Value
	
	--print("added to",_end.Name)
	
	dragRemote:FireServer("add",data)
end

local function swapItem(_start,_end) -- can only swap in hotbar
	dragSound:Play()
	
	local data = {
		tonumber(_start.Name),
		tonumber(_end.Name)
	}
	
	local startData = items[_start.category.Value][_start.name.Value]
	local startName = _start.name.Value
	local startCategory = _start.category.Value
	local endData = items[_end.category.Value][_end.name.Value]
	local endName = _end.name.Value
	local endCategory = _end.category.Value
	
	_start.category.Value = endCategory
	_start.name.Value = endName
	_start.slot.icon.ImageRectOffset = endData.offset
	
	_end.category.Value = startCategory
	_end.name.Value = startName
	_end.slot.icon.ImageRectOffset = startData.offset
	
	clearHotbarAbility()
	dragRemote:FireServer("swap",data)
end

local function moveItem(_start,_end) -- moving hotbar item to empty slot in hotbar
	dragSound:Play()
	local data = {
		tonumber(_start.Name),
		tonumber(_end.Name)
	}
	
	_end.slot.icon.ImageRectOffset = _start.slot.icon.ImageRectOffset
	_end.name.Value = _start.name.Value
	_end.category.Value = _start.category.Value
	_end.slot.ImageTransparency = 0
	_end.slot.icon.Visible = true
	
	removeItem(_start,true) -- client only
	
	print("moved",_start.Name,"to",_end.Name)
	
	clearHotbarAbility()
	dragRemote:FireServer("swap",data)
end

local function processDrag(x,y,touch)
	if (endDrag) then -- you were over a slot
		if (startDrag) then
			if (startDrag == endDrag) then -- you fully clicked a slot
				if (startDrag:IsDescendantOf(middleUI)) then
					abilityActivated(startDrag)
				elseif (startDrag:IsDescendantOf(hotbarUI)) then
					_G.hotbarAbilityActivated(startDrag)
				end
			elseif (startDrag ~= endDrag) then -- dragged to another slot
				if not (abilities[startDrag.category.Value][startDrag.name.Value].Unlocked.Value) then return end
				if (startDrag:IsDescendantOf(middleUI)) and (endDrag:IsDescendantOf(hotbarUI)) then
					addItem(startDrag,endDrag)
				elseif (startDrag:IsDescendantOf(hotbarUI)) and (endDrag:IsDescendantOf(hotbarUI)) then
					if (endDrag.name.Value ~= "") then
						swapItem(startDrag,endDrag)
					else
						moveItem(startDrag,endDrag)
					end
				end
			end
		end
	elseif not (endDrag) then -- you weren't over any slot
		if (startDrag) then
			if (startDrag:IsDescendantOf(hotbarUI)) then
				if (_math.checkBounds2D(trashUI:WaitForChild("slot"),x,y)) then
					removeItem(startDrag)
				end
			end
		end
	end
end

local function generateHotbar()
	for _,element in pairs(hotbar_container:GetChildren()) do
		if (element:IsA("Frame")) then
			local folder = hotbar[element.Name]
			local name = element:WaitForChild("name")
			local category = element:WaitForChild("category")
			name.Value = folder.Ability.Value
			category.Value = folder.Category.Value
			local slot = element:WaitForChild("slot")
			if (name.Value ~= "") and (category.Value ~= "") then
				local item = items[category.Value][name.Value]
				slot.ImageTransparency = 0
				slot:WaitForChild("icon").ImageRectOffset = item.offset
				slot:WaitForChild("icon").Visible = true
			else 
				slot.ImageTransparency = .5
				slot:WaitForChild("icon").ImageRectOffset = Vector2.new(0,0)
				slot:WaitForChild("icon").Visible = false
			end
		end
	end
end

generateHotbar()

for key,slot in pairs(hotbar_container:GetChildren()) do 
	if (slot:IsA("Frame")) then
		addConnection(slot)
	end
end

local leftUIChoices = {
	["1shop"] = shopUI,
	["2suit"] = skinsUI,
	["3abilities"] = middleUI,
	["4twitter"] = twitterUI,
	["5rebirth"] = rebirthUI
}

local blur = game:GetService("Lighting"):WaitForChild("Blur")
local leftUISelected = leftUI:WaitForChild("selected")
local hotbarAbilitySelected = hotbarUI:WaitForChild("container"):WaitForChild("Selected")

local currentLeftUITab = nil
local function updateLeftUIChoice()
	for name,ui in pairs(leftUIChoices) do 
		ui.Enabled = currentLeftUITab ~= nil and name == currentLeftUITab.Name and true or false
	end
	blur.Enabled = currentLeftUITab ~= nil
	leftUISelected.Value = currentLeftUITab
	if currentLeftUITab ~= nil then -- you just opened a tab, you need to make sure if you have your ots cam on you turn it off
		OTS_CAM_HDLR.Deactivate()
	else -- there are no tabs open now
		if hotbarAbilitySelected.Value ~= 0 and not isClimbing.Value and not isSwimming.Value then
			--print("activated from leftui")
			OTS_CAM_HDLR.Activate()
		end
	end
end

local leftUI_container=leftUI:WaitForChild("container")
local inner=leftUI_container:WaitForChild("inner")
local outer=leftUI_container:WaitForChild("outer")

local leftUI_tabs={
	inner:WaitForChild("1shop"),
	inner:WaitForChild("4twitter"),
	inner:WaitForChild("5rebirth"),
	outer:WaitForChild("2suit"),
	outer:WaitForChild("3abilities")
}

for _,element in leftUI_tabs do
	local button=element:WaitForChild("bg"):WaitForChild("button")
	button.Activated:Connect(function()
		local tab = button.Parent.Parent
		if (currentLeftUITab ~= nil) then
			if (currentLeftUITab ~= tab) then
				currentLeftUITab.bg.ImageRectOffset = Vector2.new(0,0)
				currentLeftUITab = tab
				buttonSound:Play()
				currentLeftUITab.bg.ImageRectOffset = Vector2.new(256,0)
			elseif (currentLeftUITab == tab) then
				rs:WaitForChild("ui_sound"):WaitForChild("unselect"):Play()
				currentLeftUITab.bg.ImageRectOffset = Vector2.new(0,0)
				currentLeftUITab = nil
			end
		else
			currentLeftUITab = tab
			buttonSound:Play()
			currentLeftUITab.bg.ImageRectOffset = Vector2.new(256,0)
		end
		updateLeftUIChoice()
	end)
end

local function detectUpgrade()
	local f = coroutine.wrap(_G.tweenButton)
	f(middleUI_upgrade_button.Parent.Parent)
	local abilityValue = abilities[ABILITY_SELECTED.category.Value][ABILITY_SELECTED.name.Value]
	local item=items[ABILITY_SELECTED.category.Value][ABILITY_SELECTED.name.Value]
	if (abilityValue.Unlocked.Value) then -- you already own this and want to upgrade it
		local cost = _math.getPriceFromLevel(abilityValue.Level.Value,item.upgrade)
		local cash = dataFolder.Cash.Value
		if (cost <= cash) then
			buttonSound2:Play()
			abilityRemote:FireServer(ABILITY_SELECTED.category.Value,ABILITY_SELECTED.name.Value)
		else 
			errorSound:Play()
			local deficit=cost-cash
			sales:PromptProduct(sales:ClosestProduct(deficit),player)
			--// maybe have the cash shop open up here
		end
	else -- you didn't unlock it yet, person wants to unlock it
		local cost=item.cost
		local cash = dataFolder.Cash.Value
		if cost<=cash then
			abilityRemote:FireServer(ABILITY_SELECTED.category.Value,ABILITY_SELECTED.name.Value)
			buttonSound2:Play()
		else
			errorSound:Play()
			local deficit=cost-cash
			sales:PromptProduct(sales:ClosestProduct(deficit),player)
		end
		-- send message to server to unlock
	end
end

middleUI_upgrade_button.Activated:Connect(detectUpgrade)

local function close()
	buttonSound:Play()
	currentLeftUITab.bg.ImageRectOffset = Vector2.new(0,0)
	currentLeftUITab = nil
	updateLeftUIChoice()
end

middleUI_exit:WaitForChild("bg"):WaitForChild("button").Activated:Connect(close)

local rebirthExit = rebirthUI:WaitForChild("bg"):WaitForChild("exit"):WaitForChild("exit")
local rebirthExitButton = rebirthExit:WaitForChild("bg"):WaitForChild("button")
rebirthExitButton.Activated:Connect(close)

local shopExit=shopUI:WaitForChild("container"):WaitForChild("bg_container"):WaitForChild("5"):WaitForChild("exit")
local shopExitButton=shopExit:WaitForChild("bg"):WaitForChild("button");
shopExitButton.Activated:Connect(close)

local twitterExit=twitterUI:WaitForChild("bg"):WaitForChild("exit"):WaitForChild("exit")
local twitterExitButton=twitterExit:WaitForChild("bg"):WaitForChild("button")
twitterExitButton.Activated:Connect(close)

local isOutsideStartDrag = false

local function addDrag(child,x,y)
	child:WaitForChild("slot"):WaitForChild("icon").Visible = false -- turn the startDrag's image to false
	local example = dragUI:WaitForChild("example")
	local clone = example:Clone()
	clone.Visible = true
	local item = items[child:WaitForChild("category").Value][child:WaitForChild("name").Value]
	clone.image.ImageRectOffset = item.offset
	clone.Position = UDim2.new(0,x - _math.nearest(clone.AbsoluteSize.X/2),0,y - _math.nearest(clone.AbsoluteSize.Y/2))
	clone.Name = "clone"
	clone.Parent = dragUI
end

local function removeDrag()
	local clone = dragUI:FindFirstChild("clone")
	if (clone) then
		clone:Destroy()
	end
end

local function resetTrash()
	trashUI.Enabled = false
	trashUI:WaitForChild("slot").ImageRectOffset = Vector2.new(128,0)
end

--trashUI:WaitForChild("slot"):GetPropertyChangedSignal("ImageRectOffset"):Connect(function()
	--if (trashUI:WaitForChild("slot").ImageRectOffset == Vector2.new(256,0)) then
		--dragSound:Play()
	--end
--end)

local focused_input_position = rs:WaitForChild("focused_input_position")

local function touchStarted(touch)
	if (touchGui) then 
		local thumbstickFrame = touchGui:WaitForChild("TouchControlFrame"):WaitForChild("DynamicThumbstickFrame")
		if (_math.checkBounds2D(thumbstickFrame,touch.Position.X,touch.Position.Y)) then
			game:GetService("RunService").RenderStepped:Wait() -- delay gives time for slot input to register
			if (touch ~= focused_input) then 
				thumbstick_input = touch
				--print("found thumbstick input!")
			end
		end
	end
end

local function touchMoved(touch,gpe)
	if not touchMove then
		touchMove = touch
		focused_input_position.Value=gpe and focused_input_position.Value or Vector3.new(touch.Position.X,touch.Position.Y,0)
	else 
		if touch == touchMove then
			focused_input_position.Value=gpe and focused_input_position.Value or Vector3.new(touch.Position.X,touch.Position.Y,0)
		end
	end
	if (touch == focused_input) then
		local x,y = focused_input.Position.X,focused_input.Position.Y
		--[[
		if (endDrag) then -- make sure you're inside endDrag or make it nil
			if not (_math.checkBounds2D(endDrag,x,y)) then
				print("input went outside of endDrag")
				endDrag = nil
			end
		end
		]]
		if (startDrag) then
			local isHotbarDescendant = startDrag:IsDescendantOf(hotbarUI)
			local isInsideTrash = _math.checkBounds2D(trashUI:WaitForChild("slot"),x,y)
			trashUI.Enabled = isHotbarDescendant and isOutsideStartDrag and y < hotbar_container.AbsolutePosition.Y
			--trashUI:WaitForChild("slot").ImageRectOffset = isHotbarDescendant and isInsideTrash and Vector2.new(256,0) or Vector2.new(128,0)

			if (abilities[startDrag.category.Value][startDrag.name.Value].Unlocked.Value) then
				if not (_math.checkBounds2D(startDrag:WaitForChild("slot"),x,y)) then
					if (isOutsideStartDrag == false) then
						isOutsideStartDrag = true
						dragSound:Play()			
					end
				else
					isOutsideStartDrag = false
				end
				local drag_clone = dragUI:FindFirstChild("clone")
				if (drag_clone) then
					drag_clone.Position = UDim2.new(0,x - _math.nearest(drag_clone.AbsoluteSize.X/2),0,y - _math.nearest(drag_clone.AbsoluteSize.Y/2))
				elseif not (drag_clone) and (startDrag) then
					addDrag(startDrag,x,y)
				end
			end
		end
	elseif (touch ~= focused_input) and (touch ~= thumbstick_input) then 
		local NO_UI = middleUI.Enabled == false and skinsUI.Enabled == false
		if (NO_UI) and gpe==false then 
			OTS_CAM_HDLR.Update(Vector2.new(touch.Delta.X,touch.Delta.Y))
		end
	end
end

local function touchEnded(touch)
	if touch == touchMove then
		touchMove = nil
		focused_input_position.Value = Vector3.new(0,0,0)
	end
	if (touch == focused_input) then
		resetTrash()
		isOutsideStartDrag = false
		if (startDrag) then
			startDrag:WaitForChild("slot"):WaitForChild("icon").Visible = true -- show the image again
			processDrag(focused_input.Position.X,focused_input.Position.Y)
			startDrag = nil
			endDrag = nil
			removeDrag()			
		end
		focused_input = nil
	elseif (touch == thumbstick_input) then 
		thumbstick_input = false
	end
end

local hotKeys = {
	[Enum.KeyCode.One] = hotbar_container:WaitForChild("1"),
	[Enum.KeyCode.Two] = hotbar_container:WaitForChild("2"),
	[Enum.KeyCode.Three] = hotbar_container:WaitForChild("3"),
	[Enum.KeyCode.Four] = hotbar_container:WaitForChild("4"),
	[Enum.KeyCode.Five] = hotbar_container:WaitForChild("5"),
	[Enum.KeyCode.Six] = hotbar_container:WaitForChild("6"),
	[Enum.KeyCode.Seven] = hotbar_container:WaitForChild("7"),
	[Enum.KeyCode.Eight] = hotbar_container:WaitForChild("8"),
}

local function inputBegan(input,gpe)
	if gpe then return end
	if (input.UserInputType == Enum.UserInputType.Keyboard) then 
		local value = hotKeys[input.KeyCode]
		if (value ~= nil) then
			_G.hotbarAbilityActivated(value)
		end
	end
end

local function inputChanged(input,gpe)
	if (input.UserInputType == Enum.UserInputType.MouseMovement) then
		OTS_CAM_HDLR.Update(uis:GetMouseDelta())
		focused_input_position.Value=gpe and focused_input_position.Value or Vector3.new(input.Position.X,input.Position.Y,0)
		--[[
		if (endDrag) then
			if not (_math.checkBounds2D(endDrag:WaitForChild("slot"),mouse.X,mouse.Y)) then
				endDrag = nil
			end
		end
		]]
		if (startDrag) then
			local isHotbarDescendant = startDrag:IsDescendantOf(hotbarUI)
			local isInsideTrash = _math.checkBounds2D(trashUI:WaitForChild("slot"),mouse.X,mouse.Y)
			trashUI.Enabled = isHotbarDescendant and isOutsideStartDrag and mouse.Y < hotbar_container.AbsolutePosition.Y
			--trashUI:WaitForChild("slot").ImageRectOffset = isHotbarDescendant and isInsideTrash and Vector2.new(256,0) or Vector2.new(128,0)
			if (abilities[startDrag.category.Value][startDrag.name.Value].Unlocked.Value) then
				if not (_math.checkBounds2D(startDrag:WaitForChild("slot"),mouse.X,mouse.Y)) then
					if not (isOutsideStartDrag) then
						isOutsideStartDrag = true
						dragSound:Play()					
					end
				else
					isOutsideStartDrag = false
				end
				local drag_clone = dragUI:FindFirstChild("clone")
				if (drag_clone) then
					drag_clone.Position = UDim2.new(0,mouse.X - _math.nearest(drag_clone.AbsoluteSize.X/2),0,mouse.Y - _math.nearest(drag_clone.AbsoluteSize.Y/2))
				elseif not (drag_clone) then
					addDrag(startDrag,mouse.X,mouse.Y)
				end
			end
		end	
	end
end

local ActionButtonDown=temp:WaitForChild("ActionButtonDown")

local function inputEnded(input)
	local x,y = mouse.X,mouse.Y
	if (input.UserInputType == Enum.UserInputType.Keyboard) then
	elseif (input.UserInputType == Enum.UserInputType.MouseButton1) then
		resetTrash()
		isOutsideStartDrag = false
		if (startDrag) then
			startDrag:WaitForChild("slot"):WaitForChild("icon").Visible = true -- show the image again
			processDrag(x,y)
			startDrag = nil
			endDrag = nil
			removeDrag()			
		end
		ActionButtonDown.Value=false
	end
end

_G.deathScreenStatus=false
local function updateUI()
	if (_G.cutscenePlaying) or _G.deathScreenStatus==true then
		interface.updateUI(false)
	else
		interface.updateUI(true)
	end	
end
updateUI()

local abilityLevels = {}

for _,category in pairs(abilities:GetChildren()) do
	for _,ability in pairs(category:GetChildren()) do
		local level = ability:WaitForChild("Level")
		abilityLevels[ability.Name] = level.Value
		ability:WaitForChild("Level"):GetPropertyChangedSignal("Value"):Connect(function()
			local oldLevel = abilityLevels[ability.Name]
			if oldLevel < level.Value then
				upgradeSound:Play()	
			end
			if middleUI.Enabled then
				generateAbilityDescription(ABILITY_SELECTED)
			end
		end)
		ability:WaitForChild("Unlocked"):GetPropertyChangedSignal("Value"):Connect(function()
			upgradeSound:Play()
			generateAbilityDescription(ABILITY_SELECTED)
		end)
	end
end

-- mobile
uis.TouchMoved:Connect(touchMoved)
uis.TouchEnded:Connect(touchEnded)
uis.TouchStarted:Connect(touchStarted)
-- PC
uis.InputChanged:Connect(inputChanged)
uis.InputBegan:Connect(inputBegan)
uis.InputEnded:Connect(inputEnded)

local objectiveUI=playerGui:WaitForChild("objectiveUI")
local cashUI = playerGui:WaitForChild("cashUI")
local comboUI = playerGui:WaitForChild("comboUI")
local comicUI = playerGui:WaitForChild("comicUI")

_G.deathScreen = function(bool)
	if _G.deathScreenStatus==bool then return end
	_G.deathScreenStatus=bool
	--print("deathScreen = ",bool)
	if bool == true then
		leftUI.Enabled = false
		hotbarUI.Enabled = false
		cashUI.Enabled = false
		comicUI.Enabled = false
		objectiveUI.Enabled=false
		controlsUI.Enabled=false
		comboUI.Enabled=false
		if currentLeftUITab then
			currentLeftUITab.bg.ImageRectOffset = Vector2.new(0,0)
			currentLeftUITab = nil
			leftUISelected.Value = nil
		end
		for i,v in pairs(leftUIChoices) do
			if v ~= nil then
				v.Enabled = false	
			end
		end
		if focused_input == nil then
			focused_input = {
				Position = Vector2.new(0,0)
			}
		end
		touchEnded(focused_input)
		local mockInput = {
			input = {
				UserInputType = Enum.UserInputType.MouseButton1
			}
		}
		inputEnded(mockInput)	
		blur.Enabled = false
		if hotbarAbilitySelected.Value ~= 0 and not isClimbing.Value and not isSwimming.Value then
			if not OTS_CAM_HDLR.cameraToggle then -- make sure ots cam is off first
				--print("activated ots from manager")
				OTS_CAM_HDLR.Activate()
			end
		end
	elseif bool == false then
		leftUI.Enabled = true
		hotbarUI.Enabled = true
		cashUI.Enabled = true
		objectiveUI.Enabled=true
		controlsUI.Enabled=true
		comboUI.Enabled=true
		comicUI.Enabled = true
	end
end

local lastPlatform = _G.platform
local lastCheckWasFalse = false

local screenSize = workspace.CurrentCamera.ViewportSize
_G.Scaling = false

local function checkScaling()
	if (_G.Scaling == true) then return end
	_G.Scaling = true

	screenSize = workspace.CurrentCamera.ViewportSize
	for i = 1,math.huge do
		wait(.5)
		if (workspace.CurrentCamera.ViewportSize == screenSize) then 
			break 
		else
			screenSize = workspace.CurrentCamera.ViewportSize
		end
	end
	
	updateUI()
	interface.objectiveUI() -- do the objective separately
	_G.Scaling = false
end

local world_sound = game:GetService("SoundService"):WaitForChild("world")

local function UI_changed()
	if blur.Enabled then
		world_sound.Volume = 0
		ui_loop_sound:Play()
	else 
		world_sound.Volume = 1
		ui_loop_sound:Stop()
	end
end

local tweenInfo2=TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,true,0)
local function TweenNavButtons()
	-- make sure buttons are at original positions first
	middleUI_right.Position=UDim2.new(1,0,0.5,0)
	middleUI_left.Position=UDim2.new(0,0,0.5,0)
	local offset=math.round(_G.slot_size/2)
	ts:Create(middleUI_right,tweenInfo2,{Position=UDim2.new(1,offset,.5,0)}):Play()
	ts:Create(middleUI_left,tweenInfo2,{Position=UDim2.new(0,-offset,.5,0)}):Play()
end

middleUI:GetPropertyChangedSignal("Enabled"):Connect(function()
	if middleUI.Enabled then
		generateAbilityDescription(ABILITY_SELECTED)
		TweenNavButtons()
	end
end)

blur:GetPropertyChangedSignal("Enabled"):Connect(UI_changed)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(checkScaling)

while true do
	wait(.5)
	detectDevice()
	if (_G.platform ~= lastPlatform) then
		lastPlatform = _G.platform
		for _,slot in pairs(hotbar_container:GetChildren()) do
			if (slot:IsA("Frame")) then 
				slot:WaitForChild("slot"):WaitForChild("number").Visible = lastPlatform == "PC" and true or false
			end
		end
		updateUI()
	end
end