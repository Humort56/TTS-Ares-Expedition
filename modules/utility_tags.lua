----------------------------------------------------------------------------------------------------------------------------
----------------------------------------- Utility: Tags
-- return objects with given tag
function gtag(tag)
	return getObjectsWithTag(tag)
end

-- return objects with given tags
function gtags(tags)
	if type(tags) == 'String' then return gtag(tags) end
	return getObjectsWithAllTags(tags)
end

-- return objects with given tag
function gftag(tag)
	local objs = gtag(tag)
	if #objs > 0 then return objs[1] else return nil end
end

-- return objects with given tag
function gftags(tags)
	if type(tags) == 'String' then return gftag(tags) end
	local objs = gtags(tags)
	if #objs > 0 then return objs[1] else return nil end
end

-- has given object reference given tag
function hasTagInRef(ref, stag)
	for _, ctag in ipairs(ref.tags) do
		if ctag == stag then return true end
	end
	return false
end

-- has given object reference given tags
function hasTagsInRef(ref, stags)
	for _, stag in ipairs(stags) do
		if not hasTagInRef(ref, stag) then return false end
	end
	return true
end

-- return the count of a tag for a specific player
function getTagCount(tag, pcolor)
	local counter = gtags({'TagCounter', 'c'..pcolor, tag})
	local value = counter[1].UI.getAttribute('counterText', 'text')
	return tonumber(value)
end