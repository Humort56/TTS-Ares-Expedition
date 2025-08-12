-- draw given amount of project cards, use alt for alternative hand index
function draw(pcolor,count,alt)
	local count = count or 1
	local sindex = alt and HAND_INDEX_ALT or HAND_INDEX_DRAW
	if SHUFFLING then Wait.condition(|| draw(pcolor,count,alt),|| not SHUFFLING) return end
	local deck = getDrawDeck()
	if not deck then
		broadcastToAll('Creating new deck. Please wait…',COL_MSG)
		shuffleNewDeck()
		Wait.condition(|| draw(pcolor,count,alt),|| not SHUFFLING)
	elseif deck.name == 'Card' then 
		deck.deal(1,pcolor,sindex)
		if count > 1 then
			shuffleNewDeck()
			draw(pcolor,count-1,alt)
		end
	elseif #deck.getObjects() < count then
		deck.deal(#deck.getObjects(),pcolor,sindex)
		shuffleNewDeck()
		deck.deal(count-#deck.getObjects(),pcolor,sindex)
	else
		deck.deal(count,pcolor,sindex)
	end
end

-- return project deck
function getDrawDeck()
	local dboard = gftag("DrawBoard")
	local pos = getSnapPos(dboard,'Project')
	return getCardsOnPos(pos)
end

-- create new project deck from discard pile
function shuffleNewDeck()
	SHUFFLING = true
	local dboard = gftag("DrawBoard")
	local pos = getSnapPos(dboard,'Project',2)
	local cards = getCardsOnPos(pos)
	if not cards then sendError("Deck not found!") return end
	Wait.frames(function() SHUFFLING = false end,60)
	cards.setPosition(above(getSnapPos(dboard,'Project')))
	cards.flip()
end

-- discard a project or trash any other card
function discard(card)
	if card.hasTag("Project") then
		card.removeTag('countTag')
		local dboard = gftag("DrawBoard")
		local pos = getSnapPos(dboard,'Project',2)
		card.setRotation({0,180,0})
		card.setPosition(above(pos,2.5))
	else
		trash(card)
	end
end

-- discard all cards in player's left hand
function discardHand(pcolor,selling)
	local cards = Player[pcolor].getHandObjects(HAND_INDEX_DRAW)
	local count = (CARD_VALUE + gmod(pcolor, 'cardValue'))*#cards
	for _,card in ipairs(cards) do
		discard(card)
	end
	if selling and count > 0 then
		printToColor("Sold cards for "..count.." MC",pcolor)
		addRes(pcolor,count)
	end
end
