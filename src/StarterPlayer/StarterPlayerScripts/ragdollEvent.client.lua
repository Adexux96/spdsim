local rs = game:GetService("ReplicatedStorage")
local cs = game:GetService("CollectionService")
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local ragdollEvent = rs:WaitForChild("ragdollEvent")
local ragdoll = require(rs:WaitForChild("ragdoll"))
local otsCamModule = require(rs:WaitForChild("OTS_Camera"))

local leaderstats=player:WaitForChild("leaderstats")
local temp=leaderstats:WaitForChild("temp")
local ragdollRecovery=temp:WaitForChild("RagdollRecovery")

local function adjustRagdollRecovery(bool,character,recoveryTime,start)
	local success,error=pcall(function()
		local humanoid=character:WaitForChild("Humanoid")
		local alive=humanoid.Health>0
		if not alive or bool==false then
			ragdollRecovery.Value=0 --// reset the recovery value which shuts off the countdown
			return
		end
		while true do
			local elapsed=recoveryTime-(workspace:GetServerTimeNow()-start)
			ragdollRecovery.Value=math.ceil(elapsed) -- 1.5 -> 2
			task.wait(1/20)
			if elapsed<=0 then break end
			if not (humanoid.Health>0) then break end
		end
	end)
end

ragdollEvent.OnClientEvent:Connect(function(bool,recoveryTime,start)
	--pcall(function()
	if _G.reset_inputs then
		_G.reset_inputs()
	end
	if not player.Character then return end
	local c = player.Character
	if c== nil or c.Parent == nil then return end
	local f=coroutine.wrap(adjustRagdollRecovery)
	f(bool,c,recoveryTime,start)
	if (bool) then
		if otsCamModule.running then
			otsCamModule.ShutDown()
		end
		ragdoll.clientStart(camera,c,c.PrimaryPart,c:WaitForChild("Head"),c:WaitForChild("Humanoid"))
		--wait(.25)
		--[[
		for i = 1,math.huge do -- initiate fall height check
			if (c.PrimaryPart.Velocity.magnitude < 2) then
				print("humanoid stopped falling!")
				local dist = math.floor((tempData.yPosBeforeRagdoll.Value - c.PrimaryPart.Position.Y)*10)/10
				print('client calculated fall distance @ approx ',dist,' studs.')
				if (dist > 15) then
					_fallDamage:FireServer("fall",dist)
					break
				else
					break
				end
			end
			runService.Heartbeat:Wait()
		end]]
	elseif not (bool) then
		ragdoll.clientEnd(camera,c.PrimaryPart,c:WaitForChild("Head"),c:WaitForChild("Humanoid"))
		otsCamModule.Reboot()
	end
	--end)
end)
