local portal=workspace:WaitForChild("Portal")
local rings= portal:WaitForChild("Rings")
local part=portal:WaitForChild("Part")

local function glitch_ring(ring,start,goal)
	
	ring:WaitForChild("glitch_red").CFrame=start:Lerp(goal,.33)
	ring:WaitForChild("glitch_blue").CFrame=start:Lerp(goal,.66)
	ring:WaitForChild("glitch_black").CFrame=goal
	
	for i,v in ring:GetChildren() do 
		if v:IsA("ParticleEmitter") then
			v:Emit(1)
		end
	end
end

local function toggle_glitch(ring,toggle) -- adjust visibility of the glitch
	
	ring.Transparency=toggle and 1 or 0
	ring:WaitForChild("backUI").Enabled=not toggle
	ring:WaitForChild("frontUI").Enabled=not toggle
	
	ring:WaitForChild("glitch_red").Transparency=toggle and 0.5 or 1
	ring:WaitForChild("glitch_blue").Transparency=toggle and 0.5 or 1
	ring:WaitForChild("glitch_black").Transparency=toggle and 0.5 or 1
	--[[
	for i,v in ring.glitch_red:GetChildren() do 
		v.Enabled=toggle
	end
	
	for i,v in ring.glitch_blue:GetChildren() do 
		v.Enabled=toggle
	end
	for i,v in ring.glitch_black:GetChildren() do 
		v.Enabled=toggle
	end
	]]
end

local times=1
local function glitch(ring1,ring2)
	-- make the part move and don't let it rotate while it's like this
	
	local sounds={
		[1]=part:WaitForChild("glitch_01"),
		[2]=part:WaitForChild("glitch_02"),
		[3]=part:WaitForChild("glitch_03")
	}
	
	sounds[math.random(1,3)]:Play()
	
	toggle_glitch(ring1,true)
	
	local offset=Vector3.new(0,math.random(1,5),math.random(1,5))
	local start=ring1.CFrame
	local goal=start*CFrame.new(offset)
	
	glitch_ring(ring1,start,goal)
	task.wait(.05) -- wait a bit
	
	toggle_glitch(ring1,false)
	times+=1
	
	if times<=3 then
		task.wait(.025)
		glitch(rings[tostring(times)])
	end
	
	times=0
	-- second ring glitch
	--[[
	toggle_glitch(ring2,true)
	local offset=Vector3.new(0,math.random(1,5),math.random(1,5))
	start=ring2.CFrame
	goal=start*CFrame.new(offset)

	glitch_ring(ring2,start,goal)
	task.wait(.1) -- wait a bit
	
	toggle_glitch(ring2,false)
	]]
end

local function rotate_rings(p,elapsed)
	for i,ring in rings:GetChildren() do 
		local rotation=i%2==0 and -1 or 1
		rotation=rotation/10
		-- how to make the inner circle move faster than the outer one?
		local f_outer = ring:WaitForChild("frontUI").outer
		local b_outer = ring:WaitForChild("backUI").outer
		local f_inner = ring:WaitForChild("frontUI").inner
		local b_inner = ring:WaitForChild("backUI").inner
		
		ring.CFrame*=CFrame.fromOrientation(math.rad(rotation*tonumber(ring.Name)),0,0)
		f_outer:WaitForChild("top").UIGradient.Rotation=(900*rotation)*p
		f_inner:WaitForChild("UIGradient").Rotation=(900*rotation)*p
		b_inner:WaitForChild("UIGradient").Rotation=(900*rotation)*p
		b_outer:WaitForChild("top"):WaitForChild("UIGradient").Rotation=(900*rotation)*p
		
		local t=math.clamp(math.sin(elapsed/1),.5,1)
		f_outer.ImageTransparency=t
		f_outer:WaitForChild("top").ImageTransparency=t
		b_outer.ImageTransparency=t
		b_outer:WaitForChild("top").ImageTransparency=t
	end
end

local dt=tick()
local last_glitch=tick()

local swirl=part:WaitForChild("Attachment"):WaitForChild("swirly_vortex")
local traces=part:WaitForChild("Traces")

swirl.Enabled=false
swirl:WaitForChild("tick").Value=tick()
traces.Enabled=false
traces:WaitForChild("tick").Value=tick()

while true do 
	local elapsed=tick()-dt
	local progress=math.clamp(elapsed/math.huge,0,1) -- 5 seconds
	rotate_rings(progress,elapsed)
	if tick()-last_glitch>5 and math.random(1,100) <= 30 then
		last_glitch=tick()
		task.spawn(glitch,rings:WaitForChild("1"),rings:WaitForChild("2"))
	end
	--print(progress)
	for _,particle in {swirl,traces} do
		local t=particle:WaitForChild("tick")
		local elapsed=tick()-t.Value
		local rate=particle.Rate
		local limit = (60/particle.Rate) * (1/60)
		if elapsed>=limit then
			t.Value=tick()
			particle:Emit(1)
		end
	end
	if progress==1 then break end
	task.wait()
end