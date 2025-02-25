local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local objectives=leaderstats:WaitForChild("objectives")
local amount=objectives:WaitForChild("amount")
amount:SetAttribute("Last",amount.Value)
local current=objectives:WaitForChild("current")

local playerGui=player:WaitForChild("PlayerGui")
local objectiveUI=playerGui:WaitForChild("objectiveUI")
local container=objectiveUI:WaitForChild("container")

local rs=game:GetService("ReplicatedStorage")
local items=require(rs:WaitForChild("items"))
local interface=require(rs:WaitForChild("interface"))
local _math=require(rs:WaitForChild("math"))

local villains=workspace:WaitForChild("Villains")

local ts=game:GetService("TweenService")
local tweenInfo=TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)

local function AddBox(offset,icon,text,reward)
	local clone=container:WaitForChild("clone"):Clone()
	clone.Name="2objective"
	clone.inner.Position=UDim2.new(2,0,0,0) -- place it outside of the screen
	clone.Visible=true
	clone.Parent=container
	return clone
end

local function RemoveBox(box)
	box:Destroy()
end

local function UpdateBox(box,appear)
	--print("update")
	if appear then
		box.inner.Position=UDim2.new(2,0,0,0) -- place it outside of the screen
	end
	local content=box.inner.content
	local CurrentObjective=current.Value
	if CurrentObjective>#items.objectives then return end
	local objective=items.objectives[CurrentObjective]
	local CurrentAmount=amount.Value
	local ObjectiveAmount=objective.amount
	local AmountText=ObjectiveAmount~=0 and CurrentAmount.."/"..ObjectiveAmount or ""
	local Description=objective.title..AmountText
	for _,image in content.a:GetChildren() do 
		local offset=objective.offset
		local size=objective.imageSize
		if CurrentObjective==#items.objectives then
			--print("made it here")
			local boss=villains:FindFirstChildOfClass("Model")
			if boss then
				--print("boss exists")
				local name=boss:WaitForChild("BossName").Value
				--print("name of boss=",name)
				offset=items.boss_image_offsets[name].offset
				size=items.boss_image_offsets[name].size
			end
		end
		image.ImageRectOffset=offset
		image.ImageRectSize=size
		image.Image=objective.image
	end
	content.b["2"].Text=Description--this includes the amount
	content.b["3"].Visible=objective.reward~=0
	local reward = objective.reward
	local rebirth = math.round((leaderstats:WaitForChild("Rebirths").Value/10) * reward)
	reward=(reward+rebirth)
	content.b["3"].text.Text=_math.giveNumberCommas(reward)
	interface.objectiveUI() -- update the size and positions of all boxes
	if appear then
		ts:Create(box.inner,tweenInfo,{Position=UDim2.new(0,0,0,0)}):Play()
		box.radio:Play()
	end
end

leaderstats:WaitForChild("Rebirths"):GetPropertyChangedSignal("Value"):Connect(function()
	local box=container:FindFirstChild("2objective")
	if not box then
		box=AddBox()
	end
	UpdateBox(box)
end)

local progressUI=playerGui:WaitForChild("progressUI")
local running=progressUI:WaitForChild("Running")

local function ObjectiveChanged()
	local box=container:FindFirstChild("2objective")
	if not box then
		box=AddBox()
	end
	-- wait till progress bar is full
	if running.Value then
		running:GetPropertyChangedSignal("Value"):Wait() -- wait for it to finish running, then load the objective
	end
	UpdateBox(box,true)
end

local function AmountChanged()
	--print("lastAmount=",last)
	-- change the objective box text whenever this happens
	local box=container:FindFirstChild("2objective")
	if not box then
		box=AddBox()
	end
	if running.Value then
		running:GetPropertyChangedSignal("Value"):Wait() -- wait for it to finish running, then load the objective
	end
	UpdateBox(box)
end

if not _G.slot_size then
	repeat task.wait(1/10) until _G.slot_size
end

UpdateBox(AddBox(),true) -- at first just create a box then update it's size/position, don't make visible yet

current:GetPropertyChangedSignal("Value"):Connect(ObjectiveChanged)
amount:GetPropertyChangedSignal("Value"):Connect(AmountChanged)
villains.ChildAdded:Connect(AmountChanged)