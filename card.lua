function CardColor(card)
	for _,color in ipairs(PROJ_COLORS) do
		if card.hasTag(color) then
			return color
		end
	end
	return nil
end

function CardColorHex(card)
    return Color[CardColor(card)]:toHex()
end

