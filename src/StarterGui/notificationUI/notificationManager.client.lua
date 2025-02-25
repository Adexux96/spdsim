local ui=script.Parent

--[[
	
sizes?
	x= hotbar x length
	y= cashUI y size
	
	x will be adjusted to the text length
	
	position underneath the topbar
	
]]

local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local cash=leaderstats:WaitForChild("Cash")
local rebirths=leaderstats:WaitForChild("Rebirths")
local abilities=leaderstats:WaitForChild("abilities")
local skins=leaderstats:WaitForChild("skins")
local playerGui=player:WaitForChild("PlayerGui")
local hotbarUI=playerGui:WaitForChild("hotbarUI")

local notificationUI=playerGui:WaitForChild("notificationUI")
local container=notificationUI:WaitForChild("container")

local rs=game:GetService("ReplicatedStorage")
--// modules needed
local interface=require(rs:WaitForChild("interface"))
local items=require(rs:WaitForChild("items"))
local _math=require(rs:WaitForChild("math"))

local ts=game:GetService("TweenService")
local tweenInfo1=TweenInfo.new(.25,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false)

local ability_upgrades={}
local ability_unlocks={}

local skins_upgrades={}
local skins_unlocks={}

local rebirth_upgrade=false

local function search_skins(cash_amount)
	local upgrades={}
	local unlocks={}
	
	local objectives_completed=leaderstats:WaitForChild("objectives"):WaitForChild("completed").Value
	local rebirths=rebirths.Value
	
	for _,skin in skins:GetChildren() do 
		local item=items.Skins[skin.Name]
		local unlocked=skin:WaitForChild("Unlocked").Value
		local level=skin:WaitForChild("Level").Value
		local Can_Unlock=false
		local Can_Upgrade=cash_amount>=_math.getPriceFromLevel(level,item.upgrade)

		if item.unlock then -- special requirements
			if skin.Name=="Supreme Sorcerer" then
				Can_Unlock=rebirths==10
			elseif skin.Name=="Stealth" then
				Can_Unlock=objectives_completed
			end
		else 
			Can_Unlock=cash_amount>=item.cost
		end

		if unlocked then
			if level==12 then continue end
			if not skins_upgrades[skin.Name] and Can_Upgrade then
				upgrades[#upgrades+1]="You can upgrade the "..skin.Name.." skin!"
			end
			skins_upgrades[skin.Name]=Can_Upgrade
		else 
			if not skins_unlocks[skin.Name] and Can_Unlock then
				unlocks[#unlocks+1]="You can unlock the "..skin.Name.." skin!"
			end
			skins_unlocks[skin.Name]=Can_Unlock
		end
	end
	
	return upgrades,unlocks
end

local function search_abilities(cash_amount)
	local upgrades={}
	local unlocks={}

	for _,category in abilities:GetChildren() do 
		for _,ability in category:GetChildren() do 
			local level=ability:WaitForChild("Level").Value
			local unlocked=ability:WaitForChild("Unlocked").Value
			local item=items[category.Name][ability.Name]
			
			local Can_Upgrade=cash_amount>=_math.getPriceFromLevel(level,item.upgrade)
			local Can_Unlock=cash_amount>=item.cost
			
			if unlocked then
				if level==12 then continue end
				if not ability_upgrades[ability.Name] and Can_Upgrade then
					upgrades[#upgrades+1]="You can upgrade the "..ability.Name.." ability!"
				end
				ability_upgrades[ability.Name]=Can_Upgrade
			else 
				if not ability_unlocks[ability.Name] and Can_Unlock then
					unlocks[#unlocks+1]="You can unlock the "..ability.Name.." ability!"
				end
				ability_unlocks[ability.Name]=Can_Unlock
			end
			
		end
	end
	
	return upgrades,unlocks
end

local function search_rebirth(cash_amount)
	if rebirths.Value==10 then return nil end
	local Can_Rebirth=cash_amount>=_math.getRebirthPrice(rebirths.Value)
	if rebirth_upgrade and Can_Rebirth then
		return nil -- don't allow a repeat
	end
	rebirth_upgrade=Can_Rebirth
	return Can_Rebirth and "You have a rebirth available!" or nil
end

local function create_notification(priority,text)
	-- rename all of the notifications and create a new one at the top
	local sound=notificationUI:WaitForChild("typing")
	local count=1
	for i,child in container:GetChildren() do 
		if not child:IsA("Frame") or child.Name=="clone" then continue end
		count+=1
		child.Name=child.Name+1
	end
	local clone=container:WaitForChild("clone"):Clone()
	local sound_clone=sound:Clone()
	sound_clone.Parent=clone
	local frame=clone.Frame
	frame.priority.Value=priority
	clone.Visible=true
	clone.Name="1"
	clone.Parent=container
	interface.size_notification(clone,text)
	game:GetService("Debris"):AddItem(clone,10)
	clone.Frame.Position=UDim2.new(0,0,0,-100)
	ts:Create(clone.Frame,tweenInfo1,{Position=UDim2.new(0,0,0,0)}):Play()
	task.spawn(function()
		sound_clone:Play()
		task.wait(math.random(1,3)*.25)
		sound_clone:Stop()
		sound_clone:Destroy()
	end)
end

local function remove_notification(notification)
	--print("removed",notification.Name)
	-- make sure it doesn't disturb the delayed removal
	if notification then
		notification:Destroy()
	end
end

local function search_notifications(priority)
	local lowest_priority=math.huge
	local notification_found=nil
	local amount=0
	for i,listing in container:GetChildren() do 
		if listing.Name=="clone" or not listing:IsA("Frame") then continue end
		amount+=1
		local _priority=listing:WaitForChild("Frame"):WaitForChild("priority").Value
		if _priority<=priority and _priority<lowest_priority then
			lowest_priority=_priority
			notification_found=listing
		end
	end
	return lowest_priority,notification_found,amount
end

local function sort_notifications(...)
	local items={...}
	--[[
		if lower or equal priority notifications exist:
			remove the lowest priority
		if there no lower or equal:
			don't add new notification
		
	]]
	for i,notification in items do
		--print(i,notification)
		local lowest,notif,amount=search_notifications(i)
		--print("lowest=",lowest)
		if lowest==i or amount==3 then
			remove_notification(notif)
		end
		if lowest<=i or lowest==math.huge then
			create_notification(i,notification) -- create the new notification
		end
	end
end

_G.cash_changed=function(portal,pvp)
	local cash_amount=cash.Value
	local ability_upgrades,ability_unlocks=search_abilities(cash_amount)
	local skin_upgrades,skin_unlocks=search_skins(cash_amount)
	local rebirth=search_rebirth(cash_amount)
	
	local ability=nil
	if #ability_unlocks>0 then
		if #ability_unlocks>1 then
			ability="You have new abilities to unlock!"
		else 
			ability=ability_unlocks[1]
		end
	else 
		if #ability_upgrades>1 then
			ability="You have new ability upgrades available!"
		else 
			ability=ability_upgrades[1]
		end
	end
	
	local skin=nil
	if #skin_unlocks>0 then
		if #skin_unlocks>1 then
			skin="You have new skins to unlock!"
		else 
			skin=skin_unlocks[1]
		end
	else 
		if #skin_upgrades>1 then
			skin="You have new skin upgrades available!"
		else 
			skin=skin_upgrades[1]
		end
	end
	
	sort_notifications(portal,skin,ability,rebirth,pvp)
end

--[[
for _,category in abilities:GetChildren() do 
	for _,ability in category:GetChildren() do 
		ability:WaitForChild("Unlocked"):GetPropertyChangedSignal("Value"):Connect(function()
			_G.cash_changed()
		end)
	end
end

for _,skin in skins:GetChildren() do 
	skin:WaitForChild("Unlocked"):GetPropertyChangedSignal("Value"):Connect(function()
		_G.cash_changed()
	end)
end
]]

--cash_changed() -- initial run when u join

--cash:GetPropertyChangedSignal("Value"):Connect(_G.cash_changed)

--[[

(in order)
	pvp toggle
	events (later)
	rebirths
	abilities: upgrades, unlocks (unlocks show above upgrades)
	skins: upgrades, unlocks
	boss spawns
	apartment party (later)

	"You have new ability upgrades available!"
		"You can upgrade the Punch ability!"
	"You have new abilities to unlock!"
		"You can unlock the Web Bomb ability!"
	
	"You have new skin upgrades available!"
		"You can upgrade the Miles Classic skin!"
	"You have new skins to unlock!"
		"You can unlock the Supreme Sorceror skin!"
	
	"You have a rebirth available!"
	
	"You have a reward available!"
	
	"A multiverse portal has opened!"
	
	"PVP was turned on"
	"PVP was turned off"
	"Wait x sec to toggle PVP again"
	"Wait x sec out of combat to turn PVP off"
	
]]
