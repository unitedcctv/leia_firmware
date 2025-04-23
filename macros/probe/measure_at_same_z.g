; Description: 	
;	We will move to a position in X and Y and measure at the 
;	global.PROBE_OFFSET_Z position in Z with the probe
; Input parameters:
;	- X : [mm] Position in X where the measurement will be performed
;	- Y : [mm] Position in Y where the measurement will be performed
; 	- S : [mm/min] Move speed (default will be 20000 mm/min)
; Output paramters:
;	- global.probeMeasuredValue : [mm] Distance to the bed.
; -----------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/probe/measure_at_same_z.g"
; M118 S{"[PROBE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Set global return variables -------------------------------------------------
if(!exists(global.probeMeasuredValue))
	global probeMeasuredValue = null
else 
	set global.probeMeasuredValue = null

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/probe/get_sample_single_z.g"} 			F{var.CURRENT_FILE} E65100
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/probe/get_sample_multiple_z.g"} 		F{var.CURRENT_FILE} E65101
; Checking global variables
M98 P"/macros/assert/abort_if.g" 	  R{!exists(param.X)}  	Y{"Missing parameter X"}  			F{var.CURRENT_FILE} E65102
M98 P"/macros/assert/abort_if_null.g" R{param.X}  			Y{"Input parameter X is null"}  	F{var.CURRENT_FILE} E65103
M98 P"/macros/assert/abort_if.g" 	  R{!exists(param.Y)}  	Y{"Missing parameter Y"}  			F{var.CURRENT_FILE} E65104
M98 P"/macros/assert/abort_if_null.g" R{param.Y}  			Y{"Input parameter Y is null"}  	F{var.CURRENT_FILE} E65105

; Definitions -----------------------------------------------------------------
var DELAY_SAMPLING 		= 0.3							; [sec] Sleep before startGettingData.
var Z_AMOUNT_POINTS 	= 3								; Amount of positions to measure in the same XY point.
														; When it is higher than 1, multiple measurement points
														; in different Z positions will be performed to 
														; compensate for small non linearities in the probe

var Z_MULTIPLE_STEP_SIZE = 0.025						; [mm] Distance between the positions in Z while 
														; measuring the same XY point. Only used if 
														; Z_AMOUNT_POINTS is higher than 1.
var DEFAULT_MOVE_SPEED 			= 20000					; [mm/min] Default speed to move between steps

var AVOID_FIRST_Z_POINT = { var.Z_AMOUNT_POINTS > 1 }	; Avoids recording the first Z point.

var SAMPLES_PER_POINT 	= 1								; [] Amount of values to measure in each point. 

; Getting the input parameters ------------------------------------------------
var MOVE_SPEED 	= { (exists(param.S) && param.S != null) ? param.S : var.DEFAULT_MOVE_SPEED }

; Perform sampling ------------------------------------------------------------
; M118 S{"[PROBE] Measuring point X"^param.X^" Y"^param.Y^" Z"^global.PROBE_OFFSET_Z}
G1 X{param.X} Y{param.Y} Z{global.PROBE_OFFSET_Z} F{var.MOVE_SPEED}
M400

; Capture the value -----------------------------------------------------------
if (var.Z_AMOUNT_POINTS == 1)
	M98 P"/macros/probe/get_sample_single_z.g" T{var.DELAY_SAMPLING} O{var.SAMPLES_PER_POINT}
else ; Multiple points in Z
	M98 P"/macros/probe/get_sample_multiple_z.g" Z{var.Z_AMOUNT_POINTS} A{var.AVOID_FIRST_Z_POINT} S{var.Z_MULTIPLE_STEP_SIZE} T{var.DELAY_SAMPLING} O{var.SAMPLES_PER_POINT}
; Check the results
M598
M98 P"/macros/assert/abort_if.g" 	  R{!exists(global.probeMeasuredValue)}  	Y{"Missing global probeMeasuredValue"}	F{var.CURRENT_FILE} E65120
M98 P"/macros/assert/abort_if_null.g" R{global.probeMeasuredValue}  			Y{"Global probeMeasuredValue is null"}  F{var.CURRENT_FILE} E65121

; Obtain the distance measured to the target position (PROBE_VALUE_AT_Z).
set global.probeMeasuredValue = global.PROBE_VALUE_AT_Z - global.probeMeasuredValue;

; -----------------------------------------------------------------------------
; M118 S{"[PROBE] Done "^var.CURRENT_FILE}
M99 ; Proper exit
		