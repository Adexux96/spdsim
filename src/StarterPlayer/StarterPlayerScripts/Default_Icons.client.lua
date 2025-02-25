local rs=game:GetService("ReplicatedStorage")
local Icon=require(rs:WaitForChild("TopbarPlus"):WaitForChild("Icon"))

local SocialService=game:GetService("SocialService")
local plr=game.Players.LocalPlayer

local music=rs:WaitForChild("music")

--local invite=Icon.new()
	--:setLabel("")
	--:setImage(16086868244, "Deselected")
	--:setImage(16086868447, "Selected")

local Invite=Icon.new()
Invite:setImage(13527597353)
Invite.selected:Connect(function()
	task.spawn(function()
		task.wait()
		Invite:deselect()
	end)
	local function canSendGameInvite(sendingPlayer)
		local success, canSend = pcall(function()
			return SocialService:CanSendGameInviteAsync(sendingPlayer)
		end)
		return success and canSend
	end

	local canInvite = canSendGameInvite(plr)
	if canInvite then
		local inviteOptions = Instance.new("ExperienceInviteOptions")
		inviteOptions.InviteMessageId="887aa63c-049b-3b4f-96aa-5fbf1645741b"
		local success, errorMessage = pcall(function()
			SocialService:PromptGameInvite(plr,inviteOptions)
		end)
	end
end)

local volume=0.075
local b=Icon.new()
b:setImage(13535155826)
--b:setProperty("deselectWhenOtherIconSelected", false)
b.selected:Connect(function()
	--[[
	volume_index+=1
	if volume_index>2 then
		volume_index=1 -- reset
	end
	]]
	volume=volume==0.075 and 0 or 0.075
	for _,music in music:GetChildren() do 
		--local p=1-((volume_index-1)/1)
		music.Volume=volume
		music:SetAttribute("Muted",volume==0)
	end
	--[[
	local imageIds={
		13535155826, -- 3 bars
		13535165018 -- 0 bars
	}
	]]
	--b:set("iconImageTransparency",imageIds[volume_index])
	--b:setImage(imageIds[volume])
	--Icon:setImageTransparency(volume==1 and 0 or 0.5)
	b:modifyTheme({"IconImage", "ImageTransparency", volume==0.075 and 0 or 0.5})
	--task.wait()
	b:deselect()
end)

--[[
if not _G.cash_changed then
	repeat task.wait(.2) until _G.cash_changed
end
]]

local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local PvP=leaderstats:WaitForChild("temp"):WaitForChild("PvP")
local rebirths=leaderstats:WaitForChild("Rebirths")
local pvp=Icon.new()
--pvp:setImage(13564921773)
pvp:setLabel("PVP: off")
pvp:modifyTheme({"IconLabel", "Text", rebirths.Value>=1 and "PVP: on" or "PVP: off"})
--pvp:set("iconImageTransparency",rebirths.Value>=1 and 0 or 0.5)
--pvp:modifyTheme({"IconImage", "ImageTransparency", rebirths.Value>=1 and 0 or 0.5})

local pvpEvent=rs:WaitForChild("pvpEvent")

pvpEvent.OnClientEvent:Connect(function(text)
	if not _G.cash_changed then return end
	_G.cash_changed(nil,text)
end)

pvp.selected:Connect(function()
	if not _G.cash_changed then return end
	task.spawn(function()
		task.wait()
		pvp:deselect()
	end)

	local last=PvP:GetAttribute("Last")
	if not last then -- just go ahead and send the request to the server
		pvpEvent:FireServer()
		return
	end

	local elapsed=workspace:GetServerTimeNow()-last
	if elapsed<10 then -- don't even send a message to the server, you know it's not enough elapsed time yet
		-- notify that the player has to wait x amount of seconds
		_G.cash_changed(nil,"You must wait "..10-math.round(elapsed).." seconds to toggle PvP again")
		return
	end

	local last_combat=player:GetAttribute("LastCombat") or -5
	local elapsed=workspace:GetServerTimeNow()-last_combat
	if elapsed<5 and PvP.Value then
		-- notify that the player has to wait x amount of seconds out of combat

		_G.cash_changed(nil,"You must wait "..5-math.round(elapsed).." more seconds out of combat before turning PVP off")
		return 
	end

	pvpEvent:FireServer() -- request server toggle 
end)

PvP:GetPropertyChangedSignal("Value"):Connect(function()
	pvp:modifyTheme({"IconLabel", "Text", PvP.Value and "PVP: on" or "PVP: off"})
end)