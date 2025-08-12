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
----------------------------------------- Utility: Modding functions

function rcscript()
	for _,obj in ipairs(gtag('TagCounter')) do
	end
end

function dummy(player,click,id)
	broadcastToAll("Not implemented yet")
end