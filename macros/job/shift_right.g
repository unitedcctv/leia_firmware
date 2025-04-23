; Description: 	
;	This macro shift the print to the Xmax position
; ----------------------------------------------------------------------------
var CURRENT_FILE = "/macros/job/shift_right.g"
M118 S{"[shift_right.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

if(!exists(global.printingLimitsX) || (#global.printingLimitsX != 2))
	M118 S{"global.printingLimitsX variable doesnt exist or wrong length"}
	abort

; Definitions----------------------------------------------------------------
var X_OFFSET = 100
; Creating a global variable for activating the autoplacement
if(!exists(global.autoPlacementActive))
	global autoPlacementActive = true 
else
	set global.autoPlacementActive = true

; creating the offset to move the print to the Xmax
var OFFSET_FAR_RIGHT_X = (global.printingLimitsX[1] - global.jobBBOX[3] )
var SHIFTED_X = {(global.jobBBOX[0] + var.OFFSET_FAR_RIGHT_X) , (global.jobBBOX[3] + var.OFFSET_FAR_RIGHT_X)}
var isInsideXmin = (global.printingLimitsX[0] <= var.SHIFTED_X[0])
; Checking whether can shift by offsets, if yes shift
if((var.OFFSET_FAR_RIGHT_X != 0) && (var.isInsideXmin))
	G10 L2 P2 X{var.OFFSET_FAR_RIGHT_X} Y0  ; Offset 
	M400
	G55                    ; Activate the G55 coordinate system
	M400
else
	M98 P"/macros/report/event.g" Y{"Print already on the max position or jobbox out of bound"} F{var.CURRENT_FILE} V88200
	M118 S{"[shift_right.g] Done "^var.CURRENT_FILE}
	M99	

set global.jobBBOX[0] = var.SHIFTED_X[0]
set global.jobBBOX[3] = var.SHIFTED_X[1]

M98 P"/macros/report/event.g" Y{"Print shifted to the far right in X "} F{var.CURRENT_FILE} V88201
; -------------------------------------------------------------------------------
M118 S{"[shift_right.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit
