local txt={}

local function RipID(id,origin)
	local actual,amount=string.gsub(id, "%D", "")
	if actual=="" then return end -- invalid data
	if txt[actual] then return end -- already has that id in the database
	txt[actual]=origin
end

local _types={
	--[[
	["ImageLabel"]=function(object)
		RipID(object.Image,"Image")
	end,
	["ImageButton"]=function(object)
		RipID(object.Image,"Image")
	end,
	["MeshPart"]=function(object)
		RipID(object.MeshId,"MeshId")
		RipID(object.TextureID,"TextureId")
	end,
	["Sound"]=function(object)
		RipID(object.SoundId,"SoundId")
	end,
	["ParticleEmitter"]=function(object)
		RipID(object.Texture,"Texture")
	end,
	["Beam"]=function(object)
		RipID(object.Texture,"Texture")
	end,
	["Trail"]=function(object)
		RipID(object.Texture,"Texture")
	end,
	["Animation"]=function(object)
		RipID(object.AnimationId,"AnimationId")
	end,
	["Texture"]=function(object)
		RipID(object.Texture,"Texture")
	end,
	]]
	["Shirt"]=function(object)
		RipID(object.ShirtTemplate,"Shirt")
	end,
	["Pants"]=function(object)
		RipID(object.PantsTemplate,"Pants")
	end,
}

for i,v in game:GetDescendants() do 
	if i%300==0 then print("yielding thread") task.wait() end
	local f=_types[v.ClassName]
	if not f then continue end
	f(v)
end

local s=""
for i,v in txt do
	s=s.."\n"..i.." , "..v
end
print(s)