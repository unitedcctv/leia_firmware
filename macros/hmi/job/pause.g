; Description: 	
;	This is a HMI command macro to initiate the pause.g 
;	Previously the M-code used to initiate the pause.g is called via MQTT
;	To make it readable for the MQTT users its better to have macros to call the M-codes
;       - this macro is used to call the pause.g from the sys folder
;       - trigger the Mcode for pausing the print job
; --------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/job/pause.g"
M118 S{"[pause.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
set global.hmiStateDetail = "job_pausing_manual"

; Checking global variables and input parameters --------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/pause.g"} F{var.CURRENT_FILE} E86200
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/unlock.g"} F{var.CURRENT_FILE} E86207
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_DOORS)}  Y{"Missing DOORS configuration"} F{var.CURRENT_FILE} E86206

var CAN_BE_PAUSED = (state.status=="processing")

; Making sure that the machine is printing
M98 P"/macros/assert/abort_if.g" R{!var.CAN_BE_PAUSED}    Y{"Machine is not printing at the moment so cannot pause the print"}    F{var.CURRENT_FILE} E86204

; Proceed to pause the print ----------------------------------------------------
M25 ;To trigger the pause.g from sys folder
M400
; Unlock the doors ----------------------------------------------------
M98 P"/macros/doors/unlock.g"
M400
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;M98  P"/macros/assert/result.g" R{result} Y"Unable to pause the print " F{var.CURRENT_FILE} E86205
; -------------------------------------------------------------------------------	
M118 S{"[pause.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit
