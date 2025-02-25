
local rs =game:GetService("ReplicatedStorage")
local comicPopup = rs:WaitForChild("comicPopup")
local popsModule = require(rs:WaitForChild("comicPops"))

while true do 
	local headPart = workspace:WaitForChild("comicPop")
	local randomNumber = math.random(1,5)
	local i = 0
	local popName = nil
	for key,value in (popsModule.popNames) do 
		i+=1 
		if i==randomNumber then
			popName = key
		end
	end
	if popName ~= nil then
		popsModule.newPopup(popName,headPart)
	end
	wait(1)
end
