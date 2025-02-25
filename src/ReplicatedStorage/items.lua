local items = {
	SuitSprites = {
		page1="rbxassetid://13786644415",
		page2="rbxassetid://12501882932",
		page3="rbxassetid://12501884851",
		page4="rbxassetid://12501887038",
		page5="rbxassetid://13104853966",
		page6="rbxassetid://13787666703",
		page7="rbxassetid://13786682639",
		page8="rbxassetid://89264359095124"
	},
	Special = {
		["Web Bomb"] = {
			desc = {
				[1] = "An explosive with a range of 50 studs that deals ",
				[2] = " damage."
			},
			misc = { -- base + ((multiplier * level) - multiplier)
				[1] = {  -- 925 damage
					base = 100,
					multiplier = 75,
				}
			},
			upgrade = 3000,
			order = 1,
			cost = 100000,
			offset = Vector2.new(128,128),
			category = "Special",
			comicPops = {"bam!","pow!","oof!","yow!"}
		},
		["Spider Drone"] = {
			desc = {
				[1] = "Spawns a robot drone that has ",
				[2] = " health and deals ",
				[3] = " damage."
			},
			misc = {
				[1] = { -- 1,025 health
					base = 200,
					multiplier = 75                                
				},
				[2] = { -- 925 damage
					base = 100,
					multiplier = 75
				}
			},
			upgrade = 3000,
			order = 2,
			cost = 100000,
			offset = Vector2.new(384,128),
			category = "Special",
			comicPops = {"zap!"}
		},
		["Gauntlet"] = {
			desc = {
				[1] = "A powerful gauntlet that has ",
				[2] = " range and deals ",
				[3] = " damage. (Takes 33% of health)"
			},
			misc = {
				[1] = { -- 320 max range
					base = 100,
					multiplier = 20                
				},
				[2] = { -- 3200 max damage
					base = 1000,
					multiplier = 200                        
				},
			},
			upgrade = 50000, --+250k
			order = 3,
			cost = 1000000,
			offset = Vector2.new(0,384),
			category = "Special",
			comicPops = {"zap!"}
		}
	},
	Melee = {
		["Punch"] = {
			desc = {
				[1] = "A punch that deals ",
				[2] = " damage and can combo."
			},
			misc = {
				[1] = { -- 65 damage
					base = 10,
					multiplier = 5
				}
			},
			upgrade = 250,
			order = 1,
			cost = 0,
			offset = Vector2.new(0,0),
			category = "Melee",
			comicPops = {"bam!","pow!","oof!","yow!"}
		},
		["Kick"] = {
			desc = {
				[1] = "A kick that deals ",
				[2] = " damage and can combo."
			},
			misc = {
				[1] = { -- 200 damage
					base = 24,
					multiplier = 16
				}
			},
			upgrade = 1000,
			order = 2,
			cost = 10000,
			offset = Vector2.new(0,256),
			category = "Melee",
			comicPops = {"bam!","pow!","oof!","yow!"}
		},
		["360 Kick"] = {
			desc = {
				[1] = "A spinning kick that deals ",
				[2] = " damage to nearby enemies and can combo."
			},
			misc = {
				[1] = { -- 400 damage
					base = 48,
					multiplier = 32
				}
			},
			upgrade = 2500,
			order = 3,
			cost = 25000,
			offset = Vector2.new(128,256),
			category = "Melee",
			comicPops = {"bam!","pow!","oof!","yow!"}
		}
	},
	Ranged = {
		["Impact Web"] = {
			desc = {
				[1] = "Shoots a web projectile that deals ",
				[2] = " damage and can combo."
			},
			misc = {
				[1] = { -- 65 damage
					base = 10,
					multiplier = 5
				},
			},
			upgrade = 500,
			order = 1,
			cost = 0,
			offset = Vector2.new(384,256),
			category = "Ranged",
			comicPops = {"bam!","pow!","oof!","yow!"}
		},
		["Shotgun Webs"] = {
			desc = {
				[1] = "Shoots 3 web projectiles that deal ",
				[2] = " damage each and can combo."
			},
			misc = {
				[1] = { -- 67 damage
					base = 12,
					multiplier = 5
				}
			},
			upgrade = 3500,
			order = 2,
			cost = 100000,
			offset = Vector2.new(128,0),
			category = "Ranged",
			comicPops = {"bam!","pow!","oof!","yow!"},
		},
		["Snare Web"] = {
			desc = {
				[1] = "Shoots a web projectile that stuns the victim for ",
				[2] = "",
				[3] = " seconds."
			},
			misc = {
				[1] = { -- damage
					base = 0,
					multiplier = 0
				},
				[2] = {
					base = 3,
					multiplier = .5
				},
			},
			upgrade = 12500, --x10
			order = 3,
			cost = 250000, -- x10
			offset = Vector2.new(384,0),
			category = "Ranged",
			comicPops = {"bam!","pow!","oof!","yow!"}
		},
	},
	Travel = {
		["Swing Web"] = {
			desc = {
				[1] = "Shoots a swing web with a speed of ",
				[2] = " studs per second."
			},
			misc = {
				[1] = { -- 175 speed
					base = 120,
					multiplier = 2
				}
			},
			upgrade = 250,
			order = 1,
			cost = 0,
			offset = Vector2.new(0,128),
			category = "Travel"
		},
		["Launch Webs"] = {
			desc = {
				[1] = "Shoots 2 pull webs with a speed of ",
				[2] = " studs per second."
			},
			misc = {
				[1] = { -- 200 speed
					base = 145,
					multiplier = 5
				}
			},
			upgrade = 500,
			order = 2,
			cost = 25000,
			offset = Vector2.new(256,0),
			category = "Travel"
		}
	},
	Traps = {
		["Trip Web"] = {
			desc = {
				[1] = "Set up to ",
				[2] = " trip web(s) that trip the victim for 3 seconds."
			}, -- default: 1 wire trap(s)
			misc = {
				[1] = { -- 12
					base = 1,
					multiplier = 1
				},
			},
			upgrade = 5000,
			order = 1,
			cost = 25000,
			offset = Vector2.new(256,256),
			category = "Traps"
		},
		["Anti Gravity"] = {
			desc = {
				[1] = " Anti gravity field with a range of ",
				[2] = " studs that lasts 8 seconds."
			},
			misc = {
				[1] = { -- 50
					base = 17,
					multiplier = 3
				},
			},
			upgrade = 12500,
			order = 2,
			cost = 250000,
			offset = Vector2.new(256,128),
			category = "Traps"
		}
	},

	Portals = {
		["bat"]=2,--0,
		["ak"]=4,--125,
		["shotgun"]=6,--250,
		["flamethrower"]=8,--500,
		["electric"]=10,--1000,
		["brute"]=12,--2000,
		["minigun"]=14--4000
	},        

	Skins = {
		["Classic"] = {
			cost = 0,
			upgrade = 1000,
			offset = Vector2.new(0,256),
			image = "page1",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Gwen"] = {
			cost = 0,
			upgrade = 1000,
			offset = Vector2.new(0,0),
			image = "page2",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Mayday Parker"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(0,256),
			image = "page6",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Spider Woman"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(256,256),
			image = "page7",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["ATSV India"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(256,0),
			image = "page6",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["ATSV 2099"] = {
			cost = 15000,
			upgrade = 1000,
			offset = Vector2.new(0,0),
			image = "page6",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["ATSV Punk"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(256,0),
			image = "page7",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Miles 2099"] = {
			cost = 15000,
			upgrade = 1000,
			offset = Vector2.new(256,256),
			image = "page6",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["ATSV Scarlet"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(0,256),
			image = "page7",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["ATSV Miles"] = {
			cost = 15000,
			upgrade = 1000,
			offset = Vector2.new(0,0),
			image = "page7",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Damage Control"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(256,0),
			image = "page2",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Homecoming"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(0,0),
			image = "page1",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Far From Home"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(256,0),
			image = "page4",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["No Way Home"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(0,0),
			image = "page4",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Yellow Jacket"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(256,256),
			image = "page4",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Scarlet"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(256,256),
			image = "page3",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Homemade"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(256,256),
			image = "page2",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Punk"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(0,256),
			image = "page4",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Miles Classic"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(0,256),
			image = "page2",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Miles"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(256,256),
			image = "page1",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Advanced"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(0,0),
			image = "page3",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Noir"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(256,0),
			image = "page1",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Symbiote"] = {
			cost = 25000,
			upgrade = 1000,
			offset = Vector2.new(256,0),
			image = "page3",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Iron Spider"] = {
			cost = 50000,
			upgrade = 1000,
			offset = Vector2.new(0,256),
			image = "page3",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Miles Spider Verse"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(0,0),
			image = "page5",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Spider Girl"] = {
			cost = 10000,
			upgrade = 1000,
			offset = Vector2.new(256,0),
			image = "page5",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Stealth"] = {
			cost = 0,
			upgrade = 1000,
			offset = Vector2.new(0,256),
			image = "page5",
			unlock="Complete all objectives",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Spectacular"] = {
			cost = 0,
			upgrade = 1000,
			offset = Vector2.new(0,0),
			image = "page8",
			unlock="Obtain it in a spin",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Black Spectacular"] = {
			cost = 0,
			upgrade = 1000,
			offset = Vector2.new(256,0),
			image = "page8",
			unlock="Obtain it in a spin",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
		["Supreme Sorcerer"] = {
			cost = 0,
			upgrade = 1000,
			offset = Vector2.new(256,256),
			image = "page5",
			unlock="Achieve 10 rebirths",
			desc = {
				[1] = " This suit gives you ",
				[2] = " critical chance and ",
				[3] = " health."
			},
		},
	},

	boss_image_offsets={
		["Green Goblin"]={
			offset=Vector2.new(32,32),
			size=Vector2.new(64,64)
		},
		["Venom"]={
			offset=Vector2.new(160,32),
			size=Vector2.new(64,64)
		} ,
		["Doc Ock"]={
			offset=Vector2.new(256,0),
			size=Vector2.new(128,128)
		} 
	},

	objectives={
		[1]={
			title="Talk with police officer",
			amount=0,
			reward=0,
			dialogue="Hello there! I'm getting reports that a group of thugs armed with bats are taking over an area of the city and I need your help to defeat them! Use the portal to quick travel.",
			offset=Vector2.new(384,0),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category=false,
			name="police"
		},
		[2]={
			title="Defeat thugs: ",
			amount=12,
			reward=500,
			dialogue=false,
			offset=Vector2.new(0,0),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category="bat",
			name="bat"
		},
		[3]={
			title="Talk with police officer",
			amount=0,
			reward=0,
			dialogue="Good work! I'm getting new reports that a group of thugs armed with assault rifles are taking over an area of the city and I need your help to defeat them! Use the portal to quick travel.",
			offset=Vector2.new(384,0),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category=false,
			name="police"
		},
		[4]={
			title="Defeat thugs: ",
			amount=12,
			reward=1000,
			dialogue=false,
			offset=Vector2.new(128,0),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category="ak",
			name="ak"
		},
		[5]={
			title="Talk with police officer",
			amount=0,
			reward=0,
			dialogue="Well done! I'm getting new reports that a group of thugs armed with shotguns are taking over an area of the city and I need your help to defeat them! Use the portal to quick travel.",
			offset=Vector2.new(384,0),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category=false,
			name="police"
		},
		[6]={
			title="Defeat thugs: ",
			amount=12,
			reward=2000,
			dialogue=false,
			offset=Vector2.new(256,0),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category="shotgun",
			name="shotgun"
		},
		[7]={
			title="Talk with police officer",
			amount=0,
			reward=0,
			dialogue="Splendid job! I'm getting new reports that a group of thugs armed with flamethrowers are taking over an area of the city and I need your help to defeat them! You can roll to avoid taking damage.",
			offset=Vector2.new(384,0),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category=false,
			name="police"
		},
		[8]={
			title="Defeat thugs: ",
			amount=12,
			reward=4000,
			dialogue=false,
			offset=Vector2.new(0,128),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category="flamethrower",
			name="flamethrower"
		},
		[9]={
			title="Talk with police officer",
			amount=0,
			reward=0,
			dialogue="Great job! I'm getting new reports that a group of thugs armed with electric batons are taking over an area of the city and I need your help to defeat them! You can roll to avoid taking damage.",
			offset=Vector2.new(384,0),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category=false,
			name="police"
		},        
		[10]={
			title="Defeat thugs: ",
			amount=12,
			reward=8000,
			dialogue=false,
			offset=Vector2.new(128,128),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category="electric",
			name="electric"
		},
		[11]={
			title="Talk with police officer",
			amount=0,
			reward=0,
			dialogue="Good job! I'm getting new reports that a group of brute thugs are taking over an area of the city and I need your help to defeat them! You can roll to avoid taking damage.",
			offset=Vector2.new(384,0),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category=false,
			name="police"
		},        
		[12]={
			title="Defeat thugs: ",
			amount=12,
			reward=16000,
			dialogue=false,
			offset=Vector2.new(256,128),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category="brute",
			name="brute"
		},
		[13]={
			title="Talk with police officer",
			amount=0,
			reward=0,
			dialogue="Good work! I have reports that a group of fisk thugs are taking over an area of the city and I need your help to defeat them! You can roll to avoid taking damage.",
			offset=Vector2.new(384,0),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category=false,
			name="police"
		},        
		[14]={
			title="Defeat thugs: ",
			amount=12,
			reward=32000,
			dialogue=false,
			offset=Vector2.new(384, 128),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category="minigun",
			name="minigun"
		},                
		[15]={
			title="Talk with police officer",
			amount=0,
			reward=0,
			dialogue="Nice job! You're stronger now than ever before, portals are opening up around the city! We need your help clearing the streets of monsters that come through the portals!",
			offset=Vector2.new(384,0),
			image="rbxassetid://14079536116",
			imageSize=Vector2.new(128, 128),
			category=false,
			name="police"
		},
		[16]={
			title="Defeat villains: ",
			amount=12,
			reward=100000,
			dialogue=false,
			offset=Vector2.new(32,32),
			image="rbxassetid://119079023691647",
			imageSize=Vector2.new(64,64),
			category=false,
			name="villain"
		},
	}
}
return items



