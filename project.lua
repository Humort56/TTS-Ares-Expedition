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

function ProjectConditions(pcolor, conditions)
	for element,condition in pairs(conditions) do
        local message = ProjectCondition(pcolor, element, condition)
		if message ~= true then
			sendError(message, pcolor)
			return false
		end
	end

	return true
end

function ProjectCondition(pcolor, element, condition)
    local colorError = Color.new(COL_ERR[1],COL_ERR[2],COL_ERR[3]):toHex()
	local error = 'The '..element..' condition is not met: '

	if containsKey(TERRAFORMING_RANGES, element) then
		local value = _G['get'..element]()
		local bound = condition.bound
		local puffer = gmod(pcolor, 'conditionPuffer') + gmod(pcolor, 'conditionPufferTemp')
		if puffer > 1 then puffer = 1 end
		local rangeIndex = RANGE_INDEX[condition.range]

        local colorRange = Color.fromString(condition.range):toHex()
		error = error .. '['..colorRange..']'..condition.range..'['..colorError..']'

		if 'Lower' == bound then
			if rangeIndex > 1 then rangeIndex = rangeIndex - puffer end
			local rangeName = RANGE_NAME[rangeIndex]
			local range = TERRAFORMING_RANGES[element][rangeName]

			if not (value >= range.min) then return error..' or higher' end
		elseif 'Upper' == bound then
			if rangeIndex < 4 then rangeIndex = rangeIndex + puffer end
			local rangeName = RANGE_NAME[rangeIndex]
			local range = TERRAFORMING_RANGES[element][rangeName]
			
            if not (value <= range.max) then return error..' or lower' end
		end
	end

	if 'Ocean' == element then
		local value = #getOceans()
		local limit = condition.value
		local bound = condition.bound

        error = error..condition.value

		if 'Lower' == bound then
			if not (value >= limit) then return error..' or higher' end
		elseif 'Upper' == bound then
            if not (value <= limit) then return error..' or lower' end
		end
	end

	if 'TR' == element then
		local value = getTR(pcolor)
		local limit = condition

		if not (value >= limit) then return error..condition..' or higher' end
	end

	if 'Symbol' == element then
		local symbols = ''
		local count = 0

		for symbol,value in pairs(condition) do
			local current = getTagCount(symbol, pcolor)
			if value > current then
                count = count + 1
				symbols = symbols..' ('..value..' '..symbol..')'
            end
		end

		if count > 0 then
            local verb = 'is'
            if count > 1 then verb = 'are' end
            return 'The following symbol(s) condition '..verb..' not met:'..symbols
        end
	end

	if 'Resources' == element then
        local resources = ''
        local count = 0

		for res,value in pairs(condition) do
			local current = getRes(pcolor, res)
			if value > current then
                count = count + 1
				resources = resources..' ('..value..' '..res..')'
            end
		end

		if count > 0 then
            local verb = 'is'
            if count > 1 then verb = 'are' end
            return 'The following resource(s) condition '..verb..' not met:'..resources
        end
	end

    return true
end

function ProjectInstant(pcolor, card, instantData)
	for instantType,instantValue in pairs(instantData) do
		local gainValue = 0

		if instantType == 'Token' then
			local tokens = instantValue

			if tokens.where or tokens.type then
				tokens = {tokens}
			end

			for _,token in pairs(tokens) do
				log(token)
				if token.where then
					if token.where == 'self' then
						TokenAdd(pcolor, card, token.value or 1)
					end
				end

				if token.type then
					ChoiceQueueInsert(pcolor, card, {{Token=token}})
				end
			end
		elseif 'table' == type(instantValue) then
			for type,typeData in pairs(instantValue) do
				if 'Symbol' == type then
					for symbol,symbolGain in pairs(typeData) do
						gainValue = getTagCount(symbol,pcolor) * symbolGain
						if card.hasTag(symbol) then gainValue = gainValue + symbolGain end
					end
				end
			end
		elseif 'number' == type(instantValue) then
			gainValue = instantValue
		end

		if contains(TERRAFORMING, instantType) then
			_G['inc'..instantType](gainValue,pcolor)
		end

		if contains(RESOURCES, instantType) then
			addRes(pcolor,gainValue,instantType)
			printToColor(string.format(
				"Gained %d %s(s) from your project: [%s] %s", 
				gainValue, instantType, CardColorHex(card), CARDS[gnote(card)].name
			), pcolor)
		end
	end
end