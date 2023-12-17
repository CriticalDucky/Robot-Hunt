local Math = {}

function Math.weightedChance(rarities, presetRandom) -- takes in a table of rarities and returns a random index based on the rarities. if the rarities table is empty, returns nil
	local raritiesIsEmpty
	do
		raritiesIsEmpty = true

		for _ in pairs(rarities) do
			raritiesIsEmpty = false
		end
	end

	if raritiesIsEmpty then return nil end

	local total = 0

	for _, rarity in pairs(rarities) do
		total = total + rarity
	end

	local random = (presetRandom or math.random()) * total
	local index = 1

	for i, rarity in pairs(rarities) do
		random = random - rarity

		if random <= 0 then
			index = i
			break
		end
	end

	return index
end

return Math
