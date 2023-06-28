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
                TokenSelect(pcolor, token.type)
            end

            if token.where then
                if 'self' == token.where then
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
    if queue == 0 then queue = {} end
    return queue
end

function ChoiceQueueSet(pcolor, queue)
    astate(pcolor, 'choiceQueue', queue)
end