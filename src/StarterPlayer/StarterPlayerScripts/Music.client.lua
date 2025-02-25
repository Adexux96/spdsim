local rs = game:GetService("ReplicatedStorage")
local music = rs:WaitForChild("music")

if _G.cutscenePlaying==nil then
	repeat task.wait() until _G.cutscenePlaying
end

local songs = {
	--[1] = music:WaitForChild("A Superhero Awakens"),
	
	--[1]=music:WaitForChild("Suspended"),
	[1]=music:WaitForChild("Beats For The Street"),
	--[2]=music:WaitForChild("Massive Jurassic"),
	[2]=music:WaitForChild("Urban Dawn"),
	[3]=music:WaitForChild("The Beat Beat"),
	
	--[3] = music:WaitForChild("Age Of Heroes"),
	--[4] = music:WaitForChild("Very Very Legendary"),
	--[5] = music:WaitForChild("King Of Dragons"),
	--[6] = music:WaitForChild("Curse Re-Opened"),
	--[7] = music:WaitForChild("Superhero Saves The World"),
	--[8] = music:WaitForChild("The Last Superhero")
}

local suspended=music:WaitForChild("Suspended")

local ts=game:GetService("TweenService")
local tweenInfo=TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)

local function playMusic()
	while true do 
		if _G.cutscenePlaying then
			if not suspended.IsPlaying then
				suspended.TimePosition=10
				
				suspended:Play()
			end
		else
			if suspended.IsPlaying then
				suspended:Stop()
			end
			for i,v in (songs) do
				local volume=v:GetAttribute("Muted") and 0 or 0.075
				--print("volume=",volume)
				if v.Name=="Urban Dawn" then
					v.Volume=0
					v.TimePosition=10 -- skip 10 seconds ahead
					ts:Create(v,tweenInfo,{Volume=volume}):Play()
				end
				v:Play()
				v.Ended:Wait()
			end
		end
		task.wait(1/10)
	end
end

--local play = coroutine.wrap(playMusic)
playMusic()
