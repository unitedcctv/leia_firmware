; Description: 	
;	Pre selection tool script.
;	To be called from tpre0.g or tpre1.g when using generic extruders.
;   We cannot abort in tool change macros as per doc https://docs.duet3d.com/en/User_manual/Tuning/Tool_changing
; Ïnput Parameters:
;	- T: Tool number (0 or 1) to execute the post selection.
; Example:
;	M98 P"/macros/extruder/tpre.g" T0
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/tpre.g"
M118 S{"[tpre.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------

if !exists(param.T)
	M118 S{"[tpre.g] param.T does not exist"}
	M99
M400
if param.T == null || param.T >= 2 || param.T < 0
	M118 S{"[tpre.g] Unexpected value: param.T = " ^ param.T}
	M99
M400

set global.toolPositioningFailed[param.T] = false

; Definitions -----------------------------------------------------------------
var TOOL_LIFT_AXIS = 3 + param.T
var POSITIONING_TOLERANCE = 0.1
; is it safe to move?
var moveSafe = false
var PRINTING = (state.thisInput = 2) && exists(global.homingDone) && global.homingDone

if var.PRINTING
	if !exists(global.lastPrintingTool) ; might not exist if we're resuming from power outage
		global lastPrintingTool = param.T
	else
		set global.lastPrintingTool = param.T

if (!move.axes[2].homed)
	M118 S{"[tpre.g] Z not homed. Extruder will not be moved"}
else
	if (move.axes[2].machinePosition < 0)
		M118 S{"[tpre.g] Z position < 0. Extruder will not be moved"}
	else
		set var.moveSafe = true
M400

if(!exists(move.axes[var.TOOL_LIFT_AXIS].homed) || !move.axes[var.TOOL_LIFT_AXIS].homed)
	M118 S{"[tpre.g] Lifter not homed. Extruder will not be moved"}
	set var.moveSafe = false
M400

; if it is safe to move, move the extruder -------------------------------------
if (!var.moveSafe)
	M98 P"/macros/extruder/led_strip/set_mode.g" T{param.T} S"warning"
	M118 S{"[tpre.g] Done "^var.CURRENT_FILE}
	M99
M400

if param.T == 0
	G0 U{move.axes[var.TOOL_LIFT_AXIS].min} F5000
else
	G0 W{move.axes[var.TOOL_LIFT_AXIS].min} F5000
M400

; if we have linear stage sensor installed, we need to check whether the extruder moved to the correct position
while global.touchLinearInstalled[param.T] ; this is a loop, so that we can use "break" to get out of it
	; only do the check if we are in an actual print
	; (this is to avoid the check when running pre-print routines)
	if !var.PRINTING
		break

	G4 S1 ; wait for sensor to settle
	M400
	var SENSOR_ID = global.TOUCH_BED_SENSOR_IDS[param.T]
	var TARGET_POS = move.axes[var.TOOL_LIFT_AXIS].machinePosition
	var IN_SENSOR_RANGE = global.TOUCH_BED_VALID_RANGE[0] <= var.TARGET_POS && var.TARGET_POS <= global.TOUCH_BED_VALID_RANGE[1]
	if !var.IN_SENSOR_RANGE
		break

	var actualPos = sensors.analog[var.SENSOR_ID].lastReading
	var posDiff = var.actualPos - var.TARGET_POS
	M118 S{"[tpre.g] T"^param.T^" target diff: "^var.posDiff}
	if (abs(var.posDiff) > var.POSITIONING_TOLERANCE)
		M98 P"/macros/extruder/led_strip/set_mode.g" T{param.T} S"warning"
		M118 S{"[tpre.g] T"^param.T^" did not reach target position, retrying"}
		; try once more to move up and to target position
		if param.T == 0
			G1 U{move.axes[var.TOOL_LIFT_AXIS].max + 5} H1 F600
			G1 U{move.axes[var.TOOL_LIFT_AXIS].min} F600
		else
			G1 W{move.axes[var.TOOL_LIFT_AXIS].max + 5} H1 F600
			G1 W{move.axes[var.TOOL_LIFT_AXIS].min} F600
		M400
		G4 S2 ; wait for sensor to settle
		M400
		set var.actualPos = sensors.analog[var.SENSOR_ID].lastReading
		set var.posDiff = var.actualPos - var.TARGET_POS
		M118 S{"[tpre.g] T"^param.T^" target diff: "^var.posDiff}
		if (abs(var.posDiff) > var.POSITIONING_TOLERANCE)
			M118 S{"[tpre.g] T"^param.T^" could not be selected"}
			M98 P"/macros/extruder/led_strip/set_mode.g" T{param.T} S"error"
			set global.toolPositioningFailed[param.T] = true
			M118 S{"[tpre.g] Done "^var.CURRENT_FILE}
			M99
	break ; since this loop should run only once, we break out of it here
M400

M98 P"/macros/extruder/led_strip/set_mode.g" T{param.T} S"selected"
; -----------------------------------------------------------------------------
M118 S{"[tpre.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit