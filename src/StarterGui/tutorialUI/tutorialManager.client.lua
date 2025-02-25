--game:GetService(“GuiService”):GetGuiInset()
--userInputService.MouseIconEnabled = false

--!nocheck

local uis=game:GetService("UserInputService")
local rs=game:GetService("ReplicatedStorage")

local drag_remote=rs:WaitForChild("DragEvent")

local tutorialUI=script.Parent
local bg=tutorialUI:WaitForChild("bg")
local hand=tutorialUI:WaitForChild("hand")
local text=tutorialUI:WaitForChild("TextLabel")

local player=game.Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local leaderstats=player:WaitForChild("leaderstats")
local tutorial=leaderstats:WaitForChild("tutorial")
local drag=tutorial:WaitForChild("Drag")

local hotbarUI=playerGui:WaitForChild("hotbarUI")
local hotbarUI_container=hotbarUI:WaitForChild("container")
local middleUI=playerGui:WaitForChild("middleUI")
local middleUI_container=middleUI:WaitForChild("container")
local tutorial_container=middleUI_container:WaitForChild("tutorial")
local tutorial_bg=tutorial_container:WaitForChild("bg")
local tutorial_button=tutorial_container:WaitForChild("button")

local trashUI=playerGui:WaitForChild("trashUI")
local trashUI_slot=trashUI:WaitForChild("slot")

local drag_sound=rs:WaitForChild("ui_sound"):WaitForChild("drag")

local ts=game:GetService("TweenService")
local tweenInfo1=TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
local tweenInfo2=TweenInfo.new(.01,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,false,.49)

local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
_G.tutorial_playing=false

local texts={
	[1]="Add abilities to your hotbar",
	[2]="Move abilities in your hotbar",
	[3]="Remove abilities from your hotbar"
}

local function Get_Mid_Point(middle:Frame, hotbar:Frame, top_bar_size:number)
	local x=middle.AbsolutePosition.X+(middle.AbsoluteSize.X/2)
	local upper=middle.AbsolutePosition.Y+top_bar_size+middle.AbsoluteSize.Y
	local lower=hotbar.AbsolutePosition.Y+top_bar_size
	local y=(upper+lower)/2
	x-=(hand.AbsoluteSize.X/2)
	y-=(hand.AbsoluteSize.Y/2)
	--hand.Position=UDim2.new(0,hand.AbsolutePosition.X,0,hand.AbsolutePosition.Y)
	return UDim2.new(0,x,0,y)
end

local function Stop_Tutorial()
	local ignore={
		["hand"]=true,
		["bg"]=true,
		["TextLabel"]=true,
		["tutorialManager"]=true
	}
	for _,child in tutorialUI:GetChildren() do 
		if not ignore[child.Name] then
			child:Destroy()
		end
	end
	bg.Visible=false
	hand.Position=UDim2.new(1,0,1,0)
	hotbarUI_container.Visible=true
	middleUI_container.Visible=true
	--controls:Enable()
	_G.tutorial_playing=false
	drag_remote:FireServer()
end

local function Move_Tween(pos)
	local move=ts:Create(
		hand,
		TweenInfo.new(
			.5,
			Enum.EasingStyle.Cubic,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		),
		{Position=pos}
	)
	return move
end

local function Transparency_Tween(text:TextLabel, n:number)
	local tween=ts:Create(
		text,
		TweenInfo.new(
			.25,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		),
		{TextTransparency=n}
	)
	return tween
end

local function Fade_Next_Text(text,s)
	local transparency=Transparency_Tween(text, 1)
	transparency:Play()
	transparency.Completed:Wait()
	text.Text=s
	-- make the text visible again
	transparency=Transparency_Tween(text, 0)
	transparency:Play()
	transparency.Completed:Wait()
end

local function Fade_In_Text(text,s)
	local transparency=Transparency_Tween(text, 0)
	text.Text=s
	transparency:Play()
	transparency.Completed:Wait()	
end

local function Move_Pointer(pos)
	local move=Move_Tween(pos)
	move:Play()
	move.Completed:Wait()
end

local function Add_Slot(parent) -- when an ability was added to the slot
	local slot=parent:WaitForChild("slot")
	slot.ImageTransparency=0
	slot:WaitForChild("icon").Visible=true
	slot:WaitForChild("icon").ImageRectOffset=Vector2.new(0,0)
