-- Roblox character sound script

local world_sound_group = game:GetService("SoundService"):WaitForChild("world")

local Players = game:GetService("Players")
local localPlayer = game.Players.LocalPlayer
local cs = game:GetService("CollectionService")
local rs = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local _math = require(game:GetService("ReplicatedStorage"):WaitForChild("math"))

local SOUND_DATA = {
	Climbing = {
		SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3",
		Looped = true,
		SoundGroup = world_sound_group
	},
	Died = {
		SoundId = "rbxasset://sounds/uuhhh.mp3",
		SoundGroup = world_sound_group
	},
	FreeFalling = {
		SoundId = "rbxasset://sounds/action_falling.mp3",
		Looped = true,
		SoundGroup = world_sound_group
	},
	GettingUp = {
		SoundId = "rbxasset://sounds/action_get_up.mp3",
		SoundGroup = world_sound_group
	},
	Jumping = {
		SoundId = "rbxasset://sounds/action_jump.mp3",
		SoundGroup = world_sound_group
	},
	Landing = {
		SoundId = "rbxasset://sounds/action_jump_land.mp3",
		SoundGroup = world_sound_group
	},
	Splash = {
		SoundId = "rbxasset://sounds/impact_water.mp3",
		SoundGroup = world_sound_group
	},
	Swimming = {
		SoundId = "rbxasset://sounds/action_swim.mp3",
		Looped = true,
		PlaybackSpeed = 1.6,
		SoundGroup = world_sound_group
	},
	Grass = {
		SoundId = "rbxassetid://4997263522",
		Looped = true,
		PlaybackSpeed = 1.85,	
		SoundGroup = world_sound_group
	},
	Sand = {
		SoundId = "rbxassetid://4997264822",
		Looped = true,
		PlaybackSpeed = 1.85,	
		SoundGroup = world_sound_group
	},
	Dirt = {
		SoundId = "rbxassetid://4997264822",
		Looped = true,
		PlaybackSpeed = 1.85,
		SoundGroup = world_sound_group
	},
	Water = {
		SoundId = "rbxassetid://4997265345",
		Looped = true,
		PlaybackSpeed = 1.85,
		SoundGroup = world_sound_group
	},
	Wood = {
		SoundId = "rbxassetid://4997265650",
		Looped = true,
		PlaybackSpeed = 1.85,
		SoundGroup = world_sound_group
	},
	Rock = {
		SoundId = "rbxassetid://4997313837",
		Looped = true,
		PlaybackSpeed = 1.85,
		SoundGroup = world_sound_group
	},
	Stone = {
		SoundId = "rbxassetid://4997263146",
		Looped = true,
		PlaybackSpeed = 1.85,
		SoundGroup = world_sound_group
	},
	Metal = {
		SoundId = "rbxassetid://4997264095",
		Looped = true,
		PlaybackSpeed = 1.85,
		SoundGroup = world_sound_group
	},
	Tile = {
		SoundId = "rbxassetid://4997313837",
		Looped = true,
		PlaybackSpeed = 1.85,
		SoundGroup = world_sound_group
	},
	Carpet = {
		SoundId = "rbxassetid://4997262777",
		Looped = true,
		PlaybackSpeed = 1.85,
		SoundGroup = world_sound_group		
	},
}

 -- wait for the first of the passed signals to fire
local function waitForFirst(...)
	local shunt = Instance.new("BindableEvent")
	local slots = {...}

	local function fire(...)
		for i = 1, #slots do
			slots[i]:Disconnect()
		end

		return shunt:Fire(...)
	end

	for i = 1, #slots do
		slots[i] = slots[i]:Connect(fire)
	end

	return shunt.Event:Wait()
end

