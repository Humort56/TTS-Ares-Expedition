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