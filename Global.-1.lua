-- Terraforming Mars – Ares Expedition
-- Script by Nor Dogroth, 10th February
-- MOD ID	2931011437

CARDS = require("modules.cards")
require("modules.card")
require("modules.choice")
require("modules.projects")
require("modules.projectAction")
require("modules.token")
require("modules.utilityTags")
require("modules.scoring")

----------------------------------------------------------------------------------------------------------------------------
-- 					CH CONSTANTS
----------------------------------------------------------------------------------------------------------------------------
PLAYER_COLORS = {'Red','Yellow','Blue','Green'}
RESOURCES = {'MC','Cards','Heat','Plant','Steel','Titan'}
TERRAFORMING = {'Temperature', 'Ocean', 'Forest', 'Oxygen', 'TR'}
STEEL_VALUE = 2
TITAN_VALUE = 3
CARD_VALUE = 3
RANGE_INDEX = {Purple=1, Red=2, Yellow=3, White=4}
RANGE_NAME = {'Purple', 'Red', 'Yellow', 'White'}
TERRAFORMING_RANGES = {
	Temperature = {
		Purple = {min=1,max=6},
		Red = {min=7,max=11},
		Yellow = {min=12,max=16},
		White = {min=17,max=20}
	},
	Oxygen = {
		Purple = {min=1,max=3},
		Red = {min=4,max=7},
		Yellow = {min=8,max=12},
		White = {min=13,max=15}
	}
}
PHASE_NAMES = {'Development','Construction','Action','Production','Research'}
SYMBOLS = {'Building','Space','Power','Science','Jovian','Earth','Plant','Microbe','Animal','Event'}
TOKENS = {'Microbe', 'Animal'}
PROJ_COLORS = {'Green','Blue','Red'}
COL_MSG = {0.8,0.6,0.3}
COL_ERR = {0.9,0.5,0}
HAND_INDEX_DRAW = 4
HAND_INDEX_ALT = 2
HAND_INDEX_CORP = 1
HAND_INDEX_PHASE = 5
RES_POSITIONS = {
	MC = {0.5,0,-1.1},
	Cards = {0.5,0,-0.5},
	Heat = {0.5,0,0},
	Plant = {0.5,0,0.6},
	Steel = {0.5,0,1.1},
	Titan = {-0.5,0,1.1},
}
MAX_TEMP = 20
MAX_OXY = 15

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Global Vars
----------------------------------------------------------------------------------------------------------------------------
SHUFFLING = false
GAME_STARTED = false
CURRENT_PHASE = 0
CURRENT_PHASES = { false,false,false,false,false }
READY_STATE = { Red=false, Yellow=false, Blue=false, Green=false }
SEATED_COLORS = { Red=true,Yellow=true,Blue=true,Green=true }
REACH_TEMP = false
REACH_OXY = false
REACH_OCEAN = false

-- Current effects & modifiers
E_RED = {}
E_BLUE = {}
E_YELLOW = {}
E_GREEN = {}

----------------------------------------------------------------------------------------------------------------------------
-- 					CH Save & Load
----------------------------------------------------------------------------------------------------------------------------
function onSave()
    saved_data = JSON.encode({
    		GAME_STARTED=GAME_STARTED,
    		SEATED_COLORS=SEATED_COLORS,
    		READY_STATE = READY_STATE,
    		CURRENT_PHASE = CURRENT_PHASE,
			CURRENT_PHASES = CURRENT_PHASES,
			REACH_TEMP = REACH_TEMP,
			REACH_OXY = REACH_OXY,
			REACH_OCEAN = REACH_OCEAN,
			E_RED = E_RED,
			E_BLUE = E_BLUE,
			E_YELLOW = E_YELLOW,
			E_GREEN = E_GREEN,
    })
    return saved_data
end

function onLoad(saved_data)
    if saved_data ~= '' then
        local loaded_data = JSON.decode(saved_data)
        GAME_STARTED = loaded_data.GAME_STARTED or GAME_STARTED
        SEATED_COLORS = loaded_data.SEATED_COLORS or SEATED_COLORS
        READY_STATE = loaded_data.READY_STATE or READY_STATE
    	CURRENT_PHASE = loaded_data.CURRENT_PHASE or CURRENT_PHASE
		CURRENT_PHASES = loaded_data.CURRENT_PHASES or CURRENT_PHASES
		REACH_TEMP = loaded_data.REACH_TEMP or REACH_TEMP
		REACH_OXY = loaded_data.REACH_OXY or REACH_OXY
		REACH_OCEAN = loaded_data.REACH_OCEAN or REACH_OCEAN
		E_RED = loaded_data.E_RED or E_RED
		E_BLUE = loaded_data.E_BLUE or E_BLUE
		E_YELLOW = loaded_data.E_YELLOW or E_YELLOW
		E_GREEN = loaded_data.E_GREEN or E_GREEN
    end

	for pcolor, seated in pairs(SEATED_COLORS) do
		if seated then
			local player = Player[pcolor]
			local count = player.getHandCount()
			for hand_index=1,count do
				local cards = player.getHandObjects(hand_index)

				for _, card in pairs(cards) do
					if card.hasTag('Corporation') then
						createActivateCorpButton(card)
					end

					if card.hasTag('Project') then
						createActivateProjectButton(card)
					end
				end
			end

			if 3 == CURRENT_PHASE then
				ProjectActionCreate(pcolor)
			end

		end
	end

    if GAME_STARTED then createStandardActionButtons() end
end
