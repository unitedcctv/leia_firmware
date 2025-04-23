; Description: 	
; 	We will emulate the homing of U and W axes to max.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/stage/emulator/v0/homing/uw.g"
M118 S{"[STAGE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_STAGE)}  Y{"Missing STAGE configuration"} F{var.CURRENT_FILE}  		E16310
M98 P"/macros/assert/abort_if.g" R{!exists(move.axes[3].max)}  	 Y{"Missing T0 lifting axis proper configuration"} F{var.CURRENT_FILE}  	E16311
M98 P"/macros/assert/abort_if.g" R{!exists(move.axes[4].max)}  	 Y{"Missing T1 lifting axis proper configuration"} F{var.CURRENT_FILE}  	E16312

; Definition ------------------------------------------------------------------
var MAX_TIME_HOMING_MS = 2500 ; [msec] Max. time required to home this axis

; Wait while the top is reached -----------------------------------------------
var WAITING_TIME = (random(var.MAX_TIME_HOMING_MS)+1)/1000
G4 S{var.WAITING_TIME}
M400

; Set the max position as homing position -------------------------------------
G92 U{move.axes[3].max} W{move.axes[4].max}
M400

; -----------------------------------------------------------------------------
M118 S{"[HOMING] Done "^var.CURRENT_FILE}
M99 ; Proper exit