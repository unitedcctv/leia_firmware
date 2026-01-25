; Description: 
;	   Generic log configuration file for debugging purpose: When event logging is 
;	   enabled, important events such as power up, start/finish printing and (if possible) 
;	   power down will be logged to the SD card. Each log entry is a single line of text, 
;		starting with the date and time if available, or the elapsed time since power up if 
;	   not. If the log file already exists, new log entries will be appended to the existing 
;	   file.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/logs/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_LOGS)}  	Y{"A previous LOGS configuration exists"} F{var.CURRENT_FILE} E13600
M98 P"/macros/assert/abort_if.g" R{!exists(boards[0].firmwareDate)} Y{"Missing required boards[0].firmwareDate in OM"} F{var.CURRENT_FILE} E13601
M98 P"/macros/assert/abort_if_null.g" R{boards[0].firmwareDate} 	Y{"In OM, boards[0].firmwareDate is null"} F{var.CURRENT_FILE} E13602
M98 P"/macros/assert/abort_if.g" R{boards[0].firmwareDate == ""} 	Y{"In OM, boards[0].firmwareDate is empty"} F{var.CURRENT_FILE} E13603

; DEFINITIONS --------------------------------------------------------------------------------
var LOG_NAME = {"/sys/logs/standby/" ^ {boards[0].firmwareDate} ^ ".txt"}

; CONFIGURATION ------------------------------------------------------------------------------
M929 P{var.LOG_NAME} S3 			; start logging warnings to file {var.LOG_NAME}.txt
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the logs" F{var.CURRENT_FILE} E13604

; Adding the daemon the state checker.
; M98 P"/macros/files/daemon/add.g" F"/sys/modules/logs/daemon.g"

global MODULE_LOGS = 0.1		; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99						;Proper exit file