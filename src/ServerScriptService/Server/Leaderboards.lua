local DataStoreService=game:GetService("DataStoreService")
local CashDataStore=DataStoreService:GetOrderedDataStore("CashLeaderboard")
local KillstreakDataStore=DataStoreService:GetOrderedDataStore("KillstreakLeaderboard")
local DonationsDataStore=DataStoreService:GetOrderedDataStore("DonationLeaderboard")

local Leaderboards = {}

function Leaderboards:FetchKills()
	local kills={}
	local success,_error=pcall(function()
		local killstreakData=KillstreakDataStore:GetSortedAsync(false,10)
		local killstreakPage=killstreakData:GetCurrentPage() -- send this to all the clients
		for rank,saved in killstreakPage do 
			--print("rank:",rank,"=",saved.key,saved.value)
			local name=""
			local success,_error=pcall(function()
				name=game.Players:GetNameFromUserIdAsync(saved.key)
			end)
			if _error then
				name="Unkown"
			end
			kills[rank]={
				name=name,
				amount=saved.value,
				id=saved.key
			}
		end
	end)
	return kills
end

function Leaderboards:FetchCash()
	local cash={}
	local success,_error=pcall(function()
		local cashData=CashDataStore:GetSortedAsync(false,10)
		local cashPage=cashData:GetCurrentPage() -- send this to all the clients
		for rank,saved in cashPage do 
			local name=""
			local success,_error=pcall(function()
				name=game.Players:GetNameFromUserIdAsync(saved.key)
			end)
			if _error then
				name="Unkown"
			end
			cash[rank]={
				name=name,
				amount=saved.value,
				id=saved.key
			}
		end
	end)
	return cash
end

function Leaderboards:FetchDonations()
	local donations={}
	local success,_error=pcall(function()
		local donationData=DonationsDataStore:GetSortedAsync(false,50)
		local donationPage=donationData:GetCurrentPage() -- send this to all the clients
		for rank,saved in donationPage do
			local name=""
			local success,_error=pcall(function()
				name=game.Players:GetNameFromUserIdAsync(saved.key)
			end)
			if _error then
				name="Unkown"
			end
			if saved.value<1 then continue end
			donations[rank]={
				name=name,
				amount=saved.value,
				id=saved.key
			}
		end
	end)
	
	return donations
end

function Leaderboards:Refresh()
	local success,_error=pcall(function()
		for _,player in game.Players:GetPlayers() do
			local leaderstats=player:FindFirstChild("leaderstats")
			if not leaderstats then continue end
			local Cash=leaderstats:FindFirstChild("Cash")
			local Kills=leaderstats:FindFirstChild("Kills")
			if not Cash or not Kills then continue end
			CashDataStore:SetAsync(player.UserId,Cash.Value)
			KillstreakDataStore:SetAsync(player.UserId,Kills.Value)
			local Donated=leaderstats:FindFirstChild("Donations").Donated
			DonationsDataStore:SetAsync(player.UserId,Donated.Value)
		end
	end)
	if _error then
		warn(_error)
	end
end

return Leaderboards