-- map a value from one range to another
local function map(x, inMin, inMax, outMin, outMax)
	return (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin
end

local function playSound(sound)
	sound.TimePosition = 0
	sound.Playing = true
end

local function shallowCopy(t)
	local out = {}
	for k, v in (t) do
		out[k] = v
	end
	return out
end

materials = { -- the Color3.fromRGB returned data
	["0.32549, 0.529412, 0.258824"] = "Grass", -- 83, 135, 66 
	["0.313726, 0.580392, 0.294118"] = "Grass", -- 80, 148, 75
	["0.827451, 0.745098, 0.588235"] = "Sand", -- 211, 190, 150
	["0.764706, 0.717647, 0.568627"] = "Sand", -- 195, 183, 145
	["0.639216, 0.635294, 0.647059"] = "Stone", -- 163, 162, 165
	["0.545098, 0.435294, 0.376471"] = "Wood", -- 139, 111, 96
	["0.396078, 0.588235, 0.85098"] = "Tile", -- 110, 153, 202
	["0.388235, 0.372549, 0.384314"] = "Metal", -- 99, 95, 98
	["0.494118, 0.494118, 0.494118"] = "Metal", --126, 126, 126
	["0.658824, 0.666667, 0.65098"] = "Rock", -- 168, 170, 166 
	["0.0156863, 0.686275, 0.92549"] = "Water" -- 4, 175, 236
}

local function detectMaterial(hrp)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {hrp.Parent}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	local result = workspace:Raycast(hrp.Position, Vector3.new(0,-5,0), raycastParams)
	if (result) then
		--[[
		local _texture = hit:FindFirstChildWhichIsA("Texture")
		if (_texture.Texture == "http://www.roblox.com/asset/?id=5263575321") then -- if it's a plain texture, get the color of the texture
			local _found = materials[tostring(_texture.Color3)]
			return _found and _found or "Carpet"
		end]]
		local hit = result.Instance
		if (hit.Transparency == .5) then
			return "Metal" -- glass uses metal sound
		end
		local _found = materials[tostring(hit.Color)]
		return _found and _found or "Carpet"
	end
end

local function initializeSoundSystem(player, humanoid, rootPart)
	local oldSwimmingValue = false
	local isSwimming = player:WaitForChild("leaderstats"):WaitForChild("temp"):WaitForChild("isSwimming")
	local isClimbing = player:WaitForChild("leaderstats"):WaitForChild("temp"):WaitForChild("isClimbing")
	local sounds = {}
	-- initialize sounds
	for name, props in (SOUND_DATA) do
		local sound = Instance.new("Sound")
		sound.Name = name

		-- set default values
		sound.Archivable = false
		sound.EmitterSize = 5
		sound.MaxDistance = 150
		sound.Volume = 0.65
		
		for propName, propValue in (props) do
			sound[propName] = propValue
		end

		sound.Parent = rootPart
		sounds[name] = sound
	end
	
	local playingLoopedSounds = {}
	
	local function stopPlayingLoopedSounds(except)
		for sound in (shallowCopy(playingLoopedSounds)) do
			if sound ~= except then
				sound.Playing = false
				--sound.Volume = 0
				playingLoopedSounds[sound] = nil
			end
		end
	end
	
	local lastMaterial = sounds.Carpet
	-- state transition callbacks
	local stateTransitions = {
		[Enum.HumanoidStateType.FallingDown] = function()
			stopPlayingLoopedSounds()
		end,
		
		[Enum.HumanoidStateType.GettingUp] = function()
			stopPlayingLoopedSounds()
			playSound(sounds.GettingUp)
		end,
		
		[Enum.HumanoidStateType.Jumping] = function()
			sounds.Jumping.Volume = 1
			stopPlayingLoopedSounds()
			playSound(sounds.Jumping)
		end,
		
		["Swimming"] = function() -- use the default swim sounds
			if oldSwimmingValue ~= isSwimming.Value then
				sounds.Splash.Volume = math.clamp(rootPart.Velocity.Magnitude/150,0,.5)
				playSound(sounds.Splash)
			end
			if (isSwimming.Value) then
				stopPlayingLoopedSounds(sounds.Swimming)
				sounds.Swimming.Playing = true 
				playingLoopedSounds[sounds.Swimming] = true
			end
		end,
		
		[Enum.HumanoidStateType.Freefall] = function()
			sounds.FreeFalling.Volume = 0
			stopPlayingLoopedSounds(sounds.FreeFalling)
			playingLoopedSounds[sounds.FreeFalling] = true
			playSound(sounds.FreeFalling)
		end,
		
		[Enum.HumanoidStateType.Landed] = function()
			stopPlayingLoopedSounds() -- this stops the freefall sound
			local verticalSpeed = math.abs(rootPart.Velocity.Y)
			if verticalSpeed > 75 then
				sounds.Landing.Volume = math.clamp(map(verticalSpeed, 50, 100, 0, 1), 0, 1)
				playSound(sounds.Landing)
			end
		end,
		
		[Enum.HumanoidStateType.Running] = function(newSound) -- this only runs every time the state changes
			if (newSound) then
				newSound.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
				newSound.TimePosition = 0
				newSound.Playing = true
				playingLoopedSounds[newSound] = true -- add the index to the table of playing sounds
				stopPlayingLoopedSounds(newSound) -- removes the indexes of other material sounds except for the new material sound
			else -- play the lastMaterial sound
				lastMaterial.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
				lastMaterial.TimePosition = 0
				lastMaterial.Playing = true
				playingLoopedSounds[lastMaterial] = true
				stopPlayingLoopedSounds(lastMaterial)
			end
		end,
		
		[Enum.HumanoidStateType.Climbing] = function(newSound)
			if (newSound) then
				newSound.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
				if math.abs(rootPart.Velocity.Y) > 0.1 then
					newSound.Playing = true
					stopPlayingLoopedSounds(newSound)
				else
					stopPlayingLoopedSounds()
				end
				playingLoopedSounds[newSound] = true
			else -- play last material
				lastMaterial.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
				if math.abs(rootPart.Velocity.Y) > 0.1 then
					lastMaterial.Playing = true
					stopPlayingLoopedSounds(lastMaterial)
				else
					stopPlayingLoopedSounds()
				end
				playingLoopedSounds[lastMaterial] = true	
			end
		end,
		
		[Enum.HumanoidStateType.Physics] = function()
			stopPlayingLoopedSounds()
		end,
		
		[Enum.HumanoidStateType.Seated] = function()
			stopPlayingLoopedSounds()
		end,
		
		[Enum.HumanoidStateType.Dead] = function()
			stopPlayingLoopedSounds()
			--playSound(sounds.Died) -- don't play the death sound, the server will handle this
		end,
		
	}

	-- updaters for looped sounds
	local loopedSoundUpdaters = {
		[sounds.Climbing] = function(dt, sound, vel, humanoid)
			sound.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
			sound.Playing = vel.Magnitude > 0.1
		end,
		
		[sounds.FreeFalling] = function(dt, sound, vel, humanoid)
			local min = 50
			sound.PlaybackSpeed = math.clamp((vel.Magnitude/min),0,1)
			sound.Volume = sound.PlaybackSpeed *1.5
			--sound.Volume = math.clamp(sound.Volume + 0.9*dt, 0, 5)
		end,
		
		[sounds.Carpet] = function(dt, sound, vel, humanoid)
			sound.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
			sound.Playing = vel.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5
			sound.TimePosition = sound.Playing and sound.TimePosition or 0
			sound.Volume = 1
		end,
		[sounds.Rock] = function(dt, sound, vel, humanoid)
			sound.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
			sound.Playing = vel.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5
			sound.TimePosition = sound.Playing and sound.TimePosition or 0
			sound.Volume = .75
		end,
		[sounds.Grass] = function(dt, sound, vel, humanoid)
			sound.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
			sound.Playing = vel.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5
			sound.TimePosition = sound.Playing and sound.TimePosition or 0
		end,
		[sounds.Water] = function(dt, sound, vel, humanoid)
			sound.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
			sound.Playing = vel.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5
			sound.TimePosition = sound.Playing and sound.TimePosition or 0
		end,
		[sounds.Stone] = function(dt, sound, vel, humanoid)
			sound.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
			sound.Playing = vel.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5
			sound.TimePosition = sound.Playing and sound.TimePosition or 0
			sound.Volume = .75
		end,
		[sounds.Sand] = function(dt, sound, vel, humanoid)
			sound.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
			sound.Playing = vel.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5
			sound.TimePosition = sound.Playing and sound.TimePosition or 0
			sound.Volume = 1
		end,
		[sounds.Dirt] = function(dt, sound, vel, humanoid)
			sound.Playing = vel.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5
			sound.TimePosition = sound.Playing and sound.TimePosition or 0
			sound.Volume = 1
		end,
		[sounds.Wood] = function(dt, sound, vel, humanoid)
			sound.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
			sound.Playing = vel.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5
			sound.TimePosition = sound.Playing and sound.TimePosition or 0
			sound.Volume = .75
		end,
		[sounds.Tile] = function(dt, sound, vel, humanoid)
			sound.Playing = vel.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5
			sound.TimePosition = sound.Playing and sound.TimePosition or 0
		end,
		[sounds.Metal] = function(dt, sound, vel, humanoid)
			sound.PlaybackSpeed = math.clamp((humanoid.WalkSpeed/16)*1.85,0.925,2.775)
			sound.Playing = vel.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5
			sound.TimePosition = sound.Playing and sound.TimePosition or 0
			sound.Volume = .75
		end,
	}

	local running = false
	-- state substitutions to avoid duplicating entries in the state table
	local stateRemap = {
		[Enum.HumanoidStateType.RunningNoPhysics] = Enum.HumanoidStateType.Running,
	}

	local activeState = stateRemap[humanoid:GetState()] or humanoid:GetState()
	
	local stateChangedConn = humanoid.StateChanged:Connect(function(_, state)
		state = stateRemap[state] or state

		if state ~= activeState then
			local transitionFunc = stateTransitions[state]

			if transitionFunc then
				transitionFunc()
			end

			activeState = state
		end
		
	end)
	
	local function lerp(speedPercent, percent, divide)
		return speedPercent + (percent - speedPercent) * divide
	end
	--local _speed = 0
	--local mount
	local taggedTracks = {}
	
	local terminated = false
	
	local humanoidAncestryChangedConn
	local rootPartAncestryChangedConn
	local characterAddedConn

	local function terminate()
		--print("sounds terminated")
		terminated = true
		stateChangedConn:Disconnect()
		humanoidAncestryChangedConn:Disconnect()
		rootPartAncestryChangedConn:Disconnect()
		characterAddedConn:Disconnect()
	end

	humanoidAncestryChangedConn = humanoid.AncestryChanged:Connect(function(_, parent)
		if not parent then
			terminate()
		end
	end)

	rootPartAncestryChangedConn = rootPart.AncestryChanged:Connect(function(_, parent)
		if not parent then
			terminate()
		end
	end)

	characterAddedConn = player.CharacterAdded:Connect(terminate)
	
	local start = tick()
	
	while not (terminated) do
		task.wait(1/30) -- 30fps roughly
		local dt = (tick() - start) / (1/30)
		start = tick()
		stateTransitions["Swimming"]()
		oldSwimmingValue = isSwimming.Value
		--[[
		local anims = humanoid:GetPlayingAnimationTracks()
		local foundAnimationPlaying = false
		for index,track in (anims) do 
			
			local parent = track.Animation.Parent
			
			if parent ~= nil then
				if parent.Name == "punch" then
					print("punch anim detected")
				end
				if track.Length ~= 0 then
					if (track.Animation.AnimationId == "rbxassetid://8783867280") then
						foundAnimationPlaying = true
						if not taggedTracks[track] then
							taggedTracks[track] = true
							rootPart:WaitForChild("swing").TimePosition = 0
							rootPart:WaitForChild("swing"):Play()
						end
					elseif (track.Animation.AnimationId == "rbxassetid://8853655303") then
						foundAnimationPlaying = true
						if not taggedTracks[track] then
							taggedTracks[track] = true
							rootPart:WaitForChild("swing").TimePosition = 0
							rootPart:WaitForChild("swing"):Play()
						end
					end

					if parent:IsDescendantOf(rs:WaitForChild("animations"):WaitForChild("combat")) then
						foundAnimationPlaying = true
					end
					if parent.Name == "punch" then -- is child of punch, fully loaded, playing
						if not taggedTracks[track] then
							taggedTracks[track] = true
							local sounds = {
								[1] = rootPart:WaitForChild("swing_01"),
								[2] = rootPart:WaitForChild("swing_02"),
								[3] = rootPart:WaitForChild("swing_03")
							}
							sounds[math.random(1,3)]:Play()
						end
					elseif parent.Name == "bomb" then 
						if not taggedTracks[track] then
							taggedTracks[track] = true
							local sounds = {
								[1] = rootPart:WaitForChild("swing_01"),
								[2] = rootPart:WaitForChild("swing_02"),
								[3] = rootPart:WaitForChild("swing_03")
							}
							sounds[math.random(1,3)]:Play()
						end
					elseif parent.Name == "kick" then
						if not taggedTracks[track] then
							taggedTracks[track] = true
							rootPart:WaitForChild("kick_01"):Play()
						end
					elseif parent.Name == "tripWeb" then
						if not taggedTracks[track] then
							taggedTracks[track] = true
							rootPart:WaitForChild("swing").TimePosition = 0
							rootPart:WaitForChild("swing"):Play()
						end
					elseif parent.Name == "impact" then
						if not taggedTracks[track] then
							taggedTracks[track] = true
							
							rootPart:WaitForChild("shoot"):Play()
						end
					elseif parent.Name == "snare" then
						if not taggedTracks[track] then
							taggedTracks[track] = true
							rootPart:WaitForChild("snare"):Play()
						end
					end	
				end
			end
		end
		
		if not (foundAnimationPlaying) then
			taggedTracks = {}
		end
		]]
		if (activeState == Enum.HumanoidStateType.Physics) and not isSwimming.Value and not isClimbing.Value then -- check if swimming or flying
			activeState = Enum.HumanoidStateType.Freefall
			sounds.FreeFalling.Volume = 0
			stopPlayingLoopedSounds(sounds.FreeFalling)
			playingLoopedSounds[sounds.FreeFalling] = true
			playSound(sounds.FreeFalling)
		else
			-- add an echo for the footsteps if the player is in a certain location? maybe later
			local foundMaterial = sounds[detectMaterial(rootPart)]
			if (foundMaterial) then -- needs to be the sounds[materialName] instance
				if (foundMaterial ~= lastMaterial) then -- is different from the last material, play new sound, stop other sounds
					lastMaterial = foundMaterial
					if stateTransitions[activeState] ~= nil then
						stateTransitions[activeState](lastMaterial)
					end
				end
			end
			for sound in (playingLoopedSounds) do
				local updater = loopedSoundUpdaters[sound]
				if updater then
					updater(dt, sound, rootPart.Velocity, humanoid)
				end
			end			
		end
	end
end

local function playerAdded(player)
	local function characterAdded(character)
		-- Avoiding memory leaks in the face of Character/Humanoid/RootPart lifetime has a few complications:
		-- * character deparenting is a Remove instead of a Destroy, so signals are not cleaned up automatically.
		-- ** must use a waitForFirst on everything and listen for hierarchy changes.
		-- * the character might not be in the dm by the time CharacterAdded fires
		-- ** constantly check consistency with player.Character and abort if CharacterAdded is fired again
		-- * Humanoid may not exist immediately, and by the time it's inserted the character might be deparented.
		-- * RootPart probably won't exist immediately.
		-- ** by the time RootPart is inserted and Humanoid.RootPart is set, the character or the humanoid might be deparented.
		if not character.Parent then
			waitForFirst(character.AncestryChanged, player.CharacterAdded)
		end

		if player.Character ~= character or not character.Parent then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		while character:IsDescendantOf(game) and not humanoid do
			waitForFirst(character.ChildAdded, character.AncestryChanged, player.CharacterAdded)
			humanoid = character:FindFirstChildOfClass("Humanoid")
		end

		if player.Character ~= character or not character:IsDescendantOf(game) then
			return
		end

		-- must rely on HumanoidRootPart naming because Humanoid.RootPart does not fire changed signals
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		while character:IsDescendantOf(game) and not rootPart do
			waitForFirst(character.ChildAdded, character.AncestryChanged, humanoid.AncestryChanged, player.CharacterAdded)
			rootPart = character:FindFirstChild("HumanoidRootPart")
		end

		if rootPart and humanoid:IsDescendantOf(game) and character:IsDescendantOf(game) and player.Character == character then
			initializeSoundSystem(player, humanoid, rootPart)
		end
	end

	if (player.Character) then
		characterAdded(player.Character)
	end
	player.CharacterAdded:Connect(characterAdded)
end

Players.PlayerAdded:Connect(playerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	playerAdded(player)
end
