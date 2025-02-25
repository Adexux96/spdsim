local rs=game:GetService("ReplicatedStorage")
local LeaderboardEvent=rs:WaitForChild("LeaderboardEvent") 

local _math=require(rs:WaitForChild("math"))

local TopCash=rs:WaitForChild("Top Cash")
local TopKillstreak=rs:WaitForChild("Top Killstreak")

local folder=game.ReplicatedStorage["Top Cash"]

local function least(a,b)
	return tonumber(a.Name)<tonumber(b.Name)
end

local colors={
	[1]=Color3.fromRGB(255, 207, 110),
	[2]=Color3.fromRGB(230,230,230),
	[3]=Color3.fromRGB(193, 159, 120)
}

local function writeData(ui,data)
	--print("ui=",ui)
	--print("data=",data)
	if not ui or not data then return end
	local container=ui:WaitForChild("outerContainer"):WaitForChild("innerContainer")
	local folder=ui:WaitForChild("Folder")
	local clone=folder:WaitForChild("clone")
	local list=folder:WaitForChild("listClone"):Clone()
	container:ClearAllChildren()
	list.Parent=container
	table.sort(data,least)
	for i,folder in data do
		local value=folder:FindFirstChildOfClass("NumberValue")
		if not value then --[[print("value didn't exist!")]] continue end
		local new=clone:Clone()
		--new["1"].Text="#"..i
		--new["1"].TextColor3=colors[i] and colors[i] or Color3.fromRGB(255, 255, 255)
		--local id=value:GetAttribute("id")
		local id=value:GetAttribute("id")
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size48x48
		local content, isReady = game.Players:GetUserThumbnailAsync(id, thumbType, thumbSize)
		new["1"].icon.Image=isReady and content or "rbxassetid://0"
		new["2"].Text=value.Name
		new["2"].TextColor3=colors[i] and colors[i] or Color3.fromRGB(255, 255, 255)
		new["3"].Text=_math.toSuffixString(value.Value)
		new["3"].TextColor3=colors[i] and colors[i] or Color3.fromRGB(255, 255, 255)
		new.Visible=true
		new.Parent=container
	end
end

local function UpdateCash()
	--print("updated cash!")
	local billboard=workspace:FindFirstChild("RooftopBillboard")
	local board=billboard and billboard:FindFirstChild("Board") or nil
	local cash=board and board:FindFirstChild("cash") or nil
	writeData(cash,TopCash:GetChildren())
end

local function UpdateKillstreak()
	--print("updated killstreak!")
	local billboard=workspace:FindFirstChild("RooftopBillboard")
	local board=billboard and billboard:FindFirstChild("Board") or nil
	local killstreak=board and board:FindFirstChild("killstreak") or nil
	writeData(killstreak,TopKillstreak:GetChildren())
end

TopCash:GetAttributeChangedSignal("LastUpdate"):Connect(UpdateCash)
TopKillstreak:GetAttributeChangedSignal("LastUpdate"):Connect(UpdateKillstreak)

local TopDonors=rs:WaitForChild("Top Donors")
local donation_leaderboard=workspace:WaitForChild("DonationLeaderboard")
local board=donation_leaderboard:WaitForChild("Board")
local board_surface_gui=board:WaitForChild("Page"):WaitForChild("SurfaceGui")
local board_players=board_surface_gui:WaitForChild("2")
local clone=board_surface_gui:WaitForChild("Folder"):WaitForChild("clone")
local board_nav_button=board_surface_gui:WaitForChild("Page"):WaitForChild("nav_buttons"):WaitForChild("Button")
local list=donation_leaderboard:WaitForChild("List")

local stand=workspace:WaitForChild("Stand")
local TOP_DONATOR_RIG=workspace:WaitForChild("Top_Donator_Rig")

local CURRENT_PAGE=1
local LOADING_PAGE=false
local function load_page(page,list)
	if LOADING_PAGE then return end
	LOADING_PAGE=true
	for _,element in board_players:GetChildren() do
		if element:IsA("UIListLayout") then continue end
		element:Destroy()
	end
	local start=(10*page)-10+1
	local last=start+9
	for i=start,last,1 do 
		local listing=list:FindFirstChild(tostring(i))
		if not listing then continue end
		listing=listing:FindFirstChildOfClass("NumberValue")
		local new=clone:Clone()
		new.Name=i
		local id=listing:GetAttribute("id")
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size48x48
		local content, isReady = game.Players:GetUserThumbnailAsync(id, thumbType, thumbSize)
		new["1"].Image=isReady and content or "rbxassetid://0"
		new["2"].Text=listing.Name
		new["3"].Text=_math.toSuffixString(listing.Value)
		new.Visible=true
		new.Parent=board_players
	end
	LOADING_PAGE=false
