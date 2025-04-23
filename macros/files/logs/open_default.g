; Description: 	
;	-To create new log for print job
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/files/logs/open_default.g"

; Definitions -----------------------------------------------------------------
var LOG_NAME = {"/sys/logs/standby/" ^ {boards[0].firmwareDate} ^ ".txt"}

; Closing previous log --------------------------------------------------------
M118 S{"[LOGS] Closing previous log file"}
M929 S0
M98 P"/macros/assert/result.g" R{result} Y"Unable to close the previous log file" 	F{var.CURRENT_FILE} E58400

; Open default log ------------------------------------------------------------
M929 P{var.LOG_NAME} S3 			; start logging warnings to file {var.LOG_NAME}.txt
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the new log file"  		F{var.CURRENT_FILE} E58401

M118 S{"[LOGS] Opened the default event logging file: "^var.LOG_NAME}
M99