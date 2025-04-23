; Description:
;
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/emergency/emulator/v0/config.g"
M118 S{"[EMERG] Start "^var.CURRENT_FILE}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_EMERGENCY)}  Y{"Missing EMERGENCY configuration"} F{var.CURRENT_FILE} E12160
M98 P"/macros/assert/abort_if.g" R{!exists(global.EMERGENCY_INPUTS)}  Y{"Missing global EMERGENCY_INPUTS"} F{var.CURRENT_FILE} E12161

var idx = 0
var currentState = 0
while (var.idx < #global.EMERGENCY_INPUTS)
	; if (sensors.gpIn[global.EMERGENCY_INPUTS[var.idx]].value == 0)
	;	M118 S{"[ERROR] Emergency signal in not triggered in input "^ global.EMERGENCY_INPUTS[var.idx]}
	;	M99
	set var.currentState = var.currentState + sensors.gpIn[global.EMERGENCY_INPUTS[var.idx]].value
	set var.idx = var.idx + 1

; (!) NOTE: For the emulator, we consider the emergency to be active high.
set var.currentState = var.currentState / #global.EMERGENCY_INPUTS
if( var.currentState > 0.5 )
	set global.emergencyDoorIsTriggered = true
else 
	set global.emergencyDoorIsTriggered = false

M118 S{"[EMERG] Triggered: " ^ global.emergencyDoorIsTriggered }

if(global.emergencyDoorIsTriggered)
	if( move.axes[2].homed )
		if(!exists(global.lastZPosition))
			global lastZPosition = move.axes[2].machinePosition
		else
			set global.lastZPosition = move.axes[2].machinePosition
		M118 S{"[EMERG] Saving Z Position"}
	elif (exists(global.lastZPosition))
		set global.lastZPosition = null
	M18 X Y Z ; Turn off the motors
	M118 S{"[EMERG] XYZ Motors Disabled"}
elif( exists(global.lastZPosition) && global.lastZPosition != null )
	if( state.status == "paused" )
		; M98 P"/macros/pop_up/ok_abort.g" W"The door was closed. Can we home X and Y?" H"Home X Y" T30
		M118 S{"[EMERG] Recovering Z Position: "^global.lastZPosition}
		M17 Z ; Enable Z motors
		M400
		G92 Z{global.lastZPosition}
		M400
		; if(global.popUpResult != null && global.popUpResult == "OK" )
		;	M98 P"homexy.g"
M99 