
TAG_COUNTS = {}
COUNTERS = {}

function onLoad(saveData)
  resetAndRecount()
end

function onObjectEnter(object)
	if object.hasTag('countTag') then
		resetAndRecount()
	end
end

function onObjectLeave(object)
	if object.hasTag('countTag') then
		resetAndRecount()
	end
end

function handleEnter(object)
  if object.hasTag("TagCounter") then
    COUNTERS[object.guid] = object
  else
    countChanged(object, 1)
  end
end

function handleLeave(object)
  if object.hasTag("TagCounter") then
    COUNTERS[object.guid] = nil
  else
    countChanged(object, -1)
  end
end

function countChanged(object, delta)
  if object.type == "Deck" or object.type == "Bag" then
    for _, card in ipairs(object.getObjects()) do
      updateTagCounts(card.tags, delta)
    end
  else
    updateTagCounts(object.getTags(), delta)
  end
end

function updateTagCounts(taglist, delta)
  for _, tag in ipairs(taglist) do
  	if tag == 'c'..Global.call('getOwner',self) then
  		-- do nothing
    elseif TAG_COUNTS[tag] then
      TAG_COUNTS[tag] = TAG_COUNTS[tag] + delta
    else
      TAG_COUNTS[tag] = 0
      TAG_COUNTS[tag] = TAG_COUNTS[tag] + delta
    end
  end
end

function resetAndRecount()
  TAG_COUNTS = {}
  COUNTERS = {}

  for _, object in ipairs(self.getObjects()) do
    handleEnter(object)
  end
  updateCounters()
end

function updateCounters()
  for guid, counter in pairs(COUNTERS) do
    if counter then
      local total = 0
      for _, tag in ipairs(counter.getTags()) do
        if TAG_COUNTS[tag] then
          total = total + TAG_COUNTS[tag]
        end
      end
		local field = { tag = "Text", attributes = {id="counterText", outline="#000000", outlineSize="9", color="#FFFFFF", rotation="0 0 180", position="0 0 -11", text=total, fontSize="200", width="1000", height="500"} }
		counter.UI.setXmlTable({field})
    end
  end
end