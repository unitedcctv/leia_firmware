; Description: 	
;		The machine will be moved to a safe position.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/generic/turn_off_everything.g"
M118 S{"[turn_off_everything.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/cbc/turn_off.g"} F{var.CURRENT_FILE} E59000

; Definitions -----------------------------------------------------------------
var TURN_OFF_TEMP = -273.1
var MIN_TEMP = 0 	; [dC] Value to use when the tool is off
; Turning off the bed ---------------------------------------------------------
M140 S{var.TURN_OFF_TEMP}
M118 S{"[turn_off_everything.g] Turned off bed"}

; Turn off the Tool heaters ---------------------------------------------------
while (iterations < #tools)
	if exists(tools[iterations].extruders)
		M568 P{iterations} S{var.TURN_OFF_TEMP} R{var.TURN_OFF_TEMP} A0 ;Setting extruder temp to off temp
		M118 S{"[turn_off_everything.g] Turned off T"^ iterations ^ " heater"}

; checking if the tool fans are ON and then turn it off
if(exists(global.toolFanId))
	if((global.toolFanId[0]!= null) && (fans[global.toolFanId[0]].actualValue > 0))
		M106 P{global.toolFanId[0]} S0
		M118 S{"[turn_off_everything.g] Turned off T0 fan"}

; Deselect the extruder -------------------------------------------------------
if(state.currentTool >= 0)
	T-1
; Turn off the CBC ------------------------------------------------------------
M98 P"/macros/cbc/turn_off.g"

; Turn off the motors ---------------------------------------------------------
M18
M118 S{"[turn_off_everything.g] Turned off motors"}

; -----------------------------------------------------------------------------
M118 S{"[turn_off_everything.g] Done "^var.CURRENT_FILE}
M99	; Proper exit