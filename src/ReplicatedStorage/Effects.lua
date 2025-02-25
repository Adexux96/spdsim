--!nocheck
local rs = game:GetService("ReplicatedStorage")
local ts=game:GetService("TweenService")
local clock = rs:WaitForChild("clock")

local _math=require(rs:WaitForChild("math"))

local effects = {}

local tweenInfo1 = TweenInfo.new(.1,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out,0,false,0)
local tweenInfo2 = TweenInfo.new(.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out,0,false,0)
function effects:TweenDots(dots:Frame)
	local size=math.round(dots.AbsoluteSize.X)
	local half=math.round(size/2)
	dots.Position=UDim2.new(0,half,0,half)
	ts:Create(dots,tweenInfo1,{Position=UDim2.new(0,0,0,0)}):Play()
end

function effects:TweenSkinsImage(image:ImageLabel,direction:string)
	local pos=direction=="left" and .9 or .1
	local opposite_pos=direction=="left" and .1 or .9
	local clone=image:Clone()
	clone.ZIndex=2
	clone.Parent=image.Parent
	image.ImageTransparency=1
	image.Position=UDim2.new(opposite_pos,0,.5,0)
	game:GetService("Debris"):AddItem(clone,1)
	ts:Create(image,tweenInfo2,{Position=UDim2.new(.48,0,.5,0)}):Play()
	ts:Create(image,tweenInfo2,{ImageTransparency=0}):Play()
	ts:Create(clone,tweenInfo2,{Position=UDim2.new(pos,0,.5,0)}):Play()
	ts:Create(clone,tweenInfo2,{ImageTransparency=1}):Play()
end

function effects:TweenNavButton(buttonBG:ImageLabel)
	local size=buttonBG.AbsoluteSize.X
	local goal=1.5
	local clone=buttonBG:Clone()
	clone:ClearAllChildren()
	clone.ZIndex=0
	clone.Position=UDim2.new(.5,0,.5,0)
	clone.AnchorPoint=Vector2.new(.5,.5)
	clone.Parent=buttonBG.Parent
	game:GetService("Debris"):AddItem(clone,1)
	ts:Create(clone,tweenInfo2,{Size=UDim2.new(goal,0,goal,0)}):Play()
	ts:Create(clone,tweenInfo2,{ImageTransparency=1}):Play()
end

function effects.MeleeEffect(pos)
	local punchImpact = rs:WaitForChild("punchImpact")
	local attachment = punchImpact:WaitForChild("Attachment"):Clone()
	attachment.Name = "punch"
	attachment.WorldPosition = pos 
	attachment.Parent = workspace.Terrain
	game:GetService("Debris"):AddItem(attachment,1)
	local sounds = {
		[1] = attachment.punch_01,
		[2] = attachment.punch_02,
		[3] = attachment.punch_03
	}
	sounds[math.random(1,3)]:Play()
	for i,v in pairs(attachment:GetChildren()) do 
		if v:IsA("ParticleEmitter") then
			v:Emit(1)
		end
	end
end

local function ray(origin,direction)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {
		workspace:WaitForChild("BuildingBounds"),
		workspace:WaitForChild("blocks"),
		workspace:WaitForChild("Concrete"),
		workspace:WaitForChild("Ground"),
		workspace:WaitForChild("cart_bounds"),
		workspace:WaitForChild("Traintracks")
	}
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)
	return raycastResult
end

