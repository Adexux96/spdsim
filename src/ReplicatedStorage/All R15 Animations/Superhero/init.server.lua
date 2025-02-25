animate = script:WaitForChild("Animate")
workspace.DescendantAdded:connect(function(v)
	if v.Name == 'Animate' then
		local c = animate:clone()
		c.Parent = v.Parent
		v:Destroy()
		wait()
		c.Disabled=false
	end
end)