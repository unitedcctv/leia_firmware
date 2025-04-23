; Description: 	
; 	We will emulate the homing of X axis to min.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/axes/emulator/v0/homing/x.g"
M118 S{"[HOMING] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_AXES)}  Y{"Missing AXES configuration"} F{var.CURRENT_FILE}  			E10300
M98 P"/macros/assert/abort_if.g" R{!exists(move.axes[0].min)}  	 Y{"Missing X axis proper configuration"} F{var.CURRENT_FILE}  	E10301

; Definition ------------------------------------------------------------------
var MAX_TIME_HOMING_MS  = 7000 		; [msec] Max. time required to home this axis
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
G92 X{move.axes[0].min}
M400

; -----------------------------------------------------------------------------
M118 S{"[HOMING] Done "^var.CURRENT_FILE}
M99 ; Proper exit