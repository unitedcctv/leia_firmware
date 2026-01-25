;---------------------------------------------------------------------------------------------
;	The door is controlled with an H-Bridge that will set the position of a solenoid.
; 	This file is in charge of locking or unlocking the door with its input parameter:
;		- D	: Set the status of the door to lock or unlock:
;			+ 0: The door is unlocked
;			+ 1: The door is locked
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/doors/set_solenoid.g"

M118 S{"[set_solenoid.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
if (!exists(global.MODULE_DOORS))
	M118 S{"[set_solenoid.g] Missing DOORS configuration"}
	abort

if (!exists(global.DOORS_CTRL_A) || !exists(global.DOORS_CTRL_B))
	M118 S{"[set_solenoid.g] Missing global DOORS_CTRL_A or DOORS_CTRL_B"}
	abort

if (!exists(global.doorIsLocked))
	M118 S{"[set_solenoid.g] Missing global doorIsLocked"}
	abort

if (!exists(param.D))
	M118 S{"[set_solenoid.g] Missing parameter D"}
	abort

if (param.D == null || param.D < 0 || param.D > 1)
	M118 S{"[set_solenoid.g] Invalid Parameter D="^param.D}
	abort

; Definitions
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

M118 S{"[set_solenoid.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit