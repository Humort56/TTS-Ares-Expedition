-- returns the selected coorp of given player
function getActiveCorp(pcolor)
	local board = gftags({'c'..pcolor,'PlayerBoard'})
	local pos = getSnapPos(board,'Corporation')
	return getCardsOnPos(pos)
end

-- add button on spawned coorp to activate/trash it
function createActivateCorpButton(card)
	card.createButton({
       click_function="activateCorp", position={0,0.6,0}, height=200, width=400,
       color={0,1,0,0.6}, scale={1,1,1}, tooltip="(L) Activate (R) Discard"
    })
end

-- select and activate corporation on click
function activateCorp(card,pcolor,alt)
	if alt then trash(card) return end
	if card.name == 'Deck' then sendError("You cannot activate deck",pcolor) card.clearButtons() return end
	if getActiveCorp(pcolor) then sendError("You already have a corporation",pcolor) return end
	local data = CARDS[gnote(card)]
	if not data then sendError("Could not find data for this corporation",pcolor) return end
	callAction(' starts the expedition with [CB5500]' .. gname(card),pcolor)

	local mc = data.MC
	addRes(pcolor,mc)
	printToColor("Starting MC from your corporation: " .. mc,pcolor)

	local drawing = data.Cards
	if drawing then
		draw(pcolor,drawing,true)
		printToColor("Starting with " .. drawing .. " additional cards from your corporation",pcolor)
	end
	if data.drawChoice then draw(pcolor,data.drawChoice) end

	for _,res in ipairs(RESOURCES) do
		local production = data[res..'Production']		
		if production then
			local prod = gprod(pcolor, res)
			prod['Static'] = (prod[res] or 0) + production
			aprod(pcolor, res, prod)
			updateProduction(pcolor, res)
			printToColor("Starting " .. res .. " production from your corporation: "..production,pcolor)
		end
	end

	if data.tokenType then
		card.addTag(data.tokenType..'Holder')
	end

	amodList(pcolor, data.effects or {})

	if data.revealCards then
		revealCards(pcolor, data.revealCards)
	end

	if data.manually then
		broadcastToColor('Please finish corporation setup manually',pcolor,'Orange')
		printToColor('→ '..data.manually,pcolor)
	end

	local board = gftags({'c'..pcolor,'PlayerBoard'})
	local pos = getSnapPos(board,'Corporation')
	card.setPosition(pos)
	card.addTag('c'..pcolor)
	card.addTag('activated')
	card.setLock(true)
	card.clearButtons()
	Wait.frames(|| ProjectInstant(pcolor, card, data.instant or {}))
	Wait.frames(|| discardRemainingCorps(pcolor),10)
end

-- discard any remaining coorps in player hand
function discardRemainingCorps(pcolor)
	local cards = Player[pcolor].getHandObjects(HAND_INDEX_CORP)
	for _,card in ipairs(cards) do
		if card.hasTag('Corporation') then trash(card) end
	end
end