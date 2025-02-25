local rs=game:GetService("ReplicatedStorage")

local remote=rs:WaitForChild("SpideySense")
local effect=rs:WaitForChild("Spidey_Sense")

local ts=game:GetService("TweenService")
local ti=TweenInfo.new(.25,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)

local function spidey_sense_effect(player,override)
	--if player==game.Players.LocalPlayer and not override then return end -- don't let the server trigger your own spidey sense again
	local character=player and player.Character or nil
	local head=character and character:FindFirstChild("Head") or nil
	local spidey_sense=head and head:FindFirstChild("Spidey_Sense") or nil
	if spidey_sense or not head then return end -- head didn't load or spidey sense already exists
	
	local hasSense=character:GetAttribute("HasSense")
	if hasSense then return end
	character:SetAttribute("HasSense",true)
	
	local clone=effect:Clone()
	clone.Adornee=head
	clone.Parent=character
	local image=clone.ImageLabel
	image.Size=UDim2.new(0,0,0,0)
	local tween2=ts:Create(image,ti,{Size=UDim2.new(1.1,0,1.1,0)})
	local tween=ts:Create(image,ti,{ImageTransparency=0})
	tween:Play()
	tween2:Play()
	tween.Completed:Wait()
	task.wait(1)
	tween=ts:Create(image,ti,{ImageTransparency=1})
	tween2=ts:Create(image,ti,{Size=UDim2.new(0,0,0,0)})
	tween2:Play()
	tween:Play()
	tween.Completed:Wait()
	clone:Destroy()
	character:SetAttribute("HasSense",false)
end

remote.OnClientEvent:Connect(spidey_sense_effect)