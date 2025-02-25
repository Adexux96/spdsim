local order={
	["0003"]=true, --// he
	["0006"]=true, --// l
	["0001"]=true, --// i
	["0002"]=true, --// co
	["0008"]=true, --// p
	["0005"]=true, --// t
	["0004"]=true --// er
}

local prepared=false
local function prepareHead(head)
	local other=head:FindFirstChildOfClass("Decal")
	if other and not order[other.Name] and other.Name~="eyes" then other:Destroy() end
	if not head:FindFirstChild("eyes") then
		local eyes=script.mouths.eyes:Clone()
		eyes.Transparency=0
		eyes.Parent=head
	end
end

local last=nil
while true do 
	local head=script.Head.Value
	if not head then task.wait() continue end
	
	for i=1,2 do 
		for name,_ in order do
			if last then
				last.Transparency=1
			end
			local mouth=head:FindFirstChild(name)
			if not mouth then
				mouth=script.mouths[name]:Clone()
				mouth.Parent=head
			end
			mouth.Transparency=0
			last=mouth
			task.wait(.1)
		end
		task.wait(.1) -- after you're done saying the word wait 1 second
	end
	--task.wait(5)
end