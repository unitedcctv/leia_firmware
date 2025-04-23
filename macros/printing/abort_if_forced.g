; Description: 	
;	We will check the status of the global 'forceAbort' and we will abort if
; 	if this variable is 'true'. 
;	(!) NOTE: This should be used in macros that take too much time to be 
;	executed.
; Input parameters:
;	- Y (optional): Message to print.
;	- F (optional): File name
;	- L (optional): Line in file 
; Example:
;	M98 P"/macros/printing/abort_if_forced.g" Y{"During homing XY"} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/printing/abort_if_forced.g"
M118 S{"[abort_if_forced.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

if(exists(global.forceAbort) && global.forceAbort)
	set global.forceAbort = false
	var FILE_NAME = { (exists(param.F) && param.F != null) ? param.F : var.CURRENT_FILE}
	var MESSAGE   = { (exists(param.Y) && param.Y != null) ? param.Y : "No details"}
	var LINE = { (exists(param.L) && param.L != null) ? param.L : null }
	var lineMessage = ""
	if(var.LINE != null)
		set var.lineMessage = { " | In line "^var.LINE}
	M400
	abort
M400
; -----------------------------------------------------------------------------
M118 S{"[abort_if_forced.g] Done "^var.CURRENT_FILE}
M99; Proper exit