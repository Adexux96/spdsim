local MarketplaceService = game:GetService("MarketplaceService")
local Player = game:GetService("Players").LocalPlayer
local leaderstats = Player:WaitForChild("leaderstats")
local spins = leaderstats:WaitForChild("spins")
local SpinStats = spins:WaitForChild("Spins")

local spinnerFrame = script.Parent
local button = spinnerFrame:WaitForChild("Button"):WaitForChild("ImageButton")

-- Remove previous aspect ratio constraint since we want rectangular shape
if button:FindFirstChild("UIAspectRatioConstraint") then
    button:FindFirstChild("UIAspectRatioConstraint"):Destroy()
end

-- Set button size relative to spinner frame
local function updateButtonSize()
    local spinnerSize = spinnerFrame.AbsoluteSize
    local buttonHeight = spinnerSize.Y * 0.1 -- 10% of spinner height
    button.Size = UDim2.new(0.80, 0, 0, buttonHeight) -- 35% width, fixed height
    button.Position = UDim2.new(0.5, 0, 0.05, 0) -- Center horizontally, moved up to 75% down
    button.AnchorPoint = Vector2.new(0.5, 0) -- Center anchor horizontally
end

spinnerFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateButtonSize)
updateButtonSize() -- Initial size

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