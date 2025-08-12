function ProjectActionButtonCreate(card)
    card.createButton({
        click_function="ProjectActionActivate", position={-0.62,0.6,1.02}, height=300, width=350,
        color={1,0,0,0.7}, scale={1,1,1}, tooltip="Activate"
    })
end

function ProjectActionChoiceButtonCreate(card)
    card.createButton({
        click_function="ProjectActionActivate", position={-0.62,0.6,1.02}, height=300, width=350,
        color={1,0,1,0.9}, scale={1,1,1}, tooltip="Activate"
    })
end

function ProjectActionButtonRemove(card)
    for _,btn in pairs(card.getButtons() or {}) do
        if 'ProjectActionActivate' == btn.click_function then
            card.removeButton(btn.index)
        end
    end
end

function ProjectActionClean(pcolor)
    local cards = gtags({'c'..pcolor,'activated'})

    for _,card in pairs(cards) do
        ProjectActionButtonRemove(card)
    end
end

function ProjectActionRedClean(pcolor)
    local cards = gtags({'c'..pcolor,'Red'})
    local actions = gstate(pcolor, 'action')
    for _,card in pairs(cards) do
        actions[gnote(card)] = nil
        ProjectActionButtonRemove(card)
    end

    astate(pcolor,'action',actions)
end

function ProjectActionCancelClean(pcolor)
    local cards = gtag('c'..pcolor)
    for _,card in pairs(cards) do
        ProjectActionCancelButtonRemove(card)
    end
end

function ProjectActionCancelButtonCreate(card)
    card.createButton({
        click_function="ProjectActionCancel", position={-0.62,0.6,1.02}, height=300, width=350,
        color={1,0,0,0.9}, scale={1,1,1}, tooltip="Cancel"
    })
end

function ProjectActionCancelButtonRemove(card)
    for _,btn in pairs(card.getButtons() or {}) do
        if 'ProjectActionCancel' == btn.click_function then
            card.removeButton(btn.index)
        end
    end
end

function ProjectActionActivate(card, pcolor, alt)
	local name = gnote(card)
    local state = gstate(pcolor, 'action')

    if state[name] then
        local abort = ProjectActionHandle(pcolor, state[name], card)
        if abort then return end

        ProjectActionEnd(pcolor)
    else
        local action = CARDS[name]['action'] or CARDS[name]['onPlayAction']

        local abort = ProjectActionHandle(pcolor, action, card)
        if abort then return end

        astate(pcolor, 'lastActionCard', name)
        if card.hasTag('actionUsed') then
            astate(pcolor, 'actionDouble', false)
        else
            card.addTag('actionUsed')
        end

        if 1 == gmod(pcolor, 'gainForCustomAction') then
            addRes(pcolor, 1, 'MC')
        end

        if action.choice then
            ChoiceQueueInsert(pcolor, card, action.choice)
        end

        if not ProjectActionGetInUse(pcolor, name) then
            astate(pcolor, 'actionAvailable', true)
            ProjectActionRecreate(pcolor, card)
        end
    end
end

function ProjectActionCreate(pcolor)
    local activatedCards = gtags({'c'..pcolor, 'Blue', 'activated'})
    local actionDouble = gstate(pcolor,'actionDouble')
    for _,card in pairs(activatedCards) do
        if CARDS[gnote(card)]['action'] then
            local used = card.hasTag('actionUsed')

            if used == false or (used == true and actionDouble == true) then
                ProjectActionButtonCreate(card)
            end
        end
    end
end

function ProjectActionCancel(card, pcolor, alt)
    local cancelActions = gstate(pcolor, 'cancelAction')
    local name = gnote(card)

    if not cancelActions[name] then
        -- error no cancel for this action
    end

    local cancelAction = cancelActions[name]
    ProjectActionHandle(pcolor, cancelAction, card, true)

    ProjectActionCancelButtonRemove(card)
    ProjectActionChoiceButtonCreate(card)
