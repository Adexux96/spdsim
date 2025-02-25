local proximityService=game:GetService("ProximityPromptService")

local player=game.Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")

local rs=game:GetService("ReplicatedStorage")
local crate_prompt=rs:WaitForChild("crate_prompt")

local function child_added(child)
	if child.Name=="ProximityPrompts" then
		child.ChildAdded:Connect(function(prompt)
			--print("prompt added")
			local frame=prompt:WaitForChild("Frame")
		end)
	end
end

playerGui.ChildAdded:Connect(child_added)
--[[
proximityService.PromptButtonHoldBegan:Connect(function(prompt)
	--print("hold began")
end)

proximityService.PromptButtonHoldEnded:Connect(function(prompt)
	--print("hold ended")
end)
]]