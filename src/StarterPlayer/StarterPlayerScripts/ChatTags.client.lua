local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local groupID = 3735300

local nameColors = { -- default colors for people without tags
	Color3.fromRGB(255, 0, 0),  -- Red
	Color3.fromRGB(0, 255, 0),  -- Green
	Color3.fromRGB(0, 0, 255),  -- Blue
}

local Tags = {
	[1] = {
		['CheckValidity'] = function(Player)
			local role = Player:GetRoleInGroup(groupID)
			if role == "Owner" then
				return {
					TagText = "[OWNER]",
					TagColor = "#95035d"
				}
			end
		end,
	},
	[2] = {
		['CheckValidity'] = function(Player)
			local role = Player:GetRoleInGroup(groupID)
			if role == "Developer" then
				return {
					TagText = "[DEV]",
					TagColor = "#32f3c9"
				}
			end
		end,
	},
	[3] = {
		['CheckValidity']=function(Player)
			local role = Player:GetRoleInGroup(groupID)
			if role == "Manager" then
				return {
					TagText= "[MANAGER]",
					TagColor= "#2d6dd6"
				}
			end
		end,
	},
	[4] = {
		['CheckValidity']=function(Player)
			local role = Player:GetRoleInGroup(groupID)
			if role == "Friend" then
				return {
					TagText= "[FRIEND]",
					TagColor= "#342941"
				}
			end
		end,
	},
	[5] = {
		['CheckValidity']=function(Player)
			local role = Player:GetRoleInGroup(groupID)
			if role == "Moderator" then
				return {
					TagText= "[MOD]",
					TagColor= "#d00000"
				}
			end
		end,
	},
	[6] = {
		['CheckValidity']=function(Player)
			local role = Player:GetRoleInGroup(groupID)
			if role == "Contributor" then
				return {
					TagText= "[CONTRIBUTOR]",
					TagColor= "#ff5500"
				}
			end
		end,
	},
	[7] = {
		['CheckValidity']=function(Player)
			local role = Player:GetRoleInGroup(groupID)
			if role == "Helper" then
				return {
					TagText= "[HELPER]",
					TagColor= "#ffff00"
				}
			end
		end,
	},
	[8] = {
		['CheckValidity']=function(Player)
			if Player.MembershipType == Enum.MembershipType.Premium then
				return {
					TagText= "[PREMIUM]",
					TagColor= "#ffff7f"
				}
			end
		end,
	},
	[9] = {
		['CheckValidity']=function(Player)
			local role = Player:GetRoleInGroup(groupID)
			if role == "Fan" then
				return {
					TagText= "[FAN]",
					TagColor= "#059bff"
				}
			end
		end,
	}
}

TextChatService.OnIncomingMessage = function(message)
	local properties = Instance.new("TextChatMessageProperties")

	if message.TextSource then
		local player = Players:GetPlayerByUserId(message.TextSource.UserId)
		if player then
			local nameColor
			local tagApplied = false

			for _, tagConfig in ipairs(Tags) do
				local tagData = tagConfig.CheckValidity(player)
				if tagData then
					tagApplied = true
					nameColor = Color3.fromHex(tagData.TagColor)
					properties.PrefixText = string.format( --sets tag of the user and the color of the tag
						'<font color="%s">%s</font> ',
						tagData.TagColor,
						tagData.TagText 
					)
					break
				end
			end

			if not tagApplied then
				local index = (player.UserId % #nameColors) + 1
				nameColor = nameColors[index]
			end

			properties.PrefixText = properties.PrefixText .. string.format( --displays username color of the tag
				'<font color="#%s">%s</font>: ',
				nameColor:ToHex(),
				player.DisplayName
			)
		end
	end

	return properties
end