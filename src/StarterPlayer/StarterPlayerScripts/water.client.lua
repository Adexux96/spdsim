local water = workspace:WaitForChild("water")
local waterHeight = game:GetService("ReplicatedStorage"):WaitForChild("waterHeight")

local ts = game:GetService("TweenService")
local t = 50
local tweenInfo1 = TweenInfo.new(t * 3,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true,0)
local tweenInfo2 = TweenInfo.new(t * 1.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true,0)

local waterUV = game:GetService("ReplicatedStorage"):WaitForChild("waterUV")

local OffsetStudsU = waterUV:WaitForChild("U")
local OffsetStudsV = waterUV:WaitForChild("V")

--ts:Create(OffsetStudsU,tweenInfo1,{Value = 500}):Play()
--ts:Create(OffsetStudsV,tweenInfo2,{Value = 250}):Play()

local _tickU = tick()
local _tickV = tick()
local _cycleDuration = 50
local reverseU = false
local reverseV = false

waterHeight:GetPropertyChangedSignal("Value"):Connect(function()
	local pU = math.clamp((tick()-_tickU)/_cycleDuration,0,1)
	local pV = math.clamp((tick()-_tickV)/(_cycleDuration*.5),0,1)
	
	local _alphaU = ts:GetValue(pU,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut) 
	local _alphaV = ts:GetValue(pV,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut) 
	
	local _goalU = reverseU == true and 500-(_alphaU*500) or _alphaU*500
	local _goalV = reverseV == true and 250-(_alphaV*250) or _alphaV*250
	
	for _,waterPart in (water:GetChildren()) do
		waterPart.Position = Vector3.new(waterPart.Position.X,-13,waterPart.Position.Z) --+ Vector3.new(0,waterHeight.Value,0)
		waterPart:FindFirstChild("Texture").OffsetStudsU = _goalU
		waterPart:FindFirstChild("Texture").OffsetStudsV = _goalV
	end
	
	if pU == 1 then
		_tickU = tick() 
		reverseU = not reverseU -- toggle
	end
	if pV == 1 then
		_tickV = tick() 
		reverseV = not reverseV -- toggle
	end
	
end)


