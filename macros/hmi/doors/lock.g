; Description: 	
;   This is a HMI command macro to lock the doors
;   To make it readable for the MQTT users its better to have macros to call the M-codes
;       - this macro is used to call the lock.g from the macros
;--------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/doors/lock.g"
M118 S{"[lock.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters --------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/lock.g"} F{var.CURRENT_FILE} E83000

; lock the door----------------------------------------------------------------
M98 P"/macros/doors/lock.g"

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;---------------------------------------------------------------------------------------------------------
M118 S{"[lock.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit