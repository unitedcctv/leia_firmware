; Description: 	
;	This is a HMI command macro to initiate the resume.g 
;	Previously the M-code used to initiate the resume.g is called via MQTT
;	To make it readable for the MQTT users its better to have macros to call the M-codes
;		- this macro is used to call the resume.g from the sys folder
;		- trigger the Mcode for resuming the print job
;--------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/job/resume.g"
M118 S{"[resume.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
set global.hmiStateDetail = "job_resuming"

; Checking global variables and input parameters --------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/resume.g"} F{var.CURRENT_FILE} E86300

; Making sure that the machine is paused
M98 P"/macros/assert/abort_if.g" R{(state.status!="paused")}    Y{"Machine is not paused at the moment so cannot resume the print"}    F{var.CURRENT_FILE} E86304

; Proceed to resume the print ----------------------------------------------------
M24 ;To trigger the resume.g from sys folder
M400

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -------------------------------------------------------------------------------	
M118 S{"[resume.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit
