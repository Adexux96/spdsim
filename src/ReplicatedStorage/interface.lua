local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local GuiService=game:GetService("GuiService")
local TopbarSize=GuiService:GetGuiInset()
--print(TopbarSize.Y)

local player = game.Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local temp = leaderstats:WaitForChild("temp")
local isSwimming = temp:WaitForChild("isSwimming")
local isClimbing = temp:WaitForChild("isClimbing")
local playerGui = player:WaitForChild("PlayerGui")
local playUI = playerGui:WaitForChild("playUI")
local targetUI = playerGui:WaitForChild("targetUI")
local middleUI = playerGui:WaitForChild("middleUI")
local leftUI = playerGui:WaitForChild("leftUI")
local skinsUI = playerGui:WaitForChild("skinsUI")
local advertsUI = playerGui:WaitForChild("adverts")
local cashUI = playerGui:WaitForChild("cashUI")
local hotbarUI = playerGui:WaitForChild("hotbarUI")
local dragUI = playerGui:WaitForChild("dragUI")
local trashUI = playerGui:WaitForChild("trashUI")
local damageUI = playerGui:WaitForChild("damageUI")
local rebirthUI = playerGui:WaitForChild("rebirthUI")
local controlsUI=playerGui:WaitForChild("controlsUI")
local shopUI=playerGui:WaitForChild("shopUI")
local countdownUI=playerGui:WaitForChild("countdownUI")
local twitterUI=playerGui:WaitForChild("twitterUI")
local tutorialUI=playerGui:WaitForChild("tutorialUI")
local objectiveUI=playerGui:WaitForChild("objectiveUI")
local textUI=playerGui:WaitForChild("textUI")
local dialogueUI=playerGui:WaitForChild("dialogueUI")
local notificationUI=playerGui:WaitForChild("notificationUI")
local progressUI=playerGui:WaitForChild("progressUI")
local comboUI=playerGui:WaitForChild("comboUI")
local comicUI=playerGui:WaitForChild("comicUI")

local tipUI=playerGui:WaitForChild("tipUI")

local _math = require(game:GetService("ReplicatedStorage"):WaitForChild("math"))
local panel_X_size
local panel_X_offset = 0.0963541666666667
local panel_Y_size
local panel_Y_offset = 0.0880503144654088
local panel_holder_size
_G.screenSize = Vector2.new(0,0)
local slot_size
local _4X_Slot_Size
local half_slot_size
local _85_percent_slot_size
local double_slot_size
local slot_offset
local robux_size
local half_X

-- ratios given are X/Y
local holder_ratios = {
	[2] = {
		[1] = {0.87109375,0.27}, -- ratio, slot X Offset
		[2] = {0.41796875,0.37}
	},
	[3] = {
		[1] = {0.87109375,0.27}, -- ratio, slot X Offset
		[2] = {0.765625,0.18},
		[3] = {0.41796875,0.37}
	},
}

local holder_offsets = {
	[2] = {
		[1] = Vector2.new(0,0),
		[2] = Vector2.new(419,0)
	},
	[3] = {
		[1] = Vector2.new(0,0),
		[2] = Vector2.new(223,0),
		[3] = Vector2.new(419,0)
	}
}

local holder_sizes = {
	[2] = {
		[1] = Vector2.new(223,256),
		[2] = Vector2.new(107,256)
	},
	[3] = {
		[1] = Vector2.new(223,256),
		[2] = Vector2.new(196,256),
		[3] = Vector2.new(107,256)
	}
}

local interface = {}

local function position_to_middle(container)
	local hotbar_y_pos = _G.screenSize.Y - (slot_size + slot_offset)
	local adverts_y_pos = advertsUI:WaitForChild("container").AbsoluteSize.Y
	local y_space = hotbar_y_pos - adverts_y_pos
	local middle_size_y = container.AbsoluteSize.Y + ((slot_offset * 2) + (slot_size * 2))
	local wiggle_room = y_space - middle_size_y
	local yPos
	if (wiggle_room > 0) then
		yPos = _math.nearest(adverts_y_pos + (wiggle_room/2))
	else
		yPos = adverts_y_pos
	end
	container.Position = UDim2.new(.5,0,0,yPos)
end

local function getHolderContentSize(numValue,beforeLast)
	local lastHolderXFullSize = 0
	if (beforeLast == false) then
		local lastHolderXSize = _math.nearest(holder_ratios[numValue][numValue][1] * double_slot_size)
		local lastHolderOffset = _math.nearest(lastHolderXSize * holder_ratios[numValue][numValue][2])
		lastHolderXFullSize = lastHolderOffset + slot_size
	end
	for i = 1,numValue-1 do
		lastHolderXFullSize += _math.nearest(holder_ratios[numValue][i][1] * double_slot_size)
	end
	return lastHolderXFullSize
end

local function sizeTextBGComponents(x,y,components)
	local list = {
		[1] = y,
		[2] = x - (y*2),
		[3] = y
	}
	for i,component in pairs(components) do
		component.Size = UDim2.new(0,list[tonumber(component.Name)],0,y)
	end
end

