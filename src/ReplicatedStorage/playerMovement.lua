local player = game.Players.LocalPlayer
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()

local playerMovement = {forward = 0,backward = 0,left = 0,right = 0, isNotMoving = true}

function playerMovement.GetMoveVector(self)
	local vector = controls:GetMoveVector()
	return vector
end

return playerMovement
