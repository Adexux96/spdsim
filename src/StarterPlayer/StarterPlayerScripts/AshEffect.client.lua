local rs=game:GetService("ReplicatedStorage")
local AshEvent=rs:WaitForChild("AshEvent")
local ash=rs:WaitForChild("Particles"):WaitForChild("ash")

local models={}

local function AddModel(model)
	models[model]={}
	local index=models[model]
	index.parts={}
	
	local function Ash(part,amount)
		local clone=ash:Clone()
		clone.Parent=part 
		clone:Emit(amount)
	end
	
	if model:IsDescendantOf(workspace:WaitForChild("Villains")) then
		local body=model:FindFirstChild("Body")
		if not body then return end
		local amount=2
		amount=model:WaitForChild("isMesh").Value and 15 or 2
		for _,child in body:GetDescendants() do 
			if child:IsA("BasePart") and child.Transparency~=1 then
				index.parts[#index.parts+1]=child
				Ash(child,amount)
			end
		end
	else -- thugs and characters 
		for _,child in model:GetDescendants() do 
			if child:IsA("BasePart") and child.Transparency~=1 then
				index.parts[#index.parts+1]=child
				Ash(child,2)
			end
		end
	end
	
	index.start=tick()
	index.duration=.5
	
	local healthUI=model:FindFirstChild("Health")
	if healthUI then
		healthUI.Enabled=false
	end
	
end

AshEvent.OnClientEvent:Connect(AddModel)

local function clear(index)
	local values=models[index]
	for i,v in values do -- clear all values
		values[i]=nil
	end
	models[index]=nil -- clear the listing in models dict
end

while true do 
	local amount=0
	for index,values in models do 
		amount+=1
		if not values.start then clear(index) continue end
		local elapsed=tick()-values.start 
		local p=math.clamp(elapsed/values.duration,0,1)
		for _,part in values.parts do 
			part.Transparency=p*1
			if part.Name=="Head" then
				local face=part:FindFirstChildOfClass("Decal") 
				if face then
					face.Transparency=p*1
				end
				local spidey_sense=part.Parent:FindFirstChild("Spidey_Sense")
				if spidey_sense then spidey_sense:Destroy() end
			end
		end
		if p==1 then 
			clear(index)
		end
	end
	if amount==0 then -- there aren't any listings
		--print("there aren't any listings!")
		AshEvent.OnClientEvent:Wait()
	end
	--print("running ash effect!")
	-- give the model some time to get added into the models dict
	task.wait(1/30)
end