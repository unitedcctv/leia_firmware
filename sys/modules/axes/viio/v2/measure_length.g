; Test Name:		/sys/modules/axes/viio/v2/measure_length.g
; Test Version:		0.1
; Author:			FABBRO
; Creation Date:	17.07.23
; Reviewer:			?????
; Review Date:		??.??.23
; Description:
;	This file is based on the test:
;		limits/volume/measure_xyz/test.g
;	- Tests:
;		+ 1: Check that the axis has at least an endstop
;		+ 2: Measuring XYZ
; 	 	+ 3: The axes length are within valid values
; TODO: 
;	- Add "requires", as we need to make sure the endstops, motors and 
;	  homing works!
;   - Check Emergency and 48V!
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/axes/viio/v2/measure_length.g"

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/pop_up/ok_abort.g"}    F{var.CURRENT_FILE} 						E10200
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/variable/save_number.g"} F{var.CURRENT_FILE} 						E10201
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_AXES)}  	Y{"Missing required module AXES"}  F{var.CURRENT_FILE}  E10202
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_OFFSET_Z)}  Y{"Missing global PROBE_OFFSET_Z"} F{var.CURRENT_FILE}  E10203

; Definitions
var MAX_TOLERANCE 	= 100				; [mm] Max. tolerance to reach the endstop.
var AXES_MOVE_SPEED = {2000, 2000, 400}	; [mm/min] Default movement speeds
var FAST_MOVE_SPEED	= 10000				; [mm/min] Fast move speed
var POP_UP_TIMEOUT 	= 60				; [sec] Max. amount of time waiting for a response from the user
var MIN_AXIS_LENGTH = {1080, 610, 508}	; [mm]	Min. Axes lenght supported
var Z_POS_DURING_MEASURE_XY = 100 		; [mm] Z Position while measuring XY
var axesLength 		= {0, 0, 0}			; [mm] Length measured of each axes.
var REDUCE_LENGTH_BY = {5 , 5 , 2}		; [mm] Amount of mm to removed from the measured lenght
										;  	   in each axis.

;------------------------------------------------------------------------------
;  Check that the axis has at least an endstop
;------------------------------------------------------------------------------
M118 S{"[AXES] Start "^var.CURRENT_FILE}
var axisIdx = 0
while ( var.axisIdx < 3 )
	var MISSING_ENDSTOP = (!exists(sensors.endstops[var.axisIdx]) || (exists(sensors.endstops[var.axisIdx]) && sensors.endstops[var.axisIdx] == null))
	if(var.MISSING_ENDSTOP)
		M18 ; Turn off motors
	M98 P"/macros/assert/abort_if.g" R{var.MISSING_ENDSTOP}  	Y{"Missing required endstop in XYZ AXES"}  F{var.CURRENT_FILE}  E10204
	set var.axisIdx = var.axisIdx + 1

; Getting prepared for the rest of the tests
M98 P"/macros/pop_up/ok_abort.g" W"The homing process will start, please close the door. Press OK when the machine is ready to move" H"Homing" T{var.POP_UP_TIMEOUT}
if( global.popUpResult == null || (global.popUpResult != null && global.popUpResult == "ABORT" ) )
	M18	; Turn off motors
	M98 P"/macros/assert/abort_if_null.g" R{global.popUpResult}  	Y{"There was no input from the user before homing"}  F{var.CURRENT_FILE}  E10205
	M98 P"/macros/assert/abort.g" Y{"The user aborted the process before homing"}  F{var.CURRENT_FILE}  E10206

if(state.currentTool != -1)
	T-1 ; Deselecting tools

M118 S{"[AXES] Recording the axes length"}
G28	; Homing

G90 ; Absolute positioning
G1 Z{var.Z_POS_DURING_MEASURE_XY} ; Moving Z far from the bed
M400	; Making sure the previous move was done

