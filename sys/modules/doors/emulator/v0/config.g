; Description: 	
;	The door is controlled with an H-Bridge that will set the position of a solenoid.
; 	As there is no input, the current status of the door solenoid will be stored in 
;	doorIsLocked, but this value doesn't means that the door is actually closed.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/doors/emulator/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_DOORS)}  Y{"A previous DOORS configuration exists"} F{var.CURRENT_FILE} E11640

; DEFINITIONS --------------------------------------------------------------------------------
var DOORS_OUTPUT_A = "0.out5"
var DOORS_OUTPUT_B = "0.io6.out"

M98 P"/macros/get_id/output.g"
global DOORS_CTRL_A = global.outputId ; The door works with an H-Bridge, and this is the output A
M98 P"/macros/get_id/output.g"
global DOORS_CTRL_B = global.outputId ; The door works with an H-Bridge, and this is the output B

global doorIsLocked = false			; Global variable to save if the door is open or close

; CONFIGURATION ------------------------------------------------------------------------------
M950 P{global.DOORS_CTRL_A} C{var.DOORS_OUTPUT_A} Q200
M98 P"/macros/assert/result.g" R{result} Y"Unable to create output A for DOOR" F{var.CURRENT_FILE} E11641
M950 P{global.DOORS_CTRL_B} C{var.DOORS_OUTPUT_B} Q200
M98 P"/macros/assert/result.g" R{result} Y"Unable to create output B for DOOR" F{var.CURRENT_FILE} E11642

; Making sure they are off
M42 P{global.DOORS_CTRL_A} S0
M98 P"/macros/assert/result.g" R{result} Y"Unable to set output A of DOOR" F{var.CURRENT_FILE} E11643
M42 P{global.DOORS_CTRL_B} S0
M98 P"/macros/assert/result.g" R{result} Y"Unable to set output B of DOOR" F{var.CURRENT_FILE} E11644

; Links
M98 P"/macros/files/link/create.g" L"/macros/doors/control.g" D"/sys/modules/doors/emulator/v0/set_solenoid.g"

global MODULE_DOORS = 0.1	; Setting the current version of this module

M98 P"/macros/doors/unlock.g" 	; Unlock doors

M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Exit current file