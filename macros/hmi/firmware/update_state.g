; Description: 	
;   This is a HMI command macro to set the update state of the firmware
;   To make it readable for the MQTT users its better to have macros to call the M-codes
;       - this macro is used to call the /macros/machine/update/set_waiting_state.g from the macros
;--------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/firmware/update_state.g"
M118 S{"[update_state.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters --------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/machine/update/set_waiting_state.g"} F{var.CURRENT_FILE} E85410

; Set the update state----------------------------------------------------------------
M98 P"/macros/machine/update/set_waiting_state.g"
M400

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}

; Restart the machine------------------------------------------------------------
M118 S{"[update_state.g] Done "^var.CURRENT_FILE}
M999
;---------------------------------------------------------------------------------------------------------
M99		;Proper file exit