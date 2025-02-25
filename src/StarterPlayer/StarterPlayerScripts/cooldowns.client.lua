local rs=game:GetService("ReplicatedStorage")
local clock=rs:WaitForChild("clock")

local items=require(rs:WaitForChild("items"))

local cooldowns = {
	["Roll"]=1,
	["Punch"] = .25,
	["Kick"] = .5,
	["360 Kick"] = .75,
	["Swing Web"] = .5,--.25,
	["Launch Webs"] = .5,--.25,
	["Impact Web"] = .25,
	["Snare Web"] = 30,
	["Shotgun Webs"] = .5,
	["Trip Web"] = .25,
	["Web Bomb"] = 10,
	["Anti Gravity"] = 30,
	["Spider Drone"] = 10,
	["Gauntlet"]=10
}

local player=game.Players.LocalPlayer
local ActionButtonDown=player:WaitForChild("leaderstats"):WaitForChild("temp"):WaitForChild("ActionButtonDown")
local playerGui=player:WaitForChild("PlayerGui")
local hotbarUI=playerGui:WaitForChild("hotbarUI")
local hotbarContainer=hotbarUI:WaitForChild("container")
local controlsUI=playerGui:WaitForChild("controlsUI")

local mobile=controlsUI:WaitForChild("mobile")
local mobile_roll=mobile:WaitForChild("roll")
local mobile_roll_button=mobile_roll:WaitForChild("button")
local mobile_roll_icon=mobile_roll:WaitForChild("icon")

local mobile_ability=mobile:WaitForChild("ability")
local mobile_ability_button=mobile_ability:WaitForChild("button")
local mobile_ability_icon=mobile_ability:WaitForChild("icon")

local pc=controlsUI:WaitForChild("pc")
local pc_roll=pc:WaitForChild("roll")
local pc_roll_button=pc_roll:WaitForChild("button")
local pc_roll_icon=pc_roll:WaitForChild("icon")

local pc_ability=pc:WaitForChild("ability")
local pc_ability_button=pc_ability:WaitForChild("button")
local pc_ability_icon=pc_ability:WaitForChild("icon")

_G.cooling={}

local function EmptySlot(slot)
	slot:WaitForChild("cooldown").Value=false
end

local Selected=hotbarContainer:WaitForChild("Selected")
local current_ability=nil
local ability,category="",""

-- it reads the 

local function SelectedChanged()
	if Selected.Value~=0 then
		local slot=hotbarContainer:FindFirstChild(tostring(Selected.Value))
		ability=slot:WaitForChild("name").Value
		category=slot:WaitForChild("category").Value
	end
end

Selected:GetPropertyChangedSignal("Value"):Connect(SelectedChanged)

while true do

	if _G.cooling["Roll"] then
		local elapsed=tick()-_G.cooling["Roll"]
		local text=math.floor((cooldowns["Roll"]-elapsed)*10)/10
		pc_roll_icon.ImageTransparency=.5
		mobile_roll_icon.ImageTransparency=.5
		pc_roll_button.Text=text
		mobile_roll_button.Text=text
		if elapsed>=cooldowns["Roll"] then
			_G.cooling["Roll"]=nil
			pc_roll_icon.ImageTransparency=0.1
			mobile_roll_icon.ImageTransparency=0.1
			pc_roll_button.Text=""
			mobile_roll_button.Text=""
		end
	else 
		pc_roll_icon.ImageTransparency=0.1
		mobile_roll_icon.ImageTransparency=0.1
		pc_roll_button.Text=""
		mobile_roll_button.Text=""
	end

	pc_ability.Visible=Selected.Value~=0
	mobile_ability.Visible=Selected.Value~=0

	-- issue: when you select a new ability while AbilityCooldown value is true it starts a new cooldown for that ability!
	-- fix: AbilityCooldown needs to be set to false whenever the selected changes

	if Selected.Value~=0 then -- you selected an ability
		local offset=items[category][ability].offset
		pc_ability_icon.ImageRectOffset=offset
		mobile_ability_icon.ImageRectOffset=offset
		if _G.cooling[ability] then
			local elapsed=tick()-_G.cooling[ability]
			local text=math.floor((cooldowns[ability]-elapsed)*10)/10
			pc_ability_icon.ImageTransparency=.5
			pc_ability_button.Text=text
			mobile_ability_icon.ImageTransparency=.5
			mobile_ability_button.Text=text
			if elapsed>=cooldowns[ability] then
				_G.cooling[ability]=nil
				pc_ability_icon.ImageTransparency=.1
				pc_ability_button.Text=""
				mobile_ability_icon.ImageTransparency=.1
				mobile_ability_button.Text=""
			end
		else
			pc_ability_icon.ImageTransparency=.1
			pc_ability_button.Text=""
			mobile_ability_icon.ImageTransparency=.1
			mobile_ability_button.Text=""
		end
	end

	-- update the hotbar elements cooldowns
	for _,slot in hotbarContainer:GetChildren() do
		if not slot:IsA("Frame") then continue end
		local cooldown=slot:WaitForChild("cooldown")
		local ability=slot:WaitForChild("name").Value

		if ability=="" then 
			cooldown.Value=false 
			continue 
		end

		local timer=slot:WaitForChild("cooldownTimer")
		local _slot=slot:WaitForChild("slot")
		local counter=_slot:WaitForChild("counter")

		-- objective: newly placed abilities in the hotbar inherit the cooldown (done)
		-- fix: when you drag ability to other slot after cooldown ImageTransparency stays 0 (done)

		if _G.cooling[ability] then
			cooldown.Value=true
			timer.Value=_G.cooling[ability]
			local elapsed=tick()-_G.cooling[ability]
			counter.Text=math.floor((cooldowns[ability]-elapsed)*10)/10
			--print(counter.Text)
			if elapsed>=cooldowns[ability] then
				cooldown.Value=false
				counter.Text=""
				timer.Value="0"
			end
		else
			cooldown.Value=false
			counter.Text=""
			timer.Value="0"
		end
		
	end

	for ability,timer in _G.cooling do 
		if tick()-timer>=cooldowns[ability] then
			_G.cooling[ability]=nil -- remove it from the dictionary
		end
	end

	clock:GetPropertyChangedSignal("Value"):Wait()
	--task.wait()
end