local rs = game:GetService("ReplicatedStorage")
local clock = rs:WaitForChild("clock")
local _math = require(rs:WaitForChild("math"))

local players = game.Players

local playerEvents = {}

local function disconnectEvents(player)
	if not playerEvents[player.Name] then return end -- never existed
	for index,event in pairs(playerEvents[player.Name]) do 
		event:Disconnect()
		table.remove(playerEvents[player.Name],index)
	end
end

local function playerAdded(player)
	--print(player.Name," added!")
	local leaderstats = player:WaitForChild("leaderstats")
	local temp = leaderstats:WaitForChild("temp")
	local isClimbing = temp:WaitForChild("isClimbing")
	
	local spiderLegs = nil
	local primary
	local movement
	local transition
	local animationController = nil
	local animations = nil
	
	playerEvents[player.Name] = {}
	
	local function climbingChanged(character)
		if not character then --[[print("character doesn't exist")]] return end
		disconnectEvents(player)
		
		local function stopAnimations()
			for _,track in pairs(animationController:GetPlayingAnimationTracks()) do 
				track:Stop()
			end
		end
						
		local function legsMoved()
			local sound = movement
			local clone = sound:Clone()
			clone.Parent = sound.Parent
			clone.PlaybackSpeed = _math.defined(.8,.9)
			clone:Play()
			game:GetService("Debris"):AddItem(clone,.5)
		end
				
		local function legsImpact()
			spiderLegs.PrimaryPart.Impact.PlaybackSpeed = _math.defined(1,1.1)
			spiderLegs.PrimaryPart.Impact:Play()
		end

		local function adjustSpeed(anim,speed)
			--print(speed)
			anim:AdjustSpeed(speed*.5)
		end
		
		local i = 0
		if not character:FindFirstChild("Suit") then 
			repeat task.wait(1/30) until character:FindFirstChild("Suit") or i == 20
		end
		
		if i == 20 then return end
		
		local suit = character:FindFirstChild("Suit")
		if suit.Value == "Iron Spider" then
			spiderLegs = character:WaitForChild("SpiderLegs")
			primary=spiderLegs:WaitForChild("RootLegs")
			movement=primary:WaitForChild("Movement")
			transition=primary:WaitForChild("Transition")
			animationController = spiderLegs:WaitForChild("AnimationController")
			animations = animationController:WaitForChild("Animations")
		else
			return
		end
		
		transition:Play()
		if isClimbing.Value then
			stopAnimations()
			primary.Transparency = 0
			local out = animations:WaitForChild("Out")
			local outAnim = animationController:LoadAnimation(out)
			outAnim:Play(.2,1,.5)
			outAnim.Stopped:Wait()
			if not isClimbing.Value then return end
			local climb = animations:WaitForChild("Climb")
			local climbAnim = animationController:LoadAnimation(climb)
			local speed = 0
			playerEvents[player.Name][#playerEvents[player.Name]+1] = climbAnim:GetMarkerReachedSignal("move1"):Connect(legsMoved)
			playerEvents[player.Name][#playerEvents[player.Name]+1] = climbAnim:GetMarkerReachedSignal("move2"):Connect(legsMoved)
			--events[#events+1] = climbAnim:GetMarkerReachedSignal("impact1"):Connect(legsImpact)
			--events[#events+1] = climbAnim:GetMarkerReachedSignal("impact2"):Connect(legsImpact)
			playerEvents[player.Name][#playerEvents[player.Name]+1] = clock:GetPropertyChangedSignal("Value"):Connect(function()
				local velocity = character.PrimaryPart.Velocity.Magnitude/16
				speed = character:WaitForChild("Humanoid").MoveDirection.Magnitude * velocity
				adjustSpeed(climbAnim,speed)
			end)
			climbAnim:Play(.2,1,speed)
		else
			stopAnimations()
			local In = animations:WaitForChild("In")
			local inAnim = animationController:LoadAnimation(In)
			inAnim:Play(.2,1,.5)
			inAnim.Stopped:Wait()
			if isClimbing.Value then return end
			local idle = animations:WaitForChild("Idle2")
			local idleAnim = animationController:LoadAnimation(idle)
			idleAnim:Play(.2,1,.2)
			--primary.Transparency = 1
		end
	end
	
	isClimbing:GetPropertyChangedSignal("Value"):Connect(function()
		--print(player.Name,"'s climbing changed to:",isClimbing.Value)
		local character = player.Character
		climbingChanged(character)
	end)
	
	player.CharacterAdded:Connect(function(character)
		climbingChanged(character)
	end)
	
end

players.PlayerAdded:Connect(playerAdded)

for _,player in pairs(players:GetPlayers()) do 
	playerAdded(player)
end

players.PlayerRemoving:Connect(disconnectEvents)