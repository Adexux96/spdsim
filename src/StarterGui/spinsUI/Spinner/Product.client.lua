local MarketplaceService = game:GetService("MarketplaceService")
local Player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")

for i,v in pairs(script.Parent:WaitForChild("ButtonX1"):GetChildren()) do
	if v:IsA("ImageButton") then
		v.MouseButton1Click:Connect(function()

			local ID = v:WaitForChild("ID")
			MarketplaceService:PromptProductPurchase(Player,ID.Value)
		end)
		
		for i,v in pairs(script.Parent:WaitForChild("ButtonX10"):GetChildren()) do
			if v:IsA("ImageButton") then
				v.MouseButton1Click:Connect(function()

					local ID = v:WaitForChild("ID")
					MarketplaceService:PromptProductPurchase(Player,ID.Value)
				end)
			end
		end
	end
end