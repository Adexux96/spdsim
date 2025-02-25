local teleports=workspace:WaitForChild("Teleports")
local player=game.Players.LocalPlayer
local cs=game:GetService("CollectionService")
local rs=game:GetService("ReplicatedStorage")

local _math=require(rs:WaitForChild("math"))
local items=require(rs:WaitForChild("items"))

local remote=rs:WaitForChild("TeleportEvent")

local function Effect(circle)
	if not circle or cs:HasTag(circle,"Teleporting") then return end
	local sound=circle:FindFirstChild("Sound")
	local particle=circle:FindFirstChild("Particle")
	if not sound or not particle then return end
	cs:AddTag(circle,"Teleporting")
	sound:Play()
	for i=1,10 do 
		particle:Emit(1)
		task.wait(.1)
	end
	cs:RemoveTag(circle,"Teleporting")
end

remote.OnClientEvent:Connect(function(action,teleport)
	local character=player.Character
	if not character or not character.PrimaryPart then return end
	if cs:HasTag(character,"ragdolled") then return end -- don't allow character to teleport ragdolled!
	local circle=teleport:WaitForChild("circle")
	local connecting=teleport:WaitForChild("Connecting")

	if action=="Effect" then
		for _,circle in {circle,connecting.Value} do 
			local f=coroutine.wrap(Effect)
			f(circle)
		end
	elseif action=="Teleport" then
		character:SetPrimaryPartCFrame(connecting.Value.CFrame+Vector3.new(0,1,0))		
	end

end)

local function TurnOffLock(teleport)
	local unlocked=teleport:FindFirstChild("Unlocked")
	local lock=teleport:FindFirstChild("Lock")
	if not unlocked or not lock then return end
	lock.Transparency=1 -- will be destroyed when picked up by the drop handler
end

local zone=rs:WaitForChild("SafeZone")
local camera=workspace.CurrentCamera

local leaderstats=player:WaitForChild("leaderstats")
local portals=leaderstats:WaitForChild("portals")

local hotbarUI=player:WaitForChild("PlayerGui"):WaitForChild("hotbarUI")
local hotbarUI_container=hotbarUI:WaitForChild("container")

local animations=rs:WaitForChild("animations")
local animFolder=animations:WaitForChild("Folder")
local fight_idle=animFolder:WaitForChild("fight_idle")
local cop_idle=animFolder:WaitForChild("cop")

local function animateThug(model,speed,idle)
	local animation=animFolder:FindFirstChild(model.Name)
	if animation then
		local anim=model.Humanoid:LoadAnimation(animation)
		anim.Priority=Enum.AnimationPriority.Idle
		anim:Play()
		anim:AdjustSpeed(0)
	end
	local idleAnim=model.Humanoid:LoadAnimation(idle or fight_idle)
	idleAnim.Priority=Enum.AnimationPriority.Core
	idleAnim:Play()
	--task.wait(1/30)
	idleAnim:AdjustSpeed(speed or 0)
	cs:AddTag(model,"AnimationsLoaded")
end

local ignoreNames = {
	["RightBaton"] = true,
	["LeftBaton"] = true,
	["LeftGlove"] = true,
	["RightGlove"] = true,
	["Box"] = true
}

local function setCollisionsThug(thug)
	local bodyParts={
		["RightHand"]=true,
		["LeftHand"]=true,
		["Head"]=true,
		["UpperTorso"]=true,
		["LowerTorso"]=true,
		["RightUpperArm"]=true,
		["LeftUpperArm"]=true,
		["RightLowerArm"]=true,
		["LeftLowerArm"]=true,
		["RightUpperLeg"]=true,
		["RightLowerLeg"]=true,
		["LeftUpperLeg"]=true,
		["LeftLowerLeg"]=true,
		["LeftFoot"]=true,
		["RightFoot"]=true
	}
	local amount=0
	for index,part in pairs(thug:GetDescendants()) do 
		if part:IsA("BasePart") then
			if ignoreNames[part.Name] or part.Parent:IsA("Tool") then
				part.CollisionGroup="Ghost"
			else 
				if part.Name == "Sphere" then
					part.CollisionGroup="Spheres"
				else 
					part.CollisionGroup="Thugs"
				end
			end
			if bodyParts[part.Name] then
				amount+=1
			end
		end
	end
	if amount==15 then
		cs:AddTag(thug,"CollisionsLoaded")
	end
end

while true do 
	local Is_In_Bounds=_math.checkBounds(zone.CFrame,zone.Size,camera.CFrame.Position)
	for _,teleport in teleports:GetChildren() do 

		local circle=teleport:FindFirstChild("circle")
		if not circle then continue end

		local proximityPrompt=circle:FindFirstChild("ProximityPrompt")
		if not proximityPrompt then continue end

		local unlocked=teleport:FindFirstChild("Unlocked")
		if not unlocked then return end

		local page=teleport:FindFirstChild("Page")
		--local gui=page and page:FindFirstChild("BillboardGui") or nil
		--if page and not gui then continue end

		local portalValue=portals[teleport.Name]
		if not portalValue then continue end

		unlocked.Value=portalValue.Value
		if unlocked.Value then
			TurnOffLock(teleport)
		end

		proximityPrompt.ActionText="Teleport"--unlocked.Value and "Teleport" or "Purchase"
		proximityPrompt.ObjectText=""
		--proximityPrompt.ObjectText=unlocked.Value and "" or _math.giveNumberCommas(tostring(items.Portals[teleport.Name])).." Cash"
		--if gui then
		--gui.Enabled=Is_In_Bounds
		--local slot_size=hotbarUI_container.AbsoluteSize.X
		--gui.Size=UDim2.new(0,4*slot_size,0,4*slot_size)
		--local image=gui:FindFirstChild("ImageLabel")
		--image.Size=UDim2.new(0,4*slot_size,0,4*slot_size)
		--end

		local model=teleport:FindFirstChildOfClass("Model")
		if model and model:FindFirstChild("Humanoid") then
			if not cs:HasTag(model,"AnimationsLoaded") then
				animateThug(model)
			end
			if not cs:HasTag(model,"CollisionsLoaded") then
				setCollisionsThug(model)
			end
		end

		local cop=workspace:FindFirstChild("Cop")
		if cop and cop.PrimaryPart and not cs:HasTag(cop,"AnimationsLoaded") then
			animateThug(cop,.1,cop_idle)
		end
	end

	task.wait(1/2)
end

--[[
client needs to know when to change the prompt from unlock to teleport
	it can't be a remote event? check if things load/unload first
	things do unload and load, it doesn't matter when a remote is fired, if it doesn't exist, it can't tell.
server needs to handle the prompt activation cause it's not always loaded for the client
]]