function effects.LandedEffect(root)
	local origin = root.Position
	local goalCF = root.CFrame * CFrame.new(0,-100,0)
	local direction = (goalCF.Position - origin).Unit * 100
	local result = ray(origin,direction)

			--[[
			local rayVisual = rs:WaitForChild("rayVisual"):Clone()
			rayVisual.CFrame = CFrame.new(origin:Lerp(goalCF.Position,.5),goalCF.Position)
			rayVisual.Size = Vector3.new(0.25,0.25,(goalCF.Position - origin).Magnitude)
			rayVisual.Parent = workspace:WaitForChild("detectRay")
			game:GetService("Debris"):AddItem(rayVisual,1)
			]]

	if result then
		local aboveCF = CFrame.new(result.Position) * CFrame.new(0,1,0)
		local smashPart = rs:WaitForChild("GroundSmashPart"):Clone()
		smashPart.Size=Vector3.new(10,10,.2)
		smashPart.Texture.StudsPerTileU=10
		smashPart.Texture.StudsPerTileV=10
		local normalCF = CFrame.new(result.Position, result.Position + result.Normal) --* CFrame.new(0,0,0.5)
		smashPart.CFrame = normalCF
		smashPart.Parent = workspace
		smashPart.Attachment.Sound.PlaybackSpeed=2
		smashPart.Attachment.Sound.Volume=.2
		smashPart.Attachment.Sound:Play()
		for _,particle in pairs(smashPart.Attachment:GetChildren()) do 
			if particle:IsA("ParticleEmitter") then
				particle:Emit(3)
			end
		end
		--local camera = workspace.CurrentCamera
		--local distanceFromCamera = (camera.CFrame.Position - smashPart.Position).Magnitude
		--local percent = math.clamp(1-(math.clamp(distanceFromCamera - 15,0,100) / 100),0,1)
		--_G.camShake(1.5,percent)
		local camera=workspace.CurrentCamera
		local distanceFromCamera = (camera.CFrame.Position - root.Position).Magnitude
		local percent = math.clamp(1-(math.clamp(distanceFromCamera - 15,0,100) / 100),0,1)
		_G.camShake(1.5,percent)
		
		local start = tick()
		while true do
			local p = math.clamp(((tick() - start) - 1.5)/1,0,1)
			smashPart.Texture.Transparency = (p*.25)+.75
			if p == 1 then
				smashPart:Destroy()
				break
			end
			task.wait(1/30)
		end
	end
end

local cs=game:GetService("CollectionService")

function effects:AppearCash(position,basepart)
	if not basepart then return end
	local last=basepart:GetAttribute("LastAppearCash") or 0
	if not (tick()-last>=.5) then --[[print("cash appear was too soon!")]] return end
	basepart:SetAttribute("LastAppearCash",tick())
	if position==nil then return end
	local attachment = rs.moneyPart.Attachment:Clone()
	attachment.WorldPosition = position
	attachment.Name = "money"
	attachment.Parent = workspace.Terrain
	attachment.Sound:Play()
	attachment.Particle:Emit(math.random(1,2))
	game:GetService("Debris"):AddItem(attachment,5)
end

function effects:AppearComics(position,basepart)
	if not basepart then return end
	local last=basepart:GetAttribute("LastAppearComic") or 0
	if not (tick()-last>=.5) then --[[print("cash appear was too soon!")]] return end
	basepart:SetAttribute("LastAppearComic",tick())
	if position==nil then return end
	local attachment = rs.comicsPart.Attachment:Clone()
	attachment.WorldPosition = position
	attachment.Name = "comics"
	attachment.Parent = workspace.Terrain
	attachment.Sound:Play()
	attachment.Particle:Emit(math.random(1,2))
	game:GetService("Debris"):AddItem(attachment,5)
end

local function least(a,b)
	return a[1]<b[1]
end

function effects:DarkerRGB(color:Color3)
	local function toRGB(color)
		return math.round(color.R*255),math.round(color.G*255),math.round(color.B*255)
	end

	local function darkerRGB(r,g,b)
		--return math.round(r*.2),math.round(g*.2),math.round(b*.2)
		return math.round(r*.175),math.round(g*.175),math.round(b*.175)
	end

	local r,g,b = toRGB(color)
	return darkerRGB(r,g,b)
end

local priority={ 
	["cash"]=1,
	["combo"]=2,
	["countdown"]=3,
	["killstreak"]=4,
	["multikill"]=5,
}

function effects:GetElapsed(timer,duration)
	local elapsed=tick()-timer.Value
	return elapsed<=duration/2, elapsed
end

function effects:GetHighestEligiblePriority(name:string, pos:Vector3)
	local closest=math.huge
	local highest={priority[name],name}
	for _,attachment in workspace.Terrain:GetChildren() do 
		if not attachment:IsA("Attachment") then continue end
		if attachment.Name~=name then
			local n=priority[attachment.Name]
			if n==nil then continue end --// wasn't in the priority profile
			if n>highest[1] then
				highest={n,attachment.Name}
			end
			local distance=(pos-attachment.WorldPosition).Magnitude
			if distance<closest then
				closest=distance
			end
		end
	end
	return highest[2],closest
end

function effects:RemoveLowerPriorityFlyoffs(name:string)
	local ignore={["cash"]=true,["countdown"]=true}-- ignore cash for now till you figure out what to do with em
	local highest=priority[name]
	if highest==nil then return end
	for _,attachment in workspace.Terrain:GetChildren() do 
		if not attachment:IsA("Attachment") then continue end
		if attachment.Name~=name and not ignore[attachment.Name] then
			local n=priority[attachment.Name]
			if n==nil then continue end --// wasn't in the priority profile 
			if n<highest then
				--print("destroyed",attachment.Name)
				attachment:Destroy()
			end
		end
	end
