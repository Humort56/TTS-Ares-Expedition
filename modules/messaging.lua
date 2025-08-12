
function sendError(text,pcolor)
	local text = "Error – "..text
	if pcolor then broadcastToColor(text,pcolor,COL_ERR)
	else broadcastToAll(text,COL_ERR)
	end
end

function callAction(text,pcolor)
	broadcastToAll('['..Color[pcolor]:toHex()..']'..playerName(pcolor) .. "[FFFFFF]" .. text)
end