;------------------------------------------------------------------------------
; Measuring XYZ
;------------------------------------------------------------------------------
; Measuring XY first
set var.axisIdx = 0 ; Index of AXIS X
while (var.axisIdx < 2)
	M18 ; Turnning Off all motors of XYZ
	; Telling the user what to do
	if (var.axisIdx == 0)
		M118 S{"[AXES] Measuring X"}
		if(sensors.endstops[var.axisIdx].highEnd)
			M98 P"/macros/pop_up/ok_abort.g" W"Open the door, move manually X to the min position (left), and press OK to continue" H"Move X to position MIN" T{var.POP_UP_TIMEOUT}
		else
			M98 P"/macros/pop_up/ok_abort.g" W"Open the door, move manually X to the max position (right), and press OK to continue" H"Move X to position MAX" T{var.POP_UP_TIMEOUT}
	elif (var.axisIdx == 1)
		M118 S{"[AXES] Measuring Y"}
		if(sensors.endstops[var.axisIdx].highEnd)
			M98 P"/macros/pop_up/ok_abort.g" W"Open the door, move manually Y to the min position (front), and press OK to continue" H"Move Y to position MIN" T{var.POP_UP_TIMEOUT}
		else
			M98 P"/macros/pop_up/ok_abort.g" W"Open the door, move manually Y to the max position (back), and press OK to continue" H"Move Y to position MAX" T{var.POP_UP_TIMEOUT}
	elif (var.axisIdx == 2)
		if(sensors.endstops[var.axisIdx].highEnd)
			M98 P"/macros/pop_up/ok_abort.g" W"Open the door, move manually Z to the min position (bottom), and press OK to continue" H"Move Z to position MIN" T{var.POP_UP_TIMEOUT}
		else
			M98 P"/macros/pop_up/ok_abort.g" W"Open the door, move manually Z to the max position (top), and press OK to continue" H"Move Z to position MAX" T{var.POP_UP_TIMEOUT}
	; Checking the response from the user
	if( global.popUpResult == null || (global.popUpResult != null && global.popUpResult == "ABORT" ) )
		M18
		M98 P"/macros/assert/abort_if_null.g" R{global.popUpResult}  	Y{"There was no input from the user before moving manually"}  F{var.CURRENT_FILE}  E10207
		M98 P"/macros/assert/abort.g" Y{"The user aborted the process before moving manually"}  F{var.CURRENT_FILE}  E10208
	; Getting the machine ready
	M98 P"/macros/pop_up/ok_abort.g" W"The machine will start moving, please close the door. Press OK when it is ready to move" H"Moving to endstops" T{var.POP_UP_TIMEOUT}
	if( global.popUpResult == null || (global.popUpResult != null && global.popUpResult == "ABORT" ) )
		M18
		M98 P"/macros/assert/abort_if_null.g" R{global.popUpResult}  	Y{"There was no input from the user before start moving"}  F{var.CURRENT_FILE}  E10209
		M98 P"/macros/assert/abort.g" Y{"The user aborted the process before start moving"}  F{var.CURRENT_FILE}  E10210
	; Moving until we hit an endstop
	M17 X Y Z ; Turnning ON the motors of XYZ
	G91 ; Relative positioning
	var TOTAL_MOVE = var.MIN_AXIS_LENGTH[var.axisIdx] + var.MAX_TOLERANCE
	if (var.axisIdx == 0)
		if(sensors.endstops[var.axisIdx].highEnd)
			G92 X{move.axes[var.axisIdx].min}
			G1 X{var.TOTAL_MOVE} H4 F{var.AXES_MOVE_SPEED[var.axisIdx]}
		else
			G92 X{move.axes[var.axisIdx].max}
			G1 X{-var.TOTAL_MOVE} H4 F{var.AXES_MOVE_SPEED[var.axisIdx]}
	elif(var.axisIdx == 1)
		if(sensors.endstops[var.axisIdx].highEnd)
			G92 Y{move.axes[var.axisIdx].min}
			G1 Y{var.TOTAL_MOVE} H4 F{var.AXES_MOVE_SPEED[var.axisIdx]}
		else
			G92 Y{move.axes[var.axisIdx].max}
			G1 Y{-var.TOTAL_MOVE} H4 F{var.AXES_MOVE_SPEED[var.axisIdx]}
	else 
		M18 ; Turn motors OFF
		M98 P"/macros/assert/abort.g" Y{"Not valid axes index"}  F{var.CURRENT_FILE}  E10211
	M400
	G90 ; Absolute positioning
	; Checking if the endstops were triggered
	if(!sensors.endstops[var.axisIdx].triggered)
		M18 ; Turn motors OFF
		; Check the axis and abort!
		M98 P"/macros/assert/abort_if.g" R{var.axisIdx == 0}  Y{"Unable to trigger endstops in X"}  F{var.CURRENT_FILE}  E10212
		M98 P"/macros/assert/abort.g" 						  Y{"Unable to trigger endstops in Y"}  F{var.CURRENT_FILE}  E10213
	
	; Measuring the distance
	if(sensors.endstops[var.axisIdx].highEnd)
		set var.axesLength[var.axisIdx] = move.axes[var.axisIdx].machinePosition - move.axes[var.axisIdx].min
		M118 S{"Axis "^var.axisIdx^ " length is " ^var.axesLength[var.axisIdx]^"mm" }
	else	
		set var.axesLength[var.axisIdx] = move.axes[var.axisIdx].max - move.axes[var.axisIdx].machinePosition
		M118 S{"Axis "^var.axisIdx^ " length is " ^var.axesLength[var.axisIdx]^"mm" }
	set var.axisIdx = var.axisIdx + 1

