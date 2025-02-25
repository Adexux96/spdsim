local rs=game:GetService("ReplicatedStorage")
local dialogueEvent=rs:WaitForChild("DialogueEvent")

local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local rebirths=leaderstats:WaitForChild("Rebirths")
local objectives=leaderstats:WaitForChild("objectives")
local completed=objectives:WaitForChild("completed")
local currentObjective=objectives:WaitForChild("current")
local camera=workspace.CurrentCamera

local OTS_Camera=require(rs:WaitForChild("OTS_Camera"))
local interface=require(rs:WaitForChild("interface"))
local controls=require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local items=require(rs:WaitForChild("items"))

local playerGui=player:WaitForChild("PlayerGui")
local hotbarUI=playerGui:WaitForChild("hotbarUI")
local selected=hotbarUI:WaitForChild("container"):WaitForChild("Selected")
local hotbarList=hotbarUI:WaitForChild("container"):WaitForChild("list")

local dialogueUI=playerGui:WaitForChild("dialogueUI")
local trimUI=playerGui:WaitForChild("trimUI")

local typing=dialogueUI:WaitForChild("typing")
local button3=rs:WaitForChild("ui_sound"):WaitForChild("button3")

-- change the ui to death camera
-- turn OTS off if it's on

-- turn death cam off when you stop dialogue
-- turn OTS back on if it needs to be on, similar to how ragdoll does it

local feedback={
	[1]="You can unlock and upgrade abilities in the abilities page with your cash! Drag abilities into your hotbar to use them!",
	[2]=function() -- skip
		local new=currentObjective.Value==16 and 2 or currentObjective.Value+2
		dialogueEvent:FireServer(new)
	end,
	[3]=function() -- replay last
		local new=currentObjective.Value<=2 and 16 or currentObjective.Value-2
		dialogueEvent:FireServer(new)
	end,
	[4]=nil
}

_G.dialogueEngaged=false
_G.dialogueBoxMovedIn=false
_G.dialogueChoicesMovedIn=false

local choiceContainer=dialogueUI:WaitForChild("choiceContainer")
local dialogueContainer=dialogueUI:WaitForChild("dialogueContainer")
local dialogueText=dialogueContainer:WaitForChild("inner"):WaitForChild("text"):WaitForChild("text")

local _next=dialogueContainer:WaitForChild("next")

local ts=game:GetService("TweenService")
local tweenInfo1=TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0)
local tweenInfo2=TweenInfo.new(.5,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0)

