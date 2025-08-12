function ChoiceSelect(pcolor, card, choices)
    local name = gnote(card)

    astate(pcolor, 'lastActionCard', name)
    ProjectActionSetInUse(pcolor, card, true)
    broadcastToColor('Choose the effect of [' .. Color[getProjColor(card)]:toHex() .. ']' .. CARDS[name].name, pcolor)

    for _,choice in pairs(choices) do
        if choice.Action then
            local state = gstate(pcolor, 'action')

            state[name] = choice.Action
            astate(pcolor, 'action', state)

            ProjectActionButtonRemove(card)
            ProjectActionChoiceButtonCreate(card)
        end

        if choice.Token then
            local token = choice.Token
            if token.type then
                local tokenType = token.type
                local holders = {}

                if 'table' ~= type(tokenType) then
                    tokenType = {tokenType}
                end

                for _, possibleTokenType in pairs(tokenType) do
                    local typeHolders = gtags({'c' .. pcolor, possibleTokenType .. 'Holder'})
                    for _, holder in pairs(typeHolders) do
                        table.insert(holders, holder)
                    end
                end

                if (token.value or 1) > 0 and #holders == 0 then
                    broadcastToColor("You have nowhere to place the " .. token.type .. " token", pcolor, COL_ERR)
                else
                    TokenSelect(pcolor, token.type, token.value or 1)
                end
            end

            if token.where then
                if 'self' == token.where then
                    astate(pcolor,'tokenAdd', token.value or 1)
                    TokenButtonCreate(card)
                end
            end
        end
    end
end

function ChoiceQueueInsert(playerColor, card, choices)
    if ChoiceInProgress(playerColor) then
        local queue = ChoiceQueueGet(playerColor)
        table.insert(queue, {name=gnote(card), choices=choices})
        ChoiceQueueSet(playerColor, queue)
    else
        ProjectActionClean(playerColor)
        ChoiceSelect(playerColor, card, choices)
    end
end

function ChoiceInProgress(playerColor)
    local queue = ChoiceQueueGet(playerColor)
    return #queue > 0 or ProjectActionGetInUse(playerColor, 'inUse')
end

function ChoiceQueueConsume(pcolor)
    local queue = ChoiceQueueGet(pcolor)
    local choice = table.remove(queue, 1)
    ChoiceQueueSet(pcolor, queue)

    ChoiceSelect(pcolor, gcard(pcolor, choice.name), choice.choices)
end

function ChoiceQueueGet(pcolor)
    local queue = gstate(pcolor, 'choiceQueue')

    if type(queue) ~= 'table' then 
        return {}
    end

    return queue
end

function ChoiceQueueSet(pcolor, queue)
    astate(pcolor, 'choiceQueue', queue)
end