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
	if delta ~= 0 then
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
    if not board then
        sendError('Could not find resource board for ' .. pcolor)
        return {}
    end

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
    if not board then
        sendError('Could not find resource board for ' .. pcolor)
        return 0
    end

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
	if res ~= 'Steel' and res ~= 'Titan' then
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
            if not cube then
                sendError('Could not find player cube for ' .. pcolor)
                return
            else
                local index = getResSnapIndex(field)
                local pos = above(getSnapPos(board,res,index),fcount)
                cube.setPosition(pos)
                value = value - field
            end
		end
	end
	if #cubes > ccount then
		for i=ccount+1,#cubes do cubes[i].destruct() end
	end
end

-- return a new created player cube
function getNewPlayerCube(pcolor)
	local bag = gftags({'c'..pcolor,'CubeBag'})
    if not bag then
        sendError('Could not find player cube bag for ' .. pcolor)
        return nil
    end
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
    if not board then sendError('Could not find Mars board') return {} end

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
    if not board then sendError('Could not find Mars board') return 0 end

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
function addTR(pcolor, add)
	local board = gftag('Mars')
	local cubes = getTRCubes(pcolor)
	local ccount = 0
	local add = add or 1
	local newTR = math.max(getTR(pcolor) + add,0)

	while newTR >= 50 do
		ccount = ccount + 1
		local cube = cubes[ccount] or getNewPlayerCube(pcolor)
        if not cube then
            sendError('Could not find player cube for ' .. pcolor)
            return
        end
		local pos = above(getSnapPos(board,'TR',51),ccount)
		cube.setPosition(pos)
		newTR = newTR - 50
	end

	if newTR > 0 or ccount == 0 then
		ccount = ccount + 1
		local cube = cubes[ccount] or getNewPlayerCube(pcolor)
        if not cube then
            sendError('Could not find player cube for ' .. pcolor)
            return
        end
		local index = getTRSnapIndex(newTR)
		local pos = above(getSnapPos(board,'TR',index),ccount)
		cube.setPosition(pos)
	end

	if #cubes > ccount then
		for i=ccount+1,#cubes do cubes[i].destruct() end
	end

	onTerraforming(pcolor, 'TR', add)

	Wait.frames(|| printToColor('You have '..getTR(pcolor)..' TR, now', pcolor), 1)
end

-- alias of addTR
function incTR(inc, pcolor)
	addTR(pcolor, inc)
end
