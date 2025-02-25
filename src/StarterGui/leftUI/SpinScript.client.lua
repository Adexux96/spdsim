local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Debounce = true

script.Parent.Parent:WaitForChild("spinsUI"):WaitForChild("Spinner").Size = UDim2.fromScale(0,0)
script.Parent.Parent:WaitForChild("spinsUI"):WaitForChild("Spinner").Visible = false
script.Parent.Parent:WaitForChild("spinsUI"):WaitForChild("Spinner").Rotation = 0

local Animation1 = TweenService:Create(script.Parent.Parent:WaitForChild("spinsUI"):WaitForChild("Spinner"), TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
	Size = UDim2.fromScale(0.65, 0.65),
	Rotation = 360
})

local Animation2 = TweenService:Create(script.Parent.Parent:WaitForChild("spinsUI"):WaitForChild("Spinner"), TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
	Size = UDim2.fromScale(0, 0),
	Rotation = 0
})

script.Parent.container.outer["6spins"].bg.spinOpen.MouseButton1Click:Connect(function()
	if Debounce then
		Debounce = false

		if script.Parent.Parent.spinsUI.Spinner.Visible == false then
			script.Parent.Parent.spinsUI.Spinner.Visible = true
			Lighting.Blur.Enabled = true
			Animation1:Play()
		else
			Animation2:Play()
			script.Parent.Parent.spinsUI.Spinner.Visible = false
			Lighting.Blur.Enabled = false
		end

		Animation1.Completed:Connect(function()
			Debounce = true
		end)
		Animation2.Completed:Connect(function()
			Debounce = true
		end)
	end
end)