end

board_nav_button.Activated:Connect(function()
	local has_more_than_1_page=#TopDonors:GetChildren()>10
	--if not has_more_than_1_page then return end
	local num_pages=math.ceil(#TopDonors:GetChildren()/10)
	CURRENT_PAGE+=1
	if CURRENT_PAGE>num_pages then
		CURRENT_PAGE=1
	end
	board_surface_gui:WaitForChild("Page"):WaitForChild("TextLabel").Text="< Page: "..CURRENT_PAGE.." >"
	load_page(CURRENT_PAGE,TopDonors)
end)

local function UpdateDonations()
	load_page(CURRENT_PAGE,TopDonors)
	local listing=TopDonors:WaitForChild("1")
	local value=listing:FindFirstChildOfClass("NumberValue")
	local UI=TOP_DONATOR_RIG:WaitForChild("Head"):FindFirstChild("TopDonor")
	if not UI then
		UI=rs:WaitForChild("TopDonor"):Clone()
		UI.Parent=TOP_DONATOR_RIG:WaitForChild("Head")
	end
	UI.Adornee=TOP_DONATOR_RIG:WaitForChild("Head")
	UI:WaitForChild("2").Text=value.Name
end

--UpdateCash()
--UpdateKillstreak()
--UpdateDonations()

TopDonors:GetAttributeChangedSignal("LastUpdate"):Connect(UpdateDonations)

local donations_list=list:WaitForChild("Page"):WaitForChild("SurfaceGui")
local donations_list_nav_buttons=donations_list:WaitForChild("Page"):WaitForChild("nav_buttons")
local donations_list_pages=donations_list:WaitForChild("2")
local list_page1=donations_list_pages:WaitForChild("Page1")
local list_page2=donations_list_pages:WaitForChild("Page2")

for _,button in donations_list_nav_buttons:GetChildren() do 
	if button:IsA("UIListLayout") then continue end
	button.Activated:Connect(function()
		if list_page1.Visible then
			list_page1.Visible=false
			list_page2.Visible=true
			button.Parent.Parent.TextLabel.Text="< Page: 2 >"
		else 
			list_page1.Visible=true
			list_page2.Visible=false
			button.Parent.Parent.TextLabel.Text="< Page: 1 >"
		end
		
	end)
end

local sales=require(rs:WaitForChild("sales"))

for _,page in donations_list_pages:GetChildren() do 
	for _,button in page:GetChildren() do 
		if button:IsA("UIListLayout") then continue end
		button.Activated:Connect(function()
			print(button.Text)
			button.TextColor3=Color3.fromRGB(255,255,255)
			task.wait(.2)
			button.TextColor3=Color3.fromRGB(87,255,121)
			sales:PromptProduct(button:WaitForChild("ID").Value,game.Players.LocalPlayer)
		end)
	end
end

local Top_Donator_Rig=workspace:WaitForChild("Top_Donator_Rig")
local Humanoid=Top_Donator_Rig:WaitForChild("Humanoid")

local Sturdy=Top_Donator_Rig:WaitForChild("Sturdy")
local Skibidi=Top_Donator_Rig:WaitForChild("Skibidi")
local JumpWave=Top_Donator_Rig:WaitForChild("JumpWave")
local Floss=Top_Donator_Rig:WaitForChild("Floss")
local AroundTown=Top_Donator_Rig:WaitForChild("AroundTown")
local HeroLanding=Top_Donator_Rig:WaitForChild("HeroLanding")
local GodLike=Top_Donator_Rig:WaitForChild("GodLike")
local PowerBlast=Top_Donator_Rig:WaitForChild("PowerBlast")
local Happy=Top_Donator_Rig:WaitForChild("Happy")

local anims={
	--Sturdy,
	--Floss,
	--JumpWave,
	--Skibidi,
	--AroundTown,
	--HeroLanding,
	--GodLike,
	--PowerBlast,
	Happy
}

--[[
spawn(function()
	while task.wait() do
		local t = 5; 
		local hue = tick() % t / t
		local colorrr = Color3.fromHSV(hue, 1, 1)
		workspace:WaitForChild("Top_Donator_Rig"):WaitForChild("Head"):WaitForChild("TopDonor"):WaitForChild("2").TextColor3 = colorrr
	end
end)
]]

local new=Humanoid:LoadAnimation(Sturdy)
new:Play()

UpdateCash()
UpdateKillstreak()
UpdateDonations()