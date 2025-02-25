local rewards=require(script.Parent.Rewards)

while true do 
	for i,v in rewards.contents do 
		rewards:Assign_Closest_Recipients(i)
	end
	task.wait(1/10)
end
