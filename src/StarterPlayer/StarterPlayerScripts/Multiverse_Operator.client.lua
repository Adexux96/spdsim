local Multiverse_Part=workspace:WaitForChild("MultiverseTouchPart")

local player=game.Players.LocalPlayer 
local playerGui=player:WaitForChild("PlayerGui")
local worldChooseUI=playerGui:WaitForChild("worldChooseUI")
local controls=require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()

local timers={} -- add newly created party timers here!
local timerValue=Instance.new("StringValue")

local locked_worlds={
	["Toon"]=false,
	["Noir"]=true,
	["2099"]=true
}

local canTouch=true
local lastOpen=tick()-3
local function touched(part)
	if not canTouch then return end
	if worldChooseUI.Enabled then return end
	if not part:IsDescendantOf(player.Character) then return end
	if tick()-lastOpen<5 then return end
	worldChooseUI.Enabled=true
	controls:Disable()
	_G.deathScreen(true)
end

Multiverse_Part.Touched:Connect(touched)

local rs=game:GetService("ReplicatedStorage")
local ts=game:GetService("TweenService")
local MultiversePartyEvent=rs:WaitForChild("MultiversePartyEvent")

local main=worldChooseUI:WaitForChild("main")
local bottom=main:WaitForChild("Bottom")
local create=bottom:WaitForChild("1Create")
local QueueContainer=main:WaitForChild("Queues"):WaitForChild("QueueContainer")
local clone=QueueContainer:WaitForChild("Folder"):WaitForChild("clone")
local parties=QueueContainer:WaitForChild("Parties")
local Multiverse_Parties=rs:WaitForChild("Multiverse_Parties")

local current={name="Toon",world="1"}
local worlds_container=main:WaitForChild("Worlds"):WaitForChild("WorldsContainer")

local function clear_parties()
	for _,party in parties:GetChildren() do 
		if party:IsA("UIListLayout") then continue end
		party:Destroy()
	end
end

local function clear_party(party_container)
	local users=party_container:WaitForChild("Background"):WaitForChild("Users")
	for _,child in users:GetChildren() do 
		if child:IsA("UIListLayout") then continue end
		child.Visible=false
	end
end

local partySettingsUI=playerGui:WaitForChild("partySettingsUI")

local function party_settings(world,party)
	local bg=partySettingsUI:WaitForChild("bg")
	bg.Position=UDim2.new(0.5,0,-0.5,0)
	local info=TweenInfo.new(.5,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out,0,false,0)
	ts:Create(bg,info,{Position=UDim2.new(0.5,0,0.5,0)}):Play()
	local close=bg:WaitForChild("Close")
	local connections={}
	
	local function reset()
		for index,connection in connections do 
			connection:Disconnect()
			connections[index]=nil
		end
		bg.Position=UDim2.new(0.5,0,-0.5,0)
		partySettingsUI.Enabled=false
		print("reset connections!")
	end
	
	local red=ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,17,0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255,17,0))
	})
	local green=ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(85,255,0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(85,255,0))
	})
	
	local function update_button(button,bool)
		button:WaitForChild("Background"):WaitForChild("Color"):WaitForChild("UIGradient").Color=bool and green or red
		for _,label in button:WaitForChild("Text"):GetChildren() do 
			label.Text=bool and "ON" or "OFF"
		end
	end
	
	local folder=bg:WaitForChild("Folder")
	local KICK_ALL_BUTTON=folder:WaitForChild("4"):WaitForChild("button")
	local FRIENDS_ONLY_BUTTON=folder:WaitForChild("3"):WaitForChild("button_container"):WaitForChild("button")
	update_button(FRIENDS_ONLY_BUTTON,party:GetAttribute("FriendsOnly"))
	
	local PARTY_LOCKED_BUTTON=folder:WaitForChild("2"):WaitForChild("button_container"):WaitForChild("button")
	local party_locked=party:GetAttribute("PartyLocked")
	update_button(PARTY_LOCKED_BUTTON,party:GetAttribute("PartyLocked"))
	
	local info2=TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,true,0)
	
	connections["FriendsOnlyChanged"]=party:GetAttributeChangedSignal("FriendsOnly"):Connect(function()
		update_button(FRIENDS_ONLY_BUTTON,party:GetAttribute("FriendsOnly"))
	end)
	
	connections["PartyLockedChanged"]=party:GetAttributeChangedSignal("PartyLocked"):Connect(function()
		update_button(PARTY_LOCKED_BUTTON,party:GetAttribute("PartyLocked"))
	end)
	
	connections["KICK ALL"]=KICK_ALL_BUTTON.Activated:Connect(function()
		print("kick all")
		KICK_ALL_BUTTON.Size=UDim2.new(1,0,1,0)
		ts:Create(KICK_ALL_BUTTON,info2,{Size=UDim2.new(0.8,0,0.8,0)}):Play()
		MultiversePartyEvent:FireServer("Settings",party.Parent.Name,party:GetAttribute("partyID"),"KickAll")
	end)
	connections["FRIENDS ONLY"]=FRIENDS_ONLY_BUTTON.Activated:Connect(function()
		print("friends only")
		FRIENDS_ONLY_BUTTON.Size=UDim2.new(1,0,1,0)
		ts:Create(FRIENDS_ONLY_BUTTON,info2,{Size=UDim2.new(0.8,0,0.8,0)}):Play()
		local value=party:GetAttribute("FriendsOnly")
		print("change to",not value)
		MultiversePartyEvent:FireServer("Settings",party.Parent.Name,party:GetAttribute("partyID"),"FriendsOnly",not value)
	end)
	connections["PARTY LOCKED"]=PARTY_LOCKED_BUTTON.Activated:Connect(function()
		print("party locked")
		PARTY_LOCKED_BUTTON.Size=UDim2.new(1,0,1,0)
		ts:Create(PARTY_LOCKED_BUTTON,info2,{Size=UDim2.new(0.8,0,0.8,0)}):Play()
		local value=party:GetAttribute("PartyLocked")
		print("change to",not value)
		MultiversePartyEvent:FireServer("Settings",party.Parent.Name,party:GetAttribute("partyID"),"PartyLocked",not value)
	end)
	connections["CLOSE"]=close:WaitForChild("button").Activated:Connect(function()
		partySettingsUI.Enabled=false
	end)
	connections["ENABLED"]=partySettingsUI:GetPropertyChangedSignal("Enabled"):Connect(function()
		if partySettingsUI.Enabled==false then
			reset()
		end
	end)
	
end

local function update_party(party)
	local party_container=parties:FindFirstChild(party.Name)
	if not party_container then print("couldn't find party container!") return end
	local bg=party_container:WaitForChild("Background")
	local playerCount=bg.PlayerCount
	local host=bg.Host
	local owner=party:WaitForChild("1")
	host.Text.Text=owner:GetAttribute("name")
	playerCount.Text.Text="Players "..#party:GetChildren().."/6"
	local isOwner=player.Name==owner:GetAttribute("name")
	bg.Settings.Visible=isOwner
	clear_party(party_container)
	for i=1,#party:GetChildren() do 
		local listing=party:FindFirstChild(tostring(i))
		local id=tonumber(listing.Value)
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size48x48
		local content, isReady = game.Players:GetUserThumbnailAsync(id, thumbType, thumbSize)
		local user_container=bg:WaitForChild("Users"):FindFirstChild(listing.Name)
		if not user_container then print("no user found!") return end
		user_container:WaitForChild("image").Image=isReady and content or "rbxassetid://0"
		user_container.Visible=true
		local leave=bg:WaitForChild("Leave")
		leave:WaitForChild("button").Activated:Connect(function()
			MultiversePartyEvent:FireServer("Leave",party.Parent.Name)
			partySettingsUI.Enabled=false
		end)
		local join=bg:WaitForChild("Join")
		join:WaitForChild("button").Activated:Connect(function()
			MultiversePartyEvent:FireServer("Join",party.Parent.Name,party:GetAttribute("partyID"))
		end)
		local _settings=bg:WaitForChild("Settings")
		_settings:WaitForChild("button").Activated:Connect(function()
			if partySettingsUI.Enabled then return end
			partySettingsUI.Enabled=true
			party_settings(party.Parent,party)
		end)
	end
end

local function create_party(party)
	local new=clone:Clone()
	new.Name=party.Name
	new:SetAttribute("owner",party:GetAttribute("owner"))
	new.Parent=parties
	new.Visible=true
	update_party(party)
end

local function load_world(world) -- call whenever you add/remove a party
	clear_parties()
	local folder=Multiverse_Parties:FindFirstChild(world.Name)
	for i=1,#folder:GetChildren() do -- make sure they're ordered!
		local party=folder:FindFirstChild(tostring(i))
		create_party(party)
	end
end

local button_tween_info=TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,true)

local function select_world(world)
	local name=world:WaitForChild("WorldName").Value
	local different=name~=current.name
	--if name==current.name then return end -- don't repeat
	local background=world:WaitForChild("Background")
	local uistroke=background:WaitForChild("UIStroke")
	local image=background:WaitForChild("ImageLabel")
	if different then
		local last=current
		current={name=name,world=world.Name}
		--print("world=",current.name)
		
		local last_world=worlds_container:FindFirstChild(last.world)
		local last_bg=last_world:WaitForChild("Background")
		local last_uistroke=last_bg:WaitForChild("UIStroke")
		local last_image=last_bg:WaitForChild("ImageLabel")
		last_uistroke.Enabled=false
		last_image.ImageTransparency=0.5
		
		uistroke.Enabled=true
		image.ImageTransparency=0
	end
	background.Size=UDim2.new(.95,0,.9,0)
	ts:Create(background,button_tween_info,{Size=UDim2.new(0.75,0,0.710,0)}):Play()
	if not different then return end
	load_world(name)
end

for _,world in worlds_container:GetChildren() do
	if world:IsA("UIListLayout") then continue end
	world:WaitForChild("button").Activated:Connect(function()
		select_world(world)
	end)
end

local function update_buttons()
	local found=false
	for _,world in Multiverse_Parties:GetChildren() do
		found=found==false and world:GetAttribute(player.Name) or found
		if current.name~=world.Name then continue end -- you don't need to change buttons for parties you aren't viewing
		for _,party in world:GetChildren() do
			local isInParty=party:GetAttribute(player.Name)
			local party_container=parties:FindFirstChild(party.Name)
			local bg=party_container:WaitForChild("Background")
			local join=bg:WaitForChild("Join")
			local leave=bg:WaitForChild("Leave")
			local locked=bg:WaitForChild("Locked")
			local partyFull=#party:GetChildren()>5
			if isInParty then
				leave.Visible=true
				locked.Visible=false
				join.Visible=false
				continue
			end
			if partyFull then
				print("party full")
				leave.Visible=false
				locked.Visible=false
				join.Visible=false
				continue
			end
			local PartyLocked=party:GetAttribute("PartyLocked")
			local FriendsOnly=party:GetAttribute("FriendsOnly")
			local Eligible=true -- just set it to true by default
			Eligible=FriendsOnly==false and true or player:IsFriendsWith(party:GetAttribute("owner"))
			Eligible=Eligible==true and PartyLocked==false
			leave.Visible=false
			join.Visible=Eligible
			locked.Visible=Eligible==false
		end
	end
	create.Visible=not found -- if you have a party in another world, you can't create a party in a new world!
end

local function setup_party_signals(party,world)
	party:GetAttributeChangedSignal("timer"):Connect(function()
		if current.name==world.Name then
			local party_container=parties:FindFirstChild(party.Name)
			local bg=party_container:WaitForChild("Background")
			local timer=bg:WaitForChild("Timer")
			local text=timer:WaitForChild("1"):WaitForChild("Text")
			--text.Size=UDim2.new(1,0,1,0)
			--ts:Create(text,button_tween_info,{Size=UDim2.new(.8,0,.8,0)}):Play()
			text.Text=party:GetAttribute("timer").."s"
		end
	end)
	party:GetAttributeChangedSignal("Update"):Connect(function()
		if current.name==world.Name then
			update_party(party)
			update_buttons()
		end
	end)
	party:GetAttributeChangedSignal("FriendsOnly"):Connect(function()
		-- if you're NOT in the party, change the 
		--print("friends only changed!")
		update_buttons()
	end)
	party:GetAttributeChangedSignal("PartyLocked"):Connect(function()
		--print("party locked changed")
		update_buttons()
	end)
end

for _,world in Multiverse_Parties:GetChildren() do -- existing worlds
	world:GetAttributeChangedSignal("Update"):Connect(function()
		if current.name==world.Name then
			clear_parties()
			load_world(world)
			update_buttons()
		end
	end)
	world.ChildAdded:Connect(function(party) -- whenever a new party gets added
		setup_party_signals(party,world)
	end)
	world.ChildRemoved:Connect(function(party)
		local ownerID=party:GetAttribute("owner")
		if partySettingsUI.Enabled and ownerID==player.UserId then -- you're the owner and had settings open
			partySettingsUI.Enabled=false
		end
	end)
	for _,party in world:GetChildren() do -- for the current parties already existing
		setup_party_signals(party,world)
	end
end

local create_button_clicked=false
local create_button=create:WaitForChild("button")
create_button.Activated:Connect(function()
	if create_button_clicked then return end
	create_button_clicked=true
	MultiversePartyEvent:FireServer("Create",current.name)
	create_button.Size=UDim2.new(1,0,1,0) -- reset the size just in-case
	local tween=ts:Create(create_button,button_tween_info,{Size=UDim2.new(0.8,0,0.8,0)})
	tween:Play()
	create_button_clicked=false
end)

local function removeWorldUI()
	worldChooseUI.Enabled=false
	partySettingsUI.Enabled=false
	_G.deathScreen(false)
	controls:Enable()
	lastOpen=tick()
end

local close=main:WaitForChild("Close")
close:WaitForChild("button").Activated:Connect(function()
	removeWorldUI()
end)

local function lerp(start,goal,alpha)
	return start+((goal-start)*alpha)
end

local rs=game:GetService("RunService")
local kicked_running=false
MultiversePartyEvent.OnClientEvent:Connect(function(action) -- you were kicked from party!
	if action=="Leave" then
		print("leave!")
		canTouch=false
		removeWorldUI()
		return
	end
	if kicked_running then return end
	kicked_running=true
	local kicked=main:WaitForChild("Queues"):WaitForChild("Kicked")
	local start=tick()
	local goal1=.1
	local goal2=2
	local function adjust_text_transparency(t)
		for _,text in kicked:GetChildren() do 
			text.TextTransparency=t
			local stroke=text:FindFirstChild("UIStroke")
			if stroke then
				stroke.Transparency=t
			end
		end
	end
	local function reset()
		kicked.Position=UDim2.new(.5,0,1,0) -- reset the position
		adjust_text_transparency(1)
	end
	reset()
	while true do 
		local dt=tick()-start
		local p2=math.clamp(dt/goal2,0,1)
		adjust_text_transparency(1-math.sin(math.pi*p2))
		local y=lerp(1,.975,p2)
		kicked.Position=UDim2.new(.5,0,y,0)
		if p2==1 then break end -- reached the end goal!		
		task.wait()
	end
	reset()
	kicked_running=false
end)

local listLayout=parties:WaitForChild("UIListLayout")
local function GetContentSize()
	local padding=listLayout.Padding.Offset
	local amount=#parties:GetChildren()-1
	local size=math.round(QueueContainer.AbsoluteSize.Y*0.3243243243243243)
	local contentSizeY=(size*amount)+(padding*(amount-1))
	return contentSizeY
end

local scrollInfo=TweenInfo.new(.5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
parties.ChildAdded:Connect(function(child)
	local contentSizeY=GetContentSize()
	QueueContainer.CanvasSize=UDim2.new(0,0,0,contentSizeY)
	if child:GetAttribute("owner")==player.UserId then
		print("your party was just added!")
		local difference=contentSizeY-parties.Parent.AbsoluteSize.Y
		if difference>0 then
			parties.Parent.ScrollingEnabled=false
			local tween=ts:Create(parties.Parent,scrollInfo,{CanvasPosition=Vector2.new(0,difference)})
			tween:Play()
			tween.Completed:Wait()
			parties.Parent.ScrollingEnabled=true
		end
	end
end)

parties.ChildRemoved:Connect(function(child) -- you need to manually get the size, don't rely on the layout
	local contentSizeY=GetContentSize()
	-- change the canvas size, don't change the position, it will automatically adjust
	QueueContainer.CanvasSize=UDim2.new(0,0,0,contentSizeY)
end)