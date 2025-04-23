; Description: 	
;This is a HMI command macro to initiate the home all axes
;To make it readable for the MQTT users its better to have macros to call the M-codes
;       - this macro is used to call the home all macro from the sys folder
;--------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/home/all.g"
M118 S{"[all.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters --------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/printing/get_ready.g"} F{var.CURRENT_FILE} E85000
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/homeall.g"} F{var.CURRENT_FILE} E85001;checking for the root file.

; Checking if we can home the machine -------------------------------------------
M98 P"/macros/printing/get_ready.g"

; Proceed with homing all the axes-----------------------------------------------
M98 P"/sys/homeall.g"
M400

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;--------------------------------------------------------------------------------
M118 S{"[all.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit