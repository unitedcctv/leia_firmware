; Description: 
;	This macros should be used to call python scripts via ComMQTT.
;	More information available in:
;		https://wiki.bigrep.com/display/ST3/Meta+functions+called+by+the+GCODE
; Input parameters:
;	- N: Name of the function to call
;	- (optional) F: File or folder path
;	- (optional) T: Timeout in seconds. @See enclose.g for default values
; Examples:
;	- M98 P"/macros/python/call_function.g" N"SAMPLE"
;	- M98 P"/macros/python/call_function.g" N"WITH_FILE" F"/sys/somefolder/somefile.csv"
;	- M98 P"/macros/python/call_function.g" N"WITH_FOLDER" F"/sys/somefolder/"
;	- M98 P"/macros/python/call_function.g" N"WITH_FOLDER" F"/sys/somefolder/,/sys/someotherfolder/"
;	- M98 P"/macros/python/call_function.g" N"WITH_FOLDER" F"/sys/somefolder/" A"{''paramA'':1, ''paramB'':2}"
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/python/call_function.g"

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/python/enclose.g"} 					F{var.CURRENT_FILE} E66000
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.N)} 			Y{"Missing input parameter N"} 	F{var.CURRENT_FILE} E66010
M98 P"/macros/assert/abort_if_null.g" R{param.N} 				Y{"Input parameter N is null"} 	F{var.CURRENT_FILE} E66011

; Definitions -----------------------------------------------------------------
var TIMEOUT_DEFAULT = 30 	; [sec] Default timeout

; Input variables
var FOLDER_OR_FILE = {(exists(param.F) && param.F != null && param.F != "") ? {" "^param.F} : "" }
var ARGUMENTS = {(exists(param.A) && param.A != null && param.A != "") ? {" "^param.A} : "" }

; Calling python --------------------------------------------------------------
var TIME_START = +state.time ; [sec] Recoding the time before calling python
if(exists(param.T) && param.T != null)
	M98 P"/macros/python/enclose.g" W{param.N ^ var.FOLDER_OR_FILE ^ var.ARGUMENTS} T{param.T}
else
	M98 P"/macros/python/enclose.g" W{param.N ^ var.FOLDER_OR_FILE ^ var.ARGUMENTS}

M598
M98 P"/macros/assert/abort_if.g" R{!exists(global.pythonResult)} Y{"Missing global pythonResult after calling enclose.g"} 	F{var.CURRENT_FILE} E66020

if( global.pythonResult == null )
	M98 P"/macros/report/warning.g" Y{"No answer from HMI"} F{var.CURRENT_FILE} W66020
else
	M118 S{"[INFO] HMI answered after "^(+state.time - var.TIME_START)^" sec" }
	M118 S{"[INFO] HMI answered: " ^ global.pythonResult }

; -----------------------------------------------------------------------------
M99 ; proper exit