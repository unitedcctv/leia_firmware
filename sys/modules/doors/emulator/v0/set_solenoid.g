; Description: 	
;	The door is controlled with an H-Bridge that will set the position of a solenoid.
; 	This file is in charge of locking or unlocking the door with its input parameter:
; Input parameters:
;	- D	: Set the status of the door to lock or unlock:
;		+ 0: The door is unlocked
;		+ 1: The door is locked
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/doors/emulator/v0/set_solenoid.g"

M118 S{"[DOORS] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_DOORS)}  Y{"Missing DOORS configuration"} F{var.CURRENT_FILE} E11660
M98 P"/macros/assert/abort_if.g" R{!exists(global.DOORS_CTRL_A)}  Y{"Missing global DOORS_CTRL_A"} F{var.CURRENT_FILE} E11661
M98 P"/macros/assert/abort_if.g" R{!exists(global.DOORS_CTRL_B)}  Y{"Missing global DOORS_CTRL_B"} F{var.CURRENT_FILE} E11662
M98 P"/macros/assert/abort_if.g" R{!exists(global.doorIsLocked)}  Y{"Missing global doorIsLocked"} F{var.CURRENT_FILE} E11663
M98 P"/macros/assert/abort_if.g" R{!exists(param.D)}  Y{"Missing parameter D"} F{var.CURRENT_FILE} E11664
M98 P"/macros/assert/abort_if_null.g" R{param.D}  Y{"Input parameter D is null"} F{var.CURRENT_FILE} E11665

var TIME_HOLDING_OUTPUT = 0.5 ; [sec] Time powering the solenoid.

; Making sure the door both output are disabled to avoid shortcuts
M42 P{global.DOORS_CTRL_A} S0
M42 P{global.DOORS_CTRL_B} S0
G4 S{var.TIME_HOLDING_OUTPUT}

if(param.D > 0)	; The solenoid is locking the door.
	M42 P{global.DOORS_CTRL_A} S1
	set global.doorIsLocked = true
else ; The solenoid is not locking the door.
	M42 P{global.DOORS_CTRL_B} S1
	set global.doorIsLocked = false
	
; Hold the output
G4 S{var.TIME_HOLDING_OUTPUT}

; Turning off the outputs again
M42 P{global.DOORS_CTRL_A} S0
M42 P{global.DOORS_CTRL_B} S0

M118 S"[DOORS] Done setting the status of the door with set_solenoid.g"
M118 S{"[DOORS] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
M99 ; Proper exit