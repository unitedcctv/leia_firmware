; Description: 	
; 	We will emulate the homing of Y axis to min.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/axes/emulator/v0/homing/y.g"
M118 S{"[HOMING] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_AXES)}  Y{"Missing AXES configuration"} F{var.CURRENT_FILE}  			E10320
M98 P"/macros/assert/abort_if.g" R{!exists(move.axes[1].min)}  	 Y{"Missing Y axis proper configuration"} F{var.CURRENT_FILE}  	E10321

; Definition ------------------------------------------------------------------
var MAX_TIME_HOMING_MS  = 5000 	; [msec] Max. time required to home this axis
var Z_LIFT_SPEED		= 6000		; [mm/min] Speed used when lifting Z
var Z_LIFT				= { (move.axes[2].min >= 0) ? 10 : (5 - move.axes[2].min)}		; [mm] Distance to move in Z before starting

; Lift Z ----------------------------------------------------------------------
G91			  	; relative positioning
G1 H1 Z{var.Z_LIFT} F{var.Z_LIFT_SPEED}  	; lift Z relative to current position
G90			  	; absolute positioning

; Wait while the top is reached -----------------------------------------------
var WAITING_TIME = (random(var.MAX_TIME_HOMING_MS)+1)/1000
G4 S{var.WAITING_TIME}
M400

; Set the max position as homing position -------------------------------------
G92 Y{move.axes[1].min}
M400

; -----------------------------------------------------------------------------
M118 S{"[HOMING] Done "^var.CURRENT_FILE}
M99 ; Proper exit