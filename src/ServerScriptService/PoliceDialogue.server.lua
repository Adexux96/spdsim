local rs=game:GetService("ReplicatedStorage")
local dialogueEvent=rs.DialogueEvent

local items=require(rs.items)

local cop=workspace.Cop
local proximityPrompt=cop.PrimaryPart.ProximityPrompt

dialogueEvent.OnServerEvent:Connect(function(player,new) -- player wants to change their objective
	local leaderstats=player.leaderstats
	local objectives=leaderstats.objectives
	local current=objectives.current
	local completed=objectives.completed
	local amount=objectives.amount
	if new>current.Value and completed.Value==false then
		return -- can't skip if haven't completed all misions
	end
	current.Value=new
	amount.Value=0
end)

local function PromptTriggered(plr)
	local lastTrigger=plr:GetAttribute("lastTalk")
	if not lastTrigger then
		local stamp=tick()-1
		plr:SetAttribute("lastTalk",stamp)
		lastTrigger=stamp
	end
	local elapsed=tick()-lastTrigger
	if elapsed<1 then return end -- 1 sec cooldown
	plr:SetAttribute("lastTalk",tick())
	local headCFrame=cop.PrimaryPart.CFrame*CFrame.new(0,1,-5)
	dialogueEvent:FireClient(plr,CFrame.new(headCFrame.Position,(cop.PrimaryPart.CFrame*CFrame.new(0,1,0)).Position))
	local leaderstats=plr:WaitForChild("leaderstats")
	local objectives=leaderstats:WaitForChild("objectives")
	local current_objective=objectives:WaitForChild("current")
	if current_objective.Value>#items.objectives then return end
	objectives:WaitForChild("talkedWithPolice").Value=true
	if items.objectives[current_objective.Value].title=="Talk with police officer" then
		current_objective.Value+=1
	end
end

proximityPrompt.Triggered:Connect(PromptTriggered)

