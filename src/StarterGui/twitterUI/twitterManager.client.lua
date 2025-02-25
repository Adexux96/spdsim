local twitterUI=script.Parent
local bg=twitterUI:WaitForChild("bg")
local inner=bg:WaitForChild("inner")
local folder=inner:WaitForChild("Folder")
local input=folder:WaitForChild("2input")
local textbox=input:WaitForChild("text"):WaitForChild("TextBox")

local purchase=folder:WaitForChild("3purchase")
local button=purchase:WaitForChild("text"):WaitForChild("button")

local rs=game:GetService("ReplicatedStorage")
local codeRemote=rs:WaitForChild("CodeRemote")
local buttonSound = rs:WaitForChild("ui_sound"):WaitForChild("button3")
local errorSound = rs:WaitForChild("ui_sound"):WaitForChild("error")

local player=game.Players.LocalPlayer
local leaderstats=player:WaitForChild("leaderstats")
local codes=leaderstats:WaitForChild("codes")

local function ButtonActivated()
	if _G.tweenButton then
		local f=coroutine.wrap(_G.tweenButton)
		f(purchase)
	end
	local text=textbox.Text
	local validCode=codes:FindFirstChild(text)
	local alreadyRedeemed=validCode and validCode.Redeemed.Value
	if not validCode or alreadyRedeemed then --// if doesn't exist or already redeemed
		local s=not validCode and "Invalid or expired!" or "Already redeemed!"
		textbox.Text=s
		errorSound:Play()
		return
	end
	buttonSound:Play()
	codeRemote:FireServer(text)
end

-- when the ui in enabled/disabled change the text back to ""

button.Activated:Connect(ButtonActivated)

local function Reset_Text()
	textbox.Text=""
end

twitterUI:GetPropertyChangedSignal("Enabled"):Connect(Reset_Text)