end

function effects:AttemptFlyoffMerge(name:string, pos:Vector3, total:number)
	local eligible={}
	--print("name=",name)
	local highest,closest=effects:GetHighestEligiblePriority(name,pos)
	local canCreate
	if name=="cash" then
		canCreate=true
	else 
		canCreate=highest==name
	end
	effects:RemoveLowerPriorityFlyoffs(name)
	--print("made it here1")
	for _,attachment in workspace.Terrain:GetChildren() do
		if not attachment:IsA("Attachment") then continue end
		if attachment.Name==name then
			local canOverwrite,elapsed=self:GetElapsed(attachment.tick,(1/60)*total)
			if canOverwrite then
				eligible[#eligible+1]={elapsed,attachment}
			end
		end
	end

	table.sort(eligible,least)
	local attachment=eligible[1]~=nil and eligible[1][2] or nil
	return attachment,canCreate,closest
end

function effects:Flyoff(attachment:Attachment, size:UDim2, pos:Vector3, offset:Vector3, timer:{})
	--print("flyoff for",attachment.Name)
	local text=attachment:WaitForChild("ui"):WaitForChild("bg"):WaitForChild("text")
	text:TweenSize(
		size,
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Linear,
		.1,
		false
	)
	local UIStroke=text:WaitForChild("UIStroke")

	for i = 1,timer.total do
		--print("size=",text.AbsoluteSize)
		if not attachment then break end -- doesn't exist anymore
		attachment.WorldPosition = pos + (offset * (i/timer.total))
		local p = math.clamp((i/timer.total)-.5,0,.5)/.5
		text.TextTransparency = p
		UIStroke.Transparency = math.clamp(p-.25,.25,.75)/.75
		if i <= timer.up then -- size bg thickness up
			UIStroke.Thickness = math.clamp(i/timer.up,0,1) * 3
		elseif i >= timer.down then -- size bg thickness down
			UIStroke.Thickness = math.clamp(1-((i-timer.down)/10),0,1) * 3
		end
		clock:GetPropertyChangedSignal("Value"):Wait()
	end
	
	--print(text.Size, text.Font)
	
	if attachment then
		attachment:Destroy()		
	end

end

local shakeTweenInfo = TweenInfo.new(.05,Enum.EasingStyle.Elastic,Enum.EasingDirection.InOut,1,true,0)
local blueTweenInfo=TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)

function effects:PrepareFlyoff(category:string, t:{}, ignoreEligible:boolean)
	--print("prepare flyoff")
	--print("preparing flyoff for",category)
	local found,canCreate,closest
	if ignoreEligible then
		found,canCreate,closest=false,true,0
	else 
		found,canCreate,closest=self:AttemptFlyoffMerge(category, t.pos, t.timer.total)
	end
	if not canCreate then 
		if closest<4 then
			--print("was too close to the last!")
			return
		else 
			--print("created a new flyoff cause was far away enough!")
			found=nil
		end
	end

	if found then
		local text=found.ui.bg.text
		if category=="cash" then
			local oldDifference=found.difference.Value
			local newDifference=t.difference+oldDifference
			found.difference.Value=newDifference
			--print("oldDifference=",oldDifference)
			--print("newDifference=",t.difference)
			local _negative=newDifference<0
			local _color = _negative and Color3.fromRGB(255, 98, 84) or Color3.fromRGB(164, 193, 76)
			text.TextColor3=_color
			text.Text="$"..math.abs(newDifference)
			--print("changed cash flyoff text!")
		elseif category=="comic" then
			text.Text=t.s
			--text.FontFace=t.font
			text.FontFace.Style=Enum.FontStyle.Italic
			text.TextColor3=t.color
		elseif category=="damage" then
			local current=tonumber(text.Text)
			local new=tostring(t.s+current)
			text.Text=new 
			--print("changed damage flyoff text!")
		elseif category=="combo" or category=="multikill" or category=="killstreak" then
			text.Text=t.s
			local x=math.round(text.TextBounds.X*.1)
			x=_math.negOrPos(x)
			local y=-math.round(text.TextBounds.Y*.1)
			y=_math.negOrPos(y)
			local blue=text:Clone()
			blue:ClearAllChildren()
			blue.TextStrokeTransparency=1
			blue.TextTransparency=0
			blue.TextColor3=Color3.fromRGB(0,255,255)
			blue.ZIndex=2
			blue.Parent=text.Parent
			--print(blue.Parent)
			ts:Create(blue,blueTweenInfo,{TextTransparency=1}):Play()
			ts:Create(blue,blueTweenInfo,{Position=UDim2.new(.5,x,.5,y)}):Play()
			ts:Create(text,shakeTweenInfo,{Position=UDim2.new(.5,x,.5,y)}):Play()
			--print("changed "..category.." flyoff text!")
		end
		return
	end

	local markerName=(category=="cash" or category=="comic") and "moneyMarker" or "hitMarker"
	local marker=rs:FindFirstChild(markerName)
	local attachment=marker:WaitForChild("Attachment"):Clone()
	attachment.tick.Value=tick()
	attachment.difference.Value=t.difference
	attachment.Name=category
	attachment.WorldPosition=t.pos
	attachment.Parent=workspace.Terrain

	local ui = attachment:WaitForChild("ui")
	ui.Adornee = attachment
	local text = ui:WaitForChild("bg"):WaitForChild("text")
	text.Font=t.font
	text.FontFace.Style=Enum.FontStyle.Italic
	text.TextColor3 = t.color
	text.Text = t.s

	--print("text=",t.s)

	local r,g,b = effects:DarkerRGB(text.TextColor3)
	text.UIStroke.Color = Color3.fromRGB(r,g,b)

	effects:Flyoff(attachment,t.size,t.pos,t.offset,t.timer)
