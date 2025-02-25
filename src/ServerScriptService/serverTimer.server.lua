local timer = script.Parent.timer

local interval = 1
local startTick
local i = -1
local totalTime = 0
local dt = 0

while true do
	startTick = tick() -- set the timer
	i = i + interval
	local correctTime = i
	local difference = totalTime - correctTime
	--print("totalTime: ",totalTime," correctTime: ",correctTime)
	if (difference < interval) then -- only wait if difference is less than interval
		local runCode = tick() -- set the code timer
		timer.Value = i
		runCode = tick() - startTick
		task.wait((interval - difference)-runCode)
	end
	dt = tick() - startTick
	totalTime = totalTime + dt
end