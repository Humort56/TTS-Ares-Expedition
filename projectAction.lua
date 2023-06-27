function ProjectActionButtonCreate(card)
    card.createButton({
        click_function="ProjectActionActivate", position={-0.62,0.6,1.02}, height=300, width=350,
        color={1,0,0,0.7}, scale={1,1,1}, tooltip="Activate"
    })
end

function ProjectActionChoiceButtonCreate(card, color)
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

function ProjectActionActivate(card, pcolor, alt)
	local name = gnote(card)
    local state = gstate(pcolor, 'action')

    if state[name] then
        local abort = ProjectActionHandle(pcolor, state[name], card)
        if abort then return end

        ProjectActionEnd(pcolor)
    else
        local action = CARDS[name]['action']

        local abort = ProjectActionHandle(pcolor, action, card)
        if abort then return end

        astate(pcolor, 'lastActionCard', name)
        card.addTag('alreadyActivatedAction')

        if 1 == gmod(pcolor, 'gainForCustomAction') then
            addRes(pcolor, 1, 'MC')
        end

        if action.choice then
            for _,choice in pairs(action.choice) do
                if choice.Action then
                    local state = gstate(pcolor, 'action')

                    state[name] = choice.Action
                    astate(pcolor, 'action', state)
    
                    ProjectActionInUse(pcolor, card, true)
                    ProjectActionButtonRemove(card)
                    ProjectActionChoiceButtonCreate(card)

                end
    
                if choice.Token then
                    local token = choice.Token
                    if token.type then
                        TokenSelect(pcolor, token.type)
                        ProjectActionInUse(pcolor, card, true)
                    end
    
                    if token.where then
                        if 'self' == token.where then
                            TokenButtonCreate(card)
                        end
                    end
                end
            end
        end

        local inUse = gstate(pcolor, 'actionInUse')[name] or false
        if not inUse then ProjectActionRecreate(card) end
    end
end

function ProjectActionHandle(pcolor, action, card)
    for cost,value in pairs(action.cost or {}) do
		if contains(RESOURCES, cost) then
			local res = getRes(pcolor, cost)
			local trueValue = value

			if 'table' == type(value) then
				local base = value['base']
				local reduction = 0

				if value['reductionRes'] then
					reduction = getRes(pcolor, value['reductionRes']) * value['reductionVal']
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
				TokenAdd(pcolor, tokenCard, 1)
			else
				TokenSelect(pcolor, value)
                ProjectActionButtonRemove(card)
                ProjectActionInUse(pcolor, card, true)
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
end

function ProjectActionInUse(pcolor, card, status)
    local state = gstate(pcolor, 'actionInUse')
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

function ProjectActionRecreate(card)
    ProjectActionButtonRemove(card)

    -- if limit is not reached
    ProjectActionButtonCreate(card)
end