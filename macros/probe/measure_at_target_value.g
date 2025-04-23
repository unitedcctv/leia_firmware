; Description: 	
;   We will move to a target position withing a tolerance.
; Input parameters:
;	- X : [mm] Position in X where the measurement will be performed
;	- Y : [mm] Position in Y where the measurement will be performed
;   - Z : [mm] Start point in Z
;	- B	: [mm] Move down in Z to compensate backlash (Default: 0mm)
; 	- V : [mm] Target value (Default: 0mm)
;	- E : [mm] Tolerance to the target value (Default: 0.25mm)
;	- T	: [sec] Sample time (Default: 0.3sec)
; 	- S : [mm/min] Move speed (default will be 20000 mm/min)
;	- D	: [] Max. moves to reach the target tolerance (Default: 3)
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/probe/measure_at_target_value.g"
var DBG_LEVEL		= 0	; 0: off | 1: Warning | 2: Info | 3: Debug
M118 L{var.DBG_LEVEL} S{"[PROBE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/probe/get_sample_single_z.g"} 			F{var.CURRENT_FILE} E65200
; Checking global variables
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.X)}  	Y{"Missing input parameter X"}  F{var.CURRENT_FILE} E65201
M98 P"/macros/assert/abort_if_null.g" 	R{param.X} 				Y{"Input parameter X is null"} 	F{var.CURRENT_FILE} E65202
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.Y)}  	Y{"Missing input parameter Y"}  F{var.CURRENT_FILE} E65203
M98 P"/macros/assert/abort_if_null.g" 	R{param.Y} 				Y{"Input parameter Y is null"} 	F{var.CURRENT_FILE} E65204
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.Z)}  	Y{"Missing input parameter Z"}  F{var.CURRENT_FILE} E65205
M98 P"/macros/assert/abort_if_null.g" 	R{param.Z} 				Y{"Input parameter Z is null"} 	F{var.CURRENT_FILE} E65206

; Definitions -----------------------------------------------------------------
var DEFAULT_MOVE_DOWN_BACKLASH	= 0						; [mm] Move down to compensate the backlash
var DEFAULT_TARGET_VALUE		= 0						; [mm] Target value by default
var DEFAULT_TARGET_TOLERANCE	= 0.25					; [mm] Tolerance to target value by default
var DEFAULT_DELAY_SAMPLING		= 0.26					; [sec] Sample time
var DEFAULT_MOVE_SPEED 			= 20000					; [mm/min] Speed to move between steps
var DEFAULT_MAX_MOVES			= 3						; [] Max. moves to reach the target tolerance
; Getting input parameters ----------------------------------------------------
var MOVE_DOWN_BACKLASH 	= { (exists(param.B) && param.B != null) ? param.B : var.DEFAULT_MOVE_DOWN_BACKLASH}
var TARGET_VALUE 		= { (exists(param.V) && param.V != null) ? param.V : var.DEFAULT_TARGET_VALUE}
var TARGET_TOLERANCE 	= { (exists(param.E) && param.E != null) ? param.E : var.DEFAULT_TARGET_TOLERANCE}
var DELAY_SAMPLING 		= { (exists(param.T) && param.T != null) ? param.T : var.DEFAULT_DELAY_SAMPLING}
var MOVE_SPEED 			= { (exists(param.S) && param.S != null) ? param.S : var.DEFAULT_MOVE_SPEED}
var MAX_MOVES 			= { (exists(param.D) && param.D != null) ? param.D : var.DEFAULT_MAX_MOVES}

; Perform sampling ------------------------------------------------------------
G90 ; Back to absolute positioning
M118 L{var.DBG_LEVEL} S{"[PROBE] Measuring point X"^param.X^" Y"^param.Y^" from Z"^param.Z}

G1 X{param.X} Y{param.Y} Z{param.Z+var.MOVE_DOWN_BACKLASH} F{var.MOVE_SPEED}
M400
G1 Z{param.Z} F{var.MOVE_SPEED} ; Backlash compensation
M400

; Preparing the return value of get_sample_single_z.g
if(!exists(global.probeMeasuredValue))
	global probeMeasuredValue = null
; Start loop until the target value is withing tolerance.
var moveCounter = var.MAX_MOVES
while (var.moveCounter >= 0)
	; Sampling
	M598
	M98 P"/macros/probe/get_sample_single_z.g" T{var.DELAY_SAMPLING}
	M598
	M98 P"/macros/assert/abort_if_null.g" 	R{global.probeMeasuredValue} 	Y{"Global variable probeMeasuredValue is null"} 	F{var.CURRENT_FILE} E65220

	if(abs( (global.probeMeasuredValue) - var.TARGET_VALUE ) < var.TARGET_TOLERANCE )
		break ; We are done!
	set var.moveCounter = var.moveCounter - 1
	; Let's try to reach the target with an extra move
	if(var.moveCounter >= 0)
		if(global.probeMeasuredValue < 0 )
			if(var.moveCounter == (var.MAX_MOVES - 1))
				; It is the first move and we need to move up. Something is not ok!
				M98 P"/macros/report/warning.g" Y{"The probe start point is too low"} F{var.CURRENT_FILE} W65220
			else
				M98 P"/macros/report/warning.g" Y{"The probe needs to compensate in the wrong way"} F{var.CURRENT_FILE} W65221
				G1 Z{move.axes[2].userPosition-global.probeMeasuredValue+var.MOVE_DOWN_BACKLASH} F{var.MOVE_SPEED}
				M400
		G1 Z{move.axes[2].userPosition-global.probeMeasuredValue} F{var.MOVE_SPEED}
		M400
; M118 S{"[PROBE] Stoped in X"^move.axes[0].userPosition^" Y"^move.axes[1].userPosition^" at Z"^move.axes[2].userPosition^" with an error of "^global.probeMeasuredValue^"mm after moving "^(var.MAX_MOVES - var.moveCounter)^" time(s)"}

; Obtain the distance measured to the target position (PROBE_VALUE_AT_Z).
var DEFAULT_OFFSET_IN_Z = (move.axes[2].userPosition - global.PROBE_OFFSET_Z)
set global.probeMeasuredValue = var.DEFAULT_OFFSET_IN_Z - global.probeMeasuredValue
; M118 S{"[PROBE] Measured: "^global.probeMeasuredValue^"mm"}

; -----------------------------------------------------------------------------
M118 L{var.DBG_LEVEL} S{"[PROBE] Done "^var.CURRENT_FILE}
M99 ; Proper exit