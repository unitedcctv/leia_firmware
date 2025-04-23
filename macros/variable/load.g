; Description: 
;	This script will load the value of variable from a file.
;	The value will be returned using the variables:
;		+ global.savedValue 
;		+ global.savedTime
; Input parameters:
;	- N: Name of the file
;	- (optional) D: Default value to return if the variable doesn't exist.
; Example:
;	M98 P"/macros/variable/load.g" N"length_axis_x" D1050	; Default X Length
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/variable/load.g"
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.N)}  	Y{"Missing input parameter N"}  F{var.CURRENT_FILE} E68000
M98 P"/macros/assert/abort_if_null.g" 	R{param.N} 				Y{"Input parameter N is null"} 	F{var.CURRENT_FILE} E68001
M98 P"/macros/assert/abort_if.g" 	  	R{param.N == ""}  		Y{"Parameter N is empty"} 		F{var.CURRENT_FILE} E68002
; Definitions -----------------------------------------------------------------
var VARIABLES_FOLDER 		= "/sys/variables/"  ; Folder where the file will be saved
var FILE_NAME = {var.VARIABLES_FOLDER ^ param.N ^ ".g"} ; Expected location of the file

if (!exists(global.savedValue))
	global savedValue = null
else
	set global.savedValue = null
if (!exists(global.savedTime))
	global savedTime = null
else
	set global.savedTime = null

if(!fileexists(var.FILE_NAME))
	if(exists(param.D))
		set global.savedValue = param.D
	M99 ; Proper exit
; Reading the value from the file
M98 P{var.FILE_NAME}

; -----------------------------------------------------------------------------
M99