local function size_icon_with_text(parent,y,textSize)
	parent:WaitForChild("list").Padding=UDim.new(0,slot_offset)
	parent:WaitForChild("icon").Size=UDim2.new(0,y,0,y)

	local stringHeight = y
	local stringLength = math.ceil(stringHeight*0.37) --//titillium web font compliant

	local text=parent:WaitForChild("text")
	text.TextSize = textSize or y
	text.Size = UDim2.new(0,stringLength*#text.Text,0,stringHeight)
end

local function sizeLowerText(lowerText)
	lowerText.Size = UDim2.new(1,0,0,half_slot_size)

	local top = lowerText:WaitForChild("1top")
	local name = top:WaitForChild("1name")
	name.Size = UDim2.new(0,half_X,0,half_slot_size)
	name:WaitForChild("text"):WaitForChild("text").TextSize = _G.currencyTextSize
	sizeTextBGComponents(half_X,half_slot_size,{name:WaitForChild("1"),name:WaitForChild("2"),name:WaitForChild("3")})
	local price = top:WaitForChild("2price")
	price.Size = UDim2.new(0,half_X,0,half_slot_size)

	local folder=price:WaitForChild("text")
	size_icon_with_text(folder:WaitForChild("cash"),half_slot_size,_G.currencyTextSize)
	size_icon_with_text(folder:WaitForChild("robux"),half_slot_size,_G.currencyTextSize)

	local custom=folder:FindFirstChild("custom")
	if custom then
		local custom_text=custom:WaitForChild("text")
		custom_text.Size=UDim2.new(1,-(slot_offset*2),1,0)
		custom_text.TextSize=_G.currencyTextSize
	end

	sizeTextBGComponents(half_X,half_slot_size,{price:WaitForChild("1"),price:WaitForChild("2"),price:WaitForChild("3")})

	local bottom = lowerText:WaitForChild("2bottom")
	bottom.Size = UDim2.new(0,half_X*3,0,half_slot_size)
	bottom:WaitForChild("text"):WaitForChild("text").TextSize = _G.currencyTextSize
	sizeTextBGComponents(half_X*3,half_slot_size,{bottom:WaitForChild("1"),bottom:WaitForChild("2"),bottom:WaitForChild("3")})

	local buttonContainer = lowerText:WaitForChild("3buttonContainer")
	local smaller_size=math.round(slot_size*.9)
	buttonContainer.Size = UDim2.new(0,smaller_size*3,0,smaller_size)
	local text = buttonContainer:FindFirstChild("text")
	if text then
		text:WaitForChild("button").TextSize = _G.currencyTextSize
	end

	for _,frame in pairs(buttonContainer:GetChildren()) do
		if frame:IsA("Frame") then
			local notificationFolder = frame:FindFirstChild("notificationFolder") 
			if notificationFolder then
				notificationFolder:WaitForChild("notificationContainer").Size = UDim2.new(0,half_slot_size,0,half_slot_size)
			end
			frame:WaitForChild("text"):WaitForChild("button").TextSize = _G.currencyTextSize
			for _,image in pairs(frame:GetChildren()) do 
				if (image:IsA("ImageLabel")) then
					image.Size = UDim2.new(0,smaller_size,0,smaller_size)
				end
			end
		elseif frame:IsA("ImageLabel") then
			frame.Size = UDim2.new(0,smaller_size,0,smaller_size)
		end
	end

end

function interface.middleUI(bool,screenSize)

	if (bool ~= nil) then
		if (_G.cutscenePlaying == nil) then repeat task.wait(1/30) until _G.cutscenePlaying ~= nil end
		if (_G.cutscenePlaying) then
			middleUI.Enabled = false
		end
	end

	local container = middleUI:WaitForChild("container")
	local lowerText = container:WaitForChild("lowerText")
	local holder = container:WaitForChild("holder")
	local exit = container:WaitForChild("exit")
	local tutorial=container:WaitForChild("tutorial")
	local left = container:WaitForChild("left")
	local right = container:WaitForChild("right")
	local bg = container:WaitForChild("bg")
	local dots=container:WaitForChild("dots")

	local dot_size=math.round(_4X_Slot_Size*.39)
	local dot_text_size=math.round(dot_size*.5)
	dots.Size=UDim2.new(0,dot_size,0,dot_size)	
	for _,textlabel in dots:GetChildren() do 
		if textlabel:IsA("TextLabel") then
			textlabel.TextSize=dot_text_size
		end
	end

	container.Size = UDim2.new(0,panel_X_size,0,panel_Y_size)
	position_to_middle(container)

	holder.Size = panel_holder_size

	left.Size = UDim2.new(0,_85_percent_slot_size,0,_85_percent_slot_size)
	left.Position = UDim2.new(0,0,0.5,0)

	right.Size = UDim2.new(0,_85_percent_slot_size,0,_85_percent_slot_size)
	right.Position = UDim2.new(1,0,0.5,0)

	exit.Size = UDim2.new(0,math.round(_85_percent_slot_size*.85),0,math.round(_85_percent_slot_size*.85))
	--exit.Position = UDim2.new(1,-math.round(slot_offset/2),0,math.round(slot_offset/2))
	exit.Position = UDim2.new(1,-slot_offset,0,slot_offset)
	
	tutorial.Size = UDim2.new(0,_85_percent_slot_size,0,_85_percent_slot_size)

	for _,list in pairs(holder:GetChildren()) do

		if list:IsA("Frame") then
			local slotsValue = list:WaitForChild("slots").Value
			local content_size = getHolderContentSize(slotsValue,false)
			local first_pos = _math.nearest((holder.AbsoluteSize.X - content_size)/2)

			for _,value in pairs(list:GetChildren()) do

				if (value:IsA("Frame")) then
					local name = tonumber(value.Name)
					local X = _math.nearest(holder_ratios[slotsValue][name][1] * double_slot_size)
					local slot,bg = value:WaitForChild("slot"),value:WaitForChild("bg")
					local xPos = first_pos + getHolderContentSize(name,true)

					value.Size = UDim2.new(0,X,0,double_slot_size)
					value.Position = UDim2.new(0, xPos,.5,0)
					slot.Size = UDim2.new(0,slot_size,0,slot_size)
					slot.Position = UDim2.new(0,_math.nearest(holder_ratios[slotsValue][name][2] * X),0.5,0)
					bg.ImageRectOffset = holder_offsets[slotsValue][name]
					bg.ImageRectSize = holder_sizes[slotsValue][name]
				end
			end			
		end

	end

	local inner_size_X=panel_X_size-math.round(panel_X_size*.2)
	local panel_size_Y=math.round(math.floor(inner_size_X/4)*.225)
	local x=math.round(panel_X_size/4)
	local upperText = container:WaitForChild("upperText")
	upperText.Size = UDim2.new(0,x,0,panel_size_Y)
	upperText:WaitForChild("text"):WaitForChild("text").TextSize =math.round(panel_size_Y*.65)
	sizeTextBGComponents(x,panel_size_Y,{upperText:WaitForChild("1"),upperText:WaitForChild("2"),upperText:WaitForChild("3")})

	lowerText:WaitForChild("UIListLayout").Padding=UDim.new(0,math.round(slot_offset*.75))
	lowerText.Size = UDim2.new(1,0,0,half_slot_size)
	sizeLowerText(lowerText)

end

function interface.skinsUI(bool)
	if (bool ~= nil) then
		if (_G.cutscenePlaying == nil) then repeat task.wait(1/30) until _G.cutscenePlaying ~= nil end
		if (_G.cutscenePlaying) then
			skinsUI.Enabled = false
		end
	end

	local container = skinsUI:WaitForChild("container")

	container.Size = UDim2.new(0,_4X_Slot_Size,0,_4X_Slot_Size)
	position_to_middle(container)

	local left = container:WaitForChild("left")
	left.Size = UDim2.new(0,_85_percent_slot_size,0,_85_percent_slot_size)--UDim2.new(0,slot_size,0,slot_size)
	left.Position = UDim2.new(0,0,0.5,0)
	local right = container:WaitForChild("right")
	right.Size = UDim2.new(0,_85_percent_slot_size,0,_85_percent_slot_size)--UDim2.new(0,slot_size,0,slot_size)
	right.Position = UDim2.new(1,0,0.5,0)

	local lowerText = container:WaitForChild("lowerText")
	lowerText:WaitForChild("UIListLayout").Padding=UDim.new(0,math.round(slot_offset*.75))
	sizeLowerText(lowerText)

	local dots=container:WaitForChild("dots")
	local ySize=dots.AbsoluteSize.Y
	for _,child in dots:GetChildren() do 
		if child:IsA("ImageLabel") then continue end
		child.TextSize=math.round(ySize*.5)
	end
	
end

function interface.hotbarUI(bool)
	if (bool ~= nil) then
		hotbarUI.Enabled = bool
	end
	local container = hotbarUI:WaitForChild("container")
	local list = container:WaitForChild("list")
	container.Size = UDim2.new(0,slot_size,0,slot_size)
	container.Position = UDim2.new(.5,0,1,-slot_offset)
	list.Padding = UDim.new(0,slot_offset)

	for _,slot in pairs(container:GetChildren()) do 
		if slot:IsA("Frame") then
			local counter = slot:WaitForChild("slot"):WaitForChild("counter")
			counter.TextSize = _math.nearest(slot_size * 0.4307692307692308)
		end
	end
end

local function size_shop_panels(panels,panel_size_Y,slot_size)
	local fontSizes={
		[Enum.Font.TitilliumWeb]=panel_size_Y,
		[Enum.Font.Bangers]=math.round(panel_size_Y*.65)
	}
	for _,panel in panels do 
		panel.Size=UDim2.new(1,0,0,panel_size_Y)
		sizeTextBGComponents(slot_size-slot_offset,panel_size_Y,{panel:WaitForChild("1"),panel:WaitForChild("2"),panel:WaitForChild("3")})
		if panel.Name=="bottom" then
			size_icon_with_text(panel:WaitForChild("Folder"),panel_size_Y)
			panel.Position=UDim2.new(0,0,1,slot_offset)
		else 
			local folder=panel:WaitForChild("Folder")
			local text=folder:WaitForChild("text")
			text.TextSize=fontSizes[text.Font] 
			panel.Position=UDim2.new(0,0,0,-slot_offset)
		end
	end
end

local function size_shop_slot_components(parent,panel_size_Y,slot_size)
	for _,slot in parent:GetChildren() do 
		if slot:IsA("Frame") then
			slot.Size=UDim2.new(0,slot_size,0,slot_size)
			size_shop_panels({slot:WaitForChild("bottom"),slot:WaitForChild("top")},panel_size_Y,slot_size)
		end
	end
end

function interface.shopUI()
	local container=shopUI:WaitForChild("container")
	local bg_container=container:WaitForChild("bg_container")
	local x=math.round(_G.screenSize.X*0.4519940915805022)
	x=math.clamp(x,256,math.huge)
	local y=math.round(x*0.3447712418300654)
	
	container.Size=UDim2.new(0,x,0,y)
	
	local outer=math.round(y*0.8867924528301887)
	local inner=math.round(y*0.3270440251572327)
	
	for _,element in bg_container:GetChildren() do 
		if element:IsA("UIListLayout") then continue end
		if element:GetAttribute("outer") then
			element.Size=UDim2.new(0,outer,1,0)
		end
		if element:GetAttribute("inner") then
			element.Size=UDim2.new(0,inner,1,0)
		end
	end
	
	local cash=container:WaitForChild("cash")
	local slot_size=math.floor(x/6)
	for _,element in cash:GetChildren() do 
		if element:IsA("UIListLayout") then continue end
		element.Size=UDim2.new(0,slot_size,0,slot_size)
	end
	
	local beach_ball=container:WaitForChild("beach_ball")
	local beach_ball_size=math.round(panel_X_size*0.1254)
	beach_ball.Size=UDim2.new(0,beach_ball_size,0,beach_ball_size)
	
	local exit=bg_container:WaitForChild("5"):WaitForChild("exit")
	exit.Size = UDim2.new(0,math.round(_85_percent_slot_size*.85),0,math.round(_85_percent_slot_size*.85))
	exit.Position = UDim2.new(1,-slot_offset,0,slot_offset)
	
	local panel_size_Y=math.round(y*0.10900)
	size_shop_slot_components(cash,panel_size_Y,slot_size)
end

--[[
function interface.shopUI()
	local inner_size_X=panel_X_size-math.round(panel_X_size*.2)
	local slot_size=math.floor(inner_size_X/4)
	local panel_size_Y=math.round(slot_size*.225)
	local panel_size_X=slot_size-slot_offset
	
	local container=shopUI:WaitForChild("container")
	container.Size=UDim2.new(0,panel_X_size,0,panel_Y_size)
	
	local slide_outer_size=math.round(panel_Y_size*0.8867924528301887)
	local slide_inner_size=math.round(panel_Y_size*0.6477987421383648) --0.3270440251572327
	
	local beach_ball=container:WaitForChild("beach_ball")
	local beach_ball_size=math.round(panel_X_size*0.1254)
	beach_ball.Size=UDim2.new(0,beach_ball_size,0,beach_ball_size)
	
	local exit=container:WaitForChild("exit")
	exit.Size = UDim2.new(0,math.round(_85_percent_slot_size*.85),0,math.round(_85_percent_slot_size*.85))
	--exit.Position = UDim2.new(1,-math.round(slot_offset/2),0,math.round(slot_offset/2))
	exit.Position = UDim2.new(1,-slot_offset,0,slot_offset)
	
	local buttons={container:WaitForChild("left"),container:WaitForChild("right")}
	for _,button in buttons do
		button.Size=UDim2.new(0,_85_percent_slot_size,0,_85_percent_slot_size)
	end

	local top=container:WaitForChild("top")
	local top_panel_size_X=math.round(panel_X_size/4)
	local top_panel_offset_Y=math.round(panel_Y_size*0.0613)+slot_offset
	top.Size=UDim2.new(0,top_panel_size_X,0,panel_size_Y)
	--top.Position=UDim2.new(.5,0,0,top_panel_offset_Y)

	local top_text=top:WaitForChild("Folder"):WaitForChild("TextLabel")
	top_text.TextSize=math.round(panel_size_Y*.65)
	sizeTextBGComponents(top_panel_size_X,panel_size_Y,{top:WaitForChild("1"),top:WaitForChild("2"),top:WaitForChild("3")})

	local cash=container:WaitForChild("cash")
	cash.Size=UDim2.new(0,inner_size_X,1,0)
	size_shop_slot_components(cash,panel_size_Y,slot_size)

	local gamepasses=container:WaitForChild("gamepasses")
	gamepasses.Size=UDim2.new(0,inner_size_X,1,0)
	--gamepasses:WaitForChild("list").Padding=UDim.new(0,slot_offset)
	size_shop_slot_components(gamepasses,panel_size_Y,slot_size)

end
]]

function interface.damageUI()
	local size = math.clamp(_G.screenSize.Y,0,512)
	for i,v in pairs(damageUI:GetChildren()) do 
		if v:IsA("ImageLabel") then
			v.Size = UDim2.new(0,size,0,size)
		end
	end
end

function interface.targetUI()
	local clamped = math.clamp(_math.nearest(slot_size/2),18,30)
	targetUI:WaitForChild("icon").Size = UDim2.new(0,clamped,0,clamped)
end

function interface.rebirthUI()
	local xMax = 384
	local yMax = 294
	local ySize = math.clamp(_4X_Slot_Size*1.25,0,yMax)
	local xSize = math.clamp(math.round(ySize*1.306122448979592),0,xMax)
	local bg = rebirthUI:WaitForChild("bg")
	bg.Size = UDim2.new(0,xSize,0,ySize)
	local exit = bg:WaitForChild("exit"):WaitForChild("exit")
	exit.Size = UDim2.new(0,math.round(_85_percent_slot_size*.85),0,math.round(_85_percent_slot_size*.85))
	--exit.Position = UDim2.new(1,-math.round(slot_offset/2),0,math.round(slot_offset/2))
	exit.Position = UDim2.new(1,-slot_offset,0,slot_offset)
	
	local inner = bg:WaitForChild("inner")
	local innerYSize = math.round(inner.AbsoluteSize.Y)
	local innerXSize = math.round(inner.AbsoluteSize.X)
	local purchaseInfo = inner:WaitForChild("purchaseInfo")

	local otherPriceYSize=playerGui:WaitForChild("cashUI"):WaitForChild("container"):WaitForChild("cash").Size.Y.Offset
	local TextSize=math.round(otherPriceYSize*.75)

	local textContainer = purchaseInfo:WaitForChild("1text")
	textContainer.Size = UDim2.new(1,0,0,TextSize*4)
	for _,textLabel in pairs(textContainer:GetChildren()) do
		if textLabel:IsA("TextLabel") then
			textLabel.TextSize = TextSize
		end
	end

	local uiListLayout = purchaseInfo:WaitForChild("UIListLayout")
	local listLayoutPadding = _math.nearest(slot_offset*4)
	uiListLayout.Padding = UDim.new(0,listLayoutPadding)

	local price = purchaseInfo:WaitForChild("4price")
	local priceX = math.round(innerXSize*.65)
	local priceY = otherPriceYSize--math.round(innerYSize*.102)
	price.Size = UDim2.new(0,priceX,0,priceY)
	sizeTextBGComponents(priceX,priceY,{price:WaitForChild("1"),price:WaitForChild("2"),price:WaitForChild("3")})

	--// cash container can't be bigger than cashUI container
	local cash = price:WaitForChild("text"):WaitForChild("cash")
	local stringLength = math.ceil(priceY*0.37)
	local cashText = cash:WaitForChild("text")
	local cashString = cashText.Text
	cashText.Size = UDim2.new(0,stringLength*#cashString,0,priceY)
	cashText.TextSize = TextSize
	cash:WaitForChild("icon").Size = UDim2.new(0,priceY,0,priceY)

	--// purchase container can't be bigger than the purchase buttons of the other ui
	--local otherPurchaseButtonSize=playerGui:WaitForChild("middleUI"):WaitForChild("container"):WaitForChild("lowerText"):WaitForChild("3buttonContainer").Size.Y.Offset
	local purchase = purchaseInfo:WaitForChild("5purchase")
	local purchaseY = math.round(slot_size*.9)--math.round(.2075 * innerYSize)
	local purchaseX = purchaseY * 3
	purchase.Size = UDim2.new(0,purchaseX,0,purchaseY)
	local purchaseTextSize = math.round(purchaseY/2)

	for _,image in pairs(purchase:GetChildren()) do 
		if image:IsA("ImageLabel") then
			image.Size = UDim2.new(0,purchaseY,0,purchaseY)
		end
	end

	purchase:WaitForChild("notificationFolder"):WaitForChild("notificationContainer").Size = UDim2.new(0,priceY,0,priceY)
	purchase:WaitForChild("text"):WaitForChild("button").TextSize = purchaseTextSize

	local spinner = inner:WaitForChild("spinner")
	local spinnerSize = math.round(0.3257 * innerXSize)
	spinner.Size = UDim2.new(0,spinnerSize,0,spinnerSize)

end

function interface.twitterUI()
	local xMax = 384
	local yMax = 294
	local ySize = math.clamp(_4X_Slot_Size*1.25,0,yMax)
	local xSize = math.clamp(math.round(ySize*1.306122448979592),0,xMax)

	local bg = twitterUI:WaitForChild("bg")
	bg.Size = UDim2.new(0,xSize,0,ySize)

	local exit = bg:WaitForChild("exit"):WaitForChild("exit")
	exit.Size = UDim2.new(0,math.round(_85_percent_slot_size*.85),0,math.round(_85_percent_slot_size*.85))
	--exit.Position = UDim2.new(1,-math.round(slot_offset/2),0,math.round(slot_offset/2))
	exit.Position = UDim2.new(1,-slot_offset,0,slot_offset)
	
	local inner = bg:WaitForChild("inner")
	local innerYSize = math.round(inner.AbsoluteSize.Y)
	local innerXSize = math.round(inner.AbsoluteSize.X)

	local dots = inner:WaitForChild("dots")
	local spinnerSize = math.round(0.3257 * innerXSize)
	dots.Size = UDim2.new(0,spinnerSize,0,spinnerSize)

	local folder = inner:WaitForChild("Folder")

	local otherPriceYSize=playerGui:WaitForChild("cashUI"):WaitForChild("container"):WaitForChild("cash").Size.Y.Offset
	local input=folder:WaitForChild("2input")
	local inputX = math.round(innerXSize*.65)
	local inputY = otherPriceYSize
	local textSize=math.round(inputY*.75)
	input:WaitForChild("text"):WaitForChild("TextBox")
	input.Size = UDim2.new(0,inputX,0,inputY)
	input:WaitForChild("text"):WaitForChild("TextBox").TextSize=textSize
	sizeTextBGComponents(inputX,inputY,{input:WaitForChild("1"),input:WaitForChild("2"),input:WaitForChild("3")})

	local text=folder:WaitForChild("1text")
	text.Size=UDim2.new(1,0,0,inputY*2)
	text.TextSize=textSize

	local purchase=folder:WaitForChild("3purchase")
	local purchaseY = math.round(slot_size*.9)
	local purchaseX = purchaseY * 3
	purchase.Size = UDim2.new(0,purchaseX,0,purchaseY)
	local buttonTextSize = math.round(purchaseY/2)
	purchase:WaitForChild("text"):WaitForChild("button").TextSize=buttonTextSize 

	for _,image in purchase:GetChildren() do 
		if image:IsA("ImageLabel") then
			image.Size=UDim2.new(0,purchaseY,0,purchaseY)
		end
	end

	local list = folder:WaitForChild("list")
	local total_contents_size_y=(inputY*3)+purchaseY
	local total_size_y=innerYSize
	local empty_space_y=total_size_y-total_contents_size_y
	local padding = math.round(empty_space_y/4)
	list.Padding=UDim.new(0,padding)

end

function interface.playUI()
	local container = playUI:WaitForChild("container")
	local play=container:WaitForChild("1play")

	local y = _85_percent_slot_size --math.round(slot_size*.9)
	local x = y*3
	container.Size = UDim2.new(0,x,0,y)
	--container:WaitForChild("UIListLayout").Padding=UDim.new(0,slot_offset)
	local buttonTextSize = math.round(y/2)
	--play:WaitForChild("text"):WaitForChild("button").TextSize=buttonTextSize 

	local creditContainer=playUI:WaitForChild("creditsContainer")
	for _,child in creditContainer:GetChildren() do 
		if child:IsA("TextLabel") then
			child.Size=UDim2.new(1,0,0,buttonTextSize)
		end
	end

	for _,child in container:GetChildren() do 
		if child:IsA("UIListLayout") then continue end
		for _,element in child:GetChildren() do 
			if element:IsA("ImageLabel") then
				element.Size=UDim2.new(0,y,0,y)
			end
			if element:IsA("Folder") then
				element:WaitForChild("button").TextSize=buttonTextSize
			end
		end
	end
	
end

function interface.trashUI()
	local size = math.clamp(double_slot_size,0,128)
	trashUI:WaitForChild("slot").Size = UDim2.new(0,size,0,size)
end

function interface.dragUI()
	dragUI:WaitForChild("example").Size = UDim2.new(0,slot_size,0,slot_size)
end

function interface.leftUI(bool)
	if (bool ~= nil) then
		leftUI.Enabled = bool
	end
	local container = leftUI:WaitForChild("container")
	local list = container:WaitForChild("list")
	container.Size = UDim2.new(0,slot_size,0,slot_size)
	container.Position = UDim2.new(0,slot_offset,.5,0)
	list.Padding = UDim.new(0,slot_offset)
	local inner=container:WaitForChild("inner")
	inner:WaitForChild("list").Padding=UDim.new(0,slot_offset)
	local outer=container:WaitForChild("outer")
	outer:WaitForChild("list").Padding=UDim.new(0,slot_offset)
end

function interface.Get_Length_From_Text(x,y,text,font,textSize)
	-- x is the max size
	-- use x to find the correct size (1 pixel larger than the size of the text)

	local label=textUI:WaitForChild("TextLabel"):Clone()
	game:GetService("Debris"):AddItem(label,1)
	--print("font=",label.Font)
	label.Size=UDim2.new(0,x,0,textSize or y)
	label.TextSize=textSize or y
	label.Font=font
	label.Text=text
	label.Parent=textUI
	if textSize then
		label.TextScaled=false
		label.TextScaled=true
	end
	--label.TextScaled=false
	--label.TextScaled=true
	-- toggle text scaled to get accurate size, idk why just works i think it recalculates the text size
	local i=0
	while true do 
		if label.TextFits then break end
		if i==10 then break end
		i+=1
		local sizeY=label.AbsoluteSize.Y
		label.Size=UDim2.new(0,x,0,sizeY+y) -- add another slide on
	end
	return label.TextBounds,label.TextFits
end

function interface.currencyUI(bool,container,yoffset,value)
	if (bool ~= nil) then
		cashUI.Enabled = bool
	end
	--print("updated cash")
	--local container = cashUI:WaitForChild("container")
	local currencyContainer = container:WaitForChild("cash")
	local leaderstats = player:WaitForChild("leaderstats")
	--local cash = leaderstats:WaitForChild("Cash")
	
	local info = currencyContainer:WaitForChild("info")
	
	local text = _math.giveNumberCommas(value)
	local offset = slot_offset
	local ySize = math.round(slot_size/1.75)
	local textSize = math.round(ySize*.75)
	_G.currencyTextSize=textSize
	local textBounds=interface.Get_Length_From_Text(1000,ySize,text,Enum.Font.TitilliumWeb,textSize)
	local textXLength = textBounds.X--math.ceil((#text*textSize)*.425)
	--print("x=",textXLength)
	local clampedXSize = math.clamp(textXLength,ySize,math.huge)
	local xSize = math.round(clampedXSize + (ySize*2))
	container.Size = UDim2.new(0,slot_size,0,slot_size)
	container.Position = UDim2.new(1,-offset,0.5,yoffset)
	currencyContainer.Size = UDim2.new(0,xSize,0,ySize)
	
	info:WaitForChild("iconContainer").Size = UDim2.new(0,ySize,0,ySize)
	info:WaitForChild("text").Size = UDim2.new(0,textXLength+slot_offset,0,ySize)
	info:WaitForChild("text").TextSize = textSize
	info:WaitForChild("text").Text = text
	info:WaitForChild("infoList").Padding = UDim.new(0,offset)
	
	local icon=cashUI:WaitForChild("icon")
	local biggerY=ySize+math.round(ySize*.5)
	icon.Size=UDim2.new(0,biggerY,0,biggerY)
	
	sizeTextBGComponents(xSize,ySize,{currencyContainer:WaitForChild("1"),currencyContainer:WaitForChild("2"),currencyContainer:WaitForChild("3")})
	
	local flyOffText = currencyContainer:WaitForChild("upperText"):WaitForChild("text")
	flyOffText.Size = UDim2.new(0,xSize,0,ySize)
	flyOffText.TextSize=textSize
	for i,v in flyOffText:GetChildren() do
		local y=v.Name=="top" and .5 or .6
		v.Position=UDim2.new(0,-slot_offset*3,y,0)
	end
	return flyOffText	
end

function interface.controlsUI()
	local text_size=_math.nearest(slot_size * 0.5)

	--// mobile
	local mobile=controlsUI:WaitForChild("mobile")
	mobile.Visible=_G.platform=="mobile"
	--mobile.Size=UDim2.new(0,math.round(slot_size*2.3714),0,math.round(slot_size*2.3714))
	mobile.Size=UDim2.new(0,math.round(slot_size*2),0,math.round(slot_size*2))
	mobile.Position=UDim2.new(1,-slot_offset*2,1,-slot_offset*2)

	local ability=mobile:WaitForChild("ability")
	ability.Position=UDim2.new(0,-slot_offset*0,0,-slot_offset*0)
	ability:WaitForChild("button").TextSize=text_size

	local sprint=mobile:WaitForChild("sprint")
	sprint.Position=UDim2.new(0,-slot_offset*3,.5,0)

	local roll=mobile:WaitForChild("roll")
	roll.Position=UDim2.new(0.5,0,0,-slot_offset*3)
	roll:WaitForChild("button").TextSize=text_size

	--// pc
	local pc=controlsUI:WaitForChild("pc")
	pc.Visible=_G.platform=="PC"

	pc.Size=UDim2.new(0,slot_size,0,slot_size)
	pc.Position=UDim2.new(1,-slot_offset,1,-slot_offset*4)
	pc:WaitForChild("UIListLayout").Padding=UDim.new(0,slot_offset*3)

	local pc_roll=pc:WaitForChild("roll")
	pc_roll:WaitForChild("button").TextSize=_math.nearest((slot_size*.75) * 0.4307692307692308)

	local pc_ability=pc:WaitForChild("ability")
	pc_ability:WaitForChild("button").TextSize=_math.nearest((slot_size*.75) * 0.4307692307692308)

	local pc_sprint=pc:WaitForChild("sprint")

	local pc_roll_label=pc_roll:WaitForChild("TextLabel")
	local pc_ability_label=pc_ability:WaitForChild("TextLabel")
	local pc_sprint_label=pc_sprint:WaitForChild("TextLabel")

	local triggerTextSize=math.round(pc_roll_label.AbsoluteSize.Y*.38)

	pc_sprint_label.TextSize=triggerTextSize
	pc_roll_label.TextSize=triggerTextSize
	pc_ability_label.TextSize=triggerTextSize

end

function interface.tutorialUI()
	local hand=tutorialUI:WaitForChild("hand")
	hand.Size=UDim2.new(0,math.round(slot_size*.5),0,math.round(slot_size*.5))
	hand:WaitForChild("slot").Size=UDim2.new(0,slot_size,0,slot_size)
	tutorialUI:WaitForChild("TextLabel").Size=UDim2.new(2,0,0,_G.currencyTextSize)
end

function interface.Size_Prompt_Box(container,x,y,slideAmount)
	local vars={}
	vars.slide_size=y/slideAmount
	vars.corner_size=math.round(vars.slide_size*.567)
	vars.left=container:WaitForChild("left")
	vars.right=container:WaitForChild("right")
	vars.middle=container:WaitForChild("middle")
	vars.bottom_left=container:WaitForChild("bottom_left")
	vars.bottom_middle=container:WaitForChild("bottom_middle")
	vars.bottom_right=container:WaitForChild("bottom_right")
	vars.top_left=container:WaitForChild("top_left")
	vars.top_middle=container:WaitForChild("top_middle")
	vars.top_right=container:WaitForChild("top_right")
	for _,element in {vars.left,vars.right} do 
		element:WaitForChild("Frame").Size=UDim2.new(0,vars.corner_size,0,vars.slide_size)
	end
	for _,element in vars.middle:GetChildren() do 
		if element:IsA("UIListLayout") then continue end
		element.Size=UDim2.new(1,0,0,vars.slide_size)
	end
	for _,element in {vars.bottom_middle,vars.top_middle} do 
		element.Size=UDim2.new(1,0,0,vars.corner_size)
	end
	for _,element in {vars.bottom_left,vars.bottom_right,vars.top_left,vars.top_right} do 
		element.Size=UDim2.new(0,vars.corner_size,0,vars.corner_size)
	end
end

function interface.Size_Objective_Content(content,x,y)
	local a=content:WaitForChild("a")
	local b=content:WaitForChild("b")
	local b_length=x-y
	a.Size=UDim2.new(0,y,0,y)
	b.Size=UDim2.new(0,b_length,0,y)
	for _,element in b:GetChildren() do 
		if element:IsA("UIListLayout") then continue end
		element.Size=UDim2.new(1,0,0,y/3)
		if element:IsA("TextLabel") then
			element.TextSize=y/3
		end
	end
	local _3=b:WaitForChild("3")
	local cash_icon_size=math.round(y*.5)
	_3:WaitForChild("list").Padding=UDim.new(0,slot_offset)
	_3:WaitForChild("icon").Size=UDim2.new(0,cash_icon_size,0,cash_icon_size)
	_3:WaitForChild("text").Size=UDim2.new(0,(b_length-cash_icon_size)-slot_offset,0,math.round(y*.385))
end

function interface.objectiveUI()
	local slide_size=math.round(slot_size/3)
	local y=slide_size*3
	local corner_size=math.round(slide_size*.567)
	local container=objectiveUI:WaitForChild("container")
	container.Size=UDim2.new(0,y,0,y)
	for _,child in container:GetChildren() do
		if not child:IsA("Frame") then continue end
		local inner=child:WaitForChild("inner")
		local content=inner:WaitForChild("content")
		local textLabel=content:WaitForChild("b"):WaitForChild("2")
		local textBounds,textFits=interface.Get_Length_From_Text(y*4,slide_size,textLabel.Text,textLabel.Font)
		local x=textBounds.X+slot_offset
		child.Size=UDim2.new(0,x+y,0,y)
		interface.Size_Objective_Content(content,x+y,y)
		interface.Size_Prompt_Box(inner,x+y,y,3)
	end
	local cash_container=cashUI:WaitForChild("container"):WaitForChild("cash")
	local cash_Y_Pos=cash_container.AbsolutePosition.Y
	container.Position=UDim2.new(1,(slot_offset+corner_size)*-1,0,(cash_Y_Pos+TopbarSize.Y)-y-corner_size-slot_offset)
	container:WaitForChild("list").Padding=UDim.new(0,(corner_size*2)+slot_offset)
end

function interface.dialogueUI()
	local hotbarList=hotbarUI:WaitForChild("container"):WaitForChild("list")
	local choiceContainer=dialogueUI:WaitForChild("choiceContainer")
	local dialogueContainer=dialogueUI:WaitForChild("dialogueContainer")

	local button_x=slot_size*4
	local button_y=math.round(slot_size*.6)
	local text_size=math.round(_G.currencyTextSize*.9)
	local box_x=hotbarList.AbsoluteContentSize.X
	local box_y=text_size

	if _G.dialogueBoxMovedIn==nil or _G.dialogueChoicesMovedIn==nil then
		repeat task.wait() until _G.dialogueBoxMovedIn~=nil or _G.dialogueChoicesMovedIn~=nil
	end

	dialogueContainer.Size=UDim2.new(0,box_x,0,box_y*4)
	if _G.dialogueBoxMovedIn==false then
		dialogueContainer.Position=UDim2.new(.5,0,5,0) -- move the box out of sight
	end

	local inner=dialogueContainer:WaitForChild("inner")

	local half_slot=math.round(slot_size/2)
	local name_text=inner:WaitForChild("nameText"):WaitForChild("text")
	name_text:WaitForChild("UIStroke").Thickness=text_size*.1
	name_text.Size=UDim2.new(1,0,0,half_slot)
	name_text.TextSize=text_size

	inner:WaitForChild("text"):WaitForChild("text").TextSize=text_size

	interface.Size_Prompt_Box(inner,box_x,box_y*4,4)
	local corner_size=inner:WaitForChild("top_left").AbsoluteSize.X
	name_text.Position=UDim2.new(0,0,0,-corner_size)

	local choice_container=dialogueUI:WaitForChild("choiceContainer")
	choice_container:WaitForChild("list").Padding=UDim.new(0,slot_offset)
	choice_container.Size=UDim2.new(0,button_x,0,button_y)

	for _,child in choiceContainer:GetChildren() do 
		if child:IsA("UIListLayout") then continue end
		if _G.dialogueChoicesMovedIn==false then
			child:WaitForChild("box").Position=UDim2.new(-10,0,0,0) -- place boxes outside of view
		end
		for _,element in child:WaitForChild("box"):GetChildren() do 
			if element:IsA("Folder") then
				element:WaitForChild("button").TextSize=text_size
			end
			if not element:IsA("ImageLabel") then continue end
			if element.Name=="2" then
				element.Size=UDim2.new(1,0,0,button_y)
			else 
				element.Size=UDim2.new(0,button_y,0,button_y)
			end
		end
	end
	choiceContainer.Position=UDim2.new(.5,0,1,-(slot_size*4))

	local next_size=math.round(slot_size*.75)
	local _next=dialogueContainer:WaitForChild("next")
	_next.Size=UDim2.new(0,next_size,0,next_size)
	_next.Position=UDim2.new(1,corner_size*2,1,corner_size)
end

function interface.size_notification(frame,text) -- to size a single notification
	frame=frame:WaitForChild("Frame")
	
	if not slot_size then
		repeat task.wait() until slot_size
	end
	
	local x=hotbarUI:WaitForChild("container"):WaitForChild("list").AbsoluteContentSize.X
	local y=math.round(slot_size/1.75)
	local textSize = math.round(y*.7)
	local textBounds,textFits=interface.Get_Length_From_Text(x,y,text,Enum.Font.TitilliumWeb,textSize)
	x=textBounds.X+2
	local container=notificationUI:WaitForChild("container")
	container.Size=UDim2.new(1,0,0,y)
	local edge=y
	edge=math.round(edge)
	local xSize=x+edge
	local ySize=y
	sizeTextBGComponents(xSize,ySize,{frame:WaitForChild("1"),frame:WaitForChild("2"),frame:WaitForChild("3")})
	
	frame.Parent.Size=UDim2.new(0,xSize,0,ySize)
	local text_label=frame:WaitForChild("info"):WaitForChild("text")
	text_label.Text=text
	text_label.TextSize=textSize
	text_label.Size=UDim2.new(0,x,1,0)
	
end

function interface.notificationUI()
	local y_offset=math.round(slot_offset/2)
	local y=math.round(slot_size/1.75)
	if TopbarSize.Y==0 then
		repeat task.wait() until GuiService:GetGuiInset().Y~=0
	end
	TopbarSize=GuiService:GetGuiInset()
	local yPos=TopbarSize.Y
	
	local container=notificationUI:WaitForChild("container")
	container.Size=UDim2.new(1,0,0,y)
	container.Position=UDim2.new(.5,0,0,yPos+(y_offset*2))
	-- size the container
	-- position the container
	local list=container:WaitForChild("list")
	for i,v in container:GetChildren() do
		if not v:IsA("Frame") then continue end
		local text=v:WaitForChild("Frame"):WaitForChild("info"):WaitForChild("text")
		if text.Text=="" then continue end -- don't size this if text isn't already in
		interface.size_notification(v,text.Text)
	end
	list.Padding=UDim.new(0,y_offset)
end

function interface.progressUI()
	local screen_x=_G.screenSize.X
	
	-- base it off the the slot size and Y so the height won't ever get too thick
	
	local x=math.clamp(math.round(screen_x*.333),0,377)
	--local y=math.round(x*0.05859375)
	local y=math.round(x*0.07421875)
	
	local title_x=math.round(x*.2)
	local title_y=math.round(y*0.6)
	
	local container=progressUI:WaitForChild("container")
	--container.Position=UDim2.new(.5,0,0,36+(slot_offset*2)+title_y)
	container.Size=UDim2.new(0,x,0,y)
	
	local title=container:WaitForChild("title")
	title.Size=UDim2.new(0,title_x,0,title_y)
	title.Position=UDim2.new(0,0,0,0)
	
	local sparkle=progressUI:WaitForChild("sparkle")
	local size=math.round(slot_size*.5)
	sparkle.Size=UDim2.new(0,size,0,size)
	
end

function interface.comboUI()
	local container=comboUI:WaitForChild("container")
	local offset=(slot_offset*3)+(slot_size*2)
	container.Position=UDim2.new(0,offset,.5,0)
	container.Size=UDim2.new(0,slot_size*3,0,slot_size) 
	local bottom_size_x=container:WaitForChild("bottom").Size.X.Scale
	local bottom_size_y=math.round((slot_size*3)*0.03515625)
	container:WaitForChild("bottom").Size=UDim2.new(bottom_size_x,0,0,bottom_size_y)
end

function interface.alertUI()
	local ui=playerGui:WaitForChild("AlertUI")
	local container=ui:WaitForChild("container")
	local dodge_folder=container:WaitForChild("dodge_folder")
	local dodge_text=container:WaitForChild("dodge_text")
end

function interface.tipUI()
	local bg=tipUI:WaitForChild("bg")
	local x=math.round(_G.screenSize.X*0.378)
	local y=math.round(x/2)
	bg.Size=UDim2.new(0,x,0,y)
	local bottom=bg:WaitForChild("world2"):WaitForChild("bottom")
	local button_x=math.round(x*0.117)
	local button_y=math.round(button_x/2)
	bottom:WaitForChild("2").Size=UDim2.new(0,button_x,0,button_y)
	bottom:WaitForChild("2"):WaitForChild("mobile").Size=UDim2.new(0,button_x,0,button_x)
	local exit=bg:WaitForChild("exit")
	local exit_size=math.round(x*0.0625)
	local exit_offset=math.round(exit_size/2)
	exit.Size=UDim2.new(0,exit_size,0,exit_size)
	exit.Position=UDim2.new(1,exit_offset,0,-exit_offset)
	-- 2; bottom = 0.1425 X, 2x Y
	
	local exit_bg=exit:WaitForChild("Background")
	local corners={exit:WaitForChild("UICorner"),
		exit_bg:WaitForChild("Color1"):WaitForChild("UICorner"),
		exit_bg:WaitForChild("Color2"):WaitForChild("UICorner"),
		exit_bg:WaitForChild("Shadow"):WaitForChild("UICorner")}
	for i,v in corners do 
		v.CornerRadius=UDim.new(0,math.round(exit_size*0.3125))
	end
	
end

function interface.worldChooseUI()
	-- 0.5539 X
	-- 0.6 Y of X
	local main_x=math.round(_G.screenSize.X*0.5539)
	local main_y=math.round(main_x*.6)
	local ui=playerGui:WaitForChild("worldChooseUI")
	local main=ui:WaitForChild("main")
	main.Size=UDim2.new(0,main_x,0,main_y)
	local exit_size=math.round(main_x*0.046)
	local exit=main:WaitForChild("Close")
	exit.Size=UDim2.new(0,exit_size,0,exit_size)
	local bottom=main:WaitForChild("Bottom")
	local _1Create=bottom:WaitForChild("1Create")
	--local _2Leave=bottom:WaitForChild("2Leave")
	local bottom_button_size_x=math.round(bottom.AbsoluteSize.X*0.235)
	local bottom_button_size_y=math.round(bottom.AbsoluteSize.Y*0.746)
	_1Create.Size=UDim2.new(0,bottom_button_size_x,0,bottom_button_size_y)
	--_2Leave.Size=UDim2.new(0,bottom_button_size_x,0,bottom_button_size_y)
	local worlds=main:WaitForChild("Worlds")
	local worlds_container=worlds:WaitForChild("WorldsContainer")
	local worlds_scroll_size=math.round(worlds_container.AbsoluteSize.X*0.0452)
	worlds_container.ScrollBarThickness=worlds_scroll_size
	local worlds_list=worlds_container:WaitForChild("UIListLayout")
	worlds_container.CanvasSize=UDim2.new(0,0,0,worlds_list.AbsoluteContentSize.Y)
	for _,world in worlds_container:GetChildren() do 
		if world:IsA("UIListLayout") then continue end
		world.Size=UDim2.new(.92,0,0,math.round(worlds_container.AbsoluteSize.Y*0.3243243243243243))
		local bg=world:WaitForChild("Background")
		local stat=bg:WaitForChild("Stats")
		local bottom2=stat:WaitForChild("bottom2")
		bottom2.Position=UDim2.new(0.5,0,1,math.round(0.09*bottom2.AbsoluteSize.Y))
		local top2=stat:WaitForChild("top2")
		top2.Position=UDim2.new(0.5,0,0,math.round(0.09*top2.AbsoluteSize.Y))
		local title=bg:WaitForChild("Title")
		local worldName2=title:WaitForChild("WorldName2")
		worldName2.Position=UDim2.new(0.5,0,0.5,math.round(0.055*worldName2.AbsoluteSize.Y))
	end
	local Queues=main:WaitForChild("Queues")
	local queue_scroll_size=math.round(Queues:WaitForChild("QueueContainer").AbsoluteSize.X*0.0222)
	Queues:WaitForChild("QueueContainer").ScrollBarThickness=queue_scroll_size
	-- 0.625 other users that aren't the owner of Owner size
	local function size_party_container(container)
		local parentY=container.Parent.Parent.AbsoluteSize.Y
		local containerY=math.round(parentY*0.3243243243243243)
		container.Size=UDim2.new(.98,0,0,containerY)
		local background=container:WaitForChild("Background")
		local button_size_x=math.round(background.AbsoluteSize.X*0.2877)
		local button_size_y=math.round(background.AbsoluteSize.Y*0.2777)
		local join=background:WaitForChild("Join")
		local leave=background:WaitForChild("Leave")
		local _settings=background:WaitForChild("Settings")
		local settings_size=math.round(background.AbsoluteSize.Y*0.278)
		_settings.Size=UDim2.new(0,settings_size,0,settings_size)
		join.Size=UDim2.new(0,button_size_x,0,button_size_y)
		leave.Size=UDim2.new(0,button_size_x,0,button_size_y)
		local timer=background:WaitForChild("Timer")
		local timer_y=math.round(background.AbsoluteSize.Y*0.2577)
		local timer_x=math.round(timer_y*4.8)
		timer.Size=UDim2.new(0,timer_x,0,timer_y)
		timer:WaitForChild("2").Size=UDim2.new(0,timer_y,0,timer_y)
		local users=background:WaitForChild("Users")
		for i,v in users:GetChildren() do 
			if v:IsA("UIListLayout") then continue end
			local normal=users.AbsoluteSize.Y
			local smaller=math.round(normal*0.625)
			v.Size=v.Name=="1" and UDim2.new(0,normal,0,normal) or UDim2.new(0,smaller,0,smaller)
		end
	end
	
	local Queues=main:WaitForChild("Queues")
	local QueueContainer=Queues:WaitForChild("QueueContainer")
	local clone=QueueContainer:WaitForChild("Folder"):WaitForChild("clone")
	local parties=QueueContainer:WaitForChild("Parties")
	local party_layout=parties:WaitForChild("UIListLayout")
	party_layout.Padding=UDim.new(0,slot_offset)
	for _,element in parties:GetChildren() do
		if element:IsA("UIListLayout") then continue end
		size_party_container(element)
	end
	size_party_container(clone)
end

function interface.partySettingsUI()
	local bg=playerGui:WaitForChild("partySettingsUI"):WaitForChild("bg")
	local folder=bg:WaitForChild("Folder")
	local close=bg:WaitForChild("Close")
	
	local main_x=math.round(_G.screenSize.X*0.5539)
	local size=math.round(main_x*0.34133)
	bg.Size=UDim2.new(0,size,0,size)
	
	local close_size=math.round(size*0.1171875)
	close.Size=UDim2.new(0,close_size,0,close_size)
	
	for _,element in folder:GetChildren() do 
		if element.Name=="2" or element.Name=="3" then
			local button_container=element:WaitForChild("button_container")
			local button_size_x=math.round(size*0.29296875)
			local button_size_y=math.round(button_size_x*0.4)
			button_container.Size=UDim2.new(0,button_size_x,0,button_size_y)
		end
		if element.Name=="4" then
			local button_size_x=math.round(size*0.46875)
			local button_size_y=math.round(button_size_x*0.25)
			element.Size=UDim2.new(0,button_size_x,0,button_size_y)
		end
	end
end

local inviteUI=playerGui:WaitForChild("inviteUI")

function interface.inviteUI()
	
end

function interface.updateUI(bool)
	_G.screenSize = workspace.CurrentCamera.ViewportSize
	panel_X_size = math.clamp(_math.nearest(_G.screenSize.X * 0.3764705882352941),256,512)
	half_X = _math.nearest(panel_X_size/2)
	panel_Y_size = _math.nearest(panel_X_size * 0.4140625)
	local holder_X = _math.nearest((panel_X_size*panel_X_offset)*2)
	local holder_Y = _math.nearest((panel_Y_size*panel_Y_offset)*2)
	panel_holder_size = UDim2.new(1,-holder_X,1,-holder_Y)
	slot_size = math.clamp(_math.nearest(panel_Y_size/3.212121212121212),33,56)
	_4X_Slot_Size = math.clamp(slot_size*4,0,256)
	_85_percent_slot_size = _math.nearest(slot_size*.85)
	half_slot_size = _math.nearest(slot_size/2)
	double_slot_size = _math.nearest(slot_size*2)
	robux_size = _math.nearest(half_slot_size*.75)
	slot_offset = _math.nearest(slot_size*.1)
	interface.hotbarUI(bool)
	interface.currencyUI(bool,cashUI:WaitForChild("container"),0,leaderstats:WaitForChild("Cash").Value)
	interface.currencyUI(bool,comicUI:WaitForChild("container"),math.round(slot_size/1.75)+slot_offset,leaderstats:WaitForChild("Comic pages").Value) -- comic ui
	interface.middleUI(bool)
	interface.leftUI(bool)
	interface.skinsUI(bool)
	interface.controlsUI()
	interface.dragUI()
	interface.damageUI()
	interface.trashUI()
	interface.playUI()
	interface.targetUI()
	interface.rebirthUI()
	interface.shopUI()
	interface.twitterUI()
	interface.tutorialUI()
	interface.dialogueUI()
	interface.notificationUI()
	interface.progressUI()
	interface.comboUI()
	interface.tipUI()
	interface.worldChooseUI()
	interface.partySettingsUI()
	interface.inviteUI()
	--interface.objectiveUI()
	_G.slot_offset=slot_offset
	_G.slot_size=slot_size
end

function interface.toggleUI(s)
	--print("toggle ui")
	if (s == "cutsceneStart") then
		hotbarUI.Enabled = false
		middleUI.Enabled = false
		leftUI.Enabled = false
		trashUI.Enabled = false
		cashUI.Enabled = false
		comicUI.Enabled = false
		rebirthUI.Enabled = false
		playUI.Enabled = true
		controlsUI.Enabled=false
		shopUI.Enabled=false
		twitterUI.Enabled=false
		progressUI.Enabled=false
		comboUI.Enabled=false
		--tipUI.Enabled=false
	elseif (s == "cutsceneEnd") then
		--[[
		if (isClimbing.Value) or (isSwimming.Value) then
			hotbarUI.Enabled = false
		else
			hotbarUI.Enabled = true
		end]]
		comicUI.Enabled = true
		controlsUI.Enabled=true
		hotbarUI.Enabled = true
		middleUI.Enabled = false
		leftUI.Enabled = true
		cashUI.Enabled = true
		trashUI.Enabled = false
		playUI.Enabled = false
		rebirthUI.Enabled = false
		shopUI.Enabled=false
		twitterUI.Enabled=false
		progressUI.Enabled=true
		comboUI.Enabled=true
		--tipUI.Enabled=true
		_G.tip=true
	end
end

return interface

