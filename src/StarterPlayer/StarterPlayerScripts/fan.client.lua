local ts=game:GetService("TweenService")
local room=workspace:WaitForChild("RoomScene")
local fan=room:WaitForChild("fan")

local info=TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,-1,false,0)

local tween=ts:Create(fan,info,{Orientation=Vector3.new(0,-180,0)})
tween:Play()

fan:GetPropertyChangedSignal("Parent"):Connect(function()
	tween:Destroy()
end)