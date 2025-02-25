local liveProjectiles=require(script.Parent.LiveProjectiles)
local liveMelee=require(script.Parent.LiveMelee)

local last_clean=tick()

while true do
	local success,error =pcall(function()
		local i=0
		for key,value in liveProjectiles do 
			i+=1
			if i%100==0 then task.wait() end
			if tick()-value.start>=10 then
				value.clear(liveProjectiles[key])
				liveProjectiles[key]=nil
			end
		end
		for key,value in liveMelee do 
			i+=1
			if i%100==0 then task.wait() end
			if tick()-value.start>=10 then
				value.clear(liveMelee[key])
				liveMelee[key]=nil
			end
		end
		task.wait(1)
	end)
	if not success then
		print(error)
	end
end