; Now measuring Z
M118 S{"[AXES] Measuring Z"}
if(!sensors.endstops[var.axisIdx].highEnd)
	M18 ; Turn motors OFF
	M98 P"/macros/assert/abort.g" Y{"Not supported test with lowEnd endstops in Z"}  F{var.CURRENT_FILE}  E10214

; if(fileexists("homexy.g"))
;	M98 P"homexy.g"
;else
;	G28 X Y
G28

; Moving to the middle in XY
G1 X{(move.axes[0].max - move.axes[0].min)/2} Y{(move.axes[1].max - move.axes[1].min)/2} Z{global.PROBE_OFFSET_Z} F{var.FAST_MOVE_SPEED}
M400

G91 ; Relative positioning
var TOTAL_MOVE = var.MIN_AXIS_LENGTH[var.axisIdx] + var.MAX_TOLERANCE
G1 Z{var.TOTAL_MOVE} H4 F{var.AXES_MOVE_SPEED[var.axisIdx]}
M400
G90 ; Absolute positioning
if(!sensors.endstops[var.axisIdx].triggered)
	M18 ; Turn motors OFF
	M98 P"/macros/assert/abort.g" Y{"Unable to trigger endstops in Z"}  F{var.CURRENT_FILE}  E10215

; Measuring the distance
set var.axesLength[var.axisIdx] = move.axes[var.axisIdx].machinePosition - move.axes[var.axisIdx].min
M118 S{"Axis "^var.axisIdx^ " length is " ^var.axesLength[var.axisIdx]^"mm" }

;------------------------------------------------------------------------------
; The axes length are within valid values
;------------------------------------------------------------------------------
set var.axisIdx = 0
while (var.axisIdx < 3)
	if(var.axesLength[var.axisIdx] < var.MIN_AXIS_LENGTH[var.axisIdx])
		M118 S{"Axis "^var.axisIdx^" is too short: " ^ var.axesLength[var.axisIdx] ^"mm"}
		M99 ; Proper exit
	set var.axisIdx = var.axisIdx + 1
M18 ; Turn motors OFF

while (var.axisIdx < 3)
	set var.axesLength[var.axisIdx] = var.axesLength[var.axisIdx] - var.REDUCE_LENGTH_BY[var.axisIdx]
	set var.axisIdx = var.axisIdx + 1

M118 S{"Recording the axes length"}
M98 P"/macros/variable/save_number.g" N"length_axis_x" V{var.axesLength[0]}
M98 P"/macros/variable/save_number.g" N"length_axis_y" V{var.axesLength[1]}
M98 P"/macros/variable/save_number.g" N"length_axis_z" V{var.axesLength[2]}

M118 S{"[AXES] Done "^var.CURRENT_FILE}
M99	; Proper exit current file

