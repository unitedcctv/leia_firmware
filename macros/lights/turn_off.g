; Description: 		
;	We will turn off the lights in the machine
; Example:
;	M98 P"/macros/lights/turn_off.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/lights/turn_off.g"
M118 S{"[LIGHTS] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/lights/set.g"} F{var.CURRENT_FILE} E61100
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_LIGHTS)} Y{"Missing required module LIGHTS"} F{var.CURRENT_FILE} E61101

; Controlling the lights ------------------------------------------------------
M98 P"/macros/lights/set.g" L0
M118 S{"[LIGHTS] Lights are off"}

; -----------------------------------------------------------------------------
M118 S{"[LIGHTS] Done "^var.CURRENT_FILE}
M99 ; Proper exit