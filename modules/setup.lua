-- setup game with current settings for seated players
function startGame()
	local sBoard = gftag("SetupBoard")
	broadcastToAll('Starting Ares Expedition. Please wait…',COL_MSG)
	setPlayersInGame()
	placeOceans()
	setStartingCorps(sBoard)
	setStartingProjects(sBoard)
	removePhaseBoards()
	Wait.frames(|| sBoard.destruct(),180)
	GAME_STARTED = true
	Wait.frames(|| createStandardActionButtons(),100)
end

-- clean up by removing objects from not seated player colors
function setPlayersInGame()
	for i,pcolor in ipairs(PLAYER_COLORS) do
		if Player[pcolor].seated then 
			gftags({'c'..pcolor,'PlayerBoard'}).addTag('playing')
-- 			table.insert(SEATED_COLORS,pcolor]
		else
		SEATED_COLORS[pcolor] = nil
		READY_STATE[pcolor] = nil
			Wait.frames(function()
				for _,obj in ipairs(gtag('c'..pcolor)) do
					obj.setLock(false)
					trash(obj)
				end
			end,10*i)
		end
	end
	for _,zone in ipairs(gtag('Hand')) do
		local zcolor = zone.getData().FogColor
		if not Player[zcolor].seated then zone.destruct() end
	end
end

-- deal coorporations to players
function setStartingCorps(sBoard)
	local index = sBoard.getVar('BeginnerCorporations') and 2 or 1
	local corpCount = sBoard.getVar('BeginnerCorporations') and 1 or 2
	local pos = getSnapPos(sBoard,'Corporation',index)
	local cards = getCardsOnPos(pos)
    if not cards then
        sendError("Corporation deck not found!",getSeletectedPhaseCard().color)
        return
    end

	if sBoard.getVar('PromoCorporations') then
		cards.putObject(getCardsOnPos(getSnapPos(sBoard,'Corporation',3)))
	end
	if not sBoard.getVar('BeginnerCorporations') then
		cards.putObject(getCardsOnPos(getSnapPos(sBoard,'Corporation',2)))
	end
	Wait.frames(|| cards.shuffle(),50)
	for _,pcolor in ipairs(playersInGame()) do
		Wait.frames(|| cards.deal(corpCount,pcolor,HAND_INDEX_CORP),100)
		Wait.frames(|| broadcastToColor("["..Color.Orange:toHex().."]Setup[ffffff]: Please pick a corporation.",pcolor),100)
		Wait.frames(|| printToColor("Activate a corporation in your hand by clicking on the green button. Right click to discard any other corporation.",pcolor),100)
	end
	Wait.frames(function()
		for _,obj in ipairs(gtag("Corporation")) do
			if distance(obj,sBoard) < 10 then trash(obj) end	
		end
	end,120)
end

-- deal starting projects to players
function setStartingProjects(sBoard)
	local ccount = 8
	local bcount = 16
	local cards = getCardsOnPos(getSnapPos(sBoard,'Project',1))
	local bcards = getCardsOnPos(getSnapPos(sBoard,'Project',2))
    if not cards then
        sendError("Project deck not found!",getSeletectedPhaseCard().color)
        return
    end
    if not bcards then
        sendError("Beginner project deck not found!",getSeletectedPhaseCard().color)
        return
    end

	if sBoard.getVar('BeginnerProjects') then
		bcards.shuffle()
		for _,pcolor in ipairs(playersInGame()) do
			bcards.deal(4,pcolor,HAND_INDEX_ALT)
			bcount = bcount - 4
		end
		ccount = 4
	else
		cards.putObject(bcards)
	end
	if sBoard.getVar('PromoProjects') then
		Wait.frames(|| cards.putObject(getCardsOnPos(getSnapPos(sBoard,'Project',3))),10)
	else
		trash(getCardsOnPos(getSnapPos(sBoard,'Project',3)))
	end
	Wait.frames(|| cards.flip(),50)
	Wait.frames(|| cards.shuffle(),80)
	for _,pcolor in ipairs(playersInGame()) do
		Wait.frames(|| cards.deal(ccount,pcolor,HAND_INDEX_ALT),90)
	end
	
	local dboard = gftag("DrawBoard")
	local pos = getSnapPos(dboard,'Project')
	Wait.frames( || cards.setPositionSmooth(above(pos)),160 )
	if bcount > 0 and bcount < 16 then
		local bcards = getCardsOnPos(getSnapPos(sBoard,'Project',2))
		local pos = getSnapPos(dboard,'Project',2)
		Wait.frames( || bcards.setPositionSmooth(above(pos)),160 )
	end
end

-- shuffle and place ocean tiles on Mars
function placeOceans()
	local oceans = shuffleList(gtag('Ocean'))
	local mboard = gftag('Mars')
    if not mboard then
        sendError('Could not find Mars board')
        return
    end
	local rot = addPosition(mboard.getRotation(),{0,90,180})
	for index,ocean in ipairs(oceans) do
		local snap = findSnapOnObj(mboard,'Ocean',index)
		if snap then
			local pos = mboard.positionToWorld(snap.position)
			Wait.frames(|| ocean.setPosition(above(pos)),5*index)
			ocean.setRotation(rot)
		end
	end
end
