-- Terraforming Mars – Ares Expedition
-- Script by Nor Dogroth, 10th February
-- MOD ID	2931011437

CARDS = require("cards")
require("card")
require("choice")
require("project")
require("projectAction")
require("token")
require("utilityTags")
require("scoring")

----------------------------------------------------------------------------------------------------------------------------
-- 					CH CONSTANTS
----------------------------------------------------------------------------------------------------------------------------
PLAYER_COLORS = {'Red','Yellow','Blue','Green'}
RESOURCES = {'MC','Cards','Heat','Plant','Steel','Titan'}
TERRAFORMING = {'Temperature', 'Ocean', 'Forest', 'Oxygen', 'TR'}
STEEL_VALUE = 2
TITAN_VALUE = 3
CARD_VALUE = 3
RANGE_INDEX = {Purple=1, Red=2, Yellow=3, White=4}
RANGE_NAME = {'Purple', 'Red', 'Yellow', 'White'}
TERRAFORMING_RANGES = {
	Temperature = {
		Purple = {min=1,max=6},
		Red = {min=7,max=11},
		Yellow = {min=12,max=16},
		White = {min=17,max=20}
	},
	Oxygen = {
		Purple = {min=1,max=3},
		Red = {min=4,max=7},
		Yellow = {min=8,max=12},
		White = {min=13,max=15}
	}
}
PHASE_NAMES = {'Development','Construction','Action','Production','Research'}
SYMBOLS = {'Building','Space','Power','Science','Jovian','Earth','Plant','Microbe','Animal','Event'}
TOKENS = {'Microbe', 'Animal'}
PROJ_COLORS = {'Green','Blue','Red'}
COL_MSG = {0.8,0.6,0.3}
COL_ERR = {0.9,0.5,0}
HAND_INDEX_DRAW = 4
HAND_INDEX_ALT = 2
HAND_INDEX_CORP = 1
HAND_INDEX_PHASE = 5
RES_POSITIONS = {
	MC = {0.5,0,-1.1},
	Cards = {0.5,0,-0.5},
	Heat = {0.5,0,0},
	Plant = {0.5,0,0.6},
	Steel = {0.5,0,1.1},
	Titan = {-0.5,0,1.1},
}
MAX_TEMP = 20
MAX_OXY = 15

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Global Vars
----------------------------------------------------------------------------------------------------------------------------
SHUFFLING = false
GAME_STARTED = false
CURRENT_PHASE = 0
CURRENT_PHASES = { false,false,false,false,false }
READY_STATE = { Red=false, Yellow=false, Blue=false, Green=false }
SEATED_COLORS = { Red=true,Yellow=true,Blue=true,Green=true }
REACH_TEMP = false
REACH_OXY = false
REACH_OCEAN = false

-- Current effects & modifiers
E_RED = {}
E_BLUE = {}
E_YELLOW = {}
E_GREEN = {}

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Save & Load
----------------------------------------------------------------------------------------------------------------------------
function onSave()
    saved_data = JSON.encode({
    		GAME_STARTED=GAME_STARTED,
    		SEATED_COLORS=SEATED_COLORS,
    		READY_STATE = READY_STATE,
    		CURRENT_PHASE = CURRENT_PHASE,
			CURRENT_PHASES = CURRENT_PHASES,
			REACH_TEMP = REACH_TEMP,
			REACH_OXY = REACH_OXY,
			REACH_OCEAN = REACH_OCEAN,
			E_RED = E_RED,
			E_BLUE = E_BLUE,
			E_YELLOW = E_YELLOW,
			E_GREEN = E_GREEN,
    })
    return saved_data
end

function onLoad(saved_data)
    if saved_data != '' then
        local loaded_data = JSON.decode(saved_data)
        GAME_STARTED = loaded_data.GAME_STARTED or GAME_STARTED
        SEATED_COLORS = loaded_data.SEATED_COLORS or SEATED_COLORS
        READY_STATE = loaded_data.READY_STATE or READY_STATE
    	CURRENT_PHASE = loaded_data.CURRENT_PHASE or CURRENT_PHASE
		CURRENT_PHASES = loaded_data.CURRENT_PHASES or CURRENT_PHASES
		REACH_TEMP = loaded_data.REACH_TEMP or REACH_TEMP
		REACH_OXY = loaded_data.REACH_OXY or REACH_OXY
		REACH_OCEAN = loaded_data.REACH_OCEAN or REACH_OCEAN
		E_RED = loaded_data.E_RED or E_RED
		E_BLUE = loaded_data.E_BLUE or E_BLUE
		E_YELLOW = loaded_data.E_YELLOW or E_YELLOW
		E_GREEN = loaded_data.E_GREEN or E_GREEN
    end

	for pcolor, seated in pairs(SEATED_COLORS) do
		if seated then
			local player = Player[pcolor]
			local count = player.getHandCount()
			for hand_index=1,count do
				local cards = player.getHandObjects(hand_index)

				for _, card in pairs(cards) do
					if card.hasTag('Corporation') then
						createActivateCorpButton(card)
					end

					if card.hasTag('Project') then
						createActivateProjectButton(card)
					end
				end
			end

			if 3 == CURRENT_PHASE then
				ProjectActionCreate(pcolor)
			end

		end
	end

    if GAME_STARTED then createStandardActionButtons() end
 end


----------------------------------------------------------------------------------------------------------------------------
-- 					CH Standard Actions
----------------------------------------------------------------------------------------------------------------------------

function createStandardActionButtons()
	local boards = gtag('ResourceBoard')
	local y, c = 1.445, {0,0,0,0.4}
	local paramSet = {
		{ position={-0.67,1,y}, scale={1.7,1,0.7}, color=c, tooltip='(L) Spend 20 MC to gain a forest VP and raise the oxygen one step\n(R) Raise oxygen for free', click_function='stActBuyForest' },
		{ position={-0.36,1,y}, scale={1.3,1,0.7}, color=c, tooltip='(L) Spend 14 MC to raise the temperature one step (R) Raise it for free', click_function='stActBuyTemp' },
		{ position={-0.02,1,y}, scale={1.9,1,0.7}, color=c, tooltip='(L) Spend 8 plants to gain a forest VP and raise the oxygen one step (R) Gain for free', click_function='stActPlantForest' },
		{ position={0.35,1,y}, scale={1.6,1,0.7}, color=c, tooltip='(L) Spend 8 heat to raise the temperature one step (R) Raise it for free', click_function='stActHeat' },
		{ position={0.68,1,y}, scale={1.6,1,0.7}, color=c, tooltip='(L) Spend 15 MC to flip an ocean tile\n(R) Flip an ocean tile for free', click_function='stActBuyOcean' },
	}
	for _,params in ipairs(paramSet) do
		for _,board in ipairs(boards) do
			board.createButton(params)
		end
	end
end

-- pay MC to gain forest vp and raise oxygen
function stActBuyForest(board,pcolor,alt)
	if pcolor != getOwner(board) then sendError('This board is not yours',pcolor) return end
	if alt then
		if incOxygen(1,pcolor) != 0 then
			printToColor('You raised the oxygen 1 step for free',pcolor)
		else
			sendError('Oxygen is at maximun',pcolor)
		end
	else
		local cost = 20 + gmod(pcolor,'payStandardAction')
		addRes(pcolor,-cost)
		printToColor('You paid '..cost..' MC to gain a forest VP',pcolor)
		plantForest(pcolor)
	end
end

-- pay plants to gain forest vp and raise oxygen
function stActPlantForest(board,pcolor,alt)
	if pcolor != getOwner(board) then sendError('This board is not yours',pcolor) return end
	if alt then
		printToColor('You got 1 forest VP for free',pcolor)
	else
		local plants = 8 + gmod(pcolor,'plantForest')
		addRes(pcolor,-plants,'Plant')
		printToColor('You spent '..plants..' plants to gain a forest VP',pcolor)
	end
	plantForest(pcolor)
end

-- pay MC to raise temperature
function stActBuyTemp(board,pcolor,alt)
	if pcolor != getOwner(board) then sendError('This board is not yours',pcolor) return end
	if getTemperature() == MAX_TEMP and not REACH_TEMP then sendError('Temperature is at maximum',pcolor) return end
	if not alt then
		local cost = 14 + gmod(pcolor,'payStandardAction')
		addRes(pcolor,-cost)
		printToColor('You paid '..cost..' MC to raise the temperature',pcolor)
	end
	incTemperature(1,pcolor)
end

-- pay heat to raise temperature
function stActHeat(board,pcolor,alt)
	if pcolor != getOwner(board) then sendError('This board is not yours',pcolor) return end
	if getTemperature() == MAX_TEMP and not REACH_TEMP then sendError('Temperature is at maximum',pcolor) return end
	if not alt then
		addRes(pcolor,-8,'Heat')
		printToColor('You spent 8 heat to raise the temperature',pcolor)
	end
	incTemperature(1,pcolor)
end

-- pay MC to flip an ocean
function stActBuyOcean(board,pcolor,alt)
	if pcolor != getOwner(board) then sendError('This board is not yours',pcolor) return end
	if #getDryOceans() == 0 and not REACH_OCEAN then sendError('All oceans have been flipped',pcolor) return end
	if not alt then
		local cost = 15 + gmod(pcolor,'payStandardAction')
		addRes(pcolor,-cost)
		printToColor('You paid '..cost..' MC to flip an ocean tile',pcolor)
	end
	flipOcean(pcolor)
end

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Terraforming – Temperature + Oxygen + Oceans
----------------------------------------------------------------------------------------------------------------------------

-- return list of oceans that can be flipped
function getDryOceans()
	return gtags({'Ocean','dry'})
end

-- return list of oceans that are already flipped
function getOceans()
	return gtags({'Ocean','wet'})
end

-- flip an ocean tile and activate it for given player
function flipOcean(pcolor)
	local dryOceans = getDryOceans()
	local ocean = getRandomElement(dryOceans)
	if ocean then
		if #dryOceans == 1 then
			ocean.addTag('lastOcean')
			callAction(' has flipped the last ocean tile. Players may flip it multiple times until the end of this phase.',pcolor)
			REACH_OCEAN = true
		else
			callAction(' has flipped an ocean tile',pcolor)
		end
		ocean.flip()
		ocean.removeTag('dry')
		ocean.addTag('wet')
	elseif REACH_OCEAN then
		ocean = gftag('lastOcean')
	else
		return
	end
	addTR(pcolor)
	activateOceanBonus(ocean,pcolor)
	onTerraforming(pcolor, 'Ocean')
end

-- increase ocean by given value
function incOcean(inc, pcolor)
	for i=1,inc do flipOcean(pcolor) end
end

function activateOceanBonus(ocean,pcolor)
	local nr = tonumber(ocean.memo)
	if nr == 1 then
		addRes(pcolor,2,'Plant')
		printToColor('Ocean: You got 1 TR and 2 plants',pcolor)
	elseif nr == 2 then
		draw(pcolor)
		printToColor('Ocean: You got 1 TR and 1 card',pcolor)
	elseif nr == 3 then
		draw(pcolor)
		addRes(pcolor,1,'Plant')
		printToColor('Ocean: You got 1 TR, 1 card and 1 plant',pcolor)
	elseif nr == 4 then
		addRes(pcolor,2)
		addRes(pcolor,1,'Plant')
		printToColor('Ocean: You got 1 TR, 2 MC and 1 plant',pcolor)
	elseif nr == 5 then
		addRes(pcolor)
		addRes(pcolor,1,'Plant')
		printToColor('Ocean: You got 1 TR, 1 MC and 1 plant',pcolor)
	elseif nr == 6 then
		addRes(pcolor,4)
		printToColor('Ocean: You got 1 TR and 4 MC',pcolor)
	elseif nr == 7 then
		draw(pcolor)
		addRes(pcolor)
		printToColor('Ocean: You got 1 TR, 1 card and 1 MC',pcolor)
	end
