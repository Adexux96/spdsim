function getPriceFromLevel(level,base)
	local cost = 0
	for i = 1,level do
		cost = i > 1 and cost * 2 or cost + (base * i)
	end
	return cost
end

function getStat(level,base,multiplier)
	local b = base
	for i = 1,level-1 do
		local add = math.round(b * multiplier)
		b += add
	end
	return b + 25
end


function getSuitHealth(level)
	local b = 0
	for i = 1,level-1 do 
		local add = 100 
		b += add
	end
	return b + 25
end

function getSuitCrit(level)
	local b = 5
	for i = 1,level-1 do 
		local add = 2.5
		b+=add
	end
	return b
end

for i = 1,10 do 
	local extraHealth = getSuitHealth(i)
	local price = getPriceFromLevel(i,500)
	local crit = getSuitCrit(i)
	print("price = ",price)
	print("extra health = ",extraHealth)
	print("crit = ",crit)
end