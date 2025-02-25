local rs=game:GetService("ReplicatedStorage")
local cs=game:GetService("CollectionService")
local runService=game:GetService("RunService")

local player=game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hotbarUI = playerGui:WaitForChild("hotbarUI")
local selected = hotbarUI:WaitForChild("container"):WaitForChild("Selected")

local camera=workspace.CurrentCamera
local clock=rs:WaitForChild("clock")

local camShake={}
camShake.shaking=false
camShake.newShake=false
camShake.camShakeAmount = rs:WaitForChild("camShakeAmount")
camShake.camShakeDuration = rs:WaitForChild("camShakeDuration")
camShake.start=tick()

_G.camShake = function(duration,percent)
	local percent = percent ~= nil and math.clamp(percent,0,1) or 1
	--print("camShake percent=",percent)
	local amount = math.round(duration/(1/60))

	camShake.camShakeDuration.Value = duration
	camShake.camShakeAmount.Value = amount * percent;
	camShake.start = tick()
end

while true do
	local character=player.Character
	if camShake.camShakeAmount.Value~=0 then
		local amount=math.round(camShake.camShakeDuration.Value/(1/60))
		local p = math.clamp((tick() - camShake.start) / camShake.camShakeDuration.Value,0,1)
		camShake.camShakeAmount.Value = math.round(amount*(1-p))
		if selected.Value == 0 or (character and not cs:HasTag(character,"ragdolled")) then -- if isn't ragdolled and OTS camera is off
			local factor=camShake.camShakeAmount.Value/(amount/5)*2
			camera.CFrame *= CFrame.fromEulerAnglesXYZ(math.sin(tick() * 15) * 0.002 * factor, math.sin(tick() * 25) * 0.002 * factor, 0)
		end
	end
	--clock:GetPropertyChangedSignal("Value"):Wait()
	runService.RenderStepped:Wait()
end