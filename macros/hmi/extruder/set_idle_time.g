; Description: 	
;   This macro is used to  the Extruder idle cool down timer.
;   By default ,after 20 minutes if the machine is idle and extruders are hot it automatically
;	turns off the extruders.
;   Input Parameter , T: Waiting time in minutes
;               T = 12; Turn off all the extruders in 12 minutes
;               Example : M98 P"/macros/hmi/extruder/set_idle_time.g" T12
;---------------------------------------------------------------------------------------------
var CURRENT_FILE		= "/macros/hmi/extruder/set_idle_time.g"
; Definitions--------------------------------------------------------------------
M118 S{"[set_idle_time.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Check files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/generic/set_idle_time.g"} 	F{var.CURRENT_FILE} E84201
; Variable to  change the idle time------------------------------------------------------
; (!)Default is to wait until 20 mins------------------------------------------
M98 P"/macros/assert/abort_if.g" 	R{(!exists(param.T))} 		Y{"Missing param waiting time"} F{var.CURRENT_FILE} E84202
M98 P"/macros/assert/abort_if_null.g" 	R{param.T} 		Y{"Entered waiting time is null"} F{var.CURRENT_FILE} E84203
M98 P"/macros/assert/abort_if.g" 	R{(param.T < 1)} 		Y{"Entered waiting time is invalid"} F{var.CURRENT_FILE} E84204

; Reset the timer-------------------------------------------------------------
M98 P"/macros/generic/set_idle_time.g" T{param.T}
M118 S{"[set_idle_time.g] Changed the maximum idle cool down wait time for the tools to " ^ global.tooldleWaitTime ^" mins"}

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -----------------------------------------------------------------------------
M118 S{"[set_idle_time.g] Done "^var.CURRENT_FILE}
M99