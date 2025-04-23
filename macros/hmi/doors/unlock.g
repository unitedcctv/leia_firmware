; Description: 	
;This is a HMI command macro to unlock the doors
;To make it readable for the MQTT users its better to have macros to call the M-codes
;       - this macro is used to call the unlock.g from the macros
;--------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/doors/unlock.g"
M118 S{"[unlock.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/unlock.g"} F{var.CURRENT_FILE} E83001
M98 P"/macros/doors/unlock.g"

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;--------------------------------------------------------------------------------------------------------
M118 S{"[unlock.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit