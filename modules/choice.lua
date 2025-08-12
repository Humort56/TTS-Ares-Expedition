function ChoiceSelect(pcolor, card, choices)
    local name = gnote(card)

    astate(pcolor, 'lastActionCard', name)
    ProjectActionInUse(pcolor, card, true)
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
                local holders = gtags({'c'..pcolor, token.type..'Holder'})
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

function ChoiceQueueInsert(pcolor, card, choices)
    local queue = ChoiceQueueGet(pcolor)

    if #queue > 0 or ProjectActionGetInUse(pcolor, 'inUse') then
        table.insert(queue, {name=gnote(card), choices=choices})
        ChoiceQueueSet(pcolor, queue)
    else
        ProjectActionClean(pcolor)
        ChoiceSelect(pcolor, card, choices)
    end
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