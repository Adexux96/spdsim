local roundDecimals = function(num, places)
	places = math.pow(10, places or 0)
	num = num * places
	if num >= 0 then 
		num = math.floor(num + 0.5) 
	else 
		num = math.ceil(num - 0.5) 
	end
	return num / places
end

game:GetService("RunService").Heartbeat:Connect(function()
	script.Parent.CFrame = script.Parent.Parent.Base.CFrame*CFrame.new(0,0,-script.Parent.Parent.Base.Size.Z/2)
end)