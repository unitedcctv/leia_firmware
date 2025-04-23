; Description: 	
;   This macro is used to  set the bed idle cool down timer.
;   By default ,after 120 minutes if the machine is idle and bed set temperature is >0°C
;	turns off the bed.
;   Input Parameter , B: Waiting time in minutes
;               B = 12; Turn off bed in 12 minutes
;               Example : M98 P"/macros/hmi/bed/set_idle_time.g" B12
;---------------------------------------------------------------------------------------------
var CURRENT_FILE		= "/macros/hmi/bed/set_idle_time.g"
; Definitions--------------------------------------------------------------------
M118 S{"set_idle_time.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Check files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/generic/set_idle_time.g"} 	F{var.CURRENT_FILE} E81210
; Variable to  change the idle time------------------------------------------------------
; (!)Default is to wait until 120 mins------------------------------------------
M98 P"/macros/assert/abort_if.g" 	R{(!exists(param.B))} 		Y{"Missing param waiting time"} F{var.CURRENT_FILE} E81211
M98 P"/macros/assert/abort_if_null.g" 	R{param.B} 		Y{"Entered waiting time is null"} F{var.CURRENT_FILE} E81212
M98 P"/macros/assert/abort_if.g" 	R{(param.B < 1)} 		Y{"Entered waiting time is invalid"} F{var.CURRENT_FILE} E81213

; Reset the timer-------------------------------------------------------------
M98 P"/macros/generic/set_idle_time.g" B{param.B}
M118 S{"[BED] Changed the idle cool down wait time for the bed to " ^ global.bedIdleWaitTime ^" mins"}

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -----------------------------------------------------------------------------
M118 S{"[set_idle_time.g] Done "^var.CURRENT_FILE}
M99