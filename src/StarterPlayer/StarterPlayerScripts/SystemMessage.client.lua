local prefix = "[SERVER]: "
local messages = {
	"👍 Make sure to like the game and join the group to stay updated!",
	"📢 Make sure to turn on notifications to stay updated!",
	--"👉 Follow @CleverWizard2021 for more updates!"
}

local function displayMessage(index)
	local message = messages[index]
	game.TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage("<font color='#FC6F70'>" .. prefix .. message .. "</font>")
end

local player=game.Players.LocalPlayer
local character=player.Character or player.CharacterAdded:Wait()

local index = 1
while true do
	displayMessage(index)
	index = index + 1
	if index > #messages then
		index = 1
	end
	task.wait(600) -- 10 mins
end