end

local function Remove_Slot(parent) -- when an ability was completely removed from the slot
	local slot=parent:WaitForChild("slot")
	slot:WaitForChild("icon").Visible=false
	slot.ImageTransparency=.5
end

local function Hover_Slot(parent) -- when a slot was dragged from, leaving it temporarily icon-less.
	local slot=parent.Name=="slot" and parent or parent:WaitForChild("slot")
	slot:WaitForChild("icon").Visible=false
end

local function Toggle_Hand_Slot(bool) -- show the slot behind the hand icon!
	hand:WaitForChild("slot").Visible=bool
end

local function Toggle_Hand(bool)
	hand:WaitForChild("point").ImageRectOffset=Vector2.new(128,0)--bool and Vector2.new(128,0) or Vector2.new(0,0)
end

local function Get_Size_Difference(slot)
	local x=math.abs(hand.AbsoluteSize.X-slot.AbsoluteSize.X)
	local y=math.abs(hand.AbsoluteSize.Y-slot.AbsoluteSize.Y)
	return x,y
end

local function Get_New_Position(slot,size_difference_x,size_difference_y,top_bar_size)
	local x=math.round(slot.AbsolutePosition.X)+(size_difference_x/2)
	local y=math.round(slot.AbsolutePosition.Y+top_bar_size)+(size_difference_y/2)
	return UDim2.new(0,x,0,y,0)
end

local wait_time=.05
local function Start_Tutorial(text:TextLabel, middle:Frame, hotbar:Frame, trash:ImageLabel, top_bar_size:number)
	
	local mid_point=Get_Mid_Point(middle, hotbar, top_bar_size)
	Move_Pointer(mid_point)
	
	Fade_In_Text(text,texts[1])
	
	local _1_slot=middle.holder.Melee["1"].slot
	local size_difference_x, size_difference_y=Get_Size_Difference(_1_slot)
	
	local ability_pos=Get_New_Position(_1_slot,size_difference_x,size_difference_y,top_bar_size)
	Move_Pointer(ability_pos)
	-- reached the ability slot, "drag the slot"
	Toggle_Hand(true)
	task.wait(wait_time)
	
	local slot_1=hotbar["1"]
	local slot_1_pos=Get_New_Position(slot_1,size_difference_x,size_difference_y,top_bar_size)
	
	--task.wait(.1)
	drag_sound:Play()
	Hover_Slot(_1_slot)
	Toggle_Hand_Slot(true)
	Move_Pointer(slot_1_pos)
	task.wait(wait_time)
	
	-- reached the hotbar slot, "release the slot"
	drag_sound:Play()
	Toggle_Hand(false)
	Toggle_Hand_Slot(false)
	_1_slot.icon.Visible=true -- unique case, put the ability icon back
	Add_Slot(slot_1)
	
	Move_Pointer(mid_point)
	-- reached mid point again
	
	Fade_Next_Text(text,texts[2])
	
	Move_Pointer(slot_1_pos)
	-- reached slot 1 again
	Toggle_Hand(true)
	task.wait(wait_time)
	
	local slot_3=hotbar["3"]
	local slot_3_pos=Get_New_Position(slot_3,size_difference_x,size_difference_y,top_bar_size)
	
	drag_sound:Play()
	Hover_Slot(slot_1)
	Toggle_Hand_Slot(true)
	Move_Pointer(slot_3_pos)
	task.wait(wait_time)
	-- made it to slot 3, from slot 1
	
	drag_sound:Play() -- drag sound plays when you finish dragging to a new slot
	Remove_Slot(slot_1)
	Toggle_Hand_Slot(false)
	Toggle_Hand(false)
	Add_Slot(slot_3)
	
	Move_Pointer(mid_point)
	-- reached the mid point again
	
	Fade_Next_Text(text,texts[3])
	
	Move_Pointer(slot_3_pos)
	-- reached slot 3 again, grab this!
	Toggle_Hand(true)
	task.wait(wait_time)
	Toggle_Hand_Slot(true)
	Hover_Slot(slot_3)
	
	local x,y=Get_Size_Difference(trash)
	local trash_pos=Get_New_Position(trash,x,y,top_bar_size)
	trash.Visible=true
	drag_sound:Play()
	Move_Pointer(trash_pos)
	
	Toggle_Hand(false)
	Toggle_Hand_Slot(false)
	Remove_Slot(slot_3)
	trash.Visible=false
	task.wait(wait_time)
	
	Move_Pointer(mid_point)
	
	Stop_Tutorial()
