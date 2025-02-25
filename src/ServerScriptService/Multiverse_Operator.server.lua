local rs=game:GetService("ReplicatedStorage")
local MultiversePartyEvent=rs.MultiversePartyEvent

local Multiverse_Parties=rs.Multiverse_Parties
local timers={}

local function least(a,b)
	return a[1]<b[1]
end

local function sort_by_dt(list)
	local array={}
	for _,element in list:GetChildren() do 
		array[#array+1]={element:GetAttribute("dt"),element}
	end
	table.sort(array,least)
	for i,v in array do 
		v[2].Name=tostring(i)
	end
end

local function add_player_to_party(player,party,updated)
	local n=#party:GetChildren()+1
	local new=Instance.new("StringValue")
	new.Name=tostring(n)
	new.Value=player.UserId
	new:SetAttribute("playerID",player.UserId)
	new:SetAttribute("dt",workspace:GetServerTimeNow())
	new:SetAttribute("name",player.Name)
	new.Parent=party
	party:SetAttribute(player.Name,new.Name) -- to fetch the player's listing quickly
	party.Parent:SetAttribute(player.Name,party:GetAttribute("partyID")) -- to fetch the player's party quickly
	if not updated then
		party:SetAttribute("Update",workspace:GetServerTimeNow())
	end
end

-- if i'm a party owner and I join another party, that party I joined will have a different name after the names get re-sorted
-- how do I keep a register of that specific party

-- you're trying to leave a party that is no longer the same name when:
	-- when you join a party and your party gets removed

local function remove_party(world,party)
	
	--local world=Multiverse_Parties:FindFirstChild(worldName)
	--local party=world and world:FindFirstChild(partyName)
	for _,listing in party:GetChildren() do -- remove the world attribute for each member of the party!
		local playerName=listing:GetAttribute("name")
		world:SetAttribute(playerName,nil)
	end
	if party then party:Destroy() end -- remove the party!
	sort_by_dt(world)
	world:SetAttribute("Update",workspace:GetServerTimeNow())
end

local function remove_player_from_party(player,world,party,listing)
	local isOwner=listing.Name=="1"
	if isOwner then -- if owner leaves, remove the whole party!
		remove_party(world,party)
	else -- not the owner, just remove from party
		party:SetAttribute(player.Name,nil) -- remove fetch for player's listing, listing was removed!
		world:SetAttribute(player.Name,nil) -- remove fetch for player's party! Player is no longer in a party!
		listing:Destroy()
		sort_by_dt(party)
		party:SetAttribute("Update",workspace:GetServerTimeNow())
	end
end

local function create_party(player,world)
	local listing=Instance.new("Folder")
	listing.Name=#world:GetChildren()+1
	listing:SetAttribute("partyID",game:GetService("HttpService"):GenerateGUID(false))
	listing:SetAttribute("dt",workspace:GetServerTimeNow())
	listing:SetAttribute("timer",workspace:GetServerTimeNow())
	listing:SetAttribute("owner",player.UserId)
	listing:SetAttribute("FriendsOnly",false)
	listing:SetAttribute("PartyLocked",false)
	listing.Parent=world
	add_player_to_party(player,listing,true)
	world:SetAttribute("Update",workspace:GetServerTimeNow()) -- update the world's update attribute
end

local function get_party_from_id(world,partyID)
	for _,party in world:GetChildren() do 
		if party:GetAttribute("partyID")==partyID then
			return party
		end
	end
	return nil
end

local function process_leave(player,world)
	local partyID=world and world:GetAttribute(player.Name)
	local party=partyID and get_party_from_id(world,partyID)
	local listingName=party and party:GetAttribute(player.Name)
	local listing=listingName and party:FindFirstChild(listingName)
	if not listing then return end -- doesn't exist!
	-- check if player is in the party first
	remove_player_from_party(player,world,party,listing)
end

MultiversePartyEvent.OnServerEvent:Connect(function(player,action,world,...)
	local _world=Multiverse_Parties:FindFirstChild(world)
	if not _world then return end
	if action=="Settings" then
		local args={...}
		local party=get_party_from_id(_world,args[1])
		if not party then return end -- party doesn't exist.
		local isOwner=party:GetAttribute("owner")==player.UserId
		if not isOwner then return end
		local _setting=args[2]
		if _setting=="KickAll" then
			for _,listing in party:GetChildren() do
				print(listing.Name)
				if listing:GetAttribute("name")==player.Name then continue end -- don't kick yourself!
				local plr=game.Players:GetPlayerByUserId(listing:GetAttribute("playerID"))
				MultiversePartyEvent:FireClient(plr,"Kicked")
				remove_player_from_party(plr,_world,party,listing) -- kick this player from the party!
			end
			return
		end
		
		-- security checks:
		local value=args[3]
		if value==nil then return end
		if typeof(value)~="boolean" then return end
		local attribute=party:GetAttribute(_setting)
		if attribute==nil then return end -- the attribute doesn't exist!
		if attribute==value then return end -- it's the same value, no point in changing!
		
		if _setting=="FriendsOnly" then
			party:SetAttribute(_setting,value)
			if value==true then -- get rid of members who aren't your friends!
				for _,listing in party:GetChildren() do
					if listing:GetAttribute("name")==player.Name then continue end -- don't kick yourself!
					local plr=game.Players:GetPlayerByUserId(listing:GetAttribute("playerID"))
					if not plr:IsFriendsWith(player.UserId) then
						MultiversePartyEvent:FireClient(plr)
						remove_player_from_party(plr,_world,party,listing) -- kick this player from the party!
					end
				end
			end
			return
		end
		if _setting=="PartyLocked" then
			party:SetAttribute(_setting,value)
			return
		end
	end
	if action=="Join" then
		local args={...}
		-- check if player is in any party, if it's in another one, remove them from it and put them in this one, if they have that world unlocked.
		local intended_party=get_party_from_id(_world,args[1]) -- track this first, before you sort the parties!
		local partyID=_world:GetAttribute(player.Name)
		local party_joined=get_party_from_id(_world,partyID)
		if #intended_party:GetChildren()>5 then return end -- party is full!
		if party_joined then
			-- leave the party!
			local listingName=party_joined:GetAttribute(player.Name)
			local listing=listingName and party_joined:FindFirstChild(listingName)
			remove_player_from_party(player,_world,party_joined,listing)
		end
		if not intended_party then return end -- party doesn't exist!
		if intended_party:GetAttribute("PartyLocked")==true then return end -- can't join a locked party!
		if intended_party:GetAttribute("FriendsOnly")==true then
			if not player:IsFriendsWith(intended_party:GetAttribute("owner")) then return end
		end
		add_player_to_party(player,intended_party,false)
		return
	end
	if action=="Leave" then
		process_leave(player,_world)
		return
	end
	if action=="Create" then
		for _,__world in Multiverse_Parties:GetChildren() do 
			if __world:GetAttribute(player.Name) then print("already in party!") return end -- player is already in a party!
		end
		-- check if player is already in a party
		create_party(player,_world)
		return
	end
end)

game.Players.PlayerRemoving:Connect(function(player) -- if players were teleporting they would have already removed their party
	for _,world in Multiverse_Parties:GetChildren() do 
		if world:GetAttribute(player.Name) then
			process_leave(player,world)
			break
		end
	end
end)

local function Teleport(players)
	local TeleportService = game:GetService("TeleportService")
	local Players = game:GetService("Players")

	local code = TeleportService:ReserveServer(18170176630)

	--local players = {}

	TeleportService:TeleportToPrivateServer(18170176630, code, players,nil,nil,game.ServerStorage.loadingUI)
	-- You could add extra arguments to this function: spawnName, teleportData and customLoadingScreen
end

local duration=5
while true do
	for _,world in Multiverse_Parties:GetChildren() do 
		if #world:GetChildren()>0 then -- has parties!
			for _,party in world:GetChildren() do 
				local elapsed=workspace:GetServerTimeNow()-party:GetAttribute("dt")
				--print("elapsed=",math.round(elapsed))
				party:SetAttribute("timer",duration-math.round(elapsed))
				--print(party:GetAttribute("timer"))
				if math.round(elapsed) >= duration then
					local players={}
					for _,member in party:GetChildren() do
						local player=game.Players:GetPlayerByUserId(member:GetAttribute("playerID"))
						players[#players+1]=player
						MultiversePartyEvent:FireClient(player,"Leave")
					end
					Teleport(players)
					remove_party(world,party)
					-- teleport here!
				end
			end
		end
	end
	task.wait(1)
end