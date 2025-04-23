; Description:
;	Move extruders out of the way to allow for easy part removal
;	Z will not be moved if the part is in the way.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/axes/part_removal_position.g"
M118 S{"[part_removal_position.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions-----------------------------------------------------------------
var X_SAFE_POS = move.axes[0].min
var Y_SAFE_POS = move.axes[1].max
var XY_SPEED = 10000
var Z_SPEED = 1000
var Z_POS = 5	;[mm]

; move XY first
G1 X{var.X_SAFE_POS} Y{var.Y_SAFE_POS} F{var.XY_SPEED} H4
M400

; check if we can move in Z
if (!exists(global.jobBBOX) || global.jobBBOX == null || #global.jobBBOX != 6)
	M98 P"/macros/report/warning.g" Y"Cannot determine part position. Not moving down" F{var.CURRENT_FILE} W51501
	M118 S{"[part_removal_position.g] Done "^var.CURRENT_FILE}
	M99
M400

; checking if  te part is outside the collision zone
var PATH_CLEAR_IN_X = global.jobBBOX[0] > 50
var PATH_CLEAR_IN_Y = global.jobBBOX[4] < (move.axes[1].max - 80)
var SAFE_TO_MOVE_Z = var.PATH_CLEAR_IN_X || var.PATH_CLEAR_IN_Y

if(var.SAFE_TO_MOVE_Z && move.axes[2].homed)
	G1 Z{var.Z_POS} F{var.Z_SPEED}
else
	M98 P"/macros/report/warning.g" Y"Part in the way. Not moving down" F{var.CURRENT_FILE} W51502
M400
; -----------------------------------------------------------------------------
M118 S{"[part_removal_position.g] Done "^var.CURRENT_FILE}
M99