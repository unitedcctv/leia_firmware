; Description: 	
;		-To create new log for print job
; Input parameter:
;	- C (optional) : Name of the file without extension.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/files/logs/new.g"

; Definitions -----------------------------------------------------------------
var TIME_STR = (""^(+state.time))
var FILE_NAME = { (exists(param.C) && param.C != null) ? param.C : var.TIME_STR }
var LOG_NAME = {"/sys/logs/job/" ^ var.FILE_NAME ^ ".txt"}

; Closing previous log --------------------------------------------------------
M118 S{"[LOGS] Closing previous to create a new one: "^var.LOG_NAME}
M929 S0
M98 P"/macros/assert/result.g" R{result} Y"Unable to close the previous log file" 	F{var.CURRENT_FILE} E58300

; Creating a new log ----------------------------------------------------------
M929 P{var.LOG_NAME} S3 			; start logging warnings to file {var.LOG_NAME}.txt
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the new log file" 		F{var.CURRENT_FILE}  E58301

M118 S{"[LOGS] Started logging the new job log in log: "^var.LOG_NAME}

; -----------------------------------------------------------------------------
M99