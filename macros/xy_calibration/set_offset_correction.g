if !inputs[state.thisInput].active
	M99
; Description: 	
;	We set the tool offset to the print head reference point (the ball sensor).
; 	Ïnput Parameters:
;		- T: Tool 0 or 1 to change the offset
;		- X: Offset in X
;		- Y: Offset in Y
;		- Z: Offset in Z
;		- L: Load the values from persistent variable
;		- R: Reset values to default (deletes persistent variable and requires restart)
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/xy_calibration/set_offset_correction.g"
M118 S{"[set_offset_correction.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking input parameters
if (!exists(param.L) && !exists(param.R))
	M98 P"/macros/assert/abort_if.g" R{!exists(param.X)} 		Y{"Missing required input parameter X"} F{var.CURRENT_FILE} E69130
	M98 P"/macros/assert/abort_if_null.g" R{param.X}  	 		Y{"Input parameter X is null"} 		 	F{var.CURRENT_FILE} E69131
	M98 P"/macros/assert/abort_if.g" R{!exists(param.Y)} 		Y{"Missing required input parameter Y"} F{var.CURRENT_FILE} E69132
	M98 P"/macros/assert/abort_if_null.g" R{param.Y}  	 		Y{"Input parameter Y is null"} 		 	F{var.CURRENT_FILE} E69133
M400

M98 P"/macros/assert/abort_if.g" R{!exists(param.T)} 		Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E69134
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	 		Y{"Input parameter T is null"} 		 	F{var.CURRENT_FILE} E69135	
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)} Y{"Unexpected tool value"} 				F{var.CURRENT_FILE} E69136

var OFFSET_VARIABLE = "xy_offsets_t"^param.T

; if param R exists then we reset the values to default
var RESET_TO_DEFAULT = exists(param.R)
if(var.RESET_TO_DEFAULT)
	M118 S{"[XYCAL] Resetting offsets for T"^param.T}
	M30 {"/sys/variables/"^var.OFFSET_VARIABLE^".g"}
	M118 S{"[XYCAL] Done "^var.CURRENT_FILE}
	M99

; if param L exists then we only load the values from variables
var LOAD_FROM_FILE = exists(param.L)

var x_correction = tools[param.T].offsets[0]
var y_correction = tools[param.T].offsets[1]
var zCorrection = exists(param.Z) ? param.Z : 0

if(var.LOAD_FROM_FILE)
	; Load the offset values from the stored variables -----------------------------------
	M118 S{"[XYCAL] Loading offsets for T"^param.T}
	M98 P"/macros/variable/load.g" N{var.OFFSET_VARIABLE} D{{0,0}} F{var.CURRENT_FILE}
	M598
	M98 P"/macros/assert/abort_if.g"		R{!exists(global.savedValue)}	Y{"Missing required global savedValue"}								F{var.CURRENT_FILE} E69137
	M98 P"/macros/assert/abort_if_null.g"	R{global.savedValue}			Y{"Offset variable not found: %s"} A{var.OFFSET_VARIABLE,}				F{var.CURRENT_FILE} E69138
	M98 P"/macros/assert/abort_if.g"		R{#global.savedValue!=2}		Y{"Offset variable bust be array with len 2: %s"} A{var.OFFSET_VARIABLE,}	F{var.CURRENT_FILE} E69139
	set var.x_correction = global.savedValue[0]
	set var.y_correction = global.savedValue[1]
	if (var.x_correction == 0 && var.y_correction == 0)
		M118 S{"[XYCAL] No offsets found for T"^param.T}
	else
		M118 S{"[XYCAL] Loaded offsets for T"^param.T^" from file: X"^var.x_correction^" Y"^var.y_correction}
	M400

else
	; Calculate the absolute offset value -----------------------------------------
	set var.x_correction = tools[param.T].offsets[0] + param.X
	set var.y_correction = tools[param.T].offsets[1] + param.Y
	M118 S{"_______________________________________________________________________"}
	M118 S{"[XYCAL] Old offsets of T"^param.T^" were X"^tools[param.T].offsets[0]^" Y"^tools[param.T].offsets[1]}
	M118 S{"[XYCAL] New offsets of T"^param.T^" were X"^var.x_correction^" Y"^var.y_correction}
	M118 S{"[XYCAL] Z Correction: "^var.zCorrection}
	M118 S{"_______________________________________________________________________"}
	; persist offsets
	M98 P"/macros/variable/save_number.g" N{var.OFFSET_VARIABLE} V{{var.x_correction,var.y_correction}} C1
M400

; Changing the tool offset ----------------------------------------------------
G10 P{param.T} X{var.x_correction} Y{var.y_correction}
M98 P"/macros/assert/result.g" R{result} Y{"XY Calibration failed: Unable to set the tool offset"}  F{var.CURRENT_FILE} E69140
if(var.zCorrection != 0)
	M98 P"/macros/axes/babystep_tool.g" T{param.T} S{var.zCorrection}
M400

; -----------------------------------------------------------------------------
M118 S{"[set_offset_correction.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit