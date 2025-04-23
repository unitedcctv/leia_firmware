
; Description:
;	Applies saved flow rates to all extruders of all tools
;   If this macro is run in the tool initialization phase, it will load the flow rates from persistent variables
;	If nothing has been saved, it will apply 100% to all extruders
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/flow_rate/load.g"
M118 S{"[load.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Only load from persistent variables if this is the tool initialization phase (no global var exists)
if(!exists(global.flowRateMultipliers))
	global flowRateMultipliers = {100,100}
	M98 P"/macros/variable/load.g" N"global.flowRateMultipliers"
	M400
	; Checking the saved values
	if(global.savedValue != null && #global.savedValue < 2)
		set global.flowRateMultipliers = global.savedValue
	else
		M118 S{"[load.g] No global.flowRateMultipliers persistent variable found or invalid format, using defaults"}
M400

; Iterate through all tools and apply the saved flow rates to each extruder per tool
while iterations < #tools
	var tool = iterations
	if exists(tools[var.tool].extruders)
		var flow = global.flowRateMultipliers[var.tool]
		M118 S{"[load.g] Applying flow " ^ var.flow ^ " to T" ^ var.tool}
		while iterations < #tools[var.tool].extruders
			M221 D{tools[var.tool].extruders[iterations]} S{var.flow}
		M400
	M400
M400
;--------------------------------------------------------------------------------------------------------
M118 S{"[load.g] Done "^var.CURRENT_FILE}
M99