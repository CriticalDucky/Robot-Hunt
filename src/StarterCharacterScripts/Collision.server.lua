local character = script.Parent

for _, v in ipairs(character:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CollisionGroup = "Character"
	end
end


