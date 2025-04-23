; Description: 	
;   We will home U and W together to Umax and Wmax.
; TODO:
;	- Review G92 at the end of the file, and remove it if it is not needed.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/homeuw.g"
M118 S{"[homeuw.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking modules and global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_STAGE)} Y{"Missing module STAGE"} 	F{var.CURRENT_FILE} E35400

; Definitions -----------------------------------------------------------------
; Distances
var TOLERANCE	= 2						; [mm] Max. tolerance to trigger the
										; endstop out of the defined distances.
var MOVE_LENGTH_U = {move.axes[3].max + var.TOLERANCE} ; [mm] Move up in U until
										; we touch the endstop.
var MOVE_LENGTH_W = {move.axes[4].max + var.TOLERANCE} ; [mm] Move up in W until
										; we touch the endstop.
var RETRACTION_LENGTH = 5				; [mm] Distance to separate from the 
										; endstop once we touch it.

; Speeds
var SPEED_FAST_MOVE		= 5000			; [mm/min]	Speed used for fast moves
var SPEED_SLOW_MOVE		= 150			; [mm/min]	Speed used for slow moves

; Process ---------------------------------------------------------------------
var errorMoving = false					; Used to record the result of a move.

if(!exists(move.axes[4]))
	M98 P"/sys/homeu.g"
	M99 ; Proper exit
else
	; Move up until we touch the sensor
	G91 									; Relative positioning
	G1 H1 	U{var.MOVE_LENGTH_U} W{var.MOVE_LENGTH_W}	F{var.SPEED_FAST_MOVE}	; Moving up
	set var.errorMoving = (result > 0)
	M400
	G90 							; Absolute position
	M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move Tool Lifters up into the endstops"} F{var.CURRENT_FILE} 			E35401
	M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[3].triggered} Y{"Unable to trigger the T0 Lifter endstop"} F{var.CURRENT_FILE} E35402
	M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[4].triggered} Y{"Unable to trigger the T1 Lifter endstop"} F{var.CURRENT_FILE} E35403

	; Separate from the endstop
	G91 									; Relative positioning
	G1  U{-var.RETRACTION_LENGTH} W{-var.RETRACTION_LENGTH}	F{var.SPEED_FAST_MOVE}		; Move down
	set var.errorMoving = (result > 0)
	M400
	G90 							; Absolute position
	M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move in Tool Lifters down from the endstops"} F{var.CURRENT_FILE}  E35404
	M98 P"/macros/assert/abort_if.g" R{sensors.endstops[3].triggered} Y{"The T0 Lifter endstop is still triggered"} F{var.CURRENT_FILE} E35405
	M98 P"/macros/assert/abort_if.g" R{sensors.endstops[4].triggered} Y{"The T1 Lifter endstop is still triggered"} F{var.CURRENT_FILE} E35406

	; Move up again to touch the endstop.
	G91
	G1 H1 U{var.RETRACTION_LENGTH+var.TOLERANCE} W{var.RETRACTION_LENGTH+var.TOLERANCE}	F{var.SPEED_SLOW_MOVE}
	set var.errorMoving = (result > 0)
	M400
	G90
	M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move Tool Lifters into the endstops after retraction"} F{var.CURRENT_FILE} 			 E35407
	M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[3].triggered} Y{"Unable to trigger the T0 Lifter endstop after retraction"} F{var.CURRENT_FILE} E35408
	M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[4].triggered} Y{"Unable to trigger the T1 Lifter endstop after retraction"} F{var.CURRENT_FILE} E35409

	; We are in the home position
	G92 U{move.axes[3].max} W{move.axes[4].max}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the home position for Tool Lifters" F{var.CURRENT_FILE} E35410

T-1
M400
M98 P"/macros/report/event.g" Y"Home Tool Lifters completed" F{var.CURRENT_FILE} V35400
; -----------------------------------------------------------------------------
M118 S{"[homeuw.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit