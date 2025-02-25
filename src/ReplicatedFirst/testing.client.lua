
local impactWeb = workspace.ImpactWeb

local origin = Vector3.new(720.419, 100, -170)
local target = (CFrame.new(origin) * CFrame.new(0,200,-50)).Position

workspace.Offset.Position = origin
workspace.camPart.Position = target

local distance = (origin - target).Magnitude
local speed = 80

local startCF = CFrame.new(origin,target)
local endCF = startCF * CFrame.new(0,0,-distance)
impactWeb.CFrame = startCF

local elapsed = 0

local timer = (distance/speed) - elapsed
local start = tick()

local rs = game:GetService("RunService")

local endSize = Vector3.new(1.189, 1.163, 3.144)
local startSize = Vector3.new(0,0,0)

local function castRay()
	
end

local elapsed = 0
local sizeTimer = .2
local sizeTick = tick()

local drop = distance/2

local i = 0
while (tick() - start <= timer) do 
	i+=1
	if (tick() - sizeTick <= sizeTimer) then
		local p = math.clamp((tick() - sizeTick) / sizeTimer,0,1)
		impactWeb.Size = startSize:Lerp(endSize,p)
	end
	local p = math.clamp((tick() - start) / timer,0,1)
	local sine = math.sin((0.5 - p)*(math.pi * (math.clamp(distance,0,250)/1000)))
	local newEndCF = (endCF * CFrame.new(0,(sine*drop)/2,0))
	impactWeb.CFrame = CFrame.new(startCF:Lerp(newEndCF,p).Position,newEndCF.Position) * CFrame.Angles(0,0,math.rad(-((i-1)*5)))
	rs.RenderStepped:Wait()
end

print(math.abs(origin.Y - impactWeb.Position.Y))
