local r = math.random
local rs = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera

local m = {}

local rng = Random.new(tick())

function m.linear(x)
	return rng:NextNumber(-x,x)
end

function colorToVertex(color)
	return Vector3.new(color.R/255 + 1,color.G/255 + 1,color.B/255 + 1)
end
--print(colorToVertex(Color3.fromRGB(143, 76, 42)))

function m.invertColor(color)
	local r,g,b = color.R*255, color.G*255, color.B*255
	return 255-r,255-g,255-b
end

function m.getSuitHealth(level)
	local b = 0
	for i = 1,level-1 do 
		local add = 50 + (10*i)
		b += add
	end
	return b + 25
end

function m.getSuitCrit(level)
	local b = 5
	for i = 1,level-1 do 
		local add = 3.5
		b+=add
	end
	return b
end

function m.lerp(start,goal,alpha)
	return ((goal-start)*alpha)+start
end

--[[
function m.getStat(level,base,multiplier)
	local b = base
	for i = 1,level-1 do
		local add = math.round(b * multiplier)
		b += add
	end
	return b
end

function m.getRebirth(rebirths)
	local base = 250
	local cost = base
	for i = 1,rebirths do 
		cost *= 2 + (cost * .104)
	end
	return cost
end
]]

function m.getStat(level,base,multiplier)
	local b = base
	for i = 1,level-1 do
		local add = multiplier--math.round(b * multiplier)
		b += add
	end
	return math.round(b*100)/100
end

--[[
function getStat(level,base,multiplier)
	local b = base
	for i = 1,level-1 do
		local add = multiplier--math.round(b * multiplier)
		b += add
	end
	return math.round(b)
end
print(getStat(12,100,20))
]]

function m.getRebirthPrice(rebirths)
	local base = 100000
	local cost = 0
	for i = 1,rebirths+1 do 
		cost += (cost * .25)
		cost = math.clamp(cost,base,math.huge)
	end
	return math.round(cost)	
end

function m.getPriceFromLevel(level,base)
	local cost = base
	local increase = base --+ (base*.2)
	for i = 1,level do
		--cost = i > 1 and cost * 2 or cost + (base * i)
		cost += ((i-1) * increase)
	end
	return math.round(cost)
end

--[[
function getPriceFromLevel(level,base)
	local cost = base
	local increase = base --+ (base*.2)
	for i = 1,level do
		--cost = i > 1 and cost * 2 or cost + (base * i)
		cost += ((i-1) * increase)
	end
	return math.round(cost)
end

print(getPriceFromLevel(23,50000))

local level=11
local base=2000
local cost=25000
for i=1,level do 
	cost+=getPriceFromLevel(i,base)
end
print(cost)
]]

function m.getOrientationFromCFrame(cframe)
	local x,y,z = cframe:ToOrientation()
	return math.deg(x),math.deg(y),math.deg(z)
end

function m.clampMagnitude(v, max)
	if (v.magnitude == 0) then return Vector3.new(0,0,0) end -- prevents NAN,NAN,NAN
	return v.Unit * math.min(v.Magnitude, max) 
end

function m.defined(x,y)
	return rng:NextNumber(x,y)
end

function m.least(a,b)
	return a[1] < b[1]
end

function m.greatest(a,b)
	return a[1] > b[1]
end

function m.nearest(n)
	return n < 0 and math.ceil(n-0.5) or math.floor(n+0.5)
end

function m.setNodes(position,size,nodeAmount,rowAmount)
	local nodesInRow = nodeAmount/rowAmount
	if math.floor(nodesInRow) ~= nodesInRow then
		--print("node amount must be evenly divisible by the row amount!")
		return
	end
	if (nodeAmount <= rowAmount) then
		--print("node amount must be greater than row amount!")
		return
	end
	local row = 0
	local distanceX = size.X/(nodesInRow-1)
	local distanceZ = size.Z/(rowAmount-1)
	--print("distanceX = ",distanceX)
	--print("distanceZ = ",distanceZ)
	local upperLeft = Vector3.new((position.X - (size.X/2)),position.Y,(position.Z - (size.Z/2)))
	for i = 1,nodeAmount do
		row = ((i-1)%nodesInRow == 0) and row + 1 or row
		local folder = Instance.new("Folder",workspace)
		local part = Instance.new("Part")
		part.Name = i
		part.Size = Vector3.new(1,1,1)
		part.Color = Color3.fromRGB(0,0,0)
		part.Position = upperLeft + Vector3.new(((i-1)%nodesInRow)*distanceX, 0, (row-1)*distanceZ)
		part.Parent = folder
	end	
	return
end

function m.checkBounds2D(arg,pointX,pointY)
	if (type(arg) == "table") then
		local pos,size = arg[1],arg[2]
		local isWithinX = (pointX >= pos.X) and (pointX <= (pos.X + size.X))
		local isWithinY = (pointY >= pos.Y) and (pointY <= (pos.Y + size.Y))
		return isWithinX and isWithinY
	else
		local pos,size = arg.AbsolutePosition,arg.AbsoluteSize
		local isWithinX = (pointX >= pos.X) and (pointX <= (pos.X + size.X))
		local isWithinY = (pointY >= pos.Y) and (pointY <= (pos.Y + size.Y))
		return isWithinX and isWithinY	
	end
end