end

local function Prepare_Tutorial()
	if _G.tutorial_playing then return end
	_G.tutorial_playing=true
	
	--if not _G.deathScreen then repeat task.wait() until _G.deathScreen end
	--_G.deathScreen(true)
	
	--controls:Disable()
	
	middleUI_container.Visible=false -- don't show the real middleUI!
	hotbarUI_container.Visible=false
	
	local middleUI_clone=middleUI_container:Clone()
	for _,child in middleUI_clone:GetChildren() do 
		if child.Name~="holder" and child.Name~="tutorial" and child.Name~="bg" then
			child:Destroy()
		end
		if child.Name=="holder" then
			for _,_child in child:GetChildren() do 
				if _child.Name~="Melee" then 
					_child:Destroy()
				end
			end
			child:WaitForChild("Melee").Visible=true
			for _,descendant in child:WaitForChild("Melee"):GetChildren() do  -- sort the melee
				if not descendant:IsA("Frame") then descendant:Destroy() continue end
				local slot=descendant:WaitForChild("slot")
				slot.ImageRectOffset=Vector2.new(0,0)
				local notification=slot:FindFirstChild("notificationContainer")
				if notification then notification:Destroy() end
				slot:WaitForChild("icon").ImageTransparency=descendant.Name=="1" and 0 or .5
			end
		end
	end
	middleUI_clone.Parent=tutorialUI 
	middleUI_clone.Visible=true
	
	local hotbarUI_clone=hotbarUI_container:Clone()
	for _,slot in hotbarUI_clone:GetChildren() do 
		if not slot:IsA("Frame") then continue end
		local _slot=slot:WaitForChild("slot")
		local icon=_slot:WaitForChild("icon")
		icon.Visible=false
		_slot.ImageTransparency=.5
		_slot.ImageRectOffset=Vector2.new(0,0)
		local changeToPunch=slot.Name=="1" or slot.Name=="5"
		icon.ImageRectOffset=changeToPunch and Vector2.new(0,0) or icon.ImageRectOffset
	end
	hotbarUI_clone.Parent=tutorialUI
	hotbarUI_clone.Visible=true
	
	local trashUI_clone=trashUI_slot:Clone()
	trashUI_clone.Visible=false
	trashUI_clone.Parent=tutorialUI
	
	bg.Visible=true
	
	local text=text:Clone()
	text.Visible=true
	text.TextTransparency=1
	text.Parent=middleUI_clone
	
	local top_bar_size=game:GetService("GuiService"):GetGuiInset().Y
	
	Start_Tutorial(text, middleUI_clone, hotbarUI_clone, trashUI_clone, top_bar_size)
end

--tutorial_button.Activated:Connect(Prepare_Tutorial)

local sizeTween=nil
local tweenOut=nil
local drag_value=leaderstats:WaitForChild("tutorial"):WaitForChild("Drag")--drag_value=false
local function middleUI_toggle()
	--[[
	if sizeTween then
		sizeTween=nil
	end
	if tweenOut then
		tweenOut:Cancel()
	end
	]]
	if middleUI.Enabled and not drag_value.Value then
		--drag_value=true
		tutorial_container.Position=UDim2.new(1,0,.5,0)
		tweenOut=ts:Create(tutorial_container,tweenInfo1,{Position=UDim2.new(1.25,0,.5,0)})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		if middleUI.Enabled then
			tutorial_bg.Size=UDim2.new(1,0,1,0)
			sizeTween=true
		end
		Prepare_Tutorial()
	end
end

middleUI:GetPropertyChangedSignal("Enabled"):Connect(middleUI_toggle)

--[[
local iteration=0
while true do
	if drag.Value then
		tutorial_bg.Size=UDim2.new(1,0,1,0)
		break
	end
	if sizeTween then
		task.wait(.5)
		local size=iteration%2==0 and 1.2 or 1
		tutorial_bg.Size=UDim2.new(size,0,size,0)
		iteration+=1
	else
		iteration=0
	end
	task.wait(1/10)
end
]]