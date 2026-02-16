; Description: 	
;   This is a HMI command macro to initiate the home of XY
;   Previously the M-code used to initiate the stop.g is called via MQTT
;   To make it readable for the MQTT users its better to have macros to call the M-codes
;		-this macro is used to call the home_xy.g from the sys folder
;--------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/home/xy.g"
M118 S{"[xy.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters --------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/printing/get_ready.g"} F{var.CURRENT_FILE} E85200
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/homexy.g"} F{var.CURRENT_FILE} E85201

; Definitions -------------------------------------------------------------------
var CURRENT_TOOL = state.currentTool

; Checking if we can home the machine -------------------------------------------
M98 P"/macros/printing/get_ready.g"

; Deslect the tool before start home the Z axes----------------------------------
if(var.CURRENT_TOOL != -1)
	T-1 ; Deselect the current extruder    
	M98  P"/macros/assert/result.g" R{result} Y"Unable to deselect the extruder" F{var.CURRENT_FILE}   E85204
	M118 S{"Deselected the current tool since the machine is going to home Z axes"}

; Proceed with home the XY axes--------------------------------------------------
M98 P"/sys/homexy.g"
M400
; Reslect the tool --------------------------------------------------------------
if(var.CURRENT_TOOL >= 0)
	T{var.CURRENT_TOOL}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to reselect the extruder" F{var.CURRENT_FILE}   E85205
	M118 S{"Re-selected the current tool which was T"^var.CURRENT_TOOL}

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;-------------------------------------------------------------------------------------------------------
M118 S{"[xy.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit