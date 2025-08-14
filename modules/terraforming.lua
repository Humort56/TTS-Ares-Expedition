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
	onTerraforming(pcolor, 'Ocean', 1)
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
    if not board then sendError('Could not find Mars board') return 0 end

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
    if not board then sendError('Could not find Mars board') return 0 end

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
	onTerraforming(pcolor, 'Temperature', inc)
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
	onTerraforming(pcolor, 'Oxygen', inc)
	return inc
end

-- add a forest vp for given player (do not raise oxygen here)
function addForestVP(pcolor)
	local forestCounter = gftags({'ForestCounter','c'..pcolor})
	if forestCounter then
		forestCounter.call('add')
		onTerraforming(pcolor, 'Forest', 1)
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

-- Trigger associated effects when terraforming
function onTerraforming(playerColor, terraformingType, amount)
	terraformingEffects = gmod(playerColor, 'on'..terraformingType)

	if 'table' ~= type(terraformingEffects) then
		return
	end

	for i = 1, amount do
		onPlay(playerColor, terraformingEffects)
	end
end