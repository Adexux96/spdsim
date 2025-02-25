--!nocheck
local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local meleeEvent = rs:WaitForChild("MeleeEvent")
local cashEvent=rs:WaitForChild("CashEvent")
local healEvent=rs:WaitForChild("HealEvent")
local effects = require(rs:WaitForChild("Effects"))
local _math=require(rs:WaitForChild("math"))

local landedEvent=rs:WaitForChild("LandedEvent")

local leaderstats=player:WaitForChild("leaderstats")
local temp=leaderstats:WaitForChild("temp")
local RagdollRecovery=temp:WaitForChild("RagdollRecovery")
--local combos=temp:WaitForChild("combos")
local multikills=temp:WaitForChild("multikills")
--local killstreak=leaderstats:WaitForChild("Killstreak")

meleeEvent.OnClientEvent:Connect(function(action,model)
	if action == "Melee" then
		local head=model:FindFirstChild("Head")
		if not model or not head then return end
		effects.MeleeEffect(model:WaitForChild("Head").Position)
	end
end)

local prevCashAmount=player:WaitForChild("leaderstats"):WaitForChild("Cash").Value
local difference=0
local cash=leaderstats:WaitForChild("Cash")
local function flyoffCash()
	--print("flyoff cash")
	--print("difference=",difference)
	--prevCashAmount = cash.Value -- update the prevCashValue
	if not player.Character or not player.Character.PrimaryPart then return end
	local pos = player.Character.PrimaryPart.Position
	effects:AppearCash(pos,player.Character.PrimaryPart)
	local s = "$"..math.abs(difference)
	local timer={total=80,up=20,down=60}
	local offset=Vector3.new(0,2,0)
	local color=difference<0 and Color3.fromRGB(255, 98, 84) or Color3.fromRGB(164, 193, 76)
	local t={
		s=s,
		difference=difference,
		size=UDim2.new(2,10,.5,10),
		color=color,
		font=Enum.Font.LuckiestGuy,
		pos=pos,
		offset=offset,
		timer=timer
	}
	--s, size, timer, offset, pos, color, font, difference, name
	 effects:PrepareFlyoff("cash",t)
end

cash:GetPropertyChangedSignal("Value"):Connect(function()
	difference=cash.Value-prevCashAmount
	prevCashAmount=cash.Value
	flyoffCash()
end)

local function CashEffect(plr)
	--print("cash event!")
	if not plr or plr==player then return end
	if not plr.Character or not plr.Character.PrimaryPart then return end
	local pos = plr.Character.PrimaryPart.Position
	effects:AppearCash(pos,plr.Character.PrimaryPart)
end

cashEvent.OnClientEvent:Connect(CashEffect)

local function ComicEffect(plr)
	if not plr or plr==player then return end
	if plr.Character or not plr.Character.PrimaryPart then return end
	local pos = plr.Character.PrimaryPart.Position
	effects:AppearComics(pos,plr.Character.PrimaryPart)
end

rs:WaitForChild("ComicEvent").OnClientEvent:Connect(ComicEffect)
local comics=leaderstats:WaitForChild("Comic pages")
local prevComicsAmount=player:WaitForChild("leaderstats"):WaitForChild("Comic pages").Value
local comic_difference=0

local function flyoffComic()
	if not player.Character or not player.Character.PrimaryPart then return end
	local pos = player.Character.PrimaryPart.Position
	effects:AppearComics(pos,player.Character.PrimaryPart)
	local s = comic_difference>0 and "+"..math.abs(comic_difference) or "-"..math.abs(comic_difference)
	local timer={total=80,up=20,down=60}
	local offset=Vector3.new(0,2,0)
	local color=comic_difference<0 and Color3.fromRGB(255, 98, 84) or Color3.fromRGB(255,255,255)
	local t={
		s=s,
		difference=comic_difference,
		size=UDim2.new(2,10,.5,10),
		color=color,
		font=Enum.Font.LuckiestGuy,
		pos=pos,
		offset=offset,
		timer=timer
	}
	--s, size, timer, offset, pos, color, font, difference, name
	effects:PrepareFlyoff("comic",t)
end

