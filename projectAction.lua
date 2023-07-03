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
    local cards = gtag('c'..pcolor)

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
        card.addTag('alreadyActivatedAction')

        if 1 == gmod(pcolor, 'gainForCustomAction') then
            addRes(pcolor, 1, 'MC')
        end

        if action.choice then
            ChoiceSelect(pcolor, card, action.choice)
        end

        if not ProjectActionGetInUse(pcolor, name) then
            ProjectActionRecreate(pcolor, card)
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

function ProjectActionCancelClean(pcolor)
    local cards = gtag('c'..pcolor)

    for _,card in pairs(cards) do
        ProjectActionCancelButtonRemove(card)
    end
end

function ProjectActionHandle(pcolor, action, card, cancel)
    local cancelAction = {profit={}}

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
					reduction = value['reductionAction']
				elseif value['reductionCondition'] then
					local condition = true

					for conditionType,conditionValue in pairs(value['reductionCondition']) do
						if contains(PROJ_COLORS, conditionType) then
							condition = condition and (getColorCount(pcolor, conditionType) >= conditionValue)
						end

						if contains(SYMBOLS, conditionType) then
							condition = condition and (getTagCount(pcolor, conditionType) >= conditionValue)
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
        end
	end

	for profit, value in pairs(action.profit or {}) do
		if contains(RESOURCES, profit) then
			addRes(pcolor, value, profit)
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
				TokenSelect(pcolor, value)
                ProjectActionButtonRemove(card)
                ProjectActionInUse(pcolor, card, true)
			end
		end
        if 'effects' == profit then
            for effect,effectValue in pairs(value) do
                amod(pcolor,effect,effectValue)
                local effects = cancelAction['profit']['effects'] or {}
                effects[effect] = -effectValue
                cancelAction.profit['effects'] = effects
            end
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
			local cards = Player[pcolor].getHandObjects(HAND_INDEX_DRAW)
			local card = cards[1]

			if card.hasTag('Green') then
				addRes(pcolor, 1, 'MC')
				discard(card)
			end
		end
	end

    if cancel ~= true then
        local cancelActions = gstate(pcolor, 'cancelAction')
        if cancelActions == 0 then cancelActions = {} end

        cancelActions[gnote(card)] = cancelAction
        astate(pcolor,'cancelAction', cancelActions)
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

    ProjectActionRecreate(pcolor, lastActionCard)
end

function ProjectActionRecreate(pcolor, card)
    ProjectActionButtonRemove(card)

    if PhaseIsAction() then
        -- if limit is not reached
        ProjectActionButtonCreate(card)
    elseif card.hasTag('onPlayAction') then
        ProjectActionCancelButtonCreate(card)
    else
        local queue = ChoiceQueueGet(pcolor)

        if #queue > 0 then
            ChoiceQueueConsume(pcolor)
        else
            ProjectActionOnPlay(pcolor)
        end
    end
end