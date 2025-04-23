
; Description: 	
;	This macro checks the prerequisite conditions in shifting the print part
;    on the print bed based on the entered offsets on (X,Y) directions
; 		and shift the print to the entered offset values
; Input parameter : S {Xoffset, Yoffset}
; ----------------------------------------------------------------------------
var CURRENT_FILE = "/macros/job/shift_print.g"
M118 S{"[shift_print.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

if(!exists(param.S))
	M118 S{"Input parameter S doesnt exists"}
	abort
if(!exists(global.printingLimitsX) || (#global.printingLimitsX != 2))
	M118 S{"global.printingLimitsX variable doesnt exist or wrong length"}
	abort
if(!exists(global.printingLimitsY) || (#global.printingLimitsY != 2))
	M118 S{"global.printingLimitsY variable doesnt exist or wrong length"}
	abort

; Definitions----------------------------------------------------------------

; shifted job box in X and Y
var SHIFT_JOB_DIM_X = {(global.jobBBOX[0] + param.S[0]), (global.jobBBOX[3] + param.S[0])}
var SHIFT_JOB_DIM_Y = {(global.jobBBOX[1] + param.S[1]), (global.jobBBOX[4] + param.S[1])}

; Checking the specified offset is applicable in the printable X axis area
var isInsideXmin = (global.printingLimitsX[0] <= var.SHIFT_JOB_DIM_X[0])
var isInsideXmax = (global.printingLimitsX[1] >= var.SHIFT_JOB_DIM_X[1])

; Checking the specified offset is applicable in the printable Y axis area
var isInsideYmin =  (global.printingLimitsY[0] <= var.SHIFT_JOB_DIM_Y[0]) 
var isInsideYmax = (global.printingLimitsY[1] >= var.SHIFT_JOB_DIM_Y[1])

; condition for valid offset
var offsetValid = var.isInsideXmin && var.isInsideXmax && var.isInsideYmin && var.isInsideYmax

; Checking whether can shift by offsets, if yes shift
if(var.offsetValid)
	G10 L2 P2 X{param.S[0]} Y{param.S[1]}   ; Offset 
	M400
	G55                    ; Activate the G55 coordinate system
	M400
else
	M98 P"/macros/assert/abort.g" Y{"Invalid Offset: specified offset is outside the printable area "} F{var.CURRENT_FILE} E88210
	M99

set global.jobBBOX[0] = var.SHIFT_JOB_DIM_X[0]
set global.jobBBOX[3] = var.SHIFT_JOB_DIM_X[1]
set global.jobBBOX[1] = var.SHIFT_JOB_DIM_Y[0]
set global.jobBBOX[4] = var.SHIFT_JOB_DIM_Y[1]

M98 P"/macros/report/event.g" Y{"Print shifted by {X, Y, Z} to %s"} A{global.jobBBOX,} F{var.CURRENT_FILE} V88210
; -------------------------------------------------------------------------------
M118 S{"[shift_print.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit
