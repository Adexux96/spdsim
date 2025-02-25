local rs = game:GetService("ReplicatedStorage")
local timeEvent = rs:WaitForChild("TimeEvent")

local hours = 9
local minutes = 0
local am_pm = "am"

local timer = script.Parent.timer
local function runTime(i)
	for m = 0,i do -- day/night each lasts 5 minutes
		timer.Changed:Wait()
		--task.wait(1/30)
	end
end

_G.timeOfDay = "morning"

while true do
	_G.timeOfDay = "morning"
	timeEvent:FireAllClients("morning")
	runTime(300) -- 5 mins
	_G.timeOfDay = "night"
	timeEvent:FireAllClients("night")
	runTime(300) -- 5 mins
end
