; Description: 	
;	This is a HMI command macro to initiate the resurrect.g after a power failure.
;	Previously the M-code used to initiate the resume.g is called via MQTT
;	To make it readable for the MQTT users its better to have macros to call the M-codes
;		- this macro is used to call the resurrect.g from the sys folder
;		- trigger the Mcode for resurrecting the print job
;	Input parameters: U - Failed job's UUID
;	example : M98 P"/macros/hmi/job/resurrect.g" U{"4285e92ea1e54cdba11bda8c5f6295fc"}
;--------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/job/resurrect.g"
M118 S{"[resume.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
set global.hmiStateDetail = "job_resurrecting"

; Checking global variables and input parameters --------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if.g"		R{!exists(param.U)}     	Y{"Missing jobUUID param U"}    	F{var.CURRENT_FILE} E86423
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/resume.g"} F{var.CURRENT_FILE} E86420
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/resurrect.g"} F{var.CURRENT_FILE} E86421
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/resurrect-prologue.g"} F{var.CURRENT_FILE} E86422
; Proceed to resume the print ----------------------------------------------------
; should lock the doors first as power failure unlock the doors
M98 P"/macros/doors/lock.g"
M400
; Reset the power failure variable
if(exists(global.powerFailure))
	set global.powerFailure = false
M400
; set the job UUID
if(!exists(global.jobUUID))
	global jobUUID = param.U
else
	set global.jobUUID = param.U
M400
M916 ;To trigger the resume.g from sys folder
M400
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -------------------------------------------------------------------------------	
M118 S{"[resurrect.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit