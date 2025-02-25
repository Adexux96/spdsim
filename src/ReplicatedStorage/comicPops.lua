
local rs = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local comicPopup = rs:WaitForChild("comicPopup")

local pops = {}

pops.popNames = {
	["pow!"] = {
		[1] = {
			offset = Vector2.new(128,0),
			rotation = {
				[-1] =-45,
				[1] = 45
			}
		},
		[2] = {
			offset = Vector2.new(256,0),
			rotation = {
				[-1] = -45,
				[1] = 45
			}
		}
	},
	["bam!"] = {
		[1] = {
			offset = Vector2.new(128,0),
			rotation = {
				[-1] =-45,
				[1] = 45
			}
		},
		[2] = {
			offset = Vector2.new(256,0),
			rotation = {
				[-1] = -45,
				[1] = 45
			}
		}
	},
	["oof!"] = {
		[1] = {
			offset = Vector2.new(0,0),
			rotation = {
				[-1] =0,
				[1] = 145
			}
		},
		[2] = {
			offset = Vector2.new(256,128),
			rotation = {
				[-1] = -90,
				[1] = 45
			}
		}
	},
	["yow!"] = {
		[1] = {
			offset = Vector2.new(0,0),
			rotation = {
				[-1] =0,
				[1] = 145
			}
		},
		[2] = {
			offset = Vector2.new(256,128),
			rotation = {
				[-1] = -90,
				[1] = 45
			}
		}
	},
	["zap!"] = {
		[1] = {
			offset = Vector2.new(0,128),
			rotation = {
				[-1] =0,
				[1] = 45
			}
		},
		[2] = {
			offset = Vector2.new(128,128),
			rotation = {
				[-1] = -90,
				[1] = 0
			}
		}
	},
	["ahh!"] = {
		[1] = {
			offset = Vector2.new(0,0),
			rotation = {
				[-1] =0,
				[1] = 145
			}
		},
	},
}

local patterns = {
	--[1] = Vector2.new(0,0),
	[1] = Vector2.new(128,0),
	[2] = Vector2.new(256,0),
	[3] = Vector2.new(0,128),
	[4] = Vector2.new(128,128),
	[5] = Vector2.new(256,128)
}

local ts = game:GetService("TweenService")
local tweenInfo1 = TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
local tweenInfo2 = TweenInfo.new(.05,Enum.EasingStyle.Elastic,Enum.EasingDirection.InOut,1,true,0)

local cs = game:GetService("CollectionService")

function pops.newPopup(popName,headPart)
	if cs:HasTag(headPart,"pop") then return end
	cs:AddTag(headPart,"pop")
	local popUpPart = comicPopup:Clone()
	popUpPart.CFrame = headPart:IsA("Attachment") and headPart.WorldCFrame or headPart.CFrame
	popUpPart.Name = "comicPopup"
	popUpPart.Parent = workspace:WaitForChild("comicPopups")
	
	local popUpAttachment = popUpPart.Attachment
	--popUpAttachment.ui.Adornee = headPart
	
	local ui = popUpAttachment.ui
	local bg = ui.bg 
	local pattern = bg.pattern
	local poof = bg.poof
	local text = bg.text
	text.Text = popName
	
	local textTween = ts:Create(text,tweenInfo2,{Position = UDim2.new(.4,0,.487,0)})
	
	local xOffset = math.random(0,100) <= 50 and -2 or 2
	local yOffset = 2
	
	local patternOffset = patterns[math.random(1,5)]
	local poofArray = pops.popNames[popName]
	local poofData = poofArray[math.random(1,#poofArray)]
	
	pattern.ImageRectOffset = patternOffset
	poof.ImageRectOffset = poofData.offset
	poof.Rotation = xOffset < 0 and poofData.rotation[-1] or poofData.rotation[1]
	
	local function sizeCompleted()
		wait(.5)
		local start = tick()
		local duration = .2
		while tick() - start < duration do
			local p = (tick() - start) / duration
			poof.ImageTransparency = p 
			text.TextTransparency = p
			text.UIStroke.Transparency = (p*.75)+.25 
			pattern.ImageTransparency = p
			task.wait(1/30)
		end
		popUpPart:Destroy()
		cs:RemoveTag(headPart,"pop")
	end
	
	local sizeTween = ts:Create(bg,tweenInfo1,{Size = UDim2.new(1,0,1,0)})
	sizeTween.Completed:Connect(sizeCompleted)
	local positionTween = ts:Create(ui,tweenInfo1,{ExtentsOffset = Vector3.new(xOffset,yOffset,0)})
	positionTween:Play()
	sizeTween:Play()
	textTween:Play()	
end

return pops