end

-- return current temperatur parameter
function getTemperature()
	local board = gftag('Mars')
	local cube = gftag('TemperatureCube')
	if not cube then sendError('Could not find temperature tracker') return 0 end
	for i,snap in ipairs(getSnapsWithTag(board,'TemperatureCube')) do
		local pos = board.positionToWorld(snap.position)
		local d = round(distance(pos,cube.getPosition()),1)
		if d == 0 then return i end
	end
	sendError('Temperature tracker was on invalid position')
	return 0
end

-- return current oxygen parameter
function getOxygen()
	local board = gftag('Mars')
	local cube = gftag('OxygenCube')
	if not cube then sendError('Could not find oxygen tracker') return 0 end
	for i,snap in ipairs(getSnapsWithTag(board,'OxygenCube')) do
		local pos = board.positionToWorld(snap.position)
		local d = round(distance(pos,cube.getPosition()),1)
		if d == 0 then return i end
	end
	sendError('Oxygen tracker was on invalid position')
	return 0
end

-- return set temperature paramer
function setTemperature(value)
	local board = gftag('Mars')
	local pos = above(getSnapPos(board,'TemperatureCube',value))
	local rot = getSnapRot(board,'TemperatureCube',value)
	local cube = gftag('TemperatureCube')
	if not cube then sendError('Could not find temperature tracker') return end
	cube.setPosition(pos)
	cube.setRotationSmooth(rot)
end

-- increase temperature by given value
function incTemperature(inc,pcolor)
	local value = getTemperature()
	local inc = inc or 1
	if MAX_TEMP-value-inc > 0  then
		setTemperature(value+inc)
	elseif MAX_TEMP-value > 0  then
		setTemperature(MAX_TEMP)
		REACH_TEMP = true
		broadcastToAll('Temperature reached its maximum. Players may still raise it with all benefits until the end of the current phase.')
	elseif REACH_TEMP then
	else
		return 0
	end
	callAction(" raised the temperature by " .. inc,pcolor)
	addTR(pcolor,inc)
	printToColor('You got ' .. inc .. ' TR for raising the temperature',pcolor)
	onTerraforming(pcolor, 'Temperature')
	return inc
end

-- return set oxygen paramer
function setOxygen(value)
	local board = gftag('Mars')
	local pos = above(getSnapPos(board,'OxygenCube',value))
	local rot = getSnapRot(board,'OxygenCube',value)
	local cube = gftag('OxygenCube')
	if not cube then sendError('Could not find oxygen tracker') return end
	cube.setPosition(pos)
	cube.setRotationSmooth(rot)
end

-- increase oxygen by given value
function incOxygen(inc,pcolor)
	local value = getOxygen()
	local inc = inc or 1
	if MAX_OXY-value-inc > 0  then
		setOxygen(value+inc)
	elseif MAX_OXY-value > 0  then
		setOxygen(MAX_OXY)
		REACH_OXY = true
		broadcastToAll('Oxygen reached its maximum. Players may still raise it with all benefits until the end of the current phase.')
	elseif REACH_OXY then
	else
		return 0
	end
	callAction(" raised the oxygen by " .. inc,pcolor)
	addTR(pcolor,inc)
	printToColor('You got ' .. inc .. ' TR for raising the oxygen',pcolor)
	onTerraforming(pcolor, 'Oxygen')
	return inc
end

-- add a forest vp for given player (do not raise oxygen here)
function addForestVP(pcolor)
	local forestCounter = gftags({'ForestCounter','c'..pcolor})
	if forestCounter then
		forestCounter.call('add')
		onTerraforming(pcolor, 'Forest')
	end
end

function getForestVP(pcolor)
	local forestCounter = gftags({'ForestCounter','c'..pcolor})
	if forestCounter then
		return tonumber(forestCounter.call('get'))
	end
end

-- increase forest vp by given value
function incForestVP(inc, pcolor)
	for i=1,inc do addForestVP(pcolor) end
end

-- add forest vp and raise oxygen
function plantForest(pcolor)
	addForestVP(pcolor)
	incOxygen(1,pcolor)
end

-- increase forest vp and oxygen by given value
function incForest(inc, pcolor)
	incForestVP(inc, pcolor)
	incOxygen(inc, pcolor)
end

function onTerraforming(pcolor, terraforming)
	mod = gmod(pcolor, 'on'..terraforming)

	if 'number' != type(mod) then
		onPlay(pcolor, mod)
	end
end
----------------------------------------------------------------------------------------------------------------------------
-- 					CH Corporations
----------------------------------------------------------------------------------------------------------------------------
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
			prod['Static'] = (prod[resType] or 0) + production
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
----------------------------------------------------------------------------------------------------------------------------
-- 					CH Projects
----------------------------------------------------------------------------------------------------------------------------

function createActivateProjectButton(card)
	card.createButton({
       click_function="ProjectActivate", position={0,0.6,0}, height=200, width=400,
       color={0,1,0,0.6}, scale={1,1,1}, tooltip="Activate"
    })
end

function onPlay(pcolor, effects)
	for effectType,typeData in pairs(effects) do
		if contains(RESOURCES,effectType) then
			addRes(pcolor, typeData, effectType)
		end
		
		if 'Token' == effectType then
			for _,effect in pairs(typeData) do
				local where = effect['where']

				if 'others' == where then

				else
					local card = gcard(pcolor, where)
					TokenAdd(pcolor, card, 1)
				end
			end
		end

		if 'choice' == effectType then
			for _,effect in pairs(typeData) do
				local card = gcard(pcolor,effect.name)
				ChoiceQueueInsert(pcolor, card, effect.choices)
			end
		end

		if 'Action' == effectType then
			for _,effect in pairs(typeData) do
				gstate(pcolor, 'lastActionCard')
				local state = gstate(pcolor, 'action')
				state[effect.name] = effect.action
				astate(pcolor,'action',state)
				astate(pcolor,'lastActionCard',effect.name)

				local card = gcard(pcolor,effect.name)
				ProjectActionChoiceButtonCreate(card)
				astate(pcolor, 'autoReady', false)
			end
		end

		if 'TR' == effectType then
			addTR(pcolor, typeData)
		end
	end
end

function revealCards(pcolor, reveal)
	local searching = {}

	if reveal['Color'] or (reveal['Symbol'] and 'string' == type(reveal['Symbol'])) then
		searching = {reveal['Color'] or reveal['Symbol']}
	elseif reveal['Symbol'] and 'table' == type(reveal['Symbol']) then
		searching = reveal['Symbol']
	end

	draw(pcolor,1)
	Wait.frames(|| revealCard(pcolor, searching), 50)
end

function revealCard(pcolor, tagList)
	local cards = Player[pcolor].getHandObjects(HAND_INDEX_DRAW)
	for _,tag in pairs(tagList) do
		if cards[#cards].hasTag(tag) then
			broadcastToColor('Keep the last card and discard the rest',pcolor,'Orange')
			return
		end
	end

	draw(pcolor,1)
	Wait.frames(|| revealCard(pcolor, tagList), 50)
end

function activateProjectProduction(card, pcolor)
	local data = CARDS[gnote(card)]
	local cardName = gname(card)
	local cardColor = Color[getProjColor(card)]:toHex()

	for res, resData in pairs(data.production or {}) do
		local total = getProduction(pcolor,res)
		local prod = gprod(pcolor, res)
		for resType, resProd in pairs(resData) do
			if 'Symbol' == resType then
				local symbolList = prod[resType] or {}
				for symbol,value in pairs(resProd) do
					symbolList[symbol] = (symbolList[symbol] or 0) + value
				end
				prod[resType] = symbolList
			else
				prod[resType] = (prod[resType] or 0) + resProd
			end
		end
		aprod(pcolor, res, prod)

		-- update production
		updateProduction(pcolor, res)

		-- calculate diff from start production
		local delta = getProduction(pcolor,res) - total

		mod = gmod(pcolor, 'onPlay'..res..'Production')
		if 'table' == type(mod) then
			for bonus,value in pairs(mod) do
				if 'TR' == bonus then
					local bonusValue = value * delta
					addTR(pcolor, bonusValue)
				end
			end
		end
		
		if delta > 0 then
			printToColor(string.format(
				"Secured %d %s production from your project: [%s] %s",
				delta, res, cardColor, cardName
			), pcolor)
		end
	end
end

function getProjectSnapPos(obj,stag,index)
	local pos = findProjectSnapOnObj(obj,stag,index).position
	return obj.positionToWorld(pos)
end
-- find snap point with given tag and -given index on obj
function findProjectSnapOnObj(obj,stag,index)
	if not obj then sendError("Missing Object") return {position={0,10,0}} end
	local snaps = obj.getSnapPoints()
	local n = 0
	local index = index or 1
	for s,snap in ipairs(snaps) do
		if hasTagInRef(snap,stag) then
			local cards = getCardsOnPos(obj.positionToWorld(snap.position))
			log(cards)
			if nil == cards then
				return snap
			end
		end
	end
	return nil
end

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Resources
----------------------------------------------------------------------------------------------------------------------------
-- inc resource counter for given player and resource
function addRes(pcolor,add,res)
	local res = res or 'MC'

	if 'Cards' == res then
		draw(pcolor,add or 1)
	else
		local resCounter = gftags({res..'Counter','c'..pcolor})
		if resCounter then resCounter.call('addCount',add or 1) end
	end
end

function getRes(pcolor, res)
	local resCounter = gftags({res..'Counter','c'..pcolor})
	if resCounter then
		return tonumber(resCounter.UI.getAttribute('counterText','text'))
	end
end

-- inc resource counters for player by current production rate
function produce(pcolor)
	printToColor("–– Auto Production –– ",pcolor,COL_MSG)
	for i,res in ipairs({'MC','Heat','Plant'}) do
		local add = getProduction(pcolor,res)
		if res == 'MC' then
			add = add + getTR(pcolor)
			if hasActivePhase(pcolor,4) then
				add = add + 4
			end
		end
		addRes(pcolor,add,res)
		printToColor(res .. " production: " .. add,pcolor)
	end
	local drawing = getProduction(pcolor,'Cards')
	if drawing > 0 then
		draw(pcolor,drawing)
		printToColor("Cards from production: " .. drawing,pcolor)
	end
end

-- return current production rate of given player and resource
function getProduction(pcolor,res,cubes)
	local cubes = cubes or getResourceCubes(pcolor,res)
	local value = 0
	for _,cube in ipairs(cubes) do
		value = value + getCubeProd(cube,res,pcolor)
	end
	return value
end

-- update the production based on user state
function updateProduction(pcolor, res)
	local current = getProduction(pcolor, res)
	local prod = gprod(pcolor, res)

	local static = prod['Static'] or 0
	local symbol = prod['Symbol'] or {}
	local forest = prod['Forest'] or 0

	local newProduction = static
	local symbolProd = 0
	for symbol,value in pairs(symbol) do
		symbolProd = value * getTagCount(symbol, pcolor)
		newProduction = newProduction + math.floor(symbolProd)
	end

	local forestProd = forest * getForestVP(pcolor)
	newProduction = newProduction + forestProd

	local delta = newProduction - current
	if delta != 0 then
		addProduction(pcolor, res, delta)
	end
end

-- update
function updateProductions(pcolor)
	for _,res in pairs(RESOURCES) do
		updateProduction(pcolor, res)
	end
end

-- return a list of player cubes representing production rate of given resource
function getResourceCubes(pcolor,res)
	local res = res or 'MC'
	local board = gftags({'c'..pcolor,'ResourceBoard'})
	local pos = board.positionToWorld(RES_POSITIONS[res])
	local size = multPosition(board.getBoundsNormalized().size,{0.4,1,0.15})
	local hitList = Physics.cast({
		origin = pos, type = 3, direction = {0, 1, 0}, size = size, max_distance=2 --, debug=true
	})
	local cubes = {}
	for _,hit in ipairs(hitList) do
		local obj = hit['hit_object']
		if obj.hasTag('PlayerCube') then table.insert(cubes,obj) end
	end
-- 	log(#cubes .. " Würfel gefunden")
	return cubes
end

-- return production value for given player cube depending on its position
function getCubeProd(cube,res,pcolor)
	local pcolor = pcolor or getOwner(cube)
	local res = res or 'MC'
	local board = gftags({'c'..pcolor,'ResourceBoard'})
	for i,snap in ipairs(getSnapsWithTag(board,res)) do
		local pos = board.positionToWorld(snap.position)
		local d = round(distance(pos,cube.getPosition()),1)
		if d == 0 then return getSnapResValue(i) end
	end
end

-- turn resource production field index into its shown value
function getSnapResValue(index)
	if index < 11 then return index-1
	elseif index == 11 then return 10
	elseif index == 12 then return 20
	elseif index == 13 then return 30
	else return 0 end
end

-- turn resource production field value into its index
function getResSnapIndex(value)
	if value < 20 then return value + 1
	elseif value == 20 then return 12
	elseif value == 30 then return 13
	else return 1 end
end

-- return list of existing production fields for given resource
function getResProdFiels(res)
	local fields = {20,10,9,8,7,6,5,4,3,2,1}
	if res != 'Steel' and res != 'Titan' then
		table.insert(fields,1,30)
	end
	return fields
end

-- increase production rate of given resource for given player
function addProduction(pcolor,res,add)
	local cubes = getResourceCubes(pcolor,res)
	local value = math.max(0,getProduction(pcolor,res,cubes) + add)
	updateProductionCubes(pcolor,res,value,cubes)
end

-- set player cubes to set production rate for given resource
function updateProductionCubes(pcolor,res,value,cubes)
	local board = gftags({'c'..pcolor,'ResourceBoard'})
	local cubes = cubes or getResourceCubes(pcolor,res)
	local fields = getResProdFiels(res)
	local ccount = 0
	for _,field in ipairs(fields) do
		local fcount = 0
		while value >= field do
			ccount = ccount + 1
			fcount = fcount + 1
			local cube = cubes[ccount] or getNewPlayerCube(pcolor)
			local index = getResSnapIndex(field)
			local pos = above(getSnapPos(board,res,index),fcount)
			cube.setPosition(pos)
			value = value - field
		end
	end
	if #cubes > ccount then
		for i=ccount+1,#cubes do cubes[i].destruct() end
	end
end

-- return a new created player cube
function getNewPlayerCube(pcolor)
	local bag = gftags({'c'..pcolor,'CubeBag'})
	return bag.takeObject()
end

-- turn index of TR snap points into TR rank
function getSnapTRValue(index)
	if index < 5 then return 5
	elseif index < 25 then return index+1
	elseif index == 25 then return 25
	elseif index < 52 then return index-1
	else return index-52 end
end

-- turn TR into snap point index
function getTRSnapIndex(value)
	if value == 5 then return 1
	elseif value < 5 then return value+52
	elseif value <= 25 then return value-1
	else return value+1
	end
end

-- return a list of player cubes representing TR value
function getTRCubes(pcolor)
	local board = gftag('Mars')
	local pos = addPosition(board.getPosition(),{-1,0,0})
	local size = board.getBoundsNormalized().size
	local hitList = Physics.cast({
		origin = pos, type = 3, direction = {0, 1, 0}, size = {size.z,size.y,size.x}, max_distance=2 --, debug=true
	})
	local cubes = {}
	for _,hit in ipairs(hitList) do
		local obj = hit['hit_object']
		if obj.hasTag('PlayerCube') and obj.hasTag('c'..pcolor) then table.insert(cubes,obj) end
	end
-- 	log(#cubes .. " Würfel gefunden")
	return cubes
end

-- return TR value for given player cube depending on its position
function getCubeTR(cube,pcolor)
	local pcolor = pcolor or getOwner(cube)
	local board = gftag('Mars')
	for i,snap in ipairs(getSnapsWithTag(board,'TR')) do
		local pos = board.positionToWorld(snap.position)
		local d = round(distance(pos,cube.getPosition()),1)
		if d == 0 then return getSnapTRValue(i) end
	end
	return 0
end

-- return current TR rank of given player
function getTR(pcolor)
	local cubes = getTRCubes(pcolor)
	local trvalue = 0
	for _,cube in ipairs(cubes) do
		trvalue = trvalue + getCubeTR(cube,pcolor)
	end
	return trvalue
end

-- increase TR rank of given player by given value
function addTR(pcolor,add)
	local board = gftag('Mars')
	local cubes = getTRCubes(pcolor)
	local ccount = 0
	local add = add or 1
	local newTR = math.max(getTR(pcolor) + add,0)
	while newTR >= 50 do
		ccount = ccount + 1
		local cube = cubes[ccount] or getNewPlayerCube(pcolor)
		local pos = above(getSnapPos(board,'TR',51),ccount)
		cube.setPosition(pos)
		newTR = newTR - 50
	end
	if newTR > 0 or ccount == 0 then
		ccount = ccount + 1
		local cube = cubes[ccount] or getNewPlayerCube(pcolor)
		local index = getTRSnapIndex(newTR)
		local pos = above(getSnapPos(board,'TR',index),ccount)
		cube.setPosition(pos)
	end
	if #cubes > ccount then
		for i=ccount+1,#cubes do cubes[i].destruct() end
	end
	Wait.frames(|| printToColor('You have '..getTR(pcolor)..' TR, now', pcolor), 1)
end

-- alias of addTR
function incTR(inc, pcolor)
	addTR(pcolor, inc)
end

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Phases
----------------------------------------------------------------------------------------------------------------------------
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
	local pos = getSnapPos(Global,'PhaseBoard',6)
	if not board.is_face_down then board.setRotation({0,180,180}) end
	board.setPosition(above(pos,nr))
	board.removeTag('active')
end

-- place phase board of given number in the middle to show it has been selected
function setPhaseBoard(nr)
	local board = gftags({'PhaseBoard','Ph'..nr})
	local pos = getSnapPos(Global,'PhaseBoard',nr)
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

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Drawing
----------------------------------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Setup
----------------------------------------------------------------------------------------------------------------------------
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


----------------------------------------------------------------------------------------------------------------------------
-- 					CH Misc
----------------------------------------------------------------------------------------------------------------------------
function getCardsOnPos(pos,distance,faceDown)
	local pos = above(pos,-0.5)
	local hitList = Physics.cast({
		origin = pos, direction = {0, 1, 0}, max_distance = distance or 1
	})
-- 	log(#hitList..' hits')
	for i = 1,#hitList,1 do
		local obj = hitList[i]['hit_object']
		if obj.name == 'Deck' or obj.name == 'Card' then
			if not faceDown or (faceDown == obj.is_face_down) then
				return obj
			end
		end
	end
	return nil
end

-- put obj into the game box
function trash(obj)
	local box = gftag("GameBox")
	if box then box.putObject(obj)
	else obj.destruct() end
end

-- return player color that owns given object
function getOwner(obj)
	for _,pcolor in ipairs(PLAYER_COLORS) do
		if obj.hasTag('c'..pcolor) then return pcolor end
	end
	return nil
end

-- return list of player colors in game (does not depend on seat)
function playersInGame()
	local pcolors = {}
	for pcolor,seated in pairs(SEATED_COLORS) do
		if seated then table.insert(pcolors,pcolor) end
	end
	return pcolors
end

-- returns steam name or color if player is not seated at the moment
function playerName(pcolor)
	return Player[pcolor].steam_name or pcolor
end
----------------------------------------------------------------------------------------------------------------------------
-- 					CH Events
----------------------------------------------------------------------------------------------------------------------------
function onObjectEnterZone(zone, object)
    if zone.getVar('onObjectEnter') then
      zone.call('onObjectEnter', object)
    end
end

function onObjectLeaveZone(zone, object)
    if zone.getVar('onObjectLeave') then
      zone.call('onObjectLeave', object)
    end
end

function onObjectSpawn(obj)
	-- create button on corps whenver they spawn
    if obj.hasTag("Corporation") then
    	if not obj.hasTag("activated") then
    		createActivateCorpButton(obj)
    	end
    end

	if obj.hasTag('Project') then
		if not obj.hasTag("activated") then
			createActivateProjectButton(obj)
    	end
	end
end

function tryObjectEnterContainer(container, obj)
	-- make sure phase cards cannot form or enter a deck
	if container.hasTag('GameBox') then return true end
    if obj.hasTag("Phase") then return false end
    if obj.hasTag('Corporation') != container.hasTag('Corporation') then return false end
    if obj.hasTag('Project') != container.hasTag('Project') then return false end
    return true
end

function onPlayerConnect(player)
	if not player.promoted then player.promote() end
end

function onObjectPickUp(pcolor,obj)
	if obj.hasTag('countTag') then return end
	if obj.hasTag('Project') or obj.hasTag('Coorporation') then
		obj.addTag('countTag')
	end
end
----------------------------------------------------------------------------------------------------------------------------
-- 					CH UI functions
----------------------------------------------------------------------------------------------------------------------------
function ui_draw(player,click,id)
	if not GAME_STARTED then sendError("Game has not started yet",player.color) return end
	for i=1,5 do
		if id == "DrawButton"..i then
			draw(player.color,i,click != '-1')
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
	if CURRENT_PHASE != 0 then sendError("Complete all phases to start a new round",player.color) return end
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

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Messaging
----------------------------------------------------------------------------------------------------------------------------
function sendError(text,pcolor)
	local text = "Error – "..text
	if pcolor then broadcastToColor(text,pcolor,COL_ERR)
	else broadcastToAll(text,COL_ERR)
	end
end

function callAction(text,pcolor)
	broadcastToAll('['..Color[pcolor]:toHex()..']'..playerName(pcolor) .. "[FFFFFF]" .. text)
end
----------------------------------------------------------------------------------------------------------------------------
-- 					CH Utility
----------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------- Utility: GUID
-- return object with given guid
function gguid(guid)
	return getObjectFromGUID(guid)
end
gg = gguid

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------- Utility: Obj Info
function gnote(obj)
	if type(obj) == 'userdata' then
		return obj.getGMNotes() or ""
	elseif type(obj) == 'table' then
		return obj.gm_notes
	elseif type(obj) == 'string' then
		if gguid(obj) then return gguid(obj).getGMNotes() end
	else return ""
	end
end

function gname(card)
	local name = gnote(card)
	return CARDS[name] and CARDS[name].name or name
end

function gcard(pcolor,name,all)
	local tags = {}

	if all == nil then
		table.insert(tags, 'c'..pcolor)
	end

	local cards = gtags(tags)
	for _,card in pairs(cards) do
		if name == gnote(card) then
			return card
		end
	end
end

function gowner(card)
	for _,color in pairs(PLAYER_COLORS) do
		if card.hasTag('c'..color) then
			return color
		end
	end

	return nil
end

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------- Utility: Snap Points
-- return snap points of given object
function gsnaps(obj)
	return obj.getSnapPoints()
end

-- copy snap points of given object to var
function csnaps(obj)
	TEMP_SNAPS = obj.getSnapPoints()
end

-- paste snap points from var to given object
function psnaps(obj)
	obj.setSnapPoints(TEMP_SNAPS or {})
end

function getSnapPos(obj,stag,index)
	local pos = findSnapOnObj(obj,stag,index).position
	return obj.positionToWorld(pos)
end

function getSnapRot(obj,stag,index)
	local rot = findSnapOnObj(obj,stag,index).rotation
	return addPosition(rot,obj.getRotation())
end

-- find snap point with given tag and given index on obj
function findSnapOnObj(obj,stag,index)
	if not obj then sendError("Missing Object") return {position={0,10,0}} end
	local snaps = obj.getSnapPoints()
	local n = 0
	local index = index or 1
	for s,snap in ipairs(snaps) do
		if hasTagInRef(snap,stag) then
			n = n + 1
			if n == index then return snap end
		end
	end
	return nil
end

-- find snap point with given tags and given index on obj
function findSnapsOnObj(obj,stags,index)
	local snaps = obj.getSnapPoints()
	local n = 0
	local index = index or 1
	for s,snap in ipairs(snaps) do
		if hasTagsInRef(snap,stags) then
			n = n + 1
			if n == index then return snap end
		end
	end
	return nil
end

-- return all snap points on obj with given tag
function getSnapsWithTag(obj,stag)
	local snaps = {}
	for s,snap in ipairs(obj.getSnapPoints()) do
		if hasTagInRef(snap,stag) then
			table.insert(snaps,snap)
		end
	end
	return snaps
end

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------- Utility: Lists
-- check if list contains given element
function contains(list,obj)
	for _,entry in pairs(list) do
		if entry == obj then return true end
	end
	return false
end

-- check if list contains given element
function containsKey(list,key)
	for entry,_ in pairs(list) do
		if entry == key then return true end
	end
	return false
end

-- shuffle given list
function shuffleList(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

function shuffleObjectList(list)
	local keys = {}
	for key,entry in pairs(list) do
		table.insert(keys,key)
	end
	keys = shuffleList(keys)
	local shuffledList = {}
	for _,key in ipairs(keys) do
		shuffledList[key] = list[key]
	end
	return shuffledList
end

-- return random element from given list
function getRandomElement(list)
	for i=1,3 do math.random() end
	if list == nil or #list == 0 then return nil end
	return list[math.random(#list)]
end

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------- Utility: Positions & Maths
-- above given pos
function above(pos,z)
	local z = z or 1
	return {pos[1],pos[2]+z,pos[3]}
end

function addPosition(pos1,pos2)
	return {pos1[1]+pos2[1],pos1[2]+pos2[2],pos1[3]+pos2[3]}
end

function multPosition(pos1,pos2)
	return {pos1[1]*pos2[1],pos1[2]*pos2[2],pos1[3]*pos2[3]}
end

-- return horizontal distance between given positions
function distance(a,b)
	local a = type(a) == 'userdata' and a.getPosition() or a
	local b = type(b) == 'userdata' and b.getPosition() or b
	return math.sqrt((a[1]-b[1])*(a[1]-b[1]) + (a[3]-b[3])*(a[3]-b[3]))
end

function movePosition(obj,pos)
	local pos = addPosition(obj.getPosition(),pos)
	obj.setPosition(pos)
end

-- round to x decimal places
function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------- Utility: Modding functions

function rcscript()
	for _,obj in ipairs(gtag('TagCounter')) do
	end
end

function dummy(player,click,id)
	broadcastToAll("Not implemented yet")
end

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Projects
----------------------------------------------------------------------------------------------------------------------------
-- return project card color (green, blue, red)
function getProjColor(card)
	for _,color in ipairs(PROJ_COLORS) do
		if card.hasTag(color) then
			return color
		end
	end
	return nil
end

function getColorCount(pcolor, color)
	local cards = gtags({'c'..pcolor, color})
	return #cards
end

function playCardOnBoard(pcolor, card)
	local board = gftags({'c'..pcolor,'PlayerBoard'})

	local cardColor = getProjColor(card)
	local cards = gtags({'c'..pcolor, cardColor, 'activated'})
	local count = 1
	if cards ~= nil then
		count = #cards + 1
	end

	local pos = getSnapPos(board, getProjColor(card), count)
	card.setPosition(above(pos,0.7))
	card.addTag('c'..pcolor)
	card.addTag('activated')
	card.addTag('position'..cardColor..count)
	card.clearButtons()

	Wait.frames(|| card.setLock(true),40)
	Wait.frames(|| playTag(pcolor, card), 50)
	if 3 == CURRENT_PHASE and CARDS[gnote(card)]['action'] then
		Wait.frames(|| ProjectActionButtonCreate(card), 50)
	end
end

function fulfillConditions(conditions, pcolor)
	for element,condition in pairs(conditions) do
		if not fulfillCondition(element, condition, pcolor) then
			sendError(getConditionError(element, condition, pcolor), pcolor)
			return false
		end
	end

	return true
end

function fulfillCondition(element, condition, pcolor)
	if containsKey(TERRAFORMING_RANGES, element) then
		local value = _G['get'..element]()
		local bound = condition.bound
		local puffer = gmod(pcolor, 'conditionPuffer') + gmod(pcolor, 'conditionPufferTemp')
		if puffer > 1 then puffer = 1 end
		local rangeIndex = RANGE_INDEX[condition.range]

		if 'Lower' == bound then
			if rangeIndex > 1 then rangeIndex = rangeIndex - puffer end
			local rangeName = RANGE_NAME[rangeIndex]
			local range = TERRAFORMING_RANGES[element][rangeName]
			return value >= range.min
		elseif 'Upper' == bound then
			if rangeIndex < 4 then rangeIndex = rangeIndex + puffer end
			local rangeName = RANGE_NAME[rangeIndex]
			local range = TERRAFORMING_RANGES[element][rangeName]
			return value <= range.max
		end
	end

	if 'Ocean' == element then
		local value = #getOceans()
		local limit = condition.value
		local bound = condition.bound

		if 'Lower' == bound then
			return value >= limit
		elseif 'Upper' == bound then
			return value <= limit
		end
	end

	if 'TR' == element then
		local value = getTR(pcolor)
		local limit = condition

		return value >= limit
	end

	if 'Symbol' == element then
		local symbolValid = true

		for symbol,value in pairs(condition) do
			local current = getTagCount(symbol, pcolor)
			if value > current then symbolValid = false end
		end

		return symbolValid
	end

	if 'Resources' == element then
		local resValid = true

		for res,value in pairs(condition) do
			local current = getRes(pcolor, res)
			if value > current then resValid = false end
		end

		return resValid
	end
end

function getConditionError(element, condition, pcolor)
	local colorError = Color.new(COL_ERR[1],COL_ERR[2],COL_ERR[3]):toHex()
	local error = 'The '..element..' condition is not met: '

	if containsKey(TERRAFORMING_RANGES, element) then
		local colorRange = Color.fromString(condition.range):toHex()
		error = error .. '['..colorRange..']'..condition.range..'['..colorError..']'

		if 'Lower' == condition.bound then
			return error..' or higher'
		elseif 'Upper' == condition.bound then
			return error..' or lower'
		end
	end

	if 'Ocean' == element then
		error = error..condition.value

		if 'Lower' == condition.bound then
			return error..' or higher'
		elseif 'Upper' == condition.bound then
			return error..' or lower'
		end
	end

	if 'TR' == element then
		return error..condition..' or higher'
	end

	if 'Symbol' == element then
		symbols = ''
		count = 0

		for symbol,value in pairs(condition) do
			local current = getTagCount(symbol, pcolor)
			if value > current then
				count = count + 1
				symbols = symbols..' ('..value..' '..symbol..')'
			end
		end

		local verb = 'is'
		if count > 1 then verb = 'are' end
		return 'The following symbol(s) condition '..verb..' not met:'..symbols
	end

	if 'Resources' == element then
		resources = ''
		count = 0

		for res,value in pairs(condition) do
			local current = getRes(pcolor, res)
			if value > current then
				count = count + 1
				resources = resources..' ('..value..' '..res..')'
			end
		end

		local verb = 'is'
		if count > 1 then verb = 'are' end
		return 'The following resource(s) condition '..verb..' not met:'..resources
	end
end

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Effects + Production
----------------------------------------------------------------------------------------------------------------------------
-- payEarth				pay +x MC for card with Earth tag → similar for other tags
-- payTwenty			pay +x MC for card with <=20 cost
-- payGreen				pay +x MC for green projects → simalr for blue and red
-- plantForest			spend x less plants for forests
-- HeatAsMC			spend heat as MC
-- titanValue				titan is worht +x MC
-- researchDraw		on research draw +x cards
-- researchKeep		on research keep +x cards
-- conditionPuffer		ignore one oxygen/temperature condition level

-- onPlayTag			when playing card with given tag, trigger cards with that event	
-- onPlaySteelProduction		trigger when playing card with this production
-- onOceanFlip						triggered when ocean is flipped by the player
	-- TR → gain TR

function playTag(pcolor,card)
	for _,tag in pairs(card.getTags()) do
		local mod = 0
		if string.sub(tag, -1) == '2' then tag = string.sub(tag, 1, -2) end
		if contains(SYMBOLS, tag) or contains(PROJ_COLORS, tag) then
			mod = gmod(pcolor, 'onPlay'..tag)
		end
		if 'Project' == tag then
			mod = gmod(pcolor, 'onPlayCard')
		end
		
		if 'number' != type(mod) then
			onPlay(pcolor,mod)
		end
	end
	
	local data = CARDS[gnote(card)]

	ProjectInstant(pcolor, card, data.instant or {})

	amodList(pcolor, data.afterEffects or {})

	-- reactivate onPlayAction cards if projectLimit not reached
	if gstate(pcolor,'projectLimit') > 0 and not ProjectActionGetInUse(pcolor, 'inUse') then
		ProjectActionOnPlay(pcolor)
	end
end

function geffects(pcolor)
	local state = pcolor == 'Red' and E_RED 
			or	pcolor == 'Blue' and E_BLUE
			or	pcolor == 'Yellow' and E_YELLOW
			or	pcolor == 'Green' and E_GREEN or {}
	
	if not state.effect then state.effect = {} end
	
	return state.effect
end

function gmod(pcolor,effect)
	local effects = geffects(pcolor)
	return effects[effect] or 0
end

function zmod(pcolor,effect)
	local mod = gmod(pcolor,effect)
	if type(mod) == 'number' then
		amod(pcolor,effect,-mod)
	end
end

function amod(pcolor,effect,add)
	local effects = geffects(pcolor)
	if 'number' == type(add) then
		effects[effect] = (effects[effect] or 0) + (add or 1)
	else
		local onPlay = effects[effect] or {}
		for res,value in pairs(add) do
			if 'number' == type(value) then
				onPlay[res] = (onPlay[res] or 0) + (value or 1)
			else
				local tableToken = onPlay[res] or {}
				table.insert(tableToken, value)
				onPlay[res] = tableToken
			end
		end
		effects[effect] = onPlay
	end
end

function amodList(pcolor, list)
	for effect, value in pairs(list) do
		amod(pcolor,effect,value)
	end
end

function gproductions(pcolor)
	local state = pcolor == 'Red' and E_RED 
			or	pcolor == 'Blue' and E_BLUE
			or	pcolor == 'Yellow' and E_YELLOW
			or	pcolor == 'Green' and E_GREEN
	
	if not state.production then state.production = {} end

	return state.production
end

function gprod(pcolor, prod)
	local productions = gproductions(pcolor)
	return productions[prod] or {}
end

function aprod(pcolor, prod, data)
	local productions = gproductions(pcolor)
	productions[prod] = data
end

function gstates(pcolor)
	local state = pcolor == 'Red' and E_RED 
			or	pcolor == 'Blue' and E_BLUE
			or	pcolor == 'Yellow' and E_YELLOW
			or	pcolor == 'Green' and E_GREEN
	
	if not state.state then state.state = {} end

	return state.state
end

function gstate(pcolor,state)
	local states = gstates(pcolor)
	return states[state] or 0
end

function astate(pcolor,state,add)
	local states = gstates(pcolor)
	states[state] = add
end

function mstate(pcolor,state,add)
	local states = gstates(pcolor)
	states[state] = (states[state] or 0) + (add or 1)
end

function astateList(pcolor, list)
	for state, value in pairs(list) do
		mstate(pcolor,state,value)
	end
end
