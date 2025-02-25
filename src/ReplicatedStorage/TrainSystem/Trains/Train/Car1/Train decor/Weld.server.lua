local all = {}
function scan(p)
	for _,v in pairs(p:GetDescendants()) do
		if (v:IsA("BasePart")) then
				local w = Instance.new("Weld")
			     w.Part0,w.Part1 = script.Parent.Parent.Base,v
			     w.C0 = v.CFrame:toObjectSpace(script.Parent.Parent.Base.CFrame -Vector3.new(0,1,0)):inverse()
		         w.Parent = script.Parent.Parent.Base
			     table.insert(all,v)
		end
	
	end
end
scan(script.Parent)
for _,v in pairs(all) do v.Anchored = false end 