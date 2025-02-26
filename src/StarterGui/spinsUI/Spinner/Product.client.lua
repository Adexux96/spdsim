local MarketplaceService = game:GetService("MarketplaceService")
local Player = game:GetService("Players").LocalPlayer
local leaderstats = Player:WaitForChild("leaderstats")
local spins = leaderstats:WaitForChild("spins")
local SpinStats = spins:WaitForChild("Spins")

local button = script.Parent:WaitForChild("Button"):WaitForChild("ImageButton")
local connection

local function buySpin()
    local ID = button:WaitForChild("ID")
    MarketplaceService:PromptProductPurchase(Player, ID.Value)
end

local function updateConnection()
    if SpinStats.Value == 0 and not connection then
        connection = button.Activated:Connect(buySpin)
    elseif SpinStats.Value > 0 and connection then
        connection:Disconnect()
        connection = nil
    end
end

updateConnection()

SpinStats.Changed:Connect(updateConnection)