end

function ProjectActionOnPlay(pcolor)
    local cards = gtags({'c'..pcolor,'onPlayAction'})

    for _,card in pairs(cards) do
        ProjectActionChoiceButtonCreate(card)
    end
end

function ProjectActionOnPlayClean(pcolor)
    local cards = gtags({'c'..pcolor,'onPlayAction'})

    for _,card in pairs(cards) do
        ProjectActionButtonRemove(card)
    end
end

function ProjectActionCancelClean(pcolor)
    local cards = gtag('c'..pcolor)

    for _,card in pairs(cards) do
        ProjectActionCancelButtonRemove(card)
    end
end

function ProjectActionHandle(pcolor, action, card, cancel)
    local cancelAction = {profit={}}

    if action.remove then
        local cardColor = getProjColor(card)
        card.setLock(false)
        card.removeTag('c'..pcolor,'activated')
        card.clearButtons()
        card.deal(1,pcolor,HAND_INDEX_DRAW)

        local actions = gstate(pcolor,'action')
        actions[gnote(card)] = nil
        astate(pcolor,'action',actions)

        ProjectActionRedClean(pcolor)
        createActivateProjectButton(card)

        local board = gftags({'c'..pcolor,'PlayerBoard'})
        local cards = gtags({'c'..pcolor, cardColor, 'activated'})
        local count = #cards + 1
        local index = 0

        for i=1,count do
            if card.hasTag('position'..cardColor..i) then
                index = i
                card.removeTag('position'..cardColor..i)
            end
        end

        for i=count,index+1,-1 do
            local changeCard = gftags({'c'..pcolor,'position'..cardColor..i})
            if changeCard then
                changeCard.setLock(false)
                local pos = getSnapPos(board, cardColor, 14-(count-i))
                changeCard.setPosition(above(pos,0.7))
            else
                sendError('Could not find card for position ' .. i .. ' of color ' .. cardColor)
            end
        end

        for i=index+1,count do
            local changeCard = gftags({'c'..pcolor,'position'..cardColor..i})
            if changeCard then
                changeCard.removeTag('position'..cardColor..i)
                changeCard.addTag('position'..cardColor..i-1)
            else
                sendError('Could not find card for position ' .. i .. ' of color ' .. cardColor)
            end
        end

        MoveCard(pcolor,board,cardColor,index,count-1)
    end

    for cost,value in pairs(action.cost or {}) do
		if contains(RESOURCES, cost) then
			local res = getRes(pcolor, cost)
			local trueValue = value

			if 'table' == type(value) then
				local base = value['base']
				local reduction = 0

				if value['reductionRes'] then
					reduction = getProduction(pcolor, value['reductionRes']) * value['reductionVal']
				elseif value['reductionSymbol'] then
					reduction = getTagCount(value['reductionSymbol'], pcolor) * value['reductionVal']
				elseif value['reductionAction'] then
                    if hasActivePhase(pcolor,3) then
					    reduction = value['reductionAction']
                    end
				elseif value['reductionCondition'] then
					local condition = true

					for conditionType,conditionValue in pairs(value['reductionCondition']) do
						if contains(PROJ_COLORS, conditionType) then
							condition = condition and (getColorCount(pcolor, conditionType) >= conditionValue)
						end

						if contains(SYMBOLS, conditionType) then
							condition = condition and (getTagCount(conditionType, pcolor) >= conditionValue)
						end
					end

					if condition then
						reduction = value['reductionVal']
					end
				end

				trueValue = base - reduction
				if trueValue < 0 then trueValue = 0 end
			end
			
			if trueValue > res then
				-- send error when not enought resources
				sendError('You do not have enought '..cost)
				return true
			end

			printToColor('You paid '..trueValue..' '..cost..' to use this action', pcolor)
			addRes(pcolor, -trueValue, cost)
            cancelAction.profit[cost] = trueValue
		end

        if 'Token' == cost then
            if value.where then
                if 'self' == value.where then
                    local costValue = value.value or 1
                    local tokenCount = TokenCount(card)

                    if costValue > tokenCount then
                        -- send error when not enought resources
                        sendError('You do not have enought '..CARDS[gnote(card)].tokenType..'(s)')
                        return true
                    end

                    TokenAdd(pcolor, card, -costValue)
                    cancelAction.profit.Token = {where='self',value=costValue}
                end
            end

            if value.type then
                local tokenTypes = value.type
                if type(tokenTypes) == 'string' then tokenTypes = {tokenTypes} end

                local tokenValue = value.value or 1
                local abort = TokenSelect(pcolor, value.type, -tokenValue)

                if abort then
                    local tokens = {}
                    for _,tokenType in pairs(tokenTypes) do
                        table.insert(tokens, tokenType..'\'s')
                    end
                    
                    sendError('You do not have enought '..table.concat(tokens,'/')..' token(s) on any card for this action')
                    return true
                end

                ProjectActionInUse(pcolor, card, true)
                ProjectActionClean(pcolor)
            end
        end

        if 'Discard' == cost then
            local cards = Player[pcolor].getHandObjects(HAND_INDEX_DRAW)

            local discardedCards = {}

            if #cards == 0 then
                sendError('You do not have any card(s) ready to discard')
                return true
            elseif #cards > value then
                sendError('You have too many cards ready to discard')
                return true
            end

            for _,card in pairs(cards) do
                table.insert(discardedCards, gnote(card))
            end

            astate(pcolor, 'discardedCards', discardedCards)
            discardHand(pcolor, false)
        end

        if 'TR' == cost then
            addTR(pcolor, -value)
        end
	end

	for profit, value in pairs(action.profit or {}) do
		if contains(RESOURCES, profit) then
            if type(value) == 'table' then
                local tempValue = value.base
                local bonus = value.bonus
                local condition = false

                if value.card and 0 ~= gstate(pcolor, 'discardedCards') then
                    local cardCondition = value.card
                    local discardedCards = gstate(pcolor, 'discardedCards')
                    if 'table' ~= type(discardedCards) then
                        sendError('Discarded cards must be a table')
                        discardedCards = {}
                    end
                    local tempCondition = true
                    for _,cardName in pairs(discardedCards) do
                        local card = gcard(pcolor, cardName, true)
                        for conditionType,conditionValue in pairs(cardCondition) do
                            if conditionType == 'Symbol' then
                                for symbolType,_ in pairs(conditionValue) do
                                    tempCondition = tempCondition and card.hasTag(symbolType)
                                end
                            end
                        end
                    end
                    condition = tempCondition
                end

                if condition then
                    tempValue = tempValue + bonus
                end

                value = tempValue
            end

            if value == 'discarded' then
                value = #gstate(pcolor,'discardedCards')
                astate(pcolor,'discardedCards', 0)
            end
			Wait.frames(|| addRes(pcolor, value, profit), 1)
		end

		if contains(TERRAFORMING,profit) then
			_G['inc'..profit](value, pcolor)
		end
		if 'Token' == profit then
			if value.where then
                local tokenCard = card
                if 'self' ~= value.where then
				    tokenCard = gcard(pcolor, value.where)
                end
				TokenAdd(pcolor, tokenCard, value.value or 1, true)
			else
                if type(value) ~= 'table' then
                    value = {value}
                end

                local countHolders = 0

                for _, tokenType in pairs(value) do
                    local holders = gtags({'c'..pcolor, tokenType..'Holder'})
                    countHolders = countHolders + #holders
                end

                if countHolders == 0 then
                    broadcastToColor("You have nowhere to place the " .. table.concat(value, "/") .. " token", pcolor, COL_ERR)
                    return true
                else
                    TokenSelect(pcolor, value)
                    ProjectActionButtonRemove(card)
                    ProjectActionInUse(pcolor, card, true)
                end
			end
		end

        if 'effects' == profit then
            if 'table' ~= type(value) then
                sendError('Effects must be a table')
                value = {}
            end
            for effect,effectValue in pairs(value) do
                amod(pcolor,effect,effectValue)
                local effects = cancelAction['profit']['effects'] or {}
                effects[effect] = -effectValue
                cancelAction.profit['effects'] = effects
            end
        end
        if 'state' == profit then
            astateList(pcolor, value)
        end
	end

	if hasActivePhase(pcolor,3) then
		for profit, value in pairs(action.profitBonus or {}) do
			if contains(RESOURCES, profit) then
				addRes(pcolor, value, profit)
			end
		end
	end

	if action['customAction'] then
		local custom = action['customAction']
		if 'greenMCrestKeep' == custom then
			draw(pcolor, 1)
            -- Wait for the card to be drawn before checking the card
            -- TODO: Wait for the presence of the card in the hand
            Wait.frames(function()
                local cards = Player[pcolor].getHandObjects(HAND_INDEX_DRAW)
                local card = cards[1]
    
                if card.hasTag('Green') then
                    addRes(pcolor, 1, 'MC')
                    discard(card)
                end
            end, 50)
		end
	end

    if action.manually then
		Wait.time(|| broadcastToColor(action.manually,pcolor,'Orange'), 1)
	end

    if cancel ~= true then
        local cancelActions = gstate(pcolor, 'cancelAction')
        if cancelActions == 0 then cancelActions = {} end

        cancelActions[gnote(card)] = cancelAction
        astate(pcolor,'cancelAction', cancelActions)
    end
end

function MoveCard(pcolor, board, cardColor, current, last)
    local changeCard = gftags({'c'..pcolor,'position'..cardColor..current})
    if not changeCard then
        sendError('Could not find card for position ' .. current .. ' of color ' .. cardColor)
        return
    end
    local pos = getSnapPos(board, cardColor, current)
    changeCard.setPosition(above(pos,0.7))
    Wait.frames(|| changeCard.setLock(true), 40)
    
    if current ~= last then
        Wait.time(|| MoveCard(pcolor,board,cardColor,current+1,last), 1)
    end
end

function ProjectActionGetInUse(pcolor, name)
    return gstate(pcolor, 'actionInUse')[name] or false
end

function ProjectActionInUse(pcolor, card, status)
    local state = gstate(pcolor, 'actionInUse')
    state['inUse'] = status
    state[gnote(card)] = status
    astate(pcolor, 'actionInUse', state)
end

function ProjectActionEnd(pcolor)
    TokenUnselect(pcolor)

    local lastActionName = gstate(pcolor, 'lastActionCard')
    local lastActionCard = gcard(pcolor, lastActionName)

    ProjectActionInUse(pcolor, lastActionCard, false)
    local state = gstate(pcolor, 'action')
    state[lastActionName] = nil
    astate(pcolor, 'action', state)

    astate(pcolor, 'actionAvailable', false)
    ProjectActionRecreate(pcolor, lastActionCard)
end

function ProjectActionRecreate(pcolor, card)
    ProjectActionButtonRemove(card)

    if PhaseIsAction() then
        ProjectActionClean(pcolor)
        ProjectActionCreate(pcolor)
    elseif card.hasTag('onPlayAction') then
        ProjectActionCancelButtonCreate(card)
    else
        local queue = ChoiceQueueGet(pcolor)

        if #queue > 0 then
            ChoiceQueueConsume(pcolor)
        else
            ProjectActionOnPlay(pcolor)
            ProjectActionInState(pcolor)
        end
    end
end

function ProjectActionInState(pcolor)
    local state = gstate(pcolor, 'action')

    if 'table' ~= type(state) then return end

    for name,action in pairs(state) do
        if action ~= nil then
            local card = gcard(pcolor, name)
            ProjectActionChoiceButtonCreate(card)
        end
    end
end