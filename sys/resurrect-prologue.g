; Description: 
;			File to recover the print job from power failure.
;			When M916 command is executed, this file will be called.
;---------------------------------------------------------------------
; Definitions
var TIME_STR = (""^(+state.time))
var FILE_NAME = exists(global.jobUUID) && (global.jobUUID != null) ? global.jobUUID : var.TIME_STR
var LOG_NAME = {"/sys/logs/job/" ^ var.FILE_NAME ^ ".txt"}
; start logging to the current job log file {var.LOG_NAME}.txt
M929 P{var.LOG_NAME} S3
M118 S{"Logging on the job log file "^var.LOG_NAME}
M118 S{"Loading the power meter start value when the job was started"}
M98 P"/macros/variable/load.g" N"global.powerMeterValueStart"
M400
if (global.savedValue == null)
	M118 S{"No power meter value found"}
else
	M118 S{"Loaded the power meter start value for this job " ^ global.savedValue}
	global powerMeterValueStart = global.savedValue
; have to home the axes since resurrect prologue.g needs to go the resurrected positions
G92 Z{param.Z}
M400
M98 P"homexy.g"
M400
;---------------------------------------------------------------------
M118 S{"[resurrect-prologue.g] Print resurrecting from the power failure....."}
M99
