; Description: 	
;   This macro is used to reset the Extruder and bed idle cool down timer.
;   By default ,after 20 minutes if the machine is idle and extruders are hot it automatically
;	turns off the extruders.
;   By default ,after 120 minutes if the machine is idle and set bed temperature is >0°C
;	turns off the bed.
;               Example : M98 P"/macros/hmi/generic/reset_idle_timer.g"
;---------------------------------------------------------------------------------------------
var CURRENT_FILE		= "/macros/hmi/generic/reset_idle_timer.g"
M118 S{"[reset_idle_timer.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Check files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/generic/reset_idle_timer.g"} 	F{var.CURRENT_FILE} E86000
; Call the root macro to reset the idle timer------------------------------------------
M98 P"/macros/generic/reset_idle_timer.g" 
M400

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -----------------------------------------------------------------------------
M118 S{"[reset_idle_timer.g] Done "^var.CURRENT_FILE}
M99