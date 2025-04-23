; Description: 	
;   We will home U to Umax.
; TODO:
;	- Review G92 at the end of the file, and remove it if it is not needed.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/homeu.g"
M118 S{"[homeu.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking modules and global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_STAGE)} Y{"Missing module STAGE"} 	F{var.CURRENT_FILE} E36300

; Definitions -----------------------------------------------------------------
; Distances
var TOLERANCE	= 2						; [mm] Max. tolerance to trigger the
										; endstop out of the defined distances.
var MOVE_LENGTH_U = {move.axes[3].max + var.TOLERANCE} ; [mm] Move up in U until
										; we touch the endstop.
var RETRACTION_LENGTH = 5				; [mm] Distance to separate from the 
										; endstop once we touch it.

; Speeds
var SPEED_FAST_MOVE		= 5000			; [mm/min]	Speed used for fast moves
var SPEED_SLOW_MOVE		= 150			; [mm/min]	Speed used for slow moves

; Process ---------------------------------------------------------------------
var errorMoving = false					; Used to record the result of a move.

; Move up until we touch the sensor
G91 									; Relative positioning
G1 H1 	U{var.MOVE_LENGTH_U} F{var.SPEED_FAST_MOVE}	; Moving up
set var.errorMoving = (result > 0)
M400
G90 							; Absolute position
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move T0 Lifter up into the endstops"} F{var.CURRENT_FILE} 			E36301
M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[3].triggered} Y{"Unable to trigger the T0 Lifter endstop"} F{var.CURRENT_FILE} E36302

; Separate from the endstop
G91 									; Relative positioning
G1  U{-var.RETRACTION_LENGTH} F{var.SPEED_FAST_MOVE}		; Move down
set var.errorMoving = (result > 0)
M400
G90 							; Absolute position
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move in T0 Lifter apart from the endstops"} F{var.CURRENT_FILE}  E36304
M98 P"/macros/assert/abort_if.g" R{sensors.endstops[3].triggered} Y{"The T0 Lifter endstop is still triggered"} F{var.CURRENT_FILE} E36305

; Move up again to touch the endstop.
G91
G1 H1 U{var.RETRACTION_LENGTH+var.TOLERANCE} F{var.SPEED_SLOW_MOVE}
set var.errorMoving = (result > 0)
M400
G90
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move T0 Lifter into the endstops after retraction"} F{var.CURRENT_FILE} 			 E36307
M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[3].triggered} Y{"Unable to trigger the T0 Lifter endstop after retraction"} F{var.CURRENT_FILE} E36308

; We are in the home position
G92 U{move.axes[3].max} W{move.axes[4].max}
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the home position for T0 Lifter" F{var.CURRENT_FILE} E36310
T-1
M400
M98 P"/macros/report/event.g" Y"Home T0 Lifter completed" F{var.CURRENT_FILE} V36300
; -----------------------------------------------------------------------------
M118 S{"[homeu.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit