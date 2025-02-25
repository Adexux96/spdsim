local bullets = workspace:WaitForChild("Bullets")
bullets.ChildAdded:Connect(function(child)
	child.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Trail") then
			descendant.Enabled = true
		end
	end)
end)
