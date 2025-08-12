-- select and place the phase card of given number for given player
function selectPhaseCard(player,nr)
	shufflePhases(player)
	local pcolor = player.color
	local pcard = getPhaseCard(pcolor,nr)
	if not pcard then sendError("Phase Card not found",pcolor) return end
	local lcard = getLastPhaseCard(pcolor)
	if lcard == pcard then sendError("You have already chosen this phase last",pcolor) return end
	local scard = getSeletectedPhaseCard(pcolor)
	if scard then scard.deal(1,pcolor,HAND_INDEX_PHASE) end
	if scard == pcard then
		setReady(pcolor,false)
	else
		setReady(pcolor,true)
		local pboard = gftags({'c'..pcolor,'PlayerBoard'})
		local pos = above(getSnapPos(pboard,'Phase',2),0.2)
		pcard.setRotation({0,180,180})
		pcard.setPosition(pos)
		Wait.frames(|| checkPhases(),10)
	end
end

-- return the phase card given player has played in last round
function getLastPhaseCard(pcolor)
	local pboard = gftags({'c'..pcolor,'PlayerBoard'})
	local pos = getSnapPos(pboard,'Phase',1)
	local card = getCardsOnPos(pos,1,true)
	return card
end

-- return player's currently selected phase card
function getSeletectedPhaseCard(pcolor)
	local pboard = gftags({'c'..pcolor,'PlayerBoard'})
	local pos = getSnapPos(pboard,'Phase',2)
	local card = getCardsOnPos(pos)
	return card
end

-- return player's phase card with given number
function getPhaseCard(pcolor,nr)
	return gftags({'c'..pcolor,'Ph'..(nr or '')})
end

-- shuffle phase cards on player's hand
function shufflePhases(player)
	local cards = shuffleList(player.getHandObjects(HAND_INDEX_PHASE))
	local pht = player.getHandTransform(HAND_INDEX_PHASE)
    local offSet = pht.scale.x / ( 2 * #cards)
    for i, c in ipairs(cards) do
      c.setPosition(pht.position)
      pht.position.x = pht.position.x + offSet * pht.right.x
      pht.position.z = pht.position.z + offSet * pht.right.z
    end
end

-- reveal phases if all seated players have selected a phase
function checkPhases()
	if allPhasesSelected() then 
		revealPhases()
	end
end

-- reveal all phase cards
function revealPhases()
	for _,pcolor in ipairs(playersInGame()) do
		revealPhase(pcolor)
	end
	startNextPhase()
end

-- flip phase and place phase board
function revealPhase(pcolor)
	local scard = getSeletectedPhaseCard(pcolor)
	if not scard then return end
	if scard.is_face_down then scard.flip() end
	local nr = getPhaseNr(scard)
	CURRENT_PHASES[nr] = true
	setPhaseBoard(nr)
	callAction(' revealed: ' .. PHASE_NAMES[nr],pcolor)
end

-- reset phase cards and phase boards
function newRound()
	for _,pcolor in ipairs(playersInGame()) do
		switchPhase(pcolor)
	end
	removePhaseBoards()
end

-- draw last phase card and flip current phase card
function switchPhase(pcolor)
	local lcard = getLastPhaseCard(pcolor)
	local scard = getSeletectedPhaseCard(pcolor)
	if not scard then sendError("No phase selected",pcolor) return end
	if lcard then lcard.deal(1,pcolor,HAND_INDEX_PHASE) end
	local board = gftags({'c'..pcolor,'PlayerBoard'})
	local pos = getSnapPos(board,'Phase',1)
	scard.setRotation({0,180,180})
	scard.setPositionSmooth(pos)
end

-- check if all players have selected a phase
function allPhasesSelected()
	for _,pcolor in ipairs(playersInGame()) do
		local scard = getSeletectedPhaseCard(pcolor)
		if not scard or not scard.is_face_down then return false end
	end
	return true
end

-- move phase boards aside
function removePhaseBoards()
	for i=1,5 do removePhaseBoard(i) end
end

-- move phase board of given number aside
function removePhaseBoard(nr)
	local board = gftags({'PhaseBoard','Ph'..nr})
    if not board then
        sendError("Phase Board not found",getSeletectedPhaseCard().color)
        return
    end

	local pos = getSnapPos(Global,'PhaseBoard',6)
	if not board.is_face_down then board.setRotation({0,180,180}) end
	board.setPosition(above(pos,nr))
	board.removeTag('active')
end

-- place phase board of given number in the middle to show it has been selected
function setPhaseBoard(nr)
	local board = gftags({'PhaseBoard','Ph'..nr})
	local pos = getSnapPos(Global,'PhaseBoard',nr)
    if not board then
        sendError("Phase Board not found",getSeletectedPhaseCard().color)
        return
    end

	board.setPosition(above(pos,1))
	if not board.hasTag('active') then
		board.flip()
		board.addTag('active')
	end
end

-- return number of given phase card or board
function getPhaseNr(card)
	for nr=1,5 do
		if card.hasTag('Ph'..nr) then return nr end
	end
end

-- return list of currently selected phase boards
function getActivePhaseBoards()
	return gtags({'PhaseBoard','active'})
end

-- return true if player has currently selected phase of given number
function hasActivePhase(pcolor,nr)
	local scard = getSeletectedPhaseCard(pcolor)
	if scard and scard.hasTag('Ph'..nr) then return true
	else return false end
end

function startNextPhase()
	log('Current Phase: ' .. CURRENT_PHASE)
	for pcolor,state in pairs(READY_STATE) do
		READY_STATE[pcolor] = false
	end
	REACH_TEMP = false
	REACH_OXY = false
	REACH_OCEAN = false
	if CURRENT_PHASE > 0 then CURRENT_PHASES[CURRENT_PHASE] = false end

	if CURRENT_PHASE == 3 then
		local actionCards = gtag('actionUsed')
		for _,card in pairs(actionCards) do
			card.removeTag('actionUsed')
		end
	end

	CURRENT_PHASE = getNextPhase()
	doActionPhase()
	if CURRENT_PHASE == 0 then
		broadcastToAll('All Phases completed',COL_MSG)
		setNotes('Choose your Phase')
		newRound()
	else
		Wait.frames(|| broadcastToAll('New Phase: ' .. PHASE_NAMES[CURRENT_PHASE] ,COL_MSG),100)
		setNotes("Current Phase: " .. PHASE_NAMES[CURRENT_PHASE])
	end
end

function doActionPhase()
	for _,pcolor in ipairs(playersInGame()) do
		astate(pcolor, 'projectLimit', 0)
		astate(pcolor, 'freeGreenNineLess', 0)
		astate(pcolor, 'action', {})
		astate(pcolor, 'actionInUse', {})
		zmod(pcolor, 'payCardTemp')

		ProjectActionClean(pcolor)
		ProjectActionCancelClean(pcolor)

		if 'Development' == PHASE_NAMES[CURRENT_PHASE] then
			astate(pcolor, 'autoReady', true)
			astate(pcolor, 'projectLimit', 1)
			ProjectActionOnPlay(pcolor)
		end

		if 'Construction' == PHASE_NAMES[CURRENT_PHASE] then
			local limit = 1
			if hasActivePhase(pcolor,2) then limit = 2 end
			
			astate(pcolor, 'projectLimit', limit)
			astate(pcolor, 'autoReady', true)
			ProjectActionOnPlay(pcolor)
		end

		if PhaseIsAction() then
			astate(pcolor, 'autoReady', false)

			local actionDouble = false
			if hasActivePhase(pcolor, 3) then actionDouble = true end
			astate(pcolor, 'actionDouble', actionDouble)

			ProjectActionCreate(pcolor)
		end

		if 'Production' == PHASE_NAMES[CURRENT_PHASE] then
			Wait.frames(|| produce(pcolor),150)
		end

		if 'Research' == PHASE_NAMES[CURRENT_PHASE] then
			local researchDraw = 2 + gmod(pcolor, 'researchDraw')
			local researchKeep = 1 + gmod(pcolor, 'researchKeep')

			if hasActivePhase(pcolor, CURRENT_PHASE) then
				researchDraw = researchDraw + 3
				researchKeep = researchKeep + 1
			end

			broadcastToColor('You must keep '..researchKeep..' card(s)', pcolor, 'Orange')

			draw(pcolor, researchDraw)
		end
	end
end

function PhaseIsAction()
	return CURRENT_PHASE == 3
end

function getNextPhase()
	for i=CURRENT_PHASE+1,5 do
		if CURRENT_PHASES[i] then return i end
	end
	return 0
end

function setReady(pcolor,ready)
	if not SEATED_COLORS[pcolor] then sendError("You are not part of the game!",pcolor) return end
	READY_STATE[pcolor] = ready
	updateReadyDisplay()
end

function updateReadyDisplay()
	local ready = true
	local notes = CURRENT_PHASE > 0 and "Current Phase: " .. PHASE_NAMES[CURRENT_PHASE] or ""
	for pcolor,state in pairs(READY_STATE) do
		if state then
			notes = notes .. '\n['..Color[pcolor]:toHex()..']'..playerName(pcolor) .. " is ready"
		else
			ready=false
		end
	end
	if ready then
		if CURRENT_PHASE > 0 then
			startNextPhase()
		end
	else
		setNotes(notes)
	end
end
