; Description: 	
;	Wait until the input voltages of the boards (x-board and expansion-boards)
;	reach a valid values.
;	(!) To check the valid ranges, see /macros/sensors/voltages/check_all.g
; Input parameters:
;	T: [sec] Time waiting. By default it is 60 sec.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/sensors/voltages/wait.g"
M118 S{"[SENSORS] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/sensors/voltages/check_all.g"} F{var.CURRENT_FILE} E67000

; Definitions -----------------------------------------------------------------
var DEF_MAX_TIME_WAITING = 60 	; [sec] Default maximum time waiting until the 
						  		; voltages are ok before aborting.

; Input parameters
var USE_DEF_TIME = (!exists(param.T) || (exists(param.T) && param.T != null) )
var MAX_TIME_WAITING = { var.USE_DEF_TIME ? var.DEF_MAX_TIME_WAITING : param.T }
; Implementation --------------------------------------------------------------
if(!exists(global.resultTestVoltages))
	global resultTestVoltages = 2
	G4 S0.1
else 
	set global.resultTestVoltages = 2
M400
M98 P"/macros/sensors/voltages/check_all.g" S1 ; Check the voltages

if(global.resultTestVoltages!=0)
	M98 P"/macros/report/warning.g" Y{"The voltage values in the boards are not valid."} F{var.CURRENT_FILE} W67020
	var TIMEOUT = {state.time + var.MAX_TIME_WAITING}
	while(global.resultTestVoltages != 0)
		G4 S1 ; going to sleep for 30 sec before running the test again.
		M98 P"/macros/assert/abort_if.g" R{(state.time > var.TIMEOUT)} Y{"Timeout waiting the voltages to be fixed"}  F{var.CURRENT_FILE} E67020
		M98 P"/macros/sensors/voltages/check_all.g" S1 ; Check the voltages
	M118 S{"[SENSORS] Problem with voltages is solved!"}

; -----------------------------------------------------------------------------
M118 S{"[SENSORS] Done "^var.CURRENT_FILE}
M99