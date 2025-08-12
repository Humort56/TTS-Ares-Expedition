STEPS = {
    STEP = 1,
    LARGE_STEP = 8
}
ALLOW_NEGATIVE = true

-- current_data = {count = 0}
CURRENT_COUNT = 0

function onLoad(saved_data)
    if saved_data != '' then
        local loaded_data = JSON.decode(saved_data)
        if loaded_data.count then
            CURRENT_COUNT = loaded_data.count
        end
    end

    setupButtons()
    setCounterValue()
end

function onSave()
    saved_data = JSON.encode({count=CURRENT_COUNT})
    return saved_data
end

-- Edit Nor Dogroth: Use different func to detect alt click
function setupButtons()
    setButton("decrementXButton", "onClickDecrementMajStep", "-", "LARGE_STEP")
    setButton("decrementYButton", "onClickDecrementMinStep", "-", "STEP")
    setButton("incrementXButton", "onClickIncrementMajStep", "+", "LARGE_STEP")
    setButton("incrementYButton", "onClickIncrementMinStep", "+","STEP")
end

function setButton(id, func, prefix, value)
    self.UI.setAttribute(id, "text", prefix .. STEPS[value])
    self.UI.setAttribute(id, "onClick", func)
end

function onClickIncrementMinStep(player, click, id)
	addCount(STEPS.STEP,click == "-1")
end

function onClickIncrementMajStep(player, click, id)
	addCount(STEPS.LARGE_STEP,click == "-1")
end

function onClickDecrementMinStep(player, click, id)
	addCount(-STEPS.STEP,click == "-1")
end

function onClickDecrementMajStep(player, click, id)
	addCount(-STEPS.LARGE_STEP,click == "-1")
end

function addCount(val,leftClick)
	if leftClick==false then val = 2*val end
	CURRENT_COUNT = CURRENT_COUNT + val
	 if CURRENT_COUNT < 0 and not ALLOW_NEGATIVE then
        CURRENT_COUNT = 0
    end
	setCounterValue()
end

function setCounterValue(val)
	local val = val or CURRENT_COUNT
    self.UI.setAttribute("counterText", "text", val)
    HACK_reassignColor("counterText")
end

-- Button Text Color Hack
-- There's currently a bug with XML UI, causing button text color to reset to black when the value is changed via script. Reassign color to fix this.
function HACK_reassignColor(id)
    if CURRENT_COUNT < 0 then 
    	self.UI.setAttribute(id, "textColor", "Red")
    else
    	self.UI.setAttribute(id, "textColor", "White")
    end
end