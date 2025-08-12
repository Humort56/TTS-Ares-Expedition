function onload(saved_data)
    if saved_data ~= "" then
	  VAL= saved_data ~= "" and saved_data or 0
    end
    self.createButton({
		label=VAL,
		click_function="add",
		tooltip="Forest VP",
		function_owner=self,
		position={0,0.15,-0.25},
		height=200,
		width=300,
		scale={x=2, y=2, z=2},
		font_size=300,
		font_color={0.4,0.7,0.2,95},
		color={0,0,0,0}
	})
end

function add(obj, pcolor, alt)
    local mod = alt and -1 or 1
    local newVal = math.max(VAL + mod, 0)
    if VAL ~= newVal then
	  VAL = newVal
	  self.editButton({  index = 0, label = VAL })
	  self.script_state = VAL
    end
end

function get(obj)
	return VAL
end