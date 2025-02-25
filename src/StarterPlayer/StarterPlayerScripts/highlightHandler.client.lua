local tweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,true)

_G.tweenHighlight = function(model)
	local highlight = model:FindFirstChildOfClass("Highlight") 
	if not highlight then
		highlight=Instance.new("Highlight")
		highlight.Enabled = true
		highlight.FillColor = Color3.fromRGB(255,0,0)
		highlight.FillTransparency = 1
		highlight.OutlineColor = Color3.fromRGB(0,0,0)
		highlight.OutlineTransparency = 1
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Adornee = model
		highlight.Parent = model
	end
	
	tweenService:Create(highlight,tweenInfo,{FillTransparency = 0}):Play()
	game:GetService("Debris"):AddItem(highlight,.6)
end

local camera = workspace.CurrentCamera
local cs=game:GetService("CollectionService")

local function ToggleRips(character,bool)
	for _,gui in character:GetDescendants() do 
		if gui:IsA("SurfaceGui") and tonumber(gui.Name) then
			gui:FindFirstChildOfClass("ImageLabel").ImageTransparency=bool and 0 or 1
		end
	end 
end

local plr=game.Players.LocalPlayer

while true do 
	local char=plr.Character
	local isSkin = char and char:FindFirstChild("Suit") or nil
	if char and char.PrimaryPart and isSkin then
		local highlight = char:FindFirstChild("Outline")
		if not highlight then -- no highlight but character is loaded in
			highlight=Instance.new("Highlight")
			highlight.Name="Outline"
			highlight.FillColor = Color3.fromRGB(255,0,0)
			highlight.FillTransparency = 1
			highlight.Adornee=char
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.Parent=char
		end
		local distance = (camera.CFrame.Position - char.PrimaryPart.Position).Magnitude
		highlight.Enabled = distance < 50
		highlight.OutlineColor=isSkin.Value=="ATSV Punk" and Color3.fromRGB(255, 217, 80) or Color3.fromRGB(0,0,0)		
	end

	local players = game.Players:GetPlayers()
	for _,player in pairs(players) do 
		local character = player.Character
		if not character or not character.PrimaryPart then continue end
		local humanoid=character:FindFirstChild("Humanoid")
		if not humanoid then continue end
		local health=humanoid.Health
		local maxHealth=humanoid.MaxHealth
		if health/maxHealth<=.5 then
			if not cs:HasTag(character,"Ripped") then
				ToggleRips(character,true)
				cs:AddTag(character,"Ripped")
			end
		else 
			if cs:HasTag(character,"Ripped") then
				ToggleRips(character,false)
				cs:RemoveTag(character,"Ripped")
			end
		end
	end
	
	wait(.5)
end