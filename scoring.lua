function Score(pcolor, summarize)
    local cards = CardsPlayedBy(pcolor)

    local summary = 0
    local tr = getTR(pcolor)
    local forest = getForestVP(pcolor)

    local score = tr + forest

    printToColor("Score:", pcolor)
    printToColor("  TR: "..tr, pcolor)
    printToColor("  Forest: "..forest, pcolor)
    printToColor("  Cards:", pcolor)

    for _, card in pairs(cards) do
        local data = CARDS[gnote(card)]
        if data.vp ~= nil then
            local vp = data.vp
            local cardScore = 0
            local staticCard = (type(vp) == 'number')

            if staticCard then
                cardScore = cardScore + vp
                summary = summary + cardScore
            elseif vp.token ~= nil then
                cardScore = cardScore + math.floor(TokenCount(card) / vp.token)
            elseif vp.Cards ~= nil then
                for filter, value in pairs(vp.Cards) do
                    local cardsScored = CardsPlayedByFiltered(pcolor, filter)

                    cardScore = cardScore + math.floor(#cardsScored / value)
                end
            elseif vp.Symbol ~= nil then
                for symbol, value in pairs(vp.Symbol) do
                    local symbolsScored = getTagCount(symbol, pcolor)

                    cardScore = cardScore + math.floor(symbolsScored / value)
                end
            elseif vp.Forest ~= nil then
                cardScore = cardScore + math.floor(getForestVP(pcolor) / vp.Forest)
            end

            if (not staticCard or not summarize) and cardScore > 0 then
                printToColor("    "..gnote(card)..": "..cardScore, pcolor)
            end
            score = score + cardScore
        end
    end

    if summarize and summary > 0 then
        printToColor("    Others card(s): "..summary, pcolor)
    end

    printToColor("Total: "..score, pcolor)
end