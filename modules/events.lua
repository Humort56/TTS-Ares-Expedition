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
    if obj.hasTag('Corporation') ~= container.hasTag('Corporation') then return false end
    if obj.hasTag('Project') ~= container.hasTag('Project') then return false end
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