end

function effects:Countdown(t:{})
	local text=t.attachment:WaitForChild("ui"):WaitForChild("bg"):WaitForChild("text")
	text.Size=t.size -- make it the size immediately
	text.Font=t.font
	text.Text=t.s
	local r,g,b = effects:DarkerRGB(text.TextColor3)
	text.UIStroke.Color = Color3.fromRGB(r,g,b)
	task.wait() -- wait for textbounds to update 
	local x=math.round(text.TextBounds.X*.1)
	x=_math.negOrPos(x)
	local y=-math.round(text.TextBounds.Y*.1)
	y=_math.negOrPos(y)
	local blue=text:Clone()
	blue:ClearAllChildren()
	blue.TextStrokeTransparency=1
	blue.TextTransparency=0
	blue.TextColor3=Color3.fromRGB(0,255,255)
	blue.ZIndex=2
	blue.Parent=text.Parent
	--print(blue.Parent)
	ts:Create(blue,blueTweenInfo,{TextTransparency=1}):Play()
	ts:Create(blue,blueTweenInfo,{Position=UDim2.new(.5,x,.5,y)}):Play()
	ts:Create(text,shakeTweenInfo,{Position=UDim2.new(.5,x,.5,y)}):Play()
	
	for i = 1,t.timer.total do
		if not t.attachment then break end -- doesn't exist anymore
		t.attachment.WorldPosition = t.pos --+ t.offset--(t.offset * (i/t.timer.total))
		local p = math.clamp((i/t.timer.total)-.5,0,.5)/.5
		text.TextTransparency = p
		text.UIStroke.Transparency = math.clamp(p-.25,.25,.75)/.75
		if i <= t.timer.up then -- size bg thickness up
			text.UIStroke.Thickness = math.clamp(i/t.timer.up,0,1) * 5
		elseif i >= t.timer.down then -- size bg thickness down
			text.UIStroke.Thickness = math.clamp(1-((i-t.timer.down)/10),0,1) * 5
		end
		clock:GetPropertyChangedSignal("Value"):Wait()
	end
	
	if t.attachment then
		t.attachment:Destroy()
	end
	
end

function effects:HealEffect(player)
	local BasePart=player.Character.PrimaryPart
	if not BasePart then return end
	local last=BasePart:GetAttribute("LastAppearHealth") or 0
	if not (tick()-last>=.5) then --[[print("health effect was too soon!")]] return end
	BasePart:SetAttribute("LastAppearHealth",tick())
	local clone = rs.HealEffect.Attachment:Clone()
	clone.WorldPosition = BasePart.Position
	clone.Name = "healthget"
	clone.Parent = workspace.Terrain
	game:GetService("Debris"):AddItem(clone,3)
	clone.Sound:Play()
	for i,v in clone:GetChildren() do 
		if v:IsA("ParticleEmitter") then 
			local amount = v.Name == "Icon" and 3 or 1
			v:Emit(amount)
		end
	end	
end

return effects
