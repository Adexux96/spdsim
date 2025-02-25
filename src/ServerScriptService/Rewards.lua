--!nocheck

local rs=game:GetService("ReplicatedStorage")
local cashEvent=rs:WaitForChild("CashEvent")
local healEvent=rs:WaitForChild("HealEvent")
local AnalyticsService = game:GetService("AnalyticsService")

local module = {}

module.contents={} -- 3d object, assigned

function module:RewardPlayer(player,category,amount)
	if category=="Money" then
		local cash = player.leaderstats.Cash
		local rebirth = math.round( (player.leaderstats.Rebirths.Value/10) * amount)
		local amount=(amount+rebirth) * (player.leaderstats.CashBoost.active.Value and 2 or 1) --[[*(player.leaderstats.Subs["+50Cash"].Value and 1.5 or 1)]]
		cash.Value+=amount
		--cashEvent:FireAllClients(player) commented out cause already tells clients elsewhere
		
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Cash",
			amount,
			cash.Value,
			Enum.AnalyticsEconomyTransactionType.Gameplay.Name
		)
	end
	if category=="Health" then
		if player.Character then
			player.Character.Humanoid.Health+=amount
			healEvent:FireAllClients(player)
		end
	end
	if category=="Comic" then
		local comics=player.leaderstats["Comic pages"]
		local amount = amount * (player.leaderstats.ComicPagesBoost.active.Value and 2 or 1)
		comics.Value+=amount

		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Comic Pages",
			amount,
			comics.Value,
			Enum.AnalyticsEconomyTransactionType.Gameplay.Name
		)
	end
end

function module:DeleteDrop(index)
	local drop=self.contents[index].drop
	table.remove(self.contents,index)
	drop:Destroy()
	--[[
	task.delay(1,function()
		drop:Destroy()
	end)
	]]
end

function module:Assign_Closest_Recipients(index)
	local d=100
	local plr=nil
	local data=self.contents[index]
	local function find_closest_player(position)
		for _,player in game.Players:GetPlayers() do 
			if not player.Character or player.Character.Parent~=workspace then continue end
			if player.Name==data.ignore then continue end
			local leaderstats=player.leaderstats
			local range=leaderstats.gamepasses.Collector.Value and 100 or 10
			local distance=(player.Character.PrimaryPart.Position-position).Magnitude
			local withinRange=distance<=range 
			if not withinRange then continue end
			if not (player.Character.Humanoid.Health>0) then continue end
			d=distance<d and distance or d 
			plr=d==distance and player or plr -- only change player if distance was changed
		end
		return plr,d
	end
	if data.assigned and data.assigned:IsDescendantOf(game.Players) then
		local plr=data.assigned
		local range=plr.leaderstats.gamepasses.Collector.Value and 100 or 10
		local character=plr.Character
		--//local not_within_range=not ((character.PrimaryPart.Position-data.drop.projectedPosition.Value).Magnitude<=range)
		if not character then
			-- don't remove the drop yet, wait until it finds another person or expires
			self.contents[index].assigned=nil
			self.contents[index].drop.assigned.Value=nil
			self.contents[index].drop.moveTimer.Value=0
			self.contents[index].drop.distance.Value=0
		else -- character still exists, check if the drop should've made it to the character by now 
			local move_dt=workspace:GetServerTimeNow()-self.contents[index].drop.moveTimer.Value
			local distance=self.contents[index].drop.distance.Value
			local t=math.clamp(distance/100,0,1)
			local progress=math.clamp(move_dt/t,0,1)
			progress=game:GetService("TweenService"):GetValue(progress,Enum.EasingStyle.Cubic,Enum.EasingDirection.In)
			self.contents[index].drop.projectedPosition.Value=data.drop.projectedPosition.Value:Lerp(character.PrimaryPart.Position,progress) -- update projectedPosition
			if progress==1 then -- made it to the plr, reward
				self:RewardPlayer(data.assigned,data.category,data.amount)
				self:DeleteDrop(index)
				return
			end
		end
	else
		local plr,distance=find_closest_player(self.contents[index].drop.projectedPosition.Value)
		if plr and plr.Character then
			self.contents[index].assigned=plr
			self.contents[index].drop.assigned.Value=plr.Character
			self.contents[index].drop.moveTimer.Value=workspace:GetServerTimeNow()
			self.contents[index].drop.distance.Value=distance
		end
	end
	if workspace:GetServerTimeNow()-data.drop.timer.Value >= 10 then
		self:DeleteDrop(index)
		return
	end
end

function module:Add_Reward(rewardInfo:{})
	self.contents[#self.contents+1]={
		drop=rewardInfo.drop,
		category=rewardInfo.category,
		amount=rewardInfo.amount,
		assigned=nil,
		ignore=rewardInfo.ignore
	}	
end

function module:CreateDrop(pos, maxHealth, ignoreName, fixedType, isGauntlet)
	--print("ignoreName=",ignoreName)
	local random = math.random(0,100)
	local dropType = isGauntlet and "Money" or (random <= 50 and "Money" or "Health")
	dropType=fixedType or dropType
	local amount = dropType=="Money" and math.round(maxHealth*.2) or math.round(maxHealth*.4)
	local clone = rs.drops[dropType]:Clone()
	clone.timer.Value = workspace:GetServerTimeNow()
	clone:SetPrimaryPartCFrame(CFrame.new(pos))
	clone.origin.Value=clone.PrimaryPart.CFrame
	clone.projectedPosition.Value=clone.PrimaryPart.Position
	clone.Parent = workspace.Drops
	--debris:AddItem(clone,10)
	task.spawn(function()
		wait(.5)
		self:Add_Reward({drop=clone,category=dropType,amount=amount,ignore=ignoreName})
	end)
end

return module
