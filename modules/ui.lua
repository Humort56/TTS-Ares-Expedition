function ui_draw(player,click,id)
	if not GAME_STARTED then sendError("Game has not started yet",player.color) return end
	for i=1,5 do
		if id == "DrawButton"..i then
			draw(player.color,i,click ~= '-1')
			return
		end
	end
end

function ui_phase(player,click,id)
	if not GAME_STARTED then sendError("Game has not started yet",player.color) return end
	if #getActivePhaseBoards() > 0 then sendError("Start new round before selecting new phase",player.color) return end
	for i=1,5 do
		if id == "PhaseButton"..i then
			selectPhaseCard(player,i)
			return
		end
	end
end

function ui_discard(player,click,id)
	discardHand(player.color,id == 'HandSellButton')
end

-- function ui_shuffle(player,click,id)
-- 	shufflePhases(player)
-- end

function ui_nextRound(player,click,id)
	if not GAME_STARTED then sendError("Game has not started yet",player.color) return end
	if CURRENT_PHASE ~= 0 then sendError("Complete all phases to start a new round",player.color) return end
	newRound()
end

function ui_score(player, click, id)
	local pcolor = player.color
	if not GAME_STARTED then sendError("Game has not started yet", pcolor) return end
	Score(pcolor, click == '-1')
end

function ui_ready(player,click,id)
	local pcolor = player.color
	if not GAME_STARTED then sendError("Game has not started yet",pcolor) return end
	if CURRENT_PHASE == 0 then sendError("All players need to select a phase card first",pcolor) return end
	if not SEATED_COLORS[pcolor] then sendError("You are not part of the game!",pcolor) return end
	setReady(pcolor,not READY_STATE[pcolor])
end

function initTagCounterUI()
	local field = { tag = "Text", attributes = {id="counterText", outline="#000000", outlineSize="9", color="#FFFFFF", rotation="0 0 180", position="0 0 -11", text="", fontSize="200", width="1000", height="500"}
	}
	for _,counter in ipairs(gtag('TagCounter')) do
		counter.UI.setXmlTable({field})
	end
end
