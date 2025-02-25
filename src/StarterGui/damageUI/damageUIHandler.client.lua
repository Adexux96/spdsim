local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local damageUI = script.Parent

local rs = game:GetService("RunService")

local leaderstats = player:WaitForChild("leaderstats")
local indicators = leaderstats:WaitForChild("indicators")

local uis = {}

local camera=  workspace.CurrentCamera

local function returnAngle(a,b)
	local ignoreY = Vector3.new(1,0,1)
	local lookAt = CFrame.new(a*ignoreY,b*ignoreY)
	local x,y,z = lookAt:ToOrientation()
	return math.deg(y)
end

local function childAdded(child)
	local clone = damageUI:WaitForChild("clone"):Clone()
	clone.Name = child.Name 
	clone.Visible = true
	clone.Transparency = 1
	clone.Parent = damageUI
	uis[#uis+1] = {
		objectValue = child,
		start = tick(),
		onScreen = nil,
		stop = nil,
		ui = clone,
		lastObjectPosition = child.Value.Position,
		incognito = false,
		incognitoTick = nil
	}
	--[[
	local character=player.Character
	if not character.PrimaryPart then return end
	local head=character:FindFirstChild("Head")
	local FaceCenterAttachment=head:FindFirstChild("FaceCenterAttachment")
	]]
end

indicators.ChildAdded:Connect(childAdded)

while true do 
	pcall(function()
		local character = player.Character
		for i = 1,#uis do 
			local index = uis[i]
			local objectNil = index.objectValue == nil
			--local objectNil = index.objectValue.Value == nil
			local function rotateUI(enemyPos,transparency)
				index.ui.ImageTransparency = transparency
				local cameraPos = camera.CFrame.Position
				local theta = returnAngle(cameraPos,enemyPos)
				local x,y,z = camera.CFrame:ToOrientation()
				index.ui.Rotation = math.deg(y) - theta
			end
			local function remove()
				if index.stop == nil then
					index.stop = tick()
				else 
					local p = math.clamp((tick() - index.stop) / .5,0,1)
					rotateUI(index.lastObjectPosition,math.clamp(p+.5,.5,1))
					if p == 1 then
						index.ui:Destroy()
						table.remove(uis,i)
					end
				end
			end
			if not objectNil then
				local objectDestroyed = index.objectValue.Parent == nil
				
				if objectDestroyed then
					remove()
				else 
					local enemyPos = index.objectValue.Value.Position
					index.lastObjectPosition = enemyPos
					local p = math.clamp((tick() - index.start) / .5,0,1)
					rotateUI(enemyPos,1-(p-.5))
				end		
			else 
				remove()
			end 
		end	
	end)
	rs.RenderStepped:Wait()
end
