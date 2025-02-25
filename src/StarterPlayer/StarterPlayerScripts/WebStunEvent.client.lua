local rs=game:GetService("ReplicatedStorage")
local WebStunEvent=rs:WaitForChild("WebStunRemote")

local stunValue=Instance.new("StringValue")
local stuns={}

local player=game.Players.LocalPlayer

WebStunEvent.OnClientEvent:Connect(function(model,duration,start)
	local plr=game.Players:GetPlayerFromCharacter(model)
	if plr and plr==player then return end
	local body=model:FindFirstChild("Body")
	local collision=model:FindFirstChild("CollisionPart")
	local part=collision or (body and body.PrimaryPart)
	part=part or model.PrimaryPart
	if not part then return end
	--print("part=",part)
	
	local attachment=Instance.new("Attachment")
	local clone=rs:WaitForChild("StunUI"):Clone()
	attachment.Parent=workspace.Terrain
	attachment.WorldPosition=part.Position
	clone.Adornee=attachment
	clone.Parent=attachment
	
	stuns[#stuns+1]={
		timer=start,
		duration=duration,
		adornee=part,
		ui=clone,
		attachment=attachment
	}
	
	stunValue.Value=tick() -- trigger the stun loop below
end)

while true do
	while #stuns>0 do 
		for i,data in stuns do 
			
			if not data.adornee:IsDescendantOf(game) then
				data.attachment:Destroy()
				table.remove(stuns,i)
				continue
			end
			
			local goal=data.attachment:GetAttribute("Goal")
			if not goal then
				data.attachment:SetAttribute("Goal",data.attachment.WorldPosition)
				goal=data.attachment.WorldPosition
			end
			local d=(goal-data.adornee.Position).Magnitude
			if d>=1 then -- 1 stud or more change
				data.attachment:SetAttribute("Goal",data.adornee.Position)
				goal=data.adornee.Position
			end
			
			data.attachment.WorldPosition=data.attachment.WorldPosition:Lerp(goal,.1)
			
			local elapsed=workspace:GetServerTimeNow()-data.timer
			local p=math.clamp(elapsed/data.duration,0,1)
			local container=data.ui:WaitForChild("bg"):WaitForChild("container")
			container.Size=UDim2.new(1-p,0,1,0)
			local xSize=(1-p)*256
			for _,image in container:GetChildren() do 
				image.ImageRectOffset=Vector2.new(xSize-256,0)
			end
			if p==1 then
				data.attachment:Destroy()
				table.remove(stuns,i)
				continue
			end
		end
		
		--print("running stun loop")
		task.wait()
	end
	stunValue:GetPropertyChangedSignal("Value"):Wait()
end