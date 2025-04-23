; Description: 	
;   This is a HMI command macro to initiate the cancel.g 
;   Previously the M-code used to initiate the cancel.g is called via MQTT
;   To make it readable for the MQTT users its better to have macros to call the M-codes
;	   - this macro is used to call the cancel.g from the sys folder
;--------------------------------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/job/cancel.g"
M118 S{"[cancel.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
set global.hmiStateDetail = "job_aborting"

; Checking global variables and input parameters --------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/cancel.g"} F{var.CURRENT_FILE} E86100
; changing the state 
M118 S{"[cancel.g] cancelling from state: "^state.status}

; If we're in a power failure state, reset it. In that case there will be no job to abort.
if(exists(global.powerFailure) && global.powerFailure)
	M118 S{"[cancel.g] resetting power failure state"}
	set global.powerFailure = false
	if(fileexists("/sys/resurrect.g"))
		M30 "/sys/resurrect.g"
else
	; setting the force abort variable to true if the job was aborted by the user
	if ((state.status != "pausing") && (state.status != "paused"))
		if(!exists(global.forceAbort))
			global forceAbort = true
		else
			set global.forceAbort = true
		M25
	; waiting until the moves are finished
	M400
	; calling the cancel.g
	if ((state.status != "cancelling") && (state.status != "idle"))
		M0
	M400
M400
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -------------------------------------------------------------------------------	
M118 S{"[cancel.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit
