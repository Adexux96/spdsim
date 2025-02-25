l=script:WaitForChild'Animation_Astronaut':clone()
workspace.DescendantAdded:connect(function(v)
if v.Name=='Animate' then
local c=l:clone()
c.Parent=v.Parent
v:Destroy()
wait()
c.Disabled=false
end
end)