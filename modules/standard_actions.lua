-- Helper to check if temperature can be raised
function RaiseTemperatureAllowed(playerColor)
	if getTemperature() == MAX_TEMP and not REACH_TEMP then
		sendError('Temperature is at maximum', playerColor)
		return false
	end

	return true
end

-- Helper to check if oceans can be flipped
function FlipOceanAllowed(playerColor)
	if #getDryOceans() == 0 and not REACH_OCEAN then
		sendError('All oceans have been flipped', playerColor)
		return false
	end

	return true
end

-- Helper to check board ownership
function CheckBoardOwnership(board, playerColor)
	if playerColor ~= getOwner(board) then
		sendError('This board is not yours', playerColor)
		return false
	end
	return true
end

function createStandardActionButtons()
	local boards = gtag('ResourceBoard')
	local y, c = 1.445, {0,0,0,0.4}
	local paramSet = {
		{
            position={-0.67,1,y},
            scale={1.7,1,0.7},
            color=c,
            tooltip='(L) Spend 20 MC to gain a forest VP and raise the oxygen one step\n(R) Raise oxygen for free',
            click_function='BuyForest'
        },
		{
            position={-0.36,1,y},
            scale={1.3,1,0.7},
            color=c,
            tooltip='(L) Spend 14 MC to raise the temperature one step (R) Raise it for free',
            click_function='BuyTemp'
        },
		{
            position={-0.02,1,y},
            scale={1.9,1,0.7},
            color=c,
            tooltip='(L) Spend 8 plants to gain a forest VP and raise the oxygen one step (R) Gain for free',
            click_function='PlantForest'
        },
		{
            position={0.35,1,y},
            scale={1.6,1,0.7},
            color=c,
            tooltip='(L) Spend 8 heat to raise the temperature one step (R) Raise it for free',
            click_function='RaiseTemp'
        },
		{
            position={0.68,1,y},
            scale={1.6,1,0.7},
            color=c,
            tooltip='(L) Spend 15 MC to flip an ocean tile\n(R) Flip an ocean tile for free',
            click_function='BuyOcean'
        },
	}

	for _,params in ipairs(paramSet) do
		for _,board in ipairs(boards) do
			board.createButton(params)
		end
	end
end

-- pay MC to gain forest vp and raise oxygen
function BuyForest(board, playerColor, alt)
    if not CheckBoardOwnership(board, playerColor) then return end

	if alt then
		if incOxygen(1, playerColor) ~= 0 then
			printToColor('You raised the oxygen 1 step for free',playerColor)
		else
			sendError('Oxygen is at maximun',playerColor)
		end
	else
        -- TODO: add a check for money
		local cost = 20 + gmod(playerColor,'payStandardAction')
		addRes(playerColor, -cost)
		printToColor('You paid '..cost..' MC to gain a forest VP', playerColor)
		plantForest(playerColor)
	end
end

-- pay plants to gain forest vp and raise oxygen
function PlantForest(board, playerColor, alt)
    if not CheckBoardOwnership(board, playerColor) then return end

	if alt then
		printToColor('You got 1 forest VP for free', playerColor)
	else
        -- TODO: add a check for plant
		local plants = 8 + gmod(playerColor,'plantForest')
		addRes(playerColor, -plants, 'Plant')
		printToColor('You spent '..plants..' plants to gain a forest VP', playerColor)
	end

	plantForest(playerColor)
end

-- pay MC to raise temperature
function BuyTemp(board, playerColor, alt)
	if not CheckBoardOwnership(board, playerColor) then return end
	if not RaiseTemperatureAllowed(playerColor) then return end

	if not alt then
		local cost = 14 + gmod(playerColor, 'payStandardAction')
		addRes(playerColor, -cost)
		printToColor('You paid '..cost..' MC to raise the temperature', playerColor)
	end
	incTemperature(1, playerColor)
end

-- pay heat to raise temperature
function RaiseTemp(board, playerColor, alt)
	if not CheckBoardOwnership(board, playerColor) then return end
	if not RaiseTemperatureAllowed(playerColor) then return end

	if not alt then
        -- TODO: add a check for heat
		addRes(playerColor, -8, 'Heat')
		printToColor('You spent 8 heat to raise the temperature', playerColor)
	end
	incTemperature(1, playerColor)
end

-- pay MC to flip an ocean
function BuyOcean(board, playerColor, alt)
	if not CheckBoardOwnership(board, playerColor) then return end
	if not FlipOceanAllowed(playerColor) then return end

	if not alt then
		local cost = 15 + gmod(playerColor, 'payStandardAction')
		addRes(playerColor, -cost)
		printToColor('You paid '..cost..' MC to flip an ocean tile', playerColor)
	end
	flipOcean(playerColor)
end