local isTyping=false
local function gradualText(text)
	_next:SetAttribute("Activated",false)
	typing:Play()
	local duration=#text*(1/40)
	local start=tick()
	_next.Visible=true
	while true do
		isTyping=true
		local elapsed=tick()-start
		local p=math.clamp(elapsed/duration,0,1)
		dialogueText.Text=string.sub(text,1,math.round(p*#text))
		if p==1 or _next:GetAttribute("Activated") then break end
		task.wait()
	end
	isTyping=false
	dialogueText.Text=text
	typing:Stop()
	--[[
	for i=1,#text do 
		dialogueText.Text=string.sub(text,1,i)
		task.wait()
	end
	]]
end

local function choicesMoveIn()
	_G.dialogueChoicesMovedIn=true
	interface.dialogueUI()
	for i=1,#choiceContainer:GetChildren() do 
		local element=choiceContainer:FindFirstChild(i)
		if element then
			local box=element:WaitForChild("box")
			ts:Create(box,tweenInfo2,{Position=UDim2.new(0,0,0,0)}):Play()
			task.wait(.1)
		end
	end
	task.wait(.2)
end

local function choicesMoveOut(ignore)
	_G.dialogueChoicesMovedIn=false
	for i=1,#choiceContainer:GetChildren() do 
		local element=choiceContainer:FindFirstChild(i)
		if element and element~=ignore then
			local box=element:WaitForChild("box")
			ts:Create(box,tweenInfo2,{Position=UDim2.new(-10,0,0,0)}):Play()
			task.wait(.1)
		end
	end
	task.wait(.25) -- so you can see your choice longer
	local box=ignore:WaitForChild("box")
	local last=ts:Create(box,tweenInfo1,{Position=UDim2.new(-10,0,0,0)})
	last:Play()
	last.Completed:Wait()
end

local function boxMoveIn()
	_G.dialogueBoxMovedIn=true
	_next.Visible=false
	interface.dialogueUI()
	local tween=ts:Create(dialogueContainer,tweenInfo2,{Position=UDim2.new(.5,0,1,-(_G.slot_size*2))})
	tween:Play()
	tween.Completed:Wait()
end

local function boxMoveOut()
	_G.dialogueBoxMovedIn=false
	_next.Visible=false
	local tween=ts:Create(dialogueContainer,tweenInfo2,{Position=UDim2.new(.5,0,5,0)})
	tween:Play()
	tween.Completed:Wait()
end

-- when you click a button, the buttons move out, then the action is carried out:
	-- if no feedback exists, the dialogue will stop
	-- if feedback exists, the dialogue will load that text into the box, update sizes, then move the box into the screen	
-- when the dialogue is done, it goes away and buttons come back

_G.toggleTrim=function(bool)
	local size=bool and _G.slot_size or 0
	ts:Create(trimUI:WaitForChild("top"),tweenInfo1,{Size=UDim2.new(2,0,0,size)}):Play()
	ts:Create(trimUI:WaitForChild("bottom"),tweenInfo1,{Size=UDim2.new(2,0,0,size)}):Play()
end

local function stop()
	local cop=workspace:FindFirstChild("Cop")
	if not cop or not cop.PrimaryPart then return end
	local proximityPrompt=cop.PrimaryPart:WaitForChild("ProximityPrompt")
	_G.dialogueEngaged=false
	OTS_Camera.Reboot()
	_G.deathScreen(false)
	controls:Enable()
	local character=player.Character 
	if character and character.PrimaryPart then
		local tutorialBeam=character.PrimaryPart:FindFirstChild("TutorialBeam")
		if tutorialBeam then
			tutorialBeam.Enabled=true
		end
	end
	proximityPrompt.Enabled=true
	_G.toggleTrim(false)
	camera.CameraType=Enum.CameraType.Custom
	dialogueUI.Enabled=false
end

local function start(cframe)
	dialogueUI.Enabled=true
	local cop=workspace:FindFirstChild("Cop")
	if not cop or not cop.PrimaryPart then return end
	local proximityPrompt=cop.PrimaryPart:WaitForChild("ProximityPrompt")
	if _G.dialogueEngaged==true then return end -- don't do double
	proximityPrompt.Enabled=false
	local slot=hotbarUI:WaitForChild("container"):FindFirstChild(tostring(selected.Value))
	_G.hotbarAbilityActivated(slot)
	_G.dialogueEngaged=true
	OTS_Camera.Deactivate()
	_G.deathScreen(true)
	controls:Disable()
	local character=player.Character 
	if character and character.PrimaryPart then
		local tutorialBeam=character.PrimaryPart:FindFirstChild("TutorialBeam")
		if tutorialBeam then
			tutorialBeam.Enabled=false
		end
	end
	_G.toggleTrim(true)
	camera.CameraType=Enum.CameraType.Scriptable
	ts:Create(camera,tweenInfo1,{CFrame=cframe}):Play()
end

for _,element in choiceContainer:GetChildren() do 
	if not element:IsA("Frame") then continue end
	local button=element:WaitForChild("box"):WaitForChild("text"):WaitForChild("button")
	button.Activated:Connect(function()
		button3:Play() -- play sound
		choicesMoveOut(element)
		local _feedback=feedback[tonumber(element.Name)]
		if not _feedback then
			stop()
		else 
			if type(_feedback)=="function" then
				stop()
				_feedback()
				return
			end
			dialogueText.Text=""
			boxMoveIn()
			gradualText(_feedback)
		end
	end)
end

local effects=require(rs:WaitForChild("Effects"))

_next:WaitForChild("bg"):WaitForChild("button").Activated:Connect(function()
	button3:Play()
	if isTyping then -- stop the typing
		_next:SetAttribute("Activated",true)
		return 
	end
	_next.Visible=false
	task.wait(.2)
	boxMoveOut()
	if _next:WaitForChild("EndConvo").Value then
		stop()
		_next:WaitForChild("EndConvo").Value=false
		return
	end
	choicesMoveIn()
end)

dialogueEvent.OnClientEvent:Connect(function(cframe)
	--[[
	local part=Instance.new("Part")
	part.FrontSurface=Enum.SurfaceType.Hinge
	part.Anchored=true
	part.CanCollide=false
	part.Transparency=.5
	part.BrickColor=BrickColor.Blue()
	part.Size=Vector3.new(1,1,1)
	part.CFrame=cframe
	part.Parent=workspace
	]]
	
	local canSkip=completed.Value
	choiceContainer:WaitForChild("2").Visible=canSkip
	
	local canReplayLast=true
	if currentObjective.Value<=2 and completed.Value==false then
		canReplayLast=false
	end
	choiceContainer:WaitForChild("3").Visible=canReplayLast
	
	interface.dialogueUI()
	start(cframe)
	local objective=items.objectives[currentObjective.Value]
	if objective then -- auto go to dialogue box
		if objective.name=="police" then
			_next:WaitForChild("EndConvo").Value=true
			local text=objective.dialogue
			dialogueText.Text=""
			boxMoveIn()
			gradualText(text)
		else
			choicesMoveIn()
		end
	else
		if rebirths.Value<10 then
			-- do the rebirth suggestion here if you're done with all objectives
			local text="Since you've completed all of the objectives, you might want to purchase a rebirth! This will help you progress through the game faster by earning cash."
			dialogueText.Text=""
			boxMoveIn()
			gradualText(text)
			--choicesMoveIn()
		else 
			choicesMoveIn()
		end
	end
	
end)

local HttpService = game:GetService("HttpService")
local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

--[[
-- Construct invite options with launch data
local inviteOptions = Instance.new("ExperienceInviteOptions")
inviteOptions.PromptMessage = "yes"

-- Function to check whether the player can send an invite
local function canSendGameInvite(sendingPlayer)
	local success, canSend = pcall(function()
		return SocialService:CanSendGameInviteAsync(sendingPlayer)
	end)
	return success and canSend
end

local canInvite = canSendGameInvite(player)
if canInvite then
	local success, errorMessage = pcall(function()
		SocialService:PromptGameInvite(player, inviteOptions)
	end)
	if not success then 
		print(errorMessage)
	end
else 
	print("can't invite players")
end
]]
