; Description: 	
;   This macro is used to  call the record_max_value.g from /sys/modules/probes/viio/v1/record_max_value.g
;---------------------------------------------------------------------------------------------
var CURRENT_FILE		= "/macros/hmi/probe/record_max_value.g"
; Definitions--------------------------------------------------------------------
M118 S{"[record_max_value.g] Starting"^var.CURRENT_FILE^ "I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Check files
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/probes/viio/v1/record_max_value.g"} F{var.CURRENT_FILE} E87200

; calling the macro
M98 P"/sys/modules/probes/viio/v1/record_max_value.g"
M400
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -----------------------------------------------------------------------------
M118 S{"[record_max_value.g] Done "^var.CURRENT_FILE}
M99