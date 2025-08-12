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

function ProjectInstantEffects(pcolor, card, instantData)
	for instantType,instantValue in pairs(instantData) do
		local gainValue = 0

		if instantType == 'choice' then
			local card = gcard(pcolor, instantValue.name)
			ChoiceQueueInsert(pcolor, card, instantValue.choices)
		elseif instantType == 'Token' then
			local tokens = instantValue

			if tokens.where or tokens.type then
				tokens = {tokens}
			end

			for _, token in pairs(tokens) do
				if token.where then
					if token.where == 'self' then
						TokenAdd(pcolor, card, token.value or 1)
					end
				end

				if token.type then
					ChoiceQueueInsert(pcolor, card, {{Token=token}})
				end
			end
		elseif instantType == 'RemoveCards' then
			astate(pcolor,'autoReady', false)
			local cards = gtags({'c'..pcolor,'Red','activated'})
			local actions = gstate(pcolor, 'action')

			for _,removeCard in pairs(cards) do
				local name = gnote(removeCard)
				if gnote(card) ~= name then
					ProjectActionChoiceButtonCreate(removeCard)
					actions[gnote(removeCard)] = {remove=1}
				end
			end
			astate(pcolor,'action',actions)
			astate(pcolor, 'lastActionCard', gnote(card))
		elseif 'table' == type(instantValue) then
			for type,typeData in pairs(instantValue) do
				if 'Symbol' == type then
					for symbol,symbolGain in pairs(typeData) do
						gainValue = getTagCount(symbol,pcolor) * symbolGain
						if card.hasTag(symbol) then gainValue = gainValue + symbolGain end
					end
				elseif 'Condition' == type then
					gainValue = typeData.base
					local bonus = typeData.bonus
					local condition = true
		
					for symbol,symbolValue in pairs(typeData.Symbol or {}) do
						condition = condition and (getTagCount(symbol, pcolor) >= symbolValue)
					end
	
					if condition then
						gainValue = gainValue + bonus
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

-- select and activate project on click
function ProjectActivate(card,pcolor,alt)
	if card.name == 'Deck' then sendError("You cannot activate deck",pcolor) card.clearButtons() return end

	local data = CARDS[gnote(card)]
	if not data then sendError("Could not find data for this project",pcolor) return end
	local cardName = gname(card)
	local cardColor = getProjColor(card)
	local cardHex = Color[getProjColor(card)]:toHex()
	local basicColor = Color['White']:toHex()

	local cost = ProjectCost(pcolor,card)

	if alt then
		printToColor(
			string.format(
				'The project [%s]%s[%s] will cost you %d MC',
				cardHex,cardName,basicColor,cost
			),
			pcolor
		)
		return
	end

	-- check if the current phase allow this card
	-- todo / handle special cards
	if 1 ~= CURRENT_PHASE then
		if 'Green' == cardColor and 0 == gmod(pcolor, 'playGreenDuringConstruction') and 0 == gmod(pcolor, 'playAnything') then
			sendError('You cannot play this project during this phase',pcolor)
			return
		end
		if 1 == gmod(pcolor, 'playGreenDuringConstruction') then zmod(pcolor, 'playGreenDuringConstruction') end
		if 'Green' == cardColor and 1 == gmod(pcolor, 'playAnything') then zmod(pcolor, 'playAnything') end
	end

	if 2 ~= CURRENT_PHASE then
		if ('Blue' == cardColor or 'Red' == cardColor) and 0 == gmod(pcolor, 'playAnything') then
			sendError('You cannot play this project during this phase',pcolor)
			return
		end
		if 1 == gmod(pcolor, 'playAnything') then zmod(pcolor, 'playAnything') end
	end

	local projectLimit = gstate(pcolor,'projectLimit')
	if projectLimit < 1 then
		sendError('You cannot play more projects this phase',pcolor)
		return
	end

	-- check if project can be played
	if not ProjectConditions(pcolor, data.req or {}) then
		return
	end

	local mc = getRes(pcolor,'MC')
	if 1 == gstate(pcolor,'freeGreenNineLess') then
		if ProjectCostOriginal(card) > 9 then
			sendError('This project cost more than 9 MC', pcolor)
			return
		end
		astate(pcolor,'freeGreenNineLess', 0)
	elseif 1 == gstate(pcolor,'freeGreenTwelveLess') then
		if ProjectCostOriginal(card) > 12 then
			sendError('This project cost more than 12 MC', pcolor)
			return
		end
		astate(pcolor,'freeGreenTwelveLess', 0)
	else
		if mc < cost then
			sendError("You don't have enough MC ("..cost..") for this project", pcolor)
			return
		end

		addRes(pcolor, -cost, 'MC')
		zmod(pcolor, 'payCardTemp')
	end

	callAction(' play the project ['..cardHex..']' .. cardName, pcolor)
	astate(pcolor,'projectLimit', projectLimit-1)
	if 1 == gmod(pcolor, 'conditionPufferTemp') then amod(pcolor,'conditionPufferTemp', -1) end

	printToColor(string.format(
			"Cost of your last project (%d MC): [%s] %s",
			cost, cardHex, cardName
	), pcolor)

	activateProjectProduction(card, pcolor)

	if data.revealCards then
		astate(pcolor, 'autoReady', false)
		revealCards(pcolor, data.revealCards)
	end

	astateList(pcolor, data.state or {})

	amodList(pcolor, data.effects or {})

	playCardOnBoard(pcolor, card)

	if data.manually then
		Wait.time(|| broadcastToColor(data.manually,pcolor,'Orange'), 2)
	end

	if data.tokenType then
		card.addTag(data.tokenType..'Holder')
	end

	if data.onPlayAction then
		card.addTag('onPlayAction')
	end

	ProjectActionCancelClean(pcolor)

	Wait.time(|| updateProductions(pcolor),1)
	Wait.frames(function()
		Wait.condition(
			function()
				if gstate(pcolor,'projectLimit') < 1 then
					if gstate(pcolor, 'autoReady') == true then
						ProjectActionClean(pcolor)
						Wait.time(|| setReady(pcolor,true),3)
					else
						ProjectActionOnPlayClean(pcolor)
					end
				end
			end,
			function()
				local choiceInProgress = ChoiceInProgress(pcolor)
				log(choiceInProgress)
				return not choiceInProgress
			end
		)
	end, 50)
end

function getProjColor(card)
	for _,color in ipairs(PROJ_COLORS) do
		if card.hasTag(color) then
			return color
		end
	end
	return nil
end

function getColorCount(pcolor, color)
	local cards = gtags({'c'..pcolor, color})
	return #cards
end

function playCardOnBoard(pcolor, card)
	local board = gftags({'c'..pcolor,'PlayerBoard'})

	local cardColor = getProjColor(card)
	local cards = gtags({'c'..pcolor, cardColor, 'activated'})
	local count = 1
	if cards ~= nil then
		count = #cards + 1
	end

	local pos = getSnapPos(board, getProjColor(card), count)
	card.setPosition(above(pos,0.7))
	card.addTag('c'..pcolor)
	card.addTag('activated')
	card.addTag('position'..cardColor..count)
	card.clearButtons()

	Wait.frames(|| card.setLock(true),40)
	Wait.frames(|| playTag(pcolor, card), 50)
	if 3 == CURRENT_PHASE and CARDS[gnote(card)]['action'] then
		Wait.frames(|| ProjectActionButtonCreate(card), 50)
	end
end

function fulfillConditions(conditions, pcolor)
	for element,condition in pairs(conditions) do
		if not fulfillCondition(element, condition, pcolor) then
			sendError(getConditionError(element, condition, pcolor), pcolor)
			return false
		end
	end

	return true
end

function fulfillCondition(element, condition, pcolor)
	if containsKey(TERRAFORMING_RANGES, element) then
		local value = _G['get'..element]()
		local bound = condition.bound
		local puffer = gmod(pcolor, 'conditionPuffer') + gmod(pcolor, 'conditionPufferTemp')
		if puffer > 1 then puffer = 1 end
		local rangeIndex = RANGE_INDEX[condition.range]

		if 'Lower' == bound then
			if rangeIndex > 1 then rangeIndex = rangeIndex - puffer end
			local rangeName = RANGE_NAME[rangeIndex]
			local range = TERRAFORMING_RANGES[element][rangeName]
			return value >= range.min
		elseif 'Upper' == bound then
			if rangeIndex < 4 then rangeIndex = rangeIndex + puffer end
			local rangeName = RANGE_NAME[rangeIndex]
			local range = TERRAFORMING_RANGES[element][rangeName]
			return value <= range.max
		end
	end

	if 'Ocean' == element then
		local value = #getOceans()
		local limit = condition.value
		local bound = condition.bound

		if 'Lower' == bound then
			return value >= limit
		elseif 'Upper' == bound then
			return value <= limit
		end
	end

	if 'TR' == element then
		local value = getTR(pcolor)
		local limit = condition

		return value >= limit
	end

	if 'Symbol' == element then
		local symbolValid = true

		for symbol,value in pairs(condition) do
			local current = getTagCount(symbol, pcolor)
			if value > current then symbolValid = false end
		end

		return symbolValid
	end

	if 'Resources' == element then
		local resValid = true

		for res,value in pairs(condition) do
			local current = getRes(pcolor, res)
			if value > current then resValid = false end
		end

		return resValid
	end
end

function getConditionError(element, condition, pcolor)
	local colorError = Color.new(COL_ERR[1],COL_ERR[2],COL_ERR[3]):toHex()
	local error = 'The '..element..' condition is not met: '

	if containsKey(TERRAFORMING_RANGES, element) then
		local colorRange = Color.fromString(condition.range):toHex()
		error = error .. '['..colorRange..']'..condition.range..'['..colorError..']'

		if 'Lower' == condition.bound then
			return error..' or higher'
		elseif 'Upper' == condition.bound then
			return error..' or lower'
		end
	end

	if 'Ocean' == element then
		error = error..condition.value

		if 'Lower' == condition.bound then
			return error..' or higher'
		elseif 'Upper' == condition.bound then
			return error..' or lower'
		end
	end

	if 'TR' == element then
		return error..condition..' or higher'
	end

	if 'Symbol' == element then
		symbols = ''
		count = 0

		for symbol,value in pairs(condition) do
			local current = getTagCount(symbol, pcolor)
			if value > current then
				count = count + 1
				symbols = symbols..' ('..value..' '..symbol..')'
			end
		end

		local verb = 'is'
		if count > 1 then verb = 'are' end
		return 'The following symbol(s) condition '..verb..' not met:'..symbols
	end

	if 'Resources' == element then
		resources = ''
		count = 0

		for res,value in pairs(condition) do
			local current = getRes(pcolor, res)
			if value > current then
				count = count + 1
				resources = resources..' ('..value..' '..res..')'
			end
		end

		local verb = 'is'
		if count > 1 then verb = 'are' end
		return 'The following resource(s) condition '..verb..' not met:'..resources
	end
end

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Effects + Production
----------------------------------------------------------------------------------------------------------------------------
-- payEarth				pay +x MC for card with Earth tag → similar for other tags
-- payTwenty			pay +x MC for card with <=20 cost
-- payGreen				pay +x MC for green projects → simalr for blue and red
-- plantForest			spend x less plants for forests
-- HeatAsMC			spend heat as MC
-- titanValue				titan is worht +x MC
-- researchDraw		on research draw +x cards
-- researchKeep		on research keep +x cards
-- conditionPuffer		ignore one oxygen/temperature condition level

-- onPlayTag			when playing card with given tag, trigger cards with that event	
-- onPlaySteelProduction		trigger when playing card with this production
-- onOceanFlip						triggered when ocean is flipped by the player
	-- TR → gain TR

function playTag(pcolor,card)
	for _,tag in pairs(card.getTags()) do
		local effects = nil

		-- when there are 2 time the same tag, remove the '2' at the end
		if string.sub(tag, -1) == '2' then tag = string.sub(tag, 1, -2) end

		if contains(SYMBOLS, tag) or contains(PROJ_COLORS, tag) then
			effects = gmod(pcolor, 'onPlay'..tag)
		elseif 'Project' == tag then
			effects = gmod(pcolor, 'onPlayCard')
		end
		
		if 'table' == type(effects) then
			onPlay(pcolor, effects)
		end
	end
	
	local data = CARDS[gnote(card)]

	ProjectInstantEffects(pcolor, card, data.instant or {})

	-- play the effects which do not apply to itself
	amodList(pcolor, data.afterEffects or {})

	-- reactivate onPlayAction cards if projectLimit not reached
	if gstate(pcolor,'projectLimit') > 0 and not ProjectActionGetInUse(pcolor, 'inUse') then
		ProjectActionOnPlay(pcolor)
	end
end



function createActivateProjectButton(card)
	card.createButton({
       click_function="ProjectActivate", position={0,0.6,0}, height=200, width=400,
       color={0,1,0,0.6}, scale={1,1,1}, tooltip="Activate"
    })
end

function onPlay(playerColor, effects)
	for effectType, effectData in pairs(effects) do
		if contains(RESOURCES, effectType) then
			addRes(playerColor, effectData, effectType)
		elseif 'Token' == effectType then
			for _,effect in pairs(effectData) do
				local where = effect['where']

				if 'others' == where then

				else
					local card = gcard(playerColor, where)
					TokenAdd(playerColor, card, 1)
				end
			end
		elseif 'choice' == effectType then
			for _,effect in pairs(effectData) do
				local card = gcard(playerColor,effect.name)
				ChoiceQueueInsert(playerColor, card, effect.choices)
			end
		elseif 'Action' == effectType then
			for _,effect in pairs(effectData) do
				gstate(playerColor, 'lastActionCard')
				local state = gstate(playerColor, 'action')
				state[effect.name] = effect.action
				astate(playerColor,'action',state)
				astate(playerColor,'lastActionCard',effect.name)

				local card = gcard(playerColor,effect.name)
				ProjectActionChoiceButtonCreate(card)
				astate(playerColor, 'autoReady', false)
			end
		elseif 'TR' == effectType then
			addTR(playerColor, effectData)
		end
	end
end

function revealCards(pcolor, reveal)
	local searching = {}

	if reveal['Color'] or (reveal['Symbol'] and 'string' == type(reveal['Symbol'])) then
		searching = {reveal['Color'] or reveal['Symbol']}
	elseif reveal['Symbol'] and 'table' == type(reveal['Symbol']) then
		searching = reveal['Symbol']
	end

	draw(pcolor,1)
	Wait.frames(|| revealCard(pcolor, searching), 50)
end

function revealCard(pcolor, tagList)
	local cards = Player[pcolor].getHandObjects(HAND_INDEX_DRAW)
	for _,tag in pairs(tagList) do
		if cards[#cards].hasTag(tag) then
			broadcastToColor('Keep the last card and discard the rest',pcolor,'Orange')
			return
		end
	end

	draw(pcolor,1)
	Wait.frames(|| revealCard(pcolor, tagList), 50)
end

function activateProjectProduction(card, pcolor)
	local data = CARDS[gnote(card)]
	local cardName = gname(card)
	local cardColor = Color[getProjColor(card)]:toHex()

	for res, resData in pairs(data.production or {}) do
		local total = getProduction(pcolor,res)
		local prod = gprod(pcolor, res)
		for resType, resProd in pairs(resData) do
			if 'Symbol' == resType and type(resProd) == "table" then
				local symbolList = prod[resType] or {}
				for symbol,value in pairs(resProd) do
					symbolList[symbol] = (symbolList[symbol] or 0) + value
				end
				prod[resType] = symbolList
			else
				prod[resType] = (prod[resType] or 0) + resProd
			end
		end
		aprod(pcolor, res, prod)

		-- update production
		updateProduction(pcolor, res)

		-- calculate diff from start production
		local delta = getProduction(pcolor,res) - total

		mod = gmod(pcolor, 'onPlay'..res..'Production')
		if 'table' == type(mod) then
			for bonus,value in pairs(mod) do
				if 'TR' == bonus then
					local bonusValue = value * delta
					addTR(pcolor, bonusValue)
				end
			end
		end
		
		if delta > 0 then
			printToColor(string.format(
				"Secured %d %s production from your project: [%s] %s",
				delta, res, cardColor, cardName
			), pcolor)
		end
	end
end

function getProjectSnapPos(obj,stag,index)
	local pos = findProjectSnapOnObj(obj,stag,index).position
	return obj.positionToWorld(pos)
end
-- find snap point with given tag and -given index on obj
function findProjectSnapOnObj(obj,stag,index)
	if not obj then sendError("Missing Object") return {position={0,10,0}} end
	local snaps = obj.getSnapPoints()
	local n = 0
	local index = index or 1
	for s,snap in ipairs(snaps) do
		if hasTagInRef(snap,stag) then
			local cards = getCardsOnPos(obj.positionToWorld(snap.position))
			log(cards)
			if nil == cards then
				return snap
			end
		end
	end
	return nil
end