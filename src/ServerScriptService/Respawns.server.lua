local rewards=require(script.Parent.Rewards)
local rs=game:GetService("ReplicatedStorage")
local cs=game:GetService("CollectionService")

local NPCs = require(script.Parent.NPCs)

local ragdoll= require(rs.ragdoll)

local diedEvent=rs.DiedEvent

local function Reward_Player_Attackers(player,baseCash)
	local attackers = player.leaderstats.attackers
	--print("reward player")
	for i,v in (attackers:GetChildren()) do
		local plr = game.Players:FindFirstChild(v.Name)
		--print("player=",player.Name)
		if plr then
			local totalDamage=attackers:GetAttribute("totalDamage")
			totalDamage=totalDamage or 0
			--print("totalDamage=",totalDamage)
			--print("damage=",v.damage)
			--print("baseCash=",baseCash)
			local damage=math.clamp(v.damage.Value,0,totalDamage)
			if damage==0 then continue end -- don't reward if damage is 0
			local reward=math.round(math.clamp(damage/totalDamage,0,1) * baseCash)
			rewards:RewardPlayer(plr,"Money",reward)
		end
	end
	attackers:ClearAllChildren()
	local attacking = player.leaderstats.attacking
	attacking:ClearAllChildren()
	attackers:SetAttribute("totalDamage",0)
end

local function Find_Halfway_Web(parent)
	for i,v in (parent:GetChildren()) do 
		if v.Value == "halfway" then
			return v
		end
	end	
	return nil
end

local function Remove_Halfway_TripWebs(plr:Player, serverAmount:NumberValue)
	local halfway = Find_Halfway_Web(serverAmount)
	if halfway then -- removes the player's halfway trip webs
		for _,playerInstance in (game.Players:GetChildren()) do
			local actionRemote=playerInstance:FindFirstChild("actionRemote")
			if plr ~= playerInstance and actionRemote then
				actionRemote:FireClient(
					playerInstance,
					"trip remove",
					plr.Name, -- plr name
					"last", -- action
					halfway.Name -- tag
				)
			end
		end
		halfway:Destroy()
		if serverAmount.Value > 0 then
			serverAmount.Value -= 1
		end
		--print("server removed halfway trip web when died: ",halfway.Name)
	end
end

local function Reward_Drone_Attackers(plr:Player)
	local drone = workspace.SpiderDrones:FindFirstChild(plr.Name)
	if drone then
		local health = drone.Properties.Health
		if not (health.Value > 0) then return end -- make sure it's still alive to reward its attackers before it gets deleted
		local maxHealth = drone.Properties.MaxHealth
		local tag = drone.Properties.Tag.Value
		local listing = NPCs[tag]
		if not listing then return end
		local cashAdd = math.round(25*(maxHealth.Value/100))
		for i,v in (listing.attackers) do 
			local plr = v.plr
			if not plr:IsDescendantOf(game.Players) then continue end -- make sure the player that attacked is still playing the game
			local cash = plr.leaderstats.Cash
			local rebirths = plr.leaderstats.Rebirths
			local newCash = math.round(math.clamp(v.damage/maxHealth.Value,0,1) * cashAdd)
			local extraCash = math.round((rebirths.Value/10) * newCash)
			cash.Value += (newCash + extraCash)
		end
		NPCs[tag].clear(NPCs[tag])
		NPCs[tag] = nil
		if drone:IsDescendantOf(workspace) then
			drone:Destroy()
		end
	end
end

local function Respawn_Player(player)
	if player:IsDescendantOf(game.Players) then -- player still exists
		--player:LoadCharacter()
		local skin=_G.getEquippedSkin(player)
		--print(skin)
		if not skin then
			player:LoadCharacter()
			return
		end
		local spawn_point=workspace.spawn2.CFrame*CFrame.new(0,4,0)
		_G.putOnSkin(player,skin,spawn_point)
	end
end

local function Died(plr,timer)
	if not plr:GetAttribute("spawned") then return end -- don't prematurely count a death
	--print("died server")
	local character=plr.Character
	if cs:HasTag(character,"DeathProcessed") then return end -- don't allow multiple respawn attempts
	cs:AddTag(character,"DeathProcessed")
	--print("server got that you died")
	local elapsed=workspace:GetServerTimeNow()-timer
	task.delay(3-elapsed,Respawn_Player,plr)

	local humanoid=character.Humanoid

	local leaderstats=plr.leaderstats
	local temp=leaderstats.temp

	--leaderstats.Killstreak.Value=0 -- reset your killstreak when you die

	--leaderstats.attacking:ClearAllChildren()
	--leaderstats.attackers:ClearAllChildren()

	local sound = character.PrimaryPart:FindFirstChild("ded")
	if sound then
		sound:Play()
	end

	temp:WaitForChild("previousHealth").Value = "" -- reset the health so when you respawn it doesn't apply old health
	temp:WaitForChild("isWebbing").Value = false -- turn it off so if other clients are replicating the travel web, this shuts it off

	Remove_Halfway_TripWebs(plr,temp.tripWebs.serverAmount) -- remove halfway web for other clients
	Reward_Player_Attackers(plr,math.round(50*(humanoid.MaxHealth/100)))
	Reward_Drone_Attackers(plr)

	ragdoll.ragdoll(plr,character,0,nil,false,true)
end

diedEvent.OnServerEvent:Connect(Died)