function m.giveNumberCommas(number)
	local formatted = number
	local k
	while true do 
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1 %2')
		if (k==0) then
			break
		end
	end
	return formatted
end

function m.negOrPos(n)
	local nums = {-n,n}
	return nums[rng:NextInteger(1,2)]
end

function m.getNumber(n)
	local converted = m.negOrPos(n)
	if (converted > 0) then -- positive, subtract
		return(m.defined(converted,converted-2))
	else -- negative, add
		return(m.defined(converted,converted+2))
	end
end

local suffixes = {"K", "M", "B", "T", "Q"} -- numbers don't go higher than 'Q' in Lua.

function m.toSuffixString(n)
	if n==0 then return tostring(0) end
	local i = math.floor(math.log(n, 1e3))
	local v = math.pow(10, i * 3)
	local s=("%.1f"):format(n / v):gsub("%.?0+$", "") .. (suffixes[i] or "")
	return s
end

function m.darkenColor(color)
	if not (typeof(color) == "Color3") then return end
	local h, s, v = Color3.toHSV(color) -- convert to hsv
	local v2 = math.clamp(v*.435643,0,1)
	return Color3.fromHSV(h,s,v2) -- convert back to rgb
end

function m.setColorData(model,colorData)
	for _,item in pairs(model:GetChildren()) do
		local color3Value = item:FindFirstChildOfClass("Color3Value")
		if (color3Value) then -- this item can be colored, get the data and apply the color
			local colorData = colorData[color3Value.Name]
			local color = Color3.fromRGB(colorData.r,colorData.g,colorData.b)
			item.Color = color
		end
	end
end

function m.getColorData(model)
	local t = {}
	for i,v in pairs(model:GetChildren()) do
		if v:IsA("BasePart") then
			local color3Value = v:FindFirstChildWhichIsA("Color3Value")
			if (color3Value) then -- found a part that can be colored
				if not (t[color3Value.Name]) then -- if there isn't a listing for it already
					t[color3Value.Name] = {r = m.nearest(v.Color.R*255), g = m.nearest(v.Color.G*255), b = m.nearest(v.Color.B*255)}
				end
			end
		end
	end
	return t -- this returns the table of the parts and the colors associated
end

function m.serialize(dormPrimaryPart, model) -- get the model and get the dormPrimaryPart you're loading into.
	local serial = {}

	local cfi = dormPrimaryPart.CFrame:Inverse()
	for i,v in pairs(model) do
		serial[v.Name] = tostring(cfi * v.PrimaryPart.CFrame)
	end

	return serial -- this is the CFrame data with the model name
end

function m.roundDecimals(x, n) 
	return math.floor(x * 10^n) / (10^n)
end

function m.deSerialize(dorm, modelName, cframe) -- dorm model, furniture name, furniture cframe
	local model = rs:WaitForChild("furniture"):FindFirstChild(modelName)
	if (model) then
		local components = {}
		for num in string.gmatch(cframe, "[^%s,]+") do
			components[#components+1] = tonumber(num)
		end
		local NewModel = model:Clone()
		local stuff = dorm:WaitForChild("stuff")
		local interactable = stuff:WaitForChild("interactable")
		local guiPart = NewModel:FindFirstChild("guiPart")
		if (guiPart) then
			local subLocation,mainLocation = guiPart:WaitForChild("subLocation"),guiPart:WaitForChild("mainLocation")
			mainLocation.Value = "dorms" -- just mainLocation for now, unless you decide to make sublocations inside dorms
		end
		NewModel.Parent = guiPart and interactable or stuff
		NewModel:SetPrimaryPartCFrame(dorm.PrimaryPart.CFrame * CFrame.new(unpack(components)))		
	end
end

function m.checkBounds(cframe,size,pos) -- cframe of the hitbox, size of hitbox, foreign position to check
	local relativePoint = cframe:Inverse() * pos
	local isInsideHitbox = true
	local axisTable = {
		[1] = "X",
		[2] = "Y",
		[3] = "Z"
	}
	for i = 1,#axisTable do
		local axis = axisTable[i]
		if math.abs(relativePoint[axis]) > size[axis]/2 then
			isInsideHitbox = false
			break
		end
	end
	return isInsideHitbox	
end

function m.checkTriangleBounds2D()

end

--[[
function m.checkLocation(characterPosition) -- this functions checks for if your camera and hrp are within certain locations
	local main,sub,meta,characterLocation = "outside","","","outside"
	for name,location in pairs(locations) do
		if (name ~= "outside") then
			if (m.checkBounds(location.cframe,location.size,camera.CFrame.Position)) then
				main = name
			end
			if (m.checkBounds(location.cframe,location.size,characterPosition)) then
				if (name == "lake") then

				end
				characterLocation = name
			end
		end
	end
	if (main) then
		if (locations[main].subLocations) then
			for name,location in pairs(locations[main].subLocations) do
				if (m.checkBounds(location.cframe,location.size,camera.CFrame.Position)) then
					sub = name
				end
			end
		end
	end
	return main,sub,meta,characterLocation
end]]

function m.returnTheta(startPos,endPos,axis)
	local adjascent = (startPos[axis] - endPos[axis]) -- greater number always first
	local hypotenuse = (startPos-endPos).magnitude
	return math.deg(math.acos(adjascent/hypotenuse))
end

script.loaded.Value=true

return m

