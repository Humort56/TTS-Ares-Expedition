function ProjectCost(pcolor, card)
	local data = CARDS[gnote(card)]
	local cost = data.cost or 0
	if cost >= 20 then 
		cost = cost + gmod(pcolor,'payTwenty')
	end
	
	for _,symbol in ipairs(SYMBOLS) do
		if card.hasTag(symbol) then
			cost = cost + gmod(pcolor,'pay'..symbol)

			if 'Building' == symbol then
				cost = cost - (getProduction(pcolor, 'Steel') * (STEEL_VALUE + gmod(pcolor,'steelValue')))
			end
	
			if 'Space' == symbol then
				cost = cost - (getProduction(pcolor, 'Titan') * (TITAN_VALUE + gmod(pcolor,'titanValue')))
			end
		end
	end
	
	cost = cost + gmod(pcolor,'pay'..getProjColor(card))
	cost = cost + gmod(pcolor,'payCard')
	cost = cost + gmod(pcolor,'payCardTemp')

	if hasActivePhase(pcolor,1) and 1 == CURRENT_PHASE then cost = cost - 3 end

	if cost < 0 then cost = 0 end

	return cost
end

function ProjectCostOriginal(card)
	local data = CARDS[gnote(card)]
	return data.cost or 0
end