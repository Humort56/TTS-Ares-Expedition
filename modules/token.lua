function TokenAdd(pcolor, card, add, cancel)
	local add = add or 1
	local name = gnote(card)
	local tokenType = CARDS[name]['tokenType']
	local trueTokenType = tokenType

	if tokenType == 'Science' then trueTokenType = 'Microbe' end

    if add > 0 then
        local bag = gftags({'c'..pcolor,trueTokenType..'Bag'})
        if not bag then
            sendError("Could not find " .. trueTokenType .. " bag", pcolor)
            return
        end

        local tokenPos = card.positionToWorld({0.62,0.6,-1.02})

        for i=1,add do
            local newToken = bag.takeObject()
            newToken.addTag('c'..pcolor)
            newToken.addTag(tokenType..'Token')
            newToken.addTag('OwnedBy'..name)
            newToken.setPosition(tokenPos)
        end

        if cancel ~= true then
            TokenOnPlay(pcolor, tokenType)
        end
    elseif add < 0 then
        local value = -add
        local tokenCount = TokenCount(card) 
        local tokens = gtags({tokenType..'Token','OwnedBy'..name})

        local destroyAll = false
        if tokenCount == value then destroyAll = true end

        for _,token in pairs(tokens) do
            if destroyAll then
                destroyObject(token)
            else
                if 'Custom_Token_Stack' == token['name'] then
                    if value >= token.getQuantity() then
                        destroyObject(token)
                    else
                        for i=1,value do
                            local chip = token.takeObject()
                            destroyObject(chip)
                        end
                    end
                else
                    if value > 0 then
                        value = value - 1
                        destroyObject(token)
                    end
                end
            end
        end
    end
end

function TokenButtonCreate(card)
    card.createButton({
        click_function="TokenButtonActivate", position={-0.62,0.6,0}, height=300, width=350,
        color={0,1,0,0.9}, scale={1,1,1}
    })
    card.addTag('tokenButtonActivated')
end

function TokenButtonRemove(card)
    for _,btn in pairs(card.getButtons() or {}) do
        if 'TokenButtonActivate' == btn.click_function then
            card.removeButton(btn.index)
        end
    end
end

function TokenButtonActivate(card, pcolor, alt)
    local value = gstate(pcolor,'tokenAdd')

    if value == 0 then value = 1 end

    TokenAdd(pcolor, card, value)

    ProjectActionEnd(pcolor)
end

function TokenSelect(pcolor, tokenTypes, value)
    local tokenValue = value or 1

    astate(pcolor,'tokenAdd', tokenValue)

    if 'string' == type(tokenTypes) then
        tokenTypes = {tokenTypes}
    end

    local count = 0
    for _,tokenType in pairs(tokenTypes) do
        local cards = gtags({'c'..pcolor, tokenType..'Holder'})
        for _,card in pairs(cards) do
            if 0 > tokenValue then
                if TokenCount(card) >= -tokenValue then
                    count = count+1
                    TokenButtonCreate(card)
                end
            else
                TokenButtonCreate(card)
            end
        end
    end

    if 0 > tokenValue then
        return count == 0
    end
end

function TokenUnselect(pcolor)
    local cards = gtags({'c'..pcolor, 'tokenButtonActivated'})
    for _,unusedCard in pairs(cards) do
        TokenButtonRemove(unusedCard)
        unusedCard.removeTag('tokenButtonActivated')
    end
end

function TokenCount(card)
	local name = gnote(card)
	local tokenType = CARDS[name]['tokenType']
	local tokens = gtags({tokenType..'Token','OwnedBy'..name})
	local tokenCount = 0

	local stack = nil
	local stackPresent = false
	for _,token in pairs(tokens) do
		if 'Custom_Token_Stack' == token['name'] then
			stackPresent = true
			stack = token
		end
	end

	if stackPresent and stack then
        tokenCount = stack.getQuantity()
        if #tokens > 1 then
            tokenCount = tokenCount + (#tokens - 1)
        end
	else
		tokenCount = #tokens
	end

	return tokenCount
end

function TokenOnPlay(pcolor, tokenType)
    local effects = gmod(pcolor, 'on' .. tokenType .. 'Token')
    
    if 'table' ~= type(effects) then return end

    for effectType, typeData in pairs(effects) do	
		if 'Token' == effectType then
			for _,effect in pairs(typeData) do
				local where = effect['where']

				if 'others' == where then
                    -- todo
				else
					local card = gcard(pcolor, where)
					TokenAdd(pcolor, card, 1)
				end
			end
		end
	end
end