local rs=game:GetService("ReplicatedStorage")
local m=require(rs.math)
local items=require(rs.items)
local EarningPotential = {}

EarningPotential.Ratings={
	["Punch"]={stun=false,cooldown=.25,combos=true,damage=true,AOE=false,misc=1},
	["Kick"]={stun=false,cooldown=.5,combos=true,damage=true,AOE=false,misc=1},
	["360 Kick"]={stun=false,cooldown=.75,combos=true,damage=true,AOE=2,misc=1},
	["Impact Web"]={stun=false,cooldown=.25,combos=true,damage=true,AOE=false,misc=1},
	["Shotgun Webs"]={stun=false,cooldown=.5,combos=true,damage=true,AOE=false,misc=1,multi=3},
	["Snare Web"]={stun=true,cooldown=15,combos=false,damage=false,AOE=false,misc=2},
	["Trip Web"]={stun=3,cooldown=3,combos=false,damage=false,AOE=false,misc=false},
	["Anti Gravity"]={stun=8,cooldown=15,combos=false,damage=false,AOE=false,misc=false},
	["Web Bomb"]={stun=false,cooldown=10,combos=false,damage=true,AOE=4,misc=1},
	["Spider Drone"]={stun=false,cooldown=2,combos=false,damage=true,AOE=false,misc=2},
	["Gauntlet"]={stun=false,cooldown=10,combos=false,damage=true,AOE=4,misc=2},
}

function EarningPotential.CalculateComboDamage(amount,base_damage)
	amount=math.round(amount*10)/10
	--print("amount=",amount)
	local combo_damage=0
	for i=.1,amount,.1 do
		combo_damage+=base_damage*i
	end
	--print(combo_damage)
	return combo_damage
end

function EarningPotential.GatherData(leaderstats)
	local abilities=leaderstats.abilities
	local hotbar=leaderstats.hotbar
	local damage_score=0
	local stun_score=0
	local list={}
	for _,slot in hotbar:GetChildren() do
		local ability=slot.Ability.Value
		if list[ability] then continue end -- don't count the same ability more than once
		list[ability]=true
		local category=slot.Category.Value
		if not EarningPotential.Ratings[ability] then continue end -- it's not an ability we calc
		--print(ability)
		local CategoryFolder=abilities:FindFirstChild(category)
		local AbilityFolder=CategoryFolder:FindFirstChild(ability)
		local unlocked=AbilityFolder.Unlocked.Value
		local level=AbilityFolder.Level.Value
		local profile=EarningPotential.Ratings[ability]
		if profile.stun~=false then
			local misc=profile.misc and items[category][ability].misc[profile.misc] or false
			local stun=typeof(profile.misc)=="number" and m.getStat(level,misc.base,misc.multiplier) or profile.stun
			stun=(10/profile.cooldown)*stun
			stun_score=math.clamp(stun_score+stun,0,10)
			continue
		end
		local misc=items[category][ability].misc[profile.misc]
		local damage=m.getStat(level,misc.base,misc.multiplier)
		--print("damage=",damage)
		local cooldown=profile.cooldown
		local multiplier=math.round((10/cooldown)*.9)
		local combo_damage=profile.combos and EarningPotential.CalculateComboDamage((multiplier-1)*.1,damage) or 0
		--print("multiplier=",multiplier)
		local AOE=profile.AOE or 1
		local multi=profile.multi or 1
		combo_damage*=multi
		--print("combo damage=",combo_damage)
		--print("AOE=",AOE)
		local add=(damage * multiplier) + combo_damage
		add*=AOE
		add*=multi
		damage_score+=add
	end
	
	damage_score = damage_score --+ (damage_score*(.1*stun_score))
	
	local skins=leaderstats.skins
	
	local t={}
	for _,skin in skins:GetChildren() do 
		t[#t+1]={skin.Level.Value}
	end
	
	table.sort(t,m.greatest)
	
	local crit_boost=((t[1][1]-1)*3.5 + 5)/100 
	--print("crit boost=",crit_boost)
	damage_score=damage_score+((damage_score/2)*crit_boost)
	
	--print("damage_score=",damage_score)
	
	return damage_score 
end

function EarningPotential.Calculate(player)
	if not player then return end
	local leaderstats=player.leaderstats
	local rebirths=leaderstats.Rebirths
	local DPS=EarningPotential.GatherData(leaderstats)
	local EPS=math.round(DPS*0.3632)
	EPS = EPS + (EPS * (rebirths.Value/10))
	--print("DPS=",DPS)
	--print("EPS=",EPS)
	--711 min EPS
	--69018 max EPS
	local p1=(EPS/711)-1
	local p2=p1/97.0717
	local dampen=.125--.5-(.25*p2)
	local EB=math.clamp(p1,0,math.huge)*dampen
	--EB=math.clamp(EB,0,21.58)
	leaderstats.temp.EarningsBoost.Value=EB
	--print("Earnings Boost=",leaderstats.temp.EarningsBoost.Value)
	-- use Damage per second (DPS) to track earning potential
		-- consider the stun abilities
		-- for every second in a 10 second window you can stun, you get 10% boost to damage rating
		-- consider cooldown, spider drone exception (2s)
		-- consider combos: .1*damage for each combo, limited by cooldown math.floor(10/cooldown)
		-- AOE weapons 4x multiplier
		-- track abilities even if not in hotbar?
		-- when ability levels change update, when unlock changes, update
	
	-- use cash reward from thugs: average? or 0.3632
		-- bosses drop 100% of health
		-- consider objective rewards
		-- consider cash drops
		-- consider rebirths
	
	-- suits will add critical chance % to an extra 50% damage
	
end

return EarningPotential