comics:GetPropertyChangedSignal("Value"):Connect(function()
	comic_difference=comics.Value-prevComicsAmount
	prevComicsAmount=comics.Value
	flyoffComic()
end)

local function UniversalEffect(_type,s,font,color,size,timer,offset)
	if not player.Character or not player.Character.PrimaryPart then return end
	local pos=player.Character.PrimaryPart.Position-Vector3.new(0,.5,0)
	local offset=offset or Vector3.new(0,0,0)
	local timer=timer or {total=80,up=20,down=60}
	local size=size or UDim2.new(2,10,.35,10)
	local color=color or Color3.fromRGB(255,255,255)
	local font=font or Enum.Font.LuckiestGuy
	local t={
		s=s,
		difference=0,
		size=size,
		color=color,
		font=font,
		pos=pos,
		offset=offset,
		timer=timer,
		--strokeColor=Color3.fromRGB(25,25,25)
	}
	effects:PrepareFlyoff(_type,t)
end

local multikills_texts={
	[0]="",
	[1]="double-kill!",
	[2]="triple-kill!",
	[3]="ultra-kill!",
}

local function MultikillEffect()
	if multikills.Value>0 then
		local s=multikills.Value<4 and multikills_texts[multikills.Value] or "rampage!"
		UniversalEffect("multikill",s,Enum.Font.Bangers,nil--[[Color3.fromRGB(239, 205, 48)]],UDim2.new(2,10,.35,10))
	end
end

local function CountdownEffect()
	if not player.Character or not player.Character.PrimaryPart then return end
	local pos=player.Character.PrimaryPart.Position
	if not (RagdollRecovery.Value>0) then return end
	local s=tostring(RagdollRecovery.Value)--..(RagdollRecovery.Value>1 and " seconds" or " second")
	local timer={total=40,up=10,down=30}
	local marker=rs:FindFirstChild("hitMarker")
	local attachment=marker:WaitForChild("Attachment"):Clone()
	attachment.tick.Value=tick()
	attachment.difference.Value=0
	attachment.Name="countdown"
	attachment.WorldPosition=pos
	attachment.Parent=workspace.Terrain
	
	effects:Countdown({
		size=UDim2.new(2,10,.5,10),
		s=s,
		timer=timer,
		pos=pos,
		attachment=attachment,
		font=Enum.Font.Bangers,
		offset=Vector3.new(0,2,0)
	})
	--UniversalEffect("countdown",s,Enum.Font.Bangers,nil,UDim2.new(2,10,.6,10),timer,Vector3.new(0,2,0))
end

local function HealEffect(plr) -- healing particles and sound for players
	effects:HealEffect(plr)
end

healEvent.OnClientEvent:Connect(HealEffect)

local function landed(plr,timer,camShake) -- plr is the landed player, timer is workspace:GetServerTimeNow from the server
	if not plr or not plr.Character or not plr.Character.PrimaryPart then print("didn't 1") return end
	local last_landed=plr:GetAttribute("LastLanded")
	if not last_landed then
		plr:SetAttribute("LastLanded",workspace:GetServerTimeNow()-3) -- 3 seconds behind to ensure first landed effect runs
		last_landed=plr:GetAttribute("LastLanded")	
	end
	local elapsed=timer-last_landed
	if elapsed<1.5 then print("didn't 2") return end
	plr:SetAttribute("LastLanded",workspace:GetServerTimeNow()) -- update the LastLanded
	if camShake then
		local camera=workspace.CurrentCamera
		local distanceFromCamera = (camera.CFrame.Position - plr.Character.PrimaryPart.Position).Magnitude
		local percent = math.clamp(1-(math.clamp(distanceFromCamera - 15,0,100) / 100),0,1)
		_G.camShake(1.5,percent)
	end
	effects.LandedEffect(plr.Character.PrimaryPart)
end

landedEvent.OnClientEvent:Connect(landed)

--combos:GetPropertyChangedSignal("Value"):Connect(ComboEffect)
multikills:GetPropertyChangedSignal("Value"):Connect(MultikillEffect)
--killstreak:GetPropertyChangedSignal("Value"):Connect(KillstreakEffect)
RagdollRecovery:GetPropertyChangedSignal("Value"):Connect(CountdownEffect)