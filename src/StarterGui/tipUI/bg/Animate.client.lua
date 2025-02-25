--local world1=script.Parent:WaitForChild("world1")
local world2=script.Parent:WaitForChild("world2")

local spiderman=world2:WaitForChild("world"):WaitForChild("spiderman")
local thug=world2:WaitForChild("world"):WaitForChild("thug")
local roll=world2:WaitForChild("Roll")
local roll_anim=spiderman:WaitForChild("Humanoid"):LoadAnimation(roll)
local fight_idle=world2:WaitForChild("Fight_Idle")
local fight_idle_anim=spiderman:WaitForChild("Humanoid"):LoadAnimation(fight_idle)

local bat=world2:WaitForChild("Bat")
local bat_anim=thug:WaitForChild("Humanoid"):LoadAnimation(bat)
local bat_idle=world2:WaitForChild("Bat_Idle")
local bat_idle_anim=thug:WaitForChild("Humanoid"):LoadAnimation(bat_idle)
local bat_fight_idle_anim=thug:WaitForChild("Humanoid"):LoadAnimation(fight_idle)

fight_idle_anim.Looped=true
fight_idle_anim:Play()

bat_fight_idle_anim.Looped=true
bat_fight_idle_anim:Play()

bat_idle_anim.Looped=true
bat_idle_anim:Play()

local ts=game:GetService("TweenService")
local info=TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,true)

local bottom=world2:WaitForChild("bottom")
local mobile=bottom:WaitForChild("2"):WaitForChild("mobile")
local PC=bottom:WaitForChild("2"):WaitForChild("PC")

if _G.platform==nil then
	repeat task.wait(.5) until _G.platform~=nil
end

mobile.Visible=_G.platform=="mobile"
PC.Visible=_G.platform=="PC"

local mobile_size=mobile.AbsoluteSize.X
local smaller=math.round(mobile_size*.8)

if _G.tip==nil then
	repeat task.wait(.5) until _G.tip
end

local exited=false
local exit=script.Parent:WaitForChild("exit")
local ui=script.Parent.Parent
local bg=ui:WaitForChild("bg")

local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local roll_value=leaderstats:WaitForChild("tutorial"):WaitForChild("Roll")

--[[
if roll_value.Value then 
	ui.Enabled=false
	return 
end
]]

local bring_down=ts:Create(bg,TweenInfo.new(.5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false),{Position=UDim2.new(0.5,0,0.5,0)})
bring_down:Play()

exit.Activated:Connect(function()
	exited=true
	--local bring_up=ts:Create(bg,TweenInfo.new(.5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false),{Position=UDim2.new(0.5,0,-1,0)})
	--bring_up:Play()
	--bring_up.Completed:Wait()
	script.Parent.Parent.Enabled=false
	game:GetService("ReplicatedStorage"):WaitForChild("RollEvent"):FireServer()
end)

while exited==false do 
	bat_anim:Play()
	bat_anim:AdjustSpeed(2)
	roll_anim:Play()
	bat_anim:AdjustSpeed(2)
	--ts:Create(mobile,info,{Size=UDim2.new(0,smaller,0,smaller)}):Play()
	--ts:Create(PC,info,{Position=UDim2.new(0,0,0.25,0)}):Play()
	task.wait(2)
end
