local rs = game:GetService("ReplicatedStorage")
local profileService = require(rs:WaitForChild("ProfileService"))
local RunService = game:GetService("RunService")

local dataManager = {}
dataManager.profiles = {}

local objectives={
		current=1,
		amount=0,
		talkedWithPolice=false,
		usedFirstPortal=false,
	completed=false
}

dataManager.defaultData = {
	rebirths = 0,
	cash = 0,
	killstreak=0,
	["comic pages"]=0,
	donated=0,
	timeSinceLastTouch = 0,
	yPosBeforeRagdoll = 0,
	cashGiven=false,
	objectivesWiped=false,
	suitsWipe=false,
	objectives={
		current=1,
		amount=0,
		talkedWithPolice=false,
		usedFirstPortal=false,
		completed=false
	},
	incentives={
		invite=false,
		like=false
	},
	codes={
		["EARLY!"]={
			Redeemed=false,
			Reward=1000
		},
	},
	tutorial={
		["Drag"]=false,
		["Roll"]=false,
		["Thugs"]=false
	},
	portals={
		["free"]=true,
		["bat"]=true,
		["ak"]=false,
		["shotgun"]=false,
		["flamethrower"]=false,
		["electric"]=false,
		["brute"]=false,
		["minigun"]=false
	},
	Subs={
		["+50Cash"]=false
	},
	spins={
		["Spins"]=0,
		["SpinTime"]=0
	},
	gamepasses={
			["Collector"]=false
	},
	abilities = {
		Special = {
			["Web Bomb"] = {
				Unlocked = false,
				Level = 1,
			},
			["Spider Drone"] = {
				Unlocked = false,
				Level = 1
			},
			["Gauntlet"] = {
				Unlocked = false,
				Level = 1
			}
		},
		Ranged = {
			["Impact Web"] = {
				Unlocked = true,
				Level = 1
			},
			["Snare Web"] = {
				Unlocked = false,
				Level = 1
			},
			["Shotgun Webs"] = {
				Unlocked = false,
				Level = 1
			}
		},
		Melee = {
			["Punch"] = {
				Unlocked = true,
				Level = 1
			},
			["Kick"] = {
				Unlocked = false,
				Level = 1
			},
			["360 Kick"] = {
				Unlocked = false,
				Level = 1
			}
		},
		Travel = {
			["Swing Web"] = {
				Unlocked = true,
				Level = 1
			},
			["Launch Webs"] = {
				Unlocked = false,
				Level = 1
			}
		},
		Traps = {
			["Trip Web"] = {
				Unlocked = false,
				Level = 1,
			},
			["Anti Gravity"] = {
				Unlocked = false,
				Level = 1
			}
		},
	},
	hotbar = {
		[1] = {
			Ability = "Punch",
			Category = "Melee"
		},
		[2] = {
			Ability = "Impact Web",
			Category = "Ranged"
		},
		[3] = {
			Ability = "Swing Web",
			Category = "Travel"
		},
		[4] = {
			Ability = "",
			Category = ""
		},
		[5] = {
			Ability = "",
			Category = ""
		},
		[6] = {
			Ability = "",
			Category = ""
		},
		[7] = {
			Ability = "",
			Category = ""
		},
		[8] = {
			Ability = "",
			Category = ""
		},
	},
	skins = {
		["Classic"] = {
			Unlocked = true,
			Level = 1,
			Equipped=false
		},
		["Gwen"] = {
			Unlocked = true,
			Level = 1,
			Equipped=false
		},
		["Miles"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Homemade"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Homecoming"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Yellow Jacket"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Damage Control"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Far From Home"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Miles Classic"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Noir"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Symbiote"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Scarlet"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Advanced"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Punk"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["No Way Home"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Iron Spider"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Stealth"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Supreme Sorcerer"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Spider Girl"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Miles Spider Verse"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Miles 2099"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["ATSV 2099"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["ATSV India"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["ATSV Miles"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["ATSV Scarlet"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["ATSV Punk"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Mayday Parker"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Spider Woman"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Black Spectacular"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
		["Spectacular"] = {
			Unlocked = false,
			Level = 1,
			Equipped=false
		},
	}
}

-- add to the default data when you add an update

local profileStore = profileService.GetProfileStore(
	"Player",
	dataManager.defaultData
)

function dataManager:GetUpdates(profile) -- make sure server script is also updating everything in folders
	for key,value in self.defaultData do -- 1D search
		if profile.Data[key]==nil then
			profile.Data[key]=value
		end
	end
	
	-- gamepasses updates
	for key,value in self.defaultData.gamepasses do 
		if profile.Data.gamepasses[key]==nil then
			--print("added",key)
			profile.Data.gamepasses[key]=value -- create new 
		end
	end
	
	-- (Unique case) remove gamepasses that existed before
	for key,value in profile.Data.gamepasses do 
		if self.defaultData.gamepasses[key]==nil then
			--print("removed",key)
			profile.Data.gamepasses[key]=nil --// remove this listing from your data if it's not included in the defaultData
		end
	end
	
	-- abilities updates
	local abilitiesData=profile.Data.abilities
	for category,categoryData in self.defaultData.abilities do 
		if abilitiesData[category]==nil then
			profile.Data.abilities[category]=categoryData -- create new 
		end
		for key,valueData in categoryData do 
			if abilitiesData[category][key]==nil then
				profile.Data.abilities[category][key]=valueData -- create new 
			end
		end
	end
	
	-- skins updates
	local skinsData=profile.Data.skins
	for key,value in self.defaultData.skins do 
		if skinsData[key]==nil then
			profile.Data.skins[key]=value
		end
	end
	
	-- codes updates
	local codesData=profile.Data.codes
	for key,value in self.defaultData.codes do 
		if codesData[key]==nil then
			profile.Data.codes[key]=value
		end
	end
	
	-- portals updates
	local portalsData=profile.Data.portals
	for key,value in self.defaultData.portals do 
		if portalsData[key]==nil then
			profile.Data.portals[key]=value
		end
	end
	
	-- objectives updates
	local objectivesData=profile.Data.objectives
	--profile.Data.objectives={}
	for key,value in self.defaultData.objectives do 
		if objectivesData[key]==nil then
			profile.Data.objectives[key]=value
		end
	end
	
	return profile
end

local function onPlayerAdded(player)
	-- the code below is places under the player added function --
	local profile = nil
	--[[
	if RunService:IsStudio() then
		print("loaded a mock version!")
		profile = profileStore.Mock:LoadProfileAsync(
			"Player_"..player.UserId,
			"ForceLoad"
		)
	else
		profile = profileStore:LoadProfileAsync(
			"Player_"..player.UserId,
			"ForceLoad" 
		)
	end]]
	profile = profileStore:LoadProfileAsync(
		"Player_"..player.UserId,
		"ForceLoad" 
	)
	
	if profile then
		profile:ListenToRelease(function() -- this is for when the player leaves the game
			--print("removed data!")
			--dataManager.profiles[player].Data = dataManager.defaultData
			dataManager.profiles[player] = nil
		end)
		
		if player:IsDescendantOf(game.Players) then -- make sure the player exists
			profile=dataManager:GetUpdates(profile)
			dataManager.profiles[player] = profile
			--print("isLive=",profileService.IsLive())
			--dataManager.profiles[player].Data = dataManager.defaultData -- remember to take this off later
			--[[
			workspace.change.Touched:Connect(function(object)
				if game.Players:GetPlayerFromCharacter(object.Parent) then
					local plr = game.Players:GetPlayerFromCharacter(object.Parent)
					dataManager.profiles[plr].Data = dataManager.defaultData
					plr:Kick("Reset data")
				end
			end)
			]]
		else
			profile:Release()
		end
	else
		player:Kick("Your data was open in another server, please rejoin.")
	end
end

local function onPlayerRemoving(player)
	local profile = dataManager.profiles[player]
	if profile then
		profile:Release()
	end
end

game.Players.PlayerAdded:Connect(onPlayerAdded)
game.Players.PlayerRemoving:Connect(onPlayerRemoving)

function dataManager:Get(player)
	local profile = dataManager.profiles[player]
	if (profile) then
		return profile.Data
	else
		return nil
	end
end

return dataManager