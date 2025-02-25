--!nocheck

local promptUI=script.Parent
local container=promptUI:WaitForChild("container")

local rs=game:GetService("ReplicatedStorage")
local interface=require(rs:WaitForChild("interface"))

if not _G.slot_size then repeat task.wait() until _G.slot_size end

local function Get_Text_Size(Text:string, TextLabel:TextLabel)
	local TextLabel=container:WaitForChild("TextLabel")
	TextLabel.Text=Text
	return TextLabel.TextBounds, TextLabel.TextFits
end

--[[
	Text sizes:
		text size is 40% of slot size for dialogue
		text size is 36% of slot size for notifications
]]

--[[
		size: 
		X:
		min size = the length of the text
		max size = the length of the hotbar
		start with the max length then minimize it to the text bounds X size
		
		Y:
		size= slot size/2
		
		text size = Y*0.8333
		
		pos:
		X:
		0.5
		
		Y:
		2 rows above the bottom of the screen (which if the cutscene is playing is above the black screen cut)
]]

local function Size_Box(x,y,container)
	
end

local function Get_Dialogue_Box_Size(_type:string,text:string)
	local x_Max=(_G.slot_size*8)+(_G.slot_offset*7)
	local x_Min
	
end

local function Get_Objective_Box_Size()
	local y=_G.slot_size
	local x=y*3
	return x,y
end

local function Create_Dialogue_Box()

end

local function Create_Objective_Box()
	local x,y=Get_Objective_Box_Size()
	-- cash icon size is .5 * container size
	-- cash text is .35 * container size
	-- size box first then position it offset from side of screen
	-- get the exact offset from the edge, then offset the same as the cash is offsetted
	
end

-- get the size of the box
-- create the box
-- position the box and generate